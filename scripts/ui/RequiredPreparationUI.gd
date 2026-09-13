extends "res://scripts/ui/ManagementWorkspaceUI.gd"

func build_required(model: Dictionary, reason: String) -> void:
	# Council choices already have one full-size required-choice overlay.
	if reason == "council_choice":
		return
	var pane := panel(Rect2(1072, 144, 824, 598), "ManagementContextDrawer")
	pane.z_index = 120
	copy(pane, "필수 준비", Rect2(24, 14, 580, 46), 30, GOLD)
	button(pane, "닫기", Rect2(660, 16, 140, 46), Callable(root, "_close_management_context_drawer"), "CloseManagementContextButton")
	copy(pane, str(model.get("start", {}).get("blocked_reason", "선택을 마치고 방어를 준비하세요.")), Rect2(24, 72, 776, 74), 24, PAPER, "RequiredChoiceReason")
	var scroll := ScrollContainer.new()
	scroll.name = "RequiredPreparationScroll"
	scroll.position = Vector2(24, 162)
	scroll.size = Vector2(776, 412)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	pane.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)
	if reason == "specialization":
		for id in root._defense_monster_ids():
			if str(root.monster_roster.get(id, {}).get("specialization_id", "")) != "":
				continue
			for option in root._specializations_for_monster(id):
				var spec_id := str(option.get("id", ""))
				var card: Panel = hud.child_panel(list, Rect2(0, 0, 748, 224), INK.darkened(0.2), LINE)
				card.custom_minimum_size = Vector2(748, 224)
				copy(card, "%s · %s" % [root._monster_display_name(id), str(option.get("display_name", ""))], Rect2(20, 10, 708, 44), 26, GOLD)
				copy(card, str(option.get("description", "")), Rect2(20, 62, 708, 84), 22)
				var b := button(card, "특화 확정 · 선택 후 변경 불가", Rect2(20, 162, 708, 48), Callable(root, "_choose_early_specialization_from_drawer").bind(id, spec_id), "RequiredSpecialization_%s_%s" % [id,spec_id], "tactical")
				b.disabled = not root._can_choose_early_specialization(id, spec_id)
	elif reason == "raid_choice":
		var caption := copy(list, "원정에서 임무·비용·동료를 함께 검토하세요.\n원정을 마친 뒤 방어 준비를 눌러 다음 준비를 이어가세요.", Rect2(0, 0, 748, 140), 24)
		caption.custom_minimum_size = Vector2(748, 140)
		var b := button(list, "원정 계획 열기", Rect2(0, 0, 748, 76), Callable(root, "_open_raid_screen"), "RequiredRaidOpenButton", "primary")
		b.custom_minimum_size = Vector2(748, 76)
	elif reason == "final_declaration":
		var choices := [{"id":"rival_pact","label":"라이벌 약속"},{"id":"castle_oath","label":"성 수호"}]
		if root._campaign_armistice_request_available():
			choices.append({"id":"grand_armistice_request","label":"휴전문 제안"})
		for choice in choices:
			var b := button(list, str(choice.label), Rect2(0, 0, 748, 88), Callable(root, "_set_campaign_final_declaration").bind(str(choice.id)), "RequiredFinalDeclaration_" + str(choice.id), "tactical")
			b.custom_minimum_size = Vector2(748, 88)
