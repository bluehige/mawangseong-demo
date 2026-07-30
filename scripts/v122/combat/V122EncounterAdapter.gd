class_name V122EncounterAdapter
extends RefCounted


static func annotate_schedule(
	schedule: Array,
	battle_plan: Dictionary,
	enemy_catalog: Dictionary
) -> Array:
	var result: Array = []
	var specialist_counts := {}
	for entry_value in schedule:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value.duplicate(true)
		var enemy_id := str(entry.get("enemy_id", ""))
		var enemy: Dictionary = enemy_catalog.get(enemy_id, {}).duplicate(true)
		enemy["id"] = enemy_id
		if entry.has("goal_type_override"):
			enemy["goal_type"] = str(entry.get("goal_type_override", "throne"))
		var role := _effective_role(enemy)
		if role in ["engineer", "thief"] and not entry.has("target_facility_slot_id"):
			var targets := _facility_targets(role, battle_plan)
			if not targets.is_empty():
				var occurrence := int(specialist_counts.get(role, 0))
				var target: Dictionary = targets[occurrence % targets.size()]
				entry["target_facility_slot_id"] = str(target.get("slot_id", ""))
				entry["target_room_id"] = str(target.get("room_id", ""))
				specialist_counts[role] = occurrence + 1
		var contract := spawn_contract(enemy, entry, battle_plan)
		for key in [
			"lane_id",
			"lane_label",
			"spawn_room_id",
			"exit_room_id",
			"target_room_id",
			"target_facility_slot_id",
			"target_facility_instance_id",
			"telegraph_id"
		]:
			var value = contract.get(key)
			if value != null and str(value) != "":
				entry[key] = value
		result.append(entry)
	return result


static func telegraph(
	enemy: Dictionary,
	battle_plan: Dictionary,
	wave_entry: Dictionary = {}
) -> Dictionary:
	var contract := spawn_contract(enemy, wave_entry, battle_plan)
	return {
		"telegraph_id": str(contract.get("telegraph_id", "")),
		"enemy_id": str(enemy.get("id", enemy.get("unit_id", ""))),
		"role": str(contract.get("role", "assault")),
		"lane_id": str(contract.get("lane_id", "")),
		"lane_label": str(contract.get("lane_label", "")),
		"spawn_room_id": str(contract.get("spawn_room_id", "")),
		"exit_room_id": str(contract.get("exit_room_id", "")),
		"entry_anchor": contract.get("entry_anchor", []),
		"target_room_id": str(contract.get("target_room_id", "")),
		"target_facility_slot_id": str(contract.get("target_facility_slot_id", "")),
		"target_facility_instance_id": str(contract.get("target_facility_instance_id", "")),
		"target_object_id": str(contract.get("target_object_id", "")),
		"target_anchor": contract.get("target_anchor", []),
		"route": contract.get("route", []).duplicate(),
		"counter_hint": _counter_hint(str(contract.get("role", "assault")))
	}


static func spawn_contract(
	enemy: Dictionary,
	wave_entry: Dictionary,
	battle_plan: Dictionary
) -> Dictionary:
	var role := _effective_role(enemy)
	var target := _role_target(role, battle_plan, wave_entry)
	var lane_id := _lane_id_for(role, target, wave_entry, battle_plan)
	var spawn_room_id := _lane_entry_room(lane_id, battle_plan)
	var target_room_id := str(target.get("room_id", ""))
	var route := _route_to_target(battle_plan, lane_id, spawn_room_id, target)
	var lane_label := str(battle_plan.get("lane_labels", {}).get(lane_id, lane_id))
	var enemy_id := str(enemy.get("id", enemy.get("unit_id", "")))
	var target_slot_id := str(target.get("slot_id", ""))
	var telegraph_id := "%s:%s:%s:%s" % [
		enemy_id,
		lane_id,
		target_slot_id,
		target_room_id
	]
	return {
		"telegraph_id": telegraph_id,
		"enemy_id": enemy_id,
		"role": role,
		"lane_id": lane_id,
		"lane_label": lane_label,
		"spawn_room_id": spawn_room_id,
		"exit_room_id": spawn_room_id,
		"entry_anchor": battle_plan.get("world_anchors", {}).get(spawn_room_id, []),
		"target_room_id": target_room_id,
		"target_facility_slot_id": target_slot_id,
		"target_facility_instance_id": str(target.get("facility_instance_id", target_room_id)),
		"target_object_id": str(target.get("object_id", "")),
		"target_anchor": target.get(
			"world_anchor",
			battle_plan.get("world_anchors", {}).get(target_room_id, [])
		),
		"route": route
	}


static func _effective_role(enemy: Dictionary) -> String:
	var enemy_id := str(enemy.get("id", enemy.get("unit_id", "")))
	if enemy_id == "engineer":
		return "engineer"
	if enemy_id == "thief":
		return "thief"
	return str(enemy.get("role", enemy.get("goal_type", "assault")))


