extends CharacterBody2D
class_name UnitActor

const Constants = preload("res://scripts/core/Constants.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")

const PATH_POINT_REACHED_RADIUS = 12.0
const NAVIGATION_STALL_TIMEOUT = 0.75
const NAVIGATION_PROGRESS_EPSILON = 0.05
const GROUNDED_VISUAL_SCALE = 0.42
const FLYING_VISUAL_SCALE = 0.44
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
const SOFT_COUNTER_MAX_STRENGTH = 0.35

signal hp_changed(unit: UnitActor)
signal downed(unit: UnitActor)
signal effective_healed(unit: UnitActor, amount: int, event_token: String)
signal first_heart_control_applied(unit: UnitActor)

var unit_id: String = ""
var display_name: String = ""
var faction: String = ""
var role: String = ""
var simulation_speed := 1.0
var current_room: String = ""
var assigned_room: String = ""
var goal_room: String = ""
var v20_home_zone: String = ""
var v20_monster_slot_id: String = ""
var v20_actor_id: String = ""
var v20_last_evidence_cell := Vector2i(-99999, -99999)
var v20_last_evidence_zone: String = ""

var max_hp: int = 1
var hp: int = 1
var atk: int = 1
var def: int = 0
var heart_def_bonus: int = 0
var heart_move_multiplier: float = 1.0
var heart_healing_multiplier: float = 1.0
var heart_skill_recovery_multiplier: float = 1.0
var heart_first_control_multiplier: float = 1.0
var heart_first_control_available: bool = false
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
var navigation_stall_time := 0.0
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
var threat_forced: bool = false
var loot_bonus_active: bool = false
var escaped: bool = false
var growth_preparation_name: String = ""
var growth_preparation_summary: String = ""
var growth_preparation_intro_timer: float = 0.0
var skill_preview_active: bool = false
var skill_preview_range: float = 0.0
var skill_preview_targets: Array = []
var skill_preview_label: String = ""
var royal_rally_move_multiplier: float = 1.0
var royal_rally_attack_interval_multiplier: float = 1.0
var soft_counter_effects: Dictionary = {}
var soft_counter_move_multiplier: float = 1.0
var soft_counter_healing_multiplier: float = 1.0
var soft_counter_shield_multiplier: float = 1.0
var soft_counter_skill_recovery_multiplier: float = 1.0
var soft_counter_damage_taken_multiplier: float = 1.0
var soft_counter_attack_interval_multiplier: float = 1.0
var duo_barrier: int = 0
var duo_action_lock_timer: float = 0.0
var duo_move_lock_timer: float = 0.0
var duo_march_buff_timer: float = 0.0
var duo_march_move_multiplier: float = 1.0
var duo_mark_timer: float = 0.0
var duo_mark_source_id: String = ""
var duo_penalty_timer: float = 0.0
var duo_penalty_move_multiplier: float = 1.0
var duo_damage_taken_multiplier: float = 1.0
var duo_redirect_timer: float = 0.0
var duo_redirect_fraction: float = 0.0
var duo_redirect_target: UnitActor = null
var rescue_phase_timer: float = 0.0
var action_interrupt_timer: float = 0.0
var seal_move_lock_timer: float = 0.0
var seal_skill_lock_timer: float = 0.0
var seal_target_immunity_timer: float = 0.0
var seal_telegraph_timer: float = 0.0
var seal_telegraph_source: UnitActor = null
var seal_chain_cooldown_timer: float = 0.0
var seal_chain_cast_timer: float = 0.0
var seal_chain_target: UnitActor = null
var scent_mark_target: UnitActor = null
var scent_mark_timer: float = 0.0
var scent_tracking_active: bool = false
var scent_tracking_move_multiplier: float = 1.0
var scent_marked_attack_multiplier: float = 1.0
var return_scent_timer: float = 0.0
var return_scent_move_multiplier: float = 1.0
var return_scent_damage_reduction: float = 0.0
var home_guard_reduction_timer: float = 0.0
var home_guard_damage_reduction: float = 0.0
var bounty_target: UnitActor = null
var bounty_evaluation_timer: float = 5.0
var bounty_target_timer: float = 0.0
var bounty_mark_source: UnitActor = null
var bounty_mark_timer: float = 0.0
var bounty_damage_taken_multiplier: float = 1.0
var armor_break_amount: int = 0
var armor_break_timer: float = 0.0
var armor_break_source_id: String = ""
var patch_plate_barrier: int = 0
var patch_plate_barrier_timer: float = 0.0
var scrap_stacks: int = 0
var acid_zone_timer: float = 0.0
var acid_def_penalty: int = 0
var acid_repair_multiplier: float = 1.0
var intrinsic_move_multiplier: float = 1.0
var relic_aura_timer: float = 0.0
var relic_aura_magic_multiplier: float = 1.0
var relic_aura_status_multiplier: float = 1.0
var relic_aura_morale_multiplier: float = 1.0
var consecrated_status_multiplier: float = 1.0
var boss_damage_taken_multiplier: float = 1.0
var boss_move_multiplier: float = 1.0
var boss_attack_interval_multiplier: float = 1.0
var purifying_hymn_cast_timer: float = 0.0
var ledger_mark_cast_timer: float = 0.0

var sprite_path: String = ""
var sprite: AnimatedSprite2D
var name_label: Label
static var _animation_frames_cache: Dictionary = {}
static var _sheet_chroma_shader: Shader = null

