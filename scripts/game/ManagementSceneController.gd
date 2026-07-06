extends RefCounted
class_name ManagementSceneController

const Constants = preload("res://scripts/core/Constants.gd")

var root: Node
var hud

func setup(game_root: Node, hud_controller) -> void:
	root = game_root
	hud = hud_controller

func build_management_ui() -> void:
	hud.build_top_bar()
	hud.build_room_list(16, 92, 300, 420)
	_build_layout_selector()
	var right = hud.panel(Rect2(1518, 92, 370, 760), Color("#111016dd"))
	hud.label(right, "선택 방", Vector2(24, 22), Vector2(320, 32), 27, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.build_selected_room_info(right)

	var bottom = hud.panel(Rect2(98, 880, 1725, 142), Color("#100e14e8"))
	hud.button(bottom, "건설", Rect2(18, 20, 250, 86), Callable(root, "_build_selected_slot"), 20, "BuildButton")
	hud.button(bottom, "몬스터 관리", Rect2(288, 20, 250, 86), Callable(root, "_open_monster_screen"), 20, "MonsterManagementButton")
	hud.button(bottom, "침공 작전", Rect2(558, 20, 250, 86), Callable(root, "_log").bind("침공 작전은 데모에서 비활성화되어 있습니다."), 20)
	hud.button(bottom, "방어 준비", Rect2(828, 20, 300, 86), Callable(root, "_start_combat"), 20, "StartCombatButton")
	hud.button(bottom, "다음 날", Rect2(1148, 20, 260, 86), Callable(root, "_advance_day_from_management"), 20, "NextDayButton")
	hud.label(bottom, "몬스터를 잡아 원하는 방에 놓으면 바로 배치됩니다.", Vector2(1430, 18), Vector2(270, 88), 16, Color("#bfb7cc"))

func _build_layout_selector() -> void:
	var layout_ids: Array = DataRegistry.quarter_layout_ids()
	if layout_ids.is_empty():
		return
	var panel = hud.panel(Rect2(16, 530, 300, 318), Color("#0e0d12e8"))
	hud.label(panel, "맵 커스텀", Vector2(0, 12), Vector2(300, 32), 24, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	if root.map_editor_active:
		_build_map_editor_controls(panel)
		return
	hud.label(panel, "초보던전은 28x26 활성 영역과 2칸 길 간격을 사용합니다.", Vector2(18, 48), Vector2(264, 42), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	var y = 96
	var shown_count = mini(layout_ids.size(), 4)
	for index in range(shown_count):
		var layout_id = str(layout_ids[index])
		var layout: Dictionary = DataRegistry.quarter_layout(str(layout_id))
		var grade = str(layout.get("castle_grade", "?"))
		var label = str(layout.get("layout_label", ""))
		var display_name = str(layout.get("display_name", layout_id))
		var title_prefix = label if label != "" else "%s급" % grade
		var title = "%s  %s" % [title_prefix, display_name]
		var layout_button = hud.button(panel, title, Rect2(18, y, 264, 34), Callable(root, "_select_quarter_layout").bind(str(layout_id)), 13)
		if str(layout_id) == root.quarter_layout_id:
			layout_button.disabled = true
			layout_button.add_theme_stylebox_override("disabled", hud.style(Color("#2b2340ee"), Color("#ffd36a"), 2))
			layout_button.add_theme_color_override("font_disabled_color", Color("#ffd36a"))
		y += 38
	if layout_ids.size() > shown_count:
		hud.label(panel, "+%d" % (layout_ids.size() - shown_count), Vector2(244, 54), Vector2(38, 24), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.button(panel, "편집", Rect2(18, 246, 126, 44), Callable(root, "_open_map_editor"), 16)
	hud.label(panel, "선택 방: %s" % root.rooms.get(root.selected_room, {}).get("display_name", root.selected_room), Vector2(154, 246), Vector2(128, 44), 14, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

func _build_map_editor_controls(panel: Control) -> void:
	var room_name = root.rooms.get(root.selected_room, {}).get("display_name", root.selected_room)
	hud.label(panel, "편집 방: %s" % room_name, Vector2(18, 48), Vector2(264, 28), 16, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(panel, "원점 %s" % root._map_editor_selected_origin_label(), Vector2(18, 72), Vector2(264, 22), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.button(panel, "상", Rect2(117, 98, 66, 30), Callable(root, "_move_map_editor_room").bind(Vector2i(0, -1)), 14)
	hud.button(panel, "좌", Rect2(45, 132, 66, 30), Callable(root, "_move_map_editor_room").bind(Vector2i(-1, 0)), 14)
	hud.button(panel, "우", Rect2(189, 132, 66, 30), Callable(root, "_move_map_editor_room").bind(Vector2i(1, 0)), 14)
	hud.button(panel, "하", Rect2(117, 166, 66, 30), Callable(root, "_move_map_editor_room").bind(Vector2i(0, 1)), 14)
	hud.button(panel, "연결 해제", Rect2(18, 204, 126, 34), Callable(root, "_map_editor_disconnect_selected_room"), 14)
	hud.button(panel, "인접 연결", Rect2(156, 204, 126, 34), Callable(root, "_map_editor_connect_adjacent_socket"), 14)
	hud.button(panel, "저장", Rect2(18, 246, 126, 36), Callable(root, "_save_map_editor_layout"), 15)
	hud.button(panel, "취소", Rect2(156, 246, 126, 36), Callable(root, "_cancel_map_editor"), 15)
	hud.label(panel, root._map_editor_status_line(), Vector2(18, 284), Vector2(264, 24), 12, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

func build_monster_ui() -> void:
	hud.build_top_bar()
	var left = hud.panel(Rect2(24, 118, 520, 820), Color("#0f0f14e8"))
	hud.label(left, "보유 몬스터", Vector2(24, 18), Vector2(460, 36), 27, Color("#f4e7d2"))
	var y = 78
	for monster_id in root.monster_roster.keys():
		var data = DataRegistry.monster(monster_id)
		var roster = root.monster_roster[monster_id]
		var suffix = "  Lv.%d  HP %d" % [int(roster["level"]), int(data.get("max_hp", 1)) + (int(roster["level"]) - 1) * 20]
		var monster_button = hud.button(left, "%s%s" % [data.get("display_name", monster_id), suffix], Rect2(24, y, 460, 76), Callable(root, "_select_monster").bind(monster_id), 19, _tutorial_monster_target_id(monster_id))
		if monster_id == root.selected_monster_id:
			monster_button.add_theme_color_override("font_color", Color("#d99bff"))
		y += 90
	hud.button(left, "돌아가기", Rect2(24, 714, 220, 72), Callable(root, "_set_screen").bind(Constants.SCREEN_MANAGEMENT), 19)
	hud.label(left, "배치는 관리 화면에서 몬스터를 방으로 드래그합니다.", Vector2(264, 706), Vector2(220, 88), 15, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

	var center = hud.panel(Rect2(590, 130, 780, 800), Color("#111016cc"))
	var monster = DataRegistry.monster(root.selected_monster_id)
	var roster: Dictionary = root.monster_roster[root.selected_monster_id]
	hud.label(center, monster.get("display_name", root.selected_monster_id), Vector2(250, 32), Vector2(280, 46), 39, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.texture(center, monster.get("sprite", ""), Rect2(294, 118, 192, 192))
	hud.label(center, "Lv.%d / %s" % [int(roster["level"]), monster.get("role", "")], Vector2(230, 315), Vector2(320, 34), 23, Color("#be72ff"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(center, "배치 방: %s" % root.rooms[roster["room"]].get("display_name", roster["room"]), Vector2(220, 360), Vector2(340, 34), 21, Color("#d5cbe3"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.build_stat_lines(center, monster, roster)
	hud.button(center, "훈련  금화 30", Rect2(265, 680, 250, 72), Callable(root, "_train_selected_monster"), 19)
	hud.label(center, "방 배치는 관리 화면의 드래그 조작으로 처리합니다.", Vector2(170, 756), Vector2(440, 32), 16, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

	var right = hud.panel(Rect2(1410, 130, 420, 800), Color("#0f0e13e8"))
	hud.label(right, "스킬 슬롯", Vector2(24, 24), Vector2(360, 36), 27, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	var skills: Array = monster.get("skill_slots", [])
	y = 88
	for skill_id in skills:
		if skill_id == null:
			hud.label(right, "잠금 슬롯", Vector2(28, y), Vector2(360, 70), 21, Color("#7d7586"))
		else:
			var skill = DataRegistry.skill(str(skill_id))
			hud.label(right, skill.get("display_name", skill_id), Vector2(28, y), Vector2(360, 28), 23, Color("#ffffff"))
			hud.label(right, skill.get("description", ""), Vector2(28, y + 32), Vector2(360, 54), 16, Color("#bfb7cc"))
		y += 118
	hud.label(right, "레벨업 후보 선택 UI는 검수 후 확장 대상입니다.", Vector2(28, 690), Vector2(360, 70), 17, Color("#9d90ac"))

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
	hud.label(reward_panel, "전투 결산", Vector2(0, 26), Vector2(reward_rect.size.x, 42), 27, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER)
	var y = 96
	for line in root.result_summary.get("lines", []):
		hud.label(reward_panel, str(line), Vector2(44, y), Vector2(reward_rect.size.x - 88, 34), 23, Color("#d8d1df"))
		y += 44
	hud.label(comment_panel, "다음 진행", Vector2(0, 26), Vector2(comment_rect.size.x, 42), 27, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(comment_panel, "결산 확인 후 다음 단계로 진행합니다.\nDAY 03 승리 이후에는 DAY 04 악명 원정 예고 화면으로 이어집니다.", Vector2(48, 112), Vector2(comment_rect.size.x - 96, 160), 22, Color("#d8d1df"))
	if GameState.victory or GameState.defeat or GameState.day >= GameState.max_day:
		hud.button(result_screen, "관리 화면으로", button_rect, Callable(root, "_continue_from_result"), 19, "NextDayButton")
	else:
		hud.button(result_screen, "다음 날 진행", button_rect, Callable(root, "_continue_from_result"), 19, "NextDayButton")

func _tutorial_monster_target_id(monster_id: String) -> String:
	match monster_id:
		"slime":
			return "CHR_PUDDING"
		"goblin":
			return "CHR_GOB"
		"imp":
			return "CHR_PYNN"
		_:
			return ""
