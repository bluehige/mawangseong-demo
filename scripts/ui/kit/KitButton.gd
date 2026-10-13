extends Button
class_name KitButton
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const Tooltip = preload("res://scripts/ui/kit/KitTooltip.gd")
enum VariantStyle { BASIC, PRIMARY, DANGER, DISABLED }
var tooltip_costs: Dictionary = {}
const Surface = preload("res://scripts/ui/kit/KitSurface.gd")
var surface := Surface.new()
var selected_marker := false
var jewel := false

func _init() -> void:
	theme = Kit.base_theme()
	custom_minimum_size.y = Kit.Tokens.BUTTON_HEIGHT
	focus_mode = Control.FOCUS_ALL
	# icon_max_width caps original PNGs; retain icon width in the text/button minimum.
	expand_icon = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(surface)
	resized.connect(func(): surface.sync(self))
	_sync_surface()

func configure(caption: String, variant: VariantStyle = VariantStyle.BASIC, icon_id: String = "", help: String = "") -> KitButton:
	text = caption
	icon = Kit.Icons.get_icon(icon_id) if not icon_id.is_empty() else null
	set_variant(variant)
	tooltip_text = help if not help.is_empty() else caption
	return self

func set_variant(variant: VariantStyle) -> void:
	disabled = variant == VariantStyle.DISABLED
	theme_type_variation = "KitPrimary" if variant == VariantStyle.PRIMARY else ("KitDanger" if variant == VariantStyle.DANGER else "Button")
	surface.sync(self)
	queue_redraw()

func _sync_surface() -> void:
	var empty := StyleBoxEmpty.new()
	var scale: float = theme.get_meta("kit_geometry_scale", 1.0)
	var horizontal: float = 12 if get_meta("kit_icon_button",false) else Kit.Tokens.PADDING.x
	var vertical: float = Kit.Tokens.PADDING.y
	if get_meta("kit_button_height",0) == Kit.Tokens.TAB_HEIGHT:
		horizontal = 18
		vertical = 11
	for side in [SIDE_LEFT, SIDE_RIGHT]: empty.set_content_margin(side, horizontal * scale)
	for side in [SIDE_TOP, SIDE_BOTTOM]: empty.set_content_margin(side, vertical * scale)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]: add_theme_stylebox_override(state, empty)
	surface.sync(self)

func _draw() -> void:
	surface.sync(self)
	if selected_marker or jewel:
		var scale: float = theme.get_meta("kit_geometry_scale", 1.0)
		var center := Vector2(size.x / 2, size.y + 3 if selected_marker else 0)
		var diamond := PackedVector2Array([center + Vector2(0,-10)*scale, center + Vector2(8,0)*scale, center + Vector2(0,10)*scale, center + Vector2(-8,0)*scale])
		draw_colored_polygon(diamond, Kit.Tokens.ACCENT)
		diamond.append(diamond[0])
		draw_polyline(diamond, Kit.Tokens.TEXT if selected_marker else Kit.Tokens.HIGHLIGHT, 2.0 * scale, true)

func set_ui_scale(text_scale: float = 1.0, touch: bool = false) -> void:
	Kit.apply_scale(self, text_scale, touch)

func _make_custom_tooltip(for_text: String) -> Object:
	var parts := for_text.split("\n", false, 1)
	var width: float = minf(Kit.Tokens.TOOLTIP_WIDTH, get_viewport_rect().size.x - Kit.Tokens.SPACE_LARGE * 2) if is_inside_tree() else Kit.Tokens.TOOLTIP_WIDTH
	var result := Tooltip.new().configure(parts[0] if not parts.is_empty() else text, parts[1] if parts.size() > 1 else "", tooltip_costs, width)
	Kit.inherit_theme(result, theme)
	return result