func setup(source_id: String, stats: Dictionary, unit_faction: String, room_id: String) -> void:
	_ensure_visuals()
	unit_id = source_id
	display_name = stats.get("display_name", source_id)
	faction = unit_faction
	role = stats.get("role", stats.get("goal_type", ""))
	current_room = room_id
	assigned_room = room_id
	goal_room = room_id
	v20_home_zone = ""
	v20_monster_slot_id = ""
	v20_actor_id = ""
	v20_last_evidence_cell = Vector2i(-99999, -99999)
	v20_last_evidence_zone = ""
	max_hp = int(stats.get("max_hp", 100))
	hp = max_hp
	atk = int(stats.get("atk", 10))
	def = int(stats.get("def", 0))
	move_speed = float(stats.get("move_speed", 100))
	intrinsic_move_multiplier = clampf(float(stats.get("move_speed_multiplier", 1.0)), 0.0, 2.0)
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
		if sprite_path.ends_with("_sheet.png"):
			sprite.material = _make_sheet_chroma_material()
		else:
			sprite.material = null
	_apply_visual_pose()
	name_label.text = display_name
	_update_label_color()
	set_tactical_state(Constants.UNIT_STATE_IDLE, "대기")
	_play_animation("idle_down")
	queue_redraw()

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	_ensure_visuals()
	add_to_group("units")

func _physics_process(delta: float) -> void:
	var frame_delta := delta
	delta *= simulation_speed
	if down:
		velocity = Vector2.ZERO
		return

	attack_cooldown = max(0.0, attack_cooldown - delta)
	duo_action_lock_timer = max(0.0, duo_action_lock_timer - delta)
	duo_move_lock_timer = max(0.0, duo_move_lock_timer - delta)
	duo_mark_timer = max(0.0, duo_mark_timer - delta)
	duo_penalty_timer = maxf(0.0, duo_penalty_timer - delta)
	duo_redirect_timer = maxf(0.0, duo_redirect_timer - delta)
	action_interrupt_timer = maxf(0.0, action_interrupt_timer - delta)
	seal_move_lock_timer = maxf(0.0, seal_move_lock_timer - delta)
	seal_skill_lock_timer = maxf(0.0, seal_skill_lock_timer - delta)
	seal_target_immunity_timer = maxf(0.0, seal_target_immunity_timer - delta)
	seal_telegraph_timer = maxf(0.0, seal_telegraph_timer - delta)
	scent_mark_timer = maxf(0.0, scent_mark_timer - delta)
	return_scent_timer = maxf(0.0, return_scent_timer - delta)
	home_guard_reduction_timer = maxf(0.0, home_guard_reduction_timer - delta)
	bounty_target_timer = maxf(0.0, bounty_target_timer - delta)
	bounty_mark_timer = maxf(0.0, bounty_mark_timer - delta)
	armor_break_timer = maxf(0.0, armor_break_timer - delta)
	patch_plate_barrier_timer = maxf(0.0, patch_plate_barrier_timer - delta)
	acid_zone_timer = maxf(0.0, acid_zone_timer - delta)
	relic_aura_timer = maxf(0.0, relic_aura_timer - delta)
	purifying_hymn_cast_timer = maxf(0.0, purifying_hymn_cast_timer - delta)
	ledger_mark_cast_timer = maxf(0.0, ledger_mark_cast_timer - delta)
	if bounty_target_timer <= 0.0 and bounty_target != null:
		clear_bounty_target()
	if bounty_mark_timer <= 0.0:
		bounty_mark_source = null
		bounty_damage_taken_multiplier = 1.0
	if armor_break_timer <= 0.0:
		armor_break_amount = 0
		armor_break_source_id = ""
	if patch_plate_barrier_timer <= 0.0:
		patch_plate_barrier = 0
	if acid_zone_timer <= 0.0:
		acid_def_penalty = 0
		acid_repair_multiplier = 1.0
	if relic_aura_timer <= 0.0:
		relic_aura_magic_multiplier = 1.0
		relic_aura_status_multiplier = 1.0
		relic_aura_morale_multiplier = 1.0
	if return_scent_timer <= 0.0:
		return_scent_move_multiplier = 1.0
		return_scent_damage_reduction = 0.0
	if home_guard_reduction_timer <= 0.0:
		home_guard_damage_reduction = 0.0
	if seal_telegraph_timer <= 0.0:
		seal_telegraph_source = null
	if rescue_phase_timer > 0.0:
		rescue_phase_timer = maxf(0.0, rescue_phase_timer - delta)
	if duo_mark_timer <= 0.0:
		duo_mark_source_id = ""
	if duo_penalty_timer <= 0.0:
		duo_penalty_move_multiplier = 1.0
		duo_damage_taken_multiplier = 1.0
	if duo_redirect_timer <= 0.0 or duo_redirect_target == null or not is_instance_valid(duo_redirect_target) or not duo_redirect_target.is_alive():
		duo_redirect_fraction = 0.0
		duo_redirect_target = null
	if duo_march_buff_timer > 0.0:
		duo_march_buff_timer = max(0.0, duo_march_buff_timer - delta)
		if duo_march_buff_timer <= 0.0:
			duo_march_move_multiplier = 1.0
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
		skill_cooldowns[key] = max(0.0, float(skill_cooldowns[key]) - delta * soft_counter_skill_recovery_multiplier * heart_skill_recovery_multiplier)
	_update_soft_counter_effects(delta)
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
			threat_forced = false
	if duo_action_lock_timer > 0.0 or action_interrupt_timer > 0.0:
		velocity = Vector2.ZERO
		_update_animation()
		queue_redraw()
		return

	var destination = _next_destination()
	var destination_distance_before := INF
	var movement_requested := false
	if destination != Vector2.ZERO:
		var scent_move_multiplier := return_scent_move_multiplier if return_scent_timer > 0.0 else (scent_tracking_move_multiplier if scent_tracking_active and scent_mark_timer > 0.0 else 1.0)
		var speed = effective_move_speed(scent_move_multiplier) * simulation_speed
		if duo_move_lock_timer > 0.0 or seal_move_lock_timer > 0.0:
			speed = 0.0
		var delta_position = destination - global_position
		if delta_position.length() <= _path_point_reach_radius(frame_delta, speed):
			if not path_points.is_empty():
				path_points.pop_front()
			velocity = Vector2.ZERO
		else:
			velocity = delta_position.normalized() * speed
			destination_distance_before = delta_position.length()
			movement_requested = speed > 0.0
	else:
		velocity = Vector2.ZERO
	global_position += velocity * frame_delta
	_clamp_to_dungeon_floor()
	_update_navigation_stall(destination, destination_distance_before, movement_requested, delta)
	_update_animation()
	z_index = int(global_position.y)
	queue_redraw()

