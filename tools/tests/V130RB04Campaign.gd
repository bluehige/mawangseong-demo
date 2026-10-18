extends Node
const Grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
var game: Node
var mode := "b04"
var run_seed := 130401
var locale := "ko"
var started := 0
var label := "baseline"
var layout_mode := "recommended"
var last_day := 30
var fast := true
var cosmetic_controller: Script
var checkpoint_source := ""
var checkpoint_day := 1
var retries := 0
var failures: Array = []
var checks := 0
var rows: Array = []
var purchases: Array = []
var capture_entry := false
func _ready() -> void: run.call_deferred()
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(game): return
	var v := view()
	if v!=null and v.battle!=null:
		v.set_physics_process(false)
		for unit in game.monster_units+game.enemy_units:
			if is_instance_valid(unit): unit.set_physics_process(false)
func capture(_id: String) -> void: pass
func placement_value(layout: Dictionary, v: Node) -> int:
	var assigned := Members.auto_place(layout,v.monster_ui.members,v.monster_ui.unlocked(),v.monster_ui.food_income)
	var value := assigned.size()*1000
	for id in assigned:
		var preferred := Members.preferences(v.monster_ui.members[id].species_id)
		var kind: String=Buildings.building(layout,assigned[id].building).kind
		var rank: int=preferred.find(kind)
		value-=rank if rank>=0 else 10
	return value
func auto_build() -> void:
	var v := view()
	# Buy only the approved plan's missing sites, using the real cost/limit checks.
	var sites: Array=Buildings.Layout.read(str(v.placement.grade)).buildings.duplicate(true)
	var priority := ["ward_core","barracks","recovery_nest","watchtower","bait_treasure"]
	sites.sort_custom(func(a,b): return priority.find(a.get("kind",a.id))<priority.find(b.get("kind",b.id)))
	for hint in sites:
		if hint.fixed: continue
		var present := false
		for b in v.placement.buildings:
			if b.get("plan_site_id",b.id)==hint.id or (b.kind==hint.get("kind",hint.id) and b.rect.position==Vector2i(hint.rect[0],hint.rect[1])): present=true; break
		if present: continue
		var before: Dictionary=v.placement.resources.duplicate(true)
		var next := Buildings.preview(v.placement,hint.get("kind",hint.id),Vector2i(hint.rect[0],hint.rect[1]))
		if next.get("ok",false) and int(next.resources.mana)>=60:
			v.apply_action(next)
			purchases.append({"seed":run_seed,"day":GameState.day,"site":hint.id,"action":"build","before":before,"after":v.placement.resources.duplicate(true)})
	for level in range(1,4):
		for b in v.placement.buildings.duplicate(true):
			if b.fixed or b.level!=level: continue
			var before: Dictionary=v.placement.resources.duplicate(true)
			var next := Buildings.upgrade(v.placement,b.id)
			if next.get("ok",false) and int(next.resources.mana)>=60 and placement_value(next,v)>placement_value(v.placement,v):
				v.apply_action(next)
				purchases.append({"seed":run_seed,"day":GameState.day,"site":b.id,"action":"upgrade","before":before,"after":v.placement.resources.duplicate(true)})
	expect(int(v.placement.resources.gold)>=0 and int(v.placement.resources.mana)>=0,"legal nonnegative construction wallet")
	v.sync_campaign_wallet()
	Grade.stash(game,v.placement,v.monster_ui.assignments)

