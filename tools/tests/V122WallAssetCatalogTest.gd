extends Node

const WallAssetCatalogScript = preload("res://scripts/dungeon_quarter/WallAssetCatalog.gd")
const CATALOG_PATH := "res://data/dungeon_quarter/wall_asset_catalog.json"
const TILE_VARIANT_MANIFEST_PATH := "res://data/dungeon_quarter/tile_variant_manifest.json"
const ASSET_MANIFEST_PATH := "res://data/dungeon_quarter/asset_manifest.json"
const ACTIVE_SET_ID := "cave_v2_boundary_v3"
const PROFILE_ID := "cave_v2_structural_tall_v3"
const SEGMENT_ID := "cave_v2_segment_axis_ne_sw_v3"
const CORNER_ID := "cave_v2_vertex_corner_NE_v3"

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := _load_json_object(CATALOG_PATH)
	if not catalog.is_empty():
		_test_active_catalog(catalog)
		_test_decorative_asset_rejected(catalog)
		_test_explicit_alias_required(catalog)
		_test_decorative_fallback_rejected(catalog)
		_test_edge_and_vertex_roles(catalog)
		_test_resource_contracts(catalog)
		_test_empty_connected_opening_contract(catalog)
	_test_legacy_runtime_manifests_quarantined()
	_finish()


func _test_active_catalog(catalog: Dictionary) -> void:
	_expect(int(catalog.get("schema_version", 0)) == 3, "활성 구조벽 catalog는 상대 비율 계약을 쓰는 schema 3이다")
	var errors := WallAssetCatalogScript.validate(catalog, ACTIVE_SET_ID)
	_expect(errors.is_empty(), "활성 구조벽 V3 세트가 전체 계약을 통과한다: %s" % str(errors))


func _test_decorative_asset_rejected(catalog: Dictionary) -> void:
	var variant: Dictionary = catalog.duplicate(true)
	var decorative: Dictionary = variant["assets"][SEGMENT_ID].duplicate(true)
	decorative["usage"] = "decorative_wall_prop"
	variant["assets"]["test_decorative_wall"] = decorative
	variant["structural_wall_sets"][ACTIVE_SET_ID]["edge_segments"]["N"]["asset_id"] = "test_decorative_wall"
	var errors := WallAssetCatalogScript.validate(variant, ACTIVE_SET_ID)
	_expect(_has_error(errors, "WALL_USAGE_MISMATCH"), "장식 벽 자산을 구조 edge 슬롯에 넣으면 거부한다")


func _test_explicit_alias_required(catalog: Dictionary) -> void:
	var variant: Dictionary = catalog.duplicate(true)
	variant["structural_wall_sets"][ACTIVE_SET_ID]["edge_segments"]["S"].erase("alias_of_direction")
	variant["structural_wall_sets"][ACTIVE_SET_ID]["edge_segments"]["S"].erase("alias_reason")
	var errors := WallAssetCatalogScript.validate(variant, ACTIVE_SET_ID)
	_expect(_has_error(errors, "WALL_ALIAS_REQUIRED"), "같은 직선 bitmap을 공유하면 명시적 alias가 필요하다")


func _test_decorative_fallback_rejected(catalog: Dictionary) -> void:
	var variant: Dictionary = catalog.duplicate(true)
	variant["structural_wall_sets"][ACTIVE_SET_ID]["decorative_fallback"] = true
	var errors := WallAssetCatalogScript.validate(variant, ACTIVE_SET_ID)
	_expect(_has_error(errors, "WALL_DECORATIVE_FALLBACK"), "구조벽 세트는 장식 자산 fallback을 허용하지 않는다")


