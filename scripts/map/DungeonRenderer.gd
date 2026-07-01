extends RefCounted
class_name DungeonRenderer

const Constants = preload("res://scripts/core/Constants.gd")

var root: Node
var monster_preview_cache: Dictionary = {}

var map_bounds := Rect2(400, 96, 1080, 744)
var corridor_width := 96.0
var corridor_wall_width := 138.0
var tile_size := 64

func setup(game_root: Node) -> void:
	root = game_root

func draw() -> void:
	draw_background()
	draw_connections()
	draw_rooms()
	draw_roster_preview()

func draw_background() -> void:
	root.draw_rect(Rect2(Vector2.ZERO, Vector2(1920, 1080)), Color("#07080b"))
	root.draw_rect(map_bounds.grow(36), Color("#09090d"), true)
	root.draw_rect(map_bounds.grow(36), Color("#2b2532"), false, 3.0)
	_draw_back_wall(map_bounds.grow(12))
	_draw_map_grid()
	_draw_chasm_shadow()

func draw_connections() -> void:
	var drawn: Dictionary = {}
	for room_id in root.rooms.keys():
		for exit_id in root.graph.exits(room_id):
			var key = "%s-%s" % [room_id, exit_id]
			var reverse_key = "%s-%s" % [exit_id, room_id]
			if drawn.has(key) or drawn.has(reverse_key):
				continue
			drawn[key] = true
			_draw_corridor(root.graph.center(room_id), root.graph.center(exit_id))

func draw_rooms() -> void:
	for room_id in _draw_order():
		if not root.rooms.has(room_id):
			continue
		_draw_room(room_id)

func draw_room_tiles(rect: Rect2, room_type: String) -> void:
	_draw_tile_fill(rect, root.spike_texture if room_type == "trap" else root.floor_texture, Color("#2b2927"))

func draw_roster_preview() -> void:
	if root.current_screen == Constants.SCREEN_COMBAT:
		return
	var room_counts: Dictionary = {}
	for monster_id in root.monster_roster.keys():
		var roster: Dictionary = root.monster_roster[monster_id]
		var room_id: String = roster.get("room", "")
		if not root.rooms.has(room_id):
			continue
		var count = int(room_counts.get(room_id, 0))
		var center = root.graph.center(room_id)
		var preview_pos = center + _preview_offset(count)
		room_counts[room_id] = count + 1
		_draw_monster_preview(monster_id, preview_pos)

func _draw_back_wall(bounds: Rect2) -> void:
	var block_color = Color("#121417")
	for y in range(int(bounds.position.y), int(bounds.end.y), 54):
		for x in range(int(bounds.position.x), int(bounds.end.x), 96):
			var inset = 10 if int((x + y) / 54) % 2 == 0 else 0
			var block_rect = Rect2(Vector2(x + inset, y), Vector2(84, 40))
			root.draw_rect(block_rect, block_color, true)
			root.draw_rect(block_rect, Color("#202129"), false, 1.0)

func _draw_chasm_shadow() -> void:
	root.draw_polygon(
		PackedVector2Array([
			Vector2(400, 824),
			Vector2(1480, 824),
			Vector2(1425, 866),
			Vector2(452, 866)
		]),
		PackedColorArray([Color("#030405"), Color("#030405"), Color("#060509"), Color("#060509")])
	)

func _draw_map_grid() -> void:
	var grid_color = Color("#ffffff05")
	for x in range(int(map_bounds.position.x), int(map_bounds.end.x) + tile_size, tile_size):
		root.draw_line(Vector2(x, map_bounds.position.y), Vector2(x, map_bounds.end.y), grid_color, 1.0)
	for y in range(int(map_bounds.position.y), int(map_bounds.end.y) + tile_size, tile_size):
		root.draw_line(Vector2(map_bounds.position.x, y), Vector2(map_bounds.end.x, y), grid_color, 1.0)

func _draw_corridor(start: Vector2, end: Vector2) -> void:
	var pivot = _corridor_pivot(start, end)
	_draw_corridor_segment(start, pivot)
	_draw_corridor_segment(pivot, end)
	_draw_door_lintel(start, pivot)
	_draw_door_lintel(end, pivot)

