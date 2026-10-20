extends RefCounted
class_name AutoRoadBuilder

const DIRS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const INVALID := Vector2i(-99999, -99999)

# A state is the NW anchor of a clear 2x2 footprint, not a one-cell path
# thickened afterwards. Turns and door approaches therefore cannot pinch.
# Buildings: [{id, rect:Rect2i}]. Doors: [{id, building_id, anchor:Vector2i}].
# The first two doors are entrance/throne. Inputs are never modified.
static func build(plot: Dictionary, buildings: Array, doors: Array) -> Dictionary:
	var errors: Array[String] = []
	var occupied: Dictionary = {}
	for index in range(buildings.size()):
		var building: Dictionary = buildings[index]
		var rect: Rect2i = building["rect"]
		if not preload("res://scripts/map_builder/PlotMask.gd").contains_rect(plot, rect):
			errors.append("building outside plot: %s" % building["id"])
		for prior in buildings.slice(0, index):
			if rect.grow(1).intersects(prior["rect"]):
				errors.append("buildings overlap or lack one-cell spacing: %s/%s" % [building["id"], prior["id"]])
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				occupied[Vector2i(x, y)] = true
	# Attached outside approaches reserve their width-2 landing cells.
	for cell in plot.get("blocked_cells",{}): occupied[cell] = true
	var clear: Dictionary = {}
	for cell: Vector2i in plot.get("cells", {}):
		var valid := true
		for offset in footprint_offsets():
			if not plot["cells"].has(cell + offset) or occupied.has(cell + offset):
				valid = false
		if valid:
			clear[cell] = true
	if doors.size() < 2:
		errors.append("entrance and throne doors required")
	var seen: Dictionary = {}
	for door in doors:
		if seen.has(door["id"]):
			errors.append("duplicate door: %s" % door["id"])
		seen[door["id"]] = true
		if not clear.has(door["anchor"]):
			errors.append("blocked door: %s" % door["id"])
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "road_cells": {}, "paths": []}
	var network: Dictionary = {}
	var roads: Dictionary = {}
	var paths: Array = []
	var pending := doors.slice(2).duplicate(true)
	var main := _search(doors[0]["anchor"], {doors[1]["anchor"]: true}, clear, {}, occupied)
	if main.is_empty():
		return {"ok": false, "errors": ["entrance cannot reach throne with width 2"], "road_cells": {}, "paths": []}
	_add_path(main, network, roads)
	paths.append({"door_id": doors[0]["id"], "kind": "main", "anchors": main})
	while not pending.is_empty():
		# Nearest door first, stable tie-breaking by input order.
		var best_index := 0
		var best_distance := 2147483647
		for index in range(pending.size()):
			for anchor: Vector2i in network:
				var distance: int = absi(anchor.x - pending[index]["anchor"].x) + absi(anchor.y - pending[index]["anchor"].y)
				if distance < best_distance:
					best_distance = distance
					best_index = index
		var door: Dictionary = pending.pop_at(best_index)
		var branch := _search(door["anchor"], network, clear, network, occupied)
		if branch.is_empty():
			return {"ok": false, "errors": ["door cannot reach road: %s" % door["id"]], "road_cells": {}, "paths": []}
		_add_path(branch, network, roads)
		paths.append({"door_id": door["id"], "kind": "branch", "anchors": branch})
	return {"ok": true, "errors": [], "road_cells": roads, "paths": paths, "anchor_network": network, "doors": doors.duplicate(true)}

static func footprint_offsets() -> Array[Vector2i]:
	return [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]

static func _add_path(path: Array, network: Dictionary, roads: Dictionary) -> void:
	for anchor: Vector2i in path:
		network[anchor] = true
		for offset in footprint_offsets():
			roads[anchor + offset] = true

