extends RefCounted
class_name StoryDirector

const StorySaveStateScript = preload("res://scripts/story/StorySaveState.gd")

var catalog: StoryCatalog = null
var enabled := false

var current_scene_id: String = ""
var current_cue_id: String = ""
var cursor := 0
var seen_scene_ids: Array[String] = []
var seen_scene_scope_ids: Array[String] = []
var seen_cue_ids: Array[String] = []
var pending_return_screen: String = ""
var pending_action: String = ""
var auto_enabled := false
var legacy_cutover_day := 1
var current_facts: Dictionary = {}

var _active_cues: Array[Dictionary] = []


func setup(story_catalog: StoryCatalog, current_day: int = 1) -> void:
	catalog = story_catalog
	enabled = catalog != null and catalog.loaded
	legacy_cutover_day = maxi(1, current_day)


func reset_for_new_game() -> void:
	current_scene_id = ""
	current_cue_id = ""
	cursor = 0
	seen_scene_ids.clear()
	seen_scene_scope_ids.clear()
	seen_cue_ids.clear()
	pending_return_screen = ""
	pending_action = ""
	auto_enabled = false
	legacy_cutover_day = 1
	current_facts.clear()
	_active_cues.clear()


func reset_for_new_cycle() -> void:
	var persistent_seen_cues := seen_cue_ids.duplicate()
	var persistent_auto := auto_enabled
	reset_for_new_game()
	seen_cue_ids = persistent_seen_cues
	auto_enabled = persistent_auto


func is_active() -> bool:
	return current_scene_id != "" and not _active_cues.is_empty() and cursor >= 0 and cursor < _active_cues.size()


func current_scene() -> Dictionary:
	if catalog == null or current_scene_id == "":
		return {}
	return catalog.scene(current_scene_id)


func current_cue() -> Dictionary:
	if not is_active():
		return {}
	return _active_cues[cursor].duplicate(true)


func cue_count() -> int:
	return _active_cues.size()


func try_start(day: int, trigger: String, facts: Dictionary = {}, return_screen: String = "", action: String = "", force_replay: bool = false) -> bool:
	if not enabled or catalog == null or is_active() or day < legacy_cutover_day:
		return false
	for candidate in catalog.scenes_for(day, trigger, facts):
		var scene_id := str(candidate.get("id", ""))
		var repeat_policy := str(candidate.get("repeat_policy", "once"))
		if repeat_policy == "once_first_cycle_day" and int(facts.get("cycle_index", 1)) > 1:
			continue
		if not force_replay and scene_consumed(candidate, facts):
			continue
		if start_scene(scene_id, facts, return_screen, action, force_replay):
			return true
	return false


func start_scene(scene_id: String, facts: Dictionary = {}, return_screen: String = "", action: String = "", force_replay: bool = false) -> bool:
	if not enabled or catalog == null or is_active():
		return false
	var scene := catalog.scene(scene_id)
	if scene.is_empty() or (not force_replay and scene_consumed(scene, facts)):
		return false
	var filtered := _filtered_cues(scene, facts)
	if filtered.is_empty():
		return false
	current_scene_id = scene_id
	cursor = 0
	_active_cues = filtered
	current_cue_id = str(_active_cues[0].get("id", ""))
	pending_return_screen = return_screen
	pending_action = action
	current_facts = facts.duplicate(true)
	return true


func advance(stop_auto: bool = true) -> Dictionary:
	if not is_active():
		return {"advanced": false, "completed": false}
	var consumed_cue_id := current_cue_id
	_add_unique(seen_cue_ids, consumed_cue_id)
	if stop_auto:
		auto_enabled = false
	if cursor + 1 < _active_cues.size():
		cursor += 1
		current_cue_id = str(_active_cues[cursor].get("id", ""))
		return {
			"advanced": true,
			"completed": false,
			"consumed_cue_id": consumed_cue_id,
			"cue": current_cue()
		}
	return _complete_active_scene(false, consumed_cue_id)


func skip_allowed() -> bool:
	if not is_active():
		return false
	for cue in _active_cues:
		if not seen_cue_ids.has(str(cue.get("id", ""))):
			return false
	return true


func skip() -> Dictionary:
	if not skip_allowed():
		return {"advanced": false, "completed": false, "skipped": false}
	for cue in _active_cues:
		_add_unique(seen_cue_ids, str(cue.get("id", "")))
	return _complete_active_scene(true, current_cue_id)


func cancel_active_scene() -> String:
	var canceled_scene_id := current_scene_id
	_clear_current()
	return canceled_scene_id


func unread_optional(day: int, facts: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not enabled or catalog == null or day < legacy_cutover_day:
		return result
	for candidate in catalog.optional_scenes(day, facts):
		if not seen_scene_ids.has(str(candidate.get("id", ""))):
			result.append(candidate)
	return result


func archive_scenes(max_day: int = 999) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if catalog == null:
		return result
	for scene_id in catalog.all_scene_ids():
		var candidate := catalog.scene(scene_id)
		if int(candidate.get("day", 0)) <= max_day and seen_scene_ids.has(scene_id):
			result.append(candidate)
	result.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_day := int(left.get("day", 0))
		var right_day := int(right.get("day", 0))
		if left_day != right_day:
			return left_day < right_day
		return int(left.get("priority", 0)) < int(right.get("priority", 0))
	)
	return result


