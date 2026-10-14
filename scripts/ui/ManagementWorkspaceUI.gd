extends RefCounted
const Constants = preload("res://scripts/core/Constants.gd")
const UIFont = preload("res://scripts/ui/UIFont.gd")
const Preview = preload("res://scripts/ui/FacilityPreview.gd")
const ManagementKit = preload("res://scripts/ui/kit/UIKit.gd")
const Surface = preload("res://scripts/ui/kit/KitSurface.gd")
const INK := Color("#17121f")
const LINE := Color("#67546e")
const PAPER := Color("#f4eadc")
const MUTED := Color("#c0b2c6")
const GOLD := Color("#e8bd76")
const DOCK_RECT := Rect2(360, 968, 1200, 96)
const TOOL_RECT := Rect2(416, 810, 1088, 144)
var root: Node
var hud
var shared_theme: Theme
var preview_panel: Panel
var tools_expanded := false

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
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = Vector2(rect.size.x, maxf(rect.size.y, ceilf(label.get_theme_font("font").get_height(label.get_theme_font_size("font_size")))))
	label.tooltip_text = text
	return label

func button(parent: Control, text: String, rect: Rect2, callback: Callable, id: String, grade: String = "utility") -> Button:
	var result: Button = hud.button(parent, text, rect, callback, 22, id, grade)
	result.focus_mode = Control.FOCUS_ALL
	result.add_theme_stylebox_override("focus", hud.flat_style(Color("#00000000"), GOLD, 3))
	return result

