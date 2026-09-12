extends "res://tools/UIUXBuildPlacementTest.gd"
const STAGES := ["stage_01_cave","stage_02_castle","stage_03_keep","stage_04_citadel"]
const LANDMARK_PROPS := ["entrance_gate_f","throne_f","foundation_marks"]
const ART_IDS := ["entrance_stage01_SE","entrance_stage02_SE","entrance_stage03_SE","entrance_stage04_SE","throne_stage01_SW","throne_stage02_SW","throne_stage03_SW","throne_stage04_SW","foundation_stage01_NE","foundation_stage02_NE","foundation_common_NW","foundation_stage03_NE","foundation_stage04_NE","entrance_common_NE","foundation_common_SE"]
var phase := "after"
var evidence: Array = []

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): phase = args[0]
	var combat_only := args.has("combat_only")
	output = "res://tmp/uiux_landmarks_20260913/"+phase
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
	var rooms_before: Dictionary = game.rooms.duplicate(true)
	var roster_before: Dictionary = game.monster_roster.duplicate(true)
	if phase == "after": _check_assets()
	var management_resolutions: Array = [] if combat_only else [Vector2i(1920,1080),Vector2i(1280,720)]
	for resolution in management_resolutions:
		DisplayServer.window_set_size(resolution)
		for text_scale in [0.9,1.0,1.15]:
			UISettings.text_scale = text_scale
			for stage in STAGES:
				game._clear_management_action_mode(false)
				game.rooms = rooms_before.duplicate(true)
				game.monster_roster = roster_before.duplicate(true)
				game.castle_art_stage = stage
				game._sync_castle_stage_content()
				game._refresh_quarter_map_from_rooms()
				game.management_context_drawer_open = false
				game.management_tool_tab = "build"
				game._set_screen(Constants.SCREEN_MANAGEMENT)
				await settle()
				var tag := "%dx%d_%d_%s" % [resolution.x,resolution.y,roundi(text_scale*100),stage]
				if phase == "after": await _check_map_fit(tag)
				_check_live_art(tag)
				await capture(tag+"_map")
				var before := state()
				for id in ["entrance","service_entrance","throne"]:
					check(not game._can_change_room_facility(id),tag+" fixed room "+id)
					check(not game._evaluate_facility_placement(id,"watch_post").ok,tag+" rejects construction "+id)
					check(state() == before,tag+" fixed rejection read-only "+id)
				game._select_room("throne")
				await settle()
				check(game.selected_room == "throne" and state() == before,tag+" throne detail read-only")
				await capture(tag+"_throne")
				game.management_context_drawer_open = false
				game._set_screen(Constants.SCREEN_MANAGEMENT)
				await settle()
				var targets := {}
				for id in game.rooms:
					if str(game.rooms[id].get("facility_role","")) != "build_slot": continue
					if not game._evaluate_facility_placement(str(id),"watch_post").ok: continue
					var facing: String = game.graph._object_facing_for_instance(str(id),"build_slot")
					if not targets.has(facing): targets[facing] = str(id)
				check(not targets.is_empty(),tag+" real empty construction slots")
				for facing in targets:
					await _exercise_empty(str(targets[facing]),tag+"_"+str(facing))
				await _exercise_clear(tag)
				evidence.append({"tag":tag,"slots":targets})
	# Actual battle startup uses the same landmarks and existing actor layers.
	UISettings.text_scale = 1.0
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for stage in STAGES:
			game.rooms = rooms_before.duplicate(true)
			game.monster_roster = roster_before.duplicate(true)
			game.castle_art_stage = stage
			game._sync_castle_stage_content()
			game._refresh_quarter_map_from_rooms()
			game._set_screen(Constants.SCREEN_MANAGEMENT)
			game.combat_speed_intro_seen = true
			game._start_combat()
			await settle(60)
			check(game.current_screen == Constants.SCREEN_COMBAT,stage+" actual combat startup")
			game.combat_scene.set_pause_state(true,false)
			game._clear_combat_unit_selection()
			await settle()
			_check_live_art(stage+"_combat")
			await capture("%dx%d_100_%s_combat" % [resolution.x,resolution.y,stage])
			if not game.monster_units.is_empty():
				var actor: Node2D = game.monster_units[0]
				actor.global_position = game.graph.center("throne") + Vector2(0,12)
				actor.refresh_depth_slot()
				check(actor.z_index >= 1 and actor.z_index <= 44,stage+" throne overlap retains actor depth")
				await capture("%dx%d_100_%s_throne_overlap" % [resolution.x,resolution.y,stage])
			game._set_screen(Constants.SCREEN_MANAGEMENT)
			await settle()
	print("LANDMARK_TEXTURE_MEMORY_BYTES ",Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	game.queue_free()
	await settle()
	var file := FileAccess.open(output.path_join("combat_results.json" if combat_only else "results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase":phase,"checks":checks,"failed":failed,"cases":evidence},"\t"))
	file.close()
	print("UIUX_LANDMARK_TEST: %s (%d checks)" % ["FAIL" if failed else "PASS",checks])
	get_tree().quit(1 if failed else 0)

