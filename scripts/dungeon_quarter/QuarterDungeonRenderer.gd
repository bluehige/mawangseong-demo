extends RefCounted
class_name QuarterDungeonRenderer

const Constants = preload("res://scripts/core/Constants.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")
const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")

const REQUIRED_LAYER_NAMES = [
	"FloorLayer",
	"EdgeLayer",
	"BackWallLayer",
	"DoorBackLayer",
	"ObjectBackLayer",
	"UnitYSortLayer",
	"ObjectFrontLayer",
	"FrontWallLayer",
	"TrapEffectLayer",
	"DebugOverlayLayer"
]

const FLOOR_LAYER_Z = -100
const EDGE_LAYER_Z = -90
const BACK_WALL_LAYER_Z = -70
const DOOR_BACK_LAYER_Z = -60
const OBJECT_BACK_LAYER_Z = -40
const OBJECT_FRONT_LAYER_Z = 30
const FRONT_WALL_LAYER_Z = 50
const DEBUG_LAYER_Z = 200

var root: Node
var last_floor_masks: Dictionary = {}
var last_floor_count := 0
var floor_tile_textures: Dictionary = {}
var missing_floor_tile_masks: Array = []
var edge_tile_textures: Dictionary = {}
var corner_overlay_textures: Dictionary = {}
var wall_tile_textures: Dictionary = {}
var door_tile_textures: Dictionary = {}
var missing_addon_tiles: Array = []
var object_sprite_textures: Dictionary = {}
var missing_object_sprites: Array = []

func setup(game_root: Node) -> void:
	root = game_root
	_load_floor_tile_textures()
	_load_addon_tile_textures()
	_load_object_sprite_textures()

func draw() -> void:
	if root == null or root.graph == null or not root.use_quarter_module_map:
		return
	var tile_grid = _build_tile_grid()
	_draw_background()
	_draw_floor_layer(tile_grid)
	_draw_edge_layer(tile_grid)
	_draw_corner_overlay_layer(tile_grid)
	_draw_back_wall_layer(tile_grid)
	_draw_door_back_layer(tile_grid)
	_draw_object_layer(tile_grid, "back")
	_draw_object_layer(tile_grid, "front")
	_draw_front_wall_layer(tile_grid)
	if root.debug_show_walkable_overlay:
		_draw_walkable_overlay(tile_grid)
	if root.debug_show_blocked_overlay:
		_draw_blocked_overlay(tile_grid)
	if root.debug_show_quarter_module_overlay:
		_draw_module_overlay(tile_grid)
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

func debug_loaded_visual_count() -> int:
	return 0

func has_floor_tile_textures() -> bool:
	return floor_tile_textures.size() >= 16

func debug_loaded_floor_tile_count() -> int:
	return floor_tile_textures.size()

func debug_missing_floor_tile_masks() -> Array:
	return missing_floor_tile_masks.duplicate()

func has_addon_tile_textures() -> bool:
	return edge_tile_textures.size() >= 4 and corner_overlay_textures.size() >= 8 and wall_tile_textures.size() >= 2 and door_tile_textures.size() >= 2

func debug_loaded_addon_tile_count() -> int:
	return edge_tile_textures.size() + corner_overlay_textures.size() + wall_tile_textures.size() + door_tile_textures.size()

func debug_missing_addon_tiles() -> Array:
	return missing_addon_tiles.duplicate()

func has_object_sprite_textures() -> bool:
	return object_sprite_textures.size() >= 13

func debug_loaded_object_sprite_count() -> int:
	return object_sprite_textures.size()

func debug_missing_object_sprites() -> Array:
	return missing_object_sprites.duplicate()

func debug_visual_variant_key(instance_id: String) -> String:
	return _socket_variant_key(_connected_socket_sides(instance_id))

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

func debug_layer_names() -> Array:
	return REQUIRED_LAYER_NAMES.duplicate()

