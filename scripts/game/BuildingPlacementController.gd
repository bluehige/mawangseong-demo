extends RefCounted
# Pointer ownership only. GameRoot remains the authority for rules, resources and Undo.
const Constants = preload("res://scripts/core/Constants.gd")
const Preview = preload("res://scripts/ui/FacilityPreview.gd")
var root: Node
var pointer_active := false
var dragging := false
var press_position := Vector2.ZERO
var pointer_world := Vector2.ZERO
var hover_room := ""
var committing := false
var keyboard_index := -1
var ghost: Control
var panning := false
var pan_pointer := Vector2.ZERO
var workspace_bounds := Rect2()
var workspace_min_scale := 0.25
var plot = preload("res://scripts/map_builder/PlotPlacementSession.gd").new()
var decor = preload("res://scripts/map_builder/PlotDecorationSession.gd").new()
var touch_index := -1
var native_touch_button := ""
var native_touch_index := -1
var emulated_mouse_deadline := 0

func can_navigate() -> bool:
	return root.current_screen == Constants.SCREEN_MANAGEMENT and not root.map_editor_active and not root.pause_menu_open and not root._onboarding_screen_blocks_map_input() and not pointer_active and not root.build_pick_mode and not decor.active() and not root.roster_monster_drag_active and root.dragging_monster_id == "" and root.deploy_pick_monster_id == ""

func update_navigation_buttons() -> void:
	for id in ["FitManagementMapButton","ZoomInManagementMapButton","ZoomOutManagementMapButton"]:
		var button := root.ui_layer.find_child(id,true,false) as Button
		if button != null: button.disabled = not can_navigate() or panning

func end_navigation() -> void:
	panning = false
	pan_pointer = Vector2.ZERO
	if root != null and root.ui_layer != null:
		update_navigation_buttons()

func _workspace_safe_rect() -> Rect2:
	var size: Vector2 = root.get_viewport().get_visible_rect().size
	var expanded: bool = root.management_scene.workspace_ui.tools_expanded
	var top := 196.0 if expanded else 80.0
	var height := 590.0 if expanded else 874.0
	# Reserve the left detail popup before picking, so a card drag never jumps the map.
	var left := 680.0 if expanded and root.management_tool_tab == "build" else 36.0
	return Rect2(Vector2(left,top) * size / Vector2(1920,1080), Vector2(1828-left,height) * size / Vector2(1920,1080))

func _constrain_view(view: Transform2D) -> Transform2D:
	if not workspace_bounds.has_area():
		return view
	var safe := _workspace_safe_rect()
	var low := safe.end - workspace_bounds.end * view.x.length()
	var high := safe.position - workspace_bounds.position * view.x.length()
	view.origin.x = clampf(view.origin.x,minf(low.x,high.x),maxf(low.x,high.x))
	view.origin.y = clampf(view.origin.y,minf(low.y,high.y),maxf(low.y,high.y))
	return view

func zoom_workspace(step: int, viewport_point: Vector2 = Vector2.INF) -> bool:
	if not can_navigate() or panning or not managed_view:
		return false
	var point := _workspace_safe_rect().get_center() if viewport_point == Vector2.INF else viewport_point
	var view: Transform2D = root.get_viewport().canvas_transform
	var anchor := view.affine_inverse() * point
	var scale_value := clampf(view.x.length() * pow(1.18,step),workspace_min_scale,1.6)
	if is_equal_approx(scale_value,view.x.length()):
		return false
	view = Transform2D(Vector2(scale_value,0),Vector2(0,scale_value),point-anchor*scale_value)
	root.get_viewport().canvas_transform = _constrain_view(view)
	root.quarter_renderer.sync_management_backdrop()
	root.queue_world_overlay_redraw()
	root._tutorial_build_overlay()
	return true

