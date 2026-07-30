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
var assertion_count := 0
var original_language: Dictionary = {}
var original_ui_settings: Dictionary = {}
var original_tutorial_history: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	original_language = LanguageSettings.snapshot()
	original_ui_settings = UISettings.snapshot()
	original_tutorial_history = TutorialGuidanceHistory.snapshot()
	UISettings.apply_snapshot({
		"text_scale": UISettings.DEFAULT_TEXT_SCALE,
		"layout_mode": UISettings.LAYOUT_AUTO,
		"tutorial_guidance_level": UISettings.TUTORIAL_GUIDANCE_FULL
	}, false)
	output_dir = ProjectSettings.globalize_path("res://tmp/v122_tutorial_practice")
	DirAccess.make_dir_recursive_absolute(output_dir)

	DisplayServer.window_set_size(VIEWPORTS[0])
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle()

	for locale_id in LOCALES:
		await _capture_locale(locale_id)

	game.queue_free()
	LanguageSettings.apply_snapshot(original_language, false)
	UISettings.apply_snapshot(original_ui_settings, false)
	TutorialGuidanceHistory.apply_snapshot(original_tutorial_history, false)
	await get_tree().process_frame
	print("V122_TUTORIAL_PRACTICE_CAPTURE: %s, %d checks" % [output_dir, assertion_count])
	get_tree().quit(1 if failed else 0)


func _capture_locale(locale_id: String) -> void:
	LanguageSettings.set_locale(locale_id, false)
	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_FULL, false)
	TutorialGuidanceHistory.apply_snapshot({
		"dismissed_help_ids": [TutorialGuidanceHistory.NAME_ENTRY_GUIDE_ID]
	}, false)
	game._open_settings_screen()
	game._select_settings_category("general")
	await _settle()
	for viewport_size in VIEWPORTS:
		await _resize_and_rebuild(viewport_size, Constants.SCREEN_SETTINGS)
		_expect_settings_layout(locale_id, viewport_size, false)
		await _save(
			"%s_settings_history_%dx%d.png" % [locale_id, viewport_size.x, viewport_size.y],
			viewport_size
		)

	game._reset_tutorial_guidance_history()
	await _settle()
	for viewport_size in VIEWPORTS:
		await _resize_and_rebuild(viewport_size, Constants.SCREEN_SETTINGS)
		_expect_settings_layout(locale_id, viewport_size, true)
		await _save(
			"%s_settings_history_pending_%dx%d.png" % [locale_id, viewport_size.x, viewport_size.y],
			viewport_size
		)

	game._start_tutorial_practice()
	game._tutorial_practice_next()
	game._tutorial_practice_next()
	await _settle()
	for viewport_size in VIEWPORTS:
		await _resize_and_rebuild(viewport_size, Constants.SCREEN_TUTORIAL_PRACTICE)
		_expect_practice_layout(locale_id, viewport_size)
		await _save(
			"%s_practice_day1_gob_%dx%d.png" % [locale_id, viewport_size.x, viewport_size.y],
			viewport_size
		)
	game._close_tutorial_practice()
	game._cancel_settings_changes()
	await _settle()


func _expect_settings_layout(locale_id: String, viewport_size: Vector2i, pending: bool) -> void:
	var practice_button := game.ui_layer.find_child("TutorialPracticeButton", true, false) as Control
	var reset_button := game.ui_layer.find_child("ResetTutorialHistoryButton", true, false) as Button
	var status_label := game.ui_layer.find_child("TutorialHistoryStatusLabel", true, false) as Label
	_expect(
		practice_button != null
		and reset_button != null
		and status_label != null
		and _inside_design_canvas(practice_button)
		and _inside_design_canvas(reset_button)
		and not practice_button.get_global_rect().intersects(reset_button.get_global_rect()),
		"%s settings actions stay separated inside the design canvas at %dx%d" % [
			locale_id,
			viewport_size.x,
			viewport_size.y
		]
	)
	_expect(
		status_label != null
		and (
			status_label.text.contains("적용")
			or status_label.text.contains("Apply")
		) == pending,
		"%s history status matches the pending state at %dx%d" % [
			locale_id,
			viewport_size.x,
			viewport_size.y
		]
	)


func _expect_practice_layout(locale_id: String, viewport_size: Vector2i) -> void:
	var card := game.ui_layer.find_child("TutorialPracticeCard", true, false) as Control
	var step_id := game.ui_layer.find_child("TutorialPracticeStepIdLabel", true, false) as Label
	var exit_button := game.ui_layer.find_child("TutorialPracticeExitButton", true, false) as Control
	var previous_button := game.ui_layer.find_child("TutorialPracticePreviousButton", true, false) as Control
	var next_button := game.ui_layer.find_child("TutorialPracticeNextButton", true, false) as Control
	_expect(
		game.tutorial_practice.current_step_id() == "TUT_030_SELECT_SLIME"
		and card != null
		and step_id != null
		and step_id.text == "TUT_030_SELECT_SLIME",
		"%s practice keeps the legacy Gob step ID at %dx%d" % [
			locale_id,
			viewport_size.x,
			viewport_size.y
		]
	)
	_expect(
		card != null
		and exit_button != null
		and previous_button != null
		and next_button != null
		and _inside_design_canvas(card)
		and _inside_design_canvas(exit_button)
		and _inside_design_canvas(previous_button)
		and _inside_design_canvas(next_button)
		and not exit_button.get_global_rect().intersects(previous_button.get_global_rect())
		and not previous_button.get_global_rect().intersects(next_button.get_global_rect()),
		"%s practice workspace and navigation stay inside the design canvas at %dx%d" % [
			locale_id,
			viewport_size.x,
			viewport_size.y
		]
	)


func _inside_design_canvas(control: Control) -> bool:
	return Rect2(0, 0, 1920, 1080).encloses(control.get_global_rect())


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
	assertion_count += 1
	if condition:
		print("PASS: %s" % message)
		return
	failed = true
	push_error("FAIL: %s" % message)
