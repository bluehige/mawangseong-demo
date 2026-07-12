extends RefCounted
class_name CombatSceneController

const Constants = preload("res://scripts/core/Constants.gd")
const TargetingService = preload("res://scripts/combat/TargetingService.gd")
const DamageService = preload("res://scripts/combat/DamageService.gd")
const DirectiveManager = preload("res://scripts/combat/DirectiveManager.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const UI_FONT = UIFontScript.BODY_FONT
const SFX_SLASH = preload("res://assets/audio/sfx/combat_slash.wav")
const SFX_SHIELD_BASH = preload("res://assets/audio/sfx/combat_shield_bash.wav")
const SFX_FIRE_BURST = preload("res://assets/audio/sfx/combat_fire_burst.wav")
const SFX_HIT = preload("res://assets/audio/sfx/combat_hit.wav")
const SFX_DOWN = preload("res://assets/audio/sfx/combat_down.wav")

const BARRACKS_ATTACK_MULTIPLIER = 1.25
const BARRACKS_DAMAGE_TAKEN_MULTIPLIER = 0.78
const WATCH_POST_DAMAGE_MULTIPLIER = 1.18
const WATCH_POST_SLOW_SECONDS = 0.45
const WATCH_POST_SLOW_FACTOR = 0.72
const ENGINEER_DISABLE_SECONDS = 10.0
const ROYAL_RALLY_MOVE_MULTIPLIER = 1.18
const ROYAL_RALLY_ATTACK_INTERVAL_MULTIPLIER = 0.85
const ROYAL_RALLY_PULSE_SECONDS = 8.0
const ALL_OUT_ATTACK_MULTIPLIER = 1.15
const ALL_OUT_DAMAGE_TAKEN_MULTIPLIER = 1.45
const DEFENSE_DAMAGE_TAKEN_MULTIPLIER = 0.50
const SURVIVAL_ATTACK_MULTIPLIER = 0.90
const SURVIVAL_DAMAGE_TAKEN_MULTIPLIER = 0.45
const UNOPPOSED_THRONE_DAMAGE_MULTIPLIER = 3.0
const MELEE_CONTACT_DELAY = 0.18
const PROJECTILE_TRAVEL_SECONDS = 0.12
const DAMAGE_NUMBER_LANE_WINDOW_MSEC = 700
const DAMAGE_NUMBER_LANE_OFFSETS = [
	Vector2(0, 0),
	Vector2(-26, -12),
	Vector2(26, -20),
	Vector2(-42, -30),
	Vector2(42, -38)
]

var root: Node
var hud
var recovery_heal_accumulator: Dictionary = {}
var camera_kick_cooldown := 0.0
var sfx_cooldowns: Dictionary = {}
var damage_number_lanes: Dictionary = {}
var royal_rally_pulse_timer := 0.0
var royal_rally_active_seconds := 0.0
var royal_rally_activations := 0
var royal_rally_was_active := false
var royal_rally_stopped := false

func setup(game_root: Node, hud_controller) -> void:
	root = game_root
	hud = hud_controller

func physics_process(delta: float) -> void:
	_update_sfx_cooldowns(delta)
	if root.current_screen != Constants.SCREEN_COMBAT:
		return
	hud.update_combat_skill_buttons()
	if root.combat_paused:
		return
	var sim_delta = delta * root.combat_speed
	camera_kick_cooldown = max(0.0, camera_kick_cooldown - delta)
	root.combat_time += sim_delta
	if root.has_method("_update_campaign_combat_timed_lines"):
		root._update_campaign_combat_timed_lines()
	if root.has_method("_update_facility_disables"):
		root._update_facility_disables(sim_delta)
	hud.update_facility_effect_panel()
	root.trap_cooldown = max(0.0, root.trap_cooldown - sim_delta)
	spawn_ready_enemies(sim_delta)
	_update_royal_rally(sim_delta)
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
	camera_kick_cooldown = 0.0
	sfx_cooldowns.clear()
	root.spawned_count = 0
	root.thief_steal_timers.clear()
	root.treasure_gold_stolen_this_battle = 0
	root.thieves_spawned_this_battle = 0
	root.thieves_reached_treasure_this_battle = 0
	root.thieves_completed_theft_this_battle = 0
	root.thieves_escaped_this_battle = 0
	royal_rally_pulse_timer = 0.0
	royal_rally_active_seconds = 0.0
	royal_rally_activations = 0
	royal_rally_was_active = false
	royal_rally_stopped = false
	if root.has_method("_reset_engineer_combat_state"):
		root._reset_engineer_combat_state()
	if root.has_method("_reset_campaign_combat_timed_lines"):
		root._reset_campaign_combat_timed_lines()
	recovery_heal_accumulator.clear()
	if root.has_method("_reset_facility_effect_stats"):
		root._reset_facility_effect_stats()
	if root.has_method("_reset_directive_effect_stats"):
		root._reset_directive_effect_stats()
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
			var source_label := str(modifier.get("source_label", "원정 효과 적용"))
			root._log("%s: %s" % [source_label, str(modifier.get("display_name", "다음 방어 변화"))])
			var combat_start_line := str(modifier.get("combat_start_line", ""))
			if combat_start_line != "":
				root._log(combat_start_line)
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
		if root.has_method("_growth_preparation_active") and root._growth_preparation_active(str(monster_id)):
			var preparation_name = root._growth_preparation_combat_name(str(monster_id)) if root.has_method("_growth_preparation_combat_name") else "집중 준비"
			var preparation_preview = root._result_growth_preparation_preview(str(monster_id)) if root.has_method("_result_growth_preparation_preview") else ""
			unit.activate_growth_preparation(preparation_name, preparation_preview)
			spawn_growth_preparation_feedback(unit.global_position, preparation_name)
			root._log("%s의 %s 발동: %s." % [unit.display_name, preparation_name, preparation_preview])
		if root.selected_unit == null:
			root._select_unit(unit)

func spawn_ready_enemies(delta: float) -> void:
	for entry in root.wave_manager.tick(delta):
		spawn_enemy(entry.get("enemy_id", "explorer"), entry)

func spawn_enemy(enemy_id: String, wave_entry: Dictionary = {}) -> void:
	var stats = _scaled_enemy_stats(enemy_id, wave_entry)
	var unit = root._create_unit(enemy_id, stats, Constants.FACTION_ENEMY, "entrance")
	if GameState.day == 21 and enemy_id == "selen_trainee_paladin":
		unit.role = "commander"
	unit.global_position = root._clamp_to_combat_walkable(root._room_actor_point("entrance", root.spawned_count + 3, true))
	if stats.get("goal_type", "") == "facility":
		root.engineers_spawned_this_battle += 1
		_assign_engineer_target(unit)
	else:
		var treasure_room = _treasure_room()
		unit.goal_room = treasure_room if stats.get("goal_type", "") == "treasure" and treasure_room != "" else _core_room()
		unit.set_path(_path_from_world_to_room(unit.global_position, unit.goal_room))
	root.enemy_units.append(unit)
	root.spawned_count += 1
	if enemy_id == "thief":
		root.thieves_spawned_this_battle += 1
	if root.has_method("_onboarding_enemy_spawned"):
		root._onboarding_enemy_spawned(enemy_id)
	root._log("%s가 입구에 도착했습니다." % unit.display_name)

func _royal_rally_commander() -> Node:
	if GameState.day != 21:
		return null
	for enemy in root.enemy_units:
		if enemy.is_alive() and enemy.unit_id == "selen_trainee_paladin" and enemy.role == "commander":
			return enemy
	return null

func _update_royal_rally(delta: float) -> void:
	if GameState.day != 21:
		return
	var commander = _royal_rally_commander()
	var active := commander != null
	for enemy in root.enemy_units:
		if not is_instance_valid(enemy):
			continue
		var receives_rally: bool = active and enemy.is_alive() and enemy != commander
		enemy.royal_rally_move_multiplier = ROYAL_RALLY_MOVE_MULTIPLIER if receives_rally else 1.0
		enemy.royal_rally_attack_interval_multiplier = ROYAL_RALLY_ATTACK_INTERVAL_MULTIPLIER if receives_rally else 1.0
	if active:
		royal_rally_active_seconds += delta
		royal_rally_pulse_timer -= delta
		if royal_rally_pulse_timer <= 0.0:
			royal_rally_pulse_timer = ROYAL_RALLY_PULSE_SECONDS
			royal_rally_activations += 1
			commander.play_skill(commander.global_position + Vector2(1, 0))
			commander.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "왕국군 진군 지휘", "%d명 강화" % _royal_rally_recipient_count(commander))
			root._log("셀렌의 진군 지휘: 주변 왕국군의 이동과 공격 속도가 상승합니다.")
	elif royal_rally_was_active:
		royal_rally_stopped = true
		root._log("셀렌이 쓰러져 왕국군의 진군 강화가 해제되었습니다.")
	royal_rally_was_active = active

