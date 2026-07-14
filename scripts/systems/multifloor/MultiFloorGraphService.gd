extends RefCounted
class_name MultiFloorGraphService

const FLOOR_1 := "1F"
const FLOOR_2 := "2F"
const TRANSITION_SECONDS := 0.60
const REPATH_WAIT_SECONDS := 2.0
const MAX_QUEUE_PER_DIRECTION := 2
const MODE_COUNCIL_SEASON := "council_season"


static func fixture_upper_rooms() -> Dictionary:
	return {
		"upper_stair_landing": {"display_name": "상층 계단참", "center": [760, 620], "rect": [620, 500, 280, 240], "exits": ["upper_fixture_goal"]},
		"upper_fixture_goal": {"display_name": "상층 목표 fixture", "center": [1160, 400], "rect": [1010, 280, 300, 240], "exits": ["upper_stair_landing"], "is_objective": true}
	}


static func build_graph(base_rooms_value, upper_rooms_value, base_stair_room: String = "spike_corridor", upper_stair_room: String = "upper_stair_landing") -> Dictionary:
	var base_rooms: Dictionary = base_rooms_value.duplicate(true) if base_rooms_value is Dictionary else {}
	var upper_rooms: Dictionary = upper_rooms_value.duplicate(true) if upper_rooms_value is Dictionary else {}
	if not base_rooms.has(base_stair_room) or not upper_rooms.has(upper_stair_room):
		return {"ok": false, "error": "계단 endpoint 방이 없습니다.", "floors": {FLOOR_1: base_rooms, FLOOR_2: upper_rooms}, "stairs": [], "objectives": {FLOOR_1: [], FLOOR_2: []}}
	var upper_objectives: Array[String] = []
	for room_id_value in upper_rooms.keys():
		if bool(upper_rooms[room_id_value].get("is_objective", false)):
			upper_objectives.append(str(room_id_value))
	return {
		"ok": true, "error": "", "floors": {FLOOR_1: base_rooms, FLOOR_2: upper_rooms},
		"stairs": [{"id": "castle_stair_01", "from_floor": FLOOR_1, "from_room": base_stair_room, "to_floor": FLOOR_2, "to_room": upper_stair_room}],
		"objectives": {FLOOR_1: ["throne"] if base_rooms.has("throne") else [], FLOOR_2: upper_objectives}
	}


static func path_between(graph: Dictionary, start_floor: String, start_room: String, goal_floor: String, goal_room: String) -> Array[Dictionary]:
	if not _has_room(graph, start_floor, start_room) or not _has_room(graph, goal_floor, goal_room):
		return []
	var start_key := _node_key(start_floor, start_room)
	var goal_key := _node_key(goal_floor, goal_room)
	var frontier: Array[String] = [start_key]
	var came_from := {start_key: ""}
	while not frontier.is_empty():
		var current_key: String = frontier.pop_front()
		if current_key == goal_key:
			return _reconstruct(came_from, start_key, goal_key)
		for next_key in _neighbors(graph, current_key):
			if came_from.has(next_key):
				continue
			came_from[next_key] = current_key
			frontier.append(next_key)
	return []


static func objective_path(graph: Dictionary, floor_id: String, room_id: String, objective_floor: String = "") -> Array[Dictionary]:
	var best: Array[Dictionary] = []
	var floors: Array[String] = []
	if objective_floor != "":
		floors.append(objective_floor)
	else:
		floors.append_array([FLOOR_1, FLOOR_2])
	for target_floor in floors:
		for objective_id_value in graph.get("objectives", {}).get(target_floor, []):
			var candidate := path_between(graph, floor_id, room_id, target_floor, str(objective_id_value))
			if not candidate.is_empty() and (best.is_empty() or candidate.size() < best.size()):
				best = candidate
	return best


static func new_runtime() -> Dictionary:
	return {"visible_floor": FLOOR_1, "entities": {}, "transition_queues": {_direction_key(FLOOR_1, FLOOR_2): [], _direction_key(FLOOR_2, FLOOR_1): []}}


static func unlock_if_due(active_run_value, day: int) -> Dictionary:
	var active_run: Dictionary = active_run_value.duplicate(true) if active_run_value is Dictionary else {}
	if str(active_run.get("campaign_mode_id", "")) != MODE_COUNCIL_SEASON or day < 16:
		return active_run
	var upper: Dictionary = active_run.get("upper_floor", {}).duplicate(true)
	upper["unlocked"] = true
	if not (upper.get("graph_runtime", {}) is Dictionary) or upper.get("graph_runtime", {}).is_empty():
		upper["graph_runtime"] = new_runtime()
	active_run["upper_floor"] = upper
	return active_run


