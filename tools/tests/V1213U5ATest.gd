extends Node

const GameScene = preload("res://scenes/game/GameRoot.tscn")
const Title = preload("res://scripts/ui/TitleWorkspaceUI.gd")
const Audit = preload("res://tools/ux_audit/Audit.gd")
const OUT := "res://tmp/v1213_u5a"
var game: Node
var checks := 0
var clicks := 0
var failures: Array[String] = []
var captures: Array = []
var groups: Array = []
var render := false
var capture_only := false

func _ready() -> void:
	get_tree().create_timer(180).timeout.connect(func(): get_tree().quit(2))
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: " + message)

func settle(frames: int = 10) -> void:
	for i in range(frames): await get_tree().process_frame

func control(id: String) -> Control:
	return game.ui_layer.find_child(id, true, false) as Control

func click(id: String) -> void:
	var button := control(id) as BaseButton
	expect(button != null and button.is_visible_in_tree(), "clickable " + id)
	if button == null: return
	clicks += 1
	push_click(button)
	await settle()

func push_click(button: BaseButton) -> void:
	var point := button.get_global_transform_with_canvas() * (button.size / 2)
	print("U5_CLICK %s rect=%s point=%s" % [button.name,button.get_global_rect(),point])
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)

func capture(id: String) -> void:
	if not render: return
	await settle(16)
	var fps_sample := {}
	if id in ["ko_1920x1080_title", "ko_1920x1080_dialogue"]:
		await settle(90)
		var started := Time.get_ticks_usec()
		await settle(120)
		fps_sample = {"frames":120,"elapsed_seconds":float(Time.get_ticks_usec()-started)/1000000.0,"engine_fps":Engine.get_frames_per_second()}
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(OUT.path_join(id + "_content.png"))
	var window := DisplayServer.window_get_size()
	var presented := image
	if window.x == 2560 and image.get_size() == Vector2i(1920,1080):
		presented = Image.create(2560,1080,false,Image.FORMAT_RGBA8)
		presented.fill(Color.BLACK)
		presented.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(320,0))
	presented.save_png(OUT.path_join(id + ".png"))
	var inspector = Audit.new()
	inspector.game = game
	var controls: Array = []
	inspector.collect(game.ui_layer, controls)
	inspector.free()
	captures.append({"id":id,"screen":game.current_screen,"window_size":str(window),"content_size":str(image.get_size()),"presentation":"engine framebuffer; 2560 uses exact content + keep-aspect black margins", "fps":Engine.get_frames_per_second(),"settled_fps_sample":fps_sample,"controls":controls})

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").replace("\\","/").contains("/tmp/v1213_u5a/"), "isolated APPDATA")
	if not failures.is_empty(): get_tree().quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	render = DisplayServer.get_name() != "headless"
	capture_only = OS.get_cmdline_user_args().has("--capture-only")
	Engine.max_fps = 60
	GameState.reset()
	LanguageSettings.set_locale("ko", false)
	game = GameScene.instantiate()
	game._set_campaign_save_path_for_tests("user://u5_campaign.json","user://u5_v2.json","user://u5_v3.json","user://u5_v4.json","user://u5_v5.json")
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false
	game.campaign_save_v5_enabled = false
	add_child(game)
	await settle()
	game.set_process(false)
	game.set_physics_process(false)
	if not capture_only:
		await title_and_flow()
		await dialogue_contracts()
		await continue_contract()
	if render and capture_only:
		game.story_director.cancel_active_scene()
		game.onboarding_dialogue_queue.clear()
		game.onboarding_enabled = false
		game.tutorial_gate_enabled = false
		game.tutorial_manager.active = false
		for size in [Vector2i(1920,1080), Vector2i(2560,1080), Vector2i(1280,720)]:
			DisplayServer.window_set_size(size)
			await settle()
			for locale in ["ko","en","zh_CN"]:
				LanguageSettings.set_locale(locale,false)
				var prefix := "%s_%dx%d_" % [locale,size.x,size.y]
				game._set_screen("title",false)
				await capture(prefix + "title")
				game.story_director.start_scene("STORY_D01_MANAGEMENT_ENTRY",game._story_context(),"management","",true)
				game.story_director.advance(true)
				game.story_director.advance(true)
				game._story_show_active_scene()
				await capture(prefix + "dialogue")
				game._story_advance_dialogue(true)
				await capture(prefix + "dialogue_reply")
				game.story_director.cancel_active_scene()
				game._onboarding_begin_dialogue(game._onboarding_essential_opening_entries(), "management")
				game.onboarding_dialogue_index = 1
				game._story_refresh_dialogue_ui()
				await capture(prefix + "legacy")
				game.onboarding_dialogue_queue.clear()
				game._set_screen("combat",false)
				game.story_director.start_scene("STORY_D01_COMBAT_TIME_01",game._story_context(),"combat","",true)
				if not game.story_director.is_active():
					game.story_director.start_scene("STORY_D01_MANAGEMENT_ENTRY",game._story_context(),"combat","",true)
				game.story_combat_previous_paused = game.combat_scene.requested_pause
				game.story_combat_overlay_open = true
				game.combat_scene.set_pause_state(true,false)
				game.story_presenter.build_combat_overlay()
				await capture(prefix + "combat_overlay")
				game.story_director.cancel_active_scene()
				game._story_close_combat_overlay()
				await settle()
	var result := {"checks":checks,"failures":failures,"clicks":clicks,"groups":groups,"captures":captures,"renderer":DisplayServer.get_name()}
	var file := FileAccess.open(OUT.path_join("capture_result.json" if capture_only else "contract_result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"));file.close()
	print("U5-A checks=%d failures=%d clicks=%d" % [checks,failures.size(),clicks])
	if not capture_only and failures.is_empty():
		game._set_screen("title",false)
		await settle()
		print("U5_TITLE_QUIT_REAL_INPUT")
		# No pending click coroutine on the real process-exit path.
		get_tree().create_timer(0.3).timeout.connect(func():
			push_error("Title Quit callback did not exit")
			get_tree().quit(1))
		push_click(control("TitleQuitButton") as BaseButton)
		return
	game.queue_free()
	await settle()
	get_tree().quit(0 if failures.is_empty() else 1)

