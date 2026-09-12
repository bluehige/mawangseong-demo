extends RefCounted
class_name UIUXTheme
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const INK := Color("#17121f")
const LINE := Color("#67546e")
const PAPER := Color("#f4eadc")
const MUTED := Color("#c0b2c6")
const GOLD := Color("#e8bd76")

const Obsidian = preload("res://scripts/ui/ObsidianStyleBox.gd")
static var _panel_texture: Texture2D
static var _button_texture: Texture2D

static func panel(fill: Color, border: Color, width: int = 1, _radius: int = 6) -> StyleBox:
	return surface(fill,border,width,false)

static func surface(fill: Color, border: Color, width: int = 1, is_button: bool = true) -> StyleBox:
	if _panel_texture == null:
		_panel_texture = load("res://assets/ui/uiux/obsidian_panel.png")
		_button_texture = load("res://assets/ui/uiux/obsidian_button.png")
	var result := Obsidian.new()
	result.texture = _button_texture if is_button else _panel_texture
	result.button_shape = is_button
	result.panel_texture = _panel_texture
	result.fill = fill
	result.accent = border
	result.strong = width >= 2
	result.outline_only = fill.a <= 0.01
	result.tint = Color(1.18,1.08,0.9) if width >= 2 else Color(0.72,0.75,0.8)
	if is_button and width >= 2:
		result.tint = Color(1.42,0.76,0.77) if fill.get_luminance() >= INK.get_luminance() else Color(0.95,0.48,0.52)
	elif fill.get_luminance() < INK.get_luminance()*0.65:
		result.tint = Color(0.4,0.42,0.46)
	if is_button:
		result.tint *= clampf(fill.v/INK.v,0.55,1.4)
	result.tint.a = fill.a
	return result

static var _world_badges: Dictionary = {}

static func world_badge(accent: Color) -> StyleBox:
	var key := accent.to_html()
	if not _world_badges.has(key):
		var style := surface(INK, accent, 1, true)
		style.set("strong", true)
		_world_badges[key] = style
	return _world_badges[key]

static func apply_tree(node: Node) -> void:
	if node is Button and not node.has_meta("uiux_external_button"):
		node.set_meta("uiux_external_button", true)
		node.focus_mode = Control.FOCUS_ALL
		node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		node.add_theme_stylebox_override("focus", surface(Color.TRANSPARENT, GOLD, 2))
		node.add_theme_stylebox_override("disabled", surface(INK.darkened(0.3), LINE.darkened(0.4), 1))
		node.add_theme_color_override("font_disabled_color", MUTED.darkened(0.22))
		if node.text != "":
			var font_size := UISettings.scaled_font_size(22)
			var font := UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON)
			while font_size > UISettings.scaled_font_size(18) and font.get_multiline_string_size(node.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x > node.size.x - 32:
				font_size -= 1
			node.add_theme_font_override("font", font)
			node.add_theme_font_size_override("font_size", font_size)
			node.add_theme_stylebox_override("normal", surface(INK, LINE))
			node.add_theme_stylebox_override("hover", surface(INK.lightened(0.1), GOLD, 2))
			node.add_theme_stylebox_override("pressed", surface(INK.darkened(0.2), GOLD, 2))
			node.add_theme_color_override("font_color", PAPER)
			node.tooltip_text = node.text if node.tooltip_text == "" else node.tooltip_text
	for child in node.get_children():
		apply_tree(child)
