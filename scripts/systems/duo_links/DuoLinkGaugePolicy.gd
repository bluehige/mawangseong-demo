extends RefCounted
class_name DuoLinkGaugePolicy

const MAX_GAUGE := 100
const MAX_GAIN_PER_ACTION := 10


static func empty_state(active: bool = false, inactive_reason: String = "") -> Dictionary:
	return {
		"charge": 0,
		"ready": false,
		"used_this_battle": false,
		"active": active,
		"inactive_reason": inactive_reason,
		"downed_members": [],
		"source_progress": {},
		"event_dedupe": {}
	}


static func record_action(state_value, definition: Dictionary, member_instance_id: String, source_id: String, amount: int, event_token: String) -> Dictionary:
	var state := _normalize_state(state_value)
	if amount <= 0 or bool(state.get("used_this_battle", false)) or not bool(state.get("active", false)):
		return {"state": state, "gain": 0, "counted": false}
	if int(state.get("charge", 0)) >= MAX_GAUGE:
		return {"state": state, "gain": 0, "counted": false}
	var dedupe: Dictionary = state.get("event_dedupe", {})
	var token := event_token.strip_edges()
	if token != "" and dedupe.has(token):
		return {"state": state, "gain": 0, "counted": false}
	var source_rule := _source_rule(definition, member_instance_id, source_id)
	if source_rule.is_empty():
		return {"state": state, "gain": 0, "counted": false}
	if token != "":
		dedupe[token] = true
	state["event_dedupe"] = dedupe
	var threshold := maxi(1, int(source_rule.get("threshold", 1)))
	var source_key := "%s:%s" % [member_instance_id, source_id]
	var progress: Dictionary = state.get("source_progress", {})
	var total := maxi(0, int(progress.get(source_key, 0))) + amount
	var completed := total / threshold
	progress[source_key] = total % threshold
	state["source_progress"] = progress
	var gain := mini(MAX_GAIN_PER_ACTION, completed * maxi(0, int(source_rule.get("gain", 0))))
	gain = mini(gain, MAX_GAUGE - int(state.get("charge", 0)))
	state["charge"] = int(state.get("charge", 0)) + gain
	state["ready"] = int(state.get("charge", 0)) >= MAX_GAUGE
	return {"state": state, "gain": gain, "counted": true}


static func _source_rule(definition: Dictionary, member_instance_id: String, source_id: String) -> Dictionary:
	for value in definition.get("gauge_sources", []):
		if value is Dictionary and str(value.get("member_instance_id", "")) == member_instance_id and str(value.get("source_id", "")) == source_id:
			return value
	return {}


static func _normalize_state(value) -> Dictionary:
	var result := empty_state()
	if value is Dictionary:
		for key in result.keys():
			if value.has(key) and typeof(value.get(key)) == typeof(result.get(key)):
				result[key] = value.get(key).duplicate(true) if value.get(key) is Dictionary or value.get(key) is Array else value.get(key)
	result["charge"] = clampi(int(result.get("charge", 0)), 0, MAX_GAUGE)
	result["ready"] = int(result.get("charge", 0)) >= MAX_GAUGE and not bool(result.get("used_this_battle", false))
	return result
