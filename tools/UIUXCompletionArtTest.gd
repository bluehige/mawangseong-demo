extends "res://tools/UIUXU4InteractionTest.gd"
const Actor = preload("res://scripts/units/Unit.gd")
const Art = preload("res://scripts/ui/UIUXActorArt.gd")
const Fixture = preload("res://tools/UIUXSecondaryFixture.gd")
var phase := "after"
var output := ""
var inventory: Dictionary={}
var measurements: Dictionary={}
var only_connected := false
var inspector_only := false
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg=="--before": phase="before"
		if arg=="--only-connected": only_connected=true
		if arg=="--inspector-only": inspector_only=true
	output="res://tmp/uiux_completion_art_20260913/"+("inspector" if inspector_only else phase)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	game=Game.instantiate()
	add_child(game)
	await settle()
	Fixture.prepare(game)
	inventory=JSON.parse_string(FileAccess.get_file_as_string("res://tools/fixtures/uiux_completion_actor_inventory.json"))
	if only_connected:
		var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/uiux_actor_art.json"))
		for id in inventory.keys():
			if not catalog.has(id): inventory.erase(id)
	game.hide()
	game.ui_layer.hide()
	if inspector_only:
		game.show()
		game.ui_layer.show()
		game._unlock_kobold_scout_commander()
		game.combat_speed_intro_seen=true
		GameState.day=2
		game.update4_active_run={}
		game.deployed_instance_ids.assign(["mon_core_gob"])
		expect(game._choose_early_specialization("goblin","goblin_treasure_hunter"),"inspector fixture existing specialization")
		var owned: Dictionary=game.monster_roster.duplicate(true)
		for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
			DisplayServer.window_set_size(resolution)
			for scale in [0.9,1.0,1.15]:
				UISettings.text_scale=scale
				await live_combat("%dx%d_%d"%[resolution.x,resolution.y,roundi(scale*100)],owned)
	else:
		for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
			DisplayServer.window_set_size(resolution)
			for start in range(0,inventory.size(),4):
				await page(start,resolution)
		if phase=="after": await live_checks()
	game.queue_free()
	await settle()
	var f:=FileAccess.open(output.path_join("measurements.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(measurements,"\t"))
	f.close()
	f=FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"assertions":count,"failed":failed,"captures":captures,"only_connected":only_connected,"inspector_only":inspector_only},"\t"))
	f.close()
	print("UIUX_COMPLETION_ART_TEST: %s (%d assertions, %d captures)" % ["FAIL" if failed else "PASS",count,captures.size()])
	get_tree().quit(1 if failed else 0)
func stats_for(id: String) -> Dictionary:
	var entry: Dictionary=inventory[id]
	var stats: Dictionary=DataRegistry.enemy(entry.base_id).duplicate(true) if entry.kind=="enemy" else DataRegistry.monster(entry.base_id).duplicate(true)
	if entry.kind=="form":
		var forms: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://"+str(entry.file)))
		stats.sprite=forms[id].combat_sprite
	return stats
