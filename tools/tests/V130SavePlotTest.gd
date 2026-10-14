extends Node

const Game = preload("res://scenes/game/GameRoot.tscn")
const State = preload("res://scripts/map_builder/PlotSaveState.gd")
const Migration = preload("res://scripts/systems/save/SaveV5ToV6Migrator.gd")
const Store = preload("res://scripts/systems/save/CampaignSaveV6Store.gd")
const Iso = preload("res://scripts/dungeon_quarter/IsoMath.gd")
const OUT := "res://tmp/v130_m6/"
var game: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []

func _ready() -> void: call_deferred("run")
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL: ",label)
func settle(count: int = 6) -> void:
	for i in range(count): await get_tree().process_frame
func write_json(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"\t")); f.close()
func capture(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	await settle()
	await RenderingServer.frame_post_draw
	var path := OUT+name+".png"
	get_viewport().get_texture().get_image().save_png(path)
	captures.append(path)
func spawn() -> void:
	game = Game.instantiate()
	game.campaign_save_enabled = false
	add_child(game)
	await settle()
	game.onboarding_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
	game.story_feature_enabled = false; game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
func release() -> void:
	game.campaign_autosave_pending = false
	game._shutdown_audio_for_exit()
	remove_child(game); game.queue_free(); await settle(2)
func use_paths(folder: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	game._set_campaign_save_path_for_tests(folder+"campaign_save_v1.json",folder+"campaign_save_v2.json",folder+"campaign_save_v3.json",folder+"campaign_save_v4.json",folder+"campaign_save_v5.json",folder+"campaign_save_v6.json")
func check_graph(label: String) -> void:
	expect(game.graph.validation_summary().ok,label+" graph")
	expect(not game.graph.path_between("outside_approach","throne").is_empty(),label+" Continue entrance-throne")
	for id in game.graph.module_instance_ids():
		if game.graph.module_data_for_instance(id).get("module_type","") == "room": expect(not game.graph.path_between("entrance",id).is_empty(),label+" all rooms reachable "+id)
func run() -> void:
	get_window().size = Vector2i(1920,1080)
	for version in range(1,6):
		await spawn()
		var folder := OUT+"copy_v%d/" % version
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
		for i in range(1,7):
			for suffix in ["",".tmp",".bak",".corrupt",".plot_original"]:
				var previous: String = folder+"campaign_save_v%d.json" % i+suffix
				if FileAccess.file_exists(previous): DirAccess.remove_absolute(ProjectSettings.globalize_path(previous))
		var path := folder+"campaign_save_v%d.json" % version
		expect(DirAccess.copy_absolute(ProjectSettings.globalize_path(OUT+"original_copies/campaign_save_v%d.json" % version),ProjectSettings.globalize_path(path)) == OK,"copy legacy v%d" % version)
		var hash_before := FileAccess.get_sha256(path)
		use_paths(folder)
		expect(game.campaign_save_status == "valid","v%d auto migration: %s" % [version,game.campaign_save_error])
		game._continue_campaign_save(); await settle()
		expect(game.current_screen == "management" and GameState.day == 2,"v%d Continue preserved day and checkpoint" % version)
		check_graph("legacy v%d" % version)
		expect(FileAccess.get_sha256(path) == hash_before,"v%d legacy source byte preserved" % version)
		var inspection := Store.inspect(folder+"campaign_save_v6.json",DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)
		expect(inspection.status == "valid","v6 written valid")
		expect(State.size_matches(inspection.get("envelope",{}).get("active_run",{}).get("plot_state",{}).get("size"),0),"starting plot 30x20")
		if version == 5:
			await capture("continue_v5")
			await expansion_roundtrip(folder)
			await invalid_plot_fallback(folder)
			await remaining_grades(folder)
			migration_failure_fixtures()
		await release()
	write_json(OUT+"result.json",{"checks":checks,"failures":failures,"captures":captures})
	print("V130SavePlotTest %s checks=%d failures=%s" % ["PASS" if failures.is_empty() else "FAIL",checks,failures])
	get_tree().quit(0 if failures.is_empty() else 1)

func expansion_roundtrip(folder: String) -> void:
	# Actual existing stage gate, no new grade threshold and no modified balance values.
	var old: Dictionary = game._plot_save_state()
	var throne := Iso.array_to_cell(game.graph.placed_module_data("throne").grid_origin)
	game.runtime_plot_layout = old.layout_source.duplicate(true)
	GameState.day = 15
	GameState.onboarding_complete = true
	game.onboarding_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
	game._onboarding_set_stage("CAMPAIGN_DAY_15")
	game.first_promotion_completed = true
	expect(not game._apply_castle_evolution_for_day(15),"locked stage does not give free land")
	game.campaign_stage_two_unlock_ready = true
	expect(game._apply_castle_evolution_for_day(15),"actual stage gate grants land")
	expect(game.graph.layout.plot_grid.size == [36,20],"grade width +6 height unchanged")
	expect(Iso.array_to_cell(game.graph.placed_module_data("throne").grid_origin) == throne+Vector2i(6,6),"persisted building translated, not reset")
	expect(game.plot_unlock_history.size() == 2 and game.plot_unlock_history[1].day == 15,"unlock history records gate day")
	expect(game._management_feedback_line().contains("가로 +6칸"),"Korean expansion notice in management")
	check_graph("expanded")
	var state: Dictionary = game._plot_save_state()
	var expansion_cell := Vector2i(-1,-1)
	for cell in game.graph.layout.plot_mask:
		if State.region_for_cell(state,cell) == 1: expansion_cell = cell; break
	expect(expansion_cell != Vector2i(-1,-1),"unlocked region distinct from initial land")
	expect(State.region_for_cell(state,throne+Vector2i(6,6)) == 0,"old building remains initial region")
	game.management_tool_tab = "build"
	game._set_screen("management",false)
	await capture("grade_expansion")
	game.selected_room = "throne"
	game.build_placement.plot.begin_move()
	var candidate := Vector2i(-1,-1)
	for cell in game.graph.layout.plot_mask:
		if State.region_for_cell(state,cell+Vector2i(2,2)) != 1: continue
		var assessed: Dictionary = game.build_placement.plot.assess("throne",cell,1)
		if assessed.ok:
			candidate = cell; game.build_placement.plot.preview = assessed; break
	expect(candidate != Vector2i(-1,-1),"valid placement in newly unlocked land")
	if candidate != Vector2i(-1,-1): expect(game.build_placement.plot.commit(),"place after expanding")
	await settle()
	await capture("expanded_placement")
	var before: Dictionary = game._plot_save_state()
	var resources := [GameState.gold,GameState.mana,GameState.food,GameState.infamy]
	game._schedule_campaign_autosave("management"); expect(game._flush_campaign_autosave(),"save expanded placement: "+game.campaign_save_error)
	var file := folder+"campaign_save_v6.json"
	var saved = JSON.parse_string(FileAccess.get_file_as_string(file))
	expect(saved.active_run.plot_state == JSON.parse_string(JSON.stringify(before)),"v6 has exact coordinates and history")
	var saved_rotation := -1
	for row in saved.active_run.plot_state.layout_source.placed_modules:
		if row.instance_id == "throne": saved_rotation = int(row.get("plot_rotation",0))
	expect(saved_rotation == 1,"v6 persists the rotated free placement")
	game.runtime_plot_layout.clear(); game.plot_unlock_history.clear()
	game._set_screen("title",false)
	game._continue_campaign_save(); await settle()
	expect(game.current_screen == "management","Continue expanded checkpoint")
	expect(JSON.parse_string(JSON.stringify(game._plot_save_state())) == JSON.parse_string(JSON.stringify(before)),"expanded placement and history roundtrip")
	expect([GameState.gold,GameState.mana,GameState.food,GameState.infamy] == resources,"resources roundtrip")
	check_graph("reload")
	await capture("reloaded_v6")
	# Title settings write only the v6 profile, keeping the active run intact.
	game._set_screen("title",false); game._open_settings_screen()
	var accessibility: Dictionary = game.settings_open_snapshot.accessibility.duplicate(true)
	accessibility["high_contrast_icons"] = not bool(accessibility.get("high_contrast_icons",false))
	expect(game._set_update4_accessibility(accessibility),"title accessibility writes primary v6")
	var edited = JSON.parse_string(FileAccess.get_file_as_string(file))
	expect(edited.active_run == saved.active_run,"profile-only settings preserve active plot run")
	write_json(file,saved)
	game._continue_campaign_save(); await settle()
	# Future format is never silently replaced with an old checkpoint.
	var future: Dictionary = saved.duplicate(true); future.version = 7; write_json(file,future)
	var hash := FileAccess.get_sha256(file)
	expect(game._refresh_campaign_save_status().status == "unsupported","future v6 file rejected")
	expect(FileAccess.get_sha256(file) == hash,"future save preserved")
	write_json(file,saved)
	# A process interrupted after moving the primary file still recovers v6.
	expect(DirAccess.rename_absolute(ProjectSettings.globalize_path(file),ProjectSettings.globalize_path(file+".bak")) == OK,"stage interrupted v6 write")
	expect(game._refresh_campaign_save_status().status == "valid","recover interrupted v6 primary")
	expect(JSON.parse_string(FileAccess.get_file_as_string(file)) == saved,"interrupted write retains exact checkpoint")
	# Failed atomic write retains the last valid primary save.
	var invalid: Dictionary = saved.duplicate(true); invalid.active_run.plot_state.size = [1,1]
	expect(not Store.write(invalid,file,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs).ok,"invalid schema write refused")
	expect(JSON.parse_string(FileAccess.get_file_as_string(file)) == saved,"failed write preserves checkpoint")

func invalid_plot_fallback(folder: String) -> void:
	var file := folder+"campaign_save_v6.json"
	var saved = JSON.parse_string(FileAccess.get_file_as_string(file))
	var damaged: Dictionary = saved.duplicate(true)
	for row in damaged.active_run.plot_state.layout_source.placed_modules:
		if row.instance_id == "throne": row.grid_origin = [-999,-999]
	write_json(file,damaged)
	var hash := FileAccess.get_sha256(file)
	game._continue_campaign_save(); await settle()
	expect(game.current_screen == "management" and game.campaign_save_status == "valid","invalid plot safe fallback Continue")
	expect(FileAccess.get_sha256(file+".plot_original") == hash,"failed conversion original preserved")
	check_graph("safe fallback")
	var repaired = JSON.parse_string(FileAccess.get_file_as_string(file))
	expect(bool(repaired.get("plot_migration_fallback",false)),"fallback recorded")
	expect(repaired.profile == saved.profile,"fallback profile and unlock rewards preserved")
	expect(repaired.active_run.plot_state.unlock_history == saved.active_run.plot_state.unlock_history,"coordinate fallback preserves valid unlock dates and regions")
	var second: Dictionary = repaired.duplicate(true)
	for row in second.active_run.plot_state.layout_source.placed_modules:
		if row.instance_id == "throne": row.grid_origin = [-888,-888]
	write_json(file,second)
	var second_hash := FileAccess.get_sha256(file)
	game._continue_campaign_save(); await settle()
	expect(game.campaign_save_status == "valid","repeated invalid plot still recovers")
	expect(FileAccess.get_sha256(file+".plot_original."+second_hash) == second_hash,"each distinct failed source is archived")
	expect(FileAccess.get_sha256(file+".plot_original") == hash,"second failure preserves the first original too")

func remaining_grades(folder: String) -> void:
	game.onboarding_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
	for i in range(2,4):
		LanguageSettings.set_locale("en" if i == 2 else "zh_CN",false)
		GameState.day = 20 if i == 2 else 27
		game.campaign_chapter_three_clear = true
		game.campaign_final_upgrade_ready = true
		expect(game._apply_castle_evolution_for_day(GameState.day),"grade %d actual unlock" % i)
		expect(State.size_matches(game.graph.layout.plot_grid.size,i),"grade %d width +6" % i)
		check_graph("grade %d" % i)
		expect(game.plot_unlock_history.size() == i+1,"all grades keep history")
		var text := "width +6 cells" if i == 2 else "宽度增加6格"
		expect(game.logs.slice(-2).any(func(line): return str(line).contains(text)),"localized expansion notice "+LanguageSettings.locale)
		expect(game._management_feedback_line().contains(text),"localized expansion notice visible in management")
		game._set_screen("management",false)
		game._schedule_campaign_autosave("management")
		expect(game._flush_campaign_autosave(),"save grade %d: %s" % [i,game.campaign_save_error])
		var before: Dictionary = game._plot_save_state()
		game.runtime_plot_layout.clear(); game.plot_unlock_history.clear()
		game._continue_campaign_save(); await settle()
		expect(JSON.parse_string(JSON.stringify(game._plot_save_state())) == JSON.parse_string(JSON.stringify(before)),"grade %d roundtrip" % i)
	# A failed v6 write must roll the previously written legacy files back too.
	var paths: Array = [game.campaign_save_v2_path,game.campaign_save_v3_path,game.campaign_save_v4_path,game.campaign_save_v5_path,game.campaign_save_v6_path]
	var hashes: Array = []
	for path in paths: hashes.append(FileAccess.get_sha256(path))
	var existing: String = game.campaign_save_v6_path
	game.campaign_save_v6_path = folder+"absent_directory/no_write.json"
	expect(not game._write_campaign_v2_snapshot(),"failed v6 write propagates failure")
	game.campaign_save_v6_path = existing
	for i in range(paths.size()): expect(FileAccess.get_sha256(paths[i]) == hashes[i],"bundle rollback preserves v%d" % (i+2))
	expect(game._delete_campaign_save(),"delete uses configured copy paths")
	expect(not FileAccess.file_exists(game.campaign_save_v6_path),"new game cannot revive the old v6 primary")
	LanguageSettings.set_locale("ko",false)

func migration_failure_fixtures() -> void:
	var input: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT+"original_copies/campaign_save_v5.json"))
	var world: Dictionary = input.active_run.legacy_payload.world
	world.quarter_layout["plot_grid"] = {"size":[30,20],"grade_index":0}
	for row in world.quarter_layout.placed_modules:
		if row.instance_id == "throne": row.grid_origin = [-99,-99]
	var original := JSON.stringify(input)
	var migrated := Migration.migrate_envelope(input,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)
	expect(bool(migrated.get("ok",false)) and bool(migrated.get("fallback",false)),"v5 invalid coordinates use safe default")
	expect(JSON.stringify(input) == original,"v5 migration failure leaves source object unchanged")
	world.quarter_layout.placed_modules = world.quarter_layout.placed_modules.filter(func(row): return row.instance_id != "throne")
	migrated = Migration.migrate_envelope(input,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)
	expect(bool(migrated.get("ok",false)) and bool(migrated.get("fallback",false)),"missing anchor uses canonical safe default")
	if bool(migrated.get("ok",false)): expect(State.validate(migrated.envelope.active_run.plot_state) == "","safe default has no overlap and width-two roads")
	var folder := OUT+"missing_anchor/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for i in range(1,7): Store.delete(folder+"campaign_save_v%d.json" % i)
	write_json(folder+"campaign_save_v5.json",input)
	var hash := FileAccess.get_sha256(folder+"campaign_save_v5.json")
	use_paths(folder)
	game._continue_campaign_save()
	expect(game.current_screen == "management" and game.campaign_save_status == "valid","missing anchor safe default Continue")
	check_graph("missing anchor fallback")
	expect(FileAccess.get_sha256(folder+"campaign_save_v5.json") == hash,"missing anchor original file preserved")
