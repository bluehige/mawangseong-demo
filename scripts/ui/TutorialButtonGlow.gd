extends NinePatchRect
## All light is generated raster art; the engine only assembles and pulses opacity.
const ART = preload("res://assets/ui/v131/tutorial_glow.png")
var pulse: Tween
var token := ""

static func attach(target: Control, step: String = "") -> void:
	if target == null or target.has_node("TutorialButtonGlow"): return
	if target.has_meta("tutorial_glow_dismissed") and target.get_meta("tutorial_glow_dismissed") == step: return
	var glow := new()
	glow.token = step
	glow.name = "TutorialButtonGlow"
	target.add_child(glow)
	if target is BaseButton: target.pressed.connect(glow.dismiss,CONNECT_ONE_SHOT)
	target.gui_input.connect(glow.on_input)

func _ready() -> void:
	texture = ART
	draw_center = false
	patch_margin_left = 45; patch_margin_right = 45
	patch_margin_top = 35; patch_margin_bottom = 35
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = -12; offset_top = -12; offset_right = 12; offset_bottom = 12
	pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	pulse.tween_property(self,"modulate:a",0.30,0.6)
	pulse.tween_property(self,"modulate:a",1.0,0.6)

func on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: dismiss()

func dismiss() -> void:
	get_parent().set_meta("tutorial_glow_dismissed",token)
	if pulse != null: pulse.kill()
	hide()
