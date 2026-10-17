extends "res://scripts/game/CombatSceneController.gd"
## Branch-only spatial adapter. Attacks, AI decisions, skills and settlement reuse
## CombatSceneController; road topology replaces the former room navigation.
const BattleMap = preload("res://scripts/map_builder/ApprovedBattleMap.gd")
const BattleUnit = preload("res://scripts/units/ApprovedBattleUnit.gd")
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const MapLayout = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const Presentation = preload("res://scripts/map_builder/ApprovedActorPresentation.gd")
const Occlusion = preload("res://scripts/map_builder/ApprovedBattleOcclusion.gd")
var occlusion: RefCounted
var map := BattleMap.new()
var view: Control
var actors: Node2D
var visuals: Node2D
var assignments := {}
var members := {}
var homes := {}
var command := "hold_ground"
var command_point := Vector2.ZERO
var command_target: Node
var command_until := 0.0
var direct_unit: Node
var temporary_traps: Array[Dictionary] = []
var duration_modifiers: Array[Dictionary] = []
var trap_next_hits := {}
var trap_events: Array[Dictionary] = []
var skill_events: Array[Dictionary] = []
var goal_events: Array[Dictionary] = []
var contacts: Array[Dictionary] = []
var running := false
var last_result := {}
var ai_accumulator := 0.0
var ai_interval := .12
var effects_home: Node
var original_controller
var original_graph
var original_rooms: Dictionary
var spec_effects = preload("res://scripts/systems/SpecializationEffects.gd").new()
var monster_skills = preload("res://scripts/combat/V130RMonsterSkills.gd").new()

func begin(map_view: Control) -> void:
	view = map_view; root = view.root
	original_controller = root.combat_scene; original_graph = root.graph; original_rooms = root.rooms
	setup(root,original_controller.hud)
	map.setup(view.placement); assignments = view.monster_ui.assignments.duplicate(true); members = view.monster_ui.members
	root.combat_scene = self; root.graph = map; root.rooms = map.rooms
	root.set_physics_process(false); root.set_process_input(false)
	root.world_overlay_layer.hide()
	if root.quarter_renderer!=null: root.quarter_renderer.set_world_layers_visible(false)
	root.current_screen = Constants.SCREEN_COMBAT
	root.combat_time = 0.0; root.combat_speed = 1.0; root.combat_paused = false
	root.spawned_count = 0; root.thief_steal_timers.clear(); root.treasure_gold_stolen_this_battle = 0
	root.thieves_spawned_this_battle = 0; root.thieves_escaped_this_battle = 0
	root.thieves_reached_treasure_this_battle = 0; root.thieves_completed_theft_this_battle = 0
	root.rewards_pending = {"gold":0,"mana":0,"food":0,"infamy":0}
	GameState.day = int(view.placement.day); GameState.gold = int(view.placement.resources.gold)
	GameState.mana = int(view.placement.resources.mana); GameState.food = int(view.placement.resources.food)
	if view.food_enabled():
		GameState.food_state = GameState.Food.migrate(view.placement.get("food_state",{}),GameState.day)
		GameState.food_income = GameState.Food.income(GameState.day)
	GameState.defeat = false; GameState.victory = false
	root.battle_resource_start = _resource_balance_snapshot()
	root.monster_units.clear(); root.enemy_units.clear(); root.selected_unit = null
	actors = Node2D.new(); actors.name = "LiveBattleSimulation"; root.unit_root.add_child(actors)
	visuals = Node2D.new(); visuals.name = "LiveBattleActors"; view.world.add_child(visuals)
	occlusion = Occlusion.new(); occlusion.build(view,visuals)
	# VFX share the same world transform as live units and map pieces.
	effects_home = root.effect_root.get_parent(); root.effect_root.reparent(view.world,false)
	root.effect_root.position = Vector2.ZERO; root.effect_root.z_index = 3501
	root.effect_root.show()
	spawn_monsters()
	monster_skills.setup(self)
	spec_effects.setup(self)
	root.wave_manager.setup(GameState.day,DataRegistry.waves)
	# Small seeded timing variation belongs to the approved map's wave entries.
	for entry in root.wave_manager.schedule:
		var jitter := maxf(0,float(entry.get("spawn_jitter",0)))
		if jitter>0: entry.time = maxf(0,float(entry.time)+randf_range(-jitter,jitter))
	root.wave_manager.schedule.sort_custom(func(a,b): return float(a.time)<float(b.time))
	running = true

