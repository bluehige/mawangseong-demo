extends RefCounted
class_name DungeonRenderer

const Constants = preload("res://scripts/core/Constants.gd")

var root: Node
var monster_preview_cache: Dictionary = {}

var tile_size := 64
var grid_origin := Vector2(420, 112)
var grid_columns := 17
var grid_rows := 12
var map_bounds := Rect2(grid_origin, Vector2(grid_columns * tile_size, grid_rows * tile_size))

func setup(game_root: Node) -> void:
	root = game_root

func draw() -> void:
	var layout = _build_layout()
	draw_background()
	_draw_wall_cells(layout["floor"])
	_draw_floor_cells(layout)
	_draw_room_details()
	_draw_room_props()
	_draw_room_labels()
	draw_roster_preview()

func draw_background() -> void:
	root.draw_rect(Rect2(Vector2.ZERO, Vector2(1920, 1080)), Color("#050507"))
	root.draw_rect(map_bounds.grow(42), Color("#07080b"), true)
	root.draw_rect(map_bounds.grow(42), Color("#211c25"), false, 3.0)
	_draw_cave_backdrop(map_bounds.grow(70))
	_draw_chasm_shadow()

func draw_connections() -> void:
	var layout = _build_layout()
	_draw_floor_cells(layout)

func draw_rooms() -> void:
	_draw_room_details()
	_draw_room_props()
	_draw_room_labels()

func draw_room_tiles(rect: Rect2, room_type: String) -> void:
	_draw_tile_rect(rect, root.spike_texture if room_type == "trap" else root.floor_texture, Color("#302d2b"))

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
		var preview_pos = root.graph.center(room_id) + _preview_offset(count)
		room_counts[room_id] = count + 1
		_draw_monster_preview(monster_id, preview_pos)

func _build_layout() -> Dictionary:
	var floor_cells: Dictionary = {}
	var corridor_cells: Dictionary = {}
	var room_cells: Dictionary = {}
	for room_id in root.rooms.keys():
		_add_room_cells(room_id, floor_cells, room_cells)

	var drawn: Dictionary = {}
	for room_id in root.rooms.keys():
		for exit_id in root.graph.exits(room_id):
			var key = "%s-%s" % [room_id, exit_id]
			var reverse_key = "%s-%s" % [exit_id, room_id]
			if drawn.has(key) or drawn.has(reverse_key):
				continue
			drawn[key] = true
			_add_corridor_cells(room_id, exit_id, floor_cells, corridor_cells)
	return {
		"floor": floor_cells,
		"corridor": corridor_cells,
		"room": room_cells
	}

func _add_room_cells(room_id: String, floor_cells: Dictionary, room_cells: Dictionary) -> void:
	var room: Dictionary = root.rooms[room_id]
	var position = room.get("grid_position", [0, 0])
	var size = room.get("grid_size", [1, 1])
	for x in range(int(position[0]), int(position[0]) + int(size[0])):
		for y in range(int(position[1]), int(position[1]) + int(size[1])):
			var cell = Vector2i(x, y)
			_add_cell(floor_cells, cell)
			room_cells[_cell_key(cell)] = room_id

func _add_corridor_cells(room_id: String, exit_id: String, floor_cells: Dictionary, corridor_cells: Dictionary) -> void:
	var start = _room_center_cell(room_id)
	var end = _room_center_cell(exit_id)
	var pivot = _corridor_pivot_cell(start, end)
	_add_corridor_line(start, pivot, floor_cells, corridor_cells)
	_add_corridor_line(pivot, end, floor_cells, corridor_cells)

func _add_corridor_line(start: Vector2i, end: Vector2i, floor_cells: Dictionary, corridor_cells: Dictionary) -> void:
	if start == end:
		_add_corridor_brush(start, true, floor_cells, corridor_cells)
		return
	if start.y == end.y:
		var min_x = min(start.x, end.x)
		var max_x = max(start.x, end.x)
		for x in range(min_x, max_x + 1):
			_add_corridor_brush(Vector2i(x, start.y), true, floor_cells, corridor_cells)
	else:
		var min_y = min(start.y, end.y)
		var max_y = max(start.y, end.y)
		for y in range(min_y, max_y + 1):
			_add_corridor_brush(Vector2i(start.x, y), false, floor_cells, corridor_cells)

