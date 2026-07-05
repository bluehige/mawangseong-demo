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
var validation: Dictionary = {"ok": false, "errors": ["not initialized"]}
var walk_map = null

var max_grid_size := Vector2i(20, 20)
var active_rect := Rect2i(6, 6, 8, 8)
var castle_grade := "F"
var theme_id := "cave_f"
var tile_size: Vector2 = Vector2(IsoMathScript.DEFAULT_TILE_WIDTH, IsoMathScript.DEFAULT_TILE_HEIGHT)
var tile_visual_scale := 1.0
var tile_world_origin := Vector2.ZERO

var cell_data: Dictionary = {}
var tile_floor_cells: Dictionary = {}
var tile_walk_cells: Dictionary = {}
var tile_blocked_cells: Dictionary = {}
var tile_room_by_cell: Dictionary = {}
var tile_room_floor_cells: Dictionary = {}
var tile_room_walk_cells: Dictionary = {}
var tile_sockets: Array = []
var open_edge_set: Dictionary = {}
var object_slots: Array = []

func setup_quarter(module_data: Dictionary, layout_data: Dictionary, legacy_rooms: Dictionary) -> void:
	modules = module_data.duplicate(true)
	layout = layout_data.duplicate(true)
	rooms = legacy_rooms.duplicate(true)
	placed_modules_by_id.clear()
	adjacency.clear()
	cell_data.clear()
	tile_floor_cells.clear()
	tile_walk_cells.clear()
	tile_blocked_cells.clear()
	tile_room_by_cell.clear()
	tile_room_floor_cells.clear()
	tile_room_walk_cells.clear()
	tile_sockets.clear()
	open_edge_set.clear()
	object_slots.clear()

	_load_grade_rules()
	_load_tile_size()
	_initialize_master_grid()
	_load_placed_modules()
	_apply_blueprints_to_grid()
	_build_adjacency()
	_build_open_edges()
	_rebuild_tile_projection()
	_rebuild_walk_map()
	_validate_v2_layout()

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

func debug_cell_data() -> Dictionary:
	return cell_data.duplicate(true)

func debug_active_cells() -> Dictionary:
	var result: Dictionary = {}
	for cell in cell_data.keys():
		if bool(cell_data[cell].get("active", false)):
			result[cell] = true
	return result

func debug_floor_cells() -> Dictionary:
	return tile_floor_cells.duplicate(true)

func debug_walk_cells() -> Dictionary:
	return tile_walk_cells.duplicate(true)

func debug_tile_blocked_cells() -> Dictionary:
	return tile_blocked_cells.duplicate(true)

func debug_floor_mask(cell: Vector2i) -> int:
	if not tile_floor_cells.has(cell):
		return -1
	return AutoTileMaskScript.get_4bit_mask(cell, tile_floor_cells, open_edge_set)

func debug_floor_mask_values() -> Array:
	var values: Array = []
	for cell in tile_floor_cells.keys():
		var mask = debug_floor_mask(cell)
		if mask >= 0 and not values.has(mask):
			values.append(mask)
	values.sort()
	return values

func debug_room_id_for_tile_cell(cell: Vector2i) -> String:
	return str(tile_room_by_cell.get(cell, ""))

func debug_socket_cells() -> Array:
	return tile_sockets.duplicate(true)

func debug_open_edge_set() -> Dictionary:
	return open_edge_set.duplicate(true)

func debug_object_slots() -> Array:
	return object_slots.duplicate(true)

func debug_tile_grid_size() -> Vector2i:
	return max_grid_size

func debug_active_rect() -> Rect2i:
	return active_rect

func debug_castle_grade() -> String:
	return castle_grade

func debug_theme_id() -> String:
	return theme_id

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
	return IsoMathScript.array_to_world(room.get("center", [0, 0]))

func rect(room_id: String) -> Rect2:
	var cells: Array = tile_room_floor_cells.get(room_id, [])
	if not cells.is_empty():
		var bounds: Rect2 = tile_cell_rect(cells[0])
		for index in range(1, cells.size()):
			bounds = bounds.merge(tile_cell_rect(cells[index]))
		return bounds
	var room: Dictionary = rooms.get(room_id, {})
	var value: Array = room.get("rect", [0, 0, 0, 0])
	if value.size() < 4:
		return Rect2()
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))

func exits(room_id: String) -> Array:
	if adjacency.has(room_id):
		return adjacency[room_id].duplicate()
	return []

