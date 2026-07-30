extends RefCounted
class_name StoryCatalog

const DEFAULT_MANIFEST_PATH := "res://data/story/v122_main/manifest.json"
const SUPPORTED_SCHEMA_VERSION := 1

var source_sha256: String = ""
var source_snapshot: String = ""
var loaded := false
var load_errors: Array[String] = []

var _scenes_by_id: Dictionary = {}
var _scene_ids_by_day_trigger: Dictionary = {}


func load_default() -> bool:
	return load_manifest(DEFAULT_MANIFEST_PATH)


func load_manifest(manifest_path: String) -> bool:
	clear()
	var manifest_value = _read_json(manifest_path)
	if not (manifest_value is Dictionary):
		load_errors.append("Story manifest must be a JSON object: %s" % manifest_path)
		return false
	var manifest: Dictionary = manifest_value
	if int(manifest.get("schema_version", 0)) != SUPPORTED_SCHEMA_VERSION:
		load_errors.append("Unsupported story manifest schema: %s" % str(manifest.get("schema_version", "")))
	source_sha256 = str(manifest.get("source_sha256", "")).to_lower()
	source_snapshot = str(manifest.get("source_snapshot", ""))
	if source_sha256.length() != 64:
		load_errors.append("Story manifest source_sha256 must contain 64 hex characters.")
	var day_files = manifest.get("day_files", [])
	if not (day_files is Array) or day_files.is_empty():
		load_errors.append("Story manifest day_files must not be empty.")
	else:
		for path_value in day_files:
			var day_path := str(path_value)
			if day_path == "":
				load_errors.append("Story manifest contains an empty day file path.")
				continue
			_load_day_file(day_path)
	loaded = load_errors.is_empty()
	return loaded


func clear() -> void:
	source_sha256 = ""
	source_snapshot = ""
	loaded = false
	load_errors.clear()
	_scenes_by_id.clear()
	_scene_ids_by_day_trigger.clear()


func scene(scene_id: String) -> Dictionary:
	return _scenes_by_id.get(scene_id, {}).duplicate(true)


func has_scene(scene_id: String) -> bool:
	return _scenes_by_id.has(scene_id)


func scene_count() -> int:
	return _scenes_by_id.size()


func all_scene_ids() -> Array[String]:
	var result: Array[String] = []
	for scene_id_value in _scenes_by_id.keys():
		result.append(str(scene_id_value))
	result.sort()
	return result


func scenes_for(day: int, trigger: String, facts: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var key := _day_trigger_key(day, trigger)
	for scene_id_value in _scene_ids_by_day_trigger.get(key, []):
		var candidate: Dictionary = _scenes_by_id.get(str(scene_id_value), {})
		if conditions_match(candidate.get("conditions", {}), facts):
			result.append(candidate.duplicate(true))
	result.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_priority := int(left.get("priority", 0))
		var right_priority := int(right.get("priority", 0))
		if left_priority != right_priority:
			return left_priority < right_priority
		if trigger == "combat_time":
			return float(left.get("metadata", {}).get("time_seconds", 0.0)) < float(right.get("metadata", {}).get("time_seconds", 0.0))
		if trigger == "combat_boss_hp":
			return float(left.get("metadata", {}).get("threshold", 0.0)) > float(right.get("metadata", {}).get("threshold", 0.0))
		return str(left.get("id", "")) < str(right.get("id", ""))
	)
	return result


func has_story_for(day: int, trigger: String, facts: Dictionary = {}) -> bool:
	return not scenes_for(day, trigger, facts).is_empty()


func has_trigger(day: int, trigger: String) -> bool:
	return not _scene_ids_by_day_trigger.get(_day_trigger_key(day, trigger), []).is_empty()


func optional_scenes(day: int, facts: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for scene_value in _scenes_by_id.values():
		if not (scene_value is Dictionary):
			continue
		var candidate: Dictionary = scene_value
		if int(candidate.get("day", 0)) != day:
			continue
		var metadata: Dictionary = candidate.get("metadata", {}) if candidate.get("metadata") is Dictionary else {}
		if not bool(candidate.get("optional", metadata.get("optional", false))):
			continue
		if conditions_match(candidate.get("conditions", {}), facts):
			result.append(candidate.duplicate(true))
	result.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("priority", 0)) < int(right.get("priority", 0))
	)
	return result


static func conditions_match(conditions_value, facts: Dictionary) -> bool:
	if conditions_value == null:
		return true
	if conditions_value is Array:
		for clause_value in conditions_value:
			if not _clause_matches(clause_value, facts):
				return false
		return true
	if not (conditions_value is Dictionary):
		return false
	var conditions: Dictionary = conditions_value
	if conditions.is_empty():
		return true
	for clause_value in conditions.get("all", []):
		if not _clause_matches(clause_value, facts):
			return false
	var any_clauses = conditions.get("any", [])
	if any_clauses is Array and not any_clauses.is_empty():
		var any_match := false
		for clause_value in any_clauses:
			if _clause_matches(clause_value, facts):
				any_match = true
				break
		if not any_match:
			return false
	for clause_value in conditions.get("none", []):
		if _clause_matches(clause_value, facts):
			return false
	if conditions.has("fact"):
		return _clause_matches(conditions, facts)
	return true


