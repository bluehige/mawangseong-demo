class_name V122DefenseSegmentBuilder
extends RefCounted


static func build(active_route: Array, world_anchors: Dictionary, rooms: Dictionary, day: int) -> Array:
	if active_route.is_empty():
		return []
	var segment_count := mini(active_route.size(), 4 if day <= 5 else clampi(int(round(active_route.size() / 2.0)), 3, 6))
	var segments: Array = []
	for segment_index in range(segment_count):
		var begin := int(floor(float(segment_index * active_route.size()) / float(segment_count)))
		var finish := int(floor(float((segment_index + 1) * active_route.size()) / float(segment_count)))
		var room_ids: Array = []
		var facility_roles: Array = []
		for route_index in range(begin, finish):
			var room_id := str(active_route[route_index])
			room_ids.append(room_id)
			var role := str(rooms.get(room_id, {}).get("facility_role", ""))
			if role != "" and not facility_roles.has(role):
				facility_roles.append(role)
		var entry_room := str(room_ids.front())
		var exit_room := str(room_ids.back())
		segments.append({
			"segment_id": "defense_%02d" % (segment_index + 1),
			"order": segment_index,
			"room_ids": room_ids,
			"entry_room_id": entry_room,
			"exit_room_id": exit_room,
			"entry_anchor": world_anchors.get(entry_room, []),
			"exit_anchor": world_anchors.get(exit_room, []),
			"facility_roles": facility_roles
		})
	return segments
