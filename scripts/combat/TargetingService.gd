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

static func units_in_room(candidates: Array, room_id: String) -> Array:
	var result: Array = []
	for candidate in candidates:
		if candidate != null and candidate.is_alive() and candidate.current_room == room_id:
			result.append(candidate)
	return result

