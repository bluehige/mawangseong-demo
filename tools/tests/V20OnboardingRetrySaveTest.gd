extends Node

const OnboardingService = preload("res://scripts/v20/onboarding/V20OnboardingService.gd")
const SessionService = preload("res://scripts/v20/session/V20SessionService.gd")
const SaveStore = preload("res://scripts/v20/save/V20SaveStore.gd")
const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
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
	_expect(int(session.get("day", 0)) == 1 and int(session.get("placement_state", {}).get("build_points", 0)) == 8, "마왕 DAY 1 세션·건설 예산 초기화")
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
	var summary := {"day": 1, "difficulty_id": "v20_story", "difficulty_name": "이야기", "checkpoint": "test", "completed": false}
	var write_result := SaveStore.write(payload, summary, v20_path)
	_expect(bool(write_result.get("ok", false)), "2.0 전용 경로 atomic 저장")
	var inspection := SaveStore.inspect(v20_path)
	_expect(str(inspection.get("status", "")) == SaveStore.STATUS_VALID and int(inspection.get("summary", {}).get("day", 0)) == 1, "2.0 저장 재검증·요약")
	var restored := SessionService.restore(inspection.get("payload", {}), DataRegistry.v20_economy)
	_expect(bool(restored.get("ok", false)) and str(restored.get("state", {}).get("difficulty_id", "")) == "v20_story", "2.0 session 저장 왕복")
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
	var hard_button: Button = _find_named(title_panel, "Difficulty_v20_overlord") as Button
	_expect(hard_button != null, "타이틀 2.0 난이도 세 선택 중 마왕 버튼")
	if hard_button != null:
		hard_button.pressed.emit()
	await get_tree().process_frame
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
	var result_button: Button = result_screen.get_node_or_null("V20ResultActionButton")
	_expect(result_button != null and "같은 배치" in result_button.text, "패배 결산의 배치 보존 재도전 버튼")
	if result_button != null:
		result_button.pressed.emit()
	_expect(result_action == "retry", "재도전 action signal")
	host.queue_free()
	await get_tree().process_frame


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
	_expect(str(game_root.monster_roster.get("slime", {}).get("specialization_id", "")) == "slime_gate_keeper", "2.0 기본 역할이 실제 runtime roster에 연결")
	_expect(str(SaveStore.inspect(test_path).get("status", "")) == SaveStore.STATUS_VALID, "실제 GameRoot 진입 즉시 2.0 save 생성")
	var placement: Dictionary = game_root._v20_placement_state()
	placement = PlacementService.select_slot(placement, "north_gate").get("state", {})
	var installed := PlacementService.choose_facility(placement, "v20_barricade", DataRegistry.v20_facilities)
	game_root._v20_update_placement_state(installed.get("state", {}), installed)
	var rooms_before_combat: Dictionary = game_root._v20_placement_state().get("rooms", {}).duplicate(true)
	game_root._start_combat()
	await get_tree().process_frame
	_expect(game_root.current_screen == "combat" and not game_root.combat_scene.v20_encounter_definition.is_empty(), "실제 GameRoot DAY 1 전투·encounter 연결")
	game_root._finish_combat(false, "통합 검증용 패배")
	await get_tree().process_frame
	_expect(game_root.current_screen == "result" and str(game_root.v20_session.get("status", "")) == "result" and not game_root.result_summary.get("v20", {}).is_empty(), "실제 전투 결산이 2.0 원인·수정 후보 결과 화면으로 연결")
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
