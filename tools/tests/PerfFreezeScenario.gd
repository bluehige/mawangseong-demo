extends Node
## Rendered, isolated performance replay. Run with RunPerfFreeze.py.
const Constants = preload("res://scripts/core/Constants.gd")
var game: Node
var stage := "boot"
var stage_start := 0
var last_frame := 0
var next_sample := 0
var frames: Array[float] = []
var file: FileAccess
var output := ""
var input_clock := 0.0
var input_index := 0
var pan_started := false
var pan_ended := false
var combat_seconds := 0.0
var restarting := false
var battle_runs := 1
var tooltip_point := Vector2.ZERO

func _ready() -> void:
	get_window().focus_entered.connect(func(): print("PERF_FOCUS_IN"))
	get_window().focus_exited.connect(func(): print("PERF_FOCUS_OUT"))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--perf-out="): output = arg.trim_prefix("--perf-out=")
	if output.is_empty() or not ProjectSettings.globalize_path("user://").replace("\\", "/").contains("/tmp/v1213_perf/"):
		push_error("Performance replay needs isolated APPDATA and --perf-out")
		get_tree().quit(2)
		return
	file = FileAccess.open(output.path_join("engine.jsonl"), FileAccess.WRITE)
	get_tree().create_timer(400).timeout.connect(func(): get_tree().quit(2))
	call_deferred("run")

func settle() -> void:
	for i in range(12): await get_tree().process_frame

func phase(id: String, seconds: float) -> void:
	stage = id
	stage_start = Time.get_ticks_usec()
	last_frame = stage_start
	next_sample = stage_start + 1000000
	frames.clear()
	input_clock = 0.0
	input_index = 0
	pan_started = false
	pan_ended = false
	print("PERF_PHASE " + id)
	if not id.ends_with("background"): DisplayServer.window_move_to_foreground()
	if id == "combat":
		combat_seconds = 0.0
		while combat_seconds < seconds: await get_tree().create_timer(0.25).timeout
	else:
		while Time.get_ticks_usec()-stage_start < int(seconds*1000000):
			await get_tree().process_frame

func sample(now: int) -> void:
	frames.sort()
	var counters: Node = get_node_or_null("/root/PerfCounters")
	var row := {"stage":stage,"stage_s":float(now-stage_start)/1000000.0,"wall_ms":Time.get_unix_time_from_system()*1000,
		"screen":game.current_screen,"fps":Performance.get_monitor(Performance.TIME_FPS),
		"frame_mean_ms":0.0 if frames.is_empty() else frames.reduce(func(a,b): return a+b,0.0)/frames.size(),
		"frame_p95_ms":0.0 if frames.is_empty() else frames[mini(frames.size()-1,int(frames.size()*0.95))],
		"frame_max_ms":0.0 if frames.is_empty() else frames[-1],
		"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,
		"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),
		"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"vram_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"vsync":DisplayServer.window_get_vsync_mode(),"max_fps":Engine.max_fps,"focused":DisplayServer.window_is_focused(),
		"window":str(DisplayServer.window_get_size()),"renderer":RenderingServer.get_current_rendering_method(),
		"screen_id":DisplayServer.window_get_current_screen(),"refresh_hz":DisplayServer.screen_get_refresh_rate(),"window_position":str(DisplayServer.window_get_position()),
		"combat_seconds":combat_seconds,"battle_runs":battle_runs,
		"pointer_active":game.build_placement.pointer_active,"build_pick":game.build_pick_mode,"build_preview":game.build_preview_room_id,
		"counters":{} if counters == null else counters.take()}
	file.store_line(JSON.stringify(row))
	file.flush()
	frames.clear()

func _process(delta: float) -> void:
	if game == null or stage == "boot": return
	var now := Time.get_ticks_usec()
	frames.append(float(now-last_frame)/1000.0)
	last_frame = now
	if stage == "combat":
		if game.current_screen == Constants.SCREEN_COMBAT:
			combat_seconds += delta
		elif not restarting:
			restarting = true
			call_deferred("restart_battle")
	if now >= next_sample:
		sample(now)
		next_sample = now+1000000
	if stage not in ["management", "tutorial_pan", "placement", "tooltip"]: return
	input_clock += delta
	if input_clock < 1.0/60.0: return
	input_clock -= 1.0/60.0
	input_index += 1
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(960+sin(input_index*0.1)*220,450+cos(input_index*0.1)*90)
	if stage == "tooltip": motion.position = tooltip_point if input_index%120 < 60 else Vector2(960,450)
	motion.global_position = motion.position
	motion.relative = Vector2(cos(input_index*0.1)*22,-sin(input_index*0.1)*9)
	get_viewport().push_input(motion,true)
	if stage == "management":
		var t := float(now-stage_start)/1000000.0
		if t >= 20 and not pan_started:
			mouse_button(MOUSE_BUTTON_MIDDLE,true,motion.position)
			pan_started = true
		if t >= 40 and not pan_ended:
			mouse_button(MOUSE_BUTTON_MIDDLE,false,motion.position)
			pan_ended = true
		if t > 40 and input_index % 30 == 0:
			mouse_button(MOUSE_BUTTON_WHEEL_UP if input_index % 60 == 0 else MOUSE_BUTTON_WHEEL_DOWN,true,motion.position)

