extends Node

const MANIFEST_PATH := "res://data/story/v122_main/manifest.json"
const EXPECTED_SOURCE_SHA256 := "d421651b49739c88706c48c1482a3a1dc8dc7d697b017870f5f8ead19014914b"
const EXPECTED_DAY01_TO_05_SOURCE_SHA256 := "6753f68e5cfb4662ee2ff978af5d39c73d5157bd595995438c1b4bf2de821f58"
const EXPECTED_DAY01_TO_05_SNAPSHOT_SHA256 := "886f27b8f07c2d8e613f7b0d7708878a436fb0ac62d0913289eff514a565e940"
const ALLOWED_TRIGGERS := {
	"management_entered": true,
	"placement_confirmed": true,
	"precombat_confirmed": true,
	"combat_started": true,
	"combat_time": true,
	"combat_boss_hp": true,
	"result_win": true,
	"result_loss": true,
	"raid_roster_confirmed": true,
	"raid_completed": true,
	"ending_entered": true,
}
const ALLOWED_DELIVERIES := {"blocking": true, "combat_bark": true}
const ALLOWED_REPEAT_POLICIES := {
	"once_first_cycle_day": true,
	"once_battle": true,
	"once_raid": true,
}
const ALLOWED_CONDITION_OPS := {"eq": true, "ne": true, "gt": true, "contains": true}

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var manifest := _load_json(MANIFEST_PATH)
	_expect(not manifest.is_empty(), "manifest JSON 파싱")
	if manifest.is_empty():
		_finish()
		return
	_expect(int(manifest.get("schema_version", 0)) == 1, "manifest schema_version 1")
	_expect(str(manifest.get("source_sha256", "")) == EXPECTED_SOURCE_SHA256, "승인 원문 SHA-256 고정")
	var snapshot_path := str(manifest.get("source_snapshot", ""))
	_expect(snapshot_path == "res://data/story/source/V122_MAIN_SCENARIO_DIALOGUE_BOOK_APPROVED_2026-07-31.md", "DAY 6~30 승인 스냅샷 경로 고정")
	_expect(FileAccess.file_exists(snapshot_path), "DAY 6~30 승인 스냅샷 존재")
	if FileAccess.file_exists(snapshot_path):
		var snapshot_hash := FileAccess.get_sha256(ProjectSettings.globalize_path(snapshot_path))
		_expect(snapshot_hash == EXPECTED_SOURCE_SHA256, "DAY 6~30 승인 스냅샷 해시 고정")
	_expect(str(manifest.get("source_day01_05_sha256", "")) == EXPECTED_DAY01_TO_05_SOURCE_SHA256, "DAY 1~5 기존 원본 SHA 보존")
	var day01_to_05_snapshot := str(manifest.get("source_day01_05_snapshot", ""))
	_expect(day01_to_05_snapshot == "res://data/story/source/V122_MAIN_SCENARIO_DIALOGUE_BOOK_DAY01_05_2026-07-30.md", "DAY 1~5 기존 스냅샷 경로 보존")
	_expect(FileAccess.file_exists(day01_to_05_snapshot), "DAY 1~5 기존 스냅샷 존재")
	if FileAccess.file_exists(day01_to_05_snapshot):
		_expect(FileAccess.get_sha256(ProjectSettings.globalize_path(day01_to_05_snapshot)) == EXPECTED_DAY01_TO_05_SNAPSHOT_SHA256, "DAY 1~5 기존 스냅샷 해시 보존")
	var day_files: Array = manifest.get("day_files", [])
	_expect(day_files.size() == 30, "manifest DAY 파일 30개")

	var characters := _load_json("res://data/characters.json")
	_expect(not characters.is_empty(), "캐릭터 카탈로그 파싱")
	var all_scene_ids := {}
	var all_cue_ids := {}
	var replacement_references: Array[String] = []
	for index in range(day_files.size()):
		var day_path := str(day_files[index])
		_expect(day_path == "res://data/story/v122_main/day_%02d.json" % (index + 1), "DAY %d 파일 순서" % (index + 1))
		var day_data := _load_json(day_path)
		_validate_day(day_data, index + 1, characters, all_scene_ids, all_cue_ids, replacement_references)
	for cue_id in replacement_references:
		_expect(all_cue_ids.has(cue_id), "교체 대상 cue 존재: %s" % cue_id)
	_finish()


