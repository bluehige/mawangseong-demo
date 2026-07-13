extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const HeartChamberServiceScript = preload("res://scripts/systems/hearts/HeartChamberService.gd")
const CastleHeartServiceScript = preload("res://scripts/systems/hearts/CastleHeartService.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_contract()
	_test_charge_suppression_service()
	await _test_choir_vertical_slice()
	print("CHOIR_EXORCIST_PHASE17B_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_data_contract() -> void:
	var enemy: Dictionary = DataRegistry.enemy("choir_exorcist")
	var skill: Dictionary = DataRegistry.skill("purifying_hymn")
	_expect(not enemy.is_empty() and DataRegistry.update3_enemy_extensions.has("choir_exorcist"), "3차 확장과 실전 적 카탈로그에 성가 퇴마사 로드")
	_expect(str(enemy.get("character_id", "")) == "CHR_CHOIR_EXORCIST" and str(enemy.get("behavior_handler", "")) == "choir_exorcist", "캐릭터·데이터 행동 처리기 연결")
	_expect(str(enemy.get("goal_type", "")) == "heart" and enemy.get("front_tags", []).has("holy_purification"), "성광 정화 전선·심장 목표")
	_expect(is_equal_approx(float(enemy.get("threat", 0.0)), 1.5), "위협도 1.50")
	_expect(int(enemy.get("max_hp", 0)) == 108 and int(enemy.get("atk", 0)) == 7 and int(enemy.get("def", 0)) == 3, "HP 108·ATK 7·DEF 3")
	_expect(int(enemy.get("move_speed", 0)) == 105 and int(enemy.get("attack_range", 0)) == 170 and is_equal_approx(float(enemy.get("attack_interval", 0.0)), 1.4), "이동 105·사거리 170·공격 간격 1.40")
	_expect(int(enemy.get("morale", 0)) == 88 and int(enemy.get("exp", 0)) == 46 and int(enemy.get("infamy", 0)) == 16, "사기·경험치·악명 기준치")
	_expect(is_equal_approx(float(skill.get("cast_seconds", 0.0)), 1.2) and int(skill.get("radius", 0)) == 180 and int(skill.get("max_targets", 0)) == 3, "정화 성가 1.2초·반경 180·최대 3명")
	_expect(int(skill.get("debuffs_removed_per_target", 0)) == 1 and is_equal_approx(float(skill.get("cooldown", 0.0)), 11.0), "대상별 약화 1개 제거·재사용 11초")
	_expect(is_equal_approx(float(skill.get("heart_charge_suppression_multiplier", 1.0)), 0.0) and is_equal_approx(float(skill.get("heart_charge_suppression_seconds", 0.0)), 4.0), "심장 충전 획득 -100%·4초")
	_expect(bool(skill.get("interruptible", false)) and enemy.get("counter_hints", []).size() >= 3, "시전 중단 가능·루미/추격/베베/심장실 수비 대응 안내")
	_expect(not bool(enemy.get("placeholder_art", true)) and FileAccess.file_exists(str(enemy.get("sprite", ""))) and FileAccess.file_exists(str(skill.get("icon", ""))), "최종 적 프레임·스킬 아이콘 존재")
	_expect(DataRegistry.character("CHR_CHOIR_EXORCIST").get("unit_ref", {}).get("id", "") == "choir_exorcist", "캐릭터 카탈로그 역참조")


func _test_charge_suppression_service() -> void:
	var stone := _heart_run(CastleHeartServiceScript.STONEBONE_ID, 37)
	stone = CastleHeartServiceScript.suppress_charge(stone, 4.0)
	var stone_result := CastleHeartServiceScript.record_charge(stone, "facility_damage_taken", 50, "stone_suppressed", 1.0)
	_expect(int(stone_result.get("gain", -1)) == 0 and int(stone_result.get("active_run", {}).get("heart", {}).get("charge", -1)) == 37, "석골 심장 기존 충전 유지·신규 충전 0")
	var hungry := CastleHeartServiceScript.suppress_charge(_heart_run(CastleHeartServiceScript.HUNGRY_MAW_ID, 37), 4.0)
	var hungry_damage := CastleHeartServiceScript.record_hungry_damage(hungry, 70, "hungry_suppressed")
	var hungry_finish := CastleHeartServiceScript.record_hungry_finish(hungry_damage.get("active_run", {}), "enemy_suppressed")
	_expect(int(hungry_damage.get("gain", -1)) == 0 and int(hungry_finish.get("charge_gain", -1)) == 0 and int(hungry_finish.get("active_run", {}).get("heart", {}).get("charge", -1)) == 37, "포식 심장 피해·처치 충전 모두 0, 기존 37 유지")
	var dream := CastleHeartServiceScript.suppress_charge(_heart_run(CastleHeartServiceScript.DREAM_LANTERN_ID, 37), 4.0)
	var dream_result := CastleHeartServiceScript.record_dream_charge(dream, "first_status", "dream_suppressed")
	_expect(int(dream_result.get("gain", -1)) == 0 and int(dream_result.get("active_run", {}).get("heart", {}).get("charge", -1)) == 37, "몽등 심장 상태 충전 0, 기존 37 유지")
	var ticked: Dictionary = CastleHeartServiceScript.tick_events(stone_result.get("active_run", {}), 4.01).get("active_run", {})
	var resumed := CastleHeartServiceScript.record_charge(ticked, "facility_damage_taken", 50, "stone_resumed", 5.1)
	_expect(not CastleHeartServiceScript.charge_suppressed(ticked) and int(resumed.get("gain", 0)) > 0, "4초 종료 뒤 심장 충전 자동 재개")


func _test_choir_vertical_slice() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	_prepare_stage2_heart(game)
	game.current_screen = Constants.SCREEN_COMBAT
	game.combat_paused = false
	game.monster_units.clear()
	game.enemy_units.clear()
	var seal_role := str(DataRegistry.enemy("seal_chainbearer").get("role", ""))
	var guard_role := str(DataRegistry.enemy("reliquary_guard").get("role", ""))
	var choir_role := str(DataRegistry.enemy("choir_exorcist").get("role", ""))
	_expect(seal_role != guard_role and guard_role != choir_role and seal_role != choir_role, "성광 적 3종의 봉인·저항 전열·정화/심장 역할 비중복")
	var seal_choir: Dictionary = game.combat_scene.evaluate_update3_counter_combo(["seal_chainbearer", "choir_exorcist"])
	var guard_choir: Dictionary = game.combat_scene.evaluate_update3_counter_combo(["reliquary_guard", "choir_exorcist"])
	_expect(bool(seal_choir.get("allowed", false)) and is_equal_approx(float(seal_choir.get("total_threat", 0.0)), 3.30), "봉인 사슬병+성가 퇴마사 조합 threat 3.30 허용")
	_expect(bool(guard_choir.get("allowed", false)) and is_equal_approx(float(guard_choir.get("total_threat", 0.0)), 3.80), "성물 수호기사+성가 퇴마사 조합 threat 상한 3.80 허용")
	var triple: Dictionary = game.combat_scene.evaluate_update3_counter_combo(["seal_chainbearer", "reliquary_guard", "choir_exorcist"])
	_expect(not bool(triple.get("allowed", true)) and str(triple.get("reason", "")).contains("최대 2종"), "성광 카운터 3종 동시 조합 차단")
	game.combat_scene.spawn_enemy("seal_chainbearer")
	game.combat_scene.spawn_enemy("reliquary_guard")
	game.combat_scene.spawn_enemy("choir_exorcist")
	_expect(game.enemy_units.size() == 2 and game.enemy_units.all(func(unit): return str(unit.unit_id) != "choir_exorcist"), "실제 증원에서도 카운터 적 최대 2종·세 번째 유형 보류")
	for counter_probe in game.enemy_units:
		counter_probe.queue_free()
	game.enemy_units.clear()
	game.combat_scene.spawn_enemy("choir_exorcist")
	game.combat_scene.spawn_enemy("choir_exorcist")
	var first = game.enemy_units[0]
	var second = game.enemy_units[1]
	_expect(first.goal_room == "heart_chamber" and second.goal_room == "throne" and game.combat_scene.active_heart_target_count() == 1, "성가 퇴마사 둘 중 심장 목표는 동시에 한 명만 활성")
	first.down = true
	first.hp = 0
	game.combat_scene._refresh_heart_target_limit()
	_expect(second.goal_room == "heart_chamber" and game.combat_scene.active_heart_target_count() == 1, "첫 심장 목표 격퇴 뒤 대기 퇴마사 한 명만 승계")
	first.queue_free()
	second.queue_free()
	game.enemy_units.clear()
	var center: Vector2 = game.graph.center("heart_chamber")
	var exorcist = _add_enemy(game, "choir_exorcist", center, "heart_chamber")
	exorcist.goal_room = "heart_chamber"
	var allies: Array = []
	for index in range(4):
		var ally = _add_enemy(game, "reliquary_guard", center + Vector2(35 + index * 24, 0), "heart_chamber")
		ally.apply_armor_break(2, 6.0, "test_%d" % index)
		ally.apply_slow(6.0, 0.7)
		allies.append(ally)
	var charge_before := int(game.update3_active_run.get("heart", {}).get("charge", 0))
	var started: Dictionary = game.combat_scene.begin_purifying_hymn(exorcist)
	_expect(bool(started.get("ok", false)) and game.combat_scene.purifying_hymn_casts.size() == 1 and exorcist.status_line().contains("정화 성가"), "정화 성가 1.2초 월드·HUD 예고 시작")
	_expect(is_equal_approx(float(exorcist.skill_cooldowns.get("purifying_hymn", 0.0)), 11.0), "시전 시작 시 재사용 대기 11초")
	game.combat_scene._update_choir_exorcists(1.19)
	_expect(allies.all(func(ally): return ally.armor_break_amount == 2) and not CastleHeartServiceScript.charge_suppressed(game.update3_active_run), "1.19초에는 정화·심장 봉쇄 미발동")
	game.combat_scene._update_choir_exorcists(0.02)
	var cleansed_count := 0
	for ally in allies:
		if ally.armor_break_amount == 0:
			cleansed_count += 1
	_expect(cleansed_count == 3 and allies[3].armor_break_amount == 2 and allies[0].slow_timer > 0.0, "반경 180 아군 최대 3명에게서 약화 효과를 하나씩만 제거")
	_expect(game.combat_scene.purifying_hymn_completed == 1 and game.combat_scene.purifying_hymn_cleansed == 3, "정화 성가 완료·정화 수 집계")
	_expect(int(game.update3_active_run.get("heart", {}).get("charge", -1)) == charge_before and is_equal_approx(game._update3_heart_charge_suppression_remaining(), 4.0), "심장실 완료 시 기존 충전 유지·4초 봉쇄")
	var blocked_gain: int = int(game._record_update3_heart_charge("facility_damage_taken", 30, "blocked_runtime"))
	_expect(blocked_gain == 0 and int(game.update3_active_run.get("heart", {}).get("charge", -1)) == charge_before, "실전 GameRoot 충전 경로도 봉쇄 중 획득 0")
	game._tick_update3_heart(4.01)
	var resumed_gain: int = int(game._record_update3_heart_charge("facility_damage_taken", 30, "resumed_runtime"))
	_expect(game._update3_heart_charge_suppression_remaining() <= 0.0 and resumed_gain > 0, "실전 4초 종료 뒤 충전 재개")
	for ally in allies:
		ally.queue_free()
	game.enemy_units = [exorcist]
	exorcist.global_position = center
	exorcist.current_room = "heart_chamber"
	exorcist.goal_room = "heart_chamber"
	exorcist.attack_cooldown = 0.0
	exorcist.set_skill_cooldown("purifying_hymn", 99.0)
	var chamber_hp_before := int(game.update3_active_run.get("heart", {}).get("chamber_hp", 0))
	game.combat_scene.update_room_effects(0.1)
	var chamber_damage := chamber_hp_before - int(game.update3_active_run.get("heart", {}).get("chamber_hp", 0))
	_expect(chamber_damage >= 1 and chamber_damage <= int(exorcist.atk), "심장실 도달 퇴마사의 공격력 7이 심장 방어 적용 뒤 실제 %d 피해" % chamber_damage)
	var bebe = _add_monster(game, "ghost_housemaid", center + Vector2(20, 0), "heart_chamber")
	bebe.action_direction = Vector2.LEFT
	var interrupt_target = _add_enemy(game, "reliquary_guard", center + Vector2(45, 0), "heart_chamber")
	interrupt_target.apply_armor_break(2, 6.0, "interrupt_probe")
	exorcist.set_skill_cooldown("purifying_hymn", 0.0)
	game.combat_scene.begin_purifying_hymn(exorcist)
	var suppression_before_interrupt: float = float(game._update3_heart_charge_suppression_remaining())
	var broom: Dictionary = game.combat_scene.perform_bebe_broom(bebe)
	game.combat_scene._update_choir_exorcists(0.1)
	_expect(bool(broom.get("ok", false)) and int(broom.get("interrupted", 0)) >= 1 and game.combat_scene.purifying_hymn_casts.is_empty(), "베베 빗자루 소동으로 1.2초 정화 성가 중단")
	_expect(interrupt_target.armor_break_amount == 2 and is_equal_approx(game._update3_heart_charge_suppression_remaining(), suppression_before_interrupt), "중단된 성가는 정화·심장 봉쇄를 발동하지 않음")
	game.combat_scene.clear_effects()
	for unit in game.monster_units + game.enemy_units:
		if is_instance_valid(unit):
			unit.queue_free()
	host.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _prepare_stage2_heart(game: Node) -> void:
	var front_selected := FrontServiceScript.select_front(FrontServiceScript.default_update3_profile(), FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HERO_FRONT_ID, DataRegistry.update3_fronts)
	var heart_selected := CastleHeartServiceScript.select_heart(front_selected.get("profile", {}), front_selected.get("active_run", {}), CastleHeartServiceScript.STONEBONE_ID, DataRegistry.update3_castle_hearts)
	game.castle_art_stage = "stage_02_castle"
	game.rooms = DataRegistry.rooms.duplicate(true)
	game._init_room_facilities()
	game.update3_active_run = heart_selected.get("active_run", {}).duplicate(true)
	game.update3_active_run["heart"]["awakened"] = true
	game.update3_active_run["heart"]["charge"] = 37
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()


func _heart_run(heart_id: String, charge: int) -> Dictionary:
	return {"heart": {"heart_id": heart_id, "awakened": true, "disabled_this_battle": false, "charge": charge}, "run_metrics_update3": {}}


func _add_monster(game: Node, species_id: String, position: Vector2, room_id: String):
	if not game.monster_roster.has(species_id):
		game.monster_roster[species_id] = {"level": 1, "exp": 0, "room": room_id, "specialization_id": "", "promotion_id": "", "bond": 0, "bond_rank": 0, "unlocked_memory_ids": []}
	var unit = game._create_unit(species_id, DataRegistry.monster(species_id).duplicate(true), Constants.FACTION_MONSTER, room_id)
	unit.global_position = position
	game.monster_units.append(unit)
	return unit


func _add_enemy(game: Node, enemy_id: String, position: Vector2, room_id: String):
	var unit = game._create_unit(enemy_id, DataRegistry.enemy(enemy_id).duplicate(true), Constants.FACTION_ENEMY, room_id)
	unit.global_position = position
	game.enemy_units.append(unit)
	return unit


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[ChoirExorcistPhase17B] FAIL: %s" % message)
