extends "res://scripts/ui/ManagementWorkspaceUI.gd"
const Layout = preload("res://scripts/v122/ui/V122CombatResultViewModel.gd")
var details: Panel

func loc(ko: String, en: String, zh: String) -> String:
	return root.continuity.localized(ko,en,zh)

func _preserve(node: Node) -> void:
	if node is Label: node.set_meta("hud_text_fit",true)
	for child in node.get_children(): _preserve(child)

func _child(parent: Control, rect: Rect2, id: String) -> Panel:
	var pane := kit_panel(rect,id)
	pane.reparent(parent,false)
	pane.position = rect.position
	return pane

func _portrait(parent: Control, id: String, rect: Rect2, victory: bool = false) -> void:
	var emotion: String = "victory" if victory else root.management_scene.result_portrait_emotion(id)
	var path: String = root.management_scene.monster_portrait_path(id,emotion)
	if path == "" or not ResourceLoader.exists(path):
		kit_copy(parent,loc("초상 없음","No portrait","无立绘"),rect,24,MUTED,"ResultMissingPortrait_"+id)
		return
	var art: TextureRect = hud.texture(parent,path,rect)
	art.name = ("ResultVictory_" if victory else "ResultPortrait_")+id
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_meta("portrait_emotion",emotion)
	art.set_meta("source_path",path)

func build_result(model: Dictionary, title: String, final_battle: bool) -> void:
	shared_theme = null
	var layout := Layout.design_layout_contract(false,false,true)
	var screen := kit_panel(Rect2(0,0,1920,1080),"V122ResultScreen")
	var hero := _child(screen,layout.hero,"ResultHero")
	var win: bool = model.get("win",false)
	var ids: Array = []
	for row in root.last_growth_summary: ids.append(str(row.get("monster_id","")))
	if ids.is_empty(): ids = root.monster_roster.keys()
	if win and not bool(root.result_summary.get("management_only",false)):
		for i in range(mini(3,ids.size())):
			_portrait(hero,str(ids[i]),[Rect2(12,10,250,278),Rect2(266,80,220,204),Rect2(1620,10,240,278)][i],true)
	kit_copy(hero,"DAY %02d" % GameState.day,Rect2(510,12,1080,38),28,GOLD,"ResultDay")
	kit_copy(hero,LanguageSettings.ui_text(title),Rect2(510,54,1080,66),40,PAPER,"ResultTitle")
	var core: Array[String] = []
	for row in model.get("core_metrics",[]): core.append(LanguageSettings.ui_text(str(row.label))+" "+LanguageSettings.ui_text(str(row.value)))
	kit_copy(hero," · ".join(core),Rect2(510,130,1080,74),24,MUTED,"ResultCoreMetrics")
	var paid: Array[String] = []
	for item in [["gold","금화"],["mana","마력"],["food","식량"],["infamy","악명"]]:
		if int(model.get("rewards",{}).get(item[0],0)) > 0: paid.append("%s +%d" % [LanguageSettings.ui_text(item[1]),int(model.rewards[item[0]])])
	kit_copy(hero,loc("획득 보상","Rewards","获得奖励")+" · "+(" / ".join(paid) if not paid.is_empty() else loc("없음","None","无")),Rect2(510,214,790,70),24,GOLD,"ResultRewards")
	var toggle := kit_button(hero,loc("상세 기록","Details","详细记录"),Rect2(1330,212,270,72),Callable(),"ResultDetailsButton")
	toggle.tooltip_text = loc("배치·시설·자원 순변동 기록","Placement, facilities and net resource changes","部署、设施与资源净变化记录")
	_growth(screen)
	var preview_rect: Rect2 = layout.training_preview
	if model.get("actions",[]).size() > 1: preview_rect.size.x = 940
	_training_preview(screen,preview_rect,final_battle)
	if win and not root.last_growth_summary.is_empty():
		var review := kit_button(screen,loc("확인 완료","Reviewed","已确认") if root.result_growth_reviewed else loc("성장 확인","Review growth","确认成长"),layout.growth_review,Callable(root,"_review_growth_from_result"),"GrowthReviewButton")
		review.disabled = root.result_growth_reviewed or (root._result_growth_choice_required() and not root.result_growth_choice_applied)
	var actions: Array = model.get("actions",[])
	for i in range(actions.size()):
		var action: Dictionary = actions[i]
		var id := str(action.id)
		var target := str({"continue":"NextDayButton","edit_placement":"ResultEditPlacement","retry_same_placement":"ResultRetrySamePlacement"}.get(id,id))
		var text := LanguageSettings.ui_text(str(action.label))
		if id == "continue" and win: text = loc("엔딩 보기","View ending","查看结局") if final_battle else loc("다음 DAY","Next DAY","下一天")
		var rect: Rect2 = layout.actions
		if actions.size() > 1: rect = Rect2(988+i*466,960,442,88)
		var b := kit_button(screen,text,rect,Callable(root,str(action.callback)),target,"primary" if i == 0 else "utility")
		if id == "continue":
			b.disabled = (root._result_growth_choice_required() and (not root.result_growth_choice_applied or not root.result_growth_reviewed)) or (root.onboarding_enabled and root.tutorial_gate_enabled and root.tutorial_manager.is_active_for_stage(root.onboarding_stage_id) and root.tutorial_manager.expected_action() == "growth_reviewed")
		if i == 0 and not b.disabled: call_deferred("focus_if_visible",b)
	_details(screen,model)
	toggle.pressed.connect(Callable(details,"show"))
	_preserve(screen)

