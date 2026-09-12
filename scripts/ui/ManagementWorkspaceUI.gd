extends RefCounted
const Constants = preload("res://scripts/core/Constants.gd")
const UIFont = preload("res://scripts/ui/UIFont.gd")
const Preview = preload("res://scripts/ui/FacilityPreview.gd")
const INK := Color("#17121f")
const LINE := Color("#67546e")
const PAPER := Color("#f4eadc")
const MUTED := Color("#c0b2c6")
const GOLD := Color("#e8bd76")
var root: Node
var hud

func setup(game: Node, controller) -> void:
	root = game
	hud = controller

func panel(rect: Rect2, id: String) -> Panel:
	var result: Panel = hud.panel(rect, INK, LINE, id, "flat")
	result.name = id
	result.mouse_filter = Control.MOUSE_FILTER_STOP
	return result

func copy(parent: Control, text: String, rect: Rect2, font_size: int = 22, color: Color = PAPER, id: String = "") -> Label:
	var label: Label = hud.label(parent, text, rect.position, rect.size, font_size, color, HORIZONTAL_ALIGNMENT_LEFT, id)
	if id != "":
		label.name = id
	label.set_meta("uiux_keep_font_size", true)
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = rect.size
	label.tooltip_text = text
	return label

func button(parent: Control, text: String, rect: Rect2, callback: Callable, id: String, grade: String = "utility") -> Button:
	var result: Button = hud.button(parent, text, rect, callback, 22, id, grade)
	result.focus_mode = Control.FOCUS_ALL
	result.add_theme_stylebox_override("focus", hud.flat_style(Color("#00000000"), GOLD, 3))
	return result

func build(model: Dictionary, pending_reason: String) -> void:
	root.build_placement.ensure_ghost()
	_tabs()
	match root.management_tool_tab:
		"build":
			if root.build_preview_room_id == "":
				_build_palette()
		"roster":
			root.management_scene._build_monster_roster_dock()
		"tactics":
			_tactics(model)
	_footer(model)
	if root.management_context_drawer_open and not root.build_pick_mode:
		if pending_reason != "":
			var required_ui = load("res://scripts/ui/RequiredPreparationUI.gd").new()
			required_ui.setup(root, hud)
			required_ui.build_required(model, pending_reason)
		else:
			_inspector()
	# Settings and intrusion data stay reachable above the map.
	var top := panel(Rect2(24, 86, 292, 52), "ManagementQuickActions")
	button(top, "침입 정보", Rect2(6, 4, 176, 44), Callable(root, "_open_intrusion_brief"), "OpenIntrusionBriefButton")
	button(top, "설정", Rect2(190, 4, 96, 44), Callable(root, "_open_settings_screen"), "ManagementSettingsButton")

	if root.ui_layer.find_child("CampaignNotice", true, false) != null:
		return
	# This read-only snapshot never initializes a campaign seed or spends resources.
	var snapshot: Dictionary = root.combat_scene.build_precombat_snapshot(false)
	var groups: Array[String] = []
	for group in snapshot.get("enemy_groups", []):
		groups.append("%s %d" % [str(group.get("display_name", "적")), int(group.get("count", 0))])
	var brief := "침입 %d명 · %s" % [snapshot.get("schedule", []).size(), " / ".join(groups)]
	if bool(root._campaign_day_info().get("management_only", false)):
		brief = "오늘은 관리일 · 필수 준비를 마치면 다음 날로 진행"
	var summary := panel(Rect2(328, 86, 1170, 52), "ManagementIntrusionSummary")
	var summary_label := copy(summary, brief, Rect2(12, 4, 1146, 44), 20, MUTED)
	summary_label.max_lines_visible = 1
	summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	summary_label.tooltip_text = brief

func _tabs() -> void:
	var tabs := panel(Rect2(24, 758, 1872, 52), "ManagementToolTabs")
	var index := 0
	for entry in [["build", "건설"], ["roster", "수비대"], ["tactics", "전술"]]:
		var b := button(tabs, entry[1], Rect2(8 + index * 178, 4, 166, 44), Callable(root, "_set_management_tool_tab").bind(entry[0]), "ManagementTab_%s" % entry[0], "tactical")
		if root.management_tool_tab == entry[0]:
			hud.apply_button_state(b, "selected")
		index += 1
	var help := "방을 선택하면 상태와 가능한 행동이 열립니다."
	if root.management_tool_tab == "build":
		help = "건물을 끌어 놓기  →  비용·효과 검토  →  확정    |    클릭·방향키로도 배치"
	elif root.management_tool_tab == "roster":
		help = "몬스터를 방으로 끌어 배치    |    짧게 누른 뒤 방 클릭"
	copy(tabs, help, Rect2(560, 4, 1110, 44), 21, MUTED)
	if root.management_tool_tab == "roster":
		button(tabs, "몬스터 성장", Rect2(1664, 4, 200, 44), Callable(root, "_open_monster_screen"), "MonsterManagementButton")

