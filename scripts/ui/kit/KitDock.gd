extends "res://scripts/ui/kit/KitPanel.gd"
class_name KitDock
const TabsScript = preload("res://scripts/ui/kit/KitTabs.gd")
signal action_selected(id: String)
var tabs := TabsScript.new()

func _init() -> void:
	super()
	content.add_child(tabs)
	tabs.tab_selected.connect(func(id: String): action_selected.emit(id))

func configure(entries: Array, selected: String = "") -> KitDock:
	tabs.set_tabs(entries, selected)
	for button in tabs._buttons.values():
		button.set_meta("kit_button_height", Kit.Tokens.DOCK_HEIGHT)
		button.set_meta("kit_surface_radius",Kit.Tokens.RADIUS_DOCK)
		button.custom_minimum_size.y = Kit.Tokens.DOCK_HEIGHT
	return self

func mount_bottom(parent: Control) -> void:
	# The parent should reserve this container's actual minimum height for the map.
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(margin)
	var align := VBoxContainer.new()
	align.mouse_filter = Control.MOUSE_FILTER_IGNORE
	align.alignment = BoxContainer.ALIGNMENT_END
	margin.add_child(align)
	if get_parent() != null: reparent(align)
	else: align.add_child(self)