func page(start: int,resolution: Vector2i) -> void:
	var stage:=CanvasLayer.new()
	stage.layer=100
	add_child(stage)
	var background:=ColorRect.new()
	background.color=Color("#23232c")
	background.size=Vector2(1920,1080)
	stage.add_child(background)
	var names:=["idle_down","move_down","attack_down","skill_down","down"]
	var units: Array=[]
	var row:=0
	for id in inventory.keys().slice(start,start+4):
		var stats:=stats_for(id)
		var info: Dictionary=inventory[id]
		for col in range(5):
			var unit:=Actor.new()
			stage.add_child(unit)
			unit.setup(info.base_id,stats,C.FACTION_ENEMY if info.kind=="enemy" else C.FACTION_MONSTER,"art")
			unit.set_physics_process(false)
			unit.set_process(false)
			unit.position=Vector2(195+col*375,224+row*254)
			unit._play_animation(names[col])
			unit.sprite.pause()
			var first: Texture2D=unit.sprite.sprite_frames.get_frame_texture("idle_down",0)
			var bounds:=Art.visible_bounds(first)
			var height:=bounds.size.y*unit.sprite.scale.y
			# Evidence layout enlarges each unit to the same 170px body height.
			# Actual game scale and source frame are recorded separately below.
			unit.scale=Vector2.ONE*(170/maxf(height,1))
			unit.name_label.hide()
			unit.self_modulate.a=0
			if col==0:
				measurements[id]={"path":unit.sprite_path,"profile":unit.combat_visual_profile.duplicate(true),"sprite_scale":unit.sprite.scale.y,"body_height":height,"frame_size":[first.get_width(),first.get_height()]}
				if phase=="after":
					expect(unit.sprite_path.begins_with("res://assets/sprites/uiux3d/"),id+" new sheet connected")
					expect(unit.sprite.material==null,id+" native alpha without chroma")
					expect(first.get_size()==Vector2(384,384),id+" consistent logical frame")
			var caption:=Label.new()
			caption.position=Vector2(26+col*375,12+row*254)
			caption.size=Vector2(350,50)
			caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			caption.text=id+" · "+names[col]
			stage.add_child(caption)
			units.append(unit)
		row+=1
	for frame in range(4):
		for unit in units: unit.sprite.frame=mini(frame,unit.sprite.sprite_frames.get_frame_count(unit.sprite.animation)-1)
		await capture("%dx%d_page%d_frame%d"%[resolution.x,resolution.y,start/4,frame])
	stage.queue_free()
	await settle()
func capture(id: String) -> void:
	await settle()
	var path:=output.path_join(id+".png")
	expect(get_viewport().get_texture().get_image().save_png(path)==OK,id+" capture")
	captures.append(path)
