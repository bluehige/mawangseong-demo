class_name V122SaveProgressionAdapter
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_COMMAND_SETTINGS := {
	"max_points": 3,
	"initial_points": 3,
	"recharge_seconds": 12.0,
	"preferred_commands": ["rally", "focus", "activate_facility", "emergency_fallback"]
}
const DEFAULT_UI_STATE := {
	"management_context_collapsed": false,
	"result_details_collapsed": false
}


static func build(
	battle_plan: Dictionary,
	last_confirmed_placements: Dictionary = {},
	retry_snapshot: Dictionary = {},
	command_settings: Dictionary = {},
	ui_state: Dictionary = {}
) -> Dictionary:
	var plan := battle_plan.duplicate(true)
	var current_placements := _placements_from_plan(plan)
	var confirmed := last_confirmed_placements.duplicate(true)
	if confirmed.is_empty():
		confirmed = current_placements.duplicate(true)
	else:
		confirmed = _normalize_placement_snapshot(confirmed, plan)
	var normalized_retry := _normalize_retry_snapshot(retry_snapshot, plan)
	var result := {
		"schema_version": SCHEMA_VERSION,
		"battle_plan": plan,
		"connector_state": _connector_state_from_plan(plan),
		"facility_placements": current_placements.get("facility_placements", []).duplicate(true),
		"monster_placements": current_placements.get("monster_placements", []).duplicate(true),
		"last_confirmed_placements": confirmed,
		"retry_snapshot": normalized_retry,
		"command_settings": _normalize_command_settings(command_settings),
		"ui_state": _normalize_ui_state(ui_state)
	}
	return result


static func normalize(value, fallback_battle_plan: Dictionary = {}) -> Dictionary:
	if not value is Dictionary:
		return build(fallback_battle_plan)
	var source: Dictionary = value
	var plan: Dictionary = source.get("battle_plan", {}).duplicate(true) if source.get("battle_plan") is Dictionary else fallback_battle_plan.duplicate(true)
	var result := build(
		plan,
		source.get("last_confirmed_placements", {}) if source.get("last_confirmed_placements") is Dictionary else {},
		source.get("retry_snapshot", {}) if source.get("retry_snapshot") is Dictionary else {},
		source.get("command_settings", {}) if source.get("command_settings") is Dictionary else {},
		source.get("ui_state", {}) if source.get("ui_state") is Dictionary else {}
	)
	var contract_plan := fallback_battle_plan if not fallback_battle_plan.is_empty() else plan
	result["connector_state"] = _normalize_connector_state(
		source.get("connector_state", {}) if source.get("connector_state") is Dictionary else {},
		contract_plan
	)
	if source.get("facility_placements") is Array:
		result["facility_placements"] = _normalize_facility_placements(
			source.get("facility_placements", []),
			plan,
			contract_plan
		)
	if source.get("monster_placements") is Array:
		result["monster_placements"] = _normalize_monster_placements(
			source.get("monster_placements", []),
			plan,
			contract_plan
		)
	if source.get("last_confirmed_placements") is Dictionary:
		result["last_confirmed_placements"] = _normalize_placement_snapshot(
			source.get("last_confirmed_placements", {}),
			plan,
			contract_plan
		)
	if source.get("retry_snapshot") is Dictionary:
		result["retry_snapshot"] = _normalize_retry_snapshot(
			source.get("retry_snapshot", {}),
			plan,
			contract_plan
		)
	return result


static func capture_confirmation(battle_plan: Dictionary, day: int, global_directive: String, room_directives: Dictionary) -> Dictionary:
	var placements := _placements_from_plan(battle_plan)
	var connector_state := _connector_state_from_plan(battle_plan)
	return {
		"connector_state": connector_state.duplicate(true),
		"last_confirmed_placements": placements.duplicate(true),
		"retry_snapshot": {
			"day": day,
			"layout_id": str(battle_plan.get("layout_id", "")),
			"layout_fingerprint": str(battle_plan.get("layout_fingerprint", "")),
			"connector_state": connector_state.duplicate(true),
			"facility_placements": placements.get("facility_placements", []).duplicate(true),
			"monster_placements": placements.get("monster_placements", []).duplicate(true),
			"global_directive": global_directive,
			"room_directives": room_directives.duplicate(true)
		}
	}


