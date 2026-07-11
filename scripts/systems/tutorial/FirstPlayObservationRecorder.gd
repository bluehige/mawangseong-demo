extends RefCounted
class_name FirstPlayObservationRecorder

const LONG_WAIT_SECONDS := 20.0
const MAX_EVENTS := 500
const SAFE_DETAIL_KEYS := [
	"day",
	"directive",
	"room_id",
	"monster_id",
	"unit_id",
	"target_id",
	"skill_id",
	"facility_id",
	"specialization_id",
	"win",
	"hp_ratio"
]

var active := false
var session_mode := ""
var session_started_at := ""
var session_file_stem := ""
var session_started_msec := 0
var current_step_id := ""
var current_step_started_msec := 0
var events: Array[Dictionary] = []
var completed_steps: Array[Dictionary] = []
var blocked_attempts_by_step: Dictionary = {}
var choices: Dictionary = {}
var last_written_paths: Dictionary = {}

func start_session(mode: String, initial_step_id: String, day: int) -> void:
	active = true
	session_mode = mode
	session_started_at = Time.get_datetime_string_from_system()
	session_started_msec = Time.get_ticks_msec()
	session_file_stem = "session_%s_%s_%d" % [session_started_at.replace(":", "-"), mode, session_started_msec % 1000000]
	current_step_id = initial_step_id
	current_step_started_msec = session_started_msec
	events.clear()
	completed_steps.clear()
	blocked_attempts_by_step.clear()
	choices.clear()
	last_written_paths.clear()
	_append_event("session_started", {"mode": mode, "day": day, "step_id": initial_step_id})

func stop() -> void:
	active = false

func record_screen(screen_name: String, day: int) -> void:
	if not active:
		return
	if not events.is_empty():
		var last_event: Dictionary = events[events.size() - 1]
		if str(last_event.get("type", "")) == "screen" and str(last_event.get("screen", "")) == screen_name and int(last_event.get("day", 0)) == day:
			return
	_append_event("screen", {"screen": screen_name, "day": day})

func record_blocked(action_id: String, expected_action: String, step_id: String, day: int, screen_name: String) -> void:
	if not active:
		return
	var key := step_id if step_id != "" else "no_tutorial_step"
	blocked_attempts_by_step[key] = int(blocked_attempts_by_step.get(key, 0)) + 1
	_append_event("blocked", {
		"action_id": action_id,
		"expected_action": expected_action,
		"step_id": step_id,
		"day": day,
		"screen": screen_name
	})

func record_tutorial_action(action_id: String, payload: Dictionary, step_before: String, step_after: String, advanced: bool, day: int, screen_name: String) -> void:
	if not active:
		return
	var safe_payload := _safe_details(payload)
	_append_event("tutorial_action", {
		"action_id": action_id,
		"payload": safe_payload,
		"step_before": step_before,
		"step_after": step_after,
		"advanced": advanced,
		"day": day,
		"screen": screen_name
	})
	_record_choice_from_action(action_id, safe_payload, day)
	if not advanced:
		return
	var now := Time.get_ticks_msec()
	var elapsed := _seconds_between(current_step_started_msec, now)
	var completed_id := step_before if step_before != "" else current_step_id
	completed_steps.append({
		"step_id": completed_id,
		"action_id": action_id,
		"elapsed_seconds": elapsed,
		"blocked_attempts": int(blocked_attempts_by_step.get(completed_id, 0)),
		"long_wait": elapsed >= LONG_WAIT_SECONDS,
		"day": day
	})
	current_step_id = step_after
	current_step_started_msec = now

func record_choice(category: String, value: String, day: int, details: Dictionary = {}) -> void:
	if not active or category == "" or value == "":
		return
	var key := "day_%d:%s" % [day, category]
	var row: Dictionary = choices.get(key, {})
	if row.is_empty():
		row = {
			"key": key,
			"category": category,
			"day": day,
			"first_value": value,
			"latest_value": value,
			"attempts": 1,
			"changes": 0,
			"first_at_seconds": _session_elapsed_seconds(),
			"details": _safe_details(details)
		}
	else:
		row["attempts"] = int(row.get("attempts", 0)) + 1
		if str(row.get("latest_value", "")) != value:
			row["changes"] = int(row.get("changes", 0)) + 1
		row["latest_value"] = value
		row["details"] = _safe_details(details)
	choices[key] = row
	_append_event("choice", {
		"category": category,
		"value": value,
		"day": day,
		"details": _safe_details(details),
		"attempt": int(row.get("attempts", 1))
	})

