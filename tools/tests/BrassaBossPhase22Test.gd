extends Node

const BossScript = preload("res://scripts/systems/bosses/BrassaBossBattleService.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_and_profiles()
	_test_three_stage_actions()
	_test_wall_deadlock_guards()
	_test_targets_retry_and_metrics()
	if failed:
		print("BRASSA_BOSS_PHASE22_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("BRASSA_BOSS_PHASE22_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_data_and_profiles() -> void:
	var boss: Dictionary = DataRegistry.enemies.get("rival_brassa_council_champion", {})
	_expect(bool(boss.get("placeholder_art", false)) and boss.get("skills", []).size() == 4, "브라사 placeholder boss·기술 4개")
	var unit = UnitScript.new()
	add_child(unit)
	unit.setup("rival_brassa_council_champion", boss, "enemy", "entrance")
	_expect(unit.max_hp == 620 and unit.atk == 25 and unit.def == 12 and is_equal_approx(unit.move_speed, 88.0), "브라사 최종 능력치 계약")
	unit.queue_free()
	var day25 := BossScript.battle_profile(25, boss)
	var day30 := BossScript.battle_profile(30, boss)
	_expect(int(day25.max_hp) == 465 and day25.skills.size() == 3 and int(day25.stage_count) == 3, "DAY 25 1차 형태·3기술")
	_expect(int(day30.max_hp) == 620 and day30.skills.size() == 4 and int(day30.stage_count) == 3, "DAY 30 최종 형태·4기술")


func _test_three_stage_actions() -> void:
	_expect(BossScript.stage_action(1, 25) == "bell_foundry", "1단계 철벽 설치")
	_expect(BossScript.stage_action(2, 25) == "overheat_order", "2단계 과열 지시")
	_expect(BossScript.stage_action(3, 25) == "weight_test", "DAY 25 3단계 하중 시험")
	_expect(BossScript.stage_action(3, 30) == "weight_test_then_castle_load_verdict", "DAY 30 3단계 왕관·시설 판정")
	var overheated := BossScript.apply_overheat([{"enemy_id": "bronze_automaton", "move_speed": 72.0, "atk": 13.0}, {"enemy_id": "coal_spark", "move_speed": 145.0, "atk": 12.0}], DataRegistry.skills.overheat_order)
	_expect(float(overheated[0].move_speed) > 72.0 and float(overheated[0].atk) > 13.0 and float(overheated[0].incoming_damage_multiplier) > 1.0, "과열 자동병 이동·공격·받는 피해 증가")
	_expect(not overheated[1].has("incoming_damage_multiplier"), "과열 지시 자동병에만 적용")
	var impact := BossScript.weight_test("barracks", true, DataRegistry.skills.weight_test)
	_expect(int(impact.room_damage) == 38 and int(impact.facility_damage) == 12 and is_equal_approx(float(impact.warning_seconds), 2.0), "하중 시험 예고·방·시설 실제 피해")


func _test_wall_deadlock_guards() -> void:
	var placed := BossScript.place_iron_wall([], "upper_slot", 1, DataRegistry.skills.bell_foundry)
	_expect(bool(placed.ok) and bool(placed.walls[0].blocks_players) and bool(placed.walls[0].blocks_enemies), "철벽 양측 이동 차단")
	_expect(bool(placed.walls[0].destructible) and float(placed.walls[0].decay_seconds) == 8.0 and not BossScript.wall_can_deadlock(placed.walls[0], 1), "단일 경로 철벽 파괴·8초 해제 교착 방지")
	_expect(not bool(BossScript.place_iron_wall(placed.walls, "throne", 2, DataRegistry.skills.bell_foundry).ok), "철벽 동시 1개 상한")
	var destroyed := BossScript.damage_wall(placed.walls[0], 90)
	_expect(not bool(destroyed.active) and int(destroyed.hp) == 0, "철벽 피해 파괴")


func _test_targets_retry_and_metrics() -> void:
	var targets := BossScript.verdict_targets(true, [{"id": "trap", "level": 2, "active": true}, {"id": "barracks", "level": 4, "active": true}])
	_expect(targets == ["crown_sanctum", "barracks"], "왕관실·최고 레벨 시설 목표")
	var loss := BossScript.resolve_battle({}, 25, false, {"facility_damage": 24, "walls_destroyed": 1})
	_expect(int(loss.retry_day) == 25 and str(loss.return_screen) == "management", "DAY 25 패배 관리 복귀·당일 재도전")
	_expect(int(loss.active_run.run_metrics_update4.rival_bosses.rival_brassa.attempts) == 1 and int(loss.active_run.run_metrics_update4.rival_bosses.rival_brassa.losses) == 1, "패배·시설 피해 결산 지표")
	var win := BossScript.resolve_battle(loss.active_run, 30, true, {"facility_damage": 8, "walls_destroyed": 2})
	_expect(int(win.retry_day) == 0 and str(win.return_screen) == "settlement", "DAY 30 승리 결산 이동")
	_expect(int(win.active_run.run_metrics_update4.rival_bosses.rival_brassa.wins) == 1 and int(win.active_run.run_metrics_update4.rival_bosses.rival_brassa.facility_damage) == 32 and int(win.active_run.run_metrics_update4.rival_bosses.rival_brassa.walls_destroyed) == 3, "승리·누적 결산 지표")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[BrassaBossPhase22] FAIL: %s" % label)
