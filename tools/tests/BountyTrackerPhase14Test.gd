extends Node

const MainScene = preload("res://scenes/main/Main.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_contract()
	await _test_bounty_vertical_slice()
	print("BOUNTY_TRACKER_PHASE14_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_data_contract() -> void:
	var enemy: Dictionary = DataRegistry.enemy("bounty_tracker")
	var skill: Dictionary = DataRegistry.skill("bounty_target")
	_expect(not enemy.is_empty() and DataRegistry.update3_enemy_extensions.has("bounty_tracker"), "3차 확장과 실전 적 카탈로그에 현상금 추적자 로드")
	_expect(str(enemy.get("character_id", "")) == "CHR_BOUNTY_TRACKER" and str(enemy.get("behavior_handler", "")) == "bounty_tracker", "캐릭터·데이터 행동 처리기 연결")
	_expect(int(enemy.get("max_hp", 0)) == 125 and int(enemy.get("atk", 0)) == 14 and int(enemy.get("def", 0)) == 4, "HP 125·ATK 14·DEF 4")
	_expect(int(enemy.get("move_speed", 0)) == 138 and int(enemy.get("attack_range", 0)) == 60 and is_equal_approx(float(enemy.get("attack_interval", 0.0)), 0.95), "이동 138·사거리 60·공격 간격 0.95")
	_expect(int(enemy.get("morale", 0)) == 86 and int(enemy.get("exp", 0)) == 48 and int(enemy.get("infamy", 0)) == 17, "사기·경험치·악명 기준치")
	_expect(is_equal_approx(float(skill.get("first_evaluation_seconds", 0.0)), 5.0) and is_equal_approx(float(skill.get("contribution_window_seconds", 0.0)), 20.0), "첫 평가 5초·최근 기여 창 20초")
	_expect(is_equal_approx(float(skill.get("duration", 0.0)), 6.0) and is_equal_approx(float(skill.get("cooldown", 0.0)), 12.0), "표적 6초·재평가 12초")
	_expect(is_equal_approx(float(skill.get("damage_taken_multiplier", 0.0)), 1.15), "표적 피해 증가 상한 15%")
	_expect(enemy.get("counter_hints", []).size() >= 2, "도발·보호·기여 분산 대응 안내")
	_expect(not bool(enemy.get("placeholder_art", true)) and FileAccess.file_exists(str(enemy.get("sprite", ""))), "최종 16프레임 아트 표시·파일 존재")
	_expect(DataRegistry.character("CHR_BOUNTY_TRACKER").get("unit_ref", {}).get("id", "") == "bounty_tracker", "캐릭터 카탈로그 역참조")


func _test_bounty_vertical_slice() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.current_screen = Constants.SCREEN_COMBAT
	game.combat_paused = false
	game.monster_units.clear()
	game.enemy_units.clear()
	game._reset_battle_contribution_stats()
	var center: Vector2 = game.graph.center("entrance")
	var pudding = _add_monster(game, "slime", center + Vector2(30, 0), "entrance")
	var gob = _add_monster(game, "goblin", center + Vector2(40, 0), "entrance")
	var imp = _add_monster(game, "imp", center + Vector2(50, 0), "entrance")
	var koko = _add_monster(game, "graveyard_hound", center + Vector2(60, 0), "entrance")
	var tracker = _add_enemy(game, "bounty_tracker", center, "entrance")
	tracker.bounty_evaluation_timer = 5.0
	game.combat_time = 4.9
	game.combat_scene._update_bounty_trackers(4.9)
	_expect(tracker.bounty_target == null and tracker.bounty_evaluation_timer > 0.0, "전투 시작 직후 데이터가 부족한 5초 동안 표적 없음")
	game._record_monster_contribution("slime", "damage_absorbed", 40)
	game._record_monster_contribution("goblin", "damage_dealt", 120)
	game._record_monster_contribution("imp", "damage_dealt", 70)
	game.combat_time = 5.0
	game.combat_scene._update_bounty_trackers(0.1)
	_expect(tracker.bounty_target == gob, "최근 20초 기여 1위 고블린을 정확히 선택")
	_expect(is_equal_approx(tracker.bounty_target_timer, 6.0) and is_equal_approx(gob.bounty_mark_timer, 6.0), "추적자와 대상에 현상금 표적 6초 동기화")
	_expect(gob.bounty_mark_source == tracker and gob.status_line().contains("현상금 표적"), "대상 상태 HUD용 위험 문구와 월드 표식 상태")
	_expect(is_equal_approx(gob.damage_taken_multiplier_from(tracker), 1.15) and is_equal_approx(pudding.damage_taken_multiplier_from(tracker), 1.0), "피해 증가 15%는 표시된 대상에게만 적용")
	_expect(game.combat_scene.bounty_evaluations == 1 and game.combat_scene.bounty_marks_applied == 1 and is_equal_approx(tracker.bounty_evaluation_timer, 12.0), "평가·표적 통계와 이후 12초 재평가")
	var preferred = tracker.preferred_attack_target(game.monster_units, tracker.attack_range)
	_expect(preferred == gob, "도발이 없으면 일반 공격도 현상금 대상 우선")
	tracker.apply_taunt(pudding, 4.0)
	_expect(game.combat_scene._bounty_combat_target(tracker) == pudding, "푸딩 도발로 표적을 유지한 채 일반 공격 대상 변경")
	tracker.threat_timer = 0.0
	tracker.threat_unit = null
	var bark: Dictionary = game.combat_scene.perform_koko_home_guard_bark(koko)
	_expect(bool(bark.get("ok", false)) and tracker.threat_unit == koko and game.combat_scene._bounty_combat_target(tracker) == koko, "코코 짖음 도발로 일반 공격 대상 변경")
	game._reset_battle_contribution_stats()
	game.inherited_legacy_monster = {"species_id": "slime", "display_name": "푸딩"}
	game.combat_time = 8.0
	game._record_monster_contribution("slime", "damage_dealt", 80)
	game._record_monster_contribution("goblin", "damage_dealt", 80)
	var tied_target = game.combat_scene._bounty_select_target(tracker, 20.0)
	_expect(tied_target == pudding, "기여 동률일 때만 계승 몬스터 푸딩 우선")
	game._reset_battle_contribution_stats()
	game.inherited_legacy_monster.clear()
	game.combat_time = 10.0
	game._record_monster_contribution("slime", "damage_dealt", 20)
	game._record_monster_contribution("imp", "damage_dealt", 90)
	var normal_profile_target = game.combat_scene._bounty_select_target(tracker, 20.0)
	_expect(normal_profile_target == imp, "계승 정보가 없는 일반 프로필에서도 기여 1위 선택")
	game._reset_battle_contribution_stats()
	game.combat_time = 0.0
	game._record_monster_contribution("goblin", "damage_dealt", 200)
	game.combat_time = 21.0
	game._record_monster_contribution("imp", "damage_dealt", 10)
	var window_target = game.combat_scene._bounty_select_target(tracker, 20.0)
	_expect(window_target == imp, "20초보다 오래된 높은 기여는 평가에서 제외")
	game._reset_battle_contribution_stats()
	game.combat_time = 22.0
	game._record_monster_contribution("slime", "facility_value", 30)
	game._record_monster_contribution("goblin", "damage_dealt", 100)
	var weighted_target = game.combat_scene._bounty_select_target(tracker, 20.0)
	_expect(weighted_target == pudding, "피해뿐 아니라 방어·시설 기여도 가중치로 평가")
	tracker.apply_bounty_target(gob, 6.0, 2.0)
	_expect(is_equal_approx(gob.damage_taken_multiplier_from(tracker), 1.15), "비정상 입력에도 표적 피해 증가 15% 상한 고정")
	game._select_unit(gob)
	game._set_screen(Constants.SCREEN_COMBAT)
	var hud_status = game.hud.selected_unit_dynamic_labels.get("status")
	_expect(hud_status is RichTextLabel and hud_status.text.contains("현상금 표적"), "선택 유닛 HUD에 현상금 표적과 남은 시간 표시")
	tracker.clear_bounty_target()
	_expect(gob.bounty_mark_timer == 0.0 and gob.bounty_mark_source == null, "표적 종료 시 HUD·월드 표식 상태 정리")
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
	push_error("[BountyTrackerPhase14] FAIL: %s" % message)
