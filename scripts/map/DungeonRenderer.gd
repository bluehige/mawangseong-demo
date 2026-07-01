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
var connected_map_rect := Rect2(Vector2(332, 84), Vector2(1194, 796))
var wall_height := 54
var side_wall_width := 22

func setup(game_root: Node) -> void:
	root = game_root

func draw() -> void:
	var layout = _build_layout()
	var floor_cells: Dictionary = layout["floor"]
	draw_background()
	if _has_connected_map():
		_draw_connected_map()
		_draw_room_interaction_overlays()
		_draw_room_props()
		_draw_room_labels()
		draw_roster_preview()
		return
	_draw_wall_cells(floor_cells)
	_draw_back_wall_faces(floor_cells)
	_draw_floor_cells(layout)
	_draw_room_details()
	_draw_side_wall_faces(floor_cells)
	_draw_front_wall_faces(floor_cells)
	_draw_doorways()
	_draw_room_props()
	_draw_room_labels()
	draw_roster_preview()

func draw_background() -> void:
	root.draw_rect(Rect2(Vector2.ZERO, Vector2(1920, 1080)), Color("#050507"))
	root.draw_rect(map_bounds.grow(48), Color("#050609"), true)
	root.draw_rect(map_bounds.grow(48), Color("#17131b"), false, 3.0)
	_draw_cave_backdrop(map_bounds.grow(70))
	_draw_chasm_shadow()

func draw_connections() -> void:
	if _has_connected_map():
		_draw_connected_map()
		return
	var layout = _build_layout()
	_draw_floor_cells(layout)

func draw_rooms() -> void:
	if _has_connected_map():
		_draw_room_interaction_overlays()
		_draw_room_props()
		_draw_room_labels()
		return
	_draw_room_details()
	_draw_room_props()
	_draw_room_labels()

func draw_room_tiles(rect: Rect2, room_type: String) -> void:
	_draw_tile_rect(rect, root.spike_texture if room_type == "trap" else root.floor_texture, Color("#302d2b"))

func _dungeon_art(name: String):
	return root.dungeon_art.get(name, null)

func _has_connected_map() -> bool:
	return _dungeon_art("connected_map") != null

func _draw_connected_map() -> void:
	var texture = _dungeon_art("connected_map")
	if texture == null:
		return
	root.draw_texture_rect(texture, connected_map_rect, false, Color(1, 1, 1, 0.96))
	root.draw_rect(connected_map_rect, Color("#05040855"), false, 2.0)

func _draw_dungeon_art(name: String, rect: Rect2, modulate: Color = Color.WHITE) -> bool:
	var texture = _dungeon_art(name)
	if texture == null:
		return false
	root.draw_texture_rect(texture, rect, false, modulate)
	return true

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
		_draw_wall_cell(cell, floor_cells)

func _draw_wall_cell(cell: Vector2i, floor_cells: Dictionary) -> void:
	var rect = _cell_rect(cell)
	var has_floor_below = floor_cells.has(_cell_key(cell + Vector2i(0, 1)))
	var has_floor_above = floor_cells.has(_cell_key(cell + Vector2i(0, -1)))
	var has_floor_left = floor_cells.has(_cell_key(cell + Vector2i(-1, 0)))
	var has_floor_right = floor_cells.has(_cell_key(cell + Vector2i(1, 0)))

	root.draw_rect(rect, Color("#07060a"), true)
	if not _draw_dungeon_art("floor_rough", rect, Color(0.42, 0.38, 0.50, 0.52)) and root.wall_texture != null:
		root.draw_texture_rect(root.wall_texture, rect, false, Color(0.42, 0.38, 0.50, 0.42))

	var seed = abs(cell.x * 37 + cell.y * 53)
	var rock = PackedVector2Array([
		rect.position + Vector2(4 + seed % 9, 8),
		rect.position + Vector2(tile_size - 6, 2 + seed % 13),
		rect.end - Vector2(4 + seed % 7, 8),
		rect.position + Vector2(3, tile_size - 4 - seed % 10)
	])
	root.draw_polygon(rock, PackedColorArray([Color("#100e14"), Color("#15121a"), Color("#0a090d"), Color("#0d0b10")]))

	if has_floor_below:
		root.draw_rect(Rect2(rect.position + Vector2(0, 36), Vector2(tile_size, 28)), Color("#050407dd"), true)
		root.draw_line(rect.position + Vector2(0, 38), rect.position + Vector2(tile_size, 38), Color("#4f4058"), 3.0)
	if has_floor_above:
		root.draw_line(rect.position + Vector2(0, tile_size - 4), rect.position + Vector2(tile_size, tile_size - 4), Color("#19131d"), 3.0)
	if has_floor_left:
		root.draw_rect(Rect2(rect.position, Vector2(12, tile_size)), Color("#070609aa"), true)
	if has_floor_right:
		root.draw_rect(Rect2(rect.position + Vector2(tile_size - 12, 0), Vector2(12, tile_size)), Color("#070609aa"), true)

	_draw_wall_cracks(rect, cell)
	root.draw_rect(rect, Color("#02020344"), false, 1.0)

