extends Control
class_name ChronicleScreen

signal canceled
signal settings_requested
signal ending_requested
signal companion_requested(id: String, codex: bool)

const ChronicleServiceScript = preload("res://scripts/systems/chronicle/ChronicleService.gd")
const CouncilChronicleScript = preload("res://scripts/systems/chronicle/CouncilChronicleService.gd")
const UXTheme = preload("res://scripts/ui/UIUXTheme.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const FRONT_ART_SHEET := preload("res://assets/ui/fronts/front_chronicle_sheet.png")
const BREAKPOINT_WIDTH := 1600.0
const TAB_NAMES := ["전선·심장", "라이벌·합동 기억", "회차·후일담", "엔딩"]
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const Surface = preload("res://scripts/ui/kit/KitSurface.gd")
var companions: Array = []
var selected_companion := ""

var view_model: Dictionary = {}
var update4_catalogs: Dictionary = {}
var active_tab := 0
var section_by_tab: Dictionary = {}
var scroll_by_tab: Dictionary = {}
var focus_after_build := ""
var content_root: Control
var _rebuild_queued := false
var _physical_width_override := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_queue_rebuild)
	get_viewport().size_changed.connect(_queue_rebuild)
	_queue_rebuild()


func setup(profile: Dictionary, catalogs: Dictionary, goals: Dictionary, council_profile: Dictionary = {}, council_catalogs: Dictionary = {}) -> void:
	view_model = ChronicleServiceScript.build_view_model(profile, catalogs, goals)
	update4_catalogs = council_catalogs.duplicate(true)
	view_model["update4"] = CouncilChronicleScript.build_view_model(council_profile, council_catalogs)
	if is_node_ready():
		_queue_rebuild()


func set_physical_width_override_for_tests(width: float) -> void:
	_physical_width_override = maxf(0.0, width)


func layout_mode_for_viewport(_viewport_size: Vector2) -> String:
	return "tabs"

func layout_contract(viewport_size: Vector2) -> Dictionary:
	return _layout_contract_for_mode(viewport_size,"tabs")

func _layout_contract_for_mode(viewport_size: Vector2,_mode: String) -> Dictionary:
	var margin:=54.0 if viewport_size.x>=BREAKPOINT_WIDTH else 28.0
	var gap:=14.0
	var width:=(viewport_size.x-margin*2-gap*3)/4
	var rects: Dictionary={"content":Rect2(margin,220,viewport_size.x-margin*2,viewport_size.y-312)}
	for index in range(4): rects["tab_%d"%index]=Rect2(margin+(width+gap)*index,132,width,62)
	return rects

func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_build")


