extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var failed := false
var output_dir := ""

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://tmp/directive_combat_ui_review")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var original_text_scale := UISettings.text_scale
	UISettings.set_text_scale(UISettings.MAX_TEXT_SCALE, false)
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game._debug_skip_onboarding()
	GameState.day = 1
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(4)
	await _save("01_management_max_font.png")
	game._start_combat()
	await _settle(5)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "combat screen opens for the visual check")
	game.onboarding_enabled = true
	GameState.onboarding_complete = true
	game.combat_speed_intro_seen = false
	game._set_screen(Constants.SCREEN_COMBAT)
	await _settle(4)
	_check_speed_intro_contract()
	await _save("02_speed_intro_1920_max_font.png")
	game._dismiss_combat_speed_intro()
	game.onboarding_enabled = false
	if not game.combat_paused:
		game._toggle_pause()
	if game.selected_unit == null and not game.monster_units.is_empty():
		game._select_unit(game.monster_units[0])
		game._set_screen(Constants.SCREEN_COMBAT)
	await _settle(8)
	_check_directive_combat_contract()
	await _save("03_combat_1920_max_font.png")
	await _set_window_size(Vector2i(1366, 768))
	game._set_screen(Constants.SCREEN_COMBAT)
	await _settle(8)
	_check_directive_combat_contract()
	await _save("04_combat_1366_max_font.png")
	await _set_window_size(Vector2i(1280, 720))
	game._set_screen(Constants.SCREEN_COMBAT)
	await _settle(8)
	_check_directive_combat_contract()
	await _save("05_combat_1280_max_font.png")
	UISettings.set_text_scale(original_text_scale, false)
	print("DIRECTIVE_COMBAT_UI_VISUAL_CHECK: %s" % ("FAIL" if failed else "PASS"))
	print("DIRECTIVE_COMBAT_UI_VISUAL_CHECK_OUTPUT: %s" % output_dir)
	get_tree().quit(1 if failed else 0)

func _check_directive_combat_contract() -> void:
	_expect(game.ui_layer.find_child("DirectControlButton", true, false) == null, "single-unit direct button is absent")
	_expect(game.ui_layer.find_child("SkillSlot0", true, false) == null, "manual skill button is absent")
	game._set_speed(9.0)
	_expect(is_equal_approx(game.combat_speed, 3.0), "combat speed is capped at x3")
	for unit in game.monster_units + game.enemy_units:
		_expect(unit.collision_layer == 0 and unit.collision_mask == 0, "%s has no physics collision routing" % unit.display_name)
		_expect(unit.find_child("CollisionShape2D", true, false) == null, "%s has no movement collision shape" % unit.display_name)
		_expect(is_equal_approx(unit.simulation_speed, 3.0), "%s follows x3 simulation speed" % unit.display_name)
	var speed_button := _find_button_by_text(game.ui_layer, "x3")
	_expect(speed_button != null, "x3 speed button is visible")
	if UISettings.is_touch_ui():
		var mobile_bar = game.ui_layer.find_child("MobileCombatBar", true, false)
		_expect(mobile_bar != null, "mobile directive bar is visible")
		if mobile_bar != null:
			_expect(_direct_children_fit(mobile_bar), "mobile directive controls fit inside their panel")
	else:
		var command_buttons: Array[Button] = []
		for text_value in ["사수", "총공격", "생존 우선", "집중 방어", "함정 유도", "후퇴 지점"]:
			var command_button := _find_button_by_text(game.ui_layer, text_value)
			if command_button != null:
				command_buttons.append(command_button)
		_expect(command_buttons.size() == 6, "all six directive buttons are visible")
		_expect(not _controls_overlap(command_buttons), "desktop directive buttons do not overlap")

func _check_speed_intro_contract() -> void:
	var intro = game.ui_layer.get_node_or_null("CombatSpeedFeatureIntro")
	var confirm_button := _find_button_by_text(game.ui_layer, "확인하고 전투 재개")
	_expect(intro != null, "post-tutorial speed introduction is visible")
	_expect(game.combat_speed_intro_open and game.combat_paused, "speed introduction pauses combat")
	_expect(confirm_button != null and Rect2(Vector2.ZERO, Vector2(1920, 1080)).encloses(confirm_button.get_global_rect()), "speed introduction confirmation fits inside the screen")

func _direct_children_fit(parent: Control) -> bool:
	var bounds := Rect2(Vector2.ZERO, parent.size)
	for child in parent.get_children():
		if child is Button and not bounds.encloses(Rect2(child.position, child.size)):
			return false
	return true

func _controls_overlap(controls: Array[Button]) -> bool:
	for index in range(controls.size()):
		for other_index in range(index + 1, controls.size()):
			if controls[index].get_global_rect().intersects(controls[other_index].get_global_rect()):
				return true
	return false

func _find_button_by_text(node: Node, text_value: String) -> Button:
	if node is Button and node.text == text_value:
		return node
	for child in node.get_children():
		var result := _find_button_by_text(child, text_value)
		if result != null:
			return result
	return null

func _set_window_size(value: Vector2i) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(value)
	get_window().size = value
	await _settle(6)

func _save(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var output_name := ("mobile_" if UISettings.is_touch_ui() else "desktop_") + file_name
	if image == null or image.is_empty() or image.save_png(output_dir.path_join(output_name)) != OK:
		_expect(false, "%s capture is written" % file_name)

func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		failed = true
		push_error("FAIL: %s" % message)
