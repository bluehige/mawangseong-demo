extends Node

const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const BattlePlanAdapter = preload("res://scripts/v122/spatial/V122BattlePlanAdapter.gd")
const EncounterAdapter = preload("res://scripts/v122/combat/V122EncounterAdapter.gd")
const CommandService = preload("res://scripts/v122/combat/V122CommandService.gd")
const BattleLedger = preload("res://scripts/v122/combat/V122BattleLedger.gd")
const CombatResultViewModel = preload("res://scripts/v122/ui/V122CombatResultViewModel.gd")

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, DataRegistry.quarter_starting_layout, DataRegistry.rooms)
	var plan := BattlePlanAdapter.build_snapshot(
		graph,
		"stage_01_cave",
		DataRegistry.rooms,
		{
			"mon_core_pudding": {"species_id": "slime", "room": "entrance"},
			"mon_core_gob": {"species_id": "goblin", "room": "barracks"}
		},
		["throne"],
		5
	)
	var telegraphs: Array = [
		EncounterAdapter.telegraph({"id": "thief", "role": "thief"}, plan),
		EncounterAdapter.telegraph({"id": "engineer", "role": "engineer"}, plan),
		EncounterAdapter.telegraph({"id": "trainee_hero", "role": "assault"}, plan)
	]
	var command_state := CommandService.new_state()
	var combat_model := CombatResultViewModel.build_combat(
		plan,
		telegraphs,
		CommandService.load_catalog(),
		command_state,
		{"speed": 3.0, "paused": false}
	)
	_expect(str(combat_model.get("source", "")) == "product_runtime", "combat HUD reads product runtime")
	_expect(combat_model.get("objective_room_ids", []) == ["throne"], "combat HUD shows the actual product objective")
	_expect(combat_model.get("active_route", []) == plan.get("active_route", []), "combat HUD shows the active ModuleGraph route")
	_expect(bool(combat_model.get("threat_panel_visible", false)), "telegraph panel is visible when scheduled threats exist")
	_expect(combat_model.get("threats", []).size() == 3, "thief, engineer, and boss state remain visible")
	_expect(bool(combat_model.get("boss_status_preserved", false)), "existing boss status is preserved")
	_expect(bool(combat_model.get("heart_status_preserved", false)), "existing heart status is preserved")
	_expect(bool(combat_model.get("duo_status_preserved", false)), "existing duo status is preserved")
	_expect(float(combat_model.get("speed", 0.0)) == 3.0, "speed state remains visible")
	var command_ids: Array[String] = []
	for value in combat_model.get("commands", []):
		command_ids.append(str(value.get("id", "")))
	_expect(command_ids == ["rally", "focus", "activate_facility", "emergency_fallback"], "the four limited commands are exposed in stable order")
	for command_id in command_ids:
		var command: Dictionary = CombatResultViewModel.command(combat_model, command_id)
		_expect(str(command.get("target_type", "")) in ["room", "enemy", "facility"], "%s has an actual target type" % command_id)
		_expect(int(command.get("cost", 0)) > 0, "%s exposes its command point cost" % command_id)
	var quiet_model := CombatResultViewModel.build_combat(plan, [], CommandService.load_catalog(), command_state)
	_expect(not bool(quiet_model.get("threat_panel_visible", true)), "telegraph panel is hidden when there is no threat")

	var facility_slot := _facility_slot(plan)
	var facility_result := CommandService.issue(
		command_state,
		"activate_facility",
		{"type": "facility", "id": str(facility_slot.get("room_id", ""))},
		plan,
		BattleLedger.new_state(5, 5005, str(plan.get("layout_fingerprint", "")))
	)
	_expect(bool(facility_result.get("ok", false)), "facility command targets an actual product facility object")
	_expect(not facility_result.get("highlight_anchor", []).is_empty(), "facility command highlights its world anchor")

	var ledger := BattleLedger.new_state(5, 5005, str(plan.get("layout_fingerprint", "")))
	ledger = BattleLedger.record(ledger, "treasure_stolen", {"amount": 40})
	ledger = BattleLedger.record(ledger, "throne_damage", {"amount": 75})
	ledger = BattleLedger.record(ledger, "command_contribution", {"command_id": "focus", "amount": 18.0})
	var result_model := CombatResultViewModel.build_result(
		{
			"win": false,
			"growth": [{"monster_id": "mon_core_pudding"}],
			"metrics": {"treasure_gold_stolen": 40, "alive_monsters": 0, "total_monsters": 2}
		},
		BattleLedger.summarize(ledger),
		{
			"rewards": {"gold": 15},
			"story_preserved": true,
			"meta_progress_preserved": true,
			"ending_preserved": true,
			"next_day_preserved": true
		}
	)
	_expect(str(result_model.get("primary_cause_id", "")) == "throne_damage", "result UI derives its primary cause from the actual battle ledger")
	_expect(int(result_model.get("gold_stolen", 0)) == 40, "result UI retains secondary treasure loss")
	_expect(result_model.get("growth", []).size() == 1, "existing growth result is preserved")
	_expect(int(result_model.get("rewards", {}).get("gold", 0)) == 15, "existing rewards are preserved")
	for key in ["story_preserved", "meta_progress_preserved", "ending_preserved", "next_day_preserved"]:
		_expect(bool(result_model.get(key, false)), "%s remains connected" % key)
	_expect(result_model.get("developer_copy", []).is_empty(), "combat and result UI have no developer copy")

	for viewport_size in [Vector2(1920, 1080), Vector2(1366, 768), Vector2(1280, 720), Vector2(844, 390)]:
		var contract: Dictionary = CombatResultViewModel.layout_contract(viewport_size)
		_expect(str(contract.get("mode", "")) != "orientation_notice", "%dx%d uses a landscape battle HUD" % [int(viewport_size.x), int(viewport_size.y)])
		_expect(_inside(contract, viewport_size), "%dx%d battle regions remain inside the viewport" % [int(viewport_size.x), int(viewport_size.y)])
	var portrait := CombatResultViewModel.layout_contract(Vector2(390, 844))
	_expect(str(portrait.get("mode", "")) == "orientation_notice", "portrait mobile receives a rotation notice")

	if failed:
		print("V122_COMBAT_RESULT_UI_CONTRACT_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_COMBAT_RESULT_UI_CONTRACT_TEST: PASS")
		get_tree().quit(0)


func _facility_slot(plan: Dictionary) -> Dictionary:
	for value in plan.get("facility_slots", []):
		if value is Dictionary and str(value.get("facility_role", "")) not in ["", "entry"]:
			return value
	return {}


func _inside(contract: Dictionary, viewport_size: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	for key in ["tactical_status", "battlefield", "commands", "speed_pause"]:
		var rect: Rect2 = contract.get(key, Rect2())
		if rect.size.x <= 0.0 or rect.size.y <= 0.0 or not bounds.encloses(rect):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
