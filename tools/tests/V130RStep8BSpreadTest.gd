extends "res://tools/tests/V130RStep8BalanceTest.gd"
const OUT8B := "res://tmp/v130r_step8b/"
const SIM8B = preload("res://tools/tests/V130RStep8BSpreadSimulation.gd")
var fixture := {}

func stop() -> void:
	# Finish deferred visual callbacks before destroying the isolated root.
	if is_instance_valid(game) and is_instance_valid(game.effect_root):
		for effect in game.effect_root.get_children(): effect.queue_free()
	await super.stop()
	for _frame in range(2): await get_tree().process_frame

func prepare(day: int, layout_mode: String) -> void:
	# Prepare production recommendation and its eligible, levelled, affordable roster.
	super.prepare(day,"bad" if layout_mode=="over_capacity" else "recommended")
	var available: Array = Recruits.eligible(game,view.monster_ui.members,day)
	var available_slots := -1
	if layout_mode not in ["recommended","over_capacity"]:
		var restricted: Dictionary = view.placement.duplicate(true)
		var topology := preload("res://scripts/map_builder/ApprovedBattleMap.gd").new()
		topology.setup(view.placement)
		for building in restricted.defense_points:
			var keep: Array = []
			for c in restricted.defense_points[building]:
				if (layout_mode=="anchor_cluster" and building in ["barracks","ward_core","throne"]) or (layout_mode=="final_line" and topology.line_for(c)=="final") or (layout_mode=="first_line" and topology.line_for(c)=="1"):
					keep.append(c)
			# Keep slot indices identical to the actual game's placement data.
			expect(keep.is_empty() or keep==restricted.defense_points[building],"line fixture retains complete legal building slots")
			restricted.defense_points[building] = keep
		view.monster_ui.assignments = Members.auto_place(restricted,view.monster_ui.members,available,Food.income(day))
		available_slots = 0
		for points in restricted.defense_points.values(): available_slots += points.size()
	var assignments: Dictionary = view.monster_ui.assignments
	var legal: bool = Members.sanitize(view.placement,assignments,view.monster_ui.members)==assignments
	var by_building := {}; var capacities := {}; var slots := {}
	for b in view.placement.buildings:
		capacities[b.id] = b.capacity; slots[b.id] = view.placement.defense_points[b.id].size()
	for id in assignments:
		expect(id in available,"only actually eligible defenders")
		var b := str(assignments[id].building)
		by_building[b] = int(by_building.get(b,0))+1
	if layout_mode!="over_capacity":
		expect(legal,"unique legal defense cells "+layout_mode)
		expect(Members.upkeep(assignments,view.monster_ui.members)<=Food.income(day),"food budget "+layout_mode)
		for b in by_building: expect(by_building[b]<=capacities[b],"capacity "+b)
		var manual := {}
		for id in assignments:
			var placed: Dictionary = Members.put(view.placement,manual,id,assignments[id],view.monster_ui.members,available)
			expect(placed.ok,"manual placement API accepts fixture")
			manual = placed.assignments
		expect(manual==assignments,"manual placement preserves fixture")
		if available_slots>=0: expect(assignments.size()==available_slots,"maximum legal concentration fills every allowed slot")
	fixture = {"legal":legal,"counts":by_building,"capacity":capacities,"slots":slots,"upkeep":Members.upkeep(assignments,view.monster_ui.members),"budget":Food.income(day)}
	if DisplayServer.get_name()!="headless":
		var declared: Dictionary = assignments.duplicate(true)
		view.render_map(); view.monster_ui.assignments = declared; view.update_wallet()
	view.set_physics_process(false)

