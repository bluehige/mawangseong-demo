extends Node

const OnboardingFlowScript = preload("res://scripts/systems/tutorial/OnboardingFlow.gd")

const REQUIRED_DEMO_CHARACTERS = [
	"CHR_DARKLORD_PLAYER",
	"CHR_BATI",
	"CHR_GOLDIN",
	"CHR_PUDDING",
	"CHR_GOB",
	"CHR_PYNN",
	"CHR_EXPLORER_MILO",
	"CHR_THIEF_NIA",
	"CHR_HERO_LEON"
]

var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DataRegistry.load_all()
	_expect(not DataRegistry.characters.is_empty(), "characters JSON loads")
	for character_id in REQUIRED_DEMO_CHARACTERS:
		_validate_character(character_id)

	var flow = OnboardingFlowScript.new()
	_expect(flow.load(), "onboarding flow loads")
	var speaker_emotions = _collect_speaker_emotions(flow.data)
	for speaker_id in speaker_emotions.keys():
		if speaker_id == "NARRATOR":
			continue
		var character = DataRegistry.character(speaker_id)
		_expect(not character.is_empty(), "%s has character metadata" % speaker_id)
		var portrait: Dictionary = character.get("portrait", {})
		var observed: Array = portrait.get("observed_emotions", [])
		for emotion in speaker_emotions[speaker_id]:
			if emotion == "" or emotion == "none":
				continue
			_expect(observed.has(emotion), "%s classifies emotion '%s'" % [speaker_id, emotion])

	if failed:
		print("CHARACTER_DATA_SMOKE_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("CHARACTER_DATA_SMOKE_TEST: PASS")
		get_tree().quit(0)

func _validate_character(character_id: String) -> void:
	var character = DataRegistry.character(character_id)
	_expect(not character.is_empty(), "%s classified" % character_id)
	_expect(str(character.get("category", "")) != "", "%s has category" % character_id)
	_expect(str(character.get("species_group", "")) != "", "%s has species_group" % character_id)
	_expect(str(character.get("implementation_scope", "")) != "", "%s has implementation_scope" % character_id)

	var portrait: Dictionary = character.get("portrait", {})
	_expect(not portrait.is_empty(), "%s has portrait metadata" % character_id)
	var base_path = str(portrait.get("base", ""))
	_expect(base_path != "", "%s has base portrait path" % character_id)
	_expect(ResourceLoader.exists(base_path) or FileAccess.file_exists(base_path), "%s base portrait file exists" % character_id)
	_expect(str(portrait.get("accent", "")) != "", "%s has portrait accent" % character_id)
	_expect(not portrait.get("observed_emotions", []).is_empty(), "%s has observed emotions" % character_id)

	var unit_ref = character.get("unit_ref", null)
	if unit_ref is Dictionary:
		var dataset = str(unit_ref.get("dataset", ""))
		var unit_id = str(unit_ref.get("id", ""))
		match dataset:
			"monsters":
				_expect(not DataRegistry.monster(unit_id).is_empty(), "%s references monster '%s'" % [character_id, unit_id])
			"enemies":
				_expect(not DataRegistry.enemy(unit_id).is_empty(), "%s references enemy '%s'" % [character_id, unit_id])
			_:
				_expect(false, "%s has supported unit_ref dataset" % character_id)

func _collect_speaker_emotions(data: Dictionary) -> Dictionary:
	var result = {}
	for line in data.get("dialogue", []):
		if not (line is Dictionary):
			continue
		var speaker_id = str(line.get("speaker", ""))
		if speaker_id == "":
			continue
		if not result.has(speaker_id):
			result[speaker_id] = []
		var emotion = str(line.get("emotion", ""))
		if not result[speaker_id].has(emotion):
			result[speaker_id].append(emotion)
	return result

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		push_error("FAIL: %s" % message)
		failed = true
