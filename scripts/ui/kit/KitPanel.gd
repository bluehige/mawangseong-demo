extends PanelContainer
class_name KitPanel
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
var content := VBoxContainer.new()
const Surface = preload("res://scripts/ui/kit/KitSurface.gd")
var surface := Surface.new()
var _emphasis := false
var top_jewel := false
var tooltip_pointer := false

func _init() -> void:
	theme = Kit.base_theme()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.name = "Content"
	add_child(content)
	add_child(surface)
	resized.connect(func(): surface.sync(self, _emphasis))
	_sync_surface()

func set_emphasis(enabled: bool) -> void:
	theme_type_variation = "KitEmphasisPanel" if enabled else "PanelContainer"
	_emphasis = enabled
	surface.sync(self, _emphasis)

func _draw() -> void:
	if not top_jewel and not tooltip_pointer: return
	var x := 128.0 if tooltip_pointer else size.x / 2.0
	var center := Vector2(x, 0)
	if tooltip_pointer:
		draw_colored_polygon(PackedVector2Array([center+Vector2(-18,0),center+Vector2(0,-18),center+Vector2(18,0)]),Kit.Tokens.PANEL)
	var diamond := PackedVector2Array([center+Vector2(0,-14),center+Vector2(10,0),center+Vector2(0,14),center+Vector2(-10,0)])
	draw_colored_polygon(diamond,Kit.Tokens.ACCENT)
	diamond.append(diamond[0])
	draw_polyline(diamond,Kit.Tokens.HIGHLIGHT,2,true)
	if top_jewel:
		draw_line(center+Vector2(-60,0),center+Vector2(-16,0),Kit.Tokens.HIGHLIGHT,1,true)
		draw_line(center+Vector2(16,0),center+Vector2(60,0),Kit.Tokens.HIGHLIGHT,1,true)

func _sync_surface() -> void:
	var empty := StyleBoxEmpty.new()
	var scale: float = theme.get_meta("kit_geometry_scale", 1.0)
	var padding := Kit.Tokens.PADDING if theme_type_variation == "KitChipPanel" else Vector2.ONE * Kit.Tokens.SPACE
	if get_meta("kit_resource_bar", false): padding.y = 14
	if get_meta("kit_toast", false): padding.y = 8
	if get_meta("kit_tooltip", false): padding.y = 14
	for side in [SIDE_LEFT, SIDE_RIGHT]: empty.set_content_margin(side, padding.x * scale)
	for side in [SIDE_TOP, SIDE_BOTTOM]: empty.set_content_margin(side, padding.y * scale)
	add_theme_stylebox_override("panel", empty)
	surface.sync(self, _emphasis)

func set_ui_scale(text_scale: float = 1.0, touch: bool = false) -> void:
	Kit.apply_scale(self, text_scale, touch)
