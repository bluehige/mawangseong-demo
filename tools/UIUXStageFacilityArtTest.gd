extends "res://tools/UIUXFacilityArtTest.gd"
const STAGE_ART := [{"id":"barracks_stage01_SE","prop":"weapon_rack","stage":"stage_01_cave","facing":"SE","layer":"back","reference":"assets/props/stage_01/prop_weapon_rack_stage01_SE_back.png"},{"id":"barracks_stage03_SE","prop":"weapon_rack","stage":"stage_03_keep","facing":"SE","layer":"back","reference":"assets/props/stage_03/prop_armory_stage03_SE_back.png"},{"id":"barracks_stage04_SE","prop":"weapon_rack","stage":"stage_04_citadel","facing":"SE","layer":"back","reference":"assets/props/stage_04/prop_armory_stage04_SE_back.png"},{"id":"barracks_stage04_NW","prop":"weapon_rack","stage":"stage_04_citadel","facing":"NW","layer":"back","reference":"assets/props/stage_04/prop_elite_garrison_stage04_NW_back.png"},{"id":"treasure_stage01_NW","prop":"treasure_pile_large","stage":"stage_01_cave","facing":"NW","layer":"front","reference":"assets/props/stage_01/prop_treasure_pile_stage01_NW_front.png"},{"id":"treasure_stage03_NW","prop":"treasure_pile_large","stage":"stage_03_keep","facing":"NW","layer":"front","reference":"assets/props/stage_03/prop_treasure_vault_stage03_NW_front.png"},{"id":"treasure_stage04_NW","prop":"treasure_pile_large","stage":"stage_04_citadel","facing":"NW","layer":"front","reference":"assets/props/stage_04/prop_treasure_vault_stage04_NW_front.png"},{"id":"recovery_stage01_NW","prop":"recovery_nest_f","stage":"stage_01_cave","facing":"NW","layer":"front","reference":"assets/props/stage_01/prop_recovery_nest_stage01_NW_front.png"},{"id":"recovery_stage03_NW","prop":"recovery_nest_f","stage":"stage_03_keep","facing":"NW","layer":"front","reference":"assets/props/stage_03/prop_recovery_sanctuary_stage03_NW_front.png"},{"id":"recovery_stage04_NW","prop":"recovery_nest_f","stage":"stage_04_citadel","facing":"NW","layer":"front","reference":"assets/props/stage_04/prop_recovery_sanctuary_stage04_NW_front.png"},{"id":"watch_post_stage04_NW","prop":"watch_post","stage":"stage_04_citadel","facing":"NW","layer":"front","reference":"assets/props/stage_04/prop_watch_tower_stage04_NW_front.png"}]
const FACILITY_PROP := {"barracks":"weapon_rack","treasure":"treasure_pile_large","recovery":"recovery_nest_f","watch_post":"watch_post"}

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): phase = args[0]
	output = "res://tmp/uiux_stage_art_20260913/"+phase
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
	if phase == "after": _check_stage_assets()
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for text_scale in [0.9,1.0,1.15]:
			UISettings.text_scale = text_scale
			for stage in ["stage_01_cave","stage_03_keep","stage_04_citadel"]:
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
				await capture(tag+"_overview")
				# Remove through the existing runtime so the sole SE barracks can be rebuilt.
				game._open_build_palette_for_room("barracks")
				game._set_build_facility("build_slot")
				await settle()
				check(game._confirm_build_preview(),tag+" prepare real SE construction through existing removal")
				await settle()
				game._cancel_management_action_mode()
				for entry in STAGE_ART:
					if entry.stage != stage: continue
					var facility := str(entry.id).split("_stage")[0]
					var target := ""
					for id in game.rooms:
						if game.graph._object_facing_for_instance(str(id),facility) == entry.facing and game._evaluate_facility_placement(str(id),facility).ok:
							target = str(id)
							break
					check(target != "",tag+" actual candidate "+entry.id)
					if target == "": continue
					var visual: Dictionary = game.quarter_renderer.facility_visual(target,facility)
					var tex: Texture2D = game.quarter_renderer.object_sprite_textures.get(visual.texture_keys[0])
					var expected: String = "res://assets/props/uiux/"+entry.id+".png" if phase == "after" else "res://"+entry.reference
					check(tex.resource_path == expected,tag+" actual stage override "+entry.id)
					await _exercise(facility,target,entry.facing,tag+"_"+facility+"_"+entry.facing)
					if phase == "after":
						var name_rects: Array = game.management_name_label_rects
						check(name_rects.size() == 3,tag+" all three visible monster names retained")
						for first in range(name_rects.size()):
							for second in range(first+1,name_rects.size()):
								check(not name_rects[first].intersects(name_rects[second]),tag+" clustered monster labels do not overlap")
	print("STAGE_ART_TEXTURE_MEMORY_BYTES ",Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	game.queue_free()
	await settle()
	var file := FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase":phase,"checks":checks,"failed":failed,"cases":evidence},"\t"))
	file.close()
	print("UIUX_STAGE_FACILITY_ART_TEST: %s (%d checks; %d placements)" % ["FAIL" if failed else "PASS",checks,evidence.size()])
	get_tree().quit(1 if failed else 0)

func _expected_path(facility: String, facing: String) -> String:
	var prop: Dictionary = DataRegistry.quarter_asset_manifest.props[FACILITY_PROP[facility]]
	var mapping: Dictionary = prop.get("stage_facing_sprites",{}).get(game.castle_art_stage,{}).get(facing,prop.facing_sprites.get(facing,{}))
	return "res://"+str(mapping.get("back",mapping.get("front","")))

func _check_stage_assets() -> void:
	var hashes := {}
	for entry in STAGE_ART:
		var path: String = "res://assets/props/uiux/"+entry.id+".png"
		var texture := load(path) as Texture2D
		check(texture != null,entry.id+" runtime resource")
		if texture == null: continue
		var im := texture.get_image()
		check(im.get_format() == Image.FORMAT_RGBA8 and im.has_mipmaps(),entry.id+" native RGBA with imported mipmaps")
		check(im.get_width() >= 800 and im.get_height() >= 800,entry.id+" native resolution")
		check(im.get_pixel(0,0).a == 0 and im.get_pixel(im.get_width()-1,0).a == 0 and im.get_pixel(0,im.get_height()-1).a == 0 and im.get_pixel(im.get_width()-1,im.get_height()-1).a == 0,entry.id+" transparent corners")
		var transparent := 0
		var opaque := 0
		for y in range(0,im.get_height(),16):
			for x in range(0,im.get_width(),16):
				if im.get_pixel(x,y).a == 0: transparent += 1
				if im.get_pixel(x,y).a > 0.9: opaque += 1
		check(transparent > 100 and opaque > 100,entry.id+" actual visible cutout")
		var hash_value := FileAccess.get_sha256(path)
		check(hash_value == FileAccess.get_sha256("res://assets/source/imagegen/uiux_stage_facilities_20260913/"+entry.id+".png"),entry.id+" unchanged native source")
		check(not hashes.has(hash_value),entry.id+" distinct stage and facing")
		hashes[hash_value] = true
