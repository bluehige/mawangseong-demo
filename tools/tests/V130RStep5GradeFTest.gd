extends Node
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const Grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
const Map = preload("res://scripts/map_builder/ApprovedBattleMap.gd")
const Plan = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const OUT := "res://tmp/v130r_step5/"
var preview: Node
var game: Node
var view: Control
var checks := 0
var failures: Array[String] = []
var evidence := {}
var capture := false
func _ready() -> void: run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL ",message)
func boot() -> void:
	preview = load("res://scenes/map_builder/ApprovedPlacementPreview.tscn").instantiate(); add_child(preview)
	await get_tree().create_timer(.3).timeout
	game = preview.game; view = game.ui_layer.get_node("ApprovedMapManagement")
	view.placement = Buildings.initial(game,"F"); view.monster_ui.assignments = {}
	view.state = Plan.read("F"); view.render_map(); view.show_default()
	GameState.day = 1; GameState.demon_lord_hp = 1500; GameState.demon_lord_max_hp = 1500; GameState.max_day = 30
	if capture: get_window().size = Vector2i(1920,1080)
	await get_tree().process_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==Vector2i(1920,1080),name+" native viewport")
	expect(image.save_png(OUT+name+".png")==OK,name+" saved")
func fixture_defenders() -> Dictionary:
	return {"mon_core_pudding":{"building":"barracks","slot":0},"mon_core_gob":{"building":"watchtower","slot":0},"mon_core_pynn":{"building":"throne","slot":0},"mon_core_rolo":{"building":"bait_treasure","slot":0}}
