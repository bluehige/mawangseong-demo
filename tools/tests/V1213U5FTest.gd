extends Node
const GameScene = preload("res://scenes/game/GameRoot.tscn")
const Rotation = preload("res://scripts/audio/MusicRotation.gd")
const Audit = preload("res://tools/ux_audit/Audit.gd")
var game: Node
var checks := 0
var failures: Array[String] = []
var out := "res://tmp/v1213_u5f/contract"
var capture_only := false
var captures: Array[String] = []
var observations: Array = []
var capture_filter: PackedStringArray = []

func _ready() -> void:
	get_tree().create_timer(140).timeout.connect(func(): get_tree().quit(2))
	call_deferred("run")
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL: "+message)
func settle(frames: int = 8) -> void:
	for index in frames: await get_tree().process_frame
func control(id: String) -> Control:
	return game.ui_layer.find_child(id,true,false) as Control
func click(id: String) -> void:
	var target := control(id)
	expect(target != null,"input exists "+id)
	if target == null: return
	var ancestor := target.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(target)
		ancestor = ancestor.get_parent()
	await settle()
	var point := target.get_global_transform_with_canvas()*(target.size/2)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		get_viewport().push_input(event,true)
		await get_tree().process_frame
	await settle()
func prepare() -> void:
	game.onboarding_enabled = false; game.tutorial_gate_enabled = false
	game.story_feature_enabled = false; game.tutorial_manager.active = false
	game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
	game.pause_menu_open = false
	GameState.player_name = "U5F test"; GameState.day = 7
	GameState.gold = 1000; GameState.mana = 500
	game._set_screen("management",false)
func access() -> Dictionary:
	return game.CouncilChronicleScript.normalize_accessibility(game.update4_profile.get("chronicle_update4",{}).get("accessibility",{}))
func checkpoint() -> Dictionary:
	return {"roster":game.monster_roster.duplicate(true),"campaign":game.campaign_profile.duplicate(true),"u3":game.update3_profile.duplicate(true),"u4":game.update4_profile.duplicate(true),"story":game.continuity.history.duplicate(true),"story_seen":game.onboarding_seen_dialogue_ids.duplicate(true),"day":GameState.day,"gold":GameState.gold,"mana":GameState.mana}

