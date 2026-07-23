class_name V20BattleEvidence
extends RefCounted

const PHYSICS_FPS := 60.0
const ROUTE_ORDER := {
	"gate_outpost": 0,
	"spike_corridor": 1,
	"central_battle_room": 2,
	"throne_anteroom": 3,
	"throne": 4
}


static func new_state(day: int, seed: int, board: Dictionary, throne_max_hp: int, monster_start_max_hp: int) -> Dictionary:
	return {
		"day": day,
		"seed": seed,
		"board": board.duplicate(true),
		"frame": 0,
		"events": [],
		"actor_state": {},
		"movement_paths": {},
		"target_history": [],
		"damage_by_actor": {},
		"damage_by_target": {},
		"facility_contribution": {},
		"facility_effect_events": 0,
		"first_engagement_zone": "",
		"first_engagement_frame": -1,
		"frontline_open": -1,
		"frontline_intervals": [],
		"facility_disable_open": {},
		"facility_disable_intervals": {},
		"protection_bypass_open": {},
		"protection_bypass_intervals": [],
		"rear_pressure_open": {},
		"rear_pressure_intervals": [],
		"shield_break_windows": {},
		"shield_breaks": 0,
		"fallback_breach_actors": {},
		"second_phase_leak_actors": {},
		"gold_stolen": 0,
		"escaped_actor_ids": [],
		"throne_max_hp": throne_max_hp,
		"throne_end_hp": throne_max_hp,
		"monster_start_max_hp": monster_start_max_hp,
		"monster_end_hp": monster_start_max_hp,
		"command_events": [],
		"finalized": false,
		"metrics": {}
	}


static func record_spawn(state: Dictionary, actor: Dictionary, frame: int) -> void:
	var actor_id := str(actor.get("actor_id", ""))
	if actor_id == "":
		return
	var snapshot := actor.duplicate(true)
	snapshot["frame"] = frame
	state["actor_state"][actor_id] = snapshot
	_append_event(state, "spawn", frame, snapshot)
	_record_movement_cell(state, snapshot, frame)
	_record_target_change(state, snapshot, frame)


static func sample_frame(state: Dictionary, frame: int, actors: Array[Dictionary]) -> void:
	state["frame"] = frame
	var current_ids: Dictionary = {}
	for actor_value in actors:
		var actor: Dictionary = actor_value
		var actor_id := str(actor.get("actor_id", ""))
		if actor_id == "":
			continue
		current_ids[actor_id] = true
		var previous: Dictionary = state.get("actor_state", {}).get(actor_id, {})
		if previous.is_empty():
			record_spawn(state, actor, frame)
			previous = state.get("actor_state", {}).get(actor_id, {})
		_record_zone_change(state, previous, actor, frame)
		_record_movement_cell(state, actor, frame)
		_record_target_change(state, actor, frame)
		_record_protection_transition(state, previous, actor, frame)
		_record_route_leaks(state, previous, actor, frame)
		state["actor_state"][actor_id] = actor.duplicate(true)
	_update_frontline_interval(state, frame, actors)
	_close_missing_actor_intervals(state, frame, current_ids)


