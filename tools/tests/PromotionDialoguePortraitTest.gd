extends "res://tools/tests/PlayerFeedbackHotfixTest.gd"

# Synthetic owned rosters; exercise the actual reply-frame renderer and saves.
# This is appearance/restore coverage, not a continuous earned campaign.
func run() -> void:
	output_dir = "res://tmp/promotion_portraits"
	expect(ProjectSettings.globalize_path("user://").contains("promotion_portrait_review"), "isolated synthetic userdata")
	if not failures.is_empty(): get_tree().quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game = GameRootScene.instantiate()
	add_child(game)
	await settle()
	game.continuity.acknowledge_update()
	game._onboarding_reset_game()
	game._onboarding_enter_management_day(1, true)
	game._debug_skip_onboarding()
	GameState.player_name = "Portrait QA"
	game.set_process(false)
	game.set_physics_process(false)
	game.story_feature_enabled = true
	game._set_campaign_save_path_for_tests("user://campaign_save_v1.json", "user://campaign_save_v2.json", "user://campaign_save_v3.json", "user://campaign_save_v4.json", "user://campaign_save_v5.json")
	var original: Dictionary = game.monster_roster.duplicate(true)
	for species in ["slime", "goblin", "imp"]:
		var char_id := character_for(species)
		var base: Dictionary = game._onboarding_speaker_portrait_data(char_id)
		expect(game._onboarding_speaker_portrait_path(char_id) == str(base.base), species + " unpromoted portrait preserved without recursion")
		await reply(char_id, "", str(base.base), "base_" + species)
		await catalog_reply(char_id, str(base.base), "catalog_base_" + species)
	for rule_id in DataRegistry.evolution_rules:
		var rule: Dictionary = DataRegistry.evolution_rules[rule_id]
		var species := str(rule.monster_id)
		game.monster_roster = original.duplicate(true)
		game.monster_roster[species]["promotion_id"] = rule_id
		game.monster_roster[species]["level"] = 3
		game.first_promotion_completed = true
		game.story_promotion_order.clear()
		game.story_promotion_order.append(species)
		game.update4_active_run = {}
		GameState.day = 12
		var char_id := character_for(species)
		expect(str(game._scaled_monster_stats(species).sprite) == str(rule.combat_sprite), rule_id + " combat uses promoted image")
		for emotion in ["", "victory", "wounded", "happy", "brave", "eager", "proud", "cast"]:
			var expected := str(rule.get("portrait_variants", {}).get(emotion, rule.portrait))
			expect(ResourceLoader.exists(expected), rule_id + " existing resource " + emotion)
			expect(game._onboarding_speaker_portrait_path(char_id, emotion) == expected, rule_id + " current form emotion " + emotion)
			await reply(char_id, emotion, expected, str(rule_id) if emotion == "" else "")
		var resolved: Dictionary = game._story_resolve_cue_speaker({"speaker_role": "first_promoted"})
		expect(str(resolved.get("speaker_id", "")) == char_id, rule_id + " dynamic promoted speaker identity")
		game._set_screen(Constants.SCREEN_MANAGEMENT, false)
		expect(game.continuity.save_now(), rule_id + " real five-version checkpoint write")
		game.monster_roster[species]["promotion_id"] = ""
		game._set_screen(Constants.SCREEN_TITLE, false)
		game._continue_campaign_save()
		await settle()
		expect(GameState.day == 12 and str(game.monster_roster[species].get("promotion_id", "")) == str(rule_id), rule_id + " title continue restores day and form (entry dialogue may open)")
		await reply(char_id, "", str(rule.portrait), "restored_" + str(rule_id))
		await catalog_reply(char_id, str(rule.portrait), "catalog_" + str(rule_id))
	for crown_id in DataRegistry.update4_crown_evolutions:
		var crown: Dictionary = DataRegistry.update4_crown_evolutions[crown_id]
		var species := str(crown.monster_id)
		game.monster_roster = original.duplicate(true)
		if not game.monster_roster.has(species): game.monster_roster[species] = original.slime.duplicate(true)
		var inherited := ""
		if not crown.get("branch_inheritance", {}).is_empty(): inherited = str(crown.branch_inheritance.keys()[0])
		game.monster_roster[species]["promotion_id"] = inherited
		game.monster_roster[species]["level"] = 7
		var instance_id := instance_for(species)
		game.update4_active_run = {"campaign_mode_id": "council_season", "crown": {"selected_instance_id": instance_id, "crown_form_id": crown_id}}
		var char_id := character_for(species)
		expect(char_id != "" and str(game._scaled_monster_stats(species).get("crown_form_id", "")) == str(crown_id), str(crown_id) + " actual active combat crown")
		for emotion in ["", "victory", "wounded", "happy"]:
			var expected := str(crown.get("portrait_" + emotion, crown.portrait))
			expect(ResourceLoader.exists(expected), str(crown_id) + " existing portrait " + emotion)
			expect(game._onboarding_speaker_portrait_path(char_id, emotion) == expected, str(crown_id) + " reply follows active crown " + emotion)
			await reply(char_id, emotion, expected, str(crown_id) if emotion == "" else "")
		if species in ["slime", "goblin", "imp"]:
			await catalog_reply(char_id, str(crown.portrait), "catalog_" + str(crown_id))
		game.update4_active_run["upper_floor"] = {"crown_suppressed": true}
		expect(str(game._scaled_monster_stats(species).get("crown_form_id", "")) == "", str(crown_id) + " combat crown suppression")
		var expected_base: String = str(DataRegistry.evolution_rules[inherited].portrait) if inherited != "" else str(game._onboarding_speaker_portrait_data(char_id).base)
		expect(game._onboarding_speaker_portrait_path(char_id) == expected_base, str(crown_id) + " suppressed reply follows combat form")
	game.queue_free()
	await settle()
	print("PromotionDialoguePortraitTest: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func instance_for(species: String) -> String:
	for id in DataRegistry.monster_instances:
		if str(DataRegistry.monster_instances[id].get("species_id", "")) == species: return str(id)
	return ""

func character_for(species: String) -> String:
	return str(DataRegistry.monster_instances.get(instance_for(species), {}).get("character_id", ""))

func reply(char_id: String, emotion: String, expected: String, screenshot: String) -> void:
	game._set_screen(Constants.SCREEN_MANAGEMENT, false)
	var frame := Control.new()
	frame.name = "PortraitReplyFixture"
	game.ui_layer.add_child(frame)
	game.story_presenter._build_frame(frame, {"speaker_id": char_id, "portrait_emotion": emotion, "text_ko": "현재 모습으로 대답합니다. 승급 대화 이미지 검증."}, {"title": "승급 답변 이미지 검증"}, false)
	var image := frame.find_child("CharacterPortraitImage", true, false) as TextureRect
	expect(image != null and image.texture != null and image.texture == game._onboarding_portrait_texture(expected), char_id + " actual reply TextureRect " + emotion)
	if expected.contains("uiux_evolution") or expected.contains("crowns/") or expected.contains("uiux_crowns"):
		expect(image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, char_id + " full form fits without side crop")
	if screenshot != "": await capture(screenshot)

func catalog_reply(char_id: String, expected: String, screenshot: String) -> void:
	# Real authored dialogue and full-screen presentation, not an invented scene.
	game.story_director.cancel_active_scene()
	for id in game.story_catalog.all_scene_ids():
		var scene: Dictionary = game.story_catalog.scene(id)
		var contains_speaker := false
		for cue in scene.get("cues", []):
			if str(cue.get("speaker_id", "")) == char_id: contains_speaker = true
		if not contains_speaker: continue
		if not game.story_director.start_scene(id, game._story_context({"win": true}), Constants.SCREEN_MANAGEMENT, "", true): continue
		while game.story_director.is_active():
			var cue: Dictionary = game.story_director.current_cue()
			if str(cue.get("speaker_id", "")) == char_id:
				game.story_combat_overlay_open = false
				game._set_screen(Constants.SCREEN_DIALOGUE, false)
				var portrait := game.ui_layer.find_child("CharacterPortraitImage", true, false) as TextureRect
				var actual_path: String = game._onboarding_speaker_portrait_path(char_id, str(cue.get("portrait_emotion", "")))
				expect(portrait != null and portrait.texture == game._onboarding_portrait_texture(actual_path), screenshot + " real catalog reply texture")
				expect(actual_path == expected or actual_path.get_base_dir() == expected.get_base_dir(), screenshot + " real catalog uses current form")
				await capture(screenshot)
				game.story_director.cancel_active_scene()
				return
			game.story_director.advance()
		game.story_director.cancel_active_scene()
	expect(false, screenshot + " authored speaker cue available")
