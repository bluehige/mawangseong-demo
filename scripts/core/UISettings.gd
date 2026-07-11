extends Node

signal text_scale_changed(value: float)

const SETTINGS_PATH = "user://settings.cfg"
const SETTINGS_SECTION = "interface"
const DEFAULT_TEXT_SCALE = 1.0
const MIN_TEXT_SCALE = 0.9
const MAX_TEXT_SCALE = 1.15

var text_scale := DEFAULT_TEXT_SCALE

func _ready() -> void:
	_load_settings()

func set_text_scale(value: float, persist: bool = true) -> void:
	var next_value = clampf(value, MIN_TEXT_SCALE, MAX_TEXT_SCALE)
	if is_equal_approx(text_scale, next_value):
		return
	text_scale = next_value
	if persist:
		_save_settings()
	text_scale_changed.emit(text_scale)

func reset_defaults() -> void:
	set_text_scale(DEFAULT_TEXT_SCALE)

func scaled_font_size(value: int) -> int:
	return maxi(1, int(round(float(value) * text_scale)))

func _load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	text_scale = clampf(
		float(config.get_value(SETTINGS_SECTION, "text_scale", DEFAULT_TEXT_SCALE)),
		MIN_TEXT_SCALE,
		MAX_TEXT_SCALE
	)

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, "text_scale", text_scale)
	var error = config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("UI 설정을 저장하지 못했습니다: %s" % error_string(error))
