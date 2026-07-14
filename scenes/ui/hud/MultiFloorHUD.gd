extends Control
class_name MultiFloorHUD

signal floor_selected(floor_id: String)
signal auto_camera_changed(enabled: bool)

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const CouncilChronicleScript = preload("res://scripts/systems/chronicle/CouncilChronicleService.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
const ALERT_WINDOW_SECONDS := 6.0
const INPUT_BUFFER_SECONDS := 0.2

var upper_floor: Dictionary = {}
var layouts: Dictionary = {}
var modules: Dictionary = {}
var runtime: Dictionary = {}
var accessibility: Dictionary = CouncilChronicleScript.default_accessibility()
var visible_floor := "1F"
var alert_remaining := 0.0
var input_buffer := 0.0
var content_root: Control
var upper_overlay: Panel
var alert_panel: Panel
var alert_label: Label
var floor_1_button: Button
var floor_2_button: Button
var auto_camera_check: CheckBox
var alert_sound: AudioStreamPlayer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit)
	_build()
	set_process(true)
	call_deferred("_fit")


func _exit_tree() -> void:
	if alert_sound != null:
		alert_sound.stop()
		alert_sound.stream = null


func setup(upper_value: Dictionary, layouts_value: Dictionary, modules_value: Dictionary, accessibility_value: Dictionary = {}) -> void:
	upper_floor = upper_value.duplicate(true)
	layouts = layouts_value.duplicate(true)
	modules = modules_value.duplicate(true)
	accessibility = CouncilChronicleScript.normalize_accessibility(accessibility_value)
	runtime = upper_floor.get("graph_runtime", {}).duplicate(true)
	visible_floor = str(runtime.get("visible_floor", "1F"))
	if visible_floor not in ["1F", "2F"]:
		visible_floor = "1F"
	if is_node_ready():
		_build()
		_refresh()
		var hidden_count := hidden_enemy_count()
		if hidden_count > 0:
			push_hidden_floor_alert("2F" if visible_floor == "1F" else "1F", hidden_count, false)


func hud_rects_for_viewport(viewport_size: Vector2) -> Dictionary:
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * factor) * 0.5
	return {
		"floor_tabs": Rect2(offset + Vector2(24, 22) * factor, Vector2(320, 64) * factor),
		"hidden_alert": Rect2(offset + Vector2(1460, 104) * factor, Vector2(420, 110) * factor),
		"auto_camera": Rect2(offset + Vector2(1480, 24) * factor, Vector2(400, 60) * factor)
	}


func push_hidden_floor_alert(floor_id: String, enemy_count: int, objective_under_attack: bool) -> void:
	alert_remaining = ALERT_WINDOW_SECONDS
	if alert_label != null:
		alert_label.text = "%s  %s · 적 %d명" % ["⚠ 목표 공격" if objective_under_attack else "⚠ 숨은 층 침입", floor_id, maxi(0, enemy_count)] if bool(accessibility.get("hidden_floor_summary", true)) else "⚠ %s 위험" % floor_id
	if alert_panel != null:
		alert_panel.visible = true
	if alert_sound != null and float(accessibility.get("floor_alert_volume", 0.8)) > 0.0:
		alert_sound.play()


func hidden_enemy_count() -> int:
	var hidden_floor := "2F" if visible_floor == "1F" else "1F"
	var count := 0
	for entity in runtime.get("entities", {}).values():
		if entity is Dictionary and bool(entity.get("alive", false)) and str(entity.get("faction", "")) == "enemy" and str(entity.get("floor_id", "")) == hidden_floor:
			count += 1
	return count


func select_floor(floor_id: String) -> bool:
	if floor_id not in ["1F", "2F"] or input_buffer > 0.0 or floor_id == visible_floor:
		return false
	visible_floor = floor_id
	input_buffer = INPUT_BUFFER_SECONDS
	runtime["visible_floor"] = visible_floor
	_refresh()
	floor_selected.emit(visible_floor)
	return true


func _process(delta: float) -> void:
	input_buffer = maxf(0.0, input_buffer - delta)
	if alert_remaining > 0.0:
		alert_remaining = maxf(0.0, alert_remaining - delta)
		if alert_remaining <= 0.0 and alert_panel != null:
			alert_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == _keycode(str(accessibility.get("floor_one_key", "Q"))):
			select_floor("1F")
		elif event.keycode == _keycode(str(accessibility.get("floor_two_key", "E"))):
			select_floor("2F")


