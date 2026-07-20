class_name V20PlacementBoard
extends Control

signal state_changed(state: Dictionary, result: Dictionary)

const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const MonsterButtonScript = preload("res://scripts/v20/placement/V20MonsterDragButton.gd")
const RoomButtonScript = preload("res://scripts/v20/placement/V20PlacementRoomButton.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")

var placement_state: Dictionary = {}
var facility_catalog: Dictionary = {}
var last_result: Dictionary = {}
var _rebuild_queued := false


func _ready() -> void:
	resized.connect(_queue_rebuild)


func setup(state_value: Dictionary, facilities: Dictionary) -> void:
	placement_state = state_value.duplicate(true)
	facility_catalog = facilities.duplicate(true)
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
	if size.x < 480.0 or size.y < 300.0:
		return
	var roster_width := clampf(size.x * 0.18, 150.0, 210.0)
	var palette_width := clampf(size.x * 0.22, 190.0, 250.0)
	var map_x := roster_width + 20.0
	var map_width := size.x - roster_width - palette_width - 52.0
	_build_roster(Rect2(8, 8, roster_width, size.y - 16))
	_build_rooms(Rect2(map_x, 8, map_width, size.y - 16))
	_build_facility_palette(Rect2(size.x - palette_width - 8, 8, palette_width, size.y - 16))


func _build_roster(rect: Rect2) -> void:
	var panel := _panel("MonsterRoster", rect, Color("#100e16e8"), Color("#4d4158"))
	_label(panel, "몬스터", Vector2(12, 10), Vector2(panel.size.x - 24, 28), 16, Color("#f3eadc"), UIFontScript.ROLE_EMPHASIS)
	_label(panel, "드래그 또는 클릭", Vector2(12, 36), Vector2(panel.size.x - 24, 20), 10, Color("#a99fb3"))
	var ids: Array = placement_state.get("roster", {}).keys()
	ids.sort()
	var y := 68.0
	var selected_id := str(placement_state.get("placement_session", {}).get("monster_id", ""))
	for monster_id_value in ids:
		var monster_id := str(monster_id_value)
		var monster: Dictionary = placement_state.get("roster", {}).get(monster_id, {})
		var button = MonsterButtonScript.new()
		button.name = "Monster_%s" % monster_id
		button.setup(monster_id, str(monster.get("display_name", monster_id)))
		button.position = Vector2(12, y)
		button.size = Vector2(panel.size.x - 24, 48)
		_style_button(button, monster_id == selected_id)
		button.pressed.connect(_on_monster_clicked.bind(monster_id))
		panel.add_child(button)
		var room_name := _room_display_name(str(monster.get("room_id", "")))
		button.text = "%s\n%s" % [button.text, room_name if room_name != "" else "미배치"]
		y += 58.0


func _build_rooms(rect: Rect2) -> void:
	var panel := _panel("RoomMap", rect, Color("#0908106f"), Color("#3e3547"))
	_label(panel, "배치 지도", Vector2(14, 10), Vector2(panel.size.x - 28, 24), 14, Color("#bdb3c6"), UIFontScript.ROLE_EMPHASIS)
	var ids: Array = placement_state.get("rooms", {}).keys()
	ids.sort()
	var positions := _room_positions(ids.size(), panel.size)
	var selected_room := str(placement_state.get("placement_session", {}).get("room_id", ""))
	for index in range(ids.size()):
		var room_id := str(ids[index])
		var room: Dictionary = placement_state.get("rooms", {}).get(room_id, {})
		var room_button = RoomButtonScript.new()
		room_button.name = "Room_%s" % room_id
		room_button.setup(room_id, _room_button_text(room))
		room_button.position = positions[index]
		room_button.size = Vector2(clampf(panel.size.x * 0.30, 150.0, 220.0), 86)
		_style_button(room_button, room_id == selected_room)
		room_button.pressed.connect(_on_room_clicked.bind(room_id))
		room_button.monster_dropped.connect(_on_monster_dropped)
		panel.add_child(room_button)
	_label(panel, "시설 슬롯을 누르면 오른쪽에 유효 시설만 표시됩니다.", Vector2(14, panel.size.y - 30), Vector2(panel.size.x - 28, 20), 10, Color("#a99fb3"))


