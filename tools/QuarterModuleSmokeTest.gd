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
	await _check_castle_stage_expansions()

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
	_expect(str(DataRegistry.quarter_starting_layout.get("room_grid_contract_id", "")) == "novice_4x4_grid_5x5_gap2_paths_01", "starting layout declares spaced 4x4/5x5 gap-path contract")
	var room_grid: Dictionary = DataRegistry.quarter_starting_layout.get("room_grid", {})
	var room_grid_size: Array = room_grid.get("grid_size", [])
	_expect(room_grid_size.size() >= 2 and int(room_grid_size[0]) == 4 and int(room_grid_size[1]) == 4, "starting layout uses 4x4 room grid")
	var macro_cell_size: Array = room_grid.get("cell_size", [])
	_expect(macro_cell_size.size() >= 2 and int(macro_cell_size[0]) == 5 and int(macro_cell_size[1]) == 5, "each room grid uses 5x5 master cells")
	var gap_size: Array = room_grid.get("gap_size", [])
	_expect(gap_size.size() >= 2 and int(gap_size[0]) == 2 and int(gap_size[1]) == 2, "room grid reserves 2-cell path gaps")
	_expect(_has_grid_cell(room_grid, "G00_02", "entrance"), "grid cell G00_02 anchors entrance")
	_expect(_has_grid_cell(room_grid, "G00_01", "barracks"), "grid cell G00_01 anchors barracks")
	_expect(_has_grid_cell(room_grid, "G02_01", "recovery"), "grid cell G02_01 anchors recovery")
	_expect(_has_grid_cell(room_grid, "G02_02", "treasure"), "grid cell G02_02 anchors treasure")
	_expect(_has_grid_cell(room_grid, "G01_00", "throne"), "grid cell G01_00 anchors throne")
	_expect(_has_grid_cell(room_grid, "G01_03", "slot_01"), "grid cell G01_03 anchors build slot")
	_expect(_has_placed_module(DataRegistry.quarter_starting_layout, "spike_corridor", "PATH_GAP_NETWORK"), "spike corridor is the gap path network, not a room-grid cell")
	_expect(_has_placed_module(DataRegistry.quarter_starting_layout, "outside_approach", "OUTSIDE_W"), "outside approach module connects entrance to the exterior")
	_expect(not _has_placed_instance(DataRegistry.quarter_starting_layout, "watch_post"), "starting layout has six room-grid rooms and no watch post")
	var max_grid: Array = DataRegistry.quarter_castle_grade_rules.get("max_grid_size", [])
	_expect(max_grid.size() >= 2 and int(max_grid[0]) == 28 and int(max_grid[1]) == 26, "castle rules use 28x26 max grid including west outside approach")
	var grades: Dictionary = DataRegistry.quarter_castle_grade_rules.get("grades", {})
	_expect(grades.has("F") and grades.has("S"), "castle grade rules include F through S range")
	_expect(int(DataRegistry.quarter_tile_variant_manifest.get("floor_mask", {}).size()) == 16, "tile manifest supports 16 floor masks")
	var rejected_policy: Dictionary = DataRegistry.quarter_asset_manifest.get("rejected_visual_material_policy", {})
	_expect(str(rejected_policy.get("status", "")) == "active", "rejected visual material quarantine policy is active")
	_expect(bool(rejected_policy.get("historical_only", false)), "rejected visuals are historical-only material")
	_expect(bool(rejected_policy.get("must_not_slice", false)), "rejected visuals must not be sliced into runtime assets")
	_expect(str(rejected_policy.get("new_raster_asset_route", "")).find("built-in image_gen") >= 0, "new raster assets must use built-in image_gen after a numbered contract")
	var rejected_examples: Array = rejected_policy.get("do_not_present_as_examples", [])
	_expect(rejected_examples.has("docs/concepts/spaced_grid_source_layout_concept_overlay_2026-07-06.png"), "failed spaced-grid overlay is quarantined")
	_expect(rejected_examples.has("tmp/manual_verification/01_management.png"), "failed/current management capture is quarantined as an example")
	_expect(rejected_examples.has("docs/concepts/full_grid_path_connection_gpt_image2_concept_2026-07-06.png"), "superseded GPT Image 2 path concept is quarantined")
	var rejected_runtime_sprites: Array = rejected_policy.get("must_not_load_as_runtime_sprites", [])
	_expect(rejected_runtime_sprites.has("assets/props/full_grid_rooms/room_entrance_e_full_grid.png"), "rejected full-grid entrance sprite is blocked from runtime loading")
	_expect(rejected_runtime_sprites.has("assets/props/full_grid_rooms/room_throne_s_full_grid.png"), "rejected full-grid throne sprite is blocked from runtime loading")
	_expect(rejected_runtime_sprites.has("assets/props/full_grid_rooms/room_build_slot_n_full_grid.png"), "rejected full-grid build-slot sprite is blocked from runtime loading")
	var proof_only_policy: Dictionary = DataRegistry.quarter_asset_manifest.get("proof_only_visual_material_policy", {})
	_expect(str(proof_only_policy.get("status", "")) == "active", "fresh proof-only visual material policy is active")
	_expect(bool(proof_only_policy.get("must_not_load_as_runtime_sprites", false)), "fresh proof-only visuals must not load as runtime sprites")
	_expect(bool(proof_only_policy.get("approval_required_before_slicing", false)), "fresh proof-only visuals require approval before slicing")
	var proof_only_entries: Array = proof_only_policy.get("proofs", [])
	_expect(_proof_only_entries_have_path(proof_only_entries, "docs/concepts/path_door_exterior_mouth_proof_01.png"), "path exterior proof 01 is proof-only")
	_expect(_proof_only_entries_have_path(proof_only_entries, "docs/concepts/path_door_exterior_mouth_proof_02.png"), "path exterior proof 02 is proof-only")
	_expect(str(DataRegistry.quarter_asset_manifest.get("facing_sprite_visual_status", "")) == "unverified_direction_placeholder", "current v3 facing sprites are marked as unverified visual placeholders")
	_expect(bool(DataRegistry.quarter_asset_manifest.get("reject_duplicate_or_near_identical_facings", false)), "facing sprite contract rejects duplicate or near-identical direction variants")
	var facing_direction_rule: Dictionary = DataRegistry.quarter_asset_manifest.get("facing_direction_rule", {})
	_expect(str(facing_direction_rule.get("NW", "")).find("front faces northwest") >= 0, "NW means object front faces northwest")
	_expect(str(facing_direction_rule.get("NE", "")).find("front faces northeast") >= 0, "NE means object front faces northeast")
	_expect(str(facing_direction_rule.get("SE", "")).find("front faces southeast") >= 0, "SE means object front faces southeast")
	_expect(str(facing_direction_rule.get("SW", "")).find("front faces southwest") >= 0, "SW means object front faces southwest")
	var production_contract: Dictionary = DataRegistry.quarter_asset_manifest.get("room_object_production_contract", {})
	_expect(str(production_contract.get("contract_id", "")) == "full_grid_room_object_variants_01", "full-grid room object production contract is declared")
	_expect(str(production_contract.get("projection", "")) == "iso_diamond_5x5", "production room objects require iso diamond 5x5 projection")
	_expect(int(production_contract.get("open_mask_count", 0)) == 16, "production room objects support 16 N/E/S/W opening masks")
	_expect(int(production_contract.get("variants_per_role_per_layer", 0)) == 64, "production count is four facings times sixteen opening masks per layer")
	var open_mask_bits: Dictionary = production_contract.get("open_mask_bits", {})
	_expect(int(open_mask_bits.get("N", 0)) == 1 and int(open_mask_bits.get("E", 0)) == 2 and int(open_mask_bits.get("S", 0)) == 4 and int(open_mask_bits.get("W", 0)) == 8, "production open-mask bits match canonical N/E/S/W rule")
	_expect(not production_contract.has("example_proof_image_path"), "quarantined room proof image is not an active production-contract target")
	_expect(not production_contract.has("remaining_proof_image_path"), "quarantined remaining-room proof image is not an active production-contract target")
	_expect(str(production_contract.get("active_proof_status", "")) == "none_after_failed_visual_material_quarantine", "room object contract has no active visual proof after quarantine")
	var next_room_proof: Dictionary = production_contract.get("next_fresh_proof_required", {})
	_expect(str(next_room_proof.get("route", "")).find("built-in image_gen") >= 0, "next room proof must use built-in image_gen route")
	_expect(bool(next_room_proof.get("must_not_reuse_quarantined_visuals", false)), "next room proof cannot reuse quarantined visuals")
	_expect(bool(next_room_proof.get("approval_required_before_slicing", false)), "next room proof requires approval before slicing")
	var first_proof_object_ids: Array = production_contract.get("first_proof_object_ids", [])
	_expect(first_proof_object_ids.has("throne_f") and first_proof_object_ids.has("entrance_gate_f"), "first proof set includes throne and dungeon entrance")
	var remaining_proof_object_ids: Array = production_contract.get("remaining_proof_object_ids", [])
	_expect(remaining_proof_object_ids.has("weapon_rack") and remaining_proof_object_ids.has("recovery_nest_f") and remaining_proof_object_ids.has("treasure_pile_large") and remaining_proof_object_ids.has("foundation_marks"), "remaining proof set includes barracks, recovery, treasure, and build slot")
	var proof_stage_order: Array = production_contract.get("proof_stage_order", [])
	_expect(proof_stage_order.size() >= 5 and str(proof_stage_order[0]) == "composition_throne_plus_dungeon_entrance", "production proof order starts with throne plus dungeon entrance composition")
	var default_variants: Dictionary = production_contract.get("default_layout_required_variants", {})
	_expect(default_variants.size() == 6, "default layout declares six required production room-object variants")
	_expect(_production_variant_matches(default_variants, "throne", "throne_f", "SW", 4), "throne production variant is SW open_04")
	_expect(_production_variant_matches(default_variants, "barracks", "weapon_rack", "SE", 2), "barracks production variant is SE open_02")
	_expect(_production_variant_matches(default_variants, "recovery", "recovery_nest_f", "NW", 8), "recovery production variant is NW open_08")
	_expect(_production_variant_matches(default_variants, "entrance", "entrance_gate_f", "SE", 10), "entrance production variant is SE open_10 for east path plus west exterior")
	_expect(_production_variant_matches(default_variants, "treasure", "treasure_pile_large", "NW", 8), "treasure production variant is NW open_08")
	_expect(_production_variant_matches(default_variants, "slot_01", "foundation_marks", "NE", 1), "build slot production variant is NE open_01")
	var path_contract: Dictionary = DataRegistry.quarter_asset_manifest.get("path_connection_production_contract", {})
	_expect(str(path_contract.get("contract_id", "")) == "spaced_grid_gap_path_connections_01", "spaced-grid gap path connection production contract is declared")
	_expect(str(path_contract.get("projection", "")) == "iso_diamond_5x5", "path connection contract requires iso diamond projection")
	_expect(not bool(path_contract.get("empty_macro_cells_are_floor", true)), "empty macro cells are not treated as floor in path contract")
	_expect(int(path_contract.get("path_width_cells", 0)) == 2, "path connection contract keeps two-cell-wide paths")
	_expect(str(path_contract.get("corridor_instance_id", "")) == "spike_corridor", "path connection contract uses spike corridor instance")
	_expect(int(path_contract.get("required_connection_bridge_count", 0)) == 14, "path contract records fourteen paired socket bridge segments")
	_expect(int(path_contract.get("required_path_mouth_group_count", 0)) == 7, "path contract records seven paired path mouths including exterior")
	_expect(not path_contract.has("layout_proof_image_path"), "quarantined path layout proof is not an active path-contract target")
	_expect(not path_contract.has("component_proof_image_path"), "quarantined path component proof is not an active path-contract target")
	_expect(not path_contract.has("grid_accurate_concept_image_path"), "quarantined grid concept is not an active path-contract target")
	_expect(not path_contract.has("grid_accurate_concept_overlay_path"), "quarantined grid overlay is not an active path-contract target")
	_expect(not path_contract.has("gpt_image2_concept_path"), "quarantined GPT Image 2 concept is not an active path-contract target")
	_expect(not path_contract.has("superseded_gpt_image2_concept_path"), "superseded GPT Image 2 concept is not an active path-contract target")
	_expect(str(path_contract.get("active_proof_status", "")) == "none_after_failed_visual_material_quarantine", "path contract has no active visual proof after quarantine")
	var next_path_proof: Dictionary = path_contract.get("next_fresh_proof_required", {})
	_expect(str(next_path_proof.get("route", "")).find("built-in image_gen") >= 0, "next path proof must use built-in image_gen route")
	_expect(bool(next_path_proof.get("must_not_reuse_quarantined_visuals", false)), "next path proof cannot reuse quarantined visuals")
	_expect(bool(next_path_proof.get("approval_required_before_slicing", false)), "next path proof requires approval before slicing")
	var grid_accurate_concept_generator := "res://" + str(path_contract.get("grid_accurate_concept_generator", ""))
	_expect(FileAccess.file_exists(grid_accurate_concept_generator), "grid-accurate path concept generator is saved in project")
	var connected_room_sides: Dictionary = path_contract.get("connected_room_sides", {})
	_expect(_path_connected_side_matches(connected_room_sides, "throne", "S"), "path contract connects throne south side")
	_expect(_path_connected_side_matches(connected_room_sides, "barracks", "E"), "path contract connects barracks east side")
	_expect(_path_connected_side_matches(connected_room_sides, "recovery", "W"), "path contract connects recovery west side")
	_expect(_path_connected_side_matches(connected_room_sides, "entrance", "E"), "path contract connects entrance east side")
	_expect(_path_connected_side_matches(connected_room_sides, "entrance", "W"), "path contract connects entrance west side to exterior")
	_expect(_path_connected_side_matches(connected_room_sides, "treasure", "W"), "path contract connects treasure west side")
	_expect(_path_connected_side_matches(connected_room_sides, "slot_01", "N"), "path contract connects build slot north side")

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
	_expect(graph.debug_tile_grid_size() == Vector2i(28, 26), "graph keeps 28x26 max grid with exterior approach")
	_expect(graph.debug_active_rect().size == _grade_active_rect(layout).size, "active rect comes from grade rules")
	_expect(graph.debug_active_cells().size() == graph.debug_active_rect().size.x * graph.debug_active_rect().size.y, "active cells match active rect")
	_expect(graph.debug_floor_cells().size() > 0, "floor cells are registered")
	_expect(graph.debug_walk_cells().size() > 0, "walkable cells are registered")
	_expect(graph.debug_tile_blocked_cells().is_empty(), "room objects do not block whole grid cells")
	_expect(_object_footprint_size(graph, "entrance", "entrance_gate_f") >= 25, "entrance object covers one full 5x5 room grid")
	_expect(_object_footprint_size(graph, "throne", "throne_f") >= 25, "throne object covers one full 5x5 room grid")
	_expect(_object_footprint_size(graph, "barracks", "weapon_rack") >= 25, "barracks object covers one full 5x5 room grid")
	_expect(_object_footprint_size(graph, "recovery", "recovery_nest_f") >= 25, "recovery object covers one full 5x5 room grid")
	_expect(_object_footprint_size(graph, "treasure", "treasure_pile_large") >= 25, "treasure object covers one full 5x5 room grid")
	_expect(_object_footprint_size(graph, "slot_01", "foundation_marks") >= 25, "build slot object covers one full 5x5 room grid")
	_expect(graph.debug_floor_mask_values().size() > 1, "floor masks are calculated")
	_expect(_has_socket_state(graph, "connected"), "connected sockets are represented")
	_expect(_has_socket_state(graph, "closed"), "closed socket sides are represented")
	_expect(graph.path_between("entrance", "throne").size() >= 3, "entrance to throne uses central path connector")
	_expect(graph.path_between("outside_approach", "throne").size() >= 4, "outside approach connects through entrance to throne")
	_expect(graph.path_between("entrance", "treasure").size() >= 3, "entrance to treasure room path exists")
	_expect(graph.path_between("entrance", "barracks").size() >= 3, "entrance to barracks room path exists")
	_expect(graph.path_between("entrance", "recovery").size() >= 3, "entrance to recovery room path exists")
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
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await get_tree().process_frame
	_expect(game.use_quarter_module_map, "game root uses quarter map")
	_expect(str(game.castle_art_stage) == "stage_01_cave", "game root starts with stage 01 cave art")
	_expect(game.quarter_layout_id == DataRegistry.quarter_default_layout_id, "game root uses default quarter layout")
	_expect(game.graph.debug_tile_grid_size() == Vector2i(28, 26), "game root graph uses 28x26 max grid")
	_expect(game.quarter_renderer != null, "quarter renderer is attached")
	_expect(game.quarter_renderer.uses_tile_grid_renderer(), "quarter renderer uses tile grid path")
	_expect(not game.quarter_renderer.has_module_visuals(), "quarter renderer does not use module PNG visuals")
	_expect(game.quarter_renderer.has_floor_tile_textures(), "quarter renderer loads floor mask textures")
	_expect(game.quarter_renderer.debug_missing_floor_tile_masks().is_empty(), "quarter renderer has no missing floor masks")
	_expect(game.quarter_renderer.has_addon_tile_textures(), "quarter renderer loads edge and corner overlay textures")
	_expect(game.quarter_renderer.has_corner_overlay_textures(), "quarter renderer loads generated floor corner overlays")
	_expect(game.quarter_renderer.debug_missing_addon_tiles().is_empty(), "quarter renderer has no missing edge or corner overlay textures")
	_expect(game.quarter_renderer.has_wall_edge_textures(), "quarter renderer loads generated N/E/S/W wall edge atlas")
	_expect(game.quarter_renderer.debug_missing_wall_edge_keys().is_empty(), "quarter renderer has no missing wall edge atlas keys")
	_expect(game.quarter_renderer.debug_wall_cell_count() > 14, "quarter renderer emits closed walls around multi-tile rooms")
	_expect(game.quarter_renderer.debug_wall_edge_key_for_cell(Vector2i(2, 18), "S").begins_with("wall_S_"), "blocked entrance south edge resolves to a south wall")
	_expect(game.quarter_renderer.debug_wall_edge_key_for_cell(Vector2i(13, 2), "E").begins_with("wall_E_"), "blocked throne east edge resolves to an east wall")
	_expect(game.quarter_renderer.debug_wall_edge_key_for_cell(Vector2i(11, 4), "S") == "", "connected throne south edge does not resolve to a closed wall")
	_expect(game.quarter_renderer.debug_wall_edge_key_for_cell(Vector2i(6, 16), "E") == "", "connected entrance east edge does not resolve to a closed wall")
	_expect(game.quarter_renderer.debug_wall_edge_key_for_cell(Vector2i(2, 16), "W") == "", "connected entrance west edge opens to the outside approach")
	_expect(game.quarter_renderer.debug_wall_edge_key_for_cell(Vector2i(0, 16), "W") == "socket_placeholder_W", "outside approach west edge is visibly open to exterior")
	_expect(game.quarter_renderer.has_background_plate_textures(), "quarter renderer loads generated background plate")
	_expect(game.quarter_renderer.debug_missing_background_plates().is_empty(), "quarter renderer has no missing background plates")
	_expect(game.quarter_renderer.has_socket_cap_textures(), "quarter renderer loads socket cap state textures")
	_expect(game.quarter_renderer.debug_missing_socket_caps().is_empty(), "quarter renderer has no missing socket caps")
	_expect(game.quarter_renderer.has_object_sprite_textures(), "quarter renderer loads room object sprite textures")
	_expect(game.quarter_renderer.debug_missing_object_sprites().is_empty(), "quarter renderer has no missing room object sprites")
	_expect(game.quarter_renderer.debug_object_facing("throne") == "SW", "top throne requests the center-facing SW key")
	_expect(game.quarter_renderer.debug_object_facing("entrance") == "SE", "left-lower entrance requests the center-facing SE key")
	_expect(game.quarter_renderer.debug_object_facing("barracks") == "SE", "left-upper barracks requests the center-facing SE key")
	_expect(game.quarter_renderer.debug_object_facing("recovery") == "NW", "right-upper recovery requests the center-facing NW key")
	_expect(game.quarter_renderer.debug_object_facing("treasure") == "NW", "right-lower treasure requests the center-facing NW key")
	_expect(game.quarter_renderer.debug_object_facing("slot_01") == "NE", "bottom build slot requests the center-facing NE key")
	_expect(game.quarter_renderer.debug_object_connection_variant("entrance") == "e_w", "entrance object variant follows east path plus west exterior")
	_expect(game.quarter_renderer.debug_object_connection_variant("throne") == "s", "throne object variant follows connected south path")
	_expect(game.quarter_renderer.debug_object_connection_variant("recovery") == "w", "recovery object variant follows connected west path")
	_expect(game.quarter_renderer.debug_full_grid_room_projection_count() == 6, "renderer draws six projection-safe full-grid room footprints")
	_expect(game.quarter_renderer.debug_room_wall_segment_count() == 120, "six full-grid rooms expose 120 outer wall/door segments")
	_expect(game.quarter_renderer.debug_room_wall_segment_count("wall") == 106, "unconnected building edges render as walls")
	_expect(game.quarter_renderer.debug_room_wall_segment_count("door") == 14, "connected paired room sockets render as fourteen door segments")
	_expect(not game.quarter_renderer.debug_object_uses_projection_safe_connection_sprite("throne", "back"), "front-view generated room sprite is rejected without iso projection metadata")
	_expect(game.quarter_renderer.debug_active_castle_art_stage() == "stage_01_cave", "quarter renderer reads active stage 01 cave art")
	_expect(game.quarter_renderer.debug_object_texture_key("entrance", "back") == "propstage:entrance_gate_f:stage_01_cave:SE:back", "entrance uses stage 01 SE-facing sprite over iso footprint")
	_expect(game.quarter_renderer.debug_object_texture_key("throne", "back") == "propstage:throne_f:stage_01_cave:SW:back", "throne uses stage 01 SW-facing sprite over iso footprint")
	_expect(game.quarter_renderer.debug_object_texture_key("throne", "front") == "", "stage 01 throne suppresses old front fallback")
	_expect(game.quarter_renderer.debug_object_texture_key("barracks", "back") == "propstage:weapon_rack:stage_01_cave:SE:back", "barracks uses stage 01 SE-facing sprite over iso footprint")
	_expect(game.quarter_renderer.debug_object_texture_key("recovery", "front") == "propstage:recovery_nest_f:stage_01_cave:NW:front", "recovery uses stage 01 NW-facing sprite over iso footprint")
	_expect(game.quarter_renderer.debug_object_texture_key("treasure", "front") == "propstage:treasure_pile_large:stage_01_cave:NW:front", "treasure uses stage 01 NW-facing sprite over iso footprint")
	_expect(game.quarter_renderer.debug_object_texture_key("slot_01", "back") == "propstage:foundation_marks:stage_01_cave:NE:back", "build slot uses stage 01 NE-facing sprite over iso footprint")
	game.castle_art_stage = "stage_03_keep"
	_expect(game.quarter_renderer.debug_active_castle_art_stage() == "stage_03_keep", "quarter renderer reads active stage 03 keep art")
	_expect(game.quarter_renderer.debug_object_texture_key("entrance", "back") == "propstage:entrance_gate_f:stage_03_keep:SE:back", "stage 03 entrance uses generated fortified gate")
	_expect(game.quarter_renderer.debug_object_texture_key("throne", "back") == "propstage:throne_f:stage_03_keep:SW:back", "stage 03 throne uses generated fortified throne")
	_expect(game.quarter_renderer.debug_object_texture_key("barracks", "back") == "propstage:weapon_rack:stage_03_keep:SE:back", "stage 03 barracks uses generated armory")
	_expect(game.quarter_renderer.debug_object_texture_key("recovery", "front") == "propstage:recovery_nest_f:stage_03_keep:NW:front", "stage 03 recovery uses generated sanctuary")
	_expect(game.quarter_renderer.debug_object_texture_key("treasure", "front") == "propstage:treasure_pile_large:stage_03_keep:NW:front", "stage 03 treasure uses generated vault")
	_expect(game.quarter_renderer.debug_object_texture_key("slot_01", "back") == "propstage:foundation_marks:stage_03_keep:NE:back", "stage 03 build slot uses generated ward foundation")
	game.castle_art_stage = "stage_01_cave"
	var throne_slot = _object_slot(game.graph, "throne", "throne_f")
	var throne_prop: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {}).get("throne_f", {}).duplicate(true)
	throne_prop["upgrade_stage_sprites"] = {
		"stage_01_cave": {
			"SW": {
				"open_mask_04": {
					"_complete_override": true,
					"back": "res://test_only_upgrade_stage_back.png"
				}
			}
		}
	}
	var upgrade_stage_match: Dictionary = game.quarter_renderer._stage_variant_match(throne_prop, "SW", throne_slot)
	_expect(str(upgrade_stage_match.get("variant_key", "")) == "open_mask_04", "upgrade stage sprites can match stage, facing, and open mask")
	_expect(game.quarter_renderer.debug_connection_bridge_count() == 14, "renderer draws every required connected socket bridge")
	_expect(game.quarter_renderer.debug_connection_bridge_group_count() == 7, "paired 2-cell openings collapse into seven visible path mouths")
	_expect(game.quarter_renderer.debug_outside_approach_cell_count() == 4, "renderer draws the 2x2 outside approach")
	_expect(game.graph.path_between("entrance", "recovery").size() >= 3, "complete default layout keeps right room branch path")
	_expect(_has_required_layers(game.quarter_renderer.debug_layer_names()), "quarter renderer declares v2 layer order")
	_expect(game.quarter_renderer.debug_tilemap_layer_names().has("BackgroundVoidLayer"), "background void layer exists")
	_expect(game.quarter_renderer.debug_visual_variant_key("recovery").find("w") >= 0, "recovery connected socket state affects visual variant")
	_expect(game.quarter_renderer.debug_socket_state("entrance", "to_s_l") == "closed", "unconnected entrance socket remains closed")
	_expect(game.quarter_renderer.debug_socket_cap_key("entrance", "to_s_l") == "closed:S", "closed entrance socket resolves to wall cap")
	_expect(game.quarter_renderer.debug_socket_state("entrance", "to_e_u") == "connected", "connected entrance socket remains open")
	_expect(game.quarter_renderer.debug_socket_cap_key("entrance", "to_e_u") == "connected:E", "connected entrance socket resolves to doorway cap")
	game.selected_room = "barracks"
	var gold_before = GameState.gold
	game._change_selected_room_facility("treasure")
	_expect(GameState.gold == gold_before - 120, "facility change still charges cost")
	_expect(_instance_has_object(game.graph, "barracks", "treasure_pile_large"), "facility change updates map object slots")
	_expect(_object_footprint_size(game.graph, "barracks", "treasure_pile_large") >= 25, "facility replacement keeps full 5x5 object footprint")
	_expect(_instance_has_object(game.graph, "treasure", "foundation_marks"), "unique facility replacement becomes build slot object")
	game.quarter_renderer.trigger_trap_animation("spike_corridor", "spike_floor")
	_expect(game.quarter_renderer.debug_active_trap_animation_count() == 1, "trap trigger animation starts")
	game.quarter_renderer.clear_trap_animations()
	game._select_quarter_layout("expanded_right_branch_layout_01")
	_expect(game.quarter_layout_id == "expanded_right_branch_layout_01", "custom layout selection UI callback can switch layout")
	_expect(game.graph.debug_active_rect().size == Vector2i(28, 26), "S grade layout uses full 28x26 active rect")
	_expect(game.graph.path_between("entrance", "treasure").size() >= 3, "custom layout keeps treasure path")
	game._open_map_editor()
	_expect(game.map_editor_active, "map editor can enter edit mode")
	game.selected_room = "barracks"
	game._map_editor_disconnect_selected_room()
	_expect(not _layout_has_connection(game.map_editor_layout, "spike_corridor:to_w_upper_u", "barracks:to_e_u"), "map editor can disconnect selected room upper path socket")
	_expect(not _layout_has_connection(game.map_editor_layout, "spike_corridor:to_w_upper_d", "barracks:to_e_d"), "map editor can disconnect selected room lower path socket")
	_expect(game.quarter_renderer.debug_connection_bridge_count() == 12, "disconnect removes the selected room's two visual socket bridges")
	_expect(game.quarter_renderer.debug_room_wall_segment_count("door") == 12, "disconnect closes the selected room's two doorway segments")
	_expect(game.quarter_renderer.debug_room_wall_segment_count("wall") == 108, "disconnect turns the selected room doorway segments back into walls")
	_expect(game.quarter_renderer.debug_socket_state("barracks", "to_e_u") == "open_placeholder", "disconnected barracks upper east socket becomes placeholder")
	_expect(game.quarter_renderer.debug_socket_cap_key("barracks", "to_e_u") == "open_placeholder:E", "disconnected barracks upper east socket resolves to placeholder cap")
	_expect(game.quarter_renderer.debug_socket_state("barracks", "to_e_d") == "open_placeholder", "disconnected barracks lower east socket becomes placeholder")
	_expect(game.quarter_renderer.debug_socket_cap_key("barracks", "to_e_d") == "open_placeholder:E", "disconnected barracks lower east socket resolves to placeholder cap")
	_expect(not game.map_editor_errors.is_empty(), "disconnecting required chain room reports path errors")
	game._map_editor_connect_adjacent_socket()
	game._map_editor_connect_adjacent_socket()
	_expect(_layout_has_connection(game.map_editor_layout, "spike_corridor:to_w_upper_u", "barracks:to_e_u"), "map editor can reconnect upper adjacent path socket")
	_expect(_layout_has_connection(game.map_editor_layout, "spike_corridor:to_w_upper_d", "barracks:to_e_d"), "map editor can reconnect lower adjacent path socket")
	_expect(game.quarter_renderer.debug_connection_bridge_count() == 14, "reconnect restores all visual socket bridges")
	_expect(game.quarter_renderer.debug_room_wall_segment_count("door") == 14, "reconnect restores the selected room doorway segments")
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

