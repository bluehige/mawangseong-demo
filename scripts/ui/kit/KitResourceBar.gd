extends "res://scripts/ui/kit/KitPanel.gd"
class_name KitResourceBar
var row := HFlowContainer.new()
var values: Dictionary = {}

func _init() -> void:
	super()
	custom_minimum_size.y = Kit.Tokens.RESOURCE_HEIGHT
	set_meta("kit_resource_bar", true)
	_sync_surface()
	content.add_child(row)
	for id in ["gold", "mana", "food", "infamy"]:
		var item := HBoxContainer.new()
		item.add_child(Kit.image(id))
		var value_label := Kit.label("0", "number")
		value_label.add_theme_color_override("font_color", Kit.Tokens.TEXT)
		item.add_child(value_label)
		row.add_child(item)
		item.custom_minimum_size.x = 176
		values[id] = value_label

func set_resources(amounts: Dictionary, descriptions: Dictionary = {}) -> void:
	for id in values:
		values[id].text = str(amounts.get(id, 0))
		values[id].get_parent().tooltip_text = descriptions.get(id, id)
