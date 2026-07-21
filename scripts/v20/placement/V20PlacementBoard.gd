class_name V20PlacementBoard
extends Control

signal state_changed(state: Dictionary, result: Dictionary)

const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const PathService = preload("res://scripts/v20/path/V20WeightedPathService.gd")
const DragButtonScript = preload("res://scripts/v20/placement/V20MonsterDragButton.gd")
const RoomButtonScript = preload("res://scripts/v20/placement/V20PlacementRoomButton.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")

const BOARD_ID := "v20_day_01_05_board"
const ROOM_EDGE_IDS := {
	"north_gate": "entry_north",
	"south_gate": "entry_south",
	"treasure": "south_treasure",
	"fallback": "fallback_throne"
}
const COLOR_VOID := Color("#08070d")
const COLOR_PANEL := Color("#100e16f2")
const COLOR_SOFT := Color("#17131fe8")
const COLOR_LINE := Color("#554b60")
const COLOR_GOLD := Color("#e8bb58")
const COLOR_GOLD_BRIGHT := Color("#ffe4a0")
const COLOR_PURPLE := Color("#9e7bd1")
const COLOR_TEXT := Color("#f3eadc")
const COLOR_MUTED := Color("#bdb3c6")
const COLOR_DANGER := Color("#e56a72")

var placement_state: Dictionary = {}
var facility_catalog: Dictionary = {}
var board_data: Dictionary = {}
var current_route: Dictionary = {}
var last_result: Dictionary = {}
var _map_rect := Rect2()
var _rebuild_queued := false


func _ready() -> void:
	resized.connect(_queue_rebuild)


func setup(state_value: Dictionary, facilities: Dictionary, board_value: Dictionary = {}) -> void:
	placement_state = state_value.duplicate(true)
	facility_catalog = facilities.duplicate(true)
	board_data = board_value.duplicate(true)
	if board_data.is_empty():
		board_data = DataRegistry.v20_dungeon_layouts.get(BOARD_ID, {}).duplicate(true)
	_refresh_route()
	_rebuild()


func _queue_rebuild() -> void:
	if _rebuild_queued or placement_state.is_empty():
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _rebuild() -> void:
	_rebuild_queued = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if size.x < 640.0 or size.y < 360.0:
		return
	_refresh_route()
	_map_rect = Rect2(8, 54, size.x - 16, size.y - 172)
	_build_step_ribbon(Rect2(8, 4, size.x - 16, 44))
	_build_route_map(_map_rect)
	_build_tool_tray(Rect2(8, size.y - 112, size.x - 16, 104))
	queue_redraw()


func _draw() -> void:
	if board_data.is_empty() or _map_rect.size.x <= 0.0:
		return
	draw_style_box(_style(Color("#090810b8"), Color("#3f3548"), 1, 8.0), _map_rect)
	for edge_value in board_data.get("edges", []):
		var edge: Dictionary = edge_value
		var start := _node_position(str(edge.get("from", "")))
		var finish := _node_position(str(edge.get("to", "")))
		draw_line(start, finish, COLOR_LINE, 3.0, true)
	var active_edges: Array = current_route.get("edges", [])
	for edge_value in board_data.get("edges", []):
		var edge: Dictionary = edge_value
		if not active_edges.has(str(edge.get("id", ""))):
			continue
		var start := _node_position(str(edge.get("from", "")))
		var finish := _node_position(str(edge.get("to", "")))
		draw_line(start, finish, Color("#7a5d28aa"), 11.0, true)
		draw_line(start, finish, COLOR_GOLD, 5.0, true)
		_draw_route_arrow(start, finish)
	for node_id_value in board_data.get("nodes", []):
		var node_id := str(node_id_value)
		var active: bool = current_route.get("nodes", []).has(node_id)
		draw_circle(_node_position(node_id), 13.0 if active else 9.0, COLOR_GOLD_BRIGHT if active else Color("#8b799b"))
		draw_circle(_node_position(node_id), 6.0, COLOR_VOID)


func _draw_route_arrow(start: Vector2, finish: Vector2) -> void:
	var direction := (finish - start).normalized()
	if direction.is_zero_approx():
		return
	var normal := Vector2(-direction.y, direction.x)
	var center := start.lerp(finish, 0.56)
	var points := PackedVector2Array([
		center + direction * 10.0,
		center - direction * 7.0 + normal * 6.0,
		center - direction * 7.0 - normal * 6.0
	])
	draw_colored_polygon(points, COLOR_GOLD_BRIGHT)