func _check_assets() -> void:
	var hashes := {}
	for id in ART_IDS:
		var path: String = "res://assets/props/uiux/"+id+".png"
		var tex := load(path) as Texture2D
		check(tex != null,id+" runtime texture exists")
		if tex == null: continue
		var im := tex.get_image()
		check(im.get_format() == Image.FORMAT_RGBA8,id+" native RGBA")
		check(im.get_width() >= 800 and im.get_height() >= 800,id+" native resolution preserved")
		check(im.has_mipmaps(),id+" actual imported mipmaps")
		check(im.get_pixel(0,0).a == 0 and im.get_pixel(im.get_width()-1,0).a == 0 and im.get_pixel(0,im.get_height()-1).a == 0 and im.get_pixel(im.get_width()-1,im.get_height()-1).a == 0,id+" corners transparent")
		var alpha_zero := 0
		var opaque := 0
		for y in range(0,im.get_height(),16):
			for x in range(0,im.get_width(),16):
				var alpha := im.get_pixel(x,y).a
				if alpha == 0: alpha_zero += 1
				if alpha > 0.9: opaque += 1
		check(alpha_zero > 100 and opaque > 100,id+" meaningful cutout and visible object")
		var hash_value := FileAccess.get_sha256(path)
		check(hash_value == FileAccess.get_sha256("res://assets/source/imagegen/uiux_landmarks_20260913/"+id+".png"),id+" unchanged native source")
		check(not hashes.has(hash_value),id+" distinct stage asset")
		hashes[hash_value] = true

func _check_live_art(tag: String) -> void:
	var counts := {}
	for slot in game.graph.debug_object_slots():
		var prop_id := str(slot.get("id",""))
		if prop_id not in LANDMARK_PROPS: continue
		counts[prop_id] = int(counts.get(prop_id,0))+1
		var facing := str(slot.get("facing",""))
		var prop: Dictionary = DataRegistry.quarter_asset_manifest.props[prop_id]
		var mapping: Dictionary = prop.get("stage_facing_sprites",{}).get(game.castle_art_stage,{}).get(facing,prop.facing_sprites.get(facing,{}))
		for layer in ["back","front"]:
			var key_value: String = game.quarter_renderer._object_texture_key_for_layer(slot,prop_id,layer)
			if not mapping.has(layer):
				if bool(mapping.get("_complete_override",false)):
					check(key_value == "",tag+" complete override suppresses "+prop_id+" "+layer)
				continue
			var tex: Texture2D = game.quarter_renderer.object_sprite_textures.get(key_value)
			check(tex != null and tex.resource_path == "res://"+str(mapping[layer]),tag+" exact stage/facing/layer "+prop_id+" "+facing+" "+layer)
			if phase == "after":
				check(str(mapping[layer]).begins_with("assets/props/uiux/"),tag+" live landmark uses remastered art")
			print("LANDMARK_ACTIVE_ART ",tag," ",str(slot.get("instance_id",""))," ",key_value," ",str(mapping[layer]))
		if phase == "after" and prop_id == "throne_f":
			check(game.quarter_renderer._object_texture_key_for_layer(slot,prop_id,"front") == "",tag+" complete throne has no duplicate foreground stairs")
	check(int(counts.get("entrance_gate_f",0)) == 2 and int(counts.get("throne_f",0)) == 1,tag+" existing two entries and fixed throne")

