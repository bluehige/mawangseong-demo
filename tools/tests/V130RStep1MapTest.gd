extends Node
const Layout = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const OUT := "res://tmp/v130r_step1/"
var failures: Array[String] = []
var checks := 0
var preview: Node
var game: Node
var view: Control
var capture_out := ""

func _ready() -> void: call_deferred("run")
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL ",label)
func settle(count: int = 5) -> void:
	for i in range(count): await get_tree().process_frame
func write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t"));file.close()

func geometry() -> void:
	var data := Layout.read()
	expect(data.size==[32.0,18.0] and data.grade=="E","approved E dimensions")
	expect(data.buildings.size()==8,"3 fixed and 5 buildings")
	var fixed := 0
	for b in data.buildings:
		if b.fixed: fixed += 1
		if b.code=="E": continue
		expect(b.arch==("up" if b.door in ["N","S"] else "down"),"directional arch "+b.id)
		for c in b.door_outside: expect("=XmB".contains(data.rows[int(c[1])][int(c[0])]),"two-cell door connection")
	expect(fixed==3 and data.bridges.size()==3,"fixed count and internal bridges")
	expect(Layout.cells(data,"m").size()==18 and data.monsters.size()==18,"all 18 plan defenders")
	for c in Layout.cells(data,"m"):
		var count := 0
		for node in data.draw_list:
			if node.asset.begins_with("monsters/") and node.cell==[float(c.x),float(c.y)]:
				count += 1
				expect(node.facing=="down","native down sprite")
		expect(count==1,"exactly one sprite per m cell")
	for y in range(19):
		for x in range(33):
			var cell := Vector2(x,y)
			expect(Layout.unproject(Layout.project(cell)).distance_to(cell)<0.001,"projection round trip")
	expect(Layout.project(Vector2(32,0)).y<Layout.project(Vector2(0,0)).y,"throne corner top")
	expect(Layout.TILE*Layout.DEFAULT_SCALE==Vector2(96,48),"default displayed cell 96x48")
	var previous_depth := -INF
	for n in data.draw_list:
		var rec: Dictionary = data.assets[n.asset]
		for axis in range(2): expect(absf(n.position[axis]+n.pivot[axis]-n.anchor[axis])<=0.501,"rounded reference pivot")
		expect(FileAccess.file_exists(Layout.ART+n.asset),"image exists "+n.asset)
		if n.layer=="objects":
			expect(n.depth>=previous_depth,"stable foot depth order")
			previous_depth = n.depth
		if n.asset.begins_with("monsters/"):
			expect(rec.size[0]<=128 and rec.size[1]<=96,"one-cell character footprint")
	expect(data.draw_list[-1].asset=="bridge/entrance_bridge.png","v7d exterior bridge overlap")
	expect(not preload("res://scripts/map_builder/PlotDecorationSession.gd").ENABLED,"procedural decorations disabled")

func spawn() -> void:
	preview = load("res://scenes/map_builder/ApprovedMapPreview.tscn").instantiate()
	add_child(preview)
	await settle(10)
	game = preview.game
	view = game.ui_layer.get_node_or_null("ApprovedMapManagement")
	expect(game.current_screen=="management" and view!=null,"actual GameRoot management")
	expect(not game.campaign_save_enabled,"preview does not use campaign saves")

