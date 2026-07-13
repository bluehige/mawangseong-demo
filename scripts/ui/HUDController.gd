extends RefCounted
class_name HUDController

const DirectiveManager = preload("res://scripts/combat/DirectiveManager.gd")
const Constants = preload("res://scripts/core/Constants.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const UI_FONT = UIFontScript.BODY_FONT
const UI_SKIN_BASE = "res://assets/ui/dark_fantasy/"
const PANEL_SKINS = {
	"panel": UI_SKIN_BASE + "panel_inspector.png",
	"dark": UI_SKIN_BASE + "panel_log.png",
	"parchment": UI_SKIN_BASE + "panel_parchment.png",
	"resource": UI_SKIN_BASE + "resource_plaque_wide.png",
	"resource_gold": UI_SKIN_BASE + "resource_plaque_gold.png",
	"resource_mana": UI_SKIN_BASE + "resource_plaque_mana.png",
	"resource_food": UI_SKIN_BASE + "resource_plaque_food.png",
	"resource_infamy": UI_SKIN_BASE + "resource_plaque_infamy.png",
	"resource_small": UI_SKIN_BASE + "resource_plaque_small.png",
	"hp": UI_SKIN_BASE + "hp_bar_frame.png",
	"banner": UI_SKIN_BASE + "banner_title.png",
	"icon_slot": UI_SKIN_BASE + "icon_slot.png"
}
const BUTTON_SKINS = {
	"normal": UI_SKIN_BASE + "button_normal.png",
	"hover": UI_SKIN_BASE + "button_hover.png",
	"pressed": UI_SKIN_BASE + "button_pressed.png",
	"disabled": UI_SKIN_BASE + "button_pressed.png",
	"menu": UI_SKIN_BASE + "button_menu.png"
}

var root: Node
var skin_texture_cache: Dictionary = {}
var selected_skill_buttons: Array[Button] = []
var selected_skill_unit_id: int = 0
var facility_effect_labels: Array[Label] = []
var battle_log_labels: Array[Label] = []
var resource_value_labels: Dictionary = {}
var unit_status_rows: Dictionary = {}
var selected_unit_dynamic_labels: Dictionary = {}
var selected_unit_displayed_id: int = 0
var boss_hp_label: Label = null
var boss_hp_fill: ColorRect = null
var boss_hp_fill_width := 0.0
var command_direct_button: Button = null

func setup(game_root: Node) -> void:
	root = game_root

func clear() -> void:
	selected_skill_buttons.clear()
	selected_skill_unit_id = 0
	facility_effect_labels.clear()
	battle_log_labels.clear()
	resource_value_labels.clear()
	unit_status_rows.clear()
	selected_unit_dynamic_labels.clear()
	selected_unit_displayed_id = 0
	boss_hp_label = null
	boss_hp_fill = null
	boss_hp_fill_width = 0.0
	command_direct_button = null
	for child in root.ui_layer.get_children():
		root.ui_layer.remove_child(child)
		child.queue_free()

func build_top_bar() -> void:
	resource_value_labels["gold"] = _resource_chip(Rect2(16, 10, 250, 62), "금화", "%d" % GameState.gold, Color("#ffd36a"), "resource_gold")
	resource_value_labels["mana"] = _resource_chip(Rect2(278, 10, 250, 62), "마력", "%d" % GameState.mana, Color("#67b7ff"), "resource_mana")
	resource_value_labels["food"] = _resource_chip(Rect2(540, 10, 250, 62), "식량", "%d / 30" % GameState.food, Color("#d8a77f"), "resource_food")
	resource_value_labels["infamy"] = _resource_chip(Rect2(802, 10, 250, 62), "악명", "%d" % GameState.infamy, Color("#be72ff"), "resource_infamy")
	var day_panel = panel(Rect2(1184, 10, 185, 62), Color("#0d0b10e8"), Color("#6e5630"), "", "resource_small")
	label(day_panel, "DAY %02d  밤" % GameState.day, Vector2(0, 20), Vector2(185, 24), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER)
	var hp_panel = panel(Rect2(1400, 10, 486, 62), Color("#0d0b10e8"), Color("#6e5630"), "BossHpBar", "hp")
	boss_hp_label = label(hp_panel, "마왕성 체력  %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp], Vector2(0, 14), Vector2(486, 20), 14, Color("#f7d7dd"), HORIZONTAL_ALIGNMENT_CENTER)
	boss_hp_fill_width = 360.0
	boss_hp_fill = _stat_bar(hp_panel, Rect2(88, 42, boss_hp_fill_width, 9), float(GameState.demon_lord_hp) / float(max(1, GameState.demon_lord_max_hp)), Color("#e04455"), Color("#4b111a"))

func build_room_list(x: int, y: int, w: int, h: int) -> void:
	var room_panel_skin = "flat" if root.current_screen == Constants.SCREEN_COMBAT else "panel"
	var room_panel = panel(Rect2(x, y, w, h), Color("#0e0d12e8"), Color("#3b3143"), "", room_panel_skin)
	var title = "시설 관리" if root.current_screen == Constants.SCREEN_MANAGEMENT else "시설 배치"
	label(room_panel, title, Vector2(0, 12), Vector2(w, 32), 24, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	var order = ["entrance", "throne", "barracks", "recovery", "treasure", "slot_01"]
	var row_y = 54
	var row_height = 40 if h < 420 else 48
	var row_gap = 47 if h < 420 else 58
	for room_id in order:
		if not root.rooms.has(room_id):
			continue
		var room = root.rooms[room_id]
		var text = "      %s   %s" % [room.get("display_name", room_id), _room_list_status(room_id, room)]
		var row_rect = Rect2(16, row_y, w - 32, row_height)
		var room_button = button(room_panel, text, row_rect, Callable(root, "_select_room").bind(room_id), 16, "ROOM_LIST_%s" % room_id.to_upper())
		if room_id == root.selected_room:
			room_button.add_theme_stylebox_override("normal", style(Color("#2a1a37ee"), Color("#c789ff"), 2))
		texture(room_panel, _room_icon_path(room), Rect2(26, row_y + 6, 34, 34))
		row_y += row_gap

func build_facility_build_panel(x: int, y: int, w: int, h: int) -> void:
	var build_panel = panel(Rect2(x, y, w, h), Color("#0e0d12ef"), Color("#6e5630"), "", "flat")
	var direct_target = str(root.build_palette_target_room)
	var title = "시설 팔레트" if direct_target != "" else "건설"
	var help_text = "%s을(를) 바꿉니다. 시설을 고르면 미리보기가 뜹니다." % root.display_name_for_instance(direct_target) if direct_target != "" else "역할을 고른 뒤 맵의 보라색 방이나 빈 슬롯을 클릭합니다."
	label(build_panel, title, Vector2(0, 12), Vector2(w, 32), 24, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	label(build_panel, help_text, Vector2(18, 48), Vector2(w - 36, 34), 12, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	var choices: Array = root._build_facility_choices()
	var row_y := 90
	var compact_rows := choices.size() > 5
	var row_height := 54 if compact_rows else 64
	var row_gap := 56 if compact_rows else 68
	for facility_id_value in choices:
		var facility_id = str(facility_id_value)
		var definition: Dictionary = root._facility_definition(facility_id)
		var display_name = _facility_build_label(facility_id, definition)
		var cost_label = _facility_compact_cost_label(definition.get("cost", {}))
		var role_title = str(definition.get("role_title", ""))
		var facility_button = button(build_panel, "", Rect2(16, row_y, w - 32, row_height), Callable(root, "_set_build_facility").bind(facility_id), 13)
		if facility_id == root.build_pick_facility_id:
			facility_button.add_theme_stylebox_override("normal", style(Color("#2b2340ee"), Color("#ffd36a"), 2))
			facility_button.add_theme_color_override("font_color", Color("#fff2c9"))
		texture(build_panel, str(definition.get("icon", "")), Rect2(24, row_y + 9, 30, 30))
		label(build_panel, display_name, Vector2(62, row_y + 7), Vector2(122, 20), 13, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		label(build_panel, cost_label, Vector2(178, row_y + 8), Vector2(82, 18), 10, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_BODY)
		label(build_panel, role_title, Vector2(62, row_y + 29), Vector2(198, 22 if compact_rows else 26), 11, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2)
		row_y += row_gap

	var selected_definition: Dictionary = root._facility_definition(root.build_pick_facility_id)
	var detail_y = min(row_y + 10, h - 310)
	var detail_height = h - detail_y - 18
	var detail = child_panel(build_panel, Rect2(16, detail_y, w - 32, detail_height), Color("#100d16ef"), Color("#57485e"), 1)
	var selected_name = str(selected_definition.get("display_name", "시설을 고르세요"))
	var selected_cost = root._facility_cost_label(root.build_pick_facility_id) if root.build_pick_facility_id != "" else "-"
	label(detail, "선택 역할", Vector2(14, 10), Vector2(110, 18), 13, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(detail, selected_cost, Vector2(138, 10), Vector2(112, 18), 12, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_RIGHT)
	label(detail, selected_name, Vector2(14, 34), Vector2(236, 24), 18, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(detail, str(selected_definition.get("role_title", "")), Vector2(14, 60), Vector2(236, 20), 13, Color("#d99bff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY)
	rich_label(detail, str(selected_definition.get("role_summary", "")), Vector2(14, 86), Vector2(236, 46), 12, Color("#d8d1df"))
	label(detail, "판단 기준", Vector2(14, 138), Vector2(236, 18), 13, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	rich_label(detail, _facility_detail_text(selected_definition), Vector2(14, 160), Vector2(236, max(62, detail_height - 262)), 11, Color("#cfc7d9"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_TOP)
	var preview_summary = root._build_preview_summary() if root.has_method("_build_preview_summary") else "맵에서 후보 방을 클릭하세요."
	var route_line = root._build_preview_route_line() if root.has_method("_build_preview_route_line") else ""
	label(detail, preview_summary, Vector2(14, detail_height - 96), Vector2(236, 20), 11, Color("#fff2c9"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 1)
	label(detail, route_line, Vector2(14, detail_height - 74), Vector2(236, 28), 10, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
	var confirm_button = button(detail, "건설 확정", Rect2(14, detail_height - 40, 108, 30), Callable(root, "_confirm_build_preview"), 11)
	confirm_button.disabled = not root._build_preview_ready()
	button(detail, "취소", Rect2(132, detail_height - 40, 104, 30), Callable(root, "_cancel_management_action_mode"), 11)

func build_unit_status_panel() -> void:
	unit_status_rows.clear()
	var status_panel = panel(Rect2(16, 500, 336, 184), Color("#0b0b0fe8"), Color("#3b3143"), "", "flat")
	label(status_panel, "전장 상태", Vector2(14, 10), Vector2(308, 24), 18, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(status_panel, "아군", Vector2(14, 42), Vector2(144, 20), 14, Color("#9eea9e"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(status_panel, "침입자", Vector2(176, 42), Vector2(146, 20), 14, Color("#ff9d8f"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	_build_unit_status_column(status_panel, Constants.FACTION_MONSTER, Vector2(14, 68), 3, 144)
	_build_unit_status_column(status_panel, Constants.FACTION_ENEMY, Vector2(176, 68), 3, 146)
	update_unit_status_panel()

func build_facility_effect_panel() -> void:
	facility_effect_labels.clear()
	if not root.has_method("_facility_effect_status_lines"):
		return
	var lines: Array = root._facility_effect_status_lines()
	if lines.is_empty():
		return
	var visible_line_count := mini(lines.size(), 4)
	var effect_panel_height := 44.0 + float(visible_line_count) * 24.0
	var effect_panel = panel(Rect2(390, 92, 430, effect_panel_height), Color("#0b0b0fe2"), Color("#57485e"), "", "flat")
	label(effect_panel, "시설 효과", Vector2(16, 10), Vector2(398, 22), 17, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var y = 38
	for index in range(visible_line_count):
		var status_label = label(effect_panel, str(lines[index]), Vector2(16, y), Vector2(398, 20), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY)
		status_label.name = "FacilityEffectStatus_%d" % index
		facility_effect_labels.append(status_label)
		y += 24

func update_facility_effect_panel() -> void:
	if facility_effect_labels.is_empty() or not root.has_method("_facility_effect_status_lines"):
		return
	var lines: Array = root._facility_effect_status_lines()
	for index in range(mini(lines.size(), facility_effect_labels.size())):
		var status_label := facility_effect_labels[index]
		if not is_instance_valid(status_label):
			continue
		var status_text := str(lines[index])
		status_label.text = status_text
		status_label.add_theme_color_override("font_color", Color("#ff8f80") if status_text.find("무력화") >= 0 else Color("#d8d1df"))

func build_selected_room_info(parent: Control) -> void:
	var room = root.rooms.get(root.selected_room, {})
	var display_name = _instance_display_name(root.selected_room)
	var is_room = not room.is_empty()
	var role_label = _room_role_label(room) if is_room else "통로"
	if role_label == "":
		role_label = "통로"
	var facility_level_label := ""
	if is_room and root.has_method("_facility_upgrade_unlocked") and root.has_method("_facility_upgrade_level") and root._facility_upgrade_unlocked():
		facility_level_label = " Lv.%d" % int(root._facility_upgrade_level(root.selected_room))
	var hp_label = "%d" % int(room.get("hp", 0)) if is_room else "-"
	var capacity_value = int(room.get("max_monsters", 0)) if is_room else 0
	var placed_count = root._placement_count(root.selected_room) if is_room and root.has_method("_placement_count") else 0
	var free_count = max(0, capacity_value - placed_count)
	var capacity_label = "%d/%d명" % [placed_count, capacity_value] if is_room else "-"

	var title_panel = child_panel(parent, Rect2(18, 18, 334, 88), Color("#111016e8"), Color("#6e5630"), 1)
	label(title_panel, "선택 방", Vector2(16, 10), Vector2(150, 20), 14, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(title_panel, display_name, Vector2(16, 32), Vector2(228, 30), 22, Color("#ffffff"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(title_panel, "%s%s" % [role_label, facility_level_label], Vector2(16, 62), Vector2(228, 18), 13, Color("#d99bff"))
	texture(title_panel, _room_icon_path(room), Rect2(258, 16, 58, 58))

	var summary_panel = child_panel(parent, Rect2(18, 116, 334, 92), Color("#0f0d14e8"), Color("#403448"), 1)
	label(summary_panel, "요약", Vector2(14, 10), Vector2(306, 20), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(summary_panel, "체력", Vector2(14, 36), Vector2(74, 20), 13, Color("#aaa1b5"))
	label(summary_panel, hp_label, Vector2(88, 36), Vector2(78, 20), 14, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_RIGHT)
	label(summary_panel, "배치", Vector2(184, 36), Vector2(54, 20), 13, Color("#aaa1b5"))
	label(summary_panel, capacity_label, Vector2(238, 36), Vector2(82, 20), 14, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_RIGHT)
	label(summary_panel, "방 지침", Vector2(14, 62), Vector2(74, 20), 13, Color("#aaa1b5"))
	label(summary_panel, DirectiveManager.directive_label(root.room_directives.get(root.selected_room, "none")), Vector2(88, 62), Vector2(232, 20), 14, Color("#d99bff"), HORIZONTAL_ALIGNMENT_RIGHT)

	var route_panel = child_panel(parent, Rect2(18, 220, 334, 128), Color("#0f0d14e8"), Color("#403448"), 1)
	label(route_panel, "연결", Vector2(14, 10), Vector2(306, 20), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(route_panel, _main_route_status_line(), Vector2(14, 35), Vector2(306, 20), 13, Color("#f4e7d2"))
	label(route_panel, "연결 방  %s" % _connected_room_names(), Vector2(14, 58), Vector2(306, 34), 12, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2)
	label(route_panel, "경로 변경: 왼쪽 [길 드래그 편집] -> 방에서 방으로 드래그 -> 저장", Vector2(14, 94), Vector2(306, 30), 11, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_ARBITRARY, 2)

	var command_panel = child_panel(parent, Rect2(18, 360, 334, 164), Color("#0f0d14e8"), Color("#403448"), 1)
	label(command_panel, "운영 지침", Vector2(14, 10), Vector2(306, 20), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(command_panel, "전체", Vector2(14, 42), Vector2(62, 28), 13, Color("#aaa1b5"))
	option_button(
		command_panel,
		Rect2(84, 36, 238, 34),
		[
			{"label": "사수", "value": Constants.DIRECTIVE_DEFENSE},
			{"label": "총공격", "value": Constants.DIRECTIVE_ALL_OUT},
			{"label": "생존", "value": Constants.DIRECTIVE_SURVIVAL},
		],
		root.global_directive,
		Callable(root, "_set_global_directive"),
		13,
		"GLOBAL_DIRECTIVE_DEFEND"
	)
	label(command_panel, "선택 방", Vector2(14, 86), Vector2(62, 28), 13, Color("#aaa1b5"))
	var room_directive_options: Array = root._room_directive_options(root.selected_room) if root.has_method("_room_directive_options") else [
		{"label": "기본", "value": Constants.ROOM_DIRECTIVE_NONE},
		{"label": "후퇴 유도", "value": Constants.ROOM_DIRECTIVE_RETREAT}
	]
	option_button(
		command_panel,
		Rect2(84, 80, 238, 34),
		room_directive_options,
		root.room_directives.get(root.selected_room, Constants.ROOM_DIRECTIVE_NONE),
		Callable(root, "_set_room_directive"),
		13,
		"ROOM_DIRECTIVE_BLOCK_ENTRANCE"
	)
	label(command_panel, "전투에서 몬스터가 어디를 지킬지 정합니다.", Vector2(14, 126), Vector2(306, 24), 12, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2)

	var monster_panel = child_panel(parent, Rect2(18, 528, 334, 160), Color("#0f0d14e8"), Color("#403448"), 1)
	label(monster_panel, "몬스터 배치", Vector2(14, 10), Vector2(306, 20), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	if is_room and room.get("type", "") != "build_slot":
		var capacity_help = "이 방 정원 %d명, 현재 %d명, 남은 자리 %d. 여러 마리 배치 가능." % [capacity_value, placed_count, free_count]
		var placement_help = "몬스터를 고른 뒤 맵에서 보낼 방을 클릭합니다."
		if root.deploy_pick_monster_id != "":
			placement_help = "%s 배치 중. 맵에서 방을 클릭하세요." % str(DataRegistry.monster(root.deploy_pick_monster_id).get("display_name", root.deploy_pick_monster_id))
		label(monster_panel, capacity_help, Vector2(14, 34), Vector2(306, 28), 10, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2)
		label(monster_panel, placement_help, Vector2(14, 60), Vector2(306, 20), 10, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 1)
		var monster_keys = root.monster_roster.keys()
		if root.has_method("_monster_available_for_defense"):
			monster_keys = monster_keys.filter(func(monster_id): return root._monster_available_for_defense(str(monster_id)))
		for index in range(monster_keys.size()):
			var monster_id = str(monster_keys[index])
			var monster_name = str(DataRegistry.monster(str(monster_id)).get("display_name", monster_id))
			var room_id = str(root.monster_roster[monster_id].get("room", ""))
			var marker = " 여기" if room_id == root.selected_room else ""
			var col = index % 2
			var row = int(index / 2)
			var monster_button = button(monster_panel, "%s%s" % [monster_name, marker], Rect2(12 + col * 156, 84 + row * 34, 146, 30), Callable(root, "_start_monster_placement").bind(str(monster_id)), 10)
			if str(monster_id) == root.deploy_pick_monster_id:
				monster_button.add_theme_stylebox_override("normal", style(Color("#2b2340ee"), Color("#ffd36a"), 2))
	else:
		label(monster_panel, "완성된 방에만 배치할 수 있습니다.", Vector2(14, 42), Vector2(306, 30), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	if root.map_editor_active:
		label(parent, "맵 편집 중에는 시설을 바꿀 수 없습니다.", Vector2(18, 708), Vector2(334, 30), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	elif root.build_pick_mode:
		label(parent, "선택 가능 위치는 맵에 표시됩니다.", Vector2(18, 690), Vector2(334, 22), 12, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_CENTER)
		button(parent, "건설 취소", Rect2(18, 720, 334, 36), Callable(root, "_cancel_management_action_mode"), 14)
	elif root._can_change_room_facility(root.selected_room) and root.has_method("_facility_upgrade_unlocked") and root._facility_upgrade_unlocked() and root.has_method("_upgrade_selected_facility"):
		button(parent, "시설 변경", Rect2(18, 704, 160, 38), Callable(root, "_toggle_facility_change_panel"), 14, "FacilityChangeButton")
		var upgrade_button = button(parent, "시설 강화", Rect2(192, 704, 160, 38), Callable(root, "_upgrade_selected_facility"), 14, "FacilityUpgradeButton")
		if not root.has_method("_can_upgrade_selected_facility") or not root._can_upgrade_selected_facility():
			upgrade_button.disabled = true
			var level_cap := int(root._facility_upgrade_level_cap()) if root.has_method("_facility_upgrade_level_cap") else 2
			upgrade_button.text = "강화 완료" if root.has_method("_facility_upgrade_level") and int(root._facility_upgrade_level(root.selected_room)) >= level_cap else "강화 불가"
	elif root._can_change_room_facility(root.selected_room):
		button(parent, "시설 변경", Rect2(18, 704, 334, 38), Callable(root, "_toggle_facility_change_panel"), 15, "FacilityChangeButton")
	else:
		label(parent, "고정 시설입니다.", Vector2(18, 708), Vector2(334, 30), 13, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

func build_facility_change_modal() -> void:
	var room = root.rooms.get(root.selected_room, {})
	var modal = panel(Rect2(610, 172, 700, 668), Color("#100d14f5"), Color("#9b6a27"))
	label(modal, "시설 변경", Vector2(0, 70), Vector2(700, 36), 27, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER)
	label(modal, _instance_display_name(root.selected_room), Vector2(54, 112), Vector2(592, 28), 19, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	if not root._can_change_room_facility(root.selected_room):
		label(modal, "입구, 필수 통로, 왕좌는 변경할 수 없습니다.", Vector2(64, 260), Vector2(572, 48), 19, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_CENTER)
		button(modal, "닫기", Rect2(254, 586, 192, 48), Callable(root, "_close_facility_change_panel"), 18)
		return
	var choices: Array = root._facility_choices()
	var current_facility = str(room.get("facility_role", ""))
	var y = 154
	for facility_id_value in choices:
		var facility_id = str(facility_id_value)
		var definition: Dictionary = root._facility_definition(facility_id)
		var display_name = str(definition.get("display_name", root._facility_short_label(facility_id)))
		var row = child_panel(modal, Rect2(40, y, 620, 66), Color("#0f0d14e8"), Color("#403448"), 1)
		var facility_button = button(row, display_name, Rect2(14, 10, 188, 46), Callable(root, "_change_selected_room_facility").bind(facility_id), 15)
		if current_facility == facility_id:
			facility_button.disabled = true
			facility_button.add_theme_stylebox_override("disabled", style(Color("#2b2340ee"), Color("#ffd36a"), 2))
			facility_button.add_theme_color_override("font_disabled_color", Color("#ffd36a"))
		label(row, "비용  %s" % root._facility_cost_label(facility_id), Vector2(222, 10), Vector2(166, 20), 14, Color("#d8d1df"))
		var preview_hp := int(definition.get("hp", 0))
		var preview_capacity := int(definition.get("max_monsters", 0))
		var is_build_slot: bool = facility_id == "build_slot"
		if not is_build_slot and root.has_method("_facility_stage_preview_hp"):
			preview_hp = int(root._facility_stage_preview_hp(preview_hp))
		if not is_build_slot and root.has_method("_facility_stage_preview_capacity"):
			preview_capacity = int(root._facility_stage_preview_capacity(preview_capacity))
		var capacity_text: String = "불가" if is_build_slot else str(preview_capacity)
		var stat_label = label(row, "체력 %d / 배치 %s" % [preview_hp, capacity_text], Vector2(402, 10), Vector2(182, 20), 13, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_RIGHT)
		stat_label.name = "FacilityChoiceStats_%s" % facility_id
		label(row, str(definition.get("role_title", "")), Vector2(222, 28), Vector2(362, 18), 13, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		rich_label(row, str(definition.get("role_summary", "")), Vector2(222, 44), Vector2(362, 20), 11, Color("#cfc7d9"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_TOP)
		y += 74
	button(modal, "닫기", Rect2(254, 602, 192, 44), Callable(root, "_close_facility_change_panel"), 17)

func build_stat_lines(parent: Control, monster: Dictionary, roster: Dictionary) -> void:
	var level = int(roster["level"])
	var stats = monster
	if root.has_method("_scaled_monster_stats") and root.selected_monster_id != "":
		stats = root._scaled_monster_stats(root.selected_monster_id)
	var max_hp = int(stats.get("max_hp", int(monster.get("max_hp", 1)) + (level - 1) * 20))
	var attack = int(stats.get("atk", int(monster.get("atk", 1)) + (level - 1) * 3))
	var defense = int(stats.get("def", int(monster.get("def", 0)) + (level - 1)))
	var lines = [
		"HP      %d / %d" % [max_hp, max_hp],
		"공격력   %d" % attack,
		"방어력   %d" % defense,
		"이동속도 %d" % int(stats.get("move_speed", 0)),
		"지능     %d" % int(stats.get("int", 0)),
		"충성도   %d" % int(stats.get("loyalty", 0)),
		"EXP      %d" % int(roster["exp"])
	]
	var y = 50
	for line_text in lines:
		label(parent, line_text, Vector2(20, y), Vector2(parent.size.x - 40, 26), 17, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_OFF, 1, 13)
		y += 34

func build_log_panel() -> void:
	battle_log_labels.clear()
	var log_panel = panel(Rect2(16, 700, 336, 300), Color("#0b0b0fe8"), Color("#3b3143"), "BattleLogPanel", "flat")
	log_panel.name = "BattleLogPanel"
	label(log_panel, "전투 로그", Vector2(14, 12), Vector2(308, 24), 18, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var y = 46
	for _index in range(6):
		battle_log_labels.append(label(log_panel, "", Vector2(14, y), Vector2(308, 34), 11, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2, 9))
		y += 40
	update_log_panel()

func update_log_panel() -> void:
	if battle_log_labels.is_empty():
		return
	var start_index = max(0, root.logs.size() - battle_log_labels.size())
	for row_index in range(battle_log_labels.size()):
		var log_label := battle_log_labels[row_index]
		if not is_instance_valid(log_label):
			continue
		var log_index = start_index + row_index
		log_label.text = str(root.logs[log_index]) if log_index < root.logs.size() else ""

func update_combat_status() -> void:
	if root == null or root.current_screen != Constants.SCREEN_COMBAT:
		return
	_update_resource_values()
	update_unit_status_panel()
	_update_selected_unit_status()
	_update_command_direct_button()

func _update_resource_values() -> void:
	var values := {
		"gold": "%d" % GameState.gold,
		"mana": "%d" % GameState.mana,
		"food": "%d / 30" % GameState.food,
		"infamy": "%d" % GameState.infamy
	}
	for key in values:
		var value_label = resource_value_labels.get(key)
		if value_label is Label and is_instance_valid(value_label):
			value_label.text = str(values[key])
	if boss_hp_label != null and is_instance_valid(boss_hp_label):
		boss_hp_label.text = "마왕성 체력  %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp]
	if boss_hp_fill != null and is_instance_valid(boss_hp_fill):
		var hp_ratio = clamp(float(GameState.demon_lord_hp) / float(max(1, GameState.demon_lord_max_hp)), 0.0, 1.0)
		boss_hp_fill.size = Vector2(boss_hp_fill_width * hp_ratio, boss_hp_fill.size.y)

func update_unit_status_panel() -> void:
	_update_unit_status_column(Constants.FACTION_MONSTER, root.monster_units, Color("#c9f2c9"))
	_update_unit_status_column(Constants.FACTION_ENEMY, root.enemy_units, Color("#ffd1c9"))

func _update_unit_status_column(faction: String, units: Array, base_color: Color) -> void:
	var rows: Array = unit_status_rows.get(faction, [])
	if rows.is_empty():
		return
	var visible_units: Array = []
	for unit in units:
		if unit != null and is_instance_valid(unit):
			visible_units.append(unit)
			if visible_units.size() >= rows.size():
				break
	for row_index in range(rows.size()):
		var row: Dictionary = rows[row_index]
		var name_label: Label = row.get("name")
		var status_label: Label = row.get("status")
		if not is_instance_valid(name_label) or not is_instance_valid(status_label):
			continue
		if row_index >= visible_units.size():
			name_label.text = "-" if row_index == 0 else ""
			status_label.text = ""
			name_label.add_theme_color_override("font_color", Color("#766d7f"))
			continue
		var unit = visible_units[row_index]
		var hp_ratio = clamp(float(unit.hp) / float(max(1, unit.max_hp)), 0.0, 1.0)
		var line_color = base_color
		if not unit.is_alive():
			line_color = Color("#8a8090")
		elif hp_ratio <= 0.35:
			line_color = Color("#ff9d7a")
		name_label.text = "%s  %d%%" % [unit.display_name, int(round(hp_ratio * 100.0))]
		name_label.add_theme_color_override("font_color", line_color)
		status_label.text = unit.status_line()

func _update_selected_unit_status() -> void:
	if root.selected_unit == null or not is_instance_valid(root.selected_unit):
		return
	if root.selected_unit.get_instance_id() != selected_unit_displayed_id:
		return
	var hp_label = selected_unit_dynamic_labels.get("hp")
	var room_label = selected_unit_dynamic_labels.get("room")
	var state_label = selected_unit_dynamic_labels.get("state")
	var status_label = selected_unit_dynamic_labels.get("status")
	if hp_label is Label and is_instance_valid(hp_label):
		hp_label.text = "%d / %d" % [root.selected_unit.hp, root.selected_unit.max_hp]
	if room_label is Label and is_instance_valid(room_label):
		room_label.text = str(root.rooms.get(root.selected_unit.current_room, {}).get("display_name", root.selected_unit.current_room))
	if state_label is Label and is_instance_valid(state_label):
		state_label.text = root.selected_unit.state_label()
	if status_label is RichTextLabel and is_instance_valid(status_label):
		status_label.text = root.selected_unit.status_line()
	for key in ["direct_button", "ai_button"]:
		var action_button = selected_unit_dynamic_labels.get(key)
		if action_button is Button and is_instance_valid(action_button):
			action_button.disabled = root.selected_unit.faction != Constants.FACTION_MONSTER or not root.selected_unit.is_alive()

func _update_command_direct_button() -> void:
	if command_direct_button == null or not is_instance_valid(command_direct_button):
		return
	var can_direct_control: bool = root.selected_unit != null and is_instance_valid(root.selected_unit) and root.selected_unit.faction == Constants.FACTION_MONSTER and root.selected_unit.is_alive()
	command_direct_button.disabled = not can_direct_control

func build_selected_unit_panel() -> void:
	selected_skill_buttons.clear()
	selected_skill_unit_id = 0
	selected_unit_dynamic_labels.clear()
	selected_unit_displayed_id = 0
	var unit_panel = panel(Rect2(1518, 96, 370, 756), Color("#0e0d12e8"), Color("#3b3143"), "", "flat")
	label(unit_panel, "선택 유닛", Vector2(28, 16), Vector2(314, 28), 21, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	if root.selected_unit == null or not is_instance_valid(root.selected_unit):
		label(unit_panel, "유닛을 클릭해 선택하세요.", Vector2(42, 84), Vector2(286, 48), 17, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	selected_unit_displayed_id = root.selected_unit.get_instance_id()
	texture(unit_panel, root.selected_unit.sprite_path, Rect2(129, 60, 112, 112))
	label(unit_panel, root.selected_unit.display_name, Vector2(32, 186), Vector2(306, 32), 24, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	label(unit_panel, root.selected_unit.role, Vector2(32, 222), Vector2(306, 24), 16, Color("#d99bff"), HORIZONTAL_ALIGNMENT_CENTER)
	if root.selected_unit.has_method("has_growth_preparation") and root.selected_unit.has_growth_preparation():
		var preparation_panel = child_panel(unit_panel, Rect2(52, 250, 266, 28), Color("#251d13e8"), Color("#d9a83e"), 1)
		var preparation_label = label(preparation_panel, "집중 준비 · %s" % root.selected_unit.growth_preparation_name, Vector2(8, 3), Vector2(250, 22), 13, Color("#ffe08a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		preparation_panel.tooltip_text = root.selected_unit.growth_preparation_summary
		preparation_label.tooltip_text = root.selected_unit.growth_preparation_summary
	label(unit_panel, "체력", Vector2(42, 286), Vector2(104, 24), 16, Color("#aaa1b5"))
	selected_unit_dynamic_labels["hp"] = label(unit_panel, "%d / %d" % [root.selected_unit.hp, root.selected_unit.max_hp], Vector2(154, 286), Vector2(174, 24), 17, Color("#e8dff0"), HORIZONTAL_ALIGNMENT_RIGHT)
	label(unit_panel, "공격력", Vector2(42, 326), Vector2(104, 24), 16, Color("#aaa1b5"))
	label(unit_panel, "%d" % root.selected_unit.atk, Vector2(154, 326), Vector2(174, 24), 17, Color("#e8dff0"), HORIZONTAL_ALIGNMENT_RIGHT)
	label(unit_panel, "방어력", Vector2(42, 364), Vector2(104, 24), 16, Color("#aaa1b5"))
	label(unit_panel, "%d" % root.selected_unit.def, Vector2(154, 364), Vector2(174, 24), 17, Color("#e8dff0"), HORIZONTAL_ALIGNMENT_RIGHT)
	label(unit_panel, "공격 속도", Vector2(42, 402), Vector2(116, 24), 16, Color("#aaa1b5"))
	label(unit_panel, "%.1fs" % root.selected_unit.attack_interval, Vector2(166, 402), Vector2(162, 24), 17, Color("#e8dff0"), HORIZONTAL_ALIGNMENT_RIGHT)
	label(unit_panel, "현재 방", Vector2(42, 440), Vector2(104, 24), 16, Color("#aaa1b5"))
	selected_unit_dynamic_labels["room"] = label(unit_panel, str(root.rooms.get(root.selected_unit.current_room, {}).get("display_name", root.selected_unit.current_room)), Vector2(154, 440), Vector2(174, 24), 16, Color("#e8dff0"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_OFF, 1)
	label(unit_panel, "상태", Vector2(42, 478), Vector2(104, 24), 16, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	selected_unit_dynamic_labels["state"] = label(unit_panel, root.selected_unit.state_label(), Vector2(154, 478), Vector2(174, 24), 16, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)
	selected_unit_dynamic_labels["status"] = rich_label(unit_panel, root.selected_unit.status_line(), Vector2(42, 516), Vector2(286, 58), 12, Color("#bfb7cc"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART)
	if root.selected_unit.faction == Constants.FACTION_MONSTER:
		var unit_alive = root.selected_unit.is_alive()
		var direct_button = button(unit_panel, "직접 조종", Rect2(42, 612, 130, 46), Callable(root, "_enable_direct_control"), 15, "DirectControlButton")
		var ai_button = button(unit_panel, "AI 복귀", Rect2(198, 612, 130, 46), Callable(root, "_release_direct_control"), 15)
		selected_unit_dynamic_labels["direct_button"] = direct_button
		selected_unit_dynamic_labels["ai_button"] = ai_button
		var skill_one_button = button(unit_panel, "1", Rect2(42, 670, 130, 50), Callable(root, "_use_selected_skill").bind(0), 13, "SkillSlot0")
		var skill_two_button = button(unit_panel, "2", Rect2(198, 670, 130, 50), Callable(root, "_use_selected_skill").bind(1), 13, "SkillSlot1")
		skill_one_button.mouse_entered.connect(Callable(root, "_preview_selected_skill").bind(0))
		skill_one_button.mouse_exited.connect(Callable(root, "_clear_selected_skill_preview"))
		skill_two_button.mouse_entered.connect(Callable(root, "_preview_selected_skill").bind(1))
		skill_two_button.mouse_exited.connect(Callable(root, "_clear_selected_skill_preview"))
		direct_button.disabled = not unit_alive
		ai_button.disabled = not unit_alive
		selected_skill_buttons.assign([skill_one_button, skill_two_button])
		selected_skill_unit_id = root.selected_unit.get_instance_id()
		update_combat_skill_buttons()

func update_combat_skill_buttons() -> void:
	if selected_skill_buttons.is_empty() or root.selected_unit == null or not is_instance_valid(root.selected_unit):
		return
	if root.selected_unit.get_instance_id() != selected_skill_unit_id:
		return
	var skill_slots: Array = DataRegistry.monster(root.selected_unit.unit_id).get("skill_slots", [])
	for slot in range(selected_skill_buttons.size()):
		var skill_button := selected_skill_buttons[slot]
		if not is_instance_valid(skill_button):
			continue
		if slot >= skill_slots.size() or skill_slots[slot] == null:
			skill_button.text = "%d  기술 없음" % (slot + 1)
			skill_button.tooltip_text = "이 칸에는 사용할 기술이 없습니다."
			skill_button.disabled = true
			continue
		var skill_id := str(skill_slots[slot])
		var skill: Dictionary = DataRegistry.skill(skill_id)
		var display_name := str(skill.get("display_name", skill_id))
		var mana_cost: int = root._current_skill_mana_cost(skill)
		var cooldown := float(root.selected_unit.skill_cooldowns.get(skill_id, 0.0))
		var status_text := "준비됨"
		if not root.selected_unit.is_alive():
			status_text = "전투 불능"
		elif cooldown > 0.05:
			status_text = "재사용 %.1f초" % cooldown
		elif GameState.mana < mana_cost:
			status_text = "마력 %d 필요" % mana_cost
		elif mana_cost > 0:
			status_text = "준비됨 · 마력 %d" % mana_cost
		skill_button.text = "%d  %s\n%s" % [slot + 1, display_name, status_text]
		skill_button.tooltip_text = "%s\n마력 %d · 재사용 %.1f초" % [str(skill.get("description", "")), mana_cost, float(skill.get("cooldown", 0.0))]
		skill_button.disabled = not root.selected_unit.is_alive() or cooldown > 0.05 or GameState.mana < mana_cost

func build_command_panel() -> void:
	var command_panel = panel(Rect2(560, 884, 860, 142), Color("#100e14e8"), Color("#6e5630"), "", "flat")
	label(command_panel, "전체 지침", Vector2(0, 8), Vector2(430, 26), 18, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	label(command_panel, "방 지침", Vector2(430, 8), Vector2(430, 26), 18, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	var defense_button = button(command_panel, "사수", Rect2(36, 48, 120, 66), Callable(root, "_set_global_directive").bind(Constants.DIRECTIVE_DEFENSE), 17, "GLOBAL_DIRECTIVE_DEFEND")
	var all_out_button = button(command_panel, "총공격", Rect2(170, 48, 120, 66), Callable(root, "_set_global_directive").bind(Constants.DIRECTIVE_ALL_OUT), 17)
	var survival_button = button(command_panel, "생존 우선", Rect2(304, 48, 130, 66), Callable(root, "_set_global_directive").bind(Constants.DIRECTIVE_SURVIVAL), 16)
	defense_button.tooltip_text = "배치 방을 지키며 부상 아군을 지원합니다. 받는 피해 50% 감소, HP 55% 이하에서 보호막 사수."
	all_out_button.tooltip_text = "적을 추격합니다. 기본 공격 피해 15% 증가, 받는 피해 15% 증가."
	survival_button.tooltip_text = "회복 시설이 있으면 HP 85%, 없으면 70% 이하에서 후퇴합니다. 기본 공격 피해 10% 감소, 받는 피해 55% 감소."
	button(command_panel, "함정 유도", Rect2(496, 48, 136, 66), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_TRAP_LURE), 16, "ROOM_DIRECTIVE_TRAP_LURE")
	command_direct_button = button(command_panel, "직접 조종", Rect2(648, 48, 136, 66), Callable(root, "_enable_direct_control"), 16, "DirectControlButton")
	_update_command_direct_button()

func build_speed_panel() -> void:
	var speed_panel = panel(Rect2(1438, 884, 74, 142), Color("#100e14e8"), Color("#3b3143"), "", "flat")
	if root.campaign_cycle_index >= 2:
		button(speed_panel, "x1", Rect2(9, 7, 56, 27), Callable(root, "_set_speed").bind(1.0), 12)
		button(speed_panel, "x1.5", Rect2(9, 40, 56, 27), Callable(root, "_set_speed").bind(1.5), 11)
		button(speed_panel, "x2", Rect2(9, 73, 56, 27), Callable(root, "_set_speed").bind(2.0), 12)
		button(speed_panel, "II", Rect2(9, 106, 56, 27), Callable(root, "_toggle_pause"), 12)
	else:
		button(speed_panel, "x1", Rect2(9, 12, 56, 34), Callable(root, "_set_speed").bind(1.0), 14)
		button(speed_panel, "x1.5", Rect2(9, 54, 56, 34), Callable(root, "_set_speed").bind(1.5), 13)
		button(speed_panel, "II", Rect2(9, 96, 56, 34), Callable(root, "_toggle_pause"), 14)

func _build_unit_status_column(parent: Control, faction: String, origin: Vector2, max_rows: int, width: float = 160.0) -> void:
	var rows: Array = []
	for row_index in range(max_rows):
		var y = origin.y + float(row_index) * 38.0
		var name_label = label(parent, "", Vector2(origin.x, y), Vector2(width, 17), 12, Color("#766d7f"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_OFF, 1)
		var status_label = label(parent, "", Vector2(origin.x, y + 18.0), Vector2(width, 24), 10, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 2)
		rows.append({"name": name_label, "status": status_label})
	unit_status_rows[faction] = rows

func panel(rect: Rect2, color: Color, border: Color = Color("#3b3143"), target_id: String = "", skin_id: String = "panel") -> Panel:
	var result = Panel.new()
	result.position = rect.position
	result.size = rect.size
	result.clip_contents = true
	result.add_theme_stylebox_override("panel", panel_style(skin_id, color, border, 2))
	root.ui_layer.add_child(result)
	_register_target(target_id, result)
	return result

func child_panel(parent: Control, rect: Rect2, color: Color, border: Color = Color("#3b3143"), border_width: int = 1) -> Panel:
	var result = Panel.new()
	result.position = rect.position
	result.size = rect.size
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.clip_contents = true
	result.add_theme_stylebox_override("panel", flat_style(color, border, border_width))
	parent.add_child(result)
	return result

func label(
	parent: Control,
	text: String,
	position: Vector2,
	size: Vector2,
	font_size: int = 20,
	color: Color = Color.WHITE,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
	target_id: String = "",
	font_role: String = UIFontScript.ROLE_BODY,
	vertical_align: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER,
	wrap_mode: int = TextServer.AUTOWRAP_WORD_SMART,
	max_lines: int = 0,
	min_font_size: int = 11
) -> Label:
	var result = Label.new()
	result.text = text
	result.position = position
	result.size = size
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.autowrap_mode = wrap_mode
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.clip_text = true
	result.horizontal_alignment = align
	result.vertical_alignment = vertical_align
	if max_lines > 0:
		result.max_lines_visible = max_lines
	result.add_theme_font_override("font", UIFontScript.font_for_role(font_role))
	var preferred_font_size = UISettings.scaled_font_size(font_size)
	result.add_theme_font_size_override("font_size", preferred_font_size)
	result.add_theme_color_override("font_color", color)
	parent.add_child(result)
	call_deferred("_fit_label_to_bounds", result, UISettings.scaled_font_size(min_font_size), 0)
	_register_target(target_id, result)
	return result

func rich_label(
	parent: Control,
	text: String,
	position: Vector2,
	size: Vector2,
	font_size: int = 20,
	color: Color = Color.WHITE,
	font_role: String = UIFontScript.ROLE_BODY,
	wrap_mode: int = TextServer.AUTOWRAP_WORD_SMART,
	vertical_align: VerticalAlignment = VERTICAL_ALIGNMENT_TOP,
	target_id: String = "",
	min_font_size: int = 11
) -> RichTextLabel:
	var result = RichTextLabel.new()
	result.text = text
	result.position = position
	result.size = size
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.bbcode_enabled = false
	result.fit_content = false
	result.scroll_active = false
	result.clip_contents = true
	result.autowrap_mode = wrap_mode
	result.add_theme_font_override("normal_font", UIFontScript.font_for_role(font_role))
	var preferred_font_size = UISettings.scaled_font_size(font_size)
	result.add_theme_font_size_override("normal_font_size", preferred_font_size)
	result.add_theme_color_override("default_color", color)
	parent.add_child(result)
	call_deferred("_fit_rich_label_to_bounds", result, position, size, vertical_align, UISettings.scaled_font_size(min_font_size), 0)
	_register_target(target_id, result)
	return result

func _fit_label_to_bounds(result, min_font_size: int, attempt: int) -> void:
	if not is_instance_valid(result) or not result is Label:
		return
	var current_size = result.get_theme_font_size("font_size")
	var font = result.get_theme_font("font")
	var line_count = maxi(1, result.get_line_count())
	var needed_height = float(line_count * font.get_height(current_size))
	var too_tall = needed_height > result.size.y + 1.0
	var too_wide = false
	if result.autowrap_mode == TextServer.AUTOWRAP_OFF:
		too_wide = font.get_string_size(result.text, HORIZONTAL_ALIGNMENT_LEFT, -1, current_size).x > result.size.x - 2.0
	if (too_tall or too_wide) and current_size > min_font_size and attempt < 24:
		result.add_theme_font_size_override("font_size", current_size - 1)
		call_deferred("_fit_label_to_bounds", result, min_font_size, attempt + 1)

func _fit_rich_label_to_bounds(
	result,
	base_position: Vector2,
	base_size: Vector2,
	vertical_align: VerticalAlignment,
	min_font_size: int,
	attempt: int
) -> void:
	if not is_instance_valid(result) or not result is RichTextLabel:
		return
	var current_size = result.get_theme_font_size("normal_font_size")
	var content_height = float(result.get_content_height()) + 6.0
	if content_height > base_size.y + 1.0 and current_size > min_font_size and attempt < 24:
		result.add_theme_font_size_override("normal_font_size", current_size - 1)
		call_deferred("_fit_rich_label_to_bounds", result, base_position, base_size, vertical_align, min_font_size, attempt + 1)
		return
	_align_rich_label_vertically(result, base_position, base_size, vertical_align, 0)

func _align_rich_label_vertically(
	result: RichTextLabel,
	base_position: Vector2,
	base_size: Vector2,
	vertical_align: VerticalAlignment,
	attempt: int
) -> void:
	if not is_instance_valid(result):
		return
	var content_height := float(result.get_content_height()) + 6.0
	if content_height <= 6.0 and attempt < 2:
		call_deferred("_align_rich_label_vertically", result, base_position, base_size, vertical_align, attempt + 1)
		return
	var aligned_height = min(base_size.y, max(content_height, 1.0))
	var offset_y := 0.0
	match vertical_align:
		VERTICAL_ALIGNMENT_CENTER:
			offset_y = max(0.0, (base_size.y - aligned_height) * 0.5)
		VERTICAL_ALIGNMENT_BOTTOM:
			offset_y = max(0.0, base_size.y - aligned_height)
	result.position = Vector2(base_position.x, base_position.y + offset_y)
	result.size = Vector2(base_size.x, aligned_height)

func button(parent: Control, text: String, rect: Rect2, callback: Callable, font_size: int = 21, target_id: String = "") -> Button:
	var result = Button.new()
	result.text = text
	result.position = rect.position
	result.size = rect.size
	result.focus_mode = Control.FOCUS_NONE
	result.alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	var preferred_font_size = UISettings.scaled_font_size(font_size)
	result.add_theme_font_size_override("font_size", min(preferred_font_size, _fit_button_font_size(text, rect.size.x)))
	result.add_theme_stylebox_override("normal", button_style("normal"))
	result.add_theme_stylebox_override("hover", button_style("hover"))
	result.add_theme_stylebox_override("pressed", button_style("pressed"))
	result.add_theme_stylebox_override("disabled", button_style("disabled"))
	result.add_theme_color_override("font_color", Color("#eee5f4"))
	result.add_theme_color_override("font_hover_color", Color("#ffffff"))
	result.add_theme_color_override("font_pressed_color", Color("#d9c0ff"))
	result.add_theme_color_override("font_disabled_color", Color("#756a82"))
	if callback.is_valid():
		result.pressed.connect(callback)
	parent.add_child(result)
	_register_target(target_id, result)
	return result

func slider(parent: Control, rect: Rect2, value: float, callback: Callable, minimum: float = 0.0, maximum: float = 100.0, step: float = 1.0) -> HSlider:
	var result = HSlider.new()
	result.position = rect.position
	result.size = rect.size
	result.min_value = minimum
	result.max_value = maximum
	result.step = step
	result.value = value
	result.allow_greater = false
	result.allow_lesser = false
	var track = flat_style(Color("#1c1822"), Color("#57485e"), 1)
	var fill = flat_style(Color("#8f5f28"), Color("#ffd36a"), 1)
	result.add_theme_stylebox_override("slider", track)
	result.add_theme_stylebox_override("grabber_area", fill)
	result.add_theme_stylebox_override("grabber_area_highlight", fill)
	result.value_changed.connect(callback)
	parent.add_child(result)
	return result

func option_button(
	parent: Control,
	rect: Rect2,
	items: Array,
	selected_value: String,
	callback: Callable,
	font_size: int = 14,
	target_id: String = ""
) -> OptionButton:
	var result = OptionButton.new()
	result.position = rect.position
	result.size = rect.size
	result.focus_mode = Control.FOCUS_NONE
	result.fit_to_longest_item = false
	result.alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_stylebox_override("normal", button_style("normal"))
	result.add_theme_stylebox_override("hover", button_style("hover"))
	result.add_theme_stylebox_override("pressed", button_style("pressed"))
	result.add_theme_color_override("font_color", Color("#eee5f4"))
	result.add_theme_color_override("font_hover_color", Color("#ffffff"))
	result.add_theme_color_override("font_pressed_color", Color("#d9c0ff"))
	var selected_index := 0
	for item_value in items:
		var item := item_value as Dictionary
		var index: int = result.item_count
		var value := str(item.get("value", ""))
		result.add_item(str(item.get("label", value)), index)
		result.set_item_metadata(index, value)
		if value == selected_value:
			selected_index = index
	if result.item_count > 0:
		result.select(selected_index)
	var popup := result.get_popup()
	popup.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	popup.add_theme_font_size_override("font_size", font_size)
	popup.add_theme_color_override("font_color", Color("#eee5f4"))
	popup.id_pressed.connect(_option_button_item_selected.bind(result, callback))
	parent.add_child(result)
	_register_target(target_id, result)
	return result

func _option_button_item_selected(index: int, menu: OptionButton, callback: Callable) -> void:
	if index < 0 or index >= menu.item_count:
		return
	callback.call(str(menu.get_item_metadata(index)))

func _register_target(target_id: String, control: Control) -> void:
	if target_id == "" or not root.has_method("register_tutorial_target_control"):
		return
	root.register_tutorial_target_control(target_id, control)

func texture(parent: Control, path: String, rect: Rect2) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.position = rect.position
	texture_rect.size = rect.size
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if path != "":
		texture_rect.texture = root._load_png(path)
	parent.add_child(texture_rect)
	return texture_rect

func style(color: Color, border: Color, width: int) -> StyleBox:
	return flat_style(color, border, width)

func flat_style(color: Color, border: Color, width: int) -> StyleBoxFlat:
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

func panel_style(skin_id: String, color: Color, border: Color, width: int) -> StyleBox:
	if skin_id == "flat" or (color.a <= 0.01 and border.a <= 0.01):
		return flat_style(color, border, width)
	var path = str(PANEL_SKINS.get(skin_id, PANEL_SKINS["panel"]))
	var texture = _skin_texture(path)
	if texture == null:
		return flat_style(color, border, width)
	return _texture_style(texture, _skin_margin(skin_id), 12)

func button_style(state: String) -> StyleBox:
	var path = str(BUTTON_SKINS.get(state, BUTTON_SKINS["normal"]))
	var texture = _skin_texture(path)
	if texture == null:
		return flat_style(Color("#17141ddd"), Color("#57485e"), 2)
	return _texture_style(texture, 0, 10)

func _texture_style(texture: Texture2D, texture_margin: int, content_margin: int) -> StyleBoxTexture:
	var result = StyleBoxTexture.new()
	result.texture = texture
	result.set_texture_margin(SIDE_LEFT, texture_margin)
	result.set_texture_margin(SIDE_TOP, texture_margin)
	result.set_texture_margin(SIDE_RIGHT, texture_margin)
	result.set_texture_margin(SIDE_BOTTOM, texture_margin)
	result.set_content_margin(SIDE_LEFT, content_margin)
	result.set_content_margin(SIDE_RIGHT, content_margin)
	result.set_content_margin(SIDE_TOP, content_margin)
	result.set_content_margin(SIDE_BOTTOM, content_margin)
	return result

func _skin_margin(skin_id: String) -> int:
	match skin_id:
		"resource", "resource_gold", "resource_mana", "resource_food", "resource_infamy", "resource_small", "hp":
			return 0
		"banner":
			return 0
		"icon_slot":
			return 0
		"parchment":
			return 110
		_:
			return 110

func _skin_texture(path: String) -> Texture2D:
	if skin_texture_cache.has(path):
		return skin_texture_cache[path]
	var loaded = ResourceLoader.load(path)
	if loaded is Texture2D:
		skin_texture_cache[path] = loaded
		return loaded
	var image = Image.new()
	var err = image.load(path)
	if err != OK and path.begins_with("res://"):
		err = image.load(ProjectSettings.globalize_path(path))
	if err == OK:
		var texture = ImageTexture.create_from_image(image)
		skin_texture_cache[path] = texture
		return texture
	push_warning("Could not load UI skin texture: %s" % path)
	skin_texture_cache[path] = null
	return null

func _room_list_status(room_id: String, room: Dictionary) -> String:
	if root.current_screen == Constants.SCREEN_COMBAT:
		return DirectiveManager.directive_label(root.room_directives.get(room_id, "none"))
	if room.get("type", "") == "build_slot":
		return "건설 가능"
	if root.has_method("_can_change_room_facility") and not root._can_change_room_facility(room_id):
		return "고정"
	return "%d/%d" % [root._placement_count(room_id), int(room.get("max_monsters", 0))]

func _facility_build_label(facility_id: String, definition: Dictionary) -> String:
	if facility_id == "build_slot":
		return "비우기"
	return str(definition.get("display_name", root._facility_short_label(facility_id)))

func _facility_compact_cost_label(cost: Dictionary) -> String:
	var parts: Array[String] = []
	if int(cost.get("gold", 0)) > 0:
		parts.append("금%d" % int(cost.get("gold", 0)))
	if int(cost.get("mana", 0)) > 0:
		parts.append("마%d" % int(cost.get("mana", 0)))
	if int(cost.get("food", 0)) > 0:
		parts.append("식%d" % int(cost.get("food", 0)))
	if int(cost.get("infamy", 0)) > 0:
		parts.append("악%d" % int(cost.get("infamy", 0)))
	if parts.is_empty():
		return "무료"
	return " ".join(parts)

func _facility_detail_text(definition: Dictionary) -> String:
	return "효과  %s\n추천  %s\n주의  %s" % [
		str(definition.get("effect_summary", "")),
		str(definition.get("recommend_summary", "")),
		str(definition.get("caution_summary", ""))
	]

func _resource_chip(rect: Rect2, title: String, value: String, accent: Color, skin_id: String = "resource") -> Label:
	var chip = panel(rect, Color("#0d0b10e8"), Color("#6e5630"), "", skin_id)
	label(chip, title, Vector2(0, 10), Vector2(rect.size.x, 18), 12, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	return label(chip, value, Vector2(0, 28), Vector2(rect.size.x, 24), 16, accent, HORIZONTAL_ALIGNMENT_CENTER)

func _stat_bar(parent: Control, rect: Rect2, ratio: float, fill: Color, back: Color) -> ColorRect:
	var bg = ColorRect.new()
	bg.position = rect.position
	bg.size = rect.size
	bg.color = back
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	var fg = ColorRect.new()
	fg.position = rect.position
	fg.size = Vector2(rect.size.x * clamp(ratio, 0.0, 1.0), rect.size.y)
	fg.color = fill
	fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fg)
	return fg

func _fit_button_font_size(text: String, width: float) -> int:
	var glyph_budget = max(4, int(width / 12.0))
	if text.length() > glyph_budget + 6:
		return 16
	if text.length() > glyph_budget + 2:
		return 18
	return 21

func _room_icon_path(room: Dictionary) -> String:
	var icon_name = str(room.get("icon", "res://assets/ui/room_v2/room_v2_build_slot.png"))
	if root.has_method("room_icon_path"):
		return root.room_icon_path(icon_name)
	if icon_name.begins_with("marker_"):
		return "res://assets/sprites/room_markers/%s" % icon_name
	return "res://assets/sprites/rooms/%s" % icon_name

func _room_type_label(room_type: String) -> String:
	match room_type:
		"entry":
			return "입구"
		"trap":
			return "함정 복도"
		"corridor":
			return "중앙 통로"
		"core":
			return "핵심 방"
		"support":
			return "지원 시설"
		"bait":
			return "유인 시설"
		"recovery":
			return "회복 시설"
		"build_slot":
			return "건설 슬롯"
		_:
			return room_type

func _room_role_label(room: Dictionary) -> String:
	var facility_id = str(room.get("facility_role", ""))
	if facility_id != "":
		var definition: Dictionary = root._facility_definition(facility_id)
		if not definition.is_empty() and str(definition.get("role_title", "")) != "":
			return str(definition.get("role_title", ""))
	return _room_type_label(str(room.get("type", "")))

func _instance_display_name(instance_id: String) -> String:
	if root.has_method("display_name_for_instance"):
		return root.display_name_for_instance(instance_id)
	return str(root.rooms.get(instance_id, {}).get("display_name", instance_id))

func _connected_room_names() -> String:
	var exits: Array = []
	if root.graph != null and root.graph.has_method("exits"):
		exits = root.graph.exits(root.selected_room)
	else:
		exits = root.rooms.get(root.selected_room, {}).get("exits", [])
	var names: Array[String] = []
	for exit_id_value in exits:
		var exit_id = str(exit_id_value)
		names.append(_instance_display_name(exit_id))
	if names.is_empty():
		return "없음"
	return ", ".join(names)

func _main_route_status_line() -> String:
	if root.has_method("_main_route_status_line"):
		return root._main_route_status_line()
	return "입구-왕좌 경로: 확인 불가"
