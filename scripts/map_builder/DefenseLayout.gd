extends RefCounted
## Runtime-only graybox; never migrates campaign buildings or saves.
const Plot = preload("res://scripts/map_builder/PlotMask.gd")
const Roads = preload("res://scripts/map_builder/AutoRoadBuilder.gd")
const FIXED := ["entrance","throne","vault"]
const SIDES := ["N","E","S","W"]
const ROLES := ["spike_corridor","watch_post","barracks","recovery","ward_core"]
const NAMES := {"entrance":"입구","throne":"옥좌","vault":"금고","barracks":"병영","recovery":"회복 둥지","spike_corridor":"함정방","watch_post":"감시초소","ward_core":"결계핵"}
const CAPACITY := {"barracks":4,"recovery":2,"spike_corridor":2,"watch_post":3,"ward_core":1}
const AURA := {"barracks":3.0,"recovery":2.5,"spike_corridor":2.0,"watch_post":4.0,"ward_core":3.0}

static func enabled() -> bool:
	return bool(ProjectSettings.get_setting("debug/defense_layout_graybox",false)) or OS.get_cmdline_user_args().has("--defense-graybox")

static func config(variant: String) -> Dictionary:
	if variant=="ga":
		return {"size":Vector2i(18,16),"cuts":[6,12],"split":10,"bridge_y":[7,1,13],"fixed":[Rect2i(0,7,2,3),Rect2i(14,0,4,4),Rect2i(15,13,3,3)],"small":3,"medium":4,"sites":[Vector2i(0,1),Vector2i(0,12),Vector2i(8,3),Vector2i(8,10),Vector2i(14,5)]}
	return {"size":Vector2i(30,18),"cuts":[10,21],"split":11,"bridge_y":[8,1,15],"fixed":[Rect2i(0,8,3,3),Rect2i(25,0,5,5),Rect2i(26,14,4,4)],"small":3,"medium":5,"sites":[Vector2i(4,1),Vector2i(4,13),Vector2i(16,4),Vector2i(16,10),Vector2i(25,6)]}

static func terrain(variant: String) -> Dictionary:
	var cfg := config(variant)
	var plot := Plot.defense_plot(cfg.size)
	var lava: Dictionary = {}
	var bridges: Dictionary = {}
	for cell: Vector2i in plot.cells:
		if cell.x in [cfg.cuts[0],cfg.cuts[0]+1,cfg.cuts[1],cfg.cuts[1]+1] or (cell.x>cfg.cuts[1]+1 and cell.y in [cfg.split,cfg.split+1]): lava[cell] = true
	for i in range(3):
		var start := Vector2i(cfg.cuts[0] if i==0 else cfg.cuts[1],cfg.bridge_y[i])
		for offset in Roads.footprint_offsets():
			bridges[start+offset] = ["다리1","다리2a","다리2b"][i]
	# Channel footprint and walkable bridge deck are disjoint terrain classes.
	for cell in bridges: lava.erase(cell)
	return {"plot":plot,"lava":lava,"bridges":bridges}

static func zone(cell: Vector2i, variant: String) -> String:
	var cfg := config(variant)
	if cell.x<cfg.cuts[0]: return "first"
	if cell.x>=cfg.cuts[0]+2 and cell.x<cfg.cuts[1]: return "second"
	if cell.x>=cfg.cuts[1]+2:
		if cell.y<cfg.split: return "throne_court"
		if cell.y>=cfg.split+2: return "vault_court"
	return "channel"

static func preset(variant: String, catalog: Dictionary = {}) -> Array:
	var cfg := config(variant)
	var rows: Array = []
	for i in range(3):
		var id: String = FIXED[i]
		rows.append({"id":id,"role":id,"name":NAMES[id],"rect":cfg.fixed[i],"fixed":true,"capacity":0,"aura":0.0,"zone":["first","throne_court","vault_court"][i],"variant":variant})
	for i in range(ROLES.size()):
		var id: String = ROLES[i]
		var side: int = cfg.small if i<2 else cfg.medium
		rows.append({"id":id,"role":id,"name":NAMES[id],"rect":Rect2i(cfg.sites[i],Vector2i(side,side)),"fixed":false,"capacity":int(catalog.get(id,{}).get("max_monsters",CAPACITY[id])),"aura":AURA[id],"zone":["first","first","second","second","throne_court"][i],"variant":variant})
	return rows

