extends RefCounted
class_name ModuleGraph

const PlacedModuleScript = preload("res://scripts/dungeon_quarter/PlacedModule.gd")
const SocketValidatorScript = preload("res://scripts/dungeon_quarter/SocketValidator.gd")
const DungeonWalkMapScript = preload("res://scripts/dungeon_quarter/DungeonWalkMap.gd")

var rooms: Dictionary = {}
var modules: Dictionary = {}
var layout: Dictionary = {}
var placed_modules_by_id: Dictionary = {}
var adjacency: Dictionary = {}
var walk_map = null
var validation: Dictionary = {"ok": false, "errors": ["not initialized"]}

func setup_quarter(module_data: Dictionary, layout_data: Dictionary, legacy_rooms: Dictionary) -> void:
	modules = module_data.duplicate(true)
	layout = layout_data.duplicate(true)
	rooms = legacy_rooms.duplicate(true)
	placed_modules_by_id.clear()
	adjacency.clear()

	for entry in layout.get("placed_modules", []):
		var placed = PlacedModuleScript.from_dict(entry)
		if placed.instance_id == "":
			continue
		placed_modules_by_id[placed.instance_id] = placed
		adjacency[placed.instance_id] = []

	_build_adjacency()
	var validator = SocketValidatorScript.new()
	validation = validator.validate_layout(modules, layout)
	if not bool(validation.get("ok", false)):
		push_warning("Quarter module layout validation failed: %s" % str(validation.get("errors", [])))

	walk_map = DungeonWalkMapScript.new()
	walk_map.rebuild_from_legacy_rooms(rooms, float(layout.get("world_cell_size", 16.0)))

func validation_summary() -> Dictionary:
	return validation.duplicate(true)

func center(room_id: String) -> Vector2:
	var room: Dictionary = rooms.get(room_id, {})
	var value: Array = room.get("center", [0, 0])
	return Vector2(float(value[0]), float(value[1]))

func rect(room_id: String) -> Rect2:
	var room: Dictionary = rooms.get(room_id, {})
	var value: Array = room.get("rect", [0, 0, 0, 0])
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))

func exits(room_id: String) -> Array:
	if adjacency.has(room_id) and not adjacency[room_id].is_empty():
		return adjacency[room_id].duplicate()
	return rooms.get(room_id, {}).get("exits", []).duplicate()

func path_between(start_room: String, goal_room: String) -> Array:
	if start_room == goal_room and rooms.has(start_room):
		return [start_room]
	if not rooms.has(start_room) or not rooms.has(goal_room):
		return []
	var frontier: Array = [start_room]
	var came_from: Dictionary = {start_room: ""}
	while not frontier.is_empty():
		var current: String = frontier.pop_front()
		for next_room in exits(current):
			if came_from.has(next_room):
				continue
			came_from[next_room] = current
			if next_room == goal_room:
				return _reconstruct_path(came_from, start_room, goal_room)
			frontier.append(next_room)
	return []

func find_path(start_instance_id: String, goal_instance_id: String) -> Array:
	return path_between(start_instance_id, goal_instance_id)

func path_points(start_room: String, goal_room: String) -> Array:
	var room_path = path_between(start_room, goal_room)
	if room_path.is_empty():
		return []
	var points: Array = [center(room_path[0])]
	var previous = points[0]
	for index in range(1, room_path.size()):
		var target = center(room_path[index])
		var segment = path_to_point(previous, target)
		_append_segment(points, segment)
		previous = target
	return points

func path_to_point(from_world: Vector2, to_world: Vector2) -> Array:
	if walk_map != null:
		return walk_map.get_path_world(from_world, to_world)
	return [clamp_to_walkable(to_world)]

func is_walkable(point: Vector2) -> bool:
	if walk_map != null:
		return walk_map.is_world_position_walkable(point)
	return _legacy_is_walkable(point)

func clamp_to_walkable(point: Vector2) -> Vector2:
	if walk_map != null:
		return walk_map.clamp_to_walkable(point)
	return _legacy_clamp_to_walkable(point)

