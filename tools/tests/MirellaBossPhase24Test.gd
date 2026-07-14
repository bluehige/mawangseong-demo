extends Node

const BossScript = preload("res://scripts/systems/bosses/MirellaBossBattleService.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_and_profiles()
	_test_garden_weakness_and_clarity()
	_test_pruning_regrowth_and_roots()
	_test_time_cap_retry_and_metrics()
	if failed:
		print("MIRELLA_BOSS_PHASE24_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("MIRELLA_BOSS_PHASE24_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_data_and_profiles() -> void:
	var boss: Dictionary = DataRegistry.enemies.get("rival_mirella_council_champion", {})
	_expect(bool(boss.get("placeholder_art", false)) and boss.get("skills", []).size() == 4, "미렐라 placeholder boss·기술 4개")
	var unit = UnitScript.new()
	add_child(unit)
	unit.setup("rival_mirella_council_champion", boss, "enemy", "entrance")
	_expect(unit.max_hp == 590 and unit.atk == 20 and unit.def == 9 and is_equal_approx(unit.move_speed, 100.0) and is_equal_approx(unit.attack_interval, 1.10), "미렐라 최종 능력치 계약")
	unit.queue_free()
	var day25 := BossScript.battle_profile(25, boss)
	var day30 := BossScript.battle_profile(30, boss)
	_expect(int(day25.max_hp) == 443 and day25.skills.size() == 3 and float(day25.max_duration_seconds) == 180.0, "DAY 25 1차 형태·3기술·180초 상한")
	_expect(int(day30.max_hp) == 590 and day30.skills.size() == 4 and float(day30.max_duration_seconds) == 240.0, "DAY 30 최종 형태·4기술·240초 상한")


func _test_garden_weakness_and_clarity() -> void:
	var garden_result := BossScript.create_sleeping_garden([], "upper_slot", DataRegistry.skills.sleeping_garden)
	var garden: Dictionary = garden_result.gardens[0]
	_expect(bool(garden_result.ok) and is_equal_approx(float(garden.remaining), 7.0), "잠드는 정원 7초 구역")
	_expect(float(garden.telegraph_seconds) == 2.0 and str(garden.telegraph_color) != "" and bool(garden.edge_ring) and bool(garden.remaining_time_label), "구역 예고·색·테두리·잔여시간 표시")
	_expect(not bool(BossScript.create_sleeping_garden(garden_result.gardens, "throne", DataRegistry.skills.sleeping_garden).ok), "잠드는 정원 동시 1개")
	var cleansed := BossScript.apply_garden_weakness(garden, true, 0.0, DataRegistry.skills.sleeping_garden)
	_expect(is_equal_approx(float(cleansed.remaining), 4.0), "정화로 정원 3초 단축")
	var burned := BossScript.apply_garden_weakness(garden, false, 10.0, DataRegistry.skills.sleeping_garden)
	_expect(is_equal_approx(float(burned.remaining), 4.0), "화염으로 정원 지속 단축")
	var removed := BossScript.apply_garden_weakness(garden, true, 20.0, DataRegistry.skills.sleeping_garden)
	_expect(not bool(removed.active) and is_zero_approx(float(removed.remaining)), "정화·화염 조합으로 정원 제거")


func _test_pruning_regrowth_and_roots() -> void:
	var pruned := BossScript.pruning_choice([{"id": "permanent", "temporary": false, "power": 99.0}, {"id": "small", "temporary": true, "power": 1.1}, {"id": "large", "temporary": true, "power": 1.4}], 40, 100, DataRegistry.skills.pruning_choice)
	_expect(str(pruned.removed_buff_id) == "large" and int(pruned.hp) == 55, "가장 강한 임시 버프 제거·대상 15% 회복")
	_expect(pruned.remaining_buffs.any(func(value): return str(value.get("id", "")) == "permanent"), "영구 버프 가지치기 제외")
	var regrown := BossScript.regrowth_vote([{"enemy_id": "coal_spark", "max_hp": 75}, {"enemy_id": "spore_doll", "max_hp": 120}], DataRegistry.skills.regrowth_vote)
	_expect(bool(regrown.ok) and int(regrown.hp) == 36, "포자 인형 1개 HP 30% 재성장")
	_expect(not bool(BossScript.regrowth_vote([{"enemy_id": "root_tender"}], DataRegistry.skills.regrowth_vote).ok), "포자 인형 없으면 재성장 생략")
	var roots := BossScript.create_crown_roots(DataRegistry.skills.garden_around_the_crown)
	_expect(roots.size() == 3 and roots.all(func(root): return int(root.hp) == 55), "왕관 주변 뿌리 3개")
	var state := {}
	for root in roots.duplicate(true):
		state = BossScript.damage_crown_root(roots, str(root.id), 55, DataRegistry.skills.garden_around_the_crown)
		roots = state.roots
	_expect(bool(state.all_cleared) and is_equal_approx(float(state.boss_def_multiplier), 0.70) and float(state.vulnerability_seconds) == 8.0, "뿌리 모두 제거 후 방어 감소·8초 취약")


func _test_time_cap_retry_and_metrics() -> void:
	var profile := BossScript.battle_profile(30, DataRegistry.enemies.rival_mirella_council_champion)
	var before := BossScript.time_cap_state(239.9, profile)
	var capped := BossScript.time_cap_state(240.0, profile)
	_expect(not bool(before.capped) and bool(before.regrowth_enabled), "시간 상한 전 재성장 유지")
	_expect(bool(capped.capped) and not bool(capped.regrowth_enabled) and bool(capped.clear_active_gardens) and float(capped.boss_incoming_damage_multiplier) == 1.50, "240초 장기전 상한·정원 해제·재성장 중지")
	var loss := BossScript.resolve_battle({}, 25, false, {"gardens_cleansed": 2, "roots_destroyed": 0})
	_expect(int(loss.retry_day) == 25 and str(loss.return_screen) == "management", "DAY 25 패배 관리 복귀·재도전")
	_expect(int(loss.active_run.run_metrics_update4.rival_bosses.rival_mirella.losses) == 1 and int(loss.active_run.run_metrics_update4.rival_bosses.rival_mirella.gardens_cleansed) == 2, "패배·정원 정화 지표")
	var win := BossScript.resolve_battle(loss.active_run, 30, true, {"gardens_cleansed": 1, "roots_destroyed": 3})
	_expect(int(win.retry_day) == 0 and int(win.active_run.run_metrics_update4.rival_bosses.rival_mirella.wins) == 1, "DAY 30 승리·결산 이동")
	_expect(int(win.active_run.run_metrics_update4.rival_bosses.rival_mirella.gardens_cleansed) == 3 and int(win.active_run.run_metrics_update4.rival_bosses.rival_mirella.roots_destroyed) == 3, "정원·뿌리 누적 지표")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[MirellaBossPhase24] FAIL: %s" % label)
