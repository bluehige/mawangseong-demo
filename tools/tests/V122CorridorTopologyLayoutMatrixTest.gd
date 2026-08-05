extends Node

const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const CorridorTopologyBuilderScript = preload("res://scripts/dungeon_quarter/CorridorTopologyBuilder.gd")
const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const PRODUCT_LAYOUT_ID := "corridor_topology_matrix_product_01"
const PRODUCT_LAYOUT_PATH := "res://data/dungeon_quarter/layouts/stage01_dual_front_01.json"
const CUSTOM_LAYOUT_PATH := "res://data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json"

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var product_layout := _load_json(PRODUCT_LAYOUT_PATH)
	_expect(not product_layout.is_empty(), "제품 dual-front 레이아웃을 읽는다")
	if product_layout.is_empty():
		_finish()
		return

	var game := GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	DataRegistry.register_quarter_layout(PRODUCT_LAYOUT_ID, product_layout, false)
	game.quarter_layout_id = PRODUCT_LAYOUT_ID
	game.update3_active_run["update3_enabled"] = true
	game.update3_active_run["front_selection_completed"] = true
	game.update3_active_run["front_id"] = "corridor_topology_matrix"
	game.v122_connector_state = {"connector_id": "rear_cross_lane_connector", "built": false, "built_day": 0}

	var stages := [
		{"id": "stage_01_cave", "day": 1, "floor_mode": "stage_atlas"},
		{"id": "stage_02_castle", "day": 16, "floor_mode": "tile_variant_mask"},
		{"id": "stage_03_keep", "day": 21, "floor_mode": "tile_variant_mask"},
		{"id": "stage_04_citadel", "day": 30, "floor_mode": "tile_variant_mask"}
	]
	for stage_value in stages:
		var stage: Dictionary = stage_value
		game.castle_art_stage = str(stage["id"])
		GameState.day = int(stage["day"])
		game.rooms = DataRegistry.rooms.duplicate(true)
		game._sync_castle_stage_content()
		game._setup_dungeon_graph()
		game.quarter_renderer.refresh_layout()
		await _settle(2)
		_check_graph_topology(str(stage["id"]), game.graph)
		_check_renderer_profile(str(stage["id"]), str(stage["floor_mode"]), game)

	var custom_layout := _load_json(CUSTOM_LAYOUT_PATH)
	_expect(not custom_layout.is_empty(), "구조가 다른 분기형 사용자 맵 fixture를 읽는다")
	if not custom_layout.is_empty():
		var custom_graph = ModuleGraphScript.new()
		custom_graph.setup_quarter(DataRegistry.quarter_modules, custom_layout, DataRegistry.rooms)
		_check_graph_topology("role_driven_custom", custom_graph)

	game._shutdown_audio_for_exit()
	game.queue_free()
	await _settle(2)
	_finish()