static func _clause_matches(clause_value, facts: Dictionary) -> bool:
	if not (clause_value is Dictionary):
		return false
	var clause: Dictionary = clause_value
	var fact_id := str(clause.get("fact", ""))
	if fact_id == "":
		return false
	var present := facts.has(fact_id)
	var actual = facts.get(fact_id)
	var expected = clause.get("value")
	match str(clause.get("op", "eq")):
		"eq":
			return present and actual == expected
		"ne":
			return not present or actual != expected
		"exists":
			return present
		"not_exists":
			return not present
		"truthy":
			return present and bool(actual)
		"falsy":
			return not present or not bool(actual)
		"contains":
			if actual is Array:
				return actual.has(expected)
			if actual is Dictionary:
				return actual.has(expected)
			return str(actual).contains(str(expected))
		"not_contains":
			if actual is Array:
				return not actual.has(expected)
			if actual is Dictionary:
				return not actual.has(expected)
			return not str(actual).contains(str(expected))
		"gt":
			return present and float(actual) > float(expected)
		"gte":
			return present and float(actual) >= float(expected)
		"lt":
			return present and float(actual) < float(expected)
		"lte":
			return present and float(actual) <= float(expected)
	return false


func _load_day_file(day_path: String) -> void:
	var document_value = _read_json(day_path)
	if not (document_value is Dictionary):
		load_errors.append("Story day file must be a JSON object: %s" % day_path)
		return
	var document: Dictionary = document_value
	if int(document.get("schema_version", 0)) != SUPPORTED_SCHEMA_VERSION:
		load_errors.append("Unsupported story day schema: %s" % day_path)
	var document_day := int(document.get("day", 0))
	if document_day < 1:
		load_errors.append("Story day must be positive: %s" % day_path)
	var scenes = document.get("scenes", [])
	if not (scenes is Array):
		load_errors.append("Story scenes must be an array: %s" % day_path)
		return
	for scene_value in scenes:
		_register_scene(scene_value, document_day, day_path)


func _register_scene(scene_value, document_day: int, source_path: String) -> void:
	if not (scene_value is Dictionary):
		load_errors.append("Story scene must be an object: %s" % source_path)
		return
	var candidate: Dictionary = scene_value.duplicate(true)
	var scene_id := str(candidate.get("id", ""))
	var day := int(candidate.get("day", document_day))
	var trigger := str(candidate.get("trigger", ""))
	if scene_id == "":
		load_errors.append("Story scene id is empty: %s" % source_path)
		return
	if _scenes_by_id.has(scene_id):
		load_errors.append("Duplicate story scene id: %s" % scene_id)
		return
	if day != document_day or day < 1:
		load_errors.append("Story scene day mismatch: %s" % scene_id)
	if trigger == "":
		load_errors.append("Story scene trigger is empty: %s" % scene_id)
	var cues = candidate.get("cues", [])
	if not (cues is Array) or cues.is_empty():
		load_errors.append("Story scene has no cues: %s" % scene_id)
		return
	var cue_ids: Dictionary = {}
	for cue_value in cues:
		if not (cue_value is Dictionary):
			load_errors.append("Story cue must be an object: %s" % scene_id)
			continue
		var cue: Dictionary = cue_value
		var cue_id := str(cue.get("id", ""))
		if cue_id == "" or cue_ids.has(cue_id):
			load_errors.append("Empty or duplicate cue id in scene %s: %s" % [scene_id, cue_id])
		else:
			cue_ids[cue_id] = true
		if str(cue.get("speaker_id", "")) == "":
			load_errors.append("Story cue speaker_id is empty: %s" % cue_id)
		if str(cue.get("text_ko", "")) == "":
			load_errors.append("Story cue text_ko is empty: %s" % cue_id)
		if not cue.has("portrait_emotion"):
			load_errors.append("Story cue portrait_emotion is missing: %s" % cue_id)
	candidate["day"] = day
	candidate["trigger"] = trigger
	_scenes_by_id[scene_id] = candidate
	var key := _day_trigger_key(day, trigger)
	var ids: Array = _scene_ids_by_day_trigger.get(key, [])
	ids.append(scene_id)
	_scene_ids_by_day_trigger[key] = ids


func _read_json(path: String):
	if not FileAccess.file_exists(path):
		load_errors.append("Story JSON not found: %s" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		load_errors.append("Story JSON parse error %s:%d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


func _day_trigger_key(day: int, trigger: String) -> String:
	return "%02d:%s" % [day, trigger]