func direct() -> void:
	var f: Dictionary = view.placement
	expect(f.ok,"F initial routes: "+str(f.errors))
	if not f.ok: return
	expect(Buildings.dimensions(f)==Vector2i(22,16),"F dimensions")
	var plan := Plan.read("F")
	for b in plan.buildings:
		expect(Buildings.building(f,b.id).rect==Rect2i(b.rect[0],b.rect[1],b.rect[2],b.rect[3]),"F exact building "+b.id)
	expect(f.buildings.size()==6 and f.traps.size()==4,"F 6 buildings and 4 traps")
	var defense_cells := {}
	for points in f.defense_points.values():
		for c in points: defense_cells[c] = true
	var plan_defense := Plan.cells(plan,"m")
	expect(defense_cells.size()==plan_defense.size(),"F exact plan defense count")
	for c in plan_defense: expect(defense_cells.has(c),"F authoritative defense cell "+str(c))
	evidence["f"] = {"size":str(Buildings.dimensions(f)),"water_cells":f.water.size(),"bridge_cells":f.bridges.size(),"roads":f.road_cells.size(),"defense_points":str(f.defense_points),"start_center":str(view.camera_center),"start_scale":view.camera_scale}
	expect(f.water.size()==Plan.cells(plan,"~B").size(),"exact F water count")
	for c in Plan.cells(plan,"~B"): expect(f.water.has(c),"F water "+str(c))
	for c in f.road_cells: expect(Rect2i(0,0,22,16).has_point(c),"F road in bounds")
	var expected_roads := Plan.cells(plan,"=mXB")
	var missing: Array = []; var extra: Array = []
	for c in expected_roads:
		if not f.road_cells.has(c): missing.append(str(c))
	for c in f.road_cells:
		if c not in expected_roads: extra.append(str(c))
	evidence["plan_roads"] = {"missing":missing,"extra":extra,"expected":expected_roads.size(),"actual":f.road_cells.size()}
	expect(missing.is_empty() and extra.is_empty(),"F exact plan roads "+str(evidence.plan_roads))
	var map := Map.new(); map.setup(f)
	expect(map.astar.region.size==Vector2i(22,16),"F AStar region")
	expect(map.line_for(Vector2i(13,5))=="1" and map.line_for(Vector2i(16,5))=="final","F has first and final defense only")
	for id in f.doors:
		var path := map.path_cells(f.doors.entrance.front[0],f.doors[id].front[0])
		expect(not path.is_empty(),"F AStar reaches "+id)
		for i in range(path.size()):
			expect(map.is_road(path[i]) and (not f.water.has(path[i]) or f.bridges.has(path[i])),"F path road or bridge")
			if i>0: expect(Buildings.Defense.manhattan(path[i],path[i-1])==1,"F orthogonal steps")
	for c in [Vector2(0,0),Vector2(21,15),Vector2(3.5,8.5)]: expect(Plan.unproject(Plan.project(c,22),22).distance_to(c)<.001,"F projection roundtrip")
	expect(is_equal_approx(view.camera_scale,.75*view.ScreenLayout.unit(view.size)),"0087 F start uses same cells per viewport")
	var defenders := fixture_defenders()
	expect(Members.sanitize(f,defenders,view.monster_ui.members).size()==4,"four base species valid F slots")
	var day14 := Grade.advance(game,f,defenders,14)
	expect(day14.ok and day14.layout.grade=="F" and day14.layout.stage==1,"DAY14 stays F")
	var before := JSON.stringify(Buildings.snapshot(f))
	var transition := Grade.advance(game,day14.layout,defenders,15)
	expect(transition.ok,"F to E migration")
	if not transition.ok: return
	var e: Dictionary = transition.layout
	expect(e.grade=="E" and e.stage==2 and e.day==15 and Buildings.dimensions(e)==Vector2i(32,18),"DAY15 E stage2")
	expect(e.buildings.size()==f.buildings.size(),"no free E facilities added")
	expect(e.resources==f.resources and e.serial==f.serial,"resources and serial preserved")
	for old in f.buildings:
		var row := Buildings.building(e,old.id)
		var base: Dictionary = Buildings.building(Buildings.initial(game),old.kind)
		expect(row.rect==base.rect,"same kind E default "+old.id)
		for key in ["id","level","capacity","paid"]: expect(row[key]==old[key],"preserved "+old.id+" "+key)
	for id in defenders:
		expect(transition.defenders.has(id) and transition.defenders[id].building==defenders[id].building,"same building defender "+id)
		expect(Members.cell(e,transition.defenders[id])!=Vector2i(-999,-999),"valid migrated slot")
	expect(e.traps.size()==f.traps.size(),"trap count preserved")
	expect(JSON.stringify(Buildings.snapshot(f))==before,"transition is atomic and source immutable")
	evidence["migration"] = transition.moves
	for stage_day in [[21,3],[28,4]]:
		var later := Grade.advance(game,e,transition.defenders,stage_day[0])
		expect(later.ok and later.layout.grade=="E" and later.layout.stage==stage_day[1],"D/C stages keep E map")
		expect(later.layout.buildings==e.buildings,"later stages do not relocate buildings")
	expect(not Grade.advance(game,e,transition.defenders,14).ok,"no downgrade")
	# Another barracks claims its type's default; the second must find a vacancy.
	var crowded := f.duplicate(true)
	var duplicate := Buildings.building(crowded,"barracks").duplicate(true)
	duplicate.id = "barracks_custom"; duplicate.level = 2; duplicate.paid.gold += 100
	duplicate.rect.position = Vector2i(8,0)
	crowded.buildings.append(duplicate)
	crowded = Buildings.rebuild(crowded)
	expect(crowded.ok,"fallback source geometry is valid")
	var fallback := Grade.advance(game,crowded,defenders,15)
	expect(fallback.ok,"duplicate kind finds empty E site")
	if fallback.ok:
		expect(Buildings.building(fallback.layout,"barracks_custom").rect!=Buildings.building(fallback.layout,"barracks").rect,"fallback does not overlap default")
		expect(Buildings.building(fallback.layout,"barracks_custom").level==2,"fallback preserves upgrade")
		evidence["fallback"] = fallback.moves
	var impossible := f.duplicate(true)
	var huge := duplicate.duplicate(true); huge.rect.size = Vector2i(40,40)
	impossible.buildings.append(huge)
	var unchanged := JSON.stringify(Buildings.snapshot(impossible))
	expect(not Grade.advance(game,impossible,defenders,15).ok,"unplaceable migration rejected atomically")
	expect(JSON.stringify(Buildings.snapshot(impossible))==unchanged,"failed migration preserves source")
	var overflow := {}
	var ids: Array = view.monster_ui.members.keys()
	for i in range(f.defense_points.watchtower.size()): overflow[ids[i]] = {"building":"watchtower","slot":i}
	overflow["mon_contract_mori"] = {"building":"watchtower","slot":20}
	var reserve := Grade.advance(game,f,overflow,15)
	expect(reserve.ok and "mon_contract_mori" in reserve.waiting and not reserve.defenders.has("mon_contract_mori"),"overflow goes to waiting")
	for source in [f,e]:
		var snap := Buildings.snapshot(source)
		var restored := Buildings.restore(JSON.parse_string(JSON.stringify(snap)),Buildings.initial(game,source.grade))
		expect(restored.ok and restored.grade==source.grade and restored.buildings==source.buildings,"grade snapshot roundtrip")
		expect(not Buildings.restore(snap,Buildings.initial(game,"E" if source.grade=="F" else "F")).ok,"wrong grade save rejected")
	expect(Members.save_copy(e,transition.defenders,Grade.SAVE_PATH)==OK,"only step5 test save")
	var reread := Grade.load_session(game)
	expect(reread.layout.grade=="E" and reread.defenders==transition.defenders,"reopen E progression copy")
	view.monster_ui.assignments = defenders; view.render_map()
	expect(view.start_battle(),"F combat adapter starts")
	var battle = view.battle; battle.set_pause_state(true)
	battle.spawn_enemy("explorer",{})
	var enemy: Node = game.enemy_units[-1]
	var trap: Vector2i = Vector2i(f.traps[0].cell[0],f.traps[0].cell[1])
	enemy.position = battle.map.world(trap)
	var hp: int = enemy.hp; battle.apply_cell_traps(enemy)
	expect(enemy.hp<hp,"F spikes damage existing Unit with its defenses")
	expect(enemy.get_cell_tags().trap=="spikes","F unit exposes trap cell API")
	expect(battle.map.goal_for(DataRegistry.enemy("thief"),battle.map.center("entrance"))=="bait_treasure","F thief targets decoy")
	for unit in game.monster_units:
		expect(battle.map.is_walkable(unit.position),"F defender spawns on road")
		for key in ["road","bridge","water_adjacent","trap","defense_line","aura"]: expect(unit.get_cell_tags().has(key),"F unit tag "+key)
