extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""
var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	output_dir = ProjectSettings.globalize_path("res://tmp/action_feel_review")
	DirAccess.make_dir_recursive_absolute(output_dir)

	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game._debug_skip_onboarding()
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
	game._start_combat()
	await _settle(4)

	game.combat_paused = true
	game._spawn_enemy("explorer")
	var slime = _unit_by_id(game.monster_units, "slime")
	var explorer = game.enemy_units.back() if not game.enemy_units.is_empty() else null
	if slime == null or explorer == null:
		push_error("Could not prepare action feel review units.")
		get_tree().quit(1)
		return

	var stage_center = game.graph.center("barracks")
	slime.set_physics_process(false)
	explorer.set_physics_process(false)
	slime.global_position = stage_center + Vector2(-30, 12)
	explorer.global_position = stage_center + Vector2(30, 12)
	slime.current_room = "barracks"
	explorer.current_room = "barracks"
	slime.stop_navigation()
	explorer.stop_navigation()
	game._select_unit(slime)

	slime.visual_phase = 0.16
	slime.velocity = Vector2(100, 0)
	slime._apply_visual_pose()
	await _save("01_move_pose.png")

	slime.velocity = Vector2.ZERO
	slime.attack_cooldown = 0.0
	slime.mark_action_target(explorer)
	slime.play_attack(explorer.global_position)
	slime.attack_anim_timer = 0.21
	explorer.play_hit(slime.global_position)
	slime._apply_visual_pose()
	explorer._apply_visual_pose()
	game.combat_scene.spawn_damage_number(explorer.global_position, 9, explorer.faction)
	game.combat_scene.camera_kick(3.0)
	await _save("02_attack_contact.png")

	slime.attack_anim_timer = 0.10
	explorer.hit_anim_timer = 0.08
	slime._apply_visual_pose()
	explorer._apply_visual_pose()
	await _save("03_hit_recovery.png")

	await _capture_monster_contact("slime", explorer, "05_slime_attack_keyframe.png", 11)
	await _capture_monster_contact("goblin", explorer, "06_goblin_attack_keyframe.png", 18)
	await _capture_monster_contact("imp", explorer, "07_imp_attack_keyframe.png", 24)
	await _capture_damage_number_stack(slime, explorer)

	for monster in game.monster_units:
		monster.visible = true
		monster.set_physics_process(true)
		monster.sprite.play()
	explorer.set_physics_process(true)
	game.combat_paused = false
	game.combat_speed = 0.75
	await _settle(50)
	await _save("04_live_combat.png")
	await _capture_small_view_combat(slime, explorer)
	await _capture_thief_warning()

	print("ACTION_FEEL_VISUAL_REVIEW: %s" % output_dir)
	get_tree().quit(1 if failed else 0)

func _capture_monster_contact(monster_id: String, target: Node, file_name: String, damage: int) -> void:
	var actor = _unit_by_id(game.monster_units, monster_id)
	if actor == null or target == null:
		push_error("Could not prepare %s attack keyframe capture." % monster_id)
		failed = true
		return
	game.combat_scene.clear_effects()
	for monster in game.monster_units:
		monster.visible = monster == actor
		monster.set_physics_process(false)
	actor.global_position = game.graph.center("barracks") + Vector2(-36, 12)
	target.global_position = game.graph.center("barracks") + Vector2(36, 12)
	actor.velocity = Vector2.ZERO
	target.velocity = Vector2.ZERO
	actor.mark_action_target(target)
	actor.play_attack(target.global_position)
	actor.attack_anim_timer = 0.21
	actor.sprite.frame = 2
	actor.sprite.pause()
	target.play_hit(actor.global_position)
	actor._apply_visual_pose()
	target._apply_visual_pose()
	game._select_unit(actor)
	game.combat_scene.spawn_damage_number(target.global_position, damage, target.faction)
	await _settle(3)
	await _save(file_name)

func _capture_thief_warning() -> void:
	game.combat_paused = true
	game._spawn_enemy("thief")
	var thief = _unit_by_id(game.enemy_units, "thief")
	if thief == null:
		push_error("Could not prepare thief warning capture.")
		failed = true
		return
	for enemy in game.enemy_units:
		enemy.visible = enemy == thief
		enemy.set_physics_process(false)
	var treasure_room = game._room_by_facility("treasure", "treasure")
	thief.global_position = game.graph.center(treasure_room) + Vector2(36, 12)
	thief.current_room = "spike_corridor"
	thief.velocity = Vector2.ZERO
	thief.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "목표 방 이동", "보물 보관실")
	thief._apply_visual_pose()
	thief.queue_redraw()
	await _settle(3)
	await _save("08_thief_infiltration_warning.png")
	thief.current_room = treasure_room
	thief.set_tactical_state(Constants.UNIT_STATE_LOOTING, "보물 약탈", "금화")
	thief.queue_redraw()
	await _settle(3)
	await _save("09_thief_looting_warning.png")

func _capture_damage_number_stack(attacker: Node, target: Node, file_name := "10_damage_number_stack.png") -> void:
	if attacker == null or target == null:
		return
	game.combat_scene.clear_effects()
	for monster in game.monster_units:
		monster.visible = monster == attacker
	var review_center: Vector2 = game.graph.center("spike_corridor") + Vector2(0, 72)
	attacker.global_position = review_center + Vector2(-36, 12)
	target.global_position = review_center + Vector2(36, 12)
	attacker._apply_visual_pose()
	target.play_hit(attacker.global_position)
	target._apply_visual_pose()
	for damage in [7, 12, 18]:
		game.combat_scene.spawn_damage_number(target.global_position, damage, target.faction)
	await _settle(2)
	await _save(file_name)

