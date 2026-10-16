extends Node
const Model = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Geometry = preload("res://scripts/map_builder/ApprovedPlacementLayout.gd")
const OUT := "res://tmp/v130r_step2c/"
var failures: Array[String] = []
var checks := 0
var view: Control
var metrics := {}

func _ready() -> void: call_deferred("run")
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL ",label)
func settle() -> void:
	await get_tree().create_timer(.4).timeout
	for i in range(3): await get_tree().process_frame
func packed(r: Rect2) -> Array:
	return [r.position.x,r.position.y,r.size.x,r.size.y]
func write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t")); file.close()
func check_context(label: String) -> void:
	expect(view.context_rects.size()==5,"five grouped actions "+label)
	if view.context_rects.size()!=5: return
	var center: Vector2 = view.context_center()
	var radius: float = view.context_radius()
	var angles := []
	var rects := []
	var screen := Rect2(Vector2.ZERO,view.size/view.ui_unit)
	var building: Rect2 = view.building_screen_rect(Model.building(view.placement,view.selected_id))
	expect(screen.encloses(building),"complete selected building onscreen "+label)
	for key in view.ui_rects: expect(not building.intersects(view.local_ui(key)),"selected building clear of "+key+" "+label)
	for i in range(5):
		var r: Rect2 = view.context_rects[i]; rects.append(packed(r))
		var delta := r.position+Vector2(40,40)-center
		expect(absf(delta.length()-radius)<.05,"one fixed radius "+label)
		angles.append(delta.angle())
		expect(screen.encloses(r),"action inside viewport "+label)
		for key in view.ui_rects: expect(not r.intersects(view.local_ui(key).grow(6)),"action clear of "+key+" "+label)
		for j in range(i): expect(not r.intersects(view.context_rects[j]),"action labels disjoint "+label)
	for i in range(1,5):
		expect(absf(fposmod(angles[i]-angles[i-1],TAU)-view.context_layout.step)<.001,"equal angular gaps "+label)
	expect(view.radial_backdrop.visible,"shared obsidian backing "+label)
	expect(view.selection_layer.get_child_count()>0,"selected building outlined "+label)
	var record := {"center":[center.x,center.y],"radius":radius,"step":view.context_layout.step,"rects":rects,"ui":{},"zoom":view.camera_scale}
	for key in view.ui_rects: record.ui[key] = packed(view.local_ui(key))
	if view.info.get_child_count()>0:
		expect(view.info.visible,"adjacent info visible "+label)
		var panel := Rect2(view.info.position,Vector2(360,268))
		expect(screen.encloses(panel),"info inside viewport "+label)
		for key in view.ui_rects: expect(not panel.intersects(view.local_ui(key).grow(6)),"info clear of "+key+" "+label)
		for r in view.context_rects: expect(not panel.intersects(r),"info clear of actions "+label)
		var nearest := center.clamp(panel.position,panel.end)
		expect(nearest.distance_to(center)<=radius+80,"info within radius plus margin "+label)
		expect(view.info.get_node_or_null("place_clear_all")==null,"no unexplained bottom icon "+label)
		expect(view.info.get_node("CloseInfo").position.y==18,"named close action in header "+label)
		record["panel"] = packed(panel)
	metrics[label] = record
func click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new(); event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		get_viewport().push_input(event,true)
		await get_tree().process_frame
	await settle()
func screenshot(name: String) -> void:
	await settle(); await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==Vector2i(1920,1080),"actual 1920x1080 "+name)
	expect(image.save_png(OUT+name+".png")==OK,"capture saved "+name)
func direct() -> void:
	for b in view.placement.buildings:
		view.clear_context(); view.show_default(); view.select_building(b.id); await settle()
		check_context(b.id)
		view.show_info("menu_info"); await settle(); check_context(b.id+" info")
	view.clear_context(); view.set_camera(Vector2(1600,1350),1.5)
	view.select_building("barracks"); view.show_info("menu_upgrade"); await settle(); check_context("close zoom")
	# Selection and panel closing must remove the complete shared decoration.
	view.clear_context()
	expect(view.context_rects.is_empty() and not view.radial_backdrop.visible,"clear removes backing and actions")
	expect(view.selection_layer.get_child_count()==0,"clear removes selected outline")
