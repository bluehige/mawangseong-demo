class_name WallAssetCatalog
extends RefCounted

const SCHEMA_VERSION := 3
const FIXED_CANVAS_SIZE := Vector2i(256, 256)
const DIRECTIONS := ["N", "E", "S", "W"]
const EXPECTED_LAYER_BY_DIRECTION := {
	"N": "wall_back",
	"E": "wall_front",
	"S": "wall_front",
	"W": "wall_back"
}
const EXPECTED_AXIS_BY_DIRECTION := {
	"N": "NE_SW",
	"E": "NW_SE",
	"S": "NE_SW",
	"W": "NW_SE"
}
const VERTEX_CONTRACTS := {
	"corner": {
		"piece_kind": "vertex_corner",
		"orientations": {
			"NE": ["N", "E"],
			"ES": ["E", "S"],
			"SW": ["S", "W"],
			"WN": ["W", "N"]
		}
	},
	"cap": {
		"piece_kind": "vertex_end",
		"orientations": {
			"N": ["N"],
			"E": ["E"],
			"S": ["S"],
			"W": ["W"]
		}
	},
	"junction": {
		"piece_kind": "vertex_junction",
		"orientations": {
			"NEW": ["N", "E", "W"],
			"NES": ["N", "E", "S"],
			"ESW": ["E", "S", "W"],
			"NSW": ["N", "S", "W"]
		}
	}
}


static func validate(catalog: Dictionary, active_set_id: String = "") -> Array[String]:
	var errors: Array[String] = []
	if int(catalog.get("schema_version", 0)) != SCHEMA_VERSION:
		_add_error(errors, "WALL_SCHEMA_VERSION", "吏?먰븯吏 ?딅뒗 wall catalog schema_version?낅땲??")

	var assets_value = catalog.get("assets", {})
	var profiles_value = catalog.get("join_profiles", {})
	var sets_value = catalog.get("structural_wall_sets", {})
	var marker_sets_value = catalog.get("boundary_marker_sets", {})
	if not assets_value is Dictionary:
		_add_error(errors, "WALL_ASSETS_FORMAT", "assets??Dictionary?ъ빞 ?⑸땲??")
		return errors
	if not profiles_value is Dictionary:
		_add_error(errors, "WALL_JOIN_PROFILES_FORMAT", "join_profiles??Dictionary?ъ빞 ?⑸땲??")
		return errors
	if not sets_value is Dictionary:
		_add_error(errors, "WALL_SETS_FORMAT", "structural_wall_sets??Dictionary?ъ빞 ?⑸땲??")
		return errors
	if not marker_sets_value is Dictionary:
		_add_error(errors, "WALL_MARKER_SETS_FORMAT", "boundary_marker_sets??Dictionary?ъ빞 ?⑸땲??")
		return errors

	var assets: Dictionary = assets_value
	var profiles: Dictionary = profiles_value
	var wall_sets: Dictionary = sets_value
	var marker_sets: Dictionary = marker_sets_value
	if not marker_sets.is_empty():
		_add_error(
			errors,
			"WALL_MARKER_SET_FORBIDDEN",
			"V2 ?곌껐遺???꾩쟾 怨듬갚?대ŉ 援ы삎 portal/socket marker ?명듃瑜??쒖꽦?뷀븷 ???놁뒿?덈떎."
		)

	if active_set_id != "":
		if not wall_sets.has(active_set_id):
			_add_error(errors, "WALL_ACTIVE_SET_MISSING", "?쒖꽦 援ъ“踰??명듃媛 ?놁뒿?덈떎: %s" % active_set_id)
			return errors
		_validate_wall_set(active_set_id, wall_sets.get(active_set_id), assets, profiles, errors)
		return errors

	if wall_sets.is_empty():
		_add_error(errors, "WALL_SET_MISSING", "援ъ“踰??명듃媛 ?섎굹 ?댁긽 ?꾩슂?⑸땲??")
		return errors
	for set_id_value in wall_sets.keys():
		var set_id := str(set_id_value)
		_validate_wall_set(set_id, wall_sets.get(set_id_value), assets, profiles, errors)
	return errors


