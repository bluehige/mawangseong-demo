extends "res://tools/tests/V130RStep7MonstersTest.gd"
## Independent daily snapshots; production battle/AI/skills, no campaign settlement.
const STEP8 := "res://tmp/v130r_step8/"
var config := {}
var rows: Array = []
var base_members := {}
var review_caption: Label

func set_review_caption(content: String) -> void:
	if not is_instance_valid(review_caption): review_caption = view.label_at(view.chrome,"",Vector2(520,160),22,true)
	review_caption.text = content

func save_json(path: String, value) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(value,"\t")); file.close()

func expected_level(day: int, species: String) -> int:
	var joined := int(DataRegistry.monster(species).get("join_day",1))
	if Recruits.FALLBACK.has(species): joined = int(Recruits.FALLBACK[species])
	if species in game.selected_contract_ids: joined = 1
	return 1+floori(maxi(0,day-joined)/3.0)

func prepare(day: int, layout_mode: String) -> void:
	view.placement = Buildings.initial(game,"F" if day<15 else "E")
	view.placement.day = day; view.placement.food_state = Food.fresh()
	view.state = preload("res://scripts/map_builder/ApprovedMapLayout.gd").read("F" if day<15 else "E")
	view.monster_ui.food_income = Food.income(day)
	view.placement.resources = {"gold":1200,"mana":600,"food":Food.capacity(day)}
	GameState.day = day; GameState.max_day = 30
	GameState.demon_lord_max_hp = 1500; GameState.demon_lord_hp = 1500
	GameState.food_state = Food.fresh()
	game.monster_roster.clear()
	view.monster_ui.members = base_members.duplicate(true)
	for id in view.monster_ui.members:
		var row: Dictionary = view.monster_ui.members[id]
		var level := expected_level(day,row.species_id)
		row.stats.max_hp = int(row.stats.max_hp)+(level-1)*20
		row.stats.atk = int(row.stats.atk)+(level-1)*3
		row.stats.def = int(row.stats.def)+(level-1)
		game.monster_roster[row.species_id] = {"level":level,"exp":0,"bond":0,"bond_rank":0,"unlocked_memory_ids":[],"specialization_id":""}
	var eligible: Array = Recruits.eligible(game,view.monster_ui.members,day)
	var model = load("res://tmp/v130r_step8/MembersBefore.gd") if config.get("baseline",false) else Members
	view.monster_ui.assignments = model.auto_place(view.placement,view.monster_ui.members,eligible,Food.income(day))
	if layout_mode=="bad":
		# Deliberately stack the same deployed roster at the barracks apron.
		# This deliberately invalid crowd is recorded separately from legal slots.
		var ids: Array = view.monster_ui.assignments.keys()
		var points: Array = view.placement.defense_points.barracks
		for index in range(ids.size()):
			view.monster_ui.assignments[ids[index]] = {"building":"barracks","slot":index%points.size()}
	if DisplayServer.get_name()!="headless":
		var declared_assignments: Dictionary = view.monster_ui.assignments.duplicate(true)
		view.render_map()
		# The explicit stress fixture keeps its crowd; UI slot sanitization is separate.
		view.monster_ui.assignments = declared_assignments
		view.update_wallet()
		var title := view.chrome.find_child("GradeDayLabel",true,false) as Label
		if title!=null: title.text = "DAY %d  ·  %s등급" % [day,view.placement.grade]
	view.set_physics_process(false)

