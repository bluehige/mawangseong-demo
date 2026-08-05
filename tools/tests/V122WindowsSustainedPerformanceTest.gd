extends Node

const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const DEFAULT_DURATION_SECONDS := 600.0
const WARMUP_SECONDS := 5.0
const EFFECT_INTERVAL_SECONDS := 0.50
const TRAP_INTERVAL_SECONDS := 1.00
const FACILITY_INTERVAL_SECONDS := 8.00
const FRAME_P95_LIMIT_MS := 20.0
const AVERAGE_FPS_FLOOR := 55.0
const MEMORY_GROWTH_LIMIT_BYTES := 64 * 1024 * 1024
const EFFECT_CHILDREN_LIMIT := 32

var game: Node
var duration_seconds := DEFAULT_DURATION_SECONDS
var report_path := "user://v122_windows_sustained_performance.json"
var started_usec := 0
var previous_frame_usec := 0
var effect_clock := 0.0
var trap_clock := 0.0
var facility_clock := 0.0
var sample_frame_ms: Array[float] = []
var sample_process_ms: Array[float] = []
var sample_draw_calls: Array[float] = []
var memory_start := 0.0
var memory_peak := 0.0
var effect_children_baseline := 0
var effect_children_peak := 0
var trap_slots: Array[String] = []
var running := false


func _ready() -> void:
	_parse_arguments()
	call_deferred("_start_run")


func _start_run() -> void:
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(3)
	game._debug_skip_onboarding()
	await _settle(3)
	GameState.day = 20
	game.combat_scene.start_combat()
	await _settle(5)
	# Stop product combat simulation without pausing SceneTree tweens. Pausing combat here
	# would also pause effect cleanup callbacks and turn this harness into an allocator.
	game.combat_paused = false
	game.set_physics_process(false)
	for unit in game.monster_units + game.enemy_units:
		if is_instance_valid(unit):
			unit.set_physics_process(false)
	_prepare_stress_state()
	await _settle(3)
	game.quarter_renderer.debug_reset_draw_invocation_count()
	effect_children_baseline = game.effect_root.get_child_count()
	effect_children_peak = effect_children_baseline
	memory_start = float(Performance.get_monitor(Performance.MEMORY_STATIC))
	memory_peak = memory_start
	started_usec = Time.get_ticks_usec()
	previous_frame_usec = started_usec
	running = true
	print("V122_WINDOWS_SUSTAINED_PERFORMANCE: START duration=%.1f report=%s" % [duration_seconds, report_path])


