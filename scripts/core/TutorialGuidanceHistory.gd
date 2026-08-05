extends Node

signal history_changed

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "tutorial_guidance_history"
const NAME_ENTRY_GUIDE_ID := "HELP_NAME_ENTRY_GUIDE"

var dismissed_help_ids: Dictionary = {}


func _ready() -> void:
	_load_settings()


func has_dismissed(help_id: String) -> bool:
	return help_id != "" and dismissed_help_ids.has(help_id)


func dismiss_help(help_id: String, persist: bool = true) -> void:
	if help_id == "" or dismissed_help_ids.has(help_id):
		return
	dismissed_help_ids[help_id] = true
	if persist:
		_save_settings()
	history_changed.emit()


func reset(persist: bool = true) -> void:
	if dismissed_help_ids.is_empty():
		return
	dismissed_help_ids.clear()
	if persist:
		_save_settings()
	history_changed.emit()


func dismissed_count() -> int:
	return dismissed_help_ids.size()


func snapshot() -> Dictionary:
	return {"dismissed_help_ids": _sorted_ids()}


func apply_snapshot(value: Dictionary, persist: bool = false) -> void:
	var next_ids := _normalized_ids(value.get("dismissed_help_ids", []))
	if dismissed_help_ids == next_ids:
		return
	dismissed_help_ids = next_ids
	if persist:
		_save_settings()
	history_changed.emit()


func save() -> void:
	_save_settings()


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	dismissed_help_ids = _normalized_ids(config.get_value(
		SETTINGS_SECTION,
		"dismissed_help_ids",
		[]
	))


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(
		SETTINGS_SECTION,
		"dismissed_help_ids",
		PackedStringArray(_sorted_ids())
	)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("튜토리얼 안내 기록을 저장하지 못했습니다: %s" % error_string(error))


func _normalized_ids(values) -> Dictionary:
	var result: Dictionary = {}
	if not (values is Array or values is PackedStringArray):
		return result
	for value in values:
		var help_id := str(value).strip_edges()
		if help_id != "":
			result[help_id] = true
	return result


func _sorted_ids() -> Array[String]:
	var result: Array[String] = []
	for help_id in dismissed_help_ids:
		result.append(str(help_id))
	result.sort()
	return result
