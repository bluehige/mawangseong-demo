extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	output_dir = ProjectSettings.globalize_path("res://tmp/manual_verification")
	DirAccess.make_dir_recursive_absolute(output_dir)

	game = GameRootScene.instantiate()
	add_child(game)
	await _settle()
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await _settle()
	game._select_room("barracks")
	await _settle()
	await _save("01_management.png")
	game._build_selected_slot()
	await _settle()
	await _save("01_build_pick_mode.png")
	game._cancel_management_action_mode()
	await _settle()
	game._handle_left_click(game.graph.center("slot_01"))
	await _settle()
	await _save("01_map_click_facility_palette.png")
	game._cancel_management_action_mode()
	await _settle()
	game._start_monster_placement("slime")
	await _settle()
	await _save("01_monster_pick_mode.png")
	game._cancel_management_action_mode()
	await _settle()
	game._change_selected_room_facility("watch_post")
	await _settle()
	await _save("01_watch_post_facility.png")
	await _reset_game()
	game._select_room("barracks")
	await _settle()
	game._open_map_editor()
	await _settle()
	await _save("01_map_editor.png")
	var drag_candidate: Dictionary = game._map_editor_preview_gap_path_candidate()
	if not drag_candidate.is_empty():
		var drag_source = str(drag_candidate.get("source_instance", game.selected_room))
		var drag_target = str(drag_candidate.get("other_instance", ""))
		if drag_target != "":
			game._start_map_editor_path_drag(game.graph.center(drag_source))
			game._update_map_editor_path_drag(game.graph.center(drag_target))
			await _settle()
			await _save("01_map_editor_drag_connect.png")
			game._finish_map_editor_path_drag(game.graph.center(drag_target))
			await _settle()
			await _save("01_map_editor_drag_connected.png")
			game._start_map_editor_path_drag(game.graph.center(drag_target))
			game._update_map_editor_path_drag(game.graph.center(drag_source))
			await _settle()
			await _save("01_map_editor_drag_disconnect.png")
			game._finish_map_editor_path_drag(game.graph.center(drag_source))
			await _settle()
	game._map_editor_disconnect_selected_room()
	await _settle()
	await _save("01_map_editor_disconnected.png")
	game._cancel_map_editor()
	await _settle()

	game._set_screen(Constants.SCREEN_MONSTER)
	await _settle()
	await _save("02_monster.png")

	GameState.day = 4
	game._open_raid_screen()
	await _settle()
	await _save("02_raid_screen.png")
	game._start_selected_raid()
	await _settle()
	await _save("02_raid_result.png")
	await _reset_game()

	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle()
	game._start_combat()
	await _settle()
	game._spawn_ready_enemies(0.2)
	await _settle()
	await _save("03_combat_start.png")

	var trap_enemy = _first_alive_enemy()
	if trap_enemy != null:
		trap_enemy.current_room = "spike_corridor"
		trap_enemy.global_position = game.graph.center("spike_corridor")
		game.trap_cooldown = 0.0
		game._update_room_effects(2.0)
	await _settle()
	await _save("04_combat_trap_trigger.png")

	var imp = _unit_by_id(game.monster_units, "imp")
	if imp != null:
		game._select_unit(imp)
		game.combat_scene.try_auto_monster_skill(imp)
	await _settle()
	await _save("05_combat_controls.png")

	game.wave_manager.next_index = game.wave_manager.schedule.size()
	for enemy in game.enemy_units.duplicate():
		if is_instance_valid(enemy) and enemy.is_alive():
			enemy.receive_damage(9999)
	game._check_combat_end()
	await _settle()
	await _save("06_result.png")

	print("MANUAL_VERIFICATION_CAPTURE: %s" % output_dir)
	get_tree().quit(0)

func _settle() -> void:
	for i in range(12):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().create_timer(0.06).timeout

func _reset_game() -> void:
	remove_child(game)
	game.queue_free()
	await _settle()
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle()
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await _settle()

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
		push_error("Viewport did not produce a complete manual verification frame")
		return
	var path = "%s/%s" % [output_dir, file_name]
	var err = image.save_png(path)
	if err != OK:
		push_error("Failed to save screenshot: %s" % path)

func _capture_has_ui(image: Image) -> bool:
	if image == null or image.is_empty():
		return false
	var width := image.get_width()
	var height := image.get_height()
	var sample_y := clampi(roundi(float(height) * 0.04), 0, height - 1)
	var visible_samples := 0
	for x_ratio in [0.025, 0.073, 0.18, 0.34, 0.65, 0.81]:
		var color := image.get_pixelv(Vector2i(roundi(float(width) * x_ratio), sample_y))
		if color.a > 0.80 and maxf(color.r, maxf(color.g, color.b)) > 0.025:
			visible_samples += 1
	return visible_samples >= 5

func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null

func _first_alive_enemy() -> Node:
	for unit in game.enemy_units:
		if unit.is_alive():
			return unit
	return null
