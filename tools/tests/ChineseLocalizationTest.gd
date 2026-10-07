extends Node

const Game = preload("res://scenes/game/GameRoot.tscn")
const Fonts = preload("res://scripts/ui/UIFont.gd")
var failures: Array[String] = []
var checks := 0

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func frames() -> void:
	for index in range(6): await get_tree().process_frame

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var isolated_path := ProjectSettings.globalize_path("user://")
	expect(isolated_path.contains("zh_cn_work_20261007") or isolated_path.contains("zh_cn_fix_20261007"), "Test user directory must be isolated before any save")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	var original := LanguageSettings.snapshot()
	for value in ["zh", "zh-CN", "zh_CN", "zh-SG", "zh-Hans", "zh-Hans-CN"]:
		expect(LanguageSettings.normalize_locale(value) == "zh_CN", "Simplified locale: " + value)
	for value in ["zh-TW", "zh-HK", "zh-Hant", "zh-Hant-TW"]:
		expect(LanguageSettings.normalize_locale(value) == "ko", "Traditional locale remains unsupported: " + value)
	expect(LanguageSettings.normalize_locale("en-US") == "en" and LanguageSettings.normalize_locale("ko-KR") == "ko", "Existing regional locale compatibility")
	expect(LanguageSettings.display_name("zh-CN") == "简体中文", "Selector label")
	expect(LanguageSettings.ui_catalog_error == "" and LanguageSettings.story_catalog_error == "", "All catalogs load")
	LanguageSettings.set_locale("zh-CN", false)
	expect(LanguageSettings.ui_text("CAMPAIGN MODE") == "战役模式", "English-only decorative heading localized")
	expect(LanguageSettings.ui_text("REGION ROUTE") == "区域路线", "English-only route heading localized")
	expect(LanguageSettings.ui_text("E00 · 발견") == "E00 · 已发现", "Discovered ending status with catalog code")
	expect(LanguageSettings.ui_text("LIVING CASTLE / HEART COVENANT") == "活体城堡 / 城心契约", "Heart covenant subtitle")
	expect(LanguageSettings.ui_text("Compact · 1366/1280") == "紧凑布局 · 1366/1280", "Compact settings preview")
	expect(LanguageSettings.ui_text("Standard · 1920") == "标准布局 · 1920", "Standard settings preview")
	expect(LanguageSettings.ui_text("DAY 30") == "第30天", "Number-only day label")
	expect(LanguageSettings.ui_text("Stage 04") == "第04阶段", "Number-only castle stage")
	expect(LanguageSettings.ui_text("Lv.2") == "2级", "Number-only level label")
	expect(LanguageSettings.ui_text("곱 Lv.2") == "戈布 2级", "Name and level composition")
	expect(LanguageSettings.ui_text("castle_evolution_stage_02") == "castle_evolution_stage_02", "Internal identifier stays intact")
	LanguageSettings.chinese_translation.protected_name = "DAY 30"
	expect(LanguageSettings.ui_text("DAY 30") == "DAY 30", "Custom player name stays intact")
	expect(LanguageSettings.ui_text("DAY 30负责守城 · DAY 2") == "DAY 30负责守城 · 第2天", "Player name embedded in localized text stays intact")
	expect(LanguageSettings.ui_text("第3天，DAY 30终于回来了。") == "第3天，DAY 30终于回来了。", "Native story text retains a notation-shaped player name")
	LanguageSettings.chinese_translation.protected_name = ""
	expect(LanguageSettings.ui_text("곱") == "戈布", "Chinese NPC name")
	expect(LanguageSettings.player_display_name("곱") == "곱", "Custom alias identical to NPC is preserved")
	expect(LanguageSettings.player_display_name("新魔王🦊") == "新魔王🦊", "Chinese and Unicode custom name preserved")
	expect(LanguageSettings.player_display_name("신입 마왕") == "新任魔王", "Default name localized for display only")
	expect(LanguageSettings.story_ui("next") == "下一步", "Chinese dialogue controls")
	expect(Fonts.font_for_role(Fonts.ROLE_BODY) == Fonts.FALLBACK_FONT, "Explicit bundled CJK body font")
	var characters := {}
	var ui: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/localization/ui_zh_cn.json"))
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/localization/story_zh_cn.json"))
	var texts: Array = ui.messages.values()
	texts.append_array(ui.supplemental_messages.values())
	for section in ["cues", "scene_titles", "speaker_labels"]: texts.append_array(story[section].values())
	texts.append_array(LanguageSettings.catalog.zh_CN.values())
	for entry in story.ui.values(): texts.append(entry.zh_CN)
	for text in texts:
		for character in str(text):
			var code := character.unicode_at(0)
			if (code >= 0x4e00 and code <= 0x9fff) or (code >= 0x3000 and code <= 0x303f) or code in [0xff01, 0xff0c, 0xff1a, 0xff1b, 0xff1f]:
				characters[code] = true
	for code in characters: expect(Fonts.FALLBACK_FONT.has_char(code), "Bundled glyph: U+%04X" % code)
	var label := Label.new()
	label.text = "곱"
	add_child(label)
	expect(str(label.tr(label.text)) == "戈布", "Native Chinese Translation")
	LanguageSettings.set_locale("en", false)
	expect(str(label.tr(label.text)) == "Gob", "Native English after Chinese")
	LanguageSettings.set_locale("ko", false)
	expect(str(label.tr(label.text)) == "곱", "Native Korean after Chinese; fallback must not leak")
	expect(Fonts.font_for_role(Fonts.ROLE_BODY) == Fonts.BODY_FONT, "Original ko/en font roles")
	expect(Fonts.font_for_role(Fonts.ROLE_BUTTON).has_char("简".unicode_at(0)), "Chinese selector glyph available in Korean mode")
	var game = Game.instantiate()
	game.campaign_save_enabled = false
	add_child(game)
	await frames()
	game.set_process(false)
	game.set_physics_process(false)
	var saved_name := GameState.player_name
	GameState.player_name = "곱"
	var before: Dictionary = game._campaign_save_summary("management").duplicate(true)
	game._open_settings_screen()
	game._select_settings_category("general")
	game._on_language_preview_changed("zh_CN")
	await frames()
	var option: OptionButton = game.ui_layer.find_child("LanguageOption", true, false)
	expect(option != null and option.item_count == 3 and str(option.get_selected_metadata()) == "zh_CN", "Chinese selection preview")
	expect(option.get_popup().get_theme_font("font").has_char("简".unicode_at(0)), "Opened language menu has a Chinese glyph")
	expect(game._campaign_save_summary("management").player_name == "곱" and before.player_name == "곱", "Language preview leaves saved player name intact")
	game._cancel_settings_changes()
	await frames()
	expect(LanguageSettings.locale == "ko", "Cancel restores previous locale")
	LanguageSettings.set_locale("zh_CN", true)
	var config := ConfigFile.new()
	expect(config.load(LanguageSettings.SETTINGS_PATH) == OK and config.get_value("interface", "locale", "") == "zh_CN", "Apply persists canonical Chinese locale in isolated profile")
	LanguageSettings.set_locale("ko", false)
	LanguageSettings._load_settings()
	TranslationServer.set_locale(LanguageSettings.locale)
	expect(LanguageSettings.locale == "zh_CN", "Chinese persists across settings load")
	game.story_director.start_scene("STORY_D01_MANAGEMENT_ENTRY", {"cycle_index":1}, "management", "", true)
	game._story_show_active_scene()
	await frames()
	var state: Dictionary = game.story_director.export_state()
	var cue: Dictionary = game.story_catalog.scene("STORY_D01_MANAGEMENT_ENTRY").cues[0]
	var body: RichTextLabel = game.ui_layer.find_child("StoryDialogueText", true, false)
	expect(body != null and body.text == LanguageSettings.story_text(cue, "곱"), "Chinese actual story binding")
	for value in ["en", "ko", "zh_CN"]:
		LanguageSettings.set_locale(value, false)
		await frames()
		expect(game.story_director.export_state() == state, "Language switch preserves cue cursor and read state: " + value)
	GameState.player_name = saved_name
	game.queue_free()
	await frames()
	LanguageSettings.apply_snapshot(original, false)
	print("CHINESE_LOCALIZATION_TEST: %s (%d checks, %d bundled glyphs)" % ["PASS" if failures.is_empty() else "FAIL", checks, characters.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
