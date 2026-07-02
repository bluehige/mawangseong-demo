extends RefCounted
class_name DungeonWalkMap

const IsoMathScript = preload("res://scripts/dungeon_quarter/IsoMath.gd")

const WALKABLE_ROOM_MARGIN = 34.0
const WALKABLE_CORRIDOR_HALF_WIDTH = 44.0
const MODULE_CONNECTOR_HALF_WIDTH = 24.0
const INVALID_CELL = Vector2i(-999999, -999999)

var cell_size: float = 16.0
var astar: AStarGrid2D = null
var walkable_cells: Dictionary = {}
var blocked_cells: Dictionary = {}
var rooms: Dictionary = {}
var corridor_segments: Array = []
var region: Rect2i = Rect2i()
var build_source: String = "none"
var tile_grid_mode := false
var tile_size: Vector2 = Vector2(IsoMathScript.DEFAULT_TILE_WIDTH, IsoMathScript.DEFAULT_TILE_HEIGHT)
var tile_visual_scale := 1.0
var tile_world_origin := Vector2.ZERO

func rebuild_from_legacy_rooms(room_data: Dictionary, requested_cell_size: float = 16.0) -> void:
	cell_size = max(4.0, requested_cell_size)
	build_source = "legacy_rooms"
	tile_grid_mode = false
	rooms = room_data
	corridor_segments = _corridor_segments()
	walkable_cells.clear()
	blocked_cells.clear()

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
			else:
				blocked_cells[cell] = true

func rebuild_from_modules(
	module_data: Dictionary,
	layout_data: Dictionary,
	placed_modules_by_id: Dictionary,
	room_data: Dictionary,
	requested_cell_size: float = 16.0,
	requested_tile_world_origin: Vector2 = Vector2.INF,
	requested_tile_visual_scale: float = 1.0
) -> void:
	cell_size = max(4.0, requested_cell_size)
	build_source = "tile_grid_blueprints"
	tile_grid_mode = true
	rooms = room_data
	corridor_segments.clear()
	walkable_cells.clear()
	blocked_cells.clear()
	tile_size = _layout_tile_size(layout_data)
	tile_visual_scale = max(0.1, requested_tile_visual_scale)
	tile_world_origin = requested_tile_world_origin if requested_tile_world_origin != Vector2.INF else _array_to_world(layout_data.get("dungeon_origin", [0, 0]))

	for instance_id in placed_modules_by_id.keys():
		var placed = placed_modules_by_id[instance_id]
		var module: Dictionary = module_data.get(placed.module_id, {})
		if module.is_empty():
			continue
		_add_global_module_cells(placed.grid_origin, module.get("walk_cells", []), walkable_cells)
		_add_global_module_cells(placed.grid_origin, _blocked_cell_values(module), blocked_cells)
		_add_global_module_cells(placed.grid_origin, module.get("prop_block_cells", []), blocked_cells)
		_add_socket_entry_cells(placed.grid_origin, module, walkable_cells)

	for cell in blocked_cells.keys():
		walkable_cells.erase(cell)
	_ensure_connection_cells(module_data, layout_data, placed_modules_by_id)

	_rebuild_astar_from_registered_cells()

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
	if tile_grid_mode:
		return IsoMathScript.cell_to_iso_world(cell, tile_world_origin, tile_size.x * tile_visual_scale, tile_size.y * tile_visual_scale)
	return Vector2(float(cell.x) * cell_size, float(cell.y) * cell_size) + Vector2(cell_size * 0.5, cell_size * 0.5)

func debug_walkable_rects() -> Array:
	return _debug_cell_rects(walkable_cells)

func debug_blocked_rects() -> Array:
	return _debug_cell_rects(blocked_cells)

func debug_cell_rect(cell: Vector2i) -> Rect2:
	if tile_grid_mode:
		var scaled_size = tile_size * tile_visual_scale
		return Rect2(cell_to_world(cell) - scaled_size * 0.5, scaled_size)
	return Rect2(cell_to_world(cell) - Vector2(cell_size * 0.5, cell_size * 0.5), Vector2(cell_size, cell_size))

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