func _royal_rally_recipient_count(commander: Node) -> int:
	var count := 0
	for enemy in root.enemy_units:
		if enemy != commander and enemy.is_alive():
			count += 1
	return count

func _royal_rally_result_line() -> String:
	if GameState.day != 21:
		return ""
	var stopped_text := "지휘관 격퇴" if royal_rally_stopped else "전투 종료까지 유지"
	return "셀렌 지휘: 진군 강화 %.1f초 · 지휘 %d회 · %s" % [royal_rally_active_seconds, royal_rally_activations, stopped_text]

func clear_effects() -> void:
	damage_number_lanes.clear()
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
			var room_id := _point_room(unit.global_position)
			if room_id != "":
				unit.current_room = room_id

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
	var hp_ratio = float(unit.hp) / float(unit.max_hp)
	if root.global_directive == Constants.DIRECTIVE_SURVIVAL:
		var has_recovery_nest = root._facility_is_active("recovery")
		var retreat_threshold = 0.85 if has_recovery_nest else 0.70
		var return_threshold = 0.95 if has_recovery_nest else 0.85
		var survival_recovering = unit.tactical_state == Constants.UNIT_STATE_RETREAT and hp_ratio < return_threshold
		if hp_ratio <= retreat_threshold or survival_recovering:
			_retreat_unit(unit, "생존 우선")
			return
	if root.global_directive == Constants.DIRECTIVE_DEFENSE and hp_ratio <= 0.55:
		unit.activate_shield(0.6, 0.70)
	var priority_target = TargetingService.monster_priority(unit, root.enemy_units, root.graph, _core_room(), _treasure_room())
	priority_target = _specialization_priority_target(unit, priority_target)
	if priority_target != null and priority_target.current_room == _core_room():
		move_unit_to_room(unit, _core_room())
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "왕좌 긴급 방어", priority_target.display_name)
		return
	if root.room_directives.get(unit.current_room, Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_RETREAT:
		_retreat_unit(unit, "후퇴선 유지")
		return

	if priority_target != null and _hold_attack_position(unit, priority_target):
		return
	var ai_behavior = _monster_ai_behavior(unit)
	if ai_behavior == "thief_hunter":
		if priority_target != null and priority_target.unit_id == "thief":
			if priority_target.current_room == unit.current_room:
				move_unit_to_point(unit, priority_target.global_position)
			else:
				move_unit_to_room(unit, priority_target.current_room)
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "도둑 추격", priority_target.display_name)
			if root.has_method("_onboarding_emit_trigger"):
				root._onboarding_emit_trigger("goblin_chase")
			return
		var thief_has_spawned := false
		for enemy in root.enemy_units:
			if enemy.unit_id == "thief":
				thief_has_spawned = true
				break
		if not thief_has_spawned:
			var staging_room = "spike_corridor" if root.rooms.has("spike_corridor") else str(unit.assigned_room)
			move_unit_to_room(unit, staging_room)
			unit.set_tactical_state(Constants.UNIT_STATE_SEEK_TARGET, "도둑 대비", _room_name(staging_room))
			return
	if ai_behavior == "ally_guard":
		var wounded_ally = _most_wounded_ally(unit)
		if wounded_ally != null and wounded_ally.current_room != unit.current_room:
			move_unit_to_room(unit, wounded_ally.current_room)
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "부상 아군 호위", wounded_ally.display_name)
			return
	if ai_behavior == "entry_anchor" and unit.unit_id == "slime":
		var anchor_point = root.graph.center("entrance").lerp(root.graph.center("spike_corridor"), 0.55)
		move_unit_to_point(unit, anchor_point)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "성문 파수", "입구 방어선")
		return
	if ai_behavior == "trap_support" and unit.unit_id == "imp":
		var support_point = root.graph.center("spike_corridor").lerp(root.graph.center(_barracks_room()), 0.58)
		move_unit_to_point(unit, support_point)
		unit.set_tactical_state(Constants.UNIT_STATE_SEEK_TARGET, "함정 화력 지원", "가시 복도")
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
	if unit.unit_id == "engineer" and _update_engineer_path(unit):
		return
	if unit.unit_id == "thief" and float(root.thief_steal_timers.get(unit, 0.0)) < -100.0:
		if unit.current_room != "entrance":
			move_unit_to_room(unit, "entrance")
			unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "보물 탈출", _room_name("entrance"))
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
		var pressured_ally = _most_wounded_ally(unit)
		if pressured_ally != null and pressured_ally.current_room == priority_target.current_room:
			return priority_target
		return null
	return priority_target

func _monster_ai_behavior(unit: Node) -> String:
	if root.has_method("_monster_ai_behavior"):
		return root._monster_ai_behavior(str(unit.unit_id))
	return ""

func _specialization_priority_target(unit: Node, fallback: Node) -> Node:
	match _monster_ai_behavior(unit):
		"thief_hunter":
			var thieves: Array = []
			for enemy in root.enemy_units:
				if enemy.is_alive() and enemy.unit_id == "thief":
					thieves.append(enemy)
			var thief_target = TargetingService.nearest(unit, thieves)
			if thief_target != null:
				return thief_target
		"wounded_hunter":
			var wounded_enemy: Node = null
			var lowest_ratio := 2.0
			for enemy in root.enemy_units:
				if not enemy.is_alive():
					continue
				var hp_ratio = float(enemy.hp) / float(max(1, enemy.max_hp))
				if hp_ratio < lowest_ratio:
					lowest_ratio = hp_ratio
					wounded_enemy = enemy
			if wounded_enemy != null:
				return wounded_enemy
	return fallback

