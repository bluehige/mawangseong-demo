extends RefCounted
class_name CampaignSaveStore

const SAVE_VERSION := 1
const CAMPAIGN_FINAL_DAY := 30
const SAVE_PATH := "user://campaign_save_v1.json"
const INVALID_SUFFIX := ".invalid"
const UNRESTORABLE_SUFFIX := ".unrestorable"
const DELETE_PENDING_SUFFIX := ".delete_pending"

const STATUS_VALID := "valid"
const STATUS_MISSING := "missing"
const STATUS_CORRUPT := "corrupt"
const STATUS_UNSUPPORTED := "unsupported"
const SAFE_SCREENS := ["management", "monster", "result", "ending", "dialogue", "raid_preview", "raid"]
const CASTLE_STAGE_INDEX := {
	"stage_01_cave": 1,
	"stage_02_castle": 2,
	"stage_03_keep": 3,
	"stage_04_citadel": 4
}
const REQUIRED_GAME_STATE_KEYS := [
	"day",
	"gold",
	"mana",
	"food",
	"infamy",
	"gold_income",
	"mana_income",
	"food_income",
	"infamy_income",
	"demon_lord_hp",
	"demon_lord_max_hp",
	"victory",
	"defeat",
	"player_name",
	"onboarding_stage",
	"onboarding_complete"
]


static func inspect(path: String = SAVE_PATH) -> Dictionary:
	var invalid_path := "%s%s" % [path, INVALID_SUFFIX]
	var unrestorable_path := "%s%s" % [path, UNRESTORABLE_SUFFIX]
	if FileAccess.file_exists(invalid_path):
		var invalid_reason := _read_invalid_reason(invalid_path)
		return _inspection(STATUS_CORRUPT, invalid_reason if invalid_reason != "" else "복원할 수 없는 저장 기록입니다.")
	if not FileAccess.file_exists(path) and FileAccess.file_exists(unrestorable_path):
		return _inspection(STATUS_CORRUPT, "복원하지 못한 저장 기록을 격리했습니다.")
	var inspection := _inspect_file(path)
	if str(inspection.get("status", "")) in [STATUS_MISSING, STATUS_CORRUPT]:
		_recover_interrupted_write(path)
		inspection = _inspect_file(path)
	if str(inspection.get("status", "")) == STATUS_MISSING:
		for candidate in ["%s.tmp" % path, "%s.bak" % path]:
			if not FileAccess.file_exists(candidate):
				continue
			var candidate_inspection := _inspect_file(candidate)
			if str(candidate_inspection.get("status", "")) == STATUS_UNSUPPORTED:
				return candidate_inspection
			return _inspection(STATUS_CORRUPT, "완료되지 않은 저장 기록이 남아 있습니다.")
	return inspection


