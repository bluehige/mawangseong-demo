extends "res://tools/UIUXBuildPlacementTest.gd"
var scenarios := 0
var held_buttons := 0

func _run() -> void:
	output = "res://tmp/uiux_stage_art_20260913/navigation"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	game = Game.instantiate()
	add_child(game)
	await settle()
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.story_feature_enabled = false
	GameState.day = 2
	game._choose_early_specialization("goblin","goblin_treasure_hunter")
	GameState.gold = 100000
	GameState.mana = 100000
	GameState.food = 100000
	var original_rooms: Dictionary = game.rooms.duplicate(true)
	var original_roster: Dictionary = game.monster_roster.duplicate(true)
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for text_scale in [0.9,1.0,1.15]:
			UISettings.text_scale = text_scale
			for stage in ["stage_01_cave","stage_02_castle","stage_03_keep","stage_04_citadel"]:
				game._clear_management_action_mode(false)
				game.rooms = original_rooms.duplicate(true)
				game.monster_roster = original_roster.duplicate(true)
				game.castle_art_stage = stage
				game._sync_castle_stage_content()
				game._refresh_quarter_map_from_rooms()
				game.management_context_drawer_open = false
				game.management_tool_tab = "build"
				game._set_screen(Constants.SCREEN_MANAGEMENT)
				await settle()
				var tag := "%dx%d_%d_%s" % [resolution.x,resolution.y,roundi(text_scale*100),stage]
				await _exercise_navigation(tag)
				scenarios += 1
	game.queue_free()
	await settle()
	var file := FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failed,"scenarios":scenarios},"\t"))
	file.close()
	print("UIUX_MAP_NAVIGATION_TEST: %s (%d checks; %d scenarios)" % ["FAIL" if failed else "PASS",checks,scenarios])
	get_tree().quit(1 if failed else 0)

func _button(point: Vector2, button_index: MouseButton, pressed: bool = true) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = button_index
	event.pressed = pressed
	if button_index == MOUSE_BUTTON_MIDDLE:
		held_buttons = held_buttons | MOUSE_BUTTON_MASK_MIDDLE if pressed else held_buttons & ~MOUSE_BUTTON_MASK_MIDDLE
	event.button_mask = held_buttons
	get_viewport().push_input(event,true)
	if pressed and button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		_button(point,button_index,false)

func mouse(point: Vector2, pressed: bool) -> void:
	held_buttons = held_buttons | MOUSE_BUTTON_MASK_LEFT if pressed else held_buttons & ~MOUSE_BUTTON_MASK_LEFT
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = held_buttons
	get_viewport().push_input(event,true)

func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.button_mask = held_buttons
	get_viewport().push_input(event,true)

func _click_control(id: String) -> void:
	var button := game.ui_layer.find_child(id,true,false) as Button
	check(button != null and not button.disabled,"navigation control reachable "+id)
	if button == null or button.disabled: return
	motion(button.get_global_rect().get_center())
	await settle(2)
	mouse(button.get_global_rect().get_center(),true)
	mouse(button.get_global_rect().get_center(),false)
	await settle()

