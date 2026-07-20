class_name V20PlacementService
extends RefCounted

const SCHEMA_VERSION := 1
const STATUS_INSTALLED := "installed"
const STATUS_CONFIRMATION_REQUIRED := "confirmation_required"
const STATUS_REPLACED := "replaced"
const STATUS_MONSTER_PLACED := "monster_placed"
const STATUS_UNDONE := "undone"


static func new_state(build_points: int, rooms: Dictionary, roster: Dictionary) -> Dictionary:
	var state := {
		"schema_version": SCHEMA_VERSION,
		"build_points": maxi(0, build_points),
		"rooms": rooms.duplicate(true),
		"roster": roster.duplicate(true),
		"placement_session": {},
		"pending_replacement": {},
		"undo": {},
		"last_action": {}
	}
	_normalize_state(state)
	return state


static func select_slot(state: Dictionary, room_id: String) -> Dictionary:
	var next := state.duplicate(true)
	if not next.get("rooms", {}).has(room_id):
		return _result(false, "unknown_room", state, "존재하지 않는 방입니다.")
	next["placement_session"] = {"kind": "facility", "room_id": room_id, "interaction_count": 1}
	next["pending_replacement"] = {}
	return _result(true, "slot_selected", next)


static func choose_facility(state: Dictionary, facility_id: String, facilities: Dictionary) -> Dictionary:
	var session: Dictionary = state.get("placement_session", {})
	var room_id := str(session.get("room_id", ""))
	if str(session.get("kind", "")) != "facility" or room_id == "":
		return _result(false, "slot_required", state, "먼저 시설 슬롯을 선택하세요.")
	var definition: Dictionary = facilities.get(facility_id, {})
	if definition.is_empty():
		return _result(false, "unknown_facility", state, "존재하지 않는 시설입니다.")
	var room: Dictionary = state.get("rooms", {}).get(room_id, {})
	if not _placement_allowed(room, definition):
		return _result(false, "invalid_placement", state, "이 슬롯에는 해당 시설을 설치할 수 없습니다.")
	var current_facility := str(room.get("facility_id", ""))
	if current_facility == facility_id:
		return _result(false, "already_installed", state, "이미 설치된 시설입니다.")
	var interactions := int(session.get("interaction_count", 1)) + 1
	if current_facility != "":
		var pending_state := state.duplicate(true)
		pending_state["pending_replacement"] = {
			"room_id": room_id,
			"from_facility_id": current_facility,
			"to_facility_id": facility_id,
			"interaction_count": interactions,
			"resource_loss": int(facilities.get(current_facility, {}).get("cost", {}).get("build", 0))
		}
		return _result(true, STATUS_CONFIRMATION_REQUIRED, pending_state)
	return _install_facility(state, room_id, facility_id, definition, interactions, STATUS_INSTALLED)


static func confirm_replacement(state: Dictionary, facilities: Dictionary) -> Dictionary:
	var pending: Dictionary = state.get("pending_replacement", {})
	if pending.is_empty():
		return _result(false, "replacement_required", state, "확인할 교체가 없습니다.")
	var room_id := str(pending.get("room_id", ""))
	var facility_id := str(pending.get("to_facility_id", ""))
	var definition: Dictionary = facilities.get(facility_id, {})
	if definition.is_empty():
		return _result(false, "unknown_facility", state, "교체할 시설이 없습니다.")
	return _install_facility(state, room_id, facility_id, definition, int(pending.get("interaction_count", 2)) + 1, STATUS_REPLACED)