func path_between(start_room: String, goal_room: String) -> Array:
	if start_room == goal_room and rooms.has(start_room):
		return [start_room]
	if not adjacency.has(start_room) or not adjacency.has(goal_room):
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
				return _reconstruct_room_path(came_from, start_room, goal_room)
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
	return [to_world]

func is_walkable(point: Vector2) -> bool:
	if walk_map == null:
		return false
	return walk_map.is_world_position_walkable(point)

func clamp_to_walkable(point: Vector2) -> Vector2:
	if walk_map == null:
		return point
	return walk_map.clamp_to_walkable(point)

func closest_room(point: Vector2) -> String:
	var best_room = ""
	var best_distance = INF
	for room_id in rooms.keys():
		var room_rect = rect(room_id)
		if room_rect.has_point(point):
			return room_id
		var distance = center(room_id).distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best_room = room_id
	return best_room

func room_at_world(point: Vector2) -> String:
	var cell = IsoMathScript.iso_world_to_cell(point, tile_world_origin, tile_size.x * tile_visual_scale, tile_size.y * tile_visual_scale)
	var room_id = str(tile_room_by_cell.get(cell, ""))
	if room_id != "":
		return room_id

	var best_room = ""
	var best_distance = INF
	for candidate_cell in tile_room_by_cell.keys():
		var distance = tile_cell_center(candidate_cell).distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best_room = str(tile_room_by_cell[candidate_cell])
	return best_room

func replace_module(instance_id: String, module_id: String) -> bool:
	var placed = placed_modules_by_id.get(instance_id, null)
	if placed == null or not modules.has(module_id):
		return false
	if not placed.is_replaceable_with(module_id) and not str(placed.module_id) == module_id:
		return false
	placed.module_id = module_id
	_apply_blueprints_to_grid()
	_build_adjacency()
	_build_open_edges()
	_rebuild_tile_projection()
	_rebuild_walk_map()
	_validate_v2_layout()
	return bool(validation.get("ok", false))

func _load_grade_rules() -> void:
	castle_grade = str(layout.get("castle_grade", "F"))
	var rules: Dictionary = DataRegistry.quarter_castle_grade_rules
	var max_value: Array = rules.get("max_grid_size", [20, 20])
	max_grid_size = IsoMathScript.array_to_cell(max_value, Vector2i(20, 20))
	var grades: Dictionary = rules.get("grades", {})
	var grade_rule: Dictionary = grades.get(castle_grade, {})
	if grade_rule.is_empty():
		grade_rule = grades.get("F", {})
	theme_id = str(grade_rule.get("theme", "cave_f"))
	var rect_value: Array = grade_rule.get("active_rect", [6, 6, 8, 8])
	if rect_value.size() >= 4:
		active_rect = Rect2i(int(rect_value[0]), int(rect_value[1]), int(rect_value[2]), int(rect_value[3]))
	else:
		active_rect = Rect2i(0, 0, max_grid_size.x, max_grid_size.y)

func _load_tile_size() -> void:
	var tile_size_value: Array = layout.get("tile_size", [IsoMathScript.DEFAULT_TILE_WIDTH, IsoMathScript.DEFAULT_TILE_HEIGHT])
	tile_size = Vector2(max(1.0, float(tile_size_value[0])), max(1.0, float(tile_size_value[1]))) if tile_size_value.size() >= 2 else Vector2(IsoMathScript.DEFAULT_TILE_WIDTH, IsoMathScript.DEFAULT_TILE_HEIGHT)

func _initialize_master_grid() -> void:
	cell_data.clear()
	for x in range(max_grid_size.x):
		for y in range(max_grid_size.y):
			var cell := Vector2i(x, y)
			var active = active_rect.has_point(cell)
			cell_data[cell] = {
				"gx": x,
				"gy": y,
				"active": active,
				"cell_type": "rock" if active else "void",
				"theme": theme_id,
				"walkable": false,
				"room_id": "",
				"is_corridor": false,
				"has_socket": false,
				"socket_state": "none",
				"object_id": null,
				"trap_id": null
			}

func _load_placed_modules() -> void:
	placed_modules_by_id.clear()
	for entry in layout.get("placed_modules", []):
		var placed = PlacedModuleScript.from_dict(entry)
		if placed.instance_id == "":
			continue
		placed_modules_by_id[placed.instance_id] = placed
		adjacency[placed.instance_id] = []

