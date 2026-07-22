extends Node

const OnboardingService = preload("res://scripts/v20/onboarding/V20OnboardingService.gd")
const SessionService = preload("res://scripts/v20/session/V20SessionService.gd")
const SaveStore = preload("res://scripts/v20/save/V20SaveStore.gd")
const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

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
	var session := SessionService.new_session("v20_overlord", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
	var placement: Dictionary = session.get("placement_state", {})
	var rooms: Dictionary = placement.get("rooms", {})
	_expect(rooms.keys().size() == 4 and rooms.has("gate_outpost") and rooms.has("spike_corridor") and rooms.has("central_battle_room") and rooms.has("throne_anteroom"), "새 세션이 canonical 방어 구역 4개만 생성")
	_expect(str(rooms.get("gate_outpost", {}).get("facility_slot_id", "")) == "gate_outpost_facility" and rooms.get("gate_outpost", {}).get("monster_slot_ids", []) == ["gate_outpost_monster_1", "gate_outpost_monster_2"], "gate_outpost의 시설 1·몬스터 2 슬롯 ID 고정")
	_expect(str(placement.get("roster", {}).get("slime", {}).get("monster_slot_id", "")) == "gate_outpost_monster_1" and str(placement.get("roster", {}).get("goblin", {}).get("monster_slot_id", "")) == "central_battle_room_monster_1", "초기 slime·goblin 슬롯 자동 할당")

	var installed := PlacementService.place_facility_drag(placement, "v20_barricade", "gate_outpost", DataRegistry.v20_facilities)
	placement = installed.get("state", {})
	placement = PlacementService.place_monster_drag(placement, "goblin", "spike_corridor").get("state", {})
	session = SessionService.record_placement(session, placement, installed, DataRegistry.v20_onboarding)
	session = SessionService.begin_combat(session)
	var loss := {"win": false, "lines": [], "metrics": {"combat_time": 48.0, "alive_monsters": 1, "total_monsters": 3, "demon_lord_hp": 0, "treasure_gold_stolen": 0, "facility_disables": 0}}
	session = SessionService.finalize_battle(session, loss, DataRegistry.v20_economy).get("state", {})
	session = SessionService.retry(session)
	_expect(str(session.get("placement_state", {}).get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "v20_barricade", "패배 재도전 뒤 gate_outpost 시설 보존")
	_expect(str(session.get("placement_state", {}).get("roster", {}).get("goblin", {}).get("room_id", "")) == "spike_corridor" and str(session.get("placement_state", {}).get("roster", {}).get("goblin", {}).get("monster_slot_id", "")) == "spike_corridor_monster_1", "패배 재도전 뒤 goblin 방·슬롯 보존")
	var win := {"win": true, "lines": [], "metrics": {"combat_time": 52.0, "alive_monsters": 3, "total_monsters": 3, "demon_lord_hp": 1300, "treasure_gold_stolen": 0, "facility_disables": 0}}
	session = SessionService.finalize_battle(SessionService.begin_combat(session), win, DataRegistry.v20_economy).get("state", {})
	session = SessionService.advance_after_win(session)
	_expect(int(session.get("day", 0)) == 2 and str(session.get("status", "")) == "management", "승리 뒤 DAY 1→2 및 관리 단계 전환")


func _test_v3_save_round_trip() -> void:
	var path := "user://tests/v20_onboarding_retry_save_v3.json"
	SaveStore.delete(path)
	var session := SessionService.new_session("v20_tactician", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
	var payload := SessionService.save_payload(session)
	var summary := {"day": 1, "difficulty_id": "v20_tactician", "difficulty_name": "test", "checkpoint": "management", "completed": false}
	var written := SaveStore.write(payload, summary, path)
	var inspected := SaveStore.inspect(path)
	_expect(bool(written.get("ok", false)) and str(inspected.get("status", "")) == SaveStore.STATUS_VALID and int(inspected.get("migration_count", -1)) == 0, "schema 3 v2.0 저장을 migration 없이 검사")
	var restored := SessionService.restore(inspected.get("payload", {}), DataRegistry.v20_economy)
	_expect(bool(restored.get("ok", false)) and str(restored.get("state", {}).get("placement_state", {}).get("roster", {}).get("imp", {}).get("monster_slot_id", "")) == "throne_anteroom_monster_1", "schema 3 복원 후 imp canonical 슬롯 유지")
	SaveStore.delete(path)


func _test_game_root_entry_gate() -> void:
	var path := "user://tests/v20_onboarding_game_root.json"
	SaveStore.delete(path)
	var game_root = GameRootScene.instantiate()
	game_root._v20_set_save_path_for_tests(path)
	add_child(game_root)
	await get_tree().process_frame
	await get_tree().process_frame
	game_root._v20_start_new_session("v20_tactician")
	await get_tree().process_frame
	_expect(game_root.quarter_layout_id == DataRegistry.V20_RUNTIME_LAYOUT_ID and bool(game_root.graph.validation_summary().get("ok", false)), "실제 GameRoot가 v20_day_01_05_spatial ModuleGraph 로드")
	_expect(game_root.graph.canonical_zone_ids() == ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom", "throne"], "실제 전투 그래프 canonical 구역 순서 일치")
	_expect(game_root.graph.path_between("gate_outpost", "throne").has("central_battle_room") and game_root.graph.path_between("gate_outpost", "throne").has("throne_anteroom"), "실제 이동 그래프가 중앙 전투실과 왕좌 전실을 통과")
	game_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(path)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20OnboardingRetrySave] FAIL: %s" % message)
