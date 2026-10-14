extends "res://scripts/ui/kit/KitButton.gd"
# A fixed square keeps the existing Button input contract and live HUD captions.
var action_icon: Texture2D
var caption := Label.new()

func _init() -> void:
	super()
	set_meta("kit_button_height", 168)
	custom_minimum_size=Vector2(184,184); size=Vector2(184,184)
	caption.name = "ActionCaption"
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(caption)
	resized.connect(_layout_caption)
	caption.minimum_size_changed.connect(_layout_caption)
	_layout_caption()

func set_action_caption(value: String) -> void:
	if caption.text != value: caption.text = value
	caption.tooltip_text = value
	_layout_caption()
	queue_redraw()

func _layout_caption() -> void:
	caption.position = Vector2(8, size.y * 0.33)
	caption.size = Vector2(size.x - 16, size.y * 0.67 - 6)
	var pixels := Kit.Tokens.font_size(20, UISettings.text_scale, UISettings.is_touch_ui())
	if caption.get_theme_font_size("font_size")!=pixels: caption.add_theme_font_size_override("font_size",pixels)

func _draw() -> void:
	super()
	var unavailable: bool = disabled or get_meta("action_unavailable", false)
	caption.modulate = Color(0.65,0.65,0.65) if unavailable else Color.WHITE
	var extent := minf(56, size.y * 0.30)
	if action_icon != null:
		var icon_size := action_icon.get_size()
		icon_size *= extent / maxf(icon_size.x,icon_size.y)
		draw_texture_rect(action_icon, Rect2(Vector2((size.x-icon_size.x)/2, 4+(extent-icon_size.y)/2),icon_size), false, caption.modulate)
	if unavailable:
		draw_texture_rect(Kit.Icons.get_icon("lock"), Rect2(size.x-30, 6, 24, 24), false)
