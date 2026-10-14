extends Node
const GameScene = preload("res://scenes/game/GameRoot.tscn")
var game: Node
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL: ",message)

func settle(count: int = 5) -> void:
	for index in range(count): await get_tree().process_frame

func resources() -> Array:
	return [GameState.gold,GameState.mana,GameState.food,GameState.infamy]

func control(id: String) -> Control:
	return game.ui_layer.find_child(id,true,false)

func screen(cell: Vector2i) -> Vector2:
	return game.get_global_transform_with_canvas()*game.build_placement.plot.world(cell)

func event_at(point: Vector2, pressed: bool, touch: bool) -> void:
	if pressed and not touch: await motion(point,false)
	var event: InputEvent
	if touch:
		event = InputEventScreenTouch.new()
		event.index = 0
	else:
		event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.global_position = point
	event.position = point
	event.pressed = pressed
	get_viewport().push_input(event,true)
	await settle()

func motion(point: Vector2, touch: bool) -> void:
	var event: InputEvent = InputEventScreenDrag.new() if touch else InputEventMouseMotion.new()
	if touch: event.index = 0
	else: event.global_position = point
	event.position = point
	get_viewport().push_input(event,true)
	await settle()

func ui_click(id: String, touch: bool) -> void:
	var button := control(id) as Button
	expect(button != null and button.is_visible_in_tree() and not button.disabled,"available UI action "+id)
	if button == null: return
	var parent := button.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(button)
		parent = parent.get_parent()
	await settle()
	var point := button.get_global_transform_with_canvas()*(button.size/2)
	await event_at(point,true,touch)
	await event_at(point,false,touch)
	if touch:
		var before: Dictionary = game.runtime_plot_layout.duplicate(true)
		var before_resources := resources()
		for pressed in [true,false]:
			var emulated := InputEventMouseButton.new()
			emulated.device = InputEvent.DEVICE_ID_EMULATION
			emulated.position = point; emulated.global_position = point
			emulated.button_index = MOUSE_BUTTON_LEFT; emulated.pressed = pressed
			get_viewport().push_input(emulated,true)
		expect(game.runtime_plot_layout==before and resources()==before_resources,"native tap does not double-activate emulated mouse "+id)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or not OS.get_cmdline_user_args().has("--capture"): return
	await settle()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/v130_m3/"+name+".png")
	print("CAPTURE: ",name)

func valid_origin(id: String) -> Vector2i:
	var plot = game.build_placement.plot
	var original: Vector2i = preload("res://scripts/dungeon_quarter/IsoMath.gd").array_to_cell(game.graph.placed_module_data(id).grid_origin)
	for shift in [Vector2i(4,0),Vector2i(-4,0),Vector2i(0,4),Vector2i(0,-4),Vector2i(6,2),Vector2i(-6,-2)]:
		var cell: Vector2i = original+shift
		if plot.assess(id,cell,plot.rotation).ok and not game._management_ui_at(screen(cell+Vector2i(2,2))): return cell
	for cell: Vector2i in game.graph.layout.plot_mask:
		if original.distance_to(cell) < 4 or game._management_ui_at(screen(cell+Vector2i(2,2))): continue
		if plot.assess(id,cell,plot.rotation).ok: return cell
	expect(false,"available free site")
	return original

