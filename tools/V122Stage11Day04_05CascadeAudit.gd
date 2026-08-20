extends Node

const Constants = preload("res://scripts/core/Constants.gd")
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
	output_dir = ProjectSettings.globalize_path("res://tmp/v122_stage11_day04_05_cascade_audit")
	DirAccess.make_dir_recursive_absolute(output_dir)

	for viewport_size in VIEWPORTS:
		DisplayServer.window_set_size(viewport_size)
		await _settle(8)
		await _capture_raid_preview(viewport_size)
		await _capture_raid(viewport_size, 4)
		await _capture_management(viewport_size, 4)
		await _capture_intrusion_brief(viewport_size, 4)
		await _capture_combat(viewport_size, 4, "thief")
		await _capture_result(viewport_size, 4, true)
		await _capture_management(viewport_size, 5)
		await _capture_raid(viewport_size, 5)
		await _capture_intrusion_brief(viewport_size, 5)
		await _capture_combat(viewport_size, 5, "trainee_hero")
		await _capture_result(viewport_size, 5, false)

	await _dispose_game()
	LanguageSettings.apply_snapshot(original_language, false)
	UISettings.apply_snapshot(original_ui_settings, false)
	TutorialGuidanceHistory.apply_snapshot(original_tutorial_history, false)
	print("V122_STAGE11_DAY04_05_CASCADE_AUDIT: %s (%d assertions)" % [
		"FAIL" if failed else "PASS",
		assertion_count
	])
	print("V122_STAGE11_DAY04_05_CASCADE_CAPTURE: %s" % output_dir)
	get_tree().quit(1 if failed else 0)


func _capture_raid_preview(viewport_size: Vector2i) -> void:
	await _new_game(4)
	game._set_screen(Constants.SCREEN_RAID_PREVIEW)
	await _settle(8)
	var label := "DAY 04 raid preview"
	_expect(game.current_screen == Constants.SCREEN_RAID_PREVIEW, "%s opens the actual preview screen" % label)
	_expect(_layout_matches(viewport_size), "%s uses the expected responsive layout at %s" % [label, _size_label(viewport_size)])
	var map_rect: Rect2 = game._tutorial_registered_target_rect("WorldMapPanel")
	var start_button := game.ui_layer.find_child("StartRaidButton", true, false) as Control
	var back_button := game.ui_layer.find_child("BackButton", true, false) as Control
	var briefing_text := game.ui_layer.find_child("RaidPreviewBriefingText", true, false) as RichTextLabel
	_expect(map_rect.has_area() and DESIGN_BOUNDS.encloses(map_rect), "%s keeps its world map inside the canvas" % label)
	_expect(start_button != null and DESIGN_BOUNDS.encloses(start_button.get_global_rect()), "%s keeps the first-raid action visible" % label)
	_expect(back_button != null and DESIGN_BOUNDS.encloses(back_button.get_global_rect()), "%s keeps the management action visible" % label)
	_expect(
		briefing_text != null
			and briefing_text.get_content_height() <= briefing_text.size.y,
		"%s wraps the Korean briefing without clipping" % label
	)
	if start_button != null and back_button != null:
		_expect(not start_button.get_global_rect().intersects(back_button.get_global_rect()), "%s separates its two actions" % label)
	await _save("%s_day04_raid_preview.png" % _size_label(viewport_size), viewport_size)


func _capture_raid(viewport_size: Vector2i, day: int) -> void:
	await _new_game(day)
	game._open_raid_screen()
	await _settle(8)
	var label := "DAY %02d raid" % day
	_expect(game.current_screen == Constants.SCREEN_RAID, "%s opens the actual raid screen" % label)
	_expect(_layout_matches(viewport_size), "%s uses the expected responsive layout at %s" % [label, _size_label(viewport_size)])
	var start_button := game.ui_layer.find_child("RaidStartButton", true, false) as Control
	var map_panel := _parent_for_label("악명 원정 지도")
	var detail_panel := start_button.get_parent_control() if start_button != null else null
	var roster_panel := _parent_for_label("원정대")
	_expect(start_button != null and DESIGN_BOUNDS.encloses(start_button.get_global_rect()), "%s keeps the raid action visible" % label)
	_expect(map_panel != null and detail_panel != null and roster_panel != null, "%s builds map, detail, and roster columns" % label)
	_expect_columns(label, [map_panel, detail_panel, roster_panel])
	await _save("%s_day%02d_raid.png" % [_size_label(viewport_size), day], viewport_size)


