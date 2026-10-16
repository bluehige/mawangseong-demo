extends Node
const Model = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Layout = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const OUT := "res://tmp/v130r_step2/"
const CAPTURE := "C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step2/"
var checks := 0
var failures: Array = []
var game: Node
var view: Control
var preview: Node

func _ready() -> void: call_deferred("run")
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL ",label)
func settle(count: int = 4) -> void:
	for i in range(count): await get_tree().process_frame
func json_file(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t")); file.close()

func inspect(s: Dictionary) -> void:
	expect(s.get("ok",false),"state valid "+str(s.get("errors",[])))
	if not s.get("ok",false): return
	var reached := {}; var todo: Array = [Vector2i(3,8)]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		if reached.has(c) or not s.road_cells.has(c): continue
		reached[c] = true
		for d in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]: todo.append(c+d)
	expect(reached.size()==s.road_cells.size(),"independent flood all roads")
	var used := {}
	for b in s.buildings:
		expect(s.defense_points[b.id].size()==b.capacity,"defense capacity "+b.id)
		var door: Dictionary = s.doors[b.id]
		expect(door.front.size()==2 and door.cells.size()==2,"two-cell socket")
		for c in door.front: expect(reached.has(c),"door connected "+b.id)
		for c in s.defense_points[b.id]:
			expect(not used.has(c) and not s.water.has(c) and s.road_cells.has(c),"independent whole defense cell")
			used[c] = true
		for c in Model.occupied([b]): expect(not s.water.has(c),"building off water")
	for c in s.bridges: expect(s.water.has(c) and s.road_cells.has(c),"bridge automatic at crossing")

func direct() -> void:
	var s: Dictionary = view.baseline
	json_file(OUT+"baseline_debug.json",s)
	inspect(s)
	if not s.get("ok",false): return
	var plan := Layout.read()
	var original_world_count: int = view.world.get_child_count()
	for side in ["N","S","E","W"]:
		var oriented := s.duplicate(true)
		Model.building(oriented,"watchtower").preferred = side
		oriented = Model.rebuild(oriented)
		expect(oriented.ok and oriented.doors.watchtower.side==side,"automatic socket routing "+side)
		if oriented.ok:
			var objects: Array = []
			preload("res://scripts/map_builder/ApprovedTileAssembler.gd").building(view,oriented,Model.building(oriented,"watchtower"),objects)
			var arch: String = view.door_data.face_table[side].arch
			expect(objects.any(func(o): return o.asset=="building/door_arch_"+arch+".png"),"external direction table arch "+side)
	while view.world.get_child_count()>original_world_count: view.world.get_child(-1).free()
	var cross := Model.bridge_cells({Vector2i(8,8):true,Vector2i(26,8):true,Vector2i(1,1):true},s.water)
	expect(cross.get(Vector2i(8,8),"")=="x" and cross.get(Vector2i(26,8),"")=="y" and cross.size()==2,"horizontal and vertical bridges from terrain intersection")
	var expected := {}; var actual := {}
	for c in Layout.cells(plan,"=XmB"): expected[c] = true
	for c in s.road_cells: actual[c] = true
	expect(expected.size()==actual.size(),"plan_E exact road cell count %d/%d" % [expected.size(),actual.size()])
	for c in expected: expect(actual.has(c),"plan_E road "+str(c))
	for c in actual: expect(expected.has(c),"no extra road "+str(c))
	for points in s.defense_points.values():
		for c in points: expect(c in Layout.cells(plan,"m"),"plan_E defense "+str(c))
	var m_count := 0
	for points in s.defense_points.values(): m_count += points.size()
	expect(m_count==18,"plan_E 18 defense points")
	for b in plan.buildings:
		if b.id=="entrance": continue
		expect(s.doors[b.id].side==b.door,"approved door direction "+b.id)
	for point in [Vector2i(-1,0),Vector2i(8,2),Vector2i(27,0),Vector2i(14,7)]:
		expect(not Model.preview(s,"watchtower",point).ok,"reject outside water fixed main "+str(point))
	for id in Model.FIXED: expect(not Model.preview(s,"watchtower",Vector2i.ZERO,id).ok,"fixed move rejected "+id)
	var before := JSON.stringify(Model.snapshot(s))
	var moved := Model.preview(s,"watchtower",Vector2i(3,2),"watchtower")
	inspect(moved)
	expect(JSON.stringify(Model.snapshot(s))==before,"preview is pure")
	expect(moved.get("ok",false) and moved.road_cells!=s.road_cells,"move recomputes roads")
	var rich := s.duplicate(true); rich.resources = {"gold":0,"mana":0,"food":0}
	expect(not Model.preview(rich,"watchtower",Vector2i(3,0)).ok,"cannot afford")
	rich = s.duplicate(true); rich.stage = 1
	expect(not Model.preview(rich,"ward_core",Vector2i.ZERO).ok,"stage lock")
	expect(not Model.preview(s,"recovery_nest",Vector2i.ZERO).ok,"unique count limit")
	expect(not Model.preview(s,"spikes",Vector2i(1,1)).ok,"trap off road rejected")
	var trap_cell := Vector2i(5,8)
	var trap := Model.preview(s,"spikes",trap_cell)
	inspect(trap)
	expect(trap.get("ok",false) and trap.traps.size()==s.traps.size()+1,"one-cell trap on road")
	expect(not Model.preview(trap,"sticky",trap_cell).ok,"trap overlap rejected")
	var removed := Model.dismantle(s,"watchtower")
	inspect(removed)
	var built := Model.preview(removed,"watchtower",Vector2i(3,2))
	inspect(built)
	expect(built.get("ok",false) and built.resources.gold==removed.resources.gold-100,"existing price deducted")
	if built.ok: expect(Model.building(built,"watchtower_1").capacity==5,"new build inherits existing stage capacity bonus")
	var capped := s.duplicate(true)
	for rule in capped.stage_rules.values():
		if int(rule.index)==int(capped.stage): rule.area_room_count = capped.buildings.size()
	expect(not Model.preview(capped,"watchtower",Vector2i(0,0)).ok,"existing stage total construction limit")
	var upgraded := Model.upgrade(s,"barracks")
	inspect(upgraded)
	expect(upgraded.get("ok",false) and Model.building(upgraded,"barracks").capacity==5,"upgrade capacity recalculated")
	var restored := Model.restore(JSON.parse_string(JSON.stringify(Model.snapshot(moved))),s)
	json_file(OUT+"roundtrip_expected.json",Model.snapshot(moved)); json_file(OUT+"roundtrip_actual.json",Model.snapshot(restored))
	inspect(restored)
	expect(Model.snapshot(moved)==Model.snapshot(restored),"JSON roundtrip source")
	expect(restored.road_cells==moved.road_cells and restored.doors==moved.doors and restored.defense_points==moved.defense_points,"derived save roundtrip")
	expect(Model.save_copy(moved)==OK,"write branch test copy")
	expect(Model.snapshot(Model.load_copy(s))==Model.snapshot(moved),"read branch test copy")
	for legacy in [{"version":5},{"schema_version":6,"plot_layout":{}},null]:
		expect(Model.restore(legacy,s)==s,"legacy/no extension safely defaults")
	var broken := Model.snapshot(s); broken.buildings[0].rect = [1,1,3,3]
	expect(not Model.restore(broken,s).ok,"tampered fixed save rejected")
	# Exercise the other arch pair by relocating the watchtower around the trunk.
	var found_sides := {}
	for pos in [Vector2i(0,0),Vector2i(4,0),Vector2i(0,12),Vector2i(5,12),Vector2i(20,2),Vector2i(19,14)]:
		var attempt := Model.preview(s,"watchtower",pos,"watchtower")
		if attempt.ok:
			inspect(attempt); found_sides[attempt.doors.watchtower.side] = true
	print("DOOR_SIDES ",found_sides)

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point; event.global_position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
	get_viewport().push_input(event,true); await settle(2)