func input_button(point: Vector2, button: MouseButton, pressed: bool, shift: bool = false, ctrl: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.position = point; event.global_position = point
	event.button_index = button; event.pressed = pressed
	event.shift_pressed = shift;event.ctrl_pressed = ctrl
	get_viewport().push_input(event,true)
	await settle(2)

func camera_inputs() -> void:
	expect(view.camera_scale==0.75,"starts at default zoom")
	var before: Vector2 = view.camera_center
	await input_button(Vector2(960,540),MOUSE_BUTTON_LEFT,true)
	var event := InputEventMouseMotion.new()
	event.position = Vector2(1080,600);event.global_position = event.position
	event.relative = Vector2(120,60);event.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(event,true)
	await settle(2)
	await input_button(event.position,MOUSE_BUTTON_LEFT,false)
	expect(view.camera_center.distance_to(before-Vector2(160,80))<0.01,"real pointer drag pans camera")
	var layout_before := JSON.stringify(game._plot_save_state())
	await input_button(Vector2(960,540),MOUSE_BUTTON_WHEEL_UP,true)
	expect(view.camera_scale>0.75,"wheel zoom")
	before = view.camera_center
	await input_button(Vector2(960,540),MOUSE_BUTTON_WHEEL_DOWN,true,true)
	expect(view.camera_center.x>before.x,"shift wheel horizontal pan")
	before = view.camera_center
	await input_button(Vector2(960,540),MOUSE_BUTTON_WHEEL_DOWN,true,false,true)
	expect(view.camera_center.y>before.y,"ctrl wheel vertical pan")
	for point in [Vector2(-100000,-100000),Vector2(100000,100000)]:
		view.set_camera(point,0.75)
		var half: Vector2 = view.size/2.0/view.camera_scale
		expect(view.camera_center.x-half.x>=view.CAMERA_BOUNDS.position.x-0.01,"left camera clamp")
		expect(view.camera_center.y-half.y>=view.CAMERA_BOUNDS.position.y-0.01,"top camera clamp")
		expect(view.camera_center.x+half.x<=view.CAMERA_BOUNDS.end.x+0.01,"right camera clamp")
		expect(view.camera_center.y+half.y<=view.CAMERA_BOUNDS.end.y+0.01,"bottom camera clamp")
	expect(layout_before==JSON.stringify(game._plot_save_state()),"camera input never moves/saves buildings")
	await input_button(Vector2(1742,38),MOUSE_BUTTON_LEFT,true)
	await input_button(Vector2(1742,38),MOUSE_BUTTON_LEFT,false)
	expect(view.camera_scale==0.75,"actual default zoom button")
	var menu: Control = game.ui_layer.find_child("CommonGameMenuButton",true,false)
	var zoom: Control = view.find_child("DefaultZoomButton",true,false)
	expect(menu!=null and not zoom.get_global_rect().intersects(menu.get_global_rect()),"zoom control does not overlap game menu")

func capture(label: String) -> void:
	await settle(8)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==Vector2i(1920,1080),"1920x1080 "+label)
	expect(image.save_png(capture_out+label+".png")==OK,"PNG saved "+label)
	print("CAPTURE ",label," center=",view.camera_center," scale=",view.camera_scale)

func save_compatibility() -> void:
	for label in ["legacy_v5","plot_v6"]:
		var folder: String = OUT+"copies/"+label+"/"
		var source: String = folder+"campaign_save_"+("v5" if label=="legacy_v5" else "v6")+".json"
		expect(FileAccess.file_exists(source),"existing copied save "+label)
		game._set_campaign_save_path_for_tests(folder+"campaign_save_v1.json",folder+"campaign_save_v2.json",folder+"campaign_save_v3.json",folder+"campaign_save_v4.json",folder+"campaign_save_v5.json",folder+"campaign_save_v6.json")
		expect(game.campaign_save_status=="valid","load existing save "+label+": "+game.campaign_save_error)
		if game.campaign_save_status!="valid": continue
		game._continue_campaign_save()
		await settle(8)
		expect(game.current_screen=="management","Continue management "+label)
		expect(game.ui_layer.get_node_or_null("ApprovedMapManagement")!=null,"art view after Continue "+label)
		expect(game.graph.validation_summary().ok,"legacy graph remains valid "+label)
		var saved: String = JSON.stringify(game._plot_save_state())
		expect(not saved.contains("approved_map_step1") and not saved.contains("approved_v7d_E"),"presentation is not serialized "+label)
		game.campaign_save_enabled = false
		game.campaign_autosave_pending = false
	# Turning the flag off restores the original campaign management view.
	ProjectSettings.set_setting("debug/approved_map_step1",false)
	game._set_screen("management",false)
	await settle()
	expect(game.ui_layer.get_node_or_null("ApprovedMapManagement")==null,"flag off restores existing screen")
	game._shutdown_audio_for_exit()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	geometry()
	var graphical := OS.get_cmdline_user_args().has("--capture")
	if graphical:
		get_window().size = Vector2i(1920,1080)
		capture_out = OS.get_environment("MAWANG_STEP1_CAPTURE_DIR").replace("\\","/").trim_suffix("/")+"/"
		expect(capture_out!="/","capture output directory provided")
	await spawn()
	if view!=null:
		if graphical:
			await camera_inputs()
			view.show_full()
			await capture("game_full")
			view.show_default()
			await capture("game_zoom2x")
			# Exact mockup comparison companion: same live viewport, UI hidden only.
			view.show_full();view.chrome.visible = false
			game.ui_layer.find_child("CommonGameMenuButton",true,false).hide()
			await capture("game_full_art_only")
		await save_compatibility()
	preview.queue_free()
	await settle(4)
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"capture":graphical}
	write_json(OUT+("gui_result.json" if graphical else "direct_result.json"),result)
	print("V130RStep1MapTest ",result)
	get_tree().quit(0 if failures.is_empty() else 1)
