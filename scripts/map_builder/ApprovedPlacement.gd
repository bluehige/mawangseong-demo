extends RefCounted
## Pure branch-only placement model. Never writes campaign state or user saves.
const Layout = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const Roads = preload("res://scripts/map_builder/AutoRoadBuilder.gd")
const Defense = preload("res://scripts/map_builder/DefenseLayout.gd")
const SIZE := Vector2i(32,18)
const FIXED := ["entrance","throne","vault"]
const ROLES := {"watchtower":"watch_post","bait_treasure":"treasure","recovery_nest":"recovery","barracks":"barracks","ward_core":"ward_core"}
const NAMES := {"watchtower":"감시탑","bait_treasure":"미끼보물실","recovery_nest":"회복 둥지","barracks":"병영","ward_core":"결계핵","entrance":"입구","throne":"옥좌","vault":"금고","spikes":"가시 함정","sticky":"끈끈이 함정"}
const SAVE_PATH := "res://tmp/v130r_step2/copies/layout_test.json"

static func enabled() -> bool:
	return bool(ProjectSettings.get_setting("debug/approved_map_step2",false))

static func initial(game: Node) -> Dictionary:
	var plan := Layout.read()
	var state := {"buildings":[],"traps":[],"water":{},"catalog":{},"stage":3,"day":7,"resources":{"gold":1245,"mana":320,"food":18},"serial":0}
	state["stage_rules"] = JSON.parse_string(FileAccess.get_file_as_string("res://data/castle_evolution_stages.json"))
	for t in plan.traps: state.traps.append({"kind":str(t.kind),"cell":[int(t.cell[0]),int(t.cell[1])]})
	for c in Layout.cells(plan,"~B"): state.water[c] = true
	for id in ROLES:
		var definition: Dictionary = game._facility_base_definition(ROLES[id])
		var side := 3 if id in ["watchtower","bait_treasure"] else 5
		state.catalog[id] = {"name":NAMES[id],"size":Vector2i(side,side),"capacity":int(definition.get("max_monsters",1)),"cost":definition.get("cost",{}).duplicate(),"unique":ROLES[id] in game.UNIQUE_FACILITIES,"stage":3 if id=="ward_core" else 1,"aura":Defense.AURA.get(ROLES[id],0.0)}
		for stage in state.stage_rules.values():
			if ROLES[id] in stage.unlocked_facilities:
				state.catalog[id].stage = int(stage.index); break
	# Individual one-cell traps have no existing purchase rules; temporary prices.
	for id in ["spikes","sticky"]:
		state.catalog[id] = {"name":NAMES[id],"size":Vector2i.ONE,"capacity":0,"cost":{"gold":40 if id=="spikes" else 60},"unique":false,"stage":1,"aura":0.0}
	for b in plan.buildings:
		var r: Array = b.rect
		var cap := int(state.catalog.get(b.id,{}).get("capacity",0))
		if b.id=="throne": cap = 4
		if b.id=="vault": cap = 2
		var paid: Dictionary = state.catalog.get(b.id,{}).get("cost",{}).duplicate()
		var row := {"id":b.id,"kind":b.id,"rect":Rect2i(r[0],r[1],r[2],r[3]),"fixed":b.fixed,"capacity":cap,"aura":float(state.catalog.get(b.id,{}).get("aura",0.0)),"level":1,"preferred":b.door,"paid":paid}
		if b.fixed:
			row["socket_front"] = []
			for c in b.get("door_outside",[[3,8],[3,9]]): row.socket_front.append([int(c[0]),int(c[1])])
		state.buildings.append(row)
	return rebuild(state)

static func inside(c: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO,SIZE).has_point(c)

static func occupied(rows: Array) -> Dictionary:
	var result := {}
	for b in rows:
		for x in range(b.rect.position.x,b.rect.end.x):
			for y in range(b.rect.position.y,b.rect.end.y): result[Vector2i(x,y)] = b.id
	return result

static func candidates(row: Dictionary) -> Array:
	var result := Defense.candidates(row)
	# Match the approved pair tie-break: for odd sizes use the lower pair.
	# Defense.candidates already chooses floor((length-2)/2).
	result.sort_custom(func(a,b): return a.side==row.get("preferred","") and b.side!=row.get("preferred",""))
	return result

static func clear_anchors(state: Dictionary, occ: Dictionary) -> Dictionary:
	var clear := {}
	for y in range(SIZE.y-1):
		for x in range(SIZE.x-1):
			var a := Vector2i(x,y)
			var valid := true
			for d in Roads.footprint_offsets():
				if occ.has(a+d): valid = false; break
			if valid: clear[a] = true
	return clear

