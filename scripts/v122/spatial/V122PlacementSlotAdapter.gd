class_name V122PlacementSlotAdapter
extends RefCounted

const MONSTER_SLOT_OFFSETS := [
	Vector2(-18.0, 6.0),
	Vector2(18.0, 6.0),
	Vector2(0.0, -12.0),
	Vector2(-28.0, -10.0),
	Vector2(28.0, -10.0),
	Vector2(-10.0, 18.0),
	Vector2(10.0, 18.0),
	Vector2.ZERO
]


static func build(graph, rooms: Dictionary, monster_roster: Dictionary) -> Dictionary:
	var facility_slots: Array = []
	var monster_slots: Array = []
	var facility_placements: Array = []
	var monster_placements: Array = []
	var object_slots_by_room := {}
	for value in graph.debug_object_slots():
		if not value is Dictionary:
			continue
		var room_id := str(value.get("instance_id", ""))
		var anchor: Vector2 = graph.tile_cell_center(value.get("cell", Vector2i.ZERO))
		var placement := {
			"room_id": room_id,
			"object_id": str(value.get("id", "")),
			"facing": str(value.get("facing", "")),
			"layer": str(value.get("layer", "front")),
			"world_anchor": _vector_array(anchor)
		}
		facility_placements.append(placement)
		object_slots_by_room[room_id] = placement

	var room_ids: Array = rooms.keys()
	room_ids.sort()
	for room_id_value in room_ids:
		var room_id := str(room_id_value)
		if not graph.module_instance_ids().has(room_id):
			continue
		var room: Dictionary = rooms.get(room_id, {})
		var role := str(room.get("facility_role", room.get("type", "")))
		if role != "" and role not in ["legacy", "corridor", "trap"]:
			var object_placement: Dictionary = object_slots_by_room.get(room_id, {})
			facility_slots.append({
				"slot_id": "facility:%s" % room_id,
				"room_id": room_id,
				"facility_role": role,
				"object_id": str(object_placement.get("object_id", "")),
				"world_anchor": object_placement.get("world_anchor", _vector_array(graph.center(room_id))),
				"locked": not bool(room.get("unlocked", true))
			})
		var capacity := maxi(0, int(room.get("max_monsters", 0)))
		for slot_index in range(capacity):
			monster_slots.append({
				"slot_id": "monster:%s:%d" % [room_id, slot_index],
				"room_id": room_id,
				"slot_index": slot_index,
				"world_anchor": _vector_array(_monster_anchor(graph.center(room_id), slot_index))
			})

	var used_room_slots := {}
	var roster_ids: Array = monster_roster.keys()
	roster_ids.sort()
	for roster_id_value in roster_ids:
		var roster_id := str(roster_id_value)
		var member: Dictionary = monster_roster.get(roster_id, {})
		var room_id := str(member.get("room", member.get("assigned_room", "")))
		if room_id == "" or not rooms.has(room_id):
			continue
		var slot_index := int(used_room_slots.get(room_id, 0))
		used_room_slots[room_id] = slot_index + 1
		monster_placements.append({
			"monster_instance_id": roster_id,
			"species_id": str(member.get("species_id", member.get("unit_id", roster_id))),
			"room_id": room_id,
			"slot_id": "monster:%s:%d" % [room_id, slot_index],
			"world_anchor": _vector_array(_monster_anchor(graph.center(room_id), slot_index))
		})

	return {
		"facility_slots": facility_slots,
		"monster_slots": monster_slots,
		"facility_placements": facility_placements,
		"monster_placements": monster_placements
	}


static func _monster_anchor(room_center: Vector2, slot_index: int) -> Vector2:
	return room_center + MONSTER_SLOT_OFFSETS[slot_index % MONSTER_SLOT_OFFSETS.size()]


static func _vector_array(value: Vector2) -> Array:
	return [snappedf(value.x, 0.001), snappedf(value.y, 0.001)]
