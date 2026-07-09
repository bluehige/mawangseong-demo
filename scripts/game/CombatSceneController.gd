extends RefCounted
class_name CombatSceneController

const Constants = preload("res://scripts/core/Constants.gd")
const TargetingService = preload("res://scripts/combat/TargetingService.gd")
const DamageService = preload("res://scripts/combat/DamageService.gd")
const DirectiveManager = preload("res://scripts/combat/DirectiveManager.gd")

const BARRACKS_ATTACK_MULTIPLIER = 1.25
const BARRACKS_DAMAGE_TAKEN_MULTIPLIER = 0.82
const WATCH_POST_DAMAGE_MULTIPLIER = 1.18
const WATCH_POST_SLOW_SECONDS = 0.45
const WATCH_POST_SLOW_FACTOR = 0.72

var root: Node
var hud
var recovery_heal_accumulator: Dictionary = {}

func setup(game_root: Node, hud_controller) -> void:
	root = game_root
	hud = hud_controller

func physics_process(delta: float) -> void:
	if root.current_screen != Constants.SCREEN_COMBAT or root.combat_paused:
		return
	var sim_delta = delta * root.combat_speed
	root.combat_time += sim_delta
	root.trap_cooldown = max(0.0, root.trap_cooldown - sim_delta)
	spawn_ready_enemies(sim_delta)
	refresh_unit_rooms()
	update_ai_paths()
	update_room_effects(sim_delta)
	update_attacks(sim_delta)
	check_combat_end()

func build_combat_ui() -> void:
	hud.build_top_bar()
	hud.build_facility_effect_panel()
	hud.build_room_list(20, 105, 300, 385)
	hud.build_unit_status_panel()
	hud.build_log_panel()
	hud.build_selected_unit_panel()
	hud.build_command_panel()
	hud.build_speed_panel()

func start_combat() -> void:
	root._clear_units()
	clear_effects()
	clear_quarter_trap_animations()
	root._reset_combat_view()
	root.combat_time = 0.0
	root.combat_paused = false
	root.combat_speed = 1.0
	root.trap_cooldown = 0.0
	root.spawned_count = 0
	root.thief_steal_timers.clear()
	root.treasure_gold_stolen_this_battle = 0
	recovery_heal_accumulator.clear()
	if root.has_method("_reset_facility_effect_stats"):
		root._reset_facility_effect_stats()
	root.rewards_pending = {"gold": 0, "mana": 0, "food": 0, "infamy": 0}
	root.result_summary = {"win": false, "lines": []}
	if root.has_method("_capture_battle_growth_start"):
		root._capture_battle_growth_start()
	var defense_modifiers: Dictionary = {}
	if root.has_method("_active_defense_modifiers"):
		defense_modifiers = root._active_defense_modifiers()
	root.wave_manager.setup(GameState.day, DataRegistry.waves, defense_modifiers)
	if not defense_modifiers.is_empty():
		for modifier in defense_modifiers.values():
			root._log("원정 효과 적용: %s" % str(modifier.get("display_name", "다음 방어 변화")))
		if root.has_method("_consume_defense_modifiers"):
			root._consume_defense_modifiers()
	spawn_monsters()
	for unit in root.monster_units:
		unit.set_physics_process(true)
	root._log("DAY %d 침입이 시작되었습니다." % GameState.day)
	root._set_screen(Constants.SCREEN_COMBAT)

func spawn_monsters() -> void:
	var spawn_counts: Dictionary = {}
	for monster_id in root.monster_roster.keys():
		if root.has_method("_monster_available_for_defense") and not root._monster_available_for_defense(str(monster_id)):
			continue
		var roster: Dictionary = root.monster_roster[monster_id]
		var room_id: String = roster.get("room", DataRegistry.monster(monster_id).get("recommended_room", "entrance"))
		var stats = root._scaled_monster_stats(monster_id)
		var unit = root._create_unit(monster_id, stats, Constants.FACTION_MONSTER, room_id)
		var count = int(spawn_counts.get(room_id, 0))
		unit.global_position = root._clamp_to_combat_walkable(root._room_actor_point(room_id, count, true))
		spawn_counts[room_id] = count + 1
		root.monster_units.append(unit)
		if root.selected_unit == null:
			root._select_unit(unit)

func spawn_ready_enemies(delta: float) -> void:
	for entry in root.wave_manager.tick(delta):
		spawn_enemy(entry.get("enemy_id", "explorer"), entry)

func spawn_enemy(enemy_id: String, wave_entry: Dictionary = {}) -> void:
	var stats = _scaled_enemy_stats(enemy_id, wave_entry)
	var unit = root._create_unit(enemy_id, stats, Constants.FACTION_ENEMY, "entrance")
	unit.global_position = root._clamp_to_combat_walkable(root._room_actor_point("entrance", root.spawned_count + 3, true))
	var treasure_room = _treasure_room()
	unit.goal_room = treasure_room if stats.get("goal_type", "") == "treasure" and treasure_room != "" else _core_room()
	unit.set_path(_path_from_world_to_room(unit.global_position, unit.goal_room))
	root.enemy_units.append(unit)
	root.spawned_count += 1
	if root.has_method("_onboarding_enemy_spawned"):
		root._onboarding_enemy_spawned(enemy_id)
	root._log("%s가 입구에 도착했습니다." % unit.display_name)

