extends "res://tools/tests/V130RB04Stacking.gd"
## Autoload only in the isolated manual export. Shipping main/controller intact.
var loading := false
var sample_clock := 0.0
var samples: Array = []
var capture_count := 0
var captures: Array = []
var loaded_entry := false

func _physics_process(_delta: float) -> void:
	pass # Actual view and actors run at the engine's normal physics cadence.

func run() -> void:
	await get_tree().process_frame
	game=get_tree().current_scene.get_node("GameRoot")
	base_controller=game.combat_scene
	game.campaign_save_enabled=false; game.campaign_auxiliary_save_enabled=false
	game.campaign_save_v5_enabled=false; game.campaign_save_v6_enabled=false
	get_window().mode=Window.MODE_WINDOWED
	get_window().size=Vector2i(900,506)
	get_window().position=Vector2i(30,30)
	expect(OS.get_user_data_dir().replace("\\","/").contains("v130r_engage"),"isolated actual EXE")
	write_json("boot",{"size":[get_window().size.x,get_window().size.y],"mode":get_window().mode,"user_dir":OS.get_user_data_dir(),"steam_disabled":OS.get_environment("MAWANG_DISABLE_STEAM"),"renderer":RenderingServer.get_current_rendering_method()})
	if not failures.is_empty(): get_tree().quit(1)

func write_json(id: String, data) -> void:
	var f := FileAccess.open("user://engage_"+id+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"\t")); f.close()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or loading: return
	if event.keycode==KEY_F6: load_day(1)
	elif event.keycode==KEY_F7: load_day(5)
	elif event.keycode==KEY_F9: start_manual_battle()
	elif event.keycode==KEY_F8:
		if game.current_screen!="combat" or view()==null or view().battle==null or not view().battle.running: return
		capture_count+=1
		var image := get_viewport().get_texture().get_image()
		if maxi(image.get_width(),image.get_height())>960:
			var factor := 960.0/maxi(image.get_width(),image.get_height())
			image.resize(roundi(image.get_width()*factor),roundi(image.get_height()*factor),Image.INTERPOLATE_LANCZOS)
		image.save_png("user://engage_battle_"+str(capture_count)+"_day"+str(GameState.day)+".png")
		captures.append({"index":capture_count,"day":GameState.day,"combat_time":game.combat_time,"battle_running":view().battle.running,"paused":game.combat_paused,"width":image.get_width(),"height":image.get_height(),"sample":samples.back() if not samples.is_empty() else {}})
		write_json("captures",captures)
	elif event.keycode==KEY_F10:
		write_json("checks",{"checks":checks,"failures":failures,"captures":capture_count,"user_dir":OS.get_user_data_dir(),"samples":samples})
		game._shutdown_audio_for_exit(); game.campaign_autosave_pending=false
		get_tree().quit(0 if failures.is_empty() else 1)

func load_day(day: int) -> void:
	# Never replace a live scene from its victory dialogue/callback stack.
	# Each manual process observes exactly one restored campaign entry.
	if loaded_entry: return
	loaded_entry=true
	loading=true; run_seed=130401
	var snapshot: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/test_engage/130401_"+str(day)+".json"))
	if not await restore_entry(snapshot): loading=false; return
	view().monster_ui.set_mode("place"); place_defenders(view())
	await frames(2)
	write_json("state",{"day":GameState.day,"screen":game.current_screen,"ready":true})
	loading=false

func start_manual_battle() -> void:
	if view()==null or view().battle!=null: return
	loading=true
	if game.start_flow.guide_step==1: game.start_flow.advance_guide(); await frames(2)
	for i in 12:
		if view()==null or view().battle!=null: break
		view().start_battle(); await drain(); await frames(2)
	if view()!=null and view().battle!=null:
		if not game.start_flow.command_seen: game.start_flow.ack_commands()
		view().battle.set_speed(1.0)
	loading=false

func _process(delta: float) -> void:
	if not is_instance_valid(game) or loading: return
	sample_clock+=delta
	if sample_clock<.5: return
	sample_clock=0
	var active_view=view()
	write_json("live",{"day":GameState.day,"screen":game.current_screen,"time":game.combat_time,"paused":game.combat_paused,"battle_running":active_view!=null and active_view.battle!=null and active_view.battle.running})
	if game.combat_speed_intro_open:
		game._dismiss_combat_speed_intro()
		return
	if game.story_combat_overlay_open and game.story_director.is_active():
		game._story_advance_dialogue()
		return
	if game.current_screen=="combat":
		var units: Array=[]
		for unit in game.monster_units+game.enemy_units:
			if is_instance_valid(unit): units.append({"id":unit.unit_id,"faction":unit.faction,"hp":unit.hp,"state":unit.tactical_state,"target":unit.target_text,"attack_animation":unit.attack_anim_timer,"position":[unit.position.x,unit.position.y]})
		samples.append({"day":GameState.day,"time":game.combat_time,"units":units})
		write_json("timeline",samples)