func title_and_flow() -> void:
	expect(game.current_screen == "title", "title boot")
	expect(get_viewport().gui_get_focus_owner() == control("CampaignNewGameButton"), "title initial keyboard focus")
	expect((control("CampaignContinueButton") as Button).disabled, "fresh save Continue disabled")
	for id in ["CampaignNewGameButton","CampaignContinueButton","TitleSettingsButton","EndingArchiveButton","TitleQuitButton"]:
		var b := control(id) as Button
		expect(b != null and not b.get_signal_connection_list("pressed").is_empty(), "existing callback " + id)
		expect(b.get_theme_font_size("font_size") >= 30 and b.size.x >= 520, "title menu reference proportion " + id)
	expect(control("TitleLanguageGlobe") != null, "language globe in shared group")
	expect(control("TitleUpdateNotesButton").size.x <= 64, "compact update notes")
	await click("TitleUpdateNotesButton")
	expect(control("UpdateNotesOverlay") != null, "update notes callback")
	game.continuity.acknowledge_update()
	await settle()
	var catalog := {"ending_backgrounds":[{"ending_id":"unseen","background_id":"secret"},{"ending_id":"seen","background_id":"unlocked"}]}
	expect(Title.choose_background_id({}, {}, catalog) == "default", "locked endings select no background")
	expect(Title.choose_background_id({"ending_catalog_codes":{"run":"seen"}}, {}, catalog) == "unlocked", "reached ending selects background hook")
	for locale in ["en","zh_CN","ko"]:
		await click("TitleLanguage_" + locale)
		expect(LanguageSettings.locale == locale, "language immediate " + locale)
		var hangul := RegEx.new()
		hangul.compile("[가-힣]")
		for id in ["CampaignNewGameButton","CampaignContinueButton","TitleSettingsButton","EndingArchiveButton","TitleQuitButton"]:
			expect(locale == "ko" or hangul.search((control(id) as Button).text) == null, "title menu localized " + locale + "/" + id)
		var saved := ConfigFile.new()
		expect(saved.load(LanguageSettings.SETTINGS_PATH) == OK and str(saved.get_value("interface","locale","")) == locale, "language persisted " + locale)
	await click("TitleSettingsButton")
	expect(game.current_screen == "settings", "settings callback")
	game._close_settings_screen()
	await settle()
	await click("EndingArchiveButton")
	expect(game.current_screen == "ending_archive", "codex callback")
	game._set_screen("title",false)
	await settle()
	var before := clicks
	await click("CampaignNewGameButton")
	expect(game.current_screen == "name_entry", "new game callback")
	await click("RandomNameButton")
	await click("ConfirmNameButton")
	expect(game.current_screen == "dialogue", "name enters actual opening")
	var opening_count: int = game.onboarding_dialogue_queue.size()
	await click("LegacyStoryAutoButton")
	for i in range(opening_count):
		game._story_tick_auto(10.0)
		await settle()
	expect(game.onboarding_dialogue_index == opening_count - 1 and not game.story_presenter.legacy_auto_enabled, "opening auto stops at final line")
	await click("LegacyNextButton")
	expect(game.story_director.is_active(), "opening completion enters management dialogue once")
	var management_count: int = game.story_director.cue_count()
	await click("StoryAutoButton")
	for i in range(management_count):
		game._story_tick_auto(10.0)
		await settle()
	await click("StoryNextButton")
	expect(game.current_screen == "management" and GameState.day == 1, "actual new game reaches integrated DAY1 management entry")
	expect(game.current_screen == "management", "DAY1 management ready after brief")
	groups.append({"id":"new_game_to_day1_management","input_clicks":clicks-before,"opening_lines":opening_count,"management_lines":management_count,"baseline":17,"note":"New game + random name + confirm + two auto/continue groups; intrusion forecast is integrated without an extra input. Real UI input; auto timer advanced deterministically."})

