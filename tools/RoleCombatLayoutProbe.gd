extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const SocketValidatorScript = preload("res://scripts/dungeon_quarter/SocketValidator.gd")

const LAYOUT_PATH := "res://data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json"

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DataRegistry.load_all()

	var layout := _load_json(LAYOUT_PATH)
	_expect(not layout.is_empty(), "role combat test layout loads")
	if layout.is_empty():
		_finish()
		return

	var validator = SocketValidatorScript.new()
	var socket_result: Dictionary = validator.validate_layout(DataRegistry.quarter_modules, layout)
	_expect(bool(socket_result.get("ok", false)), "socket validator passes: %s" % str(socket_result.get("errors", [])))

	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, layout, DataRegistry.rooms)
	_expect(bool(graph.validation_summary().get("ok", false)), "module graph validates: %s" % str(graph.validation_summary().get("errors", [])))
	_expect(graph.debug_tile_grid_size() == Vector2i(28, 26), "layout uses current 28x26 active grid")

	var expected_main_route := [
		"outside_approach",
		"entrance",
		"path_entrance_trap",
		"spike_corridor",
		"path_trap_barracks",
		"barracks",
		"path_barracks_throne",
		"throne"
	]
	var expected_treasure_route := [
		"entrance",
		"path_entrance_trap",
		"spike_corridor",
		"path_trap_barracks",
		"barracks",
		"path_barracks_treasure",
		"treasure"
	]
	var expected_recovery_route := [
		"barracks",
		"path_barracks_recovery",
		"recovery"
	]

	_expect(graph.path_between("outside_approach", "throne") == expected_main_route, "main enemy route is forced through entrance, trap, barracks, throne")
	_expect(graph.path_between("entrance", "treasure") == expected_treasure_route, "treasure lure route branches after barracks")
	_expect(graph.path_between("barracks", "recovery") == expected_recovery_route, "retired monster route reaches recovery side room")

	_expect(_all_points_walkable(graph, graph.path_to_point(graph.center("outside_approach"), graph.center("throne"))), "outside to throne world path stays on floor")
	_expect(_all_points_walkable(graph, graph.path_to_point(graph.center("entrance"), graph.center("treasure"))), "entrance to treasure world path stays on floor")
	_expect(_all_points_walkable(graph, graph.path_to_point(graph.center("barracks"), graph.center("recovery"))), "barracks to recovery world path stays on floor")

	_expect(graph.debug_room_id_for_tile_cell(Vector2i(9, 14)) == "spike_corridor", "trap room keeps combat-compatible spike_corridor instance id")
	_expect(_cell_trap_id(graph, Vector2i(11, 15)) == "spike_floor", "trap room exposes spike_floor trap cells")
	_expect(_object_footprint_size(graph, "barracks", "weapon_rack") >= 25, "barracks combat arena still carries a full-grid room object")
	_expect(_object_footprint_size(graph, "treasure", "treasure_pile_large") >= 25, "treasure lure room still carries a full-grid room object")

	_print_route("MAIN", graph.path_between("outside_approach", "throne"))
	_print_route("TREASURE", graph.path_between("entrance", "treasure"))
	_print_route("RECOVERY", graph.path_between("barracks", "recovery"))
	await _check_game_root_combat(layout)
	_finish()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing layout: %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("Invalid JSON layout: %s" % path)
	return {}

func _cell_trap_id(graph, cell: Vector2i) -> String:
	var cell_data: Dictionary = graph.debug_cell_data()
	var data: Dictionary = cell_data.get(cell, {})
	return str(data.get("trap_id", ""))

func _object_footprint_size(graph, instance_id: String, object_id: String) -> int:
	for slot in graph.debug_object_slots():
		if str(slot.get("instance_id", "")) == instance_id and str(slot.get("id", "")) == object_id:
			return slot.get("footprint", []).size()
	return 0

func _all_points_walkable(graph, points: Array) -> bool:
	if points.is_empty():
		return false
	for point in points:
		if not graph.is_walkable(point):
			return false
	return true

func _print_route(label: String, route: Array) -> void:
	print("%s_ROUTE: %s" % [label, " -> ".join(route)])

func _check_game_root_combat(layout: Dictionary) -> void:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await get_tree().process_frame

	var layout_id := str(layout.get("template_id", "role_driven_combat_layout_test_01"))
	_expect(DataRegistry.register_quarter_layout(layout_id, layout, false), "test layout registers at runtime without persistence")
	_expect(game.set_quarter_layout(layout_id), "GameRoot accepts role combat test layout")
	_expect(game.graph.path_between("outside_approach", "throne") == [
		"outside_approach",
		"entrance",
		"path_entrance_trap",
		"spike_corridor",
		"path_trap_barracks",
		"barracks",
		"path_barracks_throne",
		"throne"
	], "GameRoot graph preserves forced main route")

	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "GameRoot can start combat on role layout")

	game._spawn_enemy("explorer")
	var explorer = _unit_by_id(game.enemy_units, "explorer")
	_expect(explorer != null and explorer.goal_room == "throne", "throne enemy targets final throne room")
	_expect(explorer != null and not explorer.path_points.is_empty(), "throne enemy receives movement path")
	_expect(game.graph.path_between("entrance", "throne") == [
		"entrance",
		"path_entrance_trap",
		"spike_corridor",
		"path_trap_barracks",
		"barracks",
		"path_barracks_throne",
		"throne"
	], "enemy throne route must pass trap and barracks")

	game._spawn_enemy("thief")
	var thief = _unit_by_id(game.enemy_units, "thief")
	_expect(thief != null and thief.goal_room == "treasure", "treasure enemy targets lure branch")
	_expect(thief != null and game.graph.path_between("entrance", thief.goal_room) == [
		"entrance",
		"path_entrance_trap",
		"spike_corridor",
		"path_trap_barracks",
		"barracks",
		"path_barracks_treasure",
		"treasure"
	], "treasure enemy route branches after barracks")

	if explorer != null:
		explorer.current_room = "spike_corridor"
		explorer.global_position = game.graph.center("spike_corridor")
		game.trap_cooldown = 0.0
		var hp_before_trap = explorer.hp
		game._update_room_effects(2.0)
		_expect(explorer.hp < hp_before_trap, "trap room damages enemies in GameRoot combat")

	game.queue_free()
	await get_tree().process_frame

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

func _finish() -> void:
	if failed:
		print("ROLE_COMBAT_LAYOUT_PROBE: FAIL")
		get_tree().quit(1)
	else:
		print("ROLE_COMBAT_LAYOUT_PROBE: PASS")
		get_tree().quit(0)
