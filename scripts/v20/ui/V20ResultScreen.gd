class_name V20ResultScreen
extends Control

signal action_requested(action_id: String)

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const COLOR_BG := Color("#0a080ef5")
const COLOR_PANEL := Color("#14101af5")
const COLOR_TEXT := Color("#f4ecdf")
const COLOR_MUTED := Color("#aaa1b2")
const COLOR_GOLD := Color("#e7b955")
const COLOR_GOLD_BRIGHT := Color("#ffe2a0")
const COLOR_PURPLE := Color("#a980dc")
const COLOR_DANGER := Color("#e56772")
const COLOR_GREEN := Color("#58c997")
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
	var margin := clampf(size.x * 0.022, 20.0, 42.0)
	var gap := clampf(size.x * 0.012, 12.0, 22.0)
	var win := bool(result_data.get("win", false))
	var backdrop := _panel(Rect2(Vector2.ZERO, size), COLOR_BG, Color("#00000000"), "ResultBackdrop")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var header_h := clampf(size.y * 0.105, 66.0, 94.0)
	var header := _child_panel(backdrop, Rect2(margin, margin, size.x - margin * 2.0, header_h), Color("#100d15f8"), COLOR_GOLD if win else COLOR_DANGER, 1, "ResultHeader")
	_label(header, "DAY %02d  %s" % [day, "방어 성공" if win else "방어 실패"], Vector2(22, 4), Vector2(header.size.x * 0.64, header.size.y - 8), 28, COLOR_GOLD_BRIGHT if win else Color("#ffaaa1"), UIFontScript.ROLE_EMPHASIS)
	_label(header, "결과보다 원인을 먼저 봅니다.", Vector2(header.size.x * 0.48, 4), Vector2(header.size.x * 0.32, header.size.y - 8), 12, COLOR_MUTED, UIFontScript.ROLE_BODY)
	var damage := maxi(0, int(result_data.get("metrics", {}).get("demon_lord_hp_max", 1500)) - int(result_data.get("metrics", {}).get("demon_lord_hp", 1500)))
	var damage_badge := _child_panel(header, Rect2(header.size.x - 206, 12, 184, header.size.y - 24), Color("#11271f") if damage == 0 else Color("#30171b"), COLOR_GREEN if damage == 0 else COLOR_DANGER, 1, "DamageBadge")
	_label(damage_badge, "왕좌 피해  %d" % damage, Vector2.ZERO, damage_badge.size, 14, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS)

	var cards_y := margin + header_h + gap
	var cards_h := clampf(size.y * 0.245, 156.0, 214.0)
	var card_w := (size.x - margin * 2.0 - gap * 2.0) / 3.0
	var v20: Dictionary = result_data.get("v20", {})
	_build_story_card(backdrop, Rect2(margin, cards_y, card_w, cards_h), "01  막아낸 핵심" if win else "01  무너진 핵심", str(v20.get("cause", "결산 원인을 확인하세요.")), "경로 방어" if win else "원인 확인", COLOR_GOLD if win else COLOR_DANGER)
	_build_story_card(backdrop, Rect2(margin + card_w + gap, cards_y, card_w, cards_h), "02  전투에서 잘한 것", str(v20.get("highlight", _highlight_text())), _highlight_badge(), COLOR_PURPLE)
	_build_story_card(backdrop, Rect2(margin + (card_w + gap) * 2.0, cards_y, card_w, cards_h), "03  다음 날 주의", str(v20.get("guidance", "배치를 한 곳만 조정하세요.")), "다음 행동", COLOR_DANGER)

	var dock_h := clampf(size.y * 0.105, 62.0, 84.0)
	var dock_y := size.y - margin - dock_h
	var detail_y := cards_y + cards_h + gap
	var detail_h := dock_y - gap - detail_y
	var summary_w := clampf(size.x * 0.285, 300.0, 430.0)
	var ledger := _child_panel(backdrop, Rect2(margin, detail_y, size.x - margin * 2.0 - summary_w - gap, detail_h), COLOR_PANEL, Color("#51475b"), 1, "ContributionLedger")
	_label(ledger, "이번 방어의 기여", Vector2(20, 10), Vector2(ledger.size.x - 40, 28), 16, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS)
	var metrics: Dictionary = result_data.get("metrics", {})
	var rows := [
		["전투 시간", "%.1f초" % float(metrics.get("combat_time", 0.0))],
		["몬스터 생존", "%d / %d" % [int(metrics.get("alive_monsters", 0)), int(metrics.get("total_monsters", 0))]],
		["시설 방어", "무력화 %d회" % int(metrics.get("facility_disables", 0))],
		["전술 명령", "%d점 사용" % int(metrics.get("v20_command_points_spent", 0))]
	]
	var row_h := maxf(28.0, (ledger.size.y - 48.0) / float(rows.size()))
	for index in range(rows.size()):
		var row: Array = rows[index]
		if index % 2 == 0:
			var stripe := ColorRect.new()
			stripe.position = Vector2(14, 44 + index * row_h)
			stripe.size = Vector2(ledger.size.x - 28, row_h)
			stripe.color = Color("#20192588")
			stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ledger.add_child(stripe)
		_label(ledger, str(row[0]), Vector2(24, 44 + index * row_h), Vector2(ledger.size.x * 0.55, row_h), 12, COLOR_MUTED, UIFontScript.ROLE_BODY)
		_label(ledger, str(row[1]), Vector2(ledger.size.x * 0.58, 44 + index * row_h), Vector2(ledger.size.x * 0.36, row_h), 14, COLOR_GOLD_BRIGHT, UIFontScript.ROLE_EMPHASIS)
	var run_panel := _child_panel(backdrop, Rect2(size.x - margin - summary_w, detail_y, summary_w, detail_h), Color("#17121ff5"), COLOR_PURPLE, 1, "RunSummary")
	_label(run_panel, "이번 수비 방식", Vector2(20, 12), Vector2(run_panel.size.x - 40, 22), 11, COLOR_PURPLE, UIFontScript.ROLE_EMPHASIS)
	_label(run_panel, _play_style_title(), Vector2(20, 37), Vector2(run_panel.size.x - 40, 32), 21, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS)
	_label(run_panel, _play_style_summary(), Vector2(20, 72), Vector2(run_panel.size.x - 40, maxf(42.0, run_panel.size.y - 114)), 12, COLOR_MUTED, UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART)

	var dock := _child_panel(backdrop, Rect2(margin, dock_y, size.x - margin * 2.0, dock_h), Color("#100d15f8"), Color("#765b31"), 1, "ResultActionDock")
	if not win:
		var edit := _result_action_button(dock, "배치 수정", Rect2(dock.size.x * 0.50, 8, dock.size.x * 0.23 - 8, dock.size.y - 16), "retry_edit", false)
		edit.name = "V20RetryEditButton"
		var same := _result_action_button(dock, "같은 배치 재도전  →", Rect2(dock.size.x * 0.73, 8, dock.size.x * 0.27 - 8, dock.size.y - 16), "retry_same", true)
		same.name = "V20RetrySameButton"
		_label(dock, "두 경로 모두 전투 직전 HP·마나·명령·쿨다운·시설 충전·seed/RNG를 먼저 복원합니다.", Vector2(20, 5), Vector2(dock.size.x * 0.46, dock.size.y - 10), 11, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
	else:
		var action_id := "complete" if day >= 5 else "next_day"
		var action_label := "DAY 1~5 완료" if day >= 5 else "다음 침입 확인"
		var button := _result_action_button(dock, action_label + "  →", Rect2(dock.size.x * 0.54, 8, dock.size.x * 0.44 - 8, dock.size.y - 16), action_id, true)
		button.name = "V20ResultActionButton"
		_label(dock, "직전 배치는 유지하고 전투 피해·소모·성장은 다음 DAY에 이월하지 않습니다.", Vector2(20, 5), Vector2(dock.size.x * 0.49, dock.size.y - 10), 11, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)


func _build_story_card(parent: Control, rect: Rect2, eyebrow: String, body: String, badge: String, accent: Color) -> void:
	var card := _child_panel(parent, rect, COLOR_PANEL, accent, 1, "StoryCard_%s" % badge.replace(" ", "_"))
	_label(card, eyebrow, Vector2(20, 12), Vector2(card.size.x - 40, 24), 13, accent, UIFontScript.ROLE_EMPHASIS)
	_label(card, body, Vector2(20, 44), Vector2(card.size.x - 40, card.size.y - 92), 16, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS, TextServer.AUTOWRAP_WORD_SMART)
	var badge_panel := _child_panel(card, Rect2(20, card.size.y - 39, minf(180.0, card.size.x - 40), 25), Color(accent, 0.10), accent, 1, "Badge")
	_label(badge_panel, badge, Vector2(10, 1), Vector2(badge_panel.size.x - 20, 23), 10, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS, TextServer.AUTOWRAP_OFF, HORIZONTAL_ALIGNMENT_CENTER)


func _result_action_button(parent: Control, value: String, rect: Rect2, action_id: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	button.add_theme_font_size_override("font_size", 16 if not primary else 18)
	button.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT if primary else COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _style(Color("#31243b") if primary else Color("#18131f"), COLOR_GOLD if primary else Color("#5f536a"), 2 if primary else 1))
	button.add_theme_stylebox_override("hover", _style(Color("#45314f"), COLOR_GOLD_BRIGHT, 2))
	button.pressed.connect(func(): action_requested.emit(action_id))
	parent.add_child(button)
	return button


func _highlight_text() -> String:
	var metrics: Dictionary = result_data.get("metrics", {})
	var alive := int(metrics.get("alive_monsters", 0))
	var total := maxi(1, int(metrics.get("total_monsters", 0)))
	if alive == total:
		return "몬스터 전원이 끝까지 전선을 지켜 다음 방어 준비를 온전히 남겼습니다."
	if int(metrics.get("facilities_saved", 0)) > 0:
		return "공병의 시설 무력화를 막아 핵심 방어선을 지켜냈습니다."
	if int(metrics.get("v20_command_points_spent", 0)) > 0:
		return "전술 명령으로 위험 구간의 교전을 끊어냈습니다."
	return "초기 배치가 첫 교전까지 안정적으로 버텼습니다."


func _highlight_badge() -> String:
	var metrics: Dictionary = result_data.get("metrics", {})
	if int(metrics.get("alive_monsters", 0)) >= maxi(1, int(metrics.get("total_monsters", 0))):
		return "전원 생존"
	if int(metrics.get("facilities_saved", 0)) > 0:
		return "시설 방어"
	return "명령 대응"


func _play_style_title() -> String:
	var metrics: Dictionary = result_data.get("metrics", {})
	if int(metrics.get("v20_command_points_spent", 0)) >= 2:
		return "지휘형 수비"
	if int(metrics.get("facility_disables", 0)) == 0:
		return "요새형 수비"
	return "버티기 수비"


func _play_style_summary() -> String:
	var metrics: Dictionary = result_data.get("metrics", {})
	if int(metrics.get("v20_command_points_spent", 0)) >= 2:
		return "명령력을 적극적으로 사용해 위험한 순간에 전선을 재정렬했습니다."
	if int(metrics.get("facility_disables", 0)) == 0:
		return "시설과 몬스터의 구역 배치로 적의 속도를 늦추는 데 강했습니다."
	return "손실을 감수하고 마지막 방어선까지 시간을 벌었습니다."


func _panel(rect: Rect2, fill: Color, border: Color, node_name: String = "Panel") -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _style(fill, border, 2))
	add_child(panel)
	return panel


func _child_panel(parent: Control, rect: Rect2, fill: Color, border: Color, width: int = 1, node_name: String = "Panel") -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _style(fill, border, width))
	parent.add_child(panel)
	return panel


func _label(parent: Control, value: String, position: Vector2, label_size: Vector2, font_size: int, color: Color, role: String = UIFontScript.ROLE_BODY, wrap: int = TextServer.AUTOWRAP_OFF, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = value
	label.position = position
	label.size = label_size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = align
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
	if fill.a > 0.1:
		style.shadow_color = Color("#00000066")
		style.shadow_size = 4
	return style
