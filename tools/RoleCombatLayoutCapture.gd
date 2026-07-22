extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const LAYOUT_PATH := "res://data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json"

var game: Node
var output_dir := ""
var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	output_dir = ProjectSettings.globalize_path("res://tmp/role_combat_verification")
	DirAccess.make_dir_recursive_absolute(output_dir)

	var layout := _load_json(LAYOUT_PATH)
	_expect(not layout.is_empty(), "role combat layout file loads")

	game = GameRootScene.instantiate()
	add_child(game)
	await _settle()
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await _settle()

	var layout_id := str(layout.get("template_id", "role_driven_combat_layout_test_01"))
	_expect(DataRegistry.register_quarter_layout(layout_id, layout, false), "test layout registers without writing custom layouts")
	_expect(game.set_quarter_layout(layout_id), "test layout applied to GameRoot")
	_expect(game.graph.path_between("outside_approach", "throne") == [
		"outside_approach",
		"entrance",
		"path_entrance_trap",
		"spike_corridor",
		"path_trap_barracks",
		"barracks",
		"path_barracks_fallback",
		"fallback",
		"path_fallback_throne",
		"throne"
	], "main route stays forced in capture scene")

	game._select_room("barracks")
	await _settle()
	await _save("01_management_role_layout.png")

	game.debug_show_room_id_overlay = true
	game.debug_show_socket_overlay = true
	game.debug_show_walkable_overlay = true
	game.queue_redraw()
	await _settle()
	await _save("02_management_role_debug_overlay.png")

	game._start_combat()
	await _settle()
	game._spawn_enemy("explorer")
	game._spawn_enemy("thief")
	await _settle()

	var explorer = _unit_by_id(game.enemy_units, "explorer")
	var thief = _unit_by_id(game.enemy_units, "thief")
	_expect(explorer != null and explorer.goal_room == "throne", "explorer targets throne")
	_expect(thief != null and thief.goal_room == "treasure", "thief targets treasure lure branch")

	game.debug_show_path_overlay = true
	if explorer != null:
		game._select_unit(explorer)
	await _settle()
	await _save("03_combat_explorer_throne_path.png")

	if thief != null:
		game._select_unit(thief)
	await _settle()
	await _save("04_combat_thief_treasure_path.png")

	if explorer != null:
		explorer.current_room = "spike_corridor"
		explorer.global_position = game.graph.center("spike_corridor")
		game.trap_cooldown = 0.0
		var hp_before_trap = explorer.hp
		game._update_room_effects(2.0)
		_expect(explorer.hp < hp_before_trap, "trap room damages enemy during capture")
	await _settle()
	await _save("05_combat_trap_trigger.png")

	print("ROLE_COMBAT_LAYOUT_CAPTURE: %s" % output_dir)
	if failed:
		print("ROLE_COMBAT_LAYOUT_CAPTURE: FAIL")
		get_tree().quit(1)
	else:
		print("ROLE_COMBAT_LAYOUT_CAPTURE: PASS")
		get_tree().quit(0)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing layout: %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("Invalid JSON layout: %s" % path)
	return {}

func _settle() -> void:
	for i in range(10):
		await get_tree().process_frame
		await get_tree().physics_frame

func _save(file_name: String) -> void:
	await get_tree().process_frame
	var texture = get_viewport().get_texture()
	if texture == null:
		push_error("Viewport texture is null. Run this capture without --headless.")
		failed = true
		return
	var image = texture.get_image()
	if image == null:
		push_error("Viewport image is null. Run this capture without --headless.")
		failed = true
		return
	var path = "%s/%s" % [output_dir, file_name]
	var err = image.save_png(path)
	if err != OK:
		push_error("Failed to save screenshot: %s" % path)
		failed = true

func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
