extends RefCounted
class_name QuarterDungeonRenderer

const Constants = preload("res://scripts/core/Constants.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")
const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")

const REQUIRED_LAYER_NAMES = [
	"BackgroundVoidLayer",
	"FloorLayer",
	"EdgeSkirtLayer",
	"BackWallLayer",
	"ObjectBackLayer",
	"UnitYSortLayer",
	"ObjectFrontLayer",
	"FrontWallLayer",
	"FxLayer",
	"UiDebugLayer"
]

const TRAP_TRIGGER_FRAME_MSEC = 110

var root: Node
var floor_tile_textures: Dictionary = {}
var edge_tile_textures: Dictionary = {}
var corner_overlay_textures: Dictionary = {}
var wall_tile_textures: Dictionary = {}
var wall_mask_textures: Dictionary = {}
var wall_edge_textures: Dictionary = {}
var door_tile_textures: Dictionary = {}
var background_plate_textures: Dictionary = {}
var socket_cap_textures: Dictionary = {}
var object_sprite_textures: Dictionary = {}
var trap_animation_frame_counts: Dictionary = {}
var active_trap_animations: Dictionary = {}
var missing_floor_tile_masks: Array = []
var missing_addon_tiles: Array = []
var missing_wall_mask_tile_masks: Array = []
var missing_wall_edge_keys: Array = []
var missing_background_plates: Array = []
var missing_socket_caps: Array = []
var missing_object_sprites: Array = []
var last_floor_masks: Dictionary = {}
var last_open_edge_set: Dictionary = {}
var last_wall_edge_records: Array = []
var last_connection_bridge_records: Array = []
var last_room_wall_records: Array = []
var last_floor_count := 0

func setup(game_root: Node) -> void:
	root = game_root
	_load_floor_tile_textures()
	_load_addon_tile_textures()
	_load_background_plate_textures()
	_load_socket_cap_textures()
	_load_object_sprite_textures()
	_ensure_scene_layers()

func refresh_layout() -> void:
	_ensure_scene_layers()
	if root != null:
		root.queue_redraw()

func draw() -> void:
	if root == null or root.graph == null or not root.use_quarter_module_map:
		return
	_ensure_scene_layers()
	var tile_grid = _build_tile_grid()
	_draw_active_rock_layer(tile_grid)
	_draw_floor_layer(tile_grid)
	_draw_room_footprint_layer(tile_grid)
	_draw_corridor_path_layer(tile_grid)
	_draw_edge_skirt_layer(tile_grid)
	_draw_back_wall_layer(tile_grid)
	_draw_room_wall_layer(tile_grid, "wall_back")
	_draw_socket_cap_layer(tile_grid, "back")
	_draw_connection_bridge_layer(tile_grid)
	_draw_outside_approach_layer(tile_grid)
	_draw_socket_layer(tile_grid)
	_draw_object_layer(tile_grid, "back")
	_draw_front_wall_layer(tile_grid)
	_draw_socket_cap_layer(tile_grid, "front")
	_draw_object_layer(tile_grid, "front")
	_draw_room_wall_layer(tile_grid, "wall_front")
	_draw_connected_path_mouth_layer(tile_grid)
	_draw_outside_mouth_overlay_layer(tile_grid)
	if root.current_screen == Constants.SCREEN_MANAGEMENT:
		_draw_main_route_overlay()
		_draw_selected_module_highlight(tile_grid)
	if root.map_editor_active:
		_draw_map_editor_overlay()
	if root.debug_show_active_overlay:
		_draw_active_overlay(tile_grid)
	if root.debug_show_walkable_overlay:
		_draw_walkable_overlay(tile_grid)
	if root.debug_show_floor_mask_overlay:
		_draw_floor_mask_overlay(tile_grid)
	if root.debug_show_socket_overlay:
		_draw_socket_overlay(tile_grid)
	if root.debug_show_room_id_overlay:
		_draw_room_id_overlay(tile_grid)
	if root.debug_show_cursor_cell:
		_draw_unit_or_cursor_cell(tile_grid)
	if root.debug_show_path_overlay:
		_draw_path_overlay()

func has_module_visuals() -> bool:
	return false

func uses_tile_grid_renderer() -> bool:
	return true

func uses_tile_map_layers() -> bool:
	return false

func debug_loaded_visual_count() -> int:
	return 0

func has_floor_tile_textures() -> bool:
	return floor_tile_textures.size() >= 16

func debug_loaded_floor_tile_count() -> int:
	return floor_tile_textures.size()

func debug_missing_floor_tile_masks() -> Array:
	return missing_floor_tile_masks.duplicate()

func has_addon_tile_textures() -> bool:
	return edge_tile_textures.size() >= 4 and corner_overlay_textures.size() >= 8

func debug_loaded_addon_tile_count() -> int:
	return edge_tile_textures.size() + corner_overlay_textures.size() + wall_tile_textures.size() + wall_edge_textures.size() + door_tile_textures.size()

func debug_missing_addon_tiles() -> Array:
	return missing_addon_tiles.duplicate()

func has_corner_overlay_textures() -> bool:
	return corner_overlay_textures.size() >= 8

func debug_loaded_corner_overlay_count() -> int:
	return corner_overlay_textures.size()

func has_wall_mask_tile_textures() -> bool:
	return wall_mask_textures.size() >= 16

func debug_loaded_wall_mask_tile_count() -> int:
	return wall_mask_textures.size()

func debug_missing_wall_mask_tile_masks() -> Array:
	return missing_wall_mask_tile_masks.duplicate()

func has_wall_edge_textures() -> bool:
	return wall_edge_textures.size() >= 32

func debug_loaded_wall_edge_texture_count() -> int:
	return wall_edge_textures.size()

func debug_missing_wall_edge_keys() -> Array:
	return missing_wall_edge_keys.duplicate()

func has_background_plate_textures() -> bool:
	return not background_plate_textures.is_empty()

func debug_missing_background_plates() -> Array:
	return missing_background_plates.duplicate()

func has_socket_cap_textures() -> bool:
	return socket_cap_textures.size() >= 12

func debug_missing_socket_caps() -> Array:
	return missing_socket_caps.duplicate()

func debug_socket_cap_key(instance_id: String, socket_id: String) -> String:
	for socket in root.graph.debug_socket_cells():
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			var state = str(socket.get("state", "closed"))
			var side = str(socket.get("side", ""))
			var key = _socket_cap_key(state, side)
			return key if socket_cap_textures.has(key) else ""
	return ""

func debug_socket_state(instance_id: String, socket_id: String) -> String:
	for socket in root.graph.debug_socket_cells():
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			return str(socket.get("state", ""))
	return ""

func has_object_sprite_textures() -> bool:
	return object_sprite_textures.size() > 0

func debug_loaded_object_sprite_count() -> int:
	return object_sprite_textures.size()

func debug_missing_object_sprites() -> Array:
	return missing_object_sprites.duplicate()

func debug_object_texture_key(instance_id: String, layer_name: String) -> String:
	if root == null or root.graph == null:
		return ""
	var tile_grid = _build_tile_grid()
	for slot in tile_grid.get("objects", []):
		if str(slot.get("instance_id", "")) != instance_id:
			continue
		var slot_id = str(slot.get("id", ""))
		var key = _object_texture_key_for_layer(slot, slot_id, layer_name)
		if key != "":
			return key
	return ""

func debug_object_facing(instance_id: String) -> String:
	if root == null or root.graph == null:
		return ""
	var tile_grid = _build_tile_grid()
	for slot in tile_grid.get("objects", []):
		if str(slot.get("instance_id", "")) == instance_id:
			return str(slot.get("facing", ""))
	return ""

func debug_object_connection_variant(instance_id: String) -> String:
	if root == null or root.graph == null:
		return ""
	var tile_grid = _build_tile_grid()
	for slot in tile_grid.get("objects", []):
		if str(slot.get("instance_id", "")) == instance_id:
			return str(slot.get("connection_variant", ""))
	return ""

func debug_active_castle_art_stage() -> String:
	return _active_castle_art_stage()

func trigger_trap_animation(instance_id: String, trap_id: String) -> void:
	if _trap_animation_frame_count(trap_id, "trigger") <= 0:
		return
	active_trap_animations[_trap_animation_key(instance_id, trap_id)] = Time.get_ticks_msec()
	if root != null:
		root.queue_redraw()

func clear_trap_animations() -> void:
	active_trap_animations.clear()

func debug_active_trap_animation_count() -> int:
	_prune_finished_trap_animations()
	return active_trap_animations.size()

func debug_current_trap_texture_key(instance_id: String, trap_id: String) -> String:
	return _active_trap_texture_key(instance_id, trap_id)

func debug_visual_variant_key(instance_id: String) -> String:
	var sides: Array = []
	for socket in root.graph.debug_socket_cells():
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("state", "")) == "connected":
			sides.append(str(socket.get("side", "")).to_lower())
	sides.sort()
	return "closed" if sides.is_empty() else "_".join(sides)

func debug_floor_cell_count() -> int:
	if last_floor_count == 0:
		_build_tile_grid()
	return last_floor_count

func debug_connection_bridge_count() -> int:
	_build_tile_grid()
	return last_connection_bridge_records.size()

func debug_connection_bridge_group_count() -> int:
	_build_tile_grid()
	var groups: Dictionary = {}
	for record in last_connection_bridge_records:
		groups[str(record.get("group_key", ""))] = true
	return groups.size()

func debug_outside_approach_cell_count() -> int:
	if root == null or root.graph == null:
		return 0
	var tile_grid = _build_tile_grid()
	var count := 0
	for record in tile_grid.get("cells", []):
		var data: Dictionary = record.get("data", {})
		if str(data.get("room_id", "")) == "outside_approach":
			count += 1
	return count

func debug_full_grid_room_projection_count() -> int:
	if root == null or root.graph == null:
		return 0
	var tile_grid = _build_tile_grid()
	var count := 0
	for slot in tile_grid.get("objects", []):
		if _is_full_grid_room_slot(slot):
			count += 1
	return count

func debug_room_wall_segment_count(state_filter: String = "") -> int:
	_build_tile_grid()
	var count := 0
	for record in last_room_wall_records:
		if state_filter == "" or str(record.get("state", "")) == state_filter:
			count += 1
	return count

func debug_object_uses_projection_safe_connection_sprite(instance_id: String, layer_name: String) -> bool:
	if root == null or root.graph == null:
		return false
	var texture_key = debug_object_texture_key(instance_id, layer_name)
	return _object_texture_uses_projection_safe_room_sprite(texture_key)

func debug_floor_mask_values() -> Array:
	if last_floor_masks.is_empty():
		_build_tile_grid()
	var values: Array = []
	for mask in last_floor_masks.values():
		if not values.has(mask):
			values.append(mask)
	values.sort()
	return values

func debug_wall_mask_values() -> Array:
	if last_wall_edge_records.is_empty():
		_build_tile_grid()
	var values: Array = []
	for record in last_wall_edge_records:
		var key = str(record.get("texture_key", ""))
		if key != "" and not values.has(key):
			values.append(key)
	values.sort()
	return values

func debug_wall_cell_count() -> int:
	if last_wall_edge_records.is_empty():
		_build_tile_grid()
	return last_wall_edge_records.size()

func debug_wall_edge_records() -> Array:
	if last_wall_edge_records.is_empty():
		_build_tile_grid()
	return last_wall_edge_records.duplicate(true)

func debug_wall_edge_key_for_cell(cell: Vector2i, side: String) -> String:
	if last_wall_edge_records.is_empty():
		_build_tile_grid()
	for record in last_wall_edge_records:
		if record.get("cell", Vector2i.ZERO) == cell and str(record.get("side", "")) == side:
			return str(record.get("texture_key", ""))
	return ""

func debug_visual_mask_for_socket(instance_id: String, socket_id: String) -> int:
	for socket in root.graph.debug_socket_cells():
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			return root.graph.debug_floor_mask(socket.get("cell", Vector2i.ZERO))
	return -1