func _apply_blueprints_to_grid() -> void:
	_initialize_master_grid()
	tile_floor_cells.clear()
	tile_walk_cells.clear()
	tile_blocked_cells.clear()
	tile_room_by_cell.clear()
	tile_room_floor_cells.clear()
	tile_room_walk_cells.clear()
	tile_sockets.clear()
	object_slots.clear()
	var occupied_object_cells: Dictionary = {}

	for instance_id in placed_modules_by_id.keys():
		var placed = placed_modules_by_id[instance_id]
		var module: Dictionary = modules.get(placed.module_id, {})
		if module.is_empty():
			continue
		var resolved_object_slots = _object_slots_for_instance(str(instance_id), module)
		var blocked_set := _local_cell_set(_blocked_cell_values(module))
		var prop_block_set := _slot_block_cell_set(resolved_object_slots)
		for value in module.get("floor_cells", []):
			if not value is Array:
				continue
			var local_cell = _array_to_cell(value)
			var cell = placed.local_to_global_cell(local_cell)
			if not cell_data.has(cell):
				continue
			var data: Dictionary = cell_data[cell]
			data["active"] = true
			data["cell_type"] = "floor"
			data["theme"] = str(module.get("theme", theme_id))
			data["room_id"] = str(instance_id)
			data["is_corridor"] = ["corridor", "junction"].has(str(module.get("module_type", "")))
			var local_key = _cell_key(local_cell)
			var walkable = _array_has_cell(module.get("walk_cells", []), local_cell)
			data["walkable"] = walkable and not blocked_set.has(local_key) and not prop_block_set.has(local_key)
			cell_data[cell] = data
			tile_floor_cells[cell] = true
			tile_room_by_cell[cell] = str(instance_id)
			_add_room_cell(tile_room_floor_cells, str(instance_id), cell)
			if bool(data["walkable"]):
				tile_walk_cells[cell] = true
				_add_room_cell(tile_room_walk_cells, str(instance_id), cell)
			else:
				tile_blocked_cells[cell] = true

		for slot in resolved_object_slots:
			var slot_cell = _array_to_cell(slot.get("cell", [0, 0]))
			var global_cell = placed.local_to_global_cell(slot_cell)
			if occupied_object_cells.has(global_cell):
				continue
			occupied_object_cells[global_cell] = str(instance_id)
			if cell_data.has(global_cell):
				var slot_data: Dictionary = cell_data[global_cell]
				slot_data["object_id"] = str(slot.get("id", ""))
				cell_data[global_cell] = slot_data
			object_slots.append({
				"instance_id": str(instance_id),
				"id": str(slot.get("id", "")),
				"cell": global_cell,
				"local_cell": slot_cell,
				"layer": str(slot.get("layer", "front")),
				"facing": str(slot.get("facing", "")),
				"footprint": slot.get("footprint", [[0, 0]])
			})

		for value in module.get("trap_cells", []):
			if not value is Array:
				continue
			var trap_cell = placed.local_to_global_cell(_array_to_cell(value))
			if cell_data.has(trap_cell):
				var trap_data: Dictionary = cell_data[trap_cell]
				trap_data["trap_id"] = "spike_floor"
				cell_data[trap_cell] = trap_data

		_register_sockets(str(instance_id), placed, module)

func _register_sockets(instance_id: String, placed, module: Dictionary) -> void:
	var default_states: Dictionary = module.get("default_socket_states", {})
	var layout_states: Dictionary = layout.get("socket_states", {})
	for socket in module.get("sockets", []):
		var socket_id = str(socket.get("id", ""))
		var cell = placed.local_to_global_cell(_socket_local_cell(socket))
		var state = str(default_states.get(socket_id, "closed"))
		state = str(layout_states.get("%s:%s" % [instance_id, socket_id], state))
		var record = {
			"instance_id": instance_id,
			"socket_id": socket_id,
			"side": str(socket.get("side", "")),
			"cell": cell,
			"global_cell": cell,
			"state": state
		}
		tile_sockets.append(record)
		if cell_data.has(cell):
			var data: Dictionary = cell_data[cell]
			data["has_socket"] = true
			data["socket_state"] = state
			cell_data[cell] = data

