extends SceneTree

var game
var out := ""
var mode := "fresh"
var checks := 0
var failures: Array[String] = []
var evidence := {}

func _initialize() -> void: call_deferred("run")
func expect(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label); printerr("BOUNDARY_FAIL: "+label)
func settle(frames: int = 8) -> void:
	for i in range(frames): await process_frame
func click(name: String) -> bool:
	var button = game.find_child(name,true,false)
	if not button is BaseButton or not button.is_visible_in_tree() or button.disabled: return false
	var point: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = point; root.push_input(motion,true)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new(); event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event,true); await process_frame
	await settle(); return true
func read_dialogue() -> void:
	for i in range(150):
		if not game.story_director.is_active() and game.onboarding_dialogue_queue.is_empty(): return
		if game.story_director.is_active():
			if not game.story_director.current_cue().get("choices",[]).is_empty(): return
			game._story_advance_dialogue(true)
		else: game._onboarding_advance_dialogue()
		await settle()
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0]; mode = args[1]
	if args.size()>2: expect(ProjectSettings.load_resource_pack(args[2],true),"load delta pack before game script")
	expect(ProjectSettings.globalize_path("user://").contains("first-victory-save-p1"),"isolated profile before any game/save operation")
	if not failures.is_empty(): finish(); return
	DirAccess.make_dir_recursive_absolute(out)
	game = load("res://scenes/game/GameRoot.tscn").instantiate(); root.add_child(game); await settle()
	expect(game.combat_scene!=null,"game controllers initialized")
	if game.combat_scene==null: finish(); return
	if mode=="fresh": await fresh()
	elif mode=="restart": await restart_load()
	else: await legacy_boundaries()
	finish()
func inspect_save() -> Dictionary:
	var store = load("res://scripts/systems/save/CampaignSaveV5Store.gd")
	return store.inspect(game.campaign_save_v5_path,root.get_node("DataRegistry").monster_instances,root.get_node("DataRegistry").run_metric_definitions,game._update3_save_catalogs(),root.get_node("DataRegistry").update4_catalogs)
func snapshot() -> Dictionary:
	return {"day":root.get_node("GameState").day,"resources":root.get_node("GameState").campaign_snapshot(),"roster":game.monster_roster.duplicate(true),"result":game.result_summary.duplicate(true),"mode":game.update4_active_run.get("campaign_mode_id"),"update4_metrics":game.update4_active_run.get("run_metrics_update4",{}).duplicate(true)}
func fresh() -> void:
	expect(game.campaign_save_status=="missing","fresh profile no existing save")
	await click("UpdateNotesConfirm")
	expect(await click("CampaignNewGameButton"),"normal New Game control")
	expect(game.current_screen=="name_entry","normal name entry")
	game.onboarding_name_input.text="저장경계검증"; game.onboarding_name_input.text_changed.emit("저장경계검증")
	game._onboarding_confirm_name(); await settle(); await read_dialogue()
	expect(await click("EnterPlacementButton"),"normal placement prompt")
	expect(await click("MonsterCard_goblin"),"normal Goblin placement selection")
	var point: Vector2 = game.get_canvas_transform()*game.graph.center("barracks")
	for pressed in [true,false]:
		var event := InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=pressed; root.push_input(event,true); await process_frame
	await settle(); await read_dialogue()
	expect(await click("StartCombatButton"),"normal first defense start")
	await read_dialogue()
	var deadline := Time.get_ticks_msec()+120000
	while game.result_summary.get("lines",[]).is_empty() and Time.get_ticks_msec()<deadline:
		if game.story_director.is_active(): game._story_advance_dialogue(true)
		await create_timer(.1).timeout
	await read_dialogue(); await settle(60)
	expect(bool(game.result_summary.get("win",false)),"actual normal battle victory, no forced finish")
	expect(game.current_screen=="result","normal result checkpoint")
	expect(game.campaign_save_error=="" and game.campaign_save_notice=="","no result autosave error or restored-old-checkpoint toast")
	var saved := inspect_save()
	expect(saved.get("status")=="valid","actual v5 disk inspect valid after victory")
	expect(game.update4_active_run.get("run_metrics_update4",{}).is_empty(),"non-council first victory has no council run metrics")
	expect(saved.get("envelope",{}).get("active_run",{}).get("campaign_mode_id")=="front_chronicle_legacy_v4","first campaign compatibility mode retained")
	evidence=snapshot(); evidence["combat_seconds"]=game.combat_time
	var file := FileAccess.open(out.path_join("expected-restart.json"),FileAccess.WRITE); file.store_string(JSON.stringify(snapshot())); file.close()
	await capture("first-victory-valid-save")