func place_defenders(v: Node) -> void:
	v.monster_ui.auto_place()
	if layout_mode!="recommended":
		var restricted: Dictionary=v.placement.duplicate(true)
		var topology = preload("res://scripts/map_builder/ApprovedBattleMap.gd").new()
		topology.setup(v.placement)
		for building in restricted.defense_points:
			var keep: Array=[]
			for c in restricted.defense_points[building]:
				if (layout_mode=="anchor_cluster" and building in ["barracks","ward_core","throne"]) or (layout_mode=="final_line" and topology.line_for(c)=="final") or (layout_mode=="first_line" and topology.line_for(c)=="1"): keep.append(c)
			expect(keep.is_empty() or keep==restricted.defense_points[building],"concentration preserves original slot indices")
			restricted.defense_points[building]=keep
		v.monster_ui.assignments=Members.auto_place(restricted,v.monster_ui.members,v.monster_ui.unlocked(),v.monster_ui.food_income)
	var assignments: Dictionary=v.monster_ui.assignments
	expect(Members.sanitize(v.placement,assignments,v.monster_ui.members)==assignments,"unique legal defense cells")
	expect(Members.upkeep(assignments,v.monster_ui.members)<=v.monster_ui.food_income,"deployment uses real food income")
	var counts := {}
	for id in assignments:
		expect(id in v.monster_ui.unlocked(),"only actually recruited defenders")
		var target: Dictionary=assignments[id]
		counts[target.building]=int(counts.get(target.building,0))+1
	for building in counts: expect(counts[building]<=Buildings.building(v.placement,building).capacity,"legal building capacity")
	if layout_mode=="recommended" and v.placement.grade=="C":
		var tank_ports := {}
		for id in assignments:
			if assignments[id].building=="throne" and v.monster_ui.members[id].species_id in Members.TANKS:
				tank_ports[int(assignments[id].slot)/2]=true
		expect(tank_ports.size()==2,"both C throne entrances have a durable guard")
	Grade.stash(game,v.placement,assignments)

func battle_day() -> Dictionary:
	var v := view()
	if v==null: return {"error":"no management view"}
	if v.preparation_only():
		capture_entry=false
		expect(GameState.day==29 and not game._has_defense_wave_for_day(29),"DAY29 has no combat")
		var ok: bool=v.confirm_preparation_day(); await drain(); await frames(3)
		return {"seed":run_seed,"day":29,"preparation_only":true,"advanced":ok}
	v.monster_ui.set_mode("place"); place_defenders(v)
	await frames(2)
	if capture_entry:
		capture_entry=false
		write_entry_snapshot(v)
	var assignments: Dictionary=v.monster_ui.assignments.duplicate(true)
	var battle_grade: String=v.placement.grade
	var roster: Dictionary=game.monster_roster.duplicate(true)
	var wallet: Dictionary=v.placement.resources.duplicate(true)
	if game.start_flow.guide_step==1: game.start_flow.advance_guide(); await frames(2)
	for i in 12:
		v=view()
		if v==null: return {"error":"view lost before combat","screen":game.current_screen,"buttons":button_rows(game.ui_layer)}
		if v.battle!=null: break
		v.start_battle(); await drain(); await frames(2)
	v=view()
	if v==null or v.battle==null: return {"error":"battle did not start","guide":game.start_flow.guide_step,"status":v.status_text.text if v!=null else game.current_screen,"story":game.story_director.current_scene_id,"queue":game.onboarding_dialogue_queue,"active":game.story_director.is_active()}
	if not game.start_flow.command_seen: game.start_flow.ack_commands()
	var b=v.battle
	# Use the player's normal x3 control only after its tutorial unlock.
	b.set_speed(3.0 if game._combat_speed_unlocked() else 1.0)
	v.set_physics_process(false)
	for unit in game.monster_units+game.enemy_units: unit.set_physics_process(false)
	var hp_start := GameState.demon_lord_hp
	var steps := 0
	var captured := false
	var battle_started := Time.get_ticks_msec()
	while b.running and game.combat_time<600:
		if Time.get_ticks_msec()-battle_started>180000:
			return {"seed":run_seed,"day":GameState.day,"error":"battle wall timeout","screen":game.current_screen,"paused":game.combat_paused,"time":game.combat_time,"queue":game.onboarding_dialogue_queue.size()}
		if game.current_screen=="dialogue": await drain(); continue
		if game.combat_speed_intro_open:
			game._dismiss_combat_speed_intro()
		if game.story_combat_overlay_open and game.story_director.is_active():
			game._story_advance_dialogue(); await frames(1); continue
		b.physics_process(1.0/60.0)
		for unit in game.monster_units+game.enemy_units:
			if is_instance_valid(unit): unit.set_physics_process(false); unit._physics_process(1.0/60.0)
		for tween in b.active_combat_tweens.duplicate():
			if tween!=null and tween.is_valid(): tween.pause(); tween.custom_step(1.0/60.0)
		steps+=1
		if steps%3600==0: print("B04_PROGRESS ",run_seed," D",GameState.day," t=",game.combat_time," screen=",game.current_screen," paused=",game.combat_paused," queue=",game.onboarding_dialogue_queue.size())
		if GameState.day==30 and not captured and game.combat_time>95 and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://_mockup/game_step15_rebalance/battle_day30.png")
			captured=true
		if steps%300==0: await frames(1)
	var result: Dictionary=b.last_result.duplicate(true)
	result.merge({"seed":run_seed,"day":GameState.day,"grade":battle_grade,"layout":layout_mode,"assignments":assignments,"roster_before":roster,"wallet_before":wallet,"hp_start":hp_start,"hp":GameState.demon_lord_hp,"max_hp":GameState.demon_lord_max_hp,"timeout":b.running,"simulation_hz":60,"steps":steps})
	result["units_after"]=[]
	for unit in game.monster_units+game.enemy_units:
		if is_instance_valid(unit): result.units_after.append({"id":unit.unit_id,"faction":unit.faction,"hp":unit.hp,"down":unit.down,"position":[unit.position.x,unit.position.y],"goal":unit.goal_room})
	result["schedule"]=game.wave_manager.schedule.duplicate(true)
	result["directive"]=game.global_directive
	result["captured"]=captured
	result["speed"]=game.combat_speed
	expect(not result.get("win",false) or result.spawned==game.wave_manager.total_to_spawn,"a victory spawns the complete active campaign schedule")
	await frames(5); await drain(); await frames(2)
	result["settlement"]=game.result_summary.duplicate(true)
	result["roster_after"]=game.monster_roster.duplicate(true)
	result["wallet_after"]={"gold":GameState.gold,"mana":GameState.mana,"food":GameState.food}
	expect(not result.timeout,"battle completes before timeout")
	return result

