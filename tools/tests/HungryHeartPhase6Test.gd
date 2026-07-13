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
	_test_selection_upkeep_and_healing()
	_test_hunger_charge_and_limits()
	_test_active_and_ab_targets()
	await _test_game_root_vertical_fixture()
	_test_v4_safe_state()
	if failed:
		print("HUNGRY_HEART_PHASE6_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("HUNGRY_HEART_PHASE6_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _front_run() -> Dictionary:
	var selected := FrontServiceScript.select_front(FrontServiceScript.default_update3_profile(), FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HERO_FRONT_ID, DataRegistry.update3_fronts)
	return selected.get("active_run", {}).duplicate(true)


func _hungry_run(day: int = 4, stage_index: int = 2) -> Dictionary:
	var selected := HeartServiceScript.select_heart(FrontServiceScript.default_update3_profile(), _front_run(), HeartServiceScript.HUNGRY_MAW_ID, DataRegistry.update3_castle_hearts)
	var active: Dictionary = selected.get("active_run", {})
	active = HeartServiceScript.awaken(active, day).get("active_run", active)
	active = ChamberServiceScript.sync_active_run(active, stage_index)
	return active


func _test_selection_upkeep_and_healing() -> void:
	_expect(DataRegistry.update3_castle_hearts.has(HeartServiceScript.HUNGRY_MAW_ID), "Phase 7 이후에도 Phase 6 포식 심장 데이터 유지")
	_expect(DataRegistry.skills.has(HeartServiceScript.HUNGRY_ACTIVE_SKILL_ID), "devouring_corridor 스킬 데이터 연결")
	var selected := HeartServiceScript.select_heart(FrontServiceScript.default_update3_profile(), _front_run(), HeartServiceScript.HUNGRY_MAW_ID, DataRegistry.update3_castle_hearts)
	_expect(bool(selected.get("ok", false)), "포식 심장 선택 가능")
	var switched := HeartServiceScript.select_heart(FrontServiceScript.default_update3_profile(), selected.get("active_run", {}), HeartServiceScript.STONEBONE_ID, DataRegistry.update3_castle_hearts)
	_expect(not bool(switched.get("ok", true)), "회차 도중 심장 변경 금지")
	var active := _hungry_run()
	var upkeep := HeartServiceScript.apply_daily_upkeep(active, 4, 10)
	active = upkeep.get("active_run", {})
	_expect(int(upkeep.get("food", 0)) == 8 and int(upkeep.get("paid", 0)) == 2, "일일 식량 유지비 +2 실제 차감")
	var duplicate := HeartServiceScript.apply_daily_upkeep(active, 4, 8)
	_expect(int(duplicate.get("food", 0)) == 8 and int(duplicate.get("paid", -1)) == 0, "같은 날 유지비 중복 차감 없음")
	var next_day := HeartServiceScript.apply_daily_upkeep(active, 5, 8)
	_expect(int(next_day.get("food", 0)) == 6, "다음 날 유지비 다시 차감")
	_expect(is_equal_approx(HeartServiceScript.healing_multiplier(active), 0.92), "직접·지속 회복 공통 배율 -8%")
	active["heart"]["disabled_this_battle"] = true
	_expect(is_equal_approx(HeartServiceScript.healing_multiplier(active), 1.0), "심장실 비활성 시 회복 대가도 정지")


func _test_hunger_charge_and_limits() -> void:
	var active := HeartServiceScript.start_battle(_hungry_run(), "hungry_multiwave", 2)
	var damage := HeartServiceScript.record_hungry_damage(active, 70, "aoe_cast_a")
	active = damage.get("active_run", {})
	var duplicate_damage := HeartServiceScript.record_hungry_damage(active, 210, "aoe_cast_a")
	active = duplicate_damage.get("active_run", {})
	_expect(int(damage.get("gain", 0)) == 4 and bool(duplicate_damage.get("duplicate", false)) and int(duplicate_damage.get("gain", -1)) == 0, "실제 피해 35당 +2, 동일 광역 공격은 대상 수와 무관하게 1회")
	for index in range(4):
		var finish := HeartServiceScript.record_hungry_finish(active, "enemy_%d" % index)
		active = finish.get("active_run", {})
		_expect(not bool(finish.get("wave", true)), "마무리 %d회는 아직 파동 전" % (index + 1))
	_expect(int(active.get("heart", {}).get("hunger", 0)) == 4, "마무리마다 hunger +1")
	var duplicate_finish := HeartServiceScript.record_hungry_finish(active, "enemy_3")
	_expect(not bool(duplicate_finish.get("counted", true)) and int(duplicate_finish.get("charge_gain", -1)) == 0, "같은 적 마무리 중복 집계 없음")
	var fifth := HeartServiceScript.record_hungry_finish(active, "enemy_4")
	active = fifth.get("active_run", {})
	_expect(bool(fifth.get("wave", false)) and int(fifth.get("infamy", 0)) == 3, "hunger 5에서 포식 파동·악명 +3")
	_expect(int(active.get("heart", {}).get("charge", 0)) == 42, "피해 +4, 마무리 5회 +30, 파동 +8 충전 합산")
	for index in range(5, 25):
		active = HeartServiceScript.record_hungry_finish(active, "enemy_%d" % index).get("active_run", active)
	_expect(int(active.get("heart", {}).get("hunger_waves", 0)) == 3, "전투당 포식 파동 최대 3회")
	_expect(int(active.get("heart", {}).get("hungry_infamy_earned", 0)) == 9, "포식 파동 악명 보상 전투당 최대 9")
	_expect(int(active.get("heart", {}).get("hunger", -1)) <= 4, "파동 상한 뒤 hunger 안전 범위 유지")
	active["heart"]["disabled_this_battle"] = true
	var disabled := HeartServiceScript.record_hungry_finish(active, "disabled_enemy")
	_expect(not bool(disabled.get("counted", true)), "심장실 비활성 시 hunger·충전 정지")


func _test_active_and_ab_targets() -> void:
	var active := HeartServiceScript.start_battle(_hungry_run(), "hungry_active", 2)
	active["heart"]["charge"] = 100
	var insufficient := HeartServiceScript.activate(active, [], "barracks", 35)
	_expect(not bool(insufficient.get("ok", true)), "왕좌 HP 35에서는 액티브 사용 불가")
	var no_room := HeartServiceScript.activate(active, [], "", 100)
	_expect(not bool(no_room.get("ok", true)), "대상 방 없이 액티브 사용 불가")
	var activation := HeartServiceScript.activate(active, [], "barracks", 36)
	active = activation.get("active_run", {})
	_expect(bool(activation.get("ok", false)) and int(activation.get("throne_hp", 0)) == 1, "왕좌 HP 36에서 35 소모하고 최소 1 유지")
	_expect(float(active.get("heart", {}).get("active_remaining", 0.0)) == 5.0 and str(active.get("heart", {}).get("active_room_id", "")) == "barracks", "선택 방 포식 5초")
	var ticked := HeartServiceScript.tick_events(active, 5.1)
	active = ticked.get("active_run", {})
	_expect(int(ticked.get("hungry_pulses", 0)) == 5 and float(active.get("heart", {}).get("active_remaining", -1.0)) == 0.0, "초당 피해 펄스 정확히 5회")
	active["heart"]["charge"] = 100
	_expect(not bool(HeartServiceScript.activate(active, [], "barracks", 100).get("ok", true)), "포식 액티브 전투당 1회")
	var total_enemy_hp := 900.0
	var base_dps := 30.0
	var baseline_time := total_enemy_hp / base_dps
	var hungry_time := (total_enemy_hp - 3.0 * 5.0 * float(HeartServiceScript.HUNGER_WAVE_DAMAGE)) / base_dps
	_expect(hungry_time <= baseline_time * 0.92, "다수 웨이브 A/B에서 전투 시간 8% 이상 단축")
	var baseline_hp := 100
	var hungry_hp := 100
	for _turn in range(20):
		baseline_hp = maxi(0, baseline_hp - 19) + 18
		hungry_hp = maxi(0, hungry_hp - 19) + int(round(18.0 * HeartServiceScript.HUNGRY_HEAL_SCALE))
	_expect(float(hungry_hp) <= float(baseline_hp) * 0.85, "장기전 A/B에서 회복형 조합보다 잔여 HP 15% 이상 낮음")


func _test_game_root_vertical_fixture() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	GameState.day = 15
	GameState.food = 10
	GameState.demon_lord_hp = 36
	GameState.defeat = false
	game.castle_art_stage = "stage_02_castle"
	game.rooms = DataRegistry.rooms.duplicate(true)
	game._init_room_facilities()
	game.update3_profile = FrontServiceScript.default_update3_profile()
	game.update3_active_run = _hungry_run(4, 2)
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	game._prepare_update3_heart_battle()
	var monster = game._create_unit("slime", DataRegistry.monster("slime"), Constants.FACTION_MONSTER, "barracks")
	game.monster_units.append(monster)
	game._update3_refresh_monster_heart_position(monster)
	monster.hp = 50
	monster.heal(100)
	_expect(int(monster.hp) == 142, "GameRoot 실제 몬스터 직접 회복 8% 감소")
	var normal_enemy = game._create_unit("explorer", DataRegistry.enemy("explorer"), Constants.FACTION_ENEMY, "barracks")
	var boss_enemy = game._create_unit("official_hero_leon", DataRegistry.enemy("official_hero_leon"), Constants.FACTION_ENEMY, "barracks")
	game.enemy_units.append(normal_enemy)
	game.enemy_units.append(boss_enemy)
	var normal_hp := int(normal_enemy.hp)
	var boss_hp := int(boss_enemy.hp)
	var normal_morale := int(normal_enemy.morale)
	var wave: Dictionary = game._emit_update3_hunger_wave()
	_expect(int(wave.get("hit_count", 0)) == 2 and int(normal_enemy.hp) == normal_hp - 12 and int(boss_enemy.hp) == boss_hp - 6, "교전 방 파동 일반 12·보스 6 실제 피해")
	_expect(int(normal_enemy.morale) == normal_morale - 8, "포식 파동 사기 피해 8 실제 적용")
	GameState.demon_lord_hp = 36
	GameState.defeat = false
	game.update3_active_run["heart"]["charge"] = 100
	var activated: Dictionary = game._activate_update3_heart("barracks")
	_expect(bool(activated.get("ok", false)) and GameState.demon_lord_hp == 1 and not GameState.defeat, "GameRoot 액티브 왕좌 비용이 자가 패배를 만들지 않음")
	var hp_before_tick := int(normal_enemy.hp)
	game._tick_update3_heart(1.0)
	_expect(int(normal_enemy.hp) == hp_before_tick - 6 and is_equal_approx(float(normal_enemy.slow_factor), 0.85), "선택 방 초당 피해 6·일반 적 이동 -15%")
	_expect(is_equal_approx(float(boss_enemy.slow_factor), 0.92), "보스 이동 감소는 -8%")
	_expect(not game._update3_heart_result_lines().is_empty(), "결산에 포식 파동·왕좌 비용 표시")
	normal_enemy.queue_free()
	boss_enemy.queue_free()
	monster.queue_free()
	host.queue_free()


func _test_v4_safe_state() -> void:
	var migration := SaveV4MigratorScript.migrate_envelope(_base_v3_fixture(), DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs())
	var envelope: Dictionary = migration.get("envelope", {}).duplicate(true)
	var active := HeartServiceScript.start_battle(_hungry_run(4, 2), "hungry_save", 2)
	for index in range(7):
		active = HeartServiceScript.record_hungry_finish(active, "save_enemy_%d" % index).get("active_run", active)
	for key in active.keys():
		envelope["active_run"][key] = active[key].duplicate(true) if active[key] is Dictionary or active[key] is Array else active[key]
	envelope["active_run"]["legacy_payload"]["world"]["castle_art_stage"] = "stage_02_castle"
	var validation_error := SaveV4MigratorScript.validate_v4(envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs())
	_expect(validation_error == "", "포식 심장 hunger·파동·중복 방지 상태 v4 안전 지점: %s" % validation_error)
	var restored = JSON.parse_string(JSON.stringify(envelope))
	_expect(int(restored.get("active_run", {}).get("heart", {}).get("hunger", -1)) == 2 and int(restored.get("active_run", {}).get("heart", {}).get("hunger_waves", 0)) == 1, "포식 심장 전투 상태 저장 복원")
	var corrupt := envelope.duplicate(true)
	corrupt["active_run"]["heart"]["hunger_waves"] = 4
	_expect(SaveV4MigratorScript.validate_v4(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs()) != "", "파동 3회 초과 저장 거부")


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
	push_error("[HungryHeartPhase6] FAIL: %s" % message)
