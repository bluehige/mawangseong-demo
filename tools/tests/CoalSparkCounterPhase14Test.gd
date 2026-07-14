extends Node

const CounterScript = preload("res://scripts/systems/enemies/CoalSparkCounterService.gd")
const SilkyScript = preload("res://scripts/systems/monsters/SilkyCombatService.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_enemy_data_and_goal()
	_test_thread_counter()
	_test_efficiency_bounds()
	_test_alternative_response()
	if failed:
		print("COAL_SPARK_COUNTER_PHASE14_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("COAL_SPARK_COUNTER_PHASE14_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_enemy_data_and_goal() -> void:
	_expect(DataRegistry.enemies.has("coal_spark") and is_equal_approx(float(DataRegistry.enemies.coal_spark.threat), 0.85), "숯불 정령 데이터·threat 0.85")
	var unit = UnitScript.new()
	add_child(unit)
	unit.setup("coal_spark", DataRegistry.enemies.coal_spark, "enemy", "upper_stair")
	_expect(unit.max_hp == 75 and unit.atk == 12 and unit.def == 1 and is_equal_approx(unit.move_speed, 145.0), "숯불 정령 placeholder Unit 능력치")
	unit.queue_free()
	_expect(CounterScript.choose_objective({"objective_hp": {"crown_sanctum": 600}}, true) == "crown_sanctum", "활성 왕관실 목표 이동")
	_expect(CounterScript.choose_objective({"objective_hp": {"crown_sanctum": 0}}, true) == "heart_chamber", "왕관실 무력화 후 심장 목표 이동")
	var entered := CounterScript.enter_objective("coal_1", "crown_sanctum", DataRegistry.skills.residual_heat)
	_expect(bool(entered.heat_zone.active) and is_equal_approx(float(entered.heat_zone.duration), 4.0) and not bool(entered.death_explosion), "목표 진입 잔열 4초·사망 폭발 없음")


func _test_thread_counter() -> void:
	var placed := SilkyScript.place_thread(SilkyScript.new_state(), "stair", ["stair"], "", DataRegistry.skills.stitch_stairway)
	var contact := CounterScript.contact_thread(placed.state.thread, DataRegistry.enemies.coal_spark)
	_expect(int(contact.durability_damage) == 2 and bool(contact.removed), "숯불 정령 접촉 거미실 내구 2 감소·기본 실 제거")
	var warden := SilkyScript.place_thread(SilkyScript.new_state(), "stair", ["stair"], "silky_stair_warden", DataRegistry.skills.stitch_stairway)
	var warden_contact := CounterScript.contact_thread(warden.state.thread, DataRegistry.enemies.coal_spark)
	_expect(bool(warden_contact.thread.active) and int(warden_contact.thread.fire_durability) == 1, "계단 파수 재봉은 접촉 1회 후 내구 1 유지")


func _test_efficiency_bounds() -> void:
	for specialization_id in ["", "silky_stair_warden", "silky_field_tailor"]:
		var trial := CounterScript.silky_efficiency_trial(specialization_id, 1)
		_expect(float(trial.efficiency_reduction_ratio) >= 0.20 and float(trial.efficiency_reduction_ratio) <= 0.35, "%s 실키 효율 20~35%% 감소" % (specialization_id if specialization_id != "" else "기본"))
		_expect(float(trial.countered_control_seconds) > 0.0, "%s 카운터 후 실키 기능 잔존" % (specialization_id if specialization_id != "" else "기본"))


func _test_alternative_response() -> void:
	var fast := CounterScript.alternative_response(DataRegistry.enemies.coal_spark, 18.0, 0.0)
	var controlled := CounterScript.alternative_response(DataRegistry.enemies.coal_spark, 8.0, 2.0)
	_expect(bool(fast.viable) and not bool(fast.requires_silky), "실키 없이 빠른 추격 화력 대응")
	_expect(bool(controlled.viable) and not bool(controlled.requires_silky), "실키 없이 표식·제어 대응")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[CoalSparkCounterPhase14] FAIL: %s" % label)
