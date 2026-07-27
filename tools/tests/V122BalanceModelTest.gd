extends Node

const BalanceModel = preload("res://scripts/v122/balance/V122BalanceModel.gd")
const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const ParityModel = preload("res://scripts/v122/parity/V122DayParityModel.gd")
const FIXTURE_PATH := "res://tools/fixtures/v122/day01_05_parity.json"

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var config := BalanceModel.load_config()
	var fixture = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	_expect(BalanceModel.validate_config(config).is_empty(), "balance model config validates")
	_expect(fixture is Dictionary, "DAY 1~5 product parity fixture parses")
	if not fixture is Dictionary:
		get_tree().quit(1)
		return
	_expect(
		str(config.get("source_contract_sha", "")) == str(fixture.get("source_contract_sha", "")),
		"calibration and parity fixture use the same combat reference SHA"
	)
	_expect(
		str(config.get("product_base_sha", "")) == str(fixture.get("product_base_sha", "")),
		"calibration and parity fixture use the same product base SHA"
	)

	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, DataRegistry.quarter_starting_layout, DataRegistry.rooms)
	_expect(bool(graph.validation_summary().get("ok", false)), "product ModuleGraph validates")
	var coefficients: Dictionary = config.get("coefficients", {})
	var max_error := float(coefficients.get("max_relative_error", 0.10))
	var calibration_rows := {}
	for day in range(1, 6):
		var day_fixture: Dictionary = fixture.get("days", {}).get(str(day), {})
		var scenario_results := {}
		for scenario_id in ["A", "B"]:
			var scenario: Dictionary = day_fixture.get("scenarios", {}).get(scenario_id, {})
			scenario_results[scenario_id] = ParityModel.evaluate(
				day,
				scenario,
				graph,
				DataRegistry.monsters,
				DataRegistry.enemies,
				DataRegistry.waves,
				_campaign_monster_state(day),
				day_fixture.get("duration_range_seconds", [])
			)
		var calibration: Dictionary = BalanceModel.calibrate_day(
			config.get("day01_05_calibration", {}).get(str(day), {}),
			scenario_results,
			coefficients
		)
		calibration_rows[str(day)] = calibration
		_expect(
			float(calibration.get("damage_relative_error", 1.0)) <= max_error,
			"DAY %d E_HP damage budget error stays within ±10%%: %s" % [day, calibration]
		)
		_expect(
			float(calibration.get("max_duration_relative_error", 1.0)) <= max_error,
			"DAY %d A/B duration error stays within ±10%%: %s" % [day, calibration]
		)

	_check_formula_contracts(coefficients)
	print("V122_BALANCE_CALIBRATION: %s" % JSON.stringify(calibration_rows))
	if failed:
		print("V122_BALANCE_MODEL_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_BALANCE_MODEL_TEST: PASS")
		get_tree().quit(0)


func _check_formula_contracts(coefficients: Dictionary) -> void:
	_expect(
		is_equal_approx(float(coefficients.get("new_hard_pattern_discount", 0.0)), 0.07)
		and is_equal_approx(float(coefficients.get("extra_objective_discount", 0.0)), 0.04)
		and is_equal_approx(float(coefficients.get("forced_command_discount", 0.0)), 0.03)
		and is_equal_approx(float(coefficients.get("max_relative_error", 0.0)), 0.10),
		"calibrated complexity and ±10% gate coefficients are frozen"
	)
	_expect(
		is_equal_approx(BalanceModel.complexity_discount({}, coefficients), 1.0),
		"zero-complexity discount is 1.0"
	)
	_expect(
		is_equal_approx(
			BalanceModel.complexity_discount({
				"new_hard_patterns": 99,
				"extra_objectives": 99,
				"forced_command_moments": 99
			}, coefficients),
			0.72
		),
		"complexity discount keeps the frozen 0.72 floor"
	)
	_expect(
		is_equal_approx(BalanceModel.player_ehp(440.0, 20.0, 30.0, 10.0), 500.0),
		"P_EHP includes healing, shields, and prevented damage"
	)
	_expect(
		is_equal_approx(BalanceModel.player_control(3.0, 2.0, 4.0), 9.0),
		"P_CONTROL includes slow, stagger, and route delay"
	)
	_expect(
		is_equal_approx(BalanceModel.facility_value({
			"added_damage": 10.0,
			"prevented_damage": 20.0,
			"effective_healing": 30.0,
			"delay_seconds": 2.0,
			"objective_loss_prevented_value": 40.0
		}, 5.0), 110.0),
		"P_FACILITY uses the frozen ledger value equation"
	)
	var no_command := {
		"throne_damage": 100.0,
		"monster_losses": 1.0,
		"facility_losses": 1.0,
		"gold_stolen": 30.0,
		"disable_seconds": 5.0,
		"rear_pressure_seconds": 4.0,
		"breach_count": 1.0,
		"combat_seconds": 70.0
	}
	var with_command := {
		"throne_damage": 20.0,
		"monster_losses": 0.0,
		"facility_losses": 0.0,
		"gold_stolen": 0.0,
		"disable_seconds": 1.0,
		"rear_pressure_seconds": 1.0,
		"breach_count": 0.0,
		"combat_seconds": 66.0
	}
	_expect(
		BalanceModel.command_value(no_command, with_command) > 0.0,
		"P_COMMAND is positive only when the command reduces measured outcome pressure"
	)
	var wave_dps := BalanceModel.wave_dps_budget(500.0, 0.2, 1500.0, 0.1, 20.0, 50.0)
	_expect(is_equal_approx(wave_dps, 5.4), "WaveDPSBudget follows the frozen equation")
	_expect(is_equal_approx(BalanceModel.unit_hp(900.0, 0.4, 3), 120.0), "UnitHP allocates role share per unit")
	_expect(is_equal_approx(BalanceModel.unit_atk(30.0, 1.2, 0.5, 2.0), 9.0), "UnitATK allocates DPS share by active attacker count")


func _campaign_monster_state(day: int) -> Dictionary:
	var accumulated_exp: int = int([0, 14, 30, 52, 76][clampi(day - 1, 0, 4)])
	var result := {}
	for species_id in ["slime", "goblin", "imp"]:
		var level := 1
		var exp: int = accumulated_exp
		while exp >= 50 + max(0, level - 1) * 30:
			exp -= 50 + max(0, level - 1) * 30
			level += 1
		result[species_id] = {"level": level, "exp": exp}
	return result


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
