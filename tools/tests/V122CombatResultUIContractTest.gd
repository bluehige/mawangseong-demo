extends Node

const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const BattlePlanAdapter = preload("res://scripts/v122/spatial/V122BattlePlanAdapter.gd")
const EncounterAdapter = preload("res://scripts/v122/combat/V122EncounterAdapter.gd")
const CommandService = preload("res://scripts/v122/combat/V122CommandService.gd")
const BattleLedger = preload("res://scripts/v122/combat/V122BattleLedger.gd")
const CombatResultViewModel = preload("res://scripts/v122/ui/V122CombatResultViewModel.gd")
const CombatSceneController = preload("res://scripts/game/CombatSceneController.gd")


class BreachGraph:
	extends RefCounted

	func path_between(_from_room_id: String, to_room_id: String) -> Array:
		return {
			"entrance": ["entrance"],
			"barracks": ["entrance", "barracks"],
			"throne": ["entrance", "barracks", "throne"]
		}.get(to_room_id, [])


class BreachRoot:
	extends Node

	var enemy_units: Array = []
	var graph = BreachGraph.new()

	func display_name_for_instance(instance_id: String) -> String:
		return {
			"outside_approach": "성 외곽",
			"entrance": "입구",
			"barracks": "병영",
			"throne": "왕좌"
		}.get(instance_id, instance_id)


