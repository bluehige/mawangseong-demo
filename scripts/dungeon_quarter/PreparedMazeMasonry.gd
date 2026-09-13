extends RefCounted
# Visual-only masonry. Navigation and save data never change.
# A shared height field seals straight, convex, concave, T and high/low joins.
const SUBDIV := 10
const HALF_WIDTH := 2
const HIGH := 112
const LOW := 36
const MATERIAL_HEIGHT := 128.0
const MATERIAL_PATH := "res://assets/dungeon_quarter/prepared_maze/masonry_material.png"

var heights: Dictionary = {}
var back_faces: Array = []
var front_faces: Array = []
var texture: Texture2D
var built := false
var build_count := 0
var scale := 1.0
var origin := Vector2.ZERO
var basis_x := Vector2.ZERO
var basis_y := Vector2.ZERO
var source_edge_count := 0
var transition_count := 0

func invalidate() -> void:
	built = false

func rebuild(graph, edges: Array) -> void:
	scale = graph.debug_tile_visual_scale()
	basis_x = graph.tile_cell_center(Vector2i.RIGHT) - graph.tile_cell_center(Vector2i.ZERO)
	basis_y = graph.tile_cell_center(Vector2i.DOWN) - graph.tile_cell_center(Vector2i.ZERO)
	origin = graph.tile_cell_center(Vector2i.ZERO) - (basis_x + basis_y) * 0.5
	heights.clear()
	back_faces.clear()
	front_faces.clear()
	source_edge_count = 0
	transition_count = 0
	for edge in edges:
		if str(edge.get("state", "")) not in ["closed", "open_placeholder"]:
			continue
		var a: Vector2i = edge.start_vertex * SUBDIV
		var b: Vector2i = edge.end_vertex * SUBDIV
		var minimum := Vector2i(mini(a.x, b.x), mini(a.y, b.y)) - Vector2i.ONE * HALF_WIDTH
		var maximum := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y)) + Vector2i.ONE * HALF_WIDTH
		var height := LOW if str(edge.side) in ["E", "S"] else HIGH
		for y in range(minimum.y, maximum.y):
			for x in range(minimum.x, maximum.x):
				var cell := Vector2i(x, y)
				heights[cell] = maxi(int(heights.get(cell, 0)), height)
		source_edge_count += 1
	_build_top_surfaces()
	_build_side_surfaces(Vector2i.RIGHT)
	_build_side_surfaces(Vector2i.DOWN)
	back_faces.sort_custom(_face_less)
	front_faces.sort_custom(_face_less)
	built = true
	build_count += 1

func _face_less(a: Dictionary, b: Dictionary) -> bool:
	return float(a.depth) < float(b.depth)

func _ordered_cells() -> Array:
	var cells: Array = heights.keys()
	cells.sort_custom(func(a: Vector2i, b: Vector2i):
		return a.y < b.y if a.y != b.y else a.x < b.x
	)
	return cells

func _project(point: Vector2, height: float = 0.0) -> Vector2:
	return origin + basis_x * point.x + basis_y * point.y - Vector2(0, height * scale)

func _build_top_surfaces() -> void:
	var visited: Dictionary = {}
	for cell: Vector2i in _ordered_cells():
		if visited.has(cell):
			continue
		var height: int = heights[cell]
		# Merge within one texture tile; caps and corners share the same height field.
		var tile_end := Vector2i(floori(float(cell.x) / SUBDIV) + 1, floori(float(cell.y) / SUBDIV) + 1) * SUBDIV
		var end_x := cell.x + 1
		while end_x < tile_end.x and int(heights.get(Vector2i(end_x, cell.y), 0)) == height and not visited.has(Vector2i(end_x, cell.y)):
			end_x += 1
		var end_y := cell.y + 1
		while end_y < tile_end.y:
			var full := true
			for x in range(cell.x, end_x):
				if int(heights.get(Vector2i(x, end_y), 0)) != height or visited.has(Vector2i(x, end_y)):
					full = false
					break
			if not full:
				break
			end_y += 1
		for y in range(cell.y, end_y):
			for x in range(cell.x, end_x):
				visited[Vector2i(x, y)] = true
		var a := Vector2(cell) / SUBDIV
		var b := Vector2(end_x, end_y) / SUBDIV
		var corners := [a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]
		var points := PackedVector2Array()
		var uv := PackedVector2Array()
		var tile := a.floor()
		for point in corners:
			points.append(_project(point, height))
			uv.append(point - tile)
		_add_face(points, uv, Color("#d3c9baff"), height, (a + b) * 0.5, true)

func _build_side_surfaces(direction: Vector2i) -> void:
	var visited: Dictionary = {}
	var along := Vector2i.DOWN if direction == Vector2i.RIGHT else Vector2i.RIGHT
	# Deterministic order and visited checks prevent an earlier edge from covering a
	# segment that a later edge already emitted at a concave join.
	for cell: Vector2i in _ordered_cells():
		if visited.has(cell):
			continue
		var upper: int = heights[cell]
		var lower := int(heights.get(cell + direction, 0))
		if lower >= upper:
			continue
		visited[cell] = true
		var end := cell + along
		var coordinate := cell.y if along.y == 1 else cell.x
		var limit := (floori(float(coordinate) / SUBDIV) + 1) * SUBDIV
		while (end.y if along.y == 1 else end.x) < limit and not visited.has(end) and int(heights.get(end, 0)) == upper and int(heights.get(end + direction, 0)) == lower:
			visited[end] = true
			end += along
		var a := Vector2(cell + direction) / SUBDIV
		var b := Vector2(end + direction) / SUBDIV
		var u0 := fposmod(a.y if along.y == 1 else a.x, 1.0)
		var u1 := u0 + a.distance_to(b)
		var points := PackedVector2Array([_project(a, upper), _project(b, upper), _project(b, lower), _project(a, lower)])
		var uv := PackedVector2Array([
			Vector2(u0, 1.0 - upper / MATERIAL_HEIGHT),
			Vector2(u1, 1.0 - upper / MATERIAL_HEIGHT),
			Vector2(u1, 1.0 - lower / MATERIAL_HEIGHT),
			Vector2(u0, 1.0 - lower / MATERIAL_HEIGHT)
		])
		var tint := Color("#8e91a0ff") if direction == Vector2i.RIGHT else Color("#b1a89eff")
		_add_face(points, uv, tint, upper, (a + b) * 0.5, false)
		if lower > 0:
			transition_count += 1

func _add_face(points: PackedVector2Array, uv: PackedVector2Array, tint: Color, height: int, center: Vector2, top: bool) -> void:
	var face := {
		"points": points, "uv": uv, "tint": tint, "top": top,
		"depth": _project(center).y + (0.01 if top else 0.0), "height": height
	}
	if height > LOW:
		back_faces.append(face)
	else:
		front_faces.append(face)

func draw(target: CanvasItem, front: bool) -> void:
	if texture == null:
		texture = load(MATERIAL_PATH)
	for face in (front_faces if front else back_faces):
		target.draw_polygon(face.points, PackedColorArray([face.tint]), face.uv, texture)
		# Cap bevel: edge lighting over the generated material, without internal top seams.
		if not bool(face.top):
			var points: PackedVector2Array = face.points
			target.draw_line(points[0], points[1], Color("#ead8b94a"), 1.7 * scale, true)
			target.draw_line(points[2], points[3], Color("#100e1450"), 1.2 * scale, true)
