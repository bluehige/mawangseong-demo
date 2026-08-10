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
	output_dir = ProjectSettings.globalize_path("res://tmp/v122_stage11_cascade_audit")
	DirAccess.make_dir_recursive_absolute(output_dir)

	var review_viewports = [Vector2i(1280, 720)] if OS.get_environment("V125_REVIEW_1280_ONLY") == "1" else VIEWPORTS
	for viewport_size in review_viewports:
		DisplayServer.window_set_size(viewport_size)
		await _settle(8)
		await _capture_management(viewport_size, 2, "TUT_110_TRAP_CORRIDOR", "LV06_DAY02_MANAGEMENT_TREASURE", "spike_corridor", false)
		await _capture_management(viewport_size, 2, "TUT_120_TRAP_LURE", "LV06_DAY02_MANAGEMENT_TREASURE", "spike_corridor", true)
		await _capture_combat(viewport_size, 2, "TUT_130_GOBLIN_CONTROL", "LV07_DAY02_BATTLE_THIEF", "thief")
		await _capture_result(viewport_size, 2, true)
		await _capture_management(viewport_size, 3, "TUT_210_RECOVERY_NEST", "LV09_DAY03_MANAGEMENT_HERO", "recovery", false)
		await _capture_management(viewport_size, 3, "TUT_220_RETREAT_LINE", "LV09_DAY03_MANAGEMENT_HERO", "recovery", true)
		await _capture_combat(viewport_size, 3, "TUT_230_IMP_FIREBALL", "LV10_DAY03_BATTLE_HERO", "trainee_hero")
		await _capture_combat(viewport_size, 3, "TUT_240_BOSS_HP", "LV10_DAY03_BATTLE_HERO", "trainee_hero")
		await _capture_result(viewport_size, 3, false)

	await _dispose_game()
	LanguageSettings.apply_snapshot(original_language, false)
	UISettings.apply_snapshot(original_ui_settings, false)
	TutorialGuidanceHistory.apply_snapshot(original_tutorial_history, false)
	print("V122_STAGE11_CASCADE_AUDIT: %s (%d assertions)" % [
		"FAIL" if failed else "PASS",
		assertion_count
	])
	print("V122_STAGE11_CASCADE_CAPTURE: %s" % output_dir)
	get_tree().quit(1 if failed else 0)


func _capture_management(
	viewport_size: Vector2i,
	day: int,
	step_id: String,
	stage_id: String,
	room_id: String,
	drawer_open: bool
) -> void:
	await _new_game(day)
	_activate_tutorial_step(step_id, stage_id)
	game.selected_room = room_id
	game.management_context_drawer_open = drawer_open
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(8)
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "%s opens the actual management screen" % step_id)
	_expect(_layout_matches(viewport_size), "%s uses the expected responsive layout at %s" % [step_id, _size_label(viewport_size)])
	_expect_tutorial_overlay(step_id, Constants.SCREEN_MANAGEMENT)
	var drawer := game.ui_layer.find_child("ManagementContextDrawer", true, false) as Control
	var message := game.ui_layer.find_child("TutorialMessagePanel", true, false) as Control
	var badge := game.ui_layer.find_child("TutorialClickBadge", true, false) as Control
	var focus_rect: Rect2 = game._tutorial_focus_rect(game._tutorial_effective_focus_id(game.tutorial_manager.current_step()))
	_expect(message != null and not message.get_global_rect().intersects(focus_rect), "%s keeps guidance clear of its live target" % step_id)
	_expect(badge != null and not badge.get_global_rect().intersects(focus_rect), "%s keeps the click badge clear of its live target" % step_id)
	if drawer_open:
		_expect(drawer != null and DESIGN_BOUNDS.encloses(drawer.get_global_rect()), "%s keeps its context drawer inside the canvas" % step_id)
		_expect(message != null and drawer != null and not message.get_global_rect().intersects(drawer.get_global_rect()), "%s keeps guidance clear of the management drawer" % step_id)
		_expect(badge != null and drawer != null and not badge.get_global_rect().intersects(drawer.get_global_rect()), "%s keeps the click badge clear of the management drawer" % step_id)
	else:
		_expect(drawer == null, "%s leaves the optional context drawer closed" % step_id)
	await _save("%s_%s_%s.png" % [_size_label(viewport_size), _day_label(day), step_id.to_lower()], viewport_size)


