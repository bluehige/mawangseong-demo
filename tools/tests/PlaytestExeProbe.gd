extends Node
## Copied only into the isolated export project, never into the product project.
var previous := ""
var samples: Array = []
var index := 0
var portrait_index := 0
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
	if is_instance_valid(game):
		row["screen"] = game.current_screen
		row["dialogue_index"] = game.onboarding_dialogue_index
		row["automatic"] = game.story_presenter.legacy_auto_enabled
		var controls: Array = []
		for name in ["DialogueStandingLeft", "DialogueStandingRight", "LegacyStoryAutoButton", "DialogueAutoActiveMarker", "WindowModeOption", "SettingsCategory_display", "DialogueText"]:
			var node: Node = game.ui_layer.find_child(name, true, false)
			if node is Control:
				var item := {"name":name,"position":[node.global_position.x,node.global_position.y],"size":[node.size.x,node.size.y],"visible":node.is_visible_in_tree()}
				if node is BaseButton: item["pressed"] = node.button_pressed
				if node is Button: item["text"] = node.text
				if node is TextureRect: item["speaker"] = node.get_meta("speaker_id", "")
				controls.append(item)
		row["controls"] = controls
	samples.append(row)
	var file := FileAccess.open("user://display_probe.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(samples,"\t"))
	file.close()

func _process(delta: float) -> void:
	delay += delta
	if delay<0.5: return
	delay=0
	var key := str(get_window().size)+str(get_window().mode)+UISettings.window_mode+str(game.current_screen)+str(game.onboarding_dialogue_index)+str(game.story_presenter.legacy_auto_enabled)
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
		var portraits := ["CHR_PUDDING","CHR_GOB","CHR_PYNN","CHR_GOLDIN"]
		var monster: String = portraits[portrait_index % portraits.size()]
		portrait_index += 1
		for id in ["CHR_BATI", monster, monster, monster]:
			cues.append({"id":"PLAYTEST_"+id,"speaker":id,"text":"실제 EXE 대화창 · 자동 버튼과 초상 확인. 바티와 같은 화면에서 크기와 하단 기준선을 비교합니다."})
		game.story_feature_enabled=false; game.tutorial_gate_enabled=false; game.tutorial_manager.active=false
		game.story_presenter.legacy_auto_enabled=false
		game.story_presenter.participant_key=""
		game._onboarding_begin_dialogue(cues,"result","")
	elif event.keycode==KEY_F8:
		var image := get_viewport().get_texture().get_image()
		image.save_png("user://capture_"+str(Time.get_ticks_msec())+".png")
	elif event.keycode==KEY_F10:
		game._shutdown_audio_for_exit(); game.campaign_autosave_pending=false
		get_tree().quit()
