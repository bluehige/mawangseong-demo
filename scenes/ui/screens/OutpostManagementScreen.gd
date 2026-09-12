extends Control
class_name OutpostManagementScreen
signal outpost_selected(type_id: String)
signal assignment_changed(instance_ids: Array[String])
signal upgrade_requested
signal closed
const UXTheme = preload("res://scripts/ui/UIUXTheme.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const OutpostServiceScript = preload("res://scripts/systems/outpost/OutpostService.gd")
const DESIGN_SIZE := Vector2(1920,1080)
const TYPE_ORDER := ["outpost_watch_nest","outpost_supply_burrow","outpost_false_gate"]
const CARD_RECTS := {
	"outpost_watch_nest":Rect2(32,194,400,224),
	"outpost_supply_burrow":Rect2(32,438,400,224),
	"outpost_false_gate":Rect2(32,682,400,224)
}
var active_run: Dictionary = {}
var catalog: Dictionary = {}
var owned_instance_ids: Array[String] = []
var instance_catalog: Dictionary = {}
var portraits: Dictionary = {}
var day := 4
var wave_preview: Array[Dictionary] = []
var content_root: Control
var selected_type := ""
var detail: Panel
var action: Button
var notice: Label
var focus_instance_id := ""
var issued := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_fit_design_canvas)
	if content_root == null:
		_build()
	call_deferred("_fit_design_canvas")

func setup(run: Dictionary, types: Dictionary, owned: Array, instances: Dictionary, current_day: int, preview: Array = [], portrait_paths: Dictionary = {}, focus_id: String = "") -> void:
	active_run = run.duplicate(true)
	catalog = types.duplicate(true)
	owned_instance_ids.assign(owned)
	instance_catalog = instances.duplicate(true)
	portraits = portrait_paths.duplicate()
	focus_instance_id = focus_id
	day = current_day
	wave_preview.clear()
	for value in preview:
		if value is Dictionary:
			wave_preview.append(value.duplicate(true))
	selected_type = str(active_run.get("outpost",{}).get("type_id",""))
	if selected_type == "" and not catalog.is_empty():
		selected_type = str(TYPE_ORDER[0])
	issued = false
	if is_node_ready():
		_build()

func layout_rects_for_viewport(viewport_size: Vector2) -> Dictionary:
	var factor := minf(viewport_size.x / DESIGN_SIZE.x,viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size-DESIGN_SIZE*factor)*0.5
	var result := {}
	for id in CARD_RECTS:
		var rect: Rect2 = CARD_RECTS[id]
		result[id] = Rect2(offset+rect.position*factor,rect.size*factor)
	return result

func _panel(rect: Rect2, id: String) -> Panel:
	var p := Panel.new()
	p.name = id
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_theme_stylebox_override("panel",UXTheme.panel(UXTheme.INK,UXTheme.LINE))
	content_root.add_child(p)
	return p