func _navigation_input(event: InputEvent) -> bool:
	# Own the entire middle-button gesture, including release over the HUD.
	if panning:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
			end_navigation()
			return true
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			end_navigation()
			return true
		if not can_navigate():
			end_navigation()
			return false
		if event is InputEventMouseMotion:
			var view: Transform2D = root.get_viewport().canvas_transform
			view.origin += event.position - pan_pointer
			pan_pointer = event.position
			root.get_viewport().canvas_transform = _constrain_view(view)
			root.quarter_renderer.sync_management_backdrop()
			root.queue_world_overlay_redraw()
			root._tutorial_build_overlay()
			return true
		# A simultaneous left press must never select a room or start another drag.
		if event is InputEventMouseButton:
			return true
	if not can_navigate() or not event is InputEventMouseButton or not event.pressed:
		return false
	if root._management_ui_at(event.position):
		return false
	if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		zoom_workspace(1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1,event.position)
		return true
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		panning = true
		update_navigation_buttons()
		pan_pointer = event.position
		return true
	return false


func setup(game: Node) -> void:
	root = game
	plot.root = game
	decor.root = game

func ensure_ghost() -> void:
	if is_instance_valid(ghost):
		return
	ghost = Preview.new()
	ghost.name = "BuildingPlacementGhost"
	ghost.game = root
	ghost.world_preview = true
	ghost.z_index = -1
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.world_overlay_layer.add_child(ghost)

func visual_room() -> String:
	if root.build_preview_room_id != "":
		return root.build_preview_room_id
	if hover_room != "" and root._can_change_room_facility(hover_room):
		return hover_room
	if root.build_palette_target_room != "":
		return root.build_palette_target_room
	if root._can_change_room_facility(root.selected_room):
		return root.selected_room
	return root._first_changeable_room()

func viewport_to_world(point: Vector2) -> Vector2:
	return root.get_global_transform_with_canvas().affine_inverse() * point

func exact_room(point: Vector2) -> String:
	if root.graph == null or not root.graph.has_method("exact_room_at_world"):
		return ""
	return root.graph.exact_room_at_world(point)

func target_room(point: Vector2) -> String:
	# Build labels are drawn below the floor. Treat their visible rectangles as
	# candidate selectors, without snapping arbitrary off-map points to a room.
	if root.build_pick_mode and root.graph != null and not (pointer_active and dragging):
		var transform: Transform2D = root.get_global_transform_with_canvas()
		var screen_point := transform * point
		var labels := preload("res://scripts/map_builder/PlotBuildLabels.gd").layouts(root)
		for room_id in labels:
			if labels[room_id].rect.has_point(screen_point): return room_id
	return exact_room(point)

func card_input(event: InputEvent, facility_id: String, card: Control) -> void:
	if event is InputEventScreenTouch and event.pressed:
		begin(facility_id, card.get_global_transform_with_canvas() * event.position)
		touch_index = event.index
		emulated_mouse_deadline = Time.get_ticks_msec()+250
		card.accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		begin(facility_id, card.get_global_transform_with_canvas() * event.position)
		if pointer_active:
			root.hud.apply_button_state(card, "selected")
		card.accept_event()

func begin(facility_id: String, viewport_point: Vector2) -> void:
	if root.current_screen != Constants.SCREEN_MANAGEMENT or root.map_editor_active or root.pause_menu_open:
		return
	if not root._facility_unlocked(facility_id) or not GameState.can_pay(root._facility_definition(facility_id).get("cost", {})):
		return
	var target: String = root.build_palette_target_room
	root._clear_management_action_mode(false)
	root.build_palette_target_room = target
	root.build_pick_mode = true
	root.build_pick_facility_id = facility_id
	root.management_tool_tab = "build"
	root.management_context_drawer_open = false
	pointer_active = true
	press_position = viewport_point
	pointer_world = viewport_to_world(viewport_point)
	var start_button := root.ui_layer.find_child("StartCombatButton", true, false) as Button
	if start_button != null:
		start_button.disabled = true
	update_navigation_buttons()
	var feedback := root.ui_layer.find_child("PlacementFeedbackLabel", true, false) as Label
	if feedback != null:
		feedback.text = LanguageSettings.ui_text("클릭·드롭 즉시 설치 / ESC 취소")
	root.queue_world_overlay_redraw()
	root.call_deferred("_set_screen", Constants.SCREEN_MANAGEMENT, false)

