class_name AudioVoiceAllocator
extends RefCounted

## 일회성 효과음만 대상으로 하는 공통 voice 예산 관리자.
## 실제 AudioStreamPlayer를 만들지 않고 승인/축출만 결정하므로, 호출자는
## accepted와 evicted_id를 보고 플레이어를 만들거나 정리한다.

const CATEGORY_GENERAL := "general"
const CATEGORY_UI := "ui"
const CATEGORY_FOOTSTEP := "footstep"
const VALID_CATEGORIES := [CATEGORY_GENERAL, CATEGORY_UI, CATEGORY_FOOTSTEP]

const MAX_GLOBAL_ONE_SHOTS := 24
const MAX_GENERAL_EVENT_VOICES := 4
const MAX_UI_VOICES := 2
const MAX_FOOTSTEP_VOICES := 3

const PRIORITY_CRITICAL := 400
const PRIORITY_UI := 300
const PRIORITY_UNIQUE := 200
const PRIORITY_GENERAL := 100
const PRIORITY_FOOTSTEP := 50

var _active: Dictionary = {}
var _sequence := 0


func admit_voice(
	voice_id: String,
	category: String,
	priority: int,
	event_group: String = "",
	started_at: float = 0.0
) -> Dictionary:
	var normalized_id := voice_id.strip_edges()
	var normalized_category := category.strip_edges().to_lower()
	if normalized_id == "":
		return _rejected(normalized_id, "empty_voice_id")
	if not VALID_CATEGORIES.has(normalized_category):
		return _rejected(normalized_id, "invalid_category")
	if _active.has(normalized_id):
		return _rejected(normalized_id, "duplicate_voice")

	var normalized_group := event_group.strip_edges()
	if normalized_category == CATEGORY_GENERAL and normalized_group == "":
		normalized_group = normalized_id

	var constraints: Array = []
	if _active.size() >= MAX_GLOBAL_ONE_SHOTS:
		constraints.append("global")
	if (
		normalized_category == CATEGORY_GENERAL
		and _count_general_group(normalized_group) >= MAX_GENERAL_EVENT_VOICES
	):
		constraints.append("general_group")
	if normalized_category == CATEGORY_UI and _count_category(CATEGORY_UI) >= MAX_UI_VOICES:
		constraints.append("ui")
	if normalized_category == CATEGORY_FOOTSTEP and _count_category(CATEGORY_FOOTSTEP) >= MAX_FOOTSTEP_VOICES:
		constraints.append("footstep")

	var evicted_id := ""
	if not constraints.is_empty():
		var candidate_id := _oldest_lower_priority_candidate(
			constraints,
			normalized_category,
			normalized_group,
			priority
		)
		if candidate_id == "":
			return _rejected(normalized_id, "cap_protected")
		evicted_id = candidate_id
		_active.erase(candidate_id)

	_sequence += 1
	_active[normalized_id] = {
		"voice_id": normalized_id,
		"category": normalized_category,
		"priority": priority,
		"event_group": normalized_group,
		"started_at": started_at,
		"sequence": _sequence
	}
	return {
		"accepted": true,
		"voice_id": normalized_id,
		"evicted_id": evicted_id,
		"reason": "evicted_low_priority" if evicted_id != "" else "admitted"
	}


func release_voice(voice_id: String) -> bool:
	var normalized_id := voice_id.strip_edges()
	if not _active.has(normalized_id):
		return false
	_active.erase(normalized_id)
	return true


func clear() -> void:
	_active.clear()
	_sequence = 0


func active_count() -> int:
	return _active.size()


func active_count_for_category(category: String) -> int:
	return _count_category(category.strip_edges().to_lower())


func active_count_for_event(event_group: String) -> int:
	return _count_general_group(event_group.strip_edges())


func active_voice_ids() -> Array:
	return _active.keys()


func snapshot() -> Dictionary:
	return _active.duplicate(true)


func _oldest_lower_priority_candidate(
	constraints: Array,
	category: String,
	event_group: String,
	request_priority: int
) -> String:
	var best_id := ""
	for voice_id_value in _active.keys():
		var voice_id := str(voice_id_value)
		var record: Dictionary = _active.get(voice_id, {})
		if int(record.get("priority", 0)) >= request_priority:
			continue
		if not _matches_constraints(record, constraints, category, event_group):
			continue
		if best_id == "":
			best_id = voice_id
			continue
		var current: Dictionary = _active.get(best_id, {})
		if _record_precedes(record, current):
			best_id = voice_id
	return best_id


func _matches_constraints(record: Dictionary, constraints: Array, category: String, event_group: String) -> bool:
	for constraint_value in constraints:
		var constraint := str(constraint_value)
		match constraint:
			"global":
				pass
			"general_group":
				if str(record.get("category", "")) != CATEGORY_GENERAL or str(record.get("event_group", "")) != event_group:
					return false
			"ui":
				if str(record.get("category", "")) != CATEGORY_UI:
					return false
			"footstep":
				if str(record.get("category", "")) != CATEGORY_FOOTSTEP:
					return false
			_:
				return false
	return true


func _record_precedes(candidate: Dictionary, current: Dictionary) -> bool:
	var candidate_priority := int(candidate.get("priority", 0))
	var current_priority := int(current.get("priority", 0))
	if candidate_priority != current_priority:
		return candidate_priority < current_priority
	var candidate_started := float(candidate.get("started_at", 0.0))
	var current_started := float(current.get("started_at", 0.0))
	if not is_equal_approx(candidate_started, current_started):
		return candidate_started < current_started
	return int(candidate.get("sequence", 0)) < int(current.get("sequence", 0))


func _count_category(category: String) -> int:
	var count := 0
	for record_value in _active.values():
		if str(record_value.get("category", "")) == category:
			count += 1
	return count


func _count_general_group(event_group: String) -> int:
	if event_group == "":
		return 0
	var count := 0
	for record_value in _active.values():
		if (
			str(record_value.get("category", "")) == CATEGORY_GENERAL
			and str(record_value.get("event_group", "")) == event_group
		):
			count += 1
	return count


func _rejected(voice_id: String, reason: String) -> Dictionary:
	return {
		"accepted": false,
		"voice_id": voice_id,
		"evicted_id": "",
		"reason": reason
	}