func _draw_corridor_segment(from: Vector2, to: Vector2) -> void:
	if from.distance_to(to) < 1.0:
		return
	var rect = _corridor_rect(from, to)
	root.draw_rect(rect.grow((corridor_wall_width - corridor_width) * 0.5), Color("#14110f"), true)
	_draw_rock_edge(rect.grow(28.0), Color("#292624"), Color("#11100f"))
	_draw_tile_fill(rect, root.floor_texture, Color("#312d2a"))
	root.draw_rect(rect, Color("#15131366"), false, 3.0)
	_draw_floor_grid(rect, Color("#11111142"))

func _corridor_rect(from: Vector2, to: Vector2) -> Rect2:
	var half = corridor_width * 0.5
	if abs(from.x - to.x) >= abs(from.y - to.y):
		return Rect2(Vector2(min(from.x, to.x), from.y - half), Vector2(abs(from.x - to.x), corridor_width))
	return Rect2(Vector2(from.x - half, min(from.y, to.y)), Vector2(corridor_width, abs(from.y - to.y)))

func _draw_door_lintel(point: Vector2, toward: Vector2) -> void:
	var direction = (toward - point).normalized()
	if direction == Vector2.ZERO:
		return
	var side = Vector2(-direction.y, direction.x)
	var half_width = 42.0
	var depth = 12.0
	var p1 = point + side * half_width - direction * depth
	var p2 = point - side * half_width - direction * depth
	root.draw_line(p1, p2, Color("#7b684a"), 7.0, false)
	root.draw_line(p1 + direction * 10.0, p2 + direction * 10.0, Color("#201917"), 4.0, false)

func _corridor_pivot(start: Vector2, end: Vector2) -> Vector2:
	if abs(start.x - end.x) < 4.0 or abs(start.y - end.y) < 4.0:
		return end
	if abs(start.x - end.x) > abs(start.y - end.y):
		return Vector2(end.x, start.y)
	return Vector2(start.x, end.y)

func _draw_room(room_id: String) -> void:
	var room: Dictionary = root.rooms[room_id]
	var rect = root.graph.rect(room_id)
	var room_type = room.get("type", "")
	var wall_rect = rect.grow(22.0)
	var shadow_rect = rect.grow(30.0)
	root.draw_rect(shadow_rect, Color("#050505aa"), true)
	root.draw_rect(wall_rect, _wall_color(room_type), true)
	_draw_rock_edge(wall_rect, _wall_color(room_type), Color("#11100f"))
	_draw_wall_top(wall_rect)
	_draw_tile_fill(rect, root.spike_texture if room_type == "trap" else root.floor_texture, _floor_color(room_type))
	_draw_floor_grid(rect, Color("#0e0d0c55"))
	_draw_room_floor_detail(rect, room_type)
	root.draw_rect(rect, _floor_overlay(room_type), true)
	root.draw_rect(rect, Color("#101010"), false, 4.0)
	root.draw_rect(rect.grow(7.0), Color("#2b2523"), false, 3.0)
	if room_id == root.selected_room:
		root.draw_rect(rect.grow(13.0), Color("#b15dff"), false, 4.0)
		root.draw_rect(rect.grow(19.0), Color("#e0b4ff55"), false, 2.0)
	_draw_room_prop(room_id, room)
	_draw_room_lights(rect, room_type)
	_draw_room_label(room_id, room, rect)

func _draw_wall_top(wall_rect: Rect2) -> void:
	if root.wall_texture == null:
		return
	for x in range(int(wall_rect.position.x), int(wall_rect.end.x), tile_size):
		root.draw_texture_rect(root.wall_texture, Rect2(Vector2(x, wall_rect.position.y - 18), Vector2(tile_size, tile_size)), false)
		root.draw_texture_rect(root.wall_texture, Rect2(Vector2(x, wall_rect.end.y - 34), Vector2(tile_size, tile_size)), false, Color(0.55, 0.52, 0.58, 0.74))

