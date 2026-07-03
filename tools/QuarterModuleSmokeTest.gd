extends Node

const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const SocketValidatorScript = preload("res://scripts/dungeon_quarter/SocketValidator.gd")
const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DataRegistry.load_all()
	_check_data_schema()
	_check_autotile_masks()
	_check_graph(DataRegistry.quarter_starting_layout)
	_check_all_layouts()
	await _check_game_root_integration()

	if failed:
		print("QUARTER_MODULE_SMOKE_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("QUARTER_MODULE_SMOKE_TEST: PASS")
		get_tree().quit(0)

func _check_data_schema() -> void:
	_expect(not DataRegistry.quarter_modules.is_empty(), "quarter blueprints loaded")
	_expect(not DataRegistry.quarter_starting_layout.is_empty(), "starting layout loaded")
	_expect(DataRegistry.quarter_layout_ids().size() >= 2, "custom layout catalog loaded")
	_expect(str(DataRegistry.quarter_starting_layout.get("coordinate_mode", "")) == "logical_grid_v2", "starting layout uses v2 logical grid")
	_expect(str(DataRegistry.quarter_starting_layout.get("room_grid_contract_id", "")) == "cave_f_3x3_chain_01", "starting layout declares 3x3 room-grid contract")
	var room_grid: Dictionary = DataRegistry.quarter_starting_layout.get("room_grid", {})
	var room_grid_size: Array = room_grid.get("grid_size", [])
	_expect(room_grid_size.size() >= 2 and int(room_grid_size[0]) == 3 and int(room_grid_size[1]) == 3, "starting layout uses 3x3 room grid")
	_expect(_has_grid_cell(room_grid, "G00_01", "entrance"), "grid cell G00_01 anchors entrance")
	_expect(_has_grid_cell(room_grid, "G01_01", "spike_corridor"), "grid cell G01_01 anchors trap room")
	_expect(_has_grid_cell(room_grid, "G02_01", "barracks"), "grid cell G02_01 anchors barracks")
	_expect(_has_grid_cell(room_grid, "G02_00", "recovery"), "grid cell G02_00 anchors recovery")
	_expect(_has_grid_cell(room_grid, "G01_00", "treasure"), "grid cell G01_00 anchors treasure")
	_expect(_has_grid_cell(room_grid, "G00_00", "throne"), "grid cell G00_00 anchors throne")
	var max_grid: Array = DataRegistry.quarter_castle_grade_rules.get("max_grid_size", [])
	_expect(max_grid.size() >= 2 and int(max_grid[0]) == 20 and int(max_grid[1]) == 20, "castle rules use fixed 20x20 max grid")
	var grades: Dictionary = DataRegistry.quarter_castle_grade_rules.get("grades", {})
	_expect(grades.has("F") and grades.has("S"), "castle grade rules include F through S range")
	_expect(int(DataRegistry.quarter_tile_variant_manifest.get("floor_mask", {}).size()) == 16, "tile manifest supports 16 floor masks")

	var validator = SocketValidatorScript.new()
	for layout_id in DataRegistry.quarter_layout_ids():
		var result = validator.validate_layout(DataRegistry.quarter_modules, DataRegistry.quarter_layout(str(layout_id)))
		_expect(bool(result.get("ok", false)), "socket validator passes for %s: %s" % [layout_id, str(result.get("errors", []))])

	for module_id in DataRegistry.quarter_modules.keys():
		var module: Dictionary = DataRegistry.quarter_modules[module_id]
		_expect(module.has("floor_cells"), "%s has floor_cells" % module_id)
		_expect(module.has("walk_cells"), "%s has walk_cells" % module_id)
		_expect(module.has("blocked_cells"), "%s has blocked_cells" % module_id)
		_expect(module.has("socket_entries"), "%s has socket_entries" % module_id)
		_expect(module.has("default_socket_states"), "%s has default socket states" % module_id)

func _check_autotile_masks() -> void:
	_expect(AutoTileMaskScript.BITS["N"] == 1, "N bit is 1")
	_expect(AutoTileMaskScript.BITS["E"] == 2, "E bit is 2")
	_expect(AutoTileMaskScript.BITS["S"] == 4, "S bit is 4")
	_expect(AutoTileMaskScript.BITS["W"] == 8, "W bit is 8")
	for mask in range(16):
		var origin = Vector2i(mask * 10, 0)
		var floor_set: Dictionary = {origin: true}
		for side in ["N", "E", "S", "W"]:
			if (mask & int(AutoTileMaskScript.BITS[side])) != 0:
				floor_set[origin + AutoTileMaskScript.DIRS[side]] = true
		_expect(AutoTileMaskScript.get_4bit_mask(origin, floor_set) == mask, "autotile mask %d supported" % mask)

func _check_graph(layout: Dictionary) -> void:
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, layout, DataRegistry.rooms)
	_expect(bool(graph.validation_summary().get("ok", false)), "graph validation passes: %s" % str(graph.validation_summary().get("errors", [])))
	_expect(graph.debug_source_mode() == "v2_cell_data", "walk map uses v2 CellData")
	_expect(graph.debug_astar_cell_shape() == AStarGrid2D.CELL_SHAPE_ISOMETRIC_DOWN, "walk map uses isometric AStarGrid2D cells")
	_expect(graph.debug_tile_grid_size() == Vector2i(20, 20), "graph keeps fixed 20x20 max grid")
	_expect(graph.debug_active_rect().size == _grade_active_rect(layout).size, "active rect comes from grade rules")
	_expect(graph.debug_active_cells().size() == graph.debug_active_rect().size.x * graph.debug_active_rect().size.y, "active cells match active rect")
	_expect(graph.debug_floor_cells().size() > 0, "floor cells are registered")
	_expect(graph.debug_walk_cells().size() > 0, "walkable cells are registered")
	_expect(graph.debug_tile_blocked_cells().is_empty(), "room objects do not block whole grid cells")
	_expect(graph.debug_floor_mask_values().size() > 1, "floor masks are calculated")
	_expect(_has_socket_state(graph, "connected"), "connected sockets are represented")
	_expect(_has_socket_state(graph, "closed"), "closed socket sides are represented")
	_expect(graph.path_between("entrance", "throne").size() == 6, "entrance to throne follows six-room chain")
	_expect(graph.path_between("entrance", "treasure").size() >= 5, "entrance to treasure room path exists")
	_expect(_all_points_walkable(graph, graph.path_to_point(graph.center("entrance"), graph.center("treasure"))), "treasure route stays walkable")
	_expect(graph.is_walkable(graph.clamp_to_walkable(Vector2(40, 40))), "outside point clamps to walkable floor")
	_check_socket_edge_masks(graph)

