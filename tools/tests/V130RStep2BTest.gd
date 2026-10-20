extends Node
const Geometry = preload("res://scripts/map_builder/ApprovedPlacementLayout.gd")
const Model = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Layout = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const OUT := "res://tmp/v130r_step2b/"
const CAPTURE := "C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step2b/"
var failures: Array[String] = []
var checks := 0
var preview: Node
var game: Node
var view: Control
var metrics := {}
var capture_size := Vector2i(1920,1080)

func _ready() -> void: call_deferred("run")
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL ",label)
func settle(count: int = 5) -> void:
	for i in range(count): await get_tree().process_frame
func write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t")); file.close()
func pack_rect(r: Rect2) -> Array:
	return [r.position.x,r.position.y,r.size.x,r.size.y]
func transformed(r: Rect2, s: Dictionary) -> Rect2:
	return Rect2(r.position*s.zoom+s.offset,r.size*s.zoom)

func check_camera(screen: Vector2) -> void:
	var targets: Array[Rect2] = view.start_targets()
	var panels := Geometry.panels(screen)
	var solution := Geometry.solve(screen,targets,panels)
	expect(not solution.is_empty(),"camera feasible "+str(screen))
	if solution.is_empty(): return
	var rects := []
	for target in targets:
		var r := transformed(target,solution); rects.append(pack_rect(r))
		expect(Rect2(Vector2.ZERO,screen).encloses(r),"complete target inside "+str(screen))
		for key in panels: expect(not r.intersects(panels[key].grow(solution.margin-.01)),"target unobscured by "+key+str(screen))
	var obstacles: Array[Rect2] = []
	for r in panels.values(): obstacles.append(r.grow(solution.margin))
	expect(Geometry.translations(screen,targets,obstacles,solution.maximum+.0001,solution.margin).is_empty(),"larger zoom infeasible "+str(screen))
	var packed := {}
	for key in panels: packed[key] = pack_rect(panels[key])
	metrics[str(int(screen.x))+"x"+str(int(screen.y))] = {"zoom":solution.zoom,"maximum":solution.maximum,"center":[solution.center.x,solution.center.y],"offset":[solution.offset.x,solution.offset.y],"targets":rects,"ui":packed,"world_targets":targets.map(func(r): return pack_rect(r))}

func check_context(label: String) -> void:
	expect(view.context_rects.size()==5,"five visible actions "+label)
	var obstacles: Array[Rect2] = []
	for b in view.placement.buildings: obstacles.append(view.building_screen_rect(b))
	for key in view.ui_rects: obstacles.append(view.local_ui(key))
	if view.info.get_child_count()>0:
		expect(view.info.visible,"info has a free side "+label)
		var panel := Rect2(view.info.position,Vector2(360,268))
		for obstacle in obstacles: expect(not panel.intersects(obstacle),"info clear "+label)
		obstacles.append(panel)
	for i in range(view.context_rects.size()):
		var r: Rect2 = view.context_rects[i]
		expect(Rect2(Vector2.ZERO,view.size/view.ui_unit).encloses(r),"action onscreen "+label)
		for obstacle in obstacles: expect(not r.intersects(obstacle),"action no building/UI overlap "+label)
		for j in range(i): expect(not r.intersects(view.context_rects[j]),"actions disjoint "+label)

func direct() -> void:
	await resize_to(Vector2i(1920,1080))
	for screen in [Vector2(1920,1080),Vector2(1280,720),Vector2(2560,1440),Vector2(1920,1200),Vector2(1280,800),Vector2(2560,1600)]: check_camera(screen)
	expect(metrics["1920x1080"].zoom>.43,"start zoom improves on .43")
	for b in view.placement.buildings:
		view.select_building(b.id); check_context(b.id)
		view.show_info("menu_info"); check_context(b.id+" info")
		for child in view.info.get_children():
			if child is Label: expect(not child.text.contains("문 ") and not child.text.contains("×"),"no developer text")
	view.select_building("barracks"); view.show_info("menu_upgrade")
	var labels := []
	for child in view.info.get_children():
		if child is Label: labels.append(child.text)
	expect(labels.any(func(t): return t.contains("Lv1 → Lv2")),"upgrade level comparison")
	expect(labels.any(func(t): return t.contains("4 → 5명")),"upgrade capacity comparison from model")
	for screen in [Vector2i(1280,720),Vector2i(2560,1440),Vector2i(1920,1200)]:
		await resize_to(screen)
		view.select_building("barracks"); view.show_info("menu_upgrade"); check_context("responsive "+str(screen))
	await resize_to(Vector2i(1920,1080))
	view.set_camera(Vector2(1600,1350),1.5)
	view.select_building("barracks"); view.show_info("menu_upgrade"); check_context("close zoom fallback")
	view.clear_context()
	var initial: Dictionary = view.placement.resources.duplicate()
	view.placement.resources = {"gold":0,"mana":0,"food":0}; view.update_wallet()
	for kind in view.costs:
		var row: Control = view.costs[kind]
		for key in row.get_meta("values"):
			expect(row.get_node(key+"Number").modulate.g<.3,"unaffordable number red")
			expect(row.get_node(key+"Icon").modulate.r<.4,"unaffordable icon dark")
			expect(row.get_node(key+"Number").position.y==1,"cost single baseline")
	view.placement.resources = initial; view.update_wallet()
	write_json(OUT+"camera_metrics.json",metrics)

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new(); event.position = point; event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
	get_viewport().push_input(event,true); await settle(2)
func click(point: Vector2) -> void:
	await mouse(point,true); await mouse(point,false)
func button_click(parent: Node, name: String) -> void:
	var button: Control = parent.get_node(name)
	await click(button.get_global_rect().get_center())
