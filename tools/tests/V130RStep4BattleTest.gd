extends Node
const Model = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const OUT := "res://tmp/v130r_step4/"
var preview: Node
var game: Node
var view: Control
var battle
var failures: Array[String] = []
var checks := 0
var evidence := {}
var mode := "direct"
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL ",message)
func _ready() -> void: run.call_deferred()
func boot() -> void:
	preview = load("res://scenes/map_builder/ApprovedPlacementPreview.tscn").instantiate()
	add_child(preview)
	await get_tree().create_timer(.25).timeout
	game = preview.game
	view = game.ui_layer.get_node("ApprovedMapManagement")
	view.placement = view.baseline.duplicate(true)
	view.monster_ui.unlock_all = true
	view.monster_ui.assignments = Model.auto_place(view.placement,view.monster_ui.members,view.monster_ui.members.keys(),100)
	if mode=="capture":
		# A deliberate defense, rather than the over-budget fourteen-member roster,
		# leaves the first trap lane reachable and tests both lines in one real wave.
		view.monster_ui.assignments = {
			"mon_core_pudding":{"building":"watchtower","slot":0},
			"mon_core_gob":{"building":"barracks","slot":0},
			"mon_core_pynn":{"building":"barracks","slot":1},
			"mon_contract_dolkong":{"building":"barracks","slot":2},
			"mon_contract_dudum":{"building":"barracks","slot":3},
			"mon_contract_mori":{"building":"recovery_nest","slot":0},
			"mon_contract_mimi":{"building":"throne","slot":0}}
	view.render_map()
	GameState.demon_lord_hp = 1500; GameState.demon_lord_max_hp = 1500; GameState.max_day = 30
	get_window().size = Vector2i(1920,1080)
	await get_tree().process_frame
func stop() -> void:
	game.campaign_autosave_pending = false; game._shutdown_audio_for_exit()
	if battle!=null:
		battle.running = false
		battle._clear_active_combat_tweens()
	preview.queue_free(); await get_tree().process_frame
func start() -> void:
	expect(view.start_battle(),"battle tab starts placed defense")
	battle = view.battle