func _build_palette() -> void:
	var dock := panel(Rect2(24, 816, 1872, 156), "BuildingToolbox")
	var scroll := ScrollContainer.new()
	scroll.name = "BuildingCardScroll"
	scroll.position = Vector2(10, 6)
	scroll.size = Vector2(1852, 144)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dock.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	scroll.add_child(row)
	for id_value in root.FACILITY_CHOICES:
		var id := str(id_value)
		var definition: Dictionary = root._facility_definition(id)
		var unlocked: bool = root._facility_unlocked(id)
		var affordable := GameState.can_pay(definition.get("cost", {}))
		var card := button(row, "", Rect2(0, 0, 338, 128), Callable(root, "_set_build_facility").bind(id), "FacilityCard_%s" % id, "tactical")
		card.custom_minimum_size = Vector2(338, 128)
		card.set_meta("facility_id", id)
		card.disabled = not unlocked or not affordable
		card.mouse_default_cursor_shape = Control.CURSOR_DRAG if not card.disabled else Control.CURSOR_FORBIDDEN
		card.tooltip_text = "%s\n%s\n%s" % [definition.get("effect_summary", ""), definition.get("recommend_summary", ""), "다음 성 단계에서 해금" if not unlocked else ("비용 부족" if not affordable else "드래그 또는 클릭으로 위치를 선택합니다.")]
		card.gui_input.connect(Callable(root.build_placement, "card_input").bind(id, card))
		var preview := Preview.new()
		preview.game = root
		preview.facility_id = id
		preview.position = Vector2(8, 2)
		preview.size = Vector2(152, 96)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(preview)
		copy(card, str(definition.get("display_name", id)), Rect2(166, 4, 164, 32), 22)
		copy(card, str(definition.get("role_title", definition.get("role_summary", ""))), Rect2(166, 36, 164, 54), 19, MUTED)
		var status: String = root._cost_label(definition.get("cost", {}))
		if not unlocked:
			status = "잠김 · 다음 성 단계에서 해금"
		elif not affordable:
			status = "비용 부족 · " + status
		copy(card, status, Rect2(12, 94, 314, 30), 19, GOLD if unlocked and affordable else Color("#e39b9f"))
		if id == root.build_pick_facility_id:
			hud.apply_button_state(card, "selected")

func _footer(model: Dictionary) -> void:
	if root.build_pick_mode and root.build_preview_room_id != "":
		_review_bar()
		return
	var bar := panel(Rect2(24, 982, 1872, 86), "ManagementPrimaryBar")
	if root.build_pick_mode:
		var assessment: Dictionary = root._evaluate_facility_placement(root.build_preview_room_id, root.build_pick_facility_id)
		var title: String = root._build_preview_summary()
		if root.build_preview_room_id != "":
			title += "  ·  " + str(root._facility_cost_label(root.build_pick_facility_id))
		copy(bar, title, Rect2(18, 4, 1254, 32), 23, GOLD, "BuildReviewSummary")
		var definition: Dictionary = root._facility_definition(root.build_pick_facility_id)
		var detail := str(definition.get("effect_summary", "시설 카드를 선택하세요."))
		var warnings: Array = assessment.get("warnings", [])
		if not warnings.is_empty():
			detail += " · " + " / ".join(warnings)
		elif root.build_preview_room_id != "":
			detail += " · " + str(root._build_preview_route_line())
		else:
			detail = str(root._management_feedback_line())
		if root.build_preview_room_id != "" and not bool(assessment.get("ok", false)):
			detail = str(assessment.get("reason", "건설 불가"))
		var review := copy(bar, detail, Rect2(18, 38, 1240, 44), 19, MUTED, "BuildReviewEffects")
		review.tooltip_text = "%s\n%s\n%s" % [definition.get("effect_summary", ""), root._build_preview_route_line(), " / ".join(warnings)]
		var confirm := button(bar, "건설 확정", Rect2(1302, 8, 320, 68), Callable(root, "_confirm_build_preview"), "ConfirmFacilityReplacementButton", "primary")
		confirm.disabled = not root._build_preview_ready()
		button(bar, "취소 · ESC", Rect2(1636, 8, 220, 68), Callable(root, "_cancel_management_action_mode"), "CancelBuildingButton")
		return
	var undo_text := "되돌리기"
	if not root.management_undo.is_empty():
		undo_text += "\n" + str(root.management_undo.get("label", "배치"))
	var undo := button(bar, undo_text, Rect2(12, 8, 268, 68), Callable(root, "_undo_last_management_placement"), "PlacementUndoButton")
	undo.disabled = root.management_undo.is_empty()
	undo.tooltip_text = "마지막 1회 시설·수비대 배치와 자원·연결로를 복구합니다. 성장·전투·기록은 복구하지 않습니다."
	var feedback: String = root._management_feedback_line()
	var state: Dictionary = model.get("start", {})
	if not bool(state.get("can_start", false)):
		feedback = str(state.get("blocked_reason", feedback))
	copy(bar, feedback, Rect2(302, 4, 1170, 74), 21, MUTED, "PlacementFeedbackLabel")
	var campaign: Dictionary = root._campaign_day_info()
	var title := "방어 시작"
	var callback := Callable(root, "_request_combat_start")
	var enabled := bool(state.get("can_start", false))
	if root.campaign_postgame_active:
		title = "엔딩 다시 보기"
		callback = Callable(root, "_show_campaign_ending")
		enabled = true
	elif bool(campaign.get("management_only", false)):
		title = str(campaign.get("management_only_start_label", "준비 확정"))
		callback = Callable(root, "_confirm_management_only_day")
		enabled = not root._management_action_mode_active()
	elif root._update4_outpost_battle_day():
		enabled = not root._management_action_mode_active()
	if root._campaign_final_declaration_required():
		enabled = not root._campaign_final_declaration_pending() and not root._management_action_mode_active()
	var start := button(bar, title, Rect2(1490, 6, 368, 74), callback, "StartCombatButton", "primary")
	start.disabled = not enabled
	start.tooltip_text = str(state.get("blocked_reason", ""))

