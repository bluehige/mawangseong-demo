extends Control
class_name OutpostManagementScreen

signal outpost_selected(type_id: String)
signal assignment_changed(instance_ids: Array[String])
signal upgrade_requested
signal closed

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const OutpostServiceScript = preload("res://scripts/systems/outpost/OutpostService.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
const TYPE_ORDER := ["outpost_watch_nest", "outpost_supply_burrow", "outpost_false_gate"]
const CARD_RECTS := {
	"outpost_watch_nest": Rect2(132, 226, 520, 420),
	"outpost_supply_burrow": Rect2(700, 226, 520, 420),
	"outpost_false_gate": Rect2(1268, 226, 520, 420)
}

var active_run: Dictionary = {}
var catalog: Dictionary = {}
var owned_instance_ids: Array[String] = []
var instance_catalog: Dictionary = {}
var day := 4
var wave_preview: Array[Dictionary] = []
var content_root: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_fit_design_canvas)
	if content_root == null:
		_build()
	call_deferred("_fit_design_canvas")


func setup(active_run_value: Dictionary, type_catalog: Dictionary, owned_ids: Array, instances: Dictionary, current_day: int, wave_preview_value: Array = []) -> void:
	active_run = active_run_value.duplicate(true)
	catalog = type_catalog.duplicate(true)
	owned_instance_ids.clear()
	for value in owned_ids:
		owned_instance_ids.append(str(value))
	instance_catalog = instances.duplicate(true)
	day = current_day
	wave_preview.clear()
	for value in wave_preview_value:
		if value is Dictionary:
			wave_preview.append(value.duplicate(true))
	if is_node_ready():
		_build()


func layout_rects_for_viewport(viewport_size: Vector2) -> Dictionary:
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * factor) * 0.5
	var result := {}
	for type_id in CARD_RECTS:
		var source: Rect2 = CARD_RECTS[type_id]
		result[type_id] = Rect2(offset + source.position * factor, source.size * factor)
	return result


