extends "res://tools/tests/V130RStep10DCTest.gd"
## Paid, isolated daily benchmarks. No campaign save is read or written.
const OUT10B := "res://_mockup/game_step10b_dc_spread/"
var owned_layouts := {}
var daily_wallets := {}
var economy: Array = []
var purchases: Array = []

func layout_for_day(day: int) -> Dictionary:
	var grade := "D" if day<27 else "C"
	if day>=20 and owned_layouts.has(grade): return owned_layouts[grade].duplicate(true)
	return super.layout_for_day(day)

func prepare(day: int, mode: String) -> void:
	super.prepare(day,mode)
	if day>=20 and owned_layouts.has("D"):
		var wallet: Dictionary = daily_wallets.get(str(day),owned_layouts["D" if day<27 else "C"].resources)
		view.placement.resources.gold = int(wallet.gold)
		view.placement.resources.mana = int(wallet.mana)
		if config.has("probe_mana"): view.placement.resources.mana = int(config.probe_mana)
		if DisplayServer.get_name()!="headless": view.update_wallet()

func purchase_sites(source: Dictionary, sites: Array) -> Dictionary:
	var result := source.duplicate(true)
	for site in sites:
		var hint: Dictionary
		for row in Buildings.Layout.read(str(source.grade)).buildings:
			if row.id==site: hint = row; break
		expect(not hint.is_empty(),"planned construction site "+str(site))
		var before: Dictionary = result.resources.duplicate(true)
		var next := Buildings.preview(result,hint.kind,Vector2i(hint.rect[0],hint.rect[1]))
		var cost: Dictionary = result.catalog[hint.kind].cost
		var affordable := int(before.gold)>=int(cost.get("gold",0)) and int(before.mana)>=int(cost.get("mana",0))
		purchases.append({"grade":source.grade,"day":source.day,"site":site,"kind":hint.kind,"cost":cost.duplicate(),"before":before,"ok":next.get("ok",false),"affordable":affordable,"after":next.get("resources",before).duplicate(true) if next.get("ok",false) else before.duplicate(true),"errors":next.get("errors",[])})
		expect(bool(next.get("ok",false))==affordable,"construction follows actual affordability "+str(site))
		if next.get("ok",false): result = next
	return result

func settle_reference(day: int, result: Dictionary) -> Dictionary:
	expect(result.get("win",false),"reference settlement uses successful defense DAY"+str(day))
	if not result.get("win",false): return {}
	var before := {"gold":GameState.gold,"mana":GameState.mana}
	game.rewards_pending = result.rewards.duplicate(true)
	# Same bonus and resource commit used by CombatSceneController.finish_combat.
	if result.loot_bonus: game.rewards_pending.gold += roundi(float(game.rewards_pending.gold)*.1)
	game._commit_or_rollback_battle_progress(true)
	var settled := {"gold":GameState.gold,"mana":GameState.mana}
	# ApprovedGradeProgression.continue_after_result carries settled resources
	# through Grade.advance. It does NOT call the general GameState.advance_day.
	var carried: Dictionary = view.placement.duplicate(true)
	carried.resources.gold = GameState.gold; carried.resources.mana = GameState.mana
	var progressed := Grade.advance(game,carried,view.monster_ui.assignments,day+1)
	expect(progressed.get("ok",false),"native approved grade day progression")
	expect(progressed.get("layout",{}).get("resources",{}).get("gold",-1)==GameState.gold and progressed.get("layout",{}).get("resources",{}).get("mana",-1)==GameState.mana,"native grade transition preserves settled gold and mana")
	GameState.day = day+1
	var next := {"gold":GameState.gold,"mana":GameState.mana}
	economy.append({"day":day,"seed":result.seed,"initial":result.wallet,"gold_loss":result.gold_loss,"before_settlement":before,"rewards":result.rewards,"loot_bonus":result.loot_bonus,"settled":settled,"daily_income":{"gold":0,"mana":0},"next":next})
	return next

func save_reference() -> void:
	save_json(OUT10B+"economy.json",{"economy_version":3,"reference_wave_sha":"18931a116c5562c2bddd12be08da76882e6c1921","checkpoint":{"day":19,"gold":1200,"mana":600},"policy":"first successful seed per independent daily snapshot; HP/growth/food retain 0104/0106 fixtures; native approved progression has zero passive daily gold/mana income; no optional spending; DAY28 follows DAY27 settlement; DAY30 carries DAY29 preparation wallet without combat or settlement","settlements":economy,"purchases":purchases,"daily_wallets":daily_wallets,"layouts":{"D":Buildings.snapshot(owned_layouts.D),"C":Buildings.snapshot(owned_layouts.C)}})

