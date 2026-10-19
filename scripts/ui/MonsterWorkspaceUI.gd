extends "res://scripts/ui/ManagementWorkspaceUI.gd"
const Tabs = preload("res://scripts/ui/kit/KitTabs.gd")
const StatBar = preload("res://scripts/ui/kit/KitStatBar.gd")
const Contracts = preload("res://scripts/systems/contracts/ContractRosterService.gd")
var active_tab := "training"
var list_mode := "owned"
var inspected_id := ""
var codex_id := ""
var last_training: Dictionary = {}
var promotion_choice := 0
var action_footer: VBoxContainer

func loc(ko: String, en: String, zh: String) -> String:
	return root.continuity.localized(ko,en,zh)

func build_monster() -> void:
	shared_theme = null
	action_footer = null
	_background()
	root._ensure_selected_monster_available_for_defense()
	if inspected_id == "" or not root.monster_roster.has(inspected_id) or root._monster_available_for_defense(inspected_id): inspected_id = root.selected_monster_id
	var rail := kit_panel(Rect2(24,16,1750,68),"MonsterResourceRail")
	for i in range(4):
		var resource: String = ["gold","mana","food","infamy"][i]
		var icon := ManagementKit.image(resource,40)
		icon.position = Vector2(20+i*320,14)
		rail.add_child(icon)
		kit_copy(rail,str(GameState.get(resource)),Rect2(78+i*320,12,220,44),28,PAPER,"MonsterResource_"+resource)
	kit_copy(rail,"DAY %02d" % GameState.day,Rect2(1450,12,250,44),28,GOLD)
	_preserve_layout(rail)
	var left := kit_panel(Rect2(24,100,400,956),"MonsterRosterPanel")
	var column := kit_content(left,20)
	kit_line(column,loc("동료","Companions","伙伴"),"",GOLD)
	var scopes := HFlowContainer.new()
	scopes.name = "MonsterListScopes"
	scopes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scopes)
	for scope in [["owned",loc("보유","Owned","持有")],["codex",loc("도감","Codex","图鉴")]]:
		var b := kit_button(scopes,scope[1],Rect2(),_scope.bind(scope[0]),"MonsterScope_"+scope[0])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("kit_selected",list_mode == scope[0])
		b.theme_type_variation = "KitPrimary" if list_mode == scope[0] else "Button"
		b.surface.sync(b)
	var scroll := ScrollContainer.new()
	scroll.name = "MonsterRosterScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	var list := kit_flow(scroll,true)
	var ids: Array = root.monster_roster.keys() if list_mode == "owned" else DataRegistry.update2_contracts.keys()
	if list_mode == "codex": ids = root.monster_roster.keys() + ids.filter(func(value): return not root.monster_roster.has(value))
	for value in ids:
		var id := str(value)
		var owned: bool = root.monster_roster.has(id)
		var caption: String = root._monster_companion_name(id) if owned else "???"
		var status: Dictionary = root._monster_roster_status(id) if owned else {}
		var detail := "Lv.%d · %s" % [int(root.monster_roster[id].get("level",1)),LanguageSettings.ui_text({"reserve":"예비","support":"지원 전용","unavailable":"출전 불가"}.get(str(status.state),"출전"))] if owned else loc("다음 회차","Next cycle","下周目")
		var target: String = root.management_scene._tutorial_monster_target_id(id) if list_mode == "owned" and root._monster_available_for_defense(id) else "MonsterRoster_"+id
		if target == "": target = "MonsterRoster_"+id
		var row := kit_button(list,"",Rect2(),_select_owned.bind(id) if list_mode == "owned" else _select_codex.bind(id),target,"tactical")
		row.custom_minimum_size.y = 148 if UISettings.is_touch_ui() else 124
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.tooltip_text = caption+" · "+detail
		var content := kit_content(row,10)
		var h := kit_flow(content)
		var art := _art(h,id,Vector2(82,90),not owned)
		art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var words := kit_flow(h,true)
		kit_line(words,caption,"",GOLD if id == inspected_id else PAPER)
		kit_line(words,detail,"",MUTED)
		row.set_meta("kit_selected",id == (codex_id if list_mode == "codex" else inspected_id))
		row.theme_type_variation = "KitPrimary" if row.get_meta("kit_selected",false) else "Button"
		row.surface.sync(row)
	if root._contract_roster_available():
		var roster_button := kit_button(column,loc("편성","Roster","编组"),Rect2(),Callable(root,"_open_contract_roster"),"MonsterContractRoster")
		roster_button.tooltip_text = loc("계약 동료 · 출전·예비 편성","Contract companions · Deployment and reserves","契约伙伴 · 出战与待命编组")
	kit_button(column,loc("기록실로","Records","返回记录室") if root.records_companion_return else loc("관리로","Back","返回管理"),Rect2(),Callable(root,"_return_from_monster_records"),"MonsterBackButton","utility","close")
	_glass(left,0.85)
	_preserve_layout(left)
	if list_mode == "codex":
		_codex()
		return
	var id: String = inspected_id
	var pane := kit_panel(Rect2(448,100,1448,956),"MonsterGrowthTools")
	if id == "" or not root.monster_roster.has(id): return
	var roster: Dictionary = root.monster_roster[id]
	var data := DataRegistry.monster(id)
	_glass(pane,0.48)
	var main := kit_content(pane,24)
	var columns := kit_flow(main)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",24)
	var hero := Control.new()
	hero.name = "MonsterHero"
	hero.custom_minimum_size.x = 400
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(hero)
	# S1/tutorial callers read the first label of this named detail.
	var header := Control.new()
	header.name = "MonsterSelectedDetail"
	header.position = Vector2(8,8)
	header.size = Vector2(384,300)
	hero.add_child(header)
	kit_copy(header,root._monster_companion_name(id),Rect2(0,0,384,60),42,GOLD,"MonsterName")
	var status: Dictionary = root._monster_roster_status(id)
	kit_copy(header,hud.role_display_name(str(root._monster_promotion_rule(id).get("role_tag",roster.get("role_tag",data.get("role",""))))),Rect2(0,70,384,80),30,PAPER,"MonsterRole")
	kit_copy(header,"Lv.%d" % int(roster.get("level",1)),Rect2(0,160,384,52),36,GOLD,"MonsterLevel")
	kit_copy(header,loc("유대 %d/100 · %s","Bond %d/100 · %s","羁绊 %d/100 · %s") % [int(roster.get("bond",0)),LanguageSettings.ui_text(root._monster_bond_rank_name(int(roster.get("bond",0))))],Rect2(0,224,384,68),26,MUTED,"MonsterBond")
	var pedestal := Panel.new()
	pedestal.name = "MonsterPedestal"
	pedestal.position = Vector2(16,724)
	pedestal.size = Vector2(368,42)
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.13,0.08,0.20,0.88)
	base.border_color = GOLD.darkened(0.35)
	base.set_border_width_all(2)
	base.set_corner_radius_all(24)
	base.shadow_color = Color(0.45,0.18,0.75,0.28)
	base.shadow_size = 18
	pedestal.add_theme_stylebox_override("panel",base)
	pedestal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(pedestal)
	var art := _art(hero,id,Vector2(400,416))
	var fitted: Vector2 = art.texture.get_size()*minf(400.0/art.texture.get_width(),416.0/art.texture.get_height())
	art.custom_minimum_size = fitted
	art.size = fitted
	art.position = Vector2((400-fitted.x)/2,730-fitted.y)
	kit_copy(hero,LanguageSettings.ui_text(str(status.label)),Rect2(8,796,384,92),24,PAPER,"MonsterDeployment")
	var tools := kit_flow(columns,true)
	var tabs := Tabs.new()
	tabs.name = "MonsterTabs"
	tools.add_child(tabs)
	var entries: Array = []
	for item in [["training",loc("훈련","Training","训练"),"experience"],["skills",loc("스킬","Skills","技能"),"tactics"],["promotion",loc("전직","Promotion","转职"),"tactics"],["duo",loc("합동기","Duo links","合击"),"monster"],["memory",loc("기억","Memories","记忆"),"log"]]:
		entries.append({"id":item[0],"label":item[1],"icon":item[2]})
	tabs.set_tabs(entries,active_tab)
	tabs.tab_selected.connect(_tab)
	ManagementKit.inherit_theme(tabs,kit_theme())
	for key in tabs._buttons:
		var tab: Button = tabs._buttons[key]
		tab.name = "MonsterTab_"+key
		tab.add_theme_font_size_override("font_size",24)
		tab.add_theme_constant_override("icon_max_width",32)
	var body_scroll := ScrollContainer.new()
	body_scroll.name = "MonsterGrowthScroll"
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.follow_focus = true
	tools.add_child(body_scroll)
	var body := kit_flow(body_scroll,true)
	action_footer = kit_flow(tools,true) as VBoxContainer
	action_footer.name = "MonsterActionFooter"
	match active_tab:
		"training": _training(body,id,roster,root._scaled_monster_stats(id))
		"skills": _skills(body,id); _specialization(body,id)
		"promotion": _promotion(body,id)
		"duo": _duo(body,id)
		"memory": root.management_scene.memory_archive_ui.build_tab(body,id)
	_preserve_layout(pane)

