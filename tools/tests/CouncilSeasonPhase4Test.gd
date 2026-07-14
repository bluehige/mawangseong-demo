extends Node

const CouncilServiceScript = preload("res://scripts/systems/campaign/CouncilSeasonService.gd")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const SaveV3ToV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")
const SaveV4ToV5MigratorScript = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd")
const SaveV5StoreScript = preload("res://scripts/systems/save/CampaignSaveV5Store.gd")

const TEST_V5_PATH := "user://update4_phase4_council_v5.json"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	SaveV5StoreScript.delete(TEST_V5_PATH)
	_test_day_catalog_and_flags()
	_test_thirty_day_state_machine_and_saves()
	SaveV5StoreScript.delete(TEST_V5_PATH)
	if failed:
		print("COUNCIL_SEASON_PHASE4_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("COUNCIL_SEASON_PHASE4_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_day_catalog_and_flags() -> void:
	var catalog := DataRegistry.update4_council_campaign_days
	var errors := CouncilServiceScript.validate_catalog(catalog)
	_expect(errors.is_empty(), "의회 DAY 1~30 데이터 계약: %s" % [errors])
	_expect(CouncilServiceScript.has_flag(catalog, 4, "region_selection") and CouncilServiceScript.has_flag(catalog, 11, "region_selection") and CouncilServiceScript.has_flag(catalog, 21, "region_selection"), "지역 선택 DAY 4·11·21")
	_expect(CouncilServiceScript.has_flag(catalog, 13, "council_vote") and CouncilServiceScript.has_flag(catalog, 22, "council_vote") and CouncilServiceScript.has_flag(catalog, 26, "council_vote"), "의회 표결 DAY 13·22·26")
	_expect(CouncilServiceScript.has_flag(catalog, 10, "outpost_battle") and CouncilServiceScript.has_flag(catalog, 20, "outpost_battle"), "전초기지 방어 DAY 10·20")
	_expect(CouncilServiceScript.has_flag(catalog, 23, "crown_choice") and CouncilServiceScript.has_flag(catalog, 24, "representative_reveal"), "왕관 DAY 23·대표 공개 DAY 24")
	_expect(CouncilServiceScript.is_management_only(catalog, 4) and CouncilServiceScript.is_management_only(catalog, 29) and not CouncilServiceScript.can_enter_combat(catalog, 29), "관리 전용 DAY 4·29 전투 차단")
	_expect(CouncilServiceScript.empty_wave_for_day(catalog, 1).get("entries", [1]).is_empty() and CouncilServiceScript.empty_wave_for_day(catalog, 29).is_empty(), "전투 DAY 빈 웨이브·관리 DAY 웨이브 없음")


func _test_thirty_day_state_machine_and_saves() -> void:
	var catalog := DataRegistry.update4_council_campaign_days
	var v5 := _base_council_v5()
	var state := CouncilServiceScript.new_day_state(1)
	var safe_save_count := 0
	var battle_day_count := 0
	for day in range(1, 31):
		_expect(int(state.get("current_day", 0)) == day and str(state.get("phase", "")) == CouncilServiceScript.PHASE_MANAGEMENT, "DAY %02d 관리 진입" % day)
		_sync_v5_day(v5, state)
		var validation_error := SaveV4ToV5MigratorScript.validate_v5(v5, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs)
		if validation_error == "" and JSON.parse_string(JSON.stringify(v5)) is Dictionary:
			safe_save_count += 1
		else:
			_expect(false, "DAY %02d 관리 저장 유효: %s" % [day, validation_error])
		var ready := CouncilServiceScript.finish_management(state, catalog)
		_expect(bool(ready.get("ok", false)), "DAY %02d 관리 완료" % day)
		state = ready.get("state", {})
		_sync_v5_day(v5, state)
		validation_error = SaveV4ToV5MigratorScript.validate_v5(v5, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs)
		if validation_error == "":
			safe_save_count += 1
		else:
			_expect(false, "DAY %02d 준비/완료 저장 유효: %s" % [day, validation_error])
		if CouncilServiceScript.is_management_only(catalog, day):
			var blocked := CouncilServiceScript.begin_combat(state, catalog)
			_expect(not bool(blocked.get("ok", true)) and str(blocked.get("error", "")).contains("관리 전용"), "DAY %02d 관리 전용 전투 진입 거부" % day)
		else:
			battle_day_count += 1
			var started := CouncilServiceScript.begin_combat(state, catalog)
			_expect(bool(started.get("ok", false)), "DAY %02d 빈 웨이브 전투 진입" % day)
			state = started.get("state", {})
			_sync_v5_day(v5, state)
			if day == 1:
				_expect(SaveV4ToV5MigratorScript.validate_v5(v5, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs).contains("진행 중인 의회 전투"), "실시간 의회 전투 저장 거부")
			var completed := CouncilServiceScript.complete_combat(state)
			_expect(bool(completed.get("ok", false)), "DAY %02d 빈 웨이브 완료" % day)
			state = completed.get("state", {})
		if day < 30:
			var advanced := CouncilServiceScript.advance_day(state, catalog)
			_expect(bool(advanced.get("ok", false)) and int(advanced.get("state", {}).get("current_day", 0)) == day + 1, "DAY %02d→%02d 전환" % [day, day + 1])
			state = advanced.get("state", {})
		else:
			var blocked_day31 := CouncilServiceScript.advance_day(state, catalog)
			_expect(not bool(blocked_day31.get("ok", true)) and str(blocked_day31.get("error", "")).contains("DAY 30"), "DAY 31 진입 차단")
	_expect(safe_save_count == 60, "DAY 1~30 관리·전투준비/완료 60개 안전 저장 검증")
	_expect(battle_day_count == 28, "관리 전용 2일 제외 빈 웨이브 전투 28일")
	_sync_v5_day(v5, state)
	_expect(bool(SaveV5StoreScript.write(v5, TEST_V5_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs).get("ok", false)), "DAY 30 완료 상태 실제 v5 기록")


func _base_council_v5() -> Dictionary:
	var payload := {
		"checkpoint": "management", "screen": "management",
		"world": {"selected_monster_id": "slime", "castle_art_stage": "stage_01_cave", "monster_roster": {"slime": {"level": 1}, "goblin": {"level": 1}, "imp": {"level": 1}}},
		"raid": {"selected_monster_ids": []}, "campaign": {"completed": false, "final_battle_outcome": "", "postgame_active": false},
		"result": {}, "game_state": {"day": 1}, "onboarding": {}, "update2": {}
	}
	var v2 := SaveV1ToV2MigratorScript.migrate_inspection({"status": "valid", "payload": payload, "summary": {"day": 1}, "saved_at_unix": 1783872000}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	var v3 := SaveV2ToV3MigratorScript.migrate_envelope(v2.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	var v4 := SaveV3ToV4MigratorScript.migrate_envelope(v3.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
	var v4_envelope: Dictionary = v4.get("envelope", {})
	v4_envelope["profile"]["fronts"]["clear_counts"] = {"front_hero_oath": 1}
	var v5 := SaveV4ToV5MigratorScript.migrate_envelope(v4_envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs)
	var envelope: Dictionary = v5.get("envelope", {})
	envelope["active_run"] = SaveV4ToV5MigratorScript.fresh_update4_active_run(SaveV4ToV5MigratorScript.MODE_COUNCIL_SEASON, 2, 40404, v4_envelope.get("active_run", {}))
	return envelope


func _sync_v5_day(v5: Dictionary, state: Dictionary) -> void:
	var day := int(state.get("current_day", 1))
	v5["active_run"]["legacy_payload"]["game_state"]["day"] = day
	v5["active_run"]["council_season"]["day_state"] = state.duplicate(true)


func _update3_catalogs() -> Dictionary:
	return {"fronts": DataRegistry.update3_fronts, "castle_hearts": DataRegistry.update3_castle_hearts, "duo_links": DataRegistry.update3_duo_links, "rival_finales": DataRegistry.update3_rival_finales}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[CouncilSeasonPhase4] FAIL: %s" % message)
