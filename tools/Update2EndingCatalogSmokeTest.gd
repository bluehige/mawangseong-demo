extends Node

const EndingConditionEvaluatorScript = preload("res://scripts/systems/endings/EndingConditionEvaluator.gd")
const RunMetricsTrackerScript = preload("res://scripts/systems/endings/RunMetricsTracker.gd")
const NewCycleServiceScript = preload("res://scripts/systems/legacy/NewCycleService.gd")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const ORDERED_ENDINGS := [
	"true_demon_castle", "monster_family_castle", "impregnable_demon_citadel", "dread_overlord_rises",
	"demon_hero_rival_pact", "contract_monster_alliance", "royal_doctrine_broken", "challenge_seal_legend",
	"evelyns_counterledger", "adaptive_rival_mastery", "castle_without_reserves", "twelve_endings_chronicle"
]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_rules_and_reachability()
	await _test_catalog_profile_ui_and_save()
	if failed:
		print("UPDATE2_ENDING_CATALOG_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE2_ENDING_CATALOG_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_rules_and_reachability() -> void:
	var errors := EndingConditionEvaluatorScript.validate_rules(DataRegistry.ending_rules, DataRegistry.run_metric_definitions)
	_expect(errors.is_empty(), "E00~E11 조건식·지표·고유 도감 코드 검증: %s" % [errors])
	_expect(DataRegistry.ending_rules.size() >= 12, "3차 확장 뒤에도 기존 엔딩 규칙 12종 이상 유지")
	var codes: Array[String] = []
	for ending_id in ORDERED_ENDINGS:
		var rule := DataRegistry.ending_rule(ending_id)
		codes.append(str(rule.get("catalog_code", "")))
		_expect(not rule.is_empty() and ResourceLoader.exists(str(rule.get("illustration", ""))) and ResourceLoader.exists(str(rule.get("emblem", ""))) and ResourceLoader.exists(str(rule.get("thumbnail", ""))), "%s 데이터와 표시 자산 경로" % str(rule.get("catalog_code", ending_id)))
	_expect(codes == ["E00", "E01", "E02", "E03", "E04", "E05", "E06", "E07", "E08", "E09", "E10", "E11"], "E00~E11 코드가 중복 없이 순서대로 배정")

	var cases := {
		"true_demon_castle": {},
		"monster_family_castle": {"bond.core_average": 80, "bond.high_rank_count": 3, "style.family": 75},
		"impregnable_demon_citadel": {"castle.throne_hp_ratio": 0.9, "castle.security_score": 85, "style.fortress": 75},
		"dread_overlord_rises": {"infamy.final": 1600, "raid.high_risk_successes": 3, "style.dread": 75},
		"demon_hero_rival_pact": {"relation.leon": 75, "style.honor": 70, "decision.day29": "rival_pact"},
		"contract_monster_alliance": {"update2.cycle_index": 2, "update2.contract_selected_count": 2, "update2.contract_bond_average": 75, "update2.reserve_count": 1},
		"royal_doctrine_broken": {"update2.cycle_index": 2, "update2.doctrine_selected": true, "update2.decree_selected": true, "style.intrigue": 70},
		"challenge_seal_legend": {"update2.cycle_index": 2, "update2.challenge_seal_completed": true},
		"evelyns_counterledger": {"update2.cycle_index": 2, "update2.evelyn_counter_activations": 1, "update2.counterforce_activations": 4},
		"adaptive_rival_mastery": {"update2.cycle_index": 2, "update2.leon_stance_applied": 1, "relation.leon": 70},
		"castle_without_reserves": {"update2.cycle_index": 2, "update2.contract_selected_count": 2, "update2.reserve_count": 0},
		"twelve_endings_chronicle": {"update2.cycle_index": 12, "profile.catalog_count": 11}
	}
	for ending_id in ORDERED_ENDINGS:
		var result := EndingConditionEvaluatorScript.resolve(DataRegistry.ending_rules, _metrics(cases.get(ending_id, {})))
		_expect(bool(result.get("ok", false)) and str(result.get("ending_id", "")) == ending_id, "%s 단독 조건 도달성" % str(DataRegistry.ending_rule(ending_id).get("catalog_code", ending_id)))
	var collision: Dictionary = cases.get("challenge_seal_legend", {}).duplicate(true)
	for key in cases.get("evelyns_counterledger", {}).keys(): collision[key] = cases["evelyns_counterledger"][key]
	for key in cases.get("adaptive_rival_mastery", {}).keys(): collision[key] = cases["adaptive_rival_mastery"][key]
	_expect(str(EndingConditionEvaluatorScript.resolve(DataRegistry.ending_rules, _metrics(collision)).get("ending_id", "")) == "challenge_seal_legend", "E07·E08·E09 동시 충족 시 명시된 우선순위 적용")
	collision["profile.catalog_count"] = 11
	_expect(str(EndingConditionEvaluatorScript.resolve(DataRegistry.ending_rules, _metrics(collision)).get("ending_id", "")) == "twelve_endings_chronicle", "E11 메타 엔딩이 모든 일반 후보보다 우선")


func _test_catalog_profile_ui_and_save() -> void:
	var candidate := {"species_id": "slime", "display_name": "푸딩", "level": 7}
	var profile := NewCycleServiceScript.default_profile()
	for index in range(11):
		profile = NewCycleServiceScript.complete_cycle(profile, ORDERED_ENDINGS[index], {}, candidate)
	_expect(profile.get("ending_archive", {}).size() == 11 and profile.get("ending_catalog_codes", {}).size() == 11, "E00~E10 완료 이력과 도감 코드 누적")
	_expect(str(EndingConditionEvaluatorScript.resolve(DataRegistry.ending_rules, _metrics({"update2.cycle_index": 12, "profile.catalog_count": profile.get("ending_archive", {}).size()})).get("ending_id", "")) == "twelve_endings_chronicle", "E00~E10 도감 완료 후 다음 회차 E11 해금")
	profile = NewCycleServiceScript.complete_cycle(profile, "twelve_endings_chronicle", {}, candidate)
	_expect(profile.get("ending_archive", {}).size() == 12 and profile.get("ending_catalog_codes", {}).size() == 12, "E11까지 12개 도감 영구 누적")

	var root = GameRootScene.instantiate()
	add_child(root)
	await get_tree().process_frame
	root._onboarding_reset_game()
	root._debug_skip_onboarding()
	GameState.player_name = "도감 검증 마왕"
	root.campaign_profile = profile.duplicate(true)
	root.campaign_cycle_index = 13
	root.update2_cycle_seed = 13117
	_expect(root._ending_catalog_ids().slice(0, ORDERED_ENDINGS.size()) == ORDERED_ENDINGS, "도감 UI의 첫 12칸이 E00~E11 순서를 유지")
	root._set_screen(Constants.SCREEN_ENDING_ARCHIVE)
	_expect(_tree_has_label(root.ui_layer, "발견 12/%d" % DataRegistry.ending_rules.size()), "확장된 엔딩 도감 UI에 기존 12종 발견 수 표시")
	_expect(_tree_has_label(root.ui_layer, "E11"), "엔딩 도감 UI에 E11 카드 표시")

	root._set_screen(Constants.SCREEN_MANAGEMENT)
	var payload: Dictionary = root._campaign_save_payload("management")
	var v2_result := SaveV1ToV2MigratorScript.migrate_inspection({"status": "valid", "payload": payload, "summary": {"day": GameState.day}, "saved_at_unix": 1783872000, "saved_at_text": "2026-07-13"}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	var v3_result := SaveV2ToV3MigratorScript.migrate_envelope(v2_result.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v2_result.get("ok", false)) and bool(v3_result.get("ok", false)), "12개 도감 포함 저장 v1→v2→v3 변환: v2=%s / v3=%s" % [str(v2_result.get("error", "")), str(v3_result.get("error", ""))])
	var v3_profile: Dictionary = v3_result.get("envelope", {}).get("profile", {})
	_expect(v3_profile.get("ending_archive", {}).size() == 12 and v3_profile.get("ending_catalog_codes", {}).size() == 12, "저장 v3 프로필에 12개 도감 무손실 보존")
	var restored = GameRootScene.instantiate()
	add_child(restored)
	await get_tree().process_frame
	var restored_ok: bool = restored._restore_campaign_payload(payload)
	_expect(restored_ok and restored.campaign_profile.get("ending_archive", {}).size() == 12 and restored.campaign_profile.get("ending_catalog_codes", {}).size() == 12, "이어하기 후 12개 엔딩 도감 복원")
	restored.queue_free()
	root.queue_free()
	await get_tree().process_frame


func _metrics(overrides: Dictionary) -> Dictionary:
	var tracker = RunMetricsTrackerScript.new()
	tracker.setup(DataRegistry.run_metric_definitions)
	for metric_id_value in overrides.keys():
		tracker.set_value(str(metric_id_value), overrides.get(metric_id_value))
	return tracker.snapshot()


func _tree_has_label(root_node: Node, needle: String) -> bool:
	for child in root_node.get_children():
		if child is Label and str(child.text).contains(needle):
			return true
		if _tree_has_label(child, needle):
			return true
	return false


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
		return
	failed = true
	push_error("[Update2EndingCatalog] FAIL: %s" % label)
