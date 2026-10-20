extends RefCounted
# These are format versions of one campaign, never independent save slots.
# v5 is written last by GameRoot. Recoverable write errors restore the complete set.
static func snapshot(paths: Array) -> Dictionary:
	var result := {}
	for path in paths:
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file == null:
				return {"ok": false, "files": {}, "error": "기존 저장 파일을 읽을 수 없습니다: %s (오류 %d)" % [path, FileAccess.get_open_error()]}
			result[path] = file.get_buffer(file.get_length())
		else:
			result[path] = null
	return {"ok": true, "files": result}

static func restore(snapshot_data: Dictionary) -> bool:
	var ok := true
	for path in snapshot_data.get("files", {}):
		var contents = snapshot_data.files[path]
		if contents == null:
			if FileAccess.file_exists(path):
				ok = DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK and ok
			continue
		# Stage restoration before replacing a file, preserving readable data on error.
		var restore_path: String = str(path) + ".restore"
		var file := FileAccess.open(restore_path, FileAccess.WRITE)
		if file == null:
			ok = false
			continue
		file.store_buffer(contents)
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK:
			ok = false
			continue
		ok = DirAccess.rename_absolute(ProjectSettings.globalize_path(restore_path), ProjectSettings.globalize_path(path)) == OK and ok
	return ok
