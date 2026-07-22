class_name V20FacilityService
extends RefCounted


static func new_battle_state(placements: Dictionary, catalog: Dictionary) -> Dictionary:
	var runtime: Dictionary = {}
	for placement_id_value in placements.keys():
		var placement_id := str(placement_id_value)
		var placement: Dictionary = placements.get(placement_id, {})
		var facility_id := str(placement.get("facility_id", ""))
		var definition: Dictionary = catalog.get(facility_id, {})
		if definition.is_empty():
			continue
		var metrics: Dictionary = {}
		for metric_id_value in definition.get("result_metrics", []):
			metrics[str(metric_id_value)] = 0.0
		runtime[placement_id] = {
			"facility_id": facility_id,
			"slot_id": str(placement.get("slot_id", "")),
			"edge_id": str(placement.get("edge_id", "")),
			"room_id": str(placement.get("room_id", "")),
			"charges": int(definition.get("activation", {}).get("charges", 0)),
			"active_seconds": 0.0,
			"disabled_seconds": 0.0,
			"metrics": metrics
		}
	return {"placements": placements.duplicate(true), "facilities": runtime, "elapsed_seconds": 0.0}


static func activate(state: Dictionary, placement_id: String, catalog: Dictionary) -> Dictionary:
	if not state.get("facilities", {}).has(placement_id):
		return _result(false, "unknown_placement", state, "시설을 찾을 수 없습니다.")
	var runtime: Dictionary = state.get("facilities", {}).get(placement_id, {})
	if float(runtime.get("disabled_seconds", 0.0)) > 0.0:
		return _result(false, "facility_disabled", state, "무력화된 시설입니다.")
	if int(runtime.get("charges", 0)) <= 0:
		return _result(false, "no_charges", state, "시설 충전이 없습니다.")
	var facility_id := str(runtime.get("facility_id", ""))
	var definition: Dictionary = catalog.get(facility_id, {})
	var next := state.duplicate(true)
	next["facilities"][placement_id]["charges"] = int(runtime.get("charges", 0)) - 1
	next["facilities"][placement_id]["active_seconds"] = float(definition.get("activation", {}).get("duration", 0.0))
	_add_metric(next, placement_id, "activation_count", 1.0)
	return _result(true, "activated", next)


static func advance(state: Dictionary, delta: float) -> Dictionary:
	var next := state.duplicate(true)
	next["elapsed_seconds"] = float(next.get("elapsed_seconds", 0.0)) + maxf(0.0, delta)
	for placement_id in next.get("facilities", {}).keys():
		var runtime: Dictionary = next["facilities"][placement_id]
		runtime["active_seconds"] = maxf(0.0, float(runtime.get("active_seconds", 0.0)) - delta)
		var disabled_before := float(runtime.get("disabled_seconds", 0.0))
		runtime["disabled_seconds"] = maxf(0.0, disabled_before - delta)
		if disabled_before > 0.0 and runtime.get("metrics", {}).has("disabled_seconds"):
			runtime["metrics"]["disabled_seconds"] = float(runtime["metrics"].get("disabled_seconds", 0.0)) + minf(delta, disabled_before)
		next["facilities"][placement_id] = runtime
	return next


static func disable(state: Dictionary, placement_id: String, duration: float) -> Dictionary:
	if not state.get("facilities", {}).has(placement_id):
		return _result(false, "unknown_placement", state, "시설을 찾을 수 없습니다.")
	var next := state.duplicate(true)
	next["facilities"][placement_id]["disabled_seconds"] = maxf(float(next["facilities"][placement_id].get("disabled_seconds", 0.0)), duration)
	next["facilities"][placement_id]["active_seconds"] = 0.0
	return _result(true, "disabled", next)


static func record_metric(state: Dictionary, placement_id: String, metric_id: String, amount: float) -> Dictionary:
	if not state.get("facilities", {}).has(placement_id):
		return _result(false, "unknown_placement", state, "시설을 찾을 수 없습니다.")
	if not state.get("facilities", {}).get(placement_id, {}).get("metrics", {}).has(metric_id):
		return _result(false, "undeclared_metric", state, "선언되지 않은 시설 지표입니다.")
	var next := state.duplicate(true)
	_add_metric(next, placement_id, metric_id, amount)
	return _result(true, "metric_recorded", next)


static func path_context(state: Dictionary, catalog: Dictionary) -> Dictionary:
	var result := {
		"door_state_costs": {},
		"facility_route_costs": {},
		"temporary_hazard_costs": {},
		"goal_biases": {}
	}
	for placement_id_value in state.get("facilities", {}).keys():
		var placement_id := str(placement_id_value)
		var runtime: Dictionary = state.get("facilities", {}).get(placement_id, {})
		if float(runtime.get("disabled_seconds", 0.0)) > 0.0:
			continue
		var definition: Dictionary = catalog.get(str(runtime.get("facility_id", "")), {})
		var route_effect: Dictionary = definition.get("route_effect", {})
		var route_key := str(runtime.get("edge_id", ""))
		if route_key == "":
			route_key = str(runtime.get("slot_id", ""))
		if route_key != "" and route_effect.has("cost_delta"):
			result["facility_route_costs"][route_key] = float(result["facility_route_costs"].get(route_key, 0.0)) + float(route_effect.get("cost_delta", 0.0))
		var goal_key := str(route_effect.get("goal_key", ""))
		if goal_key != "":
			result["goal_biases"][goal_key] = float(result["goal_biases"].get(goal_key, 0.0)) + float(route_effect.get("goal_bias", 0.0))
		if float(runtime.get("active_seconds", 0.0)) > 0.0:
			var active_effect: Dictionary = definition.get("activation", {}).get("effect", {})
			var door_slot := str(runtime.get("slot_id", ""))
			if door_slot != "" and active_effect.has("door_cost_override"):
				result["door_state_costs"][door_slot] = float(active_effect.get("door_cost_override", 0.0))
			if goal_key != "" and active_effect.has("goal_bias_delta"):
				result["goal_biases"][goal_key] = float(result["goal_biases"].get(goal_key, 0.0)) + float(active_effect.get("goal_bias_delta", 0.0))
	return result


