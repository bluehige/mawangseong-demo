extends CharacterBody2D
class_name UnitActor

const Constants = preload("res://scripts/core/Constants.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")

const UNIT_COLLISION_RADIUS = 11.0
const UNIT_AVOIDANCE_RADIUS = 38.0
const UNIT_AVOIDANCE_WEIGHT = 0.78
const UNIT_DETOUR_SIDE_OFFSET = 86.0
const UNIT_DETOUR_FORWARD_OFFSET = 62.0
const UNIT_DETOUR_CLEARANCE = 24.0
const PATH_POINT_REACHED_RADIUS = 12.0
const MONSTER_COLLISION_LAYER = 1
const ENEMY_COLLISION_LAYER = 2
const GROUNDED_VISUAL_SCALE = 0.36
const FLYING_VISUAL_SCALE = 0.38
const GROUNDED_SPRITE_Y = -37.0
const FLYING_SPRITE_Y = -44.0
const ATTACK_ANIM_DURATION = 0.42
const SKILL_ANIM_DURATION = 0.56
const HIT_REACTION_DURATION = 0.18
const ATTACK_LUNGE_DISTANCE = 11.0
const HIT_RECOIL_DISTANCE = 9.0
const ACTION_FOCUS_DURATION = 0.52
const HIT_FOCUS_DURATION = 0.36
const GROWTH_PREPARATION_INTRO_DURATION = 2.4

signal hp_changed(unit: UnitActor)
signal downed(unit: UnitActor)

var unit_id: String = ""
var display_name: String = ""
var faction: String = ""
var role: String = ""
var current_room: String = ""
var assigned_room: String = ""
var goal_room: String = ""

var max_hp: int = 1
var hp: int = 1
var atk: int = 1
var def: int = 0
var move_speed: float = 100.0
var attack_range: float = 48.0
var attack_interval: float = 1.0
var morale: int = 0
var exp_reward: int = 0
var infamy_reward: int = 0

var level: int = 1
var exp: int = 0
var target: UnitActor = null
var attack_cooldown: float = 0.0
var skill_cooldowns: Dictionary = {}
var path_points: Array = []
var direct_control: bool = false
var command_point: Vector2 = Vector2.ZERO
var command_target: UnitActor = null
var selected: bool = false
var down: bool = false
var tactical_state: String = Constants.UNIT_STATE_IDLE
var intent_text: String = "대기"
var target_text: String = ""
var state_age: float = 0.0
var attack_anim_timer: float = 0.0
var skill_anim_timer: float = 0.0
var hit_anim_timer: float = 0.0
var target_focus_timer: float = 0.0
var hit_focus_timer: float = 0.0
var visual_phase: float = 0.0
var action_direction: Vector2 = Vector2.RIGHT
var hit_direction: Vector2 = Vector2.ZERO
var slow_timer: float = 0.0
var slow_factor: float = 1.0
var shield_timer: float = 0.0
var damage_reduction: float = 0.0
var guard_timer: float = 0.0
var guard_bonus: int = 0
var threat_unit: UnitActor = null
var threat_timer: float = 0.0
var loot_bonus_active: bool = false
var avoidance_detour_point: Vector2 = Vector2.ZERO
var avoidance_detour_timer: float = 0.0
var growth_preparation_name: String = ""
var growth_preparation_summary: String = ""
var growth_preparation_intro_timer: float = 0.0
var skill_preview_active: bool = false
var skill_preview_range: float = 0.0
var skill_preview_targets: Array = []
var skill_preview_label: String = ""
var royal_rally_move_multiplier: float = 1.0
var royal_rally_attack_interval_multiplier: float = 1.0

var sprite_path: String = ""
var sprite: AnimatedSprite2D
var name_label: Label
static var _animation_frames_cache: Dictionary = {}

