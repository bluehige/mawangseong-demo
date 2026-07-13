extends Node

const Spec = preload("res://tools/update3_baseline/Update3BaselineSpec.gd")
const Summary = preload("res://tools/update3_baseline/Update3BaselineSummary.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")
const FrontService = preload("res://scripts/systems/fronts/FrontCampaignService.gd")

const RUN_ID := "contract-test-run"
const COMMIT_SHA := "0123456789abcdef0123456789abcdef01234567"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_contract()
	_test_matrix_contract()
	_test_summary_hard_gates()
	_test_review_thresholds()
	if failed:
		print("UPDATE3_BASELINE_CONTRACT_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE3_BASELINE_CONTRACT_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_contract() -> void:
	_expect(DataRegistry.update3_fronts.size() == 3, "전선 catalog 3종")
	_expect(DataRegistry.update3_castle_hearts.size() == 3, "심장 catalog 3종")
	_expect(DataRegistry.update3_duo_links.size() == 6, "합동기 catalog 6종")
	for front_id_value in Spec.FRONT_IDS:
		var front_id := str(front_id_value)
		_expect(DataRegistry.update3_fronts.has(front_id), "%s 전선 존재" % front_id)
		_expect(str(DataRegistry.update3_fronts.get(front_id, {}).get("final_enemy_id", "")) == Spec.expected_boss(front_id), "%s 최종 보스 계약" % front_id)
		var operation_id := Spec.operation_for_front(front_id)
		var operation: Dictionary = DataRegistry.update3_front_operations.get(operation_id, {})
		_expect(not operation.is_empty() and str(operation.get("front_id", "")) == front_id and int(operation.get("day", 0)) == 28, "%s 고정 DAY 28 작전 계약" % front_id)
		var operation_modifier: Dictionary = operation.get("defense_modifier", {})
		_expect(not operation_modifier.is_empty() and str(operation_modifier.get("id", "")) != "" and int(operation_modifier.get("apply_on_day", 0)) == Spec.DAY, "%s 고정 작전 DAY 30 modifier 계약" % front_id)
		var active_run := {"update3_enabled": true, "front_id": front_id, "day28_front_operation": operation_id}
		var front_modifier := FrontService.day_defense_modifier(active_run, Spec.DAY, DataRegistry.update3_fronts, DataRegistry.update3_front_day_overlays)
		var with_modifiers: Dictionary = {}
		if not front_modifier.is_empty():
			with_modifiers[str(front_modifier.get("id", "update3_front_day_30"))] = front_modifier
		with_modifiers[str(operation_modifier.get("id", ""))] = operation_modifier
		var without_modifiers := with_modifiers.duplicate(true)
		without_modifiers.erase(str(operation_modifier.get("id", "")))
		var with_operation := WaveManagerScript.new()
		with_operation.setup(Spec.DAY, DataRegistry.waves, with_modifiers)
		var without_operation := WaveManagerScript.new()
		without_operation.setup(Spec.DAY, DataRegistry.waves, without_modifiers)
		_expect(_schedule_signature(with_operation.schedule) != _schedule_signature(without_operation.schedule), "%s 고정 작전 schedule 영향 계약" % front_id)
	for heart_id_value in Spec.HEART_IDS:
		var heart_id := str(heart_id_value)
		_expect(DataRegistry.update3_castle_hearts.has(heart_id), "%s 심장 존재" % heart_id)
	for duo_id_value in Spec.DUO_LINK_IDS:
		var duo_id := str(duo_id_value)
		var definition: Dictionary = DataRegistry.update3_duo_links.get(duo_id, {})
		_expect(not definition.is_empty(), "%s 합동기 존재" % duo_id)
		_expect(_string_array(definition.get("member_instance_ids", [])) == Spec.duo_members(duo_id), "%s 멤버 계약" % duo_id)
		for instance_id in Spec.deployment_for_duo(duo_id):
			var instance: Dictionary = DataRegistry.monster_instance(instance_id)
			_expect(not instance.is_empty(), "%s 배치 인스턴스 존재" % instance_id)
			_expect(str(instance.get("species_id", "")) == Spec.species_for_instance(instance_id), "%s species 매핑" % instance_id)


func _test_matrix_contract() -> void:
	var assignments := Spec.base_assignments()
	var trials := Spec.trials()
	_expect(assignments.size() == Spec.BASE_ASSIGNMENT_COUNT, "기본 배정 18행")
	_expect(trials.size() == Spec.TRIAL_COUNT, "seed 확장 54회")
	var trial_ids: Dictionary = {}
	var front_counts: Dictionary = {}
	var heart_counts: Dictionary = {}
	var duo_counts: Dictionary = {}
	var seed_counts: Dictionary = {}
	var front_heart_counts: Dictionary = {}
	var front_duo_counts: Dictionary = {}
	var heart_duo_counts: Dictionary = {}
	for trial_value in trials:
		var trial: Dictionary = trial_value
		var trial_id := str(trial.get("trial_id", ""))
		_expect(not trial_ids.has(trial_id), "%s trial ID 고유" % trial_id)
		trial_ids[trial_id] = true
		var front_id := str(trial.get("front_id", ""))
		var heart_id := str(trial.get("heart_id", ""))
		var duo_id := str(trial.get("duo_link_id", ""))
		_increment(front_counts, front_id)
		_increment(heart_counts, heart_id)
		_increment(duo_counts, duo_id)
		_increment(seed_counts, str(trial.get("seed", "")))
		_increment(front_heart_counts, "%s|%s" % [front_id, heart_id])
		_increment(front_duo_counts, "%s|%s" % [front_id, duo_id])
		_increment(heart_duo_counts, "%s|%s" % [heart_id, duo_id])
		var deployed := _string_array(trial.get("deployed_instance_ids", []))
		var unique_deployed: Dictionary = {}
		for instance_id in deployed:
			unique_deployed[instance_id] = true
		_expect(deployed.size() == 5 and unique_deployed.size() == 5, "%s 5인 고유 배치" % trial_id)
		for member_id in Spec.duo_members(duo_id):
			_expect(deployed.has(member_id), "%s 대상 합동기 멤버 %s 출전" % [trial_id, member_id])
	for front_id in Spec.FRONT_IDS:
		_expect(int(front_counts.get(front_id, 0)) == 18, "%s 18회" % front_id)
		for heart_id in Spec.HEART_IDS:
			_expect(int(front_heart_counts.get("%s|%s" % [front_id, heart_id], 0)) == 6, "%s×%s 6회" % [front_id, heart_id])
		for duo_id in Spec.DUO_LINK_IDS:
			_expect(int(front_duo_counts.get("%s|%s" % [front_id, duo_id], 0)) == 3, "%s×%s 3회" % [front_id, duo_id])
	for heart_id in Spec.HEART_IDS:
		_expect(int(heart_counts.get(heart_id, 0)) == 18, "%s 18회" % heart_id)
		for duo_id in Spec.DUO_LINK_IDS:
			_expect(int(heart_duo_counts.get("%s|%s" % [heart_id, duo_id], 0)) == 3, "%s×%s 3회" % [heart_id, duo_id])
	for duo_id in Spec.DUO_LINK_IDS:
		_expect(int(duo_counts.get(duo_id, 0)) == 9, "%s 9회" % duo_id)
	for trial_seed in Spec.SEEDS:
		_expect(int(seed_counts.get(str(trial_seed), 0)) == 18, "seed %d 18회" % trial_seed)


func _test_summary_hard_gates() -> void:
	var reports := _valid_reports()
	var valid := Summary.summarize(reports, RUN_ID, COMMIT_SHA)
	_expect(bool(valid.get("checks_passed", false)), "합성 54회 구조 계약 PASS")
	_expect(str(valid.get("review", {}).get("status", "")) == "PASS", "균형 합성 자료 review PASS")
	var valid_review_status := _review_statuses(valid.get("review", {}).get("checks", []))
	_expect(str(valid_review_status.get("winning_combat_time_range", "")) == "PASS", "원 계획 승리 전투 시간 목표 PASS")
	_expect(str(valid_review_status.get("heart_chamber_disable_rate", "")) == "PASS", "원 계획 심장실 무력화율 목표 PASS")
	_expect(str(valid_review_status.get("duo_average_activation_rate", "")) == "PASS", "원 계획 합동기 평균 발동률 목표 PASS")

	var missing := reports.duplicate(true)
	missing.pop_back()
	_expect(not _validation_ok(missing), "누락 trial 거부")

	var duplicate := reports.duplicate(true)
	duplicate.append(reports[0].duplicate(true))
	_expect(not _validation_ok(duplicate), "중복 trial 거부")

	var wrong_sha := reports.duplicate(true)
	wrong_sha[0]["commit_sha"] = "ffffffffffffffffffffffffffffffffffffffff"
	_expect(not _validation_ok(wrong_sha), "SHA 불일치 거부")

	var wrong_schema := reports.duplicate(true)
	wrong_schema[0]["schema_version"] = 2
	_expect(not _validation_ok(wrong_schema), "schema 불일치 거부")

	var wrong_assignment := reports.duplicate(true)
	wrong_assignment[0]["assignment"]["front_id"] = "front_guild_repossession"
	_expect(not _validation_ok(wrong_assignment), "강제 배정 불일치 거부")

	var timeout := reports.duplicate(true)
	timeout[0]["outcome"]["result"] = "timeout"
	timeout[0]["outcome"]["timed_out"] = true
	_expect(not _validation_ok(timeout), "timeout 거부")

	var wrong_boss := reports.duplicate(true)
	wrong_boss[0]["validation"]["scheduled_boss_count"] = 0
	wrong_boss[0]["validation"]["wrong_boss_ids"] = ["guild_commissioner_roman"]
	_expect(not _validation_ok(wrong_boss), "잘못된 최종 보스 거부")

	var inactive_duo := reports.duplicate(true)
	inactive_duo[0]["validation"]["duo_active_at_start"] = false
	_expect(not _validation_ok(inactive_duo), "비활성 합동기 거부")

	var wrong_heart := reports.duplicate(true)
	wrong_heart[0]["validation"]["actual_heart_id_at_start"] = "heart_dream_lantern"
	_expect(not _validation_ok(wrong_heart), "실제 심장 오배정 거부")

	var wrong_charge := reports.duplicate(true)
	wrong_charge[0]["validation"]["heart_charge_at_start"] = 99
	_expect(not _validation_ok(wrong_charge), "시작 심장 charge 불일치 거부")

	var failed_heart_active := reports.duplicate(true)
	failed_heart_active[0]["validation"]["heart_active_succeeded"] = false
	failed_heart_active[0]["outcome"]["heart_active_succeeded"] = false
	failed_heart_active[0]["outcome"]["heart_active_used"] = false
	_expect(not _validation_ok(failed_heart_active), "심장 액티브 실패 거부")

	var wrong_operation := reports.duplicate(true)
	wrong_operation[0]["validation"]["actual_operation_id_at_start"] = "d28_engineer_supply_disruption"
	_expect(not _validation_ok(wrong_operation), "실제 DAY 28 작전 오배정 거부")

	var missing_operation_modifier := reports.duplicate(true)
	missing_operation_modifier[0]["validation"]["operation_modifier_present"] = false
	_expect(not _validation_ok(missing_operation_modifier), "DAY 28 작전 modifier 활성 누락 거부")

	var unapplied_operation_schedule := reports.duplicate(true)
	unapplied_operation_schedule[0]["validation"]["operation_schedule_effect_applied"] = false
	unapplied_operation_schedule[0]["validation"]["actual_operation_schedule_signature"] = str(unapplied_operation_schedule[0]["validation"]["without_operation_schedule_signature"])
	_expect(not _validation_ok(unapplied_operation_schedule), "DAY 28 작전 schedule 미반영 거부")

	var empty_offsets := reports.duplicate(true)
	empty_offsets[0]["initial_offsets"] = {}
	_expect(not _validation_ok(empty_offsets), "빈 seed 위치 jitter 거부")

	var duplicate_offsets := reports.duplicate(true)
	duplicate_offsets[1]["initial_offsets"] = duplicate_offsets[0]["initial_offsets"].duplicate(true)
	duplicate_offsets[2]["initial_offsets"] = duplicate_offsets[0]["initial_offsets"].duplicate(true)
	_expect(not _validation_ok(duplicate_offsets), "같은 배정행의 동일 seed jitter 서명 거부")

	var inter_room_path_stall := reports.duplicate(true)
	inter_room_path_stall[0]["validation"]["inter_room_path_stall_count"] = 1
	_expect(not _validation_ok(inter_room_path_stall), "방간 이동 경로 정지 거부")


func _test_review_thresholds() -> void:
	var reports := _valid_reports()
	for report_value in reports:
		var report: Dictionary = report_value
		var assignment: Dictionary = report.get("assignment", {})
		if str(assignment.get("front_id", "")) == "front_hero_oath":
			report["outcome"]["result"] = "loss"
		if str(assignment.get("duo_link_id", "")) == "link_spore_jelly_shelter":
			report["outcome"]["duo_used"] = false
		var deployed := _string_array(assignment.get("deployed_instance_ids", []))
		var contributions: Dictionary = {}
		for index in range(deployed.size()):
			contributions[Spec.species_for_instance(deployed[index])] = 90 if index == 0 else 2
		report["outcome"]["contribution_by_species"] = contributions
	var summary := Summary.summarize(reports, RUN_ID, COMMIT_SHA)
	_expect(bool(summary.get("checks_passed", false)), "밸런스 편중은 구조 hard gate를 실패시키지 않음")
	_expect(str(summary.get("review", {}).get("status", "")) == "REVIEW", "밸런스 편중 review 상태")
	var check_status := _review_statuses(summary.get("review", {}).get("checks", []))
	_expect(str(check_status.get("front_win_rate_gap", "")) == "REVIEW", "전선 승률 격차 검토")
	_expect(str(check_status.get("duo_activation_link_spore_jelly_shelter", "")) == "REVIEW", "합동기 발동률 검토")
	_expect(str(check_status.get("maximum_individual_average_contribution", "")) == "REVIEW", "개인 기여 편중 검토")


func _valid_reports() -> Array[Dictionary]:
	var reports: Array[Dictionary] = []
	for expected_value in Spec.trials():
		var expected: Dictionary = expected_value
		var operation: Dictionary = DataRegistry.update3_front_operations.get(str(expected.get("operation_id", "")), {})
		var operation_modifier: Dictionary = operation.get("defense_modifier", {})
		var expected_schedule_signature := "with_operation:%s" % str(expected.get("operation_id", ""))
		var without_operation_schedule_signature := "without_operation:%s" % str(expected.get("front_id", ""))
		var contributions: Dictionary = {}
		for instance_id_value in expected.get("deployed_instance_ids", []):
			contributions[Spec.species_for_instance(str(instance_id_value))] = 20
		reports.append({
			"schema_version": Spec.SCHEMA_VERSION,
			"tool": "Update3BaselineTrial",
			"evidence_kind": Spec.TRIAL_EVIDENCE_KIND,
			"generated_at": "2026-07-13T00:00:00Z",
			"run_id": RUN_ID,
			"commit_sha": COMMIT_SHA,
			"fixture_version": Spec.FIXTURE_VERSION,
			"policy_id": Spec.POLICY_ID,
			"assignment_kind": "forced_automated_proxy",
			"trial_index": int(expected.get("trial_index", -1)),
			"trial_id": str(expected.get("trial_id", "")),
			"row_id": str(expected.get("row_id", "")),
			"seed": int(expected.get("seed", 0)),
			"assignment": {
				"front_id": str(expected.get("front_id", "")),
				"heart_id": str(expected.get("heart_id", "")),
				"duo_link_id": str(expected.get("duo_link_id", "")),
				"operation_id": str(expected.get("operation_id", "")),
				"deployed_instance_ids": expected.get("deployed_instance_ids", []).duplicate()
			},
			"configuration": {
				"day": Spec.DAY,
				"stage_id": Spec.STAGE_ID,
				"monster_level": Spec.MONSTER_LEVEL,
				"monster_bond": Spec.MONSTER_BOND,
				"heart_initial_charge": Spec.HEART_INITIAL_CHARGE
			},
			"validation": {
				"expected_boss_id": Spec.expected_boss(str(expected.get("front_id", ""))),
				"scheduled_boss_count": 1,
				"wrong_boss_ids": [],
				"deployed_count": 5,
				"duo_active_at_start": true,
				"actual_heart_id_at_start": str(expected.get("heart_id", "")),
				"heart_charge_at_start": Spec.HEART_INITIAL_CHARGE,
				"heart_active_succeeded": true,
				"expected_operation_id": str(expected.get("operation_id", "")),
				"actual_operation_id_at_start": str(expected.get("operation_id", "")),
				"expected_operation_modifier_id": str(operation_modifier.get("id", "")),
				"operation_modifier_present": true,
				"operation_modifier_matches_catalog": true,
				"operation_schedule_effect_expected": true,
				"operation_schedule_effect_applied": true,
				"expected_operation_schedule_signature": expected_schedule_signature,
				"actual_operation_schedule_signature": expected_schedule_signature,
				"without_operation_schedule_signature": without_operation_schedule_signature,
				"inter_room_path_stall_count": 0
			},
			"outcome": {
				"result": "win",
				"timed_out": false,
				"combat_time_seconds": 90.0 + float(int(expected.get("seed_index", 0))),
				"heart_active_succeeded": true,
				"heart_active_used": true,
				"heart_chamber_disabled": int(expected.get("seed_index", 0)) == 0,
				"duo_used": int(expected.get("seed_index", 0)) < 2,
				"contribution_by_species": contributions
			},
			"initial_offsets": {
				"monster:slime:0": [float(int(expected.get("seed_index", 0))) + 0.1, float(int(expected.get("assignment_index", 0))) + 0.2]
			},
			"hard_failure": false,
			"errors": []
		})
	return reports


func _validation_ok(reports: Array) -> bool:
	return bool(Summary.validate_reports(reports, RUN_ID, COMMIT_SHA).get("ok", false))


func _schedule_signature(schedule: Array) -> String:
	var rows: Array[String] = []
	for entry_value in schedule:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		rows.append("%s@%.4f|%.4f|%.4f|%.4f|%.4f|%s" % [
			str(entry.get("enemy_id", "")),
			float(entry.get("time", 0.0)),
			float(entry.get("hp_scale", 1.0)),
			float(entry.get("atk_scale", 1.0)),
			float(entry.get("def_scale", 1.0)),
			float(entry.get("morale_bonus", 0.0)),
			str(entry.get("_extra_source_modifier_key", ""))
		])
	return "||".join(rows)


func _review_statuses(checks: Array) -> Dictionary:
	var result: Dictionary = {}
	for check_value in checks:
		result[str(check_value.get("id", ""))] = str(check_value.get("status", ""))
	return result


func _increment(counts: Dictionary, key: String) -> void:
	counts[key] = int(counts.get(key, 0)) + 1


func _string_array(values) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[Update3BaselineContract] FAIL: %s" % message)
