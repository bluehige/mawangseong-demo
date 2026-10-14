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
	root.management_scene.monster_ui._glass(pane,0.84)
	return pane

func _portrait(parent: Control, id: String, rect: Rect2, victory: bool = false) -> void:
	var emotion: String = "victory" if victory else root.management_scene.result_portrait_emotion(id)
	var path: String = root.management_scene.monster_portrait_path(id,emotion)
	if path == "" or not ResourceLoader.exists(path):
		kit_copy(parent,loc("초상 없음","No portrait","无立绘"),rect,24,MUTED,"ResultMissingPortrait_"+id)
		return
	var art: TextureRect = root.management_scene.monster_ui._art(parent,id,rect.size,false,path)
	art.position = rect.position
	art.name = ("ResultVictory_" if victory else "ResultPortrait_")+id
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_meta("portrait_emotion",emotion)
	art.set_meta("source_path",path)

func build_result(model: Dictionary, title: String, final_battle: bool) -> void:
	shared_theme = null
	var layout := Layout.design_layout_contract(false,false,true)
	var win: bool = model.get("win",false)
	root.management_scene.monster_ui._background()
	var background: TextureRect = root.ui_layer.get_node("MonsterCastleBackground")
	background.name = "ResultCastleBackground"
	background.modulate = Color(0.42,0.38,0.48) if not win else Color(0.88,0.82,0.94)
	var screen := Panel.new()
	screen.name = "V122ResultScreen"; screen.size = Vector2(1920,1080)
	screen.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	root.ui_layer.add_child(screen)
	var hero := Panel.new()
	hero.name = "ResultHero"; hero.position = layout.hero.position; hero.size = layout.hero.size
	hero.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	screen.add_child(hero)
	var ids: Array = []
	for row in root.last_growth_summary: ids.append(str(row.get("monster_id","")))
	if ids.is_empty(): ids = root.monster_roster.keys()
	if not bool(root.result_summary.get("management_only",false)):
		for i in range(mini(3,ids.size())):
			_portrait(hero,str(ids[i]),[Rect2(370,332,350,174),Rect2(12,12,440,494),Rect2(1432,12,428,494)][i],win)
	var banner := _child(hero,Rect2(496,8,880,242),"ResultTitleBanner")
	var day := kit_copy(banner,"DAY %d" % GameState.day,Rect2(24,14,832,48),36,GOLD,"ResultDay")
	day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_size := 48 if final_battle and LanguageSettings.locale == "en" else (64 if final_battle or LanguageSettings.locale == "en" else 88)
	var heading := kit_copy(banner,LanguageSettings.ui_text(title),Rect2(24,76,832,144),title_size,PAPER,"ResultTitle")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var core: Array[String] = []
	for row in model.get("core_metrics",[]):
		if str(row.id) == "final_breach_segment": continue
		var caption := loc("생존","Survived","存活") if str(row.id) == "monster_survival" else LanguageSettings.ui_text(str(row.label))
		core.append(caption+" "+LanguageSettings.ui_text(str(row.value)))
	var metrics_pane := _child(hero,Rect2(496,260,880,62),"ResultMetricsBanner")
	var metrics := kit_copy(metrics_pane," · ".join(core),Rect2(16,10,848,42),28,PAPER,"ResultCoreMetrics")
	metrics.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rewards(hero,model.get("rewards",{}))
	_growth(screen)
	var toggle := kit_button(screen,loc("상세 기록","Details","详细记录"),Rect2(1596,548,270,52),Callable(),"ResultDetailsButton")
	_compact_button(toggle,Vector2(270,52))
	toggle.tooltip_text = loc("동료 상세 성과·배치·시설·자원 순변동 기록","Companion details, placement, facilities and net resource changes","伙伴详细战绩、部署、设施与资源净变化记录")
	var preview_rect: Rect2 = layout.training_preview
	if model.get("actions",[]).size() > 1: preview_rect.size.x = 890
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
		if actions.size() > 1: rect = Rect2(940+i*478,948,454,100)
		var b := kit_button(screen,text,rect,Callable(root,str(action.callback)),target,"primary" if i == 0 else "utility")
		if id == "continue":
			b.disabled = (root._result_growth_choice_required() and (not root.result_growth_choice_applied or not root.result_growth_reviewed)) or (root.onboarding_enabled and root.tutorial_gate_enabled and root.tutorial_manager.is_active_for_stage(root.onboarding_stage_id) and root.tutorial_manager.expected_action() == "growth_reviewed")
		if i == 0 and not b.disabled: call_deferred("focus_if_visible",b)
	_details(screen,model)
	toggle.pressed.connect(Callable(details,"show"))
	_preserve(screen)

