extends "res://tools/UIUXActorArtTest.gd"
const Fixture = preload("res://tools/UIUXSecondaryFixture.gd")
const Contracts = preload("res://scripts/systems/contracts/ContractRosterService.gd")
var contracts := {
	"stone_sentinel":{"art":"dolkong","character":"CHR_DOLKONG","instance":"mon_contract_dolkong","profile":"large_grounded"},
	"war_drummer":{"art":"dudum","character":"CHR_DUDUM","instance":"mon_contract_dudum","profile":"normal_grounded"},
	"moon_tracker":{"art":"moon","character":"CHR_LUMI","instance":"mon_contract_lumi","profile":"small_flying"},
	"mimic_porter":{"art":"mimi","character":"CHR_MIMI","instance":"mon_contract_mimi","profile":"normal_grounded"}
}
var phase := "after"
var actor_catalog: Dictionary = {}
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg=="--before": phase="before"
	out_dir = "res://tmp/uiux_contract_art_20260913/"+phase
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	game = Game.instantiate()
	add_child(game)
	await settle()
	Fixture.prepare(game)
	game.combat_speed_intro_seen = true
	game.deployed_instance_ids.append("mon_core_gob")
	expect(game._choose_early_specialization("goblin","goblin_treasure_hunter"),"fixture owned Gob chooses legal specialization")
	# A controlled owned/deployed roster exercises existing runtime paths without campaign traversal.
	for id in contracts:
		for key in DataRegistry.monster_instances:
			if str(DataRegistry.monster_instances[key].get("species_id",""))==id:
				contracts[id].instance=key
		actor_catalog[id] = {"path":DataRegistry.monster(id).sprite}
	var owned_fixture: Dictionary = game.monster_roster.duplicate(true)
	if phase=="after": check_native_actors()
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for text_scale in [0.9,1.0,1.15]:
			UISettings.text_scale=text_scale
			var tag := "%dx%d_%d" % [resolution.x,resolution.y,roundi(text_scale*100)]
			for id in contracts:
				var entry: Dictionary = contracts[id]
				game.update4_active_run = {}
				GameState.day=2
				game.monster_roster = {}
				for owned in ["slime","goblin","imp","spore_healer",id]:
					game.monster_roster[owned]=owned_fixture[owned].duplicate(true)
				game.monster_roster.spore_healer.room="treasure"
				game.selected_contract_ids.assign([id,"spore_healer"])
				game.deployed_instance_ids.assign([entry.instance,"mon_core_gob"])
				expect(Contracts.validate_contract_selection(game.selected_contract_ids,game._available_update2_contracts()).is_empty(),tag+" "+id+" valid two-contract fixture")
				expect(Contracts.validate_deployment(game.deployed_instance_ids,game._contract_owned_instance_ids(true),game.castle_art_stage).is_empty(),tag+" "+id+" valid owned deployment")
				game.selected_monster_id=id
				game._set_screen(C.SCREEN_MONSTER)
				await settle()
				expect(game.selected_monster_id==id,tag+" "+id+" actual selectable contract")
				if phase=="after":
					var detail := node("MonsterSelectedDetail").find_child("MonsterPortrait_"+id,true,false) as TextureRect
					expect(detail.texture.resource_path==portrait_path(id),tag+" "+id+" dedicated portrait")
					check_copy(game.ui_layer)
				await capture(tag+"_"+id+"_detail")
				(node("MonsterMemoryButton") as Button).grab_focus()
				await key(KEY_ENTER)
				expect(game.current_screen==C.SCREEN_MEMORY_ARCHIVE,tag+" "+id+" Enter opens memory")
				if phase=="after": expect(has_art(game.ui_layer,portrait_path(id)),tag+" "+id+" memory identity")
				await capture(tag+"_"+id+"_memory")
				game._set_screen(C.SCREEN_MANAGEMENT)
				game._onboarding_begin_dialogue([{"speaker":entry.character,"emotion":"","text":"다음 방어는 제가 맡을게요.","stage":"LV03_DAY01_MANAGEMENT_TUTORIAL"}],C.SCREEN_MANAGEMENT)
				await settle()
				if phase=="after": expect(has_art(game.ui_layer,portrait_path(id)),tag+" "+id+" dialogue identity")
				await capture(tag+"_"+id+"_dialogue")
				game._onboarding_advance_dialogue()
				await settle()
				game._set_screen(C.SCREEN_MANAGEMENT)
				await click(node("ManagementTab_roster"))
				expect(game.management_tool_tab=="roster",tag+" "+id+" actual roster tab")
				await settle()
				await capture(tag+"_"+id+"_map")
				var original_room: String = str(game.monster_roster[id].get("room",""))
				var preview: Texture2D = game.management_scene.monster_identity_texture(id)
				if phase=="after":
					expect(preview is AtlasTexture and preview.atlas.resource_path==DataRegistry.monster(id).sprite,tag+" "+id+" placement uses actual sheet")
				(node("MonsterCard_"+id) as Button).grab_focus()
				await key(KEY_ENTER)
				await settle()
				expect(game.deploy_pick_monster_id==id and game.dragging_monster_id=="",tag+" "+id+" placement mode entered")
				expect(game.monster_roster[id].room==original_room,tag+" "+id+" selection is read-only")
				await key(KEY_ESCAPE)
				expect(game.deploy_pick_monster_id=="" and game.dragging_monster_id=="",tag+" "+id+" ESC exits placement")
				expect(game.monster_roster[id].room==original_room,tag+" "+id+" cancel preserves placement")
				game._start_combat()
				await settle(20)
				expect(game.current_screen==C.SCREEN_COMBAT,tag+" "+id+" existing combat starts")
				if game.current_screen==C.SCREEN_COMBAT:
					game.combat_scene.set_pause_state(true,false)
					var found := false
					for unit in game.monster_units:
						if unit.unit_id!=id: continue
						found=true
						expect(unit.sprite_path==DataRegistry.monster(id).sprite,tag+" "+id+" spawned unit exact sheet")
						expect(unit.combat_visual_profile.profile_id==entry.profile,tag+" "+id+" size/motion profile preserved")
					expect(found,tag+" "+id+" contract spawned in real combat")
					await capture(tag+"_"+id+"_combat")
				game._set_screen(C.SCREEN_MANAGEMENT)
				await settle()
	await contact_sheet(phase,actor_catalog)
	game.queue_free()
	await settle()
	var file := FileAccess.open(out_dir.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase":phase,"assertions":count,"failed":failed,"captures":captures},"\t"))
	file.close()
	print("UIUX_CONTRACT_ART_TEST: %s (%d assertions, %d flow captures)" % ["FAIL" if failed else "PASS",count,captures.size()])
	get_tree().quit(1 if failed else 0)

func portrait_path(id: String) -> String:
	return "res://assets/sprites/portraits/uiux3d/"+str(contracts[id].art)+"_base.png"

func has_art(parent: Node,path: String) -> bool:
	if parent is TextureRect and parent.texture != null and parent.texture.resource_path==path: return true
	for child in parent.get_children():
		if has_art(child,path): return true
	return false

func capture(id: String) -> void:
	await settle()
	var path := out_dir.path_join(id+".png")
	expect(get_viewport().get_texture().get_image().save_png(path)==OK,id+" capture")
	captures.append(path)

func check_native_actors() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/uiux_actor_art.json"))
	for id in contracts:
		var info: Dictionary = catalog[id]
		var tex: Texture2D = load(info.path)
		var image := tex.get_image()
		expect(image.detect_alpha()!=Image.ALPHA_NONE and image.get_pixel(0,0).a==0,id+" native transparent atlas")
		expect(image.has_mipmaps(),id+" imported mipmaps")
		var portrait: Texture2D = load(portrait_path(id))
		var portrait_image := portrait.get_image()
		expect(portrait_image.detect_alpha()!=Image.ALPHA_NONE and portrait_image.get_pixel(0,0).a==0,id+" native transparent large portrait")
		expect(mini(portrait.get_width(),portrait.get_height())>=1024,id+" no portrait downsample")
		var data: Dictionary = DataRegistry.monster(id)
		var unit := Actor.new()
		add_child(unit)
		unit.setup(id,data,C.FACTION_MONSTER,"barracks")
		unit.set_physics_process(false)
		expect(unit.sprite_path==info.path and unit.sprite.material==null,id+" actual sprite without chroma shader")
		var profile: Dictionary = unit.combat_visual_profile
		expect(profile.profile_id==contracts[id].profile,id+" body and flying class preserved")
		expect(Vector2(profile.source_frame_px[0],profile.source_frame_px[1])==Vector2(384,384),id+" logical frame 384")
		expect(is_equal_approx(float(info.idle_height)*float(profile.render_scale),float(profile.target_art_height_px)),id+" visible body matches existing size target")
		var frames: SpriteFrames = unit.sprite.sprite_frames
		var index := 0
		for animation in ["idle_down","down","move_down","attack_down","skill_down"]:
			var expected := 2 if animation in ["idle_down","down"] else 4
			expect(frames.get_frame_count(animation)==expected,id+" "+animation+" frame count")
			for n in range(expected):
				var frame := frames.get_frame_texture(animation,n) as AtlasTexture
				expect(frame!=null and frame.atlas==tex and frame.filter_clip,id+" "+animation+" atlas identity")
				expect(frame.get_size()==Vector2(384,384),id+" "+animation+" logical canvas")
				expect(Rect2(Vector2.ZERO,tex.get_size()).encloses(frame.region),id+" "+animation+" source in bounds")
				var visible := ActorArt.visible_bounds(frame)
				expect(visible.size.x>0 and visible.size.y>0,id+" "+animation+" visible silhouette")
				index+=1
		expect(index==16,id+" exact sixteen poses")
		var idle: Texture2D = frames.get_frame_texture("idle_down",0)
		var foot := Vector2(410,265)
		var rect := ActorArt.preview_rect(idle,foot,54)
		var bounds := ActorArt.visible_bounds(idle)
		var factor := rect.size.y/384.0
		expect(is_equal_approx(bounds.size.y*factor,54),id+" map visible height ignores padding")
		expect((rect.position+Vector2(bounds.get_center().x,bounds.end.y)*factor).distance_to(foot)<0.01,id+" exact map foot anchor")
		expect(absf(unit.combat_anchor_local("head").y+float(info.idle_height)*float(profile.render_scale)+Actor.COMBAT_ANCHOR_HEAD_GAP)<6,id+" label near visible head")
		unit.queue_free()
