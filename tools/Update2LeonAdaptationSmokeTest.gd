extends Node

const LeonAdaptationServiceScript = preload("res://scripts/systems/campaign/LeonAdaptationService.gd")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const CampaignSaveStoreScript = preload("res://scripts/core/CampaignSaveStore.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_and_selection()
	await _test_runtime_announcement_combat_and_restore()
	if failed:
		print("UPDATE2_LEON_ADAPTATION_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE2_LEON_ADAPTATION_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_data_and_selection() -> void:
	var stances := DataRegistry.leon_adaptive_stances
	_expect(LeonAdaptationServiceScript.validate(stances).is_empty(), "레온 적응 자세 4종 데이터·안내·실전 효과 계약")
	_expect(DataRegistry.leon_adaptive_stance_ids() == ["leon_stance_siege", "leon_stance_pursuit", "leon_stance_purification", "leon_stance_duelist"], "레온 자세 4종 고정 ID와 순서")
	var cases := {
		"facility": "leon_stance_siege",
		"backline": "leon_stance_pursuit",
		"sustain": "leon_stance_purification",
		"direct": "leon_stance_duelist"
	}
	for analysis_key in cases.keys():
		var analysis := {"facility": 1.0, "backline": 1.0, "sustain": 1.0, "direct": 1.0}
		analysis[analysis_key] = 100.0
		var adaptation := LeonAdaptationServiceScript.choose_stance(stances, analysis, 424242)
		_expect(str(adaptation.get("stance_id", "")) == str(cases[analysis_key]), "%s 분석 우세 시 대응 자세 선택" % analysis_key)
		_expect(bool(adaptation.get("locked", false)) and int(adaptation.get("announced_day", 0)) == 24, "%s 자세 DAY 24 고정" % analysis_key)
	var normalized := LeonAdaptationServiceScript.normalize({"stance_id": "unknown", "locked": true}, stances)
	_expect(str(normalized.get("stance_id", "")) == "" and not bool(normalized.get("locked", true)), "알 수 없는 자세 저장값 안전 초기화")


func _test_runtime_announcement_combat_and_restore() -> void:
	var root = GameRootScene.instantiate()
	add_child(root)
	await get_tree().process_frame
	root._onboarding_reset_game()
	root._debug_skip_onboarding()
	GameState.player_name = "적응 검증 마왕"
	root.campaign_cycle_index = 2
	root.update2_cycle_seed = 424242
	GameState.day = 24
	root._apply_campaign_day_entry(24)
	var announced_id := str(root.leon_adaptation.get("stance_id", ""))
	_expect(DataRegistry.leon_adaptive_stances.has(announced_id), "DAY 24 현재 편성 분석으로 레온 자세 1종 결정")
	_expect(bool(root.leon_adaptation.get("locked", false)) and int(root.leon_adaptation.get("announced_day", 0)) == 24, "DAY 24 선택 자세 잠금")
	_expect(root.logs.any(func(line): return str(line).contains("DAY 24 레온 분석")), "DAY 24 선택 자세 예고 로그")
	_expect(root.logs.any(func(line): return str(line).contains("대응 약점 예고")), "DAY 24 자세 약점 동시 예고")
	_expect(root.campaign_profile.get("leon_stance_history", []).size() == 1, "프로필에 회차별 레온 자세 기록")
	var history_size: int = root.campaign_profile.get("leon_stance_history", []).size()
	root._ensure_update2_leon_adaptation(30)
	_expect(str(root.leon_adaptation.get("stance_id", "")) == announced_id and root.campaign_profile.get("leon_stance_history", []).size() == history_size, "DAY 30 재분석·중복 기록 없이 DAY 24 자세 유지")

	_prepare_stage_four(root)
	GameState.day = 30
	root.leon_adaptation = _locked_adaptation("leon_stance_siege")
	root.combat_scene.start_combat()
	root._spawn_enemy("official_hero_leon")
	var siege_leon = _unit_by_id(root.enemy_units, "official_hero_leon")
	_expect(siege_leon != null and siege_leon.role == "facility", "공성 자세가 레온 목표를 실제 시설 압박으로 변경")
	_expect(root.engineers_spawned_this_battle >= 1 and siege_leon.goal_room != "", "공성 자세가 활성 시설 목표를 실제 배정")

	root.leon_adaptation = _locked_adaptation("leon_stance_pursuit")
	root.combat_scene.start_combat()
	root._spawn_enemy("official_hero_leon")
	var pursuit_leon = _unit_by_id(root.enemy_units, "official_hero_leon")
	var pursuit_target = root.monster_units[0]
	var other_target = root.monster_units[1]
	pursuit_target.attack_range = 220.0
	other_target.attack_range = 70.0
	pursuit_leon.global_position = pursuit_target.global_position
	other_target.global_position = pursuit_target.global_position
	_expect(pursuit_leon.move_speed > float(DataRegistry.enemy("official_hero_leon").get("move_speed", 0.0)) and pursuit_leon.attack_range == 180.0, "후열 추격 자세 이동·탐색 범위 실제 증가")
	_expect(root.combat_scene._leon_pursuit_target(pursuit_leon, [other_target, pursuit_target]) == pursuit_target, "후열 추격 자세가 가장 긴 사거리 몬스터 우선 선택")

	root.leon_adaptation = _locked_adaptation("leon_stance_purification")
	root.combat_scene.start_combat()
	root._spawn_enemy("official_hero_leon")
	root.combat_scene._update_leon_adaptation(0.1)
	var purified_target = root.monster_units[0]
	_expect(purified_target.soft_counter_effects.has("healing") and purified_target.soft_counter_effects.has("shield"), "정화 자세가 회복·보호막 억제를 실제 적용")
	_expect(root.combat_scene.leon_stance_activations == 1 and purified_target.soft_counter_max_strength() <= 0.35, "정화 자세 발동 기록과 소프트 카운터 35% 상한")

	root.leon_adaptation = _locked_adaptation("leon_stance_duelist")
	root.combat_scene.start_combat()
	root._spawn_enemy("official_hero_leon")
	var duel_leon = _unit_by_id(root.enemy_units, "official_hero_leon")
	var duel_monster = root.monster_units[0]
	duel_monster.global_position = duel_leon.global_position
	duel_monster.attack_cooldown = 0.0
	var monster_hp_before := int(duel_monster.hp)
	root.combat_scene.try_attack(duel_monster, [duel_leon])
	_expect(int(duel_leon.max_hp) > int(DataRegistry.enemy("official_hero_leon").get("max_hp", 0)) and duel_leon.atk > int(DataRegistry.enemy("official_hero_leon").get("atk", 0)), "결투 자세 레온 체력·공격 실제 강화")
	_expect(int(duel_monster.hp) < monster_hp_before and root.combat_scene.leon_counter_damage > 0, "결투 자세가 근접 피해 일부를 실제 반격")
	var applied_before_retry := int(root.leon_adaptation.get("applied_count", 0))
	root.combat_scene.start_combat()
	_expect(str(root.leon_adaptation.get("stance_id", "")) == "leon_stance_duelist" and int(root.leon_adaptation.get("applied_count", 0)) == applied_before_retry + 1, "DAY 30 패배 재도전에서도 같은 자세 유지")

	root._set_screen("management")
	var payload: Dictionary = root._campaign_save_payload("management")
	_expect(payload.get("update2", {}).get("leon_adaptation", {}).get("stance_id", "") == "leon_stance_duelist", "기존 저장 payload에 잠긴 레온 자세 기록")
	var v2_result := SaveV1ToV2MigratorScript.migrate_inspection({"status": "valid", "payload": payload, "summary": {"day": 30}, "saved_at_unix": 1783872000, "saved_at_text": "2026-07-13"}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	var v3_result := SaveV2ToV3MigratorScript.migrate_envelope(v2_result.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v2_result.get("ok", false)) and bool(v3_result.get("ok", false)), "레온 적응 자료 포함 저장 v1→v2→v3 변환")
	_expect(v3_result.get("envelope", {}).get("active_run", {}).get("leon_adaptation", {}).get("stance_id", "") == "leon_stance_duelist", "저장 v3 active_run 레온 자세 무손실 보존")
	var validation_error: String = CampaignSaveStoreScript.validate_payload(payload, root._campaign_save_summary("management"))
	_expect(validation_error == "", "레온 자세 payload 기본 복원 검증: %s" % validation_error)
	_expect(root._campaign_payload_is_restorable(payload), "레온 자세 payload 그래프·튜토리얼 복원 검증")
	var restored = GameRootScene.instantiate()
	add_child(restored)
	await get_tree().process_frame
	var restored_ok: bool = restored._restore_campaign_payload(payload)
	_expect(restored_ok and str(restored.leon_adaptation.get("stance_id", "")) == "leon_stance_duelist", "이어하기 후 레온 자세 복원")
	var restored_applied := int(restored.leon_adaptation.get("applied_count", 0))
	restored.combat_scene.start_combat()
	_expect(str(restored.leon_adaptation.get("stance_id", "")) == "leon_stance_duelist" and int(restored.leon_adaptation.get("applied_count", 0)) == restored_applied + 1, "이어하기 뒤 DAY 30 재도전도 재추첨 없음")
	restored.queue_free()
	root.queue_free()
	await get_tree().process_frame


func _locked_adaptation(stance_id: String) -> Dictionary:
	var adaptation := LeonAdaptationServiceScript.default_adaptation()
	adaptation["stance_id"] = stance_id
	adaptation["announced_day"] = 24
	adaptation["locked"] = true
	adaptation["retry_seed"] = 424242
	return adaptation


func _prepare_stage_four(root: Node) -> void:
	root.castle_art_stage = "stage_04_citadel"
	root.castle_evolution_history.clear()
	root.castle_evolution_history.append_array(["stage_01_cave", "stage_02_castle", "stage_03_keep", "stage_04_citadel"])
	root.campaign_chapter_one_clear = true
	root.campaign_stage_two_prepared = true
	root.campaign_chapter_two_started = true
	root.campaign_stage_two_upgrade_funded = true
	root.campaign_stage_two_unlock_ready = true
	root.campaign_chapter_three_clear = true
	root.campaign_chapter_four_clear = true
	root.campaign_final_chapter_unlocked = true
	root.campaign_final_upgrade_ready = true
	root.campaign_final_preparation_confirmed = true
	root.first_promotion_completed = true
	root.facility_upgrade_unlocked = true
	root._sync_castle_stage_content()
	root._setup_dungeon_graph()
	root._init_room_directives()


func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if is_instance_valid(unit) and str(unit.unit_id) == unit_id:
			return unit
	return null


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
		return
	failed = true
	push_error("[Update2LeonAdaptation] FAIL: %s" % label)
