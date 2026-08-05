extends Node

signal locale_changed(locale: String)

const SETTINGS_PATH = "user://settings.cfg"
const SETTINGS_SECTION = "interface"
const CATALOG_PATH = "res://data/localization/v122_stage10_ui.json"
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

func _ready() -> void:
	_load_catalog()
	_load_settings()
	TranslationServer.set_locale(locale)

func set_locale(value: String, persist: bool = true) -> void:
	var next_locale := normalize_locale(value)
	if locale == next_locale:
		return
	locale = next_locale
	TranslationServer.set_locale(locale)
	if persist:
		_save_settings()
	locale_changed.emit(locale)

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
