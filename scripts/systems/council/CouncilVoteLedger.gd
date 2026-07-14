extends RefCounted
class_name CouncilVoteLedger

const CHOICE_APPROVE := "approve"
const CHOICE_AMEND := "amend"
const CHOICE_REJECT := "reject"
const VALID_CHOICES := [CHOICE_APPROVE, CHOICE_AMEND, CHOICE_REJECT]
const VOTE_DAYS := [13, 22, 26]


static func agendas_for_day(catalog: Dictionary, day: int, active_run_value = {}) -> Array[String]:
	var used_categories := _used_categories(active_run_value, catalog)
	var result: Array[String] = []
	for agenda_id_value in catalog.keys():
		var agenda_id := str(agenda_id_value)
		var definition: Dictionary = catalog.get(agenda_id, {})
		if int(definition.get("vote_day", 0)) != day:
			continue
		if used_categories.has(str(definition.get("category", ""))):
			continue
		result.append(agenda_id)
	result.sort()
	return result


static func forecast(active_run_value, agenda_id: String, agenda_catalog: Dictionary, rival_catalog: Dictionary, player_choice: String = CHOICE_AMEND) -> Dictionary:
	if player_choice not in VALID_CHOICES or not agenda_catalog.has(agenda_id):
		return {}
	var agenda: Dictionary = agenda_catalog.get(agenda_id, {})
	var positions := {"player": player_choice}
	for rival_id_value in rival_catalog.keys():
		var rival_id := str(rival_id_value)
		var relation := int(active_run_value.get("council_season", {}).get("rival_relations", {}).get(rival_id, 0)) if active_run_value is Dictionary else 0
		var position := CHOICE_AMEND
		if relation <= -40:
			position = CHOICE_REJECT
		elif relation >= 60 and player_choice == CHOICE_AMEND:
			position = CHOICE_AMEND
		elif rival_id in agenda.get("preferred_rival_ids", []):
			position = CHOICE_APPROVE
		elif rival_id in agenda.get("disliked_rival_ids", []):
			position = CHOICE_REJECT
		positions[rival_id] = position
	var tally := {CHOICE_APPROVE: 0, CHOICE_AMEND: 0, CHOICE_REJECT: 0}
	for value in positions.values():
		var choice := str(value)
		tally[choice] = int(tally.get(choice, 0)) + 1
	return {"agenda_id": agenda_id, "player_choice": player_choice, "positions": positions, "tally": tally, "passed": int(tally[CHOICE_APPROVE]) + int(tally[CHOICE_AMEND]) >= 3}


static func record_empty_vote(active_run_value, agenda_id: String, player_choice: String, day: int, agenda_catalog: Dictionary, rival_catalog: Dictionary) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if day not in VOTE_DAYS or not agenda_catalog.has(agenda_id) or int(agenda_catalog.get(agenda_id, {}).get("vote_day", 0)) != day:
		return _result(false, "해당 DAY에 등록된 안건이 아닙니다.", active_run, {})
	if player_choice not in VALID_CHOICES:
		return _result(false, "등록되지 않은 표결 선택입니다.", active_run, {})
	var council: Dictionary = active_run.get("council_season", {}).duplicate(true)
	var history: Array = council.get("agenda_history", []).duplicate()
	if history.has(agenda_id):
		return _result(false, "이미 표결한 안건입니다.", active_run, {})
	var category := str(agenda_catalog.get(agenda_id, {}).get("category", ""))
	if _used_categories(active_run, agenda_catalog).has(category):
		return _result(false, "이번 회차에 같은 범주의 안건을 이미 표결했습니다.", active_run, {})
	var vote := forecast(active_run, agenda_id, agenda_catalog, rival_catalog, player_choice)
	if vote.is_empty():
		return _result(false, "예상 표를 계산하지 못했습니다.", active_run, {})
	history.append(agenda_id)
	council["agenda_history"] = history
	var records: Array = council.get("vote_records", []).duplicate(true)
	var record := vote.duplicate(true)
	record["day"] = day
	record["effect_applied"] = false
	records.append(record)
	council["vote_records"] = records
	active_run["council_season"] = council
	return _result(true, "", active_run, record)


static func validate_ledger(active_run_value, agenda_catalog: Dictionary) -> String:
	if not (active_run_value is Dictionary):
		return "의회 표결 회차 상태가 Dictionary가 아닙니다."
	var council: Dictionary = active_run_value.get("council_season", {})
	var history = council.get("agenda_history", [])
	var records = council.get("vote_records", [])
	if not (history is Array) or not (records is Array) or history.size() != records.size():
		return "의회 안건 이력과 표결 원장 수가 일치해야 합니다."
	var categories := {}
	for agenda_id_value in history:
		var agenda_id := str(agenda_id_value)
		if not agenda_catalog.has(agenda_id):
			return "등록되지 않은 의회 안건입니다: %s" % agenda_id
		var category := str(agenda_catalog.get(agenda_id, {}).get("category", ""))
		if categories.has(category):
			return "같은 범주의 안건이 중복되었습니다: %s" % category
		categories[category] = true
	return ""


static func _used_categories(active_run_value, agenda_catalog: Dictionary) -> Dictionary:
	var result := {}
	if not (active_run_value is Dictionary):
		return result
	for agenda_id_value in active_run_value.get("council_season", {}).get("agenda_history", []):
		var agenda_id := str(agenda_id_value)
		if agenda_catalog.has(agenda_id):
			result[str(agenda_catalog.get(agenda_id, {}).get("category", ""))] = true
	return result


static func _result(ok: bool, error: String, active_run: Dictionary, record: Dictionary) -> Dictionary:
	return {"ok": ok, "error": error, "active_run": active_run, "record": record}
