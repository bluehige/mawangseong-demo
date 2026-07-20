class_name V20WeightedPathService
extends RefCounted

const DecisionEvidence = preload("res://scripts/v20/contracts/V20DecisionEvidence.gd")
const COST_KEYS := [
	"base_edge_cost",
	"door_state_cost",
	"facility_route_cost",
	"temporary_hazard_cost",
	"enemy_role_preference",
	"goal_preference"
]
const DEFAULT_DOOR_COSTS := {"open": 0.0, "reinforced": 12.0, "closed": 999.0, "disabled": 0.0}


static func find_path(board: Dictionary, start_node: String, goal_node: String, context: Dictionary = {}) -> Dictionary:
	var nodes: Array = board.get("nodes", [])
	if not nodes.has(start_node) or not nodes.has(goal_node):
		return {"ok": false, "error": "unknown start or goal node", "nodes": [], "edges": []}
	if start_node == goal_node:
		return _path_result(board, [start_node], [], _empty_breakdown(), goal_node, str(context.get("goal_key", "")))
	var distances: Dictionary = {start_node: 0.0}
	var frontier: Array[String] = [start_node]
	var came_from: Dictionary = {}
	var seed_value := int(context.get("seed", 0))
	while not frontier.is_empty():
		var current := _pop_best(frontier, distances, seed_value)
		if current == goal_node:
			break
		for traversal_value in _traversals_from(board, current):
			var traversal: Dictionary = traversal_value
			var next_node := str(traversal.get("to", ""))
			var breakdown := edge_cost_breakdown(traversal.get("edge", {}), context)
			var candidate := float(distances.get(current, INF)) + _breakdown_total(breakdown)
			var known := float(distances.get(next_node, INF))
			if candidate < known - 0.0001 or (is_equal_approx(candidate, known) and _prefer_candidate(seed_value, current, next_node, came_from)):
				distances[next_node] = candidate
				came_from[next_node] = {"node": current, "edge_id": str(traversal.get("edge", {}).get("id", "")), "breakdown": breakdown}
				if not frontier.has(next_node):
					frontier.append(next_node)
	if not came_from.has(goal_node):
		return {"ok": false, "error": "no path", "nodes": [], "edges": []}
	var path_nodes: Array[String] = [goal_node]
	var path_edges: Array[String] = []
	var total_breakdown := _empty_breakdown()
	var cursor := goal_node
	while cursor != start_node:
		var step: Dictionary = came_from.get(cursor, {})
		if step.is_empty():
			return {"ok": false, "error": "broken path", "nodes": [], "edges": []}
		path_edges.push_front(str(step.get("edge_id", "")))
		_add_breakdown(total_breakdown, step.get("breakdown", {}))
		cursor = str(step.get("node", ""))
		path_nodes.push_front(cursor)
	var goal_preference := float(context.get("goal_preference", 0.0))
	total_breakdown["goal_preference"] = goal_preference
	return _path_result(board, path_nodes, path_edges, total_breakdown, goal_node, str(context.get("goal_key", "")))


static func choose_goal_and_path(board: Dictionary, start_node: String, enemy_contract: Dictionary, context: Dictionary = {}) -> Dictionary:
	var goal_nodes: Dictionary = board.get("goal_nodes", {})
	var preferences: Dictionary = enemy_contract.get("goal_preferences", {"throne": 0.0})
	var candidates: Array = enemy_contract.get("candidate_goals", preferences.keys())
	var best: Dictionary = {}
	for goal_key_value in candidates:
		var goal_key := str(goal_key_value)
		var goal_node := str(goal_nodes.get(goal_key, ""))
		if goal_node == "":
			continue
		var candidate_context := context.duplicate(true)
		candidate_context["goal_key"] = goal_key
		candidate_context["goal_preference"] = float(preferences.get(goal_key, 0.0))
		candidate_context["enemy_role_preferences"] = enemy_contract.get("route_tag_costs", {}).duplicate(true)
		var candidate := find_path(board, start_node, goal_node, candidate_context)
		if not bool(candidate.get("ok", false)):
			continue
		if best.is_empty() or _route_precedes(candidate, best, int(context.get("seed", 0))):
			best = candidate
	if best.is_empty():
		return {"ok": false, "error": "no reachable goal", "nodes": [], "edges": []}
	best["enemy_role"] = str(enemy_contract.get("role", "default"))
	return best


static func edge_cost_breakdown(edge: Dictionary, context: Dictionary) -> Dictionary:
	var result := _empty_breakdown()
	result["base_edge_cost"] = float(edge.get("base_cost", 0.0))
	var door_slot := str(edge.get("door_slot", ""))
	if door_slot != "":
		var direct_door_costs: Dictionary = context.get("door_state_costs", {})
		if direct_door_costs.has(door_slot):
			result["door_state_cost"] = float(direct_door_costs.get(door_slot, 0.0))
		else:
			var door_state := str(context.get("door_states", {}).get(door_slot, "open"))
			result["door_state_cost"] = float(DEFAULT_DOOR_COSTS.get(door_state, 0.0))
	var facility_costs: Dictionary = context.get("facility_route_costs", {})
	result["facility_route_cost"] = _mapped_edge_cost(edge, facility_costs)
	var hazards: Dictionary = context.get("temporary_hazard_costs", {})
	result["temporary_hazard_cost"] = _mapped_edge_cost(edge, hazards)
	var role_preferences: Dictionary = context.get("enemy_role_preferences", {})
	result["enemy_role_preference"] = _mapped_edge_cost(edge, role_preferences)
	return result