func clear_effects() -> void:
	for child in root.effect_root.get_children():
		child.queue_free()

func clear_quarter_trap_animations() -> void:
	if root.quarter_renderer != null and root.quarter_renderer.has_method("clear_trap_animations"):
		root.quarter_renderer.clear_trap_animations()

func trigger_quarter_trap(instance_id: String, trap_id: String) -> void:
	if root.quarter_renderer != null and root.quarter_renderer.has_method("trigger_trap_animation"):
		root.quarter_renderer.trigger_trap_animation(instance_id, trap_id)

func refresh_unit_rooms() -> void:
	for unit in root.monster_units + root.enemy_units:
		if unit.is_alive():
			unit.current_room = root.graph.closest_room(unit.global_position)

func update_ai_paths() -> void:
	for unit in root.monster_units:
		if not unit.is_alive() or unit.direct_control:
			continue
		update_monster_path(unit)
	for unit in root.enemy_units:
		if not unit.is_alive():
			continue
		update_enemy_path(unit)

func update_monster_path(unit: Node) -> void:
	if float(unit.hp) / float(unit.max_hp) <= 0.35 and root.global_directive == Constants.DIRECTIVE_SURVIVAL:
		_retreat_unit(unit, "생존 우선")
		return
	if root.room_directives.get(unit.current_room, Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_RETREAT:
		_retreat_unit(unit, "후퇴선 유지")
		return

	var priority_target = TargetingService.monster_priority(unit, root.enemy_units, root.graph, _core_room(), _treasure_room())
	if priority_target != null and _hold_attack_position(unit, priority_target):
		return
	if _entry_block_active() and unit.unit_id == "slime":
		var block_point = root.graph.center("entrance").lerp(root.graph.center("spike_corridor"), 0.55)
		move_unit_to_point(unit, block_point)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "입구 봉쇄", "초크포인트")
		return

	if root.room_directives.get("spike_corridor", Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_TRAP_LURE:
		if priority_target != null and priority_target.current_room == unit.current_room:
			move_unit_to_point(unit, priority_target.global_position)
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "함정 유도 교전", priority_target.display_name)
			return
		if unit.unit_id == "imp":
			var rear_point = root.graph.center("spike_corridor").lerp(root.graph.center(_barracks_room()), 0.58)
			move_unit_to_point(unit, rear_point)
			unit.set_tactical_state(Constants.UNIT_STATE_SEEK_TARGET, "함정 뒤 화력 지원", "가시 복도")
			return
		if priority_target != null and priority_target.current_room in ["entrance", "spike_corridor", _barracks_room()]:
			move_unit_to_point(unit, _trap_lure_point(unit))
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "함정 유도", "가시 복도")
			return
	if root.global_directive == Constants.DIRECTIVE_ALL_OUT:
		var target = priority_target
		if target != null:
			if target.current_room == unit.current_room:
				move_unit_to_point(unit, target.global_position)
			else:
				move_unit_to_room(unit, target.current_room)
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "총공격", target.display_name)
			return
	var nearby = _defense_target(unit, priority_target)
	if nearby != null:
		if nearby.current_room == unit.current_room:
			move_unit_to_point(unit, nearby.global_position)
		else:
			move_unit_to_room(unit, nearby.current_room)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "방어 교전", nearby.display_name)
	elif unit.current_room != unit.assigned_room:
		move_unit_to_room(unit, unit.assigned_room)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "배치 방 복귀", _room_name(unit.assigned_room))
	else:
		unit.set_tactical_state(Constants.UNIT_STATE_IDLE, "배치 방 사수", _room_name(unit.assigned_room))

func update_enemy_path(unit: Node) -> void:
	var treasure_room = _treasure_room()
	var core_room = _core_room()
	if unit.unit_id == "trainee_hero" and _run_hero_skill(unit):
		return
	if unit.unit_id == "thief" and treasure_room != "" and unit.current_room == treasure_room:
		unit.set_tactical_state(Constants.UNIT_STATE_LOOTING, "보물 약탈", "금화")
		return
	if unit.unit_id == "thief" and treasure_room != "" and unit.threat_unit != null and unit.current_room != treasure_room:
		move_unit_to_room(unit, treasure_room)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "피격 후 침투", _room_name(treasure_room))
		return
	var monster_target = nearest_monster_in_rooms(unit, [unit.current_room])
	if monster_target != null:
		if _hold_attack_position(unit, monster_target):
			return
		move_unit_to_point(unit, monster_target.global_position, true)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "교전", monster_target.display_name)
		return
	if unit.current_room == unit.goal_room:
		if unit.goal_room == core_room:
			unit.set_tactical_state(Constants.UNIT_STATE_ATTACK, "왕좌 압박", _room_name(core_room))
		return
	move_unit_to_room(unit, unit.goal_room)
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "목표 방 이동", _room_name(unit.goal_room))