func _check_all_layouts() -> void:
	for layout_id in DataRegistry.quarter_layout_ids():
		_check_graph(DataRegistry.quarter_layout(str(layout_id)))

func _check_game_root_integration() -> void:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	_expect(game.use_quarter_module_map, "game root uses quarter map")
	_expect(game.quarter_layout_id == DataRegistry.quarter_default_layout_id, "game root uses default quarter layout")
	_expect(game.graph.debug_tile_grid_size() == Vector2i(20, 20), "game root graph uses fixed max grid")
	_expect(game.quarter_renderer != null, "quarter renderer is attached")
	_expect(game.quarter_renderer.uses_tile_grid_renderer(), "quarter renderer uses tile grid path")
	_expect(not game.quarter_renderer.has_module_visuals(), "quarter renderer does not use module PNG visuals")
	_expect(game.quarter_renderer.has_floor_tile_textures(), "quarter renderer loads floor mask textures")
	_expect(game.quarter_renderer.debug_missing_floor_tile_masks().is_empty(), "quarter renderer has no missing floor masks")
	_expect(game.quarter_renderer.has_background_plate_textures(), "quarter renderer loads generated background plate")
	_expect(game.quarter_renderer.debug_missing_background_plates().is_empty(), "quarter renderer has no missing background plates")
	_expect(game.quarter_renderer.has_socket_cap_textures(), "quarter renderer loads socket cap state textures")
	_expect(game.quarter_renderer.debug_missing_socket_caps().is_empty(), "quarter renderer has no missing socket caps")
	_expect(_has_required_layers(game.quarter_renderer.debug_layer_names()), "quarter renderer declares v2 layer order")
	_expect(game.quarter_renderer.debug_tilemap_layer_names().has("BackgroundVoidLayer"), "background void layer exists")
	_expect(game.quarter_renderer.debug_visual_variant_key("recovery").find("s") >= 0, "recovery connected socket state affects visual variant")
	_expect(game.quarter_renderer.debug_socket_state("entrance", "to_s") == "closed", "unconnected entrance socket remains closed")
	_expect(game.quarter_renderer.debug_socket_cap_key("entrance", "to_s") == "closed:S", "closed entrance socket resolves to wall cap")
	_expect(game.quarter_renderer.debug_socket_state("entrance", "to_e") == "connected", "connected entrance socket remains open")
	_expect(game.quarter_renderer.debug_socket_cap_key("entrance", "to_e") == "connected:E", "connected entrance socket resolves to doorway cap")
	game.selected_room = "barracks"
	var gold_before = GameState.gold
	game._change_selected_room_facility("treasure")
	_expect(GameState.gold == gold_before - 120, "facility change still charges cost")
	_expect(_instance_has_object(game.graph, "barracks", "treasure_pile_large"), "facility change updates map object slots")
	_expect(_instance_has_object(game.graph, "treasure", "foundation_marks"), "unique facility replacement becomes build slot object")
	game.quarter_renderer.trigger_trap_animation("spike_corridor", "spike_floor")
	_expect(game.quarter_renderer.debug_active_trap_animation_count() == 1, "trap trigger animation starts")
	game.quarter_renderer.clear_trap_animations()
	game._select_quarter_layout("expanded_right_branch_layout_01")
	_expect(game.quarter_layout_id == "expanded_right_branch_layout_01", "custom layout selection UI callback can switch layout")
	_expect(game.graph.debug_active_rect().size == Vector2i(10, 10), "E grade custom layout expands active rect")
	_expect(game.graph.path_between("entrance", "treasure").size() >= 5, "custom layout keeps treasure path")
	game._open_map_editor()
	_expect(game.map_editor_active, "map editor can enter edit mode")
	game.selected_room = "barracks"
	game._map_editor_disconnect_selected_room()
	_expect(not _layout_has_connection(game.map_editor_layout, "spike_corridor:to_e", "barracks:to_w"), "map editor can disconnect selected room west socket")
	_expect(not _layout_has_connection(game.map_editor_layout, "barracks:to_n", "recovery:to_s"), "map editor can disconnect selected room north socket")
	_expect(game.quarter_renderer.debug_socket_state("barracks", "to_w") == "open_placeholder", "disconnected barracks west socket becomes placeholder")
	_expect(game.quarter_renderer.debug_socket_cap_key("barracks", "to_w") == "open_placeholder:W", "disconnected barracks west socket resolves to placeholder cap")
	_expect(game.quarter_renderer.debug_socket_state("barracks", "to_n") == "open_placeholder", "disconnected barracks north socket becomes placeholder")
	_expect(game.quarter_renderer.debug_socket_cap_key("barracks", "to_n") == "open_placeholder:N", "disconnected barracks north socket resolves to placeholder cap")
	_expect(not game.map_editor_errors.is_empty(), "disconnecting required chain room reports path errors")
	game._map_editor_connect_adjacent_socket()
	game._map_editor_connect_adjacent_socket()
	_expect(_layout_has_connection(game.map_editor_layout, "spike_corridor:to_e", "barracks:to_w"), "map editor can reconnect west adjacent socket")
	_expect(_layout_has_connection(game.map_editor_layout, "barracks:to_n", "recovery:to_s"), "map editor can reconnect north adjacent socket")
	_expect(game.map_editor_errors.is_empty(), "reconnected adjacent sockets keep layout valid")
	game._move_map_editor_room(Vector2i(-1, 0))
	_expect(not game.map_editor_errors.is_empty(), "map editor reports invalid moved layout")
	_expect(not game._save_map_editor_layout(false), "map editor blocks invalid save")
	game._move_map_editor_room(Vector2i(1, 0))
	_expect(game.map_editor_errors.is_empty(), "moving room back restores valid layout")
	var layout_count_before = DataRegistry.quarter_layout_ids().size()
	_expect(game._save_map_editor_layout(false), "map editor can save a valid draft layout")
	_expect(not game.map_editor_active, "map editor exits after save")
	_expect(DataRegistry.quarter_layout_ids().size() == layout_count_before + 1, "saved draft is registered as custom layout")
	game._handle_key(KEY_F3)
	game._handle_key(KEY_F4)
	game._handle_key(KEY_F5)
	game._handle_key(KEY_F6)
	game._handle_key(KEY_F7)
	_expect(game.debug_show_active_overlay, "F3 toggles active overlay")
	_expect(game.debug_show_walkable_overlay, "F4 toggles walkable overlay")
	_expect(game.debug_show_floor_mask_overlay, "F5 toggles floor mask overlay")
	_expect(game.debug_show_socket_overlay, "F6 toggles socket overlay")
	_expect(game.debug_show_room_id_overlay, "F7 toggles room id overlay")
	game.queue_free()
	await get_tree().process_frame