func live_checks() -> void:
	if only_connected: return
	game.show()
	game.ui_layer.show()
	Fixture.prepare(game)
	game._unlock_kobold_scout_commander()
	game.combat_speed_intro_seen=true
	GameState.day=2
	game.update4_active_run={}
	game.deployed_instance_ids.assign(["mon_core_gob"])
	expect(game._choose_early_specialization("goblin","goblin_treasure_hunter"),"live fixture existing specialization")
	var owned: Dictionary=game.monster_roster.duplicate(true)
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale in [0.9,1.0,1.15]:
			UISettings.text_scale=scale
			var tag:="%dx%d_%d"%[resolution.x,resolution.y,roundi(scale*100)]
			for id in inventory:
				var info: Dictionary=inventory[id]
				if info.kind=="enemy": continue
				game.monster_roster=owned.duplicate(true)
				game.update4_active_run={}
				var species:=str(info.base_id)
				var instance:=instance_for(species)
				expect(instance!="",id+" existing owned instance")
				game.deployed_instance_ids.assign([instance,"mon_core_gob"] if species!="goblin" else [instance])
				if info.kind=="form":
					if str(info.file).contains("crown_evolutions"):
						game.update4_active_run={"campaign_mode_id":"council_season","council_season":{},"crown":{"selected_instance_id":instance,"crown_form_id":id},"upper_floor":{"crown_suppressed":false}}
					else:
						game.monster_roster[species].promotion_id=id
				var wanted_path:=str(stats_for(id).get("sprite",""))
				var scaled: Dictionary=game._scaled_monster_stats(species)
				expect(str(scaled.get("sprite",""))==wanted_path,tag+" "+id+" current stats select exact art")
				var preview: Texture2D=game._monster_drag_texture(species)
				expect(preview is AtlasTexture and preview.atlas.resource_path==wanted_path,tag+" "+id+" drag uses same current form")
				var identity: Texture2D=game.management_scene.monster_identity_texture(species)
				expect(identity is AtlasTexture and identity.atlas.resource_path==wanted_path,tag+" "+id+" card uses same current form")
				if species=="kobold_scout":
					game._set_screen(C.SCREEN_RAID)
					await settle()
					expect(not game._monster_available_for_defense(species),tag+" Rolo remains support-only")
					expect(has_texture(game.ui_layer,game.management_scene.monster_portrait_path(species)),tag+" Rolo actual raid portrait")
					check_copy(game.ui_layer)
					await capture(tag+"_rolo_raid")
					continue
				game.selected_monster_id=species
				game._set_screen(C.SCREEN_MONSTER)
				await settle()
				var portrait:=node("MonsterPortrait_"+species) as TextureRect
				expect(portrait!=null and not(portrait.texture is AtlasTexture),tag+" "+id+" growth uses full portrait")
				expect(portrait!=null and portrait.texture.resource_path==game.management_scene.monster_portrait_path(species),tag+" "+id+" selected portrait follows current state")
				check_copy(game.ui_layer)
				await capture(tag+"_"+id+"_growth")
				await click(node("MonsterMemoryButton"))
				expect(game.current_screen==C.SCREEN_MEMORY_ARCHIVE,tag+" "+id+" actual memory entry")
				var memory:=node("MemoryCompanionArt") as TextureRect
				expect(memory!=null and memory.texture.resource_path==game.management_scene.monster_portrait_path(species),tag+" "+id+" memory same identity")
				# Crown suppression must reveal the underlying form without overwriting stored identity.
				if info.kind=="form" and str(info.file).contains("crown_evolutions"):
					game.update4_active_run.upper_floor.crown_suppressed=true
					expect(str(game._scaled_monster_stats(species).get("sprite",""))!=wanted_path,tag+" "+id+" suppression restores base")
					game.update4_active_run.upper_floor.crown_suppressed=false
				game._set_screen(C.SCREEN_MANAGEMENT)
				await click(node("ManagementTab_roster"))
				expect(game.dungeon_renderer._roster_preview_monster_ids().has(species) or species=="kobold_scout",tag+" "+id+" actual deployed map")
				await capture(tag+"_"+id+"_map")
				# Unit.setup is the live renderer; feed its actual scaled state, not a handmade sprite.
				var unit:=Actor.new()
				game.add_child(unit)
				unit.setup(species,scaled,C.FACTION_MONSTER,"barracks")
				unit.set_physics_process(false)
				unit.set_process(false)
				expect(unit.sprite_path==wanted_path,tag+" "+id+" Unit exact current form")
				expect(unit.sprite.material==null,tag+" "+id+" no color erasure shader")
				unit.queue_free()
				await settle()
			for cue in [["CHR_ROLO",""],["CHR_ROLO","briefing"],["CHR_ROLO","mischief"],["CHR_ROLO","flustered"],["CHR_BATI","dry"],["CHR_BATI","tutorial"],["CHR_BATI","stern"],["CHR_BATI","dry_happy"],["CHR_DARKLORD_PLAYER",""],["CHR_DARKLORD_PLAYER","proud"],["CHR_DARKLORD_PLAYER","offended"],["CHR_DARKLORD_PLAYER","flustered"],["CHR_DARKLORD_PLAYER","serious"],["CHR_DARKLORD_PLAYER","command"],["CHR_SILKY","happy"],["CHR_POPO","determined"]]:
				game._onboarding_begin_dialogue([{"speaker":cue[0],"emotion":cue[1],"text":"다음 방어도 함께 준비해요.","stage":"LV03_DAY01_MANAGEMENT_TUTORIAL"}],C.SCREEN_MANAGEMENT)
				await settle()
				expect(game.current_screen==C.SCREEN_DIALOGUE,tag+" "+cue[0]+" live dialogue")
				check_copy(game.ui_layer)
				await capture(tag+"_"+cue[0]+"_"+cue[1]+"_dialogue")
				game._onboarding_advance_dialogue()
				await settle()
			await live_combat(tag,owned)
	game._set_screen(C.SCREEN_MANAGEMENT)
	await settle()

func instance_for(species: String) -> String:
	for id in DataRegistry.monster_instances:
		if str(DataRegistry.monster_instances[id].get("species_id",""))==species: return str(id)
	return ""