func direct() -> void:
	start(); view.set_physics_process(false); battle.set_pause_state(true)
	var map = battle.map
	expect(game.wave_manager.total_to_spawn==6,"DAY7 original 4 explorers and 2 thieves")
	expect(game.monster_units.size()==14,"placed individual roster reused")
	for id in map.layout.doors:
		var route: Array = map.path_cells(map.nearest_cell(map.center("entrance")),map.nearest_cell(map.center(id)))
		expect(not route.is_empty(),"A* reaches building "+id)
		for i in range(route.size()):
			expect(map.is_road(route[i]),"route only on road")
			expect(not map.layout.water.has(route[i]) or map.layout.bridges.has(route[i]),"only bridges cross water")
			if i>0: expect(absi(route[i].x-route[i-1].x)+absi(route[i].y-route[i-1].y)==1,"orthogonal A* steps")
	expect(map.path_cells(Vector2i(-1,0),Vector2i.ZERO).is_empty(),"off-road route rejected")
	expect(map.goal_for(DataRegistry.enemy("explorer"),map.center("entrance"))=="throne","default throne goal")
	expect(map.goal_for(DataRegistry.enemy("thief"),map.center("entrance"))=="bait_treasure","thief attracted to decoy building")
	var no_decoy = load("res://scripts/map_builder/ApprovedBattleMap.gd").new()
	var changed: Dictionary = map.layout.duplicate(true)
	changed.buildings = changed.buildings.filter(func(b): return b.kind!="bait_treasure")
	no_decoy.setup(changed)
	expect(no_decoy.goal_for(DataRegistry.enemy("thief"),no_decoy.center("entrance"))=="vault","thief falls back to vault")
	var facility_goal: String = map.goal_for(DataRegistry.enemy("engineer"),map.center("entrance"))
	expect(facility_goal!="throne" and map.rooms.has(facility_goal),"facility enemy targets actual building")
	var unit: Node = game.monster_units[0]
	for key in ["road","bridge","water_adjacent","trap","defense_line","aura"]: expect(unit.get_cell_tags().has(key),"unit cell API "+key)
	for c in map.layout.bridges: expect(map.tags_at(c).bridge,"bridge tags")
	var initial_home: Vector2 = battle.home(unit)
	unit.position = map.center("vault"); battle.update_monster_path(unit)
	expect(not unit.path_points.is_empty() and unit.path_points[-1].distance_to(initial_home)<1,"leash returns to exact defense cell")
	for i in range(2000):
		unit._physics_process(1.0/60)
		if unit.position.distance_to(initial_home)<1: break
	expect(unit.position.distance_to(initial_home)<2,"real Unit navigation completes return")
	unit.position = initial_home
	battle.spawn_enemy("explorer",{})
	var enemy: Node = game.enemy_units[-1]
	expect(map.cell(enemy.position) in map.layout.doors.entrance.front,"spawn inside entrance door")
	expect(unit.get_cell_tags(enemy).cell==map.cell(enemy.position),"target cell API")
	var trap_cell: Vector2i
	for t in map.layout.traps:
		if t.kind=="spikes": trap_cell = Vector2i(t.cell[0],t.cell[1]); break
	enemy.position = map.world(trap_cell)
	var hp: int = enemy.hp; battle.apply_cell_traps(enemy)
	expect(enemy.hp<hp,"spikes damage existing Unit")
	var damaged: int = enemy.hp; battle.apply_cell_traps(enemy)
	expect(enemy.hp==damaged,"trap has per-enemy two-second cooldown")
	var temporary_cell: Vector2i = map.layout.doors.entrance.front[1]
	map.trap_cells.erase(temporary_cell)
	battle.add_trap_duration_modifier([temporary_cell],1.5,10,"slow_snail_test")
	expect(is_equal_approx(unit.trap_duration_multiplier(temporary_cell),1.5),"duration query exposed to monster")
	var trap: Dictionary = unit.create_temporary_trap(temporary_cell,"sticky",2,"slow_snail_test")
	expect(trap.ok and is_equal_approx(trap.remaining,3),"temporary sticky uses duration modifier")
	enemy.position = map.world(temporary_cell); battle.apply_cell_traps(enemy)
	expect(enemy.slow_factor==.55 and enemy.slow_timer>2.9,"sticky slow and adjusted duration")
	expect(enemy.get_cell_tags().trap=="sticky","temporary trap visible through cell tags")
	battle.tick_temporary_traps(3.1)
	expect(map.trap_cells.get(temporary_cell,"")=="","expired temporary trap removed")
	expect(not unit.create_temporary_trap(Vector2i(-1,-1),"sticky",2).ok,"invalid temporary trap rejected")
	# Building effects are spatial, not permanently tied to the assigned room.
	for role in ["barracks","recovery","watch_post","ward_core"]:
		var found := false
		for id in map.layout.influence:
			if map.rooms[id].facility_role!=role: continue
			for c in map.layout.influence[id]:
				if map.is_road(c): unit.position = map.world(c); found = true; break
			if found: break
		expect(found and battle._unit_in_facility_room(unit,role),"spatial aura "+role)
		if role=="barracks":
			expect(is_equal_approx(battle._facility_attack_multiplier(unit,enemy),1.25),"existing barracks attack 1.25")
			expect(battle._apply_facility_damage_taken_modifier(enemy,unit,100)==78,"existing barracks defense .78")
		elif role=="recovery":
			unit.hp = maxi(1,unit.max_hp-30); hp = unit.hp; battle.update_room_effects(1)
			expect(unit.hp>=hp+8,"existing recovery 8 HP per second")
		elif role=="watch_post":
			battle.update_room_effects(.1)
			expect(unit.attack_range>float(unit.get_meta("base_attack_range")),"watch range aura")
		else: expect(battle._apply_facility_damage_taken_modifier(enemy,unit,100)<100,"ward protects inside aura")
	unit.position = initial_home
	# Theft uses exactly the old 5s / max100 rule, without touching any saved file.
	battle.spawn_enemy("thief",{}); var thief: Node = game.enemy_units[-1]
	thief.goal_room = "vault"; thief.position = map.center("vault")
	for ally in game.monster_units: ally.position = map.center("entrance")
	var gold: int = GameState.gold; battle.tick_theft(thief,4.9)
	expect(GameState.gold==gold,"theft waits five seconds")
	battle.tick_theft(thief,.2)
	expect(GameState.gold==gold-100 and thief.goal_room=="entrance","old theft amount and escape goal")
	thief.position = map.center("entrance"); battle.tick_theft(thief,.1)
	expect(thief.escaped,"thief escape tracked without kill reward")
	# Existing equipped skill is invoked, including cooldown and cost.
	battle.set_pause_state(false)
	var pudding: Node = game.monster_units[0]; game.selected_unit = pudding
	pudding.skill_cooldowns.clear()
	expect(battle.request_unit_skill(pudding,0),"existing slime shield casts")
	expect(pudding.shield_timer>0 and not pudding.skill_ready("slime_shield"),"skill status and cooldown retained")
	for id in ["rally","focus_attack","emergency_retreat","hold_ground","lure_retreat"]: expect(battle.issue_command(id),"tactic "+id)
	# Verify command behavior, not only command acceptance.
	unit.position = initial_home; unit.stop_navigation()
	enemy.down = false; enemy.hp = enemy.max_hp; enemy.position = initial_home+Vector2(30,0)
	battle.spawn_enemy("explorer",{}); var focused: Node = game.enemy_units[-1]
	focused.position = initial_home+Vector2(40,0)
	battle.issue_command("focus_attack",initial_home,focused)
	expect(battle._combat_action_target(unit,[enemy,focused],80)==focused,"focus prefers explicitly selected enemy over nearest")
	unit.attack_cooldown = 0; var focused_hp: int = focused.hp; var nearest_hp: int = enemy.hp
	battle.try_attack(unit,[enemy,focused])
	expect(focused.hp<focused_hp and enemy.hp==nearest_hp,"focus attack damages selected enemy only")
	battle.issue_command("hold_ground"); unit.position = initial_home
	battle.update_monster_path(unit)
	expect(unit.path_points.is_empty(),"hold ground does not chase a nearby enemy")
	battle.issue_command("emergency_retreat",battle.map.center("throne"))
	battle.update_monster_path(unit); var retreat_path: Array = unit.path_points.duplicate()
	unit.attack_cooldown = 0; battle.try_attack(unit,[enemy,focused])
	expect(not retreat_path.is_empty() and unit.path_points==retreat_path,"retreat route cannot be cancelled by ordinary attacks")
	battle.command_until = 0; battle.command = "hold_ground"
	for speed in [1,2,3]: battle.set_speed(speed); expect(game.combat_speed==speed,"speed "+str(speed))
	battle.set_pause_state(true); expect(not pudding.is_physics_processing(),"pause freezes Unit status and movement")
	battle.set_speed(1)
	expect(pudding.is_physics_processing() and not game.combat_paused,"speed resumes simulation")
	# Early all-clear must not win while scheduled reinforcements remain.
	for e in game.enemy_units: e.down = true; e.hp = 0
	battle.check_combat_end(); expect(battle.running,"no premature victory")
	game.wave_manager.next_index = game.wave_manager.total_to_spawn
	battle.check_combat_end(); expect(battle.last_result.get("win",false),"wave annihilation wins")
	await get_tree().process_frame; await get_tree().process_frame
	expect(game.current_screen=="result" and game.result_summary.win,"existing result screen receives win")
	evidence["victory"] = battle.last_result.duplicate()
	await stop(); await boot(); start(); view.set_physics_process(false)
	GameState.damage_throne(GameState.demon_lord_hp)
	battle.check_combat_end()
	await get_tree().process_frame; await get_tree().process_frame
	expect(not battle.last_result.win and game.current_screen=="result","zero throne HP loses and opens result")
	evidence["defeat"] = battle.last_result.duplicate()