static func candidates(row: Dictionary) -> Array:
	var r: Rect2i = row.rect
	var p := r.position
	var sx := (r.size.x-2)/2
	var sy := (r.size.y-2)/2
	var pairs := [["N",p+Vector2i(sx,0),Vector2i.RIGHT,Vector2i.UP],["E",p+Vector2i(r.size.x-1,sy),Vector2i.DOWN,Vector2i.RIGHT],["S",p+Vector2i(sx,r.size.y-1),Vector2i.RIGHT,Vector2i.DOWN],["W",p+Vector2i(0,sy),Vector2i.DOWN,Vector2i.LEFT]]
	var result: Array = []
	for pair in pairs:
		var front: Array = [pair[1]+pair[3],pair[1]+pair[2]+pair[3]]
		var anchor: Vector2i = front[0]
		if pair[0]=="N": anchor += Vector2i.UP
		if pair[0]=="W": anchor += Vector2i.LEFT
		result.append({"id":row.id,"side":pair[0],"cells":[pair[1],pair[1]+pair[2]],"front":front,"anchor":anchor})
	return result

static func line(a: Vector2i, b: Vector2i) -> Array:
	var points: Array = [a]
	while a!=b:
		a += Vector2i(signi(b.x-a.x),0) if a.x!=b.x else Vector2i(0,signi(b.y-a.y))
		points.append(a)
	return points

static func add_path(state: Dictionary, path: Array, id: String, kind: String) -> void:
	Roads._add_path(path,state.anchor_network,state.road_cells)
	state.paths.append({"id":id,"kind":kind,"anchors":path})

static func main_roads(state: Dictionary) -> void:
	var cfg := config(state.variant)
	var trunk: int = cfg.cuts[0]+2 if state.variant=="na" else cfg.cuts[1]-2
	var entry: Vector2i = state.doors.entrance.anchor
	add_path(state,line(entry,Vector2i(trunk,entry.y)),"bridge1","main")
	for i in [1,2]:
		var id: String = FIXED[i]
		add_path(state,line(Vector2i(trunk,entry.y),Vector2i(trunk,cfg.bridge_y[i])),id,"main")
		add_path(state,line(Vector2i(trunk,cfg.bridge_y[i]),state.doors[id].anchor),id,"main")
	state.main_cells = state.road_cells.duplicate()

static func build(rows: Array, variant: String = "", unavailable: Array = []) -> Dictionary:
	if variant=="": variant = rows[0].variant
	var ground := terrain(variant)
	var cfg := config(variant)
	var result := {"ok":false,"errors":[],"variant":variant,"buildings":rows.duplicate(true),"unavailable":unavailable.duplicate(true),"road_cells":{},"main_cells":{},"anchor_network":{},"doors":{},"paths":[],"defense_points":{},"plot":ground.plot,"lava":ground.lava,"bridges":ground.bridges}
	var occupied: Dictionary = {}
	var seen: Dictionary = {}
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var rect: Rect2i = row.rect
		if seen.has(row.id): result.errors.append("duplicate building: "+row.id)
		seen[row.id] = true
		var expected: Vector2i = cfg.fixed[FIXED.find(row.id)].size if row.id in FIXED else Vector2i.ONE*(cfg.small if row.id in ROLES.slice(0,2) else cfg.medium)
		if rect.size!=expected: result.errors.append("footprint changed: "+row.id)
		if row.id in FIXED and rect!=cfg.fixed[FIXED.find(row.id)]: result.errors.append("fixed facility moved: "+row.id)
		if not Plot.contains_rect(result.plot,rect): result.errors.append("outside plot: "+row.id)
		for prior in rows.slice(0,i):
			if rect.grow(1).intersects(prior.rect): result.errors.append("one-cell spacing: "+row.id)
		for x in range(rect.position.x,rect.end.x):
			for y in range(rect.position.y,rect.end.y):
				var cell := Vector2i(x,y)
				occupied[cell] = row.id
				if result.lava.has(cell) or result.bridges.has(cell): result.errors.append("channel or bridge blocked: "+row.id)
				if zone(cell,variant)!=row.zone: result.errors.append("wrong defense zone: "+row.id)
	for id in FIXED:
		if not seen.has(id): result.errors.append("missing fixed facility: "+id)
	if not result.errors.is_empty(): return result
	for row in rows:
		if row.id not in FIXED: continue
		for door in candidates(row):
			if door.side==("E" if row.id=="entrance" else "W"): result.doors[row.id] = door
	main_roads(result)
	for cell in result.road_cells:
		if occupied.has(cell) or result.lava.has(cell) or not result.plot.cells.has(cell): result.errors.append("main road obstructed")
	if not result.errors.is_empty(): return result
	for row in rows:
		if row.fixed: continue
		var clear: Dictionary = {}
		var goals: Dictionary = {}
		for cell: Vector2i in result.plot.cells:
			var valid := true
			for offset in Roads.footprint_offsets():
				var tile: Vector2i = cell+offset
				if not result.plot.cells.has(tile) or occupied.has(tile) or result.lava.has(tile) or result.bridges.has(tile) or zone(tile,variant)!=row.zone: valid = false
			if valid:
				clear[cell] = true
				var on_road := true
				for offset in Roads.footprint_offsets():
					if not result.road_cells.has(cell+offset): on_road = false
				if on_road: goals[cell] = true
		var best: Dictionary = {}
		var best_cost := 999999
		for door in candidates(row):
			if not clear.has(door.anchor): continue
			var path := Roads.defense_search(door.anchor,goals,clear,result.anchor_network,occupied)
			if path.is_empty(): continue
			var trial: Dictionary = result.road_cells.duplicate()
			var network: Dictionary = {}
			Roads._add_path(path,network,trial)
			if has_wide_patch(trial): continue
			var cost := path.size()*10
			for i in range(1,path.size()-1):
				if path[i]-path[i-1]!=path[i+1]-path[i]: cost += 60
			if cost<best_cost: best = {"door":door,"path":path}; best_cost = cost
		if best.is_empty(): result.errors.append("no same-zone width-2 approach: "+row.id); return result
		result.doors[row.id] = best.door
		add_path(result,best.path,row.id,"branch")
	assign_defenders(result,occupied)
	result.errors.append_array(validate(result))
	result.ok = result.errors.is_empty()
	return result

