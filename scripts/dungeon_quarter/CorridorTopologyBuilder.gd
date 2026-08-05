extends RefCounted
class_name CorridorTopologyBuilder

const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")

const SIDES := ["N", "E", "S", "W"]
const VERTEX_OFFSETS := {
	"N": [Vector2i(0, 0), Vector2i(1, 0)],
	"E": [Vector2i(1, 0), Vector2i(1, 1)],
	"S": [Vector2i(1, 1), Vector2i(0, 1)],
	"W": [Vector2i(0, 1), Vector2i(0, 0)]
}


## 전투 이동용 ModuleGraph를 바꾸지 않고, 화면에 그릴 통로 바닥과 연속 외벽만 만든다.
## visual_patches 형식:
## {
##   "id": String,
##   "cells": Array[Vector2i],
##   "cell_data": Dictionary,
##   "external_openings": [{"cell": Vector2i, "side": "N|E|S|W"}]
## }
## 패치 안에서 직교로 맞닿은 칸은 자동 연결하지만, 기존 맵과의 출입구는 반드시 명시한다.
static func build(
	base_floor_cells: Dictionary,
	base_open_edges: Dictionary,
	base_cell_data: Dictionary = {},
	sockets: Array = [],
	visual_patches: Array = []
) -> Dictionary:
	var floor_cells := base_floor_cells.duplicate(true)
	var cell_data := base_cell_data.duplicate(true)
	var open_edges := _normalize_open_edges(floor_cells, base_open_edges)
	var visual_only_cells: Dictionary = {}
	var errors: Array[String] = []

	_apply_visual_patches(
		floor_cells,
		cell_data,
		open_edges,
		visual_only_cells,
		visual_patches,
		errors
	)
	# 패치가 추가한 칸과 출입구까지 포함해 방향 쌍을 다시 정규화한다.
	open_edges = _normalize_open_edges(floor_cells, open_edges)

	var mask_by_cell := _build_strict_masks(floor_cells, open_edges)
	var socket_states := _socket_states_by_edge(sockets)
	var boundary_edges := _build_boundary_edges(
		floor_cells,
		open_edges,
		cell_data,
		socket_states
	)
	var wall_graph := _build_wall_graph(boundary_edges)
	var portals := _build_portals(floor_cells, open_edges)

	return {
		"visual_floor_set": floor_cells,
		"visual_open_edges": open_edges,
		"visual_only_cells": visual_only_cells,
		"cell_data": cell_data,
		"mask_by_cell": mask_by_cell,
		"boundary_edges": wall_graph["boundary_edges"],
		"wall_vertices": wall_graph["wall_vertices"],
		"wall_chains": wall_graph["wall_chains"],
		"wall_corners": wall_graph["wall_corners"],
		"portals": portals,
		"errors": errors
	}


static func _apply_visual_patches(
	floor_cells: Dictionary,
	cell_data: Dictionary,
	open_edges: Dictionary,
	visual_only_cells: Dictionary,
	visual_patches: Array,
	errors: Array[String]
) -> void:
	for patch_value in visual_patches:
		if not patch_value is Dictionary:
			errors.append("visual patch must be a Dictionary")
			continue
		var patch: Dictionary = patch_value
		var patch_id := str(patch.get("id", "visual_patch"))
		var patch_cells: Dictionary = {}
		for cell_value in patch.get("cells", []):
			if not cell_value is Vector2i:
				errors.append("%s contains a non-Vector2i cell" % patch_id)
				continue
			var cell: Vector2i = cell_value
			patch_cells[cell] = true
			floor_cells[cell] = true
			var data: Dictionary = patch.get("cell_data", {}).duplicate(true)
			data["visual_only"] = true
			data["walkable"] = false
			if not data.has("cell_type"):
				data["cell_type"] = "floor"
			cell_data[cell] = data
			visual_only_cells[cell] = data.duplicate(true)

		# 패치 내부만 자동 개방한다. 기존 방과 우연히 맞닿은 변은 열지 않는다.
		for cell_value in patch_cells.keys():
			var cell: Vector2i = cell_value
			for side in SIDES:
				if patch_cells.has(cell + AutoTileMaskScript.DIRS[side]):
					_add_open_edge(open_edges, cell, side)

		for opening_value in patch.get("external_openings", []):
			if not opening_value is Dictionary:
				errors.append("%s contains an invalid external opening" % patch_id)
				continue
			var opening: Dictionary = opening_value
			var opening_cell = opening.get("cell", null)
			var side := str(opening.get("side", ""))
			if not opening_cell is Vector2i or not SIDES.has(side):
				errors.append("%s contains an invalid external opening cell or side" % patch_id)
				continue
			if not patch_cells.has(opening_cell):
				errors.append("%s external opening is not on a patch cell: %s" % [patch_id, opening_cell])
				continue
			var neighbor: Vector2i = opening_cell + AutoTileMaskScript.DIRS[side]
			if not floor_cells.has(neighbor):
				errors.append("%s external opening does not meet a floor cell: %s:%s" % [patch_id, opening_cell, side])
				continue
			_add_open_edge(open_edges, opening_cell, side)