func set_auto(value: bool) -> void:
	auto_enabled = value


func export_state() -> Dictionary:
	return StorySaveStateScript.build({
		"current_scene_id": current_scene_id,
		"current_cue_id": current_cue_id,
		"cursor": cursor,
		"seen_scene_ids": seen_scene_ids,
		"seen_scene_scope_ids": seen_scene_scope_ids,
		"seen_cue_ids": seen_cue_ids,
		"pending_return_screen": pending_return_screen,
		"pending_action": pending_action,
		"auto_enabled": auto_enabled,
		"legacy_cutover_day": legacy_cutover_day,
		"current_facts": current_facts
	})


func import_state(raw_state, current_day: int, had_story_payload: bool = true) -> bool:
	var normalized: Dictionary = StorySaveStateScript.normalize(raw_state)
	current_scene_id = str(normalized.get("current_scene_id", ""))
	current_cue_id = str(normalized.get("current_cue_id", ""))
	cursor = int(normalized.get("cursor", 0))
	seen_scene_ids = _string_array(normalized.get("seen_scene_ids", []))
	seen_scene_scope_ids = _string_array(normalized.get("seen_scene_scope_ids", []))
	seen_cue_ids = _string_array(normalized.get("seen_cue_ids", []))
	pending_return_screen = str(normalized.get("pending_return_screen", ""))
	pending_action = str(normalized.get("pending_action", ""))
	auto_enabled = bool(normalized.get("auto_enabled", false))
	legacy_cutover_day = maxi(1, int(normalized.get("legacy_cutover_day", current_day if not had_story_payload else 1)))
	current_facts = normalized.get("current_facts", {}).duplicate(true) if normalized.get("current_facts") is Dictionary else {}
	_active_cues.clear()
	if not had_story_payload:
		legacy_cutover_day = maxi(1, current_day)
		_clear_current()
		return true
	if current_scene_id == "":
		return true
	if not enabled or catalog == null:
		_clear_current()
		return false
	var scene := catalog.scene(current_scene_id)
	if scene.is_empty():
		_clear_current()
		return false
	_active_cues = _filtered_cues(scene, current_facts)
	if _active_cues.is_empty():
		_clear_current()
		return false
	var cue_index := -1
	for index in range(_active_cues.size()):
		if str(_active_cues[index].get("id", "")) == current_cue_id:
			cue_index = index
			break
	if cue_index < 0:
		_clear_current()
		return false
	cursor = cue_index
	return true


func _complete_active_scene(skipped: bool, consumed_cue_id: String) -> Dictionary:
	var completed_scene_id := current_scene_id
	var completed_scene := current_scene()
	var completed_scope_key := _scene_scope_key(completed_scene, current_facts)
	var return_screen := pending_return_screen
	var action := pending_action
	_add_unique(seen_scene_ids, completed_scene_id)
	_add_unique(seen_scene_scope_ids, completed_scope_key)
	_clear_current()
	return {
		"advanced": true,
		"completed": true,
		"skipped": skipped,
		"consumed_cue_id": consumed_cue_id,
		"scene_id": completed_scene_id,
		"return_screen": return_screen,
		"action": action
	}


func scene_consumed(scene: Dictionary, facts: Dictionary = {}) -> bool:
	var repeat_policy := str(scene.get("repeat_policy", "once"))
	if repeat_policy == "always":
		return false
	var scope_key := _scene_scope_key(scene, facts)
	if scope_key != "":
		return seen_scene_scope_ids.has(scope_key)
	return seen_scene_ids.has(str(scene.get("id", "")))


func _scene_scope_key(scene: Dictionary, facts: Dictionary) -> String:
	var repeat_policy := str(scene.get("repeat_policy", "once"))
	var fact_key := ""
	if repeat_policy == "once_battle":
		fact_key = "battle_scope_id"
	elif repeat_policy == "once_raid":
		fact_key = "raid_scope_id"
	if fact_key == "":
		return ""
	var scope_id := str(facts.get(fact_key, ""))
	var scene_id := str(scene.get("id", ""))
	if scope_id == "" or scene_id == "":
		return ""
	return "%s::%s::%s" % [repeat_policy, scope_id, scene_id]


func _filtered_cues(scene: Dictionary, facts: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var replacement_ids: Dictionary = {}
	for cue_value in scene.get("cues", []):
		if not (cue_value is Dictionary):
			continue
		var cue: Dictionary = cue_value
		if not StoryCatalog.conditions_match(cue.get("conditions", {}), facts):
			continue
		candidates.append(cue.duplicate(true))
		for replaced_id_value in cue.get("replaces_cue_ids", []):
			replacement_ids[str(replaced_id_value)] = true
	var result: Array[Dictionary] = []
	for cue in candidates:
		if not replacement_ids.has(str(cue.get("id", ""))):
			result.append(cue)
	return result


func _clear_current() -> void:
	current_scene_id = ""
	current_cue_id = ""
	cursor = 0
	pending_return_screen = ""
	pending_action = ""
	current_facts.clear()
	_active_cues.clear()


func _add_unique(target: Array[String], value: String) -> void:
	if value != "" and not target.has(value):
		target.append(value)


func _string_array(value) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			var text := str(item)
			if text != "" and not result.has(text):
				result.append(text)
	return result