func _build_tile_grid() -> Dictionary:
	var cells: Array = []
	var floor_set: Dictionary = {}
	var walk_set: Dictionary = {}
	var blocked_set: Dictionary = {}
	var object_slots: Array = []
	var sockets: Array = []
	var room_centers: Dictionary = {}
	last_floor_masks.clear()

	for instance_id in root.graph.module_instance_ids():
		var placed = root.graph.placed_module_data(str(instance_id))
		var module = root.graph.module_data_for_instance(str(instance_id))
		if module.is_empty():
			continue
		var footprint = _module_footprint(module)
		for value in module.get("floor_cells", []):
			if not value is Array:
				continue
			var local_cell = _array_to_cell(value)
			var global_cell = _global_cell(placed, local_cell)
			var record = {
				"instance_id": str(instance_id),
				"local_cell": local_cell,
				"global_cell": global_cell,
				"rect": _projected_local_cell_rect(str(instance_id), local_cell, footprint)
			}
			cells.append(record)
			floor_set[global_cell] = true
		for value in module.get("walk_cells", []):
			if value is Array:
				walk_set[_global_cell(placed, _array_to_cell(value))] = true
		for value in _blocked_cell_values(module):
			if value is Array:
				blocked_set[_global_cell(placed, _array_to_cell(value))] = true
		for value in module.get("prop_block_cells", []):
			if value is Array:
				blocked_set[_global_cell(placed, _array_to_cell(value))] = true
		for slot in module.get("object_slots", []):
			object_slots.append({
				"instance_id": str(instance_id),
				"id": str(slot.get("id", "")),
				"cell": _array_to_cell(slot.get("cell", [0, 0])),
				"layer": str(slot.get("layer", "front")),
				"module_footprint": footprint,
				"object_footprint": slot.get("footprint", [[0, 0]])
			})
		for socket in module.get("sockets", []):
			var socket_local_cell = _array_to_cell(socket.get("cell", socket.get("local_cell", [0, 0])))
			sockets.append({
				"instance_id": str(instance_id),
				"socket_id": str(socket.get("id", "")),
				"side": str(socket.get("side", socket.get("dir", ""))),
				"local_cell": socket_local_cell,
				"global_cell": _global_cell(placed, socket_local_cell),
				"footprint": footprint
			})
		room_centers[str(instance_id)] = root.graph.center(str(instance_id))

	for record in cells:
		var global_cell: Vector2i = record["global_cell"]
		var mask = AutoTileMaskScript.get_4bit_mask(global_cell, floor_set)
		record["mask"] = mask
		last_floor_masks[global_cell] = mask
	last_floor_count = cells.size()
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
		"object_slots": object_slots,
		"sockets": sockets,
		"socket_edge_set": _socket_edge_set(sockets),
		"room_centers": room_centers
	}

func _draw_background() -> void:
	root.draw_rect(Rect2(Vector2.ZERO, Vector2(1920, 1080)), Color("#050507"), true)
	root.draw_rect(Rect2(Vector2(330, 78), Vector2(1198, 804)), Color("#101018"), true)
	root.draw_rect(Rect2(Vector2(330, 78), Vector2(1198, 804)), Color("#2c2435"), false, 3.0)

func _draw_floor_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var rect: Rect2 = record["rect"]
		var mask := int(record["mask"])
		var texture = _floor_tile_texture(mask)
		if texture != null:
			root.draw_texture_rect(texture, rect.grow(3.0), false, Color(1, 1, 1, 0.98))
			continue
		_draw_placeholder_floor(rect, mask)

func _draw_placeholder_floor(rect: Rect2, mask: int) -> void:
	var diamond = _diamond(rect)
	var base = Color("#242833")
	var mask_tint = Color("#443451").lerp(Color("#4b3d2f"), float(mask % 5) / 8.0)
	var fill = base.lerp(mask_tint, 0.42)
	root.draw_polygon(diamond, PackedColorArray([
		fill.lightened(0.10),
		fill.lightened(0.04),
		fill.darkened(0.05),
		fill
	]))
	root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#6e5d7a66"), 1.0)

