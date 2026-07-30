extends RefCounted
class_name ManagementSceneController

const Constants = preload("res://scripts/core/Constants.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const V122ManagementViewModelScript = preload("res://scripts/v122/ui/V122ManagementViewModel.gd")
const V122CombatResultViewModelScript = preload("res://scripts/v122/ui/V122CombatResultViewModel.gd")
const CouncilVoteLedgerScript = preload("res://scripts/systems/council/CouncilVoteLedger.gd")

var root: Node
var hud
var defense_start_countdown_label: Label
var defense_start_status_label: Label
var council_drawer_action_id := ""
var council_drawer_agenda_id := ""

func setup(game_root: Node, hud_controller) -> void:
	root = game_root
	hud = hud_controller


func build_intrusion_brief_ui(snapshot: Dictionary) -> void:
	var touch_ui := UISettings.is_touch_ui()
	var screen = hud.panel(Rect2(0, 0, 1920, 1080), Color("#07060cf8"), Color("#00000000"), "IntrusionBriefScreen", "flat")
	screen.name = "IntrusionBriefScreen"
	hud.label(screen, "DAY %02d · 침입 정보" % int(snapshot.get("day", GameState.day)), Vector2(120, 48), Vector2(1680, 58), 34 if touch_ui else 30, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(screen, "적의 편대와 목표를 확인한 뒤 배치를 시작하세요." , Vector2(120, 108), Vector2(1680, 38), 22 if touch_ui else 18, Color("#c8bfd2"))
	var schedule: Array = snapshot.get("schedule", [])
	var enemy_groups: Array = snapshot.get("enemy_groups", [])
	var last_arrival := 0.0
	for entry_value in schedule:
		if entry_value is Dictionary:
			last_arrival = maxf(last_arrival, float(entry_value.get("time", 0.0)))
	var main = hud.child_panel(screen, Rect2(120, 170, 1110, 700), Color("#100d17f2"), Color("#52455c"), 2)
	main.name = "IntrusionBriefEnemyPanel"
	hud.label(main, "침입 편대", Vector2(30, 24), Vector2(430, 42), 25 if touch_ui else 22, Color("#fff1ce"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(main, "총 %d명 · 마지막 진입 %.0f초" % [schedule.size(), last_arrival], Vector2(610, 28), Vector2(460, 34), 20 if touch_ui else 17, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_RIGHT)
	var visible_groups := mini(enemy_groups.size(), 6)
	for index in range(visible_groups):
		var group: Dictionary = enemy_groups[index]
		var row_y := 82.0 + index * 94.0
		var row = hud.child_panel(main, Rect2(24, row_y, 1062, 82), Color("#17121feb"), Color("#342b3c"), 1)
		var threat_color := Color("#ff9b8f") if bool(group.get("boss", false)) else Color("#f4e8d4")
		hud.label(row, "%s × %d" % [str(group.get("display_name", group.get("enemy_id", "적"))), int(group.get("count", 0))], Vector2(18, 10), Vector2(300, 30), 20 if touch_ui else 18, threat_color, HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(row, "%s · %.0f~%.0f초" % [_encounter_role_label(str(group.get("role", "assault"))), float(group.get("first_arrival", 0.0)), float(group.get("last_arrival", 0.0))], Vector2(18, 43), Vector2(300, 24), 16 if touch_ui else 14, Color("#a99fba"))
		var target_name: String = str(root.display_name_for_instance(str(group.get("target_room_id", "throne"))))
		hud.label(row, "목표 · %s" % target_name, Vector2(340, 12), Vector2(230, 28), 17 if touch_ui else 15, Color("#ffd36a"))
		hud.label(row, str(group.get("counter_hint", "첫 방어 구간에서 진입을 지연하세요.")), Vector2(590, 10), Vector2(448, 58), 16 if touch_ui else 14, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3)
	if enemy_groups.size() > visible_groups:
		hud.label(main, "외 %d개 편대" % (enemy_groups.size() - visible_groups), Vector2(24, 650), Vector2(1062, 28), 15, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER)
	var side = hud.child_panel(screen, Rect2(1260, 170, 540, 700), Color("#100d17f2"), Color("#52455c"), 2)
	side.name = "IntrusionBriefThreatPanel"
	hud.label(side, "이번 방어의 변수", Vector2(28, 24), Vector2(484, 42), 24 if touch_ui else 21, Color("#fff1ce"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var modifiers: Dictionary = snapshot.get("defense_modifiers", {})
	var modifier_lines: Array[String] = []
	for modifier_value in modifiers.values():
		if modifier_value is Dictionary:
			modifier_lines.append("• %s · %s" % [
				str(modifier_value.get("source_label", "방어 변수")),
				str(modifier_value.get("display_name", "침입 변화"))
			])
	if modifier_lines.is_empty():
		modifier_lines.append("• 추가 방어 변수 없음")
	hud.rich_label(side, "\n\n".join(modifier_lines), Vector2(28, 84), Vector2(484, 250), 18 if touch_ui else 16, Color("#d8d1df"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_TOP, "IntrusionModifierList", 10)
	var battle_plan: Dictionary = snapshot.get("battle_plan", {})
	var route: Array = battle_plan.get("active_route", [])
	var route_names: Array[String] = []
	for room_id in route:
		route_names.append(root.display_name_for_instance(str(room_id)))
	hud.label(side, "주요 방어선", Vector2(28, 370), Vector2(484, 32), 20 if touch_ui else 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.rich_label(side, " → ".join(route_names), Vector2(28, 414), Vector2(484, 176), 17 if touch_ui else 15, Color("#d8d1df"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_TOP, "IntrusionRouteLabel", 8)
	hud.label(side, "이 정보는 실제 전투 편성과 같은 데이터에서 생성됩니다.", Vector2(28, 610), Vector2(484, 54), 15, Color("#8f859a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3)
	var enter_rect := Rect2(680, 894, 560, 120) if touch_ui else Rect2(720, 914, 480, 94)
	hud.button(screen, "배치 시작", enter_rect, Callable(root, "_enter_placement_from_brief"), 28 if touch_ui else 23, "EnterPlacementButton", HUDController.BUTTON_GRADE_PRIMARY)
	hud.label(screen, "ESC · 배치 화면으로 이동", Vector2(1210, 940), Vector2(590, 30), 15, Color("#8f859a"), HORIZONTAL_ALIGNMENT_RIGHT)
	root.set_meta("v122_intrusion_brief_model", snapshot.duplicate(true))


func build_defense_start_ui(snapshot: Dictionary, seconds: float) -> void:
	var touch_ui := UISettings.is_touch_ui()
	var screen = hud.panel(Rect2(0, 0, 1920, 1080), Color("#050308d9"), Color("#00000000"), "DefenseStartScreen", "flat")
	screen.name = "DefenseStartScreen"
	hud.label(screen, "방어 시작", Vector2(560, 158), Vector2(800, 58), 34 if touch_ui else 30, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(screen, "현재 배치를 고정했습니다", Vector2(560, 230), Vector2(800, 44), 25 if touch_ui else 21, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	defense_start_countdown_label = hud.label(screen, str(maxi(1, ceili(seconds))), Vector2(710, 300), Vector2(500, 330), 220 if touch_ui else 190, Color("#fff0c2"), HORIZONTAL_ALIGNMENT_CENTER, "DefenseStartCountdownLabel", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER)
	defense_start_countdown_label.name = "DefenseStartCountdownLabel"
	defense_start_status_label = hud.label(screen, "0초에 배치와 침입 편성을 확정합니다.", Vector2(520, 642), Vector2(880, 44), 22 if touch_ui else 18, Color("#c8bfd2"), HORIZONTAL_ALIGNMENT_CENTER, "DefenseStartStatusLabel")
	defense_start_status_label.name = "DefenseStartStatusLabel"
	var schedule: Array = snapshot.get("schedule", [])
	hud.label(screen, "DAY %02d · 침입 %d명 · 배치 변경 잠금" % [int(snapshot.get("day", GameState.day)), schedule.size()], Vector2(520, 704), Vector2(880, 38), 19 if touch_ui else 16, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER)
	var cancel_rect := Rect2(720, 786, 480, 120) if touch_ui else Rect2(760, 800, 400, 92)
	hud.button(screen, "취소", cancel_rect, Callable(root, "_cancel_defense_start"), 27 if touch_ui else 21, "CancelDefenseStartButton", HUDController.BUTTON_GRADE_UTILITY)
	hud.label(screen, "ESC로도 취소할 수 있습니다.", Vector2(660, 914), Vector2(600, 32), 16, Color("#8f859a"), HORIZONTAL_ALIGNMENT_CENTER)


func update_defense_start_countdown(seconds: float) -> void:
	if defense_start_countdown_label != null and is_instance_valid(defense_start_countdown_label):
		defense_start_countdown_label.text = "출진!" if seconds <= 0.0 else str(maxi(1, ceili(seconds)))
	if defense_start_status_label != null and is_instance_valid(defense_start_status_label):
		defense_start_status_label.text = "전투를 시작합니다." if seconds <= 0.0 else "0초에 배치와 침입 편성을 확정합니다."


func _encounter_role_label(role: String) -> String:
	match role:
		"engineer", "facility":
			return "시설 파괴"
		"thief", "loot":
			return "보물 탈취"
		"rearline":
			return "후열 지원"
		"heart":
			return "심장실 침투"
		_:
			return "왕좌 돌파"


func build_management_ui() -> void:
	if root.map_editor_active:
		_build_map_editor_workspace_ui()
		return
	var model: Dictionary = V122ManagementViewModelScript.build(root)
	root.set_meta("v122_management_view_model", model)
	var pending_reason := str(model.get("workspace", {}).get("pending_reason", ""))
	if _tutorial_focus_requires_management_map():
		root.management_context_drawer_open = false
	elif pending_reason != "" or _tutorial_focus_requires_management_drawer():
		root.management_context_drawer_open = true
	hud.build_top_bar()
	_build_campaign_notice()
	_build_monster_roster_dock()
	_build_management_primary_bar(model)
	if root.management_context_drawer_open:
		_build_management_context_drawer(model, pending_reason)


func _tutorial_focus_requires_management_drawer() -> bool:
	if not root.onboarding_enabled or not root.tutorial_manager.is_active_for_stage(root.onboarding_stage_id):
		return false
	var focus_id := str(root._tutorial_effective_focus_id(root.tutorial_manager.current_step()))
	return focus_id in [
		"GLOBAL_DIRECTIVE_DEFEND",
		"ROOM_DIRECTIVE_TRAP_LURE",
		"ROOM_DIRECTIVE_RETREAT_LINE"
	]


func _tutorial_focus_requires_management_map() -> bool:
	if not root.onboarding_enabled or not root.tutorial_manager.is_active_for_stage(root.onboarding_stage_id):
		return false
	var focus_id := str(root._tutorial_effective_focus_id(root.tutorial_manager.current_step()))
	return focus_id in [
		"ROOM_SPIKE_CORRIDOR",
		"ROOM_RECOVERY_NEST"
	]


func _build_monster_roster_dock() -> void:
	var touch_ui := UISettings.is_touch_ui()
	var compact := UISettings.is_compact_layout() and not touch_ui
	var drawer_margin := 388.0 if root.management_context_drawer_open and not touch_ui else 0.0
	var dock_rect := Rect2(98, 586, 1725 - drawer_margin, 276) if touch_ui else (
		Rect2(16, 820, 1888 - drawer_margin, 86) if compact else Rect2(24, 786, 1872 - drawer_margin, 110)
	)
	var dock = hud.panel(dock_rect, Color("#0d0a13dc"), Color("#52455c"), "MonsterRosterDock", "flat")
	dock.name = "MonsterRosterDock"
	dock.set_meta("layout_mode", UISettings.effective_layout_mode())
	var label_width := 116.0 if touch_ui else (88.0 if compact else 112.0)
	hud.label(dock, "수비대", Vector2(18, 10), Vector2(label_width, 28), 20 if touch_ui else (17 if compact else 16), Color("#cda8ff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(
		dock,
		"초상화를 맵의 방으로 끌어 배치" if touch_ui else ("끌어 배치" if compact else "맵의 방으로 끌어 배치"),
		Vector2(18, 44 if touch_ui else 39),
		Vector2(label_width, 68 if touch_ui else 38),
		15 if touch_ui else (12 if compact else 11),
		Color("#a99fba"),
		HORIZONTAL_ALIGNMENT_LEFT,
		"",
		UIFontScript.ROLE_BODY,
		VERTICAL_ALIGNMENT_TOP,
		TextServer.AUTOWRAP_WORD_SMART,
		3
	)
	var scroll := ScrollContainer.new()
	scroll.name = "MonsterRosterScroll"
	var scroll_x := 142.0 if touch_ui else (112.0 if compact else 138.0)
	scroll.position = Vector2(scroll_x, 10 if compact else 12)
	scroll.size = Vector2(maxf(260.0, dock_rect.size.x - scroll_x - 14.0), dock_rect.size.y - (20.0 if compact else 24.0))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	dock.add_child(scroll)
	var roster_row := HBoxContainer.new()
	roster_row.name = "MonsterRosterRow"
	roster_row.add_theme_constant_override("separation", 10 if touch_ui else 8)
	roster_row.custom_minimum_size.y = scroll.size.y - 8.0
	scroll.add_child(roster_row)
	var monster_ids: Array = root._defense_monster_ids() if root.has_method("_defense_monster_ids") else root.monster_roster.keys()
	for monster_id_value in monster_ids:
		var monster_id := str(monster_id_value)
		var monster: Dictionary = DataRegistry.monster(monster_id)
		var current_room := str(root.monster_roster.get(monster_id, {}).get("room", ""))
		var room_name: String = str(root.display_name_for_instance(current_room))
		var card_width := 230.0 if touch_ui else (154.0 if compact else 176.0)
		var card = hud.button(
			roster_row,
			"%s\n%s" % [str(monster.get("display_name", monster_id)), room_name],
			Rect2(Vector2.ZERO, Vector2(card_width, scroll.size.y - 8.0)),
			Callable(),
			17 if touch_ui else (14 if compact else 13),
			"MonsterCard_%s" % monster_id,
			HUDController.BUTTON_GRADE_TACTICAL
		)
		card.name = "MonsterCard_%s" % monster_id
		card.custom_minimum_size = Vector2(card_width, scroll.size.y - 8.0)
		card.icon = root._monster_drag_texture(monster_id)
		card.expand_icon = true
		card.add_theme_constant_override("icon_max_width", 78 if touch_ui else (44 if compact else 52))
		card.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.tooltip_text = "%s을(를) 원하는 방으로 끌어 배치합니다. 짧게 누르면 클릭 배치로 전환합니다." % str(monster.get("display_name", monster_id))
		card.button_down.connect(Callable(root, "_begin_management_roster_drag").bind(monster_id))
		if root.has_method("_day1_tutorial_monster_is_fixed") and root._day1_tutorial_monster_is_fixed(monster_id):
			card.disabled = true
			card.tooltip_text = "DAY 1 고정 배치입니다. 이번에는 곱의 전열·후열 합류 위치를 선택하세요."
		var tutorial_target_id := _tutorial_monster_target_id(monster_id)
		if tutorial_target_id != "" and root.has_method("register_tutorial_target_control"):
			root.register_tutorial_target_control(tutorial_target_id, card)
		if root.deploy_pick_monster_id == monster_id:
			hud.apply_button_state(card, HUDController.UI_STATE_SELECTED)
	if root._management_action_mode_active():
		var cancel = hud.button(dock, "선택 취소", Rect2(dock_rect.size.x - 138, 12, 120, 42), Callable(root, "_cancel_management_action_mode"), 15 if touch_ui else 12, "CancelPlacementSelectionButton", HUDController.BUTTON_GRADE_UTILITY)
		cancel.z_index = 20


func _build_management_primary_bar(model: Dictionary) -> void:
	var touch_ui := UISettings.is_touch_ui()
	var compact := UISettings.is_compact_layout() and not touch_ui
	var bar_rect := Rect2(98, 878, 1725, 174) if touch_ui else (
		Rect2(16, 920, 1888, 112) if compact else Rect2(24, 912, 1872, 132)
	)
	var bar = hud.panel(bar_rect, Color("#100e14e6"), Color("#3b3143"), "ManagementPrimaryBar", "flat")
	bar.name = "ManagementPrimaryBar"
	bar.set_meta("layout_mode", UISettings.effective_layout_mode())
	var button_y := 15.0 if touch_ui else (12.0 if compact else 16.0)
	var button_h := 144.0 if touch_ui else (88.0 if compact else 100.0)
	var small_w := 172.0 if not compact else 148.0
	var button_gap := 12.0 if compact else 12.0
	hud.button(bar, "침입 정보", Rect2(18, button_y, small_w, button_h), Callable(root, "_open_intrusion_brief"), 18 if touch_ui else 15, "OpenIntrusionBriefButton", HUDController.BUTTON_GRADE_UTILITY)
	hud.button(bar, "몬스터 성장" if not compact else "몬스터", Rect2(18 + small_w + button_gap, button_y, small_w, button_h), Callable(root, "_open_monster_screen"), 18 if touch_ui else (16 if compact else 15), "MonsterManagementButton", HUDController.BUTTON_GRADE_UTILITY)
	hud.button(bar, "전술 · 상세" if not compact else "전술", Rect2(18 + (small_w + button_gap) * 2.0, button_y, small_w, button_h), Callable(root, "_open_management_context_drawer"), 18 if touch_ui else (16 if compact else 15), "OpenManagementContextButton", HUDController.BUTTON_GRADE_TACTICAL)
	var undo_label := "되돌리기"
	if not root.management_undo.is_empty():
		undo_label = "되돌리기\n%s" % str(root.management_undo.get("label", "배치"))
	var undo_button = hud.button(bar, undo_label, Rect2(18 + (small_w + button_gap) * 3.0, button_y, small_w, button_h), Callable(root, "_undo_last_management_placement"), 16 if touch_ui else (14 if compact else 13), "PlacementUndoButton", HUDController.BUTTON_GRADE_UTILITY)
	undo_button.disabled = root.management_undo.is_empty()
	var campaign_info: Dictionary = root._campaign_day_info() if root.has_method("_campaign_day_info") else {}
	var start_label := "방어 시작"
	var start_callback := Callable(root, "_request_combat_start")
	var standard_defense_action := true
	if root.campaign_postgame_active:
		start_label = "엔딩 다시 보기"
		start_callback = Callable(root, "_show_campaign_ending")
		standard_defense_action = false
	elif bool(campaign_info.get("management_only", false)):
		start_label = str(campaign_info.get("management_only_start_label", "준비 확정"))
		start_callback = Callable(root, "_confirm_management_only_day")
		standard_defense_action = false
	elif root.has_method("_update4_outpost_battle_day") and root._update4_outpost_battle_day():
		standard_defense_action = false
	var start_rect := Rect2(1280, 15, 420, 144) if touch_ui else (
		Rect2(1498, 10, 372, 92) if compact else Rect2(1388, 14, 466, 104)
	)
	var start_button = hud.button(bar, start_label, start_rect, start_callback, 27 if touch_ui else (24 if compact else 23), "StartCombatButton", HUDController.BUTTON_GRADE_PRIMARY)
	var start_state: Dictionary = model.get("start", {})
	if standard_defense_action:
		start_button.disabled = not bool(start_state.get("can_start", false))
	var final_declaration_required: bool = root.has_method("_campaign_final_declaration_required") and bool(root._campaign_final_declaration_required())
	if final_declaration_required:
		start_button.disabled = root._campaign_final_declaration_pending()
		if start_button.disabled:
			start_button.text = "선언 후 확정"
	var feedback_text: String = str(root._management_feedback_line())
	var feedback_color := Color("#ffab9f") if not root.management_feedback.is_empty() and not bool(root.management_feedback.get("ok", false)) else Color("#d8d1df")
	var feedback_x := 766.0 if touch_ui else (668.0 if compact else 782.0)
	var feedback_width := 494.0 if touch_ui else (620.0 if compact else 576.0)
	if root.has_method("_open_story_management_dialogue") and bool(root.story_feature_enabled):
		var unread_story_count := int(root._story_unread_optional_count())
		var story_label := "대화 알람 %d" % unread_story_count if unread_story_count > 0 else "대화 기록"
		var story_button_width := 184.0 if touch_ui else (176.0 if compact else 186.0)
		hud.button(
			bar,
			story_label,
			Rect2(feedback_x, button_y, story_button_width, button_h),
			Callable(root, "_open_story_management_dialogue"),
			17 if touch_ui else (14 if compact else 15),
			"StoryDialogueAlarmButton",
			HUDController.BUTTON_GRADE_TACTICAL if unread_story_count > 0 else HUDController.BUTTON_GRADE_UTILITY
		)
		feedback_x += story_button_width + 12.0
		feedback_width = maxf(220.0, feedback_width - story_button_width - 12.0)
	hud.label(bar, feedback_text, Vector2(feedback_x, 18 if not compact else 14), Vector2(feedback_width, 42), 15 if touch_ui else (14 if compact else 13), feedback_color, HORIZONTAL_ALIGNMENT_LEFT, "PlacementFeedbackLabel", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	var blocked_reason := str(start_state.get("blocked_reason", "")) if standard_defense_action and start_button.disabled else ""
	hud.label(bar, blocked_reason, Vector2(feedback_x, 64 if not compact else 58), Vector2(feedback_width, 36), 14 if touch_ui else (13 if compact else 12), Color("#ff9b8f"), HORIZONTAL_ALIGNMENT_LEFT, "StartBlockReasonLabel", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)


func _build_management_context_drawer(model: Dictionary, pending_reason: String) -> void:
	if UISettings.is_touch_ui():
		_build_touch_management_context_drawer(model, pending_reason)
		return
	var compact := UISettings.is_compact_layout()
	var drawer_rect := Rect2(1532, 80, 372, 824) if compact else Rect2(1524, 88, 372, 806)
	var drawer = hud.panel(drawer_rect, Color("#08070df2"), Color("#7b657f"), "ManagementContextDrawer", "flat")
	drawer.name = "ManagementContextDrawer"
	drawer.set_meta("layout_mode", UISettings.effective_layout_mode())
	drawer.z_index = 120
	var close_button = hud.button(drawer, "닫기", Rect2(278, 10, 76, 34), Callable(root, "_close_management_context_drawer"), 13, "CloseManagementContextButton", HUDController.BUTTON_GRADE_UTILITY)
	close_button.z_index = 300
	if pending_reason != "" and not _tutorial_focus_requires_management_drawer():
		hud.label(drawer, "필수 준비", Vector2(20, 18), Vector2(240, 32), 21, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		var start_state: Dictionary = model.get("start", {})
		hud.rich_label(drawer, str(start_state.get("blocked_reason", "필수 결정을 완료하세요.")), Vector2(20, 70), Vector2(330, 110), 17, Color("#f4e7d2"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "RequiredChoiceReason", 5)
		match pending_reason:
			"specialization":
				_build_required_specialization_drawer(drawer)
			"raid_choice":
				_build_required_raid_drawer(drawer)
			"council_choice":
				_build_required_council_drawer(drawer)
			"final_declaration":
				_build_required_final_declaration_drawer(drawer)
		hud.label(drawer, "이 드로어에서 확정하면 방어 시작이 활성화됩니다.", Vector2(24, 704 if UISettings.is_touch_ui() else 742), Vector2(322, 26), 12, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		return
	_build_management_room_context(drawer, model)


func _build_touch_management_context_drawer(model: Dictionary, pending_reason: String) -> void:
	var drawer = hud.panel(Rect2(820, 92, 1068, 770), Color("#08070df9"), Color("#7b657f"), "ManagementContextDrawer", "flat")
	drawer.name = "ManagementContextDrawer"
	drawer.z_index = 120
	drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.label(drawer, "관리 · 전술 상세", Vector2(28, 10), Vector2(700, 100), 28, Color("#fff2c9"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var close_button = hud.button(drawer, "닫기", Rect2(870, 10, 180, 100), Callable(root, "_close_management_context_drawer"), 20, "CloseManagementContextButton", HUDController.BUTTON_GRADE_UTILITY)
	close_button.z_index = 300

	var scroll := ScrollContainer.new()
	scroll.name = "ManagementContextTouchScroll"
	scroll.position = Vector2(18, 120)
	scroll.size = Vector2(1032, 632)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	drawer.add_child(scroll)
	var content := Control.new()
	content.name = "ManagementContextTouchContent"
	content.custom_minimum_size = Vector2(1000, 2300)
	content.size = content.custom_minimum_size
	scroll.add_child(content)

	if pending_reason != "" and not _tutorial_focus_requires_management_drawer():
		hud.label(content, "필수 준비", Vector2(20, 18), Vector2(240, 32), 21, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		var start_state: Dictionary = model.get("start", {})
		hud.rich_label(content, str(start_state.get("blocked_reason", "필수 결정을 완료하세요.")), Vector2(20, 70), Vector2(330, 110), 17, Color("#f4e7d2"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "RequiredChoiceReason", 5)
		match pending_reason:
			"specialization":
				_build_required_specialization_drawer(content)
			"raid_choice":
				_build_required_raid_drawer(content)
			"council_choice":
				_build_required_council_drawer(content)
			"final_declaration":
				_build_required_final_declaration_drawer(content)
		hud.label(content, "이 드로어에서 확정하면 방어 시작이 활성화됩니다.", Vector2(24, 704), Vector2(322, 26), 12, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	else:
		_build_management_room_context(content, model)
	_scale_touch_drawer_contents(content, 2.7, 3.0)


func _scale_touch_drawer_contents(node: Node, horizontal_scale: float, vertical_scale: float) -> void:
	for child in node.get_children():
		if not child is Control:
			continue
		var control := child as Control
		control.position = Vector2(control.position.x * horizontal_scale, control.position.y * vertical_scale)
		control.size = Vector2(control.size.x * horizontal_scale, control.size.y * vertical_scale)
		_scale_touch_drawer_contents(control, horizontal_scale, vertical_scale)


func _build_required_specialization_drawer(drawer: Control) -> void:
	var y := 194.0
	var shown := 0
	for monster_id_value in root._defense_monster_ids():
		var monster_id := str(monster_id_value)
		if str(root.monster_roster.get(monster_id, {}).get("specialization_id", "")) != "":
			continue
		for option_value in root._specializations_for_monster(monster_id):
			if shown >= 8:
				break
			var option: Dictionary = option_value
			var specialization_id := str(option.get("id", ""))
			var monster_name := str(DataRegistry.monster(monster_id).get("display_name", monster_id))
			var option_button = hud.button(
				drawer,
				"%s · %s\n%s" % [monster_name, str(option.get("display_name", specialization_id)), str(option.get("short_effect", ""))],
				Rect2(24, y, 322, 52),
				Callable(root, "_choose_early_specialization_from_drawer").bind(monster_id, specialization_id),
				13,
				"RequiredSpecialization_%s_%s" % [monster_id, specialization_id]
			)
			option_button.disabled = not root._can_choose_early_specialization(monster_id, specialization_id)
			option_button.tooltip_text = str(option.get("description", ""))
			y += 58.0
			shown += 1
	if shown == 0:
		hud.label(drawer, "선택 가능한 전술 특화가 없습니다.", Vector2(30, 220), Vector2(310, 64), 16, Color("#ff9b8f"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER)


func _build_required_raid_drawer(drawer: Control) -> void:
	root._ensure_raid_selection()
	var mission_ids: Array = root._available_raid_ids()
	var y := 192.0
	hud.label(drawer, "원정 계획", Vector2(24, y), Vector2(322, 24), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	y += 30.0
	for index in range(mini(3, mission_ids.size())):
		var mission_id := str(mission_ids[index])
		var mission: Dictionary = DataRegistry.raid_mission(mission_id)
		var mission_button = hud.button(
			drawer,
			"%s · %s" % [str(mission.get("title", mission_id)), root._cost_label(mission.get("cost", {}))],
			Rect2(24, y, 322, 48),
			Callable(root, "_select_raid_mission_from_drawer").bind(mission_id),
			13,
			"RequiredRaidMission_%s" % mission_id
		)
		if mission_id == root.raid_selected_mission_id:
			mission_button.add_theme_stylebox_override("normal", hud.style(Color("#352342f5"), Color("#ffd36a"), 3))
		mission_button.add_theme_color_override("font_color", Color("#fff2c9"))
		mission_button.tooltip_text = str(mission.get("description", mission.get("summary", "")))
		y += 54.0
	hud.label(drawer, "원정대", Vector2(24, y + 4), Vector2(322, 24), 15, Color("#cda8ff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	y += 34.0
	var mission: Dictionary = DataRegistry.raid_mission(root.raid_selected_mission_id)
	var fixed_captain_id: String = str(root._raid_fixed_captain_id(mission))
	var roster_ids: Array = []
	for roster_id_value in root.monster_roster.keys():
		var roster_id := str(roster_id_value)
		if roster_id != fixed_captain_id:
			roster_ids.append(roster_id)
	roster_ids.sort()
	for index in range(mini(6, roster_ids.size())):
		var monster_id := str(roster_ids[index])
		var selected: bool = root.raid_selected_monster_ids.has(monster_id)
		var roster_button = hud.button(
			drawer,
			("%s  ✓" if selected else "%s") % str(DataRegistry.monster(monster_id).get("display_name", monster_id)),
			Rect2(24 + (index % 2) * 164, y + int(index / 2) * 48, 154, 42),
			Callable(root, "_toggle_raid_monster_from_drawer").bind(monster_id),
			12,
			"RequiredRaidMonster_%s" % monster_id
		)
		if selected:
			roster_button.add_theme_stylebox_override("normal", hud.style(Color("#2b2140f5"), Color("#cda8ff"), 2))
	y += ceilf(float(mini(6, roster_ids.size())) / 2.0) * 48.0 + 12.0
	var start_button = hud.button(drawer, "이 계획으로 원정 확정", Rect2(24, y, 322, 58), Callable(root, "_start_selected_raid_from_drawer"), 17, "RequiredRaidConfirmButton")
	start_button.disabled = not root._can_start_selected_raid()
	start_button.tooltip_text = root._raid_start_block_reason() if start_button.disabled and root.has_method("_raid_start_block_reason") else ""


func _build_required_council_drawer(drawer: Control) -> void:
	var action_id := str(root._update4_required_choice_id())
	if action_id != council_drawer_action_id:
		council_drawer_action_id = action_id
		council_drawer_agenda_id = ""
	match action_id:
		"council_vote":
			_build_required_council_vote_drawer(drawer)
		"crown_choice":
			_build_required_crown_drawer(drawer)
		"council_final_declaration":
			_build_required_council_final_drawer(drawer)
		_:
			hud.label(drawer, "현재 필요한 의회 결정을 불러오지 못했습니다.", Vector2(26, 220), Vector2(318, 68), 16, Color("#ff9b8f"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER)


func _build_required_council_vote_drawer(drawer: Control) -> void:
	var seed: int = int(root.update2_cycle_seed if root.update2_cycle_seed > 0 else root.campaign_cycle_index * 1009)
	var agenda_ids: Array = CouncilVoteLedgerScript.seeded_agendas_for_day(DataRegistry.update4_council_agendas, GameState.day, root.update4_active_run, seed, 3)
	if council_drawer_agenda_id != "" and not agenda_ids.has(council_drawer_agenda_id):
		council_drawer_agenda_id = ""
	if council_drawer_agenda_id == "":
		hud.label(drawer, "안건 선택", Vector2(24, 194), Vector2(322, 26), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		var y := 228.0
		for agenda_id_value in agenda_ids:
			var agenda_id := str(agenda_id_value)
			var agenda: Dictionary = DataRegistry.update4_council_agendas.get(agenda_id, {})
			var agenda_button = hud.button(drawer, str(agenda.get("display_name", agenda_id)), Rect2(24, y, 322, 64), Callable(self, "_select_council_drawer_agenda").bind(agenda_id), 15, "RequiredCouncilAgenda_%s" % agenda_id)
			agenda_button.tooltip_text = "이점: %s · 대가: %s" % [str(agenda.get("benefit", "")), str(agenda.get("cost", ""))]
			y += 72.0
		return
	var agenda: Dictionary = DataRegistry.update4_council_agendas.get(council_drawer_agenda_id, {})
	hud.button(drawer, "← 안건 다시 선택", Rect2(24, 194, 144, 38), Callable(self, "_select_council_drawer_agenda").bind(""), 12, "RequiredCouncilAgendaBack")
	hud.label(drawer, str(agenda.get("display_name", council_drawer_agenda_id)), Vector2(24, 242), Vector2(322, 46), 17, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	var choice_labels := {"approve": "찬성", "amend": "수정안", "reject": "반대"}
	var y := 300.0
	for choice_id_value in CouncilVoteLedgerScript.VALID_CHOICES:
		var choice_id := str(choice_id_value)
		var forecast: Dictionary = CouncilVoteLedgerScript.forecast(root.update4_active_run, council_drawer_agenda_id, DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords, choice_id)
		var tally: Dictionary = forecast.get("tally", {})
		var copy := "%s · %s 예상\n찬 %d · 수 %d · 반 %d" % [
			str(choice_labels.get(choice_id, choice_id)),
			"통과" if bool(forecast.get("passed", false)) else "부결",
			int(tally.get("approve", 0)),
			int(tally.get("amend", 0)),
			int(tally.get("reject", 0))
		]
		hud.button(drawer, copy, Rect2(24, y, 322, 72), Callable(root, "_commit_update4_council_vote").bind(council_drawer_agenda_id, choice_id), 15, "RequiredCouncilVote_%s" % choice_id)
		y += 82.0


func _select_council_drawer_agenda(agenda_id: String) -> void:
	council_drawer_agenda_id = agenda_id
	root.management_context_drawer_open = true
	root._set_screen(Constants.SCREEN_MANAGEMENT)


func _build_required_crown_drawer(drawer: Control) -> void:
	var candidates: Array = root._update4_crown_candidates()
	var y := 194.0
	hud.label(drawer, "왕관 후보", Vector2(24, y), Vector2(322, 24), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	y += 30.0
	for index in range(mini(4, candidates.size())):
		var candidate: Dictionary = candidates[index]
		var instance_id := str(candidate.get("instance_id", ""))
		var crown_id := str(candidate.get("crown_form_id", ""))
		var crown: Dictionary = DataRegistry.update4_crown_evolutions.get(crown_id, {})
		hud.button(drawer, "%s · %s" % [str(candidate.get("display_name", instance_id)), str(crown.get("display_name", crown_id))], Rect2(24, y, 322, 52), Callable(root, "_confirm_update4_crown").bind(instance_id, crown_id), 13, "RequiredCrown_%s" % instance_id)
		y += 58.0
	hud.label(drawer, "왕관 대신 받을 보상", Vector2(24, y + 4), Vector2(322, 24), 14, Color("#cda8ff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	y += 34.0
	var declines := [
		{"id": "outpost_reinforcement", "label": "전초기지 보강"},
		{"id": "heart_extra_charge", "label": "심장 추가 충전"},
		{"id": "council_support_token", "label": "의회 지원 토큰"}
	]
	for index in range(declines.size()):
		var decline: Dictionary = declines[index]
		hud.button(drawer, str(decline.get("label", "")), Rect2(24 + (index % 2) * 164, y + int(index / 2) * 48, 154, 42), Callable(root, "_decline_update4_crown").bind(str(decline.get("id", ""))), 12, "RequiredCrownDecline_%s" % str(decline.get("id", "")))


func _build_required_council_final_drawer(drawer: Control) -> void:
	var choices := [
		{"id": "council_commitment", "label": "의회 의석을 지킨다"},
		{"id": "delegate_the_crown", "label": "왕관의 공을 부하에게"},
		{"id": "keep_outpost_after_council", "label": "전초기지를 집으로"},
		{"id": "reject_council_authority", "label": "의회 권위를 거부"}
	]
	var y := 194.0
	for choice_value in choices:
		var choice: Dictionary = choice_value
		hud.button(drawer, str(choice.get("label", "")), Rect2(24, y, 322, 60), Callable(root, "_commit_update4_final_declaration").bind(str(choice.get("id", ""))), 15, "RequiredCouncilFinal_%s" % str(choice.get("id", "")))
		y += 68.0


func _build_required_final_declaration_drawer(drawer: Control) -> void:
	var choices := [
		{"id": "rival_pact", "label": "라이벌 약속"},
		{"id": "castle_oath", "label": "성 수호"}
	]
	if root._campaign_armistice_request_available():
		choices.append({"id": "grand_armistice_request", "label": "휴전문 제안"})
	var y := 200.0
	for choice_value in choices:
		var choice: Dictionary = choice_value
		hud.button(drawer, str(choice.get("label", "")), Rect2(24, y, 322, 64), Callable(root, "_set_campaign_final_declaration").bind(str(choice.get("id", ""))), 16, "RequiredFinalDeclaration_%s" % str(choice.get("id", "")))
		y += 74.0


func _build_management_room_context(drawer: Control, model: Dictionary) -> void:
	var room: Dictionary = root.rooms.get(root.selected_room, {})
	var room_name: String = str(root.display_name_for_instance(root.selected_room))
	var role_name := "통로"
	if not room.is_empty():
		role_name = str(root._facility_short_label(str(room.get("facility_role", room.get("type", "")))))
	var capacity := int(room.get("max_monsters", 0))
	var placed := int(root._placement_count(root.selected_room)) if not room.is_empty() else 0
	hud.label(drawer, "방 · 지침", Vector2(20, 18), Vector2(240, 32), 21, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var summary = hud.child_panel(drawer, Rect2(18, 60, 334, 92), Color("#111016e8"), Color("#55465f"), 1)
	hud.label(summary, room_name, Vector2(16, 10), Vector2(302, 28), 20, Color("#fffdf4"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(summary, role_name, Vector2(16, 42), Vector2(190, 22), 14, Color("#d99bff"))
	hud.label(summary, "체력 %s · 배치 %d/%d" % [str(int(room.get("hp", 0))) if not room.is_empty() else "-", placed, capacity], Vector2(16, 66), Vector2(302, 18), 13, Color("#bfb7cc"))

	var directive_panel = hud.child_panel(drawer, Rect2(18, 164, 334, 220), Color("#0f0d14e8"), Color("#403448"), 1)
	hud.label(directive_panel, "전체 전술 · 모든 방", Vector2(14, 10), Vector2(306, 22), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var global_option = hud.option_button(
		directive_panel,
		Rect2(14, 38, 306, 36),
		[
			{"label": "사수 · 배치 방어선 유지", "value": Constants.DIRECTIVE_DEFENSE},
			{"label": "총공격 · 전장 전체 추격", "value": Constants.DIRECTIVE_ALL_OUT},
			{"label": "생존 · 체력 우선 후퇴", "value": Constants.DIRECTIVE_SURVIVAL}
		],
		root.global_directive,
		Callable(root, "_set_global_directive"),
		13,
		"GLOBAL_DIRECTIVE_DEFEND"
	)
	if root._day_one_global_directive_locked():
		global_option.disabled = true
		global_option.tooltip_text = "DAY 01은 사수 전술이 기본 적용됩니다. 같은 값을 다시 선택할 필요가 없습니다."
	hud.label(
		directive_panel,
		"DAY 01 고정 · " + root._global_directive_description(root.global_directive) if root._day_one_global_directive_locked() else root._global_directive_description(root.global_directive),
		Vector2(14, 78),
		Vector2(306, 34),
		11,
		Color("#bfb7cc"),
		HORIZONTAL_ALIGNMENT_LEFT,
		"",
		UIFontScript.ROLE_BODY,
		VERTICAL_ALIGNMENT_TOP,
		TextServer.AUTOWRAP_WORD_SMART,
		2
	)
	hud.label(directive_panel, "선택 방 예외 · 이 방만", Vector2(14, 116), Vector2(306, 22), 14, Color("#d9a6ff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var room_options: Array = root._room_directive_options(root.selected_room)
	var room_directive_button = hud.option_button(
		directive_panel,
		Rect2(14, 142, 306, 36),
		room_options,
		str(root.room_directives.get(root.selected_room, Constants.ROOM_DIRECTIVE_NONE)),
		Callable(root, "_set_room_directive"),
		13
	)
	room_directive_button.name = "SelectedRoomDirectiveOption"
	for option_value in room_options:
		var value := str(option_value.get("value", ""))
		var target_id := ""
		match value:
			Constants.ROOM_DIRECTIVE_ENTRY_BLOCK:
				target_id = "ROOM_DIRECTIVE_BLOCK_ENTRANCE"
			Constants.ROOM_DIRECTIVE_TRAP_LURE:
				target_id = "ROOM_DIRECTIVE_TRAP_LURE"
			Constants.ROOM_DIRECTIVE_RETREAT:
				target_id = "ROOM_DIRECTIVE_RETREAT_LINE"
		if target_id != "":
			root.register_tutorial_target_control(target_id, room_directive_button)
	var selected_room_directive := str(root.room_directives.get(root.selected_room, Constants.ROOM_DIRECTIVE_NONE))
	hud.label(
		directive_panel,
		root._room_directive_description(selected_room_directive),
		Vector2(14, 182),
		Vector2(306, 30),
		11,
		Color("#a99fba"),
		HORIZONTAL_ALIGNMENT_LEFT,
		"",
		UIFontScript.ROLE_BODY,
		VERTICAL_ALIGNMENT_TOP,
		TextServer.AUTOWRAP_WORD_SMART,
		2
	)

	var facility_panel_height := 328.0 if root.build_palette_target_room != "" or root.facility_change_panel_open else 146.0
	var facility_panel = hud.child_panel(drawer, Rect2(18, 396, 334, facility_panel_height), Color("#0f0d14e8"), Color("#403448"), 1)
	_build_contextual_facility_palette(facility_panel, room)
	if root.build_palette_target_room != "" or root.facility_change_panel_open:
		return

	var actions_y := 554.0
	hud.label(drawer, "추가 작전", Vector2(22, actions_y), Vector2(326, 24), 16, Color("#c6b8ce"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var context_actions: Array = []
	if root.has_method("_v122_defender_connector"):
		var connector: Dictionary = root._v122_defender_connector()
		if not connector.is_empty():
			var connector_built := bool(connector.get("built", false))
			var connector_unlocked := bool(connector.get("unlocked", false))
			var connector_cost: Dictionary = connector.get("cost", {})
			var connector_affordable := GameState.can_pay(connector_cost)
			var connector_label := "연결로 · 건설 완료" if connector_built else (
				"연결로 건설\n%s" % root._cost_label(connector_cost)
				if connector_unlocked
				else "연결로 · DAY %02d 해금" % int(connector.get("unlock_day", 3))
			)
			var connector_tooltip := (
				"건설 완료 · 방어자만 두 후방 전선 사이를 이동합니다. 적 경로는 변하지 않습니다."
				if connector_built
				else (
					(
						"두 후방 전선을 방어자 전용으로 연결합니다. 적은 사용할 수 없습니다."
						if connector_affordable
						else "건설 비용이 부족합니다. 필요: %s" % root._cost_label(connector_cost)
					)
					if connector_unlocked
					else "DAY %02d부터 %s으로 건설할 수 있습니다." % [
						int(connector.get("unlock_day", 3)),
						root._cost_label(connector_cost)
					]
				)
			)
			context_actions.append({
				"id": "defender_connector",
				"label": connector_label,
				"callback": "_build_v122_defender_connector",
				"enabled": root._v122_can_build_defender_connector(),
				"tooltip": connector_tooltip
			})
	for action_value in model.get("actions", []):
		if action_value is Dictionary and str(action_value.get("area", "")) == "context" and bool(action_value.get("visible", false)):
			context_actions.append(action_value)
	for index in range(context_actions.size()):
		var action: Dictionary = context_actions[index]
		var col := index % 2
		var row := int(index / 2)
		var callback_name := str(action.get("callback", ""))
		var action_button = hud.button(
			drawer,
			str(action.get("label", action.get("id", ""))),
			Rect2(18 + col * 168, actions_y + 34 + row * 60, 154, 50),
			Callable(root, callback_name),
			13,
			"ManagementContextAction_%s" % str(action.get("id", "")),
			HUDController.BUTTON_GRADE_UTILITY
		)
		action_button.disabled = not bool(action.get("enabled", true))
		action_button.tooltip_text = str(action.get("tooltip", ""))


func _build_contextual_facility_palette(panel: Control, room: Dictionary) -> void:
	var current_role := str(room.get("facility_role", room.get("type", "")))
	var current_name := str(root._facility_definition(current_role).get("display_name", root._facility_short_label(current_role)))
	hud.label(panel, "선택 방 시설", Vector2(14, 8), Vector2(306, 22), 14, Color("#c6b8ce"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(panel, "현재 · %s" % current_name, Vector2(14, 32), Vector2(306, 22), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT)
	if not root._can_change_room_facility(root.selected_room):
		hud.label(panel, "고정 시설은 교체할 수 없습니다.", Vector2(14, 64), Vector2(306, 30), 12, Color("#8f859a"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	if root.build_palette_target_room != "" or root.facility_change_panel_open:
		hud.label(panel, "교체할 시설을 고르세요", Vector2(14, 58), Vector2(306, 22), 13, Color("#cda8ff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		var scroll := ScrollContainer.new()
		scroll.name = "ContextualFacilityScroll"
		scroll.position = Vector2(12, 84)
		scroll.size = Vector2(310, 188)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.add_child(scroll)
		var list := VBoxContainer.new()
		list.name = "ContextualFacilityList"
		list.custom_minimum_size.x = 292.0
		list.add_theme_constant_override("separation", 6)
		scroll.add_child(list)
		for facility_id_value in root._build_facility_choices():
			var facility_id := str(facility_id_value)
			var definition: Dictionary = root._facility_definition(facility_id)
			var option: Button = hud.button(
				list,
				"%s  ·  %s" % [
					str(definition.get("display_name", facility_id)),
					root._cost_label(definition.get("cost", {}))
				],
				Rect2(Vector2.ZERO, Vector2(292, 48)),
				Callable(root, "_set_contextual_build_facility").bind(facility_id, root.selected_room),
				12,
				"ContextFacility_%s" % facility_id,
				HUDController.BUTTON_GRADE_TACTICAL
			)
			option.name = "ContextFacility_%s" % facility_id
			option.set_meta("facility_id", facility_id)
			option.custom_minimum_size = Vector2(292, 48)
			option.tooltip_text = str(definition.get("description", definition.get("short_effect", "")))
		hud.button(panel, "교체 취소", Rect2(12, 280, 310, 36), Callable(root, "_cancel_management_action_mode"), 12, "CancelFacilityPaletteButton", HUDController.BUTTON_GRADE_UTILITY)
		return
	if root.build_preview_room_id == root.selected_room and root.build_pick_facility_id != "":
		var preview_definition: Dictionary = root._facility_definition(root.build_pick_facility_id)
		hud.label(
			panel,
			"미리보기 · %s · %s" % [
				str(preview_definition.get("display_name", root.build_pick_facility_id)),
				root._cost_label(preview_definition.get("cost", {}))
			],
			Vector2(14, 58),
			Vector2(306, 30),
			12,
			Color("#cda8ff"),
			HORIZONTAL_ALIGNMENT_CENTER
		)
		var confirm_button: Button = hud.button(panel, "교체 확정", Rect2(12, 96, 196, 38), Callable(root, "_confirm_build_preview"), 13, "ConfirmFacilityReplacementButton", HUDController.BUTTON_GRADE_TACTICAL)
		confirm_button.name = "ConfirmFacilityReplacementButton"
		hud.button(panel, "취소", Rect2(216, 96, 106, 38), Callable(root, "_cancel_management_action_mode"), 12, "", HUDController.BUTTON_GRADE_UTILITY)
		return
	var replace_button = hud.button(panel, "이 방 시설 교체", Rect2(12, 66, 194, 38), Callable(root, "_open_build_palette_for_room").bind(root.selected_room), 13, "OpenContextFacilityPaletteButton", HUDController.BUTTON_GRADE_TACTICAL)
	replace_button.tooltip_text = "이 방을 선택한 상태에서 교체 후보만 문맥 목록으로 엽니다."
	var upgrade_button = hud.button(panel, "강화", Rect2(214, 66, 108, 38), Callable(root, "_upgrade_selected_facility"), 13, "FacilityUpgradeButton", HUDController.BUTTON_GRADE_TACTICAL)
	upgrade_button.disabled = not root.has_method("_can_upgrade_selected_facility") or not root._can_upgrade_selected_facility()


func _build_map_editor_workspace_ui() -> void:
	hud.build_top_bar()
	var touch_ui := UISettings.is_touch_ui()
	var heading_rect := Rect2(24, 104, 520, 880) if touch_ui else Rect2(24, 104, 300, 370)
	var heading = hud.panel(heading_rect, Color("#0b0911f5"), Color("#8f66b5"), "MapEditorWorkspace", "flat")
	heading.name = "MapEditorWorkspace"
	hud.label(heading, "성 구조 편집", Vector2(18, 12), Vector2(484 if touch_ui else 264, 54 if touch_ui else 34), 28 if touch_ui else 24, Color("#fff2c9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	_build_map_editor_controls(heading)
	if touch_ui:
		hud.rich_label(heading, "배치·방어 시작은 잠깁니다. 저장하면 구조를 적용하고, 취소하면 편집 전 상태로 돌아갑니다.", Vector2(28, 790), Vector2(464, 72), 18, Color("#cfc7d9"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "", 3)
		return
	var help = hud.panel(Rect2(24, 494, 300, 250), Color("#0b0911f0"), Color("#4c4354"), "", "flat")
	hud.label(help, "안전 편집 모드", Vector2(18, 18), Vector2(264, 30), 19, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.rich_label(help, "배치 카드와 방어 시작은 잠겼습니다.\n\n방을 선택하고 연결을 편집한 뒤 저장하세요. 취소하면 편집 전 구조로 돌아갑니다.", Vector2(22, 62), Vector2(256, 150), 15, Color("#d8d1df"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_TOP, "", 7)
	hud.label(help, "ESC · 현재 드래그 취소", Vector2(18, 214), Vector2(264, 22), 12, Color("#8f859a"), HORIZONTAL_ALIGNMENT_CENTER)


func _build_legacy_management_ui() -> void:
	var touch_ui := UISettings.is_touch_ui()
	hud.build_top_bar()
	if root.build_pick_mode:
		hud.build_facility_build_panel(16, 92, 300, 780)
	else:
		hud.build_room_list(16, 92, 300, 420)
		_build_layout_selector()
	_build_campaign_notice()

	var right = hud.panel(Rect2(1518, 92, 370, 760), Color("#08070def"), Color("#57485e"), "", "flat")
	hud.build_selected_room_info(right)
	if root.facility_change_panel_open:
		hud.build_facility_change_modal()
	var campaign_info: Dictionary = root._campaign_day_info() if root.has_method("_campaign_day_info") else {}
	var v122_management_view: Dictionary = V122ManagementViewModelScript.build(root)
	root.set_meta("v122_management_view_model", v122_management_view)

	var bottom = hud.panel(Rect2(98, 842, 1725, 210) if touch_ui else Rect2(98, 888, 1725, 124), Color("#100e14e8"), Color("#3b3143"), "", "flat")
	var primary_y := 28.0 if touch_ui else 20.0
	var primary_height := 142.0 if touch_ui else 86.0
	var build_label = "건설 취소" if root.build_pick_mode else "건설"
	var build_callback = Callable(root, "_build_selected_slot")
	if root.build_pick_mode and root.has_method("_build_preview_ready") and root._build_preview_ready():
		build_label = "건설 확정"
		build_callback = Callable(root, "_confirm_build_preview")
	var build_button = hud.button(bottom, build_label, Rect2(18, primary_y, 250, primary_height), build_callback, 20, "BuildButton")
	if root.build_pick_mode:
		build_button.add_theme_stylebox_override("normal", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 2))
	var monster_button = hud.button(bottom, "몬스터", Rect2(288, primary_y, 250, primary_height), Callable(root, "_open_monster_screen"), 20, "MonsterManagementButton")
	var start_label := "방어 시작"
	var start_callback := Callable(root, "_request_combat_start")
	var standard_defense_action := true
	if root.campaign_postgame_active:
		start_label = "엔딩 다시 보기"
		start_callback = Callable(root, "_show_campaign_ending")
		standard_defense_action = false
	elif bool(campaign_info.get("management_only", false)):
		start_label = str(campaign_info.get("management_only_start_label", "준비 확정"))
		start_callback = Callable(root, "_confirm_management_only_day")
		standard_defense_action = false
	elif root.has_method("_update4_outpost_battle_day") and root._update4_outpost_battle_day():
		standard_defense_action = false
	var start_button = hud.button(bottom, start_label, Rect2(558, primary_y, 330, primary_height), start_callback, 22, "StartCombatButton")
	var start_state: Dictionary = v122_management_view.get("start", {})
	if standard_defense_action:
		start_button.disabled = not bool(start_state.get("can_start", false))
		start_button.tooltip_text = str(start_state.get("blocked_reason", "")) if start_button.disabled else "3초 뒤 현재 배치로 방어를 시작합니다."
	var text_x := 930
	var guide_width := 300
	var final_declaration_required: bool = root.has_method("_campaign_final_declaration_required") and bool(root._campaign_final_declaration_required())
	var final_rival_name := str(campaign_info.get("final_rival_name", "레온"))
	if final_declaration_required:
		var declaration_id: String = str(root._campaign_final_declaration_id())
		var armistice_available: bool = root.has_method("_campaign_armistice_request_available") and bool(root._campaign_armistice_request_available())
		var declaration_width := 92.0 if armistice_available else 102.0
		var rival_button = hud.button(bottom, "라이벌\n약속", Rect2(908, primary_y, declaration_width, primary_height), Callable(root, "_set_campaign_final_declaration").bind("rival_pact"), 14, "RivalPactButton")
		var castle_button = hud.button(bottom, "성\n수호", Rect2(908 + declaration_width + 6, primary_y, declaration_width, primary_height), Callable(root, "_set_campaign_final_declaration").bind("castle_oath"), 14, "CastleOathButton")
		var armistice_button: Button
		if armistice_available:
			armistice_button = hud.button(bottom, "휴전문\n제안", Rect2(1104, primary_y, 110, primary_height), Callable(root, "_set_campaign_final_declaration").bind("grand_armistice_request"), 14, "ArmisticeRequestButton")
		if declaration_id == "rival_pact":
			rival_button.add_theme_stylebox_override("normal", hud.style(Color("#3a244bee"), Color("#ffd36a"), 2))
		elif declaration_id == "castle_oath":
			castle_button.add_theme_stylebox_override("normal", hud.style(Color("#3a244bee"), Color("#ffd36a"), 2))
		elif declaration_id == "grand_armistice_request" and armistice_button != null:
			armistice_button.add_theme_stylebox_override("normal", hud.style(Color("#3a244bee"), Color("#ffd36a"), 2))
		start_button.disabled = root._campaign_final_declaration_pending()
		if start_button.disabled:
			start_button.text = "선언 후 확정"
		text_x = 1234 if armistice_available else 1150
		guide_width = 456 if armistice_available else 520
	elif root.has_method("_update4_council_mode_active") and root._update4_council_mode_active():
		var outpost_button = hud.button(bottom, "전초기지", Rect2(908, primary_y, 170, primary_height), Callable(root, "_open_update4_outpost_management"), 17, "OutpostManagementButton")
		outpost_button.disabled = str(root.update4_active_run.get("outpost", {}).get("type_id", "")) == ""
		var upper_button = hud.button(bottom, "상층 왕성", Rect2(1088, primary_y, 170, primary_height), Callable(root, "_open_update4_upper_floor"), 17, "UpperFloorButton")
		upper_button.disabled = not bool(root.update4_active_run.get("upper_floor", {}).get("unlocked", false))
		text_x = 1290
		guide_width = 390
		if root.has_method("_update4_required_choice_pending") and root._update4_required_choice_pending():
			start_button.disabled = true
			start_button.text = "의회 결정 후 전투"
	elif root.has_method("_raid_unlocked") and root._raid_unlocked():
		var raid_button = hud.button(bottom, "원정", Rect2(908, primary_y, 210, primary_height), Callable(root, "_open_raid_screen"), 20, "RaidButton")
		if root.has_method("_campaign_raid_choice_pending") and root._campaign_raid_choice_pending():
			raid_button.text = root._campaign_required_raid_choice_label() if root.has_method("_campaign_required_raid_choice_label") else "원정 선택"
			raid_button.add_theme_stylebox_override("normal", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 2))
			raid_button.add_theme_color_override("font_color", Color("#fff2c9"))
			start_button.text = root._campaign_required_raid_choice_start_label() if root.has_method("_campaign_required_raid_choice_start_label") else "원정 선택 후 전투"
		text_x = 1150
		guide_width = 250
	if touch_ui:
		if root.has_method("_early_specialization_required_for_current_day") and root._early_specialization_required_for_current_day():
			monster_button.text = "전술 특화"
			monster_button.add_theme_stylebox_override("normal", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 3))
			start_button.text = "특화 후 전투"
		_build_touch_directive_bar()
		return
	hud.label(bottom, "준비 순서", Vector2(text_x, 18), Vector2(120, 24), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var guide_text = "시설을 고르고 배치한 뒤 몬스터 위치와 지침을 확인하고 전투를 시작합니다."
	var specialization_required := false
	var show_helper := true
	if root.has_method("_raid_unlocked") and root._raid_unlocked():
		guide_text = "원정으로 악명과 다음 방어 영향을 만들고, 관리 화면에서 배치를 정비합니다."
	if not campaign_info.is_empty() and str(campaign_info.get("management_hint", "")) != "":
		guide_text = str(campaign_info.get("management_hint", ""))
		guide_width = 520
		show_helper = false
	if bool(campaign_info.get("management_only", false)):
		guide_text = str(campaign_info.get("management_only_prompt", guide_text))
	if final_declaration_required:
		show_helper = false
		var selected_declaration: String = str(root._campaign_final_declaration_id())
		var armistice_available: bool = root.has_method("_campaign_armistice_request_available") and bool(root._campaign_armistice_request_available())
		if selected_declaration == "":
			guide_text = "최후 선언을 하나 선택하세요. 라이벌 약속은 라이벌 %s에게 다음 대결을 약속하며, 성 수호는 마왕성 방어를 우선합니다." % final_rival_name
			if armistice_available:
				guide_text = "최후 선언을 선택하세요. 세 전선의 신뢰를 모두 얻었다면 '휴전문 제안'으로 대통합 엔딩에 도전할 수 있습니다."
		elif selected_declaration == "rival_pact":
			guide_text = "선택됨: 라이벌 %s에게 다음 대결 약속 · 최종 준비를 확정할 수 있습니다." % final_rival_name
		elif selected_declaration == "grand_armistice_request":
			guide_text = "선택됨: 세 전선에 대휴전문 제안 · 최종 준비를 확정할 수 있습니다."
		else:
			guide_text = "선택됨: 마왕성과 식구 수호 · 최종 준비를 확정할 수 있습니다."
	if root.campaign_postgame_active:
		guide_text = "Stage 04와 열한 구역을 유지한 후일담 관리 모드입니다. 전투 시작 자리에서 엔딩을 다시 볼 수 있습니다."
		guide_width = 520
		show_helper = false
	if root.has_method("_campaign_raid_choice_pending") and root._campaign_raid_choice_pending():
		guide_text = root._campaign_required_raid_choice_prompt() if root.has_method("_campaign_required_raid_choice_prompt") else "[원정 선택]에서 오늘 계획 하나를 먼저 확정하세요."
	if root.has_method("_early_specialization_required_for_current_day") and root._early_specialization_required_for_current_day():
		specialization_required = true
		monster_button.text = "전술 특화"
		monster_button.add_theme_stylebox_override("normal", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 2))
		monster_button.add_theme_color_override("font_color", Color("#fff2c9"))
		start_button.text = "특화 후 전투"
		guide_text = "몬스터 메뉴에서 한 명의 전술 특화를 확정하면 전투를 시작할 수 있습니다."
	var guide_label: RichTextLabel = hud.rich_label(
		bottom,
		guide_text,
		Vector2(text_x, 44),
		Vector2(guide_width, 62),
		13 if guide_width < 300 else 15,
		Color("#d8d1df"),
		UIFontScript.ROLE_BODY,
		TextServer.AUTOWRAP_ARBITRARY,
		VERTICAL_ALIGNMENT_TOP,
		"ManagementGuideText"
	)
	guide_label.name = "ManagementGuideText"
	var chronicle_action: Dictionary = V122ManagementViewModelScript.action(v122_management_view, "chronicle")
	var chronicle_button = hud.button(bottom, str(chronicle_action.get("label", "전선 연대기")), Rect2(1430, 12, 270, 38), Callable(root, str(chronicle_action.get("callback", "_open_chronicle"))), 15, "ChronicleButton")
	chronicle_button.tooltip_text = str(chronicle_action.get("tooltip", ""))
	var duo_action: Dictionary = V122ManagementViewModelScript.action(v122_management_view, "duo_loadout")
	if not duo_action.is_empty() and bool(duo_action.get("visible", false)):
		var duo_loadout_button = hud.button(bottom, str(duo_action.get("label", "합동기 편성 변경")), Rect2(1430, 56, 270, 42), Callable(root, str(duo_action.get("callback", "_open_update3_duo_link_loadout"))), 14, "DuoLoadoutEditButton")
		duo_loadout_button.tooltip_text = str(duo_action.get("tooltip", ""))
		show_helper = false
	var helper = "몬스터는 맵 위에서 드래그\n또는 오른쪽 패널 이름 클릭"
	if root.map_editor_active:
		helper = "방에서 방으로 드래그\n연결된 길은 드래그로 해제"
	elif root._management_action_mode_active():
		if root.build_pick_mode and root.has_method("_build_preview_ready") and root._build_preview_ready():
			helper = "%s\n왼쪽에서 건설 확정\nESC 취소" % root._management_action_mode_title()
		else:
			helper = "%s\n맵에서 대상 클릭\nESC 취소" % root._management_action_mode_title()
	if not specialization_required and show_helper:
		hud.label(bottom, helper, Vector2(1430, 54), Vector2(270, 52), 12, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_ARBITRARY, 3)

func _build_touch_directive_bar() -> void:
	var bar = hud.panel(Rect2(330, 640, 1260, 190), Color("#08060cf7"), Color("#ffd36a"), "MobileManagementDirectiveBar", "flat")
	bar.name = "MobileManagementDirectiveBar"
	hud.label(bar, "전체 지침", Vector2(24, 8), Vector2(650, 34), 23, Color("#fff2c9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(bar, "선택 방 · %s" % root.display_name_for_instance(root.selected_room), Vector2(704, 8), Vector2(532, 34), 23, Color("#fff2c9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var global_options := [
		{"label": "사수", "value": Constants.DIRECTIVE_DEFENSE, "target": "GLOBAL_DIRECTIVE_DEFEND"},
		{"label": "총공격", "value": Constants.DIRECTIVE_ALL_OUT, "target": ""},
		{"label": "생존 우선", "value": Constants.DIRECTIVE_SURVIVAL, "target": ""}
	]
	for index in range(global_options.size()):
		var option: Dictionary = global_options[index]
		var global_button = hud.button(bar, str(option["label"]), Rect2(20 + index * 220, 48, 204, 126), Callable(root, "_set_global_directive").bind(str(option["value"])), 22, str(option["target"]))
		if str(option["value"]) == root.global_directive:
			global_button.add_theme_stylebox_override("normal", hud.style(Color("#3b2630f7"), Color("#fff2a8"), 4))
	var room_options: Array = root._room_directive_options(root.selected_room)
	var room_area_width := 532.0
	var room_gap := 10.0
	var room_button_width := (room_area_width - room_gap * maxf(0.0, room_options.size() - 1.0)) / maxf(1.0, room_options.size())
	for index in range(room_options.size()):
		var option: Dictionary = room_options[index]
		var value := str(option.get("value", ""))
		var target_id := ""
		match value:
			Constants.ROOM_DIRECTIVE_ENTRY_BLOCK:
				target_id = "ROOM_DIRECTIVE_BLOCK_ENTRANCE"
			Constants.ROOM_DIRECTIVE_TRAP_LURE:
				target_id = "ROOM_DIRECTIVE_TRAP_LURE"
			Constants.ROOM_DIRECTIVE_RETREAT:
				target_id = "ROOM_DIRECTIVE_RETREAT_LINE"
		var room_button = hud.button(bar, str(option.get("label", value)), Rect2(704 + index * (room_button_width + room_gap), 48, room_button_width, 126), Callable(root, "_set_room_directive").bind(value), 19, target_id)
		if value == str(root.room_directives.get(root.selected_room, Constants.ROOM_DIRECTIVE_NONE)):
			room_button.add_theme_stylebox_override("normal", hud.style(Color("#3b2630f7"), Color("#fff2a8"), 4))

func _build_campaign_notice() -> void:
	if not root.has_method("_campaign_day_info"):
		return
	var info: Dictionary = root._campaign_day_info()
	if info.is_empty():
		return
	var compact := UISettings.is_compact_layout() and not UISettings.is_touch_ui()
	var notice_rect := Rect2(292, 80, 1224, 76) if compact else Rect2(346, 88, 1138, 96)
	var notice = hud.panel(notice_rect, Color("#0c0a11d8"), Color("#6e5630"), "CampaignNotice", "flat")
	notice.name = "CampaignNotice"
	notice.set_meta("layout_mode", UISettings.effective_layout_mode())
	var title_label: Label = hud.label(notice, str(info.get("title", "DAY %d" % GameState.day)), Vector2(18, 10), Vector2(332, 24), 18 if not compact else 19, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	title_label.name = "CampaignNoticeTitle"
	if root.has_method("_castle_stage_display_line"):
		var stage_badge = hud.child_panel(notice, Rect2(360, 8, 256, 28), Color("#24172eed"), Color("#8f66b5"), 1)
		stage_badge.name = "CampaignNoticeStage"
		var area_text: String = root._castle_area_summary() if root.has_method("_castle_area_summary") else ""
		hud.label(stage_badge, "%s | %s" % [root._castle_stage_display_line(), area_text], Vector2(5, 3), Vector2(246, 22), 10, Color("#ead9ff"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var summary = root._campaign_notice_summary() if root.has_method("_campaign_notice_summary") else str(info.get("summary", ""))
	var summary_rect := Rect2(18, 38, 1188, 28) if compact else Rect2(18, 38, 596, 44)
	var summary_label: RichTextLabel = hud.rich_label(notice, summary, summary_rect.position, summary_rect.size, 15 if compact else 14, Color("#f4e7d2"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_ARBITRARY, VERTICAL_ALIGNMENT_CENTER)
	summary_label.name = "CampaignNoticeSummary"
	if compact:
		return
	var cast_line = root._campaign_notice_cast_line() if root.has_method("_campaign_notice_cast_line") else ""
	var enemy_line = root._campaign_notice_enemy_line() if root.has_method("_campaign_notice_enemy_line") else ""
	var monster_line = root._campaign_notice_monster_line() if root.has_method("_campaign_notice_monster_line") else ""
	_build_campaign_cast_portraits(notice, info)
	var cast_label: Label = hud.label(notice, cast_line, Vector2(844, 12), Vector2(258, 20), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 1)
	cast_label.name = "CampaignNoticeCast"
	var enemy_label: Label = hud.label(notice, enemy_line, Vector2(844, 38), Vector2(258, 22), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 1)
	enemy_label.name = "CampaignNoticeEnemy"
	var monster_label: Label = hud.label(notice, monster_line, Vector2(844, 64), Vector2(258, 20), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 1)
	monster_label.name = "CampaignNoticeMonster"

func _build_campaign_cast_portraits(parent: Control, info: Dictionary) -> void:
	if not root.has_method("_campaign_speaker_portrait_path"):
		return
	var cast: Array = info.get("cast", [])
	var portrait_x := 628
	for index in range(mini(cast.size(), 3)):
		var entry = cast[index]
		if not (entry is Dictionary):
			continue
		var character_id = str(entry.get("character_id", ""))
		var emotion = str(entry.get("emotion", ""))
		var portrait_path = root._campaign_speaker_portrait_path(character_id, emotion)
		if portrait_path == "":
			continue
		var accent = root._campaign_speaker_accent(character_id) if root.has_method("_campaign_speaker_accent") else Color("#57485e")
		var frame = hud.child_panel(parent, Rect2(portrait_x + index * 68, 14, 58, 58), Color("#130f19f0"), accent, 1)
		frame.name = "CampaignNoticePortrait%d" % index
		var portrait = hud.texture(frame, portrait_path, Rect2(4, 4, 50, 50))
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

func _build_layout_selector() -> void:
	var layout_ids: Array = DataRegistry.quarter_layout_ids()
	if layout_ids.is_empty():
		return
	var panel = hud.panel(Rect2(16, 530, 300, 342), Color("#08070def"), Color("#57485e"), "", "flat")
	hud.label(panel, "맵 커스텀", Vector2(0, 12), Vector2(300, 32), 24, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	if root.map_editor_active:
		_build_map_editor_controls(panel)
		return
	if root.build_pick_mode:
		hud.label(panel, "건설 모드", Vector2(18, 66), Vector2(264, 28), 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(panel, "맵 클릭은 후보 지정입니다.\n확정 전에는 비용을 쓰지 않습니다.", Vector2(18, 100), Vector2(264, 48), 13, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		var summary = root._build_preview_summary() if root.has_method("_build_preview_summary") else "맵에서 후보 방을 클릭하세요."
		var route_line = root._build_preview_route_line() if root.has_method("_build_preview_route_line") else ""
		var effect_line = root._build_preview_effect_line() if root.has_method("_build_preview_effect_line") else ""
		hud.label(panel, summary, Vector2(18, 158), Vector2(264, 24), 13, Color("#fff2c9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 1)
		hud.label(panel, route_line, Vector2(18, 188), Vector2(264, 38), 11, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		hud.label(panel, effect_line, Vector2(18, 230), Vector2(264, 38), 11, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		var confirm_button = hud.button(panel, "건설 확정", Rect2(18, 276, 126, 34), Callable(root, "_confirm_build_preview"), 13)
		confirm_button.disabled = not root._build_preview_ready()
		hud.button(panel, "취소", Rect2(156, 276, 126, 34), Callable(root, "_cancel_management_action_mode"), 13)
		hud.label(panel, "현재 선택  %s" % root.display_name_for_instance(root.selected_room), Vector2(18, 318), Vector2(264, 18), 10, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	if root._management_action_mode_active():
		hud.label(panel, root._management_action_mode_title(), Vector2(18, 54), Vector2(264, 28), 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(panel, root._management_action_mode_help(), Vector2(18, 94), Vector2(264, 96), 13, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 4)
		hud.label(panel, "선택 가능 대상은\n맵 위에 밝게 표시됩니다.", Vector2(18, 202), Vector2(264, 48), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		hud.button(panel, "작업 취소", Rect2(18, 276, 264, 40), Callable(root, "_cancel_management_action_mode"), 15)
		return

	hud.label(panel, "길은 맵에서 직접 드래그합니다.\n방에서 방으로 끌면 연결,\n연결된 방끼리는 해제됩니다.", Vector2(18, 46), Vector2(264, 72), 12, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_ARBITRARY, 3)
	var y = 124
	var shown_count = mini(layout_ids.size(), 3)
	for index in range(shown_count):
		var layout_id = str(layout_ids[index])
		var layout: Dictionary = DataRegistry.quarter_layout(str(layout_id))
		var grade = str(layout.get("castle_grade", "?"))
		var label = str(layout.get("layout_label", ""))
		var display_name = str(layout.get("display_name", layout_id))
		var title_prefix = label if label != "" else "%s급" % grade
		var title = "%s  %s" % [title_prefix, display_name]
		var layout_button = hud.button(panel, title, Rect2(18, y, 264, 30), Callable(root, "_select_quarter_layout").bind(str(layout_id)), 12)
		if str(layout_id) == root.quarter_layout_id:
			layout_button.disabled = true
			layout_button.add_theme_stylebox_override("disabled", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 2))
			layout_button.add_theme_color_override("font_disabled_color", Color("#ffd36a"))
		y += 33
	if layout_ids.size() > shown_count:
		hud.label(panel, "+%d" % (layout_ids.size() - shown_count), Vector2(244, 54), Vector2(38, 24), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(panel, "현재 선택  %s" % root.display_name_for_instance(root.selected_room), Vector2(18, 254), Vector2(264, 22), 12, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

func _build_map_editor_controls(panel: Control) -> void:
	var room_name = root.display_name_for_instance(root.selected_room)
	if UISettings.is_touch_ui():
		hud.label(panel, "연결된 길 위에 방 확장", Vector2(28, 72), Vector2(464, 46), 24, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(panel, "시작 방  %s" % room_name, Vector2(28, 122), Vector2(464, 42), 20, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
		hud.label(panel, "금색 입구→왕좌 길은 항상 유지됩니다.\n방에서 방으로 끌어 확장 길을 더하세요.", Vector2(28, 168), Vector2(464, 62), 18, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		hud.label(panel, "추천  %s" % root._map_editor_path_candidate_line(), Vector2(28, 236), Vector2(464, 66), 17, Color("#cfc4dc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		hud.button(panel, "추천 자동 연결", Rect2(28, 310, 464, 112), Callable(root, "_map_editor_auto_connect_current_candidate"), 21)
		hud.button(panel, "선택 확장선 해제", Rect2(28, 434, 226, 112), Callable(root, "_map_editor_disconnect_selected_room"), 18)
		hud.button(panel, "통로 삭제", Rect2(266, 434, 226, 112), Callable(root, "_map_editor_delete_selected_path"), 18)
		hud.button(panel, "저장", Rect2(28, 558, 226, 120), Callable(root, "_save_map_editor_layout"), 22)
		hud.button(panel, "취소", Rect2(266, 558, 226, 120), Callable(root, "_cancel_map_editor"), 22)
		hud.label(panel, root._map_editor_status_line(), Vector2(28, 690), Vector2(464, 84), 17, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3)
		return
	hud.label(panel, "연결된 길 위에 방 확장", Vector2(18, 44), Vector2(264, 28), 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(panel, "시작 방  %s" % room_name, Vector2(18, 74), Vector2(264, 22), 14, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(panel, "금색 입구→왕좌 길은 항상 유지됩니다.\n방을 끌어 확장 길을 더하세요.", Vector2(18, 100), Vector2(264, 54), 12, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	hud.label(panel, "추천  %s" % root._map_editor_path_candidate_line(), Vector2(18, 160), Vector2(264, 34), 10, Color("#cfc4dc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	hud.button(panel, "추천 자동 연결", Rect2(18, 202, 264, 34), Callable(root, "_map_editor_auto_connect_current_candidate"), 14)
	hud.button(panel, "확장선 해제", Rect2(18, 244, 126, 30), Callable(root, "_map_editor_disconnect_selected_room"), 12)
	hud.button(panel, "통로 삭제", Rect2(156, 244, 126, 30), Callable(root, "_map_editor_delete_selected_path"), 12)
	hud.button(panel, "저장", Rect2(18, 284, 126, 34), Callable(root, "_save_map_editor_layout"), 13)
	hud.button(panel, "취소", Rect2(156, 284, 126, 34), Callable(root, "_cancel_map_editor"), 13)
	hud.label(panel, root._map_editor_status_line(), Vector2(18, 320), Vector2(264, 20), 10, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)

func build_monster_ui() -> void:
	hud.build_top_bar()
	if root.has_method("_ensure_selected_monster_available_for_defense"):
		root._ensure_selected_monster_available_for_defense()
	var monster_ids: Array = root.monster_roster.keys()
	if root.has_method("_defense_monster_ids"):
		monster_ids = root._defense_monster_ids()
	var left = hud.panel(Rect2(24, 104, 400, 846), Color("#0b0a0fe8"), Color("#4c4354"), "", "flat")
	hud.label(left, "보유 몬스터", Vector2(24, 20), Vector2(352, 38), 25, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var y = 82
	for monster_id in monster_ids:
		var data = DataRegistry.monster(monster_id)
		var roster = root.monster_roster[monster_id]
		var scaled_stats = root._scaled_monster_stats(monster_id) if root.has_method("_scaled_monster_stats") else data
		var display_name = root._monster_display_name(monster_id) if root.has_method("_monster_display_name") else str(data.get("display_name", monster_id))
		var suffix = "  Lv.%d  HP %d  유대 %d" % [int(roster["level"]), int(scaled_stats.get("max_hp", 1)), int(roster.get("bond", 0))]
		if root.has_method("_growth_preparation_active") and root._growth_preparation_active(monster_id):
			suffix += "  ·  준비"
		var monster_button = hud.button(left, "%s%s" % [display_name, suffix], Rect2(24, y, 352, 58), Callable(root, "_select_monster").bind(monster_id), 17, _tutorial_monster_target_id(monster_id))
		if monster_id == root.selected_monster_id:
			monster_button.add_theme_stylebox_override("normal", hud.style(Color("#241b2eee"), Color("#a882c4"), 2))
			monster_button.add_theme_color_override("font_color", Color("#f0d8ff"))
		y += 70
	var support_line := ""
	if root.has_method("_support_only_monster_line"):
		support_line = root._support_only_monster_line()
	if support_line != "":
		hud.label(left, support_line, Vector2(24, min(y + 8, 660)), Vector2(352, 56), 14, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	hud.label(left, "배치는 관리 화면에서 변경합니다.", Vector2(24, 720), Vector2(352, 28), 14, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER)
	if root.has_method("_contract_roster_available") and root._contract_roster_available():
		hud.button(left, "출전·예비 편성", Rect2(92, 756, 216, 46), Callable(root, "_open_contract_roster"), 16)
		hud.button(left, "돌아가기", Rect2(92, 810, 216, 46), Callable(root, "_set_screen").bind(Constants.SCREEN_MANAGEMENT), 16)
	else:
		hud.button(left, "돌아가기", Rect2(92, 766, 216, 54), Callable(root, "_set_screen").bind(Constants.SCREEN_MANAGEMENT), 18)

	var center = hud.panel(Rect2(448, 104, 854, 846), Color("#0c0b10dc"), Color("#4c4354"), "", "flat")
	if root.selected_monster_id == "" or not root.monster_roster.has(root.selected_monster_id):
		hud.label(center, "배치 가능한 방어 몬스터가 없습니다.", Vector2(120, 360), Vector2(614, 60), 24, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	var monster = DataRegistry.monster(root.selected_monster_id)
	var selected_stats = root._scaled_monster_stats(root.selected_monster_id) if root.has_method("_scaled_monster_stats") else monster
	var roster: Dictionary = root.monster_roster[root.selected_monster_id]
	var selected_display_name = root._monster_display_name(root.selected_monster_id) if root.has_method("_monster_display_name") else str(monster.get("display_name", root.selected_monster_id))
	hud.label(center, selected_display_name, Vector2(36, 24), Vector2(782, 48), 34, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var active_evolution: Dictionary = root._monster_promotion_rule(root.selected_monster_id) if root.has_method("_monster_promotion_rule") else {}
	var monster_visual_path := str(monster.get("sprite", ""))
	if not active_evolution.is_empty() and str(active_evolution.get("portrait", "")) != "":
		monster_visual_path = str(active_evolution.get("portrait", ""))
	var monster_visual: TextureRect = hud.texture(center, monster_visual_path, Rect2(92, 116, 246, 246))
	if not active_evolution.is_empty():
		monster_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var role_name = str(roster.get("role_tag", monster.get("role", "")))
	var bond_value := int(roster.get("bond", 0))
	var bond_rank_name: String = str(root._monster_bond_rank_name(bond_value)) if root.has_method("_monster_bond_rank_name") else "유대"
	hud.label(center, "Lv.%d  ·  %s" % [int(roster["level"]), role_name], Vector2(58, 376), Vector2(314, 34), 22, Color("#d99bff"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(center, "배치 방  %s" % root.rooms[roster["room"]].get("display_name", roster["room"]), Vector2(58, 418), Vector2(314, 32), 18, Color("#d5cbe3"), HORIZONTAL_ALIGNMENT_CENTER)
	var bond_icon: TextureRect = hud.texture(center, "res://assets/sprites/ui/legacy/ui_icon_bond.png", Rect2(50, 454, 34, 34))
	bond_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud.label(center, "%d/100 · %s" % [bond_value, bond_rank_name], Vector2(84, 458), Vector2(190, 28), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT)
	var memory_icon: TextureRect = hud.texture(center, "res://assets/sprites/ui/legacy/ui_icon_memory.png", Rect2(278, 454, 34, 34))
	memory_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud.label(center, "%d개" % roster.get("unlocked_memory_ids", []).size(), Vector2(312, 458), Vector2(70, 28), 15, Color("#c9a5ff"), HORIZONTAL_ALIGNMENT_LEFT)
	var stat_panel = hud.child_panel(center, Rect2(400, 112, 406, 300), Color("#100e14c8"), Color("#403846"), 1)
	hud.label(stat_panel, "전투 능력", Vector2(20, 12), Vector2(366, 30), 20, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.build_stat_lines(stat_panel, selected_stats, roster)
	var growth_help = "전투에서 얻은 경험치로 성장하며 훈련은 즉시 능력치를 올립니다."
	var growth_help_color = Color("#bfb7cc")
	if root.has_method("_active_growth_preparation_line"):
		var preparation_line = root._active_growth_preparation_line(root.selected_monster_id)
		if preparation_line != "":
			growth_help = "%s\n이번 방어전이 끝나면 사라집니다." % preparation_line
			growth_help_color = Color("#ffd36a")
	hud.label(center, growth_help, Vector2(74, 500), Vector2(706, 70), 17, growth_help_color, HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	var training_reason := str(root._training_block_reason(root.selected_monster_id)) if root.has_method("_training_block_reason") else ""
	var training_button = hud.button(center, "훈련  금화 30" if training_reason == "" else training_reason, Rect2(72, 758, 220, 54), Callable(root, "_train_selected_monster"), 17)
	training_button.disabled = training_reason != ""
	hud.button(center, "기억 보기  %d개" % roster.get("unlocked_memory_ids", []).size(), Rect2(318, 758, 220, 54), Callable(root, "_open_selected_monster_memories"), 16, "MonsterMemoryButton")
	if root.has_method("_promotion_unlocked") and root._promotion_unlocked():
		_build_promotion_panel(center)

	var right = hud.panel(Rect2(1326, 104, 570, 846), Color("#0b0a0fe8"), Color("#4c4354"), "", "flat")
	hud.label(right, "스킬 슬롯", Vector2(24, 20), Vector2(522, 38), 25, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var skills: Array = monster.get("skill_slots", [])
	y = 78
	for skill_id in skills:
		var skill_panel = hud.child_panel(right, Rect2(24, y, 522, 104), Color("#100e14c8"), Color("#403846"), 1)
		if skill_id == null:
			hud.label(skill_panel, "잠금 슬롯", Vector2(18, 20), Vector2(486, 64), 18, Color("#7d7586"), HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var skill = DataRegistry.skill(str(skill_id))
			var skill_icon_path := str(skill.get("icon", ""))
			if skill_icon_path != "":
				var skill_icon: TextureRect = hud.texture(skill_panel, skill_icon_path, Rect2(10, 10, 84, 84))
				skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hud.label(skill_panel, skill.get("display_name", skill_id), Vector2(106, 10), Vector2(380, 28), 20, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
			hud.label(skill_panel, skill.get("description", ""), Vector2(106, 42), Vector2(380, 50), 14, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2, 11)
		y += 116
	_build_specialization_panel(right)

func build_memory_archive_ui() -> void:
	var screen = hud.panel(Rect2(0, 0, 1920, 1080), Color("#050407ff"), Color("#00000000"))
	if root.has_method("_onboarding_add_scene_illustration"):
		root._onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), "res://assets/ui/onboarding/scenes/scene_rookie_cave_start.png")
	var shade = hud.panel(Rect2(180, 70, 1560, 910), Color("#09070de8"), Color("#9b6a27"), "", "flat")
	var monster_id: String = str(root.selected_monster_id)
	var roster: Dictionary = root.monster_roster.get(monster_id, {})
	var display_name: String = str(root._monster_display_name(monster_id)) if root.has_method("_monster_display_name") else monster_id
	var memory_ids: Array = roster.get("unlocked_memory_ids", [])
	hud.label(shade, "%s의 기억" % display_name, Vector2(0, 30), Vector2(1560, 52), 36, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(shade, "유대와 이전 회차에서 남은 기억은 성장 초기화 뒤에도 이야기로 이어집니다.", Vector2(0, 84), Vector2(1560, 32), 16, Color("#c6a968"), HORIZONTAL_ALIGNMENT_CENTER)
	var portrait_path := _memory_portrait_path(monster_id)
	var active_evolution: Dictionary = root._monster_promotion_rule(monster_id) if root.has_method("_monster_promotion_rule") else {}
	if not active_evolution.is_empty() and str(active_evolution.get("portrait", "")) != "":
		portrait_path = str(active_evolution.get("portrait", ""))
	var portrait_frame = hud.child_panel(shade, Rect2(60, 150, 350, 620), Color("#100d14f2"), Color("#57485e"), 1)
	var portrait: TextureRect = hud.texture(portrait_frame, portrait_path, Rect2(26, 28, 298, 298))
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bond := int(roster.get("bond", 0))
	hud.label(portrait_frame, "유대 %d/100" % bond, Vector2(24, 354), Vector2(302, 34), 22, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(portrait_frame, str(root._monster_bond_rank_name(bond)) if root.has_method("_monster_bond_rank_name") else "동료", Vector2(24, 394), Vector2(302, 30), 18, Color("#d99bff"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(portrait_frame, "해금된 기억 %d개" % memory_ids.size(), Vector2(24, 452), Vector2(302, 28), 16, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER)
	var memory_icon: TextureRect = hud.texture(portrait_frame, "res://assets/sprites/ui/legacy/ui_icon_memory.png", Rect2(121, 500, 108, 108))
	memory_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(450, 150)
	scroll.size = Vector2(1050, 650)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shade.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 1024
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	if memory_ids.is_empty():
		hud.label(list, "아직 해금된 기억이 없습니다.\n함께 방어하고 원정을 마치면 유대 단계마다 새로운 기억이 열립니다.", Vector2.ZERO, Vector2(1024, 180), 21, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 4)
	else:
		for memory_id_value in memory_ids:
			_build_memory_card(list, str(memory_id_value))
	hud.button(shade, "몬스터 화면으로", Rect2(600, 826, 360, 58), Callable(root, "_set_screen").bind(Constants.SCREEN_MONSTER), 19)

func _build_memory_card(parent: Control, memory_id: String) -> void:
	var entry := DataRegistry.memory_entry(memory_id)
	var card = hud.child_panel(parent, Rect2(Vector2.ZERO, Vector2(1024, 164)), Color("#15111bf2"), Color("#6e5630"), 1)
	card.custom_minimum_size = Vector2(1024, 164)
	var title := str(entry.get("title", "기록되지 않은 기억"))
	var source_cycle := int(entry.get("source_cycle", 0))
	if source_cycle > 0:
		title = "%s · %d회차" % [title, source_cycle]
	hud.label(card, title, Vector2(28, 16), Vector2(968, 30), 21, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(card, str(entry.get("summary", "기억의 내용이 아직 기록되지 않았습니다.")), Vector2(28, 52), Vector2(968, 54), 16, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3)
	hud.label(card, "“%s”" % str(entry.get("quote", "...")), Vector2(42, 112), Vector2(940, 34), 15, Color("#c9a5ff"), HORIZONTAL_ALIGNMENT_LEFT)

func _memory_portrait_path(monster_id: String) -> String:
	return {
		"slime": "res://assets/sprites/portraits/onboarding/portrait_pudding.png",
		"goblin": "res://assets/sprites/portraits/onboarding/portrait_gob.png",
		"imp": "res://assets/sprites/portraits/onboarding/portrait_pynn.png",
		"kobold_scout": "res://assets/sprites/portraits/onboarding/portrait_rolo.png"
	}.get(monster_id, "res://assets/sprites/ui/legacy/ui_icon_memory.png")

func _build_specialization_panel(right: Control) -> void:
	hud.label(right, "전술 특화", Vector2(28, 444), Vector2(180, 30), 19, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	if not root.has_method("_early_specialization_unlocked") or not root._early_specialization_unlocked():
		hud.label(right, "DAY 2에 해금됩니다.", Vector2(226, 444), Vector2(316, 30), 14, Color("#8f8799"), HORIZONTAL_ALIGNMENT_RIGHT)
		return
	var active_rule: Dictionary = root._monster_specialization(root.selected_monster_id)
	if not active_rule.is_empty():
		hud.label(right, "선택 확정됨", Vector2(226, 444), Vector2(316, 30), 13, Color("#be72ff"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)
		var active_panel = hud.child_panel(right, Rect2(28, 488, 514, 138), Color("#15101bd8"), Color("#78558f"), 1)
		hud.label(active_panel, str(active_rule.get("display_name", "특화 완료")), Vector2(18, 14), Vector2(478, 30), 19, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(active_panel, str(active_rule.get("description", "")), Vector2(18, 50), Vector2(478, 72), 15, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 3)
		return
	var options = root._specializations_for_monster(root.selected_monster_id)
	var reason = root._specialization_block_reason(root.selected_monster_id)
	var status = "선택 후 변경 불가"
	if reason != "":
		status = reason
	hud.label(right, status, Vector2(226, 444), Vector2(316, 30), 13, Color("#a99fba"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_BODY)
	var y := 490
	for option in options:
		var specialization_id = str(option.get("id", ""))
		var option_text = "%s  |  %s" % [str(option.get("display_name", specialization_id)), str(option.get("short_effect", ""))]
		var option_button = hud.button(right, option_text, Rect2(28, y, 514, 54), Callable(root, "_choose_early_specialization").bind(root.selected_monster_id, specialization_id), 14)
		option_button.disabled = not root._can_choose_early_specialization(root.selected_monster_id, specialization_id)
		option_button.tooltip_text = str(option.get("description", ""))
		y += 64

func _build_promotion_panel(center: Control) -> void:
	var active_rule: Dictionary = root._monster_promotion_rule(root.selected_monster_id)
	if not active_rule.is_empty():
		var active_summary = root._selected_promotion_summary() if root.has_method("_selected_promotion_summary") else "진화 완료"
		hud.label(center, active_summary, Vector2(150, 608), Vector2(560, 54), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		var completed_button = hud.button(center, "진화 완료", Rect2(317, 686, 220, 54), Callable(), 13, "PromotionButton")
		completed_button.disabled = true
		return
	var options: Array = root._evolution_rules_for_monster(root.selected_monster_id)
	if options.is_empty():
		hud.label(center, "아직 진화 분기가 없습니다.", Vector2(150, 620), Vector2(560, 42), 14, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	hud.label(center, "진화 분기 · 선택 후 변경할 수 없습니다.", Vector2(150, 608), Vector2(560, 34), 14, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var option_width := 290.0
	var gap := 18.0
	var total_width := option_width * float(options.size()) + gap * float(maxi(0, options.size() - 1))
	var start_x := (854.0 - total_width) * 0.5
	for index in range(options.size()):
		var option: Dictionary = options[index]
		var rule_id := str(option.get("id", ""))
		var reason: String = str(root._promotion_block_reason(root.selected_monster_id, rule_id))
		var subline: String = str(root._cost_label(option.get("cost", {}))) if reason == "" else reason
		var option_button = hud.button(center, "%s\n%s" % [str(option.get("display_name", rule_id)), subline], Rect2(start_x + float(index) * (option_width + gap), 660, option_width, 80), Callable(root, "_promote_monster").bind(root.selected_monster_id, rule_id), 13, "PromotionOption%d" % index)
		option_button.disabled = not root._can_promote_monster(root.selected_monster_id, rule_id)
		option_button.tooltip_text = "%s\n%s" % [str(option.get("role_summary", "")), str(option.get("balance_note", ""))]
		var option_icon_path := str(option.get("icon", ""))
		if option_icon_path != "":
			var option_icon: TextureRect = hud.texture(center, option_icon_path, Rect2(start_x + float(index) * (option_width + gap) + 10, 674, 52, 52))
			option_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if option_button.disabled:
			option_button.add_theme_color_override("font_disabled_color", Color("#a99fba"))

func build_result_ui() -> void:
	var touch_ui := UISettings.is_touch_ui()
	var v122_result_view: Dictionary = V122CombatResultViewModelScript.build_result(
		root.result_summary,
		root.result_summary.get("v122_ledger", {}),
		{
			"rewards": root.rewards_pending,
			"story_preserved": true,
			"meta_progress_preserved": true,
			"ending_preserved": true,
			"next_day_preserved": true
		}
	)
	root.set_meta("v122_result_view_model", v122_result_view)
	var result_win := bool(root.result_summary.get("win", false))
	var management_only_result := bool(root.result_summary.get("management_only", false))
	var outpost_battle_result := bool(root.result_summary.get("outpost_battle", false))
	var result_day_info: Dictionary = root._campaign_day_info() if root.has_method("_campaign_day_info") else {}
	var final_battle_result := bool(result_day_info.get("final_battle", false))
	var title := "방어 성공" if result_win else "방어 실패"
	if management_only_result:
		title = "최종 준비 완료"
	elif outpost_battle_result:
		title = "전초기지 방어 성공" if result_win else "전초기지 패배 수용"
	elif final_battle_result:
		title = "최종 공성 방어 성공" if result_win else "최종 공성 방어 실패"
	if GameState.victory:
		title = "첫 장 클리어"
	var castle_evolved: bool = root.has_method("_castle_evolution_completed_today") and bool(root._castle_evolution_completed_today())
	if castle_evolved and result_win:
		title = "방어 성공 · 마왕성 진화"
		if root.has_method("_castle_stage_index") and int(root._castle_stage_index()) == 4:
			title = "방어 성공 · 대마왕성 완성"

	var result_screen: Panel = hud.panel(Rect2(0, 0, 1920, 1080), Color("#050407ff"), Color("#050407ff"), "V122ResultScreen", "flat")
	result_screen.name = "V122ResultScreen"
	hud.label(result_screen, title, Vector2(420, 72), Vector2(1080, 66), 44, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var primary_cause := str(v122_result_view.get("primary_cause_label", "")).trim_prefix("핵심 원인 · ").trim_prefix("핵심 결과 · ")
	hud.label(
		result_screen,
		primary_cause,
		Vector2(460, 140),
		Vector2(1000, 36),
		18,
		Color("#cfc7d9"),
		HORIZONTAL_ALIGNMENT_CENTER,
		"",
		UIFontScript.ROLE_BODY
	)

	var metrics_panel: Panel = hud.child_panel(result_screen, Rect2(250, 210, 760, 520), Color("#0d0b12f2"), Color("#80662f"), 2)
	metrics_panel.name = "ResultCoreMetrics"
	hud.label(metrics_panel, "전투 결산", Vector2(30, 20), Vector2(700, 38), 25, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var decision_feedback: Dictionary = v122_result_view.get("decision_feedback", {})
	var decision_line := "항상 같은 세 지표로 이번 방어를 비교합니다."
	var decision_color := Color("#aaa1b5")
	if not decision_feedback.is_empty():
		decision_line = "내 선택의 결과 · %s" % str(decision_feedback.get("summary", ""))
		decision_color = Color("#e5d2a2")
	var decision_label: Label = hud.label(
		metrics_panel,
		decision_line,
		Vector2(30, 56),
		Vector2(700, 40),
		14,
		decision_color,
		HORIZONTAL_ALIGNMENT_LEFT,
		"ResultDecisionFeedback",
		UIFontScript.ROLE_EMPHASIS,
		VERTICAL_ALIGNMENT_CENTER,
		TextServer.AUTOWRAP_WORD_SMART,
		2
	)
	decision_label.name = "ResultDecisionFeedback"
	var core_metrics: Array = v122_result_view.get("core_metrics", [])
	for index in range(mini(3, core_metrics.size())):
		var metric_value = core_metrics[index]
		if not metric_value is Dictionary:
			continue
		var metric: Dictionary = metric_value
		var metric_row: Panel = hud.child_panel(metrics_panel, Rect2(30, 102 + index * 92, 700, 76), Color("#17121df0"), Color("#403448"), 1)
		hud.label(metric_row, str(metric.get("label", "")), Vector2(18, 11), Vector2(310, 52), 18, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(metric_row, str(metric.get("value", "")), Vector2(340, 11), Vector2(342, 52), 22, Color("#fff2c9"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)

	var conditional_alerts: Array = v122_result_view.get("conditional_alerts", [])
	if not conditional_alerts.is_empty():
		hud.label(metrics_panel, "발생한 추가 손실", Vector2(30, 388), Vector2(700, 28), 15, Color("#ff9d8f"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		for alert_index in range(mini(2, conditional_alerts.size())):
			var alert_value = conditional_alerts[alert_index]
			if not alert_value is Dictionary:
				continue
			var alert: Dictionary = alert_value
			var alert_x := 30.0 + alert_index * 354.0
			var alert_row: Panel = hud.child_panel(metrics_panel, Rect2(alert_x, 424, 346, 58), Color("#251014ee"), Color("#a94444"), 1)
			hud.label(alert_row, str(alert.get("label", "")), Vector2(14, 8), Vector2(138, 42), 15, Color("#ffb1a7"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
			hud.label(alert_row, str(alert.get("value", "")), Vector2(158, 8), Vector2(174, 42), 17, Color("#fff0e8"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)

	var growth_panel: Panel = hud.child_panel(result_screen, Rect2(1050, 210, 620, 520), Color("#0d0c11f2"), Color("#4c4354"), 2)
	growth_panel.name = "ResultGrowthPanel"
	_build_growth_reward_panel(growth_panel, Rect2(Vector2.ZERO, growth_panel.size))
	var growth_choice_pending: bool = root.has_method("_result_growth_choice_required") and bool(root._result_growth_choice_required()) and not root.result_growth_choice_applied
	var show_growth_button: bool = result_win and not management_only_result and not outpost_battle_result and (
		growth_choice_pending
		or root.result_growth_choice_applied
		or not root.last_growth_summary.is_empty()
	)
	if show_growth_button:
		var growth_button_rect := Rect2(growth_panel.size.x - 294, growth_panel.size.y - 140, 260, 120) if touch_ui else Rect2(growth_panel.size.x - 274, growth_panel.size.y - 86, 230, 58)
		var growth_button: Button = hud.button(growth_panel, "성장 확인", growth_button_rect, Callable(root, "_review_growth_from_result"), 22 if touch_ui else 18, "GrowthReviewButton")
		if root.result_growth_reviewed:
			growth_button.disabled = true
			growth_button.text = "확인 완료"
		elif growth_choice_pending:
			growth_button.disabled = true
			growth_button.text = "성장 선택 필요"

	var actions: Array = v122_result_view.get("actions", [])
	var action_count := actions.size()
	var action_width := 430.0 if action_count > 1 else 500.0
	var action_gap := 34.0
	var action_y := 790.0 if touch_ui else 820.0
	var action_height := 140.0 if touch_ui else 78.0
	var actions_total_width := action_width * float(action_count) + action_gap * float(maxi(0, action_count - 1))
	var action_start_x := (1920.0 - actions_total_width) * 0.5
	var continue_button: Button = null
	for action_index in range(action_count):
		var action_value = actions[action_index]
		if not action_value is Dictionary:
			continue
		var action: Dictionary = action_value
		var action_id := str(action.get("id", ""))
		var callback_name := str(action.get("callback", ""))
		var action_label := str(action.get("label", action_id))
		if final_battle_result and result_win and action_id == "continue":
			action_label = "엔딩 보기"
		var target_id: String = str({
			"continue": "NextDayButton",
			"edit_placement": "ResultEditPlacement",
			"retry_same_placement": "ResultRetrySamePlacement"
		}.get(action_id, "ResultAction_%d" % action_index))
		var callback: Callable = Callable(root, callback_name) if callback_name != "" and root.has_method(callback_name) else Callable()
		var action_button: Button = hud.button(
			result_screen,
			action_label,
			Rect2(action_start_x + action_index * (action_width + action_gap), action_y, action_width, action_height),
			callback,
			24 if touch_ui else 20,
			str(target_id)
		)
		if str(action.get("priority", "")) == "primary":
			action_button.add_theme_stylebox_override("normal", hud.style(Color("#2b2014f5"), Color("#ffd36a"), 3))
		if action_id == "continue":
			continue_button = action_button

	var growth_review_required := false
	if root.onboarding_enabled and root.tutorial_gate_enabled and root.tutorial_manager.is_active_for_stage(root.onboarding_stage_id):
		growth_review_required = root.tutorial_manager.expected_action() == "growth_reviewed"
	if continue_button != null:
		if growth_review_required:
			continue_button.disabled = true
			continue_button.text = "성장 확인 필요"
		elif growth_choice_pending:
			continue_button.disabled = true
			continue_button.text = "성장 선택 필요"
	hud.label(result_screen, "소유·스토리·엔딩 진행은 그대로 유지됩니다.", Vector2(500, 930), Vector2(920, 30), 14, Color("#8f8798"), HORIZONTAL_ALIGNMENT_CENTER)


func _build_legacy_result_ui() -> void:
	hud.build_top_bar()
	var v122_result_view: Dictionary = V122CombatResultViewModelScript.build_result(
		root.result_summary,
		root.result_summary.get("v122_ledger", {}),
		{
			"rewards": root.rewards_pending,
			"story_preserved": true,
			"meta_progress_preserved": true,
			"ending_preserved": true,
			"next_day_preserved": true
		}
	)
	root.set_meta("v122_result_view_model", v122_result_view)
	var result_win := bool(root.result_summary.get("win", false))
	var management_only_result := bool(root.result_summary.get("management_only", false))
	var outpost_battle_result := bool(root.result_summary.get("outpost_battle", false))
	var result_day_info: Dictionary = root._campaign_day_info() if root.has_method("_campaign_day_info") else {}
	var final_battle_result := bool(result_day_info.get("final_battle", false))
	var title = "방어 성공" if result_win else "방어 실패"
	if management_only_result:
		title = "최종 준비 완료"
	elif outpost_battle_result:
		title = "전초기지 방어 성공" if result_win else "전초기지 패배 수용"
	elif final_battle_result:
		title = "최종 공성 방어 성공" if result_win else "최종 공성 방어 실패"
	var castle_evolved: bool = root.has_method("_castle_evolution_completed_today") and bool(root._castle_evolution_completed_today())
	var final_castle_evolution: bool = castle_evolved and root.has_method("_castle_stage_index") and int(root._castle_stage_index()) == 4
	if castle_evolved and root.result_summary.get("win", false):
		title = "방어 성공 · 마왕성 진화"
	if GameState.victory:
		title = "첫 장 클리어"
	if final_castle_evolution and root.result_summary.get("win", false):
		title = "방어 성공 · 대마왕성 완성"
	var title_rect = root._onboarding_rect("S05_RESULT", "ResultTitle", Rect2(560, 100, 800, 80)) if root.has_method("_onboarding_rect") else Rect2(560, 100, 800, 80)
	var reward_rect = root._onboarding_rect("S05_RESULT", "RewardPanel", Rect2(300, 220, 600, 520)) if root.has_method("_onboarding_rect") else Rect2(300, 220, 600, 520)
	var comment_rect = root._onboarding_rect("S05_RESULT", "CommentPanel", Rect2(940, 220, 680, 520)) if root.has_method("_onboarding_rect") else Rect2(940, 220, 680, 520)
	var button_rect = root._onboarding_rect("S05_RESULT", "NextDayButton", Rect2(760, 820, 400, 72)) if root.has_method("_onboarding_rect") else Rect2(760, 820, 400, 72)
	var result_screen = hud.panel(Rect2(0, 0, 1920, 1080), Color("#00000000"), Color("#00000000"))
	hud.label(result_screen, title, title_rect.position, title_rect.size, 46, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	if castle_evolved and root.has_method("_castle_stage_display_line"):
		var evolution_banner_rect := Rect2(560, 170, 800, 46) if final_castle_evolution else Rect2(610, 174, 700, 38)
		var evolution_banner_color := Color("#2b133bf2") if final_castle_evolution else Color("#21142cf2")
		var evolution_border_color := Color("#ffd36a") if final_castle_evolution else Color("#bd83f0")
		if final_castle_evolution:
			var final_glow = hud.child_panel(result_screen, Rect2(540, 166, 840, 54), Color("#55256855"), Color("#ffd36a99"), 2)
			final_glow.modulate = Color(1.0, 1.0, 1.0, 0.0)
			var final_glow_tween = root.create_tween()
			final_glow_tween.tween_property(final_glow, "modulate", Color(1.0, 1.0, 1.0, 0.85), 0.32)
			final_glow_tween.tween_property(final_glow, "modulate", Color(1.0, 1.0, 1.0, 0.35), 0.52)
		var evolution_banner = hud.panel(evolution_banner_rect, evolution_banner_color, evolution_border_color, "", "flat")
		evolution_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		evolution_banner.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var evolution_area: String = root._castle_area_summary() if root.has_method("_castle_area_summary") else root._castle_stage_subtitle()
		var evolution_text := "%s  |  %s" % [root._castle_stage_display_line(), evolution_area]
		if final_castle_evolution:
			evolution_text = "최종 진화 완료  ·  %s  |  %s" % [root._castle_stage_display_line(), evolution_area]
		hud.label(evolution_banner, evolution_text, Vector2(16, 5), Vector2(evolution_banner_rect.size.x - 32, evolution_banner_rect.size.y - 10), 15, Color("#ffe4a3") if final_castle_evolution else Color("#f0ddff"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		var evolution_tween = root.create_tween().set_parallel(true)
		evolution_tween.tween_property(evolution_banner, "modulate", Color.WHITE, 0.55 if final_castle_evolution else 0.38)
		evolution_tween.tween_property(evolution_banner, "position:y", 174.0 if final_castle_evolution else 180.0, 0.55 if final_castle_evolution else 0.38).from(160.0 if final_castle_evolution else 166.0)
	var reward_panel = hud.panel(reward_rect, Color("#0d0b12f2"), Color("#80662f"), "", "flat")
	var comment_panel = hud.panel(comment_rect, Color("#0d0c11e8"), Color("#4c4354"), "", "flat")
	var result_heading := "전투 결산"
	var primary_cause_label := str(v122_result_view.get("primary_cause_label", ""))
	if primary_cause_label != "":
		var cause_copy := primary_cause_label.trim_prefix("핵심 원인 · ").trim_prefix("핵심 결과 · ")
		result_heading = "%s  ·  %s" % [result_heading, cause_copy]
	hud.label(reward_panel, result_heading, Vector2(28, 22), Vector2(reward_rect.size.x - 56, 42), 21, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var reward_content_x: float = 28.0
	var reward_content_width: float = reward_rect.size.x - reward_content_x * 2.0
	var result_lines: Array = root.result_summary.get("lines", [])
	var result_row_count := 0
	for raw_line in result_lines:
		result_row_count += maxi(1, ceili(float(_display_result_line(str(raw_line)).length()) / 42.0))
	var compact_result := result_row_count >= 13
	var result_scroll := ScrollContainer.new()
	result_scroll.name = "ResultLinesScroll"
	result_scroll.position = Vector2(20, 72)
	result_scroll.size = Vector2(reward_rect.size.x - 40, reward_rect.size.y - 92)
	result_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	reward_panel.add_child(result_scroll)
	var result_list := VBoxContainer.new()
	result_list.name = "ResultLinesList"
	result_list.custom_minimum_size.x = result_scroll.size.x - 20.0
	result_list.add_theme_constant_override("separation", 2 if compact_result else 6)
	result_scroll.add_child(result_list)
	for line in result_lines:
		var line_text = _display_result_line(str(line))
		var is_facility_line = line_text.begins_with("시설 기여")
		var line_rows := maxi(1, ceili(float(line_text.length()) / 42.0))
		var font_size = (14 if is_facility_line else 16) if compact_result else (16 if is_facility_line else 19)
		var line_height := float(22 if compact_result else 32) * float(line_rows)
		var result_label: Label = hud.label(
			result_list,
			line_text,
			Vector2.ZERO,
			Vector2(reward_content_width, line_height),
			font_size,
			Color("#ffd36a") if is_facility_line else Color("#d8d1df"),
			HORIZONTAL_ALIGNMENT_CENTER,
			"",
			UIFontScript.ROLE_BODY,
			VERTICAL_ALIGNMENT_CENTER,
			TextServer.AUTOWRAP_ARBITRARY,
			line_rows,
			13
		)
		result_label.custom_minimum_size = Vector2(result_list.custom_minimum_size.x, line_height)
	hud.label(comment_panel, "다음 진행", Vector2(42, 24), Vector2(comment_rect.size.x - 84, 42), 27, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var next_copy = "결산 확인 후 다음 단계로 진행합니다.\nDAY 03 승리 이후에는 DAY 04 악명 원정 예고 화면으로 이어집니다."
	if not GameState.victory and not GameState.defeat and GameState.day >= 4:
		next_copy = "결산 확인 후 다음 날 관리 화면으로 진행합니다.\n원정과 방어 결과가 이어지는 정규 캠페인 구간입니다."
	if management_only_result:
		next_copy = "배치·시설·지침의 최종 점검을 확정했습니다.\n다음 진행에서 DAY 30 최종 공성전 관리 화면으로 이동합니다."
	elif outpost_battle_result:
		next_copy = "본성 왕좌와 캠페인 패배 상태는 변하지 않았습니다.\n결산 확인 후 다음 DAY 관리 화면으로 진행합니다."
	elif final_battle_result and result_win:
		next_copy = "DAY 30 최종 공성전을 막아냈습니다.\n다음 진행에서 데이터에 기록된 정규 캠페인 엔딩을 확인합니다."
	elif final_battle_result:
		next_copy = "열한 구역과 Stage 04는 사라지지 않았습니다.\n왕좌를 복구한 뒤 DAY 30 최종 공성전을 다시 준비합니다."
	if final_castle_evolution:
		next_copy = "대마왕성의 최종 진화가 완성됐습니다.\n다음 관리 화면부터 확장 구역과 최종 단계 건물이 적용됩니다."
	elif castle_evolved:
		next_copy = "%s으로 진화했습니다.\n다음 관리 화면부터 새 성 내부 외형이 적용됩니다." % root._castle_stage_display_line()
	hud.label(comment_panel, next_copy, Vector2(42, 82), Vector2(comment_rect.size.x - 84, 112), 20, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3, 14)
	hud.label(comment_panel, "몬스터 성장", Vector2(42, 214), Vector2(comment_rect.size.x - 84, 34), 22, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var growth_y := 256
	var growth_lines = root._result_growth_lines() if root.has_method("_result_growth_lines") else []
	for line in growth_lines:
		hud.label(comment_panel, str(line), Vector2(48, growth_y), Vector2(comment_rect.size.x - 96, 28), 18, Color("#d8d1df"))
		growth_y += 34
	_build_growth_reward_panel(comment_panel, comment_rect)
	var growth_button_rect = Rect2(comment_rect.position + Vector2(comment_rect.size.x - 274, comment_rect.size.y - 86), Vector2(230, 58))
	var growth_button = hud.button(comment_panel, "성장 확인", Rect2(growth_button_rect.position - comment_rect.position, growth_button_rect.size), Callable(root, "_review_growth_from_result"), 18, "GrowthReviewButton")
	growth_button.text = "성장 확인"
	var growth_choice_pending = root.has_method("_result_growth_choice_required") and root._result_growth_choice_required() and not root.result_growth_choice_applied
	if root.result_growth_reviewed:
		growth_button.disabled = true
		growth_button.text = "확인 완료"
	elif growth_choice_pending:
		growth_button.disabled = true
		growth_button.text = "성장 선택 필요"
	var growth_review_required := false
	if root.onboarding_enabled and root.tutorial_gate_enabled and root.tutorial_manager.is_active_for_stage(root.onboarding_stage_id):
		growth_review_required = root.tutorial_manager.expected_action() == "growth_reviewed"
	var next_button: Button
	if final_battle_result:
		var final_button_label := "엔딩 보기" if result_win else "DAY 30 재도전"
		next_button = hud.button(result_screen, final_button_label, button_rect, Callable(root, "_continue_from_result"), 19, "NextDayButton")
	elif GameState.victory or GameState.defeat:
		next_button = hud.button(result_screen, "관리 화면으로", button_rect, Callable(root, "_continue_from_result"), 19, "NextDayButton")
	else:
		next_button = hud.button(result_screen, "다음 날 진행", button_rect, Callable(root, "_continue_from_result"), 19, "NextDayButton")
	if growth_review_required:
		next_button.disabled = true
		next_button.text = "성장 확인 필요"
	elif growth_choice_pending:
		next_button.disabled = true
		next_button.text = "성장 선택 필요"

func _display_result_line(line_text: String) -> String:
	var tag_start = line_text.rfind(" (")
	if tag_start < 0 or not line_text.ends_with(")"):
		return line_text
	var tag = line_text.substr(tag_start + 2, line_text.length() - tag_start - 3)
	return line_text.left(tag_start) if tag.is_valid_identifier() else line_text

func _build_growth_reward_panel(comment_panel: Control, comment_rect: Rect2) -> void:
	var overlay = hud.child_panel(comment_panel, Rect2(Vector2.ZERO, comment_rect.size), Color("#111016ff"), Color("#9b6a27"), 2)
	hud.label(overlay, "몬스터 성장", Vector2(0, 24), Vector2(comment_rect.size.x, 40), 27, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var caption = "공유 EXP + 개별 활약 EXP"
	if root.has_method("_result_growth_choice_required") and root._result_growth_choice_required():
		caption = "공유 EXP + 개별 활약 EXP · 집중 성장 1명 선택"
	if root.result_growth_reviewed:
		caption = "성장 확인 완료 · 공유 EXP + 개별 활약 EXP"
	elif root.result_growth_choice_applied:
		caption = "%s +%d EXP · %s" % [
			str(root.last_growth_choice_summary.get("display_name", "선택 몬스터")),
			int(root.last_growth_choice_summary.get("bonus_exp", 0)),
			str(root.last_growth_choice_summary.get("preparation_summary", "다음 방어 준비"))
		]
	hud.label(overlay, caption, Vector2(48, 70), Vector2(comment_rect.size.x - 96, 24), 15, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

	var rows: Array = root.last_growth_summary
	if rows.is_empty():
		hud.label(overlay, "이번 전투 성장 기록이 없습니다.", Vector2(48, 180), Vector2(comment_rect.size.x - 96, 40), 21, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER)
	else:
		var shown_count = mini(rows.size(), 3)
		for index in range(shown_count):
			_build_growth_card(overlay, rows[index], Vector2(36, 112 + index * 108), comment_rect.size.x - 72)
		if rows.size() > shown_count:
			hud.label(overlay, "+%d명 더 성장" % (rows.size() - shown_count), Vector2(48, 440), Vector2(comment_rect.size.x - 96, 24), 14, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

	var review_instruction = "이번 전투에서 반영된 성장과 유대 변화입니다."
	if root.has_method("_result_growth_choice_required") and root._result_growth_choice_required():
		review_instruction = "EXP와 다음 방어 준비 효과를 받을 한 명을 고르세요."
	if root.result_growth_choice_applied:
		review_instruction = "다음 방어 준비가 예약되었습니다. 효과를 확인한 뒤 성장 확인을 누르세요."
	if root.result_growth_reviewed:
		review_instruction = "성장 반영을 확인했습니다. 다음 날 진행할 수 있습니다."
	hud.label(overlay, review_instruction, Vector2(42, comment_rect.size.y - 74), Vector2(comment_rect.size.x - 340, 44), 15, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)

func _build_growth_card(parent: Control, row: Dictionary, position: Vector2, width: float) -> void:
	var activity_exp = int(row.get("activity_exp", 0))
	var card_border = Color("#6e5630") if activity_exp > 0 else Color("#403448")
	var card = hud.child_panel(parent, Rect2(position, Vector2(width, 100)), Color("#17121df0"), card_border, 1)
	var content_x := 18.0
	var result_monster_id := str(row.get("monster_id", ""))
	var evolution_rule: Dictionary = root._monster_promotion_rule(result_monster_id) if result_monster_id != "" and root.has_method("_monster_promotion_rule") else {}
	var portrait_variants: Dictionary = evolution_rule.get("portrait_variants", {}) if evolution_rule.get("portrait_variants", {}) is Dictionary else {}
	var portrait_variant := "victory" if bool(root.result_summary.get("win", false)) else "wounded"
	var result_portrait_path := str(portrait_variants.get(portrait_variant, ""))
	if result_portrait_path != "":
		var result_portrait: TextureRect = hud.texture(card, result_portrait_path, Rect2(8, 8, 84, 84))
		result_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		content_x = 102.0
	var name = str(row.get("display_name", row.get("monster_id", "")))
	var level_before = int(row.get("level_before", row.get("level_after", 1)))
	var level_after = int(row.get("level_after", 1))
	var levels_gained = int(row.get("levels_gained", max(0, level_after - level_before)))
	var exp_gain = int(row.get("exp_gain", 0))
	var shared_exp = int(row.get("shared_exp", max(0, exp_gain - activity_exp)))
	var activity_breakdown: Dictionary = row.get("activity_breakdown", {})
	var exp_after = int(row.get("exp_after", 0))
	var next_exp = max(1, int(row.get("next_exp", 50)))
	var progress = clamp(float(exp_after) / float(next_exp), 0.0, 1.0)
	var level_text = "Lv.%d" % level_after
	if levels_gained > 0:
		level_text = "Lv.%d -> Lv.%d" % [level_before, level_after]
	var choice_required = root.has_method("_result_growth_choice_required") and root._result_growth_choice_required()

	hud.label(card, name, Vector2(content_x, 8), Vector2(180, 28), 21, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(card, level_text, Vector2(content_x, 38), Vector2(130, 24), 16, Color("#d99bff"))
	hud.label(card, "EXP +%d" % exp_gain, Vector2(width - 130, 10), Vector2(104, 24), 17, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)
	var has_result_portrait := result_portrait_path != ""
	var bar_x := 260.0 if has_result_portrait else 176.0
	var bar_width = max(80.0, width - ((444.0 if has_result_portrait else 360.0) if choice_required else (316.0 if has_result_portrait else 232.0)))
	hud.child_panel(card, Rect2(bar_x, 43, bar_width, 12), Color("#24192d"), Color("#3b3143"), 1)
	hud.child_panel(card, Rect2(bar_x, 43, bar_width * progress, 12), Color("#ffd36a"), Color("#ffd36a"), 0)
	var exp_text = "%d / %d" % [exp_after, next_exp]
	if levels_gained > 0:
		exp_text = "LEVEL UP  %s" % exp_text
	hud.label(card, exp_text, Vector2(bar_x, 56), Vector2(bar_width, 18), 12, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_RIGHT)
	hud.label(card, "공유 +%d · 활약 +%d" % [shared_exp, activity_exp], Vector2(content_x, 72), Vector2(182, 20), 13, Color("#ffd36a") if activity_exp > 0 else Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var activity_parts: Array[String] = []
	var activity_labels = {
		"attack": "공격",
		"defense": "흡수",
		"finisher": "마무리",
		"facility": "시설"
	}
	for key in ["attack", "defense", "finisher", "facility"]:
		var value = int(activity_breakdown.get(key, 0))
		if value > 0:
			activity_parts.append("%s+%d" % [activity_labels[key], value])
	if activity_parts.is_empty():
		activity_parts.append("활약 보너스 없음")
	var activity_width = width - 342 if choice_required else width - 232
	var activity_font_size = 11 if choice_required else 12
	hud.label(card, " / ".join(activity_parts), Vector2(198, 72), Vector2(activity_width, 20), activity_font_size, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_RIGHT)
	if choice_required:
		var monster_id = str(row.get("monster_id", ""))
		var bonus = root._result_growth_choice_bonus() if root.has_method("_result_growth_choice_bonus") else 0
		var preview_text := _growth_choice_preview_text(row, bonus)
		var preparation_preview = root._result_growth_preparation_preview(monster_id) if root.has_method("_result_growth_preparation_preview") else ""
		if preview_text != "":
			var preview_label = hud.label(card, preview_text, Vector2(width - 166, 31), Vector2(144, 18), 10, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_OFF, 1, 9)
			preview_label.name = "GrowthChoicePreview_%s" % monster_id
		if preparation_preview != "":
			var preparation_label = hud.rich_label(card, preparation_preview, Vector2(width - 166, 51), Vector2(144, 18), 10, Color("#f4e7d2"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_OFF, VERTICAL_ALIGNMENT_CENTER, "", 9)
			preparation_label.bbcode_enabled = true
			preparation_label.text = "[right]%s[/right]" % preparation_preview
			preparation_label.name = "GrowthChoicePreparation_%s" % monster_id
		var choice_button = hud.button(card, "집중 +%d" % bonus, Rect2(width - 126, 72, 104, 24), Callable(root, "_choose_result_growth").bind(monster_id), 11, "GrowthChoice_%s" % monster_id)
		choice_button.name = "GrowthChoice_%s" % monster_id
		if root.has_method("_result_growth_preparation_summary"):
			var tooltip_preview := preview_text
			if preparation_preview != "":
				tooltip_preview = "%s · %s" % [tooltip_preview, preparation_preview]
			choice_button.tooltip_text = "%s · %s" % [tooltip_preview, root._result_growth_preparation_summary(monster_id)]
		if root.result_growth_choice_applied:
			choice_button.disabled = true
			if str(root.result_growth_choice_monster_id) == monster_id:
				choice_button.text = "선택됨"

func _growth_choice_preview_text(row: Dictionary, bonus: int) -> String:
	if bonus <= 0:
		return ""
	var level: int = int(row.get("level_after", 1))
	var exp: int = int(row.get("exp_after", 0)) + bonus
	var next_exp: int = maxi(1, int(row.get("next_exp", 50)))
	var gained: int = 0
	var guard: int = 0
	while exp >= next_exp and guard < 20:
		exp -= next_exp
		level += 1
		gained += 1
		guard += 1
		if root.has_method("_monster_exp_to_next"):
			next_exp = maxi(1, int(root.call("_monster_exp_to_next", level)))
		else:
			next_exp = 50 + maxi(0, level - 1) * 30
	if gained > 0:
		return "선택 시 Lv.%d" % level
	return "선택 후 %d/%d" % [exp, next_exp]

func _tutorial_monster_target_id(monster_id: String) -> String:
	match monster_id:
		"slime":
			return "CHR_PUDDING"
		"goblin":
			return "CHR_GOB"
		"imp":
			return "CHR_PYNN"
		"kobold_scout":
			return "CHR_ROLO"
		_:
			return ""
