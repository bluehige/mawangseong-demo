extends RefCounted
class_name FrontCampaignService

const HERO_FRONT_ID := "front_hero_oath"
const HOLY_FRONT_ID := "front_holy_purification"
const GUILD_FRONT_ID := "front_guild_repossession"
const ALTERNATE_FRONT_IDS := [HOLY_FRONT_ID, GUILD_FRONT_ID]


static func default_profile_progress() -> Dictionary:
	return {
		"unlocked": [HERO_FRONT_ID],
		"clear_counts": {},
		"mastery": {},
		"epilogues_seen": [],
		"invitation_pending": true,
		"invitation_choice": ""
	}


static func default_update3_profile() -> Dictionary:
	return {
		"fronts": default_profile_progress(),
		"hearts": {
			"unlocked": ["heart_stonebone", "heart_hungry_maw", "heart_dream_lantern"],
			"mastery": {},
			"records": {},
			"cosmetics": []
		},
		"duo_links": {"unlocked": [], "usage_counts": {}, "first_use_cycle": {}, "memory_events_seen": []},
		"rival_relations": {"leon": 0, "selen": 0, "roman": 0},
		"update3_endings_seen": [],
		"unlocked_reward_ids": [],
		"guaranteed_contract_instance_ids": [],
		"joint_boundary_event_ids": [],
		"contract_board_free_refreshes": 0,
		"heart_voice_records": [],
		"heart_selection_flair_ids": [],
		"duo_link_preset_slots": 0,
		"duo_link_presets": [],
		"duo_link_auto_recommendation_unlocked": false,
		"front_rotation_unlocked": false,
		"front_rotation_enabled": false,
		"chronicle_final_nameplate": false,
		"recent_run_summaries": []
	}


static func default_legacy_active_run(cycle_index: int = 1) -> Dictionary:
	return {
		"cycle_index": maxi(1, cycle_index),
		"update3_enabled": false,
		"new_cycle_selection_pending": false,
		"front_selection_completed": false,
		"front_id": "front_hero_oath_legacy",
		"heart": _empty_heart(),
		"heart_event_candidate_id": "",
		"equipped_duo_links": [],
		"duo_link_loadout_confirmed": false,
		"duo_link_states": {},
		"duo_link_auto_use": false,
		"duo_link_active_effects": [],
		"duo_link_inactive_count": 0,
		"front_flags": {},
		"day28_front_operation": "",
		"rival_finale": {"rival_id": "leon", "phase_state": {}, "retry_seed": 0},
		"run_metrics_update3": {}
	}


static func new_cycle_active_run(cycle_index: int) -> Dictionary:
	var result := default_legacy_active_run(cycle_index)
	result["new_cycle_selection_pending"] = true
	result["front_id"] = ""
	result["rival_finale"] = _empty_rival()
	return result


static func normalize_active_run(value, cycle_index: int = 1) -> Dictionary:
	var result := default_legacy_active_run(cycle_index)
	if not (value is Dictionary):
		return result
	for key in result.keys():
		if value.has(key) and typeof(value.get(key)) == typeof(result.get(key)):
			result[key] = value.get(key).duplicate(true) if value.get(key) is Dictionary or value.get(key) is Array else value.get(key)
	var normalized_heart := _empty_heart()
	var saved_heart = value.get("heart", {})
	if saved_heart is Dictionary:
		for key in normalized_heart.keys():
			if saved_heart.has(key) and typeof(saved_heart.get(key)) == typeof(normalized_heart.get(key)):
				normalized_heart[key] = saved_heart.get(key).duplicate(true) if saved_heart.get(key) is Dictionary else saved_heart.get(key)
	result["heart"] = normalized_heart
	result["heart_event_candidate_id"] = str(value.get("heart_event_candidate_id", result.get("heart_event_candidate_id", "")))
	result["cycle_index"] = maxi(1, int(value.get("cycle_index", cycle_index)))
	return result


