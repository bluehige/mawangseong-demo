extends "res://tools/tests/V130RStep4CScaleTest.gd"
const S12 := "res://_mockup/game_step12_hpbar/"
const Health = preload("res://scripts/ui/PortraitHealthBar.gd")
func run() -> void:
	var selected_mode := "direct"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hpbar-mode="): selected_mode = arg.get_slice("=",1)
	mode = "direct"
	seed(12017)
	await boot()
	UISettings.set_hide_noncombat_hp_bars(false,false)
	Engine.max_fps = 60
	if selected_mode=="performance": await performance()
	elif selected_mode=="capture": await capture_hp()
	else: await direct_hp()
	await stop()
	var result := {"checks":checks,"failures":failures,"evidence":evidence}
	var f := FileAccess.open(S12+selected_mode+"_checks.json",FileAccess.WRITE); f.store_string(JSON.stringify(result,"\t")); f.close()
	print("STEP12_DONE ",selected_mode," ",checks," / ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func save_json(name: String, data) -> void:
	var f := FileAccess.open(S12+name+".json",FileAccess.WRITE); f.store_string(JSON.stringify(data,"\t")); f.close()

func direct_hp() -> void:
	start(); freeze()
	var portrait_rows := []
	for faction in ["monster","enemy"]:
		var catalog: Dictionary = DataRegistry.monsters if faction=="monster" else DataRegistry.enemies
		for id in catalog:
			var actor: Node = battle.make_unit(id,catalog[id],faction,"barracks")
			actor.set_physics_process(false); actor.sprite.pause()
			var hp: Node = actor.health
			expect(hp.portrait.texture!=null and hp.portrait.texture.get_size()==Vector2(64,64),"cached thumbnail "+id)
			expect(hp.portrait.material.shader.resource_path.ends_with("hpbar_portrait.gdshader"),"circular alpha mask "+id)
			expect(actor.name_label.get_parent()==hp and actor.name_label.position.y<0,"single ribbon name "+id)
			expect(hp.size==Vector2(64,8),"C base size "+id)
			expect(hp.portrait.size==Vector2(18,18) and hp.portrait_group.get_child(1).size==Vector2(26,28),"raster frame ignores original texture minimum "+id)
			expect(is_equal_approx(actor.vitals.scale.x,ScaleRules.ui_scale(id)),"0097 proportional scale "+id)
			portrait_rows.append({"id":id,"faction":faction,"portrait":hp.portrait_path,"multiplier":ScaleRules.multiplier(id)})
			actor.queue_free()
	await get_tree().process_frame
	save_json("portrait_coverage",portrait_rows)
	var actor: Node = game.monster_units[0]; var hp: Node = actor.health
	actor.hp = actor.max_hp; hp.sync(0)
	var before: int = actor.hp; actor.receive_damage(maxi(2,actor.max_hp/3)); hp.sync(0)
	var ratio: float = float(actor.hp)/actor.max_hp
	expect(actor.hp<before and hp.ghost_ratio>ratio and is_equal_approx(hp.ghost_wait,.4),"actual damage starts .4s ghost hold")
	var ghost: float = hp.ghost_ratio; hp.sync(.39)
	expect(is_equal_approx(hp.ghost_ratio,ghost),"ghost holds for .39 seconds")
	hp.sync(.02); expect(hp.ghost_ratio<ghost and hp.ghost_ratio>ratio,"ghost shrinks only after .4 seconds")
	hp.sync(1); expect(is_equal_approx(hp.ghost_ratio,ratio),"ghost settles at current HP")
	actor.heal(maxi(2,actor.max_hp/5)); hp.sync(0)
	expect(hp.heal_flash>0 and hp.fill_art.modulate.g>1 and is_equal_approx(hp.ghost_ratio,float(actor.hp)/actor.max_hp),"real healing flashes green and clears stale ghost")
	hp.sync(.36); expect(hp.heal_flash==0 and hp.fill_art.modulate==Color.WHITE,"healing flash ends")
	actor.grant_duo_barrier(actor.max_hp/3); hp.sync(0)
	expect(hp.shield_clip.visible and hp.shield_clip.size.x>0,"actual absorb barrier overlay")
	var barrier: int = actor.duo_barrier; actor.receive_damage(2); hp.sync(0)
	expect(actor.duo_barrier<barrier,"absorbed damage consumes existing shield")
	actor.duo_barrier = 0; actor.shield_timer = 0; actor.root_timer = 1; actor.slow_timer = 1; actor.armor_break_timer = 1; hp.sync(0)
	expect(hp.status_icons[1].visible and hp.status_icons[2].visible and hp.status_icons[3].visible,"live status icons in sockets")
	actor.root_timer = 0; actor.slow_timer = 0; actor.armor_break_timer = 0; hp.sync(0)
	var all_monsters: Array = game.monster_units.duplicate()
	game.monster_units.assign(all_monsters.slice(0,9)); view.battle_ui.layout_vitals()
	expect(hp.portrait_group.scale==Vector2.ONE,"nine living units keep full badge")
	game.monster_units.assign(all_monsters.slice(0,10)); view.battle_ui.layout_vitals()
	expect(hp.portrait_group.scale.is_equal_approx(Vector2.ONE*.85),"ten living units shrink only badge to .85")
	expect(actor.vitals.scale.is_equal_approx(Vector2.ONE*ScaleRules.ui_scale(actor.unit_id)),"crowd leaves bar/body proportion intact")
	game.monster_units.assign(all_monsters)
	actor.target = null; actor.selected = false; actor.attack_anim_timer = 0; actor.skill_anim_timer = 0
	actor.hp = actor.max_hp; hp.sync(0); hp.recent_combat = 0; hp.heal_flash = 0
	UISettings.set_hide_noncombat_hp_bars(true,false); view.battle_ui.layout_vitals()
	expect(not actor.vitals.visible and not actor.vitals_link.visible,"idle option hides complete vitals and connector")
	actor.selected = true; view.battle_ui.layout_vitals(); expect(actor.vitals.visible,"selected unit overrides idle hiding")
	actor.selected = false; UISettings.set_hide_noncombat_hp_bars(false,false)
	for zoom in [.5,.75,1.0]:
		view.set_camera(view.camera_center,zoom); view.battle_ui.layout_vitals()
		var desired: Rect2 = actor.vitals_rect_at(actor.desired_vitals_position(zoom))
		expect(absf((actor.raster_head_world_y()-desired.end.y)*zoom-6)<.01,"0099 six-screen-pixel gap "+str(zoom))
		for other in game.monster_units:
			expect(absf(other.vitals.position.x-other.visible_body_rect().get_center().x)<.01,"label stays on own body X")
		for i in range(game.monster_units.size()):
			for j in range(i+1,game.monster_units.size()):
				expect(not game.monster_units[i].vitals_rect().intersects(game.monster_units[j].vitals_rect()),"0099 vitals disjoint")
		expect(actor.silhouette.material.shader.resource_path.ends_with("approved_battle_silhouette.gdshader"),"0100 original occlusion shader")
		expect(actor.silhouette.transform.is_equal_approx(Transform2D(0,actor.position)*actor.visual_body.transform*actor.sprite.transform),"0100 exact pose outline")
	var snapshot: Dictionary = UISettings.snapshot()
	UISettings.set_hide_noncombat_hp_bars(true,false)
	expect(UISettings.save(),"isolated settings write")
	UISettings.set_hide_noncombat_hp_bars(false,false); UISettings._load_settings()
	expect(UISettings.hide_noncombat_hp_bars,"idle option persists in isolated settings")
	UISettings.apply_snapshot(snapshot,false); expect(not UISettings.hide_noncombat_hp_bars,"cancel restores idle preference")
	expect(UISettings.save(),"restore isolated settings after persistence probe")
	game.settings_category = "combat"; var settings := Control.new(); add_child(settings)
	game.settings_workspace = load("res://scripts/ui/SettingsWorkspaceUI.gd").new(); game.settings_workspace.setup(game,game.hud)
	game._build_settings_combat_category(settings)
	expect(settings.find_child("HideNoncombatHPBarsOption",true,false)!=null,"real combat settings exposes option")
	settings.queue_free()
	battle.running = false; view.battle = null
	view.placement.day = 29
	expect(view.preparation_only() and not view.start_battle(),"DAY29 remains preparation without battle")

func shot_hp(name: String) -> void:
	view.battle_ui.layout_vitals()
	for actor in game.monster_units+game.enemy_units: actor.health.sync(0); actor.update_silhouette()
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==Vector2i(1920,1080),"native capture "+name)
	expect(image.save_png(S12+name+".png")==OK,"capture "+name)
	var rows := []
	for actor in game.monster_units+game.enemy_units:
		var rect: Rect2 = view.world.global_transform*actor.vitals_rect()
		rows.append({"id":actor.unit_id,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"visible":actor.vitals.visible,"hp":actor.hp,"max_hp":actor.max_hp,"ghost":actor.health.ghost_ratio,"badge":actor.health.portrait_group.scale.x})
	save_json(name+"_state",rows)

