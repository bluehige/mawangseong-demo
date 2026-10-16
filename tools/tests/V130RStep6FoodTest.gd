extends Node
const Food = preload("res://scripts/systems/MonsterFoodService.gd")
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
const Recruits = preload("res://scripts/map_builder/ApprovedRecruitment.gd")
const OUT := "res://tmp/v130r_step6/"
var preview: Node
var game: Node
var view: Control
var checks := 0
var failures: Array[String] = []
var evidence := {}
var capture := false
func _ready() -> void: run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL ",message)
func dump(path: String, value) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(value,"\t")); file.close()
func boot() -> void:
	preview = load("res://scenes/map_builder/ApprovedPlacementPreview.tscn").instantiate(); add_child(preview)
	await get_tree().create_timer(.25).timeout
	game = preview.game
	view = game.ui_layer.get_node("ApprovedMapManagement")
	view.placement = Buildings.initial(game,"F"); view.placement.food_state = Food.fresh()
	view.monster_ui.joined = []; view.monster_ui.assignments = {}
	GameState.day = 1; GameState.food_state = Food.fresh(); GameState.food_income = 15
	GameState.max_day = 30; GameState.food = 18; GameState.demon_lord_hp = 1500; GameState.demon_lord_max_hp = 1500
	get_window().size = Vector2i(1920,1080)
	view.render_map(); view.update_wallet()
	await get_tree().process_frame
