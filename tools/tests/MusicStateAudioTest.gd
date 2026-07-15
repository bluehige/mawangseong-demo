extends Node

const GameRootScript = preload("res://scripts/game/GameRoot.gd")
const UnitActorScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var game = GameRootScript.new()
	var tracks := [
		GameRootScript.MANAGEMENT_MUSIC,
		GameRootScript.COMBAT_MUSIC,
		GameRootScript.COMBAT_BOSS_MUSIC
	]
	var paths := {}
	for stream in tracks:
		_expect(stream != null, "music state stream preloads")
		_expect(stream != null and stream.get_length() > 96.0, "music state stream is long-form audio")
		if stream != null:
			paths[stream.resource_path] = true
	_expect(paths.size() == 3, "management, normal combat, and boss combat use distinct files")

	game.enemy_units = []
	_expect(game._music_for_screen(Constants.SCREEN_MANAGEMENT) == GameRootScript.MANAGEMENT_MUSIC, "management screen selects castle management music")
	_expect(game._music_for_screen(Constants.SCREEN_COMBAT) == GameRootScript.COMBAT_MUSIC, "normal combat selects dungeon pressure music")

	var leon = UnitActorScript.new()
	leon.unit_id = "official_hero_leon"
	leon.hp = 1
	game.enemy_units.append(leon)
	_expect(game._music_for_screen(Constants.SCREEN_COMBAT) == GameRootScript.COMBAT_BOSS_MUSIC, "official Leon switches combat to boss music")
	leon.down = true
	_expect(game._music_for_screen(Constants.SCREEN_COMBAT) == GameRootScript.COMBAT_MUSIC, "defeated boss returns remaining combat to normal music")
	game.enemy_units.clear()
	leon.free()

	var brassa = UnitActorScript.new()
	brassa.unit_id = "rival_brassa_council_champion"
	brassa.hp = 1
	game.enemy_units.append(brassa)
	_expect(game._music_for_screen(Constants.SCREEN_COMBAT) == GameRootScript.COMBAT_BOSS_MUSIC, "data-driven rival boss tag switches combat to boss music")
	game.enemy_units.clear()
	brassa.free()
	game.free()

	if failed:
		print("MUSIC_STATE_AUDIO_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("MUSIC_STATE_AUDIO_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % message)
		return
	failed = true
	push_error("  FAIL - %s" % message)
