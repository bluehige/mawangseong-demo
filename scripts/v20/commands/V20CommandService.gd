class_name V20CommandService
extends RefCounted

const FacilityService = preload("res://scripts/v20/facilities/V20FacilityService.gd")


static func new_state(catalog: Dictionary, max_points: int = 3, initial_points: int = 3, recharge_seconds: float = 12.0) -> Dictionary:
	var cooldowns: Dictionary = {}
	var metrics: Dictionary = {}
	for command_id_value in catalog.keys():
		var command_id := str(command_id_value)
		cooldowns[command_id] = 0.0
		var command_metrics: Dictionary = {}
		for metric_id_value in catalog.get(command_id, {}).get("result_metrics", []):
			command_metrics[str(metric_id_value)] = 0.0
		metrics[command_id] = command_metrics
	return {
		"max_points": maxi(1, max_points),
		"points": clampi(initial_points, 0, maxi(1, max_points)),
		"recharge_seconds": maxf(1.0, recharge_seconds),
		"recharge_progress": 0.0,
		"cooldowns": cooldowns,
		"active_commands": {},
		"metrics": metrics,
		"history": [],
		"elapsed_seconds": 0.0
	}


static func issue(state: Dictionary, command_id: String, target: Dictionary, catalog: Dictionary, facility_state: Dictionary = {}, facility_catalog: Dictionary = {}) -> Dictionary:
	var definition: Dictionary = catalog.get(command_id, {})
	if definition.is_empty():
		return _result(false, "unknown_command", state, facility_state, "명령을 찾을 수 없습니다.")
	if float(state.get("cooldowns", {}).get(command_id, 0.0)) > 0.0:
		return _result(false, "cooldown", state, facility_state, "명령 재사용 대기 중입니다.")
	var cost := int(definition.get("command_point_cost", 1))
	if int(state.get("points", 0)) < cost:
		return _result(false, "insufficient_points", state, facility_state, "명령력이 부족합니다.")
	var target_error := _target_error(definition, target)
	if target_error != "":
		return _result(false, "invalid_target", state, facility_state, target_error)
	var next_facility_state := facility_state.duplicate(true)
	if bool(definition.get("effect", {}).get("activate_facility", false)):
		var activation := FacilityService.activate(facility_state, str(target.get("id", "")), facility_catalog)
		if not bool(activation.get("ok", false)):
			return _result(false, str(activation.get("status", "facility_rejected")), state, facility_state, str(activation.get("error", "시설을 발동할 수 없습니다.")))
		next_facility_state = activation.get("state", facility_state)
	var next := state.duplicate(true)
	next["points"] = int(next.get("points", 0)) - cost
	next["cooldowns"][command_id] = float(definition.get("cooldown_seconds", 0.0))
	var duration := float(definition.get("duration_seconds", 0.0))
	if duration > 0.0:
		next["active_commands"][command_id] = {
			"remaining_seconds": duration,
			"target": target.duplicate(true),
			"effect": definition.get("effect", {}).duplicate(true),
			"response_tags": definition.get("response_tags", []).duplicate()
		}
	_add_metric(next, command_id, "uses", 1.0)
	if bool(definition.get("effect", {}).get("activate_facility", false)):
		_add_metric(next, command_id, "facility_activations", 1.0)
	var history: Array = next.get("history", [])
	history.append({"command_id": command_id, "target": target.duplicate(true), "at_seconds": float(next.get("elapsed_seconds", 0.0))})
	next["history"] = history
	return _result(true, "issued", next, next_facility_state)


static func advance(state: Dictionary, delta: float) -> Dictionary:
	var step := maxf(0.0, delta)
	var next := state.duplicate(true)
	next["elapsed_seconds"] = float(next.get("elapsed_seconds", 0.0)) + step
	for command_id in next.get("cooldowns", {}).keys():
		next["cooldowns"][command_id] = maxf(0.0, float(next["cooldowns"].get(command_id, 0.0)) - step)
	var expired: Array[String] = []
	for command_id in next.get("active_commands", {}).keys():
		var active: Dictionary = next["active_commands"][command_id]
		active["remaining_seconds"] = maxf(0.0, float(active.get("remaining_seconds", 0.0)) - step)
		if is_zero_approx(float(active.get("remaining_seconds", 0.0))):
			expired.append(str(command_id))
		else:
			next["active_commands"][command_id] = active
	for command_id in expired:
		next["active_commands"].erase(command_id)
	if int(next.get("points", 0)) < int(next.get("max_points", 0)):
		next["recharge_progress"] = float(next.get("recharge_progress", 0.0)) + step
		var recharge_seconds := maxf(1.0, float(next.get("recharge_seconds", 12.0)))
		while float(next.get("recharge_progress", 0.0)) >= recharge_seconds and int(next.get("points", 0)) < int(next.get("max_points", 0)):
			next["recharge_progress"] = float(next.get("recharge_progress", 0.0)) - recharge_seconds
			next["points"] = int(next.get("points", 0)) + 1
	else:
		next["recharge_progress"] = 0.0
	return next