func write_entry_snapshot(v: Node) -> void:
	var folder := "res://tmp/v130r_b04/"+label+"/checkpoints/"
	DirAccess.make_dir_recursive_absolute(folder)
	var payload: Dictionary=game._campaign_save_payload("management")
	var snapshot := {"payload":payload,"approved_map_session":{"layout":Buildings.snapshot(v.placement),"defenders":v.monster_ui.assignments.duplicate(true)},"deployment_context":{"joined":v.monster_ui.joined.duplicate(),"food_income":v.monster_ui.food_income},"update4_profile":game.update4_profile.duplicate(true),"update4_active_run":game.update4_active_run.duplicate(true)}
	var checkpoint := FileAccess.open(folder+str(run_seed)+"_"+str(GameState.day)+".json",FileAccess.WRITE)
	checkpoint.store_string(JSON.stringify(snapshot)); checkpoint.close()

func restore_test_map(snapshot: Dictionary) -> void:
	expect(snapshot.has("approved_map_session"),"checkpoint includes actual purchased map")
	if not snapshot.has("approved_map_session"): return
	game.set_meta(Grade.SESSION,snapshot.approved_map_session.duplicate(true))
	game._set_screen("management")
	await drain(); await frames(2)
	# Restore recorded presentation/deployment caches too: opening management
	# recomputes ownership, while the real live entry can still contain its old
	# cache. Every value below comes from this exact campaign entry, never a fixture.
	expect(snapshot.has("deployment_context"),"checkpoint includes actual deployment context")
	if not snapshot.has("deployment_context"): return
	view().placement.food_state=snapshot.approved_map_session.layout.food_state.duplicate(true)
	view().monster_ui.joined.assign(snapshot.deployment_context.joined)
	view().monster_ui.food_income=int(snapshot.deployment_context.food_income)
	GameState.food_state=snapshot.payload.game_state.food_state.duplicate(true)
	GameState.food_income=int(snapshot.payload.game_state.food_income)
	var actual := Buildings.snapshot(view().placement)
	var expected: Dictionary=snapshot.approved_map_session.layout
	actual=JSON.parse_string(JSON.stringify(actual))
	for field in ["grade","buildings","traps","resources","stage","day","serial","specializations","food_state"]:
		if actual.get(field)!=expected.get(field): write_json("map_restore_diagnostic",{"actual":actual,"expected":expected,"game_state":snapshot.payload.game_state})
		expect(actual.get(field)==expected.get(field),"checkpoint preserves purchased map "+field)