func _capture_combat(
	viewport_size: Vector2i,
	day: int,
	step_id: String,
	stage_id: String,
	enemy_id: String
) -> void:
	await _new_game(day)
	if day >= 2:
		game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	if day == 2:
		game.room_directives["spike_corridor"] = Constants.ROOM_DIRECTIVE_TRAP_LURE
	elif day == 3:
		game.room_directives["recovery"] = Constants.ROOM_DIRECTIVE_RETREAT
	_activate_tutorial_step(step_id, stage_id)
	game._onboarding_set_stage(
		"LV06_DAY02_MANAGEMENT_TREASURE"
		if day == 2
		else "LV09_DAY03_MANAGEMENT_HERO"
	)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._start_combat()
	await _settle(8)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "%s opens the actual combat screen" % step_id)
	if game.current_screen != Constants.SCREEN_COMBAT:
		await _save("%s_%s_%s_blocked.png" % [_size_label(viewport_size), _day_label(day), step_id.to_lower()], viewport_size)
		return
	game._onboarding_set_stage(stage_id)
	game.combat_paused = true
	game._spawn_enemy(enemy_id)
	await _settle(4)
	_place_combat_fixture(day, enemy_id)
	game.selected_unit = null
	game._set_screen(Constants.SCREEN_COMBAT)
	await _settle(8)
	_expect(_layout_matches(viewport_size), "%s uses the expected responsive layout at %s" % [step_id, _size_label(viewport_size)])
	_expect_combat_rails(step_id)
	_expect_tutorial_overlay(step_id, Constants.SCREEN_COMBAT)
	if step_id == "TUT_240_BOSS_HP":
		_expect(
			game._tutorial_registered_target_rect("BossHpBar").has_area(),
			"%s resolves the live boss-health target after the combat HUD rebuild" % step_id
		)
	await _save("%s_%s_%s.png" % [_size_label(viewport_size), _day_label(day), step_id.to_lower()], viewport_size)


func _capture_result(viewport_size: Vector2i, day: int, win: bool) -> void:
	await _new_game(day)
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.result_summary = _result_summary(day, win)
	game.last_growth_summary = _growth_summary()
	game.result_summary["growth"] = game.last_growth_summary.duplicate(true)
	# 승리 화면은 실제 집중 성장 선택이 필요한 상태로 캡처한다.
	game.result_growth_reviewed = not win
	GameState.victory = false
	GameState.defeat = not win
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(8)
	var label := "%s result" % _day_label(day)
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
	await _save("%s_%s_result_%s.png" % [_size_label(viewport_size), _day_label(day), "win" if win else "loss"], viewport_size)


func _new_game(day: int) -> void:
	await _dispose_game()
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(8)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	GameState.day = day
	GameState.max_day = 30
	GameState.player_name = "stage11-cascade-audit"
	GameState.victory = false
	GameState.defeat = false
	GameState.onboarding_complete = true
	game._setup_dungeon_graph()
	game._init_room_directives()
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


func _activate_tutorial_step(step_id: String, stage_id: String) -> void:
	var step_index := -1
	for index in range(game.tutorial_manager.steps.size()):
		if str(game.tutorial_manager.steps[index].get("id", "")) == step_id:
			step_index = index
			break
	_expect(step_index >= 0, "cascade fixture contains %s" % step_id)
	if step_index < 0:
		return
	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	game.tutorial_manager.current_index = step_index
	game.tutorial_manager.active = true
	game._onboarding_set_stage(stage_id)


func _place_combat_fixture(day: int, enemy_id: String) -> void:
	var monster_id := "goblin" if day == 2 else "imp"
	var monster_room := "barracks" if day == 2 else "recovery"
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


