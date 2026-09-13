extends Control
class_name UpperFloorScreen
signal layout_selected(layout_id: String)
signal closed
const UXTheme = preload("res://scripts/ui/UIUXTheme.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const DESIGN_SIZE := Vector2(1920,1080)
const ORDER := ["upper_compact_guard","upper_split_vault","upper_long_gallery"]
const CARD_RECTS := [Rect2(64,242,340,120),Rect2(64,386,340,120),Rect2(64,530,340,120)]
var upper_floor: Dictionary={}
var layouts: Dictionary={}
var modules: Dictionary={}
var candidate_id := ""
var submitted := false
var content_root: Control
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(_fit)
	_build()
	call_deferred("_fit")
func setup(upper_value: Dictionary,layouts_value: Dictionary,modules_value: Dictionary) -> void:
	upper_floor=upper_value.duplicate(true)
	layouts=layouts_value.duplicate(true)
	modules=modules_value.duplicate(true)
	candidate_id=str(upper_floor.get("layout_id",ORDER[0]))
	if not layouts.has(candidate_id): candidate_id=ORDER[0]
	submitted=false
	if is_node_ready(): _build()
func layout_rects_for_viewport(viewport_size: Vector2) -> Array[Rect2]:
	var factor:=minf(viewport_size.x/DESIGN_SIZE.x,viewport_size.y/DESIGN_SIZE.y)
	var offset:=(viewport_size-DESIGN_SIZE*factor)*0.5
	var result: Array[Rect2]=[]
	for rect in CARD_RECTS: result.append(Rect2(offset+rect.position*factor,rect.size*factor))
	return result
func _build() -> void:
	if is_instance_valid(content_root):
		remove_child(content_root)
		content_root.queue_free()
	content_root=Control.new()
	content_root.name="DesignCanvas"
	content_root.size=DESIGN_SIZE
	content_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(content_root)
	var backdrop:=TextureRect.new()
	backdrop.size=DESIGN_SIZE
	backdrop.texture=load("res://assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png")
	backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate=Color(0.26,0.23,0.3)
	backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content_root.add_child(backdrop)
	_add_label(content_root,"상층 방어 배치",Rect2(64,46,1500,70),42,UXTheme.PAPER,HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(content_root,"1층과 2층이 출전 인원을 나눕니다. 배치와 실제 연결을 살펴본 뒤 확정하세요.",Rect2(64,126,1770,64),25,UXTheme.MUTED,HORIZONTAL_ALIGNMENT_LEFT)
	var locked:=bool(upper_floor.get("layout_locked",false))
	for index in ORDER.size():
		var id: String=ORDER[index]
		var title:=str(layouts.get(id,{}).get("display_name",id))
		if id==str(upper_floor.get("layout_id","")): title+="\n"+("확정된 배치" if locked else "현재 배치")
		var b:=_button(content_root,title,CARD_RECTS[index],Callable(self,"_preview").bind(id),false)
		b.name="UpperLayout_"+id
		if id==candidate_id: b.add_theme_stylebox_override("normal",UXTheme.surface(UXTheme.INK,UXTheme.GOLD,2))
	_add_label(content_root,"고정 모듈 4개\n계단 연결 1곳",Rect2(80,712,300,96),24,UXTheme.MUTED,HORIZONTAL_ALIGNMENT_LEFT)
	var def: Dictionary=layouts.get(candidate_id,{})
	var stage:=Panel.new()
	stage.name="UpperLayoutDetail"
	stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stage.position=Vector2(446,222)
	stage.size=Vector2(1410,674)
	stage.add_theme_stylebox_override("panel",UXTheme.panel(UXTheme.INK,UXTheme.LINE))
	content_root.add_child(stage)
	_add_label(stage,str(def.get("display_name","배치 선택")),Rect2(34,24,1000,54),34,UXTheme.GOLD,HORIZONTAL_ALIGNMENT_LEFT)
	_build_diagram(stage,def)
	_add_label(stage,"장점",Rect2(956,114,398,46),26,UXTheme.GOLD,HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(stage,str(def.get("advantage","")),Rect2(956,170,398,126),25,Color("#b7d6c0"),HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(stage,"주의할 점",Rect2(956,336,398,46),26,UXTheme.GOLD,HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(stage,str(def.get("weakness","")),Rect2(956,392,398,126),25,Color("#e4abb2"),HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(stage,"선은 실제 방 연결입니다.\n1층 가시 복도에서 계단으로 진입합니다.",Rect2(956,550,398,98),22,UXTheme.MUTED,HORIZONTAL_ALIGNMENT_LEFT)
	var notice:=_add_label(content_root,"확정: %s · 살펴보는 배치: %s" % [str(layouts.get(str(upper_floor.get("layout_id","")),{}).get("display_name","")),str(def.get("display_name",""))] if locked else "확정 전에는 배치가 바뀌지 않습니다. 확정한 상층 배치는 이번 회차 동안 유지됩니다.",Rect2(446,915,1410,60),23,UXTheme.MUTED,HORIZONTAL_ALIGNMENT_LEFT)
	notice.name="UpperLayoutReview"
	var close:=_button(content_root,"관리 화면으로",Rect2(64,964,340,70),Callable(self,"_close"),false)
	close.name="UpperFloorCloseButton"
	var confirm:=_button(content_root,"확정된 배치" if locked else "이 배치로 확정",Rect2(1436,976,420,70),Callable(self,"_confirm"),locked or submitted or not layouts.has(candidate_id))
	confirm.name="UpperLayoutConfirmButton"
	_fit()
func _build_diagram(parent: Control,def: Dictionary) -> void:
	var points: Dictionary={}
	var origins: Array=def.get("placed_modules",[])
	var max_x:=1.0
	for placed in origins: max_x=maxf(max_x,float(placed.get("grid_origin",[0,0])[0]))
	for placed in origins:
		var origin: Array=placed.get("grid_origin",[0,0])
		points[str(placed.instance_id)]=Vector2(128+float(origin[0])*650/max_x,204+float(origin[1])*154)
	for edge in def.get("connections",[]):
		if edge.size()!=2 or not points.has(str(edge[0])) or not points.has(str(edge[1])): continue
		var line:=Line2D.new()
		line.name="UpperConnection_"+str(edge[0])+"_"+str(edge[1])
		line.points=PackedVector2Array([points[str(edge[0])],points[str(edge[1])]])
		line.width=5
		line.default_color=UXTheme.GOLD.darkened(0.3)
		parent.add_child(line)
	for placed in origins:
		var id:=str(placed.get("module_id",""))
		var definition: Dictionary=modules.get(id,{})
		var at: Vector2=points[str(placed.instance_id)]
		var art:=TextureRect.new()
		art.name="UpperModuleArt_"+id
		art.position=at-Vector2(85,85)
		art.size=Vector2(170,148)
		var states: Dictionary=definition.get("art_states",{})
		art.texture=load(str(states.get("normal",states.get("active",""))))
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		parent.add_child(art)
		var label:=_add_label(parent,str(definition.get("display_name",id)),Rect2(at.x-102,at.y+64,204,66),23,UXTheme.PAPER,HORIZONTAL_ALIGNMENT_CENTER)
		label.add_theme_constant_override("outline_size",6)
		label.add_theme_color_override("font_outline_color",Color("#09070d"))
func _preview(id: String) -> void:
	if submitted or not layouts.has(id): return
	candidate_id=id
	_build()
	var b:=content_root.find_child("UpperLayout_"+id,true,false) as Button
	b.grab_focus()
func _confirm() -> void:
	if submitted or bool(upper_floor.get("layout_locked",false)) or not layouts.has(candidate_id): return
	submitted=true
	(content_root.find_child("UpperLayoutConfirmButton",true,false) as Button).disabled=true
	layout_selected.emit(candidate_id)

func _close() -> void:
	closed.emit()


func _fit() -> void:
	if content_root == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	content_root.scale = Vector2.ONE * factor
	content_root.position = (size - DESIGN_SIZE * factor) * 0.5


func _add_label(parent: Control, value: String, rect: Rect2, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	label.add_theme_font_size_override("font_size", UISettings.scaled_font_size(maxi(20, font_size)))
	label.add_theme_color_override("font_color", color)
	label.tooltip_text = label.text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 3
	parent.add_child(label)
	return label


func _button(parent: Control, value: String, rect: Rect2, callback: Callable, disabled: bool) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.text = value
	button.disabled = disabled
	button.add_theme_font_override("font", UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS))
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	parent.add_child(button)
	UXTheme.apply_tree(button)
	return button


func _style(fill: Color, border: Color, width: int) -> StyleBox:
	return UXTheme.panel(fill,border,width)