func _draw_rock_edge(rect: Rect2, mid: Color, dark: Color) -> void:
	var step = 38
	for x in range(int(rect.position.x), int(rect.end.x), step):
		var wobble = float((x / step) % 3) * 4.0
		root.draw_rect(Rect2(Vector2(x, rect.position.y - wobble), Vector2(step + 10, 24 + wobble)), mid, true)
		root.draw_rect(Rect2(Vector2(x + 5, rect.end.y - 18), Vector2(step + 4, 26)), dark, true)
	for y in range(int(rect.position.y), int(rect.end.y), step):
		var wobble = float((y / step) % 3) * 5.0
		root.draw_rect(Rect2(Vector2(rect.position.x - 12, y), Vector2(26, step + wobble)), dark, true)
		root.draw_rect(Rect2(Vector2(rect.end.x - 14, y + 4), Vector2(28, step + wobble)), mid, true)

func _draw_room_floor_detail(rect: Rect2, room_type: String) -> void:
	var inner = rect.grow(-12.0)
	root.draw_rect(inner, Color("#ffffff08"), false, 1.0)
	if room_type == "trap":
		for x in range(int(rect.position.x + 42), int(rect.end.x - 28), 54):
			root.draw_line(Vector2(x, rect.position.y + 22), Vector2(x + 22, rect.end.y - 18), Color("#7d8088aa"), 3.0)
	elif room_type == "core":
		root.draw_arc(rect.get_center(), min(rect.size.x, rect.size.y) * 0.35, 0.0, TAU, 48, Color("#8f2d38aa"), 4.0)
	elif room_type == "recovery":
		root.draw_arc(rect.get_center(), min(rect.size.x, rect.size.y) * 0.32, 0.0, TAU, 48, Color("#4c8e5a99"), 3.0)
	elif room_type == "bait":
		root.draw_rect(Rect2(rect.position + Vector2(24, 28), rect.size - Vector2(48, 56)), Color("#9b74201c"), false, 3.0)
	elif room_type == "build_slot":
		root.draw_dashed_line(rect.position + Vector2(24, rect.size.y * 0.5), rect.end - Vector2(24, rect.size.y * 0.5), Color("#9f83c1"), 3.0, 10.0)
		root.draw_dashed_line(Vector2(rect.get_center().x, rect.position.y + 18), Vector2(rect.get_center().x, rect.end.y - 18), Color("#9f83c1"), 3.0, 10.0)

func _draw_floor_grid(rect: Rect2, color: Color) -> void:
	for x in range(int(rect.position.x), int(rect.end.x) + 1, tile_size):
		root.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), color, 1.0)
	for y in range(int(rect.position.y), int(rect.end.y) + 1, tile_size):
		root.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), color, 1.0)

func _draw_room_lights(rect: Rect2, room_type: String) -> void:
	var glow = Color("#9f4dff24")
	var flame = Color("#bf6eff")
	if room_type == "bait":
		glow = Color("#f2a64022")
		flame = Color("#e8a23b")
	elif room_type == "core":
		glow = Color("#b32cff30")
		flame = Color("#cf61ff")
	var points = [
		rect.position + Vector2(34, 36),
		Vector2(rect.end.x - 34, rect.position.y + 36)
	]
	for point in points:
		root.draw_circle(point, 42.0, glow)
		root.draw_circle(point, 9.0, Color("#241526"))
		root.draw_circle(point + Vector2(0, -5), 7.0, flame)

func _draw_room_prop(room_id: String, room: Dictionary) -> void:
	var texture: Texture2D = root.props.get(room.get("icon", ""))
	if texture == null:
		return
	var size = Vector2(86, 86)
	if room.get("type", "") == "core":
		size = Vector2(128, 128)
	elif room_id == "entrance":
		size = Vector2(120, 100)
	elif room.get("type", "") == "bait":
		size = Vector2(104, 90)
	var center = root.graph.center(room_id)
	root.draw_texture_rect(texture, Rect2(center - size * 0.5 + Vector2(0, -10), size), false, Color(1, 1, 1, 0.92))

func _draw_room_label(room_id: String, room: Dictionary, rect: Rect2) -> void:
	var font = ThemeDB.fallback_font
	var label_size = Vector2(150, 30)
	var label_pos = rect.position + Vector2((rect.size.x - label_size.x) * 0.5, -28)
	if label_pos.y < 84.0:
		label_pos.y = rect.position.y + 8.0
	var plaque = Rect2(label_pos, label_size)
	root.draw_rect(plaque, Color("#09090bee"), true)
	root.draw_rect(plaque, _accent_color(room.get("type", "")), false, 2.0)
	root.draw_string(font, label_pos + Vector2(10, 22), room.get("display_name", room_id), HORIZONTAL_ALIGNMENT_LEFT, label_size.x - 18.0, 18, Color("#f4ead5"))

