extends RefCounted
class_name CampaignSaveV5Store

const SaveV4StoreScript = preload("res://scripts/systems/save/CampaignSaveV4Store.gd")
const MigratorScript = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd")

const SAVE_PATH := "user://campaign_save_v5.json"
const STATUS_VALID := "valid"
const STATUS_MISSING := "missing"
const STATUS_CORRUPT := "corrupt"
const STATUS_UNSUPPORTED := "unsupported"


static func inspect(path: String, instance_templates: Dictionary, metric_definitions: Dictionary, update3_catalogs: Dictionary = {}, update4_catalogs: Dictionary = {}) -> Dictionary:
	var inspection := _inspect_file(path, instance_templates, metric_definitions, update3_catalogs, update4_catalogs)
	if str(inspection.get("status", "")) in [STATUS_MISSING, STATUS_CORRUPT]:
		if _recover_interrupted_write(path, instance_templates, metric_definitions, update3_catalogs, update4_catalogs):
			inspection = _inspect_file(path, instance_templates, metric_definitions, update3_catalogs, update4_catalogs)
		elif str(inspection.get("status", "")) == STATUS_CORRUPT:
			_quarantine(path)
	return inspection


static func write(envelope: Dictionary, path: String, instance_templates: Dictionary, metric_definitions: Dictionary, update3_catalogs: Dictionary = {}, update4_catalogs: Dictionary = {}) -> Dictionary:
	var validation_error := MigratorScript.validate_v5(envelope, instance_templates, metric_definitions, update3_catalogs, update4_catalogs)
	if validation_error != "":
		return {"ok": false, "error": "저장 v5 자료가 올바르지 않습니다: %s" % validation_error}
	var output := envelope.duplicate(true)
	output["saved_at_unix"] = int(Time.get_unix_time_from_system())
	output["saved_at_text"] = Time.get_datetime_string_from_system(false, true)
	var temp_path := "%s.tmp" % path
	var backup_path := "%s.bak" % path
	var temp_file := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		return {"ok": false, "error": "저장 v5 임시 파일을 만들 수 없습니다."}
	temp_file.store_string(JSON.stringify(output, "\t"))
	temp_file.flush()
	var write_error := temp_file.get_error()
	temp_file.close()
	if write_error != OK:
		_remove_if_exists(temp_path)
		return {"ok": false, "error": "저장 v5 임시 파일을 끝까지 기록하지 못했습니다."}
	if str(_inspect_file(temp_path, instance_templates, metric_definitions, update3_catalogs, update4_catalogs).get("status", "")) != STATUS_VALID:
		_remove_if_exists(temp_path)
		return {"ok": false, "error": "저장 v5 임시 파일을 다시 읽어 검증하지 못했습니다."}
	_remove_if_exists(backup_path)
	var had_existing := FileAccess.file_exists(path)
	if had_existing and DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup_path)) != OK:
		_remove_if_exists(temp_path)
		return {"ok": false, "error": "기존 저장 v5를 백업하지 못했습니다."}
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) != OK:
		_restore_backup(path, backup_path, had_existing)
		return {"ok": false, "error": "새 저장 v5를 적용하지 못했습니다."}
	if str(_inspect_file(path, instance_templates, metric_definitions, update3_catalogs, update4_catalogs).get("status", "")) != STATUS_VALID:
		_restore_backup(path, backup_path, had_existing)
		return {"ok": false, "error": "적용한 저장 v5를 재검증하지 못했습니다."}
	_remove_if_exists(backup_path)
	_remove_if_exists("%s.corrupt" % path)
	return {"ok": true, "error": ""}


static func migrate_v4_file(v4_path: String, v5_path: String, instance_templates: Dictionary, metric_definitions: Dictionary, update3_catalogs: Dictionary = {}, update4_catalogs: Dictionary = {}) -> Dictionary:
	var v4_inspection := SaveV4StoreScript.inspect(v4_path, instance_templates, metric_definitions, update3_catalogs)
	if str(v4_inspection.get("status", "")) != SaveV4StoreScript.STATUS_VALID:
		return {"ok": false, "error": str(v4_inspection.get("error", "유효한 저장 v4가 없습니다."))}
	var migration := MigratorScript.migrate_envelope(v4_inspection.get("envelope", {}), instance_templates, metric_definitions, update3_catalogs, update4_catalogs)
	if not bool(migration.get("ok", false)):
		return {"ok": false, "error": str(migration.get("error", "저장 v4를 v5로 변환하지 못했습니다."))}
	var result := write(migration.get("envelope", {}), v5_path, instance_templates, metric_definitions, update3_catalogs, update4_catalogs)
	if bool(result.get("ok", false)) and not FileAccess.file_exists(v4_path):
		return {"ok": false, "error": "저장 v5 변환 후 기존 저장 v4가 보존되지 않았습니다."}
	return result


static func delete(path: String) -> bool:
	var ok := true
	for candidate in [path, "%s.tmp" % path, "%s.bak" % path, "%s.corrupt" % path]:
		if FileAccess.file_exists(candidate) and DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) != OK:
			ok = false
	return ok


static func _inspect_file(path: String, instance_templates: Dictionary, metric_definitions: Dictionary, update3_catalogs: Dictionary, update4_catalogs: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _inspection(STATUS_MISSING, "저장 v5 파일이 없습니다.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _inspection(STATUS_CORRUPT, "저장 v5 파일을 읽을 수 없습니다.")
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return _inspection(STATUS_CORRUPT, "저장 v5 JSON 형식이 올바르지 않습니다.")
	var envelope: Dictionary = parsed
	if not (envelope.get("version") is int or envelope.get("version") is float):
		return _inspection(STATUS_CORRUPT, "저장 v5 버전 형식이 올바르지 않습니다.")
	if int(envelope.get("version")) != MigratorScript.TARGET_VERSION:
		return _inspection(STATUS_UNSUPPORTED, "지원하지 않는 저장 v5 버전입니다.")
	var validation_error := MigratorScript.validate_v5(envelope, instance_templates, metric_definitions, update3_catalogs, update4_catalogs)
	if validation_error != "":
		return _inspection(STATUS_CORRUPT, validation_error)
	return {"status": STATUS_VALID, "error": "", "envelope": envelope.duplicate(true)}


static func _recover_interrupted_write(path: String, instance_templates: Dictionary, metric_definitions: Dictionary, update3_catalogs: Dictionary, update4_catalogs: Dictionary) -> bool:
	for candidate in ["%s.tmp" % path, "%s.bak" % path]:
		if str(_inspect_file(candidate, instance_templates, metric_definitions, update3_catalogs, update4_catalogs).get("status", "")) != STATUS_VALID:
			continue
		_remove_if_exists(path)
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(candidate), ProjectSettings.globalize_path(path)) != OK:
			return false
		_remove_if_exists("%s.bak" % path if candidate.ends_with(".tmp") else "%s.tmp" % path)
		return true
	return false


static func _quarantine(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var quarantine_path := "%s.corrupt" % path
	_remove_if_exists(quarantine_path)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(quarantine_path)) == OK


static func _restore_backup(path: String, backup_path: String, had_existing: bool) -> bool:
	_remove_if_exists(path)
	if not had_existing:
		return true
	return FileAccess.file_exists(backup_path) and DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path)) == OK


static func _remove_if_exists(path: String) -> bool:
	return not FileAccess.file_exists(path) or DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK


static func _inspection(status: String, error: String) -> Dictionary:
	return {"status": status, "error": error, "envelope": {}}