func _growth(screen: Control) -> void:
	var pane := _child(screen,Layout.design_layout_contract(false,false,true).performance,"ResultGrowthPanel")
	kit_copy(pane,loc("동료 성과 → 집중성장","Companion performance → Focus growth","伙伴战绩 → 集中成长"),Rect2(24,12,1220,44),28,GOLD,"ResultPerformanceHeading")
	kit_copy(pane,loc("공격 · 지원","Attack · Support","攻击 · 支援"),Rect2(284,68,660,36),24,MUTED)
	kit_copy(pane,loc("지속 성장 · EXP","Lasting growth · EXP","持续成长 · EXP"),Rect2(982,68,434,36),24,MUTED)
	kit_copy(pane,loc("승리 후 1명 · 무료 +8","One after victory · Free +8","胜利后1名 · 免费+8" ) if root._result_growth_choice_required() else loc("이번 전투 기록","Battle records","本场记录"),Rect2(1440,12,408,88),24,MUTED,"ResultFocusRule")
	var scroll := ScrollContainer.new()
	scroll.name = "ResultGrowthScroll"; scroll.position = Vector2(24,112); scroll.size = Vector2(1824,372)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.follow_focus = true
	pane.add_child(scroll)
	var list := kit_flow(scroll,true)
	if root.last_growth_summary.is_empty(): kit_line(list,loc("이번 전투 성장 기록이 없습니다.","No growth records for this battle.","本场无成长记录。"),"ResultEmptyGrowth",MUTED)
	for row in root.last_growth_summary:
		var id := str(row.get("monster_id",""))
		var card := _child(list,Rect2(0,0,1800,190),"ResultCompanion_"+id)
		card.custom_minimum_size = Vector2(1800,190)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_portrait(card,id,Rect2(12,12,100,144))
		kit_copy(card,root._monster_companion_name(id),Rect2(124,14,146,50),26,PAPER,"ResultName_"+id)
		kit_copy(card,"Lv.%d → %d" % [int(row.get("level_before",1)),int(row.get("level_after",1))],Rect2(124,72,146,80),24,GOLD)
		kit_copy(card,loc("피해 %d\n흡수 %d","Damage %d\nTaken %d","伤害 %d\n承受 %d") % [int(row.get("damage_dealt",0)),int(row.get("damage_absorbed",0))],Rect2(284,12,190,90),24,PAPER,"ResultAttack_"+id)
		kit_copy(card,loc("공유 +%d · 활약 +%d","Shared +%d · Activity +%d","共享 +%d · 表现 +%d") % [int(row.get("shared_exp",0)),int(row.get("activity_exp",0))],Rect2(284,138,660,44),24,MUTED,"ResultSharedExp_"+id)
		var support: Dictionary = root.growth_feedback.normalize(row.get("support_contribution",{}))
		var measured: Array[String] = []
		for pair in [["effective_healing",loc("회복 HP %d","Healed HP %d","治疗HP %d")],["support_protection_applications",loc("보호 %d회","Protection %d","保护%d次")],["shield_absorbed",loc("방어막 흡수 %d","Barrier %d","护盾吸收%d")],["redirect_actual_hp_taken",loc("대신 받은 피해 %d","Redirected HP %d","代受伤害%d")],["duo_shared_commits",loc("합동기 %d회","Duo uses %d","合技%d次")]]:
			if int(support.get(pair[0],0)) > 0: measured.append(pair[1] % int(support[pair[0]]))
		if int(row.get("facility_value",0)) > 0: measured.append(loc("시설 지원 %d","Facility support %d","设施支援%d") % int(row.facility_value))
		var support_text := " · ".join(measured) if not measured.is_empty() else (loc("이번 전투 지원 성과 없음","No support effect this battle","本场无支援成果") if not row.get("support_contribution",{}).is_empty() else loc("지원 기록 없음","No support records","无支援记录"))
		var support_label := kit_copy(card,support_text,Rect2(492,12,452,120),24,PAPER,"ResultMeasuredSupport_"+id)
		support_label.tooltip_text = support_text+"\n"+root.support_mastery.summary(id)
		var exp := kit_flow(card,true)
		exp.position = Vector2(982,12); exp.size = Vector2(434,150)
		root.management_scene.monster_ui._bar(exp,loc("전투 전","Before","战斗前"),int(row.get("exp_before",0)),int(row.get("level_before",1)),"ResultExpBefore_"+id)
		root.management_scene.monster_ui._bar(exp,loc("현재","Current","当前"),int(row.get("exp_after",0)),int(row.get("level_after",1)),"ResultExpAfter_"+id)
		kit_line(exp,"EXP +%d" % int(row.get("exp_gain",0)),"ResultExpGain_"+id,GOLD)
		if root._result_growth_choice_required():
			var selected: bool = root.result_growth_choice_applied and root.result_growth_choice_monster_id == id
			var b := kit_button(card,loc("선택됨 · EXP +8","Selected · EXP +8","已选择 · EXP +8") if selected else loc("집중성장 +8","Focus growth +8","集中成长+8"),Rect2(1440,12,336,74),Callable(root,"_choose_result_growth").bind(id),"GrowthChoice_"+id,"primary" if selected else "tactical")
			b.disabled = root.result_growth_choice_applied
			var preview: String = root.management_scene._growth_choice_preview_text(row,root._result_growth_choice_bonus()) if not root.result_growth_choice_applied else "%d/%d EXP" % [int(row.get("exp_after",0)),int(row.get("next_exp",1))]
			kit_copy(card,LanguageSettings.ui_text(preview),Rect2(1440,98,336,62),24,GOLD,"GrowthChoicePreview_"+id)

