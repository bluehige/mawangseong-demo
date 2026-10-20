extends "res://tools/tests/SkillRuntimeConnectionTest.gd"
const Damage=preload("res://scripts/combat/DamageService.gd")
var proof:Array=[]
func run()->void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"),"isolated live stat fixture")
	if not failures.is_empty():get_tree().quit(1);return
	DataRegistry.load_all()
	if OS.get_cmdline_user_args().has("--native-visual"):
		await lifecycle()
		print("CROWN_LIVE_STAT_VISUAL_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()])
		get_tree().quit(0 if failures.is_empty() else 1);return
	for form in DataRegistry.update4_crown_evolutions:
		for suppressed in [false,true]:await layers(str(form),suppressed)
	await hp_edges();await healing_restore();await resistance();await lifecycle();await callback_and_reuse()
	output_dir="res://tmp/crown_live_stat_recovery";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var file:=FileAccess.open(output_dir+"/results.json",FileAccess.WRITE);file.store_string(JSON.stringify(proof,"\t"))
	print("CROWN_LIVE_STAT_RECOVERY_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
func fixture(form:String,suppressed:bool=false)->Dictionary:
	var descriptor:Dictionary=DataRegistry.update4_crown_evolutions[form];var species:String=descriptor.monster_id
	await setup_case(species,"off")
	game.update4_active_run.campaign_mode_id=Modes.COUNCIL_MODE_ID
	var instance_id:=""
	for id in DataRegistry.monster_instances:
		if str(DataRegistry.monster_instances[id].get("species_id",""))==species:instance_id=str(id);break
	game.update4_active_run.crown={"crown_form_id":form,"selected_instance_id":instance_id}
	game.update4_active_run.upper_floor={"crown_suppressed":suppressed}
	game.update3_active_run.heart={"heart_id":"","awakened":false}
	game.monster_roster[species].level=6
	game.monster_roster[species].bond=80
	var old=caster;var stats:Dictionary=game._scaled_monster_stats(species)
	caster=game._create_unit(species,stats,Constants.FACTION_MONSTER,"entrance");caster.global_position=game.graph.center("entrance");caster.refresh_depth_slot();caster.set_physics_process(false)
	old.queue_free();game.monster_units[0]=caster;game.selected_unit=caster;await settle()
	return stats.crown_base_body.duplicate(true)
func body(unit)->Dictionary:
	return {"max_hp":unit.max_hp,"atk":unit.atk,"def":unit.def,"move_speed":unit.move_speed,"healing":unit.outgoing_healing_multiplier}
func layers(form:String,initial_suppressed:bool)->void:
	var base:Dictionary=await fixture(form,initial_suppressed)
	var descriptor:Dictionary=DataRegistry.update4_crown_evolutions[form]
	var max_active:int=roundi(float(base.max_hp)*float(descriptor.stat_multipliers.get("max_hp",1)))
	var atk_active:int=roundi(float(base.atk)*float(descriptor.stat_multipliers.get("atk",1)))
	var def_active:int=roundi(float(base.def)*float(descriptor.stat_multipliers.get("def",1)))
	var move_active:float=float(base.move_speed)*float(descriptor.stat_multipliers.get("move_speed",1))
	caster.hp=40;caster.guard_bonus=3;caster.heart_def_bonus=2;caster.armor_break_amount=1;caster.acid_def_penalty=1
	caster.intrinsic_move_multiplier=1.2;caster.slow_factor=.7;caster.heart_move_multiplier=.94
	var saved_base:Dictionary=caster.crown_base_body.duplicate(true)
	expect(caster.sprite_path==str(caster.crown_body_descriptor.base_sprite if initial_suppressed else descriptor.combat_sprite),"initial art follows existing suppression policy "+form)
	var results:Array=[]
	for i in range(20):
		var suppressed:bool=i%2==0;game.update4_active_run.upper_floor.crown_suppressed=suppressed
		var actual:Dictionary=body(caster)
		expect(actual.max_hp==int(base.max_hp if suppressed else max_active) and actual.atk==int(base.atk if suppressed else atk_active) and actual.def==int(base.def if suppressed else def_active) and is_equal_approx(actual.move_speed,float(base.move_speed) if suppressed else move_active),form+" livebodytoggle"+str(i))
		expect(caster.hp==40 and caster.crown_base_body==saved_base,"absoluteHP/snapshot noheal/drift "+form+str(i))
		expect(caster.sprite_path==str(caster.crown_body_descriptor.base_sprite if suppressed else descriptor.combat_sprite),"live native base-crown art follows currentbody "+form+str(i))
		expect(caster.effective_def()==actual.def+3 and is_equal_approx(caster.effective_move_speed(),actual.move_speed*1.2*.7*.94),"independent guard/heart/debuff/move layers preserved "+form+str(i))
		if i<2:results.append(actual)
		if i<2 and game.quarter_renderer._prepared_maze():
			expect(caster.sprite.material is ShaderMaterial and caster.sprite.material.shader==game.quarter_renderer.maze_actor_depth.ACTOR_SHADER and is_equal_approx(float(caster.sprite.material.get_shader_parameter("foot_depth")),game.to_local(caster.global_position).y),"live native material keeps real wall occlusion and footdepth "+form+str(i))
	var computed:int=Damage.compute(caster,enemy)
	game.update4_active_run.upper_floor.crown_suppressed=true
	var suppressed_damage:int=Damage.compute(caster,enemy)
	expect(suppressed_damage==maxi(1,roundi(float(base.atk)-float(enemy.effective_def())*.5)),"actual ordinary damage consumes current crown attack "+form)
	expect(GameState.mana==500,"bodytoggle never creates or changes sharedmana "+form)
	proof.append({"form":form,"initial_suppressed":initial_suppressed,"base":base,"active_damage":computed,"suppressed_damage":suppressed_damage,"sample":results,"progression":"forced crown; naturalunlock NOT_RUN"})
	game.queue_free();await settle()
func hp_edges()->void:
	var base:Dictionary=await fixture("crown_pudding_royal_bastion")
	caster.hp=caster.max_hp;game.update4_active_run.upper_floor.crown_suppressed=true
	var hp_before:int=int(base.max_hp)
	expect(caster.max_hp==hp_before and caster.hp==hp_before,"lower cap clips absoluteHP")
	game.update4_active_run.upper_floor.crown_suppressed=false
	expect(caster.max_hp>hp_before and caster.hp==hp_before,"larger cap restores capacity without healing")
	caster.hp=1
	game.update4_active_run.upper_floor.crown_suppressed=true
	expect(caster.max_hp==base.max_hp and caster.hp==1 and caster.is_alive(),"living HP1 never down from layertransition")
	caster.hp=0;caster.down=true
	game.update4_active_run.upper_floor.crown_suppressed=false
	expect(caster.max_hp>base.max_hp and caster.hp==0 and caster.down and not caster.is_alive(),"down0 never revived by crown restoration")
	game.queue_free();await settle()
	base=await fixture("crown_popo_grand_night_courier")
	caster.hp=70;game.update4_active_run.upper_floor.crown_suppressed=true
	expect(caster.max_hp==base.max_hp and caster.hp==70,"Popo removing maxHPweakness is not a freeheal")
	game.queue_free();await settle()
func healing_restore()->void:
	await fixture("crown_mori_grand_mycelial_priest",true)
	var combat=game.combat_scene
	expect(combat._outgoing_heal_amount(caster,46)==46,"Mori born suppressed normalheal46")
	game.update4_active_run.upper_floor.crown_suppressed=false
	expect(combat._outgoing_heal_amount(caster,46)==50 and combat._outgoing_heal_amount(caster,24)==26,"Mori born suppressed actual1.08 restoration")
	caster.mori_healing_penalty_timer=6;caster.mori_healing_penalty_multiplier=.85
	expect(combat._outgoing_heal_amount(caster,46)==42,"separate actual outgoing1.08*.85 once")
	game.update4_active_run.upper_floor.crown_suppressed=true
	expect(combat._outgoing_heal_amount(caster,46)==39 and caster.mori_healing_penalty_timer==6,"suppression removes crown only, preserves outgoingpenalty")
	game.queue_free();await settle()
func resistance()->void:
	await fixture("crown_popo_grand_night_courier")
	caster.apply_slow(5,.7)
	expect(is_equal_approx(caster.slow_timer,5/1.06),"actual slow5 / resistance1.06 NEW_DESIGN")
	var sampled:float=caster.slow_timer;game.update4_active_run.upper_floor.crown_suppressed=true
	expect(is_equal_approx(caster.move_speed,caster.crown_base_body.move_speed) and caster.slow_timer==sampled,"suppression never rescales existing negative timers")
	caster.slow_timer=0;caster.apply_slow(5,.7)
	expect(caster.slow_timer==5,"suppressed new status duration5")
	game.update4_active_run.upper_floor.crown_suppressed=false
	caster.seal_move_lock_timer=0;caster.seal_skill_lock_timer=0;caster.heart_first_control_available=true;caster.heart_first_control_multiplier=1.5
	caster.apply_seal_chain(5,4,7)
	expect(is_equal_approx(caster.seal_move_lock_timer,5/1.06*1.15*1.5) and is_equal_approx(caster.seal_skill_lock_timer,4/1.06*1.15),"native seal capture weakness1.15 and heartfirstcontrol once")
	expect(caster.seal_target_immunity_timer==7 and not caster.heart_first_control_available,"friendly immunity unchanged and hearttoken consumed once")
	caster.apply_armor_break(2,5,"hostile_probe")
	expect(is_equal_approx(caster.armor_break_timer,5/1.06),"armorbreak through shared actual resistance kernel")
	caster.simulation_speed=3;var before:float=caster.seal_move_lock_timer;caster._physics_process(.1)
	expect(is_equal_approx(caster.seal_move_lock_timer,before-.3),"real x3 negative timer tick")
	game.queue_free();await settle()
func lifecycle()->void:
	await fixture("crown_pudding_royal_bastion")
	output_dir="res://tmp/crown_live_stat_recovery";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	if UISettings.is_touch_ui():output_dir+="_touch";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var hud=game.combat_scene.hud
	# Fixture replaced the selected actor while root processing is paused. Remove
	# its old inspector before building the current one, as normal screen rebuild does.
	for panel in game.ui_layer.find_children("CombatUnitInspector*","",true,false):panel.get_parent().remove_child(panel);panel.queue_free()
	hud.build_combat_unit_inspector();hud._update_selected_unit_status();await capture("crown_body_active_native")
	game.update4_active_run.upper_floor.crown_suppressed=true
	hud._update_selected_unit_status()
	expect(game.combat_scene.hud._combat_unit_status_text(caster,false).contains("왕관 효과 억제"),"native HUD explicitly shows crown suppression")
	expect(hud.selected_unit_dynamic_labels.hp.text=="%d / %d"%[caster.hp,caster.max_hp] and hud.selected_unit_dynamic_labels.status.text.contains("왕관 효과 억제"),"actual rendered HP/status labels current after suppression")
	var stats_label=hud.selected_unit_dynamic_labels.get("stats",hud.selected_unit_dynamic_labels.get("role_stats"))
	expect(stats_label.text.contains("공격 %d · 방어 %d"%[caster.atk,caster.def]) and not hud.selected_unit_dynamic_labels.name.text.contains("왕관"),"native inspector stats/name now update with actual crown layers")
	await capture("crown_body_suppressed_native")
	var suppressed_hp:int=caster.hp
	game.update4_active_run.upper_floor.crown_suppressed=false;hud._update_selected_unit_status()
	expect(hud.selected_unit_dynamic_labels.name.text.contains("왕관") and caster.hp==suppressed_hp and caster.max_hp>suppressed_hp,"native restored form/capacity labels without freeheal")
	await capture("crown_body_restored_native")
	game.combat_scene.set_speed(3);game._open_pause_menu()
	var before:Dictionary=body(caster);await settle()
	expect(game.combat_paused and body(caster)==before,"menu freezes existingbody/timers")
	game._close_pause_menu();expect(game.combat_speed==3,"menu restores x3")
	var payload:String=JSON.stringify(game._campaign_save_payload("battle_start"))
	expect(not payload.contains("crown_base_body") and not payload.contains("crown_body_descriptor"),"safe checkpoint excludes actor body-layer caches")
	game.queue_free();await settle()
func callback_and_reuse()->void:
	await fixture("crown_pudding_royal_bastion")
	var original_frames:SpriteFrames=caster.sprite.sprite_frames
	var signals:Array=[]
	caster.hp_changed.connect(func(unit):
		signals.append({"max_hp":unit.max_hp,"atk":unit.atk,"def":unit.effective_def(),"alive":unit.is_alive(),"outgoing":unit.outgoing_heal_amount(10),"incoming":unit.resolved_heal_amount(10)})
	)
	caster.hp=40;game.update4_active_run.upper_floor.crown_suppressed=true
	var suppressed_max:int=caster.max_hp
	expect(signals.size()==1 and signals[0].max_hp==suppressed_max,"HPsignal callback can requery body/alive/heal kernels without recursive emit")
	expect(caster.sprite_path==str(caster.crown_body_descriptor.base_sprite),"suppression restores existing pre-crown nativeart")
	game.update4_active_run.upper_floor.crown_suppressed=false
	var restored_max:int=caster.max_hp
	expect(caster.sprite.sprite_frames==original_frames,"currentbody restoration restores same cachednativecrown frames")
	# The existing root callback grants the first Pudding threshold shield and
	# emits one additional HP signal. This is a real passive, not recursion.
	expect(signals.size()==3 and caster.duo_barrier==roundi(restored_max*.15),"reactivation root HPcallback applies first real15%shield once")
	var shield:int=caster.duo_barrier;game.update4_active_run.upper_floor.crown_suppressed=true
	var ignored:int=caster.max_hp;game.update4_active_run.upper_floor.crown_suppressed=false;ignored=caster.max_hp
	expect(caster.duo_barrier==shield and signals.size()==5,"repeatbodytoggle never grants duplicate threshold shield")
	caster.setup("goblin",DataRegistry.monster("goblin"),Constants.FACTION_ENEMY,"entrance")
	expect(caster.crown_base_body.is_empty() and caster.crown_body_descriptor.is_empty() and caster.max_hp==int(DataRegistry.monster("goblin").max_hp),"setup neutral reuse clears sourceowned crown caches")
	game.update4_active_run.upper_floor.crown_suppressed=true
	expect(caster.atk==int(DataRegistry.monster("goblin").atk) and caster.def==int(DataRegistry.monster("goblin").def),"enemy getter unaffected by former crown source")
	game.queue_free();await settle()
