class_name V122BalanceModel
extends RefCounted

const CONFIG_PATH := "res://data/v122/balance_model.json"
const DEFAULT_COEFFICIENTS := {
	"new_hard_pattern_discount": 0.07,
	"extra_objective_discount": 0.04,
	"forced_command_discount": 0.03,
	"complexity_min": 0.72,
	"complexity_max": 1.0,
	"max_relative_error": 0.10
}
const DEFAULT_OUTCOME_WEIGHTS := {
	"throne_damage": 1.0,
	"monster_losses": 120.0,
	"facility_losses": 100.0,
	"gold_stolen": 1.0,
	"disable_seconds": 8.0,
	"rear_pressure_seconds": 6.0,
	"breach_count": 90.0,
	"combat_seconds": 0.5
}


static func load_config() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return parsed if parsed is Dictionary else {}


static func validate_config(config: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if int(config.get("schema_version", 0)) != 1:
		errors.append("schema_version must be 1")
	for sha_key in ["source_contract_sha", "product_base_sha"]:
		if str(config.get(sha_key, "")).length() != 40:
			errors.append("%s must be a full SHA" % sha_key)
	var coefficients = config.get("coefficients")
	if not coefficients is Dictionary:
		errors.append("coefficients must be a Dictionary")
	else:
		for key in DEFAULT_COEFFICIENTS.keys():
			if not _is_number(coefficients.get(key)):
				errors.append("coefficient must be numeric: %s" % key)
		if float(coefficients.get("complexity_min", 0.0)) <= 0.0:
			errors.append("complexity_min must be positive")
		if float(coefficients.get("complexity_min", 1.0)) > float(coefficients.get("complexity_max", 0.0)):
			errors.append("complexity bounds are reversed")
	var calibration = config.get("day01_05_calibration")
	if not calibration is Dictionary:
		errors.append("day01_05_calibration must be a Dictionary")
		return errors
	for day in range(1, 6):
		var row = calibration.get(str(day))
		if not row is Dictionary:
			errors.append("calibration day is missing: %d" % day)
			continue
		for numeric_key in ["reference_wave_hp", "target_combat_seconds", "target_attack_uptime", "difficulty_modifier"]:
			if not _is_number(row.get(numeric_key)) or float(row.get(numeric_key)) <= 0.0:
				errors.append("calibration value is invalid: day %d/%s" % [day, numeric_key])
		if float(row.get("target_attack_uptime", 0.0)) > 1.0:
			errors.append("target_attack_uptime must not exceed 1: day %d" % day)
		var scenarios = row.get("scenarios")
		if not scenarios is Dictionary:
			errors.append("calibration scenarios are missing: day %d" % day)
			continue
		for scenario_id in ["A", "B"]:
			var scenario = scenarios.get(scenario_id)
			if not scenario is Dictionary or not _is_number(scenario.get("seconds")) or not _is_number(scenario.get("monster_damage")):
				errors.append("calibration scenario is invalid: day %d/%s" % [day, scenario_id])
	return errors


static func complexity_discount(complexity: Dictionary, coefficients: Dictionary = {}) -> float:
	var values := _coefficients(coefficients)
	var discount := (
		1.0
		- float(values.get("new_hard_pattern_discount", 0.07)) * maxi(0, int(complexity.get("new_hard_patterns", 0)))
		- float(values.get("extra_objective_discount", 0.04)) * maxi(0, int(complexity.get("extra_objectives", 0)))
		- float(values.get("forced_command_discount", 0.03)) * maxi(0, int(complexity.get("forced_command_moments", 0)))
	)
	return clampf(
		discount,
		float(values.get("complexity_min", 0.72)),
		float(values.get("complexity_max", 1.0))
	)


static func wave_hp_budget(
	player_dps_median: float,
	target_combat_seconds: float,
	target_attack_uptime: float,
	difficulty_modifier: float,
	complexity: Dictionary,
	coefficients: Dictionary = {}
) -> float:
	return (
		maxf(0.0, player_dps_median)
		* maxf(0.0, target_combat_seconds)
		* clampf(target_attack_uptime, 0.0, 1.0)
		* maxf(0.0, difficulty_modifier)
		* complexity_discount(complexity, coefficients)
	)


static func wave_dps_budget(
	player_ehp_median: float,
	target_monster_loss_ratio: float,
	objective_hp: float,
	target_objective_loss_ratio: float,
	expected_healing: float,
	target_combat_seconds: float
) -> float:
	var damage_budget := (
		maxf(0.0, player_ehp_median) * clampf(target_monster_loss_ratio, 0.0, 1.0)
		+ maxf(0.0, objective_hp) * clampf(target_objective_loss_ratio, 0.0, 1.0)
		+ maxf(0.0, expected_healing)
	)
	return damage_budget / maxf(0.001, target_combat_seconds)


static func estimated_duration(
	wave_hp: float,
	player_dps: float,
	target_attack_uptime: float,
	difficulty_modifier: float,
	complexity: Dictionary,
	coefficients: Dictionary = {}
) -> float:
	var effective_rate := (
		maxf(0.001, player_dps)
		* clampf(target_attack_uptime, 0.001, 1.0)
		* maxf(0.001, difficulty_modifier)
		* complexity_discount(complexity, coefficients)
	)
	return maxf(0.0, wave_hp) / effective_rate


static func unit_hp(wave_hp: float, role_hp_share: float, unit_count: int) -> float:
	return maxf(0.0, wave_hp) * maxf(0.0, role_hp_share) / maxi(1, unit_count)


static func unit_atk(
	wave_dps: float,
	attack_interval: float,
	role_damage_share: float,
	expected_active_attacker_count: float
) -> float:
	return (
		maxf(0.0, wave_dps)
		* maxf(0.0, attack_interval)
		* maxf(0.0, role_damage_share)
		/ maxf(0.001, expected_active_attacker_count)
	)


static func player_ehp(
	starting_hp: float,
	effective_healing: float,
	effective_shields: float,
	prevented_damage: float
) -> float:
	return (
		maxf(0.0, starting_hp)
		+ maxf(0.0, effective_healing)
		+ maxf(0.0, effective_shields)
		+ maxf(0.0, prevented_damage)
	)


static func player_control(slow_seconds: float, stagger_seconds: float, route_delay_seconds: float) -> float:
	return maxf(0.0, slow_seconds) + maxf(0.0, stagger_seconds) + maxf(0.0, route_delay_seconds)


static func facility_value(contribution: Dictionary, player_dps: float) -> float:
	return (
		maxf(0.0, float(contribution.get("added_damage", 0.0)))
		+ maxf(0.0, float(contribution.get("prevented_damage", 0.0)))
		+ maxf(0.0, float(contribution.get("effective_healing", 0.0)))
		+ maxf(0.0, float(contribution.get("delay_seconds", 0.0))) * maxf(0.0, player_dps)
		+ maxf(0.0, float(contribution.get("objective_loss_prevented_value", 0.0)))
	)


static func command_value(no_command_outcome: Dictionary, command_outcome: Dictionary, weights: Dictionary = {}) -> float:
	return outcome_pressure(no_command_outcome, weights) - outcome_pressure(command_outcome, weights)


static func outcome_pressure(outcome: Dictionary, weights: Dictionary = {}) -> float:
	var resolved_weights := DEFAULT_OUTCOME_WEIGHTS.duplicate(true)
	for key in DEFAULT_OUTCOME_WEIGHTS.keys():
		if _is_number(weights.get(key)):
			resolved_weights[key] = float(weights.get(key))
	var total := 0.0
	for key in resolved_weights.keys():
		total += maxf(0.0, float(outcome.get(key, 0.0))) * float(resolved_weights.get(key, 0.0))
	return total


static func relative_error(estimate: float, reference: float) -> float:
	return absf(estimate - reference) / maxf(0.001, absf(reference))


static func calibrate_day(
	calibration: Dictionary,
	scenario_results: Dictionary,
	coefficients: Dictionary = {}
) -> Dictionary:
	var dps_values: Array[float] = []
	for scenario_id in ["A", "B"]:
		var result = scenario_results.get(scenario_id)
		if result is Dictionary:
			dps_values.append(float(result.get("effective_dps", 0.0)))
	dps_values.sort()
	var player_dps_median := _median(dps_values)
	var complexity: Dictionary = calibration.get("complexity", {})
	var target_seconds := float(calibration.get("target_combat_seconds", 0.0))
	var target_uptime := float(calibration.get("target_attack_uptime", 0.0))
	var difficulty := float(calibration.get("difficulty_modifier", 1.0))
	var reference_hp := float(calibration.get("reference_wave_hp", 0.0))
	var hp_budget := wave_hp_budget(
		player_dps_median,
		target_seconds,
		target_uptime,
		difficulty,
		complexity,
		coefficients
	)
	var scenario_rows := {}
	var max_duration_error := 0.0
	for scenario_id in ["A", "B"]:
		var result: Dictionary = scenario_results.get(scenario_id, {})
		var reference: Dictionary = calibration.get("scenarios", {}).get(scenario_id, {})
		var duration := estimated_duration(
			reference_hp,
			float(result.get("effective_dps", 0.0)),
			target_uptime,
			difficulty,
			complexity,
			coefficients
		)
		var duration_error := relative_error(duration, float(reference.get("seconds", 0.0)))
		max_duration_error = maxf(max_duration_error, duration_error)
		scenario_rows[scenario_id] = {
			"estimated_duration_seconds": snappedf(duration, 0.001),
			"reference_duration_seconds": float(reference.get("seconds", 0.0)),
			"duration_relative_error": snappedf(duration_error, 0.000001),
			"reference_monster_damage": float(reference.get("monster_damage", 0.0))
		}
	return {
		"player_dps_median": snappedf(player_dps_median, 0.001),
		"complexity_discount": snappedf(complexity_discount(complexity, coefficients), 0.001),
		"wave_hp_budget": snappedf(hp_budget, 0.001),
		"reference_wave_hp": reference_hp,
		"damage_relative_error": snappedf(relative_error(hp_budget, reference_hp), 0.000001),
		"max_duration_relative_error": snappedf(max_duration_error, 0.000001),
		"scenarios": scenario_rows
	}


static func _coefficients(value: Dictionary) -> Dictionary:
	var result := DEFAULT_COEFFICIENTS.duplicate(true)
	for key in DEFAULT_COEFFICIENTS.keys():
		if _is_number(value.get(key)):
			result[key] = float(value.get(key))
	return result


static func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var middle := values.size() / 2
	if values.size() % 2 == 1:
		return values[middle]
	return (values[middle - 1] + values[middle]) * 0.5


static func _is_number(value) -> bool:
	return value is int or value is float