func _load_floor_tile_textures() -> void:
	floor_tile_textures.clear()
	missing_floor_tile_masks.clear()
	var manifest: Dictionary = DataRegistry.quarter_tile_variant_manifest
	var theme_id := str(manifest.get("theme_id", "cave_f"))
	var floor_mask: Dictionary = manifest.get("floor_mask", {})
	for mask in range(16):
		var entry: Dictionary = floor_mask.get(str(mask), {})
		var file_hint := str(entry.get("file_hint", "floor_%s_mask_%02d.png" % [theme_id, mask]))
		var path = _floor_tile_path(theme_id, file_hint)
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
	door_tile_textures.clear()
	missing_addon_tiles.clear()
	var manifest: Dictionary = DataRegistry.quarter_tile_variant_manifest
	var theme_id := str(manifest.get("theme_id", "cave_f"))
	_load_named_tile_group(theme_id, "edge", manifest.get("edges", {}), edge_tile_textures)
	_load_named_tile_group(theme_id, "overlay", manifest.get("corner_overlays", {}), corner_overlay_textures)
	_load_named_tile_group(theme_id, "wall", manifest.get("walls", {}), wall_tile_textures)
	_load_named_tile_group(theme_id, "door", manifest.get("doors", {}), door_tile_textures)

func _load_named_tile_group(theme_id: String, folder_name: String, entries: Dictionary, target: Dictionary) -> void:
	for key in entries.keys():
		var file_hint := str(entries[key])
		var path = _tile_asset_path(theme_id, folder_name, file_hint)
		if not ResourceLoader.exists(path):
			missing_addon_tiles.append("%s:%s" % [folder_name, key])
			continue
		var texture = ResourceLoader.load(path)
		if texture is Texture2D:
			target[str(key)] = texture
		else:
			missing_addon_tiles.append("%s:%s" % [folder_name, key])

func _load_object_sprite_textures() -> void:
	object_sprite_textures.clear()
	missing_object_sprites.clear()
	var manifest: Dictionary = DataRegistry.quarter_asset_manifest
	var props: Dictionary = manifest.get("props", {})
	for prop_id in props.keys():
		var prop: Dictionary = props[prop_id]
		var sprites: Dictionary = prop.get("sprites", {})
		for layer_name in sprites.keys():
			_load_object_sprite("prop:%s:%s" % [prop_id, layer_name], str(sprites[layer_name]))
	var traps: Dictionary = manifest.get("traps", {})
	for trap_id in traps.keys():
		var trap: Dictionary = traps[trap_id]
		var frames: Dictionary = trap.get("frames", {})
		for animation_name in frames.keys():
			var frame_paths: Array = frames[animation_name]
			for index in range(frame_paths.size()):
				_load_object_sprite("trap:%s:%s:%02d" % [trap_id, animation_name, index], str(frame_paths[index]))

func _load_object_sprite(texture_key: String, file_hint: String) -> void:
	var path = _object_sprite_path(file_hint)
	if not ResourceLoader.exists(path):
		missing_object_sprites.append(texture_key)
		return
	var texture = ResourceLoader.load(path)
	if texture is Texture2D:
		object_sprite_textures[texture_key] = texture
	else:
		missing_object_sprites.append(texture_key)

func _floor_tile_path(theme_id: String, file_hint: String) -> String:
	if file_hint.begins_with("res://"):
		return file_hint
	return "res://assets/tiles/%s/floor/%s" % [theme_id, file_hint]

func _tile_asset_path(theme_id: String, folder_name: String, file_hint: String) -> String:
	if file_hint.begins_with("res://"):
		return file_hint
	return "res://assets/tiles/%s/%s/%s" % [theme_id, folder_name, file_hint]

func _object_sprite_path(file_hint: String) -> String:
	if file_hint.begins_with("res://"):
		return file_hint
	return "res://%s" % file_hint

func _floor_tile_texture(mask: int) -> Texture2D:
	return floor_tile_textures.get(mask, null)

