extends Node

const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const CorridorTopologyBuilderScript = preload("res://scripts/dungeon_quarter/CorridorTopologyBuilder.gd")

var failures: Array[String] = []


func _ready() -> void:
	_check_all_sixteen_masks()
	_check_closed_shared_edge()
	_check_open_doorway_and_wall_caps()
	_check_hole_creates_two_closed_wall_loops()
	_check_visual_patch_is_explicit_and_non_mutating()
	_check_socket_placeholder_stays_blocked()
	_check_diagonal_point_touch_does_not_create_junction()
	_check_deterministic_order()
	_finish()


func _check_all_sixteen_masks() -> void:
	for expected_mask in range(16):
		var center := Vector2i.ZERO
		var floor_cells := {center: true}
		var open_edges: Dictionary = {}
		for side in CorridorTopologyBuilderScript.SIDES:
			if (expected_mask & int(AutoTileMaskScript.BITS[side])) == 0:
				continue
			floor_cells[center + AutoTileMaskScript.DIRS[side]] = true
			# 일부러 한 방향만 넣어 builder의 양방향 정규화도 함께 검증한다.
			open_edges[AutoTileMaskScript.edge_key(center, side)] = true
		var topology := CorridorTopologyBuilderScript.build(floor_cells, open_edges)
		_expect(topology["errors"].is_empty(), "mask %d 생성에 오류가 없어야 한다: %s" % [expected_mask, topology["errors"]])
		_expect(int(topology["mask_by_cell"].get(center, -1)) == expected_mask, "mask %d를 열린 변 그대로 계산해야 한다" % expected_mask)
		for side in CorridorTopologyBuilderScript.SIDES:
			if (expected_mask & int(AutoTileMaskScript.BITS[side])) == 0:
				continue
			var neighbor: Vector2i = center + AutoTileMaskScript.DIRS[side]
			var opposite := AutoTileMaskScript.opposite_side(side)
			_expect(
				topology["visual_open_edges"].has(AutoTileMaskScript.edge_key(neighbor, opposite)),
				"mask %d의 %s 열린 변은 반대편에도 있어야 한다" % [expected_mask, side]
			)


func _check_closed_shared_edge() -> void:
	var floor_cells := {Vector2i(0, 0): true, Vector2i(1, 0): true}
	var topology := CorridorTopologyBuilderScript.build(floor_cells, {})
	_expect(int(topology["mask_by_cell"].get(Vector2i(0, 0), -1)) == 0, "빈 open-edge 입력은 인접 바닥을 자동 개방하지 않는다")
	_expect(int(topology["mask_by_cell"].get(Vector2i(1, 0), -1)) == 0, "붙은 두 번째 칸도 닫힌 mask 0이다")
	_expect(topology["boundary_edges"].size() == 7, "붙었지만 닫힌 두 칸은 공유 벽 하나를 포함해 총 7개 벽이다")
	var seam_count := 0
	for edge_value in topology["boundary_edges"]:
		var edge: Dictionary = edge_value
		if str(edge.get("boundary_kind", "")) == "separator":
			seam_count += 1
	_expect(seam_count == 1, "닫힌 공유 변은 중복 없이 정확히 한 번만 생성한다")
	_check_closed_chain_coverage(topology, "닫힌 공유 변")


func _check_open_doorway_and_wall_caps() -> void:
	var cell := Vector2i(3, 4)
	var open_edges := {AutoTileMaskScript.edge_key(cell, "N"): true}
	var topology := CorridorTopologyBuilderScript.build({cell: true}, open_edges)
	_expect(int(topology["mask_by_cell"].get(cell, -1)) == 1, "명시한 북쪽 출입구만 mask에 반영한다")
	_expect(topology["boundary_edges"].size() == 3, "출입구 한 면을 연 단일 칸은 나머지 세 면에만 벽이 있다")
	_expect(topology["portals"].size() == 1, "바닥 밖으로 열린 변은 명시적 portal로 기록한다")
	var cap_count := 0
	for vertex_value in topology["wall_vertices"]:
		if str(vertex_value.get("kind", "")) == "cap":
			cap_count += 1
	_expect(cap_count == 2, "출입구 양옆에서 연속 벽이 정확히 두 개의 끝점을 만든다")