func setup(source_id: String, stats: Dictionary, unit_faction: String, room_id: String) -> void:
	_ensure_visuals()
	unit_id = source_id
	display_name = stats.get("display_name", source_id)
	faction = unit_faction
	role = stats.get("role", stats.get("goal_type", ""))
	current_room = room_id
	assigned_room = room_id
	goal_room = room_id
	_configure_collision_shape()
	max_hp = int(stats.get("max_hp", 100))
	hp = max_hp
	atk = int(stats.get("atk", 10))
	def = int(stats.get("def", 0))
	move_speed = float(stats.get("move_speed", 100))
	attack_range = float(stats.get("attack_range", 48))
	attack_interval = float(stats.get("attack_interval", 1.0))
	morale = int(stats.get("morale", stats.get("loyalty", 0)))
	exp_reward = int(stats.get("exp", 0))
	infamy_reward = int(stats.get("infamy", 0))
	sprite_path = stats.get("sprite", "")
	if sprite_path != "":
		var frames := warm_animation_frames(sprite_path)
		if frames != null:
			sprite.sprite_frames = frames
	_apply_visual_pose()
	name_label.text = display_name
	_update_label_color()
	set_tactical_state(Constants.UNIT_STATE_IDLE, "대기")
	_play_animation("idle_down")
	queue_redraw()

func _ready() -> void:
	_ensure_visuals()
	add_to_group("units")

func _physics_process(delta: float) -> void:
	if down:
		velocity = Vector2.ZERO
		return

	attack_cooldown = max(0.0, attack_cooldown - delta)
	attack_anim_timer = max(0.0, attack_anim_timer - delta)
	skill_anim_timer = max(0.0, skill_anim_timer - delta)
	hit_anim_timer = max(0.0, hit_anim_timer - delta)
	target_focus_timer = max(0.0, target_focus_timer - delta)
	hit_focus_timer = max(0.0, hit_focus_timer - delta)
	growth_preparation_intro_timer = max(0.0, growth_preparation_intro_timer - delta)
	visual_phase = fmod(visual_phase + delta, TAU * 100.0)
	state_age += delta
	if target != null and (not is_instance_valid(target) or not target.is_alive()):
		target = null
		target_focus_timer = 0.0
	for key in skill_cooldowns.keys():
		skill_cooldowns[key] = max(0.0, float(skill_cooldowns[key]) - delta)
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_factor = 1.0
	if shield_timer > 0.0:
		shield_timer -= delta
		if shield_timer <= 0.0:
			damage_reduction = 0.0
	if guard_timer > 0.0:
		guard_timer -= delta
		if guard_timer <= 0.0:
			guard_bonus = 0
	if threat_timer > 0.0:
		threat_timer -= delta
		if threat_timer <= 0.0:
			threat_unit = null
	if avoidance_detour_timer > 0.0:
		avoidance_detour_timer -= delta
		if avoidance_detour_timer <= 0.0:
			avoidance_detour_point = Vector2.ZERO
	if direct_control and command_target != null and (not is_instance_valid(command_target) or not command_target.is_alive()):
		command_target = null

	var destination = _next_destination()
	if destination != Vector2.ZERO:
		var speed = move_speed * slow_factor * royal_rally_move_multiplier
		var delta_position = destination - global_position
		if delta_position.length() <= PATH_POINT_REACHED_RADIUS:
			if avoidance_detour_timer > 0.0 and avoidance_detour_point != Vector2.ZERO:
				avoidance_detour_point = Vector2.ZERO
				avoidance_detour_timer = 0.0
			elif direct_control and command_point != Vector2.ZERO:
				command_point = Vector2.ZERO
			elif not path_points.is_empty():
				path_points.pop_front()
			velocity = Vector2.ZERO
		else:
			velocity = _movement_velocity(delta_position.normalized(), speed)
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_clamp_to_dungeon_floor()
	_update_collision_detour(destination)
	_update_animation()
	z_index = int(global_position.y)
	queue_redraw()

func set_path(points: Array) -> void:
	path_points = points.duplicate()
	if not path_points.is_empty() and path_points[0].distance_to(global_position) < PATH_POINT_REACHED_RADIUS:
		path_points.pop_front()

func stop_navigation(clear_direct_command: bool = false) -> void:
	path_points.clear()
	avoidance_detour_point = Vector2.ZERO
	avoidance_detour_timer = 0.0
	velocity = Vector2.ZERO
	if clear_direct_command:
		command_point = Vector2.ZERO

func command_move(point: Vector2) -> void:
	direct_control = true
	command_point = point
	command_target = null
	path_points.clear()
	set_tactical_state(Constants.UNIT_STATE_DIRECT_CONTROL, "직접 이동", "지정 위치")

