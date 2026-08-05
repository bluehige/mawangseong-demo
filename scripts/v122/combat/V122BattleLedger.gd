class_name V122BattleLedger
extends RefCounted


static func new_state(day: int, seed: int, layout_fingerprint: String) -> Dictionary:
	return {
		"day": day,
		"seed": seed,
		"layout_fingerprint": layout_fingerprint,
		"elapsed_seconds": 0.0,
		"events": []
	}


static func advance(state: Dictionary, delta: float) -> Dictionary:
	var next := state.duplicate(true)
	next["elapsed_seconds"] = float(next.get("elapsed_seconds", 0.0)) + maxf(0.0, delta)
	return next


static func record(state: Dictionary, event_type: String, payload: Dictionary = {}) -> Dictionary:
	var next := state.duplicate(true)
	var event := payload.duplicate(true)
	event["type"] = event_type
	event["at_seconds"] = snappedf(float(next.get("elapsed_seconds", 0.0)), 0.001)
	next["events"].append(event)
	return next


static func summarize(state: Dictionary) -> Dictionary:
	var counts := {}
	var facility_contribution := {}
	var command_contribution := {}
	var gold_stolen := 0
	var throne_damage := 0
	var breach_progress := 0.0
	var final_breach_segment := ""
	var deepest_breach_depth := -1
	var legacy_breach_progress := -1.0
	for value in state.get("events", []):
		if not value is Dictionary:
			continue
		var event: Dictionary = value
		var event_type := str(event.get("type", ""))
		counts[event_type] = int(counts.get(event_type, 0)) + 1
		if event_type == "facility_effect":
			var room_id := str(event.get("room_id", ""))
			facility_contribution[room_id] = float(facility_contribution.get(room_id, 0.0)) + float(event.get("amount", 1.0))
		elif event_type == "command_contribution":
			var command_id := str(event.get("command_id", ""))
			command_contribution[command_id] = float(command_contribution.get(command_id, 0.0)) + float(event.get("amount", 0.0))
		elif event_type == "treasure_stolen":
			gold_stolen += int(event.get("amount", 0))
		elif event_type == "throne_damage":
			throne_damage += int(event.get("amount", 0))
		elif event_type == "breach_progress":
			var event_progress := float(event.get("progress", 0.0))
			breach_progress = maxf(breach_progress, event_progress)
			var event_segment := str(event.get("final_breach_segment", "")).strip_edges()
			if event.has("depth") and int(event.get("depth", -1)) >= deepest_breach_depth:
				deepest_breach_depth = int(event.get("depth", -1))
				if event_segment != "":
					final_breach_segment = event_segment
			elif deepest_breach_depth < 0 and event_progress >= legacy_breach_progress:
				legacy_breach_progress = event_progress
				if event_segment != "":
					final_breach_segment = event_segment
	return {
		"event_counts": counts,
		"facility_contribution": facility_contribution,
		"command_contribution": command_contribution,
		"gold_stolen": gold_stolen,
		"throne_damage": throne_damage,
		"breach_progress": breach_progress,
		"breach_depth": deepest_breach_depth,
		"final_breach_segment": final_breach_segment,
		"events": state.get("events", []).duplicate(true)
	}
