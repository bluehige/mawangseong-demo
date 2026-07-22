extends Node

const Validator = preload("res://scripts/v20/contracts/V20ContractValidator.gd")
const FixedRouteService = preload("res://scripts/v20/path/V20FixedRouteService.gd")
const PathService = preload("res://scripts/v20/path/V20WeightedPathService.gd")
const SessionService = preload("res://scripts/v20/session/V20SessionService.gd")
const RoomGraphScript = preload("res://scripts/map/RoomGraph.gd")
const RoutePreviewScene = preload("res://scenes/v20/path/V20RoutePreview.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_board_contract()
	_test_runtime_defense_stage_layout()
	_test_weighted_costs_and_legacy_adapter()
	_test_three_strategic_placements()
	await _test_route_preview()
	if OS.get_cmdline_user_args().has("--capture-v20-route") and DisplayServer.get_name() != "headless":
		await _capture_route()
	if failed:
		print("V20_STRATEGIC_ROUTING_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_STRATEGIC_ROUTING_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_board_contract() -> void:
	var board := _board()
	var validation := Validator.validate_catalog("path", {"v20_day_01_05_board": board})
	_expect(bool(validation.get("ok", false)), "DAY 1~5 고정 침입로 catalog 승인: %s" % [validation.get("errors", [])])
	_expect(str(board.get("route_mode", "")) == "fixed" and FileAccess.file_exists(str(board.get("background_path", ""))), "마왕성 배경과 고정 경로 모드 선언")
	var section_ids: Array = board.get("ordered_sections", []).map(func(section): return str(section.get("placement_id", "")))
	_expect(section_ids == ["north_gate", "south_gate", "treasure", "fallback"], "기존 배치 ID를 유지한 4개 순차 방어 구역")
	_expect(board.get("fixed_route", {}).get("nodes", []) == board.get("nodes", []), "입구부터 왕좌까지 하나의 전체 경로 선언")
	_expect(board.get("route_waypoints", []).size() >= board.get("ordered_sections", []).size() + 1, "마왕성 배경 길을 따르는 고정 침입로 waypoint 선언")
	_expect(board.get("defense_lines", {}).size() == 3 and board.get("goal_nodes", {}).size() == 3, "전중후 3개 방어선·고정 경로 위 3개 목표")
	_expect(board.get("weight_terms", []) == PathService.COST_KEYS, "승인된 6개 비용 항과 runtime 일치")


func _test_runtime_defense_stage_layout() -> void:
	var layout := DataRegistry.quarter_layout(DataRegistry.V20_FIXED_RUNTIME_LAYOUT_ID)
	var main_route: Array = layout.get("combat_role_contract", {}).get("main_route", [])
	var barracks_index := main_route.find("barracks")
	var fallback_index := main_route.find("fallback")
	var throne_index := main_route.find("throne")
	_expect(
		barracks_index >= 0 and fallback_index > barracks_index and throne_index > fallback_index
		and main_route.has("path_barracks_fallback") and main_route.has("path_fallback_throne")
		and not main_route.has("path_barracks_throne"),
		"실제 전투 레이아웃도 병영→왕좌 전실→왕좌를 순서대로 통과"
	)
	var placed_ids: Array = layout.get("placed_modules", []).map(func(module): return str(module.get("instance_id", "")))
	_expect(placed_ids.has("fallback") and placed_ids.has("path_barracks_fallback") and placed_ids.has("path_fallback_throne") and not placed_ids.has("path_barracks_throne"), "왕좌 직통 모듈 제거·전실 방과 두 관문 모듈 배치")
	_expect(SessionService.runtime_room_for_section("fallback") == "fallback", "왕좌 전실은 왕좌와 분리된 독립 runtime 방")


func _test_weighted_costs_and_legacy_adapter() -> void:
	var board := _board()
	var context := {
		"seed": 20260721,
		"door_state_costs": {"door_north": 12.0},
		"facility_route_costs": {"south_watch_slot": 2.0},
		"temporary_hazard_costs": {"fallback_throne": 1.5},
		"enemy_role_preferences": {"section_3": 0.5},
		"goal_key": "throne",
		"goal_preference": -1.0
	}
	var route := PathService.find_path(board, "entrance", "throne", context)
	var declared_nodes: Array = board.get("fixed_route", {}).get("nodes", [])
	_expect(bool(route.get("ok", false)) and route.get("nodes", []) == declared_nodes, "시설·위험 비용이 증가해도 선언된 침입로 유지")
	_expect(str(route.get("first_engagement_node", "")) == "north_gate", "첫 교전은 항상 1구역 성문 전초")
	var breakdown: Dictionary = route.get("cost_breakdown", {})
	_expect(breakdown.keys().size() == 6 and breakdown.keys().all(func(key): return PathService.COST_KEYS.has(key)), "결과에 6개 비용 항 전부 기록")
	var total := 0.0
	for key in PathService.COST_KEYS:
		total += float(breakdown.get(key, 0.0))
	_expect(is_equal_approx(total, float(route.get("total_cost", -1.0))), "경로 총비용과 항목 합 일치")
	var same := PathService.find_path(board, "entrance", "throne", context)
	_expect(route == same, "같은 board·배치·seed 동일 경로 재현")
	var fixed := FixedRouteService.route_to_goal(board, "entrance", "throne", "throne")
	_expect(bool(fixed.get("ok", false)) and fixed.get("nodes", []) == declared_nodes, "고정 경로 서비스가 선언 순서를 그대로 반환")

	var legacy := RoomGraphScript.new()
	legacy.setup({
		"a": {"center": [0, 0], "rect": [0, 0, 10, 10], "exits": ["b"]},
		"b": {"center": [10, 0], "rect": [10, 0, 10, 10], "exits": ["a", "c"]},
		"c": {"center": [20, 0], "rect": [20, 0, 10, 10], "exits": ["b"]}
	})
	_expect(legacy.path_between("a", "c") == ["a", "b", "c"], "기존 BFS 경로 계약 불변")
	var adapted := legacy.weighted_path(board, "entrance", "throne", {"seed": 1, "goal_key": "throne"})
	_expect(bool(adapted.get("ok", false)) and adapted.get("nodes", []) == declared_nodes, "RoomGraph v2 adapter도 고정 침입로 연결")


func _test_three_strategic_placements() -> void:
	var board := _board()
	var placements := [
		{"id": "north_barricade", "door_state_costs": {"door_north": 12.0}},
		{"id": "south_barricade", "door_state_costs": {"door_south": 12.0}},
		{"id": "treasure_decoy", "facility_route_costs": {"section_1": 3.0}}
	]
	var defender_contract := {"role": "explorer", "candidate_goals": ["throne"], "goal_preferences": {"throne": 0.0}, "route_tag_costs": {}}
	var routes := PathService.predict_routes(board, placements.slice(0, 2), defender_contract, 20260721)
	var thief_contract := {"role": "thief", "candidate_goals": ["throne", "treasure"], "goal_preferences": {"throne": 0.0, "treasure": -4.0}, "route_tag_costs": {"north": 3.0}}
	var decoy_route := PathService.predict_routes(board, [placements[2]], thief_contract, 20260721)[0]
	routes.append(decoy_route)
	var throne_signatures: Dictionary = {}
	var declared_nodes: Array = board.get("fixed_route", {}).get("nodes", [])
	for route_value in routes.slice(0, 2):
		var route: Dictionary = route_value
		throne_signatures[str(route.get("signature", ""))] = true
		_expect(route.get("nodes", []) == declared_nodes, "%s 배치가 왕좌 침입로를 바꾸지 않음" % str(route.get("placement_id", "")))
	_expect(throne_signatures.size() == 1, "서로 다른 시설 비용에도 왕좌 경로 signature 하나")
	var treasure_index := declared_nodes.find("treasure")
	_expect(str(decoy_route.get("goal_key", "")) == "treasure" and decoy_route.get("nodes", []) == declared_nodes.slice(0, treasure_index + 1), "미끼 목표는 같은 고정 길의 보물 구역 prefix 사용")
	_expect(routes.all(func(route): return str(route.get("first_engagement_node", "")) == "north_gate"), "모든 목표의 첫 교전은 성문 전초로 고정")


func _test_route_preview() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var preview = RoutePreviewScene.instantiate()
	host.add_child(preview)
	await get_tree().process_frame
	var route := PathService.find_path(_board(), "entrance", "throne", {"seed": 7, "door_state_costs": {"door_north": 12.0}, "goal_key": "throne"})
	preview.setup(_board(), route)
	await get_tree().process_frame
	var summary: Label = preview.get_node_or_null("RouteSummary")
	_expect(summary != null and summary.text.begins_with("확정 침입로") and preview.get_child_count() == _board().get("nodes", []).size() + 1, "확정 침입로 summary와 8개 node label 렌더")
	_expect(preview.get_node_or_null("NodeLabel_north_gate") != null and preview.get_node_or_null("NodeLabel_south_gate") != null, "고정 경로의 1·2구역 node 표시")
	host.queue_free()
	await get_tree().process_frame


func _capture_route() -> void:
	var capture_viewport := SubViewport.new()
	capture_viewport.size = Vector2i(1280, 720)
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(capture_viewport)
	var preview = RoutePreviewScene.instantiate()
	capture_viewport.add_child(preview)
	await get_tree().process_frame
	var route := PathService.find_path(_board(), "entrance", "throne", {"seed": 7, "door_state_costs": {"door_north": 12.0}, "goal_key": "throne"})
	preview.setup(_board(), route)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := capture_viewport.get_texture().get_image()
	var path := "user://v20_phase11s_fixed_route_1280x720.png"
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_expect(error == OK, "Phase 11S 확정 침입로 1280x720 실제 렌더")
	if error == OK:
		print("V20_PHASE11S_ROUTE_CAPTURE: %s" % ProjectSettings.globalize_path(path))
	capture_viewport.queue_free()
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