static func _validate_wall_set(
	set_id: String,
	wall_set_value,
	assets: Dictionary,
	profiles: Dictionary,
	errors: Array[String]
) -> void:
	if not wall_set_value is Dictionary:
		_add_error(errors, "WALL_SET_FORMAT", "%s ?명듃??Dictionary?ъ빞 ?⑸땲??" % set_id)
		return
	var wall_set: Dictionary = wall_set_value
	var join_profile_id := str(wall_set.get("join_profile", ""))
	if join_profile_id == "" or not profiles.has(join_profile_id):
		_add_error(errors, "WALL_JOIN_PROFILE_MISSING", "%s??join profile???놁뒿?덈떎: %s" % [set_id, join_profile_id])
	else:
		_validate_join_profile(join_profile_id, profiles.get(join_profile_id), errors)

	if (
		not wall_set.has("decorative_fallback")
		or not wall_set.get("decorative_fallback") is bool
		or bool(wall_set.get("decorative_fallback"))
	):
		_add_error(errors, "WALL_DECORATIVE_FALLBACK", "%s??decorative_fallback=false?ъ빞 ?⑸땲??" % set_id)
	if str(wall_set.get("connected_opening_policy", "")) != "empty":
		_add_error(errors, "WALL_CONNECTED_OPENING_POLICY", "%s??connected opening? empty?ъ빞 ?⑸땲??" % set_id)
	if wall_set.has("marker_set"):
		_add_error(errors, "WALL_MARKER_SET_FORBIDDEN", "%s??marker_set??媛吏????놁뒿?덈떎." % set_id)
	if str(wall_set.get("portal_policy", "")) != "explicit_map_asset_only":
		_add_error(errors, "WALL_PORTAL_POLICY", "%s??臾명?? 留듭씠 紐낆떆??蹂꾨룄 ?먯궛留??덉슜?⑸땲??" % set_id)
	if str(wall_set.get("vertex_render_policy", "")) != "edge_overlap":
		_add_error(errors, "WALL_VERTEX_RENDER_POLICY", "%s는 긴 정점 원본을 중복 합성하지 않는 edge_overlap 정책이어야 합니다." % set_id)

	var validated_assets: Dictionary = {}
	var edge_segments_value = wall_set.get("edge_segments", {})
	if not edge_segments_value is Dictionary:
		_add_error(errors, "WALL_EDGE_SEGMENTS_FORMAT", "%s??edge_segments??Dictionary?ъ빞 ?⑸땲??" % set_id)
	else:
		_validate_edge_segments(
			set_id,
			edge_segments_value,
			assets,
			profiles,
			join_profile_id,
			validated_assets,
			errors
		)

	var vertices_value = wall_set.get("vertices", {})
	if not vertices_value is Dictionary:
		_add_error(errors, "WALL_VERTICES_FORMAT", "%s??vertices??Dictionary?ъ빞 ?⑸땲??" % set_id)
	else:
		_validate_vertices(
			set_id,
			vertices_value,
			assets,
			profiles,
			join_profile_id,
			validated_assets,
			errors
		)


static func _validate_join_profile(profile_id: String, profile_value, errors: Array[String]) -> void:
	if not profile_value is Dictionary:
		_add_error(errors, "WALL_JOIN_PROFILE_FORMAT", "%s join profile은 Dictionary여야 합니다." % profile_id)
		return
	var profile: Dictionary = profile_value
	if not _pair_matches(profile.get("canvas_px"), FIXED_CANVAS_SIZE):
		_add_error(errors, "WALL_PROFILE_CANVAS_MISMATCH", "%s canvas_px는 256x256이어야 합니다." % profile_id)
	if not _pair_is_numeric(profile.get("vertex_anchor_px")):
		_add_error(errors, "WALL_PROFILE_ANCHOR_MISMATCH", "%s vertex_anchor_px가 필요합니다." % profile_id)
	if str(profile.get("scale_basis", "")) != "logical_cell_edge":
		_add_error(errors, "WALL_PROFILE_SCALE_BASIS", "%s는 맵의 논리 셀 사선 변을 배율 기준으로 사용해야 합니다." % profile_id)
	var relative_ranges := {
		"target_drawn_connector_span_per_cell_edge": "WALL_PROFILE_CONNECTOR_RATIO_INVALID",
		"target_wall_face_rise_per_cell_edge": "WALL_PROFILE_FACE_RISE_RATIO_INVALID",
		"target_wall_top_depth_per_cell_edge": "WALL_PROFILE_TOP_DEPTH_RATIO_INVALID",
		"target_wall_total_extent_per_cell_edge": "WALL_PROFILE_TOTAL_EXTENT_RATIO_INVALID",
		"target_front_occluder_depth_per_cell_edge": "WALL_PROFILE_OCCLUDER_DEPTH_RATIO_INVALID"
	}
	for field_value in relative_ranges.keys():
		var field := str(field_value)
		if not _valid_positive_range(profile.get(field)):
			_add_error(errors, str(relative_ranges[field]), "%s %s에는 양수 최소·최대 상대 비율이 필요합니다." % [profile_id, field])
	if int(profile.get("masonry_courses", 0)) != 4:
		_add_error(errors, "WALL_PROFILE_MASONRY_COURSES", "%s는 승인 레퍼런스와 같은 4단 석벽이어야 합니다." % profile_id)
	if str(profile.get("palette_family", "")) != "soot_charcoal_gray":
		_add_error(errors, "WALL_PROFILE_PALETTE", "%s는 soot_charcoal_gray 팔레트를 사용해야 합니다." % profile_id)


