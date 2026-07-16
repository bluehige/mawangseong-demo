extends RefCounted
class_name FirstPlayObservationSummary

const MIN_USEFUL_SAMPLE_COUNT := 3

func load_reports(directories: Array) -> Dictionary:
	var reports: Array = []
	var seen_session_ids: Dictionary = {}
	var invalid_files: Array[String] = []
	var duplicate_files: Array[String] = []
	for directory_path in directories:
		var path := str(directory_path)
		var directory := DirAccess.open(path)
		if directory == null:
			continue
		var file_names: Array[String] = []
		directory.list_dir_begin()
		var file_name := directory.get_next()
		while file_name != "":
			if not directory.current_is_dir() and file_name.begins_with("session_") and file_name.ends_with(".json"):
				file_names.append(file_name)
			file_name = directory.get_next()
		directory.list_dir_end()
		file_names.sort()
		for candidate in file_names:
			var file_path := path.path_join(candidate)
			var parser := JSON.new()
			if parser.parse(FileAccess.get_file_as_string(file_path)) != OK:
				invalid_files.append(file_path)
				continue
			var parsed = parser.data
			if not parsed is Dictionary:
				invalid_files.append(file_path)
				continue
			var report: Dictionary = parsed
			var session_id := str(report.get("session_id", ""))
			if session_id == "" or int(report.get("schema_version", 0)) != 1:
				invalid_files.append(file_path)
				continue
			if seen_session_ids.has(session_id):
				duplicate_files.append(file_path)
				continue
			seen_session_ids[session_id] = true
			reports.append(report)
	return {
		"reports": reports,
		"invalid_files": invalid_files,
		"duplicate_files": duplicate_files
	}

func summarize(reports: Array) -> Dictionary:
	var session_rows: Array[Dictionary] = []
	var mode_counts: Dictionary = {}
	var completed_count := 0
	var step_accumulators: Dictionary = {}
	var blocker_counts: Dictionary = {}
	var choice_accumulators: Dictionary = {}
	var step_order := 0

	for source in reports:
		if not source is Dictionary:
			continue
		var report: Dictionary = source
		var mode := str(report.get("session_mode", "unknown"))
		_increment(mode_counts, mode)
		if bool(report.get("completed", false)):
			completed_count += 1
		var summary: Dictionary = report.get("summary", {})
		session_rows.append({
			"session_id": str(report.get("session_id", "")),
			"mode": mode,
			"started_at": str(report.get("session_started_at", "")),
			"day": int(report.get("day", 0)),
			"completed": bool(report.get("completed", false)),
			"duration_seconds": float(report.get("duration_seconds", 0.0)),
			"completed_step_count": int(summary.get("completed_step_count", 0)),
			"blocked_attempt_count": int(summary.get("blocked_attempt_count", 0)),
			"long_wait_count": int(summary.get("long_wait_count", 0))
		})
		for step_source in report.get("completed_steps", []):
			if not step_source is Dictionary:
				continue
			var step: Dictionary = step_source
			var step_id := str(step.get("step_id", ""))
			if step_id == "":
				continue
			if not step_accumulators.has(step_id):
				step_accumulators[step_id] = {
					"step_id": step_id,
					"action_id": str(step.get("action_id", "")),
					"first_seen_order": step_order,
					"durations": [],
					"long_wait_session_count": 0
				}
				step_order += 1
			var step_accumulator: Dictionary = step_accumulators[step_id]
			step_accumulator["durations"].append(float(step.get("elapsed_seconds", 0.0)))
			if bool(step.get("long_wait", false)):
				step_accumulator["long_wait_session_count"] = int(step_accumulator.get("long_wait_session_count", 0)) + 1
			step_accumulators[step_id] = step_accumulator
		for step_id_source in Dictionary(report.get("blocked_attempts_by_step", {})).keys():
			var blocked_step_id := str(step_id_source)
			blocker_counts[blocked_step_id] = int(blocker_counts.get(blocked_step_id, 0)) + int(report["blocked_attempts_by_step"][step_id_source])
		for choice_source in report.get("choices", []):
			if not choice_source is Dictionary:
				continue
			var choice: Dictionary = choice_source
			var day := int(choice.get("day", 0))
			var category := str(choice.get("category", ""))
			if category == "":
				continue
			var choice_key := "day_%02d:%s" % [day, category]
			if not choice_accumulators.has(choice_key):
				choice_accumulators[choice_key] = {
					"key": choice_key,
					"day": day,
					"category": category,
					"session_count": 0,
					"attempt_count": 0,
					"change_count": 0,
					"first_value_counts": {},
					"latest_value_counts": {}
				}
			var choice_accumulator: Dictionary = choice_accumulators[choice_key]
			choice_accumulator["session_count"] = int(choice_accumulator.get("session_count", 0)) + 1
			choice_accumulator["attempt_count"] = int(choice_accumulator.get("attempt_count", 0)) + int(choice.get("attempts", 0))
			choice_accumulator["change_count"] = int(choice_accumulator.get("change_count", 0)) + int(choice.get("changes", 0))
			_increment(choice_accumulator["first_value_counts"], str(choice.get("first_value", "")))
			_increment(choice_accumulator["latest_value_counts"], str(choice.get("latest_value", "")))
			choice_accumulators[choice_key] = choice_accumulator

	var step_rows := _finalize_steps(step_accumulators, blocker_counts, reports.size())
	var blocker_rows := _finalize_blockers(blocker_counts)
	var choice_rows := _finalize_choices(choice_accumulators)
	var total_blocked := 0
	for count in blocker_counts.values():
		total_blocked += int(count)
	var total_long_waits := 0
	for row in step_rows:
		total_long_waits += int(row.get("long_wait_session_count", 0))
	return {
		"schema_version": 1,
		"generated_at": Time.get_datetime_string_from_system(),
		"sample_ready": reports.size() >= MIN_USEFUL_SAMPLE_COUNT,
		"minimum_useful_sample_count": MIN_USEFUL_SAMPLE_COUNT,
		"summary": {
			"session_count": reports.size(),
			"completed_session_count": completed_count,
			"incomplete_session_count": reports.size() - completed_count,
			"total_blocked_attempt_count": total_blocked,
			"total_long_wait_count": total_long_waits,
			"choice_group_count": choice_rows.size(),
			"mode_counts": mode_counts
		},
		"sessions": session_rows,
		"steps": step_rows,
		"blockers": blocker_rows,
		"choices": choice_rows,
		"attention_points": _build_attention_points(step_rows, blocker_rows, choice_rows, reports.size())
	}

