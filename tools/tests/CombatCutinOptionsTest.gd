extends "res://tools/tests/CombatSkillPresentationTest.gd"

func _capture_numbers() -> void:
	await super._capture_numbers()
	await _test_modes_and_portraits()
	await _test_protection_and_settings()
	print("COMBAT_CUTIN_OPTIONS: actual casts / portraits / bounded queue / input / settings checked")

func _test_modes_and_portraits() -> void:
	var cut = game.combat_scene.skill_cutins
	var results := []
	for mode in ["off", "simple", "full"]:
		reset_feedback()
		game.combat_scene.set_pause_state(false, false)
		freeze_units()
		UISettings.set_reduce_combat_effects(false, false)
		UISettings.set_combat_cutin_mode(mode, false)
		game.selected_unit = units.goblin
		units.goblin.skill_cooldowns.clear()
		GameState.mana = 500
		var before: int = enemy.hp
		var combat_time: float = game.combat_time
		expect(game.combat_scene._execute_selected_unit_skill(0), mode + " actual slash succeeds")
		cut.tick(0.11)
		cut.tick(0.11)
		results.append([before - enemy.hp, GameState.mana, units.goblin.skill_cooldowns.duplicate(true)])
		expect(game.combat_time == combat_time and not game.combat_paused, mode + " cutin never advances or pauses simulation")
		if mode == "off":
			expect(cut.pending.is_empty() and cut.current.is_empty() and cut.panel == null, "off creates no extra cutin")
		else:
			expect(not cut.current.is_empty() and cut.current.mode == mode, mode + " has the requested presentation")
			expect(cut.panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "cutin panel ignores map input")
			for child in cut.panel.get_children():
				expect(child.mouse_filter == Control.MOUSE_FILTER_IGNORE and child.focus_mode == Control.FOCUS_NONE, "cutin child never captures input/focus")
			var text: Label = cut.panel.get_node("SkillCutinText")
			expect(text.get_line_count() * text.get_line_height() <= text.size.y + 2.0, "cutin label fits")
			await capture("cutin_mode_" + mode)
	expect(results[0] == results[1] and results[1] == results[2], "all three modes preserve identical actual damage mana and cooldowns")
	reset_feedback()
	UISettings.set_combat_cutin_mode("full", false)
	UISettings.set_reduce_combat_effects(true, false)
	cut.enqueue(units.goblin, "quick_slash")
	cut.tick(0.11)
	expect(cut.current.mode == "simple" and game.get_combat_vfx_accessibility().reduce_flash, "reduction downgrades cutin and enables existing flash reduction")
	game.combat_camera.offset = Vector2.ZERO
	game.combat_scene.camera_kick(8.0)
	expect(game.combat_camera.offset == Vector2.ZERO, "reduction disables camera shake without altering damage")
	UISettings.set_reduce_combat_effects(false, false)
	var roster: Dictionary = game.monster_roster.duplicate(true)
	game.first_promotion_completed = true
	GameState.day = 12
	for rule_id in DataRegistry.evolution_rules:
		reset_feedback()
		var rule: Dictionary = DataRegistry.evolution_rules[rule_id]
		var species: String = rule.monster_id
		game.monster_roster[species].promotion_id = rule_id
		game.monster_roster[species].level = 3
		var actor = game._create_unit(species, game._scaled_monster_stats(species), Constants.FACTION_MONSTER, "entrance")
		actor.set_physics_process(false)
		actor.global_position = Vector2(600, 430)
		game.selected_unit = actor
		cut.enqueue(actor, str(rule.skill_upgrade.skill_id))
		cut.tick(0.11)
		cut.tick(0.11)
		expect(not cut.current.is_empty() and cut.current.mode == "full", rule_id + " full cutin remains available")
		expect(str(cut.panel.get_meta("cutin_portrait_path")) == str(rule.portrait), rule_id + " uses the current promoted portrait")
		expect(cut.panel.get_node("SkillCutinArt").texture != null, rule_id + " portrait actually loads")
		if rule_id in ["goblin_ambush_captain", "imp_ember_shaman"]: await capture("cutin_" + rule_id)
		actor.queue_free()
	game.monster_roster = roster
	game.selected_unit = units.goblin
	var active_run_before: Dictionary = game.update4_active_run.duplicate(true)
	for crown_id in DataRegistry.update4_crown_evolutions:
		reset_feedback()
		var crown: Dictionary = DataRegistry.update4_crown_evolutions[crown_id]
		var species: String = crown.monster_id
		game.monster_roster = roster.duplicate(true)
		if not game.monster_roster.has(species): game.monster_roster[species] = roster.slime.duplicate(true)
		var inherited := ""
		if not crown.get("branch_inheritance", {}).is_empty(): inherited = str(crown.branch_inheritance.keys()[0])
		game.monster_roster[species].promotion_id = inherited
		game.monster_roster[species].level = 7
		var instance_id := ""
		for id in DataRegistry.monster_instances:
			if str(DataRegistry.monster_instances[id].get("species_id", "")) == species: instance_id = str(id); break
		game.update4_active_run = {"campaign_mode_id": "council_season", "crown": {"selected_instance_id": instance_id, "crown_form_id": crown_id}}
		var stats: Dictionary = game._scaled_monster_stats(species)
		expect(str(stats.get("crown_form_id", "")) == str(crown_id), str(crown_id) + " crown is actually active")
		var actor = game._create_unit(species, stats, Constants.FACTION_MONSTER, "entrance")
		actor.set_physics_process(false)
		actor.global_position = Vector2(600, 430)
		game.selected_unit = actor
		cut.enqueue(actor, "portrait_probe", {"display_name": "Current form"})
		cut.tick(0.11)
		cut.tick(0.11)
		expect(not cut.current.is_empty() and str(cut.panel.get_meta("cutin_portrait_path")) == str(crown.portrait), str(crown_id) + " cutin uses the active crown portrait")
		game.update4_active_run["upper_floor"] = {"crown_suppressed": true}
		cut.reset()
		cut.enqueue(actor, "portrait_probe", {"display_name": "Current form"})
		cut.tick(0.11)
		expect(not cut.current.is_empty() and str(cut.panel.get_meta("cutin_portrait_path")) == game.management_scene.monster_portrait_path(species), str(crown_id) + " suppression follows the canonical combat form")
		actor.queue_free()
	game.update4_active_run = active_run_before
	game.monster_roster = roster
	game.selected_unit = units.goblin
	reset_feedback()
	for index in range(20):
		cut.enqueue(units.goblin, "synthetic_cast_%d" % index, {"display_name": "Queue probe"})
	expect(cut.pending.size() <= 2 and cut.dropped > 0, "pending cutins are bounded under concurrent casts")
	cut.tick(0.11)
	var before_displayed: int = cut.displayed
	cut.tick(0.90)
	cut.enqueue(units.goblin, "quick_slash")
	cut.tick(0.10)
	expect(cut.displayed == before_displayed, "global presentation interval prevents repeated cutin spam")
	cut.tick(3.0)
	expect(cut.pending.is_empty(), "stale pending casts cannot build a presentation backlog")

