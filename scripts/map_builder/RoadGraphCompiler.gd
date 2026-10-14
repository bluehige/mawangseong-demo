extends RefCounted

const Mask = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")

# Partition one connected physical road into connected semantic defense zones.
# Existing zone IDs/capacities/effects survive; physical adjacency owns all
# edges, never the old hand-authored room lattice or lane coordinates.
static func compile(cells: Dictionary, aliases: Array, entrance_anchor: Vector2i = Vector2i(-1,-1)) -> Dictionary:
	var owner: Dictionary = {}
	var ordered: Array = cells.keys()
	ordered.sort_custom(func(a,b): return a.x+a.y < b.x+b.y if a.x+a.y != b.x+b.y else a.x < b.x)
	var seeds: Array = []
	for alias in aliases:
		var best: Vector2i = ordered[0]
		var best_distance := -1
		for cell: Vector2i in ordered:
			var distance := 2147483647
			for seed: Vector2i in seeds:
				distance = mini(distance, absi(cell.x-seed.x)+absi(cell.y-seed.y))
			if distance > best_distance and not seeds.has(cell):
				best_distance = distance
				best = cell
		if seeds.is_empty() and cells.has(entrance_anchor): best = entrance_anchor
		seeds.append(best)
		owner[best] = str(alias)
	var frontier := seeds.duplicate()
	var cursor := 0
	while cursor < frontier.size():
		var cell: Vector2i = frontier[cursor]
		cursor += 1
		for direction: Vector2i in Mask.DIRS.values():
			var next := cell + direction
			if cells.has(next) and not owner.has(next):
				owner[next] = owner[cell]
				frontier.append(next)
	var modules: Dictionary = {}
	var placed: Array = []
	for alias in aliases:
		var id := "map_road_%s" % alias
		modules[id] = {"id":id,"display_name":str(alias),"theme":"cave_f","module_type":"corridor","room_function":"corridor","size":[100,100],"floor_cells":[],"walk_cells":[],"blocked_cells":[],"sockets":[],"object_slots":[],"trap_cells":[]}
		placed.append({"instance_id":alias,"module_id":id,"grid_origin":[0,0],"locked":true,"legacy_room_id":alias})
	for cell: Vector2i in owner:
		var module: Dictionary = modules["map_road_%s" % owner[cell]]
		module["floor_cells"].append([cell.x,cell.y])
		module["walk_cells"].append([cell.x,cell.y])
	var connections: Array = []
	for cell: Vector2i in owner:
		for side in ["E","S"]:
			var next: Vector2i = cell + Mask.DIRS[side]
			if not owner.has(next) or owner[next] == owner[cell]: continue
			var a := "edge_%d_%d_%s" % [cell.x,cell.y,side]
			var b := a + "_reverse"
			modules["map_road_%s" % owner[cell]]["sockets"].append({"id":a,"cell":[cell.x,cell.y],"side":side})
			modules["map_road_%s" % owner[next]]["sockets"].append({"id":b,"cell":[next.x,next.y],"side":Mask.opposite_side(side)})
			connections.append({"from":"%s:%s" % [owner[cell],a],"to":"%s:%s" % [owner[next],b]})
	return {"owner":owner,"modules":modules,"placed":placed,"connections":connections}

static func room_path(connections: Array, start: String, goal: String) -> Array:
	var adjacency: Dictionary = {}
	for connection in connections:
		var a := str(connection["from"]).get_slice(":",0)
		var b := str(connection["to"]).get_slice(":",0)
		if not adjacency.has(a): adjacency[a] = []
		if not adjacency.has(b): adjacency[b] = []
		if not adjacency[a].has(b): adjacency[a].append(b)
		if not adjacency[b].has(a): adjacency[b].append(a)
	var frontier: Array = [start]
	var parents: Dictionary = {start:""}
	var cursor := 0
	while cursor < frontier.size():
		var current: String = frontier[cursor]
		cursor += 1
		if current == goal:
			var path: Array = [goal]
			while current != start:
				current = parents[current]
				path.push_front(current)
			return path
		for next in adjacency.get(current,[]):
			if not parents.has(next):
				parents[next] = current
				frontier.append(next)
	return []