func make_unit(id: String, stats: Dictionary, faction: String, room_id: String) -> Node:
	var unit = BattleUnit.new(); unit.battle_map = map; unit.battle_runtime = self
	actors.add_child(unit); unit.setup(id,stats,faction,room_id)
	unit.attach_map_visuals(visuals)
	unit.downed.connect(on_unit_downed)
	return unit

func spawn_monsters() -> void:
	for id in assignments:
		var row: Dictionary = members[id]; var species := str(row.species_id)
		var building := str(assignments[id].building)
		var stats: Dictionary = row.stats.duplicate(true)
		root._apply_specialization_stats(species,stats)
		if GameState.is_hungry(species): stats.atk = maxi(1,roundi(float(stats.atk)*.8))
		# Preview uses the same initial roster level as placement, not personal saves.
		var unit = make_unit(species,stats,Constants.FACTION_MONSTER,building)
		unit.set_meta("food_hungry",GameState.is_hungry(species))
		unit.display_name = row.display_name; unit.name_label.text = row.display_name+(" · 굶주림" if GameState.is_hungry(species) else "")
		unit.set_meta("instance_id",id); unit.set_meta("base_attack_range",unit.attack_range)
		unit.position = defense_home(assignments[id])
		homes[unit.get_instance_id()] = unit.position
		root.monster_roster[species] = root.monster_roster.get(species,{"level":1,"exp":0}).duplicate(true)
		root.monster_roster[species]["room"] = building
		unit.face_direction(map.center("entrance")-unit.position)
		root.monster_units.append(unit)

func spawn_enemy(enemy_id: String, wave_entry: Dictionary = {}) -> void:
	var stats := _scaled_enemy_stats(enemy_id,wave_entry)
	if stats.is_empty(): return
	var unit = make_unit(enemy_id,stats,Constants.FACTION_ENEMY,"entrance")
	var front: Array = map.layout.doors.entrance.front
	var lane: int = randi_range(0,front.size()-1) if bool(wave_entry.get("route_variation",false)) else root.spawned_count%front.size()
	unit.position = map.world(front[lane])
	unit.goal_room = map.goal_for(stats,unit.position,str(wave_entry.get("target_room_id","")))
	# Recon thieves may take the other branch directly to the real vault.
	if enemy_id=="thief" and bool(wave_entry.get("route_variation",false)) and randf()<.5 and str(wave_entry.get("target_room_id",""))=="": unit.goal_room = "vault"
	var objective_room := str(unit.goal_room)
	if enemy_id=="investigator" and bool(wave_entry.get("route_variation",false)) and randf()<.5 and map.layout.doors.has("ward_core"):
		unit.set_meta("next_objective",unit.goal_room); unit.goal_room = "ward_core"
	# An explicit flank preserves the final objective and the default RNG draws.
	var waypoint := str(wave_entry.get("waypoint_room_id",""))
	if enemy_id in ["investigator","royal_scout"] and map.layout.doors.has(waypoint) and waypoint!=objective_room:
		unit.set_meta("next_objective",objective_room); unit.goal_room = waypoint
	unit.set_meta("goal_type",str(stats.get("goal_type","throne")))
	var objective_chance := clampf(float(wave_entry.get("objective_priority",0)),0,1)
	unit.set_meta("objective_priority",objective_chance>0 and randf()<objective_chance)
	unit.set_meta("base_attack_range",unit.attack_range)
	unit.set_path(map.path_to_point(unit.position,map.center(unit.goal_room)))
	root.enemy_units.append(unit); root.spawned_count += 1
	if enemy_id=="thief": root.thieves_spawned_this_battle += 1
	goal_events.append({"time":root.combat_time,"id":enemy_id,"goal":unit.goal_room,"spawn_cell":str(map.cell(unit.position))})