func complete_c_reference() -> void:
	var product_waves: Dictionary = DataRegistry.waves.duplicate(true)
	var reference := "res://tmp/v130r_step10b/reference_waves.json"
	expect(FileAccess.file_exists(reference),"prepared immutable reference waves exist")
	if not FileAccess.file_exists(reference): return
	DataRegistry.waves = JSON.parse_string(FileAccess.get_file_as_string(reference))
	var opening: Dictionary = owned_layouts.C.resources.duplicate(true)
	for day in [27,28]:
		daily_wallets[str(day)] = owned_layouts.C.resources.duplicate(true)
		var result := {}
		for index in range(10):
			result = await trial(day,index,"recommended")
			if result.get("win",false): break
		var wallet := settle_reference(day,result)
		owned_layouts.C.resources.merge(wallet,true)
	daily_wallets["29"] = owned_layouts.C.resources.duplicate(true)
	daily_wallets["30"] = daily_wallets["29"].duplicate(true)
	owned_layouts.C.resources = opening
	DataRegistry.waves = product_waves
	save_reference()

func build_reference() -> void:
	var product_waves: Dictionary = DataRegistry.waves.duplicate(true)
	var reference := "res://tmp/v130r_step10b/reference_waves.json"
	if FileAccess.file_exists(reference): DataRegistry.waves = JSON.parse_string(FileAccess.get_file_as_string(reference))
	var result := await trial(19,1,"recommended")
	var wallet := settle_reference(19,result)
	var d := super.layout_for_day(20); d.resources.merge(wallet,true); d.day = 20
	owned_layouts["D"] = purchase_sites(d,["watchtower_2","bait_treasure_2"])
	for day in range(20,27):
		daily_wallets[str(day)] = owned_layouts.D.resources.duplicate(true)
		# The economic reference is a successful-day path, not a win-rate sample.
		for index in range(10):
			result = await trial(day,index,"recommended")
			if result.get("win",false): break
		wallet = settle_reference(day,result)
		owned_layouts.D.resources.merge(wallet,true)
	# Keep the opening D wallet for independent comparisons and captures.
	owned_layouts.D.resources.merge(daily_wallets["20"],true)
	var carried: Dictionary = owned_layouts.D.duplicate(true); carried.day = 26
	carried.resources.merge(wallet,true)
	var moved := Grade.advance(game,carried,{},27)
	expect(moved.get("ok",false),"paid D buildings carry to C")
	owned_layouts["C"] = purchase_sites(moved.layout,["barracks_2","recovery_nest_2"])
	await complete_c_reference()
	DataRegistry.waves = product_waves

func trial(day: int, index: int, mode: String, capture: bool = false) -> Dictionary:
	seed(130800+index); prepare(day,mode)
	var wallet: Dictionary = view.placement.resources.duplicate(true)
	battle = preload("res://tools/tests/V130RStep10BSimulation.gd").new() if config.get("fast_ui",true) else SIM8B.new()
	battle.omit_cosmetics = DisplayServer.get_name()=="headless"
	battle.begin(view); game.combat_paused = false
	var levels := {}
	for unit in game.monster_units:
		unit.level = int(game.monster_roster[unit.unit_id].level); levels[unit.unit_id] = unit.level
	if capture:
		view.monster_ui.set_mode("battle"); view.monster_ui.unit_layer.hide(); view.battle = battle
		view.battle_ui = load("res://scripts/ui/ApprovedBattleUI.gd").new()
		view.add_child(view.battle_ui); view.battle_ui.setup(view,battle)
	var steps := 0; var captured := false
	var mana_trace: Array = [{"time":0,"mana":wallet.mana}]
	var next_mana_sample := 15.0
	while battle.running and game.combat_time<360:
		var delta := 1.0/60
		battle.physics_process(delta)
		for unit in game.monster_units+game.enemy_units:
			unit.set_physics_process(false); unit._physics_process(delta)
		for tween in battle.active_combat_tweens.duplicate():
			if tween!=null and tween.is_valid(): tween.pause(); tween.custom_step(delta)
		steps += 1
		if game.combat_time>=next_mana_sample:
			mana_trace.append({"time":game.combat_time,"mana":GameState.mana})
			next_mana_sample += 15
		if capture and not captured and game.combat_time>=55:
			await capture_gates(); captured = true
		if steps%300==0: await get_tree().process_frame
	var result: Dictionary = battle.last_result.duplicate(true)
	result.merge({"day":day,"trial":index,"seed":130800+index,"layout":mode,"grade":view.placement.grade,"levels":levels,"timeout":battle.running,"throne_hp":GameState.demon_lord_hp,"throne_max":1500,"gold_loss":game.treasure_gold_stolen_this_battle,"assignments":view.monster_ui.assignments.duplicate(true),"fixture":fixture.duplicate(true),"goals":battle.goal_events.duplicate(true),"facility_losses":battle.facility_losses.duplicate(true),"road_traces":battle.road_traces.duplicate(true),"wave_entries":DataRegistry.waves["day_%d"%day].duplicate(true),"simulation_hz":60,"buildings":Buildings.snapshot(view.placement).buildings,"wallet":wallet,"rewards":game.rewards_pending.duplicate(true),"loot_bonus":battle._has_loot_bonus(),"omit_achievement_observers":bool(config.get("omit_achievement_observers",false))})
	result["mana_trace"] = mana_trace; result["end_mana"] = GameState.mana
	expect(not battle.running,"battle completed without timeout DAY"+str(day))
	print("STEP10B ",config.name," D",day," ",mode," #",index," win=",result.get("win",false)," HP=",result.throne_hp)
	if capture:
		for control in [view.battle_ui.bar,view.battle_ui.skills,view.battle_ui.battle_status,view.battle_ui.health_status]: control.queue_free()
		view.battle_ui.queue_free(); view.battle_ui = null; view.battle = null
	battle.release(); battle = null; await get_tree().process_frame
	return result

