extends Node
class_name Update3BaselineSummary

const Spec = preload("res://tools/update3_baseline/Update3BaselineSpec.gd")

var input_dir := ""
var output_dir := ""
var expected_run_id := ""
var expected_commit_sha := ""


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_read_arguments()
	var reports := load_reports(_global_path(input_dir))
	var report := summarize(reports, expected_run_id, expected_commit_sha)
	var resolved_output_dir := _global_path(output_dir)
	DirAccess.make_dir_recursive_absolute(resolved_output_dir)
	var json_path := resolved_output_dir.path_join("summary.json")
	var markdown_path := resolved_output_dir.path_join("summary.md")
	var write_ok := _write_text(json_path, JSON.stringify(report, "\t") + "\n")
	write_ok = _write_text(markdown_path, build_markdown(report)) and write_ok
	print("UPDATE3_BASELINE_SUMMARY_JSON: %s" % json_path)
	print("UPDATE3_BASELINE_SUMMARY_MARKDOWN: %s" % markdown_path)
	print("UPDATE3_BASELINE_SUMMARY: %s" % ("PASS" if bool(report.get("checks_passed", false)) and write_ok else "FAIL"))
	get_tree().quit(0 if bool(report.get("checks_passed", false)) and write_ok else 1)


func _read_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--input-dir="):
			input_dir = argument.trim_prefix("--input-dir=")
		elif argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
		elif argument.begins_with("--baseline-run-id="):
			expected_run_id = argument.trim_prefix("--baseline-run-id=")
		elif argument.begins_with("--commit-sha="):
			expected_commit_sha = argument.trim_prefix("--commit-sha=")
	if input_dir == "":
		input_dir = "res://tmp/update3_baseline/manual/trials"
	if output_dir == "":
		output_dir = "res://tmp/update3_baseline/manual"


static func load_reports(directory_path: String) -> Array[Dictionary]:
	var reports: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(directory_path):
		return reports
	var filenames := DirAccess.get_files_at(directory_path)
	filenames.sort()
	for filename in filenames:
		if not str(filename).ends_with(".json"):
			continue
		var path := directory_path.path_join(str(filename))
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
			reports.append({"_load_error": "JSON parse failed", "_source_path": path})
			continue
		var report: Dictionary = parser.data
		report["_source_path"] = path
		reports.append(report)
	return reports


static func summarize(reports: Array, run_id: String, commit_sha: String) -> Dictionary:
	var validation := validate_reports(reports, run_id, commit_sha)
	var aggregates := aggregate_reports(reports)
	var review := build_review(aggregates)
	return {
		"schema_version": Spec.SCHEMA_VERSION,
		"tool": "Update3BaselineSummary",
		"evidence_kind": Spec.SUMMARY_EVIDENCE_KIND,
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"run_id": run_id,
		"commit_sha": commit_sha,
		"fixture_version": Spec.FIXTURE_VERSION,
		"policy_id": Spec.POLICY_ID,
		"assignment_kind": "forced_automated_proxy",
		"checks_passed": bool(validation.get("ok", false)),
		"validation": validation,
		"aggregates": aggregates,
		"review": review,
		"limitations": [
			"54회 조합은 자동 강제 배정이며 플레이어의 자유 선택률을 측정하지 않는다.",
			"18개 pairwise-balanced fractional assignment를 seed 3개로 반복하므로 front×heart×duo triple interaction은 해석할 수 없다.",
			"DAY 30 단일 전투 proxy이므로 전체 30일 캠페인의 완주율을 뜻하지 않는다.",
			"seed 3개는 반복 위험 신호를 찾기 위한 표본이며 정밀 확률 추정치가 아니다.",
			"원 계획의 15회 전체 회차 proxy를 대체하지 않는다.",
			"duo별 고정 지원 조합이 함께 적용되므로 합동기만의 고립된 인과 효과가 아니다.",
			"각 전선의 실제 도달 가능한 고정 DAY 28 작전 효과가 함께 적용되므로 전선 결과와 작전 효과가 confounded되어 있다.",
			"경로 hard gate는 current_room과 goal_room이 다른 방간 이동 중 12초 정지만 검사하며, 같은 방 내부 이동이나 도착 후 상태 잔류까지 포괄하는 일반 경로 무결성 검사가 아니다."
		]
	}


