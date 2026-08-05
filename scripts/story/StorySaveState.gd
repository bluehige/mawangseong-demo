class_name StorySaveState
extends RefCounted

const SCHEMA_VERSION := 1
const MIN_CAMPAIGN_DAY := 1
const MAX_CAMPAIGN_DAY := 30
const FORBIDDEN_CONTENT_KEYS := [
	"dialogue_queue",
	"queue",
	"cues",
	"lines",
	"text"
]


static func default_state(legacy_cutover_day: int = MIN_CAMPAIGN_DAY) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"current_scene_id": "",
		"current_cue_id": "",
		"cursor": 0,
		"current_facts": {},
		"seen_scene_ids": [],
		"seen_scene_scope_ids": [],
		"seen_cue_ids": [],
		"pending_return_screen": "",
		"pending_action": "",
		"auto_enabled": false,
		"legacy_cutover_day": clampi(legacy_cutover_day, MIN_CAMPAIGN_DAY, MAX_CAMPAIGN_DAY)
	}


static func build(value: Dictionary = {}, fallback_cutover_day: int = MIN_CAMPAIGN_DAY) -> Dictionary:
	var cutover_day := (
		int(value.get("legacy_cutover_day", fallback_cutover_day))
		if _is_integer_number(value.get("legacy_cutover_day", fallback_cutover_day))
		else fallback_cutover_day
	)
	var result := default_state(cutover_day)
	result["seen_scene_ids"] = _normalized_ids(
		value.get("seen_scene_ids", []) if value.get("seen_scene_ids") is Array else []
	)
	result["seen_scene_scope_ids"] = _normalized_ids(
		value.get("seen_scene_scope_ids", []) if value.get("seen_scene_scope_ids") is Array else []
	)
	result["seen_cue_ids"] = _normalized_ids(
		value.get("seen_cue_ids", []) if value.get("seen_cue_ids") is Array else []
	)
	result["auto_enabled"] = bool(value.get("auto_enabled", false)) if value.get("auto_enabled") is bool else false
	var current_scene_id := str(value.get("current_scene_id", ""))
	var current_cue_id := str(value.get("current_cue_id", ""))
	if current_scene_id == "" or current_cue_id == "":
		return result
	result["current_scene_id"] = current_scene_id
	result["current_cue_id"] = current_cue_id
	result["cursor"] = maxi(
		0,
		int(value.get("cursor", 0)) if _is_integer_number(value.get("cursor", 0)) else 0
	)
	result["current_facts"] = (
		value.get("current_facts", {}).duplicate(true)
		if value.get("current_facts") is Dictionary
		else {}
	)
	result["pending_return_screen"] = str(value.get("pending_return_screen", ""))
	result["pending_action"] = str(value.get("pending_action", ""))
	return result


static func normalize(value, legacy_cutover_day: int = MIN_CAMPAIGN_DAY) -> Dictionary:
	if not value is Dictionary:
		return default_state(legacy_cutover_day)
	var source: Dictionary = value
	return build(source, legacy_cutover_day)


static func validate_optional_payload(payload: Dictionary, safe_screens: Array = []) -> String:
	if not payload.has("story"):
		return ""
	if not payload.get("story") is Dictionary:
		return "스토리 진행 정보 형식이 올바르지 않습니다."
	return validate_state(payload.get("story", {}), safe_screens)


