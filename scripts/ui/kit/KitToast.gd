extends "res://scripts/ui/kit/KitPanel.gd"
class_name KitToast
const IconButton = preload("res://scripts/ui/kit/KitIconButton.gd")
const Layers = preload("res://scripts/ui/kit/UIKitLayers.gd")
signal dismissed
var message: Label
var close_button := IconButton.new()
var _overlay: CanvasLayer
var _dismissed := false

func _init() -> void:
	super()
	var row := HBoxContainer.new()
	row.add_child(Kit.image("check"))
	message = Kit.label("", "body", true)
	row.add_child(message)
	row.add_child(close_button)
	content.add_child(row)
	close_button.pressed.connect(dismiss)

func configure(text: String, dismiss_help: String) -> KitToast:
	message.text = text
	close_button.configure_icon("close", dismiss_help)
	return self

func present(parent: Node, seconds: float = 3.0, text_scale: float = 1.0, touch: bool = false) -> void:
	if _overlay != null: return
	_overlay = CanvasLayer.new()
	_overlay.layer = Layers.TOAST_TOOLTIP
	parent.add_child(_overlay)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(margin)
	var align := VBoxContainer.new()
	align.mouse_filter = Control.MOUSE_FILTER_IGNORE
	align.alignment = BoxContainer.ALIGNMENT_END
	margin.add_child(align)
	size_flags_horizontal = Control.SIZE_SHRINK_END
	if get_parent() != null: reparent(align)
	else: align.add_child(self)
	custom_minimum_size.x = minf(Kit.Tokens.TOOLTIP_WIDTH, get_viewport_rect().size.x - Kit.Tokens.SPACE_LARGE * 2)
	set_ui_scale(text_scale, touch)
	if seconds > 0: get_tree().create_timer(seconds).timeout.connect(dismiss)

func dismiss() -> void:
	if _dismissed: return
	_dismissed = true
	dismissed.emit()
	if _overlay != null: _overlay.queue_free()
	else: hide()
