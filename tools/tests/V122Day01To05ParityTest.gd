extends Node

const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const ParityModel = preload("res://scripts/v122/parity/V122DayParityModel.gd")
const FIXTURE_PATH := "res://tools/fixtures/v122/day01_05_parity.json"

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var fixture = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	_expect(fixture is Dictionary, "DAY 1~5 parity fixture parses")
	if not fixture is Dictionary:
		get_tree().quit(1)
		return
	_expect(str(fixture.get("source_contract_sha", "")) == "7e61cc9762b5c157a52160ce7f13ad0bf0a7d358", "combat reference SHA is fixed")
	_expect(str(fixture.get("product_base_sha", "")) == "c483d135b13cf9771ee43b045ba2c3dde51573ee", "product runtime tag SHA is fixed")
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, DataRegistry.quarter_starting_layout, DataRegistry.rooms)
	_expect(bool(graph.validation_summary().get("ok", false)), "product ModuleGraph validates")

	var previous_exp := -1
	for day in range(1, 6):
		_expect(not DataRegistry.waves.get("day_%d" % day, []).is_empty(), "DAY %d uses the product wave catalog" % day)
		var day_fixture: Dictionary = fixture.get("days", {}).get(str(day), {})
		var scenarios: Dictionary = day_fixture.get("scenarios", {})
		var monster_state := _campaign_monster_state(day)
		var total_exp := 0
		for value in monster_state.values():
			total_exp += int(value.get("exp", 0)) + (int(value.get("level", 1)) - 1) * 50
		_expect(total_exp >= previous_exp, "DAY %d keeps accumulated product growth" % day)
		previous_exp = total_exp
		var results := {}
		for scenario_id in ["A", "B", "C", "D"]:
			var scenario: Dictionary = scenarios.get(scenario_id, {})
			var result := ParityModel.evaluate(
				day,
				scenario,
				graph,
				DataRegistry.monsters,
				DataRegistry.enemies,
				DataRegistry.waves,
				monster_state,
				day_fixture.get("duration_range_seconds", [])
			)
			results[scenario_id] = result
			_expect(bool(result.get("success", false)) == bool(scenario.get("expected_success", false)), "DAY %d response %s matches its parity outcome: %s" % [day, scenario_id, result])
		_expect(bool(results["A"].get("success", false)) and bool(results["B"].get("success", false)), "DAY %d has two valid winning responses" % day)
		_expect(not bool(results["C"].get("success", true)) and str(results["C"].get("penalty_reason", "")) != "", "DAY %d wrong response has a concrete penalty" % day)
		_expect(bool(results["D"].get("success", false)), "DAY %d one-slot response remains viable" % day)
		_expect(_placement_difference(scenarios["A"].get("placements", {}), scenarios["D"].get("placements", {})) == 1, "DAY %d D changes exactly one monster slot" % day)
		_expect(_metric_difference_count(results["A"], results["D"]) >= 2, "DAY %d D changes at least two causal metrics" % day)

	GameState.reset()
	var initial_resources := GameState.campaign_snapshot()
	for _day in range(1, 6):
		GameState.advance_day()
	_expect(GameState.day == 6, "DAY 5 victory path continues to product DAY 6")
	_expect(GameState.gold > int(initial_resources.get("gold", 0)) and GameState.mana > int(initial_resources.get("mana", 0)), "product income and rewards are not replaced by a test economy")
	_expect(not DataRegistry.campaign_day(6).is_empty() and not DataRegistry.waves.get("day_6", []).is_empty(), "DAY 6 story and combat content remain connected")

	if failed:
		print("V122_DAY01_TO_05_PARITY_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_DAY01_TO_05_PARITY_TEST: PASS")
		get_tree().quit(0)


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


func _placement_difference(left: Dictionary, right: Dictionary) -> int:
	var count := 0
	for monster_id in left.keys():
		if str(left.get(monster_id, "")) != str(right.get(monster_id, "")):
			count += 1
	return count


func _metric_difference_count(left: Dictionary, right: Dictionary) -> int:
	var count := 0
	for key in ["first_engagement_room", "total_route_steps", "effective_damage", "estimated_duration_seconds", "throne_damage"]:
		if left.get(key) != right.get(key):
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
