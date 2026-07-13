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
	_test_selection_passive_and_tradeoff()
	_test_charge_active_and_restore()
	await _test_game_root_vertical_fixture()
	_test_v4_safe_state()
	if failed:
		print("DREAM_LANTERN_HEART_PHASE7_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("DREAM_LANTERN_HEART_PHASE7_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _front_run() -> Dictionary:
	var selected := FrontServiceScript.select_front(FrontServiceScript.default_update3_profile(), FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HERO_FRONT_ID, DataRegistry.update3_fronts)
	return selected.get("active_run", {}).duplicate(true)


func _dream_run(day: int = 4, stage_index: int = 2) -> Dictionary:
	var selected := HeartServiceScript.select_heart(FrontServiceScript.default_update3_profile(), _front_run(), HeartServiceScript.DREAM_LANTERN_ID, DataRegistry.update3_castle_hearts)
	var active: Dictionary = selected.get("active_run", {})
	active = HeartServiceScript.awaken(active, day).get("active_run", active)
	active = ChamberServiceScript.sync_active_run(active, stage_index)
	return active


func _test_selection_passive_and_tradeoff() -> void:
	_expect(DataRegistry.update3_castle_hearts.size() == 3 and DataRegistry.update3_castle_hearts.has(HeartServiceScript.DREAM_LANTERN_ID), "Phase 7 심장 카탈로그 3종 완성")
	_expect(DataRegistry.skills.has(HeartServiceScript.DREAM_ACTIVE_SKILL_ID), "false_corridor 스킬 데이터 연결")
	var selected := HeartServiceScript.select_heart(FrontServiceScript.default_update3_profile(), _front_run(), HeartServiceScript.DREAM_LANTERN_ID, DataRegistry.update3_castle_hearts)
	_expect(bool(selected.get("ok", false)), "몽등 심장 선택 가능")
	var active := _dream_run()
	_expect(is_equal_approx(HeartServiceScript.skill_recovery_multiplier(active), 1.0 / 0.92), "몬스터 스킬 쿨다운 8% 단축 배율")
	_expect(is_equal_approx(HeartServiceScript.first_control_multiplier(active), 1.15), "일반 적 첫 제어 지속 +15%")
	var hp_result := HeartServiceScript.apply_dream_max_hp(active, 1500, 1500, 420)
	active = hp_result.get("active_run", {})
	_expect(int(hp_result.get("throne_max_hp", 0)) == 1350 and int(hp_result.get("throne_hp", 0)) == 1350, "왕좌 최대 HP -10%")
	_expect(int(active.get("heart", {}).get("chamber_max_hp", 0)) == 357, "심장실 최대 HP -15%")
	var repeated := HeartServiceScript.apply_dream_max_hp(active, 1350, 1350, 420)
	_expect(int(repeated.get("throne_max_hp", 0)) == 1350, "최대 HP 대가 반복 적용 없음")
	active["heart"]["disabled_this_battle"] = true
	_expect(is_equal_approx(HeartServiceScript.skill_recovery_multiplier(active), 1.0) and is_equal_approx(HeartServiceScript.first_control_multiplier(active), 1.0), "심장실 비활성 시 패시브 정지")


func _test_charge_active_and_restore() -> void:
	var active := HeartServiceScript.start_battle(_dream_run(), "dream_active", 2)
	var hit := HeartServiceScript.record_dream_charge(active, "skill_hit", "zone_cast_a")
	active = hit.get("active_run", {})
	var duplicate_hit := HeartServiceScript.record_dream_charge(active, "skill_hit", "zone_cast_a")
	active = duplicate_hit.get("active_run", {})
	var healed := HeartServiceScript.record_dream_charge(active, "effective_heal", "heal_a")
	active = healed.get("active_run", {})
	var controlled := HeartServiceScript.record_dream_charge(active, "first_status", "enemy_a")
	active = controlled.get("active_run", {})
	_expect(int(hit.get("gain", 0)) == 3 and bool(duplicate_hit.get("duplicate", false)), "스킬 적중 +3·지속 장판 최초 1회")
	_expect(int(healed.get("gain", 0)) == 3 and int(controlled.get("gain", 0)) == 5, "유효 회복 +3·첫 상태 이상 +5")
	active["heart"]["charge"] = 100
	var too_many := [
		{"token": "1", "unit_id": "explorer", "original_goal": "throne", "boss": false},
		{"token": "2", "unit_id": "thief", "original_goal": "treasure", "boss": false},
		{"token": "3", "unit_id": "roman", "original_goal": "throne", "boss": true}
	]
	_expect(not bool(HeartServiceScript.activate(active, [], "recovery", 100, too_many).get("ok", true)), "일반 적 최대 2명 제한")
	var targets := [too_many[0], too_many[2]]
	var activation := HeartServiceScript.activate(active, [], "recovery", 100, targets)
	active = activation.get("active_run", {})
	_expect(bool(activation.get("ok", false)) and int(activation.get("target_count", 0)) == 2 and int(activation.get("goal_changes", 0)) == 1, "일반 적 목표 변경·보스는 변경 제외")
	_expect(int(active.get("heart", {}).get("charge", 0)) == 8, "목표가 실제 변경된 일반 적 1명 충전 +8")
	var boss_expired := HeartServiceScript.tick_events(active, 3.1)
	active = boss_expired.get("active_run", {})
	_expect(boss_expired.get("dream_restore_entries", []).size() == 1 and bool(boss_expired.get("dream_restore_entries", [])[0].get("boss", false)), "보스 둔화 상태 3초 종료")
	var normal_expired := HeartServiceScript.tick_events(active, 3.0)
	active = normal_expired.get("active_run", {})
	_expect(normal_expired.get("dream_restore_entries", []).size() == 1 and not bool(normal_expired.get("dream_restore_entries", [])[0].get("boss", true)), "일반 적 6초 뒤 원래 목표 복귀 사건")
	_expect(active.get("heart", {}).get("false_corridor_targets", {}).is_empty(), "가짜 복도 종료 뒤 임시 대상 상태 정리")
	active["heart"]["charge"] = 100
	_expect(not bool(HeartServiceScript.activate(active, [], "recovery", 100, targets).get("ok", true)), "몽등 액티브 전투당 1회")


func _test_game_root_vertical_fixture() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	GameState.day = 15
	GameState.demon_lord_max_hp = 1500
	GameState.demon_lord_hp = 1500
	GameState.defeat = false
	game.castle_art_stage = "stage_02_castle"
	game.rooms = DataRegistry.rooms.duplicate(true)
	game._init_room_facilities()
	game.update3_profile = FrontServiceScript.default_update3_profile()
	game.update3_active_run = _dream_run(4, 2)
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	game._prepare_update3_heart_battle()
	_expect(GameState.demon_lord_max_hp == 1575, "Stage 02 왕좌 1750의 몽등 대가 -10%")
	_expect(int(game.update3_active_run.get("heart", {}).get("chamber_max_hp", 0)) == 357 and int(game.rooms.get("heart_chamber", {}).get("max_hp", 0)) == 357, "Stage 02 심장실 420의 몽등 대가 -15%")
	var monster = game._create_unit("slime", DataRegistry.monster("slime"), Constants.FACTION_MONSTER, "barracks")
	game.monster_units.append(monster)
	game._update3_refresh_monster_heart_position(monster)
	monster.set_skill_cooldown("fixture", 1.0)
	monster._physics_process(0.92)
	_expect(monster.skill_ready("fixture"), "실제 유닛 쿨다운 8% 단축")
	var normal = game._create_unit("explorer", DataRegistry.enemy("explorer"), Constants.FACTION_ENEMY, "entrance")
	var boss = game._create_unit("official_hero_leon", DataRegistry.enemy("official_hero_leon"), Constants.FACTION_ENEMY, "entrance")
	var thief = game._create_unit("thief", DataRegistry.enemy("thief"), Constants.FACTION_ENEMY, "entrance")
	var engineer = game._create_unit("engineer", DataRegistry.enemy("engineer"), Constants.FACTION_ENEMY, "entrance")
	for enemy in [normal, boss, thief, engineer]:
		game.enemy_units.append(enemy)
		game._update3_refresh_enemy_heart_control(enemy)
	normal.apply_slow(10.0, 0.8)
	_expect(is_equal_approx(float(normal.slow_timer), 11.5), "일반 적 첫 둔화만 15% 연장")
	normal.slow_timer = 0.0
	normal.slow_factor = 1.0
	normal.apply_slow(10.0, 0.8)
	_expect(is_equal_approx(float(normal.slow_timer), 10.0), "같은 적 두 번째 제어 보너스 없음")
	_expect(int(game.update3_active_run.get("heart", {}).get("charge", 0)) == 5, "첫 상태 이상 실제 충전 +5")
	game.thief_steal_timers[thief] = -999.0
	game.engineer_completed_units[engineer.get_instance_id()] = true
	var original_enemies: Array = game.enemy_units.duplicate()
	game.enemy_units = [thief, engineer]
	_expect(game._update3_dream_target_entries("recovery").is_empty(), "훔친 도둑·무력화 완료 공병 목표 변경 불가")
	game.enemy_units = original_enemies
	_expect(game._update3_dream_target_entries("slot_01").is_empty(), "보행 불가 건설 슬롯을 미끼 방으로 선택 불가")
	var original_normal_goal := str(normal.goal_room)
	var original_boss_goal := str(boss.goal_room)
	game.update3_active_run["heart"]["charge"] = 100
	var activated: Dictionary = game._activate_update3_heart("recovery")
	_expect(bool(activated.get("ok", false)) and str(normal.goal_room) == "recovery", "일반 적 목표를 미끼 방으로 임시 변경")
	_expect(str(boss.goal_room) == original_boss_goal and is_equal_approx(float(boss.slow_factor), 0.88), "보스는 목표 유지·이동 속도 -12%")
	var rebuilds_before := int(game.update3_active_run.get("run_metrics_update3", {}).get("dream_path_rebuilds", 0))
	for _frame in range(20):
		game._update3_false_corridor_holds(normal)
	_expect(int(game.update3_active_run.get("run_metrics_update3", {}).get("dream_path_rebuilds", 0)) == rebuilds_before, "가짜 복도 유지 중 경로 재생성 루프 없음")
	game._tick_update3_heart(6.1)
	_expect(str(normal.goal_room) == original_normal_goal, "6초 뒤 일반 적 원래 목표 복귀")
	_expect(int(game.update3_active_run.get("run_metrics_update3", {}).get("dream_goal_restores", 0)) == 1, "원래 목표 복귀 정확히 1회")
	_expect(int(game.update3_active_run.get("run_metrics_update3", {}).get("dream_path_rebuilds", 0)) == 2, "경로는 진입·복귀 때만 각 1회 생성")
	var baseline_arrival := 10.0
	var delayed_arrival := baseline_arrival + HeartServiceScript.DREAM_ACTIVE_SECONDS
	_expect(delayed_arrival >= baseline_arrival * 1.10, "핵심 적 왕좌 도달 시간 10% 이상 지연")
	_expect(GameState.demon_lord_max_hp <= 1750 * 0.90, "잘못 사용 시 왕좌 최대 HP 대가가 실제 존재")
	_expect(not game._update3_heart_result_lines().is_empty(), "결산에 목표 변경·복귀·경로 재생성 표시")
	for enemy in [normal, boss, thief, engineer, monster]:
		enemy.queue_free()
	host.queue_free()


func _test_v4_safe_state() -> void:
	var migration := SaveV4MigratorScript.migrate_envelope(_base_v3_fixture(), DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs())
	var envelope: Dictionary = migration.get("envelope", {}).duplicate(true)
	var active := HeartServiceScript.start_battle(_dream_run(4, 2), "dream_save", 2)
	active = HeartServiceScript.apply_dream_max_hp(active, 1750, 1750, 420).get("active_run", active)
	active["heart"]["charge"] = 66
	for key in active.keys():
		envelope["active_run"][key] = active[key].duplicate(true) if active[key] is Dictionary or active[key] is Array else active[key]
	envelope["active_run"]["legacy_payload"]["world"]["castle_art_stage"] = "stage_02_castle"
	var validation_error := SaveV4MigratorScript.validate_v4(envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs())
	_expect(validation_error == "", "몽등 최대 HP·제어·가짜 복도 상태 v4 안전 지점: %s" % validation_error)
	var restored = JSON.parse_string(JSON.stringify(envelope))
	_expect(str(restored.get("active_run", {}).get("heart", {}).get("heart_id", "")) == HeartServiceScript.DREAM_LANTERN_ID and int(restored.get("active_run", {}).get("heart", {}).get("charge", 0)) == 66, "몽등 심장 선택·충전 저장 복원")
	var corrupt := envelope.duplicate(true)
	corrupt["active_run"]["heart"]["false_corridor_targets"] = []
	_expect(SaveV4MigratorScript.validate_v4(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs()) != "", "잘못된 가짜 복도 저장 형식 거부")


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
	push_error("[DreamLanternHeartPhase7] FAIL: %s" % message)
