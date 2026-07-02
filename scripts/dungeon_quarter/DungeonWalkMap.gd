extends RefCounted
class_name DungeonWalkMap

const WALKABLE_ROOM_MARGIN = 34.0
const WALKABLE_CORRIDOR_HALF_WIDTH = 44.0
const INVALID_CELL = Vector2i(-999999, -999999)

var cell_size: float = 16.0
var astar: AStarGrid2D = null
var walkable_cells: Dictionary = {}
var rooms: Dictionary = {}
var corridor_segments: Array = []
var region: Rect2i = Rect2i()

func rebuild_from_legacy_rooms(room_data: Dictionary, requested_cell_size: float = 16.0) -> void:
	cell_size = max(4.0, requested_cell_size)
	rooms = room_data
	corridor_segments = _corridor_segments()
	walkable_cells.clear()

	var bounds = _content_bounds().grow(96.0)
	var min_cell = _world_to_cell_raw(bounds.position)
	var max_cell = _world_to_cell_raw(bounds.position + bounds.size)
	region = Rect2i(min_cell, max_cell - min_cell + Vector2i(1, 1))

	astar = AStarGrid2D.new()
	astar.region = region
	astar.cell_size = Vector2(cell_size, cell_size)
	astar.offset = Vector2(cell_size * 0.5, cell_size * 0.5)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()

	for x in range(region.position.x, region.end.x):
		for y in range(region.position.y, region.end.y):
			var cell = Vector2i(x, y)
			var walkable = _legacy_point_walkable(cell_to_world(cell))
			astar.set_point_solid(cell, not walkable)
			if walkable:
				walkable_cells[cell] = true

func is_world_position_walkable(world_position: Vector2) -> bool:
	if astar == null:
		return false
	var cell = world_to_cell(world_position)
	return walkable_cells.has(cell)

func clamp_to_walkable(world_position: Vector2) -> Vector2:
	if is_world_position_walkable(world_position):
		return world_position
	var cell = get_nearest_walkable_cell(world_position)
	if cell == INVALID_CELL:
		return world_position
	return cell_to_world(cell)

func get_path_world(from_world: Vector2, to_world: Vector2) -> Array:
	if astar == null or walkable_cells.is_empty():
		return [to_world]
	var start_cell = get_nearest_walkable_cell(from_world)
	var goal_cell = get_nearest_walkable_cell(to_world)
	if start_cell == INVALID_CELL or goal_cell == INVALID_CELL:
		return [clamp_to_walkable(to_world)]
	if start_cell == goal_cell:
		return [cell_to_world(goal_cell)]
	var id_path = astar.get_id_path(start_cell, goal_cell)
	if id_path.is_empty():
		return [cell_to_world(goal_cell)]
	var points: Array = []
	for cell in id_path:
		points.append(cell_to_world(cell))
	return points

func get_nearest_walkable_cell(world_position: Vector2) -> Vector2i:
	var origin_cell = world_to_cell(world_position)
	if walkable_cells.has(origin_cell):
		return origin_cell
	var best_cell = INVALID_CELL
	var best_distance = INF
	for cell in walkable_cells.keys():
		var distance = cell_to_world(cell).distance_squared_to(world_position)
		if distance < best_distance:
			best_distance = distance
			best_cell = cell
	return best_cell

func world_to_cell(world_position: Vector2) -> Vector2i:
	return _world_to_cell_raw(world_position)

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(float(cell.x) * cell_size, float(cell.y) * cell_size) + Vector2(cell_size * 0.5, cell_size * 0.5)

func _world_to_cell_raw(world_position: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_position.x / cell_size)), int(floor(world_position.y / cell_size)))

func _legacy_point_walkable(point: Vector2) -> bool:
	for room_id in rooms.keys():
		if _safe_room_rect(room_id).has_point(point):
			return true
	for segment in corridor_segments:
		if _distance_to_segment(point, segment[0], segment[1]) <= WALKABLE_CORRIDOR_HALF_WIDTH:
			return true
	return false

func _content_bounds() -> Rect2:
	var initialized = false
	var bounds = Rect2()
	for room_id in rooms.keys():
		var room_rect = _room_rect(room_id)
		if not initialized:
			bounds = room_rect
			initialized = true
		else:
			bounds = bounds.merge(room_rect)
	for segment in corridor_segments:
		var segment_rect = Rect2(segment[0], Vector2.ZERO).expand(segment[1]).grow(WALKABLE_CORRIDOR_HALF_WIDTH)
		if not initialized:
			bounds = segment_rect
			initialized = true
		else:
			bounds = bounds.merge(segment_rect)
	if not initialized:
		return Rect2(Vector2.ZERO, Vector2(16, 16))
	return bounds

func _corridor_segments() -> Array:
	var segments: Array = []
	var seen: Dictionary = {}
	for room_id in rooms.keys():
		for exit_id in rooms.get(room_id, {}).get("exits", []):
			if not rooms.has(exit_id):
				continue
			var key = "%s-%s" % [room_id, exit_id]
			var reverse_key = "%s-%s" % [exit_id, room_id]
			if seen.has(key) or seen.has(reverse_key):
				continue
			seen[key] = true
			segments.append([_room_center(room_id), _room_center(exit_id)])
	return segments

func _room_center(room_id: String) -> Vector2:
	var value: Array = rooms.get(room_id, {}).get("center", [0, 0])
	return Vector2(float(value[0]), float(value[1]))

func _room_rect(room_id: String) -> Rect2:
	var value: Array = rooms.get(room_id, {}).get("rect", [0, 0, 0, 0])
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))

func _safe_room_rect(room_id: String) -> Rect2:
	var room_rect = _room_rect(room_id)
	var margin = min(WALKABLE_ROOM_MARGIN, room_rect.size.x * 0.22, room_rect.size.y * 0.22)
	return room_rect.grow(-margin)

func _closest_point_on_segment(point: Vector2, start: Vector2, end: Vector2) -> Vector2:
	var segment = end - start
	var length_squared = segment.length_squared()
	if length_squared <= 0.01:
		return start
	var t = clamp((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return start + segment * t

func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	return point.distance_to(_closest_point_on_segment(point, start, end))