func mouse(point: Vector2, pressed: bool, right: bool = false) -> void:
	var event := InputEventMouseButton.new(); event.position = point; event.global_position = point
	event.button_index = MOUSE_BUTTON_RIGHT if right else MOUSE_BUTTON_LEFT; event.pressed = pressed
	get_viewport().push_input(event,true); await get_tree().process_frame
func click(point: Vector2, right: bool = false) -> void:
	await mouse(point,true,right); await mouse(point,false,right)
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==Vector2i(1920,1080),"actual 1920x1080 "+name)
	expect(image.save_png(OUT+name+".png")==OK,"capture "+name)
func capture() -> void:
	await click(Vector2(1150,55)); await get_tree().process_frame
	battle = view.battle
	expect(battle!=null and battle.running,"actual combat tab input")
	if battle==null: return
	await shot("battle_01_start")
	var contact := false; var trap := false; var skill := false
	var frames := 0
	while battle.running and frames<18000:
		await get_tree().process_frame; frames += 1
		if frames%600==0:
			var states := []
			for e in game.enemy_units:
				if e.is_alive(): states.append([e.unit_id,e.hp,str(battle.map.cell(e.position)),e.path_points.size(),e.goal_room])
			print("DAY7 time=",game.combat_time," spawned=",game.spawned_count," traps=",battle.trap_events.size()," alive=",states)
		if not contact and not battle.contacts.is_empty():
			contact = true
			var event: Dictionary = battle.contacts[0]
			expect(event.line=="1","first contact on first defense line")
			await shot("battle_02_contact")
		if not trap and not battle.trap_events.is_empty():
			trap = true; await shot("battle_03_trap")
			battle.direct_unit = null
		if contact and not skill:
			var unit: Node = game.monster_units[0]
			var location: Vector2 = view.world.to_global(unit.position-Vector2(0,40))
			await click(location)
			expect(view.battle_ui.selected==unit,"actual monster click opens adjacent skill icons")
			await shot("battle_04_skill")
			if not view.battle_ui.skill_buttons.is_empty():
				await click(view.battle_ui.skill_buttons[0].get_global_rect().get_center())
			skill = true
			await shot("battle_05_command_bar")
			await click(view.battle_ui.direct_button.get_global_rect().get_center())
			expect(battle.direct_unit==unit,"actual direct-control icon enables selected unit")
			await click(view.world.to_global(battle.map.world(Vector2i(6,8))),true)
			expect(not unit.path_points.is_empty(),"actual right click navigates direct-control unit")
		if contact and skill and trap and game.combat_speed==1: await click(view.battle_ui.speed_buttons["3"].get_global_rect().get_center())
	expect(not battle.running,"DAY7 actual wave runs to result")
	expect(contact and trap and skill,"all requested runtime states observed")
	await get_tree().create_timer(.4).timeout
	await shot("battle_06_result")
	expect(game.current_screen=="result","real result screen")
	evidence["day7"] = battle.last_result.duplicate()
	evidence["goals"] = battle.goal_events.duplicate(true)
	evidence["traps"] = battle.trap_events.duplicate(true)
	evidence["skills"] = battle.skill_events.duplicate(true)
	evidence["contacts"] = battle.contacts.duplicate(true)

