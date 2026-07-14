extends Node

const PressureScript = preload("res://scripts/systems/enemies/BronzeAutomatonPressureService.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_and_combat_rules()
	_test_facility_pressure_variants()
	_test_wave_and_counter_budget()
	if failed:
		print("BRONZE_AUTOMATON_PACKAGE_PHASE17_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("BRONZE_AUTOMATON_PACKAGE_PHASE17_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_data_and_combat_rules() -> void:
	var enemy: Dictionary = DataRegistry.enemies.get("bronze_automaton", {})
	_expect(is_equal_approx(float(enemy.get("threat", 0.0)), 1.45) and bool(enemy.get("placeholder_art", false)), "청동 자동병 threat 1.45·placeholder")
	var unit = UnitScript.new()
	add_child(unit)
	unit.setup("bronze_automaton", enemy, "enemy", "entrance")
	_expect(unit.max_hp == 175 and unit.atk == 13 and unit.def == 9 and is_equal_approx(unit.move_speed, 72.0), "청동 자동병 HP·ATK·DEF·speed 계약")
	unit.queue_free()
	_expect(is_equal_approx(PressureScript.apply_heavy_body(100.0, DataRegistry.skills.heavy_body), 50.0), "무거운 몸 밀림 50% 감소")
	var brace := PressureScript.brace_state(9, DataRegistry.skills.brace_wedge)
	_expect(is_equal_approx(float(brace.duration), 4.0) and int(brace.def) == 12 and is_zero_approx(float(brace.move_multiplier)), "버팀 쐐기 4초·방어 +25%·이동 정지")
	_expect(PressureScript.can_enter_stair(0, enemy) and not PressureScript.can_enter_stair(1, enemy), "계단 자동병 전이 동시 1명 병목")
	var goal := PressureScript.choose_goal([{"id": "trap_room", "hp": 45, "max_hp": 100, "active": true}, {"id": "barracks", "hp": 90, "max_hp": 100, "active": true}], 0)
	_expect(goal == "trap_room", "손상 시설 우선 목표")
	_expect(PressureScript.choose_goal([], 0) == "upper_stair", "시설 부재 시 계단 목표")


func _test_facility_pressure_variants() -> void:
	var overlays: Dictionary = DataRegistry.update4_region_day_overlays
	var a: Dictionary = overlays.get("ironbell_facility_pressure_a", {})
	var b: Dictionary = overlays.get("ironbell_facility_pressure_b", {})
	_expect(str(a.get("variant", "")) == "facility_pressure_a" and str(a.get("primary_goal", "")) == "facility", "철종 facility pressure A")
	_expect(str(b.get("variant", "")) == "facility_pressure_b" and str(b.get("primary_goal", "")) == "stair", "철종 facility pressure B")
	var pressure := PressureScript.facility_pressure(100, 100, a)
	_expect(int(pressure.damage) == 108 and int(pressure.repair) == 112, "시설 피해 +8%·수리 +12% overlay")
	_expect(str(b.get("outpost_wave_modifier", "")) == "ironbell_reinforced_frontline", "전초기지 웨이브 변형 연결")


func _test_wave_and_counter_budget() -> void:
	var wave := PressureScript.outpost_wave_variant(DataRegistry.enemies)
	_expect(wave.counts == {"bronze_automaton": 1, "coal_spark": 3}, "전초기지 청동 1·숯불 3 변형")
	_expect(bool(wave.within_budget) and is_equal_approx(float(wave.threat), 4.0), "전초기지 threat 4.0 예산")
	var trial := PressureScript.fixed_defense_efficiency_trial(1)
	_expect(float(trial.efficiency_reduction_ratio) >= 0.20 and float(trial.efficiency_reduction_ratio) <= 0.30 and float(trial.countered_uptime) > 0.0, "시설 고정 방어 효율 20~30% 감소·기능 잔존")
	_expect(bool(PressureScript.alternative_response(0.25, 0.0, false).viable), "방어 파괴 대응 가능")
	_expect(bool(PressureScript.alternative_response(0.0, 18.0, false).viable), "마법 피해 대응 가능")
	_expect(bool(PressureScript.alternative_response(0.0, 0.0, true).viable), "우회 추격 대응 가능")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[BronzeAutomatonPackagePhase17] FAIL: %s" % label)
