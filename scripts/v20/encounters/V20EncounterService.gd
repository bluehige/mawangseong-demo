class_name V20EncounterService
extends RefCounted

const PathService = preload("res://scripts/v20/path/V20WeightedPathService.gd")
const FixedRouteService = preload("res://scripts/v20/path/V20FixedRouteService.gd")


static func encounter_for_day(day: int, catalog: Dictionary) -> Dictionary:
	for encounter_id_value in catalog.keys():
		var encounter: Dictionary = catalog.get(encounter_id_value, {})
		if int(encounter.get("day", 0)) == day:
			var result := encounter.duplicate(true)
			result["id"] = str(encounter_id_value)
			return result
	return {}


static func build_schedule(encounter: Dictionary, board: Dictionary, context: Dictionary = {}) -> Array[Dictionary]:
	var schedule: Array[Dictionary] = []
	for phase_value in encounter.get("phases", []):
		var phase: Dictionary = phase_value
		var start_seconds := float(phase.get("start_seconds", 0.0))
		var telegraph_seconds := float(phase.get("telegraph_seconds", 0.0))
		var spawn_offset := 0.0
		for spawn_value in phase.get("spawns", []):
			var spawn: Dictionary = spawn_value
			var interval := maxf(0.1, float(spawn.get("spawn_interval", 1.0)))
			for index in range(int(spawn.get("count", 1))):
				var spawn_time := start_seconds + spawn_offset + interval * index
				var route := _route_for_spawn(spawn, board, context)
				schedule.append({
					"phase_id": str(phase.get("id", "")),
					"enemy_id": str(spawn.get("enemy_id", "")),
					"time": spawn_time,
					"telegraph_time": maxf(0.0, start_seconds - telegraph_seconds),
					"route_policy": str(spawn.get("route_policy", "")),
					"goal_key": str(spawn.get("goal_key", route.get("goal_key", "throne"))),
					"goal_node": str(route.get("goal_node", "")),
					"route_nodes": route.get("nodes", []).duplicate(),
					"route_signature": str(route.get("signature", "")),
					"hp_scale": float(spawn.get("hp_scale", 1.0)),
					"atk_scale": float(spawn.get("atk_scale", 1.0)),
					"response_tags": phase.get("response_tags", []).duplicate(),
					"special_action": phase.get("special_action", {}).duplicate(true)
				})
			spawn_offset += interval * maxi(1, int(spawn.get("count", 1)))
	schedule.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a.get("time", 0.0)), float(b.get("time", 0.0))):
			return float(a.get("time", 0.0)) < float(b.get("time", 0.0))
		return "%s|%s" % [str(a.get("phase_id", "")), str(a.get("enemy_id", ""))] < "%s|%s" % [str(b.get("phase_id", "")), str(b.get("enemy_id", ""))]
	)
	return schedule


static func new_state(encounter: Dictionary, board: Dictionary, context: Dictionary = {}) -> Dictionary:
	var phase_states: Dictionary = {}
	for phase_value in encounter.get("phases", []):
		var phase: Dictionary = phase_value
		var metrics: Dictionary = {str(phase.get("failure_metric", "failure")): 0.0}
		phase_states[str(phase.get("id", ""))] = {"telegraphed": false, "started": false, "resolved": false, "responses": [], "metrics": metrics}
	var result_metrics: Dictionary = {}
	for metric_id_value in encounter.get("result_metrics", []):
		result_metrics[str(metric_id_value)] = 0.0
	return {
		"encounter_id": str(encounter.get("id", "")),
		"day": int(encounter.get("day", 0)),
		"elapsed_seconds": 0.0,
		"schedule": build_schedule(encounter, board, context),
		"phases": phase_states,
		"events": [],
		"result_metrics": result_metrics,
		"last_telegraph": {}
	}