func closest_room(point: Vector2) -> String:
	var best_room = ""
	var best_distance = INF
	for room_id in rooms.keys():
		var room_rect = rect(room_id)
		if room_rect.has_point(point):
			return room_id
		var distance = center(room_id).distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best_room = room_id
	return best_room

func _build_adjacency() -> void:
	for connection in layout.get("connections", []):
		var from_ref = _split_ref(str(connection.get("from", "")))
		var to_ref = _split_ref(str(connection.get("to", "")))
		if from_ref.is_empty() or to_ref.is_empty():
			continue
		var from_id = from_ref["instance_id"]
		var to_id = to_ref["instance_id"]
		if not adjacency.has(from_id):
			adjacency[from_id] = []
		if not adjacency.has(to_id):
			adjacency[to_id] = []
		if not adjacency[from_id].has(to_id):
			adjacency[from_id].append(to_id)
		if not adjacency[to_id].has(from_id):
			adjacency[to_id].append(from_id)

func _split_ref(reference: String) -> Dictionary:
	var parts = reference.split(":")
	if parts.size() != 2:
		return {}
	return {"instance_id": str(parts[0]), "socket_id": str(parts[1])}

func _append_segment(points: Array, segment: Array) -> void:
	for point in segment:
		if not points.is_empty() and points[points.size() - 1].distance_to(point) < 0.1:
			continue
		points.append(point)

func _legacy_is_walkable(point: Vector2) -> bool:
	for room_id in rooms.keys():
		if _safe_room_rect(room_id).has_point(point):
			return true
	for segment in _corridor_segments():
		if _distance_to_segment(point, segment[0], segment[1]) <= DungeonWalkMapScript.WALKABLE_CORRIDOR_HALF_WIDTH:
			return true
	return false

func _legacy_clamp_to_walkable(point: Vector2) -> Vector2:
	if _legacy_is_walkable(point):
		return point
	var best_point = point
	var best_distance = INF
	for room_id in rooms.keys():
		var candidate = _closest_point_in_rect(point, _safe_room_rect(room_id))
		var distance = candidate.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best_point = candidate
	for segment in _corridor_segments():
		var on_segment = _closest_point_on_segment(point, segment[0], segment[1])
		var direction = point - on_segment
		var candidate = on_segment
		if direction.length() > DungeonWalkMapScript.WALKABLE_CORRIDOR_HALF_WIDTH:
			candidate += direction.normalized() * DungeonWalkMapScript.WALKABLE_CORRIDOR_HALF_WIDTH
		else:
			candidate = point
		var distance = candidate.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best_point = candidate
	return best_point

func _safe_room_rect(room_id: String) -> Rect2:
	var room_rect = rect(room_id)
	var margin = min(DungeonWalkMapScript.WALKABLE_ROOM_MARGIN, room_rect.size.x * 0.22, room_rect.size.y * 0.22)
	return room_rect.grow(-margin)

func _corridor_segments() -> Array:
	var segments: Array = []
	var seen: Dictionary = {}
	for room_id in rooms.keys():
		for exit_id in exits(room_id):
			if not rooms.has(exit_id):
				continue
			var key = "%s-%s" % [room_id, exit_id]
			var reverse_key = "%s-%s" % [exit_id, room_id]
			if seen.has(key) or seen.has(reverse_key):
				continue
			seen[key] = true
			segments.append([center(room_id), center(exit_id)])
	return segments

func _closest_point_on_segment(point: Vector2, start: Vector2, end: Vector2) -> Vector2:
	var segment = end - start
	var length_squared = segment.length_squared()
	if length_squared <= 0.01:
		return start
	var t = clamp((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return start + segment * t

func _closest_point_in_rect(point: Vector2, room_rect: Rect2) -> Vector2:
	return Vector2(
		clamp(point.x, room_rect.position.x, room_rect.position.x + room_rect.size.x),
		clamp(point.y, room_rect.position.y, room_rect.position.y + room_rect.size.y)
	)

func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	return point.distance_to(_closest_point_on_segment(point, start, end))

func _reconstruct_path(came_from: Dictionary, start_room: String, goal_room: String) -> Array:
	var path: Array = [goal_room]
	var current = goal_room
	while current != start_room:
		current = came_from.get(current, "")
		if current == "":
			return []
		path.push_front(current)
	return path