static func validate_reports(reports: Array, run_id: String, commit_sha: String) -> Dictionary:
	var errors: Array[String] = []
	if run_id == "":
		errors.append("baseline run ID가 비어 있습니다.")
	if commit_sha == "":
		errors.append("commit SHA가 비어 있습니다.")
	if reports.size() != Spec.TRIAL_COUNT:
		errors.append("trial 수가 %d가 아니라 %d입니다." % [Spec.TRIAL_COUNT, reports.size()])

	var by_index: Dictionary = {}
	for report_value in reports:
		if not report_value is Dictionary:
			errors.append("Dictionary가 아닌 trial 항목이 있습니다.")
			continue
		var report: Dictionary = report_value
		if report.has("_load_error"):
			errors.append("trial JSON을 읽지 못했습니다: %s" % str(report.get("_source_path", "unknown")))
			continue
		var trial_index := int(report.get("trial_index", -1))
		if trial_index < 0 or trial_index >= Spec.TRIAL_COUNT:
			errors.append("범위를 벗어난 trial_index입니다: %d" % trial_index)
			continue
		if by_index.has(trial_index):
			errors.append("중복 trial_index입니다: %d" % trial_index)
			continue
		by_index[trial_index] = report

	for trial_index in range(Spec.TRIAL_COUNT):
		if not by_index.has(trial_index):
			errors.append("trial_index %d가 누락되었습니다." % trial_index)
			continue
		_validate_one_report(by_index[trial_index], Spec.trial_for_index(trial_index), run_id, commit_sha, errors)

	_validate_distribution(reports, errors)
	_validate_seed_offset_signatures(reports, errors)
	return {
		"ok": errors.is_empty(),
		"expected_trials": Spec.TRIAL_COUNT,
		"loaded_trials": reports.size(),
		"unique_trial_indices": by_index.size(),
		"hard_gate_error_count": errors.size(),
		"hard_gate_errors": errors
	}


