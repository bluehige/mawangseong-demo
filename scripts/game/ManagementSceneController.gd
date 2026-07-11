extends RefCounted
class_name ManagementSceneController

const Constants = preload("res://scripts/core/Constants.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")

var root: Node
var hud

func setup(game_root: Node, hud_controller) -> void:
	root = game_root
	hud = hud_controller

func build_management_ui() -> void:
	hud.build_top_bar()
	if root.build_pick_mode:
		hud.build_facility_build_panel(16, 92, 300, 780)
	else:
		hud.build_room_list(16, 92, 300, 420)
		_build_layout_selector()
	_build_campaign_notice()

	var right = hud.panel(Rect2(1518, 92, 370, 760), Color("#08070def"), Color("#57485e"), "", "flat")
	hud.build_selected_room_info(right)
	if root.facility_change_panel_open:
		hud.build_facility_change_modal()

	var bottom = hud.panel(Rect2(98, 888, 1725, 124), Color("#100e14e8"), Color("#3b3143"), "", "flat")
	var build_label = "건설 취소" if root.build_pick_mode else "건설"
	var build_callback = Callable(root, "_build_selected_slot")
	if root.build_pick_mode and root.has_method("_build_preview_ready") and root._build_preview_ready():
		build_label = "건설 확정"
		build_callback = Callable(root, "_confirm_build_preview")
	var build_button = hud.button(bottom, build_label, Rect2(18, 20, 250, 86), build_callback, 20, "BuildButton")
	if root.build_pick_mode:
		build_button.add_theme_stylebox_override("normal", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 2))
	var monster_button = hud.button(bottom, "몬스터", Rect2(288, 20, 250, 86), Callable(root, "_open_monster_screen"), 20, "MonsterManagementButton")
	var start_button = hud.button(bottom, "전투 시작", Rect2(558, 20, 330, 86), Callable(root, "_start_combat"), 22, "StartCombatButton")
	var text_x := 930
	var guide_width := 300
	if root.has_method("_raid_unlocked") and root._raid_unlocked():
		hud.button(bottom, "원정", Rect2(908, 20, 210, 86), Callable(root, "_open_raid_screen"), 20, "RaidButton")
		text_x = 1150
		guide_width = 250
	hud.label(bottom, "준비 순서", Vector2(text_x, 18), Vector2(120, 24), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var guide_text = "시설을 고르고 배치한 뒤 몬스터 위치와 지침을 확인하고 전투를 시작합니다."
	var specialization_required := false
	if root.has_method("_raid_unlocked") and root._raid_unlocked():
		guide_text = "원정으로 악명과 다음 방어 영향을 만들고, 관리 화면에서 배치를 정비합니다."
	if root.has_method("_campaign_day_info"):
		var campaign_info: Dictionary = root._campaign_day_info()
		if not campaign_info.is_empty() and str(campaign_info.get("management_hint", "")) != "":
			guide_text = str(campaign_info.get("management_hint", ""))
	if root.has_method("_early_specialization_required_for_current_day") and root._early_specialization_required_for_current_day():
		specialization_required = true
		monster_button.text = "전술 특화"
		monster_button.add_theme_stylebox_override("normal", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 2))
		monster_button.add_theme_color_override("font_color", Color("#fff2c9"))
		start_button.text = "특화 후 전투"
		guide_text = "몬스터 메뉴에서 한 명의 전술 특화를 확정하면 전투를 시작할 수 있습니다."
	hud.label(bottom, guide_text, Vector2(text_x, 48), Vector2(guide_width, 44), 14 if guide_width < 300 else 15, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2)
	var helper = "몬스터는 맵 위에서 드래그\n또는 오른쪽 패널 이름 클릭"
	if root.map_editor_active:
		helper = "방에서 방으로 드래그\n연결된 길은 드래그로 해제"
	elif root._management_action_mode_active():
		if root.build_pick_mode and root.has_method("_build_preview_ready") and root._build_preview_ready():
			helper = "%s\n왼쪽에서 건설 확정\nESC 취소" % root._management_action_mode_title()
		else:
			helper = "%s\n맵에서 대상 클릭\nESC 취소" % root._management_action_mode_title()
	if not specialization_required:
		hud.label(bottom, helper, Vector2(1430, 12), Vector2(270, 96), 14, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_ARBITRARY, 4)

