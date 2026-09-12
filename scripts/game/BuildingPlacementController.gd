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

func setup(game: Node) -> void:
	root = game

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

func card_input(event: InputEvent, facility_id: String, card: Control) -> void:
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
	var fit_button := root.ui_layer.find_child("FitManagementMapButton", true, false) as Button
	if fit_button != null:
		fit_button.disabled = true
	var feedback := root.ui_layer.find_child("PlacementFeedbackLabel", true, false) as Label
	if feedback != null:
		feedback.text = "놓아서 위치 검토 · 확정 전 비용 사용 없음 · ESC로 취소"
	root.queue_world_overlay_redraw()

func reset() -> void:
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
	var next_room := "" if root._management_ui_at(viewport_point) else exact_room(pointer_world)
	if hover_room != next_room:
		hover_room = next_room
		root.queue_world_overlay_redraw()

func drop(viewport_point: Vector2) -> void:
	update_pointer(viewport_point)
	var was_dragging := dragging
	pointer_active = false
	dragging = false
	if not was_dragging:
		root._set_build_facility(root.build_pick_facility_id)
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
		root._set_management_feedback(true, "위치 선택 완료 · 아직 비용을 쓰지 않았습니다.")
	root._set_screen(Constants.SCREEN_MANAGEMENT)

func handle_input(event: InputEvent) -> bool:
	if root.current_screen != Constants.SCREEN_MANAGEMENT or root.map_editor_active or root.pause_menu_open:
		return false
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
				return true
			if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and hover_room != "":
				select_candidate(hover_room)
				root.call_deferred("_focus_build_confirmation")
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
	var key := "%s:%s" % [root.castle_art_stage, root.get_viewport().get_visible_rect().size]
	if key != workspace_view_key and fit_workspace():
		workspace_view_key = key

func fit_workspace() -> bool:
	if root.current_screen != Constants.SCREEN_MANAGEMENT or root.graph == null or root.quarter_renderer == null:
		return false
	if root.map_editor_active or root.pause_menu_open or pointer_active or root.build_pick_mode or root.roster_monster_drag_active:
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
	if not bounds.has_area():
		return false
	bounds = root.get_global_transform() * bounds.grow(30.0)
	var viewport_size: Vector2 = root.get_viewport().get_visible_rect().size
	var safe := Rect2(Vector2(36,178),Vector2(1848,552))
	safe = Rect2(safe.position * viewport_size / Vector2(1920,1080), safe.size * viewport_size / Vector2(1920,1080))
	var scale_value := clampf(minf(safe.size.x / bounds.size.x, safe.size.y / bounds.size.y), 0.25, 1.0)
	if not managed_view:
		view_before_focus = root.get_viewport().canvas_transform
		managed_view = true
	root.get_viewport().canvas_transform = Transform2D(Vector2(scale_value,0),Vector2(0,scale_value),safe.get_center() - bounds.get_center() * scale_value)
	root.queue_world_overlay_redraw()
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
	var viewport_size: Vector2 = root.get_viewport().get_visible_rect().size
	# Same design canvas as the fixed HUD: keep floor and building above the toolbox.
	var safe := Rect2(Vector2(36,212),Vector2(1848,518))
	safe = Rect2(safe.position * viewport_size / Vector2(1920,1080), safe.size * viewport_size / Vector2(1920,1080))
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
	root.queue_world_overlay_redraw()

func leave_management_view() -> void:
	workspace_view_key = ""
	if managed_view:
		root.get_viewport().canvas_transform = view_before_focus
		managed_view = false