func total_blocked_attempts() -> int:
	var total := 0
	for count in blocked_attempts_by_step.values():
		total += int(count)
	return total

func long_wait_count() -> int:
	var total := 0
	for row in completed_steps:
		if bool(row.get("long_wait", false)):
			total += 1
	return total

func choice_for(day: int, category: String) -> Dictionary:
	return choices.get("day_%d:%s" % [day, category], {})

func save_snapshot(day: int, completed: bool = false) -> Dictionary:
	if not active and events.is_empty():
		return {}
	var report := build_report(day, completed)
	var json_text := JSON.stringify(report, "\t") + "\n"
	var markdown_text := _build_markdown(report)
	var user_dir := ProjectSettings.globalize_path("user://first_play_observation")
	var user_json := user_dir.path_join("latest.json")
	var user_markdown := user_dir.path_join("latest.md")
	var user_session_json := user_dir.path_join(session_file_stem + ".json")
	var user_session_markdown := user_dir.path_join(session_file_stem + ".md")
	_write_text(user_json, json_text)
	_write_text(user_markdown, markdown_text)
	_write_text(user_session_json, json_text)
	_write_text(user_session_markdown, markdown_text)
	last_written_paths = {
		"json": user_json,
		"markdown": user_markdown,
		"session_json": user_session_json,
		"session_markdown": user_session_markdown
	}
	if OS.has_feature("editor"):
		var dev_dir := ProjectSettings.globalize_path("res://tmp/first_play_observation")
		var dev_json := dev_dir.path_join("latest.json")
		var dev_markdown := dev_dir.path_join("latest.md")
		var dev_session_json := dev_dir.path_join(session_file_stem + ".json")
		var dev_session_markdown := dev_dir.path_join(session_file_stem + ".md")
		_write_text(dev_json, json_text)
		_write_text(dev_markdown, markdown_text)
		_write_text(dev_session_json, json_text)
		_write_text(dev_session_markdown, markdown_text)
		last_written_paths["dev_json"] = dev_json
		last_written_paths["dev_markdown"] = dev_markdown
		last_written_paths["dev_session_json"] = dev_session_json
		last_written_paths["dev_session_markdown"] = dev_session_markdown
	return last_written_paths.duplicate(true)

func build_report(day: int, completed: bool = false) -> Dictionary:
	var choice_rows: Array = []
	for row in choices.values():
		choice_rows.append(row.duplicate(true))
	choice_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("first_at_seconds", 0.0)) < float(b.get("first_at_seconds", 0.0))
	)
	return {
		"schema_version": 1,
		"session_id": session_file_stem,
		"session_mode": session_mode,
		"session_started_at": session_started_at,
		"generated_at": Time.get_datetime_string_from_system(),
		"day": day,
		"completed": completed,
		"duration_seconds": _session_elapsed_seconds(),
		"privacy": "플레이어 이름과 자유 입력문은 기록하지 않음",
		"summary": {
			"completed_step_count": completed_steps.size(),
			"blocked_attempt_count": total_blocked_attempts(),
			"long_wait_count": long_wait_count(),
			"choice_count": choice_rows.size()
		},
		"completed_steps": completed_steps.duplicate(true),
		"blocked_attempts_by_step": blocked_attempts_by_step.duplicate(true),
		"choices": choice_rows,
		"events": events.duplicate(true)
	}

func _record_choice_from_action(action_id: String, payload: Dictionary, day: int) -> void:
	match action_id:
		"global_directive_set":
			record_choice("global_directive", str(payload.get("directive", "")), day)
		"room_directive_set":
			var room_id := str(payload.get("room_id", ""))
			record_choice("room_directive:%s" % room_id, str(payload.get("directive", "")), day, {"room_id": room_id})

func _safe_details(source: Dictionary) -> Dictionary:
	var safe: Dictionary = {}
	for key in SAFE_DETAIL_KEYS:
		if source.has(key):
			safe[key] = source[key]
	return safe

func _append_event(event_type: String, details: Dictionary) -> void:
	var row := {"type": event_type, "at_seconds": _session_elapsed_seconds()}
	for key in details.keys():
		row[key] = details[key]
	events.append(row)
	if events.size() > MAX_EVENTS:
		events.pop_front()

func _session_elapsed_seconds() -> float:
	if session_started_msec <= 0:
		return 0.0
	return _seconds_between(session_started_msec, Time.get_ticks_msec())

