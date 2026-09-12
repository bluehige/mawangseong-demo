extends "res://tools/UIUXU4InteractionTest.gd"
const ActorArt = preload("res://scripts/ui/UIUXActorArt.gd")
const Actor = preload("res://scripts/units/Unit.gd")
var out_dir := "res://tmp/uiux_art_direction/actors"
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	game = Game.instantiate()
	add_child(game)
	await settle()
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	game.story_feature_enabled = false
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/uiux_actor_art.json"))
	for id in catalog:
		var info: Dictionary = catalog[id]
		var tex: Texture2D = load(info.path)
		var im := tex.get_image()
		expect(im != null and im.detect_alpha() != Image.ALPHA_NONE,id+" native alpha")
		expect(im.get_pixel(0,0).a == 0,id+" transparent corner")
		var frames: SpriteFrames = Actor.warm_animation_frames(info.path)
		for animation in ["idle_down","move_down","attack_down","skill_down","down"]:
			var expected := 2 if animation in ["idle_down","down"] else 4
			expect(frames.get_frame_count(animation) == expected,id+" "+animation+" frame contract")
			for n in range(expected):
				var frame: Texture2D = frames.get_frame_texture(animation,n)
				expect(frame.get_size() == Vector2(384,384),id+" "+animation+" uniform logical frame")
				expect(frame is AtlasTexture and frame.filter_clip,id+" "+animation+" clipped source region")
		var stats: Dictionary = DataRegistry.enemy(id) if DataRegistry.enemies.has(id) else DataRegistry.monster(id)
		var unit := Actor.new()
		add_child(unit)
		unit.setup(id,stats,C.FACTION_ENEMY if DataRegistry.enemies.has(id) else C.FACTION_MONSTER,"entrance")
		unit.set_physics_process(false)
		expect(unit.sprite_path == info.path and unit.sprite.material == null,id+" runtime uses native art without chroma erasure")
		print("ACTOR_PROFILE ",id," ",unit.combat_visual_profile.source_frame_px," ",unit.combat_visual_profile.render_scale)
		expect(Vector2(unit.combat_visual_profile.source_frame_px[0],unit.combat_visual_profile.source_frame_px[1]) == Vector2(384,384),id+" profile uses actual logical frame")
		var idle := frames.get_frame_texture("idle_down",0)
		var foot := Vector2(420,260)
		var rect := ActorArt.preview_rect(idle,foot,54.0)
		var bounds := ActorArt.visible_bounds(idle)
		var factor := rect.size.y/idle.get_height()
		expect(is_equal_approx(bounds.size.y*factor,54.0),id+" management body height ignores transparent padding")
		expect((rect.position+Vector2(bounds.get_center().x,bounds.end.y)*factor).distance_to(foot)<0.01,id+" management visible feet match drop anchor")
		expect(absf(unit.combat_anchor_local("head").y + info.idle_height*float(unit.combat_visual_profile.render_scale) + Actor.COMBAT_ANCHOR_HEAD_GAP)<6.0,id+" labels stay near the visible head, ignoring padding")
		unit.queue_free()
	for id in DataRegistry.update4_rival_bosses:
		var stats: Dictionary = DataRegistry.enemy(id)
		var rival := Actor.new()
		add_child(rival)
		rival.setup(id,stats,C.FACTION_ENEMY,"entrance")
		rival.set_physics_process(false)
		expect(rival.sprite_path == str(stats.sprite_sheet),id+" existing sprite_sheet field loads")
		expect(rival.sprite.sprite_frames.get_frame_count("attack_down")==4,id+" existing rival atlas animation remains connected")
		rival.queue_free()
	for file_path in ["res://data/evolution_rules.json","res://data/regular_version/update4/crown_evolutions.json"]:
		var forms: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file_path))
		for form_id in forms:
			var form: Dictionary = forms[form_id]
			var path := str(form.get("combat_sprite",""))
			if path == "": continue
			var base_id := str(form.monster_id)
			var stats := DataRegistry.monster(base_id).duplicate(true)
			stats.sprite = path
			var unit := Actor.new()
			add_child(unit)
			unit.setup(base_id,stats,C.FACTION_MONSTER,"entrance")
			unit.set_physics_process(false)
			expect(unit.sprite_path == path,form_id+" retains its exact evolution art instead of new base art")
			expect(unit.sprite.sprite_frames.get_frame_count("attack_down")==4,form_id+" keeps existing attack animation")
			unit.queue_free()
	# Preserve current art during exact old/new comparison using the existing Unit renderer.
	var current_profiles: Dictionary = DataRegistry.combat_visual_profiles.duplicate(true)
	var baseline_profiles: Dictionary = current_profiles.duplicate(true)
	var legacy_overrides: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/fixtures/uiux_actor_legacy_profiles.json"))
	for id in catalog:
		baseline_profiles.unit_overrides[id] = legacy_overrides[id]
	var original_monsters: Dictionary = DataRegistry.monsters.duplicate(true)
	var original_enemies: Dictionary = DataRegistry.enemies.duplicate(true)
	for variant in ["before","after"]:
		DataRegistry.combat_visual_profiles = baseline_profiles.duplicate(true) if variant == "before" else current_profiles.duplicate(true)
		for id in catalog:
			var table: Dictionary = DataRegistry.enemies if DataRegistry.enemies.has(id) else DataRegistry.monsters
			table[id].sprite = str(current_profiles.unit_overrides[id].legacy_runtime_path) if variant == "before" else str(catalog[id].path)
		for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
			DisplayServer.window_set_size(resolution)
			UISettings.text_scale = 1.0
			game._set_screen(C.SCREEN_MANAGEMENT)
			GameState.day = 2
			game._choose_early_specialization("goblin","goblin_treasure_hunter")
			game.combat_speed_intro_seen = true
			game._start_combat()
			await settle(60)
			expect(game.current_screen == C.SCREEN_COMBAT,variant+" real combat")
			game.combat_scene.set_pause_state(true,false)
			await actor_shot("%s_%dx%d_combat" % [variant,resolution.x,resolution.y])
			game._set_screen(C.SCREEN_MANAGEMENT)
			await settle()
		for start in range(0,catalog.size(),4):
			var page: Dictionary = {}
			for id in catalog.keys().slice(start,start+4): page[id] = catalog[id]
			await contact_sheet(variant+"_page"+str(start/4),page)
	DataRegistry.combat_visual_profiles = current_profiles
	DataRegistry.monsters = original_monsters
	DataRegistry.enemies = original_enemies
	game.queue_free()
	await settle()
	print("UIUX_ACTOR_ART_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS",count])
	get_tree().quit(1 if failed else 0)