func _draw_edge_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect)
		var mask := int(record["mask"])
		var cell: Vector2i = record["global_cell"]
		_draw_missing_edge_tile(mask, "NW", rect, diamond[0], diamond[3], _has_socket_edge(tile_grid, cell, "NW"))
		_draw_missing_edge_tile(mask, "NE", rect, diamond[0], diamond[1], _has_socket_edge(tile_grid, cell, "NE"))
		_draw_missing_edge_tile(mask, "SE", rect, diamond[1], diamond[2], _has_socket_edge(tile_grid, cell, "SE"))
		_draw_missing_edge_tile(mask, "SW", rect, diamond[2], diamond[3], _has_socket_edge(tile_grid, cell, "SW"))

func _draw_corner_overlay_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var rect: Rect2 = record["rect"]
		var mask := int(record["mask"])
		var cell: Vector2i = record["global_cell"]
		_draw_outer_corner_if_open(tile_grid, mask, cell, "NW", "NE", "outer_nw", rect)
		_draw_outer_corner_if_open(tile_grid, mask, cell, "NE", "SE", "outer_ne", rect)
		_draw_outer_corner_if_open(tile_grid, mask, cell, "SE", "SW", "outer_se", rect)
		_draw_outer_corner_if_open(tile_grid, mask, cell, "SW", "NW", "outer_sw", rect)
		_draw_inner_corner_if_open(tile_grid, cell, "NW", "NE", Vector2i(-1, -1), "inner_nw", rect)
		_draw_inner_corner_if_open(tile_grid, cell, "NE", "SE", Vector2i(1, -1), "inner_ne", rect)
		_draw_inner_corner_if_open(tile_grid, cell, "SE", "SW", Vector2i(1, 1), "inner_se", rect)
		_draw_inner_corner_if_open(tile_grid, cell, "SW", "NW", Vector2i(-1, 1), "inner_sw", rect)

func _draw_back_wall_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var mask := int(record["mask"])
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect)
		var cell: Vector2i = record["global_cell"]
		if (mask & int(AutoTileMaskScript.BITS["NE"])) == 0:
			if not _has_socket_edge(tile_grid, cell, "NE") and not _draw_wall_tile("NE", rect):
				_draw_wall_riser(diamond[0], diamond[1], -10.0, Color("#1c1822d9"))
		if (mask & int(AutoTileMaskScript.BITS["NW"])) == 0:
			if not _has_socket_edge(tile_grid, cell, "NW") and not _draw_wall_tile("NW", rect):
				_draw_wall_riser(diamond[0], diamond[3], -10.0, Color("#18151ed9"))

func _draw_door_back_layer(tile_grid: Dictionary) -> void:
	for socket in tile_grid["sockets"]:
		var side = str(socket["side"])
		if not ["NE", "NW"].has(side):
			continue
		var point = _socket_point(socket)
		var rect = _projected_local_cell_rect(str(socket["instance_id"]), socket["local_cell"], socket["footprint"])
		if _draw_door_tile(side, point, rect):
			continue
		root.draw_circle(point + Vector2(0, -8), 8.0, Color("#5d466acc"))
		root.draw_arc(point + Vector2(0, -8), 12.0, PI, TAU, 16, Color("#b994ff99"), 2.0)

func _draw_object_layer(tile_grid: Dictionary, layer_name: String) -> void:
	for slot in tile_grid["object_slots"]:
		if str(slot["layer"]) != layer_name:
			continue
		var rect = _object_slot_rect(slot)
		var slot_id := str(slot["id"])
		var texture = _object_slot_texture(slot_id, layer_name)
		if texture is Texture2D:
			_draw_object_texture(texture, rect, slot_id, layer_name)
			continue
		var center = rect.get_center()
		var color = Color("#806bb8cc") if layer_name == "back" else Color("#c39a54cc")
		root.draw_circle(center + Vector2(0, -rect.size.y * 0.18), max(5.0, min(rect.size.x, rect.size.y) * 0.16), color)
		if root.debug_show_room_id_overlay:
			root.draw_string(UI_FONT, center + Vector2(-44, -rect.size.y * 0.34), slot_id, HORIZONTAL_ALIGNMENT_CENTER, 88, 10, Color("#fff2d7bb"))

