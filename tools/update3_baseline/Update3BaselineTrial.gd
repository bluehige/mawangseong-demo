extends "res://tools/BalanceSimulation.gd"

const Spec = preload("res://tools/update3_baseline/Update3BaselineSpec.gd")
const FrontService = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const HeartService = preload("res://scripts/systems/hearts/CastleHeartService.gd")
const DuoService = preload("res://scripts/systems/duo_links/DuoLinkService.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")

const TRIAL_TIME_SCALE := 8.0
const TRIAL_COMBAT_SPEED := 1.5
const TRIAL_MAX_SIM_SECONDS := 270.0
const POSITION_JITTER_PIXELS := Vector2(12.0, 8.0)
const INTER_ROOM_PATH_SAMPLE_INTERVAL_SECONDS := 1.0
const INTER_ROOM_PATH_STALL_SECONDS := 12.0
const INTER_ROOM_PATH_STALL_MOVEMENT_PIXELS := 4.0
const INTER_ROOM_PATH_MOVING_STATES := ["move_to_room", "move_to_target", "retreat"]

var trial_index := -1
var baseline_run_id := ""
var commit_sha := ""
var output_path := ""
var hard_errors: Array[String] = []
var stall_trackers: Dictionary = {}
var inter_room_path_stalls: Array[Dictionary] = []


func _ready() -> void:
	var log_collector := Callable(self, "_collect_log")
	if not SignalBus.log_added.is_connected(log_collector):
		SignalBus.log_added.connect(log_collector)
	call_deferred("_run_trial")


func _run_trial() -> void:
	_read_arguments()
	if not hard_errors.is_empty():
		for error in hard_errors:
			push_error(error)
		get_tree().quit(2)
		return
	var expected := Spec.trial_for_index(trial_index)
	print("UPDATE3_BASELINE_TRIAL: START %s" % str(expected.get("trial_id", "")))
	Engine.time_scale = TRIAL_TIME_SCALE
	seed(int(expected.get("seed", 0)))
	DataRegistry.load_all()
	current_logs.clear()

	var game = GameRootScene.instantiate()
	add_child(game)
	await _settle(2)
	if game.has_method("_set_campaign_save_path_for_tests"):
		game._set_campaign_save_path_for_tests("", "", "", "")
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await _settle(1)
	GameState.day = Spec.DAY
	_configure_update3(game, expected)
	_apply_final_campaign_setup(game)
	_configure_deployment(game, expected)
	_set_initial_heart_charge(game)
	var operation_evidence := _capture_operation_evidence(game, expected)
	seed(int(expected.get("seed", 0)))
	game._start_combat()
	await get_tree().physics_frame

	var scheduled := _scheduled_validation(game, expected)
	operation_evidence["actual_schedule_signature"] = _schedule_signature(game.wave_manager.schedule)
	operation_evidence["schedule_effect_applied"] = bool(operation_evidence.get("schedule_effect_expected", false)) and str(operation_evidence.get("actual_schedule_signature", "")) == str(operation_evidence.get("expected_schedule_signature", ""))
	var actual_deployed := _active_monster_instance_ids(game)
	var duo_state: Dictionary = game.update3_active_run.get("duo_link_states", {}).get(str(expected.get("duo_link_id", "")), {})
	var duo_active_at_start := bool(duo_state.get("active", false))
	var actual_heart_id_at_start := str(game.update3_active_run.get("heart", {}).get("heart_id", ""))
	var heart_charge_at_start := int(game.update3_active_run.get("heart", {}).get("charge", -1))
	var actual_operation_id_at_start := str(game.update3_active_run.get("day28_front_operation", ""))
	_validate_start_state(game, expected, scheduled, actual_deployed, duo_active_at_start, actual_heart_id_at_start, heart_charge_at_start, actual_operation_id_at_start, operation_evidence)
	game.combat_speed = TRIAL_COMBAT_SPEED
	var initial_offsets := _apply_seed_position_jitter(game, int(expected.get("seed", 0)))

	var elapsed := 0.0
	var next_path_sample := 0.0
	var next_heart_attempt := 0.0
	var heart_activation_attempts := 0
	var heart_activation_succeeded := false
	while game.current_screen != Constants.SCREEN_RESULT and elapsed < TRIAL_MAX_SIM_SECONDS:
		if not heart_activation_succeeded and elapsed >= next_heart_attempt and _alive_enemy_count(game) >= 1:
			heart_activation_attempts += 1
			var activation_target := _heart_activation_target_room(game, str(expected.get("heart_id", "")))
			var activation: Dictionary = game._activate_update3_heart(activation_target)
			heart_activation_succeeded = bool(activation.get("ok", false))
			next_heart_attempt = elapsed + 1.0
		if elapsed >= next_path_sample:
			_sample_inter_room_path_stalls(game, elapsed)
			next_path_sample += INTER_ROOM_PATH_SAMPLE_INTERVAL_SECONDS
		await get_tree().physics_frame
		elapsed += PHYSICS_STEP * TRIAL_TIME_SCALE * TRIAL_COMBAT_SPEED

	var timed_out: bool = game.current_screen != Constants.SCREEN_RESULT
	if timed_out:
		hard_errors.append("전투가 %.1f초 simulation 제한 안에 끝나지 않았습니다." % TRIAL_MAX_SIM_SECONDS)
	if not heart_activation_succeeded:
		hard_errors.append("low_input_v1 심장 액티브가 성공하지 못했습니다.")
	if not inter_room_path_stalls.is_empty():
		hard_errors.append("방간 이동 경로 정지 %d건이 감지되었습니다." % inter_room_path_stalls.size())
	var outcome := _collect_outcome(game, expected, elapsed, timed_out, heart_activation_attempts, heart_activation_succeeded)
	var report := _build_report(game, expected, scheduled, actual_deployed, duo_active_at_start, actual_heart_id_at_start, heart_charge_at_start, actual_operation_id_at_start, operation_evidence, initial_offsets, outcome)
	var resolved_output_path := _global_path(output_path)
	DirAccess.make_dir_recursive_absolute(resolved_output_path.get_base_dir())
	var write_ok := _write_report(resolved_output_path, report)
	var hard_failure := bool(report.get("hard_failure", true)) or not write_ok

	game.queue_free()
	await _settle(2)
	Engine.time_scale = 1.0
	print("UPDATE3_BASELINE_TRIAL_JSON: %s" % resolved_output_path)
	print("UPDATE3_BASELINE_TRIAL: %s" % ("FAIL" if hard_failure else "PASS"))
	get_tree().quit(1 if hard_failure else 0)