func _most_wounded_ally(unit: Node) -> Node:
	var result: Node = null
	var lowest_ratio := 0.7
	for ally in root.monster_units:
		if ally == unit or not ally.is_alive():
			continue
		var hp_ratio = float(ally.hp) / float(max(1, ally.max_hp))
		if hp_ratio < lowest_ratio:
			lowest_ratio = hp_ratio
			result = ally
	return result

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
	if root.global_directive == Constants.DIRECTIVE_SURVIVAL:
		unit.activate_shield(0.6, 0.80)
	elif root.global_directive == Constants.DIRECTIVE_DEFENSE:
		unit.activate_shield(0.6, 0.70)
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
			var hp_before = int(monster.hp)
			var dealt_damage = monster.receive_damage(20)
			_record_damage_contribution(unit, monster, 20, dealt_damage, hp_before)
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

func _nearest_active_facility_room(from_room: String) -> String:
	var best_room := ""
	var best_distance := 999999
	for room_id in root._engineer_target_facility_rooms():
		var distance := 0
		if room_id != from_room:
			var route: Array = root.graph.path_between(from_room, room_id)
			if route.is_empty():
				continue
			distance = route.size()
		if distance < best_distance or (distance == best_distance and (best_room == "" or room_id < best_room)):
			best_distance = distance
			best_room = room_id
	return best_room

func _assign_engineer_target(unit: Node) -> bool:
	var room_id := _nearest_active_facility_room(str(unit.current_room))
	if room_id == "":
		root.engineer_target_rooms.erase(unit.get_instance_id())
		unit.goal_room = _core_room()
		unit.set_path(_path_from_world_to_room(unit.global_position, unit.goal_room))
		return false
	root.engineer_target_rooms[unit.get_instance_id()] = room_id
	root.engineer_targeted_facility_rooms[room_id] = true
	unit.goal_room = room_id
	unit.set_path(_path_from_world_to_room(unit.global_position, room_id))
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "시설 교란 접근", _room_name(room_id))
	root._log("왕국 공병 목표: %s." % _room_name(room_id))
	root.queue_redraw()
	return true

func _update_engineer_path(unit: Node) -> bool:
	var instance_id = unit.get_instance_id()
	if root.engineer_completed_units.has(instance_id):
		return false
	var target_room := str(root.engineer_target_rooms.get(instance_id, ""))
	if target_room == "" or not root._facility_room_is_active(target_room):
		if not _assign_engineer_target(unit):
			return false
		target_room = str(root.engineer_target_rooms.get(instance_id, ""))
	if unit.current_room == target_room:
		root.engineer_completed_units[instance_id] = true
		root.engineer_target_rooms.erase(instance_id)
		root.engineers_reached_facility_this_battle += 1
		root._disable_facility_room(target_room, ENGINEER_DISABLE_SECONDS)
		unit.role = "throne"
		unit.goal_room = _core_room()
		unit.set_path(_path_from_world_to_room(unit.global_position, unit.goal_room))
		unit.play_skill(root.graph.center(target_room))
		unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "시설 무력화", _room_name(target_room))
		return true
	move_unit_to_room(unit, target_room)
	unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "시설 교란 접근", _room_name(target_room))
	return true

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
	if not unit.path_points.is_empty() and unit.path_points[-1].distance_to(point) <= 16.0:
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
	if not root._facility_is_active("recovery"):
		recovery_room = ""
	var core_room = _core_room()
	var treasure_room = _treasure_room()
	var watch_rooms = _watch_post_pressure_rooms()
	_record_barracks_combat_time(delta)
	for unit in root.monster_units:
		if not unit.is_alive() or recovery_room == "":
			continue
		var recovery_rate := 0.0
		if unit.current_room == recovery_room:
			recovery_rate = 8.0 * _castle_facility_scale("recovery_power_scale")
		elif unit.assigned_room == recovery_room and root.graph.exits(recovery_room).has(unit.current_room):
			recovery_rate = 3.0 * _castle_facility_scale("recovery_power_scale")
		if recovery_rate > 0.0:
			var key = unit.get_instance_id()
			var carry = float(recovery_heal_accumulator.get(key, 0.0)) + recovery_rate * delta
			var heal_amount = int(floor(carry))
			recovery_heal_accumulator[key] = carry - float(heal_amount)
			if heal_amount > 0:
				var before_hp = unit.hp
				unit.heal(heal_amount)
				var healed = max(0, unit.hp - before_hp)
				if healed > 0 and root.has_method("_record_facility_effect_stat"):
					root._record_facility_effect_stat("recovery_healing", healed)
					root._record_monster_contribution(str(unit.unit_id), "facility_value", healed)
			if unit.current_room == recovery_room:
				unit.set_tactical_state(Constants.UNIT_STATE_RETREAT, "회복 중", _room_name(recovery_room))
	for enemy in root.enemy_units:
		if enemy.is_alive() and watch_rooms.has(enemy.current_room):
			if enemy.slow_timer <= 0.05 and root.has_method("_record_facility_effect_stat"):
				root._record_facility_effect_stat("watch_post_slow_applications", 1)
			enemy.apply_slow(WATCH_POST_SLOW_SECONDS, _watch_post_slow_factor())
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
	var active_defender_count := 0
	for monster in root.monster_units:
		if monster.is_alive():
			active_defender_count += 1
	for enemy in root.enemy_units:
		if enemy.is_alive() and enemy.current_room == core_room:
			enemy.set_tactical_state(Constants.UNIT_STATE_ATTACK, "왕좌 압박", _room_name(core_room))
			if enemy.attack_cooldown <= 0.0 and TargetingService.nearest(enemy, root.monster_units, enemy.attack_range) == null:
				var throne_damage: int = maxi(8, int(enemy.atk))
				if active_defender_count == 0:
					throne_damage = int(round(float(throne_damage) * UNOPPOSED_THRONE_DAMAGE_MULTIPLIER))
				GameState.damage_throne(throne_damage)
				enemy.attack_cooldown = enemy.effective_attack_interval()
				if active_defender_count == 0:
					root._log("방어 몬스터가 모두 쓰러져 %s의 왕좌 공격이 강해졌습니다." % enemy.display_name)
				else:
					root._log("%s가 왕좌의 방을 공격했습니다." % enemy.display_name)
		if enemy.is_alive() and enemy.unit_id == "thief" and treasure_room != "" and enemy.current_room == treasure_room:
			enemy.set_tactical_state(Constants.UNIT_STATE_LOOTING, "보물 약탈", "금화")
			if not root.thief_steal_timers.has(enemy):
				root.thieves_reached_treasure_this_battle += 1
				root._log("도둑이 보물 방에 침입했습니다. 약탈까지 5초 남았습니다.")
			var timer = float(root.thief_steal_timers.get(enemy, 0.0)) + delta
			root.thief_steal_timers[enemy] = timer
			if timer >= 5.0:
				var stolen_gold = min(100, GameState.gold)
				GameState.gold = max(0, GameState.gold - stolen_gold)
				SignalBus.resources_changed.emit()
				root.thief_steal_timers[enemy] = -999.0
				root.treasure_gold_stolen_this_battle += stolen_gold
				root.thieves_completed_theft_this_battle += 1
				enemy.goal_room = "entrance"
				enemy.set_path(_path_from_world_to_room(enemy.global_position, "entrance"))
				if root.has_method("_onboarding_treasure_stolen"):
					root._onboarding_treasure_stolen()
				root._log("도둑이 보물을 훔쳤습니다. 금화 -%d." % stolen_gold)
		if enemy.is_alive() and enemy.unit_id == "thief" and float(root.thief_steal_timers.get(enemy, 0.0)) < -100.0 and enemy.current_room == "entrance":
			enemy.hp = 0
			enemy.down = true
			enemy.visible = false
			root.thieves_escaped_this_battle += 1
			root._log("도둑이 입구로 도주했습니다.")