func _check_graph_topology(label: String, graph) -> void:
	var validation: Dictionary = graph.validation_summary()
	_expect(bool(validation.get("ok", false)), "%s ModuleGraph가 유효해야 한다: %s" % [label, str(validation.get("errors", []))])
	if not bool(validation.get("ok", false)):
		return
	var base_floor: Dictionary = graph.debug_floor_cells()
	var base_open: Dictionary = graph.debug_open_edge_set()
	var base_cell_data: Dictionary = graph.debug_cell_data()
	var floor_snapshot := base_floor.duplicate(true)
	var open_snapshot := base_open.duplicate(true)
	var cell_snapshot := base_cell_data.duplicate(true)
	var topology := CorridorTopologyBuilderScript.build(
		base_floor,
		base_open,
		base_cell_data,
		graph.debug_socket_cells()
	)
	_expect(topology["errors"].is_empty(), "%s 공용 topology 오류가 없어야 한다: %s" % [label, str(topology["errors"])])
	_expect(topology["visual_floor_set"] == floor_snapshot, "%s patch가 없으면 시각 바닥이 graph 바닥과 같다" % label)
	_expect(topology["visual_open_edges"] == base_open, "%s 열린 변을 잃거나 새로 만들지 않는다" % label)
	_expect(base_floor == floor_snapshot and base_open == open_snapshot and base_cell_data == cell_snapshot, "%s builder가 graph snapshot을 변경하지 않는다" % label)

	var wall_ids: Dictionary = {}
	for edge_value in topology["boundary_edges"]:
		var edge_id := str(edge_value.get("id", ""))
		wall_ids[edge_id] = int(wall_ids.get(edge_id, 0)) + 1
	_expect(wall_ids.size() == topology["boundary_edges"].size(), "%s 물리 벽 ID가 중복되지 않는다" % label)

	for cell_value in base_floor.keys():
		var cell: Vector2i = cell_value
		var expected_mask := 0
		for side in CorridorTopologyBuilderScript.SIDES:
			var is_open := base_open.has(AutoTileMaskScript.edge_key(cell, side))
			if is_open:
				expected_mask |= int(AutoTileMaskScript.BITS[side])
			var vertices := CorridorTopologyBuilderScript._edge_vertices(cell, side)
			var edge_id := CorridorTopologyBuilderScript._physical_edge_id(vertices[0], vertices[1])
			_expect(int(wall_ids.get(edge_id, 0)) == (0 if is_open else 1), "%s %s:%s는 열림=벽0/닫힘=벽1이어야 한다" % [label, cell, side])
		_expect(int(topology["mask_by_cell"].get(cell, -1)) == expected_mask, "%s %s mask가 열린 변 bit와 일치한다" % [label, cell])

	var structural_boundary_ids: Dictionary = {}
	for edge_value in topology["boundary_edges"]:
		if str(edge_value.get("state", "closed")) in ["closed", "open_placeholder"]:
			structural_boundary_ids[str(edge_value.get("id", ""))] = true
	var chain_ids: Dictionary = {}
	for chain_value in topology["wall_chains"]:
		for edge_id_value in chain_value.get("edge_ids", []):
			var edge_id := str(edge_id_value)
			_expect(not chain_ids.has(edge_id), "%s wall chain이 벽을 중복 방문하지 않는다: %s" % [label, edge_id])
			chain_ids[edge_id] = true
	_expect(chain_ids.size() == structural_boundary_ids.size(), "%s 모든 닫힌 벽과 placeholder 벽이 정확히 한 wall chain에 속한다" % label)


