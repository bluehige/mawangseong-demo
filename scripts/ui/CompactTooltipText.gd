extends RichTextLabel
## Bounded text layout, with scrolling only when the complete copy exceeds the cap.
const Layout = preload("res://scripts/ui/DialogueLayout.gd")

func configure(words: String, font: Font, pixels: int, width: float = 512) -> void:
	text = words
	bbcode_enabled = false
	add_theme_font_override("normal_font",font)
	add_theme_font_size_override("normal_font_size",pixels)
	add_theme_color_override("default_color",Color("#fff6e8"))
	var height := ceilf(Layout.paragraph(words,font,pixels,width-8).get_size().y)+8
	custom_minimum_size = Vector2(width,clampf(height,32,420))
	size = custom_minimum_size
	scroll_active = height > 420
	mouse_filter = Control.MOUSE_FILTER_PASS if scroll_active else Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	# Tooltip popups are native Windows. Keep their top below the three map tabs.
	call_deferred("place_below_tabs")

func place_below_tabs() -> void:
	var popup := get_window()
	if not popup is PopupPanel: return
	var host := popup.get_parent().get_viewport().get_window()
	if host == popup: return
	var factor := float(host.size.y)/1080.0
	var reserved := host.position.y+ceili(126*factor)
	popup.position.y = maxi(popup.position.y,reserved)