static func apply_goal_biases(enemy_contract: Dictionary, path_context_value: Dictionary, enemy_tags: Array) -> Dictionary:
	var next := enemy_contract.duplicate(true)
	var preferences: Dictionary = next.get("goal_preferences", {}).duplicate(true)
	for goal_key in path_context_value.get("goal_biases", {}).keys():
		if goal_key == "treasure" and not (enemy_tags.has("thief") or enemy_tags.has("bait_sensitive")):
			continue
		preferences[goal_key] = float(preferences.get(goal_key, 0.0)) + float(path_context_value.get("goal_biases", {}).get(goal_key, 0.0))
		var candidate_goals: Array = next.get("candidate_goals", []).duplicate()
		if not candidate_goals.has(goal_key):
			candidate_goals.append(goal_key)
		next["candidate_goals"] = candidate_goals
	next["goal_preferences"] = preferences
	return next


static func combat_effects(state: Dictionary, placement_id: String, catalog: Dictionary) -> Dictionary:
	var runtime: Dictionary = state.get("facilities", {}).get(placement_id, {})
	if runtime.is_empty() or float(runtime.get("disabled_seconds", 0.0)) > 0.0:
		return {}
	var definition: Dictionary = catalog.get(str(runtime.get("facility_id", "")), {})
	return definition.get("activation", {}).get("effect", {}).duplicate(true) if float(runtime.get("active_seconds", 0.0)) > 0.0 else {}


static func passive_effects(state: Dictionary, placement_id: String, catalog: Dictionary) -> Dictionary:
	var runtime: Dictionary = state.get("facilities", {}).get(placement_id, {})
	if runtime.is_empty() or float(runtime.get("disabled_seconds", 0.0)) > 0.0:
		return {}
	var definition: Dictionary = catalog.get(str(runtime.get("facility_id", "")), {})
	return definition.get("combat_effect", {}).duplicate(true)


static func effects_for_room(state: Dictionary, room_id: String, catalog: Dictionary, facility_id: String = "") -> Dictionary:
	var result: Dictionary = {}
	for placement_id_value in state.get("facilities", {}).keys():
		var placement_id := str(placement_id_value)
		var runtime: Dictionary = state.get("facilities", {}).get(placement_id, {})
		if str(runtime.get("room_id", "")) != room_id:
			continue
		if facility_id != "" and str(runtime.get("facility_id", "")) != facility_id:
			continue
		result = _merge_effects(result, passive_effects(state, placement_id, catalog))
		result = _merge_effects(result, combat_effects(state, placement_id, catalog))
	return result


static func synergy_score(facility_id: String, monster_tags: Array, catalog: Dictionary) -> int:
	var score := 0
	for tag_value in catalog.get(facility_id, {}).get("synergy_tags", []):
		if monster_tags.has(tag_value):
			score += 1
	return score


static func is_countered(facility_id: String, enemy_tags: Array, catalog: Dictionary) -> bool:
	for tag_value in catalog.get(facility_id, {}).get("counter_tags", []):
		if enemy_tags.has(tag_value):
			return true
	return false


static func result_summary(state: Dictionary, catalog: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ids: Array = state.get("facilities", {}).keys()
	ids.sort()
	for placement_id_value in ids:
		var placement_id := str(placement_id_value)
		var runtime: Dictionary = state.get("facilities", {}).get(placement_id, {})
		var facility_id := str(runtime.get("facility_id", ""))
		var definition: Dictionary = catalog.get(facility_id, {})
		result.append({
			"placement_id": placement_id,
			"facility_id": facility_id,
			"display_name": str(definition.get("display_name", facility_id)),
			"role": str(definition.get("role", "")),
			"metrics": runtime.get("metrics", {}).duplicate(true),
			"strength": str(definition.get("strength", ""))
		})
	return result


static func _add_metric(state: Dictionary, placement_id: String, metric_id: String, amount: float) -> void:
	if state.get("facilities", {}).get(placement_id, {}).get("metrics", {}).has(metric_id):
		state["facilities"][placement_id]["metrics"][metric_id] = float(state["facilities"][placement_id]["metrics"].get(metric_id, 0.0)) + amount


static func _merge_effects(base: Dictionary, extra: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key_value in extra.keys():
		var key := str(key_value)
		var value = extra.get(key)
		if typeof(value) in [TYPE_FLOAT, TYPE_INT]:
			if key.contains("multiplier"):
				result[key] = minf(float(result.get(key, 1.0)), float(value)) if key in ["enemy_slow_multiplier", "monster_damage_taken_multiplier", "thief_slow_multiplier", "slow_multiplier"] else maxf(float(result.get(key, 1.0)), float(value))
			else:
				result[key] = maxf(float(result.get(key, 0.0)), float(value))
		else:
			result[key] = value
	return result


static func _result(ok: bool, status: String, state: Dictionary, error: String = "") -> Dictionary:
	return {"ok": ok, "status": status, "state": state.duplicate(true), "error": error}