func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point; event.global_position = point; event.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(event,true); await settle(3)
func click(point: Vector2) -> void:
	await mouse(point,true); await mouse(point,false)
func button_click(parent: Node, name: String) -> void:
	var button: Control = parent.get_node(name)
	await click(button.get_global_rect().get_center())
func capture(name: String) -> void:
	await settle(6); await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==Vector2i(1920,1080),"capture 1920x1080 "+name)
	expect(image.save_png(CAPTURE+name+".png")==OK,"save capture "+name)
	print("CAPTURE ",name)

func gui() -> void:
	view.placement = view.baseline.duplicate(true); view.render_map(); view.update_wallet()
	view.show_full(); await capture("dynamic_full")
	view.chrome.hide(); await capture("dynamic_full_art_only"); view.chrome.show()
	view.show_default(); await capture("zoom2x_start"); await capture("build_01_bar")
	for asset in ["interiors/throne.png","bridge/entrance_bridge.png"]:
		var sprite: Sprite2D = view.world.get_node(asset.replace("/","_").trim_suffix(".png"))
		var rect := Rect2(view.world.position+sprite.position*view.camera_scale,sprite.texture.get_size()*view.camera_scale)
		expect(Rect2(0,0,1920,1080).encloses(rect),"start includes complete artwork "+asset)
	# Start from a real radial dismantle action, then purchase/drag the same kind.
	await click(view.screen_cell(Vector2(4.5,4.5)))
	expect(view.selected_id=="watchtower","real building selection")
	await button_click(view.radial,"menu_dismantle_refund")
	expect(view.info.get_child_count()>0,"refund confirmation beside building")
	await capture("dismantle_confirmation")
	await button_click(view.info,"menu_dismantle_refund")
	expect(Model.building(view.placement,"watchtower").is_empty(),"confirmed dismantle")
	view.set_camera(Vector2(1500,1390),.6)
	var palette: Control = view.palette_buttons.watchtower
	await mouse(palette.get_global_rect().get_center(),true)
	while view.sites_pending: await settle(1)
	var world_count: int = view.world.get_child_count()
	await motion(view.screen_cell(Vector2(3.3,2.3)))
	expect(view.build_kind=="watchtower" and view.preview.get("ok",false),"palette held drag valid")
	await capture("build_02_drag_valid")
	await motion(view.screen_cell(Vector2(8.3,2.3)))
	expect(view.world.get_child_count()==world_count,"preview thresholds do not leak into map")
	expect(not view.preview.get("ok",true),"palette held drag invalid")
	await capture("build_03_drag_invalid")
	await motion(view.screen_cell(Vector2(3.3,2.3)))
	await mouse(view.screen_cell(Vector2(3.3,2.3)),false)
	expect(view.build_kind=="" and view.last_save_error==OK,"release places and saves test copy")
	var new_id := "watchtower_"+str(view.placement.serial)
	expect(not Model.building(view.placement,new_id).is_empty(),"new building committed")
	await capture("build_04_placed")
	await click(view.screen_cell(Vector2(4.5,3.5)))
	expect(view.selected_id==new_id,"placed building selected")
	await capture("build_05_radial")
	await button_click(view.radial,"menu_info")
	await capture("build_06_info")
	await button_click(view.radial,"menu_upgrade")
	await capture("upgrade_confirmation")
	await button_click(view.info,"menu_upgrade")
	expect(Model.building(view.placement,new_id).level==2,"real upgrade confirm")
	await button_click(view.radial,"menu_move")
	await motion(view.screen_cell(Vector2(3.3,1.3)))
	expect(view.preview.get("ok",false),"menu move preview")
	await click(view.screen_cell(Vector2(3.3,1.3)))
	expect(Model.building(view.placement,new_id).rect.position==Vector2i(3,1),"menu move committed")
	await capture("build_08_moved")
	# Click-to-place (as distinct from held drag).
	await click(view.palette_buttons.spikes.get_global_rect().get_center())
	expect(view.build_kind=="spikes","click palette arms trap")
	await motion(view.screen_cell(Vector2(5.4,8.4)))
	await click(view.screen_cell(Vector2(5.4,8.4)))
	expect(view.placement.traps.any(func(t): return t.cell==[5,8]),"click places trap on road")
	await capture("build_07_trap_on_road")
	var stored := Model.load_copy(view.baseline)
	expect(Model.snapshot(stored)==Model.snapshot(view.placement),"GUI placement persisted")
	inspect(view.placement)
	var before_reload := Model.snapshot(view.placement)
	game._set_screen("management",false); await settle(8)
	view = game.ui_layer.get_node("ApprovedMapManagement")
	expect(Model.snapshot(view.placement)==before_reload,"management rebuild loads saved layout")

