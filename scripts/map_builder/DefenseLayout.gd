extends RefCounted
## Runtime placement state shared by the management debug view and direct tests.
const Plot = preload("res://scripts/map_builder/PlotMask.gd")
const Roads = preload("res://scripts/map_builder/AutoRoadBuilder.gd")
const FIXED := {"entrance":Vector2i(0,7),"throne":Vector2i(8,0),"vault":Vector2i(8,14)}
const SIDES := ["N","E","S","W"]
const ROLES := ["barracks","recovery","spike_corridor","watch_post","ward_core"]
const NAMES := {"entrance":"입구","throne":"마왕의 옥좌","vault":"금고","barracks":"병영","recovery":"회복둥지","spike_corridor":"함정방","watch_post":"감시초소","ward_core":"결계핵","treasure":"미끼보물실"}
const CAPACITY := {"barracks":4,"recovery":2,"spike_corridor":2,"watch_post":3,"ward_core":1,"treasure":2}
# Radius metadata only; this stage does not apply or alter any gameplay effect.
const AURA := {"barracks":3.0,"recovery":2.5,"spike_corridor":2.0,"watch_post":4.0,"ward_core":3.0,"treasure":2.0}
const PRESETS := {
	"A":[Vector2i(4,3),Vector2i(12,3),Vector2i(4,11),Vector2i(12,11),Vector2i(15,7)],
	"B":[Vector2i(3,2),Vector2i(13,4),Vector2i(4,11),Vector2i(13,11),Vector2i(16,7)],
	"C":[Vector2i(4,2),Vector2i(12,1),Vector2i(4,12),Vector2i(12,13),Vector2i(15,7)]
}

static func enabled() -> bool:
	return bool(ProjectSettings.get_setting("debug/defense_layout_graybox",false)) or OS.get_cmdline_user_args().has("--defense-graybox")

static func preset(label: String, catalog: Dictionary = {}) -> Array:
	var rows: Array = []
	for id in FIXED:
		rows.append({"id":id,"role":id,"name":NAMES[id],"rect":Rect2i(FIXED[id],Vector2i(2,2)),"fixed":true,"capacity":0,"aura":0.0})
	for index in range(ROLES.size()):
		var role: String = ROLES[index]
		rows.append({"id":role,"role":role,"name":NAMES[role],"rect":Rect2i(PRESETS[label][index],Vector2i(2,2)),"fixed":false,"capacity":int(catalog.get(role,{}).get("max_monsters",CAPACITY[role])),"aura":AURA[role]})
	return rows

static func candidates(row: Dictionary) -> Array:
	var rect: Rect2i = row.rect
	var p := rect.position
	return [
		{"id":row.id,"side":"N","anchor":p+Vector2i(0,-2),"cells":[p,p+Vector2i.RIGHT],"front":[p+Vector2i.UP,p+Vector2i(1,-1)]},
		{"id":row.id,"side":"E","anchor":p+Vector2i(2,0),"cells":[p+Vector2i.RIGHT,p+Vector2i.ONE],"front":[p+Vector2i(2,0),p+Vector2i(2,1)]},
		{"id":row.id,"side":"S","anchor":p+Vector2i(0,2),"cells":[p+Vector2i.DOWN,p+Vector2i.ONE],"front":[p+Vector2i(0,2),p+Vector2i(1,2)]},
		{"id":row.id,"side":"W","anchor":p+Vector2i(-2,0),"cells":[p,p+Vector2i.DOWN],"front":[p+Vector2i.LEFT,p+Vector2i(-1,1)]}
	]

