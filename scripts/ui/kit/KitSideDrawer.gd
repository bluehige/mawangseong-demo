extends HBoxContainer
class_name KitSideDrawer
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const PanelScript = preload("res://scripts/ui/kit/KitPanel.gd")
const IconButton = preload("res://scripts/ui/kit/KitIconButton.gd")
signal expanded_changed(expanded: bool)
var handle := IconButton.new()
var panel := PanelScript.new()
var expanded := false

func _init() -> void:
	theme = Kit.base_theme()
	add_child(handle)
	add_child(panel)
	handle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	handle.pressed.connect(func(): set_expanded(not expanded))
	panel.hide()

func configure(title: String, help: String) -> KitSideDrawer:
	handle.configure_icon("chevron", help)
	panel.content.add_child(Kit.label(title, "number", true))
	return self

func set_expanded(value: bool) -> void:
	if expanded == value: return
	expanded = value
	panel.visible = value
	expanded_changed.emit(value)

func mount_right(parent: Control) -> void:
	var align := HBoxContainer.new()
	align.mouse_filter = Control.MOUSE_FILTER_IGNORE
	align.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	align.alignment = BoxContainer.ALIGNMENT_END
	parent.add_child(align)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	if get_parent() != null: reparent(align)
	else: align.add_child(self)

func set_ui_scale(text_scale: float = 1.0, touch: bool = false) -> void:
	Kit.apply_scale(self, text_scale, touch)