func debug_visual_mask_for_global_cell(cell: Vector2i) -> int:
	return root.graph.debug_floor_mask(cell)

func debug_edge_open(cell: Vector2i, side: String) -> bool:
	if last_open_edge_set.is_empty():
		_build_tile_grid()
	return last_open_edge_set.has(AutoTileMaskScript.edge_key(cell, side))

func debug_layer_names() -> Array:
	return REQUIRED_LAYER_NAMES.duplicate()

func debug_tilemap_layer_names() -> Array:
	var names: Array = []
	for layer_name in REQUIRED_LAYER_NAMES:
		if root.get_node_or_null(layer_name) != null:
			names.append(layer_name)
	return names

func _ensure_scene_layers() -> void:
	_ensure_background_layer()
	for layer_name in REQUIRED_LAYER_NAMES:
		if layer_name == "BackgroundVoidLayer":
			continue
		if layer_name == "UnitYSortLayer" and root.unit_root != null:
			root.unit_root.name = "UnitYSortLayer"
			root.unit_root.y_sort_enabled = true
			continue
		if layer_name == "FxLayer" and root.effect_root != null:
			root.effect_root.name = "FxLayer"
			continue
		if root.get_node_or_null(layer_name) == null:
			var node := Node2D.new()
			node.name = layer_name
			node.z_index = _layer_z(layer_name)
			if layer_name == "UnitYSortLayer":
				node.y_sort_enabled = true
			root.add_child(node)

func _ensure_background_layer() -> void:
	var layer = root.get_node_or_null("BackgroundVoidLayer")
	if layer == null:
		layer = Control.new()
		layer.name = "BackgroundVoidLayer"
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.z_index = -300
		root.add_child(layer)

	var full = layer.get_node_or_null("FullBackdrop") as ColorRect
	if full == null:
		full = ColorRect.new()
		full.name = "FullBackdrop"
		full.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(full)
	full.position = Vector2.ZERO
	full.size = Vector2(1920, 1080)
	full.color = Color("#050507")

	var panel = layer.get_node_or_null("DungeonBackdrop") as ColorRect
	if panel == null:
		panel = ColorRect.new()
		panel.name = "DungeonBackdrop"
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(panel)
	panel.position = Vector2(330, 78)
	panel.size = Vector2(1198, 804)
	panel.color = Color("#08070c")

	var plate = layer.get_node_or_null("DungeonBackgroundPlate") as TextureRect
	if plate == null:
		plate = TextureRect.new()
		plate.name = "DungeonBackgroundPlate"
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		layer.add_child(plate)
	plate.position = Vector2(330, 78)
	plate.size = Vector2(1198, 804)
	plate.texture = background_plate_textures.get("bg_cave_f_3x3_01", null)
	plate.modulate = Color(1, 1, 1, 0.82)

func _layer_z(layer_name: String) -> int:
	match layer_name:
		"FloorLayer":
			return -100
		"EdgeSkirtLayer":
			return -90
		"BackWallLayer":
			return -70
		"ObjectBackLayer":
			return -40
		"UnitYSortLayer":
			return 0
		"ObjectFrontLayer":
			return 30
		"FrontWallLayer":
			return 50
		"FxLayer":
			return 70
		"UiDebugLayer":
			return 200
	return 0

func _build_tile_grid() -> Dictionary:
	var cells: Array = []
	var active_cells: Dictionary = root.graph.debug_active_cells()
	var cell_data: Dictionary = root.graph.debug_cell_data()
	var floor_set: Dictionary = root.graph.debug_floor_cells()
	var walk_set: Dictionary = root.graph.debug_walk_cells()
	var blocked_set: Dictionary = root.graph.debug_tile_blocked_cells()
	last_floor_masks.clear()
	last_open_edge_set = root.graph.debug_open_edge_set()
	last_floor_count = floor_set.size()
	for cell in active_cells.keys():
		var data: Dictionary = cell_data.get(cell, {})
		var mask = root.graph.debug_floor_mask(cell) if floor_set.has(cell) else -1
		if mask >= 0:
			last_floor_masks[cell] = mask
		cells.append({
			"global_cell": cell,
			"rect": root.graph.tile_cell_rect(cell).grow(-2.0),
			"data": data,
			"mask": mask
		})
	cells.sort_custom(func(a, b) -> bool:
		var ca: Vector2i = a["global_cell"]
		var cb: Vector2i = b["global_cell"]
		if ca.x + ca.y == cb.x + cb.y:
			return ca.x < cb.x
		return ca.x + ca.y < cb.x + cb.y
	)
	var sockets = root.graph.debug_socket_cells()
	last_connection_bridge_records = _build_connection_bridge_records(sockets)
	last_room_wall_records = _build_room_wall_records(root.graph.debug_object_slots(), sockets)
	last_wall_edge_records = _build_wall_edge_records(cells, floor_set, sockets)
	return {
		"cells": cells,
		"floor_set": floor_set,
		"walk_set": walk_set,
		"blocked_set": blocked_set,
		"active_set": active_cells,
		"open_edge_set": last_open_edge_set,
		"sockets": sockets,
		"objects": root.graph.debug_object_slots(),
		"wall_edges": last_wall_edge_records,
		"room_walls": last_room_wall_records,
		"connection_bridges": last_connection_bridge_records
	}

func _build_room_wall_records(objects: Array, sockets: Array) -> Array:
	var records: Array = []
	var connected_socket_edges = _connected_socket_edge_set(sockets)
	for slot in objects:
		if not _is_full_grid_room_slot(slot):
			continue
		var instance_id = str(slot.get("instance_id", ""))
		var cells = _object_footprint_cells(slot)
		var cell_set: Dictionary = {}
		for cell in cells:
			cell_set[cell] = true
		for cell in cells:
			var rect = root.graph.tile_cell_rect(cell)
			for side in ["N", "E", "S", "W"]:
				if cell_set.has(cell + AutoTileMaskScript.DIRS[side]):
					continue
				var edge_key = AutoTileMaskScript.edge_key(cell, side)
				var state = "door" if connected_socket_edges.has("%s|%s" % [instance_id, edge_key]) else "wall"
				records.append({
					"instance_id": instance_id,
					"slot_id": str(slot.get("id", "")),
					"cell": cell,
					"side": side,
					"state": state,
					"layer": _wall_render_layer(side),
					"rect": rect
				})
	records.sort_custom(func(a, b) -> bool:
		var ca: Vector2i = a["cell"]
		var cb: Vector2i = b["cell"]
		if ca.x + ca.y == cb.x + cb.y:
			if ca.x == cb.x:
				return _side_sort_index(str(a["side"])) < _side_sort_index(str(b["side"]))
			return ca.x < cb.x
		return ca.x + ca.y < cb.x + cb.y
	)
	return records

func _connected_socket_edge_set(sockets: Array) -> Dictionary:
	var result: Dictionary = {}
	for socket in sockets:
		if str(socket.get("state", "")) != "connected":
			continue
		var instance_id = str(socket.get("instance_id", ""))
		var cell: Vector2i = socket.get("cell", Vector2i.ZERO)
		var side = str(socket.get("side", ""))
		result["%s|%s" % [instance_id, AutoTileMaskScript.edge_key(cell, side)]] = true
	return result

func _build_connection_bridge_records(sockets: Array) -> Array:
	var records: Array = []
	for pair in root.graph.connection_pairs():
		var from_socket = _socket_record_for_ref(sockets, str(pair.get("from_instance", "")), str(pair.get("from_socket", "")))
		var to_socket = _socket_record_for_ref(sockets, str(pair.get("to_instance", "")), str(pair.get("to_socket", "")))
		if from_socket.is_empty() or to_socket.is_empty():
			continue
		if str(from_socket.get("state", "")) != "connected" or str(to_socket.get("state", "")) != "connected":
			continue
		var from_cell: Vector2i = from_socket.get("cell", Vector2i.ZERO)
		var to_cell: Vector2i = to_socket.get("cell", Vector2i.ZERO)
		var from_rect = root.graph.tile_cell_rect(from_cell).grow(-4.0)
		var to_rect = root.graph.tile_cell_rect(to_cell).grow(-4.0)
		records.append({
			"from_instance": str(pair.get("from_instance", "")),
			"from_socket": str(pair.get("from_socket", "")),
			"from_side": str(from_socket.get("side", "")),
			"from_cell": from_cell,
			"from_rect": from_rect,
			"to_instance": str(pair.get("to_instance", "")),
			"to_socket": str(pair.get("to_socket", "")),
			"to_side": str(to_socket.get("side", "")),
			"to_cell": to_cell,
			"to_rect": to_rect,
			"start": from_rect.get_center(),
			"end": to_rect.get_center(),
			"cell_height": minf(from_rect.size.y, to_rect.size.y),
			"group_key": _connection_bridge_group_key(pair, from_socket, to_socket)
		})
	return records

func _connection_bridge_group_key(pair: Dictionary, from_socket: Dictionary, to_socket: Dictionary) -> String:
	var a = "%s:%s" % [str(pair.get("from_instance", "")), str(from_socket.get("side", ""))]
	var b = "%s:%s" % [str(pair.get("to_instance", "")), str(to_socket.get("side", ""))]
	var values = [a, b]
	values.sort()
	return "%s|%s" % [values[0], values[1]]

func _build_wall_edge_records(cells: Array, floor_set: Dictionary, sockets: Array) -> Array:
	var records: Array = []
	var endpoint_counts: Dictionary = {}
	var socket_states := _socket_state_by_edge(sockets)
	for record in cells:
		if int(record.get("mask", -1)) < 0:
			continue
		var cell: Vector2i = record["global_cell"]
		for side in ["N", "E", "S", "W"]:
			if _edge_open(cell, side):
				continue
			var neighbor: Vector2i = cell + AutoTileMaskScript.DIRS[side]
			if floor_set.has(neighbor) and not ["N", "W"].has(side):
				continue
			var raw_rect = root.graph.tile_cell_rect(cell)
			var diamond = _diamond(raw_rect)
			var points := _edge_points(diamond, side)
			if points.is_empty():
				continue
			var state = _wall_edge_state(cell, side, socket_states)
			var edge_record = {
				"cell": cell,
				"side": side,
				"state": state,
				"layer": _wall_render_layer(side),
				"rect": raw_rect,
				"start": points[0],
				"end": points[1],
				"start_key": _wall_endpoint_key(points[0]),
				"end_key": _wall_endpoint_key(points[1]),
				"join_prev": false,
				"join_next": false,
				"variant": "cap",
				"texture_key": ""
			}
			records.append(edge_record)
			if state == "closed":
				endpoint_counts[edge_record["start_key"]] = int(endpoint_counts.get(edge_record["start_key"], 0)) + 1
				endpoint_counts[edge_record["end_key"]] = int(endpoint_counts.get(edge_record["end_key"], 0)) + 1
	for index in range(records.size()):
		var edge_record: Dictionary = records[index]
		if str(edge_record.get("state", "closed")) == "closed":
			var join_prev = int(endpoint_counts.get(edge_record["start_key"], 0)) > 1
			var join_next = int(endpoint_counts.get(edge_record["end_key"], 0)) > 1
			edge_record["join_prev"] = join_prev
			edge_record["join_next"] = join_next
			edge_record["variant"] = _wall_edge_variant(join_prev, join_next)
		else:
			edge_record["variant"] = str(edge_record.get("state", "closed"))
		edge_record["texture_key"] = _wall_edge_texture_key(str(edge_record["side"]), str(edge_record["state"]), str(edge_record["variant"]))
		records[index] = edge_record
	records.sort_custom(func(a, b) -> bool:
		var ca: Vector2i = a["cell"]
		var cb: Vector2i = b["cell"]
		if ca.x + ca.y == cb.x + cb.y:
			if ca.x == cb.x:
				return _side_sort_index(str(a["side"])) < _side_sort_index(str(b["side"]))
			return ca.x < cb.x
		return ca.x + ca.y < cb.x + cb.y
	)
	return records

