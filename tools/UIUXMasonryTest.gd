extends "res://tools/UIUXPreparedMazeTest.gd"
const Masonry = preload("res://scripts/dungeon_quarter/PreparedMazeMasonry.gd")

class FixtureProjection:
	extends RefCounted
	func debug_tile_visual_scale() -> float:
		return 0.73
	func tile_cell_center(cell: Vector2i) -> Vector2:
		return Vector2(230, 140) + Vector2(64, 32) * cell.x + Vector2(-64, 32) * cell.y

func _run() -> void:
	output = "res://tmp/uiux_masonry_20260913/after"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir=res://tmp/"):
			output = argument.trim_prefix("--evidence-dir=")
	corner_contracts()
	occlusion_regression()
	await super._run()

func edge(a: Vector2i, b: Vector2i, side: String, state: String = "closed") -> Dictionary:
	return {"start_vertex": a, "end_vertex": b, "side": side, "state": state}

func corner_contracts() -> void:
	var o := Vector2i.ZERO
	var e := Vector2i.RIGHT
	var n := Vector2i.UP
	var w := Vector2i.LEFT
	var s := Vector2i.DOWN
	var cases := {
		"straight_and_end_cap": [edge(o, e, "N"), edge(e, e * 2, "N")],
		"outer_high_L": [edge(o, e, "N"), edge(o, s, "W")],
		"inner_high_L": [edge(o, w, "N"), edge(o, n, "W")],
		"low_L": [edge(o, e, "S"), edge(o, s, "E")],
		"T_join": [edge(w, e, "N"), edge(o, s, "E")],
		"four_way": [edge(w, e, "N"), edge(n, s, "W")],
		"high_low_step": [edge(w, o, "N"), edge(o, e, "S")],
		"reverse_step": [edge(w, o, "S"), edge(o, e, "N")],
		"negative_coordinates": [edge(Vector2i(-3, -2), Vector2i(-2, -2), "N"), edge(Vector2i(-2, -2), Vector2i(-2, -1), "E")],
		"open_door": [edge(w * 2, w, "N"), edge(w, e, "N", "open"), edge(e, e * 2, "N")]
	}
	for label in cases:
		var wall = Masonry.new()
		wall.rebuild(FixtureProjection.new(), cases[label])
		check_surfaces(wall, label)
		check_render_faces(wall, label)
		for cell: Vector2i in wall.heights:
			var point: Vector2 = wall._project((Vector2(cell) + Vector2.ONE * 0.5) / wall.SUBDIV, wall.heights[cell])
			var covering := 0
			for face in wall.back_faces + wall.front_faces:
				if face.top and int(face.height) == int(wall.heights[cell]) and Geometry2D.is_point_in_polygon(point, face.points):
					covering += 1
			expect(covering == 1, label + " top cell covered once: " + str(cell))
		if label == "open_door":
			expect(not wall.heights.has(Vector2i.ZERO), "open door retains its empty center")
		if label in ["high_low_step", "T_join"]:
			expect(wall.transition_count > 0, label + " has an exposed sealed height transition")
		if label in ["outer_high_L", "inner_high_L", "low_L", "T_join", "four_way"]:
			for corner in [Vector2i(-1,-1), Vector2i(0,-1), Vector2i(-1,0), Vector2i.ZERO]:
				expect(wall.heights.has(corner), label + " shared corner has no quadrant hole")
	print("MASONRY_CORNER_FIXTURES: ", cases.size(), " configurations checked")

func polygon_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for i in points.size():
		area += points[i].cross(points[(i + 1) % points.size()])
	return absf(area) * 0.5

func check_surfaces(wall, label: String) -> void:
	var top_area := 0.0
	var side_area := 0.0
	var valid_uv := true
	var valid_depth := true
	for face in wall.back_faces + wall.front_faces:
		expect(face.points.size() == 4 and polygon_area(face.points) > 0.0001, label + " nondegenerate wall face")
		for uv: Vector2 in face.uv:
			valid_uv = valid_uv and uv.x >= -0.00001 and uv.x <= 1.00001 and uv.y >= -0.00001 and uv.y <= 1.00001
		if face.top:
			top_area += polygon_area(face.points)
		else:
			side_area += polygon_area(face.points)
	for face in wall.front_faces:
		valid_depth = valid_depth and int(face.height) == wall.LOW
	for face in wall.back_faces:
		valid_depth = valid_depth and int(face.height) > wall.LOW
	var expected_top: float = wall.heights.size() * absf(wall.basis_x.cross(wall.basis_y)) / (wall.SUBDIV * wall.SUBDIV)
	var expected_sides := 0.0
	for cell: Vector2i in wall.heights:
		for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
			var exposed: int = maxi(0, int(wall.heights[cell]) - int(wall.heights.get(cell + direction, 0)))
			var basis: Vector2 = wall.basis_y if direction == Vector2i.RIGHT else wall.basis_x
			expected_sides += absf(basis.x) * exposed * wall.scale / wall.SUBDIV
	expect(absf(top_area - expected_top) < maxf(0.1, expected_top * 0.0001), label + " top area exactly covers the solid footprint")
	expect(absf(side_area - expected_sides) < maxf(0.1, expected_sides * 0.0001), label + " all camera-facing sides and steps sealed")
	expect(valid_uv, label + " no texture UV overrun")
	expect(valid_depth, label + " only low wall faces cover actors")

