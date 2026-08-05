extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const LAYOUT_ID := "stage01_corridor_wall_topology_test_01"
const LAYOUT_PATH := "res://data/dungeon_quarter/layouts/stage01_dual_front_01.json"
const ACTIVE_SET_ID := "cave_v2_boundary_v3"
const JOIN_PROFILE_ID := "cave_v2_structural_tall_v3"
const TARGET_DRAWN_CONNECTOR_SPAN_PER_CELL_EDGE := Vector2(1.08, 1.15)
const TARGET_WALL_FACE_RISE_PER_CELL_EDGE := Vector2(1.10, 1.35)
const TARGET_WALL_TOP_DEPTH_PER_CELL_EDGE := Vector2(0.40, 0.50)
const TARGET_WALL_TOTAL_EXTENT_PER_CELL_EDGE := Vector2(1.50, 1.75)
const TARGET_FRONT_OCCLUDER_DEPTH_PER_CELL_EDGE := Vector2(0.35, 0.50)
const MAX_ENDPOINT_GAP_PER_CELL_EDGE := 0.04

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	_expect(layout is Dictionary, "Stage 01 이중 전선 배치 fixture를 읽는다")
	if not layout is Dictionary:
		_finish()
		return
	var game := GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	DataRegistry.register_quarter_layout(LAYOUT_ID, layout, false)
	game.quarter_layout_id = LAYOUT_ID
	game.castle_art_stage = "stage_01_cave"
	game.v122_connector_state = {
		"connector_id": "rear_cross_lane_connector",
		"built": false,
		"built_day": 0
	}
	GameState.day = 3
	GameState.gold = 1200
	GameState.mana = 150
	game._setup_dungeon_graph()
	game.current_screen = Constants.SCREEN_MANAGEMENT
	game.set_meta("v122_battle_plan", game._v122_current_battle_plan())
	game.quarter_renderer.refresh_layout()

	_check_wall_contract(game)
	_check_stage01_bitmap_wall_contract(game)
	_check_runtime_wall_display_contract(game)
	_check_wall_draw_coverage(game)
	_check_connector_unbuilt(game)

	_expect(game._build_v122_defender_connector(), "DAY 3 전용 연결로를 건설한다")
	game.quarter_renderer.refresh_layout()
	_check_wall_contract(game)
	_check_wall_draw_coverage(game)
	_check_connector_built(game)

	game._shutdown_audio_for_exit()
	await _settle(1)
	game.queue_free()
	await _settle(2)
	_finish()


func _check_wall_contract(game: Node) -> void:
	var renderer = game.quarter_renderer
	var visual_floor: Dictionary = renderer.debug_visual_floor_cells()
	var records: Array = renderer.debug_wall_edge_records()
	var record_counts: Dictionary = {}
	for record in records:
		var cell: Vector2i = record.get("cell", Vector2i.ZERO)
		var side := str(record.get("side", ""))
		var key := AutoTileMaskScript.edge_key(cell, side)
		record_counts[key] = int(record_counts.get(key, 0)) + 1
		_expect(
			not renderer.debug_visual_edge_open(cell, side),
			"열린 바닥 연결 위에는 벽이 없어야 한다: %s" % key
		)
	for cell_value in visual_floor.keys():
		var cell: Vector2i = cell_value
		for side in ["N", "E", "S", "W"]:
			var neighbor: Vector2i = cell + AutoTileMaskScript.DIRS[side]
			var opposite := AutoTileMaskScript.opposite_side(side)
			var direct_key := AutoTileMaskScript.edge_key(cell, side)
			var opposite_key := AutoTileMaskScript.edge_key(neighbor, opposite)
			var boundary_count := int(record_counts.get(direct_key, 0))
			if visual_floor.has(neighbor):
				boundary_count += int(record_counts.get(opposite_key, 0))
			if renderer.debug_visual_edge_open(cell, side):
				_expect(boundary_count == 0, "통로 중앙의 열린 변에는 벽 조각이 0개다: %s" % direct_key)
			else:
				_expect(boundary_count == 1, "닫힌 외곽 변에는 연속 벽 구간이 정확히 1개다: %s" % direct_key)
	for socket_value in game.graph.debug_socket_cells():
		var socket: Dictionary = socket_value
		if str(socket.get("state", "")) != "connected":
			continue
		var side := str(socket.get("side", ""))
		_expect(
			renderer.debug_socket_cap_key(str(socket.get("instance_id", "")), str(socket.get("socket_id", ""))) == "",
			"연결 통로에는 구형 문틀·횃불 marker가 없어야 한다: %s:%s" % [socket.get("cell", Vector2i.ZERO), side]
		)
		_expect(
			renderer.debug_socket_marker_draw_target("connected", side) == "",
			"연결 통로는 별도 장식 레이어에도 아무것도 그리지 않는다: %s" % side
		)