func _check_renderer_profile(stage_id: String, expected_floor_mode: String, game: Node) -> void:
	var renderer = game.quarter_renderer
	var profile: Dictionary = renderer.debug_active_spatial_profile()
	_expect(str(profile.get("profile_id", "")) == "cave_v2_grid", "%s가 공용 cave_v2_grid 자산 프로필을 사용한다" % stage_id)
	_expect(str(profile.get("topology_mode", "")) == "grid_half_edge_v1", "%s가 공용 half-edge topology를 사용한다" % stage_id)
	_expect(str(profile.get("room_wall_mode", "")) == "shared_bitmap_edges", "%s가 절차 도형 방 벽을 사용하지 않는다" % stage_id)
	_expect(str(profile.get("connection_mode", "")) == "grid_cells", "%s가 중심선 통로를 사용하지 않는다" % stage_id)
	_expect(str(profile.get("corridor_floor_mode", "")) == expected_floor_mode, "%s 바닥 자산 모드가 맞다" % stage_id)
	_expect(str(profile.get("wall_kit_id", "")) == "cave_v2_boundary_v3", "%s가 높은 4단 회흑색 V3 구조 벽 세트를 사용한다" % stage_id)
	_expect(renderer.has_structural_wall_kit(), "%s 구조 벽 세트의 두 축·모서리·끝·분기 자산을 모두 로드한다" % stage_id)
	_expect(renderer.debug_missing_structural_wall_asset_ids().is_empty(), "%s 구조 벽 자산 누락이 없다" % stage_id)
	_expect(renderer.debug_active_boundary_marker_set_id() == "", "%s는 구형 portal/socket marker 세트를 사용하지 않는다" % stage_id)
	_expect(not renderer.has_socket_cap_textures() and renderer.debug_loaded_socket_cap_count() == 0, "%s는 구형 portal/socket marker를 로드하지 않는다" % stage_id)
	_expect(renderer.debug_missing_socket_caps().is_empty(), "%s marker 비활성화는 누락 오류가 아니다" % stage_id)
	var active_wall_set: Dictionary = DataRegistry.quarter_wall_asset_catalog.get("structural_wall_sets", {}).get("cave_v2_boundary_v3", {})
	_expect(not bool(active_wall_set.get("decorative_fallback", true)), "%s 구조 벽은 legacy 장식 오브젝트로 fallback하지 않는다" % stage_id)
	_expect(renderer._wall_edge_alpha("closed") >= 0.90, "%s 벽이 구조물로 읽히는 불투명도다" % stage_id)
	_expect(renderer.debug_corridor_topology_errors().is_empty(), "%s renderer topology 오류가 없어야 한다: %s" % [stage_id, str(renderer.debug_corridor_topology_errors())])
	var unit_layer := game.get_node_or_null("UnitYSortLayer") as CanvasItem
	var front_layer := game.get_node_or_null("FrontWallLayer") as CanvasItem
	_expect(unit_layer != null and front_layer != null and front_layer.z_index > unit_layer.z_index, "%s 앞벽이 유닛보다 높은 실제 Canvas 층을 사용한다" % stage_id)
	_expect(game.get_node_or_null("FrontWallLayer/CorridorFrontWallCanvas") != null, "%s 앞벽 전용 draw canvas가 존재한다" % stage_id)
	var connected_socket_count := 0
	for socket_value in game.graph.debug_socket_cells():
		var socket: Dictionary = socket_value
		var state := str(socket.get("state", "closed"))
		var side := str(socket.get("side", ""))
		if state != "connected":
			continue
		connected_socket_count += 1
		_expect(
			renderer.debug_socket_cap_key(str(socket.get("instance_id", "")), str(socket.get("socket_id", ""))) == "",
			"%s connected:%s는 구형 문틀·횃불 자산을 사용하지 않는다" % [stage_id, side]
		)
		_expect(
			renderer.debug_socket_marker_draw_target(state, side) == "",
			"%s connected:%s는 어느 Canvas에도 장식을 그리지 않는다" % [stage_id, side]
		)
	_expect(connected_socket_count > 0, "%s 연결 통로 공백 검증 대상이 존재한다" % stage_id)
	var renderer_ids: Dictionary = {}
	for edge_value in renderer.debug_wall_edge_records():
		var edge_id := str(edge_value.get("id", ""))
		renderer_ids[edge_id] = int(renderer_ids.get(edge_id, 0)) + 1
		if str(edge_value.get("state", "closed")) in ["closed", "open_placeholder"]:
			_expect(str(edge_value.get("structural_asset_id", "")) != "", "%s 막힌 변은 catalog 구조 segment만 참조한다" % stage_id)
			_expect(str(edge_value.get("texture_key", "")).ends_with("_structural_segment"), "%s 막힌 변은 legacy straight/end/cap 키를 사용하지 않는다" % stage_id)
	_expect(renderer_ids.size() == renderer.debug_wall_edge_records().size(), "%s renderer가 builder 벽을 중복하지 않는다" % stage_id)
	_expect(not renderer.debug_wall_vertex_records().is_empty(), "%s가 연속 벽 코너/끝점 정보를 renderer에 전달한다" % stage_id)
	for vertex_value in renderer.debug_wall_vertex_records():
		var kind := str(vertex_value.get("kind", ""))
		if kind == "straight":
			_expect(str(vertex_value.get("structural_asset_id", "")) == "", "%s 직선 이음은 장식 정점 그림을 추가하지 않는다" % stage_id)
		elif kind in ["corner", "cap", "junction"]:
			_expect(str(vertex_value.get("structural_asset_id", "")) != "", "%s %s 정점은 구분된 구조 자산을 사용한다" % [stage_id, kind])


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame


func _finish() -> void:
	if failures.is_empty():
		print("V122_CORRIDOR_TOPOLOGY_LAYOUT_MATRIX_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_CORRIDOR_TOPOLOGY_LAYOUT_MATRIX_TEST: FAIL")
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
