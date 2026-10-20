extends Node2D
## Background only; parent Container still owns all input and layout.
const T = preload("res://scripts/ui/kit/UIKitTokens.gd")
const ShaderSource = preload("res://assets/ui/kit/surface.gdshader")
var _material := ShaderMaterial.new()
var _extent := Vector2.ZERO
var _key := ""
var _white: GradientTexture2D
var preview_state := ""

func _init() -> void:
	show_behind_parent = true
	_material.shader = ShaderSource
	material = _material
	_white = GradientTexture2D.new()
	_white.width = 1
	_white.height = 1
	_white.gradient = Gradient.new()
	_white.gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE])

func sync(parent: Control, emphasized: bool = false) -> void:
	var scale: float = parent.theme.get_meta("kit_geometry_scale", 1.0)
	var state := preview_state
	if parent is BaseButton and state.is_empty():
		state = "disabled" if parent.disabled else ("pressed" if parent.is_pressed() else ("hover" if parent.is_hovered() else "normal"))
	var primary: bool = parent.theme_type_variation == "KitPrimary"
	var danger: bool = parent.theme_type_variation == "KitDanger"
	var chip: bool = parent.theme_type_variation == "KitChipPanel"
	var corner: float = parent.get_meta("kit_surface_radius",48.0 if chip else (T.RADIUS if parent is Button else T.RADIUS_LARGE))
	var key := "%s/%s/%s/%s/%s/%s/%s" % [state, primary, danger, emphasized, chip, scale, corner]
	if _extent != parent.size:
		_extent = parent.size
		_material.set_shader_parameter("surface_size", _extent)
		queue_redraw()
	if key == _key: return
	_key = key
	var top := T.PANEL_RAISED
	var bottom := T.BACKGROUND
	var border := T.BORDER
	var glow := 0.18
	if primary:
		top = T.GRADIENT_TOP; bottom = T.GRADIENT_BOTTOM; border = T.PRIMARY_RIM; glow = 0.8
	if danger:
		top = T.DANGER_TOP; bottom = T.DANGER_BOTTOM; border = T.DANGER
	if state == "hover":
		top = top.lightened(0.12); border = T.ACCENT; glow = 0.5
	elif state == "pressed" and not parent.get_meta("kit_selected", false):
		top = top.darkened(0.2); bottom = bottom.darkened(0.12)
	elif state == "disabled":
		top = T.DISABLED; bottom = T.DISABLED_BOTTOM; border = T.DISABLED_RIM; glow = 0.05
	if emphasized: border = T.EMPHASIS_RIM
	_material.set_shader_parameter("top_color", top)
	_material.set_shader_parameter("bottom_color", bottom)
	_material.set_shader_parameter("rim_color", border)
	_material.set_shader_parameter("glow_color",T.ACCENT)
	_material.set_shader_parameter("glow_strength", glow)
	_material.set_shader_parameter("radius", corner * scale)
	_material.set_shader_parameter("halo", 12.0 * scale)
	queue_redraw()

func _draw() -> void:
	var halo: float = _material.get_shader_parameter("halo")
	draw_texture_rect(_white, Rect2(-Vector2.ONE * halo, _extent + Vector2.ONE * halo * 2), false)
