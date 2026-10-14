extends Node
const Game = preload("res://scenes/game/GameRoot.tscn")
var game: Node
var checks := 0
var failures: Array[String] = []
var out := "res://tmp/v130_m5"
var measurements: Array = []

func _ready() -> void: call_deferred("run")
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL: ",message)
func settle(count: int = 6) -> void:
	for i in range(count): await get_tree().process_frame
func control(id: String) -> Control: return game.ui_layer.find_child(id,true,false)
func send(event: InputEvent) -> void:
	get_viewport().push_input(event,true)
	await settle(2)
func tap(point: Vector2, touch: bool) -> void:
	if not touch:
		var motion := InputEventMouseMotion.new(); motion.position=point; motion.global_position=point
		await send(motion)
	for pressed in [true,false]:
		if touch:
			var e := InputEventScreenTouch.new(); e.position=point; e.pressed=pressed; e.index=0
			await send(e)
		else:
			var e := InputEventMouseButton.new(); e.position=point; e.global_position=point; e.button_index=MOUSE_BUTTON_LEFT; e.pressed=pressed
			await send(e)

func check_map(touch: bool) -> void:
	var director = game.spectator_camera
	var map = control("CombatMinimap")
	expect(map.cells.any(func(cell): return cell.room) and map.cells.any(func(cell): return not cell.room),"minimap distinguishes rooms and roads")
	var enemy = game.enemy_units[0]
	# Inject only observer history: actual enemy HP/stats remain untouched.
	director.tracked=null; director.automatic=true
	director.previous_hp[enemy.get_instance_id()]=enemy.hp+200
	game.combat_camera.position=enemy.global_position+Vector2(100,80)
	var battle_point: Vector2=enemy.global_position+Vector2(0,-20)
	var before_interest: float=game.combat_camera.position.distance_to(battle_point)
	director._process(0.2)
	expect(game.combat_camera.position.distance_to(battle_point)<before_interest and float(director.interest[enemy.get_instance_id()])>=200,"automatic director smoothly follows highest damage interest")
	expect(game.quarter_renderer.plot_silhouette.wall_count>0,"actual plot wall alpha/depth cache exists")
	for unit in game.monster_units+game.enemy_units:
		if is_instance_valid(unit): expect(unit.sprite.material is ShaderMaterial and bool(unit.sprite.material.get_shader_parameter("spectator_silhouette")),"actual plot unit uses silhouette shader")
	expect(map != null and map.cells.size()>50,"minimap room/road cells present")
	var world: Vector2 = game.graph.center("throne")
	var point: Vector2 = map.get_global_transform_with_canvas()*map.project(world)
	await tap(point,touch)
	expect(game.combat_camera.position.distance_to(world)<2,"minimap click/touch moves to actual throne")
	expect(not director.automatic,"minimap enters manual camera")
	# Continue in map space; no unit/path/stat mutation is involved.
	var start := Vector2(900,460)
	var before: Vector2 = game.combat_camera.position
	if touch:
		var e := InputEventScreenTouch.new(); e.index=0; e.position=start; e.pressed=true; await send(e)
		var other := InputEventScreenTouch.new(); other.index=1; other.position=start+Vector2(10,10); other.pressed=true; await send(other)
		var drag := InputEventScreenDrag.new(); drag.index=0; drag.position=start+Vector2(70,30); drag.relative=Vector2(70,30); await send(drag)
		e.pressed=false; e.position=drag.position; await send(e)
		other.pressed=false; await send(other)
	else:
		var e := InputEventMouseButton.new(); e.position=start; e.button_index=MOUSE_BUTTON_LEFT; e.pressed=true; await send(e)
		var drag := InputEventMouseMotion.new(); drag.position=start+Vector2(70,30); drag.relative=Vector2(70,30); drag.button_mask=MOUSE_BUTTON_MASK_LEFT; await send(drag)
		e.pressed=false; e.position=drag.position; await send(e)
	expect(game.combat_camera.position.distance_to(before)>5,"mouse/touch drag moves camera")
	expect(director.pointer==-1 and not director.dragging,"pointer release and second finger do not stick")
	director.manual_seconds=4.9; director._process(0.05)
	expect(not director.automatic,"no auto return before 5 seconds")
	director._process(0.1)
	expect(director.automatic,"auto return after 5 seconds")
	UISettings.set_spectator_auto_camera(false,false); director._process(0.1)
	expect(not director.automatic,"settings off stops an active automatic camera")
	director._process(6)
	expect(not director.automatic,"auto disabled keeps manual camera")
	UISettings.set_spectator_auto_camera(true,false)
	director._process(0.0)
	var settings_snapshot: Dictionary=UISettings.snapshot()
	UISettings.set_spectator_auto_camera(false,false); UISettings.apply_snapshot(settings_snapshot,false)
	expect(UISettings.spectator_auto_camera,"settings snapshot roundtrip preserves camera preference")
	if not touch:
		var zoom: float = game.combat_view_zoom
		var e := InputEventMouseButton.new(); e.position=start; e.button_index=MOUSE_BUTTON_WHEEL_UP; e.pressed=true; await send(e)
		expect(game.combat_view_zoom>zoom and not director.automatic,"mouse wheel zoom enters manual")
	director.manual()
	expect(not director.automatic,"mode button starts from manual fixture")
	var mode := control("CombatCameraMode")
	await tap(mode.get_global_transform_with_canvas()*(mode.size/2),touch)
	expect(director.automatic,"auto/manual button switches to automatic")
	if touch:
		for pressed in [true,false]:
			var emulated:=InputEventMouseButton.new(); emulated.device=InputEvent.DEVICE_ID_EMULATION
			emulated.position=mode.get_global_transform_with_canvas()*(mode.size/2); emulated.button_index=MOUSE_BUTTON_LEFT; emulated.pressed=pressed
			await send(emulated)
		expect(director.automatic,"native mode tap suppresses duplicate emulated mouse activation")
	# Persistent policy and command structure remains the U5-C contract.
	for id in ["CombatTacticsToggle","CombatRoomTacticsToggle","GLOBAL_DIRECTIVE_DEFEND","V122_COMMAND_FOCUS","V122_COMMAND_FALLBACK","CombatPause","CombatSpeed1x"]:
		expect(control(id)!=null and control(id).is_visible_in_tree(),"preserved HUD "+id)
	game._clear_combat_unit_selection(true); director.reset()
	await settle()