func _check_castle_stage_expansions() -> void:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
	game.castle_art_stage = "stage_02_castle"
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	_expect(game.rooms.has("watch_post_01"), "stage 02 adds east watch-post room")
	_expect(not game.rooms.has("ward_core_01"), "stage 02 does not unlock stage 03 ward room early")
	_expect(game.graph.validation_summary().get("ok", false), "stage 02 expanded graph validates")
	_expect(not game.graph.path_between("entrance", "watch_post_01").is_empty(), "stage 02 watch branch connects to entrance")
	_expect(_instance_has_object(game.graph, "watch_post_01", "watch_post"), "stage 02 watch post has a visible room object")
	_expect(game._build_facility_choices().has("watch_post") and not game._build_facility_choices().has("ward_core"), "stage 02 unlocks watch post but keeps ward core locked")
	_expect(game._facility_upgrade_level_cap() == 3, "stage 02 raises facility upgrade cap to level 3")
	_expect(int(game.rooms["watch_post_01"].get("hp", 0)) == 460 and int(game.rooms["watch_post_01"].get("max_monsters", 0)) == 4, "stage 02 evolves watch-post durability and capacity")
	_expect(GameState.demon_lord_max_hp == 1750, "stage 02 evolves throne maximum HP")
	game.castle_art_stage = "stage_03_keep"
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	_expect(game.rooms.has("ward_core_01") and game.rooms.has("slot_02"), "stage 03 adds ward core and southeast build area")
	_expect(game.graph.validation_summary().get("ok", false), "stage 03 expanded graph validates")
	_expect(not game.graph.path_between("entrance", "ward_core_01").is_empty(), "stage 03 ward branch connects to entrance")
	_expect(not game.graph.path_between("entrance", "slot_02").is_empty(), "stage 03 build branch connects to entrance")
	_expect(_instance_has_object(game.graph, "ward_core_01", "foundation_marks"), "stage 03 ward core uses generated ward-foundation visual")
	_expect(game._build_facility_choices().has("ward_core"), "stage 03 unlocks ward-core construction")
	_expect(game._facility_upgrade_level_cap() == 4, "stage 03 raises facility upgrade cap to level 4")
	_expect(int(game.rooms["recovery"].get("hp", 0)) == 530 and int(game.rooms["recovery"].get("max_monsters", 0)) == 4, "stage 03 evolves existing recovery facility")
	_expect(GameState.demon_lord_max_hp == 2100, "stage 03 evolves throne maximum HP")
	game.castle_art_stage = "stage_04_citadel"
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	_expect(game.rooms.has("elite_garrison_01") and game.rooms.has("slot_03"), "stage 04 adds elite garrison and west build area")
	_expect(game.graph.validation_summary().get("ok", false), "stage 04 expanded graph validates")
	_expect(not game.graph.path_between("entrance", "elite_garrison_01").is_empty(), "stage 04 elite branch connects to entrance")
	_expect(not game.graph.path_between("entrance", "slot_03").is_empty(), "stage 04 west build branch connects to entrance")
	_expect(GameState.demon_lord_max_hp == 2500, "stage 04 evolves throne maximum HP")
	game._onboarding_reset_game()
	_expect(game.castle_art_stage == "stage_01_cave" and not game.rooms.has("watch_post_01"), "new-game reset restores stage 01 rooms")
	_expect(game.quarter_renderer.debug_full_grid_room_projection_count() == 6, "new-game reset restores six-room stage 01 area")
	game.queue_free()
	await get_tree().process_frame