func physics_process(delta: float) -> void:
	if not running or root.current_screen!=Constants.SCREEN_COMBAT or root.combat_paused: return
	var sim_delta: float = delta*root.combat_speed
	root.combat_time += sim_delta
	monster_skills.tick(sim_delta)
	spec_effects.tick(sim_delta)
	_update_sfx_cooldowns(delta); damage_presentation.tick(delta)
	spawn_ready_enemies(sim_delta); refresh_unit_rooms()
	for unit in root.monster_units+root.enemy_units:
		unit.set_simulation_speed(root.combat_speed)
	# Existing status/support and enemy ability runtimes are kept on simulation time.
	single_floor_support.tick_thread(); royal_support.tick(sim_delta)
	crown_mobility.tick(sim_delta); native_objectives.tick(sim_delta)
	_update_hero_dashes(sim_delta); _update_active_flame_zones(sim_delta)
	ai_accumulator += sim_delta
	if ai_accumulator>=ai_interval:
		ai_accumulator = fmod(ai_accumulator,ai_interval)
		for unit in root.monster_units:
			if unit.is_alive(): update_monster_path(unit)
		for enemy in root.enemy_units:
			if enemy.is_alive(): update_enemy_path(enemy)
	update_room_effects(sim_delta)
	for unit in root.monster_units+root.enemy_units:
		if unit.is_alive(): try_attack(unit,root.enemy_units if unit.faction==Constants.FACTION_MONSTER else root.monster_units)
	check_combat_end()

func defense_home(assignment: Dictionary) -> Vector2:
	# Stable slot-specific offsets stay strictly inside the assigned diamond.
	var offsets := [Vector2(-24,0),Vector2(0,-12),Vector2(0,12),Vector2(24,0),
		Vector2(-12,-6),Vector2(12,-6),Vector2(-12,6),Vector2(12,6)]
	return map.world(Members.cell(view.placement,assignment))+offsets[int(assignment.slot)%offsets.size()]

func home(unit: Node) -> Vector2: return homes.get(unit.get_instance_id(),unit.position)
func leash_radius(_unit: Node) -> float: return 3.0*71.554175 # Three orthogonal cells.

func local_target(unit: Node) -> Node:
	var candidates: Array = []
	for enemy in root.enemy_units:
		if enemy.is_alive() and enemy.position.distance_to(home(unit))<=leash_radius(unit): candidates.append(enemy)
	if is_instance_valid(command_target) and command_target in candidates: return command_target
	if unit.new_skill_clock<float(unit.get_meta("spec_team_until",0)):
		var marked = instance_from_id(int(unit.get_meta("spec_team_target",0)))
		if is_instance_valid(marked) and marked in candidates: return marked
	return TargetingService.monster_priority(unit,candidates,map,"throne","vault")

func update_monster_path(unit: Node) -> void:
	if unit==direct_unit: return
	if root.combat_time<command_until and command=="hold_ground":
		try_auto_monster_skill(unit); return_home(unit); return
	if root.combat_time<command_until and command in ["rally","emergency_retreat","lure_retreat"]:
		move_unit_to_point(unit,command_point,true); return
	if unit.position.distance_to(home(unit))>leash_radius(unit)+2:
		return_home(unit); return
	var target := local_target(unit)
	if target==null:
		# Retain support skill decisions even without an attack target.
		try_auto_monster_skill(unit); return_home(unit); return
	# Run the established monster AI and its specialization/skill decisions against
	# spatially filtered opponents. Navigation below enforces the home tether.
	var all_enemies: Array = root.enemy_units
	var local_enemies: Array = []
	for enemy in all_enemies:
		if enemy.is_alive() and enemy.position.distance_to(home(unit))<=leash_radius(unit): local_enemies.append(enemy)
	root.enemy_units = local_enemies
	super.update_monster_path(unit)
	root.enemy_units = all_enemies
	if not unit.path_points.is_empty():
		for p in unit.path_points:
			if p.distance_to(home(unit))>leash_radius(unit)+2: return_home(unit); break

func return_home(unit: Node) -> void:
	if unit.position.distance_to(home(unit))>2:
		move_unit_to_point(unit,home(unit),true)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM,"수비 칸 복귀")
	else:
		unit.stop_navigation()
		unit.face_direction(map.center("entrance")-unit.position)