func nearest_enemy_in_rooms(unit: Node, room_ids: Array) -> Node:
	var candidates: Array = []
	for enemy in root.enemy_units:
		if enemy.is_alive() and room_ids.has(enemy.current_room):
			candidates.append(enemy)
	return TargetingService.nearest(unit, candidates)

func nearest_monster_in_rooms(unit: Node, room_ids: Array) -> Node:
	var candidates: Array = []
	for monster in root.monster_units:
		if monster.is_alive() and room_ids.has(monster.current_room):
			candidates.append(monster)
	return TargetingService.nearest(unit, candidates)

func _defense_target(unit: Node, priority_target: Node) -> Node:
	if priority_target == null:
		return null
	var anchor_room = str(unit.assigned_room)
	if anchor_room == "" or not root.rooms.has(anchor_room):
		anchor_room = str(unit.current_room)
	var allowed_rooms = [anchor_room, unit.current_room]
	for room_id in root.graph.exits(anchor_room):
		if not allowed_rooms.has(room_id):
			allowed_rooms.append(room_id)
	if root.global_directive == Constants.DIRECTIVE_DEFENSE and not allowed_rooms.has(priority_target.current_room):
		return null
	return priority_target

func _entry_block_active() -> bool:
	return root.room_directives.get("entrance", Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_ENTRY_BLOCK or root.room_directives.get("spike_corridor", Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_ENTRY_BLOCK

func _trap_lure_point(unit: Node) -> Vector2:
	var base = root.graph.center("spike_corridor")
	if unit.unit_id == "slime":
		return root._clamp_to_combat_walkable(base + Vector2(-32, 34))
	if unit.unit_id == "goblin":
		return root._clamp_to_combat_walkable(base + Vector2(42, 26))
	return root._clamp_to_combat_walkable(base)

func _retreat_unit(unit: Node, reason: String) -> void:
	var retreat_room = _retreat_room(unit)
	move_unit_to_room(unit, retreat_room)
	unit.set_tactical_state(Constants.UNIT_STATE_RETREAT, reason, _room_name(retreat_room))
	if root.has_method("_onboarding_unit_retreat"):
		root._onboarding_unit_retreat(unit)

func _run_hero_skill(unit: Node) -> bool:
	if not unit.skill_ready("hero_dash"):
		return false
	var target = TargetingService.nearest(unit, root.monster_units, 170.0)
	if target == null:
		return false
	var direction = (target.global_position - unit.global_position).normalized()
	if direction == Vector2.ZERO:
		return false
	var dash_end = root._clamp_to_combat_walkable(unit.global_position + direction * 120.0)
	unit.set_path([dash_end])
	unit.set_skill_cooldown("hero_dash", 7.0)
	unit.play_skill()
	unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "용사의 돌진", target.display_name)
	for monster in root.monster_units:
		if monster.is_alive() and monster.global_position.distance_to(dash_end) <= 72.0:
			monster.receive_damage(20)
			monster.mark_threat(unit)
			spawn_impact(monster.global_position)
	root._log("%s가 용사의 돌진을 사용했습니다." % unit.display_name)
	return true

func _has_loot_bonus() -> bool:
	for unit in root.monster_units:
		if unit.is_alive() and unit.unit_id == "goblin":
			return true
		if unit.loot_bonus_active:
			return true
	return false

func _room_name(room_id: String) -> String:
	return root.rooms.get(room_id, {}).get("display_name", room_id)

func _core_room() -> String:
	return root._room_by_type("core", "throne")

func _treasure_room() -> String:
	return root._room_by_facility("treasure", "")

func _barracks_room() -> String:
	return root._room_by_facility("barracks", "barracks")

func _retreat_room(unit: Node) -> String:
	var fallback = str(unit.assigned_room)
	if fallback == "" or not root.rooms.has(fallback) or root.rooms[fallback].get("type", "") == "build_slot":
		fallback = "recovery"
	return root._room_by_facility("recovery", fallback)

func move_unit_to_room(unit: Node, room_id: String) -> void:
	if room_id == "" or not root.rooms.has(room_id):
		return
	if unit.goal_room == room_id and not unit.path_points.is_empty():
		return
	unit.goal_room = room_id
	unit.set_path(_path_from_world_to_room(unit.global_position, room_id))
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "방 이동", _room_name(room_id))

func move_unit_to_point(unit: Node, point: Vector2, preserve_goal: bool = false) -> void:
	point = root._clamp_to_combat_walkable(point)
	if unit.global_position.distance_to(point) <= 16.0:
		if unit.has_method("stop_navigation"):
			unit.stop_navigation()
		return
	if not preserve_goal:
		unit.goal_room = unit.current_room
	var route: Array = []
	if _point_room(point) == unit.current_room:
		route = [point]
	elif root.graph != null and root.graph.has_method("path_to_point"):
		route = root.graph.path_to_point(unit.global_position, point)
	if route.is_empty():
		route = [point]
	unit.set_path(route)
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "위치 이동")

