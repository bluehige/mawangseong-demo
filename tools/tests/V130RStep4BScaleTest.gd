extends "res://tools/tests/V130RStep4BattleTest.gd"
const ScaleRules = preload("res://scripts/map_builder/ApprovedActorPresentation.gd")
const SCALE_OUT := "res://tmp/v130r_step4b/"

func scale_contract() -> void:
	for unit in game.monster_units+game.enemy_units:
		unit.velocity = Vector2.ZERO; unit.attack_anim_timer = 0; unit.hit_anim_timer = 0; unit.skill_anim_timer = 0
		unit.presentation_skill_anim_timer = 0; unit._play_animation("idle_down"); unit._apply_visual_pose()
		var size: Vector2 = unit.idle_bounds.size*unit.body_factor
		var height: float = ScaleRules.BODY_HEIGHT*ScaleRules.multiplier(unit.unit_id)
		expect((unit.idle_bounds.size*unit.sprite.scale).distance_to(size)<.01,"actual sprite transform matches visible target "+unit.unit_id)
		expect(is_equal_approx(size.y,height),"alpha body fills target height "+unit.unit_id)
		expect(is_equal_approx(unit.health.size.x*unit.vitals.scale.x,76*ScaleRules.ui_scale(unit.unit_id)),"HP width follows body "+unit.unit_id)
		unit.refresh_depth_slot()
		expect(unit.map_visual.z_index==ScaleRules.depth(unit.position),"foot Y depth "+unit.unit_id)
		if unit.faction=="monster" and unit.has_meta("instance_id"):
			var placed: Sprite2D = view.monster_ui.units[unit.get_meta("instance_id")]
			var placed_size := ScaleRules.visible_bounds(placed.texture).size*placed.scale
			expect(placed_size.distance_to(size)<.01,"placement equals live visible body "+unit.unit_id)
		var stable: Vector2 = unit.sprite.scale
		unit._apply_visual_pose(); unit._apply_visual_pose()
		expect(unit.sprite.scale.distance_to(stable)<.01,"pose updates do not compound scale "+unit.unit_id)
	view.battle_ui.layout_vitals()
	var units: Array = game.monster_units+game.enemy_units
	for i in range(units.size()):
		if not units[i].is_alive(): continue
		for j in range(i+1,units.size()):
			if units[j].is_alive(): expect(not units[i].vitals_rect().intersects(units[j].vitals_rect()),"vitals do not overlap")

func scale_direct() -> void:
	start(); view.set_physics_process(false); battle.set_pause_state(true)
	for id in ["explorer","thief","trainee_hero","official_hero_leon","selen_trainee_paladin"]: battle.spawn_enemy(id,{})
	scale_contract()
	var normal = game.enemy_units[0]
	var boss = game.enemy_units[-1]
	expect(ScaleRules.multiplier(boss.unit_id)==1.35 and ScaleRules.multiplier(normal.unit_id)==1,"boss 1.35 multiplier")
	expect(boss.name_label.text=="셀렌" and game.enemy_units[-2].name_label.text=="레온","boss identities are not truncated")
	var point: Vector2 = normal.position
	battle.spawn_impact(point)
	var fx: AnimatedSprite2D = game.effect_root.get_children().filter(func(c): return c is AnimatedSprite2D)[-1]
	var ratio: float = battle.effect_body_ratio(fx.position)
	expect(fx.scale.distance_to(Vector2.ONE*.72*ratio)<.01,"impact proportional to unit")
	await get_tree().create_timer(.22).timeout
	expect(fx.scale.x>=.72*ratio,"impact tween retains proportional scale")
	var behind = game.monster_units[0]; var front = game.monster_units[1]
	behind.position = point; front.position = point+Vector2(0,5)
	behind.refresh_depth_slot(); front.refresh_depth_slot()
	expect(behind.map_visual.z_index<front.map_visual.z_index,"overlapping units sorted back to front")
	# Save quantitative comparison; the camera is exactly the same world transform.
	var pudding = game.monster_units[0]
	evidence["scale"] = {"body_height_world":ScaleRules.BODY_HEIGHT,"zoom":view.camera_scale,"pudding_visible_world":str(pudding.idle_bounds.size*pudding.body_factor),"boss_multiplier":ScaleRules.BOSS_MULTIPLIER,"monsters":game.monster_units.size(),"enemies":game.enemy_units.size()}