static func rebuild(source: Dictionary) -> Dictionary:
	var s := source.duplicate(true)
	s.merge({"ok":false,"errors":[],"road_cells":{},"anchor_network":{},"doors":{},"paths":[],"bridges":{},"defense_points":{},"influence":{}},true)
	var occ := occupied(s.buildings)
	for i in range(s.buildings.size()):
		var b: Dictionary = s.buildings[i]
		if not Rect2i(Vector2i.ZERO,SIZE).encloses(b.rect): s.errors.append("부지 밖")
		for prior in s.buildings.slice(0,i):
			if b.rect.intersects(prior.rect): s.errors.append("시설과 겹침")
		for c in occ:
			if occ[c]==b.id and s.water.has(c): s.errors.append("물길 위")
	if not s.errors.is_empty(): return s
	var clear := clear_anchors(s,occ)
	var fixed := {}
	var ids := {}
	for b in s.buildings:
		if ids.has(b.id): s.errors.append("중복 시설 ID"); return s
		ids[b.id] = true
		if b.fixed:
			var front: Array = []
			for pair in b.socket_front: front.append(Vector2i(pair[0],pair[1]))
			var direction: Vector2i = {"N":Vector2i.UP,"E":Vector2i.RIGHT,"S":Vector2i.DOWN,"W":Vector2i.LEFT}[b.preferred]
			var a: Vector2i = front[0]
			if b.preferred in ["N","W"]: a += direction
			s.doors[b.id] = {"id":b.id,"side":b.preferred,"front":front,"cells":[front[0]-direction,front[1]-direction],"anchor":a}
			fixed[b.id] = b
	if fixed.size()!=3: s.errors.append("고정 시설 누락"); return s
	# Deterministic grade-E trunk. Derive its junction from the water cuts and
	# fixed door sockets, not from the approved cached road cells or draw list.
	var cuts: Array = []
	for x in range(SIZE.x):
		if s.water.has(Vector2i(x,0)) and (x==0 or not s.water.has(Vector2i(x-1,0))): cuts.append(x)
	if cuts.size()!=2: s.errors.append("등급 E 고정 물길 오류"); return s
	var junction_x: int = (int(cuts[0])+int(cuts[1]))/2
	var entry: Vector2i = s.doors.entrance.anchor
	var joint := Vector2i(junction_x,entry.y)
	var paths := [Defense.line(entry,joint)]
	for id in ["throne","vault"]:
		var target: Vector2i = s.doors[id].anchor
		if id=="throne": target += Vector2i.RIGHT
		paths.append(Defense.line(joint,Vector2i(junction_x,target.y)))
		paths.append(Defense.line(Vector2i(junction_x,target.y),target))
	for path in paths:
		for a in path:
			if not clear.has(a): s.errors.append("입구→옥좌·금고 주 통로 차단"); return s
		Roads._add_path(path,s.anchor_network,s.road_cells)
		s.paths.append({"id":"main","anchors":path})
	for b in s.buildings:
		if b.fixed: continue
		var goals := {}
		for a in s.anchor_network:
			if clear.has(a): goals[a] = true
		var best := {}
		var best_cost := 2147483647
		for d in candidates(b):
			if not clear.has(d.anchor): continue
			var path := Roads.defense_search(d.anchor,goals,clear,s.anchor_network,occ)
			if path.is_empty(): continue
			var cost := 0
			for j in range(path.size()):
				cost += 6 if s.anchor_network.has(path[j]) else 10
				if j>1 and path[j]-path[j-1]!=path[j-1]-path[j-2]: cost += 60
			if cost<best_cost:
				best = {"door":d,"path":path}; best_cost = cost
			if d.side==b.preferred: break
		if best.is_empty(): s.errors.append("문에서 2칸 길 연결 불가"); return s
		s.doors[b.id] = best.door
		Roads._add_path(best.path,s.anchor_network,s.road_cells)
		s.paths.append({"id":b.id,"anchors":best.path})
	s.bridges = bridge_cells(s.road_cells,s.water)
	assign_defenders(s,occ)
	# A trap cannot silently disappear when moving a building reroutes its road.
	for trap in s.traps:
		var c := Vector2i(trap.cell[0],trap.cell[1])
		if not s.road_cells.has(c) or s.water.has(c): s.errors.append("함정의 길이 사라짐: "+str(c))
	s.errors.append_array(validate_routes(s))
	s.ok = s.errors.is_empty()
	return s

static func bridge_cells(roads: Dictionary, water: Dictionary) -> Dictionary:
	var result := {}
	for c in roads:
		if water.has(c):
			# A water column is crossed in x (screen up-right), a water row in y.
			result[c] = "x" if water.has(Vector2i(c.x,0)) else "y"
	return result

