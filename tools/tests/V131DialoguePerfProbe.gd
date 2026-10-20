extends Node
## QA-export autoload only; never installed in the product project.
var game: Node
var costs: Dictionary = {}
var samples: Array = []
var frame_times: Array[float] = []
var last_draw := 0
var measuring := false
var busy := false
var checks := 0
var failures: Array[String] = []

func record_cost(key: String, elapsed: int) -> void:
	if not costs.has(key): costs[key] = {"calls":0,"ms":0.0}
	costs[key].calls += 1
	costs[key].ms += elapsed / 1000.0

func _ready() -> void:
	RenderingServer.frame_post_draw.connect(_drawn)
	for i in 40: await get_tree().process_frame
	game = get_tree().current_scene.get_node("GameRoot")
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
	game.campaign_autosave_pending = false
	game.story_feature_enabled = false; game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.campaign_cycle_index = 2
	get_window().size = Vector2i(1920,1080)
	print("PERF_READY ", OS.get_user_data_dir())
	if OS.get_cmdline_user_args().has("--qa-benchmark"): await benchmark()

func _drawn() -> void:
	var now := Time.get_ticks_usec()
	if measuring and last_draw > 0: frame_times.append((now-last_draw)/1000.0)
	last_draw = now

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or game == null: return
	print("QA_INPUT key=",event.keycode," physical=",event.physical_keycode," input=",game.is_processing_input()," pause=",game.pause_menu_open," update=",game.continuity.update_open," confirm=",game.continuity.confirmation_action," text_focus=",game._text_input_owns_keyboard()," skill=",game.combat_scene.skill_actions.is_active())
	if event.keycode == KEY_F10 and not busy:
		game.campaign_autosave_pending = false
		game._shutdown_audio_for_exit()
		get_tree().quit()
	elif event.keycode == KEY_F6 and not busy:
		# Match StartFlow.reset_run's logical-key fallback. Computer Use's
		# injected physical scan code is not the configured Space binding.
		game.start_flow.fresh = true
		game._onboarding_begin_dialogue(fixture(),"title","")
		capture.call_deferred("opened")
	elif event.keycode == KEY_F8 and not busy: capture.call_deferred("manual")
	elif event.keycode == KEY_F9 and not busy: benchmark.call_deferred()

func fixture() -> Array:
	var lines: Array = []
	for i in 25:
		var speaker: String = ["CHR_BATI","CHR_THIEF_NIA","CHR_GOLDIN","CHR_DARKLORD_PLAYER"][i%4]
		var emotion := "teasing" if speaker == "CHR_THIEF_NIA" else "dry"
		lines.append({"speaker":speaker,"emotion":emotion,"trigger":"opening_start","text":"마왕성에 온 것을 환영합니다. 오늘의 준비를 시작하겠습니다. %d"%i})
		lines.append({"speaker":speaker,"emotion":emotion,"text":"같은 초상으로 다음 대사를 읽습니다. 성을 함께 지켜 주세요. %d"%i})
		lines.append({"speaker":speaker,"emotion":emotion,"text":"긴 대사도 한 글자도 사라지지 않고 다음 페이지에서 계속 읽을 수 있어야 합니다. ".repeat(12)+str(i)})
	return lines

func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func settle(count: int = 5) -> void:
	for i in count: await get_tree().process_frame
	await RenderingServer.frame_post_draw

