extends Node
const GameScene = preload("res://scenes/game/GameRoot.tscn")
const Audit = preload("res://tools/ux_audit/Audit.gd")
var out := "res://tmp/v1213_u5b"
var game: Node
var checks := 0
var failures: Array[String] = []
var screens: Array = []
var capture_only := false
var probe := false
var capture_filter: PackedStringArray = []

func _ready() -> void:
	get_tree().create_timer(120).timeout.connect(func(): get_tree().quit(2))
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL: "+message)

func settle(frames: int = 8) -> void:
	for i in range(frames): await get_tree().process_frame

func control(id: String) -> Control:
	return game.ui_layer.find_child(id,true,false) as Control

func point_click(point: Vector2) -> void:
	print("U5B input %s screen=%s UI=%s" % [point,game.current_screen,game._management_ui_at(point)])
	await motion(point)
	print("U5B hovered="+str(get_viewport().gui_get_hovered_control()))
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		get_viewport().push_input(event,true)
		# Let GUI focus/scroll layout settle between the physical press and release.
		await get_tree().process_frame
	await settle()
	print("U5B after screen=%s pick=%s facility=%s pointer=%s paused=%s feedback=%s" % [game.current_screen,game.build_pick_mode,game.build_pick_facility_id,game.build_placement.pointer_active,game.pause_menu_open,game.management_feedback])

func click(id: String) -> void:
	var target := control(id)
	expect(target != null and target.is_visible_in_tree(),"visible input "+id)
	if target != null: await point_click(target.get_global_transform_with_canvas()*(target.size/2))

func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point; event.global_position = point
	get_viewport().push_input(event,true)
	await settle(3)

func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code; event.pressed = pressed
		get_viewport().push_input(event,true)
	await settle()

func resources() -> Dictionary:
	return {"gold":GameState.gold,"mana":GameState.mana,"food":GameState.food,"infamy":GameState.infamy}

func prepare(tab: String = "build", expanded: bool = true) -> void:
	game.management_scene.workspace_ui.tools_expanded = expanded
	game.pause_menu_open = false
	game.story_director.cancel_active_scene()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.story_feature_enabled = false
	game.onboarding_dialogue_queue.clear()
	GameState.day = 7
	GameState.gold = 5000; GameState.mana = 5000; GameState.food = 100
	game.monster_roster.goblin.specialization_id = "goblin_treasure_hunter"
	game._clear_management_action_mode(false)
	game.management_feedback.clear()
	game.management_tool_tab = tab
	game.management_context_drawer_open = false
	game._set_screen("management",false)

# Union of visible UI blockers, clipped to the real viewport; empty map rendering
# behind a panel is never counted. This is screen space, not dungeon floor pixels.
func visible_map_percent() -> float:
	var rects: Array[Rect2] = []
	var viewport := get_viewport().get_visible_rect()
	var xs: Array[float] = [0,viewport.size.x]
	for child in game.ui_layer.get_children():
		if child is Control and child.is_visible_in_tree() and child.get_meta("u5b_occluder",false):
			var rect: Rect2 = child.get_global_rect().intersection(viewport)
			if rect.has_area(): rects.append(rect); xs.append(rect.position.x); xs.append(rect.end.x)
	for button in game.ui_layer.find_children("*","BaseButton",true,false):
		if not button.is_visible_in_tree(): continue
		var rect: Rect2 = button.get_global_rect().intersection(viewport)
		var parent: Node = button.get_parent()
		while parent != null:
			if parent is Control and parent.clip_contents: rect = rect.intersection(parent.get_global_rect())
			parent = parent.get_parent()
		if rect.has_area(): rects.append(rect); xs.append(rect.position.x); xs.append(rect.end.x)
	xs.sort()
	var blocked := 0.0
	for i in range(xs.size()-1):
		var intervals: Array[Vector2] = []
		var center := (xs[i]+xs[i+1])/2
		for rect in rects:
			if center > rect.position.x and center < rect.end.x: intervals.append(Vector2(rect.position.y,rect.end.y))
		intervals.sort_custom(func(a: Vector2,b: Vector2): return a.x < b.x)
		var low := -1.0; var high := -1.0; var height := 0.0
		for interval in intervals:
			if interval.x > high:
				height += maxf(0,high-low); low = interval.x; high = interval.y
			else: high = maxf(high,interval.y)
		height += maxf(0,high-low)
		blocked += (xs[i+1]-xs[i])*height
	return 100*(1-blocked/viewport.get_area())

