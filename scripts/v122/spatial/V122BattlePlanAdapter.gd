class_name V122BattlePlanAdapter
extends RefCounted

const DefenseSegmentBuilder = preload("res://scripts/v122/spatial/V122DefenseSegmentBuilder.gd")
const PlacementSlotAdapter = preload("res://scripts/v122/spatial/V122PlacementSlotAdapter.gd")


static func build_snapshot(
	graph,
	layout_id: String,
	rooms: Dictionary,
	monster_roster: Dictionary,
	enemy_goals: Array,
	day: int,
	connector_state: Dictionary = {}
) -> Dictionary:
	var instance_ids: Array = graph.module_instance_ids()
	var room_ids: Array = []
	var corridor_ids: Array = []
	var anchors := {}
	var fingerprint_records: Array = []
	var combat_bounds := Rect2()
	var has_bounds := false
	for instance_id_value in instance_ids:
		var instance_id := str(instance_id_value)
		var module: Dictionary = graph.module_data_for_instance(instance_id)
		var module_type := str(module.get("module_type", ""))
		if module_type in ["corridor", "junction"]:
			corridor_ids.append(instance_id)
		else:
			room_ids.append(instance_id)
		var center: Vector2 = graph.center(instance_id)
		anchors[instance_id] = _vector_array(center)
		var bounds: Rect2 = graph.rect(instance_id)
		if bounds.size.x > 0.0 and bounds.size.y > 0.0:
			combat_bounds = bounds if not has_bounds else combat_bounds.merge(bounds)
			has_bounds = true
		fingerprint_records.append({
			"instance_id": instance_id,
			"placed": graph.placed_module_data(instance_id),
			"center": anchors[instance_id]
		})

	var resolved_goals: Array = []
	for goal_value in enemy_goals:
		var goal_id := str(goal_value)
		if goal_id != "" and instance_ids.has(goal_id) and not resolved_goals.has(goal_id):
			resolved_goals.append(goal_id)
	if resolved_goals.is_empty() and instance_ids.has("throne"):
		resolved_goals.append("throne")
	var active_goal := str(resolved_goals.front()) if not resolved_goals.is_empty() else ""
	var topology := _combat_topology(graph)
	var lane_snapshot := _lane_snapshot(graph, topology, active_goal)
	var lane_routes: Dictionary = lane_snapshot.get("lane_routes", {})
	var route_starts: Dictionary = lane_snapshot.get("route_starts", {})
	var lane_entries: Dictionary = lane_snapshot.get("lane_entries", {})
	var lane_labels: Dictionary = lane_snapshot.get("lane_labels", {})
	var primary_lane_id := str(lane_snapshot.get("primary_lane_id", ""))
	var route_start := str(lane_snapshot.get("route_start", ""))
	if route_start == "":
		route_start = "outside_approach" if instance_ids.has("outside_approach") else "entrance"
	var active_route: Array = lane_snapshot.get("active_route", [])
	if active_route.is_empty() and active_goal != "":
		active_route = graph.path_between(route_start, active_goal)
	var placements := PlacementSlotAdapter.build(graph, rooms, monster_roster)
	var snapshot := {
		"layout_id": layout_id,
		"layout_source": "user_custom" if layout_id.begins_with("user_") else "product",
		"layout_fingerprint": _fingerprint(fingerprint_records, graph.connection_pairs()),
		"rooms": room_ids,
		"corridors": corridor_ids,
		"active_route": active_route,
		"route_start": route_start,
		"primary_lane_id": primary_lane_id,
		"lane_routes": lane_routes,
		"route_starts": route_starts,
		"lane_entries": lane_entries,
		"lane_labels": lane_labels,
		"enemy_goals": resolved_goals,
		"defense_zones": topology.get("defense_zones", []).duplicate(true),
		"facility_slot_contracts": placements.get("facility_slot_contracts", []),
		"facility_slots": placements.get("facility_slots", []),
		"monster_slots": placements.get("monster_slots", []),
		"facility_placements": placements.get("facility_placements", []),
		"monster_placements": placements.get("monster_placements", []),
		"world_anchors": anchors,
		"combat_bounds": _rect_array(combat_bounds)
	}
	snapshot["defender_connector"] = _connector_snapshot(
		graph,
		topology,
		day,
		connector_state
	)
	snapshot["defense_segments"] = DefenseSegmentBuilder.build(active_route, anchors, rooms, day)
	return snapshot


