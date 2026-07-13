extends Node

const MonsterInstanceValidatorScript = preload("res://scripts/systems/monsters/MonsterInstanceValidator.gd")
const EndingConditionEvaluatorScript = preload("res://scripts/systems/endings/EndingConditionEvaluator.gd")
const RunMetricsTrackerScript = preload("res://scripts/systems/endings/RunMetricsTracker.gd")
const SaveMigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2StoreScript = preload("res://scripts/core/CampaignSaveV2Store.gd")
const NewCycleServiceScript = preload("res://scripts/systems/legacy/NewCycleService.gd")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")

const TEST_V2_PATH := "user://monster_legacy_systems_v2_test.json"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveV2StoreScript.delete(TEST_V2_PATH)
	DataRegistry.load_all()
	_test_data_contracts()
	_test_metrics_and_endings()
	_test_v1_to_v2_migration()
	_test_new_cycle_profile()
	SaveV2StoreScript.delete(TEST_V2_PATH)
	if failed:
		print("MONSTER_LEGACY_SYSTEMS_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("MONSTER_LEGACY_SYSTEMS_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_data_contracts() -> void:
	var instance_errors := MonsterInstanceValidatorScript.validate_catalog(DataRegistry.monster_instances, DataRegistry.monsters, DataRegistry.characters, DataRegistry.skills, DataRegistry.evolution_rules)
	_expect(instance_errors.is_empty(), "핵심 몬스터 4명의 개체 데이터 계약 통과: %s" % [instance_errors])
	var ending_errors := EndingConditionEvaluatorScript.validate_rules(DataRegistry.ending_rules, DataRegistry.run_metric_definitions)
	_expect(ending_errors.is_empty(), "엔딩 5개의 조건식과 지표 참조 계약 통과: %s" % [ending_errors])
	var evolution_counts := {"slime": 0, "goblin": 0, "imp": 0}
	for evolution_value in DataRegistry.evolution_rules.values():
		if evolution_value is Dictionary and evolution_counts.has(str(evolution_value.get("monster_id", ""))):
			evolution_counts[str(evolution_value.get("monster_id", ""))] += 1
	_expect(int(evolution_counts.get("slime", 0)) == 2 and int(evolution_counts.get("goblin", 0)) == 2 and int(evolution_counts.get("imp", 0)) == 2, "푸딩·곱·핀의 2갈래 진화 데이터 구성")
	var broken_rules: Dictionary = DataRegistry.ending_rules.duplicate(true)
	broken_rules["monster_family_castle"]["requirements"] = {"metric": "unknown.metric", "op": ">=", "value": 1}
	_expect(not EndingConditionEvaluatorScript.validate_rules(broken_rules, DataRegistry.run_metric_definitions).is_empty(), "알 수 없는 엔딩 지표 거부")


func _test_metrics_and_endings() -> void:
	var tracker = RunMetricsTrackerScript.new()
	_expect(tracker.setup(DataRegistry.run_metric_definitions).is_empty(), "회차 지표 기본값 구성")
	_expect(tracker.add("style.family", 70), "숫자 지표 누적")
	_expect(tracker.set_value("bond.core_average", 80), "숫자 지표 설정")
	_expect(tracker.set_value("bond.high_rank_count", 3), "고유대 몬스터 수 설정")
	var family_result := EndingConditionEvaluatorScript.resolve(DataRegistry.ending_rules, tracker.snapshot())
	_expect(bool(family_result.get("ok", false)) and str(family_result.get("ending_id", "")) == "monster_family_castle", "몬스터 식구 엔딩 결정")
	var fortress_tracker = RunMetricsTrackerScript.new()
	fortress_tracker.setup(DataRegistry.run_metric_definitions)
	fortress_tracker.set_value("castle.throne_hp_ratio", 0.9)
	fortress_tracker.set_value("castle.security_score", 85)
	fortress_tracker.set_value("style.fortress", 75)
	_expect(str(EndingConditionEvaluatorScript.resolve(DataRegistry.ending_rules, fortress_tracker.snapshot()).get("ending_id", "")) == "impregnable_demon_citadel", "철벽 요새 엔딩 결정")
	var dread_tracker = RunMetricsTrackerScript.new()
	dread_tracker.setup(DataRegistry.run_metric_definitions)
	dread_tracker.set_value("infamy.final", 1600)
	dread_tracker.set_value("raid.high_risk_successes", 3)
	dread_tracker.set_value("style.dread", 75)
	_expect(str(EndingConditionEvaluatorScript.resolve(DataRegistry.ending_rules, dread_tracker.snapshot()).get("ending_id", "")) == "dread_overlord_rises", "공포의 대마왕 엔딩 결정")
	var rival_tracker = RunMetricsTrackerScript.new()
	rival_tracker.setup(DataRegistry.run_metric_definitions)
	rival_tracker.set_value("relation.leon", 75)
	rival_tracker.set_value("style.honor", 70)
	rival_tracker.set_value("decision.day29", "rival_pact")
	_expect(str(EndingConditionEvaluatorScript.resolve(DataRegistry.ending_rules, rival_tracker.snapshot()).get("ending_id", "")) == "demon_hero_rival_pact", "레온 라이벌 협정 엔딩 결정")
	var default_tracker = RunMetricsTrackerScript.new()
	default_tracker.setup(DataRegistry.run_metric_definitions)
	var default_result := EndingConditionEvaluatorScript.resolve(DataRegistry.ending_rules, default_tracker.snapshot())
	_expect(str(default_result.get("ending_id", "")) == "true_demon_castle", "조건 미달 시 기존 기본 엔딩 유지")
	_expect(not tracker.set_value("style.family", "잘못된 값"), "지표 자료형 변조 거부")
	var restored = RunMetricsTrackerScript.new()
	restored.setup(DataRegistry.run_metric_definitions)
	_expect(restored.restore(tracker.snapshot()).is_empty() and restored.snapshot() == tracker.snapshot(), "회차 지표 저장 왕복")
	var metrics_root = GameRootScript.new()
	metrics_root._reset_run_metrics()
	metrics_root.treasure_gold_stolen_this_battle = 80
	metrics_root.facility_disables_this_battle = 1
	metrics_root._record_battle_run_metrics()
	metrics_root.treasure_gold_stolen_this_battle = 20
	metrics_root.facility_disables_this_battle = 2
	metrics_root._record_battle_run_metrics()
	metrics_root._record_directive_use("all_out")
	metrics_root._record_directive_use("all_out")
	var runtime_metrics: Dictionary = metrics_root.run_metrics_tracker.snapshot()
	_expect(int(runtime_metrics.get("castle.treasure_lost", 0)) == 100 and int(runtime_metrics.get("castle.facility_disables", 0)) == 3, "여러 전투의 약탈·시설 무력화 지표 누적")
	_expect(runtime_metrics.get("directive.used_ids", []).count("all_out") == 1 and runtime_metrics.get("directive.used_ids", []).has("defense"), "회차 전체 지침 종류를 중복 없이 기록")
	metrics_root.free()


func _test_v1_to_v2_migration() -> void:
	var payload := {
		"checkpoint": "management",
		"screen": "management",
		"world": {
			"selected_monster_id": "slime",
			"monster_roster": {
				"slime": {"level": 7, "exp": 23, "room": "barracks", "specialization_id": "slime_gate_keeper", "promotion_id": "slime_gate_bulwark"},
				"goblin": {"level": 5, "exp": 9, "room": "barracks", "specialization_id": "goblin_treasure_hunter", "promotion_id": ""},
				"imp": {"level": 6, "exp": 14, "room": "recovery", "specialization_id": "imp_artillery", "promotion_id": "imp_flame_adept"},
				"kobold_scout": {"level": 4, "exp": 3, "room": "barracks", "specialization_id": "", "promotion_id": "", "raid_support": true}
			}
		},
		"raid": {"selected_monster_ids": ["kobold_scout"]},
		"campaign": {"completed": true, "final_battle_outcome": "victory"},
		"result": {"growth_choice_monster_id": "slime", "last_growth_choice_summary": {"monster_id": "slime"}, "last_growth_summary": [{"monster_id": "imp"}]},
		"game_state": {},
		"onboarding": {}
	}
	var inspection := {"status": "valid", "payload": payload, "summary": {"day": 30}, "saved_at_unix": 1234, "saved_at_text": "2026-07-12"}
	var migration := SaveMigratorScript.migrate_inspection(inspection, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(migration.get("ok", false)), "저장 v1을 v2로 변환")
	var envelope: Dictionary = migration.get("envelope", {})
	var active_run: Dictionary = envelope.get("active_run", {})
	var monsters: Dictionary = active_run.get("monsters", {})
	_expect(int(monsters.get("mon_core_pudding", {}).get("level", 0)) == 7, "푸딩 레벨·성장 자료 보존")
	_expect(str(monsters.get("mon_core_pudding", {}).get("evolution_id", "")) == "slime_gate_bulwark", "기존 승급을 진화 ID로 보존")
	_expect(str(active_run.get("legacy_payload", {}).get("world", {}).get("selected_monster_id", "")) == "mon_core_pudding", "선택 몬스터 참조를 개체 ID로 변환")
	_expect(str(active_run.get("legacy_payload", {}).get("raid", {}).get("selected_monster_ids", [""])[0]) == "mon_core_rolo", "원정 편성 참조를 개체 ID로 변환")
	_expect(envelope.get("profile", {}).get("ending_archive", {}).has("true_demon_castle"), "완료한 v1의 기본 엔딩을 프로필 도감에 보존")
	_expect(SaveMigratorScript.validate_v2(envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions) == "", "변환된 저장 v2 전체 계약 통과")
	var write_result := SaveV2StoreScript.write(envelope, TEST_V2_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(write_result.get("ok", false)), "저장 v2를 임시 파일·재검증·안전 교체 방식으로 기록")
	var v2_inspection := SaveV2StoreScript.inspect(TEST_V2_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(str(v2_inspection.get("status", "")) == SaveV2StoreScript.STATUS_VALID, "기록한 저장 v2를 다시 읽어 검증")
	var corrupt_envelope: Dictionary = envelope.duplicate(true)
	corrupt_envelope["active_run"]["run_metrics"].erase("style.family")
	_expect(not bool(SaveV2StoreScript.write(corrupt_envelope, TEST_V2_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions).get("ok", true)), "필수 지표가 빠진 저장 v2 덮어쓰기 거부")
	_expect(str(SaveV2StoreScript.inspect(TEST_V2_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions).get("status", "")) == SaveV2StoreScript.STATUS_VALID, "실패한 덮어쓰기 뒤 이전 정상 v2 유지")
	var unsupported := inspection.duplicate(true)
	unsupported["status"] = "unsupported"
	_expect(not bool(SaveMigratorScript.migrate_inspection(unsupported, DataRegistry.monster_instances, DataRegistry.run_metric_definitions).get("ok", true)), "유효하지 않은 v1 검사 결과 변환 거부")


func _test_new_cycle_profile() -> void:
	var candidate := {"species_id": "slime", "display_name": "푸딩", "level": 8, "specialization_id": "slime_gate_keeper", "promotion_id": "slime_gate_bulwark"}
	var profile := NewCycleServiceScript.complete_cycle(NewCycleServiceScript.default_profile(), "monster_family_castle", {"bond.core_average": 82.0}, candidate)
	_expect(int(profile.get("completed_cycles", 0)) == 1, "첫 회차 완료를 프로필에 누적")
	_expect(int(profile.get("ending_archive", {}).get("monster_family_castle", {}).get("seen_count", 0)) == 1, "선택된 엔딩을 도감에 기록")
	var fresh_roster := {"slime": {"level": 1, "exp": 0, "promotion_id": ""}}
	var inherited := NewCycleServiceScript.apply_legacy_memory(fresh_roster, profile.get("legacy_monster", {}))
	_expect(inherited and int(fresh_roster.get("slime", {}).get("level", 0)) == 1 and str(fresh_roster.get("slime", {}).get("promotion_id", "")) == "" and fresh_roster.get("slime", {}).get("unlocked_memory_ids", []).size() == 1, "다음 회차는 레벨·진화를 초기화하고 기억 1개만 계승")
	profile = NewCycleServiceScript.complete_cycle(profile, "impregnable_demon_citadel", {}, candidate)
	_expect(int(profile.get("completed_cycles", 0)) == 2 and profile.get("ending_archive", {}).has("impregnable_demon_citadel"), "두 번째 회차와 새 엔딩을 누적")


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[MonsterLegacySystems] FAIL: %s" % message)