func _build() -> void:
	_rebuild_queued = false
	if size.x < 10 or size.y < 10: return
	if is_instance_valid(content_root):
		remove_child(content_root); content_root.queue_free()
	content_root = Control.new()
	content_root.name = "ChronicleCanvas"
	content_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.theme = Kit.scaled_theme(UISettings.text_scale,UISettings.is_touch_ui())
	add_child(content_root)
	var backdrop := TextureRect.new()
	backdrop.name = "RecordsCastleBackground"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = load("res://assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(backdrop)
	var banner := _glass_panel(content_root,Rect2(54,16,size.x-108,98),"RecordsTitleBanner")
	_add_label(banner,_loc("기록실 · 연대기","Records · Chronicle","记录室 · 编年史"),Rect2(20,4,banner.size.x-40,76),48,UXTheme.GOLD,HORIZONTAL_ALIGNMENT_CENTER,UIFontScript.ROLE_EMPHASIS)
	var rects := layout_contract(size)
	for index in 4:
		var caption := LanguageSettings.ui_text(TAB_NAMES[index])
		if index == 3: caption = _loc("엔딩","Endings","结局")
		var button := _add_button(content_root,caption,rects["tab_%d"%index],_open_record_tab.bind(index))
		button.name = "ChronicleTab%d"%index
		if index == active_tab:
			button.theme_type_variation = "KitPrimary"
			button.set_meta("kit_selected",true); button.surface.sync(button)
	_build_page_panel(rects.content,mini(active_tab,2))
	# The old accessibility page is now only a shortcut into the single settings editor.
	_build_accessibility_controls(content_root,size.x)
	var choice := OptionButton.new()
	choice.name = "RecordCompanionOption"
	choice.position = Vector2(330,size.y-72); choice.size = Vector2(260,56)
	choice.tooltip_text = _loc("동료 기록 선택","Choose companion records","选择伙伴记录")
	content_root.add_child(choice)
	choice.add_theme_font_size_override("font_size",24)
	for id in companions:
		choice.add_item(LanguageSettings.ui_text(str(DataRegistry.monster(id).get("display_name",id))))
		choice.set_item_metadata(choice.item_count-1,id)
		if id == selected_companion: choice.select(choice.item_count-1)
	choice.item_selected.connect(func(index: int): selected_companion = str(choice.get_item_metadata(index)))
	if selected_companion == "" and not companions.is_empty(): selected_companion = str(companions[0])
	var memory := _add_button(content_root,_loc("동료 기억","Memories","伙伴记忆"),Rect2(614,size.y-72,230,56),func(): companion_requested.emit(selected_companion,false))
	memory.name = "RecordsMemoryButton"; memory.disabled = companions.is_empty()
	var codex := _add_button(content_root,_loc("동료 도감","Companions","伙伴图鉴"),Rect2(866,size.y-72,250,56),func(): companion_requested.emit(selected_companion,true))
	codex.name = "RecordsCompanionButton"
	var close := _add_button(content_root,_loc("돌아가기","Back","返回"),Rect2(size.x-274,size.y-72,220,56),_cancel)
	close.name = "ChronicleCloseButton"
	if focus_after_build != "":
		var focused := content_root.find_child(focus_after_build,true,false) as Control
		if focused != null: focused.grab_focus()
		focus_after_build = ""

func _loc(ko: String, en: String, zh: String) -> String:
	return en if LanguageSettings.locale == "en" else (zh if LanguageSettings.locale == "zh_CN" else ko)

func _open_record_tab(index: int) -> void:
	if index == 3: ending_requested.emit()
	else: _select_tab(index)

func _glass_panel(parent: Control, rect: Rect2, id: String) -> Panel:
	var pane := Panel.new()
	pane.theme = content_root.theme
	pane.name = id; pane.position = rect.position; pane.size = rect.size
	pane.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	parent.add_child(pane)
	var surface := Surface.new()
	pane.add_child(surface); surface.sync(pane)
	surface._material.set_shader_parameter("top_color",Color(0.16,0.10,0.23,0.82))
	surface._material.set_shader_parameter("bottom_color",Color(0.05,0.03,0.09,0.82))
	return pane

func _build_page_panel(rect: Rect2,page_index: int) -> void:
	var panel:=_glass_panel(content_root,rect,"ChroniclePage%d"%page_index)
	panel.name="ChroniclePage%d"%page_index
	panel.position=rect.position
	panel.size=rect.size
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE

	var sections:=_sections(page_index)
	var selected:=clampi(int(section_by_tab.get(page_index,0)),0,maxi(0,sections.size()-1))
	section_by_tab[page_index]=selected
	var nav:=ScrollContainer.new()
	nav.name="ChronicleSectionList"
	nav.position=Vector2(22,24)
	nav.size=Vector2(354,rect.size.y-48)
	nav.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	nav.follow_focus=true
	panel.add_child(nav)
	var list:=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",12)
	nav.add_child(list)
	for index in sections.size():
		var b:=_add_button(list,str(sections[index].title),Rect2(0,0,330,94),Callable(self,"_select_section").bind(index))
		b.name="ChronicleSection%d"%index
		b.custom_minimum_size=Vector2(330,94)
		b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		if index==selected:
			b.theme_type_variation="KitPrimary"
			b.set_meta("kit_selected",true); b.surface.sync(b)
	var detail_x:=410.0
	_add_label(panel,str(sections[selected].title),Rect2(detail_x,26,rect.size.x-detail_x-34,64),32,UXTheme.GOLD,HORIZONTAL_ALIGNMENT_LEFT,UIFontScript.ROLE_EMPHASIS)
	var scroll:=ScrollContainer.new()
	scroll.name="ChronicleScroll%d"%page_index
	scroll.position=Vector2(detail_x,118)
	scroll.size=Vector2(rect.size.x-detail_x-40,rect.size.y-144)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode=Control.FOCUS_ALL
	panel.add_child(scroll)
	scroll.set_deferred("scroll_vertical",int(scroll_by_tab.get("%d:%d"%[page_index,selected],0)))
	var label:=Label.new()
	label.name="ChroniclePageText%d"%page_index
	label.custom_minimum_size.x=maxf(320,scroll.size.x-24)
	label.text=LanguageSettings.ui_text(str(sections[selected].body))
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",UIFontScript.font_for_role(UIFontScript.ROLE_BODY))
	label.add_theme_font_size_override("font_size",UISettings.scaled_font_size(25))
	label.add_theme_color_override("font_color",UXTheme.PAPER)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scroll.add_child(label)

func _sections(page_index: int) -> Array:
	var result: Array=[]
	var current: Dictionary={}
	for line in _page_text(page_index).split("\n"):
		var clean:=line.strip_edges()
		if clean.begins_with("[") and clean.ends_with("]"):
			if not current.is_empty(): result.append(current)
			current={"title":clean.trim_prefix("[").trim_suffix("]"),"body":""}
		elif not current.is_empty(): current.body+=line+"\n"
	if not current.is_empty(): result.append(current)
	if result.is_empty(): result.append({"title":TAB_NAMES[page_index],"body":"아직 기록이 없습니다."})
	for section in result: section.body=str(section.body).strip_edges()
	return result

func _select_section(index: int) -> void:
	remember_scroll()
	section_by_tab[active_tab]=index
	focus_after_build="ChronicleSection%d"%index
	_queue_rebuild()

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
	lines.append("\n[의회 지역 숙련 · 0~3등급]")
	for entry_value in view_model.get("update4", {}).get("regions", []):
		var entry: Dictionary = entry_value
		lines.append("• %s  Lv.%d\n  %s" % [str(entry.get("name", "")), int(entry.get("mastery_level", 0)), str(entry.get("benefit_text", ""))])
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
	lines.append("\n[경쟁 마왕 서신 · 각 5개]")
	for entry_value in view_model.get("update4", {}).get("rival_letters", []):
		var entry: Dictionary = entry_value
		if not bool(entry.get("unlocked",false)): continue
		lines.append("• %s · %s\n  %s" % [str(entry.get("rival_name", "")), str(entry.get("subject", "???")) if bool(entry.get("unlocked", false)) else "???", str(entry.get("body", "")) if bool(entry.get("unlocked", false)) else "잠김 · %s" % str(entry.get("lock_hint", ""))])
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
	lines.append("\n[최근 5회 의회 회차 비교]")
	var council_recent: Array = view_model.get("update4", {}).get("recent_runs", [])
	if council_recent.is_empty():
		lines.append("• 아직 완료한 의회 회차가 없습니다.")
	else:
		for index in range(council_recent.size() - 1, -1, -1):
			var entry: Dictionary = council_recent[index]
			var day30: Dictionary = entry.get("day30", {})
			lines.append("• %d회차 · %s %s\n  지역 %s · 전초 %s/%s · 상층 %s\n  대표 %s · 관계 %s\n  왕관 %s · 인장 %d · 표 %d · 독립 %d\n  DAY30 %.1f초 · 생존 1F %d/2F %d · 층 피해 %s" % [
				int(entry.get("cycle_index", 0)), str(entry.get("ending_code", "")), str(entry.get("ending_title", entry.get("ending_id", ""))),
				_region_names(entry.get("region_order", [])), _catalog_name("outpost_types",str(entry.get("outpost_type_id", ""))), "생존" if bool(entry.get("outpost_survived", false)) else "파괴", _catalog_name("upper_floor_layouts",str(entry.get("upper_layout_id", ""))),
				_catalog_name("rival_lords",str(entry.get("representative_id", ""))), _relation_text(entry.get("rival_relations", {})), _catalog_name("crown_evolutions",str(entry.get("crown_form_id", ""))), int(entry.get("council_seals", 0)), int(entry.get("council_votes", 0)), int(entry.get("independence", 0)),
				float(day30.get("time_seconds", 0.0)), int(day30.get("lower_survivors", 0)), int(day30.get("upper_survivors", 0)), _floor_damage_text(day30.get("damage_by_floor", {}))
			])
	lines.append("\n[왕관 진화 도감]")
	for entry_value in view_model.get("update4", {}).get("crowns", []):
		var entry: Dictionary = entry_value
		lines.append("• %s\n  %s" % [str(entry.get("name", "???")) if bool(entry.get("seen", false)) else "???", "%s · 약점: %s" % [str(entry.get("role", "")), str(entry.get("weakness", ""))] if bool(entry.get("seen", false)) else "잠김 · %s" % str(entry.get("lock_hint", ""))])
	lines.append("\n[후일담 카드]")
	for entry_value in view_model.get("epilogues", []):
		var entry: Dictionary = entry_value
		if bool(entry.get("unlocked", false)):
			lines.append("• %s\n  %s" % [str(entry.get("title", "")), str(entry.get("text", ""))])
	return "\n\n".join(lines)


func _build_accessibility_controls(panel: Control, _panel_width: float) -> void:
	var button := _add_button(panel,_loc("조작·접근성 설정","Accessibility","操作·辅助设置"),Rect2(54,size.y-72,250,56),func(): settings_requested.emit())
	button.name = "ChronicleSettingsShortcut"


func _select_tab(index: int) -> void:
	remember_scroll()
	active_tab = clampi(index, 0, 3)
	focus_after_build="ChronicleTab%d"%active_tab
	_queue_rebuild()

func remember_scroll() -> void:
	if not is_instance_valid(content_root): return
	var scroll := content_root.find_child("ChronicleScroll%d"%active_tab,true,false) as ScrollContainer
	if scroll!=null: scroll_by_tab["%d:%d"%[active_tab,int(section_by_tab.get(active_tab,0))]]=scroll.scroll_vertical


func _cancel() -> void:
	canceled.emit()


func _add_label(parent: Control, text_value: String, rect: Rect2, font_size: int, color: Color, alignment: HorizontalAlignment, role: String) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = LanguageSettings.ui_text(text_value)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UIFontScript.font_for_role(role))
	label.add_theme_font_size_override("font_size", UISettings.scaled_font_size(maxi(20, font_size)))
	label.add_theme_color_override("font_color", color)
	label.tooltip_text = label.text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _add_button(parent: Control, text_value: String, rect: Rect2, callback: Callable) -> Button:
	var button: Button = load("res://scripts/ui/kit/KitButton.gd").new()
	button.configure(LanguageSettings.ui_text(text_value),0,"",LanguageSettings.ui_text(text_value))
	button.position = rect.position; button.size = rect.size
	parent.add_child(button)
	Kit.inherit_theme(button,content_root.theme)
	button.custom_minimum_size = rect.size
	button.add_theme_font_size_override("font_size",24)
	button.pressed.connect(callback)
	return button

func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBox:
	return UXTheme.panel(fill, border, width, radius)

func _catalog_name(catalog: String,id: String) -> String:
	if id=="" or id=="없음": return "없음"
	return str(update4_catalogs.get(catalog,{}).get(id,{}).get("display_name","기록된 항목"))

func _region_names(ids: Array) -> String:
	var names: Array[String]=[]
	for id in ids: names.append(_catalog_name("regions",str(id)))
	return " → ".join(names) if not names.is_empty() else "기록 없음"

func _relation_text(relations: Dictionary) -> String:
	var parts: Array[String]=[]
	for id in relations: parts.append("%s %d"%[_catalog_name("rival_lords",str(id)),int(relations[id])])
	return " · ".join(parts) if not parts.is_empty() else "기록 없음"

func _floor_damage_text(damage: Dictionary) -> String:
	var parts: Array[String]=[]
	for floor_id in ["1F","2F"]:
		if damage.has(floor_id): parts.append("%s %.0f"%["1층" if floor_id=="1F" else "2층",float(damage[floor_id])])
	return " · ".join(parts) if not parts.is_empty() else "기록 없음"
