extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	output_dir = ProjectSettings.globalize_path("res://tmp/v122_day02_feedback_visual")
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(5)
	game._debug_skip_onboarding()
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game.management_context_drawer_open = false
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(5)
	await _save("01_management_roster.png")
	game._select_room("treasure")
	await _settle(5)
	await _save("01b_treasure_label_1920x1080.png")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await _settle(5)
	await _save("01c_treasure_label_1280x720.png")
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	game.selected_room = "spike_corridor"
	game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
	await _settle(5)
	await _save("01d_room_directive_badge.png")

	var facility_room: String = "slot_01" if game.rooms.has("slot_01") else str(game._first_changeable_room())
	game.management_context_drawer_open = true
	game._select_room(facility_room)
	await _settle(5)
	await _save("02_contextual_facility_palette.png")
	var choices: Array = game._build_facility_choices()
	if not choices.is_empty():
		game._set_contextual_build_facility(str(choices.front()), facility_room)
		await _settle(5)
		await _save("03_contextual_facility_preview.png")

	game._clear_management_action_mode(false)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._start_combat()
	await _settle(6)
	if game.current_screen != Constants.SCREEN_COMBAT:
		game._set_screen(Constants.SCREEN_MANAGEMENT)
		game._start_combat()
		await _settle(6)
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await _settle(5)
	await _save("04_management_without_combat_actors.png")
	game._set_screen(Constants.SCREEN_COMBAT)
	game._issue_v122_command("rally")
	await _settle(5)
	await _save("05_command_targeting.png")
	game._cancel_v122_command_targeting()
	var goblin := _unit_by_id(game.monster_units, "goblin")
	if goblin != null:
		game._handle_left_click(goblin.global_position)
		await _settle(5)
		await _save("06_ally_inspector.png")
	game.combat_scene.spawn_enemy("explorer")
	await _settle(3)
	game._issue_v122_command("focus")
	await _settle(5)
	await _save("07_focus_targeting.png")
	game._cancel_v122_command_targeting()
	var explorer := _unit_by_id(game.enemy_units, "explorer")
	if explorer != null:
		game._handle_left_click(explorer.global_position)
		await _settle(5)
		await _save("08_enemy_inspector.png")

	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	game._onboarding_set_stage("LV07_DAY02_BATTLE_THIEF")
	for index in range(game.tutorial_manager.steps.size()):
		if str(game.tutorial_manager.steps[index].get("id", "")) == "TUT_130_GOBLIN_CONTROL":
			game.tutorial_manager.current_index = index
			game.tutorial_manager.active = true
			break
	game._tutorial_build_overlay()
	await _settle(5)
	await _save("09_goblin_observation.png")
	print("V122_DAY02_VISUAL_CAPTURE: %s" % output_dir)
	get_tree().quit(0)


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw


func _save(file_name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(output_dir.path_join(file_name))
	if error != OK:
		push_error("capture failed: %s" % file_name)


func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit != null and is_instance_valid(unit) and unit.is_alive() and str(unit.unit_id) == unit_id:
			return unit
	return null
