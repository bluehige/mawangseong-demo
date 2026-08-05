extends Node

const GameRootScript = preload("res://scripts/game/GameRoot.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const AudioCatalogApiScript = preload("res://scripts/audio/AudioCatalogApi.gd")
const MusicStateResolverScript = preload("res://scripts/audio/MusicStateResolver.gd")
const UnitActorScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_check_music_state_resolution()
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
		_expect(stream is AudioStreamWAV and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "music state stream uses imported forward loop")
		if stream != null:
			paths[stream.resource_path] = true
	_expect(paths.size() == 3, "management, normal combat, and boss combat use distinct files")
	var final_music_states := [
		MusicStateResolverScript.STATE_TITLE,
		MusicStateResolverScript.STATE_COMBAT_LATE_RISK,
		MusicStateResolverScript.STATE_FINAL_ENDING
	]
	var final_music_paths := {}
	for state_id in final_music_states:
		var stream = game._music_stream_for_state(state_id)
		_expect(stream != null, "%s music resolves from the approved catalog" % state_id)
		_expect(stream != null and stream.get_length() > 96.0, "%s music is long-form audio" % state_id)
		_expect(stream is AudioStreamWAV and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s music uses an imported forward loop" % state_id)
		var event_id := MusicStateResolverScript.event_for_state(state_id)
		var resolved := AudioCatalogApiScript.resolve_event(event_id)
		final_music_paths[str(resolved.get("runtime_path", ""))] = true
	_expect(final_music_paths.size() == 3, "title, late-risk, and final states use three distinct approved tracks")
	var ambience_event := AudioCatalogApiScript.find_event(GameRootScript.STAGE01_AMBIENCE_EVENT_ID)
	_expect(str(ambience_event.get("asset_id", "")) == GameRootScript.STAGE01_AMBIENCE_ASSET_ID, "Stage 01 ambience event resolves to the catalog asset")
	_expect(str(ambience_event.get("runtime_status", "")) == "connected", "Stage 01 ambience event is marked connected")
	var stage02_ambience_event := AudioCatalogApiScript.find_event(GameRootScript.STAGE02_AMBIENCE_EVENT_ID)
	_expect(str(stage02_ambience_event.get("asset_id", "")) == GameRootScript.STAGE02_AMBIENCE_ASSET_ID, "Stage 02 ambience event resolves to the catalog asset")
	_expect(str(stage02_ambience_event.get("runtime_status", "")) == "connected", "Stage 02 ambience event is marked connected")
	var stage03_ambience_event := AudioCatalogApiScript.find_event(GameRootScript.STAGE03_AMBIENCE_EVENT_ID)
	_expect(str(stage03_ambience_event.get("asset_id", "")) == GameRootScript.STAGE03_AMBIENCE_ASSET_ID, "Stage 03 ambience event resolves to the catalog asset")
	_expect(str(stage03_ambience_event.get("runtime_status", "")) == "connected", "Stage 03 ambience event is marked connected")
	var stage04_ambience_event := AudioCatalogApiScript.find_event(GameRootScript.STAGE04_AMBIENCE_EVENT_ID)
	_expect(str(stage04_ambience_event.get("asset_id", "")) == GameRootScript.STAGE04_AMBIENCE_ASSET_ID, "Stage 04 ambience event resolves to the catalog asset")
	_expect(str(stage04_ambience_event.get("runtime_status", "")) == "connected", "Stage 04 ambience event is marked connected")

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
	await _check_runtime_music_transport()

	if failed:
		print("MUSIC_STATE_AUDIO_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("MUSIC_STATE_AUDIO_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _check_music_state_resolution() -> void:
	_expect(
		MusicStateResolverScript.resolve({"screen": "title"}) == MusicStateResolverScript.STATE_TITLE,
		"title screen resolves the title music state"
	)
	_expect(
		MusicStateResolverScript.resolve({"screen": "management", "management_screen": true}) == MusicStateResolverScript.STATE_MANAGEMENT,
		"management screen resolves the management music state"
	)
	_expect(
		MusicStateResolverScript.resolve({"screen": "combat", "battle_screen": true}) == MusicStateResolverScript.STATE_COMBAT_NORMAL,
		"ordinary battle resolves normal combat music"
	)
	_expect(
		MusicStateResolverScript.resolve({"screen": "combat", "battle_screen": true, "late_wave": true}) == MusicStateResolverScript.STATE_COMBAT_LATE_RISK,
		"explicit late-wave state resolves late-risk music"
	)
	_expect(
		MusicStateResolverScript.resolve({"screen": "combat", "battle_screen": true, "high_risk": true}) == MusicStateResolverScript.STATE_COMBAT_LATE_RISK,
		"explicit high-risk state resolves late-risk music"
	)
	_expect(
		MusicStateResolverScript.resolve({"screen": "combat", "battle_screen": true, "late_wave": true, "has_boss": true}) == MusicStateResolverScript.STATE_COMBAT_BOSS,
		"boss music takes priority over late-risk music"
	)
	_expect(
		MusicStateResolverScript.resolve({"screen": "combat", "battle_screen": true, "final_battle": true, "has_boss": true}) == MusicStateResolverScript.STATE_FINAL_ENDING,
		"explicit final battle takes priority over boss music"
	)
	_expect(
		MusicStateResolverScript.resolve({"screen": "combat", "battle_screen": true, "day": 30, "final_battle": false}) == MusicStateResolverScript.STATE_COMBAT_NORMAL,
		"day 30 alone does not select final music without the final-battle flag"
	)
	_expect(
		MusicStateResolverScript.resolve({"screen": "ending"}) == MusicStateResolverScript.STATE_FINAL_ENDING,
		"ending screen resolves final and ending music"
	)
	_expect(MusicStateResolverScript.is_late_wave(6, 10) == false, "wave progress before 70 percent is not late")
	_expect(MusicStateResolverScript.is_late_wave(7, 10), "wave progress at 70 percent is late")
	_expect(MusicStateResolverScript.is_late_wave(1, 1) == false, "short one-enemy battles do not become late-risk battles")
	_expect(
		MusicStateResolverScript.event_for_state(MusicStateResolverScript.STATE_COMBAT_BOSS) == "music.combat.boss",
		"boss state maps to the catalog event contract"
	)


func _check_runtime_music_transport() -> void:
	var runtime_game = GameRootScene.instantiate()
	add_child(runtime_game)
	await get_tree().process_frame
	runtime_game.set_process(false)
	runtime_game.set_physics_process(false)
	runtime_game.onboarding_enabled = false
	runtime_game.current_screen = Constants.SCREEN_MANAGEMENT
	_expect(runtime_game.combat_music_secondary_player != null, "runtime music has a secondary crossfade player")
	_expect(runtime_game.combat_music_preview_player != null, "runtime music has a settings preview player")
	_expect(runtime_game.stage_ambience_player != null, "runtime Stage 01 ambience has a dedicated player")
	_expect(runtime_game.stage_ambience_player != null and runtime_game.stage_ambience_player.stream != null, "runtime Stage 01 ambience resolves its catalog stream")
	_expect(runtime_game.stage_ambience_player != null and runtime_game.stage_ambience_player.bus == AudioSettings.AMBIENCE_BUS, "Stage 01 ambience uses the Ambience bus")
	runtime_game.current_screen = Constants.SCREEN_MANAGEMENT
	runtime_game.castle_art_stage = GameRootScript.CASTLE_STAGE_ONE_ID
	runtime_game._update_stage_ambience()
	await get_tree().process_frame
	var ambience_player = runtime_game.stage_ambience_player
	var stage01_stream = ambience_player.stream
	_expect(ambience_player.playing, "Stage 01 ambience starts on a world-render screen")
	runtime_game._update_stage_ambience()
	_expect(runtime_game.stage_ambience_player == ambience_player and ambience_player.playing, "repeated Stage 01 ambience updates do not duplicate playback")
	runtime_game.current_screen = Constants.SCREEN_SETTINGS
	runtime_game._update_stage_ambience()
	_expect(not ambience_player.playing, "Stage 01 ambience stops outside world-render screens")
	runtime_game.current_screen = Constants.SCREEN_MANAGEMENT
	runtime_game._update_stage_ambience()
	_expect(ambience_player.playing, "Stage 01 ambience resumes when returning to a world-render screen")
	runtime_game.castle_art_stage = GameRootScript.CASTLE_STAGE_TWO_ID
	runtime_game._update_stage_ambience()
	await get_tree().process_frame
	var stage02_stream = runtime_game.stage_ambience_player.stream
	_expect(stage02_stream != null and stage02_stream != stage01_stream, "Stage 02 ambience swaps to its own catalog stream")
	_expect(runtime_game.stage_ambience_player.playing, "Stage 02 ambience starts on a world-render screen")
	_expect(runtime_game.stage_ambience_player.bus == AudioSettings.AMBIENCE_BUS, "Stage 02 ambience uses the Ambience bus")
	runtime_game._update_stage_ambience()
	_expect(runtime_game.stage_ambience_player.stream == stage02_stream and runtime_game.stage_ambience_player.playing, "repeated Stage 02 ambience updates do not duplicate playback")
	runtime_game.castle_art_stage = GameRootScript.CASTLE_STAGE_THREE_ID
	runtime_game._update_stage_ambience()
	await get_tree().process_frame
	var stage03_stream = runtime_game.stage_ambience_player.stream
	_expect(stage03_stream != null and stage03_stream != stage02_stream, "Stage 03 ambience swaps to its own catalog stream")
	_expect(runtime_game.stage_ambience_player.playing, "Stage 03 ambience starts on a world-render screen")
	_expect(runtime_game.stage_ambience_player.bus == AudioSettings.AMBIENCE_BUS, "Stage 03 ambience uses the Ambience bus")
	runtime_game._update_stage_ambience()
	_expect(runtime_game.stage_ambience_player.stream == stage03_stream and runtime_game.stage_ambience_player.playing, "repeated Stage 03 ambience updates do not duplicate playback")
	runtime_game.castle_art_stage = GameRootScript.CASTLE_STAGE_FOUR_ID
	runtime_game._update_stage_ambience()
	await get_tree().process_frame
	var stage04_stream = runtime_game.stage_ambience_player.stream
	_expect(stage04_stream != null and stage04_stream != stage03_stream, "Stage 04 ambience swaps to its own catalog stream")
	_expect(runtime_game.stage_ambience_player.playing, "Stage 04 ambience starts on a world-render screen")
	_expect(runtime_game.stage_ambience_player.bus == AudioSettings.AMBIENCE_BUS, "Stage 04 ambience uses the Ambience bus")
	runtime_game._update_stage_ambience()
	_expect(runtime_game.stage_ambience_player.stream == stage04_stream and runtime_game.stage_ambience_player.playing, "repeated Stage 04 ambience updates do not duplicate playback")

	runtime_game._stop_combat_music()
	runtime_game._kill_combat_music_tween()
	for player in [runtime_game.combat_music_player, runtime_game.combat_music_secondary_player]:
		if player != null:
			player.stop()
	runtime_game.current_screen = Constants.SCREEN_COMBAT
	runtime_game._start_combat_music(GameRootScript.COMBAT_MUSIC)
	await get_tree().process_frame
	var combat_player = runtime_game.combat_music_player
	_expect(combat_player != null and combat_player.playing, "combat transition starts the target music player")
	_expect(combat_player != null and combat_player.stream.resource_path == GameRootScript.COMBAT_MUSIC.resource_path, "combat transition selects normal combat music")
	runtime_game._start_combat_music(GameRootScript.COMBAT_MUSIC)
	await get_tree().process_frame
	_expect(runtime_game.combat_music_player == combat_player, "same combat state does not replace the player")

	runtime_game.current_screen = Constants.SCREEN_MANAGEMENT
	runtime_game._start_combat_music(GameRootScript.MANAGEMENT_MUSIC)
	await get_tree().process_frame
	var management_player = runtime_game.combat_music_player
	_expect(management_player != combat_player, "state change swaps to the other music player")
	_expect(management_player.stream.resource_path == GameRootScript.MANAGEMENT_MUSIC.resource_path, "management transition selects castle music")
	_expect(runtime_game.combat_music_secondary_player.playing, "state change keeps the outgoing player during crossfade")
	await get_tree().create_timer(0.8).timeout
	_expect(not runtime_game.combat_music_secondary_player.playing, "crossfade stops the outgoing player after the fade")

	runtime_game._preview_music()
	var preview_player = runtime_game.combat_music_preview_player
	_expect(preview_player.playing and preview_player.stream == GameRootScript.MANAGEMENT_MUSIC, "settings preview starts the management music event")
	runtime_game._preview_music()
	_expect(runtime_game.combat_music_preview_player == preview_player and preview_player.playing, "repeated preview requests do not duplicate playback")
	await get_tree().create_timer(GameRootScript.COMBAT_MUSIC_PREVIEW_SECONDS + 0.2).timeout
	_expect(not preview_player.playing, "settings preview stops after the short preview window")
	runtime_game._shutdown_audio_for_exit()
	runtime_game.queue_free()
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % message)
		return
	failed = true
	push_error("  FAIL - %s" % message)