func inspect(id: String) -> void:
	if capture_only and not capture_filter.is_empty() and not capture_filter.has(id): return
	await settle(12)
	var inspector := Audit.new()
	inspector.game = game
	var items: Array = []
	inspector.collect(game.ui_layer,items)
	inspector.free()
	var overlaps: Array = []
	for pair in [["ManagementToolTabs","ManagementContextDrawer"],["ManagementToolTabs","BuildingToolbox"],["ManagementToolTabs","MonsterRosterDock"],["ManagementToolTabs","TacticsToolbox"],["ManagementToolTabs","BuildingReviewBar"]]:
		var a := control(pair[0]); var b := control(pair[1])
		if a != null and b != null and a.is_visible_in_tree() and b.is_visible_in_tree():
			if a.get_global_rect().intersects(b.get_global_rect()): overlaps.append(pair)
	expect(overlaps.is_empty(),id+" dock/selection overlap 0")
	for item in items:
		if item.type == "Label" and str(item.text) != "":
			expect(int(item.line_count) <= int(item.visible_lines),id+" all text lines visible: "+str(item.name))
		if bool(item.button): expect(str(item.tooltip).strip_edges() != "",id+" tooltip: "+str(item.name))
		if bool(item.button) and not bool(item.clipped) and not str(item.clip_parent).contains("Scroll"):
			var rect := Rect2(item.rect[0],item.rect[1],item.rect[2],item.rect[3])
			expect(get_viewport().get_visible_rect().grow(1).encloses(rect),id+" button inside viewport: "+str(item.name))
	var rail := control("ResourceStatusRail")
	if rail != null:
		for child in rail.find_children("*","Button",true,false):
			if child.is_visible_in_tree(): expect(rail.get_global_rect().grow(1).encloses(child.get_global_rect()),id+" header owns "+str(child.name))
	var drawer := control("ManagementContextDrawer")
	if drawer != null and drawer.is_visible_in_tree():
		for child in drawer.find_children("*","Button",true,false):
			expect(child.get_global_rect().end.x <= drawer.get_global_rect().end.x-8,id+" drawer width owns "+str(child.name))
	var route := control("MazeRouteOption") as OptionButton
	if route != null:
		for i in range(route.item_count): expect(not route.get_item_text(i).contains("�"),id+" route text has no replacement characters")
	var dock := control("ManagementToolTabs")
	if dock != null and dock.is_visible_in_tree():
		for child in dock.find_children("*","Button",true,false):
			if child.is_visible_in_tree(): expect(dock.get_global_rect().grow(1).encloses(child.get_global_rect()),id+" dock owns "+str(child.name))
	var visibility := visible_map_percent()
	if id.ends_with("_default"): expect(visibility >= 80,id+" default visible map >=80%% (%.3f)" % visibility)
	var backdrop := game.get_node("BackgroundVoidLayer/DungeonBackgroundPlate") as TextureRect
	var background_rect: Rect2 = backdrop.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,backdrop.size)
	if game.current_screen == "management":
		expect(background_rect.position.length() < 0.01 and background_rect.size.distance_to(get_viewport().get_visible_rect().size) < 0.01,id+" cave covers viewport independently of map camera")
		expect(not game.get_node("BackgroundVoidLayer/DungeonBackdrop").visible,id+" old rectangular backdrop hidden")
	var shown_bounds: Rect2 = get_viewport().canvas_transform * game.build_placement.workspace_bounds
	if id.ends_with("_default"):
		var default_view: Transform2D = get_viewport().canvas_transform
		var safe: Rect2 = game.build_placement._workspace_safe_rect()
		for room_id in game.rooms:
			var floor_rect: Rect2 = game.get_global_transform_with_canvas() * game.graph.rect(str(room_id))
			expect(safe.grow(1).encloses(floor_rect),id+" default occupied room inside safe area: "+str(room_id))
			for blocker in ["ResourceStatusRail","BossHpBar","ManagementToolTabs","PlacementUndoButton","OpenManagementContextButton"]:
				expect(not floor_rect.intersects(control(blocker).get_global_rect()),id+" room floor/HUD overlap 0: "+str(room_id)+"/"+blocker)
		# Preserve the complete map and 850/874 fill gates on the explicit Fit map
		# input; default framing now deliberately favors the occupied rooms.
		await click("FitManagementMapButton")
		var full_view: Transform2D = get_viewport().canvas_transform
		var full_bounds: Rect2 = full_view * game.build_placement.workspace_bounds
		expect(safe.grow(1).encloses(full_bounds),id+" whole rendered map inside safe area")
		var fill := maxf(full_bounds.size.x/safe.size.x,full_bounds.size.y/safe.size.y)
		expect(fill >= 850.0/874.0,id+" full map fills limiting safe axis")
		expect(default_view.x.length()>full_view.x.length()*1.15,id+" default rooms larger than full map")
		get_viewport().canvas_transform=default_view
		game.quarter_renderer.sync_management_backdrop()
	if id.ends_with("_build_selected"):
		for detail in ["BuildDetailArt","BuildDetailCostIcons","BuildDetailEffect","BuildDetailPlacementCount","BuildDetailInstallHint"]:
			expect(control(detail) != null and control(detail).is_visible_in_tree(),id+" selected detail visible: "+detail)
		expect((control("BuildDetailEffect") as Label).get_line_count() == 1,id+" compact effect is one line")
		for blocker in ["ResourceStatusRail","BuildingToolbox","BuildingSlotCount","ManagementToolTabs","BossHpBar"]:
			expect(not control("BuildingReviewBar").get_global_rect().intersects(control(blocker).get_global_rect()),id+" detail/HUD overlap 0: "+blocker)
		var ghost: Control = game.build_placement.ghost
		expect(ghost.visible and not control("BuildingReviewBar").get_global_rect().intersects(ghost.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,ghost.size)),id+" existing target ghost visible outside detail popup")
	screens.append({"id":id,"locale":LanguageSettings.locale,"window":str(get_window().size),"viewport":str(get_viewport().get_visible_rect().size),"map_visible_percent":visibility,"overlaps":overlaps,"background_rect":str(background_rect),"map_bounds":str(shown_bounds),"controls":items})
	if capture_only:
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		# Native window-sized presentation of the actual engine framebuffer.
		if frame.get_size() != get_window().size: frame.resize(get_window().size.x,get_window().size.y,Image.INTERPOLATE_LANCZOS)
		frame.save_png(out.path_join(id+".png"))

