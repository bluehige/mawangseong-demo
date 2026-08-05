extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const FIXED_SEED := 20260730
const SIMULATION_TIME_SCALE := 8.0
const MAX_SIMULATED_SECONDS := 120.0
const OUTPUT_DIR := "res://tmp/day1_goblin_formation_compare"

var formation := "front"
var review_hold_seconds := 0.0
var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_read_arguments()
	if failed:
		get_tree().quit(1)
		return

	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	Engine.time_scale = SIMULATION_TIME_SCALE
	seed(FIXED_SEED)

	var game = GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.pending_title_reset_mode = "quick"
	game._onboarding_start_quick_game()
	await _settle(4)
	if game.current_screen == Constants.SCREEN_INTRUSION_BRIEF:
		game._enter_placement_from_brief()
		await _settle(4)

	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY 01 placement screen reached")
	game._start_monster_placement("goblin")
	await _settle(2)
	_expect(game.tutorial_manager.current_step_id() == "TUT_040_DEPLOY_SLIME", "Gob formation choice reached")
	var target_room := "barracks" if formation == "front" else "recovery"
	game._handle_left_click(game.graph.center(target_room))
	await _settle(3)

	var expected_zone := "zone_a_front" if formation == "front" else "zone_a_rear"
	var expected_combat_room := "spike_corridor" if formation == "front" else "path_a_front_rear"
	var goblin_roster: Dictionary = game.monster_roster.get("goblin", {})
	_expect(str(goblin_roster.get("defense_zone_id", "")) == expected_zone, "formation choice stored in the expected defense zone")

	game.update2_cycle_seed = FIXED_SEED
	seed(FIXED_SEED)
	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "DAY 01 combat started")
	var goblin = _unit_by_id(game.monster_units, "goblin")
	_expect(goblin != null and str(goblin.current_room) == expected_combat_room, "Gob spawned at the chosen combat anchor")

	var initial_snapshot := _unit_snapshot(goblin)
	var first_engagement: Dictionary = {}
	var simulated_seconds := 0.0
	while not game.result_summary.has("metrics") and simulated_seconds < MAX_SIMULATED_SECONDS:
		await get_tree().physics_frame
		simulated_seconds += (1.0 / 60.0) * SIMULATION_TIME_SCALE
		if first_engagement.is_empty() and _goblin_damage(game) > 0:
			first_engagement = _engagement_snapshot(game, goblin, simulated_seconds)
			game.combat_paused = true
			await _settle(3)
			await _save_screenshot(output_dir.path_join("%s_first_engagement.png" % formation))
			if review_hold_seconds > 0.0:
				await get_tree().create_timer(review_hold_seconds, true, false, true).timeout
			game.combat_paused = false

	_expect(not first_engagement.is_empty(), "Gob recorded a real first damaging engagement")
	await _drain_dialogue(game)
	_expect(game.current_screen == Constants.SCREEN_RESULT, "DAY 01 combat reached the actual result screen")
	await _settle(8)
	await _save_screenshot(output_dir.path_join("%s_result.png" % formation))

	var result_model: Dictionary = game.get_meta("v122_result_view_model", {})
	var decision_feedback: Dictionary = result_model.get("decision_feedback", {})
	var expected_strategy := "전방 봉쇄" if formation == "front" else "후방 화력"
	var expected_position := "전열" if formation == "front" else "후열"
	_expect(str(decision_feedback.get("strategy_label", "")) == expected_strategy, "result strategy wording matches the formation choice")
	_expect(str(decision_feedback.get("placement_label", "")).contains(expected_position), "result placement wording names the chosen line")

	var metrics: Dictionary = game.result_summary.get("metrics", {})
	var report := {
		"tool": "DayOneGoblinFormationPlayCompare",
		"evidence_kind": "automated_runtime_play_comparison",
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"formation": formation,
		"seed": FIXED_SEED,
		"simulation_time_scale": SIMULATION_TIME_SCALE,
		"chosen_room_id": target_room,
		"chosen_defense_zone_id": str(goblin_roster.get("defense_zone_id", "")),
		"initial_goblin": initial_snapshot,
		"first_engagement": first_engagement,
		"result": {
			"win": bool(game.result_summary.get("win", false)),
			"combat_time": float(metrics.get("combat_time", game.combat_time)),
			"remaining_monster_hp": int(metrics.get("remaining_monster_hp", 0)),
			"total_monster_hp": int(metrics.get("total_monster_hp", 0)),
			"alive_monsters": int(metrics.get("alive_monsters", 0)),
			"total_monsters": int(metrics.get("total_monsters", 0)),
			"goblin_contribution": metrics.get("monster_contributions", {}).get("goblin", {}).duplicate(true),
			"primary_cause_id": str(result_model.get("primary_cause_id", "")),
			"primary_cause_label": str(result_model.get("primary_cause_label", "")),
			"decision_feedback": decision_feedback.duplicate(true),
			"core_metrics": result_model.get("core_metrics", []).duplicate(true)
		},
		"failed": failed
	}
	var report_path := output_dir.path_join("%s.json" % formation)
	_write_text(report_path, JSON.stringify(report, "\t") + "\n")

	Engine.time_scale = 1.0
	print("DAY1_GOBLIN_FORMATION_COMPARE_JSON: %s" % report_path)
	print("DAY1_GOBLIN_FORMATION_COMPARE: %s (%s)" % ["FAIL" if failed else "PASS", formation])
	get_tree().quit(1 if failed else 0)