static func _normalize_open_edges(floor_cells: Dictionary, source: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for cell_value in _sorted_cells(floor_cells):
		var cell: Vector2i = cell_value
		for side in SIDES:
			var neighbor: Vector2i = cell + AutoTileMaskScript.DIRS[side]
			var opposite := AutoTileMaskScript.opposite_side(side)
			var direct_key := AutoTileMaskScript.edge_key(cell, side)
			var reverse_key := AutoTileMaskScript.edge_key(neighbor, opposite)
			if bool(source.get(direct_key, false)) or bool(source.get(reverse_key, false)):
				_add_open_edge(normalized, cell, side)
	return normalized


static func _build_strict_masks(floor_cells: Dictionary, open_edges: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for cell_value in _sorted_cells(floor_cells):
		var cell: Vector2i = cell_value
		var mask := 0
		for side in SIDES:
			if open_edges.has(AutoTileMaskScript.edge_key(cell, side)):
				mask |= int(AutoTileMaskScript.BITS[side])
		result[cell] = mask
	return result


static func _socket_states_by_edge(sockets: Array) -> Dictionary:
	var result: Dictionary = {}
	for socket_value in sockets:
		if not socket_value is Dictionary:
			continue
		var socket: Dictionary = socket_value
		var cell = socket.get("cell", socket.get("global_cell", null))
		var side := str(socket.get("side", ""))
		if not cell is Vector2i or not SIDES.has(side):
			continue
		var state := str(socket.get("state", "closed"))
		result[AutoTileMaskScript.edge_key(cell, side)] = state
		var neighbor: Vector2i = cell + AutoTileMaskScript.DIRS[side]
		var opposite := AutoTileMaskScript.opposite_side(side)
		var reverse_key := AutoTileMaskScript.edge_key(neighbor, opposite)
		if not result.has(reverse_key) or state == "open_placeholder":
			result[reverse_key] = state
	return result


static func _build_boundary_edges(
	floor_cells: Dictionary,
	open_edges: Dictionary,
	cell_data: Dictionary,
	socket_states: Dictionary
) -> Array:
	var result: Array = []
	var seen_physical_edges: Dictionary = {}
	for cell_value in _sorted_cells(floor_cells):
		var cell: Vector2i = cell_value
		for side in SIDES:
			if open_edges.has(AutoTileMaskScript.edge_key(cell, side)):
				continue
			var neighbor: Vector2i = cell + AutoTileMaskScript.DIRS[side]
			# 두 바닥 사이의 닫힌 벽은 N/W 쪽 칸이 소유하게 고정한다.
			# 같은 물리 벽이 E/S와 W/N 두 장으로 생기는 것을 막고 기존 원근 방향도 보존한다.
			if floor_cells.has(neighbor) and not side in ["N", "W"]:
				continue
			var vertices := _edge_vertices(cell, side)
			var edge_id := _physical_edge_id(vertices[0], vertices[1])
			if seen_physical_edges.has(edge_id):
				continue
			seen_physical_edges[edge_id] = true
			var state := _edge_state(cell, side, socket_states)
			var current_data: Dictionary = cell_data.get(cell, {})
			var neighbor_data: Dictionary = cell_data.get(neighbor, {})
			result.append({
				"id": edge_id,
				"cell": cell,
				"side": side,
				"neighbor": neighbor,
				"state": state,
				"boundary_kind": "separator" if floor_cells.has(neighbor) else "outer",
				"layer": _wall_render_layer(side),
				"start_vertex": vertices[0],
				"end_vertex": vertices[1],
				"start_key": _vertex_key(vertices[0]),
				"end_key": _vertex_key(vertices[1]),
				"room_id": str(current_data.get("room_id", "")),
				"neighbor_room_id": str(neighbor_data.get("room_id", "")),
				"is_corridor": bool(current_data.get("is_corridor", false)),
				"neighbor_is_corridor": bool(neighbor_data.get("is_corridor", false)),
				"join_start": false,
				"join_end": false
			})
	result.sort_custom(_edge_record_less)
	return result


static func _build_wall_graph(boundary_edges: Array) -> Dictionary:
	# 서로 대각선으로 점 하나만 닿는 두 외곽은 물리적으로 연결된 분기가 아니다.
	# 같은 격자 정점을 공유하더라도 소유 바닥별 가상 정점으로 먼저 분리한다.
	_split_diagonal_point_touch_vertices(boundary_edges)
	var incident_by_vertex: Dictionary = {}
	var edge_by_id: Dictionary = {}
	for edge_value in boundary_edges:
		var edge: Dictionary = edge_value
		if not _is_structural_boundary_state(str(edge.get("state", "closed"))):
			continue
		var edge_id := str(edge.get("id", ""))
		edge_by_id[edge_id] = edge
		for key in [str(edge.get("start_key", "")), str(edge.get("end_key", ""))]:
			if not incident_by_vertex.has(key):
				incident_by_vertex[key] = []
			incident_by_vertex[key].append(edge_id)

	for key in incident_by_vertex.keys():
		incident_by_vertex[key].sort()

	var vertices: Array = []
	var corners: Array = []
	var vertex_keys: Array = incident_by_vertex.keys()
	vertex_keys.sort()
	for key_value in vertex_keys:
		var key := str(key_value)
		var edge_ids: Array = incident_by_vertex[key]
		var kind := _vertex_join_kind(key, edge_ids, edge_by_id)
		var corner_key := _corner_key(key, edge_ids, edge_by_id) if kind == "corner" else ""
		var incident_directions := _vertex_direction_names(key, edge_ids, edge_by_id)
		var vertex_record := {
			"key": key,
			"position": _vertex_from_key(key),
			"edge_ids": edge_ids.duplicate(),
			"degree": edge_ids.size(),
			"kind": kind,
			"corner_key": corner_key,
			"incident_directions": incident_directions,
			"orientation_key": _vertex_orientation_key(kind, corner_key, incident_directions)
		}
		vertices.append(vertex_record)
		if corner_key != "":
			corners.append(vertex_record.duplicate(true))

	for index in range(boundary_edges.size()):
		var edge: Dictionary = boundary_edges[index]
		if _is_structural_boundary_state(str(edge.get("state", "closed"))):
			edge["join_start"] = int(incident_by_vertex.get(str(edge["start_key"]), []).size()) > 1
			edge["join_end"] = int(incident_by_vertex.get(str(edge["end_key"]), []).size()) > 1
		boundary_edges[index] = edge

	return {
		"boundary_edges": boundary_edges,
		"wall_vertices": vertices,
		"wall_chains": _build_wall_chains(incident_by_vertex, edge_by_id),
		"wall_corners": corners
	}


static func _split_diagonal_point_touch_vertices(boundary_edges: Array) -> void:
	var endpoint_refs_by_key: Dictionary = {}
	for index in range(boundary_edges.size()):
		var edge_value = boundary_edges[index]
		if not edge_value is Dictionary:
			continue
		var edge: Dictionary = edge_value
		if not _is_structural_boundary_state(str(edge.get("state", "closed"))):
			continue
		for endpoint in ["start", "end"]:
			var key := str(edge.get("%s_key" % endpoint, ""))
			if key == "":
				continue
			if not endpoint_refs_by_key.has(key):
				endpoint_refs_by_key[key] = []
			endpoint_refs_by_key[key].append({"index": index, "endpoint": endpoint})

	for key_value in endpoint_refs_by_key.keys():
		var key := str(key_value)
		var refs: Array = endpoint_refs_by_key[key_value]
		if refs.size() != 4:
			continue
		var refs_by_owner_cell: Dictionary = {}
		var all_outer := true
		for ref_value in refs:
			var ref: Dictionary = ref_value
			var edge: Dictionary = boundary_edges[int(ref["index"])]
			if str(edge.get("boundary_kind", "")) != "outer":
				all_outer = false
				break
			var owner_cell: Vector2i = edge.get("cell", Vector2i.ZERO)
			var owner_key := _vertex_key(owner_cell)
			if not refs_by_owner_cell.has(owner_key):
				refs_by_owner_cell[owner_key] = []
			refs_by_owner_cell[owner_key].append(ref)
		if not all_outer or refs_by_owner_cell.size() != 2:
			continue
		var owner_keys: Array = refs_by_owner_cell.keys()
		var first_cell := _vertex_from_key(str(owner_keys[0]))
		var second_cell := _vertex_from_key(str(owner_keys[1]))
		var delta := (first_cell - second_cell).abs()
		if delta != Vector2i.ONE:
			continue
		if (
			(refs_by_owner_cell[owner_keys[0]] as Array).size() != 2
			or (refs_by_owner_cell[owner_keys[1]] as Array).size() != 2
		):
			continue
		for owner_key_value in owner_keys:
			var owner_key := str(owner_key_value)
			var split_key := "%s@%s" % [key, owner_key]
			for ref_value in refs_by_owner_cell[owner_key_value]:
				var ref: Dictionary = ref_value
				var edge_index := int(ref["index"])
				var edge: Dictionary = boundary_edges[edge_index]
				edge["%s_key" % str(ref["endpoint"])] = split_key
				boundary_edges[edge_index] = edge


static func _is_structural_boundary_state(state: String) -> bool:
	# open_placeholder는 통로가 열린 상태가 아니라, 닫힌 벽 위에 건설 표식만 보이는 상태다.
	return state in ["closed", "open_placeholder"]


static func _build_wall_chains(incident_by_vertex: Dictionary, edge_by_id: Dictionary) -> Array:
	var chains: Array = []
	var visited: Dictionary = {}
	var vertex_keys: Array = incident_by_vertex.keys()
	vertex_keys.sort()

	# 끝점과 분기점에서 먼저 걸으면 직선/코너 구간이 안정적으로 분리된다.
	for vertex_key_value in vertex_keys:
		var vertex_key := str(vertex_key_value)
		var incident: Array = incident_by_vertex[vertex_key]
		if incident.size() == 2:
			continue
		for edge_id_value in incident:
			var edge_id := str(edge_id_value)
			if visited.has(edge_id):
				continue
			chains.append(_walk_wall_chain(vertex_key, edge_id, incident_by_vertex, edge_by_id, visited, false))

	# 남은 것은 닫힌 고리다. 가장 작은 edge id에서 시작해 결과 순서를 고정한다.
	var edge_ids: Array = edge_by_id.keys()
	edge_ids.sort()
	for edge_id_value in edge_ids:
		var edge_id := str(edge_id_value)
		if visited.has(edge_id):
			continue
		var edge: Dictionary = edge_by_id[edge_id]
		var edge_start_key := str(edge.get("start_key", ""))
		var edge_end_key := str(edge.get("end_key", ""))
		var start_key := edge_start_key if edge_start_key < edge_end_key else edge_end_key
		chains.append(_walk_wall_chain(start_key, edge_id, incident_by_vertex, edge_by_id, visited, true))
	return chains


static func _walk_wall_chain(
	start_vertex_key: String,
	first_edge_id: String,
	incident_by_vertex: Dictionary,
	edge_by_id: Dictionary,
	visited: Dictionary,
	loop_hint: bool
) -> Dictionary:
	var edge_ids: Array[String] = []
	var current_vertex_key := start_vertex_key
	var current_edge_id := first_edge_id
	var end_vertex_key := start_vertex_key
	while current_edge_id != "" and not visited.has(current_edge_id):
		visited[current_edge_id] = true
		edge_ids.append(current_edge_id)
		var edge: Dictionary = edge_by_id[current_edge_id]
		var next_vertex_key := (
			str(edge.get("end_key", ""))
			if str(edge.get("start_key", "")) == current_vertex_key
			else str(edge.get("start_key", ""))
		)
		end_vertex_key = next_vertex_key
		var next_incident: Array = incident_by_vertex.get(next_vertex_key, [])
		if next_incident.size() != 2:
			break
		var candidate := ""
		for candidate_value in next_incident:
			var candidate_id := str(candidate_value)
			if candidate_id != current_edge_id and not visited.has(candidate_id):
				candidate = candidate_id
				break
		if candidate == "":
			break
		current_vertex_key = next_vertex_key
		current_edge_id = candidate
	return {
		"edge_ids": edge_ids,
		"start_vertex_key": start_vertex_key,
		"end_vertex_key": end_vertex_key,
		"is_loop": loop_hint and end_vertex_key == start_vertex_key
	}


static func _build_portals(floor_cells: Dictionary, open_edges: Dictionary) -> Array:
	var result: Array = []
	for cell_value in _sorted_cells(floor_cells):
		var cell: Vector2i = cell_value
		for side in SIDES:
			if not open_edges.has(AutoTileMaskScript.edge_key(cell, side)):
				continue
			var neighbor: Vector2i = cell + AutoTileMaskScript.DIRS[side]
			if floor_cells.has(neighbor):
				continue
			result.append({"cell": cell, "side": side, "neighbor": neighbor})
	return result


static func _vertex_join_kind(vertex_key: String, edge_ids: Array, edge_by_id: Dictionary) -> String:
	match edge_ids.size():
		0:
			return "orphan"
		1:
			return "cap"
		2:
			var direction_a := _edge_direction_from_vertex(vertex_key, edge_by_id[str(edge_ids[0])])
			var direction_b := _edge_direction_from_vertex(vertex_key, edge_by_id[str(edge_ids[1])])
			return "straight" if direction_a + direction_b == Vector2i.ZERO else "corner"
		3:
			return "junction"
	# X 교차 자산으로 topology 오류를 덮지 않는다. 대각 점 접촉은 앞 단계에서 분리되고,
	# 실제 4방향 교차가 남으면 시각 정점 없이 구조 문제로 드러나게 한다.
	return "cross"


static func _vertex_direction_names(vertex_key: String, edge_ids: Array, edge_by_id: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for edge_id_value in edge_ids:
		var edge: Dictionary = edge_by_id.get(str(edge_id_value), {})
		if edge.is_empty():
			continue
		var direction_name := _direction_name(_edge_direction_from_vertex(vertex_key, edge))
		if direction_name != "" and not result.has(direction_name):
			result.append(direction_name)
	result.sort_custom(func(a, b) -> bool: return SIDES.find(a) < SIDES.find(b))
	return result


static func _vertex_orientation_key(kind: String, corner_key: String, directions: Array[String]) -> String:
	if kind == "corner":
		return corner_key
	if kind == "cap":
		return directions[0] if directions.size() == 1 else ""
	if kind == "junction" and directions.size() == 3:
		return "".join(directions)
	return ""


static func _corner_key(vertex_key: String, edge_ids: Array, edge_by_id: Dictionary) -> String:
	var direction_names: Array[String] = []
	for edge_id_value in edge_ids:
		var direction := _edge_direction_from_vertex(vertex_key, edge_by_id[str(edge_id_value)])
		var name := _direction_name(direction)
		if name != "":
			direction_names.append(name)
	for key in ["NE", "ES", "SW", "WN"]:
		if direction_names.has(key.substr(0, 1)) and direction_names.has(key.substr(1, 1)):
			return key
	return ""


static func _edge_direction_from_vertex(vertex_key: String, edge: Dictionary) -> Vector2i:
	var origin := _vertex_from_key(vertex_key)
	var other: Vector2i = (
		edge.get("end_vertex", Vector2i.ZERO)
		if str(edge.get("start_key", "")) == vertex_key
		else edge.get("start_vertex", Vector2i.ZERO)
	)
	return other - origin


static func _direction_name(direction: Vector2i) -> String:
	if direction == Vector2i(0, -1):
		return "N"
	if direction == Vector2i(1, 0):
		return "E"
	if direction == Vector2i(0, 1):
		return "S"
	if direction == Vector2i(-1, 0):
		return "W"
	return ""


static func _edge_state(cell: Vector2i, side: String, socket_states: Dictionary) -> String:
	var direct_key := AutoTileMaskScript.edge_key(cell, side)
	if socket_states.has(direct_key):
		var direct_state := str(socket_states[direct_key])
		return "open_placeholder" if direct_state == "open_placeholder" else "closed"
	var neighbor: Vector2i = cell + AutoTileMaskScript.DIRS[side]
	var reverse_key := AutoTileMaskScript.edge_key(neighbor, AutoTileMaskScript.opposite_side(side))
	var reverse_state := str(socket_states.get(reverse_key, "closed"))
	return "open_placeholder" if reverse_state == "open_placeholder" else "closed"


static func _edge_vertices(cell: Vector2i, side: String) -> Array:
	var offsets: Array = VERTEX_OFFSETS[side]
	return [cell + offsets[0], cell + offsets[1]]


static func _physical_edge_id(start: Vector2i, end: Vector2i) -> String:
	var start_key := _vertex_key(start)
	var end_key := _vertex_key(end)
	return "%s|%s" % ([start_key, end_key] if start_key < end_key else [end_key, start_key])


static func _vertex_key(vertex: Vector2i) -> String:
	return "%d,%d" % [vertex.x, vertex.y]


static func _vertex_from_key(key: String) -> Vector2i:
	var base_key := key.split("@")[0]
	var parts := base_key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


static func _wall_render_layer(side: String) -> String:
	return "wall_front" if side in ["E", "S"] else "wall_back"


static func _add_open_edge(open_edges: Dictionary, cell: Vector2i, side: String) -> void:
	if not SIDES.has(side):
		return
	open_edges[AutoTileMaskScript.edge_key(cell, side)] = true
	var neighbor: Vector2i = cell + AutoTileMaskScript.DIRS[side]
	var opposite := AutoTileMaskScript.opposite_side(side)
	open_edges[AutoTileMaskScript.edge_key(neighbor, opposite)] = true


static func _sorted_cells(cell_set: Dictionary) -> Array:
	var cells: Array = cell_set.keys()
	cells.sort_custom(func(a, b) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return cells


static func _edge_record_less(a: Dictionary, b: Dictionary) -> bool:
	var cell_a: Vector2i = a.get("cell", Vector2i.ZERO)
	var cell_b: Vector2i = b.get("cell", Vector2i.ZERO)
	if cell_a.y != cell_b.y:
		return cell_a.y < cell_b.y
	if cell_a.x != cell_b.x:
		return cell_a.x < cell_b.x
	return SIDES.find(str(a.get("side", ""))) < SIDES.find(str(b.get("side", "")))
