extends RefCounted
class_name RoomGraph

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

func _reconstruct_path(came_from: Dictionary, start_room: String, goal_room: String) -> Array:
	var path: Array = [goal_room]
	var current = goal_room
	while current != start_room:
		current = came_from.get(current, "")
		if current == "":
			return []
		path.push_front(current)
	return path

