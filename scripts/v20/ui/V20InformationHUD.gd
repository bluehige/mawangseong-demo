class_name V20InformationHUD
extends Control

signal action_requested(action_id: String)

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const UITheme = preload("res://scripts/v20/ui/V20UITheme.gd")
const PlacementBoardScene = preload("res://scenes/v20/placement/V20PlacementBoard.tscn")
const SpatialModel = preload("res://scripts/v20/spatial/V20SpatialModel.gd")
const MODE_MANAGEMENT := "management"
const MODE_COMBAT := "combat"
const PRIMARY_ACTION_GROUP := "v20_primary_action"
const TACTICAL_COMMAND_GROUP := "v20_tactical_command"
const DEFENSE_STAGE_GROUP := "v20_defense_stage"

const COLOR_VOID := UITheme.COLOR_VOID
const COLOR_PANEL := UITheme.COLOR_PANEL
const COLOR_PANEL_SOFT := UITheme.COLOR_PANEL_SOFT
const COLOR_LINE := UITheme.COLOR_LINE
const COLOR_GOLD := UITheme.COLOR_GOLD
const COLOR_GOLD_BRIGHT := UITheme.COLOR_GOLD_BRIGHT
const COLOR_TEXT := UITheme.COLOR_TEXT
const COLOR_MUTED := UITheme.COLOR_MUTED
const COLOR_DANGER := UITheme.COLOR_DANGER
const COLOR_ROUTE := UITheme.COLOR_ROUTE
const COLOR_GREEN := UITheme.COLOR_GREEN

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
	_refresh_combat_live_values()


func set_encounter_status(status: Dictionary, rebuild_now: bool = false) -> void:
	for key_value in status.keys():
		view_state[str(key_value)] = status.get(key_value)
	if rebuild_now:
		_rebuild()
	else:
		_refresh_combat_live_values()


func set_defense_stage_state(status: Dictionary) -> void:
	if status.has("defense_stages"):
		view_state["defense_stages"] = status.get("defense_stages", []).duplicate(true)
	if status.has("active_stage_label"):
		view_state["active_stage_label"] = str(status.get("active_stage_label", ""))
	_refresh_defense_stage_values()


func set_objective_state(label: String, hp: int, maximum: int) -> void:
	view_state["objective_label"] = label
	view_state["objective_hp"] = hp
	view_state["objective_hp_max"] = maxi(1, maximum)
	_refresh_objective_values()


func set_combat_speed_state(speed: float, paused: bool) -> void:
	view_state["combat_speed"] = clampf(speed, 1.0, 3.0)
	view_state["combat_paused"] = paused
	_refresh_speed_controls()


func set_targeting_state(command_id: String, command_label: String, target_type: String) -> void:
	view_state["targeting_command_id"] = command_id
	view_state["targeting_command_label"] = command_label
	view_state["targeting_target_type"] = target_type
	_refresh_combat_live_values()


func clear_targeting_state() -> void:
	view_state.erase("targeting_command_id")
	view_state.erase("targeting_command_label")
	view_state.erase("targeting_target_type")
	_refresh_combat_live_values()


func show_feedback(message: String, success: bool = true) -> void:
	view_state["feedback_message"] = message
	view_state["feedback_success"] = success
	_refresh_feedback_toast()


func set_build_points(value: int) -> void:
	if not (view_state.get("resources") is Dictionary):
		view_state["resources"] = {}
	view_state["resources"]["build"] = value
	var label: Label = get_node_or_null("BuildResources/BuildPointsValue")
	if label != null:
		label.text = str(value)


func update_placement_status(valid: bool, errors: Array, can_undo: bool, build_points: int) -> void:
	view_state["placement_valid"] = valid
	view_state["placement_errors"] = errors.duplicate()
	view_state["placement_can_undo"] = can_undo
	set_build_points(build_points)
	var status_text := _placement_status_text()
	var status_label: Label = get_node_or_null("ManagementActionDock/PlacementStatus")
	if status_label != null:
		status_label.text = status_text
		status_label.add_theme_color_override("font_color", COLOR_GREEN if valid else COLOR_DANGER)
	var header_status: Label = get_node_or_null("BuildResources/PlacementStateValue")
	if header_status != null:
		header_status.text = "배치 가능" if valid else "확인 필요"
		header_status.add_theme_color_override("font_color", COLOR_GREEN if valid else COLOR_DANGER)
	var start_button: Button = get_node_or_null("ManagementActionDock/V20PrimaryActionButton")
	if start_button != null:
		start_button.disabled = not valid
	var undo_button: Button = get_node_or_null("ManagementActionDock/UndoPlacement")
	if undo_button != null:
		undo_button.disabled = not can_undo


func set_countdown(value: float) -> void:
	view_state["countdown_seconds"] = value
	var label: Label = get_node_or_null("StrategyBoardWorkspace/DefenseCountdownValue")
	if label != null:
		label.text = "%d" % maxi(0, int(ceil(value)))