func capture_gates() -> void:
	for unit in game.monster_units+game.enemy_units: unit.refresh_depth_slot()
	view.show_full(); view.battle_ui.refresh()
	# Keep both approach roads visible in the requested review capture.
	# Hiding this presentation control does not touch bark timers or combat.
	if is_instance_valid(game.v130r_story.bark_panel): game.v130r_story.bark_panel.hide()
	set_review_caption("C · 서문 / 남문 분산 · 동일 유료 건물 · DAY 27")
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT10B+"c_split_gates.png")
	save_json(OUT10B+"capture_gates.json",{"time":game.combat_time,"goals":battle.goal_events,"traces":battle.road_traces})

func direct_paid() -> void:
	for day in [20,27]:
		var signature := ""; var wallet := ""
		for mode in ["recommended","anchor_cluster","final_line","first_line"]:
			prepare(day,mode)
			var current := JSON.stringify(Buildings.snapshot(view.placement).buildings)
			var funds := JSON.stringify(view.placement.resources)
			if signature=="": signature = current; wallet = funds
			expect(signature==current and wallet==funds,"four modes own identical paid buildings and wallet")
			expect(view.placement.buildings.size()==owned_layouts["D" if day==20 else "C"].buildings.size(),"all affordable design sites built")
			for b in view.placement.buildings: expect(int(b.level)==1,"no free facility upgrades")
	var poor := super.layout_for_day(20); poor.resources = {"gold":0,"mana":0,"food":30}
	expect(not Buildings.preview(poor,"watchtower",Vector2i(25,0)).ok,"no construction without actual budget")
	expect(DataRegistry.waves.day_29.is_empty(),"DAY29 remains preparation only")