static func validate_state(value, safe_screens: Array = []) -> String:
	if not value is Dictionary:
		return "스토리 진행 정보 형식이 올바르지 않습니다."
	var state: Dictionary = value
	for forbidden_key in FORBIDDEN_CONTENT_KEYS:
		if state.has(forbidden_key):
			return "스토리 저장에는 대사 본문이나 대사 큐를 포함할 수 없습니다: %s" % forbidden_key
	if not _is_integer_number(state.get("schema_version")) or int(state.get("schema_version")) != SCHEMA_VERSION:
		return "스토리 저장 schema가 올바르지 않습니다."
	for string_key in ["current_scene_id", "current_cue_id", "pending_return_screen"]:
		if not state.get(string_key) is String:
			return "스토리 저장 문자열 형식이 올바르지 않습니다: %s" % string_key
	if state.has("pending_action") and not state.get("pending_action") is String:
		return "스토리 완료 후 동작 형식이 올바르지 않습니다."
	if not _is_integer_number(state.get("cursor")) or int(state.get("cursor")) < 0:
		return "스토리 cue 위치가 올바르지 않습니다."
	if state.has("current_facts") and (
		not state.get("current_facts") is Dictionary
		or not _valid_fact_value(state.get("current_facts"))
	):
		return "스토리 분기 사실 정보 형식이 올바르지 않습니다."
	for array_key in ["seen_scene_ids", "seen_cue_ids"]:
		if not _valid_id_array(state.get(array_key)):
			return "스토리 읽음 기록 형식이 올바르지 않습니다: %s" % array_key
	if state.has("seen_scene_scope_ids") and not _valid_id_array(state.get("seen_scene_scope_ids")):
		return "스토리 범위별 읽음 기록 형식이 올바르지 않습니다."
	if not state.get("auto_enabled") is bool:
		return "스토리 Auto 설정 형식이 올바르지 않습니다."
	if (
		not _is_integer_number(state.get("legacy_cutover_day"))
		or int(state.get("legacy_cutover_day")) < MIN_CAMPAIGN_DAY
		or int(state.get("legacy_cutover_day")) > MAX_CAMPAIGN_DAY
	):
		return "스토리 구 세이브 전환 DAY가 올바르지 않습니다."

	var scene_id := str(state.get("current_scene_id", ""))
	var cue_id := str(state.get("current_cue_id", ""))
	var cursor := int(state.get("cursor", 0))
	var return_screen := str(state.get("pending_return_screen", ""))
	var current_facts: Dictionary = state.get("current_facts", {})
	var pending_action := str(state.get("pending_action", ""))
	if scene_id == "":
		if cue_id != "" or cursor != 0 or return_screen != "" or not current_facts.is_empty() or pending_action != "":
			return "비활성 스토리 저장에 진행 중인 cue 정보가 남아 있습니다."
		return ""
	if cue_id == "":
		return "진행 중인 스토리에 현재 cue ID가 없습니다."
	if return_screen == "":
		return "진행 중인 스토리에 복귀 화면이 없습니다."
	if not safe_screens.is_empty() and (return_screen not in safe_screens or return_screen == "dialogue"):
		return "스토리 복귀 화면이 안전하지 않습니다."
	return ""


static func is_active(value) -> bool:
	if not value is Dictionary:
		return false
	var state: Dictionary = value
	return (
		str(state.get("current_scene_id", "")) != ""
		and str(state.get("current_cue_id", "")) != ""
		and _is_integer_number(state.get("cursor", -1))
		and int(state.get("cursor", -1)) >= 0
	)


static func _normalized_ids(value: Array) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	for entry in value:
		if not entry is String:
			continue
		var entry_id := str(entry)
		if entry_id == "" or seen.has(entry_id):
			continue
		seen[entry_id] = true
		result.append(entry_id)
	return result


static func _valid_id_array(value) -> bool:
	if not value is Array:
		return false
	var seen: Dictionary = {}
	for entry in value:
		if not entry is String:
			return false
		var entry_id := str(entry)
		if entry_id == "" or seen.has(entry_id):
			return false
		seen[entry_id] = true
	return true


static func _valid_fact_value(value) -> bool:
	if value == null or value is bool or value is String or value is int:
		return true
	if value is float:
		return is_finite(float(value))
	if value is Array:
		for entry in value:
			if not _valid_fact_value(entry):
				return false
		return true
	if value is Dictionary:
		for key in value.keys():
			if not key is String or not _valid_fact_value(value.get(key)):
				return false
		return true
	return false


static func _is_integer_number(value) -> bool:
	if value is int:
		return true
	if not value is float or not is_finite(float(value)):
		return false
	return float(value) == floor(float(value))
