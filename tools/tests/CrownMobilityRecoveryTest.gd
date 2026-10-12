extends "res://tools/tests/SkillRuntimeConnectionTest.gd"
const Commands=preload("res://scripts/v122/combat/V122CommandService.gd")
const Ledger=preload("res://scripts/v122/combat/V122BattleLedger.gd")
var proof:Array=[]
func _ready()->void:
	get_tree().create_timer(180).timeout.connect(func():push_error("Crown mobility fixture timeout");get_tree().quit(1))
	call_deferred("run")
func run()->void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"),"isolated mobility userdata")
	if not failures.is_empty():get_tree().quit(1);return
	DataRegistry.load_all();UISettings.reset_skill_cutscene_history(false)
	if OS.get_cmdline_user_args().has("--mobility-visual"):
		await jelly("slime_gate_bulwark","always",false);await jelly("slime_rescue_alchemy_gel","always",false);await courier("always",false)
		print("CROWN_MOBILITY_VISUAL_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1);return
	for branch in ["slime_gate_bulwark","slime_rescue_alchemy_gel"]:
		var baseline:Dictionary={}
		for policy in ["off","once","once","always"]:
			var result:Dictionary=await jelly(branch,policy,false)
			if baseline.is_empty():baseline=result
			else:expect(result==baseline,"inheritance policies same actual outcome "+branch)
		var automatic:Dictionary=await jelly(branch,"always",true)
		expect(automatic==baseline,"actual jelly AI same outcome "+branch)
	var baseline:Dictionary={}
	for policy in ["off","once","once","always"]:
		var result:Dictionary=await courier(policy,false)
		if baseline.is_empty():baseline=result
		else:expect(result==baseline,"courier policies same actual outcome")
	expect(await courier("always",true)==baseline,"actual courier AI same outcome")
	await anchor_edges();await rescue_edges();await courier_edges();await commands_and_clock();await ranking();await suppression_and_pause();await repeated_support();await real_speed_frames();await legacy_ancestry()
	var file:=FileAccess.open(output_dir+"/results.json",FileAccess.WRITE);file.store_string(JSON.stringify(proof,"\t"))
	print("CROWN_MOBILITY_RECOVERY_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
func fixture(form:String,policy:String="off",branch:String="")->void:
	var species:String=DataRegistry.update4_crown_evolutions[form].monster_id
	await setup_case(species,policy)
	output_dir="res://tmp/crown_mobility_recovery";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game.update4_active_run.campaign_mode_id=Modes.COUNCIL_MODE_ID
	var instance_id:=""
	for id in DataRegistry.monster_instances:
		if str(DataRegistry.monster_instances[id].get("species_id",""))==species:instance_id=str(id);break
	game.update4_active_run.crown={"crown_form_id":form,"selected_instance_id":instance_id}
	game.update4_active_run.upper_floor={"crown_suppressed":false}
	game.update4_active_run.council_season={"crown_source_evolution_id":branch}
	game.update3_active_run.heart={"heart_id":"","awakened":false}
	var old=caster
	caster=game._create_unit(species,game._scaled_monster_stats(species),Constants.FACTION_MONSTER,"entrance")
	caster.global_position=game.graph.center("entrance");caster.current_room="entrance";caster.refresh_depth_slot();caster.set_physics_process(false)
	old.queue_free();game.monster_units[0]=caster;game.selected_unit=caster;caster.action_direction=Vector2.RIGHT
	ally.global_position=caster.global_position+Vector2(35,0);ally.refresh_depth_slot()
	if species=="bat_courier":
		enemy.global_position=outsider.global_position+Vector2(30,0);enemy.current_room="recovery";enemy.refresh_depth_slot();outsider.hp=maxi(1,int(outsider.max_hp*.3))
	game._set_screen(Constants.SCREEN_COMBAT,false)
	await settle()
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
func request(id:String,auto:bool=false)->bool:
	var combat=game.combat_scene
	for other in combat.skill_slots_for(caster):
		if other!=null and str(other)!=id:caster.set_skill_cooldown(str(other),100)
	return combat.try_auto_monster_skill(caster) if auto else combat.request_selected_skill(combat.skill_slots_for(caster).find(id))
func step(delta:float)->void:
	game.combat_time+=delta;game.combat_scene.crown_mobility.tick(delta)
func jelly(branch:String,policy:String,auto:bool)->Dictionary:
	await fixture("crown_pudding_royal_bastion",policy,branch)
	var runtime=game.combat_scene.crown_mobility;var action=game.combat_scene.skill_actions
	var before:Vector2=ally.global_position;var base:int=caster.effective_def()
	var seen:bool=UISettings.skill_cutscene_seen.has("skill:royal_jelly_bastion")
	expect(request("royal_jelly_bastion",auto),"actual jelly request "+branch)
	expect(action.is_active()==(policy=="always" or(policy=="once" and not seen)),"jelly viewing policy")
	if action.is_active():
		expect(caster.get_meta("royal_jelly_uses",0)==0 and ally.global_position==before,"prepare no use or displacement")
		expect(action.actors[0].sprite_frames==caster.sprite.sprite_frames,"native crown action actor")
		action.tick(.56)
		expect(action.caption.text.contains("방어 +3" if branch=="slime_gate_bulwark" else "아군 안전 이동"),"contact caption reflects actual inheritance")
		if policy=="always" and not auto:
			game.combat_scene.hud._update_selected_unit_status();await capture(branch+"_contact")
		action.skip();action.skip()
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
	expect(caster.get_meta("royal_jelly_uses",0)==1 and GameState.mana==500 and ally.royal_jelly_timer==6,"one use and existing base guard")
	if branch=="slime_gate_bulwark":
		expect(caster.crown_anchor_fixed and caster.effective_def()==base+3 and caster.effective_move_speed()==0,"real center holds and DEF3")
		expect(ally.global_position==before and runtime.jelly_caption(caster).contains("방어 +3"),"no false rescue and actual center caption")
	else:
		expect(ally.global_position.distance_to(caster.global_position-Vector2(44,0))<.1 and ally.path_points.is_empty(),"real lowest ally moves behind source44")
		expect(caster.effective_def()==base and not caster.crown_anchor_pending,"rescue never grants anchor defense")
	expect(not request("royal_jelly_bastion"),"one use cannot duplicate")
	var result:Dictionary={"mana":GameState.mana,"uses":caster.get_meta("royal_jelly_uses"),"guard":ally.royal_jelly_timer,"def_bonus":caster.effective_def()-base,"moved":ally.global_position.distance_to(before)}
	proof.append({"kind":branch,"policy":policy,"auto":auto,"result":result,"progression":"forced crown fixture, not earned unlock"})
	await dispose_case();return result
func courier(policy:String,auto:bool)->Dictionary:
	await fixture("crown_popo_grand_night_courier",policy)
	var runtime=game.combat_scene.crown_mobility;var action=game.combat_scene.skill_actions
	var start:Vector2=caster.global_position;var seen:bool=UISettings.skill_cutscene_seen.has("skill:royal_urgent_courier")
	expect(runtime.courier_target(caster)==outsider,"actual different-room danger target")
	expect(request("royal_urgent_courier",auto),"actual courier request")
	expect(action.is_active()==(policy=="always" or(policy=="once" and not seen)),"courier viewing policy")
	if action.is_active():
		expect(caster.get_meta("royal_courier_uses",0)==0 and caster.global_position==start and outsider.night_relay_buffs.is_empty(),"prepare no move/use/support")
		action.tick(.56)
		expect(action.caption.text.contains("도착 후 지원"),"contact accurately starts movement only")
		if policy=="always" and not auto:
			game.combat_scene.hud._update_selected_unit_status();await capture("courier_contact_start")
		action.skip();action.skip()
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
	expect(caster.get_meta("royal_courier_uses",0)==1 and outsider.night_relay_buffs.is_empty(),"one committed use before arrival")
	step(.1)
	expect(caster.global_position!=start and runtime.transits.has(caster.get_instance_id()) and outsider.night_relay_buffs.is_empty(),"actual safe-route half transit no early support")
	outsider.global_position+=Vector2(0,8);outsider.refresh_depth_slot();step(.1)
	expect(caster.global_position.distance_to(outsider.global_position)<.1 and not runtime.transits.has(caster.get_instance_id()),"actual moving recipient arrival within.20 simulation")
	var key:String=str(outsider.crown_courier_sources.keys()[0])
	outsider._physics_process(.2)
	expect(float(outsider.night_relay_buffs[key].remaining)==6.0,"arrival frame recipient physics never double-debits lifetime")
	expect(is_equal_approx(outsider.effective_move_speed(),outsider.move_speed*1.2) and is_equal_approx(outsider.effective_attack_interval(),outsider.attack_interval*.85),"actual move/attack support")
	expect(is_equal_approx(outsider._hostile_status_duration(5),4),"actual hostile duration20percent reduction")
	expect(caster.crown_courier_sources.is_empty() and ally.crown_courier_sources.is_empty(),"recipient only")
	expect(is_equal_approx(float(caster.skill_cooldowns[DataRegistry.monster(caster.unit_id).skill_slots[0]]),70),"actual first room entry CD100to70")
	step(5.99);expect(is_equal_approx(outsider._hostile_status_duration(5),4),"six second deadline alive5.99")
	step(.01);expect(outsider.effective_move_speed()==outsider.move_speed and outsider.crown_courier_sources.is_empty(),"six second expiry independent of recipient physics")
	var result:Dictionary={"mana":GameState.mana,"uses":caster.get_meta("royal_courier_uses"),"arrival":runtime.contributions[caster.get_instance_id()].royal_courier_arrivals,"cd_recovery":runtime.contributions[caster.get_instance_id()].royal_mail_cooldown_seconds}
	proof.append({"kind":"courier","policy":policy,"auto":auto,"result":result,"progression":"forced crown controlled rooms, not earned unlock"})
	await dispose_case();return result
func anchor_edges()->void:
	await fixture("crown_pudding_royal_bastion","off","slime_gate_bulwark")
	var runtime=game.combat_scene.crown_mobility;var center:Vector2=caster.global_position
	caster.global_position+=Vector2(-32,0);caster.refresh_depth_slot();var base:int=caster.effective_def()
	expect(request("royal_jelly_bastion") and caster.effective_def()==base and not caster.path_points.is_empty(),"approach actual walking with no prearrival DEF")
	for i in range(30):
		caster._physics_process(.05);step(.05)
		if caster.crown_anchor_fixed:break
	expect(caster.global_position.distance_to(center)<=caster.PATH_POINT_REACHED_RADIUS and caster.effective_def()==base+3,"actual Unit physics reaches center")
	game.combat_time=5.99;expect(caster.effective_def()==base+3,"arrival does not reset original six second window")
	game.combat_time=6;expect(caster.effective_def()==base and not caster.crown_anchor_pending,"anchor expiry clears fixation/DEF")
	await dispose_case()
	await fixture("crown_pudding_royal_bastion","always","slime_gate_bulwark")
	expect(request("royal_jelly_bastion"),"freeze saved evolution prepare")
	game.monster_roster.slime.promotion_id="slime_rescue_alchemy_gel";game.combat_scene.skill_actions.skip()
	expect(caster.crown_anchor_fixed,"saved crown ancestry unaffected by later roster changes")
	game.update4_active_run.upper_floor.crown_suppressed=true
	expect(caster.effective_def()==int(caster.crown_base_body.def) and not caster.crown_anchor_pending,"suppression removes own anchor immediately")
	await dispose_case()
func rescue_edges()->void:
	for boundary in ["fixed","sealed","duo_locked","occupied"]:
		await fixture("crown_pudding_royal_bastion","off","slime_rescue_alchemy_gel")
		var before:Vector2=ally.global_position
		match boundary:
			"fixed":ally.set_meta("fixed",true)
			"sealed":ally.seal_move_lock_timer=1
			"duo_locked":ally.duo_move_lock_timer=1
			"occupied":enemy.global_position=caster.global_position-Vector2(44,0);enemy.refresh_depth_slot()
		expect(request("royal_jelly_bastion") and ally.global_position==before and ally.royal_jelly_timer==6,"blocked rescue preserves actual base protection "+boundary)
		expect(game.combat_scene.crown_mobility.jelly_caption(caster).contains("이동 불가"),"accurate blocked rescue caption")
		await dispose_case()
	await fixture("crown_pudding_royal_bastion","always","slime_rescue_alchemy_gel")
	request("royal_jelly_bastion");caster.global_position+=Vector2(8,0);caster.refresh_depth_slot();game.combat_scene.skill_actions.skip()
	expect(caster.get_meta("royal_jelly_uses",0)==0 and ally.royal_jelly_timer==0,"changed frozen caster endpoint cancels before use")
	await dispose_case()
func courier_edges()->void:
	for boundary in ["dead","queued","room_changed","source_suppressed","source_sealed"]:
		await fixture("crown_popo_grand_night_courier")
		request("royal_urgent_courier");step(.15)
		match boundary:
			"dead":outsider.hp=0;outsider.down=true
			"queued":outsider.queue_free()
			"room_changed":outsider.global_position=game.graph.center("barracks");outsider.refresh_depth_slot()
			"source_suppressed":game.update4_active_run.upper_floor.crown_suppressed=true
			"source_sealed":caster.seal_move_lock_timer=1
		step(.1)
		expect(game.combat_scene.crown_mobility.transits.is_empty() and game.combat_scene.crown_mobility.buffs.is_empty() and caster.get_meta("royal_courier_uses",0)==1,"cancelled committed transit keeps use/no support "+boundary)
		await dispose_case()
	await fixture("crown_popo_grand_night_courier")
	request("royal_urgent_courier");step(.2)
	outsider.apply_night_relay_buff("ordinary",9,1.3,.75)
	game.update4_active_run.upper_floor.crown_suppressed=true
	expect(is_equal_approx(outsider.effective_move_speed(),outsider.move_speed*1.3) and outsider.crown_courier_sources.is_empty() and outsider.night_relay_buffs.has("ordinary"),"source suppression clears only own support before real consumption")
	await dispose_case()
func commands_and_clock()->void:
	await fixture("crown_popo_grand_night_courier")
	request("royal_urgent_courier");step(.15)
	game.set_meta("v122_battle_plan",{"defense_zones":[{"zone_id":"fixture","anchor_room_id":"entrance","room_ids":["entrance"]}],"world_anchors":{"entrance":[0,0]}})
	game.set_meta("v122_command_state",Commands.new_state());game.set_meta("v122_battle_ledger",Ledger.new_state(1,1,"fixture"))
	var result:Dictionary=game.combat_scene.issue_v122_command("rally",{"type":"defense_zone","id":"fixture"})
	expect(bool(result.get("ok",false)) and game.combat_scene.crown_mobility.transits.is_empty(),"accepted manual command cancels before next arrival tick")
	game.combat_scene.set_speed(3);step(.04*3)
	expect(game.combat_scene.crown_mobility.buffs.is_empty() and caster.get_meta("royal_courier_uses",0)==1,"x3 crossing completion cannot resurrect cancelled support")
	await dispose_case()
func ranking()->void:
	await fixture("crown_popo_grand_night_courier")
	ally.global_position=game.graph.center("barracks");ally.current_room="barracks";ally.hp=65;ally.max_hp=100
	outsider.hp=72;outsider.max_hp=100
	for i in range(10):
		var actor=game._create_unit("explorer",DataRegistry.enemy("explorer"),Constants.FACTION_ENEMY,"recovery")
		actor.global_position=outsider.global_position+Vector2(i,20);actor.set_physics_process(false);game.enemy_units.append(actor)
	var actor=game._create_unit("explorer",DataRegistry.enemy("explorer"),Constants.FACTION_ENEMY,"barracks")
	actor.global_position=ally.global_position+Vector2(30,0);actor.set_physics_process(false);game.enemy_units.append(actor)
	expect(game.combat_scene.crown_mobility.courier_target(caster)==ally,"lowest HP wins over many enemies at healthier recipient")
	expect(request("royal_urgent_courier",true),"eligible HP65 auto request no weighted rank omission")
	await dispose_case()
func suppression_and_pause()->void:
	await fixture("crown_popo_grand_night_courier","always")
	request("royal_urgent_courier");game.update4_active_run.upper_floor.crown_suppressed=true;game.combat_scene.skill_actions.skip()
	expect(caster.get_meta("royal_courier_uses",0)==0 and game.combat_scene.crown_mobility.transits.is_empty(),"suppression at preparation no use")
	await dispose_case()
func repeated_support()->void:
	await fixture("crown_popo_grand_night_courier")
	var runtime=game.combat_scene.crown_mobility
	request("royal_urgent_courier");step(.2)
	var first_key:String=str(outsider.crown_courier_sources.keys()[0])
	ally.global_position=game.graph.center("barracks");ally.current_room="barracks";ally.hp=1;ally.refresh_depth_slot()
	var guard=game._create_unit("explorer",DataRegistry.enemy("explorer"),Constants.FACTION_ENEMY,"barracks")
	guard.global_position=ally.global_position+Vector2(30,0);guard.set_physics_process(false);game.enemy_units.append(guard)
	expect(request("royal_urgent_courier"),"second committed different recipient")
	step(.2)
	expect(outsider.crown_courier_sources.has(first_key) and ally.crown_courier_sources.size()==1 and runtime.buffs.size()==2,"second recipient never erases first owned support")
	expect(caster.get_meta("royal_courier_uses",0)==2 and not request("royal_urgent_courier"),"two uses limit rejects third")
	expect(runtime.contributions[caster.get_instance_id()].royal_mail_cooldown_seconds==30,"second actual room entry never repeats first recovery")
	game.combat_time=6.2;runtime.tick(0)
	expect(outsider.crown_courier_sources.is_empty() and not ally.crown_courier_sources.is_empty(),"each recipient retains own arrival deadline")
	game.combat_time=6.4;runtime.tick(0);expect(runtime.buffs.is_empty(),"last own deadline removes both records")
	await dispose_case()
func real_speed_frames()->void:
	for speed in [1,3]:
		await fixture("crown_popo_grand_night_courier")
		var combat=game.combat_scene;game.story_feature_enabled=false;combat.set_speed(speed)
		request("royal_urgent_courier")
		for unit in game.monster_units+game.enemy_units:unit.attack_cooldown=100
		combat.physics_process(.1/float(speed))
		expect(combat.crown_mobility.transits.has(caster.get_instance_id()) and outsider.crown_courier_sources.is_empty(),"actual controller speed half transit "+str(speed))
		combat.physics_process(.1/float(speed))
		outsider._physics_process(.1/float(speed))
		expect(combat.crown_mobility.transits.is_empty() and outsider.crown_courier_sources.size()==1,"actual controller speed arrives "+str(speed))
		if not outsider.crown_courier_sources.is_empty():expect(float(outsider.night_relay_buffs[outsider.crown_courier_sources.keys()[0]].remaining)==6,"real controller plus recipient physics full six seconds "+str(speed))
		await dispose_case()
func legacy_ancestry()->void:
	await fixture("crown_pudding_royal_bastion","always")
	game.update4_active_run.council_season.erase("crown_source_evolution_id")
	game.monster_roster.slime.promotion_id="slime_gate_bulwark"
	request("royal_jelly_bastion")
	expect(str(game.update4_active_run.council_season.crown_source_evolution_id)=="slime_gate_bulwark","missing legacy ancestry freezes original at first preparation")
	game.monster_roster.slime.promotion_id="slime_rescue_alchemy_gel";game.combat_scene.skill_actions.skip()
	expect(caster.crown_anchor_fixed,"legacy prepared ancestry survives later roster changes")
	await dispose_case()
	await fixture("crown_popo_grand_night_courier","off")
	request("royal_urgent_courier");step(.1);game.combat_scene.set_speed(3);game._open_pause_menu()
	var position:Vector2=caster.global_position;var clock:float=game.combat_time
	game.combat_scene.physics_process(.2)
	expect(game.combat_time==clock and caster.global_position==position and game.combat_paused,"real menu pauses active transit and simulation clock")
	game.combat_scene.crown_mobility.clear()
	expect(not caster.crown_anchor_pending and game.combat_scene.crown_mobility.transits.is_empty(),"battle exit clears owned runtime")
	await dispose_case()
