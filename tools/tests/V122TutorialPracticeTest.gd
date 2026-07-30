extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const TutorialPracticeSessionScript = preload("res://scripts/systems/tutorial/TutorialPracticeSession.gd")

const TEST_SAVE_PATH := "user://v122_tutorial_practice_save_sentinel.json"
const CORE_STEP_IDS := [
	"TUT_010_NAME",
	"TUT_020_THRONE_HP",
	"TUT_030_SELECT_SLIME",
	"TUT_040_DEPLOY_SLIME",
	"TUT_090_RESULT_GROWTH",
	"TUT_110_TRAP_CORRIDOR",
	"TUT_120_TRAP_LURE",
	"TUT_210_RECOVERY_NEST",
	"TUT_220_RETREAT_LINE"
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
	LanguageSettings.set_locale(LanguageSettings.LOCALE_KOREAN, false)
	UISettings.apply_snapshot({
		"text_scale": UISettings.DEFAULT_TEXT_SCALE,
		"layout_mode": UISettings.LAYOUT_AUTO,
		"tutorial_guidance_level": UISettings.TUTORIAL_GUIDANCE_FULL
	}, false)
	TutorialGuidanceHistory.reset(false)

	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	var sentinel_text := "{\"campaign\":\"leave-this-untouched\"}"
	var sentinel_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	_expect(sentinel_file != null, "campaign sentinel file opens")
	if sentinel_file != null:
		sentinel_file.store_string(sentinel_text)
		sentinel_file.close()

	var game = GameRootScene.instantiate()
	add_child(game)
	await _settle()
	game._set_campaign_save_path_for_tests(TEST_SAVE_PATH)

	game._onboarding_reset_game()
	game._onboarding_set_stage("LV01_NAME_ENTRY")
	game._set_screen(Constants.SCREEN_NAME_ENTRY)
	await _settle()
	_expect(
		game.ui_layer.find_child("NameEntryGuideCard", true, false) != null,
		"an unrecorded optional name guide is visible"
	)
	var legacy_tip_state_before: bool = bool(game.onboarding_name_entry_tip_dismissed)
	game._onboarding_dismiss_name_entry_tip()
	await _settle()
	_expect(
		TutorialGuidanceHistory.has_dismissed(TutorialGuidanceHistory.NAME_ENTRY_GUIDE_ID)
		and game.onboarding_name_entry_tip_dismissed == legacy_tip_state_before,
		"dismissing optional help changes device history without mutating the legacy campaign field"
	)
	TutorialGuidanceHistory.reset(false)
	game._set_screen(Constants.SCREEN_NAME_ENTRY)
	await _settle()
	_expect(
		game.ui_layer.find_child("NameEntryGuideCard", true, false) != null,
		"resetting device guidance makes the optional name guide available again"
	)

	TutorialGuidanceHistory.dismiss_help(TutorialGuidanceHistory.NAME_ENTRY_GUIDE_ID, false)
	game._open_settings_screen()
	game._select_settings_category("general")
	await _settle()
	var reset_button := game.ui_layer.find_child("ResetTutorialHistoryButton", true, false) as Button
	var practice_button := game.ui_layer.find_child("TutorialPracticeButton", true, false) as Button
	_expect(
		reset_button != null
		and not reset_button.disabled
		and practice_button != null,
		"General settings exposes live guidance-history reset and tutorial-practice actions"
	)
	game._reset_tutorial_guidance_history()
	await _settle()
	var history_status := game.ui_layer.find_child("TutorialHistoryStatusLabel", true, false) as Label
	_expect(
		TutorialGuidanceHistory.dismissed_count() == 0
		and history_status != null
		and history_status.text.contains("적용"),
		"history reset stays pending until settings are applied"
	)
	game._cancel_settings_changes()
	await _settle()
	_expect(
		TutorialGuidanceHistory.has_dismissed(TutorialGuidanceHistory.NAME_ENTRY_GUIDE_ID),
		"Cancel restores the guidance history captured when settings opened"
	)
	_expect(
		FileAccess.get_file_as_string(TEST_SAVE_PATH) == sentinel_text,
		"reset and Cancel do not write the campaign save path"
	)

	game._open_settings_screen()
	game._select_settings_category("general")
	game._reset_tutorial_guidance_history()
	game._apply_settings_changes()
	await _settle()
	_expect(
		TutorialGuidanceHistory.dismissed_count() == 0
		and game.settings_open_snapshot.is_empty(),
		"Apply commits the device guidance reset and closes the settings transaction"
	)
	_expect(
		game.current_screen == Constants.SCREEN_NAME_ENTRY
		and game.ui_layer.find_child("NameEntryGuideCard", true, false) != null,
		"an applied reset restores optional help without restarting or replacing the campaign"
	)
	_expect(
		FileAccess.get_file_as_string(TEST_SAVE_PATH) == sentinel_text,
		"applying guidance history still leaves the campaign save file untouched"
	)
	TutorialGuidanceHistory.dismiss_help(TutorialGuidanceHistory.NAME_ENTRY_GUIDE_ID, false)

	game._open_settings_screen()
	game._select_settings_category("general")
	game._on_language_preview_changed(LanguageSettings.LOCALE_ENGLISH)
	game._on_tutorial_guidance_preview_changed(UISettings.TUTORIAL_GUIDANCE_CORE)
	game._reset_tutorial_guidance_history()
	await _settle()
	var tutorial_state_before: Dictionary = game.tutorial_manager.export_state().duplicate(true)
	var onboarding_stage_before: String = str(game.onboarding_stage_id)
	var day_before: int = int(GameState.day)
	var campaign_payload_before: Dictionary = game._campaign_save_payload(Constants.SCREEN_MANAGEMENT).duplicate(true)

	game._start_tutorial_practice()
	await _settle()
	_expect(
		game.current_screen == Constants.SCREEN_TUTORIAL_PRACTICE
		and game.tutorial_practice.step_ids() == CORE_STEP_IDS
		and game.tutorial_practice.current_step_id() == "TUT_010_NAME",
		"Core Only starts a separate nine-step DAY 1-3 practice session at the legacy first ID"
	)
	_expect(
		_tree_has_text(game.ui_layer, "Tutorial Practice")
		and _tree_has_text(game.ui_layer, "Register Your Name")
		and game.ui_layer.find_child("TutorialOverlay", true, false) == null,
		"practice uses the previewed English locale without leaking the live campaign overlay"
	)
	game._tutorial_practice_next()
	game._tutorial_practice_next()
	await _settle()
	_expect(
		game.tutorial_practice.current_step_id() == "TUT_030_SELECT_SLIME"
		and _tree_has_text(game.ui_layer, "Select Gob"),
		"practice advances by legacy step ID without driving TutorialManager actions"
	)
	for _index in range(game.tutorial_practice.step_count() - game.tutorial_practice.current_index):
		game._tutorial_practice_next()
		await _settle()
	_expect(
		game.tutorial_practice.completed
		and game.ui_layer.find_child("TutorialPracticeCompleteState", true, false) != null,
		"the independent practice sequence reaches its own completion state"
	)
	game._close_tutorial_practice()
	await _settle()
	_expect(
		game.current_screen == Constants.SCREEN_SETTINGS
		and game.settings_category == "general"
		and LanguageSettings.locale == LanguageSettings.LOCALE_ENGLISH
		and UISettings.tutorial_guidance_level == UISettings.TUTORIAL_GUIDANCE_CORE,
		"leaving practice returns to General settings with pending previews intact"
	)
	game._start_tutorial_practice()
	await _settle()
	_expect(
		game.tutorial_practice.current_step_id() == "TUT_010_NAME"
		and not game.tutorial_practice.completed,
		"re-entering practice starts a fresh session"
	)
	game._close_tutorial_practice()
	await _settle()
	var campaign_payload_after: Dictionary = game._campaign_save_payload(Constants.SCREEN_MANAGEMENT)
	_expect(
		game.tutorial_manager.export_state() == tutorial_state_before
		and game.onboarding_stage_id == onboarding_stage_before
		and GameState.day == day_before
		and campaign_payload_after == campaign_payload_before,
		"practice leaves campaign progress and the campaign payload unchanged"
	)
	game._cancel_settings_changes()
	await _settle()
	_expect(
		LanguageSettings.locale == LanguageSettings.LOCALE_KOREAN
		and UISettings.tutorial_guidance_level == UISettings.TUTORIAL_GUIDANCE_FULL
		and TutorialGuidanceHistory.has_dismissed(TutorialGuidanceHistory.NAME_ENTRY_GUIDE_ID),
		"Cancel after re-entry restores locale, guidance level, and help history together"
	)
	_expect(
		FileAccess.get_file_as_string(TEST_SAVE_PATH) == sentinel_text,
		"practice never writes the configured campaign save file"
	)

	game._open_settings_screen()
	game._select_settings_category("general")
	game._on_tutorial_guidance_preview_changed(UISettings.TUTORIAL_GUIDANCE_OFF)
	game._start_tutorial_practice()
	await _settle()
	_expect(
		game.tutorial_practice.step_count() == 0
		and game.ui_layer.find_child("TutorialPracticeEmptyState", true, false) != null
		and _tree_has_text(game.ui_layer, "튜토리얼 안내가 꺼져 있습니다"),
		"Off is honored in practice with a localized empty state"
	)
	game._close_tutorial_practice()
	game._cancel_settings_changes()

	var full_practice = TutorialPracticeSessionScript.new()
	full_practice.setup(game.onboarding_flow.data.get("tutorial_steps", []), UISettings.TUTORIAL_GUIDANCE_FULL)
	_expect(
		full_practice.step_ids() == TutorialPracticeSessionScript.SUPPORTED_STEP_IDS,
		"Full practice preserves all twelve localized DAY 1-3 legacy step IDs in order"
	)

	CampaignSaveStoreScript.delete(TEST_SAVE_PATH)
	game.queue_free()
	LanguageSettings.apply_snapshot(original_language, false)
	LanguageSettings.save()
	UISettings.apply_snapshot(original_ui_settings, false)
	UISettings.save()
	TutorialGuidanceHistory.apply_snapshot(original_tutorial_history, true)
	await get_tree().process_frame
	print("V122_TUTORIAL_PRACTICE_TEST: %s, %d assertions" % [
		"FAIL" if failed else "PASS",
		assertion_count
	])
	get_tree().quit(1 if failed else 0)


func _tree_has_text(parent: Node, fragment: String) -> bool:
	if parent is Label and str(parent.text).contains(fragment):
		return true
	if parent is RichTextLabel and str(parent.text).contains(fragment):
		return true
	if parent is Button and str(parent.text).contains(fragment):
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
