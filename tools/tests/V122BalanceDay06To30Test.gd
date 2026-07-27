extends Node

const BalanceModel = preload("res://scripts/v122/balance/V122BalanceModel.gd")
const SheetAudit = preload("res://scripts/v122/balance/V122BalanceSheetAudit.gd")

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var sheet := SheetAudit.load_sheet()
	var config := BalanceModel.load_config()
	var coefficients: Dictionary = config.get("coefficients", {})
	var max_error := float(coefficients.get("max_relative_error", 0.10))
	_expect(not sheet.is_empty(), "DAY 06~30 balance sheet parses")
	_expect(BalanceModel.validate_config(config).is_empty(), "frozen DAY 01~05 balance model validates")
	_expect(
		str(sheet.get("model_feature_sha", "")) == "2cb02232f3359fa0c03bf702310e34ff57fa5226",
		"DAY 06~30 sheets remain pinned to the P9 frozen model"
	)
	var audit_rows := {}
	for interval_id_value in sheet.get("intervals", {}).keys():
		var interval_id := str(interval_id_value)
		var validation_errors := SheetAudit.validate_interval(
			sheet,
			interval_id,
			DataRegistry.waves,
			DataRegistry.enemies,
			DataRegistry.campaign_days,
			DataRegistry.castle_evolution_stages
		)
		_expect(validation_errors.is_empty(), "%s sheet validates: %s" % [interval_id, validation_errors])
		var interval: Dictionary = sheet.get("intervals", {}).get(interval_id, {})
		for day_value in interval.get("days", []):
			var day := int(day_value)
			var row: Dictionary = interval.get("rows", {}).get(str(day), {})
			var audit := SheetAudit.audit_day(
				day,
				row,
				sheet.get("seed_schedule", []),
				DataRegistry.waves,
				DataRegistry.enemies,
				coefficients
			)
			audit_rows[str(day)] = audit
			_expect(
				float(audit.get("hp_relative_error", 1.0)) <= max_error,
				"DAY %d product E_HP stays within frozen ±10%% gate: %s" % [day, audit]
			)
			_expect(
				float(audit.get("dps_relative_error", 1.0)) <= max_error,
				"DAY %d product E_DPS stays within frozen ±10%% gate: %s" % [day, audit]
			)
			var results: Dictionary = audit.get("scenario_results", {})
			_expect(SheetAudit.seeded_results_pass(results.get("A", []), true), "DAY %d A seed 3 wins" % day)
			_expect(SheetAudit.seeded_results_pass(results.get("B", []), true), "DAY %d B seed 3 wins" % day)
			_expect(SheetAudit.seeded_results_pass(results.get("C", []), false), "DAY %d C seed 1 fails" % day)
			_expect(SheetAudit.one_slot_cause_is_visible(results), "DAY %d D exposes one-slot causality" % day)
			_expect(SheetAudit.x3_outcome_is_invariant(results), "DAY %d x3 keeps the x1 outcome" % day)
	print("V122_BALANCE_SHEET_AUDIT: %s" % JSON.stringify(audit_rows))
	if failed:
		print("V122_BALANCE_DAY06_30_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_BALANCE_DAY06_30_TEST: PASS")
		get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