static func _validate_one_report(report: Dictionary, expected: Dictionary, run_id: String, commit_sha: String, errors: Array[String]) -> void:
	var prefix := "trial %02d" % int(expected.get("trial_index", -1))
	_check(int(report.get("schema_version", -1)) == Spec.SCHEMA_VERSION, "%s schema_version 불일치" % prefix, errors)
	_check(str(report.get("tool", "")) == "Update3BaselineTrial", "%s tool 불일치" % prefix, errors)
	_check(str(report.get("evidence_kind", "")) == Spec.TRIAL_EVIDENCE_KIND, "%s evidence_kind 불일치" % prefix, errors)
	_check(str(report.get("fixture_version", "")) == Spec.FIXTURE_VERSION, "%s fixture_version 불일치" % prefix, errors)
	_check(str(report.get("policy_id", "")) == Spec.POLICY_ID, "%s policy_id 불일치" % prefix, errors)
	_check(str(report.get("assignment_kind", "")) == "forced_automated_proxy", "%s 강제 배정 표시 누락" % prefix, errors)
	_check(str(report.get("run_id", "")) == run_id, "%s run ID 불일치" % prefix, errors)
	_check(str(report.get("commit_sha", "")) == commit_sha, "%s commit SHA 불일치" % prefix, errors)
	_check(str(report.get("trial_id", "")) == str(expected.get("trial_id", "")), "%s trial ID 불일치" % prefix, errors)
	_check(str(report.get("row_id", "")) == str(expected.get("row_id", "")), "%s row ID 불일치" % prefix, errors)
	_check(int(report.get("seed", -1)) == int(expected.get("seed", -2)), "%s seed 불일치" % prefix, errors)

	var assignment: Dictionary = report.get("assignment", {})
	_check(str(assignment.get("front_id", "")) == str(expected.get("front_id", "")), "%s front 배정 불일치" % prefix, errors)
	_check(str(assignment.get("heart_id", "")) == str(expected.get("heart_id", "")), "%s heart 배정 불일치" % prefix, errors)
	_check(str(assignment.get("duo_link_id", "")) == str(expected.get("duo_link_id", "")), "%s duo 배정 불일치" % prefix, errors)
	_check(str(assignment.get("operation_id", "")) == str(expected.get("operation_id", "")), "%s DAY 28 작전 배정 불일치" % prefix, errors)
	_check(_string_array(assignment.get("deployed_instance_ids", [])) == _string_array(expected.get("deployed_instance_ids", [])), "%s 5인 배치 불일치" % prefix, errors)
	_check(report.get("initial_offsets", {}) is Dictionary and not report.get("initial_offsets", {}).is_empty(), "%s seed 위치 jitter가 비어 있음" % prefix, errors)

	var configuration: Dictionary = report.get("configuration", {})
	_check(int(configuration.get("day", -1)) == Spec.DAY, "%s DAY 30 불일치" % prefix, errors)
	_check(str(configuration.get("stage_id", "")) == Spec.STAGE_ID, "%s Stage 04 불일치" % prefix, errors)
	_check(int(configuration.get("monster_level", -1)) == Spec.MONSTER_LEVEL, "%s 몬스터 레벨 불일치" % prefix, errors)
	_check(int(configuration.get("monster_bond", -1)) == Spec.MONSTER_BOND, "%s 유대 수치 불일치" % prefix, errors)
	_check(int(configuration.get("heart_initial_charge", -1)) == Spec.HEART_INITIAL_CHARGE, "%s 심장 초기 충전 불일치" % prefix, errors)

	var structural: Dictionary = report.get("validation", {})
	_check(str(structural.get("expected_boss_id", "")) == Spec.expected_boss(str(expected.get("front_id", ""))), "%s 기대 보스 불일치" % prefix, errors)
	_check(int(structural.get("scheduled_boss_count", 0)) == 1, "%s 기대 보스가 정확히 1명이 아님" % prefix, errors)
	_check(_string_array(structural.get("wrong_boss_ids", [])).is_empty(), "%s 다른 전선 보스가 포함됨" % prefix, errors)
	_check(int(structural.get("deployed_count", 0)) == 5, "%s 출전 수가 5가 아님" % prefix, errors)
	_check(bool(structural.get("duo_active_at_start", false)), "%s 합동기가 전투 시작 시 비활성" % prefix, errors)
	_check(str(structural.get("actual_heart_id_at_start", "")) == str(expected.get("heart_id", "")), "%s 실제 심장 ID 불일치" % prefix, errors)
	_check(int(structural.get("heart_charge_at_start", -1)) == Spec.HEART_INITIAL_CHARGE, "%s 시작 심장 charge 불일치" % prefix, errors)
	_check(bool(structural.get("heart_active_succeeded", false)), "%s low_input_v1 심장 액티브 실패" % prefix, errors)
	_check(str(structural.get("expected_operation_id", "")) == str(expected.get("operation_id", "")), "%s 기대 DAY 28 작전 불일치" % prefix, errors)
	_check(str(structural.get("actual_operation_id_at_start", "")) == str(expected.get("operation_id", "")), "%s 실제 DAY 28 작전 불일치" % prefix, errors)
	_check(str(structural.get("expected_operation_modifier_id", "")) != "", "%s DAY 28 작전 modifier ID 누락" % prefix, errors)
	_check(bool(structural.get("operation_modifier_present", false)), "%s DAY 28 작전 modifier 활성 증거 누락" % prefix, errors)
	_check(bool(structural.get("operation_modifier_matches_catalog", false)), "%s DAY 28 작전 modifier catalog 불일치" % prefix, errors)
	_check(bool(structural.get("operation_schedule_effect_expected", false)), "%s DAY 28 작전이 schedule을 바꾸지 않음" % prefix, errors)
	_check(bool(structural.get("operation_schedule_effect_applied", false)), "%s DAY 28 작전의 실제 schedule 반영 증거 누락" % prefix, errors)
	var expected_operation_schedule := str(structural.get("expected_operation_schedule_signature", ""))
	var actual_operation_schedule := str(structural.get("actual_operation_schedule_signature", ""))
	var without_operation_schedule := str(structural.get("without_operation_schedule_signature", ""))
	_check(expected_operation_schedule != "" and actual_operation_schedule == expected_operation_schedule, "%s 실제 schedule이 작전 적용 예상과 다름" % prefix, errors)
	_check(without_operation_schedule != "" and without_operation_schedule != expected_operation_schedule, "%s 작전 미적용/적용 schedule 증거가 구분되지 않음" % prefix, errors)
	_check(int(structural.get("inter_room_path_stall_count", -1)) == 0, "%s 방간 이동 경로 정지 감지" % prefix, errors)
	_check(not bool(report.get("hard_failure", true)), "%s trial 자체 hard failure" % prefix, errors)
	_check(_string_array(report.get("errors", [])).is_empty(), "%s trial 오류 목록이 비어 있지 않음" % prefix, errors)

	var outcome: Dictionary = report.get("outcome", {})
	_check(str(outcome.get("result", "")) in ["win", "loss"], "%s 승패 결과가 없거나 timeout" % prefix, errors)
	_check(not bool(outcome.get("timed_out", true)), "%s timeout" % prefix, errors)
	_check(bool(outcome.get("heart_active_succeeded", false)) and bool(outcome.get("heart_active_used", false)), "%s 심장 액티브 성공 증거 누락" % prefix, errors)