static func validate_optional_payload(payload: Dictionary) -> String:
	if not payload.has("v122_battle_plan"):
		return ""
	if not payload.get("v122_battle_plan") is Dictionary:
		return "v1.2.2 전투 계획 저장 형식이 올바르지 않습니다."
	var state: Dictionary = payload.get("v122_battle_plan", {})
	if not _is_number(state.get("schema_version")) or int(state.get("schema_version")) != SCHEMA_VERSION:
		return "v1.2.2 전투 계획 schema가 올바르지 않습니다."
	var battle_plan = state.get("battle_plan")
	if not battle_plan is Dictionary or battle_plan.is_empty():
		return "v1.2.2 battle plan snapshot이 없습니다."
	var plan_error := _validate_battle_plan(battle_plan)
	if plan_error != "":
		return plan_error
	if state.has("connector_state") and not _valid_connector_state(state.get("connector_state")):
		return "v1.2.2 connector state 형식이 올바르지 않습니다."
	for array_key in ["facility_placements", "monster_placements"]:
		if not _array_of_dictionaries(state.get(array_key)):
			return "v1.2.2 배치 목록 형식이 올바르지 않습니다: %s" % array_key
	var placement_error := _validate_optional_placement_ids(
		state.get("facility_placements", []),
		state.get("monster_placements", [])
	)
	if placement_error != "":
		return placement_error
	var confirmed = state.get("last_confirmed_placements")
	if not confirmed is Dictionary:
		return "v1.2.2 마지막 확정 배치 형식이 올바르지 않습니다."
	for array_key in ["facility_placements", "monster_placements"]:
		if not _array_of_dictionaries(confirmed.get(array_key)):
			return "v1.2.2 마지막 확정 배치 목록이 올바르지 않습니다: %s" % array_key
	placement_error = _validate_optional_placement_ids(
		confirmed.get("facility_placements", []),
		confirmed.get("monster_placements", [])
	)
	if placement_error != "":
		return placement_error
	if not (confirmed.get("layout_fingerprint") is String):
		return "v1.2.2 마지막 확정 배치 fingerprint가 올바르지 않습니다."
	var retry = state.get("retry_snapshot")
	if not retry is Dictionary:
		return "v1.2.2 retry snapshot 형식이 올바르지 않습니다."
	if not retry.is_empty():
		for numeric_key in ["day"]:
			if not _is_number(retry.get(numeric_key)) or int(retry.get(numeric_key)) < 1 or int(retry.get(numeric_key)) > 30:
				return "v1.2.2 retry 날짜가 올바르지 않습니다."
		for string_key in ["layout_id", "layout_fingerprint", "global_directive"]:
			if not retry.get(string_key) is String:
				return "v1.2.2 retry 문구 형식이 올바르지 않습니다: %s" % string_key
		for dictionary_key in ["room_directives"]:
			if not retry.get(dictionary_key) is Dictionary:
				return "v1.2.2 retry 지침 형식이 올바르지 않습니다."
		if retry.has("connector_state") and not _valid_connector_state(retry.get("connector_state")):
			return "v1.2.2 retry connector state 형식이 올바르지 않습니다."
		for array_key in ["facility_placements", "monster_placements"]:
			if not _array_of_dictionaries(retry.get(array_key)):
				return "v1.2.2 retry 배치 형식이 올바르지 않습니다: %s" % array_key
		placement_error = _validate_optional_placement_ids(
			retry.get("facility_placements", []),
			retry.get("monster_placements", [])
		)
		if placement_error != "":
			return placement_error
	var settings = state.get("command_settings")
	if not settings is Dictionary:
		return "v1.2.2 명령 설정 형식이 올바르지 않습니다."
	for numeric_key in ["max_points", "initial_points", "recharge_seconds"]:
		if not _is_number(settings.get(numeric_key)) or float(settings.get(numeric_key)) <= 0.0:
			return "v1.2.2 명령 설정 수치가 올바르지 않습니다: %s" % numeric_key
	if int(settings.get("initial_points")) > int(settings.get("max_points")):
		return "v1.2.2 초기 명령 포인트가 최대치를 초과합니다."
	if not _string_array(settings.get("preferred_commands")):
		return "v1.2.2 선호 명령 목록 형식이 올바르지 않습니다."
	var ui_state = state.get("ui_state")
	if not ui_state is Dictionary:
		return "v1.2.2 UI 상태 형식이 올바르지 않습니다."
	for bool_key in DEFAULT_UI_STATE.keys():
		if not ui_state.get(bool_key) is bool:
			return "v1.2.2 UI 접기 상태가 올바르지 않습니다: %s" % bool_key
	return ""


