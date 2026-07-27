class_name V20ResultScreen
extends Control

signal action_requested(action_id: String)

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const UITheme = preload("res://scripts/v20/ui/V20UITheme.gd")

const COLOR_BG := Color("#09070df7")
const COLOR_PANEL := UITheme.COLOR_PANEL
const COLOR_TEXT := UITheme.COLOR_TEXT
const COLOR_MUTED := UITheme.COLOR_MUTED
const COLOR_GOLD := UITheme.COLOR_GOLD
const COLOR_GOLD_BRIGHT := UITheme.COLOR_GOLD_BRIGHT
const COLOR_PURPLE := UITheme.COLOR_ROUTE
const COLOR_DANGER := UITheme.COLOR_DANGER
const COLOR_GREEN := UITheme.COLOR_GREEN

var result_data: Dictionary = {}
var day := 1
var details_open := false
var _rebuild_queued := false


func setup(result: Dictionary, day_value: int) -> void:
	result_data = result.duplicate(true)
	day = day_value
	details_open = false
	_rebuild()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_queue_rebuild)


func _queue_rebuild() -> void:
	if _rebuild_queued or not is_node_ready() or result_data.is_empty():
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _rebuild() -> void:
	_rebuild_queued = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if size.x < 100.0 or size.y < 100.0 or result_data.is_empty():
		return
	var margin := clampf(size.x * 0.015625, 18.0, 30.0)
	var gap := clampf(size.x * 0.009375, 10.0, 18.0)
	var win := bool(result_data.get("win", false))
	var backdrop := _panel(Rect2(Vector2.ZERO, size), COLOR_BG, Color("#00000000"), "ResultBackdrop")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var header_h := clampf(size.y * 0.105, 72.0, 92.0)
	var header := _child_panel(backdrop, Rect2(margin, margin, size.x - margin * 2.0, header_h), UITheme.COLOR_PANEL_STRONG, COLOR_GOLD if win else COLOR_DANGER, 2, "ResultHeader")
	var title := _label(header, "방어 성공" if win else "방어 실패", Vector2(20, 3), Vector2(header.size.x * 0.48, header.size.y - 8), UITheme.FONT_HERO, COLOR_GOLD_BRIGHT if win else Color("#ffaaa1"), UIFontScript.ROLE_EMPHASIS)
	title.name = "ResultTitleValue"
	var day_label := _label(header, "DAY %02d" % day, Vector2(header.size.x * 0.48, 4), Vector2(100, header.size.y - 8), UITheme.FONT_BUTTON, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
	day_label.name = "ResultDayValue"
	var header_prompt := "다음 침입 전에 유지할 점을 확인하세요." if win else "원인을 확인하고 배치를 먼저 고치세요."
	var prompt_label := _label(header, header_prompt, Vector2(header.size.x * 0.58, 4), Vector2(header.size.x * 0.40 - 20, header.size.y - 8), UITheme.FONT_BODY, COLOR_MUTED, UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, HORIZONTAL_ALIGNMENT_RIGHT)
	prompt_label.name = "ResultHeaderPrompt"

	var dock_h := clampf(size.y * 0.11, 78.0, 96.0)
	var dock_y := size.y - margin - dock_h
	var content_y := margin + header_h + gap
	var content_h := dock_y - gap - content_y
	var content_w := size.x - margin * 2.0
	var summary_h := clampf(content_h * 0.54, 260.0, 310.0) if details_open else content_h
	var summary := _child_panel(backdrop, Rect2(margin, content_y, content_w, summary_h), COLOR_PANEL, Color("#51475b"), 1, "OutcomeSummary")
	_build_primary_summary(summary, details_open)
	if details_open:
		var details_y := content_y + summary_h + gap
		var details_h := dock_y - gap - details_y
		var details := _child_panel(backdrop, Rect2(margin, details_y, content_w, details_h), UITheme.COLOR_PANEL_SOFT, COLOR_PURPLE, 1, "ResultDetails")
		_build_details(details)
	var dock := _child_panel(backdrop, Rect2(margin, dock_y, content_w, dock_h), UITheme.COLOR_PANEL_STRONG, Color("#765b31"), 1, "ResultActionDock")
	_build_actions(dock, win)


func _build_primary_summary(parent: Control, compact: bool) -> void:
	var cause_color := COLOR_GOLD if bool(result_data.get("win", false)) else COLOR_DANGER
	_label(parent, "핵심 원인", Vector2(22, 12), Vector2(parent.size.x - 44, 24), UITheme.FONT_SUPPORT, cause_color, UIFontScript.ROLE_EMPHASIS)
	var cause_h := 58.0 if compact else 104.0
	var cause := _label(parent, _primary_cause(), Vector2(22, 34), Vector2(parent.size.x - 44, cause_h), UITheme.FONT_TITLE if compact else UITheme.FONT_HERO, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS, TextServer.AUTOWRAP_WORD_SMART)
	cause.name = "PrimaryCauseValue"
	var notes_y := 101.0 if compact else 156.0
	var notes_h := 70.0 if compact else 112.0
	var note_gap := 10.0
	var note_w := (parent.size.x - 44.0 - note_gap) * 0.5
	var highlight_panel := _child_panel(parent, Rect2(22, notes_y, note_w, notes_h), Color("#102119dd"), COLOR_GREEN, 1, "HighlightSummary")
	_label(highlight_panel, "잘한 점", Vector2(14, 5), Vector2(90, 20), UITheme.FONT_SUPPORT, COLOR_GREEN, UIFontScript.ROLE_EMPHASIS)
	var highlight := _label(highlight_panel, _primary_highlight(), Vector2(14, 24), Vector2(highlight_panel.size.x - 28, highlight_panel.size.y - 30), UITheme.FONT_BODY, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS, TextServer.AUTOWRAP_WORD_SMART)
	highlight.name = "PrimaryHighlightValue"
	var guidance_panel := _child_panel(parent, Rect2(22 + note_w + note_gap, notes_y, note_w, notes_h), Color("#27171cdd") if not bool(result_data.get("win", false)) else Color("#211c12dd"), COLOR_DANGER if not bool(result_data.get("win", false)) else COLOR_GOLD, 1, "GuidanceSummary")
	_label(guidance_panel, "다음에 바꿀 점" if not bool(result_data.get("win", false)) else "다음 침입 준비", Vector2(14, 5), Vector2(130, 20), UITheme.FONT_SUPPORT, COLOR_DANGER if not bool(result_data.get("win", false)) else COLOR_GOLD, UIFontScript.ROLE_EMPHASIS)
	var guidance := _label(guidance_panel, _primary_guidance(), Vector2(14, 24), Vector2(guidance_panel.size.x - 28, guidance_panel.size.y - 30), UITheme.FONT_BODY, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS, TextServer.AUTOWRAP_WORD_SMART)
	guidance.name = "PrimaryGuidanceValue"
	_build_primary_metrics(parent, compact)


func _build_primary_metrics(parent: Control, compact: bool) -> void:
	var strip_h := 72.0 if compact else 88.0
	var strip_y := parent.size.y - strip_h - 16.0
	var gap := 8.0
	var card_w := (parent.size.x - 44.0 - gap * 2.0) / 3.0
	var metrics := [
		{"label": "왕좌 피해", "value": str(_throne_damage()), "accent": COLOR_DANGER if _throne_damage() > 0 else COLOR_GREEN},
		{"label": "첫 교전", "value": _first_engagement_label(), "accent": COLOR_PURPLE},
		{"label": "정산", "value": _signed_value(_net_income()), "accent": COLOR_GOLD if _net_income() >= 0 else COLOR_DANGER}
	]
	for index in range(metrics.size()):
		var metric: Dictionary = metrics[index]
		var card := _child_panel(parent, Rect2(22 + index * (card_w + gap), strip_y, card_w, strip_h), Color("#17131ee8"), metric.get("accent", COLOR_GOLD), 1, "PrimaryMetric_%d" % index)
		_label(card, str(metric.get("label", "지표")), Vector2(14, 5), Vector2(card.size.x - 28, 20), UITheme.FONT_SUPPORT, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
		var value := _label(card, str(metric.get("value", "—")), Vector2(14, 24), Vector2(card.size.x - 28, card.size.y - 30), UITheme.FONT_VALUE, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS)
		value.name = "MetricValue"


func _build_details(parent: Control) -> void:
	_label(parent, "상세 전투 기록", Vector2(18, 5), Vector2(parent.size.x - 36, 24), UITheme.FONT_BUTTON, COLOR_PURPLE, UIFontScript.ROLE_EMPHASIS)
	var columns := _detail_columns()
	var column_gap := 12.0
	var column_w := (parent.size.x - 36.0 - column_gap) * 0.5
	for column_index in range(2):
		var rows: Array = columns[column_index]
		var column_x := 18.0 + column_index * (column_w + column_gap)
		var row_h := maxf(30.0, (parent.size.y - 38.0) / maxf(1.0, rows.size()))
		for row_index in range(rows.size()):
			var row: Dictionary = rows[row_index]
			var row_y := 33.0 + row_index * row_h
			if row_index % 2 == 0:
				var stripe := ColorRect.new()
				stripe.position = Vector2(column_x, row_y)
				stripe.size = Vector2(column_w, row_h)
				stripe.color = Color("#211a2788")
				stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
				parent.add_child(stripe)
			_label(parent, str(row.get("label", "정보")), Vector2(column_x + 10, row_y), Vector2(column_w * 0.40, row_h), UITheme.FONT_SUPPORT, COLOR_MUTED, UIFontScript.ROLE_BODY)
			_label(parent, str(row.get("value", "—")), Vector2(column_x + column_w * 0.42, row_y), Vector2(column_w * 0.54 - 10, row_h), UITheme.FONT_BODY, COLOR_GOLD_BRIGHT, UIFontScript.ROLE_EMPHASIS, TextServer.AUTOWRAP_WORD_SMART, HORIZONTAL_ALIGNMENT_RIGHT)


func _build_actions(parent: Control, win: bool) -> void:
	var toggle := _result_action_button(parent, "상세 접기" if details_open else "상세 보기", Rect2(10, 9, 150, parent.size.y - 18), "", false)
	toggle.name = "V20ResultDetailsToggle"
	toggle.pressed.connect(_toggle_details)
	_label(parent, "다음 행동", Vector2(176, 5), Vector2(parent.size.x * 0.25, parent.size.y - 10), UITheme.FONT_SUPPORT, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
	if not win:
		var same_w := clampf(parent.size.x * 0.22, 220.0, 300.0)
		var edit_w := clampf(parent.size.x * 0.34, 340.0, 470.0)
		var same_x := parent.size.x - 10.0 - same_w
		var edit_x := same_x - 8.0 - edit_w
		var edit := _result_action_button(parent, "배치 수정  →", Rect2(edit_x, 9, edit_w, parent.size.y - 18), "retry_edit", true)
		edit.name = "V20RetryEditButton"
		var same := _result_action_button(parent, "같은 배치 재도전", Rect2(same_x, 9, same_w, parent.size.y - 18), "retry_same", false)
		same.name = "V20RetrySameButton"
	else:
		var action_id := "complete" if day >= 5 else "next_day"
		var action_label := "DAY 1~5 완료" if day >= 5 else "다음 침입 확인"
		var action_w := clampf(parent.size.x * 0.40, 400.0, 560.0)
		var button := _result_action_button(parent, action_label + "  →", Rect2(parent.size.x - action_w - 10, 9, action_w, parent.size.y - 18), action_id, true)
		button.name = "V20ResultActionButton"


func _toggle_details() -> void:
	details_open = not details_open
	_rebuild()


func _result_action_button(parent: Control, value: String, rect: Rect2, action_id: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	UITheme.apply_button_style(button, primary)
	button.add_theme_font_size_override("font_size", UITheme.FONT_VALUE if primary else UITheme.FONT_BUTTON)
	if action_id != "":
		button.pressed.connect(func(): action_requested.emit(action_id))
	parent.add_child(button)
	return button


func _primary_cause() -> String:
	var win := bool(result_data.get("win", false))
	var metrics := _metrics()
	var evidence := _evidence()
	var first_zone := _first_engagement_label()
	var hold_seconds := float(evidence.get("frontline_hold_seconds", 0.0))
	if win:
		if first_zone != "미발생":
			return "%s에서 첫 교전 · %.1f초 전선을 유지해 방어에 성공했습니다." % [first_zone, hold_seconds]
		if _throne_damage() == 0:
			return "왕좌 피해 없이 마지막 침입자까지 격퇴했습니다."
		return "왕좌 피해 %d에서 전선을 지키고 마지막 침입자를 격퇴했습니다." % _throne_damage()
	var required_failure := str(result_data.get("v20_required_objective_failure", ""))
	var gold_stolen := maxi(int(metrics.get("treasure_gold_stolen", 0)), int(evidence.get("gold_stolen", 0)))
	var disable_seconds := float(evidence.get("max_contiguous_facility_disabled_seconds", 0.0))
	var rear_seconds := float(evidence.get("rear_pressure_seconds", 0.0))
	var breaches := int(evidence.get("fallback_breaches", 0))
	var leaks := int(evidence.get("second_phase_leaks", 0))
	match required_failure:
		"protect_treasure":
			return "도둑이 금화 %d를 훔쳐 보물 방어 목표를 잃었습니다." % gold_stolen
		"keep_one_facility_active":
			return "핵심 시설이 %.1f초 연속 무력화되어 방어 효과가 끊겼습니다." % disable_seconds
		"break_rear_pressure":
			return "보호받는 후열의 압박이 %.1f초 이어져 필수 방어 목표를 놓쳤습니다." % rear_seconds
		"hold_fallback_line":
			return "왕좌 전실 돌파 %d건으로 마지막 후퇴선을 지키지 못했습니다." % breaches
		"stop_reinforcement_leaks":
			return "후속 증원 누수 %d건으로 두 번째 방어 구간을 놓쳤습니다." % leaks
	if gold_stolen > 0:
		return "도둑이 금화 %d를 훔쳐 보물 방어와 왕좌 방어가 흔들렸습니다." % gold_stolen
	if disable_seconds > 0.0:
		return "핵심 시설이 %.1f초 연속 무력화되어 전선 지원이 끊겼습니다." % disable_seconds
	if breaches + leaks > 0:
		return "왕좌 전실에 %d건의 돌파·누수가 발생했습니다." % (breaches + leaks)
	if _throne_damage() > 0:
		return "왕좌 피해 %d가 누적되어 방어선이 무너졌습니다." % _throne_damage()
	var hp := int(metrics.get("demon_lord_hp", 0))
	var hp_max := maxi(1, int(metrics.get("demon_lord_hp_max", _evidence().get("throne_max_hp", 1500))))
	return "왕좌 HP %d/%d에서 방어가 종료되었습니다." % [hp, hp_max]


func _primary_highlight() -> String:
	var metrics := _metrics()
	var evidence := _evidence()
	var facility_events := int(evidence.get("facility_effect_events", 0))
	var command_events: Array = evidence.get("command_events", [])
	var command_count := command_events.size()
	var alive := int(metrics.get("alive_monsters", 0))
	var total := maxi(1, int(metrics.get("total_monsters", 0)))
	if alive == total:
		return "몬스터 %d/%d 전원이 생존해 다음 방어의 기준을 남겼습니다." % [alive, total]
	if facility_events > 0:
		return "시설 효과 %d회가 실제 교전에 적용되어 전선을 보조했습니다." % facility_events
	if command_count > 0:
		return "전술 명령 %d회로 위험 구간에 즉시 대응했습니다." % command_count
	var monster_damage := int(evidence.get("monster_damage_total", 0))
	if monster_damage > 0:
		return "몬스터가 침입대에 실제 피해 %d를 기록했습니다." % monster_damage
	var existing := str(result_data.get("v20", {}).get("highlight", "")).strip_edges()
	return existing if existing != "" else "첫 교전 구역과 왕좌 피해 기록을 다음 배치의 기준으로 남겼습니다."


func _primary_guidance() -> String:
	if bool(result_data.get("win", false)):
		var existing_win := str(result_data.get("v20", {}).get("guidance", "")).strip_edges()
		return existing_win if existing_win != "" else "현재 배치를 유지하고 다음 침입 목표에 맞춰 한 곳만 조정하세요."
	var required_failure := str(result_data.get("v20_required_objective_failure", ""))
	match required_failure:
		"protect_treasure":
			return "보물 경로에 몬스터를 남기고 도둑 등장 때 집결 명령을 사용하세요."
		"keep_one_facility_active":
			return "시설을 한 구역에 몰지 말고 공병에게 집중 명령을 예약하세요."
		"break_rear_pressure":
			return "후열 사수를 먼저 노출시키고 집중 명령으로 보호를 끊으세요."
		"hold_fallback_line", "stop_reinforcement_leaks":
			return "왕좌 전실에 몬스터를 남기고 비상 후퇴 명령력을 보존하세요."
	var evidence := _evidence()
	if int(evidence.get("gold_stolen", 0)) > 0:
		return "보물 경로에 몬스터를 남기고 도둑 등장 때 집결 명령을 사용하세요."
	if float(evidence.get("max_contiguous_facility_disabled_seconds", 0.0)) > 0.0:
		return "시설을 분산하고 공병에게 집중 명령을 예약하세요."
	if int(evidence.get("fallback_breaches", 0)) + int(evidence.get("second_phase_leaks", 0)) > 0:
		return "왕좌 전실에 몬스터를 남기고 비상 후퇴 명령력을 보존하세요."
	var existing := str(result_data.get("v20", {}).get("guidance", "")).strip_edges()
	return existing if existing != "" else "첫 교전 구역을 한 단계 뒤로 옮겨 왕좌 앞에 후퇴선을 남기세요."


func _detail_columns() -> Array:
	var metrics := _metrics()
	var evidence := _evidence()
	var command_events: Array = evidence.get("command_events", [])
	var disabled_seconds := float(evidence.get("max_contiguous_facility_disabled_seconds", 0.0))
	var stolen := maxi(int(metrics.get("treasure_gold_stolen", 0)), int(evidence.get("gold_stolen", 0)))
	var leaks := int(evidence.get("fallback_breaches", 0)) + int(evidence.get("second_phase_leaks", 0))
	var failure_parts: Array[String] = []
	if stolen > 0:
		failure_parts.append("도난 %d" % stolen)
	if disabled_seconds > 0.0:
		failure_parts.append("무력화 %.1f초" % disabled_seconds)
	if leaks > 0:
		failure_parts.append("누수 %d" % leaks)
	if failure_parts.is_empty():
		failure_parts.append("기록 없음")
	var v20: Dictionary = result_data.get("v20", {})
	return [
		[
			{"label": "전투 시간", "value": "%.1f초" % float(metrics.get("combat_time", 0.0))},
			{"label": "첫 교전 구역", "value": _first_engagement_label()},
			{"label": "시설 기여", "value": "효과 %d회" % int(evidence.get("facility_effect_events", 0))},
			{"label": "몬스터 피해", "value": str(int(evidence.get("monster_damage_total", 0)))}
		],
		[
			{"label": "명령 사용", "value": "%d회 · %d점" % [command_events.size(), int(metrics.get("v20_command_points_spent", 0))]},
			{"label": "실패 지표", "value": " · ".join(failure_parts)},
			{"label": "몬스터 잔여 HP", "value": "%d/%d" % [int(evidence.get("monster_end_hp", metrics.get("remaining_monster_hp", 0))), int(evidence.get("monster_start_max_hp", metrics.get("total_monster_hp", 0)))]},
			{"label": "보상·수리·정산", "value": "%d · -%d · %s" % [int(v20.get("gross_income", 0)), int(v20.get("repair_cost", 0)), _signed_value(_net_income())]}
		]
	]


func _metrics() -> Dictionary:
	return result_data.get("metrics", {})


func _evidence() -> Dictionary:
	return _metrics().get("v20_evidence", {})


func _throne_damage() -> int:
	var evidence := _evidence()
	if evidence.has("throne_damage"):
		return maxi(0, int(evidence.get("throne_damage", 0)))
	var metrics := _metrics()
	var maximum := int(metrics.get("demon_lord_hp_max", 1500))
	return maxi(0, maximum - int(metrics.get("demon_lord_hp", maximum)))


func _first_engagement_label() -> String:
	var zone_id := str(_evidence().get("first_engagement_zone", ""))
	return str({
		"gate_outpost": "성문 전초",
		"spike_corridor": "가시 회랑",
		"central_battle_room": "중앙 전투실",
		"throne_anteroom": "왕좌 전실",
		"throne": "왕좌"
	}.get(zone_id, "미발생" if zone_id == "" else zone_id))


func _net_income() -> int:
	return int(result_data.get("v20", {}).get("net_income", 0))


func _signed_value(value: int) -> String:
	return "+%d" % value if value >= 0 else str(value)


func _panel(rect: Rect2, fill: Color, border: Color, node_name: String = "Panel") -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", UITheme.style(fill, border, 2))
	add_child(panel)
	return panel


func _child_panel(parent: Control, rect: Rect2, fill: Color, border: Color, width: int = 1, node_name: String = "Panel") -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", UITheme.style(fill, border, width))
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
	label.add_theme_font_override("font", UITheme.font_for_role(role))
	label.add_theme_font_size_override("font_size", UITheme.scaled_font_size(font_size, size))
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