static func predict_routes(board: Dictionary, placements: Array, enemy_contract: Dictionary, seed_value: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for placement_value in placements:
		var placement: Dictionary = placement_value
		var context := {
			"seed": seed_value,
			"door_states": placement.get("door_states", {}).duplicate(true),
			"door_state_costs": placement.get("door_state_costs", {}).duplicate(true),
			"facility_route_costs": placement.get("facility_route_costs", {}).duplicate(true),
			"temporary_hazard_costs": placement.get("temporary_hazard_costs", {}).duplicate(true)
		}
		var route := choose_goal_and_path(board, "entrance", enemy_contract, context)
		route["placement_id"] = str(placement.get("id", ""))
		results.append(route)
	return results


static func _traversals_from(board: Dictionary, node_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for edge_value in board.get("edges", []):
		if not (edge_value is Dictionary):
			continue
		var edge: Dictionary = edge_value
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if from_id == node_id:
			result.append({"to": to_id, "edge": edge})
		if bool(edge.get("bidirectional", true)) and to_id == node_id:
			result.append({"to": from_id, "edge": edge})
	result.sort_custom(func(a, b): return str(a.get("edge", {}).get("id", "")) < str(b.get("edge", {}).get("id", "")))
	return result


static func _pop_best(frontier: Array[String], distances: Dictionary, seed_value: int) -> String:
	var best_index := 0
	for index in range(1, frontier.size()):
		var candidate := frontier[index]
		var best := frontier[best_index]
		var candidate_cost := float(distances.get(candidate, INF))
		var best_cost := float(distances.get(best, INF))
		if candidate_cost < best_cost - 0.0001:
			best_index = index
		elif is_equal_approx(candidate_cost, best_cost):
			var candidate_tie := DecisionEvidence.stable_index(seed_value, candidate, 1073741789)
			var best_tie := DecisionEvidence.stable_index(seed_value, best, 1073741789)
			if candidate_tie < best_tie or (candidate_tie == best_tie and candidate < best):
				best_index = index
	return frontier.pop_at(best_index)


static func _prefer_candidate(seed_value: int, previous_node: String, next_node: String, came_from: Dictionary) -> bool:
	var existing_previous := str(came_from.get(next_node, {}).get("node", ""))
	if existing_previous == "":
		return true
	var candidate_tie := DecisionEvidence.stable_index(seed_value, "%s>%s" % [previous_node, next_node], 1073741789)
	var existing_tie := DecisionEvidence.stable_index(seed_value, "%s>%s" % [existing_previous, next_node], 1073741789)
	return candidate_tie < existing_tie


static func _route_precedes(candidate: Dictionary, current: Dictionary, seed_value: int) -> bool:
	var candidate_cost := float(candidate.get("total_cost", INF))
	var current_cost := float(current.get("total_cost", INF))
	if candidate_cost < current_cost - 0.0001:
		return true
	if not is_equal_approx(candidate_cost, current_cost):
		return false
	var candidate_signature := str(candidate.get("signature", ""))
	var current_signature := str(current.get("signature", ""))
	return DecisionEvidence.stable_index(seed_value, candidate_signature, 1073741789) < DecisionEvidence.stable_index(seed_value, current_signature, 1073741789)


static func _mapped_edge_cost(edge: Dictionary, mapping: Dictionary) -> float:
	var total := float(mapping.get(str(edge.get("id", "")), 0.0))
	var facility_slot := str(edge.get("facility_slot", ""))
	if facility_slot != "":
		total += float(mapping.get(facility_slot, 0.0))
	var door_slot := str(edge.get("door_slot", ""))
	if door_slot != "":
		total += float(mapping.get(door_slot, 0.0))
	for tag_value in edge.get("tags", []):
		total += float(mapping.get(str(tag_value), 0.0))
	return total


static func _path_result(board: Dictionary, path_nodes: Array, path_edges: Array, breakdown: Dictionary, goal_node: String, goal_key: String) -> Dictionary:
	var first_engagement := ""
	for node_value in path_nodes:
		if board.get("engagement_nodes", []).has(node_value):
			first_engagement = str(node_value)
			break
	return {
		"ok": true,
		"nodes": path_nodes,
		"edges": path_edges,
		"goal_node": goal_node,
		"goal_key": goal_key,
		"first_engagement_node": first_engagement,
		"cost_breakdown": breakdown,
		"total_cost": _breakdown_total(breakdown),
		"signature": "%s::%s" % [goal_key, ">".join(path_nodes)]
	}


static func _empty_breakdown() -> Dictionary:
	var result: Dictionary = {}
	for key in COST_KEYS:
		result[key] = 0.0
	return result


static func _add_breakdown(target: Dictionary, source: Dictionary) -> void:
	for key in COST_KEYS:
		target[key] = float(target.get(key, 0.0)) + float(source.get(key, 0.0))


static func _breakdown_total(breakdown: Dictionary) -> float:
	var total := 0.0
	for key in COST_KEYS:
		total += float(breakdown.get(key, 0.0))
	return total
