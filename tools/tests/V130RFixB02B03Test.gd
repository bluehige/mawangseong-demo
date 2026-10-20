extends Node
const Grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const Controller = preload("res://scripts/game/ApprovedBattleController.gd")
const Duo = preload("res://scripts/systems/duo_links/DuoLinkService.gd")
const Front = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const Heart = preload("res://scripts/systems/hearts/CastleHeartService.gd")
var game: Node
var checks := 0
var failures: Array = []
var evidence := {}
func _ready() -> void: run.call_deferred()
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("[B02/B03] "+label)
func frames(n: int = 3) -> void:
	for i in n: await get_tree().process_frame
func run() -> void:
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	ProjectSettings.set_setting("debug/start_flow14",true)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(game); await frames(8)
	game.campaign_save_enabled=false; game.campaign_autosave_pending=false
	game.story_feature_enabled=false; game.onboarding_enabled=false; game.tutorial_gate_enabled=false
	game.start_flow.fresh=false; game.start_flow.intro_complete=true; game.start_flow.guide_step=5; game.start_flow.command_seen=true
	await stat_parity()
	await crown_hunger_and_decree()
	await date_and_wave_paths()
	await council_start_and_records()
	await legacy_duos()
	await next_cycle()
	await finish()
func finish() -> void:
	evidence["checks"]=checks; evidence["failures"]=failures
	var file := FileAccess.open("res://tmp/v130r_b02_b03/checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"\t")); file.close()
	game.campaign_autosave_pending=false; game._shutdown_audio_for_exit()
	game.queue_free(); await frames(5)
	print("B02_B03_TEST: ","PASS" if failures.is_empty() else "FAIL"," (",checks," checks)")
	get_tree().quit(0 if failures.is_empty() else 1)



func current_view() -> Node: return game.ui_layer.get_node_or_null("ApprovedMapManagement")

func dismiss() -> void:
	for i in 200:
		await frames(1)
		if game.current_screen!="dialogue": return
		if game.story_director.is_active(): game._story_advance_dialogue()
		else: game._onboarding_advance_dialogue()
	expect(false,"dialogue can close")

func leave_battle() -> void:
	var v := current_view()
	if v!=null and v.battle!=null:
		game.start_flow.abandon_battle(v); v.battle=null
	game._clear_units()
	game.combat_scene._clear_active_combat_tweens()
	game._set_screen("title",false)
	await frames(3)

func fixture(day: int, council: bool = false) -> void:
	await leave_battle()
	game.update4_active_run = game.CampaignModeServiceScript.default_active_run()
	game.update3_active_run = Front.default_legacy_active_run(2)
	game.campaign_seen_day_intros.clear(); game.campaign_seen_combat_intros.clear()
	game.campaign_profile = game.NewCycleServiceScript.default_profile()
	game.next_defense_modifiers.clear(); game.wave_variant_ids.clear()
	game.completed_raids.clear(); game.campaign_completed=false; game.campaign_postgame_active=false
	game.campaign_final_battle_outcome=""; game.campaign_final_upgrade_ready=true
	game.campaign_stage_two_upgrade_funded=true; game.campaign_chapter_two_started=true
	game.onboarding_enabled=false; GameState.onboarding_complete=true
	game.tutorial_gate_enabled=false; game.tutorial_manager.active=false
	GameState.player_name="B02B03"
	GameState.day=day; GameState.max_day=30; GameState.gold=10000; GameState.mana=10000; GameState.food=30; GameState.infamy=10000
	GameState.defeat=false; GameState.victory=false; GameState.demon_lord_hp=1500; GameState.demon_lord_max_hp=1500
	game.monster_roster.clear()
	var members := Members.roster()
	for id in members:
		game.monster_roster[members[id].species_id] = {"level":1,"exp":0,"bond":50,"room":"entrance","defense_enabled":true,"unlocked_memory_ids":["fixture_memory"]}
	game.selected_contract_ids.assign(DataRegistry.update2_contracts.keys())
	game.deployed_instance_ids.assign(members.keys())
	GameState.food_state=GameState.Food.fresh(); GameState.food_state.owned=members.keys(); GameState.food_state.contracts=game.selected_contract_ids.duplicate()
	if council: game.update4_active_run["campaign_mode_id"]="council_season"
	Grade.reset_campaign_map(game)
	game._set_screen("management",false)
	await dismiss(); await frames(4)
	var v := current_view()
	if v!=null:
		v.monster_ui.unlock_all=true
		v.monster_ui.assignments=Members.auto_place(v.placement,members,members.keys(),999)
		# Fill unused valid cells without changing the production auto-placement policy.
		for id in members:
			if v.monster_ui.assignments.has(id): continue
			var placed := false
			for building in v.placement.defense_points:
				for slot in v.placement.defense_points[building].size():
					var target := {"building":building,"slot":slot}
					if Members.occupant(v.monster_ui.assignments,target)=="":
						v.monster_ui.assignments[id]=target; placed=true; break
				if placed: break

		Grade.stash(game,v.placement,v.monster_ui.assignments)

func begin_direct() -> RefCounted:
	var v := current_view()
	expect(v!=null,"Approved management exists before spatial battle")
	if v==null: return null
	var b := Controller.new(); v.battle=b; b.begin(v)
	v.monster_ui.set_mode("battle"); v.monster_ui.unit_layer.hide(); v.show_battle_controls()
	v.set_physics_process(false)
	for unit in game.monster_units+game.enemy_units: unit.set_physics_process(false)
	return b

func numeric(unit: Node) -> Dictionary:
	return {"hp":unit.max_hp,"atk":unit.atk,"def":unit.def,"speed":unit.move_speed,"range":unit.attack_range,"interval":unit.attack_interval,"healing":unit.outgoing_healing_multiplier,"heart_def":unit.heart_def_bonus,"heart_healing":unit.heart_healing_multiplier,"heart_recovery":unit.heart_skill_recovery_multiplier}

func stat_parity() -> void:
	var comparisons: Array = []
	for level in [1,5,12]:
		await fixture(27)
		var old = game.combat_scene
		for species in game.monster_roster:
			var roster: Dictionary=game.monster_roster[species]
			roster.level=level; roster.exp=level*7
			if level>1:
				var specs: Array=game._specializations_for_monster(species)
				if not specs.is_empty(): roster["specialization_id"]=specs[0].id
				var promotions: Array=game._evolution_rules_for_monster(species)
				if not promotions.is_empty(): roster["promotion_id"]=promotions[0].id
				var focus: Dictionary=game._result_growth_preparation_rule(species)
				if not focus.is_empty(): roster["growth_preparation_day"]=GameState.day; roster["growth_preparation_id"]=focus.id
		game.campaign_profile["active_decree_id"]="decree_family_watch" if level>1 else ""
		game.campaign_profile["active_doctrine_id"]="royal_contract_registry" if level>1 else ""
		game.update3_active_run["heart"]={"heart_id":"heart_stonebone","awakened":true}
		game._prepare_update3_heart_battle()
		old.spawn_monsters()
		var expected := {}
		for unit in game.monster_units:
			unit.set_physics_process(false)
			game._update3_refresh_monster_heart_position(unit)
			expected[unit.unit_id]=numeric(unit)
		expect(expected.size()==24,"legacy spawn includes all 24 species at level "+str(level))
		game._clear_units(); await frames(2)
		var b := begin_direct()
		if b==null: continue
		expect(game.monster_units.size()==24,"Approved spawn includes all 24 species at level "+str(level))
		for unit in game.monster_units:
			var actual := numeric(unit)
			expect(expected.get(unit.unit_id,{})==actual,"legacy/Approved final stats "+unit.unit_id+" Lv"+str(level))
			comparisons.append({"species":unit.unit_id,"level":level,"legacy":expected.get(unit.unit_id,{}),"approved":actual})
		# A same-level preview never mutates EXP or growth choices.
		for species in game.monster_roster: expect(int(game.monster_roster[species].exp)==level*7,"EXP preserved "+species)
		await leave_battle()
	evidence["stat_comparisons"]=comparisons

func expected_schedule() -> Array:
	var manager := preload("res://scripts/combat/WaveManager.gd").new()
	manager.setup(GameState.day,game._active_wave_catalog(),game.combat_scene._precombat_defense_modifiers(true))
	return manager.schedule.duplicate(true)

func check_schedule(expected: Array, label: String) -> void:
	var actual: Array=game.wave_manager.schedule
	expect(actual.size()==expected.size(),label+" wave count")
	var remaining: Array=expected.duplicate(true)
	for entry in actual:
		var a: Dictionary=entry.duplicate(true); a.erase("time")
		var found := -1
		for i in remaining.size():
			var e: Dictionary=remaining[i].duplicate(true); e.erase("time")
			if a==e and absf(float(entry.time)-float(remaining[i].time))<=float(remaining[i].get("spawn_jitter",0))+.001:
				found=i; break
		expect(found>=0,label+" complete wave entry and bounded jitter")
		if found>=0: remaining.remove_at(found)
	expect(remaining.is_empty(),label+" no omitted or duplicated wave entries")

func date_and_wave_paths() -> void:
	var paths: Array=[]
	for front_id in [Front.HERO_FRONT_ID,Front.HOLY_FRONT_ID,Front.GUILD_FRONT_ID]:
		await fixture(14)
		game.update3_active_run["update3_enabled"]=true
		game.update3_active_run["front_id"]=front_id
		game.update3_active_run["heart"]={"heart_id":"heart_stonebone"}
		game.result_summary={"win":true}; game._advance_after_result()
		await dismiss(); await frames(4)
		# Intrusion preview is auxiliary; its existing back action returns to the map.
		if game.current_screen=="intrusion_brief": game._set_screen("management",false)
		expect(GameState.day==15 and int(Grade.load_session(game).layout.day)==15,front_id+" existing next-day pipeline synchronizes map")
		expect(Front.day_content_seen(game.update3_active_run,15),front_id+" front overlay entered")
		expect(bool(game.update3_active_run.heart.get("awakened",false)),front_id+" heart awakening entered")
		var schedule := expected_schedule()
		var b := begin_direct()
		if b!=null:
			check_schedule(schedule,front_id)
			# Tick the real existing enemy/heart runtimes on the Approved graph.
			var seen := {}
			for entry in schedule:
				if seen.has(entry.enemy_id): continue
				seen[entry.enemy_id]=true; b.spawn_enemy(entry.enemy_id,entry)
			for tick in 240:
				b.physics_process(.05)
				for unit in game.monster_units+game.enemy_units:
					if is_instance_valid(unit): unit.set_physics_process(false); unit._physics_process(.05)
				if tick%40==0: await frames(1)
			expect(b.running and game.combat_time>=12.0,front_id+" existing enemy runtimes tick on Approved map")

			b.spawn_enemy("investigator",{})
			expect(game.enemy_units[-1].first_heart_control_applied.is_connected(game._on_update3_first_control_applied),front_id+" shared heart signal")
		paths.append({"path":front_id,"day":GameState.day,"wave_count":schedule.size(),"flags":game.update3_active_run.get("front_flags",{}).duplicate(true)})
		await leave_battle()
	# Real expedition selection and settlement feed one-shot defense modifiers.
	await fixture(7)
	current_view().open_campaign_action("raid"); await frames(4)
	expect(game.current_screen=="raid","Approved ordinary expedition entry")
	game._ensure_raid_selection()
	# Use the authored first available mission when no such identifier exists.
	if DataRegistry.raid_mission(game.raid_selected_mission_id).is_empty(): game._ensure_raid_selection()
	for species in game.monster_roster:
		if game._can_start_selected_raid(): break
		game._toggle_raid_monster(species)
	expect(game._can_start_selected_raid(),"expedition party meets authored requirements")
	if game._can_start_selected_raid(): game._commit_selected_raid()
	await dismiss(); await frames(4)
	expect(not game.last_raid_result.is_empty(),"expedition settles real mission")
	game._set_screen("management",false); await frames(3)
	expect(current_view()!=null and current_view().placement.resources.gold==GameState.gold,"raid rewards survive Approved return")
	# The actual next-defense dictionary also tests consume-once semantics.
	game.next_defense_modifiers["b03_supply"]={"spawn_delay_bonus":5.0,"apply_on_day":7}
	var schedule := expected_schedule()
	var b := begin_direct()
	if b!=null:
		check_schedule(schedule,"expedition")
		expect(game.next_defense_modifiers.is_empty(),"one-shot expedition modifiers consumed")
	await leave_battle()
	# Council DAY16 must run its expansion and repair/day-state entry.
	await fixture(15)
	expect(int(Grade.load_session(game).layout.stage)==2,"DAY15 map initialization uses campaign stage two, not preview defaults")
	game.update4_active_run["campaign_mode_id"]="council_season"
	game.update4_active_run["council_season"]["selected_regions"]=["region_ironbell_ravine","region_moonbat_aerie"]
	game.result_summary={"win":true}; game._advance_after_result()
	await dismiss(); await frames(4)
	expect(GameState.day==16,"council existing next-day advancement")
	expect(bool(game.update4_active_run.get("expansion",{}).get("unlocked",false)),"council expansion unlocked by day entry")
	# Required choices are deliberately left pending: the Approved action must refuse combat.
	if current_view()!=null:
		expect(not current_view().start_battle(),"council required action blocks unprepared battle")
	# Inspect battle selection independently of the mandatory choice fixtures.
	game._set_screen("title",false)
	game.update4_active_run["campaign_mode_id"]="front_chronicle"
	game._set_screen("management",false); await frames(3)
	game.update4_active_run["campaign_mode_id"]="council_season"
	var v := current_view()
	if v!=null:
		v.monster_ui.unlock_all=true; v.monster_ui.assignments=Members.auto_place(v.placement,Members.roster(),Members.roster().keys(),999)
		var council_schedule := expected_schedule()
		b=begin_direct()
		if b!=null:
			check_schedule(council_schedule,"council templates")
			expect(game.update4_active_run.expansion.rooms.get("crown_sanctum","")=="recovery_nest","council objective resolves to real Approved facility")
			b.spawn_enemy("explorer",{})
			var enemy: Node=game.enemy_units[-1]
			expect(bool(enemy.get_meta("council_crown_target",false)),"council existing objective runtime selects invader")
			if enemy.get_meta("council_crown_target",false):
				enemy.position=b.map.center("recovery_nest"); enemy.attack_cooldown=0
				for unit in game.monster_units: unit.position=b.map.center("entrance")
				var before: int=game.update4_active_run.expansion.objective_hp.crown_sanctum
				b.refresh_unit_rooms()
				b.council_objectives.tick(.1)
				expect(int(game.update4_active_run.expansion.objective_hp.crown_sanctum)<before,"council objective takes real damage")
	paths.append({"path":"council","day":16})
	evidence["date_paths"]=paths
	await leave_battle()

func input_key(key: Key) -> void:
	var event := InputEventKey.new(); event.keycode=key; event.physical_keycode=key; event.pressed=true
	Input.parse_input_event(event); await frames(2)
	event=InputEventKey.new(); event.keycode=key; event.physical_keycode=key
	Input.parse_input_event(event); await frames(2)

func legacy_duos() -> void:
	var results: Array=[]
	var ids := ["link_spore_jelly_shelter","link_ghostly_evacuate","link_moon_scent_hunt","link_molten_carapace","link_stone_march","link_false_beacon_vault"]
	for id in ids:
		await fixture(27)
		game.update3_profile=Duo.unlock_fixture({},id,DataRegistry.update3_duo_links).profile
		game.update3_active_run["equipped_duo_links"]=[id]
		game.update3_active_run["duo_link_auto_use"]=false
		var b := begin_direct()
		if b==null: continue
		var center: Vector2=b.map.center("barracks")
		for unit in game.monster_units: unit.position=center+Vector2(20,0); unit.hp=unit.max_hp-30
		var partners: Array=[]
		for member_id in DataRegistry.update3_duo_links[id].member_instance_ids: partners.append(game._update3_duo_member_unit(member_id))
		partners[0].position=center; partners[1].position=center+Vector2(40,0)
		for enemy_id in ["explorer","explorer","explorer","explorer"]:
			b.spawn_enemy(enemy_id,{})
			var enemy: Node=game.enemy_units[-1]
			enemy.set_physics_process(false); enemy.max_hp=1000; enemy.hp=1000
			enemy.position=center+Vector2(60,0); enemy.morale=100
		game.enemy_units[-1].role="appraiser" # Authored role fixture; no appraiser enemy ID exists.
		var target: Node=game.enemy_units[0]
		target.apply_duo_mark(6.0,"fixture")
		b.refresh_unit_rooms()
		expect(not b.duos.activate(id),id+" uncharged blocked")
		var source: Dictionary=DataRegistry.update3_duo_links[id].gauge_sources[0]
		var gain: int=game._record_update3_duo_link_action(source.member_instance_id,source.source_id,source.threshold,"dedup:"+id)
		expect(gain>0 and game._record_update3_duo_link_action(source.member_instance_id,source.source_id,source.threshold,"dedup:"+id)==0,id+" charge deduplicates combat event")
		for gauge in DataRegistry.update3_duo_links[id].gauge_sources:
			for n in 40: game._record_update3_duo_link_action(gauge.member_instance_id,gauge.source_id,gauge.threshold,id+":"+gauge.source_id+":"+str(n))
		expect(int(game.update3_active_run.duo_link_states[id].charge)==100,id+" charge reaches 100")
		b.set_pause_state(true,false); expect(not b.duos.activate(id),id+" paused blocked")
		b.set_pause_state(false,false)
		partners[0].apply_duo_action_lock(.5); expect(not b.duos.activate(id),id+" partner action lock blocked"); partners[0].duo_action_lock_timer=0
		for unit in game.monster_units: unit.set_physics_process(false)
		var hp_before: int=target.hp
		var wounded: Node=game._update3_duo_member_unit("mon_contract_mori"); wounded.hp=10; wounded.apply_slow(3,.5)
		var wound_before: int=wounded.hp
		# Use the real map's J input, rather than calling any effect handler.
		await input_key(KEY_J)
		expect(bool(game.update3_active_run.duo_link_states[id].used_this_battle),id+" J input activates on Approved map")
		expect(b.duos.activations.size()==1,id+" exactly one recorded activation")
		await capture(id)
		match id:
			"link_spore_jelly_shelter":
				expect(wounded.duo_barrier>0 and wounded.hp>wound_before,id+" real shield and effective heal")
				expect(wounded.slow_timer<=0,id+" negative status cleansed")
			"link_ghostly_evacuate":
				expect(wounded.duo_redirect_target==partners[0],id+" rescue shares incoming damage")
				var protector_hp: int=partners[0].hp; wounded.receive_damage(4)
				expect(partners[0].hp<protector_hp,id+" redirected damage reaches protector")
			"link_moon_scent_hunt":
				expect(target.hp<hp_before and target.armor_break_amount==2,id+" marked target hit and armor broken")
				expect(partners[0].duo_damage_taken_multiplier>1,id+" authored vulnerability cost")
			"link_molten_carapace":
				expect(target.hp<hp_before and target.armor_break_amount>0,id+" real impact and armor break")
				var after: int=target.hp; b.duos.tick(1.1)
				expect(target.hp<after,id+" burn continues in Approved runtime")
			"link_stone_march":
				expect(target.hp<hp_before and target.morale<100,id+" HP and morale damage")
				expect(partners[0].duo_move_lock_timer>0,id+" authored movement lock cost")
			"link_false_beacon_vault":
				var effect: Dictionary=game.update3_active_run.duo_link_active_effects[-1]
				expect(effect.targets.size()==2,id+" lure limited to two normal enemies")
				expect(game.enemy_units[-1].duo_mark_timer>0,id+" appraiser immediately marked")
				b.duos.tick(3.1)
				expect(target.duo_mark_timer>0,id+" lure expiry applies mark and restores goal")
		expect(not b.duos.activate(id),id+" second use blocked")
		var missing: Dictionary=Duo.begin_battle({"equipped_duo_links":[id]},[DataRegistry.update3_duo_links[id].member_instance_ids[0]],DataRegistry.update3_duo_links)
		expect(not missing.duo_link_states[id].active,id+" absent partner disables link")
		partners[1].receive_damage(99999)
		expect(not game.update3_active_run.duo_link_states[id].active,id+" actual downed signal disables link")
		results.append({"id":id,"activations":b.duos.activations.duplicate(true),"state":game.update3_active_run.duo_link_states[id].duplicate(true)})
		await leave_battle()
	evidence["legacy_duos"]=results

func next_cycle() -> void:
	await fixture(29)
	var v := current_view()
	expect(v!=null and v.preparation_only(),"DAY29 remains preparation only")
	if v!=null:
		expect(not v.start_battle() and v.battle==null,"DAY29 cannot start battle")
		expect(not v.confirm_preparation_day(),"DAY29 declaration required before confirmation")
		game._set_campaign_final_declaration("castle_oath")
		await dismiss(); await frames(3)
		if current_view()==null: game._set_screen("management",false)
		v=current_view()
		expect(v.confirm_preparation_day(),"DAY29 existing preparation settles without combat")
		expect(game.current_screen=="result" and GameState.day==29,"DAY29 common preparation result")
		game._continue_from_result(); await dismiss(); await frames(3)
		expect(GameState.day==30 and int(Grade.load_session(game).layout.day)==30,"DAY29 result advances map to DAY30")
	await fixture(30)
	game.campaign_completed=true; game.campaign_final_battle_outcome="victory"
	game.result_summary={"win":true}
	var old := Grade.load_session(game)
	expect(old.layout.grade=="C" and not old.defenders.is_empty(),"next cycle starts from populated DAY30 C map fixture")
	game._show_campaign_ending(); await frames(3)
	var button: BaseButton=game.ui_layer.find_child("EndingNextCycleButton",true,false)
	expect(button!=null,"actual ending exposes next-cycle action")
	if button!=null: button.pressed.emit()
	await frames(4)
	var session := Grade.load_session(game)
	expect(game.current_screen==Constants.SCREEN_CAMPAIGN_MODE and GameState.day==4,"ending action enters mode choice at next-cycle DAY4")
	expect(session.layout.day==4 and session.layout.grade=="F" and session.defenders.is_empty(),"next cycle clears DAY30 map and defenders")
	expect(session.layout.resources.gold==GameState.gold,"next cycle initializes wallet from new run")
	expect(not game.inherited_legacy_monster.is_empty(),"legacy memory survives map reset")
	game._select_campaign_mode(game.CampaignModeServiceScript.FRONT_MODE_ID); await frames(3)
	expect(GameState.day==4 and Grade.load_session(game).layout.day==4,"front mode map starts DAY4")
	# Reopen the same newly-created mode choice to cover council's DAY1 boundary.
	game.update4_active_run=game.CampaignModeServiceScript.new_cycle_active_run()
	game.update4_profile.campaign_modes["council_season_unlocked"]=true
	game.update4_profile.campaign_modes["update3_any_front_cleared"]=true
	game._select_campaign_mode(game.CampaignModeServiceScript.COUNCIL_MODE_ID)
	await dismiss(); await frames(5)
	session=Grade.load_session(game)
	expect(GameState.day==1 and session.layout.day==1 and session.layout.grade=="F","council mode resets next-cycle map to DAY1")
	expect(session.defenders.is_empty(),"council next cycle retains no old defense assignments")
	await capture("next_cycle_council_day1")
	var snapshot: Dictionary=game.start_flow.snapshot()
	game.set_meta(Grade.SESSION,old)
	game.start_flow.restore(snapshot)
	expect(Grade.load_session(game).layout.day==1,"next-cycle snapshot restore cannot resurrect DAY30 map")
	evidence["new_cycle"]={"day":GameState.day,"grade":session.layout.grade,"legacy":game.inherited_legacy_monster.duplicate(true)}
	game._set_campaign_save_path_for_tests("user://b03_cycle_v1.json","user://b03_cycle_v2.json","user://b03_cycle_v3.json","user://b03_cycle_v4.json","user://b03_cycle_v5.json","user://b03_cycle_v6.json")
	game._set_screen("management",false); await dismiss(); await frames(3)
	game._schedule_campaign_autosave("management")
	var saved: bool=game._flush_campaign_autosave()
	expect(saved,"next-cycle disk save passes existing validation: "+game.campaign_save_error)
	if saved:
		game.campaign_autosave_pending=false; game._shutdown_audio_for_exit(); game.queue_free(); await frames(5)
		game=load("res://scenes/game/GameRoot.tscn").instantiate(); add_child(game); await frames(8)
		game._set_campaign_save_path_for_tests("user://b03_cycle_v1.json","user://b03_cycle_v2.json","user://b03_cycle_v3.json","user://b03_cycle_v4.json","user://b03_cycle_v5.json","user://b03_cycle_v6.json")
		game._continue_campaign_save(); await dismiss(); await frames(5)
		expect(GameState.day==1 and Grade.load_session(game).layout.day==1,"new GameRoot Continue restores next-cycle DAY1")
		expect(Grade.load_session(game).layout.grade=="F","Continue never restores previous C map")
		game.campaign_autosave_pending=false; game.campaign_save_enabled=false



func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/v130r_b02_b03/"+id+".png")

func crown_hunger_and_decree() -> void:
	var rows: Array=[]
	for crown_id in DataRegistry.update4_crown_evolutions:
		await fixture(27)
		var definition: Dictionary=DataRegistry.update4_crown_evolutions[crown_id]
		var species: String=definition.monster_id
		var instance_id: String=game.ContractRosterServiceScript.instance_id_for_species(species,DataRegistry.monster_instances)
		game.update4_active_run["campaign_mode_id"]="council_season"
		game.update4_active_run["crown"]={"crown_form_id":crown_id,"selected_instance_id":instance_id}
		game.monster_roster[species].level=12
		game.campaign_profile["active_decree_id"]="decree_rival_protocol"
		GameState.food_state.hungry=[species]
		current_view().placement.food_state=GameState.food_state.duplicate(true)
		var stats: Dictionary=game._monster_combat_stats(species)
		var old: Node=game._create_unit(species,stats,"monster","entrance")
		old.set_physics_process(false)
		var expected := numeric(old)
		old.queue_free(); await frames(1)
		var b := begin_direct()
		if b==null: continue
		var actual: Node=game._update3_duo_member_unit(instance_id)
		expect(actual!=null,crown_id+" crowned species is deployed")
		if actual!=null:
			expect(numeric(actual)==expected,crown_id+" final crown/decree/hunger stats match legacy")
			expect(actual.get_meta("food_hungry",false),crown_id+" hunger preserved")
			expect(not stats.get("crown_base_body",{}).is_empty(),crown_id+" preserves pre-crown layer")
			rows.append({"id":crown_id,"legacy":expected,"approved":numeric(actual)})
		await leave_battle()
	await fixture(7)
	game.campaign_cycle_index=2; game.campaign_profile["active_doctrine_id"]="royal_mana_watch"
	game._set_screen(Constants.SCREEN_CYCLE_DECREE,false)
	game._select_cycle_decree("decree_arcane_rationing"); await dismiss(); await frames(3)
	expect(game.campaign_profile.active_decree_id=="decree_arcane_rationing","existing decree selection UI applies choice")
	expect(game._current_skill_mana_cost({"cost_mana":10})==8,"decree changes actual skill mana cost")
	await fixture(7)
	game.campaign_profile["active_decree_id"]="decree_trap_maintenance"
	var b := begin_direct()
	if b!=null:
		b.spawn_enemy("explorer",{})
		var target: Node=game.enemy_units[-1]
		var trap: Dictionary=b.map.layout.traps[0]
		target.position=b.map.world(Vector2i(trap.cell[0],trap.cell[1]))
		b.apply_cell_traps(target)
		var key := str(target.get_instance_id())+":"+str(b.map.cell(target.position))
		expect(is_equal_approx(float(b.trap_next_hits[key])-game.combat_time,1.4),"trap decree applies existing 30 percent cooldown reduction")
	await leave_battle()
	evidence["crown_comparisons"]=rows

func council_start_and_records() -> void:
	await fixture(1,true)
	var v := current_view()
	for locale in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(locale,false); game._set_screen("management",false); await frames(2)
		v=current_view()
		var records: Button=v.chrome.get_node("ApprovedCampaign_records")
		expect(not records.text.contains("?"),"new campaign labels retain Unicode in "+locale)
	LanguageSettings.set_locale("ko",false); game._set_screen("management",false); await frames(2)
	v=current_view()
	expect(v!=null,"council DAY1 management is reachable")
	if v==null: return
	v.open_campaign_action("records"); await frames(3)
	expect(game.current_screen==Constants.SCREEN_CHRONICLE,"Approved records button reaches chronicle")
	game.ui_layer.get_node("ChronicleScreen").ending_requested.emit(); await frames(2)
	expect(game.current_screen==Constants.SCREEN_ENDING_ARCHIVE,"ending archive remains reachable through records flow")
	game._set_screen("management",false); await dismiss(); await frames(3)
	v=current_view()
	if v==null: expect(false,"records returns to Approved map"); return
	v.monster_ui.unlock_all=true; v.monster_ui.assignments=Members.auto_place(v.placement,Members.roster(),Members.roster().keys(),999)
	await capture("council_management_day1")
	expect(v.start_battle(),"real Approved council combat button passes prepared day")
	if v.battle==null: return
	v.set_physics_process(false)
	expect(game._update4_council_day_state().phase=="combat","council button uses existing begin-combat state machine")
	v.battle.finish_combat(true,"B03 controlled council settlement"); await frames(6); await dismiss()
	expect(game._update4_council_day_state().phase==game.CouncilSeasonServiceScript.PHASE_DAY_COMPLETE,"Approved settlement completes council combat state")
	game._advance_after_result(); await dismiss(); await frames(3)
	expect(GameState.day==2 and Grade.load_session(game).layout.day==2,"council result follows existing next-day entry")
	expect(game._update4_council_day_state().current_day==2,"council date state synchronized")
	await leave_battle()
	# The inherited DAY3 tutorial marker must not stop a later council cycle.
	await fixture(3,true)
	GameState.max_day=GameState.TUTORIAL_FINAL_DAY
	v=current_view()
	game.monster_roster.slime["specialization_id"]=game._specializations_for_monster("slime")[0].id
	expect(v.start_battle(),"council DAY3 real battle starts after required specialization")
	if v.battle==null: return
	v.set_physics_process(false)
	game.wave_manager.next_index=game.wave_manager.total_to_spawn
	v.battle.check_combat_end()
	await frames(6); await dismiss()
	expect(not GameState.victory,"council DAY3 victory is not tutorial completion")
	if game._result_growth_choice_required():
		for row in game.last_growth_summary:
			if game._choose_result_growth(str(row.monster_id)): break
		game._review_growth_from_result(); await frames(2)
	game._continue_from_result(); await dismiss(); await frames(4)
	expect(GameState.day==4 and Grade.load_session(game).layout.day==4,"council DAY3 result enters DAY4 setup instead of repeating DAY3")
	await leave_battle()
