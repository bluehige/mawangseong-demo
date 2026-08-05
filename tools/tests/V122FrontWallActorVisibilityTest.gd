extends SceneTree

const RENDERER_PATH := "res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd"
const WALL_CANVAS_PATH := "res://scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd"

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
	_finish()


func _check_renderer_contract(source: String) -> void:
	_expect(source.contains("var back_wall_canvas: Node2D = null"), "BackWall canvas 상태를 보유")
	_expect(source.contains("func _ensure_back_wall_canvas() -> void"), "BackWall canvas 생성 함수가 존재")
	_expect(source.contains('back_wall_canvas.setup(self, "wall_back")'), "BackWall canvas가 wall_back을 담당")
	_expect(source.contains('front_wall_canvas.setup(self, "wall_front")'), "FrontWall canvas가 wall_front를 담당")
	_expect(source.contains("_draw_back_wall_layer(_tile_grid_for_draw(), draw_target)"), "wall_back canvas가 구조벽 본체를 그리는 경로를 사용")
	_expect(source.contains("_draw_front_wall_layer(_tile_grid_for_draw(), draw_target)"), "wall_front canvas가 앞가림을 그리는 경로를 사용")
	_expect(source.contains("_draw_wall_edge_record(record, draw_target)"), "구조벽 edge가 지정된 canvas로 그려짐")
	_expect(source.contains("_draw_wall_vertex_body_layer(tile_grid, draw_target)"), "구조벽 vertex가 지정된 canvas로 그려짐")
	_expect(source.contains("_queue_back_wall_canvas_redraw()"), "BackWall canvas redraw가 예약됨")
	_expect(not source.contains("\n\t\t_draw_back_wall_layer(tile_grid)\n"), "GameRoot 부모 draw에서 전체 벽 본체를 직접 그리지 않음")
	_expect(source.contains('"back_draw_scope": "structural_wall_body_only"'), "BackWall 범위가 구조벽 본체로 고정됨")
	_expect(source.contains('"front_draw_scope": "front_occluder_only"'), "FrontWall 범위가 앞가림으로 고정됨")


func _check_canvas_contract(source: String) -> void:
	_expect(source.contains("renderer.draw_wall_canvas_layer(self, wall_layer_name)"), "canvas가 renderer draw API를 호출")
	_expect(source.contains('wall_layer_name == "wall_front"'), "기존 wall_front 캔버스 식별자를 보존")


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
