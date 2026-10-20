extends VBoxContainer
class_name KitStatBar
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
var header := HBoxContainer.new()
var caption: Label
var numbers: Label
var progress := ProgressBar.new()
var comparison: Label
var well := Control.new()
var track := Panel.new()

func _init() -> void:
	theme = Kit.base_theme()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption = Kit.label("HP", "support")
	caption.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	caption.custom_minimum_size.x = 72
	numbers = Kit.label("", "number")
	numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	numbers.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	numbers.theme_type_variation = "KitBarNumber"
	header.add_child(caption)
	well.custom_minimum_size = Vector2(160, 32)
	well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(well)
	add_child(header)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_theme_stylebox_override("panel",theme.get_stylebox("background","ProgressBar"))
	well.add_child(track)
	track.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	track.offset_top = 4
	track.offset_bottom = 28
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background",StyleBoxEmpty.new())
	progress.custom_minimum_size.y = Kit.Tokens.BAR_HEIGHT
	well.add_child(progress)
	progress.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	progress.offset_top = 4
	progress.offset_bottom = 28
	well.add_child(numbers)
	numbers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	numbers.offset_right = -12
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
	_sync_surface()
	comparison.visible = before >= 0.0
	if comparison.visible:
		var delta := amount - before
		comparison.text = "%s → %s (%s%s)" % [number_text(before), number_text(amount), "+" if delta >= 0 else "", number_text(delta)]
		comparison.add_theme_color_override("font_color", Kit.Tokens.HP if delta >= 0 else Kit.Tokens.DANGER)

func set_ui_scale(text_scale: float = 1.0, touch: bool = false) -> void:
	Kit.apply_scale(self, text_scale, touch)

func _sync_surface() -> void:
	var scale: float = theme.get_meta("kit_geometry_scale",1.0)
	track.add_theme_stylebox_override("panel",theme.get_stylebox("background","ProgressBar"))
	well.custom_minimum_size = Vector2(160,32) * scale
	caption.custom_minimum_size.x = 72 * scale
	numbers.offset_right = -12 * scale
	for bar in [progress,track]:
		bar.offset_top = 4 * scale
		bar.offset_bottom = 28 * scale
	var font: Font = theme.get_font("font","KitBarNumber")
	var pixels := theme.get_font_size("font_size","KitBarNumber")
	progress.offset_right = -font.get_string_size(numbers.text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x - 24 * scale

func number_text(value: float) -> String:
	if not is_equal_approx(value, roundf(value)): return "%.2f" % value
	var digits := str(int(value))
	var result := ""
	for i in range(digits.length()):
		if i > 0 and (digits.length() - i) % 3 == 0: result += ","
		result += digits[i]
	return result