func _capture_management(viewport_size: Vector2i, day: int) -> void:
	await _new_game(day)
	game.management_context_drawer_open = false
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(8)
	var label := "DAY %02d management" % day
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "%s opens the actual management screen" % label)
	_expect(_layout_matches(viewport_size), "%s uses the expected responsive layout at %s" % [label, _size_label(viewport_size)])
	var roster := game.ui_layer.find_child("MonsterRosterDock", true, false) as Control
	var actions := game.ui_layer.find_child("ManagementPrimaryBar", true, false) as Control
	var intrusion := game.ui_layer.find_child("OpenIntrusionBriefButton", true, false) as Control
	_expect(roster != null and DESIGN_BOUNDS.encloses(roster.get_global_rect()), "%s keeps the roster dock inside the canvas" % label)
	_expect(actions != null and DESIGN_BOUNDS.encloses(actions.get_global_rect()), "%s keeps the primary action rail inside the canvas" % label)
	_expect(intrusion != null and DESIGN_BOUNDS.encloses(intrusion.get_global_rect()), "%s exposes intrusion information" % label)
	var model: Dictionary = game.get_meta("v122_management_view_model", {})
	var raid_choice_pending: bool = day == 4 and game._campaign_raid_choice_pending()
	_expect(
		_model_has_action(model, "raid", "context", not raid_choice_pending),
		"%s maps raids to the context drawer%s" % [label, " as a required choice" if raid_choice_pending else ""]
	)
	if roster != null and actions != null:
		_expect(not roster.get_global_rect().intersects(actions.get_global_rect()), "%s separates roster and primary actions" % label)
	await _save("%s_day%02d_management.png" % [_size_label(viewport_size), day], viewport_size)
	game.management_context_drawer_open = true
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(8)
	var drawer := game.ui_layer.find_child("ManagementContextDrawer", true, false) as Control
	var raid_action := game.ui_layer.find_child("RequiredRaidConfirmButton" if raid_choice_pending else "ManagementContextAction_raid", true, false) as Control
	_expect(drawer != null and DESIGN_BOUNDS.encloses(drawer.get_global_rect()), "%s keeps the context drawer inside the canvas" % label)
	_expect(
		raid_action != null and drawer != null and drawer.get_global_rect().encloses(raid_action.get_global_rect()),
		"%s exposes the %s raid action inside the drawer" % [label, "required" if raid_choice_pending else "optional"]
	)
	if drawer != null and actions != null:
		_expect(not drawer.get_global_rect().intersects(actions.get_global_rect()), "%s keeps the drawer clear of primary actions" % label)
	await _save("%s_day%02d_management_raid_drawer.png" % [_size_label(viewport_size), day], viewport_size)


func _capture_intrusion_brief(viewport_size: Vector2i, day: int) -> void:
	await _new_game(day)
	game._open_intrusion_brief()
	await _settle(8)
	var label := "DAY %02d intrusion brief" % day
	_expect(game.current_screen == Constants.SCREEN_INTRUSION_BRIEF, "%s opens the actual intrusion screen" % label)
	_expect(_layout_matches(viewport_size), "%s uses the expected responsive layout at %s" % [label, _size_label(viewport_size)])
	var enemy_panel := game.ui_layer.find_child("IntrusionBriefEnemyPanel", true, false) as Control
	var threat_panel := game.ui_layer.find_child("IntrusionBriefThreatPanel", true, false) as Control
	var enter_button := game.ui_layer.find_child("EnterPlacementButton", true, false) as Control
	_expect(enemy_panel != null and threat_panel != null and enter_button != null, "%s builds enemy, threat, and placement regions" % label)
	_expect_columns(label, [enemy_panel, threat_panel])
	if enter_button != null:
		_expect(DESIGN_BOUNDS.encloses(enter_button.get_global_rect()), "%s keeps the placement action visible" % label)
		for panel in [enemy_panel, threat_panel]:
			if panel != null:
				_expect(not enter_button.get_global_rect().intersects(panel.get_global_rect()), "%s keeps the placement action clear of briefing content" % label)
	var model: Dictionary = game.get_meta("v122_intrusion_brief_model", {})
	_expect(int(model.get("day", 0)) == day, "%s reports the current day" % label)
	_expect(not model.get("schedule", []).is_empty(), "%s uses the live defense schedule" % label)
	await _save("%s_day%02d_intrusion_brief.png" % [_size_label(viewport_size), day], viewport_size)


