class_name V20InformationHUD
extends Control

signal action_requested(action_id: String)

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const PlacementBoardScene = preload("res://scenes/v20/placement/V20PlacementBoard.tscn")
const MODE_MANAGEMENT := "management"
const MODE_COMBAT := "combat"
const PRIMARY_ACTION_GROUP := "v20_primary_action"
const TACTICAL_COMMAND_GROUP := "v20_tactical_command"

const COLOR_VOID := Color("#08070dcc")
const COLOR_PANEL := Color("#100e16f2")
const COLOR_PANEL_SOFT := Color("#17131fe8")
const COLOR_LINE := Color("#5f536a")
const COLOR_GOLD := Color("#e8bb58")
const COLOR_GOLD_BRIGHT := Color("#ffe4a0")
const COLOR_TEXT := Color("#f3eadc")
const COLOR_MUTED := Color("#bdb3c6")
const COLOR_DANGER := Color("#e56a72")
const COLOR_ROUTE := Color("#9e7bd1")

var screen_mode := MODE_MANAGEMENT
var view_state: Dictionary = {}
var drawer_open := false
var _rebuild_queued := false
var placement_board


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_queue_rebuild)


func setup(mode_value: String, state_value: Dictionary) -> void:
	screen_mode = mode_value if mode_value in [MODE_MANAGEMENT, MODE_COMBAT] else MODE_MANAGEMENT
	view_state = state_value.duplicate(true)
	drawer_open = bool(view_state.get("drawer_open", false))
	_rebuild()


func set_context_drawer(open_value: bool, context: Dictionary = {}) -> void:
	drawer_open = open_value
	if not context.is_empty():
		view_state["context"] = context.duplicate(true)
	_rebuild()


func set_command_state(command_rows: Array, command_points: int, command_max: int) -> void:
	view_state["commands"] = command_rows.duplicate(true)
	view_state["command_points"] = command_points
	view_state["command_max"] = command_max
	_rebuild()


func show_placement_board(placement_state: Dictionary, facilities: Dictionary) -> Control:
	var workspace: Control = get_node_or_null("StrategyBoardWorkspace")
	if workspace == null:
		return null
	placement_board = PlacementBoardScene.instantiate()
	placement_board.name = "PlacementBoard"
	placement_board.position = Vector2(8, 42)
	placement_board.size = Vector2(workspace.size.x - 16, workspace.size.y - 82)
	workspace.add_child(placement_board)
	placement_board.setup(placement_state, facilities)
	return placement_board


func layout_rects_for_viewport(viewport_size: Vector2, mode_value: String = "", drawer_value: bool = false) -> Dictionary:
	var width := maxf(960.0, viewport_size.x)
	var height := maxf(540.0, viewport_size.y)
	var margin := clampf(width * 0.015625, 15.0, 30.0)
	var gap := clampf(width * 0.009375, 9.0, 18.0)
	var top_height := clampf(height * (0.10 if mode_value == MODE_COMBAT else 0.0833), 68.0 if mode_value == MODE_COMBAT else 54.0, 96.0 if mode_value == MODE_COMBAT else 80.0)
	var bottom_height := clampf(height * (0.12 if mode_value == MODE_COMBAT else 0.105), 68.0, 118.0)
	var top_y := margin
	var content_y := top_y + top_height + gap
	var bottom_y := height - margin - bottom_height
	var content_height := maxf(240.0, bottom_y - gap - content_y)
	var drawer_width := clampf(width * 0.245, 280.0, 390.0) if drawer_value else 0.0
	var workspace_width := width - margin * 2.0 - drawer_width - (gap if drawer_value else 0.0)
	var result := {
		"workspace": Rect2(margin, content_y, workspace_width, content_height),
		"bottom": Rect2(margin, bottom_y, width - margin * 2.0, bottom_height)
	}
	if drawer_value:
		result["drawer"] = Rect2(margin + workspace_width + gap, content_y, drawer_width, content_height)
	if mode_value == MODE_COMBAT:
		var objective_width := clampf(width * 0.42, 400.0, 720.0)
		result["objective"] = Rect2(margin, top_y, objective_width, top_height)
		result["pattern"] = Rect2(margin + objective_width + gap, top_y, width - margin * 2.0 - objective_width - gap, top_height)
		var speed_width := clampf(width * 0.235, 270.0, 410.0)
		result["commands"] = Rect2(margin, bottom_y, width - margin * 2.0 - speed_width - gap, bottom_height)
		result["speed"] = Rect2(width - margin - speed_width, bottom_y, speed_width, bottom_height)
	else:
		var day_width := clampf(width * 0.105, 116.0, 190.0)
		var resources_width := clampf(width * 0.285, 330.0, 520.0)
		result["intrusion"] = Rect2(margin, top_y, width - margin * 2.0 - day_width - resources_width - gap * 2.0, top_height)
		result["resources"] = Rect2(result["intrusion"].end.x + gap, top_y, resources_width, top_height)
		result["day"] = Rect2(width - margin - day_width, top_y, day_width, top_height)
		var actions_width := minf(820.0, width - margin * 2.0)
		result["actions"] = Rect2((width - actions_width) * 0.5, bottom_y, actions_width, bottom_height)
	return result