func command_attack(unit: UnitActor) -> void:
	if unit == null or not unit.is_alive():
		return
	direct_control = true
	command_target = unit
	command_point = Vector2.ZERO
	path_points.clear()
	set_tactical_state(Constants.UNIT_STATE_DIRECT_CONTROL, "직접 공격", unit.display_name)

func begin_direct_control() -> void:
	direct_control = true
	command_point = Vector2.ZERO
	command_target = null
	path_points.clear()
	avoidance_detour_point = Vector2.ZERO
	avoidance_detour_timer = 0.0
	set_tactical_state(Constants.UNIT_STATE_DIRECT_CONTROL, "명령 대기")

func release_direct_control() -> void:
	direct_control = false
	command_point = Vector2.ZERO
	command_target = null
	set_tactical_state(Constants.UNIT_STATE_IDLE, "AI 복귀")

func is_alive() -> bool:
	return not down and hp > 0

func receive_damage(amount: int) -> int:
	if down:
		return 0
	var final_amount = max(1, int(round(float(amount) * (1.0 - damage_reduction))))
	hp = max(0, hp - final_amount)
	hp_changed.emit(self)
	if hp <= 0:
		down = true
		direct_control = false
		command_point = Vector2.ZERO
		command_target = null
		target = null
		target_focus_timer = 0.0
		path_points.clear()
		_set_collision_enabled(false)
		set_tactical_state(Constants.UNIT_STATE_DOWN, "전투 불능")
		modulate = Color(0.35, 0.35, 0.38, 0.85)
		name_label.text = "%s DOWN" % display_name
		_play_animation("down")
		downed.emit(self)
	queue_redraw()
	return final_amount

func heal(amount: int) -> void:
	if down:
		return
	hp = min(max_hp, hp + amount)
	hp_changed.emit(self)
	queue_redraw()

func apply_slow(seconds: float, factor: float) -> void:
	slow_timer = max(slow_timer, seconds)
	slow_factor = min(slow_factor, factor)

func activate_shield(seconds: float, reduction: float, status_label: String = "점액 방패") -> void:
	shield_timer = max(shield_timer, seconds)
	damage_reduction = max(damage_reduction, reduction)
	set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, status_label)
	skill_anim_timer = max(skill_anim_timer, 0.45)
	queue_redraw()

func activate_guard(seconds: float, bonus: int) -> void:
	guard_timer = max(guard_timer, seconds)
	guard_bonus = max(guard_bonus, bonus)
	set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "통로 막기")
	skill_anim_timer = max(skill_anim_timer, 0.45)
	queue_redraw()

func effective_def() -> int:
	return def + guard_bonus

func mark_threat(attacker: UnitActor, seconds: float = 4.0) -> void:
	threat_unit = attacker
	threat_timer = max(threat_timer, seconds)

func mark_action_target(unit: UnitActor, seconds: float = ACTION_FOCUS_DURATION) -> void:
	if unit == null or not is_instance_valid(unit) or not unit.is_alive():
		target = null
		target_focus_timer = 0.0
		queue_redraw()
		return
	target = unit
	target_focus_timer = max(target_focus_timer, seconds)
	queue_redraw()

func set_selected(value: bool) -> void:
	selected = value
	if not selected:
		clear_skill_preview()
	queue_redraw()

func set_skill_preview(range_value: float, preview_targets: Array, preview_label: String) -> void:
	skill_preview_active = true
	skill_preview_range = max(0.0, range_value)
	skill_preview_targets.clear()
	for preview_target in preview_targets:
		if preview_target != null and is_instance_valid(preview_target) and preview_target.is_alive():
			skill_preview_targets.append(preview_target)
	skill_preview_label = preview_label
	queue_redraw()

func clear_skill_preview() -> void:
	skill_preview_active = false
	skill_preview_range = 0.0
	skill_preview_targets.clear()
	skill_preview_label = ""
	queue_redraw()

func skill_ready(skill_id: String) -> bool:
	return float(skill_cooldowns.get(skill_id, 0.0)) <= 0.0

func set_skill_cooldown(skill_id: String, seconds: float) -> void:
	skill_cooldowns[skill_id] = seconds

func play_attack(target_position: Vector2 = Vector2.ZERO) -> void:
	if target_position != Vector2.ZERO:
		var direction = (target_position - global_position).normalized()
		if direction != Vector2.ZERO:
			action_direction = direction
	attack_anim_timer = ATTACK_ANIM_DURATION
	_play_animation("attack_down")