func _add_corridor_brush(cell: Vector2i, horizontal: bool, floor_cells: Dictionary, corridor_cells: Dictionary) -> void:
	var offsets = [Vector2i.ZERO]
	if horizontal:
		offsets.append(Vector2i(0, -1))
	else:
		offsets.append(Vector2i(1, 0))
	for offset in offsets:
		var brush_cell = cell + offset
		_add_cell(floor_cells, brush_cell)
		_add_cell(corridor_cells, brush_cell)

func _room_center_cell(room_id: String) -> Vector2i:
	var room: Dictionary = root.rooms[room_id]
	var position = room.get("grid_position", [0, 0])
	var size = room.get("grid_size", [1, 1])
	return Vector2i(int(position[0]) + int(size[0]) / 2, int(position[1]) + int(size[1]) / 2)

func _corridor_pivot_cell(start: Vector2i, end: Vector2i) -> Vector2i:
	if start.x == end.x or start.y == end.y:
		return end
	if abs(start.x - end.x) >= abs(start.y - end.y):
		return Vector2i(end.x, start.y)
	return Vector2i(start.x, end.y)

func _add_cell(cells: Dictionary, cell: Vector2i) -> void:
	if cell.x < 0 or cell.y < 0 or cell.x >= grid_columns or cell.y >= grid_rows:
		return
	cells[_cell_key(cell)] = cell

func _draw_wall_cells(floor_cells: Dictionary) -> void:
	var wall_cells: Dictionary = {}
	var directions = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	for key in floor_cells.keys():
		var cell: Vector2i = floor_cells[key]
		for direction in directions:
			var neighbor = cell + direction
			if neighbor.x < -1 or neighbor.y < -1 or neighbor.x > grid_columns or neighbor.y > grid_rows:
				continue
			if floor_cells.has(_cell_key(neighbor)):
				continue
			wall_cells[_cell_key(neighbor)] = neighbor

	for key in wall_cells.keys():
		var cell: Vector2i = wall_cells[key]
		var rect = _cell_rect(cell)
		root.draw_rect(rect, Color("#111013"), true)
		if root.wall_texture != null:
			root.draw_texture_rect(root.wall_texture, rect, false, Color(0.62, 0.58, 0.68, 0.86))
		root.draw_rect(rect, Color("#03030477"), false, 2.0)

func _draw_floor_cells(layout: Dictionary) -> void:
	var floor_cells: Dictionary = layout["floor"]
	var corridor_cells: Dictionary = layout["corridor"]
	var room_cells: Dictionary = layout["room"]
	for key in floor_cells.keys():
		var cell: Vector2i = floor_cells[key]
		var room_id = str(room_cells.get(key, ""))
		var room_type = root.rooms.get(room_id, {}).get("type", "")
		var texture = root.spike_texture if room_type == "trap" else root.floor_texture
		var rect = _cell_rect(cell)
		_draw_tile_rect(rect, texture, _floor_color(room_type))
		if corridor_cells.has(key) and room_id == "":
			root.draw_rect(rect, Color("#0e0b0b22"), true)
		root.draw_rect(rect, Color("#0b0a0b66"), false, 1.0)

	_draw_floor_edges(floor_cells)
	_draw_path_markers(layout)

func _draw_floor_edges(floor_cells: Dictionary) -> void:
	for key in floor_cells.keys():
		var cell: Vector2i = floor_cells[key]
		var rect = _cell_rect(cell)
		if not floor_cells.has(_cell_key(cell + Vector2i(0, -1))):
			root.draw_line(rect.position, rect.position + Vector2(tile_size, 0), Color("#393238"), 5.0)
		if not floor_cells.has(_cell_key(cell + Vector2i(0, 1))):
			root.draw_line(rect.position + Vector2(0, tile_size), rect.end, Color("#0a090a"), 6.0)
		if not floor_cells.has(_cell_key(cell + Vector2i(-1, 0))):
			root.draw_line(rect.position, rect.position + Vector2(0, tile_size), Color("#1b181b"), 5.0)
		if not floor_cells.has(_cell_key(cell + Vector2i(1, 0))):
			root.draw_line(rect.position + Vector2(tile_size, 0), rect.end, Color("#1b181b"), 5.0)

