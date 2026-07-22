extends Node

const Validator = preload("res://scripts/v20/contracts/V20ContractValidator.gd")
const FixedRouteService = preload("res://scripts/v20/path/V20FixedRouteService.gd")
const PathService = preload("res://scripts/v20/path/V20WeightedPathService.gd")
const RoomGraphScript = preload("res://scripts/map/RoomGraph.gd")
const RoutePreviewScene = preload("res://scenes/v20/path/V20RoutePreview.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_board_contract()
	_test_runtime_layout()
	_test_weighted_costs_and_legacy_adapter()
	_test_three_strategic_placements()
	await _test_route_preview()
	if failed:
		print("V20_STRATEGIC_ROUTING_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_STRATEGIC_ROUTING_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_board_contract() -> void:
	var board := _board()
	var validation := Validator.validate_catalog("path", {"v20_day_01_05_board": board})
	_expect(bool(validation.get("ok", false)), "DAY 1~5 공간 계약 검증: %s" % [validation.get("errors", [])])
	var section_ids: Array = board.get("ordered_sections", []).map(func(section): return str(section.get("placement_id", "")))
	_expect(section_ids == ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom"], "배치 구역은 계약된 방어 구역 4개")
	_expect(board.get("fixed_route", {}).get("nodes", []) == ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom", "throne"], "침입 경로는 성문 전초부터 왕좌까지 5개 구역")
	_expect(board.get("weight_terms", []) == PathService.COST_KEYS, "경로 비용 항목 6개가 런타임 계산과 일치")


func _test_runtime_layout() -> void:
	var layout := DataRegistry.quarter_layout(DataRegistry.V20_RUNTIME_LAYOUT_ID)
	var route: Array = layout.get("canonical_route", {}).get("nodes", [])
	var main_route: Array = layout.get("combat_role_contract", {}).get("main_route", [])
	_expect(route == ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom", "throne"], "준비 화면과 전투가 같은 canonical_route 사용")
	_expect(main_route.has("path_central_battle_room_throne_anteroom") and main_route.has("path_throne_anteroom_throne"), "중앙 전투실→왕좌 전실→왕좌 연결 모듈 존재")
	_expect(layout.get("canonical_zones", {}).has("throne_anteroom") and layout.get("canonical_zones", {}).get("throne_anteroom", {}).get("monster_slots", []).size() == 2, "왕좌 전실은 몬스터 슬롯 2개를 가진 독립 전투 구역")


func _test_weighted_costs_and_legacy_adapter() -> void:
	var board := _board()
	var context := {
		"seed": 20260721,
		"door_state_costs": {"gate_outpost_facility": 12.0},
		"facility_route_costs": {"spike_corridor_facility": 2.0},
		"temporary_hazard_costs": {"throne_anteroom_to_throne": 1.5},
		"enemy_role_preferences": {"section_3": 0.5},
		"goal_key": "throne",
		"goal_preference": -1.0
	}
	var route := PathService.find_path(board, "gate_outpost", "throne", context)
	var declared_nodes: Array = board.get("fixed_route", {}).get("nodes", [])
	_expect(bool(route.get("ok", false)) and route.get("nodes", []) == declared_nodes, "시설·위험 비용이 있어도 선언된 침입 순서를 유지")
	_expect(str(route.get("first_engagement_node", "")) == "gate_outpost", "첫 교전 구역은 gate_outpost")
	var breakdown: Dictionary = route.get("cost_breakdown", {})
	var total := 0.0
	for key in PathService.COST_KEYS:
		total += float(breakdown.get(key, 0.0))
	_expect(breakdown.keys().size() == 6 and is_equal_approx(total, float(route.get("total_cost", -1.0))), "6개 비용 항목의 합이 total_cost와 일치")
	_expect(route == PathService.find_path(board, "gate_outpost", "throne", context), "같은 board·배치·seed는 같은 경로 결과 생성")
	var fixed := FixedRouteService.full_route(board)
	_expect(bool(fixed.get("ok", false)) and fixed.get("nodes", []) == declared_nodes, "고정 경로 서비스가 전체 선언 순서 반환")

	var legacy := RoomGraphScript.new()
	legacy.setup({
		"a": {"center": [0, 0], "rect": [0, 0, 10, 10], "exits": ["b"]},
		"b": {"center": [10, 0], "rect": [10, 0, 10, 10], "exits": ["a", "c"]},
		"c": {"center": [20, 0], "rect": [20, 0, 10, 10], "exits": ["b"]}
	})
	_expect(legacy.path_between("a", "c") == ["a", "b", "c"], "제품 1.x BFS 경로 계약 유지")
	var adapted := legacy.weighted_path(board, "gate_outpost", "throne", {"seed": 1, "goal_key": "throne"})
	_expect(bool(adapted.get("ok", false)) and adapted.get("nodes", []) == declared_nodes, "RoomGraph adapter도 canonical route 사용")


func _test_three_strategic_placements() -> void:
	var board := _board()
	var placements := [
		{"id": "front_barricade", "facility_route_costs": {"gate_outpost_facility": 12.0}},
		{"id": "corridor_barricade", "facility_route_costs": {"spike_corridor_facility": 12.0}},
		{"id": "central_decoy", "facility_route_costs": {"section_3": 3.0}}
	]
	var defender := {"role": "explorer", "candidate_goals": ["throne"], "goal_preferences": {"throne": 0.0}, "route_tag_costs": {}}
	var routes := PathService.predict_routes(board, placements.slice(0, 2), defender, 20260721)
	var thief := {"role": "thief", "candidate_goals": ["throne", "central_battle_room"], "goal_preferences": {"throne": 0.0, "central_battle_room": -4.0}, "route_tag_costs": {}}
	var decoy_route := PathService.predict_routes(board, [placements[2]], thief, 20260721)[0]
	var declared_nodes: Array = board.get("fixed_route", {}).get("nodes", [])
	_expect(routes.all(func(value): return value.get("nodes", []) == declared_nodes), "서로 다른 두 시설 슬롯 비용도 왕좌 경로 순서를 바꾸지 않음")
	var central_index := declared_nodes.find("central_battle_room")
	_expect(str(decoy_route.get("goal_key", "")) == "central_battle_room" and decoy_route.get("nodes", []) == declared_nodes.slice(0, central_index + 1), "미끼 목표는 중앙 전투실까지의 canonical prefix 사용")
	_expect(routes.all(func(value): return str(value.get("first_engagement_node", "")) == "gate_outpost"), "모든 왕좌 경로의 첫 교전은 gate_outpost")


func _test_route_preview() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var preview = RoutePreviewScene.instantiate()
	host.add_child(preview)
	await get_tree().process_frame
	var route := PathService.find_path(_board(), "gate_outpost", "throne", {"seed": 7, "goal_key": "throne"})
	preview.setup(_board(), route)
	await get_tree().process_frame
	_expect(preview.get_node_or_null("NodeLabel_gate_outpost") != null and preview.get_node_or_null("NodeLabel_spike_corridor") != null, "경로 미리보기에 1·2구역 canonical node 표시")
	host.queue_free()
	await get_tree().process_frame


func _board() -> Dictionary:
	return DataRegistry.v20_dungeon_layouts.get("v20_day_01_05_board", {}).duplicate(true)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20StrategicRouting] FAIL: %s" % message)
