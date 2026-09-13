extends "res://tools/UIUXPreparedMazeTest.gd"
var metrics: Dictionary = {}
func _run() -> void:
	output = "res://tmp/uiux_actor_depth_20260913/after"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(1920,1080))
	game = Game.instantiate()
	add_child(game)
	await settle()
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.story_feature_enabled = false
	game.combat_speed_intro_seen = true
	GameState.day = 2
	GameState.player_name = "가림 검증"
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	set_stage("stage_02_castle")
	game.management_context_drawer_open = false
	game._set_management_tool_tab("roster")
	await settle(8)
	await shot("management_01_current_placed_bodies")
	var depth = game.quarter_renderer.maze_actor_depth
	var depth_image: Image = depth.viewport.get_texture().get_image()
	print("WALL_DEPTH ",depth.bounds," ",depth.depth_range," size=",depth_image.get_size())
	var checked := 0
	var worst := 0.0
	for face: Dictionary in game.quarter_renderer.maze_masonry.visible_back_faces + game.quarter_renderer.maze_masonry.visible_front_faces:
		var center := Vector2.ZERO
		for point: Vector2 in face.points: center += point
		center /= face.points.size()
		var pixel := Vector2i((center - depth.bounds.position) / depth.bounds.size * Vector2(depth_image.get_size()))
		var sample_point: Vector2 = depth.bounds.position + (Vector2(pixel)+Vector2(0.5,0.5)) / Vector2(depth_image.get_size()) * depth.bounds.size
		if not Geometry2D.is_point_in_polygon(sample_point, face.points): continue
		var color := depth_image.get_pixelv(pixel)
		if color.a < 0.5: continue
		var decoded: float = lerpf(depth.depth_range.x,depth.depth_range.y,(roundf(color.r*255)*256+roundf(color.g*255))/65535.0)
		var expected_depth: float = game.quarter_renderer.maze_masonry._depth_at(face,sample_point)
		worst = maxf(worst,absf(decoded-expected_depth))
		checked += 1
	expect(checked > 100,"GPU depth buffer contains actual high and low wall faces")
	expect(worst < 0.15,"GPU encoded wall depth matches geometric depth, error="+str(worst))
	metrics["depth_samples"] = checked
	metrics["max_world_pixel_depth_error"] = worst
	await management_pixels()
	await combat_spawn()
	for unit in game.monster_units + game.enemy_units:
		unit.set_physics_process(false)
		unit.refresh_depth_slot()
		expect(unit.sprite.material is ShaderMaterial and unit.sprite.material.shader == depth.ACTOR_SHADER,"live combat actor uses wall-depth shader "+unit.unit_id)
		expect(unit.z_index > game.quarter_renderer.front_wall_depth(),"masked combat actor is composited after walls")
	await shot("combat_02_masked_bodies")
	await combat_pixels()
	game.queue_free()
	await settle()
	var file := FileAccess.open(output.path_join("depth_results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions":count,"failed":failed,"captures":captures,"metrics":metrics},"\t"));file.close()
	print("UIUX_ACTOR_WALL_DEPTH_TEST: %s (%d assertions, %d captures)" % ["FAIL" if failed else "PASS",count,captures.size()])
	get_tree().quit(1 if failed else 0)

func screen_image() -> Image:
	await settle(3)
	return get_viewport().get_texture().get_image()

func delta_color(a: Color, b: Color) -> float:
	return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))

