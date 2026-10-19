extends Node
## Copied only into the isolated export project, never into the product project.
var previous := ""
var samples: Array = []
var index := 0
var game: Node
var delay := 0.0

func _ready() -> void:
	await get_tree().process_frame
	game = get_tree().current_scene.get_node("GameRoot")
	game.campaign_save_enabled=false; game.campaign_auxiliary_save_enabled=false; game.campaign_save_v5_enabled=false; game.campaign_save_v6_enabled=false
	get_window().size = Vector2i(1280,720)
	get_window().position = Vector2i(30,30)
	get_window().size_changed.connect(record)
	record()

func record() -> void:
	var row := {"ticks":Time.get_ticks_msec(),"size":[get_window().size.x,get_window().size.y],"mode":get_window().mode,"settings_mode":UISettings.window_mode,"renderer":RenderingServer.get_current_rendering_method(),"user_dir":OS.get_user_data_dir()}
	samples.append(row)
	var file := FileAccess.open("user://display_probe.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(samples,"\t"))
	file.close()

func _process(delta: float) -> void:
	delay += delta
	if delay<0.5: return
	delay=0
	var key := str(get_window().size)+str(get_window().mode)+UISettings.window_mode
	if key!=previous:
		previous=key; record()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_F6:
		var sizes := [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]
		index=(index+1)%sizes.size()
		get_window().size=sizes[index]
		record()
	elif event.keycode==KEY_F7:
		var cues: Array = []
		for id in ["CHR_BATI","CHR_PUDDING","CHR_GOB","CHR_PYNN","CHR_GOLDIN"]:
			cues.append({"id":"PLAYTEST_"+id,"speaker":id,"text":"실제 EXE 대화창 · 자동 버튼과 초상 확인"})
		game.story_feature_enabled=false; game.tutorial_gate_enabled=false; game.tutorial_manager.active=false
		game._onboarding_begin_dialogue(cues,"result","")
	elif event.keycode==KEY_F8:
		var image := get_viewport().get_texture().get_image()
		image.save_png("user://capture_"+str(Time.get_ticks_msec())+".png")
	elif event.keycode==KEY_F10:
		game._shutdown_audio_for_exit(); game.campaign_autosave_pending=false
		get_tree().quit()