func _training_preview(screen: Control, rect: Rect2, final_battle: bool) -> void:
	var pane := _child(screen,rect,"ResultTrainingPreview")
	var id: String = root.result_growth_choice_monster_id
	if final_battle or not bool(root.result_summary.get("win",false)) or not root.result_growth_choice_applied or not root.monster_roster.has(id):
		kit_copy(pane,loc("결산을 확인하고 다음 일정으로 진행하세요.","Review the result and continue.","确认结算后继续下一安排。") if bool(root.result_summary.get("win",false)) else loc("배치를 수정하거나 같은 배치로 재도전하세요.","Edit placement or retry with the same placement.","修改部署或以相同部署重试。"),Rect2(24,24,rect.size.x-48,152),26,MUTED,"ResultPreviewUnavailable")
		return
	_portrait(pane,id,Rect2(12,12,112,176))
	var next: Dictionary = root.management_scene.monster_ui.training_preview(id)
	var roster: Dictionary = root.monster_roster[id]
	kit_copy(pane,root._monster_companion_name(id)+" · "+loc("훈련 미리보기","Training preview","训练预览"),Rect2(144,10,972,40),26,GOLD,"ResultTrainingCompanion")
	kit_copy(pane,loc("금화 %d · EXP +%d · Lv.%d → %d · EXP %d → %d","Gold %d · EXP +%d · Lv.%d → %d · EXP %d → %d","金币%d · EXP +%d · Lv.%d → %d · EXP %d → %d") % [root.MONSTER_TRAINING_COST.gold,root.MONSTER_TRAINING_EXP,int(roster.level),int(next.level),int(roster.exp),int(next.exp)],Rect2(144,56,972,46),24,PAPER,"ResultTrainingCost")
	var preparation: String = root._result_growth_preparation_summary(id)
	var preparation_text := "DAY %d · " % int(roster.get("growth_preparation_day",GameState.day+1)) + (LanguageSettings.ui_text(preparation) if preparation != "" else loc("준비 효과 없음","No preparation effect","无备战效果"))
	kit_copy(pane,preparation_text,Rect2(144,106,972,44),24,GOLD,"GrowthChoicePreparation_"+id)
	kit_copy(pane,loc("다음 DAY 대화·필수 준비 후 몬스터 → 같은 동료 훈련. 여기서는 구매하지 않습니다.","Next DAY: dialogue / required prep → Monsters → Training. Preview only.","下一天对话与必需准备后：怪物 → 此伙伴训练。此处仅预览。"),Rect2(144,154,972,44),24,MUTED,"ResultTrainingTiming")

