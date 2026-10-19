extends "res://scripts/ui/kit/KitIconButton.gd"
## Match the readable button tooltip; reuse the shipped GPT panel unchanged.
const Standard = preload("res://scripts/ui/UIStandard.gd")

func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	panel.name = "DialogueToolbarTooltip"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := StyleBoxTexture.new()
	frame.texture = preload("res://assets/ui/uiux/obsidian_panel.png")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		frame.set_texture_margin(side, 32)
		frame.set_content_margin(side, 14)
	panel.add_theme_stylebox_override("panel", frame)
	var label := Standard.tooltip_label(for_text)
	label.configure(LanguageSettings.ui_text(for_text),Standard.UIFont.font_for_role("body"),Standard.text_size(Standard.TOOLTIP_SIZE),minf(392,get_viewport_rect().size.x-128))
	panel.add_child(label)
	return panel
