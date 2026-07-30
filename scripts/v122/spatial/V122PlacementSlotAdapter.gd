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
	var topology := _combat_topology(graph)
	if _uses_defense_zones(topology):
		return _build_zone_placements(graph, rooms, monster_roster, topology)

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
		var role := _product_role(room_id, room)
		if role != "" and role not in ["legacy", "corridor", "trap"]:
			var object_placement: Dictionary = object_slots_by_room.get(room_id, {})
			facility_slots.append({
				"slot_id": "facility:%s" % room_id,
				"facility_instance_id": room_id,
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

	var roster_ids: Array = monster_roster.keys()
	roster_ids.sort()
	var assigned_slot_indices := {}
	var used_room_slots := {}
	for roster_id_value in roster_ids:
		var roster_id := str(roster_id_value)
		var member: Dictionary = monster_roster.get(roster_id, {})
		var room_id := str(member.get("room", member.get("assigned_room", "")))
		if room_id == "" or not rooms.has(room_id):
			continue
		var capacity := maxi(0, int(rooms.get(room_id, {}).get("max_monsters", 0)))
		var slot_index := _requested_monster_slot_index(str(member.get("placement_slot_id", "")), room_id, capacity)
		if slot_index < 0:
			continue
		var used_indices: Dictionary = used_room_slots.get(room_id, {})
		if used_indices.has(slot_index):
			continue
		used_indices[slot_index] = true
		used_room_slots[room_id] = used_indices
		assigned_slot_indices[roster_id] = slot_index

	for roster_id_value in roster_ids:
		var roster_id := str(roster_id_value)
		var member: Dictionary = monster_roster.get(roster_id, {})
		var room_id := str(member.get("room", member.get("assigned_room", "")))
		if room_id == "" or not rooms.has(room_id):
			continue
		var used_indices: Dictionary = used_room_slots.get(room_id, {})
		var slot_index := int(assigned_slot_indices.get(roster_id, -1))
		if slot_index < 0:
			slot_index = _first_open_monster_slot_index(maxi(0, int(rooms.get(room_id, {}).get("max_monsters", 0))), used_indices)
			used_indices[slot_index] = true
			used_room_slots[room_id] = used_indices
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


static func _build_zone_placements(
	graph,
	rooms: Dictionary,
	monster_roster: Dictionary,
	topology: Dictionary
) -> Dictionary:
	var instance_ids: Array = graph.module_instance_ids()
	var zones: Array = _valid_defense_zones(topology.get("defense_zones", []), instance_ids)
	var zone_by_id := {}
	for zone_value in zones:
		var zone: Dictionary = zone_value
		zone_by_id[str(zone.get("zone_id", ""))] = zone

	var object_slots_by_room := _object_slots_by_room(graph)
	var facility_slot_contracts: Array = []
	var facility_slots: Array = []
	var facility_placements: Array = []
	for contract_value in topology.get("facility_slots", []):
		if not contract_value is Dictionary:
			continue
		var contract: Dictionary = contract_value.duplicate(true)
		var slot_id := str(contract.get("slot_id", ""))
		var room_id := str(contract.get("room_id", ""))
		if slot_id == "" or not instance_ids.has(room_id):
			continue
		facility_slot_contracts.append(contract)
		var room: Dictionary = rooms.get(room_id, {})
		var facility_role := _product_role(room_id, room)
		if facility_role == "":
			facility_role = str(contract.get("default_facility_role", ""))
		var object_placement: Dictionary = object_slots_by_room.get(room_id, {})
		var world_anchor: Array = object_placement.get("world_anchor", _vector_array(graph.center(room_id)))
		var object_id := str(object_placement.get("object_id", ""))
		var placed_module: Dictionary = graph.placed_module_data(room_id)
		var slot := {
			"slot_id": slot_id,
			"facility_instance_id": room_id,
			"room_id": room_id,
			"lane_id": str(contract.get("lane_id", "")),
			"linked_zone_ids": contract.get("linked_zone_ids", []).duplicate(),
			"default_facility_role": str(contract.get("default_facility_role", "")),
			"facility_role": facility_role,
			"object_id": object_id,
			"world_anchor": world_anchor,
			"replaceable": bool(contract.get("replaceable", false)),
			"locked": bool(placed_module.get("locked", true))
		}
		facility_slots.append(slot)
		facility_placements.append({
			"placement_id": "facility_placement:%s" % slot_id,
			"facility_slot_id": slot_id,
			"facility_instance_id": room_id,
			"room_id": room_id,
			"facility_role": facility_role,
			"object_id": object_id,
			"world_anchor": world_anchor,
			"occupied": facility_role not in ["", "build_slot"]
		})

	var monster_slots: Array = []
	for zone_value in zones:
		var zone: Dictionary = zone_value
		var zone_id := str(zone.get("zone_id", ""))
		var room_id := str(zone.get("anchor_room_id", ""))
		var capacity := maxi(0, int(zone.get("capacity", 0)))
		for slot_index in range(capacity):
			monster_slots.append({
				"slot_id": "monster:%s:%d" % [zone_id, slot_index],
				"defense_zone_id": zone_id,
				"lane_id": str(zone.get("lane_id", "")),
				"room_id": room_id,
				"slot_index": slot_index,
				"world_anchor": _vector_array(_monster_anchor(graph.center(room_id), slot_index))
			})

	var room_to_zone := _room_to_zone_map(topology, zones)
	var roster_ids: Array = monster_roster.keys()
	roster_ids.sort()
	var assigned_slot_indices := {}
	var assigned_zone_ids := {}
	var used_zone_slots := {}
	for roster_id_value in roster_ids:
		var roster_id := str(roster_id_value)
		var member: Dictionary = monster_roster.get(roster_id, {})
		var zone_id := _member_zone_id(member, zone_by_id, room_to_zone)
		if zone_id == "":
			continue
		var zone: Dictionary = zone_by_id.get(zone_id, {})
		var capacity := maxi(0, int(zone.get("capacity", 0)))
		var fallback_room_id := str(member.get("room", member.get("assigned_room", "")))
		var slot_index := _requested_zone_slot_index(
			str(member.get("placement_slot_id", "")),
			zone_id,
			fallback_room_id,
			capacity
		)
		if slot_index < 0:
			continue
		var used_indices: Dictionary = used_zone_slots.get(zone_id, {})
		if used_indices.has(slot_index):
			continue
		used_indices[slot_index] = true
		used_zone_slots[zone_id] = used_indices
		assigned_zone_ids[roster_id] = zone_id
		assigned_slot_indices[roster_id] = slot_index

	var monster_placements: Array = []
	for roster_id_value in roster_ids:
		var roster_id := str(roster_id_value)
		var member: Dictionary = monster_roster.get(roster_id, {})
		var zone_id := str(assigned_zone_ids.get(roster_id, _member_zone_id(member, zone_by_id, room_to_zone)))
		if zone_id == "" or not zone_by_id.has(zone_id):
			continue
		var zone: Dictionary = zone_by_id.get(zone_id, {})
		var room_id := str(zone.get("anchor_room_id", ""))
		var used_indices: Dictionary = used_zone_slots.get(zone_id, {})
		var slot_index := int(assigned_slot_indices.get(roster_id, -1))
		if slot_index < 0:
			slot_index = _first_open_monster_slot_index(maxi(0, int(zone.get("capacity", 0))), used_indices)
			used_indices[slot_index] = true
			used_zone_slots[zone_id] = used_indices
		monster_placements.append({
			"monster_instance_id": roster_id,
			"species_id": str(member.get("species_id", member.get("unit_id", roster_id))),
			"defense_zone_id": zone_id,
			"lane_id": str(zone.get("lane_id", "")),
			"room_id": room_id,
			"slot_id": "monster:%s:%d" % [zone_id, slot_index],
			"world_anchor": _vector_array(_monster_anchor(graph.center(room_id), slot_index))
		})

	return {
		"facility_slot_contracts": facility_slot_contracts,
		"facility_slots": facility_slots,
		"monster_slots": monster_slots,
		"facility_placements": facility_placements,
		"monster_placements": monster_placements
	}


static func _combat_topology(graph) -> Dictionary:
	var layout_value = graph.get("layout")
	if not layout_value is Dictionary:
		return {}
	var topology_value = layout_value.get("combat_topology", {})
	return topology_value if topology_value is Dictionary else {}


static func _uses_defense_zones(topology: Dictionary) -> bool:
	return not topology.get("defense_zones", []).is_empty() and not topology.get("facility_slots", []).is_empty()


static func _valid_defense_zones(values: Array, instance_ids: Array) -> Array:
	var result: Array = []
	var seen := {}
	for value in values:
		if not value is Dictionary:
			continue
		var zone: Dictionary = value.duplicate(true)
		var zone_id := str(zone.get("zone_id", ""))
		var anchor_room_id := str(zone.get("anchor_room_id", ""))
		if zone_id == "" or seen.has(zone_id) or not instance_ids.has(anchor_room_id):
			continue
		seen[zone_id] = true
		result.append(zone)
	return result


static func _object_slots_by_room(graph) -> Dictionary:
	var result := {}
	for value in graph.debug_object_slots():
		if not value is Dictionary:
			continue
		var room_id := str(value.get("instance_id", ""))
		if room_id == "" or result.has(room_id):
			continue
		result[room_id] = {
			"room_id": room_id,
			"object_id": str(value.get("id", "")),
			"facing": str(value.get("facing", "")),
			"layer": str(value.get("layer", "front")),
			"world_anchor": _vector_array(graph.tile_cell_center(value.get("cell", Vector2i.ZERO)))
		}
	return result


static func _room_to_zone_map(topology: Dictionary, zones: Array) -> Dictionary:
	var result := {}
	var zone_by_id := {}
	for zone_value in zones:
		var zone: Dictionary = zone_value
		var zone_id := str(zone.get("zone_id", ""))
		zone_by_id[zone_id] = zone
		result[str(zone.get("anchor_room_id", ""))] = zone_id
		for room_id_value in zone.get("room_ids", []):
			result[str(room_id_value)] = zone_id

	for contract_value in topology.get("facility_slots", []):
		if not contract_value is Dictionary:
			continue
		var linked_zone_ids: Array = contract_value.get("linked_zone_ids", [])
		if linked_zone_ids.is_empty():
			continue
		var zone_id := str(linked_zone_ids.front())
		if zone_by_id.has(zone_id):
			result[str(contract_value.get("room_id", ""))] = zone_id

	var merge_room_id := str(topology.get("merge_room_id", ""))
	var goal_room_id := str(topology.get("goal_room_id", ""))
	var merge_zone_id := ""
	for zone_value in zones:
		var zone: Dictionary = zone_value
		if str(zone.get("lane_id", "")) == "merge":
			merge_zone_id = str(zone.get("zone_id", ""))
			break
	if merge_zone_id != "":
		result[merge_room_id] = merge_zone_id
		result[goal_room_id] = merge_zone_id

	var lanes_value = topology.get("lanes", {})
	if not lanes_value is Dictionary:
		return result
	var lane_ids: Array = lanes_value.keys()
	lane_ids.sort()
	for lane_id_value in lane_ids:
		var lane_id := str(lane_id_value)
		var lane: Dictionary = lanes_value.get(lane_id, {})
		var route: Array = lane.get("route", [])
		var lane_zones: Array = []
		for zone_value in zones:
			var zone: Dictionary = zone_value
			if str(zone.get("lane_id", "")) == lane_id:
				lane_zones.append(zone)
		for route_index in range(route.size()):
			var room_id := str(route[route_index])
			if result.has(room_id):
				continue
			var nearest_zone_id := ""
			var nearest_distance := 2147483647
			for zone_value in lane_zones:
				var zone: Dictionary = zone_value
				var anchor_index := route.find(str(zone.get("anchor_room_id", "")))
				if anchor_index < 0:
					continue
				var distance := absi(anchor_index - route_index)
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_zone_id = str(zone.get("zone_id", ""))
			if nearest_zone_id != "":
				result[room_id] = nearest_zone_id
	return result


static func _member_zone_id(member: Dictionary, zone_by_id: Dictionary, room_to_zone: Dictionary) -> String:
	var explicit_zone_id := str(member.get("defense_zone_id", member.get("assigned_defense_zone_id", "")))
	if zone_by_id.has(explicit_zone_id):
		return explicit_zone_id
	var room_id := str(member.get("room", member.get("assigned_room", "")))
	return str(room_to_zone.get(room_id, ""))


static func _requested_zone_slot_index(
	slot_id: String,
	zone_id: String,
	fallback_room_id: String,
	capacity: int
) -> int:
	var prefixes := ["monster:%s:" % zone_id]
	if fallback_room_id != "":
		prefixes.append("monster:%s:" % fallback_room_id)
	for prefix_value in prefixes:
		var prefix := str(prefix_value)
		if not slot_id.begins_with(prefix):
			continue
		var index_text := slot_id.trim_prefix(prefix)
		if not index_text.is_valid_int():
			return -1
		var slot_index := int(index_text)
		if slot_index >= 0 and slot_index < capacity:
			return slot_index
		return -1
	return -1


static func _requested_monster_slot_index(slot_id: String, room_id: String, capacity: int) -> int:
	var prefix := "monster:%s:" % room_id
	if not slot_id.begins_with(prefix):
		return -1
	var index_text := slot_id.trim_prefix(prefix)
	if not index_text.is_valid_int():
		return -1
	var slot_index := int(index_text)
	if slot_index < 0 or slot_index >= capacity:
		return -1
	return slot_index


static func _first_open_monster_slot_index(capacity: int, used_indices: Dictionary) -> int:
	for slot_index in range(capacity):
		if not used_indices.has(slot_index):
			return slot_index
	var overflow_index := capacity
	while used_indices.has(overflow_index):
		overflow_index += 1
	return overflow_index


static func _monster_anchor(room_center: Vector2, slot_index: int) -> Vector2:
	return room_center + MONSTER_SLOT_OFFSETS[slot_index % MONSTER_SLOT_OFFSETS.size()]


static func _product_role(room_id: String, room: Dictionary) -> String:
	var explicit := str(room.get("facility_role", ""))
	if explicit != "":
		return explicit
	match str(room.get("type", "")):
		"entry":
			return "entry"
		"core":
			return "core"
		"support":
			return "barracks" if room_id == "barracks" else ""
		"recovery":
			return "recovery"
		"bait":
			return "treasure"
		"build_slot":
			return "build_slot"
	return ""


static func _vector_array(value: Vector2) -> Array:
	return [snappedf(value.x, 0.001), snappedf(value.y, 0.001)]
