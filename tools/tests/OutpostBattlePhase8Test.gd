extends Node

const EncounterServiceScript = preload("res://scripts/systems/outpost/OutpostEncounterService.gd")
const BattleScene = preload("res://scenes/outpost/OutpostBattleRoot.tscn")
const SaveMigratorScript = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_simulation_contract()
	_test_settlement_and_recovery()
	await _test_scene_contract()
	if failed:
		print("OUTPOST_BATTLE_PHASE8_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("OUTPOST_BATTLE_PHASE8_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_simulation_contract() -> void:
	var encounter: Dictionary = DataRegistry.update4_outpost_encounters.get("outpost_fixed_four_modules", {})
	_expect(GameRootScript != null, "GameRoot DAY 10 전초기지 장면 전환 parse")
	_expect(bool(encounter.get("runtime_enabled", false)) and encounter.get("module_ids", []).size() == 4, "고정 4모듈 실시간 전투 활성")
	_expect(encounter.get("placeholder_wave", []).size() == 8, "DAY 10 단일 placeholder 웨이브 8개 진입")
	var loss_outpost := _outpost(0)
	var win_outpost := _outpost(3)
	var defeat_before := GameState.defeat
	var victory_before := GameState.victory
	var loss := EncounterServiceScript.run_placeholder_trial(loss_outpost, encounter, 10)
	var win := EncounterServiceScript.run_placeholder_trial(win_outpost, encounter, 10)
	_expect(not bool(loss.get("win", true)) and int(loss.get("ending_hp", 1)) == 0, "무배치 fixture 깃발 패배")
	_expect(bool(win.get("win", false)) and int(win.get("ending_hp", 0)) > 0, "3명 배치 fixture 깃발 승리")
	_expect(float(loss.get("duration_seconds", 0.0)) >= 45.0 and float(loss.get("duration_seconds", 0.0)) <= 80.0 and float(win.get("duration_seconds", 0.0)) >= 45.0 and float(win.get("duration_seconds", 0.0)) <= 80.0, "승리·패배 45~80초 목표")
	var retry := EncounterServiceScript.run_placeholder_trial(win_outpost, encounter, 10, 1)
	_expect(bool(retry.get("win", false)) == bool(win.get("win", false)) and int(retry.get("retry_count", 0)) == 1, "재도전 동일 입력 재현·횟수 기록")
	_expect(GameState.defeat == defeat_before and GameState.victory == victory_before, "본성 승리·패배 플래그 무오염")


func _test_settlement_and_recovery() -> void:
	var encounter: Dictionary = DataRegistry.update4_outpost_encounters.get("outpost_fixed_four_modules", {})
	var active := SaveMigratorScript.fresh_update4_active_run(SaveMigratorScript.MODE_COUNCIL_SEASON, 2, 404, {})
	active["outpost"] = _outpost(0)
	var loss := EncounterServiceScript.run_placeholder_trial(active.get("outpost", {}), encounter, 10)
	var settled := EncounterServiceScript.settle_result(active, loss)
	_expect(bool(settled.get("ok", false)) and settled.get("active_run", {}).get("outpost", {}).get("battle_results", []).size() == 1, "DAY 10 패배 수용 시에만 결산 기록")
	active = settled.get("active_run", {})
	_expect(not bool(EncounterServiceScript.settle_result(active, loss).get("ok", true)), "같은 DAY 중복 결산 거부")
	var recovered := EncounterServiceScript.apply_day_start_recovery(active, 11)
	_expect(int(recovered.get("outpost", {}).get("current_hp", 0)) == 200 and bool(recovered.get("outpost", {}).get("recovery_used", false)), "DAY 11 무료 50% HP 자동 복구 1회")
	_expect(is_equal_approx(float(recovered.get("outpost", {}).get("upgrade_cost_multiplier", 0.0)), 1.25), "DAY 10 패배 후 Lv.2 강화 비용 +25% 계약")
	_expect(EncounterServiceScript.apply_day_start_recovery(recovered, 11) == recovered, "무료 복구 반복 적용 금지")

	var day20_active := SaveMigratorScript.fresh_update4_active_run(SaveMigratorScript.MODE_COUNCIL_SEASON, 2, 404, {})
	day20_active["outpost"] = _outpost(0)
	day20_active["council_season"]["rival_support_id"] = "rival_vesper"
	var day20_loss := EncounterServiceScript.run_placeholder_trial(day20_active.get("outpost", {}), encounter, 20)
	var day20_settled: Dictionary = EncounterServiceScript.settle_result(day20_active, day20_loss).get("active_run", {})
	_expect(bool(day20_settled.get("outpost", {}).get("support_token_lost", false)) and str(day20_settled.get("council_season", {}).get("rival_support_id", "x")) == "", "DAY 20 패배 시 지원 토큰 상실")


func _test_scene_contract() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var screen = BattleScene.instantiate()
	var defenders := ["푸딩", "곱", "핀"]
	screen.setup(_outpost(3), DataRegistry.update4_outpost_encounters.get("outpost_fixed_four_modules", {}), DataRegistry.update4_outpost_types.get("outpost_supply_burrow", {}), defenders, 10)
	host.add_child(screen)
	await get_tree().process_frame
	_expect(screen.get_node_or_null("DesignCanvas/OutpostGate") != null and screen.get_node_or_null("DesignCanvas/OutpostCenter") != null and screen.get_node_or_null("DesignCanvas/OutpostCache") != null and screen.get_node_or_null("DesignCanvas/OutpostRetreat") != null, "실제 장면 고정 4모듈 표시")
	_expect(screen.get_node_or_null("DesignCanvas/OutpostBanner") != null and screen.get_node_or_null("DesignCanvas/DefenderRoster/DefenderSlot3") != null, "깃발 HP·배치 3칸 HUD")
	if OS.get_environment("UPDATE4_CAPTURE_UI") == "1":
		await get_tree().process_frame
		await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		if image != null:
			var path := OS.get_user_data_dir().path_join("outpost_battle_phase8.png")
			image.save_png(path)
			print("OUTPOST_BATTLE_CAPTURE: %s" % path)
	screen.debug_complete(false)
	_expect(screen.get_node_or_null("DesignCanvas/BattleResultOverlay/RetryButton") != null and screen.get_node_or_null("DesignCanvas/BattleResultOverlay/SettleLossButton") != null, "패배 결과 재도전·패배 수용 분기")
	screen._retry()
	_expect(int(screen.battle_state.get("retry_count", 0)) == 1 and screen.get_node_or_null("DesignCanvas/BattleResultOverlay") == null, "재도전 시 미결산 새 전투 상태")
	host.queue_free()


func _outpost(defender_count: int) -> Dictionary:
	var instance_ids := DataRegistry.monster_instances.keys()
	instance_ids.sort()
	var assigned: Array[String] = []
	for index in mini(defender_count, instance_ids.size()):
		assigned.append(str(instance_ids[index]))
	return {
		"type_id": "outpost_supply_burrow", "level": 1,
		"current_hp": 400, "max_hp": 400,
		"assigned_monster_ids": assigned, "battle_results": [], "damaged": false,
		"recovery_used": false, "upgrade_cost_multiplier": 1.0, "support_token_lost": false
	}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[OutpostBattlePhase8] FAIL: %s" % message)