func settings_behavior() -> void:
	prepare(); await settle()
	var original_access := access()
	var original_ui := UISettings.snapshot()
	var original_audio := AudioSettings.snapshot()
	game._open_settings_screen(); await settle()
	await click("SettingsCategory_accessibility")
	await click("HighContrastIconsToggle")
	expect(bool(game.settings_accessibility_draft.high_contrast_icons) != bool(original_access.high_contrast_icons),"accessibility input edits draft")
	expect(access() == original_access,"draft never changes campaign before apply")
	game._preview_settings_accessibility("objective_summary",false)
	expect(not game.settings_accessibility_draft.objective_summary and not game.settings_accessibility_draft.has("floor_one_key") and not game.settings_accessibility_draft.has("floor_two_key"),"objective summary draft keeps removed floor keys absent")
	game._on_ui_scale_changed(115,null); AudioSettings.set_music_volume(0.25,false)
	await click("CancelSettingsButton")
	expect(game.current_screen == "management" and access() == original_access,"cancel restores origin and campaign access")
	expect(UISettings.snapshot() == original_ui and AudioSettings.snapshot() == original_audio,"cancel restores display and sound preview")
	game._open_pause_menu(); await settle()
	await click("PauseSettingsButton")
	await click("CancelSettingsButton")
	expect(game.current_screen == "management" and game.pause_menu_open and control("PauseResumeButton") != null,"pause menu settings returns to same menu")
	game._close_pause_menu()
	game.campaign_save_enabled = true; game.campaign_auxiliary_save_enabled = true
	game.campaign_save_v4_enabled = true; game.campaign_save_v5_enabled = true
	game.update2_cycle_seed = 1729
	game._schedule_campaign_autosave("management")
	expect(game._flush_campaign_autosave(),"seed existing campaign checkpoint")
	game._open_settings_screen(); await settle()
	var baseline_cfg := FileAccess.get_file_as_bytes("user://settings.cfg")
	UISettings.set_text_scale(1.15,false)
	AudioSettings.set_music_volume(0.35,false)
	var target_contrast := not bool(original_access.high_contrast_icons)
	game._preview_settings_accessibility("high_contrast_icons",target_contrast)
	game._preview_settings_accessibility("objective_alert_volume",0.4)
	var v2_path: String = game.campaign_save_v2_path
	game.campaign_save_v2_path = "user://missing_u5f_parent/blocked.json"
	game._apply_settings_changes(); await settle()
	expect(game.current_screen == "settings" and control("SettingsWriteFailure") != null,"campaign save failure retains editor with visible retry/cancel")
	expect(not game.settings_open_snapshot.is_empty() and access()==original_access,"campaign failure preserves snapshot and old access")
	expect(FileAccess.get_file_as_bytes("user://settings.cfg")==baseline_cfg,"later save failure rolls back general settings file")
	game.campaign_save_v2_path = v2_path
	await click("ApplySettingsButton")
	expect(game.current_screen == "management" and bool(access().high_contrast_icons)==target_contrast,"retry applies access and returns to origin")
	expect(is_equal_approx(float(access().objective_alert_volume),0.4),"floor volume commits through campaign writer")
	var saved_access := access()
	UISettings.set_text_scale(1.0,false); AudioSettings.set_music_volume(0.9,false)
	UISettings._load_settings(); AudioSettings._load_settings(); LanguageSettings._load_settings(); TutorialGuidanceHistory._load_settings(); InputSettings._load_settings()
	expect(is_equal_approx(UISettings.text_scale,1.15) and is_equal_approx(AudioSettings.music_volume,0.35),"general settings reload from established config")
	game.queue_free(); await settle(3)
	game = GameScene.instantiate()
	game._set_campaign_save_path_for_tests("user://u5f.json","user://u5f_v2.json","user://u5f_v3.json","user://u5f_v4.json","user://u5f_v5.json")
	add_child(game); await settle()
	game._continue_campaign_save(); await settle()
	game.set_process(false); game.set_physics_process(false)
	expect(access() == saved_access,"fresh game and continue retain campaign accessibility")
	var stored: Dictionary = game.CampaignSaveV5StoreScript.inspect(game.campaign_save_v5_path,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)
	game._set_screen("title",false); game._open_settings_screen(); await settle()
	expect(game.settings_accessibility_persistable and game.settings_accessibility_draft==saved_access,"title reads existing saved campaign access")
	game._preview_settings_accessibility("high_contrast_icons",not bool(saved_access.high_contrast_icons))
	game._apply_settings_changes(); await settle()
	var changed: Dictionary = game.CampaignSaveV5StoreScript.inspect(game.campaign_save_v5_path,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)
	expect(game.current_screen=="title" and changed.envelope.active_run==stored.envelope.active_run,"title access apply preserves saved gameplay checkpoint")
	var old_profile: Dictionary=stored.envelope.profile.duplicate(true)
	var new_profile: Dictionary=changed.envelope.profile.duplicate(true)
	old_profile.erase("chronicle_update4"); new_profile.erase("chronicle_update4")
	expect(new_profile==old_profile,"title access apply preserves all other profile fields")
	var old_chronicle: Dictionary=stored.envelope.profile.get("chronicle_update4",{}).duplicate(true)
	var new_chronicle: Dictionary=changed.envelope.profile.get("chronicle_update4",{}).duplicate(true)
	old_chronicle.erase("accessibility"); new_chronicle.erase("accessibility")
	expect(new_chronicle==old_chronicle,"title access apply preserves chronicle records and recorded event IDs")
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	prepare(); UISettings.set_text_scale(1.0,false)
	game._open_settings_screen(); await settle()
	var cfg := FileAccess.get_file_as_bytes("user://settings.cfg")
	DirAccess.rename_absolute("user://settings.cfg","user://settings_u5f_backup.cfg")
	DirAccess.make_dir_absolute("user://settings.cfg")
	UISettings.set_reduce_combat_effects(true,false)
	game._apply_settings_changes(); await settle()
	expect(game.current_screen == "settings" and game.settings_write_failed,"config save failure keeps editor")
	DirAccess.remove_absolute("user://settings.cfg")
	DirAccess.rename_absolute("user://settings_u5f_backup.cfg","user://settings.cfg")
	await click("CancelSettingsButton")
	expect(FileAccess.get_file_as_bytes("user://settings.cfg")==cfg,"cancel after config failure preserves saved bytes")
	expect(game.current_screen == "management" and not UISettings.reduce_combat_effects,"cancel after failure restores preview")

