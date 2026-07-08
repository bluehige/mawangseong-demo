extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const DamageService = preload("res://scripts/combat/DamageService.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = await _new_game()
	await _check_map_click_build_palette(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_raid_loop(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_core_loop(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_facility_combat_effects(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_defeat_branch(game)
	game.queue_free()
	await get_tree().process_frame

	game = await _new_game()
	await _check_three_day_victory(game)
	game.queue_free()
	await get_tree().process_frame

	if failed:
		print("DEMO_SMOKE_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("DEMO_SMOKE_TEST: PASS")
		get_tree().quit(0)

func _new_game() -> Node:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await get_tree().process_frame
	return game

func _check_map_click_build_palette(game: Node) -> void:
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "맵 클릭 시설 팔레트 검증 시작")
	game._handle_left_click(game.graph.center("slot_01"))
	await get_tree().process_frame
	_expect(game.build_pick_mode and game.build_palette_target_room == "slot_01" and game.build_pick_facility_id == "", "빈 슬롯 맵 클릭으로 시설 팔레트 열림")
	game._set_build_facility("watch_post")
	await get_tree().process_frame
	_expect(not game.build_pick_mode and game.build_palette_target_room == "", "시설 팔레트 선택 후 건설 모드 해제")
	_expect(game.rooms["slot_01"].get("facility_role", "") == "watch_post", "시설 팔레트 선택이 클릭한 슬롯에 즉시 적용")

func _check_raid_loop(game: Node) -> void:
	GameState.day = 4
	game._open_raid_screen()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_RAID, "DAY 04 원정 화면 열림")
	_expect(game.monster_roster.has("kobold_scout"), "원정 화면에서 코볼트 척후대장 로로 합류")
	_expect(not DataRegistry.raid_mission("d04_signpost_flip").is_empty(), "DAY 04 표지판 원정 데이터 로드")
	var gold_before = GameState.gold
	var food_before = GameState.food
	var infamy_before = GameState.infamy
	game.raid_selected_mission_id = "d04_signpost_flip"
	game.raid_selected_monster_ids.clear()
	game.raid_selected_monster_ids.append("kobold_scout")
	game._start_selected_raid()
	await get_tree().process_frame
	_expect(game.completed_raids.has("d04_signpost_flip"), "표지판 원정 완료 플래그 저장")
	_expect(GameState.food == food_before - 5, "원정 식량 비용 차감")
	_expect(GameState.gold == gold_before + 30, "원정 금화 보상 지급")
	_expect(GameState.infamy == infamy_before + 22, "로로 대장 보너스 포함 악명 보상 지급")
	_expect(game.next_defense_modifiers.has("lost_adventurers"), "원정 결과가 다음 방어 영향으로 저장")
	_expect(not game.last_raid_result.is_empty(), "원정 결과 보고 생성")
	game._start_combat()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "원정 이후 DAY 04 방어전 시작")
	_expect(game.wave_manager.total_to_spawn == 5, "길 잃은 탐험가 효과로 DAY 04 적 수 조정")
	_expect(float(game.wave_manager.schedule[0].get("time", 0.0)) >= 4.0, "길 잃은 탐험가 효과로 첫 침입 지연")
	_expect(game.next_defense_modifiers.is_empty(), "방어전 시작 후 원정 효과 소모")
	game.wave_manager.next_index = game.wave_manager.schedule.size()
	game._check_combat_end()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_RESULT, "DAY 04 방어전 결과 화면 표시")
	_expect(not GameState.victory, "DAY 04 방어전은 3일차 데모 클리어로 처리하지 않음")

func _check_monster_screen_buttons(game: Node) -> void:
	game._open_monster_screen()
	await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_MONSTER, "몬스터 관리 화면 열림")
	var train_button = _find_button_by_text(game.ui_layer, "훈련")
	_expect(train_button != null and not train_button.disabled, "몬스터 훈련 버튼 활성")
	var gold_before = GameState.gold
	var exp_before = int(game.monster_roster[game.selected_monster_id].get("exp", 0))
	if train_button != null:
		train_button.pressed.emit()
		await get_tree().process_frame
	_expect(GameState.gold == gold_before - 30, "몬스터 화면 훈련 버튼 작동")
	_expect(int(game.monster_roster[game.selected_monster_id].get("exp", 0)) > exp_before, "훈련 EXP 증가")
	var back_button = _find_button_by_text(game.ui_layer, "돌아가기")
	_expect(back_button != null and not back_button.disabled, "몬스터 돌아가기 버튼 활성")
	if back_button != null:
		back_button.pressed.emit()
		await get_tree().process_frame
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "몬스터 화면 돌아가기 버튼 작동")

