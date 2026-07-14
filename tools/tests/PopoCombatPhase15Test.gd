extends Node

const PopoScript = preload("res://scripts/systems/monsters/PopoCombatService.gd")
const MultiFloorScript = preload("res://scripts/systems/multifloor/MultiFloorGraphService.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_and_weakness()
	_test_relay_and_alarm()
	_test_messenger_bag()
	_test_floor_transition()
	if failed:
		print("POPO_COMBAT_PHASE15_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("POPO_COMBAT_PHASE15_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_data_and_weakness() -> void:
	_expect(DataRegistry.monsters.has("bat_courier") and DataRegistry.monster_instances.has("MON_POPO") and DataRegistry.characters.has("CHR_POPO"), "포포 species·instance·character 분리 로드")
	_expect(DataRegistry.skills.has("night_relay") and DataRegistry.skills.has("echo_alarm") and DataRegistry.skills.has("messenger_bag"), "포포 액티브 2개·패시브 1개")
	_expect(DataRegistry.specializations.has("popo_royal_express") and DataRegistry.specializations.has("popo_seal_guard"), "포포 전술 특화 2개")
	var definition: Dictionary = DataRegistry.monsters.bat_courier
	_expect(not bool(definition.placeholder_art) and str(definition.get("sprite", "")).ends_with("monster_bat_courier_sheet.png") and not definition.has("crown_form_id"), "Phase 30 포포 최종 16프레임·일반형 유지")
	var unit = UnitScript.new()
	add_child(unit)
	unit.setup("bat_courier", definition, "monster", "upper_stair")
	_expect(unit.max_hp == 110 and unit.def == 2 and is_equal_approx(unit.move_speed, 170.0), "포포 낮은 생존·높은 기동 능력치")
	_expect(unit.max_hp < DataRegistry.monsters.spider_tailor.max_hp and unit.def < DataRegistry.monsters.spider_tailor.def, "포포 낮은 생존 약점 유지")
	unit.queue_free()


func _test_relay_and_alarm() -> void:
	var target := PopoScript.choose_relay_target({"id": "MON_POPO", "floor_id": "1F"}, [{"id": "ally_1f", "floor_id": "1F", "distance": 400, "danger": 2, "alive": true}, {"id": "ally_2f", "floor_id": "2F", "distance": 100, "danger": 1, "alive": true}], [])
	_expect(str(target.target_id) == "ally_2f", "밤길 중계 다른 층 아군 우선")
	var relay := PopoScript.apply_night_relay(target, "", DataRegistry.skills.night_relay)
	_expect(is_equal_approx(float(relay.duration), 5.0) and is_equal_approx(float(relay.popo_buff.move_multiplier), 1.15) and is_equal_approx(float(relay.target_buff.attack_interval_multiplier), 0.90), "밤길 중계 5초 이동·공격 간격 버프")
	var express := PopoScript.apply_night_relay(target, "popo_royal_express", DataRegistry.skills.night_relay)
	_expect(is_equal_approx(float(express.popo_buff.move_multiplier), 1.20) and is_equal_approx(float(express.popo_buff.attack_interval_multiplier), 0.86), "왕성 특급 중계 강화")
	var outpost := PopoScript.choose_relay_target({"id": "MON_POPO", "floor_id": "1F"}, [], [{"room_id": "outpost_gate", "floor_id": "1F", "distance": 120}, {"room_id": "outpost_retreat", "floor_id": "1F", "distance": 420}])
	_expect(str(outpost.kind) == "danger_room" and str(outpost.room_id) == "outpost_retreat", "단일층 전초기지 먼 위험 방 fallback")
	var alarm := PopoScript.echo_alarm([{"id": "stealth_1", "role_tags": ["stealth"]}, {"id": "thief_1", "role_tags": ["seal_thief"]}, {"id": "boss_1", "role_tags": ["ambush"], "boss": true}, {"id": "plain", "role_tags": ["frontline"]}], DataRegistry.skills.echo_alarm)
	_expect(is_equal_approx(float(alarm.duration), 8.0) and alarm.revealed_ids.size() == 3, "메아리 경보 8초 은신·급습·절도 표시")
	_expect(is_equal_approx(float(alarm.interaction_delay_by_enemy.thief_1), 2.0) and is_equal_approx(float(alarm.interaction_delay_by_enemy.boss_1), 0.7), "목표 상호작용 일반 2초·보스 0.7초 지연")


func _test_messenger_bag() -> void:
	var held := PopoScript.hold_first_theft(PopoScript.new_bag_state(), "dusk_1", "", DataRegistry.skills.messenger_bag)
	_expect(bool(held.held) and is_equal_approx(float(held.state.pending.remaining), 5.0), "전령 가방 첫 절도 5초 보류")
	var arrived := PopoScript.arrive_at_thief(held.state, "dusk_1")
	_expect(bool(arrived.recovered) and int(arrived.state.recovered) == 1, "5초 안 도달 인장 회수")
	var second := PopoScript.hold_first_theft(arrived.state, "dusk_2", "", DataRegistry.skills.messenger_bag)
	_expect(not bool(second.held), "전투당 절도 보류 1회")
	var expiring := PopoScript.hold_first_theft(PopoScript.new_bag_state(), "dusk_3", "", DataRegistry.skills.messenger_bag)
	var expired := PopoScript.tick_bag(expiring.state, 5.0)
	_expect(bool(expired.loss_finalized) and int(expired.state.finalized_losses) == 1, "5초 미도달 정상 절도 처리")
	var guard := PopoScript.hold_first_theft(PopoScript.new_bag_state(), "dusk_4", "popo_seal_guard", DataRegistry.skills.messenger_bag)
	_expect(is_equal_approx(float(guard.state.pending.remaining), 7.0), "인장 회수반 보류 +2초")


func _test_floor_transition() -> void:
	_expect(PopoScript.choose_floor_transition("1F", {"1F": 1, "2F": 3}) == "2F", "포포 층 전이 AI 위험 층 선택")
	_expect(PopoScript.choose_floor_transition("1F", {"1F": 3, "2F": 1}, "2F") == "2F", "목표 공격 경보 층 우선")
	var graph := MultiFloorScript.build_graph(DataRegistry.rooms, MultiFloorScript.fixture_upper_rooms())
	var runtime := MultiFloorScript.register_entity(MultiFloorScript.new_runtime(), "MON_POPO", "monster", "1F", "spike_corridor")
	var requested := MultiFloorScript.request_transition(runtime, graph, "MON_POPO", "2F")
	var arrived := MultiFloorScript.tick(requested.runtime, 0.60)
	_expect(bool(requested.ok) and str(arrived.entities.MON_POPO.floor_id) == "2F", "포포 직접 조종 계단 전이 PASS")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[PopoCombatPhase15] FAIL: %s" % label)