func _record_barracks_combat_time(delta: float) -> void:
	if not root.has_method("_record_facility_effect_time"):
		return
	if not root._facility_is_active("barracks"):
		return
	var barracks_room = _barracks_room()
	if barracks_room == "" or root._room_by_facility("barracks", "") == "":
		return
	for unit in root.monster_units:
		if not unit.is_alive() or unit.assigned_room != barracks_room:
			continue
		root._record_facility_effect_time("barracks_assigned_unit_seconds", delta)
		if not _unit_in_facility_room(unit, "barracks"):
			continue
		root._record_facility_effect_time("barracks_covered_unit_seconds", delta)
		var enemy_in_room := false
		var enemy_in_range := false
		for enemy in root.enemy_units:
			if not enemy.is_alive() or enemy.current_room != unit.current_room:
				continue
			enemy_in_room = true
			if unit.global_position.distance_to(enemy.global_position) <= unit.attack_range:
				enemy_in_range = true
		if enemy_in_room:
			root._record_facility_effect_time("barracks_contested_unit_seconds", delta)
		if enemy_in_range:
			root._record_facility_effect_time("barracks_in_range_unit_seconds", delta)

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
	if attacker.tactical_state == Constants.UNIT_STATE_STUNNED:
		return
	var fighting_retreat = attacker.tactical_state == Constants.UNIT_STATE_RETREAT
	var target = _direct_control_attack_target(attacker, opponents)
	if target == null:
		target = TargetingService.nearest(attacker, opponents, attacker.attack_range)
	if target == null:
		return
	if not fighting_retreat and attacker.has_method("stop_navigation"):
		attacker.stop_navigation()
	var base_damage = DamageService.compute(attacker, target, 1.0)
	var directive_multiplier = _directive_attack_multiplier(attacker)
	var directive_damage = DamageService.compute(attacker, target, directive_multiplier)
	_record_directive_attack_effect(attacker, base_damage, directive_damage)
	var damage = DamageService.compute(attacker, target, directive_multiplier * _facility_attack_multiplier(attacker, target))
	_record_facility_attack_bonus(attacker, target, directive_damage, damage, directive_multiplier)
	var damage_before_directive_reduction = damage
	damage = _apply_directive_damage_taken_modifier(target, damage)
	_record_directive_damage_taken_effect(target, damage_before_directive_reduction, damage)
	var damage_before_facility_reduction = damage
	damage = _apply_facility_damage_taken_modifier(attacker, target, damage)
	if damage < damage_before_facility_reduction and root.has_method("_record_facility_effect_stat"):
		var facility_reduction = damage_before_facility_reduction - damage
		root._record_facility_effect_stat("barracks_damage_reduced", facility_reduction)
		root._record_facility_effect_stat("barracks_damage_reduction_applications", 1)
		root._record_monster_contribution(str(target.unit_id), "facility_value", facility_reduction)
	var is_imp_projectile = attacker.faction == Constants.FACTION_MONSTER and attacker.unit_id == "imp"
	if attacker.faction == Constants.FACTION_MONSTER and attacker.unit_id == "goblin" and root.has_method("_tutorial_emit_action"):
		root._tutorial_emit_action("goblin_attacks_once", {"unit_id": attacker.unit_id, "target_id": target.unit_id})
	attacker.attack_cooldown = attacker.effective_attack_interval()
	if not fighting_retreat:
		attacker.set_tactical_state(Constants.UNIT_STATE_ATTACK, "기본 공격", target.display_name)
	_mark_action_target(attacker, target)
	if attacker.has_method("play_attack"):
		attacker.play_attack(target.global_position)
	_play_attack_sfx(attacker)
	if is_imp_projectile:
		_launch_damage_projectile(attacker, target, damage, false, "basic")
	else:
		var hp_before = int(target.hp)
		var dealt_damage = target.receive_damage(damage)
		_record_damage_contribution(attacker, target, damage, dealt_damage, hp_before)
		_apply_combat_hit_feedback(attacker, target, dealt_damage, false, MELEE_CONTACT_DELAY)
		if root.has_method("_onboarding_unit_damaged"):
			root._onboarding_unit_damaged(target)
		if target.has_method("mark_threat"):
			target.mark_threat(attacker)
		spawn_slash(target.global_position, MELEE_CONTACT_DELAY)
		root._log("%s가 %s에게 %d 피해." % [attacker.display_name, target.display_name, dealt_damage])

func _record_facility_attack_bonus(attacker: Node, target: Node, base_damage: int, boosted_damage: int, directive_multiplier: float) -> void:
	if attacker.faction != Constants.FACTION_MONSTER or not root.has_method("_record_facility_effect_stat"):
		return
	var barracks_active = _unit_in_facility_room(attacker, "barracks")
	if barracks_active:
		root._record_facility_effect_stat("barracks_attack_applications", 1)
	if boosted_damage <= base_damage:
		return
	if barracks_active:
		var barracks_only = DamageService.compute(attacker, target, directive_multiplier * _barracks_attack_multiplier())
		var barracks_bonus = max(0, min(barracks_only, int(target.hp)) - min(base_damage, int(target.hp)))
		root._record_facility_effect_stat("barracks_bonus_damage", barracks_bonus)
		root._record_monster_contribution(str(attacker.unit_id), "facility_value", barracks_bonus)
	if target.faction == Constants.FACTION_ENEMY and _watch_post_pressure_rooms().has(target.current_room):
		var watch_only = DamageService.compute(attacker, target, directive_multiplier * _watch_post_damage_multiplier())
		var watch_bonus = max(0, min(watch_only, int(target.hp)) - min(base_damage, int(target.hp)))
		root._record_facility_effect_stat("watch_post_bonus_damage", watch_bonus)
		root._record_monster_contribution(str(attacker.unit_id), "facility_value", watch_bonus)

func _mark_action_target(attacker: Node, target: Node) -> void:
	if attacker == null or target == null:
		return
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	if attacker.has_method("mark_action_target"):
		attacker.mark_action_target(target)