func reset() -> void:
	end_navigation()
	plot.reset()
	decor.reset()
	touch_index = -1
	native_touch_button = ""
	native_touch_index = -1
	pointer_active = false
	dragging = false
	hover_room = ""
	keyboard_index = -1
	if is_instance_valid(ghost):
		ghost.visible = false

func update_pointer(viewport_point: Vector2) -> void:
	pointer_world = viewport_to_world(viewport_point)
	if pointer_active and viewport_point.distance_to(press_position) >= 8.0:
		dragging = true
	var next_room := "" if root._management_ui_at(viewport_point) else target_room(pointer_world)
	plot.update(pointer_world,root._management_ui_at(viewport_point))
	if hover_room != next_room:
		hover_room = next_room
		root.queue_world_overlay_redraw()
	root.management_scene.workspace_ui.refresh_preview()

func drop(viewport_point: Vector2) -> void:
	update_pointer(viewport_point)
	var was_dragging := dragging
	pointer_active = false
	dragging = false
	if not was_dragging:
		root._set_build_facility(root.build_pick_facility_id)
		return
	if plot.active():
		if not plot.commit():
			root._set_management_feedback(false,str(plot.preview.get("reason","")))
		return
	select_candidate(hover_room)

func select_candidate(room_id: String) -> void:
	root.build_preview_room_id = ""
	root.build_palette_target_room = ""
	var result: Dictionary = root._evaluate_facility_placement(room_id, root.build_pick_facility_id)
	if not bool(result.get("ok", false)):
		root.build_blocked_room_id = room_id
		root._set_management_feedback(false, str(result.get("reason", "건설할 수 없는 위치입니다.")), "다른 건설 구역을 고르거나 ESC로 취소하세요.")
	else:
		root._set_build_preview_target(room_id)
		root.management_scene.workspace_ui.refresh_preview()
		root._confirm_build_preview()
		return
	root._set_screen(Constants.SCREEN_MANAGEMENT)

func handle_input(event: InputEvent) -> bool:
	if _navigation_input(event):
		return true
	if root.current_screen != Constants.SCREEN_MANAGEMENT or root.map_editor_active or root.pause_menu_open:
		return false
	if decor.handle_input(event): return true
	# Godot uses device -1 for mouse events emulated from native touch.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION and Time.get_ticks_msec() < emulated_mouse_deadline: return true
	if event is InputEventScreenTouch:
		if not event.pressed and native_touch_button != "":
			if event.index != native_touch_index: return true
			var button := root.ui_layer.find_child(native_touch_button,true,false) as Button
			native_touch_button = ""
			native_touch_index = -1
			emulated_mouse_deadline = Time.get_ticks_msec()+250
			if not event.canceled and button != null and not button.disabled and button.is_visible_in_tree() and button.get_global_rect().has_point(event.position): button.pressed.emit()
			return true
		if event.pressed:
			for id in ["CancelBuildingButton","PlacementUndoButton","PlotPreviewRotateButton","PlotMoveButton","PlotRotateButton","PlotDemolishButton","DecorationPaletteButton","DecorationStatusButton","DecorationBackButton","DecorationRemoveButton","DecorationCancelButton","DecorationCard_torch","DecorationCard_banner","DecorationCard_skulls","DecorationCard_crystal","DecorationCard_statue","DecorationCard_brazier"]:
				var button := root.ui_layer.find_child(id,true,false) as Button
				if button == null or button.disabled or not button.is_visible_in_tree(): continue
				var bounds := button.get_global_rect()
				var ancestor := button.get_parent()
				while ancestor != null:
					if ancestor is Control and ancestor.clip_contents: bounds = bounds.intersection(ancestor.get_global_rect())
					ancestor = ancestor.get_parent()
				if bounds.has_point(event.position):
					native_touch_button = id
					native_touch_index = event.index
					emulated_mouse_deadline = Time.get_ticks_msec()+250
					return true
	if plot.active():
		if event is InputEventScreenTouch or event is InputEventScreenDrag: emulated_mouse_deadline = Time.get_ticks_msec()+250
		if event is InputEventScreenDrag and (touch_index == -1 or event.index == touch_index):
			update_pointer(event.position)
			return true
		if event is InputEventScreenTouch:
			if pointer_active and event.index != touch_index: return true
			if pointer_active and not event.pressed:
				if event.canceled:
					root._cancel_management_action_mode()
					return true
				drop(event.position)
				touch_index = -1
				return true
			if event.pressed and not root._management_ui_at(event.position):
				update_pointer(event.position)
				plot.commit()
				return true
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not pointer_active and not root._management_ui_at(event.position):
			update_pointer(event.position)
			plot.commit()
			return true
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
			plot.rotate()
			return true
	if event is InputEventMouseMotion and (pointer_active or (root.build_pick_mode and root.build_preview_room_id == "")):
		update_pointer(event.position)
		return pointer_active
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and pointer_active and not event.pressed:
		drop(event.position)
		return true
	if event is InputEventKey and root.build_pick_mode and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			root._cancel_management_action_mode()
			return true
		if root.build_pick_facility_id != "" and root.build_preview_room_id == "":
			if event.keycode in [KEY_LEFT, KEY_UP, KEY_RIGHT, KEY_DOWN]:
				var targets: Array = []
				for id in root.rooms:
					if root._can_change_room_facility(str(id)):
						targets.append(str(id))
				if not targets.is_empty():
					keyboard_index = posmod(keyboard_index + (-1 if event.keycode in [KEY_LEFT, KEY_UP] else 1), targets.size())
					hover_room = targets[keyboard_index]
					root.queue_world_overlay_redraw()
					root.management_scene.workspace_ui.refresh_preview()
				return true
			if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and hover_room != "":
				select_candidate(hover_room)
				if root.build_pick_mode: root.call_deferred("_focus_build_confirmation")
				return true
	return false