func _build() -> void:
	if is_instance_valid(content_root):
		remove_child(content_root)
		content_root.queue_free()
	content_root = Control.new()
	content_root.name = "DesignCanvas"
	content_root.size = DESIGN_SIZE
	content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content_root)
	var bg := ColorRect.new()
	bg.size = DESIGN_SIZE
	bg.color = Color("#100c16")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(bg)
	var outpost: Dictionary = active_run.get("outpost",{})
	var built_type := str(outpost.get("type_id",""))
	_label(content_root,"전초기지",Rect2(32,30,1200,64),40,UXTheme.GOLD)
	_label(content_root,"DAY %02d · 유형별 효과를 살펴보고 수비대를 배치하세요." % day,Rect2(34,110,1836,54),24,UXTheme.MUTED)
	for id in TYPE_ORDER:
		var d: Dictionary = catalog.get(id,{})
		var b := _button(content_root,"",CARD_RECTS[id],_choose_type.bind(id),"OutpostTypeButton_"+id)
		var rect: Rect2 = CARD_RECTS[id]
		_art(b,str(d.get("art_states",{}).get("base","")),Rect2(16,8,368,120),"OutpostArt_"+id+"_base")
		_label(b,str(d.get("display_name",id)),Rect2(20,134,360,44),26,UXTheme.PAPER)
		_label(b,"건설된 유형" if id == built_type else "선택하여 효과 비교",Rect2(20,178,360,34),20,UXTheme.MUTED)
	detail = _panel(Rect2(456,194,884,712),"OutpostDetailPanel")
	var roster := _panel(Rect2(1364,194,524,712),"OutpostStatusPanel")
	var assigned: Array = outpost.get("assigned_monster_ids",[])
	_label(roster,"수비대 %d / %d명" % [assigned.size(),OutpostServiceScript.MAX_ASSIGNED],Rect2(24,16,476,48),28,UXTheme.GOLD)
	_label(roster,"배치·해제는 즉시 반영됩니다." if built_type != "" else "유형을 건설하면 배치할 수 있습니다.",Rect2(24,76,476,58),22,UXTheme.MUTED)
	var members := _scroll(roster,Rect2(18,150,488,540),"OutpostRosterScroll")
	for id in owned_instance_ids:
		var selected := assigned.has(id)
		var full := assigned.size() >= OutpostServiceScript.MAX_ASSIGNED
		var b := _button(members,"",Rect2(0,0,458,134),_toggle_assignment.bind(id),"OutpostAssignButton_"+id)
		b.custom_minimum_size = Vector2(458,134)
		b.disabled = built_type == "" or (full and not selected)
		b.tooltip_text = "3명이 배치되어 있습니다. 다른 동료를 해제하세요." if full and not selected else ""
		if selected:
			b.add_theme_stylebox_override("normal",UXTheme.panel(Color("#2b2140"),UXTheme.GOLD,2))
		var instance: Dictionary = instance_catalog.get(id,{})
		_art(b,portraits.get(id,""),Rect2(8,8,104,118),"OutpostPortrait_"+id)
		_label(b,str(instance.get("display_name",id)),Rect2(126,12,310,56),24,UXTheme.PAPER)
		_label(b,"배치됨 · 눌러 해제" if selected else ("정원 가득 참" if full else "미배치 · 눌러 배치"),Rect2(126,80,310,42),20,UXTheme.GOLD if selected else UXTheme.MUTED)
		if id == focus_instance_id and not b.disabled:
			b.call_deferred("grab_focus")
	if owned_instance_ids.is_empty():
		_paragraph(members,"보유한 동료가 없습니다.",452,24,UXTheme.MUTED)
	var close_button := _button(content_root,"관리 화면으로 · ESC",Rect2(32,976,360,64),_close,"OutpostCloseButton")
	close_button.disabled = built_type == ""
	notice = _label(content_root,"",Rect2(422,956,982,98),22,UXTheme.MUTED)
	action = _button(content_root,"",Rect2(1440,976,448,64),_commit,"OutpostUpgradeButton" if built_type != "" else "OutpostBuildButton")
	_build_detail()
	_fit_design_canvas()

func _build_detail() -> void:
	for child in detail.get_children():
		detail.remove_child(child)
		child.queue_free()
	var content := _scroll(detail,Rect2(26,20,832,672),"OutpostDetailScroll")
	var d: Dictionary = catalog.get(selected_type,{})
	var outpost: Dictionary = active_run.get("outpost",{})
	var built_type := str(outpost.get("type_id",""))
	var selected := selected_type == built_type
	var level := int(outpost.get("level",0))
	for id in TYPE_ORDER:
		var b := content_root.find_child("OutpostTypeButton_"+id,true,false) as Button
		b.add_theme_stylebox_override("normal",UXTheme.panel(Color("#2b2140") if id == selected_type else UXTheme.INK,UXTheme.GOLD if id == selected_type else UXTheme.LINE,2 if id == selected_type else 1))
	if d.is_empty():
		_paragraph(content,"목록에서 전초기지 유형을 선택하세요.",800,26,UXTheme.MUTED)
		action.disabled = true
		return
	_paragraph(content,str(d.get("display_name",selected_type)),800,34,UXTheme.GOLD)
	var state := "level2" if selected and level >= 2 else ("damaged" if selected and bool(outpost.get("damaged",false)) else "base")
	var art := _art(content,str(d.get("art_states",{}).get(state,"")),Rect2(0,0,800,230),"OutpostSelectedArt")
	art.custom_minimum_size = Vector2(800,230)
	for field in [["상시 효과","passive_text"],["방어전 효과","battle_text"],["유형의 대가","cost_text"],["Lv.2 변화","level_2_text"]]:
		_paragraph(content,str(field[0]),800,22,UXTheme.MUTED)
		_paragraph(content,str(d.get(field[1],"")).replace("raid threat","습격 위협"),800,24,UXTheme.PAPER)
	_paragraph(content,("강화 후 최대 HP %d → %d" % [outpost.get("max_hp",0),maxi(int(outpost.get("max_hp",0)),int(d.get("level_2_hp",0)))]) if selected else ("유형 기본 HP %d · Lv.2 %d" % [d.get("base_hp",0),d.get("level_2_hp",0)]),800,26,UXTheme.GOLD)
	if selected:
		_paragraph(content,"DAY 10·20 방어 결과는 엔딩 지표에 기록됩니다.",800,22,UXTheme.MUTED)
		var stats: Dictionary = outpost.get("stats",{})
		var next := OutpostServiceScript.next_raid_day(day)
		_paragraph(content,"방어 통계 %d전 %d승 · 평균 잔여 HP %.0f%%" % [stats.get("battles",0),stats.get("wins",0),float(stats.get("average_ending_hp_ratio",0.0))*100],800,22,UXTheme.MUTED)
		notice.text = "HP %d / %d · Lv.%d · 다음 습격 %s" % [outpost.get("current_hp",0),outpost.get("max_hp",0),level,("DAY %d" % next) if next > 0 else "완료"]
		if not wave_preview.is_empty():
			var parts: Array[String] = []
			for row in wave_preview:
				var enemy := DataRegistry.enemy(str(row.get("enemy_id","")))
				parts.append("%s ×%d" % [enemy.get("display_name",row.get("enemy_id","?")),row.get("count",1)])
			_paragraph(content,"감시 예고 · "+", ".join(parts),800,24,UXTheme.PAPER)
	elif built_type != "":
		notice.text = "유형은 회차당 하나입니다. 현재 건설된 전초기지는 바뀌지 않습니다."
	else:
		notice.text = "유형을 건설한 뒤에는 이번 회차에서 변경할 수 없습니다."
	if built_type == "":
		action.text = "이 유형으로 건설"
		action.disabled = day < OutpostServiceScript.BUILD_DAY
	elif not selected:
		action.text = "다른 유형 건설됨"
		action.disabled = true
	else:
		action.text = "Lv.2 강화 완료" if level >= 2 else ("DAY 12에 강화 가능" if day < OutpostServiceScript.UPGRADE_DAY else "Lv.2 강화")
		action.disabled = level >= 2 or day < OutpostServiceScript.UPGRADE_DAY

