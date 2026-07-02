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
	_expect(not DataRegistry.quarter_tile_variant_manifest.is_empty(), "quarter tile manifest loaded")
	_expect(not DataRegistry.quarter_castle_grade_rules.is_empty(), "quarter castle grade rules loaded")
	_expect(not DataRegistry.quarter_asset_manifest.is_empty(), "quarter asset manifest loaded")
	_expect(str(DataRegistry.quarter_starting_layout.get("coordinate_mode", "")) == "tile_grid", "starting layout uses tile grid coordinates")
	_expect(int(DataRegistry.quarter_tile_variant_manifest.get("floor_mask", {}).size()) == 16, "tile manifest supports 16 floor masks")
	_check_wall_mask_manifest()
	_expect(DataRegistry.quarter_castle_grade_rules.has("F"), "castle grade F exists")
	_expect(DataRegistry.quarter_castle_grade_rules.has("A"), "castle grade A exists")

	var validator = SocketValidatorScript.new()
	var result = validator.validate_layout(DataRegistry.quarter_modules, DataRegistry.quarter_starting_layout)
	_expect(bool(result.get("ok", false)), "socket layout validation passes: %s" % str(result.get("errors", [])))
	_expect(int(result.get("placed_count", 0)) >= 8, "starting layout has current demo modules")
	_expect(int(result.get("connection_count", 0)) >= 7, "starting layout has connected sockets")
	for module_id in DataRegistry.quarter_modules.keys():
		var module: Dictionary = DataRegistry.quarter_modules[module_id]
		_expect(module.has("floor_cells"), "%s has floor_cells" % module_id)
		_expect(module.has("walk_cells"), "%s has walk_cells" % module_id)
		_expect(module.has("blocked_cells"), "%s has blocked_cells" % module_id)
		_expect(module.has("object_slots"), "%s has object_slots" % module_id)
	_check_autotile_masks()

