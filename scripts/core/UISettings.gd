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
const WINDOWED = "windowed"
const FULLSCREEN = "fullscreen"
const WINDOW_MODES = [WINDOWED, FULLSCREEN]
const DEFAULT_WINDOW_MODE = WINDOWED
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
const BACKGROUND_MAX_FPS := 30

var text_scale := DEFAULT_TEXT_SCALE
var layout_mode := DEFAULT_LAYOUT_MODE
var window_mode := DEFAULT_WINDOW_MODE
const DEFAULT_REMEMBER_COMBAT_SPEED := true
const COMBAT_CUTIN_MODES := ["off", "simple", "full"]
const DEFAULT_COMBAT_CUTIN_MODE := "simple"
var combat_cutin_mode := DEFAULT_COMBAT_CUTIN_MODE
const SKILL_CUTSCENE_POLICIES := ["once", "always", "off"]
const DEFAULT_SKILL_CUTSCENE_POLICY := "once"
var skill_cutscene_policy := DEFAULT_SKILL_CUTSCENE_POLICY
var skill_cutscene_seen: Dictionary = {}
var reduce_combat_effects := false
var remember_combat_speed := DEFAULT_REMEMBER_COMBAT_SPEED
var preferred_combat_speed := 1.0
var _windowed_size := Vector2i(1280, 720)
var tutorial_guidance_level := DEFAULT_TUTORIAL_GUIDANCE_LEVEL
var _last_effective_layout_mode := LAYOUT_STANDARD
var _foreground_max_fps := 0

func _ready() -> void:
	_load_settings()
	_apply_window_mode()
	_last_effective_layout_mode = effective_layout_mode()
	if not get_tree().root.size_changed.is_connected(_on_root_size_changed):
		get_tree().root.size_changed.connect(_on_root_size_changed)
	if DisplayServer.get_name() != "headless":
		_foreground_max_fps = Engine.max_fps
		get_tree().root.focus_entered.connect(_on_window_focus_entered)
		get_tree().root.focus_exited.connect(_on_window_focus_exited)
		if not get_tree().root.has_focus():
			_on_window_focus_exited()

func _on_window_focus_entered() -> void:
	Engine.max_fps = _foreground_max_fps

func _on_window_focus_exited() -> void:
	# Limit rendering only; physics, combat and dialogue keep their tick rates.
	Engine.max_fps = BACKGROUND_MAX_FPS if _foreground_max_fps == 0 else mini(BACKGROUND_MAX_FPS, _foreground_max_fps)

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

func supports_window_mode() -> bool:
	return OS.has_feature("pc") and not OS.has_feature("web") and DisplayServer.get_name() != "headless"

func set_window_mode(value: String, persist: bool = true) -> void:
	var next_value := value if value in WINDOW_MODES else DEFAULT_WINDOW_MODE
	if window_mode == next_value:
		return
	if supports_window_mode() and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		_windowed_size = DisplayServer.window_get_size()
	window_mode = next_value
	_apply_window_mode()
	if persist:
		_save_settings()

func _apply_window_mode() -> void:
	if not supports_window_mode():
		return
	if window_mode == FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var usable := DisplayServer.screen_get_usable_rect()
	var available := usable.size - Vector2i(64, 96)
	var scale := minf(1.0, minf(float(available.x) / _windowed_size.x, float(available.y) / _windowed_size.y))
	var size := Vector2i(Vector2(_windowed_size) * maxf(0.1, scale))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(usable.position + (usable.size - size) / 2)

func normalize_tutorial_guidance_level(value: String) -> String:
	return value if value in TUTORIAL_GUIDANCE_LEVELS else DEFAULT_TUTORIAL_GUIDANCE_LEVEL

func set_remember_combat_speed(value: bool, persist: bool = true) -> void:
	remember_combat_speed = value
	if persist:
		_save_settings()

func set_preferred_combat_speed(value: float, persist: bool = true) -> void:
	preferred_combat_speed = value if value in [1.0, 1.5, 2.0, 3.0] else 1.0
	if persist:
		_save_settings()

func reset_defaults(persist: bool = true) -> void:
	combat_cutin_mode = DEFAULT_COMBAT_CUTIN_MODE
	skill_cutscene_policy = DEFAULT_SKILL_CUTSCENE_POLICY
	reduce_combat_effects = false
	text_scale = DEFAULT_TEXT_SCALE
	layout_mode = DEFAULT_LAYOUT_MODE
	window_mode = DEFAULT_WINDOW_MODE
	remember_combat_speed = DEFAULT_REMEMBER_COMBAT_SPEED
	preferred_combat_speed = 1.0
	_apply_window_mode()
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
		"window_mode": window_mode,
		"remember_combat_speed": remember_combat_speed,
		"preferred_combat_speed": preferred_combat_speed,
		"combat_cutin_mode": combat_cutin_mode,
		"skill_cutscene_policy": skill_cutscene_policy,
		"skill_cutscene_seen": skill_cutscene_seen.duplicate(true),
		"reduce_combat_effects": reduce_combat_effects,
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
	set_window_mode(str(value.get("window_mode", DEFAULT_WINDOW_MODE)), false)
	set_remember_combat_speed(bool(value.get("remember_combat_speed", false)), false)
	set_preferred_combat_speed(float(value.get("preferred_combat_speed", 1.0)), false)
	set_combat_cutin_mode(str(value.get("combat_cutin_mode", DEFAULT_COMBAT_CUTIN_MODE)), false)
	set_skill_cutscene_policy(str(value.get("skill_cutscene_policy", DEFAULT_SKILL_CUTSCENE_POLICY)), false)
	skill_cutscene_seen = Dictionary(value.get("skill_cutscene_seen", {})).duplicate(true)
	set_reduce_combat_effects(bool(value.get("reduce_combat_effects", false)), false)
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

