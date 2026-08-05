extends SceneTree

const RENDERER_PATH := "res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd"
const UNIT_PATH := "res://scripts/units/Unit.gd"
const WALL_CANVAS_PATH := "res://scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var renderer_source := _read(RENDERER_PATH)
	var unit_source := _read(UNIT_PATH)
	var wall_canvas_source := _read(WALL_CANVAS_PATH)
	_expect(not renderer_source.is_empty(), "QuarterDungeonRenderer 소스를 읽어야 한다")
	_expect(not unit_source.is_empty(), "Unit 소스를 읽어야 한다")
	_expect(not wall_canvas_source.is_empty(), "QuarterDungeonWallCanvas 소스를 읽어야 한다")
	if failures.is_empty():
		_check_renderer_contract(renderer_source)
		_check_unit_contract(unit_source)
		_check_wall_canvas_contract(wall_canvas_source)
	_finish()


func _check_renderer_contract(source: String) -> void:
	_expect(source.contains("const UNIT_DEPTH_MIN := 1"), "유닛 depth 하한이 정적 바닥 0보다 높은 1로 고정되어야 한다")
	_expect(source.contains("const UNIT_DEPTH_MAX := 44"), "유닛 depth 상한이 44 슬롯으로 고정되어야 한다")
	_expect(source.contains("const FRONT_WALL_DEPTH := 50"), "전면 벽 경계가 50으로 고정되어야 한다")
	_expect(source.contains("func unit_depth_slot_bounds()"), "유닛 depth 슬롯 범위 API가 있어야 한다")
	_expect(source.contains("func unit_depth_slot_for_position(world_position: Vector2) -> int"), "월드 위치를 depth 슬롯으로 바꾸는 API가 있어야 한다")
	_expect(source.contains("func debug_depth_world_y_range() -> Vector2"), "맵 비례 Y 범위 조회 API가 있어야 한다")
	_expect(source.contains('"back_wall_sides": ["N", "W"]'), "N/W 후면 벽 계약이 기록되어야 한다")
	_expect(source.contains('"front_wall_sides": ["E", "S"]'), "E/S 전면 occluder 계약이 기록되어야 한다")
	_expect(source.contains('"front_wall_occluder": "translucent_full_body"'), "전면 구조벽 전체가 반투명 occluder로 동작한다")
	_expect(source.contains('"structural_wall_actor_policy": "rear_opaque_front_translucent"'), "후면 불투명·전면 반투명 깊이 계약이 있다")
	_expect(source.contains('"static_floor_depth": 0'), "정적 바닥 깊이 0이 계약에 기록되어야 한다")
	_expect(source.contains('"unit_depth_policy": "above_static_floor_below_front_wall"'), "유닛이 바닥 위·전면 벽 아래라는 계약이 있다")
	_expect(source.contains('"vfx_connection_state": "LIVE_DEPTH_CONNECTED"'), "VFX가 현재 live depth에 연결된 상태로 기록되어야 한다")
	_expect(source.contains("clampi(\n\t\troundi(lerpf(float(UNIT_DEPTH_MIN), float(UNIT_DEPTH_MAX), normalized))"), "슬롯 계산이 유한 범위로 clamp되어야 한다")
	_expect(source.contains("_draw_back_wall_layer(tile_grid)"), "정적 맵 draw에서 후면 구조벽 본체를 그린다")
	_expect(source.contains('_draw_object_layer(_tile_grid_for_draw(), "front", draw_target)'), "전면 소품은 ObjectFront canvas에 그린다")
	_expect(source.contains("_draw_front_wall_layer(_tile_grid_for_draw(), draw_target)"), "전면 canvas에서 반투명 구조벽 본체를 그린다")


func _check_unit_contract(source: String) -> void:
	_expect(source.contains("const FALLBACK_UNIT_DEPTH_MIN := 1"), "Unit fallback 하한도 정적 바닥보다 높아야 한다")
	_expect(source.contains("const FALLBACK_UNIT_DEPTH_MAX := 44"), "Unit fallback 상한이 renderer 계약과 같아야 한다")
	_expect(source.contains("func refresh_depth_slot() -> void"), "Unit이 매 프레임 depth 슬롯을 갱신해야 한다")
	_expect(source.contains('renderer.has_method("unit_depth_slot_for_position")'), "Unit이 renderer depth API를 호출해야 한다")
	_expect(source.contains("z_index = clampi(roundi(global_position.y), FALLBACK_UNIT_DEPTH_MIN, FALLBACK_UNIT_DEPTH_MAX)"), "renderer 미준비 시에도 FrontWall 경계를 넘지 않아야 한다")
	_expect(not source.contains("z_index = int(global_position.y)"), "raw 월드 Y를 z_index로 직접 쓰면 안 된다")
	_expect(source.contains("refresh_depth_slot()\n\tqueue_redraw()"), "이동 후 depth 슬롯을 갱신한 뒤 다시 그려야 한다")


func _check_wall_canvas_contract(source: String) -> void:
	_expect(source.contains('"canvas_layer": wall_layer_name'), "canvas 계약에 담당 레이어가 남아야 한다")
	_expect(source.contains('"translucent_front_wall" if wall_layer_name == "wall_front"'), "canvas가 전면 반투명 구조벽을 담당한다")
	_expect(source.contains('wall_layer_name == "object_front"'), "canvas가 전면 소품도 별도 깊이에서 담당한다")
	_expect(source.contains("renderer.has_method(\"debug_depth_contract\")"), "canvas가 renderer occlusion 계약을 노출해야 한다")


func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _finish() -> void:
	if failures.is_empty():
		print("V122_V4_A_DEPTH_SLOT_CONTRACT_TEST: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_V4_A_DEPTH_SLOT_CONTRACT_TEST: FAIL")
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
