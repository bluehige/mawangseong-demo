extends Node

const EndingEvaluatorScript = preload("res://scripts/systems/endings/EndingConditionEvaluator.gd")
const RunMetricsTrackerScript = preload("res://scripts/systems/endings/RunMetricsTracker.gd")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const FrontScreenScene = preload("res://scenes/ui/screens/FrontSelectionScreen.tscn")
const ChronicleServiceScript = preload("res://scripts/systems/chronicle/ChronicleService.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_and_rules()
	_test_e15_boundaries()
	_test_e16_boundaries_and_priority()
	_test_e14_e15_tiebreak()
	_test_rewards_and_profile_gate()
	await _test_locked_and_unlocked_ui()
	_test_restore()
	if failed:
		print("ENDING_PHASE28_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("ENDING_PHASE28_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_and_rules() -> void:
	_expect(DataRegistry.update3_endings.size() == 5, "3차 엔딩 E12~E16 다섯 종 로드")
	_expect(DataRegistry.ending_rules.size() == 17, "기존 E00~E11과 신규 E12~E16 병합")
	var errors := EndingEvaluatorScript.validate_rules(DataRegistry.ending_rules, DataRegistry.run_metric_definitions)
	_expect(errors.is_empty(), "E15·E16 조건과 점수 지표 검증: %s" % [errors])
	for ending_id in ["ending_linked_corridors", "ending_three_front_armistice"]:
		var ending: Dictionary = DataRegistry.update3_endings.get(ending_id, {})
		_expect(ResourceLoader.exists(str(ending.get("illustration", ""))), "%s 일러스트 리소스 존재" % ending_id)
		_expect(not ending.has("stat_reward") and not ending.has("combat_bonus") and not ending.has("attribute_bonus"), "%s에 수치 보상 없음" % ending_id)


func _test_e15_boundaries() -> void:
	var boundary := _e15_boundary()
	_expect(_resolved(boundary) == "ending_linked_corridors", "E15 경계값에서 달성")
	var failures := [
		{"update3.final_battle_won": false},
		{"update3.distinct_link_skills_used_campaign": 1},
		{"update3.link_skill_used_day30": false},
		{"update3.average_active_pair_bond": 64},
		{"update3.max_monster_contribution_ratio": 0.41},
		{"update3.day30_pair_member_down_count": 1}
	]
	for failure in failures:
		var metrics := boundary.duplicate(true)
		for key in failure.keys():
			metrics[key] = failure[key]
		_expect(_resolved(metrics) != "ending_linked_corridors", "E15 공통 조건 하나 부족 시 차단: %s" % [failure])


func _test_e16_boundaries_and_priority() -> void:
	var boundary := _e16_boundary()
	_expect(_resolved(boundary) == "ending_three_front_armistice", "E16 모든 프로필·현재 회차 경계값에서 달성")
	var failures := [
		{"update3.front_clear_hero_oath": 0}, {"update3.front_clear_holy_purification": 0}, {"update3.front_clear_guild_repossession": 0},
		{"update3.relation_leon": 64}, {"update3.relation_selen": 64}, {"update3.relation_roman": 64},
		{"update3.ending_holy_open_gate_seen": false}, {"update3.ending_off_ledger_independence_seen": false},
		{"update3.final_battle_won": false}, {"decision.day29": "castle_oath"},
		{"update3.campaign_treasure_losses": 3}, {"update3.heart_chamber_disable_count": 2}, {"update3.campaign_abandonment_count": 1}
	]
	for failure in failures:
		var metrics := boundary.duplicate(true)
		for key in failure.keys():
			metrics[key] = failure[key]
		_expect(_resolved(metrics) != "ending_three_front_armistice", "E16 조건 하나 부족 시 완전히 차단: %s" % [failure])
	var collision := boundary.duplicate(true)
	for key in _e15_boundary().keys(): collision[key] = _e15_boundary()[key]
	for key in _e12_boundary().keys(): collision[key] = _e12_boundary()[key]
	_expect(_resolved(collision) == "ending_three_front_armistice", "E16이 E12·E15 동시 충족보다 우선")
	var e12_collision := _e15_boundary()
	for key in _e12_boundary().keys(): e12_collision[key] = _e12_boundary()[key]
	_expect(_resolved(e12_collision) == "ending_holy_open_gate", "E12가 E15보다 우선")


func _test_e14_e15_tiebreak() -> void:
	var both := _e15_boundary()
	for key in _e14_boundary().keys(): both[key] = _e14_boundary()[key]
	both["update3.heart_metric_contribution_ratio"] = 0.40
	_expect(_resolved(both) == "ending_living_castle_voice", "심장 기여 점수가 높으면 E14")
	both["update3.heart_metric_contribution_ratio"] = 0.18
	both["update3.new_duo_memories_two"] = 1
	both["update3.both_equipped_links_used_day30"] = 1
	both["update3.five_deployed_all_contributed_eight_percent"] = 1
	both["update3.day29_link_preference"] = 1
	_expect(_resolved(both) == "ending_linked_corridors", "합동 기억·DAY30 사용·균등 기여 보너스가 높으면 E15")
	both["update3.heart_metric_contribution_ratio"] = 0.24
	both["update3.new_duo_memories_two"] = 0
	both["update3.both_equipped_links_used_day30"] = 0
	both["update3.five_deployed_all_contributed_eight_percent"] = 0
	both["update3.day29_link_preference"] = 0
	both["update3.ending_e14_unseen"] = 0
	both["update3.ending_e15_unseen"] = 0
	_expect(_resolved(both) == "ending_living_castle_voice", "E14·E15 완전 동점은 E14")


func _test_rewards_and_profile_gate() -> void:
	var profile := FrontServiceScript.default_update3_profile()
	_expect(not FrontServiceScript.armistice_profile_eligible(profile), "미완료 프로필은 E16 휴전문 선택 자격 없음")
	profile = FrontServiceScript.apply_ending_rewards(profile, {}, "ending_linked_corridors", DataRegistry.update3_endings)
	_expect(int(profile.get("duo_link_preset_slots", 0)) == 2 and profile.get("duo_link_presets", []).size() == 2, "E15 합동기 프리셋 2칸 해금")
	_expect(bool(profile.get("duo_link_auto_recommendation_unlocked", false)), "E15 자동 추천 해금")
	profile["fronts"]["clear_counts"] = {"front_hero_oath": 1, "front_holy_purification": 1, "front_guild_repossession": 1}
	profile["rival_relations"] = {"leon": 65, "selen": 65, "roman": 65}
	profile["update3_endings_seen"].append_array(["ending_holy_open_gate", "ending_off_ledger_independence"])
	_expect(FrontServiceScript.armistice_profile_eligible(profile), "세 전선·세 관계·E12/E13 기록을 갖춘 프로필만 E16 선택 자격")
	profile = FrontServiceScript.apply_ending_rewards(profile, {}, "ending_three_front_armistice", DataRegistry.update3_endings)
	var unlocked: Array = profile.get("fronts", {}).get("unlocked", [])
	_expect(unlocked.has("front_hero_oath") and unlocked.has("front_holy_purification") and unlocked.has("front_guild_repossession"), "E16 다음 회차 세 전선 즉시 해금")
	_expect(bool(profile.get("front_rotation_unlocked", false)) and not bool(profile.get("front_rotation_enabled", true)), "E16 전선 순환 옵션 해금·기본 꺼짐")
	_expect(bool(profile.get("chronicle_final_nameplate", false)), "E16 연대기 최종 명패 해금")
	var view_model := ChronicleServiceScript.build_view_model(profile, {"fronts": DataRegistry.update3_fronts, "castle_hearts": DataRegistry.update3_castle_hearts, "duo_links": DataRegistry.update3_duo_links}, DataRegistry.update3_chronicle_goals)
	_expect(bool(view_model.get("final_nameplate_unlocked", false)), "연대기 보기 모델에 최종 명패 전달")


func _test_locked_and_unlocked_ui() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var locked_screen = FrontScreenScene.instantiate()
	locked_screen.setup(FrontServiceScript.default_update3_profile(), DataRegistry.update3_fronts, 2, true)
	host.add_child(locked_screen)
	await get_tree().process_frame
	var locked_button: Button = locked_screen.get_node("DesignCanvas/FrontRotationButton")
	_expect(locked_button.disabled and locked_button.text.contains("잠김"), "E16 전에는 전선 순환 UI 잠금")
	locked_screen.queue_free()
	await get_tree().process_frame
	var profile := FrontServiceScript.default_update3_profile()
	profile["front_rotation_unlocked"] = true
	profile["front_rotation_enabled"] = false
	var unlocked_screen = FrontScreenScene.instantiate()
	unlocked_screen.setup(profile, DataRegistry.update3_fronts, 3, true)
	host.add_child(unlocked_screen)
	await get_tree().process_frame
	var unlocked_button: Button = unlocked_screen.get_node("DesignCanvas/FrontRotationButton")
	_expect(not unlocked_button.disabled and unlocked_button.text.contains("꺼짐"), "E16 뒤 전선 순환 UI 해금·기본 꺼짐 표시")
	host.queue_free()


func _test_restore() -> void:
	var before := _snapshot(_e16_boundary())
	var restored_value = JSON.parse_string(JSON.stringify(before))
	var tracker = RunMetricsTrackerScript.new()
	var setup_errors: Array[String] = tracker.setup(DataRegistry.run_metric_definitions)
	var restore_errors: Array[String] = tracker.restore(restored_value)
	var after := EndingEvaluatorScript.resolve(DataRegistry.ending_rules, tracker.snapshot())
	_expect(setup_errors.is_empty() and restore_errors.is_empty(), "E16 지표 저장 문자열 복원")
	_expect(str(after.get("ending_id", "")) == "ending_three_front_armistice", "저장 복원 전후 E16 판정 동일")


func _e15_boundary() -> Dictionary:
	return {"update3.final_battle_won": true, "update3.distinct_link_skills_used_campaign": 2, "update3.link_skill_used_day30": true, "update3.average_active_pair_bond": 65, "update3.max_monster_contribution_ratio": 0.40, "update3.day30_pair_member_down_count": 0}


func _e16_boundary() -> Dictionary:
	return {"update3.front_clear_hero_oath": 1, "update3.front_clear_holy_purification": 1, "update3.front_clear_guild_repossession": 1, "update3.relation_leon": 65, "update3.relation_selen": 65, "update3.relation_roman": 65, "update3.ending_holy_open_gate_seen": true, "update3.ending_off_ledger_independence_seen": true, "update3.final_battle_won": true, "decision.day29": "grand_armistice_request", "update3.campaign_treasure_losses": 2, "update3.heart_chamber_disable_count": 1, "update3.campaign_abandonment_count": 0}


func _e14_boundary() -> Dictionary:
	return {"update3.final_battle_won": true, "update3.heart_active_uses": 8, "update3.heart_chamber_disable_count": 0, "update3.heart_metric_contribution_ratio": 0.18, "castle.throne_hp_ratio": 0.70, "update3.selected_heart_mastery_before_run": 1, "update3.selected_heart_id": "heart_stonebone", "update3.stonebone_damage_reduced": 300}


func _e12_boundary() -> Dictionary:
	return {"update3.front_id": "front_holy_purification", "update3.final_battle_won": true, "update3.relation_selen": 70, "update3.honor_tone": 62, "update3.fear_tone": 58, "update3.holy_seals_interrupted": 3, "update3.heart_chamber_disable_count": 1, "update3.mercy_choice_count": 1}


func _snapshot(overrides: Dictionary) -> Dictionary:
	var tracker = RunMetricsTrackerScript.new()
	var errors: Array[String] = tracker.setup(DataRegistry.run_metric_definitions)
	if not errors.is_empty(): push_error("Phase 28 metric setup failed: %s" % [errors])
	for metric_id_value in overrides.keys(): tracker.set_value(str(metric_id_value), overrides[metric_id_value])
	return tracker.snapshot()


func _resolved(overrides: Dictionary) -> String:
	return str(EndingEvaluatorScript.resolve(DataRegistry.ending_rules, _snapshot(overrides)).get("ending_id", ""))


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS · %s" % label)
	else:
		failed = true
		push_error("  FAIL · %s" % label)
