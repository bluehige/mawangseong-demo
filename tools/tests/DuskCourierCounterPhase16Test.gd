extends Node

const DuskScript = preload("res://scripts/systems/enemies/DuskCourierCounterService.gd")
const PopoScript = preload("res://scripts/systems/monsters/PopoCombatService.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_and_shortcut()
	_test_theft_flow()
	_test_popo_hold_and_counter_bounds()
	_test_alternative_response()
	if failed:
		print("DUSK_COURIER_COUNTER_PHASE16_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("DUSK_COURIER_COUNTER_PHASE16_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_data_and_shortcut() -> void:
	var definition: Dictionary = DataRegistry.enemies.dusk_courier
	_expect(is_equal_approx(float(definition.threat), 1.0) and int(definition.max_simultaneous) == 2, "황혼 전령 threat 1.00·동시 최대 2명")
	var unit = UnitScript.new()
	add_child(unit)
	unit.setup("dusk_courier", definition, "enemy", "vent_entry")
	_expect(unit.max_hp == 85 and is_equal_approx(unit.move_speed, 175.0), "황혼 전령 저체력·고기동 placeholder Unit")
	unit.queue_free()
	_expect(DuskScript.can_spawn(0, definition) and DuskScript.can_spawn(1, definition) and not DuskScript.can_spawn(2, definition), "황혼 전령 동시 병목 2명 제한")
	var castle_path := DuskScript.air_shortcut_path("1F", "seal_vault", false)
	var outpost_path := DuskScript.air_shortcut_path("1F", "outpost_cache", true)
	_expect(castle_path.size() == 3 and str(castle_path[-1].node) == "seal_vault" and not castle_path.any(func(node): return node.node == "throne"), "공중 지름길 인장 금고 endpoint·왕좌 직행 금지")
	_expect(str(outpost_path[-1].node) == "outpost_cache", "전초기지 보급 창고 목표")


func _test_theft_flow() -> void:
	var skill: Dictionary = DataRegistry.skills.seal_envelope
	var state := DuskScript.start_theft(DuskScript.new_theft_state("dusk_1", skill), skill, 2.0)
	_expect(str(state.phase) == "warning" and is_equal_approx(float(state.retry_remaining), 2.0), "포포 경보 적용 절도 2초 예고")
	state = DuskScript.tick_theft(state, 2.0)
	_expect(str(state.phase) == "channel" and is_equal_approx(float(state.channel_remaining), 4.0), "예고 종료 후 4초 절도 채널")
	state = DuskScript.tick_theft(state, 1.0)
	state = DuskScript.receive_damage(state, skill)
	_expect(str(state.phase) == "retry_wait" and int(state.damage_interrupts) == 1 and bool(state.blocked), "피해로 절도 차단·1초 재시도")
	state = DuskScript.tick_theft(state, 1.0)
	state = DuskScript.tick_theft(state, 4.0)
	_expect(bool(state.completed), "재시도 후 절도 완료")


func _test_popo_hold_and_counter_bounds() -> void:
	var bag := PopoScript.hold_first_theft(PopoScript.new_bag_state(), "dusk_1", "", DataRegistry.skills.messenger_bag)
	var recovered := PopoScript.arrive_at_thief(bag.state, "dusk_1")
	_expect(bool(bag.held) and bool(recovered.recovered), "포포 절도 보류·회수")
	var failed_hold := PopoScript.hold_first_theft(PopoScript.new_bag_state(), "dusk_2", "", DataRegistry.skills.messenger_bag)
	var finalized := PopoScript.tick_bag(failed_hold.state, 5.0)
	_expect(bool(finalized.loss_finalized), "포포 미도달 시 절도 정상 완료")
	for specialization_id in ["", "popo_seal_guard"]:
		var trial := DuskScript.popo_efficiency_trial(2, specialization_id)
		_expect(float(trial.efficiency_reduction_ratio) >= 0.20 and float(trial.efficiency_reduction_ratio) <= 0.30, "%s 포포 효율 감소 20~30%%" % (specialization_id if specialization_id != "" else "기본"))


func _test_alternative_response() -> void:
	var watch_and_gob := DuskScript.alternative_response(2, 1, 2.0, false)
	var split_guard := DuskScript.alternative_response(2, 0, 2.0, true)
	_expect(bool(watch_and_gob.viable) and not bool(watch_and_gob.requires_popo), "곱·감시초소 비포포 대응")
	_expect(bool(split_guard.viable) and not bool(split_guard.requires_popo), "상층 분산 배치 비포포 대응")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[DuskCourierCounterPhase16] FAIL: %s" % label)