func play_skill(target_position: Vector2 = Vector2.ZERO) -> void:
	if target_position != Vector2.ZERO:
		var direction = (target_position - global_position).normalized()
		if direction != Vector2.ZERO:
			action_direction = direction
	skill_anim_timer = SKILL_ANIM_DURATION
	_play_animation("skill_down", true)

func play_hit(source_position: Vector2) -> void:
	if down:
		return
	var direction = (global_position - source_position).normalized()
	hit_direction = direction if direction != Vector2.ZERO else -action_direction
	hit_anim_timer = HIT_REACTION_DURATION
	hit_focus_timer = HIT_FOCUS_DURATION
	queue_redraw()

func activate_growth_preparation(preparation_name: String, preparation_summary: String) -> void:
	growth_preparation_name = preparation_name
	growth_preparation_summary = preparation_summary
	growth_preparation_intro_timer = GROWTH_PREPARATION_INTRO_DURATION
	queue_redraw()

func has_growth_preparation() -> bool:
	return growth_preparation_name != ""

func set_tactical_state(state: String, intent: String = "", target_name: String = "") -> void:
	if tactical_state != state:
		tactical_state = state
		state_age = 0.0
	if intent != "":
		intent_text = intent
	target_text = target_name

func state_label() -> String:
	match tactical_state:
		Constants.UNIT_STATE_IDLE:
			return "대기"
		Constants.UNIT_STATE_MOVE_TO_ROOM:
			return "이동"
		Constants.UNIT_STATE_SEEK_TARGET:
			return "탐색"
		Constants.UNIT_STATE_MOVE_TO_TARGET:
			return "접근"
		Constants.UNIT_STATE_ATTACK:
			return "공격"
		Constants.UNIT_STATE_CAST_SKILL:
			return "스킬"
		Constants.UNIT_STATE_RETREAT:
			return "후퇴"
		Constants.UNIT_STATE_DIRECT_CONTROL:
			return "직접"
		Constants.UNIT_STATE_STUNNED:
			return "기절"
		Constants.UNIT_STATE_LOOTING:
			return "약탈"
		Constants.UNIT_STATE_DOWN:
			return "불능"
		_:
			return "상태"

func status_line() -> String:
	var target_suffix = ""
	if target_text != "":
		target_suffix = " -> %s" % target_text
	return "%s: %s%s" % [state_label(), intent_text, target_suffix]

func threat_warning_text() -> String:
	if down or faction != Constants.FACTION_ENEMY:
		return ""
	if unit_id == "selen_trainee_paladin" and role == "commander":
		return "진군 지휘"
	if unit_id == "engineer" and role == "facility":
		return "시설 교란"
	if unit_id != "thief" or role != "treasure":
		return ""
	if goal_room == "entrance":
		return ""
	if tactical_state == Constants.UNIT_STATE_LOOTING:
		return "약탈 중"
	return "보물방 침투"

func effective_attack_interval() -> float:
	return attack_interval * royal_rally_attack_interval_multiplier

func _next_destination() -> Vector2:
	if avoidance_detour_timer > 0.0 and avoidance_detour_point != Vector2.ZERO:
		return avoidance_detour_point
	if direct_control:
		if command_target != null and is_instance_valid(command_target) and command_target.is_alive():
			if global_position.distance_to(command_target.global_position) > max(12.0, attack_range * 0.82):
				if not path_points.is_empty():
					return path_points[0]
				return command_target.global_position
			return Vector2.ZERO
		if command_point != Vector2.ZERO:
			return command_point
	if not path_points.is_empty():
		return path_points[0]
	return Vector2.ZERO

func _movement_velocity(desired_direction: Vector2, speed: float) -> Vector2:
	var avoidance = _unit_avoidance(desired_direction)
	var final_direction = desired_direction
	if avoidance != Vector2.ZERO:
		final_direction = (desired_direction + avoidance * UNIT_AVOIDANCE_WEIGHT).normalized()
	if final_direction == Vector2.ZERO:
		final_direction = desired_direction
	return final_direction * speed