func write_summary(summary: Dictionary, output_directory: String) -> Dictionary:
	var error := DirAccess.make_dir_recursive_absolute(output_directory)
	if error != OK:
		return {}
	var json_path := output_directory.path_join("latest.json")
	var markdown_path := output_directory.path_join("latest.md")
	if not _write_text(json_path, JSON.stringify(summary, "\t") + "\n"):
		return {}
	if not _write_text(markdown_path, build_markdown(summary)):
		return {}
	return {"json": json_path, "markdown": markdown_path}

func build_markdown(report: Dictionary) -> String:
	var summary: Dictionary = report.get("summary", {})
	var source: Dictionary = report.get("source", {})
	var lines: Array[String] = [
		"# 첫 플레이 여러 세션 비교",
		"",
		"- 생성 시각: %s" % str(report.get("generated_at", "")),
		"- 세션: %d개 (완료 %d / 미완료 %d)" % [int(summary.get("session_count", 0)), int(summary.get("completed_session_count", 0)), int(summary.get("incomplete_session_count", 0))],
		"- 표본 판정: %s" % ("비교 가능" if bool(report.get("sample_ready", false)) else "표본 부족")
	]
	if not source.is_empty():
		lines.append("- 파일 정리: 유효 %d / 중복 제외 %d / 형식 오류 제외 %d" % [int(source.get("valid_file_count", 0)), int(source.get("duplicate_file_count", 0)), int(source.get("invalid_file_count", 0))])
	lines.append("")
	if not bool(report.get("sample_ready", false)):
		lines.append("> 아직 %d개 미만입니다. 아래 수치는 도구 검증용이며 튜토리얼이나 밸런스 변경 근거로 확정하지 않습니다." % int(report.get("minimum_useful_sample_count", MIN_USEFUL_SAMPLE_COUNT)))
		lines.append("")
	lines.append_array(["## 오래 머문 단계", "", "| 단계 | 완료 세션 | 중앙값 | 최대 | 20초 이상 | 차단 |", "|---|---:|---:|---:|---:|---:|"])
	for row in report.get("steps", []):
		lines.append("| %s | %d | %.2f초 | %.2f초 | %d | %d |" % [
			_step_label(str(row.get("step_id", ""))), int(row.get("completion_session_count", 0)),
			float(row.get("median_seconds", 0.0)), float(row.get("max_seconds", 0.0)),
			int(row.get("long_wait_session_count", 0)), int(row.get("blocked_attempt_count", 0))
		])
	if report.get("steps", []).is_empty():
		lines.append("| 기록 없음 | - | - | - | - | - |")
	lines.append_array(["", "## 반복 차단", "", "| 단계 | 차단 횟수 |", "|---|---:|"])
	for row in report.get("blockers", []):
		lines.append("| %s | %d |" % [_step_label(str(row.get("step_id", ""))), int(row.get("attempt_count", 0))])
	if report.get("blockers", []).is_empty():
		lines.append("| 없음 | 0 |")
	lines.append_array(["", "## 첫 선택과 변경", "", "| DAY | 종류 | 참여 세션 | 첫 선택 분포 | 총 시도 | 변경 |", "|---:|---|---:|---|---:|---:|"])
	for row in report.get("choices", []):
		lines.append("| %d | %s | %d | %s | %d | %d |" % [
			int(row.get("day", 0)), _choice_label(str(row.get("category", ""))), int(row.get("session_count", 0)),
			_count_map_text(row.get("first_value_counts", {})), int(row.get("attempt_count", 0)), int(row.get("change_count", 0))
		])
	if report.get("choices", []).is_empty():
		lines.append("| - | 기록 없음 | - | - | - | - |")
	lines.append_array(["", "## 살펴볼 지점", ""])
	for point in report.get("attention_points", []):
		lines.append("- %s" % str(point))
	if report.get("attention_points", []).is_empty():
		lines.append("- 현재 표본에서 반복된 대기·차단·선택 편중 신호가 없습니다.")
	lines.append_array(["", "이 보고서는 관찰 대상을 찾는 자료입니다. 실제 화면과 플레이어 반응을 확인한 뒤 수정 여부를 결정합니다.", ""])
	return "\n".join(lines)