func _exercise_navigation(tag: String) -> void:
	var nav = game.build_placement
	var before := state()
	var selected: String = game.selected_room
	var fitted: Transform2D = get_viewport().canvas_transform
	var previous_view: Transform2D = nav.view_before_focus
	var point: Vector2 = nav._workspace_safe_rect().get_center()
	var anchor: Vector2 = nav.viewport_to_world(point)
	var layout: Dictionary = game._management_label_layout(point,"× 고정된 방입니다. 다른 건설 구역을 선택하세요.",18)
	check(layout.font_size == UISettings.scaled_font_size(18),tag+" screen label respects text setting")
	for line in layout.lines:
		check(game.UI_FONT.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,layout.font_size).x <= layout.rect.size.x-23,tag+" full label text fits")
	await capture(tag+"_fit")
	_button(point,MOUSE_BUTTON_WHEEL_UP)
	await settle()
	check(get_viewport().canvas_transform.x.length() > fitted.x.length(),tag+" actual wheel zoom")
	check(nav.viewport_to_world(point).distance_to(anchor) < 0.05,tag+" zoom keeps world point under pointer")
	var zoomed_label: Dictionary = game._management_label_layout(point,"× 고정된 방입니다. 다른 건설 구역을 선택하세요.",18)
	check(zoomed_label.font_size == layout.font_size and zoomed_label.rect.size == layout.rect.size,tag+" label size does not shrink with map")
	_button(point,MOUSE_BUTTON_WHEEL_UP)
	await settle()
	var zoomed: Transform2D = get_viewport().canvas_transform
	_button(point,MOUSE_BUTTON_MIDDLE)
	motion(point+Vector2(48,26))
	await settle()
	check(nav.panning and not get_viewport().canvas_transform.is_equal_approx(zoomed),tag+" actual middle-button map movement")
	mouse(point,true)
	mouse(point,false)
	check(game.selected_room == selected and not game.build_pick_mode and game.dragging_monster_id == "",tag+" simultaneous left input cannot select or place")
	_button(Vector2(100,850),MOUSE_BUTTON_MIDDLE,false)
	await settle()
	check(not nav.panning,tag+" release over toolbox ends movement")
	check(state() == before,tag+" navigation never changes game state")
	await capture(tag+"_zoom_pan")
	var moved: Transform2D = get_viewport().canvas_transform
	_button(Vector2(100,850),MOUSE_BUTTON_WHEEL_UP)
	_button(Vector2(100,850),MOUSE_BUTTON_MIDDLE)
	motion(point)
	_button(point,MOUSE_BUTTON_MIDDLE,false)
	await settle()
	check(not nav.panning and get_viewport().canvas_transform.is_equal_approx(moved),tag+" HUD wheel and middle press do not move map")
	_button(point,MOUSE_BUTTON_MIDDLE)
	key(KEY_ESCAPE)
	await settle()
	check(not nav.panning and not game.pause_menu_open,tag+" ESC only ends map gesture")
	_button(point,MOUSE_BUTTON_MIDDLE,false)
	_button(point,MOUSE_BUTTON_MIDDLE)
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	motion(point+Vector2(20,10))
	await settle()
	check(not nav.panning and get_viewport().canvas_transform.is_equal_approx(moved),tag+" focus loss ends map gesture")
	_button(point,MOUSE_BUTTON_MIDDLE,false)
	await _click_control("FitManagementMapButton")
	check(get_viewport().canvas_transform.is_equal_approx(fitted),tag+" fit button restores all rooms")
	await _click_control("ZoomInManagementMapButton")
	check(get_viewport().canvas_transform.x.length() > fitted.x.length(),tag+" zoom button works")
	var zoom_out := game.ui_layer.find_child("ZoomOutManagementMapButton",true,false) as Button
	zoom_out.grab_focus()
	key(KEY_ENTER)
	await settle()
	check(get_viewport().canvas_transform.is_equal_approx(fitted),tag+" focused keyboard zoom out works")
	zoom_out.release_focus()
	for id in game.rooms:
		if game._can_change_room_facility(str(id)):
			check(not game._management_ui_at(world(game.graph.center(str(id)))),tag+" fitted room pointer accessible "+str(id))
	# All three monster selection modes keep camera navigation locked.
	game._begin_management_roster_drag("goblin")
	check(game.dragging_monster_id == "goblin" and not nav.can_navigate(),tag+" roster drag locks navigation")
	check(not nav.zoom_workspace(1) and not nav.fit_workspace(),tag+" roster drag blocks zoom and fit")
	game._cancel_management_action_mode()
	check(game._start_management_monster_drag(game._management_monster_preview_position("goblin")),tag+" direct map monster drag starts")
	check(not game.roster_monster_drag_active and not nav.can_navigate() and not nav.fit_workspace(),tag+" map monster drag also locks navigation")
	var fit_button := game.ui_layer.find_child("FitManagementMapButton",true,false) as Button
	check(fit_button.disabled,tag+" blocked map button is visibly disabled")
	game._cancel_management_action_mode()
	game._start_monster_placement("goblin")
	check(not nav.can_navigate() and not nav.zoom_workspace(1),tag+" monster click placement locks navigation")
	game._cancel_management_action_mode()
	await settle()
	# Real construction after a user-driven transformed view.
	var target := "slot_01"
	point = world(game.graph.center(target))
	_button(point,MOUSE_BUTTON_WHEEL_UP)
	await settle()
	_button(point,MOUSE_BUTTON_MIDDLE)
	motion(point+Vector2(20,-12))
	_button(point+Vector2(20,-12),MOUSE_BUTTON_MIDDLE,false)
	await settle()
	await drag_card("watch_post",world(game.graph.center(target)))
	var drag_view: Transform2D = get_viewport().canvas_transform
	check(nav.hover_room == target,tag+" transformed drag finds exact room")
	_button(world(game.graph.center(target)),MOUSE_BUTTON_WHEEL_UP)
	_button(world(game.graph.center(target)),MOUSE_BUTTON_MIDDLE)
	motion(world(game.graph.center(target)))
	_button(world(game.graph.center(target)),MOUSE_BUTTON_MIDDLE,false)
	check(not nav.panning and get_viewport().canvas_transform.is_equal_approx(drag_view),tag+" construction pointer locks camera")
	await check_ghost_pixels(tag)
	await capture(tag+"_drag")
	mouse(world(game.graph.center(target)),false)
	await settle()
	check(game.build_preview_room_id == target and state() == before,tag+" transformed drop remains read-only")
	await capture(tag+"_review")
	await _click_control("ConfirmFacilityReplacementButton")
	check(str(game.rooms[target].facility_role) == "watch_post",tag+" transformed view confirms construction")
	check(game._undo_last_management_placement(),tag+" transformed construction uses existing Undo")
	await settle()
	check(state() == before,tag+" Undo restores full supported state")
	_button(point,MOUSE_BUTTON_MIDDLE)
	game._set_screen(Constants.SCREEN_SETTINGS)
	_button(point,MOUSE_BUTTON_MIDDLE,false)
	await settle()
	check(not nav.panning and get_viewport().canvas_transform.is_equal_approx(previous_view),tag+" screen transition restores previous view")
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	await settle()
	check(state() == before,tag+" leaving and returning does not mutate state")
