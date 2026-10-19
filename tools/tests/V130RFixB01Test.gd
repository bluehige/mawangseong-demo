extends "res://_mockup/release_audit_v130/Audit.gd"
## Reuse 0112's new-game, RNG, auto-placement, settlement and save/reload inputs.
var checks := 0
var failures: Array = []
var case_name := "unit"
var output_dir := "res://tmp/v130r_b01/"
var close_events: Array = []
var observed_view: WeakRef
var observed_controller: WeakRef
var observed_sprites: Array = []

func _process(_delta: float) -> void:
	if case_name=="unit" or not is_instance_valid(game): return
	if game.story_combat_overlay_open and view()!=null:
		if observed_view==null:
			observed_view=weakref(view()); observed_controller=weakref(game.combat_scene)
			observed_sprites.clear()
			for unit in game.monster_units+game.enemy_units: observed_sprites.append(unit.sprite)
	elif observed_view!=null:
		var owner=observed_view.get_ref()
		if game.current_screen=="combat" and is_instance_valid(owner):
			same_owner(owner,observed_controller.get_ref(),observed_sprites,"DAY%d live overlay close" % GameState.day)
		else: expect(false,"live overlay restores combat before settlement")
		observed_view=null; observed_controller=null; observed_sprites.clear()

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("[B01] "+label)

func write_json(id: String, value) -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	var file := FileAccess.open(output_dir+id+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(value,"\t"))

func capture(_id: String) -> void:
	pass # Never overwrite the original 0112 evidence.

func create_game() -> void:
	await super.create_game()
	if case_name=="replay":
		game._set_campaign_save_path_for_tests("user://b01_v1.json","user://b01_v2.json","user://b01_v3.json","user://b01_v4.json","user://b01_v5.json","user://b01_v6.json")

func drain() -> void:
	for i in 700:
		await frames(2)
		if game.current_screen!="dialogue": return
		if game.story_director.is_active(): game._story_advance_dialogue()
		else:
			var joins: Array=game.get_meta("approved_join_pending",[]).duplicate()
			var final_join: bool=game.onboarding_dialogue_complete_action=="v130r_join" and game.onboarding_dialogue_index+1==game.onboarding_dialogue_queue.size()
			if final_join:
				for id in joins: expect(not GameState.food_state.get("owned",[]).has(id),"join grants only after final line")
			game._onboarding_advance_dialogue()
			if final_join:
				for id in joins: expect(GameState.food_state.get("owned",[]).has(id),"join completion grants once")
	expect(false,"fullscreen dialogue drains")

func same_owner(v: Node, controller, sprites: Array, label: String) -> void:
	expect(is_instance_valid(v) and view()==v,label+": same Approved view")
	expect(game.combat_scene==controller and controller.running,label+": same running controller")
	expect(game.graph==controller.map,label+": Approved graph")
	expect(game.ui_layer.find_child("CombatMinimap",true,false)==null,label+": no legacy minimap")
	for sprite in sprites: expect(is_instance_valid(sprite) and sprite.is_inside_tree(),label+": live sprite")
	close_events.append({"kind":label,"view":v.get_instance_id(),"controller":controller.get_instance_id(),"paused":game.combat_paused})

func close_lines(lines: Array, action: String, destination: String) -> void:
	game._onboarding_begin_dialogue(lines.duplicate(true),destination,action)
	await drain(); await frames(4)

func dialogue_key() -> void:
	var key := InputEventKey.new()
	key.keycode=KEY_SPACE; key.physical_keycode=KEY_SPACE; key.pressed=true
	Input.parse_input_event(key)
	await frames(2)
	key=InputEventKey.new(); key.keycode=KEY_SPACE; key.physical_keycode=KEY_SPACE
	Input.parse_input_event(key)
	await frames(2)

