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
	var build_button = hud.button(bottom, build_label, Rect2(18, 20, 250, 86), Callable(root, "_build_selected_slot"), 20, "BuildButton")
	if root.build_pick_mode:
		build_button.add_theme_stylebox_override("normal", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 2))
	hud.button(bottom, "몬스터", Rect2(288, 20, 250, 86), Callable(root, "_open_monster_screen"), 20, "MonsterManagementButton")
	hud.button(bottom, "전투 시작", Rect2(558, 20, 330, 86), Callable(root, "_start_combat"), 22, "StartCombatButton")
	var text_x := 930
	if root.has_method("_raid_unlocked") and root._raid_unlocked():
		hud.button(bottom, "원정", Rect2(908, 20, 210, 86), Callable(root, "_open_raid_screen"), 20, "RaidButton")
		text_x = 1150
	hud.label(bottom, "준비 순서", Vector2(text_x, 18), Vector2(120, 24), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var guide_text = "시설을 고르고 배치한 뒤 몬스터 위치와 지침을 확인하고 전투를 시작합니다."
	if root.has_method("_raid_unlocked") and root._raid_unlocked():
		guide_text = "원정으로 악명과 다음 방어 영향을 만들고, 관리 화면에서 배치를 정비합니다."
	if root.has_method("_campaign_day_info"):
		var campaign_info: Dictionary = root._campaign_day_info()
		if not campaign_info.is_empty() and str(campaign_info.get("management_hint", "")) != "":
			guide_text = str(campaign_info.get("management_hint", ""))
	hud.label(bottom, guide_text, Vector2(text_x, 48), Vector2(300, 44), 15, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2)
	var helper = "몬스터는 맵 위에서 드래그\n또는 오른쪽 패널 이름 클릭"
	if root.map_editor_active:
		helper = "방에서 방으로 드래그\n연결된 길은 드래그로 해제"
	elif root._management_action_mode_active():
		helper = "%s\n맵에서 대상 클릭\nESC 취소" % root._management_action_mode_title()
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
		hud.label(panel, "시설 적용 위치를 먼저 고르세요.\n길 편집은 건설을 마친 뒤 사용할 수 있습니다.", Vector2(18, 112), Vector2(264, 74), 13, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3)
		var disabled_edit = hud.button(panel, "길 편집 잠금", Rect2(18, 244, 264, 52), Callable(root, "_log").bind("건설을 취소하거나 완료한 뒤 길을 편집하세요."), 17)
		disabled_edit.disabled = true
		hud.label(panel, "현재 선택  %s" % root.display_name_for_instance(root.selected_room), Vector2(18, 304), Vector2(264, 22), 12, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
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
	var left = hud.panel(Rect2(24, 118, 520, 820), Color("#0f0f14e8"))
	hud.label(left, "보유 몬스터", Vector2(24, 18), Vector2(460, 36), 27, Color("#f4e7d2"))
	var y = 116
	var left_title = left.get_child(left.get_child_count() - 1) as Label
	if left_title != null:
		left_title.position = Vector2(0, 62)
		left_title.size = Vector2(520, 34)
		left_title.text = "보유 몬스터"
		left_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		left_title.add_theme_font_size_override("font_size", 25)
	for monster_id in monster_ids:
		var data = DataRegistry.monster(monster_id)
		var roster = root.monster_roster[monster_id]
		var scaled_stats = root._scaled_monster_stats(monster_id) if root.has_method("_scaled_monster_stats") else data
		var display_name = root._monster_display_name(monster_id) if root.has_method("_monster_display_name") else str(data.get("display_name", monster_id))
		var suffix = "  Lv.%d  HP %d" % [int(roster["level"]), int(scaled_stats.get("max_hp", 1))]
		var monster_button = hud.button(left, "%s%s" % [display_name, suffix], Rect2(54, y, 412, 64), Callable(root, "_select_monster").bind(monster_id), 18, _tutorial_monster_target_id(monster_id))
		if monster_id == root.selected_monster_id:
			monster_button.add_theme_color_override("font_color", Color("#d99bff"))
		y += 82
	var support_line := ""
	if root.has_method("_support_only_monster_line"):
		support_line = root._support_only_monster_line()
	if support_line != "":
		hud.label(left, support_line, Vector2(54, min(y, 560)), Vector2(412, 56), 14, Color("#a99fba"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	hud.button(left, "돌아가기", Rect2(24, 714, 220, 72), Callable(root, "_set_screen").bind(Constants.SCREEN_MANAGEMENT), 19)
	hud.label(left, "배치는 관리 화면에서 몬스터를 누른 뒤 방을 클릭하거나 드래그합니다.", Vector2(264, 706), Vector2(220, 88), 15, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 3)
	var left_helper = left.get_child(left.get_child_count() - 1) as Label
	var back_button = left.get_child(left.get_child_count() - 2) as Button
	if back_button != null:
		back_button.position = Vector2(60, 640)
		back_button.size = Vector2(188, 58)
		back_button.text = "돌아가기"
		back_button.add_theme_font_size_override("font_size", 18)
	if left_helper != null:
		left_helper.visible = false
		left_helper.add_theme_font_size_override("font_size", 14)

	var center = hud.panel(Rect2(590, 130, 780, 800), Color("#111016cc"))
	if root.selected_monster_id == "" or not root.monster_roster.has(root.selected_monster_id):
		hud.label(center, "배치 가능한 방어 몬스터가 없습니다.", Vector2(120, 360), Vector2(540, 60), 24, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	var monster = DataRegistry.monster(root.selected_monster_id)
	var selected_stats = root._scaled_monster_stats(root.selected_monster_id) if root.has_method("_scaled_monster_stats") else monster
	var roster: Dictionary = root.monster_roster[root.selected_monster_id]
	var selected_display_name = root._monster_display_name(root.selected_monster_id) if root.has_method("_monster_display_name") else str(monster.get("display_name", root.selected_monster_id))
	hud.label(center, selected_display_name, Vector2(220, 66), Vector2(340, 46), 34, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.texture(center, monster.get("sprite", ""), Rect2(294, 136, 192, 192))
	var role_name = str(roster.get("role_tag", monster.get("role", "")))
	hud.label(center, "Lv.%d / %s" % [int(roster["level"]), role_name], Vector2(230, 334), Vector2(320, 34), 23, Color("#be72ff"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(center, "배치 방: %s" % root.rooms[roster["room"]].get("display_name", roster["room"]), Vector2(220, 376), Vector2(340, 34), 21, Color("#d5cbe3"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.build_stat_lines(center, selected_stats, roster)
	hud.button(center, "훈련  금화 30", Rect2(265, 680, 250, 72), Callable(root, "_train_selected_monster"), 19)
	hud.label(center, "관리 화면에서 이 몬스터를 고르고 방을 클릭하면 배치됩니다.", Vector2(170, 756), Vector2(440, 32), 16, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	var center_helper = center.get_child(center.get_child_count() - 1) as Label
	var train_button = center.get_child(center.get_child_count() - 2) as Button
	if train_button != null:
		train_button.position = Vector2(150, 686)
		train_button.size = Vector2(220, 54)
		train_button.text = "훈련  금화 30"
		train_button.add_theme_font_size_override("font_size", 16)
	if center_helper != null:
		center_helper.visible = false
	if root.has_method("_promotion_unlocked") and root._promotion_unlocked():
		_build_promotion_panel(center)

	var right = hud.panel(Rect2(1410, 130, 420, 800), Color("#0f0e13e8"))
	hud.label(right, "스킬 슬롯", Vector2(24, 24), Vector2(360, 36), 27, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	var right_title = right.get_child(right.get_child_count() - 1) as Label
	if right_title != null:
		right_title.position = Vector2(92, 118)
		right_title.size = Vector2(236, 30)
		right_title.text = "스킬 슬롯"
		right_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_title.add_theme_font_size_override("font_size", 22)
	var skills: Array = monster.get("skill_slots", [])
	y = 170
	for skill_id in skills:
		if skill_id == null:
			hud.label(right, "잠금 슬롯", Vector2(92, y), Vector2(236, 54), 18, Color("#7d7586"), HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var skill = DataRegistry.skill(str(skill_id))
			hud.label(right, skill.get("display_name", skill_id), Vector2(92, y), Vector2(236, 28), 21, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT)
			hud.label(right, skill.get("description", ""), Vector2(92, y + 32), Vector2(236, 54), 14, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2)
		y += 128
	hud.label(right, "레벨업 후보 선택 UI는 검수 후 확장 대상입니다.", Vector2(28, 690), Vector2(360, 70), 17, Color("#9d90ac"))

	var skill_helper = right.get_child(right.get_child_count() - 1) as Label
	if skill_helper != null:
		skill_helper.visible = false

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
	var reward_panel = hud.panel(reward_rect, Color("#100d14f2"), Color("#9b6a27"))
	var comment_panel = hud.panel(comment_rect, Color("#111016dd"), Color("#57485e"))
	hud.label(reward_panel, "전투 결산", Vector2(0, 92), Vector2(reward_rect.size.x, 40), 26, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER)
	var reward_content_x: float = 128.0
	var reward_content_width: float = reward_rect.size.x - reward_content_x * 2.0
	var result_lines: Array = root.result_summary.get("lines", [])
	var compact_lines = result_lines.size() >= 7
	var y = 146 if compact_lines else 152
	for line in result_lines:
		var line_text = str(line)
		var is_facility_line = line_text.begins_with("시설 기여")
		var font_size = 16 if is_facility_line else (19 if compact_lines else 22)
		var line_height = 42 if is_facility_line else 32
		var line_gap = 42 if is_facility_line else (36 if compact_lines else 42)
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
			2 if is_facility_line else 1
		)
		y += line_gap
	hud.label(comment_panel, "다음 진행", Vector2(0, 26), Vector2(comment_rect.size.x, 42), 27, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	var next_copy = "결산 확인 후 다음 단계로 진행합니다.\nDAY 03 승리 이후에는 DAY 04 악명 원정 예고 화면으로 이어집니다."
	if not GameState.victory and not GameState.defeat and GameState.day >= 4:
		next_copy = "결산 확인 후 다음 날 관리 화면으로 진행합니다.\n원정과 방어 결과가 이어지는 정규 캠페인 구간입니다."
	hud.label(comment_panel, next_copy, Vector2(48, 112), Vector2(comment_rect.size.x - 96, 160), 22, Color("#d8d1df"))
	hud.label(comment_panel, "몬스터 성장", Vector2(48, 284), Vector2(comment_rect.size.x - 96, 34), 23, Color("#ffd36a"))
	var growth_y := 326
	var growth_lines = root._result_growth_lines() if root.has_method("_result_growth_lines") else []
	for line in growth_lines:
		hud.label(comment_panel, str(line), Vector2(48, growth_y), Vector2(comment_rect.size.x - 96, 28), 18, Color("#d8d1df"))
		growth_y += 34
	_build_growth_reward_panel(comment_panel, comment_rect)
	var growth_button_rect = Rect2(comment_rect.position + Vector2(comment_rect.size.x - 274, comment_rect.size.y - 86), Vector2(230, 58))
	var growth_button = hud.button(comment_panel, "성장 확인", Rect2(growth_button_rect.position - comment_rect.position, growth_button_rect.size), Callable(root, "_review_growth_from_result"), 18, "GrowthReviewButton")
	growth_button.text = "성장 확인"
	if root.result_growth_reviewed:
		growth_button.disabled = true
		growth_button.text = "확인 완료"
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

func _build_growth_reward_panel(comment_panel: Control, comment_rect: Rect2) -> void:
	var overlay = hud.child_panel(comment_panel, Rect2(Vector2.ZERO, comment_rect.size), Color("#111016f6"), Color("#9b6a27"), 2)
	hud.label(overlay, "몬스터 성장", Vector2(0, 24), Vector2(comment_rect.size.x, 40), 27, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var caption = "성장 확인으로 다음 날 진행을 해금합니다."
	if root.result_growth_reviewed:
		caption = "성장 확인 완료"
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

	hud.label(overlay, "EXP 바를 확인한 뒤 성장 확인을 누르세요.", Vector2(42, comment_rect.size.y - 74), Vector2(comment_rect.size.x - 340, 44), 15, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)

func _build_growth_card(parent: Control, row: Dictionary, position: Vector2, width: float) -> void:
	var card = hud.child_panel(parent, Rect2(position, Vector2(width, 92)), Color("#17121df0"), Color("#403448"), 1)
	var name = str(row.get("display_name", row.get("monster_id", "")))
	var level_before = int(row.get("level_before", row.get("level_after", 1)))
	var level_after = int(row.get("level_after", 1))
	var levels_gained = int(row.get("levels_gained", max(0, level_after - level_before)))
	var exp_gain = int(row.get("exp_gain", 0))
	var exp_after = int(row.get("exp_after", 0))
	var next_exp = max(1, int(row.get("next_exp", 50)))
	var progress = clamp(float(exp_after) / float(next_exp), 0.0, 1.0)
	var level_text = "Lv.%d" % level_after
	if levels_gained > 0:
		level_text = "Lv.%d -> Lv.%d" % [level_before, level_after]

	hud.label(card, name, Vector2(18, 12), Vector2(180, 28), 21, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	hud.label(card, level_text, Vector2(18, 46), Vector2(130, 24), 16, Color("#d99bff"))
	hud.label(card, "EXP +%d" % exp_gain, Vector2(width - 130, 14), Vector2(104, 24), 17, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)
	var bar_x := 176.0
	var bar_width = max(80.0, width - 232.0)
	hud.child_panel(card, Rect2(bar_x, 54, bar_width, 12), Color("#24192d"), Color("#3b3143"), 1)
	hud.child_panel(card, Rect2(bar_x, 54, bar_width * progress, 12), Color("#ffd36a"), Color("#ffd36a"), 0)
	var exp_text = "%d / %d" % [exp_after, next_exp]
	if levels_gained > 0:
		exp_text = "LEVEL UP  %s" % exp_text
	hud.label(card, exp_text, Vector2(bar_x, 66), Vector2(bar_width, 20), 12, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_RIGHT)

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