func measure(kind: String, action: Callable) -> void:
	await settle(4)
	costs.clear(); frame_times.clear(); measuring = true
	var started := Time.get_ticks_usec()
	action.call()
	var blocking := (Time.get_ticks_usec()-started)/1000.0
	await settle(3)
	measuring = false
	samples.append({"kind":kind,"blocking_ms":blocking,"frame_ms":frame_times.max() if not frame_times.is_empty() else 0.0,"frames":frame_times.duplicate(),"costs":costs.duplicate(true),"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))})

func benchmark() -> void:
	if busy: return
	busy = true
	await measure("first_entry",func(): game._onboarding_begin_dialogue(fixture(),"title",""))
	var body: RichTextLabel = game.story_presenter.page_body
	var original_body_id := body.get_instance_id()
	var initial_history: int = game.continuity.history.size()
	for i in 60:
		var target: int = game.onboarding_dialogue_index+1
		if target >= game.onboarding_dialogue_queue.size(): break
		var kind := "same_portrait" if target%3==1 else "long_text" if target%3==2 else "portrait_change"
		await measure(kind,func(): game._onboarding_advance_dialogue())
		while game.story_presenter.page_index+1 < game.story_presenter.text_pages.size():
			await measure("long_page",func(): game._onboarding_advance_dialogue())
		verify(game.story_presenter.page_body.get_meta("dialogue_full_text","") == game._onboarding_line_text(game.onboarding_dialogue_queue[game.onboarding_dialogue_index]),"page source preserved")
	await measure("log_open",func(): game.continuity.open_backlog())
	var old_index: int = game.onboarding_dialogue_index
	for i in 20: await measure("log_open_advance",func(): game._onboarding_advance_dialogue())
	verify(old_index == game.onboarding_dialogue_index,"backlog blocks input")
	game.continuity.close_backlog()
	await settle()
	game.story_presenter.toggle_legacy_auto()
	verify(game.story_presenter.legacy_auto_enabled,"auto on")
	game._onboarding_advance_dialogue()
	verify(not game.story_presenter.legacy_auto_enabled,"manual disables auto")
	var reuse: bool = original_body_id == game.story_presenter.page_body.get_instance_id()
	verify(game.continuity.history.size() >= initial_history,"history retained")
	# Check actual timer path and the explicit last-line stop.
	game.story_presenter.toggle_legacy_auto()
	game.story_presenter.legacy_auto_remaining = 0.0
	var auto_index: int = game.onboarding_dialogue_index
	game.story_presenter.tick_legacy_auto(0.1)
	verify(game.onboarding_dialogue_index > auto_index or game.story_presenter.page_index > 0,"auto advances")
	game.story_presenter.legacy_auto_enabled = false
	game.onboarding_dialogue_index = game.onboarding_dialogue_queue.size()-1
	game._story_refresh_dialogue_ui()
	await settle()
	game.story_presenter.page_index = game.story_presenter.text_pages.size()-1
	game.story_presenter.toggle_legacy_auto()
	game.story_presenter.legacy_auto_remaining = 0.0
	game.story_presenter.tick_legacy_auto(0.1)
	verify(game.story_presenter.auto_at_end and not game.story_presenter.legacy_auto_enabled,"auto stops at last line")
	game._onboarding_skip_dialogue()
	verify(game.onboarding_dialogue_queue.is_empty() and game.current_screen == "title","skip returns")
	# Existing story director path as well as legacy V130R dialogue.
	game.story_feature_enabled = true
	game.campaign_cycle_index = 1
	game.story_director.reset_for_new_game()
	var started: bool = game.story_director.start_scene("STORY_D01_MANAGEMENT_ENTRY",game._story_context(),"title","",true)
	if started: game._story_show_active_scene()
	verify(started,"story starts")
	if started:
		await settle()
		var story_body_id: int = game.story_presenter.page_body.get_instance_id()
		await measure("story_advance",func(): game._story_advance_dialogue())
		verify(game.story_presenter.page_body.get_meta("dialogue_full_text","") == LanguageSettings.story_text(game.story_director.current_cue(),game._onboarding_player_name()),"story text updated")
		reuse = reuse and story_body_id == game.story_presenter.page_body.get_instance_id()
	if OS.get_cmdline_user_args().has("--qa-expect-reuse"): verify(reuse,"dialogue controls reused")
	await capture("benchmark")
	var file := FileAccess.open("user://benchmark.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"samples":samples,"checks":checks,"failures":failures,"body_reused":reuse,"window":str(get_window().size),"viewport":str(get_viewport().get_visible_rect().size),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"user_dir":OS.get_user_data_dir()},"\t"))
	file.close()
	busy = false
	print("PERF_DONE samples=",samples.size()," checks=",checks," failures=",failures.size()," reused=",reuse)
	if OS.get_cmdline_user_args().has("--qa-benchmark"):
		game.campaign_autosave_pending = false
		game._shutdown_audio_for_exit()
		get_tree().quit(0 if failures.is_empty() else 1)

func capture(label: String) -> void:
	await settle()
	var image := get_viewport().get_texture().get_image()
	image.resize(960,540,Image.INTERPOLATE_LANCZOS)
	image.save_png("user://capture_"+label+".png")
	var file := FileAccess.open("user://capture_"+label+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"screen":game.current_screen,"index":game.onboarding_dialogue_index,"page":game.story_presenter.page_index,"backlog":game.continuity.backlog_open,"auto":game.story_presenter.legacy_auto_enabled,"window":str(get_window().size),"render":str(get_viewport().get_visible_rect().size),"input_enabled":game.is_processing_input(),"pause":game.pause_menu_open,"update":game.continuity.update_open,"confirmation":game.continuity.confirmation_action,"text_focus":game._text_input_owns_keyboard()},"\t"))
	file.close()