func _build_step_ribbon(rect: Rect2) -> void:
	var ribbon := _panel(self, "PlacementSteps", rect, COLOR_PANEL, COLOR_GOLD)
	_label(ribbon, "1  침략로 확인    →    2  시설·몬스터 배치    →    3  방어 시작", Vector2(16, 4), Vector2(ribbon.size.x * 0.57, 36), 15, COLOR_GOLD_BRIGHT, UIFontScript.ROLE_EMPHASIS)
	_label(ribbon, _route_summary(), Vector2(ribbon.size.x * 0.58, 4), Vector2(ribbon.size.x * 0.40, 36), 12, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS, HORIZONTAL_ALIGNMENT_RIGHT)


func _build_route_map(rect: Rect2) -> void:
	var map := Control.new()
	map.name = "RouteMap"
	map.position = rect.position
	map.size = rect.size
	map.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(map)
	var first_action: bool = placement_state.get("last_action", {}).is_empty()
	var guide_text := "처음이라면: 아래 바리케이드를 북문으로 드래그하세요." if first_action else "금색 화살표가 현재 예상 침략로입니다. 배치하면 즉시 다시 계산됩니다."
	var guide_color := COLOR_GOLD_BRIGHT if first_action else COLOR_MUTED
	if not last_result.is_empty():
		guide_text = _feedback_text()
		guide_color = COLOR_DANGER if not bool(last_result.get("ok", true)) else COLOR_GOLD_BRIGHT
	_label(
		map,
		guide_text,
		Vector2(16, 8),
		Vector2(map.size.x - 32, 28),
		13,
		guide_color,
		UIFontScript.ROLE_EMPHASIS
	)
	for node_id_value in board_data.get("nodes", []):
		var node_id := str(node_id_value)
		var local_position := _node_position(node_id) - rect.position
		if placement_state.get("rooms", {}).has(node_id):
			_build_room_button(map, node_id, local_position)
		else:
			_label(map, _node_display_name(node_id), local_position + Vector2(-58, 15), Vector2(116, 22), 11, COLOR_GOLD_BRIGHT if current_route.get("nodes", []).has(node_id) else COLOR_MUTED, UIFontScript.ROLE_EMPHASIS, HORIZONTAL_ALIGNMENT_CENTER)
	if not placement_state.get("pending_replacement", {}).is_empty():
		_build_replacement_confirm(map)


func _build_room_button(parent: Control, room_id: String, center: Vector2) -> void:
	var room: Dictionary = placement_state.get("rooms", {}).get(room_id, {})
	var button = RoomButtonScript.new()
	button.name = "Room_%s" % room_id
	button.setup(room_id, _room_button_text(room))
	button.position = center - Vector2(76, 38)
	button.size = Vector2(152, 76)
	button.focus_mode = Control.FOCUS_ALL
	_style_room_button(button, room_id)
	button.pressed.connect(_on_room_clicked.bind(room_id))
	button.monster_dropped.connect(_on_monster_dropped)
	button.facility_dropped.connect(_on_facility_dropped)
	parent.add_child(button)


func _build_tool_tray(rect: Rect2) -> void:
	var tray := _panel(self, "PlacementToolTray", rect, COLOR_PANEL, COLOR_LINE)
	var label_width := 126.0
	_label(tray, "시설", Vector2(12, 6), Vector2(label_width - 20, 24), 13, COLOR_GOLD_BRIGHT, UIFontScript.ROLE_EMPHASIS)
	_label(tray, "건설 %d" % int(placement_state.get("build_points", 0)), Vector2(12, 27), Vector2(label_width - 20, 22), 12, COLOR_GOLD, UIFontScript.ROLE_EMPHASIS)
	_label(tray, "몬스터", Vector2(12, 62), Vector2(label_width - 20, 24), 13, COLOR_PURPLE, UIFontScript.ROLE_EMPHASIS)
	var undo_width := 132.0
	var tools_x := label_width
	var tools_width := tray.size.x - tools_x - undo_width - 30
	_build_facility_tools(tray, Rect2(tools_x, 7, tools_width, 42))
	_build_monster_tools(tray, Rect2(tools_x, 56, tools_width, 42))
	var undo := _button(tray, "되돌리기", Rect2(tray.size.x - undo_width - 10, 10, undo_width, 84), false)
	undo.name = "UndoPlacement"
	undo.disabled = placement_state.get("undo", {}).is_empty()
	undo.pressed.connect(_on_undo)


