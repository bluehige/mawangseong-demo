class_name V20SaveStore
extends RefCounted

const SAVE_VERSION := 2
const SAVE_PATH := "user://v20/campaign_v20.json"
const STATUS_VALID := "valid"
const STATUS_MISSING := "missing"
const STATUS_CORRUPT := "corrupt"
const STATUS_UNSUPPORTED := "unsupported"


static func inspect(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _inspection(STATUS_MISSING, "2.0 저장 파일이 없습니다.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _inspection(STATUS_CORRUPT, "2.0 저장 파일을 열 수 없습니다.")
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return _inspection(STATUS_CORRUPT, "2.0 저장 JSON이 올바르지 않습니다.")
	if int(parsed.get("version", 0)) != SAVE_VERSION:
		return _inspection(STATUS_UNSUPPORTED, "지원하지 않는 2.0 저장 버전입니다.")
	var payload = parsed.get("payload")
	var summary = parsed.get("summary")
	var validation_error := validate(payload, summary)
	if validation_error != "":
		return _inspection(STATUS_CORRUPT, validation_error)
	return {"status": STATUS_VALID, "error": "", "payload": payload.duplicate(true), "summary": summary.duplicate(true), "saved_at_text": str(parsed.get("saved_at_text", ""))}


static func write(payload: Dictionary, summary: Dictionary, path: String = SAVE_PATH) -> Dictionary:
	var validation_error := validate(payload, summary)
	if validation_error != "":
		return {"ok": false, "error": validation_error}
	var absolute := ProjectSettings.globalize_path(path)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if dir_error != OK:
		return {"ok": false, "error": "2.0 저장 폴더를 만들 수 없습니다."}
	var envelope := {"version": SAVE_VERSION, "saved_at_unix": int(Time.get_unix_time_from_system()), "saved_at_text": Time.get_datetime_string_from_system(false, true), "summary": summary.duplicate(true), "payload": payload.duplicate(true)}
	var temp_path := "%s.tmp" % path
	var temp := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp == null:
		return {"ok": false, "error": "2.0 임시 저장 파일을 만들 수 없습니다."}
	temp.store_string(JSON.stringify(envelope, "\t"))
	temp.flush()
	var write_error := temp.get_error()
	temp.close()
	if write_error != OK or str(inspect(temp_path).get("status", "")) != STATUS_VALID:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return {"ok": false, "error": "2.0 임시 저장 재검증에 실패했습니다."}
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
	if str(inspect(path).get("status", "")) != STATUS_VALID:
		DirAccess.remove_absolute(absolute)
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), absolute)
		return {"ok": false, "error": "적용한 2.0 저장 재검증에 실패했습니다."}
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	return {"ok": true, "error": ""}


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


static func _inspection(status: String, error: String) -> Dictionary:
	return {"status": status, "error": error, "payload": {}, "summary": {}, "saved_at_text": ""}
