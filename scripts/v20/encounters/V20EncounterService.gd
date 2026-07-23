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
	var failure_metric := str(phase.get("failure_metric", ""))
	var failure_value := float(phase_state.get("metrics", {}).get(failure_metric, 0.0))
	var success: bool = failure_value <= 0.0
	phase_state["resolved"] = true
	phase_state["success"] = success
	phase_state["outcome_signature"] = "%s|%s|%.1f" % [phase_id, failure_metric, failure_value]
	next["phases"][phase_id] = phase_state
	return {"ok": true, "success": success, "state": next, "outcome_signature": phase_state["outcome_signature"]}


static func evaluate_strategy(encounter: Dictionary, strategy: Dictionary) -> Dictionary:
	var provided: Array = strategy.get("response_tags", [])
	var phase_results: Array[Dictionary] = []
	var metadata_complete := true
	for phase_value in encounter.get("phases", []):
		var phase: Dictionary = phase_value
		var matched: Array[String] = []
		for tag_value in phase.get("response_tags", []):
			var tag := str(tag_value)
			if provided.has(tag):
				matched.append(tag)
		var success := matched.size() >= int(phase.get("minimum_response_matches", 1))
		metadata_complete = metadata_complete and success
		phase_results.append({"phase_id": str(phase.get("id", "")), "matched": matched, "success": success})
	return {"success": false, "metadata_complete": metadata_complete, "phases": phase_results, "signature": "%02d|%s|metadata:%s" % [int(encounter.get("day", 0)), str(strategy.get("id", "strategy")), str(metadata_complete)]}


