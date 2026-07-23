class_name V20PlacementBoard
extends Control

signal state_changed(state: Dictionary, result: Dictionary)

const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const FixedRouteService = preload("res://scripts/v20/path/V20FixedRouteService.gd")
const SpatialModel = preload("res://scripts/v20/spatial/V20SpatialModel.gd")
const DragButtonScript = preload("res://scripts/v20/placement/V20MonsterDragButton.gd")
const RoomButtonScript = preload("res://scripts/v20/placement/V20PlacementRoomButton.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const CASTLE_BACKGROUND = preload("res://assets/sprites/dungeon_gpt2/gpt2_dungeon_connected_map.png")

const BOARD_ID := "v20_day_01_05_board"
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
const COLOR_ROUTE_FIXED := Color("#b84745")
const FACILITY_ORDER := ["v20_barricade", "v20_barracks", "v20_watch_post", "v20_decoy_treasure", "v20_recovery_nest"]
const MONSTER_PORTRAITS := {
	"slime": preload("res://assets/sprites/portraits/onboarding/portrait_pudding.png"),
	"goblin": preload("res://assets/sprites/portraits/onboarding/portrait_gob.png"),
	"imp": preload("res://assets/sprites/portraits/onboarding/portrait_pynn.png")
}
var placement_state: Dictionary = {}
var facility_catalog: Dictionary = {}
var board_data: Dictionary = {}
var current_route: Dictionary = {}
var last_result: Dictionary = {}
var ui_context: Dictionary = {}
var selected_room_id := ""
var _map_rect := Rect2()
var _dock_rect := Rect2()
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
	var inset := 4.0
	var gap := 10.0
	var dock_w := clampf(size.x * 0.275, 304.0, 356.0)
	var available_map_w := size.x - inset * 2.0 - gap - dock_w
	var available_h := size.y - inset * 2.0
	var map_h := minf(available_h, available_map_w * 941.0 / 1672.0)
	var map_y := inset + maxf(0.0, (available_h - map_h) * 0.5)
	_map_rect = Rect2(inset, map_y, available_map_w, map_h)
	_dock_rect = Rect2(_map_rect.end.x + gap, inset, dock_w, available_h)
	_build_route_map(_map_rect)
	_build_tool_tray(_dock_rect)
	queue_redraw()


func _draw() -> void:
	if board_data.is_empty() or _map_rect.size.x <= 0.0:
		return
	draw_style_box(_style(Color("#08070d"), Color("#67543a"), 2, 10.0), _map_rect)
	draw_texture_rect(CASTLE_BACKGROUND, _map_rect.grow(-2.0), false)
	draw_rect(_map_rect.grow(-2.0), Color("#09060c38"), true)
	var route_points := _fixed_route_points()
	for index in range(route_points.size() - 1):
		var start := route_points[index]
		var finish := route_points[index + 1]
		draw_line(start, finish, Color("#23070abd"), 12.0, true)
		draw_line(start, finish, Color(COLOR_ROUTE_FIXED, 0.78), 4.0, true)
		_draw_route_arrow(start, finish)
		var bead := start.lerp(finish, fmod(_route_phase + float(index) * 0.17, 1.0))
		draw_circle(bead, 4.5, Color("#ffb278"))
		draw_circle(bead, 2.2, Color("#6b1518"))
	for section_value in board_data.get("ordered_sections", []):
		var section: Dictionary = section_value
		var anchor := _section_anchor(str(section.get("placement_id", "")))
		draw_circle(anchor, 13.0, Color("#13080ad9"))
		draw_circle(anchor, 8.0, COLOR_ROUTE_FIXED)
		draw_string(UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS), anchor + Vector2(-4, 5), str(section.get("index", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)


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
	draw_colored_polygon(points, Color("#ffb278"))


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
	_label(rail, "확정 침입로", Vector2(16, 195), Vector2(rail.size.x - 32, 20), 11, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
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
	var guide_text := "오른쪽에서 시설 또는 몬스터를 고른 뒤, 빛나는 고정 위치에 놓으세요." if first_action else "길은 바뀌지 않습니다 · 어느 구간에 무엇을 놓느냐가 전략입니다."
	var guide_color := COLOR_GOLD_BRIGHT if first_action else COLOR_TEXT
	if not last_result.is_empty():
		guide_text = _feedback_text()
		guide_color = COLOR_DANGER if not bool(last_result.get("ok", true)) else COLOR_GOLD_BRIGHT
	var route_header := _panel(map, "FixedRouteHeader", Rect2(14, 12, map.size.x - 28, 54), Color("#09070bdb"), Color("#7e3d36"))
	_label(route_header, "확정 침입로", Vector2(14, 5), Vector2(116, 22), 13, Color("#ffab83"), UIFontScript.ROLE_EMPHASIS)
	_label(route_header, _route_display_text(), Vector2(132, 4), Vector2(route_header.size.x - 146, 24), 12, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(route_header, guide_text, Vector2(14, 27), Vector2(route_header.size.x - 28, 21), 10, guide_color, UIFontScript.ROLE_BODY)
	for section_value in board_data.get("ordered_sections", []):
		var section: Dictionary = section_value
		var room_id := str(section.get("placement_id", ""))
		if not placement_state.get("rooms", {}).has(room_id):
			continue
		var local_position := _section_anchor(room_id) - rect.position
		_build_room_button(map, room_id, local_position)
	_label(map, "침입", Vector2(map.size.x * 0.075, map.size.y * 0.79), Vector2(66, 22), 11, Color("#ffb394"), UIFontScript.ROLE_EMPHASIS, HORIZONTAL_ALIGNMENT_CENTER)
	_label(map, "왕좌", Vector2(map.size.x * 0.45, map.size.y * 0.08), Vector2(90, 22), 11, COLOR_GOLD_BRIGHT, UIFontScript.ROLE_EMPHASIS, HORIZONTAL_ALIGNMENT_CENTER)
	if not placement_state.get("pending_replacement", {}).is_empty():
		_build_replacement_confirm(map)


func _build_room_button(parent: Control, room_id: String, center: Vector2) -> void:
	var room: Dictionary = placement_state.get("rooms", {}).get(room_id, {})
	var button = RoomButtonScript.new()
	button.name = "Room_%s" % room_id
	button.setup(room_id, _room_button_text(room), _monster_tokens(room))
	var room_width := clampf(_map_rect.size.x * 0.195, 142.0, 178.0)
	var room_height := clampf(_map_rect.size.y * 0.17, 72.0, 86.0)
	button.position = center - Vector2(room_width * 0.5, room_height * 0.5)
	button.size = Vector2(room_width, room_height)
	button.focus_mode = Control.FOCUS_ALL
	_style_room_button(button, room_id)
	var session: Dictionary = placement_state.get("placement_session", {})
	var valid_target := false
	var accent := COLOR_PURPLE
	if str(session.get("kind", "")) == "facility_tool":
		accent = COLOR_GOLD
		valid_target = _placement_allowed(room, facility_catalog.get(str(session.get("facility_id", "")), {}))
	elif str(session.get("kind", "")) == "monster":
		valid_target = _room_accepts_monster(room, str(session.get("monster_id", "")))
	button.setup_visual(current_route.get("nodes", []).has(room_id), valid_target, room_id == selected_room_id, accent)
	button.pressed.connect(_on_room_clicked.bind(room_id))
	button.monster_dropped.connect(_on_monster_dropped)
	button.facility_dropped.connect(_on_facility_dropped)
	parent.add_child(button)


func _build_tool_tray(rect: Rect2) -> void:
	var tray := _panel(self, "PlacementToolTray", rect, Color("#0e0b13f8"), Color("#69563a"))
	_label(tray, "배치 도구", Vector2(16, 10), Vector2(tray.size.x - 32, 24), 16, COLOR_GOLD_BRIGHT, UIFontScript.ROLE_EMPHASIS)
	_label(tray, "시설과 수비대를 바로 끌어 고정 구역에 놓으세요.", Vector2(16, 33), Vector2(tray.size.x - 32, 18), 9, COLOR_MUTED, UIFontScript.ROLE_BODY)
	var undo_h := 38.0
	var summary_h := 72.0
	var undo_y := tray.size.y - undo_h - 10.0
	var summary_y := undo_y - summary_h - 6.0
	var facility_header_y := 55.0
	var facility_tools_y := facility_header_y + 21.0
	var facility_tools_h := clampf((summary_y - facility_tools_y) * 0.42, 102.0, 124.0)
	var monster_header_y := facility_tools_y + facility_tools_h + 6.0
	var monster_tools_y := monster_header_y + 21.0
	var monster_tools_h := maxf(108.0, summary_y - monster_tools_y - 6.0)
	_label(tray, "시설  ·  건설 %d" % int(placement_state.get("build_points", 0)), Vector2(14, facility_header_y), Vector2(tray.size.x - 28, 18), 11, COLOR_GOLD, UIFontScript.ROLE_EMPHASIS)
	_build_facility_tools(tray, Rect2(12, facility_tools_y, tray.size.x - 24, facility_tools_h))
	_label(tray, "수비대 %d  ·  초상을 끌어 구역에 배치" % int(placement_state.get("roster", {}).size()), Vector2(14, monster_header_y), Vector2(tray.size.x - 28, 18), 11, COLOR_PURPLE, UIFontScript.ROLE_EMPHASIS)
	_build_monster_tools(tray, Rect2(12, monster_tools_y, tray.size.x - 24, monster_tools_h))
	_build_selected_section_summary(tray, Rect2(12, summary_y, tray.size.x - 24, summary_h))
	var undo := _button(tray, "↶  직전 배치 되돌리기", Rect2(12, undo_y, tray.size.x - 24, undo_h), false)
	undo.name = "UndoPlacement"
	undo.disabled = placement_state.get("undo", {}).is_empty()
	undo.pressed.connect(_on_undo)


func _build_facility_tools(parent: Control, rect: Rect2) -> void:
	var ids: Array = []
	for facility_id in FACILITY_ORDER:
		if facility_catalog.has(facility_id):
			ids.append(facility_id)
	for facility_id_value in facility_catalog.keys():
		if not ids.has(facility_id_value):
			ids.append(facility_id_value)
	var columns := 2
	var rows := maxi(1, int(ceil(float(ids.size()) / float(columns))))
	var gap := 7.0
	var item_width := (rect.size.x - gap) * 0.5
	var item_height := (rect.size.y - gap * maxf(0.0, rows - 1.0)) / float(rows)
	var session: Dictionary = placement_state.get("placement_session", {})
	var selected_id := str(session.get("facility_id", "")) if str(session.get("kind", "")) == "facility_tool" else ""
	for index in range(ids.size()):
		var facility_id := str(ids[index])
		var definition: Dictionary = facility_catalog.get(facility_id, {})
		var button = DragButtonScript.new()
		button.name = "FacilityTool_%s" % facility_id
		button.setup_drag("v20_facility", facility_id, "%s\n%s · 건설 %d" % [str(definition.get("display_name", facility_id)), _facility_tool_hint(facility_id), int(definition.get("cost", {}).get("build", 0))])
		var column := index % columns
		var row := index / columns
		button.position = Vector2(rect.position.x + column * (item_width + gap), rect.position.y + row * (item_height + gap))
		button.size = Vector2(item_width, item_height)
		_style_button(button, facility_id == selected_id, COLOR_GOLD)
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_on_facility_clicked.bind(facility_id))
		button.drag_started.connect(_on_tool_drag_started)
		button.drag_finished.connect(_on_tool_drag_finished)
		parent.add_child(button)


func _build_monster_tools(parent: Control, rect: Rect2) -> void:
	var ids: Array = placement_state.get("roster", {}).keys()
	ids.sort()
	var rows := maxi(1, ids.size())
	var gap := 5.0
	var item_height := minf(60.0, (rect.size.y - gap * maxf(0.0, rows - 1.0)) / float(rows))
	var session: Dictionary = placement_state.get("placement_session", {})
	var selected_id := str(session.get("monster_id", "")) if str(session.get("kind", "")) == "monster" else ""
	for index in range(ids.size()):
		var monster_id := str(ids[index])
		var monster: Dictionary = placement_state.get("roster", {}).get(monster_id, {})
		var presentation := _monster_presentation(monster_id, monster)
		var button = DragButtonScript.new()
		button.name = "MonsterTool_%s" % monster_id
		button.setup(monster_id, str(presentation.get("name", monster_id)), str(presentation.get("role", "수비대")), _room_display_name(str(monster.get("room_id", ""))), presentation.get("portrait"))
		button.position = Vector2(rect.position.x, rect.position.y + index * (item_height + gap))
		button.size = Vector2(rect.size.x, item_height)
		_style_button(button, monster_id == selected_id, COLOR_PURPLE)
		button.pressed.connect(_on_monster_clicked.bind(monster_id))
		button.drag_started.connect(_on_tool_drag_started)
		button.drag_finished.connect(_on_tool_drag_finished)
		parent.add_child(button)


func _build_selected_section_summary(parent: Control, rect: Rect2) -> void:
	var room_id := selected_room_id
	if room_id == "" or not placement_state.get("rooms", {}).has(room_id):
		var section_ids: Array = placement_state.get("rooms", {}).keys()
		section_ids.sort_custom(func(a, b): return int(placement_state.get("rooms", {}).get(a, {}).get("section_index", 99)) < int(placement_state.get("rooms", {}).get(b, {}).get("section_index", 99)))
		room_id = str(section_ids[0]) if not section_ids.is_empty() else ""
	var room: Dictionary = placement_state.get("rooms", {}).get(room_id, {})
	var summary := _panel(parent, "SectionSummary", rect, Color("#17111df2"), COLOR_PURPLE if selected_room_id != "" else COLOR_LINE)
	_label(summary, "선택 위치" if selected_room_id != "" else "배치 효과 미리보기", Vector2(12, 5), Vector2(summary.size.x - 24, 18), 9, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
	_label(summary, str(room.get("display_name", "지도에서 위치를 선택하세요")), Vector2(12, 21), Vector2(summary.size.x - 24, 24), 14, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS)
	_label(summary, _section_effect_summary(room_id), Vector2(12, 43), Vector2(summary.size.x - 24, summary.size.y - 48), 10, COLOR_GOLD_BRIGHT, UIFontScript.ROLE_BODY)


func _build_replacement_confirm(parent: Control) -> void:
	var pending: Dictionary = placement_state.get("pending_replacement", {})
	var panel := _panel(parent, "ReplacementConfirm", Rect2(parent.size.x - 310, 42, 294, 104), Color("#28191cf7"), COLOR_DANGER)
	_label(panel, "기존 시설을 철거하고 교체할까요?", Vector2(12, 7), Vector2(panel.size.x - 24, 24), 12, Color("#ffd4d6"), UIFontScript.ROLE_EMPHASIS)
	_label(panel, "기존 시설 비용 %d 회수 뒤 새 비용 재계산" % int(pending.get("resource_loss", 0)), Vector2(12, 31), Vector2(panel.size.x - 24, 20), 10, COLOR_MUTED)
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
	var effect_text := _section_effect_summary(selected_room_id) if facility_id != "" else "배치 도구에서 시설을 골라 설치"
	_label(inspector, effect_text, Vector2(18, 163), Vector2(inspector.size.x - 36, 34), 11, COLOR_MUTED, UIFontScript.ROLE_BODY)
	if facility_id != "":
		var remove := _button(inspector, "시설 제거 · 비용 회수", Rect2(18, 198, inspector.size.x - 36, 30), false)
		remove.name = "RemoveFacilityButton"
		remove.pressed.connect(_on_remove_facility)
	_label(inspector, "배치 몬스터", Vector2(18, 234), Vector2(inspector.size.x - 36, 18), 10, COLOR_MUTED, UIFontScript.ROLE_EMPHASIS)
	var monster_names: Array[String] = []
	for monster_id_value in room.get("monster_ids", []):
		var monster_id := str(monster_id_value)
		monster_names.append(str(placement_state.get("roster", {}).get(monster_id, {}).get("display_name", monster_id)).split(" · ")[0])
	_label(inspector, " · ".join(monster_names) if not monster_names.is_empty() else "아직 없음", Vector2(18, 254), Vector2(inspector.size.x - 36, 42), 14, COLOR_TEXT, UIFontScript.ROLE_EMPHASIS)
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
	_apply_result(PlacementService.select_facility(placement_state, facility_id, facility_catalog))


func _on_monster_clicked(monster_id: String) -> void:
	_apply_result(PlacementService.select_monster(placement_state, monster_id))


func _on_facility_dropped(facility_id: String, room_id: String) -> void:
	selected_room_id = room_id
	_apply_result(PlacementService.place_facility_drag(placement_state, facility_id, room_id, facility_catalog))


func _on_monster_dropped(monster_id: String, room_id: String) -> void:
	selected_room_id = room_id
	_apply_result(PlacementService.place_monster_drag(placement_state, monster_id, room_id))


func _on_confirm_replacement() -> void:
	_apply_result(PlacementService.confirm_replacement(placement_state, facility_catalog))


func _on_cancel_replacement() -> void:
	_apply_result(PlacementService.cancel_replacement(placement_state))


func _on_remove_facility() -> void:
	_apply_result(PlacementService.remove_facility(placement_state, selected_room_id, facility_catalog))


func _on_undo() -> void:
	_apply_result(PlacementService.undo(placement_state))


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
		var valid := _room_accepts_monster(room, item_id)
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
	last_result = result.duplicate(true)
	if bool(result.get("ok", false)):
		placement_state = result.get("state", {}).duplicate(true)
		_refresh_route()
		var status := str(result.get("status", ""))
		if status in [PlacementService.STATUS_INSTALLED, PlacementService.STATUS_REPLACED, PlacementService.STATUS_FACILITY_REMOVED, PlacementService.STATUS_FACILITY_MOVED, PlacementService.STATUS_MONSTER_PLACED, PlacementService.STATUS_UNDONE]:
			state_changed.emit(placement_state.duplicate(true), last_result.duplicate(true))
	_queue_rebuild()


func _refresh_route() -> void:
	if board_data.is_empty():
		current_route = {}
		return
	current_route = FixedRouteService.full_route(board_data)


func _node_position(node_id: String) -> Vector2:
	var value: Array = board_data.get("node_positions", {}).get(node_id, [0.5, 0.5])
	var x := float(value[0]) if value.size() > 0 else 0.5
	var y := float(value[1]) if value.size() > 1 else 0.5
	return _map_rect.position + Vector2(x * _map_rect.size.x, y * _map_rect.size.y)


func _section_anchor(room_id: String) -> Vector2:
	var anchor: Array = SpatialModel.zone(board_data, room_id).get("board_anchor", [])
	if anchor.size() >= 2:
		return _map_rect.position + Vector2(float(anchor[0]) * _map_rect.size.x, float(anchor[1]) * _map_rect.size.y)
	return _node_position(room_id)


func _fixed_route_points() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for waypoint_value in board_data.get("route_waypoints", []):
		var waypoint: Array = waypoint_value
		if waypoint.size() == 2:
			result.append(_map_rect.position + Vector2(float(waypoint[0]), float(waypoint[1])) * _map_rect.size)
	if result.is_empty():
		for node_id_value in board_data.get("fixed_route", {}).get("nodes", []):
			result.append(_node_position(str(node_id_value)))
	return result


func _route_summary() -> String:
	var names: Array[String] = []
	for node_id_value in current_route.get("nodes", []):
		names.append(_node_display_name(str(node_id_value)))
	return "확정 침입로  %s" % "  →  ".join(names)


func _compact_route_summary() -> String:
	var names: Array[String] = []
	for node_id_value in current_route.get("nodes", []):
		var node_id := str(node_id_value)
		if node_id == "throne":
			continue
		names.append(_node_display_name(node_id))
	return " → ".join(names) if not names.is_empty() else "확정 경로 준비 중"


func _recommended_response() -> String:
	var title := str(ui_context.get("intrusion_title", ""))
	if "공병" in title:
		return "시설 분산\n집중 명령 준비"
	if "도둑" in title or "보물" in title:
		return "중앙 감시\n도둑 감속"
	return "성문 지연\n왕좌 전실 확보"


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
			return "시설 설치 완료 · 이 구간의 전투 효과가 바뀌었습니다."
		PlacementService.STATUS_MONSTER_PLACED:
			return "몬스터 배치 완료 · 같은 길에서도 첫 교전 위치가 달라집니다."
		PlacementService.STATUS_UNDONE:
			return "직전 배치를 되돌렸습니다."
	return "도구를 지도 위치로 직접 드래그하세요. 클릭 후 위치를 눌러도 됩니다."


func _section_effect_summary(room_id: String) -> String:
	var room: Dictionary = placement_state.get("rooms", {}).get(room_id, {})
	if room.is_empty():
		return "시설과 몬스터를 어느 구간에 둘지 정하세요."
	var installed_facility_id := str(room.get("facility_id", ""))
	var session: Dictionary = placement_state.get("placement_session", {})
	var preview_facility_id := str(session.get("facility_id", "")) if str(session.get("kind", "")) == "facility_tool" else ""
	var facility_id := preview_facility_id if preview_facility_id != "" else installed_facility_id
	var facility_effects := {
		"v20_barricade": "적 이동을 늦춰 이 구간의 교전 시간을 늘립니다.",
		"v20_barracks": "이 구간 몬스터의 공격과 생존력을 높입니다.",
		"v20_decoy_treasure": "도둑의 발을 묶어 약탈 대응 시간을 늘립니다.",
		"v20_watch_post": "이 구간과 다음 구간의 적을 감속·노출합니다.",
		"v20_recovery_nest": "이 구간에 머무는 몬스터를 회복시킵니다."
	}
	var placement_hint := str(room.get("strategy_hint", "고정 구간의 역할을 확인하세요."))
	if facility_id == "":
		return "%s\n◇ 시설 비어 있음  ·  ● 몬스터 %d/%d" % [placement_hint, room.get("monster_ids", []).size(), int(room.get("capacity", 0))]
	var prefix := "배치 예정 · " if preview_facility_id != "" and preview_facility_id != installed_facility_id else ""
	return "%s\n%s%s" % [placement_hint, prefix, str(facility_effects.get(facility_id, "선택한 시설 효과가 이 구간에 적용됩니다."))]


func _facility_tool_hint(facility_id: String) -> String:
	return str({
		"v20_barricade": "적 감속",
		"v20_barracks": "공격·생존",
		"v20_watch_post": "인접 감속",
		"v20_decoy_treasure": "도둑 지연",
		"v20_recovery_nest": "구역 회복"
	}.get(facility_id, "구역 효과"))


func _monster_presentation(monster_id: String, roster_entry: Dictionary) -> Dictionary:
	var species_id := _monster_species_id(monster_id)
	var display_text := str(roster_entry.get("display_name", monster_id))
	var display_parts := display_text.split(" · ", false, 1)
	var definition: Dictionary = DataRegistry.monster(species_id)
	return {
		"name": str(display_parts[0]) if not display_parts.is_empty() else display_text,
		"role": str(display_parts[1]) if display_parts.size() > 1 else str(definition.get("role", "수비대")),
		"portrait": MONSTER_PORTRAITS.get(species_id)
	}


func _monster_species_id(monster_id: String) -> String:
	for species_id_value in MONSTER_PORTRAITS.keys():
		var species_id := str(species_id_value)
		if monster_id == species_id or monster_id.begins_with("%s_" % species_id):
			return species_id
	return monster_id


func _monster_tokens(room: Dictionary) -> Array:
	var result: Array = []
	for monster_id_value in room.get("monster_ids", []):
		var monster_id := str(monster_id_value)
		var portrait = MONSTER_PORTRAITS.get(_monster_species_id(monster_id))
		if portrait is Texture2D:
			result.append({"monster_id": monster_id, "texture": portrait})
	return result


func _room_accepts_monster(room: Dictionary, monster_id: String) -> bool:
	if monster_id == "":
		return false
	var monster_ids: Array = room.get("monster_ids", [])
	return monster_ids.has(monster_id) or monster_ids.size() < int(room.get("capacity", 0))


func _room_button_text(room: Dictionary) -> String:
	var facility_id := str(room.get("facility_id", ""))
	var facility_name := str(facility_catalog.get(facility_id, {}).get("display_name", "시설 없음")) if facility_id != "" else "시설 없음"
	return "%s\n◇ %s\n● 수비대  %d/%d" % [str(room.get("display_name", "방")), facility_name, room.get("monster_ids", []).size(), int(room.get("capacity", 0))]


func _room_display_name(room_id: String) -> String:
	if room_id == "":
		return "미배치"
	return str(placement_state.get("rooms", {}).get(room_id, {}).get("display_name", room_id))


func _node_display_name(node_id: String) -> String:
	return str(SpatialModel.zone(board_data, node_id).get("display_name", node_id))


func _route_display_text() -> String:
	var labels: Array[String] = []
	for zone_id_value in board_data.get("fixed_route", {}).get("nodes", []):
		labels.append(_node_display_name(str(zone_id_value)))
	return "  →  ".join(labels)


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