func _check_socket_edge_masks(graph) -> void:
	var cases = [
		["entrance", "to_e", "E"],
		["spike_corridor", "to_w", "W"],
		["spike_corridor", "to_e", "E"],
		["barracks", "to_w", "W"],
		["barracks", "to_n", "N"],
		["recovery", "to_s", "S"],
		["recovery", "to_w", "W"],
		["treasure", "to_e", "E"],
		["treasure", "to_w", "W"],
		["throne", "to_e", "E"]
	]
	for entry in cases:
		var socket = _socket_record(graph, str(entry[0]), str(entry[1]))
		_expect(not socket.is_empty(), "%s:%s socket exists" % [entry[0], entry[1]])
		if socket.is_empty():
			continue
		var mask = graph.debug_floor_mask(socket["cell"])
		var side = str(entry[2])
		_expect((mask & int(AutoTileMaskScript.BITS[side])) != 0, "%s:%s opens %s edge" % [entry[0], entry[1], side])
	var closed_socket = _socket_record(graph, "entrance", "to_s")
	if not closed_socket.is_empty():
		var mask = graph.debug_floor_mask(closed_socket["cell"])
		_expect((mask & int(AutoTileMaskScript.BITS["S"])) == 0, "closed socket side does not count as connected floor")

func _has_grid_cell(room_grid: Dictionary, grid_id: String, instance_id: String) -> bool:
	for cell in room_grid.get("cells", []):
		if not (cell is Dictionary):
			continue
		if str(cell.get("grid_id", "")) == grid_id and str(cell.get("instance_id", "")) == instance_id:
			return true
	return false

