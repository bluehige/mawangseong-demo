extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const CastleHeartServiceScript = preload("res://scripts/systems/hearts/CastleHeartService.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_contract()
	_test_heart_lock_service()
	await _test_ledger_vertical_slice()
	print("LEDGER_BINDER_PHASE18_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_data_contract() -> void:
	var enemy: Dictionary = DataRegistry.enemy("ledger_binder")
	var skill: Dictionary = DataRegistry.skill("debt_mark")
	_expect(not enemy.is_empty() and DataRegistry.update3_enemy_extensions.has("ledger_binder"), "3차 확장과 실전 적 카탈로그에 장부 구속술사 로드")
	_expect(str(enemy.get("character_id", "")) == "CHR_LEDGER_BINDER" and str(enemy.get("behavior_handler", "")) == "ledger_binder", "캐릭터·데이터 행동 처리기 연결")
	_expect(str(enemy.get("goal_type", "")) == "heart" and enemy.get("front_tags", []).has("guild_recovery"), "길드 회수 전선·심장 목표")
	_expect(int(enemy.get("max_hp", 0)) == 118 and int(enemy.get("atk", 0)) == 8 and int(enemy.get("def", 0)) == 4, "HP 118·ATK 8·DEF 4")
	_expect(int(enemy.get("move_speed", 0)) == 102 and int(enemy.get("attack_range", 0)) == 165 and is_equal_approx(float(enemy.get("attack_interval", 0.0)), 1.35), "이동 102·사거리 165·공격 간격 1.35")
	_expect(int(enemy.get("morale", 0)) == 92 and int(enemy.get("exp", 0)) == 47 and int(enemy.get("infamy", 0)) == 16, "사기·경험치·악명 기준치")
	_expect(is_equal_approx(float(skill.get("telegraph_seconds", 0.0)), 1.0) and is_equal_approx(float(skill.get("duration", 0.0)), 7.0) and is_equal_approx(float(skill.get("cooldown", 0.0)), 12.0), "1초 예고·7초 표식·12초 재사용")
	_expect(int(skill.get("debt_threshold", 0)) == 3 and int(skill.get("room_damage", 0)) == 20, "액티브 스킬 3회에 방 피해 20")
	_expect(is_equal_approx(float(skill.get("room_disable_seconds", 0.0)), 3.0) and is_equal_approx(float(skill.get("heart_active_lock_seconds", 0.0)), 3.0), "방 무력화·심장 액티브 잠금 각 3초")
	_expect(skill.get("cleanse_sources", []).has("cleansing_bloom") and skill.get("cleanse_sources", []).has("spectral_transfer") and bool(skill.get("clears_on_source_down", false)), "모리·베베 정화와 시전자 처치 해제 계약")
	_expect(DataRegistry.character("CHR_LEDGER_BINDER").get("unit_ref", {}).get("id", "") == "ledger_binder", "캐릭터 카탈로그 역참조")
	_expect(not bool(enemy.get("placeholder_art", true)) and FileAccess.file_exists(str(enemy.get("sprite", ""))) and FileAccess.file_exists(str(skill.get("icon", ""))), "최종 적 프레임·스킬 아이콘 존재")


func _test_heart_lock_service() -> void:
	var run: Dictionary = _heart_run(100)
	run = CastleHeartServiceScript.apply_debt_disable_and_lock(run, 3.0, 3.0)
	_expect(CastleHeartServiceScript.active_locked(run) and not CastleHeartServiceScript.passive_active(run), "부채 폭주 중 심장 액티브 잠금·패시브 무력화")
	var blocked: Dictionary = CastleHeartServiceScript.activate(run, ["barracks"])
	_expect(not bool(blocked.get("ok", true)) and str(blocked.get("error", "")).contains("부채 표식") and int(blocked.get("active_run", {}).get("heart", {}).get("charge", 0)) == 100, "잠금 중 액티브 거부·충전 100 보존")
	var almost: Dictionary = CastleHeartServiceScript.tick_events(run, 2.99).get("active_run", {})
	_expect(CastleHeartServiceScript.active_locked(almost), "2.99초에는 심장 액티브 잠금 유지")
	var resumed: Dictionary = CastleHeartServiceScript.tick_events(almost, 0.02).get("active_run", {})
	var activated: Dictionary = CastleHeartServiceScript.activate(resumed, ["barracks"])
	_expect(not CastleHeartServiceScript.active_locked(resumed) and CastleHeartServiceScript.passive_active(resumed) and bool(activated.get("ok", false)), "3초 뒤 심장 기능·액티브 자동 복구")
	var reset: Dictionary = CastleHeartServiceScript.start_battle(run, "next_battle", 2)
	_expect(float(reset.get("heart", {}).get("debt_disabled_remaining", -1.0)) == 0.0 and float(reset.get("heart", {}).get("active_locked_remaining", -1.0)) == 0.0, "다음 전투 시작 시 심장 부채 상태 초기화")


func _test_ledger_vertical_slice() -> void:
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
	var barracks_center: Vector2 = game.graph.center("barracks")
	var binder = _add_enemy(game, "ledger_binder", barracks_center + Vector2(120, 0), "barracks")
	var slime = _add_monster(game, "slime", barracks_center, "barracks")
	var started: Dictionary = game.combat_scene.begin_ledger_mark_cast(binder, "barracks")
	_expect(bool(started.get("ok", false)) and game.combat_scene.ledger_mark_casts.size() == 1 and binder.status_line().contains("부채 표식"), "부채 표식 1초 월드·HUD 예고 시작")
	_expect(is_equal_approx(float(binder.skill_cooldowns.get("debt_mark", 0.0)), 12.0), "시전 시작 시 재사용 대기 12초")
	game.combat_scene._update_ledger_binders(0.99)
	_expect(game.combat_scene.ledger_mark_state("barracks").is_empty(), "0.99초에는 방 표식 미적용")
	game.combat_scene._update_ledger_binders(0.02)
	var mark: Dictionary = game.combat_scene.ledger_mark_state("barracks")
	_expect(not mark.is_empty() and int(mark.get("debt", -1)) == 0 and is_equal_approx(float(mark.get("remaining", 0.0)), 7.0), "1초 예고 완료 뒤 7초·부채 0 방 표식")
	var hp_before := int(game.rooms["barracks"].get("hp", 0))
	var first: Dictionary = game.combat_scene.record_ledger_skill_use(slime, "slime_shield")
	var second: Dictionary = game.combat_scene.record_ledger_skill_use(slime, "hold_corridor")
	_expect(int(first.get("debt", 0)) == 1 and int(second.get("debt", 0)) == 2 and not bool(second.get("overloaded", true)), "같은 방 액티브 스킬 사용을 부채 1·2로 집계")
	_expect(int(game.rooms["barracks"].get("hp", 0)) == hp_before and game._facility_room_disabled_remaining("barracks") <= 0.0, "2중첩까지 방 피해·무력화 없음")
	var third: Dictionary = game.combat_scene.record_ledger_skill_use(slime, "slime_shield")
	var hp_loss := hp_before - int(game.rooms["barracks"].get("hp", 0))
	_expect(bool(third.get("overloaded", false)) and game.combat_scene.ledger_mark_state("barracks").is_empty(), "3중첩 즉시 폭주·표식 소모")
	_expect(hp_loss == int(third.get("damage", -1)) and hp_loss > 0 and hp_loss <= 20, "방 피해 20이 심장 방어를 거쳐 실제 HP에 반영")
	_expect(is_equal_approx(game._facility_room_disabled_remaining("barracks"), 3.0), "시설 기능 3초 무력화")
	_expect(is_equal_approx(game.combat_scene.ledger_skill_efficiency_reduction(), 0.25), "12초 주기 대비 3초 무력화로 스킬 중심 효율 25% 감소")
	_expect(is_equal_approx(game.combat_scene.ledger_max_skill_hold_seconds(), 7.0), "스킬 미사용 강요 상한 7초")

	game.facility_disabled_timers.clear()
	game.combat_scene._resolve_ledger_mark(binder, "barracks")
	game.combat_scene.record_ledger_skill_use(slime, "slime_shield")
	_expect(game.combat_scene.cleanse_ledger_room("barracks", "모리") and game.combat_scene.ledger_mark_state("barracks").is_empty(), "모리 정화 개화 경로로 누적 부채와 방 표식 제거")
	game.combat_scene._resolve_ledger_mark(binder, "barracks")
	var bebe = _add_monster(game, "ghost_housemaid", barracks_center + Vector2(20, 0), "barracks")
	var rescue: Dictionary = game.combat_scene.perform_bebe_rescue(bebe, slime)
	_expect(bool(rescue.get("ok", false)) and bool(rescue.get("ledger_cleansed", false)) and game.combat_scene.ledger_mark_state("barracks").is_empty(), "베베 유령 이송으로 대상 방 표식 정화")

	game.combat_scene._resolve_ledger_mark(binder, "barracks")
	binder.receive_damage(9999)
	_expect(not binder.is_alive() and game.combat_scene.ledger_mark_state("barracks").is_empty() and game.combat_scene.ledger_marks_cleared_on_source_down >= 1, "시전자 처치 시 해당 방 표식 즉시 해제")
	var new_binder = _add_enemy(game, "ledger_binder", game.graph.center("heart_chamber"), "heart_chamber")
	new_binder.goal_room = "heart_chamber"
	slime.global_position = game.graph.center("heart_chamber") + Vector2(20, 0)
	slime.current_room = "heart_chamber"
	game.update3_active_run["heart"]["charge"] = 100
	var heart_hp_before := int(game.update3_active_run.get("heart", {}).get("chamber_hp", 0))
	game.combat_scene._resolve_ledger_mark(new_binder, "heart_chamber")
	game.combat_scene.record_ledger_skill_use(slime, "slime_shield")
	game.combat_scene.record_ledger_skill_use(slime, "hold_corridor")
	var heart_overload: Dictionary = game.combat_scene.record_ledger_skill_use(slime, "slime_shield")
	var heart: Dictionary = game.update3_active_run.get("heart", {})
	_expect(bool(heart_overload.get("overloaded", false)) and heart_hp_before - int(heart.get("chamber_hp", 0)) > 0, "심장방 3중첩 시 방 피해 적용")
	_expect(is_equal_approx(float(heart.get("debt_disabled_remaining", 0.0)), 3.0) and is_equal_approx(float(heart.get("active_locked_remaining", 0.0)), 3.0), "심장방 기능 무력화·액티브 잠금 3초")
	var locked_activation: Dictionary = game._activate_update3_heart()
	_expect(not bool(locked_activation.get("ok", true)) and int(game.update3_active_run.get("heart", {}).get("charge", 0)) == 100, "실전 GameRoot 심장 액티브도 잠금 중 거부·충전 보존")
	game._tick_update3_heart(3.01)
	_expect(float(game.update3_active_run.get("heart", {}).get("debt_disabled_remaining", 1.0)) <= 0.0 and float(game.update3_active_run.get("heart", {}).get("active_locked_remaining", 1.0)) <= 0.0, "3초 뒤 실전 심장 무력화·액티브 잠금 자동 해제")

	game.combat_scene._resolve_ledger_mark(new_binder, "heart_chamber")
	game.combat_scene.record_ledger_skill_use(slime, "slime_shield")
	game.combat_scene.record_ledger_skill_use(slime, "hold_corridor")
	game.combat_scene.clear_effects()
	_expect(game.combat_scene.ledger_room_marks.is_empty() and game.combat_scene.ledger_mark_casts.is_empty(), "전투 종료 정리에서 debt·표식·예고 전부 제거")
	var choir_binder: Dictionary = game.combat_scene.evaluate_update3_counter_combo(["choir_exorcist", "ledger_binder"])
	var triple: Dictionary = game.combat_scene.evaluate_update3_counter_combo(["choir_exorcist", "ledger_binder", "combat_alchemist"])
	_expect(bool(choir_binder.get("allowed", false)) and not bool(triple.get("allowed", true)), "장부 구속술사 포함 카운터 2종 허용·3종 차단")
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


func _heart_run(charge: int) -> Dictionary:
	return {"heart": {"heart_id": CastleHeartServiceScript.STONEBONE_ID, "awakened": true, "disabled_this_battle": false, "charge": charge}, "run_metrics_update3": {}}


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
	push_error("[LedgerBinderPhase18] FAIL: %s" % message)