func restart_battle() -> void:
	# Natural DAY1 battles finish before 60 seconds. Repeat the same public
	# DAY1 runtime to collect 60 seconds of combat, without freezing its AI.
	game._set_screen(Constants.SCREEN_MANAGEMENT,false)
	game._start_combat()
	battle_runs += 1
	restarting = false

func mouse_button(index: int, pressed: bool, point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = index
	event.pressed = pressed
	get_viewport().push_input(event,true)

func tutorial(id: String) -> void:
	for i in range(game.tutorial_manager.steps.size()):
		var step: Dictionary = game.tutorial_manager.steps[i]
		if str(step.id) == id:
			game.tutorial_manager.current_index = i
			game.tutorial_manager.active = true
			game.onboarding_enabled = true
			game._onboarding_set_stage(str(step.stage))
			return

func capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))

func run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	DisplayServer.window_set_title("Mawangseong performance replay")
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false
	game.campaign_save_v5_enabled = false
	add_child(game)
	await settle()
	seed(1213)
	if OS.get_cmdline_user_args().has("--hotpaths-only"):
		var button := game.ui_layer.find_child("CampaignNewGameButton",true,false) as Control
		if button == null:
			push_error("Tooltip hover target missing")
			get_tree().quit(2)
			return
		tooltip_point = button.get_global_transform_with_canvas()*(button.size/2)
		await phase("tooltip",10)
		game._debug_skip_onboarding()
		GameState.day = 2
		GameState.gold = 5000
		game.onboarding_enabled = false
		game.tutorial_gate_enabled = false
		game._set_screen(Constants.SCREEN_MANAGEMENT,false)
		game.build_placement.begin("barracks",Vector2(960,450))
		await phase("placement",10)
		file.close()
		game.queue_free()
		await settle()
		get_tree().quit()
		return
	await capture("title")
	if OS.get_cmdline_user_args().has("--title-only"):
		await phase("title",15)
		await phase("title_background",15)
		if OS.get_cmdline_user_args().has("--cap-probe"):
			Engine.max_fps = 120
			await phase("title_cap120",15)
			Engine.max_fps = 30
			await phase("title_cap30_background",15)
		else:
			await phase("title_restore",5)
		file.close()
		game.queue_free()
		await settle()
		get_tree().quit()
		return
	await phase("title",30)
	stage = "transition"
	game._onboarding_start_new_game()
	await settle()
	game.onboarding_name_input.text = "Perf replay"
	game._onboarding_confirm_name()
	for i in range(80):
		if game.current_screen != Constants.SCREEN_DIALOGUE: break
		game._onboarding_advance_dialogue()
		await settle()
	if game.current_screen == Constants.SCREEN_INTRUSION_BRIEF:
		game._set_screen(Constants.SCREEN_MANAGEMENT,false)
	await settle()
	await capture("management")
	await phase("management",60)
	stage = "transition"
	mouse_button(MOUSE_BUTTON_MIDDLE,false,Vector2(960,450))
	# Use the real DAY1 combat runtime. Tutorial completion permits launch;
	# normal AI, audio, dialogue, simulation and process callbacks stay enabled.
	game._debug_skip_onboarding()
	game._set_screen(Constants.SCREEN_MANAGEMENT,false)
	game._start_combat()
	await settle()
	await capture("combat")
	await phase("combat",60)
	stage = "transition"
	if game.current_screen == Constants.SCREEN_COMBAT:
		game._finish_combat(true,"performance replay timeout fixture")
	await settle()
	await capture("result")
	await phase("result",10)
	# The newly added room-focus pan path is exercised separately from DAY1.
	stage = "transition"
	GameState.day = 2
	tutorial("TUT_110_TRAP_CORRIDOR")
	game.management_context_drawer_open = false
	game.management_tool_tab = "roster"
	game.selected_room = "entrance"
	game._set_screen(Constants.SCREEN_MANAGEMENT,false)
	await settle()
	mouse_button(MOUSE_BUTTON_MIDDLE,true,Vector2(960,450))
	await phase("tutorial_pan",15)
	mouse_button(MOUSE_BUTTON_MIDDLE,false,Vector2(960,450))
	stage = "transition"
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game._set_screen(Constants.SCREEN_MANAGEMENT,false)
	game.build_placement.begin("barracks",Vector2(960,450))
	await phase("placement",10)
	stage = "transition"
	game._set_screen(Constants.SCREEN_TITLE,false)
	await settle()
	await phase("title_background",15)
	stage = "done"
	file.close()
	game.queue_free()
	await settle()
	print("PERF_REPLAY_DONE")
	get_tree().quit()