static func example(variant: String, catalog: Dictionary = {}) -> Dictionary:
	var requested := preset(variant,catalog)
	var rows := requested.slice(0,3)
	var unavailable: Array = []
	# Keep footprints intact and report failed facilities instead of shrinking.
	for row in requested.slice(3):
		var attempt := build(rows+[row],variant)
		if attempt.ok: rows.append(row)
		else: unavailable.append({"id":row.id,"name":row.name,"size":row.rect.size,"zone":row.zone,"reason":"해당 구역의 2칸 길·문 연결 공간 부족","errors":attempt.errors})
	return build(rows,variant,unavailable)

static func assign_defenders(state: Dictionary, occupied: Dictionary) -> void:
	var used: Dictionary = {}
	for row in state.buildings:
		var points: Array = []
		var door: Dictionary = state.doors[row.id]
		var options: Array = []
		for cell: Vector2i in state.plot.cells:
			if occupied.has(cell) or state.lava.has(cell) or state.bridges.has(cell) or used.has(cell) or zone(cell,state.variant)!=row.zone: continue
			var dist := mini(manhattan(cell,door.front[0]),manhattan(cell,door.front[1]))
			if dist>2: continue
			# Door road cells first, then the adjacent verge before the lane centre.
			var priority := dist*10+(5 if state.road_cells.has(cell) else 0)
			if cell in door.front: priority = -10
			options.append({"cell":cell,"priority":priority})
		options.sort_custom(func(a,b): return a.priority<b.priority or (a.priority==b.priority and (a.cell.y<b.cell.y or (a.cell.y==b.cell.y and a.cell.x<b.cell.x))))
		for point in options:
			if points.size()>=int(row.capacity): break
			used[point.cell] = true
			points.append({"cell":point.cell})
		state.defense_points[row.id] = points

static func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x-b.x)+absi(a.y-b.y)

static func has_wide_patch(roads: Dictionary) -> bool:
	for cell: Vector2i in roads:
		var count := 0
		for x in range(3):
			for y in range(3):
				if roads.has(cell+Vector2i(x,y)): count += 1
		if count==9: return true
	return false

