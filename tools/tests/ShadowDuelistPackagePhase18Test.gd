extends Node

const PressureScript = preload("res://scripts/systems/enemies/ShadowDuelistPressureService.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_and_targeting()
	_test_shadow_promise()
	_test_overlays_and_waves()
	_test_counter_budget()
	if failed:
		print("SHADOW_DUELIST_PACKAGE_PHASE18_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("SHADOW_DUELIST_PACKAGE_PHASE18_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_data_and_targeting() -> void:
	var enemy: Dictionary = DataRegistry.enemies.get("shadow_duelist", {})
	_expect(is_equal_approx(float(enemy.get("threat", 0.0)), 1.35) and bool(enemy.get("placeholder_art", false)), "그림자 결투사 threat 1.35·placeholder")
	var unit = UnitScript.new()
	add_child(unit)
	unit.setup("shadow_duelist", enemy, "enemy", "entrance")
	_expect(unit.max_hp == 125 and unit.atk == 17 and unit.def == 4 and is_equal_approx(unit.move_speed, 140.0), "그림자 결투사 HP·ATK·DEF·speed 계약")
	unit.queue_free()
	var candidates := [{"id": "crowned", "active": true, "has_crown": true}, {"id": "worker", "active": true, "has_crown": false}]
	_expect(PressureScript.select_target(candidates, {"crowned": 25.0, "worker": 52.0}) == "worker", "왕관이 아닌 최근 12초 최고 기여 대상")
	_expect(PressureScript.select_target(candidates, {"crowned": 60.0, "worker": 30.0}) == "crowned", "왕관 대상도 기여도가 높을 때만 선정")


func _test_shadow_promise() -> void:
	var skill: Dictionary = DataRegistry.skills.shadow_promise
	var result := PressureScript.shadow_promise({"floor_id": "upper_02", "position_x": 300.0, "facing_x": 1.0}, skill, false, "upper_02")
	_expect(bool(result.ok) and is_equal_approx(float(result.position_x), 210.0), "같은 층 대상 뒤 90px 이동")
	_expect(is_equal_approx(float(result.duration), 2.0) and float(result.atk_multiplier) > 1.0 and float(result.def_multiplier) < 1.0, "이동 후 2초 공격 증가·방어 감소")
	_expect(not bool(PressureScript.shadow_promise({"floor_id": "upper_02"}, skill, true, "upper_02").ok), "그림자 약속 전투당 1회")
	_expect(not bool(PressureScript.shadow_promise({"floor_id": "lower_01"}, skill, false, "upper_02").ok), "다른 층 직접 순간이동 금지")


func _test_overlays_and_waves() -> void:
	var overlays: Dictionary = DataRegistry.update4_region_day_overlays
	var moon: Dictionary = overlays.get("moonbat_cross_floor_pressure", {})
	var black: Dictionary = overlays.get("blackwater_cross_floor_pressure", {})
	_expect(is_equal_approx(float(moon.get("first_entry_delay_seconds", 0.0)), 3.0) and is_equal_approx(float(moon.get("reinforcement_interval_multiplier", 0.0)), 0.90), "월박쥐 첫 진입 +3초·증원 -10%")
	_expect(is_equal_approx(float(black.get("battle_gold_multiplier", 0.0)), 1.15) and is_equal_approx(float(black.get("treasure_loss_multiplier", 0.0)), 1.20), "검은물 금화 +15%·손실 +20%")
	var moon_wave := PressureScript.cross_floor_wave("region_moonbat_aerie", DataRegistry.enemies)
	var black_wave := PressureScript.cross_floor_wave("region_blackwater_exchange", DataRegistry.enemies)
	_expect(moon_wave.floors.size() == 2 and str(moon_wave.floors[1].floor_id) == "upper_02", "월박쥐 층간 웨이브")
	_expect(black_wave.floors.size() == 2 and str(black_wave.floors[1].floor_id) == "upper_02", "검은물 층간 웨이브")
	_expect(bool(moon_wave.within_budget) and bool(black_wave.within_budget), "두 지역 threat 목표 ±5%")
	_expect(absf(float(moon_wave.threat) - float(black_wave.threat)) <= 0.17, "지역 간 threat 예산 편차 ±5%")


func _test_counter_budget() -> void:
	var trial := PressureScript.focus_efficiency_trial(1)
	_expect(float(trial.efficiency_reduction_ratio) >= 0.20 and float(trial.efficiency_reduction_ratio) <= 0.30 and float(trial.effective_seconds) > 0.0, "집중 몬스터 효율 20~30% 감소·기능 잔존")
	_expect(bool(PressureScript.protection_response(true, false, false, false).viable), "푸딩 보호 대응")
	_expect(bool(PressureScript.protection_response(false, true, false, false).viable), "베베 구조 대응")
	_expect(bool(PressureScript.protection_response(false, false, true, true).viable), "실키 응급 실밥·층 이동 대응")
	_expect(not bool(PressureScript.protection_response(false, false, false, false).requires_crown), "대응에 왕관 강제 없음")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[ShadowDuelistPackagePhase18] FAIL: %s" % label)
