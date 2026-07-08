extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	output_dir = ProjectSettings.globalize_path("res://tmp/tutorial_ux_verification")
	DirAccess.make_dir_recursive_absolute(output_dir)

	game = GameRootScene.instantiate()
	add_child(game)
	await _settle()
	await _save("00_title.png")
	game._onboarding_start_new_game()
	await _settle()
	game.onboarding_name_input.text = "QA"
	game._onboarding_confirm_name()
	await _drain_dialogue()
	await _settle()
	await _save("01_first_task_card.png")

	game._select_monster("slime")
	await _drain_dialogue()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle()
	await _save("02_deploy_task_card.png")
	game._assign_monster_to_room("slime", "entrance")
	await _settle()
	game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
	await _settle()
	await _save("05_room_block_task_card.png")

	await _reset_game()
	game._debug_skip_onboarding()
	GameState.day = 1
	GameState.victory = false
	GameState.defeat = false
	game.result_summary = {
		"win": true,
		"lines": [
			"침입자 격퇴",
			"금화 +35",
			"마력 +12"
		]
	}
	game.last_growth_summary = [
		{"monster_id": "slime", "display_name": "슬라임", "level_before": 1, "level_after": 2, "levels_gained": 1, "exp_before": 44, "exp_after": 6, "exp_gain": 12, "next_exp": 80},
		{"monster_id": "goblin", "display_name": "고블린", "level_before": 1, "level_after": 1, "levels_gained": 0, "exp_before": 18, "exp_after": 31, "exp_gain": 13, "next_exp": 50},
		{"monster_id": "imp", "display_name": "임프", "level_before": 1, "level_after": 1, "levels_gained": 0, "exp_before": 8, "exp_after": 22, "exp_gain": 14, "next_exp": 50}
	]
	game.result_growth_reviewed = false
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle()
	await _save("04_result_growth_panel.png")

	await _reset_game()
	game._debug_skip_onboarding()
	game._select_room("throne")
	await _settle()
	await _save("03_throne_sw_management.png")

	await _reset_game()
	game._debug_skip_onboarding()
	game._select_room("slot_01")
	game.facility_change_panel_open = true
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle()
	await _save("06_facility_change_modal.png")

	await _reset_game()
	game._debug_skip_onboarding()
	game._open_monster_screen()
	await _settle()
	await _save("07_monster_screen.png")

	print("TUTORIAL_UX_CAPTURE: %s" % output_dir)
	get_tree().quit(0)

func _drain_dialogue(max_steps: int = 180) -> void:
	var quiet_frames := 0
	for _i in range(max_steps):
		await get_tree().process_frame
		if game.current_screen == Constants.SCREEN_DIALOGUE:
			quiet_frames = 0
			game._onboarding_advance_dialogue()
		else:
			quiet_frames += 1
			if quiet_frames >= 5:
				return
	push_error("Timed out while draining dialogue")

func _reset_game() -> void:
	remove_child(game)
	game.queue_free()
	await _settle()
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle()

func _settle() -> void:
	for _i in range(8):
		await get_tree().process_frame

func _save(file_name: String) -> void:
	await get_tree().process_frame
	var image = get_viewport().get_texture().get_image()
	var path = "%s/%s" % [output_dir, file_name]
	var err = image.save_png(path)
	if err != OK:
		push_error("Failed to save screenshot: %s" % path)
