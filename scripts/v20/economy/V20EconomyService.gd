class_name V20EconomyService
extends RefCounted

const DEFAULT_PROFILE_ID := "v20_tactician"
const REQUIRED_PROFILE_IDS := ["v20_story", "v20_tactician", "v20_overlord"]


static func validate_catalog(catalog) -> Dictionary:
	var errors: Array[String] = []
	if not (catalog is Dictionary):
		return {"ok": false, "errors": ["economy catalog must be a Dictionary"]}
	for profile_id in REQUIRED_PROFILE_IDS:
		if not catalog.has(profile_id):
			errors.append("economy.%s is required" % profile_id)
	for profile_id_value in catalog.keys():
		var profile_id := str(profile_id_value)
		var profile = catalog.get(profile_id_value)
		if not profile_id.begins_with("v20_") or not (profile is Dictionary):
			errors.append("economy.%s must be a v20 Dictionary" % profile_id)
			continue
		var build: Dictionary = profile.get("build", {})
		var command: Dictionary = profile.get("command", {})
		var encounter: Dictionary = profile.get("encounter", {})
		if str(profile.get("display_name", "")) == "":
			errors.append("economy.%s.display_name is required" % profile_id)
		if int(build.get("initial_points", 0)) < 1 or int(build.get("victory_income", -1)) < 0 or int(build.get("failure_salvage", -1)) < 0:
			errors.append("economy.%s build points must be positive and settlement must be non-negative" % profile_id)
		if int(command.get("max_points", 0)) < 1 or int(command.get("initial_points", -1)) > int(command.get("max_points", 0)):
			errors.append("economy.%s command pool is invalid" % profile_id)
		if float(command.get("recharge_seconds", 0.0)) < 1.0:
			errors.append("economy.%s command recharge must prevent spam" % profile_id)
		if int(encounter.get("objective_cap", 0)) < 1:
			errors.append("economy.%s objective_cap must be positive" % profile_id)
		var telegraph_multiplier := float(encounter.get("telegraph_multiplier", 0.0))
		if telegraph_multiplier < 0.7 or telegraph_multiplier > 1.4:
			errors.append("economy.%s telegraph multiplier must be between 0.7 and 1.4" % profile_id)
		var hp_multiplier := float(encounter.get("hp_multiplier", 0.0))
		if hp_multiplier < 0.9 or hp_multiplier > 1.1:
			errors.append("economy.%s HP multiplier must stay between 0.9 and 1.1" % profile_id)
		if not (profile.get("result_metrics") is Array) or profile.get("result_metrics", []).size() < 3:
			errors.append("economy.%s must declare at least three result metrics" % profile_id)
	return {"ok": errors.is_empty(), "errors": errors}


static func profile(catalog: Dictionary, profile_id: String = DEFAULT_PROFILE_ID) -> Dictionary:
	var resolved_id := profile_id if catalog.has(profile_id) else DEFAULT_PROFILE_ID
	if not catalog.has(resolved_id) and not catalog.is_empty():
		var ids: Array = catalog.keys()
		ids.sort()
		resolved_id = str(ids[0])
	var result: Dictionary = catalog.get(resolved_id, {}).duplicate(true)
	result["id"] = resolved_id
	return result


static func configured_encounter(encounter: Dictionary, difficulty: Dictionary) -> Dictionary:
	var result := encounter.duplicate(true)
	var rules: Dictionary = difficulty.get("encounter", {})
	var objectives: Array = encounter.get("objectives", []).duplicate()
	for objective_value in rules.get("extra_objectives", []):
		var objective := str(objective_value)
		if not objectives.has(objective):
			objectives.append(objective)
	var objective_cap := maxi(1, int(rules.get("objective_cap", objectives.size())))
	result["objectives"] = objectives.slice(0, mini(objectives.size(), objective_cap))
	result["difficulty_profile_id"] = str(difficulty.get("id", DEFAULT_PROFILE_ID))
	result["difficulty_label"] = str(difficulty.get("display_name", "보통"))
	result["build_budget"] = int(difficulty.get("build", {}).get("initial_points", 10))
	var telegraph_multiplier := float(rules.get("telegraph_multiplier", 1.0))
	var hp_multiplier := float(rules.get("hp_multiplier", 1.0))
	var atk_multiplier := float(rules.get("atk_multiplier", 1.0))
	var response_bonus := int(rules.get("response_matches_bonus", 0))
	for phase_index in range(result.get("phases", []).size()):
		var phase: Dictionary = result["phases"][phase_index]
		phase["telegraph_seconds"] = snappedf(maxf(0.5, float(phase.get("telegraph_seconds", 0.5)) * telegraph_multiplier), 0.1)
		phase["minimum_response_matches"] = mini(phase.get("response_tags", []).size(), int(phase.get("minimum_response_matches", 1)) + response_bonus)
		for spawn_index in range(phase.get("spawns", []).size()):
			var spawn: Dictionary = phase["spawns"][spawn_index]
			spawn["hp_scale"] = snappedf(minf(1.35, float(spawn.get("hp_scale", 1.0)) * hp_multiplier), 0.01)
			spawn["atk_scale"] = snappedf(float(spawn.get("atk_scale", 1.0)) * atk_multiplier, 0.01)
			phase["spawns"][spawn_index] = spawn
		result["phases"][phase_index] = phase
	return result