static func _validate_distribution(reports: Array, errors: Array[String]) -> void:
	var front_counts: Dictionary = {}
	var heart_counts: Dictionary = {}
	var duo_counts: Dictionary = {}
	var seed_counts: Dictionary = {}
	var front_heart_counts: Dictionary = {}
	var front_duo_counts: Dictionary = {}
	var heart_duo_counts: Dictionary = {}
	for report_value in reports:
		if not report_value is Dictionary or report_value.has("_load_error"):
			continue
		var assignment: Dictionary = report_value.get("assignment", {})
		var front_id := str(assignment.get("front_id", ""))
		var heart_id := str(assignment.get("heart_id", ""))
		var duo_id := str(assignment.get("duo_link_id", ""))
		var trial_seed := int(report_value.get("seed", -1))
		_increment(front_counts, front_id)
		_increment(heart_counts, heart_id)
		_increment(duo_counts, duo_id)
		_increment(seed_counts, str(trial_seed))
		_increment(front_heart_counts, "%s|%s" % [front_id, heart_id])
		_increment(front_duo_counts, "%s|%s" % [front_id, duo_id])
		_increment(heart_duo_counts, "%s|%s" % [heart_id, duo_id])
	for front_id in Spec.FRONT_IDS:
		_check(int(front_counts.get(front_id, 0)) == 18, "front %s 배정 수가 18이 아님" % front_id, errors)
	for heart_id in Spec.HEART_IDS:
		_check(int(heart_counts.get(heart_id, 0)) == 18, "heart %s 배정 수가 18이 아님" % heart_id, errors)
	for duo_id in Spec.DUO_LINK_IDS:
		_check(int(duo_counts.get(duo_id, 0)) == 9, "duo %s 배정 수가 9가 아님" % duo_id, errors)
	for trial_seed in Spec.SEEDS:
		_check(int(seed_counts.get(str(trial_seed), 0)) == 18, "seed %d 배정 수가 18이 아님" % trial_seed, errors)
	for front_id in Spec.FRONT_IDS:
		for heart_id in Spec.HEART_IDS:
			_check(int(front_heart_counts.get("%s|%s" % [front_id, heart_id], 0)) == 6, "front×heart 분포 불일치: %s/%s" % [front_id, heart_id], errors)
		for duo_id in Spec.DUO_LINK_IDS:
			_check(int(front_duo_counts.get("%s|%s" % [front_id, duo_id], 0)) == 3, "front×duo 분포 불일치: %s/%s" % [front_id, duo_id], errors)
	for heart_id in Spec.HEART_IDS:
		for duo_id in Spec.DUO_LINK_IDS:
			_check(int(heart_duo_counts.get("%s|%s" % [heart_id, duo_id], 0)) == 3, "heart×duo 분포 불일치: %s/%s" % [heart_id, duo_id], errors)


static func _validate_seed_offset_signatures(reports: Array, errors: Array[String]) -> void:
	var signatures_by_row: Dictionary = {}
	for report_value in reports:
		if not report_value is Dictionary or report_value.has("_load_error"):
			continue
		var trial_index := int(report_value.get("trial_index", -1))
		var expected := Spec.trial_for_index(trial_index)
		if expected.is_empty():
			continue
		var offsets = report_value.get("initial_offsets", {})
		if not offsets is Dictionary or offsets.is_empty():
			continue
		var row_id := str(expected.get("row_id", ""))
		var signatures: Dictionary = signatures_by_row.get(row_id, {})
		signatures[_offset_signature(offsets)] = true
		signatures_by_row[row_id] = signatures
	for assignment_value in Spec.base_assignments():
		var row_id := str(assignment_value.get("row_id", ""))
		_check(int(signatures_by_row.get(row_id, {}).size()) == Spec.SEEDS.size(), "%s의 seed 3개 위치 jitter 서명이 서로 다르지 않음" % row_id, errors)


static func _offset_signature(offsets: Dictionary) -> String:
	var keys := offsets.keys()
	keys.sort()
	var parts: Array[String] = []
	for key_value in keys:
		var key := str(key_value)
		parts.append("%s=%s" % [key, JSON.stringify(offsets.get(key_value))])
	return "|".join(parts)


static func aggregate_reports(reports: Array) -> Dictionary:
	return {
		"trial_count": reports.size(),
		"overall": _overall_summary(reports),
		"fronts": _dimension_rows(reports, "front_id", Spec.FRONT_IDS),
		"hearts": _dimension_rows(reports, "heart_id", Spec.HEART_IDS),
		"duo_links": _dimension_rows(reports, "duo_link_id", Spec.DUO_LINK_IDS),
		"contribution": _contribution_summary(reports)
	}


