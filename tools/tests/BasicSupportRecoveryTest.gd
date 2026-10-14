extends "res://tools/tests/SkillRuntimeConnectionTest.gd"

var proof: Array=[]

func run()->void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"),"isolated recovery data")
	if not failures.is_empty():get_tree().quit(1);return
	DataRegistry.load_all();UISettings.reset_skill_cutscene_history(false)
	for policy in ["off","once","once","always"]:
		await thread_case(policy,false)
		await relay_case(policy,false)
	await thread_case("always",true)
	await relay_case("always",true)
	await guards_case()
	await branches_and_live_fire()
	await menu_travel()
	await defined_crowns()
	var file:=FileAccess.open("res://tmp/basic_support_recovery/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(proof,"\t"))
	print("BASIC_SUPPORT_RECOVERY_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func fixture(species:String,policy:String)->void:
	await setup_case(species,policy)
	output_dir="res://tmp/basic_support_recovery"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))

func cast(slot:int,automatic:bool,label:String)->bool:
	var combat=game.combat_scene;var action=combat.skill_actions
	var id:String=str(combat.skill_slots_for(caster)[slot])
	var seen:bool=UISettings.skill_cutscene_seen.has("skill:"+id)
	for other in combat.skill_slots_for(caster):
		if other!=null and str(other)!=id:caster.set_skill_cooldown(str(other),100)
	var accepted:bool=combat.try_auto_monster_skill(caster) if automatic else combat.request_selected_skill(slot)
	expect(accepted,label+" real request accepted")
	var shown:bool=UISettings.skill_cutscene_policy=="always" or(UISettings.skill_cutscene_policy=="once" and not seen)
	expect(action.is_active()==shown,label+" policy respected")
	if action.is_active():
		expect(GameState.mana==500,label+" cost waits for contact")
		expect(action.actors[0].sprite_frames==caster.sprite.sprite_frames,label+" native current appearance")
		action.tick(.4);await capture(label+"_prepare")
		action.tick(.16);await capture(label+"_contact")
		action.skip();action.skip()
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
	return accepted

func thread_case(policy:String,automatic:bool)->void:
	await fixture("spider_tailor",policy)
	var runtime=game.combat_scene.single_floor_support
	var anchor:Dictionary=runtime.thread_anchor(caster)
	expect(not anchor.is_empty(),"actual connected walkable threshold exists")
	if anchor.is_empty():
		print("ANCHOR_DIAG ",game.graph.connection_pairs(),game.graph.debug_socket_cells(),caster.global_position)
		game.queue_free();await settle();return
	if not await cast(0,automatic,"stitch_"+policy+("_auto" if automatic else "_manual")):
		game.queue_free();await settle();return
	expect(GameState.mana==488 and caster.skill_cooldowns.stitch_stairway==11.0,"thread mana12/CD11 once")
	expect(runtime.thread_active(),"actual installed trap")
	var axis:Vector2=(anchor.b-anchor.a).normalized()
	var across:=Vector2(-axis.y,axis.x)
	var start:Vector2=anchor.point-across*12
	var end:Vector2=anchor.point+across*12
	if not game.graph.is_walkable(start) or not game.graph.is_walkable(end):
		start=anchor.point+across*12;end=anchor.point-across*12
	expect(game.graph.is_walkable(start) and game.graph.is_walkable(end),"crossing route uses real floor")
	var hit_count:=0
	for index in range(5):
		var crossing=game._create_unit("explorer",DataRegistry.enemy("explorer"),Constants.FACTION_ENEMY,"entrance")
		crossing.set_physics_process(false);game.enemy_units.append(crossing)
		crossing.global_position=start;runtime.tick_thread()
		crossing.set_path([end])
		for tick in range(60):
			crossing._physics_process(1.0/60.0);runtime.tick_thread()
			if crossing.slow_timer>0:break
		var slowed:bool=crossing.slow_timer>0
		expect(slowed==(index<4),"first four unique actual crossings only")
		if slowed:
			hit_count+=1
			expect(is_equal_approx(crossing.slow_factor,.65),"actual move factor.65")
			var remaining:int=int(runtime.thread.state.thread.remaining_targets)
			crossing.global_position=end;runtime.tick_thread();crossing.global_position=start;runtime.tick_thread()
			expect(int(runtime.thread.state.thread.remaining_targets)==remaining,"same enemy recross consumes no new target")
			crossing._physics_process(4.01)
			expect(crossing.slow_factor==1.0,"slow expires independently")
	expect(hit_count==4 and not runtime.thread_active(),"fourth actual passage consumes trap")
	proof.append({"skill":"stitch_stairway","policy":policy,"auto":automatic,"actual_crossings":hit_count,"mana":GameState.mana,"fire_semantics":"typed actual contact/room field; each event once"})
	game.queue_free();await settle()