func _queue_rebuild() -> void:
	if _rebuild_queued or not is_node_ready() or view_state.is_empty():
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _rebuild() -> void:
	_rebuild_queued = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if size.x < 10.0 or size.y < 10.0:
		return
	if screen_mode == MODE_COMBAT:
		_build_combat()
	else:
		_build_management()


func _build_management() -> void:
	var rects := layout_rects_for_viewport(size, MODE_MANAGEMENT, drawer_open)
	var intrusion := _panel("IntrusionBrief", rects["intrusion"], COLOR_PANEL, COLOR_GOLD)
	_label(intrusion, "오늘의 침입", Vector2(18, 7), Vector2(intrusion.size.x - 36, 21), 13, COLOR_GOLD, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(intrusion, str(view_state.get("intrusion_title", "정찰 정보 준비 중")), Vector2(18, 27), Vector2(intrusion.size.x - 36, 25), 18, COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(intrusion, str(view_state.get("intrusion_hint", "목표와 예상 경로를 확인하세요.")), Vector2(18, 42), Vector2(intrusion.size.x - 36, maxf(12.0, intrusion.size.y - 46.0)), 9, COLOR_MUTED)

	var resources := _panel("BuildResources", rects["resources"], COLOR_PANEL, COLOR_LINE)
	var resource_data: Dictionary = view_state.get("resources", {})
	_build_stat(resources, "건설", str(resource_data.get("build", resource_data.get("gold", 0))), 0.0, COLOR_GOLD)
	_build_stat(resources, "명령력", "%s / %s" % [str(resource_data.get("command", 0)), str(resource_data.get("command_max", 3))], resources.size.x * 0.5, COLOR_ROUTE)

	var day_panel := _panel("DayBadge", rects["day"], COLOR_PANEL, COLOR_GOLD)
	_label(day_panel, "DAY %02d" % int(view_state.get("day", 1)), Vector2.ZERO, day_panel.size, 18, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)

	var workspace := _panel("StrategyBoardWorkspace", rects["workspace"], Color("#09081073"), Color("#3f3548"))
	_label(workspace, "전략 보드", Vector2(18, 12), Vector2(180, 26), 15, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(workspace, str(view_state.get("board_hint", "방·문·경로를 지도에서 직접 선택")), Vector2(18, workspace.size.y - 38), Vector2(workspace.size.x - 36, 24), 12, COLOR_MUTED)
	_build_route_guide(workspace)

	var bottom := _panel("ManagementActionDock", rects["actions"], COLOR_PANEL, COLOR_LINE)
	var action_gap := 8.0
	var side_width := (bottom.size.x - action_gap * 4.0) * 0.16
	var start_width := bottom.size.x - side_width * 3.0 - action_gap * 4.0
	var button_height := bottom.size.y - 16.0
	var button_y := 8.0
	var x := action_gap
	_action_button(bottom, "건설", Rect2(x, button_y, side_width, button_height), "build", false)
	x += side_width + action_gap
	_action_button(bottom, "몬스터", Rect2(x, button_y, side_width, button_height), "monsters", false)
	x += side_width + action_gap
	_action_button(bottom, "AI 교리", Rect2(x, button_y, side_width, button_height), "doctrine", false)
	x += side_width + action_gap
	_action_button(bottom, "방어 시작", Rect2(x, button_y, start_width, button_height), "start_defense", true)

	if drawer_open:
		_build_context_drawer(rects["drawer"], "management")


func _build_combat() -> void:
	var rects := layout_rects_for_viewport(size, MODE_COMBAT, drawer_open)
	var objective := _panel("CoreObjective", rects["objective"], COLOR_PANEL, COLOR_DANGER)
	_label(objective, str(view_state.get("objective_label", "왕좌 방어")), Vector2(18, 7), Vector2(objective.size.x * 0.45, 22), 13, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	var hp_value := int(view_state.get("objective_hp", 100))
	var hp_max := maxi(1, int(view_state.get("objective_hp_max", 100)))
	_label(objective, "%d / %d" % [hp_value, hp_max], Vector2(objective.size.x * 0.54, 7), Vector2(objective.size.x * 0.41, 22), 14, COLOR_TEXT, HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	_progress(objective, Rect2(18, 36, objective.size.x - 36, 10), float(hp_value) / float(hp_max), COLOR_DANGER)
	_label(objective, str(view_state.get("phase_label", "1단계 · 정면 침입")), Vector2(18, 47), Vector2(objective.size.x - 36, maxf(11.0, objective.size.y - 50.0)), 9, COLOR_MUTED)

	var pattern := _panel("NextPattern", rects["pattern"], COLOR_PANEL, COLOR_GOLD)
	_label(pattern, "다음 특수 패턴", Vector2(18, 7), Vector2(pattern.size.x - 150, 20), 13, COLOR_GOLD, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(pattern, str(view_state.get("pattern_eta", "5.0초")), Vector2(pattern.size.x - 130, 7), Vector2(112, 20), 14, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	_label(pattern, str(view_state.get("pattern_title", "예고 없음")), Vector2(18, 26), Vector2(pattern.size.x - 36, 21), 17, COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(pattern, str(view_state.get("pattern_response", "전장을 관찰하세요.")), Vector2(18, 46), Vector2(pattern.size.x - 36, maxf(11.0, pattern.size.y - 49.0)), 9, COLOR_MUTED)

	var workspace := _panel("CombatWorkspace", rects["workspace"], Color("#09081052"), Color("#3f3548"))
	_label(workspace, str(view_state.get("combat_hint", "자동 전투 · 지도에서 방 또는 유닛을 선택")), Vector2(18, workspace.size.y - 34), Vector2(workspace.size.x - 36, 22), 11, COLOR_MUTED)

	var commands := _panel("TacticalCommandDock", rects["commands"], COLOR_PANEL, COLOR_LINE)
	_label(commands, "명령력 %d / %d" % [int(view_state.get("command_points", 0)), int(view_state.get("command_max", 3))], Vector2(10, 1), Vector2(commands.size.x - 20, 15), 9, COLOR_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	var command_labels: Array = view_state.get("commands", [
		{"id": "rally", "label": "집결"},
		{"id": "focus", "label": "집중"},
		{"id": "activate_facility", "label": "시설 발동"}
	])
	var emergency: Dictionary = view_state.get("emergency_command", {})
	if not emergency.is_empty() and command_labels.size() < 4:
		command_labels = command_labels.duplicate(true)
		command_labels.append(emergency)
	var visible_count := mini(4, command_labels.size())
	var command_gap := 8.0
	var command_width := (commands.size.x - 16.0 - command_gap * maxf(0.0, visible_count - 1.0)) / maxf(1.0, visible_count)
	for index in range(visible_count):
		var command: Dictionary = command_labels[index]
		var button_label := str(command.get("label", "명령"))
		if str(command.get("status", "")) != "":
			button_label += "\n" + str(command.get("status", ""))
		var command_button := _button(commands, button_label, Rect2(8 + index * (command_width + command_gap), 16, command_width, commands.size.y - 24), "command:%s" % str(command.get("id", "")), index == visible_count - 1)
		command_button.disabled = bool(command.get("disabled", false))
		command_button.tooltip_text = str(command.get("tooltip", ""))
		command_button.add_to_group(TACTICAL_COMMAND_GROUP)

	var speed := _panel("SpeedDock", rects["speed"], COLOR_PANEL, COLOR_LINE)
	var speed_labels := ["x1", "x2", "x3", "II"]
	var speed_actions := ["speed:1", "speed:2", "speed:3", "pause"]
	var speed_gap := 6.0
	var speed_width := (speed.size.x - 16.0 - speed_gap * 3.0) / 4.0
	for index in range(4):
		_button(speed, speed_labels[index], Rect2(8 + index * (speed_width + speed_gap), 8, speed_width, speed.size.y - 16), speed_actions[index], index == 3)

	if drawer_open:
		_build_context_drawer(rects["drawer"], "combat")


func _build_context_drawer(rect: Rect2, context_mode: String) -> void:
	var drawer := _panel("ContextDrawer", rect, COLOR_PANEL, COLOR_ROUTE)
	var context: Dictionary = view_state.get("context", {})
	_label(drawer, str(context.get("eyebrow", "선택 정보")), Vector2(20, 18), Vector2(drawer.size.x - 40, 20), 12, COLOR_ROUTE, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(drawer, str(context.get("title", "대상을 선택하세요")), Vector2(20, 42), Vector2(drawer.size.x - 40, 34), 22, COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(drawer, str(context.get("subtitle", "지도 선택이 상세 정보를 엽니다.")), Vector2(20, 78), Vector2(drawer.size.x - 40, 22), 12, COLOR_MUTED)
	_separator(drawer, 112.0)
	var facts: Array = context.get("facts", [])
	var y := 128.0
	for fact_value in facts.slice(0, 4):
		var fact: Dictionary = fact_value
		_label(drawer, str(fact.get("label", "정보")), Vector2(20, y), Vector2(drawer.size.x * 0.38, 22), 12, COLOR_MUTED)
		_label(drawer, str(fact.get("value", "-")), Vector2(drawer.size.x * 0.40, y), Vector2(drawer.size.x * 0.53, 22), 13, COLOR_TEXT, HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
		y += 34.0
	_paragraph(drawer, str(context.get("summary", "현재 선택이 경로와 교전에 미치는 영향을 이곳에서 확인합니다.")), Vector2(20, y + 10), Vector2(drawer.size.x - 40, maxf(68.0, drawer.size.y - y - 92.0)), 12, COLOR_MUTED)
	var close := _button(drawer, "닫기", Rect2(20, drawer.size.y - 54, drawer.size.x - 40, 36), "close_context", false)
	close.name = "ContextDrawerClose"
	drawer.set_meta("context_mode", context_mode)


func _build_route_guide(parent: Control) -> void:
	var route_y := parent.size.y * 0.46
	var route_width := parent.size.x * 0.58
	var start_x := parent.size.x * 0.12
	var north := ColorRect.new()
	north.name = "NorthRouteGuide"
	north.position = Vector2(start_x, route_y - 38)
	north.size = Vector2(route_width, 3)
	north.color = Color("#8064a8aa")
	north.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(north)
	var south := ColorRect.new()
	south.name = "SouthRouteGuide"
	south.position = Vector2(start_x, route_y + 38)
	south.size = Vector2(route_width * 0.88, 3)
	south.color = Color("#6e5630bb")
	south.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(south)
	_label(parent, "북문 경로", Vector2(start_x, route_y - 66), Vector2(120, 20), 11, COLOR_ROUTE)
	_label(parent, "남문 경로", Vector2(start_x, route_y + 12), Vector2(120, 20), 11, COLOR_GOLD)


func _build_stat(parent: Control, title: String, value: String, x: float, accent: Color) -> void:
	var width := parent.size.x * 0.5
	_label(parent, title, Vector2(x + 14, 9), Vector2(width - 28, 18), 11, COLOR_MUTED)
	_label(parent, value, Vector2(x + 14, 28), Vector2(width - 28, parent.size.y - 34), 18, accent, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)


func _action_button(parent: Control, text_value: String, rect: Rect2, action_id: String, primary: bool) -> Button:
	var result := _button(parent, text_value, rect, action_id, primary)
	result.add_to_group(PRIMARY_ACTION_GROUP)
	return result


func _panel(node_name: String, rect: Rect2, fill: Color, border: Color) -> Panel:
	var result := Panel.new()
	result.name = node_name
	result.position = rect.position
	result.size = rect.size
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_stylebox_override("panel", _style(fill, border, 1, 7.0))
	add_child(result)
	return result


func _label(parent: Control, text_value: String, position: Vector2, label_size: Vector2, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, role: String = UIFontScript.ROLE_BODY, wrap: int = TextServer.AUTOWRAP_OFF) -> Label:
	var result := Label.new()
	result.text = text_value
	result.position = position
	result.size = label_size
	result.horizontal_alignment = align
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.autowrap_mode = wrap
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_override("font", UIFontScript.font_for_role(role))
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	parent.add_child(result)
	return result


func _button(parent: Control, text_value: String, rect: Rect2, action_id: String, primary: bool) -> Button:
	var result := Button.new()
	result.text = text_value
	result.position = rect.position
	result.size = rect.size
	result.focus_mode = Control.FOCUS_ALL
	result.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	result.add_theme_font_size_override("font_size", 15 if rect.size.y < 60.0 else 17)
	result.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT if primary else COLOR_TEXT)
	result.add_theme_stylebox_override("normal", _style(Color("#2b2037") if primary else COLOR_PANEL_SOFT, COLOR_GOLD if primary else COLOR_LINE, 2 if primary else 1, 6.0))
	result.add_theme_stylebox_override("hover", _style(Color("#3a2b4b"), COLOR_GOLD_BRIGHT, 2, 6.0))
	result.add_theme_stylebox_override("pressed", _style(Color("#503524"), COLOR_GOLD_BRIGHT, 2, 6.0))
	result.pressed.connect(func(): action_requested.emit(action_id))
	parent.add_child(result)
	return result


func _paragraph(parent: Control, text_value: String, position: Vector2, paragraph_size: Vector2, font_size: int, color: Color) -> RichTextLabel:
	var result := RichTextLabel.new()
	result.text = text_value
	result.position = position
	result.size = paragraph_size
	result.bbcode_enabled = false
	result.fit_content = false
	result.scroll_active = false
	result.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_override("normal_font", UIFontScript.font_for_role(UIFontScript.ROLE_BODY))
	result.add_theme_font_size_override("normal_font_size", font_size)
	result.add_theme_color_override("default_color", color)
	parent.add_child(result)
	return result


func _progress(parent: Control, rect: Rect2, ratio: float, fill: Color) -> void:
	var track := ColorRect.new()
	track.position = rect.position
	track.size = rect.size
	track.color = Color("#3c1720")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(track)
	var bar := ColorRect.new()
	bar.position = rect.position
	bar.size = Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)
	bar.color = fill
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)


func _separator(parent: Control, y: float) -> void:
	var line := ColorRect.new()
	line.position = Vector2(20, y)
	line.size = Vector2(parent.size.x - 40, 1)
	line.color = COLOR_LINE
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)


func _style(fill: Color, border: Color, width: int, radius: float) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(width)
	result.corner_radius_top_left = int(radius)
	result.corner_radius_top_right = int(radius)
	result.corner_radius_bottom_left = int(radius)
	result.corner_radius_bottom_right = int(radius)
	return result
