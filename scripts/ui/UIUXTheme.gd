extends RefCounted
class_name UIUXTheme
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const INK := Color("#17121f")
const LINE := Color("#67546e")
const PAPER := Color("#f4eadc")
const MUTED := Color("#c0b2c6")
const GOLD := Color("#e8bd76")

static func panel(fill: Color, border: Color, width: int = 1, _radius: int = 6) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(mini(width, 2))
	result.set_corner_radius_all(6)
	result.content_margin_left = 16
	result.content_margin_right = 16
	result.content_margin_top = 8
	result.content_margin_bottom = 8
	return result

static func apply_tree(node: Node) -> void:
	if node is Button and not node.has_meta("uiux_external_button"):
		node.set_meta("uiux_external_button", true)
		node.focus_mode = Control.FOCUS_ALL
		node.add_theme_stylebox_override("focus", panel(Color.TRANSPARENT, GOLD, 2))
		node.add_theme_stylebox_override("disabled", panel(INK.darkened(0.3), LINE.darkened(0.4), 1))
		node.add_theme_color_override("font_disabled_color", MUTED.darkened(0.22))
		if node.text != "":
			var font_size := UISettings.scaled_font_size(22)
			var font := UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON)
			while font_size > UISettings.scaled_font_size(18) and font.get_multiline_string_size(node.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x > node.size.x - 32:
				font_size -= 1
			node.add_theme_font_override("font", font)
			node.add_theme_font_size_override("font_size", font_size)
			node.add_theme_stylebox_override("normal", panel(INK, LINE))
			node.add_theme_stylebox_override("hover", panel(INK.lightened(0.1), GOLD, 2))
			node.add_theme_stylebox_override("pressed", panel(INK.darkened(0.2), GOLD, 2))
			node.add_theme_color_override("font_color", PAPER)
			node.tooltip_text = node.text if node.tooltip_text == "" else node.tooltip_text
	for child in node.get_children():
		apply_tree(child)
