extends "res://tools/tests/PlayerFeedbackHotfixTest.gd"

func run() -> void:
	output_dir = "res://tmp/day1_feedback"
	expect(ProjectSettings.globalize_path("user://").contains("day1_feedback"), "isolated day1_feedback user data")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game = GameRootScene.instantiate()
	add_child(game)
	await settle()
	var original := UISettings.snapshot()
	# Explicit opt-out fixture also verifies cancel preserves an existing preference.
	UISettings.set_remember_combat_speed(false, false)
	expect(ProjectSettings.get_setting("application/config/version") == "1.2.10", "same product version")
	for locale in ["ko", "en", "zh_CN"]:
		LanguageSettings.set_locale(locale, false)
		game._set_screen(Constants.SCREEN_NAME_ENTRY)
		await settle()
		var names: Array = game._onboarding_random_name_candidates()
		var unique := {}
		for candidate in names:
			unique[candidate] = true
			expect(candidate.length() <= 12 and not candidate.begins_with("name."), "valid localized random name " + candidate)
		expect(unique.size() == 40, "40 unique names " + locale)
		for i in range(16):
			var previous: String = game.onboarding_name_input.text
			game._onboarding_random_name()
			expect(game.onboarding_name_input.text in names and game.onboarding_name_input.text != previous, "random name never repeats immediately " + locale)
		game._open_settings_screen()
		await settle()
		expect(game.ui_layer.find_child("RememberCombatSpeedOption", true, false) != null, "speed setting visible " + locale)
		if locale == "ko":
			await capture("speed_settings")
		game._on_combat_speed_preview_changed("remember")
		game._cancel_settings_changes()
		await settle()
		expect(not UISettings.remember_combat_speed, "settings cancel restores speed option " + locale)
		for key in ["remember_speed", "speed_reset", "speed_remember", "remember_speed_help"]:
			expect(not LanguageSettings.text("settings.display." + key).begins_with("settings."), "speed option translated " + locale)
	LanguageSettings.set_locale("ko", false)
	game._onboarding_reset_game()
	game._onboarding_enter_management_day(1, true)
	while game.story_director.is_active():
		game._story_advance_dialogue(true)
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	GameState.gold = 12345
	GameState.mana = 987
	GameState.food = 28
	GameState.infamy = 321
	for locale in ["ko", "en", "zh_CN"]:
		LanguageSettings.set_locale(locale, false)
		for scale in [1.0, 1.15]:
			UISettings.set_text_scale(scale, false)
			for layout in [UISettings.LAYOUT_STANDARD, UISettings.LAYOUT_COMPACT]:
				UISettings.set_layout_mode(layout, false)
				game._set_screen(Constants.SCREEN_MANAGEMENT)
				await settle()
				check_resources(locale + "/" + str(scale) + "/" + layout)
				if layout == UISettings.LAYOUT_COMPACT and scale == 1.15:
					await capture("resources_" + locale)
	LanguageSettings.set_locale("ko", false)
	UISettings.set_text_scale(1.0, false)
	UISettings.set_layout_mode(UISettings.LAYOUT_AUTO, false)
	GameState.day = 2
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await settle()
	expect(game._management_start_state().reason_code == "specialization", "DAY2 specialization required")
	var start: Button = game.ui_layer.find_child("StartCombatButton", true, false)
	expect(not start.disabled and start.text.contains("필수"), "required growth is prominent actionable primary button")
	await capture("day2_required_growth")
	await click(start)
	expect(game.current_screen == Constants.SCREEN_MONSTER, "primary button opens monster growth")
	expect(game.ui_layer.find_child("RequiredGrowthHeading", true, false) != null, "growth requirement banner shown")
	var choices: Array = game.ui_layer.find_children("MonsterSpecialization_*", "Button", true, false)
	expect(not choices.is_empty(), "specialization choices available")
	if not choices.is_empty():
		var choice: Button = choices[0]
		var scroll: ScrollContainer = game.ui_layer.find_child("MonsterGrowthScroll", true, false)
		expect(scroll.get_global_rect().encloses(choice.get_global_rect()), "first specialization choice visible without searching or scrolling")
		await capture("growth_choices")
		await click(choice)
		expect(not game._early_specialization_required_for_current_day(), "chosen specialization clears required gate")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await settle()
	expect(game._management_start_state().reason_code != "specialization", "management no longer blocks on growth")
	check_resources("after monster growth return")
	var tooltip_button: Button = game.ui_layer.find_child("StartCombatButton", true, false)
	var tip: Label = tooltip_button._make_custom_tooltip("체력과 공격력을 높여 다음 방어전을 준비하세요. 설명은 배경 위에 읽기 쉬운 크기로 표시합니다.")
	game.ui_layer.add_child(tip)
	tip.position = Vector2(500, 350)
	await settle()
	expect(tip.get_line_count() >= 2 and tip.get_visible_line_count() == tip.get_line_count(), "tooltip wraps and all lines visible")
	game.ui_layer.remove_child(tip)
	tip.queue_free()
	# Actual hovered button uses Godot's tooltip popup, not a mock panel.
	tooltip_button.tooltip_text = "체력과 공격력을 높여 다음 방어전을 준비하세요. 설명은 배경 위에 읽기 쉬운 크기로 표시합니다."
	var motion := InputEventMouseMotion.new()
	motion.position = tooltip_button.get_global_transform_with_canvas() * Vector2(25, 25)
	get_viewport().push_input(motion, true)
	await get_tree().create_timer(0.8).timeout
	await capture("readable_tooltip")
	UISettings.set_remember_combat_speed(true)
	game.combat_scene.set_speed(2.0)
	UISettings.set_preferred_combat_speed(1.0, false)
	UISettings.set_remember_combat_speed(false, false)
	UISettings._load_settings()
	expect(UISettings.remember_combat_speed and UISettings.preferred_combat_speed == 2.0, "speed setting and selection survive restart")
	game.combat_scene.start_combat()
	game.combat_scene.set_pause_state(true, false)
	await settle()
	expect(game.combat_speed == 2.0, "remembered speed starts next battle")
	game.combat_scene.set_speed(3.0)
	game.combat_scene.start_combat()
	game.combat_scene.set_pause_state(true, false)
	await settle()
	expect(game.combat_speed == 3.0, "last changed speed carries into following battle")
	for unit in game.monster_units:
		unit.hp = maxi(1, unit.max_hp / 2)
		unit.queue_redraw()
	game.room_directives["entrance"] = Constants.ROOM_DIRECTIVE_TRAP_LURE
	game.room_directives["recovery"] = Constants.ROOM_DIRECTIVE_RETREAT
	game.queue_world_overlay_redraw()
	await settle()
	if DisplayServer.get_name() != "headless":
		expect(not game.combat_map_label_layouts.is_empty(), "combat directive labels rendered")
		if not game.combat_map_label_layouts.is_empty() and not game.monster_units.is_empty():
			var crowded_unit: Node2D = game.monster_units[0]
			var original_bar: Rect2 = crowded_unit.map_hp_bar_screen_rect()
			var delta: Vector2 = game.combat_map_label_layouts[0].rect.get_center() - original_bar.get_center()
			crowded_unit.global_position += crowded_unit.get_canvas_transform().basis_xform_inv(delta)
			crowded_unit.queue_redraw()
			game.queue_world_overlay_redraw()
			await settle()
			expect(original_bar.get_center().distance_to(crowded_unit.map_hp_bar_screen_rect().get_center()) > 10, "real health bar moved into directive tag's previous position")
		for info in game.combat_map_label_layouts:
			for unit in game.monster_units:
				var bar: Rect2 = unit.map_hp_bar_screen_rect()
				expect(not bar.has_area() or not info.rect.intersects(bar), "directive label avoids health bar")
	await capture("combat_labels_speed")
	UISettings.set_remember_combat_speed(false)
	game.combat_scene.start_combat()
	game.combat_scene.set_pause_state(true, false)
	expect(game.combat_speed == 1.0, "option disabled resets battle speed")
	UISettings.set_remember_combat_speed(true)
	UISettings.set_preferred_combat_speed(3.0)
	game.onboarding_enabled = true
	GameState.onboarding_complete = false
	game.combat_scene.start_combat()
	game.combat_scene.set_pause_state(true, false)
	expect(game.combat_speed == 1.0 and UISettings.preferred_combat_speed == 3.0, "tutorial starts x1 without erasing remembered speed")
	UISettings.apply_snapshot(original, true)
	game.queue_free()
	await settle()
	print("DayOneFeedbackHotfixTest: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func check_resources(context: String) -> void:
	var expected := {"gold": str(GameState.gold), "mana": str(GameState.mana), "food": "%d / 30" % GameState.food, "infamy": str(GameState.infamy)}
	for resource in expected:
		var value: Label = game.hud.resource_value_labels.get(resource)
		expect(value != null and value.text == expected[resource], "resource value " + resource + " " + context)
		if value != null:
			expect(value.is_visible_in_tree() and value.get_visible_line_count() >= 1, "resource text actually visible " + resource + " " + context)
