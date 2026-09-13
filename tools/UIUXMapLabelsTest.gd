extends "res://tools/UIUXU4InteractionTest.gd"
var phase := "after"
var output := ""
func _run() -> void:
	if "--before" in OS.get_cmdline_user_args(): phase="before"
	output="res://tmp/uiux_map_labels_20260913/"+phase
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	game=Game.instantiate()
	add_child(game)
	await settle()
	game.campaign_save_enabled=false
	game._debug_skip_onboarding()
	game.onboarding_enabled=false
	game.tutorial_gate_enabled=false
	game.story_feature_enabled=false
	game.combat_speed_intro_seen=true
	GameState.day=2
	game.castle_art_stage="stage_04_citadel"
	game._sync_castle_stage_content()
	game._refresh_quarter_map_from_rooms()
	game._choose_early_specialization("goblin","goblin_treasure_hunter")
	game._set_screen(C.SCREEN_MANAGEMENT)
	game._start_combat()
	await settle(10)
	expect(game.current_screen==C.SCREEN_COMBAT,"actual defense start")
	game.combat_scene.set_pause_state(true,false)
	game._spawn_enemy("engineer")
	var engineer=game.enemy_units.back()
	engineer.set_physics_process(false)
	var canvas: Transform2D=get_viewport().canvas_transform
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale in [0.9,1.0,1.15]:
			UISettings.text_scale=scale
			game._set_screen(C.SCREEN_COMBAT)
			await settle()
			var tag:="%dx%d_%d"%[resolution.x,resolution.y,roundi(scale*100)]
			game.engineer_target_rooms.clear()
			game.facility_disabled_timers.clear()
			await shot(tag+"_normal")
			game.engineer_target_rooms[engineer.get_instance_id()]="barracks"
			await shot(tag+"_targeted")
			game.facility_disabled_timers["recovery"]=4.5
			await shot(tag+"_disabled")
			game.combat_scene.acid_telegraphs.assign([{"position":game.graph.center("spike_corridor"),"radius":85.0,"remaining":0.7,"total":1.2}])
			game.combat_scene.ledger_mark_casts.assign([{"position":game.graph.center("barracks"),"remaining":0.8,"total":1.0}])
			await shot(tag+"_warnings")
			game.combat_scene.acid_telegraphs.clear()
			game.combat_scene.ledger_mark_casts.clear()
			for zoom in [0.8,1.25]:
				get_viewport().canvas_transform=Transform2D(Vector2(zoom,0),Vector2(0,zoom),Vector2(1920,1080)*(1.0-zoom)*0.5)
				await shot(tag+"_zoom%d"%roundi(zoom*100))
			get_viewport().canvas_transform=canvas
			if phase=="after":
				expect(game._facility_combat_overlay_text("recovery")=="회복 +12.0/초","current castle healing value preserved")
				expect(game._facility_room_disabled_remaining("recovery")==4.5,"drawing never consumes disabled duration")
				expect(game._engineer_room_is_targeted("barracks"),"actual targeted facility remains targeted")
	if phase=="after": await extended_warnings()
	game.queue_free()
	await settle()
	var file:=FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions":count,"failed":failed,"captures":captures},"\t"))
	file.close()
	print("UIUX_MAP_LABELS_TEST: %s (%d assertions, %d captures)"%["FAIL" if failed else "PASS",count,captures.size()])
	get_tree().quit(1 if failed else 0)
func shot(id: String) -> void:
	var rooms: Dictionary=game.rooms.duplicate(true)
	var economy: Array=[GameState.gold,GameState.mana]
	game.queue_world_overlay_redraw()
	await settle()
	if phase=="after":
		var seen: Array=[]
		for info in game.combat_map_label_layouts:
			var rect: Rect2=info.rect
			expect(info.font_size==UISettings.scaled_font_size(18),id+" text scale preserved")
			expect(game.UI_FONT.get_string_size(info.text,HORIZONTAL_ALIGNMENT_LEFT,-1,info.font_size).x<=rect.size.x-38,id+" full text width")
			expect(rect.position.x>=8 and rect.end.x<=1920-8,id+" horizontally visible")
			for other in seen: expect(not rect.intersects(other),id+" labels do not overlap: "+info.text)
			for blocker in game.combat_map_label_blockers: expect(not rect.intersects(blocker),id+" visible outside HUD: "+info.text)
			seen.append(rect)
		for unit in game.monster_units+game.enemy_units:
			for info in unit.map_status_label_layouts:
				expect(info.font_size==UISettings.scaled_font_size(16),id+" paused unit font refreshed")
				for blocker in game.combat_map_label_blockers:
					expect(not info.rect.intersects(blocker),id+" paused unit warning visible outside HUD")
		var contour_rooms: Array=[]
		for contour in game.combat_floor_outlines:
			contour_rooms.append(contour.room_id)
			var actual_floor: bool=not contour.cells.is_empty()
			for cell in contour.cells:
				actual_floor=actual_floor and game.graph.debug_room_id_for_tile_cell(cell)==contour.room_id
			expect(actual_floor,id+" contour covers its actual room floor")
			var diagonal: bool=not contour.edges.is_empty()
			for edge in contour.edges:
				var delta: Vector2=edge[1]-edge[0]
				diagonal=diagonal and absf(delta.x)>0.1 and absf(delta.y)>0.1
			expect(diagonal,id+" contour follows isometric edges, no screen rectangle")
		for room in game._active_watch_post_pressure_rooms():
			if game.rooms.has(room) and game.graph.rect(room).size!=Vector2.ZERO:
				expect(room in contour_rooms,id+" actual affected room visible")
		if game._engineer_room_is_targeted("barracks"): expect("barracks" in contour_rooms,id+" targeted room marked")
		if game._facility_room_disabled_remaining("recovery")>0: expect("recovery" in contour_rooms,id+" disabled room marked")
		expect(seen.size()>=2,id+" live facility labels recorded")
		expect(game.rooms==rooms and [GameState.gold,GameState.mana]==economy,id+" overlay is read-only")
	var path:=output.path_join(id+".png")
	expect(get_viewport().get_texture().get_image().save_png(path)==OK,id+" capture")
	captures.append(path)

