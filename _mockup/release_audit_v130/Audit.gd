extends Node
const OUT := "res://_mockup/release_audit_v130/"
const Grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
var game: Node
var mode := "campaign"
var run_seed := 13001
var locale := "ko"
var rows: Array = []
var events: Array = []
var overflows: Array = []
var started := 0
var scenario_day := 22
var schema_version := 1

func _ready() -> void: run.call_deferred()

func frames(n: int = 4) -> void:
	for i in n: await get_tree().process_frame

func write_json(id: String, value) -> void:
	var f := FileAccess.open(OUT+id+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(value,"\t")); f.close()

func view() -> Node: return game.ui_layer.get_node_or_null("ApprovedMapManagement")

func event(tag: String, extra: Dictionary = {}) -> void:
	var row := {"tag":tag,"day":GameState.day,"screen":game.current_screen,"stage":game.onboarding_stage_id,"hp":GameState.demon_lord_hp,"gold":GameState.gold,"food":GameState.food,"max_day":GameState.max_day,"onboarding_complete":GameState.onboarding_complete,"story":game.story_director.current_scene_id}
	row.merge(extra); events.append(row)
	write_json(mode+"_"+str(run_seed)+"_events",events)
	print("AUDIT_EVENT ",JSON.stringify({"tag":tag,"day":GameState.day,"screen":game.current_screen,"hp":GameState.demon_lord_hp,"extra_keys":extra.keys()}))

func press(id: String) -> bool:
	var b := game.ui_layer.find_child(id,true,false) as BaseButton
	if b==null or b.disabled: event("missing_button",{"id":id}); return false
	b.pressed.emit(); await frames(); return true

func drain() -> void:
	for i in 500:
		await frames(2)
		if game.current_screen!="dialogue": return
		if game.story_director.is_active(): game._story_advance_dialogue()
		else: game._onboarding_advance_dialogue()
	event("dialogue_stuck")

func text_scan(node: Node, screen: String) -> void:
	if node is Control and node.is_visible_in_tree():
		if node is Label and not node.text.strip_edges().is_empty():
			var needed: Vector2 = node.get_minimum_size()
			var height: float = node.get_line_count()*node.get_theme_font("font").get_height(node.get_theme_font_size("font_size"))
			if (node.clip_text and needed.x>node.size.x+2) or height>node.size.y+3:
				overflows.append({"locale":locale,"screen":screen,"path":str(node.get_path()),"text":node.text,"size":str(node.size),"minimum":str(needed),"text_height":height})
	for child in node.get_children(): text_scan(child,screen)

func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames(); await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(1280,720,Image.INTERPOLATE_LANCZOS)
	img.save_png(OUT+"captures/"+locale+"_"+id+".png")
	text_scan(game.ui_layer,id)
	write_json("overflow_"+locale,overflows)

func create_game() -> void:
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	ProjectSettings.set_setting("debug/start_flow14",true)
	LanguageSettings.set_locale(locale,false)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	add_child(game); await frames(8)
	# GameRoot._ready randomizes; set the audit seed only after that boundary.
	seed(run_seed)
	event("boot",{"load_msec":Time.get_ticks_msec()-started,"user_dir":OS.get_user_data_dir()})

func new_game() -> void:
	if mode=="ux":
		for language in ["en","zh_CN","ko"]:
			await press("TitleLanguage_"+language)
			event("title_language",{"expected":language,"actual":LanguageSettings.locale})
	await capture("title")
	await press("TitleStartButton")
	await capture("menu")
	await press("CampaignNewGameButton")
	await capture("prologue")
	for i in 7: await press("PrologueNext")
	await press("NamingNext"); await press("NamingNext")
	await capture("name")
	game.onboarding_name_input.text = "Audit"+str(run_seed)
	game._onboarding_name_changed(game.onboarding_name_input.text)
	await press("ConfirmNameButton"); await drain(); await frames(8)
	event("new_management")
	if mode=="ux": event("tutorial_overlay_check",{"legacy_overlay_present":game.ui_layer.find_child("TutorialOverlay",true,false)!=null,"guide_step":game.start_flow.guide_step})
	await capture("guide")

func save_reload(day: int) -> void:
	game._schedule_campaign_autosave("management")
	var saved: bool = game._flush_campaign_autosave()
	event("save",{"ok":saved,"save_status":game.campaign_save_status,"save_error":game.campaign_save_error})
	game._shutdown_audio_for_exit(); game.campaign_autosave_pending = false
	game.queue_free(); await frames(5)
	await create_game()
	await press("TitleStartButton"); await press("CampaignContinueButton")
	await drain(); await frames(6)
	seed(run_seed+day*1000)
	event("reload",{"expected_day":day,"layout_day":view().placement.day if view()!=null else -1})