func _build_facility_tools(parent: Control, rect: Rect2) -> void:
	var ids: Array = facility_catalog.keys()
	ids.sort()
	var count := maxi(1, ids.size())
	var gap := 7.0
	var item_width := (rect.size.x - gap * maxf(0.0, count - 1.0)) / float(count)
	var session: Dictionary = placement_state.get("placement_session", {})
	var selected_id := str(session.get("facility_id", "")) if str(session.get("kind", "")) == "facility_tool" else ""
	for index in range(ids.size()):
		var facility_id := str(ids[index])
		var definition: Dictionary = facility_catalog.get(facility_id, {})
		var button = DragButtonScript.new()
		button.name = "FacilityTool_%s" % facility_id
		button.setup_drag("v20_facility", facility_id, "%s\n건설 %d" % [str(definition.get("display_name", facility_id)), int(definition.get("cost", {}).get("build", 0))])
		button.position = Vector2(rect.position.x + index * (item_width + gap), rect.position.y)
		button.size = Vector2(item_width, rect.size.y)
		_style_button(button, facility_id == selected_id, COLOR_GOLD)
		button.pressed.connect(_on_facility_clicked.bind(facility_id))
		parent.add_child(button)


func _build_monster_tools(parent: Control, rect: Rect2) -> void:
	var ids: Array = placement_state.get("roster", {}).keys()
	ids.sort()
	var count := maxi(1, ids.size())
	var gap := 7.0
	var item_width := minf(190.0, (rect.size.x - gap * maxf(0.0, count - 1.0)) / float(count))
	var session: Dictionary = placement_state.get("placement_session", {})
	var selected_id := str(session.get("monster_id", "")) if str(session.get("kind", "")) == "monster" else ""
	for index in range(ids.size()):
		var monster_id := str(ids[index])
		var monster: Dictionary = placement_state.get("roster", {}).get(monster_id, {})
		var button = DragButtonScript.new()
		button.name = "MonsterTool_%s" % monster_id
		button.setup(monster_id, "%s\n현재: %s" % [str(monster.get("display_name", monster_id)), _room_display_name(str(monster.get("room_id", "")))])
		button.position = Vector2(rect.position.x + index * (item_width + gap), rect.position.y)
		button.size = Vector2(item_width, rect.size.y)
		_style_button(button, monster_id == selected_id, COLOR_PURPLE)
		button.pressed.connect(_on_monster_clicked.bind(monster_id))
		parent.add_child(button)


func _build_replacement_confirm(parent: Control) -> void:
	var pending: Dictionary = placement_state.get("pending_replacement", {})
	var panel := _panel(parent, "ReplacementConfirm", Rect2(parent.size.x - 310, 42, 294, 104), Color("#28191cf7"), COLOR_DANGER)
	_label(panel, "기존 시설을 철거하고 교체할까요?", Vector2(12, 7), Vector2(panel.size.x - 24, 24), 12, Color("#ffd4d6"), UIFontScript.ROLE_EMPHASIS)
	_label(panel, "회수 없음 · 손실 %d" % int(pending.get("resource_loss", 0)), Vector2(12, 31), Vector2(panel.size.x - 24, 20), 10, COLOR_MUTED)
	var confirm := _button(panel, "교체 확정", Rect2(12, 58, 130, 34), true)
	confirm.name = "ConfirmReplacement"
	confirm.pressed.connect(_on_confirm_replacement)
	var cancel := _button(panel, "취소", Rect2(150, 58, 132, 34), false)
	cancel.name = "CancelReplacement"
	cancel.pressed.connect(_on_cancel_replacement)


func _on_room_clicked(room_id: String) -> void:
	var session: Dictionary = placement_state.get("placement_session", {})
	match str(session.get("kind", "")):
		"facility_tool":
			_apply_result(PlacementService.place_selected_facility(placement_state, room_id, facility_catalog))
		"monster":
			_apply_result(PlacementService.place_selected_monster(placement_state, room_id))
		_:
			last_result = {"ok": false, "status": "tool_required", "error": "먼저 아래에서 시설이나 몬스터를 선택하세요."}
			_rebuild()