func _build_adjacency() -> void:
	adjacency.clear()
	for instance_id in placed_modules_by_id.keys():
		adjacency[instance_id] = []
	for connection in layout.get("connections", []):
		var from_ref = _split_ref(str(connection.get("from", "")))
		var to_ref = _split_ref(str(connection.get("to", "")))
		if from_ref.is_empty() or to_ref.is_empty():
			continue
		_mark_socket_connected(from_ref["instance_id"], from_ref["socket_id"])
		_mark_socket_connected(to_ref["instance_id"], to_ref["socket_id"])
		if not adjacency.has(from_ref["instance_id"]):
			adjacency[from_ref["instance_id"]] = []
		if not adjacency.has(to_ref["instance_id"]):
			adjacency[to_ref["instance_id"]] = []
		if not adjacency[from_ref["instance_id"]].has(to_ref["instance_id"]):
			adjacency[from_ref["instance_id"]].append(to_ref["instance_id"])
		if not adjacency[to_ref["instance_id"]].has(from_ref["instance_id"]):
			adjacency[to_ref["instance_id"]].append(from_ref["instance_id"])

func _mark_socket_connected(instance_id: String, socket_id: String) -> void:
	for index in range(tile_sockets.size()):
		var socket: Dictionary = tile_sockets[index]
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			socket["state"] = "connected"
			tile_sockets[index] = socket
			var cell: Vector2i = socket.get("cell", Vector2i.ZERO)
			if cell_data.has(cell):
				var data: Dictionary = cell_data[cell]
				data["socket_state"] = "connected"
				cell_data[cell] = data

func _build_open_edges() -> void:
	open_edge_set.clear()
	for instance_id in tile_room_floor_cells.keys():
		var room_cells: Array = tile_room_floor_cells[instance_id]
		var room_set: Dictionary = {}
		for cell in room_cells:
			room_set[cell] = true
		for cell in room_cells:
			for side in ["N", "E", "S", "W"]:
				if room_set.has(cell + AutoTileMaskScript.DIRS[side]):
					_add_open_edge(cell, side)
	for socket in tile_sockets:
		if str(socket.get("state", "")) != "connected":
			continue
		var cell: Vector2i = socket.get("cell", Vector2i.ZERO)
		var side = str(socket.get("side", ""))
		_add_open_edge(cell, side)

func _add_open_edge(cell: Vector2i, side: String) -> void:
	if not AutoTileMaskScript.DIRS.has(side):
		return
	var neighbor = cell + AutoTileMaskScript.DIRS[side]
	open_edge_set[AutoTileMaskScript.edge_key(cell, side)] = true
	var opposite = AutoTileMaskScript.opposite_side(side)
	if opposite != "":
		open_edge_set[AutoTileMaskScript.edge_key(neighbor, opposite)] = true

func _rebuild_tile_projection() -> void:
	var raw_bounds := _raw_active_bounds()
	if raw_bounds.size.x <= 0.0 or raw_bounds.size.y <= 0.0:
		tile_visual_scale = 1.0
		tile_world_origin = QUARTER_VIEW_FRAME.get_center()
		return
	tile_visual_scale = min(QUARTER_VIEW_FRAME.size.x / raw_bounds.size.x, QUARTER_VIEW_FRAME.size.y / raw_bounds.size.y)
	tile_visual_scale = clamp(tile_visual_scale, 1.0, 1.9)
	tile_world_origin = QUARTER_VIEW_FRAME.get_center() - raw_bounds.get_center() * tile_visual_scale

func _raw_active_bounds() -> Rect2:
	var initialized := false
	var bounds := Rect2()
	for x in range(active_rect.position.x, active_rect.end.x):
		for y in range(active_rect.position.y, active_rect.end.y):
			var cell := Vector2i(x, y)
			var center_point = IsoMathScript.cell_to_iso_world(cell, Vector2.ZERO, tile_size.x, tile_size.y)
			var rect = Rect2(center_point - tile_size * 0.5, tile_size)
			if not initialized:
				bounds = rect
				initialized = true
			else:
				bounds = bounds.merge(rect)
	return bounds

func _rebuild_walk_map() -> void:
	walk_map = DungeonWalkMapScript.new()
	walk_map.rebuild_from_cell_data(cell_data, open_edge_set, tile_size, tile_world_origin, tile_visual_scale)

