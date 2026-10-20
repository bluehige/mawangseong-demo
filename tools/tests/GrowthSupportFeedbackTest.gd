extends "res://tools/tests/SkillRuntimeConnectionTest.gd"
var measured:Array=[]
func _ready()->void:
	get_tree().create_timer(180).timeout.connect(func():push_error("Growth feedback timeout");get_tree().quit(1))
	call_deferred("run")
func run()->void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"),"isolated growth userdata")
	if not failures.is_empty():get_tree().quit(1);return
	DataRegistry.load_all()
	if OS.get_cmdline_user_args().has("--growth-runtime"):
		for policy in ["off","once","once","always"]:await protection_case("slime_rescue_alchemy_gel",policy)
		await protection_case("slime_gate_bulwark","always");await cancelled();await duo_and_save();await next_choices()
		print("GROWTH_SUPPORT_RUNTIME: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1);return
	if OS.get_cmdline_user_args().has("--growth-cancel-duo-save"):
		await cancelled();await duo_and_save()
		print("GROWTH_CANCEL_DUO_SAVE_TARGETED: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1);return
	if OS.get_cmdline_user_args().has("--growth-clock-ui"):
		await clock_ui()
		print("GROWTH_CLOCK_UI_TARGETED: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1);return
	if OS.get_cmdline_user_args().has("--growth-existing-save-read"):
		await existing_save_read()
		print("GROWTH_EXISTING_SAVE_READ: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1);return
	for branch in ["slime_gate_bulwark","slime_rescue_alchemy_gel"]:await baseline(branch)
	var file:=FileAccess.open("res://tmp/growth_support_feedback/baseline.json",FileAccess.WRITE);file.store_string(JSON.stringify(measured,"\t"))
	print("GROWTH_EXISTING_BRANCH_BASELINE: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()]);get_tree().quit(0 if failures.is_empty() else 1)
func growth_fixture(branch:String,policy:String="off")->void:
	await setup_case("slime",policy)
	output_dir="res://tmp/growth_support_feedback";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game.update4_active_run=Modes.default_active_run();game.monster_roster.slime.level=3;game.monster_roster.slime.bond=25;game.monster_roster.slime.growth_stage=0
	GameState.day=12;game.campaign_chapter_two_started=true;GameState.gold=1000;GameState.mana=1000;GameState.infamy=1000
	var definition:Dictionary=DataRegistry.evolution_rule(branch);var money:int=GameState.gold
	expect(game._promote_monster("slime",branch),"existing DAY12 LV3 actual promotion "+branch)
	expect(GameState.gold==money-int(definition.cost.gold),"authored promotion cost unchanged "+branch)
	var old=caster;caster=game._create_unit("slime",game._scaled_monster_stats("slime"),Constants.FACTION_MONSTER,"entrance");caster.global_position=game.graph.center("entrance");old.queue_free();game.monster_units[0]=caster;game.selected_unit=caster
	caster.set_physics_process(false);caster.max_hp=1000;caster.hp=1000;ally.max_hp=1000;ally.hp=200;ally.global_position=caster.global_position+Vector2(100,0);ally.current_room="entrance"
	game._set_screen(Constants.SCREEN_COMBAT,false);game._capture_battle_growth_start();await settle()
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
func baseline(branch:String)->void:
	await growth_fixture(branch);var combat=game.combat_scene;var before:int=GameState.mana
	expect(combat.request_selected_skill(combat.skill_slots_for(caster).find("slime_shield")),"actual ordinary shield selected "+branch)
	var shielded=caster if branch=="slime_gate_bulwark" else ally
	expect(shielded.shield_timer>0 and (ally.shield_timer==0 if shielded==caster else caster.shield_timer==0),"existing branch actual shield target differs "+branch)
	var hp:int=shielded.hp;shielded.receive_damage(100)
	var row:Dictionary={"branch":branch,"actual_shield_target":str(shielded.unit_id),"shield_seconds":shielded.shield_timer,"reduction":shielded.damage_reduction,"HP_loss_incoming100":hp-shielded.hp,"mana_spent":before-GameState.mana,"natural_earning":"NOT_RUN; controlled DAY12/LV3/bond25 boundary","balance":"NOT_MEASURED"}
	for foe in game.enemy_units:foe.queue_free()
	game.enemy_units.clear();await settle();ally.current_room="recovery";ally.global_position=game.graph.center("recovery")
	for id in combat.skill_slots_for(caster):caster.set_skill_cooldown(str(id),100)
	combat.update_monster_path(caster)
	row.path_goal=str(caster.path_points[-1]) if not caster.path_points.is_empty() else "none";row.tactical=str(caster.tactical_state)
	measured.append(row);print("GROWTH_MEASURED ",JSON.stringify(row))
	await capture("baseline_"+branch);await dispose_case()
func protection_case(branch:String,policy:String)->void:
	await growth_fixture(branch,policy);var combat=game.combat_scene;var action=combat.skill_actions
	var target=caster if branch=="slime_gate_bulwark" else ally;var slot:int=combat.skill_slots_for(caster).find("slime_shield")
	expect(combat.request_selected_skill(slot),"actual protection request "+branch+policy)
	if action.is_active():
		expect(int(game.growth_feedback.snapshot("slime").support_protection_applications)==0 and game.find_child("PromotionSupportNotice",true,false)==null,"prepared action no support count/notice")
		action.skip();action.skip()
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
	expect(int(game.growth_feedback.snapshot("slime").support_protection_applications)==1,"one actual effect records protection across policy "+policy)
	var notice=game.find_child("PromotionSupportNotice",true,false)
	expect(notice!=null and notice.mouse_filter==Control.MOUSE_FILTER_IGNORE and game.continuity.support_notice_remaining==5,"first actual notice does not steal input")
	game._open_pause_menu();game.continuity.tick(9)
	expect(game.continuity.support_notice_remaining==5 and game.combat_paused,"menu pause preserves first notice simulation lifetime")
	game._close_pause_menu();expect(not game.combat_paused,"cancel menu returns gameplay input owner")
	if policy=="always":await capture("first_protection_"+branch+("_touch" if OS.get_cmdline_user_args().has("--mobile-touch-ui") else ""))
	target.shield_timer=20;target.damage_reduction=.9;caster.set_skill_cooldown("slime_shield",0)
	combat.request_selected_skill(slot)
	if action.is_active():action.skip()
	expect(int(game.growth_feedback.snapshot("slime").support_protection_applications)==1,"stronger longer shield no extra effective application")
	game.combat_time+=5.01;game.continuity.tick(0);await settle()
	expect(game.find_child("PromotionSupportNotice",true,false)==null,"notice expires once in resumed simulation")
	target.shield_timer=0;target.damage_reduction=0;caster.set_skill_cooldown("slime_shield",0);combat.request_selected_skill(slot)
	if action.is_active():action.skip()
	expect(int(game.growth_feedback.snapshot("slime").support_protection_applications)==2 and game.find_child("PromotionSupportNotice",true,false)==null,"later valid reapplication counts but first popup never repeats")
	await dispose_case()
func cancelled()->void:
	await growth_fixture("slime_rescue_alchemy_gel","always");var action=game.combat_scene.skill_actions
	game.combat_scene.request_selected_skill(game.combat_scene.skill_slots_for(caster).find("slime_shield"));caster.hp=0;caster.down=true;action.interrupt("growth invalid source")
	expect(int(game.growth_feedback.snapshot("slime").support_protection_applications)==0 and game.find_child("PromotionSupportNotice",true,false)==null,"invalid-source precontact shield never records support")
	await dispose_case()
func duo_and_save()->void:
	await growth_fixture("slime_rescue_alchemy_gel","off")
	game.update3_active_run.update3_enabled=true;game.update3_active_run.front_id="front_hero_oath";game.update3_active_run.front_selection_completed=true;game.update4_active_run.campaign_mode_id=Modes.FRONT_MODE_ID
	game.update3_active_run.heart.heart_id="heart_stonebone"
	game.monster_roster.spore_healer={"level":1,"exp":0,"bond":45,"bond_rank":1,"room":"entrance","specialization_id":""}
	var mori=game._create_unit("spore_healer",game._scaled_monster_stats("spore_healer"),Constants.FACTION_MONSTER,"entrance");mori.global_position=caster.global_position+Vector2(30,0);mori.set_physics_process(false);mori.hp=mori.max_hp-20;game.monster_units.append(mori)
	var link:String="link_spore_jelly_shelter"
	game.update3_profile=game.DuoLinkServiceScript.unlock_fixture(game.update3_profile,link,DataRegistry.update3_duo_links).profile
	game.update3_active_run.equipped_duo_links=[link];game._prepare_update3_duo_link_battle();game.update3_active_run.duo_link_states[link].charge=100
	game._activate_update3_duo_link(link)
	expect(int(game.growth_feedback.snapshot("slime").duo_shared_commits)==1 and int(game.growth_feedback.snapshot("spore_healer").duo_shared_commits)==1,"one actual duo commit appears as shared1 for each participant")
	game._activate_update3_duo_link(link)
	expect(int(game.growth_feedback.snapshot("slime").duo_shared_commits)==1,"used duo duplicate never records another shared use")
	expect(int(game.growth_feedback.snapshot("spore_healer").effective_healing)>0,"actual spore shelter healing remains owned by Mori")
	var healed:int=game.growth_feedback.snapshot("spore_healer").effective_healing;ally.hp=ally.max_hp;game.combat_scene.royal_support.heal_from(mori,ally,46)
	expect(int(game.growth_feedback.snapshot("spore_healer").effective_healing)==healed,"full target nominal healing not credited")
	caster.hp=1;caster.damage_reduction=0;caster.shield_timer=0;caster.duo_barrier=0;caster.mori_barrier=0
	ally.hp=1000;ally.duo_barrier=0;ally.duo_redirect_target=caster;ally.duo_redirect_timer=5;ally.duo_redirect_fraction=.35;ally.receive_damage(100)
	expect(int(game.growth_feedback.snapshot("slime").redirect_actual_hp_taken)==1,"redirect overkill records actual1 HP cost instead of nominal35 protection")
	var rows:Array=game._commit_or_rollback_battle_progress(true);game.result_summary={"win":true,"growth":rows};game.last_growth_summary=rows
	expect(rows.any(func(row):return str(row.monster_id)=="spore_healer" and int(row.support_contribution.effective_healing)==healed),"result rows snapshot actual support without references")
	game._set_screen(Constants.SCREEN_RESULT,false);await settle()
	expect(game.find_child("ResultMeasuredSupport",true,false)!=null,"actual result draws measured role contribution")
	var scroll=game.find_child("ResultGrowthScroll",true,false);var labels=game.find_children("ResultMeasuredSupport","Label",true,false)
	if scroll!=null and not labels.is_empty():scroll.ensure_control_visible(labels[-1]);await settle()
	await capture("measured_spore_duo_result")
	game._set_campaign_save_path_for_tests("user://growth_v1.json","user://growth_v2.json","user://growth_v3.json","user://growth_v4.json","user://growth_v5.json")
	expect(game._write_campaign_v2_snapshot(),"existing v1-v5 serializer accepts plain contribution snapshot")
	var inspection:Dictionary=game.CampaignSaveV5StoreScript.inspect(game.campaign_save_v5_path,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)
	expect(str(inspection.status)=="valid","actual saved v5 validation")
	if str(inspection.status)=="valid":
		var saved:Array=inspection.envelope.active_run.legacy_payload.result.last_growth_summary
		expect(saved.any(func(row):return str(row.monster_id)=="mon_contract_mori" and int(row.support_contribution.effective_healing)==healed),"v5 canonical instance IDs contain real support numbers in original result path")
		var money:int=GameState.gold;var exp:int=game.monster_roster.spore_healer.exp;game._continue_campaign_save();expect(GameState.gold==money and int(game.monster_roster.spore_healer.exp)==exp and game.last_growth_summary.any(func(row):return str(row.monster_id)=="spore_healer" and int(row.support_contribution.effective_healing)==healed),"continue normalizes canonical IDs without executing support or duo rewards again")
	expect(game.growth_feedback.contribution_text({})=="지원 기록 없음" and game.growth_feedback.normalize({"effective_healing":"bad"}).effective_healing==0,"old and malformed result data is safe missing evidence")
	await dispose_case()
func existing_save_read()->void:
	game=GameRootScene.instantiate();add_child(game);await settle();game.set_process(false);game.set_physics_process(false);game.continuity.acknowledge_update()
	game._set_campaign_save_path_for_tests("user://growth_v1.json","user://growth_v2.json","user://growth_v3.json","user://growth_v4.json","user://growth_v5.json")
	var stored:Dictionary=game.CampaignSaveV5StoreScript.inspect(game.campaign_save_v5_path,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)
	expect(str(stored.status)=="valid","previous actual growth v5 valid without repeating effects")
	if str(stored.status)!="valid":await dispose_case();return
	var saved:Array=stored.envelope.active_run.legacy_payload.result.last_growth_summary
	expect(saved.any(func(row):return str(row.monster_id)=="mon_contract_mori" and int(row.support_contribution.effective_healing)==6 and int(row.support_contribution.duo_shared_commits)==1),"v5 canonical source-owned actual6 heal/shared1 retained")
	game._continue_campaign_save()
	expect(game.last_growth_summary.any(func(row):return str(row.monster_id)=="spore_healer" and int(row.support_contribution.effective_healing)==6 and int(row.support_contribution.duo_shared_commits)==1),"continue normalizes instance IDs and preserves real contribution")
	var money:int=GameState.gold;var exp:int=game.monster_roster.spore_healer.exp;var bond:int=game.monster_roster.spore_healer.bond
	game._set_screen(Constants.SCREEN_TITLE,false);game._continue_campaign_save()
	expect(GameState.gold==money and int(game.monster_roster.spore_healer.exp)==exp and int(game.monster_roster.spore_healer.bond)==bond,"title continue again adds no rewards EXP or bond")
	expect(not game.pause_menu_open and not game.combat_paused,"continue input pause owner clear")
	expect(game.growth_feedback.contribution_text({})=="지원 기록 없음" and int(game.growth_feedback.normalize({"effective_healing":"bad"}).effective_healing)==0,"legacy and malformed contribution read safe")
	await dispose_case()
func next_choices()->void:
	await growth_fixture("slime_gate_bulwark")
	var before:Dictionary=game.campaign_profile.duplicate(true);var text:String=game.growth_feedback.next_choice()
	expect(text.contains("구조") and text.contains("유대25") and text.contains("기존 계약"),"opposite authored branch and Mori availability condition shown")
	game.campaign_profile.unlocked_contract_ids=["spore_healer"]
	text=game.growth_feedback.next_choice();expect(text.contains("유대45") and text.contains("기억1개") and text.contains("출전3일") and text.contains("역할조합5회"),"catalog-defined full duo unlock requirements without free unlock")
	game.update3_profile.duo_links.unlocked=["link_spore_jelly_shelter"];text=game.growth_feedback.next_choice()
	expect(text.contains("이미 해금") and not text.contains("역할조합5회"),"already unlocked duo offered without repeated task")
	expect(game.growth_feedback.seen_ending_hint()=="","unseen endings never named or previewed")
	game.campaign_profile.ending_archive={"monster_family_castle":{"seen_count":1}}
	var hint:String=game.growth_feedback.seen_ending_hint();expect(hint.contains(str(DataRegistry.ending_rules.monster_family_castle.display_name)) and hint.contains("미충족"),"known ending reads actual existing condition evaluation")
	game.result_summary={"win":true};game.last_growth_summary=game._commit_or_rollback_battle_progress(true);GameState.day=30;game.campaign_completed=true
	game._set_screen(Constants.SCREEN_RESULT,false);await settle();var label=game.find_child("ResultNextBuildChoice",true,false)
	expect(label!=null and not game.pause_menu_open and not game.continuity.update_open,"final result static alternative guide without new popup/forced nextcycle")
	await capture("next_cycle_existing_choice")
	var latest:Dictionary=game.campaign_profile.duplicate(true);game._set_screen(Constants.SCREEN_RESULT,false);expect(game.campaign_profile==latest and game.campaign_cycle_index==1,"result reread never starts cycle or grants rewards")
	await dispose_case()
func clock_ui()->void:
	await growth_fixture("slime_rescue_alchemy_gel","always");var combat=game.combat_scene
	combat.request_selected_skill(combat.skill_slots_for(caster).find("slime_shield"));combat.skill_actions.skip()
	for actor in game.monster_units:
		for id in combat.skill_slots_for(actor):actor.set_skill_cooldown(str(id),100)
	combat.set_speed(3.0);game._physics_process(.1)
	expect(is_equal_approx(game.combat_time,.3) and is_equal_approx(game.continuity.support_notice_remaining,4.7),"actual x3 physics clock consumes .3 of five simulation seconds")
	var time:float=game.combat_time;game._open_pause_menu();game._physics_process(1)
	expect(is_equal_approx(game.combat_time,time) and is_equal_approx(game.continuity.support_notice_remaining,4.7),"menu physics freezes notice and simulation clock")
	game._close_pause_menu();await capture("growth_first_protection_clock"+("_touch" if OS.get_cmdline_user_args().has("--mobile-touch-ui") else "_desktop"))
	var menu=game.find_child("CombatMenuButton",true,false);var notice=game.find_child("PromotionSupportNotice",true,false)
	expect(notice!=null and notice.mouse_filter==Control.MOUSE_FILTER_IGNORE,"clock notice remains pointer transparent")
	combat.set_speed(1.0);game._physics_process(4.71);await settle()
	expect(game.find_child("PromotionSupportNotice",true,false)==null,"actual resumed x1 simulation expires at five seconds")
	game.selected_monster_id="slime";game._set_screen(Constants.SCREEN_MONSTER,false);await settle();var scroll=game.find_child("MonsterGrowthScroll",true,false)
	if scroll!=null:scroll.scroll_vertical=999;await settle()
	await capture("growth_existing_promotion_explanation"+("_touch" if OS.get_cmdline_user_args().has("--mobile-touch-ui") else "_desktop"))
	expect(game.continuity.promotion_explanation({"id":"slime_rescue_alchemy_gel"}).contains("5.5"),"actual existing promotion detail has measured target and timing explanation")
	await dispose_case()