static func cancel_replacement(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	next["pending_replacement"] = {}
	next["placement_session"] = {}
	return _result(true, "replacement_cancelled", next)


static func select_monster(state: Dictionary, monster_id: String) -> Dictionary:
	if not state.get("roster", {}).has(monster_id):
		return _result(false, "unknown_monster", state, "존재하지 않는 몬스터입니다.")
	var next := state.duplicate(true)
	next["placement_session"] = {"kind": "monster", "monster_id": monster_id, "interaction_count": 1, "input": "click_click"}
	next["pending_replacement"] = {}
	return _result(true, "monster_selected", next)


static func place_selected_monster(state: Dictionary, room_id: String) -> Dictionary:
	var session: Dictionary = state.get("placement_session", {})
	if str(session.get("kind", "")) != "monster":
		return _result(false, "monster_required", state, "먼저 몬스터를 선택하세요.")
	return _place_monster(state, str(session.get("monster_id", "")), room_id, int(session.get("interaction_count", 1)) + 1, "click_click")


static func place_monster_drag(state: Dictionary, monster_id: String, room_id: String) -> Dictionary:
	return _place_monster(state, monster_id, room_id, 1, "drag")


static func undo(state: Dictionary) -> Dictionary:
	var snapshot: Dictionary = state.get("undo", {})
	if snapshot.is_empty():
		return _result(false, "nothing_to_undo", state, "되돌릴 배치가 없습니다.")
	var next := snapshot.duplicate(true)
	next["undo"] = {}
	next["placement_session"] = {}
	next["pending_replacement"] = {}
	next["last_action"] = {"kind": STATUS_UNDONE, "interaction_count": 1}
	return _result(true, STATUS_UNDONE, next)


static func serialize(state: Dictionary) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"build_points": int(state.get("build_points", 0)),
		"rooms": state.get("rooms", {}).duplicate(true),
		"roster": state.get("roster", {}).duplicate(true)
	}


static func restore(payload) -> Dictionary:
	if not (payload is Dictionary) or int(payload.get("schema_version", 0)) != SCHEMA_VERSION:
		return _result(false, "invalid_schema", {}, "지원하지 않는 배치 저장 형식입니다.")
	var state := new_state(int(payload.get("build_points", 0)), payload.get("rooms", {}), payload.get("roster", {}))
	var validation := validate_state(state)
	return _result(bool(validation.get("ok", false)), "restored" if bool(validation.get("ok", false)) else "invalid_state", state, "" if bool(validation.get("ok", false)) else "; ".join(validation.get("errors", [])))


static func validate_state(state: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	if int(state.get("schema_version", 0)) != SCHEMA_VERSION:
		errors.append("schema_version must be %d" % SCHEMA_VERSION)
	var rooms = state.get("rooms")
	var roster = state.get("roster")
	if not (rooms is Dictionary):
		errors.append("rooms must be a Dictionary")
		rooms = {}
	if not (roster is Dictionary):
		errors.append("roster must be a Dictionary")
		roster = {}
	var placements: Dictionary = {}
	for room_id_value in rooms.keys():
		var room_id := str(room_id_value)
		var room: Dictionary = rooms.get(room_id, {})
		var monster_ids = room.get("monster_ids", [])
		if not (monster_ids is Array):
			errors.append("rooms.%s.monster_ids must be an Array" % room_id)
			continue
		if monster_ids.size() > int(room.get("capacity", 0)):
			errors.append("rooms.%s exceeds capacity" % room_id)
		for monster_id_value in monster_ids:
			var monster_id := str(monster_id_value)
			if placements.has(monster_id):
				errors.append("monster %s is placed more than once" % monster_id)
			placements[monster_id] = room_id
			if not roster.has(monster_id):
				errors.append("rooms.%s references unknown monster %s" % [room_id, monster_id])
	for monster_id_value in roster.keys():
		var monster_id := str(monster_id_value)
		var room_id := str(roster.get(monster_id, {}).get("room_id", ""))
		if room_id != str(placements.get(monster_id, "")):
			errors.append("roster.%s room_id does not match room placement" % monster_id)
	return {"ok": errors.is_empty(), "errors": errors}


static func _install_facility(state: Dictionary, room_id: String, facility_id: String, definition: Dictionary, interactions: int, status: String) -> Dictionary:
	var cost := int(definition.get("cost", {}).get("build", 0))
	if int(state.get("build_points", 0)) < cost:
		return _result(false, "insufficient_build_points", state, "건설 자원이 부족합니다.")
	var next := state.duplicate(true)
	next["undo"] = _snapshot(state)
	next["build_points"] = int(state.get("build_points", 0)) - cost
	next["rooms"][room_id]["facility_id"] = facility_id
	next["placement_session"] = {}
	next["pending_replacement"] = {}
	next["last_action"] = {"kind": status, "room_id": room_id, "facility_id": facility_id, "interaction_count": interactions}
	return _result(true, status, next)


static func _place_monster(state: Dictionary, monster_id: String, room_id: String, interactions: int, input_kind: String) -> Dictionary:
	if not state.get("roster", {}).has(monster_id):
		return _result(false, "unknown_monster", state, "존재하지 않는 몬스터입니다.")
	if not state.get("rooms", {}).has(room_id):
		return _result(false, "unknown_room", state, "존재하지 않는 방입니다.")
	var target: Dictionary = state.get("rooms", {}).get(room_id, {})
	var target_ids: Array = target.get("monster_ids", [])
	var current_room := str(state.get("roster", {}).get(monster_id, {}).get("room_id", ""))
	if current_room != room_id and target_ids.size() >= int(target.get("capacity", 0)):
		return _result(false, "room_full", state, "배치 정원이 가득 찼습니다.")
	var next := state.duplicate(true)
	next["undo"] = _snapshot(state)
	for existing_room_id in next["rooms"].keys():
		var ids: Array = next["rooms"][existing_room_id].get("monster_ids", [])
		ids.erase(monster_id)
		next["rooms"][existing_room_id]["monster_ids"] = ids
	var placed_ids: Array = next["rooms"][room_id].get("monster_ids", [])
	if not placed_ids.has(monster_id):
		placed_ids.append(monster_id)
	next["rooms"][room_id]["monster_ids"] = placed_ids
	next["roster"][monster_id]["room_id"] = room_id
	next["placement_session"] = {}
	next["pending_replacement"] = {}
	next["last_action"] = {"kind": STATUS_MONSTER_PLACED, "monster_id": monster_id, "room_id": room_id, "input": input_kind, "interaction_count": interactions}
	return _result(true, STATUS_MONSTER_PLACED, next)


static func _placement_allowed(room: Dictionary, definition: Dictionary) -> bool:
	var room_tags: Array = room.get("placement_tags", [])
	var facility_tags: Array = definition.get("placement_tags", [])
	for tag in facility_tags:
		if room_tags.has(tag):
			return true
	return false


static func _snapshot(state: Dictionary) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"build_points": int(state.get("build_points", 0)),
		"rooms": state.get("rooms", {}).duplicate(true),
		"roster": state.get("roster", {}).duplicate(true),
		"placement_session": {},
		"pending_replacement": {},
		"undo": {},
		"last_action": state.get("last_action", {}).duplicate(true)
	}


static func _normalize_state(state: Dictionary) -> void:
	for room_id in state.get("rooms", {}).keys():
		var room: Dictionary = state["rooms"][room_id]
		if not room.has("monster_ids") or not (room.get("monster_ids") is Array):
			room["monster_ids"] = []
		room["capacity"] = maxi(0, int(room.get("capacity", 0)))
		room["facility_id"] = str(room.get("facility_id", ""))
		state["rooms"][room_id] = room
	for monster_id in state.get("roster", {}).keys():
		var monster: Dictionary = state["roster"][monster_id]
		monster["room_id"] = str(monster.get("room_id", ""))
		state["roster"][monster_id] = monster


static func _result(ok: bool, status: String, state: Dictionary, error: String = "") -> Dictionary:
	return {"ok": ok, "status": status, "state": state.duplicate(true), "error": error}