static func _role_target(
	role: String,
	battle_plan: Dictionary,
	wave_entry: Dictionary
) -> Dictionary:
	var explicit_slot_id := str(wave_entry.get("target_facility_slot_id", ""))
	var explicit_room_id := str(wave_entry.get("target_room_id", ""))
	for value in battle_plan.get("facility_slots", []):
		if not value is Dictionary:
			continue
		if (
			(explicit_slot_id != "" and str(value.get("slot_id", "")) == explicit_slot_id)
			or (explicit_room_id != "" and str(value.get("room_id", "")) == explicit_room_id)
		):
			return value.duplicate(true)
	var targets := _facility_targets(role, battle_plan)
	if not targets.is_empty():
		return targets.front()
	var goal_id := explicit_room_id
	if goal_id == "":
		var goals: Array = battle_plan.get("enemy_goals", [])
		goal_id = str(goals.front()) if not goals.is_empty() else "throne"
	return {
		"room_id": goal_id,
		"object_id": "",
		"world_anchor": battle_plan.get("world_anchors", {}).get(goal_id, [])
	}


static func _facility_targets(role: String, battle_plan: Dictionary) -> Array:
	var wanted_roles: Array = []
	match role:
		"engineer", "facility":
			wanted_roles = ["barracks", "watch_post", "recovery"]
		"thief", "loot", "treasure":
			wanted_roles = ["treasure"]
		"heart":
			wanted_roles = ["heart_chamber"]
	var result: Array = []
	for value in battle_plan.get("facility_slots", []):
		if (
			value is Dictionary
			and wanted_roles.has(str(value.get("facility_role", "")))
		):
			result.append(value.duplicate(true))
	result.sort_custom(func(a, b): return str(a.get("slot_id", "")) < str(b.get("slot_id", "")))
	return result


static func _lane_id_for(
	role: String,
	target: Dictionary,
	wave_entry: Dictionary,
	battle_plan: Dictionary
) -> String:
	var lane_routes = battle_plan.get("lane_routes", {})
	if not lane_routes is Dictionary or lane_routes.is_empty():
		return ""
	if role in ["engineer", "facility", "thief", "loot", "treasure"]:
		var target_lane_id := str(target.get("lane_id", ""))
		if lane_routes.has(target_lane_id):
			return target_lane_id
	var explicit_lane_id := str(wave_entry.get("lane_id", ""))
	if lane_routes.has(explicit_lane_id):
		return explicit_lane_id
	var primary_lane_id := str(battle_plan.get("primary_lane_id", ""))
	if lane_routes.has(primary_lane_id):
		return primary_lane_id
	var lane_ids: Array = lane_routes.keys()
	lane_ids.sort()
	return str(lane_ids.front()) if not lane_ids.is_empty() else ""


static func _lane_entry_room(lane_id: String, battle_plan: Dictionary) -> String:
	var lane_entries = battle_plan.get("lane_entries", {})
	if lane_entries is Dictionary:
		var explicit_entry := str(lane_entries.get(lane_id, ""))
		if explicit_entry != "":
			return explicit_entry
	var rooms: Array = battle_plan.get("rooms", [])
	var lane_routes = battle_plan.get("lane_routes", {})
	if lane_routes is Dictionary:
		for room_id_value in lane_routes.get(lane_id, []):
			var room_id := str(room_id_value)
			if rooms.has(room_id):
				return room_id
	if rooms.has("entrance"):
		return "entrance"
	var active_route: Array = battle_plan.get("active_route", [])
	for room_id_value in active_route:
		var room_id := str(room_id_value)
		if rooms.has(room_id):
			return room_id
	return str(battle_plan.get("route_start", "entrance"))


static func _route_to_target(
	battle_plan: Dictionary,
	lane_id: String,
	spawn_room_id: String,
	target: Dictionary
) -> Array:
	var lane_routes = battle_plan.get("lane_routes", {})
	var route: Array = []
	if lane_routes is Dictionary and lane_routes.has(lane_id):
		route = lane_routes.get(lane_id, []).duplicate()
	else:
		route = battle_plan.get("active_route", []).duplicate()
	var spawn_index := route.find(spawn_room_id)
	if spawn_index > 0:
		route = route.slice(spawn_index)
	var target_room_id := str(target.get("room_id", ""))
	var target_index := route.find(target_room_id)
	if target_index >= 0:
		return route.slice(0, target_index + 1)
	var linked_zone_ids: Array = target.get("linked_zone_ids", [])
	if not linked_zone_ids.is_empty():
		var linked_zone_id := str(linked_zone_ids.front())
		for zone_value in battle_plan.get("defense_zones", []):
			if not zone_value is Dictionary or str(zone_value.get("zone_id", "")) != linked_zone_id:
				continue
			var anchor_index := route.find(str(zone_value.get("anchor_room_id", "")))
			if anchor_index >= 0:
				route = route.slice(0, anchor_index + 1)
			break
	if target_room_id != "" and not route.has(target_room_id):
		route.append(target_room_id)
	return route


static func _counter_hint(role: String) -> String:
	match role:
		"engineer", "facility":
			return "시설 앞 집중 또는 감시 초소로 공병 접근을 끊으세요."
		"thief", "loot", "treasure":
			return "금고가 있는 전선에 수비대를 배치하세요."
		"rearline":
			return "감시 초소 또는 집중 명령으로 후열을 노출하세요."
		"heart":
			return "심장실 앞 방어 구간을 유지하세요."
	return "해당 전선의 첫 방어 구역에서 진입을 지연하세요."
