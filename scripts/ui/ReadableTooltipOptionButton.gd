extends OptionButton

func _make_custom_tooltip(for_text: String) -> Object:
	return preload("res://scripts/ui/UIStandard.gd").tooltip_label(for_text)
