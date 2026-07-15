extends Node

const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const Constants = preload("res://scripts/core/Constants.gd")

const FACILITY_SAMPLE_SECONDS := 0.5
const FACILITY_SAMPLE_STEP := 1.0 / 60.0
const MAX_FACILITY_MAP_DRAWS := 7
const MAX_IDLE_COMBAT_MAP_DRAWS := 7
const MAX_ENGINEER_SPAWN_USEC := 16000

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	game._debug_skip_onboarding()
	await _check_world_render_guard(game)
	GameState.day = 20
	if game.combat_music_player != null:
		game.combat_music_player.stream = null
	var combat_start_started := Time.get_ticks_usec()
	game.combat_scene.start_combat()
	var combat_start_usec := Time.get_ticks_usec() - combat_start_started
	print("ENGINEER_PERF combat_start_usec=%d" % combat_start_usec)
	await get_tree().process_frame
	await _check_idle_combat_redraw_rate(game)

	_check_log_updates_in_place(game)
	await get_tree().process_frame
	_check_shared_engineer_animation_frames(game)
	await _check_facility_redraw_rate(game)

	game._kill_combat_music_tween()
	if game.combat_music_player != null:
		game.combat_music_player.stop()
		game.combat_music_player.stream = null
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	if failed:
		print("ENGINEER_PERFORMANCE_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("ENGINEER_PERFORMANCE_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _check_world_render_guard(game: Node) -> void:
	var renderer = game.quarter_renderer
	_expect(renderer.debug_render_profile() == renderer.RENDER_PROFILE_FULL, "Windows native uses the full dungeon render profile")
	renderer.debug_reset_draw_invocation_count()
	var previous_screen: String = game.current_screen
	game.current_screen = Constants.SCREEN_TITLE
	game._update_world_render_visibility()
	game.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(renderer.debug_draw_invocations() == 0, "Title screen does not submit hidden dungeon drawing")
	var background_layer = game.get_node_or_null("BackgroundVoidLayer")
	_expect(background_layer is CanvasItem and not background_layer.visible, "Title screen hides persistent dungeon canvas layers")
	game.current_screen = previous_screen
	game._update_world_render_visibility()
	game.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(renderer.debug_draw_invocations() >= 1, "Management screen restores dungeon drawing")
	_expect(background_layer is CanvasItem and background_layer.visible, "Management screen restores persistent dungeon canvas layers")


func _check_idle_combat_redraw_rate(game: Node) -> void:
	var draw_events := {"count": 0}
	var on_draw := func() -> void:
		draw_events["count"] = int(draw_events["count"]) + 1
	game.draw.connect(on_draw)
	var sample_steps := int(round(FACILITY_SAMPLE_SECONDS / FACILITY_SAMPLE_STEP))
	for _index in range(sample_steps):
		await get_tree().process_frame
	game.draw.disconnect(on_draw)
	print("ENGINEER_PERF idle_combat_map_draws=%d sample_seconds=%.1f" % [int(draw_events["count"]), FACILITY_SAMPLE_SECONDS])
	_expect(int(draw_events["count"]) <= MAX_IDLE_COMBAT_MAP_DRAWS, "Idle combat redraws the full map at most %d times in 0.5 seconds" % MAX_IDLE_COMBAT_MAP_DRAWS)


func _check_log_updates_in_place(game: Node) -> void:
	var screen_events := {"count": 0}
	var on_screen_changed := func(_screen_name: String) -> void:
		screen_events["count"] = int(screen_events["count"]) + 1
	SignalBus.screen_changed.connect(on_screen_changed)
	var child_ids_before := _child_instance_ids(game.ui_layer)
	game._log("공병 성능 회귀 로그")
	var child_ids_after := _child_instance_ids(game.ui_layer)
	SignalBus.screen_changed.disconnect(on_screen_changed)
	_expect(int(screen_events["count"]) == 0, "전투 로그 추가가 화면 전환 신호를 다시 내보내지 않음")
	_expect(child_ids_after == child_ids_before, "전투 로그 추가 뒤 기존 HUD 노드가 그대로 유지됨")
	_expect(_tree_has_text(game.ui_layer, "공병 성능 회귀 로그"), "새 전투 로그 문구가 즉시 표시됨")


func _check_shared_engineer_animation_frames(game: Node) -> void:
	var first_count: int = game.enemy_units.size()
	var first_started := Time.get_ticks_usec()
	game._spawn_enemy("engineer")
	var first_spawn_usec := Time.get_ticks_usec() - first_started
	var first_created: bool = game.enemy_units.size() == first_count + 1
	var first_engineer = game.enemy_units[-1] if first_created else null
	var second_count: int = game.enemy_units.size()
	var second_started := Time.get_ticks_usec()
	game._spawn_enemy("engineer")
	var second_spawn_usec := Time.get_ticks_usec() - second_started
	var second_created: bool = game.enemy_units.size() == second_count + 1
	var second_engineer = game.enemy_units[-1] if second_created else null
	print("ENGINEER_PERF spawn_usec first=%d second=%d" % [first_spawn_usec, second_spawn_usec])
	var both_engineers: bool = first_engineer != null and second_engineer != null and first_engineer.unit_id == "engineer" and second_engineer.unit_id == "engineer"
	_expect(both_engineers, "공병 두 명 생성")
	_expect(both_engineers and first_engineer.sprite.sprite_frames == second_engineer.sprite.sprite_frames, "공병들이 캐시된 SpriteFrames 하나를 공유")
	_expect(first_spawn_usec <= MAX_ENGINEER_SPAWN_USEC, "첫 공병 소환이 %dms 이내" % int(MAX_ENGINEER_SPAWN_USEC / 1000))
	_expect(second_spawn_usec <= MAX_ENGINEER_SPAWN_USEC, "두 번째 공병 소환이 %dms 이내" % int(MAX_ENGINEER_SPAWN_USEC / 1000))


func _check_facility_redraw_rate(game: Node) -> void:
	game.combat_paused = true
	var facility_room := str(game._room_by_facility("barracks", ""))
	_expect(facility_room != "", "무력화 계측용 병영 존재")
	if facility_room == "":
		return
	game._disable_facility_room(facility_room, 10.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var draw_events := {"count": 0}
	var on_draw := func() -> void:
		draw_events["count"] = int(draw_events["count"]) + 1
	game.draw.connect(on_draw)
	var sample_steps := int(round(FACILITY_SAMPLE_SECONDS / FACILITY_SAMPLE_STEP))
	for _index in range(sample_steps):
		game._update_facility_disables(FACILITY_SAMPLE_STEP)
		await get_tree().process_frame
	game.draw.disconnect(on_draw)
	print("ENGINEER_PERF facility_map_draws=%d sample_seconds=%.1f" % [int(draw_events["count"]), FACILITY_SAMPLE_SECONDS])
	_expect(int(draw_events["count"]) >= 1 and int(draw_events["count"]) <= MAX_FACILITY_MAP_DRAWS, "무력화 카운트다운이 0.5초 동안 전체 맵을 1~%d회 다시 그림" % MAX_FACILITY_MAP_DRAWS)


func _child_instance_ids(node: Node) -> Array[int]:
	var result: Array[int] = []
	for child in node.get_children():
		result.append(child.get_instance_id())
	return result


func _tree_has_text(node: Node, needle: String) -> bool:
	if node is Label and str(node.text).find(needle) >= 0:
		return true
	if node is RichTextLabel and str(node.text).find(needle) >= 0:
		return true
	for child in node.get_children():
		if _tree_has_text(child, needle):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[EngineerPerformance] FAIL: %s" % message)