func _draw_path_markers(layout: Dictionary) -> void:
	var main_route = ["entrance", "spike_corridor", "center", "throne"]
	for index in range(main_route.size() - 1):
		_draw_path_dots(root.graph.center(main_route[index]), root.graph.center(main_route[index + 1]), Color("#8f4df077"))
	_draw_path_dots(root.graph.center("center"), root.graph.center("barracks"), Color("#c89a4070"))
	_draw_path_dots(root.graph.center("center"), root.graph.center("recovery"), Color("#56a96f70"))
	_draw_path_dots(root.graph.center("slot_01"), root.graph.center("treasure"), Color("#d1a33e70"))

func _draw_path_dots(start: Vector2, end: Vector2, color: Color) -> void:
	var distance = start.distance_to(end)
	if distance < 1.0:
		return
	var direction = (end - start).normalized()
	var steps = int(distance / 34.0)
	for step in range(1, steps):
		var point = start + direction * float(step) * 34.0
		root.draw_circle(point, 4.0, color)

func _draw_room_details() -> void:
	for room_id in _draw_order():
		if not root.rooms.has(room_id):
			continue
		var room: Dictionary = root.rooms[room_id]
		var rect = root.graph.rect(room_id)
		var room_type = room.get("type", "")
		root.draw_rect(rect, _room_overlay(room_type), true)
		if room_type == "trap":
			_draw_spike_room_detail(rect)
		elif room_type == "core":
			root.draw_arc(rect.get_center(), min(rect.size.x, rect.size.y) * 0.38, 0.0, TAU, 54, Color("#9b3147aa"), 4.0)
		elif room_type == "recovery":
			root.draw_arc(rect.get_center(), min(rect.size.x, rect.size.y) * 0.34, 0.0, TAU, 54, Color("#57a667aa"), 4.0)
		elif room_type == "build_slot":
			_draw_build_slot_detail(rect)
		if room_id == root.selected_room:
			root.draw_rect(rect.grow(9.0), Color("#b15dff"), false, 4.0)
			root.draw_rect(rect.grow(15.0), Color("#e0b4ff55"), false, 2.0)
		_draw_room_lights(rect, room_type)

func _draw_spike_room_detail(rect: Rect2) -> void:
	for x in range(int(rect.position.x + 36), int(rect.end.x - 24), 42):
		root.draw_line(Vector2(x, rect.position.y + 26), Vector2(x + 20, rect.end.y - 24), Color("#9c9aabaa"), 3.0)

func _draw_build_slot_detail(rect: Rect2) -> void:
	root.draw_rect(rect.grow(-16.0), Color("#21122c66"), false, 3.0)
	root.draw_dashed_line(Vector2(rect.get_center().x, rect.position.y + 22), Vector2(rect.get_center().x, rect.end.y - 22), Color("#b15dff"), 3.0, 10.0)
	root.draw_dashed_line(Vector2(rect.position.x + 22, rect.get_center().y), Vector2(rect.end.x - 22, rect.get_center().y), Color("#b15dff"), 3.0, 10.0)

func _draw_room_props() -> void:
	for room_id in _draw_order():
		if not root.rooms.has(room_id):
			continue
		var room: Dictionary = root.rooms[room_id]
		var texture: Texture2D = root.props.get(room.get("icon", ""))
		if texture == null:
			continue
		var size = Vector2(86, 86)
		if room.get("type", "") == "core":
			size = Vector2(132, 132)
		elif room_id == "entrance":
			size = Vector2(118, 98)
		elif room.get("type", "") == "bait":
			size = Vector2(108, 94)
		var center = root.graph.center(room_id)
		root.draw_texture_rect(texture, Rect2(center - size * 0.5 + Vector2(0, -8), size), false, Color(1, 1, 1, 0.94))