func _build() -> void:
	if content_root != null and is_instance_valid(content_root):
		content_root.queue_free()
	content_root = Control.new()
	content_root.name = "DesignCanvas"
	content_root.size = DESIGN_SIZE
	content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content_root)
	upper_overlay = Panel.new()
	upper_overlay.name = "UpperFloorSchematic"
	upper_overlay.position = Vector2(0, 0)
	upper_overlay.size = DESIGN_SIZE
	upper_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upper_overlay.add_theme_stylebox_override("panel", _style(Color("#09070df5"), Color("#31263d"), 0, 0))
	content_root.add_child(upper_overlay)
	_build_upper_schematic()
	var tab_panel := Panel.new()
	tab_panel.position = Vector2(24, 22)
	tab_panel.size = Vector2(320, 64)
	tab_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab_panel.add_theme_stylebox_override("panel", _style(Color("#100c17f4"), Color("#7c6350"), 2, 10))
	tab_panel.z_index = 40
	content_root.add_child(tab_panel)
	floor_1_button = _button(tab_panel, "1F  %s" % str(accessibility.get("floor_one_key", "Q")), Rect2(8, 8, 148, 48), Callable(self, "select_floor").bind("1F"))
	floor_2_button = _button(tab_panel, "2F  %s" % str(accessibility.get("floor_two_key", "E")), Rect2(164, 8, 148, 48), Callable(self, "select_floor").bind("2F"))
	var floor_icon = load("res://assets/ui/icons/update4/floor_switch.png")
	floor_1_button.icon = floor_icon
	floor_2_button.icon = floor_icon
	floor_1_button.expand_icon = true
	floor_2_button.expand_icon = true
	var option_panel := Panel.new()
	option_panel.position = Vector2(1480, 24)
	option_panel.size = Vector2(400, 60)
	option_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	option_panel.add_theme_stylebox_override("panel", _style(Color("#100c17f4"), Color("#5e5068"), 2, 10))
	option_panel.z_index = 40
	content_root.add_child(option_panel)
	auto_camera_check = CheckBox.new()
	auto_camera_check.position = Vector2(18, 8)
	auto_camera_check.size = Vector2(364, 44)
	auto_camera_check.mouse_filter = Control.MOUSE_FILTER_STOP
	auto_camera_check.text = "직접 조종 계단 이동 시 자동 전환"
	auto_camera_check.button_pressed = bool(upper_floor.get("auto_camera_switch", true))
	auto_camera_check.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BODY))
	auto_camera_check.add_theme_font_size_override("font_size", 15)
	auto_camera_check.toggled.connect(func(enabled: bool): auto_camera_changed.emit(enabled))
	option_panel.add_child(auto_camera_check)
	alert_panel = Panel.new()
	alert_panel.name = "HiddenFloorAlert"
	alert_panel.position = Vector2(1460, 104)
	alert_panel.size = Vector2(420, 110)
	alert_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_panel.add_theme_stylebox_override("panel", _style(Color("#140407fb") if bool(accessibility.get("high_contrast_icons", false)) else Color("#38141bea"), Color("#fff05a") if bool(accessibility.get("high_contrast_icons", false)) else Color("#e18178"), 4 if bool(accessibility.get("high_contrast_icons", false)) else 3, 12))
	alert_panel.z_index = 50
	content_root.add_child(alert_panel)
	var alert_icon := TextureRect.new()
	alert_icon.name = "SealVaultAlarmIcon"
	alert_icon.position = Vector2(12, 15)
	alert_icon.size = Vector2(80, 80)
	alert_icon.texture = load("res://assets/props/update4/upper/seal_vault_alarm.png")
	alert_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	alert_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	alert_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_panel.add_child(alert_icon)
	alert_label = _label(alert_panel, "⚠ 숨은 층 침입", Rect2(96, 12, 306, 86), 20, Color("#ffd1c8"), HORIZONTAL_ALIGNMENT_CENTER)
	alert_sound = null
	if DisplayServer.get_name() != "headless":
		alert_sound = AudioStreamPlayer.new()
		alert_sound.name = "FloorAlertSound"
		alert_sound.stream = load("res://assets/audio/sfx/update4/contract_monsters/sfx_popo_alarm.wav")
		var alert_volume := float(accessibility.get("floor_alert_volume", 0.8))
		alert_sound.volume_db = linear_to_db(alert_volume) if alert_volume > 0.0 else -80.0
		content_root.add_child(alert_sound)
	alert_panel.visible = false
	_refresh()
	_fit()


