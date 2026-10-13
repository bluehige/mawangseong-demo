extends HFlowContainer
class_name KitTabs
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const ButtonScript = preload("res://scripts/ui/kit/KitButton.gd")
signal tab_selected(id: String)
var selected_id := ""
var _buttons: Dictionary = {}
var _group := ButtonGroup.new()

func _init() -> void:
	theme = Kit.base_theme()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func set_tabs(entries: Array, active_id: String = "") -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_buttons.clear()
	selected_id = active_id
	for entry in entries:
		var id := str(entry.id)
		var button := ButtonScript.new().configure(str(entry.label), ButtonScript.VariantStyle.BASIC, str(entry.get("icon", "")), str(entry.get("tooltip", entry.label)))
		button.toggle_mode = true
		button.set_meta("kit_button_height", Kit.Tokens.TAB_HEIGHT)
		button.set_meta("kit_surface_radius",Kit.Tokens.RADIUS_TAB)
		button.button_group = _group
		button.disabled = entry.get("disabled", false)
		button.pressed.connect(func(): select_tab(id))
		_buttons[id] = button
		add_child(button)
	if active_id.is_empty() and not entries.is_empty(): selected_id = str(entries[0].id)
	_select_visuals()
	Kit.inherit_theme(self, theme)

func select_tab(id: String) -> void:
	if not _buttons.has(id) or _buttons[id].disabled: return
	if selected_id == id: return
	selected_id = id
	_select_visuals()
	tab_selected.emit(id)

func _select_visuals() -> void:
	for id in _buttons:
		var button: Button = _buttons[id]
		button.set_pressed_no_signal(id == selected_id)
		button.theme_type_variation = "KitPrimary" if id == selected_id else "Button"
		button.set_meta("kit_selected", id == selected_id)
		button.selected_marker = id == selected_id
		button.surface.sync(button)
		button.queue_redraw()

func set_ui_scale(text_scale: float = 1.0, touch: bool = false) -> void:
	Kit.apply_scale(self, text_scale, touch)