func relay_case(policy:String,automatic:bool)->void:
	await fixture("bat_courier",policy)
	var runtime=game.combat_scene.single_floor_support
	ally.global_position=game.graph.center("recovery");ally.current_room="recovery"
	enemy.global_position=ally.global_position+Vector2(8,0);enemy.current_room="recovery"
	var target:Dictionary=runtime.relay_target(caster)
	expect(not target.is_empty(),"reachable threatened ally in another actual room")
	if target.is_empty():game.queue_free();await settle();return
	if not await cast(0,automatic,"relay_"+policy+("_auto" if automatic else "_manual")):
		game.queue_free();await settle();return
	expect(GameState.mana==490 and caster.skill_cooldowns.night_relay==8.0,"relay mana10/CD8 once")
	expect(caster.night_relay_buffs.is_empty() and ally.night_relay_buffs.is_empty(),"no buff before actual arrival")
	var initial:Vector2=caster.global_position
	var mana_before:int=GameState.mana
	var route_size:int=caster.path_points.size()
	combat_attack_probe(caster)
	expect(caster.path_points.size()==route_size and caster.attack_cooldown==0.0,"delivery owns navigation beside an in-range enemy")
	var ticks:=0
	while runtime.relays.has(caster.get_instance_id()) and ticks<1800:
		caster._physics_process(1.0/60.0)
		runtime.update_relay(caster,1.0/60.0);ticks+=1
	expect(int(caster.get_meta("night_relay_arrivals",0))==1,"one actual path arrival")
	expect(caster.global_position!=initial and caster.global_position.distance_to(ally.global_position)<=12.01,"real displacement reaches recipient")
	game.combat_scene.refresh_unit_rooms()
	expect(caster.current_room==ally.current_room,"arrived room derives from actual graph position")
	expect(GameState.mana==mana_before,"walking and arrival do not pay twice")
	expect(is_equal_approx(caster.night_relay_move_multiplier,1.15) and is_equal_approx(ally.night_relay_move_multiplier,1.15),"both actual movement1.15")
	expect(is_equal_approx(caster.effective_attack_interval(),caster.attack_interval*.9),"real attack interval.90")
	await capture("relay_"+policy+("_auto" if automatic else "_manual")+"_arrived")
	caster._physics_process(5.01);ally._physics_process(5.01)
	expect(caster.night_relay_buffs.is_empty() and ally.night_relay_buffs.is_empty(),"both5second buffs expire")
	expect(caster.effective_move_speed()==caster.move_speed and caster.effective_attack_interval()==caster.attack_interval,"base values restored")
	proof.append({"skill":"night_relay","policy":policy,"auto":automatic,"arrival_frames":ticks,"distance_moved":initial.distance_to(caster.global_position),"mana":GameState.mana,"move":1.15,"attack_interval":.9})
	game.queue_free();await settle()

func combat_attack_probe(unit)->void:
	enemy.global_position=unit.global_position+Vector2(8,0)
	game.combat_scene.try_attack(unit,game.enemy_units)

