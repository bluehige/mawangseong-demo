extends RefCounted
class_name QuarterDungeonRenderer

const Constants = preload("res://scripts/core/Constants.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")
const MODULE_VISUAL_PATH = "res://assets/sprites/dungeon_quarter/modules/%s_visual.png"
const MODULE_VISUAL_MIN_WIDTH = 230.0
const MODULE_VISUAL_SCALE = 1.34
const MODULE_VISUAL_ASPECT = 1.5
const SOCKET_SIDE_ORDER = ["NE", "NW", "SE", "SW"]

var root: Node
var module_visuals: Dictionary = {}

func setup(game_root: Node) -> void:
	root = game_root
	_load_module_visuals()

func draw() -> void:
	if root == null or root.graph == null or not root.use_quarter_module_map:
		return
	_draw_module_visuals()
	if root.debug_show_blocked_overlay:
		_draw_cell_overlay(root.graph.debug_blocked_rects(), Color("#d4494930"), Color("#ff777766"), 1.0)
	if root.debug_show_walkable_overlay:
		_draw_cell_overlay(root.graph.debug_walkable_rects(), Color("#4fc36b38"), Color("#8df09a66"), 1.0)
	if root.debug_show_quarter_module_overlay:
		_draw_module_overlay()
	if root.debug_show_socket_overlay:
		_draw_socket_overlay()
	if root.debug_show_cursor_cell:
		_draw_cursor_cell()

func has_module_visuals() -> bool:
	return not module_visuals.is_empty()

func debug_loaded_visual_count() -> int:
	return module_visuals.size()

func debug_visual_variant_key(instance_id: String) -> String:
	return _socket_variant_key(_connected_socket_sides(instance_id))

func _load_module_visuals() -> void:
	module_visuals.clear()
	if root == null or root.graph == null:
		return
	for instance_id in root.graph.module_instance_ids():
		var placed = root.graph.placed_module_data(str(instance_id))
		var module_id = str(placed.get("module_id", ""))
		if module_id == "" or module_visuals.has(module_id):
			continue
		var texture = root._load_png(MODULE_VISUAL_PATH % module_id)
		if texture != null:
			module_visuals[module_id] = texture

func _draw_module_visuals() -> void:
	for instance_id in _module_draw_order():
		var placed = root.graph.placed_module_data(str(instance_id))
		var module_id = str(placed.get("module_id", ""))
		var texture = _module_visual_texture(str(instance_id), module_id)
		if texture == null:
			continue
		var draw_rect = _module_visual_rect(str(instance_id), texture)
		root.draw_circle(draw_rect.get_center() + Vector2(0, draw_rect.size.y * 0.31), draw_rect.size.x * 0.38, Color("#0202048c"))
		root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, 0.98))

func _module_visual_texture(instance_id: String, module_id: String) -> Texture2D:
	if module_id == "":
		return null
	var variant_key = _socket_variant_key(_connected_socket_sides(instance_id))
	var cache_key = "%s:%s" % [module_id, variant_key]
	if module_visuals.has(cache_key):
		return module_visuals[cache_key]
	var variant_path = "res://assets/sprites/dungeon_quarter/modules/%s_visual_%s.png" % [module_id, variant_key]
	if ResourceLoader.exists(variant_path):
		var variant_texture = root._load_png(variant_path)
		if variant_texture != null:
			module_visuals[cache_key] = variant_texture
			return variant_texture
	return module_visuals.get(module_id, null)

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
	sides.sort_custom(func(a, b) -> bool:
		return SOCKET_SIDE_ORDER.find(str(a)) < SOCKET_SIDE_ORDER.find(str(b))
	)
	return sides

func _socket_side(instance_id: String, socket_id: String) -> String:
	var socket = root.graph.socket_data(instance_id, socket_id)
	return str(socket.get("side", ""))

func _socket_variant_key(sides: Array) -> String:
	if sides.is_empty():
		return "closed"
	var parts = PackedStringArray()
	for side in sides:
		parts.append(str(side).to_lower())
	return "_".join(parts)

func _module_visual_rect(instance_id: String, texture: Texture2D) -> Rect2:
	var rect = root.graph.rect(instance_id)
	if rect.size == Vector2.ZERO:
		return Rect2()
	var aspect = MODULE_VISUAL_ASPECT
	if texture.get_height() > 0:
		aspect = float(texture.get_width()) / float(texture.get_height())
	var width = max(MODULE_VISUAL_MIN_WIDTH, rect.size.x * MODULE_VISUAL_SCALE, rect.size.y * aspect)
	var height = width / aspect
	var min_height = rect.size.y * 1.14
	if height < min_height:
		height = min_height
		width = height * aspect
	var size = Vector2(width, height)
	return Rect2(rect.get_center() - size * 0.5, size)

