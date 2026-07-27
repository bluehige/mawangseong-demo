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
	day: int
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
	var route_start := "outside_approach" if instance_ids.has("outside_approach") else "entrance"
	var active_route: Array = graph.path_between(route_start, active_goal) if active_goal != "" else []
	var placements := PlacementSlotAdapter.build(graph, rooms, monster_roster)
	var snapshot := {
		"layout_id": layout_id,
		"layout_source": "user_custom" if layout_id.begins_with("user_") else "product",
		"layout_fingerprint": _fingerprint(fingerprint_records, graph.connection_pairs()),
		"rooms": room_ids,
		"corridors": corridor_ids,
		"active_route": active_route,
		"route_start": route_start,
		"enemy_goals": resolved_goals,
		"facility_slots": placements.get("facility_slots", []),
		"monster_slots": placements.get("monster_slots", []),
		"facility_placements": placements.get("facility_placements", []),
		"monster_placements": placements.get("monster_placements", []),
		"world_anchors": anchors,
		"combat_bounds": _rect_array(combat_bounds)
	}
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
	for room_id_value in snapshot.get("active_route", []):
		if not anchors.has(str(room_id_value)):
			errors.append("route room has no world anchor: %s" % str(room_id_value))
	for placement_value in snapshot.get("monster_placements", []):
		var placement: Dictionary = placement_value
		if not anchors.has(str(placement.get("room_id", ""))):
			errors.append("monster placement has no product room")
	for placement_value in snapshot.get("facility_placements", []):
		var placement: Dictionary = placement_value
		if str(placement.get("object_id", "")) == "":
			errors.append("facility placement has no product object")
	return errors


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