# Compare actual native framebuffer pixels against an independent wall geometry query.
# The unmasked image is a diagnostic control, not claimed as a pre-change build.
func verify_pixels(actor: CanvasItem, foot: Vector2, tag: String, bounds_world: Rect2) -> void:
	var mat := actor.material as ShaderMaterial
	expect(mat != null,"real actor material present "+tag)
	if mat == null: return
	actor.visible = false
	var background: Image = await screen_image()
	actor.visible = true
	mat.set_shader_parameter("occlusion_enabled",false)
	var unmasked: Image = await screen_image()
	mat.set_shader_parameter("occlusion_enabled",true)
	var masked: Image = await screen_image()
	actor.visible = false
	var background_after: Image = await screen_image()
	actor.visible = true
	var transform: Transform2D = get_viewport().get_stretch_transform() * game.get_global_transform_with_canvas()
	var screen_rect: Rect2 = (transform * bounds_world).intersection(Rect2(Vector2.ZERO,Vector2(masked.get_size())))
	var inverse := transform.affine_inverse()
	var hidden := 0;var preserved := 0;var hidden_ok := 0;var preserved_ok := 0
	var examples: Array = []
	var depth = game.quarter_renderer.maze_actor_depth
	var depth_image: Image = depth.viewport.get_texture().get_image()
	var walls: Array = game.quarter_renderer.maze_masonry.visible_back_faces + game.quarter_renderer.maze_masonry.visible_front_faces
	var relevant: Array = []
	for face: Dictionary in walls:
		if face.bounds.intersects(bounds_world): relevant.append(face)
	for y in range(ceili(screen_rect.position.y)+2,floori(screen_rect.end.y)-2,2):
		for x in range(ceili(screen_rect.position.x)+2,floori(screen_rect.end.x)-2,2):
			var point := Vector2i(x,y)
			if delta_color(background.get_pixelv(point),background_after.get_pixelv(point)) > 0.012: continue
			if delta_color(background.get_pixelv(point),unmasked.get_pixelv(point)) < 0.12: continue
			var world: Vector2 = inverse * (Vector2(point)+Vector2(0.5,0.5))
			var wall_depth := -INF
			var edge := false
			for face: Dictionary in relevant:
				if not Geometry2D.is_point_in_polygon(world,face.points): continue
				for i in face.points.size():
					if world.distance_to(Geometry2D.get_closest_point_to_segment(world,face.points[i],face.points[(i+1)%face.points.size()])) < 1.2: edge = true
				wall_depth = maxf(wall_depth,game.quarter_renderer.maze_masonry._depth_at(face,world))
			if edge or absf(wall_depth-foot.y) < 1.5: continue
			if wall_depth > foot.y:
				hidden += 1
				if delta_color(background.get_pixelv(point),masked.get_pixelv(point)) < 0.055: hidden_ok += 1
			else:
				preserved += 1
				if delta_color(unmasked.get_pixelv(point),masked.get_pixelv(point)) < 0.055: preserved_ok += 1
				elif examples.size() < 5:
					var pixel := Vector2i((world-depth.bounds.position)/depth.bounds.size*Vector2(depth_image.get_size()))
					var sample_color := depth_image.get_pixelv(pixel)
					var decoded: float = lerpf(depth.depth_range.x,depth.depth_range.y,(roundf(sample_color.r*255)*256+roundf(sample_color.g*255))/65535.0)
					examples.append({"screen":str(point),"world":str(world),"foot":foot.y,"geometry":wall_depth,"buffer":decoded,"coverage":sample_color.a,"param_foot":mat.get_shader_parameter("foot_depth"),"origin":str(mat.get_shader_parameter("wall_origin")),"background":str(background.get_pixelv(point)),"unmasked":str(unmasked.get_pixelv(point)),"masked":str(masked.get_pixelv(point))})
	var result := {"hidden_pixels":hidden,"correctly_hidden":hidden_ok,"front_or_open_pixels":preserved,"correctly_preserved":preserved_ok}
	metrics[tag] = result
	print("ACTOR_PIXELS ",tag," ",result)
	if (hidden > 0 and float(hidden_ok)/hidden <= 0.97) or (preserved > 0 and float(preserved_ok)/preserved <= 0.97):
		print("PIXEL_MISMATCH ",examples)
		background.save_png(output.path_join(tag+"_diagnostic_background.png"))
		unmasked.save_png(output.path_join(tag+"_diagnostic_unmasked.png"))
		masked.save_png(output.path_join(tag+"_diagnostic_masked.png"))
	expect(hidden+preserved > 35,tag+" actual textured body pixels measured")
	expect(hidden == 0 or float(hidden_ok)/hidden > 0.97,tag+" front wall hides the body")
	expect(preserved == 0 or float(preserved_ok)/preserved > 0.97,tag+" rear wall leaves the body visible")

func management_pixels() -> void:
	for i in range(3): await click(node("ZoomInManagementMapButton"))
	await shot("management_02_zoom_placed_bodies")
	# Stop overlay resynchronization only during framebuffer comparison. Actual roster positions remain unchanged.
	game.set_process(false)
	game.set_physics_process(false)
	for id in game.dungeon_renderer.roster_depth_nodes:
		var actor: Node2D = game.dungeon_renderer.roster_depth_nodes[id]
		await verify_pixels(actor,actor.position,"roster_"+id,Rect2(actor.position-Vector2(48,78),Vector2(96,96)))
	game.set_process(true)

func same_wall_pair() -> Dictionary:
	var masonry = game.quarter_renderer.maze_masonry
	var depth = game.quarter_renderer.maze_actor_depth
	var buffer: Image = depth.viewport.get_texture().get_image()
	var best: Dictionary = {}
	var best_score := -INF
	for face: Dictionary in masonry.visible_front_faces + masonry.visible_back_faces:
		if bool(face.top) or float(face.height) > masonry.HIGH or face.bounds.size.x < 20.0: continue
		var center := Vector2.ZERO
		for point: Vector2 in face.points: center += point
		center /= face.points.size()
		var ground_y: float = masonry._depth_at(face,center)
		for rear_distance in [14.0,24.0,36.0]:
			var behind := Vector2(center.x,ground_y-rear_distance)
			if not game.graph.is_walkable(behind): continue
			var behind_count := occlusion_score(behind,depth,buffer)
			for front_distance in [24.0,36.0,52.0]:
				var front := Vector2(center.x,ground_y+front_distance)
				if not game.graph.is_walkable(front): continue
				var front_count := occlusion_score(front,depth,buffer)
				var score := float(behind_count-front_count*3) - absf(behind_count-18)*0.5
				if score > best_score:
					best_score = score
					best = {"behind":behind,"front":front,"height":face.height}
	return best

