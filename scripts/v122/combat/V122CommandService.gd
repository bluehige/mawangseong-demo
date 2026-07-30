class_name V122CommandService
extends RefCounted

const BattleLedger = preload("res://scripts/v122/combat/V122BattleLedger.gd")
const CATALOG_PATH := "res://data/v122/command_rules.json"


static func load_catalog() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	return parsed if parsed is Dictionary else {}


static func new_state(max_points: int = 3, initial_points: int = 3, recharge_seconds: float = 12.0) -> Dictionary:
	var catalog := load_catalog()
	var cooldowns := {}
	for command_id in catalog.keys():
		cooldowns[str(command_id)] = 0.0
	return {
		"max_points": maxi(1, max_points),
		"points": clampi(initial_points, 0, maxi(1, max_points)),
		"recharge_seconds": maxf(1.0, recharge_seconds),
		"recharge_progress": 0.0,
		"cooldowns": cooldowns,
		"active_commands": {},
		"history": []
	}


static func issue(
	state: Dictionary,
	command_id: String,
	target: Dictionary,
	battle_plan: Dictionary,
	ledger: Dictionary
) -> Dictionary:
	var catalog := load_catalog()
	var definition: Dictionary = catalog.get(command_id, {})
	if definition.is_empty():
		return _result(false, "unknown_command", state, ledger)
	if float(state.get("cooldowns", {}).get(command_id, 0.0)) > 0.0:
		return _result(false, "cooldown", state, ledger)
	var cost := int(definition.get("command_point_cost", 1))
	if int(state.get("points", 0)) < cost:
		return _result(false, "insufficient_points", state, ledger)
	var normalized_target := _validated_target(str(definition.get("target_type", "")), target, battle_plan)
	if normalized_target.is_empty():
		return _result(false, "invalid_target", state, ledger)
	var next := state.duplicate(true)
	next["points"] = int(next.get("points", 0)) - cost
	next["cooldowns"][command_id] = float(definition.get("cooldown_seconds", 0.0))
	next["active_commands"][command_id] = {
		"remaining_seconds": float(definition.get("duration_seconds", 0.0)),
		"target": normalized_target,
		"effect": definition.get("effect", {}).duplicate(true),
		"ai_priority": int(definition.get("ai_priority", 9))
	}
	next["history"].append({
		"command_id": command_id,
		"target": normalized_target,
		"point_cost": cost
	})
	var next_ledger := BattleLedger.record(ledger, "command_issued", {
		"command_id": command_id,
		"target": normalized_target,
		"point_cost": cost
	})
	return {
		"ok": true,
		"status": "issued",
		"state": next,
		"ledger": next_ledger,
		"highlight_anchor": normalized_target.get("world_anchor", [])
	}


static func advance(state: Dictionary, delta: float) -> Dictionary:
	var step := maxf(0.0, delta)
	var next := state.duplicate(true)
	for command_id in next.get("cooldowns", {}).keys():
		next["cooldowns"][command_id] = maxf(0.0, float(next["cooldowns"].get(command_id, 0.0)) - step)
	var expired: Array[String] = []
	for command_id_value in next.get("active_commands", {}).keys():
		var command_id := str(command_id_value)
		var active: Dictionary = next["active_commands"].get(command_id, {})
		active["remaining_seconds"] = maxf(0.0, float(active.get("remaining_seconds", 0.0)) - step)
		if is_zero_approx(float(active.get("remaining_seconds", 0.0))):
			expired.append(command_id)
		else:
			next["active_commands"][command_id] = active
	for command_id in expired:
		next["active_commands"].erase(command_id)
	if int(next.get("points", 0)) < int(next.get("max_points", 0)):
		next["recharge_progress"] = float(next.get("recharge_progress", 0.0)) + step
		var recharge_seconds := float(next.get("recharge_seconds", 12.0))
		while float(next.get("recharge_progress", 0.0)) >= recharge_seconds and int(next.get("points", 0)) < int(next.get("max_points", 0)):
			next["recharge_progress"] = float(next.get("recharge_progress", 0.0)) - recharge_seconds
			next["points"] = int(next.get("points", 0)) + 1
	else:
		next["recharge_progress"] = 0.0
	return next


