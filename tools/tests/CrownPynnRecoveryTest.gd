extends "res://tools/tests/CrownMobilityRecoveryTest.gd"
func _ready()->void:
	get_tree().create_timer(240).timeout.connect(func():push_error("Pynn fixture timeout");get_tree().quit(1))
	call_deferred("run")
func run()->void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"),"isolated Pynn userdata")
	if not failures.is_empty():get_tree().quit(1);return
	DataRegistry.load_all();UISettings.reset_skill_cutscene_history(false)
	if OS.get_cmdline_user_args().has("--pynn-visual"):
		await manual_ui(UISettings.is_touch_ui())
	else:
		for branch in ["imp_flame_adept","imp_ember_shaman"]:
			for value in ["single_flame","area_flame","ember_curse"]:
				var baseline:Dictionary={}
				for policy in ["off","once","once","always"]:
					var result:Dictionary=await royal_effect(branch,value,policy)
					if baseline.is_empty():baseline=result
					else:expect(result==baseline,"same actual cost/effect across policies "+branch+value)
		await prices();await history_and_ordinary();await prepared_edges();await curse_edges();await automatic_modes();await manual_ui(false);await manual_ui(true)
	var file:=FileAccess.open(output_dir+"/results.json",FileAccess.WRITE);file.store_string(JSON.stringify(proof,"\t"))
	print("CROWN_PYNN_RECOVERY_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
func pynn(policy:String="off",branch:String="imp_flame_adept")->void:
	await fixture("crown_pynn_castle_flame_sage",policy,branch)
	output_dir="res://tmp/crown_pynn_recovery";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	enemy.def=0;enemy.set_physics_process(false);enemy.hp=10000;enemy.max_hp=10000
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
func area_case()->void:
	enemy.global_position=game.graph.center("barracks");enemy.current_room="barracks";enemy.refresh_depth_slot()
	var other=game._create_unit("explorer",DataRegistry.enemy("explorer"),Constants.FACTION_ENEMY,"barracks")
	other.global_position=enemy.global_position+Vector2(30,0);other.current_room="barracks";other.hp=10000;other.max_hp=10000;other.def=0;other.set_physics_process(false);game.enemy_units.append(other)
func royal_request(value:String)->bool:
	game.combat_scene.crown_flame.set_mode(caster,value)
	return game.combat_scene.request_selected_skill(game.combat_scene.skill_slots_for(caster).find("tricolor_demonfire"))
func wait_projectile()->void:await get_tree().create_timer(.3).timeout
func royal_effect(branch:String,value:String,policy:String)->Dictionary:
	await pynn(policy,branch)
	if value=="area_flame":await area_case()
	var runtime=game.combat_scene.crown_flame;var action=game.combat_scene.skill_actions
	var hp:int=enemy.hp;var cost:int=int(runtime.quote(caster,value).cost);var seen:bool=UISettings.skill_cutscene_seen.has("skill:tricolor_demonfire")
	expect(royal_request(value),"actual tricolor request "+value)
	expect(action.is_active()==(policy=="always" or(policy=="once" and not seen)),"mode skillID viewing policy")
	if action.is_active():
		expect(GameState.mana==500 and enemy.hp==hp and runtime.histories.is_empty() and runtime.curses.is_empty(),"preparation no cost/history/damage/curse")
		expect(action.actors[0].sprite_frames==caster.sprite.sprite_frames and caster.sprite_path.contains("crown_pynn"),"current native Pynn crown actor")
		action.tick(.56)
		expect(action.caption.text.contains("마나 %d"%cost),"contact caption actual committed quote")
		if value=="single_flame":expect(action.caption.text.contains("도착 시 피해") and enemy.hp==hp,"contact launches not premature damage")
		if policy=="always":
			game.combat_scene.hud._update_selected_unit_status();await capture(branch+"_"+value+"_contact")
		action.skip();action.skip()
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
	if value=="single_flame":await wait_projectile()
	expect(GameState.mana==500-cost and caster.get_meta("tricolor_uses",0)==1 and runtime.history(caster)==[value],"actual own quote charged/history once")
	var damage:int=hp-enemy.hp
	if value=="single_flame":expect(damage==roundi(52*1.45*(1.10 if branch=="imp_flame_adept" else 1)),"actual magic projectile damage no body ATK duplicate")
	elif value=="area_flame":
		expect(damage==roundi(34*1.35*(1.10 if branch=="imp_flame_adept" else 1)) and enemy.slow_timer==2.5,"actual area contact/ordinary slow")
		expect(game.enemy_units[1].hp==10000-damage,"same frozen area recipients")
	else:
		expect(damage==0 and runtime.def_penalty(enemy)==2 and enemy.effective_def()==0,"curse no fake damage and actual independent DEF reduction")
		expect(is_equal_approx(enemy.effective_move_speed(),enemy.move_speed*.7),"actual independent Royal slow consumer")
		var record:Dictionary=runtime.curses.values()[0]
		expect(is_equal_approx(float(record.def_ends),5*1.30*(1.20 if branch=="imp_ember_shaman" else 1)),"actual inherited curse time")
	var result:Dictionary={"mana":GameState.mana,"uses":caster.get_meta("tricolor_uses"),"damage":damage,"mode":value,"curse_count":runtime.curses.size()}
	proof.append({"policy":policy,"branch":branch,"result":result,"progression":"forced crown fixture, not earned mastery"})
	await dispose_case();return result
func prices()->void:
	await pynn()
	var runtime=game.combat_scene.crown_flame
	var expected:Dictionary={"single_flame":[23,27,16],"area_flame":[26,32,19],"ember_curse":[15,18,10]}
	for value in expected:
		runtime.histories.clear();expect(int(runtime.quote(caster,value).cost)==expected[value][0],"base source quote "+value)
		runtime.histories[caster.get_instance_id()]=[value];expect(int(runtime.quote(caster,value).cost)==expected[value][1],"repeat own quote "+value)
		var recent:Array=["single_flame","area_flame","ember_curse"];recent.erase(value);recent.push_front(value)
		runtime.histories[caster.get_instance_id()]=recent;expect(int(runtime.quote(caster,value).cost)==expected[value][2],"cycle own quote "+value)
	expect(game._current_skill_mana_cost(DataRegistry.skill("fireball"),caster)==19 and game._current_skill_mana_cost(DataRegistry.skill("flame_zone"),caster)==38,"own ordinary source efficiency")
	game.selected_unit=caster
	expect(game._current_skill_mana_cost(DataRegistry.skill("fireball"),ally)==20 and game._current_skill_mana_cost(DataRegistry.skill("fireball"))==20,"selected source never leaks into another caster/default")
	game.update4_active_run.upper_floor.crown_suppressed=true
	expect(game._current_skill_mana_cost(DataRegistry.skill("fireball"),caster)==20 and not runtime.available(caster),"live suppression restores regular price")
	game.update4_active_run.upper_floor.crown_suppressed=false
	expect(game._current_skill_mana_cost({"cost_mana":0},caster)==0 and game._current_skill_mana_cost({"cost_mana":1},caster)==1,"zero/minimum no free positive casts")
	game.campaign_profile.active_decree_id="decree_arcane_rationing";runtime.histories.clear()
	expect(game._current_skill_mana_cost(DataRegistry.skill("fireball"))==16 and game._current_skill_mana_cost(DataRegistry.skill("fireball"),caster)==15,"actual existing decree.80 composes before own efficiency")
	expect(int(runtime.quote(caster,"single_flame").cost)==19 and int(runtime.quote(caster,"area_flame").cost)==22 and int(runtime.quote(caster,"ember_curse").cost)==12,"actual mode/globalceil/source round price order")
	await dispose_case()
func history_and_ordinary()->void:
	await pynn()
	var combat=game.combat_scene;var runtime=combat.crown_flame
	expect(combat.request_selected_skill(combat.skill_slots_for(caster).find("fireball")),"actual ordinary single cast")
	expect(runtime.history(caster)==["single_flame"] and GameState.mana==481,"actual ordinary producer/cost19")
	await wait_projectile();await area_case()
	expect(combat.request_selected_skill(combat.skill_slots_for(caster).find("flame_zone")),"actual ordinary area cast")
	expect(runtime.history(caster)==["single_flame","area_flame"] and GameState.mana==443,"actual area producer/cost38")
	enemy.global_position=caster.global_position+Vector2(30,0);enemy.current_room="entrance";enemy.refresh_depth_slot()
	expect(royal_request("ember_curse") and runtime.history(caster)==["single_flame","area_flame","ember_curse"] and GameState.mana==428,"three actual committed kinds achievable with one Royal use")
	expect(int(runtime.quote(caster,"single_flame").cost)==16 and royal_request("single_flame") and GameState.mana==412,"second actual Royal receives three-kind discount16")
	expect(runtime.history(caster)==["area_flame","ember_curse","single_flame"] and not royal_request("area_flame"),"latest3 only and two Royal limit")
	expect(float(runtime.contributions[caster.get_instance_id()].pynn_mana_efficiency_saved)==5,"actual integer source savings1+2+1+1")
	await wait_projectile();combat.abandon_suspended_frame()
	expect(runtime.histories.is_empty() and runtime.curses.is_empty() and enemy.crown_ember_sources.is_empty(),"production battle abandon clears temporary history/curse")
	await dispose_case()
func prepared_edges()->void:
	for boundary in ["source_suppressed","changed_history","changed_mode","changed_ancestry","low_mana","target_dead","target_queued","target_out_of_range"]:
		await pynn("always")
		var runtime=game.combat_scene.crown_flame;royal_request("single_flame")
		match boundary:
			"source_suppressed":game.update4_active_run.upper_floor.crown_suppressed=true
			"changed_history":runtime.histories[caster.get_instance_id()]=["single_flame"]
			"changed_mode":runtime.set_mode(caster,"ember_curse")
			"changed_ancestry":game.update4_active_run.council_season.crown_source_evolution_id="imp_ember_shaman"
			"low_mana":GameState.mana=0
			"target_dead":enemy.hp=0;enemy.down=true
			"target_queued":enemy.queue_free()
			"target_out_of_range":enemy.global_position=caster.global_position+Vector2(1000,0)
		game.combat_scene.skill_actions.skip()
		expect(caster.get_meta("tricolor_uses",0)==0 and GameState.mana==(0 if boundary=="low_mana" else 500) and runtime.curses.is_empty(),"stale frozen intent no costs/use/effect "+boundary)
		await dispose_case()
	await pynn("always")
	game.combat_scene.request_selected_skill(0);game.update4_active_run.upper_floor.crown_suppressed=true;game.combat_scene.skill_actions.skip()
	expect(GameState.mana==500 and enemy.hp==10000,"ordinary stale efficiency quote reject no cheap cast")
	await dispose_case()
	for id in ["fireball","flame_zone"]:
		for boundary in ["seal","duo"]:
			await pynn("always")
			if id=="flame_zone":await area_case()
			var combat=game.combat_scene
			combat.request_selected_skill(combat.skill_slots_for(caster).find(id))
			if boundary=="seal":caster.seal_skill_lock_timer=1
			else:caster.duo_action_lock_timer=1
			combat.skill_actions.skip()
			expect(GameState.mana==500 and enemy.hp==10000 and combat.crown_flame.history(caster).is_empty(),"ordinary contact rechecks action ownership "+id+boundary)
			await dispose_case()
func curse_edges()->void:
	await pynn("off","imp_ember_shaman")
	var runtime=game.combat_scene.crown_flame;enemy.def=10;enemy.armor_break_amount=3;enemy.armor_break_timer=20;enemy.slow_factor=.5;enemy.slow_timer=20
	expect(royal_request("ember_curse") and enemy.effective_def()==5 and is_equal_approx(enemy.effective_move_speed(),enemy.move_speed*.5),"independent existing armor/stronger slow composition")
	game.combat_time=4;runtime.tick()
	expect(runtime.slow_factor(enemy)==1 and runtime.def_penalty(enemy)==2 and enemy.armor_break_timer==20 and enemy.slow_timer==20,"Royal slow expires separately and never edits legacy timers")
	game.update4_active_run.upper_floor.crown_suppressed=true
	expect(enemy.effective_def()==7 and enemy.armor_break_amount==3 and enemy.crown_ember_sources.is_empty(),"suppression prunes only own curse before consumer")
	await dispose_case()
	await pynn("off","imp_ember_shaman")
	var old=enemy;enemy=game._create_unit("official_hero_leon",DataRegistry.enemy("official_hero_leon"),Constants.FACTION_ENEMY,"entrance")
	enemy.global_position=caster.global_position+Vector2(30,0);enemy.current_room="entrance";enemy.def=10;enemy.hp=1000;enemy.set_physics_process(false);game.enemy_units[0]=enemy;old.queue_free()
	royal_request("ember_curse")
	var value:Dictionary=game.combat_scene.crown_flame.curses.values()[0]
	expect(enemy.effective_def()==9 and is_equal_approx(float(value.def_ends),4*1.30*1.20),"actual boss receives reduced DEF1/four-second inherited base")
	await dispose_case()
	await pynn("off","imp_ember_shaman")
	enemy.heart_first_control_available=true;enemy.heart_first_control_multiplier=1.3
	royal_request("ember_curse")
	value=game.combat_scene.crown_flame.curses.values()[0]
	expect(not enemy.heart_first_control_available and is_equal_approx(float(value.slow_ends),2.5*1.3*1.2*1.3),"actual Royal slow consumes existing first-heart-control exactly once")
	expect(is_equal_approx(float(value.def_ends),5*1.3*1.2),"DEF effect never consumes or duplicates heart first-slow bonus")
	await dispose_case()
func automatic_modes()->void:
	for value in ["single_flame","area_flame","ember_curse"]:
		await pynn()
		var combat=game.combat_scene;var runtime=combat.crown_flame
		if value=="area_flame":await area_case()
		if value=="ember_curse":runtime.histories[caster.get_instance_id()]=["single_flame","area_flame"]
		for id in combat.skill_slots_for(caster):
			if id!=null and str(id)!="tricolor_demonfire":caster.set_skill_cooldown(str(id),100)
		runtime.set_mode(caster,"area_flame" if value!="area_flame" else "single_flame")
		expect(runtime.auto_mode(caster)==value and combat.try_auto_monster_skill(caster),"actual useful auto mode independent from manual "+value)
		expect(str(caster.get_meta("tricolor_result",{}).get("mode",""))==value,"auto committed same mode used for own quote")
		if value=="single_flame":await wait_projectile()
		await dispose_case()
	await pynn()
	var runtime=game.combat_scene.crown_flame;enemy.def=0;enemy.slow_factor=.4;enemy.slow_timer=10
	runtime.histories[caster.get_instance_id()]=["single_flame","area_flame"]
	expect(runtime.auto_mode(caster)=="single_flame","no-effect curse skips zeroDEF/longer stronger slow target")
	await dispose_case()
func manual_ui(touch:bool)->void:
	if UISettings.is_touch_ui()!=touch:return
	await pynn()
	if touch:output_dir+="_touch";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var hud=game.combat_scene.hud;var runtime=game.combat_scene.crown_flame
	expect(hud.pynn_controls.modes.size()==3 and hud.pynn_controls.skills.size()==3,"real inspector mode and three manual cast controls")
	var mode_control:Button=hud.pynn_controls.modes.ember_curse
	await click(mode_control,mode_control.size*.5)
	expect(runtime.mode(caster)=="ember_curse" and hud.pynn_controls.skills.tricolor_demonfire.text.contains("15"),"actual screen click selects mode and current price")
	game._open_pause_menu();hud._update_pynn_controls();var before:int=GameState.mana
	hud._request_pynn_manual_skill(caster,"tricolor_demonfire")
	expect(GameState.mana==before and caster.get_meta("tricolor_uses",0)==0,"protected menu callback cannot bypass pause into hidden cast")
	game._close_pause_menu();hud._update_pynn_controls()
	var control:Button=hud.pynn_controls.skills.tricolor_demonfire
	await click(control,control.size*.5)
	expect(GameState.mana==485 and caster.get_meta("tricolor_uses",0)==1 and runtime.def_penalty(enemy)==2,"real screen button commits selected curse and same quote")
	for button in hud.pynn_controls.skills.values():
		expect(button.get_parent().get_rect().size.y>=button.position.y+button.size.y,"manual controls fit actual inspector bounds")
	hud._update_selected_unit_status();await capture("pynn_manual_"+("touch" if touch else "desktop"))
	await dispose_case()