func campaign() -> void:
	if checkpoint_source=="": await new_game()
	else:
		var path := "res://tmp/v130r_b04/"+checkpoint_source+"/checkpoints/"+str(run_seed)+"_"+str(checkpoint_day)+".json"
		var snapshot: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		game.update4_profile=snapshot.update4_profile.duplicate(true)
		game.update4_active_run=snapshot.update4_active_run.duplicate(true)
		expect(game._restore_campaign_payload(snapshot.payload.duplicate(true)),"test-only campaign checkpoint restores")
		await restore_test_map(snapshot)
		if not failures.is_empty(): return
		await drain(); await frames(2)
		for field in ["day","gold","mana","food","demon_lord_hp","demon_lord_max_hp"]:
			expect(GameState.get(field)==snapshot.payload.game_state[field],"checkpoint preserves "+field)
		for species in snapshot.payload.world.monster_roster:
			for field in ["level","exp","bond","promotion_id","specialization_id"]:
				expect(game.monster_roster.get(species,{}).get(field)==snapshot.payload.world.monster_roster[species].get(field),"checkpoint preserves progression "+species+" "+field)
		seed(run_seed+checkpoint_day*1000)
	for day in range(1 if checkpoint_source=="" else checkpoint_day,last_day+1):
		await drain(); await frames(3)
		if game.current_screen!="management" or GameState.day!=day or view()==null:
			expect(false,"natural management entry DAY"+str(day)+" screen "+game.current_screen); return
		if game._early_specialization_required_for_current_day():
			var chosen := false
			for species in game.monster_roster:
				for option in game._specializations_for_monster(species):
					if game._choose_early_specialization(species,str(option.id),false): chosen=true; break
				if chosen: break
			expect(chosen,"required early specialization selected legally")
			Grade.sync_campaign_day(game)
		if game._first_promotion_required_for_current_day() and not game._first_promotion_ready():
			view().open_campaign_action("monsters"); await frames(2)
			var promoted := false
			for species in game.monster_roster:
				for rule in game._evolution_rules_for_monster(species):
					if game._can_promote_monster(species,str(rule.id)):
						var before := {"gold":GameState.gold,"mana":GameState.mana,"infamy":GameState.infamy}
						promoted=game._promote_monster(species,str(rule.id))
						for key in before: expect(GameState.get(key)==before[key]-int(rule.get("cost",{}).get(key,0)),"promotion really pays "+key)
						break
				if promoted: break
			expect(promoted,"required first promotion bought legally")
			await press("MonsterBackButton"); await drain(); await frames(2)
		if GameState.day==29 and game._campaign_final_declaration_pending():
			game._set_campaign_final_declaration("castle_oath"); await drain(); await frames(2)
		if game._campaign_raid_choice_pending():
			view().open_campaign_action("raid"); await drain(); await frames(2)
			var mission: Dictionary=DataRegistry.raid_mission(game.raid_selected_mission_id)
			for species in game.monster_roster:
				if game._can_start_selected_raid(): break
				if species!=game._raid_fixed_captain_id(mission) and species not in game.raid_selected_monster_ids: game._toggle_raid_monster(species)
			expect(game._can_start_selected_raid(),"required raid affordable and roster eligible")
			for i in 5:
				if game.completed_raids.has(game.raid_selected_mission_id): break
				game._start_selected_raid(); await drain(); await frames(2)
			expect(game.completed_raids.has(game.raid_selected_mission_id),"required raid completed through real payment")
			game._onboarding_finish_raid_preview(); await drain(); await frames(2)
		auto_build()
		capture_entry=true
		var result := await battle_day()
		result.merge({"seed":run_seed,"day":day},false)
		rows.append(result); write_json("days",rows); write_json("purchases",purchases)
		print("B04_DAY ",run_seed," D",day," win=",result.get("win",false)," HP=",result.get("hp",-1),"/",result.get("max_hp",-1)," roster=",game.monster_roster.size()," gold=",GameState.gold)
		if result.get("preparation_only",false):
			expect(result.advanced and game.current_screen=="result","DAY29 normal preparation result")
			game._continue_from_result(); await drain(); await frames(3); await auxiliary()
			continue
		if result.has("error"):
			expect(false,str(result)); return
		# Preserve first-attempt curves separately from a normal player retry.
		if not result.get("win",false):
			if retries==0: return
			game._edit_placement_from_result(); await drain(); await frames(3)
			var retry_result := await battle_day()
			result["retry"]=retry_result
			write_json("days",rows)
			print("B04_RETRY ",run_seed," D",day," win=",retry_result.get("win",false)," HP=",retry_result.get("hp",-1))
			if not retry_result.get("win",false): return
		if game._result_growth_choice_required():
			for growth in game.last_growth_summary:
				if game._choose_result_growth(str(growth.get("monster_id",""))): break
			game._review_growth_from_result(); await frames(2)
		game._continue_from_result(); await drain(); await frames(3); await auxiliary()
		if day==30:
			expect(game.campaign_completed,"DAY30 natural ending recorded")
			write_json("ending_"+str(run_seed),{"completed":game.campaign_completed,"ending":game.resolved_campaign_ending_id,"screen":game.current_screen})

