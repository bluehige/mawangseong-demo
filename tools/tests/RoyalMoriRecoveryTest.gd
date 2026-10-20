extends "res://tools/tests/SkillRuntimeConnectionTest.gd"
var proof:Array=[]
func run()->void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"),"isolated Mori data")
	if not failures.is_empty():get_tree().quit(1);return
	DataRegistry.load_all();UISettings.reset_skill_cutscene_history(false)
	var baseline:Dictionary={}
	for policy in ["off","once","once","always"]:
		var result:Dictionary=await effect(policy,false)
		if baseline.is_empty():baseline=result
		else:expect(result==baseline,"Mori actual effects identical across viewing policies")
	var automatic:Dictionary=await effect("always",true)
	expect(automatic==baseline,"Mori actual auto shares effect pipeline")
	await sacrament();await invalid_and_lifecycle()
	await duo_and_atomic_suppression()
	await skill_seal_auto()
	await queued_source()
	await retaliation_is_not_debuff()
	await queued_recipient()
	var file:=FileAccess.open("res://tmp/royal_mori_recovery/results.json",FileAccess.WRITE);file.store_string(JSON.stringify(proof,"\t"))
	print("ROYAL_MORI_RECOVERY_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
func fixture(policy:String)->void:
	await setup_case("spore_healer",policy)
	output_dir="res://tmp/royal_mori_recovery";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game.update4_active_run.campaign_mode_id=Modes.COUNCIL_MODE_ID
	game.update4_active_run.crown={"crown_form_id":"crown_mori_grand_mycelial_priest","selected_instance_id":"mon_contract_mori"}
	game.update4_active_run.upper_floor={"crown_suppressed":false}
	var old=caster
	caster=game._create_unit("spore_healer",game._scaled_monster_stats("spore_healer"),Constants.FACTION_MONSTER,"entrance")
	caster.global_position=old.global_position;caster.set_physics_process(false);old.queue_free()
	game.monster_units[0]=caster;game.selected_unit=caster
	ally.hp=10;ally.apply_slow(8,.5);ally.apply_armor_break(2,8,"fixture");ally.apply_seal_chain(6,3,4)
	outsider.hp=outsider.max_hp-30
	await settle()
func effect(policy:String,auto:bool)->Dictionary:
	await fixture(policy)
	var combat=game.combat_scene;var runtime=combat.royal_support;var action=combat.skill_actions
	var slots:Array=combat.skill_slots_for(caster);var slot:int=slots.find("royal_shared_umbrella")
	expect(slot>=0,"actual royal ability available in native slots")
	for id in slots:
		if id!=null and str(id)!="royal_shared_umbrella":caster.set_skill_cooldown(str(id),100)
	var seen:bool=UISettings.skill_cutscene_seen.has("skill:royal_shared_umbrella")
	var accepted:bool=combat.try_auto_monster_skill(caster) if auto else combat.request_selected_skill(slot)
	expect(accepted,"actual Mori royal request")
	var shown:bool=policy=="always" or(policy=="once" and not seen)
	expect(action.is_active()==shown,"Mori once/off/always")
	if action.is_active():
		expect(runtime.umbrellas.is_empty() and ally.negative_status_count()>0,"preparation no cleansing or regen")
		expect(action.actors[0].sprite_frames==caster.sprite.sprite_frames and caster.sprite_path.contains("crown_mori"),"native current crown art")
		action.tick(.4);await capture("mori_"+policy+("_auto" if auto else "_manual")+"_prepare")
		action.tick(.16);await capture("mori_"+policy+("_auto" if auto else "_manual")+"_contact")
		action.skip();action.skip()
	for actor in game.monster_units+game.enemy_units:actor.set_physics_process(false)
	expect(ally.negative_status_count()==0 and ally.seal_skill_lock_timer==0.0,"actual all cleansing including skill seal")
	expect(GameState.mana==500 and caster.get_meta("royal_umbrella_uses",0)==1,"zero mana, one battle use")
	expect(not combat.request_selected_skill(slot),"second royal use rejected")
	expect(combat.hud._selected_unit_skill_summary(caster).contains("이번 전투 사용 완료"),"native skill summary shows actual used battle ability")
	var before:int=ally.hp;var far_before:int=outsider.hp
	runtime.tick(.99);expect(ally.hp==before,"regeneration no early tick")
	runtime.tick(.01);expect(ally.hp==before+3 and outsider.hp==far_before+3,"actual first tick same floor across rooms")
	ally.clear_mori_barrier();var hp_before_fatal:int=ally.hp
	var dealt:int=ally.receive_damage(10000)
	expect(ally.hp==1 and ally.is_alive() and dealt==hp_before_fatal-1,"actual fatal hit clamped before DOWN")
	var guard_value:int=runtime.contributions[caster.get_instance_id()].fatal_raw_damage_cancelled
	expect(runtime.contributions[caster.get_instance_id()].fatal_saves==1 and runtime.contributions[caster.get_instance_id()].fatal_hp_preserved==1,"raw lethal overkill separate from actual oneHP preservation/one life saved")
	ally.receive_damage(10)
	expect(not ally.is_alive(),"second lethal hit unprotected")
	runtime.tick(4.0)
	expect(runtime.umbrellas.is_empty() and outsider.hp==far_before+15,"exact five regeneration ticks, no heal of down unit")
	expect(caster.mori_healing_penalty_timer==6.0 and combat._outgoing_heal_amount(caster,46)==42,"post regen six-second outgoing .85 plus crown1.08")
	caster._physics_process(6.01)
	expect(combat._outgoing_heal_amount(caster,46)==50,"outgoing penalty expires independently")
	var outcome:Dictionary={"far_heal":outsider.hp-far_before,"guard":guard_value,"mana":GameState.mana,"uses":caster.get_meta("royal_umbrella_uses"),"second_down":not ally.is_alive()}
	proof.append({"policy":policy,"auto":auto,"outcome":outcome,"progression":"forced crown fixture, not earned unlock"})
	game.queue_free();await settle();return outcome
func sacrament()->void:
	await fixture("off")
	var combat=game.combat_scene;var runtime=combat.royal_support
	ally.hp=ally.max_hp-2;ally.cleanse_all_negative_status()
	var effective:int=runtime.heal_from(caster,ally,46,"actual_overheal")
	expect(effective==2 and ally.mori_barrier==24,"actual adjusted50, missing2, overheal48 -> shield24")
	var hp_before:int=ally.hp;ally.receive_damage(20)
	expect(ally.hp==hp_before and ally.mori_barrier==4,"real incoming damage consumes separate sacrament shield")
	expect(runtime.contributions[caster.get_instance_id()].shield_absorbed==20,"actual attributed shield absorption")
	ally.soft_counter_healing_multiplier=.5;ally.heart_healing_multiplier=.8
	ally.hp=ally.max_hp-2;ally.clear_mori_barrier()
	effective=runtime.heal_from(caster,ally,46,"fatigued_overheal")
	expect(effective==2 and ally.mori_barrier==9,"actual receiving fatigue/heart precedes overheal shield")
	runtime.heal_from(caster,ally,10000,"cap")
	expect(ally.mori_barrier==roundi(ally.max_hp*.35),"actual maxHP35percent shield cap")
	var other:int=ally.duo_barrier;ally._physics_process(5.01)
	expect(ally.mori_barrier==0 and ally.duo_barrier==other,"five-second sacrament expiration leaves unrelated shield")
	game.update4_active_run.upper_floor.crown_suppressed=true
	ally.hp=ally.max_hp;runtime.heal_from(caster,ally,46,"suppressed")
	expect(ally.mori_barrier==0,"suppressed Mori cannot create new sacrament")
	game.queue_free();await settle()

func duo_and_atomic_suppression()->void:
	await fixture("off")
	ally.cleanse_all_negative_status();ally.hp=ally.max_hp
	var effect:Dictionary={"radius":190.0,"heal_per_second":3,"shield":40,"first_heal_ignores_fatigue":true}
	game._apply_spore_jelly_shelter_tick(caster.global_position,effect,true)
	expect(ally.duo_barrier==40 and ally.mori_barrier==2,"actual existing duo tick keeps own barrier and gains Mori-source sacrament")
	ally.duo_barrier=0;ally.clear_mori_barrier()
	game.combat_scene.royal_support.heal_from(caster,ally,46,"shield_before_atomic_suppression")
	expect(ally.mori_barrier==25,"full health actual crown overheal50 creates25 shield")
	game.update4_active_run.upper_floor.crown_suppressed=true
	var hp_before:int=ally.hp;ally.receive_damage(20)
	expect(ally.hp==hp_before-20 and ally.mori_barrier==0,"suppression invalidates shield at actual hit without waiting for frame poll")
	game.update4_active_run.upper_floor.crown_suppressed=false
	outsider.set_meta("runtime_floor_id","synthetic_other_floor")
	expect(not game.combat_scene.royal_support.targets(caster).has(outsider),"future floor adapter excludes differing identity; not real2F proof")
	game.queue_free();await settle()

func skill_seal_auto()->void:
	await fixture("off")
	for unit in game.monster_units:unit.cleanse_all_negative_status();unit.hp=unit.max_hp
	ally.seal_skill_lock_timer=3.0
	for id in game.combat_scene.skill_slots_for(caster):
		if id!=null and str(id)!="royal_shared_umbrella":caster.set_skill_cooldown(str(id),100)
	expect(game.combat_scene.try_auto_monster_skill(caster),"actual auto responds to skill-only seal at fullHP")
	expect(ally.seal_skill_lock_timer==0.0 and caster.get_meta("royal_umbrella_uses")==1,"skill-only seal really cleansed with one royal use")
	game.queue_free();await settle()

func queued_source()->void:
	await fixture("off")
	var runtime=game.combat_scene.royal_support
	ally.cleanse_all_negative_status();ally.hp=ally.max_hp
	runtime.heal_from(caster,ally,46,"queue_fixture")
	expect(ally.mori_barrier==25,"queued-source actual existing barrier fixture")
	var slot:int=game.combat_scene.skill_slots_for(caster).find("royal_shared_umbrella")
	ally.hp=20;expect(game.combat_scene.request_selected_skill(slot),"queued-source fatal protection fixture")
	caster.queue_free()
	ally.receive_damage(100)
	expect(not ally.is_alive() and ally.mori_barrier==0,"queued source immediately invalidates barrier and fatal guard")
	var hp_before:int=outsider.hp;runtime.tick(1.0)
	expect(outsider.hp==hp_before and runtime.umbrellas.is_empty(),"queued source gives no next regeneration tick")
	game.queue_free();await settle()

func retaliation_is_not_debuff()->void:
	await fixture("off")
	for unit in game.monster_units:unit.cleanse_all_negative_status();unit.hp=unit.max_hp
	for id in game.combat_scene.skill_slots_for(caster):
		if id!=null and str(id)!="royal_shared_umbrella":caster.set_skill_cooldown(str(id),100)
	ally.mark_threat(enemy,4,false)
	expect(not game.combat_scene.try_auto_monster_skill(caster) and caster.get_meta("royal_umbrella_uses",0)==0,"ordinary retaliation never wastes once-battle royal cleanse")
	ally.cleanse_all_negative_status()
	expect(ally.threat_unit==enemy and ally.threat_timer>0.0,"royal cleanse preserves ordinary combat memory")
	ally.mark_threat(enemy,4,true)
	game.combat_time+=game.combat_scene.AUTO_SKILL_DECISION_INTERVAL
	expect(game.combat_scene.try_auto_monster_skill(caster) and ally.threat_timer==0.0,"actual forced taunt is cleansed by royal automatic action")
	game.queue_free();await settle()

func queued_recipient()->void:
	await fixture("off")
	var runtime=game.combat_scene.royal_support
	var slot:int=game.combat_scene.skill_slots_for(caster).find("royal_shared_umbrella")
	expect(game.combat_scene.request_selected_skill(slot),"queued-recipient real umbrella")
	ally.queue_free()
	expect(runtime.heal_from(caster,ally,46,"queued_recipient")==0,"queued recipient no healing or sacrament contribution")
	ally.receive_damage(100)
	expect(not ally.is_alive() and not bool(runtime.umbrellas[caster.get_instance_id()].guard_used),"queued recipient receives no fatal guard/token consumption")
	runtime.tick(1.0)
	expect(int(runtime.contributions[caster.get_instance_id()].get("effective_healing",0))==3,"queued recipient no phantom tick contribution; other actual ally still heals3")
	game.queue_free();await settle()
func invalid_and_lifecycle()->void:
	await fixture("always")
	var combat=game.combat_scene;var runtime=combat.royal_support
	var slot:int=combat.skill_slots_for(caster).find("royal_shared_umbrella")
	expect(combat.request_selected_skill(slot),"prepared invalidation fixture")
	game.update4_active_run.upper_floor.crown_suppressed=true;combat.skill_actions.skip()
	expect(runtime.umbrellas.is_empty() and caster.get_meta("royal_umbrella_uses",0)==0 and ally.negative_status_count()>0,"suppression before contact no use/effect")
	game.update4_active_run.upper_floor.crown_suppressed=false;combat.set_speed(3)
	expect(combat.request_selected_skill(slot),"prepared menu interruption")
	game._open_pause_menu()
	expect(game.combat_paused and runtime.umbrellas.size()==1 and caster.get_meta("royal_umbrella_uses")==1,"menu commits valid action once, retains pause")
	var hp_before:int=outsider.hp;await settle();expect(outsider.hp==hp_before,"menu pauses regen")
	game._close_pause_menu();expect(not game.combat_paused and game.combat_speed==3.0,"menu restores x3")
	game.update4_active_run.upper_floor.crown_suppressed=true;runtime.tick(.1)
	expect(runtime.umbrellas.is_empty(),"suppression stops pending regen/fatal guard")
	var shield_before:int=ally.mori_barrier
	ally.hp=1;ally.receive_damage(10000);expect(not ally.is_alive(),"suppressed guard cannot rescue")
	combat.abandon_suspended_frame()
	expect(runtime.umbrellas.is_empty() and caster.mori_healing_penalty_timer==0 and shield_before==0,"title/checkpoint clears battle-only royal state")
	game.queue_free();await settle()
