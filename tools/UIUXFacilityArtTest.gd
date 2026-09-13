extends "res://tools/UIUXBuildPlacementTest.gd"
const PROPS := {"treasure":"treasure_pile_large","recovery":"recovery_nest_f","watch_post":"watch_post"}
const FACILITIES := ["treasure","recovery","watch_post"]
var phase := "after"
var evidence: Array = []

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): phase = args[0]
	output = "res://tmp/uiux_facilities_20260913/"+phase
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
	if phase == "after": _check_native_assets()
	var initial_rooms: Dictionary = game.rooms.duplicate(true)
	var initial_roster: Dictionary = game.monster_roster.duplicate(true)
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale_value in [0.9,1.0,1.15]:
			UISettings.text_scale = scale_value
			game.rooms = initial_rooms.duplicate(true)
			game.monster_roster = initial_roster.duplicate(true)
			game.castle_art_stage = "stage_02_castle"
			game._sync_castle_stage_content()
			game._refresh_quarter_map_from_rooms()
			game.management_context_drawer_open = false
			game.management_tool_tab = "build"
			game._set_screen(Constants.SCREEN_MANAGEMENT)
			await settle()
			var prefix := "%dx%d_%d" % [resolution.x,resolution.y,roundi(scale_value*100)]
			await capture(prefix+"_overview")
			for facility in FACILITIES:
				var targets := {}
				for id in game.rooms:
					if game._evaluate_facility_placement(str(id),facility).ok:
						var facing: String = game.graph._object_facing_for_instance(str(id),facility)
						if not targets.has(facing): targets[facing] = str(id)
				check(not targets.is_empty(),prefix+" "+facility+" has real valid construction candidates")
				print("FACILITY_ACTUAL_ROOM_FACINGS ",facility," ",targets)
				for facing in targets:
					await _exercise(facility,str(targets[facing]),str(facing),prefix+"_"+facility+"_"+str(facing))
	# Stage overrides must still resolve their actual stage and facing without inventing new art.
	DisplayServer.window_set_size(Vector2i(1920,1080))
	UISettings.text_scale = 1.0
	for stage in ["stage_01_cave","stage_03_keep","stage_04_citadel"]:
		game.rooms = initial_rooms.duplicate(true)
		game.monster_roster = initial_roster.duplicate(true)
		game.castle_art_stage = stage
		game._sync_castle_stage_content()
		game._refresh_quarter_map_from_rooms()
		game._set_screen(Constants.SCREEN_MANAGEMENT)
		await settle()
		for facility in FACILITIES:
			for id in game.rooms:
				if not game._can_change_room_facility(str(id)): continue
				var facing: String = game.graph._object_facing_for_instance(str(id),facility)
				var visual: Dictionary = game.quarter_renderer.facility_visual(str(id),facility)
				_check_visual_path(visual,facility,facing,stage+" "+str(id))
		await capture(stage+"_overview")
	print("FACILITY_TEXTURE_MEMORY_BYTES ", Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	game.queue_free()
	await settle()
	var file := FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase":phase,"checks":checks,"failed":failed,"cases":evidence},"\t"))
	file.close()
	print("UIUX_FACILITY_ART_TEST: %s (%d checks)" % ["FAIL" if failed else "PASS",checks])
	get_tree().quit(1 if failed else 0)

func _check_native_assets() -> void:
	var hashes := {}
	for facility in FACILITIES:
		for facing in ["NW","NE","SE","SW"]:
			var path: String = "res://assets/props/uiux/"+facility+"_"+facing+".png"
			check(ResourceLoader.exists(path),facility+" "+facing+" runtime resource exists")
			if not ResourceLoader.exists(path): continue
			var im := (load(path) as Texture2D).get_image()
			check(im != null and im.get_format() == Image.FORMAT_RGBA8,facility+" "+facing+" native RGBA")
			if im == null: continue
			check(im.get_width() >= 800 and im.get_height() >= 800,facility+" "+facing+" detailed native source")
			check(im.get_pixel(0,0).a == 0 and im.get_pixel(im.get_width()-1,0).a == 0 and im.get_pixel(0,im.get_height()-1).a == 0 and im.get_pixel(im.get_width()-1,im.get_height()-1).a == 0,facility+" "+facing+" transparent corners")
			var transparent := 0
			var solid := 0
			for y in range(0,im.get_height(),16):
				for x in range(0,im.get_width(),16):
					if im.get_pixel(x,y).a == 0: transparent += 1
					if im.get_pixel(x,y).a > 0.9: solid += 1
			check(transparent > 100 and solid > 100,facility+" "+facing+" alpha cutout and visible facility")
			var source: String = "res://assets/source/imagegen/uiux_facilities_20260913/"+facility+"_"+facing+".png"
			var hash_value := FileAccess.get_sha256(path)
			check(FileAccess.get_sha256(source) == hash_value,facility+" "+facing+" unchanged native output")
			check(not hashes.has(hash_value),facility+" "+facing+" independent facing asset")
			hashes[hash_value] = path

func _expected_path(facility: String, facing: String) -> String:
	var prop: Dictionary = DataRegistry.quarter_asset_manifest.props[PROPS[facility]]
	var stage: Dictionary = prop.get("stage_facing_sprites",{}).get(game.castle_art_stage,{}).get(facing,{})
	if stage.has("front"): return "res://"+str(stage.front)
	return "res://"+str(prop.facing_sprites[facing].front)

func _check_visual_path(visual: Dictionary, facility: String, facing: String, label: String) -> void:
	check(not visual.texture_keys.is_empty(),label+" "+facility+" has live composition")
	if visual.texture_keys.is_empty(): return
	var tex: Texture2D = game.quarter_renderer.object_sprite_textures.get(visual.texture_keys[0])
	check(tex != null and tex.resource_path == _expected_path(facility,facing),label+" "+facility+" exact manifest stage and facing")

func _exercise(facility: String, room_id: String, facing: String, tag: String) -> void:
	var before := state()
	game._open_build_palette_for_room(room_id)
	await drag_card(facility,world(game.graph.center(room_id)))
	await settle()
	var card: Node = game.ui_layer.find_child("FacilityCard_"+facility,true,false)
	var preview_node: Node
	for child in card.get_children():
		if "visual" in child: preview_node = child
	var visual: Dictionary = game.quarter_renderer.facility_visual(room_id,facility)
	_check_visual_path(visual,facility,facing,tag)
	check(preview_node != null and preview_node.visual.objects == visual.objects and preview_node.visual.texture_keys == visual.texture_keys,tag+" live card exact composition")
	check(game.build_placement.ghost.visual.objects == visual.objects and game.build_placement.ghost.visual.texture_keys == visual.texture_keys,tag+" ghost exact composition")
	check(state() == before,tag+" drag is read-only")
	await check_ghost_pixels(tag)
	await capture(tag+"_drag")
	mouse(world(game.graph.center(room_id)),false)
	await settle()
	check(game.build_preview_room_id == room_id and state() == before,tag+" drop selects candidate without state changes")
	await capture(tag+"_review")
	var confirm := game.ui_layer.find_child("ConfirmFacilityReplacementButton",true,false) as Button
	check(confirm != null and not confirm.disabled,tag+" local confirm reachable")
	if confirm == null or confirm.disabled: return
	var point := confirm.get_global_rect().get_center()
	mouse(point,true)
	mouse(point,false)
	await settle()
	check(str(game.rooms[room_id].get("facility_role","")) == facility,tag+" actual confirmation installs facility")
	var cost: Dictionary = game._facility_definition(facility).cost
	check(int(GameState.gold) == int(before.gold)-int(cost.get("gold",0)) and int(GameState.mana) == int(before.mana)-int(cost.get("mana",0)),tag+" charges exact existing cost once")
	var live: Array = []
	for slot in game.graph.debug_object_slots():
		if str(slot.get("instance_id","")) == room_id: live.append(slot)
	check(live == visual.objects,tag+" installation matches preview stage facing composition")
	check(game.quarter_renderer.facility_visual(room_id,facility).texture_keys == visual.texture_keys,tag+" installation uses identical art")
	if game.UNIQUE_FACILITIES.has(facility):
		check(game._rooms_by_facility(facility).size() == 1,tag+" unique facility rule preserved")
	check(not game._confirm_build_preview(),tag+" duplicate confirmation blocked")
	await capture(tag+"_installed")
	check(game._undo_last_management_placement(),tag+" existing Undo runs")
	await settle()
	check(state() == before,tag+" Undo restores resources rooms monsters paths tutorial")
	if tag.begins_with("1920x1080_100"):
		await capture(tag+"_undo")
	game._open_build_palette_for_room(room_id)
	game._set_build_facility(facility)
	await settle()
	key(KEY_ESCAPE)
	await settle()
	check(state() == before and not game.build_pick_mode,tag+" ESC cancel costs nothing")
	if tag.begins_with("1920x1080_100"):
		await capture(tag+"_cancel")
	evidence.append({"tag":tag,"room":room_id,"facility":facility,"facing":facing,"path":_expected_path(facility,facing),"restored":state()==before})
