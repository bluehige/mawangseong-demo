extends "res://scripts/ui/ManagementWorkspaceUI.gd"
# U5-C composes the U5-B surfaces and controls; gameplay remains in the controllers.
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
var tactics_open := false
var action_row: HBoxContainer
var hp_bar: ProgressBar
var status: Label
var points: Label
var threat: Label
var speed_buttons: Dictionary = {}
var pause_button: Button
var heart_button: Button
var duo_buttons: Dictionary = {}

func setup(game: Node, _controller) -> void:
	root = game

func l(ko: String, en: String, zh: String) -> String:
	return root.continuity.localized(ko, en, zh)

func pane(rect: Rect2, id: String) -> Panel:
	var result := kit_panel(rect, id)
	result.set_meta("u5c_hud", true)
	return result

func flow(parent: Control, vertical: bool = false) -> BoxContainer:
	return kit_flow(parent, vertical)

func text(parent: Control, value: String, id: String = "") -> Label:
	var result := Kit.label(LanguageSettings.ui_text(value), "support", true)
	result.name = id if id != "" else "CombatCopy"
	result.tooltip_text = result.text
	parent.add_child(result)
	return result

func action(parent: Node, value: String, callback: Callable, id: String, icon_id: String = "") -> Button:
	var result := kit_button(parent, value, Rect2(), callback, id, "utility", icon_id)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.custom_minimum_size.x = 180
	result.add_theme_constant_override("icon_max_width", 36)
	result.add_theme_font_size_override("font_size",Kit.Tokens.font_size(24,UISettings.text_scale,UISettings.is_touch_ui()))
	return result

func scroll_body(panel: Control) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = str(panel.name)+"Scroll"
	var head := 132.0 if UISettings.is_touch_ui() else 120.0
	scroll.position = Vector2(18, head)
	scroll.size = panel.size-Vector2(36,head+18)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var body := flow(scroll, true) as VBoxContainer
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return body

func title(panel: Control, value: String, callback: Callable, id: String) -> void:
	var close_width := 164.0 if UISettings.is_touch_ui() else 132.0
	kit_copy(panel, value, Rect2(18,16,panel.size.x-close_width-54,62),26)
	kit_button(panel,l("닫기","Close","关闭"),Rect2(panel.size.x-close_width-18,16,close_width,100 if UISettings.is_touch_ui() else 84),callback,id)