func measure(id: String, capture: bool) -> void:
	await settle(8)
	game.hud.update_combat_status()
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var stretch: Transform2D = get_viewport().get_stretch_transform()
	var top := control("CombatThroneStatus")
	var bar := control("CombatCommandBar")
	var top_rect: Rect2 = stretch*(top.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,top.size))
	var bar_rect: Rect2 = stretch*(bar.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,bar.size))
	var screen_height := view_size.y*stretch.get_scale().y
	var hud_height := top_rect.size.y+bar_rect.size.y
	expect(hud_height/screen_height<=0.12,"HUD persistent strips <=12 percent "+id)
	var speed_panel := control("CombatSpeedPanel")
	for button in game.hud.combat_workspace.speed_buttons.values()+[game.hud.combat_workspace.pause_button]:
		expect(speed_panel.get_global_rect().encloses(button.get_global_rect()),"all speed/pause buttons stay inside HUD "+id+" "+button.name)
	var bodies: Array = []
	for unit in game.monster_units+game.enemy_units:
		if not is_instance_valid(unit) or not unit.is_alive(): continue
		var sprite: AnimatedSprite2D = unit.sprite
		var tex := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
		var used: Rect2 = Rect2(tex.get_image().get_used_rect())
		var offset: Vector2 = sprite.offset-(tex.get_size()/2 if sprite.centered else Vector2.ZERO)
		var rect: Rect2 = stretch*(sprite.get_global_transform_with_canvas()*Rect2(used.position+offset,used.size))
		var logical_rect: Rect2 = sprite.get_global_transform_with_canvas()*Rect2(used.position+offset,used.size)
		if get_viewport().get_visible_rect().has_point(logical_rect.get_center()):
			bodies.append({"unit":unit.unit_id,"height_px":rect.size.y,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]})
			expect(rect.size.y>=64,"visible opaque unit body >=64px "+unit.unit_id+" "+id)
	expect(bodies.size()>=2,"at least two visible bodies measured "+id)
	measurements.append({"id":id,"resolution":[get_window().size.x,get_window().size.y],"zoom":game.combat_view_zoom,"hud_height_px":hud_height,"hud_percent":100*hud_height/screen_height,"top_px":top_rect.size.y,"bottom_px":bar_rect.size.y,"units":bodies})
	print("MEASUREMENT: ",JSON.stringify(measurements.back()))
	if capture and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(id+".png"))

