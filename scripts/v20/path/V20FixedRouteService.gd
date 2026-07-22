class_name V20FixedRouteService
extends RefCounted


static func has_declared_route(board: Dictionary) -> bool:
	return str(board.get("route_mode", "")) == "fixed" and board.get("fixed_route") is Dictionary


static func route_to_goal(board: Dictionary, start_node: String, goal_node: String, goal_key: String) -> Dictionary:
	if not has_declared_route(board):
		return {"ok": false, "error": "fixed route is not declared", "nodes": [], "edges": []}
	var declaration: Dictionary = board.get("fixed_route", {})
	var declared_nodes: Array = declaration.get("nodes", [])
	var declared_edges: Array = declaration.get("edges", [])
	var start_index := declared_nodes.find(start_node)
	var goal_index := declared_nodes.find(goal_node)
	if start_index < 0 or goal_index < start_index:
		return {"ok": false, "error": "goal is not on the declared route", "nodes": [], "edges": []}
	if declared_edges.size() != declared_nodes.size() - 1:
		return {"ok": false, "error": "declared route edge count mismatch", "nodes": [], "edges": []}

	var route_nodes: Array = declared_nodes.slice(start_index, goal_index + 1)
	var route_edges: Array = declared_edges.slice(start_index, goal_index)
	var first_engagement := ""
	for node_value in route_nodes:
		if board.get("engagement_nodes", []).has(node_value):
			first_engagement = str(node_value)
			break
	return {
		"ok": true,
		"route_mode": "fixed",
		"fixed_route_id": str(declaration.get("id", "")),
		"nodes": route_nodes,
		"edges": route_edges,
		"goal_node": goal_node,
		"goal_key": goal_key,
		"first_engagement_node": first_engagement,
		"signature": "%s::%s" % [goal_key, ">".join(route_nodes)]
	}


static func full_route(board: Dictionary, goal_key: String = "throne") -> Dictionary:
	var declaration: Dictionary = board.get("fixed_route", {})
	return route_to_goal(board, str(declaration.get("start_node", "")), str(declaration.get("goal_node", "")), goal_key)