func _capture_combat(viewport_size: Vector2i, day: int, enemy_id: String) -> void:
	await _new_game(day)
	game._start_combat()
	await _settle(8)
	var label := "DAY %02d combat" % day
	if day == 4:
		var start_state: Dictionary = game._management_start_state()
		_expect(
			game.current_screen != Constants.SCREEN_COMBAT and str(start_state.get("blocked_reason", "")).contains("원정 선택"),
			"%s blocks defense until the required raid choice with a clear reason" % label
		)
		# The mandatory-choice surface is captured separately above. Mark its
		# resolved campaign fact here so this fixture can also inspect the
		# actual DAY 4 combat HUD after the legitimate prerequisite.
		game.completed_raids["d04_signpost_flip"] = {"mission_id": "d04_signpost_flip", "success": true}
		game.management_context_drawer_open = false
		game._start_combat()
		await _settle(8)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "%s opens the actual combat screen" % label)
	if game.current_screen != Constants.SCREEN_COMBAT:
		await _save("%s_day%02d_combat_blocked.png" % [_size_label(viewport_size), day], viewport_size)
		return
	game.combat_paused = true
	game._spawn_enemy(enemy_id)
	await _settle(4)
	_place_combat_fixture(day, enemy_id)
	game.selected_unit = null
	game._set_screen(Constants.SCREEN_COMBAT)
	await _settle(8)
	_expect(_layout_matches(viewport_size), "%s uses the expected responsive layout at %s" % [label, _size_label(viewport_size)])
	_expect_combat_rails(label)
	await _save("%s_day%02d_combat.png" % [_size_label(viewport_size), day], viewport_size)


func _capture_result(viewport_size: Vector2i, day: int, win: bool) -> void:
	await _new_game(day)
	game.result_summary = _result_summary(day, win)
	game.last_growth_summary = _growth_summary()
	game.result_summary["growth"] = game.last_growth_summary.duplicate(true)
	game.result_growth_reviewed = true
	GameState.victory = false
	GameState.defeat = not win
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(8)
	var label := "DAY %02d result" % day
	_expect(game.current_screen == Constants.SCREEN_RESULT, "%s opens the actual result screen" % label)
	_expect(_layout_matches(viewport_size), "%s uses the expected responsive layout at %s" % [label, _size_label(viewport_size)])
	var screen := game.ui_layer.find_child("V122ResultScreen", true, false) as Control
	var metrics := game.ui_layer.find_child("ResultCoreMetrics", true, false) as Control
	var growth := game.ui_layer.find_child("ResultGrowthPanel", true, false) as Control
	_expect(screen != null and DESIGN_BOUNDS.encloses(screen.get_global_rect()), "%s stays inside the design canvas" % label)
	_expect(metrics != null and growth != null and not metrics.get_global_rect().intersects(growth.get_global_rect()), "%s keeps metrics and growth in separate columns" % label)
	for action_name in ["NextDayButton"] if win else ["ResultEditPlacement", "ResultRetrySamePlacement"]:
		var action := game.ui_layer.find_child(action_name, true, false) as Control
		_expect(action != null and DESIGN_BOUNDS.encloses(action.get_global_rect()), "%s keeps %s visible" % [label, action_name])
		if action != null and metrics != null and growth != null:
			_expect(
				not action.get_global_rect().intersects(metrics.get_global_rect())
					and not action.get_global_rect().intersects(growth.get_global_rect()),
				"%s keeps %s clear of result content" % [label, action_name]
			)
	await _save("%s_day%02d_result_%s.png" % [_size_label(viewport_size), day, "win" if win else "loss"], viewport_size)


func _new_game(day: int) -> void:
	await _dispose_game()
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(8)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	GameState.day = day
	GameState.max_day = 30
	GameState.player_name = "stage11-day04-05-audit"
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


