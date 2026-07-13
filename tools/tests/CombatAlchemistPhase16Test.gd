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
	await _test_acid_vertical_slice()
	print("COMBAT_ALCHEMIST_PHASE16_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_data_contract() -> void:
	var enemy: Dictionary = DataRegistry.enemy("combat_alchemist")
	var skill: Dictionary = DataRegistry.skill("acid_solution")
	_expect(not enemy.is_empty() and DataRegistry.update3_enemy_extensions.has("combat_alchemist"), "3차 확장과 실전 적 카탈로그에 전투 연금술사 로드")
	_expect(str(enemy.get("character_id", "")) == "CHR_COMBAT_ALCHEMIST" and str(enemy.get("behavior_handler", "")) == "combat_alchemist", "캐릭터·데이터 행동 처리기 연결")
	_expect(str(enemy.get("goal_type", "")) == "facility" and enemy.get("front_tags", []).has("guild_recovery"), "길드 회수 전선·시설 목표")
	_expect(int(enemy.get("max_hp", 0)) == 112 and int(enemy.get("atk", 0)) == 9 and int(enemy.get("def", 0)) == 3, "HP 112·ATK 9·DEF 3")
	_expect(int(enemy.get("move_speed", 0)) == 108 and int(enemy.get("attack_range", 0)) == 180 and is_equal_approx(float(enemy.get("attack_interval", 0.0)), 1.5), "이동 108·사거리 180·공격 간격 1.50")
	_expect(int(enemy.get("morale", 0)) == 80 and int(enemy.get("exp", 0)) == 49 and int(enemy.get("infamy", 0)) == 17, "사기·경험치·악명 기준치")
	_expect(is_equal_approx(float(skill.get("telegraph_seconds", 0.0)), 0.8) and int(skill.get("radius", 0)) == 85 and is_equal_approx(float(skill.get("duration", 0.0)), 5.0), "산성 용액 0.8초 예고·반경 85·5초")
	_expect(int(skill.get("def_penalty", 0)) == 2 and is_equal_approx(float(skill.get("repair_multiplier", 0.0)), 0.6), "방어력 -2 상한·수리 -40%")
	_expect(int(skill.get("damage_per_second", 0)) == 2 and is_equal_approx(float(skill.get("cooldown", 0.0)), 10.0) and bool(skill.get("non_stacking", false)), "초당 피해 2·재사용 10초·중첩 불가")
	_expect(enemy.get("counter_hints", []).size() >= 3, "베베 이동·핀 제거·장판 밖 수리 대응 안내")
	_expect(not bool(enemy.get("placeholder_art", true)) and FileAccess.file_exists(str(enemy.get("sprite", ""))), "최종 16프레임 아트 표시·파일 존재")
	_expect(DataRegistry.character("CHR_COMBAT_ALCHEMIST").get("unit_ref", {}).get("id", "") == "combat_alchemist", "캐릭터 카탈로그 역참조")


func _test_acid_vertical_slice() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.current_screen = Constants.SCREEN_COMBAT
	game.combat_paused = false
	game.monster_units.clear()
	game.enemy_units.clear()
	game.monster_roster["armored_beetle"] = {"level": 1, "exp": 0, "room": "entrance", "specialization_id": "", "promotion_id": "", "bond": 0, "bond_rank": 0, "unlocked_memory_ids": []}
	var center: Vector2 = game.graph.center("entrance")
	var toktok = _add_monster(game, "armored_beetle", center, "entrance")
	var alchemist = _add_enemy(game, "combat_alchemist", center + Vector2(150, 0), "entrance")
	var started: Dictionary = game.combat_scene.begin_alchemist_acid_throw(alchemist, toktok)
	_expect(bool(started.get("ok", false)) and game.combat_scene.acid_telegraphs.size() == 1, "사거리 180 안에서 산성 투척 예고 시작")
	_expect(is_equal_approx(float(started.get("telegraph_seconds", 0.0)), 0.8) and game.combat_scene.active_acid_warning_count() == 1, "0.8초 월드·HUD 경고 상태 노출")
	_expect(is_equal_approx(float(alchemist.skill_cooldowns.get("acid_solution", 0.0)), 10.0), "투척 시작 시 재사용 대기 10초")
	var fixed_position: Vector2 = game.combat_scene.acid_telegraphs[0].get("position", Vector2.ZERO)
	toktok.global_position += Vector2(120, 0)
	game.combat_scene._update_acid_telegraphs(0.79)
	_expect(game.combat_scene.acid_zones.is_empty() and Vector2(game.combat_scene.acid_telegraphs[0].get("position", Vector2.ZERO)) == fixed_position, "예고 0.79초에는 장판이 없고 투척 위치는 이동 대상을 따라가지 않음")
	game.combat_scene._update_acid_telegraphs(0.02)
	_expect(game.combat_scene.acid_telegraphs.is_empty() and game.combat_scene.acid_zones.size() == 1, "0.8초 완료 뒤 고정 위치에 산성 장판 생성")
	_expect(not game.combat_scene.acid_zone_contains(toktok.global_position), "예고 중 직접 이동하면 산성 장판 회피 가능")
	toktok.global_position = fixed_position
	var base_def := int(toktok.def)
	game.combat_scene._update_acid_zones(0.1)
	_expect(toktok.acid_def_penalty == 2 and toktok.effective_def() == base_def - 2, "장판 안 톡톡 방어력 -2 실제 계산 반영")
	_expect(is_equal_approx(toktok.repair_output_multiplier(), 0.6) and toktok.status_line().contains("수리 -40%"), "장판 안 수리 효율 60%와 HUD 위험 문구")
	var zone_count: int = game.combat_scene.acid_zones.size()
	var refresh: Dictionary = game.combat_scene._deploy_acid_zone(fixed_position + Vector2(10, 0), alchemist.get_instance_id(), 5.0, 85.0)
	game.combat_scene._update_acid_zones(0.1)
	_expect(bool(refresh.get("refreshed", false)) and game.combat_scene.acid_zones.size() == zone_count and toktok.acid_def_penalty == 2, "겹친 산성 용액은 장판·방어 감소를 중첩하지 않고 지속시간만 갱신")
	var hp_before_tick := int(toktok.hp)
	game.combat_scene._update_acid_zones(0.8)
	_expect(toktok.hp == hp_before_tick - 2, "산성 장판 직접 피해 초당 2·겹친 장판 피해 중첩 없음")
	var barracks: Dictionary = game.rooms["barracks"]
	barracks["max_hp"] = 300
	barracks["hp"] = 200
	toktok.current_room = "barracks"
	var acid_repair: Dictionary = game.combat_scene.perform_toktok_patch_plates(toktok, null, "barracks")
	var acid_amount := int(acid_repair.get("repair", 0))
	barracks["hp"] = 200
	toktok.acid_zone_timer = 0.0
	toktok.acid_repair_multiplier = 1.0
	var normal_repair: Dictionary = game.combat_scene.perform_toktok_patch_plates(toktok, null, "barracks")
	var normal_amount := int(normal_repair.get("repair", 0))
	_expect(bool(acid_repair.get("ok", false)) and bool(normal_repair.get("ok", false)) and acid_amount < normal_amount and float(acid_amount) / float(normal_amount) <= 0.61, "톡톡 시설 수리량이 산성 구역에서 약 40% 감소")
	var core_reduction: float = game.combat_scene.estimate_toktok_acid_core_reduction(DataRegistry.monster("armored_beetle"), int(alchemist.atk))
	_expect(core_reduction >= 0.20 and core_reduction <= 0.35, "방어·수리 복합 핵심 효율 %.1f%% 감소로 목표 20~35%%" % (core_reduction * 100.0))
	game.combat_scene.clear_effects()
	toktok.global_position = center
	toktok.current_room = "entrance"
	var bebe = _add_monster(game, "ghost_housemaid", center + Vector2(25, 0), "entrance")
	bebe.assigned_room = "recovery"
	alchemist.global_position = center + Vector2(150, 0)
	alchemist.hp = alchemist.max_hp
	alchemist.down = false
	var rescue_throw: Dictionary = game.combat_scene.begin_alchemist_acid_throw(alchemist, toktok)
	var rescue_center: Vector2 = rescue_throw.get("position", Vector2.ZERO)
	var rescue: Dictionary = game.combat_scene.perform_bebe_rescue(bebe, toktok)
	for _step in range(20):
		toktok._physics_process(0.1)
	game.combat_scene._update_acid_telegraphs(0.81)
	game.combat_scene._update_acid_zones(0.1)
	_expect(bool(rescue.get("ok", false)) and toktok.global_position.distance_to(rescue_center) > 85.0 and toktok.acid_zone_timer <= 0.0, "베베 구조로 고정 예고 지점 밖으로 이동해 장판 회피 (ok=%s distance=%.1f acid=%.2f)" % [str(rescue.get("ok", false)), toktok.global_position.distance_to(rescue_center), toktok.acid_zone_timer])
	game.combat_scene.clear_effects()
	toktok.global_position = center
	alchemist.global_position = center + Vector2(150, 0)
	alchemist.hp = alchemist.max_hp
	alchemist.down = false
	alchemist.set_skill_cooldown("acid_solution", 0.0)
	game.combat_scene.begin_alchemist_acid_throw(alchemist, toktok)
	var pynn = _add_monster(game, "imp", center - Vector2(20, 0), "entrance")
	var fire_range := 320.0
	var fire_damage := DamageService.compute(pynn, alchemist, 2.4)
	while alchemist.is_alive():
		alchemist.receive_damage(fire_damage)
	game.combat_scene._update_acid_telegraphs(0.1)
	_expect(pynn.global_position.distance_to(alchemist.global_position) <= fire_range and not alchemist.is_alive() and game.combat_scene.acid_telegraphs.is_empty(), "핀 원거리 화염으로 예고 중 연금술사를 제거하면 투척 취소")
	game.combat_scene._deploy_acid_zone(center, 999, 5.0, 85.0)
	game.combat_scene._update_acid_zones(5.01)
	_expect(game.combat_scene.acid_zones.is_empty(), "산성 장판은 5초 뒤 자동 종료")
	game.combat_scene.clear_effects()
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
		return
	failed = true
	push_error("[CombatAlchemistPhase16] FAIL: %s" % message)
