extends Node

const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const SocketValidatorScript = preload("res://scripts/dungeon_quarter/SocketValidator.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DataRegistry.load_all()
	_check_data_and_validator()
	_check_module_graph()
	await _check_game_root_integration()

	if failed:
		print("QUARTER_MODULE_SMOKE_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("QUARTER_MODULE_SMOKE_TEST: PASS")
		get_tree().quit(0)

func _check_data_and_validator() -> void:
	_expect(not DataRegistry.quarter_modules.is_empty(), "quarter module data loaded")
	_expect(not DataRegistry.quarter_starting_layout.is_empty(), "quarter layout data loaded")

	var validator = SocketValidatorScript.new()
	var result = validator.validate_layout(DataRegistry.quarter_modules, DataRegistry.quarter_starting_layout)
	_expect(bool(result.get("ok", false)), "socket layout validation passes: %s" % str(result.get("errors", [])))
	_expect(int(result.get("placed_count", 0)) >= 8, "starting layout has current demo modules")
	_expect(int(result.get("connection_count", 0)) >= 7, "starting layout has connected sockets")

func _check_module_graph() -> void:
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, DataRegistry.quarter_starting_layout, DataRegistry.rooms)
	_expect(bool(graph.validation_summary().get("ok", false)), "module graph validation summary is ok")

	var throne_path = graph.path_between("entrance", "throne")
	var treasure_path = graph.path_between("entrance", "treasure")
	_expect(throne_path.size() >= 4, "entrance to throne module path exists")
	_expect(treasure_path.size() >= 4, "entrance to treasure module path exists")

	var throne_points = graph.path_points("entrance", "throne")
	_expect(throne_points.size() > throne_path.size(), "room path expands into walk-map points")
	_expect(_all_points_walkable(graph, throne_points), "expanded throne path stays on walkable floor")

	var treasure_route = graph.path_to_point(graph.center("entrance"), graph.center("treasure"))
	_expect(treasure_route.size() > 4, "point path to treasure uses walk map")
	_expect(_all_points_walkable(graph, treasure_route), "treasure route stays on walkable floor")

	var outside_point = Vector2(40, 40)
	var clamped = graph.clamp_to_walkable(outside_point)
	_expect(graph.is_walkable(clamped), "outside world point clamps to walkable floor")

func _check_game_root_integration() -> void:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	_expect(game.use_quarter_module_map, "game root has quarter module flag enabled")
	_expect(game.graph != null and game.graph.has_method("path_to_point"), "game root uses module graph path API")
	_expect(game.graph.path_points("entrance", "throne").size() > 4, "game root graph returns expanded path")
	game.queue_free()
	await get_tree().process_frame

func _all_points_walkable(graph, points: Array) -> bool:
	if points.is_empty():
		return false
	for point in points:
		if not graph.is_walkable(point):
			return false
	return true

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
