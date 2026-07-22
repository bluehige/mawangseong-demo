class_name V20PlacementRoomButton
extends Button

const UIFontScript = preload("res://scripts/ui/UIFont.gd")

signal monster_dropped(monster_id: String, room_id: String)
signal facility_dropped(facility_id: String, room_id: String)

var room_id := ""
var active_route := false
var valid_target := false
var context_selected := false
var accent_color := Color("#c18b3a")
var _drop_hover := false
var _content_label: Label


func setup(room_id_value: String, display_name: String) -> void:
	room_id = room_id_value
	text = ""
	_content_label = Label.new()
	_content_label.name = "RoomContent"
	_content_label.text = display_name
	_content_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_label.offset_left = 12
	_content_label.offset_right = -10
	_content_label.offset_top = 5
	_content_label.offset_bottom = -5
	_content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_content_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_content_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_label.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	_content_label.add_theme_font_size_override("font_size", 10)
	_content_label.add_theme_color_override("font_color", Color("#f3eadc"))
	add_child(_content_label)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func setup_visual(route_active: bool, target_valid: bool, selected: bool, accent: Color) -> void:
	active_route = route_active
	valid_target = target_valid
	context_selected = selected
	accent_color = accent
	if _content_label != null:
		_content_label.add_theme_color_override("font_color", Color("#ffe4a0") if route_active or target_valid or selected else Color("#f3eadc"))
	queue_redraw()


func _draw() -> void:
	var fill := Color("#18131fe8")
	var border := Color("#51475b")
	if active_route:
		fill = Color("#170e14ed")
		border = Color("#a44742")
	if valid_target:
		fill = Color("#1d2d28f2")
		border = accent_color
	if context_selected or _drop_hover or is_hovered():
		fill = Color("#33263ff5")
		border = Color("#ffe3a0") if context_selected else accent_color
	var plate := StyleBoxFlat.new()
	plate.bg_color = fill
	plate.border_color = border
	plate.set_border_width_all(3 if context_selected or _drop_hover else 1)
	plate.set_corner_radius_all(8)
	plate.shadow_color = Color("#00000088")
	plate.shadow_size = 5
	draw_style_box(plate, Rect2(Vector2.ZERO, size))
	draw_rect(Rect2(0, 9, 4, size.y - 18), border, true)
	if valid_target:
		draw_style_box(plate, Rect2(4, 4, size.x - 8, size.y - 8))


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if not (data is Dictionary):
		_set_drop_hover(false)
		return false
	var kind := str(data.get("kind", ""))
	var accepted := (kind == "v20_monster" and str(data.get("monster_id", "")) != "") or (kind == "v20_facility" and str(data.get("facility_id", "")) != "")
	_set_drop_hover(accepted)
	return accepted


func _drop_data(_at_position: Vector2, data) -> void:
	if not _can_drop_data(Vector2.ZERO, data):
		return
	_set_drop_hover(false)
	if str(data.get("kind", "")) == "v20_facility":
		facility_dropped.emit(str(data.get("facility_id", "")), room_id)
	else:
		monster_dropped.emit(str(data.get("monster_id", "")), room_id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_set_drop_hover(false)


func _set_drop_hover(value: bool) -> void:
	if _drop_hover == value:
		return
	_drop_hover = value
	queue_redraw()