func shader_check() -> void:
	# Real GPU fixture: a known foreground wall depth obscures a white actor.
	if DisplayServer.get_name()=="headless": return
	var viewport := SubViewport.new(); viewport.size=Vector2i(32,32); viewport.disable_3d=true; viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var image := Image.create(32,32,false,Image.FORMAT_RGBA8); image.fill(Color.WHITE)
	var sprite := Sprite2D.new(); sprite.texture=ImageTexture.create_from_image(image); sprite.centered=false
	var material := ShaderMaterial.new(); material.shader=preload("res://scripts/dungeon_quarter/prepared_maze_actor_depth.gdshader")
	material.set_shader_parameter("wall_depth",sprite.texture); material.set_shader_parameter("wall_size",Vector2(32,32)); material.set_shader_parameter("depth_range",Vector2(0,10)); material.set_shader_parameter("foot_depth",0)
	material.set_shader_parameter("reveal_occluded_body",true); material.set_shader_parameter("spectator_silhouette",true); material.set_shader_parameter("silhouette_color",Color("#78e1cfdb"))
	sprite.material=material; viewport.add_child(sprite)
	await settle(); await RenderingServer.frame_post_draw
	var pixel := viewport.get_texture().get_image().get_pixel(16,16)
	expect(pixel.g>pixel.r+0.1 and pixel.a>0.5,"GPU occluded body becomes allied silhouette")
	material.set_shader_parameter("foot_depth",20)
	await settle(); await RenderingServer.frame_post_draw
	pixel=viewport.get_texture().get_image().get_pixel(16,16)
	expect(pixel.r>0.95 and pixel.g>0.95,"GPU unoccluded body retains artwork")
	sprite.hide()
	var canvas := Node2D.new(); viewport.add_child(canvas)
	var style := preload("res://scripts/ui/ObsidianStyleBox.gd").new(); style.fill=Color.WHITE
	canvas.draw.connect(func():
		canvas.draw_style_box(style,Rect2(0,0,2,16))
		canvas.draw_style_box(style,Rect2(4,0,10,16))
		canvas.draw_style_box(style,Rect2(0,20,20,10)))
	canvas.queue_redraw(); await settle(); await RenderingServer.frame_post_draw
	var rendered := viewport.get_texture().get_image()
	for point in [Vector2i(1,8),Vector2i(8,8),Vector2i(8,24)]:
		expect(rendered.get_pixelv(point).r>0.95,"GPU thin style fill renders without invalid polygon "+str(point))
	viewport.queue_free()

func run() -> void:
	print("M5_START")
	var args := OS.get_cmdline_user_args()
	var capture := args.has("--capture")
	var touch := args.has("--mobile-touch-ui")
	for arg in args:
		if arg.begins_with("--output-dir="): out=arg.trim_prefix("--output-dir=")
	game=Game.instantiate(); game.campaign_save_enabled=false; game.campaign_auxiliary_save_enabled=false
	add_child(game); print("M5_GAME_READY"); await settle()
	game.onboarding_enabled=false; game.tutorial_gate_enabled=false; game.tutorial_manager.active=false
	game.story_feature_enabled=false; game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
	GameState.day=1; seed(1305); UISettings.set_spectator_auto_camera(true,false)
	print("M5_START_COMBAT"); game.combat_scene.start_combat(); print("M5_COMBAT_READY"); await settle(2)
	# Start the actual DAY1 battle and let the first enemies engage.
	while game.combat_time<3.5:
		if game.combat_scene.skill_actions.is_active(): game.combat_scene.skill_actions.skip()
		await get_tree().physics_frame
	game.combat_scene.set_pause_state(true,false); await settle()
	expect(game.current_screen=="combat" and game.enemy_units.size()>0,"real DAY1 combat has enemies")
	await shader_check()
	await check_map(touch)
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		get_window().size=resolution; await settle(8)
		print("RESIZE: requested=",resolution," actual=",get_window().size," zoom=",game.combat_view_zoom," default=",game.spectator_camera.default_zoom()," physical=",game.spectator_camera.physical_scale," stretch=",get_viewport().get_stretch_transform().get_scale())
		expect(is_equal_approx(game.combat_view_zoom,game.spectator_camera.default_zoom()),"window resize preserves physical default zoom")
		game.spectator_camera.reset()
		game.combat_camera.position=game.monster_units[0].global_position+Vector2(20,-15)
		game.spectator_camera.manual()
		await measure(("touch_" if touch else "mouse_")+str(resolution.x),capture)
	# Unit click is actual input and must select and track it.
	var unit = game.monster_units[0]
	await tap(game._combat_world_to_screen(unit.global_position),touch)
	expect(game.selected_unit==unit and game.spectator_camera.tracked!=null,"unit click/tap selects and follows")
	game.combat_camera.position+=Vector2(60,30)
	var distance_before: float=game.combat_camera.position.distance_to(unit.global_position+Vector2(0,-20))
	game.spectator_camera._process(0.2)
	expect(game.combat_camera.position.distance_to(unit.global_position+Vector2(0,-20))<distance_before,"tracked unit camera follows smoothly")
	game._clear_combat_unit_selection(false)
	var file := FileAccess.open(out.path_join("metrics_touch.json" if touch else "metrics_mouse.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"measurements":measurements},"\t")); file.close()
	print("V130SpectatorTest %s checks=%d touch=%s failures=%s"%["PASS" if failures.is_empty() else "FAIL",checks,touch,failures])
	game._shutdown_audio_for_exit(); await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failures.is_empty() else 1)
