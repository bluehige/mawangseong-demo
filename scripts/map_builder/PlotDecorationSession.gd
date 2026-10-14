extends RefCounted
const Rules = preload("res://scripts/map_builder/PlotDecorationRules.gd")
const Iso = preload("res://scripts/dungeon_quarter/IsoMath.gd")
const BRAZIER = preload("res://assets/props/decor/prop_small_brazier_back.png")
var root: Node
var chosen := ""
var removing := false
var preview_cell := Vector2i(-1,-1)
var preview_valid := false
var touch_index := -1
var mouse_deadline := 0
func reset() -> void:
	chosen = ""; removing = false; preview_cell = Vector2i(-1,-1); preview_valid = false; touch_index = -1
func active() -> bool: return chosen!="" or removing
func source() -> Dictionary: return root.build_placement.plot.source()
func rows() -> Array: return source().get("decorations",[])
func begin(id: String) -> void:
	root._clear_management_action_mode(false)
	chosen = id
	removing = id == "remove"
	root.management_tool_tab = "decor"
	root.management_scene.workspace_ui.tools_expanded = true
	root._set_screen("management",false)
func valid(cell: Vector2i, id: String) -> bool:
	var layout: Dictionary = root.graph.layout.duplicate()
	var entries := rows().duplicate(true)
	entries.append({"id":id,"cell":[cell.x,cell.y]})
	layout["decorations"] = entries
	return Rules.validate(layout,DataRegistry.quarter_modules)==""
func place(cell: Vector2i) -> bool:
	if not active() or root.current_screen!="management": return false
	var next := source()
	var entries: Array = next.get("decorations",[]).duplicate(true)
	if removing:
		var found := -1
		for i in range(entries.size()):
			if Iso.array_to_cell(entries[i].cell)==cell: found = i
		if found<0: return false
		entries.remove_at(found)
	else:
		if not valid(cell,chosen): return false
		entries.append({"id":chosen,"cell":[cell.x,cell.y]})
	root._capture_management_undo(root.continuity.localized("장식 배치","Decoration placement","装饰布置"))
	next["decorations"] = entries
	root.runtime_plot_layout = next
	root._refresh_quarter_map_from_rooms()
	reset()
	root._set_screen("management",false)
	return true
func handle_input(event: InputEvent) -> bool:
	if not active(): return false
	if event is InputEventMouse and (event.device==InputEvent.DEVICE_ID_EMULATION or Time.get_ticks_msec()<mouse_deadline): return true
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		root._cancel_management_action_mode(); return true
	if event is InputEventMouseMotion or event is InputEventScreenDrag or event is InputEventScreenTouch or event is InputEventMouseButton:
		if event is InputEventScreenTouch or event is InputEventScreenDrag: mouse_deadline = Time.get_ticks_msec()+300
		if event is InputEventScreenTouch:
			if event.pressed:
				if touch_index!=-1 and touch_index!=event.index: return true
				touch_index = event.index
			elif event.index!=touch_index: return true
		if event is InputEventScreenDrag and event.index!=touch_index: return true
		preview_cell = root.build_placement.plot.cell_at(root.build_placement.viewport_to_world(event.position))
		preview_valid = not root._management_ui_at(event.position) and (removing or valid(preview_cell,chosen))
		root.queue_redraw(); root.queue_world_overlay_redraw()
		if root._management_ui_at(event.position): return false
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed: place(preview_cell)
		if event is InputEventScreenTouch and not event.pressed:
			touch_index = -1
			if event.canceled: root._cancel_management_action_mode()
			else: place(preview_cell)
		return true
	return false
func draw(target: CanvasItem) -> void:
	var sorted := rows().duplicate(true)
	sorted.sort_custom(func(a,b): return int(a.cell[0])+int(a.cell[1])<int(b.cell[0])+int(b.cell[1]))
	for row in sorted: draw_item(target,str(row.id),root.build_placement.plot.world(Iso.array_to_cell(row.cell)))
func draw_preview(target: CanvasItem) -> void:
	if not active() or preview_cell==Vector2i(-1,-1): return
	var color := Color("#70f6ab") if preview_valid else Color("#ff637b")
	target.draw_colored_polygon(root.build_placement.plot._polygon(preview_cell),Color(color,0.45))
	if not removing: draw_item(target,chosen,root.build_placement.plot.world(preview_cell),Color(color,0.7))