func set_simulation_speed(value: float) -> void:
	simulation_speed = clampf(value, 0.25, 4.0)
	if sprite != null:
		sprite.speed_scale = simulation_speed

func _path_point_reach_radius(frame_delta: float, movement_speed: float) -> float:
	# Fast-forward can cross a short waypoint in one physics frame. Consume it
	# before movement instead of oscillating around it indefinitely.
	return maxf(PATH_POINT_REACHED_RADIUS, movement_speed * frame_delta * 1.05)

func set_path(points: Array) -> void:
	path_points.clear()
	for point_value in points:
		if not (point_value is Vector2):
			continue
		var safe_point := _clamp_to_dungeon_point(point_value)
		if path_points.is_empty() or path_points[-1].distance_to(safe_point) > 1.0:
			path_points.append(safe_point)
	if not path_points.is_empty() and path_points[0].distance_to(global_position) < PATH_POINT_REACHED_RADIUS:
		path_points.pop_front()
	navigation_stall_time = 0.0

func stop_navigation() -> void:
	path_points.clear()
	velocity = Vector2.ZERO
	navigation_stall_time = 0.0


func _update_navigation_stall(destination: Vector2, distance_before: float, movement_requested: bool, delta: float) -> void:
	if not movement_requested or path_points.is_empty() or not is_finite(distance_before):
		navigation_stall_time = 0.0
		return
	var distance_after := global_position.distance_to(destination)
	if distance_after < distance_before - NAVIGATION_PROGRESS_EPSILON:
		navigation_stall_time = 0.0
		return
	navigation_stall_time += delta
	if navigation_stall_time < NAVIGATION_STALL_TIMEOUT:
		return
	path_points.pop_front()
	velocity = Vector2.ZERO
	navigation_stall_time = 0.0

func is_alive() -> bool:
	return not down and hp > 0

func receive_damage(amount: int) -> int:
	if down:
		return 0
	if duo_redirect_timer > 0.0 and duo_redirect_target != null and is_instance_valid(duo_redirect_target) and duo_redirect_target.is_alive() and duo_redirect_target != self:
		var redirected := clampi(int(round(float(maxi(0, amount)) * duo_redirect_fraction)), 0, maxi(0, amount - 1))
		amount -= redirected
		if redirected > 0:
			duo_redirect_target.receive_damage(redirected)
	var status_reduction := return_scent_damage_reduction if return_scent_timer > 0.0 else 0.0
	if home_guard_reduction_timer > 0.0:
		status_reduction = maxf(status_reduction, home_guard_damage_reduction)
	var final_amount = max(1, int(round(float(amount) * (1.0 - damage_reduction) * (1.0 - clampf(status_reduction, 0.0, 0.8)) * soft_counter_damage_taken_multiplier * boss_damage_taken_multiplier * duo_damage_taken_multiplier)))
	if patch_plate_barrier > 0 and patch_plate_barrier_timer > 0.0:
		var patch_blocked := mini(patch_plate_barrier, final_amount)
		patch_plate_barrier -= patch_blocked
		final_amount -= patch_blocked
		if patch_plate_barrier <= 0:
			patch_plate_barrier_timer = 0.0
		if final_amount <= 0:
			hp_changed.emit(self)
			queue_redraw()
			return 0
	if duo_barrier > 0:
		var blocked := mini(duo_barrier, final_amount)
		duo_barrier -= blocked
		final_amount -= blocked
		if final_amount <= 0:
			hp_changed.emit(self)
			queue_redraw()
			return 0
	hp = max(0, hp - final_amount)
	hp_changed.emit(self)
	if hp <= 0:
		down = true
		target = null
		target_focus_timer = 0.0
		path_points.clear()
		set_tactical_state(Constants.UNIT_STATE_DOWN, "전투 불능")
		modulate = Color(0.35, 0.35, 0.38, 0.85)
		name_label.text = "%s DOWN" % display_name
		_play_animation("down")
		downed.emit(self)
	queue_redraw()
	return final_amount
func receive_magic_damage(amount: int) -> int:
	var adjusted := maxi(0, int(round(float(maxi(0, amount)) * relic_aura_magic_multiplier)))
	return receive_damage(adjusted)


func heal(amount: int, heart_event_token: String = "", ignore_healing_fatigue: bool = false) -> int:
	if down:
		return 0
	var before := hp
	var fatigue_multiplier := 1.0 if ignore_healing_fatigue else soft_counter_healing_multiplier * heart_healing_multiplier
	var adjusted_amount := maxi(1, int(round(float(amount) * fatigue_multiplier))) if amount > 0 else 0
	hp = min(max_hp, hp + adjusted_amount)
	var effective := maxi(0, hp - before)
	hp_changed.emit(self)
	if effective > 0:
		effective_healed.emit(self, effective, heart_event_token)
	queue_redraw()
	return effective


func grant_duo_barrier(amount: int) -> void:
	duo_barrier = maxi(duo_barrier, maxi(0, amount))
	hp_changed.emit(self)
	queue_redraw()


