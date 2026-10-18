extends RefCounted
## A* and semantic cells for the approved map. No campaign/save dependency.
const Layout = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
var layout: Dictionary
var rooms: Dictionary = {}
var astar := AStarGrid2D.new()
var cached_paths := {}
var cached_targets := {}
var cell_tags := {}
var trap_cells := {}
var route_queries := 0
var water_cuts: Array[int] = []
var lower_throne_exit := Vector2i(-1,-1)

func setup(source: Dictionary) -> void:
	layout = source.duplicate(true)
	rooms.clear(); cached_paths.clear(); cached_targets.clear(); cell_tags.clear(); trap_cells.clear()
	water_cuts.clear()
	for x in range(Buildings.dimensions(layout).x):
		if layout.water.has(Vector2i(x,0)) and (x==0 or not layout.water.has(Vector2i(x-1,0))): water_cuts.append(x)
	lower_throne_exit = Vector2i(-1,-1)
	if layout.get("grade","")=="D" and water_cuts.size()==2:
		var last_row := -1
		for c in layout.bridges:
			if c.x==water_cuts[1]: last_row = maxi(last_row,c.y)
		if last_row>=1: lower_throne_exit = Vector2i(water_cuts[1]+2,last_row-1)
	# A 5x5 recovery building with a 2.5 centre-radius otherwise covers no
	# external road at some door orientations. Its own defense cells belong to
	# the building influence as well; radius outside that apron is unchanged.
	for b in layout.buildings:
		if b.aura<=0: continue
		for c in layout.defense_points.get(b.id,[]):
			if c not in layout.influence[b.id]: layout.influence[b.id].append(c)
	astar.region = Rect2i(Vector2i.ZERO,Buildings.dimensions(layout))
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update(); astar.fill_solid_region(astar.region,true)
	for c in layout.road_cells: astar.set_point_solid(c,false)
	for t in layout.traps: trap_cells[Vector2i(t.cell[0],t.cell[1])] = t.kind
	for c in layout.road_cells:
		var adjacent := false
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if layout.water.has(c+d) and not layout.bridges.has(c+d): adjacent = true
		var auras: Array[String] = []
		for id in layout.influence:
			if c in layout.influence[id]: auras.append(id)
		cell_tags[c] = {"road":true,"bridge":layout.bridges.has(c),"water_adjacent":adjacent,
			"trap":trap_cells.get(c,""),"defense_line":line_for(c),"aura":auras}
	for b in layout.buildings:
		var p := center(b.id)
		rooms[b.id] = {"id":b.id,"display_name":Buildings.NAMES.get(b.kind,b.id),"center":[p.x,p.y],
			"facility_role":Buildings.ROLES.get(b.kind,b.kind),"type":"core" if b.kind=="throne" else "facility",
			"level":b.level,"facility_level":b.level,"hp":500,"max_hp":500,"floor":1,"exits":[]}
	for line in ["1","2","final"]:
		var key: String = "line_"+line
		rooms[key] = {"id":key,"display_name":line+" 방어선","facility_role":"","floor":1,"type":"corridor","exits":[]}
	# Legacy skills use neighbouring room IDs. Adjacency means overlapping building
	# influence or the defense line containing its door, never the whole map.
	for id in rooms:
		for other in rooms:
			if id!=other and line_for(cell(center(id)))==line_for(cell(center(other))): rooms[id].exits.append(other)

func line_for(c: Vector2i) -> String:
	if layout.get("grade","") in ["D","C"]: return "1" if c.x<10 else "2" if c.x<(32 if layout.grade=="D" else 38) else "final"
	if water_cuts.size()==1: return "1" if c.x<water_cuts[0]+2 else "final"
	if water_cuts.size()<2: return "1"
	return "1" if c.x<water_cuts[0]+2 else "2" if c.x<water_cuts[1]+2 else "final"

func cell(point: Vector2) -> Vector2i: return Vector2i(Layout.unproject(point,Buildings.dimensions(layout).x).floor())
func world(c: Vector2i) -> Vector2: return Layout.project(Vector2(c)+Vector2(.5,.5),Buildings.dimensions(layout).x)
func is_road(c: Vector2i) -> bool: return layout.road_cells.has(c)
func is_walkable(point: Vector2) -> bool: return is_road(cell(point))
func tile_cell_center(c: Vector2i) -> Vector2: return world(c)

func tags_at(c: Vector2i) -> Dictionary:
	var tags: Dictionary = cell_tags.get(c,{"road":false,"bridge":false,"water_adjacent":false,"trap":"","defense_line":line_for(c),"aura":[]}).duplicate(true)
	tags.trap = trap_cells.get(c,""); tags["cell"] = c
	return tags

func tags_for(unit: Node, target: Node = null) -> Dictionary:
	return tags_at(cell(target.global_position if is_instance_valid(target) else unit.global_position))

func nearest_cell(point: Vector2) -> Vector2i:
	var c := cell(point)
	if is_road(c): return c
	var result := Vector2i(-999,-999); var distance := INF
	for candidate in layout.road_cells:
		var d: float = world(candidate).distance_squared_to(point)
		if d<distance: distance = d; result = candidate
	return result

func clamp_to_walkable(point: Vector2) -> Vector2:
	return point if is_walkable(point) else world(nearest_cell(point))