func _check_module_graph() -> void:
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, DataRegistry.quarter_starting_layout, DataRegistry.rooms)
	_expect(bool(graph.validation_summary().get("ok", false)), "module graph validation summary is ok")
	_expect(graph.debug_source_mode() == "tile_grid_blueprints", "walk map is built from tile grid blueprints")
	_expect(graph.debug_astar_cell_shape() == AStarGrid2D.CELL_SHAPE_ISOMETRIC_DOWN, "walk map uses AStarGrid2D isometric diamond cells")
	_expect(graph.debug_walkable_rects().size() > 0, "module walk cells are registered")
	_expect(graph.debug_blocked_rects().size() > 0, "module block cells are registered")
	_expect(graph.debug_floor_cells().size() > 0, "tile grid floor cells are registered")
	_expect(graph.debug_floor_mask_values().size() > 1, "tile grid floor masks are calculated")
	_expect(graph.debug_socket_cells().size() >= 7, "tile grid socket cells are registered")
	_expect(graph.debug_tile_grid_size() == Vector2i(8, 8), "F grade demo tile grid is 8x8")

	var blocked_rects = graph.debug_blocked_rects()
	if not blocked_rects.is_empty():
		_expect(not graph.is_walkable(blocked_rects[0].get_center()), "module blocked cell is not walkable")

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
	_expect(game.graph.debug_source_mode() == "tile_grid_blueprints", "game root walk map uses tile grid blueprints")
	_expect(game.graph.path_points("entrance", "throne").size() > 4, "game root graph returns expanded path")
	_expect(game.quarter_renderer != null, "quarter placeholder renderer is attached")
	_expect(game.quarter_renderer.uses_tile_grid_renderer(), "quarter renderer uses tile grid path")
	_expect(not game.quarter_renderer.has_module_visuals(), "quarter renderer does not use module PNG visuals")
	_expect(game.quarter_renderer.debug_loaded_visual_count() == 0, "quarter renderer has no module visual textures")
	_expect(game.quarter_renderer.has_floor_tile_textures(), "quarter renderer uses generated floor tile textures")
	_expect(game.quarter_renderer.debug_loaded_floor_tile_count() == 16, "quarter renderer loads 16 floor tile masks")
	_expect(game.quarter_renderer.debug_missing_floor_tile_masks().is_empty(), "quarter renderer has no missing floor tile masks")
	_expect(game.quarter_renderer.has_addon_tile_textures(), "quarter renderer uses generated edge wall door overlay textures")
	_expect(game.quarter_renderer.debug_loaded_addon_tile_count() == 16, "quarter renderer loads 16 tile add-on textures")
	_expect(game.quarter_renderer.debug_missing_addon_tiles().is_empty(), "quarter renderer has no missing tile add-on textures")
	_expect(game.quarter_renderer.has_wall_mask_tile_textures(), "quarter renderer uses generated wall mask textures")
	_expect(game.quarter_renderer.debug_loaded_wall_mask_tile_count() == 16, "quarter renderer loads 16 wall mask textures")
	_expect(game.quarter_renderer.debug_missing_wall_mask_tile_masks().is_empty(), "quarter renderer has no missing wall mask textures")
	_expect(game.quarter_renderer.uses_tile_map_layers(), "quarter renderer renders floor with TileMapLayer nodes")
	_expect(game.quarter_renderer.debug_tilemap_layer_names().has("FloorLayer"), "quarter renderer has a TileMapLayer floor layer")
	_expect(game.quarter_renderer.debug_tilemap_layer_names().has("BackWallLayer"), "quarter renderer keeps a separate wall layer node")
	_expect(game.quarter_renderer.debug_wall_cell_count() == 0, "quarter renderer does not place broad wall masks over connected floors")
	_check_socket_visual_masks(game.quarter_renderer)
	_check_non_socket_adjacency_is_walled(game.quarter_renderer)
	_expect(game.quarter_renderer.has_object_sprite_textures(), "quarter renderer uses generated object slot textures")
	_expect(game.quarter_renderer.debug_loaded_object_sprite_count() >= 13, "quarter renderer loads object slot and trap textures")
	_expect(game.quarter_renderer.debug_missing_object_sprites().is_empty(), "quarter renderer has no missing object slot textures")
	game.quarter_renderer.trigger_trap_animation("spike_corridor", "spike_floor")
	_expect(game.quarter_renderer.debug_active_trap_animation_count() == 1, "quarter renderer tracks active spike trigger animation")
	_expect(game.quarter_renderer.debug_current_trap_texture_key("spike_corridor", "spike_floor").begins_with("trap:spike_floor:trigger:"), "quarter renderer selects spike trigger frame")
	game.quarter_renderer.clear_trap_animations()
	_expect(game.quarter_renderer.debug_floor_cell_count() > 0, "quarter renderer draws blueprint floor cells")
	_expect(game.quarter_renderer.debug_floor_mask_values().size() > 1, "quarter renderer calculates floor masks")
	_expect(_has_required_layers(game.quarter_renderer.debug_layer_names()), "quarter renderer declares required layer order")
	_expect(game.quarter_renderer.debug_visual_variant_key("entrance") == "ne", "entrance visual variant key reflects open sockets")
	_expect(game.quarter_renderer.debug_visual_variant_key("spike_corridor") == "ne_sw", "spike corridor visual variant key reflects open sockets")
	_expect(game.quarter_renderer.debug_visual_variant_key("throne") == "sw", "throne visual variant key reflects open socket")
	_expect(game.quarter_renderer.debug_visual_variant_key("slot_01") == "nw_sw", "build slot visual variant key reflects open sockets")
	_expect(not game.debug_show_quarter_module_overlay, "quarter module outline overlay defaults off")
	game._handle_key(KEY_F2)
	game._handle_key(KEY_F3)
	game._handle_key(KEY_F4)
	game._handle_key(KEY_F5)
	game._handle_key(KEY_F6)
	game._handle_key(KEY_F7)
	game._handle_key(KEY_F8)
	game._handle_key(KEY_F9)
	game.queue_redraw()
	await get_tree().process_frame
	_expect(game.debug_show_socket_overlay, "socket debug overlay toggles on")
	_expect(game.debug_show_quarter_module_overlay, "quarter module outline overlay toggles on")
	_expect(game.debug_show_walkable_overlay, "walkable debug overlay toggles on")
	_expect(game.debug_show_floor_mask_overlay, "floor mask debug overlay toggles on")
	_expect(game.debug_show_room_id_overlay, "room id debug overlay toggles on")
	_expect(game.debug_show_blocked_overlay, "blocked debug overlay toggles on")
	_expect(game.debug_show_cursor_cell, "cursor cell debug overlay toggles on")
	_expect(game.debug_show_path_overlay, "path debug overlay toggles on")
	game.queue_free()
	await get_tree().process_frame