func _exercise_empty(room_id: String, tag: String) -> void:
	var before := state()
	mouse(world(game.graph.center(room_id)),true)
	mouse(world(game.graph.center(room_id)),false)
	await settle()
	check(game.selected_room == room_id and game.management_tool_tab == "build",tag+" empty slot click opens common toolbox")
	check(state() == before,tag+" shortcut does not mutate state")
	await capture(tag+"_empty")
	await drag_card("watch_post",world(game.graph.center(room_id)))
	check(state() == before,tag+" drag is read-only")
	await check_ghost_pixels(tag)
	mouse(world(game.graph.center(room_id)),false)
	await settle()
	check(game.build_preview_room_id == room_id and state() == before,tag+" drop only selects candidate")
	await capture(tag+"_review")
	var confirm := game.ui_layer.find_child("ConfirmFacilityReplacementButton",true,false) as Button
	check(confirm != null and not confirm.disabled,tag+" local confirmation reachable")
	if confirm == null or confirm.disabled:
		game._cancel_management_action_mode()
		return
	mouse(confirm.get_global_rect().get_center(),true)
	mouse(confirm.get_global_rect().get_center(),false)
	await settle()
	check(str(game.rooms[room_id].facility_role) == "watch_post",tag+" actual construction replaces foundation")
	var cost: Dictionary = game._facility_definition("watch_post").cost
	check(GameState.gold == before.gold-int(cost.get("gold",0)) and GameState.mana == before.mana-int(cost.get("mana",0)),tag+" existing cost once")
	await capture(tag+"_installed")
	check(game._undo_last_management_placement(),tag+" existing Undo")
	await settle()
	check(state() == before,tag+" Undo restores foundation economy roster connectors tutorial")
	await capture(tag+"_undo")
	game._open_build_palette_for_room(room_id)
	game._set_build_facility("watch_post")
	key(KEY_ESCAPE)
	await settle()
	check(state() == before and not game.build_pick_mode,tag+" ESC cancel without cost")

func _exercise_clear(tag: String) -> void:
	var before := state()
	game._open_build_palette_for_room("barracks")
	game._set_build_facility("build_slot")
	await settle()
	var visual: Dictionary = game.quarter_renderer.facility_visual("barracks","build_slot")
	check(not visual.texture_keys.is_empty(),tag+" SE clear preview exists")
	await capture(tag+"_clear_review")
	check(game._confirm_build_preview(),tag+" existing removal executes")
	await settle()
	check(str(game.rooms.barracks.facility_role) == "build_slot",tag+" SE foundation actually installed")
	check(game.quarter_renderer.facility_visual("barracks","build_slot").texture_keys == visual.texture_keys,tag+" clear preview equals actual foundation")
	await capture(tag+"_cleared")
	check(game._undo_last_management_placement(),tag+" clear Undo")
	await settle()
	check(state() == before,tag+" clear Undo restores displaced monsters and resources")
	game._cancel_management_action_mode()

func _check_map_fit(tag: String) -> void:
	var before := state()
	var fitted: Transform2D = game.get_viewport().canvas_transform
	var original: Transform2D = game.build_placement.view_before_focus
	check(game.build_placement.managed_view,tag+" management map fitted automatically")
	for id in game.rooms:
		if not game._can_change_room_facility(str(id)): continue
		var point := world(game.graph.center(str(id)))
		check(game.get_viewport().get_visible_rect().has_point(point) and not game._management_ui_at(point),tag+" real pointer can reach "+str(id))
	var button := game.ui_layer.find_child("FitManagementMapButton",true,false) as Button
	check(button != null and button.focus_mode == Control.FOCUS_ALL,tag+" keyboard focusable fit button")
	if button != null:
		var moved := fitted
		moved.origin += Vector2(80,50)
		game.get_viewport().canvas_transform = moved
		mouse(button.get_global_rect().get_center(),true)
		mouse(button.get_global_rect().get_center(),false)
		await settle()
		check(game.get_viewport().canvas_transform.is_equal_approx(fitted),tag+" actual fit button restores map framing")
	game.build_placement.pointer_active = true
	check(not game.build_placement.fit_workspace() and game.get_viewport().canvas_transform.is_equal_approx(fitted),tag+" no map movement during drag")
	game.build_placement.pointer_active = false
	game.build_placement.leave_management_view()
	check(game.get_viewport().canvas_transform.is_equal_approx(original),tag+" restores previous view when leaving management")
	game.build_placement.fit_workspace_if_needed()
	check(state() == before,tag+" map fit never mutates game state")
