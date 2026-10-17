extends RefCounted
## Branch map skills. Timers use simulation seconds, never wall-clock time.
const CELL := 71.554175
const Spec = preload("res://scripts/systems/SpecializationEffects.gd")

func v(unit: Node, id: String, field: String, base: float) -> float:
	return Spec.value(battle.root._monster_specialization(unit.unit_id),id,field,base)

func flag(unit: Node, key: String, fallback: Variant = null) -> Variant:
	return Spec.flag(battle.root._monster_specialization(unit.unit_id),key,fallback)
var battle_ref: WeakRef
var battle: RefCounted:
	get: return battle_ref.get_ref() if battle_ref!=null else null
var definitions: Dictionary = {}

func setup(controller: RefCounted) -> void:
	battle_ref = weakref(controller)
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/v130r/skills_new.json"))
	for unit in battle.root.monster_units:
		if unit.unit_id=="under_bed_shadow": unit.hidden_until = 5.0
		if unit.unit_id=="curse_doll" and battle.root.monster_units.any(func(u): return u.unit_id=="spider_tailor"):
			unit.max_hp = roundi(unit.max_hp*1.1); unit.hp = unit.max_hp
		if unit.unit_id=="bridge_troll":
			unit.set_meta("bridge_base_hp",unit.max_hp)
			update_bridge(unit)
			unit.hp = unit.max_hp

func update_bridge(unit: Node) -> void:
	var active := beside_bridge(unit)
	var old: bool = bool(unit.get_meta("bridge_bonus",false))
	if old==active: return
	unit.def += 4 if active else -4
	var base: int = int(unit.get_meta("bridge_base_hp",unit.max_hp))
	unit.max_hp = roundi(base*1.1) if active else base
	unit.hp = mini(unit.hp,unit.max_hp)
	unit.set_meta("bridge_bonus",active)

func beside_bridge(unit: Node) -> bool:
	var cell: Vector2i = battle.map.cell(unit.position)
	for offset in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		if battle.map.tags_at(cell+offset).get("bridge",false): return true
	return false

func nearby(unit: Node, units: Array, cells: float) -> Array:
	return units.filter(func(u): return u.is_alive() and u.position.distance_to(unit.position)<=cells*CELL)

func enemies(unit: Node, cells: float) -> Array:
	return nearby(unit,battle.root.enemy_units,cells)

func allies(unit: Node, cells: float) -> Array:
	return nearby(unit,battle.root.monster_units,cells)

func target(unit: Node, cells: float = 3.0) -> Node:
	var candidates := enemies(unit,cells)
	candidates = candidates.filter(func(u): return u.is_targetable_by(unit))
	candidates.sort_custom(func(a,b): return a.position.distance_to(unit.position)<b.position.distance_to(unit.position))
	return candidates[0] if not candidates.is_empty() else null

func tick(delta: float) -> void:
	for unit in battle.root.monster_units+battle.root.enemy_units:
		unit.new_skill_clock += delta
		if not unit.is_alive(): continue
		if unit.unit_id=="under_bed_shadow": unit.quiet_seconds += delta
		if unit.unit_id=="bridge_troll": update_bridge(unit)
		if unit.reassemble_pending>=0:
			unit.reassemble_pending -= delta
			if unit.reassemble_pending<=0:
				unit.reassemble_pending = -1
				var before: int = unit.hp
				unit.heal(roundi(unit.max_hp*.25))
				if unit.hp > before: unit.set_meta("ach_reassembled",true)
		if unit.unit_id=="candle_wisp":
			for enemy in enemies(unit,3):
				if not enemy.is_targetable_by(unit): AchievementService.count("STAT_WISP_REVEAL")
				enemy.set_meta("revealed_until",enemy.new_skill_clock+.2)

func slow_theft(thief: Node) -> float:
	for unit in battle.root.monster_units:
		if unit.is_alive() and unit.unit_id=="rat_union" and unit.position.distance_to(thief.position)<=3*CELL: return .5
	return 1.0

func sticky_extra(cell: Vector2i) -> float:
	for unit in battle.root.monster_units:
		if unit.is_alive() and unit.unit_id=="glue_snail" and unit.position.distance_to(battle.map.world(cell))<=2*CELL: return 2.0
	return 0.0

func is_thief(unit: Node) -> bool:
	return "thief" in str(unit.unit_id) or str(unit.get_meta("goal_type",""))=="treasure"

