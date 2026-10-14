extends "res://scripts/ui/ManagementWorkspaceUI.gd"
const Tabs = preload("res://scripts/ui/kit/KitTabs.gd")
const StatBar = preload("res://scripts/ui/kit/KitStatBar.gd")
const Contracts = preload("res://scripts/systems/contracts/ContractRosterService.gd")
var active_tab := "training"
var list_mode := "owned"
var inspected_id := ""
var codex_id := ""
var last_training: Dictionary = {}

func loc(ko: String, en: String, zh: String) -> String:
	return root.continuity.localized(ko,en,zh)

func build_monster() -> void:
	shared_theme = null
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
	kit_button(column,loc("관리로","Back","返回管理"),Rect2(),Callable(root,"_set_screen").bind(Constants.SCREEN_MANAGEMENT),"MonsterBackButton","utility","close")
	_preserve_layout(left)
	if list_mode == "codex":
		_codex()
		return
	var id: String = inspected_id
	var pane := kit_panel(Rect2(448,100,1448,956),"MonsterGrowthTools")
	if id == "" or not root.monster_roster.has(id): return
	var roster: Dictionary = root.monster_roster[id]
	var data := DataRegistry.monster(id)
	# Keep the existing named detail/first-label contract for S1 and tutorial callers.
	var header := Control.new()
	header.name = "MonsterSelectedDetail"
	header.custom_minimum_size.y = 144 if UISettings.is_touch_ui() else 120
	var main := kit_content(pane,24)
	main.add_child(header)
	kit_copy(header,root._monster_companion_name(id),Rect2(0,0,370,48),36,GOLD,"MonsterName")
	var status: Dictionary = root._monster_roster_status(id)
	kit_copy(header,"Lv.%d · %s · %s" % [int(roster.get("level",1)),hud.role_display_name(str(root._monster_promotion_rule(id).get("role_tag",roster.get("role_tag",data.get("role",""))))),LanguageSettings.ui_text(str(status.label))],Rect2(380,0,990,60),26,PAPER,"MonsterRole")
	kit_copy(header,loc("유대 %d/100 · %s","Bond %d/100 · %s","羁绊 %d/100 · %s") % [int(roster.get("bond",0)),LanguageSettings.ui_text(root._monster_bond_rank_name(int(roster.get("bond",0))))],Rect2(0,64,1376,48),24,MUTED,"MonsterBond")
	var tabs := Tabs.new()
	tabs.name = "MonsterTabs"
	main.add_child(tabs)
	var entries: Array = []
	for item in [["training",loc("훈련","Training","训练"),"experience"],["skills",loc("스킬","Skills","技能"),"tactics"],["promotion",loc("전직","Promotion","转职"),"tactics"],["duo",loc("합동기","Duo links","合击"),"monster"],["memory",loc("기억","Memories","记忆"),"log"]]:
		entries.append({"id":item[0],"label":item[1],"icon":item[2]})
	tabs.set_tabs(entries,active_tab)
	for key in tabs._buttons: tabs._buttons[key].name = "MonsterTab_"+key
	tabs.tab_selected.connect(_tab)
	ManagementKit.inherit_theme(tabs,kit_theme())
	var body_scroll := ScrollContainer.new()
	body_scroll.name = "MonsterGrowthScroll"
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.follow_focus = true
	main.add_child(body_scroll)
	var body := kit_flow(body_scroll,true)
	match active_tab:
		"training": _training(body,id,roster,root._scaled_monster_stats(id))
		"skills": _skills(body,id); _specialization(body,id)
		"promotion": _promotion(body,id)
		"duo": _duo(body,id)
		"memory": root.management_scene.memory_archive_ui.build_tab(body,id)
	_preserve_layout(pane)

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
	kit_line(parent,loc("유료 훈련 · 금화 %d · EXP +%d · 오늘 %d/2 · 상한 Lv.%d","Paid training · Gold %d · EXP +%d · Today %d/2 · Cap Lv.%d","付费训练 · 金币 %d · EXP +%d · 今日 %d/2 · 上限 Lv.%d") % [root.MONSTER_TRAINING_COST.gold,root.MONSTER_TRAINING_EXP,count,root._training_level_cap()],"TrainingLimits",GOLD)
	var row := kit_flow(parent)
	_art(row,id,Vector2(250,280))
	var comparison := kit_flow(row,true)
	kit_line(comparison,"Lv.%d → Lv.%d" % [int(roster.level),int(after.level)],"TrainingExpPreview",GOLD)
	_bar(comparison,loc("현재","Current","当前"),int(roster.exp),int(roster.level),"TrainingBeforeBar")
	_bar(comparison,loc("훈련 후","After","训练后"),int(after.exp),int(after.level),"TrainingAfterBar")
	for key in [["max_hp",loc("체력","HP","生命")],["atk",loc("공격","Attack","攻击")],["def",loc("방어","Defense","防御")]]:
		kit_line(comparison,"%s  %d → %d  (+%d)" % [key[1],current[key[0]],after.stats[key[0]],int(after.stats[key[0]])-int(current[key[0]])],"TrainingStats_"+key[0])
	kit_line(comparison,loc("같은 현재 준비 효과를 포함한 수치 비교","Both values include the same active preparation","两侧数值均包含当前相同的备战效果"),"",MUTED)
	var b := kit_button(parent,loc("훈련하기","Train","训练"),Rect2(),_train.bind(id),"MonsterTrainingButton","primary","experience")
	b.disabled = reason != ""
	if reason != "": kit_line(parent,LanguageSettings.ui_text(reason),"TrainingBlockReason",MUTED)
	if last_training.has(id) and int(last_training[id].day) == GameState.day:
		var result: Dictionary = last_training[id]
		kit_line(parent,loc("이번 훈련 완료 · EXP +%d · Lv.%d → %d · EXP %d → %d","Last training · EXP +%d · Lv.%d → %d · EXP %d → %d","本次训练完成 · EXP +%d · Lv.%d → %d · EXP %d → %d") % [result.gain,result.before.level,result.after.level,result.before.exp,result.after.exp],"TrainingReceipt",GOLD)
	kit_line(parent,loc("훈련: 유료 EXP +20. 집중성장: 승리 결과에서 1명, 무료 EXP +8. EXP는 날짜가 지나도 유지됩니다.","Training: paid EXP +20. Focus growth: one companion after victory, free EXP +8. EXP persists across days.","训练：付费 EXP +20。集中成长：胜利后选择1名伙伴，免费 EXP +8。经验跨日保留。"),"FocusGrowthExplanation",MUTED)
	var prep: Dictionary = root._result_growth_preparation_rule(id)
	var text: String = root._active_growth_preparation_line(id)
	kit_line(parent,LanguageSettings.ui_text(text) if text != "" else loc("집중성장의 준비 효과는 지정된 다음 방어 DAY에만 적용됩니다.","Focus preparation applies only on the designated next defense day.","集中成长的备战效果仅用于指定的下次防御日。"),"FocusPreparation",MUTED)
	if not prep.is_empty(): kit_line(parent,LanguageSettings.ui_text(str(prep.get("preview",""))),"",MUTED)

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
				kit_line(parent,loc("잠금 슬롯 · 조건 미정","Locked slot · Condition unspecified","锁定槽位 · 条件未定"),"SkillUnspecified",MUTED)
			for crown in crowns:
				var royal: String = str(crown.get("royal_skill_id",""))
				var rule: Dictionary = DataRegistry.skill(royal)
				kit_line(parent,loc("왕관 기술 · 별도 왕관 이벤트","Royal skill · Separate crown event","王冠技能 · 独立王冠事件")+" · "+LanguageSettings.ui_text(str(rule.get("display_name",royal))),"CrownSkillPreview",GOLD)
				kit_line(parent,LanguageSettings.ui_text(str(rule.get("description",""))),"",MUTED)
				kit_line(parent,loc("Lv.%d · 유대 %d · 성장 단계 %d · 특화 · 1차 진화 · 의회 인장 또는 대체 자원","Lv.%d · Bond %d · Growth stage %d · Specialization · First evolution · Council seals or alternative resource","Lv.%d · 羁绊 %d · 成长阶段 %d · 专精 · 首次进化 · 议会印记或替代资源") % [int(crown.get("required_level",0)),int(crown.get("required_bond",0)),int(crown.get("required_growth_stage",0))],"CrownSkillCondition",MUTED)
			continue
		var skill := DataRegistry.skill(str(value))
		var row := kit_flow(parent)
		var icon := ManagementKit.image("tactics",40)
		row.add_child(icon)
		var words := kit_flow(row,true)
		kit_line(words,LanguageSettings.ui_text(str(skill.get("display_name",value)))+" · "+loc("보유","Owned","已拥有"),"Skill_"+str(value),GOLD)
		kit_line(words,LanguageSettings.ui_text(str(skill.get("description",""))),"",MUTED)
		kit_line(words,loc("마력 %d · 재사용 %s초","Mana %d · Cooldown %ss","魔力 %d · 冷却 %s秒") % [int(skill.get("cost_mana",0)),str(skill.get("cooldown",0))],"",MUTED)