func extended_warnings() -> void:
	# Real runtime actors/state containers, paused to make transient warnings reproducible.
	game._spawn_enemy("guild_commissioner_roman")
	var roman=game.enemy_units.back()
	roman.set_physics_process(false)
	roman.global_position=game.graph.center("treasure")
	roman.refresh_depth_slot()
	game._spawn_enemy("official_paladin_selen")
	var selen=game.enemy_units.back()
	selen.set_physics_process(false)
	selen.global_position=game.graph.center("spike_corridor")
	selen.refresh_depth_slot()
	var watch_room: String=game._rooms_by_facility("watch_post")[0]
	var ally=game.monster_units[0]
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale in [0.9,1.0,1.15]:
			UISettings.text_scale=scale
			game._select_unit(ally)
			var tag:="%dx%d_%d"%[resolution.x,resolution.y,roundi(scale*100)]
			game.combat_scene.acid_zones.assign([{"position":game.graph.center("spike_corridor"),"radius":85.0,"remaining":3.0}])
			game.combat_scene.selen_consecrated_floors.assign([{"position":game.graph.center("treasure"),"radius":92.0,"remaining":2.0}])
			game.combat_scene.purifying_hymn_casts.assign([{"position":game.graph.center(watch_room),"radius":180.0,"remaining":0.9,"total":1.2}])
			await shot(tag+"_area_warnings")
			expect_live_text(["산성 구역 3.0초","축성 바닥 2.0초","정화 성가 0.9초"])
			game.combat_scene.acid_zones.clear()
			game.combat_scene.selen_consecrated_floors.clear()
			game.combat_scene.purifying_hymn_casts.clear()
			game.combat_scene.official_selen_states[selen.get_instance_id()]={"unit_id":selen.get_instance_id(),"inspection_mode":"telegraph","inspection_target":"treasure","inspection_timer":1.0}
			game.combat_scene.commissioner_roman_states[roman.get_instance_id()]={"unit_id":roman.get_instance_id(),"budget":3,"stress":2,"freeze_mode":"telegraph","freeze_target":"recovery","freeze_timer":1.1}
			game.combat_scene.ledger_room_marks[watch_room]={"debt":2,"remaining":2.0}
			await shot(tag+"_boss_warnings")
			expect_live_text(["검수 예고 1.0초","예산 3/5 · 스트레스 2/5","자산 동결 · 피해 50 · 1.1초","부채 2/3 · 2.0초"])
			game.combat_scene.official_selen_states[selen.get_instance_id()].inspection_mode="mark"
			await shot(tag+"_inspection_active")
			game._clear_combat_unit_selection()
			await shot(tag+"_inspector_closed")
			game.combat_scene.official_selen_states.clear()
			game.combat_scene.commissioner_roman_states.clear()
			game.combat_scene.ledger_room_marks.clear()
			ally.bounty_mark_timer=2.0
			ally.seal_telegraph_timer=0.8
			game._select_unit(ally)
			ally.skill_preview_active=true
			ally.skill_preview_label="방어 태세 준비"
			ally.queue_redraw()
			await shot(tag+"_unit_warnings")
			var labels: Array=ally.map_status_label_layouts
			expect(labels.size()==3,tag+" bounty, seal and skill labels use same live renderer")
			for i in range(labels.size()):
				expect(labels[i].font_size==UISettings.scaled_font_size(16),tag+" unit warning font follows settings")
				for j in range(i): expect(not labels[i].rect.intersects(labels[j].rect),tag+" simultaneous unit statuses remain separate")
			ally.bounty_mark_timer=0
			ally.seal_telegraph_timer=0
			ally.skill_preview_active=false
			ally.skill_preview_label=""
			ally.queue_redraw()

func expect_live_text(texts: Array) -> void:
	var shown: Array=[]
	for info in game.combat_map_label_layouts: shown.append(info.text)
	for text in texts: expect(text in shown,"active runtime warning is drawn: "+text)
