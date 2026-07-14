extends RefCounted
class_name CouncilEndingService

const EndingEvaluatorScript = preload("res://scripts/systems/endings/EndingConditionEvaluator.gd")
const RIVAL_IDS := ["rival_brassa", "rival_vesper", "rival_mirella"]
const LOCAL_FALLBACK_ID := "council_legacy_fallback"


static func build_metrics(active_run_value, profile_value = {}, day30_context_value = {}) -> Dictionary:
	var active_run: Dictionary = active_run_value if active_run_value is Dictionary else {}
	var profile: Dictionary = profile_value if profile_value is Dictionary else {}
	var context: Dictionary = day30_context_value if day30_context_value is Dictionary else {}
	var council: Dictionary = active_run.get("council_season", {})
	var upper: Dictionary = active_run.get("upper_floor", {})
	var crown: Dictionary = active_run.get("crown", {})
	var stored_root: Dictionary = active_run.get("run_metrics_update4", {})
	var stored: Dictionary = stored_root.get("ending", stored_root)
	var promise_count := int(council.get("agenda_promise_violations", council.get("promise_violations", []).size()))
	var relation_min := 100
	for rival_id in RIVAL_IDS:
		relation_min = mini(relation_min, int(council.get("rival_relations", {}).get(rival_id, -100)))
	var metrics := {
		"update4.final_battle_won": bool(_pick(context, stored, "final_battle_won", false)),
		"update4.council_votes": int(_pick(context, council, "council_votes", 0)),
		"update4.council_seals": int(_pick(context, council, "council_seals", 0)),
		"update4.rival_relation_min": int(_pick(context, stored, "rival_relation_min", relation_min)),
		"update4.agenda_promise_violations": int(_pick(context, stored, "agenda_promise_violations", promise_count)),
		"update4.outpost_day20_survived": bool(_pick(context, stored, "outpost_day20_survived", _day20_survived(active_run.get("outpost", {})))),
		"update4.upper_floor_integrity": float(_pick(context, stored, "upper_floor_integrity", upper.get("integrity", 0.0))),
		"update4.crown_room_disable_count_since_day16": int(_pick(context, stored, "crown_room_disable_count_since_day16", 0)),
		"update4.seal_theft_completed": int(_pick(context, stored, "seal_theft_completed", upper.get("seal_theft_count", 0))),
		"update4.day30_upper_floor_contribution_ratio": float(_pick(context, stored, "day30_upper_floor_contribution_ratio", 0.0)),
		"update4.day30_lower_survivor_count": int(_pick(context, stored, "day30_lower_survivor_count", 0)),
		"update4.day30_upper_survivor_count": int(_pick(context, stored, "day30_upper_survivor_count", 0)),
		"update4.crown_evolution_used": bool(_pick(context, stored, "crown_evolution_used", str(crown.get("crown_form_id", "")) != "")),
		"update4.crown_monster_bond": float(_pick(context, stored, "crown_monster_bond", 0.0)),
		"update4.day30_crown_monster_survived": bool(_pick(context, stored, "day30_crown_monster_survived", false)),
		"update4.day30_crown_contribution_ratio": float(_pick(context, stored, "day30_crown_contribution_ratio", 0.0)),
		"update4.day30_other_contributors_eight_percent": int(_pick(context, stored, "day30_other_contributors_eight_percent", 0)),
		"decision.day29": str(_pick(context, stored, "day29_decision_id", council.get("day29_decision_id", ""))),
		"profile.catalog_count": int(profile.get("update4_endings_seen", []).size())
	}
	return metrics


static func resolve(active_run_value, profile_value, day30_context_value, ending_catalog: Dictionary) -> Dictionary:
	var metrics := build_metrics(active_run_value, profile_value, day30_context_value)
	var result := EndingEvaluatorScript.resolve(_runtime_rules(ending_catalog), metrics)
	result["metrics"] = metrics
	return result