func _check_socket_edge_masks(graph) -> void:
	var cases = [
		["entrance", "to_e_u", "E"],
		["entrance", "to_e_d", "E"],
		["entrance", "to_w_u", "W"],
		["entrance", "to_w_d", "W"],
		["outside_approach", "to_entrance_u", "E"],
		["outside_approach", "to_entrance_d", "E"],
		["spike_corridor", "to_w_lower_u", "W"],
		["spike_corridor", "to_w_lower_d", "W"],
		["barracks", "to_e_u", "E"],
		["barracks", "to_e_d", "E"],
		["spike_corridor", "to_w_upper_u", "W"],
		["spike_corridor", "to_w_upper_d", "W"],
		["recovery", "to_w_u", "W"],
		["recovery", "to_w_d", "W"],
		["spike_corridor", "to_e_upper_u", "E"],
		["spike_corridor", "to_e_upper_d", "E"],
		["slot_01", "to_n_l", "N"],
		["slot_01", "to_n_r", "N"],
		["spike_corridor", "to_s_l", "S"],
		["spike_corridor", "to_s_r", "S"],
		["treasure", "to_w_u", "W"],
		["treasure", "to_w_d", "W"],
		["spike_corridor", "to_e_lower_u", "E"],
		["spike_corridor", "to_e_lower_d", "E"],
		["throne", "to_s_l", "S"],
		["throne", "to_s_r", "S"],
		["spike_corridor", "to_n_l", "N"],
		["spike_corridor", "to_n_r", "N"]
	]
	for entry in cases:
		var socket = _socket_record(graph, str(entry[0]), str(entry[1]))
		_expect(not socket.is_empty(), "%s:%s socket exists" % [entry[0], entry[1]])
		if socket.is_empty():
			continue
		var mask = graph.debug_floor_mask(socket["cell"])
		var side = str(entry[2])
		_expect((mask & int(AutoTileMaskScript.BITS[side])) != 0, "%s:%s opens %s edge" % [entry[0], entry[1], side])
	var closed_socket = _socket_record(graph, "entrance", "to_s_l")
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