func capture_hp() -> void:
	view.placement = Buildings.initial(game,"E"); view.placement.day = 7
	view.placement.resources = {"gold":1200,"mana":600,"food":100}
	view.state = Plan.read("E")
	view.monster_ui.assignments = Model.auto_place(view.placement,view.monster_ui.members,view.monster_ui.members.keys(),100)
	view.render_map(); view.resize_workspace(); view.show_default()
	expect(view.chrome.find_child("GradeDayLabel",true,false).text.contains("DAY 7"),"synchronize E DAY7 header")
	expect(view.placement.grade=="E" and int(view.placement.day)==7,"requested E DAY7 capture fixture")
	start()
	var frames := 0
	while battle.running and battle.contacts.is_empty() and frames<6000:
		await get_tree().process_frame; frames += 1
	expect(not battle.contacts.is_empty(),"DAY7 original wave reaches real contact")
	freeze(); game.v130r_story.clear_bark()
	var check_view := SubViewport.new(); check_view.size = Vector2i(64,64)
	check_view.world_2d = World2D.new(); check_view.transparent_bg = true; check_view.disable_3d = true
	check_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS; add_child(check_view)
	var check_portrait := TextureRect.new(); check_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	check_portrait.texture = game.monster_units[0].health.portrait.texture
	check_portrait.size = Vector2(64,64); check_portrait.material = game.monster_units[0].health.portrait.material
	check_view.add_child(check_portrait)
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	var rendered := check_view.get_texture().get_image()
	var source := check_portrait.texture.get_image()
	expect(rendered.get_pixel(0,0).a==0 and rendered.get_pixel(63,63).a==0,"GPU circle corners transparent")
	var actual := rendered.get_pixel(32,32); var expected := source.get_pixel(32,32)
	expect(absf(actual.r-expected.r)<.03 and absf(actual.g-expected.g)<.03 and absf(actual.b-expected.b)<.03,"GPU portrait preserves source color")
	check_view.queue_free()
	await shot_hp("battle_e_day7")
	# A paused, explicit stress layout, preserving production combat parameters.
	for id in ["official_hero_leon","thief","explorer"]: battle.spawn_enemy(id,{})
	freeze()
	var focus: Vector2 = battle.home(game.monster_units[0])
	var units: Array = game.monster_units+game.enemy_units
	for i in range(units.size()):
		units[i].position = focus+Vector2((i%5)*120-240,(i/5)*80-80)
		units[i].target = null; units[i].refresh_depth_slot()
	view.set_camera(focus+Vector2(80,-60),.75)
	view.battle_ui.select_unit(null)
	await shot_hp("battle_crowd")
	var leon: Node
	for actor in game.enemy_units:
		if actor.unit_id=="official_hero_leon": leon = actor
	view.set_camera(leon.position+Vector2(60,-70),1.0)
	await shot_hp("boss_leon")
	var actor: Node = game.monster_units[0]
	actor.hp = actor.max_hp; actor.health.sync(0)
	actor.receive_damage(maxi(3,actor.max_hp/2)); actor.health.sync(0)
	actor.grant_duo_barrier(actor.max_hp/4); actor.health.sync(0)
	view.set_camera(actor.position+Vector2(60,-80),1.0)
	await shot_hp("damage_ghost")
	expect(actor.health.ghost_ratio>float(actor.hp)/actor.max_hp,"damage screenshot captures held ghost")
	evidence["capture_fixture"] = "DAY7 real contact; crowd/boss/damage use paused explicit placements; barrier and damage use existing Unit APIs."