func _draw_back_wall_faces(floor_cells: Dictionary) -> void:
	for run in _horizontal_edge_runs(floor_cells, -1):
		var start_cell = Vector2i(int(run["start"]), int(run["row"]))
		var x = grid_origin.x + float(run["start"]) * tile_size
		var y = grid_origin.y + float(run["row"]) * tile_size
		var width = float(run["end"] - run["start"] + 1) * tile_size
		var face = Rect2(Vector2(x, y - wall_height), Vector2(width, wall_height + 6))
		_draw_wall_face(face, start_cell, Color("#312735"), Color("#0c090f"))
		root.draw_rect(Rect2(Vector2(x, y), Vector2(width, 22)), Color("#030204aa"), true)
		root.draw_line(Vector2(x, y + 1), Vector2(x + width, y + 1), Color("#756177"), 5.0)
		root.draw_line(Vector2(x, y + 7), Vector2(x + width, y + 7), Color("#17111a"), 2.0)

func _draw_side_wall_faces(floor_cells: Dictionary) -> void:
	for run in _vertical_edge_runs(floor_cells, -1):
		var cell = Vector2i(int(run["col"]), int(run["start"]))
		var floor_x = grid_origin.x + float(run["col"]) * tile_size
		var y = grid_origin.y + float(run["start"]) * tile_size
		var height = float(run["end"] - run["start"] + 1) * tile_size
		var left_face = Rect2(Vector2(floor_x - side_wall_width, y - 3), Vector2(side_wall_width, height + 8))
		_draw_side_wall_face(left_face, cell, true)
		root.draw_rect(Rect2(Vector2(floor_x, y), Vector2(14, height)), Color("#03020488"), true)
		root.draw_line(Vector2(floor_x, y), Vector2(floor_x, y + height), Color("#5b4a60"), 4.0)
	for run in _vertical_edge_runs(floor_cells, 1):
		var cell = Vector2i(int(run["col"]), int(run["start"]))
		var floor_x = grid_origin.x + float(run["col"] + 1) * tile_size
		var y = grid_origin.y + float(run["start"]) * tile_size
		var height = float(run["end"] - run["start"] + 1) * tile_size
		var right_face = Rect2(Vector2(floor_x, y - 3), Vector2(side_wall_width, height + 8))
		_draw_side_wall_face(right_face, cell, false)
		root.draw_rect(Rect2(Vector2(floor_x - 14, y), Vector2(14, height)), Color("#03020488"), true)
		root.draw_line(Vector2(floor_x, y), Vector2(floor_x, y + height), Color("#5b4a60"), 4.0)

func _draw_front_wall_faces(floor_cells: Dictionary) -> void:
	for run in _horizontal_edge_runs(floor_cells, 1):
		var start_cell = Vector2i(int(run["start"]), int(run["row"]))
		var x = grid_origin.x + float(run["start"]) * tile_size
		var y = grid_origin.y + float(run["row"] + 1) * tile_size
		var width = float(run["end"] - run["start"] + 1) * tile_size
		var face = Rect2(Vector2(x, y - 4), Vector2(width, wall_height + 8))
		_draw_wall_face(face, start_cell + Vector2i(0, 13), Color("#201923"), Color("#050407"))
		root.draw_rect(Rect2(Vector2(x, y - 18), Vector2(width, 18)), Color("#020203b8"), true)
		root.draw_line(Vector2(x, y - 3), Vector2(x + width, y - 3), Color("#6e5a6f"), 5.0)
		root.draw_line(Vector2(x, y + 4), Vector2(x + width, y + 4), Color("#0a070c"), 2.0)

