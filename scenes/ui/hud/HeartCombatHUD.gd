extends Control
class_name HeartCombatHUD

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
const HEART_NAMES := {
	"heart_stonebone": "석골 심장",
	"heart_hungry_maw": "포식 심장",
	"heart_dream_lantern": "몽등 심장"
}
const HEART_ACCENTS := {
	"heart_stonebone": Color("#c5a46a"),
	"heart_hungry_maw": Color("#d86b63"),
	"heart_dream_lantern": Color("#a887e8")
}

var state_provider: Callable
var content_root: Control
var name_label: Label
var detail_label: Label
var charge_label: Label
var charge_fill: ColorRect
var frame: Panel
var last_signature := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_fit_design_canvas)
	_build()
	call_deferred("_fit_design_canvas")


func setup(provider: Callable) -> void:
	state_provider = provider
	_refresh_state()


func _process(_delta: float) -> void:
	_refresh_state()


func _build() -> void:
	content_root = Control.new()
	content_root.name = "HeartHUDDesignCanvas"
	content_root.size = DESIGN_SIZE
	content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content_root)
	frame = Panel.new()
	frame.name = "HeartHUDFrame"
	frame.position = Vector2(734, 70)
	frame.size = Vector2(452, 82)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(frame)
	name_label = _label(frame, Rect2(18, 12, 170, 25), 16, Color("#fff3dc"), UIFontScript.ROLE_EMPHASIS)
	charge_label = _label(frame, Rect2(326, 12, 108, 25), 14, Color("#fff3dc"), UIFontScript.ROLE_EMPHASIS)
	charge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	detail_label = _label(frame, Rect2(18, 42, 416, 24), 14, Color("#d8cfdc"), UIFontScript.ROLE_BODY)
	var track := ColorRect.new()
	track.position = Vector2(188, 20)
	track.size = Vector2(128, 9)
	track.color = Color("#17101e")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(track)
	charge_fill = ColorRect.new()
	charge_fill.position = Vector2.ZERO
	charge_fill.size = Vector2.ZERO
	charge_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(charge_fill)
	_fit_design_canvas()


func _refresh_state() -> void:
	if frame == null or not state_provider.is_valid():
		visible = false
		return
	var state = state_provider.call()
	if not (state is Dictionary):
		visible = false
		return
	var heart: Dictionary = state.get("heart", {})
	var heart_id := str(heart.get("heart_id", ""))
	visible = heart_id != "" and bool(heart.get("awakened", false))
	if not visible:
		return
	var signature := JSON.stringify(heart)
	if signature == last_signature:
		return
	last_signature = signature
	var charge := clampi(int(heart.get("charge", 0)), 0, 100)
	var disabled := bool(heart.get("disabled_this_battle", false))
	var used := bool(heart.get("active_used_this_battle", false))
	var remaining := float(heart.get("active_remaining", 0.0))
	var accent: Color = HEART_ACCENTS.get(heart_id, Color("#c68aa8"))
	if disabled:
		accent = Color("#77717d")
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0b0810ee")
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	frame.add_theme_stylebox_override("panel", style)
	name_label.text = str(HEART_NAMES.get(heart_id, heart_id))
	charge_label.text = "%d / 100" % charge
	charge_fill.color = accent
	charge_fill.size = Vector2(128.0 * float(charge) / 100.0, 9)
	if disabled:
		detail_label.text = "심장실 무력화 · 패시브와 액티브 정지"
	elif remaining > 0.0:
		detail_label.text = "%s · %.1f초" % [_active_name(heart_id), remaining]
	elif used:
		detail_label.text = "이번 전투 액티브 사용 완료"
	elif charge >= 100:
		detail_label.text = "H키로 액티브 사용 가능"
	else:
		detail_label.text = _charge_hint(heart_id)


func _active_name(heart_id: String) -> String:
	match heart_id:
		"heart_hungry_maw": return "삼키는 복도 활성"
		"heart_dream_lantern": return "가짜 복도 활성"
		_: return "성 전체 버티기 활성"


func _charge_hint(heart_id: String) -> String:
	match heart_id:
		"heart_hungry_maw": return "피해·마무리·포식 파동으로 충전"
		"heart_dream_lantern": return "기술·회복·첫 제어·목표 변경으로 충전"
		_: return "피해 흡수·시설 피해·수리로 충전"


func _label(parent: Control, rect: Rect2, font_size: int, color: Color, role: String) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UIFontScript.font_for_role(role))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _fit_design_canvas() -> void:
	if content_root == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	content_root.scale = Vector2.ONE * factor
	content_root.position = (size - DESIGN_SIZE * factor) * 0.5