static func normalize_update3_profile(value) -> Dictionary:
	var result := default_update3_profile()
	if not (value is Dictionary):
		return result
	for key in result.keys():
		if value.has(key) and typeof(value.get(key)) == typeof(result.get(key)):
			result[key] = value.get(key).duplicate(true) if value.get(key) is Dictionary or value.get(key) is Array else value.get(key)
	result["fronts"] = _normalize_front_progress(result.get("fronts", {}))
	result["hearts"] = _normalize_heart_progress(result.get("hearts", {}))
	result["rival_relations"] = _normalize_relations(result.get("rival_relations", {}))
	result["recent_run_summaries"] = _normalize_recent_runs(result.get("recent_run_summaries", []))
	return result


static func record_front_clear(profile_value, active_run_value, catalog: Dictionary) -> Dictionary:
	var profile := normalize_update3_profile(profile_value)
	if not (active_run_value is Dictionary):
		return profile
	var front_id := str(active_run_value.get("front_id", ""))
	if front_id == "" or not catalog.has(front_id):
		return profile
	var fronts: Dictionary = profile.get("fronts", {}).duplicate(true)
	var clear_counts: Dictionary = fronts.get("clear_counts", {}).duplicate(true)
	clear_counts[front_id] = int(clear_counts.get(front_id, 0)) + 1
	fronts["clear_counts"] = clear_counts
	var mastery: Dictionary = fronts.get("mastery", {}).duplicate(true)
	mastery[front_id] = mini(100, int(clear_counts[front_id]) * 34)
	if int(clear_counts[front_id]) >= 3:
		mastery[front_id] = 100
	fronts["mastery"] = mastery
	var epilogue: Dictionary = catalog.get(front_id, {}).get("epilogue_card", {})
	var epilogue_id := str(epilogue.get("id", ""))
	var seen: Array = fronts.get("epilogues_seen", []).duplicate()
	if epilogue_id != "" and not seen.has(epilogue_id):
		seen.append(epilogue_id)
	fronts["epilogues_seen"] = seen
	profile["fronts"] = fronts
	return profile


static func apply_ending_rewards(profile_value, active_run_value, ending_id: String, ending_catalog: Dictionary) -> Dictionary:
	var profile := normalize_update3_profile(profile_value)
	if ending_id == "" or not ending_catalog.has(ending_id):
		return profile
	var seen: Array = profile.get("update3_endings_seen", []).duplicate()
	var first_unlock := not seen.has(ending_id)
	if first_unlock:
		seen.append(ending_id)
	profile["update3_endings_seen"] = seen
	if not first_unlock:
		return profile
	var reward_ids: Array = profile.get("unlocked_reward_ids", []).duplicate()
	for reward_id_value in ending_catalog.get(ending_id, {}).get("reward_ids", []):
		var reward_id := str(reward_id_value)
		if reward_id != "" and not reward_ids.has(reward_id):
			reward_ids.append(reward_id)
	profile["unlocked_reward_ids"] = reward_ids
	match ending_id:
		"ending_holy_open_gate":
			_append_unique(profile["guaranteed_contract_instance_ids"], "monster_bebe")
			_append_unique(profile["joint_boundary_event_ids"], "event_joint_boundary_inspection")
			_append_unique(profile["joint_boundary_event_ids"], "event_joint_boundary_patrol")
		"ending_off_ledger_independence":
			_append_unique(profile["guaranteed_contract_instance_ids"], "monster_toktok")
			profile["contract_board_free_refreshes"] = int(profile.get("contract_board_free_refreshes", 0)) + 1
		"ending_living_castle_voice":
			var heart_id := str(active_run_value.get("heart", {}).get("heart_id", "")) if active_run_value is Dictionary else ""
			if heart_id != "":
				var hearts: Dictionary = profile.get("hearts", {}).duplicate(true)
				var cosmetics: Array = hearts.get("cosmetics", []).duplicate()
				_append_unique(cosmetics, "%s_mastery_voice" % heart_id)
				hearts["cosmetics"] = cosmetics
				profile["hearts"] = hearts
				_append_unique(profile["heart_voice_records"], heart_id)
				_append_unique(profile["heart_selection_flair_ids"], heart_id)
		"ending_linked_corridors":
			profile["duo_link_preset_slots"] = 2
			var presets: Array = profile.get("duo_link_presets", []).duplicate(true)
			while presets.size() < 2:
				presets.append([])
			profile["duo_link_presets"] = presets
			profile["duo_link_auto_recommendation_unlocked"] = true
		"ending_three_front_armistice":
			var fronts: Dictionary = profile.get("fronts", {}).duplicate(true)
			var unlocked: Array = fronts.get("unlocked", []).duplicate()
			for front_id in [HERO_FRONT_ID, HOLY_FRONT_ID, GUILD_FRONT_ID]:
				_append_unique(unlocked, front_id)
			fronts["unlocked"] = unlocked
			fronts["invitation_pending"] = false
			profile["fronts"] = fronts
			profile["front_rotation_unlocked"] = true
			profile["front_rotation_enabled"] = false
			profile["chronicle_final_nameplate"] = true
	return profile


