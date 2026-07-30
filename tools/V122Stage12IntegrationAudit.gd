extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const CampaignSaveStore = preload("res://scripts/core/CampaignSaveStore.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const VIEWPORTS := [
	Vector2i(1920, 1080),
	Vector2i(1366, 768),
	Vector2i(1280, 720)
]
const DESIGN_BOUNDS := Rect2(0, 0, 1920, 1080)

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
	LanguageSettings.set_locale(LanguageSettings.LOCALE_KOREAN, false)
	TutorialGuidanceHistory.reset(false)
	UISettings.apply_snapshot({
		"text_scale": UISettings.DEFAULT_TEXT_SCALE,
		"layout_mode": UISettings.LAYOUT_AUTO,
		"tutorial_guidance_level": UISettings.TUTORIAL_GUIDANCE_FULL
	}, false)
	output_dir = ProjectSettings.globalize_path("res://tmp/v122_stage12_integration_audit")
	DirAccess.make_dir_recursive_absolute(output_dir)

	for viewport_size in VIEWPORTS:
		DisplayServer.window_set_size(viewport_size)
		await _settle(8)
		await _new_game()
		var invariant := _campaign_invariant()
		await _capture_management(viewport_size)
		await _capture_management_pause_and_settings(viewport_size, invariant)
		await _capture_tutorial_practice(viewport_size, invariant)
		await _capture_intrusion_and_raid(viewport_size, invariant)
		await _capture_combat_pause_and_settings(viewport_size, invariant)
		await _capture_result(viewport_size, invariant)
		_expect_save_payload(viewport_size)

	await _dispose_game()
	LanguageSettings.apply_snapshot(original_language, false)
	UISettings.apply_snapshot(original_ui_settings, false)
	TutorialGuidanceHistory.apply_snapshot(original_tutorial_history, false)
	print("V122_STAGE12_INTEGRATION_AUDIT: %s (%d assertions)" % [
		"FAIL" if failed else "PASS",
		assertion_count
	])
	print("V122_STAGE12_INTEGRATION_CAPTURE: %s" % output_dir)
	get_tree().quit(1 if failed else 0)


func _capture_management(viewport_size: Vector2i) -> void:
	var label := "DAY 05 management"
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "%s is the integration entry screen" % label)
	_expect(_layout_matches(viewport_size), "%s uses the responsive layout at %s" % [label, _size_label(viewport_size)])
	var roster := game.ui_layer.find_child("MonsterRosterDock", true, false) as Control
	var actions := game.ui_layer.find_child("ManagementPrimaryBar", true, false) as Control
	_expect(_inside(roster) and _inside(actions), "%s keeps workspace rails inside the canvas" % label)
	if roster != null and actions != null:
		_expect(not roster.get_global_rect().intersects(actions.get_global_rect()), "%s separates roster and actions" % label)
	await _save("%s_01_management.png" % _size_label(viewport_size), viewport_size)


func _capture_management_pause_and_settings(viewport_size: Vector2i, invariant: Dictionary) -> void:
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	game._handle_key(escape)
	await _settle(4)
	_expect(game.pause_menu_open, "management ESC opens the pause menu")
	_expect_pause_menu("management pause")
	await _save("%s_02_management_pause.png" % _size_label(viewport_size), viewport_size)

	var settings_button := game.ui_layer.find_child("PauseSettingsButton", true, false) as Button
	_expect(settings_button != null, "management pause exposes Settings")
	if settings_button != null:
		settings_button.pressed.emit()
	await _settle(8)
	_expect(
		game.current_screen == Constants.SCREEN_SETTINGS
			and game.settings_return_screen == Constants.SCREEN_MANAGEMENT,
		"management Settings records its return screen"
	)
	_expect_settings("management Settings", viewport_size)
	await _save("%s_03_management_settings.png" % _size_label(viewport_size), viewport_size)

	game._on_language_preview_changed(LanguageSettings.LOCALE_ENGLISH)
	await _settle(4)
	_expect(LanguageSettings.locale == LanguageSettings.LOCALE_ENGLISH, "Settings previews English before cancel")
	game._cancel_settings_changes()
	await _settle(8)
	_expect(
		game.current_screen == Constants.SCREEN_MANAGEMENT
			and game.pause_menu_open
			and LanguageSettings.locale == LanguageSettings.LOCALE_KOREAN,
		"Cancel restores Korean and the management pause menu"
	)
	_expect_pause_menu("management pause after Settings")
	_expect_invariant(invariant, "management Settings")
	game._close_pause_menu()
	await _settle(4)
	_expect(
		game.current_screen == Constants.SCREEN_MANAGEMENT and not game.pause_menu_open,
		"Continue returns to the same management workspace"
	)


