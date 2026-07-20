class_name V20SellabilityGate
extends RefCounted

const SCHEMA_VERSION := 1
const MIN_PARTICIPANTS := 6
const MAX_PARTICIPANTS := 10
const DAY_ONE_THRESHOLD := 0.80
const DECISION_EXPLANATION_THRESHOLD := 0.70
const FAILURE_RETRY_THRESHOLD := 0.70

const STATUS_PENDING := "PENDING"
const STATUS_GO := "GO"
const STATUS_NO_GO := "NO_GO"
const STATUS_INVALID := "INVALID"


static func evaluate(dataset) -> Dictionary:
	var errors: Array[String] = []
	if not (dataset is Dictionary):
		return _invalid(["dataset must be a Dictionary"])
	if int(dataset.get("schema_version", 0)) != SCHEMA_VERSION:
		errors.append("schema_version must be 1")
	var build_sha := str(dataset.get("build_sha", "")).strip_edges()
	if build_sha.length() != 40 or not build_sha.is_valid_hex_number(false):
		errors.append("build_sha must be one full 40-character Git SHA")
	var participants_value = dataset.get("participants")
	if not (participants_value is Array):
		errors.append("participants must be an Array")
		return _invalid(errors)
	var participants: Array = participants_value
	if participants.size() > MAX_PARTICIPANTS:
		errors.append("participant count must not exceed %d" % MAX_PARTICIPANTS)
	var ids: Dictionary = {}
	for index in range(participants.size()):
		var participant = participants[index]
		if not (participant is Dictionary):
			errors.append("participant %d must be a Dictionary" % (index + 1))
			continue
		_validate_participant(participant, index, ids, errors)
	if not errors.is_empty():
		return _invalid(errors)
	var total := participants.size()
	var counts := {
		"first_choice_within_90_seconds": 0,
		"day_one_without_external_help": 0,
		"decision_effect_explained_by_day_three": 0,
		"failure_change_and_retry": 0
	}
	var score_totals := {"fun": 0.0, "understanding": 0.0, "fatigue": 0.0}
	for participant_value in participants:
		var participant: Dictionary = participant_value
		if float(participant.get("first_meaningful_choice_seconds", -1.0)) >= 0.0 and float(participant.get("first_meaningful_choice_seconds", -1.0)) <= 90.0:
			counts["first_choice_within_90_seconds"] += 1
		if bool(participant.get("day_one_completed", false)) and int(participant.get("external_help_count", 0)) == 0:
			counts["day_one_without_external_help"] += 1
		if bool(participant.get("reached_day_three", false)) and bool(participant.get("explained_effect_by_day_three", false)) and str(participant.get("decision_effect_own_words", "")).strip_edges() != "":
			counts["decision_effect_explained_by_day_three"] += 1
		if bool(participant.get("failure_observed", false)) and str(participant.get("post_failure_change_own_words", "")).strip_edges() != "" and bool(participant.get("retried_after_failure", false)):
			counts["failure_change_and_retry"] += 1
		score_totals["fun"] += float(participant.get("fun_score", 0))
		score_totals["understanding"] += float(participant.get("understanding_score", 0))
		score_totals["fatigue"] += float(participant.get("fatigue_score", 0))
	var rates := {}
	for key_value in counts.keys():
		var key := str(key_value)
		rates[key] = float(counts.get(key, 0)) / float(total) if total > 0 else 0.0
	var report := {
		"status": STATUS_PENDING,
		"participant_count": total,
		"required_participants": {"minimum": MIN_PARTICIPANTS, "maximum": MAX_PARTICIPANTS},
		"counts": counts,
		"rates": rates,
		"thresholds": {
			"day_one_without_external_help": DAY_ONE_THRESHOLD,
			"decision_effect_explained_by_day_three": DECISION_EXPLANATION_THRESHOLD,
			"failure_change_and_retry": FAILURE_RETRY_THRESHOLD
		},
		"subjective_means": {
			"fun": score_totals.get("fun", 0.0) / float(total) if total > 0 else 0.0,
			"understanding": score_totals.get("understanding", 0.0) / float(total) if total > 0 else 0.0,
			"fatigue": score_totals.get("fatigue", 0.0) / float(total) if total > 0 else 0.0
		},
		"subjective_scores_affect_gate": false,
		"errors": []
	}
	if total < MIN_PARTICIPANTS:
		report["reason"] = "실제 첫 플레이 참가자 %d~%d명이 필요합니다." % [MIN_PARTICIPANTS, MAX_PARTICIPANTS]
		return report
	var passed := (
		float(rates.get("day_one_without_external_help", 0.0)) >= DAY_ONE_THRESHOLD
		and float(rates.get("decision_effect_explained_by_day_three", 0.0)) >= DECISION_EXPLANATION_THRESHOLD
		and float(rates.get("failure_change_and_retry", 0.0)) >= FAILURE_RETRY_THRESHOLD
	)
	report["status"] = STATUS_GO if passed else STATUS_NO_GO
	report["reason"] = "판매 가능성 세 기준을 모두 충족했습니다." if passed else "판매 가능성 기준 중 하나 이상이 미달했습니다."
	return report


static func _validate_participant(participant: Dictionary, index: int, ids: Dictionary, errors: Array[String]) -> void:
	var prefix := "participant %d" % (index + 1)
	var participant_id := str(participant.get("participant_id", "")).strip_edges()
	if participant_id == "":
		errors.append("%s participant_id is required" % prefix)
	elif ids.has(participant_id):
		errors.append("duplicate participant_id: %s" % participant_id)
	else:
		ids[participant_id] = true
	if not bool(participant.get("consent_confirmed", false)):
		errors.append("%s consent must be confirmed" % prefix)
	if not bool(participant.get("first_play", false)):
		errors.append("%s must be a first-play observation" % prefix)
	if not bool(participant.get("no_prior_mechanics_explanation", false)):
		errors.append("%s received prior mechanics explanation" % prefix)
	var choice_seconds := float(participant.get("first_meaningful_choice_seconds", -1.0))
	if choice_seconds < 0.0:
		errors.append("%s first meaningful choice time is required" % prefix)
	if int(participant.get("external_help_count", -1)) < 0:
		errors.append("%s external_help_count must be zero or greater" % prefix)
	for score_key in ["fun_score", "understanding_score", "fatigue_score"]:
		var score := int(participant.get(score_key, 0))
		if score < 1 or score > 5:
			errors.append("%s %s must be 1 through 5" % [prefix, score_key])


static func _invalid(errors: Array[String]) -> Dictionary:
	return {"status": STATUS_INVALID, "participant_count": 0, "errors": errors}
