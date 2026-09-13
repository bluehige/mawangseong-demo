extends "res://tools/UIUXU4InteractionTest.gd"
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp/uiux_u4_u5/interaction")
	game = Game.instantiate()
	add_child(game)
	await settle()
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.story_feature_enabled = false
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale_value in [0.9,1.0,1.15]:
			UISettings.text_scale = scale_value
			var tag := "council_%dx%d_%d" % [resolution.x,resolution.y,roundi(scale_value*100)]
			game.update4_active_run = {"campaign_mode_id":"council_season", "outpost":{"type_id":str(DataRegistry.update4_outpost_types.keys()[0])}, "council_season":{"agenda_history":[],"vote_records":[],"rival_relations":{"rival_brassa":10,"rival_vesper":10,"rival_mirella":10},"council_votes":20,"independence":15,"council_seals":2,"final_representative_id":"rival_brassa"}}
			for day in [13,23,29]:
				GameState.day = day
				game.update4_active_run.council_season["selected_regions"] = DataRegistry.update4_regions.keys().slice(0,2 if day == 13 else 3)
				if day == 23:
					game.update4_active_run.council_season["council_seals"] = 0
					game._set_screen(C.SCREEN_MANAGEMENT)
					await settle()
					var blocked := node("Update4CouncilDecisionOverlay")
					expect(blocked.find_children("*","Button",true,false).all(func(b): return b.disabled),tag + " insufficient seal cost disables unavailable rewards")
					await capture(tag + "_crown_blocked")
					game.update4_active_run.council_season["council_seals"] = 2
				game._set_screen(C.SCREEN_MANAGEMENT)
				await settle()
				var overlay := node("Update4CouncilDecisionOverlay") as Control
				expect(overlay != null,tag + " day%d required overlay exists" % day)
				if overlay == null:
					get_tree().quit(1)
					return
				var pane := overlay.find_child("DecisionPanel",true,false) as Control
				expect(Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).encloses(pane.get_global_rect()),tag + " decision stays inside viewport")
				var buttons := overlay.find_children("*","Button",true,false)
				expect(buttons.size() >= (9 if day == 13 else (3 if day == 23 else 4)),tag + " all actual choices are present")
				var last := buttons.back() as Button
				last.grab_focus()
				await settle()
				var scroll := node("CouncilDecisionScroll") as ScrollContainer
				expect(scroll.get_global_rect().grow(1).encloses(last.get_global_rect()),tag + " last choice follows keyboard focus")
				await capture(tag + "_day%d" % day)
				await key(KEY_ENTER)
				if day == 13:
					expect(game.update4_active_run.council_season.vote_records.size() == 1,tag + " real vote recorded once")
				elif day == 23:
					expect(bool(game.update4_active_run.council_season.get("crown_declined",false)) and int(game.update4_active_run.council_season.get("council_seals",0)) == 0,tag + " real no-candidate alternative advances crown choice")
				else:
					expect(game.update4_active_run.council_season.day29_decision_id == "reject_council_authority",tag + " final declaration committed")
				expect(node("Update4CouncilDecisionOverlay") == null,tag + " completed required choice closes overlay")
	game.queue_free()
	await settle(3)
	var file := FileAccess.open("res://tmp/uiux_u4_u5/interaction/council_results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions":count,"failed":failed,"captures":captures},"\t"))
	file.close()
	print("UIUX_COUNCIL_INTERACTION_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS",count])
	get_tree().quit(1 if failed else 0)