func _build_upper_schematic() -> void:
	var layout_id := str(upper_floor.get("layout_id", "upper_compact_guard"))
	var layout: Dictionary = layouts.get(layout_id, {})
	var backdrop := TextureRect.new()
	backdrop.name = "UpperFloorBackdrop"
	backdrop.size = DESIGN_SIZE
	var backdrop_path := str(layout.get("preview", ""))
	if not backdrop_path.is_empty():
		backdrop.texture = load(backdrop_path)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.modulate = Color(0.72, 0.62, 0.82, 0.34)
	backdrop.z_index = -1
	upper_overlay.add_child(backdrop)
	_label(upper_overlay, "2F · %s" % str(layout.get("display_name", layout_id)), Rect2(500, 90, 920, 64), 36, Color("#f5dfbb"), HORIZONTAL_ALIGNMENT_CENTER)
	_label(upper_overlay, "왕관실과 인장 금고는 보조 목표입니다. 파괴·절도가 왕좌 패배로 이어지지는 않습니다.", Rect2(420, 154, 1080, 40), 16, Color("#bfb1c7"), HORIZONTAL_ALIGNMENT_CENTER)
	for placement in layout.get("placed_modules", []):
		var origin: Array = placement.get("grid_origin", [0, 0])
		var module_id := str(placement.get("module_id", ""))
		var card := Panel.new()
		card.name = str(placement.get("instance_id", module_id))
		card.position = Vector2(310 + int(origin[0]) * 360, 270 + int(origin[1]) * 230)
		card.size = Vector2(290, 180)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var accent := Color("#d6ad62") if module_id == "crown_sanctum" else (Color("#a881ce") if module_id == "seal_vault" else Color("#7197b9"))
		card.add_theme_stylebox_override("panel", _style(accent.darkened(0.68), accent, 3, 12))
		card.z_index = 2
		upper_overlay.add_child(card)
		var module_art := TextureRect.new()
		module_art.name = "ModuleArt_%s" % module_id
		module_art.position = Vector2(44, 48)
		module_art.size = Vector2(202, 112)
		var module_art_path := _module_art_path(module_id)
		if not module_art_path.is_empty():
			module_art.texture = load(module_art_path)
		module_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		module_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		module_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		module_art.modulate = Color(1, 1, 1, 0.56)
		module_art.z_index = 0
		card.add_child(module_art)
		_label(card, str(modules.get(module_id, {}).get("display_name", module_id)), Rect2(18, 20, 254, 44), 23, Color("#fff0d4"), HORIZONTAL_ALIGNMENT_CENTER)
		_label(card, _module_status(module_id), Rect2(18, 78, 254, 70), 15, Color("#c8bccc"), HORIZONTAL_ALIGNMENT_CENTER)


func _module_status(module_id: String) -> String:
	match module_id:
		"crown_sanctum": return "HP %d · 왕관 기능 보호" % int(upper_floor.get("objective_hp", {}).get("crown_sanctum", 0))
		"seal_vault": return "3초 예고 · 4초 절도 채널"
		"upper_facility_slot": return "같은 층 시설 효과"
		_: return "단일 계단 endpoint"


func _module_art_path(module_id: String) -> String:
	var art_states: Dictionary = modules.get(module_id, {}).get("art_states", {})
	match module_id:
		"crown_sanctum":
			if not upper_floor.get("objective_hp", {}).has("crown_sanctum"):
				return str(art_states.get("empty", ""))
			if bool(upper_floor.get("crown_suppressed", false)) or int(upper_floor.get("objective_hp", {}).get("crown_sanctum", 0)) <= 0:
				return str(art_states.get("damaged", ""))
			return str(art_states.get("active", ""))
		"seal_vault":
			if int(upper_floor.get("seal_theft_count", 0)) > 0:
				return str(art_states.get("stolen", ""))
			if bool(runtime.get("seal_alert_active", false)):
				return str(art_states.get("alarm", ""))
			return str(art_states.get("normal", ""))
		_:
			return str(art_states.get("normal", ""))


func _keycode(key_name: String) -> Key:
	match key_name.to_upper():
		"A": return KEY_A
		"D": return KEY_D
		"1": return KEY_1
		"2": return KEY_2
		"E": return KEY_E
		_: return KEY_Q


func _refresh() -> void:
	if upper_overlay != null:
		upper_overlay.visible = visible_floor == "2F"
	if floor_1_button != null:
		floor_1_button.disabled = visible_floor == "1F"
	if floor_2_button != null:
		floor_2_button.disabled = visible_floor == "2F"


func _fit() -> void:
	if content_root == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	content_root.scale = Vector2.ONE * factor
	content_root.position = (size - DESIGN_SIZE * factor) * 0.5


func _button(parent: Control, value: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.text = value
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _label(parent: Control, value: String, rect: Rect2, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 3
	parent.add_child(label)
	return label


func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