func _hold_attack_position(unit: Node, target: Node) -> bool:
	if target == null or not is_instance_valid(target) or not target.is_alive():
		return false
	if target.current_room != unit.current_room:
		return false
	var hold_range = max(18.0, float(unit.attack_range) * 0.92)
	if unit.global_position.distance_to(target.global_position) > hold_range:
		return false
	if unit.has_method("stop_navigation"):
		unit.stop_navigation()
	unit.set_tactical_state(Constants.UNIT_STATE_ATTACK, "교전 유지", target.display_name)
	return true

func update_room_effects(delta: float) -> void:
	var recovery_room = root._room_by_facility("recovery", "")
	var core_room = _core_room()
	var treasure_room = _treasure_room()
	var watch_rooms = _watch_post_pressure_rooms()
	for unit in root.monster_units:
		if unit.is_alive() and recovery_room != "" and unit.current_room == recovery_room:
			var key = unit.get_instance_id()
			var carry = float(recovery_heal_accumulator.get(key, 0.0)) + 8.0 * delta
			var heal_amount = int(floor(carry))
			recovery_heal_accumulator[key] = carry - float(heal_amount)
			if heal_amount > 0:
				var before_hp = unit.hp
				unit.heal(heal_amount)
				var healed = max(0, unit.hp - before_hp)
				if healed > 0 and root.has_method("_record_facility_effect_stat"):
					root._record_facility_effect_stat("recovery_healing", healed)
			unit.set_tactical_state(Constants.UNIT_STATE_RETREAT, "회복 중", _room_name(recovery_room))
	for enemy in root.enemy_units:
		if enemy.is_alive() and watch_rooms.has(enemy.current_room):
			if enemy.slow_timer <= 0.05 and root.has_method("_record_facility_effect_stat"):
				root._record_facility_effect_stat("watch_post_slow_applications", 1)
			enemy.apply_slow(WATCH_POST_SLOW_SECONDS, WATCH_POST_SLOW_FACTOR)
	if root.trap_cooldown <= 0.0:
		for enemy in root.enemy_units:
			if enemy.is_alive() and enemy.current_room == "spike_corridor":
				var trap_damage = 14
				var slow_seconds = 2.0
				var slow_factor = 0.8
				if root.room_directives.get("spike_corridor", Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_TRAP_LURE:
					trap_damage = 30
					slow_seconds = 3.5
					slow_factor = 0.55
				enemy.receive_damage(trap_damage)
				enemy.apply_slow(slow_seconds, slow_factor)
				root.trap_cooldown = 2.0
				trigger_quarter_trap("spike_corridor", "spike_floor")
				if root.has_method("_onboarding_trap_triggered"):
					root._onboarding_trap_triggered()
				root._log("가시 복도가 %s에게 피해를 주었습니다." % enemy.display_name)
				spawn_impact(enemy.global_position)
				break
	for enemy in root.enemy_units:
		if enemy.is_alive() and enemy.current_room == core_room:
			enemy.set_tactical_state(Constants.UNIT_STATE_ATTACK, "왕좌 압박", _room_name(core_room))
			if enemy.attack_cooldown <= 0.0 and TargetingService.nearest(enemy, root.monster_units, enemy.attack_range) == null:
				GameState.damage_throne(max(8, enemy.atk))
				enemy.attack_cooldown = enemy.attack_interval
				root._log("%s가 왕좌의 방을 공격했습니다." % enemy.display_name)
		if enemy.is_alive() and enemy.unit_id == "thief" and treasure_room != "" and enemy.current_room == treasure_room:
			enemy.set_tactical_state(Constants.UNIT_STATE_LOOTING, "보물 약탈", "금화")
			var timer = float(root.thief_steal_timers.get(enemy, 0.0)) + delta
			root.thief_steal_timers[enemy] = timer
			if timer >= 5.0:
				var stolen_gold = min(100, GameState.gold)
				GameState.gold = max(0, GameState.gold - stolen_gold)
				SignalBus.resources_changed.emit()
				root.thief_steal_timers[enemy] = -999.0
				root.treasure_gold_stolen_this_battle += stolen_gold
				enemy.goal_room = "entrance"
				enemy.set_path(_path_from_world_to_room(enemy.global_position, "entrance"))
				if root.has_method("_onboarding_treasure_stolen"):
					root._onboarding_treasure_stolen()
				root._log("도둑이 보물을 훔쳤습니다. 금화 -%d." % stolen_gold)
		if enemy.is_alive() and enemy.unit_id == "thief" and float(root.thief_steal_timers.get(enemy, 0.0)) < -100.0 and enemy.current_room == "entrance":
			enemy.hp = 0
			enemy.down = true
			enemy.visible = false
			root._log("도둑이 입구로 도주했습니다.")

func update_attacks(_delta: float) -> void:
	for unit in root.monster_units:
		if unit.is_alive():
			try_attack(unit, root.enemy_units)
	for unit in root.enemy_units:
		if unit.is_alive():
			try_attack(unit, root.monster_units)

func _path_from_world_to_room(from_world: Vector2, room_id: String) -> Array:
	var target = root._clamp_to_combat_walkable(root.graph.center(room_id))
	if root.graph != null and root.graph.has_method("path_to_point"):
		return root.graph.path_to_point(from_world, target)
	return [target]

func _point_room(point: Vector2) -> String:
	if root.graph == null:
		return ""
	if root.graph.has_method("room_at_world"):
		return root.graph.room_at_world(point)
	if root.graph.has_method("closest_room"):
		return root.graph.closest_room(point)
	return ""

func _scaled_enemy_stats(enemy_id: String, wave_entry: Dictionary = {}) -> Dictionary:
	var stats = DataRegistry.enemy(enemy_id).duplicate(true)
	if stats.is_empty():
		return stats
	stats["max_hp"] = _scale_int_stat(stats, wave_entry, "max_hp", "hp_scale", 1.0)
	stats["atk"] = _scale_int_stat(stats, wave_entry, "atk", "atk_scale", 1.0)
	stats["def"] = _scale_int_stat(stats, wave_entry, "def", "def_scale", 0.0)
	stats["exp"] = _scale_int_stat(stats, wave_entry, "exp", "reward_scale", 0.0)
	stats["infamy"] = _scale_int_stat(stats, wave_entry, "infamy", "reward_scale", 0.0)
	return stats

func _scale_int_stat(stats: Dictionary, wave_entry: Dictionary, stat_key: String, scale_key: String, minimum: float) -> int:
	var base_value = float(stats.get(stat_key, 0))
	var flat_bonus = float(wave_entry.get("%s_bonus" % stat_key, 0.0))
	var scale = float(wave_entry.get(scale_key, 1.0))
	var scaled_value = max(minimum, base_value * scale + flat_bonus)
	return int(round(scaled_value))

func try_attack(attacker: Node, opponents: Array) -> void:
	if attacker.attack_cooldown > 0.0:
		return
	if attacker.tactical_state == Constants.UNIT_STATE_RETREAT or attacker.tactical_state == Constants.UNIT_STATE_STUNNED:
		return
	var target = _direct_control_attack_target(attacker, opponents)
	if target == null:
		target = TargetingService.nearest(attacker, opponents, attacker.attack_range)
	if target == null:
		return
	if attacker.has_method("stop_navigation"):
		attacker.stop_navigation()
	var base_damage = DamageService.compute(attacker, target, 1.0)
	var damage = DamageService.compute(attacker, target, _facility_attack_multiplier(attacker, target))
	_record_facility_attack_bonus(attacker, target, base_damage, damage)
	var damage_before_facility_reduction = damage
	damage = _apply_facility_damage_taken_modifier(attacker, target, damage)
	if damage < damage_before_facility_reduction and root.has_method("_record_facility_effect_stat"):
		root._record_facility_effect_stat("barracks_damage_reduced", damage_before_facility_reduction - damage)
	var dealt_damage = target.receive_damage(damage)
	if root.has_method("_onboarding_unit_damaged"):
		root._onboarding_unit_damaged(target)
	if attacker.faction == Constants.FACTION_MONSTER and attacker.unit_id == "goblin" and root.has_method("_tutorial_emit_action"):
		root._tutorial_emit_action("goblin_attacks_once", {"unit_id": attacker.unit_id, "target_id": target.unit_id})
	if target.has_method("mark_threat"):
		target.mark_threat(attacker)
	attacker.attack_cooldown = attacker.attack_interval
	attacker.set_tactical_state(Constants.UNIT_STATE_ATTACK, "기본 공격", target.display_name)
	if attacker.has_method("play_attack"):
		attacker.play_attack()
	if attacker.faction == Constants.FACTION_MONSTER and attacker.unit_id == "imp":
		spawn_projectile(attacker.global_position, target.global_position)
	else:
		spawn_slash(target.global_position)
	root._log("%s가 %s에게 %d 피해." % [attacker.display_name, target.display_name, dealt_damage])

func _record_facility_attack_bonus(attacker: Node, target: Node, base_damage: int, boosted_damage: int) -> void:
	if attacker.faction != Constants.FACTION_MONSTER or not root.has_method("_record_facility_effect_stat"):
		return
	if boosted_damage <= base_damage:
		return
	if _unit_in_facility_room(attacker, "barracks"):
		var barracks_only = DamageService.compute(attacker, target, BARRACKS_ATTACK_MULTIPLIER)
		root._record_facility_effect_stat("barracks_bonus_damage", max(0, barracks_only - base_damage))
	if target.faction == Constants.FACTION_ENEMY and _watch_post_pressure_rooms().has(target.current_room):
		var watch_only = DamageService.compute(attacker, target, WATCH_POST_DAMAGE_MULTIPLIER)
		root._record_facility_effect_stat("watch_post_bonus_damage", max(0, watch_only - base_damage))

func _facility_attack_multiplier(attacker: Node, target: Node) -> float:
	if attacker.faction != Constants.FACTION_MONSTER:
		return 1.0
	var multiplier := 1.0
	if _unit_in_facility_room(attacker, "barracks"):
		multiplier *= BARRACKS_ATTACK_MULTIPLIER
	if target.faction == Constants.FACTION_ENEMY and _watch_post_pressure_rooms().has(target.current_room):
		multiplier *= WATCH_POST_DAMAGE_MULTIPLIER
	return multiplier

func _apply_facility_damage_taken_modifier(attacker: Node, target: Node, damage: int) -> int:
	var result := damage
	if target.faction == Constants.FACTION_MONSTER and _unit_in_facility_room(target, "barracks"):
		result = int(round(float(result) * BARRACKS_DAMAGE_TAKEN_MULTIPLIER))
	return max(1, result)

func _unit_in_facility_room(unit: Node, facility_id: String) -> bool:
	var facility_room = root._room_by_facility(facility_id, "")
	return facility_room != "" and unit.current_room == facility_room

func _watch_post_pressure_rooms() -> Array:
	var watch_room = root._room_by_facility("watch_post", "")
	if watch_room == "":
		return []
	var result: Array = [watch_room]
	if root.graph != null and root.graph.has_method("exits"):
		for room_id in root.graph.exits(watch_room):
			if not result.has(room_id):
				result.append(room_id)
	return result

func _direct_control_attack_target(attacker: Node, opponents: Array) -> Node:
	if not attacker.direct_control or attacker.command_target == null:
		return null
	var manual_target = attacker.command_target
	if not is_instance_valid(manual_target) or not manual_target.is_alive():
		attacker.command_target = null
		return null
	if not opponents.has(manual_target):
		return null
	if attacker.global_position.distance_to(manual_target.global_position) > attacker.attack_range:
		return null
	return manual_target

func on_unit_downed(unit: Node) -> void:
	if unit.faction == Constants.FACTION_ENEMY:
		root.rewards_pending["gold"] = int(root.rewards_pending.get("gold", 0)) + 60
		root.rewards_pending["mana"] = int(root.rewards_pending.get("mana", 0)) + 20
		root.rewards_pending["infamy"] = int(root.rewards_pending.get("infamy", 0)) + unit.infamy_reward
		for monster_id in root.monster_roster.keys():
			if root.has_method("_monster_available_for_defense") and not root._monster_available_for_defense(str(monster_id)):
				continue
			root.monster_roster[monster_id]["exp"] = int(root.monster_roster[monster_id]["exp"]) + max(5, int(unit.exp_reward / 3))
		root._log("%s 격퇴. 악명 +%d." % [unit.display_name, unit.infamy_reward])
	else:
		root._log("%s가 전투 불능이 되었습니다." % unit.display_name)

func check_combat_end() -> void:
	if GameState.defeat:
		finish_combat(false, "마왕성 체력이 0이 되었습니다.")
		return
	var alive_enemies = 0
	for enemy in root.enemy_units:
		if enemy.is_alive():
			alive_enemies += 1
	if root.wave_manager.is_done() and alive_enemies == 0:
		var win_text = "DAY %d 방어 성공." % GameState.day
		if GameState.day == GameState.max_day:
			GameState.victory = true
			win_text = "3일차 수련생 용사를 격퇴했습니다."
		finish_combat(true, win_text)

func finish_combat(win: bool, reason: String) -> void:
	if root.current_screen == Constants.SCREEN_RESULT:
		return
	for unit in root.monster_units + root.enemy_units:
		if is_instance_valid(unit):
			unit.set_physics_process(false)
	if win and _has_loot_bonus():
		var bonus_gold = int(round(float(root.rewards_pending.get("gold", 0)) * 0.1))
		if bonus_gold > 0:
			root.rewards_pending["gold"] = int(root.rewards_pending.get("gold", 0)) + bonus_gold
			root._log("고블린 약탈 본능 보너스 금화 +%d." % bonus_gold)
	var growth_summary := []
	if root.has_method("_finalize_battle_growth"):
		growth_summary = root._finalize_battle_growth()
	GameState.add_rewards(root.rewards_pending)
	var lines: Array[String] = []
	lines.append(reason)
	lines.append("격퇴한 적: %d / 스폰: %d" % [count_downed_enemies(), root.spawned_count])
	lines.append("획득 금화: %d" % int(root.rewards_pending.get("gold", 0)))
	lines.append("획득 마력: %d" % int(root.rewards_pending.get("mana", 0)))
	lines.append("증가 악명: %d" % int(root.rewards_pending.get("infamy", 0)))
	if int(root.treasure_gold_stolen_this_battle) > 0:
		lines.append("보물 손실: 금화 %d" % int(root.treasure_gold_stolen_this_battle))
	elif GameState.day >= 6:
		lines.append("보물 손실: 없음")
	lines.append("마왕성 체력: %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp])
	if root.has_method("_facility_effect_result_lines"):
		lines.append_array(root._facility_effect_result_lines())
	if root.has_method("_campaign_result_lines"):
		lines.append_array(root._campaign_result_lines(win))
	if root.has_method("_apply_campaign_result_flags"):
		root._apply_campaign_result_flags(win)
	root.result_summary = {"win": win, "lines": lines, "growth": growth_summary}
	SignalBus.battle_finished.emit(root.result_summary)
	root._set_screen(Constants.SCREEN_RESULT)
	if root.has_method("_onboarding_battle_finished"):
		root._onboarding_battle_finished(win)

func count_downed_enemies() -> int:
	var count = 0
	for enemy in root.enemy_units:
		if not enemy.is_alive():
			count += 1
	return count

func set_global_directive(directive: String) -> void:
	root.global_directive = directive
	root._log("전체 지침: %s." % DirectiveManager.directive_label(directive))
	if root.current_screen == Constants.SCREEN_COMBAT:
		root._set_screen(Constants.SCREEN_COMBAT)

func set_room_directive(directive: String) -> void:
	root.room_directives[root.selected_room] = directive
	root._log("%s 지침: %s." % [root.rooms[root.selected_room].get("display_name", root.selected_room), DirectiveManager.directive_label(directive)])
	root._set_screen(root.current_screen)

func enable_direct_control() -> void:
	if root.selected_unit == null or root.selected_unit.faction != Constants.FACTION_MONSTER:
		root._log("직접 조종할 몬스터를 선택하세요.")
		return
	root.selected_unit.begin_direct_control()
	root._log("%s 직접 조종 시작. 우클릭 이동, 적 우클릭 공격 지정." % root.selected_unit.display_name)

func release_direct_control() -> void:
	if root.selected_unit == null:
		return
	root.selected_unit.release_direct_control()
	root._log("%s AI 복귀." % root.selected_unit.display_name)

func use_selected_skill(slot: int) -> void:
	if root.selected_unit == null or root.selected_unit.faction != Constants.FACTION_MONSTER:
		return
	var monster_data = DataRegistry.monster(root.selected_unit.unit_id)
	var skills: Array = monster_data.get("skill_slots", [])
	if slot < 0 or slot >= skills.size() or skills[slot] == null:
		root._log("사용 가능한 스킬이 없습니다.")
		return
	var skill_id = str(skills[slot])
	if not root.selected_unit.skill_ready(skill_id):
		root._log("스킬 재사용 대기 중입니다.")
		return
	var skill = DataRegistry.skill(skill_id)
	var cost = int(skill.get("cost_mana", 0))
	if GameState.mana < cost:
		root._log("마력이 부족합니다.")
		return
	GameState.mana -= cost
	SignalBus.resources_changed.emit()
	match skill_id:
		"slime_shield":
			var shield_duration = 5.0 + _promotion_skill_float(root.selected_unit.unit_id, skill_id, "duration_bonus", 0.0)
			var shield_reduction = 0.4 + _promotion_skill_float(root.selected_unit.unit_id, skill_id, "reduction_bonus", 0.0)
			root.selected_unit.activate_shield(shield_duration, shield_reduction)
			root.selected_unit.play_skill()
			spawn_effect_burst("shield", root.selected_unit.global_position, Vector2(0, -20), Vector2(1.18, 1.0), 12.0)
			root._log("슬라임이 점액 방패를 펼쳤습니다.")
		"hold_corridor":
			root.selected_unit.activate_guard(6.0, 3)
			root.selected_unit.play_skill()
			spawn_effect_burst("guard", root.selected_unit.global_position, Vector2(0, -18), Vector2(1.16, 1.0), 12.0)
			root._log("슬라임이 통로를 틀어막았습니다. 방어력 +3.")
		"quick_slash":
			var slash_target = TargetingService.nearest(root.selected_unit, root.enemy_units, root.selected_unit.attack_range + 38.0)
			if slash_target != null:
				var slash_multiplier = 1.9 + _promotion_skill_float(root.selected_unit.unit_id, skill_id, "damage_multiplier_bonus", 0.0)
				var damage = DamageService.compute(root.selected_unit, slash_target, slash_multiplier)
				slash_target.receive_damage(damage)
				slash_target.mark_threat(root.selected_unit)
				root.selected_unit.play_attack()
				root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "날붙이 베기", slash_target.display_name)
				spawn_slash(slash_target.global_position)
				root._log("고블린이 날붙이 베기로 %d 피해." % damage)
		"loot_instinct":
			root.selected_unit.loot_bonus_active = true
			root.selected_unit.play_skill()
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "약탈 본능", "승리 보상")
			spawn_effect_burst("loot", root.selected_unit.global_position, Vector2(0, -22), Vector2(1.05, 0.95), 13.0)
			root._log("고블린의 약탈 본능이 보상 금화를 올립니다.")
		"fireball":
			var fire_range = 320.0 + _promotion_skill_float(root.selected_unit.unit_id, skill_id, "range_bonus", 0.0)
			var fire_target = TargetingService.nearest(root.selected_unit, root.enemy_units, fire_range)
			if fire_target != null:
				var fire_damage = 52 + int(_promotion_skill_float(root.selected_unit.unit_id, skill_id, "damage_bonus", 0.0))
				fire_target.receive_damage(fire_damage)
				fire_target.mark_threat(root.selected_unit)
				root.selected_unit.play_attack()
				root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "화염구", fire_target.display_name)
				spawn_projectile(root.selected_unit.global_position, fire_target.global_position)
				root._log("임프가 화염구를 발사했습니다. 피해 %d." % fire_damage)
		"flame_zone":
			var affected = 0
			var barracks_room = _barracks_room()
			for enemy in root.enemy_units:
				if enemy.is_alive() and ["spike_corridor", barracks_room].has(enemy.current_room):
					enemy.receive_damage(34)
					enemy.mark_threat(root.selected_unit)
					enemy.apply_slow(2.5, 0.7)
					spawn_impact(enemy.global_position)
					affected += 1
			root.selected_unit.play_skill()
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "화염 지대", "가시 복도")
			root._log("화염 지대가 %d명에게 피해를 줬습니다." % affected)
		"false_footprints":
			var affected = 0
			for enemy in root.enemy_units:
				if enemy.is_alive() and root.selected_unit.global_position.distance_to(enemy.global_position) <= 260.0:
					enemy.apply_slow(3.0, 0.62)
					enemy.mark_threat(root.selected_unit)
					spawn_effect_burst("guard", enemy.global_position, Vector2(0, -18), Vector2(0.85, 0.75), 9.0)
					affected += 1
			root.selected_unit.play_skill()
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "가짜 발자국", "%d명 교란" % affected)
			root._log("로로의 가짜 발자국이 %d명을 헷갈리게 했습니다." % affected)
		"rumor_boost":
			root.rewards_pending["infamy"] = int(root.rewards_pending.get("infamy", 0)) + 8
			root.selected_unit.play_skill()
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "소문 부풀리기", "악명 +8")
			spawn_effect_burst("loot", root.selected_unit.global_position, Vector2(0, -22), Vector2(1.05, 0.95), 13.0)
			root._log("로로가 원정식 과장 보고를 시작했습니다. 악명 +8.")
		_:
			root.selected_unit.play_skill()
			root._log("%s 사용." % skill.get("display_name", skill_id))
	root.selected_unit.set_skill_cooldown(skill_id, float(skill.get("cooldown", 5.0)))
	root._set_screen(Constants.SCREEN_COMBAT)

