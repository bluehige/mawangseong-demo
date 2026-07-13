extends Node

const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const HeartServiceScript = preload("res://scripts/systems/hearts/CastleHeartService.gd")
const ChamberServiceScript = preload("res://scripts/systems/hearts/HeartChamberService.gd")
const AutoProfilePolicyScript = preload("res://scripts/systems/hearts/HeartAutoProfilePolicy.gd")
const HeartScreenScene = preload("res://scenes/ui/screens/HeartSelectionScreen.tscn")
const HeartHUDScene = preload("res://scenes/ui/hud/HeartCombatHUD.tscn")
const MainScene = preload("res://scenes/main/Main.tscn")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const SaveV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")

var failed := false
var assertion_count := 0
var hud_state: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_and_selection()
	_test_awaken_and_chamber()
	_test_mastery_basis()
	_test_auto_profiles()
	await _test_selection_screen()
	await _test_formal_hud()
	await _test_game_root_flow()
	_test_v4_restore()
	if failed:
		print("HEART_SELECTION_PHASE8_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("HEART_SELECTION_PHASE8_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _front_run() -> Dictionary:
	return FrontServiceScript.select_front(FrontServiceScript.default_update3_profile(), FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HERO_FRONT_ID, DataRegistry.update3_fronts).get("active_run", {}).duplicate(true)


func _test_catalog_and_selection() -> void:
	var expected_events := {
		HeartServiceScript.STONEBONE_ID: "event_stonebone_first_crack",
		HeartServiceScript.HUNGRY_MAW_ID: "event_hungry_maw_midnight_snack",
		HeartServiceScript.DREAM_LANTERN_ID: "event_dream_lantern_false_room"
	}
	_expect(DataRegistry.update3_castle_hearts.size() == 3, "심장 카탈로그 정확히 3종")
	for heart_id in expected_events.keys():
		var definition: Dictionary = DataRegistry.update3_castle_hearts.get(heart_id, {})
		_expect(not definition.get("passives", []).is_empty() and not definition.get("tradeoffs", []).is_empty(), "%s 강점·대가 동시 제공" % heart_id)
		_expect(not definition.get("recommended_monsters", []).is_empty() and not definition.get("danger_enemies", []).is_empty(), "%s 추천 몬스터·주의 적 동시 제공" % heart_id)
		_expect(str(definition.get("event_candidate_id", "")) == str(expected_events[heart_id]), "%s 전용 사건 후보 연결" % heart_id)
		var profile := FrontServiceScript.default_update3_profile()
		var selected := HeartServiceScript.select_heart(profile, _front_run(), heart_id, DataRegistry.update3_castle_hearts)
		_expect(bool(selected.get("ok", false)) and str(selected.get("active_run", {}).get("heart", {}).get("heart_id", "")) == heart_id, "%s 새 회차 선택" % heart_id)
		_expect(str(selected.get("active_run", {}).get("heart_event_candidate_id", "")) == str(expected_events[heart_id]), "%s 회차 사건 후보 저장" % heart_id)
		_expect(int(selected.get("profile", {}).get("hearts", {}).get("records", {}).get(heart_id, {}).get("selected_count", 0)) == 1, "%s 선택 횟수 기초 기록" % heart_id)
		var changed := HeartServiceScript.select_heart(selected.get("profile", {}), selected.get("active_run", {}), "heart_stonebone" if heart_id != "heart_stonebone" else "heart_hungry_maw", DataRegistry.update3_castle_hearts)
		_expect(not bool(changed.get("ok", true)), "%s 선택 뒤 다른 심장으로 변경 불가" % heart_id)


func _test_awaken_and_chamber() -> void:
	var selected := HeartServiceScript.select_heart(FrontServiceScript.default_update3_profile(), _front_run(), HeartServiceScript.STONEBONE_ID, DataRegistry.update3_castle_hearts)
	var active: Dictionary = selected.get("active_run", {})
	var day3 := HeartServiceScript.awaken(active, 3)
	active = day3.get("active_run", active)
	_expect(not bool(active.get("heart", {}).get("awakened", true)), "DAY 3에는 심장 미각성")
	var day4 := HeartServiceScript.awaken(active, 4)
	active = day4.get("active_run", active)
	_expect(bool(day4.get("awakened_now", false)) and int(active.get("heart", {}).get("awakened_day", 0)) == 4, "DAY 4에 정확히 한 번 각성")
	var day5 := HeartServiceScript.awaken(active, 5)
	_expect(not bool(day5.get("awakened_now", true)) and int(day5.get("active_run", {}).get("heart", {}).get("awakened_day", 0)) == 4, "DAY 5 재진입 시 중복 각성 없음")
	var stage1 := ChamberServiceScript.sync_active_run(active, 1)
	_expect(not bool(stage1.get("heart", {}).get("chamber_spawned", true)), "Stage 01에는 심장실 없음")
	var stage2 := ChamberServiceScript.sync_active_run(active, 2)
	_expect(bool(stage2.get("heart", {}).get("chamber_spawned", false)) and int(stage2.get("heart", {}).get("chamber_max_hp", 0)) == 420, "Stage 02에 심장실 1회 생성")


func _test_mastery_basis() -> void:
	var profile := FrontServiceScript.default_update3_profile()
	var selected := HeartServiceScript.select_heart(profile, _front_run(), HeartServiceScript.STONEBONE_ID, DataRegistry.update3_castle_hearts)
	profile = selected.get("profile", {})
	var active: Dictionary = selected.get("active_run", {})
	for _index in range(10):
		var usage := HeartServiceScript.record_active_use(profile, active)
		profile = usage.get("profile", profile)
		active = usage.get("active_run", active)
	_expect(int(profile.get("hearts", {}).get("records", {}).get(HeartServiceScript.STONEBONE_ID, {}).get("active_uses", 0)) == 10, "심장 액티브 10회 누적 기록")
	_expect(int(profile.get("hearts", {}).get("mastery", {}).get(HeartServiceScript.STONEBONE_ID, 0)) == 33, "액티브 10회 숙련 항목 33점")
	profile = HeartServiceScript.record_campaign_clear(profile, active)
	_expect(bool(profile.get("hearts", {}).get("records", {}).get(HeartServiceScript.STONEBONE_ID, {}).get("first_clear", false)), "첫 클리어 기록")
	_expect(bool(profile.get("hearts", {}).get("records", {}).get(HeartServiceScript.STONEBONE_ID, {}).get("day30_no_chamber_disable", false)), "심장실 무력화 없는 DAY 30 기록")
	_expect(int(profile.get("hearts", {}).get("mastery", {}).get(HeartServiceScript.STONEBONE_ID, 0)) == 100, "심장 숙련 세 항목 완료 시 100점")
	var disabled_active := HeartServiceScript.record_chamber_disabled(active)
	var disabled_profile := HeartServiceScript.record_campaign_clear(selected.get("profile", {}), disabled_active)
	_expect(not bool(disabled_profile.get("hearts", {}).get("records", {}).get(HeartServiceScript.STONEBONE_ID, {}).get("day30_no_chamber_disable", true)), "심장실 무력화 회차는 무피해 숙련 미달성")


func _test_auto_profiles() -> void:
	var audit := AutoProfilePolicyScript.audit(DataRegistry.update3_heart_auto_profiles)
	_expect(DataRegistry.update3_heart_auto_profiles.size() == 7, "3차 자동 플레이 성향 7종")
	_expect(bool(audit.get("ok", false)), "자동 성향에서 한 심장 독점 없음")
	_expect(float(audit.get("average_gap", 100.0)) < 10.0, "세 심장 평균 예상 완주율 격차 10%p 미만")
	for count in audit.get("lead_counts", {}).values():
		_expect(int(count) > 0, "각 심장이 하나 이상의 자동 성향에서 공동 선두")


func _test_selection_screen() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var screen = HeartScreenScene.instantiate()
	screen.setup(FrontServiceScript.default_update3_profile(), DataRegistry.update3_castle_hearts, "용사의 서약 전선", true)
	host.add_child(screen)
	await get_tree().process_frame
	for heart_id in [HeartServiceScript.STONEBONE_ID, HeartServiceScript.HUNGRY_MAW_ID, HeartServiceScript.DREAM_LANTERN_ID]:
		var button: Button = screen.get_node("DesignCanvas/HeartCardButton_%s" % heart_id)
		_expect(button != null and not button.disabled, "%s 선택 카드 활성" % heart_id)
		var contract: Dictionary = screen.comparison_contract(heart_id)
		_expect(not contract.get("strengths", []).is_empty() and not contract.get("tradeoffs", []).is_empty(), "%s UI 강점·대가 계약" % heart_id)
	_expect(screen.get_node_or_null("DesignCanvas/HeartSelectionCancelButton") != null, "심장 선택 보류·복귀 버튼")
	_expect(not _all_label_text(screen).contains("쉬움") and not _all_label_text(screen).contains("어려움"), "심장 카드에 쉬움·어려움 등급 없음")
	for viewport_size in [Vector2(1920, 1080), Vector2(1366, 768)]:
		var rects: Dictionary = screen.layout_rects_for_viewport(viewport_size)
		_expect(_rects_inside(rects, viewport_size), "%dx%d 심장 카드 화면 내부" % [int(viewport_size.x), int(viewport_size.y)])
		_expect(_no_overlaps(rects), "%dx%d 심장 카드 비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	host.queue_free()


func _test_formal_hud() -> void:
	var host := Control.new()
	host.size = Vector2(1366, 768)
	add_child(host)
	var hud = HeartHUDScene.instantiate()
	host.add_child(hud)
	hud_state = {"heart": {"heart_id": HeartServiceScript.HUNGRY_MAW_ID, "awakened": true, "charge": 100, "disabled_this_battle": false, "active_used_this_battle": false, "active_remaining": 0.0}}
	hud.setup(Callable(self, "_provide_hud_state"))
	await get_tree().process_frame
	_expect(hud.visible and hud.get_node_or_null("HeartHUDDesignCanvas/HeartHUDFrame") != null, "정식 심장 HUD 컴포넌트 생성")
	_expect(str(hud.name_label.text) == "포식 심장" and str(hud.detail_label.text).contains("H키"), "HUD 이름·충전 완료 행동 안내")
	_expect(hud.content_root.scale.x > 0.70 and hud.content_root.scale.x < 0.72, "1366×768 HUD 안전 배율")
	hud_state["heart"]["disabled_this_battle"] = true
	await get_tree().process_frame
	_expect(str(hud.detail_label.text).contains("무력화"), "HUD 심장실 무력화 상태 표시")
	host.queue_free()


func _provide_hud_state() -> Dictionary:
	return hud_state.duplicate(true)


func _test_game_root_flow() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.campaign_cycle_index = 2
	game.update3_profile = FrontServiceScript.default_update3_profile()
	game.update3_active_run = FrontServiceScript.new_cycle_active_run(2)
	GameState.day = 4
	game._select_update3_front(FrontServiceScript.HERO_FRONT_ID)
	_expect(game.current_screen == Constants.SCREEN_HEART_SELECTION and game.ui_layer.get_node_or_null("HeartSelectionScreen") != null, "실제 전선 선택 뒤 심장 선택 화면 진입")
	_expect(game._next_update2_cycle_setup_screen() == Constants.SCREEN_HEART_SELECTION, "심장 미선택 저장 복원 목적지")
	game._select_update3_heart(HeartServiceScript.HUNGRY_MAW_ID)
	_expect(game.current_screen == Constants.SCREEN_CONTRACT_BOARD, "실제 심장 선택 뒤 계약 화면 진입")
	_expect(str(game.update3_active_run.get("heart", {}).get("heart_id", "")) == HeartServiceScript.HUNGRY_MAW_ID and bool(game.update3_active_run.get("heart", {}).get("awakened", false)), "실제 포식 심장 저장·DAY 4 각성")
	host.queue_free()


func _test_v4_restore() -> void:
	var migration := SaveV4MigratorScript.migrate_envelope(_base_v3_fixture(), DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs())
	var envelope: Dictionary = migration.get("envelope", {}).duplicate(true)
	var profile: Dictionary = envelope.get("profile", {})
	var front_selected := FrontServiceScript.select_front(profile, FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HERO_FRONT_ID, DataRegistry.update3_fronts)
	var heart_selected := HeartServiceScript.select_heart(front_selected.get("profile", profile), front_selected.get("active_run", {}), HeartServiceScript.DREAM_LANTERN_ID, DataRegistry.update3_castle_hearts)
	profile = heart_selected.get("profile", profile)
	var active: Dictionary = HeartServiceScript.awaken(heart_selected.get("active_run", {}), 4).get("active_run", {})
	envelope["profile"]["hearts"] = profile.get("hearts", {}).duplicate(true)
	for key in active.keys():
		envelope["active_run"][key] = active[key].duplicate(true) if active[key] is Dictionary or active[key] is Array else active[key]
	_expect(SaveV4MigratorScript.validate_v4(envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, _save_catalogs()) == "", "심장 선택·숙련 기초 v4 저장 유효")
	var restored = JSON.parse_string(JSON.stringify(envelope))
	_expect(str(restored.get("active_run", {}).get("heart", {}).get("heart_id", "")) == HeartServiceScript.DREAM_LANTERN_ID, "선택 심장 v4 복원")
	_expect(str(restored.get("active_run", {}).get("heart_event_candidate_id", "")) == "event_dream_lantern_false_room", "심장 사건 후보 v4 복원")
	_expect(int(restored.get("profile", {}).get("hearts", {}).get("records", {}).get(HeartServiceScript.DREAM_LANTERN_ID, {}).get("selected_count", 0)) == 1, "심장 숙련 기록 v4 복원")


func _base_v3_fixture() -> Dictionary:
	var payload := {
		"checkpoint": "management", "screen": "management",
		"world": {"selected_monster_id": "slime", "castle_art_stage": "stage_01_cave", "monster_roster": {"slime": {"level": 1}, "goblin": {"level": 1}, "imp": {"level": 1}}},
		"raid": {"selected_monster_ids": []}, "campaign": {"completed": false, "final_battle_outcome": "", "postgame_active": false},
		"result": {}, "game_state": {"day": 4}, "onboarding": {}, "update2": {}
	}
	var v2 := SaveV1ToV2MigratorScript.migrate_inspection({"status": "valid", "payload": payload, "summary": {"day": 4}, "saved_at_unix": 1783872000}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	return SaveV2ToV3MigratorScript.migrate_envelope(v2.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions).get("envelope", {})


func _save_catalogs() -> Dictionary:
	return {"fronts": DataRegistry.update3_fronts, "castle_hearts": DataRegistry.update3_castle_hearts, "duo_links": DataRegistry.update3_duo_links, "rival_finales": DataRegistry.update3_rival_finales}


func _all_label_text(node: Node) -> String:
	var result := ""
	if node is Label:
		result += str(node.text)
	for child in node.get_children():
		result += _all_label_text(child)
	return result


func _rects_inside(rects: Dictionary, viewport_size: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	for rect_value in rects.values():
		if not bounds.encloses(rect_value):
			return false
	return true


func _no_overlaps(rects: Dictionary) -> bool:
	var values := rects.values()
	for first in range(values.size()):
		for second in range(first + 1, values.size()):
			if values[first].intersects(values[second]):
				return false
	return true


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[HeartSelectionPhase8] FAIL: %s" % message)
