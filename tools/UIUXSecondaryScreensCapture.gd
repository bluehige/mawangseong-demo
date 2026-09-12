extends "res://tools/UIUXLateScreensCapture.gd"
const Fixture = preload("res://tools/UIUXSecondaryFixture.gd")
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	dir = ProjectSettings.globalize_path("res://tmp/uiux_secondary/" + (args[0] if not args.is_empty() else "after"))
	DirAccess.make_dir_recursive_absolute(dir)
	game = Game.instantiate()
	add_child(game)
	await frames()
	Fixture.prepare(game)
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale_value in [0.9,1.0,1.15]:
			UISettings.text_scale = scale_value
			var tag := "_%dx%d_%d" % [resolution.x,resolution.y,roundi(scale_value*100)]
			for target in [C.SCREEN_CYCLE_DOCTRINE,C.SCREEN_CYCLE_DECREE,C.SCREEN_CHALLENGE_SEAL,C.SCREEN_ENDING_ARCHIVE,C.SCREEN_OUTPOST_MANAGEMENT]:
				game._set_screen(target)
				await shot(str(target)+tag)
			game.selected_contract_ids.clear()
			game.contract_board_pending_ids.clear()
			game._set_screen(C.SCREEN_CONTRACT_BOARD)
			await shot("contract_selection"+tag)
			game.selected_contract_ids.assign(["spore_healer","stone_sentinel"])
			game.deployed_instance_ids.assign(["mon_contract_mori","mon_contract_dolkong","mon_core_pudding"])
			game._set_screen(C.SCREEN_CONTRACT_BOARD)
			await shot("contract_roster"+tag)
			var built: Dictionary = game.update4_active_run.outpost.duplicate(true)
			game.update4_active_run.outpost = {}
			game._set_screen(C.SCREEN_OUTPOST_MANAGEMENT)
			await shot("outpost_selection"+tag)
			game.update4_active_run.outpost = built
	game.queue_free()
	await frames(3)
	get_tree().quit()