static func register_entity(runtime_value, entity_id: String, faction: String, floor_id: String, room_id: String) -> Dictionary:
	var runtime: Dictionary = runtime_value.duplicate(true) if runtime_value is Dictionary else new_runtime()
	if entity_id == "" or floor_id not in [FLOOR_1, FLOOR_2]:
		return runtime
	var entities: Dictionary = runtime.get("entities", {}).duplicate(true)
	entities[entity_id] = {"faction": faction, "floor_id": floor_id, "room_id": room_id, "alive": true, "in_transition": false, "can_attack": true, "damage_multiplier": 1.0, "repath_required": false}
	runtime["entities"] = entities
	return runtime


static func request_transition(runtime_value, graph: Dictionary, entity_id: String, to_floor: String) -> Dictionary:
	var runtime: Dictionary = runtime_value.duplicate(true) if runtime_value is Dictionary else new_runtime()
	var entity: Dictionary = runtime.get("entities", {}).get(entity_id, {}).duplicate(true)
	if entity.is_empty() or not bool(entity.get("alive", false)) or bool(entity.get("in_transition", false)):
		return {"ok": false, "error": "전이할 수 없는 유닛입니다.", "runtime": runtime}
	var from_floor := str(entity.get("floor_id", ""))
	var endpoint := _stair_endpoint(graph, from_floor, to_floor)
	if endpoint.is_empty() or str(entity.get("room_id", "")) != str(endpoint.get("from_room", "")):
		return {"ok": false, "error": "유닛이 계단 endpoint에 있지 않습니다.", "runtime": runtime}
	var key := _direction_key(from_floor, to_floor)
	var queues: Dictionary = runtime.get("transition_queues", {}).duplicate(true)
	var queue: Array = queues.get(key, []).duplicate(true)
	if queue.size() >= MAX_QUEUE_PER_DIRECTION:
		return {"ok": false, "error": "같은 방향 계단 전이 큐는 최대 2명입니다.", "runtime": runtime}
	queue.append({"entity_id": entity_id, "from_floor": from_floor, "to_floor": to_floor, "to_room": str(endpoint.get("to_room", "")), "elapsed": 0.0, "wait_seconds": 0.0})
	queues[key] = queue
	entity["in_transition"] = true
	entity["can_attack"] = false
	entity["damage_multiplier"] = 0.5
	var entities: Dictionary = runtime.get("entities", {}).duplicate(true)
	entities[entity_id] = entity
	runtime["entities"] = entities
	runtime["transition_queues"] = queues
	return {"ok": true, "error": "", "runtime": runtime}


static func tick(runtime_value, delta: float) -> Dictionary:
	var runtime: Dictionary = runtime_value.duplicate(true) if runtime_value is Dictionary else new_runtime()
	if delta <= 0.0:
		return runtime
	var entities: Dictionary = runtime.get("entities", {}).duplicate(true)
	var queues: Dictionary = runtime.get("transition_queues", {}).duplicate(true)
	for key_value in queues.keys():
		var key := str(key_value)
		var queue: Array = queues.get(key, []).duplicate(true)
		for index in range(queue.size() - 1, -1, -1):
			var queued_id := str(queue[index].get("entity_id", ""))
			if not entities.has(queued_id) or not bool(entities[queued_id].get("alive", false)):
				queue.remove_at(index)
		if not queue.is_empty():
			queue[0]["elapsed"] = float(queue[0].get("elapsed", 0.0)) + delta
			for index in range(1, queue.size()):
				queue[index]["wait_seconds"] = float(queue[index].get("wait_seconds", 0.0)) + delta
				if float(queue[index].get("wait_seconds", 0.0)) >= REPATH_WAIT_SECONDS:
					var waiting_id := str(queue[index].get("entity_id", ""))
					if entities.has(waiting_id):
						entities[waiting_id]["repath_required"] = true
			if float(queue[0].get("elapsed", 0.0)) >= TRANSITION_SECONDS:
				var completed: Dictionary = queue.pop_front()
				var entity_id := str(completed.get("entity_id", ""))
				if entities.has(entity_id):
					entities[entity_id]["floor_id"] = str(completed.get("to_floor", FLOOR_1))
					entities[entity_id]["room_id"] = str(completed.get("to_room", ""))
					entities[entity_id]["in_transition"] = false
					entities[entity_id]["can_attack"] = true
					entities[entity_id]["damage_multiplier"] = 1.0
		queues[key] = queue
	runtime["entities"] = entities
	runtime["transition_queues"] = queues
	return runtime


