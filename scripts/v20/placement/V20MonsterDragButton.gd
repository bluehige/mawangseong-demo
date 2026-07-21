class_name V20MonsterDragButton
extends Button

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
	var preview := Label.new()
	preview.text = text
	preview.add_theme_font_size_override("font_size", 16)
	preview.add_theme_color_override("font_color", Color("#ffe4a0"))
	set_drag_preview(preview)
	if payload_kind == "v20_facility":
		return {"kind": payload_kind, "facility_id": payload_id}
	return {"kind": "v20_monster", "monster_id": payload_id}
