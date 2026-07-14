extends Control
class_name CampaignModeSelectionScreen

signal mode_selected(mode_id: String)
signal canceled

const CampaignModeServiceScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
const MODE_RECTS := {
	"front_chronicle": Rect2(176, 300, 748, 520),
	"council_season": Rect2(996, 300, 748, 520)
}

var profile: Dictionary = {}
var catalog: Dictionary = {}
var cycle_index := 1
var allow_cancel := true
var content_root: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_fit_design_canvas)
	if content_root == null:
		_build()
	call_deferred("_fit_design_canvas")


func setup(profile_value: Dictionary, catalog_value: Dictionary, current_cycle: int, cancel_enabled: bool = true) -> void:
	profile = CampaignModeServiceScript.normalize_profile(profile_value)
	catalog = catalog_value.duplicate(true)
	cycle_index = maxi(1, current_cycle)
	allow_cancel = cancel_enabled
	if is_node_ready():
		_build()


func layout_rects_for_viewport(viewport_size: Vector2) -> Dictionary:
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * factor) * 0.5
	var result := {}
	for mode_id in MODE_RECTS:
		var source: Rect2 = MODE_RECTS[mode_id]
		result[mode_id] = Rect2(offset + source.position * factor, source.size * factor)
	return result


func _build() -> void:
	if content_root != null and is_instance_valid(content_root):
		content_root.queue_free()
	content_root = Control.new()
	content_root.name = "DesignCanvas"
	content_root.size = DESIGN_SIZE
	add_child(content_root)

	var backdrop := TextureRect.new()
	backdrop.name = "CampaignModeBackdrop"
	backdrop.size = DESIGN_SIZE
	backdrop.texture = load("res://assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(backdrop)
	var shade := ColorRect.new()
	shade.size = DESIGN_SIZE
	shade.color = Color("#07040ce8")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(shade)

	_add_label(content_root, "다음 30일을 선택하세요", Rect2(176, 68, 1100, 68), 44, Color("#fff3d2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root, "%d회차 · 선택한 회차의 규칙과 기록은 서로 분리됩니다." % cycle_index, Rect2(180, 140, 1120, 38), 20, Color("#c9bfd2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	_add_label(content_root, "CAMPAIGN MODE", Rect2(1320, 82, 424, 40), 18, Color("#cfa9ee"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root, "전선은 기존 경로를 이어가고, 의회는 DAY 1에서 새 규칙으로 시작합니다.", Rect2(176, 214, 1568, 36), 18, Color("#d7cedf"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)

	_build_mode(CampaignModeServiceScript.FRONT_MODE_ID, "기존 전선과 심장", ["레온·셀렌·로만 전선", "마왕성 심장과 합동 기억", "다음 회차 DAY 4 준비"])
	_build_mode(CampaignModeServiceScript.COUNCIL_MODE_ID, "지역과 표결의 새 회차", ["5개 지역 중 3개 선택", "전초기지·상층·왕관", "신규 의회 회차 DAY 1"])

	_add_label(content_root, "모드 선택은 새 회차 저장에 기록됩니다. 진행 중 v4 회차에는 적용되지 않습니다.", Rect2(396, 874, 1128, 34), 17, Color("#bcb2c5"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)
	var cancel_button := _add_button(content_root, "뒤로가기", Rect2(760, 942, 400, 64), Callable(self, "_cancel"), false)
	cancel_button.name = "CampaignModeCancelButton"
	cancel_button.visible = allow_cancel

	modulate.a = 0.0
	content_root.position.y = 12.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(content_root, "position:y", 0.0, 0.22)
	_fit_design_canvas()


func _build_mode(mode_id: String, kicker: String, features: Array[String]) -> void:
	var definition: Dictionary = catalog.get(mode_id, {})
	var reason := CampaignModeServiceScript.lock_reason(profile, mode_id, catalog)
	var locked := reason != ""
	var rect: Rect2 = MODE_RECTS[mode_id]
	var accent := Color(str(definition.get("accent", "#d6aa4f")))
	var button := Button.new()
	button.name = "CampaignModeButton_%s" % mode_id
	button.position = rect.position
	button.size = rect.size
	button.text = ""
	button.disabled = locked
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", _style(Color("#17101ff2"), accent.darkened(0.2), 2, 14))
	button.add_theme_stylebox_override("hover", _style(Color("#281a35f8"), accent.lightened(0.18), 4, 14))
	button.add_theme_stylebox_override("pressed", _style(Color("#0d0913fa"), Color("#fff0b0"), 4, 14))
	button.add_theme_stylebox_override("disabled", _style(Color("#100d16ec"), Color("#55465e"), 2, 14))
	button.pressed.connect(_choose_mode.bind(mode_id))
	button.tooltip_text = reason if locked else str(definition.get("summary", ""))
	content_root.add_child(button)
	var state_text := "LOCKED · 잠김" if locked else "AVAILABLE · 선택 가능"
	_add_label(button, state_text, Rect2(38, 34, 620, 28), 15, Color("#81768a") if locked else accent.lightened(0.18), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(button, str(definition.get("display_name", mode_id)), Rect2(38, 84, 664, 58), 34, Color("#938b99") if locked else Color("#fff6df"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(button, kicker, Rect2(38, 148, 664, 36), 20, Color("#aaa1ae") if locked else accent, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(button, str(definition.get("summary", "")), Rect2(38, 202, 664, 76), 18, Color("#918996") if locked else Color("#d8d0df"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	var divider := ColorRect.new()
	divider.position = Vector2(38, 304)
	divider.size = Vector2(672, 1)
	divider.color = Color("#5d4c67")
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(divider)
	for index in features.size():
		_add_label(button, "—  %s" % features[index], Rect2(42, 328 + index * 46, 650, 34), 17, Color("#88808d") if locked else Color("#e5dce8"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	var footer := reason if locked else "이 회차로 시작"
	_add_label(button, footer, Rect2(38, 470, 672, 30), 15, Color("#786f80") if locked else accent.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)


func _choose_mode(mode_id: String) -> void:
	mode_selected.emit(mode_id)


func _cancel() -> void:
	canceled.emit()


func _fit_design_canvas() -> void:
	if content_root == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	content_root.scale = Vector2.ONE * factor
	content_root.position = (size - DESIGN_SIZE * factor) * 0.5


func _add_label(parent: Control, text_value: String, rect: Rect2, font_size: int, color: Color, alignment: HorizontalAlignment, role: String) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UIFontScript.font_for_role(role))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _add_button(parent: Control, text_value: String, rect: Rect2, callback: Callable, disabled: bool) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text_value
	button.disabled = disabled
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#fff2cf"))
	button.add_theme_stylebox_override("normal", _style(Color("#251730f4"), Color("#9b6a27"), 2, 8))
	button.add_theme_stylebox_override("hover", _style(Color("#3a2348f8"), Color("#ffd36a"), 2, 8))
	button.add_theme_stylebox_override("pressed", _style(Color("#150d1df8"), Color("#fff0b0"), 2, 8))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
