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
	print("TOKTOK_PHASE15_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_data_contract() -> void:
	var toktok: Dictionary = DataRegistry.monster("armored_beetle")
	_expect(not toktok.is_empty() and DataRegistry.update3_monster_extensions.has("armored_beetle"), "3차 확장과 실전 몬스터 카탈로그에 톡톡 로드")
	_expect(str(toktok.get("character_id", "")) == "CHR_TOKTOK" and str(toktok.get("instance_id", "")) == "monster_toktok", "톡톡 캐릭터·개체 ID 연결")
	_expect(int(toktok.get("max_hp", 0)) == 195 and int(toktok.get("atk", 0)) == 11 and int(toktok.get("def", 0)) == 7, "톡톡 HP 195·ATK 11·DEF 7")
	_expect(int(toktok.get("move_speed", 0)) == 90 and int(toktok.get("attack_range", 0)) == 52 and is_equal_approx(float(toktok.get("attack_interval", 0.0)), 1.2), "톡톡 이동 90·사거리 52·공격 간격 1.20")
	_expect(int(toktok.get("int", 0)) == 21 and int(toktok.get("loyalty", 0)) == 80, "톡톡 지능 21·충성 80")
	_expect(toktok.get("skills", []) == ["carapace_ram", "patch_plates", "scrap_shell"] and str(toktok.get("behavior_handler", "")) == "armor_support", "액티브 2개·패시브 1개와 데이터 행동 처리기")
	_expect(toktok.get("priority_enemy_ids", []) == ["relic_guardian", "shieldbearer", "siege_breaker"], "유물 수호자·방패병·공성 파괴자 우선순위")
	_expect(DataRegistry.character("CHR_TOKTOK").get("unit_ref", {}).get("id", "") == "armored_beetle", "CHR_TOKTOK 종족 참조")
	_expect(DataRegistry.monster_instance("monster_toktok").get("equipped_skill_ids", []).size() == 2, "monster_toktok 기본 장착 스킬 2개")
	_expect(not bool(toktok.get("placeholder_art", true)) and FileAccess.file_exists(str(toktok.get("sprite", ""))), "최종 톡톡 프레임 표시·파일 존재")
	_expect(DataRegistry.memory_entry("toktok_spare_plate").get("monster_id", "") == "armored_beetle", "톡톡 개인 유대 기억 연결")
	_expect(DataRegistry.specialization("toktok_shell_breaker").get("monster_id", "") == "armored_beetle" and DataRegistry.specialization("toktok_castle_mason").get("monster_id", "") == "armored_beetle", "톡톡 전술 특화 2종")
	var ram: Dictionary = DataRegistry.skill("carapace_ram")
	_expect(int(ram.get("max_distance", 0)) == 110 and int(ram.get("normal_def_reduction", 0)) == 2 and is_equal_approx(float(ram.get("normal_duration", 0.0)), 5.0), "갑각 돌진 110px·일반 방어 -2·5초")
	_expect(int(ram.get("boss_def_reduction", 0)) == 1 and is_equal_approx(float(ram.get("boss_duration", 0.0)), 4.0) and is_equal_approx(float(ram.get("cooldown", 0.0)), 9.0), "보스 방어 -1·4초·재사용 9초")
	var patch_skill: Dictionary = DataRegistry.skill("patch_plates")
	_expect(int(patch_skill.get("facility_repair", 0)) == 35 and int(patch_skill.get("ally_shield", 0)) == 28 and int(patch_skill.get("range", 0)) == 120, "덧대기 판금 수리 35·보호막 28·사거리 120")
	_expect(int(DataRegistry.skill("scrap_shell").get("max_stacks", 0)) == 3 and int(patch_skill.get("scrap_bonus_per_stack", 0)) == 8, "고철 최대 3개·개당 덧대기 +8")


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
	game.monster_roster["armored_beetle"] = {"level": 1, "exp": 0, "room": "barracks", "specialization_id": "", "promotion_id": "", "bond": 0, "bond_rank": 0, "unlocked_memory_ids": []}
	var center: Vector2 = game.graph.center("entrance")
	var toktok = _add_monster(game, "armored_beetle", center - Vector2(45, 0), "entrance")
	var shieldbearer = _add_enemy(game, "shieldbearer", center + Vector2(20, 0), "entrance")
	var ram: Dictionary = game.combat_scene.perform_toktok_carapace_ram(toktok, shieldbearer)
	_expect(bool(ram.get("ok", false)) and int(ram.get("damage", 0)) > 0, "갑각 돌진이 사거리 안 첫 적과 충돌해 실제 피해")
	_expect(shieldbearer.armor_break_amount == 2 and is_equal_approx(shieldbearer.armor_break_timer, 5.0), "일반 방패병 방어력 -2·5초 적용")
	_expect(shieldbearer.effective_def() == maxi(0, shieldbearer.def - 2) and shieldbearer.status_line().contains("방어력 -2"), "실제 피해 계산 방어력과 HUD 상태 문구 연결")
	var first_reduction := int(shieldbearer.armor_break_amount)
	toktok.global_position = center - Vector2(45, 0)
	shieldbearer.armor_break_timer = 1.0
	game.combat_scene.perform_toktok_carapace_ram(toktok, shieldbearer)
	_expect(shieldbearer.armor_break_amount == first_reduction and is_equal_approx(shieldbearer.armor_break_timer, 5.0), "방어력 감소 재적용은 수치 중첩 없이 시간만 갱신")
	var high_def := {"max_hp": 160, "def": 10}
	var base_time: float = game.combat_scene.estimate_toktok_intercept_seconds(DataRegistry.monster("armored_beetle"), high_def, 0.0, false)
	var broken_time: float = game.combat_scene.estimate_toktok_intercept_seconds(DataRegistry.monster("armored_beetle"), high_def, 0.0, true)
	_expect(1.0 - broken_time / base_time >= 0.12, "고방어 적 처치 예상 시간 %.1f%% 단축으로 12%% 이상" % ((1.0 - broken_time / base_time) * 100.0))
	game.enemy_units.erase(shieldbearer)
	shieldbearer.queue_free()
	var boss = _add_enemy(game, "official_hero_leon", center + Vector2(20, 0), "entrance")
	toktok.global_position = center - Vector2(45, 0)
	var boss_ram: Dictionary = game.combat_scene.perform_toktok_carapace_ram(toktok, boss)
	_expect(bool(boss_ram.get("ok", false)) and boss.armor_break_amount == 1 and is_equal_approx(boss.armor_break_timer, 4.0), "보스에게 방어력 -1·4초 제한")
	game.enemy_units.erase(boss)
	boss.queue_free()
	var far_shield = _add_enemy(game, "shieldbearer", center + Vector2(55, 0), "entrance")
	var near_explorer = _add_enemy(game, "explorer", center - Vector2(5, 0), "entrance")
	toktok.global_position = center - Vector2(45, 0)
	var first_hit: Dictionary = game.combat_scene.perform_toktok_carapace_ram(toktok, far_shield)
	_expect(first_hit.get("target") == near_explorer, "지정 적 앞에 다른 적이 있으면 첫 충돌 적에서 돌진 정지")
	game.enemy_units.erase(far_shield)
	game.enemy_units.erase(near_explorer)
	far_shield.queue_free()
	near_explorer.queue_free()
	var shielded = _add_enemy(game, "shieldbearer", center + Vector2(20, 0), "entrance")
	shielded.grant_duo_barrier(1)
	toktok.global_position = center - Vector2(45, 0)
	toktok.scrap_stacks = 0
	var scrap_ram: Dictionary = game.combat_scene.perform_toktok_carapace_ram(toktok, shielded)
	_expect(bool(scrap_ram.get("ok", false)) and toktok.scrap_stacks == 2, "적 보호막 파괴와 방어력 감소 성공으로 고철 각각 1개")
	toktok.add_scrap_stack(9, 3)
	_expect(toktok.scrap_stacks == 3, "고철은 과다 획득해도 최대 3개")
	var ally = _add_monster(game, "slime", toktok.global_position + Vector2(25, 0), "entrance")
	var ally_patch: Dictionary = game.combat_scene.perform_toktok_patch_plates(toktok, ally, "")
	_expect(bool(ally_patch.get("ok", false)) and str(ally_patch.get("kind", "")) == "ally" and ally.patch_plate_barrier == 52, "고철 3개를 사용한 아군 보호막 28+24")
	_expect(is_equal_approx(ally.patch_plate_barrier_timer, 5.0) and toktok.scrap_stacks == 0, "판금 보호막 5초·사용 후 고철 0개")
	var ally_hp_before := int(ally.hp)
	ally.receive_damage(40)
	_expect(ally.hp == ally_hp_before and ally.patch_plate_barrier == 12, "판금 보호막이 체력보다 먼저 피해 흡수")
	ally.patch_plate_barrier_timer = 0.1
	ally._physics_process(0.2)
	_expect(ally.patch_plate_barrier == 0, "5초가 끝난 판금 보호막 상태 정리")
	var thief_stats: Dictionary = DataRegistry.enemy("thief")
	var toktok_chase: float = game.combat_scene.estimate_toktok_intercept_seconds(DataRegistry.monster("armored_beetle"), thief_stats, 500.0, false)
	var koko_chase: float = game.combat_scene.estimate_tracker_intercept_seconds(DataRegistry.monster("graveyard_hound"), thief_stats, 500.0, false)
	_expect(toktok_chase > koko_chase * 1.2, "이동 90의 톡톡은 빠른 코코보다 도둑 추격이 20% 이상 느림")
	var barracks: Dictionary = game.rooms["barracks"]
	barracks["max_hp"] = 300
	barracks["hp"] = 210
	toktok.current_room = "barracks"
	toktok.assigned_room = "barracks"
	toktok.global_position = game.graph.center("barracks")
	toktok.scrap_stacks = 0
	game.combat_scene.notify_toktok_facility_hit("barracks", 29)
	_expect(toktok.scrap_stacks == 0, "시설 피해 29는 고철 획득 기준 미만")
	game.combat_scene.notify_toktok_facility_hit("barracks", 30)
	_expect(toktok.scrap_stacks == 1, "배치 시설이 한 번에 30 피해를 받으면 고철 1개")
	var hp_before_repair := int(barracks["hp"])
	var facility_patch: Dictionary = game.combat_scene.perform_toktok_patch_plates(toktok, null, "barracks")
	var effective_repair := int(facility_patch.get("repair", 0))
	_expect(bool(facility_patch.get("ok", false)) and str(facility_patch.get("kind", "")) == "facility" and effective_repair >= 43 and int(barracks["hp"]) == hp_before_repair + effective_repair, "시설 수리 35+고철 8과 활성 심장 보정 실제 반영 (before=%d repair=%d after=%d kind=%s)" % [hp_before_repair, effective_repair, int(barracks["hp"]), str(facility_patch.get("kind", ""))])
	_expect(ally.patch_plate_barrier == 0 and toktok.scrap_stacks == 0, "시설 수리 시 아군 보호막을 함께 주지 않고 고철 소모")
	barracks["hp"] = 290
	toktok.scrap_stacks = 3
	var capped_patch: Dictionary = game.combat_scene.perform_toktok_patch_plates(toktok, null, "barracks")
	_expect(bool(capped_patch.get("ok", false)) and int(capped_patch.get("repair", 0)) == 10 and int(barracks["hp"]) == 300, "수리량이 남은 체력을 넘으면 최대 체력에서 정확히 제한")
	_expect(game.combat_scene._toktok_facility_repair_target(toktok, true) != "barracks", "최대 체력 시설은 긴급 수리 대상으로 다시 선택되지 않아 수리 루프 방지")
	game.rooms["heart_chamber"] = {"display_name": "심장실", "facility_role": "heart_chamber", "hp": 30, "max_hp": 100}
	barracks["hp"] = 100
	var heart_target: String = game.combat_scene._toktok_facility_repair_target(toktok, true)
	_expect(heart_target == "heart_chamber", "심장실 체력 35% 이하는 다른 시설보다 우선 수리")
	toktok.current_room = "heart_chamber"
	var heart_patch: Dictionary = game.combat_scene.perform_toktok_patch_plates(toktok, null, "heart_chamber")
	_expect(bool(heart_patch.get("ok", false)) and int(game.rooms["heart_chamber"]["hp"]) > 30, "심장실도 일반 시설과 같은 덧대기 판금 경로로 수리")
	game.rooms.erase("heart_chamber")
	var priority_near = _add_enemy(game, "explorer", toktok.global_position + Vector2(10, 0), "barracks")
	var priority_shield = _add_enemy(game, "shieldbearer", toktok.global_position + Vector2(80, 0), "barracks")
	_expect(game.combat_scene._toktok_ram_target(toktok) == priority_shield, "가까운 일반 적보다 우선 목록의 방패병 선택")
	game.enemy_units.erase(priority_near)
	game.enemy_units.erase(priority_shield)
	priority_near.queue_free()
	priority_shield.queue_free()
	var blocked_segment: Array = _find_blocked_segment(game)
	_expect(blocked_segment.size() == 2, "전투 바닥 경계에 110px 이내 벽 가로지름 검사 구간 발견")
	if blocked_segment.size() == 2:
		var wall_enemy = _add_enemy(game, "explorer", blocked_segment[1], "entrance")
		toktok.global_position = blocked_segment[0]
		toktok.current_room = "entrance"
		var wall_ram: Dictionary = game.combat_scene.perform_toktok_carapace_ram(toktok, wall_enemy)
		_expect(not bool(wall_ram.get("ok", false)) and str(wall_ram.get("reason", "")) == "wall_blocked", "벽·비보행 구간 앞에서 갑각 돌진 취소")
		game.enemy_units.erase(wall_enemy)
		wall_enemy.queue_free()
	game.combat_scene.clear_effects()
	for unit in game.monster_units + game.enemy_units:
		if is_instance_valid(unit):
			unit.queue_free()
	host.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _find_blocked_segment(game: Node) -> Array:
	for room_id_value in game.rooms.keys():
		var room_id := str(room_id_value)
		var center: Vector2 = game.graph.center(room_id)
		for angle_index in range(32):
			var direction := Vector2.RIGHT.rotated(TAU * float(angle_index) / 32.0)
			for start_distance in range(0, 241, 20):
				var start := center + direction * float(start_distance)
				if game._clamp_to_combat_walkable(start).distance_to(start) > 1.0:
					continue
				var desired_end := start + direction * 100.0
				if game._clamp_to_combat_walkable(desired_end).distance_to(desired_end) > 3.0:
					return [start, desired_end]
	return []


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
	push_error("[ToktokPhase15] FAIL: %s" % message)
