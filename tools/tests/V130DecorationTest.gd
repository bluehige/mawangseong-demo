extends Node
const Game = preload("res://scenes/game/GameRoot.tscn")
var game: Node
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var baseline := false
func _ready() -> void: call_deferred("run")
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL: ",label)
func settle(count: int = 8) -> void:
	for i in range(count): await get_tree().process_frame
func capture(label: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	if OS.get_cmdline_user_args().has("--capture-english-only") and label!="decor_en": return
	await settle()
	await RenderingServer.frame_post_draw
	var path := "res://tmp/v130_m4/"+("before_" if baseline else "after_")+label+".png"
	get_viewport().get_texture().get_image().save_png(path)
	captures.append(path)
func spawn() -> void:
	game = Game.instantiate()
	game.campaign_save_enabled = false
	add_child(game)
	await settle()
	GameState.player_name = "Map Lord"
	game.update2_cycle_seed = 1304
	game.set_process(false)
	game.onboarding_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
	game.story_feature_enabled = false; game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
func release() -> void:
	game.campaign_autosave_pending = false
	game._shutdown_audio_for_exit()
	game.queue_free(); await settle(3)
func show_map() -> void:
	game.management_scene.workspace_ui.tools_expanded = false
	game.management_tool_tab = "roster"
	game._set_screen("management",false)
	await settle()
func run() -> void:
	baseline = OS.get_cmdline_user_args().has("--baseline")
	get_window().size = Vector2i(1920,1080)
	LanguageSettings.set_locale("ko",false)
	if OS.get_cmdline_user_args().has("--checks-only"):
		await decoration_checks()
		finish()
		return
	await spawn()
	await show_map()
	await capture("plot")
	GameState.day = 15
	game.first_promotion_completed = true
	game.campaign_stage_two_upgrade_funded = false
	GameState.gold = 0; GameState.infamy = 0
	game._onboarding_set_stage("CAMPAIGN_DAY_15")
	await show_map()
	await capture("day15")
	game.campaign_stage_two_unlock_ready = true
	game._apply_castle_evolution_for_day(15)
	await show_map()
	await capture("expanded")
	await release()
	await spawn()
	GameState.day = 1
	game.onboarding_enabled = true; game.tutorial_gate_enabled = true
	game._onboarding_set_stage("DAY1")
	for i in range(game.tutorial_manager.steps.size()):
		if game.tutorial_manager.steps[i].id == "TUT_040_DEPLOY_SLIME":
			game.tutorial_manager.current_index = i
			game.onboarding_stage_id = str(game.tutorial_manager.steps[i].stage)
	game.tutorial_manager.active = true
	game.deploy_pick_monster_id = "goblin"
	game.selected_room = "barracks"
	game.management_tool_tab = "roster"
	game.management_scene.workspace_ui.tools_expanded = true
	game._set_screen("management",false)
	await settle()
	if not baseline:
		var targets = preload("res://scripts/map_builder/PlotTutorialTargets.gd")
		for id in targets.formation_rooms(game):
			var floor_rect: Rect2 = game.graph.rect(id)
			var anchor: Vector2 = game.get_global_transform_with_canvas()*Vector2(floor_rect.get_center().x,floor_rect.position.y)
			var name_rect: Rect2 = game._management_label_layout(anchor,game.display_name_for_instance(id),20,true).rect
			var glow: Rect2 = game._tutorial_room_rect(id).grow(-30).grow(14)
			expect(not glow.intersects(name_rect),"tutorial glow avoids upper nameplate "+id)
	await capture("tutorial")
	await release()
	if not baseline: await decoration_checks()
	finish()
func finish() -> void:
	var f := FileAccess.open("res://tmp/v130_m4/"+("baseline" if baseline else "result")+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t")); f.close()
	print("V130DecorationTest %s checks=%d failures=%s" % ["PASS" if failures.is_empty() else "FAIL",checks,failures])
	get_tree().quit(0 if failures.is_empty() else 1)
func resources() -> Array: return [GameState.gold,GameState.mana,GameState.food,GameState.infamy]
func canonical(value): return JSON.parse_string(JSON.stringify(value))
func control(id: String) -> Control: return game.ui_layer.find_child(id,true,false)
func tap(point: Vector2, touch: bool) -> void:
	for pressed in [true,false]:
		var event: InputEvent = InputEventScreenTouch.new() if touch else InputEventMouseButton.new()
		if touch: event.index = 3
		else:
			event.button_index = MOUSE_BUTTON_LEFT
			event.global_position = point
			event.device = 0
		if not touch and pressed:
			var motion := InputEventMouseMotion.new()
			motion.position = point; motion.global_position = point
			get_viewport().push_input(motion,true); await settle(2)
		event.position = point; event.pressed = pressed
		get_viewport().push_input(event,true); await settle(3)
func click(id: String, touch: bool = false) -> void:
	var button := control(id) as Button
	expect(button!=null and button.is_visible_in_tree() and not button.disabled,"UI available "+id)
	if button==null: return
	var parent := button.get_parent()
	while parent!=null:
		if parent is ScrollContainer: parent.ensure_control_visible(button)
		parent = parent.get_parent()
	await settle()
	await tap(button.get_global_rect().get_center(),touch)
func free_cell(id: String) -> Vector2i:
	var cells: Array = game.graph.layout.plot_mask.keys()
	cells.sort_custom(func(a,b): return game.build_placement.plot.world(a).distance_squared_to(game.graph.center("treasure"))<game.build_placement.plot.world(b).distance_squared_to(game.graph.center("treasure")))
	for cell in cells:
		var point: Vector2 = game.get_global_transform_with_canvas()*game.build_placement.plot.world(cell)
		if point.y<300 or point.y>760 or point.x<400 or point.x>1480 or game._management_ui_at(point): continue
		if game.build_placement.decor.valid(cell,id): return cell
	return Vector2i(-1,-1)
func assert_view() -> void:
	var rect: Rect2 = preload("res://scripts/map_builder/PlotPresentation.gd").view_bounds(game.graph)
	var shown: Rect2 = game.get_global_transform_with_canvas()*rect
	var safe: Rect2 = game.build_placement._workspace_safe_rect()
	expect(safe.grow(1).encloses(shown),"whole plot and rear wall fit workspace")
	expect(shown.get_center().distance_to(safe.get_center())<1,"plot centered after growth")
func input_flow(locale: String, touch: bool) -> void:
	LanguageSettings.set_locale(locale,false)
	await spawn(); await show_map()
	var decor = game.build_placement.decor
	var rules = preload("res://scripts/map_builder/PlotDecorationRules.gd")
	var before_rooms: Dictionary = game.rooms.duplicate(true)
	var before_roster: Dictionary = game.monster_roster.duplicate(true)
	var before_resources := resources()
	var before_walk: Dictionary = game.graph.tile_walk_cells.duplicate(true)
	var before_roads: Dictionary = game.graph.layout.auto_roads.road_cells.duplicate(true)
	var before_route: Array = game.graph.path_between("entrance","throne").duplicate(true)
	var snapshot: Dictionary = game.combat_scene.build_precombat_snapshot(false)
	var before_schedule: Array = snapshot.get("schedule",[]).duplicate(true)
	expect(rules.evaluation(decor.source(),0).grade=="F","actual initial growth appraised F, independent of legacy layout grade")
	await click("DecorationStatusButton",touch)
	expect(control("DecorationToolbox")!=null,"palette opens from visible castle grade")
	var amethyst: Control = control("DecorationCard_crystal")
	for child in amethyst.get_children():
		if child is Label:
			var translated: String = child.text
			if translated=="Amethyst":
				expect(child.get_theme_font("font").get_string_size(translated,HORIZONTAL_ALIGNMENT_LEFT,-1,child.get_theme_font_size("font_size")).x<=child.size.x,"Amethyst stays on one line")
	assert_view()
	for definition in rules.data().items:
		var id: String = definition.id
		await click("DecorationCard_"+id,touch)
		expect(decor.chosen==id,"actual palette selection "+id+locale+str(touch))
		var cell := free_cell(id)
		expect(cell!=Vector2i(-1,-1),"visible empty plot cell")
		if cell==Vector2i(-1,-1): continue
		var point: Vector2 = game.get_global_transform_with_canvas()*game.build_placement.plot.world(cell)
		await tap(point,touch)
		expect(decor.rows().size()>0 and decor.rows().back().id==id,"actual world input places "+id)
		expect(not decor.active(),"placement clears pending input")
		if touch:
			var count: int = decor.rows().size()
			for pressed in [true,false]:
				var duplicate := InputEventMouseButton.new()
				duplicate.device = InputEvent.DEVICE_ID_EMULATION; duplicate.position = point; duplicate.global_position = point
				duplicate.button_index = MOUSE_BUTTON_LEFT; duplicate.pressed = pressed
				get_viewport().push_input(duplicate,true)
			expect(decor.rows().size()==count,"touch emulation does not duplicate decoration")
	expect(decor.rows().size()==6,"all six cosmetic types placed")
	expect(rules.score(decor.source())==11,"intimidation sums catalog values")
	var evaluation: Dictionary = rules.evaluation(decor.source(),0)
	expect(evaluation.decoration==10 and evaluation.grade=="E","small capped appraisal contribution reflects castle grade")
	expect(control("DecorationStatusButton").text.contains("11"),"visible grade status refreshed")
	expect(game.rooms==before_rooms and game.monster_roster==before_roster,"all room and monster stats identical")
	expect(resources()==before_resources,"decoration spends no gameplay resource")
	expect(game.graph.tile_walk_cells==before_walk and game.graph.layout.auto_roads.road_cells==before_roads,"walkability and automatic road cells identical")
	expect(game.graph.path_between("entrance","throne")==before_route,"battle route unchanged")
	expect(game.combat_scene.build_precombat_snapshot(false).get("schedule",[])==before_schedule,"enemy wave schedule unchanged")
	var road_cell: Vector2i = before_roads.keys()[0]
	expect(not decor.valid(road_cell,"torch"),"road placement refused")
	expect(not decor.valid(game.build_placement.plot.cell_at(game.graph.center("throne")),"torch"),"room and throne placement refused")
	expect(not decor.valid(Vector2i(-100,-100),"torch"),"locked/outside placement refused")
	var occupied: Vector2i = Vector2i(int(decor.rows()[0].cell[0]),int(decor.rows()[0].cell[1]))
	expect(not decor.valid(occupied,"torch"),"overlapping decorations refused")
	var bad: Dictionary = game.graph.layout.duplicate(true)
	bad.decorations = [{"id":"unknown","cell":[0,0]}]
	expect(rules.validate(bad,DataRegistry.quarter_modules)!="","unknown decoration rejected in v6 source")
	var saved_rows: Array = decor.rows().duplicate(true)
	await click("DecorationCard_torch",touch)
	var cancel_event := InputEventKey.new(); cancel_event.keycode = KEY_ESCAPE; cancel_event.pressed = true
	get_viewport().push_input(cancel_event,true); await settle()
	expect(not decor.active() and decor.rows()==saved_rows,"ESC cancels without edits")
	await click("DecorationRemoveButton",touch)
	await tap(game.get_global_transform_with_canvas()*game.build_placement.plot.world(occupied),touch)
	expect(decor.rows().size()==5,"actual removal input")
	expect(game._undo_last_management_placement(),"shared undo restores removal")
	await settle()
	expect(decor.rows()==saved_rows,"undo restores decoration IDs and cells")
	if not touch:
		await capture("decor_"+locale)
	await save_roundtrip()
	# Put one cosmetic object under a future generated road/room. Growth must
	# relocate that object without moving a road, changing score or blocking land.
	var old_stage: String = game.castle_art_stage
	game.castle_art_stage = "stage_02_castle"
	var future: Dictionary = game._quarter_layout_for_graph()
	game.castle_art_stage = old_stage
	var conflict := Vector2i(-1,-1)
	for occupied_cell: Vector2i in rules.occupied(future,DataRegistry.quarter_modules):
		var old_cell := occupied_cell-Vector2i(6,6)
		if decor.valid(old_cell,"torch"):
			conflict = old_cell; break
	expect(conflict!=Vector2i(-1,-1),"future growth collision fixture exists")
	if conflict!=Vector2i(-1,-1):
		decor.begin("torch")
		expect(decor.place(conflict),"place under future mandatory growth footprint")
	var growth_rows: Array = decor.rows().duplicate(true)
	var score_before: int = rules.score(decor.source())
	var cell_before: Vector2i = Vector2i(int(decor.rows()[0].cell[0]),int(decor.rows()[0].cell[1]))
	GameState.day = 15; game.campaign_stage_two_unlock_ready = true
	expect(game._apply_castle_evolution_for_day(15),"existing gate grants growth")
	await show_map()
	expect(Vector2i(int(decor.rows()[0].cell[0]),int(decor.rows()[0].cell[1]))==cell_before+Vector2i(6,6),"decoration translates with enlarged coordinate center")
	expect(rules.validate(game.graph.layout,DataRegistry.quarter_modules)=="","decorations remain valid after real growth")
	expect(decor.rows().size()==growth_rows.size() and rules.score(decor.source())==score_before,"growth keeps all decoration types and score")
	if conflict!=Vector2i(-1,-1):
		expect(decor.rows().back().cell!=[conflict.x+6,conflict.y+6],"only colliding decoration rehomed off new road/room")
	var actual_layout: Dictionary = game.graph.layout.duplicate(true)
	var ordinary := actual_layout.duplicate(true)
	ordinary.erase("decorations")
	var ordinary_graph := preload("res://scripts/dungeon_quarter/ModuleGraph.gd").new()
	ordinary_graph.setup_quarter(DataRegistry.quarter_modules,ordinary,game.rooms)
	expect(ordinary_graph.tile_walk_cells==game.graph.tile_walk_cells,"growth decoration relocation does not reroute combat")
	assert_view()
	await release()
func save_roundtrip() -> void:
	var folder := "res://tmp/v130_m4/save_"+LanguageSettings.locale+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	game._set_campaign_save_path_for_tests(folder+"v1.json",folder+"v2.json",folder+"v3.json",folder+"v4.json",folder+"v5.json",folder+"v6.json")
	var before: Dictionary = game._plot_save_state()
	game._schedule_campaign_autosave("management")
	expect(game._flush_campaign_autosave(),"actual v6 write: "+game.campaign_save_error)
	if not FileAccess.file_exists(folder+"v6.json"):
		expect(false,"v6 envelope must exist before Continue")
		return
	var envelope = JSON.parse_string(FileAccess.get_file_as_string(folder+"v6.json"))
	if not envelope is Dictionary:
		expect(false,"v6 envelope must exist before Continue")
		return
	expect(envelope.version==6 and envelope.active_run.plot_state.layout_source.decorations==canonical(before.layout_source.decorations),"v6 disk decoration IDs and cells")
	var migration = preload("res://scripts/systems/save/SaveV5ToV6Migrator.gd")
	var modern_missing: Dictionary = envelope.duplicate(true)
	for id in migration.COUNCIL_1F_METRICS: modern_missing.active_run.run_metrics.erase(id)
	expect(migration.validate_v6(modern_missing,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)!="","modern v6 still rejects missing required council metrics")
	var historical: Dictionary = modern_missing.duplicate(true)
	historical.active_run["upper_floor"] = {}
	historical.active_run.erase("expansion")
	var original: Dictionary = historical.duplicate(true)
	expect(migration.validate_v6(historical,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)=="","historical v6 can adopt new council defaults without plot repair")
	var converted: Dictionary = migration.convert_council(historical,DataRegistry.run_metric_definitions)
	for id in migration.COUNCIL_1F_METRICS: expect(converted.active_run.run_metrics[id]==DataRegistry.run_metric_definitions[id].default,"new council metric defaults only "+id)
	expect(historical==original and converted.active_run.plot_state==historical.active_run.plot_state,"metric conversion preserves input and exact decorated plot")
	var invalid_existing: Dictionary = historical.duplicate(true)
	invalid_existing.active_run.run_metrics[migration.COUNCIL_1F_METRICS[0]] = "bad"
	expect(migration.council_metric_defaults(invalid_existing,DataRegistry.run_metric_definitions).active_run.run_metrics[migration.COUNCIL_1F_METRICS[0]]=="bad","existing malformed values never overwritten with defaults")

	game.runtime_plot_layout.clear(); game.plot_unlock_history.clear()
	game._set_screen("title",false)
	game._continue_campaign_save(); await settle()
	expect(game.current_screen=="management","actual Continue with decorated v6")
	expect(canonical(game._plot_save_state())==canonical(before),"entire decorated plot and unlock history roundtrip")
func decoration_checks() -> void:
	for locale in ["ko","en","zh_CN"]:
		for touch in [false,true]: await input_flow(locale,touch)
	text_checks()
	LanguageSettings.set_locale("ko",false)
func text_checks() -> void:
	var clean = preload("res://scripts/ui/CastlePresentationText.gd")
	for locale in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		var display: String = LanguageSettings.presentation_text("Stage 02 심사 비용을 먼저 마련하세요.")
		expect(not display.contains("Stage") and not display.contains("阶段"),"no internal stage in management gate "+locale)
		var expected: String = {"ko":"소마왕성","en":"Lesser Demon Castle","zh_CN":"小魔王城"}[locale]
		expect(display.contains(expected),"localized user castle name "+locale)
		var sample: String = LanguageSettings.presentation_text("Stage 02 해금: 비용 심사와 셀렌 점검을 통과해 다음 성 단계 적용 준비가 끝났다. (stage_two_unlock_ready)")
		expect(not sample.contains("stage_two_") and not sample.contains("Stage 02"),"known internal result flag hidden "+locale)
		expect(clean.clean(sample,locale)==sample,"output cleanup idempotent "+locale)
		expect(clean.clean("Stage 02",locale,"Stage 02")=="Stage 02","protected player name retained "+locale)
		expect(clean.clean("res://stage_02_castle.png",locale)=="res://stage_02_castle.png","asset paths untouched "+locale)
		expect(clean.clean("Stage 04 "+{"ko":"대마왕성","en":"Grand Demon Castle","zh_CN":"大魔王城"}[locale],locale)=={"ko":"대마왕성","en":"Grand Demon Castle","zh_CN":"大魔王城"}[locale],"no duplicate display name "+locale)
	expect(LanguageSettings.ui_text("Stage 04")=="第04阶段","raw translation contract preserved")
