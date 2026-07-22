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
const COLOR_GREEN := Color("#58c997")
const TOOL_FACILITY := "facility"
const TOOL_MONSTER := "monster"

var placement_state: Dictionary = {}
var facility_catalog: Dictionary = {}
var board_data: Dictionary = {}
var current_route: Dictionary = {}
var last_result: Dictionary = {}
var ui_context: Dictionary = {}
var selected_room_id := ""
var active_tool := TOOL_FACILITY
var _map_rect := Rect2()
var _rebuild_queued := false
var _route_phase := 0.0


func _ready() -> void:
	resized.connect(_queue_rebuild)
	set_process(true)


func setup(state_value: Dictionary, facilities: Dictionary, board_value: Dictionary = {}, context_value: Dictionary = {}) -> void:
	placement_state = state_value.duplicate(true)
	facility_catalog = facilities.duplicate(true)
	board_data = board_value.duplicate(true)
	ui_context = context_value.duplicate(true)
	if board_data.is_empty():
		board_data = DataRegistry.v20_dungeon_layouts.get(BOARD_ID, {}).duplicate(true)
	_refresh_route()
	_rebuild()


func _process(delta: float) -> void:
	_route_phase = fmod(_route_phase + delta * 0.42, 1.0)
	if is_visible_in_tree() and _map_rect.size.x > 0.0:
		queue_redraw()


func _queue_rebuild() -> void:
	if _rebuild_queued or placement_state.is_empty():
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _rebuild() -> void:
	_rebuild_queued = false
	for child in get_children():
		child.free()
	if size.x < 640.0 or size.y < 360.0:
		return
	_refresh_route()
	var inset := 8.0
	var header_h := 48.0
	var tray_h := clampf(size.y * 0.205, 100.0, 122.0)
	var content_y := inset + header_h + 6.0
	var content_h := size.y - content_y - tray_h - 14.0
	var rail_w := clampf(size.x * 0.165, 170.0, 224.0)
	var inspector_w := clampf(size.x * 0.19, 210.0, 270.0) if selected_room_id != "" else 0.0
	var gap := 10.0
	var map_x := inset + rail_w + gap
	var map_w := size.x - map_x - inset - (inspector_w + gap if inspector_w > 0.0 else 0.0)
	_map_rect = Rect2(map_x, content_y, map_w, content_h)
	_build_step_ribbon(Rect2(inset, 4, size.x - inset * 2.0, header_h))
	_build_threat_rail(Rect2(inset, content_y, rail_w, content_h))
	_build_route_map(_map_rect)
	if inspector_w > 0.0:
		_build_room_inspector(Rect2(_map_rect.end.x + gap, content_y, inspector_w, content_h))
	_build_tool_tray(Rect2(inset, size.y - tray_h - inset, size.x - inset * 2.0, tray_h))
	queue_redraw()


