extends Node

const Validator = preload("res://scripts/v20/contracts/V20ContractValidator.gd")
const FacilityService = preload("res://scripts/v20/facilities/V20FacilityService.gd")
const PathService = preload("res://scripts/v20/path/V20WeightedPathService.gd")
const CombatControllerScript = preload("res://scripts/game/CombatSceneController.gd")


class RuntimeFacilityRoot extends Node:
	func _v20_spatial_facility_rows() -> Array[Dictionary]:
		return [{
			"id": "gate_outpost",
			"facility_id": "v20_barricade",
			"node_id": "gate_outpost",
			"room_id": "gate_outpost",
			"slot_id": "gate_outpost_facility",
			"edge_id": "gate_outpost_to_spike_corridor",
			"active": true
		}]


var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_contract()
	_test_canonical_path_costs()
	_test_combat_runtime_mapping()
	_test_activation_disable_and_metrics()
	_test_distinct_combat_effects()
	if failed:
		print("V20_FACILITY_REWORK_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_FACILITY_REWORK_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_contract() -> void:
	var catalog := DataRegistry.v20_facilities
	var validation := Validator.validate_catalog("facility", catalog)
	_expect(bool(validation.get("ok", false)), "시설 catalog validator 통과: %s" % [validation.get("errors", [])])
	_expect(catalog.size() == 5, "DAY 1~5 시설 선택지 5개 로드")
	for facility_id in catalog.keys():
		var definition: Dictionary = catalog.get(facility_id, {})
		_expect(str(definition.get("role", "")) != "" and not definition.get("combat_effect", {}).is_empty() and definition.get("result_metrics", []).size() >= 4, "%s 역할·실전 효과·결과 지표 선언" % facility_id)


func _test_canonical_path_costs() -> void:
	var barricade_state := FacilityService.new_battle_state({
		"gate_outpost": {"facility_id": "v20_barricade", "slot_id": "gate_outpost_facility", "edge_id": "gate_outpost_to_spike_corridor", "room_id": "gate_outpost"}
	}, DataRegistry.v20_facilities)
	var barracks_state := FacilityService.new_battle_state({
		"gate_outpost": {"facility_id": "v20_barracks", "slot_id": "gate_outpost_facility", "edge_id": "gate_outpost_to_spike_corridor", "room_id": "gate_outpost"}
	}, DataRegistry.v20_facilities)
	var barricade_context := FacilityService.path_context(barricade_state, DataRegistry.v20_facilities)
	var barracks_context := FacilityService.path_context(barracks_state, DataRegistry.v20_facilities)
	_expect(float(barricade_context.get("facility_route_costs", {}).get("gate_outpost_to_spike_corridor", 0.0)) == 12.0, "gate_outpost 바리케이드가 첫 edge 비용 +12")
	_expect(float(barracks_context.get("facility_route_costs", {}).get("gate_outpost_to_spike_corridor", 0.0)) == 1.0, "같은 슬롯 병영은 첫 edge 비용 +1")
	var enemy := {"role": "explorer", "candidate_goals": ["throne"], "goal_preferences": {"throne": 0.0}, "route_tag_costs": {}}
	var barricade_route := PathService.choose_goal_and_path(_board(), "gate_outpost", enemy, _path_context(barricade_context, 71))
	var barracks_route := PathService.choose_goal_and_path(_board(), "gate_outpost", enemy, _path_context(barracks_context, 71))
	_expect(barricade_route.get("nodes", []) == _board().get("fixed_route", {}).get("nodes", []) and barracks_route.get("nodes", []) == barricade_route.get("nodes", []), "시설 A/B 모두 canonical route 순서 유지")
	_expect(float(barricade_route.get("total_cost", 0.0)) - float(barracks_route.get("total_cost", 0.0)) == 11.0, "시설 선택이 같은 이동 경로의 비용을 11 차이로 변경")


func _test_combat_runtime_mapping() -> void:
	var runtime_root := RuntimeFacilityRoot.new()
	add_child(runtime_root)
	var controller = CombatControllerScript.new()
	controller.setup(runtime_root, null)
	var state: Dictionary = controller._new_v20_facility_state()
	var runtime: Dictionary = state.get("facilities", {}).get("gate_outpost", {})
	_expect(str(runtime.get("room_id", "")) == "gate_outpost" and str(runtime.get("slot_id", "")) == "gate_outpost_facility", "관리 배치의 canonical 방·시설 슬롯이 전투 상태에 보존")
	_expect(str(runtime.get("edge_id", "")) == "gate_outpost_to_spike_corridor", "시설이 영향을 주는 실제 이동 edge ID 보존")
	runtime_root.queue_free()


func _test_activation_disable_and_metrics() -> void:
	var placements := {
		"front": {"facility_id": "v20_barricade", "slot_id": "gate_outpost_facility", "edge_id": "gate_outpost_to_spike_corridor", "room_id": "gate_outpost"},
		"rear": {"facility_id": "v20_recovery_nest", "slot_id": "throne_anteroom_facility", "edge_id": "throne_anteroom_to_throne", "room_id": "throne_anteroom"}
	}
	var state := FacilityService.new_battle_state(placements, DataRegistry.v20_facilities)
	_expect(is_equal_approx(float(FacilityService.effects_for_room(state, "gate_outpost", DataRegistry.v20_facilities).get("enemy_slow_multiplier", 1.0)), 0.78), "gate_outpost 바리케이드가 적 이동 배율 0.78 제공")
	_expect(is_equal_approx(float(FacilityService.effects_for_room(state, "throne_anteroom", DataRegistry.v20_facilities).get("heal_per_second", 0.0)), 8.0), "throne_anteroom 회복 둥지가 초당 8 회복 제공")
	state = FacilityService.activate(state, "front", DataRegistry.v20_facilities).get("state", {})
	_expect(is_equal_approx(float(FacilityService.effects_for_room(state, "gate_outpost", DataRegistry.v20_facilities).get("enemy_slow_multiplier", 1.0)), 0.48), "바리케이드 발동 중 적 이동 배율 0.48")
	_expect(float(FacilityService.path_context(state, DataRegistry.v20_facilities).get("door_state_costs", {}).get("gate_outpost_facility", 0.0)) == 999.0, "발동 중 gate_outpost_facility 통과 비용 999")
	state = FacilityService.disable(state, "front", 5.0).get("state", {})
	_expect(FacilityService.effects_for_room(state, "gate_outpost", DataRegistry.v20_facilities).is_empty(), "공병 무력화 5초 동안 실제 전투 효과 제거")
	state = FacilityService.advance(state, 5.0)
	_expect(is_zero_approx(float(state.get("facilities", {}).get("front", {}).get("disabled_seconds", -1.0))), "5초 경과 뒤 시설 무력화 해제")
	state = FacilityService.record_metric(state, "rear", "healing_done", 42.0).get("state", {})
	var rear_rows := FacilityService.result_summary(state, DataRegistry.v20_facilities).filter(func(row): return str(row.get("placement_id", "")) == "rear")
	_expect(rear_rows.size() == 1 and float(rear_rows[0].get("metrics", {}).get("healing_done", 0.0)) == 42.0, "회복량 42가 결과 지표에 기록")


func _test_distinct_combat_effects() -> void:
	var barracks := FacilityService.new_battle_state({"choice": {"facility_id": "v20_barracks", "room_id": "central_battle_room"}}, DataRegistry.v20_facilities)
	var barracks_effect := FacilityService.effects_for_room(barracks, "central_battle_room", DataRegistry.v20_facilities)
	_expect(is_equal_approx(float(barracks_effect.get("monster_damage_multiplier", 1.0)), 1.12) and is_equal_approx(float(barracks_effect.get("monster_damage_taken_multiplier", 1.0)), 0.88), "중앙 전투실 병영이 공격 1.12·피해 0.88 적용")
	var decoy := FacilityService.new_battle_state({"choice": {"facility_id": "v20_decoy_treasure", "room_id": "central_battle_room"}}, DataRegistry.v20_facilities)
	var passive := FacilityService.effects_for_room(decoy, "central_battle_room", DataRegistry.v20_facilities)
	_expect(is_equal_approx(float(passive.get("thief_slow_multiplier", 1.0)), 0.82) and is_equal_approx(float(passive.get("loot_delay_multiplier", 1.0)), 1.5), "중앙 전투실 미끼가 도둑 0.82 감속·약탈 준비 1.5배 적용")
	decoy = FacilityService.activate(decoy, "choice", DataRegistry.v20_facilities).get("state", {})
	var active := FacilityService.effects_for_room(decoy, "central_battle_room", DataRegistry.v20_facilities)
	_expect(is_equal_approx(float(active.get("thief_slow_multiplier", 1.0)), 0.55) and is_equal_approx(float(active.get("loot_delay_multiplier", 1.0)), 2.0), "미끼 발동 중 도둑 0.55 감속·약탈 준비 2배 적용")


func _path_context(facility_context: Dictionary, seed_value: int) -> Dictionary:
	return {
		"seed": seed_value,
		"door_state_costs": facility_context.get("door_state_costs", {}).duplicate(true),
		"facility_route_costs": facility_context.get("facility_route_costs", {}).duplicate(true),
		"temporary_hazard_costs": facility_context.get("temporary_hazard_costs", {}).duplicate(true)
	}


func _board() -> Dictionary:
	return DataRegistry.v20_dungeon_layouts.get("v20_day_01_05_board", {}).duplicate(true)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20FacilityRework] FAIL: %s" % message)
