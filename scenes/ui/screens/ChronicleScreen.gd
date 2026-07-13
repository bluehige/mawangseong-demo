extends Control
class_name ChronicleScreen

signal canceled

const ChronicleServiceScript = preload("res://scripts/systems/chronicle/ChronicleService.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const FRONT_ART_SHEET := preload("res://assets/ui/fronts/front_chronicle_sheet.png")
const BREAKPOINT_WIDTH := 1600.0
const TAB_NAMES := ["전선·심장", "라이벌·합동 기억", "회차·후일담"]

var view_model: Dictionary = {}
var active_tab := 0
var content_root: Control
var _rebuild_queued := false
var _physical_width_override := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_queue_rebuild)
	get_viewport().size_changed.connect(_queue_rebuild)
	_queue_rebuild()


func setup(profile: Dictionary, catalogs: Dictionary, goals: Dictionary) -> void:
	view_model = ChronicleServiceScript.build_view_model(profile, catalogs, goals)
	if is_node_ready():
		_queue_rebuild()


func set_physical_width_override_for_tests(width: float) -> void:
	_physical_width_override = maxf(0.0, width)


func layout_mode_for_viewport(viewport_size: Vector2) -> String:
	return "three_columns" if viewport_size.x >= BREAKPOINT_WIDTH else "tabs"


func layout_contract(viewport_size: Vector2) -> Dictionary:
	return _layout_contract_for_mode(viewport_size, layout_mode_for_viewport(viewport_size))


func _layout_contract_for_mode(viewport_size: Vector2, mode: String) -> Dictionary:
	var margin := 54.0 if viewport_size.x >= BREAKPOINT_WIDTH else 28.0
	if mode == "tabs":
		margin = 40.0 if viewport_size.x >= BREAKPOINT_WIDTH else 28.0
	var top := 170.0 if mode == "three_columns" else 168.0
	var bottom := viewport_size.y - 82.0
	if mode == "three_columns":
		var gap := 24.0
		var width := (viewport_size.x - margin * 2.0 - gap * 2.0) / 3.0
		return {
			"column_0": Rect2(margin, top, width, bottom - top),
			"column_1": Rect2(margin + width + gap, top, width, bottom - top),
			"column_2": Rect2(margin + (width + gap) * 2.0, top, width, bottom - top)
		}
	var tab_gap := 10.0
	var tab_width := (viewport_size.x - margin * 2.0 - tab_gap * 2.0) / 3.0
	return {
		"tab_0": Rect2(margin, 112, tab_width, 44),
		"tab_1": Rect2(margin + tab_width + tab_gap, 112, tab_width, 44),
		"tab_2": Rect2(margin + (tab_width + tab_gap) * 2.0, 112, tab_width, 44),
		"content": Rect2(margin, top, viewport_size.x - margin * 2.0, bottom - top)
	}


func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_build")