func _expect_combat_rails(step_id: String) -> void:
	var rail_names := [
		"CombatThroneStatus",
		"CombatThreat",
		"CombatTacticsPanel",
		"CombatCommandBar"
	]
	var rects: Array[Rect2] = []
	for rail_name in rail_names:
		var rail := game.ui_layer.find_child(rail_name, true, false) as Control
		_expect(rail != null, "%s builds %s" % [step_id, rail_name])
		if rail == null:
			continue
		var rect := rail.get_global_rect()
		_expect(DESIGN_BOUNDS.encloses(rect), "%s keeps %s inside the canvas" % [step_id, rail_name])
		rects.append(rect)
	for left_index in range(rects.size()):
		for right_index in range(left_index + 1, rects.size()):
			_expect(
				not rects[left_index].intersects(rects[right_index]),
				"%s keeps combat rails from overlapping" % step_id
			)


func _expect_tutorial_overlay(step_id: String, screen_id: String) -> void:
	var overlay := game.ui_layer.find_child("TutorialOverlay", true, false) as Control
	var message := game.ui_layer.find_child("TutorialMessagePanel", true, false) as Control
	_expect(overlay != null, "%s creates tutorial guidance on the actual %s screen" % [step_id, screen_id])
	_expect(message != null and DESIGN_BOUNDS.encloses(message.get_global_rect()), "%s keeps its guidance card inside the canvas" % step_id)
	if message == null:
		return
	if screen_id == Constants.SCREEN_COMBAT:
		var command_bar := game.ui_layer.find_child("CombatCommandBar", true, false) as Control
		var throne_status := game.ui_layer.find_child("CombatThroneStatus", true, false) as Control
		var threat := game.ui_layer.find_child("CombatThreat", true, false) as Control
		_expect(command_bar != null and not message.get_global_rect().intersects(command_bar.get_global_rect()), "%s keeps guidance clear of the command rail" % step_id)
		_expect(throne_status != null and not message.get_global_rect().intersects(throne_status.get_global_rect()), "%s keeps guidance clear of throne status" % step_id)
		_expect(threat == null or not message.get_global_rect().intersects(threat.get_global_rect()), "%s keeps guidance clear of the threat rail" % step_id)


func _result_summary(day: int, win: bool) -> Dictionary:
	return {
		"win": win,
		"lines": [],
		"metrics": {
			"day": day,
			"alive_monsters": 3 if win else 1,
			"total_monsters": 3,
			"treasure_gold_stolen": 0 if win else 35,
			"facility_disables": 0 if win else 1,
			"final_breach_segment": "가시 복도" if win else "병영 → 왕좌",
			"monster_contributions": {
				"goblin": {"damage_absorbed": 24, "damage_dealt": 52},
				"imp": {"damage_absorbed": 8, "damage_dealt": 71}
			},
			"decision_context": {
				"day": day,
				"directive_id": "defense",
				"directive_name": "사수",
				"monster_placements": [{
					"monster_id": "goblin" if day == 2 else "imp",
					"monster_name": "곱" if day == 2 else "핀",
					"room_id": "barracks" if day == 2 else "recovery",
					"room_name": "병영" if day == 2 else "회복 둥지",
					"defense_zone_id": "zone_a_front" if day == 2 else "zone_a_rear"
				}]
			}
		},
		"v122_ledger": {
			"throne_damage": 0 if win else 180,
			"gold_stolen": 0 if win else 35,
			"breach_progress": 0.28 if win else 0.84,
			"final_breach_segment": "가시 복도" if win else "병영 → 왕좌",
			"facility_contribution": {},
			"command_contribution": {},
			"events": []
		}
	}


func _growth_summary() -> Array:
	return [
		{"monster_id": "slime", "display_name": "푸딩", "level_before": 1, "level_after": 2, "levels_gained": 1, "exp_before": 42, "exp_after": 8, "exp_gain": 16, "next_exp": 80},
		{"monster_id": "goblin", "display_name": "곱", "level_before": 1, "level_after": 1, "levels_gained": 0, "exp_before": 18, "exp_after": 44, "exp_gain": 26, "next_exp": 50},
		{"monster_id": "imp", "display_name": "핀", "level_before": 1, "level_after": 1, "levels_gained": 0, "exp_before": 12, "exp_after": 39, "exp_gain": 27, "next_exp": 50}
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


func _day_label(day: int) -> String:
	return "day%02d" % day


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