static func assign_defenders(s: Dictionary, occ: Dictionary) -> void:
	var used := {}
	for b in s.buildings:
		var d: Dictionary = s.doors[b.id]
		var wanted: Array = []
		var a: Vector2i = d.anchor
		if b.kind=="throne": a += Vector2i.RIGHT
		if d.side in ["N","S"]:
			for dy in range(3):
				for dx in range(2): wanted.append(a+Vector2i(dx,dy))
		elif b.capacity==1: wanted.append(d.front[1])
		else: wanted.append_array(d.front)
		var options: Array = s.road_cells.keys()
		options.sort_custom(func(c,e):
			var cd: int = Defense.manhattan(c,a)
			var ed: int = Defense.manhattan(e,a)
			return cd<ed or (cd==ed and (c.y<e.y or (c.y==e.y and c.x<e.x))))
		wanted.append_array(options)
		var points: Array = []
		for c in wanted:
			if points.size()>=b.capacity: break
			if used.has(c) or occ.has(c) or s.water.has(c) or not s.road_cells.has(c): continue
			used[c] = true; points.append(c)
		s.defense_points[b.id] = points
		if points.size()!=b.capacity: s.errors.append("수비 정원 자리 부족")
		var aura: Array = []
		var center: Vector2 = Vector2(b.rect.get_center())
		for y in range(SIZE.y):
			for x in range(SIZE.x):
				var c := Vector2i(x,y)
				if b.aura>0 and Vector2(c).distance_to(center)<=b.aura and not s.water.has(c): aura.append(c)
		s.influence[b.id] = aura

static func validate_routes(s: Dictionary) -> Array:
	var reached := {}
	var todo: Array = [s.doors.entrance.front[0]]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		if reached.has(c) or not s.road_cells.has(c): continue
		reached[c] = true
		for d in Roads.DIRS: todo.append(c+d)
	var errors: Array = []
	for id in s.doors:
		for c in s.doors[id].front:
			if not reached.has(c): errors.append("끊어진 문·주 통로: "+id)
	if reached.size()!=s.road_cells.size(): errors.append("떨어진 길")
	return errors

static func building(s: Dictionary, id: String) -> Dictionary:
	for b in s.buildings:
		if b.id==id: return b
	return {}

static func can_pay(s: Dictionary, cost: Dictionary) -> bool:
	for resource in cost:
		if int(s.resources.get(resource,0))<int(cost[resource]): return false
	return true

static func pay(s: Dictionary, cost: Dictionary, signum: int = -1) -> void:
	for resource in cost: s.resources[resource] = int(s.resources.get(resource,0))+int(cost[resource])*signum

static func preview(s: Dictionary, kind: String, origin: Vector2i, moving: String = "") -> Dictionary:
	var candidate := s.duplicate(true)
	var rule: Dictionary = s.catalog[kind]
	if moving=="":
		if s.stage<int(rule.stage): return {"ok":false,"errors":["성 단계 미해금"]}
		if not can_pay(s,rule.cost): return {"ok":false,"errors":["자원 부족"]}
		if kind in ["spikes","sticky"]:
			if not s.road_cells.has(origin) or s.water.has(origin): return {"ok":false,"errors":["마른 길 위에만 설치"]}
			for t in s.traps:
				if Vector2i(t.cell[0],t.cell[1])==origin: return {"ok":false,"errors":["함정과 겹침"]}
			candidate.traps.append({"cell":[origin.x,origin.y],"kind":kind})
			pay(candidate,rule.cost)
			return rebuild(candidate)
		if s.buildings.size()>=int(stage_rule(s).get("area_room_count",s.buildings.size()+1)):
			return {"ok":false,"errors":["성 단계 건설 수 제한"]}
		if rule.unique:
			for b in s.buildings:
				if b.kind==kind: return {"ok":false,"errors":["고유 시설: 원형 메뉴에서 이동"]}
		candidate.serial += 1
		var capacity: int = int(rule.capacity)+int(stage_rule(s).get("facility_capacity_bonus",0))
		candidate.buildings.append({"id":kind+"_"+str(candidate.serial),"kind":kind,"rect":Rect2i(origin,rule.size),"fixed":false,"capacity":capacity,"aura":rule.aura,"level":1,"preferred":"S","paid":rule.cost.duplicate()})
		pay(candidate,rule.cost)
	else:
		var found := building(candidate,moving)
		if found.is_empty() or found.fixed: return {"ok":false,"errors":["고정 시설"]}
		found.rect.position = origin
	return rebuild(candidate)

static func refund(b: Dictionary, s: Dictionary) -> Dictionary:
	# Existing game has no individual-building dismantle economy. Branch test:
	# refund half the recorded purchase + upgrade cost, never more than paid.
	var result := {}
	for resource in b.paid: result[resource] = int(b.paid[resource])/2
	return result