func _process(delta: float) -> void:
	if not running:
		return
	var now := Time.get_ticks_usec()
	var elapsed := float(now - started_usec) / 1_000_000.0
	var frame_ms := float(now - previous_frame_usec) / 1000.0
	previous_frame_usec = now

	_drive_stress_effects(delta)
	var current_memory := float(Performance.get_monitor(Performance.MEMORY_STATIC))
	memory_peak = maxf(memory_peak, current_memory)
	effect_children_peak = maxi(effect_children_peak, game.effect_root.get_child_count())
	if elapsed >= WARMUP_SECONDS:
		sample_frame_ms.append(frame_ms)
		sample_process_ms.append(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
		sample_draw_calls.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	if elapsed >= duration_seconds:
		running = false
		_finish_run(elapsed, current_memory)


func _prepare_stress_state() -> void:
	var combat = game.combat_scene
	combat.acid_telegraphs.clear()
	for index in range(20):
		combat.acid_telegraphs.append({
			"position": game.graph.center("spike_corridor") + Vector2(float(index % 5) * 12.0, float(index / 5) * 8.0),
			"radius": 85.0,
			"remaining": duration_seconds + 60.0,
			"total": duration_seconds + 60.0
		})
	for slot_value in game.quarter_renderer._tile_grid_for_draw().get("objects", []):
		if not slot_value is Dictionary or str(slot_value.get("id", "")) != "spike_floor":
			continue
		var instance_id := str(slot_value.get("instance_id", ""))
		if instance_id != "" and not trap_slots.has(instance_id):
			trap_slots.append(instance_id)
	game.combat_scene._update_combat_overlay_redraw(0.11)


func _drive_stress_effects(delta: float) -> void:
	var combat = game.combat_scene
	effect_clock += delta
	trap_clock += delta
	facility_clock += delta
	combat._update_combat_overlay_redraw(delta)
	if effect_clock >= EFFECT_INTERVAL_SECONDS:
		effect_clock = 0.0
		for index in range(8):
			combat.spawn_effect_burst(
				"impact",
				game.graph.center("spike_corridor") + Vector2(float(index % 4) * 14.0, float(index / 4) * 12.0)
			)
	if trap_clock >= TRAP_INTERVAL_SECONDS:
		trap_clock = 0.0
		for instance_id in trap_slots:
			game.quarter_renderer.trigger_trap_animation(instance_id, "spike_floor")
	if facility_clock >= FACILITY_INTERVAL_SECONDS:
		facility_clock = 0.0
		var facility_room := str(game._room_by_facility("barracks", ""))
		if facility_room != "":
			game._disable_facility_room(facility_room, 10.0)
	game._update_facility_disables(delta)


func _finish_run(elapsed: float, memory_end: float) -> void:
	var frame_summary := _summarize(sample_frame_ms)
	var process_summary := _summarize(sample_process_ms)
	var draw_summary := _summarize(sample_draw_calls)
	var average_fps := 1000.0 / maxf(0.001, float(frame_summary.get("avg", 0.0)))
	var memory_growth := memory_end - memory_start
	var effect_children_end: int = game.effect_root.get_child_count()
	var passed := (
		average_fps >= AVERAGE_FPS_FLOOR
		and float(frame_summary.get("p95", 9999.0)) <= FRAME_P95_LIMIT_MS
		and memory_growth <= MEMORY_GROWTH_LIMIT_BYTES
		and effect_children_peak - effect_children_baseline <= EFFECT_CHILDREN_LIMIT
		and effect_children_end - effect_children_baseline <= EFFECT_CHILDREN_LIMIT
	)
	var report := {
		"schema_version": 1,
		"duration_seconds": elapsed,
		"warmup_seconds": WARMUP_SECONDS,
		"resolution": [1280, 720],
		"rendering_device_available": RenderingServer.get_rendering_device() != null,
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"video_adapter_vendor": RenderingServer.get_video_adapter_vendor(),
		"video_adapter_api_version": RenderingServer.get_video_adapter_api_version(),
		"sample_count": sample_frame_ms.size(),
		"average_fps": average_fps,
		"frame_ms": frame_summary,
		"process_ms": process_summary,
		"draw_calls": draw_summary,
		"memory_static_start_bytes": memory_start,
		"memory_static_peak_bytes": memory_peak,
		"memory_static_end_bytes": memory_end,
		"memory_static_growth_bytes": memory_growth,
		"effect_children_baseline": effect_children_baseline,
		"effect_children_peak": effect_children_peak,
		"effect_children_end": effect_children_end,
		"full_map_draws_after_warmup": game.quarter_renderer.debug_draw_invocations(),
		"stress": {
			"telegraphs": 20,
			"impact_bursts_per_half_second": 8,
			"trap_slots": trap_slots.size(),
			"facility_refresh_seconds": FACILITY_INTERVAL_SECONDS
		},
		"limits": {
			"average_fps_floor": AVERAGE_FPS_FLOOR,
			"frame_p95_ms": FRAME_P95_LIMIT_MS,
			"memory_growth_bytes": MEMORY_GROWTH_LIMIT_BYTES,
			"effect_children_above_baseline": EFFECT_CHILDREN_LIMIT
		},
		"status": "PASS" if passed else "FAIL"
	}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		push_error("[V122WindowsSustainedPerformance] Cannot write report: %s" % report_path)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("V122_WINDOWS_SUSTAINED_PERFORMANCE: %s" % JSON.stringify(report))
	get_tree().quit(0 if passed else 1)


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--duration="):
			duration_seconds = maxf(WARMUP_SECONDS + 1.0, float(argument.trim_prefix("--duration=")))
		elif argument.begins_with("--report="):
			report_path = argument.trim_prefix("--report=")


func _summarize(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"count": 0, "min": 0.0, "avg": 0.0, "p95": 0.0, "p99": 0.0, "max": 0.0}
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	for value in values:
		total += value
	return {
		"count": sorted.size(),
		"min": sorted.front(),
		"avg": total / float(sorted.size()),
		"p95": sorted[clampi(int(ceil(float(sorted.size()) * 0.95)) - 1, 0, sorted.size() - 1)],
		"p99": sorted[clampi(int(ceil(float(sorted.size()) * 0.99)) - 1, 0, sorted.size() - 1)],
		"max": sorted.back()
	}


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame
