class_name V20SaveStore
extends RefCounted

const SpatialModel = preload("res://scripts/v20/spatial/V20SpatialModel.gd")

const SAVE_VERSION := 3
const SAVE_PATH := "user://v20/campaign_v20.json"
const STATUS_VALID := "valid"
const STATUS_MISSING := "missing"
const STATUS_CORRUPT := "corrupt"
const STATUS_UNSUPPORTED := "unsupported"
const ZONE_VALUE_KEYS := [
	"zone_id", "home_zone", "target_zone", "slot_zone", "room_id", "node_id",
	"current_node", "manual_anchor_node", "anchor_node", "goal_node",
	"first_engagement_node", "checkpoint_room", "final_goal"
]
const ZONE_ARRAY_KEYS := ["nodes", "route_nodes", "checkpoints"]
const LEGACY_ZONE_IDS := {
	"entrance": "gate_outpost",
	"north_gate": "gate_outpost",
	"north_cross": "spike_corridor",
	"south_gate": "spike_corridor",
	"south_cross": "central_battle_room",
	"treasure": "central_battle_room",
	"barracks": "central_battle_room",
	"fallback": "throne_anteroom",
	"throne": "throne"
}


static func inspect(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _inspection(STATUS_MISSING, "2.0 저장 파일이 없습니다.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _inspection(STATUS_CORRUPT, "2.0 저장 파일을 읽을 수 없습니다.")
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return _inspection(STATUS_CORRUPT, "2.0 저장 JSON이 올바르지 않습니다.")
	var migration_count := 0
	var envelope: Dictionary = parsed
	match int(envelope.get("version", 0)):
		2:
			envelope = _migrate_v2_envelope(envelope)
			migration_count = 1
			var migration_error := validate(envelope.get("payload"), envelope.get("summary"))
			if migration_error != "":
				return _inspection(STATUS_CORRUPT, migration_error)
			var persisted := _write_envelope(envelope, path)
			if not bool(persisted.get("ok", false)):
				return _inspection(STATUS_CORRUPT, str(persisted.get("error", "schema 3 변환 저장 실패")))
		SAVE_VERSION:
			pass
		_:
			return _inspection(STATUS_UNSUPPORTED, "지원하지 않는 2.0 저장 버전입니다.")
	var payload = envelope.get("payload")
	var summary = envelope.get("summary")
	var validation_error := validate(payload, summary)
	if validation_error != "":
		return _inspection(STATUS_CORRUPT, validation_error)
	return {
		"status": STATUS_VALID,
		"error": "",
		"payload": payload.duplicate(true),
		"summary": summary.duplicate(true),
		"saved_at_text": str(envelope.get("saved_at_text", "")),
		"migration_count": migration_count
	}


static func write(payload: Dictionary, summary: Dictionary, path: String = SAVE_PATH) -> Dictionary:
	var validation_error := validate(payload, summary)
	if validation_error != "":
		return {"ok": false, "error": validation_error}
	var envelope := {
		"version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"saved_at_text": Time.get_datetime_string_from_system(false, true),
		"summary": summary.duplicate(true),
		"payload": payload.duplicate(true)
	}
	return _write_envelope(envelope, path)


static func delete(path: String = SAVE_PATH) -> bool:
	var ok := true
	for candidate in [path, "%s.tmp" % path, "%s.bak" % path]:
		if FileAccess.file_exists(candidate):
			ok = DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) == OK and ok
	return ok


static func validate(payload, summary) -> String:
	if not (payload is Dictionary) or not (summary is Dictionary):
		return "2.0 저장 본문 또는 요약이 없습니다."
	if int(payload.get("schema_version", 0)) != SAVE_VERSION:
		return "2.0 session schema가 올바르지 않습니다."
	var day := int(payload.get("day", 0))
	if day < 1 or day > 5 or int(summary.get("day", 0)) != day:
		return "2.0 DAY 범위 또는 요약이 올바르지 않습니다."
	if str(payload.get("difficulty_id", "")) == "" or str(summary.get("difficulty_id", "")) != str(payload.get("difficulty_id", "")):
		return "2.0 난이도 요약이 일치하지 않습니다."
	for key in ["economy", "placement", "onboarding", "retry_snapshot", "last_result"]:
		if not (payload.get(key) is Dictionary):
			return "2.0 저장 항목 형식이 올바르지 않습니다: %s" % key
	return ""


static func _write_envelope(envelope: Dictionary, path: String) -> Dictionary:
	var absolute := ProjectSettings.globalize_path(path)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if dir_error != OK:
		return {"ok": false, "error": "2.0 저장 폴더를 만들 수 없습니다."}
	var temp_path := "%s.tmp" % path
	var temp := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp == null:
		return {"ok": false, "error": "2.0 임시 저장 파일을 만들 수 없습니다."}
	temp.store_string(JSON.stringify(envelope, "\t"))
	temp.flush()
	var write_error := temp.get_error()
	temp.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return {"ok": false, "error": "2.0 임시 저장 파일 기록에 실패했습니다."}
	var backup_path := "%s.bak" % path
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	if FileAccess.file_exists(path) and DirAccess.rename_absolute(absolute, ProjectSettings.globalize_path(backup_path)) != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return {"ok": false, "error": "기존 2.0 저장을 백업할 수 없습니다."}
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), absolute) != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), absolute)
		return {"ok": false, "error": "새 2.0 저장을 적용할 수 없습니다."}
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	return {"ok": true, "error": ""}


static func _migrate_v2_envelope(source: Dictionary) -> Dictionary:
	var envelope := source.duplicate(true)
	envelope["version"] = SAVE_VERSION
	envelope["payload"] = _migrate_v2_payload(source.get("payload", {}))
	var migrations: Array = envelope.get("migrations_applied", []).duplicate()
	if not migrations.has("v2_to_v3_canonical_spatial_ids"):
		migrations.append("v2_to_v3_canonical_spatial_ids")
	envelope["migrations_applied"] = migrations
	return envelope


static func _migrate_v2_payload(source) -> Dictionary:
	var payload: Dictionary = source.duplicate(true) if source is Dictionary else {}
	payload["schema_version"] = SAVE_VERSION
	payload["placement"] = _migrate_placement(payload.get("placement", {}))
	var retry: Dictionary = payload.get("retry_snapshot", {}).duplicate(true)
	if retry.get("placement_state") is Dictionary:
		retry["placement_state"] = _migrate_placement(retry.get("placement_state", {}))
	payload["retry_snapshot"] = retry
	return _migrate_zone_fields(payload)


static func _migrate_placement(source) -> Dictionary:
	var placement: Dictionary = source.duplicate(true) if source is Dictionary else {}
	var old_rooms: Dictionary = placement.get("rooms", {})
	var rooms: Dictionary = {}
	var board := SpatialModel.load_default_board()
	for definition in SpatialModel.defense_zones(board):
		var zone_id := str(definition.get("zone_id", ""))
		var old_id := _legacy_placement_id(zone_id)
		var existing: Dictionary = old_rooms.get(old_id, old_rooms.get(zone_id, {})).duplicate(true)
		var monster_slot_ids: Array = []
		for slot_value in definition.get("monster_slots", []):
			monster_slot_ids.append(str(slot_value.get("slot_id", "")))
		rooms[zone_id] = {
			"zone_id": zone_id,
			"display_name": "%d · %s" % [int(definition.get("order", 0)), str(definition.get("display_name", zone_id))],
			"section_index": int(definition.get("order", 0)),
			"strategy_hint": str(existing.get("strategy_hint", "배치 슬롯의 실제 전투 구역")),
			"placement_tags": definition.get("placement_tags", []).duplicate(),
			"capacity": int(definition.get("max_defenders", 0)),
			"facility_slot_id": str(definition.get("facility_slot", {}).get("slot_id", "")),
			"monster_slot_ids": monster_slot_ids,
			"facility_id": str(existing.get("facility_id", "")),
			"monster_ids": existing.get("monster_ids", []).duplicate()
		}
	placement["rooms"] = rooms
	var roster: Dictionary = placement.get("roster", {}).duplicate(true)
	for zone_id in rooms.keys():
		var monster_ids: Array = rooms[zone_id].get("monster_ids", [])
		for index in range(monster_ids.size()):
			var monster_id := str(monster_ids[index])
			if not roster.has(monster_id):
				roster[monster_id] = {}
			roster[monster_id]["room_id"] = zone_id
			var slot_ids: Array = rooms[zone_id].get("monster_slot_ids", [])
			roster[monster_id]["monster_slot_id"] = str(slot_ids[index]) if index < slot_ids.size() else ""
	placement["roster"] = roster
	return placement


static func _migrate_zone_fields(value):
	if value is Array:
		var result_array: Array = []
		for item in value:
			result_array.append(_migrate_zone_fields(item))
		return result_array
	if not (value is Dictionary):
		return value
	var result: Dictionary = {}
	for key_value in value.keys():
		var key := str(key_value)
		var migrated_key := str(LEGACY_ZONE_IDS.get(key, key)) if value.get(key_value) is Dictionary else key
		var item = value.get(key_value)
		if ZONE_VALUE_KEYS.has(key) and item is String:
			result[migrated_key] = str(LEGACY_ZONE_IDS.get(str(item), str(item)))
		elif ZONE_ARRAY_KEYS.has(key) and item is Array:
			var migrated_values: Array = []
			for item_value in item:
				migrated_values.append(str(LEGACY_ZONE_IDS.get(str(item_value), str(item_value))))
			result[migrated_key] = migrated_values
		else:
			result[migrated_key] = _migrate_zone_fields(item)
	return result


static func _legacy_placement_id(zone_id: String) -> String:
	return str({
		"gate_outpost": "north_gate",
		"spike_corridor": "south_gate",
		"central_battle_room": "treasure",
		"throne_anteroom": "fallback"
	}.get(zone_id, zone_id))


static func _inspection(status: String, error: String) -> Dictionary:
	return {"status": status, "error": error, "payload": {}, "summary": {}, "saved_at_text": "", "migration_count": 0}
