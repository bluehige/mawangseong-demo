extends CharacterBody2D
class_name UnitActor

const Constants = preload("res://scripts/core/Constants.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")

const UNIT_COLLISION_RADIUS = 11.0
const UNIT_AVOIDANCE_RADIUS = 38.0
const UNIT_AVOIDANCE_WEIGHT = 0.78
const MONSTER_COLLISION_LAYER = 1
const ENEMY_COLLISION_LAYER = 2
const GROUNDED_VISUAL_SCALE = 0.42
const FLYING_VISUAL_SCALE = 0.44
const GROUNDED_SPRITE_Y = -37.0
const FLYING_SPRITE_Y = -44.0

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

var sprite_path: String = ""
var sprite: AnimatedSprite2D
var name_label: Label

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
		var texture = _load_png(sprite_path)
		if texture != null:
			_setup_animation_frames(sprite_path, texture)
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
	state_age += delta
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
		var speed = move_speed * slow_factor
		var delta_position = destination - global_position
		if delta_position.length() <= 6.0:
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
	if not path_points.is_empty() and path_points[0].distance_to(global_position) < 8.0:
		path_points.pop_front()

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

func activate_shield(seconds: float, reduction: float) -> void:
	shield_timer = max(shield_timer, seconds)
	damage_reduction = max(damage_reduction, reduction)
	set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "점액 방패")
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

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func skill_ready(skill_id: String) -> bool:
	return float(skill_cooldowns.get(skill_id, 0.0)) <= 0.0

func set_skill_cooldown(skill_id: String, seconds: float) -> void:
	skill_cooldowns[skill_id] = seconds

func play_attack() -> void:
	attack_anim_timer = 0.22
	_play_animation("attack_down")

func play_skill() -> void:
	skill_anim_timer = 0.42
	_play_animation("skill_down")

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

func _next_destination() -> Vector2:
	if avoidance_detour_timer > 0.0 and avoidance_detour_point != Vector2.ZERO:
		return avoidance_detour_point
	if direct_control:
		if command_target != null and is_instance_valid(command_target) and command_target.is_alive():
			if global_position.distance_to(command_target.global_position) > max(12.0, attack_range * 0.82):
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
		var side = Vector2(-desired_direction.y, desired_direction.x)
		var separation = global_position - other.global_position
		if side.dot(separation) < 0.0:
			side = -side
		avoidance_detour_point = _clamp_to_dungeon_point(other.global_position + side.normalized() * 82.0 + desired_direction * 36.0)
		avoidance_detour_timer = 1.6
		return

func _draw() -> void:
	if selected:
		draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 64, Color(0.74, 0.33, 1.0, 0.95), 2.5)
	if shield_timer > 0.0:
		draw_arc(Vector2.ZERO, 31.0, 0.0, TAU, 64, Color(0.25, 0.7, 1.0, 0.7), 2.5)

	var bar_width = 44.0
	var ratio = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_width * 0.5, -68.0), Vector2(bar_width, 6.0)), Color(0.05, 0.05, 0.05, 0.9))
	var hp_color = Color(0.15, 0.75, 0.18) if faction == "monster" else Color(0.9, 0.16, 0.18)
	draw_rect(Rect2(Vector2(-bar_width * 0.5, -68.0), Vector2(bar_width * ratio, 6.0)), hp_color)

func _ensure_visuals() -> void:
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.position = Vector2(0, GROUNDED_SPRITE_Y)
		sprite.scale = Vector2(GROUNDED_VISUAL_SCALE, GROUNDED_VISUAL_SCALE)
		add_child(sprite)
	if name_label == null:
		name_label = Label.new()
		name_label.position = Vector2(-54, -96)
		name_label.size = Vector2(108, 26)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font", UI_FONT)
		name_label.add_theme_font_size_override("font_size", 14)
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

func _load_png(path: String) -> Texture2D:
	var texture = ResourceLoader.load(path)
	if texture is Texture2D:
		return texture
	push_warning("Could not load texture: %s" % path)
	return null

func _setup_animation_frames(path: String, fallback_texture: Texture2D) -> void:
	var frames = SpriteFrames.new()
	var base_path = path.replace("_idle_down_00.png", "")
	for animation_name in ["idle_down", "move_down", "attack_down", "skill_down", "down"]:
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, animation_name in ["idle_down", "move_down"])
		frames.set_animation_speed(animation_name, 7.0)
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
	sprite.sprite_frames = frames

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
	if _is_flying_unit() and velocity.length() > 1.0:
		base_y += sin(Time.get_ticks_msec() / 100.0) * 2.0
	sprite.position = Vector2(0, base_y)
	sprite.scale = Vector2(base_scale, base_scale)

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

func _play_animation(animation_name: String) -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation_name):
		return
	if sprite.animation != animation_name:
		sprite.play(animation_name)

