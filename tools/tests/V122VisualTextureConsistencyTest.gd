extends Node

## Stage 01 맵의 고해상도 소품과 타일이 같은 축소 필터 규칙을 쓰는지 확인한다.

var failures: Array[String] = []

const REPRESENTATIVE_ASSETS := {
	"corridor_autotile_atlas": {"path": "res://assets/tiles/stage_01/spatial_road_autotile_v2/corridor_road_autotile_stage01_atlas.png", "size": Vector2i(2048, 256)},
	"defender_connector_junction": {"path": "res://assets/tiles/stage_01/spatial_passage_v1/defender_connector_junction_stage01.png", "size": Vector2i(128, 64)},
	"threshold_n": {"path": "res://assets/tiles/stage_01/spatial/threshold_stage01_N_2cell.png", "size": Vector2i(256, 128)},
	"floor_mask_00": {"path": "res://assets/tiles/cave_v2/floor/floor_cave_v2_mask_00.png", "size": Vector2i(128, 64)},
	"throne_stage01": {"path": "res://assets/props/stage_01/room_throne_stage01_SW_open_s_back.png", "size": Vector2i(640, 640)},
	"edge_mask": {"path": "res://assets/ui/stage_01/cavern_edge_mask_stage01_9slice.png", "size": Vector2i(1024, 1024)},
}

const WORLD_MIPMAP_DIRECTORIES := [
	"res://assets/tiles/cave_v2",
	"res://assets/tiles/stage_01",
	"res://assets/props/stage_01",
]

const WORLD_MIPMAP_IMPORTS := [
	"res://assets/backgrounds/v2/bg_cave_f_3x3_01.png.import",
	"res://assets/ui/stage_01/cavern_edge_mask_stage01_9slice.png.import",
]

const RENDERER_SOURCE := "res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_representative_assets()
	_test_world_texture_filter_contract()
	_test_world_mipmap_imports()
	if failures.is_empty():
		print("V122_VISUAL_TEXTURE_CONSISTENCY_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_VISUAL_TEXTURE_CONSISTENCY_TEST: FAIL")
	get_tree().quit(1)


func _test_representative_assets() -> void:
	for asset_id in REPRESENTATIVE_ASSETS.keys():
		var entry: Dictionary = REPRESENTATIVE_ASSETS[asset_id]
		var path := str(entry["path"])
		var texture := ResourceLoader.load(path) as Texture2D
		_expect(texture != null, "%s를 로드할 수 있다" % path)
		if texture == null:
			continue
		_expect(Vector2i(texture.get_size()) == entry["size"], "%s 크기 %s가 기준 %s와 일치한다" % [path, texture.get_size(), entry["size"]])
		var image := texture.get_image()
		_expect(image != null and image.has_mipmaps(), "%s의 실제 import 결과에 밉맵이 있다" % path)


func _test_world_texture_filter_contract() -> void:
	var setting = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", null)
	_expect(setting != null, "기본 텍스처 필터 프로젝트 설정이 존재한다")
	_expect(int(setting) == 0, "전역 기본 필터는 UI 픽셀 선명도를 위해 변경하지 않는다")
	var source := FileAccess.get_file_as_string(RENDERER_SOURCE)
	_expect(source.contains("func _configure_stage01_world_texture_filter"), "Stage 01 월드 전용 필터 설정 함수가 있다")
	_expect(source.contains("CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS"), "Stage 01 월드는 선형 밉맵 필터를 사용한다")
	_expect(source.contains("plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS"), "동굴 배경판도 동일한 필터를 사용한다")
	_expect(source.contains("stage01_edge_mask.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS"), "동굴 가장자리 마스크도 동일한 필터를 사용한다")
	print("V122_VISUAL_TEXTURE_FILTER_PROFILE: stage01_world=linear_with_mipmaps, ui_default=%s" % setting)


func _test_world_mipmap_imports() -> void:
	var import_paths: Array[String] = []
	for import_path in WORLD_MIPMAP_IMPORTS:
		import_paths.append(import_path)
	for directory in WORLD_MIPMAP_DIRECTORIES:
		_collect_png_imports(directory, import_paths)
	_expect(import_paths.size() >= 100, "Stage 01 월드 타일·소품 밉맵 import 목록을 모두 수집한다")
	for import_path in import_paths:
		var import_text := FileAccess.get_file_as_string(import_path)
		_expect(import_text.contains("mipmaps/generate=true"), "%s가 축소 표시용 밉맵을 생성한다" % import_path)


func _collect_png_imports(directory: String, output: Array[String]) -> void:
	for file_name in DirAccess.get_files_at(directory):
		if file_name.ends_with(".png.import"):
			output.append("%s/%s" % [directory, file_name])
	for child_directory in DirAccess.get_directories_at(directory):
		_collect_png_imports("%s/%s" % [directory, child_directory], output)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
