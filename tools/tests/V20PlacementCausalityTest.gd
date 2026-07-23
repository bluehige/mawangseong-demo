extends Node

const BattleEvidence = preload("res://scripts/v20/combat/V20BattleEvidence.gd")
const FacilityService = preload("res://scripts/v20/facilities/V20FacilityService.gd")
const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const SaveStore = preload("res://scripts/v20/save/V20SaveStore.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const Constants = preload("res://scripts/core/Constants.gd")

const DAY_ONE_SEED := 2001
const MAX_NATURAL_FRAMES := 7200

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_ledger_metric_rules()
	_test_facility_effect_zone_moves()
	await _test_home_zone_actual_spawn()
	await _test_command_applies_to_all_living_monsters()
	await _test_engineer_disable_actual_effect_gap()
	await _test_thief_goal_loot_escape_with_decoy()
	await _test_day_one_a_d_natural_combat()
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
