extends VBoxContainer
class_name KitStatBar
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
var header := HBoxContainer.new()
var caption: Label
var numbers: Label
var progress := ProgressBar.new()
var comparison: Label

func _init() -> void:
	theme = Kit.base_theme()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption = Kit.label("HP", "support")
	numbers = Kit.label("", "number")
	numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(caption)
	header.add_child(numbers)
	add_child(header)
	progress.show_percentage = false
	progress.custom_minimum_size.y = ceilf(theme.default_font.get_height(theme.default_font_size))
	add_child(progress)
	comparison = Kit.label("", "support", true)
	comparison.hide()
	add_child(comparison)

func configure(kind: String, amount: float, maximum: float, before: float = -1.0) -> KitStatBar:
	caption.text = kind
	progress.theme_type_variation = "KitHP" if kind == "HP" else "KitEXP"
	set_value(amount, maximum, before)
	return self

func set_value(amount: float, maximum: float, before: float = -1.0) -> void:
	progress.max_value = maxf(1, maximum)
	progress.value = amount
	numbers.text = "%s / %s" % [number_text(amount), number_text(maximum)]
	comparison.visible = before >= 0.0
	if comparison.visible:
		var delta := amount - before
		comparison.text = "%s → %s (%s%s)" % [number_text(before), number_text(amount), "+" if delta >= 0 else "", number_text(delta)]
		comparison.add_theme_color_override("font_color", Kit.Tokens.HP if delta >= 0 else Kit.Tokens.DANGER)

func set_ui_scale(text_scale: float = 1.0, touch: bool = false) -> void:
	Kit.apply_scale(self, text_scale, touch)

func number_text(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.2f" % value