func placement_flow(touch: bool) -> void:
	UISettings.set_layout_mode("compact" if touch else "standard",false)
	game.management_scene.workspace_ui.tools_expanded = true
	game.management_tool_tab = "build"
	game._set_screen("management",false)
	await settle()
	var before := resources()
	var original: Vector2i = preload("res://scripts/dungeon_quarter/IsoMath.gd").array_to_cell(game.graph.placed_module_data("slot_01").grid_origin)
	var card := control("FacilityCard_watch_post")
	expect(card != null,"U5B palette reused")
	(control("BuildingCardScroll") as ScrollContainer).ensure_control_visible(card)
	await settle()
	var card_point := card.get_global_transform_with_canvas()*(card.size/2)
	await event_at(card_point,true,touch)
	expect(game.build_placement.pointer_active,"card owns real pointer: "+str(touch))
	await motion(game.get_global_transform_with_canvas()*game.graph.center("entrance"),touch)
	expect(not game.build_placement.plot.preview.ok and game.build_placement.plot.preview.layout.has("map_build_errors"),"colliding footprint rejected before spending")
	if not touch: await capture("invalid_ghost")
	var origin := valid_origin("slot_01")
	var point := screen(origin+Vector2i(2,2))
	await motion(point,touch)
	expect(game.build_placement.plot.preview.ok,"live valid road preview "+str(touch))
	expect(not game.build_placement.plot.preview.layout.auto_roads.road_cells.is_empty(),"generated road preview")
	expect(resources() == before,"preview costs nothing")
	await capture("touch_ghost" if touch else "mouse_ghost")
	await event_at(point,false,touch)
	expect(not game.build_pick_mode,"drop installs immediately")
	expect(game.rooms.slot_01.facility_role == "watch_post","installed facility")
	expect(preload("res://scripts/dungeon_quarter/IsoMath.gd").array_to_cell(game.graph.placed_module_data("slot_01").grid_origin) == origin,"free coordinates committed")
	expect(not game.runtime_plot_layout.is_empty(),"runtime source retains free coordinates")
	expect(game.graph.validation_summary().ok,"committed graph valid")
	var paid := resources()
	expect(paid != before,"existing facility cost charged")
	var installed_rooms: Dictionary = game.rooms.duplicate(true)
	var affected: Array = game.build_placement.plot.watch_range()
	expect(affected.has("slot_01") and affected.size()>1,"actual gameplay watch range")
	game.set_meta("v122_battle_plan",game._v122_current_battle_plan())
	for id in game.graph.module_instance_ids():
		var effect: Dictionary = game.combat_scene._v122_zone_effect_for_room(id,"detection","enemies")
		expect(affected.has(id)==(effect.get("facility_role","")=="watch_post"),"display matches combat detection: "+id)
	game.facility_disabled_timers["slot_01"] = 1.0
	expect(game.build_placement.plot.watch_range().is_empty(),"disabled watch has no active range")
	game.facility_disabled_timers.erase("slot_01")
	expect(game.build_placement.plot.watch_range()==affected,"restored watch range")
	# Starting a second drag, then canceling, preserves the last committed undo.
	game._set_build_facility("barracks")
	await settle()
	await motion(screen(Vector2i(-20,-20)),touch)
	expect(not game.build_placement.plot.preview.ok,"outside plot is red")
	await ui_click("CancelBuildingButton",touch)
	await settle()
	expect(resources()==paid and game.rooms==installed_rooms,"cancel no mutation")
	await ui_click("PlacementUndoButton",touch)
	expect(game.management_undo.is_empty(),"undo after cancel via UI")
	await settle()
	expect(resources()==before,"undo resources exact")
	expect(preload("res://scripts/dungeon_quarter/IsoMath.gd").array_to_cell(game.graph.placed_module_data("slot_01").grid_origin)==original,"undo position exact")
	expect(game.runtime_plot_layout.is_empty(),"undo source exact")
	# Move/rotation preserve HP, upgrades, resources and roster.
	game.selected_room = "barracks"
	var room_before: Dictionary = game.rooms.barracks.duplicate(true)
	game.management_context_drawer_open = true
	game._set_screen("management",false)
	await settle()
	await ui_click("PlotMoveButton",touch)
	await settle()
	var move_origin := valid_origin("barracks")
	await event_at(screen(move_origin+Vector2i(2,2)),true,touch)
	await event_at(screen(move_origin+Vector2i(2,2)),false,touch)
	expect(preload("res://scripts/dungeon_quarter/IsoMath.gd").array_to_cell(game.graph.placed_module_data("barracks").grid_origin)==move_origin,"move via pointer")
	expect(game.rooms.barracks==room_before and resources()==before,"move preserves balance")
	expect(game._undo_last_management_placement(),"undo move")
	await settle()
	game.selected_room = "barracks"
	game.management_context_drawer_open = true
	game._set_screen("management",false)
	await settle()
	await ui_click("PlotRotateButton",touch)
	await settle()
	expect(not game.runtime_plot_layout.is_empty(),"rotate immediate")
	expect(game.graph.placed_module_data("barracks").module_id=="map_rotated_barracks","rotated blueprint and sockets")
	expect(game.rooms.barracks==room_before and resources()==before,"rotation preserves stats")
	expect(game.graph.validation_summary().ok,"rotated roads valid")
	expect(game._undo_last_management_placement(),"undo rotation")
	await settle()
	game.selected_room = "barracks"
	game.management_context_drawer_open = true
	game._set_screen("management",false)
	await settle()
	await ui_click("PlotDemolishButton",touch)
	await settle()
	expect(game.rooms.barracks.facility_role=="build_slot","demolish via existing empty-slot rules")
	expect(game._undo_last_management_placement(),"undo demolition")
	await settle()
	expect(game.rooms.barracks==room_before and resources()==before,"undo demolition exact")
	game.selected_room = "entrance"
	game.build_placement.plot.begin_move()
	expect(not game.build_pick_mode,"entrance locked")
	game.selected_room = "throne"
	game.build_placement.plot.demolish()
	expect(game.rooms.throne.facility_role=="core","throne cannot demolish")
	game.build_placement.plot.begin_move()
	await settle()
	var throne_site := valid_origin("throne")
	game.build_placement.plot.preview = game.build_placement.plot.assess("throne",throne_site,0)
	expect(game.build_placement.plot.commit(),"throne may move while entrance stays fixed")
	expect(game.graph.validation_summary().ok,"moved throne road valid")
	expect(game._undo_last_management_placement(),"undo throne move")
	await settle()