static func dismantle(s: Dictionary, id: String) -> Dictionary:
	var b := building(s,id)
	if b.is_empty() or b.fixed: return {"ok":false,"errors":["고정 시설"]}
	var next := s.duplicate(true)
	next.buildings = next.buildings.filter(func(row): return row.id!=id)
	pay(next,refund(b,s),1)
	return rebuild(next)

static func upgrade_cost(s: Dictionary, b: Dictionary) -> Dictionary:
	var days = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign_days.json"))
	var base: Dictionary = days.get("day_7",{}).get("facility_upgrade_cost",{"gold":90,"mana":30})
	return {"gold":int(base.get("gold",90))*int(b.level),"mana":int(base.get("mana",30))*int(b.level)}

static func upgrade(s: Dictionary, id: String) -> Dictionary:
	var b := building(s,id)
	var cap: int = int(stage_rule(s).get("facility_level_cap",2))
	if b.is_empty() or b.fixed or b.level>=cap or s.day<7: return {"ok":false,"errors":["강화 제한"]}
	var cost := upgrade_cost(s,b)
	if not can_pay(s,cost): return {"ok":false,"errors":["자원 부족"]}
	var next := s.duplicate(true)
	var row := building(next,id)
	row.level += 1; row.capacity = mini(8,row.capacity+1)
	for key in cost: row.paid[key] = int(row.paid.get(key,0))+int(cost[key])
	pay(next,cost)
	return rebuild(next)

static func stage_rule(s: Dictionary) -> Dictionary:
	for rule in s.stage_rules.values():
		if int(rule.index)==int(s.stage): return rule
	return {}

static func snapshot(s: Dictionary) -> Dictionary:
	var rows: Array = []
	for b in s.buildings:
		var row: Dictionary = b.duplicate(true)
		row.rect = [b.rect.position.x,b.rect.position.y,b.rect.size.x,b.rect.size.y]
		rows.append(row)
	return {"schema":"v130r_step2_placement_1","grade":"E","buildings":rows,"traps":s.traps,"resources":s.resources,"stage":s.stage,"day":s.day,"serial":s.serial}

static func restore(data: Variant, baseline: Dictionary) -> Dictionary:
	# Legacy v5/v6 or a campaign JSON has no branch extension: safe baseline.
	if not data is Dictionary or data.get("schema","")!="v130r_step2_placement_1": return baseline.duplicate(true)
	var s := baseline.duplicate(true)
	if not data.get("buildings") is Array: return {"ok":false,"errors":["배치 저장 형식 오류"]}
	s.buildings = []
	for b in data.buildings:
		if not b is Dictionary or not b.get("rect") is Array or b.rect.size()!=4: return {"ok":false,"errors":["건물 저장 형식 오류"]}
		for key in ["id","kind","capacity","aura","level","preferred","paid","fixed"]:
			if not b.has(key): return {"ok":false,"errors":["건물 저장 필드 누락"]}
		if b.get("kind","") not in FIXED and not s.catalog.has(b.get("kind","")): return {"ok":false,"errors":["알 수 없는 시설"]}
		var row: Dictionary = b.duplicate(true)
		row.rect = Rect2i(b.rect[0],b.rect[1],b.rect[2],b.rect[3])
		row.capacity = int(b.capacity); row.level = int(b.level); row.aura = float(b.aura)
		row.paid = integer_values(b.paid)
		if row.kind in FIXED:
			var original := building(baseline,row.kind)
			if row.rect!=original.rect or not row.fixed: return {"ok":false,"errors":["고정 시설 변경"]}
			row.socket_front = original.socket_front.duplicate(true)
		else:
			if row.rect.size!=s.catalog[row.kind].size or row.fixed: return {"ok":false,"errors":["시설 크기 오류"]}
		s.buildings.append(row)
	for key in ["stage","day","serial"]: s[key] = int(data.get(key,baseline[key]))
	s.resources = integer_values(data.get("resources",baseline.resources))
	s.traps = []
	for trap in data.get("traps",baseline.traps):
		if not trap is Dictionary or not trap.get("cell") is Array or trap.cell.size()!=2 or trap.get("kind","") not in ["spikes","sticky"]: return {"ok":false,"errors":["함정 저장 형식 오류"]}
		s.traps.append({"kind":str(trap.kind),"cell":[int(trap.cell[0]),int(trap.cell[1])]})
	return rebuild(s)

static func integer_values(data: Dictionary) -> Dictionary:
	var result := {}
	for key in data: result[key] = int(data[key])
	return result

static func save_copy(s: Dictionary) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_PATH.get_base_dir()))
	var file := FileAccess.open(SAVE_PATH+".tmp",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(s),"\t")); file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH+".tmp"),ProjectSettings.globalize_path(SAVE_PATH))

static func load_copy(baseline: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH): return baseline
	return restore(JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH)),baseline)
