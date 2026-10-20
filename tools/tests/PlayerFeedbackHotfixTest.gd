extends Node

const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const Constants = preload("res://scripts/core/Constants.gd")
var game: Node
var checks := 0
var failures: Array[String] = []
var output_dir := "res://tmp/player_feedback"

func _ready() -> void:
	get_tree().create_timer(90.0).timeout.connect(func():
		push_error("PlayerFeedbackHotfixTest timed out")
		get_tree().quit(1))
	call_deferred("run")

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for i in range(8):
		await get_tree().process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await settle()
	print("Capture: " + name)
	get_viewport().get_texture().get_image().save_png(output_dir.path_join(name + ".png"))

func click(control: Control, offset: Vector2 = Vector2(20, 20), button: int = MOUSE_BUTTON_LEFT, double_click: bool = false) -> void:
	var point := control.get_global_transform_with_canvas() * offset
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = button
		event.pressed = pressed
		event.double_click = double_click
		get_viewport().push_input(event, true)
	await settle()

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").contains("player_feedback"), "use isolated player_feedback user data")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game = GameRootScene.instantiate()
	add_child(game)
	await settle()
	expect(ProjectSettings.get_setting("application/config/version") == "1.3.0", "product version remains 1.3.0")
	await capture("title_windowed")

	var original := UISettings.snapshot()
	UISettings.set_window_mode(UISettings.FULLSCREEN, false)
	expect(UISettings.snapshot().window_mode == "fullscreen", "fullscreen in settings snapshot")
	if UISettings.supports_window_mode():
		await settle()
		expect(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN, "native fullscreen mode applied")
	UISettings.apply_snapshot(original, false)
	if UISettings.supports_window_mode():
		await settle()
		expect(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED, "native windowed mode restored")
		expect(not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS), "window has title bar")
	UISettings.set_window_mode("invalid", false)
	expect(UISettings.window_mode == UISettings.DEFAULT_WINDOW_MODE, "invalid mode safely falls back")
	UISettings.set_window_mode(UISettings.FULLSCREEN, true)
	UISettings.set_window_mode(UISettings.WINDOWED, false)
	UISettings._load_settings()
	expect(UISettings.window_mode == UISettings.FULLSCREEN, "saved window mode loads on restart")
	UISettings.set_window_mode(UISettings.WINDOWED, true)
	await settle()
	for locale in ["ko", "en", "zh_CN"]:
		LanguageSettings.set_locale(locale, false)
		game._open_settings_screen()
		await settle()
		for key in ["window_mode", "windowed", "fullscreen", "window_mode_help"]:
			expect(not LanguageSettings.text("settings.display." + key).begins_with("settings."), "translated display setting " + locale + "/" + key)
		if UISettings.supports_window_mode():
			expect(game.ui_layer.find_child("WindowModeOption", true, false) != null, "window mode option visible " + locale)
		await capture("settings_" + locale)
		if UISettings.supports_window_mode():
			var key := InputEventKey.new()
			key.keycode = KEY_ENTER
			key.alt_pressed = true
			key.pressed = true
			get_viewport().push_input(key, true)
			expect(UISettings.window_mode == UISettings.FULLSCREEN, "Alt+Enter previews mode in settings")
			await settle()
		else:
			UISettings.set_window_mode(UISettings.FULLSCREEN, false)
		game._cancel_settings_changes()
		await settle()
		expect(UISettings.window_mode == UISettings.WINDOWED, "cancel restores previous window mode")
		UISettings._load_settings()
		expect(UISettings.window_mode == UISettings.WINDOWED, "cancel does not persist Alt+Enter preview")
		await settle()
	LanguageSettings.set_locale("ko", false)

	game.hud.clear()
	var comparison: Control = game._onboarding_screen_panel(Color("#100d14"))
	var protagonist_min_size := Vector2(10000, 10000)
	for emotion in ["", "proud", "offended", "flustered", "serious", "command"]:
		var panel: Control = game._onboarding_add_portrait(comparison, Rect2(60, 430, 328, 510), "CHR_DARKLORD_PLAYER", "마왕", emotion, false)
		var portrait: TextureRect = panel.get_node("CharacterPortraitImage")
		protagonist_min_size.x = minf(protagonist_min_size.x, portrait.size.x)
		protagonist_min_size.y = minf(protagonist_min_size.y, portrait.size.y)
		if emotion != "":
			comparison.remove_child(panel)
			panel.queue_free()
	var column := 1
	for id in ["CHR_BATI", "CHR_ROLO", "CHR_GOB", "CHR_PUDDING"]:
		var portrait_data: Dictionary = game._onboarding_speaker_portrait_data(id)
		var emotions: Array = [""]
		emotions.append_array(portrait_data.get("variants", {}).keys())
		for emotion in emotions:
			var panel: Control = game._onboarding_add_portrait(comparison, Rect2(60 + 370 * column, 430, 328, 510), id, game._onboarding_speaker_name(id), str(emotion), false)
			var portrait: TextureRect = panel.get_node("CharacterPortraitImage")
			expect(portrait.size.x < protagonist_min_size.x and portrait.size.y < protagonist_min_size.y, "protagonist larger than " + id + "/" + str(emotion))
			expect(panel.get_rect().size == Vector2(328, 510), "portrait panel remains stable")
			if emotion != "":
				comparison.remove_child(panel)
				panel.queue_free()
		column += 1
	await settle()
	await capture("portrait_comparison")
	for id in DataRegistry.characters:
		if id == "CHR_DARKLORD_PLAYER":
			continue
		var data: Dictionary = game._onboarding_speaker_portrait_data(id)
		if data.is_empty():
			continue
		var emotions: Array = [""]
		emotions.append_array(data.get("variants", {}).keys())
		for emotion in emotions:
			var panel: Control = game._onboarding_add_portrait(comparison, Rect2(60, 430, 328, 510), id, id, str(emotion), false)
			var portrait: TextureRect = panel.get_node_or_null("CharacterPortraitImage")
			if portrait != null:
				expect(portrait.size.x < protagonist_min_size.x and portrait.size.y < protagonist_min_size.y, "every character/emotion smaller than protagonist: " + id + "/" + str(emotion))
			comparison.remove_child(panel)
			panel.queue_free()

	game._onboarding_begin_dialogue([
		{"speaker": "CHR_DARKLORD_PLAYER", "text": "첫 번째 대사", "text_ko": "첫 번째 대사"},
		{"speaker": "CHR_BATI", "text": "두 번째 대사", "text_ko": "두 번째 대사"},
		{"speaker": "CHR_ROLO", "text": "세 번째 대사", "text_ko": "세 번째 대사"}
	], Constants.SCREEN_TITLE)
	await settle()
	await capture("dialogue_player")
	await click(game.ui_layer.find_child("DialogueTextPanel", true, false))
	expect(game.onboarding_dialogue_index == 1, "dialogue background click advances exactly once")
	await capture("dialogue_bati")
	var label: Control = game.ui_layer.find_child("DialogueText", true, false)
	await click(label, Vector2(20, 20), MOUSE_BUTTON_RIGHT)
	expect(game.onboarding_dialogue_index == 1, "right click does not advance")
	await click(label, Vector2(20, 20), MOUSE_BUTTON_WHEEL_DOWN)
	expect(game.onboarding_dialogue_index == 1, "scroll does not advance")
	await click(label, Vector2(20, 20), MOUSE_BUTTON_LEFT, true)
	expect(game.onboarding_dialogue_index == 1, "double-click second event does not skip a cue")
	await click(label)
	expect(game.onboarding_dialogue_index == 2, "text click advances exactly once")
	await click(game.ui_layer.find_child("DialogueTextPanel", true, false))
	expect(game.current_screen == Constants.SCREEN_TITLE, "last click returns to intended screen")

	game._onboarding_reset_game()
	game._onboarding_enter_management_day(1, true)
	await settle()
	var cursor: int = game.story_director.cursor
	await click(game.ui_layer.find_child("StoryDialogueText", true, false))
	expect(game.story_director.cursor == cursor + 1, "main story text click advances exactly once")
	while game.story_director.is_active():
		game._story_advance_dialogue(true)
	await settle()
	game._set_screen(Constants.SCREEN_COMBAT)
	game.story_director.start_scene("STORY_D01_COMBAT_TIME_01", game._story_context({"combat_time": 0.0}), Constants.SCREEN_COMBAT)
	game._story_show_active_scene()
	await settle()
	expect(game.combat_paused, "combat remains paused during dialogue")
	await capture("combat_dialogue")
	cursor = game.story_director.cursor
	await click(game.ui_layer.find_child("StoryDialogueTextPanel", true, false))
	expect(game.story_director.cursor == cursor + 1, "combat dialogue background click advances exactly once")
	var auto: Button = game.ui_layer.find_child("StoryAutoButton", true, false)
	cursor = game.story_director.cursor
	await click(auto)
	expect(game.story_director.cursor == cursor, "Auto button does not also advance")
	game._story_toggle_auto()
	while game.story_director.is_active():
		await click(game.ui_layer.find_child("StoryDialogueText", true, false))
	expect(not game.story_combat_overlay_open and not game.combat_paused, "final combat dialogue click resumes battle")
	UISettings.apply_snapshot(original, true)
	game.queue_free()
	await settle()
	print("PlayerFeedbackHotfixTest: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
