extends "res://tools/tests/CrownMobilityRecoveryTest.gd"
func _ready()->void:
	get_tree().create_timer(300).timeout.connect(func():push_error("Echo objective fixture timeout");get_tree().quit(1))
	call_deferred("run")
func run()->void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"),"isolated native objective userdata")
	if not failures.is_empty():get_tree().quit(1);return
	DataRegistry.load_all();UISettings.reset_skill_cutscene_history(false)
	if OS.get_cmdline_user_args().has("--echo-ui"):
		await echo_ui()
		print("ECHO_OBJECTIVE_UI_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1);return
	for policy in ["off","once","once","always"]:
		await channel_case("dusk_courier",policy,2.0,4.0)
		await channel_case("rival_vesper_council_champion",policy,.7,5.0)
	await retry_case();await bag_cases();await shadow_case();await guards_case();await large_delta();await gold_case();await walking_and_drop();await stale_and_pause();await other_path_owner();await shadow_sources();await missing_and_cleanup();await automatic_and_generations()
	await echo_ui()
	var file:=FileAccess.open(output_dir+"/results.json",FileAccess.WRITE);file.store_string(JSON.stringify(proof,"\t"))
	print("ECHO_OBJECTIVE_RECOVERY_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
func native_fixture(policy:String="off",votes:int=10,seals:int=3)->void:
	await setup_case("bat_courier",policy)
	output_dir="res://tmp/echo_objective_recovery";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game.update4_active_run.campaign_mode_id=Modes.COUNCIL_MODE_ID
	game.update4_active_run.council_season={"council_votes":votes,"council_seals":seals}
	game.update4_active_run.crown={};game.update4_active_run.expansion={"crown_suppressed":true}
	for old in game.enemy_units:old.queue_free()
	game.enemy_units.clear();await settle()
	for actor in game.monster_units:actor.set_physics_process(false)
func spawn_native(id:String,anchor:bool=true)->Node:
	game.combat_scene.spawn_enemy(id)
	var actor=game.enemy_units[-1];actor.set_physics_process(false);actor.hp=10000;actor.max_hp=10000;actor.def=0
	if anchor:
		actor.global_position=game.graph.center(game.combat_scene._treasure_room());actor.current_room=game.combat_scene._treasure_room();actor.stop_navigation();actor.refresh_depth_slot()
	if id!="shadow_duelist":game.combat_scene.native_objectives.tick(0)
	return actor
func native_step(seconds:float)->void:
	game.combat_time+=seconds;game.combat_scene.native_objectives.tick(seconds)
func channel_case(id:String,policy:String,delay:float,duration:float)->void:
	await native_fixture(policy);var actor=spawn_native(id);var combat=game.combat_scene;var native=combat.native_objectives;var echo=combat.echo_alarm;var action=combat.skill_actions
	expect(native.channel_generation(actor)==1 and is_equal_approx(native._remaining(native.channels[actor.get_instance_id()]),duration),"actual native arrival starts full authored channel "+id)
	var start:float=game.combat_time;var seen:bool=UISettings.skill_cutscene_seen.has("skill:echo_alarm")
	if id=="rival_vesper_council_champion":
		var hp:int=actor.hp;actor.receive_damage(40)
		expect(hp-actor.hp==50 and native.channel_generation(actor)==1,"actual boss channel receives1.25 incoming damage without normal automatic retry")
	expect(request("echo_alarm"),"actual ordinary echo request "+id+policy)
	expect(action.is_active()==(policy=="always" or(policy=="once" and not seen)),"echo viewing policy")
	if action.is_active():
		expect(GameState.mana==500 and echo.credits.is_empty(),"prepared echo has no costs or delay")
		expect(action.actors[0].sprite_frames==caster.sprite.sprite_frames,"native echo actor frames")
		action.tick(.56);expect(action.caption.text.contains("지연예약"),"echo caption separates allocated delay")
		if policy=="always":await capture("echo_"+id+"_contact")
		action.skip();action.skip()
	for ally_actor in game.monster_units:ally_actor.set_physics_process(false)
	actor.set_physics_process(false)
	expect(GameState.mana==488 and is_equal_approx(float(caster.skill_cooldowns.echo_alarm),12),"authored mana12 and cooldown12 once")
	expect(is_equal_approx(echo.possible_delay(actor),0),"allocated cap reserved for channel")
	var duplicate:Dictionary=echo.prepare(caster);echo.cast(caster,duplicate)
	expect(is_equal_approx(float(caster.get_meta("echo_result").allocated_seconds),0),"duplicate same channel never refills credit")
	native_step(delay)
	expect(is_equal_approx(native._remaining(native.channels[actor.get_instance_id()]),duration),"actual delay consumed before channel")
	expect(is_equal_approx(float(echo.contributions[caster.get_instance_id()].echo_actual_delay_seconds),delay),"fractional actual delay telemetry")
	native_step(duration-.01);expect(native.losses.is_empty(),"no early real settlement")
	native_step(.011)
	expect(native.losses.size()==1 and int(game.update4_active_run.council_season.council_votes)==5,"one actual council vote debit5")
	expect(str(native.losses[0].status)=="held" and not native.pending_bag.is_empty(),"ordinary uncrowned carrier holds real loss")
	native_step(0);expect(native.losses.size()==1 and int(game.update4_active_run.council_season.council_votes)==5,"same completion no duplicate debit")
	proof.append({"actor":id,"policy":policy,"native_seconds":duration,"actual_delay_seconds":delay,"elapsed":game.combat_time-start,"loss":native.losses[0].duplicate(true),"progression":"forced council/native arrival; not natural earned campaign"})
	await dispose_case()
func retry_case()->void:
	await native_fixture();var actor=spawn_native("dusk_courier");var native=game.combat_scene.native_objectives;var echo=game.combat_scene.echo_alarm
	expect(request("echo_alarm"),"retry echo cast");actor.duo_barrier=100;var hp:int=actor.hp;actor.receive_damage(10)
	expect(actor.hp==hp and native.channel_generation(actor)==1,"fully absorbed hit never interrupts")
	actor.duo_barrier=0;actor.receive_damage(10)
	expect(actor.hp<hp and str(native.channels[actor.get_instance_id()].phase)=="retry" and echo.credits.is_empty(),"true HP damage enters retry and discards old delay")
	native_step(1.5)
	expect(native.channel_generation(actor)==2 and is_equal_approx(native._remaining(native.channels[actor.get_instance_id()]),3.5),"retry residual advances fresh channel only")
	native_step(3.5);expect(native.losses.size()==1,"retry actual channel settles once")
	await dispose_case()
func bag_cases()->void:
	for branch in ["","popo_royal_express","popo_seal_guard"]:
		await native_fixture();game.monster_roster.bat_courier.specialization_id=branch;var actor=spawn_native("dusk_courier");var native=game.combat_scene.native_objectives
		native_step(4);expect(not native.pending_bag.is_empty(),"first actual loss held "+branch)
		var expected:float=4 if branch=="popo_royal_express" else(7 if branch=="popo_seal_guard" else 5)
		expect(is_equal_approx(float(native.pending_bag.ends)-game.combat_time,expected),"authored bag recovery window "+branch)
		game.update4_active_run.council_season.council_votes=8
		native.manual_command(caster);caster.global_position=actor.global_position;caster.refresh_depth_slot();native_step(0)
		expect(native.pending_bag.is_empty() and int(game.update4_active_run.council_season.council_votes)==13 and str(native.losses[0].status)=="recovered","physical manual arrival refunds exact5 into current stock")
		native_step(10);expect(int(game.update4_active_run.council_season.council_votes)==13,"no repeated refund or timeout debit")
		await dispose_case()
	await native_fixture("off",4,2);var actor=spawn_native("dusk_courier");var native=game.combat_scene.native_objectives
	native_step(4);expect(int(game.update4_active_run.council_season.council_seals)==1 and int(native.losses[0].amount)==1,"native low votes debits actual seal1")
	native_step(5);expect(native.pending_bag.is_empty() and str(native.losses[0].status)=="final" and int(game.update4_active_run.council_season.council_seals)==1,"timeout finalizes existing debit without extra loss")
	await dispose_case()
func shadow_case()->void:
	await native_fixture();var actor=spawn_native("shadow_duelist",false);var native=game.combat_scene.native_objectives
	actor.global_position=caster.global_position+Vector2(120,0);actor.current_room="entrance";actor.def=20;caster.action_direction=Vector2.RIGHT;ally.global_position=game.graph.center("recovery")
	native.tick(0)
	expect(native.concealed(actor) and actor.global_position.distance_to(caster.global_position-Vector2(90,0))<.1,"real shadow safe behind90 ambush")
	expect(actor.effective_atk()==roundi(actor.atk*1.2) and actor.effective_def()==15,"real normal damage kernel consumes temporary ATKDEF")
	expect(not actor.is_targetable_by(caster) and actor.modulate.a<.2,"conceal rejects direct target with silhouette")
	expect(game.combat_scene.TargetingService.nearest(caster,[actor])==null,"central nearest rejects hidden actor")
	expect(game._prepared_duo_action_target("link_molten_carapace",[caster,ally])==null,"duo preparation cannot use unseen direct target")
	expect(not game._commit_prepared_duo("link_molten_carapace",[caster,ally],actor,actor.get_instance_id()),"duo contact rejects now hidden direct target")
	var hp:int=actor.hp;var impact:Dictionary=game.combat_scene._perform_standard_attack(caster,actor)
	expect(not bool(impact.get("applied",false)) and actor.hp==hp,"direct normal attack never hits unseen target")
	var beetle=game._create_unit("armored_beetle",DataRegistry.monster("armored_beetle"),Constants.FACTION_MONSTER,"entrance");beetle.global_position=caster.global_position;beetle.set_physics_process(false);game.monster_units.append(beetle)
	expect(game.combat_scene._toktok_ram_target(beetle)==null and not game.combat_scene._try_toktok_auto_skill(beetle,"carapace_ram",actor),"automatic specialist cannot prepare direct hidden ram target")
	expect(not bool(game.combat_scene.perform_toktok_carapace_ram(beetle,actor).get("ok",false)) and actor.hp==hp,"direct ram helper revalidates requested target while physical collisions stay allowed")
	actor.duo_barrier=100;actor.receive_damage(10);expect(native.concealed(actor),"shield-only contact never ends conceal")
	expect(request("echo_alarm") and actor.is_targetable_by(caster) and actor.modulate.a==1,"actual echo reveals hidden actor and restores alpha")
	native_step(2.01);expect(actor.effective_atk()==actor.atk and actor.effective_def()==20,"temporary ambush stats expire")
	await dispose_case()
func large_delta()->void:
	for id in ["dusk_courier","rival_vesper_council_champion"]:
		await native_fixture();var actor=spawn_native(id);var native=game.combat_scene.native_objectives
		var duration:float=4 if id=="dusk_courier" else 5
		native_step(duration-1);native_step(6)
		expect(is_equal_approx(float(native.losses[0].completed_at),duration),"large delta actual completion timestamp "+id)
		expect(native.pending_bag.is_empty() and str(native.losses[0].status)=="final","large delta already expired bag never receives fresh window "+id)
		expect(int(game.update4_active_run.council_season.council_votes)==5,"large delta debits only once "+id)
		await dispose_case()
	await native_fixture();var actor=spawn_native("dusk_courier");var native=game.combat_scene.native_objectives
	request("echo_alarm");native_step(11)
	expect(is_equal_approx(float(native.losses[0].completed_at),6) and native.pending_bag.is_empty(),"large delta includes consumed echo delay and correct expired hold")
	await dispose_case()
func gold_case()->void:
	await native_fixture();var actor=spawn_native("thief");var combat=game.combat_scene;var native=combat.native_objectives;var echo=combat.echo_alarm
	actor.goal_room=combat._treasure_room();actor.current_room=actor.goal_room;game.thief_steal_timers.clear()
	var gold:int=GameState.gold
	expect(native.gold_active(actor) and request("echo_alarm"),"actual first legacy gold channel eligible before sync")
	game.combat_time+=2;combat.update_room_effects(2)
	expect(is_equal_approx(float(game.thief_steal_timers[actor]),0) and is_equal_approx(float(echo.contributions[caster.get_instance_id()].echo_actual_delay_seconds),2),"gold exact delay consumes before real loot progress")
	ally.current_room=actor.current_room;ally.global_position=actor.global_position
	game.combat_time+=3;combat.update_room_effects(3)
	expect(float(game.thief_steal_timers[actor])==0 and GameState.gold==gold,"actual thief-hunter contest freezes gold clock")
	ally.current_room="entrance";ally.global_position=game.graph.center("entrance")
	game.combat_time+=4.99;combat.update_room_effects(4.99)
	expect(GameState.gold==gold,"legacy delayed gold never settles early")
	game.combat_time+=.02;combat.update_room_effects(.02)
	expect(GameState.gold==maxi(0,gold-100) and float(game.thief_steal_timers[actor])==-999 and not native.gold_active(actor),"real gold debit/sentinel preserved; no council bag")
	expect(native.losses.is_empty() and native.pending_bag.is_empty(),"gold adapter cannot claim council escrow")
	await dispose_case()
func walking_and_drop()->void:
	await native_fixture();var actor=spawn_native("dusk_courier",false);var native=game.combat_scene.native_objectives
	var origin:Vector2=actor.global_position;var moved:=false
	for i in range(1000):
		actor._physics_process(.02);game.combat_time+=.02;native.tick(.02);native.behavior(actor)
		if actor.global_position!=origin:moved=true
		if native.channel_generation(actor)>=0:break
	expect(moved and native.channel_generation(actor)>=0,"actual spawned native courier walks existing graph to channel")
	caster.global_position=actor.global_position-Vector2(70,0);caster.current_room=actor.current_room;caster.stop_navigation()
	native_step(4);var original_end:float=float(native.pending_bag.ends)
	actor.receive_damage(20000)
	expect(bool(native.pending_bag.drop) and not actor.is_alive() and is_equal_approx(float(native.pending_bag.ends),original_end),"actual fatal HP drops envelope at last position without extending deadline")
	var walked:=false;origin=caster.global_position
	for i in range(250):
		native.bag_navigation(caster);caster._physics_process(.02);game.combat_time+=.02;native.tick(.02)
		if caster.global_position!=origin:walked=true
		if native.pending_bag.is_empty():break
	expect(walked and str(native.losses[0].status)=="recovered" and int(game.update4_active_run.council_season.council_votes)==10,"actual walk to dropped envelope recovers exactly once")
	await dispose_case()
func stale_and_pause()->void:
	await native_fixture("always");var actor=spawn_native("dusk_courier");var combat=game.combat_scene;var native=combat.native_objectives
	expect(request("echo_alarm"),"stale prepared alarm starts native cutscene")
	actor.receive_damage(10);combat.skill_actions.skip()
	expect(GameState.mana==488 and combat.echo_alarm.credits.is_empty(),"manual stale channel gives warning only without new-generation delay")
	var before:float=game.combat_time;var retry:float=float(native.channels[actor.get_instance_id()].state.retry_remaining)
	game._open_pause_menu();combat.physics_process(.8)
	expect(game.combat_time==before and float(native.channels[actor.get_instance_id()].state.retry_remaining)==retry,"menu suspends actual native retry and clock")
	game._close_pause_menu();game.story_feature_enabled=false;combat.set_speed(3)
	for unit in game.monster_units:unit.set_skill_cooldown("echo_alarm",100);unit.set_skill_cooldown("night_relay",100)
	for unit in game.monster_units+game.enemy_units:unit.attack_cooldown=100
	combat.physics_process(.1)
	expect(is_equal_approx(game.combat_time-before,.3) and is_equal_approx(float(native.channels[actor.get_instance_id()].state.retry_remaining),retry-.3),"real controller speed3 advances native timer once")
	await dispose_case()
func other_path_owner()->void:
	for mode in ["recovery","timeout"]:
		await native_fixture();var actor=spawn_native("dusk_courier");var combat=game.combat_scene;var native=combat.native_objectives
		native_step(4);native.bag_navigation(caster)
		var target=outsider;target.hp=maxi(1,int(target.max_hp*.2))
		expect(combat.single_floor_support.begin_relay(caster,target,DataRegistry.skill("night_relay")),"real ordinary relay accepts while envelope held")
		var path:Array=caster.path_points.duplicate()
		if mode=="recovery":caster.global_position=actor.global_position;caster.current_room=actor.current_room;native_step(0)
		else:native_step(5)
		expect(combat.single_floor_support.relays.has(caster.get_instance_id()) and caster.path_points==path,"bag "+mode+" preserves other actual movement owner path")
		await dispose_case()
func shadow_sources()->void:
	await native_fixture();var actor=spawn_native("shadow_duelist",false);var native=game.combat_scene.native_objectives
	actor.global_position=caster.global_position+Vector2(120,0);actor.current_room="entrance";ally.current_room="recovery";ally.global_position=game.graph.center("recovery");native.tick(0)
	var position:Vector2=actor.global_position;native.tick(0);expect(actor.global_position==position and int(native.metrics.native_1f_shadow_promises)==1,"native shadow actual blink once only")
	var dog=game._create_unit("graveyard_hound",DataRegistry.monster("graveyard_hound"),Constants.FACTION_MONSTER,"entrance");dog.set_physics_process(false);game.monster_units.append(dog)
	dog.global_position=caster.global_position
	expect(game.combat_scene._danger_tracker_target(dog)==actor,"actual Koko detects hidden intruder in its assigned room")
	expect(game.combat_scene._try_koko_auto_skill(dog,"scent_lock",actor),"actual scent lock produces source-owned hidden detection")
	expect(actor.is_targetable_by(dog) and not actor.is_targetable_by(caster),"only actual Koko source scent observer can see hidden target")
	dog.scent_mark_timer=0
	expect(not actor.is_targetable_by(dog),"expired scent source does not grant lasting detection")
	actor.global_position=game.graph.center(game.combat_scene._core_room());actor.current_room=game.combat_scene._core_room()
	expect(game.combat_scene._danger_tracker_target(dog)==actor,"actual scent acquisition also detects sole hidden core intruder")
	var hp:int=actor.hp;actor.receive_magic_damage(10)
	expect(actor.hp<hp and not native.concealed(actor) and actor.modulate.a==1,"actual magic HP damage ends conceal with unchanged body visibility")
	await dispose_case()
func missing_and_cleanup()->void:
	await native_fixture();var first=spawn_native("dusk_courier");var other=spawn_native("rival_vesper_council_champion");var native=game.combat_scene.native_objectives
	native_step(5)
	expect(native.losses.size()==1 and int(game.update4_active_run.council_season.council_votes)==5,"two native actors share one actual battle loss cap")
	native.before_result()
	expect(native.pending_bag.is_empty() and str(native.losses[0].status)=="final" and str(game.update4_active_run.run_metrics_update4.native_1f_objectives.losses[0].status)=="final","result metrics finalize escrow before campaign snapshot")
	var before:int=int(game.update4_active_run.council_season.council_votes);native.clear();game.combat_scene.echo_alarm.clear()
	expect(int(game.update4_active_run.council_season.council_votes)==before and native.channels.is_empty() and native.losses.is_empty(),"battle clear never re-debits persistent council resources")
	await dispose_case()
	await native_fixture();first=spawn_native("dusk_courier");native=game.combat_scene.native_objectives
	native_step(4);first.escaped=true;first.hp=0;first.down=true;native_step(0)
	expect(native.pending_bag.is_empty() and str(native.losses[0].status)=="final","actual escape cannot receive killed-courier drop refund")
	await dispose_case()
func echo_ui()->void:
	await native_fixture("always");var actor=spawn_native("dusk_courier");var combat=game.combat_scene;var hud=combat.hud
	output_dir+="_touch" if UISettings.is_touch_ui() else "_desktop";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	hud._update_selected_unit_status();hud._update_manual_skill_controls()
	expect(hud.manual_skill_controls.skills.has("echo_alarm"),"actual ordinary inspector exposes connected echo button")
	var button:Button=hud.manual_skill_controls.skills.echo_alarm
	expect(game._combat_ui_at(button.get_global_transform_with_canvas()*(button.size*.5)),"actual echo button owns its pointer bounds")
	game._open_pause_menu();hud._request_manual_skill(caster,"echo_alarm")
	expect(not combat.skill_actions.is_active() and GameState.mana==500,"menu guards actual echo UI callback")
	game._close_pause_menu();hud._update_manual_skill_controls();await click(button,button.size*.5)
	expect(combat.skill_actions.is_active() and GameState.mana==500,"actual screen button starts presentation before cost")
	var inspector=game.ui_layer.find_child("CombatUnitInspector",true,false)
	expect(is_instance_valid(inspector) and not inspector.is_visible_in_tree(),"presentation hides the actual inspector without hiding menu controls")
	combat.skill_actions.stage.advance=Callable()
	combat.skill_actions.tick(.56);await capture("echo_manual_contact")
	var skip_button= combat.skill_actions.stage.find_child("SkillActionSkipButton",true,false)
	await click(skip_button,skip_button.size*.5)
	expect(not combat.skill_actions.is_active() and inspector.is_visible_in_tree(),"actual pointer Skip ends action and restores inspector")
	expect(GameState.mana==488 and combat.echo_alarm.revealed(actor),"clicked echo delivers real warning and authored cost")
	game._select_unit(actor);hud._update_selected_unit_status();await capture("echo_native_channel_status")
	expect(hud._combat_unit_status_text(actor,true).contains("수거") and hud._combat_unit_status_text(actor,true).contains("메아리"),"actual enemy status exposes channel and warning independently")
	await dispose_case()
func automatic_and_generations()->void:
	await native_fixture();var actor=spawn_native("dusk_courier");var combat=game.combat_scene;var native=combat.native_objectives;var echo=combat.echo_alarm
	expect(request("echo_alarm",true) and GameState.mana==488 and echo.possible_delay(actor)==0,"actual automatic control category commits useful echo once")
	caster.set_skill_cooldown("echo_alarm",0)
	expect(not request("echo_alarm",true) and GameState.mana==488,"already reserved warning cannot waste automatic echo cost")
	await dispose_case()
	await native_fixture();actor=spawn_native("thief");combat=game.combat_scene;native=combat.native_objectives;echo=combat.echo_alarm
	actor.goal_room=combat._treasure_room();actor.current_room=actor.goal_room;native.tick(0)
	expect(request("echo_alarm"),"gold initial actual alarm generation")
	var old:int=native.channel_generation(actor);actor.global_position=game.graph.center("entrance");actor.current_room="entrance";native.tick(0)
	expect(echo.credits.is_empty() and native.channel_generation(actor)==-1,"leaving real gold room discards old channel credit")
	actor.global_position=game.graph.center(combat._treasure_room());actor.current_room=combat._treasure_room();native.tick(0)
	expect(native.channel_generation(actor)>old and is_equal_approx(echo.possible_delay(actor),2),"actual gold reentry opens new limited generation budget")
	await dispose_case()
func guards_case()->void:
	await native_fixture("off",0,0);var actor=spawn_native("dusk_courier");var native=game.combat_scene.native_objectives
	expect(native.channels.is_empty() and actor.goal_room==game.combat_scene._core_room(),"zero council stock cannot create fake loss goal")
	await dispose_case()
