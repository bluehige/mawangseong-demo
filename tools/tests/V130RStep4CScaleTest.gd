extends "res://tools/tests/V130RStep4BScaleTest.gd"
const C_OUT := "res://tmp/v130r_step4c/"
const Plan = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
var masks: Array = []

func direct_c() -> void:
	await scale_direct()
	for id in ["stone_sentinel","bronze_automaton","root_tender"]:
		expect(is_equal_approx(ScaleRules.multiplier(id),1.15),"existing large data "+id)
	for id in ScaleRules.BOSSES:
		expect(is_equal_approx(ScaleRules.multiplier(id),1.35),"boss "+id)
	for id in ["bronze_automaton","root_tender"]: battle.spawn_enemy(id,{})
	scale_contract()
	for unit in game.monster_units+game.enemy_units:
		for animation in unit.sprite.sprite_frames.get_animation_names():
			if animation.begins_with("down"): continue
			for index in range(unit.sprite.sprite_frames.get_frame_count(animation)):
				unit.sprite.animation = animation; unit.sprite.frame = index
				unit.attack_anim_timer = unit.ATTACK_ANIM_DURATION*.8
				unit._apply_visual_pose()
				var texture: Texture2D = unit.sprite.sprite_frames.get_frame_texture(animation,index)
				var extent: Vector2 = ScaleRules.visible_bounds(texture).size*unit.sprite.scale
				var actual := absf(sin(unit.sprite.rotation))*extent.x+absf(cos(unit.sprite.rotation))*extent.y
				var target: float = ScaleRules.BODY_HEIGHT*ScaleRules.multiplier(unit.unit_id)
				expect(actual>=target-.01 and actual<=target*1.06+.01,"animated alpha extent stays readable "+unit.unit_id+" "+animation+str(index))
		unit.attack_anim_timer = 0; unit._play_animation("idle_down")
		unit.visual_phase = 0; unit._apply_visual_pose()
		var frame: Texture2D = unit.sprite.sprite_frames.get_frame_texture(unit.sprite.animation,unit.sprite.frame)
		var bounds: Rect2 = ScaleRules.visible_bounds(frame)
		var foot: Vector2 = Vector2(bounds.get_center().x,bounds.end.y)-frame.get_size()/2
		if unit.sprite.flip_h: foot.x *= -1
		expect((unit.visual_body.position+(foot*unit.sprite.scale).rotated(unit.sprite.rotation)).length()<.01,"alpha foot at cell center "+unit.unit_id)
	view.battle_ui.select_unit(game.monster_units[0])
	for zoom in [.5,.75,1.0]:
		view.set_camera(view.camera_center,zoom); view.battle_ui.position_skills(); view.battle_ui.layout_vitals()
		var unit: Node = game.monster_units[0]
		expect(is_equal_approx(unit.vitals.get_global_transform_with_canvas().get_scale().y,ScaleRules.ui_scale(unit.unit_id)*zoom),"vitals follow map zoom")
		expect(is_equal_approx(view.battle_ui.skills.get_global_transform_with_canvas().get_scale().y,ScaleRules.ui_scale(unit.unit_id)*zoom),"skill icons follow map zoom")
		var size: float = unit.idle_bounds.size.y*unit.sprite.get_global_transform_with_canvas().get_scale().y
		expect(is_equal_approx(size,ScaleRules.BODY_HEIGHT*zoom),"body follows map zoom")

func freeze() -> void:
	battle.set_pause_state(true); view.set_physics_process(false)
	for unit in game.monster_units+game.enemy_units:
		unit.set_physics_process(false); unit.set_process(false); unit.sprite.pause(); unit.refresh_depth_slot()
	view.battle_ui.set_process(false); view.battle_ui.position_skills(); view.battle_ui.layout_vitals()

func alpha_shot(name: String, actors: Array) -> void:
	# The opaque scene image cannot reveal body alpha under occlusion. Render an
	# auxiliary transparent pass with the SAME live sprite, frame and screen matrix.
	# These masks are measurement evidence, never composited into the scene shot.
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==Vector2i(1920,1080),"native scene "+name)
	expect(image.save_png(C_OUT+name+".png")==OK,"save scene "+name)
	var viewport := SubViewport.new(); viewport.size = Vector2i(1920,1080)
	viewport.transparent_bg = true; viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var rows := []
	for actor in actors:
		var source: Node2D = actor.sprite if "sprite" in actor else actor
		var id: String = actor.unit_id if "unit_id" in actor else view.monster_ui.members[str(actor.name)].species_id
		var clone: Node2D = source.duplicate(0)
		viewport.add_child(clone)
		clone.transform = source.get_global_transform_with_canvas(); clone.z_index = 0; clone.show()
		if clone is AnimatedSprite2D: clone.pause()
		var path: String = "alpha/"+name+"_"+id+".png"
		await get_tree().process_frame; await RenderingServer.frame_post_draw
		expect(viewport.get_texture().get_image().save_png(C_OUT+path)==OK,"save alpha "+path)
		rows.append({"id":id,"name":actor.display_name if "display_name" in actor else view.monster_ui.members[str(actor.name)].display_name,
			"class":ScaleRules.size_class(id),"multiplier":ScaleRules.multiplier(id),"mask":path,
			"zoom":view.camera_scale,"frame":source.frame if source is AnimatedSprite2D else 0,
			"matrix":[source.global_position.x,source.global_position.y,source.global_scale.x,source.global_scale.y]})
		clone.free()
	viewport.queue_free()
	masks.append({"capture":name,"grade":view.placement.get("grade","E"),"day":view.placement.day,"units":rows})