func _check_stage01_bitmap_wall_contract(game: Node) -> void:
	var renderer = game.quarter_renderer
	_expect(renderer.has_structural_wall_kit(), "두 축 직선과 corner/end/junction 구조 벽 키트를 로드한다")
	_expect(renderer.debug_missing_structural_wall_asset_ids().is_empty(), "구조 벽 PNG 누락이 없다")
	_expect(renderer.debug_active_wall_kit_id() == ACTIVE_SET_ID, "Stage 01은 높은 4단 회흑색 cave_v2 V3 구조 벽 세트를 사용한다")
	_expect(renderer._wall_edge_alpha("closed") >= 0.90, "Stage 01 석벽은 구조물로 읽히는 불투명도다")
	_expect(renderer.debug_loaded_socket_cap_count() == 0, "구형 portal/socket 장식 이미지는 하나도 로드하지 않는다")
	var profile: Dictionary = renderer.debug_active_spatial_profile()
	_expect(str(profile.get("topology_mode", "")) == "grid_half_edge_v1", "Stage 01은 공용 half-edge 통로 생성기를 사용한다")
	_expect(str(profile.get("room_wall_mode", "")) == "shared_bitmap_edges", "Stage 01은 절차 도형 방 벽을 bitmap 석벽과 겹쳐 그리지 않는다")
	_expect(str(profile.get("connection_mode", "")) == "grid_cells", "Stage 01은 셀 중심 사이에 임의 회전 도로 strip을 덧그리지 않는다")
	_expect(renderer.debug_corridor_topology_errors().is_empty(), "Stage 01 공용 topology 생성 오류가 없어야 한다")
	var wall_set: Dictionary = DataRegistry.quarter_wall_asset_catalog.get("structural_wall_sets", {}).get(ACTIVE_SET_ID, {})
	_expect(str(wall_set.get("vertex_render_policy", "")) == "edge_overlap", "V3 모서리는 긴 정점 이미지를 덧그리지 않고 직선 벽의 겹침으로 접합한다")


