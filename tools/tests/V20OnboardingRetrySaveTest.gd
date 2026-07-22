extends Node

const OnboardingService = preload("res://scripts/v20/onboarding/V20OnboardingService.gd")
const SessionService = preload("res://scripts/v20/session/V20SessionService.gd")
const SaveStore = preload("res://scripts/v20/save/V20SaveStore.gd")
const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const FacilityService = preload("res://scripts/v20/facilities/V20FacilityService.gd")
const TitlePanelScene = preload("res://scenes/v20/ui/V20TitleEntryPanel.tscn")
const ResultScreenScene = preload("res://scenes/v20/ui/V20ResultScreen.tscn")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false
var assertion_count := 0
var emitted_profile := ""
var result_action := ""


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_onboarding_contract()
	_test_session_retry_and_day_flow()
	_test_save_isolation()
	await _test_entry_and_result_ui()
	await _test_v20_no_decoy_thief_terminal()
	await _test_v20_sequential_defense_checkpoints()
	await _test_game_root_entry_gate()
	if OS.get_cmdline_user_args().has("--capture-v20-onboarding") and DisplayServer.get_name() != "headless":
		await _capture_entry_and_result()
	await get_tree().create_timer(0.1).timeout
	await get_tree().process_frame
	if failed:
		print("V20_ONBOARDING_RETRY_SAVE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_ONBOARDING_RETRY_SAVE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_onboarding_contract() -> void:
	var validation := OnboardingService.validate_config(DataRegistry.v20_onboarding)
	_expect(bool(validation.get("ok", false)), "90초 온보딩 config 승인: %s" % [validation.get("errors", [])])
	var state := OnboardingService.new_state(DataRegistry.v20_onboarding)
	_expect("첫 결정" in OnboardingService.guidance(state, DataRegistry.v20_onboarding), "시작 즉시 첫 결정 한 줄 안내")
	state = OnboardingService.advance(state, 35.0, "management")
	_expect("드래그가 어렵다면" in OnboardingService.guidance(state, DataRegistry.v20_onboarding), "30초 뒤 클릭 대체 입력 안내")
	state = OnboardingService.advance(state, 39.0, "management")
	var recorded := OnboardingService.record_action(state, DataRegistry.v20_onboarding, "facility_installed", {"facility_id": "v20_barricade"})
	state = recorded.get("state", {})
	_expect(bool(recorded.get("accepted", false)) and bool(state.get("first_meaningful_choice", {}).get("within_90_seconds", false)), "74초 첫 의미 있는 선택 기록")
	state = OnboardingService.complete_day_one(state)
	_expect(bool(OnboardingService.evaluation(state).get("internal_observation_ready", false)), "90초 선택·외부 도움 없음·DAY 1 완료 내부 관찰 기준")
	var late := OnboardingService.new_state(DataRegistry.v20_onboarding)
	late = OnboardingService.advance(late, 91.0, "management")
	late = OnboardingService.record_action(late, DataRegistry.v20_onboarding, "monster_placed").get("state", {})
	late = OnboardingService.complete_day_one(late)
	_expect(not bool(OnboardingService.evaluation(late).get("internal_observation_ready", true)), "91초 첫 선택은 기준 미달")
	state = OnboardingService.record_external_help(state)
	_expect(not bool(OnboardingService.evaluation(state).get("without_external_help", true)), "외부 설명 사용은 별도 기록")


func _test_session_retry_and_day_flow() -> void:
	var session := SessionService.new_session("v20_overlord", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
	_expect(int(session.get("day", 0)) == 1 and int(session.get("placement_state", {}).get("build_points", 0)) == 8, "어려움 DAY 1 세션·건설 예산 초기화")
	var section_rooms: Dictionary = session.get("placement_state", {}).get("rooms", {})
	_expect(
		str(section_rooms.get("north_gate", {}).get("display_name", "")).begins_with("1 · 성문 전초")
		and str(section_rooms.get("south_gate", {}).get("runtime_room_id", "")) == "spike_corridor"
		and str(section_rooms.get("treasure", {}).get("runtime_room_id", "")) == "barracks"
		and str(section_rooms.get("fallback", {}).get("runtime_room_id", "")) == "fallback",
		"저장 ID는 유지하고 4개 고정 구간을 실제 전투 공간과 1:1 연결"
	)
	var placement: Dictionary = session.get("placement_state", {})
	placement = PlacementService.select_slot(placement, "north_gate").get("state", {})
	var installed := PlacementService.choose_facility(placement, "v20_barricade", DataRegistry.v20_facilities)
	placement = installed.get("state", {})
	session = SessionService.record_placement(session, placement, installed, DataRegistry.v20_onboarding)
	_expect(str(session.get("placement_state", {}).get("rooms", {}).get("north_gate", {}).get("facility_id", "")) == "v20_barricade" and int(session.get("economy", {}).get("build_points", 0)) == 5, "배치와 경제 잔액 단일 상태로 동기화")
	_expect(str(session.get("onboarding", {}).get("first_meaningful_choice", {}).get("action_id", "")) == "facility_installed", "시설 설치가 첫 의미 있는 선택")
	var serialized_before := PlacementService.serialize(session.get("placement_state", {}))
	session = SessionService.begin_combat(session)
	_expect(session.get("retry_snapshot", {}).get("placement_state", {}) == serialized_before, "전투 직전 배치 스냅샷")
	var loss := {"win": false, "lines": [], "metrics": {"combat_time": 48.0, "alive_monsters": 1, "total_monsters": 3, "demon_lord_hp": 0, "treasure_gold_stolen": 0, "facility_disables": 0, "v20_command_points_spent": 2}}
	var finalized := SessionService.finalize_battle(session, loss, DataRegistry.v20_economy)
	session = finalized.get("state", {})
	_expect("왕좌 피해" in str(finalized.get("result", {}).get("v20", {}).get("cause", "")), "패배 원인 한 줄 분류")
	_expect(str(finalized.get("result", {}).get("v20", {}).get("highlight", "")) != "", "결산의 잘한 대응 한 줄 분류")
	_expect("후퇴선" in str(finalized.get("result", {}).get("v20", {}).get("guidance", "")), "원인에 대응하는 수정 후보 한 줄")
	session = SessionService.retry(session)
	_expect(PlacementService.serialize(session.get("placement_state", {})).get("rooms", {}) == serialized_before.get("rooms", {}), "재도전 시설·몬스터 배치 보존")
	_expect(int(session.get("onboarding", {}).get("retry_count", 0)) == 1 and str(session.get("status", "")) == "management", "재도전 횟수·관리 복귀 기록")
	var win_session := SessionService.new_session("v20_tactician", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
	win_session = SessionService.begin_combat(win_session)
	var win := {"win": true, "lines": [], "metrics": {"combat_time": 52.0, "alive_monsters": 3, "total_monsters": 3, "demon_lord_hp": 1300, "treasure_gold_stolen": 0, "facility_disables": 0}}
	win_session = SessionService.finalize_battle(win_session, win, DataRegistry.v20_economy).get("state", {})
	_expect(bool(win_session.get("onboarding", {}).get("day_one_completed", false)), "DAY 1 성공 시 내부 관찰 완료 기록")
	win_session = SessionService.advance_after_win(win_session)
	_expect(int(win_session.get("day", 0)) == 2 and str(win_session.get("status", "")) == "management", "승리 뒤 DAY 2 관리로 진행")
	win_session["day"] = 5
	win_session["last_result"] = win
	win_session = SessionService.advance_after_win(win_session)
	_expect(bool(win_session.get("completed", false)) and str(win_session.get("status", "")) == "completed", "DAY 5 성공 뒤 버티컬 슬라이스 완료")


func _test_save_isolation() -> void:
	var token := str(Time.get_ticks_usec())
	var v20_path := "user://v20_test_%s/campaign_v20.json" % token
	var legacy_path := "user://v20_test_%s/campaign_save_v1.json" % token
	_write_text(legacy_path, "LEGACY_SENTINEL")
	var session := SessionService.new_session("v20_story", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
	var payload := SessionService.save_payload(session)
	var summary := {"day": 1, "difficulty_id": "v20_story", "difficulty_name": "쉬움", "checkpoint": "test", "completed": false}
	var write_result := SaveStore.write(payload, summary, v20_path)
	_expect(bool(write_result.get("ok", false)), "2.0 전용 경로 atomic 저장")
	var inspection := SaveStore.inspect(v20_path)
	_expect(str(inspection.get("status", "")) == SaveStore.STATUS_VALID and int(inspection.get("summary", {}).get("day", 0)) == 1, "2.0 저장 재검증·요약")
	var restored := SessionService.restore(inspection.get("payload", {}), DataRegistry.v20_economy)
	_expect(bool(restored.get("ok", false)) and str(restored.get("state", {}).get("difficulty_id", "")) == "v20_story", "2.0 session 저장 왕복")
	var legacy_payload: Dictionary = inspection.get("payload", {}).duplicate(true)
	legacy_payload["placement"]["rooms"]["north_gate"]["display_name"] = "북문 길목"
	legacy_payload["placement"]["rooms"]["south_gate"]["display_name"] = "남문 길목"
	var migrated := SessionService.restore(legacy_payload, DataRegistry.v20_economy)
	_expect(bool(migrated.get("ok", false)) and str(migrated.get("state", {}).get("placement_state", {}).get("rooms", {}).get("north_gate", {}).get("display_name", "")).begins_with("1 · 성문 전초"), "기존 schema 2 저장을 새 고정 구간 이름으로 안전 정규화")
	_expect(_read_text(legacy_path) == "LEGACY_SENTINEL", "2.0 저장 중 1.2 sentinel 무변경")
	_expect(SaveStore.SAVE_PATH == "user://v20/campaign_v20.json" and SaveStore.SAVE_PATH != "user://campaign_save_v1.json", "제품 2.0 namespace가 1.2 저장과 분리")
	SaveStore.delete(v20_path)
	_remove_file(legacy_path)
	_remove_empty_test_dir(v20_path.get_base_dir())


func _test_entry_and_result_ui() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var title_panel = TitlePanelScene.instantiate()
	title_panel.position = Vector2(820, 140)
	title_panel.size = Vector2(420, 300)
	host.add_child(title_panel)
	title_panel.new_session_requested.connect(func(profile_id: String): emitted_profile = profile_id)
	title_panel.setup("v20_tactician", {"status": "valid", "summary": {"day": 3}})
	await get_tree().process_frame
	var heading: Label = _find_named(title_panel, "DifficultyHeading") as Label
	var easy_button: Button = _find_named(title_panel, "Difficulty_v20_story") as Button
	var normal_button: Button = _find_named(title_panel, "Difficulty_v20_tactician") as Button
	var hard_button: Button = _find_named(title_panel, "Difficulty_v20_overlord") as Button
	_expect(heading != null and heading.text == "난이도 선택", "타이틀 2.0 선택 항목이 난이도임을 명시")
	_expect(easy_button != null and easy_button.text == "쉬움" and normal_button != null and normal_button.text == "보통" and hard_button != null and hard_button.text == "어려움", "난이도 세 선택을 쉬움·보통·어려움으로 표시")
	var normal_summary: Label = _find_named(title_panel, "DifficultySummary") as Label
	_expect(normal_summary != null and "건설 10" in normal_summary.text and "명령 3/3" in normal_summary.text and "목표 2" in normal_summary.text and "예고 표준" in normal_summary.text, "선택한 보통 난이도의 자원·목표·예고 요약")
	if hard_button != null:
		hard_button.pressed.emit()
	await get_tree().process_frame
	var hard_summary: Label = _find_named(title_panel, "DifficultySummary") as Label
	var hard_description: Label = _find_named(title_panel, "DifficultyDescription") as Label
	_expect(hard_summary != null and "건설 8" in hard_summary.text and "명령 2/3" in hard_summary.text and "목표 3" in hard_summary.text and "예고 25% 짧게" in hard_summary.text and hard_description != null and "세 목표" in hard_description.text, "선택 변경 즉시 어려움 자원·침입 압박 설명 갱신")
	var new_button: Button = _find_named(title_panel, "V20NewSessionButton") as Button
	if new_button != null:
		new_button.pressed.emit()
	_expect(emitted_profile == "v20_overlord", "선택 난이도로 2.0 새 세션 signal")
	var continue_button: Button = _find_named(title_panel, "V20ContinueButton") as Button
	_expect(continue_button != null and not continue_button.disabled and "DAY 3" in continue_button.text, "2.0 저장이 있을 때 이어하기 DAY 표시")
	var result_screen = ResultScreenScene.instantiate()
	host.add_child(result_screen)
	result_screen.action_requested.connect(func(action_id: String): result_action = action_id)
	result_screen.setup(_sample_loss_result(), 3)
	await get_tree().process_frame
	var result_button: Button = _find_named(result_screen, "V20ResultActionButton") as Button
	_expect(result_button != null and "같은 배치" in result_button.text, "패배 결산의 배치 보존 재도전 버튼")
	_expect(_find_named(result_screen, "ContributionLedger") != null and _find_named(result_screen, "RunSummary") != null, "원인 3카드 아래 기여도·수비 방식 결산")
	if result_button != null:
		result_button.pressed.emit()
	_expect(result_action == "retry", "재도전 action signal")
	host.queue_free()
	await get_tree().process_frame


func _test_v20_sequential_defense_checkpoints() -> void:
	var test_path := "user://v20_checkpoint_test_%s/campaign_v20.json" % str(Time.get_ticks_usec())
	var game_root = GameRootScene.instantiate()
	game_root.v20_save_path = test_path
	add_child(game_root)
	await get_tree().process_frame
	await get_tree().process_frame
	game_root._v20_start_new_session("v20_story")
	await get_tree().process_frame
	game_root._start_combat()
	await get_tree().process_frame
	var controller = game_root.combat_scene
	controller.spawn_enemy("explorer", {"v20_route_nodes": ["entrance", "north_gate", "north_cross", "south_gate", "south_cross", "treasure", "fallback", "throne"]})
	var enemy: Node = game_root.enemy_units[-1] if not game_root.enemy_units.is_empty() else null
	var expected_stages := ["entrance", "spike_corridor", "barracks", "fallback", "throne"]
	_expect(enemy != null and enemy.get_meta("v20_runtime_checkpoints", []) == expected_stages and str(enemy.goal_room) == "entrance" and str(enemy.get_meta("v20_checkpoint_final_goal", "")) == "throne", "적은 왕좌 직행 대신 입구부터 5개 방어 checkpoint로 시작")
	var defense_hud: Dictionary = controller.v20_defense_stage_hud_state()
	var defense_rows: Array = defense_hud.get("defense_stages", [])
	_expect(defense_rows.size() == 4 and bool(defense_rows[0].get("active", false)) and int(defense_rows[0].get("enemy_count", 0)) == 1 and "성문 전초" in str(defense_hud.get("active_stage_label", "")), "전투 HUD에 현재 성문 교전·적 수를 4단계 방어선으로 연결")
	controller._refresh_v20_command_hud(true)
	var active_stage_value: Label = controller.v20_hud.get_node_or_null("CoreObjective/ActiveStageValue") if controller.v20_hud != null else null
	_expect(active_stage_value != null and "성문 전초" in active_stage_value.text, "실제 전투 HUD 트리에도 현재 방어 구간을 즉시 갱신")
	if OS.get_cmdline_user_args().has("--capture-v20-defense-stages") and DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var capture := get_viewport().get_texture().get_image()
		var capture_path := "user://v20_phase11t_defense_stages_combat_1280x720.png"
		var capture_error := capture.save_png(capture_path) if capture != null and not capture.is_empty() else ERR_CANT_CREATE
		_expect(capture_error == OK, "4단계 방어선 실전 1280x720 실제 렌더")
		if capture_error == OK:
			print("V20_PHASE11T_COMBAT_CAPTURE: %s" % ProjectSettings.globalize_path(capture_path))
	if enemy != null:
		var slime: Node = game_root.monster_units.filter(func(unit): return str(unit.unit_id) == "slime").front()
		var goblin: Node = game_root.monster_units.filter(func(unit): return str(unit.unit_id) == "goblin").front()
		var imp: Node = game_root.monster_units.filter(func(unit): return str(unit.unit_id) == "imp").front()
		enemy.current_room = "entrance"
		enemy.global_position = game_root.graph.center("entrance")
		enemy.stop_navigation()
		controller.update_enemy_path(enemy)
		_expect(float(enemy.get_meta("v20_checkpoint_wait_remaining", 0.0)) < 0.0 and int(enemy.get_meta("v20_checkpoint_index", -1)) == 0, "입구 수비 몬스터가 살아 있으면 첫 방어선에서 교전")
		slime.hp = 0
		slime.down = true
		controller.update_enemy_path(enemy)
		_expect(is_equal_approx(float(enemy.get_meta("v20_checkpoint_wait_remaining", 0.0)), 1.25), "입구 수비 종료 뒤 1.25초 관문 돌파 시작")
		controller._advance_v20_checkpoint_waits(1.0)
		controller.update_enemy_path(enemy)
		_expect(int(enemy.get_meta("v20_checkpoint_index", -1)) == 0 and float(enemy.get_meta("v20_checkpoint_wait_remaining", 0.0)) > 0.0, "관문 돌파 시간이 남으면 다음 방으로 건너뛰지 않음")
		controller._advance_v20_checkpoint_waits(0.3)
		controller.update_enemy_path(enemy)
		_expect(int(enemy.get_meta("v20_checkpoint_index", -1)) == 1 and str(enemy.goal_room) == "spike_corridor", "입구 관문을 돌파한 뒤 가시 회랑으로 순차 진입")
		enemy.current_room = "spike_corridor"
		enemy.global_position = game_root.graph.center("spike_corridor")
		enemy.stop_navigation()
		controller.update_enemy_path(enemy)
		controller._advance_v20_checkpoint_waits(1.3)
		controller.update_enemy_path(enemy)
		_expect(int(enemy.get_meta("v20_checkpoint_index", -1)) == 2 and str(enemy.goal_room) == "barracks", "빈 가시 회랑도 관문 대기 후 중앙 전투실로 진입")
		enemy.current_room = "barracks"
		enemy.global_position = game_root.graph.center("barracks")
		enemy.stop_navigation()
		controller.update_enemy_path(enemy)
		_expect(float(enemy.get_meta("v20_checkpoint_wait_remaining", 0.0)) < 0.0 and goblin.is_alive(), "중앙 전투실 수비 몬스터를 쓰러뜨리기 전에는 전실로 진행하지 않음")
		goblin.hp = 0
		goblin.down = true
		controller.update_enemy_path(enemy)
		controller._advance_v20_checkpoint_waits(1.3)
		controller.update_enemy_path(enemy)
		_expect(int(enemy.get_meta("v20_checkpoint_index", -1)) == 3 and str(enemy.goal_room) == "fallback", "중앙 관문 돌파 뒤 독립된 왕좌 전실로 진입")
		enemy.current_room = "fallback"
		enemy.global_position = game_root.graph.center("fallback")
		enemy.stop_navigation()
		controller.update_enemy_path(enemy)
		_expect(float(enemy.get_meta("v20_checkpoint_wait_remaining", 0.0)) < 0.0 and imp.is_alive(), "왕좌 전실 수비 몬스터가 마지막 진입을 차단")
		imp.hp = 0
		imp.down = true
		controller.update_enemy_path(enemy)
		controller._advance_v20_checkpoint_waits(1.3)
		controller.update_enemy_path(enemy)
		_expect(int(enemy.get_meta("v20_checkpoint_index", -1)) == 4 and str(enemy.goal_room) == "throne", "전실 관문을 돌파해야 왕좌에 진입")
		enemy.current_room = "throne"
		enemy.global_position = game_root.graph.center("throne")
		enemy.stop_navigation()
		controller.update_enemy_path(enemy)
		var stage_rows: Array = controller.v20_defense_stage_snapshot().get("enemies", [])
		var enemy_rows: Array = stage_rows.filter(func(row): return int(row.get("instance_id", 0)) == enemy.get_instance_id())
		_expect(not enemy_rows.is_empty() and bool(enemy_rows[0].get("complete", false)) and str(enemy.goal_room) == "throne", "마지막 checkpoint 뒤 원래 최종 목표를 복원하고 상태 snapshot 제공")
	else:
		for message in ["입구 수비 몬스터가 살아 있으면 첫 방어선에서 교전", "입구 수비 종료 뒤 1.25초 관문 돌파 시작", "관문 돌파 시간이 남으면 다음 방으로 건너뛰지 않음", "입구 관문을 돌파한 뒤 가시 회랑으로 순차 진입", "빈 가시 회랑도 관문 대기 후 중앙 전투실로 진입", "중앙 전투실 수비 몬스터를 쓰러뜨리기 전에는 전실로 진행하지 않음", "중앙 관문 돌파 뒤 독립된 왕좌 전실로 진입", "왕좌 전실 수비 몬스터가 마지막 진입을 차단", "전실 관문을 돌파해야 왕좌에 진입", "마지막 checkpoint 뒤 원래 최종 목표를 복원하고 상태 snapshot 제공"]:
			_expect(false, message)
	game_root._kill_combat_music_tween()
	if game_root.combat_music_player != null and is_instance_valid(game_root.combat_music_player):
		game_root.combat_music_player.stop()
		game_root.combat_music_player.stream = null
		game_root.remove_child(game_root.combat_music_player)
		game_root.combat_music_player.free()
		game_root.combat_music_player = null
	game_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(test_path)
	_remove_empty_test_dir(test_path.get_base_dir())


func _test_game_root_entry_gate() -> void:
	var test_path := "user://v20_root_test_%s/campaign_v20.json" % str(Time.get_ticks_usec())
	var game_root = GameRootScene.instantiate()
	game_root.v20_save_path = test_path
	add_child(game_root)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(game_root.get_node_or_null("UILayer/V20EntryPanel") != null or _find_named(game_root, "V20EntryPanel") != null, "실제 타이틀에 2.0 진입 패널 연결")
	game_root._v20_start_new_session("v20_story")
	await get_tree().process_frame
	_expect(game_root._v20_vertical_slice_active() and game_root.current_screen == "management" and GameState.day == 1 and GameState.max_day == 5, "실제 GameRoot 2.0 gate·DAY 1 관리 진입")
	var runtime_route: Array = game_root.graph.path_between("entrance", "throne")
	_expect(game_root.quarter_layout_id == DataRegistry.V20_FIXED_RUNTIME_LAYOUT_ID and bool(game_root.graph.validation_summary().get("ok", false)) and runtime_route.has("spike_corridor") and runtime_route.has("barracks") and runtime_route.has("fallback") and runtime_route.find("spike_corridor") < runtime_route.find("barracks") and runtime_route.find("barracks") < runtime_route.find("fallback"), "실제 전투도 입구→가시 회랑→중앙 전투실→왕좌 전실→왕좌 고정 레이아웃 사용")
	_expect(str(game_root.monster_roster.get("slime", {}).get("room", "")) == "entrance" and str(game_root.monster_roster.get("goblin", {}).get("room", "")) == "barracks" and str(game_root.monster_roster.get("imp", {}).get("room", "")) == "fallback", "세 몬스터의 고정 포지션이 서로 다른 실제 전투 공간에 반영")
	_expect(game_root._management_ui_at(Vector2(330, 850)), "2.0 전장 설계 카드 입력을 뒤쪽 월드 클릭에서 차단")
	_expect(str(game_root.monster_roster.get("slime", {}).get("specialization_id", "")) == "slime_gate_keeper", "2.0 기본 역할이 실제 runtime roster에 연결")
	_expect(str(SaveStore.inspect(test_path).get("status", "")) == SaveStore.STATUS_VALID, "실제 GameRoot 진입 즉시 2.0 save 생성")
	_expect(game_root._rooms_by_facility("recovery").is_empty() and game_root._rooms_by_facility("treasure").is_empty(), "V20 미배치 상태에서 숨은 회복·보물 시설 효과 제거")
	var placement: Dictionary = game_root._v20_placement_state()
	var slime_placed := PlacementService.place_monster_drag(placement, "slime", "south_gate")
	placement = slime_placed.get("state", placement)
	var goblin_placed := PlacementService.place_monster_drag(placement, "goblin", "fallback")
	placement = goblin_placed.get("state", placement)
	_expect(bool(slime_placed.get("ok", false)) and bool(goblin_placed.get("ok", false)), "수동 몬스터 배치 두 건이 서로 다른 고정 구간에 반영")
	placement = PlacementService.select_slot(placement, "north_gate").get("state", {})
	var installed := PlacementService.choose_facility(placement, "v20_barricade", DataRegistry.v20_facilities)
	placement = installed.get("state", placement)
	placement = PlacementService.select_slot(placement, "treasure").get("state", placement)
	var decoy_installed := PlacementService.choose_facility(placement, "v20_decoy_treasure", DataRegistry.v20_facilities)
	placement = decoy_installed.get("state", placement)
	placement = PlacementService.select_slot(placement, "fallback").get("state", placement)
	var recovery_installed := PlacementService.choose_facility(placement, "v20_recovery_nest", DataRegistry.v20_facilities)
	placement = recovery_installed.get("state", placement)
	game_root._v20_update_placement_state(placement, recovery_installed)
	var runtime_facilities: Array[Dictionary] = game_root._v20_runtime_facilities()
	_expect(str(game_root.rooms.get("entrance", {}).get("facility_role", "")) == "v20_barricade" and not runtime_facilities.is_empty() and str(runtime_facilities[0].get("room_id", "")) == "entrance", "성문 전초 시설 선택이 실제 입구 구간 전투 효과로 연결")
	_expect(game_root._rooms_by_facility("treasure") == ["barracks"] and game_root._rooms_by_facility("recovery") == ["fallback"], "설치한 미끼·회복 시설만 선택 구역 한 곳에 활성화")
	var rooms_before_combat: Dictionary = game_root._v20_placement_state().get("rooms", {}).duplicate(true)
	game_root._start_combat()
	await get_tree().process_frame
	_expect(game_root.current_screen == "combat" and not game_root.combat_scene.v20_encounter_definition.is_empty(), "실제 GameRoot DAY 1 전투·encounter 연결")
	var slime_units: Array = game_root.monster_units.filter(func(unit): return str(unit.unit_id) == "slime")
	var goblin_units: Array = game_root.monster_units.filter(func(unit): return str(unit.unit_id) == "goblin")
	var slime_unit: Node = slime_units[0] if not slime_units.is_empty() else null
	var goblin_unit: Node = goblin_units[0] if not goblin_units.is_empty() else null
	var slime_context: Dictionary = game_root.combat_scene._v20_role_context(slime_unit) if slime_unit != null else {}
	var goblin_context: Dictionary = game_root.combat_scene._v20_role_context(goblin_unit) if goblin_unit != null else {}
	_expect(str(slime_context.get("manual_anchor_node", "")) == "spike_corridor" and str(goblin_context.get("manual_anchor_node", "")) == "fallback", "전투 설정 뒤 역할 anchor가 수동 배치 구간을 그대로 사용")
	if slime_unit != null and goblin_unit != null:
		for unit in [slime_unit, goblin_unit]:
			unit.global_position = game_root.graph.center("entrance")
			unit.current_room = "entrance"
			unit.goal_room = "entrance"
			unit.stop_navigation()
		var slime_moved: bool = game_root.combat_scene._apply_v20_role_movement(slime_unit, null)
		var goblin_moved: bool = game_root.combat_scene._apply_v20_role_movement(goblin_unit, null)
		_expect(slime_moved and goblin_moved and str(slime_unit.goal_room) == "spike_corridor" and str(goblin_unit.goal_room) == "fallback" and not slime_unit.path_points.is_empty() and not goblin_unit.path_points.is_empty() and slime_unit.path_points != goblin_unit.path_points, "같은 출발점에서도 수동 배치별 실제 역할 이동 경로가 분리")
	else:
		_expect(false, "같은 출발점에서도 수동 배치별 실제 역할 이동 경로가 분리")
	var passive_barricade: Dictionary = game_root.combat_scene._v20_facility_effects_for_room("entrance", "v20_barricade")
	_expect(is_equal_approx(float(passive_barricade.get("enemy_slow_multiplier", 1.0)), 0.78), "관리에서 지은 바리케이드의 입구 감속 수치가 실제 CombatScene에 전달")
	var activated_barricade := FacilityService.activate(game_root.combat_scene.v20_facility_state, "north_gate", DataRegistry.v20_facilities)
	game_root.combat_scene.v20_facility_state = activated_barricade.get("state", game_root.combat_scene.v20_facility_state)
	var active_barricade: Dictionary = game_root.combat_scene._v20_facility_effects_for_room("entrance", "v20_barricade")
	_expect(is_equal_approx(float(active_barricade.get("enemy_slow_multiplier", 1.0)), 0.48), "시설 발동이 실제 CombatScene 입구 감속을 강화")
	_expect(is_equal_approx(game_root.combat_scene._v20_loot_delay_seconds("barracks"), 7.5), "중앙 전투실 미끼가 실제 약탈 준비 시간을 5초→7.5초로 지연")
	var activated_decoy := FacilityService.activate(game_root.combat_scene.v20_facility_state, "treasure", DataRegistry.v20_facilities)
	game_root.combat_scene.v20_facility_state = activated_decoy.get("state", game_root.combat_scene.v20_facility_state)
	var active_decoy: Dictionary = game_root.combat_scene._v20_facility_effects_for_room("barracks", "v20_decoy_treasure")
	_expect(is_equal_approx(game_root.combat_scene._v20_loot_delay_seconds("barracks"), 10.0) and is_equal_approx(float(active_decoy.get("thief_slow_multiplier", 1.0)), 0.55), "미끼 발동이 실제 약탈 시간을 10초로 늘리고 도둑 감속을 강화")
	var imp_units: Array = game_root.monster_units.filter(func(unit): return str(unit.unit_id) == "imp")
	var imp_unit: Node = imp_units[0] if not imp_units.is_empty() else null
	if imp_unit != null:
		imp_unit.current_room = "fallback"
		imp_unit.hp = maxi(1, imp_unit.max_hp - 20)
		var hp_before_recovery: int = imp_unit.hp
		game_root.combat_scene.update_room_effects(1.0)
		_expect(imp_unit.hp == mini(imp_unit.max_hp, hp_before_recovery + 8), "왕좌 전실 회복 둥지가 실제 몬스터를 초당 8 회복")
	else:
		_expect(false, "왕좌 전실 회복 둥지가 실제 몬스터를 초당 8 회복")
	game_root.combat_scene.spawn_enemy("thief", {"goal_type_override": "treasure", "v20_route_nodes": ["entrance", "north_gate", "north_cross", "south_gate", "south_cross", "treasure"]})
	var spawned_thief: Node = game_root.enemy_units[-1] if not game_root.enemy_units.is_empty() else null
	var thief_stages: Array = spawned_thief.get_meta("v20_runtime_checkpoints", []) if spawned_thief != null else []
	_expect(spawned_thief != null and str(spawned_thief.goal_room) == "entrance" and thief_stages == ["entrance", "spike_corridor", "barracks"] and str(spawned_thief.get_meta("v20_checkpoint_final_goal", "")) == "barracks", "도둑도 입구부터 중앙 전투실까지 순차 방어선 prefix 사용")
	if spawned_thief != null:
		spawned_thief.current_room = "barracks"
		spawned_thief.global_position = game_root.graph.center("barracks")
		game_root.combat_scene.update_room_effects(0.1)
		_expect(is_equal_approx(float(spawned_thief.slow_factor), 0.55), "발동한 미끼가 중앙 전투실의 실제 도둑 이동을 0.55배로 감속")
	else:
		_expect(false, "발동한 미끼가 중앙 전투실의 실제 도둑 이동을 0.55배로 감속")
	game_root.combat_scene._begin_v20_command_targeting("v20_rally")
	await get_tree().process_frame
	_expect(game_root.combat_scene.pending_v20_command_id == "v20_rally" and _find_named(game_root.combat_scene.v20_hud, "TargetingPrompt") != null, "실제 전투 명령 선택이 전장 대상 지정 단계 진입")
	var runtime_room_id := str(game_root.rooms.keys()[0])
	var runtime_room_point: Vector2 = game_root.graph.rect(runtime_room_id).get_center()
	_expect(game_root.combat_scene.handle_v20_world_click(runtime_room_point) and game_root.combat_scene.pending_v20_command_id == "", "실제 방 클릭으로 집결 명령 발동·대상 지정 종료")
	game_root._finish_combat(false, "통합 검증용 패배")
	await get_tree().process_frame
	_expect(game_root.current_screen == "result" and str(game_root.v20_session.get("status", "")) == "result" and not game_root.result_summary.get("v20", {}).is_empty(), "실제 전투 결산이 2.0 원인·수정 후보 결과 화면으로 연결")
	_expect(int(game_root.result_summary.get("metrics", {}).get("demon_lord_hp_max", 0)) == GameState.demon_lord_max_hp, "결과 피해 배지에 실제 마왕 최대 체력 전달")
	game_root._v20_continue_from_result("retry")
	await get_tree().process_frame
	_expect(game_root.current_screen == "management" and game_root._v20_placement_state().get("rooms", {}) == rooms_before_combat, "실제 결과 화면 재도전이 배치를 보존해 관리로 복귀")
	game_root._kill_combat_music_tween()
	game_root.combat_music_player.stop()
	game_root.combat_music_player.stream = null
	game_root.remove_child(game_root.combat_music_player)
	game_root.combat_music_player.free()
	game_root.combat_music_player = null
	game_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(test_path)
	_remove_empty_test_dir(test_path.get_base_dir())


func _test_v20_no_decoy_thief_terminal() -> void:
	var test_path := "user://v20_no_decoy_test_%s/campaign_v20.json" % str(Time.get_ticks_usec())
	var game_root = GameRootScene.instantiate()
	game_root.v20_save_path = test_path
	add_child(game_root)
	await get_tree().process_frame
	await get_tree().process_frame
	game_root._v20_start_new_session("v20_story")
	await get_tree().process_frame
	game_root._start_combat()
	await get_tree().process_frame
	_expect(game_root._rooms_by_facility("treasure").is_empty() and game_root.combat_scene._treasure_room() == "barracks", "미끼가 없어도 중앙 전투실이 도둑의 고정 약탈 목표")
	game_root.combat_scene.spawn_enemy("thief", {"goal_type_override": "treasure", "v20_route_nodes": ["entrance", "north_gate", "north_cross", "south_gate", "south_cross", "treasure"]})
	var thief: Node = game_root.enemy_units[-1] if not game_root.enemy_units.is_empty() else null
	if thief != null:
		thief.current_room = "barracks"
		thief.goal_room = "barracks"
		thief.global_position = game_root.graph.center("barracks")
		thief.stop_navigation()
		GameState.gold = 250
		game_root.combat_scene.update_room_effects(5.1)
		_expect(GameState.gold == 150 and float(game_root.thief_steal_timers.get(thief, 0.0)) < -100.0 and str(thief.goal_room) == "entrance", "미끼 없는 도둑도 5초 약탈 뒤 입구 도주로 전환")
		thief.current_room = "entrance"
		thief.global_position = game_root.graph.center("entrance")
		game_root.combat_scene.update_room_effects(0.1)
		_expect(bool(thief.down) and bool(thief.escaped), "약탈 도둑이 입구 도착 뒤 종료되어 전투 정체 방지")
	else:
		_expect(false, "미끼 없는 도둑도 5초 약탈 뒤 입구 도주로 전환")
		_expect(false, "약탈 도둑이 입구 도착 뒤 종료되어 전투 정체 방지")
	game_root._kill_combat_music_tween()
	if game_root.combat_music_player != null and is_instance_valid(game_root.combat_music_player):
		game_root.combat_music_player.stop()
		game_root.combat_music_player.stream = null
		game_root.remove_child(game_root.combat_music_player)
		game_root.combat_music_player.free()
		game_root.combat_music_player = null
	game_root.queue_free()
	await get_tree().process_frame
	SaveStore.delete(test_path)
	_remove_empty_test_dir(test_path.get_base_dir())


func _capture_entry_and_result() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var background := ColorRect.new()
	background.size = Vector2(1280, 720)
	background.color = Color("#07050b")
	viewport.add_child(background)
	var title := Label.new()
	title.text = "마왕님, 마왕성은 누가 지켜요?"
	title.position = Vector2(70, 190)
	title.size = Vector2(670, 90)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#f7efe1"))
	background.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "기존 1.2와 분리된 2.0 체험 진입"
	subtitle.position = Vector2(72, 275)
	subtitle.size = Vector2(640, 40)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("#bdb3c6"))
	background.add_child(subtitle)
	var entry = TitlePanelScene.instantiate()
	entry.position = Vector2(800, 150)
	entry.size = Vector2(420, 300)
	background.add_child(entry)
	entry.setup("v20_overlord", {"status": "valid", "summary": {"day": 3}})
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var title_path := "user://v20_phase10_title_entry_1280x720.png"
	var title_error := viewport.get_texture().get_image().save_png(title_path)
	_expect(title_error == OK, "Phase 10 타이틀 2.0 진입 1280x720 실제 렌더")
	if title_error == OK:
		print("V20_PHASE10_TITLE_CAPTURE: %s" % ProjectSettings.globalize_path(title_path))
	for child in background.get_children():
		background.remove_child(child)
		child.queue_free()
	var result_screen = ResultScreenScene.instantiate()
	background.add_child(result_screen)
	result_screen.setup(_sample_loss_result(), 3)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result_path := "user://v20_phase10_retry_result_1280x720.png"
	var result_error := viewport.get_texture().get_image().save_png(result_path)
	_expect(result_error == OK, "Phase 10 원인·재도전 1280x720 실제 렌더")
	if result_error == OK:
		print("V20_PHASE10_RESULT_CAPTURE: %s" % ProjectSettings.globalize_path(result_path))
	viewport.queue_free()
	await get_tree().process_frame


func _sample_loss_result() -> Dictionary:
	return {"win": false, "lines": [], "v20": {"cause": "공병이 핵심 시설을 무력화한 동안 전선이 비었습니다.", "guidance": "시설을 분산하고 집중 명령을 공병에게 예약하세요.", "placement_preserved": true}, "metrics": {"combat_time": 48.0, "alive_monsters": 1, "total_monsters": 3, "demon_lord_hp": 0, "treasure_gold_stolen": 0, "facility_disables": 1}}


func _find_named(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, target_name)
		if found != null:
			return found
	return null


func _write_text(path: String, content: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(content)
		file.close()


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content := file.get_as_text()
	file.close()
	return content


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _remove_empty_test_dir(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	var dir := DirAccess.open(absolute)
	if dir != null and dir.get_files().is_empty() and dir.get_directories().is_empty():
		DirAccess.remove_absolute(absolute)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20OnboardingRetrySave] FAIL: %s" % message)