func build_core() -> void:
	shared_theme = null
	speed_buttons.clear(); duo_buttons.clear(); heart_button = null
	var header := pane(Rect2(16,8,1888,96 if UISettings.is_touch_ui() else 80),"CombatThroneStatus")
	var row := kit_content(header, 8)
	var rail := flow(row)
	var day := text(rail,"DAY %02d" % GameState.day,"CombatDay")
	day.custom_minimum_size.x = 120
	rail.add_child(Kit.image("throne",40))
	hp_bar = ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.tooltip_text = l("왕좌 체력", "Throne HP", "王座生命")
	hp_bar.theme_type_variation = "KitHP"
	hp_bar.custom_minimum_size = Vector2(200,24)
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rail.add_child(hp_bar)
	status = text(rail,"","CombatGoalHP"); status.custom_minimum_size.x = 200
	points = text(rail,"","CombatCommandPoints"); points.custom_minimum_size.x = 210
	rail.add_child(Kit.image("mana",40))
	root.hud.resource_value_labels["mana"] = text(rail,str(GameState.mana),"CombatMana")
	root.hud.resource_value_labels["mana"].custom_minimum_size.x = 100
	threat = text(rail,"","CombatDefenseProgress")
	for spec in [["CombatDetails",l("전투 기록","Battle log","战斗记录"),"info",Callable(root,"_open_combat_context_drawer")],["CombatMenu",l("메뉴","Menu","菜单"),"menu",Callable(root,"_open_pause_menu")]]:
		var b := kit_button(rail,spec[1],Rect2(0,0,150,48),spec[3],spec[0],"utility",spec[2])
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.text=""
		b.tooltip_text=spec[1]
		if spec[0]=="CombatMenu": root.register_tutorial_target_control("CommonGameMenuButton",b)
	Kit.inherit_theme(header,kit_theme())
	# The dense header is the same compact variant as U5-B.
	for b in header.find_children("*","Button",true,false): b.custom_minimum_size.y=48
	root.register_tutorial_target_control("BossHpBar",header)
	var commands := pane(Rect2(16,904,1264,160) if UISettings.is_touch_ui() else Rect2(16,952,1264,112),"CombatCommandBar")
	var command_row := flow(kit_content(commands,8))
	for spec in [["rally","GLOBAL_DIRECTIVE_DEFEND","tactics"],["focus","V122_COMMAND_FOCUS","battle_start"],["emergency_fallback","V122_COMMAND_FALLBACK","undo"]]:
		var b := action(command_row,"",Callable(root,"_issue_v122_command").bind(spec[0]),spec[1],spec[2])
		b.set_meta("ui_audio_silent",true)
		root.hud.v122_command_buttons[spec[0]]=b
	var room: Dictionary = root.rooms.get(root.selected_room,{})
	if str(room.get("facility_role","")) in ["barracks","recovery","watch_post","ward_core"] and root._facility_room_is_active(root.selected_room):
		action(command_row,l("시설 가동","Activate facility","启动设施"),Callable(root,"_issue_v122_selected_facility"),"V122_COMMAND_FACILITY_CONTEXT","build")
	Kit.inherit_theme(commands,kit_theme())
	var policy := kit_button(root.ui_layer,l("전술 · 성 전체 / 이 방","Tactics · Castle / Room","战术 · 全城 / 此房间"),Rect2(16,646,640,74) if UISettings.is_touch_ui() else Rect2(16,746,600,70),Callable(self,"toggle_tactics"),"CombatTacticsToggle","utility","tactics")
	policy.set_meta("u5c_hud",true)
	var specials := pane(Rect2(16,732,1264,160) if UISettings.is_touch_ui() else Rect2(16,828,1264,112),"CombatSpecialActions")
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left=8; scroll.offset_right=-8; scroll.offset_top=4; scroll.offset_bottom=-4
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	specials.add_child(scroll)
	action_row=flow(scroll) as HBoxContainer
	build_selected_actions()
	root.hud.build_combat_special_actions_panel()
	if action_row.get_child_count()==0: specials.hide()
	Kit.inherit_theme(specials,kit_theme())
	root.hud.build_speed_panel()
	update_status(); update_commands()

func toggle_tactics() -> void:
	tactics_open = not tactics_open
	root._set_screen("combat",false)

func build_tactics() -> void:
	var panel := pane(Rect2(16,184,640,446) if UISettings.is_touch_ui() else Rect2(16,260,640,470),"CombatTacticsPanel")
	title(panel,l("전술 · 지속 정책","Tactics · Standing policy","战术 · 持续策略"),Callable(self,"toggle_tactics"),"CombatTacticsClose")
	var body := scroll_body(panel)
	text(body,l("성 전체","Castle-wide","全城"))
	var global: OptionButton = root.hud.option_button(body,Rect2(),[
		{"label":l("사수","Hold the Line","坚守"),"value":Constants.DIRECTIVE_DEFENSE},
		{"label":l("총공격","All-Out Attack","总攻"),"value":Constants.DIRECTIVE_ALL_OUT},
		{"label":l("생존 우선","Survival First","生存优先"),"value":Constants.DIRECTIVE_SURVIVAL}],root.global_directive,Callable(root,"_set_global_directive"),26,"CombatGlobalDirective")
	global.custom_minimum_size.y=76
	global.disabled=root._day_one_global_directive_locked()
	global.tooltip_text=l("성 전체 지침. DAY 01은 사수로 고정됩니다.","Castle-wide policy. DAY 01 is locked to Hold the Line.","全城方针。第1天固定为坚守。")
	text(body,l("이 방 · ","This room · ","此房间 · ")+LanguageSettings.ui_text(root.display_name_for_instance(root.selected_room)))
	var room: OptionButton = root.hud.option_button(body,Rect2(),root._room_directive_options(root.selected_room),root.room_directives.get(root.selected_room,Constants.ROOM_DIRECTIVE_NONE),Callable(root,"_set_room_directive"),26,"CombatSelectedRoomDirective")
	room.custom_minimum_size.y=76
	room.tooltip_text=l("선택한 방의 지속 지침","Standing policy for the selected room","所选房间的持续方针")
	text(body,l("선택 유닛 · 스킬은 자동 사용을 유지하며 아래 행동으로 직접 발동할 수 있습니다.","Selected unit · Skills keep automatic use; trigger them directly below.","所选单位 · 保持自动使用技能，也可通过下方操作立即施放。"))
	Kit.inherit_theme(panel,kit_theme())
	for option in [global,room]:
		for state in ["normal","hover","pressed","disabled","focus"]: option.remove_theme_stylebox_override(state)
		option.get_popup().theme=kit_theme()

