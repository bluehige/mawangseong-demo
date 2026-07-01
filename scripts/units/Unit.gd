extends CharacterBody2D
class_name UnitActor

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
var selected: bool = false
var down: bool = false
var slow_timer: float = 0.0
var slow_factor: float = 1.0
var shield_timer: float = 0.0
var damage_reduction: float = 0.0

var sprite_path: String = ""
var sprite: Sprite2D
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
		sprite.texture = _load_png(sprite_path)
	sprite.scale = Vector2.ONE
	name_label.text = display_name
	_update_label_color()
	queue_redraw()

func _ready() -> void:
	_ensure_visuals()
	add_to_group("units")

func _physics_process(delta: float) -> void:
	if down:
		velocity = Vector2.ZERO
		return

	attack_cooldown = max(0.0, attack_cooldown - delta)
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

	var destination = _next_destination()
	if destination != Vector2.ZERO:
		var speed = move_speed * slow_factor
		var delta_position = destination - global_position
		if delta_position.length() <= 6.0:
			if direct_control and command_point != Vector2.ZERO:
				command_point = Vector2.ZERO
			elif not path_points.is_empty():
				path_points.pop_front()
			velocity = Vector2.ZERO
		else:
			velocity = delta_position.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	z_index = int(global_position.y)
	queue_redraw()

func set_path(points: Array) -> void:
	path_points = points.duplicate()
	if not path_points.is_empty() and path_points[0].distance_to(global_position) < 8.0:
		path_points.pop_front()

func command_move(point: Vector2) -> void:
	direct_control = true
	command_point = point
	path_points.clear()

func release_direct_control() -> void:
	direct_control = false
	command_point = Vector2.ZERO

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
		path_points.clear()
		modulate = Color(0.35, 0.35, 0.38, 0.85)
		name_label.text = "%s DOWN" % display_name
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
	queue_redraw()

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func skill_ready(skill_id: String) -> bool:
	return float(skill_cooldowns.get(skill_id, 0.0)) <= 0.0

func set_skill_cooldown(skill_id: String, seconds: float) -> void:
	skill_cooldowns[skill_id] = seconds

func _next_destination() -> Vector2:
	if direct_control and command_point != Vector2.ZERO:
		return command_point
	if not path_points.is_empty():
		return path_points[0]
	return Vector2.ZERO

func _draw() -> void:
	if selected:
		draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 64, Color(0.74, 0.33, 1.0, 0.95), 3.0)
	if shield_timer > 0.0:
		draw_arc(Vector2.ZERO, 50.0, 0.0, TAU, 64, Color(0.25, 0.7, 1.0, 0.7), 3.0)

	var bar_width = 70.0
	var ratio = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_width * 0.5, -62.0), Vector2(bar_width, 8.0)), Color(0.05, 0.05, 0.05, 0.9))
	var hp_color = Color(0.15, 0.75, 0.18) if faction == "monster" else Color(0.9, 0.16, 0.18)
	draw_rect(Rect2(Vector2(-bar_width * 0.5, -62.0), Vector2(bar_width * ratio, 8.0)), hp_color)

func _ensure_visuals() -> void:
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.centered = true
		sprite.position = Vector2(0, -20)
		sprite.scale = Vector2(0.82, 0.82)
		add_child(sprite)
	if name_label == null:
		name_label = Label.new()
		name_label.position = Vector2(-54, -92)
		name_label.size = Vector2(108, 26)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 17)
		add_child(name_label)
	if get_node_or_null("CollisionShape2D") == null:
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 36.0
		shape.shape = circle
		add_child(shape)

func _update_label_color() -> void:
	if name_label == null:
		return
	if faction == "monster":
		name_label.add_theme_color_override("font_color", Color(0.75, 0.95, 0.75))
	else:
		name_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.72))

func _load_png(path: String) -> Texture2D:
	var image = Image.new()
	var err = image.load(path)
	if err != OK:
		push_warning("Could not load image: %s" % path)
		return null
	return ImageTexture.create_from_image(image)

