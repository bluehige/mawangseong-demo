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
var visible_front_faces: Array = []
var visible_back_faces: Array = []
var corner_piers: Array[Vector2i] = []
var clipped_front_count := 0
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
	visible_front_faces.clear()
	visible_back_faces.clear()
	corner_piers.clear()
	clipped_front_count = 0
	source_edge_count = 0
	transition_count = 0
	var endpoint_counts: Dictionary = {}
	for edge in edges:
		if str(edge.get("state", "")) in ["closed", "open_placeholder"]:
			for vertex in [edge.start_vertex, edge.end_vertex]:
				endpoint_counts[vertex] = int(endpoint_counts.get(vertex, 0)) + 1
	for edge in edges:
		if str(edge.get("state", "")) not in ["closed", "open_placeholder"]:
			continue
		var a: Vector2i = edge.start_vertex * SUBDIV
		var b: Vector2i = edge.end_vertex * SUBDIV
		var minimum := Vector2i(mini(a.x, b.x), mini(a.y, b.y)) - Vector2i.ONE * HALF_WIDTH
		var maximum := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y)) + Vector2i.ONE * HALF_WIDTH
		# Free wall ends finish on their actual plane, without a half-width peg.
		for vertex in [edge.start_vertex, edge.end_vertex]:
			if int(endpoint_counts[vertex]) != 1:
				continue
			var end: Vector2i = vertex * SUBDIV
			if a.x != b.x:
				if end.x == mini(a.x, b.x): minimum.x = end.x
				else: maximum.x = end.x
			else:
				if end.y == mini(a.y, b.y): minimum.y = end.y
				else: maximum.y = end.y
		var height := LOW if str(edge.side) in ["E", "S"] else HIGH
		for y in range(minimum.y, maximum.y):
			for x in range(minimum.x, maximum.x):
				var cell := Vector2i(x, y)
				heights[cell] = maxi(int(heights.get(cell, 0)), height)
		source_edge_count += 1
	_build_corner_piers(edges)
	_build_top_surfaces()
	_build_side_surfaces(Vector2i.RIGHT)
	_build_side_surfaces(Vector2i.DOWN)
	back_faces.sort_custom(_face_less)
	front_faces.sort_custom(_face_less)
	_clip_wall_occlusion()
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
		_add_face(points, uv, Color(0.93, 1.01, 1.20, 1.0), height, (a + b) * 0.5, true)

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
		var tint := Color(0.25, 0.29, 0.39, 1.0) if direction == Vector2i.RIGHT else Color(0.49, 0.55, 0.69, 1.0)
		_add_face(points, uv, tint, upper, (a + b) * 0.5, false, lower)
		if lower > 0:
			transition_count += 1

func _add_face(points: PackedVector2Array, uv: PackedVector2Array, tint: Color, height: int, center: Vector2, top: bool, lower: int = 0) -> void:
	var face := {
		"points": points, "uv": uv, "tint": tint, "top": top,
		"depth": _project(center).y + (0.01 if top else 0.0), "height": height
	}
	var inverse := Transform2D(points[1] - points[0], points[3] - points[0], points[0]).affine_inverse()
	face["inverse"] = inverse
	face["depth_origin"] = points[0].y + height * scale
	face["depth_dx"] = points[1].y - points[0].y
	face["depth_dy"] = points[3].y + (height if top else lower) * scale - float(face.depth_origin)
	face["bounds"] = _polygon_bounds(points)
	if height > LOW:
		back_faces.append(face)
	else:
		front_faces.append(face)

func draw(target: CanvasItem, front: bool) -> void:
	if texture == null:
		texture = load(MATERIAL_PATH)
	for face in (visible_front_faces if front else visible_back_faces):
		target.draw_polygon(face.points, PackedColorArray([face.tint]), face.uv, texture)
		# Cap bevel: edge lighting over the generated material, without internal top seams.
		if not bool(face.top) and not bool(face.get("clipped", false)):
			var points: PackedVector2Array = face.points
			target.draw_line(points[0], points[1], Color("#b4c8f0a0"), 2.3 * scale, true)
			target.draw_line(points[2], points[3], Color("#02030bd0"), 2.2 * scale, true)

func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0], Vector2.ZERO)
	for point in points:
		rect = rect.expand(point)
	return rect

func _depth_at(face: Dictionary, point: Vector2) -> float:
	var local: Vector2 = face.inverse * point
	return float(face.depth_origin) + local.x * float(face.depth_dx) + local.y * float(face.depth_dy)

func _uv_at(face: Dictionary, point: Vector2) -> Vector2:
	var local: Vector2 = face.inverse * point
	return face.uv[0] + local.x * (face.uv[1] - face.uv[0]) + local.y * (face.uv[3] - face.uv[0])

