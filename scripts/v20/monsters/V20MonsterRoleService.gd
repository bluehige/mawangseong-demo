class_name V20MonsterRoleService
extends RefCounted

const PathService = preload("res://scripts/v20/path/V20WeightedPathService.gd")


static func role_contract(specialization_id: String, specializations: Dictionary) -> Dictionary:
	var specialization: Dictionary = specializations.get(specialization_id, {})
	var contract: Dictionary = specialization.get("v20_role", {}).duplicate(true)
	if contract.is_empty():
		return {}
	contract["specialization_id"] = specialization_id
	contract["monster_id"] = str(specialization.get("monster_id", ""))
	contract["ai_behavior"] = str(specialization.get("ai_behavior", ""))
	contract["display_name"] = str(specialization.get("display_name", specialization_id))
	return contract


static func plan_turn(specialization_id: String, context: Dictionary, specializations: Dictionary) -> Dictionary:
	var contract := role_contract(specialization_id, specializations)
	if contract.is_empty():
		return {"ok": false, "error": "unknown_v20_role", "specialization_id": specialization_id}
	var target := _choose_target(contract.get("targeting", {}), context)
	var movement := _choose_movement(contract.get("movement", {}), target, context)
	var route: Dictionary = {}
	var board: Dictionary = context.get("board", {})
	var current_node := str(context.get("current_node", ""))
	var anchor_node := str(movement.get("anchor_node", ""))
	if not board.is_empty() and current_node != "" and anchor_node != "":
		route = PathService.find_path(board, current_node, anchor_node, {"seed": int(context.get("seed", 0))})
	var synergy := facility_synergy(specialization_id, context.get("facilities", []), specializations)
	var command_id := str(context.get("command_id", ""))
	var command_multiplier := float(contract.get("command_affinity", {}).get(command_id, 1.0)) if command_id != "" else 1.0
	return {
		"ok": true,
		"specialization_id": specialization_id,
		"monster_id": str(contract.get("monster_id", "")),
		"ai_behavior": str(contract.get("ai_behavior", "")),
		"movement": movement,
		"target": target,
		"route": route,
		"facility_synergy": synergy,
		"command_id": command_id,
		"command_multiplier": command_multiplier,
		"metric_ids": contract.get("result_metrics", []).duplicate()
	}


static func facility_synergy(specialization_id: String, facilities: Array, specializations: Dictionary) -> Dictionary:
	var contract := role_contract(specialization_id, specializations)
	var supported: Array = contract.get("facility_synergy", [])
	var matches: Array[String] = []
	for facility_value in facilities:
		if not (facility_value is Dictionary):
			continue
		var facility: Dictionary = facility_value
		if supported.has(str(facility.get("facility_id", ""))):
			matches.append(str(facility.get("id", facility.get("facility_id", ""))))
	matches.sort()
	return {"score": matches.size(), "placement_ids": matches}


static func new_result_state(specialization_ids: Array, specializations: Dictionary) -> Dictionary:
	var roles: Dictionary = {}
	for specialization_id_value in specialization_ids:
		var specialization_id := str(specialization_id_value)
		var contract := role_contract(specialization_id, specializations)
		if contract.is_empty():
			continue
		var metrics: Dictionary = {}
		for metric_id_value in contract.get("result_metrics", []):
			metrics[str(metric_id_value)] = 0.0
		roles[specialization_id] = {"metrics": metrics, "decisions": 0}
	return {"roles": roles}


static func record_metric(state: Dictionary, specialization_id: String, metric_id: String, amount: float) -> Dictionary:
	if not state.get("roles", {}).has(specialization_id):
		return {"ok": false, "error": "unknown_role", "state": state.duplicate(true)}
	if not state.get("roles", {}).get(specialization_id, {}).get("metrics", {}).has(metric_id):
		return {"ok": false, "error": "undeclared_metric", "state": state.duplicate(true)}
	var next := state.duplicate(true)
	next["roles"][specialization_id]["metrics"][metric_id] = float(next["roles"][specialization_id]["metrics"].get(metric_id, 0.0)) + amount
	return {"ok": true, "state": next}


static func record_decision(state: Dictionary, specialization_id: String) -> Dictionary:
	if not state.get("roles", {}).has(specialization_id):
		return state.duplicate(true)
	var next := state.duplicate(true)
	next["roles"][specialization_id]["decisions"] = int(next["roles"][specialization_id].get("decisions", 0)) + 1
	return next


static func result_summary(state: Dictionary, specializations: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ids: Array = state.get("roles", {}).keys()
	ids.sort()
	for specialization_id_value in ids:
		var specialization_id := str(specialization_id_value)
		var contract := role_contract(specialization_id, specializations)
		result.append({
			"specialization_id": specialization_id,
			"display_name": str(contract.get("display_name", specialization_id)),
			"monster_id": str(contract.get("monster_id", "")),
			"decisions": int(state.get("roles", {}).get(specialization_id, {}).get("decisions", 0)),
			"metrics": state.get("roles", {}).get(specialization_id, {}).get("metrics", {}).duplicate(true)
		})
	return result


static func _choose_target(rule: Dictionary, context: Dictionary) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for candidate_value in context.get("enemies", []):
		if candidate_value is Dictionary and int(candidate_value.get("hp", 0)) > 0:
			candidates.append(candidate_value)
	if candidates.is_empty():
		return {}
	var focused_target_id := str(context.get("focused_target_id", ""))
	if focused_target_id != "":
		for candidate in candidates:
			if str(candidate.get("id", "")) == focused_target_id:
				var focused := candidate.duplicate(true)
				focused["reason"] = "focus_command"
				return focused
	var mode := str(rule.get("mode", "nearest_to_anchor"))
	var preferred_tags: Array = rule.get("preferred_tags", [])
	var wounded_ally := _most_wounded(context.get("allies", []), 0.75)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _target_precedes(a, b, mode, preferred_tags, wounded_ally)
	)
	var result := candidates[0].duplicate(true)
	result["reason"] = mode
	return result


