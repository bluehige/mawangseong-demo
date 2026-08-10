extends Node

const MANIFEST_PATH := "res://data/story/v122_main/manifest.json"
const STATIC_SPEAKERS := {
	"마왕": "CHR_DARKLORD_PLAYER",
	"바티": "CHR_BATI",
	"골딘": "CHR_GOLDIN",
	"푸딩": "CHR_PUDDING",
	"곱": "CHR_GOB",
	"핀": "CHR_PYNN",
	"로로": "CHR_ROLO",
	"밀로": "CHR_EXPLORER_MILO",
	"니아": "CHR_THIEF_NIA",
	"레온": "CHR_HERO_LEON",
	"레온의답신": "CHR_HERO_LEON",
	"레온의 답신": "CHR_HERO_LEON",
	"레온의전언": "CHR_HERO_LEON",
	"아이리스": "CHR_INVESTIGATOR_IRIS",
	"셀렌": "CHR_SELEN",
	"셀렌의전언": "CHR_SELEN",
	"셀렌의 답신": "CHR_SELEN",
	"로만": "CHR_ROMAN",
	"로만의전언": "CHR_ROMAN",
	"로만의 답신": "CHR_ROMAN"
}
const DYNAMIC_SPEAKER_ROLES := {
	"첫 승급자": "first_promoted",
	"두번째승급자": "second_promoted",
	"먼저승급한몬스터": "first_promoted",
	"나머지몬스터": "remaining_core_monsters"
}
const ENDING_IDS := {
	"true_demon_castle": true,
	"monster_family_castle": true,
	"impregnable_demon_citadel": true,
	"dread_overlord_rises": true,
	"demon_hero_rival_pact": true
}
const RELEASE_COPY_OVERRIDES := {
	"STORY_D28_PRECOMBAT_007": "마지막 원정 선택 — ‘안전한 공성로 정찰’ 또는 ‘공병 보급 교란’.",
	"STORY_D29_MANAGEMENT_124": "최후 선언 — ‘라이벌 약속’, ‘성 수호’, 자격을 갖췄다면 ‘휴전문 제안’ 중 하나.",
	"STORY_D30_ENDING_037": "너무 무서워하면 아무도 안 오잖아."
}

var failed := false
var assertion_count := 0
var dialogue_regex := RegEx.new()


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(dialogue_regex.compile("^\\s*-\\s+\\[([^|\\]]+)\\|([^\\]]+)\\]:\\s(.*)$") == OK, "원문 대사 정규식 준비")
	var manifest := _load_json(MANIFEST_PATH)
	var snapshot_path := str(manifest.get("source_snapshot", ""))
	var source_records := _source_records(FileAccess.get_file_as_string(snapshot_path).replace("\r\n", "\n").split("\n"))
	_expect(source_records.size() > 0, "DAY 6~30 승인 원문 대사 발견")
	var day_files: Array = manifest.get("day_files", [])
	var cues_by_source_line := {}
	var dynamic_count := 0
	var day29 := {}
	var day30 := {}
	var release_added_count := 0
	for day_path_value in day_files:
		var day_data := _load_json(str(day_path_value))
		var day := int(day_data.get("day", 0))
		if day < 6 or day > 30:
			continue
		if day == 29:
			day29 = day_data
		elif day == 30:
			day30 = day_data
		for scene_value in day_data.get("scenes", []):
			if not (scene_value is Dictionary):
				continue
			var story_scene: Dictionary = scene_value
			for cue_value in story_scene.get("cues", []):
				if not (cue_value is Dictionary):
					continue
				var cue: Dictionary = cue_value
				if str(cue.get("release_added", "")) == "v1.2.5":
					release_added_count += 1
					_expect(not cue.has("source_line") and str(cue.get("text_ko", "")).strip_edges() != "", "%s는 v1.2.5 추가 대사로 명시" % str(cue.get("id", "")))
					dynamic_count += _validate_speaker_mapping(cue)
					continue
				var source_line := int(cue.get("source_line", 0))
				_expect(source_records.has(source_line), "DAY %d cue %s는 승인 원문 줄을 가리킴" % [day, str(cue.get("id", ""))])
				if not source_records.has(source_line):
					continue
				_expect(not cues_by_source_line.has(source_line), "승인 원문 줄 %d는 한 번만 수록" % source_line)
				cues_by_source_line[source_line] = cue
				var source: Dictionary = source_records[source_line]
				var cue_id := str(cue.get("id", ""))
				var expected_text := str(RELEASE_COPY_OVERRIDES.get(cue_id, source.get("text_ko", "")))
				_expect(
					int(source.get("day", 0)) == day
					and str(source.get("speaker_label", "")) == str(cue.get("speaker_label", ""))
					and str(source.get("emotion_direction", "")) == str(cue.get("emotion_direction", ""))
					and expected_text == str(cue.get("text_ko", "")),
					"DAY %d source line %d 승인 원문 또는 출시 교정문 일치" % [day, source_line]
				)
				dynamic_count += _validate_speaker_mapping(cue)
	_expect(cues_by_source_line.size() == source_records.size(), "DAY 6~30 승인 원문 %d줄 전부 수록" % source_records.size())
	for source_line_value in source_records.keys():
		_expect(cues_by_source_line.has(source_line_value), "원문 줄 %d 누락 없음" % int(source_line_value))
	_expect(dynamic_count == 11, "첫·두 번째 승급자 동적 초상화 11개 cue 등록")
	_expect(release_added_count == 7, "DAY 29 휴전문 제안 전용 반응 7개 추가")
	_validate_day29(day29)
	_validate_day30(day30)
	_finish()