func recover_gold(thief: Node, fraction: float) -> int:
	var held := int(thief.get_meta("stolen_gold",0))
	var amount := roundi(held*fraction)
	thief.set_meta("stolen_gold",held-amount)
	GameState.gold += amount
	battle.root.treasure_gold_stolen_this_battle = maxi(0,battle.root.treasure_gold_stolen_this_battle-amount)
	return amount

func on_downed(unit: Node) -> void:
	if unit.faction!="enemy" or not is_thief(unit): return
	for ally in battle.root.monster_units:
		if ally.is_alive() and ally.unit_id=="rat_union" and ally.position.distance_to(unit.position)<=float(flag(ally,"recovery_radius_cells",3))*CELL:
			var recovered := recover_gold(unit,1.0)
			AchievementService.count("STAT_RAT_GOLD",recovered)
			GameState.gold += roundi(recovered*(float(flag(ally,"recovery_gold_multiplier",1))-1))
			return

func on_hit(attacker: Node, defender: Node) -> void:
	attacker.break_stealth()
	if attacker.unit_id=="bridge_troll" and is_thief(defender) and attacker.skill_ready("toll_shakedown"):
		toll(defender,attacker); attacker.set_skill_cooldown("toll_shakedown",8)

func toll(thief: Node, caster: Node = null) -> void:
	# A completed thief's negative escape sentinel must survive the progress reset.
	if float(battle.root.thief_steal_timers.get(thief,0))>=0: battle.root.thief_steal_timers[thief] = 0.0
	var recovered := recover_gold(thief,.5)
	AchievementService.count("STAT_TROLL_TOLL",recovered)
	if caster!=null and float(flag(caster,"toll_recovery_ratio",0))>0:
		# Toll gold is picked up at settlement, not minted twice.
		GameState.gold -= recovered
		battle.root.treasure_gold_stolen_this_battle += recovered
		caster.set_meta("spec_toll_pending",int(caster.get_meta("spec_toll_pending",0))+recovered)

func false_goal(enemy: Node, goal: String, seconds: float) -> void:
	if not enemy.has_meta("v130r_original_goal"): enemy.set_meta("v130r_original_goal",enemy.goal_room)
	enemy.set_meta("v130r_false_goal",goal)
	enemy.set_meta("v130r_false_until",enemy.new_skill_clock+seconds)
	enemy.goal_room = goal; enemy.stop_navigation()

func update_false_goal(enemy: Node) -> bool:
	if not enemy.has_meta("v130r_original_goal"): return false
	if enemy.new_skill_clock<float(enemy.get_meta("v130r_false_until",0)):
		enemy.goal_room = str(enemy.get_meta("v130r_false_goal"))
		battle.move_unit_to_point(enemy,battle.map.center(enemy.goal_room),true)
		return true
	enemy.goal_room = str(enemy.get_meta("v130r_original_goal"))
	enemy.remove_meta("v130r_original_goal"); enemy.stop_navigation()
	return false

func hop_destination(unit: Node) -> Dictionary:
	var line := str(unit.get_cell_tags().get("defense_line","1"))
	var number: int = {"1":1,"2":2,"final":3}.get(line,1)
	var best := {}; var distance := INF
	for building in battle.view.placement.buildings:
		var points: Array = battle.view.placement.defense_points.get(building.id,[])
		for slot in range(points.size()):
			var point: Vector2 = battle.map.world(points[slot])
			var candidate: String = str(battle.map.tags_at(points[slot]).get("defense_line","1"))
			var candidate_number: int = {"1":1,"2":2,"final":3}.get(candidate,1)
			if candidate_number<number or candidate_number>number+1 or point.distance_to(unit.position)<CELL*.5: continue
			if battle.root.monster_units.any(func(u): return u!=unit and u.is_alive() and (u.position.distance_to(point)<CELL*.6 or battle.home(u).distance_to(point)<CELL*.6)): continue
			for enemy in battle.root.enemy_units:
				if not enemy.is_alive(): continue
				var gap: float = enemy.position.distance_to(point)
				if gap<=2*CELL and gap<distance:
					distance = gap; best = {"point":point,"building":building.id,"slot":slot}
	return best