static func build(rows: Array) -> Dictionary:
	var result := {"ok":false,"errors":[],"buildings":rows.duplicate(true),"road_cells":{},"anchor_network":{},"doors":{},"paths":[],"defense_points":{},"plot":Plot.defense_plot()}
	var occupied: Dictionary = {}
	var seen: Dictionary = {}
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		var rect: Rect2i = row.rect
		if seen.has(row.id): result.errors.append("duplicate building: "+row.id)
		seen[row.id] = true
		if rect.size != Vector2i(2,2): result.errors.append("unsupported footprint: "+row.id)
		if FIXED.has(row.id) and rect.position != FIXED[row.id]: result.errors.append("fixed facility moved: "+row.id)
		if not Plot.contains_rect(result.plot,rect): result.errors.append("outside plot: "+row.id)
		for prior in rows.slice(0,index):
			if rect.grow(1).intersects(prior.rect): result.errors.append("one-cell spacing: "+row.id)
		for x in range(rect.position.x,rect.end.x):
			for y in range(rect.position.y,rect.end.y): occupied[Vector2i(x,y)] = row.id
	for id in FIXED:
		if not seen.has(id): result.errors.append("missing fixed facility: "+id)
	if not result.errors.is_empty(): return result
	var clear: Dictionary = {}
	for cell: Vector2i in result.plot.cells:
		var valid := true
		for offset in Roads.footprint_offsets():
			if not result.plot.cells.has(cell+offset) or occupied.has(cell+offset): valid = false
		if valid: clear[cell] = true
	var fixed_sides := {"entrance":"E","throne":"S","vault":"N"}
	for row in rows:
		if not FIXED.has(row.id): continue
		for door in candidates(row):
			if door.side == fixed_sides[row.id]: result.doors[row.id] = door
		if not clear.has(result.doors[row.id].anchor): result.errors.append("fixed approach blocked: "+row.id)
	if not result.errors.is_empty(): return result
	for id in ["throne","vault"]:
		var path := Roads.defense_search(result.doors.entrance.anchor,{result.doors[id].anchor:true},clear,result.anchor_network,occupied)
		if path.is_empty(): result.errors.append("entrance cannot reach "+id); return result
		add_path(result,path,id,"main")
	# Main roads are established first. Choose the nearest reachable socket,
	# then keep that one opening; the other three sides remain closed.
	for row in rows:
		if FIXED.has(row.id): continue
		var choices := candidates(row)
		var best: Dictionary = {}
		var best_distance := 99999
		var best_cost := 999999
		for door in choices:
			if not clear.has(door.anchor): continue
			var nearest := distance(door.anchor,result.anchor_network)
			if nearest>best_distance: continue
			var path := Roads.defense_search(door.anchor,result.anchor_network,clear,result.anchor_network,occupied)
			if path.is_empty(): continue
			var trial: Dictionary = result.road_cells.duplicate()
			for anchor: Vector2i in path:
				for offset in Roads.footprint_offsets(): trial[anchor+offset] = true
			if has_wide_patch(trial): continue
			var cost := path.size()*10
			for index in range(1,path.size()-1):
				if path[index]-path[index-1]!=path[index+1]-path[index]: cost += 60
			if nearest<best_distance or cost<best_cost:
				best = {"door":door,"path":path}
				best_distance = nearest
				best_cost = cost
		if best.is_empty(): result.errors.append("no reachable door: "+row.id); return result
		result.doors[row.id] = best.door
		add_path(result,best.path,row.id,"branch")
	for row in rows:
		var points: Array = []
		var front: Array = result.doors[row.id].front
		for index in range(int(row.capacity)):
			# Several monsters may stand within a road cell; no off-road dots.
			var cell: Vector2i = front[index%2]
			var offset := Vector2(0.32 if index%2==0 else 0.68,0.32 if index<2 else 0.68)
			points.append({"cell":cell,"offset":offset})
		result.defense_points[row.id] = points
	result.errors.append_array(validate(result,occupied))
	result.ok = result.errors.is_empty()
	return result

static func distance(cell: Vector2i, goals: Dictionary) -> int:
	var best := 99999
	for goal: Vector2i in goals: best = mini(best,absi(cell.x-goal.x)+absi(cell.y-goal.y))
	return best

static func has_wide_patch(roads: Dictionary) -> bool:
	for cell: Vector2i in roads:
		var count := 0
		for x in range(3):
			for y in range(3):
				if roads.has(cell+Vector2i(x,y)): count += 1
		if count==9: return true
	return false

static func add_path(state: Dictionary, path: Array, id: String, kind: String) -> void:
	Roads._add_path(path,state.anchor_network,state.road_cells)
	state.paths.append({"id":id,"kind":kind,"anchors":path})