func battle_day() -> Dictionary:
	var v := view()
	if v==null: return {"error":"no management view"}
	if v.preparation_only():
		var ok: bool = v.confirm_preparation_day(); await drain(); await frames(6)
		return {"preparation_only":true,"advanced":ok}
	v.monster_ui.set_mode("place"); v.monster_ui.auto_place(); await frames(6)
	if game.start_flow.guide_step==1: game.start_flow.advance_guide(); await frames(6)
	for i in 8:
		v=view()
		if v==null: return {"error":"view lost before combat"}
		if v.battle!=null: break
		v.start_battle(); await drain(); await frames(6)
	v=view()
	if v==null or v.battle==null: return {"error":"battle did not start","guide":game.start_flow.guide_step}
	if not game.start_flow.command_seen: game.start_flow.ack_commands()
	v.battle.set_speed(3.0)
	if mode=="capture":
		await frames(10); await capture("battle")
	var b = v.battle
	v.set_physics_process(false)
	var steps := 0
	var wall_started := Time.get_ticks_msec()
	event("combat_started",{"grade":v.placement.grade,"deployed":v.monster_ui.assignments.size()})
	while b.running and game.combat_time<600:
		if game.story_combat_overlay_open and game.story_director.is_active():
			game._story_advance_dialogue(); await frames(2); continue
		b.physics_process(1.0/60.0)
		for unit in game.monster_units+game.enemy_units:
			if is_instance_valid(unit): unit.set_physics_process(false); unit._physics_process(1.0/60.0)
		steps += 1
		if steps%120==0: await frames(1)
		if steps%1200==0: event("combat_progress",{"combat_time":game.combat_time,"wall_msec":Time.get_ticks_msec()-wall_started,"enemies":game.enemy_units.size()})
	var result: Dictionary = b.last_result.duplicate(true)
	result.merge({"steps":steps,"grade":str(v.placement.grade),"assignments":v.monster_ui.assignments.duplicate(true),"owned":v.monster_ui.unlocked().duplicate(),"level_rows":game.monster_roster.duplicate(true)})
	await frames(8); await drain(); await frames(5)
	result.merge({"day":GameState.day,"screen":game.current_screen,"hp":GameState.demon_lord_hp,"max_hp":GameState.demon_lord_max_hp,"food":GameState.food,"gold":GameState.gold,"settlement":game.result_summary.duplicate(true)})
	return result

func campaign() -> void:
	await new_game()
	for day in range(1,32):
		await drain(); await frames(6)
		if game.current_screen!="management": event("blocked_management"); break
		if GameState.day!=day: event("day_mismatch",{"expected":day}); break
		event("day_enter",{"grade":view().placement.grade})
		if day in [2,15,20,27]: await save_reload(day)
		var result := await battle_day(); rows.append(result)
		write_json(mode+"_"+str(run_seed)+"_days",rows)
		event("day_result",{"result":result})
		if result.has("error"): break
		if mode in ["capture","ux"]: break
		if result.get("preparation_only",false): continue
		if not result.get("win",false):
			game._edit_placement_from_result(); await drain(); await frames(6)
			event("defeat_retry_management",{"layout_day":view().placement.day if view()!=null else -1})
			if view()==null: break
			var retry := await battle_day(); rows.append({"retry":retry})
			write_json(mode+"_"+str(run_seed)+"_days",rows)
			event("retry_result",{"result":retry})
			if not retry.get("win",false): break
		if day>=30:
			game._continue_from_result(); await drain(); await frames(6)
			event("ending_check",{"completed":game.campaign_completed,"ending":game.resolved_campaign_ending_id})
			break
		if game._result_growth_choice_required():
			event("growth_before")
			for growth in game.last_growth_summary:
				if game._choose_result_growth(str(growth.get("monster_id",""))): break
			game._review_growth_from_result(); await frames(4)
			event("growth_after")
		game._continue_from_result(); await drain(); await frames(6)
		await auxiliary()
		if GameState.day==day:
			event("blocked_result_continue",{"growth_required":game._result_growth_choice_required(),"growth_reviewed":game.result_growth_reviewed,"growth_applied":game.result_growth_choice_applied,"buttons":button_rows(game.ui_layer)})
			break

