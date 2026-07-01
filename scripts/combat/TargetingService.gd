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

static func monster_priority(source: Node, candidates: Array, graph) -> Node:
	var best: Node = null
	var best_score = INF
	var throne = graph.center("throne")
	for candidate in candidates:
		if candidate == null or not candidate.is_alive():
			continue
		var distance = source.global_position.distance_to(candidate.global_position)
		var throne_distance = candidate.global_position.distance_to(throne)
		var hp_ratio = float(candidate.hp) / float(max(1, candidate.max_hp))
		var score = distance * 0.45 + throne_distance * 0.35 + hp_ratio * 120.0
		if candidate.current_room == source.current_room:
			score -= 160.0
		if candidate.current_room == "throne":
			score -= 260.0
		if candidate.unit_id == "thief" and candidate.current_room in ["slot_01", "treasure"]:
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