func grant_patch_plate_barrier(amount: int, seconds: float) -> int:
	var granted := maxi(0, amount)
	patch_plate_barrier = maxi(patch_plate_barrier, granted)
	patch_plate_barrier_timer = maxf(patch_plate_barrier_timer, maxf(0.0, seconds))
	hp_changed.emit(self)
	queue_redraw()
	return patch_plate_barrier


func apply_armor_break(amount: int, seconds: float, source_id: String = "") -> bool:
	var reduction := maxi(0, amount)
	var duration := _hostile_status_duration(maxf(0.0, seconds))
	if reduction <= 0 or duration <= 0.0:
		return false
	if armor_break_timer <= 0.0:
		armor_break_amount = reduction
		armor_break_source_id = source_id
	armor_break_timer = duration
	queue_redraw()
	return true


func add_scrap_stack(amount: int = 1, maximum: int = 3) -> int:
	scrap_stacks = clampi(scrap_stacks + maxi(0, amount), 0, maxi(0, maximum))
	queue_redraw()
	return scrap_stacks


func consume_scrap_stacks() -> int:
	var consumed := scrap_stacks
	scrap_stacks = 0
	queue_redraw()
	return consumed


func apply_acid_zone(seconds: float, defense_penalty: int, repair_multiplier: float) -> void:
	acid_zone_timer = maxf(acid_zone_timer, maxf(0.0, seconds))
	acid_def_penalty = clampi(maxi(acid_def_penalty, defense_penalty), 0, 2)
	acid_repair_multiplier = maxf(0.6, minf(acid_repair_multiplier, repair_multiplier))
	queue_redraw()


func apply_relic_aura(seconds: float, magic_multiplier: float, status_multiplier: float, morale_multiplier: float) -> void:
	relic_aura_timer = maxf(relic_aura_timer, maxf(0.0, seconds))
	relic_aura_magic_multiplier = minf(relic_aura_magic_multiplier, clampf(magic_multiplier, 0.0, 1.0))
	relic_aura_status_multiplier = minf(relic_aura_status_multiplier, clampf(status_multiplier, 0.0, 1.0))
	relic_aura_morale_multiplier = minf(relic_aura_morale_multiplier, clampf(morale_multiplier, 0.0, 1.0))
	queue_redraw()


func has_relic_aura() -> bool:
	return relic_aura_timer > 0.0


func repair_output_multiplier() -> float:
	return acid_repair_multiplier if acid_zone_timer > 0.0 else 1.0


func apply_duo_action_lock(seconds: float) -> void:
	duo_action_lock_timer = maxf(duo_action_lock_timer, maxf(0.0, seconds))
	stop_navigation()


func duo_action_locked() -> bool:
	return duo_action_lock_timer > 0.0


func apply_duo_move_lock(seconds: float) -> void:
	duo_move_lock_timer = maxf(duo_move_lock_timer, maxf(0.0, seconds))


func apply_duo_march_buff(seconds: float, defense_bonus: int, move_multiplier: float) -> void:
	activate_guard(seconds, defense_bonus)
	duo_march_buff_timer = maxf(duo_march_buff_timer, seconds)
	duo_march_move_multiplier = maxf(duo_march_move_multiplier, move_multiplier)


func apply_duo_penalty(seconds: float, move_multiplier: float = 1.0, damage_taken_multiplier: float = 1.0) -> void:
	duo_penalty_timer = maxf(duo_penalty_timer, maxf(0.0, seconds))
	duo_penalty_move_multiplier = minf(duo_penalty_move_multiplier, clampf(move_multiplier, 0.1, 1.0))
	duo_damage_taken_multiplier = maxf(duo_damage_taken_multiplier, clampf(damage_taken_multiplier, 1.0, 1.25))


func apply_duo_damage_redirect(protector: UnitActor, seconds: float, fraction: float) -> void:
	if protector == null or not is_instance_valid(protector) or not protector.is_alive() or protector == self:
		return
	duo_redirect_target = protector
	duo_redirect_timer = maxf(duo_redirect_timer, maxf(0.0, seconds))
	duo_redirect_fraction = maxf(duo_redirect_fraction, clampf(fraction, 0.0, 0.5))


func receive_morale_damage(amount: int) -> int:
	var before := morale
	var adjusted := maxi(0, int(round(float(maxi(0, amount)) * relic_aura_morale_multiplier)))
	morale = maxi(0, morale - adjusted)
	return before - morale


func apply_duo_mark(seconds: float, source_instance_id: String) -> void:
	duo_mark_timer = maxf(duo_mark_timer, maxf(0.0, seconds))
	duo_mark_source_id = source_instance_id


func apply_rescue_phase(seconds: float) -> void:
	rescue_phase_timer = maxf(rescue_phase_timer, maxf(0.0, seconds))


func apply_action_interrupt(seconds: float) -> void:
	action_interrupt_timer = maxf(action_interrupt_timer, _hostile_status_duration(maxf(0.0, seconds)))
	if action_interrupt_timer > 0.0:
		purifying_hymn_cast_timer = 0.0


func start_scent_mark(target_unit: UnitActor, seconds: float, move_multiplier: float, attack_multiplier: float) -> void:
	scent_mark_target = target_unit
	scent_mark_timer = maxf(0.0, seconds)
	scent_tracking_move_multiplier = maxf(1.0, move_multiplier)
	scent_marked_attack_multiplier = maxf(1.0, attack_multiplier)
	scent_tracking_active = target_unit != null
	end_return_scent()
	queue_redraw()


func has_active_scent_mark() -> bool:
	return scent_mark_timer > 0.0 and scent_mark_target != null and is_instance_valid(scent_mark_target) and scent_mark_target.is_alive()


