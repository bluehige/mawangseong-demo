extends Node

signal text_scale_changed(value: float)
signal layout_mode_changed(requested_mode: String, effective_mode: String)
signal tutorial_guidance_level_changed(value: String)

const SETTINGS_PATH = "user://settings.cfg"
const SETTINGS_SECTION = "interface"
const DEFAULT_TEXT_SCALE = 1.0
const MIN_TEXT_SCALE = 0.9
const MAX_TEXT_SCALE = 1.15
const LAYOUT_AUTO = "auto"
const LAYOUT_STANDARD = "standard"
const LAYOUT_COMPACT = "compact"
const LAYOUT_MODES = [LAYOUT_AUTO, LAYOUT_STANDARD, LAYOUT_COMPACT]
const DEFAULT_LAYOUT_MODE = LAYOUT_AUTO
const TUTORIAL_GUIDANCE_FULL = "full"
const TUTORIAL_GUIDANCE_CORE = "core"
const TUTORIAL_GUIDANCE_OFF = "off"
const TUTORIAL_GUIDANCE_LEVELS = [
	TUTORIAL_GUIDANCE_FULL,
	TUTORIAL_GUIDANCE_CORE,
	TUTORIAL_GUIDANCE_OFF
]
const DEFAULT_TUTORIAL_GUIDANCE_LEVEL = TUTORIAL_GUIDANCE_FULL
const COMPACT_BREAKPOINT_WIDTH = 1440
const MOBILE_TOUCH_ARGUMENT = "--mobile-touch-ui"
const MOBILE_TEXT_SCALE = 1.35

var text_scale := DEFAULT_TEXT_SCALE
var layout_mode := DEFAULT_LAYOUT_MODE
var tutorial_guidance_level := DEFAULT_TUTORIAL_GUIDANCE_LEVEL
var _last_effective_layout_mode := LAYOUT_STANDARD

func _ready() -> void:
	_load_settings()
	_last_effective_layout_mode = effective_layout_mode()
	if not get_tree().root.size_changed.is_connected(_on_root_size_changed):
		get_tree().root.size_changed.connect(_on_root_size_changed)

func set_text_scale(value: float, persist: bool = true) -> void:
	var next_value := clampf(value, MIN_TEXT_SCALE, MAX_TEXT_SCALE)
	if is_equal_approx(text_scale, next_value):
		return
	text_scale = next_value
	if persist:
		_save_settings()
	text_scale_changed.emit(text_scale)

func set_layout_mode(value: String, persist: bool = true) -> void:
	var next_value := value if value in LAYOUT_MODES else DEFAULT_LAYOUT_MODE
	if layout_mode == next_value:
		return
	layout_mode = next_value
	if persist:
		_save_settings()
	_emit_layout_mode_changed()

func set_tutorial_guidance_level(value: String, persist: bool = true) -> void:
	var next_value := normalize_tutorial_guidance_level(value)
	if tutorial_guidance_level == next_value:
		return
	tutorial_guidance_level = next_value
	if persist:
		_save_settings()
	tutorial_guidance_level_changed.emit(tutorial_guidance_level)

func normalize_tutorial_guidance_level(value: String) -> String:
	return value if value in TUTORIAL_GUIDANCE_LEVELS else DEFAULT_TUTORIAL_GUIDANCE_LEVEL

func reset_defaults(persist: bool = true) -> void:
	text_scale = DEFAULT_TEXT_SCALE
	layout_mode = DEFAULT_LAYOUT_MODE
	tutorial_guidance_level = DEFAULT_TUTORIAL_GUIDANCE_LEVEL
	if persist:
		_save_settings()
	text_scale_changed.emit(text_scale)
	_emit_layout_mode_changed()
	tutorial_guidance_level_changed.emit(tutorial_guidance_level)

func snapshot() -> Dictionary:
	return {
		"text_scale": text_scale,
		"layout_mode": layout_mode,
		"tutorial_guidance_level": tutorial_guidance_level
	}