static func active_effect(state: Dictionary, command_id: String) -> Dictionary:
	return state.get("active_commands", {}).get(command_id, {}).duplicate(true)


static func effect_for_target(state: Dictionary, target_id: String, target_node: String) -> Dictionary:
	var result: Dictionary = {}
	var source_commands: Array[String] = []
	for command_id_value in state.get("active_commands", {}).keys():
		var command_id := str(command_id_value)
		var active: Dictionary = state.get("active_commands", {}).get(command_id, {})
		var target: Dictionary = active.get("target", {})
		var applies := false
		match str(target.get("type", "")):
			"enemy":
				applies = str(target.get("id", "")) == target_id
			"room":
				applies = str(target.get("id", "")) == target_node
			"facility":
				applies = str(target.get("room_id", "")) == target_node or str(target.get("id", "")) == target_id
		if not applies:
			continue
		for key_value in active.get("effect", {}).keys():
			var key := str(key_value)
			var value = active.get("effect", {}).get(key)
			if value is float or value is int:
				result[key] = float(result.get(key, 1.0 if key.ends_with("_multiplier") else 0.0)) * float(value) if key.ends_with("_multiplier") else float(result.get(key, 0.0)) + float(value)
			else:
				result[key] = value
		source_commands.append(command_id)
	result["source_commands"] = source_commands
	return result


static func command_rows(state: Dictionary, catalog: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for command_id in ["v20_rally", "v20_focus", "v20_activate_facility", "v20_emergency_fallback"]:
		if not catalog.has(command_id):
			continue
		var definition: Dictionary = catalog.get(command_id, {})
		var cooldown := float(state.get("cooldowns", {}).get(command_id, 0.0))
		var cost := int(definition.get("command_point_cost", 1))
		var status := "명령력 %d" % cost
		if cooldown > 0.0:
			status = "%.1f초" % cooldown
		result.append({
			"id": command_id,
			"label": str(definition.get("display_name", command_id)),
			"status": status,
			"disabled": cooldown > 0.0 or int(state.get("points", 0)) < cost,
			"tooltip": str(definition.get("description", ""))
		})
	return result


static func record_metric(state: Dictionary, command_id: String, metric_id: String, amount: float) -> Dictionary:
	if not state.get("metrics", {}).get(command_id, {}).has(metric_id):
		return {"ok": false, "error": "undeclared_metric", "state": state.duplicate(true)}
	var next := state.duplicate(true)
	_add_metric(next, command_id, metric_id, amount)
	return {"ok": true, "state": next}


static func evaluate_pattern(state: Dictionary, pattern: Dictionary) -> Dictionary:
	var required: Array = pattern.get("response_tags", [])
	var matched: Array[String] = []
	for active_value in state.get("active_commands", {}).values():
		for tag_value in active_value.get("response_tags", []):
			var tag := str(tag_value)
			if required.has(tag) and not matched.has(tag):
				matched.append(tag)
	matched.sort()
	var base_pressure := float(pattern.get("base_pressure", 100.0))
	var response_per_tag := float(pattern.get("response_per_tag", 35.0))
	var remaining := maxf(0.0, base_pressure - response_per_tag * matched.size())
	return {
		"matched_response_tags": matched,
		"remaining_pressure": remaining,
		"success": matched.size() >= int(pattern.get("responses_required", 1)),
		"outcome_signature": "%s|%s|%.1f" % [str(pattern.get("id", "pattern")), ">".join(matched), remaining]
	}


static func _target_error(definition: Dictionary, target: Dictionary) -> String:
	var target_type := str(definition.get("target_type", ""))
	if str(target.get("type", "")) != target_type:
		return "%s 대상을 선택해야 합니다." % target_type
	if str(target.get("id", "")) == "":
		return "대상을 선택해야 합니다."
	return ""


static func _add_metric(state: Dictionary, command_id: String, metric_id: String, amount: float) -> void:
	if state.get("metrics", {}).get(command_id, {}).has(metric_id):
		state["metrics"][command_id][metric_id] = float(state["metrics"][command_id].get(metric_id, 0.0)) + amount


static func _result(ok: bool, status: String, state: Dictionary, facility_state: Dictionary, error: String = "") -> Dictionary:
	return {"ok": ok, "status": status, "state": state.duplicate(true), "facility_state": facility_state.duplicate(true), "error": error}