func commit_feedback(room_id: String) -> void:
	# Presentation only; short and nonblocking, sharing the existing UI sound budget.
	if root.audio_director != null:
		root.audio_director.play_event("ui.confirm", -12.0, "", -1, "building.confirm")
	var bounds: Rect2 = root.graph.rect(room_id)
	var center := bounds.get_center()
	var outline := Line2D.new()
	outline.name = "BuildingCommitFeedback"
	outline.points = PackedVector2Array([Vector2(center.x, bounds.position.y), Vector2(bounds.end.x, center.y), Vector2(center.x, bounds.end.y), Vector2(bounds.position.x, center.y), Vector2(center.x, bounds.position.y)])
	outline.width = 4.0
	outline.default_color = Color("#e8bd76")
	root.world_overlay_layer.add_child(outline)
	var tween: Tween = root.create_tween()
	tween.tween_property(outline, "modulate:a", 0.0, 0.32)
	tween.tween_callback(outline.queue_free)

var managed_view := false
var view_before_focus := Transform2D.IDENTITY
var workspace_view_key := ""

func fit_workspace_if_needed() -> void:
	var key := "%s:%s:%s:%s" % [root.castle_art_stage, root.get_viewport().get_visible_rect().size,root.management_scene.workspace_ui.tools_expanded,root.graph.layout.get("plot_grid",{})]
	if key != workspace_view_key and fit_workspace(false):
		workspace_view_key = key

