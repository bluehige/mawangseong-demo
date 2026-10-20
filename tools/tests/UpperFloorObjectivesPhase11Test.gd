extends Node

const ObjectiveScript = preload("res://scripts/systems/council/CouncilObjectiveService.gd")
const ExpansionScript = preload("res://scripts/systems/council/CouncilExpansionService.gd")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_modules_and_layout()
	_test_crown_objective()
	_test_seal_theft()
	_test_facility_scope()
	if failed:
		print("UPPER_FLOOR_OBJECTIVES_PHASE11_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPPER_FLOOR_OBJECTIVES_PHASE11_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_modules_and_layout() -> void:
	_expect(GameRootScript != null,"GameRoot first-floor objective parse")
	_expect(DataRegistry.update4_expansion_modules.size()==3,"crown/vault/facility retained, transition module removed")
	_expect(DataRegistry.quarter_modules.has("room_crown_sanctum") and DataRegistry.quarter_modules.has("room_seal_vault"),"objective room modules support actual automatic roads")


func _test_crown_objective() -> void:
	var active := _active_run()
	active = ExpansionScript.unlock_if_due(active,16,DataRegistry.update4_expansion_modules,3)
	_expect(int(active.expansion.objective_hp.crown_sanctum) == 600, "DAY 16 기본 레이아웃·왕관실 HP 600")
	_expect(ObjectiveScript.crown_max_hp(DataRegistry.update4_expansion_modules, 4) == 660, "왕성 단계 왕관실 HP 보정")
	var damaged := ObjectiveScript.damage_crown_sanctum(active, 700)
	_expect(bool(damaged.destroyed) and not bool(damaged.crown_passive_enabled) and not bool(damaged.crown_skill_enabled), "왕관실 0 HP 해당 전투 왕관 기능 정지")
	_expect(not bool(damaged.castle_defeat), "왕관실 무력화는 왕좌 패배 아님")
	var repaired := ObjectiveScript.repair_next_day(damaged.active_run, DataRegistry.update4_expansion_modules, 3)
	_expect(int(repaired.expansion.objective_hp.crown_sanctum) == 600 and int(repaired.expansion.repair_cost_gold) == 24 and not bool(repaired.expansion.crown_suppressed), "다음 DAY 자동 복구·수리 비용 기록")


func _test_seal_theft() -> void:
	var active := _active_run()
	active = ExpansionScript.unlock_if_due(active,16,DataRegistry.update4_expansion_modules,3)
	active.council_season.council_votes = 12
	active.council_season.council_seals = 3
	var battle := ObjectiveScript.new_battle_objectives(active, DataRegistry.update4_expansion_modules)
	battle = ObjectiveScript.start_seal_theft(battle, DataRegistry.update4_expansion_modules)
	battle = ObjectiveScript.tick_seal_theft(battle, 2.9)
	_expect(bool(battle.seal_theft.active) and float(battle.seal_theft.warning_remaining) > 0.0, "인장 절도 3초 예고 대응 창")
	battle = ObjectiveScript.tick_seal_theft(battle, 4.1)
	_expect(bool(battle.seal_theft.ready_to_settle), "예고 후 4초 채널 절도 완료")
	var settled := ObjectiveScript.settle_seal_theft(active, battle, DataRegistry.update4_expansion_modules)
	_expect(int(settled.active_run.council_season.council_votes) == 7 and int(settled.active_run.expansion.seal_theft_count) == 1, "절도 성공 council_votes -5")
	_expect(not bool(settled.castle_defeat), "인장 절도는 왕좌 패배 아님")
	var duplicate := ObjectiveScript.settle_seal_theft(settled.active_run, settled.battle_state, DataRegistry.update4_expansion_modules)
	_expect(int(duplicate.active_run.council_season.council_votes) == 7 and int(duplicate.active_run.expansion.seal_theft_count) == 1, "절도 손실 전투당 최대 1회")
	var seal_active := _active_run()
	seal_active = ExpansionScript.unlock_if_due(seal_active,16,DataRegistry.update4_expansion_modules,3)
	seal_active.council_season.council_votes = 2
	seal_active.council_season.council_seals = 2
	var seal_battle := ObjectiveScript.new_battle_objectives(seal_active, DataRegistry.update4_expansion_modules)
	seal_battle = ObjectiveScript.tick_seal_theft(ObjectiveScript.start_seal_theft(seal_battle, DataRegistry.update4_expansion_modules), 7.0)
	var seal_settled := ObjectiveScript.settle_seal_theft(seal_active, seal_battle, DataRegistry.update4_expansion_modules)
	_expect(int(seal_settled.active_run.council_season.council_votes) == 2 and int(seal_settled.active_run.council_season.council_seals) == 1, "표 부족 시 seal charge 1 감소")
	var interrupted := ObjectiveScript.interrupt_seal_theft(ObjectiveScript.start_seal_theft(battle, DataRegistry.update4_expansion_modules))
	_expect(not bool(interrupted.seal_theft.active) and not bool(interrupted.seal_theft.ready_to_settle), "절도 채널 중단 시 무손실")


func _test_facility_scope() -> void:
	var active := ExpansionScript.unlock_if_due(_active_run(),16,DataRegistry.update4_expansion_modules,3)
	var allowed := ObjectiveScript.install_facility(active, "recovery", DataRegistry.update4_expansion_modules)
	var forbidden := ObjectiveScript.install_facility(active, "treasure", DataRegistry.update4_expansion_modules)
	_expect(bool(allowed.ok) and str(allowed.active_run.expansion.facility_role) == "recovery", "상층 병영·감시·회복 시설 설치 허용")
	_expect(not bool(forbidden.ok), "보물 보관실·왕좌·심장방 상층 이동 금지")
	_expect(not ObjectiveScript.new().has_method("same_floor_targets"),"no artificial upper-only facility filter")


func _active_run() -> Dictionary:
	return {
		"campaign_mode_id": "council_season",
		"council_season": {"council_votes": 0, "council_seals": 0},
		"expansion": ExpansionScript.default_state()
	}


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[UpperFloorObjectivesPhase11] FAIL: %s" % label)
