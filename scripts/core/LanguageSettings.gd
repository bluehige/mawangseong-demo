extends Node

signal locale_changed(locale: String)

const SETTINGS_PATH = "user://settings.cfg"
const SETTINGS_SECTION = "interface"
const CATALOG_PATH = "res://data/localization/v122_stage10_ui.json"
const STORY_CATALOG_PATH = "res://data/localization/story_en.json"
const UI_CATALOG_PATH = "res://data/localization/ui_en.json"
const EnglishTranslationScript = preload("res://scripts/core/EnglishTranslation.gd")
const LOCALE_KOREAN = "ko"
const LOCALE_ENGLISH = "en"
const SUPPORTED_LOCALES = [LOCALE_KOREAN, LOCALE_ENGLISH]
const SCOPE_PREFIXES = {
	"settings": "settings.",
	"name_entry": "name.",
	"tutorial_day1_3": "tutorial."
}

var locale := LOCALE_KOREAN
var catalog: Dictionary = {}
var catalog_error := ""
var story_catalog: Dictionary = {}
var story_catalog_error := ""
var ui_catalog_error := ""
var english_translation = EnglishTranslationScript.new()

func _ready() -> void:
	_load_catalog()
	_load_story_catalog()
	_load_ui_catalog()
	_load_settings()
	TranslationServer.set_locale(locale)
	_update_window_title()

func _exit_tree() -> void:
	TranslationServer.remove_translation(english_translation)

func set_locale(value: String, persist: bool = true) -> void:
	var next_locale := normalize_locale(value)
	if locale == next_locale:
		return
	locale = next_locale
	TranslationServer.set_locale(locale)
	_update_window_title()
	if persist:
		_save_settings()
	locale_changed.emit(locale)

func ui_text(source: String) -> String:
	return english_translation.translate_text(source) if locale == LOCALE_ENGLISH else source

func _update_window_title() -> void:
	DisplayServer.window_set_title("Who Guards the Demon Castle?" if locale == LOCALE_ENGLISH else str(ProjectSettings.get_setting("application/config/name")))

func _load_ui_catalog() -> void:
	var values: Dictionary = {}
	if FileAccess.file_exists(UI_CATALOG_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(UI_CATALOG_PATH))
		if parsed is Dictionary and parsed.get("messages") is Dictionary:
			values = parsed.messages.duplicate()
		else:
			ui_catalog_error = "Invalid English UI catalog"
	else:
		ui_catalog_error = "Missing English UI catalog"
	for key in catalog.get(LOCALE_KOREAN, {}):
		values[str(catalog[LOCALE_KOREAN][key])] = str(catalog.get(LOCALE_ENGLISH, {}).get(key, catalog[LOCALE_KOREAN][key]))
	for key in story_catalog.get("speaker_labels", {}):
		values[str(key)] = str(story_catalog.speaker_labels[key])
	# Language-neutral composition templates still contain localized names/counts.
	for template in ["%s %d", "%s %d/%d", "%s Lv.%d", "%s x%d", "%s × %d", "%s %d→%d", "%s (%s)", "[%s]", "• %s", "—  %s"]:
		values[template] = template
	english_translation.configure(values)
	TranslationServer.add_translation(english_translation)

func normalize_locale(value: String) -> String:
	var language := value.to_lower().split("_")[0].split("-")[0]
	return language if language in SUPPORTED_LOCALES else LOCALE_KOREAN

func display_name(value: String) -> String:
	return "English" if normalize_locale(value) == LOCALE_ENGLISH else "한국어"

func text(key: String, replacements: Dictionary = {}) -> String:
	if catalog.is_empty():
		_load_catalog()
	var active_catalog: Dictionary = catalog.get(locale, {})
	var korean_catalog: Dictionary = catalog.get(LOCALE_KOREAN, {})
	var result := str(active_catalog.get(key, korean_catalog.get(key, key)))
	for replacement_key in replacements:
		result = result.replace(
			"{{%s}}" % str(replacement_key),
			str(replacements[replacement_key])
		)
	return result

func catalog_keys(scope_id: String = "") -> Array[String]:
	if catalog.is_empty():
		_load_catalog()
	var prefix := str(SCOPE_PREFIXES.get(scope_id, ""))
	var seen: Dictionary = {}
	for locale_id in SUPPORTED_LOCALES:
		var locale_catalog: Dictionary = catalog.get(locale_id, {})
		for key in locale_catalog:
			var text_key := str(key)
			if prefix == "" or text_key.begins_with(prefix):
				seen[text_key] = true
	var result: Array[String] = []
	for key in seen:
		result.append(str(key))
	result.sort()
	return result