func _draw_wall_face(rect: Rect2, cell: Vector2i, top_color: Color, bottom_color: Color) -> void:
	root.draw_rect(rect, bottom_color, true)
	var rows = 4
	for row in range(rows):
		var y = rect.position.y + rect.size.y * float(row) / float(rows)
		var h = rect.size.y / float(rows) + 1.0
		var color = top_color.lerp(bottom_color, float(row) / float(rows - 1))
		root.draw_rect(Rect2(Vector2(rect.position.x, y), Vector2(rect.size.x, h)), color, true)
	if not _draw_dungeon_art("wall_face", rect, Color(1, 1, 1, 0.58)) and root.wall_texture != null:
		root.draw_texture_rect(root.wall_texture, rect, false, Color(0.55, 0.49, 0.66, 0.46))
	var cap_rect = Rect2(rect.position + Vector2(0, -8), Vector2(rect.size.x, min(rect.size.y, 40.0)))
	_draw_dungeon_art("wall_cap", cap_rect, Color(1, 1, 1, 0.72))
	var seed = abs(cell.x * 47 + cell.y * 71)
	var columns: int = max(1, int(rect.size.x / 38.0))
	for column in range(columns):
		var x = rect.position.x + 12.0 + column * 38.0 + float((seed + column * 11) % 13)
		if x > rect.end.x - 10.0:
			continue
		root.draw_line(Vector2(x, rect.position.y + 7), Vector2(x - 7, rect.end.y - 8), Color("#05040670"), 1.0)
		if column % 2 == 0:
			root.draw_line(Vector2(x - 18, rect.position.y + rect.size.y * 0.48), Vector2(x + 14, rect.position.y + rect.size.y * 0.48), Color("#4d435255"), 1.0)
	_draw_wall_cap_stones(rect, cell)
	root.draw_rect(rect, Color("#05040788"), false, 1.0)

func _draw_side_wall_face(rect: Rect2, cell: Vector2i, left: bool) -> void:
	var inner_x = rect.end.x if left else rect.position.x
	var outer_x = rect.position.x if left else rect.end.x
	var skew = -10.0 if left else 10.0
	var points = PackedVector2Array([
		Vector2(inner_x, rect.position.y),
		Vector2(outer_x, rect.position.y + 8.0),
		Vector2(outer_x, rect.end.y - 6.0),
		Vector2(inner_x, rect.end.y)
	])
	root.draw_polygon(points, PackedColorArray([Color("#211924"), Color("#0c090f"), Color("#050407"), Color("#151019")]))
	if not _draw_dungeon_art("rock_columns", rect, Color(1, 1, 1, 0.32)) and root.wall_texture != null:
		root.draw_texture_rect(root.wall_texture, rect, false, Color(0.38, 0.34, 0.48, 0.36))
	root.draw_line(Vector2(inner_x, rect.position.y), Vector2(inner_x + skew * 0.15, rect.end.y), Color("#6a566f"), 3.0)
	var seed = abs(cell.x * 29 + cell.y * 43)
	for i in range(2):
		var y = rect.position.y + 16.0 + i * 24.0 + float(seed % 7)
		root.draw_line(Vector2(rect.position.x + 4.0, y), Vector2(rect.end.x - 4.0, y + 5.0), Color("#05040688"), 1.0)

func _draw_wall_cap_stones(rect: Rect2, cell: Vector2i) -> void:
	var seed = abs(cell.x * 59 + cell.y * 31)
	var count: int = max(1, int(rect.size.x / 30.0))
	for i in range(count):
		var x = rect.position.x + float(i) * 30.0 + float((seed + i * 7) % 8)
		if x > rect.end.x - 10.0:
			continue
		var w = 18.0 + float((seed + i * 5) % 14)
		var h = 7.0 + float((seed + i * 3) % 6)
		var y = rect.position.y + 1.0 + float((seed + i * 11) % 4)
		var points = PackedVector2Array([
			Vector2(x, y + h),
			Vector2(x + 4.0, y),
			Vector2(min(x + w, rect.end.x), y + 2.0),
			Vector2(min(x + w - 2.0, rect.end.x), y + h + 2.0)
		])
		root.draw_polygon(points, PackedColorArray([Color("#4b3f50"), Color("#6b5a6c"), Color("#302733"), Color("#19141d")]))

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
		root.draw_rect(rect, Color("#0b0a0b22"), false, 1.0)

	_draw_floor_edges(floor_cells)
	_draw_path_markers(layout)