func states(prefix: String, all: bool) -> void:
	if all:
		prepare("roster",false)
		await inspect(prefix+"default")
	prepare("build")
	await inspect(prefix+"build")
	game._set_build_facility("watch_post")
	await settle()
	await motion(game.get_global_transform_with_canvas()*game.graph.center("slot_01"))
	await inspect(prefix+"build_selected")
	if all:
		prepare("roster")
		await inspect(prefix+"roster")
		prepare("tactics")
		await inspect(prefix+"tactics")
	prepare("build")
	game.selected_room = "barracks"
	game.management_context_drawer_open = true
	game._set_screen("management",false)
	await inspect(prefix+"inspector")
	if all:
		prepare()
		game._open_intrusion_brief(true)
		await inspect(prefix+"brief")
		prepare()
		game._request_combat_start()
		await inspect(prefix+"countdown")
		game._cancel_defense_start()

func interactions() -> void:
	prepare()
	await settle()
	var before := resources()
	var route: Array = game._main_route_instance_ids().duplicate()
	await click("FacilityCard_barracks")
	expect(game.build_pick_mode and resources() == before,"card selects without spending")
	var room_id := "slot_01"
	var point: Vector2 = game.get_global_transform_with_canvas()*game.graph.center(room_id)
	await motion(point)
	expect(resources() == before and game.build_placement.hover_room == room_id,"hover is read-only and exact target")
	expect(control("BuildReviewEffects") != null and (control("BuildReviewEffects") as Label).text != "","effects and actual route visible before commit")
	await point_click(point)
	var cost: Dictionary = game._facility_definition("barracks").cost
	expect(str(game.rooms[room_id].facility_role) == "barracks" and not game.build_pick_mode,"position click immediately commits")
	for id in cost: expect(resources()[id] == before[id]-cost[id],"single charge "+str(id))
	expect(game._main_route_instance_ids() == route,"same route after installation")
	expect(not game._confirm_build_preview(),"repeat commit blocked")
	await click("PlacementUndoButton")
	expect(resources() == before and str(game.rooms[room_id].facility_role) == "build_slot","undo restores resources and facility")
	expect(not game._undo_last_management_placement(),"undo consumed once")
	await click("FacilityCard_barracks")
	await point_click(Vector2(1800,700))
	expect(resources() == before and game.build_pick_mode,"invalid target keeps choice without spending")
	await click("ManagementTab_roster")
	expect(not game.build_pick_mode and game.management_tool_tab == "roster","tool switch cancels pending construction")
	await click("MonsterCard_slime")
	expect(game.deploy_pick_monster_id == "slime","roster click enters placement mode")
	var source: String = game.monster_roster.slime.room
	await point_click(game.get_global_transform_with_canvas()*game.graph.center("recovery"))
	expect(str(game.monster_roster.slime.room) == "recovery" and game.deploy_pick_monster_id == "","roster card plus room immediately assigns once")
	expect(game._undo_last_management_placement(),"deployment uses existing undo")
	await settle()
	expect(str(game.monster_roster.slime.room) == source,"deployment undo restores original room")
	await click("MonsterCard_slime")
	await key(KEY_ESCAPE)
	expect(game.deploy_pick_monster_id == "","escape cancels selection")
	expect(get_viewport().gui_get_focus_owner() != null,"escape restores a visible keyboard focus")
	prepare("build")
	await settle()
	# Drag through the real card input route and release on a world target.
	var card := control("FacilityCard_barracks")
	var start := card.get_global_transform_with_canvas()*(card.size/2)
	var press := InputEventMouseButton.new()
	press.position = start; press.global_position = start; press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true
	get_viewport().push_input(press,true)
	await settle()
	point = game.get_global_transform_with_canvas()*game.graph.center(room_id)
	await motion(point)
	var release := InputEventMouseButton.new()
	release.position = point; release.global_position = point; release.button_index = MOUSE_BUTTON_LEFT; release.pressed = false
	get_viewport().push_input(release,true)
	await settle()
	expect(str(game.rooms[room_id].facility_role) == "barracks" and not game.build_placement.pointer_active,"drag drop commits and clears pointer ownership")
	game._undo_last_management_placement()
	await settle()
	# Keyboard uses the same immediate placement authority and read-only preview.
	prepare("build")
	await settle()
	(control("FacilityCard_barracks") as Button).grab_focus()
	await key(KEY_ENTER)
	expect(game.build_pick_mode and game.build_pick_facility_id == "barracks","keyboard card activation")
	for i in range(game.rooms.size()+1):
		await key(KEY_RIGHT)
		if game.build_placement.hover_room == room_id: break
	expect(game.build_placement.hover_room == room_id,"arrows select same exact candidate")
	expect((control("BuildReviewEffects") as Label).text.contains(LanguageSettings.ui_text(game._build_preview_route_line(room_id))),"keyboard shows actual route before spending")
	await key(KEY_ENTER)
	expect(str(game.rooms[room_id].facility_role) == "barracks","keyboard confirms once")
	game._undo_last_management_placement()
	await settle()
	# Unique replacement preview includes old room vacancy before confirmation.
	game._set_build_facility("treasure")
	await settle()
	await motion(game.get_global_transform_with_canvas()*game.graph.center(room_id))
	await settle()
	var warnings: Array = game._evaluate_facility_placement(room_id,"treasure").warnings
	expect(not warnings.is_empty(),"unique facility move exposes its impact")
	expect((control("BuildReviewWarning") as Label).text.contains(game.display_name_for_instance("treasure")),"unique old room shown before commit")
	game.build_placement.select_candidate("throne")
	await settle()
	expect(game.build_pick_mode and str(game.rooms.throne.facility_role) != "treasure","fixed room rejects construction")
	game.build_placement.select_candidate(room_id)
	await settle()
	expect(str(game.rooms.treasure.facility_role) == "build_slot" and str(game.rooms[room_id].facility_role) == "treasure","unique move keeps existing relocation rules")
	game._undo_last_management_placement()
	await settle()
	prepare("tactics")
	await settle()
	await click("GlobalDirective_survival")
	expect(game.global_directive == "survival","one policy click uses existing setter")
	game.story_feature_enabled = true
	game._set_screen("management",false)
	await settle()
	expect(control("StoryDialogueAlarmButton") != null,"existing optional story entry remains reachable")
	game.story_feature_enabled = false
	prepare()
	await settle()
	await click("MonsterManagementButton")
	expect(game.current_screen == "monster","monster is direct dock navigation")
	prepare()
	game._open_intrusion_brief()
	await settle()
	expect(game.current_screen == "management","automatic forecast joins management")
	await click("OpenIntrusionBriefButton")
	expect(game.current_screen == "intrusion_brief" and control("IntrusionRouteLabel") != null,"full forecast remains reachable")
	await click("EnterPlacementButton")
	expect(game.current_screen == "management","forecast returns to management")
	await click("StartCombatButton")
	expect(game.current_screen == "defense_start" and is_equal_approx(game.defense_start_remaining,3),"production start enters three second countdown")
	var locked: Dictionary = game.rooms.duplicate(true)
	game.build_placement.begin("barracks",Vector2(500,500))
	await point_click(game.get_global_transform_with_canvas()*game.graph.center(room_id))
	expect(game.rooms == locked and not game.build_pick_mode,"countdown locks placement input")
	game.pause_menu_open = true
	game._tick_defense_start_countdown(1)
	expect(is_equal_approx(game.defense_start_remaining,3),"menu pauses countdown")
	game.pause_menu_open = false
	await click("CancelDefenseStartButton")
	expect(game.current_screen == "management" and game.pending_precombat_snapshot.is_empty(),"cancel returns with snapshot discarded")
	game._request_combat_start()
	await settle()
	await key(KEY_ESCAPE)
	expect(game.current_screen == "management","escape cancels countdown")
	game._request_combat_start()
	await settle()
	game._tick_defense_start_countdown(2)
	expect(game.current_screen == "defense_start" and is_equal_approx(game.defense_start_remaining,1),"two seconds remain locked")
	game._tick_defense_start_countdown(1)
	await settle()
	expect(game.current_screen == "combat" and game.pending_precombat_snapshot.is_empty(),"three seconds commits combat once")

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").replace("\\","/").contains("/tmp/v1213_u5b/"),"isolated profile")
	if not failures.is_empty(): get_tree().quit(2); return
	capture_only = OS.get_cmdline_user_args().has("--capture-only")
	probe = OS.get_cmdline_user_args().has("--probe")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-filter="): capture_filter = arg.trim_prefix("--capture-filter=").split(",")
		if arg.begins_with("--output-dir="): out = arg.trim_prefix("--output-dir=")
	GameState.reset()
	LanguageSettings.set_locale("ko",false)
	game = GameScene.instantiate()
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false; game.campaign_save_v5_enabled = false
	add_child(game)
	await settle()
	game.set_process(false); game.set_physics_process(false)
	if not capture_only: await interactions()
	for size in [Vector2i(1920,1080),Vector2i(1280,720)]:
		get_window().size = size
		await settle()
		for locale in ["ko","en","zh_CN"]:
			LanguageSettings.set_locale(locale,false)
			if probe and (size.x != 1920 or locale != "ko"): continue
			await states("%s_%dx%d_" % [locale,size.x,size.y],true)
	var result := {"checks":checks,"failures":failures,"screens":screens,"capture_count":screens.size() if capture_only else 0}
	var file := FileAccess.open(out.path_join("capture_result.json" if capture_only else "contract_result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")); file.close()
	game.queue_free()
	await settle()
	print("U5-B checks=%d failures=%d captures=%d" % [checks,failures.size(),screens.size() if capture_only else 0])
	get_tree().quit(0 if failures.is_empty() else 1)