func _check_autotile_masks() -> void:
	for mask in range(16):
		var origin = Vector2i(mask * 10, 0)
		var floor_set: Dictionary = {origin: true}
		for direction_name in AutoTileMaskScript.DIRS.keys():
			if (mask & int(AutoTileMaskScript.BITS[direction_name])) != 0:
				floor_set[origin + AutoTileMaskScript.DIRS[direction_name]] = true
		_expect(AutoTileMaskScript.get_4bit_mask(origin, floor_set) == mask, "autotile mask %d supported" % mask)

func _check_wall_mask_manifest() -> void:
	var wall_mask: Dictionary = DataRegistry.quarter_tile_variant_manifest.get("wall_mask", {})
	_expect(wall_mask.size() == 16, "tile manifest supports 16 wall masks")
	for mask in range(16):
		var entry: Dictionary = wall_mask.get(str(mask), {})
		var expected_file := "wall_cave_f_mask_%02d.png" % mask
		var file_hint := str(entry.get("file_hint", ""))
		_expect(file_hint == expected_file, "wall mask %d filename follows autotile order" % mask)
		_expect(ResourceLoader.exists("res://assets/tiles/cave_f/wall/%s" % file_hint), "wall mask %d texture exists" % mask)

func _check_socket_visual_masks(renderer) -> void:
	var cases = [
		["entrance", "to_spike", "NE"],
		["spike_corridor", "to_entrance", "SW"],
		["spike_corridor", "to_center", "NE"],
		["center", "to_spike", "SW"],
		["center", "to_barracks", "NW"],
		["center", "to_recovery", "SE"],
		["slot_01", "to_treasure", "SW"],
		["treasure", "to_slot", "NE"]
	]
	for entry in cases:
		var mask = renderer.debug_visual_mask_for_socket(str(entry[0]), str(entry[1]))
		var side = str(entry[2])
		_expect((mask & int(AutoTileMaskScript.BITS[side])) != 0, "%s:%s keeps %s side open" % [entry[0], entry[1], side])

func _check_non_socket_adjacency_is_walled(renderer) -> void:
	var cases = [
		[Vector2i(5, 2), "SE", "center upper-right edge stays walled without recovery socket"],
		[Vector2i(6, 2), "NW", "recovery upper-left edge stays walled without center socket"],
		[Vector2i(2, 2), "SE", "barracks upper-right edge stays walled without center socket"],
		[Vector2i(3, 2), "NW", "center upper-left edge stays walled without barracks socket"]
	]
	for entry in cases:
		_expect(not renderer.debug_edge_open(entry[0], str(entry[1])), str(entry[2]))

func _has_required_layers(layer_names: Array) -> bool:
	for layer_name in [
		"FloorLayer",
		"EdgeLayer",
		"BackWallLayer",
		"DoorBackLayer",
		"ObjectBackLayer",
		"UnitYSortLayer",
		"ObjectFrontLayer",
		"FrontWallLayer",
		"TrapEffectLayer",
		"DebugOverlayLayer"
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
