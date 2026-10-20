extends PanelContainer
class_name KitTooltip
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const Layers = preload("res://scripts/ui/kit/UIKitLayers.gd")
var copy := preload("res://scripts/ui/CompactTooltipText.gd").new()
var _overlay: CanvasLayer

func _init() -> void:
	var frame := StyleBoxTexture.new()
	frame.texture = preload("res://assets/ui/uiux/obsidian_panel.png")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		frame.set_texture_margin(side,40)
		frame.set_content_margin(side,14)
	add_theme_stylebox_override("panel",frame)
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(copy)

func configure(title: String, explanation: String, amounts: Dictionary = {}, max_width: float = Kit.Tokens.TOOLTIP_WIDTH) -> KitTooltip:
	var lines: Array[String] = [title]
	if not explanation.is_empty(): lines.append(explanation)
	for id in amounts: lines.append(LanguageSettings.ui_text(str(id))+"  "+str(int(amounts[id])))
	copy.configure("\n".join(lines),Kit.Fonts.font_for_role("body"),24,maxf(160,minf(max_width,Kit.Tokens.TOOLTIP_WIDTH)-28))
	return self

func present_at(parent: Node, anchor: Vector2, _text_scale: float = 1.0, _touch: bool = false) -> void:
	if _overlay != null: return
	_overlay = CanvasLayer.new()
	_overlay.layer = Layers.TOAST_TOOLTIP
	parent.add_child(_overlay)
	if get_parent() != null: reparent(_overlay)
	else: _overlay.add_child(self)
	await get_tree().process_frame
	size = get_combined_minimum_size()
	position = anchor.clamp(Vector2(12,126),get_viewport_rect().size-size-Vector2.ONE*12)

func dismiss() -> void:
	if _overlay != null: _overlay.queue_free()
	else: hide()
