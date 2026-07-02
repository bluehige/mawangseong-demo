extends RefCounted
class_name ModuleGraph

const PlacedModuleScript = preload("res://scripts/dungeon_quarter/PlacedModule.gd")
const SocketValidatorScript = preload("res://scripts/dungeon_quarter/SocketValidator.gd")
const DungeonWalkMapScript = preload("res://scripts/dungeon_quarter/DungeonWalkMap.gd")
const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const IsoMathScript = preload("res://scripts/dungeon_quarter/IsoMath.gd")

const QUARTER_VIEW_FRAME = Rect2(410, 112, 1100, 720)

var rooms: Dictionary = {}
var modules: Dictionary = {}
var layout: Dictionary = {}
var placed_modules_by_id: Dictionary = {}
var adjacency: Dictionary = {}
var walk_map = null
var validation: Dictionary = {"ok": false, "errors": ["not initialized"]}
var tile_floor_cells: Dictionary = {}
var tile_walk_cells: Dictionary = {}
var tile_blocked_cells: Dictionary = {}
var tile_room_by_cell: Dictionary = {}
var tile_room_floor_cells: Dictionary = {}
var tile_room_walk_cells: Dictionary = {}
var tile_sockets: Array = []
var tile_size: Vector2 = Vector2(IsoMathScript.DEFAULT_TILE_WIDTH, IsoMathScript.DEFAULT_TILE_HEIGHT)
var tile_visual_scale := 1.0
var tile_world_origin := Vector2.ZERO

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

	_rebuild_tile_grid_debug_data()
	_rebuild_tile_projection()

	walk_map = DungeonWalkMapScript.new()
	walk_map.rebuild_from_modules(
		modules,
		layout,
		placed_modules_by_id,
		rooms,
		float(layout.get("world_cell_size", 16.0)),
		tile_world_origin,
		tile_visual_scale
	)

func validation_summary() -> Dictionary:
	return validation.duplicate(true)

func module_instance_ids() -> Array:
	var ids = placed_modules_by_id.keys()
	ids.sort()
	return ids

func placed_module_data(instance_id: String) -> Dictionary:
	var placed = placed_modules_by_id.get(instance_id, null)
	if placed == null:
		return {}
	return {
		"instance_id": placed.instance_id,
		"module_id": placed.module_id,
		"grid_origin": [placed.grid_origin.x, placed.grid_origin.y],
		"locked": placed.locked,
		"legacy_room_id": placed.legacy_room_id,
		"replaceable_with": placed.replaceable_with.duplicate(true)
	}

func module_data_for_instance(instance_id: String) -> Dictionary:
	var placed = placed_modules_by_id.get(instance_id, null)
	if placed == null:
		return {}
	return modules.get(placed.module_id, {})

func connection_pairs() -> Array:
	var pairs: Array = []
	for connection in layout.get("connections", []):
		var from_ref = _split_ref(str(connection.get("from", "")))
		var to_ref = _split_ref(str(connection.get("to", "")))
		if from_ref.is_empty() or to_ref.is_empty():
			continue
		pairs.append({
			"from_instance": from_ref["instance_id"],
			"from_socket": from_ref["socket_id"],
			"to_instance": to_ref["instance_id"],
			"to_socket": to_ref["socket_id"]
		})
	return pairs

func socket_data(instance_id: String, socket_id: String) -> Dictionary:
	var module = module_data_for_instance(instance_id)
	for socket in module.get("sockets", []):
		if str(socket.get("id", "")) == socket_id:
			return socket
	return {}

func debug_walkable_rects() -> Array:
	if walk_map == null:
		return []
	return walk_map.debug_walkable_rects()

func debug_blocked_rects() -> Array:
	if walk_map == null:
		return []
	return walk_map.debug_blocked_rects()

func debug_world_cell(world_position: Vector2) -> Vector2i:
	if walk_map == null:
		return Vector2i.ZERO
	return walk_map.debug_world_cell(world_position)

func debug_cell_rect(cell: Vector2i) -> Rect2:
	if walk_map == null:
		return Rect2()
	return walk_map.debug_cell_rect(cell)

func debug_cell_walkable(cell: Vector2i) -> bool:
	if walk_map == null:
		return false
	return walk_map.debug_cell_walkable(cell)

func debug_source_mode() -> String:
	if walk_map == null:
		return "none"
	return walk_map.debug_source_mode()

func debug_astar_cell_shape() -> int:
	if walk_map == null:
		return -1
	return walk_map.debug_astar_cell_shape()

func debug_floor_cells() -> Dictionary:
	return tile_floor_cells.duplicate(true)

func debug_walk_cells() -> Dictionary:
	return tile_walk_cells.duplicate(true)

func debug_tile_blocked_cells() -> Dictionary:
	return tile_blocked_cells.duplicate(true)

func debug_floor_mask(cell: Vector2i) -> int:
	return AutoTileMaskScript.get_4bit_mask(cell, tile_floor_cells)

func debug_floor_mask_values() -> Array:
	var values: Array = []
	for cell in tile_floor_cells.keys():
		var mask = debug_floor_mask(cell)
		if not values.has(mask):
			values.append(mask)
	values.sort()
	return values

func debug_room_id_for_tile_cell(cell: Vector2i) -> String:
	return str(tile_room_by_cell.get(cell, ""))

func debug_socket_cells() -> Array:
	return tile_sockets.duplicate(true)

func debug_tile_grid_size() -> Vector2i:
	var value: Array = layout.get("grid_size", [0, 0])
	if value.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))

func debug_tile_visual_scale() -> float:
	return tile_visual_scale

func debug_tile_world_origin() -> Vector2:
	return tile_world_origin