static func _target_precedes(a: Dictionary, b: Dictionary, mode: String, preferred_tags: Array, wounded_ally: Dictionary) -> bool:
	var a_preferred := _preferred_rank(a.get("tags", []), preferred_tags)
	var b_preferred := _preferred_rank(b.get("tags", []), preferred_tags)
	match mode:
		"lowest_hp_ratio":
			var a_ratio := float(a.get("hp", 0)) / float(maxi(1, int(a.get("max_hp", 1))))
			var b_ratio := float(b.get("hp", 0)) / float(maxi(1, int(b.get("max_hp", 1))))
			if not is_equal_approx(a_ratio, b_ratio):
				return a_ratio < b_ratio
		"wounded_ally_threat":
			var a_same := not wounded_ally.is_empty() and str(a.get("node_id", "")) == str(wounded_ally.get("node_id", ""))
			var b_same := not wounded_ally.is_empty() and str(b.get("node_id", "")) == str(wounded_ally.get("node_id", ""))
			if a_same != b_same:
				return a_same
			if a_preferred != b_preferred:
				return a_preferred < b_preferred
			if not is_equal_approx(float(a.get("threat", 0.0)), float(b.get("threat", 0.0))):
				return float(a.get("threat", 0.0)) > float(b.get("threat", 0.0))
		"rear_priority":
			if a_preferred != b_preferred:
				return a_preferred < b_preferred
			if not is_equal_approx(float(a.get("threat", 0.0)), float(b.get("threat", 0.0))):
				return float(a.get("threat", 0.0)) > float(b.get("threat", 0.0))
		"cluster_priority":
			if a_preferred != b_preferred:
				return a_preferred < b_preferred
			if int(a.get("cluster_size", 1)) != int(b.get("cluster_size", 1)):
				return int(a.get("cluster_size", 1)) > int(b.get("cluster_size", 1))
		"tag_priority":
			if a_preferred != b_preferred:
				return a_preferred < b_preferred
		_:
			if a_preferred != b_preferred:
				return a_preferred < b_preferred
	if not is_equal_approx(float(a.get("distance", 99999.0)), float(b.get("distance", 99999.0))):
		return float(a.get("distance", 99999.0)) < float(b.get("distance", 99999.0))
	return str(a.get("id", "")) < str(b.get("id", ""))


static func _preferred_rank(tags: Array, preferred_tags: Array) -> int:
	for tag_value in preferred_tags:
		if tags.has(tag_value):
			return 0
	return 1


static func _choose_movement(rule: Dictionary, target: Dictionary, context: Dictionary) -> Dictionary:
	var mode := str(rule.get("mode", "facility_anchor"))
	var anchor_node := ""
	var reason := mode
	match mode:
		"wounded_ally":
			var wounded := _most_wounded(context.get("allies", []), 0.75)
			if not wounded.is_empty():
				anchor_node = str(wounded.get("node_id", ""))
				reason = "guard_wounded_ally"
		"target_pursuit":
			anchor_node = str(target.get("node_id", ""))
		"hazard_anchor":
			anchor_node = _hazard_node(context.get("hazards", []))
		"safe_backline", "facility_anchor":
			pass
	if anchor_node == "":
		anchor_node = _facility_node(rule.get("facility_ids", []), context.get("facilities", []))
	if anchor_node == "":
		anchor_node = str(rule.get("fallback_node", context.get("current_node", "")))
	return {"mode": mode, "anchor_node": anchor_node, "reason": reason}


static func _facility_node(preferred_ids: Array, facilities: Array) -> String:
	for facility_id_value in preferred_ids:
		for facility_value in facilities:
			if facility_value is Dictionary and str(facility_value.get("facility_id", "")) == str(facility_id_value) and bool(facility_value.get("active", true)):
				return str(facility_value.get("node_id", ""))
	return ""


static func _hazard_node(hazards: Array) -> String:
	var candidates: Array[String] = []
	for hazard_value in hazards:
		if hazard_value is Dictionary and bool(hazard_value.get("active", true)):
			candidates.append(str(hazard_value.get("node_id", "")))
	candidates.sort()
	return candidates[0] if not candidates.is_empty() else ""


static func _most_wounded(allies: Array, threshold: float) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for ally_value in allies:
		if not (ally_value is Dictionary):
			continue
		var ally: Dictionary = ally_value
		var ratio := float(ally.get("hp", 0)) / float(maxi(1, int(ally.get("max_hp", 1))))
		if int(ally.get("hp", 0)) > 0 and ratio < threshold:
			var copy := ally.duplicate(true)
			copy["hp_ratio"] = ratio
			candidates.append(copy)
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a.get("hp_ratio", 1.0)), float(b.get("hp_ratio", 1.0))):
			return float(a.get("hp_ratio", 1.0)) < float(b.get("hp_ratio", 1.0))
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	return candidates[0]
