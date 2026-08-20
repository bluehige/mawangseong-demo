extends RefCounted
class_name HUDController

const DirectiveManager = preload("res://scripts/combat/DirectiveManager.gd")
const Constants = preload("res://scripts/core/Constants.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const V122CombatViewModelScript = preload("res://scripts/v122/ui/V122CombatResultViewModel.gd")
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
const BUTTON_GRADE_LEGACY = "legacy"
const BUTTON_GRADE_PRIMARY = "primary"
const BUTTON_GRADE_TACTICAL = "tactical"
const BUTTON_GRADE_UTILITY = "utility"
const BUTTON_GRADE_DANGER = "danger"
const UI_STATE_DEFAULT = "default"
const UI_STATE_SELECTED = "selected"
const UI_STATE_VALID = "valid"
const UI_STATE_INVALID = "invalid"
const UI_STATE_SUCCESS = "success"
const UI_STATE_ERROR = "error"
const COLOR_VOID = Color("#08070d")
const COLOR_PANEL = Color("#100e16")
const COLOR_SOFT_PANEL = Color("#17131f")
const COLOR_LINE = Color("#5f536a")
const COLOR_BRASS = Color("#6e5630")
const COLOR_ROUTE_PURPLE = Color("#9e7bd1")
const COLOR_DECISION_GOLD = Color("#e8bb58")
const COLOR_BRIGHT_GOLD = Color("#ffe4a0")
const COLOR_DANGER = Color("#e56a72")
const COLOR_SUCCESS = Color("#58c997")
const COLOR_INFORMATION = Color("#7fb3c8")
const COLOR_TEXT = Color("#f3eadc")
const COLOR_MUTED_TEXT = Color("#bdb3c6")

var root: Node
var skin_texture_cache: Dictionary = {}
var facility_effect_labels: Array[Label] = []
var battle_log_labels: Array[Label] = []
var resource_value_labels: Dictionary = {}
var unit_status_rows: Dictionary = {}
var selected_unit_dynamic_labels: Dictionary = {}
var selected_unit_displayed_id: int = 0
var boss_hp_label: Label = null
var boss_hp_fill: ColorRect = null
var boss_hp_fill_width := 0.0
var v122_command_buttons: Dictionary = {}
var v122_command_points_label: Label = null
var v122_throne_status_label: Label = null
var v122_throne_hp_fill: ColorRect = null
var v122_throne_hp_fill_width := 0.0
var v122_defense_progress_label: Label = null
var v122_defense_progress_fill: ColorRect = null
var v122_defense_progress_fill_width := 0.0
var v122_threat_panel: Panel = null
var v122_threat_label: Label = null

func setup(game_root: Node) -> void:
	root = game_root

func clear() -> void:
	facility_effect_labels.clear()
	battle_log_labels.clear()
	resource_value_labels.clear()
	unit_status_rows.clear()
	selected_unit_dynamic_labels.clear()
	selected_unit_displayed_id = 0
	boss_hp_label = null
	boss_hp_fill = null
	boss_hp_fill_width = 0.0
	v122_command_buttons.clear()
	v122_command_points_label = null
	v122_throne_status_label = null
	v122_throne_hp_fill = null
	v122_throne_hp_fill_width = 0.0
	v122_defense_progress_label = null
	v122_defense_progress_fill = null
	v122_defense_progress_fill_width = 0.0
	v122_threat_panel = null
	v122_threat_label = null
	for child in root.ui_layer.get_children():
		root.ui_layer.remove_child(child)
		child.queue_free()

func build_top_bar() -> void:
	if not UISettings.is_touch_ui():
		_build_desktop_status_rail(UISettings.is_compact_layout())
		return
	resource_value_labels["gold"] = _resource_chip(Rect2(16, 10, 250, 62), "금화", "%d" % GameState.gold, Color("#ffd36a"), "resource_gold")
	resource_value_labels["mana"] = _resource_chip(Rect2(278, 10, 250, 62), "마력", "%d" % GameState.mana, Color("#67b7ff"), "resource_mana")
	resource_value_labels["food"] = _resource_chip(Rect2(540, 10, 250, 62), "식량", "%d / 30" % GameState.food, Color("#d8a77f"), "resource_food")
	resource_value_labels["infamy"] = _resource_chip(Rect2(802, 10, 250, 62), "악명", "%d" % GameState.infamy, Color("#be72ff"), "resource_infamy")
	var day_panel = panel(Rect2(1184, 10, 185, 62), Color("#0d0b10e8"), Color("#6e5630"), "", "resource_small")
	label(day_panel, "DAY %02d  밤" % GameState.day, Vector2(8, 14), Vector2(169, 34), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER)
	var hp_panel = panel(Rect2(1400, 10, 486, 62), Color("#0d0b10e8"), Color("#6e5630"), "BossHpBar", "hp")
	boss_hp_label = label(hp_panel, "마왕성 체력  %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp], Vector2(12, 8), Vector2(462, 30), 14, Color("#f7d7dd"), HORIZONTAL_ALIGNMENT_CENTER)
	boss_hp_fill_width = 360.0
	boss_hp_fill = _stat_bar(hp_panel, Rect2(88, 42, boss_hp_fill_width, 9), float(GameState.demon_lord_hp) / float(max(1, GameState.demon_lord_max_hp)), Color("#e04455"), Color("#4b111a"))

func _build_desktop_status_rail(compact: bool) -> void:
	var rail_rect := Rect2(12, 8, 876, 54) if compact else Rect2(16, 10, 1036, 62)
	var resource_rail = panel(rail_rect, Color("#0d0b10c8"), Color("#403747"), "", "flat")
	resource_rail.name = "ResourceStatusRail"
	resource_rail.set_meta("ui_component_grade", BUTTON_GRADE_UTILITY)
	var item_width := rail_rect.size.x / 4.0
	resource_value_labels["gold"] = _resource_rail_item(resource_rail, Rect2(0, 0, item_width, rail_rect.size.y), "금화", "%d" % GameState.gold, Color("#d9b45d"), compact)
	resource_value_labels["mana"] = _resource_rail_item(resource_rail, Rect2(item_width, 0, item_width, rail_rect.size.y), "마력", "%d" % GameState.mana, Color("#67b7ff"), compact)
	resource_value_labels["food"] = _resource_rail_item(resource_rail, Rect2(item_width * 2.0, 0, item_width, rail_rect.size.y), "식량", "%d / 30" % GameState.food, Color("#d8a77f"), compact)
	resource_value_labels["infamy"] = _resource_rail_item(resource_rail, Rect2(item_width * 3.0, 0, item_width, rail_rect.size.y), "악명", "%d" % GameState.infamy, Color("#be72ff"), compact)
	for index in range(1, 4):
		var divider := ColorRect.new()
		divider.position = Vector2(item_width * float(index), 9)
		divider.size = Vector2(1, rail_rect.size.y - 18)
		divider.color = Color("#5f536a88")
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		resource_rail.add_child(divider)

	var day_rect := Rect2(1064, 8, 170, 54) if compact else Rect2(1184, 10, 185, 62)
	var day_panel = panel(day_rect, Color("#0d0b10c8"), Color("#6e5630"), "", "flat")
	day_panel.name = "DayStatusBadge"
	label(day_panel, "DAY %02d  밤" % GameState.day, Vector2(8, 10 if compact else 14), Vector2(day_rect.size.x - 16, 34), 16 if compact else 15, Color("#d9b45d"), HORIZONTAL_ALIGNMENT_CENTER)

	var hp_rect := Rect2(1246, 8, 662, 54) if compact else Rect2(1400, 10, 486, 62)
	var hp_panel = panel(hp_rect, Color("#0d0b10c8"), Color("#6e5630"), "BossHpBar", "flat")
	hp_panel.name = "BossHpBar"
	boss_hp_label = label(hp_panel, "마왕성 체력  %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp], Vector2(12, 5 if compact else 8), Vector2(hp_rect.size.x - 24, 28 if compact else 30), 15 if compact else 14, Color("#f7d7dd"), HORIZONTAL_ALIGNMENT_CENTER)
	boss_hp_fill_width = 526.0 if compact else 360.0
	var fill_x := 68.0 if compact else 63.0
	boss_hp_fill = _stat_bar(hp_panel, Rect2(fill_x, 38 if compact else 42, boss_hp_fill_width, 8 if compact else 9), float(GameState.demon_lord_hp) / float(max(1, GameState.demon_lord_max_hp)), Color("#e04455"), Color("#4b111a"))

func _resource_rail_item(parent: Control, rect: Rect2, title: String, value: String, accent: Color, compact: bool) -> Label:
	label(parent, title, rect.position + Vector2(0, 6 if compact else 9), Vector2(rect.size.x, 18), 13 if compact else 12, COLOR_MUTED_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	return label(parent, value, rect.position + Vector2(0, 24 if compact else 29), Vector2(rect.size.x, 24), 18 if compact else 16, accent, HORIZONTAL_ALIGNMENT_CENTER)

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
	label(effect_panel, "시설 효과", Vector2(16, 6), Vector2(398, 30), 17, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var y = 40
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


func build_v122_tactical_panel() -> void:
	if not root.has_meta("v122_combat_view_model"):
		return
	var model: Dictionary = root.get_meta("v122_combat_view_model", {})
	var tactical_panel = panel(Rect2(840, 92, 660, 112), Color("#09080dde"), Color("#6e5630"), "V122TacticalStatus", "flat")
	tactical_panel.name = "V122TacticalStatus"
	label(tactical_panel, str(model.get("objective_label", "방어 목표")), Vector2(16, 8), Vector2(470, 24), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	v122_command_points_label = label(
		tactical_panel,
		"명령 %d/%d" % [int(model.get("command_points", 0)), int(model.get("command_points_max", 0))],
		Vector2(500, 8),
		Vector2(144, 24),
		14,
		Color("#67b7ff"),
		HORIZONTAL_ALIGNMENT_RIGHT,
		"",
		UIFontScript.ROLE_EMPHASIS
	)
	label(tactical_panel, str(model.get("active_route_label", "활성 경로 없음")), Vector2(16, 36), Vector2(628, 24), 12, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_OFF, 1)
	var threats: Array = model.get("threats", [])
	if not threats.is_empty():
		var threat: Dictionary = threats.front()
		var lane_label := str(threat.get("lane_label", threat.get("entry_display_name", "")))
		var threat_text := "위협 · %s%s → %s · %s" % [
			str(threat.get("enemy_id", "")),
			" · %s" % lane_label if lane_label != "" else "",
			str(threat.get("target_room_id", "")),
			str(threat.get("counter_hint", ""))
		]
		label(tactical_panel, threat_text, Vector2(16, 68), Vector2(628, 34), 12, Color("#ffb06a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)

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
	label(route_panel, "입구부터 왕좌까지 연결된 기본 방어 경로입니다.", Vector2(14, 94), Vector2(306, 30), 11, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_ARBITRARY, 2)

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
	var room_directive_button = option_button(
		command_panel,
		Rect2(84, 80, 238, 34),
		room_directive_options,
		root.room_directives.get(root.selected_room, Constants.ROOM_DIRECTIVE_NONE),
		Callable(root, "_set_room_directive"),
		13
	)
	room_directive_button.name = "SelectedRoomDirectiveOption"
	for option in room_directive_options:
		match str(option.get("value", "")):
			Constants.ROOM_DIRECTIVE_ENTRY_BLOCK:
				_register_target("ROOM_DIRECTIVE_BLOCK_ENTRANCE", room_directive_button)
			Constants.ROOM_DIRECTIVE_TRAP_LURE:
				_register_target("ROOM_DIRECTIVE_TRAP_LURE", room_directive_button)
			Constants.ROOM_DIRECTIVE_RETREAT:
				_register_target("ROOM_DIRECTIVE_RETREAT_LINE", room_directive_button)
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
	modal.name = "FacilityChangeModal"
	modal.z_index = 500
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
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
	_update_v122_combat_core_status()
	_update_v122_command_controls()


func _update_v122_combat_core_status() -> void:
	if not root.has_meta("v122_combat_view_model"):
		return
	var model: Dictionary = root.get_meta("v122_combat_view_model", {})
	var throne_hp := int(model.get("throne_hp", GameState.demon_lord_hp))
	var throne_hp_max := maxi(1, int(model.get("throne_hp_max", GameState.demon_lord_max_hp)))
	if v122_throne_status_label != null and is_instance_valid(v122_throne_status_label):
		v122_throne_status_label.text = "DAY %02d · 왕좌 %d / %d" % [GameState.day, throne_hp, throne_hp_max]
	if v122_throne_hp_fill != null and is_instance_valid(v122_throne_hp_fill):
		v122_throne_hp_fill.size.x = v122_throne_hp_fill_width * clampf(float(throne_hp) / float(throne_hp_max), 0.0, 1.0)
	var defense_progress := clampf(float(model.get("defense_progress", 0.0)), 0.0, 1.0)
	if v122_defense_progress_label != null and is_instance_valid(v122_defense_progress_label):
		v122_defense_progress_label.text = "방어 진행 %d%%" % int(round(defense_progress * 100.0))
	if v122_defense_progress_fill != null and is_instance_valid(v122_defense_progress_fill):
		v122_defense_progress_fill.size.x = v122_defense_progress_fill_width * defense_progress
	var threat_visible := bool(model.get("threat_panel_visible", false))
	if v122_threat_panel != null and is_instance_valid(v122_threat_panel):
		v122_threat_panel.visible = threat_visible
	if threat_visible and v122_threat_label != null and is_instance_valid(v122_threat_label):
		v122_threat_label.text = _v122_threat_text(model)


func _v122_threat_text(model: Dictionary) -> String:
	var threats: Array = model.get("threats", [])
	var threat: Dictionary = threats.front() if not threats.is_empty() and threats.front() is Dictionary else {}
	var lane_label := str(threat.get("lane_label", threat.get("entry_display_name", "")))
	return "%s · %s%s → %s · %s" % [
		str(threat.get("status_label", "침입 위협")),
		str(threat.get("enemy_display_name", threat.get("enemy_id", "미확인 적"))),
		" · %s" % lane_label if lane_label != "" else "",
		str(threat.get("target_display_name", threat.get("target_room_id", "왕좌"))),
		str(threat.get("counter_hint", "진입 전에 차단"))
	]


func _update_v122_command_controls() -> void:
	if not root.has_meta("v122_combat_view_model"):
		return
	var model: Dictionary = root.get_meta("v122_combat_view_model", {})
	var pending_command_id := str(model.get("pending_command_id", ""))
	if v122_command_points_label != null and is_instance_valid(v122_command_points_label):
		if pending_command_id == "":
			v122_command_points_label.text = "명령 %d/%d · 명령 선택 → 노란 대상 클릭" % [
				int(model.get("command_points", 0)),
				int(model.get("command_points_max", 0))
			]
		else:
			var pending_data := _v122_command_data(pending_command_id)
			v122_command_points_label.text = "%s 준비 · 노란 %s 클릭 · ESC/우클릭 취소" % [
				str(pending_data.get("label", pending_command_id)),
				_v122_target_type_label(str(pending_data.get("target_type", "")))
			]
	for value in model.get("commands", []):
		if not value is Dictionary:
			continue
		var command: Dictionary = value
		var command_id := str(command.get("id", ""))
		var command_button = v122_command_buttons.get(command_id)
		if not command_button is Button or not is_instance_valid(command_button):
			continue
		var live_state_value = root.get_meta("v122_command_state", {})
		var live_state: Dictionary = live_state_value if live_state_value is Dictionary else {}
		var live_cooldown := float(live_state.get("cooldowns", {}).get(command_id, command.get("cooldown_seconds", 0.0)))
		var live_active: Dictionary = live_state.get("active_commands", {}).get(command_id, {})
		var active_seconds := float(live_active.get("remaining_seconds", command.get("active_seconds", 0.0)))
		var live_points := int(live_state.get("points", model.get("command_points", 0)))
		var cost := int(command.get("cost", 0))
		var unavailable := live_cooldown > 0.0 or live_points < cost
		# Disabled controls cannot explain why a deliberate command was refused. Keep
		# the button pressable, dim it, and let the command layer return its specific
		# reason and recovery cue without spending a command point.
		command_button.disabled = false
		command_button.text = "%s\n%s" % [
			str(command.get("label", command_id)),
			"발동 %.1f초" % active_seconds if active_seconds > 0.05 else "%.1f초" % live_cooldown if live_cooldown > 0.05 else "CP %d" % cost
		]
		if unavailable:
			command_button.tooltip_text = "지금은 %s. 눌러서 이유와 다음 행동을 확인하세요." % ("재사용 대기 중" if live_cooldown > 0.0 else "명령 포인트가 부족합니다")
			command_button.add_theme_stylebox_override("normal", style(Color("#25212af5"), Color("#766d7f"), 2))
			command_button.add_theme_stylebox_override("hover", style(Color("#332b34fa"), Color("#ff9a8b"), 3))
			command_button.add_theme_color_override("font_color", Color("#c9c0cf"))
		elif active_seconds > 0.05:
			command_button.add_theme_stylebox_override("normal", style(Color("#39284bf5"), Color("#ffd36a"), 3))
			command_button.add_theme_color_override("font_color", Color("#fff2c9"))
		elif command_id == pending_command_id:
			command_button.add_theme_stylebox_override("normal", style(Color("#392b18f5"), Color("#ffd36a"), 3))
			command_button.add_theme_stylebox_override("hover", style(Color("#4b3820f8"), Color("#fff2a8"), 4))
			command_button.add_theme_color_override("font_color", Color("#fff2c9"))


func build_combat_core_hud() -> void:
	var model: Dictionary = root.get_meta("v122_combat_view_model", {})
	var touch_ui := UISettings.is_touch_ui()
	var compact := UISettings.is_compact_layout()
	var layout: Dictionary = V122CombatViewModelScript.design_layout_contract(compact, touch_ui)
	var throne_hp := int(model.get("throne_hp", GameState.demon_lord_hp))
	var throne_hp_max := maxi(1, int(model.get("throne_hp_max", GameState.demon_lord_max_hp)))
	var throne_rect: Rect2 = layout.get("throne_status", Rect2(20, 20, 620, 72))
	var throne_panel := panel(throne_rect, Color("#0b0910dc"), Color("#6e5630"), "CombatThroneStatus", "flat")
	throne_panel.name = "CombatThroneStatus"
	if root.has_method("register_tutorial_target_control"):
		root.register_tutorial_target_control("BossHpBar", throne_panel)
	var status_label_y := 7.0 if touch_ui else 3.0
	var status_bar_y := 38.0 if touch_ui else throne_rect.size.y - 16.0
	var status_bar_height := 10.0 if touch_ui else 7.0
	var status_inner_width := throne_rect.size.x - 32.0
	var progress_width := 126.0 if touch_ui else clampf(status_inner_width * 0.27, 108.0, 152.0)
	var status_gap := 18.0
	v122_throne_hp_fill_width = status_inner_width - progress_width - status_gap
	var progress_x := 16.0 + v122_throne_hp_fill_width + status_gap
	v122_throne_status_label = label(
		throne_panel,
		"DAY %02d · 왕좌 %d / %d" % [GameState.day, throne_hp, throne_hp_max],
		Vector2(16, status_label_y),
		Vector2(v122_throne_hp_fill_width, 24),
		20,
		Color("#fff0dc"),
		HORIZONTAL_ALIGNMENT_LEFT,
		"",
		UIFontScript.ROLE_EMPHASIS
	)
	v122_throne_hp_fill = _stat_bar(
		throne_panel,
		Rect2(16, status_bar_y, v122_throne_hp_fill_width, status_bar_height),
		float(throne_hp) / float(throne_hp_max),
		Color("#dc4e5d"),
		Color("#3a1118")
	)
	var defense_progress := clampf(float(model.get("defense_progress", 0.0)), 0.0, 1.0)
	v122_defense_progress_label = label(
		throne_panel,
		"방어 진행 %d%%" % int(round(defense_progress * 100.0)),
		Vector2(progress_x, status_label_y),
		Vector2(progress_width, 24),
		20,
		Color("#d8d1df"),
		HORIZONTAL_ALIGNMENT_LEFT,
		"",
		UIFontScript.ROLE_EMPHASIS
	)
	v122_defense_progress_fill_width = progress_width
	v122_defense_progress_fill = _stat_bar(
		throne_panel,
		Rect2(progress_x, status_bar_y, v122_defense_progress_fill_width, status_bar_height),
		defense_progress,
		Color("#d8a83f"),
		Color("#302512")
	)
	if bool(model.get("threat_panel_visible", false)):
		var threat_rect: Rect2 = layout.get("threat", Rect2(660, 20, 700, 72))
		var threat_panel := panel(threat_rect, Color("#180b0ddd"), Color("#a94f50"), "CombatThreat", "flat")
		threat_panel.name = "CombatThreat"
		v122_threat_panel = threat_panel
		label(threat_panel, "침입 위협", Vector2(14, status_label_y), Vector2(96, 24), 20, Color("#ff9d8f"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		v122_threat_label = label(
			threat_panel,
			_v122_threat_text(model),
			Vector2(116, status_label_y),
			Vector2(threat_rect.size.x - 130.0, threat_rect.size.y - status_label_y - 6.0),
			20,
			Color("#f7e4df"),
			HORIZONTAL_ALIGNMENT_LEFT,
			"",
			UIFontScript.ROLE_BODY,
			VERTICAL_ALIGNMENT_CENTER,
			TextServer.AUTOWRAP_WORD_SMART,
			2
		)

	var command_rect: Rect2 = layout.get("commands", Rect2(420, 884, 1000, 142))
	var command_panel := panel(command_rect, Color("#0b0910e8"), Color("#6e5630"), "CombatCommandBar", "flat")
	command_panel.name = "CombatCommandBar"
	v122_command_points_label = label(
		command_panel,
		"명령 %d/%d · 명령 선택 → 노란 대상 클릭" % [
			int(model.get("command_points", 0)),
			int(model.get("command_points_max", 0))
		],
		Vector2(14, 3),
		Vector2(command_rect.size.x - 28.0, 30 if touch_ui else (27 if compact else 22)),
		20,
		Color("#ffd36a"),
		HORIZONTAL_ALIGNMENT_CENTER,
		"",
		UIFontScript.ROLE_EMPHASIS
	)
	var command_specs := [
		{"id": "rally", "target_id": "GLOBAL_DIRECTIVE_DEFEND"},
		{"id": "focus", "target_id": "V122_COMMAND_FOCUS"},
		{"id": "emergency_fallback", "target_id": "V122_COMMAND_FALLBACK"}
	]
	var command_gap := 10.0
	var command_button_width := (command_rect.size.x - 24.0 - command_gap * maxf(0.0, float(command_specs.size() - 1))) / maxf(1.0, float(command_specs.size()))
	var command_button_y := 42.0 if touch_ui else (32.0 if compact else 26.0)
	var command_button_height := command_rect.size.y - command_button_y - 10.0
	for index in range(command_specs.size()):
		var spec: Dictionary = command_specs[index]
		var command_id := str(spec.get("id", ""))
		var command_data := _v122_command_data(command_id)
		var command_button := button(
			command_panel,
			str(command_data.get("label", command_id)),
			Rect2(
				12 + index * (command_button_width + command_gap),
				command_button_y,
				command_button_width,
				command_button_height
			),
			Callable(root, "_issue_v122_command").bind(command_id),
			20,
			str(spec.get("target_id", ""))
		)
		command_button.set_meta("ui_audio_silent", true)
		command_button.tooltip_text = "전장의 노란 %s 표시를 클릭하면 즉시 발동 · CP %d" % [
			_v122_target_type_label(str(command_data.get("target_type", ""))),
			int(command_data.get("cost", 0))
		]
		if str(command_data.get("description", "")) != "":
			command_button.tooltip_text += "\n%s" % str(command_data.get("description", ""))
		v122_command_buttons[command_id] = command_button
	if not touch_ui:
		build_combat_tactics_panel()
		build_combat_special_actions_panel()
	build_speed_panel()
	_update_v122_combat_core_status()
	_update_v122_command_controls()


func build_combat_tactics_panel() -> void:
	var compact := UISettings.is_compact_layout()
	var layout := V122CombatViewModelScript.design_layout_contract(compact, false)
	var tactics_rect: Rect2 = layout.get("tactics", Rect2(20, 884, 380, 142))
	var tactics_panel := panel(tactics_rect, Color("#0b0910e8"), Color("#5c475f"), "CombatTacticsPanel", "flat")
	tactics_panel.name = "CombatTacticsPanel"
	var panel_width := tactics_rect.size.x
	var row_height := 40.0 if compact else 34.0
	var first_row_y := 30.0 if compact else 26.0
	var second_row_y := 83.0 if compact else 69.0
	label(tactics_panel, "운영 지침", Vector2(10, 3), Vector2(panel_width - 20.0, 22), 20, Color("#d9b45d"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	label(tactics_panel, "전체", Vector2(10, first_row_y), Vector2(54, row_height), 18, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT)
	var global_button := option_button(
		tactics_panel,
		Rect2(64, first_row_y, panel_width - 74.0, row_height),
		[
			{"label": "사수 · 배치 방 방어", "value": Constants.DIRECTIVE_DEFENSE},
			{"label": "총공격 · 전장 전체 추격", "value": Constants.DIRECTIVE_ALL_OUT},
			{"label": "생존 · 회복과 이탈 우선", "value": Constants.DIRECTIVE_SURVIVAL}
		],
		root.global_directive,
		Callable(root, "_set_global_directive"),
		20,
		"GLOBAL_DIRECTIVE_DEFEND"
	)
	if root.has_method("_day_one_global_directive_locked") and root._day_one_global_directive_locked():
		global_button.disabled = true
		global_button.tooltip_text = "DAY 01은 사수로 고정됩니다."
	var selected_room_name: String = str(root.display_name_for_instance(root.selected_room))
	label(tactics_panel, selected_room_name, Vector2(10, second_row_y), Vector2(92, row_height), 18, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT)
	var selected_room_data: Dictionary = root.rooms.get(root.selected_room, {})
	var facility_role := str(selected_room_data.get("facility_role", ""))
	var active_facility: bool = (
		facility_role in ["barracks", "recovery", "watch_post", "ward_core"]
		and root.has_method("_facility_room_is_active")
		and root._facility_room_is_active(root.selected_room)
	)
	if active_facility:
		var facility_button := button(
			tactics_panel,
			"시설 가동 · %s" % root._facility_short_label(facility_role),
			Rect2(104, second_row_y, panel_width - 114.0, row_height),
			Callable(root, "_issue_v122_selected_facility"),
			18,
			"V122_COMMAND_FACILITY_CONTEXT"
		)
		facility_button.set_meta("ui_audio_silent", true)
		facility_button.tooltip_text = "선택한 시설을 즉시 가동합니다. 시설을 선택하면 이 자리에서만 나타납니다."
	else:
		var room_button := option_button(
			tactics_panel,
			Rect2(104, second_row_y, panel_width - 114.0, row_height),
			root._room_directive_options(root.selected_room),
			root.room_directives.get(root.selected_room, Constants.ROOM_DIRECTIVE_NONE),
			Callable(root, "_set_room_directive"),
			20
		)
		room_button.name = "CombatSelectedRoomDirective"
		room_button.tooltip_text = "%s의 방 지침입니다. 전장의 방을 클릭해 대상을 바꿉니다." % selected_room_name


func build_combat_special_actions_panel() -> void:
	var heart: Dictionary = root.update3_active_run.get("heart", {}) if root.update3_active_run is Dictionary else {}
	var heart_available := str(heart.get("heart_id", "")) != "" and bool(heart.get("awakened", false))
	var duo_state: Dictionary = root._update3_duo_link_hud_state() if root.has_method("_update3_duo_link_hud_state") else {}
	var equipped_links: Array = duo_state.get("equipped", [])
	var floor_available: bool = (
		root.has_method("_update4_council_mode_active")
		and root._update4_council_mode_active()
		and bool(root.update4_active_run.get("upper_floor", {}).get("unlocked", false))
	)
	if not heart_available and equipped_links.is_empty() and not floor_available:
		return
	var compact := UISettings.is_compact_layout()
	var layout := V122CombatViewModelScript.design_layout_contract(compact, false)
	var special_rect: Rect2 = layout.get("special_actions", Rect2(1568, 884, 332, 142))
	var special_panel := panel(special_rect, Color("#0b0910e8"), Color("#5c475f"), "CombatSpecialActions", "flat")
	special_panel.name = "CombatSpecialActions"
	var content_width := special_rect.size.x - 20.0
	label(special_panel, "특수 전력", Vector2(10, 3), Vector2(content_width, 22), 13 if compact else 11, Color("#d9b45d"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var actions: Array[Dictionary] = []
	if heart_available:
		actions.append({
			"text": "심장\n%d/100" % clampi(int(heart.get("charge", 0)), 0, 100),
			"callback": Callable(root, "_activate_update3_heart"),
			"disabled": int(heart.get("charge", 0)) < 100 or bool(heart.get("active_used_this_battle", false)) or bool(heart.get("disabled_this_battle", false)),
			"name": "CombatHeartActivate"
		})
	for link_index in range(mini(2, equipped_links.size())):
		var link_id := str(equipped_links[link_index])
		var state: Dictionary = duo_state.get("states", {}).get(link_id, {})
		actions.append({
			"text": "%s\n%d/100" % [str(duo_state.get("names", {}).get(link_id, link_id)), clampi(int(state.get("charge", 0)), 0, 100)],
			"callback": Callable(root, "_activate_update3_duo_link").bind(link_id),
			"disabled": not bool(state.get("active", false)) or bool(state.get("used_this_battle", false)) or int(state.get("charge", 0)) < 100,
			"name": "CombatDuoActivate_%d" % link_index
		})
	var action_count := mini(3, actions.size())
	var action_width := (content_width - maxf(0.0, float(action_count - 1)) * 6.0) / maxf(1.0, float(action_count))
	var floor_row_height := 34.0 if floor_available else 0.0
	var action_height := special_rect.size.y - 38.0 - floor_row_height
	for action_index in range(action_count):
		var action: Dictionary = actions[action_index]
		var action_button := button(
			special_panel,
			str(action.get("text", "")),
			Rect2(10 + action_index * (action_width + 6.0), 30, action_width, action_height),
			action.get("callback", Callable()),
			12 if compact else 11,
			str(action.get("name", ""))
		)
		action_button.disabled = bool(action.get("disabled", false))
	if floor_available:
		var floor_y := special_rect.size.y - 38.0
		var floor_label_width := minf(104.0, content_width * 0.32)
		var floor_button_width := (content_width - floor_label_width - 12.0) * 0.5
		label(special_panel, "표시 층", Vector2(10, floor_y), Vector2(floor_label_width, 30), 11, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_CENTER)
		button(special_panel, "1F", Rect2(16 + floor_label_width, floor_y, floor_button_width, 30), Callable(root, "_select_update4_visible_floor").bind("1F"), 11, "CombatFloor1")
		button(special_panel, "2F", Rect2(22 + floor_label_width + floor_button_width, floor_y, floor_button_width, 30), Callable(root, "_select_update4_visible_floor").bind("2F"), 11, "CombatFloor2")


func build_combat_unit_inspector() -> void:
	if root.selected_unit == null or not is_instance_valid(root.selected_unit):
		return
	selected_unit_dynamic_labels.clear()
	selected_unit_displayed_id = root.selected_unit.get_instance_id()
	var unit = root.selected_unit
	var is_enemy := str(unit.faction) == Constants.FACTION_ENEMY
	var accent := Color("#ff8f7f") if is_enemy else Color("#aee88f")
	if UISettings.is_touch_ui():
		_build_touch_combat_unit_inspector(unit, is_enemy, accent)
		return
	var layout := V122CombatViewModelScript.design_layout_contract(UISettings.is_compact_layout(), false)
	var inspector_rect: Rect2 = layout.get("unit_inspector", Rect2(1518, 104, 370, 270))
	var inspector := panel(inspector_rect, Color("#09070de8"), accent.darkened(0.52), "CombatUnitInspector", "flat")
	inspector.name = "CombatUnitInspector"
	inspector.z_index = 110
	inspector.mouse_filter = Control.MOUSE_FILTER_STOP
	label(inspector, "적 정보" if is_enemy else "아군 정보", Vector2(14, 8), Vector2(294, 30), 17, accent, HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	button(inspector, "×", Rect2(326, 7, 34, 34), Callable(root, "_clear_combat_unit_selection"), 15, "CombatUnitInspectorClose")
	texture(inspector, str(unit.sprite_path), Rect2(16, 48, 72, 72))
	label(inspector, str(unit.display_name), Vector2(100, 47), Vector2(250, 27), 19, Color("#fff0dc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(inspector, "%s · 공격 %d · 방어 %d" % [_combat_unit_role_label(unit, is_enemy), int(unit.atk), int(unit.def)], Vector2(100, 76), Vector2(250, 22), 12, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT)
	label(inspector, "HP", Vector2(100, 102), Vector2(38, 22), 12, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT)
	selected_unit_dynamic_labels["hp"] = label(inspector, "%d / %d" % [unit.hp, unit.max_hp], Vector2(140, 102), Vector2(210, 22), 13, accent, HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(inspector, "위치", Vector2(16, 132), Vector2(52, 22), 12, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT)
	selected_unit_dynamic_labels["room"] = label(
		inspector,
		root.display_name_for_instance(str(unit.current_room)),
		Vector2(72, 132),
		Vector2(278, 22),
		13,
		Color("#eee5f4"),
		HORIZONTAL_ALIGNMENT_LEFT
	)
	label(inspector, "행동", Vector2(16, 159), Vector2(52, 22), 12, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT)
	selected_unit_dynamic_labels["state"] = label(inspector, unit.state_label(), Vector2(72, 159), Vector2(278, 22), 13, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(inspector, "목표", Vector2(16, 186), Vector2(52, 22), 12, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT)
	selected_unit_dynamic_labels["objective"] = label(inspector, _combat_unit_objective_text(unit, is_enemy), Vector2(72, 186), Vector2(278, 22), 13, accent, HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var status_text := str(unit.status_line())
	if is_enemy and unit.has_method("threat_warning_text") and str(unit.threat_warning_text()) != "":
		status_text = "%s · %s" % [str(unit.threat_warning_text()), status_text]
	elif not is_enemy and unit.has_method("has_growth_preparation") and unit.has_growth_preparation():
		status_text = "집중 준비 · %s | %s" % [unit.growth_preparation_name, status_text]
	selected_unit_dynamic_labels["status"] = rich_label(
		inspector,
		status_text,
		Vector2(16, 214),
		Vector2(338, 44),
		11,
		Color("#d8d1df"),
		UIFontScript.ROLE_BODY,
		TextServer.AUTOWRAP_WORD_SMART,
		VERTICAL_ALIGNMENT_CENTER,
		"",
		2
	)


func _build_touch_combat_unit_inspector(unit: Node, is_enemy: bool, accent: Color) -> void:
	var layout := V122CombatViewModelScript.design_layout_contract(false, true)
	var inspector_rect: Rect2 = layout.get("unit_inspector", Rect2(820, 120, 1068, 620))
	var inspector := panel(inspector_rect, Color("#09070df8"), accent.darkened(0.42), "CombatUnitInspector", "flat")
	inspector.name = "CombatUnitInspector"
	inspector.z_index = 110
	inspector.mouse_filter = Control.MOUSE_FILTER_STOP
	label(inspector, "적 정보" if is_enemy else "아군 정보", Vector2(28, 18), Vector2(760, 70), 30, accent, HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER)
	button(inspector, "닫기", Rect2(820, 14, 220, 104), Callable(root, "_clear_combat_unit_selection"), 24, "CombatUnitInspectorClose")
	texture(inspector, str(unit.sprite_path), Rect2(32, 130, 180, 180))
	label(inspector, str(unit.display_name), Vector2(244, 130), Vector2(760, 54), 32, Color("#fff0dc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER)
	label(inspector, "%s · 공격 %d · 방어 %d" % [_combat_unit_role_label(unit, is_enemy), int(unit.atk), int(unit.def)], Vector2(244, 190), Vector2(760, 42), 22, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER)
	label(inspector, "체력", Vector2(244, 246), Vector2(92, 44), 22, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER)
	selected_unit_dynamic_labels["hp"] = label(inspector, "%d / %d" % [unit.hp, unit.max_hp], Vector2(346, 246), Vector2(658, 44), 26, accent, HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER)
	label(inspector, "위치", Vector2(32, 330), Vector2(170, 44), 22, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER)
	selected_unit_dynamic_labels["room"] = label(inspector, root.display_name_for_instance(str(unit.current_room)), Vector2(212, 330), Vector2(792, 44), 24, Color("#eee5f4"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER)
	label(inspector, "행동", Vector2(32, 390), Vector2(170, 44), 22, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER)
	selected_unit_dynamic_labels["state"] = label(inspector, unit.state_label(), Vector2(212, 390), Vector2(792, 44), 24, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER)
	label(inspector, "목표", Vector2(32, 450), Vector2(170, 44), 22, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER)
	selected_unit_dynamic_labels["objective"] = label(inspector, _combat_unit_objective_text(unit, is_enemy), Vector2(212, 450), Vector2(792, 44), 24, accent, HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER)
	var status_text := str(unit.status_line())
	if is_enemy and unit.has_method("threat_warning_text") and str(unit.threat_warning_text()) != "":
		status_text = "%s · %s" % [str(unit.threat_warning_text()), status_text]
	elif not is_enemy and unit.has_method("has_growth_preparation") and unit.has_growth_preparation():
		status_text = "집중 준비 · %s | %s" % [unit.growth_preparation_name, status_text]
	selected_unit_dynamic_labels["status"] = rich_label(inspector, status_text, Vector2(32, 510), Vector2(972, 84), 22, Color("#d8d1df"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "", 18)


func _combat_unit_role_label(unit: Node, is_enemy: bool) -> String:
	var role_id := str(unit.role)
	if is_enemy:
		return str({
			"throne": "왕좌 돌파",
			"treasure": "보물 약탈",
			"facility": "시설 교란",
			"commander": "지휘관",
			"assault": "돌격",
			"support": "지원"
		}.get(role_id, role_id))
	return str({
		"guard": "방어",
		"striker": "공격",
		"support": "지원",
		"treasure_hunter": "보물 추적"
	}.get(role_id, role_id))


func _combat_unit_objective_text(unit: Node, is_enemy: bool) -> String:
	if is_enemy:
		return root.display_name_for_instance(str(unit.goal_room)) if str(unit.goal_room) != "" else "왕좌 진입"
	var directive_status := "방 기본"
	if root.combat_scene != null and root.combat_scene.has_method("room_directive_status_for_unit"):
		directive_status = str(root.combat_scene.room_directive_status_for_unit(unit))
	return "%s · %s" % [directive_status, str(unit.intent_text)]


func build_combat_context_drawer(targeting_state: Dictionary = {}) -> void:
	var touch_ui := UISettings.is_touch_ui()
	var layout := V122CombatViewModelScript.design_layout_contract(UISettings.is_compact_layout(), touch_ui)
	var drawer_rect: Rect2 = layout.get("context_drawer", Rect2(1518, 96, 370, 756))
	var drawer := panel(drawer_rect, Color("#09070df8"), Color("#8d6a3a"), "CombatContextDrawer", "flat")
	drawer.name = "CombatContextDrawer"
	drawer.z_index = 120
	drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	label(drawer, "전투 상세", Vector2(18, 12), Vector2(640 if touch_ui else 250, 96 if touch_ui else 32), 26 if touch_ui else 22, Color("#fff0dc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	button(drawer, "닫기", Rect2(870, 10, 180, 100) if touch_ui else Rect2(282, 10, 70, 38), Callable(root, "_close_combat_context_drawer"), 20 if touch_ui else 13, "CombatContextClose")
	if str(targeting_state.get("command_id", "")) != "":
		_build_combat_targeting_drawer(drawer, targeting_state)
	elif touch_ui:
		_build_touch_combat_detail_drawer(drawer)
	else:
		_build_combat_detail_drawer(drawer)


func _build_combat_targeting_drawer(drawer: Control, targeting_state: Dictionary) -> void:
	var touch_ui := UISettings.is_touch_ui()
	var command_id := str(targeting_state.get("command_id", ""))
	var command_data := _v122_command_data(command_id)
	label(drawer, str(command_data.get("label", command_id)), Vector2(30, 120) if touch_ui else Vector2(18, 62), Vector2(1008, 54) if touch_ui else Vector2(334, 30), 24 if touch_ui else 20, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var target_type_label := _v122_target_type_label(str(command_data.get("target_type", "")))
	var instruction := "%s 하나를 직접 선택하세요. 전장 클릭 또는 아래 목록을 사용할 수 있습니다." % target_type_label
	if str(command_data.get("description", "")) != "":
		instruction += "\n%s" % str(command_data.get("description", ""))
	label(
		drawer,
		instruction,
		Vector2(30, 180) if touch_ui else Vector2(18, 96),
		Vector2(1008, 132) if touch_ui else Vector2(334, 108),
		18 if touch_ui else 13,
		Color("#d8d1df"),
		HORIZONTAL_ALIGNMENT_LEFT,
		"",
		UIFontScript.ROLE_BODY,
		VERTICAL_ALIGNMENT_TOP,
		TextServer.AUTOWRAP_WORD_SMART,
		3
	)
	var selected: Dictionary = targeting_state.get("target", {})
	var candidates: Array = targeting_state.get("candidates", [])
	if candidates.is_empty():
		label(drawer, "현재 선택 가능한 대상이 없습니다.", Vector2(30, 330) if touch_ui else Vector2(18, 214), Vector2(1008, 100) if touch_ui else Vector2(334, 48), 19 if touch_ui else 15, Color("#ff9d8f"), HORIZONTAL_ALIGNMENT_CENTER)
	var candidate_scroll := ScrollContainer.new()
	candidate_scroll.name = "CombatTargetCandidateScroll"
	candidate_scroll.position = Vector2(30, 330) if touch_ui else Vector2(18, 214)
	candidate_scroll.size = Vector2(1008, 370) if touch_ui else Vector2(334, 414)
	candidate_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	candidate_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	candidate_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	drawer.add_child(candidate_scroll)
	var candidate_grid := GridContainer.new()
	candidate_grid.name = "CombatTargetCandidateGrid"
	candidate_grid.columns = 2 if touch_ui else 1
	candidate_grid.custom_minimum_size.x = 1008 if touch_ui else 316
	candidate_grid.add_theme_constant_override("h_separation", 20 if touch_ui else 0)
	candidate_grid.add_theme_constant_override("v_separation", 10 if touch_ui else 6)
	candidate_scroll.add_child(candidate_grid)
	for index in range(mini(candidates.size(), 8)):
		var candidate_value = candidates[index]
		if not candidate_value is Dictionary:
			continue
		var candidate: Dictionary = candidate_value
		var target_type := str(candidate.get("type", ""))
		var target_id := str(candidate.get("id", ""))
		var is_selected := target_type == str(selected.get("type", "")) and target_id == str(selected.get("id", ""))
		var candidate_button := button(
			candidate_grid,
			"✓ %s" % str(candidate.get("label", target_id)) if is_selected else str(candidate.get("label", target_id)),
			Rect2(Vector2.ZERO, Vector2(494, 108) if touch_ui else Vector2(316, 50)),
			Callable(root, "_select_v122_command_target").bind(target_type, target_id),
			19 if touch_ui else 14,
			"CombatTarget_%d" % index
		)
		candidate_button.custom_minimum_size = Vector2(494, 108) if touch_ui else Vector2(316, 50)
		if is_selected:
			candidate_button.add_theme_stylebox_override("normal", style(Color("#312415f5"), Color("#ffd36a"), 3))
	label(
		drawer,
		"선택 대상 · %s" % (str(selected.get("label", selected.get("id", "미선택"))) if not selected.is_empty() else "미선택"),
		Vector2(30, 716) if touch_ui else Vector2(18, 638),
		Vector2(1008, 50) if touch_ui else Vector2(334, 32),
		18 if touch_ui else 14,
		Color("#fff2c9") if not selected.is_empty() else Color("#aaa1b5"),
		HORIZONTAL_ALIGNMENT_CENTER,
		"",
		UIFontScript.ROLE_EMPHASIS
	)
	var confirm_rect := Rect2(30, 774, 650, 108) if touch_ui else Rect2(18, 682, 206, 56)
	var cancel_rect := Rect2(700, 774, 338, 108) if touch_ui else Rect2(234, 682, 118, 56)
	var confirm_button := button(drawer, "대상 확정", confirm_rect, Callable(root, "_confirm_v122_command_target"), 22 if touch_ui else 16, "CombatTargetConfirm")
	confirm_button.disabled = selected.is_empty()
	button(drawer, "취소", cancel_rect, Callable(root, "_cancel_v122_command_targeting"), 21 if touch_ui else 15, "CombatTargetCancel")


func _v122_target_type_label(target_type: String) -> String:
	match target_type:
		"room":
			return "이동할 방"
		"enemy":
			return "우선 공격할 적"
		"facility":
			return "발동할 시설"
		_:
			return "대상"


func _build_touch_combat_detail_drawer(drawer: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "CombatContextTouchScroll"
	scroll.position = Vector2(18, 120)
	scroll.size = Vector2(1032, 762)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	drawer.add_child(scroll)
	var content := Control.new()
	content.name = "CombatContextTouchContent"
	content.custom_minimum_size = Vector2(1000, 2300)
	content.size = content.custom_minimum_size
	scroll.add_child(content)
	_build_combat_detail_drawer(content)
	_scale_touch_combat_drawer_contents(content, 2.7, 3.0)


func _scale_touch_combat_drawer_contents(node: Node, horizontal_scale: float, vertical_scale: float) -> void:
	for child in node.get_children():
		if not child is Control:
			continue
		var control := child as Control
		control.position = Vector2(control.position.x * horizontal_scale, control.position.y * vertical_scale)
		control.size = Vector2(control.size.x * horizontal_scale, control.size.y * vertical_scale)
		_scale_touch_combat_drawer_contents(control, horizontal_scale, vertical_scale)


func _build_combat_detail_drawer(drawer: Control) -> void:
	var unit_panel := child_panel(drawer, Rect2(18, 60, 334, 112), Color("#120f16ee"), Color("#403448"), 1)
	label(unit_panel, "선택 유닛", Vector2(12, 6), Vector2(310, 24), 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	if root.selected_unit != null and is_instance_valid(root.selected_unit):
		selected_unit_displayed_id = root.selected_unit.get_instance_id()
		label(unit_panel, "%s · HP %d/%d" % [root.selected_unit.display_name, root.selected_unit.hp, root.selected_unit.max_hp], Vector2(12, 32), Vector2(310, 26), 20, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		var status_text: String = str(root.selected_unit.status_line())
		if root.selected_unit.has_method("has_growth_preparation") and root.selected_unit.has_growth_preparation():
			status_text = "집중 준비 · %s | %s" % [root.selected_unit.growth_preparation_name, status_text]
		selected_unit_dynamic_labels["status"] = rich_label(unit_panel, status_text, Vector2(12, 60), Vector2(310, 44), 20, Color("#bfb7cc"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "", 2)
	else:
		label(unit_panel, "전장의 유닛을 선택하면 상태가 표시됩니다.", Vector2(12, 38), Vector2(310, 52), 18, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_CENTER)

	var directive_panel := child_panel(drawer, Rect2(18, 184, 334, 154), Color("#120f16ee"), Color("#403448"), 1)
	label(directive_panel, "지침", Vector2(12, 7), Vector2(310, 22), 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(directive_panel, "전체", Vector2(12, 38), Vector2(62, 34), 18, Color("#aaa1b5"))
	option_button(
		directive_panel,
		Rect2(78, 36, 244, 38),
		[
			{"label": "사수", "value": Constants.DIRECTIVE_DEFENSE},
			{"label": "총공격", "value": Constants.DIRECTIVE_ALL_OUT},
			{"label": "생존", "value": Constants.DIRECTIVE_SURVIVAL}
		],
		root.global_directive,
		Callable(root, "_set_global_directive"),
		20,
		"GLOBAL_DIRECTIVE_DEFEND"
	)
	label(directive_panel, "선택 방", Vector2(12, 91), Vector2(62, 34), 18, Color("#aaa1b5"))
	var room_directive_options: Array = root._room_directive_options(root.selected_room)
	var room_directive_button := option_button(
		directive_panel,
		Rect2(78, 89, 244, 38),
		room_directive_options,
		root.room_directives.get(root.selected_room, Constants.ROOM_DIRECTIVE_NONE),
		Callable(root, "_set_room_directive"),
		20
	)
	room_directive_button.name = "CombatSelectedRoomDirective"

	var special_panel := child_panel(drawer, Rect2(18, 350, 334, 208), Color("#120f16ee"), Color("#403448"), 1)
	label(special_panel, "특수 전력", Vector2(12, 7), Vector2(310, 22), 13, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var special_y := 34.0
	var heart: Dictionary = root.update3_active_run.get("heart", {}) if root.get("update3_active_run") is Dictionary else {}
	if str(heart.get("heart_id", "")) != "" and bool(heart.get("awakened", false)):
		var heart_names := {
			"heart_stonebone": "석골 심장",
			"heart_hungry_maw": "포식 심장",
			"heart_dream_lantern": "몽등 심장"
		}
		var charge := clampi(int(heart.get("charge", 0)), 0, 100)
		label(special_panel, "%s · %d/100" % [str(heart_names.get(str(heart.get("heart_id", "")), heart.get("heart_id", ""))), charge], Vector2(12, special_y), Vector2(192, 32), 13, Color("#f2d8e4"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		var heart_button := button(special_panel, "심장 발동", Rect2(210, special_y, 112, 34), Callable(root, "_activate_update3_heart"), 12, "CombatHeartActivate")
		heart_button.disabled = charge < 100 or bool(heart.get("active_used_this_battle", false)) or bool(heart.get("disabled_this_battle", false))
		special_y += 42.0
	var duo_state: Dictionary = root._update3_duo_link_hud_state() if root.has_method("_update3_duo_link_hud_state") else {}
	var equipped_links: Array = duo_state.get("equipped", [])
	for link_index in range(mini(2, equipped_links.size())):
		var link_id := str(equipped_links[link_index])
		var state: Dictionary = duo_state.get("states", {}).get(link_id, {})
		var charge := clampi(int(state.get("charge", 0)), 0, 100)
		label(special_panel, "%s · %d/100" % [str(duo_state.get("names", {}).get(link_id, link_id)), charge], Vector2(12, special_y), Vector2(192, 32), 12, Color("#d8eee5"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		var duo_button := button(special_panel, "합동기 발동", Rect2(210, special_y, 112, 34), Callable(root, "_activate_update3_duo_link").bind(link_id), 11, "CombatDuoActivate_%d" % link_index)
		duo_button.disabled = not bool(state.get("active", false)) or bool(state.get("used_this_battle", false)) or charge < 100
		special_y += 42.0
	if root.has_method("_update4_council_mode_active") and root._update4_council_mode_active() and bool(root.update4_active_run.get("upper_floor", {}).get("unlocked", false)):
		label(special_panel, "표시 층", Vector2(12, special_y), Vector2(84, 34), 12, Color("#cfc7d9"))
		button(special_panel, "1F", Rect2(104, special_y, 68, 34), Callable(root, "_select_update4_visible_floor").bind("1F"), 12, "CombatFloor1")
		button(special_panel, "2F", Rect2(180, special_y, 68, 34), Callable(root, "_select_update4_visible_floor").bind("2F"), 12, "CombatFloor2")
		special_y += 42.0
	if root.has_method("_facility_effect_status_lines"):
		for facility_line_value in root._facility_effect_status_lines():
			var facility_line := str(facility_line_value)
			if facility_line.find("무력화") < 0 and facility_line.find("비활성") < 0:
				continue
			label(special_panel, facility_line, Vector2(12, special_y), Vector2(310, 30), 11, Color("#ffab9f"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2)
			special_y += 34.0
			if special_y >= 176.0:
				break
	if special_y <= 34.0:
		label(special_panel, "현재 활성화된 심장·합동기·상층 전력이 없습니다.", Vector2(12, 62), Vector2(310, 54), 12, Color("#8f8798"), HORIZONTAL_ALIGNMENT_CENTER)

	var log_panel := child_panel(drawer, Rect2(18, 570, 334, 184), Color("#120f16ee"), Color("#403448"), 1)
	label(log_panel, "최근 전투 기록", Vector2(12, 7), Vector2(310, 22), 13, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var start_index := maxi(0, root.logs.size() - 4)
	for row_index in range(4):
		var log_index := start_index + row_index
		var log_text := str(root.logs[log_index]) if log_index < root.logs.size() else ""
		battle_log_labels.append(label(log_panel, log_text, Vector2(12, 34 + row_index * 34), Vector2(310, 30), 11, Color("#cfc7d9"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_BODY, VERTICAL_ALIGNMENT_CENTER, TextServer.AUTOWRAP_WORD_SMART, 2))

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
	var objective_label = selected_unit_dynamic_labels.get("objective")
	var status_label = selected_unit_dynamic_labels.get("status")
	if hp_label is Label and is_instance_valid(hp_label):
		hp_label.text = "%d / %d" % [root.selected_unit.hp, root.selected_unit.max_hp]
	if room_label is Label and is_instance_valid(room_label):
		room_label.text = str(root.rooms.get(root.selected_unit.current_room, {}).get("display_name", root.selected_unit.current_room))
	if state_label is Label and is_instance_valid(state_label):
		state_label.text = root.selected_unit.state_label()
	if objective_label is Label and is_instance_valid(objective_label):
		objective_label.text = _combat_unit_objective_text(root.selected_unit, str(root.selected_unit.faction) == Constants.FACTION_ENEMY)
	if status_label != null and is_instance_valid(status_label):
		var status_text: String = str(root.selected_unit.status_line())
		if root.selected_unit.has_method("has_growth_preparation") and root.selected_unit.has_growth_preparation():
			status_text = "집중 준비 · %s | %s" % [root.selected_unit.growth_preparation_name, status_text]
		status_label.text = status_text
	var skills_label = selected_unit_dynamic_labels.get("skills")
	if skills_label is RichTextLabel and is_instance_valid(skills_label):
		skills_label.text = _selected_unit_skill_summary(root.selected_unit)

func build_selected_unit_panel() -> void:
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
		label(unit_panel, "지시 기반 자동 전투", Vector2(42, 588), Vector2(286, 28), 17, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
		selected_unit_dynamic_labels["skills"] = rich_label(unit_panel, _selected_unit_skill_summary(root.selected_unit), Vector2(42, 626), Vector2(286, 94), 13, Color("#d8d1df"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART)

func _selected_unit_skill_summary(unit: Node) -> String:
	var lines: Array[String] = ["이동·공격·스킬은 현재 지시에 따라 자동 실행됩니다."]
	var skill_slots: Array = DataRegistry.monster(unit.unit_id).get("skill_slots", [])
	for skill_value in skill_slots:
		if skill_value == null:
			continue
		var skill_id := str(skill_value)
		var skill: Dictionary = DataRegistry.skill(skill_id)
		var cooldown := float(unit.skill_cooldowns.get(skill_id, 0.0))
		var state := "준비" if cooldown <= 0.05 else "%.1f초" % cooldown
		lines.append("• %s · %s" % [str(skill.get("display_name", skill_id)), state])
	return "\n".join(lines)

func build_command_panel() -> void:
	var command_panel = panel(Rect2(560, 884, 860, 142), Color("#100e14e8"), Color("#6e5630"), "", "flat")
	label(command_panel, "제한 명령 · 실제 대상", Vector2(0, 3), Vector2(860, 24), 14, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER, "", UIFontScript.ROLE_EMPHASIS)
	var command_specs := [
		{"id": "rally", "target_id": "GLOBAL_DIRECTIVE_DEFEND"},
		{"id": "focus", "target_id": "V122_COMMAND_FOCUS"},
		{"id": "activate_facility", "target_id": "V122_COMMAND_FACILITY"},
		{"id": "emergency_fallback", "target_id": "V122_COMMAND_FALLBACK"}
	]
	for index in range(command_specs.size()):
		var spec: Dictionary = command_specs[index]
		var command_id := str(spec.get("id", ""))
		var command_data := _v122_command_data(command_id)
		var command_button = button(
			command_panel,
			str(command_data.get("label", command_id)),
			Rect2(12 + index * 211, 28, 202, 46),
			Callable(root, "_issue_v122_command").bind(command_id),
			13,
			str(spec.get("target_id", ""))
		)
		command_button.tooltip_text = "%s 대상 · CP %d" % [
			str(command_data.get("target_type", "")),
			int(command_data.get("cost", 0))
		]
		v122_command_buttons[command_id] = command_button
	label(command_panel, "기존 방 지침", Vector2(8, 81), Vector2(136, 20), 12, Color("#aaa1b5"), HORIZONTAL_ALIGNMENT_CENTER)
	var focus_button = button(command_panel, "입구 봉쇄", Rect2(150, 82, 208, 48), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_ENTRY_BLOCK), 14, "ROOM_DIRECTIVE_ENTRY_BLOCK")
	var trap_button = button(command_panel, "함정 유도", Rect2(370, 82, 208, 48), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_TRAP_LURE), 14, "ROOM_DIRECTIVE_TRAP_LURE")
	var retreat_button = button(command_panel, "후퇴선 유지", Rect2(590, 82, 258, 48), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_RETREAT), 14, "ROOM_DIRECTIVE_RETREAT")
	focus_button.disabled = not _room_directive_available(Constants.ROOM_DIRECTIVE_ENTRY_BLOCK)
	trap_button.disabled = not _room_directive_available(Constants.ROOM_DIRECTIVE_TRAP_LURE)
	retreat_button.disabled = not _room_directive_available(Constants.ROOM_DIRECTIVE_RETREAT)
	_update_v122_command_controls()


func _v122_command_data(command_id: String) -> Dictionary:
	var model: Dictionary = root.get_meta("v122_combat_view_model", {})
	for value in model.get("commands", []):
		if value is Dictionary and str(value.get("id", "")) == command_id:
			return value
	return {}

func _room_directive_available(directive: String) -> bool:
	return root._room_directive_options(root.selected_room).any(func(option): return str(option.get("value", "")) == directive)

func build_speed_panel() -> void:
	var touch_ui := UISettings.is_touch_ui()
	var compact := UISettings.is_compact_layout()
	var layout := V122CombatViewModelScript.design_layout_contract(compact, touch_ui)
	var speed_rect: Rect2 = layout.get("speed_pause", Rect2(1438, 884, 120, 142))
	var speed_panel = panel(speed_rect, Color("#100e14dc"), Color("#3b3143"), "CombatSpeedPanel", "flat")
	speed_panel.name = "CombatSpeedPanel"
	var speed_buttons: Array[Button] = []
	if touch_ui:
		speed_buttons = [
			button(speed_panel, "x1", Rect2(8, 8, 116, 120), Callable(root, "_set_speed").bind(1.0), 18),
			button(speed_panel, "x1.5", Rect2(136, 8, 116, 120), Callable(root, "_set_speed").bind(1.5), 18),
			button(speed_panel, "x2", Rect2(8, 140, 116, 120), Callable(root, "_set_speed").bind(2.0), 18),
			button(speed_panel, "x3", Rect2(136, 140, 116, 120), Callable(root, "_set_speed").bind(3.0), 18, "CombatSpeed3x")
		]
	else:
		var gap := 6.0
		var cell_width := (speed_rect.size.x - 16.0 - gap) * 0.5
		var top_height := 32.0 if compact else 28.0
		var second_y := 8.0 + top_height + gap
		button(speed_panel, "x1", Rect2(8, 8, cell_width, top_height), Callable(root, "_set_speed").bind(1.0), 10)
		speed_buttons = [
			button(speed_panel, "x1.5", Rect2(8 + cell_width + gap, 8, cell_width, top_height), Callable(root, "_set_speed").bind(1.5), 9),
			button(speed_panel, "x2", Rect2(8, second_y, cell_width, top_height), Callable(root, "_set_speed").bind(2.0), 10),
			button(speed_panel, "x3", Rect2(8 + cell_width + gap, second_y, cell_width, top_height), Callable(root, "_set_speed").bind(3.0), 10, "CombatSpeed3x")
		]
	for speed_button in speed_buttons:
		if speed_button.text != "x1":
			speed_button.disabled = not root._combat_speed_unlocked()
		speed_button.tooltip_text = "튜토리얼 완료 후 사용할 수 있습니다." if speed_button.disabled else "전투 진행 속도를 변경합니다."
	if touch_ui:
		button(speed_panel, "일시정지", Rect2(8, 272, 244, 120), Callable(root, "_toggle_pause"), 18)
	else:
		var top_height := 32.0 if compact else 28.0
		var pause_y := 8.0 + top_height * 2.0 + 12.0
		button(speed_panel, "일시정지", Rect2(8, pause_y, speed_rect.size.x - 16.0, speed_rect.size.y - pause_y - 8.0), Callable(root, "_toggle_pause"), 10)

func build_mobile_combat_bar() -> void:
	selected_unit_dynamic_labels.clear()
	selected_unit_displayed_id = 0
	var action_panel = panel(Rect2(220, 610, 1480, 458), Color("#08060cf7"), Color("#ffd36a"), "MobileCombatBar", "flat")
	action_panel.name = "MobileCombatBar"
	var selected_monster: bool = root.selected_unit != null and is_instance_valid(root.selected_unit) and root.selected_unit.faction == Constants.FACTION_MONSTER
	var selected_name := "유닛을 탭하면 상태를 확인할 수 있습니다"
	var command_hint := "이동·공격·스킬은 지시에 따라 자동"
	if selected_monster:
		selected_unit_displayed_id = root.selected_unit.get_instance_id()
		selected_name = "%s · HP %d/%d" % [root.selected_unit.display_name, root.selected_unit.hp, root.selected_unit.max_hp]
	label(action_panel, selected_name, Vector2(24, 8), Vector2(650, 38), 24, Color("#fff7e6"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	label(action_panel, command_hint, Vector2(690, 8), Vector2(766, 38), 22, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_EMPHASIS)

	var command_specs := [
		{"id": "rally", "target_id": "GLOBAL_DIRECTIVE_DEFEND"},
		{"id": "focus", "target_id": "V122_COMMAND_FOCUS"},
		{"id": "activate_facility", "target_id": "V122_COMMAND_FACILITY"},
		{"id": "emergency_fallback", "target_id": "V122_COMMAND_FALLBACK"}
	]
	for index in range(command_specs.size()):
		var spec: Dictionary = command_specs[index]
		var command_id := str(spec.get("id", ""))
		var command_data := _v122_command_data(command_id)
		var command_button = button(
			action_panel,
			str(command_data.get("label", command_id)),
			Rect2(20 + index * 355, 54, 340, 112),
			Callable(root, "_issue_v122_command").bind(command_id),
			20,
			str(spec.get("target_id", ""))
		)
		command_button.tooltip_text = "%s 대상 · CP %d" % [
			str(command_data.get("target_type", "")),
			int(command_data.get("cost", 0))
		]
		v122_command_buttons[command_id] = command_button
	var focus_button = button(action_panel, "입구 봉쇄", Rect2(20, 178, 445, 88), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_ENTRY_BLOCK), 19, "ROOM_DIRECTIVE_ENTRY_BLOCK")
	var trap_button = button(action_panel, "함정 유도", Rect2(485, 178, 445, 88), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_TRAP_LURE), 19, "ROOM_DIRECTIVE_TRAP_LURE")
	var retreat_button = button(action_panel, "후퇴선 유지", Rect2(950, 178, 470, 88), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_RETREAT), 19, "ROOM_DIRECTIVE_RETREAT")
	button(action_panel, "x1", Rect2(20, 282, 260, 150), Callable(root, "_set_speed").bind(1.0), 22)
	var speed_buttons := [
		button(action_panel, "x1.5", Rect2(300, 282, 260, 150), Callable(root, "_set_speed").bind(1.5), 22),
		button(action_panel, "x2", Rect2(580, 282, 260, 150), Callable(root, "_set_speed").bind(2.0), 22),
		button(action_panel, "x3", Rect2(860, 282, 260, 150), Callable(root, "_set_speed").bind(3.0), 22, "CombatSpeed3x")
	]
	for speed_button in speed_buttons:
		speed_button.disabled = not root._combat_speed_unlocked()
		speed_button.tooltip_text = "튜토리얼 완료 후 사용할 수 있습니다." if speed_button.disabled else "전투 진행 속도를 변경합니다."
	button(action_panel, "일시정지", Rect2(1140, 282, 280, 150), Callable(root, "_toggle_pause"), 21)
	focus_button.disabled = not _room_directive_available(Constants.ROOM_DIRECTIVE_ENTRY_BLOCK)
	trap_button.disabled = not _room_directive_available(Constants.ROOM_DIRECTIVE_TRAP_LURE)
	retreat_button.disabled = not _room_directive_available(Constants.ROOM_DIRECTIVE_RETREAT)
	_update_v122_command_controls()

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
	# Panels are visual containers by default. Input-blocking screens and modals
	# must opt in with MOUSE_FILTER_STOP at their call site.
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var base_font_size := font_size
	if UISettings.is_touch_ui() and size.y >= 48.0:
		base_font_size = UISettings.touch_font_size(font_size, 22)
	var preferred_font_size = UISettings.scaled_font_size(base_font_size)
	result.add_theme_font_size_override("font_size", preferred_font_size)
	result.add_theme_color_override("font_color", color)
	parent.add_child(result)
	# Preferred text keeps the accessibility scale, but the fit floor must stay in
	# logical pixels. Scaling the floor as well made compact HUD rows impossible
	# to fit and caused their text to disappear at large/mobile text settings.
	var fitted_minimum = 9
	call_deferred("_fit_label_to_bounds", result, fitted_minimum, 0)
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
	var preferred_font_size = UISettings.scaled_font_size(UISettings.touch_font_size(font_size, 22))
	result.add_theme_font_size_override("normal_font_size", preferred_font_size)
	result.add_theme_color_override("default_color", color)
	parent.add_child(result)
	var fitted_minimum = 9
	call_deferred("_fit_rich_label_to_bounds", result, position, size, vertical_align, fitted_minimum, 0)
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
	if (too_tall or too_wide) and current_size > min_font_size and attempt < 48:
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
	if content_height > base_size.y + 1.0 and current_size > min_font_size and attempt < 48:
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

func button(
	parent: Control,
	text: String,
	rect: Rect2,
	callback: Callable,
	font_size: int = 21,
	target_id: String = "",
	grade: String = BUTTON_GRADE_LEGACY
) -> Button:
	var result = Button.new()
	result.text = text
	result.position = rect.position
	result.size = rect.size
	if target_id != "":
		result.name = target_id
	result.mouse_filter = Control.MOUSE_FILTER_STOP
	result.focus_mode = Control.FOCUS_NONE
	result.alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	var preferred_font_size = UISettings.scaled_font_size(UISettings.touch_font_size(font_size))
	result.add_theme_font_size_override("font_size", _fit_button_font_size(text, rect.size.x, preferred_font_size))
	if UISettings.is_touch_ui():
		result.add_theme_stylebox_override("normal", style(Color("#17111ff7"), Color("#d8a83f"), 3))
		result.add_theme_stylebox_override("hover", style(Color("#2d203af9"), Color("#ffe38a"), 4))
		result.add_theme_stylebox_override("pressed", style(Color("#5a3426fa"), Color("#fff2c9"), 4))
		result.add_theme_stylebox_override("disabled", style(Color("#100d14ef"), Color("#55495f"), 2))
		result.add_theme_constant_override("outline_size", 2)
		result.add_theme_color_override("font_outline_color", Color("#050407"))
	else:
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
	if grade != BUTTON_GRADE_LEGACY:
		apply_button_grade(result, grade)
	else:
		result.set_meta("ui_button_grade", BUTTON_GRADE_LEGACY)
		result.set_meta("ui_semantic_state", UI_STATE_DEFAULT)
	_connect_common_button_motion(result)
	_register_target(target_id, result)
	return result

func slider(parent: Control, rect: Rect2, value: float, callback: Callable, minimum: float = 0.0, maximum: float = 100.0, step: float = 1.0) -> HSlider:
	var result = HSlider.new()
	result.position = rect.position
	result.size = rect.size
	result.mouse_filter = Control.MOUSE_FILTER_STOP
	result.min_value = minimum
	result.max_value = maximum
	result.step = step
	result.value = value
	result.allow_greater = false
	result.allow_lesser = false
	var track = flat_style(Color("#1c1822"), Color("#57485e"), 1)
	var fill = flat_style(Color("#332744"), COLOR_ROUTE_PURPLE, 1)
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
	target_id: String = "",
	grade: String = BUTTON_GRADE_TACTICAL
) -> OptionButton:
	var result = OptionButton.new()
	result.position = rect.position
	result.size = rect.size
	if target_id != "":
		result.name = target_id
	result.mouse_filter = Control.MOUSE_FILTER_STOP
	result.focus_mode = Control.FOCUS_NONE
	result.fit_to_longest_item = false
	result.alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	result.add_theme_font_size_override("font_size", UISettings.scaled_font_size(UISettings.touch_font_size(font_size, 20)))
	if UISettings.is_touch_ui():
		result.add_theme_stylebox_override("normal", style(Color("#17111ff7"), Color("#d8a83f"), 3))
		result.add_theme_stylebox_override("hover", style(Color("#2d203af9"), Color("#ffe38a"), 4))
		result.add_theme_stylebox_override("pressed", style(Color("#5a3426fa"), Color("#fff2c9"), 4))
	else:
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
	popup.add_theme_font_size_override("font_size", UISettings.scaled_font_size(UISettings.touch_font_size(font_size, 20)))
	popup.add_theme_color_override("font_color", Color("#eee5f4"))
	popup.id_pressed.connect(_option_button_item_selected.bind(result, callback))
	parent.add_child(result)
	apply_button_grade(result, grade)
	_connect_common_button_motion(result)
	_register_target(target_id, result)
	return result

func _option_button_item_selected(index: int, menu: OptionButton, callback: Callable) -> void:
	if index < 0 or index >= menu.item_count:
		return
	callback.call(str(menu.get_item_metadata(index)))

func apply_button_grade(button_control: BaseButton, grade: String, semantic_state: String = UI_STATE_DEFAULT) -> void:
	if button_control == null:
		return
	var resolved_grade := grade if grade in [
		BUTTON_GRADE_PRIMARY,
		BUTTON_GRADE_TACTICAL,
		BUTTON_GRADE_UTILITY,
		BUTTON_GRADE_DANGER
	] else BUTTON_GRADE_TACTICAL
	button_control.set_meta("ui_button_grade", resolved_grade)
	button_control.set_meta("ui_semantic_state", UI_STATE_DEFAULT)
	if UISettings.is_touch_ui():
		return
	match resolved_grade:
		BUTTON_GRADE_PRIMARY:
			button_control.add_theme_stylebox_override("normal", button_style("normal"))
			button_control.add_theme_stylebox_override("hover", button_style("hover"))
			button_control.add_theme_stylebox_override("pressed", button_style("pressed"))
			button_control.add_theme_stylebox_override("disabled", flat_style(Color("#100d14d6"), Color("#55495f"), 1))
			button_control.add_theme_stylebox_override("focus", flat_style(Color("#00000000"), COLOR_BRIGHT_GOLD, 2))
			button_control.add_theme_color_override("font_color", COLOR_BRIGHT_GOLD)
			button_control.add_theme_color_override("font_hover_color", Color("#fff0bd"))
			button_control.add_theme_color_override("font_pressed_color", Color("#ffffff"))
		BUTTON_GRADE_UTILITY:
			button_control.add_theme_stylebox_override("normal", flat_style(Color("#0d0b1270"), Color("#403747"), 1))
			button_control.add_theme_stylebox_override("hover", flat_style(Color("#17131fd6"), Color("#72627f"), 1))
			button_control.add_theme_stylebox_override("pressed", flat_style(Color("#211a29e8"), COLOR_ROUTE_PURPLE, 2))
			button_control.add_theme_stylebox_override("disabled", flat_style(Color("#0a090e66"), Color("#342d3a"), 1))
			button_control.add_theme_stylebox_override("focus", flat_style(Color("#00000000"), COLOR_BRIGHT_GOLD, 2))
			button_control.add_theme_color_override("font_color", Color("#d8d0df"))
			button_control.add_theme_color_override("font_hover_color", COLOR_TEXT)
			button_control.add_theme_color_override("font_pressed_color", Color("#ead9ff"))
		BUTTON_GRADE_DANGER:
			button_control.add_theme_stylebox_override("normal", flat_style(Color("#261015e8"), Color("#7c3942"), 2))
			button_control.add_theme_stylebox_override("hover", flat_style(Color("#37151df2"), COLOR_DANGER, 2))
			button_control.add_theme_stylebox_override("pressed", flat_style(Color("#4a1821f5"), Color("#ff9b9f"), 3))
			button_control.add_theme_stylebox_override("disabled", flat_style(Color("#140d10aa"), Color("#493038"), 1))
			button_control.add_theme_stylebox_override("focus", flat_style(Color("#00000000"), COLOR_DANGER, 2))
			button_control.add_theme_color_override("font_color", Color("#f4c7c9"))
			button_control.add_theme_color_override("font_hover_color", Color("#ffe5e6"))
			button_control.add_theme_color_override("font_pressed_color", Color("#ffffff"))
		_:
			button_control.add_theme_stylebox_override("normal", flat_style(Color("#17131fe8"), COLOR_LINE, 1))
			button_control.add_theme_stylebox_override("hover", flat_style(Color("#21192af2"), COLOR_ROUTE_PURPLE, 2))
			button_control.add_theme_stylebox_override("pressed", flat_style(Color("#2b2140f5"), Color("#b99be0"), 2))
			button_control.add_theme_stylebox_override("disabled", flat_style(Color("#0d0b12b8"), Color("#403747"), 1))
			button_control.add_theme_stylebox_override("focus", flat_style(Color("#00000000"), COLOR_BRIGHT_GOLD, 2))
			button_control.add_theme_color_override("font_color", Color("#eee5f4"))
			button_control.add_theme_color_override("font_hover_color", Color("#ffffff"))
			button_control.add_theme_color_override("font_pressed_color", Color("#ead9ff"))
	button_control.add_theme_color_override("font_disabled_color", Color("#756a82"))
	if semantic_state != UI_STATE_DEFAULT:
		apply_button_state(button_control, semantic_state)

func apply_button_state(button_control: BaseButton, semantic_state: String) -> void:
	if button_control == null:
		return
	var grade := str(button_control.get_meta("ui_button_grade", BUTTON_GRADE_TACTICAL))
	apply_button_grade(button_control, grade, UI_STATE_DEFAULT)
	button_control.set_meta("ui_semantic_state", semantic_state)
	match semantic_state:
		UI_STATE_SELECTED:
			button_control.add_theme_stylebox_override("normal", flat_style(Color("#2b2140f5"), COLOR_ROUTE_PURPLE, 2))
			button_control.add_theme_stylebox_override("hover", flat_style(Color("#35274af8"), Color("#b99be0"), 2))
			button_control.add_theme_color_override("font_color", Color("#f2e5ff"))
		UI_STATE_VALID, UI_STATE_SUCCESS:
			button_control.add_theme_stylebox_override("normal", flat_style(Color("#10261fe8"), COLOR_SUCCESS, 3))
			button_control.add_theme_stylebox_override("hover", flat_style(Color("#16352bf2"), Color("#7be0b6"), 3))
			button_control.add_theme_color_override("font_color", Color("#d9ffed"))
		UI_STATE_INVALID, UI_STATE_ERROR:
			button_control.add_theme_stylebox_override("normal", flat_style(Color("#2a1117e8"), COLOR_DANGER, 3))
			button_control.add_theme_stylebox_override("hover", flat_style(Color("#3a171ff2"), Color("#ff9b9f"), 3))
			button_control.add_theme_color_override("font_color", Color("#ffe3e4"))
		_:
			button_control.set_meta("ui_semantic_state", UI_STATE_DEFAULT)

func _connect_common_button_motion(button_control: BaseButton) -> void:
	if UISettings.is_touch_ui() or button_control.has_meta("ui_motion_connected"):
		return
	button_control.set_meta("ui_motion_connected", true)
	button_control.mouse_entered.connect(_animate_common_button_hover.bind(button_control, true))
	button_control.mouse_exited.connect(_animate_common_button_hover.bind(button_control, false))

func _animate_common_button_hover(button_control: BaseButton, hovered: bool) -> void:
	if button_control == null or not is_instance_valid(button_control):
		return
	var target_color := Color(1.06, 1.06, 1.06, 1.0) if hovered and not button_control.disabled else Color.WHITE
	var tween := button_control.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button_control, "modulate", target_color, 0.08)

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
	if UISettings.is_touch_ui():
		label(chip, title, Vector2(58, 14), Vector2(62, 32), 12, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_LEFT)
		return label(chip, value, Vector2(120, 12), Vector2(rect.size.x - 136, 36), 16, accent, HORIZONTAL_ALIGNMENT_RIGHT)
	if UISettings.is_compact_layout():
		label(chip, title, Vector2(0, 6), Vector2(rect.size.x, 18), 14, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
		return label(chip, value, Vector2(0, 24), Vector2(rect.size.x, 24), 18, accent, HORIZONTAL_ALIGNMENT_CENTER)
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

func _fit_button_font_size(text: String, width: float, preferred_font_size: int) -> int:
	if UISettings.is_touch_ui():
		var font = UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON)
		var minimum_font_size := UISettings.scaled_font_size(UISettings.touch_font_size(16, 18))
		var available_width := maxf(1.0, width - 24.0)
		var fitted_font_size := preferred_font_size
		while fitted_font_size > minimum_font_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted_font_size).x > available_width:
			fitted_font_size -= 1
		return fitted_font_size
	var glyph_budget = max(4, int(width / 12.0))
	if text.length() > glyph_budget + 6:
		return mini(preferred_font_size, 16)
	if text.length() > glyph_budget + 2:
		return mini(preferred_font_size, 18)
	return mini(preferred_font_size, 21)

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
