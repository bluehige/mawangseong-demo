extends Node

const Validator = preload("res://scripts/v20/contracts/V20ContractValidator.gd")
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
	_expect(bool(validation.get("ok", false)), "DAY 1~5 weighted path catalog 승인: %s" % [validation.get("errors", [])])
	_expect(board.get("defense_lines", {}).size() == 3 and board.get("goal_nodes", {}).size() == 3, "두 경로·전중후 3개 방어선·3개 목표")
	_expect(board.get("weight_terms", []) == PathService.COST_KEYS, "승인된 6개 비용 항과 runtime 일치")


func _test_weighted_costs_and_legacy_adapter() -> void:
	var board := _board()
	var context := {
		"seed": 20260721,
		"door_state_costs": {"door_north": 12.0},
		"facility_route_costs": {"south_watch_slot": 2.0},
		"temporary_hazard_costs": {"south_fallback": 1.5},
		"enemy_role_preferences": {"south": 0.5},
		"goal_key": "throne",
		"goal_preference": -1.0
	}
	var route := PathService.find_path(board, "entrance", "throne", context)
	_expect(bool(route.get("ok", false)) and str(route.get("first_engagement_node", "")) == "south_gate", "북문 비용 증가가 남문 경로·첫 교전으로 전환")
	var breakdown: Dictionary = route.get("cost_breakdown", {})
	_expect(breakdown.keys().size() == 6 and breakdown.keys().all(func(key): return PathService.COST_KEYS.has(key)), "결과에 6개 비용 항 전부 기록")
	var total := 0.0
	for key in PathService.COST_KEYS:
		total += float(breakdown.get(key, 0.0))
	_expect(is_equal_approx(total, float(route.get("total_cost", -1.0))), "경로 총비용과 항목 합 일치")
	var same := PathService.find_path(board, "entrance", "throne", context)
	_expect(route == same, "같은 board·배치·seed 동일 경로 재현")

	var legacy := RoomGraphScript.new()
	legacy.setup({
		"a": {"center": [0, 0], "rect": [0, 0, 10, 10], "exits": ["b"]},
		"b": {"center": [10, 0], "rect": [10, 0, 10, 10], "exits": ["a", "c"]},
		"c": {"center": [20, 0], "rect": [20, 0, 10, 10], "exits": ["b"]}
	})
	_expect(legacy.path_between("a", "c") == ["a", "b", "c"], "기존 BFS 경로 계약 불변")
	var adapted := legacy.weighted_path(board, "entrance", "throne", {"seed": 1, "goal_key": "throne"})
	_expect(bool(adapted.get("ok", false)), "RoomGraph v2 weighted adapter 연결")


func _test_three_strategic_placements() -> void:
	var board := _board()
	var placements := [
		{"id": "north_barricade", "door_state_costs": {"door_north": 12.0}},
		{"id": "south_barricade", "door_state_costs": {"door_south": 12.0}},
		{"id": "treasure_decoy", "facility_route_costs": {"north": 3.0}}
	]
	var defender_contract := {"role": "explorer", "candidate_goals": ["throne"], "goal_preferences": {"throne": 0.0}, "route_tag_costs": {}}
	var routes := PathService.predict_routes(board, placements.slice(0, 2), defender_contract, 20260721)
	var thief_contract := {"role": "thief", "candidate_goals": ["throne", "treasure"], "goal_preferences": {"throne": 0.0, "treasure": -4.0}, "route_tag_costs": {"north": 3.0}}
	var decoy_route := PathService.predict_routes(board, [placements[2]], thief_contract, 20260721)[0]
	routes.append(decoy_route)
	var signatures: Dictionary = {}
	var engagements: Dictionary = {}
	for route_value in routes:
		var route: Dictionary = route_value
		signatures[str(route.get("signature", ""))] = true
		engagements[str(route.get("first_engagement_node", ""))] = true
	_expect(signatures.size() == 3, "세 배치가 세 개의 경로·목표 signature 생성")
	_expect(engagements.has("north_gate") and engagements.has("south_gate"), "세 배치가 북문·남문 첫 교전 모두 생성")
	_expect(str(routes[0].get("first_engagement_node", "")) == "south_gate" and str(routes[1].get("first_engagement_node", "")) == "north_gate" and str(routes[2].get("goal_key", "")) == "treasure", "차단·반대 차단·미끼의 전략 결과 구분")


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
	_expect(preview.get_node_or_null("RouteSummary") != null and preview.get_child_count() == _board().get("nodes", []).size() + 1, "예상 경로 summary와 8개 node label 렌더")
	_expect(preview.get_node_or_null("NodeLabel_south_gate") != null, "남문 예상 경로 node 표시")
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
	var path := "user://v20_phase4_route_1280x720.png"
	var error := image.save_png(path) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_expect(error == OK, "Phase 4 예상 경로 1280x720 실제 렌더")
	if error == OK:
		print("V20_PHASE4_CAPTURE: %s" % ProjectSettings.globalize_path(path))
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