func scale_shot(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==Vector2i(1920,1080),"native screenshot "+name)
	expect(image.save_png(SCALE_OUT+name+".png")==OK,"save "+name)

func scale_capture() -> void:
	view.monster_ui.set_mode("place")
	view.set_camera(view.START_CENTER,.75)
	await scale_shot("scale_place")
	var camera: Vector2 = view.camera_center
	var zoom: float = view.camera_scale
	start(); battle.set_pause_state(true)
	for unit in game.monster_units: unit.refresh_depth_slot(); unit._apply_visual_pose()
	view.battle_ui.layout_vitals()
	expect(view.camera_center==camera and view.camera_scale==zoom,"same camera placement and battle")
	scale_contract()
	await scale_shot("scale_battle")
	battle.set_pause_state(false)
	var frames := 0
	while battle.running and battle.contacts.is_empty() and frames<6000:
		await get_tree().process_frame; frames += 1
	expect(not battle.contacts.is_empty(),"real wave reaches contact")
	battle.set_pause_state(true)
	view.battle_ui.layout_vitals()
	await scale_shot("battle_contact")
	evidence["contact"] = battle.contacts.duplicate(true)
	# Deliberately crowded paused fixture; stats and campaign data stay unchanged.
	view.set_physics_process(false)
	for id in ["official_hero_leon","selen_trainee_paladin","explorer","thief"]: battle.spawn_enemy(id,{})
	battle.set_pause_state(true)
	var focus: Vector2 = battle.home(game.monster_units[0])
	var units: Array = game.monster_units+game.enemy_units
	for i in range(units.size()):
		units[i].position = focus+Vector2((i%4)*38-57,(i/4)*22-33)
		units[i].refresh_depth_slot()
	view.set_camera(focus+Vector2(170,-100),.75)
	view.battle_ui.select_unit(game.monster_units[0])
	scale_contract()
	await scale_shot("battle_crowd")
	evidence["crowd"] = {"fixture":"paused synthetic overlap","units":units.size(),"camera_scale":view.camera_scale}

func diagnose() -> void:
	# Diagnostic replay after the comparable live performance window, not its samples.
	view.set_physics_process(false)
	for unit in game.monster_units+game.enemy_units: unit.set_physics_process(false)
	var totals := {"controller_ms":0.0,"units_ms":0.0,"room_effects_ms":0.0,"room_refresh_ms":0.0}
	for i in range(120):
		var t := Time.get_ticks_usec(); battle.physics_process(1.0/60)
		totals.controller_ms += (Time.get_ticks_usec()-t)/1000.0
		t = Time.get_ticks_usec()
		for unit in game.monster_units+game.enemy_units: unit._physics_process(1.0/60)
		totals.units_ms += (Time.get_ticks_usec()-t)/1000.0
		t = Time.get_ticks_usec(); battle.update_room_effects(0)
		totals.room_effects_ms += (Time.get_ticks_usec()-t)/1000.0
		t = Time.get_ticks_usec(); battle.refresh_unit_rooms()
		totals.room_refresh_ms += (Time.get_ticks_usec()-t)/1000.0
	for key in totals: totals[key] /= 120
	evidence["diagnostic_replay"] = totals
	print("DIAGNOSTIC ",totals)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCALE_OUT))
	if OS.get_cmdline_user_args().has("--capture"): mode = "capture"
	elif OS.get_cmdline_user_args().has("--performance"): mode = "performance"
	var prior := {}
	for path in [Model.SAVE_PATH,Buildings.SAVE_PATH,"res://tmp/v130r_step5/copies/progression_test.json"]:
		prior[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	await boot()
	if mode=="direct": await scale_direct()
	elif mode=="capture": await scale_capture()
	else: await performance(); await diagnose()
	for path in prior: expect(prior[path]==(FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()),"prior test save unchanged "+path)
	await stop()
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"evidence":evidence}
	var file := FileAccess.open(SCALE_OUT+mode+"_result.json",FileAccess.WRITE); file.store_string(JSON.stringify(result,"\t")); file.close()
	print("V130RStep4BScaleTest ",mode," ",checks," checks / ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