func unit_cases() -> void:
	await new_game()
	game.campaign_autosave_pending=false
	game.start_flow.fresh=false; game.start_flow.guide_step=5; game.start_flow.command_seen=true
	# Exercise real 0111 data and completion actions in their authored phase.
	for kind in ["day_overlays","bond_scenes","duo_scenes"]:
		var scene: Dictionary=game.v130r_story.scenes(kind)[0]
		var block: Dictionary=scene.segments[0] if scene.has("segments") else scene
		game.set_meta("v130r_story_pending",[block.id])
		await close_lines(game.v130r_story.entries(scene,block),"v130r_story","management")
		expect(game.current_screen=="management" and view()!=null,kind+": returns to Approved management")
		expect(game.story_director.seen_scene_ids.has(str(block.id)),kind+": completion recorded")
	# Last-line and skip share the recruitment completion action, with no grant
	# until the final input. Actual eligible DAY2 recruitment is tested in replay.
	var v := view()
	v.monster_ui.auto_place()
	for i in 12:
		v=view(); v.start_battle(); await drain(); await frames(3)
		if view()!=null and view().battle!=null: break
	v=view()
	expect(v!=null and v.battle!=null,"unit battle starts")
	if v==null or v.battle==null: return
	var b=v.battle
	v.set_physics_process(false)
	b.set_pause_state(true,false)
	var sprites: Array=[]
	for unit in game.monster_units: sprites.append(unit.sprite)
	# A direct inherited refresh must also honor Approved HUD ownership.
	game._set_screen("combat",false); game._build_combat_ui(); await frames(4)
	same_owner(v,b,sprites,"direct combat refresh")
	# Blocking main-story combat overlays: next, skip, queued scenes and pause.
	var scene_id := ""
	var queued_scene_id := ""
	for scene in game.story_catalog._scenes_by_id.values():
		if scene.get("delivery","") in ["combat_overlay","combat_bark"] and not scene.get("cues",[]).is_empty():
			if scene_id=="": scene_id=str(scene.id)
			elif queued_scene_id=="": queued_scene_id=str(scene.id); break
	expect(scene_id!="","authored combat scene found")
	for paused in [false,true]:
		for skip in [false,true]:
			b.set_pause_state(paused,false)
			expect(game.story_director.start_scene(scene_id,game._story_context(),"combat","",true),"start main overlay")
			game._story_show_active_scene()
			if skip:
				game.story_director.seen_cue_ids.append(game.story_director.current_cue_id)
				# Mark the whole scene read so the real skip eligibility applies.
				for cue in game.story_director._active_cues:
					if not game.story_director.seen_cue_ids.has(str(cue.id)): game.story_director.seen_cue_ids.append(str(cue.id))
				game._story_skip_dialogue()
			else:
				for i in 100:
					if not game.story_director.is_active(): break
					await dialogue_key()
			await frames(4)
			expect(not game.story_director.is_active() and not game.story_combat_overlay_open,"main overlay closes")
			expect(game.combat_paused==paused and b.requested_pause==paused,"main overlay restores pause")
			same_owner(v,b,sprites,"main overlay paused=%s skip=%s" % [paused,skip])
	# Queued blocking scenes retain one pause owner until the final scene closes.
	b.set_pause_state(false,false)
	expect(game.story_director.start_scene(scene_id,game._story_context(),"combat","",true),"queue first scene")
	game.story_pending_combat_scenes.append({"scene_id":queued_scene_id,"facts":game._story_context()})
	game._story_show_active_scene()
	var first_id: String=game.story_director.current_scene_id
	while game.story_director.is_active():
		game._story_advance_dialogue()
		if game.story_pending_combat_scenes.is_empty(): break
	expect(game.story_director.current_scene_id==queued_scene_id and game.combat_paused,"queued scene retains pause ownership")
	for i in 100:
		if not game.story_director.is_active(): break
		game._story_advance_dialogue()
	await frames(4)
	expect(not game.story_combat_overlay_open and not game.combat_paused,"queued overlay releases pause")
	same_owner(v,b,sprites,"queued main overlays "+first_id)
	# Auto stops on the last line, then the same real input closes the overlay.
	expect(game.story_director.start_scene(scene_id,game._story_context(),"combat","",true),"auto overlay starts")
	game._story_show_active_scene(); game.story_director.set_auto(true)
	for i in game.story_director.cue_count(): game._story_tick_auto(20.0)
	expect(game.story_presenter.auto_at_end and game.story_combat_overlay_open,"auto keeps final line for manual close")
	await dialogue_key(); same_owner(v,b,sprites,"auto final-line close")
	# Legacy fullscreen returning to combat must suspend/resume its owner too.
	for kind in ["day_overlays","join_scenes","bond_scenes","duo_scenes"]:
		var scene: Dictionary=game.v130r_story.scenes(kind)[0]
		var block: Dictionary=scene.segments[0] if scene.has("segments") else scene
		await close_lines(game.v130r_story.entries(scene,block),"","combat")
		same_owner(v,b,sprites,"fullscreen "+kind)
	game._onboarding_begin_dialogue([],"combat",""); await frames(2)
	same_owner(v,b,sprites,"empty dialogue completion")
	game.campaign_cycle_index=2
	game._onboarding_begin_dialogue([{"speaker":"CHR_BATI","text":"Skip B01"}],"combat","")
	game._onboarding_skip_dialogue(); await frames(3)
	same_owner(v,b,sprites,"legacy skip")
	game.campaign_cycle_index=1
	# Settings can be rebuilt inside a suspended dialogue without losing map.
	game._onboarding_begin_dialogue([{"speaker":"CHR_BATI","text":"B01"}],"combat","")
	game._open_settings_screen(); game._cancel_settings_changes(); await frames(3)
	event("input_before",{"input":game.is_processing_input(),"screen":game.current_screen,"queue":game.onboarding_dialogue_queue.size(),"focus":str(get_viewport().gui_get_focus_owner()),"paused":game.pause_menu_open,"backlog":game.continuity.backlog_open})
	await dialogue_key()
	event("input_after",{"input":game.is_processing_input(),"screen":game.current_screen,"queue":game.onboarding_dialogue_queue.size()})
	expect(game.onboarding_dialogue_queue.is_empty(),"actual key closes suspended fullscreen")
	same_owner(v,b,sprites,"dialogue settings return")
	# Ordinary reactions own only their panel and never request screen changes.
	game.v130r_story.reset_battle()
	expect(game.v130r_story.bark(game,game.monster_units[0],"deployed"),"real bark queues")
	if DisplayServer.get_name()!="headless":
		game.v130r_story.tick_barks(game,.1)
		expect(is_instance_valid(game.v130r_story.bark_panel),"bark panel renders")
		game.v130r_story.tick_barks(game,4.0)
		expect(not is_instance_valid(game.v130r_story.bark_panel),"bark expires without screen transition")
	game.v130r_story.clear_bark(); game.combat_story_feed.clear(); await frames(3)
	same_owner(v,b,sprites,"bark expiration")
	var feed_scene: Dictionary=game.story_catalog.scene(scene_id)
	game.combat_story_feed.enqueue(game,feed_scene,game._story_context())
	game.combat_story_feed.tick(game,.01)
	expect(game.combat_story_feed.reader!=null,"ordinary feed starts")
	for i in 100:
		if game.combat_story_feed.reader==null: break
		game.combat_story_feed.tick(game,10.0)
	expect(game.combat_story_feed.reader==null and not is_instance_valid(game.combat_story_feed.panel),"ordinary feed expires")
	same_owner(v,b,sprites,"ordinary feed expiration")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output_dir+"approved_after_dialogues.png")
	# Real finish/settlement, result dialogue and disposal of reparented sprites.
	b.finish_combat(true,"B01 fixture settlement"); await frames(8); await drain()
	expect(game.current_screen=="result","postcombat dialogue returns to result")
	for unit in game.monster_units: expect(not unit.is_physics_processing(),"settled unit cannot tick freed visuals")
	if game._result_growth_choice_required():
		for growth in game.last_growth_summary:
			if game._choose_result_growth(str(growth.get("monster_id",""))): break
		game._review_growth_from_result(); await frames(3)
	game._continue_from_result(); await drain(); await frames(4); await auxiliary()
	expect(view()!=null and view().battle==null,"result returns to management")
	if view()==null: return
	# Preparation day remains battle-free.
	v=view(); v.set_preview_day(29); v.monster_ui.unlock_all=true; v.monster_ui.auto_place()
	expect(v.preparation_only() and not game._has_defense_wave_for_day(29),"DAY29 preparation only")
	expect(not v.start_battle() and v.battle==null,"DAY29 combat blocked")
	game._set_campaign_final_declaration("castle_oath"); await drain(); await frames(2)
	v=view()
	expect(v.confirm_preparation_day(),"DAY29 preparation confirms")
	await drain(); await frames(4)
	expect(game.current_screen=="result" and GameState.day==29,"preparation settles before continuing")
	game._continue_from_result(); await drain(); await frames(4)
	expect(GameState.day==30,"DAY29 advances without battle")

