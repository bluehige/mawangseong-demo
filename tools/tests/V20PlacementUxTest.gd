extends Node

const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const SessionService = preload("res://scripts/v20/session/V20SessionService.gd")
const BoardScene = preload("res://scenes/v20/placement/V20PlacementBoard.tscn")
const HUDScene = preload("res://scenes/v20/ui/V20InformationHUD.tscn")
const RoomButtonScript = preload("res://scripts/v20/placement/V20PlacementRoomButton.gd")
const DayFlowService = preload("res://scripts/v20/flow/V20DayFlowService.gd")
const UITheme = preload("res://scripts/v20/ui/V20UITheme.gd")
const SLIME_PORTRAIT = preload("res://assets/sprites/portraits/onboarding/portrait_pudding.png")
const GOBLIN_PORTRAIT = preload("res://assets/sprites/portraits/onboarding/portrait_gob.png")
const IMP_PORTRAIT = preload("res://assets/sprites/portraits/onboarding/portrait_pynn.png")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_rule_catalog()
	_test_placement_view_catalog()
	_test_three_slot_card_layout()
	_test_facility_install_replace_undo()
	_test_remove_move_and_budget_recalculation()
	_test_monster_slots_and_round_trip()
	await _test_board_interactions()
	await _test_board_facility_actions()
	if OS.get_cmdline_user_args().has("--capture-v20-ui-placement") and DisplayServer.get_name() != "headless":
		await _capture_placement_flow(Vector2i(1280, 720))
		await _capture_placement_flow(Vector2i(1366, 768))
		await _capture_three_slot_card()
	if failed:
		print("V20_PLACEMENT_UX_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_PLACEMENT_UX_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_rule_catalog() -> void:
	var rules := DataRegistry.v20_placement_rules
	_expect(int(rules.get("schema_version", 0)) == 2, "직접 배치 입력 규칙 schema 2 로드")
	_expect(str(rules.get("facility_install", {}).get("primary_input", "")) == "facility_drag_to_slot", "시설 기본 입력은 facility_drag_to_slot")
	_expect(int(rules.get("facility_install", {}).get("new_install_interactions", 0)) == 1, "빈 시설 슬롯 drag 설치는 1회 동작")
	_expect(int(rules.get("facility_install", {}).get("replacement_interactions", 0)) == 2, "시설 교체는 drag와 확인 2회 동작")
	_expect(str(rules.get("monster_placement", {}).get("primary_input", "")) == "portrait_drag_to_room", "몬스터 기본 입력은 portrait_drag_to_room")


func _test_placement_view_catalog() -> void:
	var board := _board()
	var placement_view: Dictionary = board.get("placement_view", {})
	var route_waypoints: Array = placement_view.get("route_waypoints", [])
	var stage_anchors: Dictionary = placement_view.get("stage_anchors", {})
	var card_anchors: Dictionary = placement_view.get("room_card_anchors", {})
	_expect(route_waypoints.size() >= 12 and Vector2(float(route_waypoints[0][0]), float(route_waypoints[0][1])).y > 0.95 and Vector2(float(route_waypoints[-1][0]), float(route_waypoints[-1][1])).y < 0.15, "배치 흐름선이 하단 침입구에서 실제 성 내부 통로를 거쳐 왕좌까지 연결")
	for room_id in ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom"]:
		var stage_value: Array = stage_anchors.get(room_id, [])
		var card_value: Array = card_anchors.get(room_id, [])
		var stage := Vector2(float(stage_value[0]), float(stage_value[1])) if stage_value.size() >= 2 else Vector2(-1, -1)
		var route_contains_stage := route_waypoints.any(func(waypoint_value):
			var waypoint: Array = waypoint_value
			return waypoint.size() >= 2 and Vector2(float(waypoint[0]), float(waypoint[1])).distance_to(stage) <= 0.001
		)
		_expect(stage_value.size() == 2 and card_value.size() == 2 and route_contains_stage, "%s 실제 방 stage·정보 카드 anchor와 흐름선 접점 고정" % room_id)


func _test_three_slot_card_layout() -> void:
	var button = RoomButtonScript.new()
	button.size = Vector2(226, 116)
	add_child(button)
	button.setup("three_slot_fixture", "테스트 전투실\n◇ 회복 둥지\n수비대 3/3", _three_monster_tokens(), 3)
	button._layout_monster_tokens()
	var frames: Array[Control] = []
	var all_portraits_readable := true
	for monster_id in ["slime", "goblin", "imp"]:
		var frame: Control = button.get_node_or_null("MonsterTokenFrame_%s" % monster_id)
		var portrait: TextureRect = button.get_node_or_null("MonsterTokenFrame_%s/MonsterToken_%s" % [monster_id, monster_id])
		var monster_name: Label = button.get_node_or_null("MonsterTokenFrame_%s/MonsterName_%s" % [monster_id, monster_id])
		if frame != null:
			frames.append(frame)
		all_portraits_readable = all_portraits_readable and frame != null and portrait != null and portrait.size.x >= 24.0 and monster_name != null and monster_name.text != ""
	var slots_fit := frames.size() == 3
	for index in range(frames.size()):
		slots_fit = slots_fit and frames[index].position.x >= button.size.x * 0.5 and frames[index].position.y >= 0.0 and frames[index].position.y + frames[index].size.y <= button.size.y
		if index > 0:
			slots_fit = slots_fit and not Rect2(frames[index - 1].position, frames[index - 1].size).intersects(Rect2(frames[index].position, frames[index].size))
	var content: Label = button.get_node_or_null("RoomContent")
	_expect(all_portraits_readable, "정원 3명 카드에서 몬스터 초상과 이름 3개 판독 가능")
	_expect(slots_fit and content != null and content.position.x + content.size.x < frames[0].position.x, "정원 3명 카드에서 왼쪽 정보와 오른쪽 세로 슬롯이 겹치지 않음")
	button.queue_free()


func _three_monster_tokens() -> Array:
	return [
		{"monster_id": "slime", "name": "슬라임", "texture": SLIME_PORTRAIT},
		{"monster_id": "goblin", "name": "고블린", "texture": GOBLIN_PORTRAIT},
		{"monster_id": "imp", "name": "임프", "texture": IMP_PORTRAIT}
	]


func _test_facility_install_replace_undo() -> void:
	var state := _initial_state()
	var installed := PlacementService.place_facility_drag(state, "v20_barricade", "gate_outpost", DataRegistry.v20_facilities)
	state = installed.get("state", {})
	_expect(bool(installed.get("ok", false)) and str(installed.get("status", "")) == PlacementService.STATUS_INSTALLED, "gate_outpost_facility에 바리케이드 즉시 설치")
	_expect(str(state.get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "v20_barricade" and int(state.get("build_points", 0)) == 7, "시설 ID와 건설 자원 10→7 반영")
	var pending := PlacementService.place_facility_drag(state, "v20_barracks", "gate_outpost", DataRegistry.v20_facilities)
	_expect(str(pending.get("status", "")) == PlacementService.STATUS_CONFIRMATION_REQUIRED and str(pending.get("state", {}).get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "v20_barricade", "교체 확인 전 기존 시설 유지")
	var replaced := PlacementService.confirm_replacement(pending.get("state", {}), DataRegistry.v20_facilities)
	_expect(str(replaced.get("status", "")) == PlacementService.STATUS_REPLACED and str(replaced.get("state", {}).get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "v20_barracks", "확인 후 같은 canonical 시설 슬롯 교체")
	var undone := PlacementService.undo(replaced.get("state", {}))
	_expect(str(undone.get("state", {}).get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "v20_barricade" and int(undone.get("state", {}).get("build_points", 0)) == 7, "교체 Undo가 시설과 자원 복원")


func _test_monster_slots_and_round_trip() -> void:
	var state := _initial_state()
	var moved := PlacementService.place_monster_drag(state, "slime", "spike_corridor")
	state = moved.get("state", {})
	_expect(bool(moved.get("ok", false)) and str(state.get("roster", {}).get("slime", {}).get("monster_slot_id", "")) == "spike_corridor_monster_1", "slime 이동 시 spike_corridor_monster_1 배정")
	var second := PlacementService.place_monster_drag(state, "goblin", "spike_corridor")
	state = second.get("state", {})
	_expect(bool(second.get("ok", false)) and str(state.get("roster", {}).get("goblin", {}).get("monster_slot_id", "")) == "spike_corridor_monster_2", "goblin 이동 시 spike_corridor_monster_2 배정")
	var full := PlacementService.place_monster_drag(state, "imp", "spike_corridor")
	_expect(not bool(full.get("ok", true)) and str(full.get("status", "")) == "room_full", "몬스터 슬롯 2개가 찬 구역은 세 번째 배치 거부")
	_expect(bool(PlacementService.validate_state(state).get("ok", false)), "room_id와 monster_slot_id가 일치하는 placement state")
	var restored := PlacementService.restore(JSON.parse_string(JSON.stringify(PlacementService.serialize(state))))
	_expect(bool(restored.get("ok", false)), "시설·방·몬스터 슬롯 placement JSON 왕복 복원")
	_expect(str(restored.get("state", {}).get("roster", {}).get("goblin", {}).get("monster_slot_id", "")) == "spike_corridor_monster_2", "복원 후 goblin 슬롯 ID 유지")


func _test_remove_move_and_budget_recalculation() -> void:
	var state: Dictionary = PlacementService.place_facility_drag(_initial_state(), "v20_barricade", "gate_outpost", DataRegistry.v20_facilities).get("state", {})
	var moved := PlacementService.move_facility(state, "gate_outpost", "spike_corridor", DataRegistry.v20_facilities)
	_expect(bool(moved.get("ok", false)) and str(moved.get("state", {}).get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "" and str(moved.get("state", {}).get("rooms", {}).get("spike_corridor", {}).get("facility_id", "")) == "v20_barricade", "시설 이동이 원래 슬롯을 비우고 대상 슬롯만 점유")
	_expect(int(moved.get("state", {}).get("build_points", -1)) == 7, "시설 이동은 비용 3·사용 가능 7을 바꾸지 않음")
	var removed := PlacementService.remove_facility(moved.get("state", {}), "spike_corridor", DataRegistry.v20_facilities)
	_expect(bool(removed.get("ok", false)) and int(removed.get("state", {}).get("build_points", -1)) == 10, "시설 제거가 비용 3을 회수해 사용 가능 10 복원")
	var replacement_source: Dictionary = PlacementService.place_facility_drag(_initial_state(), "v20_barricade", "gate_outpost", DataRegistry.v20_facilities).get("state", {})
	var pending := PlacementService.place_facility_drag(replacement_source, "v20_barracks", "gate_outpost", DataRegistry.v20_facilities)
	var replaced := PlacementService.confirm_replacement(pending.get("state", {}), DataRegistry.v20_facilities)
	_expect(int(replaced.get("state", {}).get("build_points", -1)) == 6, "비용 3 시설을 비용 4 시설로 교체하면 10-4=6 재계산")


func _test_board_interactions() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var board = BoardScene.instantiate()
	host.add_child(board)
	await get_tree().process_frame
	board.setup(_initial_state(), DataRegistry.v20_facilities, _board())
	await get_tree().process_frame
	var gate_button = board.get_node_or_null("RouteMap/Room_gate_outpost")
	var spike_button = board.get_node_or_null("RouteMap/Room_spike_corridor")
	_expect(gate_button != null and spike_button != null, "1280×720 보드에 gate_outpost와 spike_corridor drop target 생성")
	_expect(str(board.current_route.get("first_engagement_node", "")) == "gate_outpost", "배치 보드 첫 교전 구역은 gate_outpost")
	var gate_center: Vector2 = gate_button.position + gate_button.size * 0.5 if gate_button != null else Vector2.ZERO
	var gate_name: Label = gate_button.get_node_or_null("MonsterTokenFrame_slime/MonsterName_slime") if gate_button != null else null
	var gate_empty: Label = gate_button.get_node_or_null("MonsterTokenFrame_empty_2/MonsterSlotEmpty_2") if gate_button != null else null
	var gate_content: Label = gate_button.get_node_or_null("RoomContent") if gate_button != null else null
	var gate_frame: Control = gate_button.get_node_or_null("MonsterTokenFrame_slime") if gate_button != null else null
	var gate_portrait: TextureRect = gate_button.get_node_or_null("MonsterTokenFrame_slime/MonsterToken_slime") if gate_button != null else null
	var empty_frame: Control = gate_button.get_node_or_null("MonsterTokenFrame_empty_2") if gate_button != null else null
	_expect(gate_button != null and gate_button.size.x >= 218.0 and gate_button.size.y >= 110.0 and gate_center.distance_to(board._room_card_anchor("gate_outpost") - board._map_rect.position) <= 0.1, "1280×720 실제 방 위치에 확대된 방 정보 카드 배치")
	_expect(gate_name != null and gate_name.text == "슬라임" and gate_empty != null and gate_empty.text.contains("빈 슬롯") and gate_content != null and gate_content.text.contains("수비대 1/2"), "방 카드에서 배치 몬스터 초상·이름·빈 슬롯·정원 상태 동시 표시")
	_expect(gate_frame != null and empty_frame != null and gate_portrait != null and gate_portrait.size.x >= 36.0 and gate_frame.position.x > gate_button.size.x * 0.5 and empty_frame.position.y > gate_frame.position.y, "정원 2명 카드에서 오른쪽 세로 슬롯과 큰 몬스터 초상 표시")
	var room_cards: Array[Control] = []
	for room_id in ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom"]:
		var room_card: Control = board.get_node_or_null("RouteMap/Room_%s" % room_id)
		if room_card != null:
			room_cards.append(room_card)
	var room_cards_do_not_overlap := room_cards.size() == 4
	for first_index in range(room_cards.size()):
		for second_index in range(first_index + 1, room_cards.size()):
			room_cards_do_not_overlap = room_cards_do_not_overlap and not Rect2(room_cards[first_index].position, room_cards[first_index].size).intersects(Rect2(room_cards[second_index].position, room_cards[second_index].size))
	_expect(room_cards_do_not_overlap, "1280×720 확대 방 카드 4개가 서로 겹치지 않음")
	var map_rect_before: Rect2 = board._map_rect
	var decoy_button = board.get_node_or_null("PlacementToolTray/FacilityTool_v20_decoy_treasure")
	_expect(decoy_button != null and decoy_button.size.y >= UITheme.BUTTON_MIN_HEIGHT and decoy_button.get_node_or_null("Name") != null and decoy_button.get_node_or_null("Cost") != null and decoy_button.get_node_or_null("Effect") != null and decoy_button.get_node_or_null("DragAffordance") != null, "1280×720 시설 카드 이름·비용·효과·드래그 표시와 최소 높이")
	var tool_summary: Control = board.get_node_or_null("PlacementToolTray/SectionSummary")
	var monsters_fit := tool_summary != null
	for monster_id in ["slime", "goblin", "imp"]:
		var monster_card: Control = board.get_node_or_null("PlacementToolTray/MonsterTool_%s" % monster_id)
		monsters_fit = monsters_fit and monster_card != null and monster_card.size.y >= UITheme.BUTTON_MIN_HEIGHT and monster_card.position.y + monster_card.size.y <= tool_summary.position.y
	_expect(monsters_fit, "1280×720 몬스터 카드 3개 최소 높이·선택 요약 비겹침")
	board._on_facility_dropped("v20_barricade", "gate_outpost")
	await get_tree().process_frame
	var state_fingerprint := JSON.stringify(PlacementService.serialize(board.placement_state))
	board._on_tool_drag_started("v20_facility", "v20_barricade")
	var valid_target_count := 0
	var invalid_target_count := 0
	var invalid_button
	for room_id_value in board.placement_state.get("rooms", {}).keys():
		var room_button = board.get_node_or_null("RouteMap/Room_%s" % str(room_id_value))
		if room_button == null:
			continue
		if bool(room_button.valid_target):
			valid_target_count += 1
		else:
			invalid_target_count += 1
			if invalid_button == null:
				invalid_button = room_button
		_expect(bool(room_button.target_mode_active), "시설 drag 중 모든 시설 슬롯이 유효·비유효 상태 표시")
	_expect(valid_target_count > 0 and invalid_target_count > 0, "시설 drag 중 설치 가능한 슬롯만 금색 강조")
	if invalid_button != null:
		var invalid_payload := {"kind": "v20_facility", "facility_id": "v20_barricade"}
		_expect(not invalid_button._can_drop_data(Vector2.ZERO, invalid_payload), "잘못된 시설 슬롯 drop 거부")
	board._on_tool_drag_finished()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(JSON.stringify(PlacementService.serialize(board.placement_state)) == state_fingerprint, "잘못된 drop 후 placement state fingerprint 불변")
	var rejection_toast: Label = board.get_node_or_null("RouteMap/PlacementToast/PlacementToastMessage")
	_expect(rejection_toast != null and rejection_toast.text != "" and not bool(board.last_result.get("ok", true)), "잘못된 drop 거부 이유 토스트 표시")
	board.undo_last()
	await get_tree().process_frame
	var facility_button = board.get_node_or_null("PlacementToolTray/FacilityTool_v20_barricade")
	if facility_button != null:
		board._on_tool_drag_started("v20_facility", "v20_barricade")
		gate_button = board.get_node_or_null("RouteMap/Room_gate_outpost")
		gate_button._drop_data(Vector2.ZERO, {"kind": "v20_facility", "facility_id": "v20_barricade"})
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(str(board.placement_state.get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "v20_barricade", "시설 drag가 gate_outpost의 실제 placement state 변경")
	_expect(board.get_node_or_null("PlacementToolTray/SectionSummary/MoveFacilityButton") != null and board.get_node_or_null("PlacementToolTray/SectionSummary/RemoveFacilityButton") != null and board.get_node_or_null("PlacementToolTray/SectionSummary/ReplaceFacilityButton") != null, "배치된 시설 선택 시 이동·제거·교체 행동만 표시")
	var slime_button = board.get_node_or_null("PlacementToolTray/MonsterTool_slime")
	var payload = slime_button.drag_payload() if slime_button != null else {}
	board._on_tool_drag_started("v20_monster", "slime")
	spike_button = board.get_node_or_null("RouteMap/Room_spike_corridor")
	_expect(spike_button != null and spike_button._can_drop_data(Vector2.ZERO, payload), "빈 spike_corridor 몬스터 슬롯은 portrait drop 허용")
	if spike_button != null:
		spike_button._drop_data(Vector2.ZERO, payload)
	await get_tree().process_frame
	_expect(str(board.placement_state.get("roster", {}).get("slime", {}).get("room_id", "")) == "spike_corridor" and str(board.placement_state.get("roster", {}).get("slime", {}).get("monster_slot_id", "")) == "spike_corridor_monster_1", "UI drop이 방 ID와 슬롯 ID를 함께 변경")
	var slime_location: Label = board.get_node_or_null("PlacementToolTray/MonsterTool_slime/Location")
	var spike_monster_name: Label = board.get_node_or_null("RouteMap/Room_spike_corridor/MonsterTokenFrame_slime/MonsterName_slime")
	_expect(slime_location != null and "가시 회랑" in slime_location.text and board.get_node_or_null("RouteMap/Room_spike_corridor/MonsterTokenFrame_slime/MonsterToken_slime") != null and spike_monster_name != null and spike_monster_name.text == "슬라임", "몬스터 배치 완료 시 도구 위치와 방 카드 초상·이름 동시 갱신")
	board._on_room_clicked("central_arena")
	await get_tree().process_frame
	_expect(board._map_rect.is_equal_approx(map_rect_before) and board.get_node_or_null("RoomInspector") == null, "방 선택 전후 지도 rect 고정·상시 대형 inspector 없음")
	host.queue_free()
	await get_tree().process_frame


func _test_board_facility_actions() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var board = BoardScene.instantiate()
	host.add_child(board)
	await get_tree().process_frame
	board.setup(_initial_state(), DataRegistry.v20_facilities, _board())
	board._on_facility_dropped("v20_barricade", "gate_outpost")
	await get_tree().process_frame
	board._on_facility_clicked("v20_barracks")
	await get_tree().process_frame
	board._on_room_clicked("gate_outpost")
	await get_tree().process_frame
	_expect(board.get_node_or_null("RouteMap/ReplacementConfirm") != null and _named_node_count(board, "ReplacementConfirm") == 1, "기존 시설 위 배치 시 교체 확인 한 번만 표시")
	board._on_cancel_replacement()
	await get_tree().process_frame
	board.selected_room_id = "gate_outpost"
	board._on_begin_facility_move()
	await get_tree().process_frame
	board._on_room_clicked("spike_corridor")
	await get_tree().process_frame
	_expect(str(board.placement_state.get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "" and str(board.placement_state.get("rooms", {}).get("spike_corridor", {}).get("facility_id", "")) == "v20_barricade", "시설 이동 행동이 선택한 빈 슬롯으로 반영")
	board._on_remove_facility()
	await get_tree().process_frame
	_expect(str(board.placement_state.get("rooms", {}).get("spike_corridor", {}).get("facility_id", "")) == "" and int(board.placement_state.get("build_points", -1)) == 10, "시설 제거 행동이 슬롯과 건설 자원에 반영")
	board.undo_last()
	await get_tree().process_frame
	_expect(str(board.placement_state.get("rooms", {}).get("spike_corridor", {}).get("facility_id", "")) == "v20_barricade" and int(board.placement_state.get("build_points", -1)) == 7, "하단 되돌리기 호출이 제거 전 시설·자원을 복원")
	host.queue_free()
	await get_tree().process_frame


func _capture_placement_flow(viewport_size: Vector2i) -> void:
	var capture_viewport := SubViewport.new()
	capture_viewport.size = viewport_size
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(capture_viewport)
	var background := ColorRect.new()
	background.size = viewport_size
	background.color = Color("#07060b")
	capture_viewport.add_child(background)
	var hud = HUDScene.instantiate()
	capture_viewport.add_child(hud)
	await get_tree().process_frame
	var placement_state := _initial_state()
	hud.setup("management", _placement_hud_state(placement_state))
	var board = hud.show_placement_board(placement_state, DataRegistry.v20_facilities, _board())
	board.state_changed.connect(func(state: Dictionary, _result: Dictionary): _sync_capture_hud(hud, state))
	await get_tree().create_timer(0.2).timeout
	var size_suffix := "%dx%d" % [viewport_size.x, viewport_size.y]
	await _save_capture(capture_viewport, "v20_room_route_placement_initial_%s.png" % size_suffix, "실제 방 동선 배치 초기 렌더")
	board._on_facility_dropped("v20_barricade", "gate_outpost")
	await get_tree().process_frame
	board._on_tool_drag_started("v20_facility", "v20_barricade")
	await get_tree().process_frame
	await _save_capture(capture_viewport, "v20_room_route_placement_drag_%s.png" % size_suffix, "시설 drag 강조 실제 렌더")
	var invalid_button
	for room_id_value in board.placement_state.get("rooms", {}).keys():
		var room_button = board.get_node_or_null("RouteMap/Room_%s" % str(room_id_value))
		if room_button != null and not bool(room_button.valid_target):
			invalid_button = room_button
			break
	if invalid_button != null:
		invalid_button._can_drop_data(Vector2.ZERO, {"kind": "v20_facility", "facility_id": "v20_barricade"})
	board._on_tool_drag_finished()
	await get_tree().process_frame
	await get_tree().process_frame
	await _save_capture(capture_viewport, "v20_room_route_placement_rejected_%s.png" % size_suffix, "잘못된 drop 토스트 실제 렌더")
	board._on_monster_dropped("slime", "spike_corridor")
	await get_tree().create_timer(0.2).timeout
	await _save_capture(capture_viewport, "v20_room_route_placement_applied_%s.png" % size_suffix, "시설·몬스터 배치 실제 렌더")
	capture_viewport.queue_free()
	await get_tree().process_frame


func _capture_three_slot_card() -> void:
	var capture_viewport := SubViewport.new()
	capture_viewport.size = Vector2i(280, 160)
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(capture_viewport)
	var background := ColorRect.new()
	background.size = capture_viewport.size
	background.color = Color("#07060b")
	capture_viewport.add_child(background)
	var button = RoomButtonScript.new()
	button.position = Vector2(27, 22)
	button.size = Vector2(226, 116)
	button.setup("three_slot_capture", "중앙 전투실\n◇ 회복 둥지\n수비대 3/3", _three_monster_tokens(), 3)
	button.setup_visual(true, false, true, UITheme.COLOR_GOLD)
	capture_viewport.add_child(button)
	await get_tree().create_timer(0.2).timeout
	await _save_capture(capture_viewport, "v20_monster_card_three_slots_280x160.png", "정원 3명 방 카드 실제 렌더")
	capture_viewport.queue_free()
	await get_tree().process_frame


func _save_capture(capture_viewport: SubViewport, filename: String, message: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "user://%s" % filename
	var error := capture_viewport.get_texture().get_image().save_png(path)
	_expect(error == OK, message)
	if error == OK:
		print("V20_U2_PLACEMENT_CAPTURE: %s" % ProjectSettings.globalize_path(path))


func _placement_hud_state(placement_state: Dictionary) -> Dictionary:
	var validation := DayFlowService.validate_defense_placement(placement_state, DataRegistry.v20_facilities)
	return {
		"day": 3,
		"flow_state": "PLACEMENT",
		"intrusion_title": "핵심 시설 무력화",
		"intrusion_warning": "공병이 먼저 활성화된 시설을 무력화합니다.",
		"resources": {"build": int(placement_state.get("build_points", 0)), "command": 3, "command_max": 3},
		"placement_valid": bool(validation.get("ok", false)),
		"placement_errors": validation.get("errors", []).duplicate(),
		"placement_can_undo": not placement_state.get("undo", {}).is_empty()
	}


func _sync_capture_hud(hud: Control, placement_state: Dictionary) -> void:
	var validation := DayFlowService.validate_defense_placement(placement_state, DataRegistry.v20_facilities)
	hud.update_placement_status(bool(validation.get("ok", false)), validation.get("errors", []), not placement_state.get("undo", {}).is_empty(), int(placement_state.get("build_points", 0)))


func _named_node_count(node: Node, node_name: String) -> int:
	var count := 1 if node.name == node_name else 0
	for child in node.get_children():
		count += _named_node_count(child, node_name)
	return count


func _initial_state() -> Dictionary:
	return SessionService.initial_placement_state(10)


func _board() -> Dictionary:
	return DataRegistry.v20_dungeon_layouts.get("v20_day_01_05_board", {}).duplicate(true)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20PlacementUX] FAIL: %s" % message)
