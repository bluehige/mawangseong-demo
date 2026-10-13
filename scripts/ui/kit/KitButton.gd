extends Button
class_name KitButton
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const Tooltip = preload("res://scripts/ui/kit/KitTooltip.gd")
enum VariantStyle { BASIC, PRIMARY, DANGER, DISABLED }
var tooltip_costs: Dictionary = {}

func _init() -> void:
	theme = Kit.base_theme()
	custom_minimum_size.y = Kit.Tokens.BUTTON_HEIGHT
	focus_mode = Control.FOCUS_ALL
	# icon_max_width caps original PNGs; retain icon width in the text/button minimum.
	expand_icon = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func configure(caption: String, variant: VariantStyle = VariantStyle.BASIC, icon_id: String = "", help: String = "") -> KitButton:
	text = caption
	icon = Kit.Icons.get_icon(icon_id) if not icon_id.is_empty() else null
	set_variant(variant)
	tooltip_text = help if not help.is_empty() else caption
	return self

func set_variant(variant: VariantStyle) -> void:
	disabled = variant == VariantStyle.DISABLED
	theme_type_variation = "KitPrimary" if variant == VariantStyle.PRIMARY else ("KitDanger" if variant == VariantStyle.DANGER else "Button")

func set_ui_scale(text_scale: float = 1.0, touch: bool = false) -> void:
	Kit.apply_scale(self, text_scale, touch)

func _make_custom_tooltip(for_text: String) -> Object:
	var parts := for_text.split("\n", false, 1)
	var width: float = minf(Kit.Tokens.TOOLTIP_WIDTH, get_viewport_rect().size.x - Kit.Tokens.SPACE_LARGE * 2) if is_inside_tree() else Kit.Tokens.TOOLTIP_WIDTH
	var result := Tooltip.new().configure(parts[0] if not parts.is_empty() else text, parts[1] if parts.size() > 1 else "", tooltip_costs, width)
	Kit.inherit_theme(result, theme)
	return result