func auxiliary() -> void:
	for i in 12:
		await drain(); await frames(5)
		if game.current_screen=="management" or game.current_screen=="ending": return
		event("auxiliary_screen",{"buttons":button_rows(game.ui_layer)})
		if game.current_screen=="raid_preview":
			await press("StartRaidButton")
		elif game.current_screen=="raid":
			if game.last_raid_result.is_empty():
				if not game._can_start_selected_raid():
					for id in game.monster_roster:
						if id!=game._raid_fixed_captain_id(DataRegistry.raid_mission(game.raid_selected_mission_id)):
							game._toggle_raid_monster(str(id)); await frames(3)
							if game._can_start_selected_raid(): break
				await press("RaidStartButton"); await drain()
			else: await press("RaidBackButton")
		else: return

func button_rows(node: Node) -> Array:
	var result: Array = []
	if node is BaseButton and node.is_visible_in_tree(): result.append({"name":node.name,"text":node.text if node is Button else "","disabled":node.disabled,"tooltip":node.tooltip_text})
	for child in node.get_children(): result.append_array(button_rows(child))
	return result

func perf() -> void:
	await new_game()
	get_window().mode=Window.MODE_FULLSCREEN
	await frames(12)
	game.story_feature_enabled=false
	game.campaign_autosave_pending=false
	game.campaign_save_enabled=false; game.campaign_auxiliary_save_enabled=false
	game.campaign_save_v5_enabled=false; game.campaign_save_v6_enabled=false
	game.start_flow.fresh=false; game.start_flow.guide_step=5; game.start_flow.command_seen=true
	var v := view()
	var layout_start := Time.get_ticks_msec()
	var fixture = load("res://tools/tests/V130RStep10DCTest.gd").new()
	fixture.game=game
	v.placement=fixture.purchased_plan("C" if scenario_day>=27 else "D") if scenario_day>=20 else fixture.Buildings.initial(game,"E")
	fixture.free()
	v.placement.day=scenario_day; GameState.day=scenario_day
	v.state=v.Layout.read(str(v.placement.grade)); v.render_map(); v.update_wallet()
	v.monster_ui.unlock_all=true
	v.monster_ui.members=v.Monsters.roster()
	v.monster_ui.food_income=GameState.Food.income(scenario_day)
	v.monster_ui.auto_place()
	GameState.demon_lord_max_hp=100000; GameState.demon_lord_hp=100000
	var layout_ms := Time.get_ticks_msec()-layout_start
	v.start_battle(); await drain(); await frames(6)
	v=view()
	if v==null or v.battle==null: event("perf_failed_start"); return
	game.start_flow.ack_commands(); v.battle.set_speed(3.0)
	var samples: Array = []; var unit_counts: Array = []; var max_monsters := 0; var max_enemies := 0
	var clock := Time.get_ticks_usec()
	var sample_start := Time.get_ticks_msec()
	while v.battle.running and Time.get_ticks_msec()-sample_start<45000:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var elapsed: float = (now-clock)/1000.0; clock=now
		var monsters := 0; var enemies := 0
		for u in game.monster_units:
			if is_instance_valid(u) and u.is_alive(): monsters+=1
		for u in game.enemy_units:
			if is_instance_valid(u) and u.is_alive(): enemies+=1
		max_monsters=maxi(max_monsters,monsters); max_enemies=maxi(max_enemies,enemies)
		if Time.get_ticks_msec()-sample_start>3000: samples.append(elapsed); unit_counts.append({"monsters":monsters,"enemies":enemies})
		if Time.get_ticks_msec()-sample_start>10000 and not FileAccess.file_exists(OUT+"captures/ko_perf_"+str(scenario_day)+".png"): await capture("perf_"+str(scenario_day))
	write_json("perf_"+str(scenario_day)+"_"+str(get_window().size.x)+"x"+str(get_window().size.y),{"day":scenario_day,"grade":str(v.placement.grade),"viewport":str(get_viewport().get_visible_rect().size),"samples_ms":samples,"unit_counts":unit_counts,"max_monsters":max_monsters,"max_enemies":max_enemies,"layout_msec":layout_ms,"static_memory_bytes":OS.get_static_memory_usage(),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"duration_msec":Time.get_ticks_msec()-sample_start,"speed":game.combat_speed,"actual_size":str(get_window().size)})
	game.start_flow.abandon_battle(v)

func compatibility() -> void:
	game.campaign_autosave_pending=false
	for version in [schema_version]:
		var source := "res://tmp/v130_m6/original_copies/campaign_save_v%d.json" % version
		var folder := "user://compat%d/" % version
		DirAccess.make_dir_recursive_absolute(folder)
		DirAccess.copy_absolute(source,folder+"campaign_save_v%d.json" % version)
		game._set_campaign_save_path_for_tests(folder+"campaign_save_v1.json",folder+"campaign_save_v2.json",folder+"campaign_save_v3.json",folder+"campaign_save_v4.json",folder+"campaign_save_v5.json",folder+"campaign_save_v6.json")
		event("compat_inspect",{"schema":version,"status":game.campaign_save_status,"error":game.campaign_save_error})
		if game.campaign_save_status!="valid": continue
		game._continue_campaign_save(); await drain(); await frames(8)
		var v := view()
		var raw = JSON.parse_string(FileAccess.get_file_as_string(source))
		event("compat_loaded",{"schema":version,"raw_keys":raw.keys(),"roster":game.monster_roster.duplicate(true),"has_map":v!=null,"layout_day":v.placement.day if v!=null else -1,"layout_grade":v.placement.grade if v!=null else "","save_status":game.campaign_save_status})
		if v!=null:
			var result := await battle_day()
			event("compat_battle",{"schema":version,"result":result})
		game.campaign_autosave_pending=false

func localization() -> void:
	var result := {}
	var hangul := RegEx.new(); hangul.compile("[가-힣]")
	var catalogs := {"monsters":DataRegistry.monsters,"hpbar_names":DataRegistry.monster_instances,"enemies":DataRegistry.enemies,"skills":DataRegistry.skills,"specializations":DataRegistry.specializations}
	for language in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(language,false)
		var counts := {}
		for category in catalogs:
			var tested := 0; var missing: Array = []
			for id in catalogs[category]:
				var row: Dictionary = catalogs[category][id]
				for key in ["display_name","description","short_effect"]:
					if not row.has(key) or not row[key] is String: continue
					var source: String=row[key]
					if source.is_empty(): continue
					tested+=1
					var translated: String=LanguageSettings.ui_text(source)
					if language!="ko" and hangul.search(translated)!=null: missing.append({"id":id,"field":key,"source":source,"translated":translated})
			counts[category]={"tested":tested,"untranslated_count":missing.size(),"untranslated":missing}
		result[language]=counts
	write_json("localization_runtime",result)

func boundaries() -> void:
	await new_game()
	game.story_feature_enabled=false
	game.campaign_autosave_pending=false; game.campaign_save_enabled=false
	game.campaign_auxiliary_save_enabled=false; game.campaign_save_v5_enabled=false; game.campaign_save_v6_enabled=false
	game.start_flow.fresh=false; game.start_flow.guide_step=5; game.start_flow.command_seen=true
	var v := view()
	var source: Dictionary=v.placement
	for day in [14,15,19,20,26,27]:
		var transitioned := Grade.advance(game,source,{},day)
		event("grade_boundary_fixture",{"target_day":day,"ok":transitioned.get("ok",false),"grade":transitioned.get("layout",{}).get("grade",""),"errors":transitioned.get("errors",[])})
		if transitioned.get("ok",false): source=transitioned.layout
	v.set_preview_day(29); v.monster_ui.unlock_all=true; v.monster_ui.auto_place()
	var can_prepare: bool=v.preparation_only()
	event("day29_before",{"base_wave_size":DataRegistry.waves.get("day_29",[]).size(),"active_wave_size":game._active_wave_catalog(29).get("day_29",[]).size(),"preparation_only":can_prepare,"layout_day":v.placement.day,"wave_layout_id":game.quarter_layout_id})
	var began: bool=v.start_battle()
	event("day29_start",{"returned":began,"battle_exists":v.battle!=null,"spawned":game.spawned_count})
	if v.battle!=null: game.start_flow.abandon_battle(v)
	else:
		var advanced: bool=v.confirm_preparation_day(); await frames(6)
		event("day29_confirm",{"returned":advanced,"layout_day":view().placement.day if view()!=null else -1})

func run() -> void:
	started=Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT+"captures")
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): mode=args[0]
	for arg in args:
		if arg.begins_with("seed="): run_seed=int(arg.get_slice("=",1))
		if arg.begins_with("locale="): locale=arg.get_slice("=",1)
		if arg.begins_with("day="): scenario_day=int(arg.get_slice("=",1))
		if arg.begins_with("schema="): schema_version=int(arg.get_slice("=",1))
	seed(run_seed)
	await create_game()
	if mode=="perf": await perf()
	elif mode=="compatibility": await compatibility()
	elif mode=="localization": await localization()
	elif mode=="boundaries": await boundaries()
	else: await campaign()
	write_json(mode+"_"+str(run_seed)+"_summary",{"days":rows.size(),"events":events,"elapsed_msec":Time.get_ticks_msec()-started})
	game._shutdown_audio_for_exit(); game.campaign_autosave_pending=false
	game.queue_free(); await frames(5)
	get_tree().quit()
