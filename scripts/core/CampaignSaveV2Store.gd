extends RefCounted
class_name CampaignSaveV2Store

const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")
const MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")

const SAVE_PATH := "user://campaign_save_v2.json"
const STATUS_VALID := "valid"
const STATUS_MISSING := "missing"
const STATUS_CORRUPT := "corrupt"
const STATUS_UNSUPPORTED := "unsupported"


static func inspect(path: String, instance_templates: Dictionary, metric_definitions: Dictionary) -> Dictionary:
	var inspection := _inspect_file(path, instance_templates, metric_definitions)
	if str(inspection.get("status", "")) in [STATUS_MISSING, STATUS_CORRUPT]:
		_recover_interrupted_write(path, instance_templates, metric_definitions)
		inspection = _inspect_file(path, instance_templates, metric_definitions)
	return inspection


static func write(envelope: Dictionary, path: String, instance_templates: Dictionary, metric_definitions: Dictionary) -> Dictionary:
	var validation_error := MigratorScript.validate_v2(envelope, instance_templates, metric_definitions)
	if validation_error != "":
		return {"ok": false, "error": "저장 v2 자료가 올바르지 않습니다: %s" % validation_error}
	var output: Dictionary = envelope.duplicate(true)
	output["saved_at_unix"] = int(Time.get_unix_time_from_system())
	output["saved_at_text"] = Time.get_datetime_string_from_system(false, true)
	var temp_path := "%s.tmp" % path
	var backup_path := "%s.bak" % path
	var temp_file := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		return {"ok": false, "error": "저장 v2 임시 파일을 만들 수 없습니다."}
	temp_file.store_string(JSON.stringify(output, "\t"))
	temp_file.flush()
	var write_error := temp_file.get_error()
	temp_file.close()
	if write_error != OK:
		_remove_if_exists(temp_path)
		return {"ok": false, "error": "저장 v2 임시 파일을 끝까지 기록하지 못했습니다."}
	if str(_inspect_file(temp_path, instance_templates, metric_definitions).get("status", "")) != STATUS_VALID:
		_remove_if_exists(temp_path)
		return {"ok": false, "error": "저장 v2 임시 파일을 다시 읽어 검증하지 못했습니다."}
	_remove_if_exists(backup_path)
	var had_existing := FileAccess.file_exists(path)
	if had_existing and DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup_path)) != OK:
		_remove_if_exists(temp_path)
		return {"ok": false, "error": "기존 저장 v2를 백업하지 못했습니다."}
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) != OK:
		_restore_backup(path, backup_path, had_existing)
		return {"ok": false, "error": "새 저장 v2를 적용하지 못했습니다."}
	if str(_inspect_file(path, instance_templates, metric_definitions).get("status", "")) != STATUS_VALID:
		_restore_backup(path, backup_path, had_existing)
		return {"ok": false, "error": "적용한 저장 v2를 재검증하지 못했습니다."}
	_remove_if_exists(backup_path)
	return {"ok": true, "error": ""}


static func migrate_v1_file(v1_path: String, v2_path: String, instance_templates: Dictionary, metric_definitions: Dictionary) -> Dictionary:
	var v1_inspection := CampaignSaveStoreScript.inspect(v1_path)
	var migration := MigratorScript.migrate_inspection(v1_inspection, instance_templates, metric_definitions)
	if not bool(migration.get("ok", false)):
		return {"ok": false, "error": str(migration.get("error", "저장 v1 변환에 실패했습니다."))}
	var write_result := write(migration.get("envelope", {}), v2_path, instance_templates, metric_definitions)
	if not bool(write_result.get("ok", false)):
		return write_result
	if not FileAccess.file_exists(v1_path):
		return {"ok": false, "error": "저장 v2 변환 뒤 기존 저장 v1이 보존되지 않았습니다."}
	return {"ok": true, "error": ""}


static func delete(path: String) -> bool:
	var ok := true
	for candidate in [path, "%s.tmp" % path, "%s.bak" % path]:
		if FileAccess.file_exists(candidate) and DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) != OK:
			ok = false
	return ok


static func _inspect_file(path: String, instance_templates: Dictionary, metric_definitions: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _inspection(STATUS_MISSING, "저장 v2 파일이 없습니다.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _inspection(STATUS_CORRUPT, "저장 v2 파일을 열 수 없습니다.")
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return _inspection(STATUS_CORRUPT, "저장 v2 JSON 형식이 올바르지 않습니다.")
	var envelope: Dictionary = parsed
	if not (envelope.get("version") is int or envelope.get("version") is float):
		return _inspection(STATUS_CORRUPT, "저장 v2 버전 형식이 올바르지 않습니다.")
	if int(envelope.get("version")) != MigratorScript.TARGET_VERSION:
		return _inspection(STATUS_UNSUPPORTED, "지원하지 않는 저장 v2 버전입니다.")
	var validation_error := MigratorScript.validate_v2(envelope, instance_templates, metric_definitions)
	if validation_error != "":
		return _inspection(STATUS_CORRUPT, validation_error)
	return {"status": STATUS_VALID, "error": "", "envelope": envelope.duplicate(true)}


static func _recover_interrupted_write(path: String, instance_templates: Dictionary, metric_definitions: Dictionary) -> bool:
	for candidate in ["%s.tmp" % path, "%s.bak" % path]:
		if str(_inspect_file(candidate, instance_templates, metric_definitions).get("status", "")) != STATUS_VALID:
			continue
		_remove_if_exists(path)
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(candidate), ProjectSettings.globalize_path(path)) != OK:
			return false
		var stale := "%s.bak" % path if candidate.ends_with(".tmp") else "%s.tmp" % path
		_remove_if_exists(stale)
		return true
	return false


static func _restore_backup(path: String, backup_path: String, had_existing: bool) -> bool:
	_remove_if_exists(path)
	if not had_existing:
		return true
	if not FileAccess.file_exists(backup_path):
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path)) == OK


static func _remove_if_exists(path: String) -> bool:
	return not FileAccess.file_exists(path) or DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK


static func _inspection(status: String, error: String) -> Dictionary:
	return {"status": status, "error": error, "envelope": {}}
