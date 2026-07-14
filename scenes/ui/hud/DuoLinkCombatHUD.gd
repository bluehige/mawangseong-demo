extends Control
class_name DuoLinkCombatHUD

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
const MAX_ROWS := 2
const ROW_RECTS := [Rect2(18, 12, 524, 62), Rect2(18, 84, 524, 62)]

var state_provider: Callable
var activate_callback: Callable
var content_root: Control
var frame: Panel
var row_panels: Array[Panel] = []
var name_labels: Array[Label] = []
var state_labels: Array[Label] = []
var charge_labels: Array[Label] = []
var fills: Array[ColorRect] = []
var use_buttons: Array[Button] = []
# Phase 9 테스트와 외부 참조의 호환을 위한 1번 버튼 별칭입니다.
var use_button: Button
var row_link_ids: Array[String] = ["", ""]
var last_signature := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_fit_design_canvas)
	_build()
	call_deferred("_fit_design_canvas")


func setup(provider: Callable, activate: Callable) -> void:
	state_provider = provider
	activate_callback = activate
	_refresh_state()


func _process(_delta: float) -> void:
	_refresh_state()


func _build() -> void:
	content_root = Control.new()
	content_root.size = DESIGN_SIZE
	content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content_root)
	frame = Panel.new()
	frame.position = Vector2(1170, 70)
	frame.size = Vector2(560, 158)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _style(Color("#0b0810ee"), Color("#79bea3")))
	content_root.add_child(frame)
	for index in range(MAX_ROWS):
		_build_row(index)
	use_button = use_buttons[0]
	_fit_design_canvas()


func _build_row(index: int) -> void:
	var row := Panel.new()
	row.position = ROW_RECTS[index].position
	row.size = ROW_RECTS[index].size
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_stylebox_override("panel", _style(Color("#15111ae6"), Color("#4f7568")))
	frame.add_child(row)
	row_panels.append(row)
	var name_label := _label(row, Rect2(12, 5, 255, 22), 14, Color("#e8fff4"), UIFontScript.ROLE_EMPHASIS)
	name_labels.append(name_label)
	var charge_label := _label(row, Rect2(273, 5, 92, 22), 13, Color("#e8fff4"), UIFontScript.ROLE_EMPHASIS)
	charge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	charge_labels.append(charge_label)
	var state_label := _label(row, Rect2(12, 36, 353, 20), 12, Color("#cfddd6"), UIFontScript.ROLE_BODY)
	state_labels.append(state_label)
	var track := ColorRect.new()
	track.position = Vector2(12, 29)
	track.size = Vector2(353, 5)
	track.color = Color("#08060d")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(track)
	var fill := ColorRect.new()
	fill.size = Vector2.ZERO
	fill.color = Color("#79bea3")
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	fills.append(fill)
	var button := Button.new()
	button.position = Vector2(379, 7)
	button.size = Vector2(132, 48)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.text = "%s 발동" % ("J" if index == 0 else "K")
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	button.pressed.connect(_activate_row.bind(index))
	row.add_child(button)
	use_buttons.append(button)


func _refresh_state() -> void:
	if not state_provider.is_valid():
		visible = false
		return
	var value = state_provider.call()
	if not (value is Dictionary):
		visible = false
		return
	var equipped: Array = value.get("equipped", [])
	visible = not equipped.is_empty()
	if not visible:
		return
	var states: Dictionary = value.get("states", {})
	var signature := JSON.stringify([equipped, states])
	if signature == last_signature:
		return
	last_signature = signature
	for index in range(MAX_ROWS):
		var has_link := index < equipped.size()
		row_panels[index].visible = has_link
		row_link_ids[index] = str(equipped[index]) if has_link else ""
		if not has_link:
			continue
		_refresh_row(index, value, states.get(row_link_ids[index], {}))


func _refresh_row(index: int, value: Dictionary, state: Dictionary) -> void:
	var link_id := row_link_ids[index]
	var charge := clampi(int(state.get("charge", 0)), 0, 100)
	name_labels[index].text = str(value.get("names", {}).get(link_id, link_id))
	charge_labels[index].text = "%d / 100" % charge
	fills[index].size = Vector2(353.0 * charge / 100.0, 5)
	var active := bool(state.get("active", false))
	var used := bool(state.get("used_this_battle", false))
	use_buttons[index].disabled = not active or used or charge < 100
	if not active:
		state_labels[index].text = "비활성 · %s" % str(state.get("inactive_reason", "멤버 미출전"))
	elif used:
		state_labels[index].text = "이번 전투 사용 완료"
	elif charge >= 100:
		state_labels[index].text = "준비 완료 · %s 또는 버튼으로 발동" % ("J" if index == 0 else "K")
	else:
		state_labels[index].text = "전투 행동으로 개별 충전"


func _activate_row(index: int) -> void:
	if index < 0 or index >= row_link_ids.size() or row_link_ids[index] == "":
		return
	if activate_callback.is_valid():
		activate_callback.call(row_link_ids[index])


func row_rects_for_viewport(viewport_size: Vector2) -> Array[Rect2]:
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * factor) * 0.5
	var result: Array[Rect2] = []
	for rect in ROW_RECTS:
		result.append(Rect2(offset + (frame.position + rect.position) * factor, rect.size * factor))
	return result


func _label(parent: Control, rect: Rect2, size_value: int, color: Color, role: String) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_override("font", UIFontScript.font_for_role(role))
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _style(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	return style


func _fit_design_canvas() -> void:
	if content_root == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	content_root.scale = Vector2.ONE * factor
	content_root.position = (size - DESIGN_SIZE * factor) * 0.5
