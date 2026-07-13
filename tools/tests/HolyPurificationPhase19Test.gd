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
	print("PHASE19_STAGE: load")
	DataRegistry.load_all()
	print("PHASE19_STAGE: unlock")
	_test_unlock_routes()
	print("PHASE19_STAGE: overlay")
	_test_day_overlay_and_wave_budgets()
	print("PHASE19_STAGE: events")
	_test_events_and_selected_heart_connection()
	print("PHASE19_STAGE: operations")
	_test_day28_operations_and_day29_eve()
	print("PHASE19_STAGE: regression")
	_test_leon_regression_and_selen_placeholder()
	print("PHASE19_STAGE: game_root")
	await _test_game_root_integration()
	if failed:
		print("HOLY_PURIFICATION_PHASE19_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("HOLY_PURIFICATION_PHASE19_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _holy_run(heart_id: String = "heart_stonebone") -> Dictionary:
	var profile := FrontServiceScript.default_update3_profile()
	profile["rival_relations"]["selen"] = 45
	var selected := FrontServiceScript.select_front(profile, FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HOLY_FRONT_ID, DataRegistry.update3_fronts)
	var heart_selected := HeartServiceScript.select_heart(selected.get("profile", {}), selected.get("active_run", {}), heart_id, DataRegistry.update3_castle_hearts)
	return heart_selected.get("active_run", {}).duplicate(true)


func _hero_run() -> Dictionary:
	var selected := FrontServiceScript.select_front(FrontServiceScript.default_update3_profile(), FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HERO_FRONT_ID, DataRegistry.update3_fronts)
	return HeartServiceScript.select_heart(selected.get("profile", {}), selected.get("active_run", {}), "heart_stonebone", DataRegistry.update3_castle_hearts).get("active_run", {}).duplicate(true)


func _test_unlock_routes() -> void:
	var base := FrontServiceScript.default_update3_profile()
	_expect(not FrontServiceScript.reconcile_unlocks(base, DataRegistry.update3_fronts).get("fronts", {}).get("unlocked", []).has(FrontServiceScript.HOLY_FRONT_ID), "기본은 레온 전선만 해금")
	var relation := base.duplicate(true)
	relation["rival_relations"]["selen"] = 45
	_expect(FrontServiceScript.reconcile_unlocks(relation, DataRegistry.update3_fronts).get("fronts", {}).get("unlocked", []).has(FrontServiceScript.HOLY_FRONT_ID), "셀렌 관계 45로 성광 전선 해금")
	var ending := base.duplicate(true)
	ending["ending_catalog_codes"] = {"ending_fixture": "E04"}
	_expect(FrontServiceScript.reconcile_unlocks(ending, DataRegistry.update3_fronts).get("fronts", {}).get("unlocked", []).has(FrontServiceScript.HOLY_FRONT_ID), "E04 확인으로 성광 전선 해금")
	var doctrine := base.duplicate(true)
	doctrine["doctrine_history"] = [{"cycle": 1, "doctrine_id": "purification_crusade"}]
	_expect(FrontServiceScript.reconcile_unlocks(doctrine, DataRegistry.update3_fronts).get("fronts", {}).get("unlocked", []).has(FrontServiceScript.HOLY_FRONT_ID), "정화 성전 교리 격파로 성광 전선 해금")
	var invitation := FrontServiceScript.apply_invitation(base, FrontServiceScript.HOLY_FRONT_ID, DataRegistry.update3_fronts)
	_expect(bool(invitation.get("ok", false)) and invitation.get("profile", {}).get("fronts", {}).get("unlocked", []).has(FrontServiceScript.HOLY_FRONT_ID), "3차 첫 진입 성광 초대장 선택")
	var cleared: Dictionary = invitation.get("profile", {}).duplicate(true)
	cleared["fronts"]["clear_counts"][FrontServiceScript.HOLY_FRONT_ID] = 1
	_expect(FrontServiceScript.reconcile_unlocks(cleared, DataRegistry.update3_fronts).get("fronts", {}).get("unlocked", []).has(FrontServiceScript.GUILD_FRONT_ID), "선택한 대체 전선 1회 클리어 후 나머지 전선 자동 해금")


func _test_day_overlay_and_wave_budgets() -> void:
	var run := _holy_run()
	for day in [1, 2, 3]:
		_expect(FrontServiceScript.overlay_day_entry(run, day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays).is_empty(), "DAY %d 공통 내용 유지" % day)
	var day5 := FrontServiceScript.overlay_day_entry(run, 5, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	_expect(not day5.is_empty() and not day5.has("wave_modifier"), "DAY 05는 성광 잔향 징후만 표시")
	var expected_totals := {10: 6, 11: 7, 15: 6, 20: 7, 25: 6}
	for day in expected_totals.keys():
		var modifier := FrontServiceScript.day_defense_modifier(run, day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
		var manager = WaveManagerScript.new()
		manager.setup(day, DataRegistry.waves, {"holy": modifier})
		_expect(manager.total_to_spawn == int(expected_totals[day]), "DAY %02d 웨이브 인원 예산 기존과 동일(%d명)" % [day, int(expected_totals[day])])
		if day >= 11:
			_expect(_schedule_has_holy_enemy(manager.schedule), "DAY %02d 성광 적 출현" % day)
	_expect(_schedule_has_enemy(_schedule_for(run, 10), "seal_chainbearer"), "DAY 10 봉인 사슬 순찰대 첫 등장")
	var day15_schedule := _schedule_for(run, 15)
	_expect(_schedule_has_enemy(day15_schedule, "selen_trainee_paladin") and _schedule_has_enemy(day15_schedule, "choir_exorcist"), "DAY 15 셀렌 1차 심장 점검과 성가 퇴마사")
	var day20_schedule := _schedule_for(run, 20)
	_expect(_schedule_enemy_count(day20_schedule, "reliquary_guard") == 2 and _schedule_enemy_count(day20_schedule, "choir_exorcist") == 1, "DAY 20 성물 수호기사 2·퇴마사 1 호송대")
	var day25_schedule := _schedule_for(run, 25)
	_expect(_schedule_has_enemy(day25_schedule, "selen_trainee_paladin") and _schedule_has_enemy(day25_schedule, "seal_chainbearer"), "DAY 25 셀렌 예비 결투·사슬병")


func _test_events_and_selected_heart_connection() -> void:
	var run := _holy_run("heart_hungry_maw")
	var day15 := FrontServiceScript.overlay_day_entry(run, 15, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	var heart_event := FrontServiceScript.selected_heart_event(run, day15, DataRegistry.update3_events)
	_expect(str(heart_event.get("heart_id", "")) == "heart_hungry_maw" and str(heart_event.get("kind", "")) == "heart_event", "선택한 포식 심장 사건 1개만 DAY 15에 연결")
	_expect(DataRegistry.update3_events.has("event_selen_living_castle_testimony") and DataRegistry.update3_events.has("event_holy_wounded_acolyte"), "성광 전선 핵심 사건 2개 로드")
	var profile := FrontServiceScript.default_update3_profile()
	profile["rival_relations"]["selen"] = 45
	var choice := FrontServiceScript.apply_event_choice(profile, run, "event_selen_living_castle_testimony", "testify_life", 15, DataRegistry.update3_events)
	_expect(bool(choice.get("ok", false)) and int(choice.get("profile", {}).get("rival_relations", {}).get("selen", 0)) == 51, "살아 있는 성 증언 선택이 셀렌 관계에 반영")
	_expect(int(choice.get("active_run", {}).get("run_metrics_update3", {}).get("e12_living_castle_testimony", 0)) == 1, "증언 선택이 E12 지표에 반영")
	var repeated := FrontServiceScript.apply_event_choice(choice.get("profile", {}), choice.get("active_run", {}), "event_selen_living_castle_testimony", "testify_danger", 15, DataRegistry.update3_events)
	_expect(not bool(repeated.get("ok", false)), "같은 전선 사건 중복 선택 거부")


func _test_day28_operations_and_day29_eve() -> void:
	var run := _holy_run()
	var choices := FrontServiceScript.operation_choices(run, 28, DataRegistry.update3_front_operations)
	_expect(choices == ["d28_holy_pilgrim_detour", "d28_holy_relic_registry_swap"], "DAY 28 성광 작전 2개만 제공")
	_expect(str(DataRegistry.raid_mission("d28_holy_relic_registry_swap").get("choice_group", "")) == "day28_holy_purification", "성광 작전이 실제 원정 선택 흐름에 등록")
	var selected := FrontServiceScript.select_operation(run, "d28_holy_relic_registry_swap", 28, DataRegistry.update3_front_operations)
	_expect(bool(selected.get("ok", false)) and str(selected.get("active_run", {}).get("day28_front_operation", "")) == "d28_holy_relic_registry_swap", "성물 목록 바꿔치기 선택을 회차에 저장")
	_expect(FrontServiceScript.selected_operation_modifier(selected.get("active_run", {}), 29, DataRegistry.update3_front_operations).is_empty(), "DAY 28 작전은 DAY 29에 즉시 적용하지 않음")
	var day30_modifier := FrontServiceScript.selected_operation_modifier(selected.get("active_run", {}), 30, DataRegistry.update3_front_operations)
	_expect(int(day30_modifier.get("count_delta_by_enemy", {}).get("reliquary_guard", 0)) == -1 and float(day30_modifier.get("selen_first_inspection_delay", 0.0)) == 3.0, "성물 목록 작전 효과가 DAY 30에만 예약")
	var detour: Dictionary = DataRegistry.update3_front_operations.get("d28_holy_pilgrim_detour", {}).get("defense_modifier", {})
	_expect(float(detour.get("spawn_delay_bonus", 0.0)) == 4.0 and int(detour.get("count_delta_by_enemy", {}).get("choir_exorcist", 0)) == -1 and int(detour.get("selen_mercy_barrier_bonus", 0)) == 12, "순례길 작전의 도착 +4초·퇴마사 -1·방벽 +12")
	var day29 := FrontServiceScript.overlay_day_entry(run, 29, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	var eve := FrontServiceScript.event_definition(str(day29.get("eve_id", "")), DataRegistry.update3_events)
	_expect(str(eve.get("kind", "")) == "finale_eve" and eve.get("required_context", []).size() == 5 and not eve.has("placeholder") and eve.get("dialogue_templates", []).size() == 10, "DAY 29 셀렌 결전 전야는 심장·합동기·작전·관계를 받는 완성 대사")


func _test_leon_regression_and_selen_placeholder() -> void:
	var hero_run := _hero_run()
	for day in [10, 20, 25]:
		_expect(FrontServiceScript.day_defense_modifier(hero_run, day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays).is_empty(), "레온 전선 DAY %02d 기존 웨이브 무변경" % day)
	_expect(str(FrontServiceScript.day_defense_modifier(hero_run, 15, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays).get("id", "")) == "hero_day15_heart_chamber_test", "레온 전선 DAY 15 심장 대응 웨이브 유지")
	var manager = WaveManagerScript.new()
	manager.setup(15, DataRegistry.waves, {})
	_expect(manager.total_to_spawn == 6 and _schedule_has_enemy(manager.schedule, "selen_trainee_paladin") and not _schedule_has_holy_enemy(manager.schedule), "레온 전선 DAY 15 기존 셀렌 웨이브 회귀 방지")
	var selen: Dictionary = DataRegistry.update3_rival_finales.get("selen", {})
	var holy_day30 := FrontServiceScript.overlay_day_entry(_holy_run(), 30, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	_expect(str(selen.get("content_status", "")) == "phase20_combat_ready" and not holy_day30.has("placeholder") and str(holy_day30.get("boss_enemy_id", "")) == "official_paladin_selen", "Phase 20 정식 셀렌 최종 보스로 교체")


func _test_game_root_integration() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.update3_active_run = _holy_run()
	GameState.day = 20
	var day20_modifiers: Dictionary = game._active_defense_modifiers()
	_expect(day20_modifiers.has("holy_day20_relic_convoy"), "GameRoot 방어 시작에 DAY 20 성광 웨이브 오버레이 전달")
	GameState.day = 28
	_expect(game._campaign_required_raid_choice_group() == "day28_holy_purification", "GameRoot DAY 28 선택을 성광 전용 작전 그룹으로 교체")
	var available: Array = game._available_raid_ids()
	_expect(available.size() == 2 and available.has("d28_holy_relic_registry_swap") and available.has("d28_holy_pilgrim_detour"), "DAY 28 원정 화면에 성광 작전 2개만 표시")
	var selected := FrontServiceScript.select_operation(game.update3_active_run, "d28_holy_pilgrim_detour", 28, DataRegistry.update3_front_operations)
	game.update3_active_run = selected.get("active_run", {}).duplicate(true)
	GameState.day = 30
	var day30_modifiers: Dictionary = game._active_defense_modifiers()
	_expect(day30_modifiers.has("holy_pilgrim_detour_day30"), "GameRoot DAY 30에 저장된 성광 작전 효과 복원")
	game.update3_active_run = _hero_run()
	GameState.day = 15
	_expect(not game._active_defense_modifiers().has("holy_day15_first_heart_inspection"), "GameRoot 레온 전선에 성광 웨이브 유출 없음")
	game.update3_active_run = _holy_run("heart_dream_lantern")
	game.update3_profile = FrontServiceScript.default_update3_profile()
	game.update3_profile["rival_relations"]["selen"] = 45
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	_expect(game.ui_layer.get_node_or_null("Update3EventChoiceOverlay") != null, "DAY 15 관리 화면에 성광 사건 선택 창 표시")
	game._choose_update3_event("event_selen_living_castle_testimony", "testify_life")
	_expect(int(game.update3_profile.get("rival_relations", {}).get("selen", 0)) == 51, "실제 사건 UI 선택이 셀렌 관계에 반영")
	_expect(game._pending_update3_event_ids() == ["event_dream_lantern_false_room"], "전선 사건 후 선택한 몽등 심장 사건 1개만 이어서 표시")
	host.queue_free()
	await get_tree().process_frame


func _schedule_for(run: Dictionary, day: int) -> Array:
	var manager = WaveManagerScript.new()
	var modifier := FrontServiceScript.day_defense_modifier(run, day, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
	manager.setup(day, DataRegistry.waves, {"holy": modifier})
	return manager.schedule


func _schedule_has_holy_enemy(schedule: Array) -> bool:
	for entry_value in schedule:
		if entry_value is Dictionary and str(entry_value.get("enemy_id", "")) in ["seal_chainbearer", "reliquary_guard", "choir_exorcist"]:
			return true
	return false


func _schedule_has_enemy(schedule: Array, enemy_id: String) -> bool:
	return _schedule_enemy_count(schedule, enemy_id) > 0


func _schedule_enemy_count(schedule: Array, enemy_id: String) -> int:
	var count := 0
	for entry_value in schedule:
		if entry_value is Dictionary and str(entry_value.get("enemy_id", "")) == enemy_id:
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[HolyPurificationPhase19] FAIL: %s" % message)
