extends RefCounted
class_name ChronicleService

const MAX_RECENT_RUNS := 5
const FRONT_ORDER := ["front_hero_oath", "front_holy_purification", "front_guild_repossession"]
const HEART_ORDER := ["heart_stonebone", "heart_hungry_maw", "heart_dream_lantern"]
const RIVAL_ORDER := ["leon", "selen", "roman"]
const RIVAL_NAMES := {"leon": "레온", "selen": "셀렌", "roman": "로만"}


static func normalize_recent_runs(values) -> Array:
	var normalized: Array = []
	if values is Array:
		for value in values:
			if value is Dictionary:
				var entry: Dictionary = value.duplicate(true)
				if int(entry.get("cycle_index", 0)) > 0:
					normalized.append(entry)
	while normalized.size() > MAX_RECENT_RUNS:
		normalized.pop_front()
	return normalized


static func record_run_summary(profile_value, active_run_value, cycle_index: int, ending_id: String, ending_catalog: Dictionary, front_catalog: Dictionary) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	var active_run: Dictionary = active_run_value if active_run_value is Dictionary else {}
	var front_id := str(active_run.get("front_id", ""))
	var heart_id := str(active_run.get("heart", {}).get("heart_id", ""))
	if cycle_index < 1 or front_id == "" or ending_id == "":
		return profile
	var recent := normalize_recent_runs(profile.get("recent_run_summaries", []))
	for index in range(recent.size() - 1, -1, -1):
		var old: Dictionary = recent[index]
		if int(old.get("cycle_index", 0)) == cycle_index:
			recent.remove_at(index)
	var ending: Dictionary = ending_catalog.get(ending_id, {})
	var front: Dictionary = front_catalog.get(front_id, {})
	var link_ids: Array = []
	for link_id_value in active_run.get("equipped_duo_links", []):
		var link_id := str(link_id_value)
		if link_id != "" and not link_ids.has(link_id):
			link_ids.append(link_id)
	recent.append({
		"cycle_index": cycle_index,
		"front_id": front_id,
		"front_name": str(front.get("display_name", front_id)),
		"heart_id": heart_id,
		"ending_id": ending_id,
		"ending_code": str(ending.get("catalog_code", "")),
		"ending_title": str(ending.get("display_name", ending.get("title", ending_id))),
		"duo_link_ids": link_ids,
		"epilogue_id": str(front.get("epilogue_card", {}).get("id", ""))
	})
	profile["recent_run_summaries"] = normalize_recent_runs(recent)
	return profile


static func build_view_model(profile_value, catalogs: Dictionary, goals: Dictionary = {}) -> Dictionary:
	var profile: Dictionary = profile_value if profile_value is Dictionary else {}
	var front_catalog: Dictionary = catalogs.get("fronts", {}) if catalogs.get("fronts") is Dictionary else {}
	var heart_catalog: Dictionary = catalogs.get("castle_hearts", {}) if catalogs.get("castle_hearts") is Dictionary else {}
	var link_catalog: Dictionary = catalogs.get("duo_links", {}) if catalogs.get("duo_links") is Dictionary else {}
	var fronts_progress: Dictionary = profile.get("fronts", {})
	var hearts_progress: Dictionary = profile.get("hearts", {})
	var link_progress: Dictionary = profile.get("duo_links", {})
	var result := {
		"fronts": [], "hearts": [], "rivals": [], "links": [],
		"recent_runs": normalize_recent_runs(profile.get("recent_run_summaries", [])),
		"epilogues": [], "goals": evaluate_goals(profile, goals),
		"final_nameplate_unlocked": bool(profile.get("chronicle_final_nameplate", false))
	}
	for front_id in FRONT_ORDER:
		var definition: Dictionary = front_catalog.get(front_id, {})
		var unlocked: bool = fronts_progress.get("unlocked", []).has(front_id)
		result["fronts"].append({
			"id": front_id, "name": str(definition.get("display_name", front_id)),
			"unlocked": unlocked, "mastery": int(fronts_progress.get("mastery", {}).get(front_id, 0)),
			"clear_count": int(fronts_progress.get("clear_counts", {}).get(front_id, 0)),
			"lock_hint": "" if unlocked else front_lock_hint(front_id)
		})
		var epilogue: Dictionary = definition.get("epilogue_card", {})
		var epilogue_id := str(epilogue.get("id", ""))
		result["epilogues"].append({
			"id": epilogue_id, "title": str(epilogue.get("title", epilogue_id)),
			"text": str(epilogue.get("text", "")),
			"unlocked": fronts_progress.get("epilogues_seen", []).has(epilogue_id),
			"lock_hint": "해당 전선 DAY 30 클리어" if not fronts_progress.get("epilogues_seen", []).has(epilogue_id) else ""
		})
	for heart_id in HEART_ORDER:
		var definition: Dictionary = heart_catalog.get(heart_id, {})
		var unlocked: bool = hearts_progress.get("unlocked", []).has(heart_id)
		result["hearts"].append({
			"id": heart_id, "name": str(definition.get("display_name", heart_id)),
			"unlocked": unlocked, "mastery": int(hearts_progress.get("mastery", {}).get(heart_id, 0)),
			"lock_hint": "새 회차 심장 선택에서 해금" if not unlocked else ""
		})
	for rival_id in RIVAL_ORDER:
		var relation := int(profile.get("rival_relations", {}).get(rival_id, 0))
		result["rivals"].append({
			"id": rival_id, "name": str(RIVAL_NAMES.get(rival_id, rival_id)), "relation": relation,
			"lock_hint": "관계 45에서 전선 해금" if relation < 45 and rival_id != "leon" else ("관계 사건에서 상승" if relation < 100 else "최대 관계")
		})
	for link_id_value in link_catalog.keys():
		var link_id := str(link_id_value)
		var definition: Dictionary = link_catalog.get(link_id, {})
		var unlocked: bool = link_progress.get("unlocked", []).has(link_id)
		result["links"].append({
			"id": link_id, "name": str(definition.get("display_name", link_id)),
			"unlocked": unlocked,
			"memory_seen": link_progress.get("memory_events_seen", []).has(str(definition.get("unlock_condition", {}).get("event_id", ""))),
			"lock_hint": "" if unlocked else duo_lock_hint(definition)
		})
	result["links"].sort_custom(func(a: Dictionary, b: Dictionary): return str(a.get("id", "")) < str(b.get("id", "")))
	return result