func _draw_monster_preview(monster_id: String, position: Vector2) -> void:
	var monster = DataRegistry.monster(monster_id)
	var texture: Texture2D = _monster_texture(monster_id, monster.get("sprite", ""))
	var radius = 27.0
	root.draw_circle(position + Vector2(0, 18), radius, Color("#05050699"))
	if texture != null:
		root.draw_texture_rect(texture, Rect2(position - Vector2(36, 50), Vector2(72, 72)), false)
	root.draw_arc(position + Vector2(0, 2), 38.0, 0.0, TAU, 36, Color("#f0d375aa"), 2.0)
	var font = ThemeDB.fallback_font
	root.draw_string(font, position + Vector2(-46, 48), monster.get("display_name", monster_id), HORIZONTAL_ALIGNMENT_CENTER, 92.0, 15, Color("#fff3cd"))

func _monster_texture(monster_id: String, path: String) -> Texture2D:
	if monster_preview_cache.has(monster_id):
		return monster_preview_cache[monster_id]
	var texture: Texture2D = null
	if path != "":
		texture = root._load_png(path)
	monster_preview_cache[monster_id] = texture
	return texture

func _draw_tile_fill(rect: Rect2, texture: Texture2D, fallback: Color) -> void:
	root.draw_rect(rect, fallback, true)
	if texture == null:
		return
	var start_x = int(floor(rect.position.x / tile_size) * tile_size)
	var start_y = int(floor(rect.position.y / tile_size) * tile_size)
	for x in range(start_x, int(rect.end.x) + tile_size, tile_size):
		for y in range(start_y, int(rect.end.y) + tile_size, tile_size):
			var tile_rect = Rect2(Vector2(x, y), Vector2(tile_size, tile_size))
			if tile_rect.intersects(rect):
				var clipped = tile_rect.intersection(rect)
				var source = Rect2(clipped.position - tile_rect.position, clipped.size)
				root.draw_texture_rect_region(texture, clipped, source, Color(1, 1, 1, 0.92))

func _draw_order() -> Array:
	return ["entrance", "spike_corridor", "center", "barracks", "recovery", "slot_01", "treasure", "throne"]

func _preview_offset(index: int) -> Vector2:
	var offsets = [
		Vector2(-48, 14),
		Vector2(0, 2),
		Vector2(48, 14),
		Vector2(-24, -34),
		Vector2(32, -34)
	]
	return offsets[index % offsets.size()]

func _wall_color(room_type: String) -> Color:
	match room_type:
		"core":
			return Color("#3b2528")
		"trap":
			return Color("#343036")
		"recovery":
			return Color("#25362b")
		"bait":
			return Color("#3e311f")
		"build_slot":
			return Color("#2b2535")
		_:
			return Color("#2f2e2b")

func _floor_color(room_type: String) -> Color:
	match room_type:
		"core":
			return Color("#35282a")
		"trap":
			return Color("#29272a")
		"recovery":
			return Color("#26362d")
		"bait":
			return Color("#3a3123")
		"build_slot":
			return Color("#282637")
		_:
			return Color("#33302c")

func _floor_overlay(room_type: String) -> Color:
	match room_type:
		"core":
			return Color("#30101a33")
		"trap":
			return Color("#2b111633")
		"recovery":
			return Color("#0e2b1538")
		"bait":
			return Color("#5f431533")
		"build_slot":
			return Color("#1f143455")
		_:
			return Color("#14141422")

func _accent_color(room_type: String) -> Color:
	match room_type:
		"core":
			return Color("#bc4458")
		"trap":
			return Color("#b6b6c0")
		"recovery":
			return Color("#65b06f")
		"bait":
			return Color("#d5a642")
		"build_slot":
			return Color("#b15dff")
		"entry":
			return Color("#9d7f55")
		_:
			return Color("#786a5e")