func _read_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--trial-index="):
			trial_index = int(argument.trim_prefix("--trial-index="))
		elif argument.begins_with("--baseline-run-id="):
			baseline_run_id = argument.trim_prefix("--baseline-run-id=")
		elif argument.begins_with("--commit-sha="):
			commit_sha = argument.trim_prefix("--commit-sha=")
		elif argument.begins_with("--output-path="):
			output_path = argument.trim_prefix("--output-path=")
	if Spec.trial_for_index(trial_index).is_empty():
		hard_errors.append("trial-index는 0~%d여야 합니다." % (Spec.TRIAL_COUNT - 1))
	if baseline_run_id == "":
		hard_errors.append("baseline-run-id가 필요합니다.")
	if commit_sha.length() != 40:
		hard_errors.append("40자 commit SHA가 필요합니다.")
	if output_path == "":
		hard_errors.append("output-path가 필요합니다.")


func _configure_update3(game: Node, expected: Dictionary) -> void:
	game.campaign_cycle_index = 2
	var profile: Dictionary = FrontService.default_update3_profile()
	profile["fronts"]["unlocked"] = Spec.FRONT_IDS.duplicate()
	var active_run: Dictionary = FrontService.new_cycle_active_run(game.campaign_cycle_index)
	var front_result := FrontService.select_front(profile, active_run, str(expected.get("front_id", "")), DataRegistry.update3_fronts)
	if not bool(front_result.get("ok", false)):
		hard_errors.append("전선 fixture 설정 실패: %s" % str(front_result.get("error", "")))
		return
	profile = front_result.get("profile", profile).duplicate(true)
	active_run = front_result.get("active_run", active_run).duplicate(true)
	var heart_result := HeartService.select_heart(profile, active_run, str(expected.get("heart_id", "")), DataRegistry.update3_castle_hearts)
	if not bool(heart_result.get("ok", false)):
		hard_errors.append("심장 fixture 설정 실패: %s" % str(heart_result.get("error", "")))
		return
	profile = heart_result.get("profile", profile).duplicate(true)
	active_run = heart_result.get("active_run", active_run).duplicate(true)
	var duo_id := str(expected.get("duo_link_id", ""))
	var unlock_result := DuoService.unlock_fixture(profile, duo_id, DataRegistry.update3_duo_links)
	if not bool(unlock_result.get("ok", false)):
		hard_errors.append("합동기 fixture 해금 실패: %s" % str(unlock_result.get("error", "")))
		return
	profile = unlock_result.get("profile", profile).duplicate(true)
	var equip_result := DuoService.equip(profile, active_run, duo_id, DataRegistry.update3_duo_links)
	if not bool(equip_result.get("ok", false)):
		hard_errors.append("합동기 fixture 장착 실패: %s" % str(equip_result.get("error", "")))
		return
	active_run = equip_result.get("active_run", active_run).duplicate(true)
	active_run["duo_link_auto_use"] = true
	active_run["duo_link_loadout_confirmed"] = true
	var operation_result := FrontService.select_operation(active_run, str(expected.get("operation_id", "")), 28, DataRegistry.update3_front_operations)
	if not bool(operation_result.get("ok", false)):
		hard_errors.append("DAY 28 전선 작전 fixture 설정 실패: %s" % str(operation_result.get("error", "")))
		return
	active_run = operation_result.get("active_run", active_run).duplicate(true)
	game.update3_profile = profile
	game.update3_active_run = active_run
	game._sync_update3_heart_awaken()


