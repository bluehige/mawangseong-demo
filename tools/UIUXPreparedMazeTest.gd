extends "res://tools/UIUXU4InteractionTest.gd"
const Save = preload("res://scripts/core/CampaignSaveStore.gd")
const Actor = preload("res://scripts/units/Unit.gd")
var output := "res://tmp/uiux_prepared_maze_20260913/after"
const MAZE := "prepared_maze_growth_01"
const OLD := "stage01_dual_front_candidate_01"
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	game=Game.instantiate()
	add_child(game)
	await settle()
	game.campaign_save_enabled=false
	game._debug_skip_onboarding()
	game.onboarding_enabled=false
	game.tutorial_gate_enabled=false
	game.story_feature_enabled=false
	game.combat_speed_intro_seen=true
	GameState.day=2
	GameState.player_name="미궁 검증"
	game._choose_early_specialization("goblin","goblin_treasure_hunter")
	expect(DataRegistry.quarter_default_layout_id==MAZE and game.quarter_layout_id==MAZE,"new game uses prepared maze")
	for day in range(1,6):
		expect(DataRegistry.wave_catalog_for_layout(MAZE,day,DataRegistry.waves)==DataRegistry.wave_catalog_for_layout(OLD,day,DataRegistry.waves),"existing wave counts and balance preserved day %d"%day)
	var base_origins: Dictionary={}
	for stage in DataRegistry.castle_evolution_stage_ids():
		set_stage(stage)
		geometry(stage,base_origins)
		save_round_trip(stage)
		if stage=="stage_01_cave":
			for id in game.graph.module_instance_ids(): base_origins[id]=game.graph.placed_module_data(id).grid_origin
	# Optional heart room follows the existing update3 unlock, with both connected socket lanes.
	game.update3_active_run["front_selection_completed"]=true
	game.update3_active_run["front_id"]="front_royal_inquisition"
	set_stage("stage_02_castle")
	expect(game.graph.module_instance_ids().has("heart_chamber"),"heart content retained under its own unlock")
	expect(game.graph.validation_summary().ok,"optional heart preserves graph validation")
	check_walk(game.graph.center("entrance"),game.graph.center("heart_chamber"),"optional heart")
	game.update3_active_run.clear()
	for resolution in ([] if "--logic-only" in OS.get_cmdline_user_args() else [Vector2i(1920,1080),Vector2i(1280,720)]):
		DisplayServer.window_set_size(resolution)
		for scale in [0.9,1.0,1.15]:
			UISettings.text_scale=scale
			for stage in DataRegistry.castle_evolution_stage_ids():
				set_stage(stage)
				game.management_context_drawer_open=false
				game._set_management_tool_tab("roster")
				await settle(5)
				var tag:="%dx%d_%d_%s"%[resolution.x,resolution.y,roundi(scale*100),stage]
				expect(game.quarter_renderer.maze_arch_draw_count>0,tag+" real arch sprites drawn")
				await shot(tag+"_management")
				await click(node("ManagementTab_tactics"))
				expect(node("MazeRouteOption")!=null,tag+" route selector present")
				expect(not game.management_context_drawer_open,tag+" tactics starts with unobscured map")
				var option:=node("MazeRouteOption") as OptionButton
				expect(option.item_count==game.maze_route_forecasts.size(),tag+" only actual forecast groups offered")
				for route in game.maze_route_forecasts:
					check_walk(game.graph.center(route.spawn_room_id),game.graph.center(route.target_room_id),tag+str(route.id))
					var route_index: int=game.maze_route_forecasts.find(route)
					option.select(route_index)
					option.get_popup().id_pressed.emit(route_index)
					expect(game.maze_route_id==str(route.id),tag+" selected route matches the drawn path")
					await shot(tag+"_route_"+str(route.spawn_room_id)+"_to_"+str(route.target_room_id))
	DisplayServer.window_set_size(Vector2i(1920,1080))
	UISettings.text_scale=1.0
	set_stage("stage_02_castle")
	await tutorial_required_details()
	await route_keyboard_input()
	await roster_input()
	await connector_input()
	await combat_spawn()
	game.queue_free()
	await settle()
	var file:=FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions":count,"failed":failed,"captures":captures},"\t"));file.close()
	print("UIUX_PREPARED_MAZE_TEST: %s (%d assertions, %d captures)"%["FAIL" if failed else "PASS",count,captures.size()])
	get_tree().quit(1 if failed else 0)

func set_stage(stage: String) -> void:
	game.castle_art_stage=stage
	game.castle_evolution_history.assign(DataRegistry.castle_evolution_stage_ids().slice(0,DataRegistry.castle_evolution_stage_ids().find(stage)+1))
	game.rooms=DataRegistry.rooms.duplicate(true)
	game._init_room_facilities()
	game._sync_castle_stage_content()
	game._init_room_directives()
	game._refresh_quarter_map_from_rooms()
	game._set_screen(C.SCREEN_MANAGEMENT)