static func record_damage(state: Dictionary, frame: int, attacker: Dictionary, target: Dictionary, amount: int) -> void:
	if amount <= 0:
		return
	var attacker_id := str(attacker.get("actor_id", ""))
	var target_id := str(target.get("actor_id", ""))
	var zone_id := _earlier_zone(str(attacker.get("zone_id", "")), str(target.get("zone_id", "")))
	var event := {
		"actor_id": attacker_id,
		"target_id": target_id,
		"faction": str(attacker.get("faction", "")),
		"target_faction": str(target.get("faction", "")),
		"amount": amount,
		"zone_id": zone_id,
		"world_position": target.get("world_position", []).duplicate()
	}
	_append_event(state, "damage", frame, event)
	state["damage_by_actor"][attacker_id] = int(state.get("damage_by_actor", {}).get(attacker_id, 0)) + amount
	state["damage_by_target"][target_id] = int(state.get("damage_by_target", {}).get(target_id, 0)) + amount
	if str(attacker.get("faction", "")) == "monster":
		state["monster_end_hp"] = int(state.get("monster_end_hp", 0))
	if str(attacker.get("faction", "")) != str(target.get("faction", "")) and state.get("first_engagement_zone", "") == "":
		state["first_engagement_zone"] = zone_id
		state["first_engagement_frame"] = frame
		_append_event(state, "first_engagement", frame, {"zone_id": zone_id, "actor_id": attacker_id, "target_id": target_id})
	if str(attacker.get("unit_id", "")) == "anti_magic_archer" and bool(attacker.get("protected", false)):
		_open_interval(state["rear_pressure_open"], attacker_id, frame)


static func record_heal(state: Dictionary, frame: int, actor: Dictionary, amount: int, facility_id: String = "", placement_id: String = "") -> void:
	if amount <= 0:
		return
	var event := {
		"actor_id": str(actor.get("actor_id", "")),
		"amount": amount,
		"facility_id": facility_id,
		"placement_id": placement_id,
		"zone_id": str(actor.get("zone_id", "")),
		"world_position": actor.get("world_position", []).duplicate(),
		"start_frame": frame,
		"end_frame": frame
	}
	_append_event(state, "heal", frame, event)
	if facility_id != "":
		record_facility_effect(state, frame, placement_id, facility_id, "heal", actor, amount)


static func record_facility_effect(state: Dictionary, frame: int, placement_id: String, facility_id: String, effect_id: String, actor: Dictionary, amount: float = 0.0) -> void:
	if placement_id == "" or facility_id == "":
		return
	var event := {
		"placement_id": placement_id,
		"facility_id": facility_id,
		"effect_id": effect_id,
		"actor_id": str(actor.get("actor_id", "")),
		"amount": amount,
		"zone_id": str(actor.get("zone_id", "")),
		"world_position": actor.get("world_position", []).duplicate(),
		"start_frame": frame,
		"end_frame": frame
	}
	_append_event(state, "facility_effect", frame, event)
	state["facility_effect_events"] = int(state.get("facility_effect_events", 0)) + 1
	var contribution: Dictionary = state.get("facility_contribution", {}).get(placement_id, {})
	contribution[effect_id] = float(contribution.get(effect_id, 0.0)) + maxf(amount, 1.0)
	state["facility_contribution"][placement_id] = contribution


static func record_facility_disable_started(state: Dictionary, frame: int, placement_id: String, facility_id: String, zone_id: String, world_position: Vector2) -> void:
	if placement_id == "" or state.get("facility_disable_open", {}).has(placement_id):
		return
	state["facility_disable_open"][placement_id] = {"start_frame": frame, "facility_id": facility_id, "zone_id": zone_id, "world_position": _position_array(world_position)}
	_append_event(state, "facility_disable_started", frame, {"placement_id": placement_id, "facility_id": facility_id, "zone_id": zone_id, "world_position": _position_array(world_position)})


static func record_facility_disable_ended(state: Dictionary, frame: int, placement_id: String) -> void:
	if not state.get("facility_disable_open", {}).has(placement_id):
		return
	var opened: Dictionary = state["facility_disable_open"].get(placement_id, {})
	var interval := opened.duplicate(true)
	interval["placement_id"] = placement_id
	interval["end_frame"] = frame
	if not state["facility_disable_intervals"].has(placement_id):
		state["facility_disable_intervals"][placement_id] = []
	state["facility_disable_intervals"][placement_id].append(interval)
	state["facility_disable_open"].erase(placement_id)
	_append_event(state, "facility_disable_ended", frame, interval)