func update_enemy_path(unit: Node) -> void:
	if monster_skills.update_false_goal(unit): return
	if str(unit.get_meta("next_objective",""))!="" and unit.position.distance_to(map.center(unit.goal_room))<18:
		unit.goal_room = str(unit.get_meta("next_objective")); unit.remove_meta("next_objective")
	if unit.unit_id=="thief" and float(root.thief_steal_timers.get(unit,0))<-100:
		unit.goal_room = "entrance"
	var target: Node = unit.forced_attack_target(root.monster_units,260)
	if target==null and not bool(unit.get_meta("objective_priority",false)):
		target = TargetingService.nearest(unit,root.monster_units,maxf(80,unit.attack_range))
	if target!=null:
		if _hold_attack_position(unit,target): return
		_move_to_attack_target(unit,target,true); return
	if _run_enemy_behavior(unit): return
	if _hero_skills_enabled() and _is_hero_unit(unit) and _run_hero_skill(unit): return
	if unit.position.distance_to(map.center(unit.goal_room))<18:
		unit.stop_navigation(); return
	move_unit_to_room(unit,unit.goal_room)

func move_unit_to_room(unit: Node, room_id: String) -> void:
	var point: Vector2 = map.center(room_id)
	if unit.faction==Constants.FACTION_MONSTER:
		var target := local_target(unit)
		var guarded: Node = _most_wounded_ally(unit) if root._monster_ai_behavior(unit.unit_id)=="ally_guard" else null
		if guarded!=null and str(guarded.current_room)==room_id:
			point = guarded.position
		else: point = target.position if target!=null else home(unit)
	move_unit_to_point(unit,point,true)

func move_unit_to_point(unit: Node, point: Vector2, _preserve_goal: bool = false) -> void:
	var desired := map.clamp_to_walkable(point)
	var commanded: bool = root.combat_time<command_until and command in ["rally","emergency_retreat","lure_retreat"]
	if unit.faction==Constants.FACTION_MONSTER and unit!=direct_unit and not commanded and desired.distance_to(home(unit))>leash_radius(unit): desired = home(unit)
	# Keep a route until its destination cell changes; do not send actors backwards
	# to the cell centre on every AI tick.
	var destination: Vector2i = map.nearest_cell(desired)
	if unit.get_meta("road_destination",Vector2i(-999,-999))==destination and not unit.path_points.is_empty(): return
	unit.set_meta("road_destination",destination)
	unit.set_path(map.path_to_point(unit.position,desired))

func _move_to_attack_target(unit: Node, target: Node, _preserve_goal: bool = false) -> void:
	if unit.faction==Constants.FACTION_MONSTER and command=="focus_attack" and is_instance_valid(command_target) and command_target.is_alive() and command_target.position.distance_to(home(unit))<=leash_radius(unit): target = command_target
	move_unit_to_point(unit,target.position,true)
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET,"교전",target.display_name)

func _hold_attack_position(unit: Node, target: Node) -> bool:
	if not is_instance_valid(target) or not target.is_alive() or unit.position.distance_to(target.position)>unit.attack_range*.96: return false
	unit.stop_navigation(); unit.set_tactical_state(Constants.UNIT_STATE_ATTACK,"교전",target.display_name)
	if contacts.size()<60: contacts.append({"time":root.combat_time,"line":map.tags_for(unit).defense_line,"unit":unit.unit_id})
	return true

func try_attack(attacker: Node, opponents: Array) -> void:
	# Objective squads advance under fire; taunts still force an interception.
	if attacker.faction==Constants.FACTION_ENEMY and bool(attacker.get_meta("objective_priority",false)):
		if attacker.position.distance_to(map.center(attacker.goal_room))>=18 and attacker.forced_attack_target(root.monster_units,260)==null: return
	if attacker==direct_unit and not attacker.path_points.is_empty(): return
	if attacker.faction==Constants.FACTION_MONSTER and root.combat_time<command_until and command in ["rally","emergency_retreat","lure_retreat"] and not attacker.path_points.is_empty(): return
	super.try_attack(attacker,opponents)

func _combat_action_target(attacker: Node, opponents: Array, max_distance: float) -> Node:
	if attacker.faction==Constants.FACTION_MONSTER and command=="focus_attack" and is_instance_valid(command_target) and command_target in opponents and command_target.is_alive() and command_target.is_targetable_by(attacker):
		if attacker.position.distance_to(command_target.position)<=max_distance: return command_target
	return super._combat_action_target(attacker,opponents,max_distance)

func _path_from_world_to_room(from: Vector2, id: String, _unit: Node = null) -> Array: return map.path_to_point(from,map.center(id))
func _v122_uses_zone_facility_effects() -> bool: return false
func _treasure_room() -> String: return "vault"
func _core_room() -> String: return "throne"
func _unit_in_facility_room(unit: Node, facility_id: String) -> bool:
	for id in map.tags_for(unit).aura:
		if map.rooms[id].facility_role==facility_id and root.combat_time>=float(map.rooms[id].get("disabled_until",0)): return true
	return false

