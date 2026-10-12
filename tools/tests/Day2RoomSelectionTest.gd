extends "res://tools/tests/PlayerFeedbackHotfixTest.gd"

var checkpoint:Dictionary={}

func run() -> void:
	output_dir="res://tmp/day2_room_selection"
	expect(ProjectSettings.globalize_path("user://").contains("day2_room_selection"),"isolated synthetic save path")
	if not failures.is_empty():get_tree().quit(1);return
	var args:=OS.get_cmdline_user_args()
	for i in range(args.size()-1):
		if args[i]=="--fixture" and args[i+1].contains("first-defense-review"):
			checkpoint=JSON.parse_string(FileAccess.get_file_as_string(args[i+1]))
	expect(not checkpoint.is_empty(),"require isolated naturally reached DAY2 checkpoint via --fixture")
	if checkpoint.is_empty():get_tree().quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game=GameRootScene.instantiate();add_child(game);await settle()
	game.continuity.acknowledge_update()
	game._onboarding_reset_game()
	game.story_director.cancel_active_scene();game.onboarding_dialogue_queue.clear()
	for guidance in [UISettings.TUTORIAL_GUIDANCE_FULL,UISettings.TUTORIAL_GUIDANCE_CORE,UISettings.TUTORIAL_GUIDANCE_OFF]:
		UISettings.set_tutorial_guidance_level(guidance,false)
		for view in [Transform2D(Vector2(.72,0),Vector2(0,.72),Vector2(278,144)),Transform2D(Vector2(.58,0),Vector2(0,.58),Vector2(350,170))]:
			await fixture("TUT_110_TRAP_CORRIDOR","LV06_DAY02_MANAGEMENT_TREASURE",2,"spike_corridor")
			get_viewport().canvas_transform=view;await settle()
			var world:Vector2=game.graph.center("spike_corridor")
			var screen:Vector2=game.get_global_transform_with_canvas()*world
			expect(game._management_monster_at(world)=="slime","occupied tutorial room fixture")
			expect(not game._management_ui_at(screen),"actual target not covered by UI")
			expect(game._tutorial_room_rect("spike_corridor").get_center().distance_to(screen)<.01,"focus tracks pan and zoom")
			var before:=GameState.campaign_snapshot()
			await pointer(screen,true);await pointer(screen,false)
			expect(game.tutorial_manager.current_step_id()=="TUT_120_TRAP_LURE","actual occupied room click advances")
			expect(game.selected_room=="spike_corridor" and game.dragging_monster_id=="","required room wins over monster drag")
			expect(before==GameState.campaign_snapshot(),"room click grants no repeated resource reward")
			if guidance==UISettings.TUTORIAL_GUIDANCE_FULL:await capture("occupied_room_selected_"+str(int(view.x.x*100)))
			var payload:Dictionary=game._campaign_save_payload("management")
			game._set_screen(Constants.SCREEN_TITLE)
			expect(game._restore_campaign_payload(payload),"title to checkpoint restore accepted")
			await settle()
			expect(game.tutorial_manager.current_step_id()=="TUT_120_TRAP_LURE","restore retains completed room selection")
			expect(before==GameState.campaign_snapshot(),"restore does not replay room rewards")
	await fixture("TUT_110_TRAP_CORRIDOR","LV06_DAY02_MANAGEMENT_TREASURE",2,"spike_corridor")
	var target:Vector2=game.get_global_transform_with_canvas()*game.graph.center("spike_corridor")
	game._open_pause_menu();await settle()
	await pointer(target,true);await pointer(target,false)
	expect(game.tutorial_manager.current_step_id()=="TUT_110_TRAP_CORRIDOR","pause blocks required room input")
	game._close_pause_menu();await settle()
	await pointer(target,true);await pointer(target,false)
	expect(game.tutorial_manager.current_step_id()=="TUT_120_TRAP_LURE","closing pause restores room input")
	await fixture("TUT_210_RECOVERY_NEST","LV09_DAY03_MANAGEMENT_HERO",3,"recovery")
	var recovery:Vector2=game.get_global_transform_with_canvas()*game.graph.center("recovery")
	await pointer(recovery,true);await pointer(recovery,false)
	expect(game.tutorial_manager.current_step_id()=="TUT_220_RETREAT_LINE","same occupied-room requirement works for recovery")
	await fixture("TUT_110_TRAP_CORRIDOR","LV06_DAY02_MANAGEMENT_TREASURE",2,"spike_corridor")
	game.tutorial_gate_enabled=false
	await pointer(target,true)
	expect(game.dragging_monster_id=="slime","ordinary ungated monster drag retained")
	await pointer(target,false)
	expect(game.dragging_monster_id=="","ordinary drag release clears state")
	game.queue_free();await settle()
	print("DAY2_ROOM_SELECTION_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func fixture(step:String,stage:String,day:int,room:String)->void:
	game._restore_campaign_payload(checkpoint.duplicate(true));await settle()
	GameState.day=day;game.onboarding_enabled=true;game.tutorial_gate_enabled=true
	game.deploy_pick_monster_id="";game.build_pick_mode=false;game.map_editor_active=false
	game.selected_monster_id="goblin";game.selected_room="barracks"
	for i in range(game.tutorial_manager.steps.size()):
		if str(game.tutorial_manager.steps[i].get("id",""))==step:
			game.tutorial_manager.current_index=i;break
	game.tutorial_manager.active=true;game._onboarding_set_stage(stage)
	game.monster_roster.slime.room=room
	game._set_screen(Constants.SCREEN_MANAGEMENT);await settle()
	game.maze_deployments["slime"]={"position":game.graph.center(room),"room_id":room}

func pointer(point:Vector2,pressed:bool)->void:
	var event:=InputEventMouseButton.new();event.position=point;event.global_position=point
	event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
	get_viewport().push_input(event,true);await settle()