func tile_cell_center(cell: Vector2i) -> Vector2:
	return IsoMathScript.cell_to_iso_world(cell, tile_world_origin, tile_size.x * tile_visual_scale, tile_size.y * tile_visual_scale)

func tile_cell_rect(cell: Vector2i) -> Rect2:
	var scaled_size = tile_size * tile_visual_scale
	return Rect2(tile_cell_center(cell) - scaled_size * 0.5, scaled_size)

func tilemap_layer_origin_position() -> Vector2:
	return tile_world_origin - tile_size * 0.5 * tile_visual_scale

func center(room_id: String) -> Vector2:
	var cells: Array = tile_room_walk_cells.get(room_id, [])
	if cells.is_empty():
		cells = tile_room_floor_cells.get(room_id, [])
	if not cells.is_empty():
		var total := Vector2.ZERO
		for cell in cells:
			total += tile_cell_center(cell)
		return total / float(cells.size())
	var room: Dictionary = rooms.get(room_id, {})
	var value: Array = room.get("center", [0, 0])
	return Vector2(float(value[0]), float(value[1]))

func rect(room_id: String) -> Rect2:
	var cells: Array = tile_room_floor_cells.get(room_id, [])
	if not cells.is_empty():
		var bounds: Rect2 = tile_cell_rect(cells[0])
		for index in range(1, cells.size()):
			bounds = bounds.merge(tile_cell_rect(cells[index]))
		return bounds
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

func _rebuild_tile_grid_debug_data() -> void:
	tile_floor_cells.clear()
	tile_walk_cells.clear()
	tile_blocked_cells.clear()
	tile_room_by_cell.clear()
	tile_room_floor_cells.clear()
	tile_room_walk_cells.clear()
	tile_sockets.clear()
	for instance_id in placed_modules_by_id.keys():
		var placed = placed_modules_by_id[instance_id]
		var module: Dictionary = modules.get(placed.module_id, {})
		if module.is_empty():
			continue
		_add_global_cells(instance_id, placed.grid_origin, module.get("floor_cells", []), tile_floor_cells, true, tile_room_floor_cells)
		_add_global_cells(instance_id, placed.grid_origin, module.get("walk_cells", []), tile_walk_cells, false, tile_room_walk_cells)
		_add_global_cells(instance_id, placed.grid_origin, _blocked_cell_values(module), tile_blocked_cells, false)
		_add_global_cells(instance_id, placed.grid_origin, module.get("prop_block_cells", []), tile_blocked_cells, false)
		for socket in module.get("sockets", []):
			tile_sockets.append({
				"instance_id": str(instance_id),
				"socket_id": str(socket.get("id", "")),
				"side": _socket_side(socket),
				"cell": _global_cell(placed.grid_origin, _socket_local_cell(socket))
			})

func _add_global_cells(instance_id: String, origin: Vector2i, values: Array, target: Dictionary, assign_room: bool, room_target = null) -> void:
	for value in values:
		if not value is Array:
			continue
		var cell = _global_cell(origin, _array_to_cell(value))
		target[cell] = true
		if assign_room:
			tile_room_by_cell[cell] = instance_id
		if room_target != null:
			if not room_target.has(instance_id):
				room_target[instance_id] = []
			room_target[instance_id].append(cell)

func _rebuild_tile_projection() -> void:
	var tile_size_value: Array = layout.get("tile_size", [IsoMathScript.DEFAULT_TILE_WIDTH, IsoMathScript.DEFAULT_TILE_HEIGHT])
	if tile_size_value.size() >= 2:
		tile_size = Vector2(max(1.0, float(tile_size_value[0])), max(1.0, float(tile_size_value[1])))
	else:
		tile_size = Vector2(IsoMathScript.DEFAULT_TILE_WIDTH, IsoMathScript.DEFAULT_TILE_HEIGHT)

	var raw_bounds := _raw_iso_floor_bounds()
	if raw_bounds.size.x <= 0.0 or raw_bounds.size.y <= 0.0:
		tile_visual_scale = 1.0
		tile_world_origin = QUARTER_VIEW_FRAME.get_center()
		return

	tile_visual_scale = min(QUARTER_VIEW_FRAME.size.x / raw_bounds.size.x, QUARTER_VIEW_FRAME.size.y / raw_bounds.size.y)
	tile_visual_scale = clamp(tile_visual_scale, 1.0, 1.9)
	tile_world_origin = QUARTER_VIEW_FRAME.get_center() - raw_bounds.get_center() * tile_visual_scale

func _raw_iso_floor_bounds() -> Rect2:
	var initialized := false
	var bounds := Rect2()
	for cell in tile_floor_cells.keys():
		var center_point = IsoMathScript.cell_to_iso_world(cell, Vector2.ZERO, tile_size.x, tile_size.y)
		var rect = Rect2(center_point - tile_size * 0.5, tile_size)
		if not initialized:
			bounds = rect
			initialized = true
		else:
			bounds = bounds.merge(rect)
	if not initialized:
		return Rect2()
	return bounds

func _global_cell(origin: Vector2i, local_cell: Vector2i) -> Vector2i:
	return origin + local_cell

func _socket_local_cell(socket: Dictionary) -> Vector2i:
	var value: Array = socket.get("cell", socket.get("local_cell", [0, 0]))
	return _array_to_cell(value)

func _socket_side(socket: Dictionary) -> String:
	return str(socket.get("side", socket.get("dir", "")))

func _blocked_cell_values(module: Dictionary) -> Array:
	if module.has("blocked_cells"):
		return module.get("blocked_cells", [])
	return module.get("block_cells", [])

func _array_to_cell(value: Array) -> Vector2i:
	if value.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))

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