func trial(day: int, trial_index: int, layout_mode: String, capture: bool = false) -> Dictionary:
	seed(130800+trial_index); prepare(day,layout_mode)
	battle = SIM8B.new()
	battle.omit_cosmetics = bool(config.get("fast_cosmetics",false)) and DisplayServer.get_name()=="headless"
	battle.begin(view); game.combat_paused = false
	var levels := {}
	for unit in game.monster_units:
		unit.level = int(game.monster_roster[unit.unit_id].level); levels[unit.unit_id] = unit.level
	if capture:
		view.monster_ui.set_mode("battle"); view.monster_ui.unit_layer.hide(); view.battle = battle
		view.battle_ui = load("res://scripts/ui/ApprovedBattleUI.gd").new()
		view.add_child(view.battle_ui); view.battle_ui.setup(view,battle)
	var steps := 0; var captured := false
	while battle.running and game.combat_time<360:
		var delta := 1.0/60
		battle.physics_process(delta)
		for unit in game.monster_units+game.enemy_units:
			unit.set_physics_process(false); unit._physics_process(delta)
		for tween in battle.active_combat_tweens.duplicate():
			if tween!=null and tween.is_valid(): tween.pause(); tween.custom_step(delta)
		steps += 1
		if capture and not captured:
			var side_route := false; var throne_route := false
			for enemy in game.enemy_units:
				if not enemy.is_alive(): continue
				var c: Vector2i = battle.map.cell(enemy.position)
				if (enemy.goal_room=="bait_treasure" and c.y>=10) or (enemy.goal_room=="ward_core" and c.x>=16) or (enemy.goal_room=="vault" and c.x>=25 and c.y>=10): side_route = true
				if enemy.goal_room=="throne" and c.x>=8: throne_route = true
			var lost_facility: bool = battle.facility_losses.any(func(e): return e.building=="recovery_nest")
			if capture_ready(day,side_route,throne_route,lost_facility):
				await capture_spread(day,layout_mode); captured = true
		if steps%300==0: await get_tree().process_frame
	var result: Dictionary = battle.last_result.duplicate(true)
	result.merge({"day":day,"trial":trial_index,"seed":130800+trial_index,"layout":layout_mode,"levels":levels,"timeout":battle.running,"throne_hp":GameState.demon_lord_hp,"throne_max":1500,"gold_loss":game.treasure_gold_stolen_this_battle,"thieves":game.thieves_spawned_this_battle,"escaped":game.thieves_escaped_this_battle,"thefts":game.thieves_completed_theft_this_battle,"assignments":view.monster_ui.assignments.duplicate(true),"fixture":fixture.duplicate(true),"captured":captured,"goals":battle.goal_events.duplicate(true),"facility_losses":battle.facility_losses.duplicate(true),"road_traces":battle.road_traces.duplicate(true),"wave_entries":DataRegistry.waves.get("day_%d" % day,[]).duplicate(true),"simulation_hz":60,"baseline_recommendation":false})
	result["omit_cosmetics"] = battle.omit_cosmetics
	expect(not battle.running,"battle completed without timeout")
	print("STEP8B ",config.name," D",day," ",layout_mode," #",trial_index," win=",result.get("win",false)," HP=",result.throne_hp," gold=",result.gold_loss," facilities=",result.facility_losses.size()," fixture=",fixture.counts)
	if capture:
		for control in [view.battle_ui.bar,view.battle_ui.skills,view.battle_ui.battle_status,view.battle_ui.health_status]: control.queue_free()
		view.battle_ui.queue_free(); view.battle_ui = null; view.battle = null
	battle.release(); battle = null; await get_tree().process_frame
	return result

func capture_ready(day: int, side_route: bool, throne_route: bool, lost_facility: bool) -> bool:
	return (day==24 and game.combat_time>=24 and side_route and throne_route) or (day==27 and lost_facility)

func preparation_day_checks() -> void:
	prepare(29,"recommended")
	var preparation_checks := checks
	var preparation_failures := failures.size()
	game._enter_campaign_management_day(false); await get_tree().process_frame
	expect(GameState.day==29,"DAY29 entry retains preparation day")
	expect(DataRegistry.waves.day_29.is_empty(),"DAY29 waves remain empty")
	expect(not game._has_defense_wave_for_day(29),"DAY29 has no defense wave")
	expect(bool(game._campaign_day_info().get("management_only",false)),"DAY29 management-only schedule unchanged")
	var state: Dictionary = game._management_start_state()
	expect(not state.can_start and state.reason_code=="management_only","DAY29 combat start remains blocked")
	var hp: int = GameState.demon_lord_hp; var spawned: int = game.spawned_count
	game._start_combat(); await get_tree().process_frame
	expect(game.enemy_units.is_empty() and game.spawned_count==spawned,"DAY29 cannot spawn enemies")
	expect(GameState.day==29 and GameState.demon_lord_hp==hp,"DAY29 day and throne HP unchanged")
	save_json(OUT8B+"day29_preparation_checks.json",{"checks":checks-preparation_checks,"failures":failures.slice(preparation_failures),"day":GameState.day,"start_state":state})