func _build_facility_palette(rect: Rect2) -> void:
	var panel := _panel("FacilityPalette", rect, Color("#100e16e8"), Color("#6e5630"))
	_label(panel, "시설", Vector2(12, 10), Vector2(panel.size.x - 24, 28), 16, Color("#ffe4a0"), UIFontScript.ROLE_EMPHASIS)
	var session: Dictionary = placement_state.get("placement_session", {})
	var room_id := str(session.get("room_id", "")) if str(session.get("kind", "")) == "facility" else ""
	if room_id == "":
		_label(panel, "지도에서 빈 슬롯이나\n교체할 시설을 선택하세요.", Vector2(12, 48), Vector2(panel.size.x - 24, 60), 12, Color("#bdb3c6"), UIFontScript.ROLE_BODY, TextServer.AUTOWRAP_WORD_SMART)
	else:
		_label(panel, _room_display_name(room_id), Vector2(12, 44), Vector2(panel.size.x - 24, 24), 13, Color("#f3eadc"), UIFontScript.ROLE_EMPHASIS)
		var facility_ids: Array = facility_catalog.keys()
		facility_ids.sort()
		var y := 78.0
		for facility_id_value in facility_ids:
			var facility_id := str(facility_id_value)
			var definition: Dictionary = facility_catalog.get(facility_id, {})
			if not _placement_allowed(placement_state.get("rooms", {}).get(room_id, {}), definition):
				continue
			var facility_button := Button.new()
			facility_button.name = "Facility_%s" % facility_id
			facility_button.text = "%s  ·  %d" % [str(definition.get("display_name", facility_id)), int(definition.get("cost", {}).get("build", 0))]
			facility_button.position = Vector2(12, y)
			facility_button.size = Vector2(panel.size.x - 24, 44)
			_style_button(facility_button, false)
			facility_button.pressed.connect(_on_facility_clicked.bind(facility_id))
			panel.add_child(facility_button)
			y += 52.0
	var pending: Dictionary = placement_state.get("pending_replacement", {})
	if not pending.is_empty():
		var confirm := _panel_child(panel, "ReplacementConfirm", Rect2(12, panel.size.y - 154, panel.size.x - 24, 96), Color("#28191cf2"), Color("#e56a72"))
		_label(confirm, "기존 시설을 철거합니다", Vector2(10, 8), Vector2(confirm.size.x - 20, 24), 12, Color("#ffd4d6"), UIFontScript.ROLE_EMPHASIS)
		_label(confirm, "회수 없음 · 배치 유지 확인", Vector2(10, 30), Vector2(confirm.size.x - 20, 20), 10, Color("#bdb3c6"))
		var confirm_button := Button.new()
		confirm_button.name = "ConfirmReplacement"
		confirm_button.text = "교체 확정"
		confirm_button.position = Vector2(10, 56)
		confirm_button.size = Vector2(confirm.size.x - 20, 30)
		_style_button(confirm_button, true)
		confirm_button.pressed.connect(_on_confirm_replacement)
		confirm.add_child(confirm_button)
	if not placement_state.get("undo", {}).is_empty():
		var undo_button := Button.new()
		undo_button.name = "UndoPlacement"
		undo_button.text = "방금 배치 되돌리기"
		undo_button.position = Vector2(12, panel.size.y - 46)
		undo_button.size = Vector2(panel.size.x - 24, 34)
		_style_button(undo_button, false)
		undo_button.pressed.connect(_on_undo)
		panel.add_child(undo_button)


func _on_room_clicked(room_id: String) -> void:
	var session: Dictionary = placement_state.get("placement_session", {})
	if str(session.get("kind", "")) == "monster":
		_apply_result(PlacementService.place_selected_monster(placement_state, room_id))
	else:
		_apply_result(PlacementService.select_slot(placement_state, room_id))