func branches_and_live_fire()->void:
	for spec in ["silky_stair_warden","silky_field_tailor"]:
		await fixture("spider_tailor","always")
		game.monster_roster.spider_tailor.specialization_id=spec
		expect(game.combat_scene.request_selected_skill(0),"thread branch real request "+spec)
		expect(game.combat_scene.skill_actions.actors[0].sprite_frames==caster.sprite.sprite_frames,"thread branch current frames")
		game.combat_scene.skill_actions.skip()
		var runtime=game.combat_scene.single_floor_support
		expect(int(runtime.thread.state.thread.remaining_targets)==(3 if spec=="silky_field_tailor" else 4),"branch trap target count")
		expect(is_equal_approx(float(runtime.thread.state.thread.slow_multiplier),.60 if spec=="silky_stair_warden" else .65),"branch trap slow")
		expect(int(runtime.thread.state.thread.fire_durability)==(3 if spec=="silky_stair_warden" else 2),"branch trap fire durability")
		game.queue_free();await settle()
	for spec in ["popo_royal_express","popo_seal_guard"]:
		await fixture("bat_courier","always")
		game.monster_roster.bat_courier.specialization_id=spec
		ally.global_position=game.graph.center("recovery");ally.current_room="recovery";enemy.current_room="recovery"
		expect(game.combat_scene.request_selected_skill(0),"relay branch real request "+spec)
		game.combat_scene.skill_actions.skip()
		var runtime=game.combat_scene.single_floor_support
		var ticks:=0
		while runtime.relays.has(caster.get_instance_id()) and ticks<1800:
			caster._physics_process(1.0/60);runtime.update_relay(caster,1.0/60);ticks+=1
		expect(int(caster.get_meta("night_relay_arrivals",0))==1,"branch real arrival")
		expect(is_equal_approx(ally.night_relay_move_multiplier,1.20 if spec=="popo_royal_express" else 1.10),"branch real movement")
		expect(is_equal_approx(ally.night_relay_attack_multiplier,.86 if spec=="popo_royal_express" else .90),"branch real attack interval")
		game.queue_free();await settle()
	await fixture("spider_tailor","off")
	var combat=game.combat_scene
	caster.global_position=game.graph.center("spike_corridor");caster.current_room="spike_corridor"
	expect(combat.request_selected_skill(0),"live fire thread installed")
	var runtime=combat.single_floor_support;var anchor:Dictionary=runtime.thread.anchor
	var across:=Vector2(-(anchor.b-anchor.a).normalized().y,(anchor.b-anchor.a).normalized().x)
	outsider.global_position=anchor.point-across*12;enemy.global_position=anchor.point+across*12
	var hp_before:int=enemy.hp
	combat._launch_damage_projectile(outsider,enemy,17,false,"fireball")
	enemy.global_position=outsider.global_position
	await get_tree().create_timer(.5).timeout
	expect(enemy.hp<hp_before and int(runtime.thread.state.thread.fire_durability)==1,"actual projectile frozen trajectory burns thread once despite target moving back")
	outsider.current_room="spike_corridor";outsider.skill_cooldowns.clear();game.selected_unit=outsider
	enemy.current_room="spike_corridor"
	expect(combat.request_selected_skill(1),"actual flame zone cast")
	expect(not runtime.thread_active(),"actual flame zone room event burns second durability")
	game.queue_free();await settle()

func menu_travel()->void:
	await fixture("bat_courier","always")
	var combat=game.combat_scene;var runtime=combat.single_floor_support
	ally.global_position=game.graph.center("recovery");ally.current_room="recovery";enemy.current_room="recovery"
	combat.set_speed(3.0)
	expect(combat.request_selected_skill(0),"x3 relay preparation")
	game._open_pause_menu()
	expect(GameState.mana==490 and runtime.relays.size()==1,"menu interrupts preparation into one committed travel")
	expect(game.combat_paused and combat.requested_pause,"menu owns pause while travel waits")
	var position:Vector2=caster.global_position
	await settle()
	expect(caster.global_position==position and caster.night_relay_buffs.is_empty(),"paused menu gives no movement or fake delivery")
	game._close_pause_menu()
	expect(not game.combat_paused and game.combat_speed==3.0,"menu restores x3 travel")
	combat.abandon_suspended_frame()
	expect(runtime.relays.is_empty() and caster.path_points.is_empty(),"checkpoint/title clears pending delivery navigation")
	game.queue_free();await settle()