func direct() -> void:
	for day in range(1,31):
		var stage := 1 if day<=14 else 2 if day<=19 else 3 if day<=26 else 4
		expect(Food.income(day)==[15,23,30,34][stage-1],"DAY %d stage income" % day)
		expect(Food.capacity(day)==[30,45,60,75][stage-1],"DAY %d storage" % day)
	var all_species: Array = Food.COSTS.keys()
	var total := 0
	for cost in Food.COSTS.values(): total += cost
	expect(total==29 and all_species.size()==14,"14 original members cost 29; no new ten")
	var empty := Food.settle(18,1,[],Food.fresh())
	expect(empty.food==30 and empty.ledger.paid==0 and empty.ledger.overflow==3,"waiting free and cap surplus")
	var short := Food.settle(0,1,all_species,Food.fresh())
	expect(short.food==0 and short.ledger.due==29 and short.ledger.paid==15 and short.ledger.shortfall==14,"partial rations preserve nonnegative balance")
	expect(not short.state.hungry.is_empty(),"unpaid individuals hungry")
	var reordered := all_species.duplicate(); reordered.reverse()
	expect(Food.settle(0,1,reordered,Food.fresh()).ledger==short.ledger,"allocation independent of placement order")
	var duplicate := Food.settle(0,1,all_species,short.state)
	expect(duplicate.already_settled and duplicate.food==0,"same day cannot charge twice")
	var recovered := Food.settle(30,2,all_species,short.state)
	expect(recovered.state.hungry.is_empty() and recovered.ledger.paid==29,"full rations clear hunger")
	var rested := Food.settle(0,2,[],short.state)
	expect(rested.state.hungry.is_empty(),"reserves recover at next settlement")
	expect(Food.settle(0,1,["slime","slime","unknown"],Food.fresh()).ledger.due==1,"duplicate/unknown IDs cannot double-charge")
	expect(Food.migrate({"hungry":7,"owned":false,"last_day":"bad"},1)==Food.fresh(),"malformed optional migration defaults")
	# Actual GameState migration of old fields, bonuses and new round trip.
	var legacy := GameState.campaign_snapshot(); legacy.erase("food_state"); legacy.food_income = 6; legacy.food = 99
	for version in ["1.2.12","1.3.0"]:
		legacy.day = 15 if version=="1.3.0" else 1
		expect(GameState.restore_campaign_snapshot(legacy),version+" legacy snapshot opens")
		expect(GameState.food_income==Food.income(int(legacy.day)) and GameState.food==Food.capacity(int(legacy.day)),version+" income and cap migrate")
	legacy.food_income = 10
	expect(GameState.restore_campaign_snapshot(legacy) and GameState.food_income==27,"legacy decree income bonus retained")
	var current := GameState.campaign_snapshot(); current.food_state = short.state
	expect(GameState.restore_campaign_snapshot(current) and GameState.is_hungry(str(short.state.hungry[0])),"new hunger round trip")
	GameState.day = 1; GameState.food_income = 15; GameState.food = 4; GameState.food_state = Food.fresh()
	GameState.add_rewards({"food":10}); expect(GameState.food==14,"expedition/decree reward retained below cap")
	GameState.add_rewards({"food":99}); expect(GameState.food==30,"rewards respect cap")
	GameState.food = 18; GameState.advance_day(); expect(GameState.food==18,"next day no duplicate income")
	GameState.day = 14; GameState.food_income = 19; GameState.advance_day()
	expect(GameState.food_income==27,"stage transition keeps income bonus")
	expect(game._apply_update3_daily_heart_upkeep()==0,"old hungry heart tax superseded")
	expect(not game._facility_base_definition("barracks").cost.has("food"),"barracks no food cost")
	for rule in view.placement.catalog.values(): expect(not rule.cost.has("food"),"construction cost excludes food")
	# Canonical contract conditions take priority over fallback DAY.
	game.selected_contract_ids.clear()
	var eligible := Recruits.eligible(game,view.monster_ui.members,30)
	expect(eligible.size()==4,"DAY30 alone does not bypass contracts/fronts/council")
	game.selected_contract_ids.assign(["spore_healer","stone_sentinel"])
	eligible = Recruits.eligible(game,view.monster_ui.members,1)
	expect("mon_contract_mori" in eligible and "mon_contract_dolkong" in eligible,"existing chosen contracts win over DAY7/9")
	expect("mon_contract_lumi" not in eligible,"unchosen contract remains locked")
	game.update3_profile["fronts"] = {"clear_counts":{}}
	var ext: Dictionary = DataRegistry.update3_monster_extensions.ghost_housemaid
	game.update3_profile.fronts.clear_counts[ext.unlock_condition.front_id] = 1
	expect("monster_bebe" in Recruits.eligible(game,view.monster_ui.members,1),"existing front condition grants Bebe eligibility")
	# Fresh copies of genuine existing test fixtures use the normal Continue route.
	for folder in ["legacy_v5","plot_v6"]:
		var prefix: String = OUT+"copies/run_%d_" % OS.get_process_id()+folder+"/"
		var filename: String = "campaign_save_v5.json" if folder=="legacy_v5" else "campaign_save_v6.json"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(prefix))
		var source: String = prefix+filename
		expect(DirAccess.copy_absolute(ProjectSettings.globalize_path("res://tools/tests/fixtures/v130r_food/"+filename),ProjectSettings.globalize_path(source))==OK,"fresh isolated fixture "+folder)
		expect(FileAccess.file_exists(source),folder+" fixture copy exists")
		var source_hash := FileAccess.get_sha256(source)
		var raw = JSON.parse_string(FileAccess.get_file_as_string(source))
		var expected_roster: Dictionary = raw.active_run.legacy_payload.world.monster_roster
		game._set_campaign_save_path_for_tests(prefix+"campaign_save_v1.json",prefix+"campaign_save_v2.json",prefix+"campaign_save_v3.json",prefix+"campaign_save_v4.json",prefix+"campaign_save_v5.json",prefix+"campaign_save_v6.json")
		expect(game.campaign_save_status=="valid",folder+" existing loader validates "+game.campaign_save_error)
		game._continue_campaign_save(); await get_tree().process_frame
		expect(game.current_screen==Constants.SCREEN_MANAGEMENT,folder+" normal Continue opens management")
		for species in expected_roster: expect(game.monster_roster.has(species),folder+" roster retained "+str(species))
		expect(GameState.food<=Food.capacity(GameState.day),folder+" migrated food within storage")
		expect(FileAccess.get_sha256(source)==source_hash,folder+" fixture source unchanged")
		evidence[folder] = {"status":game.campaign_save_status,"day":GameState.day,"food":GameState.food,"roster":game.monster_roster.keys()}
		game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
		game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false; game.campaign_save_v4_enabled = false; game.campaign_autosave_pending = false
	var saved_hunger := Food.fresh(); saved_hunger.hungry = ["slime"]
	GameState.food_state = saved_hunger
	game.campaign_save_enabled = true; game.campaign_save_v6_enabled = true
	game.campaign_save_v6_path = OUT+"copies/roundtrip_v6.json"
	expect(game._write_campaign_v6_snapshot(),"new food state v6 write: "+game.campaign_save_error)
	var stored = JSON.parse_string(FileAccess.get_file_as_string(game.campaign_save_v6_path))
	expect(stored.active_run.legacy_payload.game_state.food_state.hungry==["slime"],"new v6 contains hunger")
	GameState.food_state = Food.fresh()
	for setting in ["debug/approved_map_step2","debug/approved_map_step5","debug/approved_map_step6"]: ProjectSettings.set_setting(setting,false)
	expect(game._restore_campaign_payload(stored.active_run.legacy_payload) and GameState.is_hungry("slime"),"new file roundtrip restores hunger")
	game.campaign_save_enabled = false; game.campaign_save_v6_enabled = false; game.campaign_autosave_pending = false
	# Outpost/legacy result screens can reach next day without a defense ledger.
	var prior_day: int = GameState.day
	GameState.food = 0; GameState.food_income = Food.income(prior_day); GameState.food_state = Food.fresh()
	game._advance_after_result()
	expect(GameState.day==prior_day+1,"legacy result callback advances day")
	expect(GameState.food_state.last_day==prior_day and GameState.food_state.last.income==Food.income(prior_day),"legacy result without defense ledger still settles daily rations")
	# Release the legacy renderer/Continue state before a fresh spatial battle fixture.
	game._shutdown_audio_for_exit(); preview.queue_free(); await get_tree().process_frame
	await boot()
	# Live Unit attack and actual aura healing under hunger.
	GameState.day = 1; GameState.food_income = 15; GameState.food_state = short.state
	view = game.ui_layer.get_node_or_null("ApprovedMapManagement")
	if view==null: game._set_screen(Constants.SCREEN_MANAGEMENT); view = game.ui_layer.get_node("ApprovedMapManagement")
	view.placement = Buildings.initial(game,"E"); view.placement.day = 1; view.placement.food_state = short.state
	view.monster_ui.unlock_all = true
	view.monster_ui.assignments = Members.auto_place(view.placement,view.monster_ui.members,view.monster_ui.members.keys(),100)
	view.render_map()
	expect(view.start_battle(),"actual map battle begins")
	var battle = view.battle; battle.set_pause_state(true); view.set_physics_process(false)
	var hungry: Node
	for unit in game.monster_units:
		var base: int = view.monster_ui.members[unit.get_meta("instance_id")].stats.atk
		var is_hungry: bool = unit.unit_id in short.state.hungry
		expect(unit.atk==(maxi(1,roundi(base*.8)) if is_hungry else base),"actual attack stat "+str(unit.unit_id))
		if is_hungry: hungry = unit
	expect(hungry!=null,"hungry deployed unit exists")
	if hungry!=null:
		for id in battle.map.layout.influence:
			if battle.map.rooms[id].facility_role!="recovery": continue
			for c in battle.map.layout.influence[id]:
				if battle.map.is_road(c): hungry.position = battle.map.world(c); break
			break
		hungry.hp = hungry.max_hp-30; var hp: int = hungry.hp
		battle.update_room_effects(1); expect(hungry.hp==hp,"hungry unit receives zero actual recovery-nest healing")
		hungry.set_meta("food_hungry",false); battle.update_room_effects(1)
		expect(hungry.hp>hp,"same aura heals fed unit")
		hungry.hp = hungry.max_hp-30; hp = hungry.hp; hungry.set_meta("food_hungry",true)
		expect(hungry.heal(10)>0 and hungry.hp>hp,"support/direct healing remains allowed")
	battle.running = false; battle._clear_active_combat_tweens()
	# Simulation executes the same runtime settle() for both deployments.
	var simulations := {}
	for scenario in ["recommended","full_14"]:
		var stock := 18; var state := Food.fresh(); var rows: Array = []
		for day in range(1,31):
			var layout := Buildings.initial(game,"E"); layout.day = day
			var assignments := Members.auto_place(layout,view.monster_ui.members,view.monster_ui.members.keys(),Food.income(day) if scenario=="recommended" else 100)
			var deployed: Array = []
			for id in assignments: deployed.append(view.monster_ui.members[id].species_id)
			var result := Food.settle(stock,day,deployed,state)
			expect(result.food>=0 and result.food<=Food.capacity(day),scenario+" balance DAY"+str(day))
			result.ledger["count"] = assignments.size(); result.ledger["deployed"] = deployed
			rows.append(result.ledger); stock = result.food; state = result.state
			simulations[scenario] = rows
	dump(OUT+"simulation.json",simulations)
