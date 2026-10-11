extends "res://tools/tests/PlayerFeedbackHotfixTest.gd"

# Runtime observation only: no wave, stat, AI, timer or save changes.
func run() -> void:
	expect(ProjectSettings.globalize_path("user://").contains("idle_measure"), "isolated idle measurement data")
	if not failures.is_empty(): get_tree().quit(1); return
	game = GameRootScene.instantiate()
	add_child(game)
	await settle()
	game.continuity.acknowledge_update()
	game._onboarding_reset_game()
	GameState.player_name = "Idle Measure"
	game.story_director.cancel_active_scene()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	GameState.onboarding_complete = true
	GameState.day = 12
	game._set_campaign_save_path_for_tests("user://measurement-unused.json")
	game.story_feature_enabled = false
	game.combat_scene.start_combat()
	game.combat_scene.set_speed(3.0)
	game.campaign_autosave_pending = false
	var gaps: Array = []
	var gap_start := -1.0
	var start := Time.get_ticks_msec()
	while game.current_screen == Constants.SCREEN_COMBAT and game.combat_time < 90.0 and Time.get_ticks_msec() - start < 40000:
		await get_tree().physics_frame
		var alive := false
		for enemy in game.enemy_units:
			if is_instance_valid(enemy) and enemy.is_alive(): alive = true; break
		var idle: bool = not alive and not game.wave_manager.is_done()
		if idle and gap_start < 0.0: gap_start = game.combat_time
		if not idle and gap_start >= 0.0:
			gaps.append({"start_sim_seconds": gap_start, "duration_sim_seconds": game.combat_time - gap_start})
			gap_start = -1.0
	if gap_start >= 0.0: gaps.append({"start_sim_seconds": gap_start, "duration_sim_seconds": game.combat_time - gap_start})
	var result := {"fixture": "fresh roster at DAY12; story disabled for combat-only observation; x3", "duration_sim_seconds": game.combat_time, "duration_real_seconds": (Time.get_ticks_msec() - start) / 1000.0, "spawned": game.spawned_count, "scheduled": game.wave_manager.total_to_spawn, "final_screen": game.current_screen, "enemy_free_future_wave_gaps": gaps, "compression": "NOT_ENABLED"}
	print("IDLE_MEASUREMENT ", JSON.stringify(result))
	var file := FileAccess.open("user://idle-measurement.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	expect(game.spawned_count > 0, "actual wave and actor runtime observed")
	game.queue_free()
	await settle()
	print("CombatIdleMeasureTest: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