func _validate_day(
	day_data: Dictionary,
	expected_day: int,
	characters: Dictionary,
	all_scene_ids: Dictionary,
	all_cue_ids: Dictionary,
	replacement_references: Array[String]
) -> void:
	_expect(not day_data.is_empty(), "DAY %d JSON 파싱" % expected_day)
	if day_data.is_empty():
		return
	_expect(int(day_data.get("schema_version", 0)) == 1, "DAY %d schema_version 1" % expected_day)
	_expect(int(day_data.get("day", 0)) == expected_day, "DAY %d day 값" % expected_day)
	var scenes: Array = day_data.get("scenes", [])
	_expect(not scenes.is_empty(), "DAY %d scene 존재" % expected_day)
	for scene_value in scenes:
		_expect(scene_value is Dictionary, "DAY %d scene Dictionary" % expected_day)
		if not (scene_value is Dictionary):
			continue
		var story_scene: Dictionary = scene_value
		var scene_id := str(story_scene.get("id", ""))
		_expect(scene_id != "" and not all_scene_ids.has(scene_id), "scene ID 고유: %s" % scene_id)
		all_scene_ids[scene_id] = true
		_expect(int(story_scene.get("day", 0)) == expected_day, "%s day 일치" % scene_id)
		_expect(ALLOWED_TRIGGERS.has(str(story_scene.get("trigger", ""))), "%s trigger 계약" % scene_id)
		var delivery := str(story_scene.get("delivery", ""))
		_expect(ALLOWED_DELIVERIES.has(delivery), "%s delivery 계약" % scene_id)
		_expect(ALLOWED_REPEAT_POLICIES.has(str(story_scene.get("repeat_policy", ""))), "%s repeat_policy 계약" % scene_id)
		if delivery == "combat_bark":
			_expect(str(story_scene.get("queue_policy", "")) == "append", "%s combat_bark append 대기열" % scene_id)
		if story_scene.has("conditions"):
			_expect(_valid_conditions(story_scene["conditions"]), "%s scene conditions 구조" % scene_id)
		if story_scene.has("metadata"):
			_expect(story_scene["metadata"] is Dictionary, "%s metadata Dictionary" % scene_id)
		var cues: Array = story_scene.get("cues", [])
		_expect(not cues.is_empty(), "%s cue 존재" % scene_id)
		for cue_value in cues:
			_validate_cue(cue_value, scene_id, characters, all_cue_ids, replacement_references)


func _validate_cue(
	cue_value,
	scene_id: String,
	characters: Dictionary,
	all_cue_ids: Dictionary,
	replacement_references: Array[String]
) -> void:
	_expect(cue_value is Dictionary, "%s cue Dictionary" % scene_id)
	if not (cue_value is Dictionary):
		return
	var cue: Dictionary = cue_value
	var cue_id := str(cue.get("id", ""))
	_expect(cue_id != "" and not all_cue_ids.has(cue_id), "cue ID 고유: %s" % cue_id)
	all_cue_ids[cue_id] = true
	_expect(str(cue.get("speaker_id", "")) != "", "%s speaker_id" % cue_id)
	_expect(str(cue.get("speaker_label", "")) != "", "%s speaker_label" % cue_id)
	_expect(str(cue.get("text_ko", "")) != "", "%s text_ko" % cue_id)
	_expect(str(cue.get("emotion_direction", "")) != "", "%s emotion_direction" % cue_id)
	_expect(str(cue.get("portrait_emotion", "")) != "", "%s portrait_emotion" % cue_id)
	_expect(int(cue.get("source_line", 0)) > 0, "%s source_line" % cue_id)
	var speaker_id := str(cue.get("speaker_id", ""))
	var portrait_emotion := str(cue.get("portrait_emotion", ""))
	if speaker_id == "NARRATOR":
		_expect(portrait_emotion == "none", "%s 내레이션 초상 없음" % cue_id)
	else:
		var character_value = characters.get(speaker_id, {})
		_expect(character_value is Dictionary and not character_value.is_empty(), "%s 캐릭터 ID 존재" % cue_id)
		if character_value is Dictionary:
			var portrait: Dictionary = character_value.get("portrait", {})
			var observed: Array = portrait.get("observed_emotions", [])
			_expect(observed.has(portrait_emotion), "%s 초상 감정 카탈로그 등록" % cue_id)
	if cue.has("conditions"):
		_expect(_valid_conditions(cue["conditions"]), "%s cue conditions 구조" % cue_id)
	if cue.has("replaces_cue_ids"):
		var replacement_ids = cue["replaces_cue_ids"]
		_expect(replacement_ids is Array and not replacement_ids.is_empty(), "%s replaces_cue_ids 구조" % cue_id)
		if replacement_ids is Array:
			for replacement_id in replacement_ids:
				replacement_references.append(str(replacement_id))


func _valid_conditions(value) -> bool:
	if not (value is Dictionary):
		return false
	var conditions: Dictionary = value
	if conditions.size() != 1 or not conditions.has("all"):
		return false
	var entries = conditions["all"]
	if not (entries is Array) or entries.is_empty():
		return false
	for entry_value in entries:
		if not (entry_value is Dictionary):
			return false
		var entry: Dictionary = entry_value
		if str(entry.get("fact", "")) == "" or not ALLOWED_CONDITION_OPS.has(str(entry.get("op", ""))) or not entry.has("value"):
			return false
	return true


func _load_json(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
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


func _finish() -> void:
	print("V122_STORY_DIALOGUE_SCHEMA_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)
