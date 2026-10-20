extends Node
const OUT := "res://_mockup/game_step14_start/"
const Grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
var game: Node
var trace: Array = []
var mode := "before"
var checks := 0
var failures: Array = []

func _ready() -> void:
	run.call_deferred()

func frames(count: int = 3) -> void:
	for i in count: await get_tree().process_frame

func record(tag: String) -> void:
	var line := {}
	if game.story_director.is_active(): line = game.story_director.current_cue().duplicate(true)
	elif not game.onboarding_dialogue_queue.is_empty(): line = game.onboarding_dialogue_queue[game.onboarding_dialogue_index].duplicate(true)
	trace.append({"tag":tag,"screen":game.current_screen,"stage":game.onboarding_stage_id,"story":game.story_director.current_scene_id,"line":line,"tutorial":game.tutorial_manager.current_step_id()})

func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames()
	await RenderingServer.frame_post_draw
	var picture := get_viewport().get_texture().get_image()
	picture.resize(1280,720,Image.INTERPOLATE_LANCZOS)
	picture.save_png(OUT+id+".png")

func dialogues() -> void:
	for n in 160:
		await frames()
		if game.current_screen!="dialogue": return
		record("dialogue")
		if n==0: await capture("before_dialogue_"+str(trace.size()))
		if game.story_director.is_active(): game._story_advance_dialogue()
		else: game._onboarding_advance_dialogue()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--start-mode="): mode = arg.get_slice("=",1)
	if mode!="before":
		await run_after()
		return
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	LanguageSettings.set_locale("ko",false)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
	add_child(game)
	await frames()
	record("boot"); await capture("before_title")
	game._onboarding_start_new_game()
	await frames(); record("new"); await capture("before_name")
	game.onboarding_name_input.text = "테스트마왕"
	game._onboarding_confirm_name()
	await dialogues()
	await frames(12); record("management"); await capture("before_management")
	var view: Node = game.ui_layer.get_node_or_null("ApprovedMapManagement")
	if view!=null:
		view.monster_ui.assignments = view.Monsters.auto_place(view.placement,view.monster_ui.members,view.monster_ui.unlocked(),view.monster_ui.food_income)
		view.start_battle()
		await dialogues(); await frames(8)
		view = game.ui_layer.get_node_or_null("ApprovedMapManagement")
		if view!=null and view.battle==null: view.start_battle()
		if view!=null and view.battle!=null:
			var battle = view.battle
			view.set_physics_process(false)
			for i in 18000:
				if not battle.running: break
				battle.physics_process(1.0/60)
				for unit in game.monster_units+game.enemy_units:
					if is_instance_valid(unit): unit.set_physics_process(false); unit._physics_process(1.0/60)
				if i%120==0: await frames(1)
			await frames(); record("battle_end"); await capture("before_battle_end")
	var file := FileAccess.open(OUT+"before_trace.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(trace,"\t")); file.close()
	game._shutdown_audio_for_exit(); game.campaign_autosave_pending = false
	game.queue_free(); await frames(3)
	get_tree().quit()

func expect(ok: bool, content: String) -> void:
	checks += 1
	if not ok: failures.append(content); print("FAIL ",content)

func press(id: String) -> void:
	var target := game.ui_layer.find_child(id,true,false) as Button
	expect(target!=null and not target.disabled,"clickable "+id)
	if target!=null and not target.disabled: target.pressed.emit()
	await frames(5)

func after_dialogues() -> void:
	for n in 180:
		await frames(5)
		if game.current_screen!="dialogue": return
		record("after_dialogue")
		if game.story_director.is_active(): game._story_advance_dialogue()
		else: game._onboarding_advance_dialogue()
	expect(false,"dialogue queue terminates")

func run_after() -> void:
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	ProjectSettings.set_setting("debug/start_flow14",true)
	LanguageSettings.set_locale("ko",false)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
	add_child(game); await frames(5)
	game.set_physics_process(false)
	expect(game.ui_layer.find_child("TitleStartButton",true,false)!=null,"first screen has Start")
	expect(game.ui_layer.find_child("CampaignNewGameButton",true,false)==null,"menu hidden until Start")
	await capture("title")
	for locale in ["en","zh_CN","ko"]:
		await press("TitleLanguage_"+locale)
		expect(LanguageSettings.locale==locale,"immediate locale "+locale)
		var config := ConfigFile.new(); config.load("user://settings.cfg")
		expect(config.get_value("interface","locale","")==locale,"persisted locale "+locale)
		if locale=="en": await capture("title_en")
		if locale=="zh_CN": await capture("title_zh")
	await press("TitleStartButton")
	expect(game.ui_layer.find_child("CampaignContinueButton",true,false).disabled,"no save disables Continue")
	expect(game.ui_layer.find_child("TitleAchievementsButton",true,false).disabled,"achievement placeholder disabled")
	await capture("menu_no_save")
	await press("CampaignNewGameButton")
	expect(game.current_screen=="prologue","New starts prologue")
	await capture("prologue_1")
	for i in 6:
		var key := InputEventKey.new(); key.pressed = true; key.keycode = KEY_SPACE
		game._input(key); await frames(2)
	expect(game.start_flow.prologue_index==6,"space advances all seven lines")
	await capture("prologue_last")
	await press("PrologueNext")
	expect(game.start_flow.naming_turn==0,"Bati asks before input")
	await press("NamingNext"); await press("NamingNext")
	expect(game.onboarding_name_input!=null,"two turns lead to name input")
	await capture("name_input")
	for invalid in [""," ","abcdefghijklmn","{name}","test/name","bad\nname","<b>","x:y","x|y"]:
		expect(not game.start_flow.valid_name(invalid),"invalid name rejected "+invalid)
	expect(game.start_flow.valid_name("Arden"),"valid name accepted")
	await press("RandomNameButton")
	expect(game.start_flow.valid_name(game.onboarding_name_input.text),"default suggestion valid")
	game.onboarding_name_input.text = "Arden"; game._onboarding_name_changed("Arden")
	await press("ConfirmNameButton")
	expect(game.onboarding_dialogue_queue.size()==1 and str(game.onboarding_dialogue_queue[0].text).contains("Arden"),"one confirmation uses chosen name")
	record("name_confirmation")
	game.ui_layer.find_child("LegacyNextButton",true,false).grab_focus()
	var advance_key := InputEventKey.new(); advance_key.pressed = true; advance_key.keycode = KEY_SPACE; advance_key.physical_keycode = KEY_SPACE
	game._input(advance_key); await frames(5)
	expect(game.story_director.current_scene_id=="STORY_D01_MANAGEMENT_ENTRY","Space advances confirmation even with next-button focus")
	record("management_enter")
	game.ui_layer.find_child("StoryNextButton",true,false).grab_focus()
	var cursor_before: int = game.story_director.cursor
	game._input(advance_key); await frames(3)
	expect(game.story_director.cursor==cursor_before+1,"Space advances main story with button focus")
	await after_dialogues(); await frames(12)
	var view: Node = game.ui_layer.get_node_or_null("ApprovedMapManagement")
	expect(view!=null and game.start_flow.intro_complete,"main story then eligible overlays then guide")
	expect(view.monster_ui.unlocked().size()==3,"new DAY1 starts with the three prologue companions")
	expect(game.ui_layer.find_child("TutorialOverlay",true,false)==null,"legacy tutorial absent")
	expect(game.start_flow.guide_step==1,"guide starts at map landmarks")
	await capture("day1_guide_1")
	for locale in ["en","zh_CN","ko"]:
		LanguageSettings.set_locale(locale,false); await frames(4)
		var body: Label = game.ui_layer.find_child("StartGuideText",true,false)
		expect(body!=null and body.get_line_count()*body.get_theme_font("font").get_height(body.get_theme_font_size("font_size"))<=body.size.y,"landmark guide text fits "+locale)
		if locale=="en": await capture("day1_guide_en")
		if locale=="zh_CN": await capture("day1_guide_zh")
	# Existing buildings skip step 2 without requiring a duplicate purchase.
	game.start_flow.advance_guide(); await frames(5)
	expect(game.start_flow.guide_step==3,"existing building skips build guide")
	# Empty test-layout variant exercises the actual build action as well.
	var prior: Dictionary = view.placement.duplicate(true)
	view.placement.buildings = view.placement.buildings.filter(func(b): return b.fixed)
	view.placement = view.Placement.rebuild(view.placement)
	view.render_map(); game.start_flow.guide_step = 2; await frames(4)
	await capture("day1_guide_2")
	expect(not view.start_battle(),"guide prevents unprepared battle")
	var old_barracks: Dictionary = prior.buildings.filter(func(b): return b.kind=="barracks")[0]
	var candidate: Dictionary = view.Placement.preview(view.placement,"barracks",old_barracks.rect.position)
	expect(candidate.get("ok",false),"real build preview legal")
	if candidate.get("ok",false):
		# The same candidate layout is committed by the live build handler.
		view.apply_action(candidate)
	await frames(5)
	expect(game.start_flow.guide_step==3,"building advances to placement")
	view.monster_ui.set_mode("place"); await frames(4)
	await capture("day1_guide_3")
	var core: Array = []
	for id in view.monster_ui.members:
		if view.monster_ui.members[id].species_id in ["slime","goblin","imp"]: core.append(id)
	var assignments: Dictionary = view.Monsters.auto_place(view.placement,view.monster_ui.members,core,view.monster_ui.food_income)
	for id in assignments: expect(view.monster_ui.apply_drop(id,assignments[id]),"live drop "+id)
	await frames(6)
	expect(game.start_flow.guide_step==4,"all three placements required")
	await capture("day1_guide_4")
	var saved_flow: Dictionary = game.start_flow.snapshot()
	game.start_flow.restore(saved_flow)
	expect(game.start_flow.guide_step==4,"guide progress round trip")
	UISettings.set_preferred_combat_speed(2.0,false); UISettings.set_remember_combat_speed(true,false)
	view.start_battle(); await frames(5)
	expect(game.story_director.current_scene_id=="STORY_D01_PRECOMBAT","precombat scene precedes battle")
	await after_dialogues(); await frames(8)
	view = game.ui_layer.get_node_or_null("ApprovedMapManagement")
	expect(view!=null and view.battle!=null,"battle begins after dialogue")
	if view!=null and view.battle!=null:
		expect(game.combat_speed==2.0,"configured default battle speed is used")
		UISettings.set_preferred_combat_speed(1.0,false)
		expect(game.combat_paused and not game.start_flow.command_seen,"command tutorial pauses combat once")
		await capture("day1_commands")
		await press("StartGuideNext")
		expect(game.start_flow.command_seen and not game.combat_paused,"acknowledging commands resumes")
		var battle = view.battle
		game._open_pause_menu(); game._open_settings_screen(true); await frames(5)
		expect(game.start_flow.suspended_map==view and game.combat_paused,"battle view survives opening settings")
		game._cancel_settings_changes(); await frames(5); game._close_pause_menu(); await frames(3)
		expect(game.ui_layer.get_node_or_null("ApprovedMapManagement")==view and view.battle==battle,"settings returns to same battle")
		view.set_physics_process(false)
		for i in 18000:
			if not battle.running: break
			battle.physics_process(1.0/60)
			for unit in game.monster_units+game.enemy_units:
				if is_instance_valid(unit): unit.set_physics_process(false); unit._physics_process(1.0/60)
			if i%120==0: await frames(1)
		await frames(8)
		expect(not battle.running,"first battle reaches natural outcome")
		print("NATURAL_FIRST_BATTLE: ",battle.last_result)
		record("after_battle"); await capture("day1_battle_end")
		await after_dialogues(); await frames(5)
		expect(game.current_screen=="result","outcome dialogue leads to result")
		# Verify the alternate result delivery too; no claim of natural victory.
		game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
		game._story_begin_trigger("result_win",{},"result","show_result",true,1)
		expect(game.story_director.current_scene_id=="STORY_D01_RESULT_WIN","victory dialogue is connected")
		await after_dialogues()
	await verify_saves(saved_flow)
	await verify_overlay_order()
	var file := FileAccess.open(OUT+"after_trace.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(trace,"\t")); file.close()
	file = FileAccess.open(OUT+mode+"_checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t")); file.close()
	print("STEP14: ",checks," checks, failures=",failures)
	game._shutdown_audio_for_exit(); game.campaign_autosave_pending = false
	game.queue_free(); await frames(3)
	get_tree().quit(0 if failures.is_empty() else 1)

func verify_saves(saved_flow: Dictionary) -> void:
	# Use existing read-only original test copies, never actual user data.
	for version in [1,5]:
		var source := "res://tmp/v130_m6/original_copies/campaign_save_v%d.json" % version
		expect(FileAccess.file_exists(source),"legacy source fixture v%d" % version)
		if not FileAccess.file_exists(source): continue
		var before_hash := FileAccess.get_sha256(source)
		var folder := "user://legacy_v%d_%d/" % [version,Time.get_ticks_msec()]
		DirAccess.make_dir_recursive_absolute(folder)
		var path := folder+"campaign_save_v%d.json" % version
		DirAccess.copy_absolute(source,path)
		game._set_campaign_save_path_for_tests(folder+"campaign_save_v1.json",folder+"campaign_save_v2.json",folder+"campaign_save_v3.json",folder+"campaign_save_v4.json",folder+"campaign_save_v5.json",folder+"campaign_save_v6.json")
		expect(game.campaign_save_status=="valid","legacy save inspect v%d: %s" % [version,game.campaign_save_error])
		game._continue_campaign_save(); await frames(12); await after_dialogues()
		expect(game.current_screen=="management","legacy continues without prologue/name v%d" % version)
		var view: Node = game.ui_layer.get_node_or_null("ApprovedMapManagement")
		expect(view!=null and int(view.placement.day)==GameState.day,"legacy day preserved v%d" % version)
		expect(not game.start_flow.fresh and game.start_flow.guide_step==5,"old saves do not receive new-run guide")
		expect(FileAccess.get_sha256(source)==before_hash,"original fixture unchanged v%d" % version)
	game.campaign_autosave_pending = false
	game._set_campaign_save_path_for_tests("user://new_run_save.json","user://new_v2.json","user://new_v3.json","user://new_v4.json","user://new_v5.json","user://new_v6.json")
	game.start_flow.restore(saved_flow)
	game._set_screen("management",false)
	game.start_flow.play_seconds = 3725
	game._schedule_campaign_autosave("management")
	expect(game._flush_campaign_autosave(),"new save writes extended onboarding")
	expect(FileAccess.file_exists("user://new_v6.json"),"current 1.3.0 v6 save written")
	game.start_flow.menu_open = true; game._set_screen("title",false); await frames(4)
	expect(not game.ui_layer.find_child("CampaignContinueButton",true,false).disabled,"save enables Continue")
	await capture("menu")
	await press("CampaignNewGameButton")
	expect(game.pending_title_reset_mode=="new" and game.ui_layer.find_child("TitleResetConfirmation",true,false)!=null,"existing save requires overwrite confirmation")
	await press("TitleResetCancelButton")
	expect(FileAccess.file_exists("user://new_run_save.json"),"cancel preserves save")
	await press("CampaignContinueButton")
	await frames(8)
	expect(game.start_flow.guide_step==4,"Continue restores actual guide progress")
	game._open_settings_screen(); game._select_settings_category("general"); await frames(5)
	await press("ReplayStartGuideButton")
	expect(game.start_flow.replaying and game.start_flow.guide_step==1,"settings schedules guide replay")
	game._cancel_settings_changes(); await frames(5)
	expect(not game.start_flow.replaying and game.start_flow.guide_step==4,"cancel reverts guide replay")
	game._open_settings_screen(); UISettings.set_preferred_combat_speed(2.0,false); game._select_settings_category("combat"); await frames(4)
	var speed_choice: OptionButton = game.ui_layer.find_child("DefaultCombatSpeedOption",true,false)
	expect(speed_choice!=null,"settings exposes default combat speed")
	expect(float(speed_choice.get_item_metadata(speed_choice.selected))==2.0,"settings displays selected default speed")
	game._cancel_settings_changes()
	game.start_flow.menu_open = true; game._set_screen("title",false)
	game._open_settings_screen(); game._select_settings_category("general"); await frames(4)
	await press("ReplayStartGuideButton")
	game._apply_settings_changes(); await frames(4)
	game._continue_campaign_save(); await frames(8)
	expect(game.start_flow.replaying and game.start_flow.guide_step==1,"title settings replay survives Continue")
	# A new run can skip the whole prologue in every language; questions never
	# expose substitution tokens, and all guide translations have the same keys.
	for locale in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		expect(game.start_flow.catalog[locale].prologue.size()==7,"seven prologue lines "+locale)
		expect(game.start_flow.catalog[locale].keys().size()==game.start_flow.catalog.ko.keys().size(),"translation key coverage "+locale)
		game.start_flow.start_prologue(); await frames(2)
		await press("PrologueSkip")
		expect(game.current_screen=="name_entry" and game.start_flow.naming_turn==0,"skip reaches Bati "+locale)
		expect(not str(game.start_flow.catalog[locale].name_talk).contains("{{player_name}}"),"no pre-name token "+locale)
	LanguageSettings.set_locale("ko",false)

func verify_overlay_order() -> void:
	game.campaign_autosave_pending = false; game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false; game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
	game._onboarding_reset_game(); game.start_flow.reset_run()
	game._onboarding_set_stage("LV03_DAY01_MANAGEMENT_TUTORIAL")
	GameState.player_name = "Fixture"
	game._set_screen("management",false); await frames(4)
	var view: Node = game.ui_layer.get_node("ApprovedMapManagement")
	for id in view.monster_ui.members:
		if view.monster_ui.members[id].species_id in ["spider_tailor","bat_courier"]:
			if id not in view.placement.food_state.owned: view.placement.food_state.owned.append(id)
	Grade.stash(game,view.placement,view.monster_ui.assignments)
	game.set_meta("v130r_owned_species",["slime","goblin","imp","spider_tailor","bat_courier"])
	var first := trace.size()
	game.start_flow.management_intro(); await frames(3)
	expect(game.story_director.current_scene_id=="STORY_D01_MANAGEMENT_ENTRY","eligible overlay still waits for original management entry")
	await after_dialogues(); await frames(5)
	var main_last := -1; var overlay_first := -1
	for i in range(first,trace.size()):
		if str(trace[i].story)=="STORY_D01_MANAGEMENT_ENTRY": main_last = i
		if str(trace[i].line.get("v130r_scene_id","")).begins_with("V130R_D01_MANAGEMENT") and overlay_first<0: overlay_first = i
	expect(main_last>=first and overlay_first>main_last,"0111 overlay follows all original management lines")
	expect(game.story_director.seen_scene_ids.has("V130R_D01_MANAGEMENT_S1") and game.story_director.seen_scene_ids.has("V130R_D01_MANAGEMENT_S2"),"eligible 0111 blocks both complete once")
	expect(game.start_flow.intro_complete and game.start_flow.guide_step==1,"guide begins only after eligible overlays")
	game.start_flow.guide_step = 5; game.start_flow.command_seen = true
	game.start_flow.restore(game.start_flow.snapshot()); await frames(3)
	expect(game.ui_layer.find_child("StartGuide",true,false)==null,"completed guide stays hidden after restoring state")
