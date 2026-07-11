extends Node

const SummaryScript = preload("res://scripts/systems/tutorial/FirstPlayObservationSummary.gd")

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var fixture_root := ProjectSettings.globalize_path("res://tmp/first_play_observation_summary_fixture")
	var fixture_a := fixture_root.path_join("a")
	var fixture_b := fixture_root.path_join("b")
	DirAccess.make_dir_recursive_absolute(fixture_a)
	DirAccess.make_dir_recursive_absolute(fixture_b)
	var reports := _fixture_reports()
	for report in reports:
		_write_json(fixture_a.path_join(str(report.get("session_id", "")) + ".json"), report)
	_write_json(fixture_b.path_join("session_fixture_a.json"), reports[0])
	_write_text(fixture_b.path_join("session_invalid.json"), "{broken")

	var aggregator = SummaryScript.new()
	var loaded: Dictionary = aggregator.load_reports([fixture_a, fixture_b])
	_expect(Array(loaded.get("reports", [])).size() == 4, "summary loader keeps four unique sessions")
	_expect(Array(loaded.get("duplicate_files", [])).size() == 1, "summary loader removes a mirrored duplicate session")
	_expect(Array(loaded.get("invalid_files", [])).size() == 1, "summary loader isolates a broken JSON file")

	var summary: Dictionary = aggregator.summarize(loaded.get("reports", []))
	var totals: Dictionary = summary.get("summary", {})
	_expect(bool(summary.get("sample_ready", false)), "four sessions are enough for comparison")
	_expect(int(totals.get("session_count", 0)) == 4, "summary counts all sessions")
	_expect(int(totals.get("completed_session_count", 0)) == 3 and int(totals.get("incomplete_session_count", 0)) == 1, "summary separates complete and incomplete sessions")
	_expect(int(totals.get("total_blocked_attempt_count", 0)) == 4, "summary adds blocked attempts across sessions")
	_expect(int(totals.get("total_long_wait_count", 0)) == 2, "summary adds long waits across sessions")

	var directive_step := _row_by(summary.get("steps", []), "step_id", "TUT_050_GLOBAL_DEFEND")
	_expect(float(directive_step.get("median_seconds", 0.0)) == 25.0, "summary calculates the middle directive wait")
	_expect(float(directive_step.get("max_seconds", 0.0)) == 30.0, "summary keeps the longest directive wait")
	_expect(int(directive_step.get("long_wait_session_count", 0)) == 2, "summary counts two long directive waits")
	var slime_blocker := _row_by(summary.get("blockers", []), "step_id", "TUT_030_SELECT_SLIME")
	_expect(int(slime_blocker.get("attempt_count", 0)) == 4, "summary finds the most repeated blocked step")

	var directive_choice := _choice_row(summary.get("choices", []), 1, "global_directive")
	_expect(int(directive_choice.get("session_count", 0)) == 3, "summary counts sessions that made a directive choice")
	_expect(int(directive_choice.get("attempt_count", 0)) == 4 and int(directive_choice.get("change_count", 0)) == 1, "summary adds directive attempts and changes")
	_expect(int(Dictionary(directive_choice.get("first_value_counts", {})).get("defense", 0)) == 2, "summary builds the first-choice distribution")

	var output_dir := ProjectSettings.globalize_path("res://tmp/first_play_observation_summary_test")
	var paths: Dictionary = aggregator.write_summary(summary, output_dir)
	_expect(FileAccess.file_exists(str(paths.get("json", ""))), "summary writes a JSON report")
	_expect(FileAccess.file_exists(str(paths.get("markdown", ""))), "summary writes a Korean Markdown report")
	var markdown := FileAccess.get_file_as_string(str(paths.get("markdown", "")))
	_expect(markdown.contains("# 첫 플레이 여러 세션 비교") and markdown.contains("20초 이상 머문 세션이 2개"), "summary Markdown explains repeated long waits in Korean")

	print("FIRST_PLAY_OBSERVATION_SUMMARY_TEST: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)

func _fixture_reports() -> Array:
	return [
		_report("session_fixture_a", "new", true, 4, 100.0, [
			_step("TUT_030_SELECT_SLIME", "unit_selected", 5.0, false),
			_step("TUT_050_GLOBAL_DEFEND", "global_directive_set", 25.0, true)
		], {"TUT_030_SELECT_SLIME": 1}, [
			_choice(1, "global_directive", "all_out", "defense", 2, 1),
			_choice(2, "facility", "watch_post", "watch_post", 1, 0)
		]),
		_report("session_fixture_b", "new", true, 4, 90.0, [
			_step("TUT_030_SELECT_SLIME", "unit_selected", 8.0, false),
			_step("TUT_050_GLOBAL_DEFEND", "global_directive_set", 30.0, true)
		], {"TUT_030_SELECT_SLIME": 2}, [
			_choice(1, "global_directive", "defense", "defense", 1, 0),
			_choice(2, "facility", "watch_post", "watch_post", 1, 0)
		]),
		_report("session_fixture_c", "quick", false, 1, 35.0, [
			_step("TUT_010_NAME", "name_valid", 2.0, false),
			_step("TUT_030_SELECT_SLIME", "unit_selected", 12.0, false)
		], {"TUT_030_SELECT_SLIME": 1}, []),
		_report("session_fixture_d", "new", true, 4, 70.0, [
			_step("TUT_030_SELECT_SLIME", "unit_selected", 7.0, false),
			_step("TUT_050_GLOBAL_DEFEND", "global_directive_set", 10.0, false)
		], {}, [
			_choice(1, "global_directive", "defense", "defense", 1, 0),
			_choice(2, "facility", "barracks", "barracks", 1, 0)
		])
	]

func _report(session_id: String, mode: String, completed: bool, day: int, duration: float, steps: Array, blockers: Dictionary, choices: Array) -> Dictionary:
	var long_waits := 0
	for step in steps:
		if bool(step.get("long_wait", false)):
			long_waits += 1
	var blocked_total := 0
	for count in blockers.values():
		blocked_total += int(count)
	return {
		"schema_version": 1,
		"session_id": session_id,
		"session_mode": mode,
		"session_started_at": "2026-07-11T12:00:00",
		"day": day,
		"completed": completed,
		"duration_seconds": duration,
		"summary": {
			"completed_step_count": steps.size(),
			"blocked_attempt_count": blocked_total,
			"long_wait_count": long_waits,
			"choice_count": choices.size()
		},
		"completed_steps": steps,
		"blocked_attempts_by_step": blockers,
		"choices": choices,
		"events": []
	}

func _step(step_id: String, action_id: String, elapsed: float, long_wait: bool) -> Dictionary:
	return {"step_id": step_id, "action_id": action_id, "elapsed_seconds": elapsed, "long_wait": long_wait, "blocked_attempts": 0, "day": 1}

func _choice(day: int, category: String, first_value: String, latest_value: String, attempts: int, changes: int) -> Dictionary:
	return {"day": day, "category": category, "first_value": first_value, "latest_value": latest_value, "attempts": attempts, "changes": changes}

func _row_by(rows: Array, key: String, value: String) -> Dictionary:
	for row in rows:
		if str(row.get(key, "")) == value:
			return row
	return {}

func _choice_row(rows: Array, day: int, category: String) -> Dictionary:
	for row in rows:
		if int(row.get("day", 0)) == day and str(row.get("category", "")) == category:
			return row
	return {}

func _write_json(path: String, data: Dictionary) -> void:
	_write_text(path, JSON.stringify(data, "\t") + "\n")

func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("fixture write failed: %s" % path)
		failed = true
		return
	file.store_string(content)

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
