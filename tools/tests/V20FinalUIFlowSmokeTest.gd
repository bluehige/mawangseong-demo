extends Node

const TitleScene = preload("res://scenes/v20/ui/V20TitleEntryPanel.tscn")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const SaveStore = preload("res://scripts/v20/save/V20SaveStore.gd")
const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")

var failed := false
var assertion_count := 0
var requested_profile_id := ""


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	get_window().size = Vector2i(1280, 720)
	await _test_title_start_action()
	await _test_actual_game_root_flow()
	if failed:
		print("V20_FINAL_UI_FLOW_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_FINAL_UI_FLOW_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_title_start_action() -> void:
	var host := Control.new()
	host.size = Vector2(420, 300)
	add_child(host)
	var title = TitleScene.instantiate()
	title.size = host.size
	host.add_child(title)
	await get_tree().process_frame
	title.setup("v20_tactician", {"status": "absent"})
	title.new_session_requested.connect(func(profile_id: String): requested_profile_id = profile_id)
	await get_tree().process_frame
	var start_button: Button = title.find_child("V20NewSessionButton", true, false)
	_expect(start_button != null and start_button.text == "새 테스트 시작", "타이틀 주 행동은 새 테스트 시작 하나")
	if start_button != null:
		start_button.pressed.emit()
	_expect(requested_profile_id == "v20_tactician", "타이틀 시작 signal이 v2.0 고정 profile 전달")
	host.free()
	await get_tree().process_frame
	await get_tree().process_frame


func _test_actual_game_root_flow() -> void:
	var save_path := "user://tests/v20_final_ui_flow_smoke.json"
	SaveStore.delete(save_path)
	var game_root = GameRootScene.instantiate()
	game_root._v20_set_save_path_for_tests(save_path)
	add_child(game_root)
	await get_tree().process_frame
	await get_tree().process_frame
	var acceptance: Dictionary = game_root._v20_configure_acceptance_sources_for_tests(
		["--v20-acceptance", "--v20-seed-map=1:2001,2:2002,3:2003,4:2004,5:2005", "--v20-scenario=FREE"],
		"",
		true
	)
	_expect(bool(acceptance.get("ok", false)) and str(acceptance.get("placement_fingerprint", "x")) == "", "고정 seed·FREE debug acceptance 입력")
	game_root._v20_start_new_session("v20_tactician")
	await get_tree().process_frame
	_expect(str(game_root._v20_flow_state()) == "INTRUSION_BRIEF", "새 테스트는 침입 확인부터 시작")
	var begin_button: Button = game_root.ui_layer.find_child("V20PrimaryActionButton", true, false)
	_expect(begin_button != null and begin_button.text.begins_with("배치 시작"), "침입 확인 주 행동은 배치 시작 하나")
	if begin_button != null:
		begin_button.pressed.emit()
	await get_tree().process_frame
	_expect(str(game_root._v20_flow_state()) == "PLACEMENT", "실제 배치 시작 버튼으로 PLACEMENT 진입")

	var board = game_root.ui_layer.find_child("PlacementBoard", true, false)
	_expect(board != null, "실제 GameRoot에 직접 배치 보드 표시")
	if board == null:
		game_root._shutdown_audio_for_exit()
		game_root.free()
		await get_tree().process_frame
		await get_tree().process_frame
		SaveStore.delete(save_path)
		return

	board._on_facility_dropped("v20_barricade", "gate_outpost")
	await get_tree().process_frame
	_expect(str(game_root.v20_session.get("placement_state", {}).get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "v20_barricade", "시설 drag 배선이 실제 session에 설치 반영")

	var before_invalid := JSON.stringify(PlacementService.serialize(game_root._v20_placement_state()))
	board._on_tool_drag_started("v20_facility", "v20_barricade")
	var invalid_target
	for room_id_value in board.placement_state.get("rooms", {}).keys():
		var room_button = board.get_node_or_null("RouteMap/Room_%s" % str(room_id_value))
		if room_button != null and not bool(room_button.valid_target):
			invalid_target = room_button
			break
	_expect(invalid_target != null, "시설 drag 중 잘못된 슬롯을 구분")
	if invalid_target != null:
		invalid_target._can_drop_data(Vector2.ZERO, {"kind": "v20_facility", "facility_id": "v20_barricade"})
	board._on_tool_drag_finished()
	await get_tree().process_frame
	_expect(JSON.stringify(PlacementService.serialize(game_root._v20_placement_state())) == before_invalid, "잘못된 drop 뒤 실제 session fingerprint 불변")

	board._on_monster_dropped("slime", "spike_corridor")
	await get_tree().process_frame
	_expect(str(game_root.v20_session.get("placement_state", {}).get("roster", {}).get("slime", {}).get("room_id", "")) == "spike_corridor", "몬스터 drag 배선이 실제 session 위치 변경")
	board.undo_last()
	await get_tree().process_frame
	_expect(str(game_root.v20_session.get("placement_state", {}).get("roster", {}).get("slime", {}).get("room_id", "")) == "gate_outpost", "Undo가 실제 session의 몬스터 위치 복원")

	var start_button: Button = game_root.ui_layer.find_child("V20PrimaryActionButton", true, false)
	_expect(start_button != null and not start_button.disabled and start_button.text.begins_with("방어 시작"), "유효 배치에서 방어 시작 활성")
	if start_button != null:
		start_button.pressed.emit()
	await get_tree().process_frame
	_expect(str(game_root._v20_flow_state()) == "DEFENSE_START", "방어 시작은 3초 countdown 상태 진입")
	var cancel_button: Button = game_root.ui_layer.find_child("V20CancelDefenseButton", true, false)
	_expect(cancel_button != null, "countdown에 취소 행동 표시")
	if cancel_button != null:
		cancel_button.pressed.emit()
	await get_tree().process_frame
	_expect(str(game_root._v20_flow_state()) == "PLACEMENT", "countdown 취소가 배치로 복귀")
	var restart_button: Button = game_root.ui_layer.find_child("V20PrimaryActionButton", true, false)
	if restart_button != null:
		restart_button.pressed.emit()
	game_root._v20_advance_defense_countdown(3.0)
	await get_tree().process_frame
	_expect(str(game_root._v20_flow_state()) == "COMBAT", "countdown 재시작 뒤 전투 HUD 진입")

	game_root.combat_scene.spawn_enemy("explorer")
	game_root.combat_scene._begin_v20_command_targeting("v20_focus")
	await get_tree().process_frame
	_expect(game_root.ui_layer.find_child("TargetingPrompt", true, false) != null, "전투 명령 선택 시 대상 안내 생성")
	game_root.combat_scene.cancel_v20_targeting()
	await get_tree().process_frame
	_expect(game_root.ui_layer.find_child("TargetingPrompt", true, false) == null, "명령 취소 시 대상 안내 제거")
	game_root.combat_scene._begin_v20_command_targeting("v20_focus")
	var focus_targeted: bool = game_root.combat_scene.handle_v20_world_click(game_root.enemy_units[-1].global_position)
	await get_tree().process_frame
	_expect(focus_targeted and str(game_root.v20_command_target_feedback.get("target", {}).get("type", "")) == "enemy", "집중 선택 뒤 붉게 빛나는 실제 적 클릭으로 명령 적용")
	game_root.combat_scene._begin_v20_command_targeting("v20_rally")
	var room_targeted: bool = game_root.combat_scene.handle_v20_world_click(game_root.graph.center("gate_outpost"))
	await get_tree().process_frame
	_expect(room_targeted and str(game_root.v20_command_target_feedback.get("target", {}).get("type", "")) == "room", "집결 선택 뒤 빛나는 실제 방 클릭으로 명령 적용")
	game_root.combat_scene._begin_v20_command_targeting("v20_activate_facility")
	var facility_targeted: bool = game_root.combat_scene.handle_v20_world_click(game_root.graph.canonical_slot_world_position("gate_outpost_facility"))
	await get_tree().process_frame
	_expect(facility_targeted and str(game_root.v20_command_target_feedback.get("target", {}).get("type", "")) == "facility", "시설 발동 선택 뒤 실제 시설 오브젝트 클릭으로 명령 적용")

	GameState.demon_lord_hp = 0
	game_root.combat_scene.finish_combat(false, "UI flow smoke 패배")
	await get_tree().process_frame
	var loss_edit: Button = game_root.ui_layer.find_child("V20RetryEditButton", true, false)
	_expect(str(game_root._v20_flow_state()) == "RESULT" and loss_edit != null, "패배 결과와 배치 수정 행동 표시")
	if loss_edit != null:
		loss_edit.pressed.emit()
	await get_tree().process_frame
	_expect(str(game_root._v20_flow_state()) == "PLACEMENT", "패배 결과의 배치 수정 signal이 PLACEMENT 복귀")

	var win_start: Button = game_root.ui_layer.find_child("V20PrimaryActionButton", true, false)
	if win_start != null:
		win_start.pressed.emit()
	game_root._v20_advance_defense_countdown(3.0)
	await get_tree().process_frame
	GameState.demon_lord_hp = GameState.demon_lord_max_hp
	game_root.combat_scene.finish_combat(true, "UI flow smoke 승리")
	await get_tree().process_frame
	var win_action: Button = game_root.ui_layer.find_child("V20ResultActionButton", true, false)
	_expect(str(game_root._v20_flow_state()) == "RESULT" and win_action != null and win_action.text.begins_with("다음 침입 확인"), "승리 결과 주 행동은 다음 침입 확인")

	game_root._shutdown_audio_for_exit()
	game_root.free()
	await get_tree().process_frame
	await get_tree().process_frame
	SaveStore.delete(save_path)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20FinalUIFlowSmoke] FAIL: %s" % message)