func preferred_attack_target(opponents: Array, attack_distance: float) -> UnitActor:
	if bounty_target_timer > 0.0 and bounty_target != null and is_instance_valid(bounty_target) and bounty_target.is_alive() and opponents.has(bounty_target) and global_position.distance_to(bounty_target.global_position) <= attack_distance:
		return bounty_target
	if not has_active_scent_mark() or not opponents.has(scent_mark_target):
		return null
	if global_position.distance_to(scent_mark_target.global_position) > attack_distance:
		return null
	return scent_mark_target


func attack_multiplier_against(target_unit: UnitActor) -> float:
	if has_active_scent_mark() and target_unit == scent_mark_target:
		return scent_marked_attack_multiplier
	return 1.0


func apply_bounty_target(target_unit: UnitActor, seconds: float, damage_multiplier: float) -> void:
	clear_bounty_target()
	bounty_target = target_unit
	bounty_target_timer = maxf(0.0, seconds)
	if bounty_target != null:
		bounty_target.bounty_mark_source = self
		bounty_target.bounty_mark_timer = bounty_target_timer
		bounty_target.bounty_damage_taken_multiplier = clampf(damage_multiplier, 1.0, 1.15)
		bounty_target.queue_redraw()
	queue_redraw()


func clear_bounty_target() -> void:
	if bounty_target != null and is_instance_valid(bounty_target) and bounty_target.bounty_mark_source == self:
		bounty_target.bounty_mark_source = null
		bounty_target.bounty_mark_timer = 0.0
		bounty_target.bounty_damage_taken_multiplier = 1.0
		bounty_target.queue_redraw()
	bounty_target = null
	bounty_target_timer = 0.0
	queue_redraw()


func damage_taken_multiplier_from(attacker: UnitActor) -> float:
	if bounty_mark_timer > 0.0 and bounty_mark_source == attacker:
		return clampf(bounty_damage_taken_multiplier, 1.0, 1.15)
	return 1.0


func begin_return_scent(seconds: float, move_multiplier: float, reduction: float) -> void:
	scent_tracking_active = false
	scent_mark_timer = 0.0
	scent_mark_target = null
	return_scent_timer = maxf(return_scent_timer, maxf(0.0, seconds))
	return_scent_move_multiplier = maxf(1.0, move_multiplier)
	return_scent_damage_reduction = clampf(reduction, 0.0, 0.8)
	queue_redraw()


func end_return_scent() -> void:
	return_scent_timer = 0.0
	return_scent_move_multiplier = 1.0
	return_scent_damage_reduction = 0.0
	queue_redraw()


func apply_home_guard_reduction(seconds: float, reduction: float) -> void:
	home_guard_reduction_timer = maxf(home_guard_reduction_timer, maxf(0.0, seconds))
	home_guard_damage_reduction = maxf(home_guard_damage_reduction, clampf(reduction, 0.0, 0.8))


func begin_seal_chain_telegraph(source: UnitActor, seconds: float) -> void:
	seal_telegraph_source = source
	seal_telegraph_timer = maxf(seal_telegraph_timer, maxf(0.0, seconds))
	queue_redraw()


func cancel_seal_chain_telegraph(source: UnitActor = null) -> void:
	if source != null and seal_telegraph_source != source:
		return
	seal_telegraph_source = null
	seal_telegraph_timer = 0.0
	queue_redraw()


func apply_seal_chain(move_seconds: float, skill_seconds: float, immunity_seconds: float) -> void:
	seal_move_lock_timer = maxf(seal_move_lock_timer, _heart_control_duration(maxf(0.0, move_seconds)))
	seal_skill_lock_timer = maxf(seal_skill_lock_timer, _hostile_status_duration(maxf(0.0, skill_seconds)))
	seal_target_immunity_timer = maxf(seal_target_immunity_timer, maxf(0.0, immunity_seconds))
	cancel_seal_chain_telegraph()
	set_tactical_state(Constants.UNIT_STATE_SEEK_TARGET, "봉인 사슬", "이동·스킬 제한")
	queue_redraw()


func active_skills_locked() -> bool:
	return seal_skill_lock_timer > 0.0


func reduce_seal_move_lock(multiplier: float = 0.5) -> bool:
	if seal_move_lock_timer <= 0.0:
		return false
	seal_move_lock_timer *= clampf(multiplier, 0.0, 1.0)
	queue_redraw()
	return true


func cleanse_one_negative_status() -> bool:
	if armor_break_timer > 0.0:
		armor_break_timer = 0.0
		armor_break_amount = 0
		armor_break_source_id = ""
		queue_redraw()
		return true
	if reduce_seal_move_lock(0.5):
		return true
	if slow_timer > 0.0:
		slow_timer = 0.0
		slow_factor = 1.0
		return true
	if threat_timer > 0.0:
		threat_timer = 0.0
		threat_unit = null
		threat_forced = false
		return true
	if not soft_counter_effects.is_empty():
		soft_counter_effects.erase(soft_counter_effects.keys()[0])
		return true
	return false


func negative_status_count() -> int:
	var count := 0
	count += 1 if armor_break_timer > 0.0 else 0
	count += 1 if seal_move_lock_timer > 0.0 else 0
	count += 1 if slow_timer > 0.0 else 0
	count += 1 if threat_timer > 0.0 else 0
	count += soft_counter_effects.size()
	return count


func begin_purifying_hymn(seconds: float) -> void:
	purifying_hymn_cast_timer = maxf(0.0, seconds)
	skill_anim_timer = maxf(skill_anim_timer, purifying_hymn_cast_timer)
	set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "정화 성가", "시전 중")
	queue_redraw()


func cancel_purifying_hymn() -> void:
	purifying_hymn_cast_timer = 0.0
	queue_redraw()