func _check_runtime_wall_display_contract(game: Node) -> void:
	var renderer = game.quarter_renderer
	var catalog: Dictionary = DataRegistry.quarter_wall_asset_catalog
	var join_profile: Dictionary = catalog.get("join_profiles", {}).get(JOIN_PROFILE_ID, {})
	_expect(int(catalog.get("schema_version", 0)) == 3, "구조벽 catalog는 통로 한 칸 대비 비율을 쓰는 schema 3이다")
	_expect(str(join_profile.get("scale_basis", "")) == "logical_cell_edge", "구조벽 표시 크기는 논리 통로 한 칸 길이를 기준으로 정한다")
	_expect(
		_catalog_range(join_profile, "target_drawn_connector_span_per_cell_edge") == TARGET_DRAWN_CONNECTOR_SPAN_PER_CELL_EDGE,
		"catalog와 테스트의 한 칸 대비 연결선 길이 계약이 같다"
	)
	_expect(
		_catalog_range(join_profile, "target_wall_face_rise_per_cell_edge") == TARGET_WALL_FACE_RISE_PER_CELL_EDGE,
		"catalog와 테스트의 한 칸 대비 벽면 높이 계약이 같다"
	)
	_expect(
		_catalog_range(join_profile, "target_wall_top_depth_per_cell_edge") == TARGET_WALL_TOP_DEPTH_PER_CELL_EDGE,
		"catalog와 테스트의 한 칸 대비 벽 상단 깊이 계약이 같다"
	)
	_expect(
		_catalog_range(join_profile, "target_wall_total_extent_per_cell_edge") == TARGET_WALL_TOTAL_EXTENT_PER_CELL_EDGE,
		"catalog와 테스트의 한 칸 대비 벽 중심 전체 높이 계약이 같다"
	)
	_expect(
		_catalog_range(join_profile, "target_front_occluder_depth_per_cell_edge") == TARGET_FRONT_OCCLUDER_DEPTH_PER_CELL_EDGE,
		"catalog와 테스트의 한 칸 대비 전면 가림 높이 계약이 같다"
	)
	_expect(int(join_profile.get("masonry_courses", 0)) == 4, "실행 중인 구조벽은 4단 석벽이다")

	var minimum_connector_ratio := INF
	var maximum_connector_ratio := 0.0
	var minimum_center_extent_ratio := INF
	var maximum_center_extent_ratio := 0.0
	var minimum_full_bbox_ratio := INF
	var maximum_full_bbox_ratio := 0.0
	var minimum_occluder_ratio := INF
	var maximum_occluder_ratio := 0.0
	var measured_edges := 0
	var measured_occluders := 0
	for record_value in renderer.debug_wall_edge_records():
		if not record_value is Dictionary:
			continue
		var record: Dictionary = record_value
		if str(record.get("state", "closed")) not in ["closed", "open_placeholder"]:
			continue
		var asset_id := str(record.get("structural_asset_id", ""))
		var texture = renderer.structural_wall_textures.get(asset_id, null)
		var entry: Dictionary = renderer.structural_wall_asset_entries.get(asset_id, {})
		if not texture is Texture2D or entry.is_empty():
			continue
		var start: Vector2 = record.get("start", Vector2.ZERO)
		var end: Vector2 = record.get("end", Vector2.ZERO)
		var logical_cell_edge := start.distance_to(end)
		if logical_cell_edge <= 0.0001:
			continue
		var image: Image = texture.get_image()
		var draw_rect: Rect2 = renderer._structural_edge_draw_rect(texture, entry, record)
		var source_scale := draw_rect.size.x / float(texture.get_width())
		var source_start := _catalog_point(entry.get("connector_start_px", []))
		var source_end := _catalog_point(entry.get("connector_end_px", []))
		var source_midpoint := source_start.lerp(source_end, 0.5)
		var source_axis := source_end - source_start
		if source_axis.length_squared() <= 0.0001:
			continue
		var actual_bbox := _alpha_bbox(image)
		if actual_bbox.size == Vector2i.ZERO:
			continue
		var connector_ratio := source_axis.length() * source_scale / logical_cell_edge
		var center_extent_ratio := float(
			_alpha_column_extent(image, roundi(source_midpoint.x))
		) * source_scale / logical_cell_edge
		var full_bbox_ratio := float(actual_bbox.size.y) * source_scale / logical_cell_edge
		minimum_connector_ratio = minf(minimum_connector_ratio, connector_ratio)
		maximum_connector_ratio = maxf(maximum_connector_ratio, connector_ratio)
		minimum_center_extent_ratio = minf(minimum_center_extent_ratio, center_extent_ratio)
		maximum_center_extent_ratio = maxf(maximum_center_extent_ratio, center_extent_ratio)
		minimum_full_bbox_ratio = minf(minimum_full_bbox_ratio, full_bbox_ratio)
		maximum_full_bbox_ratio = maxf(maximum_full_bbox_ratio, full_bbox_ratio)
		_expect(
			full_bbox_ratio >= center_extent_ratio,
			"%s 전체 대각 bitmap 외곽은 중심 기둥 높이보다 작지 않다" % asset_id
		)
		var occluder_texture = renderer.structural_wall_front_occluder_textures.get(asset_id, null)
		_expect(occluder_texture is Texture2D, "%s에는 몸체 전체가 아닌 낮은 전면 가림 texture가 따로 로드된다" % asset_id)
		if occluder_texture is Texture2D:
			var occluder_image: Image = occluder_texture.get_image()
			var occluder_ratio := float(
				_alpha_column_extent(occluder_image, roundi(source_midpoint.x))
			) * source_scale / logical_cell_edge
			minimum_occluder_ratio = minf(minimum_occluder_ratio, occluder_ratio)
			maximum_occluder_ratio = maxf(maximum_occluder_ratio, occluder_ratio)
			measured_occluders += 1
		measured_edges += 1
	_expect(measured_edges > 0, "통로 한 칸 대비 표시 비율을 잴 구조 벽 구간이 있다")
	if measured_edges > 0:
		print(
			"V122_WALL_RELATIVE_METRICS: connector=%.5f..%.5f center_extent=%.5f..%.5f full_bbox_diagnostic=%.5f..%.5f occluder=%.5f..%.5f"
			% [
				minimum_connector_ratio,
				maximum_connector_ratio,
				minimum_center_extent_ratio,
				maximum_center_extent_ratio,
				minimum_full_bbox_ratio,
				maximum_full_bbox_ratio,
				minimum_occluder_ratio,
				maximum_occluder_ratio
			]
		)
		_expect(
			minimum_connector_ratio >= TARGET_DRAWN_CONNECTOR_SPAN_PER_CELL_EDGE.x
			and maximum_connector_ratio <= TARGET_DRAWN_CONNECTOR_SPAN_PER_CELL_EDGE.y,
			"겹침 포함 연결선/통로 한 칸 비율 %.5f~%.5f가 계약 1.08~1.15 안이다" % [minimum_connector_ratio, maximum_connector_ratio]
		)
		_expect(
			minimum_center_extent_ratio >= TARGET_WALL_TOTAL_EXTENT_PER_CELL_EDGE.x
			and maximum_center_extent_ratio <= TARGET_WALL_TOTAL_EXTENT_PER_CELL_EDGE.y,
			"벽 중심 alpha 높이/통로 한 칸 비율 %.5f~%.5f가 계약 1.50~1.75 안이다" % [minimum_center_extent_ratio, maximum_center_extent_ratio]
		)
	_expect(measured_occluders == measured_edges, "모든 구조 벽 구간에서 별도 전면 가림 높이를 측정한다")
	if measured_occluders > 0:
		_expect(
			minimum_occluder_ratio >= TARGET_FRONT_OCCLUDER_DEPTH_PER_CELL_EDGE.x
			and maximum_occluder_ratio <= TARGET_FRONT_OCCLUDER_DEPTH_PER_CELL_EDGE.y,
			"전면 가림 중심 높이/통로 한 칸 비율 %.5f~%.5f가 계약 0.35~0.50 안이다" % [minimum_occluder_ratio, maximum_occluder_ratio]
		)

	var validated_vertices := 0
	for vertex_value in renderer.debug_wall_vertex_records():
		if not vertex_value is Dictionary:
			continue
		var vertex: Dictionary = vertex_value
		var kind := str(vertex.get("kind", ""))
		if kind not in ["cap", "corner", "junction"]:
			continue
		var asset_id := str(vertex.get("structural_asset_id", ""))
		var texture = renderer.structural_wall_textures.get(asset_id, null)
		var entry: Dictionary = renderer.structural_wall_asset_entries.get(asset_id, {})
		_expect(asset_id != "" and texture is Texture2D and not entry.is_empty(), "%s 정점 record가 유효한 V3 자산을 참조한다" % kind)
		_expect(str(vertex.get("reference_segment_asset_id", "")) != "", "%s 정점 record가 인접 직선 벽 구간을 참조한다" % kind)
		validated_vertices += 1
	_expect(validated_vertices > 0, "모서리·끝·교차점 topology record와 자산 참조가 유지된다")
	_expect(not renderer._structural_vertex_asset_overlays_enabled(), "정점 record는 topology용으로 유지하되 긴 정점 sprite를 실제 벽 위에 덧그리지 않는다")


