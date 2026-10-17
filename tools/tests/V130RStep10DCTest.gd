extends "res://tools/tests/V130RStep8BSpreadTest.gd"
const DC := "res://_mockup/game_step10_dc/"
const Grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
const Map = preload("res://scripts/map_builder/ApprovedBattleMap.gd")
var layout_cache := {}

func check_siege_priority(grade: String) -> void:
	battle.spawn_enemy("explorer",{"objective_priority":1,"attack_throne":true})
	var siege: Node = game.enemy_units[-1]; siege.set_physics_process(false)
	siege.position = battle.goal_point(siege)
	var defender: Node = game.monster_units[0]
	var old_position: Vector2 = defender.position; defender.position = siege.position+Vector2(10,0)
	var guard_hp: int = defender.hp; var throne_hp: int = GameState.demon_lord_hp
	battle.try_attack(siege,[defender])
	expect(defender.hp==guard_hp and siege.attack_cooldown<=0,"explicit siege keeps throne priority at "+grade+" door")
	battle.update_room_effects(.01)
	expect(GameState.demon_lord_hp<throne_hp and siege.attack_cooldown>0,"explicit siege actually damages "+grade+" throne near a guard")
	siege.attack_cooldown = 0; siege.apply_taunt(defender,2)
	throne_hp = GameState.demon_lord_hp
	battle.update_room_effects(.01)
	expect(GameState.demon_lord_hp==throne_hp and not battle.prioritizes_throne(siege),"taunt blocks explicit "+grade+" siege damage")
	battle.try_attack(siege,[defender])
	expect(siege.attack_cooldown>0,"taunted "+grade+" siege attacks its interceptor")
	defender.position = old_position
	siege.down = true; siege.hp = 0
	GameState.demon_lord_hp = throne_hp
	for _lane in range(2):
		battle.spawn_enemy("explorer",{"objective_priority":1,"attack_throne":true,"attack_throne_lane":0,"route_variation":false})
		var split: Node = game.enemy_units[-1]; split.set_physics_process(false)
		expect(bool(split.get_meta("attack_throne"))==(int(split.get_meta("approved_route_lane"))==0),"siege lane preserves existing spawn lane without RNG on "+grade)
		split.down = true; split.hp = 0

func prepare(day: int, layout_mode: String) -> void:
	super.prepare(day,layout_mode)
	if config.get("door_goal_center",false): view.placement["door_goal_center"] = true
	if config.get("branch_routes",false): view.placement["branch_routes"] = true

func purchased_plan(grade: String) -> Dictionary:
	var result := layout_for_day(20 if grade=="D" else 27)
	for b in Buildings.Layout.read(grade).buildings:
		if not str(b.id).ends_with("_2"): continue
		var next := Buildings.preview(result,b.kind,Vector2i(b.rect[0],b.rect[1]))
		expect(next.get("ok",false),"new site purchased "+grade+" "+b.id+" "+str(next.get("errors",[])))
		if next.get("ok",false): result = next
	return result

func layout_for_day(day: int) -> Dictionary:
	if config.get("reference_e",false): return super.layout_for_day(day)
	if day<20: return super.layout_for_day(day)
	var grade := "D" if day<27 else "C"
	if layout_cache.has(grade): return layout_cache[grade].duplicate(true)
	var old := Buildings.initial(game,"E"); old.day = 19; old.stage = 2
	var moved := Grade.advance(game,old,{},20)
	expect(moved.get("ok",false),"E to D fixture migration")
	if not moved.get("ok",false): return old
	layout_cache["D"] = moved.layout.duplicate(true)
	if day<27: return moved.layout
	moved.layout.day = 26
	var final := Grade.advance(game,moved.layout,{},27)
	expect(final.get("ok",false),"D to C fixture migration")
	if final.get("ok",false): layout_cache["C"] = final.layout.duplicate(true)
	return final.layout if final.get("ok",false) else moved.layout