func _read_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--formation="):
			formation = argument.trim_prefix("--formation=")
		elif argument.begins_with("--review-hold-seconds="):
			review_hold_seconds = maxf(0.0, float(argument.trim_prefix("--review-hold-seconds=")))
	if formation not in ["front", "rear"]:
		_fail("Unsupported formation: %s" % formation)


func _goblin_damage(game: Node) -> int:
	return int(game.battle_contribution_stats.get("goblin", {}).get("damage_dealt", 0))


func _engagement_snapshot(game: Node, goblin: Node, simulated_seconds: float) -> Dictionary:
	var target = goblin.target if goblin != null and is_instance_valid(goblin.target) else _nearest_enemy(game, goblin)
	var snapshot := {
		"simulated_seconds": snappedf(simulated_seconds, 0.001),
		"combat_time": snappedf(float(game.combat_time), 0.001),
		"goblin": _unit_snapshot(goblin),
		"target": _unit_snapshot(target),
		"goblin_damage_dealt": _goblin_damage(game)
	}
	if goblin != null and target != null:
		snapshot["distance_pixels"] = snappedf(goblin.global_position.distance_to(target.global_position), 0.1)
	return snapshot


func _nearest_enemy(game: Node, source: Node) -> Node:
	if source == null:
		return null
	var nearest = null
	var best_distance := INF
	for enemy in game.enemy_units:
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance: float = source.global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			nearest = enemy
	return nearest


func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if is_instance_valid(unit) and str(unit.unit_id) == unit_id:
			return unit
	return null


func _unit_snapshot(unit: Node) -> Dictionary:
	if unit == null or not is_instance_valid(unit):
		return {}
	return {
		"unit_id": str(unit.unit_id),
		"current_room": str(unit.current_room),
		"goal_room": str(unit.goal_room),
		"tactical_state": str(unit.tactical_state),
		"position": [
			snappedf(float(unit.global_position.x), 0.1),
			snappedf(float(unit.global_position.y), 0.1)
		],
		"hp": int(unit.hp),
		"max_hp": int(unit.max_hp)
	}


func _save_screenshot(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Empty screenshot: %s" % path)
		return
	var error := image.save_png(path)
	if error != OK:
		_fail("Could not save screenshot %s (error %d)" % [path, error])


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not write report: %s" % path)
		return
	file.store_string(text)
	file.close()


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame


func _drain_dialogue(game: Node, max_steps: int = 180) -> void:
	var quiet_frames := 0
	for _index in range(max_steps):
		await get_tree().process_frame
		if game.current_screen == Constants.SCREEN_DIALOGUE:
			quiet_frames = 0
			game._onboarding_advance_dialogue()
		else:
			quiet_frames += 1
			if quiet_frames >= 5:
				return
	_fail("Timed out while draining the result dialogue")


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	failed = true