func _configure_deployment(game: Node, expected: Dictionary) -> void:
	game.monster_roster.clear()
	game.deployed_instance_ids.clear()
	game.reserve_instance_ids.clear()
	for instance_id_value in expected.get("deployed_instance_ids", []):
		var instance_id := str(instance_id_value)
		var species_id := Spec.species_for_instance(instance_id)
		if not game._add_update3_monster_to_roster(species_id, instance_id):
			hard_errors.append("출전 roster 추가 실패: %s" % instance_id)
			continue
		game.monster_roster[species_id]["level"] = Spec.MONSTER_LEVEL
		game.monster_roster[species_id]["exp"] = 0
		game.monster_roster[species_id]["bond"] = Spec.MONSTER_BOND
		game.monster_roster[species_id]["bond_rank"] = game._monster_bond_rank(Spec.MONSTER_BOND)
		game.monster_roster[species_id]["defense_enabled"] = true
		game.deployed_instance_ids.append(instance_id)
	if not game.deployed_instance_ids.is_empty():
		game.selected_monster_id = Spec.species_for_instance(str(game.deployed_instance_ids[0]))
	game._relocate_invalid_monsters()
	if game.quarter_renderer != null:
		game.quarter_renderer.refresh_layout()


func _set_initial_heart_charge(game: Node) -> void:
	var heart: Dictionary = game.update3_active_run.get("heart", {}).duplicate(true)
	heart["charge"] = Spec.HEART_INITIAL_CHARGE
	game.update3_active_run["heart"] = heart


func _capture_operation_evidence(game: Node, expected: Dictionary) -> Dictionary:
	var operation_id := str(expected.get("operation_id", ""))
	var operation: Dictionary = DataRegistry.update3_front_operations.get(operation_id, {})
	var expected_modifier: Dictionary = operation.get("defense_modifier", {}).duplicate(true)
	var expected_modifier_id := str(expected_modifier.get("id", ""))
	var active_modifiers: Dictionary = game._active_defense_modifiers() if game.has_method("_active_defense_modifiers") else {}
	if game.has_method("_update2_seeded_wave_variant"):
		var seeded_variant: Dictionary = game._update2_seeded_wave_variant(Spec.DAY)
		if not seeded_variant.is_empty():
			active_modifiers["update2_seeded_variant"] = seeded_variant
	var active_modifier: Dictionary = active_modifiers.get(expected_modifier_id, {}) if expected_modifier_id != "" else {}
	var with_operation := WaveManagerScript.new()
	with_operation.setup(Spec.DAY, DataRegistry.waves, active_modifiers)
	var without_operation_modifiers := active_modifiers.duplicate(true)
	if expected_modifier_id != "":
		without_operation_modifiers.erase(expected_modifier_id)
	var without_operation := WaveManagerScript.new()
	without_operation.setup(Spec.DAY, DataRegistry.waves, without_operation_modifiers)
	var expected_signature := _schedule_signature(with_operation.schedule)
	var without_signature := _schedule_signature(without_operation.schedule)
	return {
		"expected_modifier_id": expected_modifier_id,
		"active_modifier_present": expected_modifier_id != "" and not active_modifier.is_empty(),
		"active_modifier_matches_catalog": active_modifier == expected_modifier,
		"expected_schedule_signature": expected_signature,
		"without_operation_schedule_signature": without_signature,
		"schedule_effect_expected": expected_signature != without_signature,
		"actual_schedule_signature": "",
		"schedule_effect_applied": false
	}