func direct_dc() -> void:
	for grade in ["D","C"]:
		var plan := Buildings.Layout.read(grade)
		var full := Buildings.initial(game,grade)
		full.food_state = Food.fresh()
		expect(full.ok,"valid "+grade+" layout: "+str(full.errors))
		if not full.ok: continue
		var roads := Buildings.Layout.cells(plan,"=BXm")
		expect(full.road_cells.size()==roads.size(),"exact approved road count "+grade)
		for c in roads: expect(full.road_cells.has(c),"exact approved road "+str(c))
		var total := 0
		for b in full.buildings:
			total += full.defense_points[b.id].size()
			var wanted: Array = full.plan_defense[b.id].cells
			expect(full.defense_points[b.id]==wanted,"approved defender order "+grade+" "+b.id)
		expect(total==(22 if grade=="D" else 26),"spatial capacity "+grade)
		var bought := purchased_plan(grade)
		expect(bought.ok and bought.buildings.size()==(10 if grade=="D" else 12),"paid example owns all sites")
		expect(bought.resources.gold<1245,"extra facilities consume construction gold")
		var extra_map := Map.new(); extra_map.setup(bought)
		expect(extra_map.resolve_site("bait_treasure_2")!="","purchased second facility resolves plan site to instance")
		var vacant_map := Map.new(); vacant_map.setup(layout_for_day(20 if grade=="D" else 27))
		expect(vacant_map.resolve_site("bait_treasure_2")=="","empty second site is not an objective")
		if grade=="D":
			bought.day = 26
			var extra_id: String = extra_map.resolve_site("bait_treasure_2")
			Buildings.building(bought,extra_id)["enhancements"] = {"test_owned_token":3}
			var expanded := Grade.advance(game,bought,{},27)
			expect(expanded.ok,"paid D secondary instances migrate to C")
			if expanded.ok:
				var carried := Buildings.building(expanded.layout,extra_id)
				expect(carried.rect.position==Vector2i(33,18) and carried.enhancements.test_owned_token==3,"second instance identity, kind site and upgrade metadata retained")
				expect(carried.capacity==Buildings.building(bought,extra_id).capacity+1,"purchased D capacity bonus not doubled at C")
			var tower_id: String = extra_map.resolve_site("watchtower_2")
			var shifted := Buildings.preview(bought,"watchtower",Vector2i(24,0),tower_id)
			expect(shifted.get("ok",false),"second purchased instance can move independently")
			if shifted.get("ok",false):
				var shifted_map := Map.new(); shifted_map.setup(shifted)
				expect(shifted_map.resolve_site("watchtower_2")==tower_id,"moved purchased instance retains stable site alias")
				var carried_tower := Grade.advance(game,shifted,{},27)
				expect(carried_tower.ok and Buildings.building(carried_tower.layout,tower_id).rect.position==Vector2i(32,0),"moved secondary instance retains relative displacement at C")
		var map := Map.new(); map.setup(full)
		expect(map.connection_pairs().size()==full.buildings.size()+(1 if grade=="C" else 0),"all primary and secondary door links exposed")
		expect(map.debug_socket_cells().size()==map.connection_pairs().size()*2,"door socket API includes C south doorway")
		for id in full.doors:
			expect(not map.path_cells(full.doors.entrance.front[0],full.doors[id].front[0]).is_empty(),"A* reaches "+grade+" "+id)
		for c in full.road_cells:
			var tags := map.tags_at(c)
			for key in ["road","bridge","water_adjacent","trap","defense_line","aura"]: expect(tags.has(key),"semantic API "+key)
		if grade=="C":
			expect(full.doors.throne.secondary.size()==1,"C second throne door")
			var joined: Dictionary = full.duplicate(true)
			for x in range(41,43):
				for y in range(6,18): joined.road_cells[Vector2i(x,y)] = true
			expect(not Buildings.validate_routes(joined).is_empty(),"new branches cannot join C final roads outside throne")
			for c in full.doors.throne.secondary[0].front:
				var wanted_point: Vector2 = (map.world(full.doors.throne.secondary[0].front[0])+map.world(full.doors.throne.secondary[0].front[1]))/2 if full.get("door_goal_center",false) else map.world(c)
				expect(map.target_point("throne",map.world(c),"S")==wanted_point,"south door target stays south")
		var snap := Buildings.snapshot(full)
		var restored := Buildings.restore(snap,Buildings.initial(game,grade))
		expect(restored.ok and Buildings.snapshot(restored)==snap,"D/C copy snapshot roundtrip")
	var e := Buildings.initial(game,"E"); e.day = 19; e.stage = 2
	e.food_state = Food.fresh()
	e.traps[0]["id"] = "owned_trap_identity"
	e.traps[0]["owned_count"] = 1
	var assignments := Members.auto_place(e,base_members,base_members.keys(),30)
	Buildings.building(e,"barracks").level = 2
	Buildings.building(e,"barracks").capacity += 1
	e.specializations = {"slime":"slime_gate_keeper"}
	var original := JSON.stringify(Buildings.snapshot(e))
	var moved := Grade.advance(game,e,assignments,20)
	expect(moved.ok and moved.layout.grade=="D","DAY20 transition")
	expect(JSON.stringify(Buildings.snapshot(e))==original,"source remains byte-equivalent")
	if moved.ok:
		expect(moved.layout.buildings.size()==e.buildings.size(),"no free D buildings")
		expect(moved.layout.resources==e.resources and moved.layout.serial==e.serial,"resources and serial preserved")
		expect(moved.layout.specializations==e.specializations,"specializations preserved")
		expect(Buildings.building(moved.layout,"barracks").level==2,"upgrade level preserved")
		expect(Buildings.building(moved.layout,"barracks").capacity==Buildings.building(e,"barracks").capacity+2,"D capacity bonus once")
		expect(moved.layout.traps.size()==e.traps.size(),"trap ownership preserved")
		expect(moved.layout.traps[0].id=="owned_trap_identity","trap explicit identity preserved")
		var d_snapshot := Buildings.snapshot(moved.layout)
		moved.layout.day = 26
		var c := Grade.advance(game,moved.layout,moved.defenders,27)
		expect(c.ok and c.layout.grade=="C","DAY27 transition")
		if c.ok:
			expect(c.layout.buildings.size()==e.buildings.size(),"no free C buildings")
			expect(Buildings.building(c.layout,"barracks").capacity==Buildings.building(e,"barracks").capacity+3,"C capacity delta, not stacked")
			var member_count: int = c.defenders.size()+c.waiting.size()
			expect(member_count==moved.defenders.size(),"every defender assigned or waiting")
			var err := Members.save_copy(c.layout,c.defenders,"res://tmp/v130r_step10/copies/roundtrip.json")
			expect(err==OK,"only isolated copy written")
			var loaded := Members.load_copy(Buildings.initial(game,"C"),base_members,"res://tmp/v130r_step10/copies/roundtrip.json")
			save_json("res://tmp/v130r_step10/copy_expected.json",Buildings.snapshot(c.layout))
			save_json("res://tmp/v130r_step10/copy_actual.json",Buildings.snapshot(loaded.layout))
			expect(JSON.stringify(Buildings.snapshot(loaded.layout))==JSON.stringify(Buildings.snapshot(c.layout)),"isolated C copy reload (JSON numeric normalization)")
			var relocated := Buildings.initial(game,"E"); relocated.traps = []; relocated.day = 19
			relocated = Buildings.preview(relocated,"barracks",Vector2i(11,1),"barracks")
			expect(relocated.ok,"custom E building location is legal")
			if relocated.ok:
				var relative := Grade.advance(game,relocated,{},20)
				expect(relative.ok and Buildings.building(relative.layout,"barracks").rect.position==Vector2i(11,0),"custom relative displacement retained when legal")
		# Impossible ownership must reject atomically.
		var impossible := e.duplicate(true)
		var row := Buildings.building(impossible,"barracks").duplicate(true)
		row.id = "oversized"; row.rect = Rect2i(0,0,99,99); impossible.buildings.append(row)
		var failed := Grade.advance(game,impossible,{},20)
		expect(not failed.ok,"impossible transition rejected")
		expect(d_snapshot.grade=="D","successful source snapshot retained")
	for marked in [true,false]:
		var purchased_e := Buildings.initial(game,"E"); purchased_e.day = 19; purchased_e.stage = 2
		var old_barracks := Buildings.building(purchased_e,"barracks")
		old_barracks.capacity += 1
		if marked: old_barracks["capacity_bonus"] = 1
		var expanded := Grade.advance(game,purchased_e,{},20)
		expect(expanded.ok and Buildings.building(expanded.layout,"barracks").capacity==6,"E construction bonus applied only as D delta, marker="+str(marked))
	prepare(22,"recommended")
	battle = SIM8B.new(); battle.omit_cosmetics = true; battle.begin(view); game.combat_paused = true
	check_siege_priority("D")
	for waypoint in ["watchtower","bait_treasure","recovery_nest","ward_core","barracks"]:
		battle.spawn_enemy("investigator",{"waypoint_room_id":waypoint,"objective_priority":1})
		var unit: Node = game.enemy_units[-1]; unit.set_physics_process(false)
		expect(unit.goal_room==waypoint and unit.get_meta("next_objective","")=="throne","D explicit waypoint "+waypoint)
		unit.position = battle.map.center(waypoint); battle.update_enemy_path(unit)
		expect(unit.goal_room=="throne" and not unit.has_meta("next_objective"),"D waypoint returns throne")
	var trap: Dictionary = view.placement.traps[0]
	battle.spawn_enemy("explorer",{})
	var enemy: Node = game.enemy_units[-1]; enemy.set_physics_process(false)
	enemy.position = battle.map.world(Vector2i(trap.cell[0],trap.cell[1]))
	var hp: int = enemy.hp
	battle.apply_cell_traps(enemy)
	expect(enemy.hp<hp or enemy.slow_timer>0,"D actual trap effect")
	battle.map.layout["branch_routes"] = true
	battle.spawn_enemy("explorer",{"route_variation":true,"objective_priority":1})
	var lower: Node = game.enemy_units[-1]; lower.set_physics_process(false)
	lower.set_meta("approved_route_lane",1)
	var lower_path: Array = battle.route_path(lower,battle.goal_point(lower))
	expect(battle.map.world(Vector2i(34,14)) in lower_path,"D second lane uses actual lower final bridge")
	var guard: Node = game.monster_units[0]
	lower.position = guard.position+Vector2(15,0); lower.apply_taunt(guard,2)
	battle.update_enemy_path(lower); battle.try_attack(lower,[guard])
	expect(lower.attack_cooldown>0,"D lower route still yields to taunt interception")
	battle.release(); battle = null
	prepare(30,"recommended")
	battle = SIM8B.new(); battle.omit_cosmetics = true; battle.begin(view); game.combat_paused = true
	check_siege_priority("C")
	for side in ["W","S"]:
		battle.spawn_enemy("explorer",{"throne_door":side,"route_variation":true,"objective_priority":1})
		var unit: Node = game.enemy_units[-1]; unit.set_physics_process(false)
		var target: Vector2 = battle.goal_point(unit)
		var path: Array = battle.map.path_cells(battle.map.cell(unit.position),battle.map.cell(target))
		expect(not path.is_empty(),"C "+side+" route reachable")
		expect(battle.map.cell(target) in (view.placement.doors.throne.front if side=="W" else view.placement.doors.throne.secondary[0].front),"C "+side+" correct target door")
		for c in path: expect(battle.map.is_road(c) and (not view.placement.water.has(c) or view.placement.bridges.has(c)),"C route road and bridge only")
		unit.position = target; battle.update_enemy_path(unit)
		expect(unit.path_points.is_empty(),"C south/west arrival stops at own door")
	for kind in ["investigator","royal_scout","explorer"]:
		battle.spawn_enemy(kind,{"waypoint_room_id":"recovery_nest","objective_priority":1})
		var unit: Node = game.enemy_units[-1]; unit.set_physics_process(false)
		expect(unit.goal_room=="recovery_nest","C flank facility "+kind)
		unit.position = battle.map.center("recovery_nest"); battle.update_enemy_path(unit)
		expect(unit.goal_room=="throne" and not unit.has_meta("next_objective"),"C flank returns to original goal")
	var c_trap: Dictionary = view.placement.traps[0]
	battle.spawn_enemy("explorer",{})
	var c_enemy: Node = game.enemy_units[-1]; c_enemy.set_physics_process(false)
	c_enemy.position = battle.map.world(Vector2i(c_trap.cell[0],c_trap.cell[1]))
	var previous_events: int = battle.trap_events.size(); battle.apply_cell_traps(c_enemy)
	expect(battle.trap_events.size()==previous_events+1,"C actual trap API")
	battle.map.layout["door_goal_center"] = true
	for side in ["W","S"]:
		battle.spawn_enemy("explorer",{"throne_door":side})
		var walker: Node = game.enemy_units[-1]; walker.set_physics_process(false)
		var destination: Vector2 = battle.goal_point(walker)
		for _step in range(5000):
			walker._physics_process(1.0/60)
			if walker.position.distance_to(destination)<1: break
		expect(walker.position.distance_to(destination)<2,"actual Unit reaches two-cell "+side+" doorway midpoint")
		expect(walker.get_cell_tags().road,"door midpoint remains on walkable road")
	battle.release(); battle = null
	await preparation_day_checks()
	for previous_day in [19,26]:
		# DAY29's real management entry replaces its old Control instance.
		var callback_source := layout_for_day(previous_day); callback_source.day = previous_day
		callback_source.food_state = Food.fresh()
		callback_source.food_state.owned = Recruits.eligible(game,base_members,previous_day+1)
		callback_source.food_state.contracts = Array(game.selected_contract_ids)
		Grade.stash(game,callback_source,{})
		GameState.food_state = callback_source.food_state.duplicate(true)
		game._set_screen("management",false)
		await get_tree().process_frame; await get_tree().process_frame
		view = game.ui_layer.get_node("ApprovedMapManagement")
		prepare(previous_day,"recommended")
		view.placement.food_state.owned = Recruits.eligible(game,base_members,previous_day+1)
		view.placement.food_state.contracts = Array(game.selected_contract_ids)
		GameState.food_state = view.placement.food_state.duplicate(true)
		GameState.gold = int(view.placement.resources.gold); GameState.mana = int(view.placement.resources.mana); GameState.food = int(view.placement.resources.food)
		var owned_roster := JSON.stringify(game.monster_roster)
		var old_assignments: Dictionary = view.monster_ui.assignments.duplicate(true)
		Grade.stash(game,view.placement,old_assignments)
		game._advance_after_result()
		await get_tree().process_frame; await get_tree().process_frame
		view = game.ui_layer.get_node("ApprovedMapManagement")
		expect(view.placement.day==previous_day+1 and view.placement.grade==("D" if previous_day==19 else "C"),"actual result callback opens new grade/day")
		expect(view.monster_ui.assignments==old_assignments,"result callback retains building IDs and slots")
		expect(JSON.stringify(game.monster_roster)==owned_roster,"result callback preserves roster growth/specialization metadata")
	var preparation := layout_for_day(29); preparation.day = 29
	preparation.resources = {"gold":973,"mana":421,"food":50}
	preparation.food_state = Food.fresh()
	preparation.food_state.owned = Recruits.eligible(game,base_members,30)
	preparation.food_state.contracts = Array(game.selected_contract_ids)
	var prepared_assignments := Members.auto_place(preparation,base_members,preparation.food_state.owned,Food.income(29))
	Grade.stash(game,preparation,prepared_assignments)
	GameState.day = 29; GameState.food_state = preparation.food_state.duplicate(true)
	game._set_screen("management",false)
	await get_tree().process_frame; await get_tree().process_frame
	view = game.ui_layer.get_node("ApprovedMapManagement")
	var spawned_before: int = game.spawned_count; var hp_before: int = GameState.demon_lord_hp
	expect(not view.start_battle() and view.battle==null,"DAY29 direct map battle tab cannot bypass preparation gate")
	ProjectSettings.set_setting("debug/approved_map_step6",false)
	expect(not view.start_battle(),"DAY29 no battle even without food-system switch")
	ProjectSettings.set_setting("debug/approved_map_step6",true)
	expect(game.enemy_units.is_empty() and game.spawned_count==spawned_before,"DAY29 map tab spawns no enemies")
	var action: Control = view.chrome.find_child("ApprovedDayAction",true,false)
	expect(action!=null and action.get_parent().get_children().any(func(c): return c is Label and c.text=="준비 확정"),"DAY29 uses existing GPT check icon and preparation label")
	# A management purchase must not be refunded from stale global balances.
	GameState.gold = 1500; GameState.mana = 999; GameState.food = 60
	var click := InputEventMouseButton.new(); click.position = action.get_global_rect().get_center()
	click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true
	action.emit_signal("gui_input",click); action.emit_signal("gui_input",click)
	await get_tree().process_frame; await get_tree().process_frame
	view = game.ui_layer.get_node("ApprovedMapManagement")
	expect(view.placement.day==30 and view.placement.grade=="C" and view.battle==null,"DAY29 confirmation reaches DAY30 once without battle")
	expect(view.placement.resources=={"gold":973,"mana":421,"food":50},"preparation retains purchases without rewards or food charge")
	expect(view.monster_ui.assignments==prepared_assignments and game.enemy_units.is_empty() and GameState.demon_lord_hp==hp_before,"preparation preserves defenders and throne HP with zero enemies")