func focus_if_visible(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree() and not control.is_queued_for_deletion() and control.is_visible_in_tree():
		control.grab_focus()

func kit_panel(rect: Rect2, id: String) -> Panel:
	var result := Panel.new()
	result.name = id
	result.position = rect.position
	result.size = rect.size
	result.theme = kit_theme()
	result.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	result.mouse_filter = Control.MOUSE_FILTER_STOP
	result.set_meta("u5b_occluder", true)
	var surface := Surface.new()
	result.add_child(surface)
	result.resized.connect(surface.sync.bind(result))
	surface.sync(result)
	root.ui_layer.add_child(result)
	return result

func kit_theme() -> Theme:
	if shared_theme == null:
		shared_theme = ManagementKit.scaled_theme(UISettings.text_scale, UISettings.is_touch_ui())
	return shared_theme

func kit_copy(parent: Control, text: String, rect: Rect2, font_size: int = 24, color: Color = PAPER, id: String = "") -> Label:
	var label := ManagementKit.label(LanguageSettings.ui_text(text), "body", true)
	label.name = id if id != "" else "Copy"
	label.position = rect.position
	label.size = rect.size
	label.theme = kit_theme()
	label.add_theme_font_size_override("font_size", ManagementKit.Tokens.font_size(maxi(24,font_size), UISettings.text_scale, UISettings.is_touch_ui()))
	label.add_theme_color_override("font_color", color)
	label.tooltip_text = label.text
	parent.add_child(label)
	return label

func kit_button(parent: Node, text: String, rect: Rect2, callback: Callable, id: String, grade: String = "utility", icon: String = "") -> Button:
	# Runtime load follows U5-A: avoid compile-time GameRoot / KitButton cycle.
	var result: Button = load("res://scripts/ui/kit/KitButton.gd").new()
	result.configure(LanguageSettings.ui_text(text), 1 if grade == "primary" else 0, icon)
	result.name = id
	result.position = rect.position
	result.size = rect.size
	result.set_meta("ui_button_grade", grade)
	if rect.size.y > 0 and rect.size.y < 70:
		result.set_meta("kit_icon_button",true)
		result.expand_icon = true
	parent.add_child(result)
	ManagementKit.inherit_theme(result, kit_theme())
	if rect.size.y > 0 and rect.size.y < 70:
		result.custom_minimum_size = rect.size
		result.add_theme_constant_override("icon_max_width",32)
		result.add_theme_font_size_override("font_size",24)
	if rect.has_area(): result.size = rect.size
	if result.tooltip_text.is_empty(): result.tooltip_text = LanguageSettings.ui_text({"close":"닫기","info":"상세 정보","settings":"설정"}.get(icon,icon))
	if callback.is_valid(): result.pressed.connect(callback)
	if id != "": root.register_tutorial_target_control(id, result)
	return result

func kit_flow(parent: Control, vertical: bool = false) -> BoxContainer:
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	parent.add_child(box)
	return box

func kit_content(pane: Control, padding: int = 12) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_"+side, padding)
	pane.add_child(margin)
	return kit_flow(margin, true) as VBoxContainer

func kit_line(parent: Control, text: String, id: String = "", color: Color = PAPER) -> Label:
	var label := ManagementKit.label(LanguageSettings.ui_text(text), "support", true)
	label.name = id if id != "" else "Copy"
	label.add_theme_color_override("font_color", color)
	label.tooltip_text = label.text
	parent.add_child(label)
	return label

func build(model: Dictionary, pending_reason: String) -> void:
	shared_theme = null
	preview_panel = null
	var snapshot: Dictionary = root.combat_scene.build_precombat_snapshot(false)
	root._refresh_maze_route_forecasts(snapshot)
	root.build_placement.ensure_ghost()
	root.build_placement.fit_workspace_if_needed()
	_top(snapshot)
	_tabs()
	if root.build_pick_mode or root.deploy_pick_monster_id != "" or (root.onboarding_enabled and root.tutorial_manager.active): tools_expanded = true
	match root.management_tool_tab if tools_expanded else "":
		"build":
			if root.build_preview_room_id == "": _build_palette()
		"roster": root.management_scene._build_monster_roster_dock()
		"tactics": _tactics(model)
	_footer(model)
	if root.management_context_drawer_open and not root.build_pick_mode:
		if pending_reason != "" and not _tutorial_needs_room_directive():
			var required_ui = load("res://scripts/ui/RequiredPreparationUI.gd").new()
			required_ui.setup(root, hud)
			required_ui.build_required(model, pending_reason)
		else: _inspector()
	elif not root.build_pick_mode:
		var handle := kit_button(root.ui_layer, "", Rect2(1830, 434, 66, 92), Callable(root, "_open_management_context_drawer"), "OpenManagementContextButton", "utility", "info")
		handle.tooltip_text = root.continuity.localized("선택 상세", "Selected room details", "所选房间详情")
		handle.set_meta("u5b_occluder", true)
	if root.build_pick_mode: _review_bar()

func _top(snapshot: Dictionary) -> void:
	var rail := kit_panel(Rect2(16, 8, 1888, 60), "ResourceStatusRail")
	rail.set_meta("kit_surface_radius", 22)
	for i in range(4):
		var id: String = ["gold", "mana", "food", "infamy"][i]
		var icon := ManagementKit.image(id, 40)
		icon.position = Vector2(20+i*194,9)
		rail.add_child(icon)
		var value: int = GameState.get(id)
		hud.resource_value_labels[id] = kit_copy(rail, str(value), Rect2(66+i*194, 7, 120, 44),28,PAPER,"ResourceValue_"+id)
		icon.tooltip_text = LanguageSettings.ui_text(["금화", "마력", "식량", "악명"][i])
	var day := kit_copy(rail, "DAY %02d" % GameState.day, Rect2(842, 7, 170, 44),26,GOLD,"DayStatusBadge")
	day.mouse_filter = Control.MOUSE_FILTER_STOP
	day.tooltip_text = effect_text(root._campaign_notice_summary()) + "\n" + LanguageSettings.ui_text(root._castle_stage_display_line()) + "\n" + LanguageSettings.ui_text(root._castle_area_summary())
	var threat: Button = kit_button(rail, "× %d" % snapshot.get("schedule",[]).size(), Rect2(1020,0,180,58), Callable(root, "_open_intrusion_brief").bind(true), "OpenIntrusionBriefButton", "utility", "explorer_enemy")
	threat.custom_minimum_size.y = 58
	threat.tooltip_text = root.continuity.localized("오늘의 침입 · 편대와 실제 경로 보기", "Today's invasion · Groups and actual route", "今日入侵 · 查看队伍与实际路线")
	var map := kit_button(rail, root.continuity.localized("지도 전체","Fit map","全图"), Rect2(1232,0,226,58), Callable(root.build_placement,"fit_workspace"), "FitManagementMapButton")
	map.custom_minimum_size.y = 58
	map.disabled = not root.build_placement.can_navigate()
	for entry in [["−",-1,1468,"ZoomOutManagementMapButton"],["+",1,1538,"ZoomInManagementMapButton"]]:
		var b := kit_button(rail,entry[0],Rect2(entry[2],0,60,58),Callable(root.build_placement,"zoom_workspace").bind(entry[1]),entry[3])
		b.custom_minimum_size.y = 58
		b.tooltip_text = root.continuity.localized("휠: 확대·축소 / 휠 버튼 드래그: 이동", "Wheel: zoom / Middle drag: pan", "滚轮：缩放 / 中键拖动：平移")
		b.disabled = not root.build_placement.can_navigate()
	for entry in [["settings",1610,"ManagementSettingsButton","_open_settings_screen"],["save",1702,"ManagementMenuButton","_open_pause_menu"],["encyclopedia",1794,"ManagementRecordsButton","_open_chronicle"]]:
		var b := kit_button(rail,"",Rect2(entry[1],0,78,58),Callable(root,entry[3]),entry[2],"utility",entry[0])
		b.custom_minimum_size = Vector2(78,58)
		b.tooltip_text = root.continuity.localized("설정", "Settings", "设置") if entry[0] == "settings" else (root.continuity.localized("메뉴", "Menu", "菜单") if entry[0] == "save" else root.continuity.localized("기록실", "Records", "记录室"))
	var goals := kit_panel(Rect2(24,80,340,100),"BossHpBar")
	var crown := ManagementKit.image("throne",40)
	crown.position = Vector2(8,6)
	goals.add_child(crown)
	hud.boss_hp_label = kit_copy(goals,"%d / %d" % [GameState.demon_lord_hp,GameState.demon_lord_max_hp],Rect2(58,2,268,38),24)
	hud.boss_hp_fill_width = 268
	hud.boss_hp_fill = hud._stat_bar(goals,Rect2(58,42,268,12),float(GameState.demon_lord_hp)/maxi(1,GameState.demon_lord_max_hp),ManagementKit.Tokens.HP,ManagementKit.Tokens.BACKGROUND)
	var treasure_id: String = root._room_by_facility("treasure")
	if treasure_id != "":
		var treasure: Dictionary = root.rooms[treasure_id]
		var chest := ManagementKit.image("treasury",40)
		chest.position = Vector2(8,56)
		goals.add_child(chest)
		kit_copy(goals,"%d / %d" % [treasure.get("hp",0),treasure.get("max_hp",treasure.get("hp",0))],Rect2(58,54,268,38),24)
	goals.tooltip_text = root.continuity.localized("현재 보호 목표 체력", "Current defense objectives HP", "当前防御目标生命值")

func select_tool(tab_id: String) -> void:
	tools_expanded = not tools_expanded if root.management_tool_tab == tab_id else true
	root.build_placement.workspace_view_key = ""
	root._set_management_tool_tab(tab_id)

func _tabs() -> void:
	var dock := kit_panel(DOCK_RECT,"ManagementToolTabs")
	var row := kit_content(dock,0)
	var items := kit_flow(row)
	items.add_theme_constant_override("separation",10)
	for entry in [["build","건설","build"],["roster","수비대","garrison"],["tactics","전술","tactics"],["monster","몬스터","monster"],["start","전투 시작","battle_start"]]:
		var callback := Callable(self,"select_tool").bind(entry[0])
		var id: String = "ManagementTab_"+entry[0]
		if entry[0] == "monster": callback = Callable(root,"_open_monster_screen"); id = "MonsterManagementButton"
		if entry[0] == "start": callback = Callable(root,"_request_combat_start"); id = "StartCombatButton"
		var b := kit_button(items, entry[1],Rect2(),callback,id,"primary" if entry[0] == "start" else "tactical",entry[2])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("kit_button_height",96)
		b.custom_minimum_size.y = 96
		if root.management_tool_tab == entry[0]:
			b.set_meta("kit_selected",true)
			b.set_variant(1)
			b.selected_marker = true

func _build_palette() -> void:
	var dock := kit_panel(TOOL_RECT,"BuildingToolbox")
	var installed := 0
	var available := 0
	for id in root.rooms:
		if root._can_change_room_facility(id):
			available += 1
			if str(root.rooms[id].get("facility_role","")) != "build_slot": installed += 1
	var count := kit_panel(Rect2(24,810,340,144),"BuildingSlotCount")
	var counts := kit_content(count)
	kit_line(counts,root.continuity.localized("설치 %d / 열린 구역 %d","Built %d / Open areas %d","已建 %d / 开放区域 %d") % [installed,available],"BuildingSlotCountLabel",GOLD)
	kit_line(counts,root.continuity.localized("시설 제한은 각 카드 설명","Facility limits: card details","设施限制：卡片详情"),"",MUTED)
	var scroll := ScrollContainer.new()
	scroll.name = "BuildingCardScroll"
	scroll.position = Vector2(8,6)
	scroll.size = dock.size-Vector2(16,12)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	dock.add_child(scroll)
	var row := kit_flow(scroll)
	for id_value in root.FACILITY_CHOICES:
		var id := str(id_value)
		var definition: Dictionary = root._facility_definition(id)
		var unlocked: bool = root._facility_unlocked(id)
		var affordable := GameState.can_pay(definition.get("cost", {}))
		var card := kit_button(row,"",Rect2(),Callable(root,"_set_build_facility").bind(id),"FacilityCard_"+id,"tactical")
		card.custom_minimum_size = Vector2(320,122)
		card.set_meta("facility_id",id)
		card.disabled = not unlocked or not affordable
		card.tooltip_text = "%s\n%s\n%s\n%s" % [LanguageSettings.ui_text(str(definition.get("display_name",id))),effect_text(str(definition.get("effect_summary",""))),LanguageSettings.ui_text(str(definition.get("recommend_summary",""))),root.continuity.localized("클릭·드롭 즉시 설치 / ESC 취소","Click or drop to install / ESC cancels","点击或放下立即安装 / ESC取消")]
		card.gui_input.connect(Callable(root.build_placement,"card_input").bind(id,card))
		var preview := Preview.new()
		preview.game = root
		preview.facility_id = id
		preview.position = Vector2(8,8)
		preview.size = Vector2(94,104)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(preview)
		kit_copy(card,str(definition.get("display_name",id)),Rect2(108,6,204,60),24)
		var cost := cost_row(card,definition.get("cost",{}))
		cost.position = Vector2(108,76)
		cost.size = Vector2(204,40)
		if not unlocked or not affordable:
			card.tooltip_text += "\n" + root.continuity.localized("잠김" if not unlocked else "비용 부족","Locked" if not unlocked else "Insufficient resources","未解锁" if not unlocked else "资源不足")
		if id == root.build_pick_facility_id: card.set_variant(1)

func effect_text(text: String) -> String:
	var sentences := LanguageSettings.ui_text(text).split(". ")
	for i in range(sentences.size()): sentences[i] = LanguageSettings.ui_text(sentences[i])
	return ". ".join(sentences)

func cost_row(parent: Control, costs: Dictionary) -> HBoxContainer:
	var row := kit_flow(parent)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",8)
	for id in ["gold","mana","food","infamy"]:
		if int(costs.get(id,0)) <= 0: continue
		row.add_child(ManagementKit.image(id,32))
		var value := ManagementKit.label(str(costs[id]),"support")
		value.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(value)
	if row.get_child_count() == 0: kit_line(row,root.continuity.localized("무료","Free","免费"))
	return row

func _footer(model: Dictionary) -> void:
	var undo := kit_button(root.ui_layer,"되돌리기",Rect2(24,968,280,96),Callable(root,"_undo_last_management_placement"),"PlacementUndoButton","utility","undo")
	undo.set_meta("u5b_occluder",true)
	undo.disabled = root.management_undo.is_empty() or root._management_action_mode_active()
	undo.tooltip_text = root.continuity.localized("마지막 건설·배치 1회와 자원 복원", "Restore the last construction or placement and resources", "恢复上一次建造或部署及资源")
	var state: Dictionary = model.get("start",{})
	var start: Button = root.ui_layer.find_child("StartCombatButton",true,false)
	var enabled := bool(state.get("can_start",false))
	if root.campaign_postgame_active:
		start.text = LanguageSettings.ui_text("엔딩 다시 보기")
		start.pressed.disconnect(Callable(root,"_request_combat_start"))
		start.pressed.connect(Callable(root,"_show_campaign_ending"))
		enabled = true
	elif bool(root._campaign_day_info().get("management_only",false)):
		start.text = LanguageSettings.ui_text(str(root._campaign_day_info().get("management_only_start_label","준비 확정")))
		start.pressed.disconnect(Callable(root,"_request_combat_start"))
		start.pressed.connect(Callable(root,"_confirm_management_only_day"))
		enabled = not root._management_action_mode_active()
	elif root._update4_outpost_battle_day(): enabled = not root._management_action_mode_active()
	if root._campaign_final_declaration_required(): enabled = not root._campaign_final_declaration_pending() and not root._management_action_mode_active()
	start.disabled = not enabled
	start.tooltip_text = LanguageSettings.ui_text(str(state.get("blocked_reason",""))) if not enabled else root.continuity.localized("현재 배치와 전술로 전투 시작", "Begin combat with this formation and tactics", "以当前部署和战术开始战斗")
	var feedback := ""
	if not bool(state.get("can_start",false)): feedback = str(state.get("blocked_reason",""))
	elif not root.management_feedback.is_empty(): feedback = root._management_feedback_line()
	if feedback != "":
		var pane := kit_panel(Rect2(384,80,1040,84),"ManagementPrimaryBar")
		var row := kit_content(pane,8)
		kit_line(row, feedback, "PlacementFeedbackLabel", MUTED)
		if str(state.get("reason_code","")) == "specialization":
			# Keep StartCombatButton's meaning; a separate path resolves the lock.
			var b := kit_button(root.ui_layer,root.continuity.localized("필수 특화 보기","Required skills","查看必选专精"),Rect2(24,870,344,78),Callable(root,"_open_monster_screen"),"RequiredSpecializationShortcut","utility","monster")
			b.set_meta("u5b_occluder",true)

func _tactics(model: Dictionary) -> void:
	var dock := kit_panel(Rect2(416,670,1088,284),"TacticsToolbox")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(12,12)
	scroll.size = dock.size-Vector2(24,24)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	dock.add_child(scroll)
	var column := kit_flow(scroll,true)
	kit_line(column,"전체 전술 · 모든 방","",GOLD)
	var policies := kit_flow(column)
	for entry in [[Constants.DIRECTIVE_DEFENSE,"사수"],[Constants.DIRECTIVE_ALL_OUT,"총공격"],[Constants.DIRECTIVE_SURVIVAL,"생존"]]:
		var b := kit_button(policies,entry[1],Rect2(),Callable(root,"_set_global_directive").bind(entry[0]),"GlobalDirective_"+entry[0],"tactical","tactics")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = root._day_one_global_directive_locked()
		b.tooltip_text = LanguageSettings.ui_text(root._global_directive_description(entry[0]))
		if entry[0] == Constants.DIRECTIVE_DEFENSE: root.register_tutorial_target_control("GLOBAL_DIRECTIVE_DEFEND",b)
		if root.global_directive == entry[0]: b.set_variant(1)
	var actions := HFlowContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation",12)
	actions.add_theme_constant_override("v_separation",12)
	column.add_child(actions)
	var connector: Dictionary = root._v122_defender_connector()
	if not connector.is_empty():
		var b := kit_button(actions,"샛문 복구",Rect2(),Callable(root,"_build_v122_defender_connector"),"ManagementContextAction_defender_connector")
		b.disabled = not root._v122_can_build_defender_connector()
		b.tooltip_text = LanguageSettings.ui_text(root._cost_label(connector.get("cost",{})))
	for action_value in model.get("actions",[]):
		var action: Dictionary = action_value
		if str(action.get("area","")) != "context" or not bool(action.get("visible",false)): continue
		var b := kit_button(actions,str(action.get("label","")),Rect2(),Callable(root,str(action.get("callback",""))),"ManagementContextAction_"+str(action.get("id","")))
		b.disabled = not bool(action.get("enabled",true))
		b.tooltip_text = LanguageSettings.ui_text(str(action.get("tooltip","")))
	if root.story_feature_enabled:
		var caption: String = root.continuity.localized("대화 · 기록", "Story log", "剧情记录")
		kit_button(actions,caption,Rect2(),Callable(root,"_open_story_management_dialogue"),"StoryDialogueAlarmButton","utility","log")
	if root._is_prepared_maze():
		var routes: Array = []
		for route in root.maze_route_forecasts:
			var entry: String = root.continuity.localized("측문","Side gate","侧门") if str(route.spawn_room_id) in ["outside_approach_b","service_entrance"] else root.continuity.localized("정문","Main gate","正门")
			var names: Array[String] = []
			for name in route.names: names.append(LanguageSettings.ui_text(str(name)))
			var caption := "%s → %s · %s ×%d" % [entry,LanguageSettings.ui_text(root.display_name_for_instance(str(route.target_room_id)))," / ".join(names),int(route.count)]
			routes.append({"label":caption,"value":str(route.id)})
		var option: OptionButton = hud.option_button(column,Rect2(),routes,root.maze_route_id,Callable(root,"_select_maze_route"),24)
		option.name = "MazeRouteOption"
		option.custom_minimum_size.y = 54
		var summary := kit_line(column,"","MazePreparationSummary",MUTED)
		summary.custom_minimum_size.y = 60
		preload("res://scripts/ui/DefensePreparationSummary.gd").refresh(root)

func _inspector() -> void:
	var room: Dictionary = root.rooms.get(root.selected_room,{})
	if room.is_empty(): return
	var drawer := kit_panel(Rect2(1436,80,460,874),"ManagementContextDrawer")
	drawer.z_index = 120
	# Card strip uses the same reserved space, never underneath an open drawer.
	for id in ["BuildingToolbox","BuildingSlotCount","MonsterRosterDock","RosterStatus","TacticsToolbox","ManagementPrimaryBar"]:
		var other := root.ui_layer.find_child(id,true,false) as Control
		if other != null: other.visible = false
	var column := kit_content(drawer,20)
	var header := kit_flow(column)
	kit_line(header,root.display_name_for_instance(root.selected_room),"SelectedRoomName",GOLD)
	kit_button(header,"",Rect2(),Callable(root,"_close_management_context_drawer"),"CloseManagementContextButton","utility","close")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	var list := kit_flow(scroll,true)
	var occupancy: Dictionary = root._management_room_occupancy(root.selected_room)
	kit_line(list,"체력 %d · 수비대 %d / %d" % [int(room.get("hp",0)),int(occupancy.count),int(occupancy.capacity)],"ManagementRoomOccupancy")
	var definition: Dictionary = root._facility_definition(str(room.get("facility_role","")))
	kit_line(list,effect_text(str(definition.get("effect_summary","성의 고정 구역입니다."))),"SelectedRoomEffect",MUTED)
	if not root._can_change_room_facility(root.selected_room): kit_line(list,root.continuity.localized("고정 구역 · 건설 대상 아님","Fixed area · Cannot build","固定区域 · 不可建造"),"FixedRoomReason",GOLD)
	kit_line(list,root._build_preview_route_line(root.selected_room),"SelectedRoomRoute",MUTED)
	kit_line(list,"방 지침 · 이 방에 적용","",GOLD)
	var directives := kit_flow(list,true)
	directives.name = "SelectedRoomDirectiveOption"
	for option in root._room_directive_options(root.selected_room):
		var value := str(option.get("value",""))
		var caption: String = LanguageSettings.ui_text(str(option.get("label",""))).split(" · ")[0]
		var b := kit_button(directives,caption,Rect2(),Callable(root,"_set_room_directive").bind(value),"RoomDirective_"+value,"tactical")
		b.tooltip_text = LanguageSettings.ui_text(root._room_directive_description(value))
		if value == str(root.room_directives.get(root.selected_room,Constants.ROOM_DIRECTIVE_NONE)): b.set_variant(1)
		var tutorial_id: String = {Constants.ROOM_DIRECTIVE_ENTRY_BLOCK:"ROOM_DIRECTIVE_BLOCK_ENTRANCE",Constants.ROOM_DIRECTIVE_TRAP_LURE:"ROOM_DIRECTIVE_TRAP_LURE",Constants.ROOM_DIRECTIVE_RETREAT:"ROOM_DIRECTIVE_RETREAT_LINE"}.get(value,"")
		if tutorial_id != "": root.register_tutorial_target_control(tutorial_id,b)
	kit_line(list,root._room_directive_description(str(root.room_directives.get(root.selected_room,Constants.ROOM_DIRECTIVE_NONE))),"SelectedRoomDirectiveDescription",MUTED)
	var level: int = root._facility_upgrade_level(root.selected_room)
	kit_line(list,"Lv.%d → Lv.%d" % [level,mini(level+1,root._facility_upgrade_level_cap())],"FacilityUpgradePreview",GOLD)
	kit_line(list,root.continuity.localized("시설 HP %d → %d\n시설 정원 %d → %d","Facility HP %d → %d\nFacility capacity %d → %d","设施生命 %d → %d\n设施容量 %d → %d") % [int(room.get("hp",0)),int(room.get("hp",0))+80,int(room.get("max_monsters",0)),mini(8,int(room.get("max_monsters",0))+1)],"FacilityUpgradeStats",MUTED)
	cost_row(list,root._facility_upgrade_cost(root.selected_room))
	var upgrade := kit_button(list,"강화",Rect2(),Callable(root,"_upgrade_selected_facility"),"FacilityUpgradeButton","tactical","build")
	_upgrade_state(list,upgrade,Rect2())
	var replace := kit_button(list,"시설 교체",Rect2(),Callable(root,"_open_build_palette_for_room").bind(root.selected_room),"OpenContextFacilityPaletteButton","tactical","build")
	replace.disabled = not root._can_change_room_facility(root.selected_room)

func _upgrade_state(drawer: Control, upgrade: Button, _reason_rect: Rect2) -> void:
	var reason: String = root._facility_upgrade_block_reason(root.selected_room)
	upgrade.disabled = reason != ""
	upgrade.tooltip_text = reason if reason != "" else root.continuity.localized("표시된 비용으로 시설 한 단계 강화", "Upgrade one level for the displayed cost", "按显示费用强化一级")
	if reason != "": kit_line(drawer,reason,"FacilityUpgradeReason",MUTED)

func _review_bar() -> void:
	preview_panel = kit_panel(Rect2(24,264,640,430),"BuildingReviewBar")
	preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var list := kit_content(preview_panel,16)
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kit_line(list,"","BuildReviewSummary",GOLD)
	kit_line(list,"","BuildReviewCost")
	kit_line(list,"","BuildReviewEffects",MUTED)
	kit_line(list,"","BuildReviewWarning",GOLD)
	var actions := kit_flow(list)
	var confirm := kit_button(actions,"건설 확정",Rect2(),Callable(root,"_confirm_build_preview"),"ConfirmFacilityReplacementButton","tactical","check")
	confirm.visible = root.build_preview_room_id != ""
	kit_button(actions,"취소 · ESC",Rect2(),Callable(root,"_cancel_management_action_mode"),"CancelBuildingButton","utility","close")
	refresh_preview()

func refresh_preview() -> void:
	if not is_instance_valid(preview_panel): return
	var room_id: String = root.build_preview_room_id if root.build_preview_room_id != "" else root.build_placement.hover_room
	if room_id == "": room_id = root.build_palette_target_room
	var assessment: Dictionary = root._evaluate_facility_placement(room_id,root.build_pick_facility_id)
	var definition: Dictionary = root._facility_definition(root.build_pick_facility_id)
	var texts := {
		"BuildReviewSummary": str(definition.get("display_name","시설을 먼저 고르세요.")),
		"BuildReviewCost": root.continuity.localized("비용: %s","Cost: %s","费用：%s") % LanguageSettings.ui_text(root._facility_cost_label(root.build_pick_facility_id)),
		"BuildReviewEffects": effect_text(str(definition.get("effect_summary",""))) + "\n" + LanguageSettings.ui_text(root._build_preview_route_line(room_id)),
		"BuildReviewWarning": ("\n".join(PackedStringArray(assessment.get("warnings",[]))) if bool(assessment.get("ok",false)) else str(assessment.get("reason",""))) + "\n" + root.continuity.localized("클릭·놓기 즉시 확정 / ESC 취소","Click or drop to confirm / ESC cancels","点击或放下立即确认 / ESC取消")
	}
	for id in texts:
		var label := preview_panel.find_child(id,true,false) as Label
		if label != null: label.text = LanguageSettings.ui_text(texts[id])
	var confirm := preview_panel.find_child("ConfirmFacilityReplacementButton",true,false) as Button
	if confirm != null: confirm.disabled = not root._build_preview_ready()

func _tutorial_needs_room_directive() -> bool:
	if not root.onboarding_enabled or not root.tutorial_gate_enabled: return false
	if not root.tutorial_manager.is_active_for_stage(root.onboarding_stage_id): return false
	return root.tutorial_manager.current_step_id() in ["TUT_120_TRAP_LURE","TUT_220_RETREAT_LINE"]

func _touch_inspector() -> void:
	_inspector()
