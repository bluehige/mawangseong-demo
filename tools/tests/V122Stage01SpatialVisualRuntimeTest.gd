extends Node

const RendererScript = preload("res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd")
const RENDERER_SOURCE := "res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd"

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_manifest_lookup()
	_test_runtime_dimensions()
	_test_corridor_autotile_ports()
	_test_renderer_contract()
	if failures.is_empty():
		print("V122_STAGE01_SPATIAL_VISUAL_RUNTIME_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_STAGE01_SPATIAL_VISUAL_RUNTIME_TEST: FAIL")
	get_tree().quit(1)


func _test_manifest_lookup() -> void:
	var stages: Dictionary = DataRegistry.quarter_asset_manifest.get("stage_spatial_visuals", {})
	var stage: Dictionary = stages.get("stage_01_cave", {})
	_expect(stage.get("corridor_cells", {}).size() == 4, "Stage 01 구형 복도 fallback은 번호가 고정된 4종이다")
	var corridor_autotile: Dictionary = stage.get("corridor_autotile", {})
	_expect(int(corridor_autotile.get("mask_count", 0)) == 16, "Stage 01 도로 autotile은 N/E/S/W 16개 연결 mask를 사용한다")
	_expect(
		corridor_autotile.get("variant_order", []) == ["00", "10", "01", "11"],
		"Stage 01 도로 autotile 재질 변형 순서는 좌표 홀짝 4종으로 고정된다"
	)
	var defender_connector: Dictionary = stage.get("defender_connector", {})
	var junction_size: Array = defender_connector.get("native_size", [])
	_expect(
		junction_size.size() == 2 and int(junction_size[0]) == 128 and int(junction_size[1]) == 64,
		"Stage 01 방어자 연결로 접속석은 128x64 bitmap이다"
	)
	_expect(stage.get("thresholds", {}).size() == 4, "Stage 01 문턱 lookup은 N/E/S/W 4종이다")
	var edge: Dictionary = stage.get("cavern_edge_mask", {})
	_expect(int(edge.get("patch_margin", 0)) == 256, "가장자리 마스크 9-slice margin은 256px이다")
	_expect(not bool(edge.get("draw_center", true)), "가장자리 마스크 중앙은 그리지 않는다")
	var throne: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {}).get("throne_f", {})
	var stage_sprites: Dictionary = throne.get("stage_facing_sprites", {})
	var stage_one: Dictionary = stage_sprites.get("stage_01_cave", {}).get("SW", {})
	var stage_two: Dictionary = stage_sprites.get("stage_02_castle", {}).get("SW", {})
	_expect(
		str(stage_one.get("back", "")) == "assets/props/stage_01/room_throne_stage01_SW_open_s_back.png",
		"새 5x5 왕좌는 Stage 01 SW에만 연결된다"
	)
	_expect(
		str(stage_two.get("back", "")) != str(stage_one.get("back", "")),
		"Stage 02 왕좌는 Stage 01 exact 자산으로 덮어쓰지 않는다"
	)
	var renderer = RendererScript.new()
	renderer._load_stage_spatial_textures()
	_expect(renderer.has_stage01_corridor_autotile_texture(), "renderer가 Stage 01 도로 autotile atlas를 로드한다")
	_expect(renderer.has_stage01_spatial_textures(), "renderer가 Stage 01 공간 자산을 모두 로드한다")
	_expect(renderer.debug_stage01_spatial_texture_count() == 8, "Stage 01 runtime texture count는 바닥·문턱·접속석 포함 8이다")


func _test_runtime_dimensions() -> void:
	for path in [
		"res://assets/tiles/stage_01/spatial/corridor_surface_stage01_2cell.png",
		"res://assets/tiles/stage_01/spatial/threshold_stage01_N_2cell.png",
		"res://assets/tiles/stage_01/spatial/threshold_stage01_E_2cell.png",
		"res://assets/tiles/stage_01/spatial/threshold_stage01_S_2cell.png",
		"res://assets/tiles/stage_01/spatial/threshold_stage01_W_2cell.png",
		"res://assets/tiles/stage_01/spatial/common_occlusion_shadow_stage01_2cell.png",
	]:
		_expect(_image_size(path) == Vector2i(256, 128), "%s는 native 256x128이다" % path)
	for cell_id in ["00", "10", "01", "11"]:
		var path := "res://assets/tiles/stage_01/spatial/corridor_surface_stage01_cell_%s.png" % cell_id
		_expect(_image_size(path) == Vector2i(128, 64), "%s는 native 128x64이다" % path)
	_expect(
		_image_size("res://assets/tiles/stage_01/spatial_road_autotile_v2/corridor_road_autotile_stage01_atlas.png") == Vector2i(2048, 256),
		"Stage 01 도로 autotile atlas는 mask 16열·재질 변형 4행이다"
	)
	_expect(
		_image_size("res://assets/tiles/stage_01/spatial_passage_v1/defender_connector_junction_stage01.png") == Vector2i(128, 64),
		"Stage 01 방어자 연결로 접속석 bitmap은 128x64이다"
	)
	_expect(
		_image_size("res://assets/props/stage_01/room_throne_stage01_SW_open_s_back.png") == Vector2i(640, 640),
		"Stage 01 왕좌 runtime canvas는 640x640이다"
	)
	var edge_path := "res://assets/ui/stage_01/cavern_edge_mask_stage01_9slice.png"
	_expect(_image_size(edge_path) == Vector2i(1024, 1024), "가장자리 마스크 runtime canvas는 1024x1024이다")
	var edge_texture := ResourceLoader.load(edge_path) as Texture2D
	var edge_image := edge_texture.get_image() if edge_texture != null else null
	if edge_image != null and not edge_image.is_empty():
		_expect(edge_image.get_pixel(400, 900).a == 0.0, "9-slice bottom stretch strip의 고립 alpha를 제거한다")
		_expect(edge_image.get_pixel(512, 512).a == 0.0, "9-slice 중앙은 완전 투명하다")


