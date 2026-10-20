extends "res://scripts/ui/kit/KitButton.gd"
class_name KitIconButton

func _init() -> void:
	super()
	set_meta("kit_icon_button", true)
	custom_minimum_size = Vector2.ONE * Kit.Tokens.ICON_BUTTON_SIZE
	_sync_surface()

func configure_icon(icon_id: String, help: String) -> KitIconButton:
	configure("", VariantStyle.BASIC, icon_id, help)
	return self

func _ready() -> void:
	if tooltip_text.strip_edges().is_empty():
		push_warning("KitIconButton requires a nonempty tooltip: " + str(get_path()))