func _object_slot_texture(slot_id: String, layer_name: String):
	var layer_key = "prop:%s:%s" % [slot_id, layer_name]
	if object_sprite_textures.has(layer_key):
		return object_sprite_textures[layer_key]
	var front_key = "prop:%s:front" % slot_id
	if object_sprite_textures.has(front_key):
		return object_sprite_textures[front_key]
	var back_key = "prop:%s:back" % slot_id
	if object_sprite_textures.has(back_key):
		return object_sprite_textures[back_key]
	var trap_key = "trap:%s:idle:00" % slot_id
	if object_sprite_textures.has(trap_key):
		return object_sprite_textures[trap_key]
	return null

func _draw_object_texture(texture: Texture2D, rect: Rect2, slot_id: String, layer_name: String) -> void:
	var width = rect.size.x * _object_texture_width_scale(slot_id)
	var height = width * float(texture.get_height()) / float(maxi(1, texture.get_width()))
	var bottom_y = rect.end.y + rect.size.y * _object_texture_bottom_offset(slot_id, layer_name)
	var draw_rect = Rect2(
		Vector2(rect.get_center().x - width * 0.5, bottom_y - height),
		Vector2(width, height)
	)
	root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, 0.98))

func _object_texture_width_scale(slot_id: String) -> float:
	match slot_id:
		"small_brazier":
			return 0.58
		"foundation_marks":
			return 0.74
		"spike_floor":
			return 0.88
		"treasure_pile_large":
			return 0.92
		"recovery_nest_f":
			return 0.78
		"weapon_rack":
			return 0.74
		"entrance_gate_f":
			return 0.68
		"throne_f":
			return 0.50
	return 0.82

func _object_texture_bottom_offset(slot_id: String, layer_name: String) -> float:
	match slot_id:
		"spike_floor", "foundation_marks":
			return 0.03
		"small_brazier":
			return -0.03
		"entrance_gate_f", "weapon_rack":
			return -0.06
		"throne_f":
			return 0.08
	return 0.04 if layer_name == "front" else -0.02

func _object_slot_rect(slot: Dictionary) -> Rect2:
	var instance_id := str(slot["instance_id"])
	var base_cell: Vector2i = slot["cell"]
	var module_footprint: Vector2i = slot["module_footprint"]
	var offsets: Array = slot.get("object_footprint", [[0, 0]])
	var min_cell := base_cell
	var max_cell := base_cell
	for value in offsets:
		if not value is Array:
			continue
		var offset := _array_to_cell(value)
		var cell := base_cell + offset
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	var top_left = _projected_local_cell_rect(instance_id, min_cell, module_footprint)
	var bottom_right = _projected_local_cell_rect(instance_id, max_cell, module_footprint)
	return top_left.merge(bottom_right)

func _draw_front_wall_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var mask := int(record["mask"])
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect)
		var cell: Vector2i = record["global_cell"]
		if (mask & int(AutoTileMaskScript.BITS["SE"])) == 0:
			if not _has_socket_edge(tile_grid, cell, "SE"):
				_draw_wall_riser(diamond[1], diamond[2], 12.0, Color("#0d0b12dd"))
		if (mask & int(AutoTileMaskScript.BITS["SW"])) == 0:
			if not _has_socket_edge(tile_grid, cell, "SW"):
				_draw_wall_riser(diamond[2], diamond[3], 12.0, Color("#0f0c14dd"))

func _draw_walkable_overlay(tile_grid: Dictionary) -> void:
	_draw_cell_set_overlay(tile_grid, tile_grid["walk_set"], Color("#4fc36b42"), Color("#9afaa777"))

func _draw_blocked_overlay(tile_grid: Dictionary) -> void:
	_draw_cell_set_overlay(tile_grid, tile_grid["blocked_set"], Color("#d4494948"), Color("#ff777799"))

func _draw_cell_set_overlay(tile_grid: Dictionary, cell_set: Dictionary, fill: Color, outline: Color) -> void:
	for record in tile_grid["cells"]:
		if not cell_set.has(record["global_cell"]):
			continue
		var diamond = _diamond(record["rect"].grow(2.0))
		root.draw_polygon(diamond, PackedColorArray([fill, fill, fill, fill]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), outline, 1.6)