func geometry(stage: String, origins: Dictionary) -> void:
	expect(game.graph.validation_summary().ok,stage+" valid modules, paired sockets, bounds and required routes")
	for id in origins: expect(game.graph.placed_module_data(id).grid_origin==origins[id],stage+" existing room position retained "+id)
	for id in game.graph.module_instance_ids():
		check_walk(game.graph.center("entrance"),game.graph.center(id),stage+" walk to "+id)
	var snapshot: Dictionary=game.combat_scene.build_precombat_snapshot(false)
	var entries: Dictionary={}
	for value in snapshot.schedule: entries[value.spawn_room_id]=true
	expect(entries.size()==(1 if stage=="stage_01_cave" else 2),stage+" actual scheduled enemies use unlocked entrances")
	if stage=="stage_01_cave": expect(not game.graph.module_instance_ids().has("outside_approach_b"),"side entry closed at stage 1")
	else:
		var used_rooms: Array=[]
		for point in game.graph.path_to_point(game.graph.center("service_entrance"),game.graph.center("throne")):
			var id: String=game.graph.exact_room_at_world(point)
			if not used_rooms.has(id): used_rooms.append(id)
		print("SIDE_WALK ",stage," ",used_rooms)
		expect(used_rooms.has("lane_b_merge") and not used_rooms.has("entrance"),stage+" side gate has a real distinct approach")
	var closed_cell:=Vector2i(25,14)
	expect(not game.graph.debug_walk_cells().has(closed_cell),stage+" paid sally port excluded from enemy floor")
	print("MAZE_GEOMETRY ",stage," ",game.graph.validation_summary())

func check_walk(start: Vector2, target: Vector2, label: String) -> void:
	var wm=game.graph.walk_map
	var first: Vector2i=wm.get_nearest_walkable_cell(start)
	var last: Vector2i=wm.get_nearest_walkable_cell(target)
	var cells: Array=wm._edge_constrained_path(first,last)
	expect(not cells.is_empty(),label+" reachable without direct-line fallback")
	var points: Array=game.graph.path_to_point(start,target)
	var previous: Vector2i=first
	for point in points:
		var cell: Vector2i=wm.world_to_cell(point)
		expect(wm.walkable_cells.has(cell),label+" stays on walkable floor")
		var delta:=cell-previous
		expect(absi(delta.x)+absi(delta.y)<=1,label+" no jump through wall")
		if delta!=Vector2i.ZERO:
			var side:="E" if delta.x==1 else ("W" if delta.x==-1 else ("S" if delta.y==1 else "N"))
			expect(wm.open_edge_set.has(wm._edge_key(previous,side)),label+" uses open physical edge")
		previous=cell
	expect(previous==last,label+" reaches intended target")

func save_round_trip(stage: String) -> void:
	var original_day:=GameState.day
	GameState.day=int({"stage_01_cave":2,"stage_02_castle":16,"stage_03_keep":21,"stage_04_citadel":28}[stage])
	game.campaign_stage_two_unlock_ready=true
	game.campaign_chapter_three_clear=true
	game.campaign_final_upgrade_ready=true
	for id in [OLD,MAZE]:
		game.quarter_layout_id=id
		set_stage(stage)
		var payload: Dictionary=game._campaign_save_payload(C.SCREEN_MANAGEMENT)
		var before: Dictionary=payload.world.quarter_layout.duplicate(true)
		var path: String="user://maze_compat_"+id+".json"
		var written: Dictionary=Save.write(payload,game._campaign_save_summary(C.SCREEN_MANAGEMENT),path)
		expect(written.ok,stage+" save write "+id+" "+str(written))
		var loaded: Dictionary=Save.inspect(path)
		expect(loaded.status==Save.STATUS_VALID,stage+" serialized save valid "+id)
		if written.ok and loaded.status==Save.STATUS_VALID:
			expect(game._restore_campaign_payload(loaded.payload),stage+" save restore "+id)
			expect(game.quarter_layout_id==id and DataRegistry.quarter_layout(id)==before,stage+" saved topology preserved "+id)
			expect(game.graph.validation_summary().ok,stage+" restored graph valid "+id)
		expect(DataRegistry.quarter_default_layout_id==MAZE,"loading old save cannot replace new-game default")

	GameState.day=original_day