func dialogue_contracts() -> void:
	game.onboarding_enabled = false;game.tutorial_gate_enabled = false;game.tutorial_manager.active = false
	for expression in ["dry","dry_happy","stern","tutorial","neutral","briefing","serious"]:
		for compact in [false,true]:
			var path: String = game._onboarding_speaker_portrait_path("CHR_BATI",expression,compact)
			expect(path.contains("/v1213_bati_cute/") and ResourceLoader.exists(path), "Bati runtime alias " + expression + str(compact))
	for id in ["STORY_D01_MANAGEMENT_ENTRY","STORY_D01_PRECOMBAT","STORY_D01_RESULT_WIN"]:
		game.story_director.cancel_active_scene()
		var started: bool = game.story_director.start_scene(id,game._story_context(),"management","",true)
		expect(started, "long story group " + id)
		if not started: continue
		game._story_show_active_scene(); await settle()
		dialogue_visual_contract(false)
		expect(not game.story_director.auto_enabled, "group defaults manual " + id)
		expect((control("StorySkipButton") as Button).disabled == not game.story_director.skip_allowed(), "unread skip guard " + id)
		var old_left: Vector2 = control("DialogueStandingLeft").position
		var policy_start := clicks
		await click("StoryAutoButton")
		expect((control("StoryAutoButton") as Button).button_pressed and control("StoryAutoButton").theme_type_variation == "KitPrimary", "auto visibly highlighted")
		var cursor: int = game.story_director.cursor
		var timer: float = game.story_auto_remaining
		await click("DialogueBacklogButton")
		game._story_tick_auto(100)
		expect(game.story_director.cursor == cursor and is_equal_approx(game.story_auto_remaining,timer), "log pauses auto " + id)
		game.continuity.close_backlog();await settle()
		await click("DialogueMenuButton")
		game._story_tick_auto(100)
		expect(game.story_director.cursor == cursor, "menu pauses auto " + id)
		game._close_pause_menu();await settle()
		game._story_tick_auto(10);await settle()
		expect(control("DialogueStandingLeft").position == old_left, "participant seat retained " + id)
		var cue: Dictionary = game._story_resolve_cue_speaker(game.story_director.current_cue())
		for name in ["DialogueStandingLeft","DialogueStandingRight"]:
			var image := control(name)
			if image != null: expect(is_equal_approx(image.modulate.r,1.0 if image.get_meta("speaker_id") == cue.speaker_id else 0.5), "speaker luminance " + name)
		var count: int = game.story_director.cue_count()
		for i in range(count): game._story_tick_auto(10);await settle()
		expect(game.story_director.cursor == count-1 and not game.story_director.auto_enabled, "auto final hold " + id)
		var group_before := clicks
		await click("StoryNextButton")
		expect(not game.story_director.is_active(), "complete group once " + id)
		var screen_instance: int = game.ui_layer.get_child(0).get_instance_id()
		game._story_advance_dialogue(true)
		expect(game.ui_layer.get_child(0).get_instance_id() == screen_instance, "duplicate completion ignored " + id)
		groups.append({"id":id,"lines":count,"policy_inputs":clicks-policy_start-2,"final_continue_inputs":clicks-group_before,"extra_probe_inputs":"log/menu probe clicks excluded"})
		expect(clicks-policy_start-2 == 2, "two policy inputs " + id)
	game.story_director.start_scene("STORY_D01_MANAGEMENT_ENTRY",game._story_context(),"management","",true)
	game._story_show_active_scene();await settle();await click("StoryAutoButton")
	game.story_auto_remaining = 0.05
	game.set_physics_process(true)
	await get_tree().create_timer(0.3).timeout
	game.set_physics_process(false)
	expect(game.story_director.cursor == 1 and game.story_director.auto_enabled, "actual story runtime timer displays next cue")
	await click("StoryNextButton")
	expect(not game.story_director.auto_enabled, "story manual input disables auto")
	game.story_director.cancel_active_scene()
	for kind in ["opening_start","management_open","precombat_confirmed","win"]:
		var entries: Array = []
		for i in range(4 if kind == "opening_start" else 8): entries.append({"speaker":"CHR_BATI" if i%2==0 else "CHR_DARKLORD_PLAYER","trigger":kind,"text":"U5 automatic line %d"%i,"text_ko":"U5 자동 대사 %d"%i})
		game._onboarding_begin_dialogue(entries,"management");await settle()
		dialogue_visual_contract(true)
		var policy_start := clicks
		await click("LegacyStoryAutoButton")
		var timer: float = game.story_presenter.legacy_auto_remaining
		await click("DialogueBacklogButton")
		game._story_tick_auto(100)
		expect(game.onboarding_dialogue_index == 0 and is_equal_approx(game.story_presenter.legacy_auto_remaining,timer), "legacy log pauses " + kind)
		game.continuity.close_backlog();await settle()
		await click("DialogueMenuButton");game._story_tick_auto(100)
		expect(game.onboarding_dialogue_index == 0, "legacy menu pauses " + kind)
		game._close_pause_menu();await settle()
		for i in range(entries.size()): game._story_tick_auto(10);await settle()
		expect(game.onboarding_dialogue_index == entries.size()-1 and not game.story_presenter.legacy_auto_enabled, "legacy final hold " + kind)
		await click("LegacyNextButton")
		var screen_instance: int = game.ui_layer.get_child(0).get_instance_id()
		game._onboarding_advance_dialogue()
		expect(game.onboarding_dialogue_queue.is_empty() and game.ui_layer.get_child(0).get_instance_id() == screen_instance, "legacy callback once " + kind)
		groups.append({"id":"legacy_"+kind,"lines":entries.size(),"policy_inputs":clicks-policy_start-2,"fixture":"synthetic same-size group; log/menu probe clicks excluded"})
		expect(clicks-policy_start-2 == 2, "two legacy policy inputs " + kind)
	game._onboarding_begin_dialogue([{"speaker":"CHR_BATI","trigger":"management_open","text":"first"},{"speaker":"CHR_DARKLORD_PLAYER","text":"second"}],"management")
	await settle();await click("LegacyStoryAutoButton");await click("LegacyNextButton")
	expect(not game.story_presenter.legacy_auto_enabled, "legacy manual input disables auto")
	game._onboarding_begin_dialogue([{"speaker":"CHR_BATI","trigger":"management_open","text":"first"},{"speaker":"CHR_DARKLORD_PLAYER","text":"second"}],"management")
	await settle();await click("LegacyStoryAutoButton")
	game.story_presenter.legacy_auto_remaining = 0.05
	game.set_physics_process(true)
	await get_tree().create_timer(0.3).timeout
	game.set_physics_process(false)
	expect(game.onboarding_dialogue_index == 1, "actual runtime auto timer displays next cue")
	game.onboarding_dialogue_queue.clear()
	for prior in [false,true]:
		game._set_screen("combat",false)
		game.combat_scene.set_pause_state(prior,false)
		game.story_director.start_scene("STORY_D01_COMBAT_TIME_01",game._story_context(),"combat","",true)
		game._story_show_active_scene()
		await settle()
		expect(control("StoryCombatDialogueOverlay") != null and game.combat_scene.requested_pause, "combat overlay paused")
		dialogue_visual_contract(false)
		expect(not control("CombatCommandBar").visible, "combat dialogue hides lower HUD")
		var cursor: int = game.story_director.cursor
		game._open_settings_screen()
		await settle();await click("SettingsCategory_general")
		game._on_language_preview_changed("en")
		await settle()
		game._story_tick_auto(100)
		var language := control("LanguageOption")
		expect(game.current_screen == "settings" and control("StoryCombatDialogueOverlay") == null and language != null and language.is_visible_in_tree(), "settings language preview stays above combat dialogue")
		expect(game.story_director.cursor == cursor, "settings pauses combat dialogue")
		game._close_settings_screen();await settle()
		expect(game.current_screen == "combat" and control("StoryCombatDialogueOverlay") != null, "settings returns to same combat dialogue")
		var count: int = game.story_director.cue_count()
		for i in range(count): game._story_advance_dialogue(true);await settle()
		expect(game.combat_scene.requested_pause == prior, "combat pause owner restored " + str(prior))
		expect(control("CombatCommandBar").visible, "combat dialogue restores HUD")
	expect(game.story_presenter.background_path({}) == game.story_presenter.THRONE_BACKGROUND, "default throne backdrop")
	expect(game.story_presenter.background_path({"background":"res://assets/ui/onboarding/scenes/scene_rookie_cave_start.png"}).ends_with("scene_rookie_cave_start.png"), "specified scene backdrop wins")