func geometry(stage: String, origins: Dictionary) -> void:
	super.geometry(stage, origins)
	var before := JSON.stringify(game.graph.layout)
	var grid: Dictionary = game.quarter_renderer._tile_grid_for_draw()
	var wall = Masonry.new()
	wall.rebuild(game.graph, grid.wall_edges)
	check_surfaces(wall, stage)
	check_render_faces(wall, stage)
	var clear_floor := true
	for cell: Vector2i in game.graph.debug_walk_cells():
		clear_floor = clear_floor and not wall.heights.has(cell * wall.SUBDIV + Vector2i.ONE * (wall.SUBDIV / 2))
	expect(clear_floor, stage + " walk-cell centers remain clear")
	expect(JSON.stringify(game.graph.layout) == before, stage + " masonry does not change layout data")
	print("MASONRY_GEOMETRY ", stage, " cells=", wall.heights.size(), " back=", wall.back_faces.size(), " front=", wall.front_faces.size())

func shot(id: String) -> void:
	await super.shot(id)
	var renderer = game.quarter_renderer
	if renderer._prepared_maze():
		expect(renderer.maze_masonry.built, id + " live masonry built")
		expect(renderer.debug_depth_contract().front_wall_occluder == "solid_low_masonry_with_cap", id + " live depth contract")
	if id in ["1920x1080_100_stage_02_castle_management", "1920x1080_100_stage_04_citadel_management"]:
		var builds: int = renderer.maze_masonry.build_count
		var original := get_viewport().canvas_transform
		for i in range(3):
			await click(node("ZoomInManagementMapButton"))
		expect(get_viewport().canvas_transform.get_scale().x > original.get_scale().x, id + " real zoom button enlarges the map")
		await super.shot(id + "_zoom_corners")
		for i in range(8):
			game.queue_world_overlay_redraw()
			await settle(1)
		expect(renderer.maze_masonry.build_count == builds, id + " zoom and redraw reuse cached geometry")
		expect(renderer.maze_door_ids.size() > 0 and renderer.maze_sconce_anchors.size() > 0, id + " room doors and mounted sconces connected")
		get_viewport().canvas_transform = original
		await settle()

func occlusion_regression() -> void:
	var wall = Masonry.new()
	# Two physical, parallel walls. A low rear face must disappear behind the nearer
	# tall wall even though low walls use the actor-foreground CanvasItem.
	wall.rebuild(FixtureProjection.new(), [
		edge(Vector2i(0, 0), Vector2i(2, 0), "S"),
		edge(Vector2i(0, 1), Vector2i(2, 1), "N")
	])
	# Independent projection of grid (0.5, 0.2), height 18, scale .73:
	# origin (230,108) + (64,32)*.5 + (-64,32)*.2 - (0,18*.73).
	var hidden_point := Vector2(249.2, 117.26)
	var raw_cover := false
	var visible_cover := false
	for face in wall.front_faces:
		raw_cover = raw_cover or Geometry2D.is_point_in_polygon(hidden_point, face.points)
	for face in wall.visible_front_faces:
		visible_cover = visible_cover or Geometry2D.is_point_in_polygon(hidden_point, face.points)
	expect(raw_cover, "fixture reproduces the low foreground strip crossing a tall wall")
	expect(not visible_cover, "closer tall masonry hides the low strip at the bad corner")
	check_render_faces(wall, "parallel occlusion")
	var end_wall = Masonry.new()
	end_wall.rebuild(FixtureProjection.new(), [edge(Vector2i.ZERO, Vector2i(2, 0), "N")])
	expect(not end_wall.heights.has(Vector2i(-1, 0)) and not end_wall.heights.has(Vector2i(20, 0)), "free wall ends stop at their plane without a projecting peg")
	expect(end_wall.heights.has(Vector2i(0, 0)) and end_wall.heights.has(Vector2i(19, 0)), "trimming the cap preserves the wall interior")

func check_render_faces(wall, label: String) -> void:
	var valid_triangles := true
	var valid_uv := true
	var visible_area := 0.0
	var raw_area := 0.0
	for face in wall.front_faces:
		raw_area += polygon_area(face.points)
	for face in wall.visible_front_faces:
		valid_triangles = valid_triangles and not Geometry2D.triangulate_polygon(face.points).is_empty()
		visible_area += polygon_area(face.points)
		for uv: Vector2 in face.uv:
			valid_uv = valid_uv and uv.x >= -0.001 and uv.x <= 1.001 and uv.y >= -0.001 and uv.y <= 1.001
	expect(valid_triangles, label + " every final clipped polygon triangulates")
	expect(valid_uv, label + " clipping preserves texture coordinates")
	expect(visible_area <= raw_area + maxf(0.1, raw_area * 0.0001), label + " clipping never adds duplicate low-wall area")
