extends "res://tools/tests/CrownMobilityRecoveryTest.gd"
func _ready()->void:
	get_tree().create_timer(240).timeout.connect(func():push_error("Gob fixture timeout");get_tree().quit(1))
	call_deferred("run")
func run()->void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"),"isolated Gob userdata")
	if not failures.is_empty():get_tree().quit(1);return
	DataRegistry.load_all();UISettings.reset_skill_cutscene_history(false)
	if OS.get_cmdline_user_args().has("--gob-cutscene-visual"):
		await chain_case("always");print("GOB_NATIVE_VISUAL: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1);return
	if OS.get_cmdline_user_args().has("--gob-visual"):
		await manual_ui();print("GOB_MANUAL_UI: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1);return
	if OS.get_cmdline_user_args().has("--gob-walk"):
		await distant_walk();print("GOB_WALK: %s"%str(failures));get_tree().quit(0 if failures.is_empty() else 1);return
	for policy in ["off","once","once","always"]:await chain_case(policy)
	await basic_kernel();await mark_priority();await edges();await branches();await distant_walk();await repeated();await controls_and_callbacks();await counter_and_trap();await manual_ui()
	var file:=FileAccess.open(output_dir+"/results.json",FileAccess.WRITE);file.store_string(JSON.stringify(proof,"\t"))
	print("CROWN_GOB_RECOVERY_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
func gob(policy:String="off",branch:String="goblin_ambush_captain")->void:
	await fixture("crown_gob_midnight_marshal",policy,branch)
	output_dir="res://tmp/crown_gob_recovery";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	enemy.def=0;enemy.hp=10000;enemy.max_hp=10000
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
	game.combat_scene.ledger_room_marks["entrance"]={"debt":0}
func manual_ui()->void:
	await gob();var combat=game.combat_scene;var hud=combat.hud;var runtime=combat.crown_command
	output_dir+="_touch" if UISettings.is_touch_ui() else "_desktop";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	expect(hud.manual_skill_controls.skills.size()==3 and hud.manual_skill_controls.skills.has("royal_no_second_cut"),"actual ally inspector exposes connected ordinary and royal skills")
	var control:Button=hud.manual_skill_controls.skills.royal_no_second_cut
	expect(game._combat_ui_at(control.get_global_transform_with_canvas()*(control.size*.5)),"actual expanded inspector owns manual button pointer")
	game._open_pause_menu();hud._request_manual_skill(caster,"royal_no_second_cut")
	expect(not runtime.owned(caster) and caster.get_meta("royal_chain_uses",0)==0,"menu guard forbids hidden manual callback")
	game._close_pause_menu();hud._update_manual_skill_controls()
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
	await click(control,control.size*.5)
	expect(runtime.owned(caster) and caster.get_meta("royal_chain_uses",0)==0,"actual royal screen click starts only approach")
	runtime.tick(.01);hud._update_selected_unit_status()
	expect(caster.get_meta("royal_chain_uses",0)==1 and enemy.hp<10000,"actual clicked chain commits real contact")
	for button in hud.manual_skill_controls.skills.values():expect(button.get_parent().size.y>=button.position.y+button.size.y,"manual skill fits actual inspector bounds")
	await capture("gob_manual_"+("touch" if UISettings.is_touch_ui() else "desktop"));await dispose_case()
func additional(id:String="spore_doll",position:Vector2=Vector2.ZERO)->Node:
	var other=game._create_unit(id,DataRegistry.enemy(id),Constants.FACTION_ENEMY,"entrance")
	other.global_position=enemy.global_position+Vector2(18,0) if position==Vector2.ZERO else position;other.current_room=game.graph.room_at_world(other.global_position)
	other.hp=10000;other.max_hp=10000;other.def=0;other.set_physics_process(false);other.refresh_depth_slot();game.enemy_units.append(other)
	return other
func advance(seconds:float)->void:
	var remaining:float=seconds
	while remaining>0:
		var delta:float=minf(.05,remaining);game.combat_time+=delta;caster._physics_process(delta);game.combat_scene.crown_command.tick(delta);remaining-=delta
func chain_case(policy:String)->void:
	await gob(policy);var other=additional();var combat=game.combat_scene;var runtime=combat.crown_command;var action=combat.skill_actions
	var hp:int=enemy.hp;var secondary_hp:int=other.hp;var expected:int=combat.DamageService.compute(caster,enemy,1.0);var origin:Vector2=caster.global_position
	var before_seen:bool=UISettings.skill_cutscene_seen.has("skill:royal_no_second_cut")
	expect(request("royal_no_second_cut"),"actual chain request "+policy)
	expect(action.is_active()==(policy=="always" or(policy=="once" and not before_seen)),"native viewing policy")
	if action.is_active():
		expect(enemy.hp==hp and caster.get_meta("royal_chain_uses",0)==0 and combat.ledger_debt_recorded==0,"preparation no use/hit/debt")
		expect(action.actors[0].sprite_frames==caster.sprite.sprite_frames and caster.sprite_path.contains("crown_gob"),"actual current crown sprite")
		action.tick(.56);expect(action.caption.text.contains("실제 타격 후 사용"),"caption approach not fake hit")
		if policy=="always":await capture("gob_chain_approach")
		action.skip();action.skip()
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
	expect(enemy.hp==hp and caster.get_meta("royal_chain_uses",0)==0 and combat.ledger_debt_recorded==0,"commit accepts approach only")
	runtime.tick(.01)
	expect(enemy.hp==hp-expected and other.hp==secondary_hp,"first actual normal contact only")
	expect(caster.get_meta("royal_chain_uses",0)==1 and combat.ledger_debt_recorded==1,"first contact commits one use/ledger")
	var interval:float=caster.effective_attack_interval();advance(interval-.1)
	expect(other.hp==secondary_hp,"second strike waits normal interval")
	advance(.2)
	expect(other.hp==secondary_hp-expected and combat.ledger_debt_recorded==1,"adjacent support one normal strike no double debt")
	advance(1.0)
	expect(not runtime.owned(caster) and caster.global_position.distance_to(origin)<=caster.PATH_POINT_REACHED_RADIUS,"actual physics walking return")
	expect(runtime.defense_factor(caster)==.85 and int(runtime.contributions[caster.get_instance_id()].royal_chain_contacts)==2,"post defense and actual contribution2")
	if policy=="always":game.combat_scene.hud._update_selected_unit_status();await capture("gob_chain_return")
	proof.append({"policy":policy,"damage":hp-enemy.hp,"support_damage":secondary_hp-other.hp,"uses":caster.get_meta("royal_chain_uses"),"debt":combat.ledger_debt_recorded,"return_distance":caster.global_position.distance_to(origin),"progression":"forced crown fixture, not natural earned"})
	await dispose_case()
func basic_kernel()->void:
	await gob();var combat=game.combat_scene;var hp:int=enemy.hp
	combat.try_attack(caster,game.enemy_units);var ordinary:int=hp-enemy.hp
	caster.attack_cooldown=0;enemy.hp=hp
	var impact:Dictionary=combat._perform_standard_attack(caster,enemy)
	expect(int(impact.actual_hp_loss)==ordinary and int(impact.requested_damage)==ordinary,"extracted full normal kernel matches ordinary exact actual HP")
	caster.attack_cooldown=0;enemy.hp=hp;enemy.duo_barrier=1000
	impact=combat._perform_standard_attack(caster,enemy)
	expect(bool(impact.applied) and int(impact.actual_hp_loss)==0,"delivered fully shielded normal hit distinct actual HP0")
	await dispose_case()
func mark_priority()->void:
	await gob();var runtime=game.combat_scene.crown_command;var other=additional("thief",game.graph.center("treasure"))
	other.current_room="treasure";other.goal_room="treasure";game.thief_steal_timers[other]=2.0
	expect(runtime.mark(caster)==other and str(runtime.marks[caster.get_instance_id()].source)=="royal_command","actual progressing gold channel outranks nearby generic")
	enemy.scent_mark_timer=4.0
	var scent:float=enemy.scent_mark_timer;runtime.mark(caster)
	expect(enemy.scent_mark_timer==scent,"royal mark preserves separate Koko scent")
	other.hp=0;other.down=true;expect(runtime.mark(caster)==enemy,"dead marked actor pruned")
	game.update4_active_run.upper_floor.crown_suppressed=true
	expect(runtime.mark(caster)==null and runtime.marks.is_empty(),"suppression clears own mark")
	await dispose_case()
func edges()->void:
	for boundary in ["source","target","room","move","seal"]:
		await gob("always");request("royal_no_second_cut")
		match boundary:
			"source":game.update4_active_run.upper_floor.crown_suppressed=true
			"target":enemy.hp=0;enemy.down=true
			"room":enemy.global_position=game.graph.center("recovery");enemy.current_room="recovery"
			"move":caster.global_position+=Vector2(16,0)
			"seal":caster.seal_skill_lock_timer=1
		game.combat_scene.skill_actions.skip()
		expect(not game.combat_scene.crown_command.owned(caster) and caster.get_meta("royal_chain_uses",0)==0 and game.combat_scene.ledger_debt_recorded==0,"stale intent no use/debt "+boundary)
		await dispose_case()
	await gob();request("royal_no_second_cut");var runtime=game.combat_scene.crown_command
	runtime.cancel(caster);expect(caster.get_meta("royal_chain_uses",0)==0 and runtime.defense_factor(caster)==1,"prehit manual cancel no penalty/use")
	request("royal_no_second_cut");runtime.tick(.01);runtime.cancel(caster,false)
	expect(caster.get_meta("royal_chain_uses",0)==1 and runtime.defense_factor(caster)==.85,"posthit cancel no refund with penalty")
	var before:int=caster.def;caster.guard_bonus=3;caster.heart_def_bonus=2
	expect(caster.effective_def()==roundi((before+5)*.85),"separate final penalty preserves base/guard/heart")
	game.combat_time+=4
	expect(caster.effective_def()==before+5 and runtime.defense_factor(caster)==1,"deadline expiry no base stat mutation")
	await dispose_case()
func counter_and_trap()->void:
	for held in [false,true]:
		await gob();var combat=game.combat_scene;var runtime=combat.crown_command
		enemy.down=true;enemy.hp=0;var leon=additional("official_hero_leon",caster.global_position+Vector2(30,0))
		combat.leon_stance_id="leon_stance_duelist";caster.hp=1;var hp:int=leon.hp
		request("royal_no_second_cut")
		if held:leon.hp_changed.connect(func(_unit):combat.presentation_hold=true,CONNECT_ONE_SHOT)
		runtime.tick(.01)
		expect(leon.hp<hp and caster.get_meta("royal_chain_uses",0)==1 and combat.ledger_debt_recorded==1,"real Leon contact use/debt before counter "+str(held))
		expect(int(runtime.contributions[caster.get_instance_id()].royal_chain_contacts)==1 and int(runtime.contributions[caster.get_instance_id()].royal_chain_actual_hp_damage)==hp-leon.hp,"royal actual contact metric before reaction")
		if held:
			expect(caster.is_alive() and combat.pending_atomic_tail.is_valid(),"held first reaction retains ordered tail")
			combat.presentation_hold=false;combat._resume_atomic_tail()
		expect(not caster.is_alive() and combat.leon_stance_activations==1,"native counter once can down caster")
		combat._resume_atomic_tail();runtime.tick(.01)
		expect(combat.leon_stance_activations==1 and not runtime.owned(caster),"no stale pursuit or duplicated counter after down")
		await dispose_case()
	await gob();var combat=game.combat_scene;var runtime=combat.crown_command
	request("royal_no_second_cut");runtime.tick(.01)
	enemy.global_position=game.graph.center("spike_corridor");enemy.current_room="spike_corridor";enemy.refresh_depth_slot();var hp:int=enemy.hp
	game.trap_cooldown=0;combat.update_room_effects(.01)
	expect(hp-enemy.hp==17 and int(runtime.contributions[caster.get_instance_id()].royal_trap_actual_total_hp_damage)==17,"actual connected trap HP14to17 and separate contribution")
	game.trap_cooldown=0;hp=enemy.hp;combat.update_room_effects(.01)
	expect(hp-enemy.hp==14,"next actual trap unchanged after consumed window")
	await dispose_case()
func branches()->void:
	await gob();var runtime=game.combat_scene.crown_command
	request("royal_no_second_cut");runtime.tick(.01)
	var data:Dictionary=runtime.trap_request(enemy,14)
	expect(int(data.damage)==17 and int(runtime.trap_request(enemy,14).damage)==14,"bounded primary trap14to17 once")
	runtime.trap_contact(data,17)
	expect(int(runtime.contributions[caster.get_instance_id()].royal_trap_actual_total_hp_damage)==17 and int(runtime.contributions[caster.get_instance_id()].royal_trap_extra_requested_damage)==3,"actual total and raw extra kept separate")
	runtime.trap_windows[caster.get_instance_id()]={"unit":caster,"target":enemy,"ends":4.0}
	expect(int(runtime.trap_request(enemy,30).damage)==36,"authored trap lure30to36")
	runtime.trap_windows[caster.get_instance_id()]={"unit":caster,"target":enemy,"ends":4.0};game.update4_active_run.upper_floor.crown_suppressed=true
	expect(int(runtime.trap_request(enemy,14).damage)==14,"suppression prunes trap own window")
	await dispose_case()
	await gob("off","goblin_vault_keeper");runtime=game.combat_scene.crown_command
	var thief=additional("thief",game.graph.center("treasure"));thief.current_room="treasure";thief.goal_room="treasure"
	game.thief_steal_timers[thief]=2
	expect(runtime.interrupt_objective_channel(thief)==2 and game.thief_steal_timers[thief]==0,"real gold progress2reset0")
	expect(runtime.interrupt_objective_channel(thief)==0,"zero progress no fake contribution")
	game.thief_steal_timers[thief]=-999;var gold:int=GameState.gold
	expect(runtime.interrupt_objective_channel(thief)==0 and game.thief_steal_timers[thief]==-999 and GameState.gold==gold,"completed sentinel and prior resource loss immutable")
	await dispose_case()
	await gob("off","goblin_vault_keeper");runtime=game.combat_scene.crown_command
	game.monster_roster.goblin.promotion_id="goblin_vault_keeper"
	caster.global_position=game.graph.center("treasure");caster.current_room="treasure";caster.refresh_depth_slot()
	enemy.queue_free();game.enemy_units.clear()
	thief=additional("thief",caster.global_position+Vector2(30,0));thief.current_room="treasure";thief.goal_room="treasure";game.thief_steal_timers[thief]=2.0
	expect(game.combat_scene._monster_ai_behavior(caster)=="vault_guard" and not game.combat_scene._thief_loot_is_contested(thief),"actual vault promotion does not precontest legacy channel")
	expect(request("royal_no_second_cut"),"actual vault crown skill request")
	runtime.tick(.01)
	expect(game.thief_steal_timers[thief]==0 and float(runtime.contributions[caster.get_instance_id()].royal_chain_theft_seconds_cancelled)==2,"actual vault hit resets genuine progress2 and records contribution")
	await dispose_case()
func distant_walk()->void:
	await gob();var runtime=game.combat_scene.crown_command;var origin:Vector2=caster.global_position
	enemy.global_position=game.graph.center("barracks");enemy.current_room="barracks";enemy.goal_room="barracks"
	expect(request("royal_no_second_cut"),"reachable different actual room approach")
	advance(.1);expect(caster.global_position!=origin and caster.get_meta("royal_chain_uses",0)==0,"actual walk no immediate teleport/use")
	advance(20)
	print("Gob actual walk end: position=%s origin=%s uses=%d owned=%s state=%s"%[caster.global_position,origin,int(caster.get_meta("royal_chain_uses",0)),runtime.owned(caster),runtime.chains])
	expect(caster.get_meta("royal_chain_uses",0)==1 and not runtime.owned(caster) and caster.global_position.distance_to(origin)<=caster.PATH_POINT_REACHED_RADIUS,"different room real hit and walking return")
	await dispose_case()
func controls_and_callbacks()->void:
	await gob();var combat=game.combat_scene;var runtime=combat.crown_command;var other=additional()
	game.set_meta("v122_command_state",{"active_commands":{"focus":{"target":{"type":"enemy","id":str(other.get_instance_id())}}}})
	expect(combat._committed_combat_target(caster,game.enemy_units)==other and runtime.prepare(caster).primary==other,"explicit focus precedes royal passive mark")
	caster.mark_threat(enemy,4,true)
	expect(combat._combat_action_target(caster,game.enemy_units,300)==enemy and runtime.prepare(caster).is_empty(),"forced taunt preserved no conflicting chain")
	caster.threat_forced=false;game.set_meta("v122_command_state",{})
	request("royal_no_second_cut");game.set_meta("v122_command_state",{"active_commands":{"focus":{"target":{"type":"enemy","id":str(other.get_instance_id())}}}});runtime.tick(.01)
	expect(not runtime.owned(caster) and caster.get_meta("royal_chain_uses",0)==0,"new explicit focus cancels frozen approach without retarget/use")
	await dispose_case()
	await gob();combat=game.combat_scene;runtime=combat.crown_command
	request("royal_no_second_cut");combat.set_pause_state(true,false);var time:float=game.combat_time;var hp:int=enemy.hp
	combat.physics_process(.5)
	expect(game.combat_time==time and enemy.hp==hp and runtime.owned(caster),"actual pause gates chain clocks/contact")
	combat.set_pause_state(false,false)
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
	combat.presentation_hold=true;combat.pending_atomic_tail=func():pass
	runtime.tick(.01);expect(enemy.hp==hp,"pending atomic tail and presentation hold forbid chain damage")
	combat.presentation_hold=false;combat.pending_atomic_tail=Callable();runtime.tick(.01)
	expect(enemy.hp<hp and caster.get_meta("royal_chain_uses",0)==1,"resume first contact once")
	await dispose_case()
	await gob();combat=game.combat_scene;runtime=combat.crown_command
	request("royal_no_second_cut")
	enemy.hp_changed.connect(func(_unit):runtime.cancel(caster,false),CONNECT_ONE_SHOT)
	runtime.tick(.01)
	expect(caster.get_meta("royal_chain_uses",0)==1 and not runtime.owned(caster) and runtime.defense_factor(caster)==.85,"synchronous hit callback cancellation keeps delivered use once")
	await dispose_case()
	await gob();combat=game.combat_scene;runtime=combat.crown_command
	request("royal_no_second_cut");var generation:int=runtime.generation
	enemy.hp_changed.connect(func(_unit):runtime.clear(),CONNECT_ONE_SHOT);runtime.tick(.01)
	expect(runtime.generation==generation+1 and runtime.chains.is_empty() and runtime.trap_windows.is_empty(),"battle replacement callback cannot resurrect stale chain")
	await dispose_case()
	await gob();combat=game.combat_scene;runtime=combat.crown_command
	request("royal_no_second_cut")
	game.set_meta("v122_battle_plan",{"defense_zones":[{"zone_id":"fixture","anchor_room_id":"entrance","room_ids":["entrance"]}],"world_anchors":{"entrance":[0,0]}})
	game.set_meta("v122_command_state",Commands.new_state());game.set_meta("v122_battle_ledger",Ledger.new_state(1,1,"fixture"))
	var response:Dictionary=combat.issue_v122_command("rally",{"type":"defense_zone","id":"fixture"})
	expect(bool(response.get("ok",false)) and not runtime.owned(caster) and caster.get_meta("royal_chain_uses",0)==0,"accepted manual movement owns next frame before contact")
	await dispose_case()
	for speed in [1,3]:
		await gob();combat=game.combat_scene;runtime=combat.crown_command;other=additional()
		game.story_feature_enabled=false;combat.set_speed(speed);request("royal_no_second_cut");hp=enemy.hp
		for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
		combat.physics_process(.05/float(speed))
		expect(enemy.hp<hp and caster.get_meta("royal_chain_uses",0)==1,"actual controller scaled first contact "+str(speed))
		var interval:float=caster.effective_attack_interval()
		for i in range(ceili((interval+.2)/.05)):
			caster._physics_process(.05/float(speed));combat.physics_process(.05/float(speed))
		expect(other.hp<10000 and caster.get_meta("royal_chain_uses",0)==1,"actual scaled second contact no duplicate use "+str(speed))
		await dispose_case()
func repeated()->void:
	await gob();var runtime=game.combat_scene.crown_command
	for i in range(2):
		expect(request("royal_no_second_cut"),"actual successive allowed cast")
		advance(7)
	expect(caster.get_meta("royal_chain_uses",0)==2 and not request("royal_no_second_cut"),"two actual first-hit limit")
	game.combat_scene.abandon_suspended_frame()
	expect(runtime.chains.is_empty() and runtime.marks.is_empty() and runtime.penalties.is_empty() and runtime.trap_windows.is_empty(),"production abandon clears own temporary state")
	await dispose_case()