func performance() -> void:
	start()
	var defender_count: int = game.monster_units.size()+4
	game.wave_manager.next_index = game.wave_manager.total_to_spawn
	# Only the stress fixture has four repeated bodies; production roster is unique.
	for i in range(4):
		var source: Node = game.monster_units[i]
		var unit: Node = battle.make_unit(source.unit_id,DataRegistry.monster(source.unit_id),"monster",source.assigned_room)
		unit.position = source.position+Vector2(0,12); battle.homes[unit.get_instance_id()] = unit.position
		game.monster_units.append(unit)
	for i in range(10): battle.spawn_enemy("explorer",{"hp_scale":100,"atk_scale":.1})
	var focus: Vector2 = battle.home(game.monster_units[0])
	for i in range(10): game.enemy_units[i].position = focus+Vector2(35+i*3,18)
	for unit in game.monster_units: unit.max_hp = 100000; unit.hp = unit.max_hp
	var samples: Array[float] = []; var cpu: Array[float] = []; var physics: Array[float] = []
	var previous := Time.get_ticks_usec(); var start_time := previous
	while Time.get_ticks_usec()-start_time<20000000:
		await get_tree().process_frame
		var now := Time.get_ticks_usec(); var ms := (now-previous)/1000.0; previous = now
		if now-start_time>2000000:
			samples.append(ms); cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
			physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
	expect(game.monster_units.size()==defender_count and game.enemy_units.size()==10,"stress fixture retains all defenders plus ten enemies")
	var mean := 0.0; var cpu_mean := 0.0; var physics_mean := 0.0
	for x in samples: mean += x
	for x in cpu: cpu_mean += x
	for x in physics: physics_mean += x
	samples.sort()
	evidence["performance"] = {"resolution":"1920x1080","renderer":"gl_compatibility","fps_cap":60,"warmup_seconds":2,"measurement_seconds":18,
		"frames":samples.size(),"mean_frame_ms":mean/samples.size(),"mean_fps":1000/(mean/samples.size()),
		"p95_frame_ms":samples[int(samples.size()*.95)],"p99_frame_ms":samples[int(samples.size()*.99)],
		"mean_process_ms":cpu_mean/cpu.size(),"mean_physics_ms":physics_mean/physics.size(),"monsters":defender_count,"enemies":10,
		"alive_monsters":game.monster_units.filter(func(u): return u.is_alive()).size(),"alive_enemies":game.enemy_units.filter(func(u): return u.is_alive()).size(),
		"path_cache_queries":battle.map.route_queries,"target_fps":60}
	print("PERFORMANCE ",evidence.performance)