func set_combat_cutin_mode(value: String, persist: bool = true) -> void:
	combat_cutin_mode = value if value in COMBAT_CUTIN_MODES else DEFAULT_COMBAT_CUTIN_MODE
	if persist: _save_settings()

func set_reduce_combat_effects(value: bool, persist: bool = true) -> void:
	reduce_combat_effects = value
	if persist: _save_settings()

func set_skill_cutscene_policy(value: String, persist: bool = true) -> void:
	skill_cutscene_policy = value if value in SKILL_CUTSCENE_POLICIES else DEFAULT_SKILL_CUTSCENE_POLICY
	if persist: _save_settings()

func should_show_skill_cutscene(key: String) -> bool:
	return skill_cutscene_policy == "always" or (skill_cutscene_policy == "once" and not bool(skill_cutscene_seen.get(key, false)))

func mark_skill_cutscene_seen(key: String) -> bool:
	if key == "": return false
	skill_cutscene_seen[key] = true
	return _save_settings()

func reset_skill_cutscene_history(persist: bool = true) -> void:
	skill_cutscene_seen.clear()
	if persist: _save_settings()

func save() -> bool:
	return _save_settings()

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
	var requested_window := str(config.get_value(SETTINGS_SECTION, "window_mode", DEFAULT_WINDOW_MODE))
	window_mode = requested_window if requested_window in WINDOW_MODES else DEFAULT_WINDOW_MODE
	remember_combat_speed = bool(config.get_value(SETTINGS_SECTION, "remember_combat_speed", DEFAULT_REMEMBER_COMBAT_SPEED))
	set_preferred_combat_speed(float(config.get_value(SETTINGS_SECTION, "preferred_combat_speed", 1.0)), false)
	set_combat_cutin_mode(str(config.get_value(SETTINGS_SECTION, "combat_cutin_mode", DEFAULT_COMBAT_CUTIN_MODE)), false)
	var migrated_policy := "off" if combat_cutin_mode == "off" else DEFAULT_SKILL_CUTSCENE_POLICY
	set_skill_cutscene_policy(str(config.get_value(SETTINGS_SECTION, "skill_cutscene_policy", migrated_policy)), false)
	var stored_seen = config.get_value(SETTINGS_SECTION, "skill_cutscene_seen", {})
	skill_cutscene_seen = stored_seen.duplicate(true) if stored_seen is Dictionary else {}
	set_reduce_combat_effects(bool(config.get_value(SETTINGS_SECTION, "reduce_combat_effects", false)), false)
	tutorial_guidance_level = normalize_tutorial_guidance_level(str(config.get_value(
		SETTINGS_SECTION,
		"tutorial_guidance_level",
		DEFAULT_TUTORIAL_GUIDANCE_LEVEL
	)))

func _save_settings() -> bool:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, "text_scale", text_scale)
	config.set_value(SETTINGS_SECTION, "layout_mode", layout_mode)
	config.set_value(SETTINGS_SECTION, "window_mode", window_mode)
	config.set_value(SETTINGS_SECTION, "remember_combat_speed", remember_combat_speed)
	config.set_value(SETTINGS_SECTION, "preferred_combat_speed", preferred_combat_speed)
	config.set_value(SETTINGS_SECTION, "combat_cutin_mode", combat_cutin_mode)
	config.set_value(SETTINGS_SECTION, "skill_cutscene_policy", skill_cutscene_policy)
	config.set_value(SETTINGS_SECTION, "skill_cutscene_seen", skill_cutscene_seen)
	config.set_value(SETTINGS_SECTION, "reduce_combat_effects", reduce_combat_effects)
	config.set_value(SETTINGS_SECTION, "tutorial_guidance_level", tutorial_guidance_level)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("UI 설정을 저장하지 못했습니다: %s" % error_string(error))
	return error == OK

func _on_root_size_changed() -> void:
	if layout_mode == LAYOUT_AUTO:
		_emit_layout_mode_changed(false)

func _emit_layout_mode_changed(force: bool = true) -> void:
	var effective_mode := effective_layout_mode()
	var effective_changed := effective_mode != _last_effective_layout_mode
	_last_effective_layout_mode = effective_mode
	if force or effective_changed:
		layout_mode_changed.emit(layout_mode, effective_mode)
