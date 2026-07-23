extends Node

const FlowService = preload("res://scripts/v20/flow/V20DayFlowService.gd")
const SessionService = preload("res://scripts/v20/session/V20SessionService.gd")
const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_exact_transition_graph()
	_test_defense_start_placement_gate()
	_test_snapshot_retry_and_budget_invariants()
	_test_one_hundred_day_transitions()
	_test_acceptance_entry_contract()
	if failed:
		print("V20_DAY_FLOW_STATE_MACHINE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_DAY_FLOW_STATE_MACHINE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_exact_transition_graph() -> void:
	var states: Array = FlowService.STATES
	var allowed := {
		"INTRUSION_BRIEF>PLACEMENT": {"action": "placement_start"},
		"PLACEMENT>DEFENSE_START": {"placement_valid": true},
		"DEFENSE_START>COMBAT": {"snapshot_saved": true, "spatial_resolved": true, "countdown_complete": true},
		"DEFENSE_START>PLACEMENT": {"cancel_or_error": true},
		"COMBAT>RESULT": {"battle_finished": true},
		"RESULT>INTRUSION_BRIEF": {"win": true, "day": 1},
		"RESULT>PLACEMENT": {"win": false, "retry_mode": "edit"},
		"RESULT>DEFENSE_START": {"win": false, "retry_mode": "same"}
	}
	var accepted := 0
	for from_state in states:
		for to_state in states:
			var key := "%s>%s" % [from_state, to_state]
			var result := FlowService.can_transition(str(from_state), str(to_state), allowed.get(key, {}))
			var expected := allowed.has(key)
			_expect(bool(result.get("ok", false)) == expected, "상태 edge %s는 %s" % [key, "허용" if expected else "거부"])
			accepted += 1 if bool(result.get("ok", false)) else 0
	_expect(accepted == 8, "허용 edge는 정확히 8개")
	_expect(not bool(FlowService.can_transition(FlowService.RESULT, FlowService.INTRUSION_BRIEF, {"win": true, "day": 5}).get("ok", true)), "DAY 5 승리 RESULT는 terminal")
	_expect(not bool(FlowService.can_transition(FlowService.DEFENSE_START, FlowService.COMBAT, {"snapshot_saved": true, "spatial_resolved": true, "countdown_complete": false}).get("ok", true)), "3초 countdown 완료 전 COMBAT 진입 거부")


func _test_defense_start_placement_gate() -> void:
	var valid := SessionService.initial_placement_state(10)
	var validation := FlowService.validate_defense_placement(valid, DataRegistry.v20_facilities)
	_expect(bool(validation.get("ok", false)) and int(validation.get("installed_cost", -1)) == 0 and int(validation.get("available_build_points", -1)) == 10, "초기 몬스터 3종 고유 슬롯과 시설비 0은 방어 시작 가능")

	var duplicate_slot := valid.duplicate(true)
	duplicate_slot["roster"]["goblin"]["monster_slot_id"] = duplicate_slot["roster"]["slime"]["monster_slot_id"]
	_expect(not bool(FlowService.validate_defense_placement(duplicate_slot, DataRegistry.v20_facilities).get("ok", true)), "몬스터 slot 중복이면 방어 시작 거부")

	var missing_monster := valid.duplicate(true)
	missing_monster["rooms"]["throne_anteroom"]["monster_ids"] = []
	missing_monster["roster"]["imp"]["room_id"] = ""
	missing_monster["roster"]["imp"]["monster_slot_id"] = ""
	_expect(not bool(FlowService.validate_defense_placement(missing_monster, DataRegistry.v20_facilities).get("ok", true)), "몬스터 하나가 미배치면 방어 시작 거부")

	var over_capacity := valid.duplicate(true)
	over_capacity["rooms"]["gate_outpost"]["monster_ids"] = ["slime", "goblin", "imp"]
	for monster_id in ["slime", "goblin", "imp"]:
		over_capacity["roster"][monster_id]["room_id"] = "gate_outpost"
		over_capacity["roster"][monster_id]["monster_slot_id"] = "gate_outpost_monster_%d" % (over_capacity["rooms"]["gate_outpost"]["monster_ids"].find(monster_id) + 1)
	_expect(not bool(FlowService.validate_defense_placement(over_capacity, DataRegistry.v20_facilities).get("ok", true)), "한 zone 몬스터 3명은 방어 시작 거부")

	var over_budget := valid.duplicate(true)
	over_budget["rooms"]["gate_outpost"]["facility_id"] = "v20_barracks"
	over_budget["rooms"]["spike_corridor"]["facility_id"] = "v20_watch_post"
	over_budget["rooms"]["central_battle_room"]["facility_id"] = "v20_recovery_nest"
	_expect(not bool(FlowService.validate_defense_placement(over_budget, DataRegistry.v20_facilities).get("ok", true)), "시설 총비용 12는 상한 10 위반")


func _test_snapshot_retry_and_budget_invariants() -> void:
	var session := SessionService.new_session("v20_tactician", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
	session = SessionService.begin_placement(session).get("state", {})
	var installed := PlacementService.place_facility_drag(session.get("placement_state", {}), "v20_watch_post", "gate_outpost", DataRegistry.v20_facilities)
	session = SessionService.record_placement(session, installed.get("state", {}), installed, DataRegistry.v20_onboarding)
	var runtime := _runtime_fixture()
	session["acceptance"] = {"scenario_id": "C", "seed_map": {1: 2001}}
	var defense := SessionService.begin_defense_start(session, DataRegistry.v20_facilities, runtime, 2001, 99112233)
	_expect(bool(defense.get("ok", false)), "유효 배치 snapshot 저장 뒤 DEFENSE_START 진입")
	session = defense.get("state", {})
	var fingerprint := FlowService.snapshot_fingerprint(session.get("precombat_snapshot", {}))
	session = SessionService.advance_defense_countdown(session, 3.0)
	session = SessionService.begin_combat(session, true, true, true).get("state", {})
	session = SessionService.finalize_battle(session, _loss_result(), DataRegistry.v20_economy).get("state", {})
	var mutated := session.duplicate(true)
	mutated["runtime_state"] = {"command": {"points": 0}, "monsters": {"slime": {"hp": 1}}, "facilities": {}}
	for retry_mode in ["edit", "same"]:
		var retried := SessionService.retry(mutated, retry_mode, DataRegistry.v20_facilities)
		_expect(bool(retried.get("ok", false)), "패배 뒤 %s 재도전 허용" % retry_mode)
		var restored: Dictionary = retried.get("state", {})
		_expect(FlowService.snapshot_fingerprint(restored.get("precombat_snapshot", {})) == fingerprint, "%s 재도전의 전투 직전 fingerprint 동일" % retry_mode)
		_expect(restored.get("runtime_state", {}) == runtime and int(restored.get("encounter_seed", 0)) == 2001 and int(restored.get("rng_state", 0)) == 99112233, "%s 재도전이 HP·mana·명령·쿨다운·시설·seed·RNG 전체 복원" % retry_mode)
		_expect(str(restored.get("acceptance", {}).get("scenario_id", "")) == "C", "C 패배 재도전이 scenario와 seed/RNG snapshot을 유지")
		_expect(str(restored.get("flow_state", "")) == (FlowService.PLACEMENT if retry_mode == "edit" else FlowService.DEFENSE_START), "%s 재도전 목표 상태 고정" % retry_mode)

	for index in range(100):
		var loop_session := SessionService.new_session("v20_tactician", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
		loop_session = SessionService.begin_placement(loop_session).get("state", {})
		var placed := PlacementService.place_facility_drag(loop_session.get("placement_state", {}), "v20_barricade", "gate_outpost", DataRegistry.v20_facilities)
		loop_session = SessionService.record_placement(loop_session, placed.get("state", {}), placed, DataRegistry.v20_onboarding)
		var started := SessionService.begin_defense_start(loop_session, DataRegistry.v20_facilities, _runtime_fixture(), 2001, 1000 + index)
		loop_session = SessionService.advance_defense_countdown(started.get("state", {}), 3.0)
		loop_session = SessionService.begin_combat(loop_session, true, true, true).get("state", {})
		loop_session = SessionService.finalize_battle(loop_session, _loss_result(), DataRegistry.v20_economy).get("state", {})
		loop_session = SessionService.retry(loop_session, "edit", DataRegistry.v20_facilities).get("state", {})
		var budget := FlowService.validate_defense_placement(loop_session.get("placement_state", {}), DataRegistry.v20_facilities)
		_expect(int(budget.get("installed_cost", -1)) == 3 and int(budget.get("available_build_points", -1)) == 7, "retry %03d회째 시설비 3·사용 가능 7 불변" % (index + 1))


func _test_acceptance_entry_contract() -> void:
	for day in range(1, 6):
		for seed in [2000 + day, 3000 + day, 4000 + day]:
			for scenario_id in FlowService.ACCEPTANCE_SCENARIOS:
				var accepted := FlowService.begin_acceptance_case({}, day, seed, scenario_id, true, false)
				_expect(bool(accepted.get("ok", false)), "debug acceptance DAY %d seed %d %s 허용" % [day, seed, scenario_id])
	_expect(not bool(FlowService.begin_acceptance_case({}, 1, 9999, "A", true, false).get("ok", true)), "protocol 밖 seed 거부")
	_expect(not bool(FlowService.begin_acceptance_case({}, 1, 2001, "UNKNOWN", true, false).get("ok", true)), "미등록 scenario 거부")
	_expect(not bool(FlowService.begin_acceptance_case({}, 1, 2001, "A", false, false).get("ok", true)), "release export acceptance 거부")
	_expect(not bool(FlowService.begin_acceptance_case({}, 1, 2001, "A", true, true).get("ok", true)), "product mode acceptance case 거부")
	_expect(not bool(FlowService.begin_acceptance_case({"flow_state": FlowService.COMBAT}, 1, 2001, "A", true, false).get("ok", true)), "COMBAT 이후 acceptance case 호출 거부")
	_expect(not bool(FlowService.begin_acceptance_case({"flow_state": FlowService.PLACEMENT}, 1, 2001, "A", true, false).get("ok", true)), "INTRUSION_BRIEF 진입 뒤 acceptance case 호출 거부")

	var seed_text := "1:2001,2:2002,3:2003,4:2004,5:2005"
	var windows := FlowService.parse_acceptance_sources(["--v20-acceptance", "--v20-seed-map=%s" % seed_text, "--v20-scenario=FREE"], "", true)
	var web := FlowService.parse_acceptance_sources([], "?v20_acceptance=1&v20_seed_map=%s&v20_scenario=FREE" % seed_text.uri_encode(), true)
	_expect(bool(windows.get("ok", false)) and bool(web.get("ok", false)) and windows.get("seed_map", {}) == web.get("seed_map", {}), "Windows args와 Web query가 같은 canonical seed map 생성")
	_expect(not bool(FlowService.parse_acceptance_sources(["--v20-acceptance", "--v20-seed-map=%s" % seed_text, "--v20-scenario=FREE"], "?v20_acceptance=1&v20_seed_map=%s&v20_scenario=FREE" % seed_text.uri_encode(), true).get("ok", true)), "Windows와 Web acceptance 동시 입력 거부")
	var campaign := FlowService.begin_acceptance_campaign(windows.get("seed_map", {}), "FREE", true, false)
	_expect(bool(campaign.get("ok", false)), "DAY 1~5 고유 seed FREE campaign 허용")
	_expect(not bool(FlowService.begin_acceptance_campaign({1: 2001, 2: 2002}, "FREE", true, false).get("ok", true)), "DAY 누락 seed map 거부")
	_expect(not bool(FlowService.begin_acceptance_campaign({1: 2001, 2: 2001, 3: 2003, 4: 2004, 5: 2005}, "FREE", true, false).get("ok", true)), "중복 seed map 거부")
	_expect(not bool(FlowService.begin_acceptance_campaign(windows.get("seed_map", {}), "A", true, false).get("ok", true)), "campaign scenario는 FREE 외 거부")
	_expect(not bool(FlowService.begin_acceptance_campaign(windows.get("seed_map", {}), "FREE", true, true).get("ok", true)), "product mode acceptance campaign 거부")
	_expect(str(campaign.get("placement_fingerprint", "x")) == "", "FREE campaign은 배치를 주입하지 않음")


func _test_one_hundred_day_transitions() -> void:
	for index in range(100):
		var session := SessionService.new_session("v20_tactician", DataRegistry.v20_economy, DataRegistry.v20_onboarding)
		session = SessionService.begin_placement(session).get("state", {})
		var installed := PlacementService.place_facility_drag(session.get("placement_state", {}), "v20_watch_post", "gate_outpost", DataRegistry.v20_facilities)
		session = SessionService.record_placement(session, installed.get("state", {}), installed, DataRegistry.v20_onboarding)
		var runtime := FlowService.new_day_runtime(session.get("placement_state", {}), DataRegistry.monsters, DataRegistry.v20_commands, DataRegistry.v20_facilities)
		var defense := SessionService.begin_defense_start(session, DataRegistry.v20_facilities, runtime, 2001, 7000 + index)
		session = SessionService.advance_defense_countdown(defense.get("state", {}), 3.0)
		session = SessionService.begin_combat(session).get("state", {})
		var win := {"win": true, "lines": [], "metrics": {"combat_time": 52.0, "alive_monsters": 3, "total_monsters": 3, "demon_lord_hp": 1500, "treasure_gold_stolen": 0, "facility_disables": 0}}
		session = SessionService.finalize_battle(session, win, DataRegistry.v20_economy).get("state", {})
		var advanced := SessionService.advance_after_win(session, DataRegistry.v20_facilities, DataRegistry.monsters, DataRegistry.v20_commands)
		_expect(bool(advanced.get("ok", false)), "DAY transition %03d회 허용" % (index + 1))
		session = advanced.get("state", {})
		var placement_check := FlowService.validate_defense_placement(session.get("placement_state", {}), DataRegistry.v20_facilities)
		_expect(int(session.get("day", 0)) == 2 and str(session.get("flow_state", "")) == FlowService.INTRUSION_BRIEF, "DAY transition %03d회가 DAY 2 침입 확인 도달" % (index + 1))
		_expect(int(placement_check.get("installed_cost", -1)) == 4 and int(placement_check.get("available_build_points", -1)) == 6 and str(session.get("placement_state", {}).get("rooms", {}).get("gate_outpost", {}).get("facility_id", "")) == "v20_watch_post", "DAY transition %03d회 배치 보존·시설비 4·사용 가능 6" % (index + 1))
		var next_runtime: Dictionary = session.get("runtime_state", {})
		var command: Dictionary = next_runtime.get("command", {})
		_expect(int(command.get("points", 0)) == 3 and int(command.get("max_points", 0)) == 3 and float(command.get("recharge_progress", -1.0)) == 0.0 and command.get("cooldowns", {}).values().all(func(value): return float(value) == 0.0), "DAY transition %03d회 명령 3/3·충전/쿨다운 0" % (index + 1))
		var resources: Dictionary = next_runtime.get("resources", {})
		_expect(int(resources.get("demon_lord_hp", 0)) == 1500 and int(resources.get("demon_lord_max_hp", 0)) == 1500 and int(resources.get("mana", 0)) == 320, "DAY transition %03d회 실제 HP 1500/1500·mana 320 초기화" % (index + 1))
		var monsters_ok := true
		for monster_id in FlowService.REQUIRED_MONSTERS:
			var monster: Dictionary = next_runtime.get("monsters", {}).get(monster_id, {})
			monsters_ok = monsters_ok and int(monster.get("level", 0)) == 1 and int(monster.get("exp", -1)) == 0
			monsters_ok = monsters_ok and int(monster.get("hp", 0)) == int(monster.get("max_hp", -1)) and int(monster.get("mana", -1)) == int(monster.get("max_mana", -2))
			monsters_ok = monsters_ok and float(monster.get("status_seconds", -1.0)) == 0.0 and monster.get("skill_cooldowns", {}).values().all(func(value): return float(value) == 0.0)
		_expect(monsters_ok, "DAY transition %03d회 몬스터 level 1·EXP 0·HP/mana max·상태/쿨다운 0" % (index + 1))
		var facility: Dictionary = next_runtime.get("facilities", {}).get("gate_outpost", {})
		_expect(int(facility.get("charges", -1)) == int(DataRegistry.v20_facilities.get("v20_watch_post", {}).get("activation", {}).get("charges", -2)) and float(facility.get("active_seconds", -1.0)) == 0.0 and float(facility.get("disabled_seconds", -1.0)) == 0.0, "DAY transition %03d회 시설 charge max·active/disable 0" % (index + 1))


func _runtime_fixture() -> Dictionary:
	return {
		"monsters": {
			"slime": {"level": 1, "exp": 0, "hp": 180, "max_hp": 180, "mana": 0, "max_mana": 0, "skill_cooldowns": {"slime_shield": 0.0}, "status_seconds": 0.0},
			"goblin": {"level": 1, "exp": 0, "hp": 140, "max_hp": 140, "mana": 0, "max_mana": 0, "skill_cooldowns": {"quick_slash": 0.0}, "status_seconds": 0.0},
			"imp": {"level": 1, "exp": 0, "hp": 120, "max_hp": 120, "mana": 0, "max_mana": 0, "skill_cooldowns": {"fireball": 0.0}, "status_seconds": 0.0}
		},
		"command": {"points": 3, "max_points": 3, "recharge_progress": 0.0, "cooldowns": {"v20_rally": 0.0}},
		"facilities": {"gate_outpost": {"charges": 2, "active_seconds": 0.0, "disabled_seconds": 0.0}}
	}


func _loss_result() -> Dictionary:
	return {"win": false, "lines": [], "metrics": {"combat_time": 48.0, "alive_monsters": 0, "total_monsters": 3, "demon_lord_hp": 0, "treasure_gold_stolen": 0, "facility_disables": 0}}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20DayFlow] FAIL: %s" % message)
