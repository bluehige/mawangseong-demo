class_name V20MonsterDragButton
extends Button

const UIFontScript = preload("res://scripts/ui/UIFont.gd")

signal drag_started(kind: String, item_id: String)
signal drag_finished

var payload_kind := "v20_monster"
var payload_id := ""
var portrait_texture: Texture2D
var card_name := ""
var card_role := ""
var card_location := ""

var _portrait: TextureRect
var _name_label: Label
var _role_label: Label
var _location_label: Label
var _drag_label: Label


func setup(monster_id_value: String, display_name: String, role_name: String = "수비대", location_name: String = "미배치", portrait: Texture2D = null) -> void:
	payload_kind = "v20_monster"
	payload_id = monster_id_value
	portrait_texture = portrait
	card_name = display_name
	card_role = role_name
	card_location = location_name
	text = ""
	tooltip_text = "%s · 초상을 끌어 구역에 배치" % display_name
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_build_monster_card()


func setup_drag(kind_value: String, id_value: String, display_name: String) -> void:
	payload_kind = kind_value
	payload_id = id_value
	portrait_texture = null
	card_name = display_name
	card_role = ""
	card_location = ""
	text = display_name
	tooltip_text = "지도 구역으로 끌어 배치"
	mouse_default_cursor_shape = Control.CURSOR_DRAG


func _get_drag_data(_at_position: Vector2):
	if payload_id == "":
		return null
	drag_started.emit(payload_kind, payload_id)
	var preview := _build_drag_preview()
	set_drag_preview(preview)
	return drag_payload()


func drag_payload() -> Dictionary:
	if payload_id == "":
		return {}
	if payload_kind == "v20_facility":
		return {"kind": payload_kind, "facility_id": payload_id}
	return {"kind": "v20_monster", "monster_id": payload_id}


func _build_drag_preview() -> Panel:
	var preview := Panel.new()
	var preview_size := Vector2(224, 68) if payload_kind == "v20_monster" and portrait_texture != null else Vector2(184, 54)
	preview.custom_minimum_size = preview_size
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#17121ff5")
	style.border_color = Color("#f0c76a") if payload_kind == "v20_facility" else Color("#b996ef")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color("#00000099")
	style.shadow_size = 6
	preview.add_theme_stylebox_override("panel", style)
	var label_x := 12.0
	if payload_kind == "v20_monster" and portrait_texture != null:
		var preview_portrait := TextureRect.new()
		preview_portrait.name = "Portrait"
		preview_portrait.texture = portrait_texture
		preview_portrait.position = Vector2(7, 7)
		preview_portrait.size = Vector2(54, 54)
		preview_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		preview_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.add_child(preview_portrait)
		label_x = 70.0
	var preview_label := Label.new()
	preview_label.text = "%s\n%s" % [card_name, "구역에 놓아 배치" if payload_kind == "v20_monster" else ""] if payload_kind == "v20_monster" else text
	preview_label.position = Vector2(label_x, 5)
	preview_label.size = Vector2(preview_size.x - label_x - 10.0, preview_size.y - 10.0)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if payload_kind == "v20_monster" else HORIZONTAL_ALIGNMENT_CENTER
	preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_label.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	preview_label.add_theme_font_size_override("font_size", 13)
	preview_label.add_theme_color_override("font_color", Color("#ffe4a0"))
	preview.add_child(preview_label)
	return preview


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_monster_card()
	if what == NOTIFICATION_DRAG_END:
		drag_finished.emit()


func _build_monster_card() -> void:
	clip_contents = true
	for child in get_children():
		child.free()
	_portrait = TextureRect.new()
	_portrait.name = "Portrait"
	_portrait.texture = portrait_texture
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	_name_label = _card_label("Name", card_name, 12, Color("#fff0cf"), UIFontScript.ROLE_EMPHASIS)
	_role_label = _card_label("Role", card_role, 10, Color("#cfb6ed"), UIFontScript.ROLE_BODY)
	_location_label = _card_label("Location", "현재 · %s" % card_location, 9, Color("#bdb3c6"), UIFontScript.ROLE_BODY)
	_drag_label = _card_label("DragAffordance", "드래그", 9, Color("#d7b8ff"), UIFontScript.ROLE_EMPHASIS)
	_drag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_layout_monster_card()
	call_deferred("_layout_monster_card")


func _card_label(node_name: String, value: String, font_size: int, color: Color, role: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", UIFontScript.font_for_role(role))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


func _layout_monster_card() -> void:
	if _portrait == null or _name_label == null:
		return
	var portrait_size := clampf(size.y - 10.0, 36.0, 52.0)
	_portrait.position = Vector2(7.0, (size.y - portrait_size) * 0.5)
	_portrait.size = Vector2(portrait_size, portrait_size)
	var content_x := portrait_size + 15.0
	var drag_width := 45.0
	var content_width := maxf(42.0, size.x - content_x - drag_width - 5.0)
	var row_height := maxf(12.0, (size.y - 7.0) / 3.0)
	_name_label.position = Vector2(content_x, 2.0)
	_name_label.size = Vector2(content_width, row_height + 2.0)
	_role_label.position = Vector2(content_x, 2.0 + row_height)
	_role_label.size = Vector2(content_width, row_height)
	_location_label.position = Vector2(content_x, 2.0 + row_height * 2.0)
	_location_label.size = Vector2(content_width + drag_width, row_height)
	_drag_label.position = Vector2(size.x - drag_width - 4.0, 3.0)
	_drag_label.size = Vector2(drag_width, row_height * 2.0)