class BreachEnemy:
	extends Node

	var unit_id := "breach_fixture"
	var current_room := "entrance"
	var goal_room := "throne"

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
	var expected_target_types := {
		"rally": "defense_zone",
		"focus": "enemy",
		"activate_facility": "facility",
		"emergency_fallback": "defense_zone"
	}
	for command_id in command_ids:
		var command: Dictionary = CombatResultViewModel.command(combat_model, command_id)
		_expect(str(command.get("target_type", "")) == str(expected_target_types.get(command_id, "")), "%s exposes its exact typed target" % command_id)
		_expect(int(command.get("cost", 0)) > 0, "%s exposes its command point cost" % command_id)
	var quiet_model := CombatResultViewModel.build_combat(plan, [], CommandService.load_catalog(), command_state)
	_expect(not bool(quiet_model.get("threat_panel_visible", true)), "telegraph panel is hidden when there is no threat")

	var facility_slot := _facility_slot(plan)
	var facility_slot_id := str(facility_slot.get("slot_id", ""))
	var facility_room_id := str(facility_slot.get("room_id", ""))
	var facility_result := CommandService.issue(
		command_state,
		"activate_facility",
		{"type": "facility", "id": facility_slot_id},
		plan,
		BattleLedger.new_state(5, 5005, str(plan.get("layout_fingerprint", "")))
	)
	_expect(bool(facility_result.get("ok", false)), "facility command targets an actual product facility object")
	_expect(not facility_result.get("highlight_anchor", []).is_empty(), "facility command highlights its world anchor")
	var normalized_facility_target: Dictionary = facility_result.get("state", {}).get("active_commands", {}).get("activate_facility", {}).get("target", {})
	_expect(str(normalized_facility_target.get("id", "")) == facility_slot_id, "facility command preserves the stable slot ID")
	_expect(str(normalized_facility_target.get("room_id", "")) == facility_room_id, "facility command keeps the spatial room ID separate")

	var legacy_segment: Dictionary = plan.get("defense_segments", []).front()
	var rally_result := CommandService.issue(
		CommandService.new_state(),
		"rally",
		{"type": "defense_zone", "id": str(legacy_segment.get("segment_id", ""))},
		plan,
		BattleLedger.new_state(5, 5006, str(plan.get("layout_fingerprint", "")))
	)
	_expect(bool(rally_result.get("ok", false)), "legacy defense segments remain valid typed zone targets")

	_check_live_breach_tracking()

	var ledger := BattleLedger.new_state(5, 5005, str(plan.get("layout_fingerprint", "")))
	ledger = BattleLedger.record(ledger, "treasure_stolen", {"amount": 40})
	ledger = BattleLedger.record(ledger, "throne_damage", {"amount": 75})
	ledger = BattleLedger.record(ledger, "command_contribution", {"command_id": "focus", "amount": 18.0})
	var result_model := CombatResultViewModel.build_result(
		{
			"win": false,
			"growth": [{"monster_id": "mon_core_pudding"}],
			"metrics": {
				"treasure_gold_stolen": 40,
				"alive_monsters": 0,
				"total_monsters": 2,
				"monster_contributions": {
					"goblin": {"damage_absorbed": 32, "damage_dealt": 47}
				},
				"decision_context": {
					"day": 1,
					"directive_id": "defense",
					"directive_name": "사수",
					"monster_placements": [{
						"monster_id": "goblin",
						"monster_name": "곱",
						"room_id": "spike_corridor",
						"room_name": "전열 통로",
						"defense_zone_id": "zone_a_front"
					}]
				}
			}
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
	var decision_feedback: Dictionary = result_model.get("decision_feedback", {})
	_expect(
		str(decision_feedback.get("strategy_label", "")) == "전방 봉쇄"
		and str(decision_feedback.get("summary", "")).contains("곱 → 전열")
		and str(decision_feedback.get("summary", "")).contains("공격 47"),
		"DAY 1 result connects the confirmed placement and directive to measured combat impact"
	)
	var rear_room_fallback := CombatResultViewModel.build_result(
		{
			"win": true,
			"metrics": {
				"alive_monsters": 3,
				"total_monsters": 3,
				"monster_contributions": {"goblin": {"damage_dealt": 21}},
				"decision_context": {
					"day": 1,
					"directive_name": "사수",
					"monster_placements": [{
						"monster_id": "goblin",
						"monster_name": "곱",
						"room_id": "path_a_front_rear",
						"room_name": "후열 연결 통로",
						"defense_zone_id": ""
					}]
				}
			}
		},
		{},
		{}
	)
	_expect(
		str(rear_room_fallback.get("decision_feedback", {}).get("strategy_label", "")) == "후방 화력"
			and str(rear_room_fallback.get("decision_feedback", {}).get("placement_label", "")).contains("후열"),
		"DAY 1 result recognizes the rear support anchor even when a legacy payload lacks a zone ID"
	)
	_expect(result_model.get("growth", []).size() == 1, "existing growth result is preserved")
	_expect(int(result_model.get("rewards", {}).get("gold", 0)) == 15, "existing rewards are preserved")
	for key in ["story_preserved", "meta_progress_preserved", "ending_preserved", "next_day_preserved"]:
		_expect(bool(result_model.get(key, false)), "%s remains connected" % key)
	_expect(result_model.get("developer_copy", []).is_empty(), "combat and result UI have no developer copy")
	var management_model := CombatResultViewModel.build_result(
		{"win": true, "management_only": true, "metrics": {"day": 29, "next_day": 30}},
		{}
	)
	_expect(
		str(management_model.get("core_metrics", [])[0].get("id", "")) == "preparation_state"
		and str(management_model.get("core_metrics", [])[2].get("value", "")) == "DAY 30",
		"management-only settlement replaces meaningless combat metrics with preparation status"
	)
	var outpost_model := CombatResultViewModel.build_result(
		{
			"win": false,
			"outpost_battle": true,
			"metrics": {
				"ending_hp": 180,
				"max_hp": 300,
				"duration_seconds": 42.5,
				"retry_count": 1
			}
		},
		{}
	)
	_expect(
		str(outpost_model.get("core_metrics", [])[0].get("value", "")) == "180 / 300"
		and str(outpost_model.get("core_metrics", [])[1].get("value", "")) == "42.5초"
		and str(outpost_model.get("actions", [])[0].get("id", "")) == "continue",
		"outpost settlement shows flag durability and duration without main-castle retry actions"
	)

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


func _check_live_breach_tracking() -> void:
	var breach_root := BreachRoot.new()
	add_child(breach_root)
	var enemy := BreachEnemy.new()
	breach_root.add_child(enemy)
	breach_root.enemy_units.append(enemy)
	breach_root.set_meta("v122_battle_plan", {
		"active_route": ["outside_approach", "entrance", "barracks", "throne"],
		"route_start": "outside_approach"
	})
	breach_root.set_meta("v122_battle_ledger", BattleLedger.new_state(1, 1001, "fixture"))
	var controller = CombatSceneController.new()
	controller.setup(breach_root, null)

	var entrance_summary := controller._v122_result_ledger_summary()
	_expect(
		str(entrance_summary.get("final_breach_segment", "")) == "돌파 없음"
		and entrance_summary.get("events", []).is_empty(),
		"an enemy spawned at the entrance does not fabricate an outside-to-entrance breach"
	)

	enemy.current_room = "barracks"
	controller._record_v122_enemy_room_transition(enemy, "entrance", "barracks")
	var barracks_summary := BattleLedger.summarize(breach_root.get_meta("v122_battle_ledger", {}))
	_expect(
		str(barracks_summary.get("final_breach_segment", "")) == "입구 → 병영",
		"live room movement advances the final breach segment"
	)
	var event_count_before_retreat: int = int(barracks_summary.get("events", []).size())

	enemy.goal_room = "entrance"
	enemy.current_room = "entrance"
	controller._record_v122_enemy_room_transition(enemy, "barracks", "entrance")
	var retreat_summary := BattleLedger.summarize(breach_root.get_meta("v122_battle_ledger", {}))
	_expect(
		str(retreat_summary.get("final_breach_segment", "")) == "입구 → 병영"
		and retreat_summary.get("events", []).size() == event_count_before_retreat,
		"retreating does not erase or falsely advance the deepest reached segment"
	)

	enemy.goal_room = "throne"
	enemy.current_room = "throne"
	controller._record_v122_enemy_room_transition(enemy, "barracks", "throne")
	var result_summary := controller._v122_result_ledger_summary()
	_expect(
		str(result_summary.get("final_breach_segment", "")) == "병영 → 왕좌"
		and is_equal_approx(float(result_summary.get("breach_progress", 0.0)), 1.0),
		"result ledger is finalized from the deepest live room observation"
	)
	breach_root.queue_free()


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
