extends "res://tools/tests/PlayerFeedbackHotfixTest.gd"
var scene_count := 0
var actors: Array = []
var enemy: Node

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"), "isolated automatic-action userdata")
	if not failures.is_empty(): get_tree().quit(1); return
	DataRegistry.load_all()
	UISettings.reset_skill_cutscene_history(false)
	var baseline: Dictionary = await _case("off", false)
	var once_first: Dictionary = await _case("once", true)
	var once_seen: Dictionary = await _case("once", false)
	var always: Dictionary = await _case("always", true)
	expect(baseline == once_first and baseline == once_seen and baseline == always, "same fixed logical step yields identical complete automatic outcomes across policies")
	await _case("always", true, true)
	print("SKILL_ACTION_AUTOMATIC_FRAME_TEST: %s (%d checks; %d failures)" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _setup(policy: String) -> void:
	UISettings.set_skill_cutscene_policy(policy, false)
	game = GameRootScene.instantiate()
	add_child(game)
	await settle()
	game.continuity.acknowledge_update()
	game._set_campaign_save_path_for_tests("")
	game._onboarding_reset_game()
	game._onboarding_enter_management_day(1, true)
	game._debug_skip_onboarding()
	game.story_feature_enabled = false
	game.campaign_save_enabled = false
	game.campaign_autosave_pending = false
	game.set_physics_process(false)
	game.set_process(false)
	for actor in game.monster_units + game.enemy_units:
		if is_instance_valid(actor): actor.queue_free()
	game.monster_units.clear()
	game.enemy_units.clear()
	actors.clear()
	for species in ["goblin", "imp"]:
		var actor = game._create_unit(species, DataRegistry.monster(species), Constants.FACTION_MONSTER, "entrance")
		actor.global_position = Vector2(600 if species == "goblin" else 570, 430)
		actor.attack_cooldown = 100.0
		actor.set_physics_process(false)
		actors.append(actor)
		game.monster_units.append(actor)
	enemy = game._create_unit("explorer", DataRegistry.enemy("explorer"), Constants.FACTION_ENEMY, "entrance")
	enemy.global_position = Vector2(630, 430)
	enemy.hp = 10000
	enemy.max_hp = 10000
	enemy.attack_cooldown = 100.0
	enemy.set_physics_process(false)
	game.enemy_units = [enemy]
	GameState.mana = 500
	game.combat_time = 0.0
	game.combat_scene.requested_pause = false
	game._set_screen(Constants.SCREEN_COMBAT, false)
	game.combat_scene.set_speed(1.0)
	game.selected_unit = actors[0]
	await settle()
	for actor in actors + [enemy]: actor.set_physics_process(true)

func _case(policy: String, expect_scenes: bool, change_speed: bool = false) -> Dictionary:
	await _setup(policy)
	var combat = game.combat_scene
	var original_delta := 0.125
	scene_count = 0
	game._physics_process(original_delta)
	var speed_requested := false
	var guard := 0
	while combat.skill_actions.is_active() or combat.has_suspended_frame():
		guard += 1
		if guard > 10:
			expect(false, "bounded two-caster continuation terminates")
			break
		expect(is_equal_approx(game.combat_time, original_delta), "suspension never reapplies original frame time")
		if combat.skill_actions.is_active():
			scene_count += 1
			expect(int(combat.suspended_frame.index) == scene_count, "AI resumes from the next actor rather than replaying one")
			if change_speed and not speed_requested:
				combat.set_speed(3.0)
				speed_requested = true
				expect(game.combat_speed == 1.0 and combat.deferred_combat_speed == 3.0, "speed change waits until original logical frame completes")
			combat.skill_actions.tick(0.55)
			combat.skill_actions.tick(0.46)
		if combat.has_suspended_frame(): game._physics_process(0.999) # Deliberately different: must resume saved0.125.
	for actor in actors + [enemy]:
		actor.set_physics_process(false)
		actor._physics_process(0.999 if expect_scenes else original_delta)
		expect(is_equal_approx(actor.attack_cooldown, 100.0 - original_delta), "each actor advances the saved delta exactly once")
	expect(scene_count == (2 if expect_scenes else 0), policy + " expected first/seen/always scene count")
	expect(is_equal_approx(game.combat_time, original_delta), "root logical clock advances once for the original step")
	expect(actors[0].skill_cooldowns.has("quick_slash") and actors[1].skill_cooldowns.has("fireball"), "both real automatic skills execute")
	var hp_before_projectile: int = enemy.hp
	await get_tree().create_timer(0.18).timeout
	expect(enemy.hp < hp_before_projectile and combat.contact_feedback_events.size() == 2, "original projectile arrival adds one actual hit without early scene damage")
	var before: int = enemy.hp
	await get_tree().create_timer(0.10).timeout
	expect(enemy.hp == before, "projectile callback does not repeat")
	if change_speed: expect(game.combat_speed == 3.0, "deferred speed selected during hold persists after resume")
	var result := {"hp": enemy.hp, "mana": GameState.mana, "combat_time": game.combat_time, "goblin_cd": actors[0].skill_cooldowns.duplicate(), "imp_cd": actors[1].skill_cooldowns.duplicate(), "goblin_attack_cd": actors[0].attack_cooldown, "imp_attack_cd": actors[1].attack_cooldown, "enemy_attack_cd": enemy.attack_cooldown, "damage_events": []}
	for event in combat.contact_feedback_events: result.damage_events.append([event.get("damage"), event.get("contact_kind")])
	print("AUTO_FRAME_RESULT ", policy, " ", JSON.stringify(result), " scenes=", scene_count)
	game.queue_free()
	await settle()
	return result