func _capture_small_view_combat(attacker: Node, target: Node) -> void:
	var original_text_scale := UISettings.text_scale
	DisplayServer.window_set_size(Vector2i(1366, 768))
	UISettings.set_text_scale(UISettings.MAX_TEXT_SCALE, false)
	game._set_screen(Constants.SCREEN_COMBAT)
	for monster in game.monster_units:
		monster.visible = true
		monster.set_physics_process(true)
	game._spawn_enemy("explorer")
	game.combat_paused = false
	game.combat_speed = 0.75
	await _settle(24)
	await _save("11_live_combat_1366_scale_115.png")
	game.combat_paused = true
	await _capture_damage_number_stack(attacker, target, "12_damage_number_stack_1366_scale_115.png")
	await _capture_dense_small_view_combat()
	UISettings.set_text_scale(original_text_scale, false)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	game._set_screen(Constants.SCREEN_COMBAT)
	await _settle(4)

func _capture_dense_small_view_combat() -> void:
	game.combat_scene.clear_effects()
	game.combat_paused = true
	for enemy in game.enemy_units:
		enemy.visible = false
		enemy.set_physics_process(false)
	var staged_enemies: Array = []
	for enemy_id in ["explorer", "explorer", "explorer", "explorer", "thief"]:
		game._spawn_enemy(enemy_id)
		var enemy = game.enemy_units.back()
		enemy.set_physics_process(false)
		staged_enemies.append(enemy)
	var center: Vector2 = game.graph.center("spike_corridor") + Vector2(0, 48)
	var monster_offsets = [Vector2(-150, -40), Vector2(-120, 45), Vector2(-45, 80)]
	for index in range(min(game.monster_units.size(), monster_offsets.size())):
		var monster = game.monster_units[index]
		monster.visible = true
		monster.set_physics_process(false)
		monster.global_position = center + monster_offsets[index]
		monster.current_room = "spike_corridor"
		monster.stop_navigation()
		monster.set_tactical_state(Constants.UNIT_STATE_ATTACK, "난전 교전", "침입자")
		monster.queue_redraw()
	var enemy_offsets = [Vector2(35, -75), Vector2(125, -35), Vector2(205, 10), Vector2(85, 70), Vector2(190, 105)]
	for index in range(staged_enemies.size()):
		var enemy = staged_enemies[index]
		enemy.visible = true
		enemy.global_position = center + enemy_offsets[index]
		enemy.current_room = "spike_corridor"
		enemy.stop_navigation()
		if enemy.unit_id == "thief":
			enemy.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_ROOM, "보물방 침투", "보물 보관실")
		else:
			enemy.set_tactical_state(Constants.UNIT_STATE_ATTACK, "왕좌 진격", "마왕의 왕좌")
		enemy.queue_redraw()
	var damage_values = [8, 11, 14, 17, 20, 23]
	for index in range(damage_values.size()):
		var target = staged_enemies[index % staged_enemies.size()]
		var offset = Vector2(-12, 0) if index >= staged_enemies.size() else Vector2.ZERO
		game.combat_scene.spawn_damage_number(target.global_position + offset, damage_values[index], target.faction)
	game._select_unit(game.monster_units[1])
	await _settle(3)
	await _save("13_dense_combat_1366_scale_115.png")

func _unit_by_id(units: Array, unit_id: String):
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null

func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame

func _save(file_name: String) -> void:
	var image: Image
	for _attempt in range(6):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var texture = get_viewport().get_texture()
		if texture != null:
			image = texture.get_image()
			if _capture_has_ui(image):
				break
	if image == null or not _capture_has_ui(image):
		push_error("Viewport did not produce a complete UI frame. Run this review without --headless.")
		failed = true
		return
	if file_name.contains("_1366_") and (absi(image.get_width() - 1366) > 1 or image.get_height() != 768):
		push_error("Small-view capture has unexpected size %s: %s" % [image.get_size(), file_name])
		failed = true
		return
	image.convert(Image.FORMAT_RGB8)
	var error = image.save_png(output_dir.path_join(file_name))
	if error != OK:
		push_error("Could not save %s (error %d)." % [file_name, error])
		failed = true

func _capture_has_ui(image: Image) -> bool:
	if image == null:
		return false
	var width := image.get_width()
	var height := image.get_height()
	var sample_y := clampi(roundi(float(height) * 0.04), 0, height - 1)
	var sample_points = [
		Vector2i(roundi(float(width) * 0.025), sample_y),
		Vector2i(roundi(float(width) * 0.073), sample_y),
		Vector2i(roundi(float(width) * 0.18), sample_y),
		Vector2i(roundi(float(width) * 0.34), sample_y),
		Vector2i(roundi(float(width) * 0.65), sample_y),
		Vector2i(roundi(float(width) * 0.81), sample_y)
	]
	var visible_samples := 0
	for point in sample_points:
		var color = image.get_pixelv(point)
		if color.a > 0.80 and max(color.r, max(color.g, color.b)) > 0.20:
			visible_samples += 1
	return visible_samples >= 3