func _validate_v2_layout() -> void:
	var errors: Array = []
	var validator = SocketValidatorScript.new()
	var socket_result = validator.validate_layout(modules, layout)
	errors.append_array(socket_result.get("errors", []))
	_validate_module_overlaps(errors)
	_validate_module_cell_bounds(errors)
	_validate_cell_bounds(errors)
	_validate_connection_adjacency(errors)
	_validate_required_paths(errors)
	validation = {
		"ok": errors.is_empty(),
		"errors": errors,
		"placed_count": placed_modules_by_id.size(),
		"connection_count": layout.get("connections", []).size(),
		"max_grid_size": [max_grid_size.x, max_grid_size.y],
		"active_rect": [active_rect.position.x, active_rect.position.y, active_rect.size.x, active_rect.size.y]
	}

func _validate_cell_bounds(errors: Array) -> void:
	for cell in tile_floor_cells.keys():
		if cell.x < 0 or cell.y < 0 or cell.x >= max_grid_size.x or cell.y >= max_grid_size.y:
			errors.append("floor cell outside max grid: %s" % str(cell))
			continue
		if not active_rect.has_point(cell):
			errors.append("floor cell outside active rect: %s" % str(cell))

func _validate_module_overlaps(errors: Array) -> void:
	var occupied: Dictionary = {}
	for instance_id in placed_modules_by_id.keys():
		var placed = placed_modules_by_id[instance_id]
		var module: Dictionary = modules.get(placed.module_id, {})
		for value in module.get("floor_cells", []):
			if not value is Array:
				continue
			var cell = placed.local_to_global_cell(_array_to_cell(value))
			if occupied.has(cell):
				errors.append("floor cell overlap: %s and %s at %s" % [occupied[cell], instance_id, str(cell)])
			else:
				occupied[cell] = str(instance_id)

func _validate_module_cell_bounds(errors: Array) -> void:
	for instance_id in placed_modules_by_id.keys():
		var placed = placed_modules_by_id[instance_id]
		var module: Dictionary = modules.get(placed.module_id, {})
		for value in module.get("floor_cells", []):
			if not value is Array:
				continue
			var cell = placed.local_to_global_cell(_array_to_cell(value))
			if cell.x < 0 or cell.y < 0 or cell.x >= max_grid_size.x or cell.y >= max_grid_size.y:
				errors.append("placed floor outside max grid: %s at %s" % [instance_id, str(cell)])
				continue
			if not active_rect.has_point(cell):
				errors.append("placed floor outside active rect: %s at %s" % [instance_id, str(cell)])

func _validate_connection_adjacency(errors: Array) -> void:
	for pair in connection_pairs():
		var from_socket = _socket_record(str(pair["from_instance"]), str(pair["from_socket"]))
		var to_socket = _socket_record(str(pair["to_instance"]), str(pair["to_socket"]))
		if from_socket.is_empty() or to_socket.is_empty():
			continue
		var from_cell: Vector2i = from_socket["cell"]
		var to_cell: Vector2i = to_socket["cell"]
		var side = AutoTileMaskScript.side_between(from_cell, to_cell)
		if side == "":
			errors.append("connected sockets are not adjacent: %s:%s -> %s:%s" % [pair["from_instance"], pair["from_socket"], pair["to_instance"], pair["to_socket"]])
			continue
		if side != str(from_socket.get("side", "")):
			errors.append("socket side does not face target: %s:%s" % [pair["from_instance"], pair["from_socket"]])

func _validate_required_paths(errors: Array) -> void:
	for requirement in layout.get("required_paths", []):
		var from_id = str(requirement.get("from", ""))
		var to_id = str(requirement.get("to", ""))
		if path_between(from_id, to_id).is_empty():
			errors.append("required path missing %s -> %s" % [from_id, to_id])
			continue
		var points = path_to_point(center(from_id), center(to_id))
		if points.is_empty():
			errors.append("required walk path missing %s -> %s" % [from_id, to_id])

func _socket_record(instance_id: String, socket_id: String) -> Dictionary:
	for socket in tile_sockets:
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			return socket
	return {}

func _local_cell_set(values: Array) -> Dictionary:
	var result: Dictionary = {}
	for value in values:
		if value is Array:
			result[_cell_key(_array_to_cell(value))] = true
	return result

func _slot_block_cell_set(slots: Array) -> Dictionary:
	var result: Dictionary = {}
	for slot in slots:
		var base_cell = _array_to_cell(slot.get("cell", [0, 0]))
		for value in slot.get("block_cells", []):
			if value is Array:
				result[_cell_key(base_cell + _array_to_cell(value))] = true
	return result