static func _inspect_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _inspection(STATUS_MISSING, "저장 파일이 없습니다.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _inspection(STATUS_CORRUPT, "저장 파일을 열 수 없습니다.")
	var raw_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		return _inspection(STATUS_CORRUPT, "저장 파일 형식이 올바르지 않습니다.")
	var envelope: Dictionary = parsed
	if not _is_number(envelope.get("version")) or not _is_number(envelope.get("campaign_final_day")):
		return _inspection(STATUS_CORRUPT, "저장 버전 형식이 올바르지 않습니다.")
	if int(envelope.get("version")) != SAVE_VERSION:
		return _inspection(STATUS_UNSUPPORTED, "지원하지 않는 저장 버전입니다.")
	if int(envelope.get("campaign_final_day")) != CAMPAIGN_FINAL_DAY:
		return _inspection(STATUS_UNSUPPORTED, "캠페인 범위가 다른 저장 버전입니다.")
	var payload = envelope.get("payload", null)
	var summary = envelope.get("summary", null)
	if not (payload is Dictionary) or not (summary is Dictionary):
		return _inspection(STATUS_CORRUPT, "저장 내용 또는 요약이 없습니다.")
	var validation_error := validate_payload(payload, summary)
	if validation_error != "":
		return _inspection(STATUS_CORRUPT, validation_error)
	if not _is_number(envelope.get("saved_at_unix")) or not (envelope.get("saved_at_text") is String):
		return _inspection(STATUS_CORRUPT, "저장 시각 형식이 올바르지 않습니다.")
	return {
		"status": STATUS_VALID,
		"error": "",
		"payload": payload.duplicate(true),
		"summary": summary.duplicate(true),
		"saved_at_unix": int(envelope.get("saved_at_unix")),
		"saved_at_text": str(envelope.get("saved_at_text"))
	}


static func write(payload: Dictionary, summary: Dictionary, path: String = SAVE_PATH) -> Dictionary:
	var validation_error := validate_payload(payload, summary)
	if validation_error != "":
		return {"ok": false, "error": "저장할 진행 정보가 올바르지 않습니다: %s" % validation_error}
	var envelope := {
		"version": SAVE_VERSION,
		"campaign_final_day": CAMPAIGN_FINAL_DAY,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"saved_at_text": Time.get_datetime_string_from_system(false, true),
		"summary": summary.duplicate(true),
		"payload": payload.duplicate(true)
	}
	var temp_path := "%s.tmp" % path
	var temp_file := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		return {"ok": false, "error": "임시 저장 파일을 만들 수 없습니다."}
	temp_file.store_string(JSON.stringify(envelope, "\t"))
	temp_file.flush()
	var write_error := temp_file.get_error()
	temp_file.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return {"ok": false, "error": "임시 저장 파일을 끝까지 기록하지 못했습니다."}
	if str(_inspect_file(temp_path).get("status", "")) != STATUS_VALID:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return {"ok": false, "error": "임시 저장 파일을 다시 읽어 검증하지 못했습니다."}

	var temp_absolute := ProjectSettings.globalize_path(temp_path)
	var save_absolute := ProjectSettings.globalize_path(path)
	var backup_path := "%s.bak" % path
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path) and DirAccess.remove_absolute(backup_absolute) != OK:
		DirAccess.remove_absolute(temp_absolute)
		return {"ok": false, "error": "이전 저장 백업을 정리하지 못했습니다."}
	var had_existing_save := FileAccess.file_exists(path)
	if had_existing_save:
		var backup_error := DirAccess.rename_absolute(save_absolute, backup_absolute)
		if backup_error != OK:
			DirAccess.remove_absolute(temp_absolute)
			return {"ok": false, "error": "기존 저장 파일을 안전하게 보관하지 못했습니다."}
	var replace_error := DirAccess.rename_absolute(temp_absolute, save_absolute)
	if replace_error != OK:
		var restored := _restore_backup_after_failed_write(path, backup_path, had_existing_save)
		return {"ok": false, "error": "새 저장 파일을 적용하지 못했습니다." if restored else "새 저장 적용과 이전 저장 복구에 모두 실패했습니다."}
	if str(_inspect_file(path).get("status", "")) != STATUS_VALID:
		var restored := _restore_backup_after_failed_write(path, backup_path, had_existing_save)
		return {"ok": false, "error": "교체한 저장 파일의 재검증에 실패했습니다." if restored else "교체한 저장 검증과 이전 저장 복구에 모두 실패했습니다."}
	var invalid_path := "%s%s" % [path, INVALID_SUFFIX]
	if FileAccess.file_exists(invalid_path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(invalid_path)) != OK:
		var restored := _restore_backup_after_failed_write(path, backup_path, had_existing_save)
		return {"ok": false, "error": "복원 실패 표식을 정리하지 못했습니다." if restored else "복원 실패 표식 정리와 이전 저장 복구에 모두 실패했습니다."}
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)
	return {"ok": true, "error": ""}


static func delete(path: String = SAVE_PATH) -> bool:
	var pending_path := "%s%s" % [path, DELETE_PENDING_SUFFIX]
	var invalid_path := "%s%s" % [path, INVALID_SUFFIX]
	var pending_invalid_path := "%s%s" % [invalid_path, DELETE_PENDING_SUFFIX]
	for stale_path in [pending_path, pending_invalid_path]:
		if FileAccess.file_exists(stale_path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(stale_path)) != OK:
			return false
	var invalid_moved := false
	if FileAccess.file_exists(invalid_path):
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(invalid_path), ProjectSettings.globalize_path(pending_invalid_path)) != OK:
			return false
		invalid_moved = true
	var save_moved := false
	if FileAccess.file_exists(path):
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(pending_path)) != OK:
			_restore_delete_markers(path, pending_path, invalid_path, pending_invalid_path, false, invalid_moved)
			return false
		save_moved = true
	for candidate in ["%s.tmp" % path, "%s.bak" % path, "%s%s" % [path, UNRESTORABLE_SUFFIX]]:
		if FileAccess.file_exists(candidate) and DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) != OK:
			_restore_delete_markers(path, pending_path, invalid_path, pending_invalid_path, save_moved, invalid_moved)
			return false
	if save_moved and DirAccess.remove_absolute(ProjectSettings.globalize_path(pending_path)) != OK:
		_restore_delete_markers(path, pending_path, invalid_path, pending_invalid_path, true, invalid_moved)
		return false
	if invalid_moved and DirAccess.remove_absolute(ProjectSettings.globalize_path(pending_invalid_path)) != OK:
		push_warning("Campaign save invalid marker cleanup deferred: %s" % pending_invalid_path)
	return true


