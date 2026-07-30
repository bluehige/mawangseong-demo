extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const VIEWPORTS := [
	Vector2i(1920, 1080),
	Vector2i(1366, 768),
	Vector2i(1280, 720)
]

var game: Node
var output_dir := ""
var failed := false
var original_ui_settings: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	original_ui_settings = UISettings.snapshot()
	LanguageSettings.set_locale(LanguageSettings.LOCALE_KOREAN, false)
	UISettings.apply_snapshot({
		"text_scale": UISettings.DEFAULT_TEXT_SCALE,
		"layout_mode": UISettings.LAYOUT_AUTO,
		"tutorial_guidance_level": UISettings.TUTORIAL_GUIDANCE_FULL
	}, false)
	output_dir = ProjectSettings.globalize_path("res://tmp/v122_tutorial_guidance")
	DirAccess.make_dir_recursive_absolute(output_dir)

	DisplayServer.window_set_size(VIEWPORTS[0])
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle()

	game._open_settings_screen()
	game._select_settings_category("general")
	await _settle()
	for viewport_size in VIEWPORTS:
		await _capture_settings(viewport_size)

	game._cancel_settings_changes()
	game._onboarding_reset_game()
	game._onboarding_set_stage("LV01_NAME_ENTRY")
	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_FULL, false)
	for viewport_size in VIEWPORTS:
		await _capture_name_entry(viewport_size)

	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_CORE, false)
	await _show_step("TUT_030_SELECT_SLIME", "LV03_DAY01_MANAGEMENT_TUTORIAL", 1)
	for viewport_size in VIEWPORTS:
		await _capture_core_choice(viewport_size)

	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_OFF, false)
	game._tutorial_build_overlay()
	await _settle()
	_expect(
		game.ui_layer.find_child("TutorialOverlay", true, false) == null,
		"Off leaves the required choice screen free of tutorial overlays"
	)
	await _save("off_required_choice_1280x720.png", VIEWPORTS[2])

	game.queue_free()
	UISettings.apply_snapshot(original_ui_settings, false)
	await get_tree().process_frame
	print("V122_TUTORIAL_GUIDANCE_CAPTURE: %s" % output_dir)
	get_tree().quit(1 if failed else 0)


func _capture_settings(viewport_size: Vector2i) -> void:
	await _resize_and_rebuild(viewport_size, Constants.SCREEN_SETTINGS)
	game._select_settings_category("general")
	await _settle()
	var option := game.ui_layer.find_child("TutorialGuidanceLevelOption", true, false) as Control
	var apply_button := game.ui_layer.find_child("ApplySettingsButton", true, false) as Control
	_expect(
		option != null
		and apply_button != null
		and not option.get_global_rect().intersects(apply_button.get_global_rect()),
		"General settings controls remain separate at %dx%d" % [viewport_size.x, viewport_size.y]
	)
	await _save("settings_general_%dx%d.png" % [viewport_size.x, viewport_size.y], viewport_size)


func _capture_name_entry(viewport_size: Vector2i) -> void:
	await _resize_and_rebuild(viewport_size, Constants.SCREEN_NAME_ENTRY)
	var guide := game.ui_layer.find_child("NameEntryGuideCard", true, false) as Control
	var input := game.onboarding_name_input as Control
	var random_button := game.onboarding_name_random_button as Control
	var confirm_button := game.onboarding_name_confirm_button as Control
	var guide_rect := guide.get_global_rect() if guide != null else Rect2()
	var valid := (
		guide != null
		and input != null
		and random_button != null
		and confirm_button != null
		and Rect2(0, 0, 1920, 1080).encloses(guide_rect)
		and not guide_rect.intersects(input.get_global_rect())
		and not guide_rect.intersects(random_button.get_global_rect())
		and not guide_rect.intersects(confirm_button.get_global_rect())
	)
	_expect(valid, "Full name guidance is non-blocking at %dx%d" % [viewport_size.x, viewport_size.y])
	await _save("name_full_%dx%d.png" % [viewport_size.x, viewport_size.y], viewport_size)


func _capture_core_choice(viewport_size: Vector2i) -> void:
	await _resize_and_rebuild(viewport_size, Constants.SCREEN_MANAGEMENT)
	var overlay := game.ui_layer.find_child("TutorialOverlay", true, false) as Control
	var message := overlay.find_child("TutorialMessagePanel", true, false) as Control if overlay != null else null
	var goblin_card := game.ui_layer.find_child("MonsterCard_goblin", true, false) as Control
	var message_rect := message.get_global_rect() if message != null else Rect2()
	var goblin_rect := goblin_card.get_global_rect() if goblin_card != null else Rect2()
	print("CORE_GUIDANCE_LAYOUT %dx%d message=%s gob=%s focus=%s" % [
		viewport_size.x,
		viewport_size.y,
		message_rect,
		goblin_rect,
		game._tutorial_focus_rect("CHR_GOB")
	])
	_expect(
		message != null
		and goblin_card != null
		and Rect2(0, 0, 1920, 1080).encloses(message_rect)
		and game._tutorial_focus_rect("CHR_GOB").is_equal_approx(goblin_card.get_global_rect().grow(8.0))
		and not message_rect.intersects(goblin_rect),
		"Core required guidance stays clear of its live target at %dx%d" % [viewport_size.x, viewport_size.y]
	)
	await _save("core_required_choice_%dx%d.png" % [viewport_size.x, viewport_size.y], viewport_size)


func _resize_and_rebuild(viewport_size: Vector2i, screen_id: String) -> void:
	DisplayServer.window_set_size(viewport_size)
	await _settle()
	game._set_screen(screen_id)
	await _settle()


func _show_step(step_id: String, stage_id: String, day: int) -> void:
	var step_index := -1
	for index in range(game.tutorial_manager.steps.size()):
		if str(game.tutorial_manager.steps[index].get("id", "")) == step_id:
			step_index = index
			break
	_expect(step_index >= 0, "capture fixture contains %s" % step_id)
	if step_index < 0:
		return
	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	GameState.day = day
	game.tutorial_manager.current_index = step_index
	game.tutorial_manager.active = true
	game._onboarding_set_stage(stage_id)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle()


func _save(file_name: String, expected_size: Vector2i) -> void:
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_expect(false, "%s produces a non-empty screenshot" % file_name)
		return
	var actual_size := image.get_size()
	if absi(actual_size.x - expected_size.x) > 1 or absi(actual_size.y - expected_size.y) > 1:
		_expect(false, "%s keeps the requested viewport size" % file_name)
		return
	var error := image.save_png("%s/%s" % [output_dir, file_name])
	_expect(error == OK, "%s saves successfully" % file_name)


func _settle() -> void:
	for _index in range(8):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failed = true
	push_error("FAIL: %s" % message)
