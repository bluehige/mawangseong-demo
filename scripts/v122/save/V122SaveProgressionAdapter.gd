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
	var result := {
		"schema_version": SCHEMA_VERSION,
		"battle_plan": plan,
		"facility_placements": plan.get("facility_slots", []).duplicate(true),
		"monster_placements": plan.get("monster_placements", []).duplicate(true),
		"last_confirmed_placements": confirmed,
		"retry_snapshot": retry_snapshot.duplicate(true),
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
	if source.get("facility_placements") is Array:
		result["facility_placements"] = source.get("facility_placements", []).duplicate(true)
	if source.get("monster_placements") is Array:
		result["monster_placements"] = source.get("monster_placements", []).duplicate(true)
	return result


static func capture_confirmation(battle_plan: Dictionary, day: int, global_directive: String, room_directives: Dictionary) -> Dictionary:
	var placements := _placements_from_plan(battle_plan)
	return {
		"last_confirmed_placements": placements.duplicate(true),
		"retry_snapshot": {
			"day": day,
			"layout_id": str(battle_plan.get("layout_id", "")),
			"layout_fingerprint": str(battle_plan.get("layout_fingerprint", "")),
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
	for array_key in ["facility_placements", "monster_placements"]:
		if not _array_of_dictionaries(state.get(array_key)):
			return "v1.2.2 배치 목록 형식이 올바르지 않습니다: %s" % array_key
	var confirmed = state.get("last_confirmed_placements")
	if not confirmed is Dictionary:
		return "v1.2.2 마지막 확정 배치 형식이 올바르지 않습니다."
	for array_key in ["facility_placements", "monster_placements"]:
		if not _array_of_dictionaries(confirmed.get(array_key)):
			return "v1.2.2 마지막 확정 배치 목록이 올바르지 않습니다: %s" % array_key
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
		for array_key in ["facility_placements", "monster_placements"]:
			if not _array_of_dictionaries(retry.get(array_key)):
				return "v1.2.2 retry 배치 형식이 올바르지 않습니다: %s" % array_key
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
	room_directives: Dictionary
) -> Dictionary:
	if retry_snapshot.is_empty():
		return {
			"rooms": rooms.duplicate(true),
			"monster_roster": monster_roster.duplicate(true),
			"global_directive": global_directive,
			"room_directives": room_directives.duplicate(true)
		}
	var next_rooms := rooms.duplicate(true)
	for value in retry_snapshot.get("facility_placements", []):
		if not value is Dictionary:
			continue
		var room_id := str(value.get("room_id", ""))
		var role := str(value.get("facility_role", ""))
		if next_rooms.has(room_id) and role != "":
			next_rooms[room_id]["facility_role"] = role
	var next_roster := monster_roster.duplicate(true)
	for value in retry_snapshot.get("monster_placements", []):
		if not value is Dictionary:
			continue
		var monster_id := str(value.get("monster_instance_id", ""))
		var room_id := str(value.get("room_id", ""))
		if next_roster.has(monster_id) and next_rooms.has(room_id):
			next_roster[monster_id]["room"] = room_id
	return {
		"rooms": next_rooms,
		"monster_roster": next_roster,
		"global_directive": str(retry_snapshot.get("global_directive", global_directive)),
		"room_directives": retry_snapshot.get("room_directives", room_directives).duplicate(true)
	}


static func _placements_from_plan(battle_plan: Dictionary) -> Dictionary:
	return {
		"layout_id": str(battle_plan.get("layout_id", "")),
		"layout_fingerprint": str(battle_plan.get("layout_fingerprint", "")),
		"facility_placements": battle_plan.get("facility_slots", []).duplicate(true),
		"monster_placements": battle_plan.get("monster_placements", []).duplicate(true)
	}


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
	if not plan.get("world_anchors") is Dictionary:
		return "v1.2.2 battle plan anchor 형식이 올바르지 않습니다."
	return ""


static func _array_of_dictionaries(value) -> bool:
	if not value is Array:
		return false
	for entry in value:
		if not entry is Dictionary:
			return false
	return true


static func _string_array(value) -> bool:
	if not value is Array:
		return false
	for entry in value:
		if not entry is String:
			return false
	return true


static func _is_number(value) -> bool:
	return value is int or value is float
