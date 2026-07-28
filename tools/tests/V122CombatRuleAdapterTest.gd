extends Node

const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const BattlePlanAdapter = preload("res://scripts/v122/spatial/V122BattlePlanAdapter.gd")
const BattleLedger = preload("res://scripts/v122/combat/V122BattleLedger.gd")
const CommandService = preload("res://scripts/v122/combat/V122CommandService.gd")
const FacilityEffectAdapter = preload("res://scripts/v122/combat/V122FacilityEffectAdapter.gd")
const CombatRuleAdapter = preload("res://scripts/v122/combat/V122CombatRuleAdapter.gd")
const EncounterAdapter = preload("res://scripts/v122/combat/V122EncounterAdapter.gd")
const BreachService = preload("res://scripts/v122/combat/V122BreachService.gd")

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, DataRegistry.quarter_starting_layout, DataRegistry.rooms)
	var roster := {
		"mon_core_pudding": {"species_id": "slime", "room": "entrance"},
		"mon_core_gob": {"species_id": "goblin", "room": "barracks"},
		"mon_core_pynn": {"species_id": "imp", "room": "recovery"}
	}
	var plan := BattlePlanAdapter.build_snapshot(graph, "stage_01_cave", DataRegistry.rooms, roster, ["throne"], 1)
	var ledger := BattleLedger.new_state(1, 2001, str(plan.get("layout_fingerprint", "")))
	var commands := CommandService.new_state()

	var rally := CommandService.issue(commands, "rally", {"type": "room", "id": "entrance"}, plan, ledger)
	_expect(bool(rally.get("ok", false)), "DAY 1 rally command is accepted on a product room")
	_expect(int(rally["state"].get("points", 0)) == 2, "rally spends one command point")
	_expect(not rally.has("directive_patch"), "rally remains a direct AI order instead of silently changing a directive")
	_expect(rally.get("highlight_anchor", []) == plan["world_anchors"]["entrance"], "rally highlights the actual product room")
	var rally_order := CommandService.movement_order_for_actor(rally["state"], "mon_core_gob", "barracks", "monster")
	_expect(str(rally_order.get("target_room_id", "")) == "entrance", "rally routes a monster to the selected product room")
	var rally_effect := CommandService.effect_for_actor(rally["state"], "mon_core_pudding", "entrance", "monster")
	_expect(float(rally_effect.get("move_speed_multiplier", 1.0)) > 1.0, "rally changes movement outcome")
	_expect(float(rally_effect.get("damage_taken_multiplier", 1.0)) < 1.0, "rally changes survival outcome")
	_expect(
		not CommandService.effect_for_actor(rally["state"], "enemy_day1_scout", "entrance", "enemy").has("move_speed_multiplier"),
		"friendly room commands do not buff enemies in the same room"
	)
	var blocked_rally := CommandService.issue(rally["state"], "rally", {"type": "room", "id": "entrance"}, plan, rally["ledger"])
	_expect(str(blocked_rally.get("status", "")) == "cooldown", "rally cooldown is enforced")

	var focus := CommandService.issue(rally["state"], "focus", {"type": "enemy", "id": "enemy_day1_scout", "world_anchor": plan["world_anchors"]["entrance"]}, plan, rally["ledger"])
	_expect(bool(focus.get("ok", false)), "focus accepts a concrete enemy target")
	_expect(not focus.has("directive_patch"), "focus remains a target-priority order instead of changing the global directive")
	_expect(CommandService.focus_target_id(focus["state"]) == "enemy_day1_scout", "focus exposes the selected enemy to combat AI")
	_expect(float(CommandService.effect_for_actor(focus["state"], "enemy_day1_scout", "entrance", "enemy").get("damage_multiplier", 1.0)) > 1.0, "focus changes actual target damage")

	var advanced := CommandService.advance(focus["state"], 12.0)
	_expect(not advanced.get("active_commands", {}).has("focus"), "commands end after their duration")
	_expect(int(advanced.get("points", 0)) >= 2, "command points recharge")

	var entrance_slot := _facility_slot(plan, "entry")
	var near_enemy := {"faction": "enemy", "world_anchor": plan["world_anchors"]["entrance"]}
	var entry_effect := FacilityEffectAdapter.effect_for_actor(entrance_slot, near_enemy)
	_expect(entry_effect.is_empty(), "entry is a breach object, not a passive aura")
	var barracks_slot := _facility_slot(plan, "barracks")
	var near_monster := {"faction": "monster", "world_anchor": barracks_slot.get("world_anchor", [])}
	var barracks_effect := FacilityEffectAdapter.effect_for_actor(barracks_slot, near_monster)
	_expect(float(barracks_effect.get("damage_multiplier", 1.0)) > 1.0, "barracks applies at its actual world anchor")
	var far_monster := {"faction": "monster", "world_anchor": [99999.0, 99999.0]}
	_expect(FacilityEffectAdapter.effect_for_actor(barracks_slot, far_monster).is_empty(), "facility effects do not apply outside their actual range")
	_expect(FacilityEffectAdapter.effect_for_actor(barracks_slot, near_monster, 3.0).is_empty(), "disabled facilities have zero effect")

	var monster_decision := CombatRuleAdapter.monster_action(
		{"hp": 10, "current_room": "entrance", "assigned_room": "barracks"},
		{
			"existing_special_action": {"skill_id": "slime_shield"},
			"placement_role_action": {"room_id": "entrance"}
		}
	)
	_expect(str(monster_decision.get("action", "")) == "existing_special", "existing monster skills keep priority over placement roles")
	var commanded_decision := CombatRuleAdapter.monster_action(
		{"hp": 10, "current_room": "entrance", "assigned_room": "barracks"},
		{"active_command": {"command_id": "rally"}, "existing_special_action": {"skill_id": "slime_shield"}}
	)
	_expect(str(commanded_decision.get("action", "")) == "limited_command", "limited commands use the documented AI priority")
	var enemy_decision := CombatRuleAdapter.enemy_action(
		{"hp": 10},
		{"existing_boss_or_special_action": {"phase": 2}, "role_action": {"room_id": "barracks"}}
	)
	_expect(str(enemy_decision.get("action", "")) == "existing_boss_or_special", "existing boss and special behavior stays ahead of role targeting")

	var engineer := EncounterAdapter.telegraph({"id": "engineer_day1", "role": "engineer"}, plan)
	_expect(str(engineer.get("target_room_id", "")) == "barracks", "engineer telegraph targets a real product facility")
	_expect(not engineer.get("target_anchor", []).is_empty(), "engineer target has a visible object anchor")
	var thief := EncounterAdapter.telegraph({"id": "thief_day1", "role": "thief"}, plan)
	_expect(str(thief.get("target_room_id", "")) == "treasure", "thief targets the actual product treasure room")

	var breach := BreachService.new_state("entrance", str(entrance_slot.get("object_id", "")), 100.0, plan.get("active_route", []))
	var interrupted := BreachService.apply_damage(breach, 30.0, true)
	_expect(is_zero_approx(float(interrupted.get("breach_progress", -1.0))), "interrupted breach does not advance a timer-only state")
	var damaged := BreachService.apply_damage(breach, 40.0)
	_expect(float(damaged.get("breach_progress", 0.0)) == 40.0, "breach damage updates the actual entrance object")
	var completed := BreachService.apply_damage(damaged, 60.0)
	_expect(bool(completed.get("completed", false)), "breach completes from object damage")
	_expect(not completed.get("next_route", []).is_empty(), "breach completion retains the real product route")

	var final_ledger := BattleLedger.record(focus["ledger"], "facility_effect", {"room_id": "barracks", "amount": 12.0})
	final_ledger = BattleLedger.record(final_ledger, "breach_progress", {"room_id": "entrance", "progress": 1.0})
	final_ledger = BattleLedger.record(final_ledger, "command_contribution", {"command_id": "focus", "amount": 25.0})
	var summary := BattleLedger.summarize(final_ledger)
	_expect(int(summary.get("event_counts", {}).get("command_issued", 0)) == 2, "ledger records each accepted product command")
	_expect(float(summary.get("facility_contribution", {}).get("barracks", 0.0)) == 12.0, "ledger derives facility result contribution from events")
	_expect(float(summary.get("command_contribution", {}).get("focus", 0.0)) == 25.0, "ledger derives command result contribution from events")

	if failed:
		print("V122_COMBAT_RULE_ADAPTER_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_COMBAT_RULE_ADAPTER_TEST: PASS")
		get_tree().quit(0)


func _facility_slot(plan: Dictionary, role: String) -> Dictionary:
	for value in plan.get("facility_slots", []):
		if value is Dictionary and str(value.get("facility_role", "")) == role:
			return value
	return {}


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