func _place_combat_fixture(day: int, enemy_id: String) -> void:
	var monster_id := "goblin" if day == 4 else "imp"
	var monster_room := "barracks" if day == 4 else "recovery"
	var monster := _unit_by_id(game.monster_units, monster_id)
	var enemy := _unit_by_id(game.enemy_units, enemy_id)
	if monster != null:
		monster.global_position = game.graph.center(monster_room)
		monster.current_room = monster_room
		monster.stop_navigation()
	if enemy != null:
		enemy.global_position = game.graph.center("entrance")
		enemy.current_room = "entrance"
		enemy.stop_navigation()


func _expect_combat_rails(label: String) -> void:
	var rail_names := [
		"CombatThroneStatus",
		"CombatTacticsPanel",
		"CombatCommandBar"
	]
	var model: Dictionary = game.get_meta("v122_combat_view_model", {})
	if bool(model.get("threat_panel_visible", false)):
		rail_names.append("CombatThreat")
	var rects: Array[Rect2] = []
	for rail_name in rail_names:
		var rail := game.ui_layer.find_child(rail_name, true, false) as Control
		_expect(rail != null, "%s builds %s" % [label, rail_name])
		if rail == null:
			continue
		var rect := rail.get_global_rect()
		_expect(DESIGN_BOUNDS.encloses(rect), "%s keeps %s inside the canvas" % [label, rail_name])
		rects.append(rect)
	for left_index in range(rects.size()):
		for right_index in range(left_index + 1, rects.size()):
			_expect(not rects[left_index].intersects(rects[right_index]), "%s keeps combat rails from overlapping" % label)


func _expect_columns(label: String, controls: Array) -> void:
	var rects: Array[Rect2] = []
	for control_value in controls:
		var control := control_value as Control
		if control == null:
			continue
		var rect := control.get_global_rect()
		_expect(DESIGN_BOUNDS.encloses(rect), "%s keeps a content column inside the canvas" % label)
		rects.append(rect)
	for left_index in range(rects.size()):
		for right_index in range(left_index + 1, rects.size()):
			_expect(not rects[left_index].intersects(rects[right_index]), "%s keeps content columns from overlapping" % label)


func _parent_for_label(text_value: String) -> Control:
	for node in game.ui_layer.find_children("*", "Label", true, false):
		if str(node.text) == text_value:
			return node.get_parent_control()
	return null


func _model_has_action(model: Dictionary, action_id: String, area: String, require_enabled: bool = true) -> bool:
	for action_value in model.get("actions", []):
		if action_value is Dictionary:
			var action: Dictionary = action_value
			if (
				str(action.get("id", "")) == action_id
				and str(action.get("area", "")) == area
				and bool(action.get("visible", false))
				and (not require_enabled or bool(action.get("enabled", false)))
			):
				return true
	return false


func _result_summary(day: int, win: bool) -> Dictionary:
	return {
		"win": win,
		"lines": [],
		"metrics": {
			"day": day,
			"alive_monsters": 4 if win else 1,
			"total_monsters": 4,
			"treasure_gold_stolen": 0 if win else 42,
			"facility_disables": 0 if win else 1,
			"final_breach_segment": "가시 복도" if win else "병영 → 왕좌",
			"monster_contributions": {
				"goblin": {"damage_absorbed": 31, "damage_dealt": 68},
				"imp": {"damage_absorbed": 11, "damage_dealt": 79}
			},
			"decision_context": {
				"day": day,
				"directive_id": "defense",
				"directive_name": "사수",
				"monster_placements": [{
					"monster_id": "goblin" if day == 4 else "imp",
					"monster_name": "곱" if day == 4 else "핀",
					"room_id": "barracks" if day == 4 else "recovery",
					"room_name": "병영" if day == 4 else "회복 둥지",
					"defense_zone_id": "zone_a_front" if day == 4 else "zone_a_rear"
				}]
			}
		},
		"v122_ledger": {
			"throne_damage": 0 if win else 210,
			"gold_stolen": 0 if win else 42,
			"breach_progress": 0.34 if win else 0.88,
			"final_breach_segment": "가시 복도" if win else "병영 → 왕좌",
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


func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit != null and is_instance_valid(unit) and str(unit.unit_id) == unit_id:
			return unit
	return null


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