func _facility_attack_multiplier(attacker: Node, _target: Node) -> float:
	var base := BARRACKS_ATTACK_MULTIPLIER if attacker.faction==Constants.FACTION_MONSTER and _unit_in_facility_room(attacker,"barracks") else 1.0
	return base

func _apply_facility_damage_taken_modifier(_attacker: Node, target: Node, damage: int) -> int:
	var factor := spec_effects.damage_multiplier(_attacker,target)
	if target.faction==Constants.FACTION_MONSTER:
		if _unit_in_facility_room(target,"barracks"): factor *= BARRACKS_DAMAGE_TAKEN_MULTIPLIER
		if _unit_in_facility_room(target,"ward_core"):
			for stage in view.placement.stage_rules.values():
				if int(stage.index)==int(view.placement.stage): factor *= float(stage.get("ward_damage_taken_scale",1.0))
	return maxi(1,roundi(damage*factor))

func update_room_effects(delta: float) -> void:
	tick_temporary_traps(delta)
	for unit in root.monster_units:
		if not unit.is_alive(): continue
		unit.attack_range = float(unit.get_meta("base_attack_range",unit.attack_range))*(1.18 if _unit_in_facility_room(unit,"watch_post") else 1.0)
		if _unit_in_facility_room(unit,"recovery") and not bool(unit.get_meta("food_hungry",false)):
			var key: int = unit.get_instance_id(); var carry := float(recovery_heal_accumulator.get(key,0))+8.0*delta
			var amount := floori(carry); recovery_heal_accumulator[key] = carry-amount
			if amount>0: unit.heal(amount)
	for enemy in root.enemy_units:
		if not enemy.is_alive(): continue
		apply_cell_traps(enemy)
		var reached: bool = enemy.position.distance_to(map.center(enemy.goal_room))<18
		if not reached: continue
		if enemy.goal_room=="throne" and enemy.attack_cooldown<=0 and TargetingService.nearest(enemy,root.monster_units,enemy.attack_range)==null:
			var damage: int = maxi(8,enemy.effective_atk())
			if not root.monster_units.any(func(u): return u.is_alive()): damage *= 3
			GameState.damage_throne(damage); enemy.attack_cooldown = enemy.effective_attack_interval()
		elif enemy.unit_id=="thief": tick_theft(enemy,delta)
		elif str(enemy.get_meta("goal_type",""))=="facility" and enemy.attack_cooldown<=0:
			map.rooms[enemy.goal_room]["disabled_until"] = root.combat_time+ENGINEER_DISABLE_SECONDS
			enemy.attack_cooldown = enemy.effective_attack_interval()
			enemy.goal_room = "throne"
			move_unit_to_room(enemy,"throne")

func tick_theft(enemy: Node, delta: float) -> void:
	if enemy.goal_room=="entrance":
		enemy.down = true; enemy.hp = 0; enemy.escaped = true; enemy.hide(); root.thieves_escaped_this_battle += 1; return
	if enemy.goal_room not in ["vault"]:
		# Decoy delays a thief for the existing five-second theft window, then sends
		# it to the actual vault. False gold never changes the real balance.
		var wait: float = float(enemy.get_meta("decoy_wait",0))+delta
		enemy.set_meta("decoy_wait",wait)
		if wait>=5: enemy.goal_room = "vault"
		return
	if TargetingService.nearest(enemy,root.monster_units,enemy.attack_range)!=null: return
	if not root.thief_steal_timers.has(enemy): root.thieves_reached_treasure_this_battle += 1
	var time: float = float(root.thief_steal_timers.get(enemy,0))+delta*monster_skills.slow_theft(enemy)
	root.thief_steal_timers[enemy] = time
	if time>=5:
		var stolen: int = mini(100,GameState.gold); GameState.gold -= stolen
		enemy.set_meta("stolen_gold",int(enemy.get_meta("stolen_gold",0))+stolen)
		root.treasure_gold_stolen_this_battle += stolen; root.thieves_completed_theft_this_battle += 1
		root.thief_steal_timers[enemy] = -999.0; enemy.goal_room = "entrance"

