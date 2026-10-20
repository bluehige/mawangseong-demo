extends "res://tools/tests/PlayerFeedbackHotfixTest.gd"
const ActorArt = preload("res://scripts/ui/UIUXActorArt.gd")
const SPECIES := ["spider_tailor", "bat_courier"]
var actors := {}

func run() -> void:
	output_dir = "res://tmp/native_contract_profile_review"
	expect(ProjectSettings.globalize_path("user://").contains("native_profile_review"), "isolated synthetic userdata")
	if not failures.is_empty(): get_tree().quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	DataRegistry.load_all()
	game = GameRootScene.instantiate()
	add_child(game)
	await settle()
	expect(game.get("combat_scene") != null, "runtime initializes")
	if not failures.is_empty(): get_tree().quit(1); return
	game.continuity.acknowledge_update()
	game._set_campaign_save_path_for_tests("")
	game._onboarding_reset_game()
	game._onboarding_enter_management_day(1, true)
	game._debug_skip_onboarding()
	game.story_feature_enabled = false
	game.campaign_save_enabled = false
	game.campaign_autosave_pending = false
	game.set_process(false)
	game.set_physics_process(false)
	for unit in game.monster_units + game.enemy_units:
		if is_instance_valid(unit): unit.queue_free()
	game.monster_units.clear()
	game.enemy_units.clear()
	GameState.day = 23
	for species in SPECIES:
		game.monster_roster[species] = game.monster_roster.slime.duplicate(true)
		game.monster_roster[species].level = 7
		game.monster_roster[species].bond = 85
		game.monster_roster[species].promotion_id = ""
		game.monster_roster[species].specialization_id = ""
		expect(game._evolution_rules_for_monster(species).is_empty(), species + " has no ordinary promotion rule; do not invent one")
		expect(game._specializations_for_monster(species).size() == 2, species + " has two real tactical specializations")
		var chosen := "silky_stair_warden" if species == "spider_tailor" else "popo_royal_express"
		expect(game._choose_early_specialization(species, chosen), species + " real specialization selection succeeds")
		expect(game._monster_ai_behavior(species) == str(DataRegistry.specialization(chosen).ai_behavior), species + " selected behavior matches its own specialization")
		var stats: Dictionary = game._scaled_monster_stats(species)
		var actor = game._create_unit(species, stats, Constants.FACTION_MONSTER, "entrance")
		actor.set_physics_process(false)
		actor.global_position = Vector2(540 if species == "spider_tailor" else 790, 430)
		game.monster_units.append(actor)
		actors[species] = actor
		_check_native(actor, species)
	game._set_screen(Constants.SCREEN_COMBAT, false)
	game.combat_paused = false
	game.combat_view_zoom = 1.45
	game.combat_camera.zoom = Vector2.ONE * 1.45
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await settle()
	for actor in actors.values(): _check_visible(actor)
	await _check_live_playback()
	await capture("native_base_idle")
	for animation in ["move_down", "attack_down", "skill_down", "down"]:
		for actor in actors.values():
			actor.sprite.play(animation)
			actor.sprite.frame = 1
			actor.sprite.speed_scale = 0.0
		await capture("native_" + animation)
	for species in SPECIES:
		await _check_cutin(actors[species], game.management_scene.monster_portrait_path(species), "base_" + species)
	await _check_popo_crown()
	game.queue_free()
	await settle()
	print("NATIVE_CONTRACT_PROFILE_GUI_REVIEW: %s (%d checks; %d failures)" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_native(actor: Node, species: String) -> void:
	var path := "res://assets/sprites/uiux3d/" + species + "_sheet.png"
	var legacy := "res://assets/sprites/monsters/update4/monster_" + species + "_sheet.png"
	var profile: Dictionary = DataRegistry.combat_visual_profile_for_unit(species, legacy)
	expect(str(profile.get("profile_key", "")) == species and str(profile.get("runtime_path", "")) == path, species + " old alias resolves to its own native profile")
	expect(str(actor.sprite_path) == path and not actor.requires_sprite_chroma, species + " actual current unit uses transparent native art")
	if actor.sprite.material != null:
		expect(actor.sprite.material is ShaderMaterial and actor.sprite.material.shader.resource_path == "res://scripts/dungeon_quarter/prepared_maze_actor_depth.gdshader", species + " only the existing wall-depth shader is attached")
		expect(not bool(actor.sprite.material.get_shader_parameter("chroma_key")), species + " wall-depth shader preserves native alpha without chroma removal")
	expect(str(actor.combat_visual_profile.normalization_state) == "NATIVE_ALPHA_RUNTIME_ATLAS", species + " native normalization is explicit")
	expect(is_equal_approx(actor.sprite.scale.x, float(profile.render_scale)), species + " actual profile scale is applied")
	expect(not ActorArt.entry(path).is_empty(), species + " registered packing metadata exists")
	for animation in ["idle_down", "move_down", "attack_down", "skill_down", "down"]:
		var count := 2 if animation in ["idle_down", "down"] else 4
		expect(actor.sprite.sprite_frames.get_frame_count(animation) == count, species + " " + animation + " complete frame count")
		for index in range(count):
			var frame = actor.sprite.sprite_frames.get_frame_texture(animation, index)
			expect(frame is AtlasTexture and frame.atlas.resource_path == path and frame.filter_clip and frame.get_size() == Vector2(384, 384), species + " " + animation + " own unclipped logical frame")
			var image = frame.get_image()
			expect(image != null and image.get_used_rect().size.y > 0, species + " " + animation + " visible alpha content")

func _check_visible(actor: Node) -> void:
	var frame = actor.sprite.sprite_frames.get_frame_texture(actor.sprite.animation, actor.sprite.frame)
	var bounds: Rect2 = ActorArt.visible_bounds(frame)
	var transform: Transform2D = actor.sprite.get_global_transform_with_canvas()
	var top: Vector2 = transform * bounds.position
	var bottom: Vector2 = transform * bounds.end
	var rect := Rect2(top, bottom - top).abs()
	expect(actor.sprite.is_visible_in_tree() and rect.size.y > 40.0 and rect.size.y < 200.0, str(actor.unit_id) + " visible body has plausible physical size")
	expect(get_viewport().get_visible_rect().encloses(rect), str(actor.unit_id) + " visible body stays inside the actual GUI viewport")

func _check_cutin(actor: Node, portrait: String, name: String) -> void:
	game.combat_scene.skill_cutins.reset()
	game._set_screen(Constants.SCREEN_COMBAT, false)
	game.combat_paused = false
	game.story_combat_overlay_open = false
	game.selected_unit = actor
	UISettings.set_combat_cutin_mode("full", false)
	var cut = game.combat_scene.skill_cutins
	expect(cut.enqueue(actor, "native_profile_review", {"display_name": "현재 형태 검증"}), name + " cutin accepts current actor")
	cut.tick(0.11)
	cut.tick(0.11)
	expect(not cut.current.is_empty() and cut.panel != null, name + " actual cutin displayed")
	if cut.panel != null:
		expect(str(cut.panel.get_meta("cutin_portrait_path")) == portrait and cut.panel.get_node("SkillCutinArt").texture != null, name + " current portrait actually loaded")
		await capture("cutin_" + name)
	cut.reset()

func _check_live_playback() -> void:
	for speed in [1.0, 3.0]:
		for actor in actors.values():
			var state := {"changes": 0}
			var callback: Callable = func(): state.changes += 1
			actor.sprite.frame_changed.connect(callback)
			actor.set_simulation_speed(speed)
			actor.sprite.play("move_down")
			await get_tree().create_timer(0.20).timeout
			expect(int(state.changes) > 0 and actor.sprite.is_playing(), str(actor.unit_id) + " actual x%.0f animation advances" % speed)
			actor.sprite.frame_changed.disconnect(callback)
			actor.sprite.play("idle_down")
			actor.sprite.frame = 0
			actor.sprite.speed_scale = 0.0

func _check_popo_crown() -> void:
	var crown_id := "crown_popo_grand_night_courier"
	game.update4_active_run = {"campaign_mode_id": "council_season", "day": 23, "council_season": {"council_seals": 3, "crown_form_id": "", "crown_declined": false}}
	game.update4_profile = {"crown_evolution": {"species_mastery": {"bat_courier": 2}}}
	var instance := str(DataRegistry.monster("bat_courier").instance_id)
	expect(game._update4_required_choice_id() == "crown_choice", "real DAY23 crown decision is available")
	game._confirm_update4_crown(instance, crown_id)
	expect(str(game.update4_active_run.get("crown", {}).get("crown_form_id", "")) == crown_id, "actual crown confirmation succeeded")
	expect(int(game.update4_active_run.council_season.council_seals) == 1, "actual crown confirmation pays the existing two-seal cost")
	var crown: Dictionary = DataRegistry.update4_crown_evolutions[crown_id]
	var stats: Dictionary = game._scaled_monster_stats("bat_courier")
	expect(str(stats.get("crown_form_id", "")) == crown_id and str(stats.sprite) == str(crown.combat_sprite), "crown stats select their own current combat art")
	actors.bat_courier.setup("bat_courier", stats, Constants.FACTION_MONSTER, "entrance")
	actors.bat_courier.set_physics_process(false)
	expect(actors.bat_courier.sprite_path == str(crown.combat_sprite), "actual crowned Unit keeps crown atlas rather than the base alias")
	for animation in ["idle_down", "move_down", "attack_down", "skill_down", "down"]:
		for index in range(actors.bat_courier.sprite.sprite_frames.get_frame_count(animation)):
			var frame = actors.bat_courier.sprite.sprite_frames.get_frame_texture(animation, index)
			expect(frame is AtlasTexture and frame.atlas.resource_path == str(crown.combat_sprite) and frame.get_size() == Vector2(384, 384), "crown " + animation + " uses its own complete native frame")
	await _check_cutin(actors.bat_courier, str(crown.portrait), "crown_popo")
	game.update4_active_run["upper_floor"] = {"crown_suppressed": true}
	stats = game._scaled_monster_stats("bat_courier")
	expect(not stats.has("crown_form_id") and str(stats.sprite) == str(DataRegistry.monster("bat_courier").sprite), "crown suppression restores current base art")
	actors.bat_courier.setup("bat_courier", stats, Constants.FACTION_MONSTER, "entrance")
	actors.bat_courier.set_physics_process(false)
	await _check_cutin(actors.bat_courier, str(DataRegistry.monster("bat_courier").portrait), "suppressed_popo")
