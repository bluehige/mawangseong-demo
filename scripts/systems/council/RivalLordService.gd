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
	council["rival_support_id"] = str(preview.get("support_rival_id", ""))
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


static func _representative_result(rival_id: String, reason: String, support_rival_id: String, locked: bool) -> Dictionary:
	return {"rival_id": rival_id, "reason": reason, "support_rival_id": support_rival_id, "locked": locked}


static func _seeded_choice(values: Array[String], cycle_seed: int) -> String:
	if values.is_empty():
		return ""
	values.sort()
	return values[absi(cycle_seed) % values.size()]