func _check_hole_creates_two_closed_wall_loops() -> void:
	var floor_cells: Dictionary = {}
	for y in range(3):
		for x in range(3):
			if Vector2i(x, y) != Vector2i(1, 1):
				floor_cells[Vector2i(x, y)] = true
	var open_edges := _all_adjacent_open_edges(floor_cells)
	var topology := CorridorTopologyBuilderScript.build(floor_cells, open_edges)
	_expect(topology["boundary_edges"].size() == 16, "3x3 고리에는 바깥 12면과 안쪽 4면이 있다")
	var loop_count := 0
	for chain_value in topology["wall_chains"]:
		if bool(chain_value.get("is_loop", false)):
			loop_count += 1
	_expect(loop_count == 2, "바깥 외벽과 안쪽 구멍 벽이 서로 다른 두 고리여야 한다")
	_check_closed_chain_coverage(topology, "구멍 fixture")


func _check_visual_patch_is_explicit_and_non_mutating() -> void:
	var base_floor := {Vector2i(0, -1): true, Vector2i(0, 2): true, Vector2i(1, 0): true}
	var base_open: Dictionary = {}
	var original_floor := base_floor.duplicate(true)
	var original_open := base_open.duplicate(true)
	var patch := {
		"id": "test_visual_connector",
		"cells": [Vector2i(0, 0), Vector2i(0, 1)],
		"cell_data": {"is_corridor": true, "defender_only": true},
		"external_openings": [
			{"cell": Vector2i(0, 0), "side": "N"},
			{"cell": Vector2i(0, 1), "side": "S"}
		]
	}
	var topology := CorridorTopologyBuilderScript.build(base_floor, base_open, {}, [], [patch])
	_expect(topology["errors"].is_empty(), "명시적 visual patch가 유효해야 한다: %s" % str(topology["errors"]))
	_expect(topology["visual_only_cells"].size() == 2, "visual patch는 지정한 두 칸만 추가한다")
	_expect(int(topology["mask_by_cell"].get(Vector2i(0, 0), -1)) == 5, "첫 patch 칸은 북/남만 열린다")
	_expect(int(topology["mask_by_cell"].get(Vector2i(0, 1), -1)) == 5, "둘째 patch 칸도 북/남만 열린다")
	_expect(not topology["visual_open_edges"].has(AutoTileMaskScript.edge_key(Vector2i(0, 0), "E")), "옆 바닥에 우연히 닿아도 명시하지 않은 동쪽 벽은 열지 않는다")
	_expect(base_floor == original_floor, "builder가 원본 floor dictionary를 바꾸지 않는다")
	_expect(base_open == original_open, "builder가 원본 open-edge dictionary를 바꾸지 않는다")


func _check_socket_placeholder_stays_blocked() -> void:
	var cell := Vector2i(2, 2)
	var sockets := [{"cell": cell, "side": "E", "state": "open_placeholder"}]
	var topology := CorridorTopologyBuilderScript.build({cell: true}, {}, {}, sockets)
	var placeholder_count := 0
	var placeholder_edge_id := ""
	for edge_value in topology["boundary_edges"]:
		if str(edge_value.get("state", "")) == "open_placeholder":
			placeholder_count += 1
			placeholder_edge_id = str(edge_value.get("id", ""))
	_expect(placeholder_count == 1, "open_placeholder는 통로를 열지 않고 한 면의 장식 상태로 남긴다")
	_expect(int(topology["mask_by_cell"].get(cell, -1)) == 0, "placeholder 소켓은 이동/시각 연결 mask에 포함하지 않는다")
	var structural_chain_contains_placeholder := false
	for chain_value in topology["wall_chains"]:
		if chain_value.get("edge_ids", []).has(placeholder_edge_id):
			structural_chain_contains_placeholder = true
			break
	_expect(structural_chain_contains_placeholder, "open_placeholder의 막힌 면은 연속 구조 벽 chain에 남는다")