func _draw_active_rock_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var data: Dictionary = record["data"]
		if str(data.get("cell_type", "")) == "floor":
			continue
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect)
		var fill = Color("#17131d72") if str(data.get("cell_type", "")) == "rock" else Color("#07060936")
		root.draw_polygon(diamond, PackedColorArray([fill.lightened(0.04), fill, fill.darkened(0.08), fill.darkened(0.03)]))
		if str(data.get("cell_type", "")) == "rock":
			root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#33294358"), 1.0)

func _draw_floor_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		if int(record["mask"]) < 0:
			continue
		var rect: Rect2 = record["rect"]
		var mask := int(record["mask"])
		var data: Dictionary = record["data"]
		var is_corridor = bool(data.get("is_corridor", false))
		var alpha := 0.98 if is_corridor else 0.42
		var texture = _floor_tile_texture(mask)
		if texture != null:
			root.draw_texture_rect(texture, rect.grow(3.0), false, Color(1, 1, 1, alpha))
		else:
			_draw_placeholder_floor(rect, mask)

func _draw_room_footprint_layer(tile_grid: Dictionary) -> void:
	for slot in tile_grid.get("objects", []):
		if not _is_full_grid_room_slot(slot):
			continue
		var cells = _object_footprint_cells(slot)
		if cells.is_empty():
			continue
		var cell_set: Dictionary = {}
		for cell in cells:
			cell_set[cell] = true
		cells.sort_custom(func(a, b) -> bool:
			if a.x + a.y == b.x + b.y:
				return a.x < b.x
			return a.x + a.y < b.x + b.y
		)
		var fill = _room_footprint_fill(str(slot.get("id", "")))
		for cell in cells:
			var rect = root.graph.tile_cell_rect(cell).grow(-2.0)
			var diamond = _diamond(rect)
			var cell_fill = _room_boundary_fill(fill) if _is_room_boundary_cell(cell, cell_set) else fill
			root.draw_polygon(diamond, PackedColorArray([
				cell_fill.lightened(0.12),
				cell_fill.lightened(0.03),
				cell_fill.darkened(0.08),
				cell_fill
			]))
			var grid_alpha := 0.46 if _is_room_boundary_cell(cell, cell_set) else 0.32
			root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), fill.lightened(0.28), grid_alpha)
		_draw_room_footprint_perimeter(cells, cell_set, fill)

func _draw_room_footprint_perimeter(cells: Array, cell_set: Dictionary, fill: Color) -> void:
	var dark = Color("#09070bd8")
	var light = fill.lightened(0.28).lerp(Color("#847978a8"), 0.55)
	for cell in cells:
		var rect = root.graph.tile_cell_rect(cell).grow(-1.0)
		var diamond = _diamond(rect)
		for side in ["N", "E", "S", "W"]:
			if cell_set.has(cell + AutoTileMaskScript.DIRS[side]):
				continue
			var points = _edge_points(diamond, side)
			if points.size() < 2:
				continue
			root.draw_line(points[0], points[1], dark, 5.4, true)
			_draw_rough_room_footprint_edge(cell, side, points[0], points[1], light)

func _draw_rough_room_footprint_edge(cell: Vector2i, side: String, start: Vector2, end: Vector2, color: Color) -> void:
	var segment_count := 3
	for index in range(segment_count):
		var edge_noise = _room_edge_noise(cell, side, 23 + index)
		if edge_noise < 0.18:
			continue
		var u0 = float(index) / float(segment_count) + 0.035
		var u1 = float(index + 1) / float(segment_count) - 0.035
		var offset_y = (edge_noise - 0.5) * 1.8
		var a = start.lerp(end, u0) + Vector2(0, offset_y)
		var b = start.lerp(end, u1) + Vector2(0, -offset_y * 0.55)
		var width = 1.0 + edge_noise * 1.2
		root.draw_line(a, b, color.darkened(edge_noise * 0.22), width, true)
		if edge_noise > 0.67:
			var chip = a.lerp(b, 0.5)
			root.draw_circle(chip, 1.1, Color("#100c12be"))

func _is_room_boundary_cell(cell: Vector2i, cell_set: Dictionary) -> bool:
	for side in ["N", "E", "S", "W"]:
		if not cell_set.has(cell + AutoTileMaskScript.DIRS[side]):
			return true
	return false

func _room_boundary_fill(fill: Color) -> Color:
	return fill.darkened(0.22).lerp(Color("#2b2830e8"), 0.48)

func _room_footprint_fill(slot_id: String) -> Color:
	match slot_id:
		"throne_f":
			return Color("#5a283ab8")
		"entrance_gate_f":
			return Color("#3e4050b8")
		"weapon_rack":
			return Color("#4d4639b8")
		"recovery_nest_f":
			return Color("#344a3fb8")
		"treasure_pile_large":
			return Color("#5b4a2cb8")
		"foundation_marks":
			return Color("#40314db0")
	return Color("#423b40b0")

func _draw_room_wall_layer(tile_grid: Dictionary, layer_name: String) -> void:
	for record in tile_grid.get("room_walls", []):
		if str(record.get("layer", "")) != layer_name:
			continue
		if str(record.get("state", "")) != "wall":
			continue
		_draw_room_boundary_wall(record)

func _draw_room_boundary_wall(record: Dictionary) -> void:
	var rect: Rect2 = record.get("rect", Rect2())
	var side = str(record.get("side", ""))
	var points = _edge_points(_diamond(rect.grow(-1.0)), side)
	if points.size() < 2:
		return
	var start: Vector2 = points[0]
	var end: Vector2 = points[1]
	var height = maxf(13.0, rect.size.y * 0.52)
	var top_start = start + Vector2(0, -height - _room_wall_noise(record, 11) * 6.0)
	var top_end = end + Vector2(0, -height - _room_wall_noise(record, 17) * 6.0)
	var face_dark = Color("#120f15cc")
	var face_mid = Color("#28242bdd")
	var face_low = Color("#0a070ce8")
	root.draw_polygon(
		PackedVector2Array([top_start, top_end, end, start]),
		PackedColorArray([face_mid.lightened(0.05), face_mid, face_low, face_dark])
	)
	_draw_room_wall_stone_courses(record, top_start, top_end, start, end)
	_draw_room_wall_top_stones(record, top_start, top_end, start, end)
	_draw_room_wall_spilled_rubble(record, start, end)
	root.draw_line(start, end, Color("#0503079a"), 3.2, true)

func _draw_room_wall_stone_courses(record: Dictionary, top_start: Vector2, top_end: Vector2, start: Vector2, end: Vector2) -> void:
	var course_count := 4
	for course in range(course_count):
		var v0 = float(course) / float(course_count)
		var v1 = float(course + 1) / float(course_count)
		var block_count = 2 + int(_room_wall_noise(record, 31 + course) * 3.99)
		var offset = (_room_wall_noise(record, 44 + course) - 0.5) * 0.22
		for block_index in range(block_count):
			var width_jitter = 0.78 + _room_wall_noise(record, 52 + course * 9 + block_index) * 0.55
			var row_span = 1.0 / float(block_count)
			var u_center = (float(block_index) + 0.5) / float(block_count) + offset
			var u0 = u_center - row_span * width_jitter * 0.46
			var u1 = u_center + row_span * width_jitter * 0.46
			if u1 <= 0.0 or u0 >= 1.0:
				continue
			u0 = clampf(u0, 0.0, 1.0)
			u1 = clampf(u1, 0.0, 1.0)
			var gap_u = minf(0.012, (u1 - u0) * 0.10)
			var gap_v = 0.018 + _room_wall_noise(record, 64 + course * 9 + block_index) * 0.030
			var shade = _room_wall_noise(record, 80 + course * 7 + block_index)
			var color = Color("#403a3ce5").lerp(Color("#1b171ee8"), shade)
			if course == 0:
				color = color.lightened(0.04)
			elif course == course_count - 1:
				color = color.darkened(0.10)
			var lean = (_room_wall_noise(record, 95 + course * 9 + block_index) - 0.5) * 0.028
			var top_lift = (_room_wall_noise(record, 101 + course * 9 + block_index) - 0.5) * 0.035
			var p0 = _room_wall_face_point(top_start, top_end, start, end, u0 + gap_u + lean, v0 + gap_v + top_lift)
			var p1 = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.52) + lean * 0.4, v0 + gap_v - top_lift * 0.8)
			var p2 = _room_wall_face_point(top_start, top_end, start, end, u1 - gap_u + lean, v0 + gap_v + top_lift * 0.55)
			var p3 = _room_wall_face_point(top_start, top_end, start, end, u1 - gap_u - lean * 0.3, v1 - gap_v)
			var p4 = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.44) - lean * 0.2, v1 - gap_v + top_lift * 0.45)
			var p5 = _room_wall_face_point(top_start, top_end, start, end, u0 + gap_u - lean, v1 - gap_v)
			root.draw_polygon(PackedVector2Array([p0, p1, p2, p3, p4, p5]), PackedColorArray([
				color.lightened(0.10),
				color.lightened(0.08),
				color.lightened(0.03),
				color.darkened(0.15),
				color.darkened(0.20),
				color.darkened(0.08)
			]))
			root.draw_line(p0, p1, Color("#887d7460"), 0.7, true)
			root.draw_line(p5, p4, Color("#070509aa"), 0.8, true)
			if shade > 0.64:
				var crack_start = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.35), lerpf(v0, v1, 0.32))
				var crack_mid = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.48), lerpf(v0, v1, 0.55))
				var crack_end = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.40), lerpf(v0, v1, 0.78))
				root.draw_polyline(PackedVector2Array([crack_start, crack_mid, crack_end]), Color("#09070ccc"), 0.9, true)

func _draw_room_wall_top_stones(record: Dictionary, top_start: Vector2, top_end: Vector2, start: Vector2, end: Vector2) -> void:
	var cap_count = 4 + int(_room_wall_noise(record, 121) * 4.99)
	for index in range(cap_count):
		var u_center = (float(index) + 0.5) / float(cap_count) + (_room_wall_noise(record, 133 + index) - 0.5) * 0.11
		var half_width = (0.33 + _room_wall_noise(record, 137 + index) * 0.24) / float(cap_count)
		var u0 = clampf(u_center - half_width, 0.0, 1.0)
		var u1 = clampf(u_center + half_width, 0.0, 1.0)
		if u1 - u0 < 0.04:
			continue
		var lift = 1.5 + _room_wall_noise(record, 140 + index) * 7.2
		var drop = 0.14 + _room_wall_noise(record, 144 + index) * 0.13
		var p0 = _room_wall_face_point(top_start, top_end, start, end, u0, 0.04) + Vector2(0, -lift * 0.70)
		var p1 = _room_wall_face_point(top_start, top_end, start, end, u1, 0.05) + Vector2(0, -lift * 0.42)
		var p2 = _room_wall_face_point(top_start, top_end, start, end, u1, drop)
		var p3 = _room_wall_face_point(top_start, top_end, start, end, u0, drop)
		var cap_color = Color("#5d555add").lerp(Color("#2f2932dd"), _room_wall_noise(record, 170 + index))
		var cap_width = 3.2 + _room_wall_noise(record, 174 + index) * 3.8
		root.draw_line(p0, p1, cap_color.lightened(0.05), cap_width, true)
		root.draw_line(p3, p2, cap_color.darkened(0.28), maxf(1.4, cap_width * 0.34), true)
		if _room_wall_noise(record, 176 + index) > 0.52:
			var crown = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.48), 0.02) + Vector2(0, -lift * 0.88)
			_draw_small_rubble_stone(crown, 1.2 + _room_wall_noise(record, 178 + index) * 1.8, cap_color.lightened(0.04))
		if _room_wall_noise(record, 181 + index) > 0.36:
			root.draw_line(p0.lerp(p1, 0.18), p0.lerp(p1, 0.82), Color("#a69c8c8f"), 0.9, true)
		root.draw_line(p3, p2, Color("#09060aaa"), 1.0, true)
	if _room_wall_noise(record, 211) > 0.58:
		var glow_u = _room_wall_noise(record, 213)
		var glow = _room_wall_face_point(top_start, top_end, start, end, glow_u, 0.72)
		root.draw_circle(glow, 1.8, Color("#a56cff74"))