static func record_loot(state: Dictionary, frame: int, actor: Dictionary, gold: int) -> void:
	if gold <= 0:
		return
	state["gold_stolen"] = int(state.get("gold_stolen", 0)) + gold
	_append_event(state, "loot", frame, {"actor_id": str(actor.get("actor_id", "")), "amount": gold, "zone_id": str(actor.get("zone_id", "")), "world_position": actor.get("world_position", []).duplicate()})


static func record_escape(state: Dictionary, frame: int, actor: Dictionary) -> void:
	var actor_id := str(actor.get("actor_id", ""))
	if actor_id == "" or state.get("escaped_actor_ids", []).has(actor_id):
		return
	state["escaped_actor_ids"].append(actor_id)
	_append_event(state, "escape", frame, {"actor_id": actor_id, "unit_id": str(actor.get("unit_id", "")), "zone_id": str(actor.get("zone_id", "")), "world_position": actor.get("world_position", []).duplicate()})


static func record_throne_damage(state: Dictionary, frame: int, actor: Dictionary, amount: int, throne_end_hp: int) -> void:
	if amount <= 0:
		return
	state["throne_end_hp"] = throne_end_hp
	_append_event(state, "throne_damage", frame, {"actor_id": str(actor.get("actor_id", "")), "amount": amount, "zone_id": "throne", "world_position": actor.get("world_position", []).duplicate()})


static func record_command(state: Dictionary, frame: int, command_id: String, target: Dictionary, applied_actor_ids: Array, point_cost: int) -> void:
	var event := {"command_id": command_id, "target": target.duplicate(true), "applied_actor_ids": applied_actor_ids.duplicate(), "point_cost": point_cost}
	state["command_events"].append(event.duplicate(true))
	_append_event(state, "command", frame, event)


static func finalize(state: Dictionary, end_frame: int, actors: Array[Dictionary], throne_end_hp: int) -> Dictionary:
	if bool(state.get("finalized", false)):
		return state.get("metrics", {}).duplicate(true)
	sample_frame(state, end_frame, actors)
	_close_all_open_intervals(state, end_frame)
	state["throne_end_hp"] = throne_end_hp
	var monster_end_hp := 0
	for actor in actors:
		if str(actor.get("faction", "")) == "monster":
			monster_end_hp += maxi(0, int(actor.get("hp", 0)))
	state["monster_end_hp"] = monster_end_hp
	var movement_rows: Dictionary = {}
	var movement_hashes: Dictionary = {}
	var total_cells := 0
	var actor_ids: Array = state.get("movement_paths", {}).keys()
	actor_ids.sort()
	for actor_id_value in actor_ids:
		var actor_id := str(actor_id_value)
		var rows: Array = state.get("movement_paths", {}).get(actor_id, []).duplicate(true)
		movement_rows[actor_id] = rows
		movement_hashes[actor_id] = JSON.stringify(rows).sha256_text()
		total_cells += rows.size()
	var disable_seconds: Dictionary = {}
	var max_disable_seconds := 0.0
	for placement_id_value in state.get("facility_disable_intervals", {}).keys():
		var placement_id := str(placement_id_value)
		var seconds := _interval_seconds(state["facility_disable_intervals"].get(placement_id, []), false)
		disable_seconds[placement_id] = seconds
		for interval in state["facility_disable_intervals"].get(placement_id, []):
			max_disable_seconds = maxf(max_disable_seconds, float(int(interval.get("end_frame", end_frame)) - int(interval.get("start_frame", end_frame))) / PHYSICS_FPS)
	var metrics := {
		"first_engagement_zone": str(state.get("first_engagement_zone", "")),
		"first_engagement_frame": int(state.get("first_engagement_frame", -1)),
		"movement_path_fingerprint": JSON.stringify(movement_hashes).sha256_text(),
		"movement_path_hashes": movement_hashes,
		"movement_path_cells": total_cells,
		"movement_paths": movement_rows,
		"target_history": state.get("target_history", []).duplicate(true),
		"frontline_hold_seconds": _interval_seconds(state.get("frontline_intervals", []), true),
		"facility_disabled_seconds": disable_seconds,
		"max_contiguous_facility_disabled_seconds": max_disable_seconds,
		"rear_pressure_seconds": _interval_seconds(state.get("rear_pressure_intervals", []), true),
		"protection_bypass_seconds": _interval_seconds(state.get("protection_bypass_intervals", []), true),
		"shield_breaks": int(state.get("shield_breaks", 0)),
		"fallback_breaches": state.get("fallback_breach_actors", {}).size(),
		"second_phase_leaks": state.get("second_phase_leak_actors", {}).size(),
		"gold_stolen": int(state.get("gold_stolen", 0)),
		"escaped_actor_ids": state.get("escaped_actor_ids", []).duplicate(),
		"escape_events": state.get("escaped_actor_ids", []).size(),
		"throne_max_hp": int(state.get("throne_max_hp", 0)),
		"throne_damage": maxi(0, int(state.get("throne_max_hp", 0)) - throne_end_hp),
		"monster_damage_total": _monster_damage_total(state),
		"monster_start_max_hp": int(state.get("monster_start_max_hp", 0)),
		"monster_end_hp": monster_end_hp,
		"facility_effect_events": int(state.get("facility_effect_events", 0)),
		"facility_contribution": state.get("facility_contribution", {}).duplicate(true),
		"damage_by_actor": state.get("damage_by_actor", {}).duplicate(true),
		"event_count": state.get("events", []).size(),
		"event_ledger": state.get("events", []).duplicate(true),
		"command_events": state.get("command_events", []).duplicate(true)
	}
	state["metrics"] = metrics.duplicate(true)
	state["finalized"] = true
	return metrics


