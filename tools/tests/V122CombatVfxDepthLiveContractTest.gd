extends SceneTree

const Constants = preload("res://scripts/core/Constants.gd")

var failed := false
var assertion_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root_scene: PackedScene = load("res://scenes/game/GameRoot.tscn")
	var runtime := game_root_scene.instantiate()
	root.add_child(runtime)
	await _settle()
	runtime.set_process(false)
	runtime.set_physics_process(false)
	runtime.onboarding_enabled = false
	runtime.current_screen = Constants.SCREEN_COMBAT
	await _settle(2)

	var combat = runtime.combat_scene
	var renderer = runtime.quarter_renderer
	_expect(combat != null, "전투 컨트롤러가 live VFX depth 테스트에 연결")
	_expect(renderer != null and renderer.has_method("unit_depth_slot_for_position"), "renderer 유닛 depth 슬롯 API가 live VFX에 제공")
	_expect(renderer != null and renderer.has_method("front_wall_depth"), "renderer wall_front depth 경계가 live VFX에 제공")
	if combat == null or renderer == null:
		await _finish(runtime)
		return

	var world_position := Vector2(420, 260)
	var parent_depth := int(runtime.effect_root.z_index)
	var unit_depth := int(renderer.unit_depth_slot_for_position(world_position))
	var front_depth := int(renderer.front_wall_depth())
	var aerial_depth := mini(unit_depth + 12, front_depth - 1)
	_expect(unit_depth < front_depth, "유닛 슬롯이 wall_front보다 낮음")
	_expect(unit_depth <= 44 and unit_depth >= -40, "유닛 슬롯이 유한 depth 범위 안에 있음")

	_assert_live_profile(combat, "slash", unit_depth, parent_depth, world_position, "몸통 VFX")
	_assert_live_profile(combat, "fireball", aerial_depth, parent_depth, world_position, "공중 VFX")
	_assert_live_profile(combat, "fx_brassa_boss", front_depth + 1, parent_depth, world_position, "전면 VFX")

	var source := FileAccess.get_file_as_string("res://scripts/game/CombatSceneController.gd")
	_expect(source.contains('_apply_vfx_profile(sprite, "fireball", Vector2.ONE, true)'), "투사체 호출이 live depth를 사용")
	_expect(source.contains('_apply_vfx_profile(sprite, "slash", Vector2(0.72, 0.72), true)'), "근접 호출이 live depth를 사용")
	_expect(source.contains('_apply_vfx_profile(sprite, "impact", Vector2(0.72, 0.72), true)'), "피격 호출이 live depth를 사용")
	_expect(source.contains('_apply_vfx_profile(sprite, effect_id, effect_scale, true)'), "공통 burst 호출이 live depth를 사용")

	await _finish(runtime)


func _assert_live_profile(combat, effect_id: String, expected_global_depth: int, parent_depth: int, world_position: Vector2, label: String) -> void:
	var sprite: AnimatedSprite2D = combat._make_effect_sprite(effect_id, false, 0.0)
	_expect(sprite != null, "%s sprite 생성" % label)
	if sprite == null:
		return
	sprite.global_position = world_position
	combat._apply_vfx_profile(sprite, effect_id, Vector2.ONE, true)
	_expect(bool(sprite.get_meta("vfx_live_depth", false)), "%s가 live depth 메타데이터를 기록" % label)
	_expect(int(sprite.get_meta("vfx_global_depth", -999)) == expected_global_depth, "%s가 renderer depth를 사용" % label)
	_expect(sprite.z_index + parent_depth == expected_global_depth, "%s z가 FxLayer 부모 깊이를 보정" % label)
	sprite.queue_free()


func _settle(frame_count: int = 8) -> void:
	for _i in range(frame_count):
		await process_frame
		await physics_frame


func _finish(runtime: Node) -> void:
	if runtime != null and is_instance_valid(runtime):
		runtime.queue_free()
	await process_frame
	if failed:
		print("V122_COMBAT_VFX_DEPTH_LIVE_CONTRACT_TEST: FAIL (%d assertions)" % assertion_count)
		quit(1)
	else:
		print("V122_COMBAT_VFX_DEPTH_LIVE_CONTRACT_TEST: PASS (%d assertions)" % assertion_count)
		quit(0)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % message)
		return
	failed = true
	push_error("  FAIL - %s" % message)