static func mark_invalid(path: String, reason: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var invalid_path := "%s%s" % [path, INVALID_SUFFIX]
	var file := FileAccess.open(invalid_path, FileAccess.WRITE)
	if file == null:
		return _quarantine_unrestorable(path)
	file.store_string(reason)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error == OK or FileAccess.file_exists(invalid_path):
		return true
	return _quarantine_unrestorable(path)


static func _quarantine_unrestorable(path: String) -> bool:
	var quarantine_path := "%s%s" % [path, UNRESTORABLE_SUFFIX]
	if FileAccess.file_exists(quarantine_path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(quarantine_path)) != OK:
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(quarantine_path)) == OK


static func _restore_backup_after_failed_write(path: String, backup_path: String, had_existing_save: bool) -> bool:
	if FileAccess.file_exists(path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
		return false
	if not had_existing_save:
		return true
	if not FileAccess.file_exists(backup_path):
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path)) == OK


static func _restore_delete_markers(path: String, pending_path: String, invalid_path: String, pending_invalid_path: String, save_moved: bool, invalid_moved: bool) -> void:
	if save_moved and FileAccess.file_exists(pending_path) and not FileAccess.file_exists(path):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(pending_path), ProjectSettings.globalize_path(path))
	if invalid_moved and FileAccess.file_exists(pending_invalid_path) and not FileAccess.file_exists(invalid_path):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(pending_invalid_path), ProjectSettings.globalize_path(invalid_path))


