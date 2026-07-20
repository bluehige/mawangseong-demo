extends Node

const SellabilityGate = preload("res://scripts/v20/playtest/V20SellabilityGate.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var empty_report := SellabilityGate.evaluate(_dataset([]))
	_expect(str(empty_report.get("status", "")) == SellabilityGate.STATUS_PENDING, "실제 참가자 0명은 PASS가 아니라 PENDING")
	var five: Array = []
	for index in range(5):
		five.append(_participant(index, true, true, true))
	_expect(str(SellabilityGate.evaluate(_dataset(five)).get("status", "")) == SellabilityGate.STATUS_PENDING, "실제 참가자 최소 6명 전에는 PENDING")
	var exact_threshold: Array = []
	for index in range(10):
		exact_threshold.append(_participant(index, index < 8, index < 7, index < 7))
	var go_report := SellabilityGate.evaluate(_dataset(exact_threshold))
	_expect(str(go_report.get("status", "")) == SellabilityGate.STATUS_GO, "80%·70%·70% 정확한 경계는 GO")
	_expect(is_equal_approx(float(go_report.get("rates", {}).get("day_one_without_external_help", 0.0)), 0.8), "DAY 1 무설명 완료율 계산")
	_expect(is_equal_approx(float(go_report.get("rates", {}).get("decision_effect_explained_by_day_three", 0.0)), 0.7), "DAY 3 결정 효과 설명률 계산")
	_expect(is_equal_approx(float(go_report.get("rates", {}).get("failure_change_and_retry", 0.0)), 0.7), "패배 뒤 수정·재도전율 계산")
	var no_go: Array = []
	for index in range(10):
		no_go.append(_participant(index, index < 7, true, true))
	_expect(str(SellabilityGate.evaluate(_dataset(no_go)).get("status", "")) == SellabilityGate.STATUS_NO_GO, "DAY 1 70%면 다른 기준 통과와 무관하게 NO_GO")
	var subjective_low: Array = []
	for index in range(6):
		var row := _participant(index, true, true, true)
		row["fun_score"] = 1
		subjective_low.append(row)
	var subjective_report := SellabilityGate.evaluate(_dataset(subjective_low))
	_expect(str(subjective_report.get("status", "")) == SellabilityGate.STATUS_GO and not bool(subjective_report.get("subjective_scores_affect_gate", true)), "주관 점수는 기록하되 자동 PASS 판정에 사용하지 않음")
	var invalid := _dataset([_participant(0, true, true, true)])
	invalid["participants"][0]["consent_confirmed"] = false
	_expect(str(SellabilityGate.evaluate(invalid).get("status", "")) == SellabilityGate.STATUS_INVALID, "동의 없는 기록은 cohort 판정에서 거부")
	var duplicate: Array = [_participant(0, true, true, true), _participant(0, true, true, true)]
	_expect(str(SellabilityGate.evaluate(_dataset(duplicate)).get("status", "")) == SellabilityGate.STATUS_INVALID, "중복 익명 ID 거부")
	var report_file := FileAccess.open("res://docs/playtest/v20/RESULTS.json", FileAccess.READ)
	var pending_dataset = JSON.parse_string(report_file.get_as_text()) if report_file != null else null
	if report_file != null:
		report_file.close()
	_expect(str(SellabilityGate.evaluate(pending_dataset).get("status", "")) == SellabilityGate.STATUS_PENDING, "저장소 실제 기록은 참가자 조작 없이 PENDING")
	if failed:
		print("V20_SELLABILITY_GATE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_SELLABILITY_GATE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _dataset(participants: Array) -> Dictionary:
	return {"schema_version": 1, "cohort_id": "synthetic-contract-test", "build_sha": "4b687aeea80b487f237e6c153dce8600989ec81b", "participants": participants}


func _participant(index: int, day_one_pass: bool, explanation_pass: bool, retry_pass: bool) -> Dictionary:
	return {
		"participant_id": "S%02d" % (index + 1),
		"consent_confirmed": true,
		"first_play": true,
		"no_prior_mechanics_explanation": true,
		"first_meaningful_choice_seconds": 60.0,
		"external_help_count": 0 if day_one_pass else 1,
		"day_one_completed": day_one_pass,
		"reached_day_three": explanation_pass,
		"explained_effect_by_day_three": explanation_pass,
		"decision_effect_own_words": "시설 위치 때문에 첫 교전이 바뀌었다." if explanation_pass else "",
		"failure_observed": retry_pass,
		"post_failure_change_own_words": "후퇴선에 몬스터를 남기겠다." if retry_pass else "",
		"retried_after_failure": retry_pass,
		"fun_score": 4,
		"understanding_score": 4,
		"fatigue_score": 2
	}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20SellabilityGate] FAIL: %s" % message)
