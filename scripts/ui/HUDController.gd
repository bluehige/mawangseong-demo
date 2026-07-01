extends RefCounted
class_name HUDController

const DirectiveManager = preload("res://scripts/combat/DirectiveManager.gd")
const Constants = preload("res://scripts/core/Constants.gd")

var root: Node

func setup(game_root: Node) -> void:
	root = game_root

func clear() -> void:
	for child in root.ui_layer.get_children():
		child.queue_free()

func build_top_bar() -> void:
	var top = panel(Rect2(16, 10, 1870, 70), Color("#0d0b10e8"), Color("#6e5630"))
	label(top, "금화  %d  +%d/분" % [GameState.gold, GameState.gold_income], Vector2(22, 12), Vector2(270, 42), 23, Color("#ffd36a"))
	label(top, "마력  %d  +%d/분" % [GameState.mana, GameState.mana_income], Vector2(310, 12), Vector2(270, 42), 23, Color("#67b7ff"))
	label(top, "식량  %d/30  +%d/분" % [GameState.food, GameState.food_income], Vector2(600, 12), Vector2(280, 42), 23, Color("#d8a77f"))
	label(top, "악명  %d  +%d/일" % [GameState.infamy, GameState.infamy_income], Vector2(900, 12), Vector2(270, 42), 23, Color("#be72ff"))
	label(top, "DAY %d / 밤" % GameState.day, Vector2(1260, 12), Vector2(170, 42), 25, Color("#e7e0ff"), HORIZONTAL_ALIGNMENT_CENTER)
	label(top, "마왕성 체력  %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp], Vector2(1460, 12), Vector2(360, 42), 23, Color("#ff7982"))

func build_room_list(x: int, y: int, w: int, h: int) -> void:
	var room_panel = panel(Rect2(x, y, w, h), Color("#0e0d12e8"))
	label(room_panel, "방 목록", Vector2(0, 12), Vector2(w, 32), 24, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	var order = ["entrance", "spike_corridor", "treasure", "barracks", "recovery", "throne", "slot_01"]
	var row_y = 58
	for room_id in order:
		if not root.rooms.has(room_id):
			continue
		var room = root.rooms[room_id]
		var text = "%s   %s" % [room.get("display_name", room_id), DirectiveManager.directive_label(root.room_directives.get(room_id, "none"))]
		var room_button = button(room_panel, text, Rect2(16, row_y, w - 32, 48), Callable(root, "_select_room").bind(room_id), 18)
		if room_id == root.selected_room:
			room_button.add_theme_color_override("font_color", Color("#d99bff"))
		row_y += 58

func build_selected_room_info(parent: Control) -> void:
	var room = root.rooms.get(root.selected_room, {})
	label(parent, room.get("display_name", root.selected_room), Vector2(24, 76), Vector2(320, 42), 31, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	texture(parent, "res://assets/sprites/rooms/%s" % room.get("icon", "prop_build_slot_01.png"), Rect2(126, 132, 120, 120))
	label(parent, "타입: %s" % room.get("type", ""), Vector2(30, 280), Vector2(300, 30), 21, Color("#cfc7d9"))
	label(parent, "HP: %d / 최대 배치 %d" % [int(room.get("hp", 0)), int(room.get("max_monsters", 0))], Vector2(30, 320), Vector2(300, 30), 21, Color("#cfc7d9"))
	label(parent, "방 지침: %s" % DirectiveManager.directive_label(root.room_directives.get(root.selected_room, "none")), Vector2(30, 360), Vector2(300, 30), 21, Color("#d99bff"))
	label(parent, "연결: %s" % ", ".join(room.get("exits", [])), Vector2(30, 410), Vector2(300, 64), 17, Color("#998fa8"))
	if room.get("type", "") == "build_slot":
		label(parent, "건설 비용: 금화 100 / 마력 50", Vector2(30, 510), Vector2(300, 30), 21, Color("#ffd36a"))
	else:
		label(parent, "이 방은 현재 고정 시설입니다.", Vector2(30, 510), Vector2(300, 30), 20, Color("#bfb7cc"))
	button(parent, "입구 봉쇄", Rect2(28, 586, 145, 52), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_ENTRY_BLOCK), 18)
	button(parent, "함정 유도", Rect2(190, 586, 145, 52), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_TRAP_LURE), 18)
	button(parent, "후퇴 유도", Rect2(28, 652, 145, 52), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_RETREAT), 18)
	button(parent, "기본", Rect2(190, 652, 145, 52), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_NONE), 18)