static func mark_defeated(runtime_value, entity_id: String) -> Dictionary:
	var runtime: Dictionary = runtime_value.duplicate(true) if runtime_value is Dictionary else new_runtime()
	var entities: Dictionary = runtime.get("entities", {}).duplicate(true)
	if entities.has(entity_id):
		entities[entity_id]["alive"] = false
		entities[entity_id]["in_transition"] = false
	var queues: Dictionary = runtime.get("transition_queues", {}).duplicate(true)
	for key in queues.keys():
		var filtered: Array = []
		for item in queues[key]:
			if str(item.get("entity_id", "")) != entity_id:
				filtered.append(item)
		queues[key] = filtered
	runtime["entities"] = entities
	runtime["transition_queues"] = queues
	return runtime


static func restore_runtime(saved_value, graph: Dictionary) -> Dictionary:
	var saved: Dictionary = saved_value if saved_value is Dictionary else {}
	var runtime := new_runtime()
	runtime["visible_floor"] = str(saved.get("visible_floor", FLOOR_1)) if str(saved.get("visible_floor", FLOOR_1)) in [FLOOR_1, FLOOR_2] else FLOOR_1
	for entity_id_value in saved.get("entities", {}).keys():
		var entity_id := str(entity_id_value)
		var entity: Dictionary = saved.get("entities", {})[entity_id_value]
		if _has_room(graph, str(entity.get("floor_id", "")), str(entity.get("room_id", ""))):
			runtime["entities"][entity_id] = entity.duplicate(true)
	for key in runtime["transition_queues"].keys():
		var restored_queue: Array = []
		for item in saved.get("transition_queues", {}).get(key, []):
			var entity_id := str(item.get("entity_id", ""))
			if runtime["entities"].has(entity_id) and bool(runtime["entities"][entity_id].get("alive", false)) and restored_queue.size() < MAX_QUEUE_PER_DIRECTION:
				restored_queue.append(item.duplicate(true))
		runtime["transition_queues"][key] = restored_queue
	return runtime


static func _neighbors(graph: Dictionary, key: String) -> Array[String]:
	var parsed := _parse_key(key)
	var floor_id := str(parsed.floor_id)
	var room_id := str(parsed.room_id)
	var result: Array[String] = []
	for exit_id_value in graph.get("floors", {}).get(floor_id, {}).get(room_id, {}).get("exits", []):
		var exit_id := str(exit_id_value)
		if _has_room(graph, floor_id, exit_id):
			result.append(_node_key(floor_id, exit_id))
	for stair in graph.get("stairs", []):
		if str(stair.get("from_floor", "")) == floor_id and str(stair.get("from_room", "")) == room_id:
			result.append(_node_key(str(stair.get("to_floor", "")), str(stair.get("to_room", ""))))
		elif str(stair.get("to_floor", "")) == floor_id and str(stair.get("to_room", "")) == room_id:
			result.append(_node_key(str(stair.get("from_floor", "")), str(stair.get("from_room", ""))))
	return result


static func _stair_endpoint(graph: Dictionary, from_floor: String, to_floor: String) -> Dictionary:
	for stair in graph.get("stairs", []):
		if str(stair.get("from_floor", "")) == from_floor and str(stair.get("to_floor", "")) == to_floor:
			return stair.duplicate(true)
		if str(stair.get("to_floor", "")) == from_floor and str(stair.get("from_floor", "")) == to_floor:
			return {"from_floor": from_floor, "from_room": stair.get("to_room", ""), "to_floor": to_floor, "to_room": stair.get("from_room", "")}
	return {}


static func _has_room(graph: Dictionary, floor_id: String, room_id: String) -> bool:
	return graph.get("floors", {}).get(floor_id, {}).has(room_id)


static func _node_key(floor_id: String, room_id: String) -> String:
	return "%s::%s" % [floor_id, room_id]


static func _parse_key(key: String) -> Dictionary:
	var parts := key.split("::", false, 1)
	return {"floor_id": parts[0] if parts.size() > 0 else "", "room_id": parts[1] if parts.size() > 1 else ""}


static func _direction_key(from_floor: String, to_floor: String) -> String:
	return "%s>%s" % [from_floor, to_floor]


static func _reconstruct(came_from: Dictionary, start_key: String, goal_key: String) -> Array[Dictionary]:
	var keys: Array[String] = [goal_key]
	var current := goal_key
	while current != start_key:
		current = str(came_from.get(current, ""))
		if current == "":
			return []
		keys.push_front(current)
	var result: Array[Dictionary] = []
	for key in keys:
		result.append(_parse_key(key))
	return result
