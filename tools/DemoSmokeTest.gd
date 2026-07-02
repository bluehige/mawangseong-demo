extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = await _new_game()
	await _check_core_loop(game)
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
	return game

func _check_core_loop(game: Node) -> void:
	_expect(game.current_screen == Constants.SCREEN_MANAGEMENT, "프로젝트 시작 시 관리 화면")

	game.selected_room = "spike_corridor"
	game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
	_expect(game.room_directives["spike_corridor"] == Constants.ROOM_DIRECTIVE_TRAP_LURE, "방 지침 변경 반영")

	game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
	_expect(game.global_directive == Constants.DIRECTIVE_ALL_OUT, "전체 지침 변경 반영")

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
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "방어 준비 후 전투 화면")
	_expect(game.monster_units.size() == 3, "슬라임, 고블린, 임프 배치")
	var selected_room_before_floor_click = game.selected_room
	game._handle_left_click(game.graph.center("slot_01"))
	_expect(game.selected_room == selected_room_before_floor_click, "전투 중 맵 바닥 클릭은 방 선택하지 않음")

	var slime = _unit_by_id(game.monster_units, "slime")
	var imp = _unit_by_id(game.monster_units, "imp")
	_expect(slime.state_label() != "" and slime.status_line() != "", "아군 상태 UI용 상태값 초기화")
	_expect(slime.sprite.sprite_frames.has_animation("move_down"), "이동 애니메이션 슬롯")
	_expect(slime.sprite.sprite_frames.has_animation("attack_down"), "공격 애니메이션 슬롯")
	_expect(slime.sprite.sprite_frames.has_animation("skill_down"), "스킬 애니메이션 슬롯")
	await _check_unit_collision_avoidance(game, slime)
	game._select_unit(slime)
	game._enable_direct_control()
	_expect(slime.direct_control and slime.path_points.is_empty(), "직접 조종 시작 시 AI 이동 경로 정지")
	var command_point = game.graph.center("center")
	game._handle_right_click(command_point)
	_expect(slime.direct_control and slime.command_point == command_point, "몬스터 직접 조종 이동 명령")
	_expect(slime.tactical_state == Constants.UNIT_STATE_DIRECT_CONTROL, "직접 조종 상태 표시")
	game._release_direct_control()
	game._select_unit(slime)
	game._handle_key(KEY_1)
	_expect(slime.shield_timer > 0.0, "키보드 1번 스킬 입력")
	_expect(slime.tactical_state == Constants.UNIT_STATE_CAST_SKILL, "스킬 사용 상태 표시")
	game._handle_key(KEY_2)
	_expect(slime.skill_cooldowns.has("hold_corridor"), "키보드 2번 스킬 입력")
	_expect(slime.guard_bonus > 0, "통로 막기 방어 보너스")

	game._spawn_ready_enemies(0.2)
	_expect(game.enemy_units.size() > 0, "적이 입구에서 등장")
	var enemy = game.enemy_units[0]
	_expect(enemy.goal_room != "" or not enemy.path_points.is_empty(), "적 이동/교전 목표 설정")

	enemy.global_position = slime.global_position + Vector2(180, 0)
	enemy.current_room = slime.current_room
	enemy.set_physics_process(false)
	game._select_unit(slime)
	game._enable_direct_control()
	var distance_before_manual_attack = slime.global_position.distance_to(enemy.global_position)
	game._handle_right_click(enemy.global_position)
	_expect(slime.command_target == enemy and slime.command_point == Vector2.ZERO, "우클릭 적 직접 공격 대상 지정")
	for i in range(45):
		await get_tree().physics_frame
	_expect(slime.global_position.distance_to(enemy.global_position) < distance_before_manual_attack, "직접 공격 대상 추적 이동")
	enemy.set_physics_process(true)

	enemy.global_position = slime.global_position + Vector2(30, 0)
	enemy.current_room = slime.current_room
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
	_expect(enemy.hp < hp_before_trap, "가시 복도 함정 피해")

	for alive_enemy in game.enemy_units:
		if alive_enemy.is_alive():
			alive_enemy.receive_damage(9999)
	game.wave_manager.next_index = game.wave_manager.schedule.size()
	game._check_combat_end()
	_expect(game.current_screen == Constants.SCREEN_RESULT, "결산 화면 표시")

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
	blocker.global_position = game.graph.center("center")
	blocker.current_room = "center"
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
	thief.current_room = "center"
	thief.goal_room = "center"
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

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
