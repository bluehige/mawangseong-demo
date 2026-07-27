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
		"directive_patch": _directive_patch(definition, normalized_target),
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


static func effect_for_actor(state: Dictionary, actor_id: String, room_id: String) -> Dictionary:
	var result := {}
	var sources: Array = []
	for command_id_value in state.get("active_commands", {}).keys():
		var command_id := str(command_id_value)
		var active: Dictionary = state["active_commands"].get(command_id, {})
		var target: Dictionary = active.get("target", {})
		var applies := (
			(str(target.get("type", "")) == "enemy" and str(target.get("id", "")) == actor_id)
			or (str(target.get("type", "")) in ["room", "facility"] and str(target.get("room_id", target.get("id", ""))) == room_id)
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


static func _validated_target(target_type: String, target: Dictionary, battle_plan: Dictionary) -> Dictionary:
	if str(target.get("type", "")) != target_type or str(target.get("id", "")) == "":
		return {}
	var result := target.duplicate(true)
	if target_type == "room":
		var room_id := str(target.get("id", ""))
		if not battle_plan.get("world_anchors", {}).has(room_id):
			return {}
		result["room_id"] = room_id
		result["world_anchor"] = battle_plan["world_anchors"][room_id]
	elif target_type == "facility":
		for value in battle_plan.get("facility_slots", []):
			if value is Dictionary and str(value.get("room_id", "")) == str(target.get("id", "")):
				result["room_id"] = str(value.get("room_id", ""))
				result["facility_role"] = str(value.get("facility_role", ""))
				result["object_id"] = str(value.get("object_id", ""))
				result["world_anchor"] = value.get("world_anchor", [])
				return result
		return {}
	elif target_type == "enemy":
		result["world_anchor"] = target.get("world_anchor", [])
	return result


static func _directive_patch(definition: Dictionary, target: Dictionary) -> Dictionary:
	var patch: Dictionary = definition.get("directive_patch", {}).duplicate(true)
	if patch.has("room_directive"):
		patch["room_id"] = str(target.get("room_id", target.get("id", "")))
	return patch


static func _result(ok: bool, status: String, state: Dictionary, ledger: Dictionary) -> Dictionary:
	return {"ok": ok, "status": status, "state": state.duplicate(true), "ledger": ledger.duplicate(true)}
