extends Node
# Presentation only: never writes unit paths, targets, speed or combat state.
var root: Node
var automatic := true
var manual_seconds := 0.0
var tracked: WeakRef
var pointer := -1
var mode_touch_index := -1
var press := Vector2.ZERO
var last := Vector2.ZERO
var dragging := false
var suppress_mouse_until := 0
var previous_hp: Dictionary = {}
var interest: Dictionary = {}
var minimap: Control
var mode_button: Button
var world_bounds := Rect2()
var physical_scale := 1.0
var auto_preference := true

func setup(game: Node) -> void:
	root = game

func reset() -> void:
	tracked = null; pointer = -1; mode_touch_index=-1; dragging = false; manual_seconds = 0
	automatic = UISettings.spectator_auto_camera
	auto_preference = automatic
	previous_hp.clear(); interest.clear()
	world_bounds = Rect2()
	var first := true
	for cell in root.graph.debug_active_cells():
		var rect: Rect2 = root.graph.tile_cell_rect(cell)
		world_bounds = rect if first else world_bounds.merge(rect)
		first = false
	# Maintain readable bodies at both supported window sizes.
	root.combat_view_zoom = default_zoom()
	physical_scale = root.get_viewport().get_stretch_transform().get_scale().y
	root.combat_camera.zoom = Vector2.ONE * root.combat_view_zoom
	root.combat_camera.position = root.graph.center("entrance")

func default_zoom() -> float:
	var physical_scale := root.get_viewport().get_stretch_transform().get_scale().y
	return 1.35 / maxf(0.5, physical_scale)

func manual() -> void:
	automatic = false; manual_seconds = 0; tracked = null

func focus(point: Vector2) -> void:
	manual()
	root.combat_camera.position = clamp_point(point)
	root.queue_world_overlay_redraw()

func follow(unit: Node) -> void:
	tracked = weakref(unit); automatic = true; manual_seconds = 0

func toggle() -> void:
	automatic = not automatic; tracked = null; manual_seconds = 0
	UISettings.set_spectator_auto_camera(automatic)
	auto_preference=automatic

func clamp_point(point: Vector2) -> Vector2:
	var bounds: Rect2 = world_bounds.grow(40)
	return Vector2(clampf(point.x,bounds.position.x,bounds.end.x),clampf(point.y,bounds.position.y,bounds.end.y))

func _process(delta: float) -> void:
	if root == null or root.current_screen != "combat":
		pointer = -1; mode_touch_index=-1; dragging = false
		return
	if auto_preference != UISettings.spectator_auto_camera:
		auto_preference=UISettings.spectator_auto_camera
		automatic=auto_preference; tracked=null; manual_seconds=0
	var next_scale: float=root.get_viewport().get_stretch_transform().get_scale().y
	if not is_equal_approx(physical_scale,next_scale):
		root.combat_view_zoom *= maxf(0.5,physical_scale)/maxf(0.5,next_scale)
		root.combat_camera.zoom=Vector2.ONE*root.combat_view_zoom
		physical_scale=next_scale
	if root.pause_menu_open or root.story_combat_overlay_open or root.combat_scene.skill_actions.is_active():
		pointer=-1; mode_touch_index=-1; dragging=false
		return
	if not automatic:
		if pointer == -1: manual_seconds += delta
		if UISettings.spectator_auto_camera and manual_seconds >= 5.0: automatic = true
	var best := -1.0
	var target: Vector2 = root.graph.center("entrance")
	var live: Dictionary = {}
	for unit in root.monster_units + root.enemy_units:
		if not is_instance_valid(unit) or not unit.is_alive(): continue
		var id: int = unit.get_instance_id()
		live[id] = true
		var damage := maxf(0,float(previous_hp.get(id,unit.hp))-unit.hp)
		previous_hp[id] = unit.hp
		interest[id] = maxf(0,float(interest.get(id,0))-delta*12)+damage
		var score := float(interest[id]) + (35 if unit.attack_anim_timer > 0 else 0) + (60 if unit.skill_anim_timer > 0 else 0)
		if unit.faction == "enemy": score += 25 + maxf(0,100-unit.global_position.distance_to(root.graph.center("throne")))*0.5
		if score > best: best = score; target = unit.global_position
	for id in previous_hp.keys():
		if not live.has(id): previous_hp.erase(id); interest.erase(id)
	if tracked != null:
		var unit = tracked.get_ref()
		if is_instance_valid(unit) and unit.is_alive(): target = unit.global_position
		else: tracked = null
	if automatic:
		root.combat_camera.position = root.combat_camera.position.lerp(clamp_point(target+Vector2(0,-20)),1-exp(-delta*3))
		root.queue_world_overlay_redraw()
	if is_instance_valid(minimap): minimap.queue_redraw()
	if is_instance_valid(mode_button):
		mode_button.text = root.continuity.localized("자동" if automatic else "수동","Auto" if automatic else "Manual","自动" if automatic else "手动")

func handle_input(event: InputEvent) -> bool:
	if root.current_screen != "combat" or root.pause_menu_open or root.story_combat_overlay_open: return false
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		var over_mode: bool=is_instance_valid(mode_button) and mode_button.get_global_rect().has_point(event.position)
		if event.device==InputEvent.DEVICE_ID_EMULATION and Time.get_ticks_msec()<suppress_mouse_until and (over_mode or not root._combat_ui_at(event.position)): return true
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		suppress_mouse_until = Time.get_ticks_msec()+400
	if event is InputEventScreenTouch:
		if mode_touch_index!=-1:
			if event.index!=mode_touch_index: return true
			if not event.pressed:
				mode_touch_index=-1
				if not event.canceled and is_instance_valid(mode_button) and mode_button.get_global_rect().has_point(event.position): mode_button.pressed.emit()
			return true
		if event.pressed and pointer==-1 and is_instance_valid(mode_button) and mode_button.get_global_rect().has_point(event.position):
			mode_touch_index=event.index
			return true
	if event is InputEventScreenDrag and mode_touch_index!=-1: return true
	if root.combat_scene.pending_v122_command_id != "": return false
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		if root._combat_ui_at(event.position): return false
		manual(); root._adjust_combat_zoom(1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1,event.position)
		return true
	var down: bool = event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE])
	if down:
		var id: int = event.index if event is InputEventScreenTouch else -2
		if event.pressed:
			if pointer != -1: return true
			if root._combat_ui_at(event.position): return false
			pointer = id; press = event.position; last = press; dragging = false
			return true
		if id != pointer: return false
		pointer = -1
		if event is InputEventScreenTouch and event.canceled:
			dragging=false
			return true
		if not dragging:
			var world: Vector2 = root._combat_screen_to_world(event.position)
			if event is InputEventScreenTouch: root._handle_touch_combat_tap(world,event.position)
			else: root._handle_left_click(world,event.position)
		dragging = false
		return true
	if (event is InputEventScreenDrag and event.index == pointer) or (event is InputEventMouseMotion and pointer == -2):
		if event.position.distance_to(press) > 8: dragging = true
		if dragging:
			manual()
			root.combat_camera.position = clamp_point(root.combat_camera.position-(event.position-last)/root.combat_view_zoom)
			root.queue_world_overlay_redraw()
		last = event.position
		return true
	return false
