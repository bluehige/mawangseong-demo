extends Node

const RoleService = preload("res://scripts/v20/monsters/V20MonsterRoleService.gd")

const ROLE_IDS := [
	"slime_gate_keeper",
	"slime_rescue_guard",
	"goblin_treasure_hunter",
	"goblin_finisher",
	"imp_artillery",
	"imp_trap_weaver"
]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_role_contracts()
	_test_slime_pair()
	_test_goblin_pair()
	_test_imp_pair()
	_test_focus_command_and_evidence()
	if failed:
		print("V20_MONSTER_ROLE_GROWTH_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_MONSTER_ROLE_GROWTH_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_role_contracts() -> void:
	var monsters: Dictionary = {}
	for role_id in ROLE_IDS:
		var legacy: Dictionary = DataRegistry.specialization(role_id)
		var contract := RoleService.role_contract(role_id, DataRegistry.specializations)
		monsters[str(contract.get("monster_id", ""))] = int(monsters.get(str(contract.get("monster_id", "")), 0)) + 1
		_expect(not contract.is_empty(), "%s v2 역할 계약 존재" % role_id)
		_expect(str(contract.get("ai_behavior", "")) == str(legacy.get("ai_behavior", "")), "%s 기존 AI behavior 보존" % role_id)
		_expect(contract.get("result_metrics", []).size() == 4 and not contract.get("facility_synergy", []).is_empty(), "%s 시설 synergy·결산 지표" % role_id)
	_expect(monsters == {"slime": 2, "goblin": 2, "imp": 2}, "슬라임·고블린·임프 각 두 빌드")


func _test_slime_pair() -> void:
	var context := _context()
	var gate := RoleService.plan_turn("slime_gate_keeper", context, DataRegistry.specializations)
	var rescue := RoleService.plan_turn("slime_rescue_guard", context, DataRegistry.specializations)
	_expect(str(gate.get("movement", {}).get("anchor_node", "")) == "north_gate", "성문 파수는 바리케이드 전선 고정")
	_expect(str(rescue.get("movement", {}).get("anchor_node", "")) == "fallback", "구조 점액은 부상 아군 후퇴선 호위")
	_expect(str(gate.get("target", {}).get("id", "")) == "front_guard" and str(rescue.get("target", {}).get("id", "")) == "fallback_raider", "슬라임 두 역할의 표적 우선순위 분리")
	_expect(str(gate.get("route", {}).get("signature", "")) != str(rescue.get("route", {}).get("signature", "")), "슬라임 두 역할의 이동 경로 분리")
	_expect(int(gate.get("facility_synergy", {}).get("score", 0)) == 2 and int(rescue.get("facility_synergy", {}).get("score", 0)) == 1, "슬라임 시설 synergy 분리")


func _test_goblin_pair() -> void:
	var context := _context()
	var hunter := RoleService.plan_turn("goblin_treasure_hunter", context, DataRegistry.specializations)
	var finisher := RoleService.plan_turn("goblin_finisher", context, DataRegistry.specializations)
	_expect(str(hunter.get("target", {}).get("id", "")) == "thief", "도둑 사냥꾼은 도둑 우선")
	_expect(str(finisher.get("target", {}).get("id", "")) == "wounded_scout", "마무리 칼날은 최저 체력 비율 우선")
	_expect(str(hunter.get("movement", {}).get("anchor_node", "")) == "treasure" and str(finisher.get("movement", {}).get("anchor_node", "")) == "north_cross", "고블린 추격 위치 분리")
	_expect(str(hunter.get("route", {}).get("signature", "")) != str(finisher.get("route", {}).get("signature", "")), "고블린 두 역할의 이동 경로 분리")
	_expect(hunter.get("facility_synergy", {}).get("placement_ids", []) == ["decoy"] and finisher.get("facility_synergy", {}).get("placement_ids", []) == ["barracks"], "고블린 시설 synergy 분리")


func _test_imp_pair() -> void:
	var context := _context()
	var artillery := RoleService.plan_turn("imp_artillery", context, DataRegistry.specializations)
	var trap := RoleService.plan_turn("imp_trap_weaver", context, DataRegistry.specializations)
	_expect(str(artillery.get("target", {}).get("id", "")) == "rear_archer", "장거리 화염술은 위협도 높은 후열 우선")
	_expect(str(trap.get("target", {}).get("id", "")) == "cluster_engineer", "함정 화염술은 밀집 표적 우선")
	_expect(str(artillery.get("movement", {}).get("anchor_node", "")) == "south_cross" and str(trap.get("movement", {}).get("anchor_node", "")) == "south_gate", "임프 후열·함정 anchor 분리")
	_expect(str(artillery.get("route", {}).get("signature", "")) != str(trap.get("route", {}).get("signature", "")), "임프 두 역할의 이동 경로 분리")
	_expect(artillery.get("facility_synergy", {}).get("placement_ids", []) == ["watch"] and trap.get("facility_synergy", {}).get("placement_ids", []) == ["wall"], "임프 시설 synergy 분리")


func _test_focus_command_and_evidence() -> void:
	var context := _context()
	context["focused_target_id"] = "front_guard"
	context["command_id"] = "v20_focus"
	var focused := RoleService.plan_turn("imp_artillery", context, DataRegistry.specializations)
	_expect(str(focused.get("target", {}).get("id", "")) == "front_guard" and str(focused.get("target", {}).get("reason", "")) == "focus_command", "집중 명령이 역할 기본 표적을 명시적으로 덮어씀")
	_expect(is_equal_approx(float(focused.get("command_multiplier", 0.0)), 1.3), "장거리 화염술 집중 명령 affinity 1.3")
	var repeat := RoleService.plan_turn("imp_artillery", context, DataRegistry.specializations)
	_expect(focused == repeat, "동일 입력 역할 계획 deterministic")
	var state := RoleService.new_result_state(ROLE_IDS, DataRegistry.specializations)
	state = RoleService.record_decision(state, "goblin_treasure_hunter")
	var recorded := RoleService.record_metric(state, "goblin_treasure_hunter", "thieves_intercepted", 2.0)
	state = recorded.get("state", {})
	var summary := RoleService.result_summary(state, DataRegistry.specializations)
	var hunter_rows := summary.filter(func(row): return str(row.get("specialization_id", "")) == "goblin_treasure_hunter")
	_expect(bool(recorded.get("ok", false)) and hunter_rows.size() == 1 and int(hunter_rows[0].get("decisions", 0)) == 1 and float(hunter_rows[0].get("metrics", {}).get("thieves_intercepted", 0.0)) == 2.0, "역할 결정·성과 지표 결산")
	_expect(not bool(RoleService.record_metric(state, "goblin_treasure_hunter", "undeclared", 1.0).get("ok", true)), "미선언 역할 지표 거부")


func _context() -> Dictionary:
	return {
		"board": DataRegistry.v20_dungeon_layouts.get("v20_day_01_05_board", {}).duplicate(true),
		"current_node": "entrance",
		"seed": 620,
		"allies": [
			{"id": "slime", "node_id": "north_gate", "hp": 90, "max_hp": 100},
			{"id": "goblin", "node_id": "fallback", "hp": 30, "max_hp": 100},
			{"id": "imp", "node_id": "south_cross", "hp": 80, "max_hp": 100}
		],
		"enemies": [
			{"id": "front_guard", "node_id": "north_gate", "hp": 90, "max_hp": 100, "distance": 4.0, "threat": 4.0, "cluster_size": 1, "tags": ["frontline", "dash"]},
			{"id": "wounded_scout", "node_id": "north_cross", "hp": 15, "max_hp": 100, "distance": 6.0, "threat": 2.0, "cluster_size": 1, "tags": ["wounded"]},
			{"id": "thief", "node_id": "treasure", "hp": 80, "max_hp": 100, "distance": 9.0, "threat": 5.0, "cluster_size": 1, "tags": ["thief", "bait_sensitive"]},
			{"id": "rear_archer", "node_id": "south_cross", "hp": 70, "max_hp": 100, "distance": 8.0, "threat": 8.0, "cluster_size": 2, "tags": ["rear", "support"]},
			{"id": "cluster_engineer", "node_id": "south_gate", "hp": 60, "max_hp": 100, "distance": 7.0, "threat": 6.0, "cluster_size": 4, "tags": ["engineer", "cluster", "frontline"]},
			{"id": "fallback_raider", "node_id": "fallback", "hp": 65, "max_hp": 100, "distance": 10.0, "threat": 9.0, "cluster_size": 1, "tags": ["finisher", "dash"]}
		],
		"facilities": [
			{"id": "wall", "facility_id": "v20_barricade", "node_id": "north_gate", "active": true},
			{"id": "barracks", "facility_id": "v20_barracks", "node_id": "north_cross", "active": true},
			{"id": "decoy", "facility_id": "v20_decoy_treasure", "node_id": "treasure", "active": true},
			{"id": "watch", "facility_id": "v20_watch_post", "node_id": "south_cross", "active": true},
			{"id": "nest", "facility_id": "v20_recovery_nest", "node_id": "fallback", "active": true}
		],
		"hazards": [{"node_id": "south_gate", "active": true}]
	}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20MonsterRoleGrowth] FAIL: %s" % message)