func _draw_room_wall_spilled_rubble(record: Dictionary, start: Vector2, end: Vector2) -> void:
	var pebble_count = 2 + int(_room_wall_noise(record, 230) * 3.99)
	for index in range(pebble_count):
		var u = _room_wall_noise(record, 240 + index)
		var point = start.lerp(end, u)
		var fall = 1.2 + _room_wall_noise(record, 250 + index) * 5.8
		var side_offset = (_room_wall_noise(record, 260 + index) - 0.5) * 7.0
		point += Vector2(side_offset, fall)
		var size = 1.1 + _room_wall_noise(record, 270 + index) * 2.2
		var color = Color("#312b30cc").lerp(Color("#18141acc"), _room_wall_noise(record, 280 + index))
		_draw_small_rubble_stone(point, size, color)

func _draw_small_rubble_stone(center: Vector2, size: float, color: Color) -> void:
	root.draw_polygon(PackedVector2Array([
		center + Vector2(0, -size * 0.72),
		center + Vector2(size * 0.88, -size * 0.10),
		center + Vector2(size * 0.44, size * 0.62),
		center + Vector2(-size * 0.56, size * 0.52),
		center + Vector2(-size * 0.86, -size * 0.18)
	]), PackedColorArray([
		color.lightened(0.16),
		color.lightened(0.05),
		color.darkened(0.16),
		color.darkened(0.22),
		color.darkened(0.06)
	]))

func _room_wall_face_point(top_start: Vector2, top_end: Vector2, start: Vector2, end: Vector2, u: float, v: float) -> Vector2:
	var top_point = top_start.lerp(top_end, clampf(u, 0.0, 1.0))
	var bottom_point = start.lerp(end, clampf(u, 0.0, 1.0))
	return top_point.lerp(bottom_point, clampf(v, 0.0, 1.0))

func _room_wall_noise(record: Dictionary, salt: int) -> float:
	var cell: Vector2i = record.get("cell", Vector2i.ZERO)
	return _room_edge_noise(cell, str(record.get("side", "")), salt)

func _room_edge_noise(cell: Vector2i, side: String, salt: int) -> float:
	var side_code = _side_sort_index(side) + 1
	var value = absi(cell.x * 92837111 + cell.y * 689287499 + side_code * 283923481 + salt * 104729)
	value = int((value * 1103515245 + 12345) % 2147483647)
	return float(value % 1000) / 999.0

