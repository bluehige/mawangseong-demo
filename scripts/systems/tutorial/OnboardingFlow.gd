extends RefCounted
class_name OnboardingFlow

const DEFAULT_PATH := "res://참고자료/onboarding_flow_dialogue_v0.4.json"

var data: Dictionary = {}
var loaded := false

func load(path: String = DEFAULT_PATH) -> bool:
	loaded = false
	data.clear()
	if not FileAccess.file_exists(path):
		push_warning("Onboarding flow JSON not found: %s" % path)
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_error("Invalid onboarding flow JSON: %s" % path)
		return false
	data = parsed
	loaded = true
	return true

func flow_entry(stage_id: String) -> Dictionary:
	for entry in data.get("flow", []):
		if entry is Dictionary and str(entry.get("id", "")) == stage_id:
			return entry
	return {}

func next_stage(stage_id: String) -> String:
	return str(flow_entry(stage_id).get("next", ""))

func screen_rect(screen_id: String, node_name: String, fallback: Rect2 = Rect2()) -> Rect2:
	var screens: Dictionary = data.get("screens", {})
	var screen: Dictionary = screens.get(screen_id, {})
	for node in screen.get("nodes", []):
		if node is Dictionary and str(node.get("name", "")) == node_name:
			return _rect_from_array(node.get("rect", []), fallback)
	return fallback

func dialogue_for_trigger(trigger_id: String, stage_id: String = "") -> Array:
	var result: Array = []
	for line in data.get("dialogue", []):
		if not (line is Dictionary):
			continue
		if str(line.get("trigger", "")) != trigger_id:
			continue
		if stage_id != "" and str(line.get("stage", "")) != stage_id:
			continue
		result.append(line.duplicate(true))
	return result

func dialogue_for_stage_triggers(stage_id: String, triggers: Array) -> Array:
	var result: Array = []
	for trigger in triggers:
		result.append_array(dialogue_for_trigger(str(trigger), stage_id))
	return result

func tutorial_steps_for_stage(stage_id: String) -> Array:
	var result: Array = []
	for step in data.get("tutorial_steps", []):
		if step is Dictionary and str(step.get("stage", "")) == stage_id:
			result.append(step.duplicate(true))
	return result

func _rect_from_array(values: Variant, fallback: Rect2) -> Rect2:
	if not (values is Array) or values.size() < 4:
		return fallback
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))