func _finalize_steps(accumulators: Dictionary, blocker_counts: Dictionary, session_count: int) -> Array:
	var rows: Array = []
	for step_id_source in accumulators.keys():
		var step_id := str(step_id_source)
		var accumulator: Dictionary = accumulators[step_id]
		var durations: Array = accumulator.get("durations", [])
		var total := 0.0
		var maximum := 0.0
		for duration_source in durations:
			var duration := float(duration_source)
			total += duration
			maximum = max(maximum, duration)
		rows.append({
			"step_id": step_id,
			"action_id": str(accumulator.get("action_id", "")),
			"first_seen_order": int(accumulator.get("first_seen_order", 0)),
			"completion_session_count": durations.size(),
			"completion_rate": _ratio(durations.size(), session_count),
			"average_seconds": _rounded(total / max(1, durations.size())),
			"median_seconds": _median(durations),
			"max_seconds": _rounded(maximum),
			"long_wait_session_count": int(accumulator.get("long_wait_session_count", 0)),
			"blocked_attempt_count": int(blocker_counts.get(step_id, 0))
		})
	rows.sort_custom(func(a, b): return int(a.get("first_seen_order", 0)) < int(b.get("first_seen_order", 0)))
	return rows

func _finalize_blockers(blocker_counts: Dictionary) -> Array:
	var rows: Array = []
	for step_id in blocker_counts.keys():
		var count := int(blocker_counts[step_id])
		if count > 0:
			rows.append({"step_id": str(step_id), "attempt_count": count})
	rows.sort_custom(func(a, b):
		if int(a.get("attempt_count", 0)) == int(b.get("attempt_count", 0)):
			return str(a.get("step_id", "")) < str(b.get("step_id", ""))
		return int(a.get("attempt_count", 0)) > int(b.get("attempt_count", 0))
	)
	return rows

func _finalize_choices(accumulators: Dictionary) -> Array:
	var keys: Array = accumulators.keys()
	keys.sort()
	var rows: Array = []
	for key in keys:
		var row: Dictionary = accumulators[key]
		var dominant := _dominant_value(row.get("first_value_counts", {}))
		row["dominant_first_value"] = str(dominant.get("value", ""))
		row["dominant_first_count"] = int(dominant.get("count", 0))
		row["dominant_first_rate"] = _ratio(int(dominant.get("count", 0)), int(row.get("session_count", 0)))
		rows.append(row)
	return rows