static func apply_evidence_metrics(state: Dictionary, encounter: Dictionary, evidence_metrics: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	for metric_id_value in next.get("result_metrics", {}).keys():
		var metric_id := str(metric_id_value)
		next["result_metrics"][metric_id] = _evidence_metric_value(evidence_metrics, metric_id)
	for phase_value in encounter.get("phases", []):
		var phase: Dictionary = phase_value
		var phase_id := str(phase.get("id", ""))
		var failure_metric := str(phase.get("failure_metric", ""))
		if next.get("phases", {}).has(phase_id):
			next["phases"][phase_id]["metrics"][failure_metric] = _evidence_metric_value(evidence_metrics, failure_metric)
	return next


static func resolve_all_phases(state: Dictionary, encounter: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var results: Array[Dictionary] = []
	for phase_value in encounter.get("phases", []):
		var phase_id := str(phase_value.get("id", ""))
		var resolved := resolve_phase(next, encounter, phase_id)
		next = resolved.get("state", next)
		results.append({"phase_id": phase_id, "success": bool(resolved.get("success", false)), "outcome_signature": str(resolved.get("outcome_signature", ""))})
	return {"state": next, "phases": results}


static func _evidence_metric_value(evidence_metrics: Dictionary, metric_id: String) -> float:
	if metric_id == "facility_disabled_seconds":
		return float(evidence_metrics.get("max_contiguous_facility_disabled_seconds", 0.0))
	var value = evidence_metrics.get(metric_id, 0.0)
	return float(value) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else 0.0


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
		var goal_key := str(scheduled.get("goal_key", "throne"))
		var entry := {
			"enemy_id": str(scheduled.get("enemy_id", "")),
			"count": 1,
			"spawn_delay": float(scheduled.get("time", 0.0)),
			"spawn_interval": 1.0,
			"hp_scale": float(scheduled.get("hp_scale", 1.0)),
			"atk_scale": float(scheduled.get("atk_scale", 1.0)),
			"v20_goal_key": goal_key,
			"v20_phase_id": str(scheduled.get("phase_id", "")),
			"v20_route_policy": str(scheduled.get("route_policy", "")),
			"v20_route_nodes": scheduled.get("route_nodes", []).duplicate(),
			"v20_response_tags": scheduled.get("response_tags", []).duplicate(),
			"v20_special_action": scheduled.get("special_action", {}).duplicate(true)
		}
		if goal_key in ["throne", "treasure", "facility", "heart"]:
			entry["goal_type_override"] = goal_key
		entries.append(entry)
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
	var pattern_id := str(phase.get("special_action", {}).get("id", encounter.get("preview", {}).get("special_pattern", "frontline_reading")))
	var player_prompt := _player_action_prompt(pattern_id, phase)
	return {
		"phase_label": "%s · %d/%d단계" % [str(encounter.get("display_name", "침입")), phase_index + 1, maxi(1, encounter.get("phases", []).size())],
		"pattern_title": _pattern_label(pattern_id),
		"pattern_eta": "%.1f초" % eta,
		"pattern_response": str(player_prompt.get("text", "지금 할 일: 집결 → 현재 교전 방 클릭")),
		"recommended_command_id": str(player_prompt.get("command_id", "v20_rally")),
		"recommended_target_label": str(player_prompt.get("target_label", "현재 교전 방"))
	}


static func _player_action_prompt(pattern_id: String, phase: Dictionary) -> Dictionary:
	var command_id := "v20_rally"
	var command_label := "집결"
	var target_label := "현재 교전 방"
	match pattern_id:
		"frontline_reading":
			target_label = "성문 전초"
		"split_objectives":
			target_label = "뚫리는 방"
		"disable_first_activated_facility":
			command_id = "v20_focus"
			command_label = "집중"
			target_label = "공병"
		"rear_silence_pressure":
			command_id = "v20_focus"
			command_label = "집중"
			target_label = "후열 사수"
		"hero_dash_breach":
			command_id = "v20_emergency_fallback"
			command_label = "비상 후퇴"
			target_label = "왕좌 전실"
		"reinforcement_section_pressure":
			target_label = "밀리는 방"
		_:
			var response_tags: Array = phase.get("response_tags", [])
			if response_tags.has("focus_target") or response_tags.has("interrupt_cast"):
				command_id = "v20_focus"
				command_label = "집중"
				target_label = "위험한 적"
			elif response_tags.has("emergency_retreat"):
				command_id = "v20_emergency_fallback"
				command_label = "비상 후퇴"
				target_label = "후퇴할 방"
			elif response_tags.has("recovery_window"):
				command_id = "v20_activate_facility"
				command_label = "시설 발동"
				target_label = "회복 시설"
	return {
		"command_id": command_id,
		"command_label": command_label,
		"target_label": target_label,
		"text": "지금 할 일: %s → %s 클릭" % [command_label, target_label]
	}


static func _route_for_spawn(spawn: Dictionary, board: Dictionary, context: Dictionary) -> Dictionary:
	var policy := str(spawn.get("route_policy", ""))
	var goal_key := str(spawn.get("goal_key", "throne"))
	var start_node := str(board.get("fixed_route", {}).get("start_node", "gate_outpost"))
	if goal_key == "facility":
		var facility_node := _facility_goal_node(context.get("facilities", []))
		if facility_node != "":
			var fixed_facility_route := FixedRouteService.route_to_goal(board, start_node, facility_node, "facility")
			if bool(fixed_facility_route.get("ok", false)):
				return fixed_facility_route
			var facility_route := PathService.find_path(board, start_node, facility_node, _path_context(context, policy))
			facility_route["goal_key"] = "facility"
			facility_route["signature"] = "facility::%s" % ">".join(facility_route.get("nodes", []))
			return facility_route
	var fixed_goal_node := str(board.get("goal_nodes", {}).get(goal_key, ""))
	if fixed_goal_node != "":
		var fixed_route := FixedRouteService.route_to_goal(board, start_node, fixed_goal_node, goal_key)
		if bool(fixed_route.get("ok", false)):
			fixed_route["enemy_role"] = str(spawn.get("enemy_id", "enemy"))
			return fixed_route
	var enemy_contract := {"role": str(spawn.get("enemy_id", "enemy")), "candidate_goals": [goal_key], "goal_preferences": {goal_key: 0.0}, "route_tag_costs": _route_policy_costs(policy)}
	return PathService.choose_goal_and_path(board, start_node, enemy_contract, _path_context(context, policy))


static func _path_context(context: Dictionary, _policy: String) -> Dictionary:
	return {
		"seed": int(context.get("seed", 0)),
		"door_state_costs": context.get("door_state_costs", {}).duplicate(true),
		"facility_route_costs": context.get("facility_route_costs", {}).duplicate(true),
		"temporary_hazard_costs": context.get("temporary_hazard_costs", {}).duplicate(true)
	}


static func _route_policy_costs(_policy: String) -> Dictionary:
	return {}


static func _facility_goal_node(facilities: Array) -> String:
	var candidates: Array[String] = []
	for facility_value in facilities:
		if facility_value is Dictionary and bool(facility_value.get("active", true)):
			candidates.append(str(facility_value.get("section_id", facility_value.get("node_id", facility_value.get("room_id", "")))))
	candidates = candidates.filter(func(value): return value != "")
	candidates.sort()
	return candidates[0] if not candidates.is_empty() else "throne_anteroom"


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