func _draw() -> void:
	if board_data.is_empty() or _map_rect.size.x <= 0.0:
		return
	draw_style_box(_style(Color("#08070dcf"), Color("#4b3f52"), 1, 10.0), _map_rect)
	var grid_color := Color("#d9bd7a0b")
	var grid_step := 42.0
	var x := _map_rect.position.x + grid_step
	while x < _map_rect.end.x:
		draw_line(Vector2(x, _map_rect.position.y + 8), Vector2(x, _map_rect.end.y - 8), grid_color, 1.0)
		x += grid_step
	var y := _map_rect.position.y + grid_step
	while y < _map_rect.end.y:
		draw_line(Vector2(_map_rect.position.x + 8, y), Vector2(_map_rect.end.x - 8, y), grid_color, 1.0)
		y += grid_step
	for edge_value in board_data.get("edges", []):
		var edge: Dictionary = edge_value
		var start := _node_position(str(edge.get("from", "")))
		var finish := _node_position(str(edge.get("to", "")))
		draw_line(start, finish, Color("#423a49"), 4.0, true)
		draw_line(start, finish, Color("#1d1821"), 1.5, true)
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
		var bead := start.lerp(finish, fmod(_route_phase + float(active_edges.find(str(edge.get("id", "")))) * 0.22, 1.0))
		draw_circle(bead, 5.5, Color("#fff1b8"))
		draw_circle(bead, 2.5, COLOR_GOLD)
	for node_id_value in board_data.get("nodes", []):
		var node_id := str(node_id_value)
		var active: bool = current_route.get("nodes", []).has(node_id)
		draw_circle(_node_position(node_id), 12.0 if active else 8.0, Color("#f6d47c") if active else Color("#71637b"))
		draw_circle(_node_position(node_id), 5.0, COLOR_VOID)


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
	var ribbon := _panel(self, "PlacementSteps", rect, Color("#0e0c13f5"), Color("#6a5634"))
	_label(ribbon, "전장 설계", Vector2(16, 5), Vector2(112, 34), 18, COLOR_GOLD_BRIGHT, UIFontScript.ROLE_EMPHASIS)
	_label(ribbon, "01  침략로", Vector2(132, 6), Vector2(100, 32), 12, COLOR_GOLD, UIFontScript.ROLE_EMPHASIS, HORIZONTAL_ALIGNMENT_CENTER)
	_label(ribbon, "02  배치", Vector2(236, 6), Vector2(86, 32), 12, COLOR_GREEN if not placement_state.get("last_action", {}).is_empty() else COLOR_TEXT, UIFontScript.ROLE_EMPHASIS, HORIZONTAL_ALIGNMENT_CENTER)
	_label(ribbon, "03  방어", Vector2(326, 6), Vector2(86, 32), 12, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS, HORIZONTAL_ALIGNMENT_CENTER)
	_label(ribbon, _route_summary(), Vector2(424, 5), Vector2(ribbon.size.x - 440, 34), 12, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS, HORIZONTAL_ALIGNMENT_RIGHT)


