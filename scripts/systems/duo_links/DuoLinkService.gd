extends RefCounted
class_name DuoLinkService

const GaugePolicy = preload("res://scripts/systems/duo_links/DuoLinkGaugePolicy.gd")
const MAX_EQUIPPED := 2


static func record_deployed_day(active_run_value, deployed_instance_ids: Array, day: int, catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if day < 1:
		return active_run
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	var days_by_link: Dictionary = metrics.get("duo_deployed_days", {}).duplicate(true)
	for link_id_value in catalog.keys():
		var link_id := str(link_id_value)
		var members: Array = catalog.get(link_id, {}).get("member_instance_ids", [])
		if members.size() != 2 or not deployed_instance_ids.has(members[0]) or not deployed_instance_ids.has(members[1]):
			continue
		var days: Array = days_by_link.get(link_id, []).duplicate()
		if not days.has(day):
			days.append(day)
		days_by_link[link_id] = days
	metrics["duo_deployed_days"] = days_by_link
	active_run["run_metrics_update3"] = metrics
	return active_run


static func record_unlock_action(active_run_value, member_instance_id: String, source_id: String, amount: int, event_token: String, catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if event_token == "" or amount <= 0:
		return active_run
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	var progress_by_link: Dictionary = metrics.get("duo_role_progress", {}).duplicate(true)
	for link_id_value in catalog.keys():
		var link_id := str(link_id_value)
		var definition: Dictionary = catalog.get(link_id, {})
		var matched := false
		var threshold := 1
		for source_value in definition.get("gauge_sources", []):
			if source_value is Dictionary and str(source_value.get("member_instance_id", "")) == member_instance_id and str(source_value.get("source_id", "")) == source_id:
				matched = true
				threshold = maxi(1, int(source_value.get("threshold", 1)))
				break
		if not matched or amount < threshold:
			continue
		var progress: Dictionary = progress_by_link.get(link_id, {"tokens": [], "member_counts": {}}).duplicate(true)
		var tokens: Array = progress.get("tokens", []).duplicate()
		var token_key := "%s:%s" % [member_instance_id, event_token]
		if tokens.has(token_key):
			continue
		tokens.append(token_key)
		var counts: Dictionary = progress.get("member_counts", {}).duplicate(true)
		counts[member_instance_id] = int(counts.get(member_instance_id, 0)) + 1
		var members: Array = definition.get("member_instance_ids", [])
		var combo_count := mini(int(counts.get(str(members[0]), 0)), int(counts.get(str(members[1]), 0))) if members.size() == 2 else 0
		progress["tokens"] = tokens
		progress["member_counts"] = counts
		progress["combo_count"] = combo_count
		progress_by_link[link_id] = progress
	metrics["duo_role_progress"] = progress_by_link
	active_run["run_metrics_update3"] = metrics
	return active_run


static func eligible_memory_event_ids(profile_value, active_run_value, member_progress: Dictionary, catalog: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var duo_progress: Dictionary = profile_value.get("duo_links", {}) if profile_value is Dictionary else {}
	var unlocked: Array = duo_progress.get("unlocked", [])
	var seen: Array = duo_progress.get("memory_events_seen", [])
	var metrics: Dictionary = active_run_value.get("run_metrics_update3", {}) if active_run_value is Dictionary else {}
	var days_by_link: Dictionary = metrics.get("duo_deployed_days", {})
	var role_progress: Dictionary = metrics.get("duo_role_progress", {})
	for link_id_value in catalog.keys():
		var link_id := str(link_id_value)
		var definition: Dictionary = catalog.get(link_id, {})
		var condition: Dictionary = definition.get("unlock_condition", {})
		var event_id := str(condition.get("event_id", ""))
		if event_id == "" or unlocked.has(link_id) or seen.has(event_id):
			continue
		var members: Array = definition.get("member_instance_ids", [])
		if members.size() != 2:
			continue
		var member_ready := true
		for member_id_value in members:
			var progress: Dictionary = member_progress.get(str(member_id_value), {})
			member_ready = member_ready and int(progress.get("bond", 0)) >= int(condition.get("bond_each", 45))
			member_ready = member_ready and progress.get("unlocked_memory_ids", []).size() >= int(condition.get("personal_memory_each", 1))
		if not member_ready or days_by_link.get(link_id, []).size() < int(condition.get("deployed_together_days", 3)) or int(role_progress.get(link_id, {}).get("combo_count", 0)) < int(condition.get("role_combo_count", 5)):
			continue
		result.append(event_id)
	result.sort()
	return result


static func complete_memory_event(profile_value, event_id: String, catalog: Dictionary) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	var link_id := ""
	for candidate_value in catalog.keys():
		var candidate := str(candidate_value)
		if str(catalog.get(candidate, {}).get("unlock_condition", {}).get("event_id", "")) == event_id:
			link_id = candidate
			break
	if link_id == "":
		return {"ok": false, "error": "합동 기억과 연결된 합동기를 찾을 수 없습니다.", "profile": profile}
	var progress: Dictionary = profile.get("duo_links", {"unlocked": [], "usage_counts": {}, "first_use_cycle": {}, "memory_events_seen": []}).duplicate(true)
	var seen: Array = progress.get("memory_events_seen", []).duplicate()
	if seen.has(event_id):
		return {"ok": false, "error": "이미 확인한 합동 기억입니다.", "profile": profile}
	var unlocked: Array = progress.get("unlocked", []).duplicate()
	if not unlocked.has(link_id):
		unlocked.append(link_id)
	seen.append(event_id)
	progress["unlocked"] = unlocked
	progress["memory_events_seen"] = seen
	profile["duo_links"] = progress
	return {"ok": true, "error": "", "profile": profile, "link_id": link_id}


static func unlock_fixture(profile_value, link_id: String, catalog: Dictionary) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	if not catalog.has(link_id):
		return {"ok": false, "error": "존재하지 않는 합동기입니다.", "profile": profile}
	var progress: Dictionary = profile.get("duo_links", {"unlocked": [], "usage_counts": {}, "first_use_cycle": {}})
	var unlocked: Array = progress.get("unlocked", []).duplicate()
	if not unlocked.has(link_id):
		unlocked.append(link_id)
	progress["unlocked"] = unlocked
	profile["duo_links"] = progress
	return {"ok": true, "error": "", "profile": profile}


static func equip(profile_value, active_run_value, link_id: String, catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if not catalog.has(link_id):
		return _equip_result(false, "존재하지 않는 합동기입니다.", active_run)
	if not profile_value.get("duo_links", {}).get("unlocked", []).has(link_id):
		return _equip_result(false, "아직 해금되지 않은 합동기입니다.", active_run)
	var equipped: Array = active_run.get("equipped_duo_links", []).duplicate()
	if equipped.has(link_id):
		return _equip_result(true, "", active_run)
	if equipped.size() >= MAX_EQUIPPED:
		return _equip_result(false, "합동기는 최대 2개까지 장착할 수 있습니다.", active_run)
	var requested_members: Array = catalog.get(link_id, {}).get("member_instance_ids", [])
	for equipped_id_value in equipped:
		var equipped_members: Array = catalog.get(str(equipped_id_value), {}).get("member_instance_ids", [])
		for member in requested_members:
			if equipped_members.has(member):
				return _equip_result(false, "한 몬스터는 두 합동기에 동시에 참여할 수 없습니다: %s" % str(member), active_run)
	equipped.append(link_id)
	active_run["equipped_duo_links"] = equipped
	return _equip_result(true, "", active_run)


static func unequip(active_run_value, link_id: String) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var equipped: Array = active_run.get("equipped_duo_links", []).duplicate()
	equipped.erase(link_id)
	active_run["equipped_duo_links"] = equipped
	return active_run


static func begin_battle(active_run_value, deployed_instance_ids: Array, catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var states: Dictionary = {}
	var inactive_count := 0
	for link_id_value in active_run.get("equipped_duo_links", []):
		var link_id := str(link_id_value)
		var members: Array = catalog.get(link_id, {}).get("member_instance_ids", [])
		var missing: Array[String] = []
		for member in members:
			if not deployed_instance_ids.has(member):
				missing.append(str(member))
		var active := missing.is_empty() and members.size() == 2
		if not active:
			inactive_count += 1
		states[link_id] = GaugePolicy.empty_state(active, "미출전 멤버: %s" % ", ".join(missing) if not active else "")
	active_run["duo_link_states"] = states
	active_run["duo_link_auto_use"] = bool(active_run.get("duo_link_auto_use", false))
	active_run["duo_link_active_effects"] = []
	active_run["duo_link_inactive_count"] = inactive_count
	return active_run


static func record_action(active_run_value, link_id: String, member_instance_id: String, source_id: String, amount: int, event_token: String, catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var states: Dictionary = active_run.get("duo_link_states", {}).duplicate(true)
	if not states.has(link_id) or not catalog.has(link_id):
		return {"active_run": active_run, "gain": 0, "counted": false}
	var result := GaugePolicy.record_action(states.get(link_id), catalog.get(link_id, {}), member_instance_id, source_id, amount, event_token)
	states[link_id] = result.get("state", {})
	active_run["duo_link_states"] = states
	return {"active_run": active_run, "gain": int(result.get("gain", 0)), "counted": bool(result.get("counted", false))}


static func member_downed(active_run_value, member_instance_id: String, catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var states: Dictionary = active_run.get("duo_link_states", {}).duplicate(true)
	for link_id_value in states.keys():
		var link_id := str(link_id_value)
		if not catalog.get(link_id, {}).get("member_instance_ids", []).has(member_instance_id):
			continue
		var state: Dictionary = states.get(link_id, {}).duplicate(true)
		var downed: Array = state.get("downed_members", []).duplicate()
		if not downed.has(member_instance_id):
			downed.append(member_instance_id)
		state["downed_members"] = downed
		state["active"] = false
		state["ready"] = false
		state["inactive_reason"] = "멤버 전투 불능"
		states[link_id] = state
	active_run["duo_link_states"] = states
	return active_run


static func activate(active_run_value, link_id: String, catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var states: Dictionary = active_run.get("duo_link_states", {}).duplicate(true)
	var state: Dictionary = states.get(link_id, {}).duplicate(true)
	if state.is_empty() or not bool(state.get("active", false)):
		return {"ok": false, "error": str(state.get("inactive_reason", "활성 멤버가 없습니다.")), "active_run": active_run}
	if bool(state.get("used_this_battle", false)):
		return {"ok": false, "error": "이 합동기는 이번 전투에 이미 사용했습니다.", "active_run": active_run}
	if int(state.get("charge", 0)) < GaugePolicy.MAX_GAUGE:
		return {"ok": false, "error": "합동기 게이지가 아직 100이 아닙니다.", "active_run": active_run}
	state["used_this_battle"] = true
	state["ready"] = false
	state["charge"] = 0
	states[link_id] = state
	active_run["duo_link_states"] = states
	return {"ok": true, "error": "", "active_run": active_run, "effect_handler": str(catalog.get(link_id, {}).get("effect_handler", ""))}


static func settle_profile(profile_value, active_run: Dictionary, cycle_index: int) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	var progress: Dictionary = profile.get("duo_links", {"unlocked": [], "usage_counts": {}, "first_use_cycle": {}})
	var usage: Dictionary = progress.get("usage_counts", {}).duplicate(true)
	var first: Dictionary = progress.get("first_use_cycle", {}).duplicate(true)
	for link_id_value in active_run.get("duo_link_states", {}).keys():
		var link_id := str(link_id_value)
		if not bool(active_run.get("duo_link_states", {}).get(link_id, {}).get("used_this_battle", false)):
			continue
		usage[link_id] = int(usage.get(link_id, 0)) + 1
		if not first.has(link_id):
			first[link_id] = maxi(1, cycle_index)
	progress["usage_counts"] = usage
	progress["first_use_cycle"] = first
	profile["duo_links"] = progress
	return profile


static func deployment_warnings(active_run: Dictionary, deployed_instance_ids: Array, catalog: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	for link_id_value in active_run.get("equipped_duo_links", []):
		var link_id := str(link_id_value)
		var missing: Array[String] = []
		for member in catalog.get(link_id, {}).get("member_instance_ids", []):
			if not deployed_instance_ids.has(member):
				missing.append(str(member))
		if not missing.is_empty():
			warnings.append("%s 비활성 예정 · 미출전 %s" % [str(catalog.get(link_id, {}).get("display_name", link_id)), ", ".join(missing)])
	return warnings


static func _equip_result(ok: bool, error: String, active_run: Dictionary) -> Dictionary:
	return {"ok": ok, "error": error, "active_run": active_run}
