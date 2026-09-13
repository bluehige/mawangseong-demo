extends "res://tools/BalanceSimulation.gd"

var inspector_checks := 0
var inspector_failed := false
var evidence := "res://tmp/uiux_inspector_20260913/direct"

func check(ok: bool, label: String) -> void:
	inspector_checks += 1
	if not ok:
		inspector_failed = true
		push_error("INSPECTOR_ASSERT_FAIL: " + label)

func settle(n: int = 10) -> void:
	for i in range(n):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

func capture(label: String) -> void:
	await settle(3)
	check(get_viewport().get_texture().get_image().save_png(evidence+"/"+label+".png") == OK,label+" capture")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence))
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		for font_scale in [0.9,1.0,1.15]:
			DisplayServer.window_set_size(resolution)
			UISettings.text_scale = font_scale
			var tag := "%d_%d" % [resolution.x,roundi(font_scale*100)]
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
			g.monster_roster.slime.promotion_id = "slime_gate_bulwark"
			g._set_screen(Constants.SCREEN_MANAGEMENT)
			g._start_combat()
			await settle(3)
			g.combat_paused = true
			for u in g.monster_units + g.enemy_units: u.set_physics_process(false)
			var slime = _unit_by_id(g.monster_units,"slime")
			slime.hp = maxi(1,int(slime.max_hp*0.2))
			slime.intent_text = "함정 유도"
			slime.target_text = "함정 유도"
			g._select_unit(slime)
			await settle()
			var hud = g.hud
			var labels: Dictionary = hud.selected_unit_dynamic_labels
			check(str(labels.state.text).contains("체력 위험"),tag+" danger state uses words")
			check(labels.hp.get_theme_color("font_color") == Color("#ff9d7a"),tag+" danger health color")
			check(str(labels.objective.text).count("함정 유도") == 1,tag+" objective does not repeat directive intent")
			check(not str(labels.status.text).contains("함정 유도"),tag+" status does not repeat target already visible")
			check(hud._combat_unit_display_name(slime,false) == "성문 방벽 푸딩",tag+" evolution name matches portrait")
			check(hud._unique_combat_parts(["방 A · 수비","수비 · 적 B",""]) == "방 A · 수비 · 적 B",tag+" distinct target preserved")
			for key in ["hp","state","room","objective"]:
				var label: Label = labels[key]
				check(label.get_line_count()*label.get_line_height() <= label.size.y+2,tag+" "+key+" text height fits")
			await capture(tag+"_ally_danger")
			slime.armor_break_timer = 4.0
			slime.armor_break_amount = 3
			await settle()
			check(str(labels.status.text).contains("방어력 -3") and str(labels.status.text).contains("4.0초"),tag+" real debuff and duration preserved")
			await capture(tag+"_ally_debuff")
			slime.armor_break_timer = 0.0
			slime.hp = slime.max_hp
			await settle()
			check(not str(labels.state.text).contains("체력 위험") and labels.hp.get_theme_color("font_color") == Color("#eee5f4"),tag+" healing clears warning without reselection")
			slime.hp = 0
			await settle()
			check(str(labels.state.text) == "전투 불능",tag+" down state explicit")
			check(labels.hp.get_theme_color("font_color") == Color("#a49aaa"),tag+" down state color")
			g.combat_scene.spawn_enemy("engineer")
			var engineer = _unit_by_id(g.enemy_units,"engineer")
			check(engineer != null,tag+" actual engineer spawned")
			engineer.set_physics_process(false)
			engineer.role = "facility"
			engineer.armor_break_timer = 4.0
			engineer.armor_break_amount = 3
			g._select_unit(engineer)
			await settle(20)
			labels = hud.selected_unit_dynamic_labels
			check(str(labels.status.text).contains("시설 교란"),tag+" enemy threat survives repeated HUD refresh")
			check(str(labels.status.text).contains("방어력 -3"),tag+" enemy threat keeps concurrent debuff")
			await capture(tag+"_enemy_threat")
			engineer.receive_damage(99999)
			await settle()
			check(not str(labels.status.text).contains("시설 교란"),tag+" ended enemy threat disappears")
			g._clear_combat_unit_selection()
			await settle()
			check(g.ui_layer.find_child("CombatUnitInspector",true,false) == null,tag+" selection close releases inspector")
			g.queue_free()
			await settle(3)
			await get_tree().create_timer(0.2,true,false,true).timeout
	print("UIUX_INSPECTOR_READABILITY_TEST: %s (%d assertions)" % ["FAIL" if inspector_failed else "PASS",inspector_checks])
	get_tree().quit(1 if inspector_failed else 0)