static func command_settings(difficulty: Dictionary) -> Dictionary:
	var command: Dictionary = difficulty.get("command", {})
	return {
		"max_points": maxi(1, int(command.get("max_points", 3))),
		"initial_points": maxi(0, int(command.get("initial_points", 3))),
		"recharge_seconds": maxf(1.0, float(command.get("recharge_seconds", 12.0)))
	}


static func new_state(difficulty: Dictionary) -> Dictionary:
	var metrics: Dictionary = {}
	for metric_id_value in difficulty.get("result_metrics", []):
		metrics[str(metric_id_value)] = 0.0
	return {
		"profile_id": str(difficulty.get("id", DEFAULT_PROFILE_ID)),
		"build_points": int(difficulty.get("build", {}).get("initial_points", 10)),
		"days_completed": 0,
		"metrics": metrics,
		"history": []
	}


static func spend_build(state: Dictionary, amount: int, reason: String) -> Dictionary:
	if amount < 0 or int(state.get("build_points", 0)) < amount:
		return {"ok": false, "error": "insufficient_build_points", "state": state.duplicate(true)}
	var next := state.duplicate(true)
	next["build_points"] = int(next.get("build_points", 0)) - amount
	_add_metric(next, "build_points_spent", amount)
	next["history"].append({"type": "build_spent", "amount": amount, "reason": reason})
	return {"ok": true, "state": next}


static func settle_day(state: Dictionary, difficulty: Dictionary, outcome: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var build: Dictionary = difficulty.get("build", {})
	var success := bool(outcome.get("success", false))
	var gross := int(build.get("victory_income", 0)) if success else int(build.get("failure_salvage", 0))
	var damage_units := ceili(maxf(0.0, float(outcome.get("objective_damage", 0.0))) / 25.0)
	var repair := mini(int(build.get("repair_reserve", 0)), damage_units)
	var net := maxi(0, gross - repair)
	next["build_points"] = int(next.get("build_points", 0)) + net
	next["days_completed"] = int(next.get("days_completed", 0)) + (1 if success else 0)
	_add_metric(next, "repair_points_spent", repair)
	_add_metric(next, "command_points_spent", int(outcome.get("command_points_spent", 0)))
	_add_metric(next, "secondary_objectives_lost", int(outcome.get("secondary_objectives_lost", 0)))
	next["history"].append({"type": "day_settlement", "success": success, "gross": gross, "repair": repair, "net": net})
	return {"state": next, "gross_income": gross, "repair_cost": repair, "net_income": net}


static func decision_load(encounter: Dictionary, difficulty: Dictionary) -> Dictionary:
	var rules: Dictionary = difficulty.get("encounter", {})
	var response_matches := 0
	var telegraph_total := 0.0
	for phase_value in encounter.get("phases", []):
		response_matches += int(phase_value.get("minimum_response_matches", 1))
		telegraph_total += float(phase_value.get("telegraph_seconds", 0.0))
	var phase_count := maxi(1, encounter.get("phases", []).size())
	var average_telegraph := telegraph_total / phase_count
	var objectives: int = encounter.get("objectives", []).size()
	var build_points := int(difficulty.get("build", {}).get("initial_points", 10))
	var command: Dictionary = difficulty.get("command", {})
	var score: float = objectives * 10.0 + response_matches * 8.0 + (14 - build_points) * 1.5 + maxf(0.0, float(command.get("recharge_seconds", 12.0)) - 8.0) + maxf(0.0, 6.0 - average_telegraph) * 2.0
	return {"score": snappedf(score, 0.1), "objective_count": objectives, "response_matches": response_matches, "average_telegraph_seconds": snappedf(average_telegraph, 0.1), "build_points": build_points, "pressure_tier": int(difficulty.get("pressure_tier", 1)), "telegraph_multiplier": float(rules.get("telegraph_multiplier", 1.0))}


static func estimated_duration(encounter: Dictionary) -> float:
	var target := float(encounter.get("limits", {}).get("target_duration_seconds", 60.0))
	var hp_total := 0.0
	var spawn_count := 0
	for phase_value in encounter.get("phases", []):
		for spawn_value in phase_value.get("spawns", []):
			hp_total += float(spawn_value.get("hp_scale", 1.0)) * int(spawn_value.get("count", 1))
			spawn_count += int(spawn_value.get("count", 1))
	var average_hp := hp_total / maxi(1, spawn_count)
	return snappedf(target * average_hp, 0.1)


static func management_summary(difficulty: Dictionary) -> String:
	var build := int(difficulty.get("build", {}).get("initial_points", 10))
	var command: Dictionary = difficulty.get("command", {})
	var encounter: Dictionary = difficulty.get("encounter", {})
	return "%s · 건설 %d · 목표 %d · 명령 %d/%d · 예고 %.0f%%" % [str(difficulty.get("display_name", "보통")), build, int(encounter.get("objective_cap", 2)), int(command.get("initial_points", 3)), int(command.get("max_points", 3)), float(encounter.get("telegraph_multiplier", 1.0)) * 100.0]


static func _add_metric(state: Dictionary, metric_id: String, amount: float) -> void:
	if state.get("metrics", {}).has(metric_id):
		state["metrics"][metric_id] = float(state["metrics"].get(metric_id, 0.0)) + amount