static func causal_difference(a: Dictionary, d: Dictionary) -> Dictionary:
	var path_changed := str(a.get("movement_path_fingerprint", "")) != str(d.get("movement_path_fingerprint", "")) or int(a.get("movement_path_cells", 0)) != int(d.get("movement_path_cells", 0))
	var structural := str(a.get("first_engagement_zone", "")) != str(d.get("first_engagement_zone", "")) or path_changed or _goal_history(a) != _goal_history(d)
	var hp_base := maxi(1, int(a.get("monster_start_max_hp", d.get("monster_start_max_hp", 1))))
	var result_changes := {
		"frontline_hold_2s": absf(float(a.get("frontline_hold_seconds", 0.0)) - float(d.get("frontline_hold_seconds", 0.0))) >= 2.0,
		"throne_hp_10pct": absf(float(a.get("throne_damage", 0)) - float(d.get("throne_damage", 0))) / float(maxi(1, int(a.get("throne_max_hp", 1500)))) >= 0.10,
		"gold_stolen": int(a.get("gold_stolen", 0)) != int(d.get("gold_stolen", 0)),
		"facility_disable_2s": absf(float(a.get("max_contiguous_facility_disabled_seconds", 0.0)) - float(d.get("max_contiguous_facility_disabled_seconds", 0.0))) >= 2.0,
		"rear_pressure_2s": absf(float(a.get("rear_pressure_seconds", 0.0)) - float(d.get("rear_pressure_seconds", 0.0))) >= 2.0,
		"fallback_breach": int(a.get("fallback_breaches", 0)) != int(d.get("fallback_breaches", 0)),
		"monster_10pct": (absf(float(a.get("monster_damage_total", 0)) - float(d.get("monster_damage_total", 0))) / float(hp_base) >= 0.10 or absf(float(a.get("monster_end_hp", 0)) - float(d.get("monster_end_hp", 0))) / float(hp_base) >= 0.10)
	}
	var consequential := result_changes.values().any(func(value): return bool(value))
	return {"pass": structural and consequential, "structural": structural, "consequential": consequential, "path_changed": path_changed, "result_changes": result_changes}