func _draw_corridor_path_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		if int(record["mask"]) < 0:
			continue
		var data: Dictionary = record["data"]
		if not bool(data.get("is_corridor", false)):
			continue
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect.grow(-7.0))
		root.draw_polygon(diamond, PackedColorArray([
			Color("#7d6b56a8"),
			Color("#655646aa"),
			Color("#3f342eb4"),
			Color("#564736aa")
		]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#c7ad7a5c"), 1.1)
		_draw_corridor_path_seam(rect)

func _draw_corridor_path_seam(rect: Rect2) -> void:
	var diamond = _diamond(rect.grow(-15.0))
	var center = rect.get_center()
	root.draw_line(center.lerp(diamond[0], 0.42), center.lerp(diamond[2], 0.42), Color("#211b19aa"), 1.0, true)
	root.draw_line(center.lerp(diamond[1], 0.42), center.lerp(diamond[3], 0.42), Color("#9b836151"), 1.0, true)

func _draw_outside_approach_layer(tile_grid: Dictionary) -> void:
	var outside_cells: Dictionary = {}
	var outside_records: Array = []
	for record in tile_grid.get("cells", []):
		var data: Dictionary = record.get("data", {})
		if str(data.get("room_id", "")) != "outside_approach":
			continue
		var cell: Vector2i = record.get("global_cell", Vector2i.ZERO)
		outside_cells[cell] = true
		outside_records.append(record)
	for record in outside_records:
		var cell: Vector2i = record.get("global_cell", Vector2i.ZERO)
		var rect: Rect2 = record.get("rect", Rect2())
		var diamond = _diamond(rect.grow(-5.0))
		root.draw_polygon(diamond, PackedColorArray([
			Color("#8f7860b8"),
			Color("#6f5f50ba"),
			Color("#322b2dc2"),
			Color("#56483fb8")
		]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#e0bd807c"), 1.35)
		_draw_corridor_path_seam(rect)

func _draw_outside_mouth_overlay_layer(tile_grid: Dictionary) -> void:
	var outside_cells: Dictionary = {}
	var outside_records: Array = []
	for record in tile_grid.get("cells", []):
		var data: Dictionary = record.get("data", {})
		if str(data.get("room_id", "")) != "outside_approach":
			continue
		var cell: Vector2i = record.get("global_cell", Vector2i.ZERO)
		outside_cells[cell] = true
		outside_records.append(record)
	for record in outside_records:
		var cell: Vector2i = record.get("global_cell", Vector2i.ZERO)
		if outside_cells.has(cell + AutoTileMaskScript.DIRS["W"]):
			continue
		_draw_outside_cave_mouth(record.get("rect", Rect2()), cell)

func _draw_outside_cave_mouth(rect: Rect2, cell: Vector2i) -> void:
	var points = _edge_points(_diamond(rect.grow(-2.0)), "W")
	if points.size() < 2:
		return
	var start: Vector2 = points[0]
	var end: Vector2 = points[1]
	var center = start.lerp(end, 0.5)
	var height = maxf(18.0, rect.size.y * 0.58)
	var arch_top = center + Vector2(0, -height)
	root.draw_line(start, end, Color("#020104fb"), maxf(12.0, rect.size.y * 0.30), true)
	root.draw_line(start, arch_top, Color("#050307f6"), maxf(8.0, rect.size.y * 0.20), true)
	root.draw_line(arch_top, end, Color("#050307f6"), maxf(8.0, rect.size.y * 0.20), true)
	root.draw_line(start, end, Color("#d0a06fee"), maxf(4.0, rect.size.y * 0.09), true)
	for index in range(4):
		var t = (float(index) + 0.5) / 4.0
		var point = start.lerp(end, t) + Vector2(_outside_noise(cell, index) * 5.0 - 2.5, -2.0 - _outside_noise(cell, index + 11) * 6.0)
		var radius = 1.7 + _outside_noise(cell, index + 21) * 2.4
		_draw_small_rubble_stone(point, radius, Color("#7d706ad8").lerp(Color("#2a242adc"), _outside_noise(cell, index + 31)))
	var glow = Color("#946cff88")
	root.draw_circle(center + Vector2(0, -height * 0.26), maxf(9.0, rect.size.y * 0.22), glow)
	root.draw_line(center + Vector2(-rect.size.x * 0.17, -height * 0.18), center + Vector2(rect.size.x * 0.20, height * 0.10), Color("#f0c988b8"), 2.5, true)

func _outside_noise(cell: Vector2i, salt: int) -> float:
	var value = absi(cell.x * 374761393 + cell.y * 668265263 + salt * 1442695041)
	value = int((value * 1103515245 + 12345) % 2147483647)
	return float(value % 1000) / 999.0

func _draw_placeholder_floor(rect: Rect2, mask: int) -> void:
	var diamond = _diamond(rect)
	var fill = Color("#242833").lerp(Color("#4b3d2f"), float(mask % 5) / 8.0)
	root.draw_polygon(diamond, PackedColorArray([fill.lightened(0.10), fill.lightened(0.04), fill.darkened(0.05), fill]))
	root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#6e5d7a66"), 1.0)

func _draw_edge_skirt_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var mask := int(record["mask"])
		if mask < 0:
			continue
		var cell: Vector2i = record["global_cell"]
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect)
		var side_points = {
			"N": [diamond[0], diamond[1]],
			"E": [diamond[1], diamond[2]],
			"S": [diamond[2], diamond[3]],
			"W": [diamond[3], diamond[0]]
		}
		_draw_floor_corner_overlays(cell, rect)
		for side in ["N", "E", "S", "W"]:
			if _edge_open(cell, side):
				continue
			var texture = edge_tile_textures.get(_edge_texture_key(side), null)
			if texture is Texture2D:
				root.draw_texture_rect(texture, rect.grow(4.0), false, Color(1, 1, 1, 0.56))
			else:
				var points: Array = side_points[side]
				root.draw_line(points[0], points[1], Color("#0a080ed9"), 2.0)

func _draw_connection_bridge_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid.get("connection_bridges", []):
		_draw_connection_bridge(record.get("start", Vector2.ZERO), record.get("end", Vector2.ZERO), float(record.get("cell_height", 24.0)))

func _socket_record_for_ref(sockets: Array, instance_id: String, socket_id: String) -> Dictionary:
	for socket in sockets:
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			return socket
	return {}

func _draw_connection_bridge(start: Vector2, end: Vector2, cell_height: float) -> void:
	var base_width = maxf(18.0, cell_height * 0.82)
	root.draw_line(start, end, Color("#130f12e2"), base_width + 8.0, true)
	root.draw_line(start, end, Color("#5d5248df"), base_width, true)
	root.draw_line(start, end, Color("#b5a079aa"), maxf(4.0, base_width * 0.18), true)
	root.draw_circle(start.lerp(end, 0.5), maxf(5.0, base_width * 0.18), Color("#c3ad7d9a"))

func _draw_connected_path_mouth_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid.get("connection_bridges", []):
		_draw_path_mouth(record.get("from_rect", Rect2()), str(record.get("from_side", "")))
		_draw_path_mouth(record.get("to_rect", Rect2()), str(record.get("to_side", "")))

func _draw_path_mouth(rect: Rect2, side: String) -> void:
	if rect.size == Vector2.ZERO:
		return
	var diamond = _diamond(rect.grow(-5.0))
	var points = _edge_points(diamond, side)
	if points.size() < 2:
		return
	var start: Vector2 = points[0]
	var end: Vector2 = points[1]
	var center = start.lerp(end, 0.5)
	var mouth_start = center.lerp(start, 0.38)
	var mouth_end = center.lerp(end, 0.38)
	var width = maxf(4.0, rect.size.y * 0.16)
	root.draw_line(mouth_start, mouth_end, Color("#100c0ecf"), width + 4.0, true)
	root.draw_line(mouth_start, mouth_end, Color("#d3bc83c6"), width, true)
	root.draw_line(mouth_start, mouth_end, Color("#fff0b06f"), maxf(1.5, width * 0.22), true)

func _draw_back_wall_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid.get("wall_edges", []):
		if str(record.get("layer", "")) != "wall_back":
			continue
		if not _draw_wall_edge_record(record):
			var points = _edge_points(_diamond(record.get("rect", Rect2())), str(record.get("side", "")))
			if points.size() >= 2:
				_draw_wall_riser(points[0], points[1], -24.0, Color("#1d1722d8"))

func _draw_socket_cap_layer(tile_grid: Dictionary, render_layer: String) -> void:
	for socket in tile_grid["sockets"]:
		var cell: Vector2i = socket.get("cell", Vector2i.ZERO)
		var rect = root.graph.tile_cell_rect(cell).grow(-2.0)
		var side = str(socket.get("side", ""))
		if _socket_render_layer(side) != render_layer:
			continue
		var state = str(socket.get("state", "closed"))
		match state:
			"connected":
				if not _draw_socket_cap_texture(state, side, rect, 0.92):
					_draw_door_tile(side, _socket_point(rect, side), rect)
			"open_placeholder":
				if not _draw_socket_cap_texture(state, side, rect, 0.62):
					_draw_open_placeholder_marker(side, rect)
			"closed":
				_draw_closed_socket_marker(side, rect)

func _draw_socket_layer(tile_grid: Dictionary) -> void:
	for socket in tile_grid["sockets"]:
		var cell: Vector2i = socket.get("cell", Vector2i.ZERO)
		var rect = root.graph.tile_cell_rect(cell).grow(-2.0)
		var side = str(socket.get("side", ""))
		var state = str(socket.get("state", "closed"))
		var point = _socket_point(rect, side)
		if state == "connected":
			_draw_doorway_threshold(side, rect)
		elif state == "open_placeholder":
			_draw_open_placeholder_marker(side, rect)
		elif state == "closed":
			_draw_closed_socket_marker(side, rect)

func _draw_object_layer(tile_grid: Dictionary, layer_name: String) -> void:
	_prune_finished_trap_animations()
	for slot in tile_grid["objects"]:
		var slot_id = str(slot.get("id", ""))
		var texture_key = _object_texture_key_for_layer(slot, slot_id, layer_name)
		if texture_key == "":
			continue
		var texture = object_sprite_textures.get(texture_key, null)
		if not texture is Texture2D:
			continue
		var full_grid_room_fallback = _is_full_grid_room_slot(slot) and not _object_texture_uses_projection_safe_room_sprite(texture_key)
		var rect = _object_draw_rect(slot, texture_key)
		_draw_object_texture(texture, rect, slot_id, layer_name, full_grid_room_fallback)
		_draw_object_connection_marks(slot, rect, slot_id, layer_name)

func _object_texture_key_for_layer(slot: Dictionary, slot_id: String, layer_name: String) -> String:
	var slot_layer := str(slot.get("layer", "front"))
	var trap_key = _active_trap_texture_key(str(slot.get("instance_id", "")), slot_id)
	if trap_key != "":
		return trap_key if slot_layer == layer_name else ""
	var props: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {})
	var prop: Dictionary = props.get(slot_id, {})
	var variant := str(slot.get("connection_variant", ""))
	var connection_sprites: Dictionary = prop.get("connection_sprites", {})
	if variant != "" and connection_sprites.has(variant) and _connection_sprite_projection_safe(slot_id, variant):
		var variant_entry: Dictionary = connection_sprites.get(variant, {})
		if variant_entry.has(layer_name):
			return "prop:%s:%s:%s" % [slot_id, variant, layer_name]
		return ""
	var facing := str(slot.get("facing", prop.get("default_facing", "")))
	var stage_entry := _stage_facing_entry(prop, facing)
	if not stage_entry.is_empty():
		if stage_entry.has(layer_name) and _prop_can_draw_layer(prop, slot_layer, layer_name):
			return "propstage:%s:%s:%s:%s" % [slot_id, _active_castle_art_stage(), facing, layer_name]
		if bool(stage_entry.get("_complete_override", false)) and _prop_can_draw_layer(prop, slot_layer, layer_name):
			return ""
	var facing_sprites: Dictionary = prop.get("facing_sprites", {})
	if facing != "" and facing_sprites.has(facing):
		var facing_entry: Dictionary = facing_sprites.get(facing, {})
		if facing_entry.has(layer_name) and _prop_can_draw_layer(prop, slot_layer, layer_name):
			return "prop:%s:%s:%s" % [slot_id, facing, layer_name]
	var sprites: Dictionary = prop.get("sprites", {})
	if sprites.has(layer_name):
		return "prop:%s:%s" % [slot_id, layer_name]
	if slot_layer != layer_name:
		return ""
	var direct_key = "prop:%s:%s" % [slot_id, layer_name]
	if object_sprite_textures.has(direct_key):
		return direct_key
	if layer_name == "front" and object_sprite_textures.has("prop:%s:back" % slot_id):
		return "prop:%s:back" % slot_id
	return ""

func _active_castle_art_stage() -> String:
	if root == null:
		return ""
	return str(root.get("castle_art_stage"))

func _stage_facing_entry(prop: Dictionary, facing: String) -> Dictionary:
	var stage = _active_castle_art_stage()
	if stage == "" or facing == "":
		return {}
	var stage_sprites: Dictionary = prop.get("stage_facing_sprites", {})
	if not stage_sprites.has(stage):
		return {}
	var stage_facings: Dictionary = stage_sprites.get(stage, {})
	if not stage_facings.has(facing):
		return {}
	return stage_facings.get(facing, {})

func _draw_front_wall_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid.get("wall_edges", []):
		if str(record.get("layer", "")) != "wall_front":
			continue
		if not _draw_wall_edge_record(record):
			var points = _edge_points(_diamond(record.get("rect", Rect2())), str(record.get("side", "")))
			if points.size() >= 2:
				_draw_front_wall_riser(points[0], points[1], Color("#1c1720d2"))

func _draw_active_overlay(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect.grow(2.0))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#9f7cff66"), 1.0)

func _draw_walkable_overlay(tile_grid: Dictionary) -> void:
	_draw_cell_set_overlay(tile_grid, tile_grid["walk_set"], Color("#4fc36b42"), Color("#9afaa777"))

func _draw_cell_set_overlay(tile_grid: Dictionary, cell_set: Dictionary, fill: Color, outline: Color) -> void:
	for record in tile_grid["cells"]:
		if not cell_set.has(record["global_cell"]):
			continue
		var diamond = _diamond(record["rect"].grow(2.0))
		root.draw_polygon(diamond, PackedColorArray([fill, fill, fill, fill]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), outline, 1.6)

func _draw_floor_mask_overlay(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var mask := int(record["mask"])
		if mask < 0:
			continue
		var rect: Rect2 = record["rect"]
		root.draw_string(UI_FONT, rect.get_center() + Vector2(-9, 4), str(mask), HORIZONTAL_ALIGNMENT_LEFT, 32, 12, Color("#fff6d6"))

func _draw_socket_overlay(tile_grid: Dictionary) -> void:
	for socket in tile_grid["sockets"]:
		var cell: Vector2i = socket.get("cell", Vector2i.ZERO)
		var rect = root.graph.tile_cell_rect(cell).grow(-2.0)
		var point = _socket_point(rect, str(socket.get("side", "")))
		var state = str(socket.get("state", "closed"))
		var color = Color("#80d6ffdd") if state == "connected" else Color("#d8a6ffcc") if state == "open_placeholder" else Color("#6f6277cc")
		root.draw_circle(point, 6.0, color)
		root.draw_string(UI_FONT, point + Vector2(8, 3), state.substr(0, 1), HORIZONTAL_ALIGNMENT_LEFT, 24, 11, color)

func _draw_room_id_overlay(_tile_grid: Dictionary) -> void:
	for instance_id in root.graph.module_instance_ids():
		var rect = root.graph.rect(str(instance_id))
		var module = root.graph.module_data_for_instance(str(instance_id))
		var label = "%s\n%s" % [str(instance_id), str(module.get("id", ""))]
		root.draw_string(UI_FONT, rect.position + Vector2(8, 20), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 12, Color("#f5ecd8cc"))

func _draw_map_editor_overlay() -> void:
	_draw_map_editor_socket_visibility_overlay()
	_draw_map_editor_gap_path_preview()
	_draw_map_editor_gap_path_socket_pair()

func _draw_main_route_overlay() -> void:
	if root.graph == null or not root.has_method("_main_route_instance_ids"):
		return
	var route: Array = root._main_route_instance_ids()
	if route.size() < 2:
		return
	var points: Array = []
	if root.graph.has_method("path_points"):
		points = root.graph.path_points(str(route[0]), str(route[route.size() - 1]))
	if points.size() < 2:
		for instance_id_value in route:
			points.append(root.graph.center(str(instance_id_value)))
	if points.size() < 2:
		return
	var packed_points := PackedVector2Array()
	for point in points:
		packed_points.append(point)
	root.draw_polyline(packed_points, Color("#120b05cc"), 7.0, true)
	root.draw_polyline(packed_points, Color("#ffd36ac8"), 3.0, true)
	for instance_id_value in route:
		var center = root.graph.center(str(instance_id_value))
		root.draw_circle(center, 5.0, Color("#ffd36af2"))

func _draw_selected_module_highlight(tile_grid: Dictionary) -> void:
	if root.selected_room == "":
		return
	var color = Color("#ffd36af0")
	if root.map_editor_active and not root.map_editor_errors.is_empty():
		color = Color("#ff5d6cf0")
	var fill = Color(color.r, color.g, color.b, 0.10)
	var found := false
	for record in tile_grid.get("cells", []):
		var data: Dictionary = record.get("data", {})
		if str(data.get("room_id", "")) != root.selected_room:
			continue
		var rect: Rect2 = record.get("rect", Rect2()).grow(-1.0)
		var diamond = _diamond(rect)
		root.draw_polygon(diamond, PackedColorArray([fill, fill, fill, fill]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(color.r, color.g, color.b, 0.70), 1.5, true)
		found = true
	var rect = root.graph.rect(root.selected_room)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	root.draw_rect(rect.grow(8.0), Color(color.r, color.g, color.b, 0.05), true)
	root.draw_rect(rect.grow(8.0), color, false, 3.0)
	if not found:
		return
	var label_text = root.display_name_for_instance(root.selected_room) if root.has_method("display_name_for_instance") else str(root.selected_room)
	var label_rect = Rect2(Vector2(rect.get_center().x - 66.0, rect.position.y - 30.0), Vector2(132.0, 24.0))
	root.draw_rect(label_rect, Color("#100d14dd"), true)
	root.draw_rect(label_rect, color, false, 1.4)
	root.draw_string(UI_FONT, label_rect.position + Vector2(0, 17), label_text, HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 13, Color("#fff6d6"))

func _draw_map_editor_socket_visibility_overlay() -> void:
	if not root.has_method("_map_editor_socket_visibility_markers"):
		return
	var markers: Array = root._map_editor_socket_visibility_markers()
	for marker in markers:
		var cell: Vector2i = marker.get("cell", Vector2i.ZERO)
		var rect = root.graph.tile_cell_rect(cell)
		var state = str(marker.get("state", ""))
		var color = Color("#7bdcfff0")
		if state == "blocked":
			color = Color("#ff5d6ce8")
		elif state == "connected":
			color = Color("#80ffaaee")
		_draw_map_editor_socket_state_marker(rect, str(marker.get("side", "")), color)

func _draw_map_editor_socket_state_marker(rect: Rect2, side: String, color: Color) -> void:
	var diamond = _diamond(rect.grow(1.5))
	var fill = Color(color.r, color.g, color.b, 0.12)
	root.draw_polygon(diamond, PackedColorArray([fill, fill, fill, fill]))
	root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), color, 1.7, true)
	var side_points = _edge_points(diamond, side)
	if side_points.size() >= 2:
		root.draw_line(side_points[0], side_points[1], color, 3.2, true)

func _draw_map_editor_gap_path_preview() -> void:
	if not root.has_method("_map_editor_preview_gap_path_candidate"):
		return
	var candidate: Dictionary = root._map_editor_preview_gap_path_candidate()
	if candidate.is_empty():
		return
	var module: Dictionary = DataRegistry.quarter_module(str(candidate.get("module_id", "")))
	if module.is_empty():
		return
	var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
	for value in module.get("floor_cells", []):
		if not (value is Array) or value.size() < 2:
			continue
		var cell = origin + Vector2i(int(value[0]), int(value[1]))
		var rect = root.graph.tile_cell_rect(cell).grow(-3.0)
		var diamond = _diamond(rect)
		root.draw_polygon(diamond, PackedColorArray([Color("#7bdcff35"), Color("#7bdcff35"), Color("#7bdcff35"), Color("#7bdcff35")]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#7bdcffdd"), 2.0)

func _draw_map_editor_gap_path_socket_pair() -> void:
	if not root.has_method("_map_editor_preview_gap_path_socket_markers"):
		return
	var markers: Array = root._map_editor_preview_gap_path_socket_markers()
	if markers.is_empty():
		return
	var prepared: Array = []
	for marker in markers:
		var cell: Vector2i = marker.get("cell", Vector2i.ZERO)
		var rect = root.graph.tile_cell_rect(cell)
		var role = str(marker.get("role", ""))
		var color = Color("#ffd36af2") if role == "source" else Color("#7bdcfff2")
		prepared.append({
			"rect": rect,
			"side": str(marker.get("side", "")),
			"color": color
		})
	if prepared.size() == 2:
		root.draw_line(
			prepared[0]["rect"].get_center(),
			prepared[1]["rect"].get_center(),
			Color("#f7efe184"),
			2.0,
			true
		)
	for item in prepared:
		_draw_map_editor_socket_pair_marker(item["rect"], str(item["side"]), item["color"])

func _draw_map_editor_socket_pair_marker(rect: Rect2, side: String, color: Color) -> void:
	var diamond = _diamond(rect.grow(5.0))
	var fill = Color(color.r, color.g, color.b, 0.18)
	root.draw_polygon(diamond, PackedColorArray([fill, fill, fill, fill]))
	root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), color, 2.6)
	var side_points = _edge_points(diamond, side)
	if side_points.size() < 2:
		return
	root.draw_line(side_points[0], side_points[1], color, 5.0, true)
	root.draw_line(side_points[0].lerp(side_points[1], 0.5), rect.get_center(), Color(color.r, color.g, color.b, 0.74), 2.0, true)

func _draw_unit_or_cursor_cell(tile_grid: Dictionary) -> void:
	var point = _mouse_world_position()
	if root.selected_unit != null and is_instance_valid(root.selected_unit):
		point = root.selected_unit.global_position
	var best_record = _nearest_record(tile_grid, point)
	if best_record.is_empty():
		return
	var rect: Rect2 = best_record["rect"]
	var diamond = _diamond(rect.grow(4.0))
	root.draw_polygon(diamond, PackedColorArray([Color("#7cf58f36"), Color("#7cf58f36"), Color("#7cf58f36"), Color("#7cf58f36")]))
	root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#7cf58fe8"), 2.0)
	var cell: Vector2i = best_record["global_cell"]
	root.draw_string(UI_FONT, rect.position + Vector2(0, -6), "%d,%d" % [cell.x, cell.y], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, Color("#fff6d6"))

func _draw_path_overlay() -> void:
	if root.selected_unit == null or not is_instance_valid(root.selected_unit):
		return
	var points: Array = [root.selected_unit.global_position]
	points.append_array(root.selected_unit.path_points)
	if points.size() < 2:
		return
	for index in range(points.size() - 1):
		root.draw_line(points[index], points[index + 1], Color("#6fe7ffcc"), 2.0)
		root.draw_circle(points[index + 1], 4.0, Color("#d6fbffcc"))

func _load_floor_tile_textures() -> void:
	floor_tile_textures.clear()
	missing_floor_tile_masks.clear()
	var manifest: Dictionary = DataRegistry.quarter_tile_variant_manifest
	var manifest_theme := str(manifest.get("theme_id", "cave_f"))
	var floor_mask: Dictionary = manifest.get("floor_mask", {})
	for mask in range(16):
		var entry: Dictionary = floor_mask.get(str(mask), {})
		var file_hint := str(entry.get("file_hint", "floor_%s_mask_%02d.png" % [manifest_theme, mask]))
		var path = "res://assets/tiles/%s/floor/%s" % [manifest_theme, file_hint]
		if not ResourceLoader.exists(path):
			missing_floor_tile_masks.append(mask)
			continue
		var texture = ResourceLoader.load(path)
		if texture is Texture2D:
			floor_tile_textures[mask] = texture
		else:
			missing_floor_tile_masks.append(mask)

func _load_addon_tile_textures() -> void:
	edge_tile_textures.clear()
	corner_overlay_textures.clear()
	wall_tile_textures.clear()
	wall_mask_textures.clear()
	wall_edge_textures.clear()
	door_tile_textures.clear()
	missing_addon_tiles.clear()
	missing_wall_mask_tile_masks.clear()
	missing_wall_edge_keys.clear()
	var manifest: Dictionary = DataRegistry.quarter_tile_variant_manifest
	var theme := str(manifest.get("theme_id", "cave_f"))
	_load_named_tile_group(theme, "edge", manifest.get("edges", {}), edge_tile_textures)
	_load_named_tile_group(theme, "overlay", manifest.get("corner_overlays", {}), corner_overlay_textures)
	_load_named_tile_group(theme, "wall", manifest.get("walls", {}), wall_tile_textures)
	_load_wall_edge_textures(theme, manifest.get("wall_edges", {}))
	_load_named_tile_group(theme, "door", manifest.get("doors", {}), door_tile_textures)
	var wall_mask: Dictionary = manifest.get("wall_mask", {})
	for mask in range(16):
		var entry: Dictionary = wall_mask.get(str(mask), {})
		var file_hint := str(entry.get("file_hint", "wall_%s_mask_%02d.png" % [theme, mask]))
		var path = "res://assets/tiles/%s/wall/%s" % [theme, file_hint]
		if ResourceLoader.exists(path):
			var texture = ResourceLoader.load(path)
			if texture is Texture2D:
				wall_mask_textures[mask] = texture
			else:
				missing_wall_mask_tile_masks.append(mask)
		else:
			missing_wall_mask_tile_masks.append(mask)

func _load_wall_edge_textures(theme: String, entries: Dictionary) -> void:
	for key in _required_wall_edge_keys():
		var file_hint := str(entries.get(key, ""))
		if file_hint == "":
			missing_wall_edge_keys.append(key)
			continue
		var path = "res://assets/tiles/%s/wall_edges/%s" % [theme, file_hint]
		if ResourceLoader.exists(path):
			var texture = ResourceLoader.load(path)
			if texture is Texture2D:
				wall_edge_textures[key] = texture
			else:
				missing_wall_edge_keys.append(key)
		else:
			missing_wall_edge_keys.append(key)

func _required_wall_edge_keys() -> Array:
	var keys: Array = []
	for side in ["N", "E", "S", "W"]:
		for variant in ["straight", "end_a", "end_b", "cap"]:
			keys.append("wall_%s_%s" % [side, variant])
	for corner in ["NE", "ES", "SW", "WN"]:
		keys.append("wall_corner_%s" % corner)
	for side in ["N", "E", "S", "W"]:
		keys.append("wall_cap_closed_%s" % side)
		keys.append("door_open_%s" % side)
		keys.append("socket_placeholder_%s" % side)
	return keys

func _load_named_tile_group(theme: String, folder_name: String, entries: Dictionary, target: Dictionary) -> void:
	for key in entries.keys():
		var file_hint := str(entries[key])
		var path = "res://assets/tiles/%s/%s/%s" % [theme, folder_name, file_hint]
		if ResourceLoader.exists(path):
			var texture = ResourceLoader.load(path)
			if texture is Texture2D:
				target[str(key)] = texture
			else:
				missing_addon_tiles.append("%s:%s" % [folder_name, key])
		else:
			missing_addon_tiles.append("%s:%s" % [folder_name, key])

func _load_background_plate_textures() -> void:
	background_plate_textures.clear()
	missing_background_plates.clear()
	var manifest: Dictionary = DataRegistry.quarter_asset_manifest
	for background_id in manifest.get("backgrounds", {}).keys():
		var entry: Dictionary = manifest.get("backgrounds", {})[background_id]
		_load_background_plate(str(background_id), str(entry.get("path", "")))

func _load_background_plate(background_id: String, file_hint: String) -> void:
	if file_hint == "":
		missing_background_plates.append(background_id)
		return
	var path = file_hint if file_hint.begins_with("res://") else "res://%s" % file_hint
	if not ResourceLoader.exists(path):
		missing_background_plates.append(background_id)
		return
	var texture = ResourceLoader.load(path)
	if texture is Texture2D:
		background_plate_textures[background_id] = texture
	else:
		missing_background_plates.append(background_id)

func _load_socket_cap_textures() -> void:
	socket_cap_textures.clear()
	missing_socket_caps.clear()
	var manifest: Dictionary = DataRegistry.quarter_asset_manifest
	var socket_caps: Dictionary = manifest.get("socket_caps", {})
	for state in ["closed", "open_placeholder", "connected"]:
		var entries: Dictionary = socket_caps.get(state, {})
		for side in ["N", "E", "S", "W"]:
			_load_socket_cap(_socket_cap_key(state, side), str(entries.get(side, "")))

func _load_socket_cap(texture_key: String, file_hint: String) -> void:
	if file_hint == "":
		missing_socket_caps.append(texture_key)
		return
	var path = file_hint if file_hint.begins_with("res://") else "res://%s" % file_hint
	if not ResourceLoader.exists(path):
		missing_socket_caps.append(texture_key)
		return
	var texture = ResourceLoader.load(path)
	if texture is Texture2D:
		socket_cap_textures[texture_key] = texture
	else:
		missing_socket_caps.append(texture_key)

func _load_object_sprite_textures() -> void:
	object_sprite_textures.clear()
	missing_object_sprites.clear()
	trap_animation_frame_counts.clear()
	var manifest: Dictionary = DataRegistry.quarter_asset_manifest
	for prop_id in manifest.get("props", {}).keys():
		var prop: Dictionary = manifest.get("props", {})[prop_id]
		for layer_name in prop.get("sprites", {}).keys():
			_load_object_sprite("prop:%s:%s" % [prop_id, layer_name], str(prop.get("sprites", {})[layer_name]))
		for variant in prop.get("connection_sprites", {}).keys():
			if not _connection_sprite_projection_safe(str(prop_id), str(variant)):
				continue
			var variant_entry: Dictionary = prop.get("connection_sprites", {})[variant]
			for layer_name in variant_entry.keys():
				_load_object_sprite("prop:%s:%s:%s" % [prop_id, variant, layer_name], str(variant_entry[layer_name]))
		for facing in prop.get("facing_sprites", {}).keys():
			var facing_entry: Dictionary = prop.get("facing_sprites", {})[facing]
			for layer_name in facing_entry.keys():
				_load_object_sprite("prop:%s:%s:%s" % [prop_id, facing, layer_name], str(facing_entry[layer_name]))
		for stage in prop.get("stage_facing_sprites", {}).keys():
			var stage_facings: Dictionary = prop.get("stage_facing_sprites", {})[stage]
			for facing in stage_facings.keys():
				var facing_entry: Dictionary = stage_facings[facing]
				for layer_name in facing_entry.keys():
					if str(layer_name).begins_with("_"):
						continue
					_load_object_sprite("propstage:%s:%s:%s:%s" % [prop_id, stage, facing, layer_name], str(facing_entry[layer_name]))
	for trap_id in manifest.get("traps", {}).keys():
		var trap: Dictionary = manifest.get("traps", {})[trap_id]
		for animation_name in trap.get("frames", {}).keys():
			var loaded_count := 0
			var frames: Array = trap.get("frames", {})[animation_name]
			for index in range(frames.size()):
				var texture_key = "trap:%s:%s:%02d" % [trap_id, animation_name, index]
				_load_object_sprite(texture_key, str(frames[index]))
				if object_sprite_textures.has(texture_key):
					loaded_count += 1
			trap_animation_frame_counts["%s:%s" % [trap_id, animation_name]] = loaded_count

func _load_object_sprite(texture_key: String, file_hint: String) -> void:
	if _is_rejected_runtime_sprite(file_hint):
		return
	var path = file_hint if file_hint.begins_with("res://") else "res://%s" % file_hint
	if not ResourceLoader.exists(path):
		missing_object_sprites.append(texture_key)
		return
	var texture = ResourceLoader.load(path)
	if texture is Texture2D:
		object_sprite_textures[texture_key] = texture
	else:
		missing_object_sprites.append(texture_key)

func _is_rejected_runtime_sprite(file_hint: String) -> bool:
	var normalized_path := file_hint
	if normalized_path.begins_with("res://"):
		normalized_path = normalized_path.substr(6)
	var policy: Dictionary = DataRegistry.quarter_asset_manifest.get("rejected_visual_material_policy", {})
	for rejected_path in policy.get("must_not_load_as_runtime_sprites", []):
		if str(rejected_path) == normalized_path:
			return true
	return false

func _floor_tile_texture(mask: int) -> Texture2D:
	return floor_tile_textures.get(mask, null)

func _edge_open(cell: Vector2i, side: String) -> bool:
	return last_open_edge_set.has(AutoTileMaskScript.edge_key(cell, side))

func _edge_points(diamond: PackedVector2Array, side: String) -> Array:
	match side:
		"N":
			return [diamond[0], diamond[1]]
		"E":
			return [diamond[1], diamond[2]]
		"S":
			return [diamond[2], diamond[3]]
		"W":
			return [diamond[3], diamond[0]]
	return []

func _socket_state_by_edge(sockets: Array) -> Dictionary:
	var states: Dictionary = {}
	for socket in sockets:
		var cell: Vector2i = socket.get("cell", Vector2i.ZERO)
		var side = str(socket.get("side", ""))
		if side == "":
			continue
		states[AutoTileMaskScript.edge_key(cell, side)] = str(socket.get("state", "closed"))
	return states

func _wall_edge_state(cell: Vector2i, side: String, socket_states: Dictionary) -> String:
	var state = str(socket_states.get(AutoTileMaskScript.edge_key(cell, side), "closed"))
	if state == "open_placeholder":
		return "open_placeholder"
	return "closed"

func _wall_endpoint_key(point: Vector2) -> String:
	return "%d,%d" % [roundi(point.x * 10.0), roundi(point.y * 10.0)]

func _wall_render_layer(side: String) -> String:
	return "wall_front" if ["E", "S"].has(side) else "wall_back"

func _wall_edge_variant(join_prev: bool, join_next: bool) -> String:
	if join_prev and join_next:
		return "straight"
	if join_prev:
		return "end_b"
	if join_next:
		return "end_a"
	return "cap"

func _side_sort_index(side: String) -> int:
	match side:
		"N":
			return 0
		"W":
			return 1
		"E":
			return 2
		"S":
			return 3
	return 4

func _edge_texture_key(side: String) -> String:
	match side:
		"N":
			return "ne_lip"
		"E":
			return "se_lip"
		"S":
			return "sw_lip"
		"W":
			return "nw_lip"
	return ""

func _draw_floor_corner_overlays(cell: Vector2i, rect: Rect2) -> void:
	if corner_overlay_textures.is_empty():
		return
	var open = {
		"N": _edge_open(cell, "N"),
		"E": _edge_open(cell, "E"),
		"S": _edge_open(cell, "S"),
		"W": _edge_open(cell, "W")
	}
	var closed = {
		"N": not bool(open["N"]),
		"E": not bool(open["E"]),
		"S": not bool(open["S"]),
		"W": not bool(open["W"])
	}
	_draw_corner_overlay_if_needed("outer_nw", bool(closed["N"]) and bool(closed["W"]), rect, 0.42)
	_draw_corner_overlay_if_needed("outer_ne", bool(closed["N"]) and bool(closed["E"]), rect, 0.42)
	_draw_corner_overlay_if_needed("outer_se", bool(closed["S"]) and bool(closed["E"]), rect, 0.42)
	_draw_corner_overlay_if_needed("outer_sw", bool(closed["S"]) and bool(closed["W"]), rect, 0.42)
	_draw_corner_overlay_if_needed("inner_nw", bool(open["N"]) and bool(open["W"]) and (bool(closed["E"]) or bool(closed["S"])), rect, 0.30)
	_draw_corner_overlay_if_needed("inner_ne", bool(open["N"]) and bool(open["E"]) and (bool(closed["S"]) or bool(closed["W"])), rect, 0.30)
	_draw_corner_overlay_if_needed("inner_se", bool(open["S"]) and bool(open["E"]) and (bool(closed["N"]) or bool(closed["W"])), rect, 0.30)
	_draw_corner_overlay_if_needed("inner_sw", bool(open["S"]) and bool(open["W"]) and (bool(closed["N"]) or bool(closed["E"])), rect, 0.30)

func _draw_corner_overlay_if_needed(key: String, should_draw: bool, rect: Rect2, alpha: float) -> void:
	if not should_draw:
		return
	var texture = corner_overlay_textures.get(key, null)
	if texture is Texture2D:
		root.draw_texture_rect(texture, rect.grow(2.0), false, Color(1, 1, 1, alpha))

func _wall_texture_key(side: String) -> String:
	match side:
		"N", "E":
			return "ne_straight"
		"S", "W":
			return "nw_straight"
	return ""

func _wall_edge_texture_key(side: String, state: String, variant: String) -> String:
	match state:
		"open_placeholder":
			return "socket_placeholder_%s" % side
		"connected":
			return "door_open_%s" % side
	return "wall_%s_%s" % [side, variant]

func _door_texture_key(side: String) -> String:
	match side:
		"N", "E":
			return "ne_open"
		"S", "W":
			return "nw_open"
	return ""

func _socket_cap_key(state: String, side: String) -> String:
	return "%s:%s" % [state, side]

func _socket_render_layer(side: String) -> String:
	return "front" if ["E", "S"].has(side) else "back"

func _draw_socket_cap_texture(state: String, side: String, rect: Rect2, alpha: float) -> bool:
	var texture = socket_cap_textures.get(_socket_cap_key(state, side), null)
	if not texture is Texture2D:
		return false
	var draw_rect = _socket_cap_rect(texture, state, side, rect)
	root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, alpha))
	return true