func _source_records(lines: PackedStringArray) -> Dictionary:
	var records := {}
	var day := 0
	for index in range(lines.size()):
		var line := lines[index]
		var day_match := RegEx.new()
		day_match.compile("^## DAY (\\d+)\\b")
		var found_day = day_match.search(line)
		if found_day != null:
			day = int(found_day.get_string(1))
			continue
		if line.begins_with("# 1회차 기본 엔딩"):
			day = 30
			continue
		if day < 6 or day > 30:
			continue
		var dialogue = dialogue_regex.search(line)
		if dialogue == null:
			continue
		records[index + 1] = {
			"day": day,
			"speaker_label": dialogue.get_string(1),
			"emotion_direction": dialogue.get_string(2),
			"text_ko": dialogue.get_string(3)
		}
	return records


func _validate_speaker_mapping(cue: Dictionary) -> int:
	var label := str(cue.get("speaker_label", ""))
	if STATIC_SPEAKERS.has(label):
		_expect(str(cue.get("speaker_id", "")) == str(STATIC_SPEAKERS[label]), "%s 기존 초상화 ID 연결" % str(cue.get("id", "")))
		return 0
	if DYNAMIC_SPEAKER_ROLES.has(label):
		_expect(str(cue.get("speaker_id", "")) == "NARRATOR" and str(cue.get("speaker_role", "")) == str(DYNAMIC_SPEAKER_ROLES[label]), "%s 실제 승급자 초상화 치환 표식" % str(cue.get("id", "")))
		return 1
	_expect(str(cue.get("speaker_id", "")) == "NARRATOR" and str(cue.get("portrait_emotion", "")) == "none", "%s 일반 적·병사에 잘못된 초상화 없음" % str(cue.get("id", "")))
	return 0


func _validate_day29(day_data: Dictionary) -> void:
	var scenes: Array = day_data.get("scenes", [])
	_expect(scenes.size() == 4, "DAY 29는 결전 전야 3구간과 선언 반응 1구간")
	if scenes.is_empty():
		return
	var management_scene_count := 0
	var declaration_scene_count := 0
	var declarations := {"rival_pact": 0, "castle_oath": 0, "grand_armistice_request": 0}
	for scene_value in scenes:
		var scene: Dictionary = scene_value
		var trigger := str(scene.get("trigger", ""))
		if trigger == "management_entered":
			management_scene_count += 1
			_expect(scene.get("cues", []).size() <= 44, "%s는 최대 44줄의 건너뛰기 경계" % str(scene.get("id", "")))
		elif trigger == "day29_declaration_selected":
			declaration_scene_count += 1
		for cue_value in scene.get("cues", []):
			var cue: Dictionary = cue_value
			for clause_value in cue.get("conditions", {}).get("all", []):
				var clause: Dictionary = clause_value
				if str(clause.get("fact", "")) == "day29_declaration":
					var value := str(clause.get("value", ""))
					declarations[value] = int(declarations.get(value, 0)) + 1
	_expect(management_scene_count == 3 and declaration_scene_count == 1, "DAY 29 trigger가 전야 3개와 선언 반응 1개로 분리")
	for declaration_id in declarations.keys():
		_expect(int(declarations[declaration_id]) == 7, "DAY 29 %s 반응 대사 7개 연결" % str(declaration_id))


func _validate_day30(day_data: Dictionary) -> void:
	var combat_scene_count := 0
	var ending_cues := 0
	var endings_seen := {}
	for scene_value in day_data.get("scenes", []):
		var scene: Dictionary = scene_value
		if str(scene.get("trigger", "")) == "combat_time":
			combat_scene_count += 1
			_expect(scene.get("cues", []).size() <= 4, "%s 전투 대화는 최대 4줄" % str(scene.get("id", "")))
		if str(scene.get("id", "")) != "STORY_D30_ENDING":
			continue
		_expect(str(scene.get("trigger", "")) == "ending_entered", "DAY 30 후일담은 엔딩 화면 직전 trigger")
		for cue_value in scene.get("cues", []):
			var cue: Dictionary = cue_value
			ending_cues += 1
			var clauses: Array = cue.get("conditions", {}).get("all", [])
			if not clauses.is_empty():
				var first_clause: Dictionary = clauses[0]
				var ending_id := str(first_clause.get("value", ""))
				if ENDING_IDS.has(ending_id):
					endings_seen[ending_id] = int(endings_seen.get(ending_id, 0)) + 1
	_expect(combat_scene_count <= 8, "DAY 30 전투 대화 정지 지점 최대 8개")
	_expect(ending_cues == 50, "기본 엔딩 5종 대사 50줄 수록")
	for ending_id in ENDING_IDS.keys():
		_expect(int(endings_seen.get(ending_id, 0)) == 10, "%s 선택 엔딩 10줄 조건 연결" % str(ending_id))


func _load_json(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_error("JSON 파일 없음: %s" % file_path)
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file_path)) != OK or not (parser.data is Dictionary):
		push_error("JSON 파싱 실패: %s" % file_path)
		return {}
	return parser.data


func _expect(condition_value: bool, label: String) -> void:
	assertion_count += 1
	if condition_value:
		return
	failed = true
	push_error("  FAIL · %s" % label)


func _finish() -> void:
	print("V122_STORY_DAY06_TO_30_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)
