extends "res://scripts/ui/ManagementWorkspaceUI.gd"

func build_result(model: Dictionary, title: String, final_battle: bool) -> void:
	var screen := panel(Rect2(0, 0, 1920, 1080), "V122ResultScreen")
	copy(screen, "DAY %02d  /  방어 기록" % GameState.day, Rect2(72, 32, 1200, 36), 20, MUTED)
	copy(screen, title, Rect2(72, 76, 1700, 64), 40, PAPER, "ResultTitle")
	copy(screen, str(model.get("primary_cause_label", "")), Rect2(74, 146, 1750, 40), 24, GOLD, "ResultObservation")
	var metrics: Panel = hud.child_panel(screen, Rect2(72, 210, 830, 560), INK.darkened(0.2), LINE)
	metrics.name = "ResultCoreMetrics"
	copy(metrics, "이번 방어에서 확인한 것", Rect2(24, 16, 782, 44), 28)
	var feedback: Dictionary = model.get("decision_feedback", {})
	var feedback_text := "배치별 상세 교전 기록 없음" if feedback.is_empty() else "내 선택의 결과 · " + str(feedback.get("summary", ""))
	copy(metrics, feedback_text, Rect2(24, 68, 782, 88), 22, MUTED, "ResultDecisionFeedback")
	var core: Array = model.get("core_metrics", [])
	for i in range(core.size()):
		var row: Panel = hud.child_panel(metrics, Rect2(24, 168 + i * 94, 782, 82), INK.lightened(0.05), LINE.darkened(0.4))
		copy(row, str(core[i].get("label", "")), Rect2(16, 12, 256, 56), 22, MUTED)
		var value := copy(row, str(core[i].get("value", "")), Rect2(282, 12, 484, 56), 26)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var alerts: Array[String] = []
	for alert in model.get("conditional_alerts", []):
		alerts.append("%s %s" % [str(alert.get("label", "")), str(alert.get("value", ""))])
	if not alerts.is_empty():
		copy(metrics, "추가 기록 · " + "  /  ".join(alerts), Rect2(24, 470, 782, 60), 22, Color("#f6a597"))
	var rewards: Dictionary = model.get("rewards", {})
	var paid: Array[String] = []
	for item in [["gold", "금화"], ["mana", "마나"], ["food", "식량"], ["infamy", "악명"]]:
		if int(rewards.get(item[0], 0)) > 0:
			paid.append("%s +%d" % [item[1], int(rewards[item[0]])])
	copy(screen, "획득 보상 · " + ("  /  ".join(paid) if not paid.is_empty() else "없음"), Rect2(72, 788, 830, 58), 22, GOLD, "ResultRewards")
	_growth(screen)
	var next_text := str(model.get("retry_action_label", ""))
	if next_text == "":
		next_text = "성장을 확인하고 다음 방어를 준비하세요." if not root.last_growth_summary.is_empty() else "결산을 확인하고 다음 일정으로 진행하세요."
	copy(screen, next_text, Rect2(72, 864, 1776, 72), 24, GOLD, "ResultRetryAction")
	var actions: Array = model.get("actions", [])
	for i in range(actions.size()):
		var action: Dictionary = actions[i]
		var id := str(action.get("id", ""))
		var target := str({"continue":"NextDayButton", "edit_placement":"ResultEditPlacement", "retry_same_placement":"ResultRetrySamePlacement"}.get(id, id))
		var text := str(action.get("label", ""))
		if final_battle and bool(model.get("win", false)) and id == "continue":
			text = "엔딩 보기"
		var b := button(screen, text, Rect2(1848 - actions.size() * 442 + i * 442, 958, 418, 76), Callable(root, str(action.get("callback", ""))), target, "primary" if i == 0 else "utility")
		if id == "continue":
			if root._result_growth_choice_required() and not root.result_growth_choice_applied:
				b.disabled = true
				b.text = "집중 성장 선택 필요"
			elif root.onboarding_enabled and root.tutorial_gate_enabled and root.tutorial_manager.is_active_for_stage(root.onboarding_stage_id) and root.tutorial_manager.expected_action() == "growth_reviewed":
				b.disabled = true
				b.text = "성장 확인 필요"
		if i == 0 and not b.disabled:
			call_deferred("focus_if_visible",b)

