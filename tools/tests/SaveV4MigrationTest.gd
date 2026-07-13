extends Node

const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const SaveV3StoreScript = preload("res://scripts/core/CampaignSaveV3Store.gd")
const MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")
const SaveV4StoreScript = preload("res://scripts/systems/save/CampaignSaveV4Store.gd")

const TEST_V3_PATH := "user://update3_phase2_v3.json"
const TEST_V4_PATH := "user://update3_phase2_v4.json"
const CORRUPT_V4_PATH := "user://update3_phase2_corrupt_v4.json"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_cleanup()
	var base_v3 := _base_v3_fixture()
	_test_five_v3_migrations(base_v3)
	_test_v4_validation_and_reset(base_v3)
	_test_safe_store_recovery_and_quarantine(base_v3)
	_cleanup()
	if failed:
		print("SAVE_V4_MIGRATION_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("SAVE_V4_MIGRATION_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _base_v3_fixture() -> Dictionary:
	var payload := {
		"checkpoint": "management",
		"screen": "management",
		"world": {"selected_monster_id": "slime", "castle_art_stage": "stage_01_cave", "monster_roster": {"slime": {"level": 7}, "goblin": {"level": 5}, "imp": {"level": 6}}},
		"raid": {"selected_monster_ids": []},
		"campaign": {"completed": false, "final_battle_outcome": "", "postgame_active": false},
		"result": {},
		"game_state": {"day": 14},
		"onboarding": {},
		"update2": {}
	}
	var v2_result := SaveV1ToV2MigratorScript.migrate_inspection({"status": "valid", "payload": payload, "summary": {"day": 14}, "saved_at_unix": 1783872000}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v2_result.get("ok", false)), "Phase 2 검사용 저장 v2 구성")
	var v3_result := SaveV2ToV3MigratorScript.migrate_envelope(v2_result.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v3_result.get("ok", false)), "Phase 2 검사용 저장 v3 구성")
	var v3: Dictionary = v3_result.get("envelope", {})
	v3["profile"]["ending_archive"] = {"true_demon_castle": {"seen_count": 1}}
	v3["profile"]["ending_catalog_codes"] = {"true_demon_castle": "E00"}
	v3["profile"]["unlocked_memory_ids"] = ["legacy_mon_core_pudding_cycle_1"]
	v3["profile"]["unlocked_contract_ids"] = ["spore_healer", "stone_sentinel"]
	v3["profile"]["contract_history"] = [{"cycle": 1, "ids": ["spore_healer", "stone_sentinel"]}]
	return v3


func _test_five_v3_migrations(base_v3: Dictionary) -> void:
	var fixtures := [
		{"label": "정상 profile", "day": 4, "screen": "management", "completed": false, "postgame": false},
		{"label": "진행 중 DAY 14", "day": 14, "screen": "management", "completed": false, "postgame": false},
		{"label": "진행 중 DAY 29", "day": 29, "screen": "management", "completed": false, "postgame": false},
		{"label": "v3 엔딩", "day": 30, "screen": "ending", "completed": true, "postgame": false},
		{"label": "v3 완료 후일담", "day": 30, "screen": "management", "completed": true, "postgame": true}
	]
	for fixture in fixtures:
		var v3 := base_v3.duplicate(true)
		var legacy: Dictionary = v3["active_run"]["legacy_payload"]
		legacy["game_state"]["day"] = fixture["day"]
		legacy["screen"] = fixture["screen"]
		legacy["checkpoint"] = fixture["screen"]
		legacy["campaign"]["completed"] = fixture["completed"]
		legacy["campaign"]["final_battle_outcome"] = "victory" if fixture["completed"] else ""
		legacy["campaign"]["postgame_active"] = fixture["postgame"]
		var migration := MigratorScript.migrate_envelope(v3, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs())
		_expect(bool(migration.get("ok", false)), "%s v3→v4 무손실 변환: %s" % [fixture["label"], migration.get("error", "")])
		var v4: Dictionary = migration.get("envelope", {})
		_expect(int(v4.get("version", 0)) == 4 and int(v4.get("profile", {}).get("profile_version", 0)) == 3, "%s 저장·프로필 버전 상승" % fixture["label"])
		_expect(v4.get("profile", {}).get("ending_archive", {}) == v3.get("profile", {}).get("ending_archive", {}) and v4.get("profile", {}).get("unlocked_contract_ids", []) == v3.get("profile", {}).get("unlocked_contract_ids", []) and v4.get("profile", {}).get("unlocked_memory_ids", []) == v3.get("profile", {}).get("unlocked_memory_ids", []), "%s 기존 엔딩·계약·추억 보존" % fixture["label"])
		_expect(not bool(v4.get("active_run", {}).get("update3_enabled", true)) and str(v4.get("active_run", {}).get("front_id", "")) == MigratorScript.LEGACY_FRONT_ID and str(v4.get("active_run", {}).get("heart", {}).get("heart_id", "")) == "", "%s 레거시 회차에 3차 콘텐츠 미삽입" % fixture["label"])


