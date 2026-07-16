extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""
var failed := false

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
	_expect_click_guidance("first management task")
	await _save("01_first_task_card.png")

	game._select_monster("slime")
	await _drain_dialogue()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._assign_monster_to_room("slime", "entrance")
	await _drain_dialogue()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle()
	_expect_click_guidance("global defense task")
	await _save("02_global_defense_task_card.png")
	game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
	await _drain_dialogue()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle()
	_expect_day1_controls_complete()
	await _save("05_day1_controls_complete.png")

	await _reset_game()
	await _show_tutorial_step("TUT_120_TRAP_LURE", "LV06_DAY02_MANAGEMENT_TREASURE", "spike_corridor", 2)
	_expect_click_guidance("DAY 02 trap lure task")
	_expect_live_directive_alignment("DAY 02 trap lure task")
	await _save("08_day2_trap_lure_task.png")

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
	get_tree().quit(1 if failed else 0)

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

func _show_tutorial_step(step_id: String, stage_id: String, room_id: String, day: int) -> void:
	var step_index := -1
	for index in range(game.tutorial_manager.steps.size()):
		if str(game.tutorial_manager.steps[index].get("id", "")) == step_id:
			step_index = index
			break
	if step_index < 0:
		push_error("Tutorial capture step is missing: %s" % step_id)
		failed = true
		return
	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	GameState.day = day
	game.tutorial_manager.current_index = step_index
	game.tutorial_manager.active = true
	game._onboarding_set_stage(stage_id)
	game.selected_room = room_id
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle()

func _save(file_name: String) -> void:
	await get_tree().process_frame
	var image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty() or image.get_width() < 1919 or image.get_height() < 1079:
		push_error("Tutorial capture is incomplete: %s" % file_name)
		failed = true
		return
	var path = "%s/%s" % [output_dir, file_name]
	var err = image.save_png(path)
	if err != OK:
		push_error("Failed to save screenshot: %s" % path)
		failed = true

func _expect_click_guidance(label: String) -> void:
	var overlay = game.ui_layer.find_child("TutorialOverlay", true, false)
	var ring = overlay.find_child("TutorialFocusOuter", true, false) if overlay != null else null
	var badge = overlay.find_child("TutorialClickBadge", true, false) if overlay != null else null
	var message = overlay.find_child("TutorialMessagePanel", true, false) if overlay != null else null
	var valid = (
		overlay != null
		and ring != null
		and badge != null
		and message != null
		and badge.size.x >= 300.0
		and not badge.get_global_rect().intersects(message.get_global_rect())
	)
	if valid:
		print("PASS: %s click guidance" % label)
	else:
		push_error("FAIL: %s click guidance (overlay=%s ring=%s badge=%s message=%s badge_rect=%s message_rect=%s overlap=%s)" % [
			label,
			overlay != null,
			ring != null,
			badge != null,
			message != null,
			badge.get_global_rect() if badge != null else Rect2(),
			message.get_global_rect() if message != null else Rect2(),
			badge.get_global_rect().intersects(message.get_global_rect()) if badge != null and message != null else false
		])
		failed = true

func _expect_live_directive_alignment(label: String) -> void:
	var control = game.ui_layer.find_child("SelectedRoomDirectiveOption", true, false) as OptionButton
	var overlay = game.ui_layer.find_child("TutorialOverlay", true, false)
	var ring = overlay.find_child("TutorialFocusOuter", true, false) as Panel if overlay != null else null
	var valid := control != null and ring != null
	if valid:
		var expected_rect := control.get_global_rect().grow(22.0)
		valid = ring.get_global_rect().is_equal_approx(expected_rect)
	if valid:
		print("PASS: %s live target alignment" % label)
	else:
		push_error("FAIL: %s live target alignment" % label)
		failed = true

func _expect_day1_controls_complete() -> void:
	var overlay = game.ui_layer.find_child("TutorialOverlay", true, false)
	var valid = game.tutorial_manager.current_step_id() == "TUT_090_RESULT_GROWTH" and overlay == null
	if valid:
		print("PASS: simplified DAY 01 controls finish without stale guidance")
	else:
		push_error("FAIL: simplified DAY 01 controls completion (step=%s overlay=%s)" % [game.tutorial_manager.current_step_id(), overlay != null])
		failed = true