func actor_shot(id: String) -> void:
	await settle()
	expect(get_viewport().get_texture().get_image().save_png(out_dir.path_join(id+".png")) == OK,id+" capture")

func contact_sheet(variant: String,catalog: Dictionary) -> void:
	game.visible = false
	game.ui_layer.visible = false
	DisplayServer.window_set_size(Vector2i(1920,1080))
	var stage := CanvasLayer.new()
	stage.layer = 100
	add_child(stage)
	var background := ColorRect.new()
	background.color = Color("#23232c")
	background.size = Vector2(1920,1080)
	stage.add_child(background)
	var names := ["idle_down","move_down","attack_down","skill_down","down"]
	var units: Array = []
	var row := 0
	for id in catalog:
		var stats: Dictionary = DataRegistry.enemy(id) if DataRegistry.enemies.has(id) else DataRegistry.monster(id)
		for col in range(5):
			var unit := Actor.new()
			stage.add_child(unit)
			unit.setup(id,stats,C.FACTION_ENEMY if DataRegistry.enemies.has(id) else C.FACTION_MONSTER,"art")
			unit.set_physics_process(false)
			unit.set_process(false)
			unit.position = Vector2(200+col*375,246+row*246)
			unit.scale = Vector2.ONE*2.8
			unit._play_animation(names[col])
			unit.sprite.frame = 0
			unit.sprite.pause()
			unit.name_label.hide()
			unit.self_modulate.a = 0.0 # Contact sheet hides UI overlays; actual combat captures retain them.
			var caption := Label.new()
			caption.position = Vector2(30+col*375,18+row*246)
			caption.size = Vector2(340,35)
			caption.text = id+" · "+names[col]
			stage.add_child(caption)
			units.append(unit)
		row += 1
	for frame_index in range(4):
		for unit in units:
			unit.sprite.frame = mini(frame_index,unit.sprite.sprite_frames.get_frame_count(unit.sprite.animation)-1)
		await actor_shot(variant+"_poses_"+str(frame_index))
	stage.queue_free()
	game.visible = true
	game.ui_layer.visible = true
	await settle()