func _build_threat_rail(rect: Rect2) -> void:
	var rail := _panel(self, "ThreatRail", rect, Color("#120e16f3"), Color("#6b3e48"))
	_label(rail, "오늘의 위협", Vector2(16, 14), Vector2(rail.size.x - 32, 24), 14, Color("#ffb17b"), UIFontScript.ROLE_EMPHASIS)
	_label(rail, str(ui_context.get("intrusion_title", "침입대가 왕좌를 노립니다")), Vector2(16, 42), Vector2(rail.size.x - 32, 54), 17, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS)
	var divider := ColorRect.new()
	divider.position = Vector2(16, 104)
	divider.size = Vector2(rail.size.x - 32, 1)
	divider.color = Color("#6b3e4866")
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.add_child(divider)
	_label(rail, "추천 대응", Vector2(16, 116), Vector2(rail.size.x - 32, 20), 11, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
	_label(rail, _recommended_response(), Vector2(16, 139), Vector2(rail.size.x - 32, 48), 14, COLOR_GOLD_BRIGHT, UIFontScript.ROLE_EMPHASIS)
	_label(rail, "현재 예상 경로", Vector2(16, 195), Vector2(rail.size.x - 32, 20), 11, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
	_label(rail, _compact_route_summary(), Vector2(16, 218), Vector2(rail.size.x - 32, 54), 13, COLOR_GOLD, UIFontScript.ROLE_EMPHASIS)
	var room_count := int(placement_state.get("rooms", {}).size())
	var roster_count := int(placement_state.get("roster", {}).size())
	_label(rail, "준비 현황", Vector2(16, rail.size.y - 76), Vector2(rail.size.x - 32, 18), 10, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
	_label(rail, "배치 방 %d · 몬스터 %d" % [room_count, roster_count], Vector2(16, rail.size.y - 54), Vector2(rail.size.x - 32, 32), 12, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS)


func _build_route_map(rect: Rect2) -> void:
	var map := Control.new()
	map.name = "RouteMap"
	map.position = rect.position
	map.size = rect.size
	map.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(map)
	var first_action: bool = placement_state.get("last_action", {}).is_empty()
	var guide_text := "첫 수: 바리케이드를 골라 북문을 누르세요 · 드래그도 가능" if first_action else "금빛 흐름 = 실제 전투 경로 · 배치 직후 자동 갱신"
	var guide_color := COLOR_GOLD_BRIGHT if first_action else COLOR_MUTED
	if not last_result.is_empty():
		guide_text = _feedback_text()
		guide_color = COLOR_DANGER if not bool(last_result.get("ok", true)) else COLOR_GOLD_BRIGHT
	_label(
		map,
		guide_text,
		Vector2(18, 7),
		Vector2(map.size.x - 36, 30),
		12,
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
	var room_width := clampf(_map_rect.size.x * 0.18, 112.0, 148.0)
	button.position = center - Vector2(room_width * 0.5, 35)
	button.size = Vector2(room_width, 70)
	button.focus_mode = Control.FOCUS_ALL
	_style_room_button(button, room_id)
	var session: Dictionary = placement_state.get("placement_session", {})
	var valid_target := false
	var accent := COLOR_PURPLE
	if str(session.get("kind", "")) == "facility_tool":
		accent = COLOR_GOLD
		valid_target = _placement_allowed(room, facility_catalog.get(str(session.get("facility_id", "")), {}))
	elif str(session.get("kind", "")) == "monster":
		valid_target = int(room.get("monster_ids", []).size()) < int(room.get("capacity", 0))
	button.setup_visual(current_route.get("nodes", []).has(room_id), valid_target, room_id == selected_room_id, accent)
	button.pressed.connect(_on_room_clicked.bind(room_id))
	button.monster_dropped.connect(_on_monster_dropped)
	button.facility_dropped.connect(_on_facility_dropped)
	parent.add_child(button)


func _build_tool_tray(rect: Rect2) -> void:
	var tray := _panel(self, "PlacementToolTray", rect, Color("#100d15f7"), Color("#69563a"))
	var mode_w := clampf(tray.size.x * 0.135, 132.0, 170.0)
	var undo_width := clampf(tray.size.x * 0.105, 112.0, 138.0)
	var mode_h := (tray.size.y - 22.0) * 0.5
	var facility_mode := _button(tray, "건설  %d" % int(placement_state.get("build_points", 0)), Rect2(10, 8, mode_w, mode_h), active_tool == TOOL_FACILITY)
	facility_mode.name = "FacilityMode"
	facility_mode.pressed.connect(_set_active_tool.bind(TOOL_FACILITY))
	var monster_mode := _button(tray, "몬스터 배치", Rect2(10, 12 + mode_h, mode_w, mode_h), active_tool == TOOL_MONSTER)
	monster_mode.name = "MonsterMode"
	_style_button(monster_mode, active_tool == TOOL_MONSTER, COLOR_PURPLE)
	monster_mode.pressed.connect(_set_active_tool.bind(TOOL_MONSTER))
	var tools_x := mode_w + 22.0
	var tools_width := tray.size.x - tools_x - undo_width - 24.0
	_label(tray, "시설 선택 → 방 선택" if active_tool == TOOL_FACILITY else "몬스터 선택 → 방 선택", Vector2(tools_x, 5), Vector2(tools_width, 20), 10, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
	if active_tool == TOOL_FACILITY:
		_build_facility_tools(tray, Rect2(tools_x, 28, tools_width, tray.size.y - 38))
	else:
		_build_monster_tools(tray, Rect2(tools_x, 28, tools_width, tray.size.y - 38))
	var undo := _button(tray, "↶  되돌리기", Rect2(tray.size.x - undo_width - 10, 12, undo_width, tray.size.y - 24), false)
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
		button.drag_started.connect(_on_tool_drag_started)
		button.drag_finished.connect(_on_tool_drag_finished)
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
		button.setup(monster_id, "%s\n%s" % [str(monster.get("display_name", monster_id)), _room_display_name(str(monster.get("room_id", "")))])
		button.position = Vector2(rect.position.x + index * (item_width + gap), rect.position.y)
		button.size = Vector2(item_width, rect.size.y)
		_style_button(button, monster_id == selected_id, COLOR_PURPLE)
		button.pressed.connect(_on_monster_clicked.bind(monster_id))
		button.drag_started.connect(_on_tool_drag_started)
		button.drag_finished.connect(_on_tool_drag_finished)
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


func _build_room_inspector(rect: Rect2) -> void:
	var room: Dictionary = placement_state.get("rooms", {}).get(selected_room_id, {})
	if room.is_empty():
		selected_room_id = ""
		return
	var inspector := _panel(self, "RoomInspector", rect, Color("#130f19f7"), COLOR_PURPLE)
	_label(inspector, "선택한 방", Vector2(18, 14), Vector2(inspector.size.x - 58, 18), 10, COLOR_PURPLE, UIFontScript.ROLE_EMPHASIS)
	_label(inspector, str(room.get("display_name", selected_room_id)), Vector2(18, 34), Vector2(inspector.size.x - 56, 34), 21, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS)
	var close := _button(inspector, "×", Rect2(inspector.size.x - 42, 12, 30, 30), false)
	close.name = "CloseRoomInspector"
	close.pressed.connect(_close_room_inspector)
	var capacity := int(room.get("capacity", 0))
	var used := int(room.get("monster_ids", []).size())
	_label(inspector, "수비 인원  %d / %d" % [used, capacity], Vector2(18, 72), Vector2(inspector.size.x - 36, 24), 12, COLOR_GREEN if used < capacity else COLOR_GOLD, UIFontScript.ROLE_EMPHASIS)
	var facility_id := str(room.get("facility_id", ""))
	var facility_name := str(facility_catalog.get(facility_id, {}).get("display_name", "비어 있음")) if facility_id != "" else "비어 있음"
	_label(inspector, "시설", Vector2(18, 112), Vector2(inspector.size.x - 36, 18), 10, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
	_label(inspector, facility_name, Vector2(18, 132), Vector2(inspector.size.x - 36, 28), 17, COLOR_GOLD_BRIGHT, UIFontScript.ROLE_EMPHASIS)
	var route_delta := float(facility_catalog.get(facility_id, {}).get("route_effect", {}).get("cost_delta", 0.0)) if facility_id != "" else 0.0
	var effect_text := "경로 비용 +%.0f · 적 우회 유도" % route_delta if route_delta > 0.0 else "배치 도구에서 시설을 골라 설치"
	_label(inspector, effect_text, Vector2(18, 163), Vector2(inspector.size.x - 36, 34), 11, COLOR_MUTED, UIFontScript.ROLE_BODY)
	_label(inspector, "배치 몬스터", Vector2(18, 212), Vector2(inspector.size.x - 36, 18), 10, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
	var monster_names: Array[String] = []
	for monster_id_value in room.get("monster_ids", []):
		var monster_id := str(monster_id_value)
		monster_names.append(str(placement_state.get("roster", {}).get(monster_id, {}).get("display_name", monster_id)).split(" · ")[0])
	_label(inspector, " · ".join(monster_names) if not monster_names.is_empty() else "아직 없음", Vector2(18, 234), Vector2(inspector.size.x - 36, 42), 14, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS)
	_label(inspector, "세부 정보는 선택했을 때만 열립니다.", Vector2(18, inspector.size.y - 42), Vector2(inspector.size.x - 36, 24), 9, COLOR_MUTED, UIFontScript.ROLE_BODY)


func _on_room_clicked(room_id: String) -> void:
	var session: Dictionary = placement_state.get("placement_session", {})
	match str(session.get("kind", "")):
		"facility_tool":
			selected_room_id = room_id
			_apply_result(PlacementService.place_selected_facility(placement_state, room_id, facility_catalog))
		"monster":
			selected_room_id = room_id
			_apply_result(PlacementService.place_selected_monster(placement_state, room_id))
		_:
			selected_room_id = "" if selected_room_id == room_id else room_id
			last_result = {}
			_queue_rebuild()


func _on_facility_clicked(facility_id: String) -> void:
	active_tool = TOOL_FACILITY
	_apply_result(PlacementService.select_facility(placement_state, facility_id, facility_catalog))


func _on_monster_clicked(monster_id: String) -> void:
	active_tool = TOOL_MONSTER
	_apply_result(PlacementService.select_monster(placement_state, monster_id))


func _on_facility_dropped(facility_id: String, room_id: String) -> void:
	if active_tool != TOOL_FACILITY:
		_reject_cross_tool_drop("건설 도구를 선택한 뒤 시설을 놓으세요.")
		return
	selected_room_id = room_id
	_apply_result(PlacementService.place_facility_drag(placement_state, facility_id, room_id, facility_catalog))


func _on_monster_dropped(monster_id: String, room_id: String) -> void:
	if active_tool != TOOL_MONSTER:
		_reject_cross_tool_drop("몬스터 배치 도구를 선택한 뒤 몬스터를 놓으세요.")
		return
	selected_room_id = room_id
	_apply_result(PlacementService.place_monster_drag(placement_state, monster_id, room_id))


func _reject_cross_tool_drop(message: String) -> void:
	placement_state["placement_session"] = {}
	last_result = {"ok": false, "status": "inactive_tool_drop", "error": message}
	_queue_rebuild()


func _on_confirm_replacement() -> void:
	_apply_result(PlacementService.confirm_replacement(placement_state, facility_catalog))


func _on_cancel_replacement() -> void:
	_apply_result(PlacementService.cancel_replacement(placement_state))


func _on_undo() -> void:
	_apply_result(PlacementService.undo(placement_state))


func _set_active_tool(tool_id: String) -> void:
	if tool_id not in [TOOL_FACILITY, TOOL_MONSTER] or active_tool == tool_id:
		return
	active_tool = tool_id
	placement_state["placement_session"] = {}
	last_result = {}
	_queue_rebuild()


func _close_room_inspector() -> void:
	selected_room_id = ""
	_queue_rebuild()


func _on_tool_drag_started(kind: String, item_id: String) -> void:
	for room_id_value in placement_state.get("rooms", {}).keys():
		var room_id := str(room_id_value)
		var button = get_node_or_null("RouteMap/Room_%s" % room_id)
		if button == null or not button.has_method("setup_visual"):
			continue
		var room: Dictionary = placement_state.get("rooms", {}).get(room_id, {})
		var valid := int(room.get("monster_ids", []).size()) < int(room.get("capacity", 0))
		var accent := COLOR_PURPLE
		if kind == "v20_facility":
			accent = COLOR_GOLD
			valid = _placement_allowed(room, facility_catalog.get(item_id, {}))
		button.setup_visual(current_route.get("nodes", []).has(room_id), valid, room_id == selected_room_id, accent)


func _on_tool_drag_finished() -> void:
	for room_id_value in placement_state.get("rooms", {}).keys():
		var room_id := str(room_id_value)
		var button = get_node_or_null("RouteMap/Room_%s" % room_id)
		if button != null and button.has_method("setup_visual"):
			button.setup_visual(current_route.get("nodes", []).has(room_id), false, room_id == selected_room_id, COLOR_PURPLE)


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
	_queue_rebuild()


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


func _compact_route_summary() -> String:
	var names: Array[String] = []
	for node_id_value in current_route.get("nodes", []):
		var node_id := str(node_id_value)
		if node_id in ["entrance", "throne"]:
			continue
		names.append(_node_display_name(node_id))
	return " → ".join(names) if not names.is_empty() else "정찰 중"


func _recommended_response() -> String:
	var title := str(ui_context.get("intrusion_title", ""))
	if "공병" in title:
		return "시설 분산\n집중 명령 준비"
	if "도둑" in title or "보물" in title:
		return "남문 감시\n미끼 방어"
	return "첫 교전 분산\n후퇴선 확보"


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
	var transparent := _style(Color("#00000000"), Color("#00000000"), 0, 0.0)
	button.add_theme_stylebox_override("normal", transparent)
	button.add_theme_stylebox_override("hover", transparent)
	button.add_theme_stylebox_override("pressed", transparent)
	button.add_theme_stylebox_override("focus", transparent)


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
	button.add_theme_color_override("font_disabled_color", Color("#756e79"))
	button.add_theme_stylebox_override("normal", _style(Color("#2c2138") if selected else COLOR_SOFT, accent if selected else COLOR_LINE, 2 if selected else 1, 6.0))
	button.add_theme_stylebox_override("hover", _style(Color("#382947"), accent, 2, 6.0))
	button.add_theme_stylebox_override("pressed", _style(Color("#4b3323"), COLOR_GOLD_BRIGHT, 2, 6.0))
	button.add_theme_stylebox_override("disabled", _style(Color("#111017dd"), Color("#39323e"), 1, 6.0))


func _style(fill: Color, border: Color, width: int, radius: float = 6.0) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(width)
	result.set_corner_radius_all(int(radius))
	if fill.a > 0.1:
		result.shadow_color = Color("#00000055")
		result.shadow_size = 3
	return result