static func validate_snapshot(snapshot: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if str(snapshot.get("layout_id", "")) == "":
		errors.append("layout_id is empty")
	if str(snapshot.get("layout_fingerprint", "")).length() != 64:
		errors.append("layout_fingerprint is invalid")
	if snapshot.get("rooms", []).is_empty():
		errors.append("rooms are empty")
	if snapshot.get("active_route", []).is_empty():
		errors.append("active_route is empty")
	if snapshot.get("defense_segments", []).is_empty():
		errors.append("defense_segments are empty")
	var anchors: Dictionary = snapshot.get("world_anchors", {})
	var lane_routes = snapshot.get("lane_routes", {})
	var route_starts = snapshot.get("route_starts", {})
	var lane_entries = snapshot.get("lane_entries", {})
	var lane_labels = snapshot.get("lane_labels", {})
	if not lane_routes is Dictionary:
		errors.append("lane_routes are invalid")
		lane_routes = {}
	if not route_starts is Dictionary:
		errors.append("route_starts are invalid")
		route_starts = {}
	if not lane_entries is Dictionary:
		errors.append("lane_entries are invalid")
		lane_entries = {}
	if not lane_labels is Dictionary:
		errors.append("lane_labels are invalid")
		lane_labels = {}
	for room_id_value in snapshot.get("active_route", []):
		if not anchors.has(str(room_id_value)):
			errors.append("route room has no world anchor: %s" % str(room_id_value))
	for lane_id_value in lane_routes.keys():
		var lane_id := str(lane_id_value)
		var route = lane_routes.get(lane_id, [])
		if not route is Array or route.is_empty():
			errors.append("lane route is empty: %s" % lane_id)
			continue
		var route_start := str(route_starts.get(lane_id, ""))
		if route_start == "" or str(route.front()) != route_start:
			errors.append("lane route start is invalid: %s" % lane_id)
		var entry_room_id := str(lane_entries.get(lane_id, ""))
		if entry_room_id == "" or not route.has(entry_room_id):
			errors.append("lane entry is invalid: %s" % lane_id)
		if str(lane_labels.get(lane_id, "")) == "":
			errors.append("lane label is empty: %s" % lane_id)
		for room_id_value in route:
			if not anchors.has(str(room_id_value)):
				errors.append("lane route room has no world anchor: %s" % str(room_id_value))
	var zone_ids := {}
	for zone_value in snapshot.get("defense_zones", []):
		if not zone_value is Dictionary:
			errors.append("defense zone is invalid")
			continue
		var zone_id := str(zone_value.get("zone_id", ""))
		var anchor_room_id := str(zone_value.get("anchor_room_id", ""))
		if zone_id == "" or zone_ids.has(zone_id):
			errors.append("defense zone id is invalid: %s" % zone_id)
		else:
			zone_ids[zone_id] = true
		if not anchors.has(anchor_room_id):
			errors.append("defense zone has no world anchor: %s" % zone_id)
	for contract_value in snapshot.get("facility_slot_contracts", []):
		if not contract_value is Dictionary:
			errors.append("facility slot contract is invalid")
			continue
		if str(contract_value.get("slot_id", "")) == "":
			errors.append("facility slot contract has no id")
		if not anchors.has(str(contract_value.get("room_id", ""))):
			errors.append("facility slot contract has no product room")
		for zone_id_value in contract_value.get("linked_zone_ids", []):
			if not zone_ids.has(str(zone_id_value)):
				errors.append("facility slot contract has an invalid linked zone")
	for placement_value in snapshot.get("monster_placements", []):
		var placement: Dictionary = placement_value
		if not anchors.has(str(placement.get("room_id", ""))):
			errors.append("monster placement has no product room")
		var zone_id := str(placement.get("defense_zone_id", ""))
		if zone_id != "" and not zone_ids.has(zone_id):
			errors.append("monster placement has an invalid defense zone")
	for placement_value in snapshot.get("facility_placements", []):
		var placement: Dictionary = placement_value
		if str(placement.get("object_id", "")) == "":
			errors.append("facility placement has no product object")
	if snapshot.has("defender_connector"):
		var connector = snapshot.get("defender_connector")
		if not connector is Dictionary:
			errors.append("defender connector is invalid")
		elif not connector.is_empty():
			var connector_id := str(connector.get("connector_id", ""))
			var from_zone_id := str(connector.get("from_zone_id", ""))
			var to_zone_id := str(connector.get("to_zone_id", ""))
			if connector_id == "":
				errors.append("defender connector has no id")
			if not zone_ids.has(from_zone_id) or not zone_ids.has(to_zone_id):
				errors.append("defender connector has an invalid zone")
			if not anchors.has(str(connector.get("from_room_id", ""))) or not anchors.has(str(connector.get("to_room_id", ""))):
				errors.append("defender connector has an invalid room")
			if not connector.get("world_anchor") is Array or connector.get("world_anchor", []).size() != 2:
				errors.append("defender connector has no world anchor")
			if not connector.get("route_points") is Array or connector.get("route_points", []).size() != 3:
				errors.append("defender connector route is invalid")
			if not connector.get("cost") is Dictionary:
				errors.append("defender connector cost is invalid")
			if bool(connector.get("defender_only", false)) and bool(connector.get("enemy_path_allowed", false)):
				errors.append("defender-only connector allows enemy paths")
	return errors


static func _combat_topology(graph) -> Dictionary:
	var layout_value = graph.get("layout")
	if not layout_value is Dictionary:
		return {}
	var topology_value = layout_value.get("combat_topology", {})
	return topology_value if topology_value is Dictionary else {}


static func _connector_snapshot(
	graph,
	topology: Dictionary,
	day: int,
	connector_state: Dictionary
) -> Dictionary:
	var contract_value = topology.get("connector_contract", {})
	if not contract_value is Dictionary or contract_value.is_empty():
		return {}
	var contract: Dictionary = contract_value
	var connector_id := str(contract.get("connector_id", ""))
	var from_zone_id := str(contract.get("from_zone_id", ""))
	var to_zone_id := str(contract.get("to_zone_id", ""))
	var zones := {}
	for zone_value in topology.get("defense_zones", []):
		if not zone_value is Dictionary:
			continue
		var zone_id := str(zone_value.get("zone_id", ""))
		if zone_id != "":
			zones[zone_id] = zone_value
	var from_zone: Dictionary = zones.get(from_zone_id, {})
	var to_zone: Dictionary = zones.get(to_zone_id, {})
	var from_room_id := str(from_zone.get("anchor_room_id", ""))
	var to_room_id := str(to_zone.get("anchor_room_id", ""))
	if (
		connector_id == ""
		or from_room_id == ""
		or to_room_id == ""
		or not graph.module_instance_ids().has(from_room_id)
		or not graph.module_instance_ids().has(to_room_id)
	):
		return {}
	var grid_origin_value = contract.get("grid_origin", [])
	if not grid_origin_value is Array or grid_origin_value.size() != 2:
		return {}
	var grid_origin := Vector2i(
		int(grid_origin_value[0]),
		int(grid_origin_value[1])
	)
	var connector_anchor: Vector2 = (
		graph.tile_cell_center(grid_origin)
		if graph.has_method("tile_cell_center")
		else graph.center(from_room_id).lerp(graph.center(to_room_id), 0.5)
	)
	var state_matches := str(connector_state.get("connector_id", "")) == connector_id
	var built := state_matches and bool(connector_state.get("built", false))
	var built_day := int(connector_state.get("built_day", 0)) if built else 0
	var unlock_day := maxi(1, int(contract.get("unlock_day", 1)))
	return {
		"connector_id": connector_id,
		"from_zone_id": from_zone_id,
		"to_zone_id": to_zone_id,
		"from_lane_id": str(from_zone.get("lane_id", "")),
		"to_lane_id": str(to_zone.get("lane_id", "")),
		"from_room_id": from_room_id,
		"to_room_id": to_room_id,
		"grid_origin": [grid_origin.x, grid_origin.y],
		"world_anchor": _vector_array(connector_anchor),
		"route_points": [
			_vector_array(graph.center(from_room_id)),
			_vector_array(connector_anchor),
			_vector_array(graph.center(to_room_id))
		],
		"initial_state": str(contract.get("initial_state", "collapsed_unplaced")),
		"state": "built" if built else ("available" if day >= unlock_day else str(contract.get("initial_state", "collapsed_unplaced"))),
		"defender_only": bool(contract.get("defender_only", true)),
		"enemy_path_allowed": bool(contract.get("enemy_path_allowed", false)),
		"unlock_day": unlock_day,
		"unlocked": day >= unlock_day,
		"cost": contract.get("cost", {}).duplicate(true) if contract.get("cost") is Dictionary else {},
		"permanent": bool(contract.get("permanent", true)),
		"built": built,
		"built_day": built_day
	}


static func _lane_snapshot(graph, topology: Dictionary, active_goal: String) -> Dictionary:
	var lanes_value = topology.get("lanes", {})
	if not lanes_value is Dictionary or lanes_value.is_empty():
		return {}
	var lane_ids: Array = lanes_value.keys()
	lane_ids.sort()
	var lane_routes := {}
	var route_starts := {}
	var lane_entries := {}
	var lane_labels := {}
	var topology_goal := str(topology.get("goal_room_id", active_goal))
	for lane_id_value in lane_ids:
		var lane_id := str(lane_id_value)
		var lane: Dictionary = lanes_value.get(lane_id, {})
		var route_start := str(lane.get("outside_room_id", lane.get("entry_room_id", "")))
		if route_start == "":
			continue
		var route: Array = _string_array(lane.get("route", []))
		if route.is_empty() or str(route.front()) != route_start or str(route.back()) != topology_goal:
			route = graph.path_between(route_start, topology_goal)
		if route.is_empty():
			continue
		lane_routes[lane_id] = route
		route_starts[lane_id] = route_start
		lane_entries[lane_id] = str(lane.get("entry_room_id", route_start))
		lane_labels[lane_id] = str(lane.get("display_name", lane_id))
	if lane_routes.is_empty():
		return {}
	var primary_lane_id := "lane_a" if lane_routes.has("lane_a") else str(lane_routes.keys().front())
	var route_start := str(route_starts.get(primary_lane_id, ""))
	var active_route: Array = lane_routes.get(primary_lane_id, [])
	if active_goal != "" and active_goal != topology_goal:
		active_route = graph.path_between(route_start, active_goal)
	return {
		"primary_lane_id": primary_lane_id,
		"lane_routes": lane_routes,
		"route_starts": route_starts,
		"lane_entries": lane_entries,
		"lane_labels": lane_labels,
		"route_start": route_start,
		"active_route": active_route
	}


static func _string_array(value) -> Array:
	if not value is Array:
		return []
	var result: Array = []
	for entry in value:
		var text := str(entry)
		if text == "":
			return []
		result.append(text)
	return result


static func _fingerprint(instances: Array, connections: Array) -> String:
	var records := {
		"instances": instances,
		"connections": connections
	}
	return JSON.stringify(records).sha256_text()


static func _vector_array(value: Vector2) -> Array:
	return [snappedf(value.x, 0.001), snappedf(value.y, 0.001)]


static func _rect_array(value: Rect2) -> Array:
	return [
		snappedf(value.position.x, 0.001),
		snappedf(value.position.y, 0.001),
		snappedf(value.size.x, 0.001),
		snappedf(value.size.y, 0.001)
	]
