extends Node

const PROFILE_IDS = ["balanced", "aggressive", "fortified", "survival", "minimal"]

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var input_dir := ProjectSettings.globalize_path("res://tmp/day1_3_proxy_records")
	var reports := _load_reports(input_dir)
	_expect(reports.size() == PROFILE_IDS.size(), "자동 대리 프로필 5개 로드")
	var rows: Array[Dictionary] = []
	var seen_profiles: Dictionary = {}
	var directive_kinds: Dictionary = {}
	var facility_kinds: Dictionary = {}
	for report_value in reports:
		var report: Dictionary = report_value
		var profile_id := str(report.get("proxy_profile", ""))
		_expect(str(report.get("evidence_kind", "")) == "automated_proxy", "%s 자료가 자동 대리로 표시" % profile_id)
		_expect(PROFILE_IDS.has(profile_id) and not seen_profiles.has(profile_id), "%s 프로필 식별" % profile_id)
		seen_profiles[profile_id] = true
		var row := _summarize_profile(report)
		rows.append(row)
		_expect(bool(row.get("completed", false)) and not bool(report.get("summary", {}).get("failed", true)), "%s DAY 1~3 결과 기록 완료" % profile_id)
		_expect(float(row.get("total_combat_time", 0.0)) > 0.0, "%s 전투 시간 기록" % profile_id)
		for directive in row.get("directives", []):
			directive_kinds[str(directive)] = true
		facility_kinds[str(row.get("planned_facility", "none"))] = true
	_expect(seen_profiles.size() == PROFILE_IDS.size(), "예정된 프로필이 빠짐없이 존재")
	_expect(directive_kinds.size() >= 3, "전체 지침 세 종류 비교")
	_expect(facility_kinds.size() >= 4, "시설 계획 네 종류 비교")

	rows.sort_custom(func(a, b): return PROFILE_IDS.find(str(a.get("profile_id", ""))) < PROFILE_IDS.find(str(b.get("profile_id", ""))))
	var all_completed := rows.size() == PROFILE_IDS.size() and rows.all(func(row): return bool(row.get("completed", false)))
	var summary := {
		"tool": "DayOneToThreeProxySummary",
		"evidence_kind": "automated_proxy_comparison",
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"profile_count": rows.size(),
		"all_completed": all_completed,
		"checks_passed": not failed,
		"profiles": rows,
		"signals": _build_signals(rows),
		"limitations": [
			"실제 사람이 아닌 규칙 기반 자동 플레이 결과입니다.",
			"조작 이해도, 화면을 읽는 난이도, 재미와 피로도는 판단할 수 없습니다.",
			"전투 조합의 상대적 위험과 보상 차이를 찾는 보조 자료로만 사용합니다."
		]
	}
	var output_dir := ProjectSettings.globalize_path("res://tmp/day1_3_proxy_summary")
	DirAccess.make_dir_recursive_absolute(output_dir)
	_write_text(output_dir.path_join("latest.json"), JSON.stringify(summary, "\t") + "\n")
	_write_text(output_dir.path_join("latest.md"), _build_markdown(summary))
	print("DAY1_3_PROXY_SUMMARY_JSON: %s" % output_dir.path_join("latest.json"))
	print("DAY1_3_PROXY_SUMMARY_MARKDOWN: %s" % output_dir.path_join("latest.md"))
	print("DAY1_3_PROXY_SUMMARY: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)

func _load_reports(directory_path: String) -> Array[Dictionary]:
	var reports: Array[Dictionary] = []
	for profile_id in PROFILE_IDS:
		var path := directory_path.path_join("proxy_%s.json" % profile_id)
		if not FileAccess.file_exists(path):
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
			push_error("자동 대리 기록을 읽지 못했습니다: %s" % path)
			failed = true
			continue
		reports.append(parser.data)
	return reports

func _summarize_profile(report: Dictionary) -> Dictionary:
	var total_combat_time := 0.0
	var minimum_monster_hp_ratio := 1.0
	var minimum_throne_hp := 999999
	var throne_max_hp := 0
	var total_skill_uses := 0
	var thief_reached_days := 0
	var thief_stole_days := 0
	var directives: Array[String] = []
	var facility_totals := {
		"watch_post_bonus_damage": 0,
		"watch_post_slow_applications": 0,
		"barracks_bonus_damage": 0,
		"barracks_damage_reduced": 0,
		"recovery_healing": 0
	}
	var growth_focus_counts: Dictionary = {}
	var days: Array = report.get("days", [])
	var completed := days.size() == 3
	for day_value in days:
		var day: Dictionary = day_value
		if bool(day.get("timed_out", false)) or not str(day.get("result", "")) in ["win", "loss"]:
			completed = false
		total_combat_time += float(day.get("combat_time", 0.0))
		var total_hp := int(day.get("total_monster_hp", 0))
		if total_hp > 0:
			minimum_monster_hp_ratio = min(minimum_monster_hp_ratio, float(day.get("remaining_monster_hp", 0)) / float(total_hp))
		minimum_throne_hp = mini(minimum_throne_hp, int(day.get("throne_hp", 0)))
		throne_max_hp = maxi(throne_max_hp, int(day.get("throne_max_hp", 0)))
		total_skill_uses += int(day.get("skill_uses", 0))
		if bool(day.get("thief_reached_treasure", false)):
			thief_reached_days += 1
		if bool(day.get("thief_stole", false)):
			thief_stole_days += 1
		var directive := str(day.get("directive", ""))
		if directive != "" and not directives.has(directive):
			directives.append(directive)
		var facility: Dictionary = day.get("facility_effects", {})
		for key in facility_totals.keys():
			facility_totals[key] = int(facility_totals[key]) + int(facility.get(key, 0))
		var growth_choice: Dictionary = day.get("growth_choice", {})
		var monster_id := str(growth_choice.get("monster_id", ""))
		if monster_id != "":
			growth_focus_counts[monster_id] = int(growth_focus_counts.get(monster_id, 0)) + 1
	if minimum_throne_hp == 999999:
		minimum_throne_hp = 0
	return {
		"profile_id": str(report.get("proxy_profile", "")),
		"profile_label": str(report.get("proxy_profile_label", "")),
		"seed": int(report.get("seed", 0)),
		"days_recorded": days.size(),
		"completed": completed,
		"victory": bool(report.get("summary", {}).get("victory", false)),
		"last_result": str(days[-1].get("result", "")) if not days.is_empty() else "",
		"total_combat_time": snappedf(total_combat_time, 0.1),
		"minimum_monster_hp_ratio": snappedf(minimum_monster_hp_ratio, 0.001),
		"minimum_throne_hp": minimum_throne_hp,
		"throne_max_hp": throne_max_hp,
		"total_skill_uses": total_skill_uses,
		"thief_reached_days": thief_reached_days,
		"thief_stole_days": thief_stole_days,
		"directives": directives,
		"planned_facility": _planned_facility(str(report.get("proxy_profile", ""))),
		"facility_totals": facility_totals,
		"growth_focus_counts": growth_focus_counts
	}

func _build_signals(rows: Array[Dictionary]) -> Array[String]:
	var signals: Array[String] = []
	if rows.is_empty():
		return signals
	var winning_rows: Array[Dictionary] = rows.filter(func(row): return bool(row.get("victory", false)))
	var fastest: Dictionary = winning_rows[0] if not winning_rows.is_empty() else rows[0]
	var slowest: Dictionary = winning_rows[0] if not winning_rows.is_empty() else rows[0]
	var safest: Dictionary = rows[0]
	var riskiest: Dictionary = rows[0]
	for row in rows:
		if float(row.get("minimum_monster_hp_ratio", 0.0)) > float(safest.get("minimum_monster_hp_ratio", -1.0)):
			safest = row
		if float(row.get("minimum_monster_hp_ratio", 1.0)) < float(riskiest.get("minimum_monster_hp_ratio", 2.0)):
			riskiest = row
	for row in winning_rows:
		if float(row.get("total_combat_time", 0.0)) < float(fastest.get("total_combat_time", INF)):
			fastest = row
		if float(row.get("total_combat_time", 0.0)) > float(slowest.get("total_combat_time", -1.0)):
			slowest = row
	signals.append("승리 조합 중 가장 빠른 조합은 %s %.1f초, 가장 느린 조합은 %s %.1f초입니다." % [fastest.get("profile_label", ""), fastest.get("total_combat_time", 0.0), slowest.get("profile_label", ""), slowest.get("total_combat_time", 0.0)])
	signals.append("최저 체력 기준 가장 안정적인 조합은 %s %.0f%%, 가장 위험한 조합은 %s %.0f%%입니다." % [safest.get("profile_label", ""), float(safest.get("minimum_monster_hp_ratio", 0.0)) * 100.0, riskiest.get("profile_label", ""), float(riskiest.get("minimum_monster_hp_ratio", 0.0)) * 100.0])
	for row in rows:
		if not bool(row.get("victory", false)):
			signals.append("%s은 DAY 3에서 패배해 해당 선택 조합의 위험이 실제 결과로 드러났습니다." % row.get("profile_label", ""))
		if int(row.get("thief_stole_days", 0)) > 0:
			signals.append("%s에서 도둑의 실제 도난이 %d일 발생했습니다." % [row.get("profile_label", ""), row.get("thief_stole_days", 0)])
	return signals

func _build_markdown(report: Dictionary) -> String:
	var lines: Array[String] = [
		"# DAY 1~3 자동 대리 플레이 비교",
		"",
		"- 생성 시각: %s" % report.get("generated_at", ""),
		"- 프로필: %d개" % int(report.get("profile_count", 0)),
		"- 판정: %s" % ("5개 프로필 모두 DAY 1~3 결과 기록 완료" if bool(report.get("all_completed", false)) and bool(report.get("checks_passed", false)) else "실패 항목 있음"),
		"",
		"> 이 자료는 실제 사람의 플레이 기록이 아닙니다. 규칙 기반 자동 조작으로 조합별 전투 결과만 비교합니다.",
		"",
		"| 프로필 | DAY 3 결과 | 총 전투 시간 | 최저 몬스터 HP | 최저 마왕성 HP | 스킬 | 도둑 도달 | 도난 | 시설 |",
		"|---|---|---:|---:|---:|---:|---:|---:|---|"
	]
	for row in report.get("profiles", []):
		lines.append("| %s | %s | %.1f초 | %.0f%% | %d/%d | %d | %d일 | %d일 | %s |" % [
			row.get("profile_label", ""), "승리" if bool(row.get("victory", false)) else "패배", row.get("total_combat_time", 0.0), float(row.get("minimum_monster_hp_ratio", 0.0)) * 100.0,
			row.get("minimum_throne_hp", 0), row.get("throne_max_hp", 0), row.get("total_skill_uses", 0),
			row.get("thief_reached_days", 0), row.get("thief_stole_days", 0), _facility_label(str(row.get("planned_facility", "none")))
		])
	lines.append_array(["", "## 비교 신호", ""])
	for signal_text in report.get("signals", []):
		lines.append("- %s" % signal_text)
	lines.append_array(["", "## 해석 제한", ""])
	for limitation in report.get("limitations", []):
		lines.append("- %s" % limitation)
	lines.append("")
	return "\n".join(lines)

func _planned_facility(profile_id: String) -> String:
	return str({"balanced": "watch_post", "aggressive": "barracks", "fortified": "watch_post", "survival": "recovery", "minimal": "none"}.get(profile_id, "none"))

func _facility_label(facility_id: String) -> String:
	return str({"watch_post": "감시 초소", "barracks": "병영", "recovery": "회복 둥지", "none": "추가 건설 없음"}.get(facility_id, facility_id))

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
