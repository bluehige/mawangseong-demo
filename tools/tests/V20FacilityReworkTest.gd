extends Node

const Validator = preload("res://scripts/v20/contracts/V20ContractValidator.gd")
const FacilityService = preload("res://scripts/v20/facilities/V20FacilityService.gd")
const PathService = preload("res://scripts/v20/path/V20WeightedPathService.gd")
const CombatControllerScript = preload("res://scripts/game/CombatSceneController.gd")


class RuntimeFacilityRoot extends Node:
	func _v20_runtime_facilities() -> Array[Dictionary]:
		return [{
			"id": "north_gate",
			"facility_id": "v20_barricade",
			"node_id": "north_gate",
			"room_id": "north_gate",
			"slot_id": "north_door_slot",
			"edge_id": "entry_north",
			"active": true
		}]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_contract()
	_test_path_and_goal_effects()
	_test_combat_runtime_route_mapping()
	_test_activation_disable_and_metrics()
	_test_strength_counter_synergy()
	_test_facility_choice_difference()
	if failed:
		print("V20_FACILITY_REWORK_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_FACILITY_REWORK_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_contract() -> void:
	var catalog := DataRegistry.v20_facilities
	var validation := Validator.validate_catalog("facility", catalog)
	_expect(bool(validation.get("ok", false)), "시설 catalog validator 승인: %s" % [validation.get("errors", [])])
	_expect(catalog.size() == 5, "DAY 1~5 전략 시설 5종")
	var roles: Dictionary = {}
	for facility_id_value in catalog.keys():
		var facility_id := str(facility_id_value)
		var definition: Dictionary = catalog.get(facility_id, {})
		roles[str(definition.get("role", ""))] = true
		_expect(str(definition.get("strength", "")) != "" and not definition.get("counter_tags", []).is_empty() and not definition.get("synergy_tags", []).is_empty() and definition.get("result_metrics", []).size() >= 4, "%s 강점·카운터·시너지·결산 지표" % facility_id)
	_expect(roles.size() == 5, "시설 5종 역할 중복 없음")


func _test_path_and_goal_effects() -> void:
	var state := FacilityService.new_battle_state({
		"north_wall": {"facility_id": "v20_barricade", "slot_id": "door_north", "edge_id": "entry_north", "room_id": "north_gate"},
		"treasure_lure": {"facility_id": "v20_decoy_treasure", "slot_id": "treasure_decoy_slot", "edge_id": "south_treasure", "room_id": "treasure"}
	}, DataRegistry.v20_facilities)
	var context := FacilityService.path_context(state, DataRegistry.v20_facilities)
	_expect(float(context.get("facility_route_costs", {}).get("entry_north", 0.0)) == 12.0, "바리케이드가 weighted path 비용 +12")
	_expect(float(context.get("goal_biases", {}).get("treasure", 0.0)) == -8.0, "미끼 보물실이 treasure 목표 선호 생성")
	var explorer := {"role": "explorer", "candidate_goals": ["throne"], "goal_preferences": {"throne": 0.0}, "route_tag_costs": {}}
	var explorer_route := PathService.choose_goal_and_path(_board(), "entrance", explorer, _path_context(context, 13))
	_expect(str(explorer_route.get("first_engagement_node", "")) == "south_gate", "북문 바리케이드가 탐험가를 남문으로 우회")
	var thief := {"role": "thief", "candidate_goals": ["throne"], "goal_preferences": {"throne": 0.0}, "route_tag_costs": {}}
	thief = FacilityService.apply_goal_biases(thief, context, ["thief", "bait_sensitive"])
	var thief_route := PathService.choose_goal_and_path(_board(), "entrance", thief, _path_context(context, 13))
	_expect(str(thief_route.get("goal_key", "")) == "treasure", "미끼 보물실이 도둑 목표를 왕좌에서 분리")
	var normal := FacilityService.apply_goal_biases(explorer, context, ["explorer"])
	_expect(not normal.get("candidate_goals", []).has("treasure"), "미끼 무시 적에게 treasure 목표 미적용")


func _test_combat_runtime_route_mapping() -> void:
	var runtime_root := RuntimeFacilityRoot.new()
	add_child(runtime_root)
	var controller = CombatControllerScript.new()
	controller.setup(runtime_root, null)
	var state: Dictionary = controller._new_v20_facility_state()
	var north: Dictionary = state.get("facilities", {}).get("north_gate", {})
	_expect(str(north.get("slot_id", "")) == "north_door_slot" and str(north.get("edge_id", "")) == "entry_north", "관리 배치 slot·edge가 실제 전투 경로까지 보존")
	var context := FacilityService.path_context(state, DataRegistry.v20_facilities)
	_expect(float(context.get("facility_route_costs", {}).get("entry_north", 0.0)) == 12.0, "실제 전투 바리케이드가 entry_north 경로 비용에 반영")
	runtime_root.queue_free()


func _test_activation_disable_and_metrics() -> void:
	var placements := {
		"north_wall": {"facility_id": "v20_barricade", "slot_id": "door_north", "edge_id": "entry_north", "room_id": "north_gate"},
		"watch": {"facility_id": "v20_watch_post", "slot_id": "south_watch_slot", "edge_id": "south_crossing", "room_id": "south_cross"},
		"nest": {"facility_id": "v20_recovery_nest", "slot_id": "fallback_nest_slot", "edge_id": "fallback_throne", "room_id": "fallback"}
	}
	var state := FacilityService.new_battle_state(placements, DataRegistry.v20_facilities)
	var activated := FacilityService.activate(state, "north_wall", DataRegistry.v20_facilities)
	state = activated.get("state", {})
	_expect(bool(activated.get("ok", false)) and int(state.get("facilities", {}).get("north_wall", {}).get("charges", -1)) == 0, "시설 발동 charge 1회 소비")
	var active_context := FacilityService.path_context(state, DataRegistry.v20_facilities)
	_expect(float(active_context.get("door_state_costs", {}).get("door_north", 0.0)) == 999.0, "바리케이드 발동이 6초 봉쇄 비용 생성")
	_expect(not bool(FacilityService.activate(state, "north_wall", DataRegistry.v20_facilities).get("ok", true)), "charge 소진 뒤 연속 발동 불가")
	state = FacilityService.disable(state, "watch", 5.0).get("state", {})
	_expect(not FacilityService.path_context(state, DataRegistry.v20_facilities).get("facility_route_costs", {}).has("south_crossing"), "공병 무력화 중 시설 경로 효과 제거")
	_expect(not bool(FacilityService.activate(state, "watch", DataRegistry.v20_facilities).get("ok", true)), "무력화 중 수동 발동 거부")
	state = FacilityService.advance(state, 5.0)
	_expect(is_zero_approx(float(state.get("facilities", {}).get("watch", {}).get("disabled_seconds", -1.0))), "무력화 시간 경과 복구")
	state = FacilityService.record_metric(state, "nest", "healing_done", 42.0).get("state", {})
	state = FacilityService.record_metric(state, "nest", "returns_to_line", 2.0).get("state", {})
	var summary := FacilityService.result_summary(state, DataRegistry.v20_facilities)
	var nest_summary: Dictionary = summary.filter(func(row): return str(row.get("placement_id", "")) == "nest")[0]
	_expect(float(nest_summary.get("metrics", {}).get("healing_done", 0.0)) == 42.0 and float(nest_summary.get("metrics", {}).get("returns_to_line", 0.0)) == 2.0, "회복 둥지 결산 회복·복귀 지표")


func _test_strength_counter_synergy() -> void:
	var catalog := DataRegistry.v20_facilities
	_expect(FacilityService.synergy_score("v20_barricade", ["slime_gate_keeper"], catalog) == 1, "바리케이드×성문 파수 시너지")
	_expect(FacilityService.synergy_score("v20_watch_post", ["imp_artillery"], catalog) == 1, "감시 초소×임프 포병 시너지")
	_expect(FacilityService.synergy_score("v20_recovery_nest", ["slime_rescue_guard"], catalog) == 1, "회복 둥지×구조 점액 시너지")
	_expect(FacilityService.is_countered("v20_barricade", ["engineer"], catalog), "공병이 바리케이드 명시 카운터")
	_expect(FacilityService.is_countered("v20_recovery_nest", ["healing_suppression"], catalog), "회복 억제가 둥지 명시 카운터")


func _test_facility_choice_difference() -> void:
	var barricade_state := FacilityService.new_battle_state({"choice": {"facility_id": "v20_barricade", "slot_id": "door_north", "edge_id": "entry_north", "room_id": "north_gate"}}, DataRegistry.v20_facilities)
	var barracks_state := FacilityService.new_battle_state({"choice": {"facility_id": "v20_barracks", "slot_id": "south_watch_slot", "edge_id": "south_crossing", "room_id": "south_cross"}}, DataRegistry.v20_facilities)
	var enemy := {"role": "explorer", "candidate_goals": ["throne"], "goal_preferences": {"throne": 0.0}, "route_tag_costs": {}}
	var barricade_route := PathService.choose_goal_and_path(_board(), "entrance", enemy, _path_context(FacilityService.path_context(barricade_state, DataRegistry.v20_facilities), 71))
	var barracks_route := PathService.choose_goal_and_path(_board(), "entrance", enemy, _path_context(FacilityService.path_context(barracks_state, DataRegistry.v20_facilities), 71))
	_expect(str(barricade_route.get("signature", "")) != str(barracks_route.get("signature", "")), "시설 A/B가 서로 다른 적 경로 생성")
	_expect(str(barricade_route.get("first_engagement_node", "")) == "south_gate" and str(barracks_route.get("first_engagement_node", "")) == "north_gate", "차단 시설과 거점 시설 첫 교전 위치 구분")


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
