extends Node

const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const SaveV3ToV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")
const SaveV4StoreScript = preload("res://scripts/systems/save/CampaignSaveV4Store.gd")
const MigratorScript = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd")
const SaveV5StoreScript = preload("res://scripts/systems/save/CampaignSaveV5Store.gd")

const TEST_V4_PATH := "user://update4_phase2_v4.json"
const TEST_V5_PATH := "user://update4_phase2_v5.json"
const CORRUPT_V5_PATH := "user://update4_phase2_corrupt_v5.json"
const UNSUPPORTED_V5_PATH := "user://update4_phase2_unsupported_v5.json"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_cleanup()
	var base_v4 := _base_v4_fixture()
	_test_v4_migration_fixtures(base_v4)
	_test_council_fixture_and_validation(base_v4)
	_test_safe_store_recovery(base_v4)
	_cleanup()
	if failed:
		print("SAVE_V5_MIGRATION_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("SAVE_V5_MIGRATION_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _base_v4_fixture() -> Dictionary:
	var payload := {
		"checkpoint": "management", "screen": "management",
		"world": {"selected_monster_id": "slime", "castle_art_stage": "stage_01_cave", "monster_roster": {"slime": {"level": 7}, "goblin": {"level": 5}, "imp": {"level": 6}}},
		"raid": {"selected_monster_ids": []},
		"campaign": {"completed": false, "final_battle_outcome": "", "postgame_active": false},
		"result": {}, "game_state": {"day": 10}, "onboarding": {}, "update2": {}
	}
	var v2 := SaveV1ToV2MigratorScript.migrate_inspection({"status": "valid", "payload": payload, "summary": {"day": 10}, "saved_at_unix": 1783872000}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v2.get("ok", false)), "Phase 2 검사용 저장 v2 구성")
	var v3 := SaveV2ToV3MigratorScript.migrate_envelope(v2.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v3.get("ok", false)), "Phase 2 검사용 저장 v3 구성")
	var v4 := SaveV3ToV4MigratorScript.migrate_envelope(v3.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
	_expect(bool(v4.get("ok", false)), "Phase 2 검사용 저장 v4 구성")
	var envelope: Dictionary = v4.get("envelope", {})
	envelope["profile"]["fronts"]["clear_counts"] = {"front_hero_oath": 1}
	envelope["profile"]["update3_endings_seen"] = ["E16"]
	return envelope


func _test_v4_migration_fixtures(base_v4: Dictionary) -> void:
	var fixtures := [
		{"label": "DAY 10 진행", "day": 10, "screen": "management", "completed": false, "postgame": false},
		{"label": "DAY 20 진행", "day": 20, "screen": "management", "completed": false, "postgame": false},
		{"label": "DAY 29 진행", "day": 29, "screen": "management", "completed": false, "postgame": false},
		{"label": "DAY 30 엔딩", "day": 30, "screen": "ending", "completed": true, "postgame": false},
		{"label": "DAY 30 후일담", "day": 30, "screen": "management", "completed": true, "postgame": true}
	]
	for fixture in fixtures:
		var v4 := base_v4.duplicate(true)
		v4["active_run"]["legacy_payload"]["game_state"]["day"] = fixture["day"]
		v4["active_run"]["legacy_payload"]["screen"] = fixture["screen"]
		v4["active_run"]["legacy_payload"]["checkpoint"] = fixture["screen"]
		v4["active_run"]["legacy_payload"]["campaign"]["completed"] = fixture["completed"]
		v4["active_run"]["legacy_payload"]["campaign"]["postgame_active"] = fixture["postgame"]
		v4["active_run"]["legacy_payload"]["campaign"]["final_battle_outcome"] = "victory" if fixture["completed"] else ""
		var migration := MigratorScript.migrate_envelope(v4, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
		_expect(bool(migration.get("ok", false)), "%s v4→v5 무손실 변환: %s" % [fixture["label"], migration.get("error", "")])
		var v5: Dictionary = migration.get("envelope", {})
		_expect(int(v5.get("version", 0)) == 5 and int(v5.get("profile", {}).get("profile_version", 0)) == 4, "%s 저장·프로필 버전 승격" % fixture["label"])
		_expect(str(v5.get("active_run", {}).get("campaign_mode_id", "")) == MigratorScript.MODE_LEGACY_V4 and v5.get("active_run", {}).get("council_season", {}).get("selected_regions", []).is_empty(), "%s 레거시 완주·Update 4 미삽입" % fixture["label"])
		_expect(v5.get("profile", {}).get("fronts", {}) == v4.get("profile", {}).get("fronts", {}) and v5.get("profile", {}).get("ending_archive", {}) == v4.get("profile", {}).get("ending_archive", {}), "%s 기존 프로필 보존" % fixture["label"])


func _test_council_fixture_and_validation(base_v4: Dictionary) -> void:
	var migration := MigratorScript.migrate_envelope(base_v4, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
	var v5: Dictionary = migration.get("envelope", {})
	_expect(bool(v5.get("profile", {}).get("campaign_modes", {}).get("council_season_unlocked", false)) and bool(v5.get("profile", {}).get("campaign_modes", {}).get("open_council_rule", false)), "기존 3차 클리어·E16에서 의회·고급 규칙 해금 계산")
	var council := v5.duplicate(true)
	council["active_run"] = MigratorScript.fresh_update4_active_run(MigratorScript.MODE_COUNCIL_SEASON, 3, 40404, base_v4.get("active_run", {}))
	council["active_run"]["legacy_payload"]["game_state"]["day"] = 4
	var council_error := MigratorScript.validate_v5(council, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
	_expect(council_error == "", "의회 DAY 4 지역 선택 전 fixture 유효: %s" % council_error)
	council["active_run"]["council_season"]["selected_regions"] = ["region_ash", "region_mist", "region_mire"]
	council["active_run"]["council_season"]["current_region_index"] = 0
	council_error = MigratorScript.validate_v5(council, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
	_expect(council_error == "", "의회 DAY 4 지역 선택 후 fixture 유효: %s" % council_error)
	var corrupt := council.duplicate(true)
	corrupt["active_run"]["council_season"]["selected_regions"] = ["region_ash", "region_ash"]
	_expect(MigratorScript.validate_v5(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs()).contains("중복 없는"), "중복 지역 거부")
	corrupt = council.duplicate(true)
	corrupt["active_run"]["upper_floor"]["unlocked"] = true
	_expect(MigratorScript.validate_v5(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs()).contains("DAY 16"), "DAY 16 이전 상층 해금 거부")
	corrupt = council.duplicate(true)
	corrupt["active_run"]["council_season"]["rival_relations"]["rival_brassa"] = 101
	_expect(MigratorScript.validate_v5(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs()).contains("-100~100"), "경쟁 마왕 관계 범위 검증")
	corrupt = v5.duplicate(true)
	corrupt["active_run"]["outpost"]["type_id"] = "outpost_watch"
	_expect(MigratorScript.validate_v5(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs()).contains("레거시"), "진행 중 v4 회차 Update 4 상태 삽입 거부")


func _test_safe_store_recovery(base_v4: Dictionary) -> void:
	var migration := MigratorScript.migrate_envelope(base_v4, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
	var v5: Dictionary = migration.get("envelope", {})
	_expect(bool(SaveV5StoreScript.write(v5, TEST_V5_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs()).get("ok", false)), "v5 임시 기록·재검증·안전 교체")
	var first := SaveV5StoreScript.inspect(TEST_V5_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
	var second := SaveV5StoreScript.inspect(TEST_V5_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
	_expect(str(first.get("status", "")) == SaveV5StoreScript.STATUS_VALID and first.get("envelope", {}) == second.get("envelope", {}), "v5 반복 복원 멱등성")
	var text := FileAccess.get_file_as_string(TEST_V5_PATH)
	SaveV5StoreScript.delete(TEST_V5_PATH)
	_write_text("%s.tmp" % TEST_V5_PATH, text)
	_expect(str(SaveV5StoreScript.inspect(TEST_V5_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs()).get("status", "")) == SaveV5StoreScript.STATUS_VALID and FileAccess.file_exists(TEST_V5_PATH), "중단된 v5 tmp 자동 복구")
	_expect(bool(SaveV4StoreScript.write(base_v4, TEST_V4_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs()).get("ok", false)), "v4 원본 파일 기록")
	_expect(bool(SaveV5StoreScript.migrate_v4_file(TEST_V4_PATH, TEST_V5_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs()).get("ok", false)) and FileAccess.file_exists(TEST_V4_PATH), "v4 원본 보존 상태로 v5 변환")
	_write_text(CORRUPT_V5_PATH, "{}")
	var corrupt_inspection := SaveV5StoreScript.inspect(CORRUPT_V5_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
	_expect(str(corrupt_inspection.get("status", "")) == SaveV5StoreScript.STATUS_CORRUPT and FileAccess.file_exists("%s.corrupt" % CORRUPT_V5_PATH), "손상 v5 격리")
	var unsupported := v5.duplicate(true)
	unsupported["version"] = 6
	_write_text(UNSUPPORTED_V5_PATH, JSON.stringify(unsupported))
	var unsupported_inspection := SaveV5StoreScript.inspect(UNSUPPORTED_V5_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
	_expect(str(unsupported_inspection.get("status", "")) == SaveV5StoreScript.STATUS_UNSUPPORTED and FileAccess.file_exists(UNSUPPORTED_V5_PATH), "미지원 버전은 격리하지 않고 차단")


func _update3_catalogs() -> Dictionary:
	return {
		"fronts": {"front_hero_oath": {"final_rival_id": "leon"}},
		"castle_hearts": {"heart_stonebone": {}, "heart_hungry_maw": {}, "heart_dream_lantern": {}},
		"duo_links": {}, "rival_finales": {}
	}


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


func _cleanup() -> void:
	SaveV4StoreScript.delete(TEST_V4_PATH)
	SaveV5StoreScript.delete(TEST_V5_PATH)
	SaveV5StoreScript.delete(CORRUPT_V5_PATH)
	SaveV5StoreScript.delete(UNSUPPORTED_V5_PATH)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[SaveV5Migration] FAIL: %s" % message)
