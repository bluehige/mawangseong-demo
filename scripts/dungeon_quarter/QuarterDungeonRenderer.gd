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
var wall_tile_textures: Dictionary = {}
var wall_mask_textures: Dictionary = {}
var door_tile_textures: Dictionary = {}
var background_plate_textures: Dictionary = {}
var socket_cap_textures: Dictionary = {}
var object_sprite_textures: Dictionary = {}
var trap_animation_frame_counts: Dictionary = {}
var active_trap_animations: Dictionary = {}
var missing_floor_tile_masks: Array = []
var missing_addon_tiles: Array = []
var missing_wall_mask_tile_masks: Array = []
var missing_background_plates: Array = []
var missing_socket_caps: Array = []
var missing_object_sprites: Array = []
var last_floor_masks: Dictionary = {}
var last_open_edge_set: Dictionary = {}
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
	_draw_edge_skirt_layer(tile_grid)
	_draw_back_wall_layer(tile_grid)
	_draw_socket_cap_layer(tile_grid, "back")
	_draw_connection_bridge_layer(tile_grid)
	_draw_socket_layer(tile_grid)
	_draw_object_layer(tile_grid, "back")
	_draw_object_layer(tile_grid, "front")
	_draw_front_wall_layer(tile_grid)
	_draw_socket_cap_layer(tile_grid, "front")
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
	return edge_tile_textures.size() >= 4

func debug_loaded_addon_tile_count() -> int:
	return edge_tile_textures.size() + wall_tile_textures.size() + door_tile_textures.size()

func debug_missing_addon_tiles() -> Array:
	return missing_addon_tiles.duplicate()

func has_wall_mask_tile_textures() -> bool:
	return wall_mask_textures.size() >= 16

func debug_loaded_wall_mask_tile_count() -> int:
	return wall_mask_textures.size()

func debug_missing_wall_mask_tile_masks() -> Array:
	return missing_wall_mask_tile_masks.duplicate()

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
	return []

func debug_wall_cell_count() -> int:
	return 0

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
	return {
		"cells": cells,
		"floor_set": floor_set,
		"walk_set": walk_set,
		"blocked_set": blocked_set,
		"active_set": active_cells,
		"open_edge_set": last_open_edge_set,
		"sockets": root.graph.debug_socket_cells(),
		"objects": root.graph.debug_object_slots()
	}

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
		var texture = _floor_tile_texture(mask)
		if texture != null:
			root.draw_texture_rect(texture, rect.grow(3.0), false, Color(1, 1, 1, 0.98))
		else:
			_draw_placeholder_floor(rect, mask)

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
	for pair in root.graph.connection_pairs():
		var from_socket = _socket_record_for_ref(tile_grid["sockets"], str(pair.get("from_instance", "")), str(pair.get("from_socket", "")))
		var to_socket = _socket_record_for_ref(tile_grid["sockets"], str(pair.get("to_instance", "")), str(pair.get("to_socket", "")))
		if from_socket.is_empty() or to_socket.is_empty():
			continue
		if str(from_socket.get("state", "")) != "connected" or str(to_socket.get("state", "")) != "connected":
			continue
		var from_rect = root.graph.tile_cell_rect(from_socket.get("cell", Vector2i.ZERO)).grow(-4.0)
		var to_rect = root.graph.tile_cell_rect(to_socket.get("cell", Vector2i.ZERO)).grow(-4.0)
		_draw_connection_bridge(from_rect.get_center(), to_rect.get_center(), minf(from_rect.size.y, to_rect.size.y))

func _socket_record_for_ref(sockets: Array, instance_id: String, socket_id: String) -> Dictionary:
	for socket in sockets:
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			return socket
	return {}

func _draw_connection_bridge(start: Vector2, end: Vector2, cell_height: float) -> void:
	var base_width = maxf(14.0, cell_height * 0.68)
	root.draw_line(start, end, Color("#1b1518"), base_width + 5.0, true)
	root.draw_line(start, end, Color("#6b5f57"), base_width, true)
	root.draw_line(start, end, Color("#91806d"), maxf(3.0, base_width * 0.18), true)
	root.draw_circle(start.lerp(end, 0.5), maxf(4.0, base_width * 0.18), Color("#a9977faa"))