func _draw_module_overlay(tile_grid: Dictionary) -> void:
	for instance_id in root.graph.module_instance_ids():
		var rect = root.graph.rect(str(instance_id))
		var color = _module_color(str(root.rooms.get(str(instance_id), {}).get("type", "")))
		var diamond = _diamond(rect.grow(5.0))
		root.draw_polygon(diamond, PackedColorArray([
			Color(color.r, color.g, color.b, 0.09),
			Color(color.r, color.g, color.b, 0.07),
			Color(color.r, color.g, color.b, 0.13),
			Color(color.r, color.g, color.b, 0.08)
		]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(color.r, color.g, color.b, 0.75), 2.0)

func _draw_floor_mask_overlay(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var rect: Rect2 = record["rect"]
		root.draw_string(UI_FONT, rect.get_center() + Vector2(-9, 4), str(record["mask"]), HORIZONTAL_ALIGNMENT_LEFT, 32, 12, Color("#fff6d6"))

func _draw_socket_overlay(tile_grid: Dictionary) -> void:
	for pair in root.graph.connection_pairs():
		var from_socket = _socket_record(tile_grid, str(pair.get("from_instance", "")), str(pair.get("from_socket", "")))
		var to_socket = _socket_record(tile_grid, str(pair.get("to_instance", "")), str(pair.get("to_socket", "")))
		if from_socket.is_empty() or to_socket.is_empty():
			continue
		var start = _socket_point(from_socket)
		var end = _socket_point(to_socket)
		root.draw_dashed_line(start, end, Color("#ffd36acc"), 2.0, 10.0)
		root.draw_circle(start, 5.0, Color("#fff0a4dd"))
		root.draw_circle(end, 5.0, Color("#80d6ffdd"))

func _draw_room_id_overlay(tile_grid: Dictionary) -> void:
	for instance_id in root.graph.module_instance_ids():
		var rect = root.graph.rect(str(instance_id))
		var module = root.graph.module_data_for_instance(str(instance_id))
		var label = "%s\n%s" % [str(instance_id), str(module.get("id", ""))]
		root.draw_string(UI_FONT, rect.position + Vector2(8, 20), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 12, Color("#f5ecd8cc"))

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

func _draw_missing_edge_tile(mask: int, side: String, rect: Rect2, start: Vector2, end: Vector2, has_socket: bool) -> void:
	if has_socket:
		return
	var bit := int(AutoTileMaskScript.BITS[side])
	if (mask & bit) != 0:
		return
	var texture = edge_tile_textures.get("%s_lip" % side.to_lower(), null)
	if texture is Texture2D:
		var draw_rect := rect.grow(4.0)
		match side:
			"NW":
				draw_rect.position += Vector2(-6, -3)
			"NE":
				draw_rect.position += Vector2(6, -3)
			"SE":
				draw_rect.position += Vector2(7, 5)
			"SW":
				draw_rect.position += Vector2(-7, 5)
		root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, 0.78))
		return
	_draw_missing_edge(mask, bit, start, end)

func _draw_outer_corner_if_open(tile_grid: Dictionary, mask: int, cell: Vector2i, side_a: String, side_b: String, texture_key: String, rect: Rect2) -> void:
	if _has_socket_edge(tile_grid, cell, side_a) or _has_socket_edge(tile_grid, cell, side_b):
		return
	if (mask & int(AutoTileMaskScript.BITS[side_a])) != 0:
		return
	if (mask & int(AutoTileMaskScript.BITS[side_b])) != 0:
		return
	_draw_corner_overlay(texture_key, rect, 0.50)

func _draw_inner_corner_if_open(tile_grid: Dictionary, cell: Vector2i, side_a: String, side_b: String, diagonal_offset: Vector2i, texture_key: String, rect: Rect2) -> void:
	if _has_socket_edge(tile_grid, cell, side_a) or _has_socket_edge(tile_grid, cell, side_b):
		return
	if not tile_grid["floor_set"].has(cell + AutoTileMaskScript.DIRS[side_a]):
		return
	if not tile_grid["floor_set"].has(cell + AutoTileMaskScript.DIRS[side_b]):
		return
	if tile_grid["floor_set"].has(cell + diagonal_offset):
		return
	_draw_corner_overlay(texture_key, rect, 0.46)