func _test_edge_and_vertex_roles(catalog: Dictionary) -> void:
	var wrong_layer: Dictionary = catalog.duplicate(true)
	wrong_layer["structural_wall_sets"][ACTIVE_SET_ID]["edge_segments"]["N"]["layer"] = "wall_front"
	_expect(
		_has_error(WallAssetCatalogScript.validate(wrong_layer, ACTIVE_SET_ID), "WALL_LAYER_MISMATCH"),
		"N/E/S/W 구조 edge의 앞뒤 합성층을 검증한다"
	)

	var wrong_direction: Dictionary = catalog.duplicate(true)
	wrong_direction["assets"][SEGMENT_ID]["directions"] = ["E", "W"]
	_expect(
		_has_error(WallAssetCatalogScript.validate(wrong_direction, ACTIVE_SET_ID), "WALL_DIRECTION_MISMATCH"),
		"직선 자산의 지원 방향을 검증한다"
	)

	var wrong_vertex_kind: Dictionary = catalog.duplicate(true)
	wrong_vertex_kind["structural_wall_sets"][ACTIVE_SET_ID]["vertices"]["corner"]["NE"] = "cave_v2_vertex_end_N_v3"
	_expect(
		_has_error(WallAssetCatalogScript.validate(wrong_vertex_kind, ACTIVE_SET_ID), "WALL_VERTEX_KIND_MISMATCH"),
		"모서리와 끝마감 역할을 서로 바꿀 수 없다"
	)

	var wrong_orientation: Dictionary = catalog.duplicate(true)
	wrong_orientation["structural_wall_sets"][ACTIVE_SET_ID]["vertices"]["corner"]["NE"] = "cave_v2_vertex_corner_SW_v3"
	_expect(
		_has_error(WallAssetCatalogScript.validate(wrong_orientation, ACTIVE_SET_ID), "WALL_VERTEX_ORIENTATION_MISMATCH"),
		"모서리 자산의 방향 슬롯이 실제 연결 방향과 같아야 한다"
	)


func _test_resource_contracts(catalog: Dictionary) -> void:
	var wrong_canvas: Dictionary = catalog.duplicate(true)
	wrong_canvas["assets"][CORNER_ID]["canvas_px"] = [128, 128]
	_expect(
		_has_error(WallAssetCatalogScript.validate(wrong_canvas, ACTIVE_SET_ID), "WALL_CANVAS_MISMATCH"),
		"구조벽 자산은 고정 256x256 canvas를 사용한다"
	)

	var missing_source: Dictionary = catalog.duplicate(true)
	missing_source["assets"][CORNER_ID]["source_doc"] = "assets/source/imagegen/not_found/SOURCE.md"
	_expect(
		_has_error(WallAssetCatalogScript.validate(missing_source, ACTIVE_SET_ID), "WALL_SOURCE_DOC_MISSING"),
		"구조벽 자산의 생성 출처 문서가 실제로 존재해야 한다"
	)

	var wrong_anchor: Dictionary = catalog.duplicate(true)
	wrong_anchor["assets"][SEGMENT_ID]["anchor_px"] = [128, 232]
	_expect(
		_has_error(WallAssetCatalogScript.validate(wrong_anchor, ACTIVE_SET_ID), "WALL_ANCHOR_MISMATCH"),
		"직선 anchor는 두 연결점의 중점이어야 한다"
	)

	var wrong_source_extent: Dictionary = catalog.duplicate(true)
	wrong_source_extent["assets"][CORNER_ID]["source_anchor_extent_px"] = (
		int(wrong_source_extent["assets"][CORNER_ID]["source_anchor_extent_px"]) + 1
	)
	_expect(
		_has_error(WallAssetCatalogScript.validate(wrong_source_extent, ACTIVE_SET_ID), "WALL_SOURCE_EXTENT_METADATA"),
		"원본 alpha와 다른 source_anchor_extent_px 메타데이터를 거부한다"
	)

	var reversed_display_range: Dictionary = catalog.duplicate(true)
	reversed_display_range["join_profiles"][PROFILE_ID]["target_wall_top_depth_per_cell_edge"] = [0.50, 0.40]
	_expect(
		_has_error(
			WallAssetCatalogScript.validate(reversed_display_range, ACTIVE_SET_ID),
			"WALL_PROFILE_TOP_DEPTH_RATIO_INVALID"
		),
		"통로 한 칸 대비 벽 상단 깊이 비율의 최소·최대가 뒤집힌 catalog를 거부한다"
	)

	var missing_front_occluder: Dictionary = catalog.duplicate(true)
	missing_front_occluder["assets"][SEGMENT_ID].erase("front_occluder_path")
	_expect(
		_has_error(
			WallAssetCatalogScript.validate(missing_front_occluder, ACTIVE_SET_ID),
			"WALL_FRONT_OCCLUDER_MISSING"
		),
		"화면 앞쪽을 향하는 구조벽은 낮은 전면 가림 자산을 반드시 가진다"
	)


