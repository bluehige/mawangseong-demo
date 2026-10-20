extends "res://scripts/ui/kit/KitPanel.gd"
class_name KitModal
const ButtonScript = preload("res://scripts/ui/kit/KitButton.gd")
const Layers = preload("res://scripts/ui/kit/UIKitLayers.gd")
signal confirmed
signal cancelled
var title_label: Label
var description: Label
var confirm_button := ButtonScript.new()
var cancel_button := ButtonScript.new()
var _overlay: CanvasLayer
var _previous_focus: WeakRef
var _resolved := false

func _init() -> void:
	super()
	top_jewel = true
	set_emphasis(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_label = Kit.label("", "number", true)
	description = Kit.label("", "body", true)
	content.add_child(title_label)
	content.add_child(description)
	var actions := HFlowContainer.new()
	actions.add_child(cancel_button)
	actions.add_child(confirm_button)
	content.add_child(actions)
	confirm_button.pressed.connect(func(): resolve(true))
	cancel_button.pressed.connect(func(): resolve(false))

func configure(title: String, explanation: String, confirm_text: String, cancel_text: String) -> KitModal:
	title_label.text = title
	description.text = explanation
	confirm_button.configure(confirm_text, ButtonScript.VariantStyle.PRIMARY)
	cancel_button.configure(cancel_text)
	return self

func present(parent: Node, text_scale: float = 1.0, touch: bool = false) -> void:
	if _overlay != null: return
	var focus := parent.get_viewport().gui_get_focus_owner()
	_previous_focus = weakref(focus) if focus != null else null
	_resolved = false
	_overlay = CanvasLayer.new()
	_overlay.layer = Layers.MODAL
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(_overlay)
	var blocker := ColorRect.new()
	blocker.color = Color(Kit.Tokens.BACKGROUND, 0.8)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(blocker)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.add_child(center)
	if get_parent() != null: reparent(center)
	else: center.add_child(self)
	custom_minimum_size.x = minf(Kit.Tokens.TOOLTIP_WIDTH, get_viewport_rect().size.x - Kit.Tokens.SPACE_LARGE * 2)
	set_ui_scale(text_scale, touch)
	cancel_button.grab_focus()
	# Trap keyboard focus inside the decision, without changing gameplay pause.
	for button in [cancel_button, confirm_button]:
		var other: Button = confirm_button if button == cancel_button else cancel_button
		button.focus_next = button.get_path_to(other)
		button.focus_previous = button.get_path_to(other)

func resolve(accepted: bool) -> void:
	if _resolved: return
	_resolved = true
	if accepted: confirmed.emit()
	else: cancelled.emit()
	if _previous_focus != null:
		var focus = _previous_focus.get_ref()
		if is_instance_valid(focus) and focus.is_visible_in_tree(): focus.grab_focus()
	if _overlay != null: _overlay.queue_free()
	else: hide()

func _unhandled_input(event: InputEvent) -> void:
	if _overlay != null and event.is_action_pressed("ui_cancel"):
		resolve(false)
		get_viewport().set_input_as_handled()
