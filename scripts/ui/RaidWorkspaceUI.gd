extends "res://scripts/ui/ManagementWorkspaceUI.gd"

func build_raid() -> void:
	root._unlock_kobold_scout_commander()
	root._ensure_raid_selection()
	var screen := panel(Rect2(0,0,1920,1080), "RaidWorkspace")
	hud.build_top_bar()
	var missions := panel(Rect2(24,100,524,854), "RaidMissionPanel")
	copy(missions, "원정 계획", Rect2(24,14,476,48), 30, GOLD)
	var list := scroll_list(missions, Rect2(20,82,484,748), "RaidMissionsScroll")
	for value in root._available_raid_ids():
		var id := str(value)
		var mission := DataRegistry.raid_mission(id)
		var b := button(list, "", Rect2(0,0,456,240), Callable(root,"_select_raid_mission").bind(id), "RaidMission_" + id, "tactical")
		b.custom_minimum_size = Vector2(456,240)
		b.disabled = root._raid_choice_locked(id)
		copy(b, str(mission.get("title",id)), Rect2(20,10,416,78), 26)
		copy(b, "보상 · " + root._raid_expected_reward_label(mission), Rect2(20,94,416,62), 22, MUTED)
		copy(b, "완료" if root.completed_raids.has(id) else ("다른 계획 확정" if b.disabled else "위험 · %s / %s" % [mission.get("difficulty",""),mission.get("risk","")]), Rect2(20,160,416,66),20,GOLD)
		if id == root.raid_selected_mission_id:
			hud.apply_button_state(b,"selected")
	var mission := DataRegistry.raid_mission(root.raid_selected_mission_id)
	var detail := panel(Rect2(572,100,784,854), "RaidSelectedMission")
	var content := scroll_list(detail,Rect2(24,20,736,814),"RaidDetailScroll")
	line(content,str(mission.get("title","임무를 선택하세요.")),708,88,32,GOLD)
	line(content,str(mission.get("summary","")),708,128,24)
	for field in [["비용",root._raid_cost_label(mission)],["보상",root._raid_expected_reward_label(mission)],["순보상",root._raid_net_reward_label(mission)]]:
		line(content,"%s · %s" % field,708,68,24,MUTED)
	var preview: Dictionary = root._raid_defense_preview(mission)
	var timing := line(content,str(preview.get("timing", "")),708,44,24,GOLD)
	timing.name = "RaidEffectTiming"
	var changes := line(content,str(preview.get("changes", "")),708,80,22,GOLD)
	changes.name = "RaidWaveChanges"
	line(content,str(mission.get("next_defense_modifier",{}).get("description",mission.get("description","영향 없음"))),708,104,22)
	if not root.last_raid_result.is_empty():
		line(content,"최근 원정 보고",708,42,24,GOLD)
		line(content,"\n".join(root.last_raid_result.get("lines",[])),708,192,22)
	else:
		line(content,"브리핑",708,42,24,GOLD)
		line(content,"\n".join(mission.get("briefing_lines",[])),708,170,22)
	var roster := panel(Rect2(1380,100,516,854),"RaidRosterPanel")
	copy(roster,"원정대",Rect2(24,14,468,48),30,GOLD)
	var captain: String = root._raid_fixed_captain_id(mission)
	if captain != "":
		var path: String = root.management_scene.monster_portrait_path(captain)
		hud.texture(roster,path,Rect2(24,82,124,150))
		copy(roster,"로로 · 작전 지휘",Rect2(168,88,324,46),26)
		copy(roster,"원정 슬롯을 쓰지 않고 지휘\n악명 보상 +10%",Rect2(168,140,324,92),22,MUTED)
	var members := scroll_list(roster,Rect2(24,258,468,496),"RaidMembersScroll")
	for value in root.monster_roster.keys():
		var id := str(value)
		if id == captain:
			continue
		var selected: bool = root.raid_selected_monster_ids.has(id)
		var b := button(members,"",Rect2(0,0,440,112),Callable(root,"_toggle_raid_monster").bind(id),"RaidMember_" + id,"tactical")
		b.custom_minimum_size = Vector2(440,112)
		var path: String = root.management_scene.monster_portrait_path(id)
		if path != "":
			hud.texture(b,path,Rect2(8,8,92,96))
		copy(b,root._monster_display_name(id),Rect2(116,12,300,40),24)
		copy(b,"선택됨" if selected else "눌러서 호위로 편성",Rect2(116,60,300,38),22,GOLD if selected else MUTED)
		if selected:
			hud.apply_button_state(b,"selected")
	copy(roster,root._raid_roster_hint(),Rect2(24,770,468,60),22,MUTED)
	var back := button(screen,"방어 준비",Rect2(24,980,320,64),Callable(root,"_onboarding_finish_raid_preview"),"RaidBackButton")
	back.disabled = root._day_four_intro_raid_pending()
	copy(screen,root._raid_start_hint(),Rect2(374,978,1006,76),24,MUTED,"RaidStartReason")
	var start := button(screen,"원정 출발",Rect2(1452,980,444,64),Callable(root,"_start_selected_raid"),"RaidStartButton","primary")
	start.disabled = not root._can_start_selected_raid()
	if root.completed_raids.has(root.raid_selected_mission_id):
		start.text = "완료된 원정"
	elif root._raid_choice_locked(root.raid_selected_mission_id):
		start.text = "다른 계획 확정"

func scroll_list(parent: Control, rect: Rect2, id: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = id
	scroll.position = rect.position
	scroll.size = rect.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	parent.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",16)
	scroll.add_child(list)
	return list

func line(parent: Control, text: String, width: float, height: float, font_size: int, color: Color = PAPER) -> Label:
	var label := copy(parent,text,Rect2(0,0,width,height),font_size,color)
	label.custom_minimum_size = Vector2(width,height)
	return label
