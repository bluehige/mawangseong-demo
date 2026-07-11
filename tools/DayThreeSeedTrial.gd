extends "res://tools/DayOneToThreePlaytestRecorder.gd"

const TRIAL_SEEDS = [20260711, 20260729, 20260747]
const POSITION_JITTER_PIXELS = Vector2(12.0, 8.0)
const TIMELINE_INTERVAL_SECONDS = 15.0
const PROFILE_BASELINES = {
	"balanced": {
		"resources": {"gold": 1573, "mana": 408, "food": 24, "infamy": 668},
		"roster": {"slime": [2, 5, "entrance"], "goblin": [2, 8, "barracks"], "imp": [1, 45, "recovery"]},
		"preparation": ["goblin", "pursuit_drill"]
	},
	"aggressive": {
		"resources": {"gold": 1573, "mana": 318, "food": 22, "infamy": 668},
		"roster": {"slime": [1, 45, "entrance"], "goblin": [2, 14, "barracks"], "imp": [1, 46, "recovery"]},
		"preparation": ["goblin", "pursuit_drill"]
	},
	"fortified": {
		"resources": {"gold": 1573, "mana": 408, "food": 24, "infamy": 668},
		"roster": {"slime": [2, 15, "entrance"], "goblin": [1, 48, "barracks"], "imp": [1, 44, "recovery"]},
		"preparation": ["slime", "reinforced_body"]
	},
	"survival": {
		"resources": {"gold": 1673, "mana": 378, "food": 24, "infamy": 668},
		"roster": {"slime": [2, 4, "entrance"], "goblin": [1, 48, "barracks"], "imp": [2, 3, "entrance"]},
		"preparation": ["slime", "reinforced_body"]
	},
	"minimal": {
		"resources": {"gold": 1673, "mana": 458, "food": 24, "infamy": 668},
		"roster": {"slime": [2, 5, "entrance"], "goblin": [2, 7, "barracks"], "imp": [1, 45, "recovery"]},
		"preparation": ["goblin", "pursuit_drill"]
	}
}

var trial_seed := 0

func _ready() -> void:
	var log_collector = Callable(self, "_collect_log")
	if not SignalBus.log_added.is_connected(log_collector):
		SignalBus.log_added.connect(log_collector)
	call_deferred("_run_trial")

