extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const STAGES := ["stage_01_cave", "stage_02_castle", "stage_03_keep", "stage_04_citadel"]

var output_dir := ""

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	output_dir = ProjectSettings.globalize_path("res://tmp/castle_stage_review")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var game = GameRootScene.instantiate()
	add_child(game)
	await _settle(18)
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await _settle(12)
	var records: Array = []
	for stage_id in STAGES:
		game.castle_art_stage = stage_id
		game._sync_castle_stage_content()
		game._setup_dungeon_graph()
		game._init_room_directives()
		game._set_screen(Constants.SCREEN_MANAGEMENT)
		game.quarter_renderer.refresh_layout()
		await _settle(14)
		var stage_info: Dictionary = game._castle_stage_info()
		var file_name := "%s_1920x1080.png" % stage_id
		await _save(file_name)
		records.append({
			"stage_id": stage_id,
			"rendered_room_count": game.quarter_renderer.debug_full_grid_room_projection_count(),
			"declared_room_count": int(stage_info.get("area_room_count", 0)),
			"unlocked_room_grid_ids": game.graph.debug_unlocked_room_grid_ids(),
			"active_cell_count": game.graph.debug_active_cells().size(),
			"tile_visual_scale": game.graph.debug_tile_visual_scale(),
			"screenshot": "tmp/castle_stage_review/%s" % file_name
		})
	var report := {
		"viewport": [1920, 1080],
		"stages": records
	}
	var report_file := FileAccess.open(output_dir.path_join("latest.json"), FileAccess.WRITE)
	if report_file == null:
		push_error("Failed to write castle stage visual report")
		get_tree().quit(1)
		return
	report_file.store_string(JSON.stringify(report, "  "))
	report_file.close()
	print("CASTLE_STAGE_VISUAL_REVIEW: PASS")
	get_tree().quit(0)

func _settle(frame_count: int) -> void:
	for _index in range(frame_count):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().create_timer(0.06).timeout

func _save(file_name: String) -> void:
	var image: Image
	for _attempt in range(8):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var texture := get_viewport().get_texture()
		if texture != null:
			image = texture.get_image()
			if _capture_has_ui(image):
				break
	if image == null or not _capture_has_ui(image):
		push_error("Viewport did not produce a complete castle-stage UI frame")
		get_tree().quit(1)
		return
	var error := image.save_png(output_dir.path_join(file_name))
	if error != OK:
		push_error("Failed to save castle stage screenshot: %s" % file_name)

func _capture_has_ui(image: Image) -> bool:
	if image == null or image.is_empty():
		return false
	var width := image.get_width()
	var height := image.get_height()
	var sample_y := clampi(roundi(float(height) * 0.04), 0, height - 1)
	var sample_points = [
		Vector2i(roundi(float(width) * 0.025), sample_y),
		Vector2i(roundi(float(width) * 0.073), sample_y),
		Vector2i(roundi(float(width) * 0.18), sample_y),
		Vector2i(roundi(float(width) * 0.34), sample_y),
		Vector2i(roundi(float(width) * 0.65), sample_y),
		Vector2i(roundi(float(width) * 0.81), sample_y)
	]
	var visible_samples := 0
	for point in sample_points:
		var color := image.get_pixelv(point)
		if color.a > 0.80 and maxf(color.r, maxf(color.g, color.b)) > 0.025:
			visible_samples += 1
	return visible_samples >= 5
