extends "res://scripts/ui/ManagementWorkspaceUI.gd"

func build_monster() -> void:
	hud.build_top_bar()
	root._ensure_selected_monster_available_for_defense()
	var left := panel(Rect2(24, 100, 336, 944), "MonsterRosterPanel")
	copy(left, "동료", Rect2(20, 12, 296, 48), 30)
	var list := scroll_list(left, Rect2(12, 78, 312, 672), "MonsterRosterScroll")
	for id in root._defense_monster_ids():
		var roster: Dictionary = root.monster_roster[id]
		var row := button(list, "", Rect2(0, 0, 286, 112), Callable(root, "_select_monster").bind(id), root.management_scene._tutorial_monster_target_id(id), "tactical")
		row.custom_minimum_size = Vector2(286, 112)
		portrait(row, id, Rect2(6, 8, 86, 96))
		copy(row, root._monster_display_name(id), Rect2(102, 10, 170, 34), 24)
		var location := room_name(str(roster.get("room", "")))
		copy(row, "Lv.%d · %s" % [int(roster.get("level", 1)), location], Rect2(102, 48, 170, 56), 20, MUTED)
		if id == root.selected_monster_id:
			hud.apply_button_state(row, "selected")
	copy(left, root._support_only_monster_line(), Rect2(20, 762, 296, 72), 18, MUTED)
	if root._contract_roster_available():
		button(left, "출전·예비 편성", Rect2(20, 838, 296, 42), Callable(root, "_open_contract_roster"), "MonsterContractRoster")
	button(left, "관리로 돌아가기", Rect2(20, 888, 296, 44), Callable(root, "_set_screen").bind(Constants.SCREEN_MANAGEMENT), "MonsterBackButton")
	var middle := panel(Rect2(384, 100, 580, 944), "MonsterSelectedDetail")
	var id: String = root.selected_monster_id
	if id == "" or not root.monster_roster.has(id):
		copy(middle, "현재 출전 가능한 동료가 없습니다.\n출전·예비 편성에서 동료를 확인하세요.", Rect2(32, 360, 516, 150), 26)
		return
	var roster: Dictionary = root.monster_roster[id]
	var data := DataRegistry.monster(id)
	var stats: Dictionary = root._scaled_monster_stats(id)
	copy(middle, root._monster_display_name(id), Rect2(24, 16, 532, 54), 36)
	copy(middle, "Lv.%d · %s" % [int(roster["level"]), str(roster.get("role_tag", data.get("role", "")))], Rect2(24, 76, 532, 42), 24, GOLD)
	portrait(middle, id, Rect2(40, 128, 500, 376))
	copy(middle, "현재 배치 · " + room_name(str(roster.get("room", ""))), Rect2(24, 518, 532, 64), 24, PAPER, "MonsterCurrentRoom")
	var stat_keys := [["max_hp","체력"],["atk","공격"],["def","방어"],["move_speed","이동 속도"],["int","지능"],["loyalty","충성"]]
	for i in range(stat_keys.size()):
		var key: Array = stat_keys[i]
		var x := 24.0 + (i % 2) * 266.0
		var y := 600.0 + (i / 2) * 60.0
		copy(middle, "%s  %d" % [key[1], int(stats.get(key[0], 0))], Rect2(x, y, 250, 48), 24)
	copy(middle, "유대 %d/100 · %s" % [int(roster.get("bond", 0)), root._monster_bond_rank_name(int(roster.get("bond", 0)))], Rect2(24, 794, 532, 52), 22, GOLD)
	button(middle, "기억 보기 · %d개" % roster.get("unlocked_memory_ids", []).size(), Rect2(24, 868, 532, 64), Callable(root, "_open_selected_monster_memories"), "MonsterMemoryButton")
	var right := panel(Rect2(988, 100, 908, 944), "MonsterGrowthTools")
	copy(right, "성장과 전술", Rect2(24, 16, 860, 48), 30)
	var tools := scroll_list(right, Rect2(24, 84, 860, 836), "MonsterGrowthScroll")
	var preparation: String = root._active_growth_preparation_line(id)
	if preparation != "":
		var preparation_card := entry(tools, 142)
		copy(preparation_card, preparation, Rect2(24, 14, 784, 66), 22, GOLD)
		copy(preparation_card, "이번 방어전이 끝나면 사라집니다.", Rect2(24, 88, 784, 40), 20, MUTED)
	_training(tools, id, roster, stats)
	_specialization(tools, id)
	_promotion(tools, id)
	var heading := copy(tools, "보유 기술", Rect2(0, 0, 832, 52), 28)
	heading.custom_minimum_size = Vector2(832, 52)
	for skill_id in data.get("skill_slots", []):
		var card := entry(tools, 142)
		if skill_id == null:
			copy(card, "잠금 슬롯", Rect2(24, 24, 784, 84), 22, MUTED)
			continue
		var skill := DataRegistry.skill(str(skill_id))
		var path := str(skill.get("icon", ""))
		if path != "":
			hud.texture(card, path, Rect2(16, 20, 96, 96))
		copy(card, str(skill.get("display_name", skill_id)), Rect2(132, 12, 678, 36), 24)
		copy(card, str(skill.get("description", "")), Rect2(132, 54, 678, 78), 22, MUTED)

