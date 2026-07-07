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

func setup(game_root: Node) -> void:
	root = game_root

func clear() -> void:
	for child in root.ui_layer.get_children():
		child.queue_free()

func build_top_bar() -> void:
	_resource_chip(Rect2(16, 10, 250, 62), "금화", "%d" % GameState.gold, "+%d/분" % GameState.gold_income, Color("#ffd36a"))
	_resource_chip(Rect2(278, 10, 250, 62), "마력", "%d" % GameState.mana, "+%d/분" % GameState.mana_income, Color("#67b7ff"))
	_resource_chip(Rect2(540, 10, 250, 62), "식량", "%d/30" % GameState.food, "+%d/분" % GameState.food_income, Color("#d8a77f"))
	_resource_chip(Rect2(802, 10, 250, 62), "악명", "%d" % GameState.infamy, "+%d/일" % GameState.infamy_income, Color("#be72ff"))
	var day_panel = panel(Rect2(1184, 10, 185, 62), Color("#0d0b10e8"), Color("#6e5630"), "", "resource_small")
	label(day_panel, "DAY %02d  밤" % GameState.day, Vector2(54, 24), Vector2(104, 22), 15, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER)
	var hp_panel = panel(Rect2(1400, 10, 486, 62), Color("#0d0b10e8"), Color("#6e5630"), "BossHpBar", "hp")
	label(hp_panel, "마왕성 체력  %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp], Vector2(84, 18), Vector2(372, 18), 14, Color("#f7d7dd"), HORIZONTAL_ALIGNMENT_CENTER)
	_stat_bar(hp_panel, Rect2(94, 42, 352, 9), float(GameState.demon_lord_hp) / float(max(1, GameState.demon_lord_max_hp)), Color("#e04455"), Color("#4b111a"))

func build_room_list(x: int, y: int, w: int, h: int) -> void:
	var room_panel = panel(Rect2(x, y, w, h), Color("#0e0d12e8"))
	label(room_panel, "시설 배치", Vector2(0, 12), Vector2(w, 32), 24, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	var order = ["entrance", "throne", "barracks", "recovery", "treasure", "slot_01"]
	var row_y = 54
	var row_height = 40 if h < 420 else 48
	var row_gap = 47 if h < 420 else 58
	for room_id in order:
		if not root.rooms.has(room_id):
			continue
		var room = root.rooms[room_id]
		var text = "      %s   %s" % [room.get("display_name", room_id), DirectiveManager.directive_label(root.room_directives.get(room_id, "none"))]
		var row_rect = Rect2(16, row_y, w - 32, row_height)
		var room_button = button(room_panel, text, row_rect, Callable(root, "_select_room").bind(room_id), 16, "ROOM_LIST_%s" % room_id.to_upper())
		if room_id == root.selected_room:
			room_button.add_theme_stylebox_override("normal", style(Color("#2a1a37ee"), Color("#c789ff"), 2))
		texture(room_panel, _room_icon_path(room), Rect2(26, row_y + 6, 34, 34))
		row_y += row_gap

func build_unit_status_panel() -> void:
	var status_panel = panel(Rect2(20, 500, 360, 200), Color("#0b0b0fe8"))
	label(status_panel, "전장 상태", Vector2(18, 10), Vector2(320, 28), 22, Color("#f4e7d2"))
	label(status_panel, "아군", Vector2(18, 44), Vector2(150, 24), 17, Color("#9eea9e"))
	label(status_panel, "침입자", Vector2(184, 44), Vector2(150, 24), 17, Color("#ff9d8f"))
	_build_unit_status_column(status_panel, root.monster_units, Vector2(18, 72), 3, Color("#c9f2c9"))
	_build_unit_status_column(status_panel, root.enemy_units, Vector2(184, 72), 4, Color("#ffd1c9"))

func build_selected_room_info(parent: Control) -> void:
	var room = root.rooms.get(root.selected_room, {})
	label(parent, room.get("display_name", root.selected_room), Vector2(24, 76), Vector2(320, 42), 31, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	texture(parent, _room_icon_path(room), Rect2(116, 126, 140, 140))
	label(parent, "용도: %s" % _room_type_label(room.get("type", "")), Vector2(30, 286), Vector2(300, 30), 21, Color("#cfc7d9"))
	label(parent, "HP: %d / 최대 배치 %d" % [int(room.get("hp", 0)), int(room.get("max_monsters", 0))], Vector2(30, 320), Vector2(300, 30), 21, Color("#cfc7d9"))
	label(parent, "방 지침: %s" % DirectiveManager.directive_label(root.room_directives.get(root.selected_room, "none")), Vector2(30, 360), Vector2(300, 30), 21, Color("#d99bff"))
	label(parent, "연결: %s" % ", ".join(room.get("exits", [])), Vector2(30, 410), Vector2(300, 64), 17, Color("#998fa8"))
	label(parent, "시설 변경", Vector2(30, 482), Vector2(300, 26), 20, Color("#ffd36a"))
	if root._can_change_room_facility(root.selected_room):
		var choices: Array = root._facility_choices()
		var current_facility = str(room.get("facility_role", ""))
		var positions = [
			Rect2(28, 516, 96, 36),
			Rect2(136, 516, 96, 36),
			Rect2(244, 516, 96, 36),
			Rect2(28, 558, 96, 36),
			Rect2(136, 558, 96, 36)
		]
		for i in range(min(choices.size(), positions.size())):
			var facility_id = str(choices[i])
			var facility_button = button(parent, root._facility_short_label(facility_id), positions[i], Callable(root, "_change_selected_room_facility").bind(facility_id), 14)
			if current_facility == facility_id:
				facility_button.disabled = true
				facility_button.add_theme_stylebox_override("disabled", style(Color("#2b2340ee"), Color("#ffd36a"), 2))
				facility_button.add_theme_color_override("font_disabled_color", Color("#ffd36a"))
		label(parent, "병영 금화100/식량2 | 보물고 금화120 | 회복 마력80", Vector2(30, 600), Vector2(300, 18), 12, Color("#bfb7cc"))
		label(parent, "감시 금화100/마력50 | 빈 슬롯 무료", Vector2(30, 618), Vector2(300, 18), 12, Color("#bfb7cc"))
	else:
		label(parent, "입구, 가시 복도, 중앙 통로, 왕좌의 방은 고정 시설입니다.", Vector2(30, 520), Vector2(300, 52), 16, Color("#bfb7cc"))
	label(parent, "방 지침", Vector2(30, 646), Vector2(300, 24), 18, Color("#f4e7d2"))
	button(parent, "입구 봉쇄", Rect2(28, 674, 145, 34), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_ENTRY_BLOCK), 15, "ROOM_DIRECTIVE_BLOCK_ENTRANCE")
	button(parent, "함정 유도", Rect2(190, 674, 145, 34), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_TRAP_LURE), 15, "ROOM_DIRECTIVE_TRAP_LURE")
	button(parent, "후퇴 유도", Rect2(28, 716, 145, 34), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_RETREAT), 15, "ROOM_DIRECTIVE_RETREAT_LINE")
	button(parent, "기본", Rect2(190, 716, 145, 34), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_NONE), 15)

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
	var log_panel = panel(Rect2(20, 710, 360, 288), Color("#0b0b0fe8"), Color("#3b3143"), "BattleLogPanel", "dark")
	label(log_panel, "전투 로그", Vector2(18, 14), Vector2(320, 30), 23, Color("#f4e7d2"))
	var y = 56
	for message in root.logs:
		label(log_panel, message, Vector2(18, y), Vector2(315, 26), 15, Color("#cfc7d9"))
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
	label(unit_panel, "상태  %s" % root.selected_unit.state_label(), Vector2(36, 520), Vector2(300, 28), 21, Color("#ffd36a"))
	label(unit_panel, root.selected_unit.status_line(), Vector2(36, 548), Vector2(300, 44), 16, Color("#bfb7cc"))
	if root.selected_unit.faction == Constants.FACTION_MONSTER:
		button(unit_panel, "직접 조종", Rect2(36, 604, 136, 52), Callable(root, "_enable_direct_control"), 18, "DirectControlButton")
		button(unit_panel, "AI 복귀", Rect2(196, 604, 136, 52), Callable(root, "_release_direct_control"), 18)
		button(unit_panel, "스킬 1", Rect2(36, 668, 136, 42), Callable(root, "_use_selected_skill").bind(0), 17, "SkillSlot0")
		button(unit_panel, "스킬 2", Rect2(196, 668, 136, 42), Callable(root, "_use_selected_skill").bind(1), 17, "SkillSlot1")