static func _validate_edge_segments(
	set_id: String,
	edge_segments: Dictionary,
	assets: Dictionary,
	profiles: Dictionary,
	join_profile_id: String,
	validated_assets: Dictionary,
	errors: Array[String]
) -> void:
	var uses_by_asset: Dictionary = {}
	for direction in DIRECTIONS:
		var edge_value = edge_segments.get(direction)
		if not edge_value is Dictionary:
			_add_error(errors, "WALL_EDGE_MISSING", "%s/%s 援ъ“ edge媛 ?놁뒿?덈떎." % [set_id, direction])
			continue
		var edge: Dictionary = edge_value
		var asset_id := str(edge.get("asset_id", ""))
		if asset_id == "" or not assets.has(asset_id):
			_add_error(errors, "WALL_ASSET_MISSING", "%s/%s媛 李몄“?섎뒗 ?먯궛???놁뒿?덈떎: %s" % [set_id, direction, asset_id])
			continue
		var used_directions: Array = uses_by_asset.get(asset_id, [])
		used_directions.append(direction)
		uses_by_asset[asset_id] = used_directions
		if str(edge.get("layer", "")) != str(EXPECTED_LAYER_BY_DIRECTION[direction]):
			_add_error(errors, "WALL_LAYER_MISMATCH", "%s/%s???욌뮘 layer媛 ?섎せ?섏뿀?듬땲??" % [set_id, direction])
		var asset_value = assets.get(asset_id)
		if not asset_value is Dictionary:
			_add_error(errors, "WALL_ASSET_FORMAT", "%s ?먯궛? Dictionary?ъ빞 ?⑸땲??" % asset_id)
			continue
		var asset: Dictionary = asset_value
		_validate_structural_asset(asset_id, asset, profiles, join_profile_id, validated_assets, errors)
		if str(asset.get("piece_kind", "")) != "edge_segment":
			_add_error(errors, "WALL_PIECE_KIND_MISMATCH", "%s/%s??edge_segment?ъ빞 ?⑸땲??" % [set_id, direction])
		if not _same_string_set(asset.get("directions", []), ["N", "S"] if direction in ["N", "S"] else ["E", "W"]):
			_add_error(errors, "WALL_DIRECTION_MISMATCH", "%s??%s 諛⑺뼢 異??먯궛???꾨떃?덈떎." % [asset_id, direction])
		if str(asset.get("screen_axis", "")) != str(EXPECTED_AXIS_BY_DIRECTION[direction]):
			_add_error(errors, "WALL_AXIS_MISMATCH", "%s???붾㈃ 異뺤씠 %s 諛⑺뼢怨?留욎? ?딆뒿?덈떎." % [asset_id, direction])
	_validate_explicit_aliases(set_id, edge_segments, uses_by_asset, errors)


