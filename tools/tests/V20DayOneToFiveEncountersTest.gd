extends Node

const Validator = preload("res://scripts/v20/contracts/V20ContractValidator.gd")
const EncounterService = preload("res://scripts/v20/encounters/V20EncounterService.gd")
const WaveManager = preload("res://scripts/combat/WaveManager.gd")
const FIXTURE_PATH := "res://tools/tests/fixtures/v20/day_response_scenarios.json"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_contract()
	_test_schedules_and_routes()
	_test_telegraph_response_and_failure()
	_test_strategy_alternatives()
	_test_wave_manager_adapter()
	_test_candidate_schedule_and_required_objectives()
	_test_candidate_fixture_contract()
	if failed:
		print("V20_DAY_ONE_TO_FIVE_ENCOUNTERS_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_DAY_ONE_TO_FIVE_ENCOUNTERS_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_contract() -> void:
	var validation := Validator.validate_catalog("encounter", DataRegistry.v20_encounters)
	_expect(bool(validation.get("ok", false)), "DAY 1~5 encounter validator 통과: %s" % [validation.get("errors", [])])
	_expect(DataRegistry.v20_encounters.size() == 5, "DAY 1~5 encounter 5개 로드")
	var days: Array[int] = []
	for encounter_id in DataRegistry.v20_encounters.keys():
		var encounter: Dictionary = DataRegistry.v20_encounters.get(encounter_id, {})
		days.append(int(encounter.get("day", 0)))
		_expect(encounter.get("preview", {}).get("route_ids", []).all(func(route_id): return str(route_id) == "v20_castle_intrusion_route"), "%s preview가 canonical route ID만 사용" % encounter_id)
		for phase_value in encounter.get("phases", []):
			var phase: Dictionary = phase_value
			_expect(phase.get("response_tags", []).size() >= 2, "%s/%s 유효 대응 태그 2개 이상" % [encounter_id, str(phase.get("id", ""))])
			for spawn_value in phase.get("spawns", []):
				var spawn: Dictionary = spawn_value
				_expect(DataRegistry.enemies.has(str(spawn.get("enemy_id", ""))), "%s enemy ID가 제품 catalog에 존재" % str(spawn.get("enemy_id", "")))
				_expect(str(spawn.get("route_policy", "")) == "v20_castle_intrusion_route", "%s spawn이 canonical route policy 사용" % str(spawn.get("enemy_id", "")))
				_expect(float(spawn.get("hp_scale", 0.0)) <= float(encounter.get("limits", {}).get("hp_scale_max", 0.0)), "%s HP scale이 DAY 상한 이하" % str(spawn.get("enemy_id", "")))
	days.sort()
	_expect(days == [1, 2, 3, 4, 5], "DAY 번호 1~5 중복·누락 없음")


func _test_schedules_and_routes() -> void:
	var expected_counts := {1: 6, 2: 5, 3: 5, 4: 5, 5: 6}
	var fixed_nodes: Array = _board().get("fixed_route", {}).get("nodes", [])
	for day in range(1, 6):
		var encounter := EncounterService.encounter_for_day(day, DataRegistry.v20_encounters)
		var schedule := EncounterService.build_schedule(encounter, _board(), _context("gate_outpost", 805))
		_expect(schedule.size() == int(expected_counts.get(day, 0)), "DAY %d spawn 수 %d" % [day, schedule.size()])
		_expect(schedule.all(func(row): return _is_fixed_prefix(row.get("route_nodes", []), fixed_nodes) and str(row.get("route_signature", "")) != ""), "DAY %d 모든 spawn이 canonical route 또는 prefix 사용" % day)
		_expect(schedule == EncounterService.build_schedule(encounter, _board(), _context("gate_outpost", 805)), "DAY %d 같은 seed schedule 재현" % day)
		var changed := EncounterService.build_schedule(encounter, _board(), _context("throne_anteroom", 9900 + day))
		var throne_rows := changed.filter(func(row): return str(row.get("goal_key", "")) == "throne")
		_expect(not throne_rows.is_empty() and throne_rows.all(func(row): return row.get("route_nodes", []) == fixed_nodes), "DAY %d 시설 목표 변경 뒤에도 왕좌 침입 순서 고정" % day)

	var day_three := EncounterService.encounter_for_day(3, DataRegistry.v20_encounters)
	var front_schedule := EncounterService.build_schedule(day_three, _board(), _context("gate_outpost", 805))
	var rear_schedule := EncounterService.build_schedule(day_three, _board(), _context("throne_anteroom", 805))
	var front_engineer: Dictionary = front_schedule.filter(func(row): return str(row.get("enemy_id", "")) == "engineer")[0]
	var rear_engineer: Dictionary = rear_schedule.filter(func(row): return str(row.get("enemy_id", "")) == "engineer")[0]
	_expect(front_engineer.get("route_nodes", []) == ["gate_outpost"] and rear_engineer.get("route_nodes", []) == ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom"], "DAY 3 공병이 실제 시설 구역까지의 canonical prefix 사용")


func _test_telegraph_response_and_failure() -> void:
	var encounter := EncounterService.encounter_for_day(3, DataRegistry.v20_encounters)
	var state := EncounterService.new_state(encounter, _board(), _context("gate_outpost", 303))
	state = EncounterService.advance(state, 0.0, encounter)
	_expect(state.get("events", []).any(func(event): return str(event.get("type", "")) == "telegraph" and str(event.get("phase_id", "")) == "engineer_entry"), "DAY 3 시작 시 engineer_entry 예고 발생")
	state = EncounterService.advance(state, 5.0, encounter)
	_expect(state.get("events", []).any(func(event): return str(event.get("type", "")) == "phase_started"), "5초 예고 후 engineer_entry 시작")
	_expect(not bool(EncounterService.apply_response(state, encounter, "engineer_entry", "unknown_response").get("ok", true)), "선언되지 않은 대응 거부")
	state = EncounterService.apply_response(state, encounter, "engineer_entry", "focus_target").get("state", {})
	var success := EncounterService.resolve_phase(state, encounter, "engineer_entry")
	_expect(bool(success.get("success", false)), "실제 실패 지표 0이면 response tag와 무관하게 phase 성공")
	var no_response := EncounterService.resolve_phase(EncounterService.new_state(encounter, _board(), _context("gate_outpost", 303)), encounter, "engineer_entry")
	_expect(bool(no_response.get("success", false)), "response tag 0개도 실제 실패 지표 0이면 성공")
	var failed_state := EncounterService.new_state(encounter, _board(), _context("gate_outpost", 303))
	failed_state = EncounterService.apply_response(failed_state, encounter, "engineer_entry", "backup_line").get("state", {})
	failed_state = EncounterService.record_metric(failed_state, encounter, "engineer_entry", "facility_disabled_seconds", 7.0).get("state", {})
	var failure := EncounterService.resolve_phase(failed_state, encounter, "engineer_entry")
	_expect(not bool(failure.get("success", true)) and float(failure.get("state", {}).get("result_metrics", {}).get("facility_disabled_seconds", 0.0)) == 7.0, "시설 무력화 7초를 기록한 phase는 실패")
	_expect(str(success.get("outcome_signature", "")) != str(failure.get("outcome_signature", "")), "성공·실패 outcome signature 분리")


func _test_strategy_alternatives() -> void:
	for day in range(1, 6):
		var encounter := EncounterService.encounter_for_day(day, DataRegistry.v20_encounters)
		var response_a: Array[String] = []
		var response_b: Array[String] = []
		for phase_value in encounter.get("phases", []):
			var tags: Array = phase_value.get("response_tags", [])
			response_a.append(str(tags[0]))
			response_b.append(str(tags[1]))
		var metadata_a := EncounterService.evaluate_strategy(encounter, {"id": "a", "response_tags": response_a})
		var metadata_b := EncounterService.evaluate_strategy(encounter, {"id": "b", "response_tags": response_b})
		_expect(bool(metadata_a.get("metadata_complete", false)) and not bool(metadata_a.get("success", true)), "DAY %d 대응 A tag는 설명 metadata이며 성공 판정 아님" % day)
		_expect(bool(metadata_b.get("metadata_complete", false)) and not bool(metadata_b.get("success", true)), "DAY %d 대응 B tag는 설명 metadata이며 성공 판정 아님" % day)


func _test_wave_manager_adapter() -> void:
	for day in range(1, 6):
		var entries: Array = EncounterService.wave_catalog_for_day(day, DataRegistry.v20_encounters, _board(), _context("gate_outpost", 900 + day)).get("day_%d" % day, [])
		_expect(not entries.is_empty() and entries.all(func(entry): return int(entry.get("count", 0)) == 1 and entry.has("v20_phase_id") and _is_fixed_prefix(entry.get("v20_route_nodes", []), _board().get("fixed_route", {}).get("nodes", []))), "DAY %d WaveManager adapter가 canonical route 전달" % day)
	var day_two_entries: Array = EncounterService.wave_catalog_for_day(2, DataRegistry.v20_encounters, _board(), _context("gate_outpost", 902)).get("day_2", [])
	var thief_entry: Dictionary = day_two_entries.filter(func(entry): return str(entry.get("enemy_id", "")) == "thief")[0]
	_expect(str(thief_entry.get("v20_goal_key", "")) == "central_battle_room" and not thief_entry.has("goal_type_override"), "DAY 2 도둑의 좌표 goal key가 treasure 행동 유형을 덮어쓰지 않음")
	var encounter := EncounterService.encounter_for_day(5, DataRegistry.v20_encounters)
	var status := EncounterService.hud_status(EncounterService.new_state(encounter, _board(), _context("gate_outpost", 5)), encounter)
	_expect(str(status.get("recommended_command_id", "")) == "v20_emergency_fallback" and str(status.get("recommended_target_label", "")) != "", "DAY 5 HUD가 비상 후퇴 명령과 왕좌 전실 목표 제공")
	var manager = WaveManager.new()
	var catalog := EncounterService.wave_catalog_for_day(4, DataRegistry.v20_encounters, _board(), _context("gate_outpost", 2004))
	manager.setup_v20(4, catalog, 2004, 778899)
	_expect(manager.v20_seed == 2004 and manager.v20_rng_state == 778899 and manager.total_to_spawn == 5, "acceptance seed·RNG state가 WaveManager v20 adapter까지 전달")


func _test_candidate_schedule_and_required_objectives() -> void:
	var expected := {
		1: [["explorer", 30], ["explorer", 110], ["explorer", 190], ["explorer", 270], ["explorer", 350], ["explorer", 430]],
		2: [["thief", 40], ["explorer", 50], ["explorer", 197], ["explorer", 344], ["explorer", 491]],
		3: [["engineer", 50], ["explorer", 150], ["explorer", 285], ["explorer", 420], ["explorer", 555]],
		4: [["shieldbearer", 50], ["anti_magic_archer", 94], ["shieldbearer", 233], ["shieldbearer", 416], ["shieldbearer", 599]],
		5: [["trainee_hero", 60], ["explorer", 450], ["explorer", 530], ["explorer", 610], ["explorer", 690], ["thief", 770]]
	}
	for day in range(1, 6):
		var encounter := EncounterService.encounter_for_day(day, DataRegistry.v20_encounters)
		var schedule := EncounterService.build_schedule(encounter, _board(), _context("gate_outpost", 2000 + day))
		var actual: Array = schedule.map(func(row): return [str(row.get("enemy_id", "")), roundi(float(row.get("time", 0.0)) * 10.0)])
		_expect(actual == expected.get(day, []), "DAY %d 후보 적 ID·spawn 0.1초 단위 고정: %s" % [day, str(actual)])
	var day_one := EncounterService.build_schedule(EncounterService.encounter_for_day(1, DataRegistry.v20_encounters), _board(), _context("gate_outpost", 2001))
	_expect(day_one.all(func(row): return int(row.get("max_hp_bonus", 0)) == 40 and is_equal_approx(float(row.get("hp_scale", 0.0)), 1.10) and is_equal_approx(float(row.get("atk_scale", 0.0)), 2.00)), "DAY 1 6명 모두 HP +40·×1.10, 공격 ×2.00")
	var day_four := EncounterService.build_schedule(EncounterService.encounter_for_day(4, DataRegistry.v20_encounters), _board(), _context("gate_outpost", 2004))
	_expect(int(day_four[0].get("max_hp_bonus", 0)) == 170 and day_four.slice(2).filter(func(row): return str(row.get("enemy_id", "")) == "shieldbearer").all(func(row): return int(row.get("max_hp_bonus", 0)) == 0), "DAY 4 첫 방패병만 HP +170")

	var day_two := EncounterService.encounter_for_day(2, DataRegistry.v20_encounters)
	_expect(not bool(EncounterService.required_objective_result(day_two, {"gold_stolen": 100}).get("success", true)), "DAY 2 실제 도난 100이면 protect_treasure 실패")
	var disable_only := {"event_ledger": [{"type": "facility_disable_started", "placement_id": "front", "frame": 120}, {"type": "facility_disable_ended", "placement_id": "front", "frame": 540}]}
	var disable_with_backup := {"event_ledger": [{"type": "facility_disable_started", "placement_id": "front", "frame": 120}, {"type": "facility_effect", "placement_id": "rear", "frame": 240}, {"type": "facility_disable_ended", "placement_id": "front", "frame": 540}]}
	var day_three := EncounterService.encounter_for_day(3, DataRegistry.v20_encounters)
	_expect(not bool(EncounterService.required_objective_result(day_three, disable_only).get("success", true)) and bool(EncounterService.required_objective_result(day_three, disable_with_backup).get("success", false)), "DAY 3 무력화 중 다른 시설 실제 effect 유무로 필수 목표 분리")
	var day_four_encounter := EncounterService.encounter_for_day(4, DataRegistry.v20_encounters)
	_expect(not bool(EncounterService.required_objective_result(day_four_encounter, {"rear_pressure_seconds": 6.0}).get("success", true)) and bool(EncounterService.required_objective_result(day_four_encounter, {"rear_pressure_seconds": 5.98}).get("success", false)), "DAY 4 후열 압박 6.00초부터 break_rear_pressure 실패")
	var day_five := EncounterService.encounter_for_day(5, DataRegistry.v20_encounters)
	_expect(not bool(EncounterService.required_objective_result(day_five, {"fallback_breaches": 1}).get("success", true)) and not bool(EncounterService.required_objective_result(day_five, {"second_phase_leaks": 1}).get("success", true)) and not bool(EncounterService.required_objective_result(day_five, {"gold_stolen": 100}).get("success", true)) and bool(EncounterService.required_objective_result(day_five, {}).get("success", false)), "DAY 5 후퇴 돌파·증원 누수·도난 각각 필수 목표 실패")


func _test_candidate_fixture_contract() -> void:
	var file := FileAccess.open(FIXTURE_PATH, FileAccess.READ)
	var fixture = JSON.parse_string(file.get_as_text()) if file != null else null
	_expect(fixture is Dictionary and int(fixture.get("schema_version", 0)) == 1, "DAY A/B/C/D 후보 fixture JSON schema 1")
	if not (fixture is Dictionary):
		return
	_expect(str(fixture.get("difficulty_id", "")) == "v20_tactician" and int(fixture.get("combat_speed", 0)) == 1 and int(fixture.get("physics_fps", 0)) == 60, "fixture는 보통·x1·60 Hz만 선언")
	for day in range(1, 6):
		var day_fixture: Dictionary = fixture.get("days", {}).get(str(day), {})
		var scenarios: Dictionary = day_fixture.get("scenarios", {})
		_expect(int(fixture.get("seed_schedule", {}).get(str(day), 0)) == 2000 + day and scenarios.keys().all(func(key): return str(key) in ["A", "B", "C", "D"]) and scenarios.size() == 4, "DAY %d seed와 A/B/C/D 네 fixture" % day)
		for scenario_id in ["A", "B", "C", "D"]:
			var scenario: Dictionary = scenarios.get(scenario_id, {})
			var monster_ids: Array[String] = []
			var slot_ids: Array[String] = []
			for monster_value in scenario.get("monsters", []):
				var monster: Dictionary = monster_value
				monster_ids.append(str(monster.get("monster_id", "")))
				slot_ids.append(str(monster.get("slot_id", "")))
			monster_ids.sort()
			_expect(monster_ids == ["goblin", "imp", "slime"] and slot_ids.size() == 3 and _unique_count(slot_ids) == 3, "DAY %d %s 기존 몬스터 3종·고유 slot" % [day, scenario_id])
			_expect(scenario.has("primary_success") and scenario.has("secondary_success") and scenario.get("mechanism_assertions", []) is Array, "DAY %d %s primary·secondary·mechanism 선언" % [day, scenario_id])
			_expect(scenario.get("facilities", []).all(func(row): return DataRegistry.v20_facilities.has(str(row.get("facility_id", ""))) and str(row.get("slot_id", "")).ends_with("_facility")), "DAY %d %s 시설 ID·slot 참조 유효" % [day, scenario_id])
			_expect(scenario.get("command_events", []).all(func(row): return DataRegistry.v20_commands.has(str(row.get("command_id", ""))) and str(row.get("trigger", "")) != ""), "DAY %d %s 명령 ID·event trigger 참조 유효" % [day, scenario_id])
		var diff := _fixture_monster_diff(scenarios.get("A", {}), scenarios.get("D", {}))
		var declared: Dictionary = day_fixture.get("d_slot_change", {})
		_expect(scenarios.get("A", {}).get("facilities", []) == scenarios.get("D", {}).get("facilities", []) and scenarios.get("A", {}).get("command_events", []) == scenarios.get("D", {}).get("command_events", []) and diff.size() == 1 and str(diff[0].get("monster_id", "")) == str(declared.get("monster_id", "")) and str(diff[0].get("from", "")) == str(declared.get("from", "")) and str(diff[0].get("to", "")) == str(declared.get("to", "")), "DAY %d D는 A의 선언된 monster slot 한 건만 변경" % day)
	var encounter_source := FileAccess.get_file_as_string("res://data/v20/encounters.json")
	var registry_source := FileAccess.get_file_as_string("res://scripts/core/DataRegistry.gd")
	_expect("flank_route" not in encounter_source and "opposite_first_engagement" not in encounter_source and "north_route" not in encounter_source and "south_route" not in encounter_source, "고정 1경로와 모순되는 encounter key 0건")
	_expect("day_response_scenarios.json" not in registry_source, "product DataRegistry가 test fixture를 읽지 않음")


func _unique_count(values: Array[String]) -> int:
	var seen: Dictionary = {}
	for value in values:
		seen[value] = true
	return seen.size()


func _fixture_monster_diff(a: Dictionary, d: Dictionary) -> Array[Dictionary]:
	var a_slots: Dictionary = {}
	var d_slots: Dictionary = {}
	for row_value in a.get("monsters", []):
		var row: Dictionary = row_value
		a_slots[str(row.get("monster_id", ""))] = str(row.get("slot_id", ""))
	for row_value in d.get("monsters", []):
		var row: Dictionary = row_value
		d_slots[str(row.get("monster_id", ""))] = str(row.get("slot_id", ""))
	var result: Array[Dictionary] = []
	for monster_id_value in a_slots.keys():
		var monster_id := str(monster_id_value)
		if str(a_slots.get(monster_id, "")) != str(d_slots.get(monster_id, "")):
			result.append({"monster_id": monster_id, "from": str(a_slots.get(monster_id, "")), "to": str(d_slots.get(monster_id, ""))})
	return result


func _board() -> Dictionary:
	return DataRegistry.v20_dungeon_layouts.get("v20_day_01_05_board", {}).duplicate(true)


func _context(facility_node: String, seed_value: int) -> Dictionary:
	return {
		"seed": seed_value,
		"facilities": [{"id": "primary", "facility_id": "v20_barricade", "node_id": facility_node, "active": true}],
		"door_state_costs": {},
		"facility_route_costs": {},
		"temporary_hazard_costs": {}
	}


func _is_fixed_prefix(route_nodes: Array, fixed_nodes: Array) -> bool:
	return not route_nodes.is_empty() and route_nodes == fixed_nodes.slice(0, route_nodes.size())


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20DayOneToFiveEncounters] FAIL: %s" % message)