static func zone_for_position(board: Dictionary, world_position: Vector2) -> String:
	var matches: Array[String] = []
	for zone_id_value in board.get("zones", {}).keys():
		var zone_id := str(zone_id_value)
		var bounds: Array = board.get("zones", {}).get(zone_id, {}).get("combat_bounds", [])
		if bounds.size() == 4 and Rect2(Vector2(float(bounds[0]), float(bounds[1])), Vector2(float(bounds[2]), float(bounds[3]))).has_point(world_position):
			matches.append(zone_id)
	if matches.is_empty():
		return ""
	matches.sort_custom(func(a: String, b: String): return int(ROUTE_ORDER.get(a, 999)) < int(ROUTE_ORDER.get(b, 999)))
	return matches[0]


static func logical_cell(board: Dictionary, world_position: Vector2) -> Vector2i:
	var projection: Dictionary = board.get("spatial_header", {}).get("world_projection", {})
	var origin_values: Array = projection.get("origin", [0.0, 0.0])
	var basis_x_values: Array = projection.get("basis_x", [1.0, 0.0])
	var basis_y_values: Array = projection.get("basis_y", [0.0, 1.0])
	var origin := Vector2(float(origin_values[0]), float(origin_values[1]))
	var basis_x := Vector2(float(basis_x_values[0]), float(basis_x_values[1]))
	var basis_y := Vector2(float(basis_y_values[0]), float(basis_y_values[1]))
	var relative := world_position - origin
	var determinant := basis_x.x * basis_y.y - basis_x.y * basis_y.x
	if is_zero_approx(determinant):
		return Vector2i(roundi(world_position.x), roundi(world_position.y))
	var cell_x := (relative.x * basis_y.y - relative.y * basis_y.x) / determinant
	var cell_y := (basis_x.x * relative.y - basis_x.y * relative.x) / determinant
	return Vector2i(roundi(cell_x), roundi(cell_y))


static func _record_zone_change(state: Dictionary, previous: Dictionary, actor: Dictionary, frame: int) -> void:
	var before := str(previous.get("zone_id", ""))
	var after := str(actor.get("zone_id", ""))
	if before == after:
		return
	if before != "":
		_append_event(state, "zone_exit", frame, {"actor_id": str(actor.get("actor_id", "")), "zone_id": before, "world_position": actor.get("world_position", []).duplicate()})
	if after != "":
		_append_event(state, "zone_enter", frame, {"actor_id": str(actor.get("actor_id", "")), "zone_id": after, "world_position": actor.get("world_position", []).duplicate()})


static func _record_movement_cell(state: Dictionary, actor: Dictionary, frame: int) -> void:
	var actor_id := str(actor.get("actor_id", ""))
	var world: Array = actor.get("world_position", [])
	if actor_id == "" or world.size() != 2:
		return
	var cell := logical_cell(state.get("board", {}), Vector2(float(world[0]), float(world[1])))
	var row := [frame, cell.x, cell.y, str(actor.get("zone_id", ""))]
	if not state["movement_paths"].has(actor_id):
		state["movement_paths"][actor_id] = []
	var rows: Array = state["movement_paths"][actor_id]
	if not rows.is_empty() and int(rows[-1][1]) == cell.x and int(rows[-1][2]) == cell.y and str(rows[-1][3]) == str(row[3]):
		return
	rows.append(row)


static func _record_target_change(state: Dictionary, actor: Dictionary, frame: int) -> void:
	var actor_id := str(actor.get("actor_id", ""))
	var target_id := str(actor.get("target_id", ""))
	var goal_zone := str(actor.get("goal_zone", ""))
	var history: Array = state.get("target_history", [])
	for index in range(history.size() - 1, -1, -1):
		var prior: Array = history[index]
		if str(prior[1]) == actor_id:
			if str(prior[2]) == target_id and str(prior[3]) == goal_zone:
				return
			break
	history.append([frame, actor_id, target_id, goal_zone])