func _seconds_between(start_msec: int, end_msec: int) -> float:
	return snappedf(max(0.0, float(end_msec - start_msec) / 1000.0), 0.01)

func _write_text(path: String, content: String) -> bool:
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		push_warning("첫 플레이 관찰 기록 폴더를 만들지 못했습니다: %s" % path.get_base_dir())
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("첫 플레이 관찰 기록을 저장하지 못했습니다: %s" % path)
		return false
	file.store_string(content)
	return true

func _build_markdown(report: Dictionary) -> String:
	var summary: Dictionary = report.get("summary", {})
	var lines: Array[String] = [
		"# 첫 플레이 관찰 기록",
		"",
		"- 시작 방식: %s" % _mode_label(str(report.get("session_mode", ""))),
		"- 시작 시각: %s" % str(report.get("session_started_at", "")),
		"- 현재 진행: DAY %d" % int(report.get("day", 0)),
		"- 전체 소요: %.2f초" % float(report.get("duration_seconds", 0.0)),
		"- DAY 1~3 완료: %s" % ("예" if bool(report.get("completed", false)) else "아니오"),
		"",
		"## 한눈에 보기",
		"",
		"- 완료한 필수 단계: %d개" % int(summary.get("completed_step_count", 0)),
		"- 막힌 조작: %d회" % int(summary.get("blocked_attempt_count", 0)),
		"- 20초 이상 머문 단계: %d개" % int(summary.get("long_wait_count", 0)),
		"- 기록된 선택 묶음: %d개" % int(summary.get("choice_count", 0)),
		"",
		"## 필수 단계",
		"",
		"| 단계 | 완료 행동 | 걸린 시간 | 막힌 횟수 | 관찰 표시 |",
		"|---|---|---:|---:|---|"
	]
	for row in report.get("completed_steps", []):
		lines.append("| %s | %s | %.2f초 | %d | %s |" % [
			str(row.get("step_id", "")),
			str(row.get("action_id", "")),
			float(row.get("elapsed_seconds", 0.0)),
			int(row.get("blocked_attempts", 0)),
			"오래 머묾" if bool(row.get("long_wait", false)) else "-"
		])
	if report.get("completed_steps", []).is_empty():
		lines.append("| 기록 없음 | - | - | - | - |")
	lines.append_array(["", "## 처음 고른 선택과 재시도", "", "| DAY | 종류 | 처음 선택 | 마지막 선택 | 시도 | 변경 |", "|---:|---|---|---|---:|---:|"])
	for row in report.get("choices", []):
		lines.append("| %d | %s | %s | %s | %d | %d |" % [
			int(row.get("day", 0)),
			_choice_label(str(row.get("category", ""))),
			_value_label(str(row.get("first_value", ""))),
			_value_label(str(row.get("latest_value", ""))),
			int(row.get("attempts", 0)),
			int(row.get("changes", 0))
		])
	if report.get("choices", []).is_empty():
		lines.append("| - | 기록 없음 | - | - | - | - |")
	lines.append_array([
		"",
		"## 기록 범위",
		"",
		"이 보고서는 화면 이동, 필수 행동, 막힌 조작, 지침·시설·성장·전술 특화 선택만 기록합니다.",
		"플레이어 이름과 자유 입력문은 저장하지 않습니다.",
		""
	])
	return "\n".join(lines)

func _mode_label(mode: String) -> String:
	return "빠른 시작" if mode == "quick" else "일반 시작"

func _choice_label(category: String) -> String:
	if category == "global_directive":
		return "전체 지침"
	if category.begins_with("room_directive:"):
		return "방 지침 (%s)" % category.trim_prefix("room_directive:")
	match category:
		"facility":
			return "시설"
		"growth_focus":
			return "집중 성장"
		"specialization":
			return "전술 특화"
	return category

func _value_label(value: String) -> String:
	var labels := {
		"all_out": "총공격",
		"defense": "사수",
		"survival": "생존",
		"entry_block": "입구 봉쇄",
		"trap_lure": "함정 유도",
		"retreat": "후퇴선",
		"watch_post": "감시 초소",
		"barracks": "병영",
		"treasure": "보물방",
		"recovery": "회복 둥지",
		"build_slot": "빈 건설칸",
		"slime": "슬라임",
		"goblin": "고블린",
		"imp": "임프",
		"goblin_treasure_hunter": "보물방 사냥꾼"
	}
	return str(labels.get(value, value))
