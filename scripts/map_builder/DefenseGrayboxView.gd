extends Control
## Interactive debug renderer embedded in the real management workspace.
const Layout = preload("res://scripts/map_builder/DefenseLayout.gd")
const Service = preload("res://scripts/map_builder/MapBuildService.gd")
const FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")
var CELL := 40.0
var GRID := Vector2(78,218)
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
var selected_preset := "ga"
var message := "건물을 드래그하면 문과 가지길이 자동으로 연결됩니다."

func setup(game: Node) -> void:
	root = game
	name = "DefenseGrayboxManagement"
	size = Vector2(1920,1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	state = Service.defense_state(root)
	fit_grid()
	for index in range(2):
		var id: String = ["ga","na"][index]
		var button := Button.new()
		button.text = "(가) 18×16" if id=="ga" else "(나) 30×18"
		button.position = Vector2(1336+index*256,102)
		button.size = Vector2(230,44)
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
	fit_grid()
	cancel_drag()
	message = "입구 → 1차 → 다리1 → 2차 갈림 → 다리2a 옥좌 / 다리2b 금고"
	queue_redraw()

func fit_grid() -> void:
	CELL = 40.0 if state.variant=="na" else 44.0
	GRID = Vector2(78+(1200-state.plot.size.x*CELL)/2,220)

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
	if event.keycode in [KEY_A,KEY_B]:
		load_preset({KEY_A:"ga",KEY_B:"na"}[event.keycode])
		return true
	return false

func text_at(point: Vector2, text: String, font_size: int = 20, color: Color = Color("#30363d")) -> void:
	draw_string(FONT,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(GRID+Vector2(cell)*CELL,Vector2.ONE*CELL)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#f0f1f2"))
	draw_rect(Rect2(0,0,1920,76),Color("#29303a"))
	text_at(Vector2(40,48),"성 관리  /  회색 박스 2차 · 방어선과 건물 크기",28,Color.WHITE)
	text_at(Vector2(1450,47),"1.3.0  ·  사용자 확인 대기",22,Color("#d6dce2"))
	var shown: Dictionary = preview if not preview.is_empty() and preview.ok else state
	var grid_size: Vector2i = shown.plot.size
	var cfg := Layout.config(shown.variant)
	text_at(Vector2(48,118),"%s  |  등급 E  |  %d × %d칸  |  요청 8개 / 배치 %d개" % ["(가)" if shown.variant=="ga" else "(나)",grid_size.x,grid_size.y,shown.buildings.size()],24)
	text_at(Vector2(48,154),"몬스터 1마리 = 1칸   ·   길 / 다리 폭 2칸 = 2마리 나란히   ·   용암 수로 폭 2칸",20)
	text_at(Vector2(48,1018),message,23,Color("#b82d3f") if not preview.is_empty() and not preview.ok else Color("#334d44"))
	text_at(Vector2(48,1056),"드래그: 같은 구역 안에서 이동    ESC: 취소    A: (가)    B: (나)    수로·고정 다리·주 도로를 막는 배치는 거부",18)
	for i in range(3):
		var start: int = 0 if i==0 else cfg.cuts[i-1]+2
		var p := GRID+Vector2(start*CELL,-48)
		text_at(p,["1차 방어선","2차 방어선","최종 방어선"][i],22)
		text_at(p+Vector2(0,25),["입구 · 전초","주 전장 · 갈림길","옥좌 / 금고 두 뜰"][i],16)
	draw_rect(Rect2(GRID,Vector2(grid_size)*CELL),FLOOR)
	for cell: Vector2i in shown.lava: draw_rect(cell_rect(cell),Color("#965940"))
	for cell: Vector2i in shown.road_cells: draw_rect(cell_rect(cell),ROAD)
	for cell: Vector2i in shown.bridges: draw_rect(cell_rect(cell),Color("#72acb4"))
	for x in range(grid_size.x+1): draw_line(GRID+Vector2(x*CELL,0),GRID+Vector2(x*CELL,grid_size.y*CELL),Color(0.25,0.28,0.32,0.20))
	for y in range(grid_size.y+1): draw_line(GRID+Vector2(0,y*CELL),GRID+Vector2(grid_size.x*CELL,y*CELL),Color(0.25,0.28,0.32,0.20))
	for x in range(grid_size.x): text_at(GRID+Vector2(x*CELL+8,-4),str(x),13,Color("#6a727c"))
	for y in range(grid_size.y): text_at(GRID+Vector2(-28,y*CELL+27),str(y),14,Color("#6a727c"))
	for row in shown.buildings: draw_building(row,shown.doors.get(row.id,{}))
	for points in shown.defense_points.values():
		for point in points:
			var rect := cell_rect(point.cell)
			draw_rect(rect,Color(0.81,0.16,0.22,0.45))
			draw_rect(rect,Color("#c52f43"),false,2)
	for i in range(3):
		var p := GRID+Vector2((cfg.cuts[0] if i==0 else cfg.cuts[1])*CELL,(cfg.bridge_y[i]+0.8)*CELL)
		text_at(p+Vector2(4,0),["다리1","다리2a","다리2b"][i],16,Color("#143c44"))
	var court_x: float = GRID.x+(cfg.cuts[1]+2)*CELL+4
	text_at(Vector2(court_x,GRID.y+cfg.split*CELL-8),"옥좌 뜰",17,Color("#563e71"))
	text_at(Vector2(court_x,GRID.y+(cfg.split+2)*CELL+23),"금고 뜰",17,Color("#765a2f"))
	if dragging!="":
		for row in state.buildings:
			if row.id!=dragging: continue
			var rect := Rect2(GRID+Vector2(drag_origin)*CELL,Vector2(row.rect.size)*CELL)
			var color := Color("#3c976e") if preview.ok else Color("#d13b4f")
			draw_circle(rect.get_center(),float(row.aura)*CELL,Color(color,0.13))
			draw_arc(rect.get_center(),float(row.aura)*CELL,0,TAU,96,Color(color,0.65),2,true)
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
	var small := "%d×%d · %s" % [row.rect.size.x,row.rect.size.y,"고정" if row.fixed else "수비 %d" % row.capacity]
	text_at(rect.get_center()+Vector2(-FONT.get_string_size(small,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x/2,21),small,15,ink)

func legend(shown: Dictionary) -> void:
	text_at(Vector2(1336,202),"방어선 연결 검사",25)
	var lines := ["입구 → 다리1 → 2차 갈림", "다리2a → 옥좌  /  다리2b → 금고", "배치된 문 %d / %d 연결" % [shown.doors.size(),shown.buildings.size()],"수로 위 건물·길 0  /  떨어진 길 0", "건물 가지길: 같은 구역 안에서만"]
	for i in range(lines.size()): text_at(Vector2(1336,240+i*31),lines[i],19)
	text_at(Vector2(1336,420),"범례",22)
	var entries := [["빈 바닥",FLOOR],["자동 길 · 폭 2칸",ROAD],["용암 수로 · 통행 / 건설 불가",Color("#965940")],["고정 다리 · 폭 2칸 · 유일한 횡단",Color("#72acb4")],["몬스터 1칸 · 빨간 네모 1개 = 1마리",Color("#cf384a")],["문 · 선택한 한 면",GREEN]]
	for i in range(entries.size()):
		var p := Vector2(1336,440+i*35)
		draw_rect(Rect2(p,Vector2(22,22)),entries[i][1])
		text_at(p+Vector2(34,18),entries[i][0],18)
	text_at(Vector2(1336,692),"예시 건물 · 소형 / 중형",22)
	var y := 728
	for id in Layout.ROLES:
		var missing: Dictionary = {}
		for row in shown.unavailable:
			if row.id==id: missing = row
		var label: String = Layout.NAMES[id]
		if not missing.is_empty(): label += " %d×%d · 배치 불가" % [missing.size.x,missing.size.y]
		else:
			for row in shown.buildings:
				if row.id==id: label += " %d×%d · 수비 %d" % [row.rect.size.x,row.rect.size.y,row.capacity]
		text_at(Vector2(1336,y),label,21,Color("#b82d3f") if not missing.is_empty() else Color("#30363d"))
		y += 36
	text_at(Vector2(1336,936),"수비 칸: 문 앞 → 길 가장자리 우선",18)
	text_at(Vector2(1336,964),"배치 불가 건물의 크기는 줄이지 않음",18)