func _capture_tutorial_practice(viewport_size: Vector2i, invariant: Dictionary) -> void:
	game._open_pause_menu()
	game._open_settings_screen(true)
	game._select_settings_category("general")
	await _settle(6)
	game._start_tutorial_practice()
	game._tutorial_practice_next()
	game._tutorial_practice_next()
	await _settle(6)
	var card := game.ui_layer.find_child("TutorialPracticeCard", true, false) as Control
	var next_button := game.ui_layer.find_child("TutorialPracticeNextButton", true, false) as Control
	_expect(
		game.current_screen == Constants.SCREEN_TUTORIAL_PRACTICE
			and game.tutorial_practice.current_step_id() == "TUT_030_SELECT_SLIME",
		"practice keeps the save-compatible Gob step ID"
	)
	_expect(_inside(card) and _inside(next_button), "practice keeps its workspace and primary action inside the canvas")
	await _save("%s_04_tutorial_practice.png" % _size_label(viewport_size), viewport_size)
	game._close_tutorial_practice()
	game._cancel_settings_changes()
	await _settle(8)
	_expect(
		game.current_screen == Constants.SCREEN_MANAGEMENT and game.pause_menu_open,
		"practice exits through Settings to the management pause menu"
	)
	_expect_invariant(invariant, "tutorial practice")
	game._close_pause_menu()
	await _settle(4)


func _capture_intrusion_and_raid(viewport_size: Vector2i, invariant: Dictionary) -> void:
	game._open_intrusion_brief()
	await _settle(8)
	var enemy_panel := game.ui_layer.find_child("IntrusionBriefEnemyPanel", true, false) as Control
	var threat_panel := game.ui_layer.find_child("IntrusionBriefThreatPanel", true, false) as Control
	var placement_button := game.ui_layer.find_child("EnterPlacementButton", true, false) as Control
	_expect(game.current_screen == Constants.SCREEN_INTRUSION_BRIEF, "management opens the live intrusion brief")
	_expect(_inside(enemy_panel) and _inside(threat_panel) and _inside(placement_button), "intrusion brief stays inside the canvas")
	if enemy_panel != null and threat_panel != null:
		_expect(not enemy_panel.get_global_rect().intersects(threat_panel.get_global_rect()), "intrusion brief separates enemy and threat columns")
	await _save("%s_05_intrusion.png" % _size_label(viewport_size), viewport_size)
	game._enter_placement_from_brief()
	await _settle(5)
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "intrusion brief returns to placement")

	game._open_raid_screen()
	await _settle(8)
	var raid_action := game.ui_layer.find_child("RaidStartButton", true, false) as Control
	var raid_roster := _parent_for_label("원정대")
	_expect(game.current_screen == Constants.SCREEN_RAID, "management path opens the raid screen")
	_expect(_inside(raid_action) and _inside(raid_roster), "raid action and roster stay inside the canvas")
	await _save("%s_06_raid.png" % _size_label(viewport_size), viewport_size)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(5)
	_expect_invariant(invariant, "intrusion and raid navigation")


func _capture_combat_pause_and_settings(viewport_size: Vector2i, invariant: Dictionary) -> void:
	game._start_combat()
	await _settle(10)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "placement starts the actual combat screen")
	if game.current_screen != Constants.SCREEN_COMBAT:
		return
	var music_stream = game.combat_music_player.stream if game.combat_music_player != null else null
	game._toggle_pause()
	await _settle(4)
	_expect(game.combat_paused and game.pause_menu_open, "combat pause stops simulation and opens its menu")
	_expect_pause_menu("combat pause")
	_expect_combat_units_paused()
	await _save("%s_07_combat_pause.png" % _size_label(viewport_size), viewport_size)

	var settings_button := game.ui_layer.find_child("PauseSettingsButton", true, false) as Button
	if settings_button != null:
		settings_button.pressed.emit()
	await _settle(8)
	_expect(
		game.current_screen == Constants.SCREEN_SETTINGS
			and game.settings_return_screen == Constants.SCREEN_COMBAT
			and game.combat_paused,
		"combat Settings keeps the battle paused and records its return screen"
	)
	_expect(
		game.combat_music_player == null or game.combat_music_player.stream == music_stream,
		"combat Settings keeps the active music stream"
	)
	_expect_settings("combat Settings", viewport_size)
	await _save("%s_08_combat_settings.png" % _size_label(viewport_size), viewport_size)

	game._cancel_settings_changes()
	await _settle(8)
	_expect(
		game.current_screen == Constants.SCREEN_COMBAT
			and game.combat_paused
			and game.pause_menu_open,
		"closing combat Settings returns to the paused battle menu"
	)
	_expect_pause_menu("combat pause after Settings")
	_expect_combat_units_paused()
	game._close_pause_menu()
	await _settle(4)
	_expect(
		not game.combat_paused and not game.pause_menu_open,
		"Continue resumes the same combat"
	)
	_expect_invariant(invariant, "combat Settings")