func _tactics(model: Dictionary) -> void:
	var dock := panel(Rect2(24, 816, 1872, 156), "TacticsToolbox")
	copy(dock, "전체 전술 · 모든 방", Rect2(18, 6, 432, 32), 23, GOLD)
	var global: OptionButton = hud.option_button(dock, Rect2(18, 42, 440, 48), [
		{"label": "사수 · 배치 방어선 유지", "value": Constants.DIRECTIVE_DEFENSE},
		{"label": "총공격 · 전장 전체 추격", "value": Constants.DIRECTIVE_ALL_OUT},
		{"label": "생존 · 체력 우선 후퇴", "value": Constants.DIRECTIVE_SURVIVAL}
	], root.global_directive, Callable(root, "_set_global_directive"), 22, "GLOBAL_DIRECTIVE_DEFEND")
	global.focus_mode = Control.FOCUS_ALL
	global.disabled = root._day_one_global_directive_locked()
	copy(dock, root._global_directive_description(root.global_directive), Rect2(18, 94, 620, 56), 19, MUTED)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(660, 12)
	scroll.size = Vector2(1190, 132)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dock.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	scroll.add_child(row)
	var connector: Dictionary = root._v122_defender_connector()
	if not connector.is_empty():
		var built := bool(connector.get("built", false))
		var unlocked := bool(connector.get("unlocked", false))
		var text := "연결로 · 완료" if built else ("연결로 건설\n" + str(root._cost_label(connector.get("cost", {}))) if unlocked else "연결로\nDAY %02d 해금" % int(connector.get("unlock_day", 3)))
		var b := button(row, text, Rect2(0, 0, 252, 112), Callable(root, "_build_v122_defender_connector"), "ManagementContextAction_defender_connector")
		b.custom_minimum_size = Vector2(252, 112)
		b.disabled = not root._v122_can_build_defender_connector()
		b.tooltip_text = "방어자 전용 연결로입니다. 적 경로는 변하지 않습니다."
	for action_value in model.get("actions", []):
		var action: Dictionary = action_value
		if str(action.get("area", "")) != "context" or not bool(action.get("visible", false)):
			continue
		var b := button(row, str(action.get("label", "")), Rect2(0, 0, 220, 112), Callable(root, str(action.get("callback", ""))), "ManagementContextAction_%s" % str(action.get("id", "")))
		b.custom_minimum_size = Vector2(220, 112)
		b.disabled = not bool(action.get("enabled", true))
		b.tooltip_text = str(action.get("tooltip", ""))
	if root.story_feature_enabled:
		var b := button(row, "대화 · 기록", Rect2(0, 0, 210, 112), Callable(root, "_open_story_management_dialogue"), "StoryDialogueAlarmButton")
		b.custom_minimum_size = Vector2(210, 112)

