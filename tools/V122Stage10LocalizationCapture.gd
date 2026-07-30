extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const VIEWPORTS := [
	Vector2i(1920, 1080),
	Vector2i(1366, 768),
	Vector2i(1280, 720)
]
const LOCALES := ["ko", "en"]

var game: Node
var output_dir := ""
var failed := false
var original_language: Dictionary = {}
var original_ui_settings: Dictionary = {}
var original_tutorial_history: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	original_language = LanguageSettings.snapshot()
	original_ui_settings = UISettings.snapshot()
	original_tutorial_history = TutorialGuidanceHistory.snapshot()
	TutorialGuidanceHistory.reset(false)
	UISettings.apply_snapshot({
		"text_scale": UISettings.DEFAULT_TEXT_SCALE,
		"layout_mode": UISettings.LAYOUT_AUTO,
		"tutorial_guidance_level": UISettings.TUTORIAL_GUIDANCE_FULL
	}, false)
	output_dir = ProjectSettings.globalize_path("res://tmp/v122_stage10_localization")
	DirAccess.make_dir_recursive_absolute(output_dir)

	DisplayServer.window_set_size(VIEWPORTS[0])
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle()

	for locale_id in LOCALES:
		LanguageSettings.set_locale(locale_id, false)
		await _capture_locale(locale_id)

	game.queue_free()
	LanguageSettings.apply_snapshot(original_language, false)
	UISettings.apply_snapshot(original_ui_settings, false)
	TutorialGuidanceHistory.apply_snapshot(original_tutorial_history, false)
	await get_tree().process_frame
	print("V122_STAGE10_LOCALIZATION_CAPTURE: %s" % output_dir)
	get_tree().quit(1 if failed else 0)


func _capture_locale(locale_id: String) -> void:
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	for category_id in ["general", "display", "audio"]:
		game.settings_category = category_id
		for viewport_size in VIEWPORTS:
			await _resize_and_rebuild(viewport_size, Constants.SCREEN_SETTINGS)
			var category_ready := false
			match category_id:
				"general":
					var language_option := game.ui_layer.find_child("LanguageOption", true, false) as OptionButton
					category_ready = (
						language_option != null
						and str(language_option.get_selected_metadata()) == locale_id
					)
				"display":
					category_ready = game.ui_layer.find_child("LayoutModeOption", true, false) != null
				_:
					category_ready = game.ui_layer.find_children("*", "HSlider", true, false).size() == 3
			_expect(
				category_ready,
				"%s %s settings builds its live controls at %dx%d" % [
					locale_id,
					category_id,
					viewport_size.x,
					viewport_size.y
				]
			)
			await _save(
				"%s_settings_%s_%dx%d.png" % [
					locale_id,
					category_id,
					viewport_size.x,
					viewport_size.y
				],
				viewport_size
			)

	game._onboarding_reset_game()
	game._onboarding_set_stage("LV01_NAME_ENTRY")
	for viewport_size in VIEWPORTS:
		await _resize_and_rebuild(viewport_size, Constants.SCREEN_NAME_ENTRY)
		var guide := game.ui_layer.find_child("NameEntryGuideCard", true, false) as Control
		var input := game.onboarding_name_input as Control
		_expect(
			guide != null
			and input != null
			and not guide.get_global_rect().intersects(input.get_global_rect()),
			"%s name guide stays clear of the live input at %dx%d" % [
				locale_id,
				viewport_size.x,
				viewport_size.y
			]
		)
		await _save(
			"%s_name_full_%dx%d.png" % [locale_id, viewport_size.x, viewport_size.y],
			viewport_size
		)

	await _capture_tutorial_step(
		locale_id,
		"TUT_030_SELECT_SLIME",
		"LV03_DAY01_MANAGEMENT_TUTORIAL",
		1,
		"day1_select_gob"
	)
	await _capture_tutorial_step(
		locale_id,
		"TUT_130_GOBLIN_CONTROL",
		"LV07_DAY02_BATTLE_THIEF",
		2,
		"day2_goblin_observation"
	)
	await _capture_tutorial_step(
		locale_id,
		"TUT_210_RECOVERY_NEST",
		"LV09_DAY03_MANAGEMENT_HERO",
		3,
		"day3_recovery_choice"
	)


func _capture_tutorial_step(
	locale_id: String,
	step_id: String,
	stage_id: String,
	day: int,
	file_stem: String
) -> void:
	await _show_step(step_id, stage_id, day)
	for viewport_size in VIEWPORTS:
		await _resize_and_rebuild(viewport_size, Constants.SCREEN_MANAGEMENT)
		var overlay := game.ui_layer.find_child("TutorialOverlay", true, false) as Control
		var message := overlay.find_child("TutorialMessagePanel", true, false) as Control if overlay != null else null
		var badge := overlay.find_child("TutorialClickBadge", true, false) as Control if overlay != null else null
		var drawer := game.ui_layer.find_child("ManagementContextDrawer", true, false) as Control
		var step: Dictionary = game.tutorial_manager.current_step()
		var focus_rect: Rect2 = game._tutorial_focus_rect(game._tutorial_effective_focus_id(step))
		var clears_click_target: bool = (
			game._tutorial_step_is_observation(step)
			or not focus_rect.has_area()
			or (message != null and not message.get_global_rect().intersects(focus_rect))
		)
		_expect(
			message != null
			and Rect2(0, 0, 1920, 1080).encloses(message.get_global_rect()),
			"%s %s message remains inside the design canvas at %dx%d" % [
				locale_id,
				step_id,
				viewport_size.x,
				viewport_size.y
			]
		)
		_expect(
			clears_click_target,
			"%s %s message stays clear of its click target at %dx%d" % [
				locale_id,
				step_id,
				viewport_size.x,
				viewport_size.y
			]
		)
		_expect(
			badge == null
			or drawer == null
			or not badge.get_global_rect().intersects(drawer.get_global_rect()),
			"%s %s click badge stays clear of the context drawer at %dx%d" % [
				locale_id,
				step_id,
				viewport_size.x,
				viewport_size.y
			]
		)
		await _save(
			"%s_%s_%dx%d.png" % [locale_id, file_stem, viewport_size.x, viewport_size.y],
			viewport_size
		)


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


func _resize_and_rebuild(viewport_size: Vector2i, screen_id: String) -> void:
	DisplayServer.window_set_size(viewport_size)
	await _settle()
	game._set_screen(screen_id)
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
