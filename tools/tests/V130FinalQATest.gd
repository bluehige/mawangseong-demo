extends "res://tools/tests/V130PlacementTest.gd"

const OUT := "res://tmp/v130_qa/"
var captured: Array[String] = []

func capture(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-filter=") and not name in arg.trim_prefix("--capture-filter=").split(","): return
	await settle(); await RenderingServer.frame_post_draw
	var path := OUT+name+".png"
	expect(get_viewport().get_texture().get_image().save_png(path)==OK,"capture saved "+name)
	captured.append(path)

func destroy_game() -> void:
	game.campaign_autosave_pending=false
	game._shutdown_audio_for_exit()
	game.queue_free(); await settle()

func create_game() -> void:
	GameState.reset()
	game=GameScene.instantiate()
	game.campaign_save_enabled=false; game.campaign_auxiliary_save_enabled=false
	game.campaign_save_v4_enabled=false; game.campaign_save_v5_enabled=false; game.campaign_save_v6_enabled=false
	add_child(game); await settle()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var touch := UISettings.is_touch_ui()
	var polish_only := OS.get_cmdline_user_args().has("--polish-only")
	get_window().size=Vector2i(1280,720) if polish_only else Vector2i(1920,1080)
	LanguageSettings.set_locale("ko",false)
	await create_game()
	game.set_process(false)
	game.onboarding_enabled=false; game.tutorial_gate_enabled=false; game.tutorial_manager.active=false
	game.story_feature_enabled=false; game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
	game.management_scene.workspace_ui.tools_expanded=false
	game._set_screen("management",false); await settle()
	await capture("day1_default_1920")
	if polish_only:
		await ui_click("FitManagementMapButton",touch)
		await capture("day1_fullplot_1280")
	GameState.day=15; game.first_promotion_completed=true
	game.campaign_stage_two_upgrade_funded=false
	game._onboarding_set_stage("CAMPAIGN_DAY_15")
	game.campaign_stage_two_unlock_ready=true
	expect(game._apply_castle_evolution_for_day(15),"real DAY15 expansion")
	game._set_screen("management",false); await settle()
	await capture("day15_expanded_default_1920")
	var original_locale: String=LanguageSettings.locale
	game._open_settings_screen(); await settle()
	await ui_click("SettingsCategory_general",touch)
	for locale in ["en","zh_CN","ko"]:
		await ui_click("SettingsLanguage_"+locale,touch)
		expect(LanguageSettings.locale==locale,"actual language button previews "+locale)
		for choice in ["ko","en","zh_CN"]:
			var button: Button=control("SettingsLanguage_"+choice)
			expect(button!=null and button.is_visible_in_tree() and button.button_pressed==(choice==locale),"native language selection "+choice)
		expect(control("SettingsRowIcon_156")!=null,"language row has existing kit icon")
	await capture("settings_languages_1920")
	for category in ["display","audio","accessibility","general","combat"]:
		await ui_click("SettingsCategory_"+category,touch)
		var icons: Array[Node]=game.ui_layer.find_children("SettingsRowIcon_*","TextureRect",true,false)
		expect(not icons.is_empty(),"settings row icons present "+category)
		for icon in icons:
			expect(icon.texture!=null,"row icon uses shipped artwork")
			for toggle in game.ui_layer.find_children("*","CheckBox",true,false):
				expect(not icon.get_global_rect().intersects(toggle.get_global_rect()),"row icon avoids checkbox input "+category)
	await ui_click("CancelSettingsButton",touch)
	expect(LanguageSettings.locale==original_locale and game.current_screen=="management","cancel restores settings origin and language")
	game.result_summary={"win":false,"rewards":{"gold":0,"mana":0,"food":0,"infamy":0},"metrics":{"alive_monsters":1,"total_monsters":3},"v122_ledger":{"throne_damage":125,"breach_progress":0.8}}
	game._set_screen("result",false); await settle()
	for id in ["gold","mana","infamy"]:
		expect((control("ResultRewardValue_"+id) as Label).text=="+0" and control("ResultRewardValue_"+id).is_visible_in_tree(),"defeat fixture shows zero reward "+id)
	await capture("defeat_rewards_1920")
	await destroy_game()
	if polish_only:
		var polish := FileAccess.open(OUT+"polish_touch.json",FileAccess.WRITE)
		polish.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captured,"touch":touch},"\t")); polish.close()
		print("V130FinalQATest polish %s checks=%d failures=%s"%["PASS" if failures.is_empty() else "FAIL",checks,failures])
		get_tree().quit(0 if failures.is_empty() else 1)
		return

	# Start a fresh campaign through actual GUI input. No stat, placement, wave,
	# day or tutorial fixtures are injected into this first defense.
	await create_game()
	game.set_process(false)
	expect(game.current_screen=="title","fresh campaign starts at title")
	await ui_click("CampaignNewGameButton",false)
	expect(game.current_screen=="name_entry","new game opens name entry")
	await ui_click("RandomNameButton",false)
	await ui_click("ConfirmNameButton",false)
	await drain_dialogue()
	expect(GameState.day==1 and game.current_screen=="management","DAY1 opening reaches management")
	print("DAY1_MAP plot=",game.graph.layout.has("plot_grid")," errors=",game.graph.layout.get("map_build_errors",[]))
	expect(game.graph.layout.has("plot_grid"),"new game uses actual free-placement plot")
	expect(game.tutorial_manager.current_step_id()=="TUT_030_SELECT_SLIME","first mandatory selection intact")
	await tap_target(game._tutorial_focus_rect("CHR_GOB").get_center())
	expect(game.tutorial_manager.current_step_id()=="TUT_040_DEPLOY_SLIME","real Gob selection advances tutorial")
	var targets: Array[String]=game._day1_goblin_tutorial_target_rooms()
	expect(targets.size()==2,"default first-day defense targets exist")
	await tap_target(game.get_global_transform_with_canvas()*game.graph.center(targets[0]))
	await drain_dialogue()
	expect(game.tutorial_manager.current_step_id()=="TUT_090_RESULT_GROWTH","deployment reaches first defense without bypass")
	game.set_process(true)
	await ui_click("StartCombatButton",false)
	for frame in range(260):
		await get_tree().process_frame
		if game.current_screen=="dialogue": await drain_dialogue()
		if game.current_screen=="combat": break
	print("FIRST_DEFENSE_ENTRY screen=",game.current_screen," logs=",game.logs)
	expect(game.current_screen=="combat","first defense starts through GUI")
	game.set_process(true)
	var deadline: int=Time.get_ticks_msec()+90000
	var combat_captured := false
	while game.current_screen in ["combat","dialogue"] and Time.get_ticks_msec()<deadline:
		if game.current_screen=="dialogue" or game.story_director.is_active(): await drain_dialogue()
		if game.combat_scene.skill_actions.is_active(): game.combat_scene.skill_actions.skip()
		if not combat_captured and game.combat_time>=3.5:
			for id in ["CombatTacticsToggle","CombatRoomTacticsToggle"]:
				expect((control(id) as Button).icon!=null,"first defense policy icon visible "+id)
			await capture("first_defense_1920")
			combat_captured=true
		await get_tree().physics_frame
	expect(game.current_screen=="result" and GameState.day==1,"actual first defense finishes on DAY1 result")
	expect(bool(game.result_summary.get("win",false)),"unmodified first defense succeeds")
	var summary := {"checks":checks,"failures":failures,"captures":captured,"day":GameState.day,"screen":game.current_screen,"win":game.result_summary.get("win",false),"combat_seconds":game.combat_time,"renderer":DisplayServer.get_name()}
	var file := FileAccess.open(OUT+"final_qa_gui.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(summary,"\t")); file.close()
	await destroy_game()
	print("V130FinalQATest %s checks=%d failures=%s"%["PASS" if failures.is_empty() else "FAIL",checks,failures])
	get_tree().quit(0 if failures.is_empty() else 1)

func tap_target(point: Vector2) -> void:
	await event_at(point,true,false); await event_at(point,false,false)