func _draw_room_labels() -> void:
	for room_id in _draw_order():
		if not root.rooms.has(room_id):
			continue
		var room: Dictionary = root.rooms[room_id]
		var rect = root.graph.rect(room_id)
		var font = ThemeDB.fallback_font
		var label_size = Vector2(150, 30)
		var label_pos = rect.position + Vector2((rect.size.x - label_size.x) * 0.5, -28)
		if label_pos.y < 84.0:
			label_pos.y = rect.position.y + 8.0
		var plaque = Rect2(label_pos, label_size)
		root.draw_rect(plaque, Color("#09090bee"), true)
		root.draw_rect(plaque, _accent_color(room.get("type", "")), false, 2.0)
		root.draw_string(font, label_pos + Vector2(10, 22), room.get("display_name", room_id), HORIZONTAL_ALIGNMENT_LEFT, label_size.x - 18.0, 18, Color("#f4ead5"))

func _draw_room_lights(rect: Rect2, room_type: String) -> void:
	var glow = Color("#9f4dff22")
	var flame = Color("#bf6eff")
	if room_type == "bait":
		glow = Color("#f2a64022")
		flame = Color("#e8a23b")
	elif room_type == "core":
		glow = Color("#b32cff30")
		flame = Color("#cf61ff")
	for point in [rect.position + Vector2(34, 36), Vector2(rect.end.x - 34, rect.position.y + 36)]:
		root.draw_circle(point, 42.0, glow)
		root.draw_circle(point, 9.0, Color("#241526"))
		root.draw_circle(point + Vector2(0, -5), 7.0, flame)

func _draw_monster_preview(monster_id: String, position: Vector2) -> void:
	var monster = DataRegistry.monster(monster_id)
	var texture: Texture2D = _monster_texture(monster_id, monster.get("sprite", ""))
	root.draw_circle(position + Vector2(0, 18), 27.0, Color("#05050699"))
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

func _draw_cave_backdrop(bounds: Rect2) -> void:
	var colors = [Color("#111116"), Color("#15131a"), Color("#0c0d10")]
	var index = 0
	for y in range(int(bounds.position.y), int(bounds.end.y), 72):
		for x in range(int(bounds.position.x), int(bounds.end.x), 96):
			var block_rect = Rect2(Vector2(x + (index % 2) * 10, y), Vector2(84, 46))
			root.draw_rect(block_rect, colors[index % colors.size()], true)
			root.draw_rect(block_rect, Color("#22202a"), false, 1.0)
			index += 1

func _draw_chasm_shadow() -> void:
	root.draw_polygon(
		PackedVector2Array([
			Vector2(map_bounds.position.x - 24, map_bounds.end.y - 20),
			Vector2(map_bounds.end.x + 24, map_bounds.end.y - 20),
			Vector2(map_bounds.end.x - 42, map_bounds.end.y + 26),
			Vector2(map_bounds.position.x + 48, map_bounds.end.y + 26)
		]),
		PackedColorArray([Color("#030405"), Color("#030405"), Color("#060509"), Color("#060509")])
	)

func _draw_tile_rect(rect: Rect2, texture: Texture2D, fallback: Color) -> void:
	root.draw_rect(rect, fallback, true)
	if texture != null:
		root.draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.93))

func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(grid_origin + Vector2(cell.x * tile_size, cell.y * tile_size), Vector2(tile_size, tile_size))

func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]

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

func _floor_color(room_type: String) -> Color:
	match room_type:
		"core":
			return Color("#30262a")
		"trap":
			return Color("#27272c")
		"recovery":
			return Color("#26362d")
		"bait":
			return Color("#3a3123")
		"build_slot":
			return Color("#282637")
		_:
			return Color("#302d2b")

func _room_overlay(room_type: String) -> Color:
	match room_type:
		"core":
			return Color("#39101d25")
		"trap":
			return Color("#2f101a2a")
		"recovery":
			return Color("#0e2b1530")
		"bait":
			return Color("#5f431530")
		"build_slot":
			return Color("#2312384f")
		"entry":
			return Color("#5a43201c")
		_:
			return Color("#16121712")

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