func restart_load() -> void:
	expect(game.campaign_save_status=="valid","new engine process discovers existing v5 save")
	await click("UpdateNotesConfirm")
	game._continue_campaign_save(); await settle(60)
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("expected-restart.json")))
	expect(game.current_screen=="result","continue restores first result checkpoint")
	# JSON deserializes numeric Variants as floats. Compare both sides in the
	# same persisted representation without omitting any state or reward field.
	expect(JSON.parse_string(JSON.stringify(snapshot()))==expected,"restart restores day/resources/roster/result/mode without reward replay")
	expect(game.campaign_save_error=="" and game.campaign_save_notice=="","restart does not invalidate saved progress")
	evidence=snapshot(); await capture("restart-loaded-first-result")
func legacy_boundaries() -> void:
	var registry = root.get_node("DataRegistry")
	var migrator = load("res://scripts/systems/save/SaveV4ToV5Migrator.gd")
	var modes = load("res://scripts/systems/campaign/CampaignModeService.gd")
	# A real v4 envelope emitted by the normal fresh-victory writer is copied
	# only inside this synthetic review profile; no personal record is used.
	var v4: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[3]))
	var migrated: Dictionary = migrator.migrate_envelope(v4,registry.monster_instances,registry.run_metric_definitions,game._update3_save_catalogs(),registry.update4_catalogs)
	expect(bool(migrated.get("ok",false)),"existing v4 migrates with legacy guard unchanged")
	var envelope: Dictionary=migrated.get("envelope",{})
	expect(envelope.active_run.campaign_mode_id==modes.LEGACY_MODE_ID and envelope.active_run.run_metrics_update4.is_empty(),"actual v4 stays legacy and council-empty")
	var invalid: Dictionary=envelope.duplicate(true); invalid.active_run.run_metrics_update4={"native_1f_objectives":{"adapter":"actual_1F","metrics":{},"losses":[]}}
	expect(str(migrator.validate_v5(invalid,registry.monster_instances,registry.run_metric_definitions,game._update3_save_catalogs(),registry.update4_catalogs)).contains("레거시"),"legacy rejects inserted council metrics")
	var store = load("res://scripts/systems/save/CampaignSaveV5Store.gd")
	var path := "user://synthetic_legacy_guard_v5.json"
	expect(bool(store.write(envelope,path,registry.monster_instances,registry.run_metric_definitions,game._update3_save_catalogs(),registry.update4_catalogs).get("ok",false)),"valid migrated legacy writes normally")
	var before := FileAccess.get_file_as_string(path)
	expect(not bool(store.write(invalid,path,registry.monster_instances,registry.run_metric_definitions,game._update3_save_catalogs(),registry.update4_catalogs).get("ok",false)) and FileAccess.get_file_as_string(path)==before,"rejected council injection preserves exact existing legacy bytes")
	game.update4_active_run=modes.default_active_run()
	game.combat_scene.native_objectives.before_result()
	expect(game.update4_active_run.run_metrics_update4.is_empty(),"legacy result adapter does not insert council state")
	game.update4_active_run.campaign_mode_id=modes.COUNCIL_MODE_ID
	game.combat_scene.native_objectives.before_result()
	expect(game.update4_active_run.run_metrics_update4.has("native_1f_objectives"),"council result still records its objectives")
	game.update4_profile.campaign_modes.council_season_unlocked=true
	game.campaign_save_v5_envelope=envelope.duplicate(true)
	game._onboarding_reset_game()
	expect(game.update4_active_run==modes.default_active_run() and not game.update4_profile.campaign_modes.council_season_unlocked and game.campaign_save_v5_envelope.is_empty(),"new game clears prior council context and cached envelope")
	game.update4_profile.campaign_modes.council_season_unlocked=true
	game.update4_profile.crown_evolution={"species_mastery":{"bat_courier":2}}
	var profile: Dictionary=game.update4_profile.duplicate(true)
	game._onboarding_reset_game(true)
	expect(game.update4_profile==profile,"existing next-cycle preservation keeps earned Update4 profile")
	evidence={"legacy_guard_unchanged":true,"new_game_reset":true,"next_cycle_profile_retained":true}
func finish() -> void:
	if out!="":
		var file := FileAccess.open(out.path_join(mode+"-results.json"),FileAccess.WRITE)
		if file!=null:file.store_string(JSON.stringify({"mode":mode,"checks":checks,"failures":failures,"evidence":evidence},"\t"))
	print("FIRST_VICTORY_SAVE_BOUNDARY "+mode+": "+("PASS" if failures.is_empty() else "FAIL")+" (%d/%d)"%[checks-failures.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