static func _overall_summary(reports: Array) -> Dictionary:
	var completed := 0
	var wins := 0
	var losses := 0
	var winning_time_minimum := INF
	var winning_time_maximum := 0.0
	var winning_time_out_of_range := 0
	var heart_chamber_disables := 0
	var duo_uses := 0
	var time_minimum := float(Spec.REVIEW_THRESHOLDS.winning_combat_time_min_seconds)
	var time_maximum := float(Spec.REVIEW_THRESHOLDS.winning_combat_time_max_seconds)
	for report_value in reports:
		if not report_value is Dictionary:
			continue
		var outcome: Dictionary = report_value.get("outcome", {})
		var result := str(outcome.get("result", ""))
		if result not in ["win", "loss"]:
			continue
		completed += 1
		if result == "win":
			wins += 1
			var combat_time := float(outcome.get("combat_time_seconds", 0.0))
			winning_time_minimum = minf(winning_time_minimum, combat_time)
			winning_time_maximum = maxf(winning_time_maximum, combat_time)
			if combat_time < time_minimum or combat_time > time_maximum:
				winning_time_out_of_range += 1
		else:
			losses += 1
		if bool(outcome.get("heart_chamber_disabled", false)):
			heart_chamber_disables += 1
		if bool(outcome.get("duo_used", false)):
			duo_uses += 1
	return {
		"completed": completed,
		"wins": wins,
		"losses": losses,
		"winning_time_min_seconds": 0.0 if winning_time_minimum == INF else snappedf(winning_time_minimum, 0.1),
		"winning_time_max_seconds": snappedf(winning_time_maximum, 0.1),
		"winning_time_out_of_range_count": winning_time_out_of_range,
		"heart_chamber_disable_count": heart_chamber_disables,
		"heart_chamber_disable_rate": _rounded_ratio(heart_chamber_disables, completed),
		"duo_use_count": duo_uses,
		"duo_average_activation_rate": _rounded_ratio(duo_uses, completed)
	}


