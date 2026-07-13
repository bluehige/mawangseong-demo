extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const HeartServiceScript = preload("res://scripts/systems/hearts/CastleHeartService.gd")
const ChamberServiceScript = preload("res://scripts/systems/hearts/HeartChamberService.gd")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const SaveV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_selection_and_awakening()
	_test_charge_passive_and_active()
	await _test_game_root_vertical_fixture()
	_test_v4_safe_point()
	if failed:
		print("STONEBONE_HEART_PHASE5_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("STONEBONE_HEART_PHASE5_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _front_run() -> Dictionary:
	var selected := FrontServiceScript.select_front(FrontServiceScript.default_update3_profile(), FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HERO_FRONT_ID, DataRegistry.update3_fronts)
	return selected.get("active_run", {}).duplicate(true)


func _stonebone_run(day: int = 4, stage_index: int = 2) -> Dictionary:
	var selected := HeartServiceScript.select_heart(FrontServiceScript.default_update3_profile(), _front_run(), HeartServiceScript.STONEBONE_ID, DataRegistry.update3_castle_hearts)
	var active: Dictionary = selected.get("active_run", {})
	active = HeartServiceScript.awaken(active, day).get("active_run", active)
	active = ChamberServiceScript.sync_active_run(active, stage_index)
	return active


func _test_selection_and_awakening() -> void:
	_expect(DataRegistry.update3_castle_hearts.has(HeartServiceScript.STONEBONE_ID), "Phase 6 이후에도 Phase 5 석골 심장 데이터 유지")
	_expect(DataRegistry.skills.has(HeartServiceScript.ACTIVE_SKILL_ID), "castle_brace 스킬 데이터 연결")
	var invalid := HeartServiceScript.select_heart(FrontServiceScript.default_update3_profile(), _front_run(), "heart_missing", DataRegistry.update3_castle_hearts)
	_expect(not bool(invalid.get("ok", true)), "없는 심장 ID 선택 거부")
	var selected := HeartServiceScript.select_heart(FrontServiceScript.default_update3_profile(), _front_run(), HeartServiceScript.STONEBONE_ID, DataRegistry.update3_castle_hearts)
	_expect(bool(selected.get("ok", false)) and bool(selected.get("active_run", {}).get("update3_enabled", false)), "석골 심장 선택 저장·3차 활성")
	var active: Dictionary = selected.get("active_run", {})
	_expect(not bool(HeartServiceScript.awaken(active, 3).get("active_run", {}).get("heart", {}).get("awakened", true)), "DAY 1~3 심장 후면")
	var awakened := HeartServiceScript.awaken(active, 4)
	_expect(bool(awakened.get("awakened_now", false)) and int(awakened.get("active_run", {}).get("heart", {}).get("awakened_day", 0)) == 4, "DAY 4 심장 1회 각성")
	_expect(not bool(HeartServiceScript.awaken(awakened.get("active_run", {}), 5).get("awakened_now", true)), "각성 이벤트 중복 방지")


func _test_charge_passive_and_active() -> void:
	var active := HeartServiceScript.start_battle(_stonebone_run(), "fixture_day15", 2)
	var damage := HeartServiceScript.apply_room_damage(active, "barracks", 100, "siege_a", 1.0)
	active = damage.get("active_run", {})
	_expect(int(damage.get("damage", 0)) == 88 and int(damage.get("reduced", 0)) == 12, "시설 피해 -12%")
	_expect(int(damage.get("charge_gain", 0)) == 10, "시설 피해 15당 충전 +2")
	var repair := HeartServiceScript.apply_repair(active, 40, "repair_a", 1.3)
	active = repair.get("active_run", {})
	_expect(int(repair.get("repair", 0)) == 50 and int(repair.get("bonus", 0)) == 10, "시설 수리 +25%")
	_expect(int(repair.get("charge_gain", 0)) == 15, "수리 10당 충전 +3")
	var first_hit := HeartServiceScript.record_charge(active, "monster_damage_absorbed", 20, "tank_a", 2.01)
	var duplicate_hit := HeartServiceScript.record_charge(first_hit.get("active_run", {}), "monster_damage_absorbed", 20, "tank_a", 2.10)
	active = duplicate_hit.get("active_run", {})
	_expect(int(first_hit.get("gain", 0)) == 2 and int(duplicate_hit.get("gain", -1)) == 0 and bool(duplicate_hit.get("duplicate", false)), "0.2초 다중 피격 충전 중복 없음")
	for index in range(60):
		var charge_result := HeartServiceScript.record_charge(active, "monster_damage_absorbed", 20, "tank_%d" % index, 3.0 + float(index) * 0.21)
		active = charge_result.get("active_run", active)
	_expect(int(active.get("heart", {}).get("charge", -1)) == 100, "심장 충전 0~100 상한")
	var activation := HeartServiceScript.activate(active, ["barracks", "recovery", ChamberServiceScript.ROOM_ID])
	active = activation.get("active_run", {})
	_expect(bool(activation.get("ok", false)) and int(activation.get("shielded_rooms", 0)) == 3, "castle_brace 활성 시설·심장실 보호막 45")
	_expect(float(active.get("heart", {}).get("active_remaining", 0.0)) == 6.0 and int(active.get("heart", {}).get("charge", -1)) == 0, "액티브 6초·충전 0")
	var shielded := HeartServiceScript.apply_room_damage(active, "barracks", 100, "siege_b", 20.0)
	_expect(int(shielded.get("shield_absorbed", 0)) == 45 and int(shielded.get("damage", 0)) == 48, "보호막 후 석골 패시브 순차 적용")
	_expect((100.0 - float(shielded.get("damage", 100))) / 100.0 >= 0.15, "필수 A/B 시설 피해 15% 이상 차이")
	active = shielded.get("active_run", {})
	active["heart"]["charge"] = 100
	var second_activation := HeartServiceScript.activate(active, ["barracks"])
	_expect(not bool(second_activation.get("ok", true)), "액티브 전투당 2회 사용 금지")
	var monster_damage := HeartServiceScript.monster_damage(active, 100, true)
	_expect(int(monster_damage.get("damage", 0)) == 88, "액티브 중 방 내부 몬스터 피해 -12%")
	active = HeartServiceScript.tick(active, 6.1)
	_expect(float(active.get("heart", {}).get("active_remaining", -1.0)) == 0.0 and active.get("heart", {}).get("room_shields", {}).is_empty(), "6초 후 액티브·보호막 종료")
	active["heart"]["disabled_this_battle"] = true
	var disabled_damage := HeartServiceScript.apply_room_damage(active, "barracks", 100, "siege_c", 30.0)
	_expect(int(disabled_damage.get("damage", 0)) == 100, "심장실 비활성 시 패시브 정지")
	var disabled_charge := HeartServiceScript.record_charge(disabled_damage.get("active_run", {}), "monster_damage_absorbed", 100, "tank_disabled", 31.0)
	_expect(int(disabled_charge.get("gain", -1)) == 0, "심장실 비활성 시 충전 정지")


func _test_game_root_vertical_fixture() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	GameState.day = 15
	game.castle_art_stage = "stage_02_castle"
	game.rooms = DataRegistry.rooms.duplicate(true)
	game._init_room_facilities()
	game.update3_profile = FrontServiceScript.default_update3_profile()
	game.update3_active_run = _stonebone_run(4, 2)
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	game._prepare_update3_heart_battle()
	_expect(game.rooms.has(ChamberServiceScript.ROOM_ID), "기존 레온 전선 DAY 15 Stage 02 심장실 연결")
	var room_id := "barracks"
	var hp_before := int(game.rooms[room_id].get("hp", 0))
	var dealt: Dictionary = game._damage_update3_facility(room_id, 100, "day15_siege")
	_expect(int(dealt.get("damage", 0)) == 88 and int(game.rooms[room_id].get("hp", 0)) == hp_before - 88, "GameRoot 시설 피해 실제 반영")
	var repaired: Dictionary = game._repair_update3_facility(room_id, 40, "day15_repair")
	_expect(int(repaired.get("repair", 0)) == 50, "GameRoot 시설 수리 실제 반영")
	game.update3_active_run["heart"]["charge"] = 100
	var activated: Dictionary = game._activate_update3_heart()
	_expect(bool(activated.get("ok", false)), "GameRoot H키 액티브 연결")
	_expect(not bool(game._activate_update3_heart().get("ok", true)), "GameRoot 액티브 중복 방지")
	var chamber_result: Dictionary = game._damage_update3_heart_chamber(9999)
	_expect(not bool(chamber_result.get("castle_defeat", true)) and bool(game.update3_active_run.get("heart", {}).get("disabled_this_battle", false)), "심장실 무력화는 패배 없이 패시브만 정지")
	_expect(not game._update3_heart_result_lines().is_empty(), "결산에 심장 기여 표시")
	var unit = game._create_unit("slime", DataRegistry.monster("slime"), Constants.FACTION_MONSTER, "barracks")
	game.monster_roster["slime"]["room"] = "barracks"
	game.update3_active_run = _stonebone_run(4, 2)
	game._update3_refresh_monster_heart_position(unit)
	_expect(int(unit.heart_def_bonus) == 1, "자신의 배치 방 석골 DEF +1")
	game.monster_roster["slime"]["room"] = ChamberServiceScript.ROOM_ID
	unit.current_room = "treasure"
	game._update3_refresh_monster_heart_position(unit)
	_expect(is_equal_approx(float(unit.heart_move_multiplier), 0.94), "배치 방에서 2방 초과 이탈 시 이동 속도 -6%")
	unit.queue_free()
	host.queue_free()


func _test_v4_safe_point() -> void:
	var migration := SaveV4MigratorScript.migrate_envelope(_base_v3_fixture(), DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs())
	var envelope: Dictionary = migration.get("envelope", {}).duplicate(true)
	var active := _stonebone_run(4, 2)
	active = HeartServiceScript.start_battle(active, "save_fixture", 2)
	active["heart"]["charge"] = 73
	for key in active.keys():
		envelope["active_run"][key] = active[key].duplicate(true) if active[key] is Dictionary or active[key] is Array else active[key]
	envelope["active_run"]["legacy_payload"]["world"]["castle_art_stage"] = "stage_02_castle"
	var validation_error := SaveV4MigratorScript.validate_v4(envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs())
	_expect(validation_error == "", "석골 심장 Stage 02 v4 안전 지점: %s" % validation_error)
	var restored = JSON.parse_string(JSON.stringify(envelope))
	_expect(str(restored.get("active_run", {}).get("heart", {}).get("heart_id", "")) == HeartServiceScript.STONEBONE_ID and int(restored.get("active_run", {}).get("heart", {}).get("charge", 0)) == 73, "심장 선택·충전도 저장 복원")
	var corrupt := envelope.duplicate(true)
	corrupt["active_run"]["heart"]["charge"] = 101
	_expect(SaveV4MigratorScript.validate_v4(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs()) != "", "충전도 100 초과 저장 거부")


func _base_v3_fixture() -> Dictionary:
	var payload := {
		"checkpoint": "management", "screen": "management",
		"world": {"selected_monster_id": "slime", "castle_art_stage": "stage_01_cave", "monster_roster": {"slime": {"level": 1}, "goblin": {"level": 1}, "imp": {"level": 1}}},
		"raid": {"selected_monster_ids": []}, "campaign": {"completed": false, "final_battle_outcome": "", "postgame_active": false},
		"result": {}, "game_state": {"day": 4}, "onboarding": {}, "update2": {}
	}
	var v2 := SaveV1ToV2MigratorScript.migrate_inspection({"status": "valid", "payload": payload, "summary": {"day": 4}, "saved_at_unix": 1783872000}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	var v3 := SaveV2ToV3MigratorScript.migrate_envelope(v2.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	return v3.get("envelope", {})


func _save_catalogs() -> Dictionary:
	return {"fronts": DataRegistry.update3_fronts, "castle_hearts": DataRegistry.update3_castle_hearts, "duo_links": DataRegistry.update3_duo_links, "rival_finales": DataRegistry.update3_rival_finales}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[StoneboneHeartPhase5] FAIL: %s" % message)
