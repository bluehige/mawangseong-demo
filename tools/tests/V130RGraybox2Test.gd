extends Node
const Layout = preload("res://scripts/map_builder/DefenseLayout.gd")
const OUT := "C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/graybox2/"
var failures: Array = []
var checks := 0
var game: Node
var view: Control
var metrics := {"accepted":0,"attempts":0,"rejected":0,"main_connections":0,"connected_doors":0,"road_fragments":0,"lava_buildings":0,"lava_roads":0,"branch_zone_violations":0,"monster_cells":0,"variants":{}}
func _ready() -> void: call_deferred("run")
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL ",message)
func settle(count: int = 6) -> void:
	for i in range(count): await get_tree().process_frame

func inspect(state: Dictionary) -> void:
	expect(state.ok,"valid state: "+str(state.errors))
	if not state.ok: return
	var visited: Dictionary = {}
	var queue: Array = [state.doors.entrance.front[0]]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		if visited.has(c) or not state.road_cells.has(c): continue
		visited[c] = true
		for delta in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]: queue.append(c+delta)
	expect(visited.size()==state.road_cells.size(),"independent all-road flood fill")
	if visited.size()!=state.road_cells.size(): metrics.road_fragments += 1
	var cfg := Layout.config(state.variant)
	for row in state.buildings:
		for x in range(row.rect.position.x,row.rect.end.x):
			for y in range(row.rect.position.y,row.rect.end.y):
				var c := Vector2i(x,y)
				var water: bool = state.lava.has(c) or state.bridges.has(c)
				expect(not water,"building off channel and bridge")
				if water: metrics.lava_buildings += 1
				var right_zone: bool = c.x<cfg.cuts[0] if row.zone=="first" else (c.x>=cfg.cuts[0]+2 and c.x<cfg.cuts[1]) if row.zone=="second" else (c.x>=cfg.cuts[1]+2 and c.y<cfg.split) if row.zone=="throne_court" else (c.x>=cfg.cuts[1]+2 and c.y>=cfg.split+2)
				expect(right_zone,"independent building zone")
		for c in state.doors[row.id].front: expect(visited.has(c),"door connected "+row.id)
		metrics.connected_doors += 1
		if row.id in ["throne","vault"]: metrics.main_connections += 1
	var used: Dictionary = {}
	for row in state.buildings:
		var points: Array = state.defense_points[row.id]
		expect(points.size()==row.capacity,"capacity "+row.id)
		for point in points:
			var c: Vector2i = point.cell
			expect(not used.has(c),"one monster per whole cell")
			used[c] = true
			expect(not state.lava.has(c) and not state.bridges.has(c),"monster off channel and bridge")
			for other in state.buildings: expect(not other.rect.has_point(c),"monster outside building")
			var adjacent: bool = state.road_cells.has(c)
			for delta in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
				if state.road_cells.has(c+delta): adjacent = true
			expect(adjacent,"monster on road or verge")
			metrics.monster_cells += 1
	for c in state.road_cells:
		expect(not state.lava.has(c),"road off lava")
		if state.lava.has(c): metrics.lava_roads += 1
		for row in state.buildings: expect(not row.rect.has_point(c),"road off building")
	for c in state.bridges: expect(visited.has(c),"every fixed bridge tile connected")
	for path in state.paths:
		if path.kind!="branch": continue
		var row: Dictionary = {}
		for building in state.buildings:
			if building.id==path.id: row = building
		for a in path.anchors:
			for d in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.ONE]:
				var c: Vector2i = a+d
				var valid: bool = Layout.zone(c,state.variant)==row.zone and not state.bridges.has(c)
				expect(valid,"branch remains inside same zone")
				if not valid: metrics.branch_zone_violations += 1