func apply_cell_traps(enemy: Node) -> void:
	var c: Vector2i = map.cell(enemy.position); var kind: String = map.trap_cells.get(c,"")
	if kind=="": return
	var key := str(enemy.get_instance_id())+":"+str(c)
	if root.combat_time<float(trap_next_hits.get(key,0)): return
	trap_next_hits[key] = root.combat_time+2.0
	var damage := 0
	if kind=="spikes": damage = enemy.receive_damage(14)
	else: enemy.apply_slow(2.0*trap_duration_multiplier(c)+monster_skills.sticky_extra(c),.55)
	trap_events.append({"time":root.combat_time,"kind":kind,"cell":str(c),"damage":damage,"enemy":enemy.unit_id})
	# Existing GPT tile artwork flashes; no procedural geometry or new drawing.
	var flash: Sprite2D = view.cell_highlight(visuals,c,Color(1,.5,.15,.8) if kind=="spikes" else Color(.35,1,.6,.8))
	flash.z_index = 3500
	var tween := view.create_tween(); tween.tween_property(flash,"modulate:a",0,.55); tween.tween_callback(flash.queue_free)

func create_temporary_trap(c: Vector2i, kind: String, seconds: float, source_id: String = "") -> Dictionary:
	if not map.is_road(c) or kind not in ["spikes","sticky"] or seconds<=0: return {"ok":false}
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/maps/v130r_step1/traps/"+kind+".png")
	sprite.position = map.world(c); visuals.add_child(sprite); sprite.modulate = Color(.7,1,.8,.8)
	var trap := {"ok":true,"cell":c,"kind":kind,"remaining":seconds*trap_duration_multiplier(c)+monster_skills.sticky_extra(c),"source_id":source_id,"sprite":sprite}
	temporary_traps.append(trap); rebuild_trap_tags(); return trap.duplicate()

func add_trap_duration_modifier(cells: Array, multiplier: float, seconds: float, source_id: String) -> void:
	if multiplier>0 and seconds>0: duration_modifiers.append({"cells":cells.duplicate(),"multiplier":multiplier,"remaining":seconds,"source_id":source_id})

func trap_duration_multiplier(c: Vector2i) -> float:
	var multiplier := 1.0
	for modifier in duration_modifiers:
		if modifier.remaining>0 and c in modifier.cells: multiplier *= float(modifier.multiplier)
	return multiplier

func tick_temporary_traps(delta: float) -> void:
	var changed := false
	for i in range(temporary_traps.size()-1,-1,-1):
		temporary_traps[i].remaining -= delta
		if temporary_traps[i].remaining<=0:
			temporary_traps[i].sprite.queue_free(); temporary_traps.remove_at(i); changed = true
	for i in range(duration_modifiers.size()-1,-1,-1):
		duration_modifiers[i].remaining -= delta
		if duration_modifiers[i].remaining<=0: duration_modifiers.remove_at(i)
	if changed: rebuild_trap_tags()

func rebuild_trap_tags() -> void:
	map.trap_cells.clear()
	for t in map.layout.traps: map.trap_cells[Vector2i(t.cell[0],t.cell[1])] = t.kind
	for t in temporary_traps: map.trap_cells[t.cell] = t.kind

func request_unit_skill(unit: Node, slot: int, notify_ai: bool = false) -> bool:
	if not is_instance_valid(unit) or not running or root.combat_paused: return false
	var slots: Array = skill_slots_for(unit)
	if slot>=0 and slot<slots.size() and monster_skills.definitions.has(str(slots[slot])):
		return monster_skills.cast(unit,str(slots[slot]),notify_ai)
	var previous = root.selected_unit; root.selected_unit = unit
	var intent := _prepare_selected_skill(slot,notify_ai); root.selected_unit = previous
	if intent.is_empty(): return false
	intent["notify_ai"] = notify_ai
	var ok := _commit_and_notify_skill(intent)
	if ok: skill_events.append({"time":root.combat_time,"unit":unit.unit_id,"skill":intent.skill_id,"automatic":notify_ai})
	return ok

func _flame_zone_targets() -> Array:
	return root.enemy_units.filter(func(u): return u.is_alive() and map.tags_for(u).defense_line=="1")

func set_speed(speed: float) -> void:
	root.combat_speed = clampf(speed,1,3); root.combat_paused = false
	for unit in root.monster_units+root.enemy_units: unit.set_simulation_speed(root.combat_speed); unit.set_physics_process(running)

