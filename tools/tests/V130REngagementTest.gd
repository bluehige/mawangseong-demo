extends "res://tools/tests/V130RCommandsTest.gd"
## Production controller and actors, with isolated positions for contact cases.
func write_json(id: String, data) -> void:
	var f := FileAccess.open("res://tmp/v130r_engage/unit/"+id+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"\t")); f.close()

func run() -> void:
	unit_only=true # This suite inherits disposal, not the paired crisis policy.
	started=Time.get_ticks_msec(); run_seed=130401; stack_source="v13_final"
	expect(OS.get_user_data_dir().replace("\\","/").contains("v130r_engage"),"isolated engagement regression")
	for path in ["res://data/waves.json","res://data/v122/dual_front_day01_05_waves.json"]:
		check_priorities(JSON.parse_string(FileAccess.get_file_as_string(path)))
	if not failures.is_empty(): get_tree().quit(1); return
	await create_game(); base_controller=game.combat_scene
	if not await restore_entry(read_entry(5)): await finish_commands(); return
	var b=await start_test_battle()
	if b==null: await finish_commands(); return
	var defender: Node=game.monster_units[0]
	# Only one live guard in these synthetic contact cases; no user save is read.
	for other in game.monster_units:
		if other!=defender: other.down=true
	var origin: Vector2=defender.position
	b.spawn_enemy("explorer",{"objective_priority":1.0})
	var ordinary: Node=game.enemy_units[-1]
	expect(not ordinary.get_meta("objective_priority"),"ordinary explorer cannot inherit objective bypass")
	ordinary.position=origin+Vector2(70,0)
	expect(b.enemy_engagement_target(ordinary)==defender,"ordinary enemy acquires nearby guard")
	b.update_enemy_path(ordinary)
	expect(ordinary.tactical_state==Constants.UNIT_STATE_MOVE_TO_TARGET,"ordinary enemy pursues guard instead of throne")
	ordinary.down=true
	for id in ["thief","engineer"]:
		b.spawn_enemy(id,{"objective_priority":1.0,"attack_throne":true})
		var enemy: Node=game.enemy_units[-1]
		expect(enemy.get_meta("objective_priority"),id+" retains authored objective role")
		enemy.position=origin+Vector2(70,0)
		expect(b.enemy_engagement_target(enemy)==null,id+" keeps an unobstructed objective route")
		enemy.position=origin+Vector2(35,0)
		expect(b.enemy_engagement_target(enemy)==defender,id+" fights a body blocker")
		enemy.attack_cooldown=5.0
		enemy.path_points=[origin-Vector2(80,0)]
		b.hold_enemy_contact(enemy)
		expect(enemy.path_points.is_empty(),id+" cannot walk through a guard during attack cooldown")
		enemy.goal_room="throne"
		expect(not b.prioritizes_throne(enemy),id+" cannot prioritize throne through a guard")
		enemy.attack_cooldown=0.0
		var hp_before: int=defender.hp
		b.try_attack(enemy,game.monster_units)
		for tween in b.active_combat_tweens.duplicate():
			if tween!=null and tween.is_valid(): tween.pause(); tween.custom_step(2.0)
		expect(defender.hp<hp_before,id+" actually deals damage to the blocking monster")
		var start := origin+Vector2(90,0)
		enemy.position=origin-Vector2(90,0)
		b.block_enemy_step(enemy,start)
		expect(enemy.position.x>=origin.x+b.BODY_BLOCK_RADIUS-.1,id+" swept fast frame cannot tunnel through guard")
		enemy.position=start
		b.hero_dash_states[enemy.get_instance_id()]={"unit":enemy,"target":defender,"start":start,"end":origin-Vector2(90,0),"elapsed":0.0,"finished":false}
		b._update_hero_dashes(.1)
		expect(b.hero_dash_states[enemy.get_instance_id()].end.x>=origin.x+b.BODY_BLOCK_RADIUS-.1,id+" inherited hero dash endpoint stops at first guard")
		b.hero_dash_states.clear()
		enemy.position=origin+Vector2(35,0)
		defender.down=true
		expect(b.enemy_engagement_target(enemy)==null,id+" releases a dead blocker")
		defender.down=false
		enemy.down=true
	# A false destination must not consume the authored real waypoint. Expiry
	# must also restore that goal while a nearby guard is being fought.
	b.spawn_enemy("investigator",{"waypoint_room_id":"barracks"})
	var fooled: Node=game.enemy_units[-1]
	fooled.set_meta("next_objective","throne")
	fooled.set_meta("v130r_original_goal","barracks")
	fooled.set_meta("v130r_false_goal","entrance")
	fooled.set_meta("v130r_false_until",2.0)
	fooled.new_skill_clock=0.0; fooled.goal_room="entrance"
	fooled.position=b.map.center("entrance")
	b.update_enemy_path(fooled)
	expect(str(fooled.get_meta("next_objective",""))=="throne","false goal arrival preserves the real waypoint continuation")
	fooled.set_meta("next_objective","throne")
	fooled.new_skill_clock=3.0; fooled.position=b.map.center("barracks")
	b.update_enemy_path(fooled)
	expect(fooled.goal_room=="throne" and not fooled.has_meta("next_objective"),"expired illusion restores and completes the real waypoint even beside a guard")
	expect(not game._has_defense_wave_for_day(29),"DAY29 remains combat-free")
	await finish_commands()

func check_priorities(value: Variant, role: String = "") -> void:
	if value is Dictionary:
		role=str(value.get("enemy_id",role))
		for key in value:
			if key=="objective_priority": expect(float(value[key])==0 or role in ["thief","engineer"],"only objective roles have priority, including grade overrides")
			check_priorities(value[key],role)
	elif value is Array:
		for item in value: check_priorities(item,role)