func _draw_corner_overlay(texture_key: String, rect: Rect2, alpha: float) -> void:
	var texture = corner_overlay_textures.get(texture_key, null)
	if not texture is Texture2D:
		return
	var draw_rect = _bottom_aligned_texture_rect(rect, texture, rect.size.x * 0.94, rect.end.y + 4.0)
	root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, alpha))

func _draw_wall_tile(side: String, rect: Rect2) -> bool:
	var texture = wall_tile_textures.get("%s_straight" % side.to_lower(), null)
	if not texture is Texture2D:
		return false
	var draw_rect = _bottom_aligned_texture_rect(rect, texture, rect.size.x * 0.82, rect.position.y + rect.size.y * 0.48)
	if side == "NW":
		draw_rect.position.x -= rect.size.x * 0.06
	elif side == "NE":
		draw_rect.position.x += rect.size.x * 0.06
	root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, 0.76))
	return true

func _draw_door_tile(side: String, point: Vector2, rect: Rect2) -> bool:
	var texture = door_tile_textures.get("%s_open" % side.to_lower(), null)
	if not texture is Texture2D:
		return false
	var width = rect.size.x * 0.82
	var height = width * float(texture.get_height()) / float(maxi(1, texture.get_width()))
	var draw_rect = Rect2(
		Vector2(point.x - width * 0.5, point.y - height + rect.size.y * 0.28),
		Vector2(width, height)
	)
	if side == "NW":
		draw_rect.position.x -= rect.size.x * 0.08
	elif side == "NE":
		draw_rect.position.x += rect.size.x * 0.08
	root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, 0.92))
	return true

func _bottom_aligned_texture_rect(rect: Rect2, texture: Texture2D, width: float, bottom_y: float) -> Rect2:
	var height = width * float(texture.get_height()) / float(maxi(1, texture.get_width()))
	return Rect2(
		Vector2(rect.get_center().x - width * 0.5, bottom_y - height),
		Vector2(width, height)
	)

func _draw_missing_edge(mask: int, bit: int, start: Vector2, end: Vector2) -> void:
	if (mask & bit) != 0:
		return
	root.draw_line(start, end, Color("#0a080ed9"), 2.0)
	root.draw_line(start + Vector2(0, 4), end + Vector2(0, 4), Color("#2a2035a8"), 2.0)

func _draw_wall_riser(start: Vector2, end: Vector2, height: float, color: Color) -> void:
	var top_start = start + Vector2(0, height)
	var top_end = end + Vector2(0, height)
	root.draw_polygon(PackedVector2Array([top_start, top_end, end, start]), PackedColorArray([color, color, color.darkened(0.14), color.darkened(0.14)]))

func _projected_local_cell_rect(instance_id: String, local_cell: Vector2i, footprint: Vector2i) -> Rect2:
	var rect = root.graph.rect(instance_id)
	var cell_width = rect.size.x / float(maxi(1, footprint.x))
	var cell_height = rect.size.y / float(maxi(1, footprint.y))
	return Rect2(
		rect.position + Vector2(float(local_cell.x) * cell_width, float(local_cell.y) * cell_height),
		Vector2(cell_width, cell_height)
	).grow(-2.0)

func _socket_point(socket_record: Dictionary) -> Vector2:
	var rect = _projected_local_cell_rect(str(socket_record["instance_id"]), socket_record["local_cell"], socket_record["footprint"])
	var center = rect.get_center()
	match str(socket_record["side"]):
		"NE":
			return Vector2(center.x + rect.size.x * 0.18, rect.position.y + rect.size.y * 0.08)
		"SW":
			return Vector2(center.x - rect.size.x * 0.18, rect.end.y - rect.size.y * 0.08)
		"NW":
			return Vector2(rect.position.x + rect.size.x * 0.08, center.y - rect.size.y * 0.18)
		"SE":
			return Vector2(rect.end.x - rect.size.x * 0.08, center.y + rect.size.y * 0.18)
	return center