func build_selected_actions() -> void:
	root.hud.manual_skill_controls.clear(); root.hud.pynn_controls.clear()
	var unit = root.selected_unit
	if not is_instance_valid(unit) or str(unit.faction)==Constants.FACTION_ENEMY: return
	if root.hud._has_pynn_controls(unit,false):
		root.hud.pynn_controls={"unit":unit,"modes":{},"skills":{}}
		for id in ["fireball","flame_zone","tricolor_demonfire"]:
			root.hud.pynn_controls.skills[id]=action(action_row,"",Callable(root.hud,"_request_pynn_manual_skill").bind(unit,id),"PynnCast_"+id,"tactics")
		root.hud._update_pynn_controls()
	else:
		root.hud.manual_skill_controls={"unit":unit,"skills":{}}
		for value in root.combat_scene.skill_slots_for(unit):
			if value==null or str(value) not in root.combat_scene.IMPLEMENTED_ACTION_SKILLS: continue
			var id := str(value)
			var b := action(action_row,"",Callable(root.hud,"_request_manual_skill").bind(unit,id),"ManualCast_"+id,"tactics")
			b.tooltip_text=LanguageSettings.ui_text(str(DataRegistry.skill(id).get("description",id)))
			root.hud.manual_skill_controls.skills[id]=b
		root.hud._update_manual_skill_controls()

func build_special_actions() -> void:
	var heart: Dictionary=root.update3_active_run.get("heart",{})
	if str(heart.get("heart_id",""))!="" and bool(heart.get("awakened",false)):
		heart_button=action(action_row,"",Callable(root,"_activate_update3_heart"),"CombatHeartActivate","throne")
	var duo: Dictionary=root._update3_duo_link_hud_state()
	var equipped: Array=duo.get("equipped",[])
	for i in range(mini(2,equipped.size())):
		var id:=str(equipped[i])
		duo_buttons[id]=action(action_row,"",Callable(root,"_activate_update3_duo_link").bind(id),"CombatDuoActivate_%d"%i,"monster")
	if root._update4_council_mode_active() and bool(root.update4_active_run.get("upper_floor",{}).get("unlocked",false)):
		var panel:=pane(Rect2(900,112,380,112 if UISettings.is_touch_ui() else 84),"CombatFloorControls")
		var row:=flow(kit_content(panel,4))
		for id in ["1F","2F"]:
			var b:=action(row,id,Callable(root,"_select_update4_visible_floor").bind(id),"CombatFloor"+id.left(1),"encyclopedia")
			b.custom_minimum_size.x=150; b.custom_minimum_size.y=64
			b.set_variant(1 if str(root.update4_active_run.upper_floor.get("graph_runtime",{}).get("visible_floor","1F"))==id else 0)
		Kit.inherit_theme(panel,kit_theme())