static func _record_protection_transition(state: Dictionary, previous: Dictionary, actor: Dictionary, frame: int) -> void:
	var actor_id := str(actor.get("actor_id", ""))
	var protected := bool(actor.get("protected", false))
	var targetable := bool(actor.get("targetable", true))
	var bypass := protected and targetable
	if bypass:
		_open_interval(state["protection_bypass_open"], actor_id, frame)
		var window_id := str(actor.get("protection_window_id", "default"))
		var key := "%s|%s" % [actor_id, window_id]
		if not state["shield_break_windows"].has(key):
			state["shield_break_windows"][key] = true
			state["shield_breaks"] = int(state.get("shield_breaks", 0)) + 1
			_append_event(state, "shield_break", frame, {"actor_id": actor_id, "zone_id": str(actor.get("zone_id", "")), "world_position": actor.get("world_position", []).duplicate(), "effect_window": window_id})
	else:
		_close_named_interval(state["protection_bypass_open"], state["protection_bypass_intervals"], actor_id, frame)
	if str(actor.get("unit_id", "")) == "anti_magic_archer" and (not protected or not bool(actor.get("alive", false))):
		_close_named_interval(state["rear_pressure_open"], state["rear_pressure_intervals"], actor_id, frame)


static func _record_route_leaks(state: Dictionary, previous: Dictionary, actor: Dictionary, frame: int) -> void:
	if str(actor.get("faction", "")) != "enemy":
		return
	var actor_id := str(actor.get("actor_id", ""))
	var before := str(previous.get("zone_id", ""))
	var after := str(actor.get("zone_id", ""))
	if before == "throne_anteroom" and after == "throne" and not state["fallback_breach_actors"].has(actor_id):
		state["fallback_breach_actors"][actor_id] = true
		_append_event(state, "breach", frame, {"actor_id": actor_id, "from_zone": before, "zone_id": after, "world_position": actor.get("world_position", []).duplicate()})
	if int(state.get("day", 0)) == 5 and bool(actor.get("second_phase", false)) and after == "throne_anteroom" and before != after and not state["second_phase_leak_actors"].has(actor_id):
		state["second_phase_leak_actors"][actor_id] = true
		_append_event(state, "second_phase_leak", frame, {"actor_id": actor_id, "zone_id": after, "world_position": actor.get("world_position", []).duplicate()})


static func _update_frontline_interval(state: Dictionary, frame: int, actors: Array[Dictionary]) -> void:
	var zone_id := str(state.get("first_engagement_zone", ""))
	if zone_id == "":
		return
	var monsters := 0
	var enemies := 0
	for actor in actors:
		if not bool(actor.get("alive", false)) or not bool(actor.get("attackable", true)) or str(actor.get("zone_id", "")) != zone_id:
			continue
		if str(actor.get("faction", "")) == "monster":
			monsters += 1
		elif str(actor.get("faction", "")) == "enemy":
			enemies += 1
	if monsters > 0 and enemies > 0:
		if int(state.get("frontline_open", -1)) < 0:
			state["frontline_open"] = frame
	elif int(state.get("frontline_open", -1)) >= 0:
		state["frontline_intervals"].append({"start_frame": int(state.get("frontline_open", frame)), "end_frame": frame})
		state["frontline_open"] = -1


static func _close_missing_actor_intervals(state: Dictionary, frame: int, current_ids: Dictionary) -> void:
	for actor_id_value in state.get("protection_bypass_open", {}).keys().duplicate():
		var actor_id := str(actor_id_value)
		if not current_ids.has(actor_id):
			_close_named_interval(state["protection_bypass_open"], state["protection_bypass_intervals"], actor_id, frame)
	for actor_id_value in state.get("rear_pressure_open", {}).keys().duplicate():
		var actor_id := str(actor_id_value)
		if not current_ids.has(actor_id):
			_close_named_interval(state["rear_pressure_open"], state["rear_pressure_intervals"], actor_id, frame)