func guards_case()->void:
	await fixture("spider_tailor","off")
	var combat=game.combat_scene;var runtime=combat.single_floor_support
	expect(combat.request_selected_skill(0),"thread fire fixture placed")
	var a:Dictionary=runtime.thread.anchor
	runtime.fire_hit(a.point-Vector2(100,0),a.point+Vector2(100,0),[],"one")
	expect(int(runtime.thread.state.thread.fire_durability)==1 and runtime.thread_active(),"first actual intersecting fire hit")
	runtime.fire_hit(a.point-Vector2(100,0),a.point+Vector2(100,0),[],"one")
	expect(int(runtime.thread.state.thread.fire_durability)==1,"same fire event cannot double hit")
	runtime.fire_hit(Vector2.ZERO,Vector2.ZERO,a.rooms,"two")
	expect(not runtime.thread_active(),"second fire room event removes thread")
	caster.skill_cooldowns.clear();GameState.mana=500
	UISettings.set_skill_cutscene_policy("always",false)
	expect(combat.request_selected_skill(0),"cancel preparation accepted")
	caster.hp=0;caster.down=true
	combat.skill_actions.interrupt("review_cancel")
	expect(GameState.mana==500 and not runtime.thread_active(),"invalid prepared caster before contact no cost/trap")
	game.queue_free();await settle()
	await fixture("bat_courier","off")
	combat=game.combat_scene;runtime=combat.single_floor_support
	ally.global_position=game.graph.center("recovery");ally.current_room="recovery";enemy.current_room="recovery"
	expect(combat.request_selected_skill(0),"target death travel fixture")
	ally.hp=0;ally.down=true;runtime.update_relay(caster,1.0/60)
	expect(runtime.relays.is_empty() and caster.night_relay_buffs.is_empty(),"target death cancels no invented arrival buff")
	expect(GameState.mana==490,"committed travel cancellation keeps authored cast cost")
	caster.apply_night_relay_buff("express",2,1.20,.86)
	caster.apply_night_relay_buff("normal",5,1.15,.9)
	caster._physics_process(2.01)
	expect(is_equal_approx(caster.night_relay_move_multiplier,1.15) and is_equal_approx(caster.night_relay_attack_multiplier,.9),"strong short buff expires without borrowing weaker lifetime")
	combat.abandon_suspended_frame()
	expect(runtime.relays.is_empty() and caster.night_relay_buffs.is_empty(),"title/abandon clears battle-only support state")
	game.queue_free();await settle()

func defined_crowns()->void:
	await fixture("slime","off")
	ally.max_hp=140;ally.hp=70
	ally.receive_damage(14)
	expect(ally.hp==56 and ally.duo_barrier==21,"actual threshold hit immediately grants Pudding barrier")
	ally.receive_damage(60)
	expect(ally.hp==17 and ally.is_alive(),"same-frame next hit consumes barrier before down")
	game.queue_free();await settle()
	await fixture("slime","off")
	ally.hp=roundi(ally.max_hp*.4)
	game.combat_scene._update_defined_crown_support()
	expect(ally.duo_barrier==roundi(ally.max_hp*.15),"real first40percent Pudding ally shield")
	ally.duo_barrier=0;game.combat_scene._update_defined_crown_support()
	expect(ally.duo_barrier==0,"same ally cannot rearm passive")
	caster.hp=floori(caster.max_hp*.4);game.combat_scene._update_defined_crown_support()
	expect(caster.duo_barrier==roundi(caster.max_hp*.15),"native self ally convention, own first trigger")
	game.update4_active_run.expansion.crown_suppressed=true
	outsider.current_room=caster.current_room;outsider.hp=1;game.combat_scene._update_defined_crown_support()
	expect(outsider.duo_barrier==0,"suppressed passive cannot trigger")
	game.queue_free();await settle()
	await fixture("spore_healer","off")
	game.update4_active_run.campaign_mode_id=Modes.COUNCIL_MODE_ID
	game.update4_active_run.crown={"crown_form_id":"crown_mori_grand_mycelial_priest","selected_instance_id":"mon_contract_mori"}
	game.update4_active_run.expansion={"crown_suppressed":false}
	var stats:Dictionary=game._scaled_monster_stats("spore_healer")
	caster.outgoing_healing_multiplier=float(stats.get("outgoing_healing_multiplier",1.0))
	ally.hp=1
	expect(game.combat_scene.request_selected_skill(0),"actual Mori healing skill")
	expect(ally.hp==51,"46x1.08 rounded50 actual HP gain")
	game.update4_active_run.expansion.crown_suppressed=true
	ally.hp=1;caster.skill_cooldowns.clear();GameState.mana=500
	expect(game.combat_scene.request_selected_skill(0),"suppressed Mori ordinary heal remains usable")
	expect(ally.hp==47,"suppressed current crown loses outgoing multiplier")
	game.update4_active_run.expansion.crown_suppressed=false
	ally.hp=1;caster.skill_cooldowns.clear();GameState.mana=500
	expect(game.combat_scene.request_selected_skill(0) and ally.hp==51,"reactivated Mori multiplier returns without rebuilding actor")
	game.queue_free();await settle()
