extends Node

const GameScene = preload("res://scenes/game/GameRoot.tscn")
const WalkMap = preload("res://scripts/dungeon_quarter/DungeonWalkMap.gd")
const Mask = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
var game: Node
var checks := 0
var failures: Array[String] = []
var samples := 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok and not failures.has(message): failures.append(message);print("FAIL: ",message)

func _ready() -> void:
	call_deferred("run")

func settle(count: int = 8) -> void:
	for index in range(count): await get_tree().process_frame

func check_path(path: Array, label: String) -> void:
	expect(not path.is_empty(),label+" exists")
	for point: Vector2 in path:
		expect(game.graph.is_walkable(point),label+" waypoints on actual walk cells")
	for index in range(1,path.size()):
		var a: Vector2i = game.graph.walk_map.world_to_cell(path[index-1])
		var b: Vector2i = game.graph.walk_map.world_to_cell(path[index])
		expect(absi(a.x-b.x)+absi(a.y-b.y) <= 1,label+" adjacent physical cells")

func run() -> void:
	var day := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--day="): day = int(arg.trim_prefix("--day="))
	seed(130+day)
	game = GameScene.instantiate()
	game.campaign_save_enabled = false;game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false;game.campaign_save_v5_enabled = false
	add_child(game)
	await settle()
	seed(130+day)
	game.onboarding_enabled = false;game.tutorial_gate_enabled = false;game.tutorial_manager.active = false
	game.story_feature_enabled = false;game.story_director.cancel_active_scene();game.onboarding_dialogue_queue.clear()
	get_window().size = Vector2i(1920,1080)
	GameState.day = day
	if day == 12:
		game.castle_art_stage = "stage_02_castle"
		game._sync_castle_stage_content()
		game._setup_dungeon_graph()
		game.quarter_renderer.refresh_layout()
	expect(game.graph.layout.has("plot_grid"),"DAY%d new plot active" % day)
	expect(game.graph.validation_summary().ok,"DAY%d physical graph valid: %s" % [day,game.graph.validation_summary()])
	expect(game.graph.layout.plot_grid.size == [36 if day == 12 else 30,20],"grade width and fixed height")
	var nav: Dictionary = game.graph.layout.get("generated_navigation",{})
	check_path(nav.get("main",[]),"main attack")
	check_path(nav.get("thief",[]),"thief treasure")
	if day == 12:
		expect(game.graph.module_instance_ids().has("outside_approach_b"),"DAY12 independent service approach preserved")
		check_path(game.graph.path_points("outside_approach_b","throne"),"DAY12 service attack")
	expect(not nav.get("patrol",{}).is_empty(),"patrol generated")
	for id in nav.get("patrol",{}): check_path(nav.patrol[id],"patrol "+id)
	var source: Dictionary = game._layout_with_castle_stage_expansions(DataRegistry.quarter_layout(game.quarter_layout_id))
	expect(game.graph.layout.combat_topology.defense_zones == source.combat_topology.defense_zones,"zone capacities and effect references unchanged")
	var trap_module: Dictionary = game.graph.module_data_for_instance("spike_corridor")
	expect(trap_module.trap_cells.size() == 6 and trap_module.room_function == "trap","six trap cells and trap function preserved")
	for value in trap_module.trap_cells:
		var cell := Vector2i(value[0],value[1])
		expect(game.graph.debug_cell_walkable(cell) and game.graph.debug_cell_data()[cell].trap_id == "spike_floor","trap mapped to real road")
	for lane in game.graph.layout.combat_topology.lanes.values():
		var route: Array = lane.route
		expect(not route.is_empty() and route.front() == lane.get("outside_room_id",lane.get("entry_room_id","entrance")) and route.back() == game.graph.layout.combat_topology.get("goal_room_id","throne"),"auto lane endpoints: %s" % lane)
		for index in range(1,route.size()): expect(game.graph.exits(route[index-1]).has(route[index]),"auto lane uses actual adjacency")
	var disconnected := WalkMap.new()
	disconnected.allow_direct_fallback = false
	disconnected.rebuild_from_cell_data({Vector2i(0,0):{"active":true,"walkable":true},Vector2i(5,0):{"active":true,"walkable":true}}, {},Vector2(128,64),Vector2.ZERO,1)
	expect(disconnected.get_path_world(disconnected.cell_to_world(Vector2i.ZERO),disconnected.cell_to_world(Vector2i(5,0))).is_empty(),"disconnected graph refuses straight fallback")
	game.combat_scene.start_combat()
	await settle(2)
	expect(game.current_screen == "combat","DAY%d combat starts" % day)
	var first_secondary_time := 0.0
	var sample_frames := 720
	if day == 12:
		first_secondary_time = INF
		for entry in game.wave_manager.schedule:
			if entry.get("lane_id","") == "lane_b": first_secondary_time = minf(first_secondary_time,float(entry.get("time",0)))
		expect(is_finite(first_secondary_time),"DAY12 actual schedule includes a secondary-lane enemy")
		if is_finite(first_secondary_time): sample_frames = maxi(sample_frames,int((first_secondary_time+15)*60))
		print("DAY12 secondary first scheduled at ",first_secondary_time,"s")
	var captured := false
	var moved := false
	var last_positions: Dictionary = {}
	var maximum_enemies := 0
	var lane_samples: Dictionary = {}
	for frame in range(sample_frames):
		await get_tree().physics_frame
		maximum_enemies = maxi(maximum_enemies,game.enemy_units.size())
		for enemy in game.enemy_units:
			if not is_instance_valid(enemy) or not enemy.is_alive(): continue
			samples += 1
			var lane_id := str(enemy.get_meta("v122_lane_id",""))
			lane_samples[lane_id] = int(lane_samples.get(lane_id,0)) + 1
			expect(game.graph.is_walkable(enemy.global_position),"DAY%d enemy never outside room/road" % day)
			for point in enemy.path_points: expect(game.graph.is_walkable(point),"live enemy path stays on road")
			var id: int = enemy.get_instance_id()
			if last_positions.has(id) and enemy.global_position.distance_to(last_positions[id]) > 0.1: moved = true
			last_positions[id] = enemy.global_position
		if frame >= 180 and not captured and game.enemy_units.size() > 0 and OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var path := "res://tmp/v130_map/M2_DAY%d.png" % day
			get_viewport().get_texture().get_image().save_png(path)
			print("CAPTURE: ",path)
			captured = true
		if game.current_screen != "combat": break
		if day == 12 and frame >= 720 and int(lane_samples.get("lane_b",0)) >= 60 and game.combat_time >= first_secondary_time+1: break
	expect(maximum_enemies > 0 and moved and samples > 100,"DAY%d real enemies spawn and move; samples=%d" % [day,samples])
	if day == 12: expect(int(lane_samples.get("lane_a",0)) > 0 and int(lane_samples.get("lane_b",0)) >= 60,"DAY12 both entry lanes sampled in live combat")
	expect(game.combat_time >= 3.0,"combat clock advances normally")
	if OS.get_cmdline_user_args().has("--capture"): expect(captured,"representative combat captured")
	# Verify the excluded council branch still receives its unconverted legacy
	# layout and that plot terrain is hidden when returning to that renderer.
	game.combat_scene.set_pause_state(true,false)
	game.update4_active_run["campaign_mode_id"] = preload("res://scripts/systems/campaign/CampaignModeService.gd").COUNCIL_MODE_ID
	var council_layout: Dictionary = game._quarter_layout_for_graph()
	expect(not council_layout.has("plot_grid") and not council_layout.has("map_builder_modules"),"council keeps legacy layout")
	print("V130CombatMapTest DAY%d %s checks=%d samples=%d max_enemies=%d lanes=%s failures=%s" % [day,"PASS" if failures.is_empty() else "FAIL",checks,samples,maximum_enemies,lane_samples,failures])
	game._shutdown_audio_for_exit()
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failures.is_empty() else 1)
