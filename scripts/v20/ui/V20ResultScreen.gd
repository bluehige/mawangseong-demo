class_name V20ResultScreen
extends Control

signal action_requested(action_id: String)

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
var result_data: Dictionary = {}
var day := 1


func setup(result: Dictionary, day_value: int) -> void:
	result_data = result.duplicate(true)
	day = day_value
	_rebuild()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_rebuild)


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if size.x < 100.0 or result_data.is_empty():
		return
	var margin := clampf(size.x * 0.04, 28.0, 72.0)
	var gap := clampf(size.x * 0.025, 20.0, 44.0)
	var content_y := clampf(size.y * 0.20, 120.0, 190.0)
	var content_h := size.y - content_y - clampf(size.y * 0.18, 110.0, 170.0)
	var panel_w := (size.x - margin * 2.0 - gap) * 0.5
	var win := bool(result_data.get("win", false))
	_label(self, "DAY %02d · %s" % [day, "방어 성공" if win else "방어 실패"], Vector2(margin, 42), Vector2(size.x - margin * 2.0, 60), 36, Color("#ffe4a0") if win else Color("#ff9b8f"), UIFontScript.ROLE_EMPHASIS)
	_label(self, "배치를 지우지 않고 원인부터 확인합니다.", Vector2(margin, 100), Vector2(size.x - margin * 2.0, 30), 16, Color("#bdb3c6"))
	var cause_panel := _panel(Rect2(margin, content_y, panel_w, content_h), Color("#100e16f2"), Color("#e56a72") if not win else Color("#e8bb58"))
	_label(cause_panel, "무슨 일이 있었나", Vector2(24, 20), Vector2(panel_w - 48, 30), 19, Color("#ffe4a0"), UIFontScript.ROLE_EMPHASIS)
	_label(cause_panel, str(result_data.get("v20", {}).get("cause", "결산 원인을 확인하세요.")), Vector2(24, 66), Vector2(panel_w - 48, 92), 22, Color("#f3eadc"), UIFontScript.ROLE_EMPHASIS, TextServer.AUTOWRAP_WORD_SMART)
	var metrics: Dictionary = result_data.get("metrics", {})
	var metric_text := "전투 %.1f초 · 생존 %d/%d\n왕좌 HP %d · 보물 손실 %d\n시설 무력화 %d회" % [float(metrics.get("combat_time", 0.0)), int(metrics.get("alive_monsters", 0)), int(metrics.get("total_monsters", 0)), int(metrics.get("demon_lord_hp", 0)), int(metrics.get("treasure_gold_stolen", 0)), int(metrics.get("facility_disables", 0))]
	_label(cause_panel, metric_text, Vector2(24, 178), Vector2(panel_w - 48, 100), 16, Color("#bdb3c6"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART)
	var action_panel := _panel(Rect2(margin + panel_w + gap, content_y, panel_w, content_h), Color("#100e16f2"), Color("#9e7bd1"))
	_label(action_panel, "다음에 바꿀 한 가지", Vector2(24, 20), Vector2(panel_w - 48, 30), 19, Color("#cdb2ff"), UIFontScript.ROLE_EMPHASIS)
	_label(action_panel, str(result_data.get("v20", {}).get("guidance", "배치를 한 곳만 조정하세요.")), Vector2(24, 66), Vector2(panel_w - 48, 92), 22, Color("#f3eadc"), UIFontScript.ROLE_EMPHASIS, TextServer.AUTOWRAP_WORD_SMART)
	_label(action_panel, "유지됨\n✓ 시설 배치\n✓ 몬스터 배치\n✓ 난이도와 경제 상태", Vector2(24, 178), Vector2(panel_w - 48, 120), 16, Color("#bdb3c6"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART)
	var action_id := "retry" if not win else ("complete" if day >= 5 else "next_day")
	var action_label := "같은 배치로 재도전" if not win else ("DAY 1~5 완료" if day >= 5 else "DAY %02d 준비" % (day + 1))
	var button := Button.new()
	button.name = "V20ResultActionButton"
	button.text = action_label
	button.position = Vector2(size.x * 0.28, size.y - 94)
	button.size = Vector2(size.x * 0.44, 58)
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#ffe4a0"))
	button.add_theme_stylebox_override("normal", _style(Color("#2b2037"), Color("#e8bb58"), 2))
	button.pressed.connect(func(): action_requested.emit(action_id))
	add_child(button)


func _panel(rect: Rect2, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _style(fill, border, 2))
	add_child(panel)
	return panel


func _label(parent: Control, value: String, position: Vector2, label_size: Vector2, font_size: int, color: Color, role: String = UIFontScript.ROLE_BODY, wrap: int = TextServer.AUTOWRAP_OFF) -> Label:
	var label := Label.new()
	label.text = value
	label.position = position
	label.size = label_size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = wrap
	label.add_theme_font_override("font", UIFontScript.font_for_role(role))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(8)
	return style
