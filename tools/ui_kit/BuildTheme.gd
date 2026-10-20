extends SceneTree
## Regenerate the one serialized Theme from UIKitTokens. No project-global install.
const T = preload("res://scripts/ui/kit/UIKitTokens.gd")
const F = preload("res://scripts/ui/UIFont.gd")
const Icons = preload("res://scripts/ui/kit/UIKitIcons.gd")

func bar(fill: Color) -> StyleBoxTexture:
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="24"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="#%s"/><stop offset=".45" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs><rect x="1" y="1" width="126" height="22" rx="11" fill="url(#g)" stroke="#%s" stroke-width="1"/></svg>' % [fill.lightened(0.5).to_html(false), fill.to_html(false), fill.darkened(0.38).to_html(false), fill.lightened(0.4).to_html(false)]
	var image := Image.new()
	image.load_svg_from_string(svg)
	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(image)
	style.texture_margin_left = 12
	style.texture_margin_right = 12
	return style

func flat(fill: Color, border: Color, radius: int = T.RADIUS, padding: Vector2 = T.PADDING, glow: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding.x
	style.content_margin_right = padding.x
	style.content_margin_top = padding.y
	style.content_margin_bottom = padding.y
	style.shadow_color = T.GLOW if glow else T.SHADOW
	style.shadow_size = T.GLOW_SIZE if glow else T.SHADOW_SIZE
	style.shadow_offset = Vector2.ZERO if glow else T.SHADOW_OFFSET
	return style

func _initialize() -> void:
	var theme := Theme.new()
	theme.resource_name = "Style B - Cute Dark Fantasy"
	theme.default_font = F.font_for_role(F.ROLE_BODY)
	theme.default_font_size = T.BODY_SIZE
	var panel := flat(T.PANEL, T.BORDER, T.RADIUS_LARGE, Vector2(T.SPACE, T.SPACE))
	var normal := flat(T.PANEL_RAISED, T.BORDER)
	var hover := flat(T.PANEL_RAISED.lightened(0.12), T.ACCENT, T.RADIUS, T.PADDING, true)
	var pressed := flat(T.GRADIENT_BOTTOM, T.ACCENT)
	var disabled := flat(T.DISABLED, T.BORDER.darkened(0.4))
	var focus := flat(Color.TRANSPARENT, T.HIGHLIGHT)
	focus.set_border_width_all(2)
	focus.shadow_size = 0
	var danger := flat(T.DANGER.darkened(0.65), T.DANGER)
	var accent := StyleBoxTexture.new()
	# The SVG and its one small embedded texture are derived from tokens, not a
	# second palette. Decode the SVG directly so regeneration needs no editor import.
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="64" viewBox="0 0 256 64"><defs><linearGradient id="b" x2="0" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs><rect x="1" y="1" width="254" height="62" rx="%d" fill="url(#b)" stroke="#%s" stroke-width="2"/><path d="M18 4H238" stroke="#%s" opacity=".45"/></svg>\n' % [T.GRADIENT_TOP.to_html(false), T.GRADIENT_BOTTOM.to_html(false), T.RADIUS, T.ACCENT.to_html(false), T.TEXT.to_html(false)]
	var source := FileAccess.open("res://assets/ui/kit/accent_button.svg", FileAccess.WRITE)
	source.store_string(svg)
	source.close()
	var gradient_image := Image.new()
	var svg_error := gradient_image.load_svg_from_string(svg)
	if svg_error != OK:
		push_error("Style B gradient SVG could not be decoded")
		quit(1)
		return
	accent.texture = ImageTexture.create_from_image(gradient_image)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: accent.set_texture_margin(side, T.RADIUS + 2)
	accent.content_margin_left = T.PADDING.x
	accent.content_margin_right = T.PADDING.x
	accent.content_margin_top = T.PADDING.y
	accent.content_margin_bottom = T.PADDING.y
	for type in ["Button", "OptionButton", "CheckBox"]:
		theme.set_font("font", type, F.font_for_role(F.ROLE_BUTTON))
		theme.set_font_size("font_size", type, T.BUTTON_SIZE)
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			theme.set_stylebox(state, type, {"normal":normal, "hover":hover, "pressed":pressed, "hover_pressed":hover, "disabled":disabled, "focus":focus}[state])
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]: theme.set_color(state, type, T.TEXT)
		theme.set_color("font_disabled_color", type, T.TEXT_MUTED)
		theme.set_color("icon_disabled_color", type, T.TEXT_MUTED)
		theme.set_constant("h_separation", type, T.SPACE_SMALL)
		theme.set_constant("icon_max_width", type, T.ICON_SIZE)
	for variant in ["KitPrimary", "KitDanger"]:
		theme.set_type_variation(variant, "Button")
		theme.set_stylebox("normal", variant, accent if variant == "KitPrimary" else danger)
		theme.set_stylebox("pressed", variant, pressed if variant == "KitPrimary" else flat(T.DANGER.darkened(0.8), T.DANGER))
		theme.set_stylebox("hover", variant, hover if variant == "KitPrimary" else flat(T.DANGER.darkened(0.5), T.DANGER, T.RADIUS, T.PADDING, true))
		theme.set_stylebox("hover_pressed", variant, theme.get_stylebox("hover", variant))
	for variant in ["KitTitle", "KitSupport", "KitNumber", "KitBarNumber"]:
		theme.set_type_variation(variant, "Label")
		theme.set_font_size("font_size", variant, {"KitTitle":T.TITLE_SIZE, "KitSupport":T.SUPPORT_SIZE, "KitNumber":T.NUMBER_SIZE, "KitBarNumber":T.SUPPORT_SIZE}[variant])
		theme.set_font("font", variant, F.font_for_role(F.ROLE_EMPHASIS if variant == "KitTitle" else F.ROLE_BODY))
		theme.set_color("font_color", variant, T.TEXT_SECONDARY if variant == "KitSupport" else T.TEXT)
	theme.set_color("font_color", "Label", T.TEXT)
	theme.set_font("font", "Label", F.font_for_role(F.ROLE_BODY))
	theme.set_font_size("font_size", "Label", T.BODY_SIZE)
	theme.set_type_variation("KitTooltipBody", "Label")
	theme.set_font_size("font_size", "KitTooltipBody", T.TOOLTIP_SIZE)
	theme.set_font("font", "KitTooltipBody", F.font_for_role(F.ROLE_BODY))
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_type_variation("KitEmphasisPanel", "PanelContainer")
	theme.set_stylebox("panel", "KitEmphasisPanel", flat(T.PANEL, T.HIGHLIGHT, T.RADIUS_LARGE, Vector2(T.SPACE, T.SPACE), true))
	theme.set_type_variation("KitChipPanel", "PanelContainer")
	theme.set_stylebox("panel", "KitChipPanel", flat(T.PANEL_RAISED, T.BORDER, T.RADIUS_LARGE))
	for type in ["HBoxContainer", "VBoxContainer", "GridContainer", "HFlowContainer"]:
		for key in ["separation", "h_separation", "v_separation"]: theme.set_constant(key, type, T.SPACE_SMALL)
	for key in ["margin_left", "margin_right", "margin_top", "margin_bottom"]: theme.set_constant(key, "MarginContainer", T.SPACE)
	for type in ["ProgressBar", "HSlider"]:
		var track := flat(T.BACKGROUND, T.BORDER.darkened(0.3), T.RADIUS_SMALL, Vector2(0, 0))
		track.shadow_size = 0
		var fill := bar(T.EXP)
		theme.set_stylebox("background" if type == "ProgressBar" else "slider", type, track)
		theme.set_stylebox("fill" if type == "ProgressBar" else "grabber_area", type, fill)
		if type == "HSlider":
			theme.set_stylebox("grabber_area_highlight", type, fill)
			theme.set_icon("grabber", type, Icons.get_icon("slider_grip"))
			theme.set_icon("grabber_highlight", type, Icons.get_icon("slider_grip"))
			theme.set_icon("grabber_disabled", type, Icons.get_icon("slider_grip"))
		theme.set_color("font_color", type, T.TEXT)
		theme.set_font_size("font_size", type, T.SUPPORT_SIZE)
	for variant in ["KitHP", "KitEXP"]:
		theme.set_type_variation(variant, "ProgressBar")
		var fill := bar(T.HP if variant == "KitHP" else T.EXP)
		theme.set_stylebox("fill", variant, fill)
	for state in ["tab_unselected", "tab_selected", "tab_hovered", "tab_disabled", "tab_focus"]:
		theme.set_stylebox(state, "TabBar", {"tab_unselected":normal, "tab_selected":accent, "tab_hovered":hover, "tab_disabled":disabled, "tab_focus":focus}[state])
	theme.set_font("font", "TabBar", F.font_for_role(F.ROLE_BUTTON))
	theme.set_font_size("font_size", "TabBar", T.BUTTON_SIZE)
	for state in ["font_selected_color", "font_unselected_color", "font_hovered_color"]: theme.set_color(state, "TabBar", T.TEXT)
	theme.set_color("font_disabled_color", "TabBar", T.TEXT_MUTED)
	theme.set_constant("h_separation", "TabBar", T.SPACE_SMALL)
	theme.set_constant("icon_max_width", "TabBar", T.ICON_SIZE)
	theme.set_stylebox("panel", "TooltipPanel", flat(T.BACKGROUND, T.HIGHLIGHT))
	theme.set_color("font_color", "TooltipLabel", T.TEXT)
	theme.set_font("font", "TooltipLabel", F.font_for_role(F.ROLE_BODY))
	theme.set_font_size("font_size", "TooltipLabel", T.TOOLTIP_SIZE)
	theme.set_stylebox("panel", "ScrollContainer", flat(Color.TRANSPARENT, Color.TRANSPARENT, 0, Vector2.ZERO))
	var empty_image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	empty_image.fill(Color.TRANSPARENT)
	var empty_icon := ImageTexture.create_from_image(empty_image)
	for type in ["HScrollBar", "VScrollBar"]:
		theme.set_stylebox("scroll", type, flat(T.BACKGROUND, Color.TRANSPARENT, T.RADIUS_SMALL, Vector2(4, 4)))
		for state in ["grabber", "grabber_highlight", "grabber_pressed"]: theme.set_stylebox(state, type, flat(T.BORDER, T.ACCENT, T.RADIUS_SMALL, Vector2(4, 4)))
		for state in ["increment", "decrement", "increment_highlight", "decrement_highlight", "increment_pressed", "decrement_pressed"]: theme.set_icon(state, type, empty_icon)
		theme.set_constant("minimum_grab_thickness", type, T.SPACE_SMALL)
	theme.set_stylebox("panel", "PopupMenu", panel)
	theme.set_stylebox("hover", "PopupMenu", hover)
	theme.set_font("font", "PopupMenu", F.font_for_role(F.ROLE_BODY))
	theme.set_font_size("font_size", "PopupMenu", T.BUTTON_SIZE)
	theme.set_color("font_color", "PopupMenu", T.TEXT)
	theme.set_color("font_hover_color", "PopupMenu", T.TEXT)
	theme.set_color("font_disabled_color", "PopupMenu", T.TEXT_MUTED)
	theme.set_icon("arrow", "OptionButton", Icons.get_icon("chevron"))
	for key in ["checked", "radio_checked", "checked_disabled", "radio_checked_disabled"]: theme.set_icon(key, "CheckBox", Icons.get_icon("check"))
	for key in ["unchecked", "radio_unchecked", "unchecked_disabled", "radio_unchecked_disabled"]: theme.set_icon(key, "CheckBox", Icons.get_icon("unchecked"))
	var error := ResourceSaver.save(theme, "res://assets/ui/kit/StyleB.tres")
	print("BUILD_THEME ", error_string(error))
	quit(0 if error == OK else 1)