static func _validate_explicit_aliases(
	set_id: String,
	edge_segments: Dictionary,
	uses_by_asset: Dictionary,
	errors: Array[String]
) -> void:
	for asset_id_value in uses_by_asset.keys():
		var asset_id := str(asset_id_value)
		var directions: Array = uses_by_asset[asset_id_value]
		if directions.size() <= 1:
			continue
		var bases: Array[String] = []
		for direction_value in directions:
			var direction := str(direction_value)
			var edge: Dictionary = edge_segments.get(direction, {})
			if not edge.has("alias_of_direction"):
				bases.append(direction)
		if bases.size() != 1:
			_add_error(errors, "WALL_ALIAS_REQUIRED", "%s?먯꽌 %s瑜?怨듭쑀?섎뒗 諛⑺뼢? 湲곗? ?섎굹? 紐낆떆??alias媛 ?꾩슂?⑸땲??" % [set_id, asset_id])
			continue
		for direction_value in directions:
			var direction := str(direction_value)
			if direction == bases[0]:
				continue
			var edge: Dictionary = edge_segments.get(direction, {})
			if str(edge.get("alias_of_direction", "")) != bases[0] or str(edge.get("alias_reason", "")).strip_edges() == "":
				_add_error(errors, "WALL_ALIAS_INVALID", "%s/%s alias ?좎뼵???섎せ?섏뿀?듬땲??" % [set_id, direction])


static func _validate_vertices(
	set_id: String,
	vertices: Dictionary,
	assets: Dictionary,
	profiles: Dictionary,
	join_profile_id: String,
	validated_assets: Dictionary,
	errors: Array[String]
) -> void:
	for kind in VERTEX_CONTRACTS.keys():
		var slots_value = vertices.get(kind)
		if not slots_value is Dictionary:
			_add_error(errors, "WALL_VERTEX_MISSING", "%s??%s 諛⑺뼢蹂?vertex ?щ’???놁뒿?덈떎." % [set_id, kind])
			continue
		var slots: Dictionary = slots_value
		var contract: Dictionary = VERTEX_CONTRACTS[kind]
		var orientations: Dictionary = contract["orientations"]
		for orientation in orientations.keys():
			var asset_id := str(slots.get(orientation, ""))
			if asset_id == "" or not assets.has(asset_id):
				_add_error(errors, "WALL_ASSET_MISSING", "%s/%s/%s vertex ?먯궛???놁뒿?덈떎." % [set_id, kind, orientation])
				continue
			var asset_value = assets.get(asset_id)
			if not asset_value is Dictionary:
				_add_error(errors, "WALL_ASSET_FORMAT", "%s ?먯궛? Dictionary?ъ빞 ?⑸땲??" % asset_id)
				continue
			var asset: Dictionary = asset_value
			_validate_structural_asset(asset_id, asset, profiles, join_profile_id, validated_assets, errors)
			if str(asset.get("piece_kind", "")) != str(contract["piece_kind"]):
				_add_error(errors, "WALL_VERTEX_KIND_MISMATCH", "%s/%s/%s??vertex ??븷???섎せ?섏뿀?듬땲??" % [set_id, kind, orientation])
			if str(asset.get("orientation_key", "")) != str(orientation):
				_add_error(errors, "WALL_VERTEX_ORIENTATION_MISMATCH", "%s orientation_key媛 ?щ’怨??ㅻ쫭?덈떎." % asset_id)
			if not _same_string_set(asset.get("incident_directions", []), orientations[orientation]):
				_add_error(errors, "WALL_VERTEX_DIRECTION_MISMATCH", "%s???곌껐 諛⑺뼢???щ’怨??ㅻ쫭?덈떎." % asset_id)
		for orientation_value in slots.keys():
			if not orientations.has(str(orientation_value)):
				_add_error(errors, "WALL_VERTEX_ORIENTATION_UNKNOWN", "%s/%s???????녿뒗 諛⑺뼢 ?щ’???덉뒿?덈떎: %s" % [set_id, kind, orientation_value])