func spread_route_checks() -> void:
	prepare(17,"recommended")
	battle = SIM8B.new(); battle.begin(view); game.combat_paused = true
	var visits: Array = []
	for species in ["investigator","royal_scout"]:
		for waypoint in ["watchtower","ward_core","recovery_nest","vault","bait_treasure","barracks"]:
			battle.spawn_enemy(species,{"route_variation":true,"objective_priority":1,"waypoint_room_id":waypoint})
			var enemy: Node = game.enemy_units[-1]; enemy.set_physics_process(false)
			expect(enemy.goal_room==waypoint and enemy.get_meta("next_objective","")=="throne","explicit flank retains final throne objective")
			var visited: Array = []
			for _step in range(6000):
				battle.update_enemy_path(enemy)
				if not enemy.has_meta("next_objective"): break
				enemy._physics_process(1.0/60)
				var c: Vector2i = battle.map.cell(enemy.position)
				if visited.is_empty() or visited[-1]!=c: visited.append(c)
			expect(battle.map.nearest_cell(battle.map.center(waypoint)) in visited,"flanker walks actual side-road destination")
			expect(enemy.goal_room=="throne" and not enemy.has_meta("next_objective"),"flanker resumes throne after reaching waypoint")
			visits.append({"id":species,"waypoint":waypoint,"cells":str(visited)})
	for specialized in [{"id":"engineer","goal":"recovery_nest"},{"id":"thief","goal":"vault"}]:
		battle.spawn_enemy(specialized.id,{"target_room_id":specialized.goal,"waypoint_room_id":"watchtower"})
		var enemy: Node = game.enemy_units[-1]; enemy.set_physics_process(false)
		expect(enemy.goal_room==specialized.goal and not enemy.has_meta("next_objective"),"flank option preserves specialized facility/theft goals")
	seed(130899)
	battle.spawn_enemy("investigator",{"route_variation":true,"objective_priority":1,"waypoint_room_id":"missing_room"})
	var invalid: Node = game.enemy_units[-1]; invalid.set_physics_process(false)
	var invalid_goal: String = invalid.goal_room; var invalid_path: Array = invalid.path_points.duplicate()
	var invalid_next := str(invalid.get_meta("next_objective","")); var invalid_random := randf()
	seed(130899)
	battle.spawn_enemy("investigator",{"route_variation":true,"objective_priority":1})
	var fallback: Node = game.enemy_units[-1]; fallback.set_physics_process(false)
	expect(invalid_goal==fallback.goal_room and invalid_path==fallback.path_points and invalid_next==str(fallback.get_meta("next_objective","")),"invalid waypoint retains default routing")
	expect(invalid_random==randf(),"optional waypoint preserves default random draws")
	battle.spawn_enemy("investigator",{"waypoint_room_id":"watchtower","objective_priority":1})
	var taunted: Node = game.enemy_units[-1]; taunted.set_physics_process(false)
	var guard: Node = game.monster_units[0]
	taunted.position = guard.position+Vector2(15,0); taunted.apply_taunt(guard,2)
	battle.update_enemy_path(taunted); battle.try_attack(taunted,[guard])
	expect(taunted.attack_cooldown>0,"taunt still intercepts an explicit flanker")
	expect(taunted.goal_room=="watchtower" and taunted.get_meta("next_objective","")=="throne","interception preserves remaining flank and final goal")
	battle.release(); battle = null; await get_tree().process_frame
	save_json(OUT8B+"spread_route_checks.json",{"checks":checks,"failures":failures,"visits":visits})