func _training(parent: Control, id: String, roster: Dictionary, current: Dictionary) -> void:
	var card := entry(parent, 266)
	copy(card, "훈련", Rect2(24, 12, 784, 40), 28)
	var level := int(roster.get("level", 1))
	var exp: int = int(roster.get("exp", 0)) + root.MONSTER_TRAINING_EXP
	while exp >= root._monster_exp_to_next(level):
		exp -= root._monster_exp_to_next(level)
		level += 1
	var after: Dictionary = root._scaled_monster_stats(id, level)
	copy(card, "금화 %d · EXP +%d  /  하루 2회" % [int(root.MONSTER_TRAINING_COST.gold), root.MONSTER_TRAINING_EXP], Rect2(24, 58, 784, 36), 22, GOLD)
	copy(card, "EXP %d → %d/%d · Lv.%d → %d" % [int(roster.get("exp", 0)), exp, root._monster_exp_to_next(level), int(roster.get("level", 1)), level], Rect2(24, 102, 784, 36), 22, PAPER, "TrainingExpPreview")
	copy(card, "체력 %d → %d    공격 %d → %d    방어 %d → %d" % [int(current.max_hp), int(after.max_hp), int(current.atk), int(after.atk), int(current.def), int(after.def)], Rect2(24, 146, 784, 38), 22, MUTED, "TrainingStatsPreview")
	var reason: String = root._training_block_reason(id)
	if reason == "" and not GameState.can_pay(root.MONSTER_TRAINING_COST):
		reason = "금화 부족"
	var b := button(card, "훈련하기" if reason == "" else reason, Rect2(24, 198, 784, 54), Callable(root, "_train_selected_monster"), "MonsterTrainingButton", "primary")
	b.disabled = reason != ""

func _specialization(parent: Control, id: String) -> void:
	var active: Dictionary = root._monster_specialization(id)
	if not active.is_empty():
		var card := entry(parent, 182)
		copy(card, "전술 특화 · " + str(active.get("display_name", "")), Rect2(24, 16, 784, 44), 26, GOLD)
		copy(card, str(active.get("description", "")), Rect2(24, 70, 784, 96), 22, MUTED)
		return
	if not root._early_specialization_unlocked():
		var locked := entry(parent, 82)
		copy(locked, "전술 특화 · DAY 2에 해금", Rect2(24, 14, 784, 54), 24, MUTED)
		return
	for option in root._specializations_for_monster(id):
		var card := entry(parent, 212)
		var spec_id := str(option.get("id", ""))
		copy(card, "특화 · " + str(option.get("display_name", "")), Rect2(24, 12, 784, 42), 26, GOLD)
		copy(card, str(option.get("description", "")), Rect2(24, 62, 784, 74), 22)
		var reason: String = root._specialization_block_reason(id)
		var b := button(card, "이 특화 선택 · 변경 불가" if reason == "" else reason, Rect2(24, 150, 784, 50), Callable(root, "_choose_early_specialization").bind(id, spec_id), "MonsterSpecialization_" + spec_id, "tactical")
		b.disabled = not root._can_choose_early_specialization(id, spec_id)

func _promotion(parent: Control, id: String) -> void:
	if not root._promotion_unlocked():
		return
	var active: Dictionary = root._monster_promotion_rule(id)
	if not active.is_empty():
		var card := entry(parent, 128)
		copy(card, "진화 완료 · " + str(active.get("display_name", "")), Rect2(24, 14, 784, 42), 26, GOLD)
		copy(card, root._selected_promotion_summary(), Rect2(24, 64, 784, 52), 20, MUTED)
		return
	var i := 0
	for option in root._evolution_rules_for_monster(id):
		var card := entry(parent, 278)
		var rule_id := str(option.get("id", ""))
		var path := str(option.get("portrait", ""))
		if path != "":
			hud.texture(card, path, Rect2(12, 18, 152, 182))
		copy(card, str(option.get("display_name", "")), Rect2(182, 12, 626, 42), 26, GOLD)
		copy(card, str(option.get("role_summary", "")), Rect2(182, 64, 626, 78), 22)
		copy(card, "비용 · " + str(root._cost_label(option.get("cost", {}))), Rect2(182, 152, 626, 48), 22, MUTED)
		var reason: String = root._promotion_block_reason(id, rule_id)
		var b := button(card, "이 모습으로 진화 · 변경 불가" if reason == "" else reason, Rect2(24, 214, 784, 52), Callable(root, "_promote_monster").bind(id, rule_id), "PromotionOption%d" % i, "tactical")
		b.disabled = not root._can_promote_monster(id, rule_id)
		i += 1

func entry(parent: Control, height: float) -> Panel:
	var result: Panel = hud.child_panel(parent, Rect2(0, 0, 832, height), INK.darkened(0.2), LINE.darkened(0.3))
	result.custom_minimum_size = Vector2(832, height)
	return result

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
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)
	return list

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
