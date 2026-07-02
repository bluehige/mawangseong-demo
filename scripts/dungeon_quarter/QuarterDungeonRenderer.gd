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

func setup(game_root: Node) -> void:
	root = game_root

func draw() -> void:
	if root == null or root.graph == null or not root.use_quarter_module_map:
		return
	var tile_grid = _build_tile_grid()
	_draw_background()
	_draw_floor_layer(tile_grid)
	_draw_edge_layer(tile_grid)
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
				"footprint": footprint
			})
		for socket in module.get("sockets", []):
			sockets.append({
				"instance_id": str(instance_id),
				"socket_id": str(socket.get("id", "")),
				"side": str(socket.get("side", socket.get("dir", ""))),
				"local_cell": _array_to_cell(socket.get("cell", socket.get("local_cell", [0, 0]))),
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

func _draw_edge_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect)
		var mask := int(record["mask"])
		_draw_missing_edge(mask, AutoTileMaskScript.BITS["NW"], diamond[0], diamond[3])
		_draw_missing_edge(mask, AutoTileMaskScript.BITS["NE"], diamond[0], diamond[1])
		_draw_missing_edge(mask, AutoTileMaskScript.BITS["SE"], diamond[1], diamond[2])
		_draw_missing_edge(mask, AutoTileMaskScript.BITS["SW"], diamond[2], diamond[3])

func _draw_back_wall_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var mask := int(record["mask"])
		var diamond = _diamond(record["rect"])
		if (mask & int(AutoTileMaskScript.BITS["NE"])) == 0:
			_draw_wall_riser(diamond[0], diamond[1], -10.0, Color("#1c1822d9"))
		if (mask & int(AutoTileMaskScript.BITS["NW"])) == 0:
			_draw_wall_riser(diamond[0], diamond[3], -10.0, Color("#18151ed9"))

func _draw_door_back_layer(tile_grid: Dictionary) -> void:
	for socket in tile_grid["sockets"]:
		var side = str(socket["side"])
		if not ["NE", "NW"].has(side):
			continue
		var point = _socket_point(socket)
		root.draw_circle(point + Vector2(0, -8), 8.0, Color("#5d466acc"))
		root.draw_arc(point + Vector2(0, -8), 12.0, PI, TAU, 16, Color("#b994ff99"), 2.0)

func _draw_object_layer(tile_grid: Dictionary, layer_name: String) -> void:
	for slot in tile_grid["object_slots"]:
		if str(slot["layer"]) != layer_name:
			continue
		var rect = _projected_local_cell_rect(str(slot["instance_id"]), slot["cell"], slot["footprint"])
		var center = rect.get_center()
		var color = Color("#806bb8cc") if layer_name == "back" else Color("#c39a54cc")
		root.draw_circle(center + Vector2(0, -rect.size.y * 0.18), max(5.0, min(rect.size.x, rect.size.y) * 0.16), color)
		if root.debug_show_room_id_overlay:
			root.draw_string(UI_FONT, center + Vector2(-44, -rect.size.y * 0.34), str(slot["id"]), HORIZONTAL_ALIGNMENT_CENTER, 88, 10, Color("#fff2d7bb"))

func _draw_front_wall_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var mask := int(record["mask"])
		var diamond = _diamond(record["rect"])
		if (mask & int(AutoTileMaskScript.BITS["SE"])) == 0:
			_draw_wall_riser(diamond[1], diamond[2], 12.0, Color("#0d0b12dd"))
		if (mask & int(AutoTileMaskScript.BITS["SW"])) == 0:
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
