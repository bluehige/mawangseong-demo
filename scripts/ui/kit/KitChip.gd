extends "res://scripts/ui/kit/KitPanel.gd"
class_name KitChip
var row := HBoxContainer.new()
var symbol: TextureRect
var value_label: Label

func _init() -> void:
	super()
	theme_type_variation = "KitChipPanel"
	content.add_child(row)
	symbol = Kit.image("gold", Kit.Tokens.ICON_SMALL)
	value_label = Kit.label("", "number")
	row.add_child(symbol)
	row.add_child(value_label)

func configure(icon_id: String, amount: int, maximum: int = -1, title: String = "") -> KitChip:
	symbol.texture = Kit.Icons.get_icon(icon_id)
	set_amount(amount, maximum)
	tooltip_text = title
	return self

func set_amount(amount: int, maximum: int = -1) -> void:
	value_label.text = "%d / %d" % [amount, maximum] if maximum >= 0 else "×%d" % amount
