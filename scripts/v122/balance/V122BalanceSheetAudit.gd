class_name V122BalanceSheetAudit
extends RefCounted

const BalanceModel = preload("res://scripts/v122/balance/V122BalanceModel.gd")
const SHEET_PATH := "res://data/v122/balance_day06_30.json"
const REQUIRED_ROW_FIELDS := [
	"campaign_fixture",
	"player_growth",
	"roster",
	"facilities",
	"castle_stage",
	"enemy_formation",
	"enemy_objectives",
	"new_patterns",
	"telegraph",
	"responses",
	"command_class",
	"target_combat_seconds",
	"allowed_throne_damage",
	"allowed_monster_losses",
	"required_failure_causes",
	"seed_expectations",
	"physical_sample",
	"model_inputs"
]


static func load_sheet() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SHEET_PATH))
	return parsed if parsed is Dictionary else {}


static func validate_interval(
	sheet: Dictionary,
	interval_id: String,
	waves: Dictionary,
	enemies: Dictionary,
	campaign_days: Dictionary,
	castle_stages: Dictionary
) -> Array[String]:
	var errors: Array[String] = []
	if int(sheet.get("schema_version", 0)) != 1:
		errors.append("sheet schema_version must be 1")
	if str(sheet.get("model_feature_sha", "")).length() != 40:
		errors.append("model_feature_sha must be a full SHA")
	var seeds = sheet.get("seed_schedule")
	if not seeds is Array or seeds.size() != 3:
		errors.append("seed_schedule must contain exactly three seeds")
	var interval = sheet.get("intervals", {}).get(interval_id)
	if not interval is Dictionary:
		errors.append("interval is missing: %s" % interval_id)
		return errors
	var day_values = interval.get("days")
	var rows = interval.get("rows")
	if not day_values is Array or not rows is Dictionary:
		errors.append("interval days/rows are invalid: %s" % interval_id)
		return errors
	for day_value in day_values:
		var day := int(day_value)
		var row = rows.get(str(day))
		if not row is Dictionary:
			errors.append("DAY %d row is missing" % day)
			continue
		for field in REQUIRED_ROW_FIELDS:
			if not row.has(field):
				errors.append("DAY %d missing field: %s" % [day, field])
		if str(row.get("campaign_fixture", "")) != "day_%d" % day:
			errors.append("DAY %d campaign fixture key is not aligned" % day)
		if not campaign_days.has("day_%d" % day):
			errors.append("DAY %d product campaign definition is missing" % day)
		if not castle_stages.has(str(row.get("castle_stage", ""))):
			errors.append("DAY %d castle stage is missing" % day)
		var summary := actual_wave_summary(day, waves, enemies)
		if int(summary.get("unit_count", 0)) <= 0:
			errors.append("DAY %d product wave is empty" % day)
		for enemy_id_value in row.get("enemy_formation", []):
			if not summary.get("enemy_ids", []).has(str(enemy_id_value)):
				errors.append("DAY %d sheet enemy is absent from product wave: %s" % [day, enemy_id_value])
		for actual_enemy_id in summary.get("enemy_ids", []):
			if not row.get("enemy_formation", []).has(actual_enemy_id):
				errors.append("DAY %d product enemy is absent from sheet: %s" % [day, actual_enemy_id])
		var responses = row.get("responses")
		if not responses is Dictionary:
			errors.append("DAY %d responses are invalid" % day)
			continue
		for scenario_id in ["A", "B", "C", "D"]:
			if not responses.get(scenario_id) is Dictionary:
				errors.append("DAY %d response %s is missing" % [day, scenario_id])
		if str(responses.get("D", {}).get("one_slot_from", "")) != "A":
			errors.append("DAY %d response D must be one slot from A" % day)
		var physical = row.get("physical_sample")
		if not physical is Dictionary:
			errors.append("DAY %d physical sample is invalid" % day)
		elif (
			str(physical.get("result", "")) != "WIN"
			or float(physical.get("seconds", 0.0)) <= 0.0
			or int(physical.get("throne_damage", 0)) > int(row.get("allowed_throne_damage", -1))
			or int(physical.get("monster_losses", 0)) > int(row.get("allowed_monster_losses", -1))
			or int(physical.get("objective_loss", 0)) > 0
		):
			errors.append("DAY %d physical sample exceeds sheet limits" % day)
		if row.has("boss_phase_budget"):
			var boss_budget = row.get("boss_phase_budget")
			if not boss_budget is Dictionary:
				errors.append("DAY %d boss phase budget is invalid" % day)
			else:
				for boss_key in [
					"phase_hp_budget",
					"phase_time_target",
					"telegraph_window",
					"interrupt_threshold",
					"summon_budget",
					"objective_pressure_budget",
					"recovery_window",
					"final_phase_risk"
				]:
					if not boss_budget.has(boss_key):
						errors.append("DAY %d boss phase field is missing: %s" % [day, boss_key])
				var phase_hp = boss_budget.get("phase_hp_budget")
				var phase_time = boss_budget.get("phase_time_target")
				if not phase_hp is Array or phase_hp.size() < 2:
					errors.append("DAY %d boss requires at least two HP phases" % day)
				elif BalanceModel.relative_error(_numeric_sum(phase_hp), float(summary.get("wave_hp", 0.0))) > 0.10:
					errors.append("DAY %d boss phase HP does not match product wave" % day)
				if not phase_time is Array or phase_time.size() != phase_hp.size():
					errors.append("DAY %d boss phase time count is invalid" % day)
				elif BalanceModel.relative_error(_numeric_sum(phase_time), float(row.get("target_combat_seconds", 0.0))) > 0.10:
					errors.append("DAY %d boss phase time does not match target" % day)
	return errors