func _world_to_cell_raw(world_position: Vector2) -> Vector2i:
	if tile_grid_mode:
		return IsoMathScript.iso_world_to_cell(world_position, tile_world_origin, tile_size.x * tile_visual_scale, tile_size.y * tile_visual_scale)
	return Vector2i(int(floor(world_position.x / cell_size)), int(floor(world_position.y / cell_size)))

func _debug_cell_rects(cells: Dictionary) -> Array:
	var rects: Array = []
	for cell in cells.keys():
		rects.append(debug_cell_rect(cell))
	return rects

func _rebuild_astar_from_registered_cells() -> void:
	var used_cells: Array = []
	for cell in walkable_cells.keys():
		used_cells.append(cell)
	for cell in blocked_cells.keys():
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
	astar.cell_size = tile_size * tile_visual_scale if tile_grid_mode else Vector2(cell_size, cell_size)
	astar.offset = Vector2.ZERO if tile_grid_mode else Vector2(cell_size * 0.5, cell_size * 0.5)
	astar.cell_shape = AStarGrid2D.CELL_SHAPE_ISOMETRIC_DOWN if tile_grid_mode else AStarGrid2D.CELL_SHAPE_SQUARE
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()

	for x in range(region.position.x, region.end.x):
		for y in range(region.position.y, region.end.y):
			var cell = Vector2i(x, y)
			astar.set_point_solid(cell, not walkable_cells.has(cell))

func _layout_tile_size(layout_data: Dictionary) -> Vector2:
	var value: Array = layout_data.get("tile_size", [IsoMathScript.DEFAULT_TILE_WIDTH, IsoMathScript.DEFAULT_TILE_HEIGHT])
	if value.size() < 2:
		return Vector2(IsoMathScript.DEFAULT_TILE_WIDTH, IsoMathScript.DEFAULT_TILE_HEIGHT)
	return Vector2(max(1.0, float(value[0])), max(1.0, float(value[1])))

func _add_global_module_cells(origin: Vector2i, values: Array, target: Dictionary) -> void:
	for value in values:
		if value is Array:
			target[origin + _array_to_cell(value)] = true

func _add_socket_entry_cells(origin: Vector2i, module: Dictionary, target: Dictionary) -> void:
	var socket_entries: Dictionary = module.get("socket_entry_cells", {})
	for socket_id in socket_entries.keys():
		for value in socket_entries[socket_id]:
			if value is Array:
				target[origin + _array_to_cell(value)] = true

func _ensure_connection_cells(module_data: Dictionary, layout_data: Dictionary, placed_modules_by_id: Dictionary) -> void:
	for connection in layout_data.get("connections", []):
		for endpoint in [str(connection.get("from", "")), str(connection.get("to", ""))]:
			var ref = _split_ref(endpoint)
			if ref.is_empty():
				continue
			var placed = placed_modules_by_id.get(ref["instance_id"], null)
			if placed == null:
				continue
			var module: Dictionary = module_data.get(placed.module_id, {})
			var socket = _socket_data(module, str(ref["socket_id"]))
			if socket.is_empty():
				continue
			var cell = placed.grid_origin + _array_to_cell(socket.get("cell", socket.get("local_cell", [0, 0])))
			walkable_cells[cell] = true
			blocked_cells.erase(cell)

func _split_ref(reference: String) -> Dictionary:
	var parts = reference.split(":")
	if parts.size() != 2:
		return {}
	return {"instance_id": str(parts[0]), "socket_id": str(parts[1])}

func _socket_data(module: Dictionary, socket_id: String) -> Dictionary:
	for socket in module.get("sockets", []):
		if str(socket.get("id", "")) == socket_id:
			return socket
	return {}

func _module_footprint(module: Dictionary) -> Vector2i:
	var value: Array = module.get("size", module.get("footprint", [1, 1]))
	if value.size() < 2:
		return Vector2i.ONE
	return Vector2i(maxi(1, int(value[0])), maxi(1, int(value[1])))

func _blocked_cell_values(module: Dictionary) -> Array:
	if module.has("blocked_cells"):
		return module.get("blocked_cells", [])
	return module.get("block_cells", [])

