class_name V20TitleEntryPanel
extends Control

signal new_session_requested(profile_id: String)
signal continue_requested

const PROFILE_IDS := ["v20_tactician"]
const PROFILE_LABELS := {"v20_story": "쉬움", "v20_tactician": "보통", "v20_overlord": "어려움"}
const PROFILE_DETAILS := {
	"v20_story": {
		"summary": "건설 14 · 명령 4/4 · 목표 1 · 예고 35% 길게",
		"description": "넉넉한 자원으로 한 목표씩 배치를 익힙니다."
	},
	"v20_tactician": {
		"summary": "건설 10 · 명령 3/3 · 목표 2 · 예고 표준",
		"description": "배치와 명령을 함께 운용하는 표준 난이도입니다."
	},
	"v20_overlord": {
		"summary": "건설 8 · 명령 2/3 · 목표 3 · 예고 25% 짧게",
		"description": "빠듯한 자원으로 세 목표를 동시에 지킵니다."
	}
}
const UIFontScript = preload("res://scripts/ui/UIFont.gd")

var selected_profile_id := "v20_tactician"
var save_inspection: Dictionary = {}


func setup(profile_id: String, inspection: Dictionary) -> void:
	selected_profile_id = profile_id if profile_id in PROFILE_IDS else "v20_tactician"
	save_inspection = inspection.duplicate(true)
	_rebuild()


func _ready() -> void:
	if save_inspection.is_empty():
		_rebuild()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var back := Panel.new()
	back.name = "Panel"
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.add_theme_stylebox_override("panel", _style(Color("#100e16f5"), Color("#e8bb58"), 2))
	add_child(back)
	_label(back, "2.0 PC 버티컬 슬라이스", Vector2(20, 12), Vector2(size.x - 40, 26), 18, Color("#ffe4a0"), UIFontScript.ROLE_EMPHASIS)
	_label(back, "DAY 1~5 · 고정 침입로·구역 배치·전술 명령", Vector2(20, 38), Vector2(size.x - 40, 18), 11, Color("#bdb3c6"))
	var heading := _label(back, "DAY 1~5 검증 조건", Vector2(20, 64), Vector2(size.x - 40, 18), 12, Color("#e8bb58"), UIFontScript.ROLE_EMPHASIS)
	heading.name = "DifficultyHeading"
	var gap := 8.0
	var button_width := size.x - 40.0
	for index in range(PROFILE_IDS.size()):
		var profile_id: String = str(PROFILE_IDS[index])
		var button := _button(back, str(PROFILE_LABELS.get(profile_id, profile_id)), Rect2(20 + index * (button_width + gap), 84, button_width, 38), false)
		button.name = "Difficulty_%s" % profile_id
		if profile_id == selected_profile_id:
			button.add_theme_stylebox_override("normal", _style(Color("#3a2b4b"), Color("#ffe4a0"), 2))
		button.pressed.connect(_select_profile.bind(profile_id))
	var detail: Dictionary = PROFILE_DETAILS.get(selected_profile_id, PROFILE_DETAILS["v20_tactician"])
	var summary := _label(back, str(detail.get("summary", "")), Vector2(20, 128), Vector2(size.x - 40, 18), 11, Color("#ffe4a0"), UIFontScript.ROLE_EMPHASIS)
	summary.name = "DifficultySummary"
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var description := _label(back, str(detail.get("description", "")), Vector2(20, 148), Vector2(size.x - 40, 20), 11, Color("#cfc5d7"))
	description.name = "DifficultyDescription"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var start := _button(back, "보통 고정 조건으로 시작", Rect2(20, 178, size.x - 40, 44), true)
	start.name = "V20NewSessionButton"
	start.pressed.connect(func(): new_session_requested.emit(selected_profile_id))
	var valid_save := str(save_inspection.get("status", "")) == "valid"
	var continue_label := "2.0 이어하기"
	if valid_save:
		continue_label += " · DAY %d" % int(save_inspection.get("summary", {}).get("day", 1))
	var continue_button := _button(back, continue_label, Rect2(20, 230, size.x - 40, 38), false)
	continue_button.name = "V20ContinueButton"
	continue_button.disabled = not valid_save
	continue_button.pressed.connect(func(): continue_requested.emit())
	_label(back, "1.2 저장과 완전히 분리됩니다.", Vector2(20, size.y - 24), Vector2(size.x - 40, 16), 10, Color("#9e92aa"))


func _select_profile(profile_id: String) -> void:
	selected_profile_id = profile_id
	_rebuild()


func _label(parent: Control, value: String, position: Vector2, label_size: Vector2, font_size: int, color: Color, role: String = UIFontScript.ROLE_BODY) -> Label:
	var label := Label.new()
	label.text = value
	label.position = position
	label.size = label_size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UIFontScript.font_for_role(role))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _button(parent: Control, value: String, rect: Rect2, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#ffe4a0") if primary else Color("#f3eadc"))
	button.add_theme_stylebox_override("normal", _style(Color("#2b2037") if primary else Color("#17131f"), Color("#e8bb58") if primary else Color("#5f536a"), 2 if primary else 1))
	button.add_theme_stylebox_override("hover", _style(Color("#3a2b4b"), Color("#ffe4a0"), 2))
	parent.add_child(button)
	return button


func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(7)
	return style