func build_speed() -> void:
	var panel:=pane(Rect2(1300,904,604,160) if UISettings.is_touch_ui() else Rect2(1300,952,604,112),"CombatSpeedPanel")
	var row:=flow(kit_content(panel,4))
	row.add_theme_constant_override("separation",4)
	for value in [1.0,1.5,2.0,3.0]:
		var b:=action(row,{1.0:"×1",1.5:"×1.5",2.0:"×2",3.0:"×3"}[value],Callable(root,"_set_speed").bind(value),{1.0:"CombatSpeed1x",1.5:"CombatSpeed15x",2.0:"CombatSpeed2x",3.0:"CombatSpeed3x"}[value])
		b.custom_minimum_size.x=82
		b.autowrap_mode=TextServer.AUTOWRAP_OFF
		b.disabled=value>1 and not root._combat_speed_unlocked()
		b.tooltip_text=l("전투 속도 · 튜토리얼 후 해금","Battle speed · unlocks after tutorial","战斗速度 · 教程后解锁")
		speed_buttons[value]=b
	pause_button=action(row,"",Callable(root.combat_scene,"toggle_pause"),"CombatPause","pause")
	pause_button.custom_minimum_size.x=84
	pause_button.tooltip_text=l("일시정지 / 재개","Pause / resume","暂停 / 继续")
	Kit.inherit_theme(panel,kit_theme())

func build_inspector() -> void:
	var unit=root.selected_unit
	if not is_instance_valid(unit): return
	var enemy: bool=str(unit.faction)==Constants.FACTION_ENEMY
	root.hud.selected_unit_dynamic_labels.clear(); root.hud.selected_unit_displayed_id=unit.get_instance_id()
	var width:=600.0 if UISettings.is_touch_ui() else 434.0
	var panel:=pane(Rect2(1904-width,184,width,640),"CombatUnitInspector")
	title(panel,l("선택 유닛","Selected unit","所选单位"),Callable(root,"_clear_combat_unit_selection"),"CombatUnitInspectorClose")
	var body:=scroll_body(panel)
	var portrait: TextureRect=root.hud._combat_unit_portrait(body,unit,enemy,Rect2(0,0,144,140))
	portrait.custom_minimum_size=Vector2(144,140)
	for pair in [["name",root.hud._combat_unit_display_name(unit,enemy)],["role",root.hud._combat_unit_role_label(unit,enemy)],["hp","%d / %d"%[unit.hp,unit.max_hp]],["stats",l("공격 %d · 방어 %d","ATK %d · DEF %d","攻击 %d · 防御 %d")%[unit.atk,unit.def]],["room",root.display_name_for_instance(str(unit.current_room))],["state",root.hud._combat_unit_state_text(unit)],["objective",root.hud._combat_unit_objective_text(unit,enemy)],["status",root.hud._combat_unit_status_text(unit,enemy)]]:
		if pair[0] == "room":
			var location := flow(body)
			var caption := text(location,l("위치","Location","位置"),"CombatUnitLocationTitle")
			caption.custom_minimum_size.x=140
			caption.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
			root.hud.selected_unit_dynamic_labels[pair[0]]=text(location,str(pair[1]),"CombatSelected_room")
		else:
			root.hud.selected_unit_dynamic_labels[pair[0]]=text(body,str(pair[1]),"CombatSelected_"+pair[0])
	if root.hud._has_pynn_controls(unit,enemy):
		text(body,l("선택 유닛 · 삼색 정책","Selected unit · Tricolor policy","所选单位 · 三色策略"))
		for mode in ["single_flame","area_flame","ember_curse"]:
			root.hud.pynn_controls.modes[mode]=action(body,"",Callable(root.hud,"_choose_pynn_mode").bind(unit,mode),"PynnMode_"+mode)
		root.hud.pynn_controls["auto"]=text(body,"")
		root.hud._update_pynn_controls()
	Kit.inherit_theme(panel,kit_theme())

func build_context(_targeting: Dictionary={}) -> void:
	var panel:=pane(Rect2(1264,184,640,640),"CombatContextDrawer")
	title(panel,l("전투 기록","Battle log","战斗记录"),Callable(root,"_close_combat_context_drawer"),"CombatContextClose")
	var body:=scroll_body(panel)
	for line in root.logs: text(body,LanguageSettings.ui_text(str(line)))
	if root.logs.is_empty(): text(body,l("기록이 없습니다.","No battle events yet.","暂无战斗记录。"))
	Kit.inherit_theme(panel,kit_theme())