func set_pause_state(paused: bool, _emit_log: bool = true) -> void:
	root.combat_paused = paused
	for tween in active_combat_tweens:
		if tween!=null and tween.is_valid():
			if paused: tween.pause()
			else: tween.play()
	for unit in root.monster_units+root.enemy_units:
		unit.set_physics_process(not paused and running)
		if unit.sprite!=null: unit.sprite.speed_scale = 0 if paused else root.combat_speed

func spawn_projectile(from_position: Vector2, to_position: Vector2, on_arrival: Callable = Callable(), impact_on_arrival: bool = true) -> void:
	var sprite = _make_effect_sprite("fireball",true,0)
	if sprite==null:
		if on_arrival.is_valid(): on_arrival.call()
		return
	root.effect_root.add_child(sprite); sprite.position = from_position
	_apply_vfx_profile(sprite,"fireball",Vector2.ONE,false)
	sprite.rotation = from_position.angle_to_point(to_position)
	var tween := _create_combat_tween()
	tween.tween_property(sprite,"position",to_position,_visual_seconds(PROJECTILE_TRAVEL_SECONDS))
	if on_arrival.is_valid(): tween.tween_callback(on_arrival)
	if impact_on_arrival: tween.tween_callback(spawn_impact.bind(to_position))
	tween.tween_callback(sprite.queue_free)

func nearest_visible_unit(point: Vector2) -> Node:
	var closest: Node
	var distance := INF
	for unit in root.monster_units+root.enemy_units:
		var d: float = unit.position.distance_squared_to(point)
		if unit.is_alive() and d<distance: distance = d; closest = unit
	return closest

func effect_body_ratio(point: Vector2) -> float:
	var closest := nearest_visible_unit(point)
	return closest.body_factor/closest.legacy_factor if closest!=null else 1.0

func _apply_vfx_profile(sprite: AnimatedSprite2D, effect_id: String, requested_scale: Vector2, _use_live_depth: bool = false) -> void:
	super._apply_vfx_profile(sprite,effect_id,requested_scale,false)
	if sprite==null: return
	var ratio: float = sprite.get_meta("map_body_ratio") if sprite.has_meta("map_body_ratio") else effect_body_ratio(sprite.position)
	sprite.scale *= ratio
	# Effects belong to this map's world, not the hidden legacy quarter renderer.
	sprite.z_index = 3600-root.effect_root.z_index

func spawn_slash(point: Vector2, delay: float = 0.0) -> void:
	if delay>0:
		_create_combat_tween().tween_interval(_visual_seconds(delay)).finished.connect(spawn_slash.bind(point))
		return
	spawn_contact_effect("slash",point,.10,1.25)

func spawn_impact(point: Vector2) -> void:
	spawn_contact_effect("impact",point,.16,1.333333)

func spawn_contact_effect(id: String, point: Vector2, seconds: float, growth: float) -> void:
	var sprite = _make_effect_sprite(id,false,0)
	if sprite==null: return
	sprite.set_meta("map_body_ratio",effect_body_ratio(point))
	sprite.position = point+Vector2(0,-presentation_height(point)/2)
	_apply_vfx_profile(sprite,id,Vector2(.72,.72),false)
	root.effect_root.add_child(sprite)
	var tween = _create_combat_tween().bind_node(sprite)
	tween.tween_property(sprite,"scale",sprite.scale*growth,_visual_seconds(seconds))
	tween.tween_callback(_finish_cosmetic_vfx.bind(sprite))

func presentation_height(point: Vector2) -> float:
	var closest := nearest_visible_unit(point)
	return closest.idle_bounds.size.y*closest.body_factor if closest!=null else Presentation.BODY_HEIGHT

func spawn_damage_number(point: Vector2, damage: int, faction: String, _anchor_target = null) -> void:
	if damage<=0 or not running: return
	var number := Label.new(); number.text = "−%d" % damage
	number.add_theme_font_override("font",preload("res://assets/fonts/NEXON_Maplestory_Bold.otf"))
	number.add_theme_font_size_override("font_size",22)
	var closest := nearest_visible_unit(point)
	number.scale = Vector2.ONE*Presentation.ui_scale(closest.unit_id if closest!=null else "")
	number.add_theme_color_override("font_color",Color("ff9c9c") if faction=="monster" else Color("ffe795"))
	number.position = point+Vector2(-12,-presentation_height(point)); number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.effect_root.add_child(number)
	var tween := _create_combat_tween()
	tween.tween_property(number,"position:y",number.position.y-30,.6)
	tween.parallel().tween_property(number,"modulate:a",0,.6)
	tween.tween_callback(number.queue_free)

