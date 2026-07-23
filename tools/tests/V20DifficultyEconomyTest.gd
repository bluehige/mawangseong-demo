extends Node

const EconomyService = preload("res://scripts/v20/economy/V20EconomyService.gd")
const EncounterService = preload("res://scripts/v20/encounters/V20EncounterService.gd")
const CommandService = preload("res://scripts/v20/commands/V20CommandService.gd")
const HUDScene = preload("res://scenes/v20/ui/V20InformationHUD.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_and_profiles()
	_test_decision_pressure_not_time_only()
	_test_budget_and_settlement()
	_test_command_and_wave_integration()
	if OS.get_cmdline_user_args().has("--capture-v20-economy") and DisplayServer.get_name() != "headless":
		await _capture_management_hud()
	if failed:
		print("V20_DIFFICULTY_ECONOMY_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_DIFFICULTY_ECONOMY_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_and_profiles() -> void:
	var validation := EconomyService.validate_catalog(DataRegistry.v20_economy)
	_expect(bool(validation.get("ok", false)), "난이도·경제 catalog 승인: %s" % [validation.get("errors", [])])
	_expect(DataRegistry.v20_economy.size() == 3, "쉬움·보통·어려움 세 프로필")
	var story := _profile("v20_story")
	var standard := _profile("v20_tactician")
	var hard := _profile("v20_overlord")
	_expect(str(story.get("display_name", "")) == "쉬움" and str(standard.get("display_name", "")) == "보통" and str(hard.get("display_name", "")) == "어려움", "내부 ID는 유지하고 표시 난이도는 직관적 용어 사용")
	_expect(int(story.get("pressure_tier", -1)) == 0 and int(standard.get("pressure_tier", -1)) == 1 and int(hard.get("pressure_tier", -1)) == 2, "압박 tier 순서 고정")
	_expect(int(story.get("build", {}).get("initial_points", 0)) > int(standard.get("build", {}).get("initial_points", 0)) and int(standard.get("build", {}).get("initial_points", 0)) > int(hard.get("build", {}).get("initial_points", 0)), "난이도 상승 시 건설 예산 선택 압박 증가")
	_expect(float(story.get("encounter", {}).get("hp_multiplier", 0.0)) >= 0.9 and float(hard.get("encounter", {}).get("hp_multiplier", 2.0)) <= 1.1, "HP 보정 ±10% 상한")
	_expect(str(EconomyService.profile(DataRegistry.v20_economy, "unknown").get("id", "")) == EconomyService.DEFAULT_PROFILE_ID, "알 수 없는 난이도는 보통으로 안전 복귀")


func _test_decision_pressure_not_time_only() -> void:
	var base := EncounterService.encounter_for_day(5, DataRegistry.v20_encounters)
	var configured: Array[Dictionary] = []
	var loads: Array[float] = []
	var durations: Array[float] = []
	for profile_id in ["v20_story", "v20_tactician", "v20_overlord"]:
		var difficulty := _profile(profile_id)
		var encounter := EconomyService.configured_encounter(base, difficulty)
		configured.append(encounter)
		loads.append(float(EconomyService.decision_load(encounter, difficulty).get("score", 0.0)))
		durations.append(EconomyService.estimated_duration(encounter))
	_expect(configured[0].get("objectives", []).size() == 1 and configured[1].get("objectives", []).size() == 2 and configured[2].get("objectives", []).size() == 3, "난이도별 동시 목표 1·2·3")
	var story_telegraph := float(configured[0].get("phases", [])[0].get("telegraph_seconds", 0.0))
	var standard_telegraph := float(configured[1].get("phases", [])[0].get("telegraph_seconds", 0.0))
	var hard_telegraph := float(configured[2].get("phases", [])[0].get("telegraph_seconds", 0.0))
	_expect(story_telegraph > standard_telegraph and standard_telegraph > hard_telegraph, "난이도별 예고 시간 차등")
	_expect(int(configured[2].get("phases", [])[0].get("minimum_response_matches", 0)) == 2, "어려움 난이도는 같은 패턴에서 대응 조합 요구")
	_expect(loads[0] < loads[1] and loads[1] < loads[2], "난이도 상승 시 판단 부하 점수 증가")
	_expect(durations[2] / durations[0] < 1.1, "최고 난이도 예상 전투 시간 증가는 10% 미만")
	var schedules: Array[Array] = []
	for encounter in configured:
		schedules.append(EncounterService.build_schedule(encounter, _board(), _context()))
	_expect(schedules.all(func(schedule): return schedule.size() == 6), "DAY 5 난이도별 spawn 수 6으로 동일")
	_expect(_spawn_times(schedules[0]) == _spawn_times(schedules[1]) and _spawn_times(schedules[1]) == _spawn_times(schedules[2]), "난이도별 spawn 시각 동일·대기 시간 인위 증가 없음")


func _test_budget_and_settlement() -> void:
	var story := _profile("v20_story")
	var hard := _profile("v20_overlord")
	var story_state := EconomyService.new_state(story)
	var hard_state := EconomyService.new_state(hard)
	_expect(int(story_state.get("build_points", 0)) == 14 and int(hard_state.get("build_points", 0)) == 8, "초기 건설 예산 적용")
	var spent := EconomyService.spend_build(hard_state, 7, "바리케이드+병영")
	_expect(bool(spent.get("ok", false)) and int(spent.get("state", {}).get("build_points", 0)) == 1, "시설 조합 비용 지출·잔액 기록")
	var rejected := EconomyService.spend_build(spent.get("state", {}), 3, "미끼 보물실")
	_expect(not bool(rejected.get("ok", true)) and int(rejected.get("state", {}).get("build_points", 0)) == 1, "부족한 건설 예산은 원자적으로 거부")
	var victory := EconomyService.settle_day(spent.get("state", {}), hard, {"success": true, "objective_damage": 60, "command_points_spent": 2, "secondary_objectives_lost": 1})
	_expect(int(victory.get("gross_income", 0)) == 3 and int(victory.get("repair_cost", 0)) == 3 and int(victory.get("net_income", -1)) == 0, "어려움 승리 수입에서 실제 피해 수리비 차감")
	var retry := EconomyService.settle_day(hard_state, hard, {"success": false, "objective_damage": 0})
	_expect(int(retry.get("gross_income", 0)) == 1 and int(retry.get("state", {}).get("build_points", 0)) == 9, "패배 재도전용 최소 회수 자원")
	var validation_profile := _profile("v20_tactician")
	var validation_state := EconomyService.new_state(validation_profile)
	var validation_win := EconomyService.settle_day(validation_state, validation_profile, {"success": true, "objective_damage": 1500})
	var validation_loss := EconomyService.settle_day(validation_state, validation_profile, {"success": false, "objective_damage": 0})
	_expect(int(validation_win.get("gross_income", -1)) == 0 and int(validation_win.get("net_income", -1)) == 0 and int(validation_win.get("state", {}).get("build_points", -1)) == 10, "검증선 승리 income 0·건설 상한 증가 없음")
	_expect(int(validation_loss.get("gross_income", -1)) == 0 and int(validation_loss.get("net_income", -1)) == 0 and int(validation_loss.get("state", {}).get("build_points", -1)) == 10, "검증선 패배 salvage 0·retry 파밍 없음")
	_expect(float(victory.get("state", {}).get("metrics", {}).get("secondary_objectives_lost", 0.0)) == 1.0, "경제 결산에 보조 목표 손실 기록")


func _test_command_and_wave_integration() -> void:
	var settings_rows: Array[Dictionary] = []
	for profile_id in ["v20_story", "v20_tactician", "v20_overlord"]:
		var settings := EconomyService.command_settings(_profile(profile_id))
		settings_rows.append(settings)
		var state := CommandService.new_state(DataRegistry.v20_commands, int(settings.get("max_points", 0)), int(settings.get("initial_points", 0)), float(settings.get("recharge_seconds", 0.0)))
		_expect(int(state.get("points", -1)) == int(settings.get("initial_points", -2)) and float(state.get("recharge_seconds", 0.0)) == float(settings.get("recharge_seconds", -1.0)), "%s 명령 자원 초기화" % profile_id)
	_expect(int(settings_rows[0].get("initial_points", 0)) > int(settings_rows[2].get("initial_points", 0)) and float(settings_rows[0].get("recharge_seconds", 99.0)) < float(settings_rows[2].get("recharge_seconds", 0.0)), "난이도 상승 시 명령 자원 선택 압박 증가")
	var hard_encounter := EconomyService.configured_encounter(EncounterService.encounter_for_day(5, DataRegistry.v20_encounters), _profile("v20_overlord"))
	var wave_catalog := EncounterService.wave_catalog_for_encounter(hard_encounter, _board(), _context())
	var entries: Array = wave_catalog.get("day_5", [])
	_expect(entries.size() == 6 and entries.all(func(entry): return float(entry.get("hp_scale", 0.0)) <= 1.35), "DAY 5 설정 난이도 6개 spawn이 WaveManager adapter에 전달")
	_expect(entries.any(func(entry): return is_equal_approx(float(entry.get("hp_scale", 0.0)), 1.21)), "마왕 HP 5% 보정이 spawn 단위에 적용")
	_expect("어려움" in EconomyService.management_summary(_profile("v20_overlord")) and "건설 8" in EconomyService.management_summary(_profile("v20_overlord")) and "명령 2/3" in EconomyService.management_summary(_profile("v20_overlord")), "관리 HUD 난이도·자원 요약")


func _capture_management_hud() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var hud = HUDScene.instantiate()
	viewport.add_child(hud)
	var difficulty := _profile("v20_overlord")
	var settings := EconomyService.command_settings(difficulty)
	hud.setup("management", {
		"day": 5,
		"intrusion_title": "전열 돌파와 2단계 변화",
		"intrusion_hint": "%s · 목표·경로 확인 후 방어선 선택" % EconomyService.management_summary(difficulty),
		"resources": {"build": 8, "command": int(settings.get("initial_points", 2)), "command_max": int(settings.get("max_points", 3))},
		"board_hint": "방·문·경로를 지도에서 직접 선택",
		"drawer_open": false
	})
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var path := "user://v20_phase9_difficulty_economy_1280x720.png"
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_expect(error == OK, "Phase 9 난이도·경제 HUD 1280x720 실제 렌더")
	if error == OK:
		print("V20_PHASE9_CAPTURE: %s" % ProjectSettings.globalize_path(path))
	viewport.queue_free()
	await get_tree().process_frame


func _profile(profile_id: String) -> Dictionary:
	return EconomyService.profile(DataRegistry.v20_economy, profile_id)


func _board() -> Dictionary:
	return DataRegistry.v20_dungeon_layouts.get("v20_day_01_05_board", {}).duplicate(true)


func _context() -> Dictionary:
	return {"seed": 905, "facilities": [{"id": "primary", "facility_id": "v20_barricade", "node_id": "gate_outpost", "active": true}], "door_state_costs": {}, "facility_route_costs": {}, "temporary_hazard_costs": {}}


func _spawn_times(schedule: Array) -> Array[float]:
	var result: Array[float] = []
	for row_value in schedule:
		result.append(float(row_value.get("time", 0.0)))
	return result


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20DifficultyEconomy] FAIL: %s" % message)