static func validate(state: Dictionary) -> Array:
	var errors: Array = []
	var roads: Dictionary = state.road_cells
	var occupied: Dictionary = {}
	for row in state.buildings:
		for x in range(row.rect.position.x,row.rect.end.x):
			for y in range(row.rect.position.y,row.rect.end.y):
				var cell := Vector2i(x,y)
				occupied[cell] = true
				if state.lava.has(cell) or state.bridges.has(cell) or zone(cell,state.variant)!=row.zone: errors.append("building terrain violation")
	var reached: Dictionary = {}
	var pending: Array = [state.doors.entrance.front[0]]
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		if reached.has(cell) or not roads.has(cell): continue
		reached[cell] = true
		for offset in Roads.DIRS: pending.append(cell+offset)
	if reached.size()!=roads.size(): errors.append("disconnected road fragment")
	if has_wide_patch(roads): errors.append("road wider than two cells")
	for cell in roads:
		if state.lava.has(cell) or occupied.has(cell) or not state.plot.cells.has(cell): errors.append("road terrain violation")
	for cell in state.bridges:
		if not reached.has(cell): errors.append("bridge disconnected")
	for path in state.paths:
		if path.kind!="branch": continue
		var row_zone := ""
		for row in state.buildings:
			if row.id==path.id: row_zone = row.zone
		for anchor in path.anchors:
			for offset in Roads.footprint_offsets():
				if zone(anchor+offset,state.variant)!=row_zone or state.bridges.has(anchor+offset): errors.append("branch leaves defense zone")
	var used: Dictionary = {}
	for row in state.buildings:
		for cell in state.doors[row.id].front:
			if not reached.has(cell): errors.append("door disconnected: "+row.id)
		var points: Array = state.defense_points.get(row.id,[])
		if points.size()!=int(row.capacity): errors.append("defense capacity mismatch: "+row.id)
		for point in points:
			var cell: Vector2i = point.cell
			if used.has(cell) or occupied.has(cell) or state.lava.has(cell) or state.bridges.has(cell) or zone(cell,state.variant)!=row.zone: errors.append("invalid monster cell")
			used[cell] = true
	return errors

static func move(state: Dictionary, id: String, origin: Vector2i) -> Dictionary:
	if id in FIXED: return {"ok":false,"errors":["fixed facility cannot move"]}
	var rows: Array = state.buildings.duplicate(true)
	for row in rows:
		if row.id==id: row.rect.position = origin
	return build(rows,state.variant,state.unavailable)

static func wall_bands(row: Dictionary, door: Dictionary) -> Array:
	var rect := Rect2(row.rect)
	var bands: Array = []
	for side in SIDES:
		if side==door.get("side",""): continue
		var band: Rect2
		match side:
			"N": band = Rect2(rect.position,Vector2(rect.size.x,0.14))
			"W": band = Rect2(rect.position,Vector2(0.14,rect.size.y))
			"E": band = Rect2(rect.position+Vector2(rect.size.x-0.10,0),Vector2(0.10,rect.size.y))
			_: band = Rect2(rect.position+Vector2(0,rect.size.y-0.10),Vector2(rect.size.x,0.10))
		bands.append({"side":side,"rect":band,"rear":side in ["N","W"]})
	return bands

static func dump(state: Dictionary, _preview: Dictionary = {}, _dragging: String = "", _origin: Vector2i = Vector2i.ZERO) -> String:
	var size: Vector2i = state.plot.size
	var text := "Graybox2 %s | actual management runtime | E | grid=%s\n(0,0)=upper-left; +x right; +y down\n. floor = road ~ lava B bridge E entrance T throne V vault 1..5 facilities M one monster cell\n" % [state.variant,size]
	var cells: Dictionary = {}
	for cell in state.lava: cells[cell] = "~"
	for cell in state.road_cells: cells[cell] = "="
	for cell in state.bridges: cells[cell] = "B"
	for row in state.buildings:
		var token: String = ["E","T","V"][FIXED.find(row.id)] if row.fixed else str(ROLES.find(row.id)+1)
		for x in range(row.rect.position.x,row.rect.end.x):
			for y in range(row.rect.position.y,row.rect.end.y): cells[Vector2i(x,y)] = token
	for points in state.defense_points.values():
		for point in points: cells[point.cell] = "M"
	for y in range(size.y):
		text += "%02d " % y
		for x in range(size.x): text += cells.get(Vector2i(x,y),".")
		text += "\n"
	text += "config=%s\n" % config(state.variant)
	for row in state.buildings: text += "%s rect=%s zone=%s capacity=%s door=%s monsters=%s\n" % [row.id,row.rect,row.zone,row.capacity,state.doors[row.id],state.defense_points[row.id]]
	for item in state.unavailable: text += "배치 불가 %s %s %s %s\n" % [item.name,item.size,item.zone,item.reason]
	for path in state.paths: text += "PATH %s\n" % path
	text += "lava=%s\nbridges=%s\nroads=%s\n" % [state.lava,state.bridges,state.road_cells.keys()]
	return text
