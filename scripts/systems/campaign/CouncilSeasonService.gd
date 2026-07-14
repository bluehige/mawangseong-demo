extends RefCounted
class_name CouncilSeasonService

const FIRST_DAY := 1
const FINAL_DAY := 30
const PHASE_MANAGEMENT := "management"
const PHASE_BATTLE_READY := "battle_ready"
const PHASE_COMBAT := "combat"
const PHASE_DAY_COMPLETE := "day_complete"


static func new_day_state(day: int = FIRST_DAY) -> Dictionary:
	return {"current_day": clampi(day, FIRST_DAY, FINAL_DAY), "phase": PHASE_MANAGEMENT, "completed_days": [], "battle_cleared_days": []}


static func normalize_day_state(value, fallback_day: int = FIRST_DAY) -> Dictionary:
	var result := new_day_state(fallback_day)
	if not (value is Dictionary):
		return result
	result["current_day"] = clampi(int(value.get("current_day", fallback_day)), FIRST_DAY, FINAL_DAY)
	var phase := str(value.get("phase", PHASE_MANAGEMENT))
	result["phase"] = phase if phase in [PHASE_MANAGEMENT, PHASE_BATTLE_READY, PHASE_COMBAT, PHASE_DAY_COMPLETE] else PHASE_MANAGEMENT
	result["completed_days"] = _unique_days(value.get("completed_days", []))
	result["battle_cleared_days"] = _unique_days(value.get("battle_cleared_days", []))
	return result


static func validate_catalog(catalog: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if catalog.size() != FINAL_DAY:
		errors.append("의회 DAY 카탈로그는 30개여야 합니다.")
	var seen_days := {}
	for entry_id_value in catalog.keys():
		var entry_id := str(entry_id_value)
		var entry = catalog.get(entry_id_value)
		if not (entry is Dictionary):
			errors.append("의회 DAY 항목은 Dictionary여야 합니다: %s" % entry_id)
			continue
		for key in ["day", "title", "story_beat", "encounter_kind", "management_only", "feature_flags", "empty_wave"]:
			if not entry.has(key):
				errors.append("의회 DAY 필수 필드 누락: %s/%s" % [entry_id, key])
		var day := int(entry.get("day", 0))
		if day < FIRST_DAY or day > FINAL_DAY or seen_days.has(day):
			errors.append("의회 DAY 번호가 중복되거나 범위를 벗어났습니다: %s" % day)
		seen_days[day] = true
		if not (entry.get("management_only") is bool) or not (entry.get("empty_wave") is bool) or not (entry.get("feature_flags") is Array):
			errors.append("의회 DAY 상태 필드 형식이 올바르지 않습니다: %s" % entry_id)
		if bool(entry.get("management_only", false)) == bool(entry.get("empty_wave", false)):
			errors.append("관리 전용 DAY와 빈 웨이브 계약이 충돌합니다: %s" % entry_id)
	for day in range(FIRST_DAY, FINAL_DAY + 1):
		if not seen_days.has(day):
			errors.append("의회 DAY가 누락되었습니다: %d" % day)
	return errors


static func definition_for_day(catalog: Dictionary, day: int) -> Dictionary:
	for entry_value in catalog.values():
		if entry_value is Dictionary and int(entry_value.get("day", 0)) == day:
			return entry_value.duplicate(true)
	return {}


static func feature_flags(catalog: Dictionary, day: int) -> Array[String]:
	var result: Array[String] = []
	for flag in definition_for_day(catalog, day).get("feature_flags", []):
		result.append(str(flag))
	return result


static func has_flag(catalog: Dictionary, day: int, flag: String) -> bool:
	return flag in feature_flags(catalog, day)


static func is_management_only(catalog: Dictionary, day: int) -> bool:
	return bool(definition_for_day(catalog, day).get("management_only", false))


static func can_enter_combat(catalog: Dictionary, day: int) -> bool:
	var definition := definition_for_day(catalog, day)
	return not definition.is_empty() and not bool(definition.get("management_only", false))


static func empty_wave_for_day(catalog: Dictionary, day: int) -> Dictionary:
	var definition := definition_for_day(catalog, day)
	if definition.is_empty() or not bool(definition.get("empty_wave", false)):
		return {}
	return {"id": "council_empty_day_%02d" % day, "day": day, "encounter_kind": definition.get("encounter_kind", ""), "entries": []}


static func start_day(state_value, day: int, catalog: Dictionary) -> Dictionary:
	if day < FIRST_DAY or day > FINAL_DAY or definition_for_day(catalog, day).is_empty():
		return _result(false, "DAY %d에는 진입할 수 없습니다." % day, normalize_day_state(state_value))
	var state := normalize_day_state(state_value, day)
	state["current_day"] = day
	state["phase"] = PHASE_MANAGEMENT
	return _result(true, "", state)


static func finish_management(state_value, catalog: Dictionary) -> Dictionary:
	var state := normalize_day_state(state_value)
	if str(state.get("phase", "")) != PHASE_MANAGEMENT:
		return _result(false, "관리 단계가 아닙니다.", state)
	var day := int(state.get("current_day", FIRST_DAY))
	state["phase"] = PHASE_DAY_COMPLETE if is_management_only(catalog, day) else PHASE_BATTLE_READY
	return _result(true, "", state)


static func begin_combat(state_value, catalog: Dictionary) -> Dictionary:
	var state := normalize_day_state(state_value)
	var day := int(state.get("current_day", FIRST_DAY))
	if is_management_only(catalog, day):
		return _result(false, "관리 전용 DAY에는 전투에 진입할 수 없습니다.", state)
	if str(state.get("phase", "")) != PHASE_BATTLE_READY:
		return _result(false, "전투 준비 단계가 아닙니다.", state)
	state["phase"] = PHASE_COMBAT
	return _result(true, "", state)


static func complete_combat(state_value) -> Dictionary:
	var state := normalize_day_state(state_value)
	if str(state.get("phase", "")) != PHASE_COMBAT:
		return _result(false, "진행 중인 의회 전투가 없습니다.", state)
	var day := int(state.get("current_day", FIRST_DAY))
	_append_day(state["battle_cleared_days"], day)
	state["phase"] = PHASE_DAY_COMPLETE
	return _result(true, "", state)


static func advance_day(state_value, catalog: Dictionary) -> Dictionary:
	var state := normalize_day_state(state_value)
	if str(state.get("phase", "")) != PHASE_DAY_COMPLETE:
		return _result(false, "현재 DAY를 완료하지 않았습니다.", state)
	var day := int(state.get("current_day", FIRST_DAY))
	_append_day(state["completed_days"], day)
	if day >= FINAL_DAY:
		return _result(false, "DAY 30 이후에는 진행할 수 없습니다.", state)
	return start_day(state, day + 1, catalog)


static func _result(ok: bool, error: String, state: Dictionary) -> Dictionary:
	return {"ok": ok, "error": error, "state": state}


static func _unique_days(value) -> Array[int]:
	var result: Array[int] = []
	if not (value is Array):
		return result
	for item in value:
		var day := int(item)
		if day >= FIRST_DAY and day <= FINAL_DAY and not result.has(day):
			result.append(day)
	result.sort()
	return result


static func _append_day(days: Array, day: int) -> void:
	if not days.has(day):
		days.append(day)
		days.sort()