func _schedule_signature(schedule: Array) -> String:
	var rows: Array[String] = []
	for entry_value in schedule:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		rows.append("%s@%.4f|%.4f|%.4f|%.4f|%.4f|%s" % [
			str(entry.get("enemy_id", "")),
			float(entry.get("time", 0.0)),
			float(entry.get("hp_scale", 1.0)),
			float(entry.get("atk_scale", 1.0)),
			float(entry.get("def_scale", 1.0)),
			float(entry.get("morale_bonus", 0.0)),
			str(entry.get("_extra_source_modifier_key", ""))
		])
	return "||".join(rows)


func _scheduled_validation(game: Node, expected: Dictionary) -> Dictionary:
	var expected_boss_id := Spec.expected_boss(str(expected.get("front_id", "")))
	var final_boss_ids := Spec.EXPECTED_BOSS_BY_FRONT.values()
	var scheduled_enemy_ids: Array[String] = []
	var expected_count := 0
	var wrong_boss_ids: Array[String] = []
	for entry_value in game.wave_manager.schedule:
		var enemy_id := str(entry_value.get("enemy_id", ""))
		scheduled_enemy_ids.append(enemy_id)
		if enemy_id == expected_boss_id:
			expected_count += 1
		elif final_boss_ids.has(enemy_id) and not wrong_boss_ids.has(enemy_id):
			wrong_boss_ids.append(enemy_id)
	return {
		"expected_boss_id": expected_boss_id,
		"scheduled_boss_count": expected_count,
		"wrong_boss_ids": wrong_boss_ids,
		"scheduled_enemy_ids": scheduled_enemy_ids
	}


func _validate_start_state(game: Node, expected: Dictionary, scheduled: Dictionary, actual_deployed: Array[String], duo_active_at_start: bool, actual_heart_id: String, heart_charge_at_start: int, actual_operation_id: String, operation_evidence: Dictionary) -> void:
	if game.current_screen != Constants.SCREEN_COMBAT:
		hard_errors.append("DAY 30 전투 화면에 진입하지 못했습니다.")
	if GameState.day != Spec.DAY:
		hard_errors.append("실제 전투 일이 DAY 30이 아닙니다.")
	if str(game.castle_art_stage) != Spec.STAGE_ID:
		hard_errors.append("실제 성 단계가 Stage 04가 아닙니다.")
	if int(scheduled.get("scheduled_boss_count", 0)) != 1:
		hard_errors.append("기대 최종 보스가 schedule에 정확히 1명 있지 않습니다.")
	if not scheduled.get("wrong_boss_ids", []).is_empty():
		hard_errors.append("다른 전선의 최종 보스가 schedule에 포함되었습니다.")
	if actual_deployed.size() != 5:
		hard_errors.append("실제 출전 몬스터가 5명이 아닙니다: %d" % actual_deployed.size())
	for instance_id_value in expected.get("deployed_instance_ids", []):
		if not actual_deployed.has(str(instance_id_value)):
			hard_errors.append("예정된 출전 인스턴스가 생성되지 않았습니다: %s" % str(instance_id_value))
	if not duo_active_at_start:
		hard_errors.append("대상 합동기가 전투 시작 시 active가 아닙니다.")
	if actual_heart_id != str(expected.get("heart_id", "")):
		hard_errors.append("실제 심장 ID가 강제 배정과 다릅니다: %s" % actual_heart_id)
	if heart_charge_at_start != Spec.HEART_INITIAL_CHARGE:
		hard_errors.append("전투 시작 심장 charge가 100이 아닙니다: %d" % heart_charge_at_start)
	if actual_operation_id != str(expected.get("operation_id", "")):
		hard_errors.append("실제 DAY 28 작전이 강제 배정과 다릅니다: %s" % actual_operation_id)
	if not bool(operation_evidence.get("active_modifier_present", false)):
		hard_errors.append("선택한 DAY 28 작전의 DAY 30 defense_modifier가 활성 목록에 없습니다.")
	if not bool(operation_evidence.get("active_modifier_matches_catalog", false)):
		hard_errors.append("활성 DAY 28 작전 modifier가 catalog 정의와 다릅니다.")
	if not bool(operation_evidence.get("schedule_effect_expected", false)):
		hard_errors.append("고정 DAY 28 작전 modifier가 DAY 30 schedule을 바꾸지 않습니다.")
	if not bool(operation_evidence.get("schedule_effect_applied", false)):
		hard_errors.append("선택한 DAY 28 작전 modifier가 실제 DAY 30 schedule에 반영되지 않았습니다.")


