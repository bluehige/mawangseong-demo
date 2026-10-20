extends Button

const Standard = preload("res://scripts/ui/UIStandard.gd")

func _make_custom_tooltip(for_text: String) -> Object:
	return Standard.tooltip_label(for_text)