func _socket_cap_rect(texture: Texture2D, state: String, side: String, rect: Rect2) -> Rect2:
	var width = rect.size.x
	var point = _socket_point(rect, side)
	var bottom_y = point.y + rect.size.y * 0.18
	match state:
		"closed":
			width = rect.size.x * 1.08
			bottom_y = rect.position.y + rect.size.y * 0.64
			if ["E", "S"].has(side):
				bottom_y = rect.end.y + rect.size.y * 0.16
		"connected":
			width = rect.size.x * 0.74
			bottom_y = point.y + rect.size.y * 0.22
		"open_placeholder":
			width = rect.size.x * 0.58
			bottom_y = point.y + rect.size.y * 0.18
	var height = width * float(texture.get_height()) / float(maxi(1, texture.get_width()))
	match side:
		"N":
			point.x += rect.size.x * 0.06
		"W":
			point.x -= rect.size.x * 0.06
		"E":
			point.x += rect.size.x * 0.05
		"S":
			point.x -= rect.size.x * 0.05
	return Rect2(Vector2(point.x - width * 0.5, bottom_y - height), Vector2(width, height))

func _draw_wall_tile(side: String, rect: Rect2) -> bool:
	var texture = wall_tile_textures.get(_wall_texture_key(side), null)
	if not texture is Texture2D:
		return false
	var width = rect.size.x * 1.18
	var height = width * float(texture.get_height()) / float(maxi(1, texture.get_width()))
	var center_x = rect.get_center().x
	var bottom_y = rect.position.y + rect.size.y * 0.62
	match side:
		"N":
			center_x += rect.size.x * 0.10
			bottom_y += rect.size.y * 0.04
		"W":
			center_x -= rect.size.x * 0.10
			bottom_y += rect.size.y * 0.02
	var draw_rect = Rect2(Vector2(center_x - width * 0.5, bottom_y - height), Vector2(width, height))
	root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, 0.96))
	return true

