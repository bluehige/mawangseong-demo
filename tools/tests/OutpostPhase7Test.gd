extends Node

const OutpostServiceScript = preload("res://scripts/systems/outpost/OutpostService.gd")
const OutpostScreenScene = preload("res://scenes/ui/screens/OutpostManagementScreen.tscn")
const ModeServiceScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")
const CouncilServiceScript = preload("res://scripts/systems/campaign/CouncilSeasonService.gd")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const SaveV3ToV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")
const SaveV4ToV5MigratorScript = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd")
const SaveV5StoreScript = preload("res://scripts/systems/save/CampaignSaveV5Store.gd")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")

const TEST_PATH := "user://update4_phase7_outpost_v5.json"

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
		print("OUTPOST_PHASE7_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("OUTPOST_PHASE7_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_service_contract() -> void:
	var profile := _profile()
	var active := _active(profile)
	_expect(GameRootScript != null, "GameRoot 전초기지 화면·저장 연동 parse")
	_expect(DataRegistry.update4_outpost_types.size() == 3, "전초기지 유형 3종 로드")
	_expect(DataRegistry.update4_outpost_encounters.size() == 1 and bool(DataRegistry.update4_outpost_encounters.values()[0].get("runtime_enabled", false)) and DataRegistry.update4_outpost_encounters.values()[0].get("module_ids", []).size() == 4, "Phase 8 실시간 전투 활성·고정 4모듈 유지")
	_expect(not OutpostServiceScript.setup_pending(active, 3) and OutpostServiceScript.setup_pending(active, 4), "DAY 4 건설 슬롯 개방")
	var early := OutpostServiceScript.build(profile, active, "outpost_watch_nest", 3, DataRegistry.update4_outpost_types)
	_expect(not bool(early.get("ok", true)), "DAY 4 이전 건설 거부")
	var built := OutpostServiceScript.build(profile, active, "outpost_watch_nest", 4, DataRegistry.update4_outpost_types)
	_expect(bool(built.get("ok", false)), "DAY 4 감시 둥지 건설")
	profile = built.get("profile", {})
	active = built.get("active_run", {})
	_expect(not OutpostServiceScript.setup_pending(active, 4) and profile.get("outpost", {}).get("types_seen", []).has("outpost_watch_nest"), "건설 후 대기 해제·프로필 발견 기록")
	_expect(not bool(OutpostServiceScript.build(profile, active, "outpost_supply_burrow", 4, DataRegistry.update4_outpost_types).get("ok", true)), "동일 회차 전초기지 1개 제한")
	var owned := _owned_ids()
	var assigned := OutpostServiceScript.assign_monsters(active, owned.slice(0, 3), owned, DataRegistry.monster_instances)
	_expect(bool(assigned.get("ok", false)) and assigned.get("active_run", {}).get("outpost", {}).get("assigned_monster_ids", []).size() == 3, "배치 몬스터 3칸 저장")
	active = assigned.get("active_run", {})
	_expect(not bool(OutpostServiceScript.assign_monsters(active, [owned[0], owned[0]], owned, DataRegistry.monster_instances).get("ok", true)), "배치 몬스터 중복 거부")
	_expect(not bool(OutpostServiceScript.assign_monsters(active, owned.slice(0, 4), owned, DataRegistry.monster_instances).get("ok", true)), "배치 4명 초과 거부")
	_expect(not bool(OutpostServiceScript.upgrade(active, 11, DataRegistry.update4_outpost_types).get("ok", true)), "DAY 12 이전 Lv.2 강화 거부")
	var upgraded := OutpostServiceScript.upgrade(active, 12, DataRegistry.update4_outpost_types)
	active = upgraded.get("active_run", {})
	_expect(bool(upgraded.get("ok", false)) and int(active.get("outpost", {}).get("level", 0)) == 2 and int(active.get("outpost", {}).get("max_hp", 0)) == 450, "DAY 12 Lv.2·HP 강화")
	_expect(OutpostServiceScript.validate_state(active, 12, DataRegistry.update4_outpost_types, DataRegistry.monster_instances) == "", "전초기지 완성 상태 검증")
	_expect(OutpostServiceScript.next_raid_day(4) == 10 and OutpostServiceScript.next_raid_day(10) == 20 and OutpostServiceScript.next_raid_day(20) == 0, "다음 습격 DAY 10·20 표시 계약")


func _test_screen_contract() -> void:
	var profile := _profile()
	var active := _active(profile)
	var built := OutpostServiceScript.build(profile, active, "outpost_supply_burrow", 4, DataRegistry.update4_outpost_types)
	active = built.get("active_run", {})
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var screen = OutpostScreenScene.instantiate()
	screen.setup(active, DataRegistry.update4_outpost_types, _owned_ids(), DataRegistry.monster_instances, 12)
	host.add_child(screen)
	await get_tree().process_frame
	var type_count := 0
	for type_id in DataRegistry.update4_outpost_types.keys():
		if screen.get_node_or_null("DesignCanvas/OutpostTypeButton_%s" % type_id) != null:
			type_count += 1
	_expect(type_count == 3, "전초기지 유형 비교 UI 3열")
	_expect(screen.get_node_or_null("DesignCanvas/OutpostStatusPanel/AssignedSlot1") != null and screen.get_node_or_null("DesignCanvas/OutpostStatusPanel/AssignedSlot3") != null, "배치 몬스터 3칸 표시")
	var upgrade_button: Button = screen.get_node("DesignCanvas/OutpostStatusPanel/OutpostUpgradeButton")
	_expect(not upgrade_button.disabled, "DAY 12 Lv.2 강화 버튼 활성")
	for viewport_size in [Vector2(1920, 1080), Vector2(1366, 768)]:
		var rects: Dictionary = screen.layout_rects_for_viewport(viewport_size)
		_expect(_rects_inside(rects, viewport_size) and not _any_overlap(rects), "%dx%d 유형 비교 카드 경계·비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	if OS.get_environment("UPDATE4_CAPTURE_UI") == "1":
		await get_tree().process_frame
		await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		if image != null:
			var path := OS.get_user_data_dir().path_join("outpost_phase7.png")
			image.save_png(path)
			print("OUTPOST_CAPTURE: %s" % path)
	host.queue_free()


func _test_save_restore() -> void:
	var v5 := _base_v5_fixture()
	var profile := _profile()
	var active := _active(profile)
	var built := OutpostServiceScript.build(profile, active, "outpost_false_gate", 4, DataRegistry.update4_outpost_types)
	profile = built.get("profile", {})
	active = built.get("active_run", {})
	active = OutpostServiceScript.assign_monsters(active, _owned_ids().slice(0, 3), _owned_ids(), DataRegistry.monster_instances).get("active_run", {})
	active = OutpostServiceScript.upgrade(active, 12, DataRegistry.update4_outpost_types).get("active_run", {})
	v5["profile"] = _merge_keys(v5.get("profile", {}), profile, ModeServiceScript.default_profile().keys())
	v5["active_run"] = _merge_keys(v5.get("active_run", {}), active, ModeServiceScript.default_active_run().keys())
	v5["active_run"]["legacy_payload"]["game_state"]["day"] = 12
	v5["active_run"]["legacy_payload"]["screen"] = "outpost_management"
	v5["active_run"]["legacy_payload"]["checkpoint"] = "outpost_management"
	v5["active_run"]["council_season"]["day_state"] = CouncilServiceScript.new_day_state(12)
	var validation_error := SaveV4ToV5MigratorScript.validate_v5(v5, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs)
	_expect(validation_error == "", "Lv.2 전초기지 v5 저장 검증: %s" % validation_error)
	_expect(bool(SaveV5StoreScript.write(v5, TEST_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs).get("ok", false)), "전초기지 v5 기록")
	var inspection := SaveV5StoreScript.inspect(TEST_PATH, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _update3_catalogs(), DataRegistry.update4_catalogs)
	var restored: Dictionary = inspection.get("envelope", {}).get("active_run", {}).get("outpost", {})
	_expect(str(inspection.get("status", "")) == SaveV5StoreScript.STATUS_VALID and str(restored.get("type_id", "")) == "outpost_false_gate" and int(restored.get("level", 0)) == 2 and restored.get("assigned_monster_ids", []).size() == 3, "v5 전초기지 유형·Lv.2·3칸 복원")


func _profile() -> Dictionary:
	return ModeServiceScript.normalize_profile(ModeServiceScript.default_profile(), {"fronts": {"clear_counts": {"front_hero_oath": 1}}})


func _active(profile: Dictionary) -> Dictionary:
	return ModeServiceScript.select_mode(profile, ModeServiceScript.new_cycle_active_run(), ModeServiceScript.COUNCIL_MODE_ID, DataRegistry.update4_campaign_modes).get("active_run", {})


func _owned_ids() -> Array[String]:
	var result: Array[String] = []
	for instance_id_value in DataRegistry.monster_instances.keys():
		result.append(str(instance_id_value))
	result.sort()
	return result


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
	push_error("[OutpostPhase7] FAIL: %s" % message)