func _record_damage_contribution(attacker: Node, target: Node, incoming_damage: int, dealt_damage: int, hp_before: int, attacker_unit_id: String = "") -> void:
	if target == null or not is_instance_valid(target) or not root.has_method("_record_monster_contribution"):
		return
	var actual_hp_loss = max(0, hp_before - int(target.hp))
	var resolved_attacker_id = attacker_unit_id
	var attacker_is_monster = false
	var attacker_is_enemy = false
	if attacker != null and is_instance_valid(attacker):
		resolved_attacker_id = str(attacker.unit_id)
		attacker_is_monster = attacker.faction == Constants.FACTION_MONSTER
		attacker_is_enemy = attacker.faction == Constants.FACTION_ENEMY
	elif resolved_attacker_id != "" and root.monster_roster.has(resolved_attacker_id):
		attacker_is_monster = true
	if attacker_is_monster and target.faction == Constants.FACTION_ENEMY:
		root._record_monster_contribution(resolved_attacker_id, "damage_dealt", actual_hp_loss)
		if hp_before > 0 and not target.is_alive():
			root._record_monster_contribution(resolved_attacker_id, "finishing_blows", 1)
	elif attacker_is_enemy and target.faction == Constants.FACTION_MONSTER:
		var prevented_damage = max(0, incoming_damage - dealt_damage)
		var pressure_handled = mini(incoming_damage, actual_hp_loss + prevented_damage)
		root._record_monster_contribution(str(target.unit_id), "damage_absorbed", pressure_handled)

func _directive_attack_multiplier(attacker: Node) -> float:
	if attacker.faction != Constants.FACTION_MONSTER:
		return 1.0
	match root.global_directive:
		Constants.DIRECTIVE_ALL_OUT:
			return ALL_OUT_ATTACK_MULTIPLIER
		Constants.DIRECTIVE_SURVIVAL:
			return SURVIVAL_ATTACK_MULTIPLIER
		_:
			return 1.0

func _record_directive_attack_effect(attacker: Node, base_damage: int, directive_damage: int) -> void:
	if attacker.faction != Constants.FACTION_MONSTER or not root.has_method("_record_directive_effect_stat"):
		return
	if root.global_directive == Constants.DIRECTIVE_ALL_OUT and directive_damage > base_damage:
		root._record_directive_effect_stat("all_out_bonus_damage", directive_damage - base_damage)

func _apply_directive_damage_taken_modifier(target: Node, damage: int) -> int:
	if target.faction != Constants.FACTION_MONSTER:
		return damage
	var multiplier := 1.0
	match root.global_directive:
		Constants.DIRECTIVE_ALL_OUT:
			multiplier = ALL_OUT_DAMAGE_TAKEN_MULTIPLIER
		Constants.DIRECTIVE_SURVIVAL:
			multiplier = SURVIVAL_DAMAGE_TAKEN_MULTIPLIER
		_:
			multiplier = DEFENSE_DAMAGE_TAKEN_MULTIPLIER
	return max(1, int(round(float(damage) * multiplier)))

func _record_directive_damage_taken_effect(target: Node, before: int, after: int) -> void:
	if target.faction != Constants.FACTION_MONSTER or not root.has_method("_record_directive_effect_stat"):
		return
	match root.global_directive:
		Constants.DIRECTIVE_ALL_OUT:
			root._record_directive_effect_stat("all_out_extra_damage_taken", max(0, after - before))
		Constants.DIRECTIVE_SURVIVAL:
			root._record_directive_effect_stat("survival_damage_reduced", max(0, before - after))
		_:
			root._record_directive_effect_stat("defense_damage_reduced", max(0, before - after))

func _facility_attack_multiplier(attacker: Node, target: Node) -> float:
	if attacker.faction != Constants.FACTION_MONSTER:
		return 1.0
	var multiplier := 1.0
	if _unit_in_facility_room(attacker, "barracks"):
		multiplier *= _barracks_attack_multiplier()
	if target.faction == Constants.FACTION_ENEMY and _watch_post_pressure_rooms().has(target.current_room):
		multiplier *= _watch_post_damage_multiplier()
	return multiplier

func _apply_facility_damage_taken_modifier(attacker: Node, target: Node, damage: int) -> int:
	var result := damage
	if target.faction == Constants.FACTION_MONSTER:
		var barracks_room = root._room_by_facility("barracks", "") if root._facility_is_active("barracks") else ""
		if barracks_room != "" and target.assigned_room == barracks_room and root.has_method("_record_facility_effect_stat"):
			root._record_facility_effect_stat("barracks_assigned_incoming_attacks", 1)
		if _unit_in_facility_room(target, "barracks"):
			result = int(round(float(result) * _barracks_damage_taken_multiplier()))
			if result >= damage and root.has_method("_record_facility_effect_stat"):
				root._record_facility_effect_stat("barracks_no_reduction_hits", 1)
		if root._facility_is_active("ward_core"):
			var before_ward := result
			result = int(round(float(result) * _castle_facility_scale("ward_damage_taken_scale")))
			if result < before_ward and root.has_method("_record_facility_effect_stat"):
				root._record_facility_effect_stat("ward_damage_reduced", before_ward - result)
	return max(1, result)

func _castle_facility_scale(key: String) -> float:
	if root.has_method("_castle_facility_scale"):
		return float(root._castle_facility_scale(key, 1.0))
	return 1.0

func _barracks_attack_multiplier() -> float:
	return 1.0 + (BARRACKS_ATTACK_MULTIPLIER - 1.0) * _castle_facility_scale("barracks_power_scale")

func _barracks_damage_taken_multiplier() -> float:
	return 1.0 - (1.0 - BARRACKS_DAMAGE_TAKEN_MULTIPLIER) * _castle_facility_scale("barracks_power_scale")

func _watch_post_damage_multiplier() -> float:
	return 1.0 + (WATCH_POST_DAMAGE_MULTIPLIER - 1.0) * _castle_facility_scale("watch_power_scale")

func _watch_post_slow_factor() -> float:
	return clampf(1.0 - (1.0 - WATCH_POST_SLOW_FACTOR) * _castle_facility_scale("watch_power_scale"), 0.45, 0.95)

func _unit_in_facility_room(unit: Node, facility_id: String) -> bool:
	if not root._facility_is_active(facility_id):
		return false
	var facility_room = root._room_by_facility(facility_id, "")
	if facility_room == "" or unit.assigned_room != facility_room:
		return false
	if unit.current_room == facility_room:
		return true
	return root.graph != null and root.graph.exits(facility_room).has(unit.current_room)

