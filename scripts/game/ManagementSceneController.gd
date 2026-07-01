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
	var right = hud.panel(Rect2(1518, 92, 370, 760), Color("#111016dd"))
	hud.label(right, "선택 방", Vector2(24, 22), Vector2(320, 32), 27, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.build_selected_room_info(right)

	var bottom = hud.panel(Rect2(98, 880, 1725, 142), Color("#100e14e8"))
	hud.button(bottom, "건설", Rect2(18, 20, 250, 86), Callable(root, "_build_selected_slot"), 20)
	hud.button(bottom, "몬스터", Rect2(288, 20, 250, 86), Callable(root, "_open_monster_screen"), 20)
	hud.button(bottom, "침공 작전", Rect2(558, 20, 250, 86), Callable(root, "_log").bind("침공 작전은 데모에서 비활성화되어 있습니다."), 20)
	hud.button(bottom, "방어 준비", Rect2(828, 20, 300, 86), Callable(root, "_start_combat"), 20)
	hud.button(bottom, "다음 날", Rect2(1148, 20, 260, 86), Callable(root, "_advance_day_from_management"), 20)
	hud.label(bottom, "방을 클릭해 선택하고, 방어 준비로 전투를 시작합니다.", Vector2(1430, 18), Vector2(270, 88), 16, Color("#bfb7cc"))

func build_monster_ui() -> void:
	hud.build_top_bar()
	var left = hud.panel(Rect2(24, 118, 520, 820), Color("#0f0f14e8"))
	hud.label(left, "보유 몬스터", Vector2(24, 18), Vector2(460, 36), 27, Color("#f4e7d2"))
	var y = 78
	for monster_id in root.monster_roster.keys():
		var data = DataRegistry.monster(monster_id)
		var roster = root.monster_roster[monster_id]
		var suffix = "  Lv.%d  HP %d" % [int(roster["level"]), int(data.get("max_hp", 1)) + (int(roster["level"]) - 1) * 20]
		var monster_button = hud.button(left, "%s%s" % [data.get("display_name", monster_id), suffix], Rect2(24, y, 460, 76), Callable(root, "_select_monster").bind(monster_id), 19)
		if monster_id == root.selected_monster_id:
			monster_button.add_theme_color_override("font_color", Color("#d99bff"))
		y += 90
	hud.button(left, "돌아가기", Rect2(24, 714, 220, 72), Callable(root, "_set_screen").bind(Constants.SCREEN_MANAGEMENT), 19)
	hud.button(left, "선택 방 배치", Rect2(264, 714, 220, 72), Callable(root, "_place_selected_monster"), 18)

	var center = hud.panel(Rect2(590, 130, 780, 800), Color("#111016cc"))
	var monster = DataRegistry.monster(root.selected_monster_id)
	var roster: Dictionary = root.monster_roster[root.selected_monster_id]
	hud.label(center, monster.get("display_name", root.selected_monster_id), Vector2(250, 32), Vector2(280, 46), 39, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.texture(center, monster.get("sprite", ""), Rect2(294, 118, 192, 192))
	hud.label(center, "Lv.%d / %s" % [int(roster["level"]), monster.get("role", "")], Vector2(230, 315), Vector2(320, 34), 23, Color("#be72ff"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(center, "배치 방: %s" % root.rooms[roster["room"]].get("display_name", roster["room"]), Vector2(220, 360), Vector2(340, 34), 21, Color("#d5cbe3"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.build_stat_lines(center, monster, roster)
	hud.button(center, "훈련  금화 30", Rect2(120, 680, 250, 72), Callable(root, "_train_selected_monster"), 19)
	hud.button(center, "배치", Rect2(410, 680, 250, 72), Callable(root, "_place_selected_monster"), 19)

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
	var result_panel = hud.panel(Rect2(520, 205, 880, 630), Color("#100d14f2"), Color("#9b6a27"))
	var title = "방어 성공" if root.result_summary.get("win", false) else "방어 실패"
	if GameState.victory:
		title = "데모 클리어"
	hud.label(result_panel, title, Vector2(0, 48), Vector2(880, 64), 46, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	var y = 150
	for line in root.result_summary.get("lines", []):
		hud.label(result_panel, str(line), Vector2(120, y), Vector2(640, 34), 23, Color("#d8d1df"))
		y += 44
	if GameState.victory or GameState.defeat or GameState.day >= GameState.max_day:
		hud.button(result_panel, "관리 화면으로", Rect2(315, 500, 250, 76), Callable(root, "_set_screen").bind(Constants.SCREEN_MANAGEMENT), 19)
	else:
		hud.button(result_panel, "다음 날 진행", Rect2(315, 500, 250, 76), Callable(root, "_advance_after_result"), 19)