static func armistice_profile_eligible(profile_value) -> bool:
	var profile := normalize_update3_profile(profile_value)
	var clears: Dictionary = profile.get("fronts", {}).get("clear_counts", {})
	var relations: Dictionary = profile.get("rival_relations", {})
	var seen: Array = profile.get("update3_endings_seen", [])
	return (
		int(clears.get(HERO_FRONT_ID, 0)) >= 1
		and int(clears.get(HOLY_FRONT_ID, 0)) >= 1
		and int(clears.get(GUILD_FRONT_ID, 0)) >= 1
		and int(relations.get("leon", 0)) >= 65
		and int(relations.get("selen", 0)) >= 65
		and int(relations.get("roman", 0)) >= 65
		and seen.has("ending_holy_open_gate")
		and seen.has("ending_off_ledger_independence")
	)


static func reconcile_unlocks(profile_value, catalog: Dictionary) -> Dictionary:
	var profile := normalize_update3_profile(profile_value)
	var fronts: Dictionary = profile.get("fronts", {})
	var unlocked: Array = fronts.get("unlocked", []).duplicate()
	_append_known_front(unlocked, HERO_FRONT_ID, catalog)
	var relations: Dictionary = profile.get("rival_relations", {})
	var ending_codes := _ending_code_set(profile_value)
	var defeated_doctrines := _defeated_doctrine_set(profile_value)
	if int(relations.get("selen", 0)) >= 45 or ending_codes.has("E04") or ending_codes.has("E09") or defeated_doctrines.has("purification_crusade") or defeated_doctrines.has("doctrine_holy_purification"):
		_append_known_front(unlocked, HOLY_FRONT_ID, catalog)
	if int(relations.get("roman", 0)) >= 45 or ending_codes.has("E05") or ending_codes.has("E08") or defeated_doctrines.has("facility_assault") or defeated_doctrines.has("treasure_pressure"):
		_append_known_front(unlocked, GUILD_FRONT_ID, catalog)
	var clear_counts: Dictionary = fronts.get("clear_counts", {})
	if int(clear_counts.get(HOLY_FRONT_ID, 0)) >= 1:
		_append_known_front(unlocked, GUILD_FRONT_ID, catalog)
	if int(clear_counts.get(GUILD_FRONT_ID, 0)) >= 1:
		_append_known_front(unlocked, HOLY_FRONT_ID, catalog)
	fronts["unlocked"] = unlocked
	if unlocked.has(HOLY_FRONT_ID) or unlocked.has(GUILD_FRONT_ID):
		fronts["invitation_pending"] = false
	profile["fronts"] = fronts
	return profile