func trial(day: int, trial_index: int, layout_mode: String, capture: bool = false) -> Dictionary:
	var wall_start := Time.get_ticks_msec()
	seed(130800+trial_index)
	prepare(day,layout_mode)
	var wall_prepare := Time.get_ticks_msec()
	battle = load("res://tools/tests/V130RStep8Simulation.gd").new()
	battle.begin(view); game.combat_paused = false
	if capture:
		view.monster_ui.set_mode("battle"); view.monster_ui.unit_layer.hide()
		view.battle = battle
		view.battle_ui = load("res://scripts/ui/ApprovedBattleUI.gd").new()
		view.add_child(view.battle_ui); view.battle_ui.setup(view,battle)
	var wall_begin := Time.get_ticks_msec()
	for unit in game.monster_units: unit.level = int(game.monster_roster[unit.unit_id].level)
	var steps := 0; var captured := false; var nearest := INF; var captured_time := -1.0
	var levels := {}
	for unit in game.monster_units: levels[unit.unit_id] = unit.level
	while battle.running and game.combat_time<360:
		var delta := 1.0/float(config.get("hz",60))
		battle.physics_process(delta)
		for unit in game.monster_units+game.enemy_units:
			unit.set_physics_process(false); unit._physics_process(delta)
		for tween in battle.active_combat_tweens.duplicate():
			if tween!=null and tween.is_valid(): tween.pause(); tween.custom_step(delta)
		steps += 1
		if capture and not captured:
			nearest = INF
			for enemy in game.enemy_units:
				if not enemy.is_alive(): continue
				nearest = minf(nearest,enemy.position.distance_to(battle.map.center("throne")))
			var minimum_time := float({15:60,30:66}.get(day,0))
			if nearest<150 and GameState.demon_lord_hp<1450 and game.combat_time>=minimum_time:
				captured_time = game.combat_time
				await capture_battle(day); captured = true
		if steps%300==0: await get_tree().process_frame
	var result: Dictionary = battle.last_result.duplicate(true)
	result.merge({"day":day,"trial":trial_index,"seed":130800+trial_index,"layout":layout_mode,"levels":levels,"timeout":battle.running,"throne_hp":GameState.demon_lord_hp,"throne_max":1500,"gold_loss":game.treasure_gold_stolen_this_battle,"thieves":game.thieves_spawned_this_battle,"escaped":game.thieves_escaped_this_battle,"thefts":game.thieves_completed_theft_this_battle,"assignments":view.monster_ui.assignments.duplicate(true),"captured":captured,"goals":battle.goal_events.duplicate(true)})
	result["wave_entries"] = DataRegistry.waves.get("day_%d" % day,[]).duplicate(true)
	result["simulation_hz"] = int(config.get("hz",60))
	result["capture_time"] = captured_time
	result["baseline_recommendation"] = bool(config.get("baseline",false))
	if battle.running:
		result["alive"] = []
		for unit in game.monster_units+game.enemy_units:
			if unit.is_alive(): result.alive.append({"id":unit.unit_id,"hp":unit.hp,"goal":unit.goal_room,"pos":str(unit.position),"path":unit.path_points.size()})
	print("STEP8 ",config.get("name","trial")," D",day," ",layout_mode," #",trial_index," win=",result.get("win",false)," HP=",GameState.demon_lord_hp," gold=",result.gold_loss," t=",game.combat_time," wall_ms=",[wall_prepare-wall_start,wall_begin-wall_prepare,Time.get_ticks_msec()-wall_begin])
	if capture:
		for control in [view.battle_ui.bar,view.battle_ui.skills,view.battle_ui.battle_status,view.battle_ui.health_status]: control.queue_free()
		view.battle_ui.queue_free(); view.battle_ui = null; view.battle = null
	battle.release(); battle = null
	await get_tree().process_frame
	return result

func capture_battle(day: int) -> void:
	for unit in game.monster_units+game.enemy_units: unit.refresh_depth_slot()
	view.set_camera(battle.map.center("throne")+Vector2(-150,100),.85)
	view.battle_ui.refresh()
	set_review_caption("DAY %d · 옥좌 근처 교전 · 추천 배치 · 성장 적용" % day)
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(STEP8+"battle_day%d.png" % day)

func capture_kkogit() -> void:
	prepare(30,"recommended")
	view.monster_ui.unit_layer.hide()
	battle = load("res://tools/tests/V130RStep7Simulation.gd").new(); battle.begin(view)
	var kkogit_name := ""
	for unit in game.monster_units:
		if unit.unit_id=="crumpled_map": kkogit_name = unit.name_label.text
	expect(kkogit_name=="꼬깃","production roster uses the correct Kkogit name label")
	game.combat_paused = true; clear_units(); await get_tree().process_frame
	var center: Vector2 = battle.map.center("throne")+Vector2(-300,550)
	for index in range(4):
		var unit := make("crumpled_map",center+Vector2(index*220,0))
		unit.name_label.text = kkogit_name+" · "+["SW","SE","NE","NW"][index]
		unit.face_direction([Vector2(-1,1),Vector2(1,1),Vector2(1,-1),Vector2(-1,-1)][index])
		unit._update_animation(); unit.refresh_depth_slot()
		expect(absf(unit.visible_body_rect().size.y-96)<6,"kkogit body96 direction"+str(index))
	for index in range(2):
		var species: String = ["slime","imp"][index]
		var reference := make(species,center+Vector2(220+index*220,220))
		reference.name_label.text = str(DataRegistry.monster(species).display_name)+" · 96"
		reference._update_animation(); reference.refresh_depth_slot()
	view.set_camera(center+Vector2(330,90),.9)
	for unit in game.monster_units:
		unit.set_vitals_position(unit.desired_vitals_position(view.camera_scale))
		unit.name_label.show(); unit.vitals.show()
	set_review_caption("0103 꼬깃 · 4방향 / 몸 높이 96월드px · 일시정지 비교")
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(STEP8+"kkogit_battle.png")
	battle.release(); battle = null; await get_tree().process_frame