func cast(unit: Node, id: String, automatic: bool = false) -> bool:
	if not definitions.has(id) or bool(definitions[id].passive) or not unit.is_alive() or not unit.skill_ready(id): return false
	if unit.active_skills_locked() or unit.duo_action_locked() or unit.action_interrupt_timer>0: return false
	var enemy := target(unit)
	var friends := allies(unit,v(unit,id,"radius_cells",2))
	var affected: Array = []
	match id:
		"tongue_snag":
			var candidates := enemies(unit,v(unit,id,"range",3*CELL)/CELL)
			candidates = candidates.filter(func(u): return u.is_targetable_by(unit) and (u.get_cell_tags().bridge or u.get_cell_tags().water_adjacent))
			if candidates.is_empty(): return false
			enemy = candidates[0]; enemy.apply_root(v(unit,id,"root_seconds",1.5)); enemy.apply_slow(3,.6); affected = [enemy]
			if enemy.root_timer > 0 and enemy.get_cell_tags().bridge: AchievementService.count("STAT_FROG_SNAG")
		"puddle_song":
			if friends.is_empty() or (automatic and enemies(unit,3).is_empty()): return false
			for ally in friends: ally.activate_guard(5,roundi(v(unit,id,"def_bonus",3)))
			affected = friends
		"slime_trail":
			var cells: Array = battle.map.layout.road_cells.keys()
			cells.sort_custom(func(a,b): return battle.map.world(a).distance_to(unit.position)<battle.map.world(b).distance_to(unit.position))
			var chosen: Array = []
			for cell in cells:
				if battle.map.world(cell).distance_to(unit.position)>2*CELL: break
				if (battle.map.world(cell)-unit.position).dot(battle.map.center("entrance")-unit.position)>0 and battle.map.world(cell).distance_to(unit.position)>8 and not battle.temporary_traps.any(func(t): return t.cell==cell):
					chosen.append(cell)
					if chosen.size()>=roundi(v(unit,id,"trap_count",1)): break
			if chosen.is_empty(): return false
			for cell in chosen:
				if not unit.create_temporary_trap(cell,"sticky",6,id).get("ok",false): return false
		"shell_retreat":
			if unit.hp>unit.max_hp*.35: return false
			unit.activate_shield(4,v(unit,id,"reduction",.6))
		"no_passage","hero_pose":
			affected = enemies(unit,v(unit,id,"radius_cells",1.5))
			if id=="hero_pose": affected = affected.slice(0,roundi(v(unit,id,"max_targets",3)))
			if affected.is_empty(): return false
			for opponent in affected: opponent.apply_taunt(unit,v(unit,id,"duration",3 if id=="no_passage" else 4))
		"toll_shakedown":
			var thieves := enemies(unit,unit.attack_range/CELL).filter(func(u): return is_thief(u))
			if thieves.is_empty(): return false
			enemy = thieves[0]; deal(unit,enemy,1.0); toll(enemy,unit); affected = [enemy]
		"peekaboo":
			if enemy==null or not unit.stealthed() or unit.position.distance_to(enemy.position)>unit.attack_range: return false
			var fear := v(unit,id,"fear_radius_cells",0)
			deal(unit,enemy,1.8); affected = nearby(enemy,battle.root.enemy_units,fear) if fear>0 else [enemy]
			for opponent in affected:
				if opponent.is_alive():
					false_goal(opponent,"entrance",v(unit,id,"duration",2.5))
					AchievementService.count("STAT_SHADOW_FEAR")
		"blanket_hide":
			if automatic and unit.stealthed(): return false
			unit.hidden_until = unit.new_skill_clock+3; unit.quiet_seconds = 0
		"reassemble":
			if unit.reassemble_used or unit.hp>unit.max_hp*.3: return false
			unit.reassemble_used = true; unit.reassemble_pending = 3; unit.activate_shield(3,.9)
		"wax_drip":
			if enemy==null: return false
			var holy: bool = "selen" in str(enemy.unit_id) or "paladin" in str(enemy.unit_id) or "exorcist" in str(enemy.unit_id)
			deal(unit,enemy,1.3 if holy else 1.0,true); enemy.apply_slow(2,.8); affected = [enemy]
			var seconds := v(unit,id,"burn_seconds",0)
			if seconds>0:
				for opponent in nearby(enemy,battle.root.enemy_units,v(unit,id,"burn_radius_cells",0)):
					opponent.set_meta("spec_burn_until",opponent.new_skill_clock+seconds)
					opponent.set_meta("spec_burn_dps",v(unit,id,"burn_dps",0))
		"tunnel_hop":
			var destination := hop_destination(unit)
			if destination.is_empty(): return false
			unit.position = destination.point; unit.stop_navigation()
			unit.assigned_room = destination.building; battle.homes[unit.get_instance_id()] = unit.position
			unit.refresh_depth_slot()
			var duration := v(unit,id,"ally_guard_seconds",0)
			if duration>0:
				for ally in allies(unit,v(unit,id,"ally_guard_radius_cells",2)): ally.activate_guard(duration,roundi(v(unit,id,"ally_guard_bonus",0)))
		"undermine":
			var candidates := enemies(unit,2).filter(func(u): return "engineer" in str(u.unit_id) or "shield" in str(u.unit_id))
			candidates.sort_custom(func(a,b): return "engineer" in str(a.unit_id) and not "engineer" in str(b.unit_id))
			if candidates.is_empty(): return false
			enemy = candidates[0]; enemy.apply_action_interrupt(v(unit,id,"interrupt_seconds",2.5)); enemy.apply_armor_break(3,4,id); affected = [enemy]
			if "engineer" in str(enemy.unit_id) and enemy.action_interrupt_timer > 0: AchievementService.count("STAT_MOLE_SABOTAGE")
		"wrong_way":
			affected = enemies(unit,2.5).filter(func(u): return "explorer" in str(u.unit_id) or (bool(flag(unit,"wrong_way_investigator",false)) and "investigator" in str(u.unit_id)))
			if affected.is_empty(): return false
			for opponent in affected:
				var goals: Array = battle.map.layout.doors.keys().filter(func(key): return key!=opponent.goal_room and key!="entrance")
				if not goals.is_empty():
					false_goal(opponent,str(goals[0]),v(unit,id,"duration",4))
					if "explorer" in str(opponent.unit_id): AchievementService.count("STAT_MAP_LOST")
		"map_spread":
			if friends.is_empty() or (automatic and enemies(unit,3).is_empty()): return false
			for ally in friends: ally.apply_night_relay_buff(id,5,v(unit,id,"move_multiplier",1.15),1.0)
			affected = friends
		"swarm":
			if enemy==null or unit.position.distance_to(enemy.position)>unit.attack_range: return false
			for hit in range(roundi(v(unit,id,"hits",3))):
				if enemy.is_alive(): deal(unit,enemy,1.0)
			enemy.apply_slow(2,.85); affected = [enemy]
		"stitch_curse":
			var candidates := enemies(unit,3)
			candidates.sort_custom(func(a,b): return is_boss(a) and not is_boss(b))
			if candidates.is_empty(): return false
			enemy = candidates[0]; enemy.set_meta("curse_until",enemy.new_skill_clock+v(unit,id,"duration",6)); affected = [enemy]
			enemy.set_meta("curse_attack_multiplier",v(unit,id,"attack_multiplier",.85))
			enemy.set_meta("curse_damage_multiplier",v(unit,id,"damage_taken_multiplier",1.2))
		"proxy_pain":
			friends = friends.filter(func(u): return u!=unit and u.hp<u.max_hp)
			friends.sort_custom(func(a,b): return float(a.hp)/a.max_hp<float(b.hp)/b.max_hp)
			if friends.is_empty(): return false
			affected = friends.slice(0,roundi(v(unit,id,"max_targets",1)))
			for ally in affected: ally.apply_duo_damage_redirect(unit,5,v(unit,id,"redirect_ratio",.3))
		_: return false
	unit.set_skill_cooldown(id,maxf(0,v(unit,id,"cooldown",float(definitions[id].cooldown))))
	if id!="blanket_hide": unit.break_stealth()
	unit.play_skill(enemy.global_position if enemy!=null else Vector2.ZERO)
	battle.skill_events.append({"time":battle.root.combat_time,"unit":unit.unit_id,"skill":id,"automatic":automatic})
	battle.duos.skill(unit,id)
	for recipient in affected:
		battle.spawn_effect_burst("shield_pulse" if recipient.faction=="monster" else "hit_slash",recipient.position)
	return true

func is_boss(unit: Node) -> bool:
	return bool(DataRegistry.enemies.get(unit.unit_id,{}).get("boss",false)) or "hero" in str(unit.unit_id) or "leon" in str(unit.unit_id) or "selen" in str(unit.unit_id)

func deal(caster: Node, victim: Node, multiplier: float, magic: bool = false) -> int:
	var amount := DamageService.compute(caster,victim,multiplier)
	amount = roundi(amount*victim.damage_taken_multiplier_from(caster)*battle._facility_attack_multiplier(caster,victim))
	amount = battle._apply_facility_damage_taken_modifier(caster,victim,amount)
	victim.incoming_source = caster
	var lost: int = victim.receive_magic_damage(amount) if magic else victim.receive_damage(amount)
	battle.spawn_damage_number(victim.position,lost,victim.faction,victim)
	return lost