func _growth(screen: Control) -> void:
	var pane: Panel = hud.child_panel(screen, Rect2(930, 210, 918, 636), INK.darkened(0.2), LINE)
	pane.name = "ResultGrowthPanel"
	copy(pane, "동료들의 성장", Rect2(24, 16, 870, 44), 28)
	var required: bool = root._result_growth_choice_required()
	var caption := "이번 전투에서 반영된 경험치"
	if required:
		caption = "다음 방어를 준비할 한 명 · 집중 성장 선택"
	if root.result_growth_choice_applied:
		caption = "%s · 집중 성장 반영 완료" % str(root.last_growth_choice_summary.get("display_name", "동료"))
	copy(pane, caption, Rect2(24, 66, 870, 56), 22, GOLD)
	var scroll := ScrollContainer.new()
	scroll.name = "ResultGrowthScroll"
	scroll.position = Vector2(24, 130)
	scroll.size = Vector2(870, 398)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	pane.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	if root.last_growth_summary.is_empty():
		var empty := copy(list, "이번 전투 성장 기록이 없습니다.", Rect2(0, 0, 836, 100), 24, MUTED)
		empty.custom_minimum_size = Vector2(836, 100)
	for row in root.last_growth_summary:
		var card: Panel = hud.child_panel(list, Rect2(0, 0, 836, 178), INK.lightened(0.05), LINE.darkened(0.4))
		card.custom_minimum_size = Vector2(836, 178)
		var id := str(row.get("monster_id", ""))
		var portrait_path: String = root.management_scene.monster_portrait_path(id, "victory" if root.result_summary.get("win", false) else "wounded")
		if portrait_path != "":
			var portrait: TextureRect = hud.texture(card, portrait_path, Rect2(12, 14, 126, 150))
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		copy(card, str(row.get("display_name", id)), Rect2(154, 10, 340, 36), 26)
		copy(card, "Lv.%d → %d  ·  EXP +%d" % [int(row.get("level_before", 1)), int(row.get("level_after", 1)), int(row.get("exp_gain", 0))], Rect2(154, 50, 400, 38), 22, GOLD)
		copy(card, "공유 +%d · 활약 +%d" % [int(row.get("shared_exp", int(row.get("exp_gain", 0)) - int(row.get("activity_exp", 0)))), int(row.get("activity_exp", 0))], Rect2(154, 92, 400, 32), 20, MUTED)
		if required:
			var bonus: int = root._result_growth_choice_bonus()
			var preview: String = "%d/%d EXP" % [int(row.get("exp_after", 0)), int(row.get("next_exp", 1))] if root.result_growth_choice_applied else root.management_scene._growth_choice_preview_text(row, bonus)
			copy(card, preview, Rect2(566, 8, 252, 38), 20, GOLD, "GrowthChoicePreview_%s" % id)
			var preparation: String = root._result_growth_preparation_summary(id)
			copy(card, preparation, Rect2(154, 128, 654, 42), 18, MUTED, "GrowthChoicePreparation_%s" % id)
			var b := button(card, "집중 성장 +%d" % bonus, Rect2(566, 52, 252, 66), Callable(root, "_choose_result_growth").bind(id), "GrowthChoice_%s" % id, "tactical")
			b.disabled = root.result_growth_choice_applied
			if str(root.result_growth_choice_monster_id) == id:
				b.text = "선택됨"
	copy(pane, "모든 동료를 스크롤하거나 Tab으로 선택할 수 있습니다.", Rect2(24, 544, 560, 70), 20, MUTED)
	if bool(root.result_summary.get("win", false)) and not root.last_growth_summary.is_empty():
		var b := button(pane, "성장 확인", Rect2(620, 552, 274, 60), Callable(root, "_review_growth_from_result"), "GrowthReviewButton")
		if required and not root.result_growth_choice_applied:
			b.disabled = true
			b.text = "집중 성장 선택 필요"
		elif root.result_growth_reviewed:
			b.disabled = true
			b.text = "확인 완료"