func run() -> void:
	started=Time.get_ticks_msec()
	var seeds := "130401"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("label="): label=arg.get_slice("=",1)
		if arg.begins_with("seeds="): seeds=arg.get_slice("=",1)
		if arg.begins_with("last_day="): last_day=int(arg.get_slice("=",1))
		if arg.begins_with("layout="): layout_mode=arg.get_slice("=",1)
		if arg.begins_with("checkpoint="): checkpoint_source=arg.get_slice("=",1)
		if arg.begins_with("day="): checkpoint_day=int(arg.get_slice("=",1))
		if arg.begins_with("retries="): retries=int(arg.get_slice("=",1))
		if arg=="raster=full": fast=false
	expect(OS.get_user_data_dir().replace("\\","/").contains("v130r_b04"),"isolated test profile")
	if not failures.is_empty(): get_tree().quit(1); return
	# Replace only the test process's unit resource with its cosmetic-only subclass.
	# The actual controller, damage, movement, growth and settlement remain intact.
	if fast and DisplayServer.get_name()=="headless":
		cosmetic_controller=load("res://tools/tests/V130RB04FastController.gd")
		cosmetic_controller.take_over_path("res://scripts/game/ApprovedBattleController.gd")
	for value in seeds.split(","):
		run_seed=int(value)
		await create_game()
		await campaign()
		write_json("days",rows); write_json("purchases",purchases)
		game._shutdown_audio_for_exit(); game.campaign_autosave_pending=false
		game.queue_free(); await frames(5)
	write_json("checks",{"checks":checks,"failures":failures,"elapsed_msec":Time.get_ticks_msec()-started})
	get_tree().quit(0 if failures.is_empty() else 1)