func legacy_copies() -> void:
	for label in ["legacy_v5","plot_v6"]:
		var folder: String = OUT+"copies/"+label+"/"
		var source: String = folder+"campaign_save_"+("v5" if label=="legacy_v5" else "v6")+".json"
		expect(FileAccess.file_exists(source),"existing copied save "+label)
		if not FileAccess.file_exists(source): continue
		game._set_campaign_save_path_for_tests(folder+"campaign_save_v1.json",folder+"campaign_save_v2.json",folder+"campaign_save_v3.json",folder+"campaign_save_v4.json",folder+"campaign_save_v5.json",folder+"campaign_save_v6.json")
		expect(game.campaign_save_status=="valid","valid legacy copy "+label)
		if game.campaign_save_status=="valid":
			game._continue_campaign_save(); await settle(8)
			var current: Control = game.ui_layer.get_node_or_null("ApprovedMapManagement")
			expect(current!=null and current.placement.ok,"Continue with step2 "+label)
			expect(game.graph.validation_summary().ok,"original campaign graph preserved "+label)
		game.campaign_save_enabled = false; game.campaign_autosave_pending = false

func run() -> void:
	if OS.get_cmdline_user_args().has("--capture"): get_window().size = Vector2i(1920,1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(CAPTURE)
	# Deterministic test baseline. Only delete this explicitly named test copy.
	if FileAccess.file_exists(Model.SAVE_PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(Model.SAVE_PATH))
	preview = load("res://scenes/map_builder/ApprovedPlacementPreview.tscn").instantiate()
	add_child(preview); await settle(10)
	game = preview.game
	view = game.ui_layer.get_node_or_null("ApprovedMapManagement")
	expect(view!=null,"actual GameRoot placement management")
	var graphical := OS.get_cmdline_user_args().has("--capture")
	if view!=null:
		if graphical: await gui()
		else: direct()
		await legacy_copies()
	game.campaign_save_enabled = false; game.campaign_autosave_pending = false; game._shutdown_audio_for_exit()
	preview.queue_free(); await settle(5)
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"capture":graphical}
	json_file(OUT+("gui_result.json" if graphical else "direct_result.json"),result)
	print("V130RStep2PlacementTest ",result)
	get_tree().quit(0 if failures.is_empty() else 1)