func begin_ledger_mark_cast(seconds: float, room_name: String) -> void:
	ledger_mark_cast_timer = maxf(0.0, seconds)
	skill_anim_timer = maxf(skill_anim_timer, ledger_mark_cast_timer)
	set_tactical_state(Constants.UNIT_STATE_CAST_SKILL, "부채 표식 예고", room_name)
	queue_redraw()


func cancel_ledger_mark_cast() -> void:
	ledger_mark_cast_timer = 0.0
	queue_redraw()

func apply_slow(seconds: float, factor: float) -> void:
	var duration := _heart_control_duration(seconds)
	slow_timer = max(slow_timer, duration)
	slow_factor = min(slow_factor, factor)

func apply_root(seconds: float) -> void:
	var duration := _heart_control_duration(seconds)
	slow_timer = max(slow_timer, duration)
	slow_factor = 0.0

func apply_taunt(attacker: UnitActor, seconds: float = 4.0) -> void:
	mark_threat(attacker, _heart_control_duration(seconds), true)

func _heart_control_duration(seconds: float) -> float:
	var duration := _hostile_status_duration(seconds)
	if heart_first_control_available and heart_first_control_multiplier > 1.0:
		duration *= heart_first_control_multiplier
		heart_first_control_available = false
		first_heart_control_applied.emit(self)
	return duration


func _hostile_status_duration(seconds: float) -> float:
	return maxf(0.0, seconds) * relic_aura_status_multiplier * consecrated_status_multiplier

func activate_shield(seconds: float, reduction: float, status_label: String = "점액 방패") -> void:
	shield_timer = max(shield_timer, seconds)
	damage_reduction = max(damage_reduction, reduction * soft_counter_shield_multiplier)
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
	return maxi(0, def + guard_bonus + heart_def_bonus - armor_break_amount - acid_def_penalty)

func mark_threat(attacker: UnitActor, seconds: float = 4.0, forced: bool = false) -> void:
	# Ordinary retaliation memory must not replace an active explicit taunt.
	if threat_forced and threat_timer > 0.0 and not forced:
		return
	threat_unit = attacker
	threat_timer = max(threat_timer, seconds)
	threat_forced = forced

func forced_attack_target(opponents: Array, attack_distance: float) -> UnitActor:
	if not threat_forced or threat_timer <= 0.0:
		return null
	if threat_unit == null or not is_instance_valid(threat_unit) or not threat_unit.is_alive():
		return null
	if not opponents.has(threat_unit) or global_position.distance_to(threat_unit.global_position) > attack_distance:
		return null
	return threat_unit

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
		Constants.UNIT_STATE_STUNNED:
			return "기절"
		Constants.UNIT_STATE_LOOTING:
			return "약탈"
		Constants.UNIT_STATE_DOWN:
			return "불능"
		_:
			return "상태"

func status_line() -> String:
	if ledger_mark_cast_timer > 0.0:
		return "위험: 부채 표식 %.1f초 · 시전자 처치로 차단" % ledger_mark_cast_timer
	if purifying_hymn_cast_timer > 0.0:
		return "위험: 정화 성가 %.1f초 · 빗자루로 중단 가능" % purifying_hymn_cast_timer
	if seal_telegraph_timer > 0.0:
		return "위험: 봉인 사슬 예고 %.1f초 · 빗자루로 중단 가능" % seal_telegraph_timer
	if seal_move_lock_timer > 0.0 or seal_skill_lock_timer > 0.0:
		return "봉인: 이동 %.1f초 · 스킬 %.1f초" % [seal_move_lock_timer, seal_skill_lock_timer]
	if return_scent_timer > 0.0:
		return "복귀: 돌아가는 냄새 %.1f초 · 이동 +35%% · 피해 -8%%" % return_scent_timer
	if has_active_scent_mark():
		return "추적: %s 냄새 고정 %.1f초" % [scent_mark_target.display_name, scent_mark_timer]
	if bounty_mark_timer > 0.0:
		return "위험: 현상금 표적 %.1f초 · 추적자 피해 +15%%" % bounty_mark_timer
	if bounty_target_timer > 0.0 and bounty_target != null and is_instance_valid(bounty_target):
		return "추적: 현상금 표적 %s %.1f초" % [bounty_target.display_name, bounty_target_timer]
	if armor_break_timer > 0.0 and armor_break_amount > 0:
		return "약화: 방어력 -%d · %.1f초" % [armor_break_amount, armor_break_timer]
	if patch_plate_barrier > 0 and patch_plate_barrier_timer > 0.0:
		return "판금 보호막 %d · %.1f초" % [patch_plate_barrier, patch_plate_barrier_timer]
	if acid_zone_timer > 0.0:
		return "위험: 산성 구역 · 방어 -%d · 수리 -40%%" % acid_def_penalty
	if relic_aura_timer > 0.0:
		return "성물 오라: 마법 피해 -15% · 상태·사기 피해 -25%"
	if scrap_stacks > 0:
		return "고철 등딱지 %d/3" % scrap_stacks
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
	return attack_interval * royal_rally_attack_interval_multiplier * soft_counter_attack_interval_multiplier * boss_attack_interval_multiplier


func effective_move_speed(extra_multiplier: float = 1.0) -> float:
	return move_speed * intrinsic_move_multiplier * slow_factor * royal_rally_move_multiplier * soft_counter_move_multiplier * heart_move_multiplier * duo_march_move_multiplier * duo_penalty_move_multiplier * boss_move_multiplier * float(get_meta("v20_command_move_multiplier", 1.0)) * extra_multiplier

