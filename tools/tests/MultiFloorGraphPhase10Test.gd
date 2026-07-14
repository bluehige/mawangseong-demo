extends Node

const MultiFloorScript = preload("res://scripts/systems/multifloor/MultiFloorGraphService.gd")
const RoomGraphScript = preload("res://scripts/map/RoomGraph.gd")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_graph_and_paths()
	_test_transition_queue()
	_test_restore_and_unlock()
	if failed:
		print("MULTI_FLOOR_GRAPH_PHASE10_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("MULTI_FLOOR_GRAPH_PHASE10_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_graph_and_paths() -> void:
	_expect(GameRootScript != null, "GameRoot DAY 16 상층 해금 연동 parse")
	var before := JSON.stringify(DataRegistry.rooms)
	var upper := MultiFloorScript.fixture_upper_rooms()
	var graph := MultiFloorScript.build_graph(DataRegistry.rooms, upper)
	_expect(bool(graph.ok) and graph.floors["2F"].size() == 2 and graph.stairs.size() == 1, "상층 최소 2방·단일 계단 fixture")
	_expect(JSON.stringify(DataRegistry.rooms) == before, "기존 1층 방 데이터 무변경")
	var original = RoomGraphScript.new()
	original.setup(DataRegistry.rooms)
	var original_path: Array = original.path_between("entrance", "throne")
	var multi_path := MultiFloorScript.path_between(graph, "1F", "entrance", "1F", "throne")
	_expect(_room_ids(multi_path) == original_path, "기존 1층 왕좌 경로 보존")
	var cross_path := MultiFloorScript.path_between(graph, "1F", "entrance", "2F", "upper_fixture_goal")
	_expect(cross_path.size() >= 4 and cross_path.any(func(node): return node.floor_id == "2F" and node.room_id == "upper_stair_landing"), "계단 endpoint를 거친 층간 경로")
	var upper_objective := MultiFloorScript.objective_path(graph, "1F", "entrance", "2F")
	var throne_objective := MultiFloorScript.objective_path(graph, "1F", "entrance", "1F")
	_expect(not upper_objective.is_empty() and str(upper_objective[-1].room_id) == "upper_fixture_goal", "2층 목표 path")
	_expect(not throne_objective.is_empty() and str(throne_objective[-1].room_id) == "throne", "1층 왕좌 목표 path")


func _test_transition_queue() -> void:
	var graph := MultiFloorScript.build_graph(DataRegistry.rooms, MultiFloorScript.fixture_upper_rooms())
	var runtime := MultiFloorScript.new_runtime()
	runtime = MultiFloorScript.register_entity(runtime, "monster_a", "monster", "1F", "spike_corridor")
	runtime = MultiFloorScript.register_entity(runtime, "enemy_a", "enemy", "1F", "spike_corridor")
	runtime = MultiFloorScript.register_entity(runtime, "enemy_b", "enemy", "1F", "spike_corridor")
	var first := MultiFloorScript.request_transition(runtime, graph, "monster_a", "2F")
	var second := MultiFloorScript.request_transition(first.runtime, graph, "enemy_a", "2F")
	var overflow := MultiFloorScript.request_transition(second.runtime, graph, "enemy_b", "2F")
	_expect(bool(first.ok) and bool(second.ok) and not bool(overflow.ok), "같은 방향 계단 큐 최대 2명")
	runtime = second.runtime
	_expect(not bool(runtime.entities.monster_a.can_attack) and is_equal_approx(float(runtime.entities.monster_a.damage_multiplier), 0.5), "전이 중 공격 불가·피해 50% 감소")
	runtime = MultiFloorScript.tick(runtime, 0.60)
	_expect(str(runtime.entities.monster_a.floor_id) == "2F" and str(runtime.entities.monster_a.room_id) == "upper_stair_landing", "몬스터 0.60초 층 이동")
	runtime = MultiFloorScript.tick(runtime, 0.60)
	_expect(str(runtime.entities.enemy_a.floor_id) == "2F" and runtime.transition_queues["1F>2F"].is_empty(), "적 층 이동·계단 교착 없음")
	runtime = MultiFloorScript.register_entity(runtime, "fallen", "monster", "1F", "spike_corridor")
	var queued := MultiFloorScript.request_transition(runtime, graph, "fallen", "2F")
	runtime = MultiFloorScript.mark_defeated(queued.runtime, "fallen")
	_expect(runtime.transition_queues["1F>2F"].is_empty() and not bool(runtime.entities.fallen.in_transition), "쓰러진 유닛 계단 큐 즉시 정리")


func _test_restore_and_unlock() -> void:
	var graph := MultiFloorScript.build_graph(DataRegistry.rooms, MultiFloorScript.fixture_upper_rooms())
	var saved := MultiFloorScript.new_runtime()
	saved.visible_floor = "3F"
	saved = MultiFloorScript.register_entity(saved, "valid_enemy", "enemy", "2F", "upper_stair_landing")
	saved.entities["invalid_enemy"] = {"floor_id": "3F", "room_id": "void", "alive": true}
	saved.transition_queues["2F>1F"] = [{"entity_id": "invalid_enemy"}]
	var restored := MultiFloorScript.restore_runtime(saved, graph)
	_expect(str(restored.visible_floor) == "1F" and restored.entities.has("valid_enemy") and not restored.entities.has("invalid_enemy"), "저장 안전 화면·유효 엔티티 복원")
	_expect(restored.transition_queues["2F>1F"].is_empty(), "잘못된 저장 전이 큐 격리")
	var active := {"campaign_mode_id": "council_season", "upper_floor": {"unlocked": false, "layout_id": "", "objective_hp": {}, "facility_role": "", "seal_theft_count": 0, "graph_runtime": {}}}
	var day15 := MultiFloorScript.unlock_if_due(active, 15)
	var day16 := MultiFloorScript.unlock_if_due(active, 16)
	_expect(not bool(day15.upper_floor.unlocked) and bool(day16.upper_floor.unlocked), "의회 회차 DAY 16 상층 해금")
	_expect(day16.upper_floor.graph_runtime.has("visible_floor") and JSON.stringify(day16.upper_floor.graph_runtime) != "", "멀티플로어 런타임 JSON 저장 가능")


func _room_ids(path: Array) -> Array:
	var result: Array = []
	for node in path:
		result.append(str(node.room_id))
	return result


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[MultiFloorGraphPhase10] FAIL: %s" % label)

