extends Node

const ModeServiceScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")
const ModeScreenScene = preload("res://scenes/ui/screens/CampaignModeSelectionScreen.tscn")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const SaveV3ToV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")
const SaveV4ToV5MigratorScript = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd")
const SaveV5StoreScript = preload("res://scripts/systems/save/CampaignSaveV5Store.gd")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")

const TEST_V5_PATH := "user://update4_phase3_council_v5.json"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	SaveV5StoreScript.delete(TEST_V5_PATH)
	_test_service_contract()
	await _test_screen_contract()
	_test_council_save_and_continue()
	SaveV5StoreScript.delete(TEST_V5_PATH)
	if failed:
		print("CAMPAIGN_MODE_PHASE3_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("CAMPAIGN_MODE_PHASE3_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_service_contract() -> void:
	var catalog := DataRegistry.update4_campaign_modes
	_expect(GameRootScript != null, "GameRoot v5 권위 저장·모드 화면 연결 parse")
	var profile := ModeServiceScript.default_profile()
	var active := ModeServiceScript.new_cycle_active_run()
	_expect(catalog.size() == 2 and catalog.has(ModeServiceScript.FRONT_MODE_ID) and catalog.has(ModeServiceScript.COUNCIL_MODE_ID), "캠페인 모드 2종 분리 로드")
	_expect(ModeServiceScript.lock_reason(profile, ModeServiceScript.FRONT_MODE_ID, catalog) == "", "전선 연대기는 항상 선택 가능")
	_expect(ModeServiceScript.lock_reason(profile, ModeServiceScript.COUNCIL_MODE_ID, catalog).contains("DAY 30"), "미클리어 프로필 의회 회차 잠금 이유")
	var locked := ModeServiceScript.select_mode(profile, active, ModeServiceScript.COUNCIL_MODE_ID, catalog)
	_expect(not bool(locked.get("ok", true)) and str(active.get("campaign_mode_id", "")) == "", "잠긴 의회 선택 거부·원본 불변")
	var update3_profile := {"fronts": {"clear_counts": {"front_hero_oath": 1}}, "update3_endings_seen": []}
	profile = ModeServiceScript.normalize_profile(profile, update3_profile)
	_expect(bool(profile.get("campaign_modes", {}).get("council_season_unlocked", false)), "전선 DAY 30 승리 기록으로 의회 해금")
	var front := ModeServiceScript.select_mode(profile, active, ModeServiceScript.FRONT_MODE_ID, catalog)
	var council := ModeServiceScript.select_mode(profile, active, ModeServiceScript.COUNCIL_MODE_ID, catalog)
	_expect(bool(front.get("ok", false)) and str(front.get("active_run", {}).get("campaign_mode_id", "")) == ModeServiceScript.FRONT_MODE_ID and ModeServiceScript.start_day(ModeServiceScript.FRONT_MODE_ID, catalog) == 4, "기존 전선 경로·DAY 4 보존")
	_expect(bool(council.get("ok", false)) and str(council.get("active_run", {}).get("campaign_mode_id", "")) == ModeServiceScript.COUNCIL_MODE_ID and ModeServiceScript.start_day(ModeServiceScript.COUNCIL_MODE_ID, catalog) == 1, "의회 회차 DAY 1 시작")
	_expect(council.get("active_run", {}).get("council_season", {}).get("selected_regions", []).is_empty() and not bool(council.get("active_run", {}).get("upper_floor", {}).get("unlocked", true)), "Phase 3 의회 빈 상태·상층 미구현")


func _test_screen_contract() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var screen = ModeScreenScene.instantiate()
	var unlocked_profile := ModeServiceScript.normalize_profile(ModeServiceScript.default_profile(), {"fronts": {"clear_counts": {"front_hero_oath": 1}}})
	screen.setup(unlocked_profile, DataRegistry.update4_campaign_modes, 2, true)
	host.add_child(screen)
	await get_tree().process_frame
	var front_button: Button = screen.get_node("DesignCanvas/CampaignModeButton_front_chronicle")
	var council_button: Button = screen.get_node("DesignCanvas/CampaignModeButton_council_season")
	_expect(not front_button.disabled and not council_button.disabled, "해금 프로필 모드 선택 UI 2종 활성")
	_expect(screen.get_node_or_null("DesignCanvas/CampaignModeCancelButton") != null, "모드 선택 뒤로가기")
	for viewport_size in [Vector2(1920, 1080), Vector2(1366, 768)]:
		var rects: Dictionary = screen.layout_rects_for_viewport(viewport_size)
		_expect(_rects_inside(rects, viewport_size), "%dx%d 모드 선택 화면 내부" % [int(viewport_size.x), int(viewport_size.y)])
		_expect(not rects[ModeServiceScript.FRONT_MODE_ID].intersects(rects[ModeServiceScript.COUNCIL_MODE_ID]), "%dx%d 모드 카드 비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	if OS.get_environment("UPDATE4_CAPTURE_UI") == "1":
		await get_tree().process_frame
		await get_tree().process_frame
		var capture_path := OS.get_user_data_dir().path_join("campaign_mode_phase3.png")
		var capture_image := get_viewport().get_texture().get_image()
		if capture_image != null:
			capture_image.save_png(capture_path)
			print("CAMPAIGN_MODE_CAPTURE: %s" % capture_path)
	host.queue_free()


func _test_council_save_and_continue() -> void:
	var v4 := _base_v4_fixture()
	var migration := SaveV4ToV5MigratorScript.migrate_envelope(v4, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs)
	_expect(bool(migration.get("ok", false)), "Phase 3 검증용 v5 구성")
	var v5: Dictionary = migration.get("envelope", {}).duplicate(true)
	var profile := ModeServiceScript.normalize_profile(v5.get("profile", {}), v5.get("profile", {}))
	var selected := ModeServiceScript.select_mode(profile, ModeServiceScript.new_cycle_active_run(), ModeServiceScript.COUNCIL_MODE_ID, DataRegistry.update4_campaign_modes)
	for key in ModeServiceScript.default_profile().keys():
		v5["profile"][key] = selected.get("profile", {}).get(key).duplicate(true) if selected.get("profile", {}).get(key) is Dictionary or selected.get("profile", {}).get(key) is Array else selected.get("profile", {}).get(key)
	for key in ModeServiceScript.default_active_run().keys():
		v5["active_run"][key] = selected.get("active_run", {}).get(key).duplicate(true) if selected.get("active_run", {}).get(key) is Dictionary or selected.get("active_run", {}).get(key) is Array else selected.get("active_run", {}).get(key)
	v5["active_run"]["legacy_payload"]["game_state"]["day"] = 1
	v5["active_run"]["legacy_payload"]["screen"] = "management"
	v5["active_run"]["legacy_payload"]["checkpoint"] = "management"
	var validation_error := SaveV4ToV5MigratorScript.validate_v5(v5, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs)
	_expect(validation_error == "", "의회 DAY 1 v5 저장 유효: %s" % validation_error)
	_expect(bool(SaveV5StoreScript.write(v5, TEST_V5_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs).get("ok", false)), "의회 DAY 1 권위 v5 저장 생성")
	var inspection := SaveV5StoreScript.inspect(TEST_V5_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs)
	var restored: Dictionary = inspection.get("envelope", {})
	_expect(str(inspection.get("status", "")) == SaveV5StoreScript.STATUS_VALID and str(restored.get("active_run", {}).get("campaign_mode_id", "")) == ModeServiceScript.COUNCIL_MODE_ID, "의회 v5 이어하기 모드 복원")
	_expect(int(restored.get("active_run", {}).get("legacy_payload", {}).get("game_state", {}).get("day", 0)) == 1 and str(restored.get("active_run", {}).get("legacy_payload", {}).get("screen", "")) == "management", "의회 이어하기 DAY 1 빈 관리 화면 복원")


func _base_v4_fixture() -> Dictionary:
	var payload := {
		"checkpoint": "management", "screen": "management",
		"world": {"selected_monster_id": "slime", "castle_art_stage": "stage_01_cave", "monster_roster": {"slime": {"level": 1}, "goblin": {"level": 1}, "imp": {"level": 1}}},
		"raid": {"selected_monster_ids": []}, "campaign": {"completed": false, "final_battle_outcome": "", "postgame_active": false},
		"result": {}, "game_state": {"day": 4}, "onboarding": {}, "update2": {}
	}
	var v2 := SaveV1ToV2MigratorScript.migrate_inspection({"status": "valid", "payload": payload, "summary": {"day": 4}, "saved_at_unix": 1783872000}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	var v3 := SaveV2ToV3MigratorScript.migrate_envelope(v2.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	var v4 := SaveV3ToV4MigratorScript.migrate_envelope(v3.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs())
	var envelope: Dictionary = v4.get("envelope", {})
	envelope["profile"]["fronts"]["clear_counts"] = {"front_hero_oath": 1}
	return envelope


func _update3_catalogs() -> Dictionary:
	return {"fronts": DataRegistry.update3_fronts, "castle_hearts": DataRegistry.update3_castle_hearts, "duo_links": DataRegistry.update3_duo_links, "rival_finales": DataRegistry.update3_rival_finales}


func _rects_inside(rects: Dictionary, viewport_size: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	for rect in rects.values():
		if not bounds.encloses(rect):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[CampaignModePhase3] FAIL: %s" % message)