func _capture_result(viewport_size: Vector2i, invariant: Dictionary) -> void:
	game.result_summary = _result_summary()
	game.last_growth_summary = _growth_summary()
	game.result_summary["growth"] = game.last_growth_summary.duplicate(true)
	game.result_growth_reviewed = true
	GameState.victory = false
	GameState.defeat = false
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(8)
	var screen := game.ui_layer.find_child("V122ResultScreen", true, false) as Control
	var metrics := game.ui_layer.find_child("ResultCoreMetrics", true, false) as Control
	var growth := game.ui_layer.find_child("ResultGrowthPanel", true, false) as Control
	var next_button := game.ui_layer.find_child("NextDayButton", true, false) as Control
	_expect(game.current_screen == Constants.SCREEN_RESULT, "combat path opens the result screen")
	_expect(_inside(screen) and _inside(metrics) and _inside(growth) and _inside(next_button), "result regions stay inside the canvas")
	if metrics != null and growth != null:
		_expect(not metrics.get_global_rect().intersects(growth.get_global_rect()), "result separates metrics and growth")
	await _save("%s_09_result.png" % _size_label(viewport_size), viewport_size)
	_expect_invariant(invariant, "result presentation")


func _expect_save_payload(viewport_size: Vector2i) -> void:
	var payload: Dictionary = game._campaign_save_payload(game.current_screen)
	var summary: Dictionary = game._campaign_save_summary(game.current_screen)
	var validation_error := CampaignSaveStore.validate_payload(payload, summary)
	_expect(
		validation_error == "",
		"screen integration leaves a valid campaign payload at %s" % _size_label(viewport_size)
	)
	_expect(
		str(payload.get("v122_battle_plan", {}).get("battle_plan", {}).get("layout_fingerprint", "")).length() == 64,
		"screen integration retains the battle-plan fingerprint at %s" % _size_label(viewport_size)
	)


func _expect_pause_menu(label: String) -> void:
	var overlay := game.ui_layer.find_child("PauseMenuOverlay", true, false) as Control
	var panel := game.ui_layer.find_child("PauseMenuPanel", true, false) as Control
	var resume := game.ui_layer.find_child("PauseResumeButton", true, false) as Control
	var settings := game.ui_layer.find_child("PauseSettingsButton", true, false) as Control
	_expect(_inside(overlay) and _inside(panel) and _inside(resume) and _inside(settings), "%s stays inside the canvas" % label)
	if resume != null and settings != null:
		_expect(not resume.get_global_rect().intersects(settings.get_global_rect()), "%s separates Continue and Settings" % label)
		_expect(
			str(resume.get_meta("ui_button_grade", "")) == "primary"
				and str(settings.get_meta("ui_button_grade", "")) == "utility",
			"%s keeps one primary action and one utility action" % label
		)


func _expect_settings(label: String, viewport_size: Vector2i) -> void:
	var apply_button := game.ui_layer.find_child("ApplySettingsButton", true, false) as Control
	var cancel_button := game.ui_layer.find_child("CancelSettingsButton", true, false) as Control
	var category := game.ui_layer.find_child("SettingsCategory_display", true, false) as Control
	var layout_option := game.ui_layer.find_child("LayoutModeOption", true, false) as Control
	_expect(game.current_screen == Constants.SCREEN_SETTINGS, "%s opens the settings screen" % label)
	_expect(_layout_matches(viewport_size), "%s keeps the responsive layout at %s" % [label, _size_label(viewport_size)])
	_expect(
		_inside(apply_button) and _inside(cancel_button) and _inside(category) and _inside(layout_option),
		"%s keeps navigation and actions inside the canvas" % label
	)
	if apply_button != null and cancel_button != null:
		_expect(not apply_button.get_global_rect().intersects(cancel_button.get_global_rect()), "%s separates Apply and Cancel" % label)