func _check_wall_draw_coverage(game: Node) -> void:
	var renderer = game.quarter_renderer
	var missed_endpoints: Array[String] = []
	for record in renderer.debug_wall_edge_records():
		if str(record.get("state", "closed")) not in ["closed", "open_placeholder"]:
			continue
		var asset_id := str(record.get("structural_asset_id", ""))
		var texture = renderer.structural_wall_textures.get(asset_id, null)
		var entry: Dictionary = renderer.structural_wall_asset_entries.get(asset_id, {})
		if not texture is Texture2D:
			missed_endpoints.append("missing structural texture %s" % asset_id)
			continue
		var source_start := _catalog_point(entry.get("connector_start_px", []))
		var source_end := _catalog_point(entry.get("connector_end_px", []))
		var image: Image = texture.get_image()
		if (
			source_start == Vector2.ZERO
			or source_end == Vector2.ZERO
			or image == null
			or image.is_empty()
			or image.get_pixelv(Vector2i(source_start)).a <= 0.05
			or image.get_pixelv(Vector2i(source_end)).a <= 0.05
		):
			missed_endpoints.append("catalog connector has no alpha %s" % asset_id)
			continue
		var draw_rect: Rect2 = renderer._structural_edge_draw_rect(texture, entry, record)
		var scale := draw_rect.size.x / float(texture.get_width())
		var mapped_start := draw_rect.position + source_start * scale
		var mapped_end := draw_rect.position + source_end * scale
		var start: Vector2 = record.get("start", Vector2.ZERO)
		var end: Vector2 = record.get("end", Vector2.ZERO)
		var logical_cell_edge := start.distance_to(end)
		if logical_cell_edge <= 0.0001:
			missed_endpoints.append("zero-length logical edge %s/%s" % [record.get("cell", Vector2i.ZERO), record.get("side", "")])
			continue
		var start_gap_ratio := _distance_to_segment(start, mapped_start, mapped_end) / logical_cell_edge
		var end_gap_ratio := _distance_to_segment(end, mapped_start, mapped_end) / logical_cell_edge
		if start_gap_ratio > MAX_ENDPOINT_GAP_PER_CELL_EDGE or end_gap_ratio > MAX_ENDPOINT_GAP_PER_CELL_EDGE:
			missed_endpoints.append(
				"%s/%s gap_ratio=%.5f/%.5f mapped=%s..%s logical=%s..%s"
				% [record.get("cell", Vector2i.ZERO), record.get("side", ""), start_gap_ratio, end_gap_ratio, mapped_start, mapped_end, start, end]
			)
	_expect(
		missed_endpoints.is_empty(),
		"실제 석벽 alpha 연결선이 닫힌 변과 open_placeholder 변의 양 끝점을 통로 한 칸의 4%% 안에서 덮는다: %s"
		% str(missed_endpoints.slice(0, mini(4, missed_endpoints.size())))
	)
	var placeholder_records: Array = renderer.debug_wall_edge_records().filter(
		func(record): return str(record.get("state", "")) == "open_placeholder"
	)
	_expect(not placeholder_records.is_empty(), "open_placeholder 경계 재현 record가 존재한다")
	for record in placeholder_records:
		_expect(str(record.get("structural_asset_id", "")) != "", "open_placeholder가 구조 벽 segment를 유지한다")
		_expect(str(record.get("texture_key", "")).find("structural_segment") >= 0, "open_placeholder의 벽 소유자는 구조 벽 경로다")
		_expect(str(record.get("marker_overlay_state", "")) == "", "open_placeholder도 구형 석주 marker를 겹치지 않는다")