func tutorial_required_details() -> void:
	var steps: Array=game.tutorial_manager.steps.duplicate(true)
	var state: Dictionary=game.tutorial_manager.export_state()
	var stage: String=game.onboarding_stage_id
	for id in ["TUT_120_TRAP_LURE","TUT_220_RETREAT_LINE"]:
		for step in steps:
			if str(step.id)!=id:continue
			game.tutorial_manager.setup([step])
			game.onboarding_stage_id=str(step.stage)
			game.onboarding_enabled=true
			game._set_management_tool_tab("tactics")
			await settle()
			expect(game.management_context_drawer_open,"required tutorial opens room details "+id)
			var target: Dictionary=game.tutorial_targets.get(str(step.focus),{})
			expect(is_instance_valid(target.get("control")),"required tutorial resolves its real directive control "+id)
	game.onboarding_enabled=false
	game.onboarding_stage_id=stage
	game.tutorial_manager.setup(steps)
	game.tutorial_manager.current_index=int(state.current_index)
	game.tutorial_manager.completed=state.completed
	game.tutorial_manager.active=bool(state.active)

func route_keyboard_input() -> void:
	game._set_management_tool_tab("tactics")
	await settle()
	var option:=node("MazeRouteOption") as OptionButton
	option.select(0)
	option.get_popup().id_pressed.emit(0)
	option.grab_focus()
	await key(KEY_ENTER)
	var popup:=option.get_popup()
	expect(popup.visible,"keyboard opens actual route popup")
	for code in [KEY_DOWN,KEY_ENTER]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true;event.window_id=popup.get_window_id()
		get_viewport().push_input(event,true)
		event=event.duplicate();event.pressed=false
		get_viewport().push_input(event,true)
		await settle()
		if code == KEY_DOWN: expect(popup.get_focused_item() == 1,"Down moves the real popup focus to the next route")
	expect(game.maze_route_id==str(game.maze_route_forecasts[1].id),"popup keyboard selection updates the actual route")
	await shot("route_01_keyboard_selection")

func roster_input() -> void:
	GameState.day=2
	game._set_management_tool_tab("roster")
	await settle()
	var before: Dictionary=game.monster_roster.duplicate(true)
	var economy:=[GameState.gold,GameState.mana]
	var card:=node("MonsterCard_goblin") as Button
	mouse(card.get_global_rect().get_center(),true)
	await settle()
	var target: Vector2=game.get_global_transform_with_canvas()*game.graph.center("lane_b_rear")
	motion(target)
	await settle()
	expect(game.roster_monster_drag_active,"actual roster press starts drag")
	expect(game.drag_hover_room=="lane_b_rear","native pointer keeps the live ghost on the intended guard zone")
	expect(game.monster_roster==before,"drag preview preserves placement")
	await shot("roster_01_drag_to_sally_port")
	mouse(target,false)
	await settle()
	expect(game.monster_roster.goblin.assigned_defense_zone_id=="zone_b_rear","GUI drop sets existing zone field")
	expect(game.monster_roster.goblin.room==before.goblin.room and [GameState.gold,GameState.mana]==economy,"guard placement preserves home room and economy")
	expect(game.maze_deployments.goblin.room_id=="lane_b_rear","preview and battle plan use selected actual corridor")
	await shot("roster_02_placed")
	var undo_before: Dictionary=game.management_undo.duplicate(true)
	expect(game._assign_monster_to_room("goblin","lane_b_rear"),"same zone input is acknowledged")
	expect(game.management_undo==undo_before,"duplicate zone input preserves the previous undo")
	expect(game._undo_last_management_placement(),"existing undo accepts guard placement")
	await settle()
	expect(game.monster_roster==before,"undo restores complete original roster")
	await shot("roster_03_undo")
	game._begin_management_roster_drag("goblin")
	await key(KEY_ESCAPE)
	expect(game.monster_roster==before and game.dragging_monster_id=="","ESC cancels guard drag without changing placement")
	var old_roster: Dictionary=game.monster_roster.duplicate(true)
	for id in ["slime","goblin","imp"]:
		game.monster_roster[id]["assigned_defense_zone_id"]="zone_b_rear"
		game.monster_roster[id]["defense_zone_id"]="zone_b_rear"
	game.monster_roster["kobold_scout"]={"level":1,"exp":0,"bond":0,"room":"barracks"}
	var full_roster: Dictionary=game.monster_roster.duplicate(true)
	expect(not game._assign_monster_to_room("kobold_scout","lane_b_rear"),"existing three-slot guard zone rejects fourth defender")
	expect(game.monster_roster==full_roster,"capacity rejection preserves assignments")
	expect(not game._assign_monster_to_room("kobold_scout","treasure"),"facility shortcut also respects the same guard-zone capacity")
	game.monster_roster=old_roster
	game._set_screen(C.SCREEN_MANAGEMENT)
	await settle()
	card=node("MonsterCard_goblin")
	card.grab_focus()
	await key(KEY_ENTER)
	expect(game.deploy_pick_monster_id=="goblin","keyboard card selection starts click placement")
	target=game.get_global_transform_with_canvas()*game.graph.center("lane_b_front")
	mouse(target,true);mouse(target,false)
	await settle()
	expect(game.monster_roster.goblin.assigned_defense_zone_id=="zone_b_front","click alternative assigns same existing zone contract")
	await shot("roster_04_keyboard_click")
	GameState.day=16
	var saved: Dictionary=game._campaign_save_payload(C.SCREEN_MANAGEMENT)
	expect(game._restore_campaign_payload(saved),"zone placement save restores")
	expect(game.monster_roster.goblin.assigned_defense_zone_id=="zone_b_front","saved assigned zone retained")