func _draw_wall_edge_record(record: Dictionary) -> bool:
	var texture_key = str(record.get("texture_key", ""))
	var texture = wall_edge_textures.get(texture_key, null)
	if not texture is Texture2D:
		return false
	var rect: Rect2 = record.get("rect", Rect2())
	var side = str(record.get("side", ""))
	var state = str(record.get("state", "closed"))
	var draw_rect = _wall_edge_draw_rect(texture, rect, side, state)
	root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, _wall_edge_alpha(state)))
	return true

func _wall_edge_draw_rect(texture: Texture2D, rect: Rect2, side: String, state: String) -> Rect2:
	var diamond = _diamond(rect)
	var points = _edge_points(diamond, side)
	var anchor = rect.get_center()
	if points.size() >= 2:
		anchor = points[0].lerp(points[1], 0.5)
	var width = rect.size.x * _wall_edge_width_scale(side, state)
	var height = width * float(texture.get_height()) / float(maxi(1, texture.get_width()))
	var max_height = rect.size.y * (0.72 if state == "open_placeholder" else 0.86)
	if height > max_height:
		var shrink = max_height / height
		width *= shrink
		height = max_height
	var bottom_y = anchor.y + rect.size.y * _wall_edge_bottom_offset(side, state)
	var center_x = anchor.x
	match side:
		"N":
			center_x += rect.size.x * 0.03
		"W":
			center_x -= rect.size.x * 0.03
		"E":
			center_x += rect.size.x * 0.03
		"S":
			center_x -= rect.size.x * 0.03
	return Rect2(Vector2(center_x - width * 0.5, bottom_y - height), Vector2(width, height))

func _wall_edge_width_scale(side: String, state: String) -> float:
	match state:
		"open_placeholder":
			return 0.32
		"connected":
			return 0.38
	match side:
		"N", "S":
			return 0.34
		"E", "W":
			return 0.30
	return 0.32

func _wall_edge_bottom_offset(side: String, state: String) -> float:
	if state == "open_placeholder":
		return 0.16
	match side:
		"N", "W":
			return 0.20
		"E", "S":
			return 0.18
	return 0.18

func _wall_edge_alpha(state: String) -> float:
	if state == "open_placeholder":
		return 0.46
	return 0.56

func _draw_door_tile(side: String, point: Vector2, rect: Rect2) -> bool:
	var texture = door_tile_textures.get(_door_texture_key(side), null)
	if not texture is Texture2D:
		return false
	var width = rect.size.x * 0.74
	var height = width * float(texture.get_height()) / float(maxi(1, texture.get_width()))
	var draw_rect = Rect2(Vector2(point.x - width * 0.5, point.y - height + rect.size.y * 0.22), Vector2(width, height))
	root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, 0.88))
	return true

func _draw_open_placeholder_marker(side: String, rect: Rect2) -> void:
	var point = _socket_point(rect, side)
	root.draw_circle(point, 6.0, Color("#b26cff99"))
	root.draw_arc(point, 13.0, 0.0, TAU, 28, Color("#d8a6ffbb"), 1.5)

func _draw_closed_socket_marker(side: String, rect: Rect2) -> void:
	root.draw_circle(_socket_point(rect, side), 5.5, Color("#2d2530dd"))

func _draw_doorway_threshold(side: String, rect: Rect2) -> void:
	var diamond = _diamond(rect.grow(-2.0))
	var start: Vector2
	var end: Vector2
	match side:
		"N":
			start = diamond[0]
			end = diamond[1]
		"E":
			start = diamond[1]
			end = diamond[2]
		"S":
			start = diamond[2]
			end = diamond[3]
		"W":
			start = diamond[3]
			end = diamond[0]
		_:
			return
	var center = start.lerp(end, 0.5)
	root.draw_line(center.lerp(start, 0.38), center.lerp(end, 0.38), Color("#8d746066"), 1.4)

func _object_slot_rect(slot: Dictionary) -> Rect2:
	var cell: Vector2i = slot.get("cell", Vector2i.ZERO)
	var bounds = root.graph.tile_cell_rect(cell).grow(-2.0)
	for value in slot.get("footprint", [[0, 0]]):
		if not value is Array:
			continue
		var footprint_cell = cell + Vector2i(int(value[0]), int(value[1]))
		bounds = bounds.merge(root.graph.tile_cell_rect(footprint_cell).grow(-2.0))
	return bounds

func _object_draw_rect(slot: Dictionary, texture_key: String) -> Rect2:
	if _is_full_grid_room_slot(slot) and not _object_texture_uses_projection_safe_room_sprite(texture_key):
		return _object_full_grid_room_rect(slot)
	return _object_slot_rect(slot)

func _object_full_grid_room_rect(slot: Dictionary) -> Rect2:
	return _object_slot_rect(slot).grow(6.0)