func _on_facility_clicked(facility_id: String) -> void:
	_apply_result(PlacementService.select_facility(placement_state, facility_id, facility_catalog))


func _on_monster_clicked(monster_id: String) -> void:
	_apply_result(PlacementService.select_monster(placement_state, monster_id))


func _on_facility_dropped(facility_id: String, room_id: String) -> void:
	_apply_result(PlacementService.place_facility_drag(placement_state, facility_id, room_id, facility_catalog))


func _on_monster_dropped(monster_id: String, room_id: String) -> void:
	_apply_result(PlacementService.place_monster_drag(placement_state, monster_id, room_id))


func _on_confirm_replacement() -> void:
	_apply_result(PlacementService.confirm_replacement(placement_state, facility_catalog))


func _on_cancel_replacement() -> void:
	_apply_result(PlacementService.cancel_replacement(placement_state))


func _on_undo() -> void:
	_apply_result(PlacementService.undo(placement_state))


func _apply_result(result: Dictionary) -> void:
	var before_engagement := str(current_route.get("first_engagement_node", ""))
	last_result = result.duplicate(true)
	if bool(result.get("ok", false)):
		placement_state = result.get("state", {}).duplicate(true)
		_refresh_route()
		var after_engagement := str(current_route.get("first_engagement_node", ""))
		if before_engagement != "" and after_engagement != "" and before_engagement != after_engagement:
			last_result["feedback"] = "예상 첫 교전이 %s에서 %s(으)로 바뀌었습니다." % [_node_display_name(before_engagement), _node_display_name(after_engagement)]
		var status := str(result.get("status", ""))
		if status in [PlacementService.STATUS_INSTALLED, PlacementService.STATUS_REPLACED, PlacementService.STATUS_MONSTER_PLACED, PlacementService.STATUS_UNDONE]:
			state_changed.emit(placement_state.duplicate(true), last_result.duplicate(true))
	_rebuild()


func _refresh_route() -> void:
	if board_data.is_empty():
		current_route = {}
		return
	var facility_route_costs: Dictionary = {}
	for room_id_value in placement_state.get("rooms", {}).keys():
		var room_id := str(room_id_value)
		var facility_id := str(placement_state.get("rooms", {}).get(room_id, {}).get("facility_id", ""))
		if facility_id == "" or not ROOM_EDGE_IDS.has(room_id):
			continue
		var delta := float(facility_catalog.get(facility_id, {}).get("route_effect", {}).get("cost_delta", 0.0))
		if not is_zero_approx(delta):
			facility_route_costs[str(ROOM_EDGE_IDS.get(room_id, ""))] = delta
	current_route = PathService.find_path(board_data, "entrance", "throne", {"seed": 13, "goal_key": "throne", "facility_route_costs": facility_route_costs})


func _node_position(node_id: String) -> Vector2:
	var value: Array = board_data.get("node_positions", {}).get(node_id, [0.5, 0.5])
	var x := float(value[0]) if value.size() > 0 else 0.5
	var y := float(value[1]) if value.size() > 1 else 0.5
	return _map_rect.position + Vector2(34.0 + x * maxf(1.0, _map_rect.size.x - 68.0), 36.0 + y * maxf(1.0, _map_rect.size.y - 72.0))


func _route_summary() -> String:
	var names: Array[String] = []
	for node_id_value in current_route.get("nodes", []):
		names.append(_node_display_name(str(node_id_value)))
	return "예상 침략  %s" % "  →  ".join(names)


func _feedback_text() -> String:
	if last_result.has("feedback"):
		return str(last_result.get("feedback", ""))
	if not bool(last_result.get("ok", true)):
		return str(last_result.get("error", "배치를 완료하지 못했습니다."))
	match str(last_result.get("status", "")):
		"facility_selected":
			return "선택한 시설을 지도 위치로 드래그하거나 위치를 클릭하세요."
		"monster_selected":
			return "선택한 몬스터를 지도 위치로 드래그하거나 위치를 클릭하세요."
		PlacementService.STATUS_INSTALLED:
			return "시설 설치 완료 · 예상 침략로를 다시 계산했습니다."
		PlacementService.STATUS_MONSTER_PLACED:
			return "몬스터 배치 완료 · 전투 전까지 언제든 바꿀 수 있습니다."
		PlacementService.STATUS_UNDONE:
			return "직전 배치를 되돌렸습니다."
	return "도구를 지도 위치로 직접 드래그하세요. 클릭 후 위치를 눌러도 됩니다."


