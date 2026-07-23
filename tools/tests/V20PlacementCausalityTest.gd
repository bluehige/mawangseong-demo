extends Node

const BattleEvidence = preload("res://scripts/v20/combat/V20BattleEvidence.gd")
const FacilityService = preload("res://scripts/v20/facilities/V20FacilityService.gd")
const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const SaveStore = preload("res://scripts/v20/save/V20SaveStore.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const Constants = preload("res://scripts/core/Constants.gd")

const DAY_ONE_SEED := 2001
const MAX_NATURAL_FRAMES := 7200
const CANDIDATE_FIXTURE_PATH := "res://tools/tests/fixtures/v20/day_response_scenarios.json"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	if not OS.get_cmdline_user_args().has("--candidate-only"):
		_test_ledger_metric_rules()
		_test_facility_effect_zone_moves()
		await _test_home_zone_actual_spawn()
		await _test_command_applies_to_all_living_monsters()
		await _test_engineer_disable_actual_effect_gap()
		await _test_thief_goal_loot_escape_with_decoy()
		await _test_day_one_a_d_natural_combat()
	await _test_day_one_to_five_candidate_runs()
	if failed:
		print("V20_PLACEMENT_CAUSALITY_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_PLACEMENT_CAUSALITY_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_ledger_metric_rules() -> void:
	var state := BattleEvidence.new_state(5, 2005, _board(), 1500, 440)
	var monster := _actor("monster:slime", "slime", "monster", Vector2(610.56, 364.48), "gate_outpost", "", true, true)
	var explorer := _actor("enemy:explorer:1", "explorer", "enemy", Vector2(620.0, 390.0), "gate_outpost", "throne", true, true)
	BattleEvidence.record_spawn(state, monster, 0)
	BattleEvidence.record_spawn(state, explorer, 0)
	BattleEvidence.record_damage(state, 60, monster, explorer, 20)
	BattleEvidence.sample_frame(state, 60, [monster, explorer])
	BattleEvidence.sample_frame(state, 240, [monster, explorer])
	BattleEvidence.record_facility_disable_started(state, 120, "front", "v20_barricade", "gate_outpost", Vector2(610.56, 391.36))
	BattleEvidence.record_facility_disable_ended(state, 300, "front")
	var archer := _actor("enemy:archer:1", "anti_magic_archer", "enemy", Vector2(800.0, 480.0), "spike_corridor", "throne", true, true)
	archer["protected"] = true
	archer["targetable"] = true
	archer["protection_window_id"] = "enemy:shield:1"
	BattleEvidence.record_spawn(state, archer, 100)
	BattleEvidence.record_damage(state, 100, archer, monster, 8)
	BattleEvidence.sample_frame(state, 100, [monster, explorer, archer])
	archer["protected"] = false
	BattleEvidence.sample_frame(state, 220, [monster, explorer, archer])
	var reinforcement := _actor("enemy:explorer:2", "explorer", "enemy", Vector2(1081.0, 431.0), "central_battle_room", "throne", true, true)
	reinforcement["second_phase"] = true
	BattleEvidence.record_spawn(state, reinforcement, 200)
	BattleEvidence.sample_frame(state, 200, [monster, explorer, archer, reinforcement])
	reinforcement["world_position"] = [1363.2, 579.52]
	reinforcement["zone_id"] = "throne_anteroom"
	BattleEvidence.sample_frame(state, 230, [monster, explorer, archer, reinforcement])
	reinforcement["world_position"] = [1551.36, 485.44]
	reinforcement["zone_id"] = "throne"
	BattleEvidence.sample_frame(state, 260, [monster, explorer, archer, reinforcement])
	BattleEvidence.record_loot(state, 270, reinforcement, 100)
	BattleEvidence.record_throne_damage(state, 280, reinforcement, 150, 1350)
	var metrics := BattleEvidence.finalize(state, 360, [monster, explorer, archer, reinforcement], 1350)
	_expect(str(metrics.get("first_engagement_zone", "")) == "gate_outpost" and int(metrics.get("first_engagement_frame", -1)) == 60, "첫 몬스터↔적 피해 frame 60과 gate_outpost 기록")
	_expect(float(metrics.get("frontline_hold_seconds", 0.0)) >= 3.0, "첫 교전 양측 생존 frame union을 3초 이상 계산")
	_expect(is_equal_approx(float(metrics.get("max_contiguous_facility_disabled_seconds", 0.0)), 3.0), "시설 무력화 frame 120~300을 연속 3초로 계산")
	_expect(is_equal_approx(float(metrics.get("protection_bypass_seconds", 0.0)), 2.0) and int(metrics.get("shield_breaks", 0)) == 1, "보호 무시 겹침은 union 2초·effect window당 방패 파괴 1회")
	_expect(is_equal_approx(float(metrics.get("rear_pressure_seconds", 0.0)), 2.0), "보호받는 궁수의 실제 공격부터 보호 종료까지 후열 압박 2초")
	_expect(int(metrics.get("fallback_breaches", 0)) == 1 and int(metrics.get("second_phase_leaks", 0)) == 1, "왕좌 전실→왕좌 돌파와 DAY 5 증원 누수 actor당 1회")
	_expect(int(metrics.get("gold_stolen", 0)) == 100 and int(metrics.get("throne_damage", 0)) == 150, "실제 loot·왕좌 damage event에서 금화 100·왕좌 피해 150 계산")
	_expect(str(metrics.get("movement_path_fingerprint", "")).length() == 64 and int(metrics.get("movement_path_cells", 0)) > 0, "연속 중복 cell 제거 뒤 SHA-256 이동 fingerprint와 cell 수 보존")


func _test_facility_effect_zone_moves() -> void:
	var gate_position := Vector2(610.56, 391.36)
	var spike_position := Vector2(798.72, 485.44)
	for facility_id_value in DataRegistry.v20_facilities.keys():
		var facility_id := str(facility_id_value)
		var gate_state := FacilityService.new_battle_state({"placed": {"facility_id": facility_id, "room_id": "gate_outpost", "slot_id": "gate_outpost_facility"}}, DataRegistry.v20_facilities)
		var spike_state := FacilityService.new_battle_state({"placed": {"facility_id": facility_id, "room_id": "spike_corridor", "slot_id": "spike_corridor_facility"}}, DataRegistry.v20_facilities)
		var gate_effect := FacilityService.effects_for_position(gate_state, gate_position, _board(), DataRegistry.v20_facilities, facility_id)
		var moved_effect := FacilityService.effects_for_position(spike_state, spike_position, _board(), DataRegistry.v20_facilities, facility_id)
		_expect(not gate_effect.is_empty() and FacilityService.effects_for_position(gate_state, spike_position, _board(), DataRegistry.v20_facilities, facility_id).is_empty(), "%s 실제 effect zone은 gate_outpost 설치 bounds" % facility_id)
		_expect(not moved_effect.is_empty() and FacilityService.effects_for_position(spike_state, gate_position, _board(), DataRegistry.v20_facilities, facility_id).is_empty(), "%s 이동 뒤 실제 effect zone도 spike_corridor bounds" % facility_id)


func _test_home_zone_actual_spawn() -> void:
	var gate_case := await _capture_slime_spawn("gate")
	var throne_case := await _capture_slime_spawn("throne")
	_expect(str(gate_case.get("slot_id", "")) == "gate_outpost_monster_1" and str(gate_case.get("home_zone", "")) == "gate_outpost", "gate case slime 실제 home zone·slot 필드 고정")
	_expect(str(throne_case.get("slot_id", "")) == "throne_anteroom_monster_1" and str(throne_case.get("home_zone", "")) == "throne_anteroom", "throne case slime 실제 home zone·slot 필드 고정")
	_expect(Vector2(gate_case.get("position", Vector2.ZERO)).distance_to(Vector2(610.56, 364.48)) <= 1.0 and Vector2(throne_case.get("position", Vector2.ZERO)).distance_to(Vector2(1363.2, 552.64)) <= 1.0, "같은 slime이 선택한 canonical slot의 실제 world coordinate에서 spawn")
	_expect(gate_case.get("path", []) != throne_case.get("path", []), "gate와 throne 배치의 첫 실제 logical movement path가 다름")


func _capture_slime_spawn(case_id: String) -> Dictionary:
	var path := "user://tests/v20_placement_causality_spawn_%s.json" % case_id
	var game_root = await _new_root_to_placement(path)
	var placement: Dictionary = game_root._v20_placement_state()
	if case_id == "throne":
		placement = _apply_monster_move(game_root, placement, "imp", "spike_corridor")
		placement = _apply_monster_move(game_root, placement, "slime", "throne_anteroom")
	game_root._v20_request_defense_start()
	game_root._v20_advance_defense_countdown(3.0)
	var slime = game_root.monster_units.filter(func(unit): return str(unit.unit_id) == "slime")[0]
	await get_tree().physics_frame
	var evidence: Dictionary = game_root.combat_scene.v20_evidence_snapshot()
	var result := {
		"slot_id": str(slime.v20_monster_slot_id),
		"home_zone": str(slime.v20_home_zone),
		"position": slime.global_position,
		"path": evidence.get("movement_paths", {}).get("monster:slime", []).duplicate(true)
	}
	game_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(path)
	return result


func _test_command_applies_to_all_living_monsters() -> void:
	var path := "user://tests/v20_placement_causality_command.json"
	var game_root = await _new_root_to_placement(path)
	game_root._v20_request_defense_start()
	game_root._v20_advance_defense_countdown(3.0)
	await get_tree().physics_frame
	game_root.combat_scene._issue_v20_command_with_target("v20_rally", {"type": "room", "id": "spike_corridor", "label": "가시 회랑"})
	await get_tree().physics_frame
	var evidence: Dictionary = game_root.combat_scene.v20_evidence_snapshot()
	var commands: Array = evidence.get("command_events", [])
	var applied: Array = commands[0].get("applied_actor_ids", []) if not commands.is_empty() else []
	var expected := ["monster:goblin", "monster:imp", "monster:slime"]
	applied.sort()
	_expect(commands.size() == 1 and applied == expected, "집결 1회가 실제 생존 몬스터 slime·goblin·imp 전체 actor ID에 적용")
	game_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(path)


func _test_engineer_disable_actual_effect_gap() -> void:
	var path := "user://tests/v20_placement_causality_engineer.json"
	var game_root = await _new_root_to_placement(path, 3)
	var placement: Dictionary = game_root._v20_placement_state()
	placement = _apply_facility_install(game_root, placement, "v20_recovery_nest", "gate_outpost")
	placement = _apply_monster_move(game_root, placement, "goblin", "gate_outpost")
	game_root._v20_request_defense_start()
	game_root._v20_advance_defense_countdown(3.0)
	var frames := await _advance_to_result(game_root)
	var evidence: Dictionary = game_root.combat_scene.v20_evidence_snapshot()
	var events: Array = evidence.get("events", [])
	var disable_start := -1
	var disable_end := -1
	var disable_start_index := -1
	var disable_end_index := -1
	for event_index in range(events.size()):
		var event: Dictionary = events[event_index]
		if str(event.get("facility_id", "")) != "v20_recovery_nest":
			continue
		if str(event.get("type", "")) == "facility_disable_started":
			disable_start = int(event.get("frame", -1))
			disable_start_index = event_index
		elif str(event.get("type", "")) == "facility_disable_ended":
			disable_end = int(event.get("frame", -1))
			disable_end_index = event_index
	var effects_during := 0
	var effects_after := 0
	for event_index in range(events.size()):
		var event: Dictionary = events[event_index]
		if str(event.get("type", "")) != "facility_effect" or str(event.get("facility_id", "")) != "v20_recovery_nest":
			continue
		if disable_start_index >= 0 and event_index > disable_start_index and (disable_end_index < 0 or event_index < disable_end_index):
			effects_during += 1
		elif disable_end_index >= 0 and event_index > disable_end_index:
			effects_after += 1
	_expect(game_root.current_screen == Constants.SCREEN_RESULT and frames < MAX_NATURAL_FRAMES, "DAY 3 공병 검증 전투가 직접 결과 호출 없이 RESULT 도달")
	_expect(disable_start >= 0 and disable_end > disable_start and disable_end - disable_start >= 60 * 6, "공병이 실제 시설을 무력화하고 약 7초 뒤 복구 event 기록")
	_expect(effects_during == 0, "공병 무력화 start~end 실제 시설 effect event 0건")
	_expect(effects_after > 0, "무력화 종료 뒤 같은 회복 둥지 실제 effect event 복구")
	print("V20_ENGINEER_DISABLE_EVIDENCE: %s" % JSON.stringify({"start_frame": disable_start, "end_frame": disable_end, "effects_during": effects_during, "effects_after": effects_after}))
	game_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(path)


func _test_thief_goal_loot_escape_with_decoy() -> void:
	var no_decoy := await _run_day_two_thief_case(false)
	var with_decoy := await _run_day_two_thief_case(true)
	_expect(no_decoy.get("goals", []).has("central_battle_room") and not with_decoy.get("goals", []).has("central_battle_room"), "미끼 없음은 Z3, gate 미끼 설치는 gate_outpost가 도둑 실제 목표")
	_expect(int(no_decoy.get("gold_stolen", 0)) != int(with_decoy.get("gold_stolen", 0)) or int(no_decoy.get("loot_frame", -1)) != int(with_decoy.get("loot_frame", -1)), "미끼 유무가 실제 loot 발생 여부 또는 physics frame을 변경")
	_expect(int(no_decoy.get("escape_events", 0)) != int(with_decoy.get("escape_events", 0)) or int(no_decoy.get("escape_frame", -1)) != int(with_decoy.get("escape_frame", -1)) or no_decoy.get("path", []) != with_decoy.get("path", []), "미끼 유무가 실제 도주 event 또는 돌아가는 이동 경로를 변경")
	_expect(int(with_decoy.get("gold_stolen", 0)) == 100 and int(with_decoy.get("escape_events", 0)) == 1, "방어자가 없는 gate 미끼에서 도둑은 실제 100 약탈 뒤 gate_outpost로 도주")
	print("V20_THIEF_DECOY_EVIDENCE: %s" % JSON.stringify({"no_decoy": no_decoy, "with_decoy": with_decoy}))


func _run_day_two_thief_case(with_decoy: bool) -> Dictionary:
	var case_id := "with_decoy" if with_decoy else "no_decoy"
	var path := "user://tests/v20_placement_causality_thief_%s.json" % case_id
	var game_root = await _new_root_to_placement(path, 2)
	var placement: Dictionary = game_root._v20_placement_state()
	placement = _apply_monster_move(game_root, placement, "imp", "spike_corridor")
	placement = _apply_monster_move(game_root, placement, "slime", "throne_anteroom")
	placement = _apply_monster_move(game_root, placement, "goblin", "throne_anteroom")
	placement = _apply_monster_move(game_root, placement, "imp", "central_battle_room")
	if with_decoy:
		placement = _apply_facility_install(game_root, placement, "v20_decoy_treasure", "gate_outpost")
	game_root._v20_request_defense_start()
	game_root._v20_advance_defense_countdown(3.0)
	var frames := await _advance_to_result(game_root)
	var evidence: Dictionary = game_root.combat_scene.v20_evidence_snapshot()
	var events: Array = evidence.get("events", [])
	var thief_actor_id := ""
	var loot_frame := -1
	var escape_frame := -1
	for event_value in events:
		var event: Dictionary = event_value
		if str(event.get("unit_id", "")) == "thief" and str(event.get("type", "")) == "spawn":
			thief_actor_id = str(event.get("actor_id", ""))
		if thief_actor_id != "" and str(event.get("actor_id", "")) == thief_actor_id:
			if str(event.get("type", "")) == "loot":
				loot_frame = int(event.get("frame", -1))
			elif str(event.get("type", "")) == "escape":
				escape_frame = int(event.get("frame", -1))
	var goals: Array[String] = []
	for history_value in evidence.get("target_history", []):
		var history: Array = history_value
		if history.size() >= 4 and str(history[1]) == thief_actor_id and str(history[3]) != "" and not goals.has(str(history[3])):
			goals.append(str(history[3]))
	var result := {
		"completed": game_root.current_screen == Constants.SCREEN_RESULT and frames < MAX_NATURAL_FRAMES,
		"goals": goals,
		"gold_stolen": int(evidence.get("gold_stolen", 0)),
		"loot_frame": loot_frame,
		"escape_events": evidence.get("escaped_actor_ids", []).size(),
		"escape_frame": escape_frame,
		"path": evidence.get("movement_paths", {}).get(thief_actor_id, []).duplicate(true)
	}
	_expect(bool(result.get("completed", false)), "DAY 2 %s 도둑 검증 전투가 자연 RESULT 도달" % case_id)
	game_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(path)
	return result


func _test_day_one_a_d_natural_combat() -> void:
	var run_a := await _run_day_one_case("A")
	var run_d := await _run_day_one_case("D")
	_expect(bool(run_a.get("completed", false)) and bool(run_d.get("completed", false)), "DAY 1 seed 2001 A/D가 직접 결과 호출 없이 7200 physics frame 안에 RESULT 도달")
	_expect(int(run_a.get("combat_speed", 0)) == 1 and int(run_d.get("combat_speed", 0)) == 1, "A/D 모두 x1 전투 속도 유지")
	_expect(str(run_a.get("slime_slot", "")) == "gate_outpost_monster_1" and str(run_d.get("slime_slot", "")) == "spike_corridor_monster_2", "D는 A의 slime monster_slot만 gate 1→spike 2로 변경")
	_expect(run_a.get("unchanged", {}) == run_d.get("unchanged", {}), "A/D 시설·imp·goblin·난이도·seed·명령 event 동일")
	var metrics_a: Dictionary = run_a.get("metrics", {})
	var metrics_d: Dictionary = run_d.get("metrics", {})
	var causal := BattleEvidence.causal_difference(metrics_a, metrics_d)
	_expect(bool(causal.get("structural", false)), "A/D 첫 교전 구역·목표·실제 이동 fingerprint 중 하나가 다름: %s" % [causal])
	_expect(bool(causal.get("consequential", false)), "A/D 유지 시간·왕좌·도난·무력화·압박·돌파·실제 피해/잔여 HP threshold 중 하나가 다름: %s" % [causal])
	_expect(bool(causal.get("pass", false)), "DAY 1 A/D가 계약 7.5 두 조건 동시 충족")
	_expect(int(metrics_a.get("facility_effect_events", 0)) > 0 and int(metrics_a.get("monster_damage_total", 0)) > 0, "A 자연 전투의 시설 effect event와 몬스터 실제 피해가 모두 0보다 큼")
	_expect(metrics_a.get("command_events", []).is_empty() and metrics_d.get("command_events", []).is_empty(), "A/D 자연 전투에서 명령·결과 덮어쓰기 없이 배치만 비교")
	print("V20_PLACEMENT_CAUSALITY_A_D: %s" % JSON.stringify({"A": _metric_digest(metrics_a), "D": _metric_digest(metrics_d), "causal": causal}))


func _run_day_one_case(case_id: String) -> Dictionary:
	var path := "user://tests/v20_placement_causality_day1_%s.json" % case_id.to_lower()
	var game_root = await _new_root_to_placement(path)
	var placement: Dictionary = game_root._v20_placement_state()
	placement = _apply_facility_install(game_root, placement, "v20_barricade", "gate_outpost")
	placement = _apply_monster_move(game_root, placement, "imp", "spike_corridor")
	if case_id == "D":
		placement = _apply_monster_move(game_root, placement, "slime", "spike_corridor")
	var roster: Dictionary = placement.get("roster", {})
	var unchanged := {
		"facility": str(placement.get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")),
		"imp_slot": str(roster.get("imp", {}).get("monster_slot_id", "")),
		"goblin_slot": str(roster.get("goblin", {}).get("monster_slot_id", "")),
		"difficulty": str(game_root.v20_session.get("difficulty_id", "")),
		"seed": int(game_root.v20_session.get("encounter_seed", 0))
	}
	var slime_slot := str(roster.get("slime", {}).get("monster_slot_id", ""))
	game_root._v20_request_defense_start()
	game_root._v20_advance_defense_countdown(3.0)
	var frames := 0
	while game_root.current_screen == Constants.SCREEN_COMBAT and frames < MAX_NATURAL_FRAMES:
		await get_tree().physics_frame
		frames += 1
	var completed: bool = game_root.current_screen == Constants.SCREEN_RESULT
	var summary: Dictionary = game_root.result_summary.duplicate(true)
	var result := {
		"completed": completed,
		"frames": frames,
		"combat_speed": game_root.combat_speed,
		"slime_slot": slime_slot,
		"unchanged": unchanged,
		"metrics": summary.get("metrics", {}).get("v20_evidence", {}).duplicate(true)
	}
	game_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(path)
	return result


func _test_day_one_to_five_candidate_runs() -> void:
	var fixture := _load_candidate_fixture()
	_expect(int(fixture.get("schema_version", 0)) == 1, "DAY 1~5 후보 fixture schema 1 로드")
	_expect(str(fixture.get("difficulty_id", "")) == "v20_tactician" and int(fixture.get("combat_speed", 0)) == 1 and int(fixture.get("physics_fps", 0)) == 60, "후보 run은 보통·x1·60 Hz로 고정")
	var all_runs: Dictionary = {}
	var selected_day := _candidate_selected_day()
	var days: Array = [selected_day] if selected_day in [1, 2, 3, 4, 5] else [1, 2, 3, 4, 5]
	for day in days:
		var day_fixture: Dictionary = fixture.get("days", {}).get(str(day), {})
		var seed := int(fixture.get("seed_schedule", {}).get(str(day), 0))
		_expect(seed == 2000 + day, "DAY %d 첫 protocol seed가 %d" % [day, 2000 + day])
		_expect(_a_d_fixture_diff_is_one_slot(day_fixture), "DAY %d A/D fixture는 계약에 적힌 monster slot 한 건만 다름" % day)
		var day_runs: Dictionary = {}
		var selected_scenario := _candidate_selected_scenario()
		var scenario_ids: Array = [selected_scenario] if selected_scenario in ["A", "B", "C", "D"] else ["A", "B", "C", "D"]
		for scenario_id in scenario_ids:
			var scenario: Dictionary = day_fixture.get("scenarios", {}).get(scenario_id, {})
			var run := await _run_candidate_case(day, scenario_id, seed, scenario)
			day_runs[scenario_id] = run
			print("V20_BALANCE_CANDIDATE_RUN: %s" % JSON.stringify(_candidate_digest(run)))
		all_runs[day] = day_runs
		if scenario_ids.size() == 4:
			_assert_day_candidate_gate(day, day_fixture, day_runs)
	_expect(all_runs.size() == days.size(), "선택 DAY·scenario 후보 실제 물리 전투 실행")


func _candidate_selected_day() -> int:
	for arg_value in OS.get_cmdline_user_args():
		var arg := str(arg_value)
		if arg.begins_with("--candidate-day="):
			return int(arg.trim_prefix("--candidate-day="))
	return 0


func _candidate_selected_scenario() -> String:
	for arg_value in OS.get_cmdline_user_args():
		var arg := str(arg_value)
		if arg.begins_with("--candidate-scenario="):
			return arg.trim_prefix("--candidate-scenario=").to_upper()
	return ""


func _load_candidate_fixture() -> Dictionary:
	var file := FileAccess.open(CANDIDATE_FIXTURE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _a_d_fixture_diff_is_one_slot(day_fixture: Dictionary) -> bool:
	var scenarios: Dictionary = day_fixture.get("scenarios", {})
	var a: Dictionary = scenarios.get("A", {})
	var d: Dictionary = scenarios.get("D", {})
	if a.get("facilities", []) != d.get("facilities", []) or a.get("command_events", []) != d.get("command_events", []):
		return false
	var a_slots := _monster_slot_map(a)
	var d_slots := _monster_slot_map(d)
	if a_slots.keys().size() != 3 or a_slots.keys() != d_slots.keys():
		return false
	var changed: Array[String] = []
	for monster_id_value in a_slots.keys():
		var monster_id := str(monster_id_value)
		if str(a_slots.get(monster_id, "")) != str(d_slots.get(monster_id, "")):
			changed.append(monster_id)
	var declared: Dictionary = day_fixture.get("d_slot_change", {})
	if changed.size() != 1:
		return false
	return changed == [str(declared.get("monster_id", ""))] and str(a_slots.get(changed[0], "")) == str(declared.get("from", "")) and str(d_slots.get(changed[0], "")) == str(declared.get("to", ""))


func _monster_slot_map(scenario: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for row_value in scenario.get("monsters", []):
		var row: Dictionary = row_value
		result[str(row.get("monster_id", ""))] = str(row.get("slot_id", ""))
	return result


func _run_candidate_case(day: int, scenario_id: String, seed: int, scenario: Dictionary) -> Dictionary:
	var path := "user://tests/v20_balance_candidate_d%d_%s.json" % [day, scenario_id.to_lower()]
	var game_root = await _new_candidate_root(path, day, seed, scenario_id)
	var placement_ok := _apply_candidate_placement(game_root, scenario)
	_expect(placement_ok, "DAY %d %s fixture를 실제 placement API로 입력" % [day, scenario_id])
	var requested: bool = game_root._v20_request_defense_start()
	_expect(requested, "DAY %d %s 유효 배치로 DEFENSE_START 진입" % [day, scenario_id])
	game_root._v20_advance_defense_countdown(3.0)
	var pending_commands: Array = scenario.get("command_events", []).duplicate(true)
	var command_observations: Array[Dictionary] = []
	var frames := 0
	while game_root.current_screen == Constants.SCREEN_COMBAT and frames < MAX_NATURAL_FRAMES:
		await get_tree().physics_frame
		frames += 1
		_try_issue_candidate_commands(game_root, pending_commands, command_observations, frames)
	var completed: bool = game_root.current_screen == Constants.SCREEN_RESULT
	var summary: Dictionary = game_root.result_summary.duplicate(true)
	var metrics: Dictionary = summary.get("metrics", {}).get("v20_evidence", {}).duplicate(true)
	var result := {
		"day": day,
		"scenario_id": scenario_id,
		"seed": seed,
		"completed": completed,
		"win": bool(summary.get("win", false)),
		"frames": frames,
		"combat_seconds": float(game_root.combat_time),
		"combat_speed": int(game_root.combat_speed),
		"spawned_count": int(game_root.spawned_count),
		"scheduled_count": int(game_root.wave_manager.total_to_spawn),
		"wave_seed": int(game_root.wave_manager.v20_seed),
		"wave_rng_state": int(game_root.wave_manager.v20_rng_state),
		"pending_command_count": pending_commands.size(),
		"command_observations": command_observations,
		"required_objective_failure": str(summary.get("v20_required_objective_failure", "")),
		"live_enemies": game_root.enemy_units.filter(func(unit): return is_instance_valid(unit) and unit.is_alive()).map(func(unit): return {"unit_id": str(unit.unit_id), "hp": int(unit.hp), "zone": _candidate_actor_zone(game_root, unit), "targetable": bool(unit.get_meta("v20_targetable", true))}),
		"live_monsters": game_root.monster_units.filter(func(unit): return is_instance_valid(unit) and unit.is_alive()).map(func(unit): return {"unit_id": str(unit.unit_id), "hp": int(unit.hp), "zone": _candidate_actor_zone(game_root, unit)}),
		"fixture": scenario.duplicate(true),
		"metrics": metrics
	}
	game_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(path)
	return result


func _new_candidate_root(path: String, day: int, seed: int, scenario_id: String):
	SaveStore.delete(path)
	var game_root = GameRootScene.instantiate()
	game_root._v20_set_save_path_for_tests(path)
	add_child(game_root)
	await get_tree().process_frame
	await get_tree().process_frame
	var acceptance: Dictionary = game_root.begin_acceptance_case(day, seed, scenario_id)
	_expect(bool(acceptance.get("ok", false)), "DAY %d %s acceptance case seed %d 승인" % [day, scenario_id, seed])
	game_root._v20_start_new_session("v20_tactician")
	await get_tree().process_frame
	_expect(game_root._v20_start_placement(), "DAY %d %s INTRUSION_BRIEF→PLACEMENT 정상 전이" % [day, scenario_id])
	return game_root


func _apply_candidate_placement(game_root, scenario: Dictionary) -> bool:
	var placement: Dictionary = game_root._v20_placement_state()
	for zone_id_value in placement.get("rooms", {}).keys():
		var zone_id := str(zone_id_value)
		if str(placement.get("rooms", {}).get(zone_id, {}).get("facility_id", "")) == "":
			continue
		var removed := PlacementService.remove_facility(placement, zone_id, DataRegistry.v20_facilities)
		if not bool(removed.get("ok", false)):
			return false
		placement = removed.get("state", placement)
		game_root._v20_update_placement_state(placement, removed)
	var staging := {"slime": "gate_outpost", "goblin": "central_battle_room", "imp": "throne_anteroom"}
	for monster_id_value in staging.keys():
		var staged := PlacementService.place_monster_drag(placement, str(monster_id_value), str(staging.get(monster_id_value, "")))
		if not bool(staged.get("ok", false)):
			return false
		placement = staged.get("state", placement)
		game_root._v20_update_placement_state(placement, staged)
	var monster_rows: Array = scenario.get("monsters", []).duplicate(true)
	monster_rows.sort_custom(func(a, b): return str(a.get("slot_id", "")) < str(b.get("slot_id", "")))
	for row_value in monster_rows:
		var row: Dictionary = row_value
		var slot_id := str(row.get("slot_id", ""))
		var moved := PlacementService.place_monster_drag(placement, str(row.get("monster_id", "")), _zone_from_monster_slot(slot_id))
		if not bool(moved.get("ok", false)):
			return false
		placement = moved.get("state", placement)
		game_root._v20_update_placement_state(placement, moved)
	for row_value in scenario.get("facilities", []):
		var row: Dictionary = row_value
		var installed := PlacementService.place_facility_drag(placement, str(row.get("facility_id", "")), _zone_from_facility_slot(str(row.get("slot_id", ""))), DataRegistry.v20_facilities)
		if not bool(installed.get("ok", false)):
			return false
		placement = installed.get("state", placement)
		game_root._v20_update_placement_state(placement, installed)
	var actual_slots := _monster_slot_map({"monsters": placement.get("roster", {}).keys().map(func(monster_id): return {"monster_id": str(monster_id), "slot_id": str(placement.get("roster", {}).get(monster_id, {}).get("monster_slot_id", ""))})})
	return actual_slots == _monster_slot_map(scenario) and _facility_fixture_matches(placement, scenario)


func _facility_fixture_matches(placement: Dictionary, scenario: Dictionary) -> bool:
	var expected: Dictionary = {}
	for row_value in scenario.get("facilities", []):
		var row: Dictionary = row_value
		expected[_zone_from_facility_slot(str(row.get("slot_id", "")))] = str(row.get("facility_id", ""))
	for zone_id_value in placement.get("rooms", {}).keys():
		var zone_id := str(zone_id_value)
		if str(placement.get("rooms", {}).get(zone_id, {}).get("facility_id", "")) != str(expected.get(zone_id, "")):
			return false
	return true


func _zone_from_facility_slot(slot_id: String) -> String:
	return slot_id.trim_suffix("_facility")


func _zone_from_monster_slot(slot_id: String) -> String:
	return slot_id.trim_suffix("_monster_1").trim_suffix("_monster_2")


func _try_issue_candidate_commands(game_root, pending: Array, observations: Array[Dictionary], frame: int) -> void:
	for index in range(pending.size() - 1, -1, -1):
		var row: Dictionary = pending[index]
		var trigger := _candidate_trigger(game_root, str(row.get("trigger", "")))
		if not bool(trigger.get("ready", false)):
			continue
		var target := _candidate_command_target(game_root, row)
		var before: int = game_root.combat_scene.v20_battle_evidence.get("command_events", []).size()
		game_root.combat_scene._issue_v20_command_with_target(str(row.get("command_id", "")), target)
		var after: int = game_root.combat_scene.v20_battle_evidence.get("command_events", []).size()
		observations.append({
			"command_id": str(row.get("command_id", "")),
			"trigger": str(row.get("trigger", "")),
			"trigger_frame": int(trigger.get("frame", frame)),
			"issue_frame": frame,
			"input_delay_seconds": float(frame - int(trigger.get("frame", frame))) / 60.0,
			"target": target.duplicate(true),
			"issued": after == before + 1
		})
		pending.remove_at(index)


func _candidate_trigger(game_root, trigger_id: String) -> Dictionary:
	match trigger_id:
		"engineer_spawn":
			return _enemy_trigger(game_root, "engineer", "")
		"archer_spawn":
			return _enemy_trigger(game_root, "anti_magic_archer", "")
		"archer_enters_spike":
			return _enemy_trigger(game_root, "anti_magic_archer", "spike_corridor")
		"archer_enters_watch_radius":
			return _enemy_enters_watch_radius_trigger(game_root)
		"hero_dash_telegraph":
			for event_value in game_root.combat_scene.v20_battle_evidence.get("events", []):
				var event: Dictionary = event_value
				if str(event.get("type", "")) == "hero_dash_telegraph":
					return {"ready": true, "frame": int(event.get("frame", 0))}
		"living_monsters_arrive_throne_anteroom":
			var living: Array = game_root.monster_units.filter(func(unit): return is_instance_valid(unit) and unit.is_alive())
			if not living.is_empty() and living.any(func(unit): return V20FacilityService.position_in_zone(_board(), "throne_anteroom", unit.global_position) and int(unit.hp) < int(unit.max_hp)):
				return {"ready": true, "frame": int(game_root.combat_scene.v20_evidence_frame)}
		"hero_damages_monster_in_throne_anteroom":
			for event_value in game_root.combat_scene.v20_battle_evidence.get("events", []):
				var event: Dictionary = event_value
				var world: Array = event.get("world_position", [])
				var inside_anteroom := world.size() == 2 and V20FacilityService.position_in_zone(_board(), "throne_anteroom", Vector2(float(world[0]), float(world[1])))
				if str(event.get("type", "")) == "damage" and str(event.get("actor_id", "")).begins_with("enemy:trainee_hero") and str(event.get("target_id", "")).begins_with("monster:") and inside_anteroom:
					return {"ready": true, "frame": int(event.get("frame", 0))}
	return {"ready": false}


func _enemy_enters_watch_radius_trigger(game_root) -> Dictionary:
	for enemy in game_root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or str(enemy.unit_id) != "anti_magic_archer":
			continue
		for placement_id_value in game_root.combat_scene.v20_facility_state.get("facilities", {}).keys():
			var placement_id := str(placement_id_value)
			var runtime: Dictionary = game_root.combat_scene.v20_facility_state.get("facilities", {}).get(placement_id, {})
			if str(runtime.get("facility_id", "")) != "v20_watch_post":
				continue
			var definition: Dictionary = DataRegistry.v20_facilities.get("v20_watch_post", {})
			var reveal_radius := float(definition.get("activation", {}).get("effect", {}).get("reveal_radius", 0.0))
			var facility_position := V20FacilityService.facility_world_position(runtime, _board())
			if reveal_radius > 0.0 and facility_position.distance_to(enemy.global_position) <= reveal_radius:
				return {"ready": true, "frame": int(game_root.combat_scene.v20_evidence_frame), "enemy": enemy}
	return {"ready": false}


func _enemy_trigger(game_root, enemy_id: String, zone_id: String) -> Dictionary:
	for enemy in game_root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or str(enemy.unit_id) != enemy_id:
			continue
		if zone_id != "" and not V20FacilityService.position_in_zone(_board(), zone_id, enemy.global_position):
			continue
		var actor_id := str(enemy.get_meta("v20_actor_id", ""))
		var trigger_frame := int(game_root.combat_scene.v20_evidence_frame)
		for event_value in game_root.combat_scene.v20_battle_evidence.get("events", []):
			var event: Dictionary = event_value
			if str(event.get("actor_id", "")) != actor_id:
				continue
			if zone_id == "" and str(event.get("type", "")) == "spawn":
				trigger_frame = int(event.get("frame", trigger_frame))
				break
			if zone_id != "":
				break
		return {"ready": true, "frame": trigger_frame, "enemy": enemy}
	return {"ready": false}


func _candidate_command_target(game_root, row: Dictionary) -> Dictionary:
	var command_id := str(row.get("command_id", ""))
	var target_id := str(row.get("target", ""))
	if command_id == "v20_focus":
		for enemy in game_root.enemy_units:
			if is_instance_valid(enemy) and enemy.is_alive() and str(enemy.unit_id) == target_id:
				return {"type": "enemy", "id": str(enemy.get_instance_id()), "room_id": str(enemy.current_room), "label": str(enemy.display_name)}
	elif command_id == "v20_activate_facility":
		var zone_id := _zone_from_facility_slot(target_id)
		return {"type": "facility", "id": zone_id, "room_id": zone_id, "label": target_id}
	elif command_id in ["v20_rally", "v20_emergency_fallback"]:
		return {"type": "room", "id": target_id, "label": target_id}
	return {"type": "", "id": ""}


func _candidate_actor_zone(game_root, actor: Node) -> String:
	var zone_id := BattleEvidence.zone_for_position(_board(), actor.global_position)
	return zone_id if zone_id != "" else str(actor.current_room)


func _assert_day_candidate_gate(day: int, day_fixture: Dictionary, runs: Dictionary) -> void:
	for scenario_id in ["A", "B"]:
		var run: Dictionary = runs.get(scenario_id, {})
		var scenario: Dictionary = day_fixture.get("scenarios", {}).get(scenario_id, {})
		_expect(_candidate_primary_success(run) == bool(scenario.get("primary_success", false)), "DAY %d %s 실제 자연 전투 primary_success" % [day, scenario_id])
		_expect(_candidate_secondary_success(day, run) == bool(scenario.get("secondary_success", false)), "DAY %d %s 실제 ledger secondary_success" % [day, scenario_id])
		var mechanisms := _candidate_mechanism_results(run, scenario.get("mechanism_assertions", []))
		_expect(mechanisms.values().all(func(value): return bool(value)), "DAY %d %s 실제 mechanism 전부 발생: %s" % [day, scenario_id, mechanisms])
		var duration_range: Array = day_fixture.get("duration_range_seconds", [])
		_expect(duration_range.size() == 2 and float(run.get("combat_seconds", 0.0)) >= float(duration_range[0]) and float(run.get("combat_seconds", 0.0)) <= float(duration_range[1]), "DAY %d %s 전투 시간 %.2f초가 %.0f~%.0f초 범위" % [day, scenario_id, float(run.get("combat_seconds", 0.0)), float(duration_range[0]), float(duration_range[1])])
		_expect(int(run.get("combat_speed", 0)) == 1 and int(run.get("wave_seed", 0)) == 2000 + day and int(run.get("pending_command_count", -1)) == 0, "DAY %d %s x1·WaveManager seed·조건부 명령 전달" % [day, scenario_id])
	var c: Dictionary = runs.get("C", {})
	var c_fixture: Dictionary = day_fixture.get("scenarios", {}).get("C", {})
	_expect(_candidate_primary_success(c) == bool(c_fixture.get("primary_success", true)), "DAY %d C 실제 전투 primary_success=false" % day)
	var penalties := _candidate_penalty_results(day, runs.get("A", {}), c, c_fixture.get("penalty_assertions", []))
	_expect(penalties.values().all(func(value): return bool(value)), "DAY %d C 실제 불이익 전부 발생: %s" % [day, penalties])
	var causal := BattleEvidence.causal_difference(runs.get("A", {}).get("metrics", {}), runs.get("D", {}).get("metrics", {}))
	_expect(bool(causal.get("structural", false)) and bool(causal.get("consequential", false)), "DAY %d A/D 계약 7.5 구조·결과 threshold 동시 충족: %s" % [day, causal])


func _candidate_primary_success(run: Dictionary) -> bool:
	return bool(run.get("completed", false)) and bool(run.get("win", false)) and int(run.get("frames", MAX_NATURAL_FRAMES)) < MAX_NATURAL_FRAMES and int(run.get("spawned_count", -1)) == int(run.get("scheduled_count", -2))


func _candidate_secondary_success(day: int, run: Dictionary) -> bool:
	var metrics: Dictionary = run.get("metrics", {})
	match day:
		1:
			return int(metrics.get("throne_damage", 0)) == 0
		2:
			return int(metrics.get("gold_stolen", 0)) == 0
		3:
			var disable_count := _events(metrics, "facility_disable_started").size()
			return int(metrics.get("throne_damage", 0)) == 0 and run.get("fixture", {}).get("facilities", []).size() >= 1 and float(metrics.get("max_contiguous_facility_disabled_seconds", 0.0)) <= 7.5 and (disable_count == 0 or _other_facility_effect_during_disable(metrics))
		4:
			return float(metrics.get("rear_pressure_seconds", 0.0)) < 6.0 and _actor_terminal_defeated(run, "anti_magic_archer")
		5:
			return int(metrics.get("fallback_breaches", 0)) == 0 and int(metrics.get("second_phase_leaks", 0)) == 0 and int(metrics.get("gold_stolen", 0)) == 0
	return false


func _candidate_mechanism_results(run: Dictionary, rule_ids: Array) -> Dictionary:
	var result: Dictionary = {}
	var metrics: Dictionary = run.get("metrics", {})
	for rule_id_value in rule_ids:
		var rule_id := str(rule_id_value)
		match rule_id:
			"first_gate": result[rule_id] = str(metrics.get("first_engagement_zone", "")) == "gate_outpost"
			"first_spike": result[rule_id] = str(metrics.get("first_engagement_zone", "")) == "spike_corridor"
			"barricade_slow": result[rule_id] = _facility_effect_amount(metrics, "v20_barricade", "slow") > 0.0
			"imp_damage": result[rule_id] = _damage_amount(metrics, "monster:imp", "enemy:", "") > 0
			"barracks_contribution": result[rule_id] = _facility_effect_amount(metrics, "v20_barracks", "bonus_damage") > 0.0 or _facility_effect_amount(metrics, "v20_barracks", "damage_reduced") > 0.0
			"thief_goal_central": result[rule_id] = _actor_goal_seen(metrics, "enemy:thief", "central_battle_room")
			"decoy_lure": result[rule_id] = _facility_effect_on_actor(metrics, "v20_decoy_treasure", "enemy:thief")
			"goblin_damage_thief": result[rule_id] = _damage_amount(metrics, "monster:goblin", "enemy:thief", "") > 0
			"decoy_absent": result[rule_id] = not run.get("fixture", {}).get("facilities", []).any(func(row): return str(row.get("facility_id", "")) == "v20_decoy_treasure")
			"spike_damage_explorer": result[rule_id] = _damage_amount(metrics, "monster:slime", "enemy:explorer", "spike_corridor") + _damage_amount(metrics, "monster:imp", "enemy:explorer", "spike_corridor") > 0
			"central_goblin_damage_thief": result[rule_id] = _damage_amount(metrics, "monster:goblin", "enemy:thief", "central_battle_room") > 0
			"focus_engineer_in_1s": result[rule_id] = _command_observation_pass(run, "v20_focus", "engineer_spawn", 1.0)
			"engineer_disable_at_most_2": result[rule_id] = float(metrics.get("max_contiguous_facility_disabled_seconds", 0.0)) <= 2.0
			"engineer_disable_interrupted_or_absent": result[rule_id] = _events(metrics, "facility_disable_started").is_empty()
			"engineer_disable_6_5_to_7_5": result[rule_id] = float(metrics.get("max_contiguous_facility_disabled_seconds", 0.0)) >= 6.5 and float(metrics.get("max_contiguous_facility_disabled_seconds", 0.0)) <= 7.5
			"other_facility_effect_during_disable": result[rule_id] = _other_facility_effect_during_disable(metrics)
			"watch_reveal_archer": result[rule_id] = float(metrics.get("protection_bypass_seconds", 0.0)) > 0.0 and _command_observation_pass(run, "v20_activate_facility", "archer_enters_watch_radius", 1.0)
			"imp_damage_archer_during_reveal": result[rule_id] = _damage_during_reveal(metrics, "monster:imp", "enemy:anti_magic_archer") > 0
			"focus_archer_in_1s": result[rule_id] = _command_observation_pass(run, "v20_focus", "archer_spawn", 1.0)
			"protection_bypass": result[rule_id] = float(metrics.get("protection_bypass_seconds", 0.0)) > 0.0
			"archer_defeated_before_shieldbearer": result[rule_id] = _last_damage_frame(metrics, "enemy:anti_magic_archer") < _first_terminal_damage_frame(metrics, "enemy:shieldbearer")
			"fallback_in_1s_to_throne_anteroom": result[rule_id] = _command_observation_pass(run, "v20_emergency_fallback", "hero_dash_telegraph", 1.0) and _command_target_is(run, "v20_emergency_fallback", "throne_anteroom")
			"recovery_healing": result[rule_id] = _facility_heal_amount(metrics, "v20_recovery_nest") > 0 and _command_issued(run, "v20_activate_facility")
			"no_commands": result[rule_id] = metrics.get("command_events", []).is_empty()
			"hero_defeated_spike": result[rule_id] = _last_damage_zone(metrics, "enemy:trainee_hero") == "spike_corridor"
			"reinforcement_explorer_first_spike": result[rule_id] = _reinforcement_first_zone(metrics, "explorer") == "spike_corridor"
			"reinforcement_thief_first_central": result[rule_id] = _reinforcement_first_zone(metrics, "thief") == "central_battle_room"
			_: result[rule_id] = false
	return result


func _candidate_penalty_results(day: int, a: Dictionary, c: Dictionary, rule_ids: Array) -> Dictionary:
	var result: Dictionary = {}
	var a_metrics: Dictionary = a.get("metrics", {})
	var c_metrics: Dictionary = c.get("metrics", {})
	for rule_id_value in rule_ids:
		var rule_id := str(rule_id_value)
		match rule_id:
			"first_central": result[rule_id] = str(c_metrics.get("first_engagement_zone", "")) == "central_battle_room"
			"throne_hp_10pct_or_duration_plus_2": result[rule_id] = int(c_metrics.get("throne_damage", 0)) - int(a_metrics.get("throne_damage", 0)) >= 150 or float(c.get("combat_seconds", 0.0)) - float(a.get("combat_seconds", 0.0)) >= 2.0
			"gold_stolen": result[rule_id] = int(c_metrics.get("gold_stolen", 0)) >= 1
			"engineer_disable_at_least_2": result[rule_id] = float(c_metrics.get("max_contiguous_facility_disabled_seconds", 0.0)) >= 2.0
			"sole_facility_objective_failed": result[rule_id] = str(c.get("required_objective_failure", "")) == "keep_one_facility_active"
			"throne_hp_10pct_worse": result[rule_id] = int(c_metrics.get("throne_damage", 0)) - int(a_metrics.get("throne_damage", 0)) >= 150
			"rear_pressure_at_least_2_or_monster_hp_10pct_worse": result[rule_id] = float(c_metrics.get("rear_pressure_seconds", 0.0)) >= 2.0 or int(a_metrics.get("monster_end_hp", 0)) - int(c_metrics.get("monster_end_hp", 0)) >= int(ceil(float(c_metrics.get("monster_start_max_hp", 1)) * 0.10))
			"fallback_breach_or_second_phase_leak": result[rule_id] = int(c_metrics.get("fallback_breaches", 0)) >= 1 or int(c_metrics.get("second_phase_leaks", 0)) >= 1
			"fallback_breach_or_second_phase_leak_or_gold_stolen": result[rule_id] = int(c_metrics.get("fallback_breaches", 0)) >= 1 or int(c_metrics.get("second_phase_leaks", 0)) >= 1 or int(c_metrics.get("gold_stolen", 0)) >= 1
			_: result[rule_id] = false
	return result


func _events(metrics: Dictionary, event_type: String) -> Array:
	return metrics.get("event_ledger", []).filter(func(event): return str(event.get("type", "")) == event_type)


func _facility_effect_amount(metrics: Dictionary, facility_id: String, effect_id: String) -> float:
	var total := 0.0
	for event_value in _events(metrics, "facility_effect"):
		var event: Dictionary = event_value
		if str(event.get("facility_id", "")) == facility_id and (effect_id == "" or str(event.get("effect_id", "")) == effect_id):
			total += maxf(0.0, float(event.get("amount", 0.0)))
	return total


func _facility_effect_on_actor(metrics: Dictionary, facility_id: String, actor_prefix: String) -> bool:
	return _events(metrics, "facility_effect").any(func(event): return str(event.get("facility_id", "")) == facility_id and str(event.get("actor_id", "")).begins_with(actor_prefix))


func _facility_heal_amount(metrics: Dictionary, facility_id: String) -> int:
	var total := 0
	for event_value in _events(metrics, "heal"):
		var event: Dictionary = event_value
		if str(event.get("facility_id", "")) == facility_id:
			total += int(event.get("amount", 0))
	return total


func _damage_amount(metrics: Dictionary, actor_prefix: String, target_prefix: String, zone_id: String) -> int:
	var total := 0
	for event_value in _events(metrics, "damage"):
		var event: Dictionary = event_value
		if str(event.get("actor_id", "")).begins_with(actor_prefix) and str(event.get("target_id", "")).begins_with(target_prefix) and (zone_id == "" or str(event.get("zone_id", "")) == zone_id):
			total += int(event.get("amount", 0))
	return total


func _actor_goal_seen(metrics: Dictionary, actor_prefix: String, goal_zone: String) -> bool:
	return metrics.get("target_history", []).any(func(row): return row.size() >= 4 and str(row[1]).begins_with(actor_prefix) and str(row[3]) == goal_zone)


func _command_observation_pass(run: Dictionary, command_id: String, trigger_id: String, max_delay: float) -> bool:
	return run.get("command_observations", []).any(func(row): return str(row.get("command_id", "")) == command_id and str(row.get("trigger", "")) == trigger_id and bool(row.get("issued", false)) and float(row.get("input_delay_seconds", 999.0)) <= max_delay)


func _command_issued(run: Dictionary, command_id: String) -> bool:
	return run.get("command_observations", []).any(func(row): return str(row.get("command_id", "")) == command_id and bool(row.get("issued", false)))


func _command_target_is(run: Dictionary, command_id: String, target_id: String) -> bool:
	return run.get("command_observations", []).any(func(row): return str(row.get("command_id", "")) == command_id and str(row.get("target", {}).get("id", "")) == target_id)


func _other_facility_effect_during_disable(metrics: Dictionary) -> bool:
	var starts: Dictionary = {}
	for event_value in metrics.get("event_ledger", []):
		var event: Dictionary = event_value
		var event_type := str(event.get("type", ""))
		var placement_id := str(event.get("placement_id", ""))
		if event_type == "facility_disable_started":
			starts[placement_id] = int(event.get("frame", 0))
		elif event_type == "facility_disable_ended" and starts.has(placement_id):
			var start_frame := int(starts.get(placement_id, 0))
			var end_frame := int(event.get("frame", 0))
			if _events(metrics, "facility_effect").any(func(effect): return str(effect.get("placement_id", "")) != placement_id and int(effect.get("frame", -1)) > start_frame and int(effect.get("frame", -1)) < end_frame):
				return true
	return false


func _damage_during_reveal(metrics: Dictionary, actor_prefix: String, target_prefix: String) -> int:
	var windows: Array[Vector2i] = []
	for event_value in _events(metrics, "shield_break"):
		var event: Dictionary = event_value
		if str(event.get("actor_id", "")).begins_with(target_prefix):
			windows.append(Vector2i(int(event.get("frame", 0)), int(event.get("frame", 0)) + 360))
	var total := 0
	for event_value in _events(metrics, "damage"):
		var event: Dictionary = event_value
		if not str(event.get("actor_id", "")).begins_with(actor_prefix) or not str(event.get("target_id", "")).begins_with(target_prefix):
			continue
		if windows.any(func(window): return int(event.get("frame", -1)) >= window.x and int(event.get("frame", -1)) <= window.y):
			total += int(event.get("amount", 0))
	return total


func _last_damage_frame(metrics: Dictionary, target_prefix: String) -> int:
	var result := 999999999
	var matched := false
	for event_value in _events(metrics, "damage"):
		var event: Dictionary = event_value
		if str(event.get("target_id", "")).begins_with(target_prefix):
			result = int(event.get("frame", -1))
			matched = true
	return result if matched else 999999999


func _first_terminal_damage_frame(metrics: Dictionary, target_prefix: String) -> int:
	var actor_frames: Dictionary = {}
	for event_value in _events(metrics, "damage"):
		var event: Dictionary = event_value
		var target_id := str(event.get("target_id", ""))
		if target_id.begins_with(target_prefix):
			actor_frames[target_id] = int(event.get("frame", -1))
	var values: Array = actor_frames.values()
	if values.is_empty():
		return 999999999
	values.sort()
	return int(values[0])


func _last_damage_zone(metrics: Dictionary, target_prefix: String) -> String:
	var result := ""
	for event_value in _events(metrics, "damage"):
		var event: Dictionary = event_value
		if str(event.get("target_id", "")).begins_with(target_prefix):
			result = str(event.get("zone_id", ""))
	return result


func _actor_terminal_defeated(run: Dictionary, unit_id: String) -> bool:
	return _candidate_primary_success(run) and _last_damage_frame(run.get("metrics", {}), "enemy:%s" % unit_id) < 999999999


func _reinforcement_first_zone(metrics: Dictionary, unit_id: String) -> String:
	var actors: Array[String] = []
	for event_value in _events(metrics, "spawn"):
		var event: Dictionary = event_value
		if str(event.get("unit_id", "")) == unit_id and bool(event.get("second_phase", false)):
			actors.append(str(event.get("actor_id", "")))
	var zones: Array[String] = []
	for actor_id in actors:
		for event_value in _events(metrics, "damage"):
			var event: Dictionary = event_value
			if str(event.get("actor_id", "")) == actor_id or str(event.get("target_id", "")) == actor_id:
				zones.append(str(event.get("zone_id", "")))
				break
	if zones.is_empty():
		return ""
	var first := zones[0]
	return first if zones.all(func(zone): return zone == first) else "mixed"


func _candidate_digest(run: Dictionary) -> Dictionary:
	var metrics: Dictionary = run.get("metrics", {})
	var first_events := _events(metrics, "first_engagement")
	var first_event: Dictionary = first_events[0] if not first_events.is_empty() else {}
	var first_actor_id := str(first_event.get("actor_id", ""))
	var first_spawns := _events(metrics, "spawn").filter(func(event): return str(event.get("actor_id", "")) == first_actor_id)
	var first_spawn: Dictionary = first_spawns[0] if not first_spawns.is_empty() else {}
	return {
		"day": int(run.get("day", 0)),
		"scenario": str(run.get("scenario_id", "")),
		"seed": int(run.get("seed", 0)),
		"win": bool(run.get("win", false)),
		"completed": bool(run.get("completed", false)),
		"seconds": snappedf(float(run.get("combat_seconds", 0.0)), 0.01),
		"first_zone": str(metrics.get("first_engagement_zone", "")),
		"first_frame": int(metrics.get("first_engagement_frame", -1)),
		"first_actor": first_actor_id,
		"first_target": str(first_event.get("target_id", "")),
		"first_actor_home": str(first_spawn.get("home_zone", "")),
		"first_actor_spawn_zone": str(first_spawn.get("zone_id", "")),
		"throne_damage": int(metrics.get("throne_damage", 0)),
		"gold_stolen": int(metrics.get("gold_stolen", 0)),
		"disable_seconds": snappedf(float(metrics.get("max_contiguous_facility_disabled_seconds", 0.0)), 0.01),
		"rear_pressure_seconds": snappedf(float(metrics.get("rear_pressure_seconds", 0.0)), 0.01),
		"fallback_breaches": int(metrics.get("fallback_breaches", 0)),
		"second_phase_leaks": int(metrics.get("second_phase_leaks", 0)),
		"monster_damage": int(metrics.get("monster_damage_total", 0)),
		"monster_end_hp": int(metrics.get("monster_end_hp", 0)),
		"protection_bypass_seconds": snappedf(float(metrics.get("protection_bypass_seconds", 0.0)), 0.01),
		"imp_damage_archer_during_reveal": _damage_during_reveal(metrics, "monster:imp", "enemy:anti_magic_archer"),
		"recovery_healing": _facility_heal_amount(metrics, "v20_recovery_nest"),
		"required_objective_failure": str(run.get("required_objective_failure", "")),
		"live_enemies": run.get("live_enemies", []).duplicate(true) if not bool(run.get("completed", false)) else [],
		"live_monsters": run.get("live_monsters", []).duplicate(true) if not bool(run.get("completed", false)) else [],
		"command_observations": run.get("command_observations", []).duplicate(true)
	}


func _new_root_to_placement(path: String, case_day: int = 1):
	SaveStore.delete(path)
	var game_root = GameRootScene.instantiate()
	game_root._v20_set_save_path_for_tests(path)
	add_child(game_root)
	await get_tree().process_frame
	await get_tree().process_frame
	var acceptance: Dictionary
	if case_day == 1:
		acceptance = game_root._v20_configure_acceptance_sources_for_tests(["--v20-acceptance", "--v20-seed-map=1:2001,2:2002,3:2003,4:2004,5:2005", "--v20-scenario=FREE"], "", true)
	else:
		acceptance = game_root.begin_acceptance_case(case_day, 2000 + case_day, "FREE")
	_expect(bool(acceptance.get("ok", false)), "DAY %d FREE acceptance 입력 승인" % case_day)
	game_root._v20_start_new_session("v20_tactician")
	await get_tree().process_frame
	_expect(game_root._v20_start_placement(), "DAY %d INTRUSION_BRIEF→PLACEMENT 정상 전이" % case_day)
	return game_root


func _advance_to_result(game_root) -> int:
	var frames := 0
	while game_root.current_screen == Constants.SCREEN_COMBAT and frames < MAX_NATURAL_FRAMES:
		await get_tree().physics_frame
		frames += 1
	return frames


func _apply_facility_install(game_root, placement: Dictionary, facility_id: String, zone_id: String) -> Dictionary:
	var operation := PlacementService.place_facility_drag(placement, facility_id, zone_id, DataRegistry.v20_facilities)
	_expect(bool(operation.get("ok", false)), "%s를 %s에 실제 placement API로 설치" % [facility_id, zone_id])
	var next: Dictionary = operation.get("state", placement)
	game_root._v20_update_placement_state(next, operation)
	return next


func _apply_monster_move(game_root, placement: Dictionary, monster_id: String, zone_id: String) -> Dictionary:
	var operation := PlacementService.place_monster_drag(placement, monster_id, zone_id)
	_expect(bool(operation.get("ok", false)), "%s를 %s canonical slot에 실제 placement API로 이동" % [monster_id, zone_id])
	var next: Dictionary = operation.get("state", placement)
	game_root._v20_update_placement_state(next, operation)
	return next


func _actor(actor_id: String, unit_id: String, faction: String, position: Vector2, zone_id: String, goal_zone: String, alive: bool, attackable: bool) -> Dictionary:
	return {"actor_id": actor_id, "unit_id": unit_id, "faction": faction, "world_position": [position.x, position.y], "zone_id": zone_id, "goal_zone": goal_zone, "target_id": "", "alive": alive, "attackable": attackable, "hp": 100, "max_hp": 100, "protected": false, "targetable": true, "protection_window_id": "", "second_phase": false}


func _metric_digest(metrics: Dictionary) -> Dictionary:
	return {
		"first_engagement_zone": str(metrics.get("first_engagement_zone", "")),
		"movement_path_fingerprint": str(metrics.get("movement_path_fingerprint", "")),
		"movement_path_cells": int(metrics.get("movement_path_cells", 0)),
		"frontline_hold_seconds": float(metrics.get("frontline_hold_seconds", 0.0)),
		"throne_damage": int(metrics.get("throne_damage", 0)),
		"monster_damage_total": int(metrics.get("monster_damage_total", 0)),
		"monster_end_hp": int(metrics.get("monster_end_hp", 0)),
		"facility_effect_events": int(metrics.get("facility_effect_events", 0))
	}


func _board() -> Dictionary:
	return DataRegistry.v20_dungeon_layouts.get("v20_day_01_05_board", {}).duplicate(true)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20PlacementCausality] FAIL: %s" % message)