func _draw_module_overlay() -> void:
	for instance_id in _module_draw_order():
		var rect = root.graph.rect(instance_id)
		if rect.size == Vector2.ZERO:
			continue
		var room = root.rooms.get(instance_id, {})
		var color = _module_color(str(room.get("type", "")))
		var diamond = _diamond(rect.grow(5.0))
		root.draw_polygon(diamond, PackedColorArray([
			Color(color.r, color.g, color.b, 0.12),
			Color(color.r, color.g, color.b, 0.08),
			Color(color.r, color.g, color.b, 0.16),
			Color(color.r, color.g, color.b, 0.10)
		]))
		_draw_polyline(diamond, Color(color.r, color.g, color.b, 0.88), 2.0)
		_draw_module_axis(rect, color)
		if root.current_screen != Constants.SCREEN_COMBAT:
			var label = str(root.graph.module_data_for_instance(instance_id).get("module_type", "module"))
			root.draw_string(UI_FONT, rect.position + Vector2(10, 18), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, 13, Color("#f5ecd8cc"))

func _draw_socket_overlay() -> void:
	for pair in root.graph.connection_pairs():
		var from_instance = str(pair.get("from_instance", ""))
		var to_instance = str(pair.get("to_instance", ""))
		var from_socket = root.graph.socket_data(from_instance, str(pair.get("from_socket", "")))
		var to_socket = root.graph.socket_data(to_instance, str(pair.get("to_socket", "")))
		if from_socket.is_empty() or to_socket.is_empty():
			continue
		var start = _socket_point(from_instance, from_socket)
		var end = _socket_point(to_instance, to_socket)
		root.draw_dashed_line(start, end, Color("#ffd36acc"), 2.0, 10.0)
		root.draw_circle(start, 5.0, Color("#fff0a4dd"))
		root.draw_circle(end, 5.0, Color("#80d6ffdd"))

func _draw_cell_overlay(rects: Array, fill: Color, outline: Color, width: float) -> void:
	for rect in rects:
		root.draw_rect(rect, fill, true)
		root.draw_rect(rect, outline, false, width)

func _draw_cursor_cell() -> void:
	if not root.graph.has_method("debug_world_cell"):
		return
	var world_position = _mouse_world_position()
	var cell = root.graph.debug_world_cell(world_position)
	var rect = root.graph.debug_cell_rect(cell)
	var walkable = root.graph.debug_cell_walkable(cell)
	var color = Color("#7cf58f") if walkable else Color("#ff6b6b")
	root.draw_rect(rect.grow(2.0), Color(color.r, color.g, color.b, 0.28), true)
	root.draw_rect(rect.grow(2.0), Color(color.r, color.g, color.b, 0.94), false, 2.0)
	root.draw_string(UI_FONT, rect.position + Vector2(0, -6), "%d,%d" % [cell.x, cell.y], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, Color("#fff6d6"))

func _module_draw_order() -> Array:
	var ids = root.graph.module_instance_ids()
	ids.sort_custom(func(a, b) -> bool:
		var ca = root.graph.center(str(a))
		var cb = root.graph.center(str(b))
		if ca.y == cb.y:
			return ca.x < cb.x
		return ca.y < cb.y
	)
	return ids

func _diamond(rect: Rect2) -> PackedVector2Array:
	var center = rect.get_center()
	return PackedVector2Array([
		Vector2(center.x, rect.position.y),
		Vector2(rect.end.x, center.y),
		Vector2(center.x, rect.end.y),
		Vector2(rect.position.x, center.y)
	])

func _draw_polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	for index in range(points.size()):
		root.draw_line(points[index], points[(index + 1) % points.size()], color, width)

func _draw_module_axis(rect: Rect2, color: Color) -> void:
	var center = rect.get_center()
	root.draw_line(Vector2(center.x, rect.position.y), Vector2(center.x, rect.end.y), Color(color.r, color.g, color.b, 0.34), 1.0)
	root.draw_line(Vector2(rect.position.x, center.y), Vector2(rect.end.x, center.y), Color(color.r, color.g, color.b, 0.34), 1.0)

func _socket_point(instance_id: String, socket: Dictionary) -> Vector2:
	var rect = root.graph.rect(instance_id)
	var center = rect.get_center()
	match str(socket.get("side", "")):
		"NE":
			return Vector2(center.x + rect.size.x * 0.18, rect.position.y + rect.size.y * 0.08)
		"SW":
			return Vector2(center.x - rect.size.x * 0.18, rect.end.y - rect.size.y * 0.08)
		"NW":
			return Vector2(rect.position.x + rect.size.x * 0.08, center.y - rect.size.y * 0.18)
		"SE":
			return Vector2(rect.end.x - rect.size.x * 0.08, center.y + rect.size.y * 0.18)
	return center

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
