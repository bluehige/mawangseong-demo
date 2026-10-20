extends "res://tools/tests/EchoObjectiveRecoveryTest.gd"
const Mastery=preload("res://scripts/systems/crown/SupportMasteryRuntime.gd")
const Crown=preload("res://scripts/systems/crown/CrownEvolutionService.gd")
func _ready()->void:
	get_tree().create_timer(180).timeout.connect(func():push_error("Earned support fixture timeout");get_tree().quit(1))
	call_deferred("run")
func run()->void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"),"isolated earned support userdata")
	if not failures.is_empty():get_tree().quit(1);return
	DataRegistry.load_all();UISettings.reset_skill_cutscene_history(false)
	if OS.get_cmdline_user_args().has("--earned-save-only"):
		await save_and_crown()
		print("EARNED_SUPPORT_SAVE_TARGETED: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1);return
	if OS.get_cmdline_user_args().has("--earned-owned-ui-only"):
		await support_fixture("spore_healer");game._ensure_update4_council_roster();game.deployed_instance_ids.assign(["mon_core_pudding"])
		game._open_contract_roster();await settle();game.secondary_workspace.selected_id=game.ContractRosterServiceScript.instance_id_for_species("spore_healer",DataRegistry.monster_instances);game.secondary_workspace.contract_detail();await settle()
		var toggle=game.find_child("ContractToggleButton",true,false)
		expect(toggle!=null and not toggle.disabled,"touch owned Mori actual deployment button available")
		expect(game.find_child("ContractMastery",true,false)!=null,"touch owned detail shows new milestone requirements")
		if toggle!=null:await click(toggle,Vector2(70,24))
		expect(game._monster_deployed_for_defense("spore_healer"),"touch actual viewport pointer deploys Mori")
		game.secondary_workspace.selected_id=game.ContractRosterServiceScript.instance_id_for_species("spore_healer",DataRegistry.monster_instances);game.secondary_workspace.contract_detail();await settle()
		await capture("earned_owned_roster_touch");await dispose_case()
		print("EARNED_SUPPORT_OWNED_UI_TARGETED: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1);return
	if OS.get_cmdline_user_args().has("--earned-new-boundaries"):
		await new_boundary_cases()
		print("EARNED_SUPPORT_NEW_BOUNDARIES: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1);return
	if OS.get_cmdline_user_args().has("--earned-final-extra"):
		await new_boundary_cases();await save_and_crown()
		print("EARNED_SUPPORT_TARGETED_EXTRA: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1);return
	await healer();await guards_and_identity();await toktok();await carrier();await roster();await save_and_crown()
	print("EARNED_SUPPORT_PROGRESSION_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1)
func support_fixture(species:String)->void:
	await setup_case(species,"off")
	output_dir="res://tmp/earned_support_progression";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game.update4_profile=Modes.normalize_profile({})
	game.update4_active_run.campaign_mode_id=Modes.COUNCIL_MODE_ID
	game.deployed_instance_ids.clear()
	for unit in game.monster_units:
		var id:String=game.ContractRosterServiceScript.instance_id_for_species(str(unit.unit_id),DataRegistry.monster_instances)
		if id!="":game.deployed_instance_ids.append(id)
	game._capture_battle_growth_start()
func mastery(species:String)->int:return int(game.update4_profile.get("crown_evolution",{}).get("species_mastery",{}).get(species,0))
func healer()->void:
	await support_fixture("spore_healer")
	var support=game.support_mastery
	var before:int=ally.hp;game.combat_scene.royal_support.heal_from(caster,ally,46)
	expect(ally.hp>before and bool(support.pending[caster.get_instance_id()].support),"actual ordinary healing records actor support")
	expect(mastery("spore_healer")==0,"effect before victory never persists mastery")
	caster.receive_damage(30)
	expect(int(support.pending[caster.get_instance_id()].hp_loss)>0,"true HP loss records same actor")
	game.monster_roster.spore_healer.bond=77;game.battle_growth_start.spore_healer.bond=77
	var rows:Array=game._commit_or_rollback_battle_progress(true)
	expect(mastery("spore_healer")==3,"actual normal victory gain/support/survival earn unique three")
	expect(rows.all(func(row):return row is Dictionary) and rows.any(func(row):return str(row.get("support_mastery","")).contains("3 ·")),"growth retains dictionary schema with truthful support summary")
	var frozen:Dictionary=game.update4_profile.duplicate(true);support.settle(true);support.summary("spore_healer")
	expect(game.update4_profile==frozen,"duplicate settlement and viewing never add mastery")
	game.last_growth_summary=rows;game.result_summary={"win":true};game._set_screen(Constants.SCREEN_RESULT,false);await capture("earned_support_result")
	expect(game.find_child("ResultSupportMastery",true,false)!=null,"actual result UI contains mastery")
	await dispose_case()
func guards_and_identity()->void:
	await support_fixture("spore_healer");var support=game.support_mastery
	ally.hp=ally.max_hp;game.combat_scene.royal_support.heal_from(caster,ally,46)
	expect(support.pending.is_empty(),"full HP nominal healing/shield offered is not actual support")
	ally.hp=1;game.combat_scene.royal_support.heal_from(caster,ally,46)
	caster.duo_barrier=1000;caster.receive_damage(30)
	expect(int(support.pending[caster.get_instance_id()].hp_loss)==0,"fully shielded damage is not survival evidence")
	support.settle(true);expect(mastery("spore_healer")==1,"shield-only win earns support only")
	support.begin_battle();caster.duo_barrier=0;caster.receive_damage(10);support.settle(true)
	expect(mastery("spore_healer")==1,"other battle HP loss cannot combine with prior support")
	support.begin_battle();ally.hp=1;game.combat_scene.royal_support.heal_from(caster,ally,46);game._commit_or_rollback_battle_progress(false)
	expect(mastery("spore_healer")==1 and not support.active and support.pending.is_empty(),"loss rolls back new milestones")
	support.begin_battle();support.record_support(caster,"synthetic boundary",1);game._clear_units()
	expect(not support.active and support.pending.is_empty(),"abandon/unit cleanup discards pending evidence")
	await dispose_case()
	await support_fixture("spore_healer");support=game.support_mastery
	var id:String=game.ContractRosterServiceScript.instance_id_for_species("spore_healer",DataRegistry.monster_instances)
	game.deployed_instance_ids.erase(id);ally.hp=1;game.combat_scene.royal_support.heal_from(caster,ally,46);caster.receive_damage(10);game.monster_roster.spore_healer.bond=80;support.settle(true)
	expect(mastery("spore_healer")==0,"reserve actor cannot earn support/survive/prepatch bond")
	await dispose_case()
	await support_fixture("spore_healer");support=game.support_mastery
	ally.hp=1;game.combat_scene.royal_support.heal_from(caster,ally,46);caster.receive_damage(100000);support.settle(true)
	expect(mastery("spore_healer")==1,"actual down actor may earn support but never survival")
	await dispose_case()
func toktok()->void:
	await support_fixture("armored_beetle");var support=game.support_mastery
	enemy.def=0;game.combat_scene.perform_toktok_carapace_ram(caster,enemy)
	expect(support.pending.is_empty(),"zero effective DEF reduction never awards support")
	caster.global_position=enemy.global_position-Vector2(30,0);enemy.armor_break_amount=0;enemy.armor_break_timer=0;enemy.def=20
	game.combat_scene.perform_toktok_carapace_ram(caster,enemy)
	expect(bool(support.pending.get(caster.get_instance_id(),{}).get("support",false)),"real surviving target DEF reduction earns support")
	support.begin_battle();caster.global_position=game.graph.center("barracks");caster.current_room="barracks"
	game.rooms.barracks.max_hp=100;game.rooms.barracks.hp=60;game.rooms.barracks.disabled=false
	var hp:int=game.rooms.barracks.hp;var result:Dictionary=game.combat_scene.perform_toktok_patch_plates(caster,null,"barracks")
	expect(bool(result.get("ok",false)) and int(game.rooms.barracks.hp)>hp and bool(support.pending.get(caster.get_instance_id(),{}).get("support",false)),"actual room HP repair records support")
	support.begin_battle();game.rooms.barracks.hp=100;game.combat_scene.perform_toktok_patch_plates(caster,null,"barracks")
	expect(support.pending.is_empty(),"full facility nominal repair does not earn support")
	await dispose_case()
func carrier()->void:
	await support_fixture("bat_courier");var combat=game.combat_scene;var support=game.support_mastery
	game.update4_active_run.council_season={"council_votes":10,"council_seals":3}
	for old in game.enemy_units:old.queue_free()
	game.enemy_units.clear();await settle();var actor=spawn_native("dusk_courier")
	var quote:Dictionary=combat.echo_alarm.prepare(caster);combat.echo_alarm.cast(caster,quote)
	expect(support.pending.is_empty(),"reserved echo delay never awards before consumption")
	native_step(.7)
	expect(bool(support.pending.get(caster.get_instance_id(),{}).get("support",false)),"actual fractional echo consumption records support")
	support.begin_battle();native_step(6);combat.native_objectives.manual_command(caster);caster.global_position=actor.global_position;native_step(0)
	expect(bool(support.pending.get(caster.get_instance_id(),{}).get("support",false)) and int(game.update4_active_run.council_season.council_votes)==10,"physical bag exact refund records actual support")
	await dispose_case()
func roster()->void:
	await support_fixture("spore_healer")
	game.update4_active_run=Modes.default_active_run();game.campaign_cycle_index=2
	game.current_screen=Constants.SCREEN_CONTRACT_BOARD;game.selected_contract_ids.clear()
	var offered:Dictionary=game._available_update2_contracts();var other:String=""
	for key in offered:
		if str(key)!="spore_healer":other=str(key);break
	game.contract_board_pending_ids.assign(["spore_healer",other]);game._confirm_contract_selection()
	expect(game.campaign_profile.unlocked_contract_ids.has("spore_healer"),"real contract confirmation persists earned Mori ownership")
	game.monster_roster.erase("spore_healer")
	game.update3_profile=game.FrontCampaignServiceScript.apply_ending_rewards(game.update3_profile,game.update3_active_run,"ending_off_ledger_independence",DataRegistry.update3_endings)
	game.update4_profile.campaign_modes.council_season_unlocked=true
	game._select_campaign_mode(Modes.COUNCIL_MODE_ID)
	expect(game.monster_roster.has("spore_healer") and game.monster_roster.has("armored_beetle"),"Council restores already earned contract and reward ownership")
	expect(game.deployed_instance_ids.size()==5 and not game._monster_deployed_for_defense("spore_healer") and not game._monster_deployed_for_defense("armored_beetle"),"original five start; restored extras reserve")
	expect(game._current_contract_deployment_limit()==5 and game._contract_roster_available(),"Council owned UI bypasses ordinary two-candidate selection")
	game.selected_contract_ids.clear();game._open_contract_roster();await settle()
	expect(not game.secondary_workspace.contract_selection,"Council opens actual owned roster without candidate offer")
	await capture("council_owned_roster")
	var prior:Array=game.deployed_instance_ids.duplicate();game._ensure_update4_council_roster()
	expect(game.deployed_instance_ids==prior,"repeated ownership restoration preserves current deployment")
	game.deployed_instance_ids.clear();game._sync_contract_reserves()
	expect(not game._monster_deployed_for_defense("slime") and game.reserve_instance_ids.size()>=7,"empty Council selection means none not all reserves")
	game.combat_scene.start_combat();expect(game.current_screen==Constants.SCREEN_CONTRACT_BOARD and game.monster_units.size()==3,"empty army combat rejected before clearing live actors")
	game.deployed_instance_ids.assign(["invalid"]);game._ensure_update4_council_roster()
	expect(game.deployed_instance_ids.size()==5 and not game._monster_deployed_for_defense("spore_healer"),"invalid legacy IDs fallback only original five")
	game.current_screen=Constants.SCREEN_CONTRACT_BOARD
	var mori:String=game.ContractRosterServiceScript.instance_id_for_species("spore_healer",DataRegistry.monster_instances)
	var first:String=game.deployed_instance_ids[0];game._toggle_contract_deployment(first);game._toggle_contract_deployment(mori)
	var selected:Array=game.deployed_instance_ids.duplicate();game._ensure_update4_council_roster()
	expect(game.deployed_instance_ids==selected and game._monster_deployed_for_defense("spore_healer"),"saved changed five preserves earned support choice")
	game.selected_monster_id="spore_healer";game._set_screen(Constants.SCREEN_MONSTER);await capture("earned_support_monster")
	expect(game.find_child("MonsterSupportMastery",true,false)!=null,"actual monster UI shows missing earned milestones")
	await dispose_case()
func save_and_crown()->void:
	await support_fixture("spore_healer");var support=game.support_mastery
	game.update4_profile.campaign_modes.council_season_unlocked=true
	ally.hp=1;game.combat_scene.royal_support.heal_from(caster,ally,46);caster.receive_damage(20);support.settle(true)
	game.update4_profile.crown_evolution.future_nested={"keep":42}
	var normalized:Dictionary=Modes.normalize_profile({"crown_evolution":{"species_milestones":{"spore_healer":{"support":"bad","survive":true,"other":"keep"}},"species_mastery":{"spore_healer":9,"armored_beetle":"bad"},"future_nested":{"keep":42}}})
	expect(int(normalized.crown_evolution.species_mastery.spore_healer)==9 and int(normalized.crown_evolution.species_mastery.armored_beetle)==0,"old higher numeric mastery preserved; malformed value safely normalized")
	expect(not normalized.crown_evolution.species_milestones.spore_healer.support and normalized.crown_evolution.future_nested.keep==42,"malformed flags normalize without dropping unknown nested crown data")
	game.monster_roster.spore_healer.level=6;game.monster_roster.spore_healer.bond=80;game.monster_roster.spore_healer.specialization_id="mori_spore_shaman"
	var instance:Dictionary=game._update4_crown_instance(game.ContractRosterServiceScript.instance_id_for_species("spore_healer",DataRegistry.monster_instances))
	var form:String=""
	for key in DataRegistry.update4_crown_evolutions:
		if str(DataRegistry.update4_crown_evolutions[key].monster_id)=="spore_healer":form=str(key);break
	game.update4_active_run.council_season=game.SaveV4ToV5MigratorScript.default_council_season();game.update4_active_run.council_season.council_seals=2;var map:Dictionary=game.update4_profile.crown_evolution.species_mastery
	expect(Crown.candidate_check(instance,DataRegistry.update4_crown_evolutions[form],game.update4_active_run.council_season,map).eligible,"real candidate reads earned mastery2 with existing LV/bond/spec gates")
	instance.level=5;expect(not Crown.candidate_check(instance,DataRegistry.update4_crown_evolutions[form],game.update4_active_run.council_season,map).eligible,"LV gate unchanged")
	instance.level=6;var result:Dictionary=Crown.confirm(game.update4_active_run,instance,form,DataRegistry.update4_crown_evolutions,map)
	expect(result.ok and int(result.active_run.council_season.council_seals)==0 and not Crown.confirm(result.active_run,instance,form,DataRegistry.update4_crown_evolutions,map).ok,"real confirmation spends authored2 once and rejects reuse")
	game._set_screen(Constants.SCREEN_MANAGEMENT,false)
	game._set_campaign_save_path_for_tests("user://earned_v1.json","user://earned_v2.json","user://earned_v3.json","user://earned_v4.json","user://earned_v5.json")
	expect(game._write_campaign_v2_snapshot(),"actual v1-v5 path writes earned plain crown data")
	var stored:Dictionary=game.CampaignSaveV5StoreScript.inspect(game.campaign_save_v5_path,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)
	if str(stored.status)!="valid":expect(false,"valid v5 required before continue assertions");await dispose_case();return
	expect(str(stored.status)=="valid" and int(stored.envelope.profile.crown_evolution.species_mastery.spore_healer)==2,"actual v5 validation and read retain mastery")
	game.update4_profile={};game._load_update4_context_from_v5(stored.envelope,true)
	expect(mastery("spore_healer")==2 and game.update4_profile.crown_evolution.future_nested.keep==42,"actual continue context restores milestones and unknown nested crown fields")
	game.campaign_save_enabled=false;game.campaign_completed=true;game.campaign_final_battle_outcome="victory"
	game._campaign_next_cycle_from_ending()
	expect(mastery("spore_healer")==2 and game.campaign_cycle_index>=2,"actual next-cycle boundary preserves earned mastery without new levels")
	await dispose_case()
func new_boundary_cases()->void:
	await support_fixture("spore_healer");var support=game.support_mastery
	var second=game._create_unit("spore_healer",game._scaled_monster_stats("spore_healer"),Constants.FACTION_MONSTER,"entrance");game.monster_units.append(second);second.set_physics_process(false)
	ally.hp=1;game.combat_scene.royal_support.heal_from(caster,ally,46);second.receive_damage(20);support.settle(true)
	expect(mastery("spore_healer")==1,"same species actors cannot combine one support and another HP loss")
	await dispose_case()
	await support_fixture("armored_beetle");support=game.support_mastery
	game.update4_active_run.crown={"crown_form_id":"crown_toktok_royal_shell","selected_instance_id":"monster_toktok"};game.update4_active_run.upper_floor={"crown_suppressed":false}
	# Find the authored form without introducing a new form ID.
	for form in DataRegistry.update4_crown_evolutions:
		if str(DataRegistry.update4_crown_evolutions[form].monster_id)=="armored_beetle":game.update4_active_run.crown.crown_form_id=str(form)
	caster.global_position=game.graph.center("barracks");caster.current_room="barracks";caster.assigned_room="barracks"
	game.rooms.barracks.max_hp=100;game.rooms.barracks.hp=40;game.rooms.barracks.disabled=false
	game.combat_scene.crown_facilities.cast(caster,"barracks",DataRegistry.skill("royal_emergency_plating"))
	expect(int(game.rooms.barracks.hp)==70 and bool(support.pending.get(caster.get_instance_id(),{}).get("support",false)),"actual royal facility repair counts support")
	await dispose_case()
	await support_fixture("bat_courier");support=game.support_mastery
	game.combat_scene.crown_mobility._courier_arrive(caster,ally,{"duration":6,"move_multiplier":1.2,"attack_interval_multiplier":.85,"status_resistance_bonus":.20})
	expect(not ally.night_relay_buffs.is_empty() and bool(support.pending.get(caster.get_instance_id(),{}).get("support",false)),"actual royal arrival buff kernel counts support")
	await dispose_case()
	await support_fixture("spore_healer")
	game.update3_profile=game.FrontCampaignServiceScript.record_front_clear(game.update3_profile,{"front_id":"front_guild_repossession"},DataRegistry.update3_fronts)
	game.monster_roster.erase("armored_beetle");game._sync_update3_reward_monsters()
	expect(game.monster_roster.has("armored_beetle"),"actual authored Front-clear producer restores Tok")
	game.monster_roster.erase("armored_beetle");game.update3_profile=game.FrontCampaignServiceScript.default_update3_profile()
	game.update3_profile=game.FrontCampaignServiceScript.apply_ending_rewards(game.update3_profile,game.update3_active_run,"ending_off_ledger_independence",DataRegistry.update3_endings)
	game._sync_update3_reward_monsters()
	expect(game.update3_profile.guaranteed_contract_instance_ids.has("monster_toktok") and game.monster_roster.has("armored_beetle"),"actual E13 reward producer restores Tok")
	game._ensure_update4_council_roster();game.deployed_instance_ids.clear();game._ensure_update4_council_roster()
	expect(game.deployed_instance_ids.is_empty(),"restoration preserves deliberate empty edited Council selection")
	game.deployed_instance_ids.assign(["mon_core_pudding"]);game._open_contract_roster();await settle()
	game.secondary_workspace.selected_id=game.ContractRosterServiceScript.instance_id_for_species("spore_healer",DataRegistry.monster_instances);game.secondary_workspace.contract_detail();await settle()
	var toggle=game.find_child("ContractToggleButton",true,false);expect(toggle!=null and not toggle.disabled,"earned Mori has actual available deployment button")
	if toggle!=null:await click(toggle,Vector2(70,24))
	expect(game._monster_deployed_for_defense("spore_healer") and game.deployed_instance_ids.size()==2,"actual viewport pointer deploys owned Mori")
	await capture("earned_roster_actual_pointer"+ ("_touch" if OS.get_cmdline_user_args().has("--mobile-touch-ui") else "_desktop"))
	await dispose_case()