func event(tag: String, extra: Dictionary = {}) -> void:
	print("B04_EVENT ",run_seed," D",GameState.day," ",tag," ",JSON.stringify(extra) if tag in ["blocked_result_continue","missing_button"] else "")
func expect(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error("B04 "+message)
func write_json(id: String, data) -> void:
	var path := "res://tmp/v130r_b04/"+label+"/"+id+".json"
	var f := FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"\t")); f.close()
func frames(n: int = 4) -> void:
	Engine.max_fps=0
	OS.low_processor_usage_mode=false
	for i in n: await get_tree().process_frame


func view() -> Node: return game.ui_layer.get_node_or_null("ApprovedMapManagement")


func press(id: String) -> bool:
	var b := game.ui_layer.find_child(id,true,false) as BaseButton
	if b==null or b.disabled: event("missing_button",{"id":id}); return false
	b.pressed.emit(); await frames(); return true


func drain() -> void:
	for i in 500:
		await frames(2)
		if game.current_screen!="dialogue": return
		if game.story_director.is_active(): game._story_advance_dialogue()
		else: game._onboarding_advance_dialogue()
	event("dialogue_stuck")


func create_game() -> void:
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	ProjectSettings.set_setting("debug/start_flow14",true)
	LanguageSettings.set_locale(locale,false)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(game); await frames(8)
	# GameRoot._ready randomizes; set the audit seed only after that boundary.
	seed(run_seed)
	event("boot",{"load_msec":Time.get_ticks_msec()-started,"user_dir":OS.get_user_data_dir()})


func new_game() -> void:
	if mode=="ux":
		for language in ["en","zh_CN","ko"]:
			await press("TitleLanguage_"+language)
			event("title_language",{"expected":language,"actual":LanguageSettings.locale})
	await capture("title")
	await press("TitleStartButton")
	await capture("menu")
	await press("CampaignNewGameButton")
	await capture("prologue")
	for i in 7: await press("PrologueNext")
	await press("NamingNext"); await press("NamingNext")
	await capture("name")
	game.onboarding_name_input.text = "Audit"+str(run_seed)
	game._onboarding_name_changed(game.onboarding_name_input.text)
	await press("ConfirmNameButton"); await drain(); await frames(8)
	event("new_management")
	expect(GameState.day==1 and GameState.demon_lord_hp==1500 and game.monster_roster.size()==3,"fresh game starts without a campaign fixture")
	for row in game.monster_roster.values(): expect(int(row.level)==1 and int(row.exp)==0,"fresh companions start at level one with zero EXP")
	if mode=="ux": event("tutorial_overlay_check",{"legacy_overlay_present":game.ui_layer.find_child("TutorialOverlay",true,false)!=null,"guide_step":game.start_flow.guide_step})
	await capture("guide")


func auxiliary() -> void:
	for i in 12:
		await drain(); await frames(5)
		if game.current_screen=="management" or game.current_screen=="ending": return
		event("auxiliary_screen",{"buttons":button_rows(game.ui_layer)})
		if game.current_screen=="raid_preview":
			await press("StartRaidButton")
		elif game.current_screen=="raid":
			if game.last_raid_result.is_empty():
				if not game._can_start_selected_raid():
					for id in game.monster_roster:
						if id!=game._raid_fixed_captain_id(DataRegistry.raid_mission(game.raid_selected_mission_id)):
							game._toggle_raid_monster(str(id)); await frames(3)
							if game._can_start_selected_raid(): break
				await press("RaidStartButton"); await drain()
			else: await press("RaidBackButton")
		else: return


func button_rows(node: Node) -> Array:
	var result: Array = []
	if node is BaseButton and node.is_visible_in_tree(): result.append({"name":node.name,"text":node.text if node is Button else "","disabled":node.disabled,"tooltip":node.tooltip_text})
	for child in node.get_children(): result.append_array(button_rows(child))
	return result
