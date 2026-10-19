extends Node
## Test-only autoload, included only in the isolated EXE copy. Product Main stays intact.
var game: Node
var sample := 0
func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-resolution="):
			var dimensions := arg.trim_prefix("--qa-resolution=").split("x")
			get_window().size = Vector2i(int(dimensions[0]),int(dimensions[1]))
	get_window().position = Vector2i(60,60)
	await get_tree().process_frame
	await get_tree().process_frame
	game = get_tree().root.find_child("GameRoot",true,false)
	if game == null: return
	for i in 40: await get_tree().process_frame
	fixture()
func fixture() -> void:
	game._onboarding_reset_game()
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
	game.campaign_autosave_pending = false
	game.start_flow.fresh = false
	game.start_flow.intro_complete = true
	game.start_flow.guide_step = 5
	game.start_flow.command_seen = true
	GameState.day = 2
	game.monster_roster.slime.exp = 7
	game.selected_monster_id = "slime"
	game.management_scene.monster_ui.inspected_id = "slime"
	game.management_scene.monster_ui.active_tab = "training"
	if OS.get_cmdline_user_args().has("--qa-map"):
		GameState.day = 1; game.start_flow.fresh = true; game.start_flow.guide_step = 3
		game._set_screen("management",false)
	else: game._set_screen("monster",false)
	await get_tree().process_frame
	record()
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	if event.keycode == KEY_F10:
		game.campaign_autosave_pending = false
		game._shutdown_audio_for_exit()
		get_tree().quit()
	if event.keycode == KEY_F6:
		sample += 1
		if sample == 1:
			game.management_scene.monster_ui.active_tab = "skills"
			game._set_screen("monster",false)
		else:
			GameState.day = 1
			game.start_flow.fresh = true
			game.start_flow.guide_step = 3
			game.start_flow.guide_key = ""
			game._set_screen("management",false)
		get_viewport().set_input_as_handled()
func record() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var rendered_size := image.get_size()
	image.resize(920,518,Image.INTERPOLATE_LANCZOS)
	var filename := "user://sample-%d-%d" % [sample,get_window().size.x]
	image.save_png(filename+".png")
	var rows := []
	for control in game.ui_layer.find_children("*","Control",true,false):
		if control.name in ["TrainingPreviewCard","MonsterGrowthScroll","SpecializationCapacity","BuildTab","PlaceTab","ApprovedDayAction"]:
			rows.append({"name":control.name,"rect":str(control.get_global_rect()),"minimum":str(control.get_combined_minimum_size())})
	var file := FileAccess.open(filename+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"screen":game.current_screen,"window_size":str(get_window().size),"render_size":str(rendered_size),"controls":rows,"user_dir":OS.get_user_data_dir()},"\t"))