func path_cells(a: Vector2i, b: Vector2i) -> Array:
	if not is_road(a) or not is_road(b): return []
	var key := Vector4i(a.x,a.y,b.x,b.y)
	if not cached_paths.has(key):
		route_queries += 1; cached_paths[key] = Array(astar.get_id_path(a,b))
	return cached_paths[key].duplicate()

func path_to_point(from: Vector2, to: Vector2) -> Array:
	var a := nearest_cell(from); var b := nearest_cell(to)
	var points := path_cells(a,b); var result: Array = []
	if points.is_empty(): return result
	# First reach the current cell centre before taking an orthogonal turn.
	for c in points:
		var p := world(c)
		if result.is_empty() and p.distance_to(from)<.1: continue
		result.append(p)
	if is_walkable(to) and (result.is_empty() or result[-1].distance_to(to)>.1): result.append(to)
	return result

func center(id: String) -> Vector2:
	if id.begins_with("line_"):
		for c in layout.road_cells:
			if "line_"+line_for(c)==id: return world(c)
	if layout.doors.has(id): return world(layout.doors[id].front[0])
	return world(layout.doors.entrance.front[0])

func target_point(id: String, from: Vector2, side: String = "") -> Vector2:
	# C throne's two separated final roads retain independent reachable doors.
	if not layout.doors.has(id): return center(id)
	var doors: Array = [layout.doors[id]]+layout.doors[id].get("secondary",[])
	var midpoint: bool = id=="throne" and bool(layout.get("door_goal_center",false))
	if doors.size()==1 and not midpoint: return center(id)
	var start := nearest_cell(from)
	var cache_key := id+"|"+side+"|"+str(start)
	if cached_targets.has(cache_key): return cached_targets[cache_key]
	if side!="": doors = doors.filter(func(d): return d.side==side)
	var best := center(id); var length := 2147483647
	var selected := {}
	for d in doors:
		for c in d.front:
			var path := path_cells(start,c)
			if not path.is_empty() and path.size()<length: length = path.size(); best = world(c); selected = d
	if midpoint and not selected.is_empty(): best = (world(selected.front[0])+world(selected.front[1]))/2
	cached_targets[cache_key] = best
	return best

func room_at_world(point: Vector2) -> String:
	var c := cell(point)
	for id in ["throne","vault","entrance"]:
		if c in layout.doors[id].front: return id
		for d in layout.doors[id].get("secondary",[]):
			if c in d.front: return id
	# A facility door remains its own room even where influence areas overlap.
	for id in layout.doors:
		if c in layout.doors[id].front: return id
	var tags := tags_at(c)
	if not tags.aura.is_empty(): return str(tags.aura[0])
	return "line_"+str(tags.defense_line)

func closest_room(point: Vector2) -> String: return room_at_world(point)
func exits(id: String) -> Array: return rooms.get(id,{}).get("exits",[])
func module_instance_ids() -> Array: return rooms.keys()
func is_corridor_room(id: String) -> bool: return id.begins_with("line_")
func path_between(a: String, b: String) -> Array: return [a,b] if a!=b else [a]
func room_patrol_path(id: String) -> Array: return [center(id)]

func debug_socket_cells() -> Array:
	var sockets: Array = []
	for id in layout.doors:
		var doors: Array = [layout.doors[id]]+layout.doors[id].get("secondary",[])
		for index in range(doors.size()):
			var front: Array = doors[index].front
			var suffix := "" if index==0 else "_"+str(index)
			sockets.append({"instance_id":id,"socket_id":"front"+suffix+"_a","cell":front[0],"state":"connected"})
			sockets.append({"instance_id":"line_"+line_for(front[1]),"socket_id":id+"_front"+suffix+"_b","cell":front[1],"state":"connected"})
	return sockets

func connection_pairs() -> Array:
	var pairs: Array = []
	for id in layout.doors:
		var doors: Array = [layout.doors[id]]+layout.doors[id].get("secondary",[])
		for index in range(doors.size()):
			var front: Array = doors[index].front
			var suffix := "" if index==0 else "_"+str(index)
			pairs.append({"from_instance":id,"from_socket":"front"+suffix+"_a","to_instance":"line_"+line_for(front[1]),"to_socket":id+"_front"+suffix+"_b"})
	return pairs

func resolve_site(id: String) -> String:
	if layout.doors.has(id): return id
	# Plan IDs describe sites; purchased instances retain their own serial IDs.
	var site: Dictionary = layout.get("plan_defense",{}).get(id,{})
	if site.is_empty(): return ""
	for b in layout.buildings:
		if b.kind==site.get("kind","") and b.get("plan_site_id","")==id: return b.id
		if b.kind==site.get("kind","") and b.rect==site.rect: return b.id
	return "" # An empty site must never become an enemy objective.

func goal_for(stats: Dictionary, from: Vector2, preferred: String = "") -> String:
	var actual := resolve_site(preferred)
	if actual!="": return actual
	match str(stats.get("goal_type","throne")):
		"treasure":
			for b in layout.buildings:
				if b.kind=="bait_treasure": return b.id
			return "vault"
		"facility":
			var best := "throne"; var distance := INF
			for b in layout.buildings:
				if b.fixed: continue
				var d := path_cells(nearest_cell(from),nearest_cell(center(b.id))).size()
				if d>0 and d<distance: distance = d; best = b.id
			return best
	return "throne" # heart goals map to the actual throne; no heart building here.
