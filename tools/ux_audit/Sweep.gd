extends "res://tools/ux_audit/Audit.gd"
## Deterministic UI fixtures, not a campaign or balance regression.
const Constants = preload("res://scripts/core/Constants.gd")
const SCREENS = ["title", "settings", "name_entry", "dialogue", "intrusion_brief", "management", "defense_start", "monster", "combat", "result", "ending", "ending_archive", "memory_archive", "cycle_doctrine", "cycle_decree", "challenge_seal", "contract_board", "front_selection", "campaign_mode_selection", "region_selection", "outpost_management", "outpost_battle", "upper_floor", "heart_selection", "duo_link_loadout", "chronicle", "raid_preview", "raid", "tutorial_practice"]
var fixture_failures: Array[String] = []

func start() -> void:
	get_tree().create_timer(180).timeout.connect(func(): get_tree().quit(2))
	await super.start()
	if game == null: return
	game._debug_skip_onboarding()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.campaign_save_notice = ""
	game.continuity.acknowledge_update()
	GameState.day = 7
	GameState.gold = 5000
	GameState.mana = 5000
	GameState.food = 100
	game.selected_monster_id = "slime"
	game.result_summary = {"win":true,"day":7,"damage_to_castle":0,"enemies_defeated":3,"v122_ledger":{}}
	game.onboarding_dialogue_queue = [{"speaker":"CHR_BATI","speaker_name":"바티","text":"표시 검사 대사","text_ko":"표시 검사 대사"}]
	for screen in SCREENS:
		game._set_screen(screen, false)
		await settle(20)
		if game.current_screen != screen: fixture_failures.append(screen + " redirected to " + game.current_screen)
		await capture(screen, "UI visibility", "synthetic display fixture; no campaign progression")
		if screen == "settings":
			for tab in ["general", "audio", "combat"]:
				game.settings_category = tab
				game._set_screen(screen, false)
				await capture("settings_" + tab, "Settings tab", "synthetic tab fixture")
		if screen == "management":
			for tab in ["build", "roster", "tactics"]:
				game.management_tool_tab = tab
				game._set_screen(screen, false)
				await capture("management_" + tab, "Management tab", "synthetic tab fixture")
			game.selected_room = "barracks"
			game.management_context_drawer_open = true
			game._set_screen(screen, false)
			await capture("management_detail", "Room details", "synthetic drawer fixture")
			game.management_context_drawer_open = false
		if screen == "monster":
			var scroll := game.ui_layer.find_child("MonsterGrowthScroll", true, false) as ScrollContainer
			if scroll != null:
				scroll.scroll_vertical = 900
				await capture("monster_scrolled", "Growth lower rows", "synthetic scroll fixture")
			GameState.day = 12
			game._set_screen(screen, false)
			await capture("monster_day12", "Late growth rows", "synthetic DAY12 fixture")
			GameState.day = 7
		if screen == "combat":
			game.combat_scene.start_combat()
			game.combat_scene.set_pause_state(true,false)
			for unit in game.unit_root.get_children(): unit.set_physics_process(false)
			if game.unit_root.get_child_count() == 0: fixture_failures.append("combat has no units")
			else:
				game.selected_unit = game.unit_root.get_child(0)
				game._set_screen(screen, false)
				await capture("combat_inspector", "Actual unit details", "paused actual unit fixture")
				# Every manual-control variation must keep speed and command controls reachable.
				for unit in game.unit_root.get_children():
					if unit.faction != "monster": continue
					game.selected_unit = unit
					game._set_screen(screen, false)
					await capture("combat_inspector_" + str(unit.unit_id), "Actual unit details", "paused actual unit fixture")
			var detail_scroll := game.ui_layer.find_child("CombatUnitInspectorScroll", true, false) as ScrollContainer
			if UISettings.is_touch_ui() and detail_scroll == null: fixture_failures.append("touch inspector lacks bounded scroll")
			if detail_scroll != null:
				detail_scroll.scroll_vertical = 10000
				await capture("combat_inspector_scrolled", "Inspector lower actions", "actual scroll on paused unit fixture")
			var presentation = game.combat_scene.skill_actions
			presentation.current = {"name":"표시 검사 기술","actors":[],"kind":"skill"}
			presentation._build_stage()
			presentation.stage.set_process(false)
			presentation._lock_gameplay_buttons()
			await capture("skill_action", "Cutscene layering", "synthetic frozen stage fixture")
			var support_unit: Node = game.unit_root.get_child(0)
			var prior_promotion: String = game.monster_roster[support_unit.unit_id].get("promotion_id", "")
			game.monster_roster[support_unit.unit_id]["promotion_id"] = "slime_gate_bulwark"
			game.continuity.record_pudding_support(support_unit, support_unit)
			game.monster_roster[support_unit.unit_id]["promotion_id"] = prior_promotion
			presentation._hide_inspectors()
			await capture("skill_action_with_support", "First protection layering", "production notice on frozen stage fixture")
			presentation._unlock_gameplay_buttons()
			var support_notice := game.ui_layer.find_child("PromotionSupportNotice", true, false) as Control
			if support_notice == null or not support_notice.visible: fixture_failures.append("support notice not restored after presentation")
			var speed_panel := game.ui_layer.find_child("CombatSpeedPanel", true, false) as Control
			if speed_panel == null or not speed_panel.visible: fixture_failures.append("speed panel not restored after presentation")
			presentation.stage.queue_free()
			presentation.stage = null
			presentation.current.clear()
			game.selected_unit = null
		if screen == "chronicle":
			for tab in range(1, 4):
				var workspace: Node = game.ui_layer.find_child("ChronicleScreen", true, false)
				if workspace != null and workspace.has_method("_select_tab"):
					workspace._select_tab(tab)
					await capture("chronicle_" + str(tab), "Chronicle tab", "synthetic tab fixture")
	# Tutorial mask uses the same production path as the audited DAY1 roster.
	GameState.day = 1
	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	for i in range(game.tutorial_manager.steps.size()):
		if str(game.tutorial_manager.steps[i].id) == "TUT_030_SELECT_SLIME":
			game.tutorial_manager.current_index = i
			game.tutorial_manager.active = true
			game.onboarding_stage_id = str(game.tutorial_manager.steps[i].stage)
	game.management_tool_tab = "roster"
	game._set_screen("management", false)
	await capture("tutorial_mask", "Tutorial mask", "synthetic DAY1 step fixture")
	write_json("sweep_result.json", {"screen_count":SCREENS.size(),"captures":captures.size(),"fixture_failures":fixture_failures,"touch":UISettings.is_touch_ui()})
	print("UX_SWEEP screens=%d captures=%d fixture_failures=%s" % [SCREENS.size(),captures.size(),fixture_failures])
	get_tree().quit(0 if fixture_failures.is_empty() else 1)