static func selectable_front_ids(profile_value, catalog: Dictionary) -> Array[String]:
	var profile := reconcile_unlocks(profile_value, catalog)
	var result: Array[String] = []
	for front_id_value in catalog.keys():
		var front_id := str(front_id_value)
		if profile.get("fronts", {}).get("unlocked", []).has(front_id):
			result.append(front_id)
	result.sort()
	if result.has(HERO_FRONT_ID):
		result.erase(HERO_FRONT_ID)
		result.push_front(HERO_FRONT_ID)
	return result


static func invitation_required(profile_value, catalog: Dictionary) -> bool:
	var profile := normalize_update3_profile(profile_value)
	var fronts: Dictionary = profile.get("fronts", {})
	if not bool(fronts.get("invitation_pending", false)):
		return false
	var unlocked: Array = fronts.get("unlocked", [])
	return catalog.has(HOLY_FRONT_ID) and catalog.has(GUILD_FRONT_ID) and not unlocked.has(HOLY_FRONT_ID) and not unlocked.has(GUILD_FRONT_ID)


static func apply_invitation(profile_value, front_id: String, catalog: Dictionary) -> Dictionary:
	var profile := normalize_update3_profile(profile_value)
	if not invitation_required(profile, catalog) or not front_id in ALTERNATE_FRONT_IDS or not catalog.has(front_id):
		return {"ok": false, "error": "선택할 수 없는 3차 초대장입니다.", "profile": profile}
	var fronts: Dictionary = profile.get("fronts", {})
	var unlocked: Array = fronts.get("unlocked", []).duplicate()
	if not unlocked.has(front_id):
		unlocked.append(front_id)
	fronts["unlocked"] = unlocked
	fronts["invitation_pending"] = false
	fronts["invitation_choice"] = front_id
	profile["fronts"] = fronts
	return {"ok": true, "error": "", "profile": profile}


static func lock_reason(profile_value, front_id: String, catalog: Dictionary) -> String:
	if not catalog.has(front_id):
		return "존재하지 않는 전선"
	var profile := reconcile_unlocks(profile_value, catalog)
	if profile.get("fronts", {}).get("unlocked", []).has(front_id):
		return ""
	if front_id == HOLY_FRONT_ID:
		return "셀렌 관계 45 또는 관련 엔딩·초대장 필요"
	if front_id == GUILD_FRONT_ID:
		return "로만 관계 45 또는 관련 엔딩·소환장 필요"
	return "해금 조건을 충족하지 못함"


static func select_front(profile_value, active_run_value, front_id: String, catalog: Dictionary) -> Dictionary:
	var profile := reconcile_unlocks(profile_value, catalog)
	if front_id == "" or not catalog.has(front_id):
		return {"ok": false, "error": "잘못된 전선 ID입니다: %s" % front_id, "profile": profile, "active_run": active_run_value}
	if not profile.get("fronts", {}).get("unlocked", []).has(front_id):
		return {"ok": false, "error": lock_reason(profile, front_id, catalog), "profile": profile, "active_run": active_run_value}
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else new_cycle_active_run(1)
	active_run["update3_enabled"] = false
	active_run["new_cycle_selection_pending"] = false
	active_run["front_selection_completed"] = true
	active_run["front_id"] = front_id
	active_run["heart"] = _empty_heart()
	active_run["heart_event_candidate_id"] = ""
	active_run["equipped_duo_links"] = []
	active_run["duo_link_loadout_confirmed"] = false
	active_run["duo_link_states"] = {}
	active_run["duo_link_auto_use"] = false
	active_run["duo_link_active_effects"] = []
	active_run["duo_link_inactive_count"] = 0
	active_run["front_flags"] = {}
	active_run["day28_front_operation"] = ""
	active_run["rival_finale"] = {
		"rival_id": str(catalog.get(front_id, {}).get("final_rival_id", "")),
		"phase_state": {},
		"retry_seed": 0
	}
	active_run["run_metrics_update3"] = {}
	return {"ok": true, "error": "", "profile": profile, "active_run": active_run}