func build_stat_lines(parent: Control, monster: Dictionary, roster: Dictionary) -> void:
	var level = int(roster["level"])
	var max_hp = int(monster.get("max_hp", 1)) + (level - 1) * 20
	var attack = int(monster.get("atk", 1)) + (level - 1) * 3
	var defense = int(monster.get("def", 0)) + (level - 1)
	var lines = [
		"HP      %d / %d" % [max_hp, max_hp],
		"공격력   %d" % attack,
		"방어력   %d" % defense,
		"이동속도 %d" % int(monster.get("move_speed", 0)),
		"지능     %d" % int(monster.get("int", 0)),
		"충성도   %d" % int(monster.get("loyalty", 0)),
		"EXP      %d" % int(roster["exp"])
	]
	var y = 420
	for line_text in lines:
		label(parent, line_text, Vector2(250, y), Vector2(300, 26), 22, Color("#d8d1df"))
		y += 34

func build_log_panel() -> void:
	var log_panel = panel(Rect2(20, 710, 455, 300), Color("#0b0b0fe8"))
	label(log_panel, "전투 로그", Vector2(18, 14), Vector2(400, 30), 24, Color("#f4e7d2"))
	var y = 56
	for message in root.logs:
		label(log_panel, message, Vector2(18, y), Vector2(410, 26), 16, Color("#cfc7d9"))
		y += 30