func apply_soft_counter(mode: String, seconds: float, strength: float, source_id: String = "") -> float:
	if mode not in ["movement", "healing", "shield", "skill_recovery", "exposure", "attack_speed"]:
		return 0.0
	var clamped_strength := clampf(strength, 0.0, SOFT_COUNTER_MAX_STRENGTH)
	if clamped_strength <= 0.0 or seconds <= 0.0:
		return 0.0
	var current: Dictionary = soft_counter_effects.get(mode, {})
	soft_counter_effects[mode] = {
		"strength": maxf(float(current.get("strength", 0.0)), clamped_strength),
		"remaining": maxf(float(current.get("remaining", 0.0)), seconds),
		"source_id": source_id
	}
	_refresh_soft_counter_multipliers()
	return clamped_strength

func soft_counter_max_strength() -> float:
	var result := 0.0
	for effect_value in soft_counter_effects.values():
		if effect_value is Dictionary:
			result = maxf(result, float(effect_value.get("strength", 0.0)))
	return result

func _update_soft_counter_effects(delta: float) -> void:
	if soft_counter_effects.is_empty():
		return
	for mode_value in soft_counter_effects.keys():
		var mode := str(mode_value)
		var effect: Dictionary = soft_counter_effects.get(mode, {})
		effect["remaining"] = maxf(0.0, float(effect.get("remaining", 0.0)) - delta)
		if float(effect.get("remaining", 0.0)) <= 0.0:
			soft_counter_effects.erase(mode)
		else:
			soft_counter_effects[mode] = effect
	_refresh_soft_counter_multipliers()

func _refresh_soft_counter_multipliers() -> void:
	soft_counter_move_multiplier = 1.0
	soft_counter_healing_multiplier = 1.0
	soft_counter_shield_multiplier = 1.0
	soft_counter_skill_recovery_multiplier = 1.0
	soft_counter_damage_taken_multiplier = 1.0
	soft_counter_attack_interval_multiplier = 1.0
	for mode_value in soft_counter_effects.keys():
		var mode := str(mode_value)
		var strength := clampf(float(soft_counter_effects.get(mode, {}).get("strength", 0.0)), 0.0, SOFT_COUNTER_MAX_STRENGTH)
		match mode:
			"movement":
				soft_counter_move_multiplier = minf(soft_counter_move_multiplier, 1.0 - strength)
			"healing":
				soft_counter_healing_multiplier = minf(soft_counter_healing_multiplier, 1.0 - strength)
			"shield":
				soft_counter_shield_multiplier = minf(soft_counter_shield_multiplier, 1.0 - strength)
			"skill_recovery":
				soft_counter_skill_recovery_multiplier = minf(soft_counter_skill_recovery_multiplier, 1.0 - strength)
			"exposure":
				soft_counter_damage_taken_multiplier = maxf(soft_counter_damage_taken_multiplier, 1.0 + strength)
			"attack_speed":
				soft_counter_attack_interval_multiplier = maxf(soft_counter_attack_interval_multiplier, 1.0 + strength)

func _next_destination() -> Vector2:
	if not path_points.is_empty():
		return path_points[0]
	return Vector2.ZERO