func _watch_post_pressure_rooms() -> Array:
	if not root._facility_is_active("watch_post"):
		return []
	var watch_room = root._room_by_facility("watch_post", "")
	if watch_room == "":
		return []
	var result: Array = [watch_room]
	if root.graph != null and root.graph.has_method("exits"):
		for room_id in root.graph.exits(watch_room):
			if not result.has(room_id):
				result.append(room_id)
		if _castle_facility_scale("watch_power_scale") > 1.0:
			var first_ring := result.duplicate()
			for first_room in first_ring:
				for room_id in root.graph.exits(str(first_room)):
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
			var shared_exp = max(5, int(unit.exp_reward / 3))
			root.monster_roster[monster_id]["exp"] = int(root.monster_roster[monster_id]["exp"]) + shared_exp
			if root.has_method("_record_monster_contribution"):
				root._record_monster_contribution(str(monster_id), "shared_exp", shared_exp)
		root._log("%s 격퇴. 악명 +%d." % [unit.display_name, unit.infamy_reward])
		if GameState.day == 21 and unit.unit_id == "selen_trainee_paladin":
			_update_royal_rally(0.0)
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
	var alive_monsters := 0
	var total_monsters := 0
	var remaining_monster_hp := 0
	var total_monster_hp := 0
	for monster in root.monster_units:
		if not is_instance_valid(monster):
			continue
		total_monsters += 1
		remaining_monster_hp += max(0, int(monster.hp))
		total_monster_hp += int(monster.max_hp)
		if monster.is_alive():
			alive_monsters += 1
	lines.append(reason)
	lines.append("격퇴한 적: %d / 스폰: %d" % [count_downed_enemies(), root.spawned_count])
	lines.append("전투 시간: %.1f초 / 생존 몬스터: %d/%d" % [root.combat_time, alive_monsters, total_monsters])
	lines.append("잔여 전력: HP %d / %d" % [remaining_monster_hp, total_monster_hp])
	lines.append("획득 금화: %d" % int(root.rewards_pending.get("gold", 0)))
	lines.append("획득 마력: %d" % int(root.rewards_pending.get("mana", 0)))
	lines.append("증가 악명: %d" % int(root.rewards_pending.get("infamy", 0)))
	if root.has_method("_current_security_result_line"):
		var security_result_line: String = root._current_security_result_line()
		if security_result_line != "":
			lines.append(security_result_line)
	if int(root.treasure_gold_stolen_this_battle) > 0:
		lines.append("보물 손실: 금화 %d" % int(root.treasure_gold_stolen_this_battle))
	lines.append("마왕성 체력: %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp])
	if root.has_method("_directive_effect_result_lines"):
		lines.append_array(root._directive_effect_result_lines())
	if root.has_method("_facility_effect_result_lines"):
		lines.append_array(root._facility_effect_result_lines())
	if root.has_method("_engineer_result_lines"):
		lines.append_array(root._engineer_result_lines())
	var rally_result_line := _royal_rally_result_line()
	if rally_result_line != "":
		lines.append(rally_result_line)
	if root.has_method("_campaign_result_lines"):
		lines.append_array(root._campaign_result_lines(win))
	if root.has_method("_apply_campaign_result_flags"):
		root._apply_campaign_result_flags(win)
	for line_index in range(lines.size()):
		if str(lines[line_index]).begins_with("마왕성 체력:"):
			lines[line_index] = "마왕성 체력: %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp]
			break
	root.result_summary = {
		"win": win,
		"lines": lines,
		"growth": growth_summary,
		"metrics": {
			"combat_time": root.combat_time,
			"alive_monsters": alive_monsters,
			"total_monsters": total_monsters,
			"remaining_monster_hp": remaining_monster_hp,
			"total_monster_hp": total_monster_hp,
			"directive": root.global_directive,
			"directive_effects": root.directive_effect_stats.duplicate(true),
			"facility_effects": root.facility_effect_stats.duplicate(true),
			"monster_contributions": root.battle_contribution_stats.duplicate(true),
			"demon_lord_hp": GameState.demon_lord_hp,
			"treasure_gold_stolen": root.treasure_gold_stolen_this_battle,
			"thieves_spawned": root.thieves_spawned_this_battle,
			"thieves_reached_treasure": root.thieves_reached_treasure_this_battle,
			"thieves_completed_theft": root.thieves_completed_theft_this_battle,
			"thieves_escaped": root.thieves_escaped_this_battle,
			"engineers_spawned": root.engineers_spawned_this_battle,
			"engineers_reached_facility": root.engineers_reached_facility_this_battle,
			"facility_disables": root.facility_disables_this_battle,
			"facilities_saved": root._engineer_facilities_saved_count(),
			"royal_rally_seconds": royal_rally_active_seconds,
			"royal_rally_activations": royal_rally_activations,
			"royal_rally_stopped": royal_rally_stopped
		}
	}
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

func enable_direct_control() -> bool:
	if root.selected_unit == null or root.selected_unit.faction != Constants.FACTION_MONSTER:
		root._log("직접 조종할 몬스터를 선택하세요.")
		return false
	if not root.selected_unit.is_alive():
		root._log("전투 불능인 몬스터는 직접 조종할 수 없습니다.")
		return false
	root.selected_unit.begin_direct_control()
	root._log("%s 직접 조종 시작. 우클릭 이동, 적 우클릭 공격 지정." % root.selected_unit.display_name)
	return true

func release_direct_control() -> void:
	if root.selected_unit == null:
		return
	root.selected_unit.release_direct_control()
	root._log("%s AI 복귀." % root.selected_unit.display_name)

func preview_selected_skill(slot: int) -> void:
	clear_skill_preview()
	if root.selected_unit == null or not is_instance_valid(root.selected_unit) or root.selected_unit.faction != Constants.FACTION_MONSTER:
		return
	var skill_slots: Array = DataRegistry.monster(root.selected_unit.unit_id).get("skill_slots", [])
	if slot < 0 or slot >= skill_slots.size() or skill_slots[slot] == null:
		return
	var skill_id := str(skill_slots[slot])
	var skill_name := str(DataRegistry.skill(skill_id).get("display_name", skill_id))
	var preview_range := 0.0
	var preview_targets: Array = []
	match skill_id:
		"slime_shield", "hold_corridor", "loot_instinct", "rumor_boost":
			preview_range = 52.0
			preview_targets.append(root.selected_unit)
		"quick_slash":
			preview_range = root.selected_unit.attack_range + 38.0
			var slash_target = TargetingService.nearest(root.selected_unit, root.enemy_units, preview_range)
			if slash_target != null:
				preview_targets.append(slash_target)
		"fireball":
			preview_range = 320.0 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "range_bonus", 0.0)
			var fire_target = TargetingService.nearest(root.selected_unit, root.enemy_units, preview_range)
			if fire_target != null:
				preview_targets.append(fire_target)
		"flame_zone":
			var barracks_room = _barracks_room()
			for enemy in root.enemy_units:
				if enemy.is_alive() and ["spike_corridor", barracks_room].has(enemy.current_room):
					preview_targets.append(enemy)
		"false_footprints":
			preview_range = 260.0
			for enemy in root.enemy_units:
				if enemy.is_alive() and root.selected_unit.global_position.distance_to(enemy.global_position) <= preview_range:
					preview_targets.append(enemy)
	var target_summary := "자신 강화" if preview_targets.size() == 1 and preview_targets[0] == root.selected_unit else "%d명 대상" % preview_targets.size()
	if preview_targets.is_empty() and ["quick_slash", "fireball", "flame_zone", "false_footprints"].has(skill_id):
		target_summary = "현재 대상 없음"
	root.selected_unit.set_skill_preview(preview_range, preview_targets, "%s · %s" % [skill_name, target_summary])

func clear_skill_preview() -> void:
	for monster in root.monster_units:
		if is_instance_valid(monster) and monster.has_method("clear_skill_preview"):
			monster.clear_skill_preview()