func _build() -> void:
	_rebuild_queued = false
	if size.x < 10.0 or size.y < 10.0:
		return
	if content_root != null and is_instance_valid(content_root):
		content_root.queue_free()
	content_root = Control.new()
	content_root.name = "ChronicleCanvas"
	content_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content_root)
	var backdrop := TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = load("res://assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(backdrop)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("#07040cf2")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(shade)
	var map_art := TextureRect.new()
	map_art.name = "ChronicleThreeFrontMap"
	map_art.position = Vector2(maxf(620.0, size.x - 520.0), 4)
	map_art.size = Vector2(310, 150)
	map_art.texture = _sheet_cell(FRONT_ART_SHEET, Vector2i(3, 0), Vector2i(4, 3))
	map_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_art.material = _chroma_material()
	map_art.modulate.a = 0.62
	map_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(map_art)
	_add_label(content_root, "전선 연대기", Rect2(54, 20, size.x - 108, 48), 32 if size.x < BREAKPOINT_WIDTH else 40, Color("#fff3d2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	_add_label(content_root, "전투 능력치를 올리지 않는 장기 기록 · 숙련, 관계, 기억과 후일담을 한곳에서 확인합니다.", Rect2(54, 64, size.x - 108, 28), 14 if size.x < BREAKPOINT_WIDTH else 17, Color("#c9bfd2"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_BODY)
	if bool(view_model.get("final_nameplate_unlocked", false)):
		var nameplate := _add_label(content_root, "세 전선의 대휴전 조율자", Rect2(size.x - 474, 22, 420, 42), 18 if size.x < BREAKPOINT_WIDTH else 21, Color("#ffe4a0"), HORIZONTAL_ALIGNMENT_RIGHT, UIFontScript.ROLE_EMPHASIS)
		nameplate.name = "ChronicleFinalNameplate"
		nameplate.tooltip_text = "E16 · 세 전선 대휴전 엔딩을 완수한 기록 명패"
	var window_size := Vector2(DisplayServer.window_get_size())
	if _physical_width_override > 0.0:
		window_size.x = _physical_width_override
	var mode_probe := Vector2(minf(size.x, window_size.x), minf(size.y, window_size.y))
	var mode := layout_mode_for_viewport(mode_probe)
	var rects := _layout_contract_for_mode(size, mode)
	if mode == "three_columns":
		_build_page_panel(rects["column_0"], 0)
		_build_page_panel(rects["column_1"], 1)
		_build_page_panel(rects["column_2"], 2)
	else:
		for index in range(3):
			var button := _add_button(content_root, TAB_NAMES[index], rects["tab_%d" % index], Callable(self, "_select_tab").bind(index))
			button.name = "ChronicleTab%d" % index
			if index == active_tab:
				button.add_theme_stylebox_override("normal", _style(Color("#3a244bee"), Color("#ffd36a"), 2, 8))
		_build_page_panel(rects["content"], active_tab)
	var close := _add_button(content_root, "돌아가기", Rect2(size.x - 214, size.y - 64, 160, 44), Callable(self, "_cancel"))
	close.name = "ChronicleCloseButton"


func _build_page_panel(rect: Rect2, page_index: int) -> void:
	var panel := Panel.new()
	panel.name = "ChroniclePage%d" % page_index
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _style(Color("#120d19ef"), Color("#6e5630"), 2, 10))
	content_root.add_child(panel)
	_add_label(panel, TAB_NAMES[page_index], Rect2(20, 10, rect.size.x - 40, 34), 21, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, UIFontScript.ROLE_EMPHASIS)
	var body := _page_text(page_index)
	var scroll := ScrollContainer.new()
	scroll.name = "ChronicleScroll%d" % page_index
	scroll.position = Vector2(16, 52)
	scroll.size = Vector2(rect.size.x - 32, rect.size.y - 68)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var label := Label.new()
	label.name = "ChroniclePageText%d" % page_index
	label.custom_minimum_size = Vector2(maxf(240.0, scroll.size.x - 18), 0)
	label.text = body
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_BODY))
	label.add_theme_font_size_override("font_size", 15 if size.x < BREAKPOINT_WIDTH else 16)
	label.add_theme_color_override("font_color", Color("#e9e0ed"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(label)


func _sheet_cell(sheet: Texture2D, cell: Vector2i, grid: Vector2i) -> AtlasTexture:
	var cell_size := Vector2(sheet.get_width() / float(grid.x), sheet.get_height() / float(grid.y))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(cell) * cell_size, cell_size)
	return atlas


func _chroma_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float m=min(c.r,c.b)-c.g; float balance=1.0-smoothstep(0.10,0.32,abs(c.r-c.b)); float k=smoothstep(0.10,0.34,m)*balance; c.a*=1.0-k; COLOR=c; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _page_text(page_index: int) -> String:
	match page_index:
		0:
			return _front_heart_text()
		1:
			return _rival_link_text()
		_:
			return _run_epilogue_text()


func _front_heart_text() -> String:
	var lines: Array[String] = ["[전선 숙련]"]
	for entry_value in view_model.get("fronts", []):
		var entry: Dictionary = entry_value
		var state := "%d%% · 클리어 %d회" % [int(entry.get("mastery", 0)), int(entry.get("clear_count", 0))] if bool(entry.get("unlocked", false)) else "잠김 · %s" % str(entry.get("lock_hint", ""))
		lines.append("• %s\n  %s" % [str(entry.get("name", "")), state])
	lines.append("\n[심장 숙련]")
	for entry_value in view_model.get("hearts", []):
		var entry: Dictionary = entry_value
		var state := "%d%%" % int(entry.get("mastery", 0)) if bool(entry.get("unlocked", false)) else "잠김 · %s" % str(entry.get("lock_hint", ""))
		lines.append("• %s\n  %s" % [str(entry.get("name", "")), state])
	lines.append("\n숙련 보상은 문패·기록 카드 같은 꾸미기와 이야기뿐이며, 공격력·체력 같은 전투 수치는 오르지 않습니다.")
	return "\n\n".join(lines)


func _rival_link_text() -> String:
	var lines: Array[String] = ["[라이벌 관계]"]
	for entry_value in view_model.get("rivals", []):
		var entry: Dictionary = entry_value
		lines.append("• %s  %d/100\n  %s" % [str(entry.get("name", "")), int(entry.get("relation", 0)), str(entry.get("lock_hint", ""))])
	lines.append("\n[합동 기억]")
	for entry_value in view_model.get("links", []):
		var entry: Dictionary = entry_value
		lines.append("• %s\n  %s" % [str(entry.get("name", "")), "기억 확인·합동기 해금" if bool(entry.get("unlocked", false)) else "잠김 · %s" % str(entry.get("lock_hint", ""))])
	return "\n\n".join(lines)


func _run_epilogue_text() -> String:
	var lines: Array[String] = ["[최근 5회차]"]
	var recent: Array = view_model.get("recent_runs", [])
	if recent.is_empty():
		lines.append("• 아직 완료한 회차가 없습니다.")
	else:
		for index in range(recent.size() - 1, -1, -1):
			var entry: Dictionary = recent[index]
			lines.append("• %d회차 · %s\n  %s %s" % [int(entry.get("cycle_index", 0)), str(entry.get("front_name", entry.get("front_id", ""))), str(entry.get("ending_code", "")), str(entry.get("ending_title", entry.get("ending_id", "")))])
	lines.append("\n[후일담 카드]")
	for entry_value in view_model.get("epilogues", []):
		var entry: Dictionary = entry_value
		if bool(entry.get("unlocked", false)):
			lines.append("• %s\n  %s" % [str(entry.get("title", "")), str(entry.get("text", ""))])
		else:
			lines.append("• ???\n  잠김 · %s" % str(entry.get("lock_hint", "")))
	return "\n\n".join(lines)


func _select_tab(index: int) -> void:
	active_tab = clampi(index, 0, 2)
	_queue_rebuild()


func _cancel() -> void:
	canceled.emit()


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
	parent.add_child(label)
	return label


func _add_button(parent: Control, text_value: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text_value
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("#fff2cf"))
	button.add_theme_stylebox_override("normal", _style(Color("#251730f4"), Color("#9b6a27"), 2, 8))
	button.add_theme_stylebox_override("hover", _style(Color("#3a2348f8"), Color("#ffd36a"), 2, 8))
	button.add_theme_stylebox_override("pressed", _style(Color("#150d1df8"), Color("#fff0b0"), 2, 8))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


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