func _run_trial() -> void:
	_read_trial_arguments()
	if failed:
		get_tree().quit(1)
		return
	proxy_mode = true
	simulation_time_scale = SIM_TIME_SCALE
	max_sim_seconds = 270.0
	Engine.time_scale = simulation_time_scale
	output_dir = ProjectSettings.globalize_path("res://tmp/day3_seed_matrix/trials")
	DirAccess.make_dir_recursive_absolute(output_dir)
	print("DAY3_SEED_TRIAL: START %s %d" % [proxy_profile_id, trial_seed])

	var game = GameRootScene.instantiate()
	add_child(game)
	await _settle(2)
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await _settle(1)
	_prepare_day_three_baseline(game)
	var choices := _prepare_day(game, 3)
	var log_start_index := log_messages.size()
	seed(trial_seed)

	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "DAY 3 전투 화면 진입")
	game.combat_speed = TEST_COMBAT_SPEED
	var initial_offsets := _apply_seed_position_jitter(game)
	var elapsed := 0.0
	var skill_uses := 0
	var thief_reached_treasure := false
	var assist_mode := _profile_assist(3)
	var timeline: Array[Dictionary] = [_timeline_snapshot(game, 0.0)]
	var next_timeline_second := TIMELINE_INTERVAL_SECONDS
	while game.current_screen != Constants.SCREEN_RESULT and elapsed < max_sim_seconds:
		skill_uses += _apply_assist(game, assist_mode)
		if _any_thief_in_treasure(game):
			thief_reached_treasure = true
		await get_tree().physics_frame
		elapsed += PHYSICS_STEP * simulation_time_scale * TEST_COMBAT_SPEED
		if elapsed >= next_timeline_second:
			timeline.append(_timeline_snapshot(game, elapsed))
			next_timeline_second += TIMELINE_INTERVAL_SECONDS
	_apply_result_growth_choice(game, choices)
	await get_tree().process_frame
	var record := _collect_day_record(game, 3, elapsed, skill_uses, thief_reached_treasure, choices, log_start_index)
	record["seed"] = trial_seed
	record["initial_offsets"] = initial_offsets
	record["timeline"] = timeline
	_verify_trial_record(record)

	var report := {
		"tool": "DayThreeSeedTrial",
		"evidence_kind": "automated_proxy_seed_trial",
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"proxy_profile": proxy_profile_id,
		"proxy_profile_label": _profile_label(proxy_profile_id),
		"seed": trial_seed,
		"position_jitter_pixels": [POSITION_JITTER_PIXELS.x, POSITION_JITTER_PIXELS.y],
		"baseline_source": "DAY 1~2 자동 대리 플레이 완료 상태",
		"failed": failed,
		"trial": record
	}
	var path := output_dir.path_join("%s_%d.json" % [proxy_profile_id, trial_seed])
	_write_text(path, JSON.stringify(report, "\t") + "\n")
	game.queue_free()
	await _settle(2)
	Engine.time_scale = 1.0
	print("DAY3_SEED_TRIAL_JSON: %s" % path)
	print("DAY3_SEED_TRIAL: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)

func _read_trial_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--proxy-profile="):
			proxy_profile_id = argument.trim_prefix("--proxy-profile=")
		elif argument.begins_with("--trial-seed="):
			trial_seed = int(argument.trim_prefix("--trial-seed="))
	if not PROXY_PROFILE_IDS.has(proxy_profile_id):
		_fail("알 수 없는 DAY 3 프로필: %s" % proxy_profile_id)
	if not TRIAL_SEEDS.has(trial_seed):
		_fail("허용되지 않은 DAY 3 시작값: %d" % trial_seed)

func _prepare_day_three_baseline(game: Node) -> void:
	GameState.day = 3
	GameState.victory = false
	GameState.defeat = false
	GameState.demon_lord_hp = GameState.demon_lord_max_hp
	var chosen: bool = game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	_expect(chosen, "DAY 3 고블린 도둑 사냥꾼 특화 적용")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	var facility_id := str(_profile_settings().get("facility", ""))
	if facility_id != "":
		_expect(game._change_room_facility("slot_01", facility_id), "DAY 3 %s 기준 시설 적용" % _facility_label(facility_id))
	var baseline: Dictionary = PROFILE_BASELINES[proxy_profile_id]
	for monster_id in baseline.get("roster", {}).keys():
		var values: Array = baseline["roster"][monster_id]
		game.monster_roster[monster_id]["level"] = int(values[0])
		game.monster_roster[monster_id]["exp"] = int(values[1])
		game.monster_roster[monster_id]["room"] = str(values[2])
	var preparation: Array = baseline.get("preparation", [])
	if preparation.size() >= 2:
		var prepared_monster_id := str(preparation[0])
		game.monster_roster[prepared_monster_id]["growth_preparation_id"] = str(preparation[1])
		game.monster_roster[prepared_monster_id]["growth_preparation_day"] = 3
		_expect(game._growth_preparation_active(prepared_monster_id), "DAY 3 집중 성장 준비 효과 적용")
	if game.has_method("_relocate_invalid_monsters"):
		game._relocate_invalid_monsters()
	var resources: Dictionary = baseline.get("resources", {})
	GameState.gold = int(resources.get("gold", 0))
	GameState.mana = int(resources.get("mana", 0))
	GameState.food = int(resources.get("food", 0))
	GameState.infamy = int(resources.get("infamy", 0))
	SignalBus.resources_changed.emit()

func _apply_seed_position_jitter(game: Node) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = trial_seed
	var offsets: Dictionary = {}
	var units: Array = game.monster_units + game.enemy_units
	for index in range(units.size()):
		var unit = units[index]
		if not unit.is_alive():
			continue
		var requested := Vector2(
			rng.randf_range(-POSITION_JITTER_PIXELS.x, POSITION_JITTER_PIXELS.x),
			rng.randf_range(-POSITION_JITTER_PIXELS.y, POSITION_JITTER_PIXELS.y)
		)
		var before: Vector2 = unit.global_position
		unit.global_position = game._clamp_to_combat_walkable(before + requested)
		unit.stop_navigation()
		var applied: Vector2 = unit.global_position - before
		offsets["%s:%s:%d" % [unit.faction, unit.unit_id, index]] = [snappedf(applied.x, 0.1), snappedf(applied.y, 0.1)]
	game.combat_scene.refresh_unit_rooms()
	return offsets

func _verify_trial_record(record: Dictionary) -> void:
	var result := str(record.get("result", ""))
	_expect(not bool(record.get("timed_out", false)), "DAY 3 전투가 제한 시간 안에 결산 도달")
	_expect(result in ["win", "loss"], "DAY 3 승패 결과 기록")
	_expect(int(record.get("total_monster_hp", 0)) > 0, "DAY 3 몬스터 전체 체력 기준 기록")
	_expect((record.get("growth", []) as Array).size() >= 3, "DAY 3 몬스터 성장 기록 3명 이상")
	_expect((record.get("result_lines", []) as Array).size() >= 8, "DAY 3 결산 문구 기록")
	_expect(not (record.get("timeline", []) as Array).is_empty(), "DAY 3 15초 간격 전투 진단 기록")
	if result == "win":
		_expect(int(record.get("enemy_down", 0)) == int(record.get("spawned", -1)), "DAY 3 승리 시 적 전원 격퇴")
		_expect(int(record.get("throne_hp", 0)) > 0, "DAY 3 승리 시 마왕성 체력 생존")
	else:
		_expect(int(record.get("throne_hp", -1)) == 0, "DAY 3 패배 시 마왕성 체력 소진")
	if _profile_assist(3) != "none":
		_expect(int(record.get("skill_uses", 0)) > 0, "DAY 3 스킬 보조 사용 기록")

func _timeline_snapshot(game: Node, elapsed: float) -> Dictionary:
	return {
		"elapsed_seconds": snappedf(elapsed, 0.1),
		"throne_hp": GameState.demon_lord_hp,
		"spawned": game.spawned_count,
		"enemy_down": game._count_downed_enemies(),
		"units": _live_unit_snapshot(game)
	}