static func apply_retry_snapshot(
	retry_snapshot: Dictionary,
	rooms: Dictionary,
	monster_roster: Dictionary,
	global_directive: String,
	room_directives: Dictionary,
	battle_plan: Dictionary = {}
) -> Dictionary:
	if retry_snapshot.is_empty():
		return {
			"rooms": rooms.duplicate(true),
			"monster_roster": monster_roster.duplicate(true),
			"global_directive": global_directive,
			"room_directives": room_directives.duplicate(true),
			"connector_state": _connector_state_from_plan(battle_plan)
		}
	var next_rooms := rooms.duplicate(true)
	for value in retry_snapshot.get("facility_placements", []):
		if not value is Dictionary:
			continue
		var room_id := str(value.get("room_id", ""))
		if room_id == "":
			room_id = str(value.get("facility_instance_id", ""))
		if room_id == "":
			var facility_slot_id := str(value.get("facility_slot_id", value.get("slot_id", "")))
			var slot_index: Dictionary = _facility_slot_index(battle_plan)
			room_id = str(slot_index.get("by_id", {}).get(facility_slot_id, {}).get("room_id", ""))
		var role := str(value.get("facility_role", ""))
		if next_rooms.has(room_id) and role != "":
			next_rooms[room_id]["facility_role"] = role
	var next_roster := monster_roster.duplicate(true)
	for value in retry_snapshot.get("monster_placements", []):
		if not value is Dictionary:
			continue
		var monster_id := str(value.get("monster_instance_id", ""))
		var room_id := str(value.get("room_id", ""))
		if not next_roster.has(monster_id):
			continue
		var defense_zone_id := str(value.get("defense_zone_id", value.get("assigned_defense_zone_id", "")))
		if room_id == "" and defense_zone_id != "":
			var zone_index: Dictionary = _defense_zone_index(battle_plan)
			room_id = str(zone_index.get("by_id", {}).get(defense_zone_id, {}).get("anchor_room_id", ""))
		if room_id != "" and next_rooms.has(room_id):
			next_roster[monster_id]["room"] = room_id
		if defense_zone_id != "":
			next_roster[monster_id]["defense_zone_id"] = defense_zone_id
			next_roster[monster_id]["assigned_defense_zone_id"] = defense_zone_id
		var placement_slot_id := str(value.get("placement_slot_id", value.get("slot_id", "")))
		if placement_slot_id != "":
			next_roster[monster_id]["placement_slot_id"] = placement_slot_id
	return {
		"rooms": next_rooms,
		"monster_roster": next_roster,
		"global_directive": str(retry_snapshot.get("global_directive", global_directive)),
		"room_directives": retry_snapshot.get("room_directives", room_directives).duplicate(true),
		"connector_state": _normalize_connector_state(
			retry_snapshot.get("connector_state", {})
				if retry_snapshot.get("connector_state") is Dictionary
				else _connector_state_from_plan(battle_plan),
			battle_plan
		)
	}


