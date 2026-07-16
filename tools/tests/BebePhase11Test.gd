extends Node

const MainScene = preload("res://scenes/main/Main.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_contract()
	await _test_combat_vertical_slice()
	print("BEBE_PHASE11_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_data_contract() -> void:
	var bebe: Dictionary = DataRegistry.monster("ghost_housemaid")
	_expect(not bebe.is_empty() and DataRegistry.update3_monster_extensions.has("ghost_housemaid"), "3차 몬스터 카탈로그와 실전 카탈로그에 베베 로드")
	_expect(str(bebe.get("character_id", "")) == "CHR_BEBE" and str(bebe.get("instance_id", "")) == "monster_bebe", "베베 캐릭터·개체 ID 연결")
	_expect(int(bebe.get("max_hp", 0)) == 112 and int(bebe.get("atk", 0)) == 9 and int(bebe.get("def", 0)) == 2, "베베 HP·ATK·DEF 기준치")
	_expect(int(bebe.get("move_speed", 0)) == 142 and int(bebe.get("attack_range", 0)) == 95 and is_equal_approx(float(bebe.get("attack_interval", 0.0)), 1.2), "베베 이동·사거리·공격 간격")
	_expect(bebe.get("skills", []) == ["spectral_transfer", "haunted_broom_whirl", "house_spirit"], "액티브 2개와 패시브 1개 로드")
	_expect(DataRegistry.skills.has("spectral_transfer") and DataRegistry.skills.has("haunted_broom_whirl") and DataRegistry.skills.has("house_spirit"), "베베 스킬 3개 참조 정상")
	_expect(DataRegistry.character("CHR_BEBE").get("unit_ref", {}).get("id", "") == "ghost_housemaid", "CHR_BEBE에서 종족 참조")
	_expect(DataRegistry.monster_instance("monster_bebe").get("equipped_skill_ids", []).size() == 2, "monster_bebe 기본 장착 스킬 2개")
	_expect(not bool(bebe.get("placeholder_art", true)) and FileAccess.file_exists(str(bebe.get("sprite", ""))), "최종 베베 프레임 표시·파일 존재")
	_expect(DataRegistry.memory_entry("bebe_room_key").get("monster_id", "") == "ghost_housemaid", "베베 개인 유대 기억 연결")
	_expect(DataRegistry.specialization("bebe_night_steward").get("monster_id", "") == "ghost_housemaid" and DataRegistry.specialization("bebe_poltergeist_cleaner").get("monster_id", "") == "ghost_housemaid", "베베 전술 특화 2종 데이터")
	var rescue: Dictionary = DataRegistry.skill("spectral_transfer")
	_expect(int(rescue.get("range", 0)) == 220 and int(rescue.get("max_move", 0)) == 110 and int(rescue.get("shield", 0)) == 20, "유령 당번 교대 사거리·최대 이동·보호막")
	_expect(int(rescue.get("cost_mana", 0)) == 16 and int(rescue.get("cooldown", 0)) == 11, "유령 당번 교대 마나 16·재사용 11초")


func _test_combat_vertical_slice() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.current_screen = Constants.SCREEN_COMBAT
	game.monster_units.clear()
	game.enemy_units.clear()
	game.monster_roster["ghost_housemaid"] = {
		"level": 1, "exp": 0, "room": "recovery", "specialization_id": "", "promotion_id": "",
		"bond": 0, "bond_rank": 0, "unlocked_memory_ids": []
	}
	var entrance: Vector2 = game.graph.center("entrance")
	var throne: Vector2 = game.graph.center("throne")
	var bebe = _add_monster(game, "ghost_housemaid", entrance + Vector2(0, 12), "entrance")
	bebe.assigned_room = "recovery"
	var wounded = _add_monster(game, "slime", entrance + Vector2(50, 0), "entrance")
	wounded.assigned_room = "recovery"
	wounded.hp = 40
	var enemy = _add_enemy(game, "explorer", entrance + Vector2(80, 0), "entrance")
	var rescue_result: Dictionary = game.combat_scene.perform_bebe_rescue(bebe, wounded)
	_expect(bool(rescue_result.get("ok", false)) and bool(rescue_result.get("moved", false)), "부상 아군 안전 이동 시작")
	_expect(wounded.duo_barrier == 20 and is_equal_approx(wounded.rescue_phase_timer, 0.8), "구조 대상 보호막 20·충돌 무시 0.8초")
	var route: Array = rescue_result.get("route", [])
	_expect(not route.is_empty() and wounded.global_position.distance_to(route[-1]) <= 110.01, "한 번의 구조 이동은 110px 이하")
	var all_walkable := true
	for point_value in route:
		var point: Vector2 = point_value
		if point.distance_to(game._clamp_to_combat_walkable(point)) > 0.5:
			all_walkable = false
	_expect(all_walkable, "구조 경로의 모든 지점은 보행 가능해 벽을 통과하지 않음")
	for _step in range(120):
		wounded._physics_process(0.05)
	_expect(wounded.path_points.is_empty(), "구조 경로를 따라간 후 경로 정지 0건")
	var original_graph = game.graph
	game.graph = null
	var no_cell_target = _add_monster(game, "goblin", entrance + Vector2(30, 20), "entrance")
	no_cell_target.hp = 30
	var no_cell: Dictionary = game.combat_scene.perform_bebe_rescue(bebe, no_cell_target)
	_expect(bool(no_cell.get("ok", false)) and not bool(no_cell.get("moved", true)), "안전 셀이 없으면 이동하지 않음")
	_expect(no_cell_target.duo_barrier == 20 and no_cell_target.path_points.is_empty(), "안전 셀 없음에도 보호막만 정상 적용")
	game.graph = original_graph
	var lower_hp = _add_monster(game, "imp", throne + Vector2(-50, 0), "entrance")
	lower_hp.hp = 10
	var throne_wounded = _add_monster(game, "goblin", throne + Vector2(30, 0), "throne")
	throne_wounded.hp = 35
	bebe.global_position = throne
	bebe.current_room = "throne"
	enemy.global_position = throne + Vector2(60, 0)
	enemy.current_room = "throne"
	var emergency_target = game.combat_scene._bebe_rescue_target(bebe, 0.40)
	_expect(emergency_target == throne_wounded, "왕좌 공격 중에는 더 낮은 HP의 다른 방 아군보다 왕좌 부상자 우선")
	bebe.current_room = "recovery"
	game.facility_disabled_timers["recovery"] = 10.0
	game._update_facility_disables(4.4)
	_expect(is_equal_approx(game._facility_room_disabled_remaining("recovery"), 5.0), "베베가 시설 내부에 있으면 무력화 실제 시간 12% 감소")
	game.selected_unit = bebe
	bebe.skill_cooldowns["spectral_transfer"] = 0.0
	GameState.mana = 100
	for prior_ally in [wounded, no_cell_target, lower_hp, throne_wounded]:
		prior_ally.hp = prior_ally.max_hp
	var auto_target = _add_monster(game, "slime", bebe.global_position + Vector2(45, 0), "recovery")
	auto_target.hp = 30
	game.combat_scene.update_ai_paths()
	_expect(auto_target.duo_barrier == 20 and float(bebe.skill_cooldowns.get("spectral_transfer", 0.0)) > 0.0, "베베가 지시에 따라 자동 구조·재사용 적용")
	game._set_screen(Constants.SCREEN_COMBAT)
	var toggle = game.ui_layer.find_child("BebeAutoRescueToggle", true, false)
	_expect(toggle == null, "베베 선택 패널에서 직접 조작용 자동 구조 토글 제거")
	enemy.global_position = bebe.global_position + Vector2(-300, 0)
	enemy.current_room = "entrance"
	var normal = _add_enemy(game, "explorer", bebe.global_position + Vector2(50, 0), "recovery")
	var boss = _add_enemy(game, "official_hero_leon", bebe.global_position + Vector2(62, 8), "recovery")
	var behind = _add_enemy(game, "explorer", bebe.global_position + Vector2(-50, 0), "recovery")
	bebe.action_direction = Vector2.RIGHT
	normal.skill_anim_timer = 1.0
	boss.skill_anim_timer = 1.0
	var normal_hp := int(normal.hp)
	var normal_position: Vector2 = normal.global_position
	var boss_hp := int(boss.hp)
	var behind_hp := int(behind.hp)
	var broom: Dictionary = game.combat_scene.perform_bebe_broom(bebe)
	_expect(int(broom.get("targets", 0)) == 2 and normal.hp < normal_hp and boss.hp < boss_hp and behind.hp == behind_hp, "빗자루 전방 부채꼴 85px 피해")
	_expect(is_equal_approx(normal.action_interrupt_timer, 0.35) and normal.global_position.distance_to(normal_position) > 0.0 and normal.global_position.distance_to(normal_position) <= 24.01, "일반 적 시전 0.35초 중단·24px 이하 밀침")
	_expect(boss.action_interrupt_timer == 0.0 and boss.path_points.is_empty(), "보스는 피해만 받고 중단·밀침 면역")
	var survival = _add_monster(game, "goblin", entrance, "entrance")
	survival.hp = 30
	survival.grant_duo_barrier(20)
	for _hit in range(3):
		survival.receive_damage(10)
	_expect(survival.is_alive() and survival.hp == 20, "구조 보호막으로 비구조 기준 3타 전투 불능을 막아 생존 시간 25% 이상 증가")
	var bebe_dps := float(DataRegistry.monster("ghost_housemaid")["atk"]) / float(DataRegistry.monster("ghost_housemaid")["attack_interval"])
	var imp_dps := float(DataRegistry.monster("imp")["atk"]) / float(DataRegistry.monster("imp")["attack_interval"])
	_expect(bebe_dps <= imp_dps * 0.85, "화력 프로필에서 베베의 기본 DPS는 임프보다 15% 이상 낮아 명확한 대가")
	var payload: Dictionary = game._campaign_save_payload(Constants.SCREEN_COMBAT)
	var roundtrip = JSON.parse_string(JSON.stringify(payload))
	_expect(roundtrip is Dictionary and not roundtrip.get("world", {}).get("monster_roster", {}).get("ghost_housemaid", {}).has("bebe_auto_rescue"), "베베 자동 구조가 별도 수동 설정 없이 저장·JSON 복원")
	_expect(str(roundtrip.get("world", {}).get("monster_roster", {}).get("ghost_housemaid", {}).get("room", "")) == "recovery", "베베 배치 방·로스터 저장")
	for unit in game.monster_units + game.enemy_units:
		if is_instance_valid(unit):
			unit.queue_free()
	host.queue_free()
	await get_tree().process_frame


func _add_monster(game: Node, species_id: String, position: Vector2, room_id: String):
	var stats: Dictionary = DataRegistry.monster(species_id).duplicate(true)
	var unit = game._create_unit(species_id, stats, Constants.FACTION_MONSTER, room_id)
	unit.global_position = position
	game.monster_units.append(unit)
	return unit


func _add_enemy(game: Node, enemy_id: String, position: Vector2, room_id: String):
	var unit = game._create_unit(enemy_id, DataRegistry.enemy(enemy_id), Constants.FACTION_ENEMY, room_id)
	unit.global_position = position
	game.enemy_units.append(unit)
	return unit


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		return
	failed = true
	push_error("[BebePhase11] FAIL: %s" % message)
