extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""
var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://tmp/update3_phase25/bebe")
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game._debug_skip_onboarding()
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game._start_combat()
	await _settle(4)
	game.combat_paused = true
	var bebe = game._create_unit("ghost_housemaid", DataRegistry.monster("ghost_housemaid"), Constants.FACTION_MONSTER, "barracks")
	game.monster_units.append(bebe)
	bebe.global_position = game.graph.center("barracks")
	bebe.current_room = "barracks"
	bebe.assigned_room = "barracks"
	bebe.set_physics_process(false)
	bebe.play_skill()
	game._select_unit(bebe)
	game.combat_scene.spawn_effect_burst("bebe_broom", bebe.global_position, Vector2(0, -22), Vector2(1.2, 1.2), 10.0)
	await _capture(Vector2i(1920, 1080), "bebe_combat_1920x1080.png")
	game.combat_scene.spawn_effect_burst("bebe_rescue", bebe.global_position, Vector2(0, -22), Vector2(1.2, 1.2), 10.0)
	await _capture(Vector2i(1366, 768), "bebe_combat_1366x768.png")
	print("BEBE_PHASE25A_VISUAL_REVIEW: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _capture(size: Vector2i, file_name: String) -> void:
	DisplayServer.window_set_size(size)
	await _settle(8)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or absi(image.get_width() - size.x) > 1 or image.get_height() != size.y:
		failed = true
		push_error("예상 해상도 %s 화면을 얻지 못했습니다: %s" % [size, image.get_size() if image != null else Vector2i.ZERO])
		return
	image.convert(Image.FORMAT_RGB8)
	var error := image.save_png(output_dir.path_join(file_name))
	if error != OK:
		failed = true
		push_error("캡처 저장 실패: %s (오류 %d)" % [file_name, error])


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame
