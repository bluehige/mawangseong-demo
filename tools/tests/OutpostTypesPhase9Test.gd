extends Node

const OutpostServiceScript = preload("res://scripts/systems/outpost/OutpostService.gd")
const EncounterServiceScript = preload("res://scripts/systems/outpost/OutpostEncounterService.gd")
const OutpostScreenScene = preload("res://scenes/ui/screens/OutpostManagementScreen.tscn")
const BattleScene = preload("res://scenes/outpost/OutpostBattleRoot.tscn")
const GameRootScript = preload("res://scripts/game/GameRoot.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_type_passives()
	_test_battle_differences()
	_test_statistics_and_e20_metrics()
	await _test_ui_contract()
	if failed:
		print("OUTPOST_TYPES_PHASE9_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("OUTPOST_TYPES_PHASE9_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_type_passives() -> void:
	_expect(GameRootScript != null, "GameRoot 전초기지 보상·패시브 연동 parse")
	var supply := _outpost("outpost_supply_burrow", 1)
	var activated := OutpostServiceScript.activate_income_passive({"outpost": supply}, 32, 6, DataRegistry.update4_outpost_types)
	_expect(int(activated.gold_income) == 36 and int(activated.food_income) == 7, "보급 굴 일일 금화·식량 +12% 반올림")
	var repeated := OutpostServiceScript.activate_income_passive(activated.active_run, int(activated.gold_income), int(activated.food_income), DataRegistry.update4_outpost_types)
	_expect(int(repeated.gold_income) == 36 and int(repeated.food_income) == 7, "보급 굴 패시브 중복 적용 방지")
	var watch_run := {"outpost": _outpost("outpost_watch_nest", 1)}
	var watch_modifiers := OutpostServiceScript.campaign_modifiers(watch_run, DataRegistry.update4_outpost_types)
	_expect(int(watch_modifiers.wave_variant_preview_count) == 2 and not bool(watch_modifiers.upper_entry_preview), "감시 둥지 다음 본성 변형 2개 공개")
	var preview := OutpostServiceScript.preview_next_home_wave(watch_run, DataRegistry.waves, 4)
	_expect(preview.size() == 2 and int(preview[0].day) == 5, "감시 둥지 다음 본성 웨이브 2개 실제 예고")
	watch_run.outpost.level = 2
	_expect(bool(OutpostServiceScript.campaign_modifiers(watch_run, DataRegistry.update4_outpost_types).upper_entry_preview), "감시 둥지 Lv.2 상층 진입 위치 공개")
	var false_run := {"outpost": _outpost("outpost_false_gate", 2)}
	var false_modifiers := OutpostServiceScript.campaign_modifiers(false_run, DataRegistry.update4_outpost_types)
	_expect(is_equal_approx(float(false_modifiers.home_first_wave_threat_multiplier), 0.92) and int(false_modifiers.final_vanguard_delay_count) == 1, "가짜 성문 본성 첫 웨이브 -8%·DAY 30 선발대 지연")
	var home_modifier := OutpostServiceScript.home_defense_modifier(false_run, 5, DataRegistry.update4_outpost_types)
	var wave_manager = WaveManagerScript.new()
	wave_manager.setup(5, DataRegistry.waves, {"outpost_false_gate": home_modifier})
	var first_source: Dictionary = DataRegistry.waves.day_5[0]
	_expect(is_equal_approx(float(wave_manager.schedule[0].hp_scale), float(first_source.hp_scale) * 0.92) and is_equal_approx(float(wave_manager.schedule[0].atk_scale), float(first_source.atk_scale) * 0.92), "가짜 성문 첫 본성 웨이브 HP·공격 위협 -8% 실제 적용")
	var consumed := OutpostServiceScript.consume_home_defense_modifier(false_run, 5)
	_expect(bool(consumed.outpost.home_threat_reduction_used) and OutpostServiceScript.home_defense_modifier(consumed, 5, DataRegistry.update4_outpost_types).is_empty(), "가짜 성문 다음 본성 1회 적용 후 소비")
	var supply_run := {"outpost": _outpost("outpost_supply_burrow", 2)}
	_expect(bool(OutpostServiceScript.campaign_modifiers(supply_run, DataRegistry.update4_outpost_types).clear_assigned_fatigue_after_battle), "보급 굴 Lv.2 파견 몬스터 피로 제거 계약")


func _test_battle_differences() -> void:
	var encounter: Dictionary = DataRegistry.update4_outpost_encounters.outpost_fixed_four_modules
	var watch_definition: Dictionary = DataRegistry.update4_outpost_types.outpost_watch_nest
	var watch_state := EncounterServiceScript.new_battle_state(_outpost("outpost_watch_nest", 1), encounter, 10, 0, watch_definition)
	watch_state = EncounterServiceScript.step(watch_state, 0.1)
	_expect(is_equal_approx(float(watch_state.enemies[0].travel_seconds), 14.0), "감시 둥지 첫 적 진입 +2초")
	var supply_definition: Dictionary = DataRegistry.update4_outpost_types.outpost_supply_burrow
	var supply_outpost := _outpost("outpost_supply_burrow", 1)
	supply_outpost.assigned_monster_ids = []
	var supply_state := EncounterServiceScript.new_battle_state(supply_outpost, encounter, 10, 0, supply_definition)
	while float(supply_state.elapsed) < 30.0 and not bool(supply_state.completed):
		supply_state = EncounterServiceScript.step(supply_state, 0.1)
	_expect(bool(supply_state.supply_chest_used) and int(supply_state.supply_chest_healing) > 0, "보급 굴 중앙 회복 상자 1회 발동")
	var false_definition: Dictionary = DataRegistry.update4_outpost_types.outpost_false_gate
	var false_state := EncounterServiceScript.new_battle_state(_outpost("outpost_false_gate", 1), encounter, 10, 0, false_definition)
	_expect(false_state.wave.size() == encounter.placeholder_wave.size() + 1, "가짜 성문 깃발 목표 적 +1 위험")
	while float(false_state.elapsed) < 20.0 and not bool(false_state.completed):
		false_state = EncounterServiceScript.step(false_state, 0.1)
	_expect(int(false_state.detoured_count) >= 1, "가짜 성문 적 일부 우회")
	var day10 := EncounterServiceScript.new_battle_state(_outpost("outpost_watch_nest", 2), encounter, 10, 0, watch_definition)
	var day20 := EncounterServiceScript.new_battle_state(_outpost("outpost_watch_nest", 2), encounter, 20, 0, watch_definition)
	_expect(day10.wave.size() == 8 and day20.wave.size() == 9, "DAY 20 두 번째 강화 웨이브")
	var watch_result := EncounterServiceScript.run_placeholder_trial(_outpost("outpost_watch_nest", 2), encounter, 10, 0, watch_definition)
	var supply_result := EncounterServiceScript.run_placeholder_trial(_outpost("outpost_supply_burrow", 2), encounter, 10, 0, supply_definition)
	_expect(bool(watch_result.win) and bool(supply_result.win), "세 명 배치 기준 감시·보급 DAY 10 승리")
	_expect(int(watch_result.reward.gold) < int(supply_result.reward.gold) and int(watch_result.reward.food) < int(supply_result.reward.food), "감시 저보상·보급 고보상 A/B")


func _test_statistics_and_e20_metrics() -> void:
	var active := {"outpost": _outpost("outpost_supply_burrow", 2), "run_metrics_update4": {}, "council_season": {"rival_support_id": "rival_mirella"}}
	var profile := {"outpost": {"types_seen": ["outpost_supply_burrow"], "perfect_defenses": 0}}
	var day10 := {"day": 10, "win": true, "duration_seconds": 55.0, "ending_hp": 350, "max_hp": 500, "retry_count": 0, "type_id": "outpost_supply_burrow", "reward": {"gold": 30, "food": 12}}
	var first := EncounterServiceScript.settle_result(active, day10, profile)
	_expect(bool(first.ok) and int(first.active_run.outpost.stats.battles) == 1 and bool(first.active_run.outpost.stats.day10_win), "DAY 10 승리 통계 기록")
	var day20 := {"day": 20, "win": true, "duration_seconds": 55.0, "ending_hp": 300, "max_hp": 500, "retry_count": 0, "type_id": "outpost_supply_burrow", "reward": {"gold": 45, "food": 18}}
	var second := EncounterServiceScript.settle_result(first.active_run, day20, first.profile)
	var metrics: Dictionary = second.active_run.run_metrics_update4.outpost
	_expect(bool(second.ok) and int(metrics.battles) == 2 and int(metrics.wins) == 2 and bool(metrics.both_battles_won), "DAY 10·20 전초기지 2승 통계")
	_expect(is_equal_approx(float(metrics.banner_hp_average_ratio), 0.65), "E20 평균 깃발 HP 지표")
	_expect(bool(metrics.perfect_defense) and int(second.profile.outpost.perfect_defenses) == 1, "Lv.2·2승·평균 50% 완벽 방어 프로필 기록")
	_expect(second.active_run.outpost.battle_results[1].fatigue_cleared_monster_ids.size() == 3, "보급 굴 Lv.2 전투 후 3명 피로 제거 기록")
	var loss_active := {"outpost": _outpost("outpost_false_gate", 2), "run_metrics_update4": {}, "council_season": {"rival_support_id": "rival_brassa"}}
	var loss := EncounterServiceScript.settle_result(loss_active, {"day": 20, "win": false, "ending_hp": 0, "max_hp": 550}, profile)
	_expect(bool(loss.active_run.outpost.support_token_lost) and str(loss.active_run.council_season.rival_support_id) == "", "DAY 20 패배 최종 지원 손실·DAY 30 진입 보존")
	_expect(not bool(loss.active_run.run_metrics_update4.outpost.perfect_defense), "DAY 20 패배 E20 완벽 방어 제외")


func _test_ui_contract() -> void:
	var screen = OutpostScreenScene.instantiate()
	add_child(screen)
	screen.setup({"outpost": _outpost("outpost_watch_nest", 2)}, DataRegistry.update4_outpost_types, [], DataRegistry.monster_instances, 20)
	await get_tree().process_frame
	_expect(_has_label(screen, "엔딩 지표") and _has_label(screen, "방어 통계"), "전초기지 관리 화면 효과·통계 안내")
	screen.queue_free()
	var battle = BattleScene.instantiate()
	add_child(battle)
	battle.setup(_outpost("outpost_false_gate", 2), DataRegistry.update4_outpost_encounters.outpost_fixed_four_modules, DataRegistry.update4_outpost_types.outpost_false_gate, [], 20)
	await get_tree().process_frame
	_expect(_has_label(battle, "적 일부가 가짜 왕좌로 우회"), "방어전 화면 유형별 실제 효과 표시")
	battle.queue_free()


func _outpost(type_id: String, level: int) -> Dictionary:
	var definition: Dictionary = DataRegistry.update4_outpost_types.get(type_id, {})
	var max_hp := int(definition.get("level_2_hp" if level >= 2 else "base_hp", 400))
	return {
		"type_id": type_id, "level": level, "current_hp": max_hp, "max_hp": max_hp,
		"assigned_monster_ids": ["slime_basic_01", "goblin_basic_01", "bat_basic_01"],
		"battle_results": [], "damaged": false, "recovery_used": false,
		"upgrade_cost_multiplier": 1.0, "support_token_lost": false,
		"passive_applied": false, "passive_income_bonus": {"gold": 0, "food": 0},
		"home_threat_reduction_used": false, "final_vanguard_delay_used": false,
		"stats": OutpostServiceScript.default_stats()
	}


func _has_label(root: Node, fragment: String) -> bool:
	if root is Label and fragment in root.text:
		return true
	for child in root.get_children():
		if _has_label(child, fragment):
			return true
	return false


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[OutpostTypesPhase9] FAIL: %s" % label)