func _test_protection_and_settings() -> void:
	var cut = game.combat_scene.skill_cutins
	reset_feedback()
	UISettings.set_combat_cutin_mode("full", false)
	cut.enqueue(units.goblin, "quick_slash")
	cut.enqueue(units.goblin, "quick_slash")
	expect(cut.pending.size() == 1, "same actual cast token is deduplicated")
	cut.tick(0.11)
	var focus_before = get_viewport().gui_get_focus_owner()
	expect(get_viewport().gui_get_focus_owner() == focus_before, "presentation has not grabbed focus")
	var speed_button: Button
	for button in game.ui_layer.find_children("*", "Button", true, false):
		if button.text == "x3": speed_button = button
	expect(speed_button != null, "existing x3 control remains available")
	if speed_button != null:
		await click(speed_button)
		expect(game.combat_speed == 3.0, "actual x3 button works during a cutin")
	game._open_pause_menu()
	expect(cut.current.is_empty() and cut.pending.is_empty() and game.combat_paused, "menu cancels presentation immediately and owns pause")
	game._close_pause_menu()
	freeze_units()
	expect(not game.combat_paused and cut.current.is_empty(), "menu return restores pause without replaying the cutin")
	game.story_combat_overlay_open = true
	expect(not cut.enqueue(units.goblin, "fireball"), "important subtitle/dialogue suppresses cutins")
	game.story_combat_overlay_open = false
	game.continuity.backlog_open = true
	expect(not cut.enqueue(units.goblin, "fireball"), "backlog suppresses cutins")
	game.continuity.backlog_open = false
	reset_feedback()
	cut.enqueue(units.goblin, "quick_slash")
	cut.tick(0.11)
	game._set_screen(Constants.SCREEN_TITLE, false)
	expect(cut.current.is_empty() and cut.pending.is_empty(), "title clears presentation state immediately")
	var original := UISettings.snapshot()
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await settle()
	for locale in ["ko", "en", "zh_CN"]:
		LanguageSettings.set_locale(locale, false)
		game._open_settings_screen()
		game._select_settings_category("combat")
		expect(game.ui_layer.find_child("CombatCutinModeOption", true, false) != null and game.ui_layer.find_child("CombatReducedEffectsOption", true, false) != null, locale + " both new settings are accessible")
		await capture("cutin_settings_" + locale)
		game._on_combat_cutin_preview_changed("off")
		game._on_combat_effects_preview_changed("reduced")
		game._cancel_settings_changes()
		expect(UISettings.combat_cutin_mode == original.combat_cutin_mode and UISettings.reduce_combat_effects == original.reduce_combat_effects, "cancel restores both pending options")
	LanguageSettings.set_locale("ko", false)
	game._open_settings_screen()
	game._select_settings_category("combat")
	game._on_combat_cutin_preview_changed("off")
	game._on_combat_effects_preview_changed("reduced")
	game._apply_settings_changes()
	UISettings.set_combat_cutin_mode("full", false)
	UISettings.set_reduce_combat_effects(false, false)
	UISettings._load_settings()
	expect(UISettings.combat_cutin_mode == "off" and UISettings.reduce_combat_effects, "applied settings survive a real ConfigFile reload")
	game._open_settings_screen()
	game._select_settings_category("combat")
	game._reset_settings_category()
	expect(UISettings.combat_cutin_mode == "simple" and not UISettings.reduce_combat_effects, "combat category reset restores defaults")
	game._cancel_settings_changes()
	# A real filesystem failure must leave Apply retryable and preserve Cancel.
	var settings_path := ProjectSettings.globalize_path("user://settings.cfg")
	var backup_path := ProjectSettings.globalize_path("user://settings.cutin_savefail_backup.cfg")
	expect(DirAccess.rename_absolute(settings_path, backup_path) == OK, "isolate synthetic settings for failure test")
	expect(DirAccess.make_dir_absolute(settings_path) == OK, "force real synthetic settings write failure")
	game._open_settings_screen()
	game._select_settings_category("combat")
	game._on_combat_cutin_preview_changed("full")
	print("EXPECTED_SETTINGS_WRITE_FAILURE_BEGIN")
	game._apply_settings_changes()
	print("EXPECTED_SETTINGS_WRITE_FAILURE_END")
	expect(game.current_screen == Constants.SCREEN_SETTINGS and game.ui_layer.find_child("SettingsWriteFailure", true, false) != null, "write failure stays in settings with visible retry/cancel feedback")
	game._cancel_settings_changes()
	expect(DirAccess.remove_absolute(settings_path) == OK, "remove only the empty synthetic failure directory")
	expect(DirAccess.rename_absolute(backup_path, settings_path) == OK, "restore original synthetic settings file")
	UISettings.apply_snapshot(original, false)
	UISettings.save()
	game._set_screen(Constants.SCREEN_COMBAT, false)