func _draw() -> void:
	if ledger_mark_cast_timer > 0.0 and not down:
		var ledger_ratio := clampf(ledger_mark_cast_timer, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 40.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - ledger_ratio), 48, Color("#e7a95f"), 4.0)
		draw_string(UI_FONT, Vector2(-54, -116), "부채 표식 %.1f" % ledger_mark_cast_timer, HORIZONTAL_ALIGNMENT_CENTER, 108, 12, Color("#ffe1b0"))
	if purifying_hymn_cast_timer > 0.0 and not down:
		var hymn_ratio := clampf(purifying_hymn_cast_timer / 1.2, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 38.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - hymn_ratio), 48, Color("#fff2a8"), 4.0)
		draw_string(UI_FONT, Vector2(-48, -116), "정화 성가 %.1f" % purifying_hymn_cast_timer, HORIZONTAL_ALIGNMENT_CENTER, 96, 12, Color("#fff5c8"))
	if unit_id == "reliquary_guard" and not down:
		draw_arc(Vector2.ZERO, 155.0, 0.0, TAU, 72, Color(0.95, 0.84, 0.43, 0.72), 2.5)
		draw_arc(Vector2.ZERO, 151.0, 0.0, TAU, 72, Color(0.72, 0.84, 1.0, 0.28), 1.0)
		draw_string(UI_FONT, Vector2(-58, -126), "성물 오라 155", HORIZONTAL_ALIGNMENT_CENTER, 116, 12, Color("#fff0a8"))
	elif relic_aura_timer > 0.0 and not down:
		draw_arc(Vector2.ZERO, 29.0, 0.0, TAU, 40, Color("#efd98a"), 2.0)
	if acid_zone_timer > 0.0 and not down:
		draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 48, Color("#a8d64f"), 3.0)
		draw_string(UI_FONT, Vector2(-56, -112), "산성 · DEF -%d" % acid_def_penalty, HORIZONTAL_ALIGNMENT_CENTER, 112, 12, Color("#dff5a0"))
	if armor_break_timer > 0.0 and armor_break_amount > 0 and not down:
		draw_arc(Vector2.ZERO, 30.0, PI * 0.12, PI * 0.88, 28, Color("#ff9b55"), 3.0)
		draw_string(UI_FONT, Vector2(-44, -76), "방어 -%d" % armor_break_amount, HORIZONTAL_ALIGNMENT_CENTER, 88, 12, Color("#ffd8ae"))
	if patch_plate_barrier > 0 and patch_plate_barrier_timer > 0.0 and not down:
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 48, Color("#d8b36d"), 3.0)
	if scrap_stacks > 0 and not down:
		draw_string(UI_FONT, Vector2(-38, -94), "고철 %d/3" % scrap_stacks, HORIZONTAL_ALIGNMENT_CENTER, 76, 12, Color("#e7c788"))
	if bounty_mark_timer > 0.0 and not down:
		var bounty_color := Color("#ff5f45")
		var bounty_pulse := (sin(visual_phase * 10.0) + 1.0) * 0.5
		var diamond := PackedVector2Array([Vector2(0, -112 - bounty_pulse * 3.0), Vector2(9, -103 - bounty_pulse * 3.0), Vector2(0, -94 - bounty_pulse * 3.0), Vector2(-9, -103 - bounty_pulse * 3.0)])
		draw_colored_polygon(diamond, Color(bounty_color.r, bounty_color.g, bounty_color.b, 0.82))
		draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#fff0d8"), 1.5)
		var bounty_rect := Rect2(Vector2(-42, -142), Vector2(84, 22))
		draw_rect(bounty_rect, Color("#260b08e8"), true)
		draw_rect(bounty_rect, bounty_color, false, 1.5)
		draw_string(UI_FONT, bounty_rect.position + Vector2(0, 16), "현상금", HORIZONTAL_ALIGNMENT_CENTER, bounty_rect.size.x, 12, Color("#fff4e7"))
	if has_active_scent_mark() and not down:
		var scent_color := Color("#72b9ff")
		var scent_pulse := (sin(visual_phase * 8.0) + 1.0) * 0.5
		draw_arc(Vector2.ZERO, 27.0 + scent_pulse * 2.0, 0.0, TAU, 48, scent_color, 2.5)
		draw_line(Vector2(0, -28), to_local(scent_mark_target.global_position) + Vector2(0, -28), Color(0.45, 0.73, 1.0, 0.48), 1.5, true)
	if return_scent_timer > 0.0 and not down:
		draw_arc(Vector2.ZERO, 31.0, -PI * 0.75, PI * 0.75, 40, Color("#8ee6c4"), 3.0)
	if seal_telegraph_timer > 0.0 and not down:
		var seal_skill: Dictionary = DataRegistry.skill("seal_chain")
		var telegraph_total := maxf(0.01, float(seal_skill.get("telegraph_seconds", 0.9)))
		var seal_ratio := clampf(seal_telegraph_timer / telegraph_total, 0.0, 1.0)
		var seal_pulse := (sin(visual_phase * 12.0) + 1.0) * 0.5
		var seal_color := Color("#ff496f")
		draw_circle(Vector2.ZERO, 38.0, Color(seal_color.r, seal_color.g, seal_color.b, 0.08 + seal_pulse * 0.04))
		draw_arc(Vector2.ZERO, 34.0 + seal_pulse * 3.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - seal_ratio), 64, seal_color, 4.0)
		if seal_telegraph_source != null and is_instance_valid(seal_telegraph_source):
			draw_line(Vector2(0, -30), to_local(seal_telegraph_source.global_position) + Vector2(0, -30), Color(1.0, 0.29, 0.44, 0.78), 2.0, true)
		var seal_rect := Rect2(Vector2(-74, -120), Vector2(148, 24))
		draw_rect(seal_rect, Color("#240912ee"), true)
		draw_rect(seal_rect, seal_color, false, 2.0)
		draw_string(UI_FONT, seal_rect.position + Vector2(0, 17), "봉인 사슬 %.1f초" % seal_telegraph_timer, HORIZONTAL_ALIGNMENT_CENTER, seal_rect.size.x, 12, Color("#fff1f5"))
	if seal_move_lock_timer > 0.0 and not down:
		draw_arc(Vector2.ZERO, 29.0, 0.0, TAU, 48, Color("#bd72e8"), 3.0)
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

	var bar_width = 52.0
	var ratio = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	var hp_rect = Rect2(Vector2(-bar_width * 0.5, -73.0), Vector2(bar_width, 7.0))
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
		name_label.position = Vector2(-55, -96)
		name_label.size = Vector2(110, 24)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font", UI_FONT)
		name_label.add_theme_font_size_override("font_size", 14)
		add_child(name_label)

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

static func _make_sheet_chroma_material() -> ShaderMaterial:
	if _sheet_chroma_shader == null:
		_sheet_chroma_shader = Shader.new()
		_sheet_chroma_shader.code = """
shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float magenta = min(color.r, color.b) - color.g;
	float red_blue_balance = 1.0 - smoothstep(0.10, 0.32, abs(color.r - color.b));
	float key = smoothstep(0.10, 0.34, magenta) * red_blue_balance;
	color.a *= 1.0 - key;
	COLOR = color;
}
"""
	var material := ShaderMaterial.new()
	material.shader = _sheet_chroma_shader
	return material

static func warm_animation_frames(path: String) -> SpriteFrames:
	if path == "":
		return null
	if _animation_frames_cache.has(path):
		return _animation_frames_cache[path]
	var fallback_texture := _load_png(path)
	if fallback_texture == null:
		return null
	var frames := _build_sheet_animation_frames(fallback_texture) if path.ends_with("_sheet.png") else _build_animation_frames(path, fallback_texture)
	_animation_frames_cache[path] = frames
	return frames


static func _build_sheet_animation_frames(sheet: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var cell_size := Vector2(sheet.get_width() / 4.0, sheet.get_height() / 4.0)
	var cell_map := {
		"idle_down": [Vector2i(0, 0), Vector2i(1, 0)],
		"down": [Vector2i(2, 0), Vector2i(3, 0)],
		"move_down": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
		"attack_down": [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)],
		"skill_down": [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)]
	}
	for animation_name in cell_map.keys():
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, animation_name in ["idle_down", "move_down"])
		frames.set_animation_speed(animation_name, 5.0 if animation_name == "idle_down" else 7.0 if animation_name == "down" else 8.0 if animation_name == "skill_down" else 10.0)
		for cell_value in cell_map[animation_name]:
			var cell: Vector2i = cell_value
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(Vector2(cell.x, cell.y) * cell_size, cell_size)
			frames.add_frame(animation_name, frame)
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