func capture_map(name: String, layout: Dictionary, full: bool, assigned: Variant = null) -> void:
	view.placement = layout; view.state = Buildings.Layout.read(str(layout.grade))
	GameState.day = int(layout.day); GameState.food_income = Food.income(int(layout.day))
	view.monster_ui.food_income = GameState.food_income
	view.monster_ui.assignments = assigned.duplicate(true) if assigned is Dictionary else Members.auto_place(layout,view.monster_ui.members,Recruits.eligible(game,view.monster_ui.members,int(layout.day)),Food.income(int(layout.day)))
	view.render_map(); view.update_wallet()
	if full: view.show_full()
	else: view.show_default()
	var title: Label = view.chrome.find_child("GradeDayLabel",true,false)
	if title!=null: title.text = "DAY %d · %s등급" % [layout.day,layout.grade]
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DC+name+".png")
	expect(is_equal_approx(view.camera_scale,.75) if not full else true,"0087 start zoom "+name)

func capture_spread(day: int, _layout_mode: String) -> void:
	for unit in game.monster_units+game.enemy_units: unit.refresh_depth_slot()
	view.show_full(); view.battle_ui.refresh()
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DC+("battle_d_day22.png" if day==22 else "battle_c_day30.png"))

func capture_ready(_day: int, _side: bool, _throne: bool, _lost: bool) -> bool:
	return game.combat_time>=24 and not battle.contacts.is_empty()