func capture_spread(day: int, layout_mode: String) -> void:
	for unit in game.monster_units+game.enemy_units: unit.refresh_depth_slot()
	view.set_camera(Vector2(1900,1250),.65)
	view.battle_ui.refresh()
	var titles := {"recommended":"추천 배치","anchor_cluster":"병영·결계핵·옥좌 집중","final_line":"최종선 집중","first_line":"1차선 집중"}
	var losses: Array = battle.facility_losses.filter(func(e): return e.building in Buildings.ROLES)
	var note := "회복 둥지 무력화" if day==27 else "옥좌·시설 경로 분기"
	set_review_caption("DAY %d · %s · %s · %.1f초 · 시설 손실 %d / 금고 %d" % [day,titles.get(layout_mode,layout_mode),note,game.combat_time,losses.size(),game.treasure_gold_stolen_this_battle])
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	var name := "split_route_day24" if day==24 else "crowded_fail_day27"
	get_viewport().get_texture().get_image().save_png(OUT8B+name+".png")
	var visible_units: Array = []
	for unit in game.monster_units+game.enemy_units:
		var c: Vector2i = battle.map.cell(unit.position)
		visible_units.append({"id":unit.unit_id,"faction":unit.faction,"alive":unit.is_alive(),"hp":unit.hp,"goal":unit.goal_room,"cell":[c.x,c.y],"position":[unit.position.x,unit.position.y]})
	save_json(OUT8B+name+"_state.json",{"time":game.combat_time,"layout":layout_mode,"fixture":fixture,"units":visible_units,"goals":battle.goal_events,"traces":battle.road_traces,"facility_losses":losses})

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT8B))
	config = JSON.parse_string(FileAccess.get_file_as_string(OUT8B+"config.json"))
	print("STEP8B_ISOLATED_USERDATA ",OS.get_user_data_dir())
	print("STEP8B_NATIVE_PHYSICS_HZ ",Engine.physics_ticks_per_second)
	expect(Engine.physics_ticks_per_second==60,"production native physics remains60Hz")
	await boot(); base_members = Members.roster()
	game.selected_contract_ids.assign(["spore_healer","stone_sentinel"])
	if config.get("route_checks",false): await spread_route_checks()
	if not failures.is_empty():
		await stop()
		save_json(OUT8B+str(config.name)+"_checks.json",{"checks":checks,"failures":failures})
		get_tree().quit(1); return
	if config.get("waves","")!="": DataRegistry.waves = JSON.parse_string(FileAccess.get_file_as_string(str(config.waves)))
	for candidate in config.get("candidates",[]):
		var key := "day_%d" % int(candidate.day)
		var original: Array = DataRegistry.waves[key].duplicate(true)
		DataRegistry.waves[key] = candidate.entries.duplicate(true)
		for layout_mode in candidate.get("layouts",["recommended","anchor_cluster"]):
			for index in range(int(candidate.get("trials",config.get("trials",10)))):
				var result: Dictionary = await trial(int(candidate.day),index+int(candidate.get("seed_offset",0)),str(layout_mode),bool(candidate.get("capture",false)))
				result["candidate_id"] = str(candidate.id); rows.append(result)
			save_json(OUT8B+str(config.name)+".json",rows)
		DataRegistry.waves[key] = original
	for day in config.days:
		if int(day)==29: continue # Preparation only; no battle is measured.
		for layout_mode in config.layouts:
			if config.get("fixtures_only",false):
				prepare(int(day),str(layout_mode))
				rows.append({"day":int(day),"layout":str(layout_mode),"fixture":fixture.duplicate(true),"assignments":view.monster_ui.assignments.duplicate(true)})
				save_json(OUT8B+str(config.name)+".json",rows)
				continue
			for index in range(int(config.get("trials",10))):
				rows.append(await trial(int(day),index+int(config.get("seed_offset",0)),str(layout_mode),bool(config.get("capture",false))))
			save_json(OUT8B+str(config.name)+".json",rows)
	if config.get("preparation_day",false): await preparation_day_checks()
	await stop()
	save_json(OUT8B+str(config.name)+"_checks.json",{"checks":checks,"failures":failures})
	print("STEP8B_DONE rows=",rows.size()," checks=",checks," failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