static func _close_all_open_intervals(state: Dictionary, frame: int) -> void:
	if int(state.get("frontline_open", -1)) >= 0:
		state["frontline_intervals"].append({"start_frame": int(state.get("frontline_open", frame)), "end_frame": frame})
		state["frontline_open"] = -1
	for placement_id_value in state.get("facility_disable_open", {}).keys().duplicate():
		record_facility_disable_ended(state, frame, str(placement_id_value))
	for actor_id_value in state.get("protection_bypass_open", {}).keys().duplicate():
		_close_named_interval(state["protection_bypass_open"], state["protection_bypass_intervals"], str(actor_id_value), frame)
	for actor_id_value in state.get("rear_pressure_open", {}).keys().duplicate():
		_close_named_interval(state["rear_pressure_open"], state["rear_pressure_intervals"], str(actor_id_value), frame)


static func _open_interval(open_intervals: Dictionary, actor_id: String, frame: int) -> void:
	if not open_intervals.has(actor_id):
		open_intervals[actor_id] = frame


static func _close_named_interval(open_intervals: Dictionary, closed_intervals: Array, actor_id: String, frame: int) -> void:
	if not open_intervals.has(actor_id):
		return
	closed_intervals.append({"actor_id": actor_id, "start_frame": int(open_intervals.get(actor_id, frame)), "end_frame": frame})
	open_intervals.erase(actor_id)


static func _interval_seconds(intervals: Array, union_over_actors: bool) -> float:
	if intervals.is_empty():
		return 0.0
	var normalized: Array[Vector2i] = []
	for interval in intervals:
		normalized.append(Vector2i(int(interval.get("start_frame", 0)), int(interval.get("end_frame", 0))))
	normalized.sort_custom(func(a: Vector2i, b: Vector2i): return a.x < b.x or (a.x == b.x and a.y < b.y))
	if not union_over_actors:
		var total := 0
		for interval in normalized:
			total += maxi(0, interval.y - interval.x)
		return float(total) / PHYSICS_FPS
	var union_frames := 0
	var start := normalized[0].x
	var finish := normalized[0].y
	for index in range(1, normalized.size()):
		var interval := normalized[index]
		if interval.x <= finish:
			finish = maxi(finish, interval.y)
		else:
			union_frames += maxi(0, finish - start)
			start = interval.x
			finish = interval.y
	union_frames += maxi(0, finish - start)
	return float(union_frames) / PHYSICS_FPS


static func _monster_damage_total(state: Dictionary) -> int:
	var total := 0
	for actor_id_value in state.get("damage_by_actor", {}).keys():
		var actor_id := str(actor_id_value)
		var actor: Dictionary = state.get("actor_state", {}).get(actor_id, {})
		if str(actor.get("faction", "")) == "monster":
			total += int(state.get("damage_by_actor", {}).get(actor_id, 0))
	return total


static func _goal_history(metrics: Dictionary) -> Array[String]:
	var goals: Array[String] = []
	for row in metrics.get("target_history", []):
		var goal := str(row[3])
		if goal != "" and (goals.is_empty() or goals[-1] != goal):
			goals.append(goal)
	return goals


static func _earlier_zone(a: String, b: String) -> String:
	if a == "":
		return b
	if b == "":
		return a
	return a if int(ROUTE_ORDER.get(a, 999)) <= int(ROUTE_ORDER.get(b, 999)) else b


static func _append_event(state: Dictionary, event_type: String, frame: int, details: Dictionary) -> void:
	var event := details.duplicate(true)
	event["type"] = event_type
	event["frame"] = frame
	event["at_seconds"] = float(frame) / PHYSICS_FPS
	state["events"].append(event)


static func _position_array(position: Vector2) -> Array[float]:
	return [position.x, position.y]
