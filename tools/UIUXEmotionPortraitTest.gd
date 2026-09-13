extends "res://tools/BalanceSimulation.gd"

var assertions := 0
var emotion_failed := false
var evidence := "res://tmp/uiux_emotions_20260913/direct"

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		emotion_failed = true
		push_error("EMOTION_ASSERT_FAIL: " + label)

func settle(frames: int = 3) -> void:
	for i in range(frames):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

func capture(label: String) -> void:
	await settle()
	check(get_viewport().get_texture().get_image().save_png(evidence + "/" + label + ".png") == OK, label + " capture")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence))
	for resolution in [Vector2i(1920,1080), Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		UISettings.text_scale = 1.0 if resolution.x == 1920 else 1.15
		var g = GameRootScene.instantiate()
		g.campaign_save_enabled = false
		g.campaign_auxiliary_save_enabled = false
		g.campaign_save_v4_enabled = false
		g.campaign_save_v5_enabled = false
		add_child(g)
		await settle(5)
		g._debug_skip_onboarding()
		GameState.day = 30
		_apply_final_campaign_setup(g)
		g.story_feature_enabled = false
		g.combat_speed_intro_seen = true
		g._set_screen(Constants.SCREEN_MANAGEMENT)
		var manager = g.management_scene
		for rule_id in DataRegistry.evolution_rules:
			var rule: Dictionary = DataRegistry.evolution_rules[rule_id]
			var species := str(rule.monster_id)
			g.monster_roster[species].promotion_id = rule_id
			for mood in ["victory", "wounded"]:
				var path: String = manager.monster_portrait_path(species,mood)
				var tex = load(path) as Texture2D
				check(path == str(rule.portrait_variants[mood]) and path != str(rule.portrait),str(rule_id)+" unique "+mood)
				check(tex is AtlasTexture and tex.get_size() == Vector2(512,512),str(rule_id)+" large "+mood)
		for crown_id in DataRegistry.update4_crown_evolutions:
			var crown: Dictionary = DataRegistry.update4_crown_evolutions[crown_id]
			var species := str(crown.monster_id)
			var instance_id := ""
			for candidate in DataRegistry.monster_instances:
				if str(DataRegistry.monster_instances[candidate].get("species_id","")) == species:
					instance_id = str(candidate)
					break
			if not g.monster_roster.has(species):
				g.monster_roster[species] = {"level":6,"exp":0,"room":"entrance"}
			g.update4_active_run = {"campaign_mode_id":"council_season","crown":{"selected_instance_id":instance_id,"crown_form_id":crown_id},"upper_floor":{}}
			check(instance_id != "",str(crown_id)+" real instance")
			for mood in ["victory", "wounded"]:
				var path: String = manager.monster_portrait_path(species,mood)
				var tex = load(path) as Texture2D
				check(path == str(crown["portrait_"+mood]),str(crown_id)+" active "+mood)
				check(tex is AtlasTexture and tex.get_size() == Vector2(512,512),str(crown_id)+" large "+mood)
				g.result_summary = {"win":true,"metrics":{"monster_outcomes":{species:{"hp":20 if mood == "wounded" else 100,"max_hp":100,"down":false}}}}
				g.last_growth_summary = [{"monster_id":species,"display_name":str(crown.display_name),"level_before":6,"level_after":6,"exp_gain":0}]
				g._set_screen(Constants.SCREEN_RESULT)
				await settle()
				var crown_portrait = g.ui_layer.find_child("ResultPortrait_"+species,true,false)
				check(crown_portrait != null and crown_portrait.texture == tex,str(crown_id)+" actual result "+mood)
				if resolution.x == 1920 or species == "slime" or species == "spore_healer":
					await capture(str(resolution.x)+"_"+str(crown_id)+"_"+mood)
			g.update4_active_run.upper_floor.crown_suppressed = true
			check(manager.monster_portrait_path(species,"wounded") != str(crown.portrait_wounded),str(crown_id)+" suppressed form fallback")
		g.update4_active_run.clear()
		for species in ["spore_healer","armored_beetle","bat_courier"]:
			g.monster_roster.erase(species)
		g.monster_roster.slime.promotion_id = "slime_gate_bulwark"
		g.monster_roster.goblin.promotion_id = "goblin_ambush_captain"
		g.monster_roster.imp.promotion_id = "imp_flame_adept"
		g._set_screen(Constants.SCREEN_MANAGEMENT)
		g._start_combat()
		await settle(3)
		g.combat_paused = true
		for unit in g.monster_units + g.enemy_units:
			unit.set_physics_process(false)
		check(g.current_screen == Constants.SCREEN_COMBAT,"actual combat starts")
		var slime = _unit_by_id(g.monster_units,"slime")
		var goblin = _unit_by_id(g.monster_units,"goblin")
		var imp = _unit_by_id(g.monster_units,"imp")
		check(slime != null and goblin != null and imp != null,"actual core actors")
		slime.hp = slime.max_hp
		g._select_unit(slime)
		await settle(5)
		var portrait = g.ui_layer.find_child("CombatUnitPortrait",true,false)
		check(portrait != null and portrait.texture == g._load_png(manager.monster_portrait_path("slime")),"healthy live neutral portrait")
		await capture(str(resolution.x)+"_combat_healthy")
		slime.hp = int(slime.max_hp * 0.2)
		await settle(8)
		check(portrait.texture == g._load_png(manager.monster_portrait_path("slime","wounded")),"live damage changes portrait without reselection")
		await capture(str(resolution.x)+"_combat_wounded")
		slime.hp = slime.max_hp
		await settle(8)
		check(portrait.texture == g._load_png(manager.monster_portrait_path("slime")),"live recovery restores neutral portrait")
		slime.hp = 0
		goblin.hp = goblin.max_hp
		imp.hp = int(imp.max_hp * 0.2)
		g.combat_scene.finish_combat(true,"초상 상태 연결 검증용 승리")
		await settle(5)
		check(g.current_screen == Constants.SCREEN_RESULT,"actual finish opens result")
		for species in ["slime","goblin","imp"]:
			var mood := "victory" if species == "goblin" else "wounded"
			check(manager.result_portrait_emotion(species) == mood,species+" real outcome mood")
			var result_portrait = g.ui_layer.find_child("ResultPortrait_"+species,true,false)
			check(result_portrait != null and result_portrait.texture == g._load_png(manager.monster_portrait_path(species,mood)),species+" actual result texture")
		await capture(str(resolution.x)+"_result_mixed")
		var scroll = g.ui_layer.find_child("ResultGrowthScroll",true,false)
		if scroll != null: scroll.scroll_vertical = 999
		await capture(str(resolution.x)+"_result_scroll")
		var payload: Dictionary = g._campaign_save_payload("result")
		var serialized: Dictionary = JSON.parse_string(JSON.stringify(payload))
		check(g._restore_campaign_payload(serialized),"serialized result payload restores")
		check(manager.result_portrait_emotion("slime") == "wounded" and manager.result_portrait_emotion("goblin") == "victory","restored real health moods survive")
		g.result_summary.metrics.erase("monster_outcomes")
		g.result_summary.win = false
		check(manager.result_portrait_emotion("slime") == "","old loss cannot invent injury")
		g.result_summary.win = true
		check(manager.result_portrait_emotion("slime") == "victory","old victory compatible fallback")
		check(manager.portrait_emotion_for_state({"hp":35,"max_hp":100}) == "wounded","35 percent threshold")
		check(manager.portrait_emotion_for_state({"hp":36,"max_hp":100}) == "","above threshold neutral")
		check(manager.portrait_emotion_for_state({"hp":0,"max_hp":0,"down":true},true) == "wounded","down overrides victory even without max hp")
		g.queue_free()
		await settle(3)
		await get_tree().create_timer(0.2,true,false,true).timeout
	print("UIUX_EMOTION_PORTRAIT_TEST: %s (%d assertions)" % ["FAIL" if emotion_failed else "PASS",assertions])
	get_tree().quit(1 if emotion_failed else 0)