static func _validate_structural_asset(
	asset_id: String,
	asset: Dictionary,
	profiles: Dictionary,
	join_profile_id: String,
	validated_assets: Dictionary,
	errors: Array[String]
) -> void:
	if validated_assets.has(asset_id):
		return
	validated_assets[asset_id] = true
	if str(asset.get("usage", "")) != "structural_boundary":
		_add_error(errors, "WALL_USAGE_MISMATCH", "%s는 structural_boundary 자산이어야 합니다." % asset_id)
	if str(asset.get("status", "")) != "runtime":
		_add_error(errors, "WALL_STATUS_MISMATCH", "%s는 runtime 상태여야 합니다." % asset_id)
	if str(asset.get("join_profile", "")) != join_profile_id:
		_add_error(errors, "WALL_JOIN_PROFILE_MISMATCH", "%s join profile이 활성 세트와 다릅니다." % asset_id)
	if not _pair_matches(asset.get("canvas_px"), FIXED_CANVAS_SIZE):
		_add_error(errors, "WALL_CANVAS_MISMATCH", "%s canvas_px는 256x256이어야 합니다." % asset_id)
	if not _valid_content_bbox(asset.get("content_bbox_px")):
		_add_error(errors, "WALL_CONTENT_BBOX_INVALID", "%s content_bbox_px가 유효하지 않습니다." % asset_id)

	var piece_kind := str(asset.get("piece_kind", ""))
	if piece_kind == "edge_segment":
		_validate_edge_connector_metadata(asset_id, asset, errors)
	else:
		var profile: Dictionary = profiles.get(join_profile_id, {})
		if not _pairs_equal(asset.get("anchor_px"), profile.get("vertex_anchor_px")):
			_add_error(errors, "WALL_ANCHOR_MISMATCH", "%s vertex anchor가 join profile과 다릅니다." % asset_id)
	_validate_source_anchor_extent(asset_id, asset, errors)

	var path := str(asset.get("path", ""))
	var resource_path := _resource_path(path)
	if path == "" or not FileAccess.file_exists(resource_path):
		_add_error(errors, "WALL_FILE_MISSING", "%s runtime PNG가 없습니다: %s" % [asset_id, path])
	else:
		var image := Image.new()
		var load_error := image.load(ProjectSettings.globalize_path(resource_path))
		if load_error != OK:
			_add_error(errors, "WALL_IMAGE_LOAD_FAILED", "%s runtime PNG를 읽을 수 없습니다." % asset_id)
		elif image.get_size() != FIXED_CANVAS_SIZE:
			_add_error(errors, "WALL_CANVAS_MISMATCH", "%s 실제 PNG가 256x256이 아닙니다." % asset_id)
	var source_doc := str(asset.get("source_doc", ""))
	if source_doc == "" or not FileAccess.file_exists(_resource_path(source_doc)):
		_add_error(errors, "WALL_SOURCE_DOC_MISSING", "%s source_doc가 없습니다: %s" % [asset_id, source_doc])
	_validate_front_occluder(asset_id, asset, errors)


static func _validate_front_occluder(asset_id: String, asset: Dictionary, errors: Array[String]) -> void:
	var incident_value = asset.get("directions", asset.get("incident_directions", []))
	var incident: Array = incident_value if incident_value is Array else []
	var requires_front_occluder := incident.has("E") or incident.has("S")
	var path := str(asset.get("front_occluder_path", ""))
	if requires_front_occluder and path == "":
		_add_error(errors, "WALL_FRONT_OCCLUDER_MISSING", "%s에는 E/S 최하단 앞가림 자산이 필요합니다." % asset_id)
		return
	if not requires_front_occluder and path != "":
		_add_error(errors, "WALL_FRONT_OCCLUDER_UNEXPECTED", "%s는 순수 N/W 벽이므로 앞가림 자산을 가져서는 안 됩니다." % asset_id)
		return
	if path == "":
		return
	var resource_path := _resource_path(path)
	if not FileAccess.file_exists(resource_path):
		_add_error(errors, "WALL_FRONT_OCCLUDER_FILE_MISSING", "%s 앞가림 PNG가 없습니다: %s" % [asset_id, path])
		return
	if not _valid_content_bbox(asset.get("front_occluder_bbox_px")):
		_add_error(errors, "WALL_FRONT_OCCLUDER_BBOX_INVALID", "%s 앞가림 bbox가 유효하지 않습니다." % asset_id)
	var occluder := Image.new()
	var load_error := occluder.load(ProjectSettings.globalize_path(resource_path))
	if load_error != OK or occluder.get_size() != FIXED_CANVAS_SIZE:
		_add_error(errors, "WALL_FRONT_OCCLUDER_CANVAS_MISMATCH", "%s 앞가림 PNG는 본체와 같은 256x256이어야 합니다." % asset_id)
		return
	var body := Image.new()
	var body_path := _resource_path(str(asset.get("path", "")))
	if body.load(ProjectSettings.globalize_path(body_path)) != OK:
		return
	for y in range(FIXED_CANVAS_SIZE.y):
		for x in range(FIXED_CANVAS_SIZE.x):
			if occluder.get_pixel(x, y).a > body.get_pixel(x, y).a + 0.001:
				_add_error(errors, "WALL_FRONT_OCCLUDER_ALPHA_OUTSIDE_BODY", "%s 앞가림 alpha가 본체 밖으로 나갔습니다." % asset_id)
				return


