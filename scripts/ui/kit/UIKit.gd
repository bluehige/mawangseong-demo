extends RefCounted
class_name UIKit
const Tokens = preload("res://scripts/ui/kit/UIKitTokens.gd")
const Fonts = preload("res://scripts/ui/UIFont.gd")
const Icons = preload("res://scripts/ui/kit/UIKitIcons.gd")
const THEME_PATH := "res://assets/ui/kit/StyleB.tres"
static var _base_theme: Theme

static func base_theme() -> Theme:
	if _base_theme == null: _base_theme = load(THEME_PATH)
	return _base_theme

static func label(text: String, role: String = "body", wrap: bool = false) -> Label:
	var result := Label.new()
	result.text = text
	result.theme_type_variation = {"title":"KitTitle", "support":"KitSupport", "number":"KitNumber"}.get(role, "Label")
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func image(id: String, pixels: int = Tokens.ICON_SIZE) -> TextureRect:
	var result := TextureRect.new()
	result.texture = Icons.get_icon(id)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.custom_minimum_size = Vector2.ONE * pixels
	result.set_meta("kit_image_pixels", pixels)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return result

static func scaled_theme(text_scale: float = 1.0, touch: bool = false) -> Theme:
	var result := base_theme().duplicate(true) as Theme
	var scale := Tokens.geometry_scale(text_scale, touch)
	result.set_meta("kit_geometry_scale", scale)
	result.default_font = Fonts.font_for_role(Fonts.ROLE_BODY)
	result.default_font_size = Tokens.font_size(Tokens.BODY_SIZE, text_scale, touch)
	for type in result.get_type_list():
		for item in result.get_font_size_list(type):
			result.set_font_size(item, type, Tokens.font_size(base_theme().get_font_size(item, type), text_scale, touch))
		for item in result.get_font_list(type):
			result.set_font(item, type, Fonts.font_for_role(Fonts.ROLE_BUTTON if type in ["Button", "TabBar", "OptionButton", "CheckBox", "KitTitle", "KitNumber"] else Fonts.ROLE_BODY))
		for item in result.get_constant_list(type):
			if item in ["separation", "h_separation", "v_separation", "icon_max_width", "margin_left", "margin_right", "margin_top", "margin_bottom", "minimum_grab_thickness", "outline_size"]:
				result.set_constant(item, type, roundi(result.get_constant(item, type) * scale))
	# Shared styles must be scaled once, not once per theme key.
	var visited: Dictionary = {}
	for type in result.get_type_list():
		for item in result.get_stylebox_list(type):
			var style := result.get_stylebox(item, type)
			if visited.has(style.get_instance_id()): continue
			visited[style.get_instance_id()] = true
			for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				style.set_content_margin(side, style.get_content_margin(side) * scale)
			if style is StyleBoxFlat:
				for corner in range(4): style.set_corner_radius(corner, roundi(style.get_corner_radius(corner) * scale))
				style.shadow_size = roundi(style.shadow_size * scale)
				style.shadow_offset *= scale
			elif style is StyleBoxTexture:
				for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: style.set_texture_margin(side, style.get_texture_margin(side) * scale)
	return result

static func apply_scale(root: Control, text_scale: float = 1.0, touch: bool = false) -> void:
	_apply_theme(root, scaled_theme(text_scale, touch), Tokens.geometry_scale(text_scale, touch))

static func inherit_theme(root: Control, shared: Theme) -> void:
	_apply_theme(root, shared, shared.get_meta("kit_geometry_scale", 1.0))

static func _apply_theme(node: Node, shared: Theme, scale: float) -> void:
	if node is Control:
		node.theme = shared
		if node.has_meta("kit_image_pixels"):
			node.custom_minimum_size = Vector2.ONE * node.get_meta("kit_image_pixels") * scale
		if node is Button:
			node.custom_minimum_size = Vector2.ONE * Tokens.ICON_BUTTON_SIZE * scale if node.get_meta("kit_icon_button", false) else Vector2(0, Tokens.BUTTON_HEIGHT * scale)
			# Text/font minimum is provided by Button; never freeze its Rect height.
		if node is ProgressBar:
			node.custom_minimum_size.y = ceilf(shared.default_font.get_height(shared.default_font_size))
	for child in node.get_children(): _apply_theme(child, shared, scale)