func _specialization(parent: Control, id: String) -> void:
	kit_line(parent,loc("전술 특화 · 팀 선택 %d/%d · 선택 후 변경 불가","Specialization · Team %d/%d · Permanent choice","战术专精 · 全队 %d/%d · 选择后不可更改") % [root._early_specialization_count(),root._early_specialization_limit()],"SpecializationCapacity",GOLD)
	if GameState.day < 4: kit_line(parent,loc("DAY2 해금 · 추가 선택 DAY4","Unlocks DAY2 · More choices DAY4","DAY2解锁 · DAY4可追加选择"),"",MUTED)
	var active: Dictionary = root._monster_specialization(id)
	if not active.is_empty():
		kit_line(parent,LanguageSettings.ui_text(str(active.get("display_name",""))),"",GOLD)
		kit_line(parent,LanguageSettings.ui_text(str(active.get("description",""))))
		return
	for option in root._specializations_for_monster(id):
		kit_line(parent,LanguageSettings.ui_text(str(option.get("display_name",""))),"",GOLD)
		kit_line(parent,LanguageSettings.ui_text(str(option.get("description",""))),"",MUTED)
		var reason: String = root._specialization_block_reason(id,str(option.id))
		var b := kit_button(parent,loc("특화 선택 · 변경 불가","Choose specialization · Permanent","选择专精 · 不可更改"),Rect2(),Callable(root,"_choose_early_specialization").bind(id,str(option.id)),"MonsterSpecialization_"+str(option.id))
		b.disabled = not root._can_choose_early_specialization(id,str(option.id))
		if reason != "": kit_line(parent,LanguageSettings.ui_text(reason),"",MUTED)

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
				text += loc(" · 다음 확대 DAY%d (%s)"," · Next expansion DAY%d (%s)"," · 下次扩充 DAY%d (%s)") % [day,str(future) if future > 0 else loc("제한 없음","Unlimited","无限制")]
				break
	return text

