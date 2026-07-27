class_name V20TitleEntryPanel
extends Control

signal new_session_requested(profile_id: String)
signal continue_requested

const PROFILE_ID := "v20_tactician"
const PRIMARY_ACTION_GROUP := "v20_title_primary_action"
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const UITheme = preload("res://scripts/v20/ui/V20UITheme.gd")

var selected_profile_id := PROFILE_ID
var save_inspection: Dictionary = {}


func setup(_profile_id: String, inspection: Dictionary) -> void:
	selected_profile_id = PROFILE_ID
	save_inspection = inspection.duplicate(true)
	_rebuild()


func _ready() -> void:
	if save_inspection.is_empty():
		_rebuild()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if size.x < 10.0 or size.y < 10.0:
		return
	var back := Panel.new()
	back.name = "Panel"
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.add_theme_stylebox_override("panel", UITheme.style(Color("#0b0910f2"), UITheme.COLOR_GOLD, 1, 10.0))
	add_child(back)

	if OS.is_debug_build():
		var debug_badge := _label(back, UITheme.debug_build_badge(), Vector2(16, 8), Vector2(size.x - 32, 16), 9, Color("#8f8499"), UIFontScript.ROLE_BODY)
		debug_badge.name = "DebugBuildBadge"
		debug_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var title := _label(back, "마왕성", Vector2(24, 28), Vector2(size.x - 48, 42), UITheme.FONT_HERO, UITheme.COLOR_GOLD_BRIGHT, UIFontScript.ROLE_EMPHASIS)
	title.name = "GameTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := _label(back, "DAY 1~5 전술 방어 테스트", Vector2(24, 70), Vector2(size.x - 48, 24), UITheme.FONT_BODY, UITheme.COLOR_MUTED)
	subtitle.name = "V20TestSubtitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var start := _button(back, "새 테스트 시작", Rect2(24, 112, size.x - 48, 52), true)
	start.name = "V20NewSessionButton"
	start.add_to_group(PRIMARY_ACTION_GROUP)
	start.pressed.connect(func(): new_session_requested.emit(PROFILE_ID))

	var valid_save := str(save_inspection.get("status", "")) == "valid"
	if valid_save:
		var continue_label := "이어하기 · DAY %d" % int(save_inspection.get("summary", {}).get("day", 1))
		var continue_button := _button(back, continue_label, Rect2(24, 176, size.x - 48, 44), false)
		continue_button.name = "V20ContinueButton"
		continue_button.pressed.connect(func(): continue_requested.emit())
	else:
		var continue_hint := _label(back, "저장된 테스트가 생기면 이어하기가 표시됩니다.", Vector2(24, 178), Vector2(size.x - 48, 40), UITheme.FONT_SUPPORT, Color("#92879c"))
		continue_hint.name = "ContinueUnavailableHint"
		continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var save_notice := _label(back, "기존 1.2 저장과 분리되어 안전하게 테스트합니다.", Vector2(24, size.y - 46), Vector2(size.x - 48, 22), UITheme.FONT_SUPPORT, Color("#a99dae"))
	save_notice.name = "SaveIsolationNotice"
	save_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	back.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(back, "modulate", Color.WHITE, 0.18)


func _label(parent: Control, value: String, position: Vector2, label_size: Vector2, font_size: int, color: Color, role: String = UIFontScript.ROLE_BODY) -> Label:
	var label := Label.new()
	label.text = value
	label.position = position
	label.size = label_size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UITheme.font_for_role(role))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Control, value: String, rect: Rect2, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	UITheme.apply_button_style(button, primary)
	button.add_theme_font_size_override("font_size", UITheme.FONT_BUTTON)
	parent.add_child(button)
	return button