func _check_core_loop(game: Node) -> void:
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "프로젝트 시작 시 관리 화면")

	await _check_monster_screen_buttons(game)

	game.selected_room = "spike_corridor"
	game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
	_expect(game.room_directives["spike_corridor"] == Constants.ROOM_DIRECTIVE_TRAP_LURE, "방 지침 변경 반영")

	game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
	_expect(game.global_directive == Constants.DIRECTIVE_ALL_OUT, "전체 지침 변경 반영")

	game.selected_room = "entrance"
	game._build_selected_slot()
	await get_tree().process_frame
	_expect(game.build_pick_mode, "건설 버튼이 위치 선택 모드로 전환")
	_expect(game.build_pick_facility_id == "watch_post", "건설 모드 기본 시설은 감시 초소")
	game._handle_left_click(game.graph.center("slot_01"))
	await get_tree().process_frame
	_expect(game.selected_room == "slot_01" and not game.facility_change_panel_open and not game.build_pick_mode, "건설 모드에서 맵 클릭으로 선택 시설 바로 적용")
	_expect(game.rooms["slot_01"].get("facility_role", "") == "watch_post", "맵 클릭 대상에 감시 초소 건설")

	game._start_monster_placement("imp")
	await get_tree().process_frame
	_expect(game.deploy_pick_monster_id == "imp", "몬스터 버튼이 방 선택 배치 모드로 전환")
	game._handle_left_click(game.graph.center("barracks"))
	await get_tree().process_frame
	_expect(game.monster_roster["imp"]["room"] == "barracks" and game.deploy_pick_monster_id == "", "배치 모드에서 맵 클릭으로 몬스터 방 이동")

	var goblin_start = game._management_monster_preview_position("goblin")
	var recovery_target = game.graph.center("recovery")
	_expect(game._start_management_monster_drag(goblin_start), "관리 화면 몬스터 드래그 시작")
	game._update_management_monster_drag(recovery_target)
	game._finish_management_monster_drag(recovery_target)
	_expect(game.monster_roster["goblin"]["room"] == "recovery", "드래그로 몬스터 방 배치")

	var gold_before_purpose = GameState.gold
	game.selected_room = "barracks"
	game._change_selected_room_facility("treasure")
	_expect(game.rooms["barracks"].get("facility_role", "") == "treasure", "방 용도 변경으로 보물 보관실 이동")
	_expect(game.rooms["treasure"].get("facility_role", "") == "build_slot", "기존 보물 보관실 빈 슬롯 전환")
	_expect(GameState.gold == gold_before_purpose - 120, "방 용도 변경 비용 차감")
	game._spawn_enemy("thief")
	var thief_probe = _unit_by_id(game.enemy_units, "thief")
	_expect(thief_probe != null and thief_probe.goal_room == "barracks", "도둑 목표가 현재 보물 보관실을 추적")
	game._clear_units()

	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "전투 시작 후 전투 화면")
	_expect(game.monster_units.size() == 3, "슬라임, 고블린, 임프 배치")
	var selected_room_before_floor_click = game.selected_room
	game._handle_left_click(game.graph.center("recovery"))
	_expect(game.selected_room == selected_room_before_floor_click, "전투 중 맵 바닥 클릭은 방 선택하지 않음")

	var slime = _unit_by_id(game.monster_units, "slime")
	var imp = _unit_by_id(game.monster_units, "imp")
	_expect(slime.sprite.scale.x <= 0.5 and imp.sprite.scale.x <= 0.5, "전투 캐릭터 스프라이트 축소")
	_expect(slime.sprite.position.y <= -34.0 and imp.sprite.position.y <= -40.0, "캐릭터 발 위치 기준 정렬")
	var zoom_before = game.combat_view_zoom
	game._adjust_combat_zoom(1, Vector2(960, 540))
	_expect(game.combat_view_zoom > zoom_before, "전투 휠 확대")
	game._adjust_combat_zoom(-1, Vector2(960, 540))
	_expect(game.combat_view_zoom <= zoom_before + 0.01, "전투 휠 축소")
	var outside_point = Vector2(40, 40)
	var clamped_point = game._clamp_to_combat_walkable(outside_point)
	_expect(game.graph.is_walkable(clamped_point), "던전 밖 이동 좌표 보행 영역 보정")
	_expect(slime.state_label() != "" and slime.status_line() != "", "아군 상태 UI용 상태값 초기화")
	_expect(slime.sprite.sprite_frames.has_animation("move_down"), "이동 애니메이션 슬롯")
	_expect(slime.sprite.sprite_frames.has_animation("attack_down"), "공격 애니메이션 슬롯")
	_expect(slime.sprite.sprite_frames.has_animation("skill_down"), "스킬 애니메이션 슬롯")
	_expect(slime.sprite.sprite_frames.get_frame_count("move_down") >= 4, "몬스터 이동 애니메이션 다중 프레임")
	_expect(slime.sprite.sprite_frames.get_frame_count("attack_down") >= 4, "몬스터 공격 애니메이션 다중 프레임")
	_expect(slime.sprite.sprite_frames.get_frame_count("skill_down") >= 4, "몬스터 스킬 애니메이션 다중 프레임")
	_expect(game.effect_frame_sets.get("fireball", []).size() >= 4, "화염구 이펙트 다중 프레임")
	_expect(game.effect_frame_sets.get("shield", []).size() >= 4, "방어 스킬 이펙트 다중 프레임")
	await _check_unit_collision_avoidance(game, slime)
	game._select_unit(slime)
	game._enable_direct_control()
	_expect(slime.direct_control and slime.path_points.is_empty(), "직접 조종 시작 시 AI 이동 경로 정지")
	var command_point = game.graph.center("barracks")
	game._handle_right_click(command_point)
	_expect(slime.direct_control and slime.command_point == command_point, "몬스터 직접 조종 이동 명령")
	game._handle_right_click(outside_point)
	_expect(game.graph.is_walkable(slime.command_point), "직접 이동 명령 던전 내부 보정")
	_expect(slime.tactical_state == Constants.UNIT_STATE_DIRECT_CONTROL, "직접 조종 상태 표시")
	game._release_direct_control()
	game._select_unit(slime)
	var shield_effects_before = game.effect_root.get_child_count()
	game._handle_key(KEY_1)
	_expect(slime.shield_timer > 0.0, "키보드 1번 스킬 입력")
	_expect(slime.tactical_state == Constants.UNIT_STATE_CAST_SKILL, "스킬 사용 상태 표시")
	_expect(game.effect_root.get_child_count() > shield_effects_before, "방어 스킬 이펙트 생성")
	game._handle_key(KEY_2)
	_expect(slime.skill_cooldowns.has("hold_corridor"), "키보드 2번 스킬 입력")
	_expect(slime.guard_bonus > 0, "통로 막기 방어 보너스")

	game._spawn_ready_enemies(0.2)
	_expect(game.enemy_units.size() > 0, "적이 입구에서 등장")
	var enemy = game.enemy_units[0]
	_expect(enemy.goal_room != "" or not enemy.path_points.is_empty(), "적 이동/교전 목표 설정")
	_expect(enemy.sprite.sprite_frames.get_frame_count("move_down") >= 4, "적 이동 뛰기 애니메이션 다중 프레임")

	enemy.global_position = game.graph.center("barracks")
	enemy.current_room = "barracks"
	enemy.set_physics_process(false)
	_expect(game.graph.is_walkable(enemy.global_position), "직접 공격 검증 대상이 보행 셀 위에 있음")
	game._select_unit(slime)
	game._enable_direct_control()
	game._handle_right_click(enemy.global_position)
	_expect(slime.command_target == enemy and slime.command_point == Vector2.ZERO, "우클릭 적 직접 공격 대상 지정")
	var path_count_before_manual_attack = slime.path_points.size()
	var position_before_manual_attack = slime.global_position
	for i in range(45):
		await get_tree().physics_frame
	var moved_for_manual_attack = slime.global_position.distance_to(position_before_manual_attack) > 8.0
	var path_progressed_for_manual_attack = slime.path_points.size() < path_count_before_manual_attack
	_expect(moved_for_manual_attack or path_progressed_for_manual_attack, "직접 공격 대상 경로 추적 이동")
	enemy.set_physics_process(true)
	game._release_direct_control()

	enemy.global_position = slime.global_position + Vector2(30, 0)
	enemy.current_room = slime.current_room
	slime.set_path([slime.global_position + Vector2(96, 0)])
	slime.velocity = Vector2(30, 0)
	game.combat_scene.update_monster_path(slime)
	_expect(slime.path_points.is_empty() and slime.velocity.length() <= 0.01 and slime.tactical_state == Constants.UNIT_STATE_ATTACK, "근접 교전 사거리 안에서 이동 정지")

	enemy.global_position = slime.global_position + Vector2(30, 0)
	enemy.current_room = slime.current_room
	slime.attack_cooldown = 0.0
	var hp_before_attack = enemy.hp
	game._try_attack(slime, [enemy])
	_expect(enemy.hp < hp_before_attack, "몬스터 자동 공격 피해")

	enemy.hp = enemy.max_hp
	enemy.down = false
	enemy.visible = true
	enemy.global_position = imp.global_position + Vector2(90, 0)
	enemy.current_room = imp.current_room
	game._select_unit(imp)
	var effect_count = game.effect_root.get_child_count()
	game._handle_key(KEY_1)
	_expect(enemy.hp < enemy.max_hp and game.effect_root.get_child_count() > effect_count, "임프 화염구 투사체")

	enemy.hp = enemy.max_hp
	enemy.down = false
	enemy.current_room = "spike_corridor"
	enemy.global_position = game.graph.center("spike_corridor")
	game.trap_cooldown = 0.0
	var hp_before_trap = enemy.hp
	game._update_room_effects(2.0)
	_expect(game.quarter_renderer.debug_active_trap_animation_count() == 1, "spike trap trigger animation starts")
	_expect(enemy.hp < hp_before_trap, "가시 복도 함정 피해")

	for alive_enemy in game.enemy_units:
		if alive_enemy.is_alive():
			alive_enemy.receive_damage(9999)
	game.wave_manager.next_index = game.wave_manager.schedule.size()
	game._check_combat_end()
	_expect(game.current_screen == Constants.SCREEN_RESULT, "결산 화면 표시")

