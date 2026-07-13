extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const DamageService = preload("res://scripts/combat/DamageService.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_contract()
	await _test_combat_vertical_slice()
	print("KOKO_PHASE13_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_data_contract() -> void:
	var koko: Dictionary = DataRegistry.monster("graveyard_hound")
	_expect(not koko.is_empty() and DataRegistry.update3_monster_extensions.has("graveyard_hound"), "3차 확장과 실전 몬스터 카탈로그에 코코 로드")
	_expect(str(koko.get("character_id", "")) == "CHR_KOKO" and str(koko.get("instance_id", "")) == "monster_koko", "코코 캐릭터·개체 ID 연결")
	_expect(int(koko.get("max_hp", 0)) == 168 and int(koko.get("atk", 0)) == 14 and int(koko.get("def", 0)) == 5, "코코 HP 168·ATK 14·DEF 5")
	_expect(int(koko.get("move_speed", 0)) == 152 and int(koko.get("attack_range", 0)) == 47 and is_equal_approx(float(koko.get("attack_interval", 0.0)), 0.9), "코코 이동 152·사거리 47·공격 간격 0.90")
	_expect(int(koko.get("int", 0)) == 17 and int(koko.get("loyalty", 0)) == 76, "코코 지능 17·충성 76")
	_expect(koko.get("skills", []) == ["scent_lock", "home_guard_bark", "return_scent"] and str(koko.get("behavior_handler", "")) == "danger_tracker", "액티브 2개·패시브 1개와 데이터 행동 처리기")
	_expect(DataRegistry.character("CHR_KOKO").get("unit_ref", {}).get("id", "") == "graveyard_hound", "CHR_KOKO 종족 참조")
	_expect(DataRegistry.monster_instance("monster_koko").get("equipped_skill_ids", []).size() == 2, "monster_koko 기본 장착 스킬 2개")
	_expect(not bool(koko.get("placeholder_art", true)) and FileAccess.file_exists(str(koko.get("sprite", ""))), "최종 코코 프레임 표시·파일 존재")
	_expect(DataRegistry.memory_entry("koko_bone_not_food").get("monster_id", "") == "graveyard_hound", "코코 개인 유대 기억 연결")
	_expect(DataRegistry.specialization("koko_bounty_sniffer").get("monster_id", "") == "graveyard_hound" and DataRegistry.specialization("koko_throne_shepherd").get("monster_id", "") == "graveyard_hound", "코코 전술 특화 2종")
	var scent: Dictionary = DataRegistry.skill("scent_lock")
	_expect(is_equal_approx(float(scent.get("duration", 0.0)), 7.0) and is_equal_approx(float(scent.get("tracking_move_multiplier", 0.0)), 1.25) and is_equal_approx(float(scent.get("marked_basic_attack_multiplier", 0.0)), 1.10), "냄새 고정 7초·추적 이동 +25%·기본 공격 +10%")
	var bark: Dictionary = DataRegistry.skill("home_guard_bark")
	_expect(int(bark.get("radius", 0)) == 145 and int(bark.get("max_normal_targets", 0)) == 2 and is_equal_approx(float(bark.get("normal_taunt_seconds", 0.0)), 2.5), "집 지키는 짖음 반경·일반 대상 수·도발 시간")
	var returning: Dictionary = DataRegistry.skill("return_scent")
	_expect(is_equal_approx(float(returning.get("duration", 0.0)), 4.0) and is_equal_approx(float(returning.get("return_move_multiplier", 0.0)), 1.35) and is_equal_approx(float(returning.get("damage_reduction", 0.0)), 0.08), "돌아가는 냄새 4초·복귀 이동 +35%·피해 -8%")


func _test_combat_vertical_slice() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.current_screen = Constants.SCREEN_COMBAT
	game.combat_paused = false
	game.monster_units.clear()
	game.enemy_units.clear()
	game.monster_roster["graveyard_hound"] = {"level": 1, "exp": 0, "room": "barracks", "specialization_id": "", "promotion_id": "", "bond": 0, "bond_rank": 0, "unlocked_memory_ids": []}
	GameState.mana = 100
	var entrance: Vector2 = game.graph.center("entrance")
	var barracks: Vector2 = game.graph.center("barracks")
	var recovery: Vector2 = game.graph.center("recovery")
	var throne: Vector2 = game.graph.center("throne")
	var koko = _add_monster(game, "graveyard_hound", barracks, "barracks")
	koko.assigned_room = "barracks"
	var engineer = _add_enemy(game, "engineer", recovery, "recovery")
	var target = game.combat_scene._danger_tracker_target(koko)
	_expect(target == engineer, "공병을 일반 적보다 우선 추적 대상으로 선택")
	var mark: Dictionary = game.combat_scene.perform_koko_scent_lock(koko, engineer)
	_expect(bool(mark.get("ok", false)) and koko.scent_mark_target == engineer and is_equal_approx(koko.scent_mark_timer, 7.0), "공병 냄새 고정 7초")
	_expect(is_equal_approx(koko.scent_tracking_move_multiplier, 1.25) and is_equal_approx(koko.attack_multiplier_against(engineer), 1.10), "표식 방향 이동·기본 공격 보너스 상태")
	game.combat_scene._update_danger_tracker(koko)
	_expect(koko.scent_tracking_active and not koko.path_points.is_empty() and koko.status_line().contains("냄새 고정"), "먼 표식을 향해 방을 비우는 추격 경로·위험 대가가 실제로 발생")
	var base_target = _add_enemy(game, "explorer", entrance, "entrance")
	var marked_target = _add_enemy(game, "explorer", entrance, "entrance")
	koko.global_position = entrance
	koko.current_room = "entrance"
	base_target.global_position = entrance + Vector2(30, 0)
	marked_target.global_position = entrance + Vector2(30, 0)
	koko.scent_mark_timer = 0.0
	koko.scent_mark_target = null
	var base_hp := int(base_target.hp)
	base_target.receive_damage(DamageService.compute(koko, base_target, 1.0))
	var base_damage := base_hp - int(base_target.hp)
	game.combat_scene.perform_koko_scent_lock(koko, marked_target)
	var marked_hp := int(marked_target.hp)
	var preferred = koko.preferred_attack_target([base_target, marked_target], koko.attack_range)
	var marked_attack := maxi(1, int(round(float(DamageService.compute(koko, marked_target, 1.0)) * koko.attack_multiplier_against(marked_target))))
	marked_target.receive_damage(marked_attack)
	var marked_damage := marked_hp - int(marked_target.hp)
	_expect(preferred == marked_target and marked_damage > base_damage and marked_target.hp < marked_hp and base_target.hp == base_hp - base_damage, "표식 대상 우선 공격과 기본 공격 피해 +10%")
	var thief = _add_enemy(game, "thief", recovery, "recovery")
	game.thief_steal_timers[thief] = -999.0
	target = game.combat_scene._danger_tracker_target(koko)
	_expect(target == thief, "보물을 훔쳐 탈출 중인 도둑을 모든 표식보다 최우선")
	var throne_enemy = _add_enemy(game, "explorer", throne, "throne")
	game.thief_steal_timers[thief] = 0.0
	target = game.combat_scene._danger_tracker_target(koko)
	_expect(target == throne_enemy, "현재 표식이 보스가 아니면 왕좌 침입 적으로 긴급 전환")
	var home_enemy = _add_enemy(game, "explorer", barracks + Vector2(20, 0), "barracks")
	target = game.combat_scene._danger_tracker_target(koko)
	_expect(target == home_enemy, "배치 방 침입은 먼 표식 추적보다 우선")
	game.enemy_units.erase(home_enemy)
	home_enemy.queue_free()
	koko.scent_mark_target = engineer
	koko.scent_mark_timer = 7.0
	engineer.receive_damage(9999)
	game.combat_scene._update_danger_tracker(koko)
	_expect(is_equal_approx(koko.return_scent_timer, 4.0) and is_equal_approx(koko.return_scent_move_multiplier, 1.35), "표식 대상 처치 후 4초·35% 가속 복귀 시작")
	var return_path_size: int = koko.path_points.size()
	game.combat_scene._update_danger_tracker(koko)
	_expect(koko.path_points.size() == return_path_size and return_path_size > 0, "반복 갱신에도 복귀 경로가 증식하거나 루프하지 않음")
	var hp_before_return_hit := int(koko.hp)
	koko.receive_damage(100)
	_expect(hp_before_return_hit - koko.hp == 92, "복귀 중 받는 피해 8% 감소")
	koko.current_room = "barracks"
	koko.global_position = barracks
	game.combat_scene._update_danger_tracker(koko)
	_expect(koko.return_scent_timer == 0.0 and koko.path_points.is_empty(), "배치 방 도착 즉시 복귀 상태와 경로 종료")
	var normal_a = _add_enemy(game, "explorer", barracks + Vector2(30, 0), "barracks")
	var normal_b = _add_enemy(game, "investigator", barracks + Vector2(45, 0), "barracks")
	var normal_c = _add_enemy(game, "shieldbearer", barracks + Vector2(60, 0), "barracks")
	var boss = _add_enemy(game, "official_hero_leon", barracks + Vector2(75, 0), "barracks")
	var bark: Dictionary = game.combat_scene.perform_koko_home_guard_bark(koko)
	_expect(int(bark.get("normal_targets", 0)) == 2 and int(bark.get("boss_targets", 0)) == 1, "일반 적 최대 2명 도발·보스 1명 우선도 변경")
	_expect(normal_a.threat_unit == koko and normal_b.threat_unit == koko and normal_c.threat_unit != koko and is_equal_approx(boss.threat_timer, 1.5), "가까운 일반 적 2명 2.5초·보스 1.5초 규칙")
	_expect(koko.duo_barrier == 18, "짖음 사용 시 코코 보호막 18")
	var tracker_stats: Dictionary = DataRegistry.monster("graveyard_hound")
	var engineer_stats: Dictionary = DataRegistry.enemy("engineer")
	var baseline_time: float = game.combat_scene.estimate_tracker_intercept_seconds(tracker_stats, engineer_stats, 400.0, false)
	var marked_time: float = game.combat_scene.estimate_tracker_intercept_seconds(tracker_stats, engineer_stats, 400.0, true)
	var time_reduction: float = 1.0 - marked_time / baseline_time
	_expect(time_reduction >= 0.18, "공병 표적 처치 시간 %.1f%% 단축으로 18%% 이상" % (time_reduction * 100.0))
	var armored_stats := {"max_hp": 195, "def": 12}
	var armored_base: float = game.combat_scene.estimate_tracker_intercept_seconds(tracker_stats, armored_stats, 400.0, false)
	var armored_marked: float = game.combat_scene.estimate_tracker_intercept_seconds(tracker_stats, armored_stats, 400.0, true)
	_expect(1.0 - armored_marked / armored_base < 0.08, "고방어 전열에는 피해 반올림 때문에 이득이 8% 미만으로 제한")
	thief.hp = 0
	thief.down = true
	koko.scent_mark_target = thief
	koko.scent_mark_timer = 4.0
	game.combat_scene._update_danger_tracker(koko)
	koko.current_room = "barracks"
	game.combat_scene._update_danger_tracker(koko)
	game.enemy_units.erase(throne_enemy)
	throne_enemy.queue_free()
	target = game.combat_scene._danger_tracker_target(koko)
	_expect(target != thief and target != null, "도둑 처리·복귀 뒤 남은 적을 찾아 일반 전투로 복귀")
	koko.apply_seal_chain(2.2, 1.5, 5.0)
	var sealed_position: Vector2 = koko.global_position
	koko.set_path([sealed_position + Vector2(100, 0)])
	koko._physics_process(0.1)
	_expect(koko.global_position.distance_to(sealed_position) < 0.01 and koko.active_skills_locked(), "코코는 봉인 사슬의 이동·스킬 억제에 취약")
	game.combat_scene.clear_effects()
	for unit in game.monster_units + game.enemy_units:
		if is_instance_valid(unit):
			unit.queue_free()
	host.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _add_monster(game: Node, species_id: String, position: Vector2, room_id: String):
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
		return
	failed = true
	push_error("[KokoPhase13] FAIL: %s" % message)
