extends "res://tools/tests/V130RStep4DLabelsTest.gd"

func _init() -> void:
	D_OUT = "res://tmp/v130r_step4e/"

func home_contract() -> void:
	var rows := []
	for unit in game.monster_units:
		var assignment: Dictionary = battle.assignments[unit.get_meta("instance_id")]
		var cell: Vector2i = Model.cell(view.placement,assignment)
		var point: Vector2 = battle.home(unit)
		expect(battle.map.cell(point)==cell,"offset stays in assigned defense cell "+unit.display_name)
		expect(point.distance_to(battle.map.world(cell))<25,"small fixed home offset")
		expect(point==battle.defense_home(assignment),"stable slot home independent of pose")
		rows.append({"name":unit.display_name,"building":assignment.building,"slot":assignment.slot,"cell":[cell.x,cell.y],"home":[point.x,point.y]})
		expect(unit.silhouette.transform.is_equal_approx(Transform2D(0,unit.position)*unit.visual_body.transform*unit.sprite.transform),"outline uses exact live pose")
	evidence["homes"] = rows
	var front := rows.filter(func(row): return row.building=="barracks")
	for i in range(front.size()):
		for j in range(i+1,front.size()):
			var a := Vector2(front[i].home[0],front[i].home[1])
			var b := Vector2(front[j].home[0],front[j].home[1])
			expect(a.distance_to(b)>=88,"barracks 2x2 resting formation separates all four feet")

func direct_d() -> void:
	super.direct_d()
	home_contract()
	var unit: Node = game.monster_units[0]
	var target: Vector2 = battle.home(unit)
	unit.position = battle.map.center("vault"); battle.update_monster_path(unit)
	expect(not unit.path_points.is_empty() and unit.path_points[-1].distance_to(target)<.01,"return path ends at offset home")
	for i in range(2500):
		unit._physics_process(1.0/60)
		if unit.position.distance_to(target)<2: break
	expect(unit.position.distance_to(target)<2,"existing movement reaches offset home")

func capture_d() -> void:
	view.monster_ui.assignments = Model.auto_place(view.placement,view.monster_ui.members,view.monster_ui.members.keys(),100)
	view.render_map(); view.show_default()
	await contact_d("battle_e_day7")
	home_contract()
	# Isolate the real four barracks defenders at their production resting homes.
	var defenders := []
	var center := Vector2.ZERO
	for unit in game.monster_units:
		if unit.assigned_room!="barracks":
			unit.map_visual.hide(); unit.vitals.hide(); unit.silhouette.hide(); unit.vitals_link.hide()
			continue
		unit.position = battle.home(unit); unit.velocity = Vector2.ZERO
		unit.attack_anim_timer = 0; unit.hit_anim_timer = 0; unit.skill_anim_timer = 0; unit.presentation_skill_anim_timer = 0
		unit._play_animation("idle_down"); unit._apply_visual_pose(); unit.refresh_depth_slot()
		defenders.append(unit); center += unit.position
	expect(defenders.size()==4,"four original barracks defenders")
	for unit in game.enemy_units:
		unit.map_visual.hide(); unit.vitals.hide(); unit.silhouette.hide(); unit.vitals_link.hide()
	var monsters: Array = game.monster_units.duplicate(); var enemies: Array = game.enemy_units.duplicate()
	game.monster_units.assign(defenders); game.enemy_units.clear()
	view.set_camera(center/defenders.size()+Vector2(0,-65),1.0)
	await evidence_shot("barracks_front")
	game.monster_units.assign(monsters); game.enemy_units.assign(enemies)
	game.monster_units[0].map_visual.show(); game.monster_units[0].vitals.show()
	await occlusion_fixture()
	var f := FileAccess.open(D_OUT+"label_manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(label_manifest,"\t")); f.close()

func backwall_control(unit: Node) -> void:
	# Reuse the genuinely occluded road position for GPU zoom and faction checks.
	for zoom in [.5,.75,1.0]:
		view.set_camera(unit.position+Vector2(0,-90),zoom)
		await evidence_shot("outline_zoom_"+str(zoom))
	unit.faction = "enemy"; battle.occlusion.bind(unit)
	await evidence_shot("outline_enemy")
	unit.faction = "monster"; battle.occlusion.bind(unit)
	await super.backwall_control(unit)

func evidence_shot(name: String) -> void:
	await super.evidence_shot(name)
	var row: Dictionary = label_manifest[-1]
	var inverse: Transform2D = view.world.global_transform.affine_inverse()
	row["screen_to_map"] = [inverse.x.x,inverse.x.y,inverse.y.x,inverse.y.y,inverse.origin.x,inverse.origin.y]
	row["wall_bounds"] = rect_data(battle.occlusion.bounds)
	expect(battle.occlusion.viewport.get_texture().get_image().save_png(D_OUT+"wall_depth.png")==OK,"depth evidence")