func gui() -> void:
	view.clear_context(); view.show_default()
	await click(view.screen_cell(Vector2(12.5,3.5)))
	expect(view.selected_id=="barracks","actual building click")
	check_context("radial_barracks"); await screenshot("radial_barracks")
	await click(view.radial.get_node("menu_upgrade").get_global_rect().get_center())
	expect(view.panel_mode=="menu_upgrade","actual upgrade click")
	check_context("info_upgrade"); await screenshot("info_upgrade")
	var texts := []
	for child in view.info.get_children():
		if child is Label: texts.append(child.text)
	expect(texts.any(func(t): return t.contains("Lv1 → Lv2")),"upgrade levels retained")
	expect(texts.any(func(t): return t.contains("4 → 5명")),"upgrade capacity retained")
	await click(view.radial.get_node("menu_dismantle_refund").get_global_rect().get_center())
	expect(view.panel_mode=="menu_dismantle_refund","actual dismantle click")
	check_context("info_dismantle"); await screenshot("info_dismantle")
	await click(view.info.get_node("CloseInfo").get_global_rect().get_center())
	expect(view.panel_mode=="" and view.info.get_child_count()==0,"actual header close")
	view.clear_context(); view.set_camera(Vector2(1930,1390),.75)
	var tower := Model.building(view.placement,"watchtower")
	var before: Vector2 = view.screen_cell(Vector2(tower.rect.position)+Vector2(tower.rect.size)/2)
	expect(before.x<260,"watchtower starts at left edge")
	view.select_building("watchtower"); await settle()
	check_context("radial_watchtower_edge"); await screenshot("radial_watchtower_edge")
	view.clear_context(); view.show_default()
	var ward := Model.building(view.placement,"ward_core")
	var ward_center: Vector2 = view.screen_cell(Vector2(ward.rect.position)+Vector2(ward.rect.size)/2)
	view.set_camera(view.camera_center+(ward_center-Vector2(1100,170))/view.camera_scale,view.camera_scale)
	expect(view.screen_cell(Vector2(ward.rect.position)+Vector2(ward.rect.size)/2).y<220,"ward starts beside top UI")
	view.select_building("ward_core"); await settle()
	check_context("radial_throne_near_ui"); await screenshot("radial_throne_near_ui")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var previous := FileAccess.get_file_as_bytes(Model.SAVE_PATH) if FileAccess.file_exists(Model.SAVE_PATH) else PackedByteArray()
	var preview: Node = load("res://scenes/map_builder/ApprovedPlacementPreview.tscn").instantiate()
	add_child(preview); await settle()
	get_window().size = Vector2i(1920,1080); await settle()
	var game: Node = preview.game
	view = game.ui_layer.get_node("ApprovedMapManagement")
	view.placement = view.baseline.duplicate(true); view.render_map(); view.update_wallet(); view.show_default()
	if OS.get_cmdline_user_args().has("--capture"): await gui()
	else: await direct()
	expect(previous==(FileAccess.get_file_as_bytes(Model.SAVE_PATH) if FileAccess.file_exists(Model.SAVE_PATH) else PackedByteArray()),"test layout bytes unchanged")
	game.campaign_save_enabled = false; game.campaign_autosave_pending = false; game._shutdown_audio_for_exit()
	preview.queue_free(); await get_tree().process_frame
	var mode := "capture" if OS.get_cmdline_user_args().has("--capture") else "direct"
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}
	write_json(OUT+mode+"_result.json",result); write_json(OUT+mode+"_metrics.json",metrics)
	print("V130RStep2CTest ",result)
	get_tree().quit(0 if failures.is_empty() else 1)