func _catalog_point(value) -> Vector2:
	if value is Array and value.size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


func _catalog_range(profile: Dictionary, field: String) -> Vector2:
	return _catalog_point(profile.get(field, []))


func _alpha_bbox(image: Image) -> Rect2i:
	if image == null or image.is_empty():
		return Rect2i()
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a8 <= 0:
				continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
	if right < left or bottom < top:
		return Rect2i()
	return Rect2i(left, top, right - left + 1, bottom - top + 1)


func _alpha_column_extent(image: Image, x: int) -> int:
	if image == null or image.is_empty() or x < 0 or x >= image.get_width():
		return 0
	var first_y := image.get_height()
	var last_y := -1
	for y in range(image.get_height()):
		if image.get_pixel(x, y).a8 <= 64:
			continue
		first_y = mini(first_y, y)
		last_y = maxi(last_y, y)
	return 0 if last_y < first_y else last_y - first_y + 1


func _distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var delta := segment_end - segment_start
	if delta.length_squared() <= 0.0001:
		return point.distance_to(segment_start)
	var t := clampf((point - segment_start).dot(delta) / delta.length_squared(), 0.0, 1.0)
	return point.distance_to(segment_start + delta * t)


func _check_connector_unbuilt(game: Node) -> void:
	var renderer = game.quarter_renderer
	var visual_floor: Dictionary = renderer.debug_visual_floor_cells()
	for cell in _connector_cells():
		_expect(not visual_floor.has(cell), "건설 전 연결로 칸은 열린 통로로 보이지 않는다: %s" % cell)