func performance() -> void:
	start()
	game.wave_manager.next_index = game.wave_manager.total_to_spawn
	# Only the stress fixture has four repeated bodies; production roster is unique.
	for i in range(4):
		var source: Node = game.monster_units[i]
		var unit: Node = battle.make_unit(source.unit_id,DataRegistry.monster(source.unit_id),"monster",source.assigned_room)
		unit.position = source.position+Vector2(0,12); battle.homes[unit.get_instance_id()] = unit.position
		game.monster_units.append(unit)
	for i in range(10): battle.spawn_enemy("explorer",{"hp_scale":100,"atk_scale":.1})
	var focus: Vector2 = battle.home(game.monster_units[0])
	for i in range(10): game.enemy_units[i].position = focus+Vector2(35+i*3,18)
	for unit in game.monster_units: unit.max_hp = 100000; unit.hp = unit.max_hp
	var samples: Array[float] = []; var cpu: Array[float] = []; var physics: Array[float] = []
	var previous := Time.get_ticks_usec(); var start_time := previous
	while Time.get_ticks_usec()-start_time<20000000:
		await get_tree().process_frame
		var now := Time.get_ticks_usec(); var ms := (now-previous)/1000.0; previous = now
		if now-start_time>2000000:
			samples.append(ms); cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
			physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
	expect(game.monster_units.size()==18 and game.enemy_units.size()==10,"18 defenders plus 10 enemies")
	var mean := 0.0; var cpu_mean := 0.0; var physics_mean := 0.0
	for x in samples: mean += x
	for x in cpu: cpu_mean += x
	for x in physics: physics_mean += x
	samples.sort()
	evidence["performance"] = {"resolution":"1920x1080","renderer":"gl_compatibility","fps_cap":60,"warmup_seconds":2,"measurement_seconds":18,
		"frames":samples.size(),"mean_frame_ms":mean/samples.size(),"mean_fps":1000/(mean/samples.size()),
		"p95_frame_ms":samples[int(samples.size()*.95)],"p99_frame_ms":samples[int(samples.size()*.99)],
		"mean_process_ms":cpu_mean/cpu.size(),"mean_physics_ms":physics_mean/physics.size(),"monsters":18,"enemies":10,
		"alive_monsters":game.monster_units.filter(func(u): return u.is_alive()).size(),"alive_enemies":game.enemy_units.filter(func(u): return u.is_alive()).size(),
		"path_cache_queries":battle.map.route_queries,"target_fps":60}
	print("PERFORMANCE ",evidence.performance)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if OS.get_cmdline_user_args().has("--capture"): mode = "capture"
	elif OS.get_cmdline_user_args().has("--performance"): mode = "performance"
	var prior := {}
	for path in [Model.SAVE_PATH,Buildings.SAVE_PATH]:
		prior[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	await boot()
	if mode=="capture": await capture()
	elif mode=="performance": await performance()
	else: await direct()
	for path in prior: expect(prior[path]==(FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()),"earlier test save preserved "+path)
	await stop()
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"evidence":evidence}
	var file := FileAccess.open(OUT+mode+"_result.json",FileAccess.WRITE); file.store_string(JSON.stringify(result,"\t")); file.close()
	print("V130RStep4BattleTest ",mode," ",checks," checks / ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
