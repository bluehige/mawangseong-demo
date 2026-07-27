class_name V20UITheme
extends RefCounted

const UIFontScript = preload("res://scripts/ui/UIFont.gd")

const COLOR_VOID := Color("#08070dcc")
const COLOR_PANEL := Color("#100e16f2")
const COLOR_PANEL_STRONG := Color("#0d0b12f7")
const COLOR_PANEL_SOFT := Color("#17131fe8")
const COLOR_LINE := Color("#5f536a")
const COLOR_GOLD := Color("#e8bb58")
const COLOR_GOLD_BRIGHT := Color("#ffe4a0")
const COLOR_TEXT := Color("#f3eadc")
const COLOR_MUTED := Color("#bdb3c6")
const COLOR_DANGER := Color("#e56a72")
const COLOR_ROUTE := Color("#9e7bd1")
const COLOR_GREEN := Color("#58c997")

const FONT_HERO := 30
const FONT_TITLE := 20
const FONT_VALUE := 18
const FONT_BUTTON := 15
const FONT_BODY := 13
const FONT_SUPPORT := 11

const SCREEN_MARGIN := 20.0
const PANEL_GAP := 12.0
const BUTTON_MIN_HEIGHT := 44.0
const PANEL_RADIUS := 8.0


static func responsive_scale(viewport_size: Vector2) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	return clampf(minf(viewport_size.x / 1280.0, viewport_size.y / 720.0), 0.85, 1.35)


static func scaled_font_size(base_size: int, viewport_size: Vector2) -> int:
	return maxi(FONT_SUPPORT, int(round(float(base_size) * responsive_scale(viewport_size))))


static func font_for_role(role: String):
	return UIFontScript.font_for_role(role)


static func style(fill: Color = COLOR_PANEL, border: Color = COLOR_LINE, width: int = 1, radius: float = PANEL_RADIUS, shadow: bool = true) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(width)
	result.corner_radius_top_left = int(radius)
	result.corner_radius_top_right = int(radius)
	result.corner_radius_bottom_left = int(radius)
	result.corner_radius_bottom_right = int(radius)
	if shadow:
		result.shadow_color = Color("#00000066")
		result.shadow_size = 4
	return result


static func apply_button_style(button: Button, primary: bool) -> void:
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, BUTTON_MIN_HEIGHT)
	button.add_theme_font_override("font", font_for_role(UIFontScript.ROLE_BUTTON))
	button.add_theme_font_size_override("font_size", FONT_BUTTON)
	button.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT if primary else COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_GOLD_BRIGHT)
	button.add_theme_color_override("font_focus_color", COLOR_GOLD_BRIGHT)
	button.add_theme_color_override("font_disabled_color", Color("#746d79"))
	button.add_theme_stylebox_override("normal", style(Color("#30243b") if primary else Color("#18131ff2"), COLOR_GOLD if primary else COLOR_LINE, 2 if primary else 1))
	button.add_theme_stylebox_override("hover", style(Color("#3d2d4c"), COLOR_GOLD_BRIGHT if primary else COLOR_ROUTE, 2))
	button.add_theme_stylebox_override("pressed", style(Color("#4b3323"), COLOR_GOLD_BRIGHT, 2))
	button.add_theme_stylebox_override("focus", style(Color("#2a2038bb"), COLOR_GOLD_BRIGHT, 2))
	button.add_theme_stylebox_override("disabled", style(Color("#121017dd"), Color("#37313d"), 1))


static func debug_build_badge() -> String:
	var source_sha := OS.get_environment("V20_SOURCE_SHA").strip_edges()
	var build_flavor := OS.get_environment("V20_BUILD_FLAVOR").strip_edges()
	if source_sha == "":
		source_sha = "working-tree"
	elif source_sha.length() > 12:
		source_sha = source_sha.left(12)
	if build_flavor == "":
		build_flavor = "local-debug"
	return "DEBUG · %s · %s" % [source_sha, build_flavor]
