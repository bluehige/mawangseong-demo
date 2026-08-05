extends Node

const CATALOG_PATH := "res://data/dungeon_quarter/wall_asset_catalog.json"
const JOIN_PROFILE_ID := "cave_v2_structural_tall_v3"
const EXPECTED_CANVAS := Vector2i(256, 256)
const EXPECTED_STRUCTURAL_ASSET_COUNT := 14
const EXPECTED_CONNECTOR_SPAN_RATIO := Vector2(1.08, 1.15)
const EXPECTED_WALL_FACE_RISE_RATIO := Vector2(1.10, 1.35)
const EXPECTED_WALL_TOP_DEPTH_RATIO := Vector2(0.40, 0.50)
const EXPECTED_WALL_TOTAL_EXTENT_RATIO := Vector2(1.50, 1.75)
const EXPECTED_FRONT_OCCLUDER_DEPTH_RATIO := Vector2(0.35, 0.50)
const SLOPE_TOLERANCE := 0.02
const MAX_MEDIAN_SATURATION := 0.18
const MAX_MEAN_CHANNEL_SPREAD := 10.0
const MAX_PURPLE_FRACTION := 0.10

var failures: Array[String] = []
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := _load_catalog()
	if not catalog.is_empty():
		var loaded_assets := _test_asset_canvas_bbox_source_extent_and_palette(catalog)
		_test_edge_pixels(loaded_assets)
		_test_directional_vertex_pixels(loaded_assets)
	if failures.is_empty():
		print("V122_STRUCTURAL_WALL_PIXEL_CONTRACT_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_STRUCTURAL_WALL_PIXEL_CONTRACT_TEST: FAIL (%d assertions)" % assertion_count)
	get_tree().quit(1)


