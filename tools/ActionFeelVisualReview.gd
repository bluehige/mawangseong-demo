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

	for monster in game.monster_units:
		monster.visible = true
		monster.set_physics_process(true)
		monster.sprite.play()
	explorer.set_physics_process(true)
	game.combat_paused = false
	game.combat_speed = 0.75
	await _settle(50)
	await _save("04_live_combat.png")

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
	image.convert(Image.FORMAT_RGB8)
	var error = image.save_png(output_dir.path_join(file_name))
	if error != OK:
		push_error("Could not save %s (error %d)." % [file_name, error])
		failed = true

func _capture_has_ui(image: Image) -> bool:
	if image == null:
		return false
	var sample_points = [
		Vector2i(48, 44),
		Vector2i(140, 43),
		Vector2i(350, 43),
		Vector2i(650, 43),
		Vector2i(1240, 43),
		Vector2i(1550, 43)
	]
	var visible_samples := 0
	for point in sample_points:
		var color = image.get_pixelv(point)
		if color.a > 0.80 and max(color.r, max(color.g, color.b)) > 0.20:
			visible_samples += 1
	return visible_samples >= 3
