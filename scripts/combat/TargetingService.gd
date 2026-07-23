extends RefCounted
class_name TargetingService

static func nearest(source: Node, candidates: Array, max_distance: float = INF) -> Node:
	var best: Node = null
	var best_distance = max_distance
	for candidate in candidates:
		if candidate == null or not candidate.is_alive():
			continue
		var distance = source.global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best

static func monster_priority(source: Node, candidates: Array, graph, core_room: String = "throne", treasure_room: String = "treasure") -> Node:
	var best: Node = null
	var best_score = INF
	var throne = graph.center(core_room)
	var treasure_pressure_rooms: Array = []
	if treasure_room != "":
		treasure_pressure_rooms = [treasure_room] + graph.exits(treasure_room)
	for candidate in candidates:
		if candidate == null or not candidate.is_alive():
			continue
		var distance = source.global_position.distance_to(candidate.global_position)
		var throne_distance = candidate.global_position.distance_to(throne)
		var hp_ratio = float(candidate.hp) / float(max(1, candidate.max_hp))
		var score = distance * 0.45 + throne_distance * 0.35 + hp_ratio * 120.0
		if candidate.current_room == source.current_room:
			score -= 160.0
		if candidate.current_room == core_room:
			score -= 260.0
		if candidate.unit_id == "thief" and treasure_pressure_rooms.has(candidate.current_room):
			score -= 220.0
		if score < best_score:
			best_score = score
			best = candidate
	return best

static func units_in_room(candidates: Array, room_id: String) -> Array:
	var result: Array = []
	for candidate in candidates:
		if candidate != null and candidate.is_alive() and candidate.current_room == room_id:
			result.append(candidate)
	return result


static func v20_targetable_nearest(source: Node, candidates: Array, max_distance: float = INF) -> Node:
	var targetable: Array = []
	for candidate in candidates:
		if candidate == null or not candidate.is_alive():
			continue
		if candidate.has_meta("v20_targetable") and not bool(candidate.get_meta("v20_targetable", true)):
			continue
		targetable.append(candidate)
	return nearest(source, targetable, max_distance)


static func v20_tag_priority(source: Node, candidates: Array, preferred_tags: Array, max_distance: float = INF, focused_target_id: String = "") -> Node:
	var best: Node = null
	var best_score := INF
	for candidate in candidates:
		if candidate == null or not candidate.is_alive():
			continue
		if candidate.has_meta("v20_targetable") and not bool(candidate.get_meta("v20_targetable", true)):
			continue
		var distance: float = source.global_position.distance_to(candidate.global_position)
		if distance > max_distance:
			continue
		if focused_target_id != "" and str(candidate.get_instance_id()) == focused_target_id:
			return candidate
		var tags: Array = candidate.get_meta("v20_tags", [])
		var preferred := preferred_tags.any(func(tag): return tags.has(tag))
		var score: float = distance - (10000.0 if preferred else 0.0)
		if score < best_score:
			best_score = score
			best = candidate
	return best

