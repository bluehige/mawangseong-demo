extends PanelContainer
class_name KitPanel
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
var content := VBoxContainer.new()

func _init() -> void:
	theme = Kit.base_theme()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.name = "Content"
	add_child(content)

func set_emphasis(enabled: bool) -> void:
	theme_type_variation = "KitEmphasisPanel" if enabled else "PanelContainer"

func set_ui_scale(text_scale: float = 1.0, touch: bool = false) -> void:
	Kit.apply_scale(self, text_scale, touch)