static func evaluate_goals(profile_value, goals: Dictionary) -> Array:
	var result: Array = []
	var profile: Dictionary = profile_value if profile_value is Dictionary else {}
	for goal_id_value in goals.keys():
		var goal_id := str(goal_id_value)
		var goal: Dictionary = goals.get(goal_id, {})
		var progress := _goal_progress(profile, str(goal.get("goal_type", "")), str(goal.get("target_id", "")))
		var threshold := maxi(1, int(goal.get("threshold", 1)))
		result.append({
			"id": goal_id, "title": str(goal.get("title", goal_id)), "progress": progress,
			"threshold": threshold, "complete": progress >= threshold,
			"reward_ids": goal.get("reward_ids", []).duplicate(),
			"lock_hint": str(goal.get("lock_hint", ""))
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.get("id", "")) < str(b.get("id", "")))
	return result


static func front_lock_hint(front_id: String) -> String:
	match front_id:
		"front_holy_purification":
			return "셀렌 관계 45 · 관련 엔딩/교리 격파 · 첫 초대장 중 하나"
		"front_guild_repossession":
			return "로만 관계 45 · 관련 엔딩/교리 격파 · 첫 초대장 중 하나"
		_:
			return "기본 전선"


static func duo_lock_hint(definition: Dictionary) -> String:
	var condition: Dictionary = definition.get("unlock_condition", {})
	return "유대 각 %d · 개인 기억 각 %d · %d일 동시 출전 · 역할 합동 %d회 · 합동 기억 확인" % [
		int(condition.get("bond_each", 45)), int(condition.get("personal_memory_each", 1)),
		int(condition.get("deployed_together_days", 3)), int(condition.get("role_combo_count", 5))
	]


static func has_numeric_rewards(goals: Dictionary) -> bool:
	for goal_value in goals.values():
		if not (goal_value is Dictionary):
			continue
		for reward_value in goal_value.get("reward_ids", []):
			var reward_id := str(reward_value)
			if reward_id.begins_with("stat_") or reward_id.begins_with("resource_") or reward_id.begins_with("combat_"):
				return true
	return false


static func _goal_progress(profile: Dictionary, goal_type: String, target_id: String) -> int:
	match goal_type:
		"front_mastery":
			return int(profile.get("fronts", {}).get("mastery", {}).get(target_id, 0))
		"heart_mastery":
			return int(profile.get("hearts", {}).get("mastery", {}).get(target_id, 0))
		"rival_relation":
			return int(profile.get("rival_relations", {}).get(target_id, 0))
		"duo_memory":
			return 1 if profile.get("duo_links", {}).get("unlocked", []).has(target_id) else 0
		"recent_runs":
			return normalize_recent_runs(profile.get("recent_run_summaries", [])).size()
		"epilogue":
			return 1 if profile.get("fronts", {}).get("epilogues_seen", []).has(target_id) else 0
	return 0
