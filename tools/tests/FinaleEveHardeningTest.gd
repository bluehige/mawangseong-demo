extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const ConstantsScript = preload("res://scripts/core/Constants.gd")
const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")

const FRONT_CASES := [
	{"front_id": "front_hero_oath", "eve_id": "eve_leon_oath_front", "rival_id": "leon", "character_id": "CHR_HERO_LEON", "operation_id": "d28_siege_route_recon", "tier_mins": [65, 50, 0]},
	{"front_id": "front_holy_purification", "eve_id": "eve_selen_purification_front", "rival_id": "selen", "character_id": "CHR_SELEN_OFFICIAL", "operation_id": "d28_holy_relic_registry_swap", "tier_mins": [70, 45, 0]},
	{"front_id": "front_guild_repossession", "eve_id": "eve_roman_repossession_front", "rival_id": "roman", "character_id": "CHR_ROMAN_COMMISSIONER", "operation_id": "d28_guild_ledger_forgery", "tier_mins": [68, 45, 0]}
]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_resolver_for_all_fronts()
	_test_relation_boundaries()
	_test_armistice_hint_gate()
	await _test_game_root_day29_and_declaration_regressions()
	print("FINALE_EVE_HARDENING_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_resolver_for_all_fronts() -> void:
	for case in FRONT_CASES:
		var front_id := str(case["front_id"])
		var rival_id := str(case["rival_id"])
		var run := _front_run(front_id, str(case["operation_id"]))
		var profile := FrontServiceScript.default_update3_profile()
		profile["rival_relations"][rival_id] = int(case["tier_mins"][0])
		var event: Dictionary = DataRegistry.update3_events[str(case["eve_id"])].duplicate(true)
		var operation: Dictionary = DataRegistry.update3_front_operations[str(case["operation_id"])].duplicate(true)
		operation["id"] = str(case["operation_id"])
		var before := JSON.stringify([run, profile, event, operation])
		var resolved := FrontServiceScript.resolve_finale_eve(run, profile, event, DataRegistry.update3_castle_hearts, DataRegistry.update3_duo_links, operation)
		_expect(str(resolved.get("rival_id", "")) == rival_id and str(resolved.get("rival_character_id", "")) == str(case["character_id"]), "%s 전야가 해당 최종 라이벌을 사용" % front_id)
		_expect(resolved.get("dialogue", []).size() == 10 and not _dialogue_contains_token(resolved.get("dialogue", [])), "%s 전야 10줄의 문맥 토큰을 모두 해석" % front_id)
		_expect(str(resolved.get("heart_name", "")) == str(DataRegistry.update3_castle_hearts["heart_stonebone"]["display_name"]) and str(resolved.get("duo_name", "")) == str(DataRegistry.update3_duo_links["link_spore_jelly_shelter"]["display_name"]), "%s 전야는 선택 심장과 첫 장착 합동기를 사용" % front_id)
		_expect(str(resolved.get("operation_id", "")) == str(case["operation_id"]) and str(resolved.get("operation_name", "")) == str(operation.get("display_name", "")) and str(resolved.get("operation_result", "")) != "DAY 30 효과 미확정", "%s 전야는 DAY 28 작전과 예약 결과를 사용" % front_id)
		_expect(str(resolved.get("relation_line", "")) == str(event.get("relation_tiers", [])[0].get("text", "")), "%s 전야는 고관계 전용 마지막 대사를 선택" % front_id)
		_expect(_portrait_exists(str(case["character_id"]), str(event.get("rival_emotion", ""))), "%s 전야의 기존 라이벌 초상 리소스 존재" % front_id)
		_expect(before == JSON.stringify([run, profile, event, operation]), "%s 전야 resolver는 입력을 변경하지 않음" % front_id)


func _test_relation_boundaries() -> void:
	for case in FRONT_CASES:
		var event: Dictionary = DataRegistry.update3_events[str(case["eve_id"])]
		var operation: Dictionary = DataRegistry.update3_front_operations[str(case["operation_id"])].duplicate(true)
		operation["id"] = str(case["operation_id"])
		for tier_index in range(3):
			var profile := FrontServiceScript.default_update3_profile()
			profile["rival_relations"][str(case["rival_id"])] = int(case["tier_mins"][tier_index])
			var resolved := FrontServiceScript.resolve_finale_eve(_front_run(str(case["front_id"]), str(case["operation_id"])), profile, event, DataRegistry.update3_castle_hearts, DataRegistry.update3_duo_links, operation)
			_expect(str(resolved.get("relation_line", "")) == str(event.get("relation_tiers", [])[tier_index].get("text", "")), "%s 관계 경계 %d에서 %d단계 대사" % [case["rival_id"], int(case["tier_mins"][tier_index]), tier_index])


func _test_armistice_hint_gate() -> void:
	var case: Dictionary = FRONT_CASES[0]
	var event: Dictionary = DataRegistry.update3_events[str(case["eve_id"])]
	var operation: Dictionary = DataRegistry.update3_front_operations[str(case["operation_id"])].duplicate(true)
	operation["id"] = str(case["operation_id"])
	var locked := FrontServiceScript.resolve_finale_eve(_front_run(str(case["front_id"]), str(case["operation_id"])), FrontServiceScript.default_update3_profile(), event, DataRegistry.update3_castle_hearts, DataRegistry.update3_duo_links, operation)
	_expect(not _dialogue_contains(locked.get("dialogue", []), "휴전문 제안도 가능합니다"), "E16 프로필 미달이면 휴전문 선택 힌트를 숨김")
	var eligible := FrontServiceScript.default_update3_profile()
	eligible["fronts"]["clear_counts"] = {"front_hero_oath": 1, "front_holy_purification": 1, "front_guild_repossession": 1}
	eligible["rival_relations"] = {"leon": 65, "selen": 65, "roman": 65}
	eligible["update3_endings_seen"] = ["ending_holy_open_gate", "ending_off_ledger_independence"]
	var unlocked := FrontServiceScript.resolve_finale_eve(_front_run(str(case["front_id"]), str(case["operation_id"])), eligible, event, DataRegistry.update3_castle_hearts, DataRegistry.update3_duo_links, operation)
	_expect(_dialogue_contains(unlocked.get("dialogue", []), "휴전문 제안도 가능합니다"), "E16 프로필 충족 때만 휴전문 선택 힌트를 표시")


func _test_game_root_day29_and_declaration_regressions() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game._debug_skip_onboarding()
	GameState.day = 29
	var base_day29_before := JSON.stringify(DataRegistry.campaign_day(29))
	game.update3_profile = FrontServiceScript.default_update3_profile()
	game.update3_profile["rival_relations"]["leon"] = 65
	game.update3_active_run = _front_run(FrontServiceScript.HERO_FRONT_ID, "")
	game.completed_raids.clear()
	game.completed_raids["d28_siege_route_recon"] = true
	var hero_info: Dictionary = game._campaign_day_info()
	_expect(str(hero_info.get("final_rival_name", "")) == "레온" and str(hero_info.get("summary", "")).contains("안전한 공성로 정찰"), "구버전 Hero 저장은 완료 원정에서 DAY 28 작전을 복구해 DAY 29에 표시")
	_expect(hero_info.get("management_lines", []).size() == 10 and str(hero_info.get("management_lines", [""])[0]).begins_with("푸딩:"), "전선 DAY 29 관리 로그가 대사 화자 이름을 보존")
	_expect(str(game.update3_active_run.get("day28_front_operation", "")) == "", "DAY 29 구버전 작전 복구는 저장 회차를 암묵적으로 변경하지 않음")
	_expect(base_day29_before == JSON.stringify(DataRegistry.campaign_day(29)), "전선 DAY 29 override가 공통 campaign day 원본을 변경하지 않음")
	for case in [FRONT_CASES[1], FRONT_CASES[2]]:
		game.update3_active_run = _front_run(str(case["front_id"]), str(case["operation_id"]))
		game.update3_profile = FrontServiceScript.default_update3_profile()
		game.update3_profile["rival_relations"][str(case["rival_id"])] = int(case["tier_mins"][0])
		var alternate_info := JSON.stringify(game._campaign_day_info())
		_expect(not alternate_info.contains("레온") and not alternate_info.contains("CHR_HERO_LEON"), "%s DAY 29 정보에 레온 전선 대사·배우가 유출되지 않음" % case["front_id"])

	_test_declaration_metrics(game, FrontServiceScript.HERO_FRONT_ID, true, "현재 Hero 전선")
	_test_declaration_metrics(game, FrontServiceScript.LEGACY_HERO_FRONT_ID, true, "기존 E04 호환 Hero 전선")
	_test_declaration_metrics(game, FrontServiceScript.HOLY_FRONT_ID, false, "성광 전선")
	_test_declaration_metrics(game, FrontServiceScript.GUILD_FRONT_ID, false, "길드 전선")
	_test_legacy_alternate_front_metric_cleanup(game)
	host.queue_free()
	await get_tree().process_frame


func _test_declaration_metrics(game, front_id: String, legacy_bonus_expected: bool, label: String) -> void:
	game._reset_run_metrics()
	game.logs.clear()
	game.update3_profile = FrontServiceScript.default_update3_profile()
	if front_id == FrontServiceScript.LEGACY_HERO_FRONT_ID:
		game.update3_active_run = FrontServiceScript.default_legacy_active_run(1)
	else:
		game.update3_active_run = _front_run(front_id, _operation_for_front(front_id))
	game._set_campaign_final_declaration("rival_pact")
	var leon_relation := int(game.run_metrics_tracker.metrics.get("relation.leon", 0))
	var honor := int(game.run_metrics_tracker.metrics.get("style.honor", 0))
	_expect((leon_relation == 70 and honor == 65) if legacy_bonus_expected else (leon_relation == 0 and honor == 0), "%s 라이벌 약속의 legacy E04 보너스 범위" % label)
	var rival_name := str({FrontServiceScript.HOLY_FRONT_ID: "셀렌", FrontServiceScript.GUILD_FRONT_ID: "로만"}.get(front_id, "레온"))
	_expect(_logs_contain(game.logs, "라이벌 %s에게" % rival_name) and not _logs_contain(game.logs, "과(와)"), "%s 선언 로그가 조사 오류 없는 해당 라이벌 문구를 사용" % label)


func _test_legacy_alternate_front_metric_cleanup(game) -> void:
	game._reset_run_metrics()
	game.update3_profile = FrontServiceScript.default_update3_profile()
	game.update3_profile["rival_relations"]["leon"] = 35
	game.update3_active_run = _front_run(FrontServiceScript.HOLY_FRONT_ID, _operation_for_front(FrontServiceScript.HOLY_FRONT_ID))
	game.castle_art_stage = "stage_04_citadel"
	game.castle_evolution_history.clear()
	for stage_id in ["stage_01_cave", "stage_02_castle", "stage_03_keep", "stage_04_citadel"]:
		game.castle_evolution_history.append(stage_id)
	game.campaign_stage_two_unlock_ready = true
	game.campaign_chapter_three_clear = true
	game.campaign_final_upgrade_ready = true
	game._sync_castle_stage_content()
	game._setup_dungeon_graph()
	game._init_room_directives()
	GameState.player_name = "저장 검증 마왕"
	game.run_metrics_tracker.set_value("decision.day29", "rival_pact")
	game.run_metrics_tracker.set_value("relation.leon", 70.0)
	game.run_metrics_tracker.set_value("style.honor", 65.0)
	var legacy_payload: Dictionary = game._campaign_save_payload("legacy-alternate-front-day29")
	legacy_payload["screen"] = ConstantsScript.SCREEN_MANAGEMENT
	legacy_payload["checkpoint"] = ConstantsScript.SCREEN_MANAGEMENT
	var validation_error := CampaignSaveStoreScript.validate_payload(legacy_payload, game._campaign_save_summary(ConstantsScript.SCREEN_MANAGEMENT))
	_expect(validation_error == "", "구버전 대체 전선 DAY 29 payload 기본 저장 계약 PASS: %s" % validation_error)
	var restored: bool = bool(game._restore_campaign_payload(legacy_payload))
	_expect(restored, "구버전 대체 전선 DAY 29 payload를 실제 복원 경로에서 수용")
	_expect(int(game.run_metrics_tracker.metrics.get("relation.leon", 0)) == 35 and int(game.run_metrics_tracker.metrics.get("style.honor", 0)) == 0, "구버전 대체 전선 저장의 잘못된 E04 보너스를 기존 프로필 관계로 복구")
	_expect(str(game.run_metrics_tracker.metrics.get("decision.day29", "")) == "rival_pact", "구버전 대체 전선 저장의 실제 라이벌 선언 선택은 보존")
	game.run_metrics_tracker.set_value("relation.leon", 70.0)
	game.run_metrics_tracker.set_value("style.honor", 65.0)
	game.run_metrics_tracker.set_value("update2.cycle_index", 2)
	game.run_metrics_tracker.set_value("update2.leon_stance_applied", 1)
	game.run_metrics_tracker.set_value("update3.front_id", FrontServiceScript.HOLY_FRONT_ID)
	var ending_id: String = str(game._resolve_campaign_ending())
	_expect(ending_id not in ["demon_hero_rival_pact", "adaptive_rival_mastery"], "대체 전선은 오염된 legacy 지표가 남아도 레온 전용 E04/E09를 해금하지 않음")
	game.update3_profile["rival_relations"]["leon"] = 35
	game._sync_update3_leon_relation()
	_expect(int(game.update3_profile.get("rival_relations", {}).get("leon", 0)) == 35, "대체 전선의 legacy relation.leon 값은 영구 프로필로 승격되지 않음")


func _front_run(front_id: String, operation_id: String) -> Dictionary:
	var run := FrontServiceScript.default_legacy_active_run(2)
	run["update3_enabled"] = true
	run["front_selection_completed"] = true
	run["front_id"] = front_id
	run["heart"]["heart_id"] = "heart_stonebone"
	run["equipped_duo_links"] = ["link_spore_jelly_shelter", "link_ghostly_evacuate"]
	run["duo_link_loadout_confirmed"] = true
	run["day28_front_operation"] = operation_id
	return run


func _operation_for_front(front_id: String) -> String:
	for case in FRONT_CASES:
		if str(case["front_id"]) == front_id:
			return str(case["operation_id"])
	return ""


func _dialogue_contains_token(dialogue: Array) -> bool:
	for line in dialogue:
		if line is Dictionary and str(line.get("text", "")).contains("{{"):
			return true
	return false


func _dialogue_contains(dialogue: Array, fragment: String) -> bool:
	for line in dialogue:
		if line is Dictionary and str(line.get("text", "")).contains(fragment):
			return true
	return false


func _logs_contain(logs: Array, fragment: String) -> bool:
	for line in logs:
		if str(line).contains(fragment):
			return true
	return false


func _portrait_exists(character_id: String, emotion: String) -> bool:
	var character: Dictionary = DataRegistry.character(character_id)
	var portrait: Dictionary = character.get("portrait", {})
	var variants: Dictionary = portrait.get("variants", {})
	var path := str(variants.get(emotion, portrait.get("base", "")))
	return path != "" and ResourceLoader.exists(path)


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS · %s" % label)
	else:
		failed = true
		push_error("  FAIL · %s" % label)
