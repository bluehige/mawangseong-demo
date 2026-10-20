extends Node

const Game = preload("res://scenes/game/GameRoot.tscn")
const Expansion = preload("res://scripts/systems/council/CouncilExpansionService.gd")
const Objective = preload("res://scripts/systems/council/CouncilObjectiveService.gd")
const Season = preload("res://scripts/systems/campaign/CouncilSeasonService.gd")
const Runtime = preload("res://scripts/systems/campaign/Update4CampaignRuntimeService.gd")
const PlotState = preload("res://scripts/map_builder/PlotSaveState.gd")
const Build = preload("res://scripts/map_builder/MapBuildService.gd")
const Migrator = preload("res://scripts/systems/save/SaveV5ToV6Migrator.gd")
var game
var failures: Array[String] = []
var checks := 0
const OUT := "res://tmp/v130_council/"
func _ready() -> void: call_deferred("run")
func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label); print("FAIL: ",label)
func settle(count: int = 3) -> void:
	for i in range(count): await get_tree().process_frame
func capture(id: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	await settle(); await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+id+".png")
func run() -> void:
	DataRegistry.load_all()
	game = Game.instantiate(); game.campaign_save_enabled = false; add_child(game); await settle()
	game.onboarding_enabled=false; game.tutorial_gate_enabled=false; game.tutorial_manager.active=false
	game.story_feature_enabled=false; game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
	game.set_physics_process(false)
	game.update4_active_run.campaign_mode_id = "council_season"
	game.update4_profile.campaign_modes.council_season_unlocked=true
	game.update4_active_run.council_season.selected_regions=["region_ironbell_ravine","region_moonbat_aerie","region_mistcap_marsh"]
	game.update4_active_run.council_season.current_region_index=0
	game.update4_active_run.council_season.final_representative_id="rival_brassa"
	test_dates()
	test_objectives()
	await test_maps_and_battle()
	test_migration()
	await test_save_continue()
	var f := FileAccess.open(OUT+"checks.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t")); f.close()
	game._shutdown_audio_for_exit(); game.queue_free(); await settle(3)
	print("V130_COUNCIL_1F_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
func test_dates() -> void:
	var state := Season.new_day_state()
	for day in range(1,31):
		var start := Season.start_day(state,day,DataRegistry.update4_council_campaign_days)
		expect(start.ok,"DAY%d enter"%day); state=start.state
		var prepared := Season.finish_management(state,DataRegistry.update4_council_campaign_days)
		expect(prepared.ok,"DAY%d management"%day); state=prepared.state
		if not Season.is_management_only(DataRegistry.update4_council_campaign_days,day):
			var combat := Season.begin_combat(state,DataRegistry.update4_council_campaign_days)
			expect(combat.ok,"DAY%d combat"%day)
			var completed := Season.complete_combat(combat.state); expect(completed.ok,"DAY%d complete"%day); state=completed.state
		if day < 30:
			var next := Season.advance_day(state,DataRegistry.update4_council_campaign_days); expect(next.ok,"DAY%d advance"%day); state=next.state
		var run := Expansion.unlock_if_due(game.update4_active_run,day,DataRegistry.update4_expansion_modules,1)
		if day in [16,17,18,27]:
			expect(run.expansion.unlocked,"DAY%d objectives unlock independent of grade"%day)
			expect(Runtime.required_choice_id(run,day) != "upper_layout","DAY%d no removed layout gate"%day)
		var wave := Runtime.wave_catalog_for_day(run,day,DataRegistry.update4_council_wave_templates,DataRegistry.update4_rival_lords,DataRegistry.waves)
		if day in [25,30]:
			var boss: Dictionary=wave["day_%d"%day][-1]
			expect(boss.spawn_delay==(8.0 if day==25 else 6.0) and boss.hp_scale==(0.75 if day==25 else 1.0) and boss.atk_scale==(0.90 if day==25 else 1.0),"DAY%d boss stats unchanged"%day)
func test_objectives() -> void:
	var modules: Dictionary=DataRegistry.update4_expansion_modules
	expect(modules.size()==3 and not modules.has("upper_stair_landing"),"three retained objective/facility modules; no transition module")
	var active:=Expansion.unlock_if_due(game.update4_active_run,16,modules,3)
	expect(active.expansion.objective_hp.crown_sanctum==600 and Objective.crown_max_hp(modules,4)==660,"crown HP600/660 unchanged")
	var destroyed:=Objective.damage_crown_sanctum(active,600)
	expect(destroyed.destroyed and destroyed.active_run.expansion.crown_suppressed and not destroyed.castle_defeat,"crown disable is auxiliary failure")
	expect(destroyed.active_run.expansion.disable_count_since_day16==1,"real disable recorded once")
	var duplicate:=Objective.damage_crown_sanctum(destroyed.active_run,10)
	expect(duplicate.active_run.expansion.disable_count_since_day16==1,"duplicate damage cannot add disables")
	var repaired:=Objective.repair_next_day(destroyed.active_run,modules,3)
	expect(repaired.expansion.objective_hp.crown_sanctum==600 and repaired.expansion.repair_cost_gold==24 and not repaired.expansion.crown_suppressed,"next-day repair HP/cost unchanged")
	active.council_season.council_votes=12; active.council_season.council_seals=2
	var battle:=Objective.start_seal_theft(Objective.new_battle_objectives(active,modules),modules)
	battle=Objective.tick_seal_theft(battle,2.9); expect(battle.seal_theft.warning_remaining>0 and not battle.seal_theft.ready_to_settle,"3s warning boundary")
	battle=Objective.tick_seal_theft(battle,0.1+3.9); expect(not battle.seal_theft.ready_to_settle,"4s channel boundary")
	battle=Objective.tick_seal_theft(battle,0.1)
	var settled:=Objective.settle_seal_theft(active,battle,modules)
	expect(settled.active_run.council_season.council_votes==7 and settled.active_run.expansion.seal_theft_count==1 and not settled.castle_defeat,"one theft costs5 votes; throne unaffected")
	var second:=Objective.settle_seal_theft(settled.active_run,settled.battle_state,modules)
	expect(second.active_run.council_season.council_votes==7,"one loss maximum per battle")
	active.council_season.council_votes=2
	settled=Objective.settle_seal_theft(active,battle,modules)
	expect(settled.active_run.council_season.council_votes==2 and settled.active_run.council_season.council_seals==1,"insufficient votes cost1 seal")
func all_paths(label: String) -> void:
	expect(game.graph.validation_summary().ok,label+" graph valid")
	for id in game.graph.module_instance_ids():
		if game.graph.module_data_for_instance(id).get("module_type","")=="room": expect(not game.graph.path_between("entrance",id).is_empty(),label+" reachable "+id)
func set_day(day: int) -> void:
	GameState.day=day
	game.update4_active_run.council_season.day_state=Season.new_day_state(day)
	game.update4_active_run=Expansion.unlock_if_due(game.update4_active_run,day,DataRegistry.update4_expansion_modules,game._castle_stage_index())
	game._setup_dungeon_graph()
	game._set_screen("management",false)
func test_maps_and_battle() -> void:
	var fixture_outpost := preload("res://scripts/systems/outpost/OutpostService.gd").build(game.update4_profile,game.update4_active_run,"outpost_watch_nest",4,DataRegistry.update4_outpost_types)
	expect(fixture_outpost.ok,"DAY4 outpost prerequisite is prepared before capturing later management")
	game.update4_active_run=fixture_outpost.active_run
	set_day(15); expect(not game.update4_active_run.expansion.unlocked,"DAY15 preview only")
	set_day(16); all_paths("DAY16 temporary")
	expect(game.graph.layout.plot_grid.size==[30,20],"DAY16 no free plot expansion")
	expect(game.update4_active_run.expansion.temporary and not game.update4_active_run.expansion.eligible,"undergrade temporary cannot earn E18")
	await capture("day16_temporary")
	var old_gold: int=GameState.gold
	var old_infamy: int=GameState.infamy
	GameState.gold=0; GameState.infamy=0; game.campaign_stage_two_upgrade_funded=false; game.campaign_stage_two_unlock_ready=false
	game._apply_council_plot_progression(true)
	expect(game._castle_stage_index()==1 and game.graph.layout.plot_grid.size==[30,20],"insufficient existing grade budget does not expand plot")
	GameState.gold=720; GameState.infamy=720
	game._apply_council_plot_progression(true)
	expect(game._castle_stage_index()==2 and game.graph.layout.plot_grid.size==[36,20],"delayed existing grade qualification opens exactly6 cells")
	expect(GameState.gold==720 and GameState.infamy==720,"castle qualification checks holdings without spending either resource")
	expect(game.plot_unlock_history[-1].day==16,"delayed grade records actual unlock day")
	GameState.gold=old_gold; GameState.infamy=old_infamy
	game.runtime_plot_layout.clear()
	set_day(18); all_paths("DAY18 expanded")
	var placement: Dictionary=game.update4_active_run.expansion
	expect(placement.rooms.size()==2,"two real first-floor objective sites")
	expect(placement.eligible and not placement.temporary,"grade expansion moves both objectives into expanded land")
	await capture("day18_expanded")
	for day in [17,18,23,27,30]:
		set_day(day); all_paths("DAY%d"%day)
		expect(game._quarter_layout_for_graph().has("plot_grid"),"DAY%d council uses M6"%day)
		if day==23:
			game.update4_active_run.council_season.crown_declined=true
			expect(Runtime.required_choice_id(game.update4_active_run,23)=="","DAY23 decline keeps progression")
	set_day(30)
	# Identical species remain separate instances; later movement cannot change assignments.
	var a=game._create_unit("slime",DataRegistry.monster("slime"),"monster","entrance")
	var b=game._create_unit("slime",DataRegistry.monster("slime"),"monster",placement.rooms.crown_sanctum)
	a.global_position=game.graph.center("entrance"); b.global_position=game.graph.center(placement.rooms.crown_sanctum)
	a.set_physics_process(false); b.set_physics_process(false); game.monster_units=[a,b]
	game._prepare_update4_council_battle()
	var before:=Expansion.survivors(game.update4_active_run.expansion,game.monster_units)
	expect(before.original==1 and before.expansion==1,"DAY30 instance assignment has both zones")
	a.global_position=b.global_position; b.global_position=game.graph.center("entrance")
	expect(Expansion.survivors(game.update4_active_run.expansion,game.monster_units)==before,"support movement never changes assigned zone")
	a.hp=0; expect(Expansion.survivors(game.update4_active_run.expansion,game.monster_units).original==0,"fallen assigned unit not counted")
	a.hp=a.max_hp
	game.combat_scene.spawn_enemy("bronze_automaton")
	var enemy=game.enemy_units[-1]; enemy.set_physics_process(false); enemy.global_position=game.graph.center(placement.rooms.crown_sanctum); enemy.current_room=placement.rooms.crown_sanctum; enemy.attack_cooldown=0
	a.global_position=game.graph.center("entrance"); b.global_position=a.global_position; a.current_room="entrance"; b.current_room="entrance"
	var hp:=int(game.update4_active_run.expansion.objective_hp.crown_sanctum)
	game.combat_scene.council_objectives.tick(1.0/60.0)
	expect(int(game.update4_active_run.expansion.objective_hp.crown_sanctum)==hp-int(enemy.atk),"actual enemy arrival damages crown with unchanged ATK")
	game.update4_active_run.council_season.council_votes=12
	game.combat_scene.native_objectives.clear()
	game.combat_scene.spawn_enemy("dusk_courier")
	var dusk=game.enemy_units[-1]; dusk.set_physics_process(false); dusk.global_position=game.graph.center(placement.rooms.seal_vault); dusk.current_room=placement.rooms.seal_vault
	var channels: Dictionary=game.combat_scene.native_objectives.channels
	expect(channels.has(dusk.get_instance_id()),"actual first-floor vault channel registered")
	if channels.has(dusk.get_instance_id()):
		game.combat_scene.native_objectives._start(dusk,channels[dusk.get_instance_id()])
		game.combat_scene.native_objectives.tick(2.9)
		expect(channels[dusk.get_instance_id()].warning_remaining>0 and channels[dusk.get_instance_id()].state.channel_remaining==4.0,"actual vault waits3s before4s collection")
		game.combat_scene.native_objectives.tick(0.1)
		game.combat_scene.native_objectives.tick(4.0)
		expect(game.update4_active_run.council_season.council_votes==7,"actual first-floor vault applies exactly5 vote loss")
	game.combat_scene.native_objectives.clear(); game.update4_active_run.council_season.council_votes=12
	dusk.hp=0
	game.combat_scene.spawn_enemy("rival_vesper_council_champion")
	var vesper=game.enemy_units[-1]; vesper.set_physics_process(false)
	var dive_entry: Dictionary=game.combat_scene.native_objectives.channels.get(vesper.get_instance_id(),{})
	expect(str(dive_entry.get("phase",""))=="dive_warning","Vesper uses connected first-floor dive entrance")
	if not dive_entry.is_empty():
		game.combat_scene.native_objectives._tick_dive(vesper,dive_entry,1.5)
		game.combat_scene.native_objectives._tick_dive(vesper,dive_entry,0.35)
		expect(game.graph.is_walkable(vesper.global_position),"Vesper intermediate point remains on actual safe route")
		game.combat_scene.native_objectives._tick_dive(vesper,dive_entry,0.35)
		expect(vesper.current_room==placement.rooms.seal_vault and vesper.current_room!="throne" and str(dive_entry.phase)=="moving","existing0.7s dive arrives via vault passage without throne teleport")
	LanguageSettings.set_locale("en",false); game._set_screen("expansion",false); await settle(); await capture("objectives_en")
	LanguageSettings.set_locale("zh_CN",false); game._set_screen("expansion",false); await settle(); await capture("objectives_zh_cn")
	LanguageSettings.set_locale("ko",false)
func test_migration() -> void:
	var old: Dictionary=game.update4_active_run.duplicate(true); old.erase("expansion")
	old.upper_floor={"unlocked":true,"objective_hp":{"crown_sanctum":0},"crown_suppressed":true,"seal_theft_count":2,"graph_runtime":{"visible_floor":"2F","entities":{"legacy":{"floor_id":"2F"}},"transition_queues":{"1F>2F":["legacy"]}},"layout_id":"upper_compact_guard","layout_locked":true}
	old.run_metrics_update4={"ending":{"upper_floor_integrity":100,"day30_upper_floor_contribution_ratio":0.8,"day30_upper_survivor_count":8}}
	var original:=JSON.stringify(old)
	var converted:=Expansion.convert_active(old)
	expect(JSON.stringify(old)==original,"legacy state input untouched")
	expect(not converted.has("upper_floor") and not converted.expansion.has("graph_runtime"),"legacy floor queues and entities discarded")
	expect(converted.expansion.objective_hp.crown_sanctum==0 and converted.expansion.crown_suppressed,"disabled crown HP is transferred without free heal")
	expect(not converted.expansion.record_complete and not converted.expansion.eligible,"historical defense never proves expansion performance")
	expect(not converted.run_metrics_update4.ending.has("day30_expansion_survivor_ratio"),"old ratios never become new zone ratios")
	expect(Expansion.convert_active(converted)==converted,"conversion idempotent")
	var source: Dictionary=game._plot_save_state()
	expect(PlotState.validate(source)=="","council objective source validates for v6 save")
	var envelope:={"version":6,"active_run":old,"profile":{"update4_endings_seen":["E18"],"cosmetic_ids":["upper_floor_epilogue_layout"],"unlocked_reward_ids":["cosmetic_upper_floor_epilogue_layout","chronicle_floor_detail"]}}
	envelope.active_run.plot_state=source
	var migrated:=Migrator.convert_council(envelope)
	expect(migrated.active_run.plot_state==source,"v6 coordinates and unlock dates unchanged during council conversion")
	expect(migrated.profile.update4_endings_seen==["E18"] and migrated.profile.chronicle.zone_detail_unlocked,"historical E18/rewards retained with equivalent zone detail")
func test_save_continue() -> void:
	GameState.player_name="Council fixture"
	GameState.onboarding_complete=true
	game.enemy_units.clear(); game.monster_units.clear()
	game.update4_active_run.council_season.selected_regions=["region_ironbell_ravine","region_moonbat_aerie"]
	game.update4_active_run.council_season.current_region_index=1
	set_day(18)
	var outpost_service=preload("res://scripts/systems/outpost/OutpostService.gd")
	var active: Dictionary=game.update4_active_run.duplicate(true)
	active.outpost=preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd").default_outpost()
	var built: Dictionary=outpost_service.build(game.update4_profile,active,"outpost_watch_nest",4,DataRegistry.update4_outpost_types)
	expect(built.ok,"save fixture uses valid existing outpost service")
	game.update4_active_run=built.active_run
	game.campaign_cycle_index=2; game.update2_cycle_seed=13018
	game.update4_profile.update4_endings_seen=["E18"]
	game.update4_profile.cosmetic_ids=["upper_floor_epilogue_layout"]
	game.update4_profile.unlocked_reward_ids=["cosmetic_upper_floor_epilogue_layout","chronicle_floor_detail"]
	game.campaign_save_enabled=true; game.campaign_save_v6_enabled=true
	game.campaign_save_v5_envelope.clear()
	game._set_campaign_save_path_for_tests(OUT+"continue_v1.json",OUT+"continue_v2.json",OUT+"continue_v3.json",OUT+"continue_v4.json",OUT+"continue_v5.json",OUT+"continue_v6.json")
	game._set_screen("management",false)
	var source: Dictionary=game._plot_save_state()
	expect(game._write_campaign_v6_snapshot(),"actual council v6 snapshot: "+game.campaign_save_error)
	game._refresh_campaign_save_status()
	expect(game.campaign_save_status=="valid","v6 Continue preflight: "+game.campaign_save_error)
	game._continue_campaign_save(); await settle()
	expect(GameState.day==18 and game.current_screen=="management","council Continue preserves DAY18 checkpoint")
	var restored_source: Dictionary=game._plot_save_state()
	var debug_save := FileAccess.open(OUT+"continue_sources.json",FileAccess.WRITE)
	debug_save.store_string(JSON.stringify({"before":source,"after":restored_source},"\t"));debug_save.close()
	expect(JSON.parse_string(JSON.stringify(restored_source))==JSON.parse_string(JSON.stringify(source)),"council Continue preserves objective coordinates/rotation/history")
	expect(not game.update4_active_run.has("upper_floor") and game.update4_active_run.expansion.unlocked,"Continue does not recreate upper runtime")
	expect(game.update4_profile.update4_endings_seen==["E18"] and "upper_floor_epilogue_layout" in game.update4_profile.get("cosmetic_ids",[]),"Continue keeps E18 and cosmetic reward IDs")
	all_paths("Continue council")
	game.campaign_save_enabled=false