func trial(day: int, index: int, layout_mode: String, capture: bool = false) -> Dictionary:
	var result: Dictionary = await super.trial(day,index,layout_mode,capture)
	result["grade"] = view.placement.grade; result["stage"] = view.placement.stage
	result["buildings"] = Buildings.snapshot(view.placement).buildings
	result["door_goal_center"] = view.placement.get("door_goal_center",false)
	result["branch_routes"] = view.placement.get("branch_routes",false)
	result["traps"] = view.placement.traps.duplicate(true)
	return result

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DC))
	config = {"name":"dc","fast_cosmetics":true}
	var run_mode := "direct"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dc-mode="): run_mode = arg.get_slice("=",1)
	await boot(); base_members = Members.roster(); game.selected_contract_ids.assign(["spore_healer","stone_sentinel"])
	if run_mode=="direct": await direct_dc()
	elif run_mode=="capture":
		for grade in ["D","C"]:
			var layout := purchased_plan(grade)
			await capture_map(grade.to_lower()+"_full",layout,true)
			await capture_map(grade.to_lower()+"_start",layout,false)
		for pair in [["E",19,20,"e_to_d"],["D",26,27,"d_to_c"]]:
			var layout := Buildings.initial(game,pair[0]) if pair[0]=="E" else purchased_plan("D")
			layout.day = pair[1]
			var a := Members.auto_place(layout,base_members,Recruits.eligible(game,base_members,int(layout.day)),Food.income(layout.day))
			await capture_map(pair[3]+"_before",layout,true,a)
			var moved := Grade.advance(game,layout,a,pair[2]); expect(moved.ok,"capture transition")
			if moved.ok: await capture_map(pair[3]+"_after",moved.layout,true,moved.defenders)
		for day in [22,30]: rows.append(await trial(day,0,"recommended",true))
		save_json(DC+"capture_rows.json",rows)
	else:
		var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tmp/v130r_step10/config.json"))
		var original_waves: Dictionary = DataRegistry.waves.duplicate(true)
		for candidate in settings.get("cases",[settings]):
			var checks_before := checks; var failures_before := failures.size()
			config["name"] = str(candidate.name)
			config["reference_e"] = bool(candidate.get("reference_e",false))
			config["door_goal_center"] = bool(candidate.get("door_goal_center",false))
			config["branch_routes"] = bool(candidate.get("branch_routes",false))
			DataRegistry.waves = JSON.parse_string(FileAccess.get_file_as_string(candidate.waves)) if candidate.has("waves") else original_waves.duplicate(true)
			var path: String = DC+str(candidate.name)+".json"
			rows = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else []
			for day in candidate.days:
				if int(day)==29: continue
				for layout_mode in candidate.get("layouts",["recommended","anchor_cluster","final_line","first_line"]):
					for trial_number in range(int(candidate.get("trials",10))):
						var index := trial_number+int(candidate.get("seed_offset",0))
						if rows.any(func(r): return r.day==int(day) and r.layout==layout_mode and r.trial==index): continue
						rows.append(await trial(int(day),index,str(layout_mode),false))
						save_json(path,rows)
			save_json(DC+str(candidate.name)+"_checks.json",{"checks":checks-checks_before,"failures":failures.slice(failures_before),"rows":rows.size()})
	await stop()
	save_json(DC+run_mode+"_checks.json",{"checks":checks,"failures":failures})
	print("STEP10_DONE ",run_mode," rows=",rows.size()," checks=",checks," failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