func shot(name: String) -> void:
	await get_tree().create_timer(.12).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==Vector2i(1920,1080),name+" actual 1920x1080 viewport")
	expect(image.save_png(OUT+name+".png")==OK,name+" PNG written")
func visual() -> void:
	view.monster_ui.unlock_all = true
	view.placement = Buildings.initial(game,"F"); view.placement.day = 7; view.placement.food_state = Food.fresh()
	view.placement.food_state.owned = view.monster_ui.members.keys()
	view.monster_ui.joined = view.monster_ui.members.keys()
	view.placement.resources.food = 0; view.monster_ui.food_income = Food.income(7)
	view.set_preview_day(7)
	view.monster_ui.assignments = Members.auto_place(view.placement,view.monster_ui.members,view.monster_ui.members.keys(),100)
	view.render_map(); view.monster_ui.set_mode("place"); view.update_wallet()
	await shot("food_01_hud")
	expect(view.start_battle(),"capture live battle start")
	var battle = view.battle; battle.set_pause_state(true); view.set_physics_process(false)
	# The result transition is real, with an explicitly forced win for this focused UI fixture.
	battle.finish_combat(true,"식량 정산 확인용 방어 성공")
	await get_tree().create_timer(.5).timeout
	expect(game.result_summary.get("food_ledger",{}).get("due",0)==29,"actual result charged all 14")
	expect(game.ui_layer.has_node("FoodSettlementPanel"),"actual settlement inset visible")
	await shot("food_02_settlement")
	game._advance_after_result()
	await get_tree().create_timer(.35).timeout
	view = game.ui_layer.get_node("ApprovedMapManagement")
	expect(view.placement.day==8,"real result next-day callback")
	view.monster_ui.unlock_all = true; view.start_battle(); view.battle.set_pause_state(true); view.set_physics_process(false)
	var hungry: Node
	for unit in game.monster_units:
		if bool(unit.get_meta("food_hungry",false)): hungry = unit; break
	expect(hungry!=null,"next actual battle contains hungry units")
	if hungry!=null:
		view.battle_ui.select_unit(hungry)
		expect(view.battle_ui.skills.find_child("HungryStatus",true,false)!=null,"selected hungry unit explains both restrictions")
	await shot("food_03_hungry")
	view.battle.finish_combat(true,"굶주림 다음 전투 확인")
	await get_tree().create_timer(.35).timeout
	game._advance_after_result()
	await get_tree().create_timer(.25).timeout
	view = game.ui_layer.get_node("ApprovedMapManagement")
	# Existing two-choice contract selection -> existing dialogue UI -> roster add.
	Grade.stash(game,view.placement,view.monster_ui.assignments)
	for id in ["mon_contract_mori","mon_contract_dolkong"]: view.placement.food_state.owned.erase(id)
	for species in ["spore_healer","stone_sentinel"]: game.monster_roster.erase(species)
	Grade.stash(game,view.placement,view.monster_ui.assignments)
	game.selected_contract_ids.clear(); game.contract_board_pending_ids.clear()
	view.request_join("mon_contract_mori")
	expect(game.current_screen==Constants.SCREEN_CONTRACT_BOARD,"locked card opens existing contract board")
	game._toggle_contract_candidate("spore_healer"); game._toggle_contract_candidate("stone_sentinel")
	game._confirm_contract_selection()
	await get_tree().create_timer(.2).timeout
	expect(game.current_screen==Constants.SCREEN_DIALOGUE,"existing contract conditions enter actual dialogue")
	expect("mon_contract_mori" not in Grade.load_session(game).layout.food_state.owned,"not added before scene closes")
	await shot("join_01_scene")
	game._onboarding_advance_dialogue(); game._onboarding_advance_dialogue()
	await get_tree().create_timer(.2).timeout
	view = game.ui_layer.get_node("ApprovedMapManagement")
	expect("mon_contract_mori" in view.monster_ui.unlocked(),"Mori added after final dialogue")
	expect("mon_contract_dolkong" in view.monster_ui.unlocked(),"Dolkong added after final dialogue")
	expect(Members.load_copy(view.placement,view.monster_ui.members,Grade.save_path()).layout.food_state.owned==view.placement.food_state.owned,"joined roster saved and reopens")
	game.selected_contract_ids.clear()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await get_tree().process_frame
	view = game.ui_layer.get_node("ApprovedMapManagement")
	expect(game.selected_contract_ids==["spore_healer","stone_sentinel"],"reopening restores same two contracts, no extra pair")
func run() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	await boot()
	if capture: await visual()
	else: await direct()
	game.campaign_autosave_pending = false; game._shutdown_audio_for_exit()
	if is_instance_valid(view) and view.battle!=null:
		view.battle.running = false; view.battle._clear_active_combat_tweens()
	preview.queue_free(); await get_tree().process_frame
	dump(OUT+("capture" if capture else "direct")+"_result.json",{"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"evidence":evidence})
	print("FOOD ",checks," checks; failures ",failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
