extends "res://tools/UIUXU4InteractionTest.gd"
const Fixture = preload("res://tools/UIUXSecondaryFixture.gd")
const IDS := {"slime":"CHR_PUDDING","goblin":"CHR_GOB","imp":"CHR_PYNN","spore_healer":"CHR_MORI"}
const FILES := {"slime":"pudding_base","goblin":"gob_base","imp":"pynn_base","spore_healer":"mori_base"}
const INSTANCES := {"slime":"mon_core_pudding","goblin":"mon_core_gob","imp":"mon_core_pynn","spore_healer":"mon_contract_mori"}
var phase := "after"
var output_dir := ""
var late: Dictionary = {}
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--before": phase = "before"
	output_dir = "res://tmp/uiux_portraits_20260913/" + phase
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game = Game.instantiate()
	add_child(game)
	await settle()
	Fixture.prepare(game)
	GameState.day = 16
	game.combat_speed_intro_seen = true
	game.selected_contract_ids.assign(["spore_healer"])
	late = JSON.parse_string(FileAccess.get_file_as_string("res://data/regular_version/update4/characters.json"))
	if phase == "after":
		check_assets()
		check_late_paths()
		check_evolution_paths()
		check_crown_paths()
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for text_scale in [0.9,1.0,1.15]:
			UISettings.text_scale = text_scale
			var tag := "%dx%d_%d" % [resolution.x,resolution.y,roundi(text_scale*100)]
			for id in IDS:
				game.deployed_instance_ids.assign([INSTANCES[id]])
				game.selected_monster_id = id
				game._set_screen(C.SCREEN_MONSTER)
				await settle()
				var detail: Control = node("MonsterSelectedDetail")
				expect(detail != null,tag+" "+id+" active detail")
				if phase == "after":
					var art := detail.find_child("MonsterPortrait_"+id,true,false) as TextureRect
					expect(art != null and art.texture.resource_path == wanted(id),tag+" "+id+" dedicated full portrait")
					expect(not (art.texture is AtlasTexture),tag+" "+id+" no enlarged combat frame")
					check_copy(game.ui_layer)
				await shot(tag+"_"+id+"_detail")
				(node("MonsterMemoryButton") as Button).grab_focus()
				await key(KEY_ENTER)
				expect(game.current_screen == C.SCREEN_MEMORY_ARCHIVE,tag+" "+id+" Enter opens actual memory screen")
				if phase == "after":
					expect(has_texture(game.ui_layer,wanted(id)),tag+" "+id+" memory uses correct identity")
					var empty := node("MemoryEmptyState") as Label
					expect(empty != null and empty.size.y >= 180,tag+" empty memory guidance has visible height")
				await shot(tag+"_"+id+"_memory")
				game._set_screen(C.SCREEN_MANAGEMENT)
				await dialogue(IDS[id],"",tag+"_"+id+"_dialogue")
			await dialogue("CHR_GOB","eager",tag+"_gob_eager")
			for speaker in late:
				var emotion := "happy" if str(speaker) in ["CHR_SILKY","CHR_POPO"] else "challenge"
				await dialogue(speaker,emotion,tag+"_"+str(speaker).to_lower()+"_"+emotion)
			game.deployed_instance_ids.assign(["mon_core_pudding","mon_core_gob","mon_core_pynn"])
			game._set_screen(C.SCREEN_TITLE)
			await settle()
			if phase == "after":
				for id in ["slime","goblin","imp"]:
					expect(has_texture(game.ui_layer,wanted(id)),tag+" title "+id+" portrait")
			await shot(tag+"_title")
			# Controlled growth rows test the real result presenter, not a claimed completed battle.
			game.result_summary = {"win":true}
			game.last_growth_summary.clear()
			for id in IDS:
				game.last_growth_summary.append({"monster_id":id,"display_name":game._monster_display_name(id),"level_before":1,"level_after":1,"exp_gain":0,"exp_after":0,"next_exp":100})
			game._set_screen(C.SCREEN_RESULT)
			await settle()
			if phase == "after":
				for id in IDS: expect(has_texture(game.ui_layer,wanted(id)),tag+" result presenter "+id+" portrait")
			await shot(tag+"_result_fixture")
			game._set_screen(C.SCREEN_RAID)
			await settle()
			await shot(tag+"_raid")
			if phase == "after":
				var prior_crown: Dictionary = game.update4_active_run.get("crown",{}).duplicate(true)
				game.update4_active_run.crown = {"selected_instance_id":"mon_core_pudding","crown_form_id":"crown_pudding_royal_bastion"}
				game.selected_monster_id = "slime"
				game._set_screen(C.SCREEN_MONSTER)
				await settle()
				var crown_path := str(DataRegistry.update4_crown_evolutions.crown_pudding_royal_bastion.portrait)
				expect(has_texture(node("MonsterSelectedDetail"),crown_path),tag+" active crown detail")
				await shot(tag+"_crown_detail")
				await click(node("MonsterMemoryButton"))
				expect(has_texture(game.ui_layer,crown_path),tag+" memory retains crown over base/evolution")
				await shot(tag+"_crown_memory")
				game.update4_active_run.crown = prior_crown
	game.queue_free()
	await settle()
	var result := {"phase":phase,"assertions":count,"failed":failed,"captures":captures,"result_rows":"controlled fixture; not completed battle"}
	var file := FileAccess.open(output_dir.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	print("UIUX_PORTRAIT_ART_TEST: %s (%d assertions, %d captures, %s)" % ["FAIL" if failed else "PASS",count,captures.size(),phase])
	get_tree().quit(1 if failed else 0)

func wanted(id: String) -> String:
	return "res://assets/sprites/portraits/uiux3d/"+str(FILES[id])+".png"

func check_assets() -> void:
	for id in IDS:
		var path := wanted(id)
		expect(game.management_scene.monster_portrait_path(id) == path,id+" central large portrait path")
		for emotion in ["","victory","wounded","unknown"]:
			expect(game.management_scene.monster_portrait_path(id,emotion) == path,id+" base emotion fallback "+emotion)
		var tex: Texture2D = load(path)
		var im := tex.get_image()
		expect(im != null and im.detect_alpha() != Image.ALPHA_NONE,id+" native alpha")
		expect(im.get_pixel(0,0).a == 0,id+" transparent corner")
		expect(mini(im.get_width(),im.get_height()) >= 1024,id+" large art without downsample")
		# Godot 4.6.3 CompressedTexture2D.has_alpha() always returns false; inspect GPU image data above.
		expect(im.has_mipmaps(),id+" imported mipmaps")
		var drag: Texture2D = game.management_scene.monster_identity_texture(id)
		expect(drag is AtlasTexture and drag.atlas.resource_path == DataRegistry.monster(id).sprite,id+" map/drag retains actual combat art")
	var eager := "res://assets/sprites/portraits/uiux3d/gob_eager.png"
	expect(game._onboarding_speaker_portrait_path("CHR_GOB","eager")==eager,"Gob eager variant exact path")
	var im := (load(eager) as Texture2D).get_image()
	expect(im.detect_alpha()!=Image.ALPHA_NONE and im.get_pixel(0,0).a==0,"Gob eager native alpha")

func check_late_paths() -> void:
	for id in late:
		var portraits: Dictionary = late[id].portraits
		for emotion in portraits:
			expect(game._onboarding_speaker_portrait_path(id,emotion)==str(portraits[emotion]),id+" existing late variant "+emotion)
			expect(ResourceLoader.exists(portraits[emotion]),id+" late resource exists "+emotion)
		var base := str(portraits.get("base",portraits.get("council","")))
		expect(game._onboarding_speaker_portrait_path(id,"unrecognized")==base,id+" fallback to base/council")
		expect(game._onboarding_speaker_portrait_path(id)==base,id+" neutral base/council")
	expect(game._onboarding_speaker_portrait_path("MISSING_CHARACTER")=="","missing speaker stays explicit")
	# Normalizing the late schema must not mutate the source character catalog.
	for id in late:
		expect(DataRegistry.character(id).portraits==late[id].portraits,id+" immutable source catalog")

func check_evolution_paths() -> void:
	var prior: Dictionary = game.monster_roster.duplicate(true)
	for rule_id in DataRegistry.evolution_rules:
		var rule: Dictionary = DataRegistry.evolution_rule(rule_id)
		var id := str(rule.get("monster_id",""))
		if not IDS.has(id): continue
		game.monster_roster[id].promotion_id = rule_id
		for emotion in ["","victory","wounded"]:
			expect(game.management_scene.monster_portrait_path(id,emotion)==str(rule.get("portrait_variants",{}).get(emotion,rule.get("portrait",""))),rule_id+" exact evolution portrait "+emotion)
	game.monster_roster = prior

func dialogue(speaker: String, emotion: String, tag: String) -> void:
	game.onboarding_enabled = false
	game.story_feature_enabled = false
	game._onboarding_begin_dialogue([{"speaker":speaker,"emotion":emotion,"text":"함께 다음 방어를 준비해요.","stage":"LV03_DAY01_MANAGEMENT_TUTORIAL"}],C.SCREEN_MANAGEMENT)
	await settle()
	expect(game.current_screen==C.SCREEN_DIALOGUE,tag+" actual dialogue screen")
	if phase == "after":
		var path: String = game._onboarding_speaker_portrait_path(speaker,emotion)
		expect(path!="" and has_texture(game.ui_layer,path),tag+" displayed portrait")
		if path.contains("/portraits/uiux3d/"):
			var tex := find_texture(game.ui_layer,path)
			expect(tex.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,tag+" entire transparent silhouette fits")
	await shot(tag)
	game._onboarding_advance_dialogue()
	await settle()

func find_texture(parent: Node,path: String) -> TextureRect:
	if parent is TextureRect and parent.texture != null and parent.texture.resource_path==path: return parent
	for child in parent.get_children():
		var found := find_texture(child,path)
		if found != null: return found
	return null

func has_texture(parent: Node,path: String) -> bool:
	return find_texture(parent,path)!=null

func shot(id: String) -> void:
	await settle()
	var path := output_dir.path_join(id+".png")
	expect(get_viewport().get_texture().get_image().save_png(path)==OK,id+" capture")
	captures.append(path)

func check_crown_paths() -> void:
	var prior: Dictionary = game.update4_active_run.duplicate(true)
	for crown_id in DataRegistry.update4_crown_evolutions:
		var crown: Dictionary = DataRegistry.update4_crown_evolutions[crown_id]
		var id := str(crown.monster_id)
		var instance_id := ""
		for key in DataRegistry.monster_instances:
			if str(DataRegistry.monster_instances[key].get("species_id",""))==id: instance_id=key
		expect(instance_id!="",crown_id+" actual instance available")
		game.update4_active_run.crown = {"selected_instance_id":instance_id,"crown_form_id":crown_id}
		game.update4_active_run.upper_floor = {"crown_suppressed":false}
		expect(game._scaled_monster_stats(id).get("crown_form_id","")==crown_id,crown_id+" live form selector")
		expect(game.management_scene.monster_portrait_path(id)==str(crown.portrait),crown_id+" neutral portrait")
		expect(game.management_scene.monster_portrait_path(id,"victory")==str(crown.portrait_victory),crown_id+" victory portrait")
		expect(game.management_scene.monster_portrait_path(id,"wounded")==str(crown.portrait_wounded) and ResourceLoader.exists(str(crown.portrait_wounded)),crown_id+" uses authored wounded portrait")
		game.update4_active_run.upper_floor.crown_suppressed = true
		expect(game.management_scene.monster_portrait_path(id)!=str(crown.portrait),crown_id+" suppressed crown does not overwrite current form")
	game.update4_active_run = prior