func objective_checks() -> void:
	prepare(7,"recommended")
	for id in view.monster_ui.assignments:
		if view.monster_ui.members[id].species_id=="imp": expect(view.monster_ui.assignments[id].building=="throne","ranged imp holds the recommended final guard")
	expect(Members.sanitize(view.placement,view.monster_ui.assignments,view.monster_ui.members)==view.monster_ui.assignments,"recommended slots are legal and unique")
	expect(Members.upkeep(view.monster_ui.assignments,view.monster_ui.members)<=Food.income(7),"recommended guard stays within ration budget")
	battle = load("res://tools/tests/V130RStep8Simulation.gd").new(); battle.begin(view)
	game.combat_paused = true
	var clean_wave = preload("res://scripts/combat/WaveManager.gd").new(); clean_wave.setup(7,DataRegistry.waves)
	expect(clean_wave.schedule.size()==game.wave_manager.schedule.size(),"jitter preserves the enemy count")
	for entry in game.wave_manager.schedule:
		var closest := INF
		for original in clean_wave.schedule:
			if original.enemy_id==entry.enemy_id: closest = minf(closest,absf(float(original.time)-float(entry.time)))
		expect(closest<=.350001,"spawn jitter remains bounded to0.35s")
	var guard: Node = game.monster_units[0]
	battle.spawn_enemy("explorer",{"objective_priority":1})
	var enemy: Node = game.enemy_units[-1]; enemy.position = guard.position+Vector2(20,0)
	enemy.set_physics_process(false); enemy.goal_room = "throne"
	battle.update_enemy_path(enemy)
	expect(enemy.get_meta("road_destination")==battle.map.nearest_cell(battle.map.center("throne")),"objective squad advances past unforced contact")
	enemy.attack_cooldown = 0; battle.try_attack(enemy,[guard])
	expect(enemy.attack_cooldown==0,"advancing squad does not stop for an unforced attack")
	enemy.apply_taunt(guard,2)
	expect(enemy.forced_attack_target([guard],260)==guard,"taunt still intercepts objective squad")
	battle.update_enemy_path(enemy); battle.try_attack(enemy,[guard])
	expect(enemy.attack_cooldown>0,"taunted squad fights its interceptor")
	battle.release(); battle = null; await get_tree().process_frame
	prepare(20,"recommended")
	battle = load("res://tools/tests/V130RStep8Simulation.gd").new(); battle.begin(view)
	game.combat_paused = true
	var varied := false
	seed(130890)
	for index in range(12):
		battle.spawn_enemy("investigator",{"route_variation":true,"objective_priority":1})
		var scout: Node = game.enemy_units[-1]; scout.set_physics_process(false)
		if scout.has_meta("next_objective"):
			varied = true; scout.position = battle.map.center("ward_core"); battle.update_enemy_path(scout)
			expect(scout.goal_room=="throne" and not scout.has_meta("next_objective"),"investigator resumes throne objective after flank waypoint")
	expect(varied,"investigators actually use an alternate branch")
	battle.release(); battle = null; await get_tree().process_frame
	save_json(STEP8+"objective_checks.json",{"checks":checks,"failures":failures})

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STEP8))
	config = JSON.parse_string(FileAccess.get_file_as_string(STEP8+"config.json"))
	print("STEP8_ISOLATED_USERDATA ",OS.get_user_data_dir())
	print("STEP8_NATIVE_PHYSICS_HZ ",Engine.physics_ticks_per_second)
	await boot(); base_members = Members.roster()
	game.selected_contract_ids.assign(["spore_healer","stone_sentinel"])
	if config.get("waves","")!="": DataRegistry.waves = JSON.parse_string(FileAccess.get_file_as_string(str(config.waves)))
	if config.get("kkogit",false): await capture_kkogit()
	if config.get("direct",false): await objective_checks()
	# Optional literal wave candidates share the exact same daily battle kernel.
	# Every measured row retains its complete entries and candidate ID.
	var original_waves: Dictionary = DataRegistry.waves.duplicate(true)
	for candidate in config.get("candidates",[]):
		DataRegistry.waves = original_waves.duplicate(true)
		var day := int(candidate.day)
		DataRegistry.waves["day_%d" % day] = candidate.entries.duplicate(true)
		for index in range(int(candidate.get("trials",10))):
			var result: Dictionary = await trial(day,index,"recommended")
			result["candidate_id"] = str(candidate.id)
			rows.append(result)
		save_json(STEP8+str(config.get("name","results"))+".json",rows)
	DataRegistry.waves = original_waves
	for day in config.get("days",range(1,31)):
		for layout_mode in config.get("layouts",["recommended","bad"]):
			for index in range(int(config.get("trials",10))):
				var trial_index := index+int(config.get("seed_by_day",{}).get(str(int(day)),0))
				rows.append(await trial(int(day),trial_index,str(layout_mode),bool(config.get("capture",false))))
			save_json(STEP8+str(config.get("name","results"))+".json",rows)
	await stop()
	print("STEP8_DONE rows=",rows.size()," failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
