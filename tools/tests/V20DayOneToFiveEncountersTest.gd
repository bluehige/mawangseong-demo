extends Node

const Validator = preload("res://scripts/v20/contracts/V20ContractValidator.gd")
const EncounterService = preload("res://scripts/v20/encounters/V20EncounterService.gd")

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
	var expected_counts := {1: 3, 2: 3, 3: 3, 4: 3, 5: 4}
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
	_expect(bool(success.get("success", false)), "focus_target 대응과 실패 지표 0이면 phase 성공")
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
		_expect(bool(EncounterService.evaluate_strategy(encounter, {"id": "a", "response_tags": response_a}).get("success", false)), "DAY %d 대응 A가 모든 phase 통과" % day)
		_expect(bool(EncounterService.evaluate_strategy(encounter, {"id": "b", "response_tags": response_b}).get("success", false)), "DAY %d 대응 B가 모든 phase 통과" % day)


func _test_wave_manager_adapter() -> void:
	for day in range(1, 6):
		var entries: Array = EncounterService.wave_catalog_for_day(day, DataRegistry.v20_encounters, _board(), _context("gate_outpost", 900 + day)).get("day_%d" % day, [])
		_expect(not entries.is_empty() and entries.all(func(entry): return int(entry.get("count", 0)) == 1 and entry.has("v20_phase_id") and _is_fixed_prefix(entry.get("v20_route_nodes", []), _board().get("fixed_route", {}).get("nodes", []))), "DAY %d WaveManager adapter가 canonical route 전달" % day)
	var encounter := EncounterService.encounter_for_day(5, DataRegistry.v20_encounters)
	var status := EncounterService.hud_status(EncounterService.new_state(encounter, _board(), _context("gate_outpost", 5)), encounter)
	_expect(str(status.get("recommended_command_id", "")) == "v20_emergency_fallback" and str(status.get("recommended_target_label", "")) != "", "DAY 5 HUD가 비상 후퇴 명령과 왕좌 전실 목표 제공")


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