func _module_world_rect(placed, module: Dictionary, layout_data: Dictionary) -> Rect2:
	var legacy_room_id = str(placed.legacy_room_id)
	if legacy_room_id != "" and rooms.has(legacy_room_id):
		return _room_rect(legacy_room_id)
	if rooms.has(str(placed.instance_id)):
		return _room_rect(str(placed.instance_id))
	var footprint = _module_footprint(module)
	var origin = _array_to_world(layout_data.get("dungeon_origin", [0, 0]))
	return Rect2(
		origin + Vector2(float(placed.grid_origin.x), float(placed.grid_origin.y)) * cell_size,
		Vector2(float(footprint.x) * cell_size, float(footprint.y) * cell_size)
	)

func _add_module_cells(cells: Array, footprint: Vector2i, module_rect: Rect2, target: Dictionary) -> void:
	for value in cells:
		if value is Array:
			_add_projected_local_cell(_array_to_cell(value), footprint, module_rect, target)

func _collect_socket_entry_points(instance_id: String, module: Dictionary, footprint: Vector2i, module_rect: Rect2, socket_points: Dictionary) -> void:
	var socket_entries: Dictionary = module.get("socket_entry_cells", {})
	for socket_id in socket_entries.keys():
		var key = "%s:%s" % [instance_id, str(socket_id)]
		if not socket_points.has(key):
			socket_points[key] = []
		for value in socket_entries[socket_id]:
			if value is Array:
				var local_cell = _array_to_cell(value)
				var rect = _projected_local_cell_rect(local_cell, footprint, module_rect)
				var point = rect.get_center()
				socket_points[key].append(point)

func _add_projected_local_cell(local_cell: Vector2i, footprint: Vector2i, module_rect: Rect2, target: Dictionary) -> void:
	_add_world_rect_cells(_projected_local_cell_rect(local_cell, footprint, module_rect), target, false)

func _projected_local_cell_rect(local_cell: Vector2i, footprint: Vector2i, module_rect: Rect2) -> Rect2:
	var cell_width = module_rect.size.x / float(maxi(1, footprint.x))
	var cell_height = module_rect.size.y / float(maxi(1, footprint.y))
	return Rect2(
		module_rect.position + Vector2(float(local_cell.x) * cell_width, float(local_cell.y) * cell_height),
		Vector2(cell_width, cell_height)
	)

func _add_world_rect_cells(rect: Rect2, target: Dictionary, clear_blocked: bool) -> void:
	var min_cell = _world_to_cell_raw(rect.position)
	var max_cell = _world_to_cell_raw(rect.end - Vector2(0.01, 0.01))
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var cell = Vector2i(x, y)
			if not rect.grow(cell_size * 0.02).has_point(cell_to_world(cell)):
				continue
			target[cell] = true
			if clear_blocked:
				blocked_cells.erase(cell)

func _add_world_point_cell(world_point: Vector2, target: Dictionary, clear_blocked: bool) -> void:
	var cell = world_to_cell(world_point)
	target[cell] = true
	if clear_blocked:
		blocked_cells.erase(cell)

func _add_connector_cells(start: Vector2, end: Vector2) -> void:
	var half_width = max(MODULE_CONNECTOR_HALF_WIDTH, cell_size * 1.4)
	var bounds = Rect2(start, Vector2.ZERO).expand(end).grow(half_width + cell_size)
	var min_cell = _world_to_cell_raw(bounds.position)
	var max_cell = _world_to_cell_raw(bounds.end)
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var cell = Vector2i(x, y)
			var point = cell_to_world(cell)
			if _distance_to_segment(point, start, end) <= half_width:
				walkable_cells[cell] = true
				blocked_cells.erase(cell)

func _average_point(points: Array) -> Vector2:
	if points.is_empty():
		return Vector2.INF
	var total = Vector2.ZERO
	for point in points:
		total += point
	return total / float(points.size())

func _array_to_cell(value: Array) -> Vector2i:
	if value.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))

func _array_to_world(value: Array) -> Vector2:
	if value.size() < 2:
		return Vector2.ZERO
	return Vector2(float(value[0]), float(value[1]))

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