func _details(screen: Control, model: Dictionary) -> void:
	details = _child(screen,Rect2(420,332,1080,500),"ResultDetailsPanel")
	var column := kit_content(details,24)
	kit_button(column,loc("닫기","Close","关闭"),Rect2(),Callable(details,"hide"),"ResultDetailsClose")
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var body := kit_flow(scroll,true)
	kit_line(body,LanguageSettings.ui_text(str(model.get("primary_cause_label",""))),"ResultObservation",GOLD)
	kit_line(body,LanguageSettings.ui_text(str(model.get("decision_feedback",{}).get("summary",""))),"ResultDecisionFeedback",MUTED)
	kit_line(body,LanguageSettings.ui_text(str(model.get("facility_feedback",""))),"ResultFacilityFeedback",PAPER)
	for row in model.get("conditional_alerts",[]): kit_line(body,LanguageSettings.ui_text(str(row.label)+" "+str(row.value)))
	var balance: Dictionary = model.get("resource_balance",{})
	if not balance.is_empty():
		var delta: Dictionary = balance.get("delta",{})
		kit_line(body,LanguageSettings.ui_text("최종 순변동" if bool(model.get("win",false)) else "재도전 복구 후 순변동")+" · "+LanguageSettings.ui_text("금화 %+d / 마력 %+d" % [int(delta.get("gold",0)),int(delta.get("mana",0))]),"ResultResourceBalance",GOLD)
		kit_line(body,LanguageSettings.ui_text("전투 시작부터 결산 완료까지의 변화입니다. 다음 날 수입은 포함하지 않습니다."))
		for item in [["gold","금화"],["mana","마력"],["food","식량"],["infamy","악명"]]:
			kit_line(body,"%s: %d → %d (%+d)" % [LanguageSettings.ui_text(item[1]),int(balance.get("before",{}).get(item[0],0)),int(balance.get("after",{}).get(item[0],0)),int(delta.get(item[0],0))])
	if str(model.get("retry_action_label","")) != "": kit_line(body,LanguageSettings.ui_text(str(model.retry_action_label)),"ResultRetryAction",GOLD)
	var next_text: String = root.growth_feedback.next_choice() if root._is_regular_campaign_final_battle() and bool(model.get("win",false)) else ""
	if next_text != "": kit_line(body,next_text,"ResultNextBuildChoice",GOLD)
	details.hide()
