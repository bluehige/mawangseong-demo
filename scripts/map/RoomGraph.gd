extends RefCounted
class_name RoomGraph

const V20WeightedPathService = preload("res://scripts/v20/path/V20WeightedPathService.gd")

const WALKABLE_ROOM_MARGIN = 34.0
const WALKABLE_CORRIDOR_HALF_WIDTH = 44.0

var rooms: Dictionary = {}

func setup(room_data: Dictionary) -> void:
	rooms = room_data

func center(room_id: String) -> Vector2:
	var room: Dictionary = rooms.get(room_id, {})
	var value: Array = room.get("center", [0, 0])
	return Vector2(float(value[0]), float(value[1]))

func rect(room_id: String) -> Rect2:
	var room: Dictionary = rooms.get(room_id, {})
	var value: Array = room.get("rect", [0, 0, 0, 0])
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))

func exits(room_id: String) -> Array:
	return rooms.get(room_id, {}).get("exits", [])

func path_between(start_room: String, goal_room: String) -> Array:
	if start_room == goal_room:
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

func path_points(start_room: String, goal_room: String) -> Array:
	var room_path = path_between(start_room, goal_room)
	var points: Array = []
	for room_id in room_path:
		points.append(center(room_id))
	return points

func weighted_path(board: Dictionary, start_node: String, goal_node: String, context: Dictionary = {}) -> Dictionary:
	return V20WeightedPathService.find_path(board, start_node, goal_node, context)

func is_walkable(point: Vector2) -> bool:
	for room_id in rooms.keys():
		if _safe_room_rect(room_id).has_point(point):
			return true
	for segment in _corridor_segments():
		if _distance_to_segment(point, segment[0], segment[1]) <= WALKABLE_CORRIDOR_HALF_WIDTH:
			return true
	return false

func clamp_to_walkable(point: Vector2) -> Vector2:
	if is_walkable(point):
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
		if direction.length() > WALKABLE_CORRIDOR_HALF_WIDTH:
			candidate += direction.normalized() * WALKABLE_CORRIDOR_HALF_WIDTH
		else:
			candidate = point
		var distance = candidate.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best_point = candidate
	return best_point

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

func _safe_room_rect(room_id: String) -> Rect2:
	var room_rect = rect(room_id)
	var margin = min(WALKABLE_ROOM_MARGIN, room_rect.size.x * 0.22, room_rect.size.y * 0.22)
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

