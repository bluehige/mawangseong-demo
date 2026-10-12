extends "res://tools/tests/SkillRuntimeConnectionTest.gd"
const Heart=preload("res://scripts/systems/hearts/CastleHeartService.gd")
var proof:Array=[]
func run()->void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"),"isolated facility recovery")
	if not failures.is_empty():get_tree().quit(1);return
	DataRegistry.load_all();UISettings.reset_skill_cutscene_history(false)
	var baseline:Dictionary={}
	for policy in ["off","once","once","always"]:
		var result:Dictionary=await effect(policy,false)
		if baseline.is_empty():baseline=result
		else:expect(result==baseline,"actual facility effects equal across policies")
	var automatic:Dictionary=await effect("always",true)
	expect(automatic==baseline,"actual facility AI effect identical")
	await heart_cap();await heart_art();await forge();await lifecycle();await invalidation()
	var file:=FileAccess.open("res://tmp/crown_facility_recovery/results.json",FileAccess.WRITE);file.store_string(JSON.stringify(proof,"\t"))
	print("CROWN_FACILITY_RECOVERY_TEST: %s (%d/%d)"%["PASS" if failures.is_empty() else "FAIL",checks-failures.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
func fixture(policy:String)->void:
	await setup_case("armored_beetle",policy)
	output_dir="res://tmp/crown_facility_recovery";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game.update4_active_run.campaign_mode_id=Modes.COUNCIL_MODE_ID
	game.update4_active_run.crown={"crown_form_id":"crown_toktok_royal_armorer","selected_instance_id":"monster_toktok"}
	game.update4_active_run.upper_floor={"crown_suppressed":false}
	game.update3_active_run.heart={"heart_id":"","awakened":false}
	var old=caster
	caster=game._create_unit("armored_beetle",game._scaled_monster_stats("armored_beetle"),Constants.FACTION_MONSTER,"barracks")
	caster.global_position=game.graph.center("barracks");caster.current_room="barracks";caster.assigned_room="barracks";caster.set_physics_process(false)
	old.queue_free();game.monster_units[0]=caster;game.selected_unit=caster
	game.rooms.barracks.hp=40;game.rooms.barracks.max_hp=100;game.rooms.barracks.disabled=false
	await settle()
func effect(policy:String,auto:bool)->Dictionary:
	await fixture(policy)
	var combat=game.combat_scene;var runtime=combat.crown_facilities;var action=combat.skill_actions
	var slots:Array=combat.skill_slots_for(caster);var slot:int=slots.find("royal_emergency_plating")
	expect(slot>=0 and runtime.target(caster)=="barracks","actual crown picks damaged placed barracks")
	var seen:bool=UISettings.skill_cutscene_seen.has("skill:royal_emergency_plating")
	for id in slots:
		if id!=null and str(id)!="royal_emergency_plating":caster.set_skill_cooldown(str(id),100)
	var accepted:bool=combat.try_auto_monster_skill(caster) if auto else combat.request_selected_skill(slot)
	expect(accepted,"real plating request")
	var shown:bool=policy=="always" or(policy=="once" and not seen)
	expect(action.is_active()==shown,"plating viewing policy")
	if action.is_active():
		expect(game.rooms.barracks.hp==40 and runtime.protections.is_empty(),"preparation no repair or protection")
		expect(action.actors[0].sprite_frames==caster.sprite.sprite_frames and caster.sprite_path.contains("crown_toktok"),"current native crown caster")
		expect(is_instance_valid(action.object_art) and action.target_art==null,"actual facility art instead of fake monster target")
		var snapshot:Dictionary=action.current.facility_snapshot
		expect(snapshot.room_id=="barracks" and snapshot.facility_id==str(game.rooms.barracks.facility_role) and not snapshot.layers.is_empty(),"actual placed facility snapshot and texture layers")
		action.tick(.4);await capture("plating_"+policy+("_auto" if auto else "_manual")+"_prepare")
		action.tick(.16)
		expect(action.caption.text.contains("수리 30"),"contact caption actual HP repaired")
		expect(action.object_status.text.contains("40 → 70/100"),"contact facility label shows actual HP before and after")
		await capture("plating_"+policy+("_auto" if auto else "_manual")+"_contact")
		action.skip();action.skip()
	for unit in game.monster_units+game.enemy_units:unit.set_physics_process(false)
	expect(game.rooms.barracks.hp==70 and GameState.mana==500 and caster.get_meta("royal_plating_uses")==1,"real repair30, zero mana, one use")
	expect(not combat.request_selected_skill(slot) and combat.hud._selected_unit_skill_summary(caster).contains("이번 전투 사용 완료"),"battle limit and native state")
	expect(is_equal_approx(caster.effective_move_speed(),caster.move_speed*.75),"real five-second movement penalty")
	var base:int=caster.effective_def()
	var damage:Dictionary=game._damage_update3_facility("barracks",20,"real_guard_probe")
	expect(int(damage.actual_hp_loss)==14 and game.rooms.barracks.hp==56,"actual facility incoming20 ->14")
	expect(int(runtime.contributions[caster.get_instance_id()].facility_hp_prevented)==6,"actual HP loss difference6, no overkill inflation")
	expect(caster.effective_def()==base+2,"last actual14HP loss produces forge2")
	caster._physics_process(5.01)
	expect(caster.crown_plating_move_timer==0.0 and is_equal_approx(caster.effective_move_speed(),caster.move_speed),"movement penalty expires independently of protection")
	game.combat_time=7.99;expect(is_equal_approx(runtime.damage_scale("barracks"),.70),"eight-second guard alive at7.99")
	game.combat_time=8.0;expect(runtime.damage_scale("barracks")==1.0,"guard expires atactualsimulationdeadline8")
	var outcome:Dictionary={"hp":game.rooms.barracks.hp,"mana":GameState.mana,"uses":caster.get_meta("royal_plating_uses"),"loss":damage.actual_hp_loss,"repair":runtime.contributions[caster.get_instance_id()].facility_repair_actual,"prevented":runtime.contributions[caster.get_instance_id()].facility_hp_prevented}
	proof.append({"policy":policy,"auto":auto,"outcome":outcome,"progression":"forced crown and controlledHP fixture; not earned unlock"})
	game.queue_free();await settle();return outcome
func heart_cap()->void:
	await fixture("off")
	var combat=game.combat_scene;var runtime=combat.crown_facilities
	game.update3_active_run.heart={"heart_id":"heart_stonebone","awakened":true,"disabled_this_battle":false,"room_shields":{}}
	var old_run:Dictionary=game.update3_active_run.duplicate(true)
	var ordinary:Dictionary=Heart.apply_repair(old_run,30,"ordinary",0)
	expect(int(ordinary.repair)==38 and game.update3_active_run==old_run,"ordinary heart repair boost preserved and service read is pure")
	var slot:int=combat.skill_slots_for(caster).find("royal_emergency_plating")
	expect(combat.request_selected_skill(slot) and game.rooms.barracks.hp==70,"royal finalrepair30cap afterexisting1.25heartboost")
	expect(int(game.update3_active_run.get("run_metrics_update3",{}).get("stonebone_repair_bonus",0))==0,"capped royal repair no phantom heartbonus")
	game.rooms.barracks.max_hp=300;game.rooms.barracks.hp=250
	game.update3_active_run.heart.room_shields={"barracks":10}
	game.update3_active_run.run_metrics_update3={}
	var hit:Dictionary=game._damage_update3_facility("barracks",100,"heart_guard")
	expect(int(hit.actual_hp_loss)==53 and game.rooms.barracks.hp==197,"royal70, heartshield10, heart.88 -> actual53")
	expect(int(game.update3_active_run.heart.room_shields.barracks)==0,"actual heartshield consumed once")
	expect(int(game.update3_active_run.run_metrics_update3.stonebone_facility_damage_reduced)==17,"discarded pure comparison never commits heart metrics twice")
	expect(int(runtime.contributions[caster.get_instance_id()].facility_hp_prevented)==26,"actual royal HP prevention79-53 aftersameheartkernel")
	game.queue_free();await settle()
func invalidation()->void:
	for boundary in ["replacement","floor","disabled","queued"]:
		await fixture("off")
		game.rooms.barracks.max_hp=101
		var combat=game.combat_scene;var runtime=combat.crown_facilities
		var slot:int=combat.skill_slots_for(caster).find("royal_emergency_plating")
		expect(combat.request_selected_skill(slot) and game.rooms.barracks.hp==70,"integer maxHP101 royal cap floor30 "+boundary)
		match boundary:
			"replacement":game.rooms.barracks.facility_role="recovery"
			"floor":game.rooms.barracks.runtime_floor_id="fixture_different_floor"
			"disabled":game.rooms.barracks.disabled=true
			"queued":caster.queue_free()
		expect(runtime.damage_scale("barracks")==1.0 and not runtime.protections.has("barracks"),"immediate guard invalidation "+boundary)
		game.queue_free();await settle()
func heart_art()->void:
	await fixture("always")
	# Create the existing placed-heart art through its production renderer. This
	# fixture forces heart placement; it does not establish natural heart unlock.
	game.rooms.heart_chamber={"facility_role":"heart_chamber","display_name":"심장실","hp":40,"max_hp":100,"disabled":false}
	game.update3_active_run.heart={"heart_id":"heart_stonebone","stage":2,"awakened":true}
	var renderer=game.quarter_renderer
	expect(renderer._show_heart_core_art(Rect2(game.graph.center("barracks"),Vector2(160,140))),"existing heart world art created")
	var sprite:Sprite2D=renderer.heart_core_sprite
	var before_transform:Transform2D=sprite.global_transform
	var children:int=sprite.get_parent().get_child_count()
	var snapshot:Dictionary=renderer.facility_cutscene_snapshot("heart_chamber")
	expect(snapshot.layers.size()==1 and snapshot.layers[0].texture==sprite.texture and snapshot.layers[0].material==sprite.material,"heart snapshot retains actual atlas and chroma material")
	var action=game.combat_scene.skill_actions
	var packet:Dictionary={"key":"facility_heart_art_probe","name":"심장 시설 그림 검증","actors":[caster],"animation":"skill_down","target":null,"facility_snapshot":snapshot}
	action.request(packet,func()->bool:game.rooms.heart_chamber.hp=70;return true)
	expect(is_instance_valid(action.object_art) and action.object_art.material==sprite.material,"independent heart cutscene canvas uses actual world chroma")
	expect(sprite.global_transform==before_transform and sprite.get_parent().get_child_count()==children,"heart snapshot and cutscene never mutate world sprite or add world nodes")
	await capture("plating_actual_heart_prepare")
	action.tick(.56)
	expect(action.object_status.text.contains("40 → 70/100"),"heart contact label reflects actual target HP")
	await capture("plating_actual_heart_contact")
	action.skip();game.queue_free();await settle()
func forge()->void:
	await fixture("off")
	var runtime=game.combat_scene.crown_facilities
	game.rooms.barracks.hp=100;var base:int=caster.effective_def()
	game._damage_update3_facility("barracks",35,"forge35")
	expect(caster.effective_def()==base+4,"forge actual last35 ->4")
	game._damage_update3_facility("barracks",1,"forge1")
	expect(caster.effective_def()==base+1,"next actual1 replaces, no cumulative repair or hit stacking")
	game._repair_update3_facility("barracks",10,"repair_not_damage")
	expect(caster.effective_def()==base+1,"repair never creates forge activation")
	game.rooms.barracks.hp=3;game._damage_update3_facility("barracks",1000,"overkill")
	expect(caster.effective_def()==base+1,"actual3HP overkillloss, notrequested1000 sixbonus")
	game._damage_update3_facility("barracks",1000,"zero_hp")
	expect(caster.effective_def()==base+1,"zero HP loss creates no new forge event")
	caster.global_position=game.graph.center("recovery")
	expect(caster.effective_def()==base and caster.crown_forge_bonus==0,"actual room exit clears bonus despite assignedbarracks")
	caster.global_position=game.graph.center("barracks")
	expect(caster.effective_def()==base,"reentry no stale forge reactivation")
	game.rooms.barracks.hp=40;game._damage_update3_facility("barracks",20,"newhit")
	game.update4_active_run.upper_floor.crown_suppressed=true
	expect(caster.effective_def()==base and caster.crown_forge_bonus==0,"current suppression immediately removes own forge layer")
	game.queue_free();await settle()
func lifecycle()->void:
	await fixture("always")
	var combat=game.combat_scene;var runtime=combat.crown_facilities
	var slot:int=combat.skill_slots_for(caster).find("royal_emergency_plating")
	expect(combat.request_selected_skill(slot),"stale target preparation")
	game.rooms.barracks.facility_role="recovery";combat.skill_actions.skip()
	expect(caster.get_meta("royal_plating_uses",0)==0 and game.rooms.barracks.hp==40 and runtime.protections.is_empty(),"changed actual facility cancels no use/repair")
	game.rooms.barracks.facility_role="barracks";combat.set_speed(3)
	expect(combat.request_selected_skill(slot),"menu valid plating")
	game._open_pause_menu()
	expect(game.combat_paused and caster.get_meta("royal_plating_uses")==1 and game.rooms.barracks.hp==70,"menu interruption one valid commit and pause")
	var clock:float=game.combat_time;await settle();expect(game.combat_time==clock and runtime.damage_scale("barracks")<1.0,"menu freezes actual protection deadline")
	game._close_pause_menu();expect(not game.combat_paused and game.combat_speed==3.0,"menu restores x3")
	game.update4_active_run.upper_floor.crown_suppressed=true
	expect(runtime.damage_scale("barracks")==1.0,"suppression immediate guardinvalid before damage")
	var encoded:String=JSON.stringify(game._campaign_save_payload("battle_start"))
	expect(not encoded.contains("crown_forge_bonus") and not encoded.contains("royal_plating_uses"),"checkpoint excludes transient actor royal effects/uses")
	combat.abandon_suspended_frame()
	expect(runtime.protections.is_empty() and caster.crown_plating_move_timer==0.0,"title checkpoint clears protection and penalty")
	game.queue_free();await settle()