func _socket_record(tile_grid: Dictionary, instance_id: String, socket_id: String) -> Dictionary:
	for socket in tile_grid["sockets"]:
		if str(socket["instance_id"]) == instance_id and str(socket["socket_id"]) == socket_id:
			return socket
	return {}

func _socket_edge_set(sockets: Array) -> Dictionary:
	var edges: Dictionary = {}
	for socket in sockets:
		var cell: Vector2i = socket.get("global_cell", Vector2i.ZERO)
		var side := str(socket.get("side", ""))
		if side == "":
			continue
		edges[_socket_edge_key(cell, side)] = true
	return edges

func _has_socket_edge(tile_grid: Dictionary, cell: Vector2i, side: String) -> bool:
	return tile_grid.get("socket_edge_set", {}).has(_socket_edge_key(cell, side))

func _socket_edge_key(cell: Vector2i, side: String) -> String:
	return "%d,%d:%s" % [cell.x, cell.y, side]

func _nearest_record(tile_grid: Dictionary, point: Vector2) -> Dictionary:
	var best_record: Dictionary = {}
	var best_distance = INF
	for record in tile_grid["cells"]:
		var distance = record["rect"].get_center().distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best_record = record
	return best_record

func _module_footprint(module: Dictionary) -> Vector2i:
	var value: Array = module.get("size", module.get("footprint", [1, 1]))
	if value.size() < 2:
		return Vector2i.ONE
	return Vector2i(maxi(1, int(value[0])), maxi(1, int(value[1])))

func _blocked_cell_values(module: Dictionary) -> Array:
	if module.has("blocked_cells"):
		return module.get("blocked_cells", [])
	return module.get("block_cells", [])

func _global_cell(placed: Dictionary, local_cell: Vector2i) -> Vector2i:
	return _array_to_cell(placed.get("grid_origin", [0, 0])) + local_cell

func _array_to_cell(value: Array) -> Vector2i:
	if value.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))

func _diamond(rect: Rect2) -> PackedVector2Array:
	var center = rect.get_center()
	return PackedVector2Array([
		Vector2(center.x, rect.position.y),
		Vector2(rect.end.x, center.y),
		Vector2(center.x, rect.end.y),
		Vector2(rect.position.x, center.y)
	])

func _connected_socket_sides(instance_id: String) -> Array:
	var sides: Array = []
	for pair in root.graph.connection_pairs():
		var side = ""
		if str(pair.get("from_instance", "")) == instance_id:
			side = _socket_side(instance_id, str(pair.get("from_socket", "")))
		elif str(pair.get("to_instance", "")) == instance_id:
			side = _socket_side(instance_id, str(pair.get("to_socket", "")))
		if side != "" and not sides.has(side):
			sides.append(side)
	sides.sort()
	return sides

func _socket_side(instance_id: String, socket_id: String) -> String:
	var socket = root.graph.socket_data(instance_id, socket_id)
	return str(socket.get("side", socket.get("dir", "")))

func _socket_variant_key(sides: Array) -> String:
	if sides.is_empty():
		return "closed"
	var parts = PackedStringArray()
	for side in sides:
		parts.append(str(side).to_lower())
	return "_".join(parts)

func _mouse_world_position() -> Vector2:
	var screen_point = root.get_viewport().get_mouse_position()
	if root.current_screen == Constants.SCREEN_COMBAT:
		return root._combat_screen_to_world(screen_point)
	return root.get_global_mouse_position()

func _module_color(room_type: String) -> Color:
	match room_type:
		"core":
			return Color("#e05a70")
		"trap":
			return Color("#b9b7c8")
		"recovery":
			return Color("#67c477")
		"bait":
			return Color("#e1b64e")
		"build_slot":
			return Color("#b26cff")
		"entry":
			return Color("#d69f65")
		_:
			return Color("#7ab6d6")