func visible_representatives() -> Array:
	var chosen := []; var ids := {}
	# Include enemies first. Keep at least six DISTINCT species fully on screen.
	for unit in game.enemy_units+game.monster_units:
		if not unit.is_alive() or ids.has(unit.unit_id): continue
		var frame: Texture2D = unit.sprite.sprite_frames.get_frame_texture(unit.sprite.animation,unit.sprite.frame)
		var bounds: Rect2 = ScaleRules.visible_bounds(frame)
		var rect: Rect2 = unit.sprite.get_global_transform_with_canvas()*Rect2(bounds.position-frame.get_size()/2,bounds.size)
		if not Rect2(0,180,1920,680).encloses(rect): continue
		chosen.append(unit); ids[unit.unit_id] = true
		if chosen.size()==6: break
	expect(chosen.size()==6,"six on-screen species")
	return chosen

func battle_capture(name: String) -> void:
	start()
	var frames := 0
	while battle.running and battle.contacts.is_empty() and frames<6000:
		await get_tree().process_frame; frames += 1
	expect(not battle.contacts.is_empty(),name+" original wave reaches contact")
	freeze()
	evidence[name] = {"contacts":battle.contacts.size(),"spawned":game.spawned_count,"wave_total":game.wave_manager.total_to_spawn,"time":game.combat_time}
	await alpha_shot(name,visible_representatives())

func capture_c() -> void:
	# Placement uses the unchanged default E camera, with all fourteen test-unlocked.
	view.monster_ui.assignments = Model.auto_place(view.placement,view.monster_ui.members,view.monster_ui.members.keys(),100)
	view.render_map(); view.monster_ui.set_mode("place"); view.show_default()
	var placed := []
	for id in ["mon_core_pudding","mon_core_gob","mon_core_pynn","mon_contract_dolkong","mon_contract_dudum","mon_contract_mori"]:
		placed.append(view.monster_ui.units[id])
	await alpha_shot("place_scale",placed)
	await battle_capture("battle_e_day7")
	# A paused crowded fixture explicitly includes both boss and large classes.
	battle._clear_active_combat_tweens()
	for child in game.effect_root.get_children(): child.free()
	for id in ["official_hero_leon","selen_trainee_paladin","bronze_automaton","root_tender"]: battle.spawn_enemy(id,{})
	var focus: Vector2 = battle.home(game.monster_units[0])
	var units: Array = game.monster_units+game.enemy_units
	for i in range(units.size()):
		units[i].position = focus+Vector2((i%5)*50-100,(i/5)*36-54)
		units[i].refresh_depth_slot()
	view.set_camera(focus+Vector2(0,-120),.75)
	view.battle_ui.select_unit(game.monster_units[0]); freeze()
	var reps := [game.monster_units[0],game.monster_units[1]]
	for unit in game.enemy_units:
		if unit.unit_id in ["official_hero_leon","selen_trainee_paladin","bronze_automaton","root_tender"]: reps.append(unit)
	await alpha_shot("crowd",reps)
	for i in range(units.size()):
		for j in range(i+1,units.size()):
			expect(not units[i].vitals_rect().intersects(units[j].vitals_rect()),"crowded vitals disjoint")
	evidence["crowd"] = {"fixture":"paused synthetic overlap","units":units.size()}
	await stop(); preview = null; battle = null
	await boot()
	view.placement = Buildings.initial(game,"F"); view.placement.day = 3
	view.monster_ui.assignments = Model.auto_place(view.placement,view.monster_ui.members,view.monster_ui.members.keys(),100)
	view.state = Plan.read("F"); view.render_map(); view.show_default()
	expect(view.set_preview_day(3).ok,"F DAY3 preview updates grade/day HUD")
	# F placement and E placement must use the exact same alpha height rule.
	for id in view.monster_ui.units:
		var sprite: Sprite2D = view.monster_ui.units[id]
		var species: String = view.monster_ui.members[id].species_id
		expect(is_equal_approx(ScaleRules.visible_bounds(sprite.texture).size.y*sprite.scale.y,ScaleRules.BODY_HEIGHT*ScaleRules.multiplier(species)),"F placement same height "+species)
	await battle_capture("battle_f_day3")
	var f := FileAccess.open(C_OUT+"alpha_manifest.json",FileAccess.WRITE); f.store_string(JSON.stringify(masks,"\t")); f.close()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(C_OUT+"alpha"))
	if OS.get_cmdline_user_args().has("--capture"): mode = "capture"
	elif OS.get_cmdline_user_args().has("--performance"): mode = "performance"
	var prior := {}
	for path in [Model.SAVE_PATH,Buildings.SAVE_PATH,"res://tmp/v130r_step5/copies/progression_test.json"]:
		prior[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	await boot()
	if mode=="direct": await direct_c()
	elif mode=="capture": await capture_c()
	else: await performance()
	for path in prior: expect(prior[path]==(FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()),"prior saves unchanged "+path)
	await stop()
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"evidence":evidence}
	var f := FileAccess.open(C_OUT+mode+"_result.json",FileAccess.WRITE); f.store_string(JSON.stringify(result,"\t")); f.close()
	print("V130RStep4CScaleTest ",mode," ",checks," checks / ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
