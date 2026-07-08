extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DataRegistry.load_all()
	await _check_gap_without_manual_path_does_not_connect()
	await _check_user_path_placement_candidate_cycle()
	await _check_user_path_auto_connect_click_target()
	await _check_user_path_candidate_socket_pair_markers()
	await _check_user_path_click_target_picker()
	await _check_user_path_click_target_reclick_cycles_candidate()
	await _check_user_path_drag_connect_disconnect()
	await _check_indirect_route_does_not_count_as_duplicate_connection()
	await _check_user_path_placement_ui_east_west()
	await _check_user_path_placement_ui_north_south()
	await _check_user_path_connect_ends_ui()
	await _check_user_path_delete_ui()
	await _check_system_required_path_delete_blocked()
	await _check_manual_path_authoring_east_west()
	await _check_manual_path_authoring_north_south()
	await _check_required_route_save_connects_existing_manual_path()
	await _check_required_route_save_inserts_system_path()
	await _check_map_editor_save_without_persistence()
	await _check_required_route_combat_start_repairs_runtime_path()
	if failed:
		print("ROOM_PATH_AUTHORING_PROBE: FAIL")
		get_tree().quit(1)
	else:
		print("ROOM_PATH_AUTHORING_PROBE: PASS")
		get_tree().quit(0)