func _check_facility_combat_effects(game: Node) -> void:
	_expect(game._change_room_facility("slot_01", "watch_post"), "감시 초소 건설 효과 준비")
	_expect(game.rooms["slot_01"].get("facility_role", "") == "watch_post", "감시 초소 시설 역할 적용")
	game.monster_roster["slime"]["room"] = "barracks"
	game._start_combat()
	await get_tree().physics_frame

	var slime = _unit_by_id(game.monster_units, "slime")
	_expect(slime != null, "시설 효과 검증용 슬라임 생성")
	if slime == null:
		return
	var barracks_room = game._room_by_facility("barracks", "")
	var watch_room = game._room_by_facility("watch_post", "")
	var recovery_room = game._room_by_facility("recovery", "")
	_expect(barracks_room != "" and watch_room != "" and recovery_room != "", "시설 효과 대상 방 확인")
	if barracks_room == "" or watch_room == "" or recovery_room == "":
		return

	slime.global_position = game.graph.center(barracks_room)
	slime.current_room = barracks_room
	slime.assigned_room = barracks_room
	slime.attack_cooldown = 0.0
	slime.set_physics_process(false)
	game._spawn_enemy("explorer")
	var enemy = game.enemy_units[game.enemy_units.size() - 1]
	enemy.global_position = slime.global_position + Vector2(8, 0)
	enemy.current_room = barracks_room
	enemy.attack_cooldown = 999.0
	enemy.set_physics_process(false)
	var base_barracks_damage = DamageService.compute(slime, enemy)
	var enemy_hp_before = enemy.hp
	game.combat_scene.try_attack(slime, [enemy])
	_expect(enemy_hp_before - enemy.hp > base_barracks_damage, "병영 안 아군 공격 보너스 적용")
	_expect(int(game.facility_effect_stats.get("barracks_bonus_damage", 0)) > 0, "병영 추가 피해 통계 기록")

	enemy.hp = enemy.max_hp
	enemy.attack_cooldown = 0.0
	slime.hp = slime.max_hp
	slime.attack_cooldown = 999.0
	var base_taken_damage = DamageService.compute(enemy, slime)
	var slime_hp_before = slime.hp
	game.combat_scene.try_attack(enemy, [slime])
	_expect(slime_hp_before - slime.hp < base_taken_damage, "병영 안 아군 피해 감소 적용")
	_expect(int(game.facility_effect_stats.get("barracks_damage_reduced", 0)) > 0, "병영 피해 감소 통계 기록")

	game._spawn_enemy("explorer")
	var watched_enemy = game.enemy_units[game.enemy_units.size() - 1]
	watched_enemy.global_position = game.graph.center(watch_room)
	watched_enemy.current_room = watch_room
	watched_enemy.slow_factor = 1.0
	watched_enemy.slow_timer = 0.0
	watched_enemy.set_physics_process(false)
	game.combat_scene.update_room_effects(0.2)
	_expect(watched_enemy.slow_timer > 0.0 and watched_enemy.slow_factor <= 0.78, "감시 초소 구역 적 둔화 적용")
	_expect(int(game.facility_effect_stats.get("watch_post_slow_applications", 0)) > 0, "감시 초소 둔화 통계 기록")

	slime.global_position = watched_enemy.global_position + Vector2(8, 0)
	slime.current_room = "entrance"
	slime.attack_cooldown = 0.0
	watched_enemy.hp = watched_enemy.max_hp
	var base_watch_damage = DamageService.compute(slime, watched_enemy)
	var watched_hp_before = watched_enemy.hp
	game.combat_scene.try_attack(slime, [watched_enemy])
	_expect(watched_hp_before - watched_enemy.hp > base_watch_damage, "감시 초소 구역 적 피해 증가 적용")
	_expect(int(game.facility_effect_stats.get("watch_post_bonus_damage", 0)) > 0, "감시 초소 추가 피해 통계 기록")

	slime.current_room = recovery_room
	slime.hp = slime.max_hp - 20
	var wounded_hp = slime.hp
	game.combat_scene.update_room_effects(1.0)
	_expect(slime.hp > wounded_hp, "회복 둥지 전투 중 회복 적용")
	_expect(int(game.facility_effect_stats.get("recovery_healing", 0)) > 0, "회복 둥지 회복 통계 기록")
	var facility_result_lines: Array = game._facility_effect_result_lines()
	_expect(not facility_result_lines.is_empty() and str(facility_result_lines[0]).find("시설 기여") >= 0, "전투 결과 시설 기여 문구 생성")