func _draw_room_interaction_overlays() -> void:
	for room_id in _draw_order():
		if not root.rooms.has(room_id):
			continue
		var room: Dictionary = root.rooms[room_id]
		var rect = root.graph.rect(room_id)
		var zone = rect.grow(-6.0) if _has_connected_map() else rect
		var room_type = room.get("type", "")
		root.draw_rect(zone, _room_overlay(room_type), true)
		if _has_connected_map():
			root.draw_rect(zone, _with_alpha(_accent_color(room_type), 0.42), false, 2.0)
		if room_type == "core":
			root.draw_arc(zone.get_center(), min(zone.size.x, zone.size.y) * 0.38, 0.0, TAU, 54, Color("#9b3147aa"), 4.0)
		elif room_type == "recovery":
			root.draw_arc(zone.get_center(), min(zone.size.x, zone.size.y) * 0.34, 0.0, TAU, 54, Color("#57a667aa"), 4.0)
		elif room_type == "build_slot":
			_draw_build_slot_detail(zone)
		if room_id == root.selected_room:
			root.draw_rect(zone.grow(9.0), Color("#b15dff"), false, 4.0)
			root.draw_rect(zone.grow(15.0), Color("#e0b4ff55"), false, 2.0)

func _draw_floor_edges(floor_cells: Dictionary) -> void:
	for key in floor_cells.keys():
		var cell: Vector2i = floor_cells[key]
		var rect = _cell_rect(cell)
		if not floor_cells.has(_cell_key(cell + Vector2i(0, -1))):
			root.draw_rect(Rect2(rect.position, Vector2(tile_size, 18)), Color("#05030788"), true)
		if not floor_cells.has(_cell_key(cell + Vector2i(0, 1))):
			root.draw_rect(Rect2(rect.position + Vector2(0, tile_size - 12), Vector2(tile_size, 14)), Color("#05040688"), true)
		if not floor_cells.has(_cell_key(cell + Vector2i(-1, 0))):
			root.draw_rect(Rect2(rect.position, Vector2(10, tile_size)), Color("#07060966"), true)
		if not floor_cells.has(_cell_key(cell + Vector2i(1, 0))):
			root.draw_rect(Rect2(rect.position + Vector2(tile_size - 10, 0), Vector2(10, tile_size)), Color("#07060966"), true)

func _draw_doorways() -> void:
	var drawn: Dictionary = {}
	for room_id in root.rooms.keys():
		for exit_id in root.graph.exits(room_id):
			var key = "%s-%s" % [room_id, exit_id]
			var reverse_key = "%s-%s" % [exit_id, room_id]
			if drawn.has(key) or drawn.has(reverse_key):
				continue
			drawn[key] = true
			_draw_doorway(room_id, exit_id)

func _draw_doorway(room_id: String, exit_id: String) -> void:
	var room_rect = root.graph.rect(room_id)
	var start = root.graph.center(room_id)
	var end = root.graph.center(exit_id)
	var delta = end - start
	if abs(delta.x) >= abs(delta.y):
		var x = room_rect.end.x if delta.x > 0.0 else room_rect.position.x
		var y = clamp(start.y, room_rect.position.y + 44.0, room_rect.end.y - 44.0)
		var top = Vector2(x, y - 44.0)
		var bottom = Vector2(x, y + 44.0)
		root.draw_rect(Rect2(Vector2(x - 13, y - 56), Vector2(26, 112)), Color("#050305dd"), true)
		_draw_dungeon_art("door_arch", Rect2(Vector2(x - 48, y - 66), Vector2(96, 128)), Color(1, 1, 1, 0.56))
		root.draw_line(top, bottom, Color("#171018"), 18.0)
		root.draw_line(top + Vector2(0, 8), bottom - Vector2(0, 8), Color("#8b704e"), 4.0)
		root.draw_line(top + Vector2(9, 4), bottom + Vector2(9, -4), Color("#0b070d"), 3.0)
		_draw_pillar(top + Vector2(0, -12))
		_draw_pillar(bottom + Vector2(0, 12))
	else:
		var y = room_rect.end.y if delta.y > 0.0 else room_rect.position.y
		var x = clamp(start.x, room_rect.position.x + 44.0, room_rect.end.x - 44.0)
		var left = Vector2(x - 48.0, y)
		var right = Vector2(x + 48.0, y)
		root.draw_rect(Rect2(Vector2(x - 58, y - 14), Vector2(116, 28)), Color("#050305dd"), true)
		_draw_dungeon_art("door_arch", Rect2(Vector2(x - 54, y - 82), Vector2(108, 126)), Color(1, 1, 1, 0.62))
		root.draw_line(left, right, Color("#171018"), 18.0)
		root.draw_line(left + Vector2(8, 0), right - Vector2(8, 0), Color("#8b704e"), 4.0)
		root.draw_line(left + Vector2(7, 9), right - Vector2(7, -9), Color("#0b070d"), 3.0)
		_draw_pillar(left + Vector2(-12, 0))
		_draw_pillar(right + Vector2(12, 0))

