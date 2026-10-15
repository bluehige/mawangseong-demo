extends Control
## Interactive debug renderer embedded in the real management workspace.
const Layout = preload("res://scripts/map_builder/DefenseLayout.gd")
const Service = preload("res://scripts/map_builder/MapBuildService.gd")
const FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")
const CELL := 48.0
const GRID := Vector2(388,174)
const COLORS := {"entrance":Color("#344c69"),"throne":Color("#563e71"),"vault":Color("#765a2f"),"barracks":Color("#a7bbcf"),"recovery":Color("#b0cbbd"),"spike_corridor":Color("#d3b0a3"),"watch_post":Color("#b7b1cc"),"ward_core":Color("#a6c8cd"),"treasure":Color("#d3c28b")}
const FLOOR := Color("#dedfe0")
const ROAD := Color("#d5c49d")
const DARK := Color("#45494e")
const RIM := Color("#b9bec2")
const GREEN := Color("#64b986")
var root: Node
var state: Dictionary = {}
var preview: Dictionary = {}
var dragging := ""
var drag_origin := Vector2i.ZERO
var drag_offset := Vector2i.ZERO
var selected_preset := "A"
var message := "건물을 드래그하면 문과 가지길이 자동으로 연결됩니다."

func setup(game: Node) -> void:
	root = game
	name = "DefenseGrayboxManagement"
	size = Vector2(1920,1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	state = Service.defense_state(root)
	for index in range(3):
		var id: String = ["A","B","C"][index]
		var button := Button.new()
		button.text = "배치 "+id
		button.position = Vector2(1336+index*128,102)
		button.size = Vector2(112,44)
		button.add_theme_font_override("font",FONT)
		button.add_theme_font_size_override("font_size",20)
		button.pressed.connect(load_preset.bind(id))
		add_child(button)

func load_preset(id: String) -> void:
	var next := Service.defense_state(root,id)
	if not next.ok:
		message = str(next.errors)
		queue_redraw()
		return
	state = next
	selected_preset = id
	cancel_drag()
	message = "배치 %s · 입구→옥좌 / 입구→금고 / 모든 문 연결 확인" % id
	queue_redraw()

func screen_cell(point: Vector2) -> Vector2i:
	return Vector2i(((point-GRID)/CELL).floor())

func center(cell: Vector2i) -> Vector2:
	return GRID+(Vector2(cell)+Vector2(0.5,0.5))*CELL

func begin_drag(cell: Vector2i) -> bool:
	for row in state.buildings:
		if not row.rect.has_point(cell): continue
		if row.fixed:
			message = row.name+"는 고정 시설입니다. 이동·철거할 수 없습니다."
			queue_redraw()
			return false
		dragging = row.id
		drag_offset = cell-row.rect.position
		update_drag(cell)
		return true
	return false

func update_drag(cell: Vector2i) -> void:
	if dragging == "": return
	drag_origin = cell-drag_offset
	preview = Layout.move(state,dragging,drag_origin)
	message = "배치 가능 · 놓으면 문·길·수비 지점 갱신" if preview.ok else "배치 거부 · 주 도로 / 문 연결 / 건물 간격을 확보하세요"
	queue_redraw()

func end_drag() -> bool:
	if dragging == "": return false
	# Rebuild at the release boundary, rather than trusting a stale preview.
	var next := Layout.move(state,dragging,drag_origin)
	var accepted: bool = next.ok
	if accepted:
		state = next
		Service.apply_defense_state(root,state)
		message = "배치 적용 · 자동 길·문·수비 지점 갱신"
	cancel_drag()
	queue_redraw()
	return accepted

func cancel_drag() -> void:
	dragging = ""
	preview = {}
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: begin_drag(screen_cell(event.position))
		else: end_drag()
		accept_event()
	elif event is InputEventMouseMotion and dragging!="":
		update_drag(screen_cell(event.position))
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed: begin_drag(screen_cell(event.position))
		else: end_drag()
		accept_event()
	elif event is InputEventScreenDrag and dragging!="":
		update_drag(screen_cell(event.position))
		accept_event()

func handle_key(event: InputEvent) -> bool:
	if not event is InputEventKey or not event.pressed or event.echo: return false
	if event.keycode==KEY_ESCAPE and dragging!="":
		cancel_drag()
		return true
	if event.keycode in [KEY_A,KEY_B,KEY_C]:
		load_preset({KEY_A:"A",KEY_B:"B",KEY_C:"C"}[event.keycode])
		return true
	return false

func text_at(point: Vector2, text: String, font_size: int = 20, color: Color = Color("#30363d")) -> void:
	draw_string(FONT,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(GRID+Vector2(cell)*CELL,Vector2.ONE*CELL)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#f0f1f2"))
	draw_rect(Rect2(0,0,1920,76),Color("#29303a"))
	text_at(Vector2(40,48),"성 관리  /  수비 구조·건물 배치",28,Color.WHITE)
	text_at(Vector2(1400,47),"1.3.0  ·  회색 박스 검토",22,Color("#d6dce2"))
	text_at(Vector2(48,118),"등급 E  |  18 × 16칸  |  건물 8개",22)
	text_at(Vector2(48,150),"자동 길 폭 2칸 · 최소 간격 1칸",18)
	text_at(Vector2(48,1018),message,24,Color("#b82d3f") if not preview.is_empty() and not preview.ok else Color("#334d44"))
	text_at(Vector2(48,1056),"드래그: 이동    놓기: 적용    ESC: 취소    A / B / C: 같은 8개 건물의 비교 배치",18)
	draw_rect(Rect2(GRID,Vector2(18,16)*CELL),FLOOR)
	var shown: Dictionary = preview if not preview.is_empty() and preview.ok else state
	for cell: Vector2i in shown.road_cells: draw_rect(cell_rect(cell),ROAD)
	if not preview.is_empty() and preview.ok:
		for cell: Vector2i in shown.road_cells:
			if not state.road_cells.has(cell): draw_rect(cell_rect(cell),Color(0.22,0.65,0.43,0.36))
	for x in range(19): draw_line(GRID+Vector2(x*CELL,0),GRID+Vector2(x*CELL,16*CELL),Color(0.25,0.28,0.32,0.16))
	for y in range(17): draw_line(GRID+Vector2(0,y*CELL),GRID+Vector2(18*CELL,y*CELL),Color(0.25,0.28,0.32,0.16))
	for x in range(18): text_at(GRID+Vector2(x*CELL+17,-12),str(x),15,Color("#6a727c"))
	for y in range(16): text_at(GRID+Vector2(-32,y*CELL+29),str(y),15,Color("#6a727c"))
	# Flat interior bands only. Nothing extends over another building or floor.
	for row in shown.buildings: draw_building(row,shown.doors.get(row.id,{}))
	for points in shown.defense_points.values():
		for point in points:
			draw_circle(GRID+(Vector2(point.cell)+point.offset)*CELL,5.5,Color("#cf384a"))
	if dragging!="":
		var row: Dictionary = {}
		for building in state.buildings:
			if building.id==dragging: row = building
		var c := GRID+(Vector2(drag_origin)+Vector2.ONE)*CELL
		var color := Color("#3c976e") if preview.ok else Color("#d13b4f")
		draw_circle(c,float(row.aura)*CELL,Color(color,0.13))
		draw_arc(c,float(row.aura)*CELL,0,TAU,96,Color(color,0.65),2,true)
		var rect := Rect2(GRID+Vector2(drag_origin)*CELL,Vector2.ONE*CELL*2)
		draw_rect(rect,Color(color,0.22))
		draw_rect(rect,color,false,4)
		text_at(rect.position+Vector2(0,-12),"연결 미리보기" if preview.ok else "배치 거부",20,color)
	legend(shown)

func draw_building(row: Dictionary, door: Dictionary) -> void:
	var rect := Rect2(GRID+Vector2(row.rect.position)*CELL,Vector2(row.rect.size)*CELL)
	draw_rect(rect,COLORS[row.role])
	var side := str(door.get("side",""))
	for band in Layout.wall_bands(row,door):
		var r: Rect2 = band.rect
		draw_rect(Rect2(GRID+r.position*CELL,r.size*CELL),DARK if band.rear else RIM)
	if not door.is_empty():
		for cell in door.cells:
			var r := cell_rect(cell)
			# Green door tile is inset so the entire interior remains legible.
			var band: Rect2
			match side:
				"N": band = Rect2(r.position,Vector2(CELL,10))
				"S": band = Rect2(r.position+Vector2(0,CELL-10),Vector2(CELL,10))
				"W": band = Rect2(r.position,Vector2(10,CELL))
				_: band = Rect2(r.position+Vector2(CELL-10,0),Vector2(10,CELL))
			draw_rect(band,GREEN)
	var ink := Color.WHITE if row.fixed else Color("#27343e")
	var label: String = row.name
	var width := FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
	text_at(rect.get_center()+Vector2(-width/2,-2),label,17,ink)
	var small := "고정" if row.fixed else "수비 %d" % row.capacity
	text_at(rect.get_center()+Vector2(-FONT.get_string_size(small,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x/2,21),small,15,ink)

func legend(shown: Dictionary) -> void:
	text_at(Vector2(1336,204),"배치 "+selected_preset+"  ·  실시간 검사",25)
	var lines := ["입구 → 옥좌    연결", "입구 → 금고    연결", "건물 문 %d / %d 연결" % [shown.doors.size(),shown.buildings.size()],"떨어진 길 조각    0", "자유 벽 / 경계 벽 / 장식    0", "직선 구간 최소 3칸"]
	for index in range(lines.size()): text_at(Vector2(1336,246+index*33),lines[index],20)
	text_at(Vector2(1336,498),"범례",22)
	var entries := [["빈 바닥",FLOOR],["자동 길 · 폭 2칸",ROAD],["건물 내부 · 이름",COLORS.barracks],["뒷벽 · 위 / 왼쪽 면",DARK],["낮은 턱 · 아래 / 오른쪽 면",RIM],["문 · 선택한 한 면",GREEN],["수비 지점 · 정원만큼",Color("#cf384a")],["드래그 오라 · 효과 범위",Color(0.22,0.65,0.43,0.30)]]
	for index in range(entries.size()):
		var p := Vector2(1336,526+index*36)
		if index==6: draw_circle(p+Vector2(10,10),5.5,entries[index][1])
		else: draw_rect(Rect2(p,Vector2(20,20)),entries[index][1])
		text_at(p+Vector2(34,17),entries[index][0],18)
	text_at(Vector2(1336,868),"고정 시설은 이동·철거 불가",19)
	text_at(Vector2(1336,901),"문은 네 후보 중 가까운 길로 선택",19)
	text_at(Vector2(1336,934),"오라: 반경 데이터만 · 효과 수치 유지",18)