func build_command_panel() -> void:
	var command_panel = panel(Rect2(560, 884, 860, 142), Color("#100e14e8"), Color("#6e5630"))
	label(command_panel, "전체 지침", Vector2(0, 8), Vector2(430, 26), 18, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	label(command_panel, "방 지침", Vector2(430, 8), Vector2(430, 26), 18, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	button(command_panel, "사수", Rect2(36, 48, 120, 66), Callable(root, "_set_global_directive").bind(Constants.DIRECTIVE_DEFENSE), 17, "GLOBAL_DIRECTIVE_DEFEND")
	button(command_panel, "총공격", Rect2(170, 48, 120, 66), Callable(root, "_set_global_directive").bind(Constants.DIRECTIVE_ALL_OUT), 17)
	button(command_panel, "생존 우선", Rect2(304, 48, 130, 66), Callable(root, "_set_global_directive").bind(Constants.DIRECTIVE_SURVIVAL), 16)
	button(command_panel, "함정 유도", Rect2(496, 48, 136, 66), Callable(root, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_TRAP_LURE), 16, "ROOM_DIRECTIVE_TRAP_LURE")
	button(command_panel, "직접 조종", Rect2(648, 48, 136, 66), Callable(root, "_enable_direct_control"), 16, "DirectControlButton")

func build_speed_panel() -> void:
	var speed_panel = panel(Rect2(1438, 884, 74, 142), Color("#100e14e8"))
	button(speed_panel, "x1", Rect2(9, 12, 56, 34), Callable(root, "_set_speed").bind(1.0), 14)
	button(speed_panel, "x1.5", Rect2(9, 54, 56, 34), Callable(root, "_set_speed").bind(1.5), 13)
	button(speed_panel, "II", Rect2(9, 96, 56, 34), Callable(root, "_toggle_pause"), 14)

func _build_unit_status_column(parent: Control, units: Array, origin: Vector2, max_rows: int, color: Color) -> void:
	var y = origin.y
	var shown = 0
	for unit in units:
		if shown >= max_rows:
			break
		if unit == null or not is_instance_valid(unit):
			continue
		var hp_ratio = clamp(float(unit.hp) / float(max(1, unit.max_hp)), 0.0, 1.0)
		var hp_text = "%d%%" % int(round(hp_ratio * 100.0))
		var line_color = color
		if not unit.is_alive():
			line_color = Color("#8a8090")
		elif hp_ratio <= 0.35:
			line_color = Color("#ff9d7a")
		var name_text = "%s  %s" % [unit.display_name, hp_text]
		label(parent, name_text, origin + Vector2(0, y - origin.y), Vector2(160, 18), 14, line_color)
		label(parent, unit.status_line(), origin + Vector2(0, y - origin.y + 18), Vector2(160, 24), 12, Color("#aaa1b5"))
		y += 42
		shown += 1
	if shown == 0:
		label(parent, "-", origin, Vector2(160, 28), 16, Color("#766d7f"), HORIZONTAL_ALIGNMENT_CENTER)

func panel(rect: Rect2, color: Color, border: Color = Color("#3b3143"), target_id: String = "", skin_id: String = "panel") -> Panel:
	var result = Panel.new()
	result.position = rect.position
	result.size = rect.size
	result.add_theme_stylebox_override("panel", panel_style(skin_id, color, border, 2))
	root.ui_layer.add_child(result)
	_register_target(target_id, result)
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
	max_lines: int = 0
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
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	parent.add_child(result)
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
	target_id: String = ""
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
	result.add_theme_font_size_override("normal_font_size", font_size)
	result.add_theme_color_override("default_color", color)
	parent.add_child(result)
	if vertical_align != VERTICAL_ALIGNMENT_TOP:
		call_deferred("_align_rich_label_vertically", result, position, size, vertical_align, 0)
	_register_target(target_id, result)
	return result

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
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	result.add_theme_font_size_override("font_size", min(font_size, _fit_button_font_size(text, rect.size.x)))
	result.add_theme_stylebox_override("normal", button_style("normal"))
	result.add_theme_stylebox_override("hover", button_style("hover"))
	result.add_theme_stylebox_override("pressed", button_style("pressed"))
	result.add_theme_stylebox_override("disabled", button_style("disabled"))
	result.add_theme_color_override("font_color", Color("#eee5f4"))
	result.add_theme_color_override("font_hover_color", Color("#ffffff"))
	result.add_theme_color_override("font_pressed_color", Color("#d9c0ff"))
	result.add_theme_color_override("font_disabled_color", Color("#756a82"))
	result.pressed.connect(callback)
	parent.add_child(result)
	_register_target(target_id, result)
	return result

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
		"resource", "resource_small", "hp":
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
	var image = Image.new()
	var err = image.load(path)
	if err != OK and path.begins_with("res://"):
		err = image.load(ProjectSettings.globalize_path(path))
	if err == OK:
		var texture = ImageTexture.create_from_image(image)
		skin_texture_cache[path] = texture
		return texture
	var loaded = ResourceLoader.load(path)
	if loaded is Texture2D:
		skin_texture_cache[path] = loaded
		return loaded
	push_warning("Could not load UI skin texture: %s" % path)
	skin_texture_cache[path] = null
	return null

func _resource_chip(rect: Rect2, title: String, value: String, delta: String, accent: Color) -> void:
	var chip = panel(rect, Color("#0d0b10e8"), Color("#6e5630"), "", "resource")
	label(chip, "%s %s  %s" % [title, value, delta], Vector2(58, 23), Vector2(168, 20), 13, accent, HORIZONTAL_ALIGNMENT_CENTER)

func _stat_bar(parent: Control, rect: Rect2, ratio: float, fill: Color, back: Color) -> void:
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