func direct() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 130220261015
	for variant in ["ga","na"]:
		var state := Layout.example(variant,DataRegistry.rooms)
		print("EXAMPLE ",variant," ok=",state.ok," placed=",state.buildings.size()," unavailable=",state.unavailable," errors=",state.errors)
		inspect(state)
		if not state.ok: continue
		if variant=="ga":
			# Exhaust all origins, not just the suggested example positions.
			for row in Layout.preset(variant,DataRegistry.rooms).slice(5):
				var fits := 0
				for x in range(state.plot.size.x):
					for y in range(state.plot.size.y):
						var candidate: Dictionary = row.duplicate(true)
						candidate.rect.position = Vector2i(x,y)
						if Layout.build(state.buildings+[candidate],variant).ok: fits += 1
				expect(fits==0,"exhaustive unavailable footprint "+row.id)
				print("EXHAUSTIVE ga ",row.id," origins=288 valid=",fits)
		var ids: Array = []
		for row in state.buildings:
			if not row.fixed: ids.append(row.id)
		var unique: Dictionary = {}
		var accepted := 0
		var attempts := 0
		while accepted<100 and attempts<12000:
			attempts += 1
			metrics.attempts += 1
			var id: String = ids[rng.randi_range(0,ids.size()-1)]
			var next := Layout.move(state,id,Vector2i(rng.randi_range(0,state.plot.size.x-1),rng.randi_range(0,state.plot.size.y-1)))
			if not next.ok: metrics.rejected += 1; continue
			var key := ""
			for row in next.buildings: key += str(row.rect.position)
			if unique.has(key): continue
			unique[key] = true
			state = next
			inspect(state)
			accepted += 1
			metrics.accepted += 1
			if accepted%25==0: print("RANDOM ",variant," ",accepted," attempts=",attempts)
		metrics.variants[variant] = {"accepted":accepted,"attempts":attempts}
		expect(accepted==100,"100 distinct random states "+variant)
		for id in Layout.FIXED: expect(not Layout.move(state,id,Vector2i.ZERO).ok,"fixed move rejected")
		var base := Layout.example(variant,DataRegistry.rooms)
		for pos in [Vector2i(cfg_cut(variant),4),Vector2i(cfg_cut(variant),Layout.config(variant).bridge_y[0]),Vector2i(Layout.config(variant).cuts[0]+2,4),Vector2i(-1,0)]:
			expect(not Layout.move(base,"spike_corridor",pos).ok,"reject lava bridge wrong-zone outside move")
		var bad := base.duplicate(true)
		bad.road_cells[bad.lava.keys()[0]] = true
		expect(not Layout.validate(bad).is_empty(),"validator detects injected lava road")
		bad = base.duplicate(true)
		bad.defense_points.spike_corridor[1] = bad.defense_points.spike_corridor[0]
		expect(not Layout.validate(bad).is_empty(),"validator detects overlapping monsters")
		bad = base.duplicate(true)
		bad.road_cells.erase(bad.bridges.keys()[0])
		expect(not Layout.validate(bad).is_empty(),"validator detects broken fixed bridge")
		bad = base.duplicate(true)
		for path in bad.paths:
			if path.kind=="branch": path.anchors.append(Vector2i(Layout.config(variant).cuts[0],0)); break
		expect(not Layout.validate(bad).is_empty(),"validator detects cross-zone branch")

func cfg_cut(variant: String) -> int: return Layout.config(variant).cuts[0]
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
	expect(image.get_size()==Vector2i(1920,1080),"1920x1080 "+label)
	expect(image.save_png(OUT+label+".png")==OK,"saved PNG "+label)
	var file := FileAccess.open(OUT+label+".txt",FileAccess.WRITE)
	file.store_string(Layout.dump(view.state))
	file.close()
	print("CAPTURE ",label)

func gui() -> void:
	get_window().size = Vector2i(1920,1080)
	ProjectSettings.set_setting("debug/defense_layout_graybox",true)
	LanguageSettings.set_locale("ko",false)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false
	add_child(game)
	await settle(10)
	game.set_process(false)
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.story_feature_enabled = false
	game.story_director.cancel_active_scene()
	game.onboarding_dialogue_queue.clear()
	game._set_screen("management",false)
	await settle(10)
	view = game.ui_layer.get_node_or_null("DefenseGrayboxManagement")
	expect(view!=null,"real management view")
	if view==null: return
	for i in range(2):
		var variant: String = ["ga","na"][i]
		var button: Button = view.get_child(i)
		await mouse(button.position+button.size/2,true)
		await mouse(button.position+button.size/2,false)
		expect(view.state.ok and view.selected_preset==variant,"actual comparison button "+variant)
		expect(game.graph.layout.defense_layout==view.state,"graph-owned management state")
		inspect(view.state)
		await capture("defense_"+variant)
	# Actual release must reject crossing the zone or covering the fixed bridge.
	var original: Dictionary = view.state.duplicate(true)
	await mouse(view.center(Vector2i(4,1)),true)
	await motion(view.center(Vector2i(10,8)))
	expect(view.dragging=="spike_corridor" and not view.preview.ok,"real bridge-blocking drag rejected")
	await mouse(view.center(Vector2i(10,8)),false)
	expect(view.state==original,"rejected drag preserves graph")
	await mouse(view.center(Vector2i(4,1)),true)
	await motion(view.center(Vector2i(4,2)))
	expect(view.preview.ok,"real same-zone move accepted")
	await mouse(view.center(Vector2i(4,2)),false)
	expect(view.state.buildings[3].rect.position==Vector2i(4,2),"real release applies position")
	expect(view.state==game.graph.layout.defense_layout,"release updates graph")
	ProjectSettings.set_setting("debug/defense_layout_graybox",false)
	game._set_screen("management",false)
	await settle(6)
	expect(game.ui_layer.get_node_or_null("DefenseGrayboxManagement")==null,"flag off restores normal management")
	game.campaign_autosave_pending = false
	game._shutdown_audio_for_exit()
	game.queue_free()
	await settle(4)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	if OS.get_cmdline_user_args().has("--capture"): await gui()
	else: direct()
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"seed":130220261015,"metrics":metrics}
	var file := FileAccess.open(OUT+("gui_result.json" if OS.get_cmdline_user_args().has("--capture") else "random_result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	print("V130RGraybox2Test ",result)
	get_tree().quit(0 if failures.is_empty() else 1)