func _test_empty_connected_opening_contract(catalog: Dictionary) -> void:
	var wrong_policy: Dictionary = catalog.duplicate(true)
	wrong_policy["structural_wall_sets"][ACTIVE_SET_ID]["connected_opening_policy"] = "portal_frame"
	_expect(
		_has_error(WallAssetCatalogScript.validate(wrong_policy, ACTIVE_SET_ID), "WALL_CONNECTED_OPENING_POLICY"),
		"connected 통로의 기본값은 완전 공백이다"
	)

	var marker_set: Dictionary = catalog.duplicate(true)
	marker_set["boundary_marker_sets"] = {"legacy": {"connected": {}}}
	marker_set["structural_wall_sets"][ACTIVE_SET_ID]["marker_set"] = "legacy"
	var errors := WallAssetCatalogScript.validate(marker_set, ACTIVE_SET_ID)
	_expect(_has_error(errors, "WALL_MARKER_SET_FORBIDDEN"), "구형 connected portal/socket marker 세트의 재활성화를 막는다")


func _test_legacy_runtime_manifests_quarantined() -> void:
	var tile_manifest := _load_json_object(TILE_VARIANT_MANIFEST_PATH)
	var asset_manifest := _load_json_object(ASSET_MANIFEST_PATH)
	if tile_manifest.is_empty() or asset_manifest.is_empty():
		return
	_expect(not tile_manifest.has("wall_edges"), "tile manifest가 구형 문틀·벽 장식 목록을 중복 소유하지 않는다")
	_expect(str(tile_manifest.get("boundary_asset_catalog", "")) == CATALOG_PATH, "tile manifest가 단일 wall catalog를 가리킨다")
	_expect(not tile_manifest.has("walls"), "과거 straight wall tile은 활성 manifest에서 제거됐다")
	_expect(not tile_manifest.has("wall_mask"), "과거 임시 wall mask는 활성 manifest에서 제거됐다")
	_expect(not tile_manifest.has("doors"), "과거 door tile은 connected fallback으로 활성화되지 않는다")
	_expect(not asset_manifest.has("socket_caps"), "asset manifest도 구형 socket marker를 중복 소유하지 않는다")
	_expect(
		str(asset_manifest.get("spatial_asset_profiles", {}).get("cave_v2_grid", {}).get("wall_kit_id", "")) == ACTIVE_SET_ID,
		"모든 Stage 01~04가 구조벽 V3 세트를 사용한다"
	)


func _load_json_object(path: String) -> Dictionary:
	_expect(FileAccess.file_exists(path), "%s 파일이 존재한다" % path)
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	_expect(parsed is Dictionary, "%s 파일은 유효한 JSON object다" % path)
	return parsed if parsed is Dictionary else {}


func _has_error(errors: Array[String], code: String) -> bool:
	var prefix := "[%s]" % code
	for error in errors:
		if error.begins_with(prefix):
			return true
	return false


func _finish() -> void:
	if failures.is_empty():
		print("V122_WALL_ASSET_CATALOG_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_WALL_ASSET_CATALOG_TEST: FAIL")
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