func connector_input() -> void:
	GameState.day=2;GameState.gold=1500;GameState.mana=200
	expect(not game._build_v122_defender_connector(),"sally port locked before day 3")
	expect([GameState.gold,GameState.mana]==[1500,200],"locked sally port spends nothing")
	GameState.day=3
	game._set_management_tool_tab("tactics")
	await settle()
	var floor_before: Dictionary=game.graph.debug_walk_cells().duplicate(true)
	await click(node("ManagementContextAction_defender_connector"))
	expect(game.v122_connector_state.get("built",false),"actual sally port button restores connector")
	expect([GameState.gold,GameState.mana]==[500,100],"existing 1000 gold / 100 mana cost once")
	var contract: Dictionary=game._v122_defender_connector()
	var anchor:=Vector2(contract.world_anchor[0],contract.world_anchor[1])
	expect(not game.graph.is_walkable(anchor) and game.graph.debug_walk_cells()==floor_before,"restoration never opens enemy navigation")
	var defender=Actor.new();defender.faction=C.FACTION_MONSTER;game.add_child(defender);defender.set_physics_process(false)
	var enemy=Actor.new();enemy.faction=C.FACTION_ENEMY;game.add_child(enemy);enemy.set_physics_process(false)
	var start: Vector2=game.graph.center("lane_a_rear")
	var goal: Vector2=game.graph.center("lane_b_rear")
	var friendly: Array=game.combat_scene._path_from_world_to_room(start,"lane_b_rear",defender)
	var hostile: Array=game.combat_scene._path_from_world_to_room(start,"lane_b_rear",enemy)
	expect(friendly.has(anchor) and not hostile.has(anchor),"only defender runtime path traverses restored sally port")
	check_walk(start,goal,"enemy still follows open corridors around port")
	defender.queue_free();enemy.queue_free()
	await shot("sally_port_01_restored")
	expect(not game._build_v122_defender_connector() and [GameState.gold,GameState.mana]==[500,100],"duplicate restoration is free and rejected")
	expect(game._undo_last_management_placement(),"sally port uses existing undo")
	expect(not game.v122_connector_state.get("built",false) and [GameState.gold,GameState.mana]==[1500,200],"undo restores closed port and both resources")
	await shot("sally_port_02_undo")

func combat_spawn() -> void:
	GameState.day=2
	game._set_screen(C.SCREEN_MANAGEMENT)
	await settle()
	var preview: Dictionary=game.maze_deployments.duplicate(true)
	var snapshot: Dictionary=game.combat_scene.build_precombat_snapshot(false)
	game._start_combat()
	game.combat_scene.set_pause_state(true,false)
	expect(game.current_screen==C.SCREEN_COMBAT,"actual defense flow starts on new maze")
	for unit in game.monster_units:
		expect(preview.has(unit.unit_id),"defender preview exists")
		if preview.has(unit.unit_id): expect(unit.global_position.distance_to(preview[unit.unit_id].position)<0.1,"defender preview equals actual battle spawn "+unit.unit_id)
	for entry in snapshot.schedule:
		game.combat_scene.spawn_enemy(entry.enemy_id,entry)
		var unit=game.enemy_units.back()
		unit.set_physics_process(false)
		expect(unit.goal_room==entry.target_room_id,"actual enemy goal agrees with forecast "+unit.unit_id)
		expect(unit.get_meta("v122_spawn_room_id","")==entry.spawn_room_id,"actual enemy uses forecast entrance "+unit.unit_id)
		check_walk(unit.global_position,game.graph.center(unit.goal_room),"actual "+unit.unit_id)
	await shot("combat_01_real_defenders_and_enemy_goals")

func mouse(point: Vector2,pressed: bool) -> void:
	Input.warp_mouse(point)
	var e:=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
	get_viewport().push_input(e,true)
func motion(point: Vector2) -> void:
	Input.warp_mouse(point)
	var e:=InputEventMouseMotion.new();e.position=point;e.global_position=point;e.button_mask=MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(e,true)
func shot(id: String) -> void:
	game.queue_world_overlay_redraw()
	await settle(3)
	var path:=output.path_join(id+".png")
	expect(get_viewport().get_texture().get_image().save_png(path)==OK,id+" capture")
	captures.append(path)
