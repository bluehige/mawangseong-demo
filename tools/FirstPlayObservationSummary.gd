extends Node

const SummaryScript = preload("res://scripts/systems/tutorial/FirstPlayObservationSummary.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var aggregator = SummaryScript.new()
	var loaded: Dictionary = aggregator.load_reports([
		ProjectSettings.globalize_path("user://first_play_observation"),
		ProjectSettings.globalize_path("res://tmp/first_play_observation")
	])
	var reports: Array = loaded.get("reports", [])
	if reports.is_empty():
		push_error("FIRST_PLAY_OBSERVATION_SUMMARY: 집계할 session_*.json 파일이 없습니다.")
		get_tree().quit(1)
		return
	var summary: Dictionary = aggregator.summarize(reports)
	summary["source"] = {
		"valid_file_count": reports.size(),
		"duplicate_file_count": Array(loaded.get("duplicate_files", [])).size(),
		"invalid_file_count": Array(loaded.get("invalid_files", [])).size()
	}
	var paths := aggregator.write_summary(summary, ProjectSettings.globalize_path("res://tmp/first_play_observation_summary"))
	if paths.is_empty():
		push_error("FIRST_PLAY_OBSERVATION_SUMMARY: 보고서를 저장하지 못했습니다.")
		get_tree().quit(1)
		return
	print("FIRST_PLAY_OBSERVATION_SUMMARY_JSON: %s" % paths.get("json", ""))
	print("FIRST_PLAY_OBSERVATION_SUMMARY_MARKDOWN: %s" % paths.get("markdown", ""))
	print("FIRST_PLAY_OBSERVATION_SUMMARY: PASS")
	get_tree().quit(0)
