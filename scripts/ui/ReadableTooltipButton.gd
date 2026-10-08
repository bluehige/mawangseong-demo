extends Button

const UIFont = preload("res://scripts/ui/UIFont.gd")

func _make_custom_tooltip(for_text: String) -> Object:
	var description := Label.new()
	description.text = LanguageSettings.ui_text(for_text)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font := UIFont.font_for_role(UIFont.ROLE_BODY)
	var font_size := UISettings.scaled_font_size(22)
	# The popup must know the wrapped height before placing itself near a window edge.
	var height := font.get_multiline_string_size(description.text, HORIZONTAL_ALIGNMENT_LEFT, 560, font_size).y + 8
	description.custom_minimum_size = Vector2(560, height)
	description.size = description.custom_minimum_size
	description.add_theme_font_override("font", font)
	description.add_theme_font_size_override("font_size", font_size)
	description.add_theme_color_override("font_color", Color("#fff6e8"))
	return description
