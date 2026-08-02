extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const PRODUCT_LAYOUT_ID := "v122_structural_wall_capture_product"
const PRODUCT_LAYOUT_PATH := "res://data/dungeon_quarter/layouts/stage01_dual_front_01.json"
const CUSTOM_LAYOUT_ID := "v122_structural_wall_capture_custom"
const CUSTOM_LAYOUT_PATH := "res://data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json"
const OUTPUT_DIR := "res://tmp/v122_structural_wall_review"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var product_layout := _load_json(PRODUCT_LAYOUT_PATH)
	var custom_layout := _load_json(CUSTOM_LAYOUT_PATH)
	if product_layout.is_empty() or custom_layout.is_empty():
		push_error("구조 벽 캡처용 레이아웃을 읽지 못했습니다.")
		get_tree().quit(1)
		return

	var game = GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	DataRegistry.register_quarter_layout(PRODUCT_LAYOUT_ID, product_layout, false)
	DataRegistry.register_quarter_layout(CUSTOM_LAYOUT_ID, custom_layout, false)
	game.update3_active_run["update3_enabled"] = true
	game.update3_active_run["front_selection_completed"] = true
	game.update3_active_run["front_id"] = "structural_wall_capture"
	game.v122_connector_state = {
		"connector_id": "rear_cross_lane_connector",
		"built": false,
		"built_day": 0
	}
	GameState.gold = 1200
	GameState.mana = 150

	var cases := [
		{"name": "stage_01_cave", "layout_id": PRODUCT_LAYOUT_ID, "stage": "stage_01_cave", "day": 1},
		{"name": "stage_02_castle", "layout_id": PRODUCT_LAYOUT_ID, "stage": "stage_02_castle", "day": 16},
		{"name": "stage_03_keep", "layout_id": PRODUCT_LAYOUT_ID, "stage": "stage_03_keep", "day": 21},
		{"name": "stage_04_citadel", "layout_id": PRODUCT_LAYOUT_ID, "stage": "stage_04_citadel", "day": 30},
		{"name": "custom_branch_map", "layout_id": CUSTOM_LAYOUT_ID, "stage": "stage_01_cave", "day": 3}
	]
	for case_value in cases:
		var capture_case: Dictionary = case_value
		game.quarter_layout_id = str(capture_case["layout_id"])
		game.castle_art_stage = str(capture_case["stage"])
		GameState.day = int(capture_case["day"])
		game.rooms = DataRegistry.rooms.duplicate(true)
		game._sync_castle_stage_content()
		game._setup_dungeon_graph()
		game._init_room_directives()
		game._set_screen(Constants.SCREEN_MANAGEMENT)
		game.quarter_renderer.refresh_layout()
		await _settle(5)
		if not await _save_case(str(capture_case["name"])):
			get_tree().quit(1)
			return

	game._shutdown_audio_for_exit()
	print("V122_STRUCTURAL_WALL_CAPTURE: PASS")
	get_tree().quit(0)


func _save_case(case_name: String) -> bool:
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != Vector2i(1280, 720):
		push_error("%s 1280x720 화면을 읽지 못했습니다." % case_name)
		return false
	var full_path := ProjectSettings.globalize_path(OUTPUT_DIR).path_join("%s_1280x720.png" % case_name)
	if image.save_png(full_path) != OK:
		push_error("%s 전체 화면을 저장하지 못했습니다." % case_name)
		return false
	var crop_rect := Rect2i(210, 70, 800, 480)
	var crop := image.get_region(crop_rect)
	var crop_path := ProjectSettings.globalize_path(OUTPUT_DIR).path_join("%s_map_crop.png" % case_name)
	if crop.save_png(crop_path) != OK:
		push_error("%s 맵 영역을 저장하지 못했습니다." % case_name)
		return false
	return true


func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	await get_tree().create_timer(0.04).timeout