func _background() -> void:
	var art := TextureRect.new()
	art.name = "MonsterCastleBackground"
	art.texture = load("res://assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.size = Vector2(1920,1080)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.ui_layer.add_child(art)

func _glass(pane: Control, opacity: float) -> void:
	for child in pane.get_children():
		if child is Surface:
			child._material.set_shader_parameter("top_color",Color(0.16,0.10,0.23,opacity))
			child._material.set_shader_parameter("bottom_color",Color(0.05,0.03,0.09,opacity))

func card(parent: Control, id: String, padding: int = 18) -> VBoxContainer:
	var pane := PanelContainer.new()
	pane.name = id
	pane.theme = kit_theme()
	pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075,0.045,0.115,0.80)
	style.border_color = Color(0.47,0.35,0.55,0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: style.set_content_margin(side,padding)
	pane.add_theme_stylebox_override("panel",style)
	parent.add_child(pane)
	return kit_flow(pane,true) as VBoxContainer

func chip(parent: Control, text: String, id: String = "", color: Color = PAPER, icon: String = "") -> void:
	var content := card(parent,id+"Chip",10)
	var row := kit_flow(content)
	if icon != "": row.add_child(ManagementKit.image(icon,32))
	kit_line(row,text,id,color)

func _preserve_layout(node: Node) -> void:
	if node is Label: node.set_meta("hud_text_fit",true)
	for child in node.get_children(): _preserve_layout(child)

func _scope(mode: String) -> void:
	list_mode = mode
	root._set_screen(Constants.SCREEN_MONSTER)

func _select_owned(id: String) -> void:
	inspected_id = id
	if root._monster_available_for_defense(id): root._select_monster(id)
	else: root._set_screen(Constants.SCREEN_MONSTER)

func _select_codex(id: String) -> void:
	codex_id = id
	root._set_screen(Constants.SCREEN_MONSTER)

func _tab(id: String) -> void:
	active_tab = id
	root._set_screen(Constants.SCREEN_MONSTER)

func _art(parent: Control, id: String, dimensions: Vector2, silhouette: bool = false, path: String = "") -> TextureRect:
	var art := TextureRect.new()
	art.name = "MonsterPortrait_"+id
	var actual_path: String = path if path != "" else root.management_scene.monster_portrait_path(id)
	art.texture = load(actual_path) if actual_path != "" and ResourceLoader.exists(actual_path) else root.management_scene.monster_identity_texture(id)
	var regions := {"pudding_base.png":Rect2(48,276,1168,789),"gob_base.png":Rect2(55,12,1145,1281),"pynn_base.png":Rect2(68,42,1171,1184),"mori_base.png":Rect2(131,136,1052,994)}
	if regions.has(actual_path.get_file()):
		var detail := AtlasTexture.new()
		detail.atlas = art.texture
		detail.region = regions[actual_path.get_file()]
		art.texture = detail
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = dimensions
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if silhouette: art.modulate = Color(0.02,0.015,0.035,1)
	parent.add_child(art)
	return art

func training_preview(id: String) -> Dictionary:
	var roster: Dictionary = root.monster_roster[id]
	var level := int(roster.get("level",1))
	var exp: int = int(roster.get("exp",0))+root.MONSTER_TRAINING_EXP
	var guard := 0
	while exp >= root._monster_exp_to_next(level) and guard < 50:
		exp -= root._monster_exp_to_next(level)
		level += 1
		guard += 1
	return {"level":level,"exp":exp,"stats":root._scaled_monster_stats(id,level)}

func _bar(parent: Control, caption: String, exp: int, level: int, name: String) -> void:
	var bar := StatBar.new().configure(caption,exp,root._monster_exp_to_next(level))
	bar.name = name
	bar.progress.tooltip_text = "%s · EXP %d / %d · Lv.%d" % [caption,exp,root._monster_exp_to_next(level),level]
	parent.add_child(bar)
	ManagementKit.inherit_theme(bar,kit_theme())

func _training(parent: Control, id: String, roster: Dictionary, current: Dictionary) -> void:
	if root._early_specialization_required_for_current_day():
		kit_button(parent,LanguageSettings.text("feedback.specialization_heading"),Rect2(),_tab.bind("skills"),"RequiredGrowthHeading")
	var after := training_preview(id)
	var count := int(roster.get("training_count_today",0)) if int(roster.get("training_day",0)) == GameState.day else 0
	var reason: String = root._training_block_reason(id)
	if not root._monster_available_for_defense(id): reason = loc("지원 전용 · 훈련 불가","Support only · Training unavailable","仅支援 · 无法训练")
	elif reason == "" and not GameState.can_pay(root.MONSTER_TRAINING_COST): reason = loc("금화 부족","Not enough gold","金币不足")
	var preview := card(parent,"TrainingPreviewCard")
	kit_line(preview,loc("훈련 미리보기","Training preview","训练预览"),"",GOLD)
	kit_line(preview,"Lv.%d → Lv.%d" % [int(roster.level),int(after.level)],"TrainingExpPreview",GOLD).add_theme_font_size_override("font_size",32)
	_bar(preview,loc("현재","Current","当前"),int(roster.exp),int(roster.level),"TrainingBeforeBar")
	_bar(preview,loc("훈련 후","After","训练后"),int(after.exp),int(after.level),"TrainingAfterBar")
	var row := kit_flow(parent)
	var stats := card(row,"TrainingStatsCard")
	stats.get_parent().size_flags_stretch_ratio = 1.2
	for key in [["max_hp",loc("체력","HP","生命"),"hp"],["atk",loc("공격","Attack","攻击"),"attack"],["def",loc("방어","Defense","防御"),"shield"]]:
		var line := kit_flow(stats)
		line.add_child(ManagementKit.image(key[2],36))
		var label := kit_line(line,"%s  %d → %d  (+%d)" % [key[1],current[key[0]],after.stats[key[0]],int(after.stats[key[0]])-int(current[key[0]])],"TrainingStats_"+key[0])
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.tooltip_text = loc("같은 현재 준비 효과를 포함한 수치 비교","Both values include the same active preparation","两侧数值均包含当前相同的备战效果")
	var cost := card(row,"TrainingCostCard")
	var price := kit_flow(cost)
	price.add_child(ManagementKit.image("gold",40))
	kit_line(price,loc("금화 %d","Gold %d","金币 %d") % root.MONSTER_TRAINING_COST.gold,"TrainingPrice",GOLD)
	kit_line(cost,"EXP +%d" % root.MONSTER_TRAINING_EXP,"TrainingGain")
	kit_line(cost,loc("오늘 %d/2 · 하루 2회","Today %d/2 · Twice daily","今日 %d/2 · 每天2次") % count,"TrainingLimits",MUTED)
	chip(parent,loc("영구 성장 · EXP +%d","Permanent growth · EXP +%d","永久成长 · EXP +%d") % root.MONSTER_TRAINING_EXP,"FocusGrowthExplanation",PAPER,"experience")
	var growth_label: Label = parent.find_child("FocusGrowthExplanation",true,false)
	growth_label.mouse_filter = Control.MOUSE_FILTER_PASS
	growth_label.tooltip_text = loc("훈련: 유료 EXP +20. 집중성장: 승리 결과에서 1명, 무료 EXP +8. EXP는 날짜가 지나도 유지됩니다.","Training: paid EXP +20. Focus growth: one companion after victory, free EXP +8. EXP persists across days.","训练：付费 EXP +20。集中成长：胜利后选择1名伙伴，免费 EXP +8。经验跨日保留。")
	chip(parent,loc("다음 전투 준비 · 별도 효과","Next battle preparation · Separate effect","下次战斗准备 · 独立效果"),"FocusPreparation",MUTED,"tactics")
	var prep: Dictionary = root._result_growth_preparation_rule(id)
	var text: String = root._active_growth_preparation_line(id)
	var prep_label: Label = parent.find_child("FocusPreparation",true,false)
	prep_label.mouse_filter = Control.MOUSE_FILTER_PASS
	prep_label.tooltip_text = (LanguageSettings.ui_text(text) if text != "" else loc("집중성장의 준비 효과는 지정된 다음 방어 DAY에만 적용됩니다.","Focus preparation applies only on the designated next defense day.","集中成长的备战效果仅用于指定的下次防御日。"))+"\n"+LanguageSettings.ui_text(str(prep.get("preview","")))
	kit_line(parent,loc("훈련은 EXP를 키웁니다 · 집중성장 무료 +8","Training adds EXP · Focus growth gives free +8","训练提升EXP · 集中成长免费+8"),"",MUTED)
	if last_training.has(id) and int(last_training[id].day) == GameState.day:
		var result: Dictionary = last_training[id]
		kit_line(parent,loc("이번 훈련 완료 · EXP +%d · Lv.%d → %d","Last training · EXP +%d · Lv.%d → %d","本次训练完成 · EXP +%d · %d级 → %d级") % [result.gain,result.before.level,result.after.level],"TrainingReceipt",GOLD)
	kit_line(action_footer,loc("현재 장 훈련 상한 Lv.%d","Chapter training cap Lv.%d","当前章节训练上限 %d级") % root._training_level_cap(),"TrainingCap",MUTED)
	var b := kit_button(action_footer,"",Rect2(),_train.bind(id),"MonsterTrainingButton","primary")
	b.custom_minimum_size.y = 112
	b.tooltip_text = loc("훈련하기","Train","训练")+(" · "+LanguageSettings.ui_text(reason) if reason != "" else "")
	b.disabled = reason != ""
	var button_words := kit_content(b,10)
	var caption := kit_line(button_words,loc("훈련하기","Train","训练"),"TrainingButtonCaption",MUTED if b.disabled else PAPER)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",30)
	if reason != "":
		var blocked := kit_line(button_words,LanguageSettings.ui_text(reason),"TrainingBlockReason",MUTED)
		blocked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _train(id: String) -> void:
	if id != root.selected_monster_id or not root._monster_available_for_defense(id): return
	var before: Dictionary = root.monster_roster[id].duplicate(true)
	root._train_selected_monster()
	var after: Dictionary = root.monster_roster[id].duplicate(true)
	if int(after.get("training_count_today",0)) != int(before.get("training_count_today",0)) or int(after.get("training_day",0)) != int(before.get("training_day",0)):
		last_training[id] = {"day":GameState.day,"gain":root.MONSTER_TRAINING_EXP,"before":before,"after":after}
		root._set_screen(Constants.SCREEN_MONSTER,false)

func _skills(parent: Control, id: String) -> void:
	kit_line(parent,loc("전투 자동 사용 · 직접 사용 가능 여부는 전투 버튼에서 확인","Automatic use in combat · Manual availability on combat buttons","战斗中自动使用 · 手动操作见战斗按钮"),"",MUTED)
	kit_line(parent,loc("보유 기술 · 잠금 슬롯의 습득 레벨은 정해지지 않았습니다.","Owned skills · Locked slots have no defined unlock level.","已有技能 · 锁定槽位尚无指定解锁等级。"),"SkillAvailability",GOLD)
	for value in DataRegistry.monster(id).get("skill_slots",[]):
		if value == null:
			var crowns: Array = []
			for crown_id in DataRegistry.update4_crown_evolutions:
				var crown: Dictionary = DataRegistry.update4_crown_evolutions[crown_id]
				if str(crown.get("monster_id","")) == id: crowns.append(crown)
			if crowns.is_empty():
				kit_line(card(parent,"SkillLockedCard"),loc("잠금 슬롯 · 조건 미정","Locked slot · Condition unspecified","锁定槽位 · 条件未定"),"SkillUnspecified",MUTED)
			for crown in crowns:
				var royal_card := card(parent,"RoyalSkillCard")
				var royal: String = str(crown.get("royal_skill_id",""))
				var rule: Dictionary = DataRegistry.skill(royal)
				kit_line(royal_card,loc("왕관 기술 · 별도 왕관 이벤트","Royal skill · Separate crown event","王冠技能 · 独立王冠事件")+" · "+LanguageSettings.ui_text(str(rule.get("display_name",royal))),"CrownSkillPreview",GOLD)
				kit_line(royal_card,LanguageSettings.ui_text(str(rule.get("description",""))),"",MUTED)
				kit_line(royal_card,loc("Lv.%d · 유대 %d · 성장 단계 %d · 특화 · 1차 진화 · 의회 인장 또는 대체 자원","Lv.%d · Bond %d · Growth stage %d · Specialization · First evolution · Council seals or alternative resource","%d级 · 羁绊 %d · 成长阶段 %d · 专精 · 首次进化 · 议会印记或替代资源") % [int(crown.get("required_level",0)),int(crown.get("required_bond",0)),int(crown.get("required_growth_stage",0))],"CrownSkillCondition",MUTED)
			continue
		var skill := DataRegistry.skill(str(value))
		var row := kit_flow(card(parent,"SkillCard_"+str(value)))
		var icon := ManagementKit.image(ManagementKit.Icons.action_icon(str(value)),40)
		row.add_child(icon)
		var words := kit_flow(row,true)
		kit_line(words,LanguageSettings.ui_text(str(skill.get("display_name",value)))+" · "+loc("보유","Owned","已拥有"),"Skill_"+str(value),GOLD)
		kit_line(words,LanguageSettings.ui_text(str(skill.get("description",""))),"",MUTED)
		kit_line(words,loc("마력 %d · 재사용 %s초","Mana %d · Cooldown %ss","魔力 %d · 冷却 %s秒") % [int(skill.get("cost_mana",0)),str(skill.get("cooldown",0))],"",MUTED)

func _specialization(parent: Control, id: String) -> void:
	kit_line(parent,loc("전술 특화 · 팀 선택 %d/%d · 선택 후 변경 불가","Specialization · Team %d/%d · Permanent choice","战术专精 · 全队 %d/%d · 选择后不可更改") % [root._early_specialization_count(),root._early_specialization_limit()],"SpecializationCapacity",GOLD)
	if GameState.day < 4: kit_line(parent,loc("DAY2 해금 · 추가 선택 DAY4","Unlocks DAY2 · More choices DAY4","第2天解锁 · 第4天可追加选择"),"",MUTED)
	var active: Dictionary = root._monster_specialization(id)
	if not active.is_empty():
		parent.add_child(ManagementKit.image(str(active.get("badge","")),52))
		kit_line(parent,LanguageSettings.ui_text(str(active.get("display_name",""))),"",GOLD)
		var base: Dictionary = DataRegistry.monster(id).duplicate(true)
		kit_line(parent," · ".join(preload("res://scripts/systems/SpecializationEffects.gd").preview(active,base)),"SpecializationStatArrows",GOLD)
		kit_line(parent,LanguageSettings.ui_text(str(active.get("description",""))))
		return
	for option in root._specializations_for_monster(id):
		var content := card(parent,"SpecializationCard_"+str(option.id))
		kit_line(content,LanguageSettings.ui_text(str(option.get("display_name",""))),"",GOLD)
		kit_line(content,LanguageSettings.ui_text(str(option.get("description",""))),"",MUTED)
		var reason: String = root._specialization_block_reason(id,str(option.id))
		var b := kit_button(content,loc("특화 선택 · 변경 불가","Choose specialization · Permanent","选择专精 · 不可更改"),Rect2(),Callable(root,"_choose_early_specialization").bind(id,str(option.id)),"MonsterSpecialization_"+str(option.id))
		b.disabled = not root._can_choose_early_specialization(id,str(option.id))
		if reason != "": kit_line(content,LanguageSettings.ui_text(reason),"",MUTED)

func promotion_capacity() -> String:
	var done: int = root._promotion_count()
	var limit: int = root._promotion_limit_for_current_day()
	var text := loc("승급 완료 %d명 / 허용 총 %d명","Promoted %d / Total allowed %d","已晋升 %d名 / 允许总计 %d名") % [done,limit] if limit > 0 else loc("승급 완료 %d명 · 인원 제한 없음","Promoted %d · No roster limit","已晋升 %d名 · 人数不限") % done
	var ready := 0
	for id in root.monster_roster:
		for rule in root._evolution_rules_for_monster(id):
			if root._can_promote_monster(id,str(rule.id)): ready += 1; break
	text += loc(" · 현재 조건 충족 %d명"," · Eligible now %d"," · 当前符合条件 %d名") % ready
	if limit > 0:
		for day in range(GameState.day+1,31):
			var info: Dictionary = root._campaign_day_info(day)
			var future := int(info.get("promotion_limit",1 if bool(info.get("first_promotion_limit",false)) or day < root.SECOND_PROMOTION_UNLOCK_DAY else 0))
			if future == 0 or future > limit:
				text += loc(" · 다음 확대 DAY%d (%s)"," · Next expansion DAY%d (%s)"," · 下次扩充 第%d天 (%s)") % [day,str(future) if future > 0 else loc("제한 없음","Unlimited","无限制")]
				break
	return text

func condition(parent: Control, text: String, met: bool, name: String = "") -> void:
	chip(parent,("✓ " if met else "○ ")+text,name,ManagementKit.Tokens.HP if met else MUTED)

func _choose_promotion(index: int) -> void:
	promotion_choice = index
	root._set_screen(Constants.SCREEN_MONSTER,false)

func _promotion(parent: Control, id: String) -> void:
	var capacity := kit_line(parent,promotion_capacity(),"PromotionCapacity",GOLD)
	capacity.tooltip_text = capacity.text+"\n"+loc("전직 · 기존 진화/승급 · 선택 후 변경 불가","Promotion · Existing evolution · Permanent choice","转职 · 原有进化与晋升 · 选择后不可更改")
	var active: Dictionary = root._monster_promotion_rule(id)
	capacity.mouse_filter = Control.MOUSE_FILTER_PASS
	if not active.is_empty(): capacity.tooltip_text += "\n"+loc("진화 완료","Evolution complete","已进化")+" · "+LanguageSettings.ui_text(str(active.get("display_name","")))
	var options: Array = root._evolution_rules_for_monster(id)
	if options.is_empty():
		kit_line(parent,loc("승급 규칙이 없습니다.","No promotion rule available.","暂无晋升规则。"))
		return
	promotion_choice = clampi(promotion_choice,0,options.size()-1)
	var choices := kit_flow(parent)
	for index in range(options.size()):
		var choice: Button = kit_button(choices,LanguageSettings.ui_text(str(options[index].get("display_name",""))),Rect2(),_choose_promotion.bind(index),"PromotionChoice%d" % index,"primary" if index == promotion_choice else "utility")
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var option: Dictionary = options[promotion_choice]
	var preview := card(parent,"PromotionPreviewCard",14)
	var row := kit_flow(preview)
	_art(row,id,Vector2(220,220),false,str(option.get("portrait","")))
	var words := kit_flow(row,true)
	kit_line(words,LanguageSettings.ui_text(str(option.get("display_name",""))),"PromotionName",GOLD)
	var role := kit_line(words,LanguageSettings.ui_text(root._promotion_role_display_name(str(option.get("role_tag","")))))
	role.mouse_filter = Control.MOUSE_FILTER_PASS
	role.tooltip_text += "\n"+LanguageSettings.ui_text(str(option.get("role_summary","")))
	var changes: Array[String] = []
	for key in option.get("stat_multipliers",{}): changes.append("%s %+d%%" % [LanguageSettings.ui_text({"max_hp":"체력","atk":"공격","def":"방어","move_speed":"이동 속도"}.get(key,key)),roundi((float(option.stat_multipliers[key])-1)*100)])
	for key in option.get("stat_bonuses",{}): changes.append("%s %+d" % [LanguageSettings.ui_text({"max_hp":"체력","atk":"공격","def":"방어"}.get(key,key)),int(option.stat_bonuses[key])])
	chip(words," · ".join(changes),"PromotionStatChanges",GOLD,"shield")
	var upgrade: Dictionary = option.get("skill_upgrade",{})
	kit_line(words,LanguageSettings.ui_text(str(DataRegistry.skill(str(upgrade.get("skill_id",""))).get("display_name","")))+" · "+LanguageSettings.ui_text(str(upgrade.get("summary",""))),"PromotionSkill",MUTED)
	var conditions := GridContainer.new()
	conditions.name = "PromotionConditions"
	conditions.columns = 2
	conditions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conditions.add_theme_constant_override("h_separation",12)
	conditions.add_theme_constant_override("v_separation",8)
	parent.add_child(conditions)
	var roster: Dictionary = root.monster_roster[id]
	condition(conditions,"Lv.%d / %d" % [roster.get("level",1),option.get("required_level",1)],int(roster.get("level",1)) >= int(option.get("required_level",1)),"PromotionLevelCondition")
	condition(conditions,"DAY %d / %d" % [GameState.day,option.get("unlock_day",1)],root._promotion_unlocked() and GameState.day >= int(option.get("unlock_day",1)),"PromotionDayCondition")
	if int(option.get("required_bond",0)) > 0:
		condition(conditions,loc("유대 %d / %d","Bond %d / %d","羁绊 %d / %d") % [roster.get("bond",0),option.get("required_bond",0)],int(roster.get("bond",0)) >= int(option.get("required_bond",0)),"PromotionBondCondition")
	for flag in option.get("required_flags",[]):
		var names := {"campaign_chapter_two_started":loc("2장 시작","Chapter 2 started","第二章开始"),"campaign_chapter_one_clear":loc("1장 완료","Chapter 1 cleared","第一章完成"),"campaign_stage_two_prepared":loc("2장 준비 완료","Chapter 2 prepared","第二章准备完成"),"campaign_stage_two_unlock_ready":loc("2장 해금 준비","Chapter 2 unlock ready","第二章解锁准备")}
		condition(conditions,str(names.get(str(flag),flag)),root._promotion_flags_met({"required_flags":[flag]}))
	for resource in option.get("cost",{}):
		if int(option.cost[resource]) > 0: condition(conditions,"%s %d / %d" % [LanguageSettings.ui_text({"gold":"금화","mana":"마력","infamy":"악명","food":"식량"}.get(resource,resource)),GameState.get(resource),int(option.cost[resource])],int(GameState.get(resource)) >= int(option.cost[resource]))
	var reason: String = root._promotion_block_reason(id,str(option.id))
	if reason.begins_with("오늘은"): reason = promotion_capacity()
	if reason != "": kit_line(action_footer,LanguageSettings.ui_text(reason),"PromotionReason%d" % promotion_choice,MUTED)
	var b := kit_button(action_footer,loc("이 모습으로 전직","Promote to this form","转职为此形态"),Rect2(),Callable(root,"_promote_monster").bind(id,str(option.id)),"PromotionOption%d" % promotion_choice,"primary")
	b.disabled = not root._can_promote_monster(id,str(option.id))
	b.custom_minimum_size.y = 96
	var duo_button := kit_button(action_footer,loc("합동기 조건 보기","Duo link requirements","查看合击条件"),Rect2(),_tab.bind("duo"),"PromotionDuoPreview")
	duo_button.custom_minimum_size.y = 60

func _duo(parent: Control, id: String) -> void:
	var b := kit_button(parent,loc("팀 합동기 편성","Edit team duo links","编组合击"),Rect2(),Callable(root,"_open_update3_duo_link_loadout"),"MonsterDuoEditButton")
	b.disabled = not root._update3_duo_loadout_edit_available()
	if b.disabled: kit_line(parent,loc("편성: 2회차 이후 · 기존 편성 확정 뒤 · 포스트게임 제외","Editing: cycle 2+ · After loadout confirmation · Outside postgame","编组：第二周目起 · 已确认编组 · 非通关后模式"),"DuoEditLock",MUTED)

	var screen: Control = load("res://scenes/ui/screens/DuoLinkLoadoutScreen.gd").new()
	screen.profile = root.update3_profile.duplicate(true)
	screen.active_run = root.update3_active_run.duplicate(true)
	screen.catalog = DataRegistry.update3_duo_links
	screen.deployed_instance_ids = root.deployed_instance_ids
	screen.member_progress = root._update3_duo_member_progress()
	for member in screen.member_progress:
		screen.member_progress[member]["owned"] = root.monster_roster.has(str(DataRegistry.monster_instance(member).get("species_id","")))
	screen.selected_member_id = Contracts.instance_id_for_species(id,DataRegistry.monster_instances)
	screen.editable = false
	# A read-only tab shares the exact card builder with the signal-based team editor.
	screen.build_embedded(parent)
	screen.free()

func _codex() -> void:
	var pane := kit_panel(Rect2(448,100,1448,956),"MonsterCodex")
	_glass(pane,0.55)
	var column := kit_content(pane,32)
	var id: String = codex_id if codex_id != "" else root.selected_monster_id
	var owned: bool = root.monster_roster.has(id)
	var contract := DataRegistry.update2_contract(id)
	kit_line(column,loc("동료 도감","Companion codex","伙伴图鉴"),"",GOLD)
	var row := kit_flow(column)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_art(row,id,Vector2(560,560),not owned)
	var details := card(row,"CodexIdentityCard",28)
	kit_line(details,root._monster_companion_name(id) if owned else "???","CodexIdentity",GOLD).add_theme_font_size_override("font_size",42)
	chip(details,LanguageSettings.ui_text(str(contract.get("role",DataRegistry.monster(id).get("role","")))),"CodexRole",PAPER,"monster")
	chip(details,loc("이미 만난 동료","Companion met","已结识的伙伴") if owned else loc("만나는 조건 · 다음 회차 계약 후보에서 선택","Encounter condition · Select from next cycle contracts","相遇条件 · 在下周目契约候选中选择"),"CodexCondition",MUTED,"lock" if not owned else "check")
	kit_line(details,loc("다음 회차에서도 새 동료를 만나 보세요.","Meet new companions in future cycles.","在下周目结识新伙伴。"),"",MUTED)
	_preserve_layout(pane)

func portrait(parent: Control, id: String, rect: Rect2) -> void:
	# Large art has its own resolution and follows the currently active form.
	var path: String = root.management_scene.monster_portrait_path(id)
	var art: TextureRect
	if path != "" and ResourceLoader.exists(path):
		art = hud.texture(parent, path, rect)
	else:
		var actual: Texture2D = root.management_scene.monster_identity_texture(id)
		if actual == null: return
		art = TextureRect.new()
		art.texture = actual
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.position = rect.position
		art.size = rect.size
		parent.add_child(art)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.name = "MonsterPortrait_" + id
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func room_name(room_id: String) -> String:
	return str(root.rooms.get(room_id, {}).get("display_name", "미배치"))