func use_selected_skill(slot: int) -> bool:
	clear_skill_preview()
	if root.selected_unit == null or root.selected_unit.faction != Constants.FACTION_MONSTER:
		return false
	if not root.selected_unit.is_alive():
		root._log("전투 불능인 몬스터는 스킬을 사용할 수 없습니다.")
		return false
	var monster_data = DataRegistry.monster(root.selected_unit.unit_id)
	var skills: Array = monster_data.get("skill_slots", [])
	if slot < 0 or slot >= skills.size() or skills[slot] == null:
		root._log("사용 가능한 스킬이 없습니다.")
		return false
	var skill_id = str(skills[slot])
	if not root.selected_unit.skill_ready(skill_id):
		root._log("스킬 재사용 대기 중입니다.")
		return false
	var skill = DataRegistry.skill(skill_id)
	var cost = int(skill.get("cost_mana", 0))
	if GameState.mana < cost:
		root._log("마력이 부족합니다.")
		return false
	var prepared_target: Node = null
	if skill_id == "quick_slash":
		prepared_target = TargetingService.nearest(root.selected_unit, root.enemy_units, root.selected_unit.attack_range + 38.0)
	elif skill_id == "fireball":
		var prepared_fire_range = 320.0 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "range_bonus", 0.0)
		prepared_target = TargetingService.nearest(root.selected_unit, root.enemy_units, prepared_fire_range)
	if ["quick_slash", "fireball"].has(skill_id) and prepared_target == null:
		root._log("사거리 안에 공격할 대상이 없습니다.")
		return false
	GameState.mana -= cost
	SignalBus.resources_changed.emit()
	match skill_id:
		"slime_shield":
			var shield_duration = 5.0 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "duration_bonus", 0.0)
			var shield_reduction = 0.4 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "reduction_bonus", 0.0)
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
			var slash_target = prepared_target
			var slash_multiplier = 1.9 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "damage_multiplier_bonus", 0.0)
			var damage = DamageService.compute(root.selected_unit, slash_target, slash_multiplier)
			var hp_before = int(slash_target.hp)
			var dealt_damage = slash_target.receive_damage(damage)
			_record_damage_contribution(root.selected_unit, slash_target, damage, dealt_damage, hp_before)
			slash_target.mark_threat(root.selected_unit)
			_mark_action_target(root.selected_unit, slash_target)
			root.selected_unit.play_attack(slash_target.global_position)
			_play_attack_sfx(root.selected_unit)
			_apply_combat_hit_feedback(root.selected_unit, slash_target, dealt_damage, true, MELEE_CONTACT_DELAY)
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "날붙이 베기", slash_target.display_name)
			spawn_slash(slash_target.global_position, MELEE_CONTACT_DELAY)
			root._log("고블린이 날붙이 베기로 %d 피해." % damage)
		"loot_instinct":
			root.selected_unit.loot_bonus_active = true
			root.selected_unit.play_skill()
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "약탈 본능", "승리 보상")
			spawn_effect_burst("loot", root.selected_unit.global_position, Vector2(0, -22), Vector2(1.05, 0.95), 13.0)
			root._log("고블린의 약탈 본능이 보상 금화를 올립니다.")
		"fireball":
			var fire_target = prepared_target
			var fire_damage = 52 + int(_combat_skill_float(root.selected_unit.unit_id, skill_id, "damage_bonus", 0.0))
			_mark_action_target(root.selected_unit, fire_target)
			root.selected_unit.play_attack(fire_target.global_position)
			_play_attack_sfx(root.selected_unit)
			root.selected_unit.set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "화염구", fire_target.display_name)
			_launch_damage_projectile(root.selected_unit, fire_target, fire_damage, true, "fireball")
			root._log("임프가 화염구를 발사했습니다.")
		"flame_zone":
			_play_sfx(SFX_FIRE_BURST, "fire", -10.0, 0.12, 0.92, 1.02)
			var affected = 0
			var barracks_room = _barracks_room()
			var flame_damage = 34 + int(_combat_skill_float(root.selected_unit.unit_id, skill_id, "damage_bonus", 0.0))
			var slow_seconds = 2.5 + _combat_skill_float(root.selected_unit.unit_id, skill_id, "slow_seconds_bonus", 0.0)
			var slow_factor = max(0.4, 0.7 - _combat_skill_float(root.selected_unit.unit_id, skill_id, "slow_factor_bonus", 0.0))
			for enemy in root.enemy_units:
				if enemy.is_alive() and ["spike_corridor", barracks_room].has(enemy.current_room):
					var hp_before = int(enemy.hp)
					var dealt_damage = enemy.receive_damage(flame_damage)
					_record_damage_contribution(root.selected_unit, enemy, flame_damage, dealt_damage, hp_before)
					enemy.mark_threat(root.selected_unit)
					enemy.apply_slow(slow_seconds, slow_factor)
					_apply_combat_hit_feedback(root.selected_unit, enemy, dealt_damage, affected == 0)
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
	return true

func _combat_skill_float(monster_id: String, skill_id: String, key: String, fallback: float = 0.0) -> float:
	if root.has_method("_combat_skill_float"):
		return root._combat_skill_float(monster_id, skill_id, key, fallback)
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

func spawn_projectile(from_position: Vector2, to_position: Vector2, on_arrival: Callable = Callable()) -> void:
	var sprite = _make_effect_sprite("fireball", true, 14.0)
	if sprite == null:
		if on_arrival.is_valid():
			on_arrival.call()
		return
	sprite.global_position = from_position
	sprite.z_index = 3000
	sprite.rotation = from_position.angle_to_point(to_position)
	root.effect_root.add_child(sprite)
	var tween = root.create_tween()
	tween.tween_property(sprite, "global_position", to_position, PROJECTILE_TRAVEL_SECONDS)
	if on_arrival.is_valid():
		tween.tween_callback(on_arrival)
	tween.tween_callback(Callable(self, "spawn_impact").bind(to_position))
	tween.tween_callback(sprite.queue_free)

func _launch_damage_projectile(attacker: Node, target: Node, damage: int, force_camera_kick: bool, hit_kind: String) -> void:
	if attacker == null or target == null or not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	_mark_action_target(attacker, target)
	var arrival = Callable(self, "_resolve_projectile_damage").bind(
		attacker.get_instance_id(),
		target.get_instance_id(),
		attacker.global_position,
		str(attacker.unit_id),
		str(attacker.display_name),
		damage,
		force_camera_kick,
		hit_kind
	)
	spawn_projectile(attacker.global_position, target.global_position, arrival)

func _resolve_projectile_damage(attacker_instance_id: int, target_instance_id: int, source_position: Vector2, attacker_unit_id: String, attacker_name: String, damage: int, force_camera_kick: bool, hit_kind: String) -> void:
	var target = instance_from_id(target_instance_id)
	if target == null or not is_instance_valid(target) or not target.is_alive():
		return
	var attacker = instance_from_id(attacker_instance_id)
	var hp_before = int(target.hp)
	var dealt_damage = target.receive_damage(damage)
	_record_damage_contribution(attacker, target, damage, dealt_damage, hp_before, attacker_unit_id)
	if attacker != null and is_instance_valid(attacker) and target.has_method("mark_threat"):
		target.mark_threat(attacker)
	if root.has_method("_onboarding_unit_damaged"):
		root._onboarding_unit_damaged(target)
	_show_combat_hit_feedback(source_position, attacker_unit_id, target, dealt_damage, force_camera_kick)
	if hit_kind == "fireball":
		root._log("화염구가 %s에게 %d 피해." % [target.display_name, dealt_damage])
	else:
		root._log("%s가 %s에게 %d 피해." % [attacker_name, target.display_name, dealt_damage])

func spawn_slash(position: Vector2, delay: float = 0.0) -> void:
	if delay > 0.0:
		var delayed_tween = root.create_tween()
		delayed_tween.tween_interval(delay)
		delayed_tween.tween_callback(Callable(self, "spawn_slash").bind(position, 0.0))
		return
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