func _choose_type(id: String) -> void:
	if issued or not catalog.has(id):
		return
	selected_type = id
	_build_detail()
	UXTheme.apply_tree(content_root)

func _commit() -> void:
	if issued or action.disabled or not catalog.has(selected_type):
		return
	issued = true
	if str(active_run.get("outpost",{}).get("type_id","")) == "":
		outpost_selected.emit(selected_type)
	else:
		upgrade_requested.emit()

func _toggle_assignment(id: String) -> void:
	if issued or not owned_instance_ids.has(id) or str(active_run.get("outpost",{}).get("type_id","")) == "":
		return
	var assigned: Array[String] = []
	assigned.assign(active_run.get("outpost",{}).get("assigned_monster_ids",[]))
	if assigned.has(id):
		assigned.erase(id)
	elif assigned.size() < OutpostServiceScript.MAX_ASSIGNED:
		assigned.append(id)
	else:
		notice.text = "이미 3명이 배치되어 있습니다. 다른 동료를 해제한 뒤 선택하세요."
		return
	issued = true
	assignment_changed.emit(assigned)

func _upgrade() -> void:
	_commit()

func _close() -> void:
	if issued or str(active_run.get("outpost",{}).get("type_id","")) == "":
		return
	issued = true
	closed.emit()

func _fit_design_canvas() -> void:
	if not is_instance_valid(content_root) or size.x <= 0 or size.y <= 0:
		return
	var factor := minf(size.x/DESIGN_SIZE.x,size.y/DESIGN_SIZE.y)
	content_root.scale = Vector2.ONE*factor
	content_root.position = (size-DESIGN_SIZE*factor)*0.5
	UXTheme.apply_tree(content_root)

func _scroll(parent: Control, rect: Rect2, id: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = id
	scroll.position = rect.position
	scroll.size = rect.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	parent.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",14)
	scroll.add_child(box)
	return box

func _label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",UIFontScript.font_for_role(UIFontScript.ROLE_BODY))
	label.add_theme_font_size_override("font_size",UISettings.scaled_font_size(font_size))
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.tooltip_text = text
	label.set_meta("uiux_keep_font_size",true)
	parent.add_child(label)
	return label

func _paragraph(parent: Control, text: String, width: float, font_size: int, color: Color) -> Label:
	var label := _label(parent,text,Rect2(0,0,width,48),font_size,color)
	var font: Font = label.get_theme_font("font")
	var actual := label.get_theme_font_size("font_size")
	label.custom_minimum_size = Vector2(width,font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,width,actual).y+16)
	return label

func _button(parent: Control, text: String, rect: Rect2, callback: Callable, id: String) -> Button:
	var b := Button.new()
	b.name = id
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	for state in ["normal","hover","pressed","disabled","focus"]:
		b.add_theme_stylebox_override(state,UXTheme.panel(UXTheme.INK,UXTheme.GOLD if state in ["hover","focus"] else UXTheme.LINE))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _art(parent: Control, path: Variant, rect: Rect2, id: String) -> TextureRect:
	var art := TextureRect.new()
	art.name = id
	art.position = rect.position
	art.size = rect.size
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if path is Texture2D:
		art.texture = path
	elif str(path) != "" and ResourceLoader.exists(str(path)):
		art.texture = load(str(path))
	parent.add_child(art)
	return art