func _load_catalog() -> Dictionary:
	_expect(FileAccess.file_exists(CATALOG_PATH), "구조벽 자산 catalog가 존재한다")
	if not FileAccess.file_exists(CATALOG_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	_expect(parsed is Dictionary, "구조벽 자산 catalog는 유효한 JSON object다")
	return parsed if parsed is Dictionary else {}


func _test_asset_canvas_bbox_source_extent_and_palette(catalog: Dictionary) -> Dictionary:
	_expect(int(catalog.get("schema_version", 0)) == 3, "구조벽 catalog는 상대 비율 계약을 쓰는 schema 3이다")
	var assets_value = catalog.get("assets", {})
	_expect(assets_value is Dictionary, "catalog assets가 Dictionary다")
	if not assets_value is Dictionary:
		return {}
	var assets: Dictionary = assets_value
	var structural_ids: Array[String] = []
	for asset_id_value in assets.keys():
		var entry_value = assets.get(asset_id_value, {})
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if str(entry.get("usage", "")) == "structural_boundary" and str(entry.get("status", "")) == "runtime":
			structural_ids.append(str(asset_id_value))
	structural_ids.sort()
	_expect(
		structural_ids.size() == EXPECTED_STRUCTURAL_ASSET_COUNT,
		"runtime 구조벽 PNG가 직선 2 + 방향별 정점 12, 총 14개다: %s" % str(structural_ids)
	)

	var profile: Dictionary = catalog.get("join_profiles", {}).get(JOIN_PROFILE_ID, {})
	_expect(str(profile.get("scale_basis", "")) == "logical_cell_edge", "V3 구조벽 크기는 통로 한 칸 길이를 기준으로 정한다")
	_expect(
		_catalog_range(profile, "target_drawn_connector_span_per_cell_edge") == EXPECTED_CONNECTOR_SPAN_RATIO,
		"V3 연결선 길이 비율 계약은 1.08~1.15다"
	)
	_expect(
		_catalog_range(profile, "target_wall_face_rise_per_cell_edge") == EXPECTED_WALL_FACE_RISE_RATIO,
		"V3 벽면 높이 비율 계약은 1.10~1.35다"
	)
	_expect(
		_catalog_range(profile, "target_wall_top_depth_per_cell_edge") == EXPECTED_WALL_TOP_DEPTH_RATIO,
		"V3 벽 상단 깊이 비율 계약은 0.40~0.50이다"
	)
	_expect(
		_catalog_range(profile, "target_wall_total_extent_per_cell_edge") == EXPECTED_WALL_TOTAL_EXTENT_RATIO,
		"V3 중심 기둥 전체 높이 비율 계약은 1.50~1.75다"
	)
	_expect(
		_catalog_range(profile, "target_front_occluder_depth_per_cell_edge") == EXPECTED_FRONT_OCCLUDER_DEPTH_RATIO,
		"V3 전면 가림 높이 비율 계약은 0.35~0.50이다"
	)
	_expect(int(profile.get("masonry_courses", 0)) == 4, "V3 벽은 정확히 4단 석벽이다")
	_expect(str(profile.get("palette_family", "")) == "soot_charcoal_gray", "V3 벽은 그을린 짙은 회색 계열이다")

	var loaded: Dictionary = {}
	for asset_id in structural_ids:
		var entry: Dictionary = assets[asset_id]
		var path := _res_path(str(entry.get("path", "")))
		_expect(path != "res://" and FileAccess.file_exists(path), "%s PNG가 존재한다: %s" % [asset_id, path])
		if path == "res://" or not FileAccess.file_exists(path):
			continue
		var image := Image.new()
		var load_error := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
		_expect(load_error == OK and not image.is_empty(), "%s PNG 원본 픽셀을 읽을 수 있다" % asset_id)
		if load_error != OK or image.is_empty():
			continue
		image.convert(Image.FORMAT_RGBA8)
		_expect(image.get_size() == EXPECTED_CANVAS, "%s canvas는 256x256이다" % asset_id)
		var actual_bbox := _alpha_bbox(image)
		var bbox_value = entry.get("content_bbox_px", [])
		var has_recorded_bbox: bool = bbox_value is Array and bbox_value.size() == 4
		_expect(has_recorded_bbox, "%s content_bbox_px가 네 좌표로 기록돼 있다" % asset_id)
		if has_recorded_bbox:
			var recorded_bbox := _rect_from_bounds(bbox_value)
			_expect(actual_bbox == recorded_bbox, "%s catalog bbox와 실제 alpha bbox가 일치한다" % asset_id)
		var anchor: Array = entry.get("anchor_px", [])
		var source_anchor_extent := int(anchor[1]) - actual_bbox.position.y if anchor.size() == 2 else 999
		_expect(
			int(entry.get("source_anchor_extent_px", -1)) == source_anchor_extent,
			"%s source_anchor_extent_px가 실제 alpha와 일치한다" % asset_id
		)
		var front_occluder: Image = null
		if _requires_front_occluder(entry):
			var occluder_path := _res_path(str(entry.get("front_occluder_path", "")))
			_expect(
				occluder_path != "res://" and FileAccess.file_exists(occluder_path),
				"%s 화면 앞쪽 벽에는 전면 가림 PNG가 존재한다" % asset_id
			)
			if occluder_path != "res://" and FileAccess.file_exists(occluder_path):
				front_occluder = Image.new()
				var occluder_load_error := front_occluder.load_png_from_buffer(FileAccess.get_file_as_bytes(occluder_path))
				_expect(
					occluder_load_error == OK and not front_occluder.is_empty(),
					"%s 전면 가림 PNG 픽셀을 읽을 수 있다" % asset_id
				)
				if occluder_load_error == OK and not front_occluder.is_empty():
					front_occluder.convert(Image.FORMAT_RGBA8)
					_expect(front_occluder.get_size() == image.get_size(), "%s 전면 가림 PNG와 몸체 PNG의 canvas가 같다" % asset_id)
					var occluder_bbox := _alpha_bbox(front_occluder)
					var occluder_bbox_value = entry.get("front_occluder_bbox_px", [])
					var has_recorded_occluder_bbox: bool = occluder_bbox_value is Array and occluder_bbox_value.size() == 4
					_expect(has_recorded_occluder_bbox, "%s front_occluder_bbox_px가 네 좌표로 기록돼 있다" % asset_id)
					if has_recorded_occluder_bbox:
						_expect(
							occluder_bbox == _rect_from_bounds(occluder_bbox_value),
							"%s catalog 전면 가림 bbox와 실제 alpha bbox가 일치한다" % asset_id
						)
					_expect(_alpha_is_subset(front_occluder, image), "%s 전면 가림 alpha는 몸체 alpha의 일부다" % asset_id)
		else:
			_expect(
				str(entry.get("front_occluder_path", "")) == "",
				"%s 화면 뒤쪽 전용 벽에는 불필요한 전면 가림 PNG가 없다" % asset_id
			)
		_test_gray_palette(asset_id, image, actual_bbox)
		loaded[asset_id] = {"entry": entry, "image": image, "bbox": actual_bbox, "front_occluder": front_occluder}
	return loaded


func _test_gray_palette(asset_id: String, image: Image, bbox: Rect2i) -> void:
	var saturations: Array[float] = []
	var luminances: Array[float] = []
	var red_sum := 0.0
	var green_sum := 0.0
	var blue_sum := 0.0
	var purple_count := 0
	var pixel_count := 0
	for y in range(bbox.position.y, bbox.end.y):
		for x in range(bbox.position.x, bbox.end.x):
			var color := image.get_pixel(x, y)
			if color.a8 <= 64:
				continue
			var maximum := maxf(color.r, maxf(color.g, color.b))
			var minimum := minf(color.r, minf(color.g, color.b))
			saturations.append(0.0 if maximum <= 0.0 else (maximum - minimum) / maximum)
			luminances.append((0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b) * 255.0)
			red_sum += color.r8
			green_sum += color.g8
			blue_sum += color.b8
			if color.b8 > color.r8 + 8 and color.b8 > color.g8 + 8:
				purple_count += 1
			pixel_count += 1
	_expect(pixel_count > 0, "%s에 실제 불투명 석재 픽셀이 있다" % asset_id)
	if pixel_count == 0:
		return
	var median_saturation := _median(saturations)
	var median_luminance := _median(luminances)
	var mean_channels := [red_sum / pixel_count, green_sum / pixel_count, blue_sum / pixel_count]
	var channel_spread: float = mean_channels.max() - mean_channels.min()
	var purple_fraction := float(purple_count) / float(pixel_count)
	_expect(median_saturation <= MAX_MEDIAN_SATURATION, "%s 중간 채도 %.3f가 회색 한계 %.2f 이하다" % [asset_id, median_saturation, MAX_MEDIAN_SATURATION])
	_expect(channel_spread <= MAX_MEAN_CHANNEL_SPREAD, "%s 평균 RGB 채널 편차 %.2f가 10 이하다" % [asset_id, channel_spread])
	_expect(purple_fraction <= MAX_PURPLE_FRACTION, "%s 보라 우세 픽셀 비율 %.3f가 10%% 이하다" % [asset_id, purple_fraction])
	_expect(median_luminance >= 20.0 and median_luminance <= 80.0, "%s 중간 명도 %.1f가 거무튀튀한 회색 범위다" % [asset_id, median_luminance])


func _test_edge_pixels(loaded_assets: Dictionary) -> void:
	var edge_pieces: Array[Dictionary] = []
	for asset_id_value in loaded_assets.keys():
		var loaded: Dictionary = loaded_assets[asset_id_value]
		var entry: Dictionary = loaded.get("entry", {})
		if str(entry.get("piece_kind", "")) == "edge_segment":
			loaded["asset_id"] = str(asset_id_value)
			edge_pieces.append(loaded)
	_expect(edge_pieces.size() == 2, "구조벽 edge segment는 두 화면 대각축이다")
	if edge_pieces.size() != 2:
		return
	var ns_piece: Dictionary = {}
	var ew_piece: Dictionary = {}
	for piece in edge_pieces:
		var entry: Dictionary = piece.get("entry", {})
		var directions: Array = entry.get("directions", [])
		var expected_slope := 0.5 if _same_string_set(directions, ["N", "S"]) else -0.5
		if expected_slope > 0.0:
			ns_piece = piece
		else:
			ew_piece = piece
		var image: Image = piece.get("image")
		var start: Array = entry.get("connector_start_px", [])
		var end: Array = entry.get("connector_end_px", [])
		var connector_delta := Vector2(float(end[0] - start[0]), float(end[1] - start[1])) if start.size() == 2 and end.size() == 2 else Vector2.ZERO
		var connector_slope := connector_delta.y / connector_delta.x if absf(connector_delta.x) > 0.0001 else INF
		_expect(
			absf(connector_slope - expected_slope) <= SLOPE_TOLERANCE,
			"%s 실제 연결점 축의 기울기가 2:1 등각축이다" % str(piece.get("asset_id", ""))
		)
		_expect(start.size() == 2 and image.get_pixel(int(start[0]), int(start[1])).a8 > 0, "%s 시작 연결점에 석재 alpha가 있다" % str(piece.get("asset_id", "")))
		_expect(end.size() == 2 and image.get_pixel(int(end[0]), int(end[1])).a8 > 0, "%s 끝 연결점에 석재 alpha가 있다" % str(piece.get("asset_id", "")))
	_expect(not ns_piece.is_empty() and not ew_piece.is_empty(), "N/S와 E/W 직선이 각각 존재한다")
	if not ns_piece.is_empty() and not ew_piece.is_empty():
		_expect(
			_is_exact_horizontal_mirror(ns_piece.get("image"), ew_piece.get("image"), 128),
			"두 직선 축은 공통 재질 원본의 정확한 수평 반전이다"
		)


func _test_directional_vertex_pixels(loaded_assets: Dictionary) -> void:
	var counts := {"vertex_corner": 0, "vertex_end": 0, "vertex_junction": 0}
	var orientations_by_kind := {"vertex_corner": {}, "vertex_end": {}, "vertex_junction": {}}
	for asset_id_value in loaded_assets.keys():
		var loaded: Dictionary = loaded_assets[asset_id_value]
		var entry: Dictionary = loaded.get("entry", {})
		var kind := str(entry.get("piece_kind", ""))
		if not counts.has(kind):
			continue
		counts[kind] = int(counts[kind]) + 1
		var orientation := str(entry.get("orientation_key", ""))
		_expect(orientation != "", "%s에 방향별 orientation_key가 있다" % asset_id_value)
		_expect(not orientations_by_kind[kind].has(orientation), "%s의 %s 방향 PNG는 하나뿐이다" % [kind, orientation])
		orientations_by_kind[kind][orientation] = true
		var directions: Array = entry.get("incident_directions", [])
		_expect(directions.size() in [1, 2, 3], "%s는 1~3개의 실제 연결 방향만 가진다" % asset_id_value)
	_expect(int(counts["vertex_corner"]) == 4, "모서리 PNG는 네 방향으로 분리됐다")
	_expect(int(counts["vertex_end"]) == 4, "끝마감 PNG는 네 방향으로 분리됐다")
	_expect(int(counts["vertex_junction"]) == 4, "T분기 PNG는 빠진 방향별 네 종류다")
	_expect(not orientations_by_kind["vertex_junction"].has("NESW"), "잘못된 X 교차 자산은 존재하지 않는다")


func _alpha_bbox(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a8 == 0:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _bottom_alpha_y(image: Image, x: int, bbox: Rect2i) -> int:
	for y in range(bbox.end.y - 1, bbox.position.y - 1, -1):
		if image.get_pixel(x, y).a8 > 0:
			return y
	return -1


func _is_exact_horizontal_mirror(source: Image, mirrored: Image, anchor_x: int) -> bool:
	if source.get_size() != mirrored.get_size():
		return false
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			var mirrored_x := anchor_x * 2 - x
			if mirrored_x < 0 or mirrored_x >= source.get_width():
				if source.get_pixel(x, y).a8 != 0 or mirrored.get_pixel(x, y).a8 != 0:
					return false
				continue
			if source.get_pixel(x, y) != mirrored.get_pixel(mirrored_x, y):
				return false
	return true


func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	values.sort()
	var middle := values.size() / 2
	if values.size() % 2 == 1:
		return values[middle]
	return (values[middle - 1] + values[middle]) * 0.5


func _same_string_set(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for value in expected:
		if not actual.has(value):
			return false
	return true


func _requires_front_occluder(entry: Dictionary) -> bool:
	var directions_value = entry.get("directions", entry.get("incident_directions", []))
	if not directions_value is Array:
		return false
	var directions: Array = directions_value
	return directions.has("E") or directions.has("S")


func _alpha_is_subset(subset: Image, body: Image) -> bool:
	if subset == null or body == null or subset.get_size() != body.get_size():
		return false
	for y in range(subset.get_height()):
		for x in range(subset.get_width()):
			if subset.get_pixel(x, y).a > body.get_pixel(x, y).a + 0.001:
				return false
	return true


func _catalog_range(profile: Dictionary, field: String) -> Vector2:
	var value = profile.get(field, [])
	if value is Array and value.size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


func _rect_from_bounds(bounds: Array) -> Rect2i:
	return Rect2i(int(bounds[0]), int(bounds[1]), int(bounds[2]) - int(bounds[0]), int(bounds[3]) - int(bounds[1]))


func _res_path(path: String) -> String:
	return path if path.begins_with("res://") else "res://%s" % path


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