func _test_v4_validation_and_reset(base_v3: Dictionary) -> void:
	var migration := MigratorScript.migrate_envelope(base_v3, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs())
	var v4: Dictionary = migration.get("envelope", {})
	_expect(v4.get("profile", {}).get("fronts", {}).get("unlocked", []) == ["front_hero_oath"], "레온 전선만 기본 해금")
	_expect(v4.get("profile", {}).get("hearts", {}).get("unlocked", []).size() == 3 and v4.get("profile", {}).get("duo_links", {}).get("unlocked", []).is_empty(), "심장 3종 기본 해금·합동 기억 자동 해금 금지")
	_expect(bool(v4.get("profile", {}).get("fronts", {}).get("invitation_pending", false)), "대체 전선 첫 진입 초대 선택 플래그")

	var reset := MigratorScript.reset_active_run_for_new_cycle(v4, 3, 30303)
	_expect(reset.get("profile", {}) == v4.get("profile", {}), "새 회차 초기화에서 profile 영구 진행 보존")
	_expect(bool(reset.get("active_run", {}).get("new_cycle_selection_pending", false)) and str(reset.get("active_run", {}).get("front_id", "")) == "" and int(reset.get("active_run", {}).get("cycle_index", 0)) == 3, "새 회차 active_run만 선택 대기 상태로 초기화")
	_expect(MigratorScript.validate_v4(reset, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()) == "", "profile 유지·active_run 초기화 저장 v4 유효")

	var enabled := v4.duplicate(true)
	enabled["active_run"]["update3_enabled"] = true
	enabled["active_run"]["new_cycle_selection_pending"] = false
	enabled["active_run"]["front_id"] = "front_hero_oath"
	enabled["active_run"]["heart"]["heart_id"] = "heart_stonebone"
	enabled["active_run"]["rival_finale"]["rival_id"] = "leon"
	_expect(MigratorScript.validate_v4(enabled, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()) == "", "선택 완료된 Stage 01 3차 회차 저장 유효")

	var duo_enabled := enabled.duplicate(true)
	duo_enabled["profile"]["duo_links"]["unlocked"] = ["link_spore_jelly_shelter"]
	duo_enabled["active_run"]["equipped_duo_links"] = ["link_spore_jelly_shelter"]
	duo_enabled["active_run"]["duo_link_loadout_confirmed"] = true
	duo_enabled["active_run"]["duo_link_auto_use"] = false
	duo_enabled["active_run"]["duo_link_states"] = {"link_spore_jelly_shelter": {"charge": 63, "active": true, "used_this_battle": false}}
	_expect(MigratorScript.validate_v4(duo_enabled, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()) == "", "L01 장착·게이지·수동 사용 상태 v4 저장 유효")
	duo_enabled["active_run"]["duo_link_auto_use"] = true
	_expect(MigratorScript.validate_v4(duo_enabled, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()) == "", "사용자가 켠 합동기 자동 사용 상태 v4 저장 유효")

	var corrupt := enabled.duplicate(true)
	corrupt["active_run"]["heart"]["heart_id"] = "heart_locked"
	_expect(MigratorScript.validate_v4(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()).contains("심장"), "잠긴 heart ID 저장 거부")

	corrupt = enabled.duplicate(true)
	corrupt["profile"]["duo_links"]["unlocked"] = ["link_a", "link_b"]
	corrupt["active_run"]["equipped_duo_links"] = ["link_a", "link_b"]
	_expect(MigratorScript.validate_v4(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()).contains("동일 monster instance"), "중복 합동 멤버 저장 거부")

	corrupt = enabled.duplicate(true)
	corrupt["active_run"]["legacy_payload"]["world"]["castle_art_stage"] = "stage_02_castle"
	_expect(MigratorScript.validate_v4(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()).contains("heart_chamber"), "Stage 02 이상 심장방 누락 저장 거부")

	corrupt = enabled.duplicate(true)
	corrupt["active_run"]["rival_finale"]["rival_id"] = "selen"
	_expect(MigratorScript.validate_v4(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()).contains("DAY 30 라이벌"), "front와 DAY 30 라이벌 불일치 저장 거부")

	corrupt = enabled.duplicate(true)
	corrupt["profile"]["rival_relations"]["leon"] = 101
	_expect(MigratorScript.validate_v4(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()).contains("0~100"), "라이벌 관계 범위 손상 거부")


