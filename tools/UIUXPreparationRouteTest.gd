extends "res://tools/BalanceSimulation.gd"
const Summary = preload("res://scripts/ui/DefensePreparationSummary.gd")
var checks := 0
var preparation_failed := false
var evidence := "res://tmp/uiux_preparation_20260913/direct"

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		preparation_failed = true
		push_error("PREPARATION_ASSERT_FAIL: "+label)

func settle(n: int = 3) -> void:
	for i in range(n):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

func capture(name: String) -> void:
	await settle()
	check(get_viewport().get_texture().get_image().save_png(evidence+"/"+name+".png") == OK,name+" capture")

func enter() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event,true)
	await settle()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence))
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		UISettings.text_scale = 1.0 if resolution.x == 1920 else 1.15
		for day in [2,12,22,30]:
			var g = GameRootScene.instantiate()
			g.campaign_save_enabled = false
			g.campaign_auxiliary_save_enabled = false
			g.campaign_save_v4_enabled = false
			g.campaign_save_v5_enabled = false
			add_child(g)
			await settle(5)
			g._debug_skip_onboarding()
			g.onboarding_enabled = false
			g.tutorial_gate_enabled = false
			g.story_feature_enabled = false
			GameState.day = day
			match day:
				12: _apply_stage_two_campaign_setup(g,"goblin")
				22: _apply_late_campaign_setup(g)
				30: _apply_final_campaign_setup(g)
			for id in ["slime","goblin","imp"]:
				g.monster_roster[id].room = "spike_corridor"
				g.monster_roster[id].defense_zone_id = "zone_a_front"
				g.monster_roster[id].assigned_defense_zone_id = "zone_a_front"
			g._set_management_tool_tab("tactics")
			await settle()
			var tag := "%d_day%02d" % [resolution.x,day]
			check(not g.maze_route_forecasts.is_empty(),tag+" real wave routes available")
			var route_id := ""
			for route in g.maze_route_forecasts:
				if g.graph.path_between(route.spawn_room_id,route.target_room_id).has("spike_corridor"):
					route_id = str(route.id)
					break
			check(route_id != "",tag+" fixture has entry front route")
			var roster_before: Dictionary = g.monster_roster.duplicate(true)
			var start_before: Dictionary = g._management_start_state()
			var gold_before: int = GameState.gold
			var mana_before: int = GameState.mana
			var seed_before: int = g.update2_cycle_seed
			g._select_maze_route(route_id)
			await settle()
			var summary: Dictionary = Summary.selected_route(g)
			check(summary.known and summary.count == 3,tag+" three actual initial defenders")
			var label: Label = g.ui_layer.find_child("MazePreparationSummary",true,false)
			check(label != null and label.text == str(summary.text),tag+" selected route refreshes visible description")
			check(label != null and label.get_line_count()*label.get_line_height() <= label.size.y+2,tag+" summary fits current text scale")
			check(label != null and label.tooltip_text.contains("Lv.%d" % int(g.monster_roster.slime.level)),tag+" real growth level displayed")
			check(g.monster_roster == roster_before and g._management_start_state() == start_before and GameState.gold == gold_before and GameState.mana == mana_before and g.update2_cycle_seed == seed_before,tag+" preview preserves roster resources seed and start gates")
			await capture(tag+"_staffed_route")
			# A reserve/disabled unit must not be presented as initial coverage.
			for id in g.monster_roster: g.monster_roster[id].defense_enabled = false
			g._set_management_tool_tab("tactics")
			g._select_maze_route(route_id)
			await settle()
			summary = Summary.selected_route(g)
			check(summary.known and summary.count == 0,tag+" disabled defenders excluded")
			check(str(summary.text).contains("초기 배치 없음"),tag+" empty route shows placement guidance")
			await capture(tag+"_empty_route")
			g.monster_roster = roster_before.duplicate(true)
			g._set_management_tool_tab("tactics")
			await settle()
			var button: Button = g.ui_layer.find_child("OpenRouteRosterButton",true,false)
			button.grab_focus()
			await enter()
			check(g.management_tool_tab == "roster",tag+" keyboard shortcut opens real roster toolbox")
			var card: Button = g.ui_layer.find_child("MonsterCard_slime",true,false)
			check(card != null and card.text.contains("Lv.%d" % int(g.monster_roster.slime.level)),tag+" roster card shows real level")
			check(g.monster_roster == roster_before and GameState.gold == gold_before and GameState.mana == mana_before,tag+" shortcut does not deploy or charge")
			await capture(tag+"_roster")
			g.maze_route_forecasts.clear()
			check(not bool(Summary.selected_route(g).known),tag+" missing forecast is unknown rather than uncovered")
			g.queue_free()
			await settle()
			await get_tree().create_timer(0.2,true,false,true).timeout
	print("UIUX_PREPARATION_ROUTE_TEST: %s (%d assertions)" % ["FAIL" if preparation_failed else "PASS",checks])
	get_tree().quit(1 if preparation_failed else 0)