func dialogue_visual_contract(legacy: bool) -> void:
	var body := control("DialogueText" if legacy else "StoryDialogueText")
	var speaker := control("DialogueSpeakerLabel" if legacy else "StorySpeakerLabel")
	expect(body.get_theme_font_size("normal_font_size") >= 32, "dialogue body minimum 32")
	expect(speaker.get_theme_font_size("font_size") >= 26, "dialogue speaker minimum 26")
	var skip := control("LegacyStorySkipButton" if legacy else "StorySkipButton") as Button
	expect(control("DialogueSkipLock").is_visible_in_tree() == skip.disabled, "unread skip lock visibility")
	for id in ["DialogueBacklogButton", "LegacyStoryAutoButton" if legacy else "StoryAutoButton", "LegacyStorySkipButton" if legacy else "StorySkipButton"]:
		expect(control(id + "Caption") != null and (control(id) as Button).get_theme_constant("icon_max_width") >= 64, "large labeled toolbar " + id)
	for name in ["DialogueStandingLeft", "DialogueStandingRight"]:
		var image := control(name)
		if image != null and image.get_meta("speaker_id") == "CHR_BATI":
			var standing_rect := image.get_global_rect()
			for id in ["DialogueBacklogButton", "LegacyStoryAutoButton" if legacy else "StoryAutoButton", "LegacyStorySkipButton" if legacy else "StorySkipButton", "DialogueMenuButton"]:
				expect(not standing_rect.intersects(control(id).get_global_rect()), "Bati avoids toolbar " + id)

