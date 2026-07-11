extends Node

const PROFILE_IDS = ["balanced", "aggressive", "fortified", "survival", "minimal"]
const TRIAL_SEEDS = [20260711, 20260729, 20260747]

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var input_dir := ProjectSettings.globalize_path("res://tmp/day3_seed_matrix/trials")
	var reports := _load_reports(input_dir)
	_expect(reports.size() == PROFILE_IDS.size() * TRIAL_SEEDS.size(), "DAY 3 다중 시작값 기록 15개 로드")
	var rows: Array[Dictionary] = []
	for profile_id in PROFILE_IDS:
		var profile_reports: Array[Dictionary] = []
		for report_value in reports:
			var report: Dictionary = report_value
			if str(report.get("proxy_profile", "")) == profile_id:
				profile_reports.append(report)
		var row := _summarize_profile(profile_id, profile_reports)
		rows.append(row)
		_expect(int(row.get("trials", 0)) == TRIAL_SEEDS.size(), "%s 시작값 3개 기록" % profile_id)
		_expect(int(row.get("completed", 0)) == TRIAL_SEEDS.size(), "%s DAY 3 결산 3회 완료" % profile_id)
		_expect(int(row.get("unique_offset_sets", 0)) == TRIAL_SEEDS.size(), "%s 시작 위치 변화 3종 확인" % profile_id)
	var review_flags := _build_review_flags(rows)
	var summary := {
		"tool": "DayThreeSeedSummary",
		"evidence_kind": "automated_proxy_seed_comparison",
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"profile_count": rows.size(),
		"trial_count": reports.size(),
		"seeds": TRIAL_SEEDS,
		"checks_passed": not failed,
		"profiles": rows,
		"review_flags": review_flags,
		"limitations": [
			"실제 사람이 아닌 자동 대리 전투입니다.",
			"시작값은 유닛 시작 위치를 최대 가로 12픽셀, 세로 8픽셀 바꿔 첫 교전 순서를 흔듭니다.",
			"3회 표본은 반복 신호를 찾는 1차 검사이며 정밀한 승률 통계가 아닙니다."
		]
	}
	var output_dir := ProjectSettings.globalize_path("res://tmp/day3_seed_matrix")
	DirAccess.make_dir_recursive_absolute(output_dir)
	_write_text(output_dir.path_join("latest.json"), JSON.stringify(summary, "\t") + "\n")
	_write_text(output_dir.path_join("latest.md"), _build_markdown(summary))
	print("DAY3_SEED_SUMMARY_JSON: %s" % output_dir.path_join("latest.json"))
	print("DAY3_SEED_SUMMARY_MARKDOWN: %s" % output_dir.path_join("latest.md"))
	print("DAY3_SEED_SUMMARY: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)

func _load_reports(directory_path: String) -> Array[Dictionary]:
	var reports: Array[Dictionary] = []
	for profile_id in PROFILE_IDS:
		for trial_seed in TRIAL_SEEDS:
			var path := directory_path.path_join("%s_%d.json" % [profile_id, trial_seed])
			if not FileAccess.file_exists(path):
				continue
			var parser := JSON.new()
			if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
				push_error("DAY 3 기록을 읽지 못했습니다: %s" % path)
				failed = true
				continue
			var report: Dictionary = parser.data
			_expect(str(report.get("evidence_kind", "")) == "automated_proxy_seed_trial", "%s %d 자동 대리 자료 표시" % [profile_id, trial_seed])
			_expect(not bool(report.get("failed", true)), "%s %d 기록 자체 검사 통과" % [profile_id, trial_seed])
			reports.append(report)
	return reports

func _summarize_profile(profile_id: String, reports: Array[Dictionary]) -> Dictionary:
	var wins := 0
	var completed := 0
	var thief_reached := 0
	var thief_stole := 0
	var over_180_seconds := 0
	var total_time := 0.0
	var minimum_hp_ratio := 1.0
	var minimum_throne_hp := 999999
	var offset_sets: Dictionary = {}
	for report in reports:
		var trial: Dictionary = report.get("trial", {})
		if not bool(trial.get("timed_out", true)) and str(trial.get("result", "")) in ["win", "loss"]:
			completed += 1
		if str(trial.get("result", "")) == "win":
			wins += 1
		if bool(trial.get("thief_reached_treasure", false)):
			thief_reached += 1
		if bool(trial.get("thief_stole", false)):
			thief_stole += 1
		var combat_time := float(trial.get("combat_time", trial.get("elapsed_seconds", 0.0)))
		total_time += combat_time
		if combat_time > 180.0:
			over_180_seconds += 1
		var total_hp := int(trial.get("total_monster_hp", 0))
		if total_hp > 0:
			minimum_hp_ratio = min(minimum_hp_ratio, float(trial.get("remaining_monster_hp", 0)) / float(total_hp))
		minimum_throne_hp = mini(minimum_throne_hp, int(trial.get("throne_hp", 0)))
		offset_sets[JSON.stringify(trial.get("initial_offsets", {}))] = true
	var trials := reports.size()
	return {
		"profile_id": profile_id,
		"profile_label": _profile_label(profile_id),
		"trials": trials,
		"completed": completed,
		"wins": wins,
		"losses": trials - wins,
		"win_rate": snappedf(float(wins) / float(maxi(1, trials)), 0.001),
		"thief_reached": thief_reached,
		"thief_reached_rate": snappedf(float(thief_reached) / float(maxi(1, trials)), 0.001),
		"thief_stole": thief_stole,
		"thief_stole_rate": snappedf(float(thief_stole) / float(maxi(1, trials)), 0.001),
		"over_180_seconds": over_180_seconds,
		"average_combat_time": snappedf(total_time / float(maxi(1, trials)), 0.1),
		"minimum_monster_hp_ratio": snappedf(minimum_hp_ratio, 0.001),
		"minimum_throne_hp": 0 if minimum_throne_hp == 999999 else minimum_throne_hp,
		"unique_offset_sets": offset_sets.size()
	}

func _build_review_flags(rows: Array[Dictionary]) -> Array[String]:
	var flags: Array[String] = []
	for row in rows:
		if int(row.get("losses", 0)) >= 2:
			flags.append("%s은 3회 중 %d회 패배해 반복 위험 신호가 있습니다." % [row.get("profile_label", ""), row.get("losses", 0)])
		if int(row.get("thief_stole", 0)) >= 2:
			flags.append("%s은 3회 중 %d회 도난을 허용했습니다." % [row.get("profile_label", ""), row.get("thief_stole", 0)])
		if int(row.get("over_180_seconds", 0)) > 0:
			flags.append("%s은 %d회가 180초를 넘어 장기전 위험이 있습니다." % [row.get("profile_label", ""), row.get("over_180_seconds", 0)])
	if flags.is_empty():
		flags.append("3회 중 2회 이상 반복된 패배·도난 신호가 없습니다.")
	return flags

func _build_markdown(report: Dictionary) -> String:
	var lines: Array[String] = [
		"# DAY 3 다중 시작값 자동 대리 비교",
		"",
		"- 생성 시각: %s" % report.get("generated_at", ""),
		"- 실행 수: %d회" % int(report.get("trial_count", 0)),
		"- 시작값: %s" % str(report.get("seeds", [])),
		"- 판정: %s" % ("기록 완성" if bool(report.get("checks_passed", false)) else "기록 오류 있음"),
		"",
		"> 실제 사람이 아닌 자동 대리 전투이며, 시작 위치의 작은 차이에 대한 결과 안정성만 비교합니다.",
		"",
		"| 프로필 | 승리 | 패배 | 승률 | 평균 시간 | 최저 몬스터 HP | 도둑 도달 | 도난 |",
		"|---|---:|---:|---:|---:|---:|---:|---:|"
	]
	for row in report.get("profiles", []):
		lines.append("| %s | %d | %d | %.0f%% | %.1f초 | %.0f%% | %d/3 | %d/3 |" % [
			row.get("profile_label", ""), row.get("wins", 0), row.get("losses", 0), float(row.get("win_rate", 0.0)) * 100.0,
			row.get("average_combat_time", 0.0), float(row.get("minimum_monster_hp_ratio", 0.0)) * 100.0,
			row.get("thief_reached", 0), row.get("thief_stole", 0)
		])
	lines.append_array(["", "## 반복 신호", ""])
	for flag_text in report.get("review_flags", []):
		lines.append("- %s" % flag_text)
	lines.append_array(["", "## 해석 제한", ""])
	for limitation in report.get("limitations", []):
		lines.append("- %s" % limitation)
	lines.append("")
	return "\n".join(lines)

func _profile_label(profile_id: String) -> String:
	return str({"balanced": "균형형", "aggressive": "공격형", "fortified": "방어형", "survival": "생존형", "minimal": "최소 조작형"}.get(profile_id, profile_id))

func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("보고서를 저장하지 못했습니다: %s" % path)
		failed = true
		return
	file.store_string(content)

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
