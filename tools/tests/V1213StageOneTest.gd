extends Node

const GameScene = preload("res://scenes/game/GameRoot.tscn")
const Constants = preload("res://scripts/core/Constants.gd")
const OUTPUT = "res://tmp/v1213_s1"
var game: Node
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	get_tree().create_timer(60).timeout.connect(func():
		push_error("V1213 stage one test timed out")
		get_tree().quit(1))
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok: failures.append(message)

func settle() -> void:
	for i in range(8): await get_tree().process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await settle()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size() == Vector2i(1920,1080), "1920x1080 " + name)
	image.save_png(OUTPUT.path_join(name + ".png"))

func click(control: Control) -> void:
	if control == null:
		expect(false, "missing click control")
		return
	var point := control.get_global_transform_with_canvas() * (control.size / 2)
	await click_point(point)

func click_point(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
	await settle()

func control(name: String) -> Control:
	return game.ui_layer.find_child(name, true, false) as Control

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").replace("\\", "/").contains("/tmp/v1213_s1/"), "isolated user directory")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	GameState.reset()
	game = GameScene.instantiate()
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false
	game.campaign_save_v5_enabled = false
	add_child(game)
	await settle()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1920,1080))
		await settle()
	game._debug_skip_onboarding()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.story_feature_enabled = false
	game.set_process(false)
	game.set_physics_process(false)
	GameState.day = 7
	GameState.gold = 5000
	GameState.mana = 5000
	GameState.food = 100
	game.selected_monster_id = "slime"
	game._set_screen(Constants.SCREEN_MONSTER, false)
	await settle()
	await click(control("MonsterTrainingButton"))
	expect(int(game.monster_roster.slime.get("training_count_today",0)) == 1, "S1-04 training via viewport")
	await click(control("CHR_GOB"))
	expect(game.selected_monster_id == "goblin", "S1-04 select goblin after training")
	await click(control("CHR_PYNN"))
	expect(game.selected_monster_id == "imp", "S1-04 select imp after training")
	await capture("growth_after_training")
	GameState.day = 12
	game.campaign_chapter_two_started = true
	game.monster_roster.slime.level = 5
	game.monster_roster.slime.bond = 80
	game.selected_monster_id = "slime"
	var rule: Dictionary = game._evolution_rule_choice("slime")
	expect(game._promote_monster("slime", str(rule.get("id", ""))), "S1-04 actual promotion under fulfilled conditions")
	await settle()
	await click(control("CHR_GOB"))
	expect(game.selected_monster_id == "goblin", "S1-04 select goblin after promotion")
	await click(control("CHR_PYNN"))
	expect(game.selected_monster_id == "imp", "S1-04 select imp after promotion")
	await capture("growth_after_promotion")
	await day_two_click()
	GameState.day = 7
	game.selected_room = "barracks"
	game.management_context_drawer_open = true
	game._set_screen(Constants.SCREEN_MANAGEMENT, false)
	await settle()
	await click(control("CloseManagementContextButton"))
	expect(not game.management_context_drawer_open, "S1-03 inspector close via viewport")
	game.management_tool_tab = "roster"
	game._set_screen(Constants.SCREEN_MANAGEMENT, false)
	await settle()
	game._assign_monster_to_room("goblin", "barracks")
	var before: int = game._placement_count("barracks")
	game._assign_monster_to_room("goblin", "recovery")
	expect(game._placement_count("barracks") == before - 1, "S1-05 old room count immediately decreases")
	# Home facility and active defense zone are intentionally independent.
	# Display occupancy must follow the latter while placement validation can ignore the mover.
	var zone: Dictionary = game.graph.layout.combat_topology.defense_zones[0]
	expect(game._assign_monster_to_maze_zone("goblin", str(zone.anchor_room_id)), "S1-05 assign to actual defense zone")
	var occupancy: Dictionary = game._management_room_occupancy(str(zone.anchor_room_id))
	expect(int(occupancy.count) == game._maze_zone_occupancy(str(zone.zone_id)), "S1-05 displayed count follows actual zone immediately")
	expect(int(occupancy.capacity) == int(zone.capacity), "S1-05 displayed capacity follows actual zone")
	var next_zone: Dictionary = game.graph.layout.combat_topology.defense_zones[1]
	var next_count: int = game._maze_zone_occupancy(str(next_zone.zone_id))
	expect(game._assign_monster_to_maze_zone("goblin",str(next_zone.anchor_room_id)), "S1-05 move between defense zones")
	expect(int(game._management_room_occupancy(str(zone.anchor_room_id)).count) == int(occupancy.count)-1, "S1-05 source zone display decreases immediately")
	expect(int(game._management_room_occupancy(str(next_zone.anchor_room_id)).count) == next_count+1, "S1-05 destination zone display increases immediately")
	expect(game._assign_monster_to_maze_zone("goblin",str(zone.anchor_room_id)), "S1-05 return to source zone")
	expect(game._placement_capacity_label("recovery", "goblin") == game._placement_capacity_label("recovery"), "S1-05 selecting a deployed member does not subtract displayed count")
	game.selected_room = str(zone.anchor_room_id)
	game.management_context_drawer_open = true
	game._set_screen(Constants.SCREEN_MANAGEMENT, false)
	await settle()
	expect((control("ManagementRoomOccupancy") as Label).text.contains("%d / %d" % [occupancy.count,occupancy.capacity]), "S1-05 inspector displays current zone count")
	await capture("deployment_after_move")
	var mismatches := 0
	var tiles := 0
	for room_id in game.rooms:
		for cell in game._management_room_tile_cells(room_id):
			tiles += 1
			if game.build_placement.exact_room(game.graph.tile_cell_center(cell)) != room_id: mismatches += 1
	expect(tiles > 0 and mismatches == 0, "S1-06 displayed tile centers use exact room hit test (%d tiles, %d mismatches)" % [tiles,mismatches])
	var interior_samples := 0
	for room_id in game.rooms:
		for cell in game._management_room_tile_cells(room_id):
			var rect: Rect2 = game.graph.tile_cell_rect(cell).grow(-2.0)
			for vertex in game._management_diamond(rect):
				interior_samples += 1
				if game.build_placement.exact_room(rect.get_center().lerp(vertex,0.95)) != room_id: mismatches += 1
	expect(mismatches == 0, "S1-06 displayed tile near-edge samples match exact hit (%d samples)" % interior_samples)
	game.management_context_drawer_open = false
	game.management_tool_tab = "build"
	game._set_build_facility("watch_post")
	await settle()
	var candidate := "slot_01"
	expect(game._evaluate_facility_placement(candidate,"watch_post").ok, "S1-06 displayed candidate is installable")
	var bounds: Rect2 = game.graph.rect(candidate)
	var transform: Transform2D = game.get_global_transform_with_canvas()
	var label: Rect2 = game._management_label_layout(transform * Vector2(bounds.get_center().x,bounds.end.y),"✓ 건설 구역").rect
	var label_world: Vector2 = transform.affine_inverse() * label.get_center()
	expect(game.build_placement.exact_room(label_world) != candidate, "S1-06 reproduce displayed build label outside its floor tiles")
	await capture("construction_targets")
	await click_point(label.get_center())
	expect(game.build_preview_room_id == candidate, "S1-06 displayed build label selects its own candidate")
	expect(game.build_placement.target_room(Vector2(-100000,-100000)) == "", "S1-06 arbitrary outside points still rejected")
	await settle()
	await capture("construction_candidate")
	expect(game._confirm_build_preview(), "S1-06 candidate installs through production confirmation")
	game._clear_management_action_mode(false)
	game.selected_room = "barracks"
	GameState.gold = 0
	GameState.mana = 0
	game.management_context_drawer_open = true
	game._set_screen(Constants.SCREEN_MANAGEMENT, false)
	await settle()
	var upgrade := control("FacilityUpgradeButton") as Button
	expect(upgrade != null and upgrade.disabled, "S1-07 insufficient resources disable upgrade")
	expect(upgrade != null and upgrade.tooltip_text != "", "S1-07 disabled upgrade explains reason")
	for locale in ["ko", "en", "zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		game.selected_room = "barracks"
		game.rooms.barracks.facility_level = 1
		GameState.gold = 0
		GameState.mana = 0
		game._set_screen(Constants.SCREEN_MANAGEMENT, false)
		await settle()
		upgrade = control("FacilityUpgradeButton") as Button
		var reason := control("FacilityUpgradeReason") as Label
		expect(upgrade.disabled and reason != null and reason.text == upgrade.tooltip_text, "S1-07 visible insufficient resources reason " + locale)
		await capture("upgrade_insufficient_" + locale)
		GameState.gold = 5000
		GameState.mana = 5000
		game.rooms.barracks.facility_level = game._facility_upgrade_level_cap()
		game._set_screen(Constants.SCREEN_MANAGEMENT, false)
		await settle()
		expect((control("FacilityUpgradeButton") as Button).disabled and control("FacilityUpgradeReason") != null, "S1-07 maximum level disabled " + locale)
		await capture("upgrade_maximum_" + locale)
		game.selected_room = "throne"
		game._set_screen(Constants.SCREEN_MANAGEMENT, false)
		await settle()
		expect((control("FacilityUpgradeButton") as Button).disabled and control("FacilityUpgradeReason") != null, "S1-07 fixed building disabled " + locale)
		await capture("upgrade_fixed_" + locale)
	LanguageSettings.set_locale("ko",false)
	game.selected_room = "barracks"
	game.rooms.barracks.facility_level = 1
	var gold: int = GameState.gold
	var cost: Dictionary = game._facility_upgrade_cost()
	game._set_screen(Constants.SCREEN_MANAGEMENT,false)
	await settle()
	expect(not (control("FacilityUpgradeButton") as Button).disabled, "S1-07 eligible upgrade enabled")
	await click(control("FacilityUpgradeButton"))
	expect(game._facility_upgrade_level("barracks") == 2 and GameState.gold == gold-int(cost.gold), "S1-07 eligible upgrade applies and pays exactly once")
	game.queue_free()
	await settle()
	print("V1213_STAGE_ONE_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func day_two_click() -> void:
	# Recreate the recorded occupied TUT110 target without private player data.
	var home: String = game.monster_roster.slime.room
	GameState.day = 2
	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	for i in range(game.tutorial_manager.steps.size()):
		if str(game.tutorial_manager.steps[i].get("id", "")) == "TUT_110_TRAP_CORRIDOR":
			game.tutorial_manager.current_index = i
			break
	game.tutorial_manager.active = true
	game._onboarding_set_stage("LV06_DAY02_MANAGEMENT_TREASURE")
	game.monster_roster.slime.room = "spike_corridor"
	game._set_screen(Constants.SCREEN_MANAGEMENT,false)
	await settle()
	var point: Vector2 = game.graph.center("spike_corridor")
	game.maze_deployments.slime = {"position":point,"room_id":"spike_corridor"}
	expect(game._management_monster_at(point) == "slime", "S1-03 reproduce occupied DAY2 tutorial target")
	var screen_point: Vector2 = game.get_global_transform_with_canvas() * point
	expect(not game._management_ui_at(screen_point), "S1-03 occupied tutorial target not blocked by UI")
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = screen_point
		event.global_position = screen_point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
	await settle()
	expect(game.tutorial_manager.current_step_id() == "TUT_120_TRAP_LURE" and game.dragging_monster_id == "", "S1-03 DAY2 occupied-room click advances without starting drag")
	await capture("day2_occupied_room_click")
	game.monster_roster.slime.room = home
	game._debug_skip_onboarding()