func occlusion_score(foot: Vector2, depth, buffer: Image) -> int:
	var hits := 0
	for y in range(-60,1,10):
		for x in range(-20,21,10):
			var pixel := Vector2i((foot+Vector2(x,y)-depth.bounds.position)/depth.bounds.size*Vector2(buffer.get_size()))
			if not Rect2i(Vector2i.ZERO,buffer.get_size()).has_point(pixel): continue
			var color := buffer.get_pixelv(pixel)
			var value: float = lerpf(depth.depth_range.x,depth.depth_range.y,(roundf(color.r*255)*256+roundf(color.g*255))/65535.0)
			if color.a > 0.5 and value > foot.y+0.5: hits += 1
	return hits

func combat_pixels() -> void:
	game.set_process(false)
	game.set_physics_process(false)
	for unit in game.monster_units+game.enemy_units:
		unit.set_physics_process(false)
		unit.sprite.pause()
		unit.visible = false
	var pair := same_wall_pair()
	expect(not pair.is_empty(),"same wall has real walkable floor on both sides")
	if pair.is_empty(): return
	metrics["same_wall_walkable_positions"] = {"behind":str(pair.behind),"front":str(pair.front),"wall_height":pair.height}
	game.combat_camera.enabled = false
	var original := get_viewport().canvas_transform
	var center: Vector2 = (pair.behind+pair.front)*0.5
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for text_scale in [0.9,1.0,1.15]:
			UISettings.text_scale = text_scale
			game._set_screen(C.SCREEN_COMBAT)
			game.combat_camera.enabled = false
			await settle(3)
			get_viewport().canvas_transform = Transform2D(Vector2(2.2,0),Vector2(0,2.2),Vector2(900,470)-center*2.2)
			var tag := "%dx%d_%d" % [resolution.x,resolution.y,roundi(text_scale*100)]
			for unit in [game.monster_units[0],game.enemy_units[0]]:
				unit.visible = true
				unit.name_label.visible = true
				for side in ["behind","front"]:
					unit.global_position = pair[side]
					unit.refresh_depth_slot()
					unit.queue_redraw()
					await shot(tag+"_combat_"+unit.faction+"_"+side+"_same_wall")
					var texture: Texture2D = unit.sprite.sprite_frames.get_frame_texture(unit.sprite.animation,unit.sprite.frame)
					var size := texture.get_size()
					var rect: Rect2 = unit.sprite.get_global_transform() * Rect2(unit.sprite.offset - (size*0.5 if unit.sprite.centered else Vector2.ZERO),size)
					await verify_pixels(unit.sprite,unit.global_position,tag+"_combat_"+unit.faction+"_"+side,rect)
				unit.visible = false
	# Exercise the existing Unit physics/path implementation around the actual wall/door.
	DisplayServer.window_set_size(Vector2i(1920,1080))
	UISettings.text_scale = 1.0
	game._set_screen(C.SCREEN_COMBAT)
	game.combat_camera.enabled = false
	get_viewport().canvas_transform = Transform2D(Vector2(1.6,0),Vector2(0,1.6),Vector2(900,470)-center*1.6)
	var walker = game.monster_units[0]
	walker.visible = true
	walker.global_position = pair.behind
	walker.target = null
	walker.set_path(game.graph.path_to_point(pair.behind,pair.front))
	walker.set_physics_process(true)
	var start: Vector2 = walker.global_position
	var samples := 0
	for frame in range(480):
		await get_tree().physics_frame
		if frame % 100 == 0:
			await shot("movement_%03d_existing_unit_path" % frame)
			samples += 1
			expect(absf(float(walker.sprite.material.get_shader_parameter("foot_depth"))-walker.global_position.y)<0.01,"moving body depth updated from current foot")
		if walker.path_points.is_empty(): break
	walker.set_physics_process(false)
	expect(walker.global_position.distance_to(start)>20,"real Unit physics moved the character")
	expect(walker.global_position.distance_to(pair.front)<20,"existing path reaches the other side through walkable floor")
	metrics["movement"] = {"start":str(start),"end":str(walker.global_position),"captures":samples,"remaining_waypoints":walker.path_points.size()}
	await shot("movement_final_existing_unit_path")
	get_viewport().canvas_transform = original