func _socket_record(graph, instance_id: String, socket_id: String) -> Dictionary:
	for socket in graph.debug_socket_cells():
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			return socket
	return {}

func _has_socket_state(graph, state: String) -> bool:
	for socket in graph.debug_socket_cells():
		if str(socket.get("state", "")) == state:
			return true
	return false

func _instance_has_object(graph, instance_id: String, object_id: String) -> bool:
	for slot in graph.debug_object_slots():
		if str(slot.get("instance_id", "")) == instance_id and str(slot.get("id", "")) == object_id:
			return true
	return false

func _layout_has_connection(layout: Dictionary, ref_a: String, ref_b: String) -> bool:
	for connection in layout.get("connections", []):
		var from_ref = str(connection.get("from", ""))
		var to_ref = str(connection.get("to", ""))
		if from_ref == ref_a and to_ref == ref_b:
			return true
		if from_ref == ref_b and to_ref == ref_a:
			return true
	return false

func _grade_active_rect(layout: Dictionary) -> Rect2i:
	var grades: Dictionary = DataRegistry.quarter_castle_grade_rules.get("grades", {})
	var grade_rule: Dictionary = grades.get(str(layout.get("castle_grade", "F")), {})
	var rect: Array = grade_rule.get("active_rect", [0, 0, 20, 20])
	return Rect2i(int(rect[0]), int(rect[1]), int(rect[2]), int(rect[3]))

func _has_required_layers(layer_names: Array) -> bool:
	for layer_name in [
		"BackgroundVoidLayer",
		"FloorLayer",
		"EdgeSkirtLayer",
		"BackWallLayer",
		"ObjectBackLayer",
		"UnitYSortLayer",
		"ObjectFrontLayer",
		"FrontWallLayer",
		"FxLayer",
		"UiDebugLayer"
	]:
		if not layer_names.has(layer_name):
			return false
	return true

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
