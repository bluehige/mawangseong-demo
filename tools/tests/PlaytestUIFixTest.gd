extends Node
## Serial GUI fixture, isolated by run_playtest_ui.py; never loads player saves.
const OUT := "res://tmp/playtest_ui_20261019/"
var game: Node
var phase := "after"
var failures: Array = []
var checks := 0
var rows: Array = []

func _ready() -> void: run.call_deferred()
func frames(n: int = 5) -> void:
	for i in n: await get_tree().process_frame
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func clear() -> void:
	for child in game.ui_layer.get_children(): child.free()
func capture(name: String) -> void:
	await frames()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OUT + phase + "_" + name + ".png")
func silhouette(control: TextureRect) -> Rect2:
	var pixels := control.texture.get_image()
	if pixels.is_compressed(): pixels.decompress()
	var bounds: Rect2i = game.story_presenter.standing_visible_bounds(control.texture)
	var factor := minf(control.size.x / pixels.get_width(), control.size.y / pixels.get_height())
	return Rect2(control.position + (control.size - Vector2(pixels.get_size()) * factor) * 0.5 + Vector2(bounds.position) * factor, Vector2(bounds.size) * factor)
func dialogue(id: String) -> Control:
	clear()
	game.onboarding_dialogue_queue.assign([{"speaker":"CHR_BATI","text":"기준 초상"},{"speaker":id,"text":"크기와 하단 기준선 비교"},{"speaker":id,"text":"다음"},{"speaker":id,"text":"마지막"}])
	game.onboarding_dialogue_index = 1
	game.onboarding_dialogue_return_screen = "result"
	game.story_presenter.participant_key = ""
	var screen: Control = game._onboarding_screen_panel(Color("#100d14"))
	game.story_presenter._background(screen,{})
	game.story_presenter._build_shared_frame(screen,id,game._onboarding_speaker_name(id),"", "초상 크기 · 바티의 화면 높이와 하단 기준선에 맞춥니다.",false,true)
	await frames(8)
	return screen
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="): phase = arg.get_slice("=",1)
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	ProjectSettings.set_setting("debug/start_flow14",true)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled=false; game.campaign_auxiliary_save_enabled=false; game.campaign_save_v5_enabled=false; game.campaign_save_v6_enabled=false
	add_child(game); await frames(12)
	game.set_process(false); game.set_physics_process(false); game.start_flow.set_process(false)
	game.current_screen="dialogue"; game.story_feature_enabled=false; game.tutorial_gate_enabled=false; game.tutorial_manager.active=false
	var monsters: Array[String] = []
	for instance in DataRegistry.monster_instances.values():
		var id := str(instance.get("character_id",""))
		if id != "" and not monsters.has(id): monsters.append(id)
	for id in DataRegistry.characters:
		if "monster" in str(DataRegistry.character(id).get("category","")) and not monsters.has(id): monsters.append(id)
	monsters.append("CHR_GOLDIN")
	if phase != "before":
		var pudding: Texture2D = game._onboarding_portrait_texture("res://assets/sprites/portraits/uiux3d/pudding_base.png")
		var bounds: Rect2i = game.story_presenter.standing_visible_bounds(pudding)
		expect(bounds == Rect2i(50,240,1163,783), "ignore nearly transparent pudding canvas speckles")
	for resolution in [Vector2i(1280,720), Vector2i(1920,1080)]:
		get_window().size = resolution; await frames(8)
		for id in monsters:
			var screen: Control = await dialogue(id)
			var left: TextureRect = screen.find_child("DialogueStandingLeft",true,false)
			var right: TextureRect = screen.find_child("DialogueStandingRight",true,false)
			if right == null or left == null:
				expect(false,"missing portrait " + id); continue
			var reference := silhouette(left)
			var actual := silhouette(right)
			rows.append({"speaker":id,"resolution":[resolution.x,resolution.y],"height":actual.size.y,"baseline":actual.end.y,"reference_height":reference.size.y,"reference_baseline":reference.end.y})
			if phase != "before":
				expect(absf(reference.size.y-actual.size.y)<1.1,"height "+id)
				expect(absf(reference.end.y-actual.end.y)<1.1,"baseline "+id)
			if id in ["CHR_PUDDING","CHR_GOB","CHR_PYNN","CHR_GOLDIN"]:
				await capture(str(resolution.x)+"_"+id)
		var screen: Control = await dialogue("CHR_PUDDING")
		for automatic in [false,true]:
			game.story_presenter.legacy_auto_enabled=automatic
			screen = await dialogue("CHR_PUDDING")
			var button: Button = screen.find_child("LegacyStoryAutoButton",true,false)
			var tooltip: Control = button._make_custom_tooltip(button.tooltip_text)
			tooltip.position=Vector2(1420,150); screen.add_child(tooltip)
			await frames(8)
			rows.append({"automatic":automatic,"tooltip_size":[tooltip.size.x,tooltip.size.y],"tooltip_text":button.tooltip_text})
			if phase != "before":
				expect(button.button_pressed==automatic,"toggle state")
				expect(button.get_node("DialogueAutoActiveMarker").visible==automatic,"GPT check state")
				expect(tooltip.size.x<=480 and tooltip.size.y<260,"tooltip compact bounds")
				expect(tooltip.get_child(0).position.x >= 40 and tooltip.get_child(0).position.y >= 40,"tooltip text clears frame ornaments")
				expect(("켜짐" if automatic else "꺼짐") in button.tooltip_text,"tooltip current state")
				var skip: Button = screen.find_child("LegacyStorySkipButton",true,false)
				expect(not skip.tooltip_text.is_empty(),"locked skip explains state")
			await capture(str(resolution.x)+"_auto_"+str(automatic))
		game.story_presenter.legacy_auto_enabled=false
	if phase != "before":
		for id in ["CHR_DARKLORD_PLAYER","CHR_EXPLORER_MILO","CHR_HERO_LEON"]:
			expect(not game.story_presenter.is_monster_speaker(id),"human untouched "+id)
	var result := {"phase":phase,"checks":checks,"failures":failures,"monsters":monsters,"rows":rows,"renderer":RenderingServer.get_current_rendering_method(),"user_dir":OS.get_user_data_dir()}
	var file := FileAccess.open(OUT+phase+"_checks.json",FileAccess.WRITE); file.store_string(JSON.stringify(result,"\t")); file.close()
	print("PLAYTEST_UI ",phase," checks=",checks," failures=",failures.size()," speakers=",monsters.size())
	if not failures.is_empty(): print("FAILURES ",failures.slice(0,8))
	game._shutdown_audio_for_exit(); game.campaign_autosave_pending=false; game.queue_free(); await frames(8)
	get_tree().quit(0 if failures.is_empty() else 1)