static func advance(state: Dictionary, delta: float, encounter: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var before := float(next.get("elapsed_seconds", 0.0))
	var now := before + maxf(0.0, delta)
	next["elapsed_seconds"] = now
	next["events"] = []
	for phase_value in encounter.get("phases", []):
		var phase: Dictionary = phase_value
		var phase_id := str(phase.get("id", ""))
		var phase_state: Dictionary = next.get("phases", {}).get(phase_id, {})
		var start := float(phase.get("start_seconds", 0.0))
		var telegraph_at := maxf(0.0, start - float(phase.get("telegraph_seconds", 0.0)))
		if not bool(phase_state.get("telegraphed", false)) and now >= telegraph_at:
			phase_state["telegraphed"] = true
			var event := {"type": "telegraph", "phase_id": phase_id, "at_seconds": telegraph_at, "seconds_until_start": maxf(0.0, start - now), "response_tags": phase.get("response_tags", []).duplicate(), "special_action": phase.get("special_action", {}).duplicate(true)}
			next["events"].append(event)
			next["last_telegraph"] = event.duplicate(true)
		if not bool(phase_state.get("started", false)) and now >= start:
			phase_state["started"] = true
			next["events"].append({"type": "phase_started", "phase_id": phase_id, "at_seconds": start})
		next["phases"][phase_id] = phase_state
	return next


static func apply_response(state: Dictionary, encounter: Dictionary, phase_id: String, response_tag: String) -> Dictionary:
	var phase := _phase(encounter, phase_id)
	if phase.is_empty() or not phase.get("response_tags", []).has(response_tag):
		return {"ok": false, "error": "undeclared_response", "state": state.duplicate(true)}
	var next := state.duplicate(true)
	var responses: Array = next.get("phases", {}).get(phase_id, {}).get("responses", [])
	if not responses.has(response_tag):
		responses.append(response_tag)
		responses.sort()
	next["phases"][phase_id]["responses"] = responses
	return {"ok": true, "state": next}


static func record_metric(state: Dictionary, encounter: Dictionary, phase_id: String, metric_id: String, amount: float) -> Dictionary:
	var phase := _phase(encounter, phase_id)
	if phase.is_empty() or str(phase.get("failure_metric", "")) != metric_id:
		return {"ok": false, "error": "undeclared_phase_metric", "state": state.duplicate(true)}
	var next := state.duplicate(true)
	next["phases"][phase_id]["metrics"][metric_id] = float(next["phases"][phase_id]["metrics"].get(metric_id, 0.0)) + amount
	if next.get("result_metrics", {}).has(metric_id):
		next["result_metrics"][metric_id] = float(next["result_metrics"].get(metric_id, 0.0)) + amount
	return {"ok": true, "state": next}


static func resolve_phase(state: Dictionary, encounter: Dictionary, phase_id: String) -> Dictionary:
	var phase := _phase(encounter, phase_id)
	if phase.is_empty():
		return {"ok": false, "error": "unknown_phase", "state": state.duplicate(true)}
	var next := state.duplicate(true)
	var phase_state: Dictionary = next.get("phases", {}).get(phase_id, {})
	var response_count: int = phase_state.get("responses", []).size()
	var minimum := int(phase.get("minimum_response_matches", 1))
	var failure_metric := str(phase.get("failure_metric", ""))
	var failure_value := float(phase_state.get("metrics", {}).get(failure_metric, 0.0))
	var success: bool = response_count >= minimum and failure_value <= 0.0
	phase_state["resolved"] = true
	phase_state["success"] = success
	phase_state["outcome_signature"] = "%s|%s|%.1f" % [phase_id, ">".join(phase_state.get("responses", [])), failure_value]
	next["phases"][phase_id] = phase_state
	return {"ok": true, "success": success, "state": next, "outcome_signature": phase_state["outcome_signature"]}


static func evaluate_strategy(encounter: Dictionary, strategy: Dictionary) -> Dictionary:
	var provided: Array = strategy.get("response_tags", [])
	var phase_results: Array[Dictionary] = []
	var all_success := true
	for phase_value in encounter.get("phases", []):
		var phase: Dictionary = phase_value
		var matched: Array[String] = []
		for tag_value in phase.get("response_tags", []):
			var tag := str(tag_value)
			if provided.has(tag):
				matched.append(tag)
		var success := matched.size() >= int(phase.get("minimum_response_matches", 1))
		all_success = all_success and success
		phase_results.append({"phase_id": str(phase.get("id", "")), "matched": matched, "success": success})
	return {"success": all_success, "phases": phase_results, "signature": "%02d|%s|%s" % [int(encounter.get("day", 0)), str(strategy.get("id", "strategy")), str(all_success)]}


static func wave_catalog_for_day(day: int, catalog: Dictionary, board: Dictionary, context: Dictionary = {}) -> Dictionary:
	var encounter := encounter_for_day(day, catalog)
	if encounter.is_empty():
		return {}
	return wave_catalog_for_encounter(encounter, board, context)


static func wave_catalog_for_encounter(encounter: Dictionary, board: Dictionary, context: Dictionary = {}) -> Dictionary:
	if encounter.is_empty():
		return {}
	var entries: Array[Dictionary] = []
	for scheduled_value in build_schedule(encounter, board, context):
		var scheduled: Dictionary = scheduled_value
		entries.append({
			"enemy_id": str(scheduled.get("enemy_id", "")),
			"count": 1,
			"spawn_delay": float(scheduled.get("time", 0.0)),
			"spawn_interval": 1.0,
			"hp_scale": float(scheduled.get("hp_scale", 1.0)),
			"atk_scale": float(scheduled.get("atk_scale", 1.0)),
			"goal_type_override": str(scheduled.get("goal_key", "throne")),
			"v20_phase_id": str(scheduled.get("phase_id", "")),
			"v20_route_policy": str(scheduled.get("route_policy", "")),
			"v20_route_nodes": scheduled.get("route_nodes", []).duplicate(),
			"v20_response_tags": scheduled.get("response_tags", []).duplicate(),
			"v20_special_action": scheduled.get("special_action", {}).duplicate(true)
		})
	return {"day_%d" % int(encounter.get("day", 0)): entries}


static func hud_status(state: Dictionary, encounter: Dictionary) -> Dictionary:
	var telegraph: Dictionary = state.get("last_telegraph", {})
	var phase := _phase(encounter, str(telegraph.get("phase_id", "")))
	if phase.is_empty():
		var phases: Array = encounter.get("phases", [])
		phase = phases[0] if not phases.is_empty() else {}
	var start := float(phase.get("start_seconds", 0.0))
	var eta := maxf(0.0, start - float(state.get("elapsed_seconds", 0.0)))
	var phase_index := maxi(0, encounter.get("phases", []).find(phase))
	var response_labels: Array[String] = []
	for tag_value in phase.get("response_tags", []).slice(0, 3):
		response_labels.append(_response_label(str(tag_value)))
	var pattern_id := str(phase.get("special_action", {}).get("id", encounter.get("preview", {}).get("special_pattern", "frontline_reading")))
	return {
		"phase_label": "%s · %d/%d단계" % [str(encounter.get("display_name", "침입")), phase_index + 1, maxi(1, encounter.get("phases", []).size())],
		"pattern_title": _pattern_label(pattern_id),
		"pattern_eta": "%.1f초" % eta,
		"pattern_response": "대응: %s" % " · ".join(response_labels)
	}


static func _route_for_spawn(spawn: Dictionary, board: Dictionary, context: Dictionary) -> Dictionary:
	var policy := str(spawn.get("route_policy", ""))
	var goal_key := str(spawn.get("goal_key", "throne"))
	if goal_key == "facility":
		var facility_node := _facility_goal_node(context.get("facilities", []))
		if facility_node != "":
			var fixed_facility_route := FixedRouteService.route_to_goal(board, "entrance", facility_node, "facility")
			if bool(fixed_facility_route.get("ok", false)):
				return fixed_facility_route
			var facility_route := PathService.find_path(board, "entrance", facility_node, _path_context(context, policy))
			facility_route["goal_key"] = "facility"
			facility_route["signature"] = "facility::%s" % ">".join(facility_route.get("nodes", []))
			return facility_route
	var fixed_goal_node := str(board.get("goal_nodes", {}).get(goal_key, ""))
	if fixed_goal_node != "":
		var fixed_route := FixedRouteService.route_to_goal(board, "entrance", fixed_goal_node, goal_key)
		if bool(fixed_route.get("ok", false)):
			fixed_route["enemy_role"] = str(spawn.get("enemy_id", "enemy"))
			return fixed_route
	var enemy_contract := {"role": str(spawn.get("enemy_id", "enemy")), "candidate_goals": [goal_key], "goal_preferences": {goal_key: 0.0}, "route_tag_costs": _route_policy_costs(policy)}
	return PathService.choose_goal_and_path(board, "entrance", enemy_contract, _path_context(context, policy))


static func _path_context(context: Dictionary, policy: String) -> Dictionary:
	var result := {
		"seed": int(context.get("seed", 0)),
		"door_state_costs": context.get("door_state_costs", {}).duplicate(true),
		"facility_route_costs": context.get("facility_route_costs", {}).duplicate(true),
		"temporary_hazard_costs": context.get("temporary_hazard_costs", {}).duplicate(true)
	}
	if policy == "opposite_first_engagement":
		result["temporary_hazard_costs"] = context.get("opposite_route_costs", {"north": 8.0}).duplicate(true)
	return result


static func _route_policy_costs(policy: String) -> Dictionary:
	match policy:
		"north_throne":
			return {"south": 20.0}
		"south_treasure":
			return {"north": 20.0}
		"frontline_cover":
			return {"treasure_route": 6.0}
		"protected_rear":
			return {"frontline": 3.0, "south": -1.0}
		"dash_past_first_line":
			return {"frontline": -2.0, "fallback_route": -1.0}
		_:
			return {}


static func _facility_goal_node(facilities: Array) -> String:
	var candidates: Array[String] = []
	for facility_value in facilities:
		if facility_value is Dictionary and bool(facility_value.get("active", true)):
			candidates.append(str(facility_value.get("section_id", facility_value.get("node_id", facility_value.get("room_id", "")))))
	candidates = candidates.filter(func(value): return value != "")
	candidates.sort()
	return candidates[0] if not candidates.is_empty() else "fallback"


static func _phase(encounter: Dictionary, phase_id: String) -> Dictionary:
	for phase_value in encounter.get("phases", []):
		if phase_value is Dictionary and str(phase_value.get("id", "")) == phase_id:
			return phase_value
	return {}


static func _pattern_label(pattern_id: String) -> String:
	return str({
		"frontline_reading": "정면 진입",
		"split_objectives": "왕좌·보물 분리 침투",
		"disable_first_activated_facility": "공병 시설 무력화",
		"rear_silence_pressure": "보호받는 후열 사격",
		"hero_dash_breach": "전열 돌파 대시",
		"reinforcement_section_pressure": "후속 구간 증원"
	}.get(pattern_id, pattern_id))


static func _response_label(tag: String) -> String:
	return str({
		"entry_anchor": "길목 고정",
		"rear_fire": "후방 화력",
		"read_combat": "전투 관찰",
		"split_defense": "병력 분리",
		"thief_hunter": "도둑 추격",
		"goal_lure": "미끼 유인",
		"rally_response": "집결",
		"focus_target": "집중",
		"backup_line": "예비 방어선",
		"facility_spread": "시설 분산",
		"interrupt_cast": "시전 차단",
		"watch_reveal": "감시 노출",
		"artillery": "임프 포병",
		"flank_route": "측면 집중",
		"recovery_window": "회복 창구",
		"emergency_retreat": "비상 후퇴"
	}.get(tag, tag))
