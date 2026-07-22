class_name V20MonsterDragButton
extends Button

signal drag_started(kind: String, item_id: String)
signal drag_finished

var payload_kind := "v20_monster"
var payload_id := ""


func setup(monster_id_value: String, display_name: String) -> void:
	setup_drag("v20_monster", monster_id_value, display_name)


func setup_drag(kind_value: String, id_value: String, display_name: String) -> void:
	payload_kind = kind_value
	payload_id = id_value
	text = display_name
	tooltip_text = ""


func _get_drag_data(_at_position: Vector2):
	if payload_id == "":
		return null
	drag_started.emit(payload_kind, payload_id)
	var preview := Panel.new()
	preview.custom_minimum_size = Vector2(184, 54)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#17121ff5")
	style.border_color = Color("#f0c76a") if payload_kind == "v20_facility" else Color("#b996ef")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color("#00000099")
	style.shadow_size = 6
	preview.add_theme_stylebox_override("panel", style)
	var preview_label := Label.new()
	preview_label.text = text
	preview_label.position = Vector2(12, 5)
	preview_label.size = Vector2(160, 44)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_label.add_theme_font_size_override("font_size", 13)
	preview_label.add_theme_color_override("font_color", Color("#ffe4a0"))
	preview.add_child(preview_label)
	set_drag_preview(preview)
	if payload_kind == "v20_facility":
		return {"kind": payload_kind, "facility_id": payload_id}
	return {"kind": "v20_monster", "monster_id": payload_id}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_finished.emit()