func _draw_back_wall_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var mask := int(record["mask"])
		if mask < 0:
			continue
		var cell: Vector2i = record["global_cell"]
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect)
		if not _edge_open(cell, "N"):
			if not _draw_wall_tile("N", rect):
				_draw_wall_riser(diamond[0], diamond[1], -24.0, Color("#1d1722d8"))
		if not _edge_open(cell, "W"):
			if not _draw_wall_tile("W", rect):
				_draw_wall_riser(diamond[3], diamond[0], -22.0, Color("#18141ed2"))

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
				if not _draw_socket_cap_texture(state, side, rect, 1.0):
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
		var rect = _object_slot_rect(slot)
		_draw_object_texture(texture, rect, slot_id, layer_name)

func _object_texture_key_for_layer(slot: Dictionary, slot_id: String, layer_name: String) -> String:
	var slot_layer := str(slot.get("layer", "front"))
	var trap_key = _active_trap_texture_key(str(slot.get("instance_id", "")), slot_id)
	if trap_key != "":
		return trap_key if slot_layer == layer_name else ""
	var props: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {})
	var prop: Dictionary = props.get(slot_id, {})
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

func _draw_front_wall_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var mask := int(record["mask"])
		if mask < 0:
			continue
		var cell: Vector2i = record["global_cell"]
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect)
		if not _edge_open(cell, "E"):
			_draw_front_wall_riser(diamond[1], diamond[2], Color("#1c1720d2"))
		if not _edge_open(cell, "S"):
			_draw_front_wall_riser(diamond[2], diamond[3], Color("#1a151dd2"))

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
	var rect = root.graph.rect(root.selected_room)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var color = Color("#ffd36add") if root.map_editor_errors.is_empty() else Color("#ff5d6cdd")
	root.draw_rect(rect.grow(8.0), Color(color.r, color.g, color.b, 0.08), true)
	root.draw_rect(rect.grow(8.0), color, false, 3.0)

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
	wall_tile_textures.clear()
	wall_mask_textures.clear()
	door_tile_textures.clear()
	missing_addon_tiles.clear()
	missing_wall_mask_tile_masks.clear()
	var manifest: Dictionary = DataRegistry.quarter_tile_variant_manifest
	var theme := str(manifest.get("theme_id", "cave_f"))
	_load_named_tile_group(theme, "edge", manifest.get("edges", {}), edge_tile_textures)
	_load_named_tile_group(theme, "wall", manifest.get("walls", {}), wall_tile_textures)
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
	var path = file_hint if file_hint.begins_with("res://") else "res://%s" % file_hint
	if not ResourceLoader.exists(path):
		missing_object_sprites.append(texture_key)
		return
	var texture = ResourceLoader.load(path)
	if texture is Texture2D:
		object_sprite_textures[texture_key] = texture
	else:
		missing_object_sprites.append(texture_key)

func _floor_tile_texture(mask: int) -> Texture2D:
	return floor_tile_textures.get(mask, null)

func _edge_open(cell: Vector2i, side: String) -> bool:
	return last_open_edge_set.has(AutoTileMaskScript.edge_key(cell, side))

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

func _wall_texture_key(side: String) -> String:
	match side:
		"N", "E":
			return "ne_straight"
		"S", "W":
			return "nw_straight"
	return ""

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

func _draw_object_texture(texture: Texture2D, rect: Rect2, slot_id: String, layer_name: String) -> void:
	var width = rect.size.x * _object_texture_width_scale(slot_id)
	var height = width * float(texture.get_height()) / float(maxi(1, texture.get_width()))
	var bottom_y = rect.end.y + rect.size.y * _object_texture_bottom_offset(slot_id, layer_name)
	var draw_rect = Rect2(Vector2(rect.get_center().x - width * 0.5, bottom_y - height), Vector2(width, height))
	root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, 0.98))

func _object_texture_width_scale(slot_id: String) -> float:
	match slot_id:
		"small_brazier":
			return 0.72
		"foundation_marks":
			return 0.92
		"spike_floor":
			return 0.96
		"treasure_pile_large":
			return 1.16
		"recovery_nest_f":
			return 1.02
		"weapon_rack":
			return 1.12
		"entrance_gate_f":
			return 0.92
		"throne_f":
			return 0.86
		"watch_post":
			return 0.94
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