func apply_snapshot(value: Dictionary, persist: bool = false) -> void:
	var previous_text_scale := text_scale
	var previous_layout_mode := layout_mode
	var previous_tutorial_guidance_level := tutorial_guidance_level
	text_scale = clampf(
		float(value.get("text_scale", DEFAULT_TEXT_SCALE)),
		MIN_TEXT_SCALE,
		MAX_TEXT_SCALE
	)
	var requested_layout := str(value.get("layout_mode", DEFAULT_LAYOUT_MODE))
	layout_mode = requested_layout if requested_layout in LAYOUT_MODES else DEFAULT_LAYOUT_MODE
	tutorial_guidance_level = normalize_tutorial_guidance_level(str(value.get(
		"tutorial_guidance_level",
		DEFAULT_TUTORIAL_GUIDANCE_LEVEL
	)))
	if persist:
		_save_settings()
	if not is_equal_approx(previous_text_scale, text_scale):
		text_scale_changed.emit(text_scale)
	if previous_layout_mode != layout_mode:
		_emit_layout_mode_changed()
	if previous_tutorial_guidance_level != tutorial_guidance_level:
		tutorial_guidance_level_changed.emit(tutorial_guidance_level)

func save() -> void:
	_save_settings()

func effective_layout_mode(viewport_width: int = -1) -> String:
	if layout_mode != LAYOUT_AUTO:
		return layout_mode
	var width := viewport_width
	if width <= 0:
		width = DisplayServer.window_get_size().x
	if width <= 0:
		width = 1920
	return LAYOUT_COMPACT if width < COMPACT_BREAKPOINT_WIDTH else LAYOUT_STANDARD

func is_compact_layout(viewport_width: int = -1) -> bool:
	return effective_layout_mode(viewport_width) == LAYOUT_COMPACT

func scaled_font_size(value: int) -> int:
	var platform_scale := MOBILE_TEXT_SCALE if is_touch_ui() else 1.0
	return maxi(1, int(round(float(value) * text_scale * platform_scale)))

func is_touch_ui() -> bool:
	if OS.has_feature("mobile_touch_ui"):
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	return OS.get_cmdline_args().has(MOBILE_TOUCH_ARGUMENT) or OS.get_cmdline_user_args().has(MOBILE_TOUCH_ARGUMENT)

func touch_font_size(value: int, minimum: int = 24) -> int:
	return maxi(value, minimum) if is_touch_ui() else value

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	text_scale = clampf(
		float(config.get_value(SETTINGS_SECTION, "text_scale", DEFAULT_TEXT_SCALE)),
		MIN_TEXT_SCALE,
		MAX_TEXT_SCALE
	)
	var requested_layout := str(config.get_value(SETTINGS_SECTION, "layout_mode", DEFAULT_LAYOUT_MODE))
	layout_mode = requested_layout if requested_layout in LAYOUT_MODES else DEFAULT_LAYOUT_MODE
	tutorial_guidance_level = normalize_tutorial_guidance_level(str(config.get_value(
		SETTINGS_SECTION,
		"tutorial_guidance_level",
		DEFAULT_TUTORIAL_GUIDANCE_LEVEL
	)))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, "text_scale", text_scale)
	config.set_value(SETTINGS_SECTION, "layout_mode", layout_mode)
	config.set_value(SETTINGS_SECTION, "tutorial_guidance_level", tutorial_guidance_level)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("UI 설정을 저장하지 못했습니다: %s" % error_string(error))

func _on_root_size_changed() -> void:
	if layout_mode == LAYOUT_AUTO:
		_emit_layout_mode_changed(false)

func _emit_layout_mode_changed(force: bool = true) -> void:
	var effective_mode := effective_layout_mode()
	var effective_changed := effective_mode != _last_effective_layout_mode
	_last_effective_layout_mode = effective_mode
	if force or effective_changed:
		layout_mode_changed.emit(layout_mode, effective_mode)
