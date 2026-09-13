extends "res://tools/UIUXBuildPlacementTest.gd"
const Fixture = preload("res://tools/UIUXSecondaryFixture.gd")
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	output = "res://tmp/uiux_art_direction/" + (args[0] if not args.is_empty() else "after")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	game = Game.instantiate()
	add_child(game)
	await settle()
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.story_feature_enabled = false
	GameState.day = 2
	game._choose_early_specialization("goblin","goblin_treasure_hunter")
	var initial_rooms: Dictionary = game.rooms.duplicate(true)
	var initial_roster: Dictionary = game.monster_roster.duplicate(true)
	var initial_deployed: Array = game.deployed_instance_ids.duplicate()
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale_value in [0.9,1.0,1.15]:
			UISettings.text_scale = scale_value
			var tag := "%dx%d_%d_" % [resolution.x,resolution.y,roundi(scale_value*100)]
			for stage in ["stage_01_cave","stage_02_castle","stage_03_keep","stage_04_citadel"]:
				game.rooms = initial_rooms.duplicate(true)
				game.monster_roster = initial_roster.duplicate(true)
				game.castle_art_stage = stage
				game._sync_castle_stage_content()
				game._refresh_quarter_map_from_rooms()
				game.management_context_drawer_open = false
				game.management_tool_tab = "build"
				game._set_screen(Constants.SCREEN_MANAGEMENT)
				await capture(tag+stage)
			# Later-screen fixture changes deployment; restore the starter roster for this portrait capture.
			game.deployed_instance_ids.assign(initial_deployed)
			game.selected_monster_id = "goblin"
			check(game._defense_monster_ids().size() == 3, tag+"portrait fixture restores three core companions")
			game._set_screen(Constants.SCREEN_MONSTER)
			await capture(tag+"monster")
			game._set_screen(Constants.SCREEN_TITLE)
			await capture(tag+"title")
			game._open_settings_screen()
			await capture(tag+"settings")
			Fixture.prepare(game)
			game._set_screen(Constants.SCREEN_CYCLE_DOCTRINE)
			await capture(tag+"doctrine")
			game._set_screen(Constants.SCREEN_OUTPOST_MANAGEMENT)
			await capture(tag+"outpost")
			print("UIUX_TEXTURE_MEMORY_BYTES ",tag," ",Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	game.queue_free()
	await settle()
	finish()
