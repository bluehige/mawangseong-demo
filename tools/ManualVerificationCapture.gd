extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	output_dir = ProjectSettings.globalize_path("res://tmp/manual_verification")
	DirAccess.make_dir_recursive_absolute(output_dir)

	game = GameRootScene.instantiate()
	add_child(game)
	await _settle()
	game._select_room("barracks")
	await _settle()
	await _save("01_management.png")

	game._set_screen(Constants.SCREEN_MONSTER)
	await _settle()
	await _save("02_monster.png")

	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle()
	game._start_combat()
	await _settle()
	game._spawn_ready_enemies(0.2)
	await _settle()
	await _save("03_combat_start.png")

	var trap_enemy = _first_alive_enemy()
	if trap_enemy != null:
		trap_enemy.current_room = "spike_corridor"
		trap_enemy.global_position = game.graph.center("spike_corridor")
		game.trap_cooldown = 0.0
		game._update_room_effects(2.0)
	await _settle()
	await _save("04_combat_trap_trigger.png")

	var imp = _unit_by_id(game.monster_units, "imp")
	if imp != null:
		game._select_unit(imp)
		game._enable_direct_control()
		game._handle_right_click(game.graph.center("spike_corridor"))
		game._handle_key(KEY_1)
	await _settle()
	await _save("05_combat_controls.png")

	game.wave_manager.next_index = game.wave_manager.schedule.size()
	for enemy in game.enemy_units:
		if enemy.is_alive():
			enemy.receive_damage(9999)
	game._check_combat_end()
	await _settle()
	await _save("06_result.png")

	print("MANUAL_VERIFICATION_CAPTURE: %s" % output_dir)
	get_tree().quit(0)

func _settle() -> void:
	for i in range(8):
		await get_tree().process_frame

func _save(file_name: String) -> void:
	await get_tree().process_frame
	var image = get_viewport().get_texture().get_image()
	var path = "%s/%s" % [output_dir, file_name]
	var err = image.save_png(path)
	if err != OK:
		push_error("Failed to save screenshot: %s" % path)

func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null

func _first_alive_enemy() -> Node:
	for unit in game.enemy_units:
		if unit.is_alive():
			return unit
	return null