func continue_contract() -> void:
	game.story_director.cancel_active_scene();game.onboarding_dialogue_queue.clear()
	game.story_combat_overlay_open = false
	game._onboarding_reset_game();game._debug_skip_onboarding()
	GameState.player_name = "U5 isolated save"
	game.campaign_save_enabled = true;game.campaign_auxiliary_save_enabled = true;game.campaign_save_v4_enabled = true;game.campaign_save_v5_enabled = true
	game._set_screen("management",false)
	expect(game.continuity.save_now(), "create isolated valid checkpoint")
	game._set_screen("title",false);await settle()
	expect(not (control("CampaignContinueButton") as Button).disabled, "valid Continue enabled")
	await click("CampaignContinueButton")
	expect(game.current_screen != "title" and GameState.player_name == "U5 isolated save", "Continue callback loads saved run")
	game.campaign_save_notice = "U5 rejected save notice"
	game._set_screen("title",false);await settle()
	expect((control("CampaignContinueButton") as Button).disabled, "save notice blocks Continue")
	game.campaign_save_notice = ""
	for raw in ["{\"version\":5}", "{\"version\":999}"]:
		var file := FileAccess.open(game.campaign_save_v5_path,FileAccess.WRITE)
		file.store_string(raw);file.close()
		game._set_screen("title",false);await settle()
		expect((control("CampaignContinueButton") as Button).disabled, "corrupt/unsupported Continue disabled " + raw)
		var status := control("TitleSaveStatus") as Label
		expect(status.get_line_count() <= status.get_visible_line_count(), "invalid save explanation fits")
	game.campaign_save_enabled = false;game.campaign_auxiliary_save_enabled = false;game.campaign_save_v4_enabled = false;game.campaign_save_v5_enabled = false