static func effect_for_actor(state: Dictionary, actor_id: String, room_id: String, actor_faction: String = "") -> Dictionary:
	var result := {}
	var sources: Array = []
	for command_id_value in state.get("active_commands", {}).keys():
		var command_id := str(command_id_value)
		var active: Dictionary = state["active_commands"].get(command_id, {})
		var target: Dictionary = active.get("target", {})
		var target_type := str(target.get("type", ""))
		var applies := target_type == "enemy" and str(target.get("id", "")) == actor_id
		if target_type in ["defense_zone", "room"]:
			if command_id in ["rally", "emergency_fallback"]:
				applies = actor_faction == "monster" or actor_faction == ""
			else:
				var target_room_ids: Array = target.get("room_ids", [])
				var room_matches := target_room_ids.has(room_id) if not target_room_ids.is_empty() else str(target.get("room_id", target.get("id", ""))) == room_id
				applies = room_matches and (actor_faction == "monster" or actor_faction == "")
		elif target_type == "facility":
			var linked_room_ids: Array = target.get("linked_room_ids", [])
			var facility_room_matches := linked_room_ids.has(room_id) if not linked_room_ids.is_empty() else str(target.get("room_id", target.get("id", ""))) == room_id
			applies = (
				(actor_faction == "monster" or actor_faction == "")
				and facility_room_matches
			)
		if not applies:
			continue
		for effect_key_value in active.get("effect", {}).keys():
			var effect_key := str(effect_key_value)
			var effect_value = active.get("effect", {}).get(effect_key)
			if effect_value is int or effect_value is float:
				var identity := 1.0 if effect_key.ends_with("_multiplier") else 0.0
				result[effect_key] = float(result.get(effect_key, identity)) * float(effect_value) if effect_key.ends_with("_multiplier") else float(result.get(effect_key, identity)) + float(effect_value)
			else:
				result[effect_key] = effect_value
		sources.append(command_id)
	result["source_commands"] = sources
	return result


static func movement_order_for_actor(
	state: Dictionary,
	_actor_id: String,
	room_id: String,
	actor_faction: String
) -> Dictionary:
	if actor_faction != "monster":
		return {}
	var candidates: Array[Dictionary] = []
	for command_id_value in state.get("active_commands", {}).keys():
		var command_id := str(command_id_value)
		if command_id not in ["rally", "emergency_fallback"]:
			continue
		var active: Dictionary = state.get("active_commands", {}).get(command_id, {})
		var target: Dictionary = active.get("target", {})
		if str(target.get("type", "")) not in ["defense_zone", "room"]:
			continue
		var target_room_id := str(target.get("anchor_room_id", target.get("room_id", target.get("id", ""))))
		if target_room_id == "":
			continue
		var target_room_ids: Array = target.get("room_ids", [])
		candidates.append({
			"command_id": command_id,
			"target_room_id": target_room_id,
			"arrived": target_room_ids.has(room_id) if not target_room_ids.is_empty() else room_id == target_room_id,
			"ai_priority": int(active.get("ai_priority", 9)),
			"remaining_seconds": float(active.get("remaining_seconds", 0.0)),
			"move_attack_policy": str(active.get("effect", {}).get("move_attack_policy", "normal"))
		})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		if int(first.get("ai_priority", 9)) == int(second.get("ai_priority", 9)):
			return str(first.get("command_id", "")) < str(second.get("command_id", ""))
		return int(first.get("ai_priority", 9)) < int(second.get("ai_priority", 9))
	)
	return candidates.front()


static func focus_target_id(state: Dictionary) -> String:
	var active: Dictionary = state.get("active_commands", {}).get("focus", {})
	var target: Dictionary = active.get("target", {})
	return str(target.get("id", "")) if str(target.get("type", "")) == "enemy" else ""


static func active_facility_power(state: Dictionary, facility_key: String) -> float:
	var active: Dictionary = state.get("active_commands", {}).get("activate_facility", {})
	var target: Dictionary = active.get("target", {})
	if str(target.get("type", "")) != "facility":
		return 1.0
	var target_keys := [
		str(target.get("id", "")),
		str(target.get("facility_slot_id", "")),
		str(target.get("facility_instance_id", "")),
		str(target.get("room_id", "")),
		str(target.get("object_id", "")),
		str(target.get("facility_role", ""))
	]
	if not target_keys.has(facility_key):
		return 1.0
	return maxf(1.0, float(active.get("effect", {}).get("facility_power_multiplier", 1.0)))