func _check_defeat_branch(game: Node) -> void:
	game._start_combat()
	await get_tree().physics_frame
	GameState.damage_throne(GameState.demon_lord_max_hp)
	game._check_combat_end()
	_expect(GameState.defeat and game.current_screen == Constants.SCREEN_RESULT, "왕좌의 방 HP 0 패배")

func _check_three_day_victory(game: Node) -> void:
	for day in range(1, GameState.max_day + 1):
		_expect(GameState.day == day, "DAY %d 시작" % day)
		game._start_combat()
		await get_tree().physics_frame
		game.wave_manager.next_index = game.wave_manager.schedule.size()
		var saw_trainee_hero := false
		for entry in game.wave_manager.schedule:
			game._spawn_enemy(str(entry.get("enemy_id", "explorer")))
		for enemy in game.enemy_units:
			if enemy.unit_id == "trainee_hero":
				saw_trainee_hero = true
			if enemy.is_alive():
				enemy.receive_damage(9999)
		game._check_combat_end()
		_expect(game.current_screen == Constants.SCREEN_RESULT, "DAY %d 결과 화면" % day)
		if day < GameState.max_day:
			game._advance_after_result()
			await get_tree().process_frame
		else:
			_expect(saw_trainee_hero, "3일차 수련생 용사 등장")
			_expect(GameState.victory, "3일차 수련생 용사 격퇴 후 데모 클리어")

