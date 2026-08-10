extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const STAGES := ["stage_02_castle", "stage_04_citadel"]
const VIEWPORT_SIZE := Vector2i(1920, 1080)
const OUTPUT_DIR := "res://tmp/v125_stage_progression_combat"

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(VIEWPORT_SIZE)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var records: Array[Dictionary] = []
	for stage_id in STAGES:
		var game = await _prepare_stage(stage_id)
		if game == null:
			failed = true
			continue
		var staged := await _stage_combat_contact(game)
		var file_name := "%s_combat_1920x1080.png" % stage_id
		await _save(game, file_name)
		records.append({
			"stage_id": stage_id,
			"renderer_stage_id": game.quarter_renderer.debug_active_castle_art_stage(),
			"monster_count": game.monster_units.size(),
			"enemy_count": game.enemy_units.size(),
			"staged_unit_count": staged,
			"screenshot": OUTPUT_DIR.trim_prefix("res://").path_join(file_name)
		})
		game.queue_free()
		await _settle(4)
	_write_report(records)
	print("V125_STAGE_PROGRESSION_COMBAT_VISUAL_REVIEW: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _prepare_stage(stage_id: String):
	var game = GameRootScene.instantiate()
	game.campaign_save_enabled = false
	game.story_feature_enabled = false
	add_child(game)
	await _settle(18)
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await _settle(8)
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
	game.castle_art_stage = stage_id
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	game._init_room_directives()
	game.quarter_renderer.refresh_layout()
	game._start_combat()
	await _settle(18)
	if game.current_screen != Constants.SCREEN_COMBAT:
		push_error("%s 전투 화면 진입 실패" % stage_id)
		game.queue_free()
		await _settle(2)
		return null
	game.combat_paused = true
	return game


func _stage_combat_contact(game: Node) -> int:
	for enemy in game.enemy_units:
		enemy.visible = false
		enemy.set_physics_process(false)
	for enemy_id in ["explorer", "explorer", "explorer", "explorer", "thief"]:
		game._spawn_enemy(enemy_id)
	var monsters: Array = game.monster_units.slice(0, mini(3, game.monster_units.size()))
	var enemies: Array = game.enemy_units.slice(maxi(0, game.enemy_units.size() - 5))
	var center: Vector2 = game.graph.center("spike_corridor") + Vector2(0, 38)
	var monster_offsets := [Vector2(-150, -16), Vector2(-88, 56), Vector2(-12, -4)]
	var enemy_offsets := [Vector2(58, -58), Vector2(132, -6), Vector2(205, 48), Vector2(92, 86), Vector2(222, 106)]
	for index in range(monsters.size()):
		var monster = monsters[index]
		monster.visible = true
		monster.set_physics_process(false)
		monster.set_process(false)
		monster.global_position = game._clamp_to_combat_walkable(center + monster_offsets[index])
		monster.current_room = "spike_corridor"
		monster.stop_navigation()
		monster.velocity = Vector2(80, 0) if index == 1 else Vector2.ZERO
		monster._apply_visual_pose()
		monster.refresh_depth_slot()
	for index in range(enemies.size()):
		var enemy = enemies[index]
		enemy.visible = true
		enemy.set_physics_process(false)
		enemy.set_process(false)
		enemy.global_position = game._clamp_to_combat_walkable(center + enemy_offsets[index])
		enemy.current_room = "spike_corridor"
		enemy.stop_navigation()
		enemy.velocity = Vector2(-70, 0) if index == 2 else Vector2.ZERO
		enemy._apply_visual_pose()
		enemy.refresh_depth_slot()
	if not monsters.is_empty() and not enemies.is_empty():
		monsters[0].mark_action_target(enemies[0])
		monsters[0].play_attack(enemies[0].global_position)
		monsters[0].attack_anim_timer = 0.21
		enemies[0].play_hit(monsters[0].global_position)
		monsters[0]._apply_visual_pose()
		enemies[0]._apply_visual_pose()
		game.combat_scene.spawn_damage_number(enemies[0].global_position, 18, enemies[0].faction, enemies[0])
	if enemies.size() >= 3:
		game.combat_scene.spawn_damage_number(enemies[1].global_position, 12, enemies[1].faction, enemies[1])
		game.combat_scene.spawn_damage_number(enemies[2].global_position, 24, enemies[2].faction, enemies[2])
	if monsters.size() >= 2:
		game._select_unit(monsters[1])
	game.queue_redraw()
	await _settle(10)
	return monsters.size() + enemies.size()


func _save(game: Node, file_name: String) -> void:
	var image: Image
	for _attempt in range(8):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var texture := get_viewport().get_texture()
		if texture != null:
			image = texture.get_image()
			if _capture_has_ui(game, image):
				break
	if image == null or not _capture_has_ui(game, image):
		push_error("완전한 전투 UI 프레임을 얻지 못했습니다: %s" % file_name)
		failed = true
		return
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR).path_join(file_name))
	if error != OK:
		push_error("전투 화면 저장 실패: %s" % file_name)
		failed = true


func _capture_has_ui(game: Node, image: Image) -> bool:
	return (
		image != null
		and not image.is_empty()
		and image.get_size() == VIEWPORT_SIZE
		and game.current_screen == Constants.SCREEN_COMBAT
		and game.ui_layer != null
		and game.ui_layer.get_child_count() > 0
	)


func _write_report(records: Array[Dictionary]) -> void:
	var report := {
		"viewport": [VIEWPORT_SIZE.x, VIEWPORT_SIZE.y],
		"save_writes_disabled": true,
		"stages": records
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT_DIR).path_join("latest.json"), FileAccess.WRITE)
	if file == null:
		push_error("전투 그래픽 검수 보고서 저장 실패")
		failed = true
		return
	file.store_string(JSON.stringify(report, "  "))
	file.store_string("\n")
	file.close()


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