static func _validated_target(target_type: String, target: Dictionary, battle_plan: Dictionary) -> Dictionary:
	if str(target.get("type", "")) != target_type or str(target.get("id", "")) == "":
		return {}
	var result := target.duplicate(true)
	if target_type == "defense_zone":
		var requested_zone_id := str(target.get("id", ""))
		for zone_value in _defense_zone_contracts(battle_plan):
			if not zone_value is Dictionary:
				continue
			var zone: Dictionary = zone_value
			if str(zone.get("zone_id", zone.get("segment_id", ""))) != requested_zone_id:
				continue
			var anchor_room_id := str(zone.get("anchor_room_id", zone.get("entry_room_id", "")))
			var room_ids: Array = zone.get("room_ids", []).duplicate()
			if anchor_room_id == "" and not room_ids.is_empty():
				anchor_room_id = str(room_ids.front())
			if anchor_room_id == "" or not battle_plan.get("world_anchors", {}).has(anchor_room_id):
				return {}
			result["id"] = requested_zone_id
			result["zone_id"] = requested_zone_id
			result["anchor_room_id"] = anchor_room_id
			result["room_id"] = anchor_room_id
			result["room_ids"] = room_ids
			result["lane_id"] = str(zone.get("lane_id", ""))
			result["world_anchor"] = battle_plan["world_anchors"][anchor_room_id]
			return result
		return {}
	elif target_type == "room":
		var room_id := str(target.get("id", ""))
		if not battle_plan.get("world_anchors", {}).has(room_id):
			return {}
		result["room_id"] = room_id
		result["world_anchor"] = battle_plan["world_anchors"][room_id]
	elif target_type == "facility":
		for value in battle_plan.get("facility_slots", []):
			if not value is Dictionary:
				continue
			var slot: Dictionary = value
			var requested_id := str(target.get("id", ""))
			var slot_id := str(slot.get("slot_id", ""))
			var room_id := str(slot.get("room_id", ""))
			var facility_instance_id := str(slot.get("facility_instance_id", room_id))
			var object_id := str(slot.get("object_id", ""))
			if requested_id not in [slot_id, facility_instance_id, room_id, object_id]:
				continue
			var linked_zone_ids: Array = slot.get("linked_zone_ids", []).duplicate()
			result["id"] = slot_id if slot_id != "" else room_id
			result["facility_slot_id"] = slot_id
			result["facility_instance_id"] = facility_instance_id
			result["room_id"] = room_id
			result["facility_role"] = str(slot.get("facility_role", ""))
			result["object_id"] = object_id
			result["linked_zone_ids"] = linked_zone_ids
			result["linked_room_ids"] = _room_ids_for_zones(linked_zone_ids, battle_plan)
			result["world_anchor"] = slot.get("world_anchor", [])
			return result
		return {}
	elif target_type == "enemy":
		result["world_anchor"] = target.get("world_anchor", [])
	return result


static func _defense_zone_contracts(battle_plan: Dictionary) -> Array:
	var explicit_zones: Array = battle_plan.get("defense_zones", [])
	if not explicit_zones.is_empty():
		return explicit_zones
	var result: Array = []
	for segment_value in battle_plan.get("defense_segments", []):
		if not segment_value is Dictionary:
			continue
		var segment: Dictionary = segment_value
		var zone := segment.duplicate(true)
		zone["zone_id"] = str(segment.get("segment_id", ""))
		zone["anchor_room_id"] = str(segment.get("entry_room_id", ""))
		result.append(zone)
	return result


static func _room_ids_for_zones(zone_ids: Array, battle_plan: Dictionary) -> Array:
	var result: Array = []
	for zone_value in _defense_zone_contracts(battle_plan):
		if not zone_value is Dictionary:
			continue
		var zone: Dictionary = zone_value
		if not zone_ids.has(str(zone.get("zone_id", zone.get("segment_id", "")))):
			continue
		for room_id_value in zone.get("room_ids", []):
			var room_id := str(room_id_value)
			if room_id != "" and not result.has(room_id):
				result.append(room_id)
	return result

static func _result(ok: bool, status: String, state: Dictionary, ledger: Dictionary) -> Dictionary:
	return {"ok": ok, "status": status, "state": state.duplicate(true), "ledger": ledger.duplicate(true)}