func direct_routes() -> void:
	for day in [20,27]:
		prepare(day,"recommended")
		battle = SIM8B.new(); battle.omit_cosmetics = true; battle.begin(view); game.combat_paused = true
		var doors := {}
		for lane in range(2):
			battle.spawn_enemy("investigator",{"route_variation":false,"waypoint_room_ids":["watchtower_2","bait_treasure_2"],"objective_priority":1,"attack_throne":true})
			var unit: Node = game.enemy_units[-1]; unit.set_physics_process(false)
			var site: String = ["watchtower_2","bait_treasure_2"][int(unit.get_meta("approved_route_lane"))]
			expect(unit.goal_room==battle.map.resolve_site(site),"secondary waypoint resolves paid instance")
			expect(unit.get_meta("next_objective","")=="throne","secondary waypoint retains final throne goal")
			var path: Array = unit.path_points.duplicate()
			expect(not path.is_empty(),"secondary waypoint reachable")
			unit.position = battle.map.center(unit.goal_room); battle.update_enemy_path(unit)
			expect(unit.goal_room=="throne" and not unit.has_meta("next_objective"),"secondary visit resumes throne")
			if day==27: doors[str(unit.get_meta("throne_door"))] = true
			unit.position = battle.goal_point(unit)
			var hp := GameState.demon_lord_hp
			battle.update_room_effects(.01)
			expect(GameState.demon_lord_hp<hp,"secondary flanker can damage throne after arrival")
			var guard: Node = game.monster_units[0]; var home: Vector2 = guard.position
			guard.position = unit.position+Vector2(10,0); unit.attack_cooldown = 0; unit.apply_taunt(guard,2)
			hp = GameState.demon_lord_hp; battle.update_room_effects(.01)
			expect(GameState.demon_lord_hp==hp and not battle.prioritizes_throne(unit),"taunt blocks the investigator throne priority")
			guard.position = home
			unit.down = true; unit.hp = 0
		if day==27: expect(doors.has("W") and doors.has("S"),"C keeps separate west and south doors")
		for lane in range(2):
			battle.spawn_enemy("explorer",{"route_variation":false,"waypoint_room_ids":["watchtower_2",""],"objective_priority":1,"attack_throne":true,"attack_throne_lane":1})
			var unit: Node = game.enemy_units[-1]; unit.set_physics_process(false)
			var route_lane := int(unit.get_meta("approved_route_lane"))
			expect(unit.goal_room==(battle.map.resolve_site("watchtower_2") if route_lane==0 else "throne"),"heavy candidate changes only the upper branch waypoint")
			expect(bool(unit.get_meta("attack_throne",false))==(route_lane==1),"heavy candidate preserves the original siege lane")
			if route_lane==0:
				unit.position = battle.map.center(unit.goal_room); battle.update_enemy_path(unit)
				expect(unit.goal_room=="throne","heavy upper waypoint resumes its original throne destination")
			unit.down = true; unit.hp = 0
		for entry in [{"id":"engineer","target":"recovery_nest"},{"id":"thief","target":"vault"}]:
			battle.spawn_enemy(entry.id,{"target_room_id":entry.target,"waypoint_room_ids":["watchtower_2","bait_treasure_2"]})
			var unit: Node = game.enemy_units[-1]; unit.set_physics_process(false)
			expect(unit.goal_room==entry.target and not unit.has_meta("next_objective"),"specialist goal survives waypoint option")
		battle.release(); battle = null
		await get_tree().process_frame
	# Existing saves may leave both secondary sites empty: retain default RNG/AI.
	prepare(20,"recommended"); view.placement = super.layout_for_day(20)
	battle = SIM8B.new(); battle.omit_cosmetics = true; battle.begin(view); game.combat_paused = true
	seed(130899)
	battle.spawn_enemy("investigator",{"route_variation":true,"waypoint_room_ids":["watchtower_2","bait_treasure_2"]})
	var first: Node = game.enemy_units[-1]; first.set_physics_process(false)
	var goal: String = first.goal_room; var path: Array = first.path_points.duplicate()
	var next: String = str(first.get_meta("next_objective","")); var draw := randf()
	seed(130899)
	battle.spawn_enemy("investigator",{"route_variation":true})
	var fallback: Node = game.enemy_units[-1]; fallback.set_physics_process(false)
	expect(fallback.goal_room==goal and fallback.path_points==path and str(fallback.get_meta("next_objective",""))==next,"vacant secondary sites retain default route")
	expect(randf()==draw,"secondary routing consumes no extra random draw")
	battle.release(); battle = null; await get_tree().process_frame
	prepare(29,"recommended"); game.current_screen = Constants.SCREEN_MANAGEMENT
	var wallet: Dictionary = view.placement.resources.duplicate(true)
	var hp := GameState.demon_lord_hp
	expect(not game._has_defense_wave_for_day(29),"DAY29 has no defense wave")
	expect(not view.start_battle(),"paid C layout cannot start DAY29 combat")
	expect(game.enemy_units.is_empty() and GameState.day==29 and GameState.demon_lord_hp==hp,"DAY29 creates no enemies or throne damage")
	expect(view.placement.resources==wallet,"DAY29 gate does not charge resources")
	var prepared := Grade.advance(game,view.placement,view.monster_ui.assignments,30)
	expect(prepared.get("ok",false) and int(prepared.layout.day)==30,"native DAY29 preparation advances to DAY30")
	expect(prepared.layout.resources==wallet,"DAY29 native grade progression adds no passive income or combat reward")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT10B))
	config = JSON.parse_string(FileAccess.get_file_as_string("res://tmp/v130r_step10b/config.json"))
	for arg in OS.get_cmdline_user_args():
		if arg=="--spread-mode=direct":
			config.name = "direct"; config.days = []; config.route_checks = true; config.erase("waves")
			config.erase("budget_diagnostics"); config.erase("probe_mana")
		elif arg=="--spread-mode=capture":
			config.name = "capture"; config.capture = true; config.erase("waves")
			config.erase("budget_diagnostics"); config.erase("probe_mana")
	print("STEP10B_ISOLATED_USERDATA ",OS.get_user_data_dir())
	expect(OS.get_environment("MAWANG_DISABLE_STEAM")=="1" and not AchievementService.bridge.initialized,"Steam initialization disabled for isolated benchmark")
	expect(Engine.physics_ticks_per_second==60,"native 60Hz")
	await boot(); base_members = Members.roster(); game.selected_contract_ids.assign(["spore_healer","stone_sentinel"])
	if config.get("omit_achievement_observers",false):
		# Observer-only service: no battle, movement, skill or resource rule changes.
		AchievementService.catalog = {"achievements":[],"stats":[]}
		AchievementService.storage_enabled = false; AchievementService.set_process(false)
	if FileAccess.file_exists(OUT10B+"economy.json") and not config.get("rebuild_economy",false):
		var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT10B+"economy.json"))
		if int(saved.get("economy_version",0))!=3:
			push_error("Archive stale economic assumptions before rebuilding economy v3")
			get_tree().quit(1); return
		expect(saved.reference_wave_sha=="18931a116c5562c2bddd12be08da76882e6c1921" and int(saved.checkpoint.day)==19 and int(saved.checkpoint.gold)==1200 and int(saved.checkpoint.mana)==600,"cached economy retains declared immutable source and checkpoint")
		for grade in ["D","C"]: owned_layouts[grade] = Buildings.restore(saved.layouts[grade],Buildings.initial(game,grade))
		daily_wallets = saved.daily_wallets
	else: await build_reference()
	if not failures.is_empty():
		save_json(OUT10B+str(config.name)+"_checks.json",{"checks":checks,"failures":failures,"phase":"economic_reference"})
		await stop(); get_tree().quit(1); return
	direct_paid()
	if config.get("route_checks",false): await direct_routes()
	if config.has("waves"): DataRegistry.waves = JSON.parse_string(FileAccess.get_file_as_string(config.waves))
	if config.get("budget_diagnostics",false):
		var diagnostics: Array = [await trial(30,3,"recommended")]
		config["probe_mana"] = 600
		diagnostics.append(await trial(30,3,"recommended"))
		config.erase("probe_mana")
		diagnostics[0]["diagnostic_only"] = "actual_settlement_budget"
		diagnostics[1]["diagnostic_only"] = "legacy_600_mana_control_not_adopted"
		save_json(OUT10B+"day30_budget_diagnostics.json",diagnostics)
	if config.get("capture",false):
		prepare(20,"recommended"); view.show_full()
		set_review_caption("D · 추천 건설: 감시탑 II / 미끼 보물실 II · 유료 건설 후 배치")
		await get_tree().process_frame; await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OUT10B+"d_recommended_buildings.png")
		var parity_day := 22
		if FileAccess.file_exists(OUT10B+"selection.json"):
			var selected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT10B+"selection.json"))
			for day in selected.accepted_days:
				if int(day)<27: parity_day = int(day); break
		rows.append(await trial(parity_day,0,"recommended"))
		rows.append(await trial(27,0,"recommended",true))
		save_json(OUT10B+"capture_rows.json",rows)
	else:
		var path: String = OUT10B+str(config.name)+".json"
		rows = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else []
		for row in rows:
			expect(row.wave_entries==DataRegistry.waves["day_%d"%int(row.day)],"resume retains measured wave entries")
			var expected: Dictionary = daily_wallets[str(int(row.day))]
			expect(row.wallet.gold==expected.gold and row.wallet.mana==expected.mana,"resume retains measured daily budget")
		if not failures.is_empty():
			await stop(); save_json(OUT10B+str(config.name)+"_checks.json",{"checks":checks,"failures":failures})
			get_tree().quit(1); return
		for day in config.get("days",[]):
			if int(day)==29: continue
			for mode in config.get("layouts",["recommended","anchor_cluster","final_line","first_line"]):
				for index in range(int(config.get("trials",10))):
					if rows.any(func(r): return r.day==int(day) and r.layout==mode and r.trial==index): continue
					rows.append(await trial(int(day),index,str(mode)))
					save_json(path,rows)
	await stop()
	save_json(OUT10B+str(config.name)+"_checks.json",{"checks":checks,"failures":failures,"rows":rows.size()})
	print("STEP10B_DONE rows=",rows.size()," checks=",checks," failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