func key(code: Key) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = true
	view.handle_key(event); await settle()
func capture(name: String) -> void:
	await settle(6); await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==capture_size,"actual capture size "+name+str(image.get_size()))
	expect(image.save_png(CAPTURE+name+".png")==OK,"save "+name)
	print("CAPTURE ",name)
func resize_to(dimensions: Vector2i) -> void:
	get_window().size = dimensions; capture_size = dimensions
	await settle(12)
	expect(Vector2(dimensions)==view.size,"workspace follows actual screen "+str(dimensions))
	view.show_default(); await settle()

func gui() -> void:
	for spec in [[Vector2i(1920,1080),"start_1920"],[Vector2i(1280,720),"start_1280"],[Vector2i(2560,1440),"start_2560"],[Vector2i(1920,1200),"start_16x10"]]:
		await resize_to(spec[0]); check_camera(Vector2(spec[0])); await capture(spec[1])
	await resize_to(Vector2i(1920,1080))
	await click(view.screen_cell(Vector2(12.5,3.5)))
	expect(view.selected_id=="barracks","actual building click")
	await button_click(view.radial,"menu_upgrade")
	expect(view.panel_mode=="menu_upgrade","actual upgrade icon click")
	check_context("upgrade screenshot"); await capture("info_upgrade")
	await button_click(view.radial,"menu_dismantle_refund")
	expect(view.panel_mode=="menu_dismantle_refund","actual dismantle icon click")
	check_context("refund screenshot"); await capture("info_dismantle")
	# Bring a real building near the left edge. Layout must turn actions inward.
	view.clear_context(); view.set_camera(Vector2(1930,1390),.75)
	view.select_building("watchtower"); check_context("left edge")
	await capture("radial_edge")
	var button: Control = view.radial.get_node("menu_info")
	var motion := InputEventMouseMotion.new(); motion.position = button.get_global_rect().get_center(); motion.global_position = motion.position
	get_viewport().push_input(motion,true); await settle()
	expect(button.modulate.r>1,"actual hover highlight")
	view.clear_context(); view.show_default()
	var resources: Dictionary = view.placement.resources.duplicate()
	view.placement.resources = {"gold":90,"mana":0,"food":0}; view.update_wallet()
	await capture("build_bar_cost")
	view.placement.resources = resources; view.update_wallet()
	# Exercise the relocated build bar without committing or changing any save.
	var build_button: Control = view.palette_buttons["watchtower"]
	await click(build_button.get_global_rect().get_center())
	expect(view.build_kind=="watchtower","actual relocated build icon selects facility")
	var ghost_motion := InputEventMouseMotion.new()
	ghost_motion.position = view.screen_cell(Vector2(3.5,.5)); ghost_motion.global_position = ghost_motion.position
	get_viewport().push_input(ghost_motion,true); await settle()
	expect(view.preview_layer.get_child_count()>0,"actual build pointer shows ghost")
	await key(KEY_ESCAPE)
	expect(view.build_kind=="","escape cancels build without saving")
	expect(view.status_text.text=="","cancel clears placement status")
	var old_center: Vector2 = view.camera_center
	var point: Vector2 = view.mini_picture.get_global_rect().position+view.mini_picture.get_global_rect().size*Vector2(.7,.45)
	await click(point)
	expect(view.camera_center.distance_to(old_center)>50,"actual minimap click pans")
	expect(view.selected_id=="" and view.build_kind=="","minimap click consumed")
	var visible := Rect2(view.camera_center-view.size/2/view.camera_scale,view.size/view.camera_scale).intersection(view.MINIMAP_BOUNDS)
	var expected_size: Vector2 = visible.size/view.MINIMAP_BOUNDS.size*view.mini_picture.size
	expect(view.mini_outline.size.distance_to(expected_size)<.01,"minimap viewport frame has correct size")
	await capture("minimap_click")
	await key(KEY_2)
	expect(view.camera_center.distance_to(view.start_solution.center)<.01 and absf(view.camera_scale-view.start_solution.zoom)<.0001,"2 restores calculated start")
	await key(KEY_F)
	expect(view.camera_scale<view.start_solution.zoom,"F fits entire map")
	write_json(OUT+"camera_metrics.json",metrics)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(CAPTURE)
	# Preserve any previous step-two test layout byte-for-byte. Never write it.
	var previous := FileAccess.get_file_as_bytes(Model.SAVE_PATH) if FileAccess.file_exists(Model.SAVE_PATH) else PackedByteArray()
	preview = load("res://scenes/map_builder/ApprovedPlacementPreview.tscn").instantiate()
	add_child(preview); await settle(10)
	game = preview.game; view = game.ui_layer.get_node_or_null("ApprovedMapManagement")
	expect(view!=null,"actual GameRoot placement workspace")
	if view!=null:
		view.placement = view.baseline.duplicate(true); view.render_map(); view.update_wallet(); view.show_default()
		if OS.get_cmdline_user_args().has("--capture"): await gui()
		else: await direct()
	expect(previous==(FileAccess.get_file_as_bytes(Model.SAVE_PATH) if FileAccess.file_exists(Model.SAVE_PATH) else PackedByteArray()),"step-two test save unchanged")
	game.campaign_save_enabled = false; game.campaign_autosave_pending = false; game._shutdown_audio_for_exit()
	preview.queue_free(); await settle()
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}
	var mode := "capture" if OS.get_cmdline_user_args().has("--capture") else "direct"
	write_json(OUT+mode+"_result.json",result); print("V130RStep2BTest ",result)
	get_tree().quit(0 if failures.is_empty() else 1)