func condition(parent: Control, text: String, met: bool, name: String = "") -> void:
	kit_line(parent,("✓ " if met else "○ ")+text,name,ManagementKit.Tokens.HP if met else MUTED)

func _promotion(parent: Control, id: String) -> void:
	kit_line(parent,loc("전직 · 기존 진화/승급 · 선택 후 변경 불가","Promotion · Existing evolution · Permanent choice","转职 · 原有进化与晋升 · 选择后不可更改"),"",GOLD)
	kit_line(parent,promotion_capacity(),"PromotionCapacity",GOLD)
	var active: Dictionary = root._monster_promotion_rule(id)
	if not active.is_empty(): kit_line(parent,loc("진화 완료","Evolution complete","已进化")+" · "+LanguageSettings.ui_text(str(active.get("display_name",""))),"",GOLD)
	var index := 0
	for option in root._evolution_rules_for_monster(id):
		var row := kit_flow(parent)
		_art(row,id,Vector2(220,230),false,str(option.get("portrait","")))
		var words := kit_flow(row,true)
		kit_line(words,LanguageSettings.ui_text(str(option.get("display_name",""))),"",GOLD)
		kit_line(words,LanguageSettings.ui_text(root._promotion_role_display_name(str(option.get("role_tag","")))))
		kit_line(words,LanguageSettings.ui_text(str(option.get("role_summary",""))),"",MUTED)
		var changes: Array[String] = []
		for key in option.get("stat_multipliers",{}): changes.append("%s %+d%%" % [LanguageSettings.ui_text({"max_hp":"체력","atk":"공격","def":"방어","move_speed":"이동 속도"}.get(key,key)),roundi((float(option.stat_multipliers[key])-1)*100)])
		for key in option.get("stat_bonuses",{}): changes.append("%s %+d" % [LanguageSettings.ui_text({"max_hp":"체력","atk":"공격","def":"방어"}.get(key,key)),int(option.stat_bonuses[key])])
		kit_line(words," · ".join(changes))
		var upgrade: Dictionary = option.get("skill_upgrade",{})
		kit_line(words,LanguageSettings.ui_text(str(DataRegistry.skill(str(upgrade.get("skill_id",""))).get("display_name","")))+" · "+LanguageSettings.ui_text(str(upgrade.get("summary",""))),"",MUTED)
		var roster: Dictionary = root.monster_roster[id]
		condition(words,"Lv.%d / %d" % [roster.get("level",1),option.get("required_level",1)],int(roster.get("level",1)) >= int(option.get("required_level",1)))
		condition(words,"DAY %d / %d" % [GameState.day,option.get("unlock_day",1)],root._promotion_unlocked() and GameState.day >= int(option.get("unlock_day",1)))
		condition(words,loc("유대 %d / %d","Bond %d / %d","羁绊 %d / %d") % [roster.get("bond",0),option.get("required_bond",0)],int(roster.get("bond",0)) >= int(option.get("required_bond",0)))
		for flag in option.get("required_flags",[]):
			var names := {"campaign_chapter_two_started":loc("2장 시작","Chapter 2 started","第二章开始"),"campaign_chapter_one_clear":loc("1장 완료","Chapter 1 cleared","第一章完成"),"campaign_stage_two_prepared":loc("2장 준비 완료","Chapter 2 prepared","第二章准备完成"),"campaign_stage_two_unlock_ready":loc("2장 해금 준비","Chapter 2 unlock ready","第二章解锁准备")}
			condition(words,str(names.get(str(flag),flag)),root._promotion_flags_met({"required_flags":[flag]}))
		for resource in option.get("cost",{}): condition(words,"%s %d / %d" % [LanguageSettings.ui_text({"gold":"금화","mana":"마력","infamy":"악명","food":"식량"}.get(resource,resource)),GameState.get(resource),int(option.cost[resource])],int(GameState.get(resource)) >= int(option.cost[resource]))
		var reason: String = root._promotion_block_reason(id,str(option.id))
		if reason.begins_with("오늘은"): reason = promotion_capacity()
		if reason != "": kit_line(parent,LanguageSettings.ui_text(reason),"PromotionReason%d" % index,MUTED)
		var b := kit_button(parent,loc("이 모습으로 진화","Evolve into this form","进化为此形态"),Rect2(),Callable(root,"_promote_monster").bind(id,str(option.id)),"PromotionOption%d" % index)
		b.disabled = not root._can_promote_monster(id,str(option.id))
		index += 1
	if index == 0: kit_line(parent,loc("승급 규칙이 없습니다.","No promotion rule available.","暂无晋升规则。"))
	kit_button(parent,loc("합동기 · 별도 해금 조건 보기","Duo links · Separate unlock requirements","合击 · 查看独立解锁条件"),Rect2(),_tab.bind("duo"),"PromotionDuoPreview")

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
	var column := kit_content(pane,32)
	var id: String = codex_id if codex_id != "" else root.selected_monster_id
	var owned: bool = root.monster_roster.has(id)
	var contract := DataRegistry.update2_contract(id)
	kit_line(column,loc("동료 도감","Companion codex","伙伴图鉴"),"",GOLD)
	_art(column,id,Vector2(360,360),not owned)
	kit_line(column,root._monster_companion_name(id) if owned else "???","CodexIdentity",GOLD)
	kit_line(column,LanguageSettings.ui_text(str(contract.get("role",DataRegistry.monster(id).get("role","")))),"CodexRole")
	kit_line(column,loc("이미 만난 동료","Companion met","已结识的伙伴") if owned else loc("만나는 조건 · 다음 회차 계약 후보에서 선택","Encounter condition · Select from next cycle contracts","相遇条件 · 在下周目契约候选中选择"),"CodexCondition",MUTED)
	kit_line(column,loc("다음 회차에서도 새 동료를 만나 보세요.","Meet new companions in future cycles.","在下周目结识新伙伴。"),"",MUTED)

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