func records_behavior() -> void:
	prepare(); await settle()
	var before := checkpoint()
	game.continuity.record("u5f_log","푸딩","저장된 대화 · 읽기 전용")
	before=checkpoint()
	for index in 2:
		game.continuity.open_backlog(); await settle()
		await click("BacklogCloseButton")
	expect(checkpoint()==before,"dialogue backlog repeated reads execute no reward or story events")
	game._open_chronicle(); await settle()
	var screen: Control = control("ChronicleScreen")
	expect(screen.find_child("Update4AccessibilityControls",true,false)==null,"chronicle contains no settings editor")
	expect(screen.find_child("QuickDialogueToggle",true,false)==null,"quick dialogue editable in settings only")
	await click("ChronicleTab1"); await click("ChronicleSection1")
	var section: int = int(screen.section_by_tab.get(1,0))
	await click("ChronicleSettingsShortcut")
	expect(game.current_screen == "settings" and game.settings_category=="accessibility","chronicle shortcut opens same unified editor")
	await click("CancelSettingsButton")
	expect(game.current_screen=="chronicle" and control("ChronicleScreen").active_tab==1,"settings returns to same chronicle tab")
	expect(int(control("ChronicleScreen").section_by_tab.get(1,0))==section,"same chronicle section retained")
	await click("RecordsMemoryButton")
	expect(game.current_screen=="monster" and game.management_scene.monster_ui.active_tab=="memory","record companion goes to A04 memory")
	await click("MonsterBackButton")
	expect(game.current_screen=="chronicle" and control("ChronicleScreen").active_tab==1,"companion memory returns to same record position")
	await click("RecordsCompanionButton")
	expect(game.current_screen=="monster" and game.management_scene.monster_ui.list_mode=="codex","record companion goes to A04 codex")
	await click("MonsterBackButton")
	await click("ChronicleTab3")
	expect(game.current_screen=="ending_archive","ending and chronicle share records entry")
	expect(control("EndingDetailArt")==null and game.secondary_workspace.ids.is_empty(),"unlocked archive contains no hidden ending artwork or rows")
	await click("RecordsChronicleTab")
	var vm: Dictionary = control("ChronicleScreen").view_model
	vm["epilogues"] = [{"unlocked":false,"title":"SECRET_ENDING_TITLE","text":"SECRET_ENDING_BODY","lock_hint":"SECRET_ENDING_HINT"}]
	vm.update4.rival_letters = [{"unlocked":false,"subject":"SECRET_LETTER","body":"SECRET_BODY","lock_hint":"SECRET_HINT"}]
	expect(not control("ChronicleScreen")._run_epilogue_text().contains("SECRET"),"locked epilogue titles/body/hints excluded")
	expect(not control("ChronicleScreen")._rival_link_text().contains("SECRET"),"locked letter titles/body/hints excluded")
	await click("ChronicleCloseButton")
	expect(game.current_screen=="management","records returns to original gameplay screen")
	expect(checkpoint()==before,"reading all record paths replays no events, grants no resources and changes no profile")
	# An earned ending uses the original payload only; browsing it does not mark it seen again.
	var ending_id: String = str(game._ending_catalog_ids()[0])
	game.campaign_profile["ending_archive"] = {ending_id:{"first_seen_cycle":1,"seen_count":1,"last_seen_cycle":1}}
	game._open_ending_archive(); await settle()
	var earned := checkpoint()
	game.secondary_workspace.select(ending_id); await settle()
	expect(control("EndingDetailArt")!=null,"earned ending displays its existing art")
	expect(checkpoint()==earned,"re-reading earned ending triggers no event or seen counter")
	await click("CampaignConfirmButton")
	expect(game.current_screen=="management","earned archive back returns to origin")
	game._set_screen("title",false); game._open_ending_archive(); await settle()
	await click("CampaignConfirmButton")
	expect(game.current_screen=="title","title archive preserves title return")
	game._open_chronicle(); await settle(); await click("RecordsMemoryButton")
	game._set_screen("title",false); prepare(); game._set_screen("monster",false); await settle()
	await click("MonsterBackButton")
	expect(game.current_screen=="management","leaving record context never redirects later ordinary monster Back")

func music_behavior() -> void:
	var rotation = Rotation.new()
	for scene in ["title","management","combat","result","final_ending"]:
		var events: Array[String] = rotation.candidates(scene)
		expect(events.size()=={"title":2,"management":2,"combat":3,"result":2,"final_ending":1}[scene],"playlist size "+scene)
		var seen: Dictionary = {}; var previous := ""
		for index in events.size()*3:
			var event: String = rotation.next_event(scene)
			expect(events.has(event),"rotation registered candidate "+scene)
			expect(event!=previous or events.size()==1,"rotation no consecutive repeat "+scene)
			previous=event; seen[event]=true
		expect(seen.size()==events.size(),"all scene tracks cycle and wrap "+scene)
	prepare(); await settle()
	for screen_name in ["title","management","combat","result"]:
		game._set_screen(screen_name,false); await settle()
		var current: String = game.music_rotation_event
		var playing: AudioStreamPlayer = game.combat_music_player
		game._update_combat_music(screen_name,screen_name)
		expect(game.music_rotation_event==current and game.combat_music_player==playing,"same screen rebuild preserves current track "+screen_name)
		game._advance_music_rotation()
		expect(game.music_rotation_event!=current,"timer advances track without consecutive repeat "+screen_name)
		expect(game.combat_music_player.playing and game.combat_music_secondary_player.playing,"two music players overlap during crossfade "+screen_name)
		expect(game.combat_music_player.stream.loop_mode==AudioStreamWAV.LOOP_DISABLED,"multiple candidates do not loop forever "+screen_name)
		if screen_name=="combat":
			var advanced: String = game.music_rotation_event
			game._refresh_combat_music_variant()
			expect(game.music_rotation_event==advanced,"combat refresh never resets rotated track")
		game._kill_combat_music_tween()
		game._finish_combat_music_crossfade(game.combat_music_secondary_player,game.combat_music_player)
		expect(not game.combat_music_secondary_player.playing and game.combat_music_player.playing,"crossfade completion retires outgoing "+screen_name)
		print("BGM_TRANSITION "+JSON.stringify(game.music_rotation_log.back()))
	game._set_screen("management",false); await settle()
	var current_event: String = game.music_rotation_event
	game._open_settings_screen(); await settle()
	game._preview_music()
	expect(not game.combat_music_preview_player.playing,"music volume preview never overlays current BGM")
	await click("CancelSettingsButton")
	expect(game.music_rotation_event==current_event,"settings return keeps playing track")
	game._set_screen("name_entry",false)
	game._set_screen("management",false); await settle()
	if game.combat_music_tween!=null: game.combat_music_tween.custom_step(1.0)
	expect(game.combat_music_active and game.combat_music_player.playing,"rapid return cancels scheduled stop")
	game.set_meta("combat_music_risk","high")
	game._set_screen("combat",false); await settle()
	expect(game.music_rotation_state=="combat_late_risk","risk state changes are preserved")
	game.remove_meta("combat_music_risk")
	game.campaign_completed=true; game.campaign_final_battle_outcome="victory"
	game._update_combat_music("combat","result")
	expect(game.music_rotation_scene=="final_ending" and game.music_rotation_event=="music.final.ending","final victory keeps dedicated ending concept")
	expect(game.combat_music_player.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and game.music_rotation_timer.is_stopped(),"single-track scene seamlessly loops without transition churn")
	game.campaign_completed=false; game.campaign_final_battle_outcome=""
	game._stop_combat_music()
	expect(game.music_rotation_timer.is_stopped(),"stop cancels pending rotation")
	game._finish_combat_music_stop()
	expect(not game.combat_music_player.playing and not game.combat_music_secondary_player.playing,"stop retires both players")

func inspect_nodes(node: Node, id: String) -> void:
	if node is Control and node.is_visible_in_tree():
		if node is Label and not node.text.is_empty():
			expect(node.get_line_count()<=node.get_visible_line_count(),id+" complete label "+str(node.name))
			expect(not node.text.contains("�"),id+" no broken glyph "+str(node.name))
		if node is BaseButton or node is Range:
			expect(not node.tooltip_text.is_empty(),id+" tooltip "+str(node.name))
		if node is HSlider:
			expect(node.get_theme_stylebox("slider").get_minimum_size().y>=12,id+" slider track visible")
			expect(node.get_theme_stylebox("grabber_area").get_minimum_size().y>=12,id+" slider fill visible")
		if node is Button and not node is OptionButton and not node.text.is_empty():
			var width: float = node.size.x-32 if node.autowrap_mode != TextServer.AUTOWRAP_OFF else -1
			var required: Vector2 = node.get_theme_font("font").get_multiline_string_size(node.text,HORIZONTAL_ALIGNMENT_CENTER,width,node.get_theme_font_size("font_size"))
			expect(required.x<=node.size.x-16 and required.y<=node.size.y-12,id+" button text fits "+str(node.name))
	for child in node.get_children(): inspect_nodes(child,id)