func _has_placed_module(layout: Dictionary, instance_id: String, grid_id: String) -> bool:
	for placed in layout.get("placed_modules", []):
		if not (placed is Dictionary):
			continue
		if str(placed.get("instance_id", "")) == instance_id and str(placed.get("grid_id", "")) == grid_id:
			return true
	return false

func _has_placed_instance(layout: Dictionary, instance_id: String) -> bool:
	for placed in layout.get("placed_modules", []):
		if placed is Dictionary and str(placed.get("instance_id", "")) == instance_id:
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

func _object_slot(graph, instance_id: String, object_id: String) -> Dictionary:
	for slot in graph.debug_object_slots():
		if str(slot.get("instance_id", "")) == instance_id and str(slot.get("id", "")) == object_id:
			return slot
	return {}

func _object_footprint_size(graph, instance_id: String, object_id: String) -> int:
	for slot in graph.debug_object_slots():
		if str(slot.get("instance_id", "")) == instance_id and str(slot.get("id", "")) == object_id:
			return slot.get("footprint", []).size()
	return 0

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

func _production_variant_matches(variants: Dictionary, instance_id: String, object_id: String, facing: String, open_mask: int) -> bool:
	var variant: Dictionary = variants.get(instance_id, {})
	return str(variant.get("object_id", "")) == object_id and str(variant.get("facing", "")) == facing and int(variant.get("open_mask", -1)) == open_mask

func _proof_only_entries_have_path(entries: Array, proof_path: String) -> bool:
	for entry in entries:
		if entry is Dictionary and str(entry.get("path", "")) == proof_path:
			return true
	return false

func _path_connected_side_matches(connected_room_sides: Dictionary, instance_id: String, side: String) -> bool:
	var sides: Array = connected_room_sides.get(instance_id, [])
	return sides.has(side)

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
