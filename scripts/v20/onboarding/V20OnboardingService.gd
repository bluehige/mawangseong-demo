class_name V20OnboardingService
extends RefCounted


static func validate_config(config) -> Dictionary:
	var errors: Array[String] = []
	if not (config is Dictionary):
		return {"ok": false, "errors": ["onboarding config must be a Dictionary"]}
	if int(config.get("schema_version", 0)) != 2:
		errors.append("onboarding schema_version must be 2")
	if float(config.get("first_choice_deadline_seconds", 0.0)) != 90.0:
		errors.append("first meaningful choice deadline must be exactly 90 seconds")
	if not (config.get("meaningful_actions") is Array) or config.get("meaningful_actions", []).size() < 3:
		errors.append("at least three meaningful actions are required")
	if not (config.get("guidance") is Array) or config.get("guidance", []).size() < 3:
		errors.append("progressive guidance is required")
	if not (config.get("retry_promises") is Array) or config.get("retry_promises", []).size() < 4:
		errors.append("retry promises are incomplete")
	return {"ok": errors.is_empty(), "errors": errors}


static func new_state(config: Dictionary) -> Dictionary:
	return {
		"schema_version": 2,
		"elapsed_seconds": 0.0,
		"deadline_seconds": float(config.get("first_choice_deadline_seconds", 90.0)),
		"first_meaningful_choice": {},
		"external_help_count": 0,
		"day_one_completed": false,
		"events": [],
		"retry_count": 0,
		"last_retry_cause": ""
	}


static func advance(state: Dictionary, delta: float, screen_name: String) -> Dictionary:
	var next := state.duplicate(true)
	if next.get("first_meaningful_choice", {}).is_empty() and screen_name == "management":
		next["elapsed_seconds"] = float(next.get("elapsed_seconds", 0.0)) + maxf(0.0, delta)
	return next


static func record_action(state: Dictionary, config: Dictionary, action_id: String, details: Dictionary = {}) -> Dictionary:
	var next := state.duplicate(true)
	if not config.get("meaningful_actions", []).has(action_id):
		return {"accepted": false, "state": next}
	var event := {"action_id": action_id, "at_seconds": snappedf(float(next.get("elapsed_seconds", 0.0)), 0.1), "details": details.duplicate(true)}
	next["events"].append(event)
	if next.get("first_meaningful_choice", {}).is_empty():
		event["within_90_seconds"] = float(event.get("at_seconds", 0.0)) <= float(next.get("deadline_seconds", 90.0))
		next["first_meaningful_choice"] = event.duplicate(true)
	return {"accepted": true, "state": next, "event": event}


static func record_external_help(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	next["external_help_count"] = int(next.get("external_help_count", 0)) + 1
	return next


static func complete_day_one(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	next["day_one_completed"] = true
	return next


static func record_retry(state: Dictionary, cause: String) -> Dictionary:
	var next := state.duplicate(true)
	next["retry_count"] = int(next.get("retry_count", 0)) + 1
	next["last_retry_cause"] = cause
	return next


static func guidance(state: Dictionary, config: Dictionary) -> String:
	var first_choice: Dictionary = state.get("first_meaningful_choice", {})
	if not first_choice.is_empty():
		return "첫 결정 완료 · 전투 전까지 시설과 몬스터 배치를 더 바꿀 수 있습니다."
	var elapsed := float(state.get("elapsed_seconds", 0.0))
	var result := "첫 결정을 시작하세요."
	for row_value in config.get("guidance", []):
		var row: Dictionary = row_value
		if elapsed >= float(row.get("after_seconds", 0.0)):
			result = str(row.get("text", result))
	return result


static func evaluation(state: Dictionary) -> Dictionary:
	var first_choice: Dictionary = state.get("first_meaningful_choice", {})
	var within_deadline := not first_choice.is_empty() and bool(first_choice.get("within_90_seconds", false))
	var without_external_help := int(state.get("external_help_count", 0)) == 0
	var day_one_completed := bool(state.get("day_one_completed", false))
	return {
		"first_choice_recorded": not first_choice.is_empty(),
		"within_90_seconds": within_deadline,
		"without_external_help": without_external_help,
		"day_one_completed": day_one_completed,
		"internal_observation_ready": within_deadline and without_external_help and day_one_completed
	}