func _active_monster_instance_ids(game: Node) -> Array[String]:
	var result: Array[String] = []
	for unit in game.monster_units:
		if not is_instance_valid(unit):
			continue
		var instance_id := str(game._update3_unit_instance_id(unit))
		if instance_id != "" and not result.has(instance_id):
			result.append(instance_id)
	return result


func _heart_activation_target_room(game: Node, heart_id: String) -> String:
	if heart_id == HeartService.DREAM_LANTERN_ID:
		var room_ids: Array = game.rooms.keys()
		room_ids.sort()
		for room_id_value in room_ids:
			var room_id := str(room_id_value)
			if str(game.rooms.get(room_id, {}).get("type", "")) == "build_slot":
				continue
			if not game._update3_dream_target_entries(room_id).is_empty():
				return room_id
	if heart_id == HeartService.HUNGRY_MAW_ID:
		return str(game._update3_devouring_target_room())
	return ""


func _apply_seed_position_jitter(game: Node, trial_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = trial_seed
	var offsets: Dictionary = {}
	var units: Array = game.monster_units + game.enemy_units
	for index in range(units.size()):
		var unit = units[index]
		if not is_instance_valid(unit) or not unit.is_alive():
			continue
		var requested := Vector2(rng.randf_range(-POSITION_JITTER_PIXELS.x, POSITION_JITTER_PIXELS.x), rng.randf_range(-POSITION_JITTER_PIXELS.y, POSITION_JITTER_PIXELS.y))
		var before: Vector2 = unit.global_position
		unit.global_position = game._clamp_to_combat_walkable(before + requested)
		unit.stop_navigation()
		var applied: Vector2 = unit.global_position - before
		offsets["%s:%s:%d" % [unit.faction, unit.unit_id, index]] = [snappedf(applied.x, 0.1), snappedf(applied.y, 0.1)]
	game.combat_scene.refresh_unit_rooms()
	return offsets


func _sample_inter_room_path_stalls(game: Node, elapsed: float) -> void:
	var seen: Dictionary = {}
	for faction_group in [["monster", game.monster_units], ["enemy", game.enemy_units]]:
		for unit in faction_group[1]:
			if not is_instance_valid(unit):
				continue
			var tracker_id := str(unit.get_instance_id())
			seen[tracker_id] = true
			var moving: bool = (
				unit.is_alive()
				and str(unit.tactical_state) in INTER_ROOM_PATH_MOVING_STATES
				and str(unit.current_room) != str(unit.goal_room)
				and not unit.path_points.is_empty()
			)
			if not moving:
				stall_trackers.erase(tracker_id)
				continue
			var position: Vector2 = unit.global_position
			if not stall_trackers.has(tracker_id):
				stall_trackers[tracker_id] = {"position": position, "sample_time": elapsed, "stationary_seconds": 0.0, "reported": false}
				continue
			var tracker: Dictionary = stall_trackers[tracker_id]
			var sample_delta := maxf(0.0, elapsed - float(tracker.get("sample_time", elapsed)))
			if position.distance_to(tracker.get("position", position)) < INTER_ROOM_PATH_STALL_MOVEMENT_PIXELS:
				tracker["stationary_seconds"] = float(tracker.get("stationary_seconds", 0.0)) + sample_delta
			else:
				tracker["stationary_seconds"] = 0.0
			tracker["position"] = position
			tracker["sample_time"] = elapsed
			if float(tracker.get("stationary_seconds", 0.0)) >= INTER_ROOM_PATH_STALL_SECONDS and not bool(tracker.get("reported", false)):
				tracker["reported"] = true
				inter_room_path_stalls.append({
					"faction": str(faction_group[0]),
					"unit_id": str(unit.unit_id),
					"tactical_state": str(unit.tactical_state),
					"room": str(unit.current_room),
					"goal_room": str(unit.goal_room),
					"path_point_count": unit.path_points.size(),
					"stationary_seconds": snappedf(float(tracker.get("stationary_seconds", 0.0)), 0.1),
					"position": [snappedf(position.x, 0.1), snappedf(position.y, 0.1)]
				})
			stall_trackers[tracker_id] = tracker
	for tracker_id in stall_trackers.keys():
		if not seen.has(tracker_id):
			stall_trackers.erase(tracker_id)


func _alive_enemy_count(game: Node) -> int:
	var count := 0
	for enemy in game.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive():
			count += 1
	return count


func _collect_outcome(game: Node, expected: Dictionary, elapsed: float, timed_out: bool, heart_attempts: int, heart_succeeded: bool) -> Dictionary:
	var result := "timeout"
	if not timed_out:
		result = "win" if bool(game.result_summary.get("win", false)) else "loss"
	var metrics: Dictionary = game.result_summary.get("metrics", {})
	var raw_contributions: Dictionary = metrics.get("monster_contributions", game.battle_contribution_stats).duplicate(true)
	var contribution_by_species: Dictionary = {}
	for species_id_value in raw_contributions.keys():
		var contribution: Dictionary = raw_contributions.get(species_id_value, {})
		contribution_by_species[str(species_id_value)] = (
			maxi(0, int(contribution.get("damage_dealt", 0)))
			+ maxi(0, int(contribution.get("damage_absorbed", 0)))
			+ maxi(0, int(contribution.get("facility_value", 0)))
			+ maxi(0, int(contribution.get("finishing_blows", 0))) * 50
		)
	var heart: Dictionary = game.update3_active_run.get("heart", {})
	var update3_metrics: Dictionary = game.update3_active_run.get("run_metrics_update3", {})
	var duo_id := str(expected.get("duo_link_id", ""))
	var duo_state: Dictionary = game.update3_active_run.get("duo_link_states", {}).get(duo_id, {})
	var day30_links: Array = update3_metrics.get("link_skills_used_day30", [])
	return {
		"result": result,
		"timed_out": timed_out,
		"elapsed_proxy_seconds": snappedf(elapsed, 0.1),
		"combat_time_seconds": snappedf(float(metrics.get("combat_time", game.combat_time)), 0.1),
		"throne_hp": int(metrics.get("demon_lord_hp", GameState.demon_lord_hp)),
		"throne_max_hp": GameState.demon_lord_max_hp,
		"alive_monsters": int(metrics.get("alive_monsters", 0)),
		"total_monsters": int(metrics.get("total_monsters", game.monster_units.size())),
		"remaining_monster_hp": int(metrics.get("remaining_monster_hp", 0)),
		"total_monster_hp": int(metrics.get("total_monster_hp", 0)),
		"heart_activation_attempts": heart_attempts,
		"heart_active_succeeded": heart_succeeded,
		"heart_active_used": heart_succeeded or bool(heart.get("active_used_this_battle", false)),
		"heart_chamber_disabled": bool(heart.get("disabled_this_battle", false)) or int(heart.get("chamber_hp", 1)) <= 0,
		"duo_used": bool(duo_state.get("used_this_battle", false)) or day30_links.has(duo_id),
		"contribution_by_species": contribution_by_species,
		"raw_monster_contributions": raw_contributions
	}


func _build_report(game: Node, expected: Dictionary, scheduled: Dictionary, actual_deployed: Array[String], duo_active_at_start: bool, actual_heart_id_at_start: String, heart_charge_at_start: int, actual_operation_id_at_start: String, operation_evidence: Dictionary, initial_offsets: Dictionary, outcome: Dictionary) -> Dictionary:
	return {
		"schema_version": Spec.SCHEMA_VERSION,
		"tool": "Update3BaselineTrial",
		"evidence_kind": Spec.TRIAL_EVIDENCE_KIND,
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"run_id": baseline_run_id,
		"commit_sha": commit_sha,
		"fixture_version": Spec.FIXTURE_VERSION,
		"policy_id": Spec.POLICY_ID,
		"assignment_kind": "forced_automated_proxy",
		"trial_index": trial_index,
		"trial_id": str(expected.get("trial_id", "")),
		"row_id": str(expected.get("row_id", "")),
		"seed": int(expected.get("seed", 0)),
		"assignment": {
			"front_id": str(expected.get("front_id", "")),
			"heart_id": str(expected.get("heart_id", "")),
			"duo_link_id": str(expected.get("duo_link_id", "")),
			"operation_id": str(expected.get("operation_id", "")),
			"deployed_instance_ids": expected.get("deployed_instance_ids", []).duplicate()
		},
		"configuration": {
			"day": Spec.DAY,
			"stage_id": Spec.STAGE_ID,
			"monster_level": Spec.MONSTER_LEVEL,
			"monster_bond": Spec.MONSTER_BOND,
			"heart_initial_charge": Spec.HEART_INITIAL_CHARGE,
			"time_scale": TRIAL_TIME_SCALE,
			"combat_speed": TRIAL_COMBAT_SPEED,
			"position_jitter_pixels": [POSITION_JITTER_PIXELS.x, POSITION_JITTER_PIXELS.y]
		},
		"validation": {
			"expected_boss_id": str(scheduled.get("expected_boss_id", "")),
			"scheduled_boss_count": int(scheduled.get("scheduled_boss_count", 0)),
			"wrong_boss_ids": scheduled.get("wrong_boss_ids", []).duplicate(),
			"scheduled_enemy_ids": scheduled.get("scheduled_enemy_ids", []).duplicate(),
			"deployed_count": actual_deployed.size(),
			"actual_deployed_instance_ids": actual_deployed,
			"duo_active_at_start": duo_active_at_start,
			"actual_heart_id_at_start": actual_heart_id_at_start,
			"heart_charge_at_start": heart_charge_at_start,
			"heart_active_succeeded": bool(outcome.get("heart_active_succeeded", false)),
			"expected_operation_id": str(expected.get("operation_id", "")),
			"actual_operation_id_at_start": actual_operation_id_at_start,
			"expected_operation_modifier_id": str(operation_evidence.get("expected_modifier_id", "")),
			"operation_modifier_present": bool(operation_evidence.get("active_modifier_present", false)),
			"operation_modifier_matches_catalog": bool(operation_evidence.get("active_modifier_matches_catalog", false)),
			"operation_schedule_effect_expected": bool(operation_evidence.get("schedule_effect_expected", false)),
			"operation_schedule_effect_applied": bool(operation_evidence.get("schedule_effect_applied", false)),
			"expected_operation_schedule_signature": str(operation_evidence.get("expected_schedule_signature", "")),
			"actual_operation_schedule_signature": str(operation_evidence.get("actual_schedule_signature", "")),
			"without_operation_schedule_signature": str(operation_evidence.get("without_operation_schedule_signature", "")),
			"inter_room_path_stall_count": inter_room_path_stalls.size(),
			"inter_room_path_stalls": inter_room_path_stalls.duplicate(true)
		},
		"outcome": outcome,
		"initial_offsets": initial_offsets,
		"hard_failure": not hard_errors.is_empty(),
		"errors": hard_errors.duplicate(),
		"log_tail": current_logs.slice(maxi(0, current_logs.size() - 30), current_logs.size())
	}


func _global_path(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("res://") or path.begins_with("user://") else path


func _write_report(path: String, report: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Update3 baseline trial을 저장하지 못했습니다: %s" % path)
		return false
	file.store_string(JSON.stringify(report, "\t") + "\n")
	return true


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
