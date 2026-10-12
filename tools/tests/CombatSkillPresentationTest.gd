extends "res://tools/tests/CombatPresentationPrototypeTest.gd"
const DamageScript = preload("res://scripts/combat/DamageService.gd")

func _capture_numbers() -> void:
	await _test_representative_skills()
	await _test_frame_completion()
	await super._capture_numbers()

func freeze_units() -> void:
	for unit in game.monster_units + game.enemy_units: unit.set_physics_process(false)

func _test_representative_skills() -> void:
	for speed in [1.0, 3.0]:
		for species in ["goblin", "imp", "slime"]:
			reset_feedback()
			game.combat_scene.set_pause_state(false, false)
			game.combat_scene.set_speed(speed)
			freeze_units()
			var actor: Node = units[species]
			actor.global_position = enemy.global_position + Vector2(-25, 0)
			actor.skill_cooldowns.clear()
			actor.skill_anim_timer = 0.0
			actor.presentation_skill_anim_timer = 0.0
			game.selected_unit = actor
			GameState.mana = 500
			var skill_id: String = DataRegistry.monster(species).skill_slots[0]
			var cost: int = game._current_skill_mana_cost(DataRegistry.skill(skill_id))
			var hp_before: int = enemy.hp
			var expected_slash: int = DamageScript.compute(actor, enemy, 1.9)
			expect(game.combat_scene._execute_selected_unit_skill(0), "real representative skill succeeds at x%.0f: %s" % [speed, skill_id])
			expect(GameState.mana == 500 - cost, "existing representative mana cost remains exact")
			expect(is_equal_approx(actor.skill_cooldowns[skill_id], float(DataRegistry.skill(skill_id).cooldown)), "existing representative cooldown remains exact")
			if species == "goblin":
				expect(enemy.hp == hp_before - expected_slash and contact_sum() == expected_slash, "slash real damage and contact event remain synchronous")
				expect(actor.skill_anim_timer == 0.0 and actor.presentation_skill_anim_timer > 0.0, "slash visual uses no interruption-facing skill timer")
				expect(actor.sprite.animation == "skill_down" and actor.sprite.frame == 2, "immediate slash starts on its contact pose")
			elif species == "imp":
				expect(enemy.hp == hp_before and game.combat_scene.contact_feedback_events.is_empty(), "fireball launch does not apply premature damage")
				expect(actor.skill_anim_timer == 0.0 and actor.presentation_skill_anim_timer > 0.0, "fireball visual timer stays separate from gameplay")
				await get_tree().create_timer(0.24 / speed + 0.06).timeout
				# SceneTree timers and tweens can cross their deadline on the same
				# slow rendered frame. Wait for the actual arrival, with a bound,
				# rather than assuming timer callback ordering is a combat result.
				var deadline := Time.get_ticks_msec() + 1000
				while enemy.hp == hp_before and Time.get_ticks_msec() < deadline:
					await get_tree().process_frame
				if enemy.hp != hp_before - 52 or game.combat_scene.contact_feedback_events.size() != 1:
					print("PROJECTILE_REVIEW: " + JSON.stringify({"speed":speed,"hp_before":hp_before,"hp_after":enemy.hp,"contacts":game.combat_scene.contact_feedback_events.size(),"damage":contact_sum()}))
				expect(enemy.hp == hp_before - 52 and game.combat_scene.contact_feedback_events.size() == 1 and contact_sum() == 52, "unchanged projectile arrival applies exactly one52-damage contact")
			else:
				expect(actor.skill_anim_timer > 0.0 and is_equal_approx(actor.damage_reduction, 0.4), "shield retains its original gameplay cast and40percent reduction")
				expect(enemy.hp == hp_before and game.combat_scene.contact_feedback_events.is_empty(), "defensive cast creates no fabricated damage")
			if DisplayServer.get_name() != "headless":
				await capture("skill_%s_x%d" % [skill_id, int(speed)])
	# Changing speed during a paused in-flight shot must not resume animation
	# or release its real damage callback before the original pause is lifted.
	reset_feedback()
	game.combat_scene.set_pause_state(false, false)
	freeze_units()
	game.combat_scene.set_speed(1.0)
	var hp_before: int = enemy.hp
	game.combat_scene._launch_damage_projectile(units.imp, enemy, 23, false, "basic")
	game.combat_scene.set_pause_state(true, false)
	game.combat_scene.set_speed(3.0)
	var paused_effect = game.combat_scene._make_effect_sprite("impact", false, 14.0)
	game.effect_root.add_child(paused_effect)
	expect(paused_effect.speed_scale == 0.0, "an effect created during pause starts frozen")
	await get_tree().create_timer(0.18).timeout
	expect(enemy.hp == hp_before, "paused projectile cannot resolve damage even after speed change")
	for effect in game.effect_root.get_children():
		if effect is AnimatedSprite2D: expect(effect.speed_scale == 0.0, "speed selection preserves paused VFX")
	game.combat_scene.set_pause_state(false, false)
	freeze_units()
	expect(paused_effect.speed_scale == 3.0, "new paused effect restores selected speed on resume")
	paused_effect.queue_free()
	await get_tree().create_timer(0.20).timeout
	expect(enemy.hp == hp_before - 23 and game.combat_scene.contact_feedback_events.size() == 1, "resume releases the original projectile callback once")

func _test_frame_completion() -> void:
	for speed in [1.0, 3.0]:
		reset_feedback()
		game.combat_scene.set_pause_state(false, false)
		freeze_units()
		game.combat_scene.set_speed(speed)
		game.combat_scene.spawn_effect_burst("goblin_ambush_captain", Vector2(700, 400))
		var sprite: AnimatedSprite2D
		for child in game.effect_root.get_children():
			if child is AnimatedSprite2D: sprite = child
		expect(sprite != null and sprite.sprite_frames.get_frame_count("play") == 4 and sprite.speed_scale == speed, "four-frame representative VFX uses the selected speed")
		var state := {"completed": false, "removed": false}
		sprite.animation_finished.connect(func(): state.completed = true)
		sprite.tree_exited.connect(func(): state.removed = true)
		await get_tree().create_timer(0.65 / speed + 0.12).timeout
		expect(bool(state.completed) and bool(state.removed), "x%.0f VFX completes all frames before removal" % speed)
	print("COMBAT_SKILL_PRESENTATION: representative skills / actual projectile / pause / x3 frames checked")
