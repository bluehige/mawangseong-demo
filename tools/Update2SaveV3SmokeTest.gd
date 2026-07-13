extends Node

const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const SaveV3StoreScript = preload("res://scripts/core/CampaignSaveV3Store.gd")

const TEST_V3_PATH := "user://update2_save_v3_smoke_test.json"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveV3StoreScript.delete(TEST_V3_PATH)
	DataRegistry.load_all()
	var v2_envelope := _fixture_v2_envelope()
	_test_migration(v2_envelope)
	_test_safe_store(v2_envelope)
	SaveV3StoreScript.delete(TEST_V3_PATH)
	if failed:
		print("UPDATE2_SAVE_V3_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE2_SAVE_V3_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _fixture_v2_envelope() -> Dictionary:
	var payload := {
		"checkpoint": "management",
		"screen": "management",
		"world": {
			"selected_monster_id": "slime",
			"castle_art_stage": "stage_01_cave",
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
	var inspection := {
		"status": "valid",
		"payload": payload,
		"summary": {"day": 30},
		"saved_at_unix": 1783872000,
		"saved_at_text": "2026-07-13"
	}
	var migration := SaveV1ToV2MigratorScript.migrate_inspection(inspection, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(migration.get("ok", false)), "v3 검사용 저장 v2 구성")
	return migration.get("envelope", {})


func _test_migration(v2_envelope: Dictionary) -> void:
	var migration := SaveV2ToV3MigratorScript.migrate_envelope(v2_envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(migration.get("ok", false)), "저장 v2를 v3로 변환")
	var v3: Dictionary = migration.get("envelope", {})
	_expect(int(v3.get("version", 0)) == 3 and int(v3.get("profile", {}).get("profile_version", 0)) == 2, "저장·프로필 버전 상승")
	_expect(v3.get("active_run", {}).get("legacy_payload", {}) == v2_envelope.get("active_run", {}).get("legacy_payload", {}), "전체 레거시 진행 자료 무손실 보존")
	_expect(v3.get("active_run", {}).get("monsters", {}) == v2_envelope.get("active_run", {}).get("monsters", {}), "몬스터 개체·성장 자료 무손실 보존")
	_expect(v3.get("active_run", {}).get("run_metrics", {}) == v2_envelope.get("active_run", {}).get("run_metrics", {}), "회차 지표 무손실 보존")
	_expect(v3.get("profile", {}).get("ending_archive", {}) == v2_envelope.get("profile", {}).get("ending_archive", {}), "엔딩 도감 무손실 보존")
	_expect(str(v3.get("profile", {}).get("ending_catalog_codes", {}).get("true_demon_castle", "")) == "E00", "기존 기본 엔딩에 E00 코드 부여")
	_expect(v3.get("active_run", {}).get("deployed_instance_ids", []).size() == 3 and v3.get("active_run", {}).get("reserve_instance_ids", []).has("mon_core_rolo"), "Stage 01 출전 3명·원정 지원 로로 예비 배치")
	_expect(int(v3.get("active_run", {}).get("cycle_seed", 0)) > 0, "재현 가능한 양수 회차 seed 생성")
	_expect(SaveV2ToV3MigratorScript.validate_v3(v3, DataRegistry.monster_instances, DataRegistry.run_metric_definitions) == "", "변환된 저장 v3 전체 계약 통과")
	var corrupt: Dictionary = v3.duplicate(true)
	corrupt["active_run"]["reserve_instance_ids"].append(corrupt["active_run"]["deployed_instance_ids"][0])
	_expect(SaveV2ToV3MigratorScript.validate_v3(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions) != "", "출전·예비 중복 개체 거부")


func _test_safe_store(v2_envelope: Dictionary) -> void:
	var migration := SaveV2ToV3MigratorScript.migrate_envelope(v2_envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	var v3: Dictionary = migration.get("envelope", {})
	var write_result := SaveV3StoreScript.write(v3, TEST_V3_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(write_result.get("ok", false)), "저장 v3 임시 파일·재검증·안전 교체 기록")
	var inspection := SaveV3StoreScript.inspect(TEST_V3_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(str(inspection.get("status", "")) == SaveV3StoreScript.STATUS_VALID, "기록한 저장 v3 재검증")
	var original_text := _read_text(TEST_V3_PATH)
	SaveV3StoreScript.delete(TEST_V3_PATH)
	_write_text("%s.tmp" % TEST_V3_PATH, original_text)
	var recovered := SaveV3StoreScript.inspect(TEST_V3_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(str(recovered.get("status", "")) == SaveV3StoreScript.STATUS_VALID and FileAccess.file_exists(TEST_V3_PATH), "중단된 임시 저장 v3 자동 복구")
	var corrupt: Dictionary = v3.duplicate(true)
	corrupt["active_run"]["selected_contract_ids"] = ["a", "b", "c"]
	_expect(not bool(SaveV3StoreScript.write(corrupt, TEST_V3_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions).get("ok", true)), "계약 3종을 담은 손상 v3 덮어쓰기 거부")
	_expect(str(SaveV3StoreScript.inspect(TEST_V3_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions).get("status", "")) == SaveV3StoreScript.STATUS_VALID, "실패한 덮어쓰기 뒤 이전 정상 v3 유지")


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)
	file.close()


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[Update2SaveV3] FAIL: %s" % message)