func _object_slots_for_instance(instance_id: String, module: Dictionary) -> Array:
	var function_id = str(module.get("room_function", ""))
	if ["entry", "core", "trap", "corridor"].has(function_id) or str(module.get("module_type", "")) in ["corridor", "junction"]:
		return _slots_with_facing(instance_id, module.get("object_slots", []).duplicate(true), function_id)
	var facility = str(rooms.get(instance_id, {}).get("facility_role", function_id))
	var cell = _facility_object_cell(module)
	match facility:
		"barracks":
			return _slots_with_facing(instance_id, [{"id": "weapon_rack", "cell": [0, 0], "layer": "back", "footprint": [[0, 0]], "block_cells": []}], facility)
		"treasure":
			return _slots_with_facing(instance_id, [{"id": "treasure_pile_large", "cell": [cell.x, cell.y], "layer": "front", "footprint": [[0, 0]], "block_cells": []}], facility)
		"recovery":
			return _slots_with_facing(instance_id, [{"id": "recovery_nest_f", "cell": [cell.x, cell.y], "layer": "front", "footprint": [[0, 0]], "block_cells": []}], facility)
		"watch_post":
			return _slots_with_facing(instance_id, [{"id": "watch_post", "cell": [cell.x, cell.y], "layer": "front", "footprint": [[0, 0]], "block_cells": []}], facility)
		"build_slot":
			return _slots_with_facing(instance_id, [{"id": "foundation_marks", "cell": [cell.x, cell.y], "layer": "back", "footprint": [[0, 0]], "block_cells": []}], facility)
	return _slots_with_facing(instance_id, module.get("object_slots", []).duplicate(true), function_id)

func _slots_with_facing(instance_id: String, slots: Array, role_hint: String) -> Array:
	var facing = _object_facing_for_instance(instance_id, role_hint)
	for slot in slots:
		if not slot is Dictionary:
			continue
		if not slot.has("facing") or str(slot.get("facing", "")) == "":
			slot["facing"] = facing
	return slots

func _object_facing_for_instance(instance_id: String, role_hint: String) -> String:
	var room_grid: Dictionary = layout.get("room_grid", {})
	for cell in room_grid.get("cells", []):
		if not cell is Dictionary:
			continue
		if str(cell.get("instance_id", "")) == instance_id and str(cell.get("object_facing", "")) != "":
			return str(cell.get("object_facing", ""))
	match role_hint:
		"entry":
			return "SE"
		"core", "barracks", "treasure", "recovery", "watch_post", "build_slot", "corridor":
			return "SW"
	return "SW"

func _facility_object_cell(module: Dictionary) -> Vector2i:
	var footprint = _module_footprint(module)
	return Vector2i(maxi(0, footprint.x - 1), 0 if footprint.y <= 1 else 1)

func _module_footprint(module: Dictionary) -> Vector2i:
	var value: Array = module.get("size", module.get("footprint", [1, 1]))
	if value.size() < 2:
		return Vector2i.ONE
	return Vector2i(maxi(1, int(value[0])), maxi(1, int(value[1])))

func _blocked_cell_values(module: Dictionary) -> Array:
	if module.has("blocked_cells"):
		return module.get("blocked_cells", [])
	return module.get("block_cells", [])

func _array_has_cell(values: Array, cell: Vector2i) -> bool:
	for value in values:
		if value is Array and _array_to_cell(value) == cell:
			return true
	return false

func _add_room_cell(target: Dictionary, room_id: String, cell: Vector2i) -> void:
	if not target.has(room_id):
		target[room_id] = []
	target[room_id].append(cell)

func _socket_local_cell(socket: Dictionary) -> Vector2i:
	return _array_to_cell(socket.get("cell", socket.get("local_cell", [0, 0])))

func _array_to_cell(value: Array) -> Vector2i:
	return IsoMathScript.array_to_cell(value)

func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _split_ref(reference: String) -> Dictionary:
	var parts = reference.split(":")
	if parts.size() != 2 or str(parts[0]) == "" or str(parts[1]) == "":
		return {}
	return {"instance_id": str(parts[0]), "socket_id": str(parts[1])}

func _append_segment(points: Array, segment: Array) -> void:
	for point in segment:
		if not points.is_empty() and points[points.size() - 1].distance_to(point) < 0.1:
			continue
		points.append(point)

func _reconstruct_room_path(came_from: Dictionary, start_room: String, goal_room: String) -> Array:
	var path: Array = [goal_room]
	var current = goal_room
	while current != start_room:
		current = came_from.get(current, "")
		if current == "":
			return []
		path.push_front(current)
	return path
