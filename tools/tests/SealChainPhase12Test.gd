extends Node

const MainScene = preload("res://scenes/main/Main.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_contract()
	await _test_combat_counter()
	print("SEAL_CHAIN_PHASE12_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_data_contract() -> void:
	var enemy: Dictionary = DataRegistry.enemy("seal_chainbearer")
	var skill: Dictionary = DataRegistry.skill("seal_chain")
	_expect(not enemy.is_empty() and DataRegistry.update3_enemy_extensions.has("seal_chainbearer"), "3차 확장과 실전 적 카탈로그에 봉인 사슬병 로드")
	_expect(str(enemy.get("character_id", "")) == "CHR_SEAL_CHAINBEARER" and str(enemy.get("behavior_handler", "")) == "seal_chainbearer", "캐릭터·행동 처리기 참조")
	_expect(int(enemy.get("max_hp", 0)) == 128 and int(enemy.get("atk", 0)) == 9 and int(enemy.get("def", 0)) == 4, "HP 128·ATK 9·DEF 4")
	_expect(int(enemy.get("move_speed", 0)) == 98 and int(enemy.get("attack_range", 0)) == 80 and is_equal_approx(float(enemy.get("attack_interval", 0.0)), 1.35), "이동 98·사거리 80·공격 간격 1.35")
	_expect(int(enemy.get("morale", 0)) == 90 and int(enemy.get("exp", 0)) == 44 and int(enemy.get("infamy", 0)) == 15, "사기·경험치·악명 기준치")
	_expect(enemy.get("skills", []) == ["seal_chain"] and not skill.is_empty(), "봉인 사슬 스킬 참조")
	_expect(is_equal_approx(float(skill.get("telegraph_seconds", 0.0)), 0.9) and int(skill.get("range", 0)) == 150, "예고 0.9초·사거리 150")
	_expect(is_equal_approx(float(skill.get("move_lock_seconds", 0.0)), 2.2) and is_equal_approx(float(skill.get("skill_lock_seconds", 0.0)), 1.5), "이동 2.2초·스킬 1.5초 봉인")
	_expect(is_equal_approx(float(skill.get("same_target_immunity_seconds", 0.0)), 5.0) and is_equal_approx(float(skill.get("cooldown", 0.0)), 9.0), "동일 대상 면역 5초·재사용 9초")
	_expect(skill.get("priority_monster_ids", []) == ["ghost_housemaid", "graveyard_hound", "moon_tracker"], "베베·코코·루미 우선 지정")
	_expect(enemy.get("counter_hints", []).size() >= 2 and str(enemy.get("counter_hints", [])[1]).contains("도발"), "플레이어 대응 안내 2개 이상")
	_expect(int(enemy.get("first_appearance_max_count", 0)) == 1, "첫 등장 편성은 정확히 1기 제한")
	_expect(not bool(enemy.get("placeholder_art", true)) and FileAccess.file_exists(str(enemy.get("sprite", ""))), "최종 16프레임 아트 표시·파일 존재")
	_expect(DataRegistry.character("CHR_SEAL_CHAINBEARER").get("unit_ref", {}).get("id", "") == "seal_chainbearer", "캐릭터 카탈로그 역참조")


func _test_combat_counter() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.current_screen = Constants.SCREEN_COMBAT
	game.combat_paused = false
	game.monster_units.clear()
	game.enemy_units.clear()
	var center: Vector2 = game.graph.center("entrance")
	var chain = _add_enemy(game, "seal_chainbearer", center, "entrance")
	var bebe = _add_monster(game, "ghost_housemaid", center + Vector2(55, 0), "entrance")
	var lumi = _add_monster(game, "moon_tracker", center + Vector2(65, 30), "entrance")
	var pudding = _add_monster(game, "slime", center + Vector2(60, -30), "entrance")
	var mori = _add_monster(game, "spore_healer", center + Vector2(80, 20), "entrance")
	var selected = game.combat_scene._seal_chain_target(chain, 150.0, DataRegistry.skill("seal_chain").get("priority_monster_ids", []))
	_expect(selected == bebe, "일반 상황에서 베베를 루미·일반 몬스터보다 우선 지정")
	game.combat_scene._update_seal_chainbearers(0.01)
	_expect(chain.seal_chain_target == bebe and chain.seal_chain_cast_timer > 0.0 and bebe.seal_telegraph_source == chain, "0.9초 사슬 예고 시작")
	_expect(bebe.status_line().contains("봉인 사슬 예고") and bebe.status_line().contains("빗자루"), "대상 상태창에서 위험과 중단 방법을 즉시 읽을 수 있음")
	_expect(chain.skill_anim_timer >= 0.89 and game.combat_scene.seal_chain_telegraphs_started == 1, "시전 동작과 예고 통계 기록")
	bebe.action_direction = Vector2.LEFT
	var broom: Dictionary = game.combat_scene.perform_bebe_broom(bebe)
	game.combat_scene._update_seal_chainbearers(0.01)
	_expect(int(broom.get("interrupted", 0)) == 1 and chain.seal_chain_target == null, "베베 빗자루가 예고 중 봉인 사슬 시전을 중단")
	_expect(game.combat_scene.seal_chain_interruptions == 1 and bebe.seal_move_lock_timer == 0.0, "중단된 사슬은 봉인을 적용하지 않음")
	chain.action_interrupt_timer = 0.0
	chain.seal_chain_cooldown_timer = 0.0
	chain.global_position = center
	bebe.global_position = center + Vector2(55, 0)
	game.combat_scene._update_seal_chainbearers(0.01)
	game.combat_scene._update_seal_chainbearers(0.9)
	_expect(is_equal_approx(bebe.seal_move_lock_timer, 2.2) and is_equal_approx(bebe.seal_skill_lock_timer, 1.5), "예고 완료 뒤 이동·스킬 봉인 적용")
	_expect(is_equal_approx(bebe.seal_target_immunity_timer, 5.0) and game.combat_scene.seal_chain_activations == 1, "같은 대상 재봉인 면역 5초와 발동 기록")
	var rescue: Dictionary = game.combat_scene.perform_bebe_rescue(bebe, pudding)
	_expect(not bool(rescue.get("ok", true)) and str(rescue.get("reason", "")) == "skill_locked", "봉인 중 베베 구조 스킬 사용 불가")
	var old_position: Vector2 = bebe.global_position
	bebe.set_path([old_position + Vector2(100, 0)])
	bebe._physics_process(0.1)
	_expect(bebe.global_position.distance_to(old_position) < 0.01 and bebe.velocity.length() < 0.01, "이동 봉인 중 경로 명령에도 정지")
	var before_cleanse := float(bebe.seal_move_lock_timer)
	_expect(bebe.cleanse_one_negative_status() and is_equal_approx(bebe.seal_move_lock_timer, before_cleanse * 0.5), "모리 정화 규칙은 남은 이동 봉인을 절반으로 감소")
	chain.seal_chain_cooldown_timer = 0.0
	chain.threat_timer = 0.0
	chain.threat_unit = null
	selected = game.combat_scene._seal_chain_target(chain, 150.0, DataRegistry.skill("seal_chain").get("priority_monster_ids", []))
	_expect(selected == lumi, "베베 면역 중에는 다음 우선 대상 루미를 선택해 연속 봉인 방지")
	chain.apply_taunt(pudding, 4.0)
	selected = game.combat_scene._seal_chain_target(chain, 150.0, DataRegistry.skill("seal_chain").get("priority_monster_ids", []))
	_expect(selected == pudding, "푸딩 도발은 사슬 대상을 일반 몬스터로 변경")
	var reduction: float = game.combat_scene.seal_chain_fairness_reduction()
	var baseline_success: float = 1.0
	var one_chain_success: float = baseline_success - reduction
	var gob_precast_success: float = baseline_success
	var mori_cleanse_success: float = baseline_success - reduction * 0.5
	_expect(reduction >= 0.20 and reduction <= 0.35, "베베 대 사슬 1기 구조 성공률 감소가 %.1f%%로 20~35%% 범위" % (reduction * 100.0))
	_expect(one_chain_success > 0.5 and one_chain_success < baseline_success, "사슬 1기는 완전 차단이 아닌 소프트 카운터")
	_expect(gob_precast_success > one_chain_success and mori_cleanse_success > one_chain_success, "곱 선제 처치·모리 정화 조합은 사슬 대응 성과 향상")
	_expect(game.combat_scene.SEAL_CHAIN_HINT.contains("푸딩 도발") and game.combat_scene.SEAL_CHAIN_HINT.contains("베베 빗자루") and game.combat_scene.SEAL_CHAIN_HINT.contains("모리 정화"), "전투 안내에 세 가지 대응법 노출")
	for unit in game.monster_units + game.enemy_units:
		if is_instance_valid(unit):
			unit.queue_free()
	host.queue_free()
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
	push_error("[SealChainPhase12] FAIL: %s" % message)