func _draw_path_markers(layout: Dictionary) -> void:
	var main_route = ["entrance", "spike_corridor", "center", "throne"]
	for index in range(main_route.size() - 1):
		_draw_path_dots(root.graph.center(main_route[index]), root.graph.center(main_route[index + 1]), Color("#8c7a6146"))
	_draw_path_dots(root.graph.center("center"), root.graph.center("barracks"), Color("#8c7a613a"))
	_draw_path_dots(root.graph.center("center"), root.graph.center("recovery"), Color("#8c7a613a"))
	_draw_path_dots(root.graph.center("slot_01"), root.graph.center("treasure"), Color("#8c7a613a"))

func _draw_path_dots(start: Vector2, end: Vector2, color: Color) -> void:
	var distance = start.distance_to(end)
	if distance < 1.0:
		return
	var direction = (end - start).normalized()
	var steps = int(distance / 34.0)
	for step in range(1, steps):
		var point = start + direction * float(step) * 34.0
		root.draw_circle(point, 3.0, color)
		root.draw_circle(point + Vector2(3, 2), 1.5, Color("#18100f44"))

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
		_draw_corner_pillars(rect)
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
		if _has_connected_map():
			var marker_size = float(room.get("icon_size", 76.0))
			size = Vector2(marker_size, marker_size)
		var center = _room_icon_center(room_id, room)
		if _has_connected_map():
			_draw_room_marker_plate(center, size, room.get("type", ""))
		var alpha = 0.62 if root.current_screen == Constants.SCREEN_COMBAT else 0.94
		root.draw_texture_rect(texture, Rect2(center - size * 0.5, size), false, Color(1, 1, 1, alpha))

func _room_icon_center(room_id: String, room: Dictionary) -> Vector2:
	var center = root.graph.center(room_id)
	var offset = room.get("icon_offset", [0, -8])
	if offset is Array and offset.size() >= 2:
		center += Vector2(float(offset[0]), float(offset[1]))
	elif not _has_connected_map():
		center += Vector2(0, -8)
	return center

func _draw_room_marker_plate(center: Vector2, size: Vector2, room_type: String) -> void:
	var radius = max(size.x, size.y) * 0.58
	var accent = _accent_color(room_type)
	root.draw_circle(center + Vector2(0, 7), radius, Color("#030205aa"))
	root.draw_circle(center, radius, Color("#0b080dcc"))
	root.draw_arc(center, radius, 0.0, TAU, 48, _with_alpha(accent, 0.72), 2.5)

func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

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
		_draw_torch(point, glow, flame)

func _draw_corner_pillars(rect: Rect2) -> void:
	var points = [
		rect.position + Vector2(12, 12),
		Vector2(rect.end.x - 12, rect.position.y + 12),
		Vector2(rect.position.x + 12, rect.end.y - 12),
		rect.end - Vector2(12, 12)
	]
	for point in points:
		_draw_pillar(point)

func _draw_pillar(point: Vector2) -> void:
	root.draw_circle(point + Vector2(0, 7), 14.0, Color("#050407aa"))
	if _draw_dungeon_art("pillar", Rect2(point - Vector2(24, 54), Vector2(48, 78)), Color(1, 1, 1, 0.9)):
		return
	root.draw_circle(point, 12.0, Color("#2d2730"))
	root.draw_circle(point + Vector2(-3, -3), 6.0, Color("#5a4e5d"))
	root.draw_circle(point, 12.0, Color("#0b090d"), false, 2.0)

