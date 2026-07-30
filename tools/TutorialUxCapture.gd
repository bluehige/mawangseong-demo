extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""
var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	LanguageSettings.set_locale(LanguageSettings.LOCALE_KOREAN, false)
	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_FULL, false)
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
	if game.current_screen == Constants.SCREEN_INTRUSION_BRIEF:
		game._enter_placement_from_brief()
	await _settle()
	_expect_click_guidance("first management task")
	await _save("01_first_task_card.png")

	game._start_monster_placement("goblin")
	await _settle()
	if game.tutorial_manager.current_step_id() != "TUT_040_DEPLOY_SLIME" or not game._management_action_mode_active():
		push_error("Real monster-roster flow did not reach the room deployment step")
		failed = true
	_expect_formation_guidance("Gob front-or-rear formation task")
	await _save("02_goblin_formation_task_card.png")
	await _capture_goblin_formation_variant(Vector2i(1366, 768), "02a_goblin_formation_1366x768.png")
	await _capture_goblin_formation_variant(Vector2i(1280, 720), "02b_goblin_formation_1280x720.png")
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await _settle()
	game._handle_left_click(game.graph.center("recovery"))
	await _drain_dialogue()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle()
	_expect_day1_controls_complete()
	await _save("05_day1_controls_complete.png")

	await _reset_game()
	await _show_tutorial_step("TUT_110_TRAP_CORRIDOR", "LV06_DAY02_MANAGEMENT_TREASURE", "entrance", 2)
	_expect_click_guidance("DAY 02 spike corridor room task")
	await _save("08a_day2_spike_corridor_target.png")

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

func _capture_goblin_formation_variant(viewport_size: Vector2i, file_name: String) -> void:
	DisplayServer.window_set_size(viewport_size)
	await _settle()
	var label := "Gob formation %dx%d compact layout" % [viewport_size.x, viewport_size.y]
	_expect_formation_guidance(label)
	_expect_formation_layout(label, "compact")
	await _save(file_name, viewport_size)


func _save(file_name: String, expected_size: Vector2i = Vector2i(1920, 1080)) -> void:
	await get_tree().process_frame
	var image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Tutorial capture is empty: %s" % file_name)
		failed = true
		return
	var actual_size := image.get_size()
	var size_delta := actual_size - expected_size
	if absi(size_delta.x) > 1 or absi(size_delta.y) > 1:
		push_error("Tutorial capture size mismatch: %s expected=%s actual=%s window=%s" % [
			file_name,
			expected_size,
			actual_size,
			DisplayServer.window_get_size()
		])
		failed = true
		return
	if actual_size != expected_size:
		print("NOTE: %s uses aspect-fit content size %s inside window %s" % [
			file_name,
			actual_size,
			DisplayServer.window_get_size()
		])
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
	var drawer = game.ui_layer.find_child("ManagementContextDrawer", true, false) as Control
	var close_button = drawer.find_child("CloseManagementContextButton", true, false) as Control if drawer != null else null
	var drawer_top_z: int = drawer.z_index + (close_button.z_index if close_button != null else 0) if drawer != null else -1
	var valid = (
		overlay != null
		and ring != null
		and badge != null
		and message != null
		and badge.size.x >= 300.0
		and not badge.get_global_rect().intersects(message.get_global_rect())
		and (drawer == null or overlay.z_index > drawer_top_z)
		and (drawer == null or not message.get_global_rect().intersects(drawer.get_global_rect()))
	)
	if valid:
		print("PASS: %s click guidance" % label)
	else:
		push_error("FAIL: %s click guidance (overlay=%s ring=%s badge=%s message=%s badge_rect=%s message_rect=%s overlap=%s overlay_z=%s drawer_top_z=%s drawer_overlap=%s)" % [
			label,
			overlay != null,
			ring != null,
			badge != null,
			message != null,
			badge.get_global_rect() if badge != null else Rect2(),
			message.get_global_rect() if message != null else Rect2(),
			badge.get_global_rect().intersects(message.get_global_rect()) if badge != null and message != null else false,
			overlay.z_index if overlay != null else -1,
			drawer_top_z,
			message.get_global_rect().intersects(drawer.get_global_rect()) if message != null and drawer != null else false
		])
		failed = true


func _expect_formation_guidance(label: String) -> void:
	var overlay = game.ui_layer.find_child("TutorialOverlay", true, false)
	var ring = overlay.find_child("TutorialFocusOuter", true, false) if overlay != null else null
	var badge = overlay.find_child("TutorialClickBadge", true, false) if overlay != null else null
	var focus_rect: Rect2 = game._tutorial_focus_rect("DAY1_GOBLIN_FORMATION")
	var valid: bool = (
		overlay != null
		and ring != null
		and badge == null
		and focus_rect.encloses(game._tutorial_room_rect("barracks"))
		and focus_rect.encloses(game._tutorial_room_rect("recovery"))
	)
	if valid:
		print("PASS: %s" % label)
	else:
		push_error("FAIL: %s" % label)
		failed = true


func _expect_formation_layout(label: String, expected_layout_mode: String) -> void:
	var overlay = game.ui_layer.find_child("TutorialOverlay", true, false)
	var ring = overlay.find_child("TutorialFocusOuter", true, false) as Control if overlay != null else null
	var message = overlay.find_child("TutorialMessagePanel", true, false) as Control if overlay != null else null
	var drawer = game.ui_layer.find_child("ManagementContextDrawer", true, false) as Control
	var roster_dock = game.ui_layer.find_child("MonsterRosterDock", true, false) as Control
	var gob_card = game.ui_layer.find_child("MonsterCard_goblin", true, false) as Control
	var front_rect: Rect2 = game._tutorial_room_rect("barracks").grow(24.0)
	var rear_rect: Rect2 = game._tutorial_room_rect("recovery").grow(24.0)
	var message_rect := message.get_global_rect() if message != null else Rect2()
	var gob_card_rect := gob_card.get_global_rect() if gob_card != null else Rect2()
	var rear_room_rect: Rect2 = game.graph.rect("recovery")
	var rear_label_rect := Rect2(
		Vector2(rear_room_rect.get_center().x - 74.0, rear_room_rect.end.y + 4.0),
		Vector2(148.0, 22.0)
	)
	var label_inside_focus := ring != null and ring.get_global_rect().grow(-10.0).encloses(rear_label_rect)
	var valid: bool = (
		UISettings.effective_layout_mode() == expected_layout_mode
		and ring != null
		and message != null
		and roster_dock != null
		and gob_card != null
		and gob_card.visible
		and not gob_card.disabled
		and label_inside_focus
		and not message_rect.intersects(front_rect)
		and not message_rect.intersects(rear_rect)
		and not message_rect.intersects(gob_card_rect)
		and (drawer == null or not message_rect.intersects(drawer.get_global_rect()))
	)
	if valid:
		print("PASS: %s card, targets, and guidance placement" % label)
	else:
		push_error("FAIL: %s card, targets, and guidance placement (layout=%s message=%s gob=%s label_inside_focus=%s front_overlap=%s rear_overlap=%s gob_overlap=%s drawer_overlap=%s)" % [
			label,
			UISettings.effective_layout_mode(),
			message_rect,
			gob_card_rect,
			label_inside_focus,
			message_rect.intersects(front_rect),
			message_rect.intersects(rear_rect),
			message_rect.intersects(gob_card_rect),
			message_rect.intersects(drawer.get_global_rect()) if drawer != null else false
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
