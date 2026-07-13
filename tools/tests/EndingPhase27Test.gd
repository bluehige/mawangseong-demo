extends Node

const EndingEvaluatorScript = preload("res://scripts/systems/endings/EndingConditionEvaluator.gd")
const RunMetricsTrackerScript = preload("res://scripts/systems/endings/RunMetricsTracker.gd")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_and_rules()
	_test_e12_reachability()
	_test_e13_reachability()
	_test_e14_heart_variants()
	_test_priority_and_restore()
	_test_rewards()
	if failed:
		print("ENDING_PHASE27_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("ENDING_PHASE27_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_and_rules() -> void:
	_expect(DataRegistry.update3_endings.size() >= 3, "Phase 27 엔딩 E12~E14 세 종을 후속 엔딩과 함께 로드")
	_expect(DataRegistry.ending_rules.size() >= 15, "기존 E00~E11과 Phase 27 E12~E14를 후속 엔딩과 함께 보존")
	var errors := EndingEvaluatorScript.validate_rules(DataRegistry.ending_rules, DataRegistry.run_metric_definitions)
	_expect(errors.is_empty(), "병합된 엔딩 조건·지표·도감 코드 검증: %s" % [errors])
	var codes: Array[String] = []
	for ending_id in ["ending_holy_open_gate", "ending_off_ledger_independence", "ending_living_castle_voice"]:
		var raw: Dictionary = DataRegistry.update3_endings.get(ending_id, {})
		codes.append(str(raw.get("catalog_code", "")))
		_expect(ResourceLoader.exists(str(raw.get("illustration", ""))), "%s 일러스트 리소스 존재" % ending_id)
		_expect(raw.get("reward_ids", []) is Array and not raw.get("reward_ids", []).is_empty(), "%s 비수치 보상 ID 존재" % ending_id)
	_expect(codes == ["E12", "E13", "E14"], "신규 도감 코드는 E12·E13·E14 순서")


func _test_e12_reachability() -> void:
	var boundary := _e12_boundary()
	_expect(_resolved(boundary) == "ending_holy_open_gate", "E12 경계값 성공 fixture")
	var clear := boundary.duplicate(true)
	clear["update3.relation_selen"] = 88
	clear["update3.honor_tone"] = 80
	clear["update3.holy_seals_interrupted"] = 6
	clear["update3.day30_no_down"] = 1
	clear["update3.bebe_rescues_five"] = 1
	clear["update3.selen_mercy_vulnerable_success"] = 1
	_expect(_resolved(clear) == "ending_holy_open_gate", "E12 명확한 성공 fixture")
	for failure in [
		{"update3.relation_selen": 69},
		{"update3.holy_seals_interrupted": 2},
		{"update3.mercy_choice_count": 0}
	]:
		var metrics := boundary.duplicate(true)
		for key in failure.keys(): metrics[key] = failure[key]
		_expect(_resolved(metrics) != "ending_holy_open_gate", "E12 조건 하나 부족 시 차단: %s" % [failure])
	var mismatch := boundary.duplicate(true)
	mismatch["update3.front_id"] = "front_guild_repossession"
	_expect(_resolved(mismatch) != "ending_holy_open_gate", "E12는 성광 정화 전선 밖에서 차단")


func _test_e13_reachability() -> void:
	var boundary := _e13_boundary()
	_expect(_resolved(boundary) == "ending_off_ledger_independence", "E13 경계값 성공 fixture")
	var clear := boundary.duplicate(true)
	clear["update3.relation_roman"] = 91
	clear["update3.average_security_grade"] = 4
	clear["update3.debt_marks_cleansed"] = 8
	clear["update3.day28_no_ledger_forgery"] = 1
	clear["update3.roman_final_budget_two_or_less"] = 1
	clear["update3.toktok_repairs_five"] = 1
	_expect(_resolved(clear) == "ending_off_ledger_independence", "E13 명확한 성공 fixture")
	for failure in [
		{"update3.average_security_grade": 2.99},
		{"update3.campaign_treasure_losses": 2},
		{"update3.gold_at_final": 279}
	]:
		var metrics := boundary.duplicate(true)
		for key in failure.keys(): metrics[key] = failure[key]
		_expect(_resolved(metrics) != "ending_off_ledger_independence", "E13 조건 하나 부족 시 차단: %s" % [failure])
	var mismatch := boundary.duplicate(true)
	mismatch["update3.front_id"] = "front_holy_purification"
	_expect(_resolved(mismatch) != "ending_off_ledger_independence", "E13은 길드 회수 전선 밖에서 차단")


func _test_e14_heart_variants() -> void:
	var stone := _e14_common()
	stone["update3.selected_heart_id"] = "heart_stonebone"
	stone["update3.stonebone_damage_reduced"] = 300
	_expect(_resolved(stone) == "ending_living_castle_voice", "E14 석골 경계값 성공")
	var hungry := _e14_common()
	hungry["update3.selected_heart_id"] = "heart_hungry_maw"
	hungry["update3.hungry_waves"] = 12
	hungry["update3.hungry_safe_clear"] = true
	_expect(_resolved(hungry) == "ending_living_castle_voice", "E14 포식 경계값 성공")
	var dream := _e14_common()
	dream["update3.selected_heart_id"] = "heart_dream_lantern"
	dream["update3.dream_goal_changes"] = 12
	dream["update3.dream_throne_damage"] = 300
	_expect(_resolved(dream) == "ending_living_castle_voice", "E14 몽등 경계값 성공")
	for failure in [
		{"update3.heart_active_uses": 7},
		{"update3.heart_metric_contribution_ratio": 0.179},
		{"update3.selected_heart_mastery_before_run": 0}
	]:
		var metrics := stone.duplicate(true)
		for key in failure.keys(): metrics[key] = failure[key]
		_expect(_resolved(metrics) != "ending_living_castle_voice", "E14 공통 조건 하나 부족 시 차단: %s" % [failure])
	stone["update3.stonebone_damage_reduced"] = 299
	_expect(_resolved(stone) != "ending_living_castle_voice", "E14 석골 변형 조건 1 부족 차단")
	var variants: Dictionary = DataRegistry.update3_endings.get("ending_living_castle_voice", {}).get("heart_variant_lines", {})
	_expect(variants.size() == 3 and not str(variants.get("heart_stonebone", "")).is_empty() and not str(variants.get("heart_hungry_maw", "")).is_empty() and not str(variants.get("heart_dream_lantern", "")).is_empty(), "E14 심장별 변형 대사 3종")


func _test_priority_and_restore() -> void:
	var collision := _e12_boundary()
	for key in _e14_common().keys(): collision[key] = _e14_common()[key]
	collision["update3.selected_heart_id"] = "heart_stonebone"
	collision["update3.stonebone_damage_reduced"] = 400
	_expect(_resolved(collision) == "ending_holy_open_gate", "E12와 E14 충돌 시 전선 특수 E12 우선")
	collision["update2.cycle_index"] = 12
	collision["profile.catalog_count"] = 11
	_expect(_resolved(collision) == "ending_holy_open_gate", "E12와 기존 최상위 E11 충돌 시 E12 우선")
	var before := _snapshot(_e13_boundary())
	var encoded := JSON.stringify(before)
	var restored_value = JSON.parse_string(encoded)
	var restored_tracker = RunMetricsTrackerScript.new()
	var setup_errors: Array[String] = restored_tracker.setup(DataRegistry.run_metric_definitions)
	var restore_errors: Array[String] = restored_tracker.restore(restored_value)
	var after_result := EndingEvaluatorScript.resolve(DataRegistry.ending_rules, restored_tracker.snapshot())
	_expect(setup_errors.is_empty() and restore_errors.is_empty(), "엔딩 지표 저장 문자열 복원 성공")
	_expect(str(EndingEvaluatorScript.resolve(DataRegistry.ending_rules, before).get("ending_id", "")) == str(after_result.get("ending_id", "")) and str(after_result.get("ending_id", "")) == "ending_off_ledger_independence", "저장 복원 전후 E13 판정 동일")


func _test_rewards() -> void:
	var profile := FrontServiceScript.default_update3_profile()
	profile = FrontServiceScript.apply_ending_rewards(profile, {"heart": {"heart_id": "heart_stonebone"}}, "ending_holy_open_gate", DataRegistry.update3_endings)
	_expect(profile.get("update3_endings_seen", []).has("ending_holy_open_gate") and profile.get("guaranteed_contract_instance_ids", []).has("monster_bebe"), "E12 기록·베베 계약 보장 해금")
	_expect(profile.get("joint_boundary_event_ids", []).size() == 2, "E12 공동 경계 사건 두 종 해금")
	profile = FrontServiceScript.apply_ending_rewards(profile, {}, "ending_off_ledger_independence", DataRegistry.update3_endings)
	_expect(profile.get("guaranteed_contract_instance_ids", []).has("monster_toktok") and int(profile.get("contract_board_free_refreshes", 0)) == 1, "E13 톡톡 계약 보장·무료 새로고침 해금")
	profile = FrontServiceScript.apply_ending_rewards(profile, {"heart": {"heart_id": "heart_stonebone"}}, "ending_living_castle_voice", DataRegistry.update3_endings)
	_expect(profile.get("hearts", {}).get("cosmetics", []).has("heart_stonebone_mastery_voice") and profile.get("heart_voice_records", []).has("heart_stonebone") and profile.get("heart_selection_flair_ids", []).has("heart_stonebone"), "E14 선택 심장 외형·음성·다음 회차 연출 해금")
	profile = FrontServiceScript.apply_ending_rewards(profile, {}, "ending_off_ledger_independence", DataRegistry.update3_endings)
	_expect(int(profile.get("contract_board_free_refreshes", 0)) == 1, "같은 엔딩 재판정으로 일회성 보상이 중복되지 않음")
	for ending_value in DataRegistry.update3_endings.values():
		_expect(not ending_value.has("stat_reward") and not ending_value.has("combat_bonus") and not ending_value.has("attribute_bonus"), "%s에 능력치 보상 없음" % str(ending_value.get("catalog_code", "")))


func _e12_boundary() -> Dictionary:
	return {
		"update3.front_id": "front_holy_purification", "update3.final_battle_won": true,
		"update3.relation_selen": 70, "update3.honor_tone": 62, "update3.fear_tone": 58,
		"update3.holy_seals_interrupted": 3, "update3.heart_chamber_disable_count": 1,
		"update3.mercy_choice_count": 1
	}


func _e13_boundary() -> Dictionary:
	return {
		"update3.front_id": "front_guild_repossession", "update3.final_battle_won": true,
		"update3.relation_roman": 68, "update3.average_security_grade": 3,
		"update3.campaign_treasure_losses": 1, "update3.facility_disable_count": 4,
		"update3.debt_marks_cleansed": 4, "update3.gold_at_final": 280
	}


func _e14_common() -> Dictionary:
	return {
		"update3.final_battle_won": true, "update3.heart_active_uses": 8,
		"update3.heart_chamber_disable_count": 0, "update3.heart_metric_contribution_ratio": 0.18,
		"castle.throne_hp_ratio": 0.70, "update3.selected_heart_mastery_before_run": 1
	}


func _snapshot(overrides: Dictionary) -> Dictionary:
	var tracker = RunMetricsTrackerScript.new()
	var errors: Array[String] = tracker.setup(DataRegistry.run_metric_definitions)
	if not errors.is_empty():
		push_error("Phase 27 metric setup failed: %s" % [errors])
	for metric_id_value in overrides.keys():
		tracker.set_value(str(metric_id_value), overrides[metric_id_value])
	return tracker.snapshot()


func _resolved(overrides: Dictionary) -> String:
	return str(EndingEvaluatorScript.resolve(DataRegistry.ending_rules, _snapshot(overrides)).get("ending_id", ""))


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS: %s" % label)
		return
	failed = true
	push_error("  FAIL: %s" % label)