func _test_safe_store_recovery_and_quarantine(base_v3: Dictionary) -> void:
	var migration := MigratorScript.migrate_envelope(base_v3, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs())
	var v4: Dictionary = migration.get("envelope", {})
	_expect(bool(SaveV4StoreScript.write(v4, TEST_V4_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()).get("ok", false)), "v4 임시 기록·재검증·안전 교체")
	var first := SaveV4StoreScript.inspect(TEST_V4_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs())
	var second := SaveV4StoreScript.inspect(TEST_V4_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs())
	_expect(str(first.get("status", "")) == SaveV4StoreScript.STATUS_VALID and first.get("envelope", {}) == second.get("envelope", {}), "v4 반복 복원 멱등성")
	var text := FileAccess.get_file_as_string(TEST_V4_PATH)
	SaveV4StoreScript.delete(TEST_V4_PATH)
	_write_text("%s.tmp" % TEST_V4_PATH, text)
	_expect(str(SaveV4StoreScript.inspect(TEST_V4_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()).get("status", "")) == SaveV4StoreScript.STATUS_VALID and FileAccess.file_exists(TEST_V4_PATH), "중단된 v4 tmp 자동 복구")

	_expect(bool(SaveV3StoreScript.write(base_v3, TEST_V3_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions).get("ok", false)), "v3 원본 파일 기록")
	_expect(bool(SaveV4StoreScript.migrate_v3_file(TEST_V3_PATH, TEST_V4_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs()).get("ok", false)) and FileAccess.file_exists(TEST_V3_PATH), "v3 파일 보존 상태로 v4 변환")

	_write_text(CORRUPT_V4_PATH, "{}")
	var corrupt_inspection := SaveV4StoreScript.inspect(CORRUPT_V4_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _catalogs())
	_expect(str(corrupt_inspection.get("status", "")) == SaveV4StoreScript.STATUS_CORRUPT and FileAccess.file_exists("%s.corrupt" % CORRUPT_V4_PATH) and not FileAccess.file_exists(CORRUPT_V4_PATH), "손상 v4 저장 격리")


func _catalogs() -> Dictionary:
	return {
		"fronts": {"front_hero_oath": {"final_rival_id": "leon"}},
		"castle_hearts": {"heart_stonebone": {}, "heart_hungry_maw": {}, "heart_dream_lantern": {}},
		"duo_links": {
			"link_a": {"member_instance_ids": ["mon_core_pudding", "mon_core_gob"]},
			"link_b": {"member_instance_ids": ["mon_core_pudding", "mon_core_pynn"]},
			"link_spore_jelly_shelter": {"member_instance_ids": ["mon_core_pudding", "mon_contract_mori"]}
		}
	}


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


func _cleanup() -> void:
	SaveV3StoreScript.delete(TEST_V3_PATH)
	SaveV4StoreScript.delete(TEST_V4_PATH)
	SaveV4StoreScript.delete(CORRUPT_V4_PATH)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[SaveV4Migration] FAIL: %s" % message)
