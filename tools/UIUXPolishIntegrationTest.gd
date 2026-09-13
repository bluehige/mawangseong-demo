extends "res://tools/BalanceSimulation.gd"
const Director = preload("res://scripts/story/StoryDirector.gd")
const Unit = preload("res://scripts/units/Unit.gd")
const ResultModel = preload("res://scripts/v122/ui/V122CombatResultViewModel.gd")
var checks := 0
var polish_failed := false
var output := "res://tmp/uiux_polish_20260913/direct"
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		polish_failed = true
		push_error("POLISH_ASSERT_FAIL: " + label)
func settle(n: int = 3) -> void:
	for i in range(n):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
func snap(name: String) -> void:
	await settle()
	expect(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png") == OK, name+" capture")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	await movement_contract()
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		UISettings.text_scale = 1.0 if resolution.x == 1920 else 1.15
		var g = GameRootScene.instantiate()
		add_child(g)
		await settle(5)
		g.campaign_save_enabled = false
		g._debug_skip_onboarding()
		GameState.day = 30
		_apply_final_campaign_setup(g)
		g.combat_speed_intro_seen = true
		g._set_screen(Constants.SCREEN_MANAGEMENT)
		g.story_feature_enabled = true
		for route in ["d28_siege_route_recon","d28_siege_engineer_disruption"]:
			g.story_director.reset_for_new_game()
			_apply_raid_choice(g,route)
			g._request_combat_start()
			expect(g.story_director.current_scene_id == "STORY_D30_PRECOMBAT",route+" actual preparation entry")
			expect(g.story_director.cue_count() == 6 and g.enemy_units.is_empty(),route+" six preparation lines before enemy spawn")
			await snap("%d_brief_%s" % [resolution.x,route])
			var saved: Dictionary = g.story_director.export_state()
			saved.current_cue_id = "STORY_D30_PRECOMBAT_059"
			saved.cursor = 40
			var restored = Director.new()
			restored.setup(g.story_catalog,30)
			expect(restored.import_state(saved,30,true),"legacy precombat state imports")
			expect(str(restored.current_cue_id).ends_with("BRIEF_001"),"legacy battle cue migrates to preparation")
			g.story_director.reset_for_new_game()
			g.pending_precombat_snapshot.clear()
			g._set_screen(Constants.SCREEN_MANAGEMENT)
		g.story_feature_enabled = false
		g._start_combat()
		await settle(4)
		expect(g.current_screen == Constants.SCREEN_COMBAT,"real combat initialized")
		g.set_physics_process(false)
		for unit in g.monster_units + g.enemy_units: unit.set_physics_process(false)
		g.story_feature_enabled = true
		g.story_director.reset_for_new_game()
		g.combat_story_feed.clear()
		var event_scene: Dictionary = g.story_catalog.scene("STORY_D30_EVENT_OATH_END")
		expect(not g._story_runtime_scene_ready(event_scene,"combat_time",{"combat_time":999,"combat_events":{}}),"time alone cannot announce a shield ending")
		g.combat_scene.spawn_enemy("official_hero_leon")
		var leon = _unit_by_id(g.enemy_units,"official_hero_leon")
		leon.set_physics_process(false)
		g.combat_scene.final_oath_activations = 1
		leon.shield_timer = 2.0
		expect(not g._story_live_combat_events().oath_ended,"active shield does not announce its end")
		leon.shield_timer = 0.0
		expect(g._story_live_combat_events().oath_ended,"actual shield expiration opens event")
		g._story_queue_combat_trigger("combat_time",{"combat_time":g.combat_time})
		g.combat_story_feed.tick(g,0.01)
		await settle()
		expect(not g.combat_paused and not g.story_combat_overlay_open,"ordinary reaction never pauses battle")
		var feed: Control = g.ui_layer.find_child("StoryCombatFeed",true,false)
		expect(feed != null and feed.mouse_filter == Control.MOUSE_FILTER_IGNORE and feed.focus_mode == Control.FOCUS_NONE,"reaction cannot steal map input or focus")
		expect(str(g.combat_story_feed.reader.current_cue_id) == "STORY_D30_PRECOMBAT_059","urgent shield fact is first visible cue")
		var queued: int = g.combat_story_feed.pending.size()
		g._story_queue_combat_trigger("combat_time",{"combat_time":g.combat_time})
		expect(g.combat_story_feed.pending.size() == queued,"same event is offered only once per battle")
		await snap("%d_live_reaction" % resolution.x)
		g.combat_story_feed.tick(g,6.0)
		expect(g.story_director.seen_cue_ids.has("STORY_D30_PRECOMBAT_059"),"consumed reaction retains stable read ID")
		expect(g.story_director.archive_scenes(30).any(func(s): return s.id == "STORY_D30_EVENT_OATH_END"),"partly read reaction can be revisited in archive")
		var u = g.monster_units.front()
		var original_role: String = str(u.role)
		for role in ["blocker","chaser","caster","support_blocker","vault_guard","zone_support"]:
			u.role = role
			expect(g.hud._combat_unit_role_label(u,false) != role,"localized role "+role)
		u.role = original_role
		expect(g.display_name_for_instance("path_a_entry_front") == "정문 진입 복도","path label is a readable place")
		g.combat_story_feed.clear()
		g.combat_time = 50.0
		var before: int = g.effect_root.get_child_count()
		g.combat_scene.spawn_damage_number(u.global_position,11,u.faction,u)
		g.combat_scene.spawn_damage_number(u.global_position,7,u.faction,u)
		expect(g.effect_root.get_child_count() == before+1,"rapid hits share one visual label")
		var damage = g.effect_root.get_child(g.effect_root.get_child_count()-1)
		expect(damage.text == "-18" and damage.get_meta("damage_total") == 18,"merged hit label preserves total damage")
		g.combat_time += 0.2
		g.combat_scene.spawn_damage_number(u.global_position,5,u.faction,u)
		expect(g.effect_root.get_child_count() == before+2,"later hit receives its own label")
		for rule_id in DataRegistry.evolution_rules:
			var rule: Dictionary = DataRegistry.evolution_rules[rule_id]
			for mood in ["portrait"]:
				var tex: Texture2D = g._load_png(str(rule[mood]))
				expect(tex is AtlasTexture and tex.get_size() == Vector2(512,512),"native portrait "+str(rule_id))
		u.current_room = "path_a_entry_front"
		g._select_unit(u)
		await settle(6)
		expect(str(g.hud.selected_unit_dynamic_labels["room"].text) == "정문 진입 복도", "live HUD refresh preserves readable location")
		print("POLISH_PORTRAIT_PATH "+str(g.management_scene.monster_portrait_path(str(u.unit_id))))
		await snap("%d_promoted_inspector" % resolution.x)
		g.story_feature_enabled = false
		g._set_screen(Constants.SCREEN_MANAGEMENT)
		g._select_room("slot_01")
		g._open_management_context_drawer()
		expect(g._build_preview_route_line("slot_01").begins_with("효과 적용:"),"prepared maze facility shows its actual linked zone")
		await snap("%d_facility_zone" % resolution.x)
		for rule_id in DataRegistry.evolution_rules:
			var rule: Dictionary = DataRegistry.evolution_rules[rule_id]
			var monster_id: String = str(rule.monster_id)
			g.monster_roster[monster_id]["promotion_id"] = rule_id
			g._select_monster(monster_id)
			await settle()
			var role_label: Label = g.ui_layer.find_child("MonsterRole",true,false)
			expect(role_label != null and not role_label.text.contains(str(rule.role_tag)), "monster management does not expose role ID")
			await snap("%d_portrait_%s" % [resolution.x,rule_id])
		g.result_summary = {"win":false,"metrics":{"decision_context":{"built_facilities":["watch_post"]},"facility_effects":{"watch_post_bonus_damage":0,"watch_post_slow_applications":0}}}
		g._set_screen(Constants.SCREEN_RESULT)
		await snap("%d_zero_effect_record" % resolution.x)
		var note: Label = g.ui_layer.find_child("ResultFacilityFeedback",true,false)
		expect(note != null and note.text.contains("추가 피해 0"),"actual result screen shows recorded zero contribution")
		if note != null: expect(note.get_line_count()*note.get_line_height() <= note.size.y + 2,"facility note fits at current text scale")
		g.queue_free()
		await settle()
	var zero := ResultModel._facility_feedback({"decision_context":{"built_facilities":["watch_post"]},"facility_effects":{"watch_post_bonus_damage":0,"watch_post_slow_applications":0}})
	expect(zero.contains("추가 피해 0") and zero.contains("경로"),"zero contribution suggests checking overlap without inventing cause")
	expect(ResultModel._facility_feedback({}) == "","missing facility record is not a fabricated zero")
	print("UIUX_POLISH_INTEGRATION_TEST: %s (%d assertions)" % ["FAIL" if polish_failed else "PASS",checks])
	get_tree().quit(1 if polish_failed else 0)
func movement_contract() -> void:
	var u = Unit.new()
	add_child(u)
	u.setup("slime",DataRegistry.monster("slime"),Constants.FACTION_MONSTER,"entrance")
	u.set_physics_process(false)
	u.move_speed = 100.0
	u.intrinsic_move_multiplier = 1.0
	for speed in [1.0,3.0]:
		u.set_simulation_speed(speed)
		u.global_position = Vector2(100,100)
		u.set_path([Vector2(101,100),Vector2(101,150)])
		u._physics_process(0.02)
		expect(is_equal_approx(u.global_position.x,101) and u.global_position.y > 100,"remaining distance turns exact corner at x"+str(speed))
		expect(u.velocity.length() > 0 and not u.path_points.is_empty(),"corner does not insert a stop frame")
		for i in range(100): u._physics_process(0.02)
		expect(u.path_points.is_empty() and u.global_position.distance_to(Vector2(101,150)) < 0.05,"endpoint reached without overshoot at x"+str(speed))
	u.queue_free()
	await settle()