func show_placement_board(placement_state: Dictionary, facilities: Dictionary, board: Dictionary = {}) -> Control:
	var workspace: Control = get_node_or_null("StrategyBoardWorkspace")
	if workspace == null:
		return null
	placement_board = PlacementBoardScene.instantiate()
	placement_board.name = "PlacementBoard"
	placement_board.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	placement_board.position = Vector2(6, 6)
	placement_board.size = Vector2(workspace.size.x - 12, workspace.size.y - 12)
	workspace.add_child(placement_board)
	placement_board.setup(placement_state, facilities, board, view_state)
	return placement_board


func layout_rects_for_viewport(viewport_size: Vector2, mode_value: String = "", drawer_value: bool = false) -> Dictionary:
	var width := maxf(960.0, viewport_size.x)
	var height := maxf(540.0, viewport_size.y)
	var margin := clampf(width * 0.015625, 15.0, 30.0)
	var gap := clampf(width * 0.009375, 9.0, 18.0)
	var top_height := clampf(height * (0.086 if mode_value == MODE_COMBAT else 0.0833), 58.0, 82.0)
	var bottom_height := clampf(height * (0.11 if mode_value == MODE_COMBAT else 0.105), 76.0, 96.0)
	var top_y := margin
	var content_y := top_y + top_height + gap
	var bottom_y := height - margin - bottom_height
	var content_height := maxf(240.0, bottom_y - gap - content_y)
	if mode_value == MODE_COMBAT:
		var speed_width := clampf(width * 0.18, 228.0, 320.0)
		var drawer_width := clampf(width * 0.205, 230.0, 320.0) if drawer_value else 0.0
		var workspace_x := margin
		var workspace_width := width - margin * 2.0 - drawer_width - (gap if drawer_value else 0.0)
		var result := {
			"header": Rect2(margin, top_y, width - margin * 2.0 - speed_width - gap, top_height),
			"speed": Rect2(width - margin - speed_width, top_y, speed_width, top_height),
			"workspace": Rect2(workspace_x, content_y, workspace_width, content_height),
			"commands": Rect2(margin, bottom_y, width - margin * 2.0, bottom_height)
		}
		result["stages"] = Rect2(workspace_x + 12.0, content_y + 10.0, workspace_width - 24.0, 46.0)
		var pattern_width := minf(workspace_width - 40.0, clampf(workspace_width * 0.68, 520.0, 820.0))
		result["pattern"] = Rect2(workspace_x + (workspace_width - pattern_width) * 0.5, content_y + 66.0, pattern_width, 64.0)
		if drawer_value:
			result["drawer"] = Rect2(workspace_x + workspace_width + gap, content_y, drawer_width, content_height)
		return result
	var day_width := clampf(width * 0.105, 116.0, 190.0)
	var resources_width := clampf(width * 0.285, 330.0, 520.0)
	var workspace_width := width - margin * 2.0
	var result := {
		"workspace": Rect2(margin, content_y, workspace_width, content_height),
		"bottom": Rect2(margin, bottom_y, workspace_width, bottom_height),
		"intrusion": Rect2(margin, top_y, width - margin * 2.0 - day_width - resources_width - gap * 2.0, top_height),
		"resources": Rect2(width - margin - day_width - resources_width - gap, top_y, resources_width, top_height),
		"day": Rect2(width - margin - day_width, top_y, day_width, top_height)
	}
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
	var flow_state := str(view_state.get("flow_state", "INTRUSION_BRIEF"))
	var rects := layout_rects_for_viewport(size, MODE_MANAGEMENT, false)
	if flow_state == "INTRUSION_BRIEF":
		_build_intrusion_brief(rects)
		return
	var intrusion := _panel("IntrusionBrief", rects["intrusion"], Color("#0d0b12f7"), Color("#765b31"))
	_label(intrusion, "배치 준비" if flow_state == "PLACEMENT" else "방어 준비", Vector2(18, 5), Vector2(138, intrusion.size.y - 10), 20, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(intrusion, str(view_state.get("intrusion_title", "정찰 정보 준비 중")), Vector2(156, 5), Vector2(intrusion.size.x - 174, 24), 14, COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(intrusion, str(view_state.get("intrusion_warning", view_state.get("intrusion_hint", "적은 표시된 고정 침입로만 통과합니다."))) if flow_state == "PLACEMENT" else str(view_state.get("intrusion_hint", "적은 표시된 고정 침입로만 통과합니다.")), Vector2(156, 27), Vector2(intrusion.size.x - 174, maxf(16.0, intrusion.size.y - 31.0)), 10, COLOR_MUTED)

	var resources := _panel("BuildResources", rects["resources"], Color("#121019f5"), Color("#51475b"))
	var resource_data: Dictionary = view_state.get("resources", {})
	_build_stat(resources, "건설", str(resource_data.get("build", resource_data.get("gold", 0))), 0.0, COLOR_GOLD, "BuildPointsValue")
	if flow_state == "PLACEMENT":
		_build_stat(resources, "배치 상태", "배치 가능" if bool(view_state.get("placement_valid", false)) else "확인 필요", resources.size.x * 0.5, COLOR_GREEN if bool(view_state.get("placement_valid", false)) else COLOR_DANGER, "PlacementStateValue")
	else:
		_build_stat(resources, "명령력", "%s / %s" % [str(resource_data.get("command", 0)), str(resource_data.get("command_max", 3))], resources.size.x * 0.5, COLOR_ROUTE)

	var day_panel := _panel("DayBadge", rects["day"], Color("#241a12f6"), COLOR_GOLD)
	_label(day_panel, "DAY %02d" % int(view_state.get("day", 1)), Vector2.ZERO, day_panel.size, 18, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)

	var workspace := _panel("StrategyBoardWorkspace", rects["workspace"], Color("#08070d75"), Color("#493d4f"))
	if flow_state == "DEFENSE_START":
		_label(workspace, "배치 snapshot 저장 완료", Vector2(40, workspace.size.y * 0.22), Vector2(workspace.size.x - 80, 48), 24, COLOR_GREEN, HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)
		var countdown := _label(workspace, "%d" % maxi(0, int(ceil(float(view_state.get("countdown_seconds", 3.0))))), Vector2(40, workspace.size.y * 0.36), Vector2(workspace.size.x - 80, 110), 72, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)
		countdown.name = "DefenseCountdownValue"
		_label(workspace, "0이 되면 추가 확인 없이 전투를 시작합니다.", Vector2(40, workspace.size.y * 0.62), Vector2(workspace.size.x - 80, 40), 16, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)

	var bottom := _panel("ManagementActionDock", rects["actions"], Color("#100d15f8"), Color("#765b31"))
	var start_width := clampf(bottom.size.x * 0.38, 280.0, 390.0)
	match flow_state:
		"DEFENSE_START":
			_label(bottom, "3/5  방어 시작 · snapshot 복원 가능", Vector2(22, 8), Vector2(bottom.size.x - start_width - 48, bottom.size.y - 16), 13, COLOR_GREEN, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
			var cancel := _action_button(bottom, "카운트다운 취소", Rect2(bottom.size.x - start_width - 8, 8, start_width, bottom.size.y - 16), "cancel_defense_start", false)
			cancel.name = "V20CancelDefenseButton"
		_:
			var undo_width := clampf(bottom.size.x * 0.18, 132.0, 156.0)
			var action_gap := 8.0
			var undo_x := bottom.size.x - start_width - undo_width - action_gap * 2.0
			var status := _label(bottom, _placement_status_text(), Vector2(22, 8), Vector2(undo_x - 34, bottom.size.y - 16), UITheme.FONT_BODY, COLOR_GREEN if bool(view_state.get("placement_valid", false)) else COLOR_DANGER, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
			status.name = "PlacementStatus"
			var undo := _action_button(bottom, "↶ 되돌리기", Rect2(undo_x, 8, undo_width, bottom.size.y - 16), "undo_placement", false)
			undo.name = "UndoPlacement"
			undo.disabled = not bool(view_state.get("placement_can_undo", false))
			var start := _action_button(bottom, "방어 시작  →", Rect2(bottom.size.x - start_width - 8, 8, start_width, bottom.size.y - 16), "start_defense", true)
			start.name = "V20PrimaryActionButton"
			start.disabled = not bool(view_state.get("placement_valid", false))


func _build_intrusion_brief(rects: Dictionary) -> void:
	var intrusion_rect: Rect2 = rects["intrusion"]
	var resource_rect: Rect2 = rects["resources"]
	var header_rect := Rect2(intrusion_rect.position, Vector2(resource_rect.end.x - intrusion_rect.position.x, intrusion_rect.size.y))
	var header := _panel("IntrusionBrief", header_rect, Color("#0d0b12f7"), Color("#765b31"))
	_label(header, "침입 정찰", Vector2(20, 5), Vector2(126, header.size.y - 10), UITheme.FONT_TITLE, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(header, str(view_state.get("intrusion_title", "이번 침입을 확인하세요")), Vector2(150, 5), Vector2(header.size.x - 170, header.size.y - 10), 15, COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)

	var day_panel := _panel("DayBadge", rects["day"], Color("#241a12f6"), COLOR_GOLD)
	_label(day_panel, "DAY %02d" % int(view_state.get("day", 1)), Vector2.ZERO, day_panel.size, UITheme.FONT_VALUE, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)

	var workspace := _panel("StrategyBoardWorkspace", rects["workspace"], Color("#08070d9c"), Color("#493d4f"))
	var content_width := minf(980.0, workspace.size.x - 96.0)
	var content_x := (workspace.size.x - content_width) * 0.5
	_label(workspace, "이번 전투 브리핑", Vector2(content_x, 22), Vector2(content_width, 36), 26, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS).name = "IntrusionBriefTitle"
	_label(workspace, "적의 목표와 고정 침입 순서를 확인한 뒤 배치를 시작하세요.", Vector2(content_x, 58), Vector2(content_width, 26), UITheme.FONT_BODY, COLOR_MUTED).name = "IntrusionBriefSubtitle"

	var portrait_size := minf(168.0, workspace.size.y - 164.0)
	var portrait_rect := Rect2(content_x, 108, portrait_size, portrait_size)
	var portrait_panel := _child_panel(workspace, "IntrusionEnemyPortrait", portrait_rect, Color("#17131fe8"), Color("#765b31"), 1)
	var portrait_path := str(view_state.get("intrusion_enemy_portrait", ""))
	var texture_resource = load(portrait_path) if portrait_path != "" and ResourceLoader.exists(portrait_path) else null
	if texture_resource is Texture2D:
		var portrait := TextureRect.new()
		portrait.name = "EnemyTexture"
		portrait.position = Vector2(10, 10)
		portrait.size = portrait_panel.size - Vector2(20, 20)
		portrait.texture = texture_resource
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_panel.add_child(portrait)
	else:
		_label(portrait_panel, "⚔", Vector2.ZERO, portrait_panel.size, 54, COLOR_GOLD, HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)
	var enemy_name := _label(workspace, str(view_state.get("intrusion_enemy_name", "침입대")), Vector2(content_x, portrait_rect.end.y + 8), Vector2(portrait_size, 34), 17, COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)
	enemy_name.name = "IntrusionEnemyName"

	var facts_x := portrait_rect.end.x + 42.0
	var facts_width := content_x + content_width - facts_x
	_brief_fact(workspace, "적의 목표", str(view_state.get("intrusion_goal", "왕좌를 지키세요.")), facts_x, 108, facts_width, "IntrusionGoal")
	_brief_fact(workspace, "고정 침입 순서", str(view_state.get("intrusion_route_order", "성문 전초 → 가시 회랑 → 중앙 전투실 → 왕좌 전실")), facts_x, 190, facts_width, "IntrusionRouteOrder")
	_brief_fact(workspace, "이번 DAY 주의", str(view_state.get("intrusion_warning", "첫 교전 위치를 정하고 적의 움직임을 확인하세요.")), facts_x, 272, facts_width, "IntrusionWarning", COLOR_DANGER)

	var bottom := _panel("ManagementActionDock", rects["actions"], Color("#100d15f8"), Color("#765b31"))
	var start_width := clampf(bottom.size.x * 0.38, 280.0, 390.0)
	_label(bottom, "목표와 침입 순서를 확인했습니다.", Vector2(22, 8), Vector2(bottom.size.x - start_width - 48, bottom.size.y - 16), UITheme.FONT_BODY, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	var begin := _action_button(bottom, "배치 시작  →", Rect2(bottom.size.x - start_width - 8, 8, start_width, bottom.size.y - 16), "begin_placement", true)
	begin.name = "V20PrimaryActionButton"

	workspace.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(workspace, "modulate", Color.WHITE, 0.18)


func _brief_fact(parent: Control, heading: String, value: String, x: float, y: float, width: float, node_name: String, accent: Color = COLOR_GOLD) -> void:
	_label(parent, heading, Vector2(x, y), Vector2(width, 22), UITheme.FONT_SUPPORT, accent, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	var value_label := _label(parent, value, Vector2(x, y + 24), Vector2(width, 48), UITheme.FONT_VALUE, COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS, TextServer.AUTOWRAP_WORD_SMART)
	value_label.name = node_name


func _build_combat() -> void:
	var rects := layout_rects_for_viewport(size, MODE_COMBAT, drawer_open)
	var header := _panel("CombatHeader", rects["header"], Color("#0d0b12f8"), Color("#51475b"))
	_label(header, "DAY %02d" % int(view_state.get("day", 1)), Vector2(16, 4), Vector2(90, header.size.y - 8), 18, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS).name = "DayValue"
	var objective_title := _label(header, str(view_state.get("objective_label", "왕좌 방어")), Vector2(108, 4), Vector2(150, header.size.y - 8), UITheme.FONT_BUTTON, COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	objective_title.name = "ObjectiveLabelValue"
	var hp_value := int(view_state.get("objective_hp", 100))
	var hp_max := maxi(1, int(view_state.get("objective_hp_max", 100)))
	var hp_label := _label(header, "왕좌 HP  %d / %d" % [hp_value, hp_max], Vector2(266, 2), Vector2(158, header.size.y - 14), UITheme.FONT_BODY, COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	hp_label.name = "ObjectiveHpValue"
	_progress(header, Rect2(266, header.size.y - 13, 158, 6), float(hp_value) / float(hp_max), COLOR_DANGER, "ObjectiveHp")
	var header_title := _label(header, str(view_state.get("encounter_title", "침입대 방어")), Vector2(444, 4), Vector2(maxf(120.0, header.size.x - 676.0), header.size.y - 8), UITheme.FONT_BUTTON, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	header_title.name = "EncounterTitleValue"
	var phase_value := _label(header, str(view_state.get("phase_label", "WAVE 준비")), Vector2(header.size.x - 224, 4), Vector2(208, header.size.y - 8), UITheme.FONT_BODY, COLOR_ROUTE, HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	phase_value.name = "PhaseLabelValue"

	var speed := _panel("SpeedDock", rects["speed"], Color("#100d15f8"), Color("#51475b"))
	var speed_labels := ["x1", "x2", "x3", "정지"]
	var speed_actions := ["speed:1", "speed:2", "speed:3", "pause"]
	var speed_gap := 4.0
	var speed_width := (speed.size.x - 14.0 - speed_gap * 3.0) / 4.0
	var current_speed := float(view_state.get("combat_speed", 1.0))
	var paused := bool(view_state.get("combat_paused", false))
	for index in range(4):
		var selected := paused if index == 3 else not paused and is_equal_approx(current_speed, float(index + 1))
		var speed_button := _button(speed, speed_labels[index], Rect2(7 + index * (speed_width + speed_gap), 7, speed_width, maxf(UITheme.BUTTON_MIN_HEIGHT, speed.size.y - 14)), speed_actions[index], selected)
		speed_button.name = "CombatSpeed_%d" % index

	var workspace := _panel("CombatWorkspace", rects["workspace"], Color("#00000000"), Color("#6b5c74"))
	_build_defense_stage_strip(rects["stages"])
	if _threat_active():
		_build_threat_panel(rects["pattern"])

	var commands := _panel("TacticalCommandDock", rects["commands"], Color("#100d15f8"), Color("#765b31"))
	_label(commands, "전술 명령", Vector2(14, 7), Vector2(98, 22), UITheme.FONT_BODY, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	var command_points_label := _label(commands, _command_point_text(), Vector2(14, 29), Vector2(98, commands.size.y - 34), UITheme.FONT_SUPPORT, COLOR_ROUTE, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	command_points_label.name = "CommandPointsValue"
	var command_labels: Array = view_state.get("commands", [
		{"id": "v20_rally", "label": "집결", "cost": 1, "availability_label": "사용 가능"},
		{"id": "v20_focus", "label": "집중", "cost": 1, "availability_label": "사용 가능"},
		{"id": "v20_activate_facility", "label": "시설 발동", "cost": 1, "availability_label": "사용 가능"},
		{"id": "v20_emergency_fallback", "label": "비상 후퇴", "cost": 2, "availability_label": "사용 가능"}
	])
	var primary_commands: Array = []
	for command_value in command_labels:
		var command: Dictionary = command_value
		primary_commands.append(command)
		if primary_commands.size() == 4:
			break
	var visible_count := primary_commands.size()
	var command_gap := 6.0
	var command_start := 118.0
	var command_width := (commands.size.x - command_start - 8.0 - command_gap * maxf(0.0, visible_count - 1.0)) / maxf(1.0, visible_count)
	for index in range(visible_count):
		var command: Dictionary = primary_commands[index]
		var button_label := _command_button_text(command)
		var command_id := str(command.get("id", ""))
		var selected := command_id == str(view_state.get("targeting_command_id", ""))
		var command_button := _button(commands, button_label, Rect2(command_start + index * (command_width + command_gap), 8, command_width, commands.size.y - 16), "command:%s" % command_id, selected)
		command_button.name = "Command_%s" % command_id
		command_button.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		command_button.disabled = bool(command.get("disabled", false))
		command_button.tooltip_text = str(command.get("tooltip", ""))
		command_button.add_to_group(TACTICAL_COMMAND_GROUP)

	if drawer_open:
		_build_context_drawer(rects["drawer"], "combat")
	_refresh_targeting_prompt()
	_refresh_feedback_toast()


func _refresh_combat_live_values() -> void:
	if screen_mode != MODE_COMBAT or not is_node_ready():
		return
	_set_label_text("CombatHeader/PhaseLabelValue", str(view_state.get("phase_label", "WAVE 준비")))
	_set_label_text("TacticalCommandDock/CommandPointsValue", _command_point_text())
	_refresh_objective_values()
	_refresh_speed_controls()
	_refresh_threat_panel()
	_refresh_defense_stage_values()
	for command_value in view_state.get("commands", []):
		var command: Dictionary = command_value
		var command_id := str(command.get("id", ""))
		var button: Button = get_node_or_null("TacticalCommandDock/Command_%s" % command_id)
		if button == null:
			continue
		button.text = _command_button_text(command)
		button.disabled = bool(command.get("disabled", false))
		_apply_button_style(button, command_id == str(view_state.get("targeting_command_id", "")))
	_refresh_targeting_prompt()


func _refresh_objective_values() -> void:
	if screen_mode != MODE_COMBAT:
		return
	var hp := int(view_state.get("objective_hp", 100))
	var maximum := maxi(1, int(view_state.get("objective_hp_max", 100)))
	_set_label_text("CombatHeader/ObjectiveLabelValue", str(view_state.get("objective_label", "왕좌 방어")))
	_set_label_text("CombatHeader/ObjectiveHpValue", "왕좌 HP  %d / %d" % [hp, maximum])
	var track: ColorRect = get_node_or_null("CombatHeader/ObjectiveHpTrack")
	var bar: ColorRect = get_node_or_null("CombatHeader/ObjectiveHpBar")
	if track != null and bar != null:
		bar.size.x = track.size.x * clampf(float(hp) / float(maximum), 0.0, 1.0)


func _refresh_speed_controls() -> void:
	if screen_mode != MODE_COMBAT:
		return
	var speed := float(view_state.get("combat_speed", 1.0))
	var paused := bool(view_state.get("combat_paused", false))
	for index in range(4):
		var button: Button = get_node_or_null("SpeedDock/CombatSpeed_%d" % index)
		if button == null:
			continue
		var selected := paused if index == 3 else not paused and is_equal_approx(speed, float(index + 1))
		if index == 3:
			button.text = "재개" if paused else "정지"
		_apply_button_style(button, selected)


func _threat_active() -> bool:
	return bool(view_state.get("threat_active", false))


func _build_threat_panel(rect: Rect2) -> void:
	var pattern := _panel("NextPattern", rect, Color("#30151af5"), COLOR_DANGER)
	_label(pattern, "위협", Vector2(14, 4), Vector2(58, pattern.size.y - 8), UITheme.FONT_SUPPORT, Color("#ff9d86"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	var pattern_title := _label(pattern, str(view_state.get("pattern_title", "적 행동")), Vector2(70, 3), Vector2(pattern.size.x - 344, 28), UITheme.FONT_BUTTON, COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	pattern_title.name = "PatternTitleValue"
	var recommendation := _label(pattern, _threat_recommendation_text(), Vector2(70, 30), Vector2(pattern.size.x - 166, pattern.size.y - 34), UITheme.FONT_SUPPORT, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	recommendation.name = "PatternRecommendationValue"
	var pattern_eta := _label(pattern, str(view_state.get("pattern_eta", "—")), Vector2(pattern.size.x - 92, 3), Vector2(78, pattern.size.y - 8), UITheme.FONT_BUTTON, Color("#ffc3ad"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	pattern_eta.name = "PatternEtaValue"


func _refresh_threat_panel() -> void:
	var existing := get_node_or_null("NextPattern")
	if not _threat_active():
		if existing != null:
			existing.free()
		return
	if existing == null:
		_build_threat_panel(layout_rects_for_viewport(size, MODE_COMBAT, drawer_open)["pattern"])
		return
	_set_label_text("NextPattern/PatternTitleValue", str(view_state.get("pattern_title", "적 행동")))
	_set_label_text("NextPattern/PatternRecommendationValue", _threat_recommendation_text())
	_set_label_text("NextPattern/PatternEtaValue", str(view_state.get("pattern_eta", "—")))


func _threat_recommendation_text() -> String:
	var command_label := str(view_state.get("recommended_command_label", ""))
	if command_label == "":
		var command_id := str(view_state.get("recommended_command_id", ""))
		for command_value in view_state.get("commands", []):
			var command: Dictionary = command_value
			if str(command.get("id", "")) == command_id:
				command_label = str(command.get("label", command_id))
				break
	var target_label := str(view_state.get("recommended_target_label", ""))
	if command_label != "" and target_label != "":
		return "권장 명령 · %s   |   권장 대상 · %s" % [command_label, target_label]
	return str(view_state.get("pattern_response", "위협 대상과 대응 명령을 확인하세요."))


func _build_defense_stage_strip(rect: Rect2) -> void:
	var strip := _panel("DefenseStageStrip", rect, Color("#0c0910de"), Color("#51475b"))
	var gap := 4.0
	var row_width := (strip.size.x - gap * 3.0) / 4.0
	for index in range(4):
		var row := _child_panel(strip, "DefenseStage_%d" % index, Rect2(index * (row_width + gap), 0, row_width, strip.size.y), COLOR_PANEL_SOFT, COLOR_LINE)
		row.add_to_group(DEFENSE_STAGE_GROUP)
		var stage_label := _label(row, "", Vector2(9, 1), Vector2(row.size.x - 82, row.size.y - 2), UITheme.FONT_SUPPORT, COLOR_TEXT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
		stage_label.name = "StageLabel"
		var stage_status := _label(row, "", Vector2(row.size.x - 78, 1), Vector2(69, row.size.y - 2), UITheme.FONT_SUPPORT, COLOR_MUTED, HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
		stage_status.name = "StageStatus"
	_refresh_defense_stage_values()


func _refresh_defense_stage_values() -> void:
	if screen_mode != MODE_COMBAT or not is_node_ready():
		return
	var stages := _defense_stage_rows()
	var active_label := str(view_state.get("active_stage_label", ""))
	if active_label == "" and not stages.is_empty():
		active_label = str(stages[0].get("label", ""))
	for index in range(4):
		var row: Panel = get_node_or_null("DefenseStageStrip/DefenseStage_%d" % index)
		if row == null:
			continue
		var stage: Dictionary = stages[index]
		var is_active := _defense_stage_is_active(stage, active_label)
		var status := str(stage.get("status", "대기"))
		var color := _defense_stage_color(status, is_active)
		row.set_meta("active", is_active)
		var stage_label: Label = row.get_node_or_null("StageLabel")
		var stage_status: Label = row.get_node_or_null("StageStatus")
		if stage_label != null:
			stage_label.text = ("▶ " if is_active else "") + str(stage.get("label", "방어 구간"))
			stage_label.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT if is_active else COLOR_TEXT)
		if stage_status != null:
			stage_status.text = _defense_stage_status_text(status, is_active)
			stage_status.add_theme_color_override("font_color", color)
		row.add_theme_stylebox_override("panel", _style(Color(color.r, color.g, color.b, 0.16 if is_active else 0.07), color, 2 if is_active else 1, 6.0))


func _defense_stage_status_text(status: String, is_active: bool) -> String:
	if is_active or "교전" in status:
		return "● 교전"
	if "돌파" in status or "위험" in status:
		return "✕ 돌파"
	if "저지" in status or "완료" in status or "방어" in status:
		return "✓ 저지"
	return "○ 대기"


func _defense_stage_rows() -> Array[Dictionary]:
	var defaults: Array[Dictionary] = []
	var board := SpatialModel.board_from_catalog(DataRegistry.v20_dungeon_layouts)
	for zone in SpatialModel.defense_zones(board):
		var zone_id := str(zone.get("zone_id", ""))
		defaults.append({"id": zone_id, "label": "%d차 · %s" % [int(zone.get("order", 0)), str(zone.get("display_name", zone_id))], "status": "대기"})
	var source: Array = view_state.get("defense_stages", [])
	var result: Array[Dictionary] = []
	for index in range(4):
		var stage := defaults[index].duplicate(true)
		if index < source.size():
			var value = source[index]
			if value is Dictionary:
				for key_value in value.keys():
					stage[str(key_value)] = value.get(key_value)
			else:
				stage["label"] = str(value)
		result.append(stage)
	return result


func _defense_stage_is_active(stage: Dictionary, active_label: String) -> bool:
	if bool(stage.get("active", false)):
		return true
	var stage_id := str(stage.get("id", ""))
	var label := str(stage.get("label", ""))
	return active_label != "" and (active_label == stage_id or active_label == label or active_label in label or label in active_label)


func _defense_stage_color(status: String, is_active: bool) -> Color:
	if is_active:
		return COLOR_GOLD
	if "돌파" in status or "위험" in status:
		return COLOR_DANGER
	if "저지" in status or "완료" in status or "방어" in status:
		return COLOR_GREEN
	return COLOR_LINE


func _command_button_text(command: Dictionary) -> String:
	var label := str(command.get("label", "명령"))
	var command_id := str(command.get("id", ""))
	var symbol := str({
		"v20_rally": "◎",
		"v20_focus": "◇",
		"v20_activate_facility": "◆",
		"v20_emergency_fallback": "↩"
	}.get(command_id, "•"))
	var cost := int(command.get("cost", 1))
	var availability := str(command.get("availability_label", command.get("status", "사용 가능")))
	return "%s  %s  ·  %d   |   %s" % [symbol, label, cost, availability]


func _refresh_targeting_prompt() -> void:
	var workspace: Control = get_node_or_null("CombatWorkspace")
	if workspace == null:
		return
	var existing := workspace.get_node_or_null("TargetingPrompt")
	if existing != null:
		existing.free()
	var command_id := str(view_state.get("targeting_command_id", ""))
	if command_id == "":
		return
	var target_labels := {"enemy": "적", "room": "방", "facility": "시설"}
	var target_type := str(view_state.get("targeting_target_type", ""))
	var target_label := str(target_labels.get(target_type, "대상"))
	var command_row := _command_row(command_id)
	var target_hint := str(command_row.get("target_hint", "%s 클릭" % target_label))
	var effect_hint := str(command_row.get("effect_hint", "선택한 대상에 효과 적용"))
	var width := minf(680.0, workspace.size.x - 40.0)
	var prompt := _child_panel(workspace, "TargetingPrompt", Rect2((workspace.size.x - width) * 0.5, workspace.size.y - 78.0, width, 60.0), Color("#2a2038f6"), COLOR_ROUTE, 2)
	_label(prompt, "%s 대상 선택 · %s" % [str(view_state.get("targeting_command_label", "명령")), target_hint], Vector2(16, 3), Vector2(prompt.size.x - 126, 28), UITheme.FONT_BODY, Color("#eadcff"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(prompt, "예상 효과 · %s" % effect_hint, Vector2(16, 29), Vector2(prompt.size.x - 126, 26), UITheme.FONT_SUPPORT, COLOR_GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_label(prompt, "ESC 취소", Vector2(prompt.size.x - 108, 3), Vector2(92, 52), UITheme.FONT_SUPPORT, COLOR_MUTED, HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	prompt.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(prompt, "modulate", Color.WHITE, 0.16)


func _command_row(command_id: String) -> Dictionary:
	for command_value in view_state.get("commands", []):
		var command: Dictionary = command_value
		if str(command.get("id", "")) == command_id:
			return command
	return {}


func _refresh_feedback_toast() -> void:
	var workspace: Control = get_node_or_null("CombatWorkspace")
	if workspace == null:
		return
	var existing := workspace.get_node_or_null("CommandFeedbackToast")
	if existing != null:
		existing.free()
	var message := str(view_state.get("feedback_message", ""))
	if message == "":
		return
	view_state.erase("feedback_message")
	var success := bool(view_state.get("feedback_success", true))
	var border := COLOR_GREEN if success else COLOR_DANGER
	var width := minf(620.0, workspace.size.x - 42.0)
	var toast_y := 142.0 if _threat_active() else 70.0
	var toast := _child_panel(workspace, "CommandFeedbackToast", Rect2((workspace.size.x - width) * 0.5, toast_y, width, 48), Color("#111a17f7") if success else Color("#281317f7"), border, 2)
	_label(toast, ("✓  " if success else "!  ") + message, Vector2(18, 3), Vector2(toast.size.x - 36, 42), 13, COLOR_TEXT, HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)
	toast.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(toast, "modulate", Color.WHITE, 0.16)
	tween.tween_interval(2.2)
	tween.tween_property(toast, "modulate", Color(1, 1, 1, 0), 0.28)
	tween.tween_callback(toast.queue_free)


func _command_point_text() -> String:
	var points := int(view_state.get("command_points", 0))
	var maximum := maxi(1, int(view_state.get("command_max", 3)))
	var tokens: Array[String] = []
	for index in range(maximum):
		tokens.append("●" if index < points else "○")
	return "%s  %d/%d" % [" ".join(tokens), points, maximum]


func _set_label_text(path: String, value: String) -> void:
	var label: Label = get_node_or_null(path)
	if label != null:
		label.text = value


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
	_paragraph(drawer, str(context.get("summary", "현재 선택이 이 구역의 교전에 미치는 영향을 확인합니다.")), Vector2(20, y + 10), Vector2(drawer.size.x - 40, maxf(68.0, drawer.size.y - y - 92.0)), 12, COLOR_MUTED)
	var close := _button(drawer, "닫기", Rect2(20, drawer.size.y - 54, drawer.size.x - 40, 36), "close_context", false)
	close.name = "ContextDrawerClose"
	drawer.set_meta("context_mode", context_mode)
	drawer.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(drawer, "modulate", Color.WHITE, 0.18)


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
	_label(parent, "확정 침입로", Vector2(start_x, route_y - 66), Vector2(120, 20), 11, COLOR_ROUTE)
	_label(parent, "고정 배치 위치", Vector2(start_x, route_y + 12), Vector2(120, 20), 11, COLOR_GOLD)


func _build_stat(parent: Control, title: String, value: String, x: float, accent: Color, value_name: String = "") -> void:
	var width := parent.size.x * 0.5
	_label(parent, title, Vector2(x + 14, 9), Vector2(width - 28, 18), 11, COLOR_MUTED)
	var value_label := _label(parent, value, Vector2(x + 14, 28), Vector2(width - 28, parent.size.y - 34), 18, accent, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	if value_name != "":
		value_label.name = value_name


func _placement_status_text() -> String:
	if bool(view_state.get("placement_valid", false)):
		return "배치 완료 · 방어를 시작할 수 있습니다."
	var errors: Array = view_state.get("placement_errors", [])
	if errors.is_empty():
		return "시설과 몬스터 배치를 확인하세요."
	var error_text := str(errors[0])
	if ".required_placement_missing" in error_text or ".required_slot_missing" in error_text:
		var monster_id := error_text.get_slice(".", 0)
		var monster_prompts := {"slime": "슬라임을", "goblin": "고블린을", "imp": "임프를"}
		return "%s 몬스터 슬롯에 배치하세요." % str(monster_prompts.get(monster_id, "필수 몬스터를"))
	if "facility_cost_exceeds" in error_text:
		return "건설 자원 안에서 시설을 다시 선택하세요."
	if "monster_capacity_exceeded" in error_text or "duplicate_monster_slot" in error_text:
		return "한 구역의 몬스터 슬롯은 두 칸까지입니다."
	if "unknown_facility" in error_text:
		return "사용할 수 없는 시설을 제거하거나 교체하세요."
	return "겹치거나 비어 있는 배치 슬롯을 확인하세요."


func _action_button(parent: Control, text_value: String, rect: Rect2, action_id: String, primary: bool) -> Button:
	var result := _button(parent, text_value, rect, action_id, primary)
	if primary:
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


func _child_panel(parent: Control, node_name: String, rect: Rect2, fill: Color, border: Color, width: int = 1) -> Panel:
	var result := Panel.new()
	result.name = node_name
	result.position = rect.position
	result.size = rect.size
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_stylebox_override("panel", _style(fill, border, width, 8.0))
	parent.add_child(result)
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
	_apply_button_style(result, primary)
	result.add_theme_font_size_override("font_size", UITheme.FONT_BUTTON if rect.size.y < 60.0 else 17)
	result.pressed.connect(func(): action_requested.emit(action_id))
	parent.add_child(result)
	return result


func _apply_button_style(button: Button, primary: bool) -> void:
	UITheme.apply_button_style(button, primary)


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


func _progress(parent: Control, rect: Rect2, ratio: float, fill: Color, name_prefix: String = "") -> void:
	var track := ColorRect.new()
	if name_prefix != "":
		track.name = "%sTrack" % name_prefix
	track.position = rect.position
	track.size = rect.size
	track.color = Color("#3c1720")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(track)
	var bar := ColorRect.new()
	if name_prefix != "":
		bar.name = "%sBar" % name_prefix
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
	return UITheme.style(fill, border, width, radius)