func _check_gap_without_manual_path_does_not_connect() -> void:
	var layout = _base_layout("room_path_authoring_no_auto_path_test_01")
	layout["placed_modules"] = [
		_module("entrance", "room_entrance_01", [2, 14]),
		_module("treasure", "room_treasure_01", [9, 14])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "entrance"
	game._open_map_editor()
	await get_tree().process_frame
	game._map_editor_connect_adjacent_socket()
	await get_tree().process_frame
	_expect(game.map_editor_layout.get("connections", []).is_empty(), "gap without manually placed path does not connect")
	_expect(_placed_count(game.map_editor_layout) == 2, "gap without manually placed path does not create a path module")
	game.queue_free()
	await get_tree().process_frame

func _check_user_path_placement_candidate_cycle() -> void:
	var layout = _base_layout("room_path_authoring_candidate_cycle_test_01")
	layout["placed_modules"] = [
		_module("barracks", "room_barracks_01", [2, 7]),
		_module("recovery", "room_recovery_01", [9, 7]),
		_module("treasure", "room_treasure_01", [2, 14])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "barracks"
	game._open_map_editor()
	await get_tree().process_frame

	var first_candidate: Dictionary = game._map_editor_preview_gap_path_candidate()
	_expect(not first_candidate.is_empty(), "path placement candidate preview exists")
	var first_target = str(first_candidate.get("other_instance", ""))
	var first_origin: Vector2i = first_candidate.get("origin", Vector2i.ZERO)
	game._map_editor_next_gap_path_candidate()
	await get_tree().process_frame
	var second_candidate: Dictionary = game._map_editor_preview_gap_path_candidate()
	_expect(not second_candidate.is_empty(), "path placement candidate cycle keeps a preview")
	var second_target = str(second_candidate.get("other_instance", ""))
	var second_origin: Vector2i = second_candidate.get("origin", Vector2i.ZERO)
	_expect(first_target != second_target or first_origin != second_origin, "path placement candidate cycle selects a different target or gap")

	game._map_editor_place_gap_path()
	await get_tree().process_frame
	var path_id = str(game.selected_room)
	var placed_path = _placed_entry(game.map_editor_layout, path_id)
	var placed_origin = placed_path.get("grid_origin", [])
	_expect(str(placed_path.get("module_id", "")) == str(second_candidate.get("module_id", "")), "cycled candidate uses the previewed module")
	_expect(placed_origin == [second_origin.x, second_origin.y], "cycled candidate places at the previewed origin")
	_expect(str(placed_path.get("grid_id", "")) == "USER_AUTHORED_PATH", "cycled candidate still creates a user-authored path")
	game.queue_free()
	await get_tree().process_frame

func _check_user_path_auto_connect_click_target() -> void:
	var layout = _base_layout("room_path_authoring_auto_connect_click_test_01")
	layout["placed_modules"] = [
		_module("barracks", "room_barracks_01", [2, 7]),
		_module("recovery", "room_recovery_01", [9, 7])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "barracks"
	game._open_map_editor()
	await get_tree().process_frame

	var before_count = _placed_count(game.map_editor_layout)
	_expect(game._map_editor_connect_selected_to("recovery"), "clicking target room auto-connects selected room")
	await get_tree().process_frame
	var path_id = _first_user_path_id(game.map_editor_layout)
	_expect(path_id != "", "auto-connect creates a user-authored path")
	_expect(_placed_count(game.map_editor_layout) == before_count + 1, "auto-connect adds exactly one path module")
	_expect(game.map_editor_layout.get("connections", []).size() == 4, "auto-connect links both room-path socket pairs")
	_expect(game.selected_room == "recovery", "auto-connect continues from the clicked target")
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, game.map_editor_layout, DataRegistry.rooms)
	_expect(graph.path_between("barracks", "recovery") == ["barracks", path_id, "recovery"], "auto-connect route uses the generated path")
	game.queue_free()
	await get_tree().process_frame

func _check_user_path_candidate_socket_pair_markers() -> void:
	var layout = _base_layout("room_path_authoring_candidate_socket_markers_test_01")
	layout["placed_modules"] = [
		_module("barracks", "room_barracks_01", [2, 7]),
		_module("recovery", "room_recovery_01", [9, 7]),
		_module("treasure", "room_treasure_01", [2, 14])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "barracks"
	game._open_map_editor()
	await get_tree().process_frame

	var candidate: Dictionary = game._map_editor_preview_gap_path_candidate()
	var markers: Array = game._map_editor_preview_gap_path_socket_markers()
	_expect(not candidate.is_empty(), "socket marker test starts with a path candidate")
	_expect(markers.size() == 2, "path candidate exposes source and target socket markers")
	var source_marker = _marker_for_role(markers, "source")
	var target_marker = _marker_for_role(markers, "target")
	_expect(str(source_marker.get("ref", "")) == str(candidate.get("source_socket", "")), "source socket marker follows the preview candidate")
	_expect(str(target_marker.get("ref", "")) == str(candidate.get("other_socket", "")), "target socket marker follows the preview candidate")
	_expect(source_marker.get("cell", Vector2i.ZERO) != target_marker.get("cell", Vector2i.ZERO), "socket markers point at two distinct grid cells")

	game._handle_left_click(game.graph.center("treasure"), Vector2(960, 540))
	await get_tree().process_frame
	var path_id = _first_user_path_id(game.map_editor_layout)
	_expect(path_id != "", "socket marker target click creates the target path")
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, game.map_editor_layout, DataRegistry.rooms)
	_expect(graph.path_between("barracks", "treasure") == ["barracks", path_id, "treasure"], "socket marker target click connects the clicked target")

	game.queue_free()
	await get_tree().process_frame

func _check_user_path_click_target_picker() -> void:
	var layout = _base_layout("room_path_authoring_click_target_test_01")
	layout["placed_modules"] = [
		_module("barracks", "room_barracks_01", [2, 7]),
		_module("recovery", "room_recovery_01", [9, 7]),
		_module("treasure", "room_treasure_01", [2, 14])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "barracks"
	game._open_map_editor()
	await get_tree().process_frame
	var clicked_target = "treasure"
	game._handle_left_click(game.graph.center(clicked_target), Vector2(960, 540))
	await get_tree().process_frame

	var path_id = _first_user_path_id(game.map_editor_layout)
	var placed_path = _placed_entry(game.map_editor_layout, path_id)
	_expect(game.selected_room == clicked_target, "click target picker continues from the clicked target")
	_expect(str(placed_path.get("grid_id", "")) == "USER_AUTHORED_PATH", "click target picker creates a user-authored path")
	_expect(game.map_editor_layout.get("connections", []).size() == 4, "click target picker connects both sides automatically")
	game.queue_free()
	await get_tree().process_frame

func _check_user_path_click_target_reclick_cycles_candidate() -> void:
	var layout = _base_layout("room_path_authoring_click_target_reclick_test_01")
	layout["placed_modules"] = [
		_module("barracks", "room_barracks_01", [2, 7]),
		_module("treasure", "room_treasure_01", [2, 14])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "barracks"
	game._open_map_editor()
	await get_tree().process_frame
	var clicked_target = "treasure"
	var target_candidates := []
	for candidate in game._map_editor_gap_path_candidates_for_selected():
		if str(candidate.get("other_instance", "")) == clicked_target:
			target_candidates.append(candidate)
	_expect(target_candidates.size() >= 1, "click target reclick test has a target candidate")

	game._handle_left_click(game.graph.center(clicked_target), Vector2(960, 540))
	await get_tree().process_frame
	var first_path_id = _first_user_path_id(game.map_editor_layout)
	var first_count = _placed_count(game.map_editor_layout)
	var first_connections = game.map_editor_layout.get("connections", []).size()

	game._handle_left_click(game.graph.center("barracks"), Vector2(960, 540))
	await get_tree().process_frame
	_expect(_first_user_path_id(game.map_editor_layout) == first_path_id, "target reclick keeps the existing path")
	_expect(_placed_count(game.map_editor_layout) == first_count, "target reclick does not add duplicate paths")
	_expect(game.map_editor_layout.get("connections", []).size() == first_connections, "target reclick does not duplicate connections")
	game.queue_free()
	await get_tree().process_frame

func _check_user_path_drag_connect_disconnect() -> void:
	var layout = _base_layout("room_path_authoring_drag_connect_disconnect_test_01")
	layout["placed_modules"] = [
		_module("barracks", "room_barracks_01", [2, 7]),
		_module("recovery", "room_recovery_01", [9, 7])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "barracks"
	game._open_map_editor()
	await get_tree().process_frame

	_expect(game._start_map_editor_path_drag(game.graph.center("barracks")), "drag starts from a room")
	game._update_map_editor_path_drag(game.graph.center("recovery"))
	game._finish_map_editor_path_drag(game.graph.center("recovery"))
	await get_tree().process_frame
	var path_id = _first_user_path_id(game.map_editor_layout)
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, game.map_editor_layout, DataRegistry.rooms)
	_expect(path_id != "", "drag connect creates a user-authored path")
	_expect(graph.path_between("barracks", "recovery") == ["barracks", path_id, "recovery"], "drag connect produces a usable route")

	_expect(game._start_map_editor_path_drag(game.graph.center("recovery")), "drag disconnect starts from connected target")
	game._update_map_editor_path_drag(game.graph.center("barracks"))
	game._finish_map_editor_path_drag(game.graph.center("barracks"))
	await get_tree().process_frame
	_expect(_first_user_path_id(game.map_editor_layout) == "", "drag disconnect removes the generated path")
	_expect(game.map_editor_layout.get("connections", []).is_empty(), "drag disconnect removes socket connections")
	game.queue_free()
	await get_tree().process_frame

func _check_indirect_route_does_not_count_as_duplicate_connection() -> void:
	var layout = DataRegistry.quarter_layout("current_demo_v2_master_grid_01").duplicate(true)
	layout["template_id"] = "room_path_authoring_indirect_duplicate_test_01"
	layout["display_name"] = "Indirect duplicate connection test"
	var game = await _new_game_with_layout(layout)
	game.selected_room = "barracks"
	game._open_map_editor()
	await get_tree().process_frame

	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, game.map_editor_layout, game.rooms)
	_expect(not graph.path_between("barracks", "recovery").is_empty(), "demo layout has an indirect barracks-recovery route through the hub")
	_expect(game._layout_count_connections_between_instances(game.map_editor_layout, "barracks", "recovery") == 0, "demo layout has no direct barracks-recovery socket pair")
	_expect(not game._map_editor_ref_instances_connected("barracks", "recovery"), "indirect hub route does not block a new direct branch")
	_expect(game._map_editor_drag_state("barracks", "recovery") != "indirect", "drag state does not report indirect routes as already connected")
	game.queue_free()
	await get_tree().process_frame

func _check_user_path_placement_ui_east_west() -> void:
	var layout = _base_layout("room_path_authoring_ui_place_ew_test_01")
	layout["placed_modules"] = [
		_module("entrance", "room_entrance_01", [2, 14]),
		_module("treasure", "room_treasure_01", [9, 14])
	]
	await _run_user_path_placement_case(layout, "entrance", "treasure", "corridor_gap_ew_2x2_01", ["e"], ["w"], "east-west UI path placement")

func _check_user_path_placement_ui_north_south() -> void:
	var layout = _base_layout("room_path_authoring_ui_place_ns_test_01")
	layout["placed_modules"] = [
		_module("barracks", "room_barracks_01", [2, 7]),
		_module("treasure", "room_treasure_01", [2, 14])
	]
	await _run_user_path_placement_case(layout, "barracks", "treasure", "corridor_gap_ns_2x2_01", ["s"], ["n"], "north-south UI path placement")

func _check_user_path_connect_ends_ui() -> void:
	var layout = _base_layout("room_path_authoring_connect_ends_test_01")
	layout["placed_modules"] = [
		_module("entrance", "room_entrance_01", [2, 14]),
		_module("treasure", "room_treasure_01", [9, 14])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "entrance"
	game._open_map_editor()
	await get_tree().process_frame
	game._map_editor_place_gap_path()
	await get_tree().process_frame
	var path_id = str(game.selected_room)
	_expect(game.map_editor_layout.get("connections", []).is_empty(), "connect ends starts with an unconnected placed path")
	game._map_editor_connect_selected_path_ends()
	await get_tree().process_frame
	_expect(game.map_editor_layout.get("connections", []).size() == 4, "connect ends links both sides of the selected 2x2 path")
	game._map_editor_connect_selected_path_ends()
	await get_tree().process_frame
	_expect(game.map_editor_layout.get("connections", []).size() == 4, "connect ends does not duplicate existing socket links")
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, game.map_editor_layout, DataRegistry.rooms)
	_expect(graph.path_between("entrance", "treasure") == ["entrance", path_id, "treasure"], "connect ends produces a usable room-path-room graph route")
	game.queue_free()
	await get_tree().process_frame

func _check_user_path_delete_ui() -> void:
	var layout = _base_layout("room_path_authoring_delete_user_path_test_01")
	layout["placed_modules"] = [
		_module("entrance", "room_entrance_01", [2, 14]),
		_module("treasure", "room_treasure_01", [9, 14])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "entrance"
	game._open_map_editor()
	await get_tree().process_frame
	game._map_editor_place_gap_path()
	await get_tree().process_frame
	var path_id = str(game.selected_room)
	for _index in range(4):
		game._map_editor_connect_adjacent_socket()
	await get_tree().process_frame
	_expect(game.map_editor_layout.get("connections", []).size() == 4, "user path delete test starts with connected path")
	game._map_editor_delete_selected_path()
	await get_tree().process_frame
	_expect(_placed_entry(game.map_editor_layout, path_id).is_empty(), "user path delete removes the selected path module")
	_expect(_placed_count(game.map_editor_layout) == 2, "user path delete keeps only the original rooms")
	_expect(game.map_editor_layout.get("connections", []).is_empty(), "user path delete removes path socket connections")
	game.queue_free()
	await get_tree().process_frame

func _check_system_required_path_delete_blocked() -> void:
	var layout = _base_layout("room_path_authoring_delete_system_path_blocked_test_01")
	var system_path = _module("system_required_path_01", "corridor_gap_ew_2x2_01", [7, 16])
	system_path["grid_id"] = "SYSTEM_REQUIRED_ROUTE"
	system_path["system_required"] = true
	layout["required_paths"] = [{"from": "entrance", "to": "throne", "purpose": "main_enemy_path"}]
	layout["placed_modules"] = [
		_module("entrance", "room_entrance_01", [2, 14]),
		system_path,
		_module("throne", "room_throne_01", [9, 14])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "entrance"
	game._open_map_editor()
	await get_tree().process_frame
	game._map_editor_connect_adjacent_socket()
	game._map_editor_connect_adjacent_socket()
	game.selected_room = "system_required_path_01"
	game._map_editor_connect_adjacent_socket()
	game._map_editor_connect_adjacent_socket()
	await get_tree().process_frame
	_expect(game.map_editor_layout.get("connections", []).size() == 4, "system path delete test starts with connected required path")
	game._map_editor_delete_selected_path()
	await get_tree().process_frame
	_expect(not _placed_entry(game.map_editor_layout, "system_required_path_01").is_empty(), "system required path delete is blocked without replacement route")
	_expect(game.map_editor_layout.get("connections", []).size() == 4, "blocked system required path delete keeps socket connections")
	game.queue_free()
	await get_tree().process_frame

func _run_user_path_placement_case(layout: Dictionary, start_room: String, goal_room: String, expected_module_id: String, start_variant_parts: Array, goal_variant_parts: Array, label: String) -> void:
	var game = await _new_game_with_layout(layout)
	game.selected_room = start_room
	game._open_map_editor()
	await get_tree().process_frame

	game._map_editor_place_gap_path()
	await get_tree().process_frame
	var path_id = str(game.selected_room)
	var placed_path = _placed_entry(game.map_editor_layout, path_id)
	_expect(path_id.begins_with("user_path_"), "%s selects the newly placed user path" % label)
	_expect(not placed_path.is_empty(), "%s creates a path module" % label)
	_expect(str(placed_path.get("module_id", "")) == expected_module_id, "%s uses the expected corridor module" % label)
	_expect(str(placed_path.get("grid_id", "")) == "USER_AUTHORED_PATH", "%s marks the path as user-authored" % label)
	_expect(bool(placed_path.get("user_authored", false)), "%s stores user_authored marker" % label)
	_expect(_placed_count(game.map_editor_layout) == 3, "%s adds exactly one path module" % label)
	_expect(game.map_editor_layout.get("connections", []).is_empty(), "%s places path without auto-connecting sockets" % label)

	for _index in range(4):
		game._map_editor_connect_adjacent_socket()
	await get_tree().process_frame

	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, game.map_editor_layout, DataRegistry.rooms)
	_expect(game.map_editor_layout.get("connections", []).size() == 4, "%s connects paired room-path sockets through existing action" % label)
	_expect(graph.path_between(start_room, goal_room) == [start_room, path_id, goal_room], "%s graph path uses the placed user path" % label)
	_expect(_object_variant_has(graph, start_room, start_variant_parts), "%s start room open mask follows placed path" % label)
	_expect(_object_variant_has(graph, goal_room, goal_variant_parts), "%s goal room open mask follows placed path" % label)

	game.queue_free()
	await get_tree().process_frame

func _check_manual_path_authoring_east_west() -> void:
	var layout = _base_layout("room_path_authoring_manual_ew_test_01")
	layout["placed_modules"] = [
		_module("entrance", "room_entrance_01", [2, 14]),
		_module("path_entrance_treasure", "corridor_gap_ew_2x2_01", [7, 16]),
		_module("treasure", "room_treasure_01", [9, 14])
	]
	await _run_manual_path_case(layout, "entrance", "path_entrance_treasure", "treasure", ["e"], ["w"], "east-west manual path")

func _check_manual_path_authoring_north_south() -> void:
	var layout = _base_layout("room_path_authoring_manual_ns_test_01")
	layout["placed_modules"] = [
		_module("barracks", "room_barracks_01", [2, 7]),
		_module("path_barracks_treasure", "corridor_gap_ns_2x2_01", [4, 12]),
		_module("treasure", "room_treasure_01", [2, 14])
	]
	await _run_manual_path_case(layout, "barracks", "path_barracks_treasure", "treasure", ["s"], ["n"], "north-south manual path")

func _run_manual_path_case(layout: Dictionary, start_room: String, path_id: String, goal_room: String, start_variant_parts: Array, goal_variant_parts: Array, label: String) -> void:
	var game = await _new_game_with_layout(layout)
	game.selected_room = start_room
	game._open_map_editor()
	await get_tree().process_frame

	game._map_editor_connect_adjacent_socket()
	game._map_editor_connect_adjacent_socket()
	game.selected_room = path_id
	game._map_editor_connect_adjacent_socket()
	game._map_editor_connect_adjacent_socket()
	await get_tree().process_frame

	_expect(_placed_count(game.map_editor_layout) == 3, "%s keeps only manually placed modules" % label)
	_expect(game.map_editor_layout.get("connections", []).size() == 4, "%s connects four paired sockets manually" % label)
	_expect(game.map_editor_errors.is_empty(), "%s keeps editor layout valid: %s" % [label, str(game.map_editor_errors)])

	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, game.map_editor_layout, DataRegistry.rooms)
	_expect(bool(graph.validation_summary().get("ok", false)), "%s authored graph validates: %s" % [label, str(graph.validation_summary().get("errors", []))])
	_expect(graph.path_between(start_room, goal_room) == [start_room, path_id, goal_room], "%s graph path uses manually placed connector" % label)
	_expect(_object_variant_has(graph, start_room, start_variant_parts), "%s start room open mask follows manual connection" % label)
	_expect(_object_variant_has(graph, goal_room, goal_variant_parts), "%s goal room open mask follows manual connection" % label)

	game.selected_room = start_room
	game._map_editor_disconnect_selected_room()
	await get_tree().process_frame
	_expect(_placed_count(game.map_editor_layout) == 3, "%s disconnect does not delete manually placed path" % label)

	game.queue_free()
	await get_tree().process_frame

func _check_required_route_save_connects_existing_manual_path() -> void:
	var layout = _base_layout("room_path_authoring_required_route_existing_path_test_01")
	layout["required_paths"] = [{"from": "entrance", "to": "throne", "purpose": "main_enemy_path"}]
	layout["placed_modules"] = [
		_module("entrance", "room_entrance_01", [2, 14]),
		_module("path_entrance_throne", "corridor_gap_ew_2x2_01", [7, 16]),
		_module("throne", "room_throne_01", [9, 14])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "entrance"
	game._open_map_editor()
	await get_tree().process_frame
	_expect(game.map_editor_errors.size() >= 1, "required route save test starts disconnected before commit")
	_expect(game._save_map_editor_layout(false), "save repairs required route through existing manual path")
	await get_tree().process_frame
	var saved_layout = DataRegistry.quarter_layout(game.quarter_layout_id)
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, saved_layout, DataRegistry.rooms)
	_expect(_placed_count(saved_layout) == 3, "required route repair keeps existing manual path only")
	_expect(saved_layout.get("connections", []).size() == 4, "required route repair connects paired 2-cell sockets")
	_expect(graph.path_between("entrance", "throne") == ["entrance", "path_entrance_throne", "throne"], "required route repair uses existing path module")
	game.queue_free()
	await get_tree().process_frame

func _check_required_route_save_inserts_system_path() -> void:
	var layout = _base_layout("room_path_authoring_required_route_insert_path_test_01")
	layout["required_paths"] = [{"from": "entrance", "to": "throne", "purpose": "main_enemy_path"}]
	layout["placed_modules"] = [
		_module("entrance", "room_entrance_01", [2, 14]),
		_module("throne", "room_throne_01", [9, 14])
	]
	var game = await _new_game_with_layout(layout)
	game.selected_room = "entrance"
	game._open_map_editor()
	await get_tree().process_frame
	_expect(game._save_map_editor_layout(false), "save inserts system path when required route has no manual path")
	await get_tree().process_frame
	var saved_layout = DataRegistry.quarter_layout(game.quarter_layout_id)
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, saved_layout, DataRegistry.rooms)
	var system_path_id = _first_system_required_path_id(saved_layout)
	_expect(system_path_id != "", "required route repair creates a system_required path module")
	_expect(_placed_count(saved_layout) == 3, "required route repair adds exactly one path module")
	_expect(saved_layout.get("connections", []).size() == 4, "inserted system path gets four paired socket connections")
	_expect(graph.path_between("entrance", "throne") == ["entrance", system_path_id, "throne"], "inserted system path connects entrance to throne")
	game.queue_free()
	await get_tree().process_frame

func _check_required_route_combat_start_repairs_runtime_path() -> void:
	var layout = _base_layout("room_path_authoring_required_route_runtime_combat_test_01")
	layout["required_paths"] = [{"from": "entrance", "to": "throne", "purpose": "main_enemy_path"}]
	layout["placed_modules"] = [
		_module("entrance", "room_entrance_01", [2, 14]),
		_module("throne", "room_throne_01", [9, 14])
	]
	var game = await _new_game_with_layout(layout)
	game._start_combat()
	await get_tree().process_frame
	var runtime_layout = DataRegistry.quarter_layout(game.quarter_layout_id)
	var system_path_id = _first_system_required_path_id(runtime_layout)
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "combat start continues after required route runtime repair")
	_expect(system_path_id != "", "combat start runtime repair creates system_required path")
	_expect(game.graph.path_between("entrance", "throne") == ["entrance", system_path_id, "throne"], "combat route uses runtime repaired path")
	game.queue_free()
	await get_tree().process_frame

func _check_map_editor_save_without_persistence() -> void:
	var previous_disabled = DataRegistry.runtime_layout_persistence_disabled
	DataRegistry.runtime_layout_persistence_disabled = true
	var layout = _base_layout("room_path_authoring_runtime_only_save_test_01")
	layout["placed_modules"] = [
		_module("entrance", "room_entrance_01", [2, 14]),
		_module("throne", "room_throne_01", [9, 14])
	]
	var game = await _new_game_with_layout(layout)
	game._open_map_editor()
	await get_tree().process_frame
	_expect(game._save_map_editor_layout(true), "map editor save succeeds without file persistence")
	_expect(not game.map_editor_active, "map editor exits after runtime-only save")
	_expect(not DataRegistry.quarter_layout(game.quarter_layout_id).is_empty(), "runtime-only map editor layout is registered for immediate play")
	game.queue_free()
	await get_tree().process_frame
	DataRegistry.runtime_layout_persistence_disabled = previous_disabled
	DataRegistry.load_all()

func _new_game_with_layout(layout: Dictionary) -> Node:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await get_tree().process_frame
	var layout_id = str(layout.get("template_id", ""))
	_expect(DataRegistry.register_quarter_layout(layout_id, layout, false), "%s layout registers" % layout_id)
	_expect(game.set_quarter_layout(layout_id), "%s layout applies" % layout_id)
	return game

func _base_layout(template_id: String) -> Dictionary:
	return {
		"template_id": template_id,
		"display_name": template_id,
		"coordinate_mode": "logical_grid_v2",
		"castle_grade": "S",
		"tile_size": [128, 64],
		"room_grid_contract_id": "novice_4x4_grid_5x5_gap2_paths_authoring_test_01",
		"room_grid": {
			"contract_id": "novice_4x4_grid_5x5_gap2_paths_authoring_test_01",
			"grid_size": [4, 4],
			"cell_size": [5, 5],
			"master_origin": [2, 0],
			"gap_size": [2, 2],
			"stride": [7, 7],
			"active_master_size": [28, 26],
			"cells": []
		},
		"placed_modules": [],
		"socket_states": {},
		"connections": [],
		"required_paths": []
	}

func _module(instance_id: String, module_id: String, origin: Array) -> Dictionary:
	return {
		"instance_id": instance_id,
		"module_id": module_id,
		"grid_id": "AUTHORING_TEST",
		"grid_origin": origin,
		"locked": false,
		"legacy_room_id": instance_id
	}

func _placed_count(layout: Dictionary) -> int:
	return layout.get("placed_modules", []).size()

func _placed_entry(layout: Dictionary, instance_id: String) -> Dictionary:
	for placed in layout.get("placed_modules", []):
		if placed is Dictionary and str(placed.get("instance_id", "")) == instance_id:
			return placed
	return {}

func _first_system_required_path_id(layout: Dictionary) -> String:
	for placed in layout.get("placed_modules", []):
		if placed is Dictionary and bool(placed.get("system_required", false)):
			return str(placed.get("instance_id", ""))
	return ""

func _first_user_path_id(layout: Dictionary) -> String:
	for placed in layout.get("placed_modules", []):
		if placed is Dictionary and bool(placed.get("user_authored", false)):
			return str(placed.get("instance_id", ""))
	return ""

func _marker_for_role(markers: Array, role: String) -> Dictionary:
	for marker in markers:
		if marker is Dictionary and str(marker.get("role", "")) == role:
			return marker
	return {}

func _object_variant_has(graph, instance_id: String, required_parts: Array) -> bool:
	for slot in graph.debug_object_slots():
		if str(slot.get("instance_id", "")) != instance_id:
			continue
		var variant = str(slot.get("connection_variant", ""))
		for part in required_parts:
			if not variant.split("_").has(str(part)):
				return false
		return true
	return false

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