static func audit_day(
	day: int,
	row: Dictionary,
	seeds: Array,
	waves: Dictionary,
	enemies: Dictionary,
	coefficients: Dictionary
) -> Dictionary:
	var actual := actual_wave_summary(day, waves, enemies)
	var inputs: Dictionary = row.get("model_inputs", {})
	var complexity: Dictionary = inputs.get("complexity", {})
	var target_seconds := float(row.get("target_combat_seconds", 0.0))
	var hp_budget := BalanceModel.wave_hp_budget(
		float(inputs.get("player_dps_median", 0.0)),
		target_seconds,
		float(inputs.get("target_attack_uptime", 0.0)),
		float(inputs.get("difficulty_modifier", 1.0)),
		complexity,
		coefficients
	)
	var dps_budget := BalanceModel.wave_dps_budget(
		float(inputs.get("player_ehp_median", 0.0)),
		float(inputs.get("target_monster_loss_ratio", 0.0)),
		float(inputs.get("objective_hp", 0.0)),
		float(inputs.get("target_objective_loss_ratio", 0.0)),
		float(inputs.get("expected_healing", 0.0)),
		target_seconds
	)
	var effective_enemy_dps := (
		float(actual.get("raw_enemy_dps", 0.0))
		* float(inputs.get("enemy_attack_uptime", 0.0))
	)
	var scenario_results := {}
	for scenario_id in ["A", "B"]:
		var results: Array[Dictionary] = []
		for seed_value in seeds:
			results.append(_run_seeded_response(day, scenario_id, row, int(seed_value), 1.0))
		scenario_results[scenario_id] = results
	var c_seed := int(seeds[0]) if not seeds.is_empty() else day
	scenario_results["C"] = [_run_seeded_response(day, "C", row, c_seed, 1.0)]
	scenario_results["D"] = [_run_seeded_response(day, "D", row, c_seed, 1.0)]
	scenario_results["x3"] = [_run_seeded_response(day, "A", row, c_seed, 3.0)]
	return {
		"day": day,
		"actual_wave_hp": snappedf(float(actual.get("wave_hp", 0.0)), 0.001),
		"wave_hp_budget": snappedf(hp_budget, 0.001),
		"hp_relative_error": snappedf(BalanceModel.relative_error(hp_budget, float(actual.get("wave_hp", 0.0))), 0.000001),
		"actual_effective_enemy_dps": snappedf(effective_enemy_dps, 0.001),
		"wave_dps_budget": snappedf(dps_budget, 0.001),
		"dps_relative_error": snappedf(BalanceModel.relative_error(dps_budget, effective_enemy_dps), 0.000001),
		"complexity_discount": snappedf(BalanceModel.complexity_discount(complexity, coefficients), 0.001),
		"last_spawn_second": float(actual.get("last_spawn_second", 0.0)),
		"scenario_results": scenario_results
	}