func _test_corridor_autotile_ports() -> void:
	var atlas_path := "res://assets/tiles/stage_01/spatial_road_autotile_v2/corridor_road_autotile_stage01_atlas.png"
	var atlas_texture := ResourceLoader.load(atlas_path) as Texture2D
	var atlas := atlas_texture.get_image() if atlas_texture != null else null
	_expect(atlas != null and not atlas.is_empty(), "Stage 01 도로 autotile atlas 픽셀을 읽을 수 있다")
	if atlas == null or atlas.is_empty():
		return
	var ports := {
		"N": {"bit": 1, "point": Vector2i(96, 16)},
		"E": {"bit": 2, "point": Vector2i(96, 48)},
		"S": {"bit": 4, "point": Vector2i(32, 48)},
		"W": {"bit": 8, "point": Vector2i(32, 16)},
	}
	for variant_index in range(4):
		for mask_value in range(16):
			var origin := Vector2i(mask_value * 128, variant_index * 64)
			_expect(
				_max_alpha_near(atlas, origin + Vector2i(64, 32)) > 0.35,
				"도로 mask %02d variant %d의 중앙이 비지 않는다" % [mask_value, variant_index]
			)
			for side in ports.keys():
				var port: Dictionary = ports[side]
				var connected := (mask_value & int(port["bit"])) != 0
				var alpha := _max_alpha_near(atlas, origin + Vector2i(port["point"]))
				_expect(
					alpha > 0.08 if connected else alpha < 0.08,
					"도로 mask %02d variant %d의 %s 포트 alpha가 연결 비트와 일치한다" % [mask_value, variant_index, side]
				)


func _test_renderer_contract() -> void:
	var source := FileAccess.get_file_as_string(RENDERER_SOURCE)
	var draw_body := _function_body(source, "draw")
	var back_threshold := draw_body.find("_draw_stage01_threshold_layer(tile_grid, \"back\")")
	var back_wall := draw_body.find("_draw_back_wall_layer")
	var front_wall := draw_body.find("_draw_room_wall_layer(tile_grid, \"wall_front\")")
	var front_threshold := draw_body.find("_draw_stage01_threshold_layer(tile_grid, \"front\")")
	_expect(back_threshold >= 0 and back_wall > back_threshold, "N/W 문턱은 후면 벽보다 먼저 합성된다")
	_expect(front_wall >= 0 and front_threshold > front_wall, "E/S 문턱은 전면 벽 단계 뒤에 합성된다")
	_expect(source.contains("Control.MOUSE_FILTER_IGNORE"), "가장자리 overlay는 전투 입력을 받지 않는다")
	_expect(source.contains("stage01_edge_mask.draw_center = bool"), "9-slice 중앙 비표시 계약을 renderer에 연결한다")
	_expect(source.contains("draw_texture_rect_region"), "도로 autotile은 atlas 영역을 실제 bitmap으로 합성한다")
	_expect(source.contains("int(record.get(\"mask\", 0))"), "도로 autotile 선택은 셀의 N/E/S/W 연결 mask를 사용한다")
	var bridge_body := _function_body(source, "_draw_connection_bridge_layer")
	_expect(bridge_body.contains("connection_mode"), "공용 격자 프로필은 셀 중심 사이에 임의 회전 도로 strip을 덧그리지 않는다")
	_expect(not source.contains("_draw_stage01_connection_bridge_asset"), "폐기한 Stage 01 회전 도로 bitmap 경로를 다시 사용하지 않는다")
	_expect(source.contains("CorridorTopologyBuilderScript.build"), "모든 맵은 공용 통로 topology builder를 사용한다")
	_expect(source.contains("_build_visual_topology_patches"), "DAY 3 방어자 연결로는 실제 2x2 시각 격자 patch에 편입된다")
	_expect(source.contains("_v122_defender_connector_cells"), "DAY 3 연결로는 고정된 격자 칸을 사용한다")
	_expect(
		source.contains("propstage:throne_f:stage_01_cave:SW:back"),
		"projection-safe 5x5 왕좌 예외는 Stage 01 exact key로 제한된다"
	)


func _image_size(path: String) -> Vector2i:
	var texture := ResourceLoader.load(path) as Texture2D
	if texture == null:
		return Vector2i.ZERO
	return texture.get_size()


func _max_alpha_near(image: Image, center: Vector2i) -> float:
	var result := 0.0
	for y in range(center.y - 2, center.y + 3):
		for x in range(center.x - 2, center.x + 3):
			result = maxf(result, image.get_pixel(x, y).a)
	return result


func _function_body(source: String, function_name: String) -> String:
	var marker := "func %s(" % function_name
	var start := source.find(marker)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + marker.length())
	return source.substr(start, source.length() - start) if next < 0 else source.substr(start, next - start)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
