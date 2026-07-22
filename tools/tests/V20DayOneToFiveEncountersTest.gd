extends Node

const Validator = preload("res://scripts/v20/contracts/V20ContractValidator.gd")
const EncounterService = preload("res://scripts/v20/encounters/V20EncounterService.gd")
const HUDScene = preload("res://scenes/v20/ui/V20InformationHUD.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_contract()
	_test_schedules_and_routes()
	_test_telegraph_response_and_failure()
	_test_fixed_strategy_gate()
	_test_multiple_responses()
	_test_wave_manager_adapter()
	if OS.get_cmdline_user_args().has("--capture-v20-encounter") and DisplayServer.get_name() != "headless":
		await _capture_encounter_hud()
	if failed:
		print("V20_DAY_ONE_TO_FIVE_ENCOUNTERS_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_DAY_ONE_TO_FIVE_ENCOUNTERS_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_contract() -> void:
	var validation := Validator.validate_catalog("encounter", DataRegistry.v20_encounters)
	_expect(bool(validation.get("ok", false)), "DAY 1~5 encounter validator 승인: %s" % [validation.get("errors", [])])
	_expect(DataRegistry.v20_encounters.size() == 5, "DAY 1~5 encounter 정확히 5개")
	var days: Array[int] = []
	for encounter_id_value in DataRegistry.v20_encounters.keys():
		var encounter: Dictionary = DataRegistry.v20_encounters.get(encounter_id_value, {})
		days.append(int(encounter.get("day", 0)))
		_expect(encounter.get("preview", {}).get("targets", []).size() >= 1 and encounter.get("preview", {}).get("route_ids", []).size() >= 1, "%s 목표·확정 경로 preview" % encounter_id_value)
		_expect(encounter.get("preview", {}).get("route_ids", []).all(func(route_id): return str(route_id).begins_with("fixed_")), "%s preview가 고정 경로·구간 용어만 사용" % encounter_id_value)
		for phase_value in encounter.get("phases", []):
			var phase: Dictionary = phase_value
			_expect(phase.get("response_tags", []).size() >= 2, "%s/%s 대응 두 개 이상" % [encounter_id_value, str(phase.get("id", ""))])
			for spawn_value in phase.get("spawns", []):
				var spawn: Dictionary = spawn_value
				_expect(DataRegistry.enemies.has(str(spawn.get("enemy_id", ""))), "%s 기존 enemy ID 재사용" % str(spawn.get("enemy_id", "")))
				_expect(float(spawn.get("hp_scale", 0.0)) <= float(encounter.get("limits", {}).get("hp_scale_max", 0.0)), "%s HP scale 상한 준수" % str(spawn.get("enemy_id", "")))
	days.sort()
	_expect(days == [1, 2, 3, 4, 5], "DAY 번호 1~5 중복·누락 없음")


func _test_schedules_and_routes() -> void:
	var expected_counts := {1: 3, 2: 3, 3: 3, 4: 3, 5: 4}
	var fixed_nodes: Array = _board().get("fixed_route", {}).get("nodes", [])
	for day in range(1, 6):
		var encounter := EncounterService.encounter_for_day(day, DataRegistry.v20_encounters)
		var schedule := EncounterService.build_schedule(encounter, _board(), _context("north_gate", 805))
		_expect(schedule.size() == int(expected_counts.get(day, 0)), "DAY %d spawn schedule %d명" % [day, schedule.size()])
		var all_routed := schedule.all(func(row): return _is_fixed_prefix(row.get("route_nodes", []), fixed_nodes) and str(row.get("route_signature", "")) != "")
		_expect(all_routed, "DAY %d 모든 spawn이 선언된 고정 침입로 또는 목표 prefix 사용" % day)
		var repeat := EncounterService.build_schedule(encounter, _board(), _context("north_gate", 805))
		_expect(schedule == repeat, "DAY %d 동일 seed schedule deterministic" % day)
		var changed_context := _context("fallback", 9900 + day)
		changed_context["door_state_costs"] = {"door_north": 999.0, "door_south": 999.0}
		changed_context["facility_route_costs"] = {"entry_north": 500.0, "fallback_throne": 500.0}
		changed_context["temporary_hazard_costs"] = {"south_treasure": 250.0}
		var changed := EncounterService.build_schedule(encounter, _board(), changed_context)
		var throne_rows := changed.filter(func(row): return str(row.get("goal_key", "")) == "throne")
		_expect(not throne_rows.is_empty() and throne_rows.all(func(row): return row.get("route_nodes", []) == fixed_nodes), "DAY %d seed·시설·위험 비용과 무관하게 왕좌 침입로 고정" % day)
	var day_three := EncounterService.encounter_for_day(3, DataRegistry.v20_encounters)
	var north := EncounterService.build_schedule(day_three, _board(), _context("north_gate", 805))
	var south := EncounterService.build_schedule(day_three, _board(), _context("south_cross", 805))
	var north_engineer: Dictionary = north.filter(func(row): return str(row.get("enemy_id", "")) == "engineer")[0]
	var south_engineer: Dictionary = south.filter(func(row): return str(row.get("enemy_id", "")) == "engineer")[0]
	_expect(str(north_engineer.get("route_signature", "")) != str(south_engineer.get("route_signature", "")), "공병은 같은 고정 길에서 목표 시설까지의 prefix만 변경")
	_expect(_is_fixed_prefix(north_engineer.get("route_nodes", []), fixed_nodes) and _is_fixed_prefix(south_engineer.get("route_nodes", []), fixed_nodes), "공병 시설 목표도 고정 침입로 밖으로 이탈하지 않음")


func _test_telegraph_response_and_failure() -> void:
	var encounter := EncounterService.encounter_for_day(3, DataRegistry.v20_encounters)
	var state := EncounterService.new_state(encounter, _board(), _context("north_gate", 303))
	state = EncounterService.advance(state, 0.0, encounter)
	_expect(state.get("events", []).any(func(event): return str(event.get("type", "")) == "telegraph" and str(event.get("phase_id", "")) == "engineer_entry"), "DAY 3 시작 전 공병 무력화 예고")
	state = EncounterService.advance(state, 5.0, encounter)
	_expect(state.get("events", []).any(func(event): return str(event.get("type", "")) == "phase_started"), "5초 예고 뒤 공병 phase 시작")
	var invalid := EncounterService.apply_response(state, encounter, "engineer_entry", "unknown_response")
	_expect(not bool(invalid.get("ok", true)), "미선언 encounter 대응 거부")
	state = EncounterService.apply_response(state, encounter, "engineer_entry", "focus_target").get("state", {})
	var success := EncounterService.resolve_phase(state, encounter, "engineer_entry")
	_expect(bool(success.get("success", false)), "집중 대응·시설 무력화 0초면 phase 성공")
	var failed_state := EncounterService.new_state(encounter, _board(), _context("north_gate", 303))
	failed_state = EncounterService.apply_response(failed_state, encounter, "engineer_entry", "backup_line").get("state", {})
	failed_state = EncounterService.record_metric(failed_state, encounter, "engineer_entry", "facility_disabled_seconds", 7.0).get("state", {})
	var failed_result := EncounterService.resolve_phase(failed_state, encounter, "engineer_entry")
	_expect(not bool(failed_result.get("success", true)) and float(failed_result.get("state", {}).get("result_metrics", {}).get("facility_disabled_seconds", 0.0)) == 7.0, "대응 선택이 있어도 실패 지표 발생 시 실패·결산 유지")
	_expect(str(success.get("outcome_signature", "")) != str(failed_result.get("outcome_signature", "")), "성공·실패 outcome signature 분리")


func _test_fixed_strategy_gate() -> void:
	var fixed := {"id": "unchanged_front_blob", "response_tags": ["entry_anchor", "rear_fire", "read_combat"]}
	var results: Array[bool] = []
	for day in range(1, 6):
		var encounter := EncounterService.encounter_for_day(day, DataRegistry.v20_encounters)
		results.append(bool(EncounterService.evaluate_strategy(encounter, fixed).get("success", false)))
	_expect(results[0], "DAY 1 기본 전열+후방 조합 성공")
	_expect(not results[1] and not results[2] and not results[3] and not results[4], "DAY 2~5 고정 입구 배치·무명령 완주 불가 계약")


func _test_multiple_responses() -> void:
	for day in range(1, 6):
		var encounter := EncounterService.encounter_for_day(day, DataRegistry.v20_encounters)
		var strategy_a: Array[String] = []
		var strategy_b: Array[String] = []
		for phase_value in encounter.get("phases", []):
			var tags: Array = phase_value.get("response_tags", [])
			strategy_a.append(str(tags[0]))
			strategy_b.append(str(tags[1]))
		var result_a := EncounterService.evaluate_strategy(encounter, {"id": "a", "response_tags": strategy_a})
		var result_b := EncounterService.evaluate_strategy(encounter, {"id": "b", "response_tags": strategy_b})
		_expect(bool(result_a.get("success", false)) and bool(result_b.get("success", false)), "DAY %d 서로 다른 두 대응 경로 성공 가능" % day)


func _test_wave_manager_adapter() -> void:
	for day in range(1, 6):
		var waves := EncounterService.wave_catalog_for_day(day, DataRegistry.v20_encounters, _board(), _context("north_gate", 900 + day))
		var entries: Array = waves.get("day_%d" % day, [])
		var fixed_nodes: Array = _board().get("fixed_route", {}).get("nodes", [])
		_expect(not entries.is_empty() and entries.all(func(entry): return int(entry.get("count", 0)) == 1 and entry.has("v20_phase_id") and _is_fixed_prefix(entry.get("v20_route_nodes", []), fixed_nodes)), "DAY %d 기존 WaveManager 고정 경로 adapter" % day)
	var status := EncounterService.hud_status(EncounterService.new_state(EncounterService.encounter_for_day(5, DataRegistry.v20_encounters), _board(), _context("north_gate", 5)), EncounterService.encounter_for_day(5, DataRegistry.v20_encounters))
	_expect(str(status.get("pattern_title", "")) == "전열 돌파 대시" and "예비 방어선" in str(status.get("pattern_response", "")), "DAY 5 HUD 예고·대응 한국어 문구")


func _capture_encounter_hud() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var hud = HUDScene.instantiate()
	viewport.add_child(hud)
	await get_tree().process_frame
	var encounter := EncounterService.encounter_for_day(5, DataRegistry.v20_encounters)
	var encounter_state := EncounterService.new_state(encounter, _board(), _context("north_gate", 5))
	var status := EncounterService.hud_status(encounter_state, encounter)
	hud.setup("combat", {
		"objective_label": "왕좌 방어",
		"objective_hp": 68,
		"objective_hp_max": 100,
		"phase_label": status.get("phase_label", ""),
		"pattern_title": status.get("pattern_title", ""),
		"pattern_eta": status.get("pattern_eta", ""),
		"pattern_response": status.get("pattern_response", ""),
		"command_points": 2,
		"command_max": 3,
		"commands": [
			{"id": "v20_rally", "label": "집결", "status": "명령력 1"},
			{"id": "v20_focus", "label": "집중", "status": "명령력 1"},
			{"id": "v20_activate_facility", "label": "시설 발동", "status": "명령력 1"},
			{"id": "v20_emergency_fallback", "label": "비상 후퇴", "status": "명령력 2"}
		]
	})
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var path := "user://v20_phase8_day5_encounter_1280x720.png"
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_expect(error == OK, "Phase 8 DAY 5 encounter 1280x720 실제 렌더")
	if error == OK:
		print("V20_PHASE8_CAPTURE: %s" % ProjectSettings.globalize_path(path))
	viewport.queue_free()
	await get_tree().process_frame


func _board() -> Dictionary:
	return DataRegistry.v20_dungeon_layouts.get("v20_day_01_05_board", {}).duplicate(true)


func _context(facility_node: String, seed_value: int) -> Dictionary:
	return {
		"seed": seed_value,
		"facilities": [{"id": "primary", "facility_id": "v20_barricade", "node_id": facility_node, "active": true}],
		"door_state_costs": {},
		"facility_route_costs": {},
		"temporary_hazard_costs": {},
		"opposite_route_costs": {"north": 8.0}
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