static func draw_item(target: CanvasItem, id: String, p: Vector2, tint: Color = Color.WHITE, scale_value: float = 1.0) -> void:
	var ink := Color("#292333")*tint
	var color := Color(str(Rules.item(id).get("color","#ffffff")))*tint
	var s := scale_value
	target.draw_circle(p+Vector2(0,4)*s,14*s,Color(0,0,0,0.3)*tint)
	match id:
		"torch", "brazier":
			target.draw_texture_rect(BRAZIER,Rect2(p-Vector2(19,53)*s,Vector2(38,58)*s),false,tint)
			if id=="torch": target.draw_line(p-Vector2(0,7)*s,p-Vector2(0,34)*s,color,4*s)
		"banner":
			target.draw_line(p,p-Vector2(0,60)*s,Color("#bd9b65")*tint,4*s)
			target.draw_colored_polygon(PackedVector2Array([p+Vector2(2,-58)*s,p+Vector2(29,-58)*s,p+Vector2(29,-23)*s,p+Vector2(16,-30)*s,p+Vector2(2,-23)*s]),color)
			target.draw_line(p+Vector2(6,-50)*s,p+Vector2(24,-50)*s,Color("#e5bd75")*tint,2*s)
		"crystal":
			for offset in [Vector2(-9,0),Vector2(5,-5),Vector2(13,3)]:
				var base: Vector2 = p+offset*s
				target.draw_colored_polygon(PackedVector2Array([base+Vector2(-7,0)*s,base+Vector2(-5,-22)*s,base+Vector2(0,-34)*s,base+Vector2(7,-18)*s,base+Vector2(6,1)*s]),color)
				target.draw_line(base,base-Vector2(0,29)*s,color.lightened(0.35),2*s)
		"skulls":
			for offset in [Vector2(-8,0),Vector2(8,1),Vector2(0,-12)]:
				var pos: Vector2 = p+offset*s
				target.draw_circle(pos,8*s,color)
				target.draw_circle(pos+Vector2(-3,-1)*s,2*s,ink)
				target.draw_circle(pos+Vector2(3,-1)*s,2*s,ink)
		"statue":
			target.draw_rect(Rect2(p-Vector2(18,8)*s,Vector2(36,12)*s),color.darkened(0.3))
			target.draw_colored_polygon(PackedVector2Array([p+Vector2(-12,-9)*s,p+Vector2(-9,-39)*s,p+Vector2(9,-39)*s,p+Vector2(12,-9)*s]),color)
			target.draw_circle(p-Vector2(0,46)*s,10*s,color.lightened(0.15))
			target.draw_line(p+Vector2(10,-33)*s,p+Vector2(17,-56)*s,Color("#d8bf8e")*tint,3*s)
func build_status(ui) -> void:
	if not root.graph.layout.has("plot_grid"): return
	var value := Rules.evaluation(source(),root._castle_stage_index()-1)
	var button: Button = ui.kit_button(root.ui_layer,root.continuity.localized("성 등급 %s · 위압감 %d","Castle grade %s · Dread %d","城堡评级 %s · 威慑 %d") % [value.grade,value.intimidation],Rect2(24,194,340,62),Callable(ui,"select_tool").bind("decor"),"DecorationStatusButton")
	button.set_meta("u5b_occluder",true)
	button.tooltip_text = root.continuity.localized("%s\n평가 %d = 성장 %d + 꾸밈 %d/10\n전투 효과 없음 · 부지 확장은 기존 승급 조건 유지","%s\nAppraisal %d = growth %d + decor %d/10\nNo combat effects · Land uses existing evolution gates","%s\n评分 %d = 成长 %d + 装饰 %d/10\n不影响战斗 · 扩建仍需原有晋级条件") % [LanguageSettings.ui_text(root._castle_stage_display_line()),value.score,value.base,value.decoration]
func build_palette(ui) -> void:
	var dock: Control = ui.kit_panel(ui.TOOL_RECT,"DecorationToolbox")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(8,6); scroll.size = dock.size-Vector2(16,12)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	dock.add_child(scroll)
	var row = ui.kit_flow(scroll)
	for definition in Rules.data().items:
		var id: String = definition.id
		var card: Button = ui.kit_button(row,"",Rect2(),Callable(self,"begin").bind(id),"DecorationCard_"+id,"tactical")
		card.custom_minimum_size = Vector2(170,122)
		card.tooltip_text = root.continuity.localized("%s · 위압감 +%d\n빈칸 클릭·터치: 배치 / ESC: 취소\n전투 효과 없음","%s · Dread +%d\nClick or tap empty land to place / ESC cancels\nNo combat effects","%s · 威慑 +%d\n点击或触摸空地放置 / ESC取消\n不影响战斗") % [Rules.name_for(id),definition.intimidation]
		card.draw.connect(func(): draw_item(card,id,Vector2(26,82),Color.WHITE,0.8))
		ui.kit_copy(card,Rules.name_for(id),Rect2(50,8,114,70),24)
		ui.kit_copy(card,"+%d" % definition.intimidation,Rect2(58,78,104,34),24,ui.GOLD)
		if chosen==id: card.set_variant(1)
	var actions: Control = ui.kit_panel(Rect2(24,810,340,144),"DecorationActions")
	ui.kit_button(actions,root.continuity.localized("건설","Build","建造"),Rect2(8,8,156,58),Callable(ui,"select_tool").bind("build"),"DecorationBackButton")
	ui.kit_button(actions,root.continuity.localized("제거","Remove","移除"),Rect2(174,8,156,58),Callable(self,"begin").bind("remove"),"DecorationRemoveButton")
	ui.kit_button(actions,root.continuity.localized("취소","Cancel","取消"),Rect2(8,78,322,58),Callable(root,"_cancel_management_action_mode"),"DecorationCancelButton")
