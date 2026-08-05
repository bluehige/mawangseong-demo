extends Node

const CombatSceneControllerScript = preload("res://scripts/game/CombatSceneController.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const CatalogScript = preload("res://scripts/audio/AudioCatalogApi.gd")
const UPDATE4_EVENT_ASSETS := {
	"update4.skill.stitch_stairway": "sfx_silky_stitch",
	"update4.skill.emergency_thread_pull": "sfx_silky_rescue",
	"update4.skill.night_relay": "sfx_popo_relay",
	"update4.skill.echo_alarm": "sfx_popo_alarm",
	"update4.crown.pudding_royal_bastion": "sfx_crown_pudding_ascend",
	"update4.crown.gob_midnight_marshal": "sfx_crown_gob_ascend",
	"update4.crown.pynn_castle_flame_sage": "sfx_crown_pynn_ascend",
	"update4.crown.mori_grand_mycelial_priest": "sfx_crown_mori_ascend",
	"update4.crown.toktok_royal_armorer": "sfx_crown_toktok_ascend",
	"update4.crown.popo_grand_night_courier": "sfx_crown_popo_ascend",
	"update4.rival.boss.brassa": "boss_brassa_motif",
	"update4.rival.boss.vesper": "boss_vesper_motif",
	"update4.rival.boss.mirella": "boss_mirella_motif"
}
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
	DataRegistry.load_all()
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
	_test_update4_catalog_routes()
	await _check_update4_runtime_routing()

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


func _test_update4_catalog_routes() -> void:
	CatalogScript.reset_for_test()
	for event_id_value in UPDATE4_EVENT_ASSETS.keys():
		var event_id := str(event_id_value)
		var expected_asset := str(UPDATE4_EVENT_ASSETS[event_id])
		var resolved: Dictionary = CatalogScript.resolve_event(event_id)
		_expect(not resolved.is_empty(), "%s catalog event resolves" % event_id)
		_expect(str(resolved.get("event", {}).get("asset_id", "")) == expected_asset, "%s maps to its data asset" % event_id)
		_expect(str(resolved.get("runtime_path", "")) != "" and FileAccess.file_exists(str(resolved.get("runtime_path", ""))), "%s has runtime audio file" % event_id)


func _check_update4_runtime_routing() -> void:
	var runtime_game = GameRootScene.instantiate()
	add_child(runtime_game)
	await get_tree().process_frame
	runtime_game.set_process(false)
	runtime_game.set_physics_process(false)
	runtime_game.onboarding_enabled = false
	_expect(runtime_game.audio_director != null, "GameRoot owns the common AudioDirector")

	var skill_result: Dictionary = runtime_game._play_update4_skill_sfx("echo_alarm", "d2-skill-token")
	await get_tree().process_frame
	_expect(bool(skill_result.get("accepted", false)), "Update 4 skill SFX is admitted through AudioDirector")
	_expect(runtime_game.audio_director.active_voice_count() == 1, "skill event creates one active voice")
	var skill_repeat: Dictionary = runtime_game._play_update4_skill_sfx("echo_alarm", "d2-skill-token")
	await get_tree().process_frame
	_expect(not bool(skill_repeat.get("accepted", true)), "same skill instance token is not played twice")
	_expect(str(skill_repeat.get("reason", "")) == "duplicate_voice", "duplicate skill is rejected by voice allocator")
	_expect(runtime_game.audio_director.active_voice_count() == 1, "duplicate skill does not add a second voice")
	runtime_game.audio_director.stop_all()

	var crown_result: Dictionary = runtime_game._play_update4_crown_sfx("crown_pudding_royal_bastion", "d2-crown-token")
	await get_tree().process_frame
	_expect(bool(crown_result.get("accepted", false)), "crown evolution SFX is admitted through catalog")
	_expect(runtime_game.audio_director.active_voice_count() == 1, "crown event creates one active voice")
	runtime_game.audio_director.stop_all()

	var boss_result: Dictionary = runtime_game._play_update4_boss_motif("rival_brassa_council_champion", "d2-boss-token")
	await get_tree().process_frame
	_expect(bool(boss_result.get("accepted", false)), "rival boss motif is admitted through catalog")
	_expect(runtime_game.audio_director.active_voice_count() == 1, "rival boss event creates one active voice")
	runtime_game.audio_director.stop_all()

	var update3_result: Dictionary = runtime_game._play_update3_sfx("boss_selen_motif", -12.0, "d2-update3-token")
	await get_tree().process_frame
	_expect(bool(update3_result.get("accepted", false)), "Update 3 warning is routed through AudioDirector")
	var update3_repeat: Dictionary = runtime_game._play_update3_sfx("boss_selen_motif", -12.0, "d2-update3-token")
	await get_tree().process_frame
	_expect(not bool(update3_repeat.get("accepted", true)), "Update 3 warning duplicate token is suppressed")
	_expect(runtime_game.audio_director.active_voice_count() == 1, "Update 3 duplicate warning does not add a voice")
	runtime_game.audio_director.stop_all()
	runtime_game.queue_free()
	await get_tree().process_frame
