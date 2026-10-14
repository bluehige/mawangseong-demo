extends Node

const GameScene = preload("res://scenes/game/GameRoot.tscn")
const Service = preload("res://scripts/map_builder/MapBuildService.gd")
var game: Node
var checks := 0
var failures: Array[String] = []

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL: ",message)

func _ready() -> void:
	call_deferred("run")

func settle(count: int = 8) -> void:
	for index in range(count): await get_tree().process_frame

func run() -> void:
	game = GameScene.instantiate()
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false
	game.campaign_save_v5_enabled = false
	add_child(game)
	await settle()
	game.set_process(false)
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.story_feature_enabled = false
	game.story_director.cancel_active_scene()
	game.onboarding_dialogue_queue.clear()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--width="):
			var width := int(arg.trim_prefix("--width="))
			get_window().size = Vector2i(width, width*9/16)
	game._set_screen("management",false)
	await settle()
	expect(game.graph.layout.has("plot_grid"),"runtime uses new coordinate system")
	expect(game.graph.layout.get("plot_grid",{}).get("size",[]) == [30,20],"runtime starts 30x20")
	expect(game.graph.validation_summary()["ok"],"runtime layout valid: %s" % game.graph.validation_summary())
	var source: Dictionary = DataRegistry.quarter_layout(game.quarter_layout_id)
	var before := source.duplicate(true)
	var converted := Service.prepare_layout(source,DataRegistry.quarter_modules,0)
	expect(source == before,"conversion does not mutate source/save layout")
	expect(converted.has("plot_grid"),"pure conversion succeeds")
	for row in source["placed_modules"]:
		var module: Dictionary = DataRegistry.quarter_modules.get(row["module_id"],{})
		if module.get("module_type","") == "room":
			expect(game.graph.module_instance_ids().has(row["instance_id"]),"preserved room composition: %s" % row["instance_id"])
	# Conversion covers every existing castle grade without unlocking M6 content.
	var initial_stage: String = game.castle_art_stage
	for stage in DataRegistry.castle_evolution_stage_ids():
		game.castle_art_stage = stage
		var stage_index: int = game._castle_stage_index() - 1
		var expanded: Dictionary = game._layout_with_castle_stage_expansions(source)
		var stage_layout := Service.prepare_layout(expanded,DataRegistry.quarter_modules,stage_index)
		expect(stage_layout.has("plot_grid"),"grade conversion succeeds: %s" % stage)
		if stage_layout.has("plot_grid"):
			var stage_graph := preload("res://scripts/dungeon_quarter/ModuleGraph.gd").new()
			stage_graph.setup_quarter(DataRegistry.quarter_modules,stage_layout,game.rooms)
			expect(stage_graph.validation_summary().ok,"grade layout valid: %s/%s" % [stage,stage_graph.validation_summary()])
			expect(stage_layout.plot_grid.size == [30+stage_index*6,20],"grade exact expansion: %s" % stage)
	game.castle_art_stage = initial_stage
	var separated := Service._socket_pair({"sockets":[{"id":"a","side":"E","cell":[4,0]},{"id":"b","side":"E","cell":[4,4]}]},"E")
	expect(separated.is_empty(),"separate doors cannot be mistaken for a width-2 pair")
	var grid: Dictionary = game.quarter_renderer._tile_grid_for_draw()
	expect(game.quarter_renderer.last_topology_errors.is_empty(),"automatic visual patches valid")
	for cell in game.graph.layout.auto_roads.road_cells:
		expect(grid.floor_set.has(cell),"actual road floor tile")
		expect(game.quarter_renderer.last_visual_floor_set.has(cell) and game.graph.tile_walk_cells.has(cell),"visual and navigation use identical roads")
	var rear := 0
	var rim := 0
	var none := 0
	for edge in grid.wall_edges:
		var profile := str(edge.get("wall_profile",""))
		if edge.is_corridor:
			expect(profile == "none","corridor has no wall")
			none += 1
		elif edge.side in ["N","W"]:
			expect(profile == "normal","rear wall normal height")
			rear += 1
		else:
			expect(profile == "low_rim","front knee-high rim")
			rim += 1
	expect(rear > 0 and rim > 0 and none > 0,"all cutaway profiles exercised")
	expect(game.quarter_renderer._plot_map() and not game.quarter_renderer._prepared_maze(),"plot presentation owns cutaway, gameplay flags preserved")
	var plate: TextureRect = game.get_node("BackgroundVoidLayer/DungeonBackgroundPlate")
	expect(plate.texture != null,"existing terrain texture loaded")
	var screen_rect: Rect2 = plate.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,plate.size)
	expect(screen_rect.position.length() < 0.01 and screen_rect.size.distance_to(get_viewport().get_visible_rect().size) < 0.01,"terrain covers every viewport corner")
	expect(not game.quarter_renderer.stage01_edge_layer.visible,"old diamond cave mask disabled")
	if OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		# Sample exposed map corners below the opaque top HUD and above the tool dock.
		for corner in [Vector2i(4,130),Vector2i(image.get_width()-5,130),Vector2i(4,image.get_height()-100),Vector2i(image.get_width()-5,image.get_height()-100)]:
			var color := image.get_pixelv(corner)
			expect(color.r+color.g+color.b > 0.045,"corner has terrain, no black void: %s" % corner)
		var path := "res://tmp/v130_map/M1_%dx%d.png" % [get_window().size.x,get_window().size.y]
		image.save_png(path)
		print("CAPTURE: ",path)
	print("V130MapIntegrationTest %s checks=%d profiles=%d/%d/%d failures=%s" % ["PASS" if failures.is_empty() else "FAIL",checks,rear,rim,none,failures])
	game._shutdown_audio_for_exit()
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failures.is_empty() else 1)
