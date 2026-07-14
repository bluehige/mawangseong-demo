extends Node

const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const HeartServiceScript = preload("res://scripts/systems/hearts/CastleHeartService.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")
const MainScene = preload("res://scenes/main/Main.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_unlock_routes()
	_test_day_overlays_and_roles()
	_test_events()
	_test_operations()
	await _test_game_root_and_regression()
	print("GUILD_REPOSSESSION_PHASE21_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _guild_run(heart_id: String = "heart_stonebone") -> Dictionary:
	var profile := FrontServiceScript.default_update3_profile()
	profile["rival_relations"]["roman"] = 45
	var selected := FrontServiceScript.select_front(profile, FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.GUILD_FRONT_ID, DataRegistry.update3_fronts)
	return HeartServiceScript.select_heart(selected.get("profile", {}), selected.get("active_run", {}), heart_id, DataRegistry.update3_castle_hearts).get("active_run", {}).duplicate(true)


func _hero_run() -> Dictionary:
	var selected := FrontServiceScript.select_front(FrontServiceScript.default_update3_profile(), FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HERO_FRONT_ID, DataRegistry.update3_fronts)
	return selected.get("active_run", {}).duplicate(true)


func _test_unlock_routes() -> void:
	var base := FrontServiceScript.default_update3_profile()
	_expect(not FrontServiceScript.reconcile_unlocks(base, DataRegistry.update3_fronts).get("fronts", {}).get("unlocked", []).has(FrontServiceScript.GUILD_FRONT_ID), "기본 프로필에서 길드 전선 잠김")
	var relation := base.duplicate(true)
	relation["rival_relations"]["roman"] = 45
	_expect(FrontServiceScript.reconcile_unlocks(relation, DataRegistry.update3_fronts).get("fronts", {}).get("unlocked", []).has(FrontServiceScript.GUILD_FRONT_ID), "로만 관계 45로 해금")
	for code in ["E05", "E08"]:
		var ending := base.duplicate(true)
		ending["ending_catalog_codes"] = {"fixture": code}
		_expect(FrontServiceScript.reconcile_unlocks(ending, DataRegistry.update3_fronts).get("fronts", {}).get("unlocked", []).has(FrontServiceScript.GUILD_FRONT_ID), "%s 확인으로 해금" % code)
	for doctrine_id in ["facility_assault", "treasure_pressure"]:
		var doctrine := base.duplicate(true)
		doctrine["doctrine_history"] = [{"cycle": 1, "doctrine_id": doctrine_id}]
		_expect(FrontServiceScript.reconcile_unlocks(doctrine, DataRegistry.update3_fronts).get("fronts", {}).get("unlocked", []).has(FrontServiceScript.GUILD_FRONT_ID), "%s 교리 격파로 해금" % doctrine_id)
	var invitation := FrontServiceScript.apply_invitation(base, FrontServiceScript.GUILD_FRONT_ID, DataRegistry.update3_fronts)
	_expect(bool(invitation.get("ok", false)) and invitation.get("profile", {}).get("fronts", {}).get("unlocked", []).has(FrontServiceScript.GUILD_FRONT_ID), "첫 진입 길드 소환장 선택")


func _test_day_overlays_and_roles() -> void:
	var run := _guild_run()
	for day in [1, 2, 3]:
		_expect(FrontServiceScript.overlay_day_entry(run, day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays).is_empty(), "DAY %d 공통 내용 유지" % day)
	_expect(not FrontServiceScript.overlay_day_entry(run, 5, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays).has("wave_modifier"), "DAY 05는 등록 비용 이야기만 표시")
	var totals := {10: 6, 15: 6, 20: 7, 25: 6}
	for day in totals:
		var schedule := _schedule_for(run, day)
		_expect(schedule.size() == int(totals[day]), "DAY %02d 기존 인원 예산 %d명 유지" % [day, int(totals[day])])
	var day10 := _schedule_for(run, 10)
	_expect(_count(day10, "bounty_tracker") == 1 and _count(day10, "thief") == 2 and _count(day10, "ledger_binder") == 0, "DAY 10 고기여 표적·보물 압박, 장부 압박 없음")
	var day15 := _schedule_for(run, 15)
	_expect(_count(day15, "combat_alchemist") == 1 and _count(day15, "engineer") == 2 and _count(day15, "thief") == 0, "DAY 15 연금술사·공병 시설 시험, 보물 압박 없음")
	var day20 := _schedule_for(run, 20)
	_expect(_count(day20, "roman") == 1 and _count(day20, "ledger_binder") == 1 and _count(day20, "thief") == 0 and _count(day20, "bounty_tracker") == 0, "DAY 20 로만·장부·심장 압박만 분리")
	var day25 := _schedule_for(run, 25)
	_expect(_count(day25, "roman") == 1 and _count(day25, "bounty_tracker") == 1 and _count(day25, "ledger_binder") == 0, "DAY 25 강화 로만·현상금 추적자")


func _test_events() -> void:
	var profile := FrontServiceScript.default_update3_profile()
	profile["rival_relations"]["roman"] = 45
	var run := _guild_run("heart_hungry_maw")
	var day15 := FrontServiceScript.overlay_day_entry(run, 15, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	var heart_event := FrontServiceScript.selected_heart_event(run, day15, DataRegistry.update3_events)
	_expect(str(heart_event.get("heart_id", "")) == "heart_hungry_maw" and str(heart_event.get("kind", "")) == "heart_event", "길드 전선에서도 선택한 심장 사건 1개 연결")
	var hearing := FrontServiceScript.apply_event_choice(profile, run, "event_roman_asset_hearing", "claim_independent_castle", 15, DataRegistry.update3_events)
	_expect(bool(hearing.get("ok", false)) and int(hearing.get("profile", {}).get("rival_relations", {}).get("roman", 0)) == 51, "소유권 청문이 로만 관계 +6 반영")
	_expect(int(hearing.get("active_run", {}).get("run_metrics_update3", {}).get("e13_independent_claim", 0)) == 1, "소유권 청문 E13 지표 기록")
	var reward := FrontServiceScript.apply_event_choice(hearing.get("profile", {}), hearing.get("active_run", {}), "event_guild_reward_split", "pay_mercenaries", 20, DataRegistry.update3_events)
	_expect(bool(reward.get("ok", false)) and int(reward.get("profile", {}).get("rival_relations", {}).get("roman", 0)) == 58 and int(reward.get("effects", {}).get("gold", 0)) == -80, "용병 보수 지급이 관계·금화 효과 반영")


func _test_operations() -> void:
	var run := _guild_run()
	var available: Array[String] = FrontServiceScript.operation_choices(run, 28, DataRegistry.update3_front_operations)
	_expect(available.size() == 2 and available.has("d28_guild_ledger_forgery") and available.has("d28_guild_payroll_cut"), "DAY 28 길드 작전 2개만 제공")
	_expect(not DataRegistry.raid_mission("d28_guild_ledger_forgery").is_empty() and not DataRegistry.raid_mission("d28_guild_payroll_cut").is_empty(), "길드 작전이 실제 원정 선택 흐름에 등록")
	var forgery: Dictionary = DataRegistry.update3_front_operations["d28_guild_ledger_forgery"]
	_expect(int(forgery.get("reward", {}).get("gold", -1)) == 0 and int(forgery.get("defense_modifier", {}).get("count_delta_by_enemy", {}).get("ledger_binder", 0)) == -1 and int(forgery.get("defense_modifier", {}).get("roman_start_budget_delta", 0)) == -1, "작전 A 장부술사 -1·로만 예산 -1·금화 보상 0")
	var payroll: Dictionary = DataRegistry.update3_front_operations["d28_guild_payroll_cut"]
	_expect(int(payroll.get("defense_modifier", {}).get("roman_mercenary_call_max", 0)) == 1 and int(payroll.get("defense_modifier", {}).get("morale_bonus_by_enemy", {}).get("ledger_binder", 0)) == -10, "작전 B 용병 상한 1·길드 일반 적 사기 -10")
	var selected := FrontServiceScript.select_operation(run, "d28_guild_payroll_cut", 28, DataRegistry.update3_front_operations)
	_expect(bool(selected.get("ok", false)) and str(selected.get("active_run", {}).get("day28_front_operation", "")) == "d28_guild_payroll_cut", "길드 작전 선택 회차 저장")
	var modifier: Dictionary = FrontServiceScript.selected_operation_modifier(selected.get("active_run", {}), 30, DataRegistry.update3_front_operations)
	var manager = WaveManagerScript.new()
	manager.setup(30, DataRegistry.waves, {"operation": modifier})
	var tracker_entry := _first_entry(manager.schedule, "bounty_tracker")
	_expect(_count(manager.schedule, "bounty_tracker") == 1 and int(tracker_entry.get("morale_bonus", 0)) == -10, "작전 B DAY30 추적자 +1·사기 -10을 실제 웨이브에 적용")


func _test_game_root_and_regression() -> void:
	for day in [10, 15, 20, 25]:
		_expect(FrontServiceScript.day_defense_modifier(_hero_run(), day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays).is_empty(), "레온 전선 DAY %02d 길드 웨이브 유출 없음" % day)
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.update3_active_run = _guild_run()
	GameState.day = 28
	_expect(game._campaign_required_raid_choice_group() == "day28_guild_repossession", "GameRoot DAY28 원정을 길드 전용 작전 그룹으로 교체")
	game.completed_raids["d28_guild_payroll_cut"] = true
	game.update3_active_run = FrontServiceScript.select_operation(game.update3_active_run, "d28_guild_payroll_cut", 28, DataRegistry.update3_front_operations).get("active_run", game.update3_active_run)
	game.next_defense_modifiers.clear()
	GameState.day = 30
	_expect(game._restore_final_expedition_modifier_for_retry() and game.next_defense_modifiers.has("guild_payroll_cut_day30"), "DAY30 재도전에서 같은 길드 작전 효과 복원")
	var eve := FrontServiceScript.overlay_day_entry(game.update3_active_run, 29, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	var eve_event: Dictionary = DataRegistry.update3_events.get(str(eve.get("eve_id", "")), {})
	_expect(str(eve_event.get("kind", "")) == "finale_eve" and not eve_event.has("placeholder") and eve_event.get("required_context", []).has("relation_roman") and eve_event.get("dialogue_templates", []).size() == 10, "DAY29 로만 결전 전야 완성 대사·관계 문맥")
	var day30 := FrontServiceScript.overlay_day_entry(game.update3_active_run, 30, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	_expect(not day30.has("placeholder") and str(day30.get("boss_enemy_id", "")) == "guild_commissioner_roman", "Phase22 길드 총감사관 로만 최종 보스로 교체")
	host.queue_free()
	await get_tree().process_frame


func _schedule_for(run: Dictionary, day: int) -> Array:
	var manager = WaveManagerScript.new()
	manager.setup(day, DataRegistry.waves, {"guild": FrontServiceScript.day_defense_modifier(run, day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)})
	return manager.schedule


func _count(schedule: Array, enemy_id: String) -> int:
	var result := 0
	for entry in schedule:
		if str(entry.get("enemy_id", "")) == enemy_id:
			result += 1
	return result


func _first_entry(schedule: Array, enemy_id: String) -> Dictionary:
	for entry_value in schedule:
		if str(entry_value.get("enemy_id", "")) == enemy_id:
			return entry_value
	return {}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[GuildRepossessionPhase21] FAIL: %s" % message)