func _rewards(hero: Control, rewards: Dictionary) -> void:
	var resources: Array[String] = ["gold","mana","infamy"]
	if int(rewards.get("food",0)) > 0: resources.append("food")
	var pane := _child(hero,Rect2(752,338,624,168),"ResultRewards")
	var caption := kit_copy(pane,loc("획득 보상","Rewards","获得奖励"),Rect2(16,6,592,36),24,GOLD,"ResultRewardHeading")
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var width := 592.0/resources.size()
	for i in range(resources.size()):
		var id := resources[i]
		var x := 16+i*width
		var icon := ManagementKit.image(id,64)
		icon.name = "ResultRewardIcon_"+id; icon.position = Vector2(x+(width-64)/2,44)
		pane.add_child(icon)
		var value := kit_copy(pane,"+%d" % int(rewards.get(id,0)),Rect2(x,112,width,48),36,PAPER,"ResultRewardValue_"+id)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _cell(parent: Control, text: String, rect: Rect2, id: String, color: Color = PAPER) -> Label:
	var label := kit_copy(parent,text,rect,24,color,id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _measured(value: int, count: bool = false) -> String:
	return (loc("%d회","%d uses","%d次") % value if count else str(value)) if value > 0 else "—"

func _compact_button(button: Button, extent: Vector2) -> void:
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		var style: StyleBox = button.get_theme_stylebox(state).duplicate()
		style.set_content_margin(SIDE_TOP,2); style.set_content_margin(SIDE_BOTTOM,2)
		button.add_theme_stylebox_override(state,style)
	button.size = extent

func _row_details(row: Dictionary) -> String:
	var support: Dictionary = root.growth_feedback.normalize(row.get("support_contribution",{}))
	var lines: Array[String] = ["Lv.%d → %d" % [int(row.get("level_before",1)),int(row.get("level_after",1))],loc("공유 EXP +%d · 활약 EXP +%d","Shared EXP +%d · Activity EXP +%d","共享EXP +%d · 表现EXP +%d") % [int(row.get("shared_exp",0)),int(row.get("activity_exp",0))]]
	for pair in [["damage_absorbed",loc("받은 피해 %d","Damage taken %d","承受伤害%d")],["shield_absorbed",loc("방어막 흡수 %d","Barrier absorbed %d","护盾吸收%d")],["redirect_actual_hp_taken",loc("대신 받은 피해 %d","Redirected HP %d","代受伤害%d")],["facility_value",loc("시설 지원 %d","Facility support %d","设施支援%d")]]:
		var value := int(row.get(pair[0],0)) if pair[0] in ["damage_absorbed","facility_value"] else int(support.get(pair[0],0))
		lines.append(pair[1] % value)
	lines.append(root.support_mastery.summary(str(row.get("monster_id",""))))
	return "\n".join(lines)

func _preparation(id: String) -> String:
	return LanguageSettings.ui_text(root._result_growth_preparation_preview(id))

func _growth(screen: Control) -> void:
	var pane := _child(screen,Layout.design_layout_contract(false,false,true).performance,"ResultGrowthPanel")
	pane.tooltip_text = loc("동료 성과 · 승리 후 한 명 집중성장 +8 · 세부는 상세 기록","Companion performance · One free focus growth +8 after victory · Details in records","伙伴战绩 · 胜利后为一名伙伴集中成长+8 · 细节见详细记录")
	var columns := [[24,300,loc("동료","Companion","伙伴")],[324,150,loc("피해","Damage","伤害")],[474,150,loc("회복","Healing","治疗")],[624,170,loc("보호","Protection","保护")],[794,160,loc("합동기","Duo","合技")],[954,350,"EXP"],[1304,240,loc("비고","Notes","备注")]]
	for i in range(columns.size()):
		var col: Array = columns[i]
		_cell(pane,col[2],Rect2(col[0],8,col[1],44),"ResultColumn_%d" % i,GOLD)
		if i > 0:
			var divider := Line2D.new()
			divider.points = PackedVector2Array([Vector2(col[0],12),Vector2(col[0],334)])
			divider.width = 1; divider.default_color = Color(0.6,0.45,0.7,0.35)
			pane.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.name = "ResultGrowthScroll"; scroll.position = Vector2(24,62); scroll.size = Vector2(1824,276)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.follow_focus = true
	pane.add_child(scroll)
	var list := kit_flow(scroll,true)
	list.add_theme_constant_override("separation",8)
	if root.last_growth_summary.is_empty(): kit_line(list,loc("이번 전투 성장 기록이 없습니다.","No growth records for this battle.","本场无成长记录。"),"ResultEmptyGrowth",MUTED)
	for row in root.last_growth_summary:
		var id := str(row.get("monster_id",""))
		var selected: bool = root.result_growth_choice_applied and root.result_growth_choice_monster_id == id
		var card := _child(list,Rect2(0,0,1800,84),"ResultCompanion_"+id)
		card.custom_minimum_size = Vector2(1800,84)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_STOP; card.tooltip_text = _row_details(row)
		if selected:
			for child in card.get_children():
				if child is Surface: card.remove_child(child); child.queue_free()
			var highlight := StyleBoxFlat.new()
			highlight.bg_color = Color(0.12,0.06,0.20,0.86)
			highlight.border_color = Color("#cda5ff")
			highlight.set_border_width_all(2); highlight.set_corner_radius_all(18)
			card.add_theme_stylebox_override("panel",highlight)
		_portrait(card,id,Rect2(8,4,92,76))
		kit_copy(card,root._monster_companion_name(id),Rect2(110,18,182,48),26,PAPER,"ResultName_"+id)
		var support: Dictionary = root.growth_feedback.normalize(row.get("support_contribution",{}))
		for metric in [["Attack",300,150,int(row.get("damage_dealt",0)),false],["Healing",450,150,int(support.get("effective_healing",0)),false],["Protection",600,170,int(support.get("support_protection_applications",0)),true],["Duo",770,160,int(support.get("duo_shared_commits",0)),true]]:
			_cell(card,_measured(metric[3],metric[4]),Rect2(metric[1],18,metric[2],48),"Result%s_%s" % [metric[0],id])
		var before_max: int = root._monster_exp_to_next(int(row.get("level_before",1)))
		var after_max: int = root._monster_exp_to_next(int(row.get("level_after",1)))
		var exp := _cell(card,"%d/%d → %d/%d" % [int(row.get("exp_before",0)),before_max,int(row.get("exp_after",0)),after_max],Rect2(930,2,350,38),"ResultExpTransition_"+id)
		exp.tooltip_text = _row_details(row)
		exp.mouse_filter = Control.MOUSE_FILTER_STOP
		_cell(card,loc("영구 EXP +%d","Permanent EXP +%d","永久EXP +%d") % int(row.get("exp_gain",0)),Rect2(930,42,350,38),"ResultExpGain_"+id,GOLD)
		if root._result_growth_choice_required():
			var b := kit_button(card,loc("집중성장 선택됨","Focus growth selected","已选择集中成长") if selected else loc("집중성장 +8","Focus growth +8","集中成长+8"),Rect2(1294,4,494,40),Callable(root,"_choose_result_growth").bind(id),"GrowthChoice_"+id,"primary" if selected else "tactical")
			b.disabled = root.result_growth_choice_applied
			_compact_button(b,Vector2(494,40))
			b.tooltip_text = LanguageSettings.ui_text(root.management_scene._growth_choice_preview_text(row,root._result_growth_choice_bonus()))+"\n"+LanguageSettings.ui_text(root._result_growth_preparation_summary(id))+"\n"+_row_details(row)
			if selected:
				b.add_theme_color_override("font_disabled_color",PAPER)
				b.surface._material.set_shader_parameter("top_color",Color("#62329a"))
				b.surface._material.set_shader_parameter("bottom_color",Color("#34124f"))
				b.surface._material.set_shader_parameter("rim_color",Color("#cda5ff"))
			var preparation := "DAY %d · " % int(root.monster_roster[id].get("growth_preparation_day",GameState.day+1))+_preparation(id) if selected else ("—" if root.result_growth_choice_applied else loc("승리 후 1명 · 무료 +8","One after victory · Free +8","胜利后1名 · 免费+8"))
			_cell(card,preparation,Rect2(1294,46,494,36),("GrowthChoicePreparation_" if selected else "GrowthChoicePreview_")+id,GOLD if selected else MUTED)
		else:
			_cell(card,"—",Rect2(1294,18,494,48),"ResultNote_"+id,MUTED)

func _training_preview(screen: Control, rect: Rect2, final_battle: bool) -> void:
	var pane := _child(screen,rect,"ResultTrainingPreview")
	var id: String = root.result_growth_choice_monster_id
	if not root.monster_roster.has(id):
		id = str(root.last_growth_summary[0].get("monster_id","")) if not root.last_growth_summary.is_empty() else ""
	var available: bool = root.monster_roster.has(id)
	if available: _portrait(pane,id,Rect2(8,8,112,124))
	var width := rect.size.x-152
	var win: bool = root.result_summary.get("win",false)
	if final_battle or not win or not available:
		var heading := loc("최종 결산","Final result","最终结算") if final_battle else (loc("결산 확인","Result review","确认结算") if win else loc("재도전 준비","Retry preparation","重试准备"))
		var copy := loc("동료의 영구 성장을 확인하고 엔딩을 보세요.","Review permanent growth, then view the ending.","确认伙伴的永久成长后查看结局。") if final_battle else (loc("결산을 확인하고 다음 일정으로 진행하세요.","Review the result and continue.","确认结算后继续下一安排。") if win else loc("배치를 수정하거나 같은 배치로 재도전하세요.","Edit placement or retry with the same placement.","修改部署或以相同部署重试。"))
		kit_copy(pane,heading,Rect2(136,12,width,40),28,GOLD,"ResultPreviewHeading")
		kit_copy(pane,copy,Rect2(136,62,width,64),24,MUTED,"ResultPreviewUnavailable")
		return
	kit_copy(pane,root._monster_companion_name(id)+" · "+loc("훈련 미리보기","Training preview","训练预览"),Rect2(136,8,width,40),26,GOLD,"ResultTrainingCompanion")
	var icon := ManagementKit.image("gold",32)
	icon.position = Vector2(136,57); pane.add_child(icon)
	kit_copy(pane,"%d   ·   EXP +%d" % [root.MONSTER_TRAINING_COST.gold,root.MONSTER_TRAINING_EXP],Rect2(180,52,width-44,40),26,PAPER,"ResultTrainingCost")
	kit_copy(pane,loc("다음 DAY 준비에서 실행","Run during next DAY preparation","下一天备战时执行"),Rect2(136,96,width,36),24,MUTED,"ResultTrainingTiming")
	pane.tooltip_text = loc("읽기 전용 미리보기 · 다음 DAY 대화·필수 준비 후 몬스터 → 같은 동료 훈련","Read-only preview · Next DAY dialogue / required prep → Monsters → Same companion training","只读预览 · 下一天对话与必需准备后：怪物 → 此伙伴训练")
	if root.result_growth_choice_applied:
		var next: Dictionary = root.management_scene.monster_ui.training_preview(id)
		var roster: Dictionary = root.monster_roster[id]
		pane.tooltip_text += "\nLv.%d → %d · EXP %d → %d" % [int(roster.level),int(next.level),int(roster.exp),int(next.exp)]
		var day: int = int(roster.get("growth_preparation_day",GameState.day+1))
		pane.tooltip_text += "\nDAY %d · " % day+LanguageSettings.ui_text(root._result_growth_preparation_summary(id))

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
	for metric in model.get("core_metrics",[]):
		kit_line(body,LanguageSettings.ui_text(str(metric.label))+" "+LanguageSettings.ui_text(str(metric.value)))
	for row in root.last_growth_summary:
		kit_line(body,root._monster_companion_name(str(row.get("monster_id","")))+" · "+_row_details(row),"",MUTED)
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