func _expect_combat_units_paused() -> void:
	for unit in game.monster_units + game.enemy_units:
		if unit != null and is_instance_valid(unit):
			_expect(not unit.is_physics_processing(), "paused combat stops unit physics")


func _campaign_invariant() -> Dictionary:
	var rooms: Dictionary = {}
	for monster_id_value in game.monster_roster:
		var monster_id := str(monster_id_value)
		if not bool(game.monster_roster.get(monster_id, {}).get("defense_enabled", true)):
			continue
		rooms[monster_id] = str(game.monster_roster.get(monster_id, {}).get("room", ""))
	return {
		"day": GameState.day,
		"player_name": GameState.player_name,
		"layout_fingerprint": str(game._v122_current_battle_plan().get("layout_fingerprint", "")),
		"monster_rooms": rooms
	}


func _expect_invariant(expected: Dictionary, label: String) -> void:
	var actual := _campaign_invariant()
	_expect(actual == expected, "%s leaves day, player, layout, and monster rooms unchanged" % label)


func _new_game() -> void:
	await _dispose_game()
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(8)
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game._debug_skip_onboarding()
	GameState.day = 5
	GameState.max_day = 30
	GameState.player_name = "stage12-integration-audit"
	GameState.victory = false
	GameState.defeat = false
	GameState.onboarding_complete = true
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game._setup_dungeon_graph()
	game._init_room_directives()
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(6)


func _dispose_game() -> void:
	if game == null or not is_instance_valid(game):
		game = null
		return
	remove_child(game)
	game.queue_free()
	game = null
	await _settle(4)


func _parent_for_label(text_value: String) -> Control:
	for node in game.ui_layer.find_children("*", "Label", true, false):
		if str(node.text) == text_value:
			return node.get_parent_control()
	return null


func _result_summary() -> Dictionary:
	return {
		"win": true,
		"lines": [],
		"metrics": {
			"day": 5,
			"alive_monsters": 3,
			"total_monsters": 3,
			"treasure_gold_stolen": 0,
			"facility_disables": 0,
			"final_breach_segment": "가시 복도",
			"monster_contributions": {
				"goblin": {"damage_absorbed": 31, "damage_dealt": 68},
				"imp": {"damage_absorbed": 11, "damage_dealt": 79}
			},
			"decision_context": {
				"day": 5,
				"directive_id": "defense",
				"directive_name": "사수",
				"monster_placements": [{
					"monster_id": "goblin",
					"monster_name": "곱",
					"room_id": "barracks",
					"room_name": "병영",
					"defense_zone_id": "zone_a_front"
				}]
			}
		},
		"v122_ledger": {
			"throne_damage": 0,
			"gold_stolen": 0,
			"breach_progress": 0.34,
			"final_breach_segment": "가시 복도",
			"facility_contribution": {},
			"command_contribution": {},
			"events": []
		}
	}


func _growth_summary() -> Array:
	return [
		{"monster_id": "slime", "display_name": "푸딩", "level_before": 2, "level_after": 2, "levels_gained": 0, "exp_before": 18, "exp_after": 42, "exp_gain": 24, "next_exp": 80},
		{"monster_id": "goblin", "display_name": "곱", "level_before": 2, "level_after": 3, "levels_gained": 1, "exp_before": 46, "exp_after": 12, "exp_gain": 28, "next_exp": 90},
		{"monster_id": "imp", "display_name": "핀", "level_before": 2, "level_after": 2, "levels_gained": 0, "exp_before": 30, "exp_after": 57, "exp_gain": 27, "next_exp": 80}
	]


func _inside(control: Control) -> bool:
	return control != null and DESIGN_BOUNDS.encloses(control.get_global_rect())


func _layout_matches(viewport_size: Vector2i) -> bool:
	var expected := UISettings.LAYOUT_STANDARD if viewport_size.x >= 1440 else UISettings.LAYOUT_COMPACT
	return UISettings.effective_layout_mode() == expected


func _size_label(viewport_size: Vector2i) -> String:
	return "%dx%d" % [viewport_size.x, viewport_size.y]


func _save(file_name: String, expected_size: Vector2i) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_expect(false, "%s produces a non-empty screenshot" % file_name)
		return
	var size_delta := image.get_size() - expected_size
	_expect(
		absi(size_delta.x) <= 1 and absi(size_delta.y) <= 1,
		"%s preserves the requested viewport size" % file_name
	)
	var error := image.save_png(output_dir.path_join(file_name))
	_expect(error == OK, "%s saves successfully" % file_name)


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("PASS: %s" % message)
		return
	failed = true
	push_error("FAIL: %s" % message)
