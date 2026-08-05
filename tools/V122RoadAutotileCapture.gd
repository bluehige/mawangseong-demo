extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const OUTPUT_DIR := "res://tmp/v122_road_autotile_review"


func _ready() -> void:
	print("V122_ROAD_AUTOTILE_CAPTURE: READY")
	call_deferred("_run")


func _run() -> void:
	print("V122_ROAD_AUTOTILE_CAPTURE: START")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var game = GameRootScene.instantiate()
	add_child(game)
	print("V122_ROAD_AUTOTILE_CAPTURE: GAME_ADDED")
	await _settle(18)
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await _settle(12)
	game.castle_art_stage = "stage_01_cave"
	GameState.day = 3
	GameState.gold = 1200
	GameState.mana = 150
	game.v122_connector_state = {
		"connector_id": "rear_cross_lane_connector",
		"built": false,
		"built_day": 0
	}
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	game._init_room_directives()
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game.quarter_renderer.refresh_layout()
	await _settle(14)
	_print_corridor_mask_summary(game)
	if not _validate_corridor_structure(game, false):
		get_tree().quit(1)
		return
	if not _save_viewport("stage_01_day03_connector_unbuilt_1280x720.png"):
		get_tree().quit(1)
		return
	if not _save_viewport_crop(
		"stage_01_day03_connector_unbuilt_map_crop.png",
		Rect2i(210, 70, 800, 480)
	):
		get_tree().quit(1)
		return
	if not game._build_v122_defender_connector():
		push_error("DAY 3 defender connector construction failed during capture")
		get_tree().quit(1)
		return
	game.quarter_renderer.refresh_layout()
	await _settle(10)
	if not _validate_corridor_structure(game, true):
		get_tree().quit(1)
		return
	if not _save_viewport("stage_01_day03_connector_built_1280x720.png"):
		get_tree().quit(1)
		return
	if not _save_viewport_crop(
		"stage_01_day03_connector_built_map_crop.png",
		Rect2i(210, 70, 800, 480)
	):
		get_tree().quit(1)
		return
	if not _save_viewport_crop(
		"stage_01_day03_connector_built_detail.png",
		Rect2i(510, 205, 280, 260)
	):
		get_tree().quit(1)
		return
	print("V122_ROAD_AUTOTILE_CAPTURE: PASS")
	get_tree().quit(0)


func _save_viewport(filename: String) -> bool:
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("1280x720 road autotile capture failed")
		return false
	var output_path := ProjectSettings.globalize_path(OUTPUT_DIR).path_join(filename)
	var error := image.save_png(output_path)
	if error != OK:
		push_error("road autotile capture write failed: %s" % error)
		return false
	return true


func _save_viewport_crop(filename: String, crop_rect: Rect2i) -> bool:
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("1280x720 corridor crop source is empty")
		return false
	var bounded_rect := crop_rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if bounded_rect.size != crop_rect.size:
		push_error("corridor crop is outside the viewport: %s" % crop_rect)
		return false
	var crop := image.get_region(bounded_rect)
	var output_path := ProjectSettings.globalize_path(OUTPUT_DIR).path_join(filename)
	var error := crop.save_png(output_path)
	if error != OK:
		push_error("corridor crop write failed: %s" % error)
		return false
	return true


func _print_corridor_mask_summary(game: Node) -> void:
	var counts: Dictionary = {}
	var tile_grid: Dictionary = game.quarter_renderer._tile_grid_for_draw()
	for record in tile_grid.get("cells", []):
		if not bool(record.get("data", {}).get("is_corridor", false)):
			continue
		var mask := int(record.get("mask", 0))
		counts[mask] = int(counts.get(mask, 0)) + 1
	print("V122_ROAD_MASK_COUNTS: %s" % counts)


func _validate_corridor_structure(game: Node, connector_built: bool) -> bool:
	var renderer = game.quarter_renderer
	var visual_floor: Dictionary = renderer.debug_visual_floor_cells()
	for record in renderer.debug_wall_edge_records():
		var cell: Vector2i = record.get("cell", Vector2i.ZERO)
		var side := str(record.get("side", ""))
		if renderer.debug_visual_edge_open(cell, side):
			push_error("corridor capture rejected a wall on an open floor edge: %s/%s" % [cell, side])
			return false
	var connector_cells := [Vector2i(18, 12), Vector2i(19, 12), Vector2i(18, 13), Vector2i(19, 13)]
	for cell in connector_cells:
		if visual_floor.has(cell) != connector_built:
			push_error("corridor capture connector topology mismatch: %s built=%s" % [cell, connector_built])
			return false
	return true


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame
	# 정지 화면에서는 frame_post_draw 신호가 다시 오지 않을 수 있으므로 직접 한 프레임을 합성한다.
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	await get_tree().create_timer(0.06).timeout
