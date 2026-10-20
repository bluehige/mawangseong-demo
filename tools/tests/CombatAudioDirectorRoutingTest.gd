extends Node

const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const CombatSceneControllerScript = preload("res://scripts/game/CombatSceneController.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var runtime_game = GameRootScene.instantiate()
	add_child(runtime_game)
	await get_tree().process_frame
	runtime_game.set_process(false)
	runtime_game.set_physics_process(false)
	runtime_game.onboarding_enabled = false
	_expect(runtime_game.audio_director != null, "GameRoot provides AudioDirector to combat and HUD")

	var combat = runtime_game.combat_scene
	var hit_result: int = runtime_game.audio_director.active_voice_count()
	_expect(hit_result == 0, "combat audio starts with no one-shot voice")
	combat._play_sfx(CombatSceneControllerScript.SFX_HIT, "d3_hit", -11.0, 0.045, 1.0, 1.0)
	await get_tree().process_frame
	_expect(runtime_game.audio_director.active_voice_count() == 1, "combat hit uses the common catalog voice path")
	combat._play_sfx(CombatSceneControllerScript.SFX_HIT, "d3_hit", -11.0, 0.045, 1.0, 1.0)
	await get_tree().process_frame
	_expect(runtime_game.audio_director.active_voice_count() == 1, "combat cooldown prevents an immediate duplicate hit")
	runtime_game.audio_director.stop_all()

	combat._play_skill_sfx("fireball")
	await get_tree().process_frame
	_expect(runtime_game.audio_director.active_voice_count() == 1, "combat skill uses its catalog event through AudioDirector")
	_expect(runtime_game.audio_director.active_voice_ids().size() == 1, "combat skill creates exactly one voice")
	runtime_game.audio_director.stop_all()

	combat.council_objectives.alert("entrance")
	await get_tree().process_frame
	_expect(runtime_game.audio_director.active_voice_count()==1,"objective alert uses common catalog voice")
	combat.council_objectives.alert("entrance")
	await get_tree().process_frame
	_expect(runtime_game.audio_director.active_voice_count()==1,"repeated objective alert does not stack voices")
	combat.council_objectives.clear()
	await get_tree().process_frame
	_expect(runtime_game.audio_director.active_voice_count()==0,"objective cleanup releases its owned alert voice")
	runtime_game.queue_free()
	await get_tree().process_frame

	if failed:
		print("COMBAT_AUDIO_DIRECTOR_ROUTING_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("COMBAT_AUDIO_DIRECTOR_ROUTING_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % message)
		return
	failed = true
	push_error("  FAIL - %s" % message)
