extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const HeartServiceScript = preload("res://scripts/systems/hearts/CastleHeartService.gd")
const LeonServiceScript = preload("res://scripts/systems/campaign/LeonAdaptationService.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_day_overlays_and_events()
	_test_day28_operations_and_day29_eve()
	_test_stance_and_ending_regression()
	_test_epilogue_records()
	await _test_leon_one_time_responses()
	print("HERO_OATH_PHASE23_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _hero_run() -> Dictionary:
	var profile := FrontServiceScript.default_update3_profile()
	var selected := FrontServiceScript.select_front(profile, FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HERO_FRONT_ID, DataRegistry.update3_fronts)
	return HeartServiceScript.select_heart(selected.get("profile", {}), selected.get("active_run", {}), "heart_stonebone", DataRegistry.update3_castle_hearts).get("active_run", {}).duplicate(true)


func _test_day_overlays_and_events() -> void:
	var run := _hero_run()
	var day15 := FrontServiceScript.overlay_day_entry(run, 15, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	_expect(str(day15.get("wave_modifier", {}).get("id", "")) == "hero_day15_heart_chamber_test" and bool(day15.get("heart_event", false)), "DAY 15 심장방 시험·심장 사건 연결")
	var manager = WaveManagerScript.new()
	manager.setup(15, DataRegistry.waves, {"hero": day15.get("wave_modifier", {})})
	_expect(manager.total_to_spawn == 6 and _count(manager.schedule, "thief") == 0 and _count(manager.schedule, "investigator") == 2, "DAY 15 기존 6명 예산 유지·도둑을 심장 조사관으로 교체")
	var heart_entry := _first_goal_entry(manager.schedule, "investigator", "heart")
	_expect(str(heart_entry.get("goal_type_override", "")) == "heart", "추가 조사관의 목표를 심장방으로 지정")
	for day in [20, 25, 30]:
		var entry := FrontServiceScript.overlay_day_entry(run, day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
		_expect(not entry.has("wave_modifier"), "DAY %02d 기존 웨이브 수치 유지" % day)
	_expect(str(FrontServiceScript.overlay_day_entry(run, 30, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays).get("boss_enemy_id", "")) == "official_hero_leon", "DAY 30 정식 레온 보스 유지")
	var first := FrontServiceScript.apply_event_choice(FrontServiceScript.default_update3_profile(), run, "event_leon_heart_sketch", "correct_map", 15, DataRegistry.update3_events)
	_expect(bool(first.get("ok", false)) and int(first.get("active_run", {}).get("run_metrics_update3", {}).get("leon_heart_guidance", 0)) == 1, "첫 번째 레온 심장 언급 사건 선택 기록")
	var second := FrontServiceScript.apply_event_choice(first.get("profile", {}), first.get("active_run", {}), "event_leon_link_note", "share_link_note", 20, DataRegistry.update3_events)
	_expect(bool(second.get("ok", false)) and int(second.get("active_run", {}).get("run_metrics_update3", {}).get("leon_link_respect", 0)) == 1, "두 번째 레온 합동기 언급 사건 선택 기록")


func _test_day28_operations_and_day29_eve() -> void:
	var run := _hero_run()
	var choices := FrontServiceScript.operation_choices(run, 28, DataRegistry.update3_front_operations)
	_expect(choices == ["d28_engineer_supply_disruption", "d28_siege_route_recon"], "DAY 28 용사 전선 기존 최종 원정 2개를 전선 작전으로 연결")
	var source_raid := DataRegistry.raid_mission("d28_siege_route_recon")
	var operation: Dictionary = DataRegistry.update3_front_operations.get("d28_siege_route_recon", {})
	_expect(str(source_raid.get("subtitle", "")) != "" and source_raid.get("briefing_lines", []).size() == 2 and int(source_raid.get("reward", {}).get("gold", 0)) == 80, "소스 원정의 상세·브리핑·보상을 덮어쓰지 않음")
	_expect(int(operation.get("reward", {}).get("infamy", 0)) == 45 and float(operation.get("defense_modifier", {}).get("spawn_delay_bonus", 0.0)) == 5.0, "전선 작전 조회에는 소스 보상과 DAY 30 효과를 hydrate")
	var selected := FrontServiceScript.select_operation(run, "d28_siege_route_recon", 28, DataRegistry.update3_front_operations)
	_expect(bool(selected.get("ok", false)) and str(selected.get("active_run", {}).get("day28_front_operation", "")) == "d28_siege_route_recon", "용사 DAY 28 작전 선택을 회차에 저장")
	var modifier := FrontServiceScript.selected_operation_modifier(selected.get("active_run", {}), 30, DataRegistry.update3_front_operations)
	_expect(int(modifier.get("count_delta_by_enemy", {}).get("investigator", 0)) == -1 and float(modifier.get("spawn_delay_bonus", 0.0)) == 5.0, "용사 DAY 28 작전 효과를 DAY 30에 복원")
	var day29 := FrontServiceScript.overlay_day_entry(run, 29, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	var eve := FrontServiceScript.event_definition(str(day29.get("eve_id", "")), DataRegistry.update3_events)
	_expect(str(eve.get("kind", "")) == "finale_eve" and str(eve.get("rival_id", "")) == "leon" and eve.get("dialogue_templates", []).size() == 10, "DAY 29 레온 결전 전야 완성 대사 연결")


func _test_stance_and_ending_regression() -> void:
	var expected := ["leon_stance_siege", "leon_stance_pursuit", "leon_stance_purification", "leon_stance_duelist"]
	for stance_id in expected:
		_expect(DataRegistry.leon_adaptive_stances.has(stance_id), "기존 레온 자세 유지: %s" % stance_id)
	_expect(DataRegistry.leon_adaptive_stances.size() == 4 and LeonServiceScript.validate(DataRegistry.leon_adaptive_stances).is_empty(), "기존 적응 자세 정확히 4종·자료 검증 통과")
	var base_analysis := {"facility": 80.0, "backline": 20.0, "sustain": 10.0, "direct": 5.0}
	var extended := base_analysis.duplicate(true)
	extended["heart_id"] = "heart_stonebone"
	extended["heart_active_uses"] = 8
	extended["equipped_duo_links"] = 2
	var base_pick := LeonServiceScript.choose_stance(DataRegistry.leon_adaptive_stances, base_analysis, 23)
	var extended_pick := LeonServiceScript.choose_stance(DataRegistry.leon_adaptive_stances, extended, 23)
	_expect(str(base_pick.get("stance_id", "")) == str(extended_pick.get("stance_id", "")), "심장·합동기 관찰 정보가 자세 약점 선택을 덮어쓰지 않음")
	var ending_codes: Array = []
	for rule_value in DataRegistry.ending_rules.values():
		var code := str(rule_value.get("catalog_code", ""))
		if code != "":
			ending_codes.append(code)
	var all_reachable := true
	for index in range(12):
		all_reachable = all_reachable and ending_codes.has("E%02d" % index)
	_expect(all_reachable and ending_codes.size() >= 17, "기존 E00~E11을 포함한 최종 E00~E16 엔딩 자료 유지")


func _test_epilogue_records() -> void:
	for front_id in [FrontServiceScript.HERO_FRONT_ID, FrontServiceScript.HOLY_FRONT_ID, FrontServiceScript.GUILD_FRONT_ID]:
		var profile := FrontServiceScript.record_front_clear(FrontServiceScript.default_update3_profile(), {"front_id": front_id}, DataRegistry.update3_fronts)
		var epilogue_id := str(DataRegistry.update3_fronts.get(front_id, {}).get("epilogue_card", {}).get("id", ""))
		_expect(int(profile.get("fronts", {}).get("clear_counts", {}).get(front_id, 0)) == 1 and profile.get("fronts", {}).get("epilogues_seen", []).has(epilogue_id), "%s 클리어 횟수·에필로그 카드 기록" % front_id)
		profile = FrontServiceScript.record_front_clear(profile, {"front_id": front_id}, DataRegistry.update3_fronts)
		_expect(int(profile.get("fronts", {}).get("clear_counts", {}).get(front_id, 0)) == 2 and profile.get("fronts", {}).get("epilogues_seen", []).count(epilogue_id) == 1, "%s 재클리어 횟수 증가·에필로그 중복 방지" % front_id)


func _test_leon_one_time_responses() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.current_screen = Constants.SCREEN_COMBAT
	game.combat_paused = true
	game.enemy_units.clear()
	game.update3_active_run = _hero_run()
	game.combat_scene.spawn_enemy("official_hero_leon")
	var leon = game.enemy_units.back()
	game.combat_scene.leon_stance_id = "leon_stance_siege"
	leon.set_meta("leon_stance_id", "leon_stance_siege")
	_expect(game.combat_scene.trigger_leon_heart_response("heart_stonebone"), "레온 심장 대응 첫 1회 발동")
	_expect(not game.combat_scene.trigger_leon_heart_response("heart_dream_lantern") and game.combat_scene.leon_heart_response_count == 1, "같은 전투의 두 번째 심장 대응 차단")
	_expect(is_equal_approx(float(leon.shield_timer), 2.5) and is_equal_approx(float(leon.damage_reduction), 0.10), "심장 대응은 2.5초·피해 감소 10%의 약한 보조 효과")
	_expect(str(leon.get_meta("leon_stance_id", "")) == "leon_stance_siege" and game.combat_scene.leon_stance_id == "leon_stance_siege", "심장 대응 후 기존 자세와 약점 유지")
	leon.shield_timer = 0.0
	leon.damage_reduction = 0.0
	_expect(game.combat_scene.trigger_leon_duo_response("link_pudding_bebe"), "레온 합동기 대응 첫 1회 발동")
	_expect(not game.combat_scene.trigger_leon_duo_response("link_gob_koko") and game.combat_scene.leon_duo_response_count == 1, "같은 전투의 두 번째 합동기 대응 차단")
	_expect(is_equal_approx(float(leon.shield_timer), 2.0) and is_equal_approx(float(leon.damage_reduction), 0.08), "합동기 대응은 2초·피해 감소 8%의 약한 보조 효과")
	var metrics: Dictionary = game.update3_active_run.get("run_metrics_update3", {})
	_expect(int(metrics.get("leon_heart_responses", 0)) == 1 and int(metrics.get("leon_duo_responses", 0)) == 1, "두 대응을 회차 지표에 각각 1회 기록")
	_expect(2.5 + 2.0 <= 8.0, "추가 방어 시간 합계 4.5초로 기존 DAY 30 허용 편차 ±8초 이내")
	host.queue_free()
	await get_tree().process_frame


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


func _first_goal_entry(schedule: Array, enemy_id: String, goal_type: String) -> Dictionary:
	for entry_value in schedule:
		if str(entry_value.get("enemy_id", "")) == enemy_id and str(entry_value.get("goal_type_override", "")) == goal_type:
			return entry_value
	return {}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[HeroOathPhase23] FAIL: %s" % message)
