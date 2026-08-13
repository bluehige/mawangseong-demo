extends Node

const MANIFEST_PATH := "res://data/story/v122_main/manifest.json"
const EXPECTED_UNIQUE_SOURCE_LINES := {1: 38, 2: 34, 3: 34, 4: 42, 5: 35}

var failed := false
var assertion_count := 0
var dialogue_regex := RegEx.new()


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var regex_error := dialogue_regex.compile("^\\s*-\\s+\\[([^|\\]]+)\\|([^\\]]+)\\]:\\s(.*)$")
	_expect(regex_error == OK, "원문 대사 정규식 준비")
	var manifest := _load_json(MANIFEST_PATH)
	var snapshot_lines := FileAccess.get_file_as_string(str(manifest.get("source_day01_05_snapshot", ""))).split("\n")
	var days := {}
	for day_path_value in manifest.get("day_files", []):
		var day_data := _load_json(str(day_path_value))
		days[int(day_data.get("day", 0))] = day_data
	_validate_source_fidelity(days, snapshot_lines)
	_validate_day01(days.get(1, {}))
	_validate_day02(days.get(2, {}))
	_validate_day03(days.get(3, {}))
	_validate_day04(days.get(4, {}))
	_validate_day05(days.get(5, {}))
	print("V122_STORY_DAY01_TO_05_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _validate_source_fidelity(days: Dictionary, snapshot_lines: PackedStringArray) -> void:
	for day in range(1, 6):
		var day_data: Dictionary = days.get(day, {})
		var source_lines_seen := {}
		for story_scene in day_data.get("scenes", []):
			for cue in story_scene.get("cues", []):
				var source_line := int(cue.get("source_line", 0))
				source_lines_seen[source_line] = true
				var source_dialogue := _source_dialogue(snapshot_lines, source_line)
				_expect(
					str(cue.get("speaker_label", "")) == str(source_dialogue.get("speaker_label", ""))
					and str(cue.get("emotion_direction", "")) == str(source_dialogue.get("emotion_direction", ""))
					and str(cue.get("text_ko", "")) == str(source_dialogue.get("text_ko", "")),
					"DAY %d source line %d 원문 무수정" % [day, source_line]
				)
		_expect(source_lines_seen.size() == int(EXPECTED_UNIQUE_SOURCE_LINES[day]), "DAY %d 편집 원고 대사 %d줄 전부 수록" % [day, EXPECTED_UNIQUE_SOURCE_LINES[day]])


func _validate_day01(day_data: Dictionary) -> void:
	_expect(_scene(day_data, "STORY_D01_PLACEMENT_FRONT").get("cues", []).size() == 2, "DAY 1 곱 전열 반응 2줄")
	_expect(_scene(day_data, "STORY_D01_PLACEMENT_REAR").get("cues", []).size() == 2, "DAY 1 곱 후열 반응 2줄")
	_expect(_scene(day_data, "STORY_D01_RESULT_LOSS").get("cues", []).size() == 2, "DAY 1 패배 대사 2줄")
	_expect(_count_trigger(day_data, "combat_time") == 4, "DAY 1 전투 대사 4개 시간 묶음")
	_expect(_active_cue_count(day_data, {"gob_formation": "front"}, ["result_loss"]) == 34, "DAY 1 전열 승리 경로 34줄")
	_expect(_active_cue_count(day_data, {"gob_formation": "rear"}, ["result_loss"]) == 34, "DAY 1 후열 승리 경로 34줄")


func _validate_day02(day_data: Dictionary) -> void:
	var result_scene := _scene(day_data, "STORY_D02_RESULT_WIN")
	var replacement_cues: Array = []
	for cue in result_scene.get("cues", []):
		if cue.has("replaces_cue_ids"):
			replacement_cues.append(cue)
	_expect(result_scene.get("cues", []).size() == 10, "DAY 2 승리 원문 8줄 + 금고 피해 교체 2줄")
	_expect(replacement_cues.size() == 2, "DAY 2 금고 피해 cue 2개 교체형")
	_expect(_active_cues(result_scene, {"treasure_gold_stolen_this_battle": 0}).size() == 8, "DAY 2 보물 손실 0 결과 8줄")
	_expect(_active_cues(result_scene, {"treasure_gold_stolen_this_battle": 1}).size() == 8, "DAY 2 보물 손실 발생 결과 8줄")
	var loss_text := _cue_text(_active_cues(result_scene, {"treasure_gold_stolen_this_battle": 1}))
	_expect(loss_text.contains("보물 손실 발생!") and loss_text.contains("오늘은 8점.") and not loss_text.contains("보물 손실 0.") and not loss_text.contains("오늘 보안은 7점."), "DAY 2 금고 피해 결과 모순 제거")
	_expect(_count_trigger(day_data, "result_loss") == 0, "DAY 2 미작성 패배 대사 미생성")


func _validate_day03(day_data: Dictionary) -> void:
	var expected := {0.75: 4, 0.5: 2, 0.25: 2}
	var observed := {}
	for story_scene in day_data.get("scenes", []):
		if str(story_scene.get("trigger", "")) == "combat_boss_hp":
			observed[float(story_scene.get("metadata", {}).get("threshold", -1.0))] = story_scene.get("cues", []).size()
	_expect(observed == expected, "DAY 3 보스 HP 75/50/25% 대사 4/2/2줄")
	_expect(_scene(day_data, "STORY_D03_RESULT_LOSS").get("cues", []).size() == 2, "DAY 3 패배 대사 2줄")


func _validate_day04(day_data: Dictionary) -> void:
	var roster_scene := _scene(day_data, "STORY_D04_RAID_ROSTER")
	var resolution_scene := _scene(day_data, "STORY_D04_RAID_RESOLUTION")
	_expect(str(roster_scene.get("trigger", "")) == "raid_roster_confirmed", "DAY 4 원정 편성 확정 trigger")
	_expect(str(resolution_scene.get("trigger", "")) == "raid_completed", "DAY 4 즉시 원정 결산 trigger")
	_expect(str(roster_scene.get("metadata", {}).get("branch_mode", "")) == "additive" and str(resolution_scene.get("metadata", {}).get("branch_mode", "")) == "additive", "DAY 4 편성 반응 additive")
	_expect(_active_cue_count(day_data, {"raid_mission_id": "d04_signpost_flip", "selected_raid_monster_ids": [], "day4_raid_completed": true}) == 30, "DAY 4 로로 고정 지휘 경로 30줄·추가 대사 없음")
	_expect(_active_cue_count(day_data, {"raid_mission_id": "d04_signpost_flip", "selected_raid_monster_ids": ["mon_core_gob"], "day4_raid_completed": true}) == 34, "DAY 4 반응 몬스터 1명 경로 34줄")
	_expect(_active_cue_count(day_data, {"raid_mission_id": "d04_signpost_flip", "selected_raid_monster_ids": ["mon_core_gob", "mon_core_pudding"], "day4_raid_completed": true}) == 38, "DAY 4 반응 몬스터 2명 경로 38줄")
	_expect(_scene(day_data, "STORY_D04_DEFENSE_ARRIVAL").get("cues", []).size() == 2, "DAY 4 원정 후 방어 도착 대사 2줄")
	_expect(_count_trigger(day_data, "result_win") == 0 and _count_trigger(day_data, "result_loss") == 0, "DAY 4 미작성 방어 결산 대사 미생성")


func _validate_day05(day_data: Dictionary) -> void:
	var raid_scene := _scene(day_data, "STORY_D05_RAID_RESULT")
	_expect(str(raid_scene.get("trigger", "")) == "raid_completed", "DAY 5 선택 원정 완료 trigger")
	_expect(str(raid_scene.get("metadata", {}).get("mission_id", "")) == "d05_supply_tag" and raid_scene.get("cues", []).size() == 3, "DAY 5 보급 상자 원정 3줄")
	_expect(_count_trigger(day_data, "result_loss") == 0, "DAY 5 미작성 패배 대사 미생성")
	_expect(_active_cue_count(day_data, {}) == 32, "DAY 5 기본 방어 경로 32줄")
	_expect(_active_cue_count(day_data, {"raid_mission_id": "d05_supply_tag"}) == 35, "DAY 5 선택 원정 포함 경로 35줄")


func _source_dialogue(snapshot_lines: PackedStringArray, source_line: int) -> Dictionary:
	if source_line <= 0 or source_line > snapshot_lines.size():
		return {}
	# The approved source is maintained as Windows CRLF text. Strip the line
	# ending before applying the exact dialogue grammar, so the fidelity gate
	# checks the dialogue itself rather than the checkout's line-ending style.
	var match := dialogue_regex.search(snapshot_lines[source_line - 1].strip_edges())
	if match == null:
		return {}
	return {
		"speaker_label": match.get_string(1),
		"emotion_direction": match.get_string(2),
		"text_ko": match.get_string(3),
	}


func _scene(day_data: Dictionary, scene_id: String) -> Dictionary:
	for story_scene in day_data.get("scenes", []):
		if str(story_scene.get("id", "")) == scene_id:
			return story_scene
	return {}


func _count_trigger(day_data: Dictionary, trigger: String) -> int:
	var count := 0
	for story_scene in day_data.get("scenes", []):
		if str(story_scene.get("trigger", "")) == trigger:
			count += 1
	return count


func _active_cue_count(day_data: Dictionary, facts: Dictionary, excluded_triggers: Array[String] = []) -> int:
	var count := 0
	for story_scene in day_data.get("scenes", []):
		if excluded_triggers.has(str(story_scene.get("trigger", ""))) or not _conditions_match(story_scene.get("conditions", {}), facts):
			continue
		count += _active_cues(story_scene, facts).size()
	return count


func _active_cues(story_scene: Dictionary, facts: Dictionary) -> Array:
	var result: Array = []
	for cue in story_scene.get("cues", []):
		if _conditions_match(cue.get("conditions", {}), facts):
			result.append(cue)
	return result


func _conditions_match(conditions_value, facts: Dictionary) -> bool:
	if not (conditions_value is Dictionary) or conditions_value.is_empty():
		return true
	for entry in conditions_value.get("all", []):
		var fact_name := str(entry.get("fact", ""))
		var actual = facts.get(fact_name)
		var expected = entry.get("value")
		match str(entry.get("op", "")):
			"eq":
				if actual != expected:
					return false
			"gt":
				if float(actual if actual != null else 0) <= float(expected):
					return false
			"contains":
				if not (actual is Array) or not actual.has(expected):
					return false
			_:
				return false
	return true


func _cue_text(cues: Array) -> String:
	var parts: Array[String] = []
	for cue in cues:
		parts.append(str(cue.get("text_ko", "")))
	return "\n".join(parts)


func _load_json(file_path: String) -> Dictionary:
	if file_path == "" or not FileAccess.file_exists(file_path):
		push_error("JSON 파일 없음: %s" % file_path)
		return {}
	var parser := JSON.new()
	var parse_error := parser.parse(FileAccess.get_file_as_string(file_path))
	if parse_error != OK or not (parser.data is Dictionary):
		push_error("JSON 파싱 실패: %s (%s)" % [file_path, parser.get_error_message()])
		return {}
	return parser.data


func _expect(condition_value: bool, label: String) -> void:
	assertion_count += 1
	if condition_value:
		print("  PASS · %s" % label)
	else:
		failed = true
		push_error("  FAIL · %s" % label)
