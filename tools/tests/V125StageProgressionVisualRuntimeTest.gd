extends Node

const RendererScript = preload("res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd")

const STAGES := {
	"stage_02_castle": {
		"number": "02",
		"background_id": "bg_stage02_castle",
		"background_path": "res://assets/backgrounds/v125/bg_stage02_castle.png",
	},
	"stage_03_keep": {
		"number": "03",
		"background_id": "bg_stage03_keep",
		"background_path": "res://assets/backgrounds/v125/bg_stage03_keep.png",
	},
	"stage_04_citadel": {
		"number": "04",
		"background_id": "bg_stage04_citadel",
		"background_path": "res://assets/backgrounds/v125/bg_stage04_citadel.png",
	},
}

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_manifest_contract()
	_test_runtime_dimensions()
	_test_autotile_ports()
	_test_renderer_loading()
	if failures.is_empty():
		print("V125_STAGE_PROGRESSION_VISUAL_RUNTIME_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V125_STAGE_PROGRESSION_VISUAL_RUNTIME_TEST: FAIL")
	get_tree().quit(1)


func _test_manifest_contract() -> void:
	var profiles: Dictionary = DataRegistry.quarter_asset_manifest.get("stage_spatial_profiles", {})
	var visuals: Dictionary = DataRegistry.quarter_asset_manifest.get("stage_spatial_visuals", {})
	var backgrounds: Dictionary = DataRegistry.quarter_asset_manifest.get("backgrounds", {})
	var entrance: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {}).get("entrance_gate_f", {})
	for stage_id in STAGES.keys():
		var expected: Dictionary = STAGES[stage_id]
		var profile: Dictionary = profiles.get(stage_id, {})
		_expect(str(profile.get("corridor_floor_mode", "")) == "stage_atlas", "%s는 전용 bitmap 통로를 사용한다" % stage_id)
		_expect(str(profile.get("special_visuals", "")) == stage_id, "%s의 공간 lookup은 자기 단계 ID를 사용한다" % stage_id)
		_expect(str(profile.get("background_id", "")) == str(expected["background_id"]), "%s는 전용 배경판을 사용한다" % stage_id)
		_expect(str(profile.get("wall_modulate", "")) != "", "%s는 벽 색 통합값을 선언한다" % stage_id)
		_expect(str(profile.get("object_modulate", "")) != "", "%s는 시설 색 통합값을 선언한다" % stage_id)
		var visual: Dictionary = visuals.get(stage_id, {})
		_expect(visual.get("corridor_cells", {}).size() == 4, "%s는 parity fallback 셀 4종을 보존한다" % stage_id)
		var autotile: Dictionary = visual.get("corridor_autotile", {})
		_expect(int(autotile.get("mask_count", 0)) == 16, "%s 자동타일은 N/E/S/W 16개 연결 mask를 사용한다" % stage_id)
		_expect(autotile.get("variant_order", []) == ["00", "10", "01", "11"], "%s 자동타일 변형 순서가 고정된다" % stage_id)
		_expect(str(visual.get("cavern_edge_mask", {}).get("path", "")) != "", "%s 외곽이 검은 사각형으로 끝나지 않는다" % stage_id)
		var background: Dictionary = backgrounds.get(expected["background_id"], {})
		_expect(str(background.get("path", "")) == str(expected["background_path"]).trim_prefix("res://"), "%s 배경 경로가 manifest와 일치한다" % stage_id)
	var entrance_stage_placement: Dictionary = entrance.get("stage_placement", {})
	var stage03_entrance: Dictionary = entrance_stage_placement.get("stage_03_keep", {}).get("default", {})
	var stage04_entrance: Dictionary = entrance_stage_placement.get("stage_04_citadel", {}).get("default", {})
	_expect(not bool(stage03_entrance.get("full_grid_fallback", true)), "Stage 03 입구는 구형 전체 방 강제 확대를 사용하지 않는다")
	_expect(not bool(stage04_entrance.get("full_grid_fallback", true)), "Stage 04 입구는 구형 전체 방 강제 확대를 사용하지 않는다")
	_expect(float(stage04_entrance.get("fit_width", 2.0)) < float(stage03_entrance.get("fit_width", 0.0)), "Stage 04 입구는 상단 HUD 안전 영역에 맞게 Stage 03보다 작다")


