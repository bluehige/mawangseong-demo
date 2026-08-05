extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const LOCALIZED_TUTORIAL_IDS := [
	"TUT_010_NAME",
	"TUT_020_THRONE_HP",
	"TUT_030_SELECT_SLIME",
	"TUT_040_DEPLOY_SLIME",
	"TUT_090_RESULT_GROWTH",
	"TUT_110_TRAP_CORRIDOR",
	"TUT_120_TRAP_LURE",
	"TUT_130_GOBLIN_CONTROL",
	"TUT_210_RECOVERY_NEST",
	"TUT_220_RETREAT_LINE",
	"TUT_230_IMP_FIREBALL",
	"TUT_240_BOSS_HP"
]

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
	TutorialGuidanceHistory.reset(false)
	LanguageSettings.set_locale(LanguageSettings.LOCALE_KOREAN, false)
	UISettings.apply_snapshot({
		"text_scale": UISettings.DEFAULT_TEXT_SCALE,
		"layout_mode": UISettings.LAYOUT_AUTO,
		"tutorial_guidance_level": UISettings.TUTORIAL_GUIDANCE_FULL
	}, false)

	_expect(LanguageSettings.catalog_error == "", "Stage 10 localization catalog loads without an error")
	for scope_id in ["settings", "name_entry", "tutorial_day1_3"]:
		_expect(
			not LanguageSettings.catalog_keys(scope_id).is_empty(),
			"%s scope declares stable string keys" % scope_id
		)
		for locale_id in LanguageSettings.SUPPORTED_LOCALES:
			_expect(
				LanguageSettings.missing_keys(locale_id, scope_id).is_empty(),
				"%s has no missing %s keys" % [LanguageSettings.display_name(locale_id), scope_id]
			)

	var game = GameRootScene.instantiate()
	add_child(game)
	await _settle()

	var localized_tutorial_ids: Array[String] = []
	for step_value in game.tutorial_manager.steps:
		var step: Dictionary = step_value
		var step_id := str(step.get("id", ""))
		if step_id not in LOCALIZED_TUTORIAL_IDS:
			continue
		localized_tutorial_ids.append(step_id)
		var text_key := str(step.get("text_key", ""))
		_expect(
			text_key == "tutorial.step.%s" % step_id
			and LanguageSettings.catalog_keys("tutorial_day1_3").has(text_key),
			"%s keeps its save-compatible ID and points to a catalog key" % step_id
		)
	_expect(localized_tutorial_ids == LOCALIZED_TUTORIAL_IDS, "DAY 1-3 tutorial IDs remain unchanged and ordered")

	game._open_settings_screen()
	game._select_settings_category("general")
	await _settle()
	var language_option := game.ui_layer.find_child("LanguageOption", true, false) as OptionButton
	_expect(
		language_option != null
		and _option_values(language_option) == [
			LanguageSettings.LOCALE_KOREAN,
			LanguageSettings.LOCALE_ENGLISH
		]
		and str(language_option.get_selected_metadata()) == LanguageSettings.LOCALE_KOREAN,
		"General settings exposes Korean and English in a fixed order"
	)
	_expect(
		_tree_has_text(game.ui_layer, "언어")
		and _tree_has_text(game.ui_layer, "튜토리얼 안내"),
		"Korean settings strings come from the active catalog"
	)

	game._on_language_preview_changed(LanguageSettings.LOCALE_ENGLISH)
	await _settle()
	language_option = game.ui_layer.find_child("LanguageOption", true, false) as OptionButton
	_expect(
		LanguageSettings.locale == LanguageSettings.LOCALE_ENGLISH
		and language_option != null
		and str(language_option.get_selected_metadata()) == LanguageSettings.LOCALE_ENGLISH,
		"English selection previews immediately without persisting"
	)
	_expect(
		_tree_has_text(game.ui_layer, "Language")
		and _tree_has_text(game.ui_layer, "Tutorial Guidance")
		and _tree_has_text(game.ui_layer, "Apply"),
		"English settings shell and General category rebuild together"
	)
	game._select_settings_category("display")
	await _settle()
	_expect(
		_tree_has_text(game.ui_layer, "Display")
		and _tree_has_text(game.ui_layer, "Text Size")
		and _tree_has_text(game.ui_layer, "Screen Layout"),
		"English Display settings render entirely from the catalog"
	)
	game._select_settings_category("audio")
	await _settle()
	_expect(
		_tree_has_text(game.ui_layer, "Audio")
		and _tree_has_text(game.ui_layer, "Master Volume")
		and _tree_has_text(game.ui_layer, "Sound Effects"),
		"English Audio settings render entirely from the catalog"
	)

	game._cancel_settings_changes()
	await _settle()
	_expect(
		LanguageSettings.locale == LanguageSettings.LOCALE_KOREAN,
		"Cancel restores the locale captured when settings opened"
	)

	LanguageSettings.set_locale(LanguageSettings.LOCALE_ENGLISH, false)
	game._onboarding_reset_game()
	game._onboarding_set_stage("LV01_NAME_ENTRY")
	game._set_screen(Constants.SCREEN_NAME_ENTRY)
	await _settle()
	_expect(
		_tree_has_text(game.ui_layer, "F-Rank Demon Lord Registration")
		and game.onboarding_name_input.placeholder_text == "Enter your demon lord name"
		and game.onboarding_name_random_button.text == "Random Name"
		and game.onboarding_name_confirm_button.text == "Begin With This Name",
		"English name registration localizes the form and both actions"
	)
	_expect(
		_tree_has_text(game.ui_layer, "This is the F-rank registration form.")
		and _tree_has_text(game.ui_layer, "NAME REGISTRATION")
		and _tree_has_text(game.ui_layer, "Close Guide"),
		"English name registration localizes Bati's note and non-blocking guide"
	)
	game.onboarding_name_input.text = ""
	game._onboarding_confirm_name()
	_expect(
		game.onboarding_bati_comment_label.text.contains("A blank will not do."),
		"English empty-name validation uses the name-entry catalog"
	)
	game.onboarding_name_input.text = "1234567890123"
	game._onboarding_confirm_name()
	_expect(
		game.onboarding_bati_comment_label.text.contains("That name is too long."),
		"English long-name validation uses the name-entry catalog"
	)

	await _show_step(game, "TUT_030_SELECT_SLIME", "LV03_DAY01_MANAGEMENT_TUTORIAL", 1)
	_expect(
		_tree_has_text(game.ui_layer, "Select Gob")
		and _tree_has_text(game.ui_layer, "Pudding is fixed to the front")
		and _tree_has_text(game.ui_layer, "Click here!"),
		"DAY 1 heading, instruction, and click badge render in English"
	)
	await _show_step(game, "TUT_130_GOBLIN_CONTROL", "LV07_DAY02_BATTLE_THIEF", 2)
	_expect(
		_tree_has_text(game.ui_layer, "Goblin AI Default")
		and _tree_has_text(game.ui_layer, "Goblin pursues thieves first"),
		"DAY 2 observation heading and instruction render in English"
	)
	await _show_step(game, "TUT_210_RECOVERY_NEST", "LV09_DAY03_MANAGEMENT_HERO", 3)
	var day3_message := game.ui_layer.find_child("TutorialMessagePanel", true, false) as Control
	var day3_focus: Rect2 = game._tutorial_focus_rect("ROOM_RECOVERY_NEST")
	_expect(
		_tree_has_text(game.ui_layer, "Select Recovery Nest")
		and _tree_has_text(game.ui_layer, "Click the glowing yellow [Recovery Nest]."),
		"DAY 3 required-choice heading and instruction render in English"
	)
	_expect(
		day3_message != null
		and day3_focus.has_area()
		and not day3_message.get_global_rect().intersects(day3_focus),
		"DAY 3 localized guidance stays clear of the Recovery Nest click target"
	)

	LanguageSettings.set_locale(LanguageSettings.LOCALE_KOREAN, false)
	game._tutorial_build_overlay()
	await _settle()
	_expect(
		_tree_has_text(game.ui_layer, "회복 둥지를 선택하세요")
		and _tree_has_text(game.ui_layer, "노란색으로 빛나는 [회복 둥지]를 클릭하세요."),
		"the same DAY 3 step rebuilds from the Korean catalog"
	)

	game.queue_free()
	LanguageSettings.apply_snapshot(original_language, false)
	UISettings.apply_snapshot(original_ui_settings, false)
	TutorialGuidanceHistory.apply_snapshot(original_tutorial_history, false)
	await get_tree().process_frame
	print("V122_STAGE10_LOCALIZATION_TEST: %s, %d assertions" % [
		"FAIL" if failed else "PASS",
		assertion_count
	])
	get_tree().quit(1 if failed else 0)


func _show_step(game: Node, step_id: String, stage_id: String, day: int) -> void:
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
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle()


func _option_values(option: OptionButton) -> Array:
	var values: Array = []
	if option == null:
		return values
	for index in range(option.item_count):
		values.append(str(option.get_item_metadata(index)))
	return values


func _tree_has_text(parent: Node, fragment: String) -> bool:
	if parent is Label and str(parent.text).contains(fragment):
		return true
	if parent is RichTextLabel and str(parent.text).contains(fragment):
		return true
	if parent is BaseButton and str(parent.text).contains(fragment):
		return true
	for child in parent.get_children():
		if _tree_has_text(child, fragment):
			return true
	return false


func _settle() -> void:
	for _index in range(6):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("PASS: %s" % message)
		return
	failed = true
	push_error("FAIL: %s" % message)