static func _dimension_rows(reports: Array, assignment_key: String, ids: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for id_value in ids:
		var target_id := str(id_value)
		var trials := 0
		var wins := 0
		var losses := 0
		var winning_time_total := 0.0
		var winning_time_samples := 0
		var duo_uses := 0
		for report_value in reports:
			if not report_value is Dictionary:
				continue
			var assignment: Dictionary = report_value.get("assignment", {})
			if str(assignment.get(assignment_key, "")) != target_id:
				continue
			trials += 1
			var outcome: Dictionary = report_value.get("outcome", {})
			var result := str(outcome.get("result", ""))
			if result == "win":
				wins += 1
				winning_time_total += float(outcome.get("combat_time_seconds", 0.0))
				winning_time_samples += 1
			elif result == "loss":
				losses += 1
			if bool(outcome.get("duo_used", false)):
				duo_uses += 1
		rows.append({
			"id": target_id,
			"trials": trials,
			"wins": wins,
			"losses": losses,
			"win_rate": _rounded_ratio(wins, trials),
			"winning_time_samples": winning_time_samples,
			"mean_winning_time_seconds": snappedf(winning_time_total / float(maxi(1, winning_time_samples)), 0.1),
			"duo_uses": duo_uses,
			"duo_activation_rate": _rounded_ratio(duo_uses, trials)
		})
	return rows


static func _contribution_summary(reports: Array) -> Dictionary:
	var individual_totals: Dictionary = {}
	var individual_samples: Dictionary = {}
	var pair_totals: Dictionary = {}
	var pair_samples: Dictionary = {}
	var zero_total_trials := 0
	for report_value in reports:
		if not report_value is Dictionary:
			continue
		var assignment: Dictionary = report_value.get("assignment", {})
		var outcome: Dictionary = report_value.get("outcome", {})
		var contributions: Dictionary = outcome.get("contribution_by_species", {})
		var total := 0.0
		for contribution_value in contributions.values():
			total += maxf(0.0, float(contribution_value))
		if total <= 0.0:
			zero_total_trials += 1
		var deployed_species: Array[String] = []
		for instance_id_value in assignment.get("deployed_instance_ids", []):
			var species_id := Spec.species_for_instance(str(instance_id_value))
			if species_id != "" and not deployed_species.has(species_id):
				deployed_species.append(species_id)
		for species_id in deployed_species:
			individual_totals[species_id] = float(individual_totals.get(species_id, 0.0)) + (maxf(0.0, float(contributions.get(species_id, 0.0))) / total if total > 0.0 else 0.0)
			individual_samples[species_id] = int(individual_samples.get(species_id, 0)) + 1
		var duo_id := str(assignment.get("duo_link_id", ""))
		var pair_ratio := 0.0
		if total > 0.0:
			for instance_id in Spec.duo_members(duo_id):
				pair_ratio += maxf(0.0, float(contributions.get(Spec.species_for_instance(instance_id), 0.0))) / total
		pair_totals[duo_id] = float(pair_totals.get(duo_id, 0.0)) + pair_ratio
		pair_samples[duo_id] = int(pair_samples.get(duo_id, 0)) + 1

	var individual_rows: Array[Dictionary] = []
	var species_ids := individual_totals.keys()
	species_ids.sort()
	var maximum_average := 0.0
	var maximum_species_id := ""
	for species_id_value in species_ids:
		var species_id := str(species_id_value)
		var average := float(individual_totals.get(species_id, 0.0)) / float(maxi(1, int(individual_samples.get(species_id, 0))))
		if average > maximum_average:
			maximum_average = average
			maximum_species_id = species_id
		individual_rows.append({"species_id": species_id, "samples": int(individual_samples.get(species_id, 0)), "average_ratio": snappedf(average, 0.001)})

	var pair_rows: Array[Dictionary] = []
	for duo_id_value in Spec.DUO_LINK_IDS:
		var duo_id := str(duo_id_value)
		var samples := int(pair_samples.get(duo_id, 0))
		var average := float(pair_totals.get(duo_id, 0.0)) / float(maxi(1, samples))
		pair_rows.append({"duo_link_id": duo_id, "samples": samples, "average_pair_ratio": snappedf(average, 0.001)})
	return {
		"zero_total_trials": zero_total_trials,
		"individuals": individual_rows,
		"maximum_individual_average_ratio": snappedf(maximum_average, 0.001),
		"maximum_individual_species_id": maximum_species_id,
		"duo_pairs": pair_rows
	}


static func build_review(aggregates: Dictionary) -> Dictionary:
	var checks: Array[Dictionary] = []
	var overall: Dictionary = aggregates.get("overall", {})
	var winning_time_minimum := float(Spec.REVIEW_THRESHOLDS.winning_combat_time_min_seconds)
	var winning_time_maximum := float(Spec.REVIEW_THRESHOLDS.winning_combat_time_max_seconds)
	if int(overall.get("wins", 0)) <= 0:
		checks.append(_review_check("winning_combat_time_range", "INSUFFICIENT", 0, {"minimum": winning_time_minimum, "maximum": winning_time_maximum}, "승리 전투 시간 표본이 없습니다."))
	else:
		var time_outliers := int(overall.get("winning_time_out_of_range_count", 0))
		checks.append(_review_check(
			"winning_combat_time_range",
			"PASS" if time_outliers == 0 else "REVIEW",
			{"minimum": overall.get("winning_time_min_seconds", 0.0), "maximum": overall.get("winning_time_max_seconds", 0.0), "out_of_range": time_outliers},
			{"minimum": winning_time_minimum, "maximum": winning_time_maximum},
			"승리 전투 시간 %.1f~%.1f초, 범위 밖 %d건 (기준 %.1f~%.1f초)" % [float(overall.get("winning_time_min_seconds", 0.0)), float(overall.get("winning_time_max_seconds", 0.0)), time_outliers, winning_time_minimum, winning_time_maximum]
		))
	checks.append(_range_check(
		"heart_chamber_disable_rate",
		float(overall.get("heart_chamber_disable_rate", 0.0)),
		float(Spec.REVIEW_THRESHOLDS.heart_chamber_disable_rate_min),
		float(Spec.REVIEW_THRESHOLDS.heart_chamber_disable_rate_max),
		int(overall.get("completed", 0)),
		"심장실 무력화 발생률"
	))
	checks.append(_range_check(
		"duo_average_activation_rate",
		float(overall.get("duo_average_activation_rate", 0.0)),
		float(Spec.REVIEW_THRESHOLDS.duo_average_activation_rate_min),
		float(Spec.REVIEW_THRESHOLDS.duo_average_activation_rate_max),
		int(overall.get("completed", 0)),
		"합동기 평균 발동률"
	))
	checks.append(_gap_check("front_win_rate_gap", aggregates.get("fronts", []), float(Spec.REVIEW_THRESHOLDS.front_win_rate_gap)))
	checks.append(_gap_check("heart_win_rate_gap", aggregates.get("hearts", []), float(Spec.REVIEW_THRESHOLDS.heart_win_rate_gap)))
	checks.append(_gap_check("duo_win_rate_gap", aggregates.get("duo_links", []), float(Spec.REVIEW_THRESHOLDS.duo_win_rate_gap)))
	checks.append(_winning_time_check("front_winning_time_spread", aggregates.get("fronts", [])))
	checks.append(_winning_time_check("heart_winning_time_spread", aggregates.get("hearts", [])))
	checks.append(_winning_time_check("duo_winning_time_spread", aggregates.get("duo_links", [])))
	for row_value in aggregates.get("duo_links", []):
		var row: Dictionary = row_value
		var rate := float(row.get("duo_activation_rate", 0.0))
		var threshold := float(Spec.REVIEW_THRESHOLDS.duo_activation_rate_min)
		checks.append(_review_check(
			"duo_activation_%s" % str(row.get("id", "")),
			"PASS" if rate + 0.0001 >= threshold else "REVIEW",
			rate,
			threshold,
			"%s 자동 발동률 %.1f%% (기준 %.1f%% 이상)" % [str(row.get("id", "")), rate * 100.0, threshold * 100.0]
		))
	var contribution: Dictionary = aggregates.get("contribution", {})
	var maximum := float(contribution.get("maximum_individual_average_ratio", 0.0))
	var maximum_threshold := float(Spec.REVIEW_THRESHOLDS.individual_average_contribution_max)
	checks.append(_review_check(
		"maximum_individual_average_contribution",
		"PASS" if maximum <= maximum_threshold + 0.0001 else "REVIEW",
		maximum,
		maximum_threshold,
		"최대 평균 개인 기여율 %.1f%% (%s, 기준 %.1f%% 이하)" % [maximum * 100.0, str(contribution.get("maximum_individual_species_id", "")), maximum_threshold * 100.0]
	))
	for pair_value in contribution.get("duo_pairs", []):
		var pair: Dictionary = pair_value
		var ratio := float(pair.get("average_pair_ratio", 0.0))
		var pair_threshold := float(Spec.REVIEW_THRESHOLDS.duo_pair_average_contribution_review)
		checks.append(_review_check(
			"duo_pair_contribution_%s" % str(pair.get("duo_link_id", "")),
			"PASS" if ratio <= pair_threshold + 0.0001 else "REVIEW",
			ratio,
			pair_threshold,
			"%s 두 멤버 평균 기여율 %.1f%% (%.1f%% 초과 시 검토)" % [str(pair.get("duo_link_id", "")), ratio * 100.0, pair_threshold * 100.0]
		))
	if int(contribution.get("zero_total_trials", 0)) > 0:
		checks.append(_review_check("zero_contribution_trials", "INSUFFICIENT", int(contribution.get("zero_total_trials", 0)), 0, "기여도 합계가 0인 trial이 있습니다."))

	var flags: Array[String] = []
	var insufficient: Array[String] = []
	for check_value in checks:
		var check: Dictionary = check_value
		if str(check.get("status", "")) == "REVIEW":
			flags.append(str(check.get("message", "")))
		elif str(check.get("status", "")) == "INSUFFICIENT":
			insufficient.append(str(check.get("message", "")))
	return {
		"status": "REVIEW" if not flags.is_empty() else ("INSUFFICIENT" if not insufficient.is_empty() else "PASS"),
		"thresholds": Spec.REVIEW_THRESHOLDS.duplicate(true),
		"checks": checks,
		"flags": flags,
		"insufficient_signals": insufficient
	}


static func _gap_check(check_id: String, rows: Array, threshold: float) -> Dictionary:
	if rows.is_empty():
		return _review_check(check_id, "INSUFFICIENT", 0.0, threshold, "%s 계산 표본이 없습니다." % check_id)
	var minimum := 1.0
	var maximum := 0.0
	for row_value in rows:
		var rate := float(row_value.get("win_rate", 0.0))
		minimum = minf(minimum, rate)
		maximum = maxf(maximum, rate)
	var gap := maximum - minimum
	return _review_check(check_id, "PASS" if gap <= threshold + 0.0001 else "REVIEW", snappedf(gap, 0.001), threshold, "%s %.1f%%p (기준 %.1f%%p 이하)" % [check_id, gap * 100.0, threshold * 100.0])


static func _winning_time_check(check_id: String, rows: Array) -> Dictionary:
	var required := int(Spec.REVIEW_THRESHOLDS.winning_time_min_samples_per_group)
	var minimum := INF
	var maximum := 0.0
	for row_value in rows:
		if int(row_value.get("winning_time_samples", 0)) < required:
			return _review_check(check_id, "INSUFFICIENT", int(row_value.get("winning_time_samples", 0)), required, "%s: 모든 그룹에 승리 표본 %d개 이상이 필요합니다." % [check_id, required])
		var value := float(row_value.get("mean_winning_time_seconds", 0.0))
		minimum = minf(minimum, value)
		maximum = maxf(maximum, value)
	if minimum <= 0.0 or minimum == INF:
		return _review_check(check_id, "INSUFFICIENT", 0.0, required, "%s: 유효한 승리 시간이 없습니다." % check_id)
	var spread := (maximum - minimum) / minimum
	var threshold := float(Spec.REVIEW_THRESHOLDS.winning_clear_time_spread)
	return _review_check(check_id, "PASS" if spread <= threshold + 0.0001 else "REVIEW", snappedf(spread, 0.001), threshold, "%s %.1f%% (기준 %.1f%% 이하)" % [check_id, spread * 100.0, threshold * 100.0])


static func _review_check(check_id: String, status: String, value, threshold, message: String) -> Dictionary:
	return {"id": check_id, "status": status, "value": value, "threshold": threshold, "message": message}


static func _range_check(check_id: String, value: float, minimum: float, maximum: float, sample_count: int, label: String) -> Dictionary:
	if sample_count <= 0:
		return _review_check(check_id, "INSUFFICIENT", value, {"minimum": minimum, "maximum": maximum}, "%s 표본이 없습니다." % label)
	var passed := value + 0.0001 >= minimum and value <= maximum + 0.0001
	return _review_check(check_id, "PASS" if passed else "REVIEW", snappedf(value, 0.001), {"minimum": minimum, "maximum": maximum}, "%s %.1f%% (기준 %.1f~%.1f%%)" % [label, value * 100.0, minimum * 100.0, maximum * 100.0])


static func build_markdown(report: Dictionary) -> String:
	var validation: Dictionary = report.get("validation", {})
	var review: Dictionary = report.get("review", {})
	var lines: Array[String] = [
		"# Update 3 DAY 30 자동 강제 배정 baseline",
		"",
		"- Run ID: `%s`" % str(report.get("run_id", "")),
		"- Commit SHA: `%s`" % str(report.get("commit_sha", "")),
		"- 구조 검증: **%s**" % ("PASS" if bool(report.get("checks_passed", false)) else "FAIL"),
		"- 밸런스 검토 상태: **%s**" % str(review.get("status", "")),
		"- Trial: %d / %d" % [int(validation.get("loaded_trials", 0)), Spec.TRIAL_COUNT],
		"",
		"> 이 자료는 조합을 강제로 배정한 자동 DAY 30 proxy다. 인간의 자유 선택률이나 전체 캠페인 완주율로 해석하지 않는다.",
		"",
		"## 구조 hard gate",
		""
	]
	if bool(validation.get("ok", false)):
		lines.append("- 54회 매트릭스와 실행 계약이 모두 일치한다.")
	else:
		for error_value in validation.get("hard_gate_errors", []):
			lines.append("- FAIL: %s" % str(error_value))
	lines.append_array(["", "## 밸런스 검토 신호", ""])
	if review.get("flags", []).is_empty():
		lines.append("- 임계치를 넘은 검토 신호가 없다.")
	else:
		for flag_value in review.get("flags", []):
			lines.append("- %s" % str(flag_value))
	for signal_value in review.get("insufficient_signals", []):
		lines.append("- 표본 부족: %s" % str(signal_value))
	lines.append_array(["", "## 해석 제한", ""])
	for limitation_value in report.get("limitations", []):
		lines.append("- %s" % str(limitation_value))
	lines.append("")
	return "\n".join(lines)


static func _increment(counts: Dictionary, key: String) -> void:
	counts[key] = int(counts.get(key, 0)) + 1


static func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


static func _string_array(values) -> Array[String]:
	var result: Array[String] = []
	if not values is Array:
		return result
	for value in values:
		result.append(str(value))
	return result


static func _rounded_ratio(numerator: int, denominator: int) -> float:
	return snappedf(float(numerator) / float(maxi(1, denominator)), 0.001)


func _global_path(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("res://") or path.begins_with("user://") else path


func _write_text(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Update3 baseline summary를 저장하지 못했습니다: %s" % path)
		return false
	file.store_string(content)
	return true