func _check_diagonal_point_touch_does_not_create_junction() -> void:
	var topology := CorridorTopologyBuilderScript.build({
		Vector2i(0, 0): true,
		Vector2i(1, 1): true
	}, {})
	var touching_vertices: Array = []
	for vertex_value in topology["wall_vertices"]:
		var vertex: Dictionary = vertex_value
		if vertex.get("position", Vector2i.ZERO) == Vector2i(1, 1):
			touching_vertices.append(vertex)
	_expect(touching_vertices.size() == 2, "대각선으로 점만 닿는 두 방은 서로 다른 두 모서리로 분리한다")
	for vertex_value in touching_vertices:
		var vertex: Dictionary = vertex_value
		_expect(str(vertex.get("kind", "")) == "corner", "점 접촉부에 교차 분기탑 대신 방향이 맞는 corner를 사용한다")
		_expect(int(vertex.get("degree", 0)) == 2, "분리된 점 접촉 모서리는 각각 두 벽만 잇는다")
		_expect(str(vertex.get("key", "")).contains("@"), "점 접촉 분리 키가 소유 셀을 명시한다")


func _check_deterministic_order() -> void:
	var cells_a := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
	var cells_b := cells_a.duplicate()
	cells_b.reverse()
	var floor_a := _cell_set(cells_a)
	var floor_b := _cell_set(cells_b)
	var open_a := _all_adjacent_open_edges(floor_a)
	var open_b: Dictionary = {}
	var open_keys: Array = open_a.keys()
	open_keys.reverse()
	for key in open_keys:
		open_b[key] = true
	var topology_a := CorridorTopologyBuilderScript.build(floor_a, open_a)
	var topology_b := CorridorTopologyBuilderScript.build(floor_b, open_b)
	_expect(topology_a["boundary_edges"] == topology_b["boundary_edges"], "입력 Dictionary 삽입 순서와 무관하게 벽 순서가 같다")
	_expect(topology_a["wall_chains"] == topology_b["wall_chains"], "입력 순서와 무관하게 wall chain 순서가 같다")


func _all_adjacent_open_edges(floor_cells: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for cell_value in floor_cells.keys():
		var cell: Vector2i = cell_value
		for side in CorridorTopologyBuilderScript.SIDES:
			if floor_cells.has(cell + AutoTileMaskScript.DIRS[side]):
				result[AutoTileMaskScript.edge_key(cell, side)] = true
	return result


func _cell_set(cells: Array) -> Dictionary:
	var result: Dictionary = {}
	for cell in cells:
		result[cell] = true
	return result


func _check_closed_chain_coverage(topology: Dictionary, label: String) -> void:
	var expected_ids: Dictionary = {}
	for edge_value in topology["boundary_edges"]:
		if str(edge_value.get("state", "closed")) in ["closed", "open_placeholder"]:
			expected_ids[str(edge_value.get("id", ""))] = true
	var visited_ids: Dictionary = {}
	for chain_value in topology["wall_chains"]:
		for edge_id_value in chain_value.get("edge_ids", []):
			var edge_id := str(edge_id_value)
			_expect(not visited_ids.has(edge_id), "%s wall chain이 같은 벽을 두 번 포함하지 않는다: %s" % [label, edge_id])
			visited_ids[edge_id] = true
	_expect(visited_ids.size() == expected_ids.size(), "%s wall chain이 모든 닫힌 벽을 정확히 한 번 덮는다" % label)


func _finish() -> void:
	if failures.is_empty():
		print("CORRIDOR_TOPOLOGY_BUILDER_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("CORRIDOR_TOPOLOGY_BUILDER_TEST: FAIL")
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
