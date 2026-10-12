extends "res://tools/tests/CombatPresentationPrototypeTest.gd"
var shots: Array[Dictionary] = []

func _capture_numbers() -> void:
	output_dir = "res://tmp/skill_action_manual"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var combat = game.combat_scene
	var action = combat.skill_actions
	reset_feedback()
	combat.requested_pause = false
	combat.set_speed(1.0)
	for unit in game.monster_units + game.enemy_units: unit.set_physics_process(false)
	UISettings.set_skill_cutscene_policy("always", false)
	UISettings.reset_skill_cutscene_history(false)
	game.selected_unit = units.goblin
	units.goblin.skill_cooldowns.clear()
	GameState.mana = 500
	var hp_before: int = enemy.hp
	var combat_time: float = game.combat_time
	var commits_before: int = action.commits
	expect(combat.request_selected_skill(0), "manual action accepted")
	expect(action.is_active() and game.combat_paused, "action owns a simulation hold")
	expect(enemy.hp == hp_before and GameState.mana == 500 and units.goblin.skill_cooldowns.is_empty(), "preparation has no early damage mana or cooldown")
	expect(not combat.request_selected_skill(0), "rapid duplicate request cannot commit again")
	await get_tree().create_timer(0.07).timeout
	await _raw_shot("01_prepare")
	expect(enemy.hp == hp_before, "preparation frame remains before impact")
	await get_tree().create_timer(0.20).timeout
	await _raw_shot("02_attack")
	expect(enemy.hp == hp_before and action.actors[0].animation == "attack_down", "actual existing attack frames precede damage")
	game.selected_unit = units.imp
	await get_tree().create_timer(0.30).timeout
	await _raw_shot("03_impact")
	expect(enemy.hp < hp_before and combat.contact_feedback_events.size() == 1, "one real contact at action impact")
	expect(game.selected_unit == units.imp and units.goblin.skill_cooldowns.has("quick_slash") and units.imp.skill_cooldowns.is_empty(), "prepared caster is independent of later selection")
	expect(game.combat_time == combat_time, "presentation never advances combat logical time")
	await get_tree().create_timer(0.48).timeout
	expect(not action.is_active() and not game.combat_paused, "short action finishes and restores simulation ownership")
	expect(action.commits == commits_before + 1 and bool(UISettings.skill_cutscene_seen.get("skill:quick_slash", false)), "one completed commit records the skill ID")
	UISettings.skill_cutscene_seen.clear()
	UISettings._load_settings()
	expect(bool(UISettings.skill_cutscene_seen.get("skill:quick_slash", false)), "viewed record survives a real settings reload")
	var expected := {"damage": hp_before - enemy.hp, "mana": GameState.mana, "cooldowns": units.goblin.skill_cooldowns.duplicate()}
	print("MANUAL_EQUIVALENCE_EXPECTED ", JSON.stringify(expected))
	for policy in ["off", "once", "always"]:
		reset_feedback()
		game.selected_unit = units.goblin
		units.goblin.skill_cooldowns.clear()
		GameState.mana = 500
		UISettings.set_skill_cutscene_policy(policy, false)
		expect(combat.request_selected_skill(0), policy + " same valid request")
		if action.is_active(): action.skip()
		print("MANUAL_EQUIVALENCE_ACTUAL ", policy, " ", JSON.stringify({"damage": hp_before - enemy.hp, "mana": GameState.mana, "cooldowns": units.goblin.skill_cooldowns.duplicate()}))
		expect({"damage": hp_before - enemy.hp, "mana": GameState.mana, "cooldowns": units.goblin.skill_cooldowns.duplicate()} == expected, policy + " same logical damage mana cooldown outcome")
	reset_feedback()
	UISettings.set_skill_cutscene_policy("always", false)
	UISettings.reset_skill_cutscene_history(false)
	game.selected_unit = units.goblin
	units.goblin.skill_cooldowns.clear()
	GameState.mana = 500
	expect(combat.request_selected_skill(0), "menu interruption action accepted")
	game._open_pause_menu()
	expect(not action.is_active() and game.combat_paused and enemy.hp < hp_before and combat.contact_feedback_events.size() == 1, "menu interrupt commits once and retains its own pause")
	expect(not UISettings.skill_cutscene_seen.has("skill:quick_slash"), "interrupted scene is not recorded as viewed")
	game._close_pause_menu()
	for unit in game.monster_units + game.enemy_units: unit.set_physics_process(false)
	expect(not game.combat_paused, "menu return does not inherit a stale presentation pause")
	reset_feedback()
	game.selected_unit = units.goblin
	units.goblin.skill_cooldowns.clear()
	GameState.mana = 500
	expect(combat.request_selected_skill(0), "user-pause ownership action accepted")
	combat.set_pause_state(true, false)
	var age: float = action.age
	await get_tree().create_timer(0.20).timeout
	expect(action.age == age and enemy.hp == hp_before, "user pause freezes presentation and pending gameplay")
	combat.set_pause_state(false, false)
	action.skip()
	for unit in game.monster_units + game.enemy_units: unit.set_physics_process(false)
	expect(enemy.hp < hp_before and not action.is_active(), "explicit skip commits once after pause")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for locale in ["ko", "en", "zh_CN"]:
		LanguageSettings.set_locale(locale, false)
		game._open_settings_screen()
		game._select_settings_category("combat")
		expect(game.ui_layer.find_child("SkillCutscenePolicyOption", true, false) != null and game.ui_layer.find_child("SkillCutsceneHistoryResetButton", true, false) != null, locale + " new policy and history reset visible")
		await capture("settings_" + locale)
		game._cancel_settings_changes()
	LanguageSettings.set_locale("ko", false)
	for shot in shots:
		expect(shot.image.save_png(output_dir.path_join(str(shot.name) + ".png")) == OK, "actual action raw frame saved")
	var report := []
	for shot in shots: report.append({"name": shot.name, "age": shot.age, "actor_animation": shot.actor_animation, "actor_frame": shot.actor_frame, "hp": shot.hp})
	var file := FileAccess.open(output_dir.path_join("first-action-frames.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("FIRST_MANUAL_SKILL_ACTION: preparation / existing attack frames / real impact / persistent policy checked")

func _raw_shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var action = game.combat_scene.skill_actions
	if not action.is_active():
		expect(false, "action still active at capture " + name)
		return
	shots.append({"name": name, "image": get_viewport().get_texture().get_image(), "age": action.age, "actor_animation": str(action.actors[0].animation), "actor_frame": action.actors[0].frame, "hp": enemy.hp})
