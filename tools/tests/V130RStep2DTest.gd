extends "res://tools/tests/V130RStep2CTest.gd"
const OUTPUT := "res://tmp/v130r_step2d/"
var capture_size := Vector2i(1920,1080)

func key(code: Key) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = true
	get_viewport().push_input(event,true); await settle()

func check_outline() -> void:
	var visible := Rect2(view.camera_center-view.size/2/view.camera_scale,view.size/view.camera_scale).intersection(view.MINIMAP_BOUNDS)
	var position: Vector2 = (visible.position-view.MINIMAP_BOUNDS.position)/view.MINIMAP_BOUNDS.size*view.mini_picture.size
	var dimensions: Vector2 = visible.size/view.MINIMAP_BOUNDS.size*view.mini_picture.size
	expect(view.mini_outline.position.distance_to(position)<.01,"minimap position follows camera")
	expect(view.mini_outline.size.distance_to(dimensions)<.01,"minimap size follows zoom")

func check_fonts(node: Node) -> void:
	if node is Label:
		var font: Font = node.get_theme_font("font")
		expect(font==view.TITLE_FONT or font==view.BODY_FONT,"MapleStory font: "+node.text)
		var bounds: Rect2 = node.get_global_rect()
		if node.is_visible_in_tree():
			expect(Rect2(Vector2.ZERO,view.size).encloses(bounds),"label inside screen: "+node.text)
			if view.info.is_ancestor_of(node):
				var panel := Rect2(view.info.global_position,Vector2(360,268)*view.ui_unit)
				expect(panel.encloses(bounds),"label inside information frame: "+node.text)
		if node.text in ["건설","몬스터 배치","전투","미니맵","정보","강화","이동","해체","수비"] or node.get_parent().name=="BuildBar" and node.text in Model.NAMES.values():
			expect(font==view.TITLE_FONT,"title uses Bold: "+node.text)
		if node.name.ends_with("Number") or node.text.begins_with("영향 범위") or node.text.begins_with("수비 정원"):
			expect(font==view.BODY_FONT,"body uses Light: "+node.text)
	for child in node.get_children(): check_fonts(child)

func screenshot(name: String) -> void:
	await settle(); await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==capture_size,"actual viewport dimensions "+name)
	expect(image.save_png(OUTPUT+name+".png")==OK,"capture saved "+name)

func resize_to(dimensions: Vector2i) -> void:
	get_window().size = dimensions; capture_size = dimensions; await settle()
	view.clear_context(); view.show_default(); await settle()

func camera_check(dimensions: Vector2i) -> void:
	await resize_to(dimensions)
	var ratio := minf(dimensions.x/1920.0,dimensions.y/1080.0)
	expect(view.camera_center.distance_to(Vector2(1930,1390))<.01,"reference center "+str(dimensions))
	expect(absf(view.camera_scale-.75*ratio)<.0001,"proportional reference zoom "+str(dimensions))
	check_outline(); check_fonts(view.chrome)
	metrics[str(dimensions)] = {"zoom":view.camera_scale,"center":[view.camera_center.x,view.camera_center.y],"world_visible":[view.size.x/view.camera_scale,view.size.y/view.camera_scale]}

func exercise(capture: bool) -> void:
	for dimensions in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(2560,1440),Vector2i(1920,1200),Vector2i(1280,800),Vector2i(2560,1600)]:
		await camera_check(dimensions)
		if capture and dimensions==Vector2i(1920,1080): await screenshot("start_1920")
		if capture and dimensions==Vector2i(1280,720): await screenshot("start_1280")
	await resize_to(Vector2i(1920,1080))
	view.set_camera(Vector2(1600,1200),1.1); await key(KEY_2)
	expect(view.camera_center.distance_to(Vector2(1930,1390))<.01 and absf(view.camera_scale-.75)<.0001,"actual key 2 restores reference")
	check_outline(); await key(KEY_F)
	expect(view.camera_scale<.75,"actual F shows full map"); check_outline()
	await key(KEY_2); check_outline()
	var point: Vector2 = view.mini_picture.get_global_rect().position+view.mini_picture.get_global_rect().size*Vector2(.7,.45)
	await click(point); expect(view.camera_center.distance_to(Vector2(1930,1390))>50,"actual minimap click moves camera"); check_outline()
	await key(KEY_2)
	if capture: await screenshot("font_bar")
	for b in view.placement.buildings:
		view.clear_context(); view.show_default(); view.select_building(b.id); await settle()
		for mode in ["menu_info","menu_upgrade","menu_dismantle_refund"]:
			view.show_info(mode); await settle(); check_context(b.id+mode); check_fonts(view.chrome)
	view.clear_context(); view.show_default(); view.select_building("barracks"); await settle()
	await click(view.radial.get_node("menu_upgrade").get_global_rect().get_center())
	expect(view.panel_mode=="menu_upgrade","actual upgrade opens info")
	check_fonts(view.chrome); check_outline()
	if capture: await screenshot("font_info")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var previous := FileAccess.get_file_as_bytes(Model.SAVE_PATH) if FileAccess.file_exists(Model.SAVE_PATH) else PackedByteArray()
	var preview: Node = load("res://scenes/map_builder/ApprovedPlacementPreview.tscn").instantiate()
	add_child(preview); await settle()
	var game: Node = preview.game
	view = game.ui_layer.get_node("ApprovedMapManagement")
	view.placement = view.baseline.duplicate(true); view.render_map(); view.update_wallet()
	var capture := OS.get_cmdline_user_args().has("--capture")
	await exercise(capture)
	expect(previous==(FileAccess.get_file_as_bytes(Model.SAVE_PATH) if FileAccess.file_exists(Model.SAVE_PATH) else PackedByteArray()),"test layout bytes unchanged")
	game.campaign_save_enabled = false; game.campaign_autosave_pending = false; game._shutdown_audio_for_exit()
	preview.queue_free(); await get_tree().process_frame
	var mode := "capture" if capture else "direct"
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}
	write_json(OUTPUT+mode+"_result.json",result); write_json(OUTPUT+mode+"_metrics.json",metrics)
	print("V130RStep2DTest ",result)
	get_tree().quit(0 if failures.is_empty() else 1)
