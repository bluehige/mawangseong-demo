extends Node

const CombatSceneControllerScript = preload("res://scripts/game/CombatSceneController.gd")
const SKILL_IDS := [
	"slime_shield", "hold_corridor", "quick_slash", "loot_instinct", "fireball", "flame_zone",
	"false_footprints", "rumor_boost", "spore_mend", "cleansing_bloom", "rooted_guard", "stone_pulse",
	"war_rhythm", "steady_beat", "moon_mark", "scent_pursuit", "false_treasure", "vault_swap",
	"spectral_transfer", "haunted_broom_whirl", "scent_lock", "home_guard_bark", "carapace_ram", "patch_plates"
]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var paths := {}
	_expect(CombatSceneControllerScript.SKILL_SFX.size() == SKILL_IDS.size(), "direct combat skill cue count is 24")
	for skill_id in SKILL_IDS:
		var expected_path := "res://assets/audio/sfx/skills/%s.wav" % skill_id
		var stream: AudioStream = CombatSceneControllerScript.SKILL_SFX.get(skill_id)
		_expect(stream != null, "%s cue preloads" % skill_id)
		_expect(stream != null and stream.resource_path == expected_path, "%s cue maps to its own WAV" % skill_id)
		_expect(stream != null and stream.get_length() > 0.0, "%s cue has playable audio frames" % skill_id)
		paths[expected_path] = true
	_expect(paths.size() == SKILL_IDS.size(), "all direct skill cue paths are unique")

	if failed:
		print("SKILL_AUDIO_PALETTE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("SKILL_AUDIO_PALETTE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % message)
		return
	failed = true
	push_error("  FAIL - %s" % message)