func _apply_combat_hit_feedback(attacker: Node, target: Node, damage: int, force_camera_kick: bool = false, feedback_delay: float = MELEE_CONTACT_DELAY) -> void:
	if damage <= 0 or target == null or not is_instance_valid(target):
		return
	var source_position: Vector2 = attacker.global_position
	var attacker_id = str(attacker.unit_id)
	if feedback_delay > 0.0:
		var delayed_tween = root.create_tween()
		delayed_tween.tween_interval(feedback_delay)
		delayed_tween.tween_callback(Callable(self, "_show_combat_hit_feedback").bind(source_position, attacker_id, target, damage, force_camera_kick))
		return
	_show_combat_hit_feedback(source_position, attacker_id, target, damage, force_camera_kick)

func _show_combat_hit_feedback(source_position: Vector2, attacker_id: String, target, damage: int, force_camera_kick: bool) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("play_hit"):
		target.play_hit(source_position)
	spawn_damage_number(target.global_position, damage, target.faction)
	if not target.is_alive():
		_play_sfx(SFX_DOWN, "down", -7.0, 0.09, 0.94, 1.03)
	elif attacker_id == "slime":
		_play_sfx(SFX_SHIELD_BASH, "shield_bash", -8.5, 0.07, 0.94, 1.04)
	else:
		_play_sfx(SFX_HIT, "hit", -11.0, 0.045, 0.94, 1.07)
	if force_camera_kick or damage >= 30 or not target.is_alive():
		camera_kick(1.8 + min(3.2, float(damage) * 0.05))

func _play_attack_sfx(attacker: Node) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	if attacker.faction == Constants.FACTION_MONSTER and attacker.unit_id == "slime":
		return
	if attacker.faction == Constants.FACTION_MONSTER and attacker.unit_id == "imp":
		_play_sfx(SFX_FIRE_BURST, "fire", -10.5, 0.08, 0.94, 1.04)
		return
	_play_sfx_delayed(SFX_SLASH, "slash", 0.055, -10.0, 0.055, 0.94, 1.07)

func _play_sfx_delayed(stream: AudioStream, key: String, delay: float, volume_db: float, min_interval: float, pitch_min: float, pitch_max: float) -> void:
	if delay <= 0.0:
		_play_sfx(stream, key, volume_db, min_interval, pitch_min, pitch_max)
		return
	var tween = root.create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(Callable(self, "_play_sfx").bind(stream, key, volume_db, min_interval, pitch_min, pitch_max))

func _play_sfx(stream: AudioStream, key: String, volume_db: float, min_interval: float, pitch_min: float = 1.0, pitch_max: float = 1.0) -> void:
	if stream == null or root == null or root.effect_root == null:
		return
	if float(sfx_cooldowns.get(key, 0.0)) > 0.0:
		return
	sfx_cooldowns[key] = min_interval
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = AudioSettings.SFX_BUS
	player.volume_db = volume_db
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	root.effect_root.add_child(player)
	player.finished.connect(Callable(player, "queue_free"))
	player.play()

func _update_sfx_cooldowns(delta: float) -> void:
	for key in sfx_cooldowns.keys():
		var remaining = max(0.0, float(sfx_cooldowns[key]) - delta)
		if remaining <= 0.0:
			sfx_cooldowns.erase(key)
		else:
			sfx_cooldowns[key] = remaining

func spawn_damage_number(position: Vector2, damage: int, target_faction: String) -> void:
	var damage_label = Label.new()
	var lane := _next_damage_number_lane(position)
	damage_label.text = "-%d" % damage
	var label_size = Vector2(66, 32)
	damage_label.position = position + Vector2(-label_size.x * 0.5, -112.0 - min(12.0, float(damage) * 0.12)) + DAMAGE_NUMBER_LANE_OFFSETS[lane]
	damage_label.size = label_size
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.add_theme_font_override("font", UI_FONT)
	damage_label.add_theme_font_size_override("font_size", _damage_number_font_size(damage))
	var damage_color = Color("#ff8f84") if target_faction == Constants.FACTION_MONSTER else Color("#ffe078")
	if damage >= 40:
		damage_color = Color("#ffd2cb") if target_faction == Constants.FACTION_MONSTER else Color("#fff0a8")
	damage_label.add_theme_color_override("font_color", damage_color)
	damage_label.add_theme_color_override("font_outline_color", Color("#241522"))
	damage_label.add_theme_constant_override("outline_size", 5 if damage >= 40 else 4)
	damage_label.z_index = 3100
	damage_label.scale = Vector2(0.82, 0.82)
	damage_label.set_meta("combat_feedback_kind", "damage")
	damage_label.set_meta("damage_number_lane", lane)
	root.effect_root.add_child(damage_label)
	var tween = root.create_tween().set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 32.0, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(damage_label, "scale", Vector2.ONE * _damage_number_scale(damage), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.52).set_delay(0.15)
	tween.chain().tween_callback(damage_label.queue_free)

func spawn_growth_preparation_feedback(position: Vector2, preparation_name: String) -> void:
	var feedback_label = Label.new()
	feedback_label.text = "집중 준비 · %s" % preparation_name
	feedback_label.position = position + Vector2(-100, -126)
	feedback_label.size = Vector2(200, 30)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_override("font", UI_FONT)
	feedback_label.add_theme_font_size_override("font_size", 15)
	feedback_label.add_theme_color_override("font_color", Color("#ffe08a"))
	feedback_label.add_theme_color_override("font_outline_color", Color("#241522"))
	feedback_label.add_theme_constant_override("outline_size", 5)
	feedback_label.z_index = 3200
	feedback_label.scale = Vector2(0.82, 0.82)
	feedback_label.set_meta("combat_feedback_kind", "growth_preparation")
	root.effect_root.add_child(feedback_label)
	var tween = root.create_tween().set_parallel(true)
	tween.tween_property(feedback_label, "position:y", feedback_label.position.y - 24.0, 1.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.55).set_delay(0.80)
	tween.chain().tween_callback(feedback_label.queue_free)

func _next_damage_number_lane(position: Vector2) -> int:
	var key := "%d:%d" % [roundi(position.x / 48.0), roundi(position.y / 48.0)]
	var now := Time.get_ticks_msec()
	var row: Dictionary = damage_number_lanes.get(key, {})
	var lane := 0
	if not row.is_empty() and now - int(row.get("last_msec", 0)) <= DAMAGE_NUMBER_LANE_WINDOW_MSEC:
		lane = (int(row.get("lane", 0)) + 1) % DAMAGE_NUMBER_LANE_OFFSETS.size()
	damage_number_lanes[key] = {"lane": lane, "last_msec": now}
	return lane

func _damage_number_font_size(damage: int) -> int:
	return 16 + min(8, int(floor(float(max(0, damage)) / 12.0)))

func _damage_number_scale(damage: int) -> float:
	if damage >= 55:
		return 1.18
	if damage >= 30:
		return 1.08
	return 1.0

func camera_kick(amount: float) -> void:
	if root.combat_camera == null or not root.combat_camera.enabled:
		return
	if camera_kick_cooldown > 0.0:
		return
	camera_kick_cooldown = 0.10
	root.combat_camera.offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
	var tween = root.create_tween()
	tween.tween_property(root.combat_camera, "offset", Vector2.ZERO, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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
