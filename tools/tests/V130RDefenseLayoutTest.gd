extends Node
const Layout = preload("res://scripts/map_builder/DefenseLayout.gd")
const Roads = preload("res://scripts/map_builder/AutoRoadBuilder.gd")
const Service = preload("res://scripts/map_builder/MapBuildService.gd")
const OUT := "C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/graybox/"
var checks := 0
var failures: Array = []
var accepted := 0
var rejected := 0
var attempts := 0
var duplicates := 0
var game: Node
var view: Control
var metrics := {"main_connections":0,"connected_doors":0,"road_fragments":0,"width_violations":0,"short_segments":0,"occluding_walls":0,"defense_points":0}

func _ready() -> void: call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL ",message)

func settle(count: int = 6) -> void:
	for index in range(count): await get_tree().process_frame

func independent_checks(state: Dictionary) -> void:
	expect(state.ok,"accepted layout")
	if not state.ok: return
	var roads: Dictionary = state.road_cells
	var reached: Dictionary = {}
	var pending: Array = [state.doors.entrance.front[0]]
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		if reached.has(cell) or not roads.has(cell): continue
		reached[cell] = true
		for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]: pending.append(cell+direction)
	expect(reached.size()==roads.size(),"independent flood fill: no fragments")
	if reached.size()!=roads.size(): metrics.road_fragments += 1
	for cell: Vector2i in roads:
		var square: Array = []
		for x in range(3):
			for y in range(3):
				if roads.has(cell+Vector2i(x,y)): square.append(cell+Vector2i(x,y))
		expect(square.size()<9,"no solid three-wide road patch")
		if square.size()==9: metrics.width_violations += 1
	for id in ["throne","vault"]:
		var linked := true
		for cell in state.doors[id].front:
			if not reached.has(cell): linked = false
		expect(linked,"main connection "+id)
		if linked: metrics.main_connections += 1
	var rebuilt: Dictionary = {}
	for path in state.paths:
		var anchors: Array = path.anchors
		var turn_indices: Array = [0]
		for index in range(1,anchors.size()-1):
			if anchors[index]-anchors[index-1] != anchors[index+1]-anchors[index]: turn_indices.append(index)
		if anchors.size()>1: turn_indices.append(anchors.size()-1)
		for index in range(1,turn_indices.size()):
			var long_enough: bool = turn_indices[index]-turn_indices[index-1]+1>=3
			expect(long_enough,"independent segment length")
			if not long_enough: metrics.short_segments += 1
		for anchor: Vector2i in anchors:
			for x in range(2):
				for y in range(2):
					var cell := anchor+Vector2i(x,y)
					rebuilt[cell] = true
					expect(roads.has(cell),"independent width-two raster")
					if not roads.has(cell): metrics.width_violations += 1
	expect(rebuilt.size()==roads.size(),"every road tile belongs to width-two path")
	for row in state.buildings:
		var rect: Rect2i = row.rect
		for cell in roads:
			expect(not rect.has_point(cell),"road does not enter wall or building")
		var door: Dictionary = state.doors[row.id]
		var bands := Layout.wall_bands(row,door)
		expect(bands.size()==3,"only three closed building edges")
		for band in bands:
			var enclosed: bool = Rect2(rect).encloses(band.rect)
			expect(enclosed and band.side!=door.side,"wall stays inside own building and omits door")
			if not enclosed: metrics.occluding_walls += 1
			for other in state.buildings:
				if other.id==row.id: continue
				var occludes: bool = band.rect.intersects(Rect2(other.rect))
				expect(not occludes,"wall does not cover another building")
				if occludes: metrics.occluding_walls += 1
		var linked := true
		for cell in door.front:
			if not reached.has(cell): linked = false
		expect(linked,"building door connected "+row.id)
		if linked: metrics.connected_doors += 1
		expect(Layout.candidates(row).size()==4 and door.cells.size()==2,"one width-two opening from four candidates")
		var points: Array = state.defense_points[row.id]
		expect(points.size()==int(row.capacity),"capacity dots "+row.id)
		metrics.defense_points += points.size()
		for point in points: expect(point.cell in door.front and roads.has(point.cell),"defense point on door-front road")
		if row.fixed: expect(rect.position==Layout.FIXED[row.id],"fixed location "+row.id)
	# Renderer bands are strictly inside their own nonoverlapping footprint;
	# they have zero height/extrusion, so cannot obscure another building.
	for index in range(state.buildings.size()):
		var row: Dictionary = state.buildings[index]
		for other in state.buildings.slice(index+1): expect(not row.rect.grow(1).intersects(other.rect),"one-cell building gap")