func update_status() -> void:
	if not is_instance_valid(status): return
	var model: Dictionary=root.get_meta("v122_combat_view_model",{})
	var hp:=int(model.get("throne_hp",GameState.demon_lord_hp))
	var maximum:=maxi(1,int(model.get("throne_hp_max",GameState.demon_lord_max_hp)))
	hp_bar.max_value=maximum; hp_bar.value=hp
	status.text="%d / %d"%[hp,maximum]
	points.text=l("명령 %d / %d","Orders %d / %d","指令 %d / %d")%[int(model.get("command_points",0)),int(model.get("command_points_max",0))]
	var remaining := 0
	for enemy in root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive(): remaining+=1
	for i in range(root.wave_manager.next_index,root.wave_manager.schedule.size()): remaining+=int(root.wave_manager.schedule[i].get("count",1))
	threat.text=l("남은 적 %d","Enemies %d","剩余敌人 %d")%remaining
	threat.tooltip_text=l("방어 %d%%", "Defense %d%%", "防守 %d%%")%roundi(float(model.get("defense_progress",0))*100)+"\n"+LanguageSettings.ui_text(root.hud._v122_threat_text(model))

	if is_instance_valid(pause_button):
		pause_button.icon=Kit.Icons.get_icon("play" if root.combat_scene.requested_pause else "pause")
	for speed in speed_buttons:
		if is_instance_valid(speed_buttons[speed]): speed_buttons[speed].set_variant(1 if is_equal_approx(root.combat_speed,speed) else 0); speed_buttons[speed].disabled=speed>1 and not root._combat_speed_unlocked()
	var heart: Dictionary=root.update3_active_run.get("heart",{})
	if is_instance_valid(heart_button):
		heart_button.text=l("심장","Heart","心脏")+" %d/100"%clampi(int(heart.get("charge",0)),0,100)
		heart_button.disabled=int(heart.get("charge",0))<100 or bool(heart.get("active_used_this_battle",false)) or bool(heart.get("disabled_this_battle",false))
	var duo: Dictionary=root._update3_duo_link_hud_state()
	for id in duo_buttons:
		var b: Button=duo_buttons[id]
		if not is_instance_valid(b): continue
		var state: Dictionary=duo.get("states",{}).get(id,{})
		b.text=LanguageSettings.ui_text(str(duo.get("names",{}).get(id,id)))+" %d/100"%clampi(int(state.get("charge",0)),0,100)
		b.disabled=not bool(state.get("active",false)) or bool(state.get("used_this_battle",false)) or int(state.get("charge",0))<100

func update_commands() -> void:
	var model: Dictionary=root.get_meta("v122_combat_view_model",{})
	for spec in model.get("commands",[]):
		var id:=str(spec.get("id",""))
		var b= root.hud.v122_command_buttons.get(id)
		if not is_instance_valid(b): continue
		var state: Dictionary=root.get_meta("v122_command_state",{})
		var cooldown:=float(state.get("cooldowns",{}).get(id,spec.get("cooldown_seconds",0)))
		var active: Dictionary=state.get("active_commands",{}).get(id,{})
		var remaining:=float(active.get("remaining_seconds",spec.get("active_seconds",0)))
		var cost:=int(spec.get("cost",0))
		var detail:=l("명령 %d","Orders %d","指令 %d")%cost
		if cooldown>0.05: detail=l("대기 %.1f초","Wait %.1fs","等待 %.1f秒")%cooldown
		elif remaining>0.05: detail=l("발동 %.1f초","Active %.1fs","生效 %.1f秒")%remaining
		b.text=LanguageSettings.ui_text(str(spec.get("label",id)))+"\n"+detail
		b.tooltip_text=LanguageSettings.ui_text(str(spec.get("description","")))+"\n"+l("명령 선택 → 노란 대상 선택. ESC/우클릭 취소.","Choose an order, then a yellow target. ESC/right-click cancels.","选择指令后选择黄色目标。ESC/右键取消。")
		b.set_variant(1 if id==root.combat_scene.pending_v122_command_id or remaining>0.05 else 0)
		b.modulate=Color(0.65,0.65,0.65) if cooldown>0 or int(state.get("points",0))<cost else Color.WHITE
		# Keep refusal feedback reachable, matching the existing command contract.
		b.disabled=false
