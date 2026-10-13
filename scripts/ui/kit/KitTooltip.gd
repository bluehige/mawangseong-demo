extends "res://scripts/ui/kit/KitPanel.gd"
class_name KitTooltip
const Layers = preload("res://scripts/ui/kit/UIKitLayers.gd")
var title_label: Label
var description: Label
var costs := HFlowContainer.new()
var _overlay: CanvasLayer
var illustration: TextureRect

func _init() -> void:
	super()
	tooltip_pointer = true
	set_meta("kit_tooltip",true)
	set_meta("kit_surface_radius",Kit.Tokens.RADIUS_COMPACT)
	_sync_surface()
	set_emphasis(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label = Kit.label("", "title", true)
	title_label.add_theme_font_size_override("font_size",32)
	description = Kit.label("", "body", true)
	description.theme_type_variation = "KitTooltipBody"
	var row := HBoxContainer.new()
	illustration = Kit.image("build", 176)
	illustration.hide()
	row.add_child(illustration)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(title_label)
	copy.add_child(description)
	copy.add_child(costs)
	row.add_child(copy)
	content.add_child(row)

func set_illustration(texture: Texture2D) -> void:
	illustration.texture = texture
	illustration.visible = texture != null

func configure(title: String, explanation: String, amounts: Dictionary = {}, max_width: float = Kit.Tokens.TOOLTIP_WIDTH) -> KitTooltip:
	title_label.text = title
	description.text = explanation
	description.visible = not explanation.is_empty()
	for child in costs.get_children():
		costs.remove_child(child)
		child.queue_free()
	for id in amounts:
		var cost := HBoxContainer.new()
		cost.add_child(Kit.image(id,40))
		cost.add_child(Kit.label(str(int(amounts[id])),"number"))
		costs.add_child(cost)
	costs.visible = not amounts.is_empty()
	# Width is bounded by the viewport; height belongs to wrapped contents.
	custom_minimum_size.x = minf(max_width, Kit.Tokens.TOOLTIP_WIDTH)
	Kit.inherit_theme(self, theme)
	return self

func present_at(parent: Node, anchor: Vector2, text_scale: float = 1.0, touch: bool = false) -> void:
	if _overlay != null: return
	_overlay = CanvasLayer.new()
	_overlay.layer = Layers.TOAST_TOOLTIP
	parent.add_child(_overlay)
	if get_parent() != null: reparent(_overlay)
	else: _overlay.add_child(self)
	set_ui_scale(text_scale, touch)
	custom_minimum_size.x = minf(Kit.Tokens.TOOLTIP_WIDTH, get_viewport_rect().size.x - Kit.Tokens.SPACE_LARGE * 2)
	await get_tree().process_frame
	size = get_combined_minimum_size()
	position = anchor.clamp(Vector2.ONE * Kit.Tokens.SPACE, get_viewport_rect().size - size - Vector2.ONE * Kit.Tokens.SPACE)

func dismiss() -> void:
	if _overlay != null: _overlay.queue_free()
	else: hide()