static func validate(state: Dictionary, occupied: Dictionary = {}) -> Array:
	var errors: Array = []
	var roads: Dictionary = state.road_cells
	var reached: Dictionary = {}
	var pending: Array = [state.doors.entrance.front[0]]
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		if reached.has(cell) or not roads.has(cell): continue
		reached[cell] = true
		for offset in Roads.DIRS: pending.append(cell+offset)
	if reached.size()!=roads.size(): errors.append("disconnected road fragment")
	# A solid 3x3 road square indicates adjacent parallel lanes widening into
	# a plaza. Width-two L/T/+ junctions do not contain a full 3x3 square.
	if has_wide_patch(roads): errors.append("road wider than two cells")
	var reconstructed: Dictionary = {}
	for path in state.paths:
		var anchors: Array = path.anchors
		var previous := Vector2i.ZERO
		var run := 0
		for index in range(anchors.size()):
			var anchor: Vector2i = anchors[index]
			for offset in Roads.footprint_offsets():
				var cell: Vector2i = anchor+offset
				reconstructed[cell] = true
				if not roads.has(cell) or occupied.has(cell) or not state.plot.cells.has(cell): errors.append("width-2 footprint obstructed")
			if index==0: continue
			var delta: Vector2i = anchor-anchors[index-1]
			if delta not in Roads.DIRS: errors.append("nonadjacent path anchor")
			if delta!=previous and run>0:
				if run<2: errors.append("straight segment shorter than three anchor cells")
				run = 0
			previous = delta
			run += 1
		if run>0 and run<2: errors.append("terminal segment shorter than three anchor cells")
	if reconstructed.size()!=roads.size(): errors.append("unowned road tile")
	for row in state.buildings:
		if not state.doors.has(row.id): errors.append("missing door: "+row.id); continue
		for cell in state.doors[row.id].front:
			if not reached.has(cell): errors.append("door disconnected: "+row.id)
		var points: Array = state.defense_points.get(row.id,[])
		if points.size()!=int(row.capacity): errors.append("defense capacity mismatch: "+row.id)
		for point in points:
			if point.cell not in state.doors[row.id].front or not reached.has(point.cell): errors.append("defender outside door road")
	return errors

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

static func move(state: Dictionary, id: String, origin: Vector2i) -> Dictionary:
	if FIXED.has(id): return {"ok":false,"errors":["fixed facility cannot move"]}
	var rows: Array = state.buildings.duplicate(true)
	for row in rows:
		if row.id == id: row.rect.position = origin
	return build(rows)

static func dump(state: Dictionary, preview: Dictionary = {}, dragging: String = "", origin: Vector2i = Vector2i.ZERO) -> String:
	var text := "Defense layout graybox 1.3.0 | actual management runtime data\nGrid: 18x16; (0,0)=upper-left; +x=right; +y=down\n. floor  = road  D door  E entrance  T throne  V vault  1..5 buildings\n"
	var cells: Dictionary = {}
	for cell in state.road_cells: cells[cell] = "="
	for index in range(state.buildings.size()):
		var row: Dictionary = state.buildings[index]
		var token: String = str(index-2) if index>=3 else ["E","T","V"][index]
		for x in range(row.rect.position.x,row.rect.end.x):
			for y in range(row.rect.position.y,row.rect.end.y): cells[Vector2i(x,y)] = token
	for door in state.doors.values():
		for cell in door.cells: cells[cell] = "D"
	text += "    012345678901234567\n"
	for y in range(16):
		text += "%02d  " % y
		for x in range(18): text += cells.get(Vector2i(x,y),".")
		text += "\n"
	for row in state.buildings:
		text += "%s %s rect=%s fixed=%s capacity=%d aura=%s door=%s front=%s points=%s\n" % [row.id,row.name,row.rect,row.fixed,row.capacity,row.aura,state.doors.get(row.id,{}),state.doors.get(row.id,{}).get("front",[]),state.defense_points.get(row.id,[])]
	for path in state.paths: text += "PATH %s %s %s\n" % [path.id,path.kind,path.anchors]
	text += "road_cells=%s\nanchor_network=%s\n" % [state.road_cells.keys(),state.anchor_network.keys()]
	if not preview.is_empty():
		text += "DRAG id=%s origin=%s accepted=%s errors=%s\nPREVIEW_ROAD_CELLS=%s\nPREVIEW_DOORS=%s\n" % [dragging,origin,preview.ok,preview.errors,preview.get("road_cells",{}).keys(),preview.get("doors",{})]
	return text