func fit_workspace(whole_plot: bool = true) -> bool:
	if root.current_screen != Constants.SCREEN_MANAGEMENT or root.graph == null or root.quarter_renderer == null:
		return false
	if not can_navigate() or panning:
		return false
	var bounds := Rect2()
	for room_id in root.rooms:
		var room_bounds: Rect2 = root.graph.rect(str(room_id))
		if room_bounds.has_area():
			bounds = room_bounds if not bounds.has_area() else bounds.merge(room_bounds)
	# Include the actual rendered roof/steps, whose extent can exceed the room floor.
	var renderer = root.quarter_renderer
	for slot in root.graph.debug_object_slots():
		for layer in ["back", "front"]:
			var id := str(slot.get("id", ""))
			var texture_key: String = renderer._object_texture_key_for_layer(slot, id, layer)
			var texture: Texture2D = renderer.object_sprite_textures.get(texture_key)
			if texture == null:
				continue
			var safe_sprite: bool = renderer._is_full_grid_room_slot(slot) and renderer._object_texture_uses_projection_safe_room_sprite(texture_key)
			var fallback: bool = renderer._is_full_grid_room_slot(slot) and not safe_sprite and bool(renderer._object_placement(id, layer).get("full_grid_fallback", true))
			var drawn: Rect2 = renderer._object_texture_draw_rect(texture, renderer._object_draw_rect(slot, texture_key), id, layer, fallback, safe_sprite)
			bounds = drawn if not bounds.has_area() else bounds.merge(drawn)
	var navigation_bounds := bounds
	if root.graph.layout.has("plot_grid"):
		navigation_bounds = preload("res://scripts/map_builder/PlotPresentation.gd").view_bounds(root.graph)
		# Default: occupied rooms and room to build. The Fit map action owns the
		# complete plot, including the reserved expansion. Combat has its own camera.
		bounds = navigation_bounds if whole_plot else bounds.grow_individual(96,72,96,72)
	if not bounds.has_area():
		return false
	bounds = root.get_global_transform() * bounds.grow(30.0)
	workspace_bounds = root.get_global_transform() * navigation_bounds.grow(30.0)
	var safe := _workspace_safe_rect()
	var scale_value := clampf(minf(safe.size.x / bounds.size.x, safe.size.y / bounds.size.y), 0.25, 1.6)
	workspace_min_scale = clampf(minf(safe.size.x / workspace_bounds.size.x,safe.size.y / workspace_bounds.size.y),0.25,1.6)
	if not managed_view:
		view_before_focus = root.get_viewport().canvas_transform
		managed_view = true
	root.get_viewport().canvas_transform = Transform2D(Vector2(scale_value,0),Vector2(0,scale_value),safe.get_center() - bounds.get_center() * scale_value)
	root.quarter_renderer.sync_management_backdrop()
	root.queue_world_overlay_redraw()
	root._tutorial_build_overlay()
	return true


func reveal_candidate(room_id: String) -> void:
	if root.current_screen != Constants.SCREEN_MANAGEMENT or root.quarter_renderer == null:
		return
	var visual: Dictionary = root.quarter_renderer.facility_visual(room_id, root.build_pick_facility_id)
	var bounds: Rect2 = visual.get("bounds", Rect2())
	if bounds.size == Vector2.ZERO:
		return
	var transform: Transform2D = root.get_global_transform_with_canvas()
	var shown: Rect2 = transform * bounds
	# Same design canvas as the fixed HUD: keep floor and building above the toolbox.
	var safe := _workspace_safe_rect()
	var shift := Vector2.ZERO
	if shown.end.y > safe.end.y:
		shift.y = safe.end.y - shown.end.y
	if shown.position.y + shift.y < safe.position.y:
		shift.y = safe.position.y - shown.position.y
	if shown.end.x > safe.end.x:
		shift.x = safe.end.x - shown.end.x
	if shown.position.x + shift.x < safe.position.x:
		shift.x = safe.position.x - shown.position.x
	if shift.is_zero_approx():
		return
	if not managed_view:
		view_before_focus = root.get_viewport().canvas_transform
		managed_view = true
	var view: Transform2D = root.get_viewport().canvas_transform
	view.origin += shift
	root.get_viewport().canvas_transform = view
	root.quarter_renderer.sync_management_backdrop()
	root.queue_world_overlay_redraw()
	root._tutorial_build_overlay()

func leave_management_view() -> void:
	end_navigation()
	workspace_view_key = ""
	if managed_view:
		root.get_viewport().canvas_transform = view_before_focus
		managed_view = false

func candidate_label(room_id: String) -> Dictionary:
	return preload("res://scripts/map_builder/PlotBuildLabels.gd").layouts(root).get(room_id,{})

func draw_candidate_label(room_id: String, color: Color) -> void:
	var layout := candidate_label(room_id)
	if layout.is_empty(): return
	preload("res://scripts/ui/MapStatusLabel.gd").draw_management(root._world_overlay_draw_target,layout.anchor,layout,color,root.UI_FONT)
