class_name V20PlacementRoomButton
extends Button

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const UITheme = preload("res://scripts/v20/ui/V20UITheme.gd")

signal monster_dropped(monster_id: String, room_id: String)
signal facility_dropped(facility_id: String, room_id: String)
signal drop_rejected(room_id: String, reason: String)

var room_id := ""
var active_route := false
var valid_target := false
var context_selected := false
var target_mode_active := false
var invalid_reason := ""
var accent_color := Color("#c18b3a")
var _drop_hover := false
var _content_label: Label
var _monster_token_frames: Array[Panel] = []
var _monster_capacity := 0


func setup(room_id_value: String, display_name: String, monster_tokens: Array = [], monster_capacity: int = 0) -> void:
	room_id = room_id_value
	_monster_capacity = maxi(monster_capacity, monster_tokens.size())
	text = ""
	_content_label = Label.new()
	_content_label.name = "RoomContent"
	_content_label.text = display_name
	_content_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_label.offset_left = 12
	_content_label.offset_right = -112
	_content_label.offset_top = 7
	_content_label.offset_bottom = -7
	_content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_content_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_content_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_content_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_content_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_label.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	_content_label.add_theme_font_size_override("font_size", UITheme.FONT_SUPPORT)
	_content_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT)
	add_child(_content_label)
	_build_monster_tokens(monster_tokens)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func setup_visual(route_active: bool, target_valid: bool, selected: bool, accent: Color, target_active: bool = false, rejection_reason: String = "") -> void:
	active_route = route_active
	valid_target = target_valid
	context_selected = selected
	accent_color = accent
	target_mode_active = target_active
	invalid_reason = rejection_reason
	if _content_label != null:
		var content_color := UITheme.COLOR_GOLD_BRIGHT if route_active or target_valid or selected else UITheme.COLOR_TEXT
		if target_mode_active and not valid_target:
			content_color = Color("#716978")
		_content_label.add_theme_color_override("font_color", content_color)
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
	if target_mode_active and not valid_target:
		fill = Color("#09080dbd")
		border = Color("#302b35")
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
	var has_payload := (kind == "v20_monster" and str(data.get("monster_id", "")) != "") or (kind == "v20_facility" and str(data.get("facility_id", "")) != "")
	var accepted := has_payload and valid_target
	if has_payload and target_mode_active and not accepted:
		drop_rejected.emit(room_id, invalid_reason if invalid_reason != "" else "이 슬롯에는 놓을 수 없습니다.")
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
	if what == NOTIFICATION_RESIZED:
		_layout_monster_tokens()
	if what == NOTIFICATION_DRAG_END:
		_set_drop_hover(false)


func _set_drop_hover(value: bool) -> void:
	if _drop_hover == value:
		return
	_drop_hover = value
	queue_redraw()


func _build_monster_tokens(monster_tokens: Array) -> void:
	_monster_token_frames.clear()
	for slot_index in range(_monster_capacity):
		var token: Dictionary = monster_tokens[slot_index] if slot_index < monster_tokens.size() else {}
		var monster_id := str(token.get("monster_id", ""))
		var texture = token.get("texture")
		var frame := Panel.new()
		frame.name = "MonsterTokenFrame_%s" % (monster_id if monster_id != "" else "empty_%d" % (slot_index + 1))
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color("#21182bea") if monster_id != "" else Color("#0b0910d9")
		frame_style.border_color = Color("#c7a4ff") if monster_id != "" else Color("#5a5064")
		frame_style.set_border_width_all(1)
		frame_style.set_corner_radius_all(5)
		frame.add_theme_stylebox_override("panel", frame_style)
		if monster_id != "" and texture is Texture2D:
			var portrait := TextureRect.new()
			portrait.name = "MonsterToken_%s" % monster_id
			portrait.texture = texture
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.add_child(portrait)
			var monster_name := Label.new()
			monster_name.name = "MonsterName_%s" % monster_id
			monster_name.text = str(token.get("name", monster_id))
			monster_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			monster_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			monster_name.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
			monster_name.add_theme_font_size_override("font_size", 10)
			monster_name.add_theme_color_override("font_color", Color("#f4eaff"))
			monster_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.add_child(monster_name)
		else:
			var empty_label := Label.new()
			empty_label.name = "MonsterSlotEmpty_%d" % (slot_index + 1)
			empty_label.text = "＋ 빈 슬롯"
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_label.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BODY))
			empty_label.add_theme_font_size_override("font_size", 10)
			empty_label.add_theme_color_override("font_color", Color("#a69cad"))
			empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.add_child(empty_label)
		add_child(frame)
		_monster_token_frames.append(frame)
	_layout_monster_tokens()


func _layout_monster_tokens() -> void:
	if _monster_token_frames.is_empty():
		return
	var slot_count := _monster_token_frames.size()
	var gap := 5.0 if slot_count <= 2 else 3.0
	var token_width := clampf(size.x * 0.42, 92.0, 108.0)
	var start_x := size.x - token_width - 7.0
	var available_height := size.y - 14.0
	var token_height := (available_height - gap * maxf(0.0, slot_count - 1.0)) / float(slot_count)
	if _content_label != null:
		_content_label.offset_right = -(token_width + 14.0)
	for index in range(_monster_token_frames.size()):
		var frame := _monster_token_frames[index]
		frame.position = Vector2(start_x, 7.0 + index * (token_height + gap))
		frame.size = Vector2(token_width, token_height)
		var portrait: TextureRect = frame.get_node_or_null("MonsterToken_%s" % str(frame.name).trim_prefix("MonsterTokenFrame_"))
		if portrait != null:
			var portrait_size := minf(token_height - 4.0, clampf(token_width * 0.4, 24.0, 42.0))
			portrait.position = Vector2(2, 2)
			portrait.size = Vector2(portrait_size, portrait_size)
			var monster_name: Label = frame.get_node_or_null("MonsterName_%s" % str(frame.name).trim_prefix("MonsterTokenFrame_"))
			if monster_name != null:
				monster_name.position = Vector2(portrait_size + 6.0, 1.0)
				monster_name.size = Vector2(token_width - portrait_size - 9.0, token_height - 2.0)
				monster_name.add_theme_font_size_override("font_size", 10 if slot_count <= 2 else 8)
		else:
			var empty_label: Label = frame.get_child(0) if frame.get_child_count() > 0 else null
			if empty_label != null:
				empty_label.position = Vector2.ZERO
				empty_label.size = frame.size
				empty_label.add_theme_font_size_override("font_size", 10 if slot_count <= 2 else 8)
