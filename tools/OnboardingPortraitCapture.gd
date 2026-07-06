extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	output_dir = ProjectSettings.globalize_path("res://tmp/onboarding_portrait_verification")
	DirAccess.make_dir_recursive_absolute(output_dir)

	game = GameRootScene.instantiate()
	add_child(game)
	await _settle()
	await _save("01_title.png")

	game._onboarding_start_new_game()
	await _settle()
	await _save("02_name_entry_bati_portrait.png")

	game.onboarding_name_input.text = "스샷마왕"
	game._onboarding_confirm_name()
	await _settle()
	await _save("03_dialogue_first_portrait.png")

	await _advance_to_speaker("CHR_BATI")
	await _save("04_dialogue_bati_portrait.png")

	await _advance_to_speaker("CHR_GOLDIN")
	await _save("05_dialogue_goldin_portrait.png")

	print("ONBOARDING_PORTRAIT_CAPTURE: %s" % output_dir)
	get_tree().quit(0)

func _advance_to_speaker(speaker_id: String, max_steps: int = 80) -> void:
	for _step in range(max_steps):
		if game.current_screen != Constants.SCREEN_DIALOGUE:
			return
		var line = game.onboarding_dialogue_queue[game.onboarding_dialogue_index]
		if line is Dictionary and str(line.get("speaker", "")) == speaker_id:
			await _settle()
			return
		game._onboarding_advance_dialogue()
		await _settle()
	push_error("Timed out while advancing to speaker: %s" % speaker_id)

func _settle() -> void:
	for _i in range(10):
		await get_tree().process_frame

func _save(file_name: String) -> void:
	await get_tree().process_frame
	var image = get_viewport().get_texture().get_image()
	var path = "%s/%s" % [output_dir, file_name]
	var err = image.save_png(path)
	if err != OK:
		push_error("Failed to save screenshot: %s" % path)