func capture_run() -> void:
	expect(view.placement.ok,"capture F valid")
	if not view.placement.ok: return
	view.show_full(); await get_tree().create_timer(.4).timeout; await shot("f_full")
	view.show_default(); await get_tree().create_timer(.2).timeout; await shot("f_start")
	expect(is_equal_approx(view.camera_scale,.75),"native F 96x48 cell pixels")
	view.monster_ui.assignments = fixture_defenders(); view.render_map()
	var before: Dictionary = view.set_preview_day(14)
	expect(before.ok,"set F DAY14")
	await get_tree().create_timer(.2).timeout; await shot("f_to_e_transition_before")
	var after: Dictionary = view.set_preview_day(15)
	expect(after.ok,"view F to E")
	evidence["view_migration"] = after.get("moves",[])
	await get_tree().create_timer(.4).timeout; await shot("f_to_e_transition_after")
	# Reload a fresh F fixture, then run the unchanged DAY3 schedule to settlement.
	view.placement = Buildings.initial(game,"F"); view.monster_ui.assignments = fixture_defenders()
	view.state = Plan.read("F"); view.render_map(); view.set_preview_day(3)
	expect(view.start_battle(),"F DAY3 actual start")
	var battle = view.battle
	expect(game.wave_manager.total_to_spawn==5,"original DAY3 explorer3 thief1 trainee1")
	var contact := false; var screenshot := false
	var started := Time.get_ticks_msec()
	while battle.running and Time.get_ticks_msec()-started<150000:
		await get_tree().process_frame
		if not screenshot and not battle.contacts.is_empty():
			contact = true; battle.set_pause_state(true)
			await shot("f_battle_day3"); screenshot = true
			battle.set_pause_state(false); battle.set_speed(3)
	expect(not battle.running,"DAY3 actual wave finishes")
	expect(contact and screenshot,"DAY3 actual contact captured")
	expect(game.spawned_count==game.wave_manager.total_to_spawn,"all original DAY3 enemies spawned")
	evidence["day3"] = battle.last_result.duplicate(true)
	evidence["contacts"] = battle.contacts.size(); evidence["skills"] = battle.skill_events.size()
	await get_tree().create_timer(.3).timeout
	expect(game.current_screen=="result","existing result screen")
	# Exercise the same next-day callback used by the real result button, across
	# DAY14 -> DAY15, while remaining inside the isolated preview session.
	var session := Grade.load_session(game)
	session.layout.day = 14; Grade.stash(game,session.layout,session.defenders)
	game._advance_after_result(); await get_tree().create_timer(.3).timeout
	view = game.ui_layer.get_node("ApprovedMapManagement")
	expect(view.placement.day==15 and view.placement.grade=="E","actual result next-day callback swaps F to E")
	evidence["result_continuation"] = {"day":view.placement.day,"grade":view.placement.grade,"defenders":view.monster_ui.assignments}
func run() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var prior := {}
	for p in [Members.SAVE_PATH,Buildings.SAVE_PATH]: prior[p] = FileAccess.get_file_as_bytes(p) if FileAccess.file_exists(p) else PackedByteArray()
	await boot()
	if capture: await capture_run()
	else: await direct()
	for p in prior: expect(prior[p]==(FileAccess.get_file_as_bytes(p) if FileAccess.file_exists(p) else PackedByteArray()),"earlier test save untouched")
	game.campaign_autosave_pending = false; game._shutdown_audio_for_exit()
	if is_instance_valid(view) and view.battle!=null:
		view.battle.running = false; view.battle._clear_active_combat_tweens()
	preview.queue_free(); await get_tree().process_frame
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"evidence":evidence}
	var file := FileAccess.open(OUT+("capture" if capture else "direct")+"_result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")); file.close()
	print("V130RStep5GradeFTest ",checks," checks / ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