static func actual_wave_summary(day: int, waves: Dictionary, enemies: Dictionary) -> Dictionary:
	var wave_hp := 0.0
	var raw_enemy_dps := 0.0
	var unit_count := 0
	var last_spawn_second := 0.0
	var enemy_ids: Array[String] = []
	var objectives: Array[String] = []
	for entry_value in waves.get("day_%d" % day, []):
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var enemy_id := str(entry.get("enemy_id", ""))
		var enemy: Dictionary = enemies.get(enemy_id, {})
		var count := maxi(0, int(entry.get("count", 0)))
		var hp_scale := float(entry.get("hp_scale", 1.0))
		var atk_scale := float(entry.get("atk_scale", 1.0))
		wave_hp += float(enemy.get("max_hp", 0.0)) * hp_scale * count
		raw_enemy_dps += (
			float(enemy.get("atk", 0.0))
			* atk_scale
			/ maxf(0.1, float(enemy.get("attack_interval", 1.0)))
			* count
		)
		unit_count += count
		last_spawn_second = maxf(
			last_spawn_second,
			float(entry.get("spawn_delay", 0.0))
			+ maxi(0, count - 1) * float(entry.get("spawn_interval", 1.0))
		)
		if enemy_id != "" and not enemy_ids.has(enemy_id):
			enemy_ids.append(enemy_id)
		var objective := str(enemy.get("goal_type", "throne"))
		if not objectives.has(objective):
			objectives.append(objective)
	enemy_ids.sort()
	objectives.sort()
	return {
		"wave_hp": wave_hp,
		"raw_enemy_dps": raw_enemy_dps,
		"unit_count": unit_count,
		"last_spawn_second": last_spawn_second,
		"enemy_ids": enemy_ids,
		"objectives": objectives
	}


static func seeded_results_pass(results: Array, expected_success: bool) -> bool:
	if results.is_empty():
		return false
	for result_value in results:
		if not result_value is Dictionary or bool(result_value.get("success", false)) != expected_success:
			return false
	return true


static func one_slot_cause_is_visible(scenario_results: Dictionary) -> bool:
	var a_rows: Array = scenario_results.get("A", [])
	var d_rows: Array = scenario_results.get("D", [])
	if a_rows.is_empty() or d_rows.is_empty():
		return false
	return (
		bool(a_rows[0].get("success", false))
		and not bool(d_rows[0].get("success", true))
		and float(d_rows[0].get("pressure", 0.0)) - float(a_rows[0].get("pressure", 0.0)) >= 0.07
	)


static func x3_outcome_is_invariant(scenario_results: Dictionary) -> bool:
	var a_rows: Array = scenario_results.get("A", [])
	var x3_rows: Array = scenario_results.get("x3", [])
	if a_rows.is_empty() or x3_rows.is_empty():
		return false
	return (
		bool(a_rows[0].get("success", false)) == bool(x3_rows[0].get("success", true))
		and is_equal_approx(
			float(a_rows[0].get("simulated_seconds", 0.0)),
			float(x3_rows[0].get("simulated_seconds", -1.0))
		)
		and absf(
			float(a_rows[0].get("wall_clock_seconds", 0.0)) / 3.0
			- float(x3_rows[0].get("wall_clock_seconds", -1.0))
		) <= 0.001
	)


static func _run_seeded_response(
	day: int,
	scenario_id: String,
	row: Dictionary,
	seed: int,
	speed: float
) -> Dictionary:
	var response: Dictionary = row.get("responses", {}).get(scenario_id, {})
	var seed_modifier: float = float([0.98, 1.0, 1.02][abs(seed) % 3])
	var response_ratio: float = float(response.get("power", 0.0)) * seed_modifier
	var success: bool = response_ratio >= 0.99
	var target_seconds := float(row.get("target_combat_seconds", 0.0))
	var simulated_seconds := target_seconds / maxf(0.5, response_ratio)
	var pressure := maxf(0.0, 1.0 - response_ratio)
	return {
		"day": day,
		"scenario": scenario_id,
		"seed": seed,
		"speed": speed,
		"success": success,
		"simulated_seconds": snappedf(simulated_seconds, 0.001),
		"wall_clock_seconds": snappedf(simulated_seconds / maxf(1.0, speed), 0.001),
		"pressure": snappedf(pressure, 0.001),
		"failure_cause": "" if success else str(row.get("required_failure_causes", ["insufficient_response"])[0])
	}


static func _numeric_sum(values: Array) -> float:
	var total := 0.0
	for value in values:
		total += float(value)
	return total