func _promotion_skill_float(monster_id: String, skill_id: String, key: String, fallback: float = 0.0) -> float:
	if root.has_method("_promotion_skill_float"):
		return root._promotion_skill_float(monster_id, skill_id, key, fallback)
	return fallback

func set_speed(speed: float) -> void:
	root.combat_speed = speed
	root._log("전투 속도 x%.1f." % root.combat_speed)

func toggle_pause() -> void:
	root.combat_paused = not root.combat_paused
	for unit in root.monster_units + root.enemy_units:
		if is_instance_valid(unit):
			unit.set_physics_process(not root.combat_paused)
	root._log("일시정지." if root.combat_paused else "전투 재개.")

func spawn_projectile(from_position: Vector2, to_position: Vector2) -> void:
	var sprite = _make_effect_sprite("fireball", true, 14.0)
	if sprite == null:
		return
	sprite.global_position = from_position
	sprite.z_index = 3000
	sprite.rotation = from_position.angle_to_point(to_position)
	root.effect_root.add_child(sprite)
	var tween = root.create_tween()
	tween.tween_property(sprite, "global_position", to_position, 0.22)
	tween.tween_callback(Callable(self, "spawn_impact").bind(to_position))
	tween.tween_callback(sprite.queue_free)

func spawn_slash(position: Vector2) -> void:
	var sprite = _make_effect_sprite("slash", false, 18.0)
	if sprite == null:
		return
	sprite.global_position = position + Vector2(0, -18)
	sprite.scale = Vector2(0.72, 0.72)
	sprite.z_index = 3000
	root.effect_root.add_child(sprite)
	var tween = root.create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.90, 0.90), 0.10)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.14)
	tween.tween_callback(sprite.queue_free)