func _room_button_text(room: Dictionary) -> String:
	var facility_id := str(room.get("facility_id", ""))
	var facility_name := str(facility_catalog.get(facility_id, {}).get("display_name", "시설 없음")) if facility_id != "" else "시설 없음"
	var monster_names: Array[String] = []
	for monster_id_value in room.get("monster_ids", []):
		var monster_id := str(monster_id_value)
		monster_names.append(str(placement_state.get("roster", {}).get(monster_id, {}).get("display_name", monster_id)).split(" · ")[0])
	var monster_line := ", ".join(monster_names) if not monster_names.is_empty() else "몬스터 없음"
	return "%s\n%s\n%s  %d/%d" % [str(room.get("display_name", "방")), facility_name, monster_line, room.get("monster_ids", []).size(), int(room.get("capacity", 0))]


func _room_display_name(room_id: String) -> String:
	if room_id == "":
		return "미배치"
	return str(placement_state.get("rooms", {}).get(room_id, {}).get("display_name", room_id))


func _node_display_name(node_id: String) -> String:
	var names := {
		"entrance": "침입구", "north_gate": "북문", "north_cross": "북부 교차로",
		"south_gate": "남문", "south_cross": "남부 교차로", "treasure": "미끼 보물실",
		"fallback": "후퇴선", "throne": "왕좌"
	}
	return str(names.get(node_id, node_id))


func _placement_allowed(room: Dictionary, definition: Dictionary) -> bool:
	for tag in definition.get("placement_tags", []):
		if room.get("placement_tags", []).has(tag):
			return true
	return false


func _style_room_button(button: Button, room_id: String) -> void:
	var session: Dictionary = placement_state.get("placement_session", {})
	var accent := COLOR_PURPLE
	var selected := false
	if str(session.get("kind", "")) == "facility_tool":
		accent = COLOR_GOLD
		selected = _placement_allowed(placement_state.get("rooms", {}).get(room_id, {}), facility_catalog.get(str(session.get("facility_id", "")), {}))
	elif str(session.get("kind", "")) == "monster":
		selected = true
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT if selected else COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _style(Color("#251c30f2") if selected else Color("#17131ff2"), accent if selected else COLOR_LINE, 2 if selected else 1, 8.0))
	button.add_theme_stylebox_override("hover", _style(Color("#382947"), accent, 2, 8.0))
	button.add_theme_stylebox_override("pressed", _style(Color("#4b3323"), COLOR_GOLD_BRIGHT, 2, 8.0))


func _panel(parent: Control, node_name: String, rect: Rect2, fill: Color, border: Color) -> Panel:
	var result := Panel.new()
	result.name = node_name
	result.position = rect.position
	result.size = rect.size
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_stylebox_override("panel", _style(fill, border, 1, 7.0))
	parent.add_child(result)
	return result


func _label(parent: Control, text_value: String, position: Vector2, label_size: Vector2, font_size: int, color: Color, role: String = UIFontScript.ROLE_BODY, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var result := Label.new()
	result.text = text_value
	result.position = position
	result.size = label_size
	result.horizontal_alignment = align
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.add_theme_font_override("font", UIFontScript.font_for_role(role))
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


func _button(parent: Control, text_value: String, rect: Rect2, selected: bool) -> Button:
	var result := Button.new()
	result.text = text_value
	result.position = rect.position
	result.size = rect.size
	result.focus_mode = Control.FOCUS_ALL
	_style_button(result, selected, COLOR_GOLD)
	parent.add_child(result)
	return result


func _style_button(button: Button, selected: bool, accent: Color) -> void:
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT if selected else COLOR_TEXT)
	button.add_theme_stylebox_override("normal", _style(Color("#2c2138") if selected else COLOR_SOFT, accent if selected else COLOR_LINE, 2 if selected else 1, 6.0))
	button.add_theme_stylebox_override("hover", _style(Color("#382947"), accent, 2, 6.0))
	button.add_theme_stylebox_override("pressed", _style(Color("#4b3323"), COLOR_GOLD_BRIGHT, 2, 6.0))


func _style(fill: Color, border: Color, width: int, radius: float = 6.0) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(width)
	result.set_corner_radius_all(int(radius))
	return result
