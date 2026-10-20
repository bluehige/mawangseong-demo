extends Node
## Autoload in disposable QA copies only. Production callbacks/renderer stay active.
const Mode = preload("res://scripts/systems/campaign/CampaignModeService.gd")
const Council = preload("res://scripts/systems/campaign/CouncilSeasonService.gd")
var game: Node
var samples: Array = []
var textures := {}
var failures: Array[String] = []
var frames_ms: Array[float] = []
var counters: Array = []
var last_draw := 0
var measuring := false
var busy := false
var manual := false
var boot_ms := 0

func _ready() -> void:
	RenderingServer.frame_post_draw.connect(drawn)
	manual = OS.get_cmdline_user_args().has("--opt-manual")
	call_deferred("run")

func drawn() -> void:
	var now := Time.get_ticks_usec()
	if measuring and last_draw > 0:
		frames_ms.append((now-last_draw)/1000.0)
		counters.append({"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)})
	last_draw = now

func settle(count: int = 5) -> void:
	for i in count: await get_tree().process_frame

func run() -> void:
	await get_tree().process_frame
	game = get_tree().current_scene.get_node("GameRoot")
	get_window().size = Vector2i(900,506) if manual else Vector2i(1920,1080)
	await RenderingServer.frame_post_draw
	boot_ms = Time.get_ticks_msec()
	disable_saves()
	if not OS.get_user_data_dir().replace("\\","/").contains("v131_optimization"):
		failures.append("nonisolated profile"); finish(); return
	print("OPT_TITLE_MS ",boot_ms)
	if manual:
		print("OPT_MANUAL_READY"); return
	if OS.get_cmdline_user_args().has("--opt-checks"):
		await regression(); finish(); return
	busy = true
	await sample("title",4.0)
	await management(27,false)
	await sample("management_day27",4.0)
	await battle()
	await sample("combat_day27",18.0)
	game._set_screen("settings",false)
	await sample("hidden_battle_settings",4.0)
	game._set_screen("combat",false)
	await sample("resumed_combat_day27",4.0)
	await reset_game()
	await management(2,true)
	await sample("council_management_day2",4.0)
	await battle()
	await sample("council_combat_day2",14.0)
	finish()

func disable_saves() -> void:
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
	game.campaign_autosave_pending = false

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
	print("OPT_CHECK ",message," ",ok)

func regression() -> void:
	await management(2,false); await battle()
	var view = game.ui_layer.get_node("ApprovedMapManagement")
	var controller = view.battle
	var ui = view.battle_ui
	var unit = game.monster_units[0]
	check(game.current_screen=="combat" and controller.running,"actual approved combat")
	await settle(10)
	game._set_screen("settings",false); await settle(5)
	check(not view.is_visible_in_tree(),"settings hides retained view")
	var old_position: Vector2 = unit.vitals.position
	var old_time: float = game.combat_time
	get_tree().root.set_meta("opt_visual_calls",{})
	await settle(20)
	check(get_tree().root.get_meta("opt_visual_calls",{}).is_empty(),"hidden UI performs zero visual updates")
	check(is_equal_approx(old_time,game.combat_time),"hidden battle remains paused")
	check(unit.vitals.position==old_position,"hidden vitals remain unchanged")
	game._set_screen("combat",false); await settle(8)
	check(view.is_visible_in_tree() and view.battle==controller,"same battle restored")
	check(get_tree().root.get_meta("opt_visual_calls",{}).get("layout_vitals",0)>0,"visible layout resumes")
	check(game.combat_time>old_time,"battle resumes its simulation")
	# Keep the existing nonvisual notice expiry alive while hiding the view.
	view.hide(); game.continuity.promotion_notice_remaining = 2.0
	ui._process(.2)
	check(is_equal_approx(game.continuity.promotion_notice_remaining,1.8),"nonvisual notice expiry remains active")
	view.show()
	check(not game._has_defense_wave_for_day(29),"DAY29 remains preparation only")

func reset_game() -> void:
	game._shutdown_audio_for_exit(); game.queue_free(); await settle(6)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	get_tree().current_scene.add_child(game)
	disable_saves(); await settle()

func management(day: int, council: bool) -> void:
	game._onboarding_reset_game(); disable_saves()
	game.onboarding_enabled = false; game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false; game.story_feature_enabled = false
	game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
	game.continuity.acknowledge_update()
	game.start_flow.guide_step = 99; game.start_flow.guide_key = ""
	game.start_flow.intro_complete = true; game.start_flow.command_seen = true
	GameState.onboarding_complete = true; GameState.day = day
	game.campaign_cycle_index = 3 if council else 1
	if council:
		game.update4_active_run = Mode.default_active_run()
		game.update4_active_run.campaign_mode_id = Mode.COUNCIL_MODE_ID
		game._set_update4_council_day_state(Council.new_day_state(day))
	game._set_screen("management",false)
	get_window().size = Vector2i(900,506) if manual else Vector2i(1920,1080)
	await settle(12)
	var view = game.ui_layer.get_node_or_null("ApprovedMapManagement")
	if view == null: failures.append("approved management missing"); return
	view.monster_ui.auto_place()
	await settle(5)
	if council and not game._update4_council_mode_active(): failures.append("council inactive")

func battle() -> void:
	var view = game.ui_layer.get_node_or_null("ApprovedMapManagement")
	if view == null: failures.append("view absent before battle"); return
	seed(131004)
	# Use the shipped controller with the same deterministic legal placements.
	# QA skips progression prompts, not battle rules or wave data.
	if game._update4_council_mode_active():
		var state := Council.finish_management(game._update4_council_day_state(),DataRegistry.update4_council_campaign_days)
		state = Council.begin_combat(state.get("state",{}),DataRegistry.update4_council_campaign_days)
		if not state.get("ok",false): failures.append("council phase cannot begin"); return
		game._set_update4_council_day_state(state.state)
	view.monster_ui.set_mode("battle"); view.monster_ui.unit_layer.hide()
	view.battle = load("res://scripts/game/ApprovedBattleController.gd").new()
	view.battle.begin(view); view.show_battle_controls()
	view.battle.set_speed(1.0)
	await settle(5)
	if game.current_screen != "combat": failures.append("battle inactive")

func sample(label: String, seconds: float) -> void:
	await settle(15)
	frames_ms.clear(); counters.clear(); measuring = true
	get_tree().root.set_meta("opt_visual_calls",{})
	var begin := Time.get_ticks_msec()
	var max_enemies := 0
	while Time.get_ticks_msec()-begin < seconds*1000:
		await get_tree().process_frame
		max_enemies = maxi(max_enemies,game.enemy_units.size())
	measuring = false
	track_textures(game)
	var sorted := frames_ms.duplicate(); sorted.sort()
	var sum := 0.0
	for value in sorted: sum += value
	var avg := sum/maxi(1,sorted.size())
	var row := {"scenario":label,"screen":game.current_screen,"day":GameState.day,"cycle":game.campaign_cycle_index,"council":game._update4_council_mode_active(),"frame_count":sorted.size(),"fps":1000.0/maxf(.001,avg),"frame_ms":avg,"p95_ms":sorted[clampi(ceili(sorted.size()*.95)-1,0,sorted.size()-1)],"max_ms":sorted.max(),"counters":counters.duplicate(),"max_enemies":max_enemies,"combat_time":game.combat_time,"engine_end_ms":Time.get_ticks_msec()}
	samples.append(row)
	row["visual_calls"] = get_tree().root.get_meta("opt_visual_calls",{}).duplicate(true)
	row["window"] = str(get_window().size)
	print("OPT_SAMPLE ",label," fps=",snappedf(row.fps,.01)," enemies=",max_enemies," screen=",game.current_screen)
	if label.contains("combat") and (game.current_screen!="combat" or max_enemies==0): failures.append(label+" lacks live battle")
	write_results()
	if label in ["title","management_day27","combat_day27","council_combat_day2"]:
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.resize(960,540,Image.INTERPOLATE_LANCZOS)
		image.save_png("user://"+label+".png")

func track_textures(node: Node) -> void:
	var texture: Texture2D
	var size := Vector2.ZERO
	if node is TextureRect and node.is_visible_in_tree():
		texture = node.texture; size = node.size*node.get_global_transform().get_scale().abs()
	elif node is Sprite2D and node.is_visible_in_tree() and node.texture != null:
		texture = node.texture; size = node.get_rect().size*node.get_global_transform().get_scale().abs()
	if texture != null:
		var key := texture.resource_path
		if texture is AtlasTexture:
			key = texture.atlas.resource_path+"#"+str(texture.region)
		var old: Dictionary = textures.get(key,{"display_x":0.0,"display_y":0.0,"nodes":[]})
		old.display_x = maxf(old.display_x,size.x); old.display_y = maxf(old.display_y,size.y)
		if not str(node.get_path()) in old.nodes: old.nodes.append(str(node.get_path()))
		textures[key] = old
	for child in node.get_children(): track_textures(child)

func write_results() -> void:
	var file := FileAccess.open("user://optimization.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"boot_ms":boot_ms,"startup_data_load_ms":get_tree().root.get_meta("opt_load_all",[]),"startup_textures_ms":get_tree().root.get_meta("opt__load_textures",[]),"samples":samples,"textures":textures,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"window":str(get_window().size),"user_dir":OS.get_user_data_dir()},"\t"))

func finish() -> void:
	write_results()
	print("OPT_RESULT failures=",failures.size()," ",failures)
	game.campaign_autosave_pending = false; game._shutdown_audio_for_exit()
	get_tree().quit(0 if failures.is_empty() else 1)

func _input(event: InputEvent) -> void:
	if not manual or busy or not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_F6: open_manual.call_deferred()
	elif event.keycode == KEY_F8: screenshot.call_deferred()
	elif event.keycode == KEY_F10: finish()

func open_manual() -> void:
	busy = true
	if game.current_screen == "title": await management(27,false)
	elif game.current_screen == "management": await battle()
	await settle(); track_textures(game); write_results()
	busy = false

func screenshot() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if maxi(image.get_width(),image.get_height())>960:
		image.resize(960,roundi(image.get_height()*960.0/image.get_width()),Image.INTERPOLATE_LANCZOS)
	image.save_png("user://manual-"+game.current_screen+".png")