func _on_facility_clicked(facility_id: String) -> void:
	_apply_result(PlacementService.choose_facility(placement_state, facility_id, facility_catalog))


func _on_confirm_replacement() -> void:
	_apply_result(PlacementService.confirm_replacement(placement_state, facility_catalog))


func _on_monster_clicked(monster_id: String) -> void:
	_apply_result(PlacementService.select_monster(placement_state, monster_id))


func _on_monster_dropped(monster_id: String, room_id: String) -> void:
	_apply_result(PlacementService.place_monster_drag(placement_state, monster_id, room_id))


func _on_undo() -> void:
	_apply_result(PlacementService.undo(placement_state))


func _apply_result(result: Dictionary) -> void:
	last_result = result.duplicate(true)
	if bool(result.get("ok", false)):
		placement_state = result.get("state", {}).duplicate(true)
		state_changed.emit(placement_state.duplicate(true), last_result.duplicate(true))
	_rebuild()


func _room_button_text(room: Dictionary) -> String:
	var facility_id := str(room.get("facility_id", ""))
	var facility_name := str(facility_catalog.get(facility_id, {}).get("display_name", "빈 시설 슬롯")) if facility_id != "" else "빈 시설 슬롯"
	return "%s\n%s\n배치 %d / %d" % [str(room.get("display_name", "방")), facility_name, room.get("monster_ids", []).size(), int(room.get("capacity", 0))]


func _room_display_name(room_id: String) -> String:
	return str(placement_state.get("rooms", {}).get(room_id, {}).get("display_name", room_id))


func _room_positions(count: int, panel_size: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var points := [Vector2(0.10, 0.18), Vector2(0.10, 0.58), Vector2(0.58, 0.36), Vector2(0.58, 0.70)]
	for index in range(count):
		var point: Vector2 = points[index % points.size()]
		result.append(Vector2(14 + point.x * maxf(1.0, panel_size.x - 230.0), 46 + point.y * maxf(1.0, panel_size.y - 150.0)))
	return result


func _placement_allowed(room: Dictionary, definition: Dictionary) -> bool:
	var room_tags: Array = room.get("placement_tags", [])
	for tag in definition.get("placement_tags", []):
		if room_tags.has(tag):
			return true
	return false


func _panel(node_name: String, rect: Rect2, fill: Color, border: Color) -> Panel:
	var result := _panel_child(self, node_name, rect, fill, border)
	return result


func _panel_child(parent: Control, node_name: String, rect: Rect2, fill: Color, border: Color) -> Panel:
	var result := Panel.new()
	result.name = node_name
	result.position = rect.position
	result.size = rect.size
	result.add_theme_stylebox_override("panel", _style(fill, border, 1))
	parent.add_child(result)
	return result


func _label(parent: Control, text_value: String, position: Vector2, label_size: Vector2, font_size: int, color: Color, role: String = UIFontScript.ROLE_BODY, wrap: int = TextServer.AUTOWRAP_OFF) -> Label:
	var result := Label.new()
	result.text = text_value
	result.position = position
	result.size = label_size
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.autowrap_mode = wrap
	result.add_theme_font_override("font", UIFontScript.font_for_role(role))
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


func _style_button(button: Button, selected: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BUTTON))
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("#ffe4a0") if selected else Color("#f3eadc"))
	button.add_theme_stylebox_override("normal", _style(Color("#2c2138") if selected else Color("#17131f"), Color("#e8bb58") if selected else Color("#5f536a"), 2 if selected else 1))
	button.add_theme_stylebox_override("hover", _style(Color("#382947"), Color("#ffe4a0"), 2))
	button.add_theme_stylebox_override("pressed", _style(Color("#4b3323"), Color("#ffe4a0"), 2))


func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(width)
	result.set_corner_radius_all(6)
	return result