func _test_runtime_dimensions() -> void:
	for stage_id in STAGES.keys():
		var expected: Dictionary = STAGES[stage_id]
		var number := str(expected["number"])
		var stage_dir := "stage_%s" % number
		_expect(_image_size(str(expected["background_path"])) == Vector2i(1536, 1024), "%s 배경은 1536x1024이다" % stage_id)
		_expect(_image_size("res://assets/tiles/%s/spatial/corridor_surface_stage%s_2cell.png" % [stage_dir, number]) == Vector2i(256, 128), "%s 기본 통로는 256x128이다" % stage_id)
		for cell_id in ["00", "10", "01", "11"]:
			var cell_path := "res://assets/tiles/%s/spatial/corridor_surface_stage%s_cell_%s.png" % [stage_dir, number, cell_id]
			_expect(_image_size(cell_path) == Vector2i(128, 64), "%s %s 셀은 128x64이다" % [stage_id, cell_id])
		var atlas_path := "res://assets/tiles/%s/spatial_road_autotile_v1/corridor_road_autotile_stage%s_atlas.png" % [stage_dir, number]
		_expect(_image_size(atlas_path) == Vector2i(2048, 256), "%s 자동타일 atlas는 2048x256이다" % stage_id)


func _test_autotile_ports() -> void:
	var ports := {
		"N": {"bit": 1, "point": Vector2i(96, 16)},
		"E": {"bit": 2, "point": Vector2i(96, 48)},
		"S": {"bit": 4, "point": Vector2i(32, 48)},
		"W": {"bit": 8, "point": Vector2i(32, 16)},
	}
	for stage_id in STAGES.keys():
		var number := str(STAGES[stage_id]["number"])
		var atlas_path := "res://assets/tiles/stage_%s/spatial_road_autotile_v1/corridor_road_autotile_stage%s_atlas.png" % [number, number]
		var texture := ResourceLoader.load(atlas_path) as Texture2D
		var atlas := texture.get_image() if texture != null else null
		_expect(atlas != null and not atlas.is_empty(), "%s 자동타일 픽셀을 읽는다" % stage_id)
		if atlas == null or atlas.is_empty():
			continue
		for variant_index in range(4):
			for mask_value in range(16):
				var origin := Vector2i(mask_value * 128, variant_index * 64)
				_expect(_max_alpha_near(atlas, origin + Vector2i(64, 32)) > 0.35, "%s mask %02d 중심이 비지 않는다" % [stage_id, mask_value])
				for port in ports.values():
					var connected := (mask_value & int(port["bit"])) != 0
					var alpha := _max_alpha_near(atlas, origin + Vector2i(port["point"]))
					_expect(alpha > 0.08 if connected else alpha < 0.08, "%s mask %02d 포트가 연결 비트와 일치한다" % [stage_id, mask_value])


func _test_renderer_loading() -> void:
	var renderer = RendererScript.new()
	renderer._load_background_plate_textures()
	renderer._load_stage_spatial_textures()
	_expect(renderer.debug_missing_background_plates().is_empty(), "단계별 배경판이 모두 로드된다")
	for stage_id in STAGES.keys():
		_expect(renderer._has_stage_corridor_visual(stage_id), "%s 전용 통로 atlas가 renderer에 로드된다" % stage_id)
		_expect(renderer.stage_spatial_textures.has("%s:edge_mask" % stage_id), "%s 외곽 mask가 renderer에 로드된다" % stage_id)


func _image_size(path: String) -> Vector2i:
	var texture := ResourceLoader.load(path) as Texture2D
	return texture.get_size() if texture != null else Vector2i.ZERO


func _max_alpha_near(image: Image, center: Vector2i) -> float:
	var result := 0.0
	for y in range(center.y - 2, center.y + 3):
		for x in range(center.x - 2, center.x + 3):
			result = maxf(result, image.get_pixel(x, y).a)
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