static func _placements_from_plan(battle_plan: Dictionary) -> Dictionary:
	var facility_placements = battle_plan.get("facility_placements")
	if not _has_facility_state_placements(facility_placements):
		facility_placements = battle_plan.get("facility_slots", [])
	return {
		"layout_id": str(battle_plan.get("layout_id", "")),
		"layout_fingerprint": str(battle_plan.get("layout_fingerprint", "")),
		"facility_placements": _normalize_facility_placements(facility_placements, battle_plan),
		"monster_placements": _normalize_monster_placements(
			battle_plan.get("monster_placements", []),
			battle_plan
		)
	}


static func _has_facility_state_placements(value) -> bool:
	if not value is Array or value.is_empty():
		return false
	for entry in value:
		if not entry is Dictionary:
			continue
		if str(entry.get("facility_slot_id", "")) != "" or str(entry.get("facility_role", "")) != "":
			return true
	return false


static func _normalize_placement_snapshot(
	value: Dictionary,
	plan: Dictionary,
	fallback_plan: Dictionary = {}
) -> Dictionary:
	var result := value.duplicate(true)
	if result.get("facility_placements") is Array:
		result["facility_placements"] = _normalize_facility_placements(
			result.get("facility_placements", []),
			plan,
			fallback_plan
		)
	if result.get("monster_placements") is Array:
		result["monster_placements"] = _normalize_monster_placements(
			result.get("monster_placements", []),
			plan,
			fallback_plan
		)
	return result


static func _normalize_retry_snapshot(
	value: Dictionary,
	plan: Dictionary,
	fallback_plan: Dictionary = {}
) -> Dictionary:
	if value.is_empty():
		return {}
	var result := _normalize_placement_snapshot(value, plan, fallback_plan)
	var contract_plan := fallback_plan if not fallback_plan.is_empty() else plan
	result["connector_state"] = _normalize_connector_state(
		value.get("connector_state", {}) if value.get("connector_state") is Dictionary else {},
		contract_plan
	)
	return result


static func _connector_state_from_plan(plan: Dictionary) -> Dictionary:
	var connector_value = plan.get("defender_connector", {})
	if not connector_value is Dictionary or connector_value.is_empty():
		return {}
	var connector: Dictionary = connector_value
	var connector_id := str(connector.get("connector_id", ""))
	if connector_id == "":
		return {}
	var built := bool(connector.get("built", false))
	return {
		"connector_id": connector_id,
		"built": built,
		"built_day": int(connector.get("built_day", 0)) if built else 0
	}


static func _normalize_connector_state(value: Dictionary, plan: Dictionary) -> Dictionary:
	var expected := _connector_state_from_plan(plan)
	if expected.is_empty():
		return {}
	var connector_id := str(expected.get("connector_id", ""))
	var state_id := str(value.get("connector_id", ""))
	var built := state_id == connector_id and bool(value.get("built", false))
	return {
		"connector_id": connector_id,
		"built": built,
		"built_day": clampi(int(value.get("built_day", 0)), 0, 30) if built else 0
	}


static func _normalize_facility_placements(
	values,
	plan: Dictionary,
	fallback_plan: Dictionary = {}
) -> Array:
	if not values is Array:
		return []
	var slot_index := _facility_slot_index(plan, fallback_plan)
	var by_id: Dictionary = slot_index.get("by_id", {})
	var by_room: Dictionary = slot_index.get("by_room", {})
	var result: Array = []
	for value in values:
		if not value is Dictionary:
			continue
		var placement: Dictionary = value.duplicate(true)
		var room_id := str(placement.get("room_id", placement.get("facility_instance_id", "")))
		if str(placement.get("room_id", "")) == "" and room_id != "":
			placement["room_id"] = room_id
		var facility_slot_id := str(placement.get("facility_slot_id", ""))
		if facility_slot_id == "" and by_room.has(room_id):
			facility_slot_id = str(by_room.get(room_id, ""))
		if facility_slot_id == "":
			var legacy_slot_id := str(placement.get("slot_id", ""))
			if by_id.has(legacy_slot_id):
				facility_slot_id = legacy_slot_id
		if facility_slot_id != "":
			placement["facility_slot_id"] = facility_slot_id
			if room_id == "" and by_id.has(facility_slot_id):
				room_id = str(by_id.get(facility_slot_id, {}).get("room_id", ""))
				placement["room_id"] = room_id
		if str(placement.get("facility_instance_id", "")) == "" and room_id != "":
			placement["facility_instance_id"] = room_id
		result.append(placement)
	return result


