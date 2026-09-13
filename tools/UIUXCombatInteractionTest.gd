extends "res://tools/UIUXU4InteractionTest.gd"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp/uiux_u4_u5/interaction")
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale_value in [0.9,1.0,1.15]:
			UISettings.text_scale = scale_value
			var tag := "combat_%dx%d_%d" % [resolution.x,resolution.y,roundi(scale_value*100)]
			game = Game.instantiate()
			add_child(game)
			await settle()
			game.campaign_save_enabled = false
			game._debug_skip_onboarding()
			# Prevent automatic story entry from occupying the command fixture; exercise it explicitly below.
			game.story_feature_enabled = false
			game.onboarding_enabled = false
			game.tutorial_gate_enabled = false
			GameState.day = 2
			game._choose_early_specialization("goblin","goblin_treasure_hunter")
			game._set_global_directive(C.DIRECTIVE_ALL_OUT)
			game.combat_speed_intro_seen = true
			game._set_screen(C.SCREEN_MANAGEMENT)
			game._start_combat()
			await settle()
			expect(game.current_screen == C.SCREEN_COMBAT,tag+" actual defense starts")
			await click(text_button(node("CombatSpeedPanel"),"일시정지"))
			expect(game.combat_paused,tag+" actual pause button pauses")
			var time: float = game.combat_time
			await settle(6)
			expect(is_equal_approx(game.combat_time,time),tag+" simulation clock stays stopped")
			await capture(tag+"_pause")
			await click(node("PauseResumeButton"))
			expect(not game.combat_paused and not game.pause_menu_open,tag+" actual Continue resumes from pause menu")
			await click(text_button(node("CombatSpeedPanel"),"x2"))
			expect(game.combat_speed == 2.0 and not game.combat_paused,tag+" actual speed button sets x2")
			# Freeze fixture timing while checking target hit areas; the existing integration test checks live AI.
			game.set_physics_process(false)
			for unit in game.monster_units + game.enemy_units:
				unit.set_physics_process(false)
			expect(game.hud.v122_command_buttons.size() == 3,tag+" exactly three global commands")
			for command in ["rally","emergency_fallback"]:
				refill()
				var b: Button = game.hud.v122_command_buttons[command]
				await click(b)
				expect(game.combat_scene.pending_v122_command_id == command,tag+" "+command+" arms direct targeting")
				var candidate := target_with_room(game.combat_scene.command_targeting_state().get("candidates",[]))
				expect(not candidate.is_empty(),tag+" "+command+" has actual target")
				var points := int(game.get_meta("v122_command_state",{}).get("points",0))
				if not candidate.is_empty():
					await world_click(game.graph.center(str(candidate.anchor_room_id)))
				var state: Dictionary = game.get_meta("v122_command_state",{})
				expect(state.get("active_commands",{}).has(command),tag+" "+command+" world click activates without confirmation")
				expect(int(state.get("points",0)) < points,tag+" "+command+" consumes real command points")
				expect(node("CombatContextDrawer") == null,tag+" command creates no confirmation drawer")
			refill()
			await click(game.hud.v122_command_buttons.focus)
			var before := int(game.get_meta("v122_command_state",{}).get("points",0))
			await world_click(Vector2(-2000,-2000))
			expect(game.combat_scene.pending_v122_command_id == "focus" and int(game.get_meta("v122_command_state",{}).get("points",0)) == before,tag+" invalid target costs no points")
			expect(node("CombatCommandFeedbackToast") != null,tag+" rejection exposes existing nonmodal feedback")
			await capture(tag+"_invalid_command")
			await key(KEY_ESCAPE)
			expect(game.combat_scene.pending_v122_command_id == "",tag+" ESC cancels command targeting")
			refill()
			var enemy = game.enemy_units[0]
			enemy.global_position = game.graph.center("barracks")
			await click(game.hud.v122_command_buttons.focus)
			await world_click(enemy.global_position)
			var active: Dictionary = game.get_meta("v122_command_state",{}).get("active_commands",{})
			expect(str(active.get("focus",{}).get("target",{}).get("id","")) == str(enemy.get_instance_id()),tag+" focus chooses exact enemy instance")
			refill()
			var facilities: Array = game.get_meta("v122_battle_plan",{}).get("facility_slots",[])
			expect(not facilities.is_empty(),tag+" actual facility slot available")
			if not facilities.is_empty():
				game._select_room(str(facilities[0].room_id))
				game._set_screen(C.SCREEN_COMBAT)
				await settle()
				var facility := node("V122_COMMAND_FACILITY_CONTEXT") as Button
				expect(facility != null,tag+" selected facility has separate action")
				if facility != null:
					await click(facility)
				active = game.get_meta("v122_command_state",{}).get("active_commands",{})
				expect(str(active.get("activate_facility",{}).get("target",{}).get("id","")) == str(facilities[0].slot_id),tag+" facility GUI executes current slot")
			for label in [game.hud.v122_throne_status_label,game.hud.v122_defense_progress_label]:
				expect(label.get_theme_font_size("font_size") >= UISettings.scaled_font_size(18),tag+" core metric keeps readable font")
				expect(label.get_line_count() * label.get_line_height() <= label.size.y + 2,tag+" core metric fits visible bounds")
			await capture(tag+"_facility")
			game.set_physics_process(true)
			game.combat_scene.set_pause_state(false,false)
			expect(game.story_director.start_scene("STORY_D01_COMBAT_TIME_01",game._story_context({"combat_time":0.0}),C.SCREEN_COMBAT),tag+" existing combat dialogue starts")
			game._story_show_active_scene()
			await settle()
			expect(game.story_combat_overlay_open and game.combat_paused,tag+" combat dialogue freezes actual simulation")
			time = game.combat_time
			await settle(6)
			expect(is_equal_approx(game.combat_time,time),tag+" dialogue retains stopped clock")
			await capture(tag+"_dialogue")
			var limit := 0
			while game.story_director.is_active() and limit < 20:
				var next := node("StoryNextButton") as Button
				if next == null:
					expect(false,tag+" combat dialogue Next exists")
					break
				next.grab_focus()
				await key(KEY_ENTER)
				limit += 1
			expect(not game.story_combat_overlay_open and not game.combat_paused and game.combat_speed == 2.0,tag+" keyboard Next resumes previous speed and pause state")
			game.queue_free()
			await settle(3)
	var f := FileAccess.open("res://tmp/uiux_u4_u5/interaction/combat_results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"assertions":count,"failed":failed,"captures":captures},"\t"))
	f.close()
	print("UIUX_COMBAT_INTERACTION_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS",count])
	get_tree().quit(1 if failed else 0)

func refill() -> void:
	var state: Dictionary = game.get_meta("v122_command_state",{})
	state["points"] = 3
	state["cooldowns"] = {}
	state["active_commands"] = {}
	game.set_meta("v122_command_state",state)
	game.hud.update_combat_status()

func text_button(parent: Node, text: String) -> Button:
	if parent is Button and parent.text == text:
		return parent
	for child in parent.get_children():
		var found := text_button(child,text)
		if found != null:
			return found
	return null

func target_with_room(candidates: Array) -> Dictionary:
	for candidate in candidates:
		var id := str(candidate.get("anchor_room_id",""))
		if game.rooms.has(id):
			var point: Vector2 = game._combat_world_to_screen(game.graph.center(id))
			if point.y > 160 and point.y < 820:
				return candidate
	return {}

func world_click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = game._combat_world_to_screen(point)
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	event.button_mask = 0
	get_viewport().push_input(event,true)
	await settle()
