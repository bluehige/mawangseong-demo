extends Node

const SeededCampaignServiceScript = preload("res://scripts/systems/campaign/Update2SeededCampaignService.gd")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const PRIMARY_SEED := 424242
const OTHER_SEED := 900001
const MILESTONE_DAYS := [10, 15, 20, 25, 30]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_seed_contract()
	await _test_runtime_save_and_restore()
	if failed:
		print("UPDATE2_SEEDED_CAMPAIGN_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE2_SEEDED_CAMPAIGN_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_seed_contract() -> void:
	var data: Dictionary = DataRegistry.update2_seeded_campaign
	_expect(SeededCampaignServiceScript.validate(data).is_empty(), "사건·웨이브 데이터 참조와 1.10 수치 상한")
	var deck_a := SeededCampaignServiceScript.event_deck(data, PRIMARY_SEED)
	var deck_b := SeededCampaignServiceScript.event_deck(data, PRIMARY_SEED)
	var deck_other := SeededCampaignServiceScript.event_deck(data, OTHER_SEED)
	_expect(deck_a == deck_b and deck_a.size() == 10, "같은 seed의 사건 덱 10장이 같은 순서로 재현")
	_expect(deck_a != deck_other, "다른 seed에서 사건 덱 순서 변화")
	_expect(_unique_count(deck_a) == deck_a.size(), "사건 덱에 중복 카드 없음")
	var waves_a := SeededCampaignServiceScript.wave_variant_ids(data, PRIMARY_SEED)
	var waves_b := SeededCampaignServiceScript.wave_variant_ids(data, PRIMARY_SEED)
	var waves_other := SeededCampaignServiceScript.wave_variant_ids(data, OTHER_SEED)
	_expect(waves_a == waves_b and waves_a.size() == 5, "같은 seed의 웨이브 변형 5개가 같은 조합으로 재현")
	_expect(waves_a != waves_other or deck_a != deck_other, "다른 seed에서 사건 또는 웨이브가 변화")
	for day in MILESTONE_DAYS:
		var variant: Dictionary = SeededCampaignServiceScript.wave_variant_for_day(data, waves_a, day)
		_expect(not variant.is_empty() and int(variant.get("day", 0)) == day, "DAY %d 웨이브 변형 정확히 1개 선택" % day)
		_expect(not variant.get("extra_waves", []).is_empty(), "DAY %d 웨이브 변형에 실제 추가 적 존재" % day)


func _test_runtime_save_and_restore() -> void:
	var root = GameRootScene.instantiate()
	add_child(root)
	await get_tree().process_frame
	root._onboarding_reset_game()
	root._debug_skip_onboarding()
	GameState.player_name = "시드 검증 마왕"
	root.campaign_cycle_index = 2
	root.update2_cycle_seed = PRIMARY_SEED
	root._ensure_update2_seeded_campaign()
	var expected_deck := SeededCampaignServiceScript.event_deck(DataRegistry.update2_seeded_campaign, PRIMARY_SEED)
	var expected_waves := SeededCampaignServiceScript.wave_variant_ids(DataRegistry.update2_seeded_campaign, PRIMARY_SEED)
	_expect(root.event_deck_order == expected_deck, "GameRoot 현재 회차 사건 덱 생성")
	_expect(root.wave_variant_ids == expected_waves, "GameRoot 현재 회차 웨이브 변형 생성")

	var event: Dictionary = SeededCampaignServiceScript.event_for_day(DataRegistry.update2_seeded_campaign, expected_deck, 5)
	var resources_before := _resource_snapshot()
	root._apply_update2_seeded_event(5)
	var resources_after := _resource_snapshot()
	_expect(root.update2_triggered_event_ids == [str(event.get("id", ""))], "DAY 5 사건을 현재 회차에 1회 기록")
	_expect(resources_after != resources_before or int(event.get("bond_all", 0)) > 0 or int(event.get("contract_bond", 0)) > 0, "시드 사건의 자원 또는 유대 효과 적용")
	var profile_event_id := "cycle_2:%s" % str(event.get("id", ""))
	_expect(root.campaign_profile.get("seen_event_ids", []).has(profile_event_id), "프로필 사건 도감에 회차와 ID 기록")
	root._apply_update2_seeded_event(5)
	_expect(root.update2_triggered_event_ids.size() == 1 and _resource_snapshot() == resources_after, "같은 사건 중복 적용 차단")

	GameState.day = 10
	var day10_variant: Dictionary = root._update2_seeded_wave_variant(10)
	root.combat_scene.start_combat()
	var scheduled_ids: Array[String] = []
	for entry_value in root.wave_manager.schedule:
		scheduled_ids.append(str(entry_value.get("enemy_id", "")))
	var expected_extra_id := str(day10_variant.get("extra_waves", [])[0].get("enemy_id", ""))
	_expect(scheduled_ids.has(expected_extra_id), "실제 DAY 10 전투 스케줄에 선택된 대응 적 합류")
	_expect(root.logs.any(func(line): return str(line).contains(str(day10_variant.get("title", "")))), "전투 로그에 seed 고정 웨이브 이름 표시")

	root._set_screen("management")
	var payload: Dictionary = root._campaign_save_payload("management")
	_expect(payload.get("update2", {}).get("event_deck_order", []) == expected_deck, "기존 저장 payload에 사건 덱 순서 기록")
	_expect(payload.get("update2", {}).get("wave_variant_ids", []) == expected_waves, "기존 저장 payload에 웨이브 변형 ID 기록")
	_expect(payload.get("update2", {}).get("triggered_event_ids", []) == root.update2_triggered_event_ids, "기존 저장 payload에 발생 사건 기록")
	var v2_result := SaveV1ToV2MigratorScript.migrate_inspection({
		"status": "valid", "payload": payload, "summary": {"day": GameState.day},
		"saved_at_unix": 1783872000, "saved_at_text": "2026-07-13"
	}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v2_result.get("ok", false)), "시드 자료 포함 저장 v1→v2 변환")
	var v3_result := SaveV2ToV3MigratorScript.migrate_envelope(v2_result.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v3_result.get("ok", false)), "시드 자료 포함 저장 v2→v3 변환")
	var active_run: Dictionary = v3_result.get("envelope", {}).get("active_run", {})
	_expect(active_run.get("cycle_seed", 0) == PRIMARY_SEED, "저장 v3 회차 seed 보존")
	_expect(active_run.get("event_deck_order", []) == expected_deck, "저장 v3 사건 덱 순서 보존")
	_expect(active_run.get("wave_variant_ids", []) == expected_waves, "저장 v3 웨이브 변형 보존")
	_expect(active_run.get("triggered_event_ids", []) == root.update2_triggered_event_ids, "저장 v3 발생 사건 보존")
	var validation_error: String = CampaignSaveStoreScript.validate_payload(payload, root._campaign_save_summary("management"))
	_expect(validation_error == "", "시드 회차 payload 기본 검증 통과: %s" % validation_error)
	_expect(root._campaign_payload_is_restorable(payload), "시드 회차 payload 그래프·튜토리얼 복원 검사 통과")

	var restored = GameRootScene.instantiate()
	add_child(restored)
	await get_tree().process_frame
	var restored_ok: bool = restored._restore_campaign_payload(payload)
	_expect(restored_ok, "시드 회차 payload 복원 성공")
	_expect(restored.update2_cycle_seed == PRIMARY_SEED and restored.event_deck_order == expected_deck and restored.wave_variant_ids == expected_waves, "이어하기 후 재추첨 없이 같은 seed 결과 유지")
	_expect(restored.update2_triggered_event_ids == root.update2_triggered_event_ids, "이어하기 후 이미 발생한 사건 유지")
	restored.queue_free()
	root.queue_free()
	await get_tree().process_frame


func _resource_snapshot() -> Dictionary:
	return {"gold": GameState.gold, "mana": GameState.mana, "food": GameState.food, "infamy": GameState.infamy}


func _unique_count(values: Array) -> int:
	var seen: Dictionary = {}
	for value in values:
		seen[str(value)] = true
	return seen.size()


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[Update2SeededCampaign] FAIL: %s" % message)
