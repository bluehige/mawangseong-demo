extends SceneTree

const RENDERER_PATH := "res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd"
const WALL_CANVAS_PATH := "res://scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd"
const ASSET_MANIFEST_PATH := "res://data/dungeon_quarter/asset_manifest.json"

var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var renderer_source := _read(RENDERER_PATH)
	var wall_canvas_source := _read(WALL_CANVAS_PATH)
	_expect(not renderer_source.is_empty(), "QuarterDungeonRenderer 소스를 읽어야 함")
	_expect(not wall_canvas_source.is_empty(), "QuarterDungeonWallCanvas 소스를 읽어야 함")
	if failures.is_empty():
		_check_renderer_contract(renderer_source)
		_check_canvas_contract(wall_canvas_source)
		_check_alpha_contract(_read(ASSET_MANIFEST_PATH))
	_finish()


func _check_renderer_contract(source: String) -> void:
	_expect(source.contains("var back_wall_canvas: Node2D = null"), "BackWall canvas 상태를 보유")
	_expect(source.contains("var object_front_canvas: Node2D = null"), "ObjectFront canvas 상태를 보유")
	_expect(source.contains("func _ensure_back_wall_canvas() -> void"), "BackWall canvas 생성 함수가 존재")
	_expect(source.contains("func _ensure_object_front_canvas() -> void"), "ObjectFront canvas 생성 함수가 존재")
	_expect(source.contains('back_wall_canvas.setup(self, "wall_back")'), "BackWall canvas가 wall_back을 담당")
	_expect(source.contains('object_front_canvas.setup(self, "object_front")'), "ObjectFront canvas가 object_front를 담당")
	_expect(source.contains('front_wall_canvas.setup(self, "wall_front")'), "FrontWall canvas가 wall_front를 담당")
	var draw_start := source.find("func draw() -> void:")
	var draw_end := source.find("func _platform_render_profile()", draw_start)
	var draw_source := source.substr(draw_start, draw_end - draw_start)
	var wall_index := draw_source.find("_draw_back_wall_layer(tile_grid)")
	var actor_index := draw_source.find('_draw_object_layer(tile_grid, "back")')
	_expect(wall_index >= 0, "구조벽 본체를 정적 맵 draw에서 직접 그린다")
	_expect(actor_index > wall_index, "구조벽 본체를 캐릭터·방 오브젝트보다 먼저 그린다")
	_expect(not draw_source.contains('_draw_object_layer(tile_grid, "front")'), "전면 소품을 바닥과 같은 GameRoot에 그리지 않는다")
	_expect(
		draw_source.contains("if render_profile != RENDER_PROFILE_MOBILE:\n\t\t_draw_edge_skirt_layer(tile_grid)\n\t\t_draw_back_wall_layer(tile_grid)"),
		"모바일 경량 프로필에서는 높은 후면 구조벽을 생략한다"
	)
	var canvas_start := source.find("func draw_wall_canvas_layer(")
	var canvas_end := source.find("func debug_wall_canvas_contract()", canvas_start)
	var canvas_source := source.substr(canvas_start, canvas_end - canvas_start)
	_expect(not canvas_source.contains("_draw_back_wall_layer("), "BackWall 호환 canvas가 벽 본체를 중복으로 그리지 않는다")
	_expect(canvas_source.contains("_draw_front_wall_layer(_tile_grid_for_draw(), draw_target)"), "FrontWall canvas가 전면 벽 전체를 별도로 그린다")
	_expect(canvas_source.contains('_draw_object_layer(_tile_grid_for_draw(), "front", draw_target)'), "ObjectFront canvas가 전면 소품을 실제 별도 레이어에 그린다")
	var front_start := source.find("func _draw_front_wall_layer(")
	var front_end := source.find("func _draw_active_overlay(", front_start)
	var front_source := source.substr(front_start, front_end - front_start)
	_expect(not front_source.contains("_draw_wall_edge_front_occluder("), "캐릭터 앞에 고정된 구조벽 돌출 띠를 제거했다")
	_expect(front_source.contains("_draw_wall_edge_record(record, draw_target, alpha)"), "전면 벽은 얇은 띠가 아니라 전체 본체를 반투명으로 그린다")
	_expect(front_source.contains('not in ["E", "S"]'), "전면 레이어는 E/S 카메라 방향 벽만 담당한다")
	_expect(source.contains('not in ["N", "W"]'), "정적 맵은 N/W 후면 벽만 담당한다")
	_expect(source.contains('"static_draw_scope": "rear_structural_wall_body_before_objects"'), "후면 구조벽의 정적 draw 범위를 기록한다")
	_expect(source.contains('"object_front_draw_scope": "front_props_at_depth_30"'), "전면 소품의 실제 깊이 계약을 기록한다")
	_expect(source.contains('"front_draw_scope": "translucent_full_body_above_actors"'), "전면 구조벽 전체 반투명 계약을 기록한다")
	_expect(source.contains("func debug_structural_wall_draw_rect(record: Dictionary) -> Rect2"), "캡처가 실제 벽 PNG draw rect를 조회할 수 있다")
	_expect(source.contains("func debug_structural_wall_overlap_sample(record: Dictionary) -> Dictionary"), "캡처가 벽 PNG의 실제 불투명 픽셀을 고를 수 있다")
	_expect(source.contains("func debug_structural_wall_source_alpha_at(record: Dictionary, world_position: Vector2) -> float"), "캡처가 겹침 지점의 벽 원본 alpha를 검증할 수 있다")
	_expect(source.contains("target.draw_texture_rect(texture, draw_rect"), "소품 texture는 지정된 ObjectFront draw target을 사용한다")
	_expect(source.contains("target.draw_line(start, end"), "소품 연결 표지도 지정된 ObjectFront draw target을 사용한다")


func _check_canvas_contract(source: String) -> void:
	_expect(source.contains("renderer.draw_wall_canvas_layer(self, wall_layer_name)"), "canvas가 renderer draw API를 호출")
	_expect(source.contains('"translucent_front_wall" if wall_layer_name == "wall_front"'), "canvas가 전면 반투명 벽 역할을 명시한다")
	_expect(source.contains('wall_layer_name == "object_front"'), "canvas가 전면 소품 레이어 역할도 명시한다")


func _check_alpha_contract(manifest_source: String) -> void:
	var parsed = JSON.parse_string(manifest_source)
	_expect(parsed is Dictionary, "벽 렌더 프로필 JSON을 읽는다")
	if not parsed is Dictionary:
		return
	var alpha := float(parsed.get("spatial_asset_profiles", {}).get("cave_v2_grid", {}).get("wall_render", {}).get("front_occlusion_alpha", -1.0))
	_expect(alpha >= 0.30 and alpha <= 0.58, "전면 벽은 형태와 캐릭터가 모두 보이는 반투명 범위다")


func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _finish() -> void:
	if failures.is_empty():
		print("V122_FRONT_WALL_ACTOR_VISIBILITY_TEST: PASS (%d assertions)" % assertions)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_FRONT_WALL_ACTOR_VISIBILITY_TEST: FAIL (%d assertions)" % assertions)
	quit(1)


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
