extends Node

const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const BoardScene = preload("res://scenes/v20/placement/V20PlacementBoard.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_rule_catalog()
	_test_facility_install_replace_undo()
	_test_monster_placement_inputs()
	_test_save_round_trip()
	await _test_board_interactions()
	if OS.get_cmdline_user_args().has("--capture-v20-placement") and DisplayServer.get_name() != "headless":
		await _capture_board()
	if failed:
		print("V20_PLACEMENT_UX_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_PLACEMENT_UX_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_rule_catalog() -> void:
	var rules := DataRegistry.v20_placement_rules
	_expect(int(rules.get("schema_version", 0)) == 2, "직접 배치 규칙 schema 2 로드")
	_expect(str(rules.get("facility_install", {}).get("primary_input", "")) == "facility_drag_to_slot", "시설 drag 기본 입력 계약")
	_expect(int(rules.get("facility_install", {}).get("new_install_interactions", 0)) == 1, "시설 drag 신규 설치 1동작 계약")
	_expect(int(rules.get("facility_install", {}).get("replacement_interactions", 0)) == 2, "시설 drag 교체 2동작 계약")
	_expect(int(rules.get("facility_install", {}).get("accessible_new_install_interactions", 0)) == 2, "시설 클릭 접근성 2동작 계약")
	_expect(str(rules.get("monster_placement", {}).get("primary_input", "")) == "portrait_drag_to_room", "몬스터 drag 기본 입력 계약")


func _test_facility_install_replace_undo() -> void:
	var state := _initial_state()
	var installed := PlacementService.place_facility_drag(state, "v20_barricade", "north_gate", _facilities())
	state = installed.get("state", {})
	_expect(bool(installed.get("ok", false)) and str(installed.get("status", "")) == PlacementService.STATUS_INSTALLED, "빈 슬롯 drag 즉시 설치")
	_expect(str(state.get("rooms", {}).get("north_gate", {}).get("facility_id", "")) == "v20_barricade" and int(state.get("build_points", 0)) == 7, "신규 설치 자원·시설 반영")
	_expect(int(state.get("last_action", {}).get("interaction_count", 0)) == 1 and str(state.get("last_action", {}).get("input", "")) == "drag", "시설→지도 drag 정확히 1동작")
	var undone := PlacementService.undo(state)
	state = undone.get("state", {})
	_expect(str(undone.get("status", "")) == PlacementService.STATUS_UNDONE and str(state.get("rooms", {}).get("north_gate", {}).get("facility_id", "")) == "" and int(state.get("build_points", 0)) == 10, "한 단계 Undo가 시설·자원 복원")
	_expect(not bool(PlacementService.undo(state).get("ok", true)), "Undo 깊이 1회 제한")

	var selected := PlacementService.select_facility(state, "v20_barricade", _facilities())
	installed = PlacementService.place_selected_facility(selected.get("state", {}), "north_gate", _facilities())
	state = installed.get("state", {})
	_expect(int(state.get("last_action", {}).get("interaction_count", 0)) == 2 and str(state.get("last_action", {}).get("input", "")) == "click_click", "시설 클릭→지도 클릭 접근성 2동작")
	var pending := PlacementService.place_facility_drag(state, "v20_barracks", "north_gate", _facilities())
	var pending_state: Dictionary = pending.get("state", {})
	_expect(str(pending.get("status", "")) == PlacementService.STATUS_CONFIRMATION_REQUIRED, "기존 시설 drag 교체는 확인 대기")
	_expect(str(pending_state.get("rooms", {}).get("north_gate", {}).get("facility_id", "")) == "v20_barricade", "확인 전 원본 시설 불변")
	_expect(int(pending_state.get("pending_replacement", {}).get("resource_loss", 0)) == 3, "교체 확인에 자원 손실 명시")
	var replaced := PlacementService.confirm_replacement(pending_state, _facilities())
	state = replaced.get("state", {})
	_expect(str(replaced.get("status", "")) == PlacementService.STATUS_REPLACED and str(state.get("rooms", {}).get("north_gate", {}).get("facility_id", "")) == "v20_barracks", "두 번째 확인 뒤 교체")
	_expect(int(state.get("last_action", {}).get("interaction_count", 0)) == 2 and str(state.get("last_action", {}).get("input", "")) == "drag", "drag 교체 정확히 2동작")
	state = PlacementService.undo(state).get("state", {})
	_expect(str(state.get("rooms", {}).get("north_gate", {}).get("facility_id", "")) == "v20_barricade" and int(state.get("build_points", 0)) == 7, "교체 Undo가 이전 시설·자원 복원")
	var flexible_state := _initial_state()
	var flexible := PlacementService.place_facility_drag(flexible_state, "v20_recovery_nest", "north_gate", _facilities())
	_expect(bool(flexible.get("ok", false)) and str(flexible.get("status", "")) == PlacementService.STATUS_INSTALLED, "같은 고정 위치에서도 다른 시설 전략 선택 가능")


func _test_monster_placement_inputs() -> void:
	var state := _initial_state()
	var drag := PlacementService.place_monster_drag(state, "slime_01", "fallback")
	state = drag.get("state", {})
	_expect(bool(drag.get("ok", false)) and int(state.get("last_action", {}).get("interaction_count", 0)) == 1 and str(state.get("last_action", {}).get("input", "")) == "drag", "초상→방 drag 1동작")
	_expect(not state.get("rooms", {}).get("north_gate", {}).get("monster_ids", []).has("slime_01") and state.get("rooms", {}).get("fallback", {}).get("monster_ids", []).has("slime_01"), "drag 이동 시 이전 방 제거·새 방 배치")
	var selected := PlacementService.select_monster(state, "goblin_01")
	var clicked := PlacementService.place_selected_monster(selected.get("state", {}), "south_gate")
	state = clicked.get("state", {})
	_expect(bool(clicked.get("ok", false)) and int(state.get("last_action", {}).get("interaction_count", 0)) == 2 and str(state.get("last_action", {}).get("input", "")) == "click_click", "클릭→클릭 접근성 2동작")
	state = PlacementService.place_monster_drag(state, "imp_01", "south_gate").get("state", {})
	var full := PlacementService.place_monster_drag(state, "slime_01", "south_gate")
	_expect(not bool(full.get("ok", true)) and str(full.get("status", "")) == "room_full", "방 정원 초과 drag 거부")
	_expect(bool(PlacementService.validate_state(state).get("ok", false)), "몬스터 중복 없는 placement state")


func _test_save_round_trip() -> void:
	var state := _initial_state()
	state = PlacementService.place_facility_drag(state, "v20_barricade", "north_gate", _facilities()).get("state", {})
	state = PlacementService.place_monster_drag(state, "goblin_01", "fallback").get("state", {})
	var encoded := JSON.stringify(PlacementService.serialize(state))
	var decoded = JSON.parse_string(encoded)
	var restored := PlacementService.restore(decoded)
	_expect(bool(restored.get("ok", false)), "placement JSON 저장 복원 승인")
	var restored_state: Dictionary = restored.get("state", {})
	_expect(
		int(restored_state.get("build_points", -1)) == int(state.get("build_points", -2))
		and str(restored_state.get("rooms", {}).get("north_gate", {}).get("facility_id", "")) == "v20_barricade"
		and str(restored_state.get("roster", {}).get("goblin_01", {}).get("room_id", "")) == "fallback",
		"시설·몬스터·자원 저장 왕복 무손실"
	)
	_expect(restored.get("state", {}).get("placement_session", {}).is_empty() and restored.get("state", {}).get("undo", {}).is_empty(), "임시 선택·Undo는 저장에 혼입되지 않음")


func _test_board_interactions() -> void:
	var host := Control.new()
	host.size = Vector2(1180, 560)
	add_child(host)
	var board = BoardScene.instantiate()
	host.add_child(board)
	await get_tree().process_frame
	board.setup(_initial_state(), _facilities())
	await get_tree().process_frame
	var room_button: Button = board.get_node_or_null("RouteMap/Room_north_gate")
	_expect(room_button != null, "확정 침입로 위에 직접 배치 가능한 성문 전초")
	_expect(str(board.board_data.get("background_path", "")) == "res://assets/sprites/dungeon_gpt2/gpt2_dungeon_connected_map.png" and str(board.board_data.get("route_mode", "")) == "fixed", "우리 마왕성 배경과 고정 경로 데이터 사용")
	var facility_button: Button = board.get_node_or_null("PlacementToolTray/FacilityTool_v20_barricade")
	_expect(facility_button != null, "별도 설정 패널 없이 기본 건설 도구가 즉시 노출")
	_expect(facility_button != null and "적 감속" in facility_button.text, "시설 카드에서 설치 전 핵심 전투 효과 확인")
	if facility_button != null:
		facility_button.pressed.emit()
	await get_tree().process_frame
	_expect("배치 예정" in board._section_effect_summary("north_gate") and "교전 시간을 늘립니다" in board._section_effect_summary("north_gate"), "시설 선택 즉시 구역 조합 효과 미리보기")
	_expect(board.get_node_or_null("PlacementToolTray/MonsterTool_slime_01") == null, "건설 중 몬스터 카드를 숨겨 한 위치 한 기능 유지")
	var monster_mode: Button = board.get_node_or_null("PlacementToolTray/MonsterMode")
	_expect(monster_mode != null and board.get_node_or_null("PlacementToolTray/FacilityMode") != null, "오른쪽 건설·몬스터 배치 두 도구 고정")
	if monster_mode != null:
		monster_mode.pressed.emit()
	await get_tree().process_frame
	_expect(board.get_node_or_null("PlacementToolTray/MonsterTool_slime_01") != null and board.get_node_or_null("PlacementToolTray/FacilityTool_v20_barricade") == null, "몬스터 도구 선택 시 배치 대상만 노출")
	var points_before_stale_drop := int(board.placement_state.get("build_points", 0))
	board._on_facility_dropped("v20_barricade", "north_gate")
	await get_tree().process_frame
	_expect(int(board.placement_state.get("build_points", 0)) == points_before_stale_drop and str(board.active_tool) == "monster", "도구 전환 뒤 남은 시설 drag 이벤트가 몬스터 배치를 침범하지 않음")
	var facility_mode: Button = board.get_node_or_null("PlacementToolTray/FacilityMode")
	if facility_mode != null:
		facility_mode.pressed.emit()
	await get_tree().process_frame
	_expect(board.get_node_or_null("FacilityPalette") == null, "상시 건물 설정 palette 제거")
	var map_rect_before_select: Rect2 = board._map_rect
	room_button = board.get_node_or_null("RouteMap/Room_north_gate")
	if room_button != null:
		room_button.pressed.emit()
	await get_tree().process_frame
	_expect(board.get_node_or_null("PlacementToolTray/SectionSummary") != null and board.selected_room_id == "north_gate", "위치 선택 시 오른쪽 도구함 안에서만 효과 설명 갱신")
	_expect(board._map_rect == map_rect_before_select and board.get_node_or_null("RoomInspector") == null, "위치 설명 전후 마왕성 지도 크기 고정")
	_expect(str(board.current_route.get("route_mode", "")) == "fixed" and str(board.current_route.get("first_engagement_node", "")) == "north_gate", "첫 교전 구간이 성문 전초로 확정")
	var route_signature_before := str(board.current_route.get("signature", ""))
	room_button = board.get_node_or_null("RouteMap/Room_north_gate")
	if room_button != null:
		room_button._drop_data(Vector2.ZERO, {"kind": "v20_facility", "facility_id": "v20_barricade"})
	await get_tree().process_frame
	_expect(str(board.placement_state.get("rooms", {}).get("north_gate", {}).get("facility_id", "")) == "v20_barricade", "UI 시설→성문 전초 drag 즉시 설치")
	_expect(str(board.current_route.get("signature", "")) == route_signature_before and str(board.current_route.get("first_engagement_node", "")) == "north_gate", "시설 설치 뒤에도 확정 침입로 불변")
	_expect(board.get_node_or_null("PlacementToolTray/UndoPlacement") != null, "설치 직후 같은 도구함에 Undo 노출")
	monster_mode = board.get_node_or_null("PlacementToolTray/MonsterMode")
	if monster_mode != null:
		monster_mode.pressed.emit()
	await get_tree().process_frame
	var fallback_button = board.get_node_or_null("RouteMap/Room_fallback")
	if fallback_button != null:
		fallback_button._drop_data(Vector2.ZERO, {"kind": "v20_monster", "monster_id": "slime_01"})
	await get_tree().process_frame
	_expect(str(board.placement_state.get("roster", {}).get("slime_01", {}).get("room_id", "")) == "fallback", "UI drop target이 monster drag 적용")
	host.queue_free()
	await get_tree().process_frame


func _capture_board() -> void:
	var capture_viewport := SubViewport.new()
	capture_viewport.size = Vector2i(1280, 720)
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(capture_viewport)
	var board = BoardScene.instantiate()
	capture_viewport.add_child(board)
	await get_tree().process_frame
	board.setup(_initial_state(), _facilities())
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := capture_viewport.get_texture().get_image()
	var path := "user://v20_phase11s_fixed_castle_board_1280x720.png"
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_expect(error == OK, "Phase 11S 고정 마왕성 배치 보드 1280x720 실제 렌더")
	if error == OK:
		print("V20_PHASE11_CAPTURE: %s" % ProjectSettings.globalize_path(path))
	capture_viewport.queue_free()
	await get_tree().process_frame


func _initial_state() -> Dictionary:
	return PlacementService.new_state(10, {
		"north_gate": {"display_name": "1 · 성문 전초", "section_index": 1, "strategy_hint": "첫 교전", "placement_tags": ["door", "corridor", "room", "bait", "recovery", "overlook"], "facility_id": "", "capacity": 2, "monster_ids": ["slime_01"]},
		"south_gate": {"display_name": "2 · 가시 회랑", "section_index": 2, "strategy_hint": "함정 집중", "placement_tags": ["door", "corridor", "room", "bait", "recovery", "overlook"], "facility_id": "", "capacity": 2, "monster_ids": []},
		"treasure": {"display_name": "3 · 중앙 전투실", "section_index": 3, "strategy_hint": "중앙 교전", "placement_tags": ["door", "corridor", "room", "bait", "recovery", "overlook"], "facility_id": "", "capacity": 2, "monster_ids": []},
		"fallback": {"display_name": "4 · 왕좌 전실", "section_index": 4, "strategy_hint": "최종 방어", "placement_tags": ["door", "corridor", "room", "bait", "recovery", "overlook"], "facility_id": "", "capacity": 2, "monster_ids": ["imp_01"]}
	}, {
		"slime_01": {"display_name": "슬라임", "room_id": "north_gate"},
		"goblin_01": {"display_name": "고블린", "room_id": ""},
		"imp_01": {"display_name": "임프", "room_id": "fallback"}
	})


func _facilities() -> Dictionary:
	return {
		"v20_barricade": {"display_name": "바리케이드", "placement_tags": ["door"], "cost": {"build": 3}, "combat_effect": {"enemy_slow_multiplier": 0.78}},
		"v20_barracks": {"display_name": "병영", "placement_tags": ["door", "room"], "cost": {"build": 4}, "combat_effect": {"monster_damage_multiplier": 1.12}},
		"v20_recovery_nest": {"display_name": "회복 둥지", "placement_tags": ["recovery"], "cost": {"build": 4}, "combat_effect": {"heal_per_second": 8}}
	}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20PlacementUX] FAIL: %s" % message)