func required_specialization() -> Dictionary:
	if not game._early_specialization_required_for_current_day(): return {}
	var ui=view().monster_ui
	for id in ui.unlocked():
		var species: String=ui.members[id].species_id
		for option in game._specializations_for_monster(species):
			if ui.choose_specialization(id,str(option.id)):
				await frames(2)
				return {"species":species,"id":str(option.id)}
	expect(false,"required specialization chosen through actual placement UI")
	return {}

func campaign() -> void:
	if case_name=="unit": await unit_cases(); return
	await new_game()
	var last_day := 3 if case_name=="replay" else 10
	if case_name=="continuous":
		# B01 control-flow fixture: isolate B04 survival balance without changing
		# waves, damage, roster, dialogue or product code. Never a win-rate claim.
		GameState.demon_lord_max_hp=100000; GameState.demon_lord_hp=100000
	for day in range(1,last_day+1):
		await drain(); await frames(6)
		var entered: bool=game.current_screen=="management" and GameState.day==day and view()!=null and int(view().placement.day)==day
		expect(entered,"continuous enters DAY%d with matching layout" % day)
		if not entered: return
		var selected := await required_specialization()
		if case_name=="replay" and day==2:
			await save_reload(day)
			if not selected.is_empty(): expect(str(game.monster_roster[selected.species].get("specialization_id",""))==selected.id,"save reload retains chosen specialization")
			expect(not game._early_specialization_required_for_current_day(),"reloaded preparation satisfies specialization gate")
		var result := await battle_day(); rows.append(result)
		write_json("days",rows)
		if result.has("error"): write_json("start_diagnostic",{"result":result,"day":GameState.day,"screen":game.current_screen,"gate":game._management_start_state(false)})
		expect(not result.has("error"),"DAY%d battle finishes" % day)
		if result.has("error"): return
		if not result.get("win",false):
			game._edit_placement_from_result(); await drain(); await frames(6)
			result=await battle_day(); rows.append({"retry":result})
			expect(not result.has("error"),"DAY%d retry finishes" % day)
		event("b01_day_complete",{"result":result})
		if day==last_day and case_name=="replay": break
		expect(result.get("win",false),"DAY%d can advance" % day)
		if not result.get("win",false): return
		if game._result_growth_choice_required():
			for growth in game.last_growth_summary:
				if game._choose_result_growth(str(growth.get("monster_id",""))): break
			game._review_growth_from_result(); await frames(4)
		if case_name=="continuous" and day==3:
			# Known B03: the legacy raid-preview tutorial boundary changes only
			# GameState.day, leaving the Approved session at DAY3. Isolate this
			# separate blocker in the B01 ten-day control-flow fixture only.
			GameState.onboarding_complete=true; GameState.max_day=30; GameState.victory=false
		game._continue_from_result(); await drain(); await frames(6); await auxiliary()
	if case_name=="continuous": expect(GameState.day==11 and game.current_screen=="management","DAY1-10 continuous reaches DAY11")
	if case_name=="replay": expect(not close_events.is_empty(),"0112 live combat overlay actually closed")
	write_json("days",rows)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("case="): case_name=arg.get_slice("=",1)
		if arg.begins_with("out="): output_dir=arg.trim_prefix("out=").trim_suffix("/")+"/"
	expect(OS.get_user_data_dir().replace("\\","/").contains("v130r_b01"),"isolated test user directory")
	if not failures.is_empty(): get_tree().quit(1); return
	await super.run()
	write_json("checks",{"case":case_name,"seed":run_seed,"checks":checks,"failures":failures,"close_events":close_events})
	print("B01_RESULT ",JSON.stringify({"case":case_name,"seed":run_seed,"checks":checks,"failures":failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
