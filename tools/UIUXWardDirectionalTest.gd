extends "res://tools/UIUXBuildPlacementTest.gd"
var evidence: Array = []
func _run() -> void:
	output = "res://tmp/uiux_secondary/ward"
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
	for stage in ["stage_03_keep","stage_04_citadel"]:
		var mapping: Dictionary = DataRegistry.quarter_asset_manifest.props.ward_core.stage_facing_sprites[stage]
		for facing in ["NE","SE","SW"]:
			var path := "res://"+str(mapping[facing].back)
			var im := (load(path) as Texture2D).get_image()
			check(im != null and im.get_format() == Image.FORMAT_RGBA8,stage+" "+facing+" native RGBA")
			check(im.get_pixel(0,0).a == 0 and im.get_pixel(im.get_width()-1,im.get_height()-1).a == 0,stage+" "+facing+" transparent outside")
			var transparent := 0
			var solid := 0
			for y in range(0,im.get_height(),8):
				for x in range(0,im.get_width(),8):
					if im.get_pixel(x,y).a == 0: transparent += 1
					if im.get_pixel(x,y).a > 0.9: solid += 1
			check(transparent > 2000 and solid > 1000,stage+" "+facing+" meaningful alpha cutout and visible building")
			var stem := "stage03" if stage == "stage_03_keep" else "stage04"
			var source: String = "res://assets/source/imagegen/uiux_ward_core_directions_20260912/"+stem+"_"+facing+".png"
			check(FileAccess.get_sha256(path) == FileAccess.get_sha256(source),stage+" "+facing+" runtime is unchanged native output")
			evidence.append({"stage":stage,"facing":facing,"path":path,"sha256":FileAccess.get_sha256(path),"transparent_samples":transparent,"solid_samples":solid})
	var initial_rooms: Dictionary = game.rooms.duplicate(true)
	var initial_roster: Dictionary = game.monster_roster.duplicate(true)
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale_value in [0.9,1.0,1.15]:
			UISettings.text_scale = scale_value
			for stage in ["stage_03_keep","stage_04_citadel"]:
				game.rooms = initial_rooms.duplicate(true)
				game.monster_roster = initial_roster.duplicate(true)
				game.castle_art_stage = stage
				game._sync_castle_stage_content()
				game._refresh_quarter_map_from_rooms()
				game._set_screen(Constants.SCREEN_MANAGEMENT)
				await settle()
				var targets := {}
				for id in game.rooms:
					if game._evaluate_facility_placement(str(id),"ward_core").ok:
						var facing: String = game.graph._object_facing_for_instance(str(id),"ward_core")
						if not targets.has(facing): targets[facing] = str(id)
				print("WARD_ACTUAL_ROOM_FACINGS ",stage," ",targets)
				check(targets.size() >= 3,stage+" current construction rooms expose their existing facings")
				for facing in targets:
					var target: String = targets[facing]
					var tag := "%dx%d_%d_%s_%s" % [resolution.x,resolution.y,roundi(scale_value*100),stage,facing]
					var before := state()
					game._open_build_palette_for_room(target)
					await drag_card("ward_core",world(game.graph.center(target)))
					await settle()
					var card: Node = game.ui_layer.find_child("FacilityCard_ward_core",true,false)
					var preview_node = card.get_child(0)
					for child in card.get_children():
						if "visual" in child: preview_node = child
					var preview: Dictionary = game.quarter_renderer.facility_visual(target,"ward_core")
					var texture_key := "propstage:ward_core:%s:%s:back" % [stage,facing]
					check(preview.texture_keys == [texture_key],tag+" selected room resolves exact facing asset")
					check(preview_node.visual.texture_keys == preview.texture_keys and game.build_placement.ghost.visual.texture_keys == preview.texture_keys,tag+" live card and ghost use identical asset")
					check(state() == before,tag+" review is read-only")
					await check_ghost_pixels(tag)
					await capture(tag+"_drag")
					mouse(world(game.graph.center(target)),false)
					await settle()
					check(game.build_preview_room_id == target,tag+" drop selects candidate only")
					await capture(tag+"_review")
					var confirm := game.ui_layer.find_child("ConfirmFacilityReplacementButton",true,false) as Button
					var point := confirm.get_global_rect().get_center()
					mouse(point,true)
					mouse(point,false)
					await settle()
					check(game.rooms[target].facility_role == "ward_core",tag+" actual confirmation installs ward")
					var live: Array = []
					for slot in game.graph.debug_object_slots():
						if str(slot.get("instance_id","")) == target: live.append(slot)
					check(live == preview.objects,tag+" installation has same composition and facing")
					check(game.quarter_renderer.facility_visual(target,"ward_core").texture_keys == preview.texture_keys,tag+" installed asset matches card and ghost")
					check(not game._confirm_build_preview(),tag+" duplicate confirm ignored")
					await capture(tag+"_installed")
					check(game._undo_last_management_placement(),tag+" existing Undo executes")
					await settle()
					check(state() == before,tag+" Undo restores prior resources rooms monsters and paths")
					game._open_build_palette_for_room(target)
					game._set_build_facility("ward_core")
					await settle()
					key(KEY_ESCAPE)
					await settle()
					check(state() == before and not game.build_pick_mode,tag+" ESC cancels without changes")
	game.queue_free()
	await settle()
	var file := FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failed,"assets":evidence},"\t"))
	file.close()
	print("UIUX_WARD_DIRECTIONAL_TEST: %s (%d checks)" % ["FAIL" if failed else "PASS",checks])
	get_tree().quit(1 if failed else 0)