func _check_unit_collision_avoidance(game: Node, blocker: Node) -> void:
	var original_position = blocker.global_position
	var original_physics = blocker.is_physics_processing()
	blocker.global_position = game.graph.center("barracks")
	blocker.current_room = "barracks"
	blocker.set_physics_process(false)
	game.combat_paused = true
	game._spawn_enemy("thief")
	var thief = _unit_by_id(game.enemy_units, "thief")
	_expect(thief != null, "충돌 검증용 도둑 생성")
	if thief == null:
		blocker.set_physics_process(original_physics)
		blocker.global_position = original_position
		game.combat_paused = false
		return
	thief.global_position = blocker.global_position + Vector2(-120, 0)
	thief.current_room = "barracks"
	thief.goal_room = "barracks"
	thief.set_path([blocker.global_position + Vector2(120, 0)])
	var collision_shape = _collision_shape(thief)
	var circle = collision_shape.shape as CircleShape2D if collision_shape != null else null
	_expect(circle != null and circle.radius <= 18.0, "유닛 충돌체가 근접 전투용 소형 반경")
	var min_distance = INF
	var moved_past_blocker = false
	for i in range(90):
		await get_tree().physics_frame
		min_distance = min(min_distance, thief.global_position.distance_to(blocker.global_position))
		if thief.global_position.x > blocker.global_position.x + 34.0:
			moved_past_blocker = true
	_expect(min_distance >= 22.0, "도둑이 유닛 충돌체를 관통하지 않음")
	_expect(moved_past_blocker, "도둑이 충돌 유닛을 돌아서 이동")
	game.enemy_units.erase(thief)
	thief.queue_free()
	blocker.global_position = original_position
	blocker.set_physics_process(original_physics)
	game.combat_paused = false

func _collision_shape(unit: Node) -> CollisionShape2D:
	for child in unit.get_children():
		if child is CollisionShape2D:
			return child
	return null

func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null

func _find_button_by_text(node: Node, needle: String) -> Button:
	if node is Button and String(node.text).find(needle) >= 0:
		return node
	for child in node.get_children():
		var found = _find_button_by_text(child, needle)
		if found != null:
			return found
	return null

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