func _unit_avoidance(desired_direction: Vector2) -> Vector2:
	var result = Vector2.ZERO
	for other in get_tree().get_nodes_in_group("units"):
		if other == self or not other.has_method("is_alive") or not other.is_alive():
			continue
		var separation = global_position - other.global_position
		var distance = separation.length()
		if distance <= 0.01 or distance >= UNIT_AVOIDANCE_RADIUS:
			continue
		var away = separation / distance
		var strength = (UNIT_AVOIDANCE_RADIUS - distance) / UNIT_AVOIDANCE_RADIUS
		result += away * strength * 0.55
		var closing = desired_direction.dot(-away)
		if closing > 0.2:
			var side = Vector2(-desired_direction.y, desired_direction.x)
			if side.dot(away) < 0.0:
				side = -side
			result += side * strength * closing
	return result

func _update_collision_detour(destination: Vector2) -> void:
	if destination == Vector2.ZERO or velocity.length() <= 1.0:
		return
	var desired_direction = (destination - global_position).normalized()
	if desired_direction == Vector2.ZERO:
		return
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var other = collision.get_collider()
		if other == null or other == self or not other.is_in_group("units"):
			continue
		var side = Vector2(-desired_direction.y, desired_direction.x).normalized()
		var separation = global_position - other.global_position
		var preferred_side = 1.0
		if side.dot(separation) < 0.0:
			preferred_side = -1.0
		var candidates: Array = []
		for side_sign in [preferred_side, -preferred_side]:
			candidates.append(other.global_position + side * side_sign * UNIT_DETOUR_SIDE_OFFSET + desired_direction * UNIT_DETOUR_FORWARD_OFFSET)
			candidates.append(other.global_position + side * side_sign * (UNIT_DETOUR_SIDE_OFFSET * 0.68) + desired_direction * (UNIT_DETOUR_FORWARD_OFFSET * 1.45))
		candidates.append(destination)
		avoidance_detour_point = _best_collision_detour(candidates, other, desired_direction, destination)
		avoidance_detour_timer = 1.6
		return

func _best_collision_detour(candidates: Array, blocker: Node, desired_direction: Vector2, destination: Vector2) -> Vector2:
	var best_point := Vector2.ZERO
	var best_score := -INF
	for raw_candidate in candidates:
		var candidate = _clamp_to_dungeon_point(raw_candidate)
		var clearance = candidate.distance_to(blocker.global_position)
		if clearance < UNIT_DETOUR_CLEARANCE:
			continue
		var travel = candidate - global_position
		if travel.length() < 8.0:
			continue
		var forward_progress = travel.dot(desired_direction)
		var destination_score = -candidate.distance_to(destination) * 0.08
		var clearance_score = min(clearance, 120.0) * 0.22
		var score = forward_progress + destination_score + clearance_score
		if score > best_score:
			best_score = score
			best_point = candidate
	if best_point != Vector2.ZERO:
		return best_point
	return _clamp_to_dungeon_point(destination)