func _build_attention_points(steps: Array, blockers: Array, choices: Array, session_count: int) -> Array[String]:
	var points: Array[String] = []
	if session_count < MIN_USEFUL_SAMPLE_COUNT:
		points.append("표본이 %d개이므로 반복 경향 판정은 보류합니다." % session_count)
	for row in steps:
		if int(row.get("long_wait_session_count", 0)) >= 2:
			points.append("%s에서 20초 이상 머문 세션이 %d개입니다." % [_step_label(str(row.get("step_id", ""))), int(row.get("long_wait_session_count", 0))])
	for row in blockers:
		if int(row.get("attempt_count", 0)) >= 2:
			points.append("%s에서 차단된 조작이 %d회입니다." % [_step_label(str(row.get("step_id", ""))), int(row.get("attempt_count", 0))])
	for row in choices:
		if int(row.get("session_count", 0)) >= MIN_USEFUL_SAMPLE_COUNT and float(row.get("dominant_first_rate", 0.0)) >= 0.8:
			points.append("DAY %d %s 첫 선택이 %s에 %.0f%% 집중됐습니다." % [int(row.get("day", 0)), _choice_label(str(row.get("category", ""))), _value_label(str(row.get("dominant_first_value", ""))), float(row.get("dominant_first_rate", 0.0)) * 100.0])
	return points

func _median(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values := values.duplicate()
	sorted_values.sort()
	var middle := sorted_values.size() / 2
	if sorted_values.size() % 2 == 1:
		return _rounded(float(sorted_values[middle]))
	return _rounded((float(sorted_values[middle - 1]) + float(sorted_values[middle])) / 2.0)

func _dominant_value(counts: Dictionary) -> Dictionary:
	var best_value := ""
	var best_count := 0
	var keys: Array = counts.keys()
	keys.sort()
	for value in keys:
		var count := int(counts[value])
		if count > best_count:
			best_value = str(value)
			best_count = count
	return {"value": best_value, "count": best_count}

func _increment(counts: Dictionary, key: String) -> void:
	if key != "":
		counts[key] = int(counts.get(key, 0)) + 1

func _ratio(numerator: int, denominator: int) -> float:
	return _rounded(float(numerator) / float(denominator)) if denominator > 0 else 0.0

func _rounded(value: float) -> float:
	return snappedf(value, 0.01)

func _write_text(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	return true

func _count_map_text(source) -> String:
	var counts: Dictionary = source if source is Dictionary else {}
	var keys: Array = counts.keys()
	keys.sort()
	var parts: Array[String] = []
	for value in keys:
		parts.append("%s %d" % [_value_label(str(value)), int(counts[value])])
	return ", ".join(parts)

func _step_label(step_id: String) -> String:
	var labels := {
		"TUT_010_NAME": "마왕명 확정",
		"TUT_020_THRONE_HP": "첫 대화",
		"TUT_030_SELECT_SLIME": "슬라임 선택",
		"TUT_040_DEPLOY_SLIME": "슬라임 배치",
		"TUT_050_GLOBAL_DEFEND": "전체 지침 사수",
		"TUT_090_RESULT_GROWTH": "성장 확인",
		"TUT_110_TRAP_CORRIDOR": "가시 복도 선택",
		"TUT_120_TRAP_LURE": "함정 유도",
		"TUT_130_GOBLIN_CONTROL": "고블린 자동 추격",
		"TUT_210_RECOVERY_NEST": "회복 둥지 선택",
		"TUT_220_RETREAT_LINE": "후퇴선",
		"TUT_230_IMP_FIREBALL": "임프 자동 화염구",
		"TUT_240_BOSS_HP": "보스 체력 대응",
		"TUT_310_RAID_PREVIEW": "원정 미리보기"
	}
	return "%s (`%s`)" % [str(labels.get(step_id, step_id)), step_id]

func _choice_label(category: String) -> String:
	if category == "global_directive": return "전체 지침"
	if category.begins_with("room_directive:"): return "방 지침 (%s)" % category.trim_prefix("room_directive:")
	return str({"facility": "시설", "growth_focus": "집중 성장", "specialization": "전술 특화"}.get(category, category))

func _value_label(value: String) -> String:
	return str({
		"all_out": "총공격", "defense": "사수", "survival": "생존", "entry_block": "입구 봉쇄",
		"trap_lure": "함정 유도", "retreat": "후퇴선", "watch_post": "감시 초소", "barracks": "병영",
		"treasure": "보물방", "recovery": "회복 둥지", "slime": "슬라임", "goblin": "고블린",
		"imp": "임프", "goblin_treasure_hunter": "보물방 사냥꾼"
	}.get(value, value))