func run() -> void:
	game = GameScene.instantiate()
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false
	game.campaign_save_v5_enabled = false
	add_child(game)
	await settle()
	game.set_process(false)
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.story_feature_enabled = false
	game.story_director.cancel_active_scene()
	game.onboarding_dialogue_queue.clear()
	GameState.day = 7
	GameState.gold = 5000; GameState.mana = 5000
	for touch in [UISettings.is_touch_ui()]: await placement_flow(touch)
	game._shutdown_audio_for_exit()
	game.queue_free()
	await settle()
	for locale in ["ko","en","zh_CN"]:
		for touch in [UISettings.is_touch_ui()]: await tutorial_flow(locale,touch)
	print("V130PlacementTest %s checks=%d failures=%s" % ["PASS" if failures.is_empty() else "FAIL",checks,failures])
	get_tree().quit(0 if failures.is_empty() else 1)

func drain_dialogue() -> void:
	var quiet := 0
	for index in range(160):
		await get_tree().process_frame
		if game.story_director.is_active():
			quiet = 0
			game._story_advance_dialogue(true)
		elif game.current_screen == "dialogue":
			quiet = 0
			game._onboarding_advance_dialogue()
		else:
			quiet += 1
			if quiet >= 3: return
	expect(false,"dialogue drains without blocking")

func tutorial_flow(locale: String, touch: bool) -> void:
	LanguageSettings.set_locale(locale,false)
	UISettings.set_layout_mode("compact" if touch else "standard",false)
	game = GameScene.instantiate()
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false
	game.campaign_save_v5_enabled = false
	add_child(game)
	await settle()
	game.pending_title_reset_mode = "new"
	game._onboarding_start_new_game()
	await settle()
	expect(game.tutorial_manager.steps.size()==13,"13 tutorial steps preserved")
	game.onboarding_name_input.text = "Map Lord"
	game._onboarding_confirm_name()
	await drain_dialogue()
	expect(game.current_screen in ["intrusion_brief","management"],"new game reaches first-day integrated brief: "+locale)
	game._enter_placement_from_brief()
	await settle()
	expect(game.tutorial_manager.current_step_id()=="TUT_030_SELECT_SLIME","required selection preserved")
	var selection_step: String = game.tutorial_manager.current_step_id()
	var front_id: String = game._day1_goblin_tutorial_target_rooms()[0]
	var former_center: Vector2 = game.graph.center(front_id)
	game.selected_room = front_id
	game.build_placement.plot.begin_move()
	await settle()
	var shifted := valid_origin(front_id)
	game.build_placement.plot.preview = game.build_placement.plot.assess(front_id,shifted,0)
	expect(game.build_placement.plot.commit(),"tutorial defense facility can move")
	game.management_tool_tab = "roster"
	game._set_screen("management",false)
	await settle()
	expect(game.tutorial_manager.current_step_id()==selection_step,"building move cannot skip mandatory selection")
	expect(game.graph.center(front_id)!=former_center,"tutorial fixture uses moved building")
	for id in ["BUILD_PALETTE_CARD","BUILD_GHOST","AUTO_ROAD_PREVIEW","PLOT_ENTRANCE","PLOT_THRONE"]:
		expect(game._tutorial_focus_rect(id).has_area(),"live plot tutorial target "+id)
	var step: String = game.tutorial_manager.current_step_id()
	game._start_monster_placement("slime")
	expect(game.tutorial_manager.current_step_id()==step,"wrong monster cannot skip step")
	await settle()
	var card_point: Vector2 = game._tutorial_focus_rect("CHR_GOB").get_center()
	await motion(card_point,false)
	await event_at(card_point,true,touch)
	await event_at(card_point,false,touch)
	expect(game.tutorial_manager.current_step_id()=="TUT_040_DEPLOY_SLIME","real card selects Gob: "+locale+str(touch))
	if game.tutorial_manager.current_step_id()!="TUT_040_DEPLOY_SLIME":
		game._shutdown_audio_for_exit()
		game.queue_free()
		await settle()
		return
	# The target remains tied to current layout coordinates after free movement.
	var targets: Array[String] = game._day1_goblin_tutorial_target_rooms()
	expect(targets.size()==2 and game.tutorial_manager.day1_target_rooms==targets,"one target set shared with action validation")
	expect(game._tutorial_focus_rect("DAY1_GOBLIN_FORMATION").has_point(game.get_global_transform_with_canvas()*game.graph.center(front_id)),"guidance follows moved target")
	if locale=="ko" and not touch: await capture("tutorial_day1")
	var point: Vector2 = game.get_global_transform_with_canvas()*game.graph.center(targets[1] if touch else targets[0])
	await event_at(point,true,touch)
	await event_at(point,false,touch)
	await drain_dialogue()
	expect(game.tutorial_manager.current_step_id()=="TUT_090_RESULT_GROWTH","formation preserves mandatory action: "+locale+str(touch))
	expect(not game._management_action_mode_active(),"formation clears transient input")
	game._request_combat_start()
	for index in range(260):
		await get_tree().process_frame
		if game.current_screen=="dialogue": await drain_dialogue()
		if game.current_screen=="combat": break
	expect(game.current_screen=="combat","first defense starts without interrupted tutorial: "+locale+str(touch))
	game._shutdown_audio_for_exit()
	game.queue_free()
	await settle()
