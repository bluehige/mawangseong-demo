extends Control
## Image pieces in the actual management CanvasLayer. No procedural art.
const Layout = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")
const CAMERA_BOUNDS := Rect2(-144, 135, 4000, 2319)
var root: Node
var state: Dictionary
var world: Node2D
var camera_center := Vector2(1984,1248)
var camera_scale := Layout.DEFAULT_SCALE
var dragging := false
var chrome: Control
var scale_label: Label
var textures: Dictionary = {}

func setup(game: Node) -> void:
	root = game
	name = "ApprovedMapManagement"
	size = Vector2(1920,1080)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	state = Layout.read()
	# Graph-owned presentation data is separate from campaign rooms and plot saves.
	root.graph.layout["approved_map_step1"] = state
	world = Node2D.new()
	world.name = "ApprovedImagePieces"
	add_child(world)
	var bg: Dictionary = state.background
	var background := image_node(str(bg.asset), Vector2(bg.position[0],bg.position[1]))
	background.scale = Vector2(bg.size[0],bg.size[1])/background.texture.get_size()
	background.name = "CaveBackground"
	for record in state.draw_list:
		var sprite := image_node(str(record.asset), Vector2(record.position[0],record.position[1]))
		sprite.set_meta("placement", record)
	build_chrome()
	set_camera(Vector2(state.default_camera.center[0],state.default_camera.center[1]), Layout.DEFAULT_SCALE)

func image_node(asset: String, point: Vector2) -> Sprite2D:
	if not textures.has(asset): textures[asset] = load(Layout.ART+asset)
	var sprite := Sprite2D.new()
	sprite.name = asset.replace("/","_").trim_suffix(".png")
	sprite.texture = textures[asset]
	sprite.centered = false
	sprite.position = point
	world.add_child(sprite)
	return sprite

func build_chrome() -> void:
	chrome = Control.new()
	chrome.name = "MapControls"
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chrome)
	var title := Label.new()
	title.position = Vector2(24,16)
	title.text = LanguageSettings.text("map.castle_management_grade_e_32_18_map_preview_1")
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_y", 2)
	chrome.add_child(title)
	for i in range(2):
		var button := Button.new()
		button.name = "FullMapButton" if i==0 else "DefaultZoomButton"
		button.text = LanguageSettings.text("map.full_map") if i==0 else LanguageSettings.text("map.default_2")
		button.position = Vector2(1520+i*152,16)
		button.size = Vector2(140,44)
		button.add_theme_font_override("font",FONT)
		button.add_theme_font_size_override("font_size",20)
		button.pressed.connect(show_full if i==0 else show_default)
		chrome.add_child(button)
	scale_label = Label.new()
	scale_label.position = Vector2(24,1034)
	scale_label.add_theme_font_override("font",FONT)
	scale_label.add_theme_font_size_override("font_size",18)
	scale_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	scale_label.add_theme_constant_override("shadow_offset_y", 2)
	chrome.add_child(scale_label)

func set_camera(center: Vector2, factor: float) -> void:
	camera_scale = clampf(factor, Layout.FULL_SCALE, 1.5)
	camera_center = center
	var half := size/2.0/camera_scale
	# Keep the viewport inside the painted cave/bridge extent at every zoom.
	for axis in range(2):
		var low: float = CAMERA_BOUNDS.position[axis]+half[axis]
		var high: float = CAMERA_BOUNDS.end[axis]-half[axis]
		camera_center[axis] = clampf(camera_center[axis],low,high) if low<=high else CAMERA_BOUNDS.get_center()[axis]
	world.scale = Vector2.ONE*camera_scale
	world.position = size/2.0-camera_center*camera_scale
	scale_label.text = LanguageSettings.text("map.drag_pan_wheel_zoom_shift_wheel_horizontal_ctrl_wheel_vertical_f_full_") % [roundi(128*camera_scale),roundi(64*camera_scale)]

func show_full() -> void:
	set_camera(Vector2(state.full_camera.center[0],state.full_camera.center[1]),Layout.FULL_SCALE)

func show_default() -> void:
	set_camera(Vector2(state.default_camera.center[0],state.default_camera.center[1]),Layout.DEFAULT_SCALE)

func zoom_at(point: Vector2, factor: float) -> void:
	var before := camera_center+(point-size/2.0)/camera_scale
	var next := clampf(camera_scale*factor,Layout.FULL_SCALE,1.5)
	set_camera(before-(point-size/2.0)/next,next)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE,MOUSE_BUTTON_RIGHT]:
			dragging = event.pressed
		elif event.pressed:
			var step := maxf(1.0,event.factor)*120.0/camera_scale
			if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
				var signum := -1.0 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0
				if event.shift_pressed: set_camera(camera_center+Vector2(signum*step,0),camera_scale)
				elif event.ctrl_pressed: set_camera(camera_center+Vector2(0,signum*step),camera_scale)
				else: zoom_at(event.position,1.15 if signum<0 else 1.0/1.15)
			elif event.button_index in [MOUSE_BUTTON_WHEEL_LEFT,MOUSE_BUTTON_WHEEL_RIGHT]:
				set_camera(camera_center+Vector2(-step if event.button_index==MOUSE_BUTTON_WHEEL_LEFT else step,0),camera_scale)
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		set_camera(camera_center-event.relative/camera_scale,camera_scale)
		accept_event()
	elif event is InputEventScreenDrag:
		set_camera(camera_center-event.relative/camera_scale,camera_scale)
		accept_event()
	elif event is InputEventScreenTouch:
		accept_event()
	elif event is InputEventMagnifyGesture:
		zoom_at(event.position,event.factor)
		accept_event()
	elif event is InputEventPanGesture:
		set_camera(camera_center+event.delta*40.0/camera_scale,camera_scale)
		accept_event()

func handle_key(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F: show_full(); return true
		if event.keycode==KEY_2: show_default(); return true
	return false