func story_text(cue: Dictionary, player_name: String) -> String:
	return _story_translation("cues", str(cue.get("id", "")), str(cue.get("text_ko", ""))).replace("{{player_name}}", player_display_name(player_name))

func player_display_name(player_name: String) -> String:
	return ui_text("신입 마왕") if player_name.strip_edges() == "" or player_name == "신입 마왕" else player_name

func story_title(scene: Dictionary, fallback: String = "") -> String:
	var original := str(scene.get("title", fallback))
	if original == "":
		original = story_ui("main_story")
	return _story_translation("scene_titles", str(scene.get("id", "")), original)

func story_speaker(resolved: Dictionary, player_name: String) -> String:
	if str(resolved.get("speaker_id", "")) == "CHR_DARKLORD_PLAYER":
		return player_display_name(player_name)
	var label := str(resolved.get("speaker_label", ""))
	return _story_translation("speaker_labels", label, label)

func story_ui(key: String) -> String:
	var entry: Dictionary = story_catalog.get("ui", {}).get(key, {})
	return str(entry.get(locale, entry.get(LOCALE_KOREAN, key)))

func _story_translation(section: String, key: String, fallback: String) -> String:
	if locale != LOCALE_ENGLISH:
		return fallback
	var translated := str(story_catalog.get(section, {}).get(key, ""))
	return translated if translated.strip_edges() != "" else fallback

func _load_story_catalog() -> void:
	story_catalog.clear()
	story_catalog_error = ""
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(STORY_CATALOG_PATH))
	if not (parsed is Dictionary):
		story_catalog_error = "Invalid story language catalog: %s" % STORY_CATALOG_PATH
		push_warning(story_catalog_error)
		return
	for section in ["cues", "scene_titles", "speaker_labels", "ui"]:
		if not (parsed.get(section) is Dictionary):
			story_catalog_error = "Missing story language section: %s" % section
			push_warning(story_catalog_error)
			return
	story_catalog = parsed

func missing_keys(value: String, scope_id: String = "") -> Array[String]:
	var normalized_locale := normalize_locale(value)
	var locale_catalog: Dictionary = catalog.get(normalized_locale, {})
	var result: Array[String] = []
	for key in catalog_keys(scope_id):
		if not locale_catalog.has(key) or str(locale_catalog.get(key, "")).strip_edges() == "":
			result.append(key)
	return result

func reset_default(persist: bool = true) -> void:
	set_locale(_system_default_locale(), persist)

func snapshot() -> Dictionary:
	return {"locale": locale}

func apply_snapshot(value: Dictionary, persist: bool = false) -> void:
	set_locale(str(value.get("locale", LOCALE_KOREAN)), persist)

func save() -> void:
	_save_settings()

func _system_default_locale() -> String:
	return normalize_locale(OS.get_locale_language())

func _load_catalog() -> void:
	catalog.clear()
	catalog_error = ""
	var source := FileAccess.get_file_as_string(CATALOG_PATH)
	if source == "":
		catalog_error = "언어 카탈로그를 읽지 못했습니다: %s" % CATALOG_PATH
		push_warning(catalog_error)
		return
	var parsed = JSON.parse_string(source)
	if not (parsed is Dictionary):
		catalog_error = "언어 카탈로그 형식이 올바르지 않습니다: %s" % CATALOG_PATH
		push_warning(catalog_error)
		return
	var parsed_locales = parsed.get("locales", {})
	if not (parsed_locales is Dictionary):
		catalog_error = "언어 카탈로그에 locales가 없습니다: %s" % CATALOG_PATH
		push_warning(catalog_error)
		return
	for locale_id in SUPPORTED_LOCALES:
		var locale_catalog = parsed_locales.get(locale_id, {})
		if locale_catalog is Dictionary:
			catalog[locale_id] = locale_catalog.duplicate(true)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		locale = _system_default_locale()
		return
	locale = normalize_locale(str(config.get_value(
		SETTINGS_SECTION,
		"locale",
		_system_default_locale()
	)))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, "locale", locale)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("언어 설정을 저장하지 못했습니다: %s" % error_string(error))