func direct_checks() -> void:
	for id in ["A","B","C"]:
		var state := Layout.build(Layout.preset(id,DataRegistry.rooms))
		expect(state.ok,"preset "+id+" "+str(state.errors))
		if state.ok: independent_checks(state)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13020261015
	var state := Layout.build(Layout.preset("A",DataRegistry.rooms))
	if not state.ok: return
	var unique: Dictionary = {}
	while accepted<200 and attempts<20000:
		attempts += 1
		var id: String = Layout.ROLES[rng.randi_range(0,Layout.ROLES.size()-1)]
		var origin := Vector2i(rng.randi_range(2,16),rng.randi_range(0,14))
		var next := Layout.move(state,id,origin)
		if not next.ok:
			rejected += 1
			continue
		var key := ""
		for row in next.buildings: key += str(row.rect.position)
		if unique.has(key): duplicates += 1; continue
		unique[key] = true
		state = next
		independent_checks(state)
		accepted += 1
		if accepted%25==0: print("RANDOM accepted=",accepted," attempts=",attempts)
	expect(accepted==200,"200 distinct random accepted layouts")
	var before := state.duplicate(true)
	for id in Layout.FIXED: expect(not Layout.move(state,id,Vector2i(6,6)).ok,"reject fixed move "+id)
	var blocked := Layout.move(Layout.build(Layout.preset("A",DataRegistry.rooms)),"barracks",Vector2i(3,7))
	expect(not blocked.ok and str(blocked.errors).contains("approach"),"reject blocked entrance approach")
	expect(not Layout.move(state,"barracks",Vector2i(18,3)).ok,"reject outside plot")
	expect(state==before,"rejected moves preserve state")
	var rows := Layout.preset("A",DataRegistry.rooms)
	rows[7].role = "treasure"; rows[7].id = "treasure"; rows[7].capacity = Layout.CAPACITY.treasure; rows[7].aura = Layout.AURA.treasure
	var bait := Layout.build(rows)
	expect(bait.ok and bait.defense_points.get("treasure",[]).size()==2,"sixth facility bait capacity")
	# Corrupt otherwise valid data to ensure the validator actually rejects it.
	var corrupt := state.duplicate(true)
	corrupt.road_cells[Vector2i(17,15)] = true
	expect(not Layout.validate(corrupt).is_empty(),"validator rejects orphan / unowned tile")
	corrupt = state.duplicate(true)
	corrupt.defense_points.barracks = []
	expect(not Layout.validate(corrupt).is_empty(),"validator rejects wrong defense capacity")
	var decoration = preload("res://scripts/map_builder/PlotDecorationSession.gd").new()
	decoration.begin("banner")
	expect(not decoration.active(),"free decoration placement disabled")

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point; event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
	get_viewport().push_input(event,true)
	await settle(2)

func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point; event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(event,true)
	await settle(2)

func capture(label: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==Vector2i(1920,1080),"exact capture resolution "+label)
	expect(image.save_png(OUT+label+".png")==OK,"PNG "+label)
	var file := FileAccess.open(OUT+label+".txt",FileAccess.WRITE)
	var shown: Dictionary = view.preview if not view.preview.is_empty() and view.preview.ok else view.state
	file.store_string("Displayed state: "+("preview" if shown!=view.state else "committed")+"\n"+Layout.dump(shown,view.preview,view.dragging,view.drag_origin)); file.close()
	print("CAPTURE ",label)