func _build() -> void:
	if content_root != null and is_instance_valid(content_root):
		content_root.queue_free()
	content_root = Control.new()
	content_root.name = "DesignCanvas"
	content_root.size = DESIGN_SIZE
	add_child(content_root)
	var backdrop := TextureRect.new()
	backdrop.name = "OutpostBackdrop"
	backdrop.size = DESIGN_SIZE
	backdrop.texture = load("res://assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(backdrop)
	var shade := ColorRect.new()
	shade.size = DESIGN_SIZE
	shade.color = Color("#07040cef")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(shade)

	var outpost: Dictionary = active_run.get("outpost", {})
	var built_type := str(outpost.get("type_id", ""))
	_add_label(content_root, "성 밖의 두 번째 책임", Rect2(132, 44, 1100, 62), 42, Color("#fff3d2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root, "DAY %02d · 전초기지 유형은 회차당 하나만 선택할 수 있습니다." % day, Rect2(134, 112, 1120, 36), 20, Color("#d9b86c"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root, "OUTPOST  ·  %s" % (str(catalog.get(built_type, {}).get("display_name", "건설 대기"))), Rect2(1260, 64, 528, 38), 17, Color("#cfa9ee"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root, "세 유형은 패시브·방어전 효과·보상·위험이 모두 다릅니다. DAY 10·20 결과는 엔딩 지표에 기록됩니다.", Rect2(134, 164, 1654, 32), 17, Color("#c9bfd2"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_BODY)

	for type_id in TYPE_ORDER:
		_build_type_card(type_id, built_type, outpost)
	_build_status_panel(outpost, built_type)
	var close_button := _add_button(content_root, "관리 화면으로", Rect2(760, 986, 400, 58), Callable(self, "_close"), false)
	close_button.name = "OutpostCloseButton"
	close_button.disabled = built_type == ""
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_fit_design_canvas()


func _build_type_card(type_id: String, built_type: String, outpost: Dictionary) -> void:
	var definition: Dictionary = catalog.get(type_id, {})
	var accent := Color(str(definition.get("accent", "#c89f53")))
	var selected := type_id == built_type
	var card := Button.new()
	card.name = "OutpostTypeButton_%s" % type_id
	var rect: Rect2 = CARD_RECTS[type_id]
	card.position = rect.position
	card.size = rect.size
	card.text = ""
	card.disabled = built_type != ""
	card.clip_contents = true
	card.add_theme_stylebox_override("normal", _style(Color("#17101ff5"), accent.darkened(0.18), 2, 12))
	card.add_theme_stylebox_override("hover", _style(Color("#2b1b39fa"), accent.lightened(0.2), 4, 12))
	card.add_theme_stylebox_override("pressed", _style(Color("#100a16fa"), Color("#fff0b0"), 4, 12))
	card.add_theme_stylebox_override("disabled", _style(Color("#100d16ef"), accent if selected else Color("#493d50"), 4 if selected else 2, 12))
	card.pressed.connect(_choose_type.bind(type_id))
	content_root.add_child(card)
	var state := "base"
	if selected:
		state = "level2" if int(outpost.get("level", 0)) >= 2 else ("damaged" if bool(outpost.get("damaged", false)) else "base")
	var art := TextureRect.new()
	art.name = "OutpostArt_%s_%s" % [type_id, state]
	art.position = Vector2(2, 2)
	art.size = Vector2(516, 140)
	var art_path := str(definition.get("art_states", {}).get(state, ""))
	if not art_path.is_empty():
		art.texture = load(art_path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = Color(1, 1, 1, 0.72 if built_type == "" or selected else 0.34)
	art.z_index = 0
	card.add_child(art)
	var art_shade := ColorRect.new()
	art_shade.position = art.position
	art_shade.size = art.size
	art_shade.color = Color(0.035, 0.018, 0.05, 0.42)
	art_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_shade.z_index = 1
	card.add_child(art_shade)
	_add_label(card, "건설 완료" if selected else ("선택 가능" if built_type == "" else "다른 유형 건설됨"), Rect2(28, 22, 464, 26), 15, accent if selected or built_type == "" else Color("#81768a"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(card, str(definition.get("display_name", type_id)), Rect2(28, 62, 464, 52), 31, Color("#fff4d8") if built_type == "" or selected else Color("#99919e"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_divider(card, 128)
	_add_row(card, "패시브", str(definition.get("passive_text", "")), 148, accent)
	_add_row(card, "방어전", str(definition.get("battle_text", "")), 208, accent)
	_add_row(card, "대가", str(definition.get("cost_text", "")), 268, Color("#d17e86"))
	_add_row(card, "Lv.2", str(definition.get("level_2_text", "")), 328, Color("#d3b36b"))
	_add_label(card, "깃발 HP  %d → %d" % [int(definition.get("base_hp", 0)), int(definition.get("level_2_hp", 0))], Rect2(28, 382, 464, 24), 14, Color("#bfb3c5"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)


func _build_status_panel(outpost: Dictionary, built_type: String) -> void:
	var panel := Panel.new()
	panel.name = "OutpostStatusPanel"
	panel.position = Vector2(132, 682)
	panel.size = Vector2(1656, 280)
	panel.add_theme_stylebox_override("panel", _style(Color("#100c16f2"), Color("#6e566f"), 2, 12))
	content_root.add_child(panel)
	var level := int(outpost.get("level", 0))
	var next_raid := OutpostServiceScript.next_raid_day(day)
	_add_label(panel, "배치 몬스터  ·  최대 3명", Rect2(28, 20, 460, 32), 20, Color("#fff0cf"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(panel, "HP  %d / %d   ·   Lv.%d   ·   다음 습격  %s" % [int(outpost.get("current_hp", 0)), int(outpost.get("max_hp", 0)), level, ("DAY %d" % next_raid) if next_raid > 0 else "완료"], Rect2(960, 20, 664, 32), 18, Color("#d9cbdc"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_BODY)
	var assigned: Array = outpost.get("assigned_monster_ids", [])
	var stats: Dictionary = outpost.get("stats", {})
	_add_label(panel, "방어 통계  %d전 %d승 · 평균 잔여 HP %.0f%%" % [int(stats.get("battles", 0)), int(stats.get("wins", 0)), float(stats.get("average_ending_hp_ratio", 0.0)) * 100.0], Rect2(960, 52, 664, 28), 15, Color("#b9a8c2"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_BODY)
	if not wave_preview.is_empty():
		var preview_parts: Array[String] = []
		for preview in wave_preview:
			preview_parts.append("%s×%d" % [str(preview.get("enemy_id", "?")), int(preview.get("count", 1))])
		_add_label(panel, "감시 예고 DAY %d · %s" % [int(wave_preview[0].get("day", day)), " / ".join(preview_parts)], Rect2(1030, 84, 594, 26), 14, Color("#8fc2e8"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
	for slot in 3:
		var slot_panel := Panel.new()
		slot_panel.name = "AssignedSlot%d" % (slot + 1)
		slot_panel.position = Vector2(28 + slot * 330, 84)
		slot_panel.size = Vector2(302, 70)
		slot_panel.add_theme_stylebox_override("panel", _style(Color("#1b1323"), Color("#6f5a78"), 1, 8))
		panel.add_child(slot_panel)
		var instance_id := str(assigned[slot]) if slot < assigned.size() else ""
		var name := str(instance_catalog.get(instance_id, {}).get("display_name", "빈 배치 칸"))
		_add_label(slot_panel, "%d  ·  %s" % [slot + 1, name], Rect2(14, 10, 274, 50), 17, Color("#f2e7f4") if instance_id != "" else Color("#8d8292"), HORIZONTAL_ALIGNMENT_CENTER, UIFontScript.ROLE_EMPHASIS)
	_add_label(panel, "보유 몬스터를 눌러 배치/해제", Rect2(28, 158, 370, 26), 15, Color("#a99daf"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	for index in mini(owned_instance_ids.size(), 7):
		var instance_id := owned_instance_ids[index]
		var selected := assigned.has(instance_id)
		var label := ("해제 · " if selected else "배치 · ") + str(instance_catalog.get(instance_id, {}).get("display_name", instance_id))
		var button := _add_button(panel, label, Rect2(28 + index * 188, 194, 176, 50), Callable(self, "_toggle_assignment").bind(instance_id), built_type == "")
		button.name = "OutpostAssignButton_%s" % instance_id
		button.add_theme_font_size_override("font_size", 14)
	var upgrade := _add_button(panel, "Lv.2 강화" if level < 2 else "Lv.2 강화 완료", Rect2(1366, 184, 258, 60), Callable(self, "_upgrade"), built_type == "" or day < OutpostServiceScript.UPGRADE_DAY or level >= 2)
	upgrade.name = "OutpostUpgradeButton"
	upgrade.tooltip_text = "DAY 12부터 강화할 수 있습니다." if day < OutpostServiceScript.UPGRADE_DAY else ""


func _choose_type(type_id: String) -> void:
	outpost_selected.emit(type_id)


func _toggle_assignment(instance_id: String) -> void:
	var assigned: Array[String] = []
	for value in active_run.get("outpost", {}).get("assigned_monster_ids", []):
		assigned.append(str(value))
	if assigned.has(instance_id):
		assigned.erase(instance_id)
	elif assigned.size() < OutpostServiceScript.MAX_ASSIGNED:
		assigned.append(instance_id)
	assignment_changed.emit(assigned)


func _upgrade() -> void:
	upgrade_requested.emit()


func _close() -> void:
	closed.emit()


func _fit_design_canvas() -> void:
	if content_root == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	content_root.scale = Vector2.ONE * factor
	content_root.position = (size - DESIGN_SIZE * factor) * 0.5


func _add_row(parent: Control, title: String, value: String, y: float, accent: Color) -> void:
	_add_label(parent, title, Rect2(28, y, 70, 42), 14, accent, HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(parent, value, Rect2(104, y, 388, 42), 16, Color("#e7deea"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)


func _add_label(parent: Control, text_value: String, rect: Rect2, font_size: int, color: Color, alignment: HorizontalAlignment, role: String) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UIFontScript.font_for_role(role))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 3
	parent.add_child(label)
	return label


func _add_button(parent: Control, text_value: String, rect: Rect2, callback: Callable, disabled: bool) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text_value
	button.disabled = disabled
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("#fff2cf"))
	button.add_theme_stylebox_override("normal", _style(Color("#251730f4"), Color("#9b6a27"), 2, 8))
	button.add_theme_stylebox_override("hover", _style(Color("#3a2348f8"), Color("#ffd36a"), 2, 8))
	button.add_theme_stylebox_override("pressed", _style(Color("#150d1df8"), Color("#fff0b0"), 2, 8))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_divider(parent: Control, y: float) -> void:
	var divider := ColorRect.new()
	divider.position = Vector2(28, y)
	divider.size = Vector2(464, 1)
	divider.color = Color("#5d4c67")
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.z_index = 3
	parent.add_child(divider)


func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