func inspect(id: String) -> void:
	await settle()
	inspect_nodes(game.ui_layer,id)
	var previous: Control
	for category in ["display","audio","accessibility","general","combat"]:
		var tab := control("SettingsCategory_"+category)
		if tab!=null:
			expect(tab.get_parent().get_global_rect().encloses(tab.get_global_rect()),id+" category inside navigation "+category)
			if previous!=null: expect(not previous.get_global_rect().intersects(tab.get_global_rect()),id+" categories separated "+category)
			previous=tab
	for name in ["ApplySettingsButton","CancelSettingsButton","ChronicleCloseButton","CampaignConfirmButton"]:
		var target := control(name)
		if target!=null: expect(Rect2(Vector2.ZERO,Vector2(1920,1080)).encloses(target.get_global_rect()),id+" footer visible "+name)
	observations.append({"id":id,"screen":game.current_screen})
	if capture_only and capture_filter.has(id) and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(id+".png")); captures.append(id+".png")
func layout() -> void:
	for locale in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		for dimensions in [Vector2i(1920,1080),Vector2i(1280,720)]:
			get_window().size=dimensions
			prepare(); game._open_settings_screen(); await settle()
			for category in ["display","audio","accessibility","general","combat"]:
				game._select_settings_category(category)
				var id := "%s_%d_%s"%[locale,dimensions.x,category]
				await inspect(id)
				var scroll := control("SettingsFieldsScroll") as ScrollContainer
				scroll.scroll_vertical = 10000; await inspect(id+"_tail")
			game._cancel_settings_changes()
			game._open_chronicle(); await settle()
			await inspect("%s_%d_chronicle"%[locale,dimensions.x])
			for tab in [1,2]:
				control("ChronicleScreen")._select_tab(tab)
				await inspect("%s_%d_chronicle_%d"%[locale,dimensions.x,tab])
			var earned_id: String = str(game._ending_catalog_ids()[0])
			game.campaign_profile["ending_archive"] = {earned_id:{"first_seen_cycle":1,"seen_count":1,"last_seen_cycle":1}}
			game._open_ending_archive(); await settle()
			await inspect("%s_%d_archive"%[locale,dimensions.x])
			game._return_from_records()
			game._open_pause_menu(); await settle()
			await inspect("%s_%d_menu"%[locale,dimensions.x])
			game._close_pause_menu()
			game._set_screen("title",false); game._open_settings_screen()
			game._select_settings_category("accessibility"); await settle()
			if not game.settings_accessibility_persistable:
				expect((control("HighContrastIconsToggle") as CheckBox).disabled,"fresh title keeps campaign access condition")
				expect(control("SettingsCampaignAccessNotice")!=null,"fresh title explains campaign access condition")
			await inspect("%s_%d_title_accessibility"%[locale,dimensions.x])
			game._cancel_settings_changes()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output-dir="): out=arg.trim_prefix("--output-dir=")
		if arg.begins_with("--capture-filter="): capture_filter=arg.trim_prefix("--capture-filter=").split(",")
	capture_only=OS.get_cmdline_user_args().has("--capture-only")
	expect(ProjectSettings.globalize_path("user://").replace("\\","/").contains("/tmp/v1213_u5f/"),"isolated APPDATA")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	GameState.reset(); LanguageSettings.set_locale("ko",false)
	UISettings.reset_defaults(false); AudioSettings.reset_defaults(false)
	game=GameScene.instantiate()
	game._set_campaign_save_path_for_tests("user://u5f.json","user://u5f_v2.json","user://u5f_v3.json","user://u5f_v4.json","user://u5f_v5.json")
	game.campaign_save_enabled=false; game.campaign_auxiliary_save_enabled=false
	add_child(game); await settle()
	game._debug_skip_onboarding(); game.set_process(false); game.set_physics_process(false)
	if not capture_only:
		await settings_behavior(); await records_behavior(); await music_behavior()
	await layout()
	var file:=FileAccess.open(out.path_join("result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"observations":observations,"music_log":game.music_rotation_log},"\t")); file.close()
	print("V1213_U5F_TEST: %s (%d checks, %d failures, %d captures)"%["PASS" if failures.is_empty() else "FAIL",checks,failures.size(),captures.size()])
	game.queue_free(); await settle(3); get_tree().quit(0 if failures.is_empty() else 1)
