extends "res://tools/tests/V130RStep4CScaleTest.gd"
var D_OUT := "res://tmp/v130r_step4d/"
var label_manifest: Array = []

func rect_data(rect: Rect2) -> Array:
	return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]

func label_contract() -> void:
	view.battle_ui.layout_vitals()
	var units: Array = game.monster_units+game.enemy_units
	for i in range(units.size()):
		var unit: Node = units[i]
		if not unit.is_alive(): continue
		var desired: Vector2 = unit.desired_vitals_position(view.camera_scale)
		var body: Rect2 = unit.visible_body_rect()
		var box: Rect2 = unit.vitals_rect_at(desired)
		expect(absf((unit.raster_head_world_y()-box.end.y)*view.camera_scale-6)<.01,"head gap exactly six screen pixels "+unit.unit_id)
		expect(absf(unit.vitals.position.x-body.get_center().x)<.01,"collision keeps label above its own X "+unit.unit_id)
		expect(unit.map_visual.z_index==ScaleRules.depth(unit.position),"actor shares world foot depth")
		for j in range(i+1,units.size()):
			if units[j].is_alive(): expect(not unit.vitals_rect().intersects(units[j].vitals_rect()),"labels disjoint")

func direct_d() -> void:
	for piece in view.world.get_children():
		if piece.has_meta("map_depth"): expect(piece.z_index==0,"management overlays retain original draw order")
	start(); freeze()
	var debug_pieces := []
	for piece in view.world.get_children():
		if piece.has_meta("map_asset"):
			debug_pieces.append({"asset":piece.get_meta("map_asset"),"depth":piece.z_index,"rect":rect_data(piece.transform*piece.get_rect())})
	var roads := []
	for c in battle.map.layout.road_cells:
		var point: Vector2 = battle.map.world(c)
		roads.append([c.x,c.y,point.x,point.y])
	var f := FileAccess.open(D_OUT+"geometry.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"pieces":debug_pieces,"roads":roads},"\t")); f.close()
	for zoom in [.5,.75,1.0]:
		view.set_camera(view.camera_center,zoom)
		for unit in game.monster_units:
			var frame: Texture2D = unit.sprite.sprite_frames.get_frame_texture("idle_down",0)
			var raw := Rect2(frame.get_image().get_used_rect())
			if frame is AtlasTexture: raw.position += frame.margin.position
			expect(ScaleRules.visible_bounds(frame)==raw,"trimmed atlas margin restored "+unit.unit_id)
			for animation in unit.sprite.sprite_frames.get_animation_names():
				if animation.begins_with("down") or unit.sprite.sprite_frames.get_frame_count(animation)==0: continue
				unit.sprite.animation = animation; unit.sprite.frame = 0; unit.attack_anim_timer = .2
				unit._apply_visual_pose()
				var body: Rect2 = unit.visible_body_rect()
				var desired: Rect2 = unit.vitals_rect_at(unit.desired_vitals_position(zoom))
				expect(absf((unit.raster_head_world_y()-desired.end.y)*zoom-6)<.01,"pose/zoom follows alpha "+animation)
			unit.attack_anim_timer = 0; unit._play_animation("idle_down"); unit._apply_visual_pose()
		label_contract()
		var inverse: Transform2D = view.world.global_transform.affine_inverse()
		expect(game.monster_units[0].silhouette.material.get_shader_parameter("map_x")==Vector3(inverse.x.x,inverse.y.x,inverse.origin.x),"paused zoom updates silhouette coordinates")
	var count := 0
	for piece in view.world.get_children():
		if piece.has_meta("map_depth"):
			expect(piece.z_index==piece.get_meta("map_depth") and piece.z_index>0,"building and trap depth assigned")
			count += 1
	expect(count>30,"map elevated pieces participate in depth")
	var focus: Vector2 = battle.home(game.monster_units[0])
	for i in range(game.monster_units.size()):
		game.monster_units[i].position = focus+Vector2((i%4)*38,(i/4)*24)
		game.monster_units[i].refresh_depth_slot()
	view.battle_ui.select_unit(game.monster_units[0]); label_contract()
	var linked := 0
	for unit in game.monster_units:
		if unit.vitals_link.visible: linked += 1
	expect(linked>0,"displaced labels have a body connector")
	evidence["elevated_pieces"] = count
	var sample: Node = game.monster_units[0]
	var before: Vector2 = sample.desired_vitals_position(view.camera_scale)
	for unit in game.monster_units: unit.position.y += 32; unit.refresh_depth_slot()
	view.set_camera(view.camera_center+Vector2(0,32),view.camera_scale)
	var after: Vector2 = sample.desired_vitals_position(view.camera_scale)
	expect(absf(after.y-before.y-32)<.01,"camera-follow cache retains world coordinates")
	var samples: Array[float] = []
	for i in range(40):
		for unit in game.monster_units: unit.position.x += .25; unit.refresh_depth_slot()
		var begin := Time.get_ticks_usec(); view.battle_ui.layout_vitals()
		samples.append((Time.get_ticks_usec()-begin)/1000.0)
	var total := 0.0
	for value in samples: total += value
	samples.sort()
	evidence["moving_label_layout_cpu_ms"] = {"subjects":game.monster_units.size(),"samples":samples.size(),"mean":total/samples.size(),"p95":samples[int(samples.size()*.95)],"scope":"isolated moving-label CPU, not whole-game FPS"}

func raster_pass(source: Node2D, viewport: SubViewport, path: String) -> void:
	var clone := Sprite2D.new()
	clone.texture = source.sprite_frames.get_frame_texture(source.animation,source.frame) if source is AnimatedSprite2D else source.texture
	clone.transform = source.get_global_transform_with_canvas()
	clone.flip_h = source.flip_h; clone.flip_v = source.flip_v
	clone.texture_filter = source.texture_filter; clone.material = source.material
	viewport.add_child(clone)
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	expect(viewport.get_texture().get_image().save_png(D_OUT+path)==OK,"raster "+path)
	clone.free()

func evidence_shot(name: String) -> void:
	view.battle_ui.layout_vitals()
	for unit in game.monster_units+game.enemy_units: unit.update_silhouette()
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	expect(get_viewport().get_texture().get_image().save_png(D_OUT+name+".png")==OK,"scene "+name)
	var viewport := SubViewport.new(); viewport.size = Vector2i(1920,1080)
	viewport.world_2d = World2D.new(); viewport.disable_3d = true; viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; add_child(viewport)
	var rows := []
	for unit in game.monster_units+game.enemy_units:
		if not unit.is_alive() or not unit.map_visual.visible: continue
		var mask: String = "alpha/"+name+"_"+str(unit.get_instance_id())+".png"
		await raster_pass(unit.sprite,viewport,mask)
		var silhouette_mask: String = mask.replace("alpha/","silhouette/")
		await raster_pass(unit.silhouette,viewport,silhouette_mask)
		var box: Rect2 = view.world.global_transform*unit.vitals_rect()
		var desired: Rect2 = view.world.global_transform*unit.vitals_rect_at(unit.desired_vitals_position(view.camera_scale))
		rows.append({"id":unit.unit_id,"name":unit.display_name,"mask":mask,"silhouette":silhouette_mask,
			"body_predicted":rect_data(view.world.global_transform*unit.visible_body_rect()),"label":rect_data(box),
			"desired_label":rect_data(desired),"displacement_px":(unit.vitals.position.y-unit.desired_vitals_position(view.camera_scale).y)*view.camera_scale,
			"foot":[unit.position.x,unit.position.y],"cell":[battle.map.cell(unit.position).x,battle.map.cell(unit.position).y],"depth":unit.map_visual.z_index})
	viewport.queue_free()
	label_manifest.append({"capture":name,"grade":view.placement.get("grade","E"),"zoom":view.camera_scale,"units":rows})
	label_contract()

func contact_d(name: String) -> void:
	start()
	var frames := 0
	while battle.running and battle.contacts.is_empty() and frames<6000:
		await get_tree().process_frame; frames += 1
	expect(not battle.contacts.is_empty(),"original wave reaches contact "+name)
	freeze()
	evidence[name] = {"contacts":battle.contacts.size(),"spawned":game.spawned_count,"time":game.combat_time}
	await evidence_shot(name)

func occlusion_fixture() -> void:
	# A real road cell immediately behind an existing low front wall.
	var unit: Node = game.monster_units[0]
	unit.velocity = Vector2.ZERO; unit.attack_anim_timer = 0; unit.hit_anim_timer = 0; unit.skill_anim_timer = 0
	unit.presentation_skill_anim_timer = 0; unit._play_animation("idle_down"); unit._apply_visual_pose()
	var found := false
	for piece in view.world.get_children():
		if not piece.has_meta("map_asset") or not str(piece.get_meta("map_asset")).begins_with("building/front_"): continue
		var rect: Rect2 = piece.transform*piece.get_rect()
		for c in battle.map.layout.road_cells:
			var point: Vector2 = battle.map.world(c)
			if point.y>=piece.z_index-8 or point.y<piece.z_index-96: continue
			if absf(point.x-rect.get_center().x)>80: continue
			unit.position = point; unit.refresh_depth_slot()
			if not unit.visible_body_rect().intersects(rect): continue
			found = true
			evidence["occlusion_fixture"] = {"cell":[c.x,c.y],"asset":piece.get_meta("map_asset"),"wall_depth":piece.z_index,"unit_depth":unit.map_visual.z_index}
			break
		if found: break
	expect(found,"real road cell behind front rim exists")
	for other in game.monster_units+game.enemy_units:
		if other==unit: continue
		other.map_visual.hide(); other.vitals.hide(); other.silhouette.hide(); other.vitals_link.hide()
	view.set_camera(unit.position+Vector2(0,-90),1.0)
	# Keep hidden subjects out of the label solver for this isolated fixture.
	var monsters: Array = game.monster_units.duplicate(); var enemies: Array = game.enemy_units.duplicate()
	game.monster_units.assign([unit]); game.enemy_units.clear()
	await evidence_shot("occlusion_check")
	unit.silhouette.hide()
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(D_OUT+"occlusion_without_reveal.png")
	unit.silhouette.show()
	await backwall_control(unit)
	game.monster_units.assign(monsters); game.enemy_units.assign(enemies)

func backwall_control(unit: Node) -> void:
	# Control case: a road cell IN FRONT of a rear wall. No building may
	# erase the body or add a false silhouette just because it overlaps in 2D.
	var depth: Image = battle.occlusion.viewport.get_texture().get_image()
	var origin: Vector2 = battle.occlusion.bounds.position
	var found := false
	for piece in view.world.get_children():
		if not piece.has_meta("map_asset") or not str(piece.get_meta("map_asset")).begins_with("building/back_"): continue
		var rect: Rect2 = piece.transform*piece.get_rect()
		for c in battle.map.layout.road_cells:
			var point: Vector2 = battle.map.world(c)
			if point.y<piece.z_index+8 or point.y>piece.z_index+96 or absf(point.x-rect.get_center().x)>80: continue
			unit.position = point; unit.refresh_depth_slot()
			var body: Rect2 = unit.visible_body_rect()
			if not body.intersects(rect): continue
			var blocked := false
			for y in range(floori(body.position.y),ceili(body.end.y)):
				for x in range(floori(body.position.x),ceili(body.end.x)):
					var p := Vector2i(Vector2(x,y)-origin)
					if not Rect2i(Vector2i.ZERO,depth.get_size()).has_point(p): continue
					var color := depth.get_pixelv(p)
					var foot := (roundi(color.r*255)*256+roundi(color.g*255))/65535.0*3500
					if color.a>.5 and foot>unit.map_visual.z_index+.5: blocked = true; break
				if blocked: break
			if blocked: continue
			found = true
			evidence["backwall_control"] = {"cell":[c.x,c.y],"wall_depth":piece.z_index,"unit_depth":unit.map_visual.z_index}
			break
		if found: break
	expect(found,"road in front of rear wall without foreground blockers")
	view.set_camera(unit.position+Vector2(0,-90),1.0)
	await evidence_shot("backwall_control")

func capture_d() -> void:
	view.monster_ui.assignments = Model.auto_place(view.placement,view.monster_ui.members,view.monster_ui.members.keys(),100)
	view.render_map(); view.show_default()
	await contact_d("battle_e_day7")
	await occlusion_fixture()
	await stop(); preview = null; battle = null; await boot()
	view.placement = Buildings.initial(game,"F"); view.placement.day = 3
	view.monster_ui.assignments = Model.auto_place(view.placement,view.monster_ui.members,view.monster_ui.members.keys(),100)
	view.state = Plan.read("F"); view.render_map(); view.show_default()
	expect(view.set_preview_day(3).ok,"F DAY3 HUD")
	await contact_d("battle_f_day3")
	var f := FileAccess.open(D_OUT+"label_manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(label_manifest,"\t")); f.close()

func run() -> void:
	for path in ["alpha","silhouette"]: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(D_OUT+path))
	mode = "capture" if OS.get_cmdline_user_args().has("--capture") else "direct"
	var prior := {}
	for path in [Model.SAVE_PATH,Buildings.SAVE_PATH,"res://tmp/v130r_step5/copies/progression_test.json"]:
		prior[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	await boot()
	if mode=="capture": await capture_d()
	else: await direct_d()
	for path in prior: expect(prior[path]==(FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()),"prior test save preserved")
	await stop()
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"evidence":evidence}
	var f := FileAccess.open(D_OUT+mode+"_result.json",FileAccess.WRITE); f.store_string(JSON.stringify(result,"\t")); f.close()
	print("V130RStep4DLabelsTest ",mode," ",checks," checks / ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
