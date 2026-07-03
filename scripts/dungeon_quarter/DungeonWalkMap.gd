extends RefCounted
class_name DungeonWalkMap

const IsoMathScript = preload("res://scripts/dungeon_quarter/IsoMath.gd")

const INVALID_CELL = Vector2i(-999999, -999999)

var astar: AStarGrid2D = null
var walkable_cells: Dictionary = {}
var blocked_cells: Dictionary = {}
var cell_data: Dictionary = {}
var open_edge_set: Dictionary = {}
var region: Rect2i = Rect2i()
var tile_size: Vector2 = Vector2(IsoMathScript.DEFAULT_TILE_WIDTH, IsoMathScript.DEFAULT_TILE_HEIGHT)
var tile_visual_scale := 1.0
var tile_world_origin := Vector2.ZERO
var build_source := "none"

func rebuild_from_cell_data(
	source_cell_data: Dictionary,
	source_open_edge_set: Dictionary,
	requested_tile_size: Vector2,
	requested_tile_world_origin: Vector2,
	requested_tile_visual_scale: float
) -> void:
	build_source = "v2_cell_data"
	cell_data = source_cell_data.duplicate(true)
	open_edge_set = source_open_edge_set.duplicate(true)
	tile_size = requested_tile_size
	tile_world_origin = requested_tile_world_origin
	tile_visual_scale = max(0.1, requested_tile_visual_scale)
	walkable_cells.clear()
	blocked_cells.clear()

	for cell in cell_data.keys():
		var data: Dictionary = cell_data[cell]
		if bool(data.get("walkable", false)):
			walkable_cells[cell] = true
		elif bool(data.get("active", false)):
			blocked_cells[cell] = true

	_rebuild_astar()

func is_world_position_walkable(world_position: Vector2) -> bool:
	if astar == null:
		return false
	return walkable_cells.has(world_to_cell(world_position))

func clamp_to_walkable(world_position: Vector2) -> Vector2:
	if is_world_position_walkable(world_position):
		return world_position
	var nearest = get_nearest_walkable_cell(world_position)
	if nearest == INVALID_CELL:
		return world_position
	return cell_to_world(nearest)

func get_path_world(from_world: Vector2, to_world: Vector2) -> Array:
	if astar == null or walkable_cells.is_empty():
		return [to_world]
	var start_cell = get_nearest_walkable_cell(from_world)
	var goal_cell = get_nearest_walkable_cell(to_world)
	if start_cell == INVALID_CELL or goal_cell == INVALID_CELL:
		return [clamp_to_walkable(to_world)]
	if start_cell == goal_cell:
		return [cell_to_world(goal_cell)]
	var id_path = _edge_constrained_path(start_cell, goal_cell)
	if id_path.is_empty():
		return [cell_to_world(goal_cell)]
	var points: Array = []
	for cell in id_path:
		points.append(cell_to_world(cell))
	return points

func _edge_constrained_path(start_cell: Vector2i, goal_cell: Vector2i) -> Array:
	if start_cell == goal_cell:
		return [start_cell]
	var frontier: Array = [start_cell]
	var came_from: Dictionary = {start_cell: INVALID_CELL}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		for side in ["N", "E", "S", "W"]:
			if not open_edge_set.has(_edge_key(current, side)):
				continue
			var next_cell: Vector2i = current + _dir(side)
			if not walkable_cells.has(next_cell) or came_from.has(next_cell):
				continue
			came_from[next_cell] = current
			if next_cell == goal_cell:
				return _reconstruct_cell_path(came_from, start_cell, goal_cell)
			frontier.append(next_cell)
	return []

func _reconstruct_cell_path(came_from: Dictionary, start_cell: Vector2i, goal_cell: Vector2i) -> Array:
	var path: Array = [goal_cell]
	var current: Vector2i = goal_cell
	while current != start_cell:
		current = came_from.get(current, INVALID_CELL)
		if current == INVALID_CELL:
			return []
		path.push_front(current)
	return path

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
	return IsoMathScript.iso_world_to_cell(
		world_position,
		tile_world_origin,
		tile_size.x * tile_visual_scale,
		tile_size.y * tile_visual_scale
	)

func cell_to_world(cell: Vector2i) -> Vector2:
	return IsoMathScript.cell_to_iso_world(
		cell,
		tile_world_origin,
		tile_size.x * tile_visual_scale,
		tile_size.y * tile_visual_scale
	)

func debug_walkable_rects() -> Array:
	return _debug_cell_rects(walkable_cells)

func debug_blocked_rects() -> Array:
	return _debug_cell_rects(blocked_cells)

func debug_cell_rect(cell: Vector2i) -> Rect2:
	var scaled_size = tile_size * tile_visual_scale
	return Rect2(cell_to_world(cell) - scaled_size * 0.5, scaled_size)

func debug_world_cell(world_position: Vector2) -> Vector2i:
	return world_to_cell(world_position)

func debug_cell_walkable(cell: Vector2i) -> bool:
	return walkable_cells.has(cell)

func debug_source_mode() -> String:
	return build_source

func debug_astar_cell_shape() -> int:
	if astar == null:
		return -1
	return int(astar.cell_shape)

func _debug_cell_rects(cells: Dictionary) -> Array:
	var rects: Array = []
	for cell in cells.keys():
		rects.append(debug_cell_rect(cell))
	return rects

func _edge_key(cell: Vector2i, side: String) -> String:
	return "%d,%d:%s" % [cell.x, cell.y, side]

func _dir(side: String) -> Vector2i:
	match side:
		"N":
			return Vector2i(0, -1)
		"E":
			return Vector2i(1, 0)
		"S":
			return Vector2i(0, 1)
		"W":
			return Vector2i(-1, 0)
	return Vector2i.ZERO

func _rebuild_astar() -> void:
	var used_cells: Array = []
	for cell in cell_data.keys():
		if bool(cell_data[cell].get("active", false)):
			used_cells.append(cell)
	if used_cells.is_empty():
		astar = null
		region = Rect2i()
		return

	var min_cell: Vector2i = used_cells[0]
	var max_cell: Vector2i = used_cells[0]
	for cell in used_cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	region = Rect2i(min_cell - Vector2i(1, 1), max_cell - min_cell + Vector2i(3, 3))

	astar = AStarGrid2D.new()
	astar.region = region
	astar.cell_size = tile_size * tile_visual_scale
	astar.offset = Vector2.ZERO
	astar.cell_shape = AStarGrid2D.CELL_SHAPE_ISOMETRIC_DOWN
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()

	for x in range(region.position.x, region.end.x):
		for y in range(region.position.y, region.end.y):
			var cell := Vector2i(x, y)
			astar.set_point_solid(cell, not walkable_cells.has(cell))
