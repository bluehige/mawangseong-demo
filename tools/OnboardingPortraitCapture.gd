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

	var leon_captures := [
		["06_dialogue_leon_heroic_portrait.png", "LV10_DAY03_BATTLE_HERO", "boss_spawn", "CHR_HERO_LEON", "heroic"],
		["07_dialogue_leon_flustered_portrait.png", "LV10_DAY03_BATTLE_HERO", "boss_spawn", "CHR_HERO_LEON", "flustered"],
		["08_dialogue_leon_manual_portrait.png", "LV10_DAY03_BATTLE_HERO", "boss_spawn", "CHR_HERO_LEON", "manual"],
		["09_dialogue_leon_determined_portrait.png", "LV10_DAY03_BATTLE_HERO", "boss_hp_50", "CHR_HERO_LEON", "determined"],
		["10_dialogue_leon_defeated_portrait.png", "LV11_DAY03_RESULT_DEMO_CLEAR", "win", "CHR_HERO_LEON", "defeated"]
	]
	for capture in leon_captures:
		await _capture_dialogue_variant(capture[0], capture[1], capture[2], capture[3], capture[4])

	print("ONBOARDING_PORTRAIT_CAPTURE: %s" % output_dir)
	get_tree().quit(0)

func _capture_dialogue_variant(file_name: String, stage_id: String, trigger_id: String, speaker_id: String, emotion: String) -> void:
	var line = _find_dialogue_line(stage_id, trigger_id, speaker_id, emotion)
	if line.is_empty():
		push_error("Missing dialogue line for capture: %s %s %s %s" % [stage_id, trigger_id, speaker_id, emotion])
		return
	game._onboarding_set_stage(stage_id)
	game._onboarding_begin_dialogue([line], Constants.SCREEN_MANAGEMENT)
	await _settle()
	await _save(file_name)

func _find_dialogue_line(stage_id: String, trigger_id: String, speaker_id: String, emotion: String) -> Dictionary:
	for line in game.onboarding_flow.dialogue_for_trigger(trigger_id, stage_id):
		if not (line is Dictionary):
			continue
		if str(line.get("speaker", "")) == speaker_id and str(line.get("emotion", "")) == emotion:
			return line.duplicate(true)
	return {}

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