func _check_connector_built(game: Node) -> void:
	var renderer = game.quarter_renderer
	var visual_floor: Dictionary = renderer.debug_visual_floor_cells()
	var graph_floor: Dictionary = game.graph.debug_floor_cells()
	var expected_masks := {
		Vector2i(18, 12): 7,
		Vector2i(19, 12): 13,
		Vector2i(18, 13): 7,
		Vector2i(19, 13): 13
	}
	for cell in _connector_cells():
		_expect(visual_floor.has(cell), "건설 후 2x2 연결로 바닥이 실제 격자에 보인다: %s" % cell)
		_expect(not graph_floor.has(cell), "방어자 전용 연결로는 공용 적 바닥 그래프에 추가하지 않는다: %s" % cell)
		_expect(
			renderer.debug_render_mask_for_global_cell(cell) == int(expected_masks[cell]),
			"연결로 바닥 mask가 N/S 출입구와 내부 이웃만 연다: %s" % cell
		)
	for x in [18, 19]:
		_expect(renderer.debug_visual_edge_open(Vector2i(x, 12), "N"), "연결로 북쪽 문턱이 방 벽에 붙어 열린다")
		_expect(renderer.debug_visual_edge_open(Vector2i(x, 13), "S"), "연결로 남쪽 문턱이 방 벽에 붙어 열린다")
	for y in [12, 13]:
		_expect(not renderer.debug_visual_edge_open(Vector2i(18, y), "W"), "연결로 서쪽에는 연속 벽이 남는다")
		_expect(not renderer.debug_visual_edge_open(Vector2i(19, y), "E"), "연결로 동쪽에는 연속 벽이 남는다")


func _connector_cells() -> Array[Vector2i]:
	return [Vector2i(18, 12), Vector2i(19, 12), Vector2i(18, 13), Vector2i(19, 13)]


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame


func _finish() -> void:
	if failures.is_empty():
		print("V122_CORRIDOR_WALL_TOPOLOGY_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_CORRIDOR_WALL_TOPOLOGY_TEST: FAIL")
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