func _spawn_contact_damage_number(target: Node, damage: int, _attacker, _attacker_id: String, _contact_kind: String) -> void:
	spawn_damage_number(target.position,damage,target.faction,target)

func issue_command(id: String, point: Vector2 = Vector2.INF, target: Node = null) -> bool:
	if id not in ["rally","focus_attack","emergency_retreat","hold_ground","lure_retreat"] or not running: return false
	command = id; command_target = target; command_until = root.combat_time+6.0
	command_point = map.clamp_to_walkable(point) if point!=Vector2.INF else map.center("recovery_nest" if map.layout.doors.has("recovery_nest") else "throne")
	root.global_directive = Constants.DIRECTIVE_DEFENSE
	if id=="emergency_retreat": root.global_directive = Constants.DIRECTIVE_SURVIVAL
	elif id=="focus_attack": root.global_directive = Constants.DIRECTIVE_ALL_OUT
	for unit in root.monster_units:
		if not unit.is_alive(): continue
		if id=="lure_retreat":
			for enemy in root.enemy_units:
				if enemy.is_alive() and enemy.position.distance_to(unit.position)<220: enemy.mark_threat(unit,4,true)
		if id=="hold_ground": return_home(unit)
	return true

func finish_combat(win: bool, reason: String) -> void:
	if not running: return
	running = false
	spec_effects.refund_tolls()
	last_result = {"win":win,"reason":reason,"duration":root.combat_time,"spawned":root.spawned_count,"trap_hits":trap_events.size(),"skills":skill_events.size(),"gold_stolen":root.treasure_gold_stolen_this_battle}
	# Restore the campaign graph before existing result/settlement services run.
	# All campaign save flags remain disabled by the isolated preview entry.
	root.graph = original_graph; root.rooms = original_rooms
	root.effect_root.reparent(effects_home,false); root.effect_root.position = Vector2.ZERO
	view.finish_pending = true
	call_deferred_result(win,reason)

func call_deferred_result(win: bool, reason: String) -> void:
	# View owns the deferred boundary so it is not freed in the physics callback.
	view.show_battle_result.bind(win,reason).call_deferred()

func settle_result(win: bool, reason: String) -> void:
	super.finish_combat(win,reason)

func try_auto_monster_skill(unit: Node) -> bool:
	if DataRegistry.monster(unit.unit_id).get("instance_id","").begins_with("mon_v130r_"):
		if root.combat_time<float(unit.get_meta("new_auto_next",0)): return false
		unit.set_meta("new_auto_next",root.combat_time+.35)
		for id in skill_slots_for(unit):
			if id=="toll_shakedown": continue
			if monster_skills.cast(unit,str(id),true): return true
		return false
	return super.try_auto_monster_skill(unit)

func _perform_standard_attack(attacker: Node, target: Node, fighting_retreat: bool = false, contact_callback: Callable = Callable()) -> Dictionary:
	var stealth_attack: bool = attacker.unit_id=="under_bed_shadow" and attacker.stealthed()
	if stealth_attack and monster_skills.cast(attacker,"peekaboo",true):
		attacker.attack_cooldown = attacker.effective_attack_interval()
		return {"applied":true}
	var result := super._perform_standard_attack(attacker,target,fighting_retreat,contact_callback)
	if result.get("applied",false): monster_skills.on_hit(attacker,target)
	return result

func on_unit_downed(unit: Node) -> void:
	monster_skills.on_downed(unit)
	super.on_unit_downed(unit)

func _specialization_after_skill(caster: Node, id: String, victim: Node) -> void:
	spec_effects.after_legacy_skill(caster,id,victim)

func _apply_v122_focus_damage(source: Node, target: Node, damage: int) -> int:
	return roundi(super._apply_v122_focus_damage(source,target,damage)*spec_effects.damage_multiplier(source,target))

func _most_wounded_ally(unit: Node) -> Node:
	if root._monster_ai_behavior(unit.unit_id)=="ally_guard": return spec_effects.guard_ally(unit)
	return super._most_wounded_ally(unit)
