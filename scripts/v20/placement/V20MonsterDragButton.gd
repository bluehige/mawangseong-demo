class_name V20MonsterDragButton
extends Button

var monster_id := ""


func setup(monster_id_value: String, display_name: String) -> void:
	monster_id = monster_id_value
	text = display_name
	tooltip_text = "방으로 드래그하거나 클릭한 뒤 방을 클릭하세요."


func _get_drag_data(_at_position: Vector2):
	if monster_id == "":
		return null
	var preview := Label.new()
	preview.text = text
	preview.add_theme_font_size_override("font_size", 16)
	preview.add_theme_color_override("font_color", Color("#ffe4a0"))
	set_drag_preview(preview)
	return {"kind": "v20_monster", "monster_id": monster_id}
