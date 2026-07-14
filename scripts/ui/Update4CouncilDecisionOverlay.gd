extends Control
class_name Update4CouncilDecisionOverlay

const CouncilVoteScript = preload("res://scripts/systems/council/CouncilVoteLedger.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")

signal vote_confirmed(agenda_id: String, choice_id: String)
signal crown_confirmed(instance_id: String, crown_id: String)
signal crown_declined(option_id: String)
signal final_declaration_confirmed(choice_id: String)


func setup(action_id: String, day: int, active_run: Dictionary, catalogs: Dictionary, crown_candidates: Array = [], cycle_seed: int = 1) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 480
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color("#030207d9")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	var panel := PanelContainer.new()
	panel.name = "DecisionPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-600, -410)
	panel.size = Vector2(1200, 820)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#0b0811fa"), Color("#d2ad55"), 3))
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 34)
	for side in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	margin.add_child(stack)
	_add_label(stack, "DAY %02d · 마계 의회 필수 결정" % day, 30, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	if action_id == "council_vote":
		_build_vote(stack, day, active_run, catalogs, cycle_seed)
	elif action_id == "council_final_declaration":
		_build_final_declaration(stack, active_run, catalogs)
	else:
		_build_crown(stack, active_run, catalogs, crown_candidates)


func _build_vote(parent: VBoxContainer, day: int, active_run: Dictionary, catalogs: Dictionary, cycle_seed: int) -> void:
	_add_label(parent, "한 안건과 입장을 선택하세요. 예상 표는 공개되며 부결되어도 회차는 계속됩니다.", 18, Color("#cfc5d7"), HORIZONTAL_ALIGNMENT_CENTER)
	var agenda_catalog: Dictionary = catalogs.get("council_agendas", {})
	var rival_catalog: Dictionary = catalogs.get("rival_lords", {})
	var agenda_ids := CouncilVoteScript.seeded_agendas_for_day(agenda_catalog, day, active_run, cycle_seed, 3)
	for agenda_id in agenda_ids:
		var agenda: Dictionary = agenda_catalog.get(agenda_id, {})
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 184)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_theme_stylebox_override("panel", _panel_style(Color("#15101df2"), Color("#55465f"), 1))
		parent.add_child(card)
		var card_margin := MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 20)
		card_margin.add_theme_constant_override("margin_right", 20)
		card_margin.add_theme_constant_override("margin_top", 14)
		card_margin.add_theme_constant_override("margin_bottom", 14)
		card.add_child(card_margin)
		var card_stack := VBoxContainer.new()
		card_stack.add_theme_constant_override("separation", 8)
		card_margin.add_child(card_stack)
		_add_label(card_stack, str(agenda.get("display_name", agenda_id)), 22, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT)
		_add_label(card_stack, "이점: %s  ·  대가: %s" % [str(agenda.get("benefit", "")), str(agenda.get("cost", ""))], 16, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT)
		var choices := HBoxContainer.new()
		choices.add_theme_constant_override("separation", 12)
		card_stack.add_child(choices)
		for choice_id in CouncilVoteScript.VALID_CHOICES:
			var forecast := CouncilVoteScript.forecast(active_run, agenda_id, agenda_catalog, rival_catalog, choice_id)
			var tally: Dictionary = forecast.get("tally", {})
			var button := Button.new()
			button.custom_minimum_size = Vector2(345, 64)
			button.text = "%s  ·  %s 예상  (%d/%d/%d)" % [
				_choice_label(choice_id),
				"통과" if bool(forecast.get("passed", false)) else "부결",
				int(tally.get("approve", 0)), int(tally.get("amend", 0)), int(tally.get("reject", 0))
			]
			_style_button(button, 16)
			button.pressed.connect(_emit_vote.bind(agenda_id, choice_id))
			choices.add_child(button)


