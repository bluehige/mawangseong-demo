extends Node

const RendererScript = preload("res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd")
const RENDERER_SOURCE := "res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd"

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_manifest_lookup()
	_test_runtime_dimensions()
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
	_expect(stage.get("corridor_cells", {}).size() == 4, "Stage 01 복도 셀 lookup은 번호가 고정된 4종이다")
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
	_expect(renderer.has_stage01_spatial_textures(), "renderer가 Stage 01 공간 자산 10종을 모두 로드한다")
	_expect(renderer.debug_stage01_spatial_texture_count() == 10, "Stage 01 runtime texture count는 10이다")


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
	_expect(
		source.contains("propstage:throne_f:stage_01_cave:SW:back"),
		"projection-safe 5x5 왕좌 예외는 Stage 01 exact key로 제한된다"
	)


func _image_size(path: String) -> Vector2i:
	var texture := ResourceLoader.load(path) as Texture2D
	if texture == null:
		return Vector2i.ZERO
	return texture.get_size()


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