static func _normalize_monster_placements(
	values,
	plan: Dictionary,
	fallback_plan: Dictionary = {}
) -> Array:
	if not values is Array:
		return []
	var zone_index := _defense_zone_index(plan, fallback_plan)
	var by_id: Dictionary = zone_index.get("by_id", {})
	var by_room: Dictionary = zone_index.get("by_room", {})
	var result: Array = []
	for value in values:
		if not value is Dictionary:
			continue
		var placement: Dictionary = value.duplicate(true)
		var room_id := str(placement.get("room_id", ""))
		var defense_zone_id := str(
			placement.get("defense_zone_id", placement.get("assigned_defense_zone_id", ""))
		)
		if defense_zone_id == "":
			defense_zone_id = str(by_room.get(room_id, ""))
		if defense_zone_id != "":
			placement["defense_zone_id"] = defense_zone_id
			placement["assigned_defense_zone_id"] = defense_zone_id
			if room_id == "" and by_id.has(defense_zone_id):
				placement["room_id"] = str(by_id.get(defense_zone_id, {}).get("anchor_room_id", ""))
			_normalize_zone_slot_id(placement, defense_zone_id)
		result.append(placement)
	return result


static func _facility_slot_index(plan: Dictionary, fallback_plan: Dictionary = {}) -> Dictionary:
	var by_id := {}
	var by_room := {}
	for source_plan in [plan, fallback_plan]:
		if not source_plan is Dictionary:
			continue
		var contracts = source_plan.get("facility_slot_contracts", [])
		if not contracts is Array or contracts.is_empty():
			contracts = source_plan.get("facility_slots", [])
		for value in contracts:
			if not value is Dictionary:
				continue
			var slot: Dictionary = value
			var slot_id := str(slot.get("slot_id", slot.get("facility_slot_id", "")))
			var room_id := str(slot.get("room_id", slot.get("facility_instance_id", "")))
			if slot_id == "":
				continue
			by_id[slot_id] = slot
			if room_id != "":
				by_room[room_id] = slot_id
	return {"by_id": by_id, "by_room": by_room}


static func _defense_zone_index(plan: Dictionary, fallback_plan: Dictionary = {}) -> Dictionary:
	var by_id := {}
	var by_room := {}
	var plans: Array = [plan, fallback_plan]
	for source_plan in plans:
		if not source_plan is Dictionary:
			continue
		for value in source_plan.get("defense_zones", []):
			if not value is Dictionary:
				continue
			var zone: Dictionary = value
			var zone_id := str(zone.get("zone_id", ""))
			if zone_id == "":
				continue
			by_id[zone_id] = zone
			var anchor_room_id := str(zone.get("anchor_room_id", ""))
			if anchor_room_id != "":
				by_room[anchor_room_id] = zone_id
			for room_id_value in zone.get("room_ids", []):
				var room_id := str(room_id_value)
				if room_id != "":
					by_room[room_id] = zone_id
		for value in source_plan.get("facility_slot_contracts", []):
			if not value is Dictionary:
				continue
			var linked_zone_ids: Array = value.get("linked_zone_ids", [])
			if linked_zone_ids.is_empty():
				continue
			var linked_zone_id := str(linked_zone_ids.front())
			var facility_room_id := str(value.get("room_id", value.get("facility_instance_id", "")))
			if facility_room_id != "" and by_id.has(linked_zone_id):
				by_room[facility_room_id] = linked_zone_id
		_index_lane_route_rooms(source_plan, by_id, by_room)
	return {"by_id": by_id, "by_room": by_room}