func _draw_torch(point: Vector2, glow: Color, flame: Color) -> void:
	root.draw_circle(point, 42.0, glow)
	if _draw_dungeon_art("purple_torch", Rect2(point - Vector2(24, 56), Vector2(48, 66)), Color(1, 1, 1, 0.92)):
		return
	root.draw_rect(Rect2(point + Vector2(-4, -2), Vector2(8, 18)), Color("#171018"), true)
	root.draw_circle(point + Vector2(0, -6), 8.0, Color("#f57d2c"))
	root.draw_circle(point + Vector2(0, -10), 6.0, flame)
	root.draw_circle(point + Vector2(0, -13), 3.0, Color("#fff0a4"))

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
	root.draw_rect(bounds, Color("#050507"), true)
	var index = 0
	for y in range(int(bounds.position.y - 40), int(bounds.end.y + 40), 78):
		for x in range(int(bounds.position.x - 48), int(bounds.end.x + 48), 92):
			var offset = Vector2(float((index * 19) % 31) - 15.0, float((index * 23) % 27) - 13.0)
			var center = Vector2(x, y) + offset
			var points = PackedVector2Array([
				center + Vector2(-42, -18 - index % 11),
				center + Vector2(-10 + index % 15, -35),
				center + Vector2(44, -16 + index % 9),
				center + Vector2(34 - index % 7, 22),
				center + Vector2(-28, 28 - index % 13)
			])
			var base = Color("#111017") if index % 2 == 0 else Color("#0b0b10")
			root.draw_polygon(points, PackedColorArray([base, Color("#18131d"), Color("#08080c"), Color("#060609"), base]))
			if index % 3 == 0:
				root.draw_line(center + Vector2(-24, -5), center + Vector2(24, 8), Color("#251f2b55"), 2.0)
			index += 1
	_draw_dungeon_art("fortress_wall", Rect2(Vector2(map_bounds.end.x - 40, map_bounds.position.y + 310), Vector2(360, 190)), Color(1, 1, 1, 0.35))
	_draw_dungeon_art("rock_border", Rect2(Vector2(map_bounds.position.x - 80, map_bounds.end.y - 190), Vector2(320, 205)), Color(1, 1, 1, 0.36))
	_draw_dungeon_art("rock_columns", Rect2(Vector2(map_bounds.end.x - 270, map_bounds.end.y - 185), Vector2(300, 180)), Color(1, 1, 1, 0.28))

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

func _draw_wall_cracks(rect: Rect2, cell: Vector2i) -> void:
	var seed = abs(cell.x * 37 + cell.y * 53)
	if seed % 2 == 0:
		var start = rect.position + Vector2(18 + seed % 20, 12)
		root.draw_line(start, start + Vector2(-8, 14), Color("#070608aa"), 2.0)
		root.draw_line(start + Vector2(-8, 14), start + Vector2(6, 24), Color("#070608aa"), 2.0)
	if seed % 3 == 0:
		var stone = Rect2(rect.position + Vector2(10 + seed % 22, 38), Vector2(22, 12))
		root.draw_rect(stone, Color("#34303955"), true)
		root.draw_rect(stone, Color("#0a090c88"), false, 1.0)

func _sorted_cells(cells: Dictionary) -> Array:
	var sorted: Array = []
	for key in cells.keys():
		sorted.append(cells[key])
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return sorted

func _horizontal_edge_runs(floor_cells: Dictionary, direction_y: int) -> Array:
	var by_row: Dictionary = {}
	for cell in _sorted_cells(floor_cells):
		if floor_cells.has(_cell_key(cell + Vector2i(0, direction_y))):
			continue
		var row_key = str(cell.y)
		if not by_row.has(row_key):
			by_row[row_key] = []
		by_row[row_key].append(cell.x)
	var runs: Array = []
	for row_key in by_row.keys():
		var xs: Array = by_row[row_key]
		xs.sort()
		if xs.is_empty():
			continue
		var start = int(xs[0])
		var previous = start
		for index in range(1, xs.size()):
			var current = int(xs[index])
			if current == previous + 1:
				previous = current
				continue
			runs.append({"row": int(row_key), "start": start, "end": previous})
			start = current
			previous = current
		runs.append({"row": int(row_key), "start": start, "end": previous})
	return runs

func _vertical_edge_runs(floor_cells: Dictionary, direction_x: int) -> Array:
	var by_col: Dictionary = {}
	for cell in _sorted_cells(floor_cells):
		if floor_cells.has(_cell_key(cell + Vector2i(direction_x, 0))):
			continue
		var col_key = str(cell.x)
		if not by_col.has(col_key):
			by_col[col_key] = []
		by_col[col_key].append(cell.y)
	var runs: Array = []
	for col_key in by_col.keys():
		var ys: Array = by_col[col_key]
		ys.sort()
		if ys.is_empty():
			continue
		var start = int(ys[0])
		var previous = start
		for index in range(1, ys.size()):
			var current = int(ys[index])
			if current == previous + 1:
				previous = current
				continue
			runs.append({"col": int(col_key), "start": start, "end": previous})
			start = current
			previous = current
		runs.append({"col": int(col_key), "start": start, "end": previous})
	return runs

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
