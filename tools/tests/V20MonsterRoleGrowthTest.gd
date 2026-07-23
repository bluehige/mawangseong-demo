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
	_test_actual_enemy_catalog_tags()
	if failed:
		print("V20_MONSTER_ROLE_GROWTH_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_MONSTER_ROLE_GROWTH_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_role_contracts() -> void:
	var monster_counts: Dictionary = {}
	for role_id in ROLE_IDS:
		var contract := RoleService.role_contract(role_id, DataRegistry.specializations)
		monster_counts[str(contract.get("monster_id", ""))] = int(monster_counts.get(str(contract.get("monster_id", "")), 0)) + 1
		_expect(not contract.is_empty(), "%s 역할 계약 존재" % role_id)
		_expect(_board().get("nodes", []).has(str(contract.get("movement", {}).get("fallback_node", ""))), "%s fallback_node가 canonical route 안에 존재" % role_id)
		_expect(contract.get("result_metrics", []).size() == 4 and not contract.get("facility_synergy", []).is_empty(), "%s 시설 synergy와 결과 지표 4개 선언" % role_id)
	_expect(monster_counts == {"slime": 2, "goblin": 2, "imp": 2}, "slime·goblin·imp 각각 역할 2개")


func _test_slime_pair() -> void:
	var gate := RoleService.plan_turn("slime_gate_keeper", _context(), DataRegistry.specializations)
	var rescue := RoleService.plan_turn("slime_rescue_guard", _context(), DataRegistry.specializations)
	_expect(str(gate.get("movement", {}).get("anchor_node", "")) == "gate_outpost", "성문 파수는 gate_outpost 시설에 고정")
	_expect(str(rescue.get("movement", {}).get("anchor_node", "")) == "throne_anteroom", "구조 점액은 체력 30% goblin의 throne_anteroom으로 이동")
	_expect(str(gate.get("target", {}).get("id", "")) == "front_guard" and str(rescue.get("target", {}).get("id", "")) == "rear_raider", "두 slime 역할이 서로 다른 적 선택")
	_expect(gate.get("route", {}).get("nodes", []) == ["gate_outpost"] and rescue.get("route", {}).get("nodes", []) == ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom"], "두 slime 역할의 실제 이동 경로 분리")
	_expect(int(gate.get("facility_synergy", {}).get("score", 0)) == 2 and int(rescue.get("facility_synergy", {}).get("score", 0)) == 1, "성문 파수 synergy 2·구조 점액 synergy 1")


func _test_goblin_pair() -> void:
	var hunter := RoleService.plan_turn("goblin_treasure_hunter", _context(), DataRegistry.specializations)
	var finisher := RoleService.plan_turn("goblin_finisher", _context(), DataRegistry.specializations)
	_expect(str(hunter.get("target", {}).get("id", "")) == "thief", "도둑 사냥꾼은 thief 선택")
	_expect(str(finisher.get("target", {}).get("id", "")) == "wounded_scout", "마무리 칼날은 HP 15% wounded_scout 선택")
	_expect(str(hunter.get("movement", {}).get("anchor_node", "")) == "central_battle_room" and str(finisher.get("movement", {}).get("anchor_node", "")) == "spike_corridor", "두 goblin 역할의 목표 구역 분리")
	_expect(str(hunter.get("route", {}).get("signature", "")) != str(finisher.get("route", {}).get("signature", "")), "두 goblin 역할의 이동 경로 signature 분리")
	_expect(hunter.get("facility_synergy", {}).get("placement_ids", []) == ["decoy"] and finisher.get("facility_synergy", {}).get("placement_ids", []) == ["barracks"], "도둑 사냥꾼은 미끼·마무리 칼날은 병영 synergy")


func _test_imp_pair() -> void:
	var artillery := RoleService.plan_turn("imp_artillery", _context(), DataRegistry.specializations)
	var trap := RoleService.plan_turn("imp_trap_weaver", _context(), DataRegistry.specializations)
	_expect(str(artillery.get("target", {}).get("id", "")) == "rear_archer", "장거리 화염술은 rear_archer 선택")
	_expect(str(trap.get("target", {}).get("id", "")) == "cluster_engineer", "함정 화염술은 cluster_engineer 선택")
	_expect(str(artillery.get("movement", {}).get("anchor_node", "")) == "throne_anteroom" and str(trap.get("movement", {}).get("anchor_node", "")) == "spike_corridor", "두 imp 역할의 목표 구역 분리")
	_expect(str(artillery.get("route", {}).get("signature", "")) != str(trap.get("route", {}).get("signature", "")), "두 imp 역할의 이동 경로 signature 분리")
	_expect(artillery.get("facility_synergy", {}).get("placement_ids", []) == ["watch"] and trap.get("facility_synergy", {}).get("placement_ids", []) == ["wall"], "장거리 화염술은 감시 초소·함정 화염술은 바리케이드 synergy")


func _test_focus_command_and_evidence() -> void:
	var context := _context()
	context["focused_target_id"] = "front_guard"
	context["command_id"] = "v20_focus"
	var focused := RoleService.plan_turn("imp_artillery", context, DataRegistry.specializations)
	_expect(str(focused.get("target", {}).get("id", "")) == "front_guard" and str(focused.get("target", {}).get("reason", "")) == "focus_command", "집중 명령이 기본 표적을 front_guard로 교체")
	_expect(is_equal_approx(float(focused.get("command_multiplier", 0.0)), 1.3), "장거리 화염술 집중 명령 배율 1.3")
	_expect(focused == RoleService.plan_turn("imp_artillery", context, DataRegistry.specializations), "같은 입력 역할 계획 deterministic")
	var state := RoleService.new_result_state(ROLE_IDS, DataRegistry.specializations)
	state = RoleService.record_decision(state, "goblin_treasure_hunter")
	var recorded := RoleService.record_metric(state, "goblin_treasure_hunter", "thieves_intercepted", 2.0)
	var rows := RoleService.result_summary(recorded.get("state", {}), DataRegistry.specializations).filter(func(row): return str(row.get("specialization_id", "")) == "goblin_treasure_hunter")
	_expect(bool(recorded.get("ok", false)) and rows.size() == 1 and int(rows[0].get("decisions", 0)) == 1 and float(rows[0].get("metrics", {}).get("thieves_intercepted", 0.0)) == 2.0, "역할 결정 1회와 도둑 차단 2회 결과 기록")


func _test_actual_enemy_catalog_tags() -> void:
	var expected := {
		"explorer": ["frontline", "cluster"],
		"thief": ["thief", "bait_sensitive"],
		"engineer": ["engineer", "support"],
		"shieldbearer": ["frontline", "protector"],
		"anti_magic_archer": ["rear", "protected_rear"],
		"trainee_hero": ["dash", "finisher"]
	}
	for enemy_id_value in expected.keys():
		var enemy_id := str(enemy_id_value)
		var tags: Array = DataRegistry.enemy(enemy_id).get("tags", [])
		_expect(expected[enemy_id].all(func(tag): return tags.has(tag)), "%s 실제 catalog tag가 역할 우선순위 계약과 일치" % enemy_id)
	var context := _context()
	context["enemies"][3]["targetable"] = false
	var protected_archer := RoleService.plan_turn("imp_artillery", context, DataRegistry.specializations)
	_expect(str(protected_archer.get("target", {}).get("id", "")) != "rear_archer", "보호 중 targetable=false 궁수는 역할 표적에서 제외")
	context["enemies"][3]["targetable"] = true
	var revealed_archer := RoleService.plan_turn("imp_artillery", context, DataRegistry.specializations)
	_expect(str(revealed_archer.get("target", {}).get("id", "")) == "rear_archer", "감시·집중으로 targetable=true가 된 궁수는 실제 표적 복귀")


func _context() -> Dictionary:
	return {
		"board": _board(),
		"current_node": "gate_outpost",
		"seed": 620,
		"allies": [
			{"id": "slime", "node_id": "gate_outpost", "hp": 90, "max_hp": 100},
			{"id": "goblin", "node_id": "throne_anteroom", "hp": 30, "max_hp": 100},
			{"id": "imp", "node_id": "central_battle_room", "hp": 80, "max_hp": 100}
		],
		"enemies": [
			{"id": "front_guard", "node_id": "gate_outpost", "hp": 90, "max_hp": 100, "distance": 4.0, "threat": 4.0, "cluster_size": 1, "tags": ["frontline", "dash"]},
			{"id": "wounded_scout", "node_id": "spike_corridor", "hp": 15, "max_hp": 100, "distance": 6.0, "threat": 2.0, "cluster_size": 1, "tags": ["wounded"]},
			{"id": "thief", "node_id": "central_battle_room", "hp": 80, "max_hp": 100, "distance": 9.0, "threat": 5.0, "cluster_size": 1, "tags": ["thief", "bait_sensitive"]},
			{"id": "rear_archer", "node_id": "throne_anteroom", "hp": 70, "max_hp": 100, "distance": 8.0, "threat": 8.0, "cluster_size": 2, "tags": ["rear", "support"]},
			{"id": "cluster_engineer", "node_id": "spike_corridor", "hp": 60, "max_hp": 100, "distance": 7.0, "threat": 6.0, "cluster_size": 4, "tags": ["engineer", "cluster", "frontline"]},
			{"id": "rear_raider", "node_id": "throne_anteroom", "hp": 65, "max_hp": 100, "distance": 10.0, "threat": 9.0, "cluster_size": 1, "tags": ["finisher", "dash"]}
		],
		"facilities": [
			{"id": "wall", "facility_id": "v20_barricade", "node_id": "gate_outpost", "active": true},
			{"id": "barracks", "facility_id": "v20_barracks", "node_id": "central_battle_room", "active": true},
			{"id": "decoy", "facility_id": "v20_decoy_treasure", "node_id": "central_battle_room", "active": true},
			{"id": "watch", "facility_id": "v20_watch_post", "node_id": "throne_anteroom", "active": true},
			{"id": "nest", "facility_id": "v20_recovery_nest", "node_id": "throne_anteroom", "active": true}
		],
		"hazards": [{"node_id": "spike_corridor", "active": true}]
	}


func _board() -> Dictionary:
	return DataRegistry.v20_dungeon_layouts.get("v20_day_01_05_board", {}).duplicate(true)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20MonsterRoleGrowth] FAIL: %s" % message)