func _build_campaign_notice() -> void:
	if not root.has_method("_campaign_day_info"):
		return
	var info: Dictionary = root._campaign_day_info()
	if info.is_empty():
		return
	var notice = hud.panel(Rect2(346, 92, 1138, 112), Color("#0c0a11e8"), Color("#6e5630"), "", "flat")
	hud.label(notice, str(info.get("title", "DAY %d" % GameState.day)), Vector2(18, 12), Vector2(336, 24), 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(notice, str(info.get("summary", "")), Vector2(18, 42), Vector2(596, 48), 14, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	var cast_line = root._campaign_notice_cast_line() if root.has_method("_campaign_notice_cast_line") else ""
	var enemy_line = root._campaign_notice_enemy_line() if root.has_method("_campaign_notice_enemy_line") else ""
	var monster_line = root._campaign_notice_monster_line() if root.has_method("_campaign_notice_monster_line") else ""
	_build_campaign_cast_portraits(notice, info)
	hud.label(notice, cast_line, Vector2(844, 16), Vector2(258, 20), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 1)
	hud.label(notice, enemy_line, Vector2(844, 44), Vector2(258, 22), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 1)
	hud.label(notice, monster_line, Vector2(844, 70), Vector2(258, 20), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 1)

func _build_campaign_cast_portraits(parent: Control, info: Dictionary) -> void:
	if not root.has_method("_campaign_speaker_portrait_path"):
		return
	var cast: Array = info.get("cast", [])
	var portrait_x := 628
	for index in range(mini(cast.size(), 3)):
		var entry = cast[index]
		if not (entry is Dictionary):
			continue
		var character_id = str(entry.get("character_id", ""))
		var emotion = str(entry.get("emotion", ""))
		var portrait_path = root._campaign_speaker_portrait_path(character_id, emotion)
		if portrait_path == "":
			continue
		var accent = root._campaign_speaker_accent(character_id) if root.has_method("_campaign_speaker_accent") else Color("#57485e")
		var frame = hud.child_panel(parent, Rect2(portrait_x + index * 68, 14, 58, 58), Color("#130f19f0"), accent, 1)
		var portrait = hud.texture(frame, portrait_path, Rect2(4, 4, 50, 50))
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

func _build_layout_selector() -> void:
	var layout_ids: Array = DataRegistry.quarter_layout_ids()
	if layout_ids.is_empty():
		return
	var panel = hud.panel(Rect2(16, 530, 300, 342), Color("#08070def"), Color("#57485e"), "", "flat")
	hud.label(panel, "맵 커스텀", Vector2(0, 12), Vector2(300, 32), 24, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	if root.map_editor_active:
		_build_map_editor_controls(panel)
		return
	if root.build_pick_mode:
		hud.label(panel, "건설 모드", Vector2(18, 66), Vector2(264, 28), 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(panel, "맵 클릭은 후보 지정입니다.\n확정 전에는 비용을 쓰지 않습니다.", Vector2(18, 100), Vector2(264, 48), 13, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		var summary = root._build_preview_summary() if root.has_method("_build_preview_summary") else "맵에서 후보 방을 클릭하세요."
		var route_line = root._build_preview_route_line() if root.has_method("_build_preview_route_line") else ""
		var effect_line = root._build_preview_effect_line() if root.has_method("_build_preview_effect_line") else ""
		hud.label(panel, summary, Vector2(18, 158), Vector2(264, 24), 13, Color("#fff2c9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 1)
		hud.label(panel, route_line, Vector2(18, 188), Vector2(264, 38), 11, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		hud.label(panel, effect_line, Vector2(18, 230), Vector2(264, 38), 11, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		var confirm_button = hud.button(panel, "건설 확정", Rect2(18, 276, 126, 34), Callable(root, "_confirm_build_preview"), 13)
		confirm_button.disabled = not root._build_preview_ready()
		hud.button(panel, "취소", Rect2(156, 276, 126, 34), Callable(root, "_cancel_management_action_mode"), 13)
		hud.label(panel, "현재 선택  %s" % root.display_name_for_instance(root.selected_room), Vector2(18, 318), Vector2(264, 18), 10, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	if root._management_action_mode_active():
		hud.label(panel, root._management_action_mode_title(), Vector2(18, 54), Vector2(264, 28), 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(panel, root._management_action_mode_help(), Vector2(18, 94), Vector2(264, 96), 13, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 4)
		hud.label(panel, "선택 가능 대상은\n맵 위에 밝게 표시됩니다.", Vector2(18, 202), Vector2(264, 48), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
		hud.button(panel, "작업 취소", Rect2(18, 276, 264, 40), Callable(root, "_cancel_management_action_mode"), 15)
		return

	hud.label(panel, "길은 맵에서 직접 드래그합니다.\n방에서 방으로 끌면 연결,\n연결된 방끼리는 해제됩니다.", Vector2(18, 46), Vector2(264, 72), 12, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_ARBITRARY, 3)
	var y = 124
	var shown_count = mini(layout_ids.size(), 3)
	for index in range(shown_count):
		var layout_id = str(layout_ids[index])
		var layout: Dictionary = DataRegistry.quarter_layout(str(layout_id))
		var grade = str(layout.get("castle_grade", "?"))
		var label = str(layout.get("layout_label", ""))
		var display_name = str(layout.get("display_name", layout_id))
		var title_prefix = label if label != "" else "%s급" % grade
		var title = "%s  %s" % [title_prefix, display_name]
		var layout_button = hud.button(panel, title, Rect2(18, y, 264, 30), Callable(root, "_select_quarter_layout").bind(str(layout_id)), 12)
		if str(layout_id) == root.quarter_layout_id:
			layout_button.disabled = true
			layout_button.add_theme_stylebox_override("disabled", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 2))
			layout_button.add_theme_color_override("font_disabled_color", Color("#ffd36a"))
		y += 33
	if layout_ids.size() > shown_count:
		hud.label(panel, "+%d" % (layout_ids.size() - shown_count), Vector2(244, 54), Vector2(38, 24), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	var edit_button = hud.button(panel, "길 드래그 편집", Rect2(18, 244, 264, 52), Callable(root, "_open_map_editor"), 17, "MapEditButton")
	edit_button.add_theme_stylebox_override("normal", hud.style(Color("#271936f4"), Color("#ffd36a"), 2))
	edit_button.add_theme_color_override("font_color", Color("#fff2c9"))
	hud.label(panel, "현재 선택  %s" % root.display_name_for_instance(root.selected_room), Vector2(18, 304), Vector2(264, 22), 12, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

func _build_map_editor_controls(panel: Control) -> void:
	var room_name = root.display_name_for_instance(root.selected_room)
	hud.label(panel, "길 드래그 편집", Vector2(18, 44), Vector2(264, 28), 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(panel, "시작 방  %s" % room_name, Vector2(18, 74), Vector2(264, 22), 14, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(panel, "방에서 방으로 드래그하면 연결합니다.\n이미 이어진 방끼리 드래그하면 끊습니다.", Vector2(18, 100), Vector2(264, 54), 12, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	hud.label(panel, "추천  %s" % root._map_editor_path_candidate_line(), Vector2(18, 160), Vector2(264, 34), 10, Color("#cfc4dc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	hud.button(panel, "추천 자동 연결", Rect2(18, 202, 264, 34), Callable(root, "_map_editor_auto_connect_current_candidate"), 14)
	hud.button(panel, "선택 연결 해제", Rect2(18, 244, 126, 30), Callable(root, "_map_editor_disconnect_selected_room"), 12)
	hud.button(panel, "통로 삭제", Rect2(156, 244, 126, 30), Callable(root, "_map_editor_delete_selected_path"), 12)
	hud.button(panel, "저장", Rect2(18, 284, 126, 34), Callable(root, "_save_map_editor_layout"), 13)
	hud.button(panel, "취소", Rect2(156, 284, 126, 34), Callable(root, "_cancel_map_editor"), 13)
	hud.label(panel, root._map_editor_status_line(), Vector2(18, 320), Vector2(264, 20), 10, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)

func build_monster_ui() -> void:
	hud.build_top_bar()
	if root.has_method("_ensure_selected_monster_available_for_defense"):
		root._ensure_selected_monster_available_for_defense()
	var monster_ids: Array = root.monster_roster.keys()
	if root.has_method("_defense_monster_ids"):
		monster_ids = root._defense_monster_ids()
	var left = hud.panel(Rect2(24, 104, 400, 846), Color("#0b0a0fe8"), Color("#4c4354"), "", "flat")
	hud.label(left, "보유 몬스터", Vector2(24, 20), Vector2(352, 38), 25, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var y = 82
	for monster_id in monster_ids:
		var data = DataRegistry.monster(monster_id)
		var roster = root.monster_roster[monster_id]
		var scaled_stats = root._scaled_monster_stats(monster_id) if root.has_method("_scaled_monster_stats") else data
		var display_name = root._monster_display_name(monster_id) if root.has_method("_monster_display_name") else str(data.get("display_name", monster_id))
		var suffix = "  Lv.%d  HP %d" % [int(roster["level"]), int(scaled_stats.get("max_hp", 1))]
		var monster_button = hud.button(left, "%s%s" % [display_name, suffix], Rect2(24, y, 352, 58), Callable(root, "_select_monster").bind(monster_id), 17, _tutorial_monster_target_id(monster_id))
		if monster_id == root.selected_monster_id:
			monster_button.add_theme_stylebox_override("normal", hud.style(Color("#241b2eee"), Color("#a882c4"), 2))
			monster_button.add_theme_color_override("font_color", Color("#f0d8ff"))
		y += 70
	var support_line := ""
	if root.has_method("_support_only_monster_line"):
		support_line = root._support_only_monster_line()
	if support_line != "":
		hud.label(left, support_line, Vector2(24, min(y + 8, 660)), Vector2(352, 56), 14, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	hud.label(left, "배치는 관리 화면에서 변경합니다.", Vector2(24, 720), Vector2(352, 28), 14, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.button(left, "돌아가기", Rect2(92, 766, 216, 54), Callable(root, "_set_screen").bind(Constants.SCREEN_MANAGEMENT), 18)

	var center = hud.panel(Rect2(448, 104, 854, 846), Color("#0c0b10dc"), Color("#4c4354"), "", "flat")
	if root.selected_monster_id == "" or not root.monster_roster.has(root.selected_monster_id):
		hud.label(center, "배치 가능한 방어 몬스터가 없습니다.", Vector2(120, 360), Vector2(614, 60), 24, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	var monster = DataRegistry.monster(root.selected_monster_id)
	var selected_stats = root._scaled_monster_stats(root.selected_monster_id) if root.has_method("_scaled_monster_stats") else monster
	var roster: Dictionary = root.monster_roster[root.selected_monster_id]
	var selected_display_name = root._monster_display_name(root.selected_monster_id) if root.has_method("_monster_display_name") else str(monster.get("display_name", root.selected_monster_id))
	hud.label(center, selected_display_name, Vector2(36, 24), Vector2(782, 48), 34, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	hud.texture(center, monster.get("sprite", ""), Rect2(92, 116, 246, 246))
	var role_name = str(roster.get("role_tag", monster.get("role", "")))
	hud.label(center, "Lv.%d  ·  %s" % [int(roster["level"]), role_name], Vector2(58, 376), Vector2(314, 34), 22, Color("#d99bff"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(center, "배치 방  %s" % root.rooms[roster["room"]].get("display_name", roster["room"]), Vector2(58, 418), Vector2(314, 32), 18, Color("#d5cbe3"), HORIZONTAL_ALIGNMENT_CENTER)
	var stat_panel = hud.child_panel(center, Rect2(400, 112, 406, 300), Color("#100e14c8"), Color("#403846"), 1)
	hud.label(stat_panel, "전투 능력", Vector2(20, 12), Vector2(366, 30), 20, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.build_stat_lines(stat_panel, selected_stats, roster)
	hud.label(center, "전투에서 얻은 경험치로 성장하며 훈련은 즉시 능력치를 올립니다.", Vector2(74, 500), Vector2(706, 54), 17, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	hud.button(center, "훈련  금화 30", Rect2(72, 758, 220, 54), Callable(root, "_train_selected_monster"), 17)
	if root.has_method("_promotion_unlocked") and root._promotion_unlocked():
		_build_promotion_panel(center)

	var right = hud.panel(Rect2(1326, 104, 570, 846), Color("#0b0a0fe8"), Color("#4c4354"), "", "flat")
	hud.label(right, "스킬 슬롯", Vector2(24, 20), Vector2(522, 38), 25, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var skills: Array = monster.get("skill_slots", [])
	y = 78
	for skill_id in skills:
		var skill_panel = hud.child_panel(right, Rect2(24, y, 522, 104), Color("#100e14c8"), Color("#403846"), 1)
		if skill_id == null:
			hud.label(skill_panel, "잠금 슬롯", Vector2(18, 20), Vector2(486, 64), 18, Color("#7d7586"), HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var skill = DataRegistry.skill(str(skill_id))
			hud.label(skill_panel, skill.get("display_name", skill_id), Vector2(18, 10), Vector2(486, 28), 20, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
			hud.label(skill_panel, skill.get("description", ""), Vector2(18, 42), Vector2(486, 50), 14, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2, 11)
		y += 116
	_build_specialization_panel(right)

func _build_specialization_panel(right: Control) -> void:
	hud.label(right, "전술 특화", Vector2(28, 444), Vector2(180, 30), 19, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	if not root.has_method("_early_specialization_unlocked") or not root._early_specialization_unlocked():
		hud.label(right, "DAY 2에 해금됩니다.", Vector2(226, 444), Vector2(316, 30), 14, Color("#8f8799"), HORIZONTAL_ALIGNMENT_RIGHT)
		return
	var active_rule: Dictionary = root._monster_specialization(root.selected_monster_id)
	if not active_rule.is_empty():
		hud.label(right, "선택 확정됨", Vector2(226, 444), Vector2(316, 30), 13, Color("#be72ff"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)
		var active_panel = hud.child_panel(right, Rect2(28, 488, 514, 138), Color("#15101bd8"), Color("#78558f"), 1)
		hud.label(active_panel, str(active_rule.get("display_name", "특화 완료")), Vector2(18, 14), Vector2(478, 30), 19, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		hud.label(active_panel, str(active_rule.get("description", "")), Vector2(18, 50), Vector2(478, 72), 15, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 3)
		return
	var options = root._specializations_for_monster(root.selected_monster_id)
	var reason = root._specialization_block_reason(root.selected_monster_id)
	var status = "선택 후 변경 불가"
	if reason != "":
		status = reason
	hud.label(right, status, Vector2(226, 444), Vector2(316, 30), 13, Color("#a99fba"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_BODY)
	var y := 490
	for option in options:
		var specialization_id = str(option.get("id", ""))
		var option_text = "%s  |  %s" % [str(option.get("display_name", specialization_id)), str(option.get("short_effect", ""))]
		var option_button = hud.button(right, option_text, Rect2(28, y, 514, 54), Callable(root, "_choose_early_specialization").bind(root.selected_monster_id, specialization_id), 14)
		option_button.disabled = not root._can_choose_early_specialization(root.selected_monster_id, specialization_id)
		option_button.tooltip_text = str(option.get("description", ""))
		y += 64

func _build_promotion_panel(center: Control) -> void:
	var icon_path = root._selected_promotion_icon() if root.has_method("_selected_promotion_icon") else ""
	if icon_path != "":
		var icon_frame = hud.child_panel(center, Rect2(592, 610, 52, 52), Color("#17121df0"), Color("#6e5630"), 1)
		hud.texture(icon_frame, icon_path, Rect2(5, 5, 42, 42))
	var summary = root._selected_promotion_summary() if root.has_method("_selected_promotion_summary") else "승급 후보를 확인하세요."
	hud.label(center, summary, Vector2(150, 608), Vector2(420, 54), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	var button_text = root._selected_promotion_button_text() if root.has_method("_selected_promotion_button_text") else "승급"
	var promote_button = hud.button(center, button_text, Rect2(410, 686, 220, 54), Callable(root, "_promote_selected_monster"), 13, "PromotionButton")
	promote_button.disabled = not root._can_promote_selected_monster()
	if promote_button.disabled:
		promote_button.add_theme_color_override("font_disabled_color", Color("#a99fba"))

func build_result_ui() -> void:
	hud.build_top_bar()
	var title = "방어 성공" if root.result_summary.get("win", false) else "방어 실패"
	if GameState.victory:
		title = "데모 클리어"
	var title_rect = root._onboarding_rect("S05_RESULT", "ResultTitle", Rect2(560, 100, 800, 80)) if root.has_method("_onboarding_rect") else Rect2(560, 100, 800, 80)
	var reward_rect = root._onboarding_rect("S05_RESULT", "RewardPanel", Rect2(300, 220, 600, 520)) if root.has_method("_onboarding_rect") else Rect2(300, 220, 600, 520)
	var comment_rect = root._onboarding_rect("S05_RESULT", "CommentPanel", Rect2(940, 220, 680, 520)) if root.has_method("_onboarding_rect") else Rect2(940, 220, 680, 520)
	var button_rect = root._onboarding_rect("S05_RESULT", "NextDayButton", Rect2(760, 820, 400, 72)) if root.has_method("_onboarding_rect") else Rect2(760, 820, 400, 72)
	var result_screen = hud.panel(Rect2(0, 0, 1920, 1080), Color("#00000000"), Color("#00000000"))
	hud.label(result_screen, title, title_rect.position, title_rect.size, 46, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	var reward_panel = hud.panel(reward_rect, Color("#0d0b12f2"), Color("#80662f"), "", "flat")
	var comment_panel = hud.panel(comment_rect, Color("#0d0c11e8"), Color("#4c4354"), "", "flat")
	hud.label(reward_panel, "전투 결산", Vector2(28, 22), Vector2(reward_rect.size.x - 56, 42), 27, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var reward_content_x: float = 28.0
	var reward_content_width: float = reward_rect.size.x - reward_content_x * 2.0
	var result_lines: Array = root.result_summary.get("lines", [])
	var available_height = reward_rect.size.y - 98.0
	var line_gap = clampf(available_height / float(maxi(1, result_lines.size())), 30.0, 48.0)
	var y = 76.0
	for line in result_lines:
		var line_text = str(line)
		var is_facility_line = line_text.begins_with("시설 기여")
		var font_size = 16 if is_facility_line else 19
		var line_height = maxf(28.0, line_gap - 2.0)
		hud.label(
			reward_panel,
			line_text,
			Vector2(reward_content_x, y),
			Vector2(reward_content_width, line_height),
			font_size,
			Color("#ffd36a") if is_facility_line else Color("#d8d1df"),
			HORIZONTAL_ALIGNMENT_CENTER,
			"",
			UIFontScript.ROLE_BODY,
			VERTICAL_ALIGNMENT_CENTER,
			TextServer.AUTOWRAP_WORD_SMART,
			2,
			13
		)
		y += line_gap
	hud.label(comment_panel, "다음 진행", Vector2(42, 24), Vector2(comment_rect.size.x - 84, 42), 27, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var next_copy = "결산 확인 후 다음 단계로 진행합니다.\nDAY 03 승리 이후에는 DAY 04 악명 원정 예고 화면으로 이어집니다."
	if not GameState.victory and not GameState.defeat and GameState.day >= 4:
		next_copy = "결산 확인 후 다음 날 관리 화면으로 진행합니다.\n원정과 방어 결과가 이어지는 정규 캠페인 구간입니다."
	hud.label(comment_panel, next_copy, Vector2(42, 82), Vector2(comment_rect.size.x - 84, 112), 20, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3, 14)
	hud.label(comment_panel, "몬스터 성장", Vector2(42, 214), Vector2(comment_rect.size.x - 84, 34), 22, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var growth_y := 256
	var growth_lines = root._result_growth_lines() if root.has_method("_result_growth_lines") else []
	for line in growth_lines:
		hud.label(comment_panel, str(line), Vector2(48, growth_y), Vector2(comment_rect.size.x - 96, 28), 18, Color("#d8d1df"))
		growth_y += 34
	_build_growth_reward_panel(comment_panel, comment_rect)
	var growth_button_rect = Rect2(comment_rect.position + Vector2(comment_rect.size.x - 274, comment_rect.size.y - 86), Vector2(230, 58))
	var growth_button = hud.button(comment_panel, "성장 확인", Rect2(growth_button_rect.position - comment_rect.position, growth_button_rect.size), Callable(root, "_review_growth_from_result"), 18, "GrowthReviewButton")
	growth_button.text = "성장 확인"
	var growth_choice_pending = root.has_method("_result_growth_choice_required") and root._result_growth_choice_required() and not root.result_growth_choice_applied
	if root.result_growth_reviewed:
		growth_button.disabled = true
		growth_button.text = "확인 완료"
	elif growth_choice_pending:
		growth_button.disabled = true
		growth_button.text = "성장 선택 필요"
	var growth_review_required := false
	if root.onboarding_enabled and root.tutorial_gate_enabled and root.tutorial_manager.is_active_for_stage(root.onboarding_stage_id):
		growth_review_required = root.tutorial_manager.expected_action() == "growth_reviewed"
	var next_button: Button
	if GameState.victory or GameState.defeat:
		next_button = hud.button(result_screen, "관리 화면으로", button_rect, Callable(root, "_continue_from_result"), 19, "NextDayButton")
	else:
		next_button = hud.button(result_screen, "다음 날 진행", button_rect, Callable(root, "_continue_from_result"), 19, "NextDayButton")
	if growth_review_required:
		next_button.disabled = true
		next_button.text = "성장 확인 필요"
	elif growth_choice_pending:
		next_button.disabled = true
		next_button.text = "성장 선택 필요"

func _build_growth_reward_panel(comment_panel: Control, comment_rect: Rect2) -> void:
	var overlay = hud.child_panel(comment_panel, Rect2(Vector2.ZERO, comment_rect.size), Color("#111016f6"), Color("#9b6a27"), 2)
	hud.label(overlay, "몬스터 성장", Vector2(0, 24), Vector2(comment_rect.size.x, 40), 27, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var caption = "공유 EXP + 개별 활약 EXP"
	if root.has_method("_result_growth_choice_required") and root._result_growth_choice_required():
		caption = "공유 EXP + 개별 활약 EXP · 집중 성장 1명 선택"
	if root.result_growth_reviewed:
		caption = "성장 확인 완료 · 공유 EXP + 개별 활약 EXP"
	elif root.result_growth_choice_applied:
		caption = "%s 집중 성장 +%d EXP" % [str(root.last_growth_choice_summary.get("display_name", "선택 몬스터")), int(root.last_growth_choice_summary.get("bonus_exp", 0))]
	hud.label(overlay, caption, Vector2(48, 70), Vector2(comment_rect.size.x - 96, 24), 15, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

	var rows: Array = root.last_growth_summary
	if rows.is_empty():
		hud.label(overlay, "이번 전투 성장 기록이 없습니다.", Vector2(48, 180), Vector2(comment_rect.size.x - 96, 40), 21, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER)
	else:
		var shown_count = mini(rows.size(), 3)
		for index in range(shown_count):
			_build_growth_card(overlay, rows[index], Vector2(36, 112 + index * 108), comment_rect.size.x - 72)
		if rows.size() > shown_count:
			hud.label(overlay, "+%d명 더 성장" % (rows.size() - shown_count), Vector2(48, 440), Vector2(comment_rect.size.x - 96, 24), 14, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

	var review_instruction = "한 명에게 집중 성장을 준 뒤 성장 확인을 누르세요."
	if root.result_growth_choice_applied:
		review_instruction = "집중 성장이 반영되었습니다. EXP 바를 확인한 뒤 성장 확인을 누르세요."
	if root.result_growth_reviewed:
		review_instruction = "성장 반영을 확인했습니다. 다음 날 진행할 수 있습니다."
	hud.label(overlay, review_instruction, Vector2(42, comment_rect.size.y - 74), Vector2(comment_rect.size.x - 340, 44), 15, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)

func _build_growth_card(parent: Control, row: Dictionary, position: Vector2, width: float) -> void:
	var activity_exp = int(row.get("activity_exp", 0))
	var card_border = Color("#6e5630") if activity_exp > 0 else Color("#403448")
	var card = hud.child_panel(parent, Rect2(position, Vector2(width, 100)), Color("#17121df0"), card_border, 1)
	var name = str(row.get("display_name", row.get("monster_id", "")))
	var level_before = int(row.get("level_before", row.get("level_after", 1)))
	var level_after = int(row.get("level_after", 1))
	var levels_gained = int(row.get("levels_gained", max(0, level_after - level_before)))
	var exp_gain = int(row.get("exp_gain", 0))
	var shared_exp = int(row.get("shared_exp", max(0, exp_gain - activity_exp)))
	var activity_breakdown: Dictionary = row.get("activity_breakdown", {})
	var exp_after = int(row.get("exp_after", 0))
	var next_exp = max(1, int(row.get("next_exp", 50)))
	var progress = clamp(float(exp_after) / float(next_exp), 0.0, 1.0)
	var level_text = "Lv.%d" % level_after
	if levels_gained > 0:
		level_text = "Lv.%d -> Lv.%d" % [level_before, level_after]
	var choice_required = root.has_method("_result_growth_choice_required") and root._result_growth_choice_required()

	hud.label(card, name, Vector2(18, 8), Vector2(180, 28), 21, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(card, level_text, Vector2(18, 38), Vector2(130, 24), 16, Color("#d99bff"))
	hud.label(card, "EXP +%d" % exp_gain, Vector2(width - 130, 10), Vector2(104, 24), 17, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)
	var bar_x := 176.0
	var bar_width = max(80.0, width - (360.0 if choice_required else 232.0))
	hud.child_panel(card, Rect2(bar_x, 43, bar_width, 12), Color("#24192d"), Color("#3b3143"), 1)
	hud.child_panel(card, Rect2(bar_x, 43, bar_width * progress, 12), Color("#ffd36a"), Color("#ffd36a"), 0)
	var exp_text = "%d / %d" % [exp_after, next_exp]
	if levels_gained > 0:
		exp_text = "LEVEL UP  %s" % exp_text
	hud.label(card, exp_text, Vector2(bar_x, 56), Vector2(bar_width, 18), 12, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_RIGHT)
	hud.label(card, "공유 +%d · 활약 +%d" % [shared_exp, activity_exp], Vector2(18, 72), Vector2(182, 20), 13, Color("#ffd36a") if activity_exp > 0 else Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var activity_parts: Array[String] = []
	var activity_labels = {
		"attack": "공격",
		"defense": "흡수",
		"finisher": "마무리",
		"facility": "시설"
	}
	for key in ["attack", "defense", "finisher", "facility"]:
		var value = int(activity_breakdown.get(key, 0))
		if value > 0:
			activity_parts.append("%s +%d" % [activity_labels[key], value])
	if activity_parts.is_empty():
		activity_parts.append("활약 보너스 없음")
	var activity_width = width - 360 if choice_required else width - 232
	hud.label(card, " / ".join(activity_parts), Vector2(206, 72), Vector2(activity_width, 20), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_RIGHT)
	if choice_required:
		var monster_id = str(row.get("monster_id", ""))
		var bonus = root._result_growth_choice_bonus() if root.has_method("_result_growth_choice_bonus") else 0
		var preview_text := _growth_choice_preview_text(row, bonus)
		if preview_text != "":
			hud.label(card, preview_text, Vector2(width - 156, 38), Vector2(134, 18), 12, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_RIGHT)
		var choice_button = hud.button(card, "집중 +%d" % bonus, Rect2(width - 126, 62, 104, 28), Callable(root, "_choose_result_growth").bind(monster_id), 12, "GrowthChoice_%s" % monster_id)
		if root.result_growth_choice_applied:
			choice_button.disabled = true
			if str(root.result_growth_choice_monster_id) == monster_id:
				choice_button.text = "선택됨"

func _growth_choice_preview_text(row: Dictionary, bonus: int) -> String:
	if bonus <= 0:
		return ""
	var level: int = int(row.get("level_after", 1))
	var exp: int = int(row.get("exp_after", 0)) + bonus
	var next_exp: int = maxi(1, int(row.get("next_exp", 50)))
	var gained: int = 0
	var guard: int = 0
	while exp >= next_exp and guard < 20:
		exp -= next_exp
		level += 1
		gained += 1
		guard += 1
		if root.has_method("_monster_exp_to_next"):
			next_exp = maxi(1, int(root.call("_monster_exp_to_next", level)))
		else:
			next_exp = 50 + maxi(0, level - 1) * 30
	if gained > 0:
		return "선택 시 Lv.%d" % level
	return "선택 후 %d/%d" % [exp, next_exp]

func _tutorial_monster_target_id(monster_id: String) -> String:
	match monster_id:
		"slime":
			return "CHR_PUDDING"
		"goblin":
			return "CHR_GOB"
		"imp":
			return "CHR_PYNN"
		"kobold_scout":
			return "CHR_ROLO"
		_:
			return ""
