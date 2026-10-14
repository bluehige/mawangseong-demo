extends "res://tools/tests/V130DecorationTest.gd"

const Presentation = preload("res://scripts/map_builder/PlotPresentation.gd")
const OUT := "res://tmp/v130_m4fix/"
var framing_measurements: Array = []

func capture(label: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	await settle()
	await RenderingServer.frame_post_draw
	var path := OUT+label+".png"
	get_viewport().get_texture().get_image().save_png(path)
	captures.append(path)

func projection_checks() -> void:
	var graph = game.graph
	var before_walk: Dictionary = graph.tile_walk_cells.duplicate(true)
	var before_roads: Dictionary = graph.layout.auto_roads.road_cells.duplicate(true)
	var before_layout: Dictionary = graph.layout.duplicate(true)
	var before_route: Array = graph.path_between("entrance","throne").duplicate(true)
	var before_resources := resources()
	var cells: Rect2 = Presentation.surface_cells(graph)
	var surface: PackedVector2Array = Presentation.surface_polygon(graph,cells)
	for cell: Vector2i in graph.layout.plot_mask:
		expect(cells.encloses(Rect2(Vector2(cell)-Vector2(0.5,0.5),Vector2.ONE)),"floor encloses full existing buildable tile")
		expect(Geometry2D.is_point_in_polygon(graph.tile_cell_center(cell),surface),"existing buildable tile lies on projected floor")
	var step: Vector2 = graph.tile_size*graph.tile_visual_scale
	for i in range(4):
		var edge := surface[(i+1)%4]-surface[i]
		expect(absf(edge.x)>0 and absf(edge.y)>0,"boundary has no screen-aligned edge")
		expect(is_equal_approx(absf(edge.y/edge.x),step.y/step.x),"boundary uses room/road projection slope")
	var locked: Rect2 = Presentation.locked_cells(graph)
	if int(graph.layout.plot_grid.grade_index)<3:
		expect(locked.has_area() and locked.position.x==cells.end.x,"locked floor adjoins cell-axis edge")
		var polygon: PackedVector2Array = Presentation.surface_polygon(graph,locked)
		expect(polygon[0].is_equal_approx(surface[1]) and polygon[3].is_equal_approx(surface[2]),"locked/open floor share exact projected edge")
		expect(Geometry2D.is_point_in_polygon((polygon[0]+polygon[2])*0.5,polygon),"lock anchor lies inside locked floor")
	else:
		expect(not locked.has_area(),"last grade has no locked expansion")
	await settle()
	expect(graph.layout==before_layout and graph.tile_walk_cells==before_walk and graph.layout.auto_roads.road_cells==before_roads,"presentation preserves layout, roads and walkability")
	expect(graph.path_between("entrance","throne")==before_route and resources()==before_resources,"presentation preserves combat route and resources")
	var default_view: Transform2D = get_viewport().canvas_transform
	var safe: Rect2 = game.build_placement._workspace_safe_rect()
	for id in game.rooms:
		expect(safe.grow(1).encloses(game.get_global_transform_with_canvas()*graph.rect(id)),"default view encloses occupied room "+str(id))
	assert_view()
	var whole_scale: float = get_viewport().canvas_transform.x.length()
	expect(default_view.x.length()>whole_scale*1.15,"default rooms are visibly larger than full plot at every grade")
	framing_measurements.append({"day":GameState.day,"grade":graph.layout.plot_grid.grade_index,"window":str(get_window().size),"default_scale":default_view.x.length(),"full_plot_scale":whole_scale,"room_enlargement":default_view.x.length()/whole_scale})
	get_viewport().canvas_transform = default_view
	game.quarter_renderer.sync_management_backdrop()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	LanguageSettings.set_locale("ko",false)
	get_window().size = Vector2i(1920,1080)
	await spawn(); await show_map()
	await projection_checks()
	await capture("day1_1920")
	GameState.day = 15
	game.first_promotion_completed = true
	game.campaign_stage_two_upgrade_funded = false
	GameState.gold = 0; GameState.infamy = 0
	game._onboarding_set_stage("CAMPAIGN_DAY_15")
	game.campaign_stage_two_unlock_ready = true
	expect(game._apply_castle_evolution_for_day(15),"DAY15 real expansion")
	await show_map(); await projection_checks()
	await capture("day15_expanded_1920")
	await release()
	await spawn(); GameState.day = 1
	get_window().size = Vector2i(1280,720)
	await show_map(); await projection_checks()
	await capture("day1_1280")
	# Remaining grades exercise changing scenery bounds, with no new captures.
	for grade in [2,3]:
		game.castle_art_stage = "stage_03_keep" if grade==2 else "stage_04_citadel"
		game._setup_dungeon_graph()
		expect(int(game.graph.layout.plot_grid.grade_index)==grade,"real projected grade "+str(grade))
		await show_map(); await projection_checks()
	await release()
	var file := FileAccess.open(OUT+"projection_result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"framing":framing_measurements},"\t")); file.close()
	print("V130PlotProjectionTest %s checks=%d failures=%s" % ["PASS" if failures.is_empty() else "FAIL",checks,failures])
	get_tree().quit(0 if failures.is_empty() else 1)