func _build_crown(parent: VBoxContainer, active_run: Dictionary, catalogs: Dictionary, candidates: Array) -> void:
	var council: Dictionary = active_run.get("council_season", {})
	_add_label(parent, "오래 성장한 몬스터 한 마리를 왕관 진화시키거나, 인장 대체 보상을 선택하세요.", 18, Color("#cfc5d7"), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(parent, "의회 인장 %d · 대체 인장 %d" % [int(council.get("council_seals", 0)), int(council.get("alternative_seal_resource", 0))], 20, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER)
	var crown_catalog: Dictionary = catalogs.get("crown_evolutions", {})
	var candidate_box := VBoxContainer.new()
	candidate_box.add_theme_constant_override("separation", 10)
	parent.add_child(candidate_box)
	if candidates.is_empty():
		_add_label(candidate_box, "현재 조건을 충족한 왕관 후보가 없습니다. 대체 보상으로 이번 회차를 계속할 수 있습니다.", 18, Color("#e6a36f"), HORIZONTAL_ALIGNMENT_CENTER)
	for candidate_value in candidates:
		if not (candidate_value is Dictionary):
			continue
		var candidate: Dictionary = candidate_value
		var crown_id := str(candidate.get("crown_form_id", ""))
		var crown: Dictionary = crown_catalog.get(crown_id, {})
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 70)
		button.text = "%s  ·  %s\n%s" % [str(candidate.get("display_name", crown_id)), str(candidate.get("instance_id", "")), str(crown.get("weakness_text", ""))]
		_style_button(button, 18)
		button.pressed.connect(_emit_crown.bind(str(candidate.get("instance_id", "")), crown_id))
		candidate_box.add_child(button)
	var spacer := HSeparator.new()
	parent.add_child(spacer)
	_add_label(parent, "왕관을 쓰지 않는 선택", 20, Color("#f0cf73"), HORIZONTAL_ALIGNMENT_CENTER)
	var declines := HBoxContainer.new()
	declines.alignment = BoxContainer.ALIGNMENT_CENTER
	declines.add_theme_constant_override("separation", 14)
	parent.add_child(declines)
	var labels := {
		"outpost_reinforcement": "전초기지 최종 보강",
		"heart_extra_charge": "DAY 30 심장 추가 충전",
		"council_support_token": "의회 지원 토큰"
	}
	for option_id in labels.keys():
		var button := Button.new()
		button.custom_minimum_size = Vector2(330, 64)
		button.text = str(labels[option_id])
		_style_button(button, 17)
		button.pressed.connect(_emit_decline.bind(str(option_id)))
		declines.add_child(button)


func _build_final_declaration(parent: VBoxContainer, active_run: Dictionary, catalogs: Dictionary) -> void:
	var council: Dictionary = active_run.get("council_season", {})
	var rival_id := str(council.get("final_representative_id", ""))
	var rival_name := str(catalogs.get("rival_lords", {}).get(rival_id, {}).get("display_name", rival_id))
	_add_label(parent, "DAY 30 대표 %s와의 최종전을 앞두고 회기 뒤에 남길 약속을 선택하세요." % rival_name, 20, Color("#cfc5d7"), HORIZONTAL_ALIGNMENT_CENTER)
	var choices := [
		{"id": "council_commitment", "title": "의회 의석을 지킨다", "summary": "표와 인장, 세 경쟁 마왕과의 관계를 공식 기록으로 남긴다."},
		{"id": "delegate_the_crown", "title": "왕관의 공을 부하에게 돌린다", "summary": "왕관을 쓴 몬스터와 동료들의 기여를 최우선으로 기록한다."},
		{"id": "keep_outpost_after_council", "title": "전초기지를 집으로 남긴다", "summary": "두 차례 습격을 견딘 성 밖 보루를 회기 뒤에도 유지한다."},
		{"id": "reject_council_authority", "title": "의회의 권위를 거부한다", "summary": "허가보다 서로의 성을 직접 지키는 독립 노선을 선언한다."}
	]
	for choice in choices:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 118)
		button.text = "%s\n%s" % [str(choice.title), str(choice.summary)]
		_style_button(button, 19)
		button.pressed.connect(_emit_final_declaration.bind(str(choice.id)))
		parent.add_child(button)


func _emit_vote(agenda_id: String, choice_id: String) -> void:
	vote_confirmed.emit(agenda_id, choice_id)


func _emit_crown(instance_id: String, crown_id: String) -> void:
	crown_confirmed.emit(instance_id, crown_id)


func _emit_decline(option_id: String) -> void:
	crown_declined.emit(option_id)


func _emit_final_declaration(choice_id: String) -> void:
	final_declaration_confirmed.emit(choice_id)


func _add_label(parent: Control, text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = alignment
	label.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BODY))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _style_button(button: Button, font_size: int) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("#f7efe1"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("#21182af5"), Color("#6c5779"), 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#352342fa"), Color("#ffd36a"), 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#4a2e58fa"), Color("#ffe38a"), 2))


func _panel_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _choice_label(choice_id: String) -> String:
	return {"approve": "찬성", "amend": "수정안", "reject": "반대"}.get(choice_id, choice_id)
