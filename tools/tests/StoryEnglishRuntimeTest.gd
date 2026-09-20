extends Node

const GameScene = preload("res://scenes/game/GameRoot.tscn")
const Reader = preload("res://scripts/story/StoryDirector.gd")
var failures: Array[String] = []
var checks := 0
var game: Node

func _ready() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for i in range(6):
		await get_tree().process_frame

func _run() -> void:
	var language_snapshot := LanguageSettings.snapshot()
	var ui_snapshot := UISettings.snapshot()
	var history_snapshot := TutorialGuidanceHistory.snapshot()
	LanguageSettings.set_locale("en", false)
	UISettings.apply_snapshot({"text_scale":1.0, "layout_mode":UISettings.LAYOUT_AUTO}, false)
	game = GameScene.instantiate()
	add_child(game)
	await _settle()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.set_process(false)
	game.set_physics_process(false)
	_expect(LanguageSettings.story_catalog_error == "", "English story catalog loads")
	var catalog = game.story_catalog
	var first: Dictionary = catalog.scene("STORY_D01_MANAGEMENT_ENTRY").cues[0]
	var original := first.duplicate(true)
	_expect(LanguageSettings.story_text(first, "Aster").begins_with("Deep in the mountains"), "English lookup")
	_expect(LanguageSettings.story_text({"id":"UNKNOWN", "text_ko":"안녕 {{player_name}}"}, "Aster") == "안녕 Aster", "Untranslated cue falls back and replaces player")
	_expect(LanguageSettings.story_speaker({"speaker_id":"CHR_DARKLORD_PLAYER", "speaker_label":"마왕"}, "바티") == "바티", "Custom player name is never translated")
	_expect(LanguageSettings.story_speaker({"speaker_id":"NARRATOR", "speaker_label":"알 수 없는 편지"}, "Aster") == "알 수 없는 편지", "Unknown narrative role stays intact")
	_expect(LanguageSettings.story_speaker({"speaker_id":"CHR_GOB", "speaker_label":"곱"}, "Aster") == "Gob", "Resolved promoted character label is localized")
	var placeholder_cues := 0
	for id in catalog.all_scene_ids():
		var scene: Dictionary = catalog.scene(id)
		if int(scene.day) > 10:
			continue
		for cue in scene.cues:
			if str(cue.text_ko).contains("{{player_name}}"):
				placeholder_cues += 1
				var translated := LanguageSettings.story_text(cue, "Aster")
				_expect(translated.contains("Aster") and not translated.contains("{{player_name}}"), "Real player placeholder: " + str(cue.id))
	_expect(placeholder_cues > 0, "Real source placeholder coverage")
	_expect(first == original, "Resolver leaves source cue unchanged")
	_expect(game.story_director.start_scene("STORY_D01_MANAGEMENT_ENTRY", {"cycle_index":1}, "management", "", true), "Fullscreen scene starts")
	game._story_show_active_scene()
	await _settle()
	var body = game.ui_layer.find_child("StoryDialogueText", true, false)
	_expect(body != null and body.text == LanguageSettings.story_text(first, game._onboarding_player_name()), "Fullscreen uses English text")
	_expect(game.ui_layer.find_child("StoryNextButton", true, false).text == "Next", "Controls use English")
	var state: Dictionary = game.story_director.export_state()
	var expected_time := clampf(1.4 + float(body.text.length()) * 0.045, 2.2, 7.0)
	_expect(is_equal_approx(game.story_auto_remaining, expected_time), "Auto timer uses rendered text length")
	await _capture("fullscreen_en")
	LanguageSettings.set_locale("ko", false)
	await _settle()
	body = game.ui_layer.find_child("StoryDialogueText", true, false)
	_expect(body.text == first.text_ko, "Open dialogue refreshes to Korean")
	_expect(game.story_director.export_state() == state, "Language switch preserves story progress")
	LanguageSettings.set_locale("en", false)
	await _settle()
	_expect(game.story_director.export_state() == state, "English switch preserves story progress")
	game.story_combat_overlay_open = true
	game._set_screen("combat", false)
	await _settle()
	var paused_label = game.tutorial_targets.get("StoryCombatPausedLabel", {}).get("control")
	_expect(paused_label != null and paused_label.text == "Dialogue · Battle Paused", "Combat overlay localized")
	await _capture("overlay_en")
	game.story_combat_overlay_open = false
	game.story_presenter.clear_combat_overlay()
	game.story_director.reset_for_new_game()
	game.current_screen = "combat"
	var feed = game.combat_story_feed
	feed.reader = Reader.new()
	feed.reader.setup(catalog, 1)
	_expect(feed.reader.start_scene("STORY_D09_COMBAT_01", {}, "combat", "", true), "Combat feed scene starts")
	feed._show(game)
	await _settle()
	var feed_body: Label = game.tutorial_targets.get("StoryCombatFeedText", {}).get("control")
	_expect(feed_body.text.begins_with("Pudding anchors"), "Combat feed uses English")
	_expect(feed_body.get_line_count() == feed_body.get_visible_line_count(), "English combat feed fits")
	_expect(feed.panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and feed_body.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Feed never captures input")
	var feed_state: Dictionary = feed.reader.export_state()
	var log_snapshot = game.logs.duplicate()
	LanguageSettings.set_locale("ko", false)
	await _settle()
	_expect(feed.reader.export_state() == feed_state and game.logs == log_snapshot, "Feed language refresh does not advance or duplicate logs")
	LanguageSettings.set_locale("en", false)
	await _settle()
	await _capture("feed_en")
	feed.clear()
	game.story_director.seen_scene_ids.append("STORY_D01_MANAGEMENT_ENTRY")
	GameState.day = 10
	game._build_story_archive_overlay()
	await _settle()
	var archive_button = game.ui_layer.find_child("StoryArchive_STORY_D01_MANAGEMENT_ENTRY", true, false)
	_expect(archive_button != null and archive_button.text == "DAY 1 · Castle Affairs", "Archive shows English scene title without internal ID")
	await _capture("archive_en")
	game.queue_free()
	await _settle()
	LanguageSettings.apply_snapshot(language_snapshot, false)
	UISettings.apply_snapshot(ui_snapshot, false)
	TutorialGuidanceHistory.apply_snapshot(history_snapshot, false)
	print("STORY_ENGLISH_RUNTIME_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("res://tmp/story_english_validation")
	DirAccess.make_dir_recursive_absolute(directory)
	_expect(get_viewport().get_texture().get_image().save_png(directory.path_join(label + ".png")) == OK, "Capture " + label)