func spawn_impact(position: Vector2) -> void:
	var sprite = _make_effect_sprite("impact", false, 16.0)
	if sprite == null:
		return
	sprite.global_position = position + Vector2(0, -20)
	sprite.scale = Vector2(0.72, 0.72)
	sprite.z_index = 3000
	root.effect_root.add_child(sprite)
	var tween = root.create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.96, 0.96), 0.16)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.20)
	tween.tween_callback(sprite.queue_free)

func spawn_effect_burst(effect_id: String, position: Vector2, offset: Vector2 = Vector2.ZERO, effect_scale: Vector2 = Vector2.ONE, fps: float = 14.0) -> void:
	var sprite = _make_effect_sprite(effect_id, false, fps)
	if sprite == null:
		return
	sprite.global_position = position + offset
	sprite.scale = effect_scale
	sprite.z_index = 3000
	root.effect_root.add_child(sprite)
	var tween = root.create_tween()
	tween.tween_interval(0.28)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.12)
	tween.tween_callback(sprite.queue_free)

func _make_effect_sprite(effect_id: String, loop: bool, fps: float) -> AnimatedSprite2D:
	var sprite = AnimatedSprite2D.new()
	var frames = SpriteFrames.new()
	frames.add_animation("play")
	frames.set_animation_loop("play", loop)
	frames.set_animation_speed("play", fps)
	var sequence: Array = root.effect_frame_sets.get(effect_id, [])
	for texture in sequence:
		if texture != null:
			frames.add_frame("play", texture)
	if frames.get_frame_count("play") == 0:
		var fallback = root.effect_textures.get(effect_id)
		if fallback == null:
			return null
		frames.add_frame("play", fallback)
	sprite.sprite_frames = frames
	sprite.animation = "play"
	sprite.play("play")
	return sprite
