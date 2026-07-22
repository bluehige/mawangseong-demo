extends Node

const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const SessionService = preload("res://scripts/v20/session/V20SessionService.gd")
const BoardScene = preload("res://scenes/v20/placement/V20PlacementBoard.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_rule_catalog()
	_test_facility_install_replace_undo()
	_test_remove_move_and_budget_recalculation()
	_test_monster_slots_and_round_trip()
	await _test_board_interactions()
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
	var facility_button = board.get_node_or_null("PlacementToolTray/FacilityTool_v20_barricade")
	if facility_button != null:
		board._on_tool_drag_started("v20_facility", "v20_barricade")
		gate_button._drop_data(Vector2.ZERO, {"kind": "v20_facility", "facility_id": "v20_barricade"})
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(str(board.placement_state.get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "v20_barricade", "시설 drag가 gate_outpost의 실제 placement state 변경")
	var slime_button = board.get_node_or_null("PlacementToolTray/MonsterTool_slime")
	var payload = slime_button.drag_payload() if slime_button != null else {}
	board._on_tool_drag_started("v20_monster", "slime")
	spike_button = board.get_node_or_null("RouteMap/Room_spike_corridor")
	_expect(spike_button != null and spike_button._can_drop_data(Vector2.ZERO, payload), "빈 spike_corridor 몬스터 슬롯은 portrait drop 허용")
	if spike_button != null:
		spike_button._drop_data(Vector2.ZERO, payload)
	await get_tree().process_frame
	_expect(str(board.placement_state.get("roster", {}).get("slime", {}).get("room_id", "")) == "spike_corridor" and str(board.placement_state.get("roster", {}).get("slime", {}).get("monster_slot_id", "")) == "spike_corridor_monster_1", "UI drop이 방 ID와 슬롯 ID를 함께 변경")
	host.queue_free()
	await get_tree().process_frame


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