func _inspector() -> void:
	var room: Dictionary = root.rooms.get(root.selected_room, {})
	if room.is_empty():
		return
	var drawer := panel(Rect2(1524, 86, 372, 654), "ManagementContextDrawer")
	drawer.z_index = 120
	copy(drawer, "선택한 방", Rect2(18, 10, 216, 38), 24, GOLD)
	button(drawer, "닫기", Rect2(270, 8, 86, 42), Callable(root, "_close_management_context_drawer"), "CloseManagementContextButton")
	copy(drawer, root.display_name_for_instance(root.selected_room), Rect2(18, 62, 336, 44), 27)
	copy(drawer, "체력 %d · 수비대 %d / %d" % [int(room.get("hp", 0)), root._placement_count(root.selected_room), int(room.get("max_monsters", 0))], Rect2(18, 112, 336, 56), 21, MUTED)
	var role := str(room.get("facility_role", ""))
	var definition: Dictionary = root._facility_definition(role)
	var effect := str(definition.get("effect_summary", "성의 고정 구역입니다."))
	if effect.begins_with("체력 ") and effect.contains(". "):
		effect = effect.substr(effect.find(". ") + 2)
	copy(drawer, effect, Rect2(18, 174, 336, 112), 22)
	copy(drawer, root._build_preview_route_line(root.selected_room), Rect2(18, 292, 336, 66), 20, MUTED)
	var options: Array = root._room_directive_options(root.selected_room)
	copy(drawer, "방 지침 · 이 방에 적용", Rect2(18, 366, 336, 32), 22, GOLD)
	var option: OptionButton = hud.option_button(drawer, Rect2(18, 408, 336, 50), options, str(root.room_directives.get(root.selected_room, Constants.ROOM_DIRECTIVE_NONE)), Callable(root, "_set_room_directive"), 21)
	option.name = "SelectedRoomDirectiveOption"
	option.focus_mode = Control.FOCUS_ALL
	for id in ["ROOM_DIRECTIVE_BLOCK_ENTRANCE", "ROOM_DIRECTIVE_TRAP_LURE", "ROOM_DIRECTIVE_RETREAT_LINE"]:
		root.register_tutorial_target_control(id, option)
	copy(drawer, root._room_directive_description(str(root.room_directives.get(root.selected_room, Constants.ROOM_DIRECTIVE_NONE))), Rect2(18, 466, 336, 76), 20, MUTED)
	var replace := button(drawer, "시설 교체", Rect2(18, 570, 198, 58), Callable(root, "_open_build_palette_for_room").bind(root.selected_room), "OpenContextFacilityPaletteButton", "tactical")
	replace.disabled = not root._can_change_room_facility(root.selected_room)
	var upgrade := button(drawer, "강화", Rect2(228, 570, 126, 58), Callable(root, "_upgrade_selected_facility"), "FacilityUpgradeButton", "tactical")
	upgrade.disabled = not root._can_upgrade_selected_facility()

func _review_bar() -> void:
	var bar := panel(Rect2(24, 816, 1872, 252), "BuildingReviewBar")
	var preview := Preview.new()
	preview.game = root
	preview.facility_id = root.build_pick_facility_id
	preview.position = Vector2(12, 6)
	preview.size = Vector2(272, 206)
	bar.add_child(preview)
	copy(bar, "검토 중 · 비용 사용 전", Rect2(24, 210, 264, 34), 20, GOLD)
	copy(bar, root._build_preview_summary(), Rect2(308, 8, 1080, 42), 28, GOLD, "BuildReviewSummary")
	copy(bar, "건설 비용  " + str(root._facility_cost_label(root.build_pick_facility_id)), Rect2(308, 56, 1040, 34), 23, PAPER, "BuildReviewCost")
	var definition: Dictionary = root._facility_definition(root.build_pick_facility_id)
	copy(bar, str(definition.get("effect_summary", "")), Rect2(308, 96, 1040, 58), 21, PAPER, "BuildReviewEffects")
	var assessment: Dictionary = root._evaluate_facility_placement(root.build_preview_room_id, root.build_pick_facility_id)
	var warnings: Array = assessment.get("warnings", [])
	var note: String = root._build_preview_route_line()
	if not bool(assessment.get("ok", false)):
		note = str(assessment.get("reason", "건설 불가"))
	elif not warnings.is_empty():
		note = "주의 · " + " / ".join(warnings)
	copy(bar, note, Rect2(308, 164, 1040, 78), 21, MUTED if warnings.is_empty() else Color("#f1bd94"), "BuildReviewWarning")
	var confirm := button(bar, "건설 확정", Rect2(1396, 40, 444, 78), Callable(root, "_confirm_build_preview"), "ConfirmFacilityReplacementButton", "primary")
	confirm.disabled = not root._build_preview_ready()
	button(bar, "취소 · ESC", Rect2(1396, 134, 444, 66), Callable(root, "_cancel_management_action_mode"), "CancelBuildingButton")