func live_combat(tag: String,owned: Dictionary) -> void:
	game.monster_roster=owned.duplicate(true)
	game.update4_active_run={}
	GameState.day=2
	game.deployed_instance_ids.assign(["mon_core_gob",instance_for("ghost_housemaid"),instance_for("spider_tailor"),instance_for("bat_courier")])
	game._set_screen(C.SCREEN_MANAGEMENT)
	game._start_combat()
	await settle(20)
	expect(game.current_screen==C.SCREEN_COMBAT,tag+" actual defense start")
	if game.current_screen!=C.SCREEN_COMBAT: return
	game.combat_scene.set_pause_state(true,false)
	for unit in game.monster_units:
		var id:=str(unit.unit_id)
		expect(unit.sprite_path==str(game._scaled_monster_stats(id).get("sprite","")),tag+" live defender "+id+" current art")
		expect(unit.display_name==game._monster_companion_name(id),tag+" live defender "+id+" companion name")
		game._select_unit(unit)
		await settle()
		var portrait:=node("CombatUnitPortrait") as TextureRect
		expect(portrait!=null and not(portrait.texture is AtlasTexture) and portrait.texture.resource_path==game.management_scene.monster_portrait_path(id),tag+" "+id+" inspector full current portrait")
		check_inspector_copy(unit,tag)
		if inspector_only: await capture(tag+"_ally_fixture_"+id)
	await capture(tag+"_actual_combat")
	# Controlled enemy groups exercise the real spawn path and rendering, not a claim about a played wave.
	var ids: Array=[]
	for id in inventory:
		if inventory[id].kind=="enemy": ids.append(id)
	# Spawn each counter enemy alone; grouping several counters can correctly reject
	# reinforcement under the existing composition cap.
	for id_value in ids:
		for enemy in game.enemy_units:
			if is_instance_valid(enemy): enemy.queue_free()
		game.enemy_units.clear()
		await settle()
		var id:=str(id_value)
		game._spawn_enemy(id)
		expect(game.enemy_units.size()==1,tag+" "+id+" legal individual reinforcement")
		if game.enemy_units.is_empty(): continue
		var unit=game.enemy_units.back()
		unit.position=game.graph.center("barracks")+Vector2(0,-55)
		unit.set_physics_process(false)
		expect(unit.sprite_path==str(stats_for(id).get("sprite_sheet",stats_for(id).get("sprite",""))),tag+" "+id+" existing spawn route exact art")
		expect(unit.sprite.material==null,tag+" "+id+" actual spawn native alpha")
		game._select_unit(unit)
		await settle()
		var portrait:=node("CombatUnitPortrait") as TextureRect
		expect(portrait!=null and portrait.texture is AtlasTexture and portrait.texture.atlas.resource_path==unit.sprite_path,tag+" "+id+" inspector single live pose")
		check_inspector_copy(unit,tag)
		await capture(tag+"_enemy_fixture_"+id)
	game._set_screen(C.SCREEN_MANAGEMENT)
	await settle()

func has_texture(parent: Node, path: String) -> bool:
	if parent is TextureRect and parent.texture!=null and parent.texture.resource_path==path: return true
	for child in parent.get_children():
		if has_texture(child,path): return true
	return false

func check_inspector_copy(unit: Node,tag: String) -> void:
	var role_label:=node("CombatUnitRole") as Label
	var stats_label:=node("CombatUnitStats") as Label
	var inspector:=node("CombatUnitInspector") as Control
	expect(role_label!=null and stats_label!=null,tag+" role and combat values separately visible")
	if role_label==null or stats_label==null: return
	expect(stats_label.text=="공격 %d · 방어 %d"%[int(unit.atk),int(unit.def)],tag+" exact actual attack and defense")
	for field in [role_label,stats_label]:
		expect(field.get_theme_font_size("font_size")>=UISettings.scaled_font_size(20),tag+" readable role/stat size")
		expect(field.get_line_count()*field.get_line_height()<=field.size.y+2,tag+" role/stat full text fits: "+field.text)
	expect(role_label.get_rect().end.y<=stats_label.position.y,tag+" separate role and stats do not overlap")
	var hp: Label=game.hud.selected_unit_dynamic_labels.hp
	expect(not stats_label.get_rect().intersects(hp.get_rect()),tag+" stats do not overlap HP")
	for field in game.hud.selected_unit_dynamic_labels.values():
		expect(field.get_rect().end.y<=inspector.size.y,tag+" dynamic content stays within inspector")
	var fields: Array=game.hud.selected_unit_dynamic_labels.values()
	fields.append(stats_label)
	for first in range(fields.size()):
		for second in range(first+1,fields.size()):
			expect(not fields[first].get_rect().intersects(fields[second].get_rect()),tag+" inspector values do not overlap")