func gui_checks() -> void:
	get_window().size = Vector2i(1920,1080)
	ProjectSettings.set_setting("debug/defense_layout_graybox",true)
	LanguageSettings.set_locale("ko",false)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false
	add_child(game)
	await settle(10)
	game.set_process(false)
	game.onboarding_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
	game.story_feature_enabled = false; game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
	game._set_screen("management",false)
	await settle(10)
	view = game.ui_layer.get_node_or_null("DefenseGrayboxManagement")
	expect(view!=null,"debug view mounted by real management screen")
	if view==null: return
	for id in ["A","B","C"]:
		var button: Button = view.get_child(["A","B","C"].find(id))
		await mouse(button.position+button.size/2,true)
		await mouse(button.position+button.size/2,false)
		expect(view.state.ok,"GUI preset "+id)
		expect(game.graph.layout.defense_layout==view.state,"renderer uses graph-owned runtime cells")
		await capture("graybox_"+id)
	view.load_preset("A")
	var start: Vector2 = view.center(Vector2i(4,3))
	await mouse(start,true)
	expect(view.dragging=="barracks","real mouse press begins drag")
	# Find a distinct accepted destination, avoiding fabricated previews.
	var destination := Vector2i.ZERO
	for x in range(2,16):
		for y in range(1,13):
			var cell := Vector2i(x,y)
			if cell!=Vector2i(4,3) and Layout.move(view.state,"barracks",cell).ok:
				destination = cell; break
		if destination!=Vector2i.ZERO: break
	await motion(view.center(destination))
	expect(not view.preview.is_empty() and view.preview.ok,"real drag produces connected preview and aura")
	await capture("graybox_drag")
	await mouse(view.center(destination),false)
	expect(view.dragging=="" and game.graph.layout.defense_layout==view.state,"real release applies graph state")
	view.load_preset("A")
	await mouse(start,true)
	await motion(view.center(Vector2i(3,7)))
	expect(not view.preview.is_empty() and not view.preview.ok,"real drag blocks main approach and shows rejection")
	await capture("graybox_reject")
	var before: Dictionary = view.state.duplicate(true)
	await mouse(view.center(Vector2i(3,7)),false)
	expect(view.state==before and view.dragging=="","rejected release preserves actual layout")
	await mouse(view.center(Vector2i(8,0)),true)
	expect(view.dragging=="","fixed throne cannot drag")
	await mouse(view.center(Vector2i(8,0)),false)
	await mouse(start,true)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE; escape.pressed = true
	get_viewport().push_input(escape,true)
	await settle(3)
	expect(view.dragging=="" and not game.pause_menu_open,"ESC cancels drag before global pause shortcut")
	var key := InputEventKey.new()
	key.keycode = KEY_C; key.pressed = true
	get_viewport().push_input(key,true)
	await settle(3)
	expect(view.selected_preset=="C","keyboard comparison preset")
	# Disabling the flag restores the actual standard management workspace.
	ProjectSettings.set_setting("debug/defense_layout_graybox",false)
	# Command-line switch is absent in this runner; only the setting is used.
	game._set_screen("management",false)
	await settle(6)
	expect(game.ui_layer.get_node_or_null("DefenseGrayboxManagement")==null,"flag off restores standard management")
	expect(game.ui_layer.get_node_or_null("ResourceStatusRail")!=null,"standard management status rail restored")
	game.campaign_autosave_pending = false
	game._shutdown_audio_for_exit()
	game.queue_free()
	await settle(4)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	if OS.get_cmdline_user_args().has("--capture"):
		await gui_checks()
	else:
		direct_checks()
		expect(accepted==200,"direct suite reached 200 random layouts")
	expect(checks>0,"suite executed checks")
	var summary := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"random_seed":13020261015,"random_accepted":accepted,"random_rejected":rejected,"random_attempts":attempts,"duplicate_valid_states":duplicates,"metrics":metrics}
	var file := FileAccess.open(OUT+("gui_result.json" if OS.get_cmdline_user_args().has("--capture") else "random_result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(summary,"\t")); file.close()
	print("V130RDefenseLayoutTest ",summary)
	get_tree().quit(0 if failures.is_empty() else 1)