static func apply_rewards(profile_value, active_run_value, ending_id: String, ending_catalog: Dictionary) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	if ending_id == LOCAL_FALLBACK_ID or not ending_catalog.has(ending_id):
		return profile
	var ending: Dictionary = ending_catalog.get(ending_id, {})
	var seen: Array = profile.get("update4_endings_seen", []).duplicate()
	var first_unlock := not seen.has(ending_id)
	_append_unique(seen, ending_id)
	profile["update4_endings_seen"] = seen
	var catalog_codes: Dictionary = profile.get("ending_catalog_codes", {}).duplicate(true)
	catalog_codes[ending_id] = str(ending.get("catalog_code", ""))
	profile["ending_catalog_codes"] = catalog_codes
	if not first_unlock:
		return profile
	var reward_ids: Array = profile.get("unlocked_reward_ids", []).duplicate()
	for reward_id_value in ending.get("reward_ids", []):
		_append_unique(reward_ids, str(reward_id_value))
	profile["unlocked_reward_ids"] = reward_ids
	match ending_id:
		"ending_council_seat":
			var modes: Dictionary = profile.get("campaign_modes", {}).duplicate(true)
			modes["agenda_extra_preview_unlocked"] = true
			profile["campaign_modes"] = modes
			var cosmetics: Array = profile.get("cosmetic_ids", []).duplicate()
			_append_unique(cosmetics, "council_nameplate")
			profile["cosmetic_ids"] = cosmetics
		"ending_two_floors_one_throne":
			var cosmetics: Array = profile.get("cosmetic_ids", []).duplicate()
			_append_unique(cosmetics, "upper_floor_epilogue_layout")
			profile["cosmetic_ids"] = cosmetics
			var chronicle: Dictionary = profile.get("chronicle", {}).duplicate(true)
			chronicle["floor_detail_unlocked"] = true
			profile["chronicle"] = chronicle
		"ending_minion_wears_the_crown":
			var crown_profile: Dictionary = profile.get("crown_evolution", {}).duplicate(true)
			var epilogue_forms: Array = crown_profile.get("epilogue_form_ids", []).duplicate()
			var crown_form_id := str(active_run_value.get("crown", {}).get("crown_form_id", "")) if active_run_value is Dictionary else ""
			if crown_form_id != "":
				_append_unique(epilogue_forms, crown_form_id)
			crown_profile["epilogue_form_ids"] = epilogue_forms
			crown_profile["representative_portrait_unlocked"] = true
			profile["crown_evolution"] = crown_profile
	return profile


static func _runtime_rules(ending_catalog: Dictionary) -> Dictionary:
	var rules := {}
	for ending_id_value in ending_catalog.keys():
		var ending_id := str(ending_id_value)
		var source = ending_catalog.get(ending_id_value)
		if ending_id == "" or not (source is Dictionary):
			continue
		var rule: Dictionary = source.duplicate(true)
		rule["id"] = ending_id
		rule["fallback"] = false
		rule["requirements"] = rule.get("condition", {}).duplicate(true)
		rules[ending_id] = rule
	rules[LOCAL_FALLBACK_ID] = {
		"id": LOCAL_FALLBACK_ID,
		"display_name": "기존 결말",
		"fallback": true,
		"priority": -1,
		"base_score": 0,
		"requirements": {},
		"score_weights": {}
	}
	return rules


static func _pick(primary: Dictionary, secondary: Dictionary, key: String, default_value):
	if primary.has(key):
		return primary.get(key)
	if secondary.has(key):
		return secondary.get(key)
	return default_value


static func _day20_survived(outpost_value) -> bool:
	if not (outpost_value is Dictionary):
		return false
	if outpost_value.has("day20_survived"):
		return bool(outpost_value.get("day20_survived"))
	for result_value in outpost_value.get("battle_results", []):
		if result_value is Dictionary and int(result_value.get("day", 0)) == 20:
			return bool(result_value.get("survived", result_value.get("won", false)))
	return false


static func _append_unique(values: Array, value: String) -> void:
	if value != "" and not values.has(value):
		values.append(value)
