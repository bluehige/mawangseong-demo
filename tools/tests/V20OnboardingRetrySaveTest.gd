extends Node

const OnboardingService = preload("res://scripts/v20/onboarding/V20OnboardingService.gd")
const SessionService = preload("res://scripts/v20/session/V20SessionService.gd")
const SaveStore = preload("res://scripts/v20/save/V20SaveStore.gd")
const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const Constants = preload("res://scripts/core/Constants.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_onboarding_contract()
	_test_session_retry_and_day_flow()
	_test_v3_save_round_trip()
	await _test_game_root_entry_gate()
	if failed:
		print("V20_ONBOARDING_RETRY_SAVE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_ONBOARDING_RETRY_SAVE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_onboarding_contract() -> void:
	var validation := OnboardingService.validate_config(DataRegistry.v20_onboarding)
	_expect(bool(validation.get("ok", false)), "초회 사용자 90초 config 검증: %s" % [validation.get("errors", [])])
	var state := OnboardingService.new_state(DataRegistry.v20_onboarding)
	state = OnboardingService.advance(state, 74.0, "management")
	var recorded := OnboardingService.record_action(state, DataRegistry.v20_onboarding, "facility_installed", {"facility_id": "v20_barricade", "room_id": "gate_outpost"})
	state = OnboardingService.complete_day_one(recorded.get("state", {}))
	var evaluation := OnboardingService.evaluation(state)
	_expect(bool(recorded.get("accepted", false)) and bool(evaluation.get("within_90_seconds", false)), "74초 시설 설치를 첫 의미 있는 선택으로 기록")
	_expect(bool(evaluation.get("internal_observation_ready", false)), "DAY 1 완료·외부 도움 0·90초 이내 선택이면 내부 관찰 기준 충족")
	var late := OnboardingService.new_state(DataRegistry.v20_onboarding)
	late = OnboardingService.advance(late, 91.0, "management")
	late = OnboardingService.complete_day_one(OnboardingService.record_action(late, DataRegistry.v20_onboarding, "monster_placed", {"room_id": "spike_corridor"}).get("state", {}))
	_expect(not bool(OnboardingService.evaluation(late).get("internal_observation_ready", true)), "91초 첫 선택은 90초 기준 미달")


func _test_session_retry_and_day_flow() -> void:
	var session := SessionService.new_session("v20_tactician", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
	var placement: Dictionary = session.get("placement_state", {})
	var rooms: Dictionary = placement.get("rooms", {})
	_expect(rooms.keys().size() == 4 and rooms.has("gate_outpost") and rooms.has("spike_corridor") and rooms.has("central_battle_room") and rooms.has("throne_anteroom"), "새 세션이 canonical 방어 구역 4개만 생성")
	_expect(str(rooms.get("gate_outpost", {}).get("facility_slot_id", "")) == "gate_outpost_facility" and rooms.get("gate_outpost", {}).get("monster_slot_ids", []) == ["gate_outpost_monster_1", "gate_outpost_monster_2"], "gate_outpost의 시설 1·몬스터 2 슬롯 ID 고정")
	_expect(str(placement.get("roster", {}).get("slime", {}).get("monster_slot_id", "")) == "gate_outpost_monster_1" and str(placement.get("roster", {}).get("goblin", {}).get("monster_slot_id", "")) == "central_battle_room_monster_1", "초기 slime·goblin 슬롯 자동 할당")

	_expect(str(session.get("flow_state", "")) == "INTRUSION_BRIEF", "새 세션은 침입 확인부터 시작")
	session = SessionService.begin_placement(session).get("state", {})
	var installed := PlacementService.place_facility_drag(placement, "v20_barricade", "gate_outpost", DataRegistry.v20_facilities)
	placement = installed.get("state", {})
	placement = PlacementService.place_monster_drag(placement, "goblin", "spike_corridor").get("state", {})
	session = SessionService.record_placement(session, placement, installed, DataRegistry.v20_onboarding)
	var runtime := {
		"monsters": {"slime": {"hp": 180, "mana": 0}, "goblin": {"hp": 140, "mana": 0}, "imp": {"hp": 120, "mana": 0}},
		"command": {"points": 3, "recharge_progress": 0.0, "cooldowns": {}},
		"facilities": {"gate_outpost": {"charges": 1, "active_seconds": 0.0, "disabled_seconds": 0.0}}
	}
	var defense := SessionService.begin_defense_start(session, DataRegistry.v20_facilities, runtime, 2001, 424242)
	_expect(bool(defense.get("ok", false)) and str(defense.get("state", {}).get("flow_state", "")) == "DEFENSE_START", "배치 snapshot 뒤 방어 시작 상태 진입")
	session = SessionService.advance_defense_countdown(defense.get("state", {}), 3.0)
	session = SessionService.begin_combat(session).get("state", {})
	var loss := {"win": false, "lines": [], "metrics": {"combat_time": 48.0, "alive_monsters": 1, "total_monsters": 3, "demon_lord_hp": 0, "treasure_gold_stolen": 0, "facility_disables": 0}}
	session = SessionService.finalize_battle(session, loss, DataRegistry.v20_economy).get("state", {})
	var retried := SessionService.retry(session, "edit", DataRegistry.v20_facilities)
	_expect(bool(retried.get("ok", false)), "패배 뒤 배치 수정 재도전 허용")
	session = retried.get("state", {})
	_expect(str(session.get("placement_state", {}).get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "v20_barricade", "패배 재도전 뒤 gate_outpost 시설 보존")
	_expect(str(session.get("placement_state", {}).get("roster", {}).get("goblin", {}).get("room_id", "")) == "spike_corridor" and str(session.get("placement_state", {}).get("roster", {}).get("goblin", {}).get("monster_slot_id", "")) == "spike_corridor_monster_1", "패배 재도전 뒤 goblin 방·슬롯 보존")
	_expect(session.get("runtime_state", {}) == runtime and int(session.get("encounter_seed", 0)) == 2001 and int(session.get("rng_state", 0)) == 424242, "패배 재도전 뒤 전투 직전 자원·seed·RNG 복원")
	var win := {"win": true, "lines": [], "metrics": {"combat_time": 52.0, "alive_monsters": 3, "total_monsters": 3, "demon_lord_hp": 1300, "treasure_gold_stolen": 0, "facility_disables": 0}}
	defense = SessionService.begin_defense_start(session, DataRegistry.v20_facilities, runtime, 2001, 424242)
	session = SessionService.advance_defense_countdown(defense.get("state", {}), 3.0)
	session = SessionService.begin_combat(session).get("state", {})
	session = SessionService.finalize_battle(session, win, DataRegistry.v20_economy).get("state", {})
	var advanced := SessionService.advance_after_win(session, DataRegistry.v20_facilities, DataRegistry.monsters, DataRegistry.v20_commands)
	_expect(bool(advanced.get("ok", false)), "승리 뒤 다음 DAY 전이 허용")
	session = advanced.get("state", {})
	_expect(int(session.get("day", 0)) == 2 and str(session.get("flow_state", "")) == "INTRUSION_BRIEF", "승리 뒤 DAY 1→2 침입 확인 전환")
	_expect(int(session.get("runtime_state", {}).get("command", {}).get("points", 0)) == 3 and float(session.get("runtime_state", {}).get("command", {}).get("recharge_progress", -1.0)) == 0.0, "새 DAY 명령 3/3·충전 진행 0")


func _test_v3_save_round_trip() -> void:
	var path := "user://tests/v20_onboarding_retry_save_v3.json"
	SaveStore.delete(path)
	var session := SessionService.new_session("v20_tactician", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
	session = SessionService.begin_placement(session).get("state", {})
	var runtime := {"monsters": {"slime": {"hp": 180, "mana": 0}}, "command": {"points": 3}, "facilities": {"gate_outpost": {"charges": 1}}}
	var defense := SessionService.begin_defense_start(session, DataRegistry.v20_facilities, runtime, 2001, 123456)
	session = defense.get("state", {})
	var payload := SessionService.save_payload(session)
	var summary := {"day": 1, "difficulty_id": "v20_tactician", "difficulty_name": "test", "checkpoint": "defense_start", "completed": false}
	var written := SaveStore.write(payload, summary, path)
	var inspected := SaveStore.inspect(path)
	_expect(bool(written.get("ok", false)) and str(inspected.get("status", "")) == SaveStore.STATUS_VALID and int(inspected.get("migration_count", -1)) == 0, "schema 3 v2.0 저장을 migration 없이 검사")
	var restored := SessionService.restore(inspected.get("payload", {}), DataRegistry.v20_economy)
	_expect(bool(restored.get("ok", false)) and str(restored.get("state", {}).get("placement_state", {}).get("roster", {}).get("imp", {}).get("monster_slot_id", "")) == "throne_anteroom_monster_1", "schema 3 복원 후 imp canonical 슬롯 유지")
	var restored_state: Dictionary = restored.get("state", {})
	var restored_runtime: Dictionary = restored_state.get("runtime_state", {})
	_expect(str(restored_state.get("flow_state", "")) == "DEFENSE_START", "종료·이어하기 뒤 DEFENSE_START 상태 유지")
	_expect(int(restored_runtime.get("monsters", {}).get("slime", {}).get("hp", 0)) == 180 and int(restored_runtime.get("monsters", {}).get("slime", {}).get("mana", -1)) == 0, "종료·이어하기 전후 slime HP 180·mana 0 일치")
	_expect(int(restored_runtime.get("command", {}).get("points", 0)) == 3 and int(restored_runtime.get("facilities", {}).get("gate_outpost", {}).get("charges", 0)) == 1, "종료·이어하기 전후 command 3·facility charge 1 일치")
	_expect(int(restored_state.get("encounter_seed", 0)) == 2001 and int(restored_state.get("rng_state", 0)) == 123456, "종료·이어하기 전후 seed 2001·RNG 123456 일치")
	SaveStore.delete(path)


func _test_game_root_entry_gate() -> void:
	get_window().size = Vector2i(1280, 720)
	var web_path := "user://tests/v20_onboarding_game_root_web.json"
	var web_root = await _acceptance_root_to_combat(web_path, [], "?v20_acceptance=1&v20_seed_map=1%3A2001%2C2%3A2002%2C3%3A2003%2C4%3A2004%2C5%3A2005&v20_scenario=FREE", "web", false)
	_expect(str(web_root._v20_flow_state()) == "COMBAT" and int(web_root.wave_manager.get_meta("v20_seed", 0)) == 2001, "실제 Web query GameRoot가 DAY 1 COMBAT에 seed 2001 전달")
	web_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(web_path)

	var windows_path := "user://tests/v20_onboarding_game_root_windows.json"
	var windows_root = await _acceptance_root_to_combat(windows_path, ["--v20-acceptance", "--v20-seed-map=1:2001,2:2002,3:2003,4:2004,5:2005", "--v20-scenario=FREE"], "", "windows", true)
	_expect(int(windows_root.wave_manager.get_meta("v20_seed", 0)) == 2001, "실제 Windows args GameRoot가 첫 전투 frame 전에 seed 2001 전달")
	_expect(int(windows_root.wave_manager.get_meta("v20_rng_state", 0)) == int(windows_root.v20_session.get("rng_state", -1)), "실제 Windows args GameRoot가 첫 전투 frame 전에 RNG state 전달")
	_expect(windows_root.quarter_layout_id == DataRegistry.V20_RUNTIME_LAYOUT_ID and bool(windows_root.graph.validation_summary().get("ok", false)), "실제 GameRoot가 v20_day_01_05_spatial ModuleGraph 로드")
	_expect(windows_root.graph.canonical_zone_ids() == ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom", "throne"], "실제 전투 그래프 canonical 구역 순서 일치")
	_expect(windows_root.graph.path_between("gate_outpost", "throne").has("central_battle_room") and windows_root.graph.path_between("gate_outpost", "throne").has("throne_anteroom"), "실제 이동 그래프가 중앙 전투실과 왕좌 전실을 통과")

	var exp_before := int(windows_root.monster_roster.get("slime", {}).get("exp", -1))
	windows_root.combat_scene.spawn_enemy("explorer")
	var defeated_enemy = windows_root.enemy_units.back()
	defeated_enemy.hp = 0
	defeated_enemy.down = true
	windows_root.combat_scene.on_unit_downed(defeated_enemy)
	_expect(int(windows_root.monster_roster.get("slime", {}).get("exp", -2)) == exp_before, "v2.0 실제 적 처치가 몬스터 EXP를 올리지 않음")
	windows_root.combat_scene.finish_combat(false, "테스트 패배")
	await get_tree().process_frame
	_expect(str(windows_root._v20_flow_state()) == "RESULT" and windows_root.current_screen == Constants.SCREEN_RESULT, "실제 전투 종료가 다섯 번째 상태 RESULT에 도달")
	var edit_button: Button = windows_root.ui_layer.find_child("V20RetryEditButton", true, false)
	var same_button: Button = windows_root.ui_layer.find_child("V20RetrySameButton", true, false)
	_expect(edit_button != null and same_button != null, "패배 RESULT에 배치 수정·같은 배치 재도전 두 버튼 노출")
	_expect(GameState.mana > 320, "전투 종료 시점 mana가 snapshot 값과 다른 상태를 실제로 만듦")
	if edit_button != null:
		edit_button.pressed.emit()
	await get_tree().process_frame
	_expect(str(windows_root._v20_flow_state()) == "PLACEMENT", "실제 RESULT 배치 수정 클릭이 PLACEMENT로 복귀")
	_expect(GameState.demon_lord_hp == 1500 and GameState.mana == 320, "패배 재도전이 실제 HP 1500·mana 320 snapshot을 복원")
	_expect(int(windows_root.monster_roster.get("slime", {}).get("level", 0)) == 1 and int(windows_root.monster_roster.get("slime", {}).get("exp", -1)) == 0, "패배 재도전이 실제 roster level 1·EXP 0을 복원")
	windows_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(windows_path)


func _acceptance_root_to_combat(path: String, user_args: Array, web_query: String, expected_source: String, exercise_guards: bool):
	SaveStore.delete(path)
	var game_root = GameRootScene.instantiate()
	game_root._v20_set_save_path_for_tests(path)
	add_child(game_root)
	await get_tree().process_frame
	await get_tree().process_frame
	var acceptance: Dictionary = game_root._v20_configure_acceptance_sources_for_tests(user_args, web_query, true)
	_expect(bool(acceptance.get("ok", false)) and str(acceptance.get("source", "")) == expected_source and str(acceptance.get("placement_fingerprint", "x")) == "", "실제 GameRoot %s acceptance FREE 입력·빈 배치 fingerprint" % expected_source)
	game_root._v20_start_new_session("v20_tactician")
	await get_tree().process_frame
	_expect(str(game_root._v20_flow_state()) == "INTRUSION_BRIEF", "실제 GameRoot가 침입 확인 화면부터 시작")
	var begin_button: Button = game_root.ui_layer.find_child("V20PrimaryActionButton", true, false)
	_expect(begin_button != null and begin_button.text.begins_with("배치 시작"), "1280×720 침입 확인에 배치 시작 버튼 1개 노출")
	if begin_button != null:
		begin_button.pressed.emit()
	await get_tree().process_frame
	_expect(str(game_root._v20_flow_state()) == "PLACEMENT", "실제 버튼 입력으로 INTRUSION_BRIEF → PLACEMENT")
	if exercise_guards:
		_expect(not game_root._v20_start_placement(), "연타로 PLACEMENT 상태를 건너뛰지 못함")
	var start_button: Button = game_root.ui_layer.find_child("V20PrimaryActionButton", true, false)
	_expect(start_button != null and not start_button.disabled and start_button.text.begins_with("방어 시작"), "유효 초기 배치에서 방어 시작 버튼 활성")
	if start_button != null:
		start_button.pressed.emit()
	await get_tree().process_frame
	_expect(str(game_root._v20_flow_state()) == "DEFENSE_START" and game_root.current_screen == Constants.SCREEN_MANAGEMENT, "실제 버튼 입력으로 snapshot 뒤 DEFENSE_START, COMBAT 즉시 건너뛰지 않음")
	if exercise_guards:
		_expect(not game_root._v20_request_defense_start(), "방어 시작 연타로 COMBAT을 건너뛰지 못함")
		var cancel_button: Button = game_root.ui_layer.find_child("V20CancelDefenseButton", true, false)
		_expect(cancel_button != null, "3초 countdown에 취소 버튼 노출")
		if cancel_button != null:
			cancel_button.pressed.emit()
		await get_tree().process_frame
		_expect(str(game_root._v20_flow_state()) == "PLACEMENT", "countdown 취소는 PLACEMENT로만 복귀")
		_expect(not game_root._v20_cancel_defense_start(), "PLACEMENT에서 뒤로가기 성격의 취소가 상태를 건너뛰지 못함")
		game_root._v20_request_defense_start()
	game_root._v20_advance_defense_countdown(2.9)
	_expect(str(game_root._v20_flow_state()) == "DEFENSE_START", "countdown 2.9초에는 DEFENSE_START 유지")
	game_root._v20_advance_defense_countdown(0.1)
	_expect(str(game_root._v20_flow_state()) == "COMBAT", "countdown 누적 3.0초 뒤 COMBAT 진입")
	return game_root


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20OnboardingRetrySave] FAIL: %s" % message)