func _draw() -> void:
	if skill_preview_active and selected and not down:
		var preview_color := Color("#ffd36a")
		if skill_preview_range > 0.0:
			draw_circle(Vector2.ZERO, skill_preview_range, Color(preview_color.r, preview_color.g, preview_color.b, 0.035))
			draw_arc(Vector2.ZERO, skill_preview_range, 0.0, TAU, 96, Color(preview_color.r, preview_color.g, preview_color.b, 0.72), 2.0)
		for preview_target in skill_preview_targets:
			if preview_target == null or not is_instance_valid(preview_target) or not preview_target.is_alive():
				continue
			var target_point := to_local(preview_target.global_position)
			var is_self_target: bool = preview_target == self
			var target_color: Color = preview_color if is_self_target else Color("#ff735d")
			draw_circle(target_point, 25.0, Color(target_color.r, target_color.g, target_color.b, 0.10))
			draw_arc(target_point, 29.0, 0.0, TAU, 48, target_color, 3.0)
			if not is_self_target:
				draw_line(Vector2.ZERO, target_point, Color(1.0, 0.76, 0.32, 0.52), 1.5, true)
		if skill_preview_label != "":
			var preview_rect := Rect2(Vector2(-100, -132), Vector2(200, 24))
			draw_rect(preview_rect, Color("#120d16e8"), true)
			draw_rect(preview_rect, Color("#d5a64b"), false, 1.5)
			draw_string(UI_FONT, preview_rect.position + Vector2(0, 17), skill_preview_label, HORIZONTAL_ALIGNMENT_CENTER, preview_rect.size.x, 12, Color("#fff0bd"))
	if has_growth_preparation() and not down:
		var preparation_pulse = (sin(visual_phase * 4.0) + 1.0) * 0.5
		var intro_ratio = clamp(growth_preparation_intro_timer / GROWTH_PREPARATION_INTRO_DURATION, 0.0, 1.0)
		var ring_alpha = 0.34 + preparation_pulse * 0.18 + intro_ratio * 0.28
		var ring_radius = 34.0 + preparation_pulse * 2.0 + intro_ratio * 4.0
		draw_circle(Vector2.ZERO, ring_radius, Color(1.0, 0.76, 0.24, 0.035 + intro_ratio * 0.045))
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 64, Color(1.0, 0.76, 0.24, ring_alpha), 2.5)
		draw_arc(Vector2.ZERO, ring_radius - 4.0, -PI * 0.35, PI * 0.35, 20, Color(1.0, 0.92, 0.58, 0.42 + intro_ratio * 0.30), 1.5)
	var warning_text = threat_warning_text()
	if warning_text != "":
		var looting = tactical_state == Constants.UNIT_STATE_LOOTING
		var warning_color = Color("#ff625f") if looting else Color("#ffb347")
		var pulse = (sin(visual_phase * 5.0) + 1.0) * 0.5
		draw_arc(Vector2.ZERO, 29.0 + pulse * 3.0, 0.0, TAU, 48, Color(warning_color.r, warning_color.g, warning_color.b, 0.72 + pulse * 0.20), 2.5)
		var warning_rect = Rect2(Vector2(-46, -116), Vector2(92, 22))
		draw_rect(warning_rect, Color("#16090bea"), true)
		draw_rect(warning_rect, warning_color, false, 1.5)
		draw_string(UI_FONT, warning_rect.position + Vector2(0, 16), warning_text, HORIZONTAL_ALIGNMENT_CENTER, warning_rect.size.x, 12, Color("#fff4e0"))
	if target_focus_timer > 0.0 and target != null and is_instance_valid(target) and target.is_alive():
		var focus_ratio = clamp(target_focus_timer / ACTION_FOCUS_DURATION, 0.0, 1.0)
		var source_point = Vector2(0, -34)
		var target_point = to_local(target.global_position) + Vector2(0, -34)
		var focus_color = Color(1.0, 0.73, 0.24, 0.48 * focus_ratio) if faction == "monster" else Color(1.0, 0.22, 0.20, 0.42 * focus_ratio)
		draw_line(source_point, target_point, focus_color, 2.0, true)
		draw_circle(target_point, 7.0 + (1.0 - focus_ratio) * 5.0, Color(focus_color.r, focus_color.g, focus_color.b, 0.16 * focus_ratio))
		draw_arc(target_point, 12.0 + (1.0 - focus_ratio) * 5.0, 0.0, TAU, 48, Color(focus_color.r, focus_color.g, focus_color.b, 0.72 * focus_ratio), 2.0)
	if selected:
		draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 64, Color(0.74, 0.33, 1.0, 0.95), 2.5)
	if shield_timer > 0.0:
		draw_arc(Vector2.ZERO, 31.0, 0.0, TAU, 64, Color(0.25, 0.7, 1.0, 0.7), 2.5)
	if hit_focus_timer > 0.0:
		var hit_ratio = clamp(hit_focus_timer / HIT_FOCUS_DURATION, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 27.0 + (1.0 - hit_ratio) * 7.0, 0.0, TAU, 64, Color(1.0, 0.28, 0.22, 0.76 * hit_ratio), 3.0)

	var bar_width = 44.0
	var ratio = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	var hp_rect = Rect2(Vector2(-bar_width * 0.5, -68.0), Vector2(bar_width, 6.0))
	draw_rect(hp_rect, Color(0.05, 0.05, 0.05, 0.9))
	var hp_color = Color(0.15, 0.75, 0.18) if faction == "monster" else Color(0.9, 0.16, 0.18)
	if ratio <= 0.25:
		hp_color = Color(1.0, 0.24, 0.28)
	elif ratio <= 0.50:
		hp_color = Color(1.0, 0.67, 0.20)
	draw_rect(Rect2(hp_rect.position, Vector2(bar_width * ratio, hp_rect.size.y)), hp_color)
	draw_rect(hp_rect, Color(0.0, 0.0, 0.0, 0.72), false, 1.0)

