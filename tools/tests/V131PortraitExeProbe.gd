extends Node
## QA export only. One dialogue per process avoids the old F7 transition crash.
var game: Node
var opened := false

func _ready() -> void:
	for i in 40: await get_tree().process_frame
	game = get_tree().current_scene.get_node("GameRoot")
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
	get_window().size = Vector2i(920,518)
	get_window().position = Vector2i(80,80)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or game == null: return
	if event.keycode == KEY_F10:
		game.campaign_autosave_pending = false
		game._shutdown_audio_for_exit()
		get_tree().quit()
	elif event.keycode == KEY_F7 and not opened:
		opened = true
		var target := "CHR_THIEF_NIA"
		var emotion := "teasing"
		var text := "마왕. 개업 축하해. 첫 도난은 내가 맡으려고 왔어."
		for arg in OS.get_cmdline_user_args():
			if arg == "--qa-portrait=milo":
				target = "CHR_EXPLORER_MILO"; emotion = "panic"
				text = "미로가 움직였어! 지도와 등불을 놓치면 안 돼."
			elif arg == "--qa-portrait=leon":
				target = "CHR_HERO_LEON"; emotion = "heroic"
				text = "이번에는 물러서지 않겠어. 정정당당하게 승부하자!"
		game.story_feature_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
		game.story_presenter.legacy_auto_enabled = false
		game.story_presenter.participant_key = ""
		game._onboarding_begin_dialogue([
			{"speaker":target,"emotion":emotion,"text":text},
			{"speaker":"CHR_DARKLORD_PLAYER","text":"마왕성에 온 것을 환영한다."},
			{"speaker":target,"emotion":emotion,"text":text}
		],"result","")
		capture.call_deferred(target)
	elif event.keycode == KEY_F8:
		capture.call_deferred("manual")

func capture(target: String) -> void:
	for i in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(920,518,Image.INTERPOLATE_LANCZOS)
	image.save_png("user://dialogue_"+target+".png")
	var controls: Array = []
	for name in ["DialogueStandingLeft","DialogueStandingRight","DialogueText"]:
		var control: Node = game.ui_layer.find_child(name,true,false)
		if control is Control:
			controls.append({"name":name,"rect":str(control.get_global_rect()),"speaker":control.get_meta("speaker_id",""),"portrait":control.get_meta("portrait_path","")})
	var file := FileAccess.open("user://dialogue_"+target+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"target":target,"controls":controls,"screen":game.current_screen,"user_dir":OS.get_user_data_dir(),"size":str(get_window().size),"renderer":RenderingServer.get_current_rendering_method()},"\t"))
	file.close()
