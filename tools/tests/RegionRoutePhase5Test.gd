extends Node

const RegionServiceScript = preload("res://scripts/systems/regions/RegionRouteService.gd")
const ModeServiceScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")
const CouncilServiceScript = preload("res://scripts/systems/campaign/CouncilSeasonService.gd")
const RegionScreenScene = preload("res://scenes/ui/screens/RegionSelectionScreen.tscn")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const SaveV3ToV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")
const SaveV4ToV5MigratorScript = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd")
const SaveV5StoreScript = preload("res://scripts/systems/save/CampaignSaveV5Store.gd")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")

const TEST_PATH := "user://update4_phase5_region_route_v5.json"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	SaveV5StoreScript.delete(TEST_PATH)
	_test_service_contract()
	await _test_screen_contract()
	_test_save_restore()
	SaveV5StoreScript.delete(TEST_PATH)
	if failed:
		print("REGION_ROUTE_PHASE5_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("REGION_ROUTE_PHASE5_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_service_contract() -> void:
	var catalog := DataRegistry.update4_regions
	_expect(GameRootScript != null, "GameRoot 지역 선택 화면 연동 parse")
	_expect(catalog.size() == 5, "지역 카탈로그 5종 로드")
	_expect(RegionServiceScript.SELECTION_DAYS == [4, 11, 21], "지역 선택 DAY 4·11·21 고정")
	_expect(RegionServiceScript.ordered_route_count(catalog) == 60, "5개 중 순서 있는 3개 선택 60순열")

	var profile := _unlocked_profile()
	var active := _council_active(profile)
	_expect(RegionServiceScript.pending_selection_slot(active, 3) == -1 and RegionServiceScript.pending_selection_slot(active, 4) == 0, "DAY 4 이전 차단·첫 슬롯 개방")
	var first := RegionServiceScript.select_region(profile, active, "region_ironbell_ravine", 4, catalog)
	_expect(bool(first.get("ok", false)), "DAY 4 첫 지역 선택")
	profile = first.get("profile", {})
	active = first.get("active_run", {})
	_expect(RegionServiceScript.pending_selection_slot(active, 10) == -1 and RegionServiceScript.pending_selection_slot(active, 11) == 1, "DAY 11 두 번째 슬롯 검증")
	var duplicate := RegionServiceScript.select_region(profile, active, "region_ironbell_ravine", 11, catalog)
	_expect(not bool(duplicate.get("ok", true)), "같은 회차 지역 중복 거부")
	var second := RegionServiceScript.select_region(profile, active, "region_moonbat_aerie", 11, catalog)
	profile = second.get("profile", {})
	active = second.get("active_run", {})
	_expect(bool(second.get("ok", false)) and RegionServiceScript.pending_selection_slot(active, 21) == 2, "DAY 11 선택 후 DAY 21 세 번째 슬롯")
	var third := RegionServiceScript.select_region(profile, active, "region_mistcap_marsh", 21, catalog)
	active = third.get("active_run", {})
	_expect(bool(third.get("ok", false)) and not RegionServiceScript.selection_pending(active, 30), "세 지역 선택 후 추가 슬롯 차단")
	_expect(RegionServiceScript.selected_region_ids(active) == ["region_ironbell_ravine", "region_moonbat_aerie", "region_mistcap_marsh"], "선택 순서 보존")
	_expect(RegionServiceScript.current_region_id(active) == "region_mistcap_marsh", "현재 지역이 세 번째 선택을 가리킴")
	_expect(RegionServiceScript.validate_selection_state(active, 21, catalog) == "", "완성 지역 경로 상태 검증")
	_expect(_all_ordered_routes_succeed(catalog), "60개 순열 모두 DAY 4·11·21 선택 허용")


func _test_screen_contract() -> void:
	var profile := _unlocked_profile()
	var active := _council_active(profile)
	active = RegionServiceScript.select_region(profile, active, "region_ironbell_ravine", 4, DataRegistry.update4_regions).get("active_run", {})
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var screen = RegionScreenScene.instantiate()
	screen.setup(active, DataRegistry.update4_regions, 11, true)
	host.add_child(screen)
	await get_tree().process_frame
	var button_count := 0
	for region_id in RegionServiceScript.available_region_ids({"campaign_mode_id": ModeServiceScript.COUNCIL_MODE_ID, "council_season": {"selected_regions": []}}, DataRegistry.update4_regions):
		if screen.get_node_or_null("DesignCanvas/RegionCardButton_%s" % region_id) != null:
			button_count += 1
	_expect(button_count == 5, "지역 카드 UI 5종 생성")
	var selected_button: Button = screen.get_node("DesignCanvas/RegionCardButton_region_ironbell_ravine")
	var available_button: Button = screen.get_node("DesignCanvas/RegionCardButton_region_moonbat_aerie")
	_expect(selected_button.disabled and not available_button.disabled, "선택 완료 카드 비활성·남은 카드 활성")
	for viewport_size in [Vector2(1920, 1080), Vector2(1366, 768)]:
		var rects: Dictionary = screen.layout_rects_for_viewport(viewport_size)
		_expect(_rects_inside(rects, viewport_size) and not _any_overlap(rects), "%dx%d 지역 카드 화면 경계·비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	if OS.get_environment("UPDATE4_CAPTURE_UI") == "1":
		await get_tree().process_frame
		await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		if image != null:
			var path := OS.get_user_data_dir().path_join("region_route_phase5.png")
			image.save_png(path)
			print("REGION_ROUTE_CAPTURE: %s" % path)
	host.queue_free()


func _test_save_restore() -> void:
	var v5 := _base_v5_fixture()
	var profile: Dictionary = v5.get("profile", {}).duplicate(true)
	var active := _council_active(profile)
	for pair in [[4, "region_blackwater_exchange"], [11, "region_bone_lantern_fields"], [21, "region_moonbat_aerie"]]:
		var selected := RegionServiceScript.select_region(profile, active, str(pair[1]), int(pair[0]), DataRegistry.update4_regions)
		_expect(bool(selected.get("ok", false)), "저장 fixture DAY %d 지역 선택" % int(pair[0]))
		profile = selected.get("profile", {})
		active = selected.get("active_run", {})
	v5["profile"] = _merge_keys(v5.get("profile", {}), profile, ModeServiceScript.default_profile().keys())
	v5["active_run"] = _merge_keys(v5.get("active_run", {}), active, ModeServiceScript.default_active_run().keys())
	v5["active_run"]["legacy_payload"]["game_state"]["day"] = 21
	v5["active_run"]["legacy_payload"]["screen"] = "management"
	v5["active_run"]["legacy_payload"]["checkpoint"] = "management"
	v5["active_run"]["council_season"]["day_state"] = CouncilServiceScript.new_day_state(21)
	var validation_error := SaveV4ToV5MigratorScript.validate_v5(v5, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs)
	_expect(validation_error == "", "세 지역 v5 저장 검증: %s" % validation_error)
	_expect(bool(SaveV5StoreScript.write(v5, TEST_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs).get("ok", false)), "세 지역 경로 v5 기록")
	var inspection := SaveV5StoreScript.inspect(TEST_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs)
	var restored: Dictionary = inspection.get("envelope", {}).get("active_run", {})
	_expect(str(inspection.get("status", "")) == SaveV5StoreScript.STATUS_VALID and RegionServiceScript.selected_region_ids(restored) == ["region_blackwater_exchange", "region_bone_lantern_fields", "region_moonbat_aerie"], "v5 재로딩 선택 순서 복원")


func _all_ordered_routes_succeed(catalog: Dictionary) -> bool:
	var ids := catalog.keys()
	var success_count := 0
	for first_id in ids:
		for second_id in ids:
			for third_id in ids:
				if first_id == second_id or first_id == third_id or second_id == third_id:
					continue
				var profile := _unlocked_profile()
				var active := _council_active(profile)
				var first := RegionServiceScript.select_region(profile, active, str(first_id), 4, catalog)
				var second := RegionServiceScript.select_region(first.get("profile", {}), first.get("active_run", {}), str(second_id), 11, catalog)
				var third := RegionServiceScript.select_region(second.get("profile", {}), second.get("active_run", {}), str(third_id), 21, catalog)
				if bool(first.get("ok", false)) and bool(second.get("ok", false)) and bool(third.get("ok", false)):
					success_count += 1
	return success_count == 60


func _unlocked_profile() -> Dictionary:
	return ModeServiceScript.normalize_profile(ModeServiceScript.default_profile(), {"fronts": {"clear_counts": {"front_hero_oath": 1}}})


func _council_active(profile: Dictionary) -> Dictionary:
	return ModeServiceScript.select_mode(profile, ModeServiceScript.new_cycle_active_run(), ModeServiceScript.COUNCIL_MODE_ID, DataRegistry.update4_campaign_modes).get("active_run", {})


func _base_v5_fixture() -> Dictionary:
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
	return SaveV4ToV5MigratorScript.migrate_envelope(envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs).get("envelope", {})


func _merge_keys(base_value: Dictionary, overlay: Dictionary, keys: Array) -> Dictionary:
	var result := base_value.duplicate(true)
	for key in keys:
		if overlay.has(key):
			result[key] = overlay.get(key).duplicate(true) if overlay.get(key) is Dictionary or overlay.get(key) is Array else overlay.get(key)
	return result


func _update3_catalogs() -> Dictionary:
	return {"fronts": DataRegistry.update3_fronts, "castle_hearts": DataRegistry.update3_castle_hearts, "duo_links": DataRegistry.update3_duo_links, "rival_finales": DataRegistry.update3_rival_finales}


func _rects_inside(rects: Dictionary, viewport_size: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	for rect in rects.values():
		if not bounds.encloses(rect):
			return false
	return true


func _any_overlap(rects: Dictionary) -> bool:
	var values := rects.values()
	for index in values.size():
		for other in range(index + 1, values.size()):
			if values[index].intersects(values[other]):
				return true
	return false


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[RegionRoutePhase5] FAIL: %s" % message)