func _ensure_visuals() -> void:
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.position = Vector2(0, GROUNDED_SPRITE_Y)
		sprite.scale = Vector2(GROUNDED_VISUAL_SCALE, GROUNDED_VISUAL_SCALE)
		add_child(sprite)
	if name_label == null:
		name_label = Label.new()
		name_label.position = Vector2(-46, -86)
		name_label.size = Vector2(92, 22)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font", UI_FONT)
		name_label.add_theme_font_size_override("font_size", 12)
		add_child(name_label)
	_configure_collision_shape()

func _configure_collision_shape() -> void:
	var shape = _collision_shape()
	if shape == null:
		shape = CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		add_child(shape)
	var circle = shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
	circle.radius = UNIT_COLLISION_RADIUS
	shape.shape = circle
	shape.disabled = down
	_update_collision_layers(not down)

func _set_collision_enabled(enabled: bool) -> void:
	var shape = _collision_shape()
	if shape != null:
		shape.disabled = not enabled
	_update_collision_layers(enabled)

func _update_collision_layers(enabled: bool) -> void:
	if not enabled:
		collision_layer = 0
		collision_mask = 0
		return
	match faction:
		Constants.FACTION_MONSTER:
			collision_layer = MONSTER_COLLISION_LAYER
			collision_mask = ENEMY_COLLISION_LAYER
		Constants.FACTION_ENEMY:
			collision_layer = ENEMY_COLLISION_LAYER
			collision_mask = MONSTER_COLLISION_LAYER
		_:
			collision_layer = MONSTER_COLLISION_LAYER | ENEMY_COLLISION_LAYER
			collision_mask = MONSTER_COLLISION_LAYER | ENEMY_COLLISION_LAYER

func _collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child
	return null

func _update_label_color() -> void:
	if name_label == null:
		return
	if faction == "monster":
		name_label.add_theme_color_override("font_color", Color(0.75, 0.95, 0.75))
	else:
		name_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.72))

static func _load_png(path: String) -> Texture2D:
	var texture = ResourceLoader.load(path)
	if texture is Texture2D:
		return texture
	push_warning("Could not load texture: %s" % path)
	return null

static func warm_animation_frames(path: String) -> SpriteFrames:
	if path == "":
		return null
	if _animation_frames_cache.has(path):
		return _animation_frames_cache[path]
	var fallback_texture := _load_png(path)
	if fallback_texture == null:
		return null
	var frames := _build_animation_frames(path, fallback_texture)
	_animation_frames_cache[path] = frames
	return frames

static func _build_animation_frames(path: String, fallback_texture: Texture2D) -> SpriteFrames:
	var frames = SpriteFrames.new()
	var base_path = path.replace("_idle_down_00.png", "")
	for animation_name in ["idle_down", "move_down", "attack_down", "skill_down", "down"]:
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, animation_name in ["idle_down", "move_down"])
		var animation_speed = 5.0
		match animation_name:
			"move_down":
				animation_speed = 10.0
			"attack_down":
				animation_speed = 10.0
			"skill_down":
				animation_speed = 8.0
			"down":
				animation_speed = 7.0
		frames.set_animation_speed(animation_name, animation_speed)
		var added = false
		for index in range(8):
			var frame_path = "%s_%s_%02d.png" % [base_path, animation_name, index]
			if ResourceLoader.exists(frame_path):
				var frame_texture = _load_png(frame_path)
				if frame_texture != null:
					frames.add_frame(animation_name, frame_texture)
					added = true
		if not added:
			frames.add_frame(animation_name, fallback_texture)
	return frames

func _update_animation() -> void:
	if down:
		_play_animation("down")
	elif skill_anim_timer > 0.0:
		_play_animation("skill_down")
	elif attack_anim_timer > 0.0:
		_play_animation("attack_down")
	elif velocity.length() > 1.0:
		_play_animation("move_down")
	else:
		_play_animation("idle_down")
	_apply_visual_pose()

