extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false
var original_ui_settings: Dictionary = {}
var original_tutorial_history: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	original_ui_settings = UISettings.snapshot()
	original_tutorial_history = TutorialGuidanceHistory.snapshot()
	TutorialGuidanceHistory.reset(false)
	LanguageSettings.set_locale(LanguageSettings.LOCALE_KOREAN, false)
	UISettings.apply_snapshot({
		"text_scale": UISettings.DEFAULT_TEXT_SCALE,
		"layout_mode": UISettings.DEFAULT_LAYOUT_MODE,
		"tutorial_guidance_level": "invalid"
	}, false)
	_expect(
		UISettings.tutorial_guidance_level == UISettings.TUTORIAL_GUIDANCE_FULL,
		"invalid tutorial level falls back to Full"
	)
	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_CORE, false)
	_expect(
		str(UISettings.snapshot().get("tutorial_guidance_level", "")) == UISettings.TUTORIAL_GUIDANCE_CORE,
		"tutorial level participates in the device settings snapshot"
	)
	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_FULL, false)

	var game = GameRootScene.instantiate()
	add_child(game)
	await _settle()

	game._open_settings_screen()
	await _settle()
	var general_category := game.ui_layer.find_child("SettingsCategory_general", true, false) as Button
	_expect(
		general_category != null,
		"settings navigation exposes the implemented General category"
	)
	game._select_settings_category("general")
	await _settle()
	general_category = game.ui_layer.find_child("SettingsCategory_general", true, false) as Button
	var guidance_option := game.ui_layer.find_child("TutorialGuidanceLevelOption", true, false) as OptionButton
	_expect(
		general_category != null and str(general_category.get_meta("ui_semantic_state", "")) == "selected",
		"General category opens as the selected settings page"
	)
	_expect(
		guidance_option != null and _option_values(guidance_option) == [
			UISettings.TUTORIAL_GUIDANCE_FULL,
			UISettings.TUTORIAL_GUIDANCE_CORE,
			UISettings.TUTORIAL_GUIDANCE_OFF
		],
		"settings exposes Full, Core only, and Off in the fixed order"
	)
	game._on_tutorial_guidance_preview_changed(UISettings.TUTORIAL_GUIDANCE_CORE)
	await _settle()
	guidance_option = game.ui_layer.find_child("TutorialGuidanceLevelOption", true, false) as OptionButton
	_expect(
		UISettings.tutorial_guidance_level == UISettings.TUTORIAL_GUIDANCE_CORE
		and guidance_option != null
		and str(guidance_option.get_selected_metadata()) == UISettings.TUTORIAL_GUIDANCE_CORE,
		"tutorial level immediately previews in the General settings page"
	)
	game._cancel_settings_changes()
	await _settle()
	_expect(
		UISettings.tutorial_guidance_level == UISettings.TUTORIAL_GUIDANCE_FULL,
		"Cancel restores the tutorial level captured when settings opened"
	)

	game._onboarding_reset_game()
	game._onboarding_set_stage("LV01_NAME_ENTRY")
	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_FULL, false)
	game._set_screen(Constants.SCREEN_NAME_ENTRY)
	await _settle()
	var name_guide_card := game.ui_layer.find_child("NameEntryGuideCard", true, false) as Control
	_expect(
		game.onboarding_name_tip_overlay != null
		and name_guide_card != null
		and game.onboarding_name_input.visible
		and game.onboarding_name_input.editable
		and not name_guide_card.get_global_rect().intersects(game.onboarding_name_input.get_global_rect()),
		"Full keeps a non-blocking name registration explanation beside the live input"
	)

	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_CORE, false)
	game._set_screen(Constants.SCREEN_NAME_ENTRY)
	await _settle()
	_expect(
		game.onboarding_name_tip_overlay == null
		and game.onboarding_name_input.visible
		and game.onboarding_name_input.editable,
		"Core only opens name registration without an extra help card"
	)

	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_OFF, false)
	game._set_screen(Constants.SCREEN_NAME_ENTRY)
	await _settle()
	_expect(
		game.onboarding_name_tip_overlay == null
		and game.onboarding_name_input.visible
		and game.onboarding_name_confirm_button.visible,
		"Off keeps the required name registration controls available"
	)

	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_CORE, false)
	await _show_step(game, "TUT_030_SELECT_SLIME", "LV03_DAY01_MANAGEMENT_TUTORIAL", 1, Constants.SCREEN_MANAGEMENT)
	var essential_overlay := game.ui_layer.find_child("TutorialOverlay", true, false) as Control
	var essential_message := essential_overlay.find_child("TutorialMessagePanel", true, false) as Control if essential_overlay != null else null
	var goblin_card := game.ui_layer.find_child("MonsterCard_goblin", true, false) as Control
	_expect(
		essential_message != null
		and goblin_card != null
		and game._tutorial_focus_rect("CHR_GOB").is_equal_approx(goblin_card.get_global_rect().grow(8.0))
		and not essential_message.get_global_rect().intersects(goblin_card.get_global_rect()),
		"Core only highlights the live Gob card without covering it"
	)

	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_FULL, false)
	await _show_step(game, "TUT_130_GOBLIN_CONTROL", "LV07_DAY02_BATTLE_THIEF", 2, Constants.SCREEN_MANAGEMENT)
	_expect(
		game.ui_layer.find_child("TutorialOverlay", true, false) != null,
		"Full shows automatic-combat observation guidance"
	)
	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_CORE, false)
	game._tutorial_build_overlay()
	_expect(
		game.ui_layer.find_child("TutorialOverlay", true, false) == null,
		"Core only hides automatic-combat observation guidance"
	)

	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_OFF, false)
	await _show_step(game, "TUT_030_SELECT_SLIME", "LV03_DAY01_MANAGEMENT_TUTORIAL", 1, Constants.SCREEN_MANAGEMENT)
	_expect(
		game.ui_layer.find_child("TutorialOverlay", true, false) == null,
		"Off hides tutorial cards and target emphasis"
	)
	_expect(
		not game._tutorial_allows("unit_selected", {"unit_id": "slime"})
		and game.ui_layer.find_child("TutorialOverlay", true, false) == null,
		"Off does not re-open guidance when an invalid required choice is blocked"
	)
	_expect(
		game._tutorial_allows("unit_selected", {"unit_id": "goblin"}),
		"Off still accepts the required choice"
	)
	game._on_tutorial_action("unit_selected", {"unit_id": "goblin"})
	await _settle()
	_expect(
		game.tutorial_manager.current_step_id() == "TUT_040_DEPLOY_SLIME"
		and game.tutorial_gate_enabled
		and game.ui_layer.find_child("TutorialOverlay", true, false) == null,
		"Off preserves required tutorial progression without visual guidance"
	)

	game.queue_free()
	UISettings.apply_snapshot(original_ui_settings, false)
	TutorialGuidanceHistory.apply_snapshot(original_tutorial_history, false)
	await get_tree().process_frame
	print("V122_TUTORIAL_GUIDANCE_LEVEL_TEST: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _show_step(game: Node, step_id: String, stage_id: String, day: int, screen_id: String) -> void:
	var step_index := -1
	for index in range(game.tutorial_manager.steps.size()):
		if str(game.tutorial_manager.steps[index].get("id", "")) == step_id:
			step_index = index
			break
	_expect(step_index >= 0, "tutorial fixture contains %s" % step_id)
	if step_index < 0:
		return
	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	GameState.day = day
	game.tutorial_manager.current_index = step_index
	game.tutorial_manager.active = true
	game._onboarding_set_stage(stage_id)
	game._set_screen(screen_id)
	await _settle()


func _option_values(option: OptionButton) -> Array:
	var values: Array = []
	if option == null:
		return values
	for index in range(option.item_count):
		values.append(str(option.get_item_metadata(index)))
	return values


func _settle() -> void:
	for _index in range(5):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	failed = true
	push_error("FAIL: %s" % message)