func _object_footprint_cells(slot: Dictionary) -> Array:
	var base_cell: Vector2i = slot.get("cell", Vector2i.ZERO)
	var cells: Array = []
	for value in slot.get("footprint", [[0, 0]]):
		if value is Array:
			cells.append(base_cell + Vector2i(int(value[0]), int(value[1])))
	return cells

func _is_full_grid_room_slot(slot: Dictionary) -> bool:
	return slot.get("footprint", []).size() >= 25 and str(slot.get("id", "")) != "spike_floor"

func _draw_object_texture(texture: Texture2D, rect: Rect2, slot_id: String, layer_name: String, full_grid_room_fallback: bool = false) -> void:
	var placement = _object_placement(slot_id, layer_name)
	var width_scale_value = float(placement.get("fit_width", _object_texture_width_scale(slot_id)))
	if full_grid_room_fallback:
		width_scale_value = maxf(width_scale_value, _full_grid_room_width_scale(slot_id, layer_name))
	var width_scale_max := 1.72 if full_grid_room_fallback else 1.18
	var width_scale = clampf(width_scale_value, 0.10, width_scale_max)
	var width = rect.size.x * width_scale
	var height = width * float(texture.get_height()) / float(maxi(1, texture.get_width()))
	var max_height_value = float(placement.get("max_height", 0.78))
	if full_grid_room_fallback:
		max_height_value = maxf(max_height_value, _full_grid_room_max_height(slot_id, layer_name))
	var max_height_scale_max := 1.90 if full_grid_room_fallback else 1.16
	var max_height = rect.size.y * clampf(max_height_value, 0.10, max_height_scale_max)
	if max_height > 1.0 and height > max_height:
		var shrink = max_height / height
		width *= shrink
		height = max_height
	var bottom_offset_value = float(placement.get("bottom_offset", _object_texture_bottom_offset(slot_id, layer_name)))
	if full_grid_room_fallback:
		bottom_offset_value = _full_grid_room_bottom_offset(slot_id, layer_name)
	var bottom_offset = clampf(bottom_offset_value, -0.46, 0.18)
	var x_offset = float(placement.get("x_offset", 0.0))
	var center_x = rect.get_center().x + rect.size.x * x_offset
	var bottom_y = rect.end.y + rect.size.y * bottom_offset
	var draw_rect = Rect2(Vector2(center_x - width * 0.5, bottom_y - height), Vector2(width, height))
	root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, float(placement.get("alpha", 0.98))))

func _full_grid_room_width_scale(slot_id: String, layer_name: String) -> float:
	match slot_id:
		"throne_f":
			return 1.58
		"entrance_gate_f":
			return 1.54
		"weapon_rack":
			return 1.50
		"recovery_nest_f", "treasure_pile_large":
			return 1.42
		"foundation_marks":
			return 1.34
	return 1.46

func _full_grid_room_max_height(slot_id: String, layer_name: String) -> float:
	match slot_id:
		"throne_f":
			return 1.90
		"entrance_gate_f":
			return 1.70
		"weapon_rack":
			return 1.62
		"recovery_nest_f", "treasure_pile_large":
			return 1.48
		"foundation_marks":
			return 1.28
	return 1.52

func _full_grid_room_bottom_offset(slot_id: String, layer_name: String) -> float:
	match slot_id:
		"throne_f":
			return 0.06 if layer_name == "front" else 0.02
		"entrance_gate_f", "weapon_rack":
			return 0.00
		"recovery_nest_f", "treasure_pile_large":
			return 0.04
		"foundation_marks":
			return 0.00
	return 0.02

func _draw_object_connection_marks(slot: Dictionary, rect: Rect2, slot_id: String, layer_name: String) -> void:
	var sides: Array = slot.get("connected_sides", [])
	if _is_full_grid_room_slot(slot) or sides.is_empty() or _has_connection_sprite_for_variant(slot_id, str(slot.get("connection_variant", ""))) or not _should_draw_object_connection_marks(slot_id, slot, layer_name):
		return
	var diamond = _diamond(rect.grow(-4.0))
	var mark_width = maxf(5.0, rect.size.y * 0.045)
	for side_value in sides:
		var side = str(side_value)
		var points = _edge_points(diamond, side)
		if points.size() < 2:
			continue
		var start = points[0].lerp(points[1], 0.34)
		var end = points[0].lerp(points[1], 0.66)
		root.draw_line(start, end, Color("#100b0dcc"), mark_width + 4.0, true)
		root.draw_line(start, end, Color("#b99a67bb"), mark_width, true)
		root.draw_line(start, end, Color("#f0dda488"), maxf(1.5, mark_width * 0.24), true)

func _should_draw_object_connection_marks(slot_id: String, slot: Dictionary, layer_name: String) -> bool:
	if layer_name == "front":
		return true
	var slot_layer = str(slot.get("layer", "front"))
	return slot_layer == layer_name and not _object_has_front_visual(slot_id)

func _object_has_front_visual(slot_id: String) -> bool:
	var props: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {})
	var prop: Dictionary = props.get(slot_id, {})
	if prop.get("sprites", {}).has("front"):
		return true
	for stacked_layer in prop.get("stack_layers", []):
		if str(stacked_layer) == "front":
			return true
	for facing_entry in prop.get("facing_sprites", {}).values():
		if facing_entry is Dictionary and facing_entry.has("front"):
			return true
	return false

func _has_connection_sprite_for_variant(slot_id: String, variant: String) -> bool:
	if variant == "":
		return false
	return _connection_sprite_projection_safe(slot_id, variant)

func _connection_sprite_projection_safe(slot_id: String, variant: String) -> bool:
	if variant == "":
		return false
	var props: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {})
	var prop: Dictionary = props.get(slot_id, {})
	if not prop.get("connection_sprites", {}).has(variant):
		return false
	var projection_value = prop.get("connection_sprite_projection", "")
	if projection_value is Dictionary:
		projection_value = projection_value.get(variant, "")
	return str(projection_value) == "iso_diamond_5x5"

func _object_texture_uses_projection_safe_room_sprite(texture_key: String) -> bool:
	var parts = texture_key.split(":")
	if parts.size() != 4 or str(parts[0]) != "prop":
		return false
	return _connection_sprite_projection_safe(str(parts[1]), str(parts[2]))

func _prop_can_draw_layer(prop: Dictionary, slot_layer: String, layer_name: String) -> bool:
	if slot_layer == layer_name:
		return true
	for stacked_layer in prop.get("stack_layers", []):
		if str(stacked_layer) == layer_name:
			return true
	return false

func _object_placement(slot_id: String, layer_name: String) -> Dictionary:
	var props: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {})
	var prop: Dictionary = props.get(slot_id, {})
	var placement_root: Dictionary = prop.get("placement", {})
	var result: Dictionary = {}
	for key in placement_root.get("default", {}).keys():
		result[key] = placement_root["default"][key]
	if placement_root.has(layer_name):
		var layer_placement: Dictionary = placement_root[layer_name]
		for key in layer_placement.keys():
			result[key] = layer_placement[key]
	return result

func _object_texture_width_scale(slot_id: String) -> float:
	match slot_id:
		"small_brazier":
			return 0.88
		"foundation_marks":
			return 1.08
		"spike_floor":
			return 1.02
		"treasure_pile_large":
			return 1.26
		"recovery_nest_f":
			return 1.22
		"weapon_rack":
			return 1.32
		"entrance_gate_f":
			return 1.30
		"throne_f":
			return 1.18
		"watch_post":
			return 1.04
	return 0.96

func _object_texture_bottom_offset(slot_id: String, layer_name: String) -> float:
	match slot_id:
		"spike_floor", "foundation_marks":
			return 0.00
		"small_brazier":
			return 0.02
		"entrance_gate_f", "weapon_rack":
			return 0.00
		"throne_f":
			return 0.08 if layer_name == "front" else 0.02
		"treasure_pile_large", "recovery_nest_f":
			return 0.04
		"watch_post":
			return 0.04
	return 0.02 if layer_name == "front" else -0.01

func _active_trap_texture_key(instance_id: String, trap_id: String) -> String:
	var animation_key = _trap_animation_key(instance_id, trap_id)
	if active_trap_animations.has(animation_key):
		var frame_count = _trap_animation_frame_count(trap_id, "trigger")
		var elapsed = maxi(0, int(Time.get_ticks_msec()) - int(active_trap_animations[animation_key]))
		var frame_index = int(elapsed / TRAP_TRIGGER_FRAME_MSEC)
		if frame_index >= frame_count:
			active_trap_animations.erase(animation_key)
		else:
			if root != null:
				root.queue_redraw()
			return "trap:%s:trigger:%02d" % [trap_id, frame_index]
	if _trap_animation_frame_count(trap_id, "idle") > 0:
		return "trap:%s:idle:00" % trap_id
	return ""

func _trap_animation_frame_count(trap_id: String, animation_name: String) -> int:
	return int(trap_animation_frame_counts.get("%s:%s" % [trap_id, animation_name], 0))

func _trap_animation_key(instance_id: String, trap_id: String) -> String:
	return "%s:%s" % [instance_id, trap_id]

func _prune_finished_trap_animations() -> void:
	for animation_key in active_trap_animations.keys():
		var trap_id = str(animation_key).get_slice(":", 1)
		var frame_count = _trap_animation_frame_count(trap_id, "trigger")
		var elapsed = maxi(0, int(Time.get_ticks_msec()) - int(active_trap_animations[animation_key]))
		if frame_count <= 0 or int(elapsed / TRAP_TRIGGER_FRAME_MSEC) >= frame_count:
			active_trap_animations.erase(animation_key)

func _socket_point(rect: Rect2, side: String) -> Vector2:
	var center = rect.get_center()
	match side:
		"N":
			return Vector2(center.x + rect.size.x * 0.18, rect.position.y + rect.size.y * 0.08)
		"E":
			return Vector2(rect.end.x - rect.size.x * 0.08, center.y + rect.size.y * 0.18)
		"S":
			return Vector2(center.x - rect.size.x * 0.18, rect.end.y - rect.size.y * 0.08)
		"W":
			return Vector2(rect.position.x + rect.size.x * 0.08, center.y - rect.size.y * 0.18)
	return center

func _draw_wall_riser(start: Vector2, end: Vector2, height: float, color: Color) -> void:
	var top_start = start + Vector2(0, height)
	var top_end = end + Vector2(0, height)
	root.draw_polygon(PackedVector2Array([top_start, top_end, end, start]), PackedColorArray([color, color, color.darkened(0.14), color.darkened(0.14)]))

func _draw_front_wall_riser(start: Vector2, end: Vector2, color: Color) -> void:
	var height := 7.0
	var bottom_start = start + Vector2(0, height)
	var bottom_end = end + Vector2(0, height)
	root.draw_polygon(PackedVector2Array([start, end, bottom_end, bottom_start]), PackedColorArray([color.lightened(0.12), color.lightened(0.06), color.darkened(0.20), color.darkened(0.16)]))
	root.draw_line(start, end, Color("#574758aa"), 1.2)
	root.draw_line(bottom_start, bottom_end, Color("#07050acc"), 1.0)

func _nearest_record(tile_grid: Dictionary, point: Vector2) -> Dictionary:
	var best_record: Dictionary = {}
	var best_distance = INF
	for record in tile_grid["cells"]:
		var distance = record["rect"].get_center().distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best_record = record
	return best_record

func _mouse_world_position() -> Vector2:
	var screen_point = root.get_viewport().get_mouse_position()
	if root.current_screen == Constants.SCREEN_COMBAT:
		return root._combat_screen_to_world(screen_point)
	return root.get_global_mouse_position()

func _diamond(rect: Rect2) -> PackedVector2Array:
	var center = rect.get_center()
	return PackedVector2Array([
		Vector2(center.x, rect.position.y),
		Vector2(rect.end.x, center.y),
		Vector2(center.x, rect.end.y),
		Vector2(rect.position.x, center.y)
	])