func _apply_visual_pose() -> void:
	var base_scale = FLYING_VISUAL_SCALE if _is_flying_unit() else GROUNDED_VISUAL_SCALE
	var base_y = FLYING_SPRITE_Y if _is_flying_unit() else GROUNDED_SPRITE_Y
	var pose_position = Vector2(0, base_y)
	var pose_scale = Vector2(base_scale, base_scale)
	var pose_rotation := 0.0
	if velocity.length() > 1.0:
		var move_wave = visual_phase * 10.0
		var move_strength = 1.25 if unit_id == "slime" else 1.0
		pose_position.y -= abs(sin(move_wave)) * (4.0 if _is_flying_unit() else 3.2) * move_strength
		pose_scale.x *= 1.0 + sin(move_wave) * 0.06 * move_strength
		pose_scale.y *= 1.0 - sin(move_wave) * 0.075 * move_strength
		pose_rotation = sin(move_wave) * 0.04
		if abs(velocity.x) > 2.0:
			sprite.flip_h = velocity.x < 0.0
	elif _is_flying_unit():
		pose_position.y += sin(visual_phase * 4.0) * 3.0
	else:
		pose_position.y += sin(visual_phase * 2.5) * 0.8
	if attack_anim_timer > 0.0:
		var attack_progress = clamp(1.0 - attack_anim_timer / ATTACK_ANIM_DURATION, 0.0, 1.0)
		var attack_offset := 0.0
		var attack_strength := 0.0
		if attack_progress < 0.24:
			var anticipation = smoothstep(0.0, 0.24, attack_progress)
			attack_offset = -3.5 * anticipation
			pose_scale.x *= 1.0 - anticipation * 0.06
			pose_scale.y *= 1.0 + anticipation * 0.09
			pose_rotation -= action_direction.x * anticipation * 0.05
		elif attack_progress < 0.52:
			attack_strength = smoothstep(0.24, 0.52, attack_progress)
			attack_offset = lerp(-3.5, ATTACK_LUNGE_DISTANCE, attack_strength)
			pose_scale.x *= 1.0 + attack_strength * 0.15
			pose_scale.y *= 1.0 - attack_strength * 0.09
			pose_rotation += action_direction.x * attack_strength * 0.10
		else:
			attack_strength = 1.0 - smoothstep(0.52, 1.0, attack_progress)
			attack_offset = ATTACK_LUNGE_DISTANCE * attack_strength
			pose_scale.x *= 1.0 + attack_strength * 0.08
			pose_scale.y *= 1.0 - attack_strength * 0.05
			pose_rotation += action_direction.x * attack_strength * 0.05
		pose_position += action_direction * attack_offset
		if abs(action_direction.x) > 0.05:
			sprite.flip_h = action_direction.x < 0.0
	elif skill_anim_timer > 0.0:
		var skill_progress = 1.0 - skill_anim_timer / SKILL_ANIM_DURATION
		var skill_pulse = sin(clamp(skill_progress, 0.0, 1.0) * PI)
		pose_position.y -= skill_pulse * 4.0
		pose_scale *= 1.0 + skill_pulse * 0.08
	if hit_anim_timer > 0.0:
		var hit_strength = hit_anim_timer / HIT_REACTION_DURATION
		pose_position += hit_direction * HIT_RECOIL_DISTANCE * hit_strength
		pose_scale.x *= 1.0 + hit_strength * 0.08
		pose_scale.y *= 1.0 - hit_strength * 0.08
		sprite.modulate = Color(1.45, 1.15, 1.15, 1.0)
	else:
		sprite.modulate = Color.WHITE
	sprite.position = pose_position
	sprite.scale = pose_scale
	sprite.rotation = pose_rotation

func _is_flying_unit() -> bool:
	return unit_id == "imp"

func _clamp_to_dungeon_floor() -> void:
	global_position = _clamp_to_dungeon_point(global_position)

func _clamp_to_dungeon_point(point: Vector2) -> Vector2:
	var game_root = _game_root()
	if game_root != null and game_root.has_method("_clamp_to_combat_walkable"):
		return game_root._clamp_to_combat_walkable(point)
	return point

func _game_root() -> Node:
	var node = get_parent()
	while node != null:
		if node.has_method("_clamp_to_combat_walkable"):
			return node
		node = node.get_parent()
	return null

func _play_animation(animation_name: String, restart: bool = false) -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation_name):
		return
	if sprite.animation != animation_name or restart:
		sprite.play(animation_name)
		if restart:
			sprite.frame = 0
			sprite.frame_progress = 0.0