static func _index_lane_route_rooms(
	plan: Dictionary,
	zone_by_id: Dictionary,
	zone_by_room: Dictionary
) -> void:
	var lane_routes = plan.get("lane_routes", {})
	if not lane_routes is Dictionary or lane_routes.is_empty():
		return
	var merge_zone_id := ""
	for zone_id_value in zone_by_id.keys():
		var zone_id := str(zone_id_value)
		if str(zone_by_id.get(zone_id, {}).get("lane_id", "")) == "merge":
			merge_zone_id = zone_id
			break
	var route_room_counts := {}
	for route_value in lane_routes.values():
		if not route_value is Array:
			continue
		for room_id_value in route_value:
			var room_id := str(room_id_value)
			route_room_counts[room_id] = int(route_room_counts.get(room_id, 0)) + 1
	if merge_zone_id != "":
		for room_id_value in route_room_counts.keys():
			var room_id := str(room_id_value)
			if int(route_room_counts.get(room_id, 0)) > 1 and not zone_by_room.has(room_id):
				zone_by_room[room_id] = merge_zone_id
	for lane_id_value in lane_routes.keys():
		var lane_id := str(lane_id_value)
		var route = lane_routes.get(lane_id, [])
		if not route is Array:
			continue
		var route_array: Array = route
		var lane_zones: Array = []
		for zone_id_value in zone_by_id.keys():
			var zone_id := str(zone_id_value)
			var zone: Dictionary = zone_by_id.get(zone_id, {})
			if str(zone.get("lane_id", "")) == lane_id:
				lane_zones.append(zone)
		for route_index in range(route_array.size()):
			var room_id := str(route_array[route_index])
			if zone_by_room.has(room_id):
				continue
			var nearest_zone_id := ""
			var nearest_distance := 2147483647
			for zone_value in lane_zones:
				var zone: Dictionary = zone_value
				var anchor_index: int = route_array.find(str(zone.get("anchor_room_id", "")))
				if anchor_index < 0:
					continue
				var distance := absi(anchor_index - route_index)
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_zone_id = str(zone.get("zone_id", ""))
			if nearest_zone_id != "":
				zone_by_room[room_id] = nearest_zone_id


static func _normalize_zone_slot_id(placement: Dictionary, defense_zone_id: String) -> void:
	var slot_id := str(placement.get("slot_id", placement.get("placement_slot_id", "")))
	if slot_id == "":
		return
	var slot_index := _slot_index(slot_id)
	if slot_index < 0:
		return
	var normalized_slot_id := "monster:%s:%d" % [defense_zone_id, slot_index]
	if slot_id != normalized_slot_id:
		if not placement.has("legacy_slot_id"):
			placement["legacy_slot_id"] = slot_id
		placement["slot_id"] = normalized_slot_id
	elif not placement.has("slot_id"):
		placement["slot_id"] = normalized_slot_id


static func _slot_index(slot_id: String) -> int:
	var separator_index := slot_id.rfind(":")
	if separator_index < 0:
		return -1
	var index_text := slot_id.substr(separator_index + 1)
	if not index_text.is_valid_int():
		return -1
	var slot_index := int(index_text)
	return slot_index if slot_index >= 0 else -1


static func _normalize_command_settings(value: Dictionary) -> Dictionary:
	var result := DEFAULT_COMMAND_SETTINGS.duplicate(true)
	for key in DEFAULT_COMMAND_SETTINGS.keys():
		if value.has(key):
			result[key] = value.get(key)
	result["max_points"] = maxi(1, int(result.get("max_points", 3)))
	result["initial_points"] = clampi(int(result.get("initial_points", 3)), 1, int(result.get("max_points", 3)))
	result["recharge_seconds"] = maxf(1.0, float(result.get("recharge_seconds", 12.0)))
	if not _string_array(result.get("preferred_commands")):
		result["preferred_commands"] = DEFAULT_COMMAND_SETTINGS["preferred_commands"].duplicate()
	return result