static func overlay_day_entry(active_run_value, day: int, fronts: Dictionary, overlays: Dictionary) -> Dictionary:
	if day < 1 or not (active_run_value is Dictionary):
		return {}
	var active_run: Dictionary = active_run_value
	if not bool(active_run.get("update3_enabled", false)):
		return {}
	var front_id := str(active_run.get("front_id", ""))
	var overlay_id := str(fronts.get(front_id, {}).get("day_overlay_id", ""))
	var overlay: Dictionary = overlays.get(overlay_id, {})
	if str(overlay.get("front_id", "")) != front_id:
		return {}
	var days: Dictionary = overlay.get("days", {})
	var entry = days.get(str(day), {})
	return entry.duplicate(true) if entry is Dictionary else {}


static func day_defense_modifier(active_run_value, day: int, fronts: Dictionary, overlays: Dictionary) -> Dictionary:
	var entry := overlay_day_entry(active_run_value, day, fronts, overlays)
	var modifier = entry.get("wave_modifier", {})
	return modifier.duplicate(true) if modifier is Dictionary else {}


static func operation_choices(active_run_value, day: int, operations: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if not (active_run_value is Dictionary):
		return result
	var front_id := str(active_run_value.get("front_id", ""))
	for operation_id_value in operations.keys():
		var operation_id := str(operation_id_value)
		var operation: Dictionary = operations.get(operation_id, {})
		if str(operation.get("front_id", "")) == front_id and int(operation.get("day", 0)) == day:
			result.append(operation_id)
	result.sort()
	return result


static func select_operation(active_run_value, operation_id: String, day: int, operations: Dictionary) -> Dictionary:
	var active_run: Dictionary = normalize_active_run(active_run_value)
	if not bool(active_run.get("update3_enabled", false)):
		return {"ok": false, "error": "3차 전선과 심장이 확정되지 않았습니다.", "active_run": active_run}
	if str(active_run.get("day28_front_operation", "")) != "":
		return {"ok": false, "error": "이미 DAY 28 전선 작전을 선택했습니다.", "active_run": active_run}
	var operation: Dictionary = operations.get(operation_id, {})
	if operation.is_empty() or str(operation.get("front_id", "")) != str(active_run.get("front_id", "")) or int(operation.get("day", 0)) != day:
		return {"ok": false, "error": "현재 전선과 DAY에서 선택할 수 없는 작전입니다.", "active_run": active_run}
	active_run["day28_front_operation"] = operation_id
	var flags: Dictionary = active_run.get("front_flags", {}).duplicate(true)
	flags["day28_operation_selected"] = true
	flags["day28_operation_id"] = operation_id
	active_run["front_flags"] = flags
	return {"ok": true, "error": "", "active_run": active_run, "operation": operation.duplicate(true), "reward": operation.get("reward", {}).duplicate(true)}


static func selected_operation_modifier(active_run_value, day: int, operations: Dictionary) -> Dictionary:
	if not (active_run_value is Dictionary):
		return {}
	var operation_id := str(active_run_value.get("day28_front_operation", ""))
	var operation: Dictionary = operations.get(operation_id, {})
	if operation.is_empty() or str(operation.get("front_id", "")) != str(active_run_value.get("front_id", "")):
		return {}
	var modifier: Dictionary = operation.get("defense_modifier", {})
	if int(modifier.get("apply_on_day", 0)) != day:
		return {}
	return modifier.duplicate(true)


static func event_definition(event_id: String, events: Dictionary) -> Dictionary:
	var definition = events.get(event_id, {})
	return definition.duplicate(true) if definition is Dictionary else {}


static func selected_heart_event(active_run_value, entry: Dictionary, events: Dictionary) -> Dictionary:
	if not bool(entry.get("heart_event", false)) or not (active_run_value is Dictionary):
		return {}
	var event_id := str(active_run_value.get("heart_event_candidate_id", ""))
	var event: Dictionary = event_definition(event_id, events)
	if str(event.get("kind", "")) != "heart_event":
		return {}
	return event


static func mark_day_content_seen(active_run_value, day: int, event_ids: Array = []) -> Dictionary:
	var active_run: Dictionary = normalize_active_run(active_run_value)
	var flags: Dictionary = active_run.get("front_flags", {}).duplicate(true)
	flags["day_%d_overlay_seen" % day] = true
	for event_id_value in event_ids:
		flags["event_%s_seen" % str(event_id_value)] = true
	active_run["front_flags"] = flags
	return active_run


static func day_content_seen(active_run_value, day: int) -> bool:
	return active_run_value is Dictionary and bool(active_run_value.get("front_flags", {}).get("day_%d_overlay_seen" % day, false))


static func apply_event_choice(profile_value, active_run_value, event_id: String, choice_id: String, day: int, events: Dictionary) -> Dictionary:
	var profile := normalize_update3_profile(profile_value)
	var active_run := normalize_active_run(active_run_value)
	var event: Dictionary = event_definition(event_id, events)
	var event_kind := str(event.get("kind", ""))
	var event_front_matches := str(event.get("front_id", "")) == str(active_run.get("front_id", "")) or event_kind in ["heart_event", "duo_memory"]
	var event_day_matches := int(event.get("day", 0)) == day or (event_kind == "duo_memory" and int(event.get("day", 0)) == 0)
	if event.is_empty() or not event_front_matches or not event_day_matches:
		return {"ok": false, "error": "현재 전선과 DAY에서 발생할 수 없는 사건입니다.", "profile": profile, "active_run": active_run}
	var flags: Dictionary = active_run.get("front_flags", {}).duplicate(true)
	var choice_flag := "event_%s_choice" % event_id
	if str(flags.get(choice_flag, "")) != "":
		return {"ok": false, "error": "이미 선택을 완료한 사건입니다.", "profile": profile, "active_run": active_run}
	var selected_choice: Dictionary = {}
	for choice_value in event.get("choices", []):
		if choice_value is Dictionary and str(choice_value.get("id", "")) == choice_id:
			selected_choice = choice_value
			break
	if selected_choice.is_empty():
		return {"ok": false, "error": "사건 선택지를 찾을 수 없습니다.", "profile": profile, "active_run": active_run}
	var effects: Dictionary = selected_choice.get("effects", {}).duplicate(true)
	var relations: Dictionary = profile.get("rival_relations", {}).duplicate(true)
	if effects.has("relation_selen"):
		relations["selen"] = clampi(int(relations.get("selen", 0)) + int(effects.get("relation_selen", 0)), 0, 100)
	if effects.has("relation_roman"):
		relations["roman"] = clampi(int(relations.get("roman", 0)) + int(effects.get("relation_roman", 0)), 0, 100)
	profile["rival_relations"] = relations
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	for effect_key_value in effects.keys():
		var effect_key := str(effect_key_value)
		if effect_key.begins_with("metric_"):
			metrics[effect_key.trim_prefix("metric_")] = int(metrics.get(effect_key.trim_prefix("metric_"), 0)) + int(effects[effect_key])
	active_run["run_metrics_update3"] = metrics
	flags[choice_flag] = choice_id
	flags["event_%s_seen" % event_id] = true
	active_run["front_flags"] = flags
	return {"ok": true, "error": "", "profile": profile, "active_run": active_run, "choice": selected_choice.duplicate(true), "effects": effects}


static func _normalize_front_progress(value) -> Dictionary:
	var result := default_profile_progress()
	if value is Dictionary:
		for key in result.keys():
			if value.has(key) and typeof(value.get(key)) == typeof(result.get(key)):
				result[key] = value.get(key).duplicate(true) if value.get(key) is Dictionary or value.get(key) is Array else value.get(key)
	var unlocked: Array = []
	for front_id_value in result.get("unlocked", []):
		var front_id := str(front_id_value)
		if front_id != "" and not unlocked.has(front_id):
			unlocked.append(front_id)
	if not unlocked.has(HERO_FRONT_ID):
		unlocked.push_front(HERO_FRONT_ID)
	result["unlocked"] = unlocked
	return result


static func _normalize_heart_progress(value) -> Dictionary:
	var result: Dictionary = default_update3_profile()["hearts"].duplicate(true)
	if value is Dictionary:
		for key in result.keys():
			if value.has(key) and typeof(value.get(key)) == typeof(result.get(key)):
				result[key] = value.get(key).duplicate(true) if value.get(key) is Dictionary or value.get(key) is Array else value.get(key)
	var unlocked: Array = []
	for heart_id_value in result.get("unlocked", []):
		var heart_id := str(heart_id_value)
		if heart_id != "" and not unlocked.has(heart_id):
			unlocked.append(heart_id)
	result["unlocked"] = unlocked
	return result


static func _normalize_relations(value) -> Dictionary:
	var result := {"leon": 0, "selen": 0, "roman": 0}
	if value is Dictionary:
		for rival_id in result.keys():
			result[rival_id] = clampi(int(value.get(rival_id, 0)), 0, 100)
	return result


static func _normalize_recent_runs(value) -> Array:
	var result: Array = []
	if value is Array:
		for entry in value:
			if entry is Dictionary and int(entry.get("cycle_index", 0)) > 0:
				result.append(entry.duplicate(true))
	while result.size() > 5:
		result.pop_front()
	return result


static func _ending_code_set(profile_value) -> Dictionary:
	var result: Dictionary = {}
	if not (profile_value is Dictionary):
		return result
	for code_value in profile_value.get("update3_endings_seen", []):
		var ending_value := str(code_value)
		result[ending_value] = true
		match ending_value:
			"ending_holy_open_gate": result["E12"] = true
			"ending_off_ledger_independence": result["E13"] = true
			"ending_living_castle_voice": result["E14"] = true
			"ending_linked_corridors": result["E15"] = true
			"ending_three_front_armistice": result["E16"] = true
	for code_value in profile_value.get("ending_catalog_codes", {}).values():
		result[str(code_value)] = true
	return result


static func _defeated_doctrine_set(profile_value) -> Dictionary:
	var result: Dictionary = {}
	if not (profile_value is Dictionary):
		return result
	for doctrine_id_value in profile_value.get("defeated_doctrine_ids", []):
		result[str(doctrine_id_value)] = true
	for history_value in profile_value.get("doctrine_history", []):
		if history_value is Dictionary:
			var doctrine_id := str(history_value.get("doctrine_id", ""))
			if doctrine_id != "":
				result[doctrine_id] = true
	return result


static func _append_known_front(values: Array, front_id: String, catalog: Dictionary) -> void:
	if catalog.has(front_id) and not values.has(front_id):
		values.append(front_id)


static func _append_unique(values: Array, value: String) -> void:
	if value != "" and not values.has(value):
		values.append(value)


static func _empty_heart() -> Dictionary:
	return {
		"heart_id": "", "awakened": false, "awakened_day": 0,
		"chamber_spawned": false, "chamber_hp": 0, "chamber_max_hp": 0, "disabled_this_battle": false,
		"charge": 0, "active_used_this_battle": false, "active_remaining": 0.0,
		"room_shields": {}, "battle_charge_dedupe": {}, "battle_id": "",
		"hunger": 0, "hunger_waves": 0, "hunger_finish_ids": {}, "hungry_damage_tokens": {},
		"hungry_infamy_earned": 0, "active_room_id": "", "active_tick_accumulator": 0.0,
		"last_upkeep_day": 0, "dream_charge_dedupe": {}, "false_corridor_targets": {},
		"dream_base_throne_max_hp": 0, "dream_adjusted_throne_max_hp": 0
	}


static func _empty_rival() -> Dictionary:
	return {"rival_id": "", "phase_state": {}, "retry_seed": 0}