func build_selected_unit_panel() -> void:
	var unit_panel = panel(Rect2(1518, 142, 370, 710), Color("#0e0d12e8"))
	label(unit_panel, "선택 유닛", Vector2(0, 16), Vector2(370, 34), 26, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	if root.selected_unit == null or not is_instance_valid(root.selected_unit):
		label(unit_panel, "유닛을 클릭해 선택하세요.", Vector2(36, 90), Vector2(300, 48), 21, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	texture(unit_panel, root.selected_unit.sprite_path, Rect2(118, 72, 132, 132))
	label(unit_panel, root.selected_unit.display_name, Vector2(26, 220), Vector2(320, 38), 31, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	label(unit_panel, root.selected_unit.role, Vector2(26, 262), Vector2(320, 30), 20, Color("#d99bff"), HORIZONTAL_ALIGNMENT_CENTER)
	label(unit_panel, "체력  %d / %d" % [root.selected_unit.hp, root.selected_unit.max_hp], Vector2(36, 330), Vector2(300, 30), 23, Color("#e8dff0"))
	label(unit_panel, "공격력  %d" % root.selected_unit.atk, Vector2(36, 372), Vector2(300, 28), 21, Color("#e8dff0"))
	label(unit_panel, "방어력  %d" % root.selected_unit.def, Vector2(36, 410), Vector2(300, 28), 21, Color("#e8dff0"))
	label(unit_panel, "공격 속도  %.1fs" % root.selected_unit.attack_interval, Vector2(36, 448), Vector2(300, 28), 21, Color("#e8dff0"))
	label(unit_panel, "현재 방  %s" % root.rooms.get(root.selected_unit.current_room, {}).get("display_name", root.selected_unit.current_room), Vector2(36, 486), Vector2(300, 28), 21, Color("#e8dff0"))
	if root.selected_unit.faction == Constants.FACTION_MONSTER:
		button(unit_panel, "직접 조종", Rect2(36, 560, 136, 58), Callable(root, "_enable_direct_control"), 18)
		button(unit_panel, "AI 복귀", Rect2(196, 560, 136, 58), Callable(root, "_release_direct_control"), 18)
		button(unit_panel, "스킬 1", Rect2(36, 632, 136, 50), Callable(root, "_use_selected_skill").bind(0), 18)
		button(unit_panel, "스킬 2", Rect2(196, 632, 136, 50), Callable(root, "_use_selected_skill").bind(1), 18)

func build_command_panel() -> void:
	var command_panel = panel(Rect2(560, 804, 860, 206), Color("#100e14e8"), Color("#6e5630"))
	label(command_panel, "전체 지침", Vector2(0, 8), Vector2(430, 32), 23, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	label(command_panel, "방 지침", Vector2(430, 8), Vector2(430, 32), 23, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	button(command_panel, "사수", Rect2(40, 55, 130, 110), Callable(root, "_set_global_directive").bind(Constants.DIRECTIVE_DEFENSE), 19)
	button(command_panel, "총공격", Rect2(185, 55, 130, 110), Callable(root, "_set_global_directive").bind(Constants.DIRECTIVE_ALL_OUT), 19)
	button(command_panel, "생존 우선", Rect2(330, 55, 130, 110), Callable(root, "_set_global_directive").bind(Constants.DIRECTIVE_SURVIVAL), 18)
	button(command_panel, "함정 유도", Rect2(500, 55, 145, 110), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_TRAP_LURE), 18)
	button(command_panel, "직접 조종", Rect2(665, 55, 145, 110), Callable(root, "_enable_direct_control"), 18)

func build_speed_panel() -> void:
	var speed_panel = panel(Rect2(1438, 820, 80, 190), Color("#100e14e8"))
	button(speed_panel, "x1", Rect2(10, 16, 60, 48), Callable(root, "_set_speed").bind(1.0), 17)
	button(speed_panel, "x1.5", Rect2(10, 72, 60, 48), Callable(root, "_set_speed").bind(1.5), 16)
	button(speed_panel, "II", Rect2(10, 128, 60, 48), Callable(root, "_toggle_pause"), 17)

func panel(rect: Rect2, color: Color, border: Color = Color("#3b3143")) -> Panel:
	var result = Panel.new()
	result.position = rect.position
	result.size = rect.size
	result.add_theme_stylebox_override("panel", style(color, border, 2))
	root.ui_layer.add_child(result)
	return result

func label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int = 20, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var result = Label.new()
	result.text = text
	result.position = position
	result.size = size
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.clip_text = true
	result.horizontal_alignment = align
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	parent.add_child(result)
	return result

func button(parent: Control, text: String, rect: Rect2, callback: Callable, font_size: int = 21) -> Button:
	var result = Button.new()
	result.text = text
	result.position = rect.position
	result.size = rect.size
	result.focus_mode = Control.FOCUS_NONE
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.add_theme_font_size_override("font_size", min(font_size, _fit_button_font_size(text, rect.size.x)))
	result.add_theme_stylebox_override("normal", style(Color("#17141ddd"), Color("#57485e"), 2))
	result.add_theme_stylebox_override("hover", style(Color("#2a1a37ee"), Color("#a65dff"), 2))
	result.add_theme_stylebox_override("pressed", style(Color("#35194dee"), Color("#d6a5ff"), 2))
	result.add_theme_color_override("font_color", Color("#eee5f4"))
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func texture(parent: Control, path: String, rect: Rect2) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.position = rect.position
	texture_rect.size = rect.size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if path != "":
		texture_rect.texture = root._load_png(path)
	parent.add_child(texture_rect)
	return texture_rect

func style(color: Color, border: Color, width: int) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border
	result.set_border_width_all(width)
	result.corner_radius_top_left = 6
	result.corner_radius_top_right = 6
	result.corner_radius_bottom_left = 6
	result.corner_radius_bottom_right = 6
	result.set_content_margin(SIDE_LEFT, 8)
	result.set_content_margin(SIDE_RIGHT, 8)
	result.set_content_margin(SIDE_TOP, 8)
	result.set_content_margin(SIDE_BOTTOM, 8)
	return result

func _fit_button_font_size(text: String, width: float) -> int:
	var glyph_budget = max(4, int(width / 12.0))
	if text.length() > glyph_budget + 6:
		return 16
	if text.length() > glyph_budget + 2:
		return 18
	return 21