static func _normalize_ui_state(value: Dictionary) -> Dictionary:
	var result := DEFAULT_UI_STATE.duplicate(true)
	for key in DEFAULT_UI_STATE.keys():
		if value.get(key) is bool:
			result[key] = bool(value.get(key))
	return result


static func _validate_battle_plan(plan: Dictionary) -> String:
	for string_key in ["layout_id", "layout_fingerprint"]:
		if not plan.get(string_key) is String or str(plan.get(string_key, "")) == "":
			return "v1.2.2 battle plan 문구가 올바르지 않습니다: %s" % string_key
	if str(plan.get("layout_fingerprint", "")).length() != 64:
		return "v1.2.2 battle plan fingerprint가 올바르지 않습니다."
	for array_key in ["active_route", "enemy_goals", "facility_slots", "monster_slots", "facility_placements", "monster_placements", "defense_segments"]:
		if not plan.get(array_key) is Array:
			return "v1.2.2 battle plan 목록 형식이 올바르지 않습니다: %s" % array_key
	for optional_array_key in ["defense_zones", "facility_slot_contracts"]:
		if plan.has(optional_array_key) and not _array_of_dictionaries(plan.get(optional_array_key)):
			return "v1.2.2 battle plan 선택 목록 형식이 올바르지 않습니다: %s" % optional_array_key
	for optional_dictionary_key in ["lane_routes", "route_starts", "defender_connector"]:
		if plan.has(optional_dictionary_key) and not plan.get(optional_dictionary_key) is Dictionary:
			return "v1.2.2 battle plan 선택 사전 형식이 올바르지 않습니다: %s" % optional_dictionary_key
	if plan.has("defender_connector") and not _valid_connector_state(plan.get("defender_connector")):
		return "v1.2.2 battle plan connector state 형식이 올바르지 않습니다."
	if not plan.get("world_anchors") is Dictionary:
		return "v1.2.2 battle plan anchor 형식이 올바르지 않습니다."
	return ""


static func _validate_optional_placement_ids(
	facility_placements: Array,
	monster_placements: Array
) -> String:
	for placement_value in facility_placements:
		var placement: Dictionary = placement_value
		for key in ["facility_slot_id", "facility_instance_id", "room_id"]:
			if placement.has(key) and not placement.get(key) is String:
				return "v1.2.2 시설 배치 식별자 형식이 올바르지 않습니다: %s" % key
	for placement_value in monster_placements:
		var placement: Dictionary = placement_value
		for key in [
			"defense_zone_id",
			"assigned_defense_zone_id",
			"room_id",
			"slot_id",
			"placement_slot_id",
			"legacy_slot_id"
		]:
			if placement.has(key) and not placement.get(key) is String:
				return "v1.2.2 몬스터 배치 식별자 형식이 올바르지 않습니다: %s" % key
	return ""


static func _array_of_dictionaries(value) -> bool:
	if not value is Array:
		return false
	for entry in value:
		if not entry is Dictionary:
			return false
	return true


static func _valid_connector_state(value) -> bool:
	if not value is Dictionary:
		return false
	if value.is_empty():
		return true
	if not value.get("connector_id") is String or str(value.get("connector_id", "")) == "":
		return false
	if not value.get("built") is bool:
		return false
	if not _is_number(value.get("built_day")):
		return false
	var built_day := int(value.get("built_day", 0))
	return built_day >= 0 and built_day <= 30


static func _string_array(value) -> bool:
	if not value is Array:
		return false
	for entry in value:
		if not entry is String:
			return false
	return true


static func _is_number(value) -> bool:
	return value is int or value is float