static func _search(start: Vector2i, goals: Dictionary, clear: Dictionary, reuse: Dictionary, occupied: Dictionary) -> Array:
	# A* state includes heading so turn costs cannot discard a better arrival.
	var initial := Vector3i(start.x, start.y, -1)
	var frontier: Array = [initial]
	var costs: Dictionary = {initial: 0}
	var parents: Dictionary = {}
	var scores: Dictionary = {initial: _heuristic(start, goals)}
	while not frontier.is_empty():
		var best := 0
		for index in range(1, frontier.size()):
			if int(scores[frontier[index]]) < int(scores[frontier[best]]):
				best = index
		var current: Vector3i = frontier.pop_at(best)
		var cell := Vector2i(current.x, current.y)
		if goals.has(cell):
			var path: Array = [cell]
			while parents.has(current):
				current = parents[current]
				path.push_front(Vector2i(current.x, current.y))
			return path
		for direction in range(4):
			var next: Vector2i = cell + DIRS[direction]
			if not clear.has(next):
				continue
			var state := Vector3i(next.x, next.y, direction)
			var cost: int = int(costs[current]) + (8 if reuse.has(next) else 10)
			if current.z >= 0 and current.z != direction:
				cost += 2
			for offset in [Vector2i(-1, 0), Vector2i(2, 0), Vector2i(0, -1), Vector2i(0, 2)]:
				if occupied.has(next + offset):
					cost += 1
			if cost < int(costs.get(state, 2147483647)):
				costs[state] = cost
				parents[state] = current
				scores[state] = cost + _heuristic(next, goals)
				if not frontier.has(state):
					frontier.append(state)
	return []

static func _heuristic(cell: Vector2i, goals: Dictionary) -> int:
	var distance := 2147483647
	for goal: Vector2i in goals:
		distance = mini(distance, absi(cell.x - goal.x) + absi(cell.y - goal.y))
	return distance * 8

# Defense-layout routing uses the same clear 2x2 anchor representation. A run
# must contain at least three anchor cells before a bend or terminal connection
# (two moves; rasterized width-two run is at least four floor cells long).
# Keep legacy campaigns on their existing routing contract.
static func defense_search(start: Vector2i, goals: Dictionary, clear: Dictionary, reuse: Dictionary, occupied: Dictionary) -> Array:
	if goals.has(start): return [start]
	var initial := Vector4i(start.x,start.y,-1,0)
	var heap: Array = []
	_heap_push(heap, [0,initial,0])
	var costs: Dictionary = {initial:0}
	var parents: Dictionary = {}
	while not heap.is_empty():
		var item: Array = _heap_pop(heap)
		var current: Vector4i = item[1]
		if int(item[2]) != int(costs[current]): continue
		var cell := Vector2i(current.x,current.y)
		if goals.has(cell) and current.w >= 2:
			var path: Array = [cell]
			while parents.has(current):
				current = parents[current]
				path.push_front(Vector2i(current.x,current.y))
			return path
		for direction in range(4):
			if current.z >= 0 and direction != current.z:
				if current.w < 2 or direction == (current.z+2)%4: continue
			var next: Vector2i = cell+DIRS[direction]
			if not clear.has(next): continue
			var run := mini(2,current.w+1) if direction == current.z else 1
			var state := Vector4i(next.x,next.y,direction,run)
			var cost: int = costs[current]+(6 if reuse.has(next) else 10)
			if current.z >= 0 and direction != current.z: cost += 60
			for offset in [Vector2i(-1,0),Vector2i(2,0),Vector2i(0,-1),Vector2i(0,2)]:
				if occupied.has(next+offset): cost += 4
			if cost >= int(costs.get(state,2147483647)): continue
			costs[state] = cost
			parents[state] = current
			_heap_push(heap,[cost+_heuristic(next,goals)*3/4,state,cost])
	return []

static func _heap_push(heap: Array, item: Array) -> void:
	heap.append(item)
	var index := heap.size()-1
	while index > 0:
		var parent := (index-1)/2
		if heap[parent][0] <= item[0]: break
		heap[index] = heap[parent]
		index = parent
	heap[index] = item

static func _heap_pop(heap: Array) -> Array:
	var result: Array = heap[0]
	var tail: Array = heap.pop_back()
	if heap.is_empty(): return result
	var index := 0
	while index*2+1 < heap.size():
		var child := index*2+1
		if child+1 < heap.size() and heap[child+1][0] < heap[child][0]: child += 1
		if tail[0] <= heap[child][0]: break
		heap[index] = heap[child]
		index = child
	heap[index] = tail
	return result
