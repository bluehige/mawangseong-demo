extends Node

const MainScene = preload("res://scenes/main/Main.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_contract()
	await _test_relic_aura_vertical_slice()
	print("RELIQUARY_GUARD_PHASE17A_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_data_contract() -> void:
	var enemy: Dictionary = DataRegistry.enemy("reliquary_guard")
	var skill: Dictionary = DataRegistry.skill("relic_aura")
	_expect(not enemy.is_empty() and DataRegistry.update3_enemy_extensions.has("reliquary_guard"), "3차 확장과 실전 적 카탈로그에 성물 수호기사 로드")
	_expect(str(enemy.get("character_id", "")) == "CHR_RELIQUARY_GUARD" and str(enemy.get("behavior_handler", "")) == "reliquary_guard", "캐릭터·데이터 행동 처리기 연결")
	_expect(str(enemy.get("goal_type", "")) == "throne" and enemy.get("front_tags", []).has("holy_purification"), "성광 정화 전선·왕좌 목표")
	_expect(is_equal_approx(float(enemy.get("threat", 0.0)), 1.85), "위협도 1.85")
	_expect(int(enemy.get("max_hp", 0)) == 175 and int(enemy.get("atk", 0)) == 10 and int(enemy.get("def", 0)) == 8, "HP 175·ATK 10·DEF 8")
	_expect(int(enemy.get("move_speed", 0)) == 80 and int(enemy.get("attack_range", 0)) == 48 and is_equal_approx(float(enemy.get("attack_interval", 0.0)), 1.3), "이동 80·사거리 48·공격 간격 1.30")
	_expect(int(enemy.get("morale", 0)) == 105 and int(enemy.get("exp", 0)) == 52 and int(enemy.get("infamy", 0)) == 18, "사기·경험치·악명 기준치")
	_expect(int(skill.get("radius", 0)) == 155 and is_equal_approx(float(skill.get("magic_damage_multiplier", 0.0)), 0.85), "오라 반경 155·마법 피해 -15%")
	_expect(is_equal_approx(float(skill.get("status_duration_multiplier", 0.0)), 0.75) and is_equal_approx(float(skill.get("morale_damage_multiplier", 0.0)), 0.75), "상태 이상 시간·사기 피해 -25%")
	_expect(is_equal_approx(float(skill.get("self_move_multiplier", 0.0)), 0.92) and bool(skill.get("non_stacking", false)), "본인 이동 -8%·오라 중첩 불가")
	_expect(enemy.get("counter_hints", []).size() >= 3, "톡톡·후열 우회·푸딩/핀 대응 안내")
	_expect(not bool(enemy.get("placeholder_art", true)) and FileAccess.file_exists(str(enemy.get("sprite", ""))), "최종 16프레임 아트 표시·파일 존재")
	_expect(DataRegistry.character("CHR_RELIQUARY_GUARD").get("unit_ref", {}).get("id", "") == "reliquary_guard", "캐릭터 카탈로그 역참조")


func _test_relic_aura_vertical_slice() -> void:
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
	var guard = _add_enemy(game, "reliquary_guard", center, "entrance")
	var guard_two = _add_enemy(game, "reliquary_guard", center + Vector2(20, 0), "entrance")
	var protected = _add_enemy(game, "combat_alchemist", center + Vector2(100, 0), "entrance")
	var outside = _add_enemy(game, "combat_alchemist", center + Vector2(220, 0), "entrance")
	game.combat_scene._update_reliquary_auras(0.1)
	_expect(game.combat_scene.active_relic_aura_sources() == 2 and game.combat_scene.relic_aura_peak_protected == 3, "수호기사 2명과 오라 안 고유 아군 3명 감지")
	_expect(protected.has_relic_aura() and not outside.has_relic_aura(), "반경 155 안쪽만 성물 오라 적용")
	_expect(is_equal_approx(protected.relic_aura_magic_multiplier, 0.85) and is_equal_approx(protected.relic_aura_status_multiplier, 0.75) and is_equal_approx(protected.relic_aura_morale_multiplier, 0.75), "오라 감소 배율 3종 실제 상태 반영")
	game.combat_scene._update_reliquary_auras(0.1)
	_expect(is_equal_approx(protected.relic_aura_magic_multiplier, 0.85) and is_equal_approx(protected.relic_aura_status_multiplier, 0.75), "수호기사 둘의 겹친 오라는 수치 중첩 없이 시간만 갱신")
	var hp_before_magic := int(protected.hp)
	var magic_dealt := int(protected.receive_magic_damage(100))
	_expect(magic_dealt == 85 and protected.hp == hp_before_magic - 85, "오라 안 마법 피해 100을 85로 감소")
	var outside_hp := int(outside.hp)
	_expect(outside.receive_magic_damage(100) == 100 and outside.hp == outside_hp - 100, "오라 밖 마법 피해는 감소하지 않음")
	protected.apply_slow(4.0, 0.5)
	_expect(is_equal_approx(protected.slow_timer, 3.0), "오라 안 4초 이동 둔화가 3초로 감소")
	protected.armor_break_timer = 0.0
	protected.armor_break_amount = 0
	protected.apply_armor_break(2, 4.0, "test")
	_expect(protected.armor_break_amount == 2 and is_equal_approx(protected.armor_break_timer, 3.0), "방어 감소 수치는 유지하고 지속시간만 25% 감소")
	var morale_before := int(protected.morale)
	var morale_dealt := int(protected.receive_morale_damage(40))
	_expect(morale_dealt == 30 and protected.morale == morale_before - 30, "사기 피해 40을 30으로 감소")
	_expect(guard.status_line().contains("성물 오라") and protected.has_relic_aura(), "수호기사 HUD 오라 문구와 보호 아군 실제 오라 상태")
	_expect(is_equal_approx(guard.effective_move_speed(), 73.6), "수호기사 이동 속도 80에 본인 대가 -8% 실제 적용")
	guard.down = true
	guard_two.down = true
	protected.stop_navigation()
	protected._physics_process(0.3)
	_expect(not protected.has_relic_aura() and is_equal_approx(protected.relic_aura_magic_multiplier, 1.0), "모든 오라 원천 제거 뒤 보호 효과 자동 종료")
	guard.down = false
	guard.hp = guard.max_hp
	guard.global_position = center + Vector2(60, 0)
	guard_two.global_position = center + Vector2(-220, 0)
	guard_two.down = true
	var toktok = _add_monster(game, "armored_beetle", center, "entrance")
	game.combat_scene._update_reliquary_auras(0.1)
	var ram: Dictionary = game.combat_scene.perform_toktok_carapace_ram(toktok, guard)
	_expect(bool(ram.get("ok", false)) and guard.armor_break_amount == 2 and guard.effective_def() == 6, "톡톡 갑각 돌진이 수호기사 방어력 8을 6으로 파괴")
	_expect(is_equal_approx(guard.armor_break_timer, 3.75), "성물 오라가 톡톡 방어 파괴 지속 5초를 3.75초로 줄임")
	for unit in game.monster_units + game.enemy_units:
		if is_instance_valid(unit):
			unit.queue_free()
	host.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


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
	push_error("[ReliquaryGuardPhase17A] FAIL: %s" % message)