func _clip_wall_occlusion() -> void:
	# Every wall surface shares one depth test. A center-sorted tall surface can
	# otherwise paint over the nearer side of an adjoining wall just like a low strip.
	var all_faces: Array = back_faces + front_faces
	for face: Dictionary in all_faces:
		var pieces: Array[PackedVector2Array] = [face.points]
		for blocker: Dictionary in all_faces:
			if pieces.is_empty(): break
			if not face.bounds.intersects(blocker.bounds): continue
			var overlaps := Geometry2D.intersect_polygons(face.points, blocker.points)
			if overlaps.is_empty(): continue
			var overlap: PackedVector2Array = overlaps[0]
			if not _usable_polygon(overlap): continue
			var sample := Vector2.ZERO
			for point in overlap: sample += point
			sample /= overlap.size()
			if _depth_at(blocker, sample) <= _depth_at(face, sample) + 0.01: continue
			var remaining: Array[PackedVector2Array] = []
			for piece in pieces:
				remaining.append_array(_subtract_convex(piece, blocker.points))
			pieces = remaining
		var destination: Array = visible_front_faces if int(face.height) == LOW else visible_back_faces
		if pieces.size() == 1 and pieces[0] == face.points:
			destination.append(face)
			continue
		if int(face.height) == LOW: clipped_front_count += 1
		for piece in pieces:
			if not _usable_polygon(piece): continue
			var clipped := face.duplicate()
			clipped["points"] = piece
			clipped["clipped"] = true
			var uv := PackedVector2Array()
			for point in piece: uv.append(_uv_at(face, point))
			clipped["uv"] = uv
			destination.append(clipped)

func _build_corner_piers(edges: Array) -> void:
	var joints: Dictionary = {}
	for edge in edges:
		if str(edge.get("state", "")) not in ["closed", "open_placeholder"]: continue
		for vertex in [edge.start_vertex, edge.end_vertex]:
			if not joints.has(vertex): joints[vertex] = []
			var other: Vector2i = edge.end_vertex if vertex == edge.start_vertex else edge.start_vertex
			var direction: Vector2i = (other - vertex).sign()
			if not joints[vertex].has(direction): joints[vertex].append(direction)
	for vertex: Vector2i in joints:
		var directions: Array = joints[vertex]
		if directions.size() < 2: continue
		if directions.size() == 2 and directions[0] == -directions[1]: continue
		var center := vertex * SUBDIV
		var height := 0
		for y in range(center.y - HALF_WIDTH, center.y + HALF_WIDTH):
			for x in range(center.x - HALF_WIDTH, center.x + HALF_WIDTH):
				height = maxi(height, int(heights.get(Vector2i(x, y), 0)))
		# A slightly broader quoin gives abrupt cutaway returns a deliberate stop.
		# It remains within a tile's boundary band, never the walk-cell center.
		var radius := HALF_WIDTH + 1
		for y in range(center.y - radius, center.y + radius):
			for x in range(center.x - radius, center.x + radius):
				heights[Vector2i(x, y)] = height + 8
		corner_piers.append(vertex)

func _signed_area(points: PackedVector2Array) -> float:
	if points.size() < 3: return 0.0
	var area := 0.0
	# Local coordinates avoid cancellation on the far end of a large map.
	for i in range(1, points.size() - 1):
		area += (points[i] - points[0]).cross(points[i + 1] - points[0])
	return area * 0.5

func _usable_polygon(points: PackedVector2Array) -> bool:
	return points.size() >= 3 and absf(_signed_area(points)) > 0.01

func _half_plane(points: PackedVector2Array, a: Vector2, b: Vector2, sign_value: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.is_empty(): return result
	var previous := points[-1]
	var previous_side := (b - a).cross(previous - a) * sign_value
	for point in points:
		var side := (b - a).cross(point - a) * sign_value
		if (side >= 0.0) != (previous_side >= 0.0):
			var crossing := previous.lerp(point, previous_side / (previous_side - side))
			if result.is_empty() or result[-1].distance_squared_to(crossing) > 0.00001:
				result.append(crossing)
		if side >= 0.0 and (result.is_empty() or result[-1].distance_squared_to(point) > 0.00001):
			result.append(point)
		previous = point
		previous_side = side
	if result.size() > 1 and result[0].distance_squared_to(result[-1]) < 0.00001:
		result.remove_at(result.size() - 1)
	return result

func _subtract_convex(subject: PackedVector2Array, cutter: PackedVector2Array) -> Array[PackedVector2Array]:
	# Split into convex pieces instead of producing hole contours or near-zero slivers.
	# Godot can render each piece directly without interpreting a hole as a filled polygon.
	var result: Array[PackedVector2Array] = []
	var inside := subject
	var winding := 1.0 if _signed_area(cutter) > 0.0 else -1.0
	for i in cutter.size():
		var a := cutter[i]
		var b := cutter[(i + 1) % cutter.size()]
		var outside := _half_plane(inside, a, b, -winding)
		if _usable_polygon(outside): result.append(outside)
		inside = _half_plane(inside, a, b, winding)
		if not _usable_polygon(inside): break
	return result
