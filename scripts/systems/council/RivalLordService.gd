extends RefCounted
class_name RivalLordService

const RELATION_MIN := -100
const RELATION_MAX := 100
const HOSTILE_REPRESENTATIVE_THRESHOLD := -30
const ALLY_SUPPORT_THRESHOLD := 60


static func relation(active_run_value, rival_id: String) -> int:
	if not (active_run_value is Dictionary):
		return 0
	return clampi(int(active_run_value.get("council_season", {}).get("rival_relations", {}).get(rival_id, 0)), RELATION_MIN, RELATION_MAX)


static func set_relation(active_run_value, rival_id: String, value: int, catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if not catalog.has(rival_id):
		return {"ok": false, "error": "등록되지 않은 경쟁 마왕입니다: %s" % rival_id, "active_run": active_run}
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	var relations: Dictionary = council.get("rival_relations", {}).duplicate(true)
	relations[rival_id] = clampi(value, RELATION_MIN, RELATION_MAX)
	council["rival_relations"] = relations
	active_run["council_season"] = council
	return {"ok": true, "error": "", "active_run": active_run}


static func change_relation(active_run_value, rival_id: String, delta: int, catalog: Dictionary) -> Dictionary:
	return set_relation(active_run_value, rival_id, relation(active_run_value, rival_id) + delta, catalog)


static func relation_stage(value: int) -> String:
	var clamped := clampi(value, RELATION_MIN, RELATION_MAX)
	if clamped <= -61:
		return "hostile_challenger"
	if clamped <= -30:
		return "challenger"
	if clamped <= 29:
		return "neutral_rival"
	if clamped <= 59:
		return "respectful"
	return "council_ally"


static func validate_relations(active_run_value, catalog: Dictionary) -> String:
	if not (active_run_value is Dictionary):
		return "경쟁 마왕 회차 상태가 Dictionary가 아닙니다."
	var relations = active_run_value.get("council_season", {}).get("rival_relations", {})
	if not (relations is Dictionary):
		return "경쟁 마왕 관계 원장이 없습니다."
	for rival_id_value in catalog.keys():
		var rival_id := str(rival_id_value)
		if not relations.has(rival_id):
			return "경쟁 마왕 관계가 없습니다: %s" % rival_id
		var value = relations.get(rival_id)
		if not (value is int or value is float) or int(value) < RELATION_MIN or int(value) > RELATION_MAX:
			return "경쟁 마왕 관계는 -100~100이어야 합니다: %s" % rival_id
	return ""


static func representative_preview(active_run_value, catalog: Dictionary, cycle_seed: int) -> Dictionary:
	if not (active_run_value is Dictionary) or catalog.is_empty():
		return {}
	var council: Dictionary = active_run_value.get("council_season", {})
	var locked_id := str(council.get("final_representative_id", ""))
	if locked_id != "" and catalog.has(locked_id):
		return _representative_result(locked_id, "locked", support_candidate(active_run_value, catalog, locked_id, cycle_seed), true)
	var hostile: Array[String] = []
	var lowest := RELATION_MAX + 1
	for rival_id_value in catalog.keys():
		var rival_id := str(rival_id_value)
		var value := relation(active_run_value, rival_id)
		if value > HOSTILE_REPRESENTATIVE_THRESHOLD:
			continue
		if value < lowest:
			lowest = value
			hostile = [rival_id]
		elif value == lowest:
			hostile.append(rival_id)
	if not hostile.is_empty():
		var chosen := _seeded_choice(hostile, cycle_seed)
		return _representative_result(chosen, "lowest_relation", support_candidate(active_run_value, catalog, chosen, cycle_seed), false)
	var leaders: Array[String] = []
	var high_score := -2147483648
	for rival_id_value in catalog.keys():
		var rival_id := str(rival_id_value)
		var state: Dictionary = council.get("rival_states", {}).get(rival_id, {})
		var score := int(state.get("competitive_score", catalog.get(rival_id, {}).get("competitive_score", 0)))
		if score > high_score:
			high_score = score
			leaders = [rival_id]
		elif score == high_score:
			leaders.append(rival_id)
	var chosen := _seeded_choice(leaders, cycle_seed)
	return _representative_result(chosen, "competitive_score", support_candidate(active_run_value, catalog, chosen, cycle_seed), false)


static func lock_representative(active_run_value, catalog: Dictionary, cycle_seed: int) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var preview := representative_preview(active_run, catalog, cycle_seed)
	if preview.is_empty():
		return {"ok": false, "error": "대표 후보를 계산할 수 없습니다.", "active_run": active_run, "preview": {}}
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	council["final_representative_id"] = str(preview.get("rival_id", ""))
	council["final_representative_reason"] = str(preview.get("reason", ""))
	council["rival_support_id"] = str(preview.get("support_rival_id", ""))
	council["rival_support_used"] = false
	active_run["council_season"] = council
	preview["locked"] = true
	return {"ok": true, "error": "", "active_run": active_run, "preview": preview}


static func support_candidate(active_run_value, catalog: Dictionary, representative_id: String, cycle_seed: int) -> String:
	var candidates: Array[String] = []
	var highest := ALLY_SUPPORT_THRESHOLD - 1
	for rival_id_value in catalog.keys():
		var rival_id := str(rival_id_value)
		if rival_id == representative_id:
			continue
		var value := relation(active_run_value, rival_id)
		if value < ALLY_SUPPORT_THRESHOLD:
			continue
		if value > highest:
			highest = value
			candidates = [rival_id]
		elif value == highest:
			candidates.append(rival_id)
	return _seeded_choice(candidates, cycle_seed + 17) if not candidates.is_empty() else ""


static func recompute_competitive_scores(active_run_value, catalog: Dictionary, metrics: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	var states: Dictionary = council.get("rival_states", {}).duplicate(true)
	for rival_id_value in catalog.keys():
		var rival_id := str(rival_id_value)
		var state: Dictionary = states.get(rival_id, {}).duplicate(true)
		var rival_metrics: Dictionary = metrics.get(rival_id, {})
		var score := int(catalog[rival_id].get("competitive_score", 50))
		score += int(rival_metrics.get("region_wins", 0)) * 8
		score += int(rival_metrics.get("agenda_alignments", 0)) * 5
		score += int(rival_metrics.get("objective_pressure", 0)) * 3
		score += int(rival_metrics.get("preview_duel_wins", 0)) * 6
		state["competitive_score"] = score
		states[rival_id] = state
	council["rival_states"] = states
	active_run["council_season"] = council
	return active_run


static func day24_notice(active_run_value, catalog: Dictionary) -> Dictionary:
	if not (active_run_value is Dictionary):
		return {}
	var council: Dictionary = active_run_value.get("council_season", {})
	var rival_id := str(council.get("final_representative_id", ""))
	if not catalog.has(rival_id):
		return {}
	var support_id := str(council.get("rival_support_id", ""))
	return {"day": 24, "rival_id": rival_id, "display_name": str(catalog[rival_id].get("display_name", rival_id)), "reason": str(council.get("final_representative_reason", "locked")), "support_rival_id": support_id, "support_name": str(catalog.get(support_id, {}).get("display_name", "")), "locked": true}


static func activate_support(active_run_value, trigger_id: String, battle_context: Dictionary, catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	var support_id := str(council.get("rival_support_id", ""))
	if support_id == "" or not catalog.has(support_id):
		return {"ok": false, "reason": "no_support", "active_run": active_run}
	if bool(council.get("rival_support_used", false)):
		return {"ok": false, "reason": "already_used", "active_run": active_run}
	if bool(active_run.get("outpost", {}).get("support_token_lost", false)):
		return {"ok": false, "reason": "support_token_lost", "active_run": active_run}
	var effect := {}
	match str(catalog[support_id].get("support_handler_id", "")):
		"rival_support_repair_facility":
			if trigger_id != "facility_danger":
				return {"ok": false, "reason": "wrong_trigger", "active_run": active_run}
			effect = {"type": "facility_shield", "target_id": str(battle_context.get("facility_id", "")), "duration": 8.0}
		"rival_support_cancel_objective":
			if trigger_id != "objective_channel":
				return {"ok": false, "reason": "wrong_trigger", "active_run": active_run}
			effect = {"type": "cancel_objective_channel", "target_id": str(battle_context.get("enemy_id", "")), "cancelled": true}
		"rival_support_rescue_monster":
			if trigger_id != "ally_near_down":
				return {"ok": false, "reason": "wrong_trigger", "active_run": active_run}
			var max_hp := maxi(1, int(battle_context.get("max_hp", 1)))
			effect = {"type": "rescue_heal", "target_id": str(battle_context.get("monster_id", "")), "hp": maxi(int(battle_context.get("hp", 0)), roundi(max_hp * 0.20))}
		_:
			return {"ok": false, "reason": "unknown_support", "active_run": active_run}
	council["rival_support_used"] = true
	active_run["council_season"] = council
	return {"ok": true, "reason": "", "active_run": active_run, "support_rival_id": support_id, "effect": effect}


static func day29_letters(letter_catalog: Dictionary, rival_catalog: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for rival_id_value in rival_catalog.keys():
		var rival_id := str(rival_id_value)
		for letter_id_value in letter_catalog.keys():
			var letter: Dictionary = letter_catalog[letter_id_value]
			if str(letter.get("rival_id", "")) == rival_id and str(letter.get("stage", "")) == "day29_finale":
				var entry := letter.duplicate(true)
				entry["id"] = str(letter_id_value)
				result.append(entry)
				break
	result.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.id) < str(b.id))
	return result


static func unlocked_letters(letter_catalog: Dictionary, max_day: int, rival_id: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for letter_id_value in letter_catalog.keys():
		var letter = letter_catalog.get(letter_id_value)
		if not (letter is Dictionary):
			continue
		if rival_id != "" and str(letter.get("rival_id", "")) != rival_id:
			continue
		if int(letter.get("unlock_day", 0)) > max_day:
			continue
		var entry: Dictionary = letter.duplicate(true)
		entry["id"] = str(letter_id_value)
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary):
		var day_compare := int(a.get("unlock_day", 0)) - int(b.get("unlock_day", 0))
		return str(a.get("id", "")) < str(b.get("id", "")) if day_compare == 0 else day_compare < 0
	)
	return result


static func _representative_result(rival_id: String, reason: String, support_rival_id: String, locked: bool) -> Dictionary:
	return {"rival_id": rival_id, "reason": reason, "support_rival_id": support_rival_id, "locked": locked}


static func _seeded_choice(values: Array[String], cycle_seed: int) -> String:
	if values.is_empty():
		return ""
	values.sort()
	return values[absi(cycle_seed) % values.size()]
