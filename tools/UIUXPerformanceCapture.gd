extends Node
const Game = preload("res://scenes/game/GameRoot.tscn")
const Constants = preload("res://scripts/core/Constants.gd")
var game
func _ready() -> void:
	call_deferred("_run")
func frame() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	game = Game.instantiate()
	add_child(game)
	for i in range(6):
		await frame()
	game._debug_skip_onboarding()
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game.management_context_drawer_open = false
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	for i in range(60):
		await frame()
	var intervals: Array[float] = []
	var last := Time.get_ticks_usec()
	for i in range(180):
		await frame()
		var now := Time.get_ticks_usec()
		intervals.append(float(now - last) / 1000.0)
		last = now
	var dispatch: Array[float] = []
	var visible_response: Array[float] = []
	var accepted := 0
	for i in range(10):
		var card := game.ui_layer.find_child("MonsterCard_slime", true, false) as Button
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		event.position = card.get_global_rect().get_center()
		event.global_position = event.position
		var start := Time.get_ticks_usec()
		get_viewport().push_input(event, true)
		dispatch.append(float(Time.get_ticks_usec() - start) / 1000.0)
		if game.dragging_monster_id == "slime":
			accepted += 1
		await frame()
		visible_response.append(float(Time.get_ticks_usec() - start) / 1000.0)
		event.pressed = false
		event.button_mask = 0
		get_viewport().push_input(event, true)
		game._clear_management_action_mode(false)
		game._set_screen(Constants.SCREEN_MANAGEMENT)
		for n in range(6):
			await frame()
	var report := {"resolution": "1920x1080", "text_scale": UISettings.text_scale, "frame_ms": distribution(intervals), "input_dispatch_ms": distribution(dispatch), "input_next_render_ms": distribution(visible_response), "accepted": accepted, "samples": [180, 10], "renderer": RenderingServer.get_current_rendering_method()}
	DirAccess.make_dir_recursive_absolute("res://tmp")
	var file := FileAccess.open("res://tmp/uiux_performance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("UIUX_PERFORMANCE: " + JSON.stringify(report))
	get_tree().quit(0 if accepted == 10 else 1)
func distribution(samples: Array[float]) -> Dictionary:
	samples.sort()
	var sum := 0.0
	for sample in samples:
		sum += sample
	return {"mean": sum / samples.size(), "p50": samples[samples.size() / 2], "p95": samples[mini(samples.size() - 1, floori(samples.size() * 0.95))], "max": samples.back()}