static func _validate_source_anchor_extent(
	asset_id: String,
	asset: Dictionary,
	errors: Array[String]
) -> void:
	var bbox = asset.get("content_bbox_px", [])
	var anchor = asset.get("anchor_px", [])
	if not bbox is Array or bbox.size() != 4 or not _pair_is_numeric(anchor):
		return
	var calculated := int(anchor[1]) - int(bbox[1])
	var recorded := int(asset.get("source_anchor_extent_px", -1))
	if recorded != calculated:
		_add_error(errors, "WALL_SOURCE_EXTENT_METADATA", "%s source_anchor_extent_px가 실제 bbox와 다릅니다." % asset_id)


static func _validate_edge_connector_metadata(asset_id: String, asset: Dictionary, errors: Array[String]) -> void:
	var start_value = asset.get("connector_start_px")
	var end_value = asset.get("connector_end_px")
	var anchor_value = asset.get("anchor_px")
	if not _pair_is_numeric(start_value) or not _pair_is_numeric(end_value) or not _pair_is_numeric(anchor_value):
		_add_error(errors, "WALL_CONNECTOR_MISSING", "%s edge?먮뒗 connector? anchor媛 ?꾩슂?⑸땲??" % asset_id)
		return
	var start := Vector2(float(start_value[0]), float(start_value[1]))
	var end := Vector2(float(end_value[0]), float(end_value[1]))
	var anchor := Vector2(float(anchor_value[0]), float(anchor_value[1]))
	if not anchor.is_equal_approx(start.lerp(end, 0.5)):
		_add_error(errors, "WALL_ANCHOR_MISMATCH", "%s edge anchor????connector???뺥솗??以묒젏?댁뼱???⑸땲??" % asset_id)
	var delta := end - start
	if is_zero_approx(delta.x):
		_add_error(errors, "WALL_CONNECTOR_AXIS", "%s edge connector 湲몄씠媛 0?낅땲??" % asset_id)
		return
	var expected_slope := 0.5 if str(asset.get("screen_axis", "")) == "NE_SW" else -0.5
	if absf(delta.y / delta.x - expected_slope) > 0.001:
		_add_error(errors, "WALL_CONNECTOR_AXIS", "%s edge connector媛 2:1 ?깃컖 異뺢낵 留욎? ?딆뒿?덈떎." % asset_id)


static func _same_string_set(actual_value, expected_value) -> bool:
	if not actual_value is Array or not expected_value is Array:
		return false
	var actual: Array = actual_value
	var expected: Array = expected_value
	if actual.size() != expected.size():
		return false
	for value in expected:
		if not actual.has(value):
			return false
	return true


static func _pair_matches(value, expected: Vector2i) -> bool:
	return (
		value is Array
		and value.size() == 2
		and int(value[0]) == expected.x
		and int(value[1]) == expected.y
	)


static func _pair_is_numeric(value) -> bool:
	return (
		value is Array
		and value.size() == 2
		and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT]
		and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT]
	)


static func _pair_is_positive(value) -> bool:
	return _pair_is_numeric(value) and float(value[0]) > 0.0 and float(value[1]) > 0.0


static func _valid_positive_range(value) -> bool:
	return _pair_is_positive(value) and float(value[0]) <= float(value[1])


static func _pairs_equal(first, second) -> bool:
	return (
		_pair_is_numeric(first)
		and _pair_is_numeric(second)
		and int(first[0]) == int(second[0])
		and int(first[1]) == int(second[1])
	)


static func _valid_content_bbox(value) -> bool:
	if not value is Array or value.size() != 4:
		return false
	var left := int(value[0])
	var top := int(value[1])
	var right := int(value[2])
	var bottom := int(value[3])
	return (
		left >= 0
		and top >= 0
		and right <= FIXED_CANVAS_SIZE.x
		and bottom <= FIXED_CANVAS_SIZE.y
		and left < right
		and top < bottom
	)


static func _resource_path(path: String) -> String:
	if path == "" or path.begins_with("res://"):
		return path
	return "res://%s" % path


static func _add_error(errors: Array[String], code: String, message: String) -> void:
	errors.append("[%s] %s" % [code, message])