static func _read_invalid_reason(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var reason := file.get_as_text().strip_edges()
	file.close()
	return reason


static func _recover_interrupted_write(path: String) -> bool:
	var current := _inspect_file(path)
	var current_status := str(current.get("status", STATUS_CORRUPT))
	if current_status in [STATUS_VALID, STATUS_UNSUPPORTED]:
		return false
	var temp_path := "%s.tmp" % path
	var backup_path := "%s.bak" % path
	for candidate in [temp_path, backup_path]:
		if str(_inspect_file(candidate).get("status", "")) != STATUS_VALID:
			continue
		var save_absolute := ProjectSettings.globalize_path(path)
		var candidate_absolute := ProjectSettings.globalize_path(candidate)
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(save_absolute) != OK:
			return false
		if DirAccess.rename_absolute(candidate_absolute, save_absolute) != OK:
			return false
		var stale_path := backup_path if candidate == temp_path else temp_path
		if FileAccess.file_exists(stale_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(stale_path))
		return true
	return false


static func validate_payload(payload: Dictionary, summary: Dictionary) -> String:
	for required_key in ["game_state", "world", "raid", "campaign", "result", "onboarding"]:
		if not (payload.get(required_key, null) is Dictionary):
			return "필수 진행 정보가 없습니다: %s" % required_key
	if not (payload.get("screen") is String) or not SAFE_SCREENS.has(payload.get("screen")):
		return "안전하지 않은 화면에서 생성된 저장 파일입니다."
	if not (payload.get("checkpoint") is String) or payload.get("checkpoint") != payload.get("screen"):
		return "저장 지점과 화면 정보가 일치하지 않습니다."

	var game_state: Dictionary = payload.get("game_state", {})
	for required_key in REQUIRED_GAME_STATE_KEYS:
		if not game_state.has(required_key):
			return "게임 진행 정보가 누락되었습니다: %s" % required_key
	for numeric_key in ["day", "gold", "mana", "food", "infamy", "gold_income", "mana_income", "food_income", "infamy_income", "demon_lord_hp", "demon_lord_max_hp"]:
		if not _is_number(game_state.get(numeric_key)):
			return "게임 수치 형식이 올바르지 않습니다: %s" % numeric_key
	var day := int(game_state.get("day"))
	if day < 1 or day > CAMPAIGN_FINAL_DAY:
		return "저장된 날짜가 캠페인 범위를 벗어났습니다."
	for resource_key in ["gold", "mana", "food", "infamy", "gold_income", "mana_income", "food_income", "infamy_income"]:
		if int(game_state.get(resource_key)) < 0:
			return "저장된 자원 수치가 음수입니다: %s" % resource_key
	var maximum_hp := int(game_state.get("demon_lord_max_hp"))
	var current_hp := int(game_state.get("demon_lord_hp"))
	if maximum_hp < 1 or current_hp < 0 or current_hp > maximum_hp:
		return "마왕 체력 수치가 올바르지 않습니다."
	if not (game_state.get("victory") is bool) or not (game_state.get("defeat") is bool):
		return "전투 결과 형식이 올바르지 않습니다."
	if game_state.get("victory") and game_state.get("defeat"):
		return "승리와 패배 상태가 동시에 저장되어 있습니다."
	if not (game_state.get("player_name") is String) or not (game_state.get("onboarding_stage") is String) or not (game_state.get("onboarding_complete") is bool):
		return "플레이어 또는 안내 진행 정보 형식이 올바르지 않습니다."

	for numeric_key in ["day", "campaign_final_day", "castle_stage_index"]:
		if not _is_number(summary.get(numeric_key)):
			return "저장 요약 수치 형식이 올바르지 않습니다: %s" % numeric_key
	for string_key in ["player_name", "castle_stage", "castle_name", "checkpoint", "checkpoint_label", "final_battle_outcome"]:
		if not (summary.get(string_key) is String):
			return "저장 요약 문구 형식이 올바르지 않습니다: %s" % string_key
	for bool_key in ["campaign_completed", "campaign_postgame_active"]:
		if not (summary.get(bool_key) is bool):
			return "저장 요약 상태 형식이 올바르지 않습니다: %s" % bool_key
	if int(summary.get("day")) != day:
		return "저장 요약과 진행 날짜가 일치하지 않습니다."
	if int(summary.get("campaign_final_day")) != CAMPAIGN_FINAL_DAY:
		return "저장 요약의 캠페인 범위가 올바르지 않습니다."
	if summary.get("checkpoint") != payload.get("screen") or summary.get("player_name") != game_state.get("player_name"):
		return "저장 요약과 실제 진행 정보가 일치하지 않습니다."

	var world: Dictionary = payload.get("world", {})
	if not (world.get("castle_art_stage") is String):
		return "마왕성 단계 형식이 올바르지 않습니다."
	var stage_id: String = world.get("castle_art_stage")
	if not CASTLE_STAGE_INDEX.has(stage_id):
		return "저장된 마왕성 단계가 올바르지 않습니다."
	if int(summary.get("castle_stage_index")) != int(CASTLE_STAGE_INDEX[stage_id]) or summary.get("castle_stage") != stage_id:
		return "저장 요약과 마왕성 단계가 일치하지 않습니다."
	var rooms = world.get("rooms", null)
	if not (rooms is Dictionary) or rooms.is_empty() or not rooms.has("entrance") or not rooms.has("throne"):
		return "필수 방 정보가 올바르지 않습니다."
	for room_data in rooms.values():
		if not (room_data is Dictionary):
			return "손상된 방 정보가 포함되어 있습니다."
		for numeric_key in ["hp", "max_monsters", "facility_level", "icon_size", "castle_stage_hp_bonus", "castle_stage_capacity_bonus"]:
			if room_data.has(numeric_key) and not _is_number(room_data.get(numeric_key)):
				return "방 수치 형식이 올바르지 않습니다: %s" % numeric_key
		for string_key in ["type", "display_name", "facility_role", "icon"]:
			if room_data.has(string_key) and not (room_data.get(string_key) is String):
				return "방 설명 형식이 올바르지 않습니다: %s" % string_key
		for array_key in ["center", "rect", "grid_position", "grid_size", "icon_offset"]:
			if room_data.has(array_key) and not _array_contains_only_numbers(room_data.get(array_key)):
				return "방 좌표 형식이 올바르지 않습니다: %s" % array_key
	var roster = world.get("monster_roster", null)
	if not (roster is Dictionary) or roster.is_empty():
		return "몬스터 편성 정보가 올바르지 않습니다."
	for monster_data in roster.values():
		if not (monster_data is Dictionary):
			return "손상된 몬스터 정보가 포함되어 있습니다."
		for numeric_key in ["level", "exp"]:
			if not _is_number(monster_data.get(numeric_key)) or int(monster_data.get(numeric_key)) < 0:
				return "몬스터 성장 수치가 올바르지 않습니다: %s" % numeric_key
		if not (monster_data.get("room") is String):
			return "몬스터 배치 정보가 올바르지 않습니다."
		for bool_key in ["defense_enabled", "raid_support"]:
			if monster_data.has(bool_key) and not (monster_data.get(bool_key) is bool):
				return "몬스터 상태 형식이 올바르지 않습니다: %s" % bool_key
		if monster_data.has("growth_preparation_day") and not _is_number(monster_data.get("growth_preparation_day")):
			return "몬스터 준비 날짜 형식이 올바르지 않습니다."
		for string_key in ["growth_preparation_id", "specialization_id", "promotion_id", "role_tag"]:
			if monster_data.has(string_key) and not (monster_data.get(string_key) is String):
				return "몬스터 성장 정보 형식이 올바르지 않습니다: %s" % string_key
	for string_key in ["quarter_layout_id", "selected_room", "selected_monster_id", "global_directive", "last_castle_evolution_from_stage"]:
		if not (world.get(string_key) is String):
			return "성 관리 문구 형식이 올바르지 않습니다: %s" % string_key
	if not _is_number(world.get("last_castle_evolution_day")):
		return "마왕성 진화 날짜 형식이 올바르지 않습니다."
	if not _dictionary_value_is(world, "room_directives", TYPE_DICTIONARY) or not _dictionary_value_is(world, "quarter_layout", TYPE_DICTIONARY):
		return "방 지시 또는 맵 정보 형식이 올바르지 않습니다."
	for directive_value in world.get("room_directives").values():
		if not (directive_value is String):
			return "방 지시 값 형식이 올바르지 않습니다."
	if not _array_contains_only_type(world.get("castle_evolution_history"), TYPE_STRING) or not _array_contains_only_type(world.get("logs"), TYPE_STRING):
		return "마왕성 이력 또는 기록 형식이 올바르지 않습니다."
	var evolution_history: Array = world.get("castle_evolution_history")
	if evolution_history.is_empty() or evolution_history[evolution_history.size() - 1] != stage_id:
		return "마왕성 진화 이력과 현재 단계가 일치하지 않습니다."
	var layout: Dictionary = world.get("quarter_layout", {})
	if layout.is_empty():
		return "저장된 맵 배치가 비어 있습니다."
	if layout.has("tile_size") and not _array_contains_only_numbers(layout.get("tile_size")):
		return "맵 타일 크기 형식이 올바르지 않습니다."
	if layout.has("socket_states") and not (layout.get("socket_states") is Dictionary):
		return "맵 연결 상태 형식이 올바르지 않습니다."
	for layout_key in ["placed_modules", "connections", "required_paths"]:
		if not layout.has(layout_key) or not _array_contains_only_type(layout.get(layout_key), TYPE_DICTIONARY):
			return "맵 배치 항목 형식이 올바르지 않습니다: %s" % layout_key
	for placed_value in layout.get("placed_modules"):
		var placed: Dictionary = placed_value
		for string_key in ["instance_id", "module_id", "legacy_room_id"]:
			if not (placed.get(string_key) is String):
				return "맵 모듈 문구 형식이 올바르지 않습니다: %s" % string_key
		if not _array_contains_only_numbers(placed.get("grid_origin")):
			return "맵 모듈 좌표 형식이 올바르지 않습니다."
		if placed.has("locked") and not (placed.get("locked") is bool):
			return "맵 모듈 잠금 형식이 올바르지 않습니다."
		if placed.has("replaceable_with") and not _array_contains_only_type(placed.get("replaceable_with"), TYPE_STRING):
			return "맵 모듈 교체 목록 형식이 올바르지 않습니다."
	for connection_value in layout.get("connections"):
		var connection: Dictionary = connection_value
		if not (connection.get("from") is String) or not (connection.get("to") is String):
			return "맵 연결 정보 형식이 올바르지 않습니다."
	for requirement_value in layout.get("required_paths"):
		var requirement: Dictionary = requirement_value
		if not (requirement.get("from") is String) or not (requirement.get("to") is String):
			return "맵 필수 경로 형식이 올바르지 않습니다."
	if layout.has("room_grid"):
		if not (layout.get("room_grid") is Dictionary):
			return "맵 격자 정보 형식이 올바르지 않습니다."
		var room_grid: Dictionary = layout.get("room_grid", {})
		if room_grid.has("cells") and not _array_contains_only_type(room_grid.get("cells"), TYPE_DICTIONARY):
			return "맵 격자 칸 정보 형식이 올바르지 않습니다."
		for grid_key in ["grid_size", "cell_size", "master_origin"]:
			if room_grid.has(grid_key) and not _array_contains_only_numbers(room_grid.get(grid_key)):
				return "맵 격자 좌표 형식이 올바르지 않습니다: %s" % grid_key

	var raid: Dictionary = payload.get("raid", {})
	if not (raid.get("selected_mission_id") is String) or not _array_contains_only_type(raid.get("selected_monster_ids"), TYPE_STRING):
		return "원정 편성 정보 형식이 올바르지 않습니다."
	for key in ["completed_raids", "last_raid_result", "next_defense_modifiers"]:
		if not _dictionary_value_is(raid, key, TYPE_DICTIONARY):
			return "원정 진행 정보 형식이 올바르지 않습니다: %s" % key
	var last_raid_result: Dictionary = raid.get("last_raid_result", {})
	if last_raid_result.has("lines") and not _array_contains_only_type(last_raid_result.get("lines"), TYPE_STRING):
		return "최근 원정 보고 형식이 올바르지 않습니다."
	if last_raid_result.has("reward") and not (last_raid_result.get("reward") is Dictionary):
		return "최근 원정 보상 형식이 올바르지 않습니다."
	var defense_modifiers: Dictionary = raid.get("next_defense_modifiers", {})
	for modifier_value in defense_modifiers.values():
		if not (modifier_value is Dictionary):
			return "손상된 다음 방어 효과가 포함되어 있습니다."
		var modifier: Dictionary = modifier_value
		for numeric_key in ["apply_on_day", "spawn_delay_bonus", "spawn_interval_bonus"]:
			if modifier.has(numeric_key) and not _is_number(modifier.get(numeric_key)):
				return "다음 방어 효과 수치가 올바르지 않습니다: %s" % numeric_key
		if modifier.has("extra_waves") and not _array_contains_only_type(modifier.get("extra_waves"), TYPE_DICTIONARY):
			return "다음 방어 추가 웨이브 형식이 올바르지 않습니다."
		for map_key in ["count_delta_by_enemy", "spawn_delay_bonus_by_enemy", "spawn_interval_bonus_by_enemy", "hp_scale_delta_by_enemy", "atk_scale_delta_by_enemy", "def_scale_delta_by_enemy", "reward_scale_delta_by_enemy"]:
			if modifier.has(map_key) and not _dictionary_contains_only_numbers(modifier.get(map_key)):
				return "다음 방어 적별 효과 형식이 올바르지 않습니다: %s" % map_key

	var campaign: Dictionary = payload.get("campaign", {})
	for key in ["seen_day_intros", "seen_combat_intros"]:
		if not _array_contains_only_numbers(campaign.get(key)):
			return "캠페인 이력 형식이 올바르지 않습니다: %s" % key
	for key in ["chapter_one_clear", "stage_two_prepared", "chapter_two_started", "stage_two_upgrade_funded", "stage_two_unlock_ready", "chapter_three_clear", "chapter_four_clear", "final_chapter_unlocked", "final_upgrade_ready", "final_preparation_confirmed", "completed", "finale_defeat_seen", "postgame_active", "first_promotion_completed", "facility_upgrade_unlocked"]:
		if not (campaign.get(key) is bool):
			return "캠페인 상태 형식이 올바르지 않습니다: %s" % key
	for key in ["final_battle_outcome", "last_security_grade"]:
		if not (campaign.get(key) is String):
			return "캠페인 결과 형식이 올바르지 않습니다: %s" % key
	var final_outcome: String = campaign.get("final_battle_outcome")
	if final_outcome not in ["", "defeat", "victory"]:
		return "최종전 결과 값이 올바르지 않습니다."
	if summary.get("campaign_completed") != campaign.get("completed") or summary.get("campaign_postgame_active") != campaign.get("postgame_active") or summary.get("final_battle_outcome") != final_outcome:
		return "저장 요약과 캠페인 결과가 일치하지 않습니다."
	var stage_index := int(CASTLE_STAGE_INDEX[stage_id])
	if (day < 15 and stage_index != 1) or (day >= 16 and stage_index < 2) or (day < 20 and stage_index > 2) or (day >= 21 and stage_index < 3) or (day < 27 and stage_index > 3) or (day >= 28 and stage_index != 4):
		return "날짜와 마왕성 진화 단계가 일치하지 않습니다."
	if stage_index >= 2 and not campaign.get("stage_two_unlock_ready"):
		return "Stage 02 해금 기록이 누락되었습니다."
	if stage_index >= 3 and not campaign.get("chapter_three_clear"):
		return "Stage 03 해금 기록이 누락되었습니다."
	if stage_index >= 4 and not campaign.get("final_upgrade_ready"):
		return "Stage 04 해금 기록이 누락되었습니다."
	if day >= CAMPAIGN_FINAL_DAY and not campaign.get("final_preparation_confirmed"):
		return "DAY 30 최종 준비 기록이 누락되었습니다."
	if day < CAMPAIGN_FINAL_DAY and (campaign.get("completed") or campaign.get("postgame_active") or final_outcome != ""):
		return "최종전 결과가 DAY 30 이전에 기록되어 있습니다."
	if campaign.get("completed") != (final_outcome == "victory"):
		return "캠페인 완료 상태와 최종전 결과가 일치하지 않습니다."
	if final_outcome == "defeat" and not campaign.get("finale_defeat_seen"):
		return "최종전 패배 기록이 일치하지 않습니다."
	if campaign.get("postgame_active") and not campaign.get("completed"):
		return "후일담 상태에 완료 기록이 없습니다."

	var result: Dictionary = payload.get("result", {})
	for key in ["summary", "rewards_pending", "last_growth_choice_summary"]:
		if not _dictionary_value_is(result, key, TYPE_DICTIONARY):
			return "결산 정보 형식이 올바르지 않습니다: %s" % key
	if not _dictionary_value_is(result, "last_growth_summary", TYPE_ARRAY):
		return "성장 결과 형식이 올바르지 않습니다."
	var result_summary: Dictionary = result.get("summary", {})
	if result_summary.has("lines") and not _array_contains_only_type(result_summary.get("lines"), TYPE_STRING):
		return "결산 문구 형식이 올바르지 않습니다."
	for bool_key in ["win", "management_only"]:
		if result_summary.has(bool_key) and not (result_summary.get(bool_key) is bool):
			return "결산 상태 형식이 올바르지 않습니다: %s" % bool_key
	for growth_row_value in result.get("last_growth_summary"):
		if not (growth_row_value is Dictionary):
			return "손상된 몬스터 성장 결과가 포함되어 있습니다."
		var growth_row: Dictionary = growth_row_value
		for numeric_key in ["level_before", "level_after", "levels_gained", "exp_before", "exp_after", "exp_gain", "next_exp", "shared_exp", "activity_exp", "damage_dealt", "damage_absorbed", "finishing_blows", "facility_value", "choice_bonus_exp"]:
			if growth_row.has(numeric_key) and not _is_number(growth_row.get(numeric_key)):
				return "몬스터 성장 수치 형식이 올바르지 않습니다: %s" % numeric_key
		if growth_row.has("activity_breakdown") and not _dictionary_contains_only_numbers(growth_row.get("activity_breakdown")):
			return "몬스터 활약 내역 형식이 올바르지 않습니다."
	for reward_value in result.get("rewards_pending").values():
		if not _is_number(reward_value):
			return "대기 보상 수치 형식이 올바르지 않습니다."
	for key in ["growth_reviewed", "growth_choice_applied"]:
		if not (result.get(key) is bool):
			return "성장 선택 상태 형식이 올바르지 않습니다: %s" % key
	if not (result.get("growth_choice_monster_id") is String):
		return "성장 선택 대상 형식이 올바르지 않습니다."
	var growth_choice_summary: Dictionary = result.get("last_growth_choice_summary", {})
	if result.get("growth_choice_applied"):
		for string_key in ["monster_id", "display_name", "preparation_id", "preparation_preview", "preparation_summary"]:
			if not (growth_choice_summary.get(string_key) is String):
				return "집중 성장 요약 문구 형식이 올바르지 않습니다: %s" % string_key
		for numeric_key in ["bonus_exp", "preparation_day", "level_before", "level_after", "exp_before", "exp_after"]:
			if not _is_number(growth_choice_summary.get(numeric_key)):
				return "집중 성장 요약 수치 형식이 올바르지 않습니다: %s" % numeric_key
		if result.get("growth_choice_monster_id") == "" or growth_choice_summary.get("monster_id") != result.get("growth_choice_monster_id"):
			return "집중 성장 대상과 요약이 일치하지 않습니다."
	elif result.get("growth_choice_monster_id") != "" or not growth_choice_summary.is_empty():
		return "적용되지 않은 집중 성장 정보가 남아 있습니다."
	if payload.get("screen") == "result" and day == CAMPAIGN_FINAL_DAY:
		if final_outcome == "" or bool(result_summary.get("win", false)) != (final_outcome == "victory"):
			return "DAY 30 결산 승패와 최종전 결과가 일치하지 않습니다."

	var onboarding: Dictionary = payload.get("onboarding", {})
	for key in ["seen_dialogue_ids", "tutorial_manager"]:
		if not _dictionary_value_is(onboarding, key, TYPE_DICTIONARY):
			return "안내 진행 정보 형식이 올바르지 않습니다: %s" % key
	if not _array_contains_only_type(onboarding.get("dialogue_queue"), TYPE_DICTIONARY):
		return "대화 진행 정보 형식이 올바르지 않습니다."
	for key in ["stage_id", "dialogue_return_screen", "dialogue_complete_action"]:
		if not (onboarding.get(key) is String):
			return "안내 진행 문구 형식이 올바르지 않습니다: %s" % key
	if onboarding.get("stage_id") != game_state.get("onboarding_stage"):
		return "안내 단계와 게임 진행 단계가 일치하지 않습니다."
	if not _is_number(onboarding.get("dialogue_index")) or int(onboarding.get("dialogue_index")) < 0:
		return "대화 순서 형식이 올바르지 않습니다."
	if onboarding.get("dialogue_return_screen") not in SAFE_SCREENS or onboarding.get("dialogue_return_screen") == "dialogue":
		return "대화 종료 후 돌아갈 화면이 올바르지 않습니다."
	var dialogue_index := int(onboarding.get("dialogue_index"))
	var dialogue_queue: Array = onboarding.get("dialogue_queue")
	if payload.get("screen") == "dialogue" and (dialogue_queue.is_empty() or dialogue_index >= dialogue_queue.size()):
		return "대화 화면의 진행 위치가 올바르지 않습니다."
	if payload.get("screen") == "result" and result_summary.is_empty():
		return "결산 화면에 결산 내용이 없습니다."
	if payload.get("screen") == "ending" and (not campaign.get("completed") or final_outcome != "victory"):
		return "엔딩 화면과 캠페인 완료 상태가 일치하지 않습니다."
	for key in ["name_entry_tip_dismissed", "tutorial_gate_enabled"]:
		if not (onboarding.get(key) is bool):
			return "안내 진행 상태 형식이 올바르지 않습니다: %s" % key
	var tutorial_state: Dictionary = onboarding.get("tutorial_manager", {})
	if not _dictionary_value_is(tutorial_state, "completed", TYPE_DICTIONARY) or not _is_number(tutorial_state.get("current_index")) or int(tutorial_state.get("current_index")) < 0 or not (tutorial_state.get("active") is bool):
		return "튜토리얼 진행 정보 형식이 올바르지 않습니다."
	if day >= 5 and (not game_state.get("onboarding_complete") or onboarding.get("tutorial_gate_enabled") or tutorial_state.get("active")):
		return "정규 캠페인에 완료되지 않은 튜토리얼 상태가 남아 있습니다."
	return ""


static func _dictionary_value_is(source: Dictionary, key: String, expected_type: int) -> bool:
	return source.has(key) and typeof(source.get(key)) == expected_type


static func _array_contains_only_type(value, expected_type: int) -> bool:
	if not (value is Array):
		return false
	for entry in value:
		if typeof(entry) != expected_type:
			return false
	return true


static func _array_contains_only_numbers(value) -> bool:
	if not (value is Array):
		return false
	for entry in value:
		if not _is_number(entry):
			return false
	return true


static func _dictionary_contains_only_numbers(value) -> bool:
	if not (value is Dictionary):
		return false
	for entry in value.values():
		if not _is_number(entry):
			return false
	return true


static func _is_number(value) -> bool:
	return value is int or value is float


static func _inspection(status: String, error: String) -> Dictionary:
	return {
		"status": status,
		"error": error,
		"payload": {},
		"summary": {},
		"saved_at_unix": 0,
		"saved_at_text": ""
	}
