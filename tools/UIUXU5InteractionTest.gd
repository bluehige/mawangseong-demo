extends "res://tools/UIUXU4InteractionTest.gd"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp/uiux_u4_u5/interaction")
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale_value in [0.9,1.0,1.15]:
			UISettings.text_scale = scale_value
			var tag := "u5_%dx%d_%d" % [resolution.x,resolution.y,roundi(scale_value*100)]
			game = Game.instantiate()
			add_child(game)
			await settle()
			game.campaign_save_enabled = false
			game._debug_skip_onboarding()
			game.onboarding_enabled = false
			game.tutorial_gate_enabled = false
			GameState.day = 2
			GameState.player_name = "입력 검증 마왕"
			game._set_screen(C.SCREEN_MANAGEMENT)
			game._open_management_context_drawer()
			await settle()
			var spec := node("RequiredSpecialization_goblin_goblin_treasure_hunter") as Button
			expect(spec != null and not spec.disabled, tag + " mandatory preparation remains reachable")
			if spec != null:
				spec.grab_focus()
				await settle()
				check_copy(node("ManagementContextDrawer"))
				await capture(tag + "_required")
				await key(KEY_ENTER)
				expect(game.monster_roster.goblin.specialization_id == "goblin_treasure_hunter", tag + " required choice uses real specialization callback")
			# Write only the isolated test save, then exercise the actual title confirmation.
			game._set_campaign_save_path_for_tests("user://uiux_u5_test.json")
			game._set_screen(C.SCREEN_MANAGEMENT)
			game._schedule_campaign_autosave(C.SCREEN_MANAGEMENT)
			await settle()
			game._set_screen(C.SCREEN_TITLE)
			await settle()
			expect(node("CampaignContinueButton") != null, tag + " valid save exposes Continue")
			if node("CampaignContinueButton") == null:
				get_tree().quit(1)
				return
			check_copy(game.ui_layer)
			var saved_hash := FileAccess.get_sha256(game.campaign_save_path)
			await click(node("CampaignNewGameButton"))
			expect(node("TitleResetConfirmation") != null, tag + " new game asks before replacing save")
			expect(get_viewport().gui_get_focus_owner() == node("TitleResetCancelButton"), tag + " reset focuses cancel")
			expect((node("CampaignContinueButton") as Button).disabled, tag + " modal blocks background keyboard controls")
			await key(KEY_TAB)
			expect(get_viewport().gui_get_focus_owner() == node("TitleResetConfirmButton"), tag + " Tab reaches confirm within modal")
			await key(KEY_TAB)
			expect(get_viewport().gui_get_focus_owner() == node("TitleResetCancelButton"), tag + " Tab cycles back to cancel")
			await capture(tag + "_save_confirmation")
			await key(KEY_ENTER)
			expect(node("TitleResetConfirmation") == null and saved_hash == FileAccess.get_sha256(game.campaign_save_path), tag + " Enter cancel preserves exact save bytes")
			await click(node("CampaignNewGameButton"))
			await key(KEY_ESCAPE)
			expect(node("TitleResetConfirmation") == null and saved_hash == FileAccess.get_sha256(game.campaign_save_path), tag + " ESC cancel preserves exact save bytes")
			await click(node("CampaignContinueButton"))
			expect(GameState.day == 2 and game.current_screen == C.SCREEN_MANAGEMENT, tag + " actual Continue restores saved checkpoint")
			game.campaign_save_enabled = false
			game.story_feature_enabled = false
			GameState.day = 4
			GameState.gold = 500
			GameState.mana = 500
			GameState.food = 100
			GameState.infamy = 50
			game.completed_raids.clear()
			game.raid_selected_monster_ids.clear()
			game.raid_selected_mission_id = "d04_signpost_flip"
			game._set_screen(C.SCREEN_RAID)
			await settle()
			expect((node("RaidStartButton") as Button).disabled, tag + " empty expedition blocks start")
			check_copy(game.ui_layer)
			await click(node("RaidMember_goblin"))
			expect(game.raid_selected_monster_ids == ["goblin"], tag + " member selection changes only roster")
			var mission := DataRegistry.raid_mission(game.raid_selected_mission_id)
			var reward: Dictionary = game._raid_reward_with_bonus(mission)
			var before := economy()
			var wanted := before.duplicate()
			for resource in wanted.keys():
				wanted[resource] = before[resource] - int(mission.get("cost",{}).get(resource,0)) + int(reward.get(resource,0))
			await capture(tag + "_raid_review")
			await click(node("RaidStartButton"))
			expect(economy() == wanted and game.completed_raids.has("d04_signpost_flip"), tag + " raid input settles actual cost and rewards exactly once")
			game._start_selected_raid()
			expect(economy() == wanted and (node("RaidStartButton") as Button).disabled, tag + " completed raid ignores duplicate input")
			await click(node("RaidBackButton"))
			expect(game.current_screen in [C.SCREEN_MANAGEMENT,C.SCREEN_INTRUSION_BRIEF,C.SCREEN_DIALOGUE] and not game._day_four_intro_raid_pending(), tag + " completed raid enters the existing next-preparation / briefing flow")
			game.story_feature_enabled = true
			game.onboarding_dialogue_queue.clear()
			GameState.day = 1
			expect(game.story_director.start_scene("STORY_D01_MANAGEMENT_ENTRY",game._story_context({}),C.SCREEN_MANAGEMENT),tag + " actual story scene begins")
			game._story_show_active_scene()
			await settle()
			var cue: String = str(game.story_director.current_cue_id)
			(node("StoryAutoButton") as Button).grab_focus()
			await key(KEY_ENTER)
			expect(game.story_director.auto_enabled and str(game.story_director.current_cue_id) == cue,tag + " focused Auto toggles without skipping dialogue")
			(node("StoryAutoButton") as Button).grab_focus()
			await key(KEY_ENTER)
			expect(not game.story_director.auto_enabled,tag + " focused Auto can stop automatic advancement")
			var body := node("StoryDialogueText") as RichTextLabel
			expect(body != null and body.get_theme_font_size("normal_font_size") >= UISettings.scaled_font_size(26),tag + " dialogue body retains readable font")
			await capture(tag + "_story")
			(node("StoryNextButton") as Button).grab_focus()
			await key(KEY_ENTER)
			expect(str(game.story_director.current_cue_id) != cue,tag + " focused Next advances actual cue once")
			for id in DataRegistry.monsters.keys():
				if DataRegistry.monster(str(id)).has("portrait") or str(id) in ["slime","goblin","imp","kobold_scout"]:
					var path: String = game.management_scene.monster_portrait_path(str(id))
					expect(path != "" and ResourceLoader.exists(path),tag + " catalog portrait available: " + str(id))
			game.queue_free()
			await settle(3)
	var file := FileAccess.open("res://tmp/uiux_u4_u5/interaction/u5_results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions":count,"failed":failed,"captures":captures},"\t"))
	file.close()
	print("UIUX_U5_INTERACTION_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS",count])
	get_tree().quit(1 if failed else 0)

func economy() -> Dictionary:
	return {"gold":GameState.gold,"mana":GameState.mana,"food":GameState.food,"infamy":GameState.infamy}
