extends Node
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Food = preload("res://scripts/systems/MonsterFoodService.gd")
const Recruits = preload("res://scripts/map_builder/ApprovedRecruitment.gd")
const Duo = preload("res://scripts/systems/duo_links/DuoLinkService.gd")
const OUT := "res://tmp/v130r_step7/"
var preview: Node
var game: Node
var view: Control
var battle
var checks := 0
var failures: Array = []
var evidence := {}
var mode := "direct"

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL ",message)

func _ready() -> void: run.call_deferred()

func boot() -> void:
	preview = load("res://scenes/map_builder/ApprovedPlacementPreview.tscn").instantiate(); add_child(preview)
	await get_tree().create_timer(.2).timeout
	game = preview.game; view = game.ui_layer.get_node("ApprovedMapManagement")
	view.placement = Buildings.initial(game,"E"); view.placement.day = 15
	view.placement.food_state = Food.fresh(); GameState.food_state = Food.fresh()
	view.monster_ui.unlock_all = true
	view.monster_ui.assignments = Members.auto_place(view.placement,view.monster_ui.members,view.monster_ui.members.keys(),100)
	get_window().size = Vector2i(1920,1080)
	view.render_map(); view.show_default()
	GameState.day = 15; GameState.max_day = 30; GameState.demon_lord_hp = 1500; GameState.demon_lord_max_hp = 1500
	await get_tree().process_frame

func start() -> void:
	expect(view.start_battle(),"battle starts")
	battle = view.battle; view.set_physics_process(false); battle.set_pause_state(true)
	game.wave_manager.next_index = game.wave_manager.total_to_spawn

func make(species: String, at: Vector2) -> Node:
	var unit: Node = battle.make_unit(species,DataRegistry.monster(species),"monster","barracks")
	unit.position = at; unit.set_physics_process(false); unit.set_meta("base_attack_range",unit.attack_range)
	battle.homes[unit.get_instance_id()] = at; unit.refresh_depth_slot(); game.monster_units.append(unit)
	return unit

func foe(species: String, at: Vector2) -> Node:
	battle.spawn_enemy(species)
	var unit: Node = game.enemy_units[-1]; unit.position = at; unit.max_hp = 10000; unit.hp = 10000; unit.set_physics_process(false); unit.refresh_depth_slot()
	return unit

func clear_units() -> void:
	battle._clear_active_combat_tweens()
	for effect in game.effect_root.get_children(): effect.queue_free()
	for unit in game.monster_units+game.enemy_units: unit.queue_free()
	game.monster_units.clear(); game.enemy_units.clear(); battle.homes.clear()

func tick(seconds: float) -> void:
	var count := ceili(seconds*60)
	for index in range(count):
		var delta := minf(1.0/60,seconds-index/60.0)
		battle.monster_skills.tick(delta)
		battle.tick_temporary_traps(delta)
		for unit in game.monster_units+game.enemy_units: unit._physics_process(delta)

func catalog() -> void:
	expect(view.monster_ui.members.size()==24,"24 unique roster members")
	expect(view.chrome.z_index>3800 and not view.chrome.z_as_relative,"roster and skill controls remain above map depth")
	expect(view.monster_ui.cards.size()==24,"24 placement cards")
	expect(Food.COSTS.size()==24 and Food.COSTS.values().reduce(func(a,b): return a+b,0)==48,"data upkeep 24/48")
	for member in view.monster_ui.members.values():
		expect(FileAccess.file_exists(member.stats.sprite),"SW sheet "+member.species_id)
		expect(FileAccess.file_exists(member.stats.sprite_ne),"NE sheet "+member.species_id)
		expect(member.upkeep==Food.COSTS[member.species_id],"upkeep "+member.species_id)
	var new_monsters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/v130r/monsters_new.json"))
	for species in new_monsters:
		var definition: Dictionary = DataRegistry.monster(species)
		expect(definition.specialization_ids.size()==2,"two specializations "+species)
		var character: Dictionary = DataRegistry.characters[definition.character_id]
		for emotion in ["base","happy","determined"]:
			var path: String = character.portrait.base if emotion=="base" else character.portrait.variants[emotion]
			expect(FileAccess.file_exists(path),"portrait "+species+" "+emotion)
	for species in ["spore_healer","stone_sentinel","war_drummer","moon_tracker","mimic_porter","kobold_scout"]:
		expect(DataRegistry.monster(species).specialization_ids.size()==2,"existing specializations "+species)
	var source := "연못 반환 요구서 37번째인데요."
	expect(LanguageSettings.english_translation.translate_text(source)!=source,"English standalone join line registered")
	expect(LanguageSettings.chinese_translation.translate_text(source)!=source,"Chinese standalone join line registered")
	var short := Food.settle(0,1,Food.COSTS.keys(),Food.fresh())
	expect(short.ledger.due==48 and short.ledger.paid==15 and not short.state.hungry.is_empty(),"24 member hunger settlement")
	game.selected_contract_ids.clear()
	for species in new_monsters:
		var definition: Dictionary = new_monsters[species]; var id: String = definition.instance_id
		expect(id not in Recruits.eligible(game,view.monster_ui.members,int(definition.join_day)-1),"locked before join "+species)
		expect(id in Recruits.eligible(game,view.monster_ui.members,int(definition.join_day)),"eligible at join "+species)
	var eligible := Recruits.eligible(game,view.monster_ui.members,30)
	expect("mon_contract_mori" not in eligible and "monster_bebe" not in eligible,"contracts/fronts retain priority")

func duos() -> void:
	var progress := {}; var active := {}; var catalog := DataRegistry.update3_duo_links
	var selected := {}
	for id in catalog:
		var definition: Dictionary = catalog[id]
		if str(definition.get("display_name","")) not in ["포자 젤리 피난처","석상 행진곡","가짜 등대 금고"]: continue
		selected[id] = definition
		for member_id in definition.member_instance_ids:
			var species: String = DataRegistry.monster_instances[member_id].species_id
			game.monster_roster[species] = {"bond":0,"unlocked_memory_ids":[]}
			var granted: Dictionary = game._grant_monster_bond(species,25)
			var memory: String = granted.unlocked_memory_id
			expect(memory!="" and not DataRegistry.memory_entry(memory).is_empty(),"real bond grants valid memory "+species)
			game._grant_monster_bond(species,20)
			progress[member_id] = game.monster_roster[species].duplicate(true)
		for day in [1,2,3]: active = Duo.record_deployed_day(active,definition.member_instance_ids,day,selected)
		for count in range(5):
			for source in definition.gauge_sources:
				active = Duo.record_unlock_action(active,str(source.member_instance_id),str(source.source_id),int(source.get("threshold",1)),"step7_%s_%d" % [source.member_instance_id,count],selected)
	var events := Duo.eligible_memory_event_ids({},active,progress,selected)
	expect(selected.size()==3 and events.size()==3,"three duo memory events eligible")
	var profile := {}
	for event in events:
		var result := Duo.complete_memory_event(profile,event,selected)
		expect(result.ok,"duo unlock through memory event "+event); profile = result.profile
	expect(profile.get("duo_links",{}).get("unlocked",[]).size()==3,"three links unlocked")
	evidence["duos"] = {"catalog":selected.keys(),"events":events,"progress":progress,"profile":profile}

func skills() -> void:
	start(); clear_units()
	var center: Vector2 = battle.map.world(battle.map.layout.bridges.keys()[0])
	var tested: Array = []
	for id in battle.monster_skills.definitions:
		var definition: Dictionary = battle.monster_skills.definitions[id]
		if definition.passive: continue
		clear_units()
		var species := ""
		for candidate in DataRegistry.monsters:
			if id in DataRegistry.monster(candidate).get("skill_slots",[]): species = candidate; break
		var unit := make(species,center)
		var enemy := foe("thief" if id=="toll_shakedown" else "engineer" if id=="undermine" else "explorer",center+Vector2(25,0))
		var ally := make("slime",center+Vector2(-25,0)); ally.hp = 20
		if id=="tongue_snag": enemy.position = center
		if id=="peekaboo": unit.hidden_until = 10
		if id=="shell_retreat": unit.hp = floori(unit.max_hp*.3)
		if id=="reassemble": unit.hp = floori(unit.max_hp*.25)
		if id=="toll_shakedown": game.thief_steal_timers[enemy] = 3.5; enemy.set_meta("stolen_gold",100)
		if id=="tunnel_hop":
			var found := false
			for points in battle.map.layout.defense_points.values():
				for point in points:
					var line: String = battle.map.tags_at(point).defense_line
					if line in [unit.get_cell_tags().defense_line,"2"] and battle.map.world(point).distance_to(unit.position)>150:
						enemy.position = battle.map.world(point); found = true; break
				if found: break
		var before_hp: int = enemy.hp; var before_gold: int = GameState.gold; var before: Vector2 = unit.position
		var ok: bool = battle.monster_skills.cast(unit,id)
		expect(ok,id+" activates")
		if not ok: continue
		tested.append(id)
		expect(unit.reassemble_used if id=="reassemble" else not unit.skill_ready(id),id+" cooldown or once-use gate")
		match id:
			"tongue_snag":
				expect(enemy.root_timer>1.49 and enemy.slow_timer>2.99 and is_equal_approx(enemy.slow_factor,.6),id+" root/slow")
				tick(1.6); expect(enemy.root_timer==0 and enemy.slow_timer>1,id+" separate durations")
			"puddle_song": expect(ally.guard_timer>4.99 and ally.effective_def()>=ally.def+3,id+" guard5")
			"slime_trail": expect(battle.temporary_traps.size()>0 and battle.temporary_traps[-1].remaining>=6,id+" temporary sticky6+2")
			"shell_retreat": expect(unit.shield_timer>3.99 and is_equal_approx(unit.damage_reduction,.6),id+" shield4")
			"no_passage","hero_pose": expect(enemy.threat_unit==unit,id+" taunt")
			"toll_shakedown": expect(game.thief_steal_timers[enemy]==0 and GameState.gold==before_gold+50 and enemy.get_meta("stolen_gold")==50,id+" reset and50%")
			"peekaboo": expect(enemy.hp<before_hp and enemy.goal_room=="entrance" and not unit.stealthed(),id+" damage fear unhide")
			"blanket_hide":
				expect(not unit.is_targetable_by(enemy),id+" hidden"); tick(3.1); expect(unit.is_targetable_by(enemy),id+" ends3")
			"reassemble":
				var hp: int = unit.hp; tick(2.9); expect(unit.hp==hp,id+" delayed heal")
				tick(.2); expect(unit.hp==hp+roundi(unit.max_hp*.25),id+" heal25 after3")
				unit.skill_cooldowns.clear(); expect(not battle.monster_skills.cast(unit,id),id+" once per battle")
			"wax_drip": expect(enemy.hp<before_hp and enemy.slow_timer>1.99 and is_equal_approx(enemy.slow_factor,.8),id+" damage slow2")
			"tunnel_hop": expect(unit.position!=before and battle.home(unit)==unit.position,id+" self teleport empty defense")
			"undermine": expect(enemy.action_interrupt_timer>2.49 and enemy.effective_def()<=enemy.def-3,id+" interrupt and armor")
			"wrong_way": expect(enemy.has_meta("v130r_original_goal") and float(enemy.get_meta("v130r_false_until"))==4,id+" false4")
			"map_spread": expect(ally.effective_move_speed()>ally.move_speed,id+" move15%5")
			"swarm": expect(enemy.hp<before_hp and enemy.slow_timer>1.99 and is_equal_approx(enemy.slow_factor,.85),id+" three hits slow2")
			"stitch_curse":
				expect(enemy.effective_atk()<enemy.atk,id+" attack85 six seconds")
				var current_hp: int = enemy.hp; enemy.receive_damage(50)
				expect(current_hp-enemy.hp==60,id+" all incoming120 including raw trap damage")
			"proxy_pain":
				expect(ally.duo_redirect_target==unit and ally.duo_redirect_timer>4.99,id+" redirect30%5")
				ally.hp = 100
				var protector_hp: int = unit.hp; ally.receive_damage(50)
				expect(protector_hp-unit.hp==15 and ally.hp==65,id+" actual damage split15/35")
		tick(22)
		expect(unit.skill_ready(id),id+" cooldown expires")
		match id:
			"tongue_snag": expect(enemy.root_timer==0 and enemy.slow_timer<=0,id+" effects expire")
			"puddle_song": expect(ally.guard_timer<=0 and ally.guard_bonus==0,id+" guard ends")
			"slime_trail": expect(battle.temporary_traps.is_empty(),id+" restores tile")
			"shell_retreat": expect(unit.shield_timer<=0 and unit.damage_reduction==0,id+" shield ends")
			"no_passage","hero_pose": expect(enemy.threat_timer<=0,id+" taunt expires")
			"peekaboo","wrong_way":
				battle.monster_skills.update_false_goal(enemy)
				expect(not enemy.has_meta("v130r_original_goal"),id+" original goal restored")
			"wax_drip","swarm": expect(enemy.slow_timer<=0,id+" slow expires")
			"undermine": expect(enemy.action_interrupt_timer==0 and enemy.armor_break_amount==0,id+" both timers expire")
			"map_spread": expect(is_equal_approx(ally.night_relay_move_multiplier,1.0),id+" speed restored")
			"stitch_curse": expect(enemy.effective_atk()==enemy.atk and is_equal_approx(enemy.damage_taken_multiplier_from(unit),1.0),id+" curse ends6")
			"proxy_pain": expect(ally.duo_redirect_timer==0,id+" redirect ends5")

	evidence["active_skills"] = tested

func passives() -> void:
	clear_units()
	var wet := Vector2i.ZERO
	for cell in battle.map.layout.road_cells:
		if battle.map.tags_at(cell).water_adjacent: wet = cell; break
	var point: Vector2 = battle.map.world(wet)
	var frog := make("river_frog",point)
	expect(frog.effective_atk()==roundi(frog.atk*1.1),"rainy_day wet attack110%")
	var candle := make("candle_wisp",point)
	expect(candle.effective_atk()==roundi(candle.atk*.8),"afraid_of_drips wet attack80%")
	var shadow := make("under_bed_shadow",point)
	var thief := foe("thief",point)
	shadow.hidden_until = 5
	expect(not shadow.is_targetable_by(thief),"under_the_bed starts hidden")
	shadow.break_stealth(); expect(shadow.is_targetable_by(thief),"under_the_bed broken by attack")
	tick(5.1); expect(not shadow.is_targetable_by(thief),"under_the_bed hides after quiet5")
	shadow.receive_damage(10); expect(shadow.is_targetable_by(thief),"under_the_bed hit resets5")
	var concealed := foe("shadow_duelist",battle.map.center("barracks"))
	candle.position = concealed.position
	battle.native_objectives.shadows[concealed.get_instance_id()] = {"hidden_ends":game.combat_time+10}
	expect(not concealed.is_targetable_by(candle),"candle_light fixture is truly concealed before detection")
	battle.monster_skills.tick(.1)
	expect(concealed.is_targetable_by(candle),"candle_light reveals within3 cells")
	candle.position += Vector2(1000,0); tick(.3)
	expect(float(concealed.get_meta("revealed_until"))<=concealed.new_skill_clock and not concealed.is_targetable_by(candle),"candle_light range exit restores actual concealment")
	thief.position = point
	var rat := make("rat_union",point)
	expect(is_equal_approx(battle.monster_skills.slow_theft(thief),.5),"cheese_reclaim theft50% in3")
	thief.set_meta("stolen_gold",100); var gold: int = GameState.gold
	battle.monster_skills.on_downed(thief)
	expect(GameState.gold==gold+100 and thief.get_meta("stolen_gold")==0,"cheese_reclaim returns100% once")
	battle.monster_skills.on_downed(thief); expect(GameState.gold==gold+100,"cheese_reclaim no double return")
	rat.hp = floori(rat.max_hp*.5)
	expect(is_equal_approx(rat.effective_attack_interval(),rat.attack_interval/1.2),"strike_line attack speed120% below50")
	rat.hp = rat.max_hp
	expect(is_equal_approx(rat.effective_attack_interval(),rat.attack_interval),"strike_line ends above50")
	var snail := make("glue_snail",point)
	expect(battle.monster_skills.sticky_extra(wet)==2,"sticky_neighbor extra2 in2")
	snail.position += Vector2(1000,0)
	expect(battle.monster_skills.sticky_extra(wet)==0,"sticky_neighbor outside2 no bonus")
	var mole := make("mole_digger",point)
	var hp: int = mole.hp; mole.receive_context_damage(40,thief,true,false)
	expect(hp-mole.hp==30,"safety_first area damage75%")
	hp = mole.hp; mole.receive_context_damage(40,thief,false,false)
	expect(hp-mole.hp==40,"safety_first single hit unchanged")
	var paper := make("crumpled_map",point)
	hp = paper.hp; paper.receive_context_damage(40,thief,false,false)
	expect(hp-paper.hp==20,"paper_body first hit50%")
	hp = paper.hp; paper.receive_context_damage(40,thief,false,true)
	expect(hp-paper.hp==52,"paper_body fire130% after first hit")
	var armor := make("hollow_armor",point)
	var hero := foe("official_hero_leon",point)
	expect(is_equal_approx(armor.damage_taken_multiplier_from(hero),.8),"old_masters_scent hero damage80%")
	var doll := make("curse_doll",point); var tailor := make("spider_tailor",point)
	var troll := make("bridge_troll",battle.map.world(battle.map.layout.bridges.keys()[0]))
	var hp_doll: int = doll.max_hp; var hp_troll: int = troll.max_hp; var defense: int = troll.def
	battle.monster_skills.setup(battle)
	expect(doll.max_hp==roundi(hp_doll*1.1),"mothers_stitches deployed Silky HP110%")
	expect(troll.max_hp==roundi(hp_troll*1.1) and troll.def==defense+4,"my_bridge_my_job bridge HP110 defense4")
	var saved_hp: int = armor.hp; armor.receive_context_damage(50,hero,true,false)
	expect(saved_hp-armor.hp==40,"old_masters_scent hero area80%")
	clear_units()
	var engineer := foe("engineer",battle.map.center("bait_treasure"))
	engineer.goal_room = "bait_treasure"; engineer.attack_cooldown = 0
	battle.update_room_effects(.1)
	expect(engineer.goal_room=="throne" and not engineer.path_points.is_empty(),"engineer continues after disabling facility; DAY30 cannot stall there")
	evidence["passive_skills"] = ["rainy_day","afraid_of_drips","under_the_bed","candle_light","cheese_reclaim","strike_line","sticky_neighbor","safety_first","paper_body","old_masters_scent","mothers_stitches","my_bridge_my_job"]

func directions() -> void:
	clear_units()
	var point: Vector2 = battle.map.center("barracks")
	for row in view.monster_ui.members.values():
		var unit := make(row.species_id,point)
		for direction in [Vector2(-1,1),Vector2(1,1),Vector2(1,-1),Vector2(-1,-1)]:
			unit.face_direction(direction); unit.velocity = direction*30; unit._update_animation()
			expect(unit.sprite.animation.ends_with("_ne")==bool(direction.y<0),"direction bank "+unit.unit_id+str(direction))
			expect(unit.sprite.flip_h==bool(direction.x>0 if direction.y>0 else direction.x<0),"direction flip "+unit.unit_id+str(direction))
		unit.velocity = Vector2.ZERO; unit.attack_anim_timer = 0; unit.skill_anim_timer = 0
		for animation in unit.sprite.sprite_frames.get_animation_names():
			if animation=="default" or animation.begins_with("down"): continue
			unit.sprite.animation = animation
			for frame in range(unit.sprite.sprite_frames.get_frame_count(animation)):
				unit.sprite.frame = frame; unit._apply_visual_pose()
				var texture: Texture2D = unit.sprite.sprite_frames.get_frame_texture(animation,frame)
				expect(texture is AtlasTexture and texture.get_width()<=texture.atlas.get_width()/4.0+.1,"sheet slices one body "+row.species_id+" "+animation+str(frame))

				var height: float = unit.visible_body_rect().size.y
				var target: float = unit.Presentation.BODY_HEIGHT*unit.Presentation.multiplier(row.species_id)
				expect(height>=target-.2 and height<=target*1.061,"live frame height "+row.species_id+" "+animation+str(frame))
		clear_units()

func shot(name: String) -> void:
	if battle!=null and battle.running:
		for unit in game.monster_units+game.enemy_units:
			unit.refresh_depth_slot()
			expect(unit.map_visual.position.distance_to(unit.position)<.01,"body matches simulated position "+name+" "+unit.unit_id)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	expect(image.get_size()==Vector2i(1920,1080),"actual1920 "+name)
	expect(image.save_png(OUT+name+".png")==OK,"screenshot "+name)

func captures() -> void:
	view.monster_ui.set_mode("place")
	await shot("roster_24")
	for id in view.monster_ui.cards:
		var rect: Rect2 = view.monster_ui.cards[id].get_global_rect()
		expect(Rect2(Vector2.ZERO,Vector2(1920,1080)).encloses(rect),"visible roster card "+id)
	start()
	game.wave_manager.setup(15,DataRegistry.waves)
	view.set_physics_process(true); battle.set_speed(3)
	while battle.running and game.combat_time<120 and battle.contacts.is_empty(): await get_tree().process_frame
	battle.set_pause_state(true); view.set_physics_process(false)
	expect(battle.running and not battle.contacts.is_empty(),"DAY15 real wave first contact")
	await shot("battle_new_day15")
	clear_units(); await get_tree().process_frame
	var center: Vector2 = battle.map.world(battle.map.layout.bridges.keys()[0])
	var fixture_center: Vector2 = center+Vector2(500,600)
	view.set_camera(fixture_center,.75)
	var vectors := [Vector2(-1,1),Vector2(1,1),Vector2(1,-1),Vector2(-1,-1)]
	for index in range(4):
		var unit := make("river_frog",fixture_center+Vector2(-420+index*280,0))
		unit.display_name = ["남서 SW","남동 SE","북동 NE","북서 NW"][index]; unit.name_label.text = unit.display_name
		unit.face_direction(vectors[index]); unit.velocity = vectors[index]*30; unit._update_animation()
	await shot("directions")
	clear_units(); await get_tree().process_frame
	var compare := ["slime","stone_sentinel","armored_beetle","goblin","river_frog","bridge_troll","hollow_armor","mole_digger"]
	for index in range(compare.size()):
		var unit := make(compare[index],fixture_center+Vector2(-450+(index%4)*300,-100+(index/4)*250))
		unit.name_label.text = DataRegistry.monster(compare[index]).get("display_name",compare[index])
		unit._update_animation()
	await shot("compare_scale")
	var label: Label = view.label_at(view.chrome,"",Vector2(550,170),24,true)
	for id in ["tongue_snag","no_passage","peekaboo","tunnel_hop","cheese_reclaim","reassemble"]:
		clear_units(); await get_tree().process_frame
		var species: String = {"tongue_snag":"river_frog","no_passage":"bridge_troll","peekaboo":"under_bed_shadow","tunnel_hop":"mole_digger","cheese_reclaim":"rat_union","reassemble":"hollow_armor"}[id]
		var unit := make(species,center)
		var enemy := foe("thief" if id=="cheese_reclaim" else "explorer",center+Vector2(35,10))
		if id=="tongue_snag": enemy.position = center; unit.position = center+Vector2(-140,30)
		if id=="peekaboo": unit.hidden_until = unit.new_skill_clock+5
		if id=="reassemble": unit.hp = floori(unit.max_hp*.25)
		if id=="tunnel_hop":
			for points in battle.map.layout.defense_points.values():
				for point in points:
					if battle.map.tags_at(point).defense_line in [unit.get_cell_tags().defense_line,"2"] and battle.map.world(point).distance_to(center)>180:
						enemy.position = battle.map.world(point); break
		if id=="cheese_reclaim":
			enemy.set_meta("stolen_gold",100); var gold: int = GameState.gold
			enemy.hp = 1; enemy.receive_damage(100)
			expect(GameState.gold==gold+100,"visual cheese returns actual100")
			label.text = "치즈값 회수 · 도둑 사망 / 금화 +100 / 3칸 범위"
		else:
			expect(battle.monster_skills.cast(unit,id),"visual skill activates "+id)
			label.text = str(DataRegistry.skill(id).display_name)+" · "+str(DataRegistry.skill(id).description)
		label.size.x = 1250; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		view.set_camera(unit.position,.75)
		unit._update_animation(); enemy._update_animation()
		view.battle_ui.select_unit(unit)
		await shot("skill_"+id)
	label.queue_free()
	# Normal recruitment dialogue, with the roster addition delayed to its final line.
	battle.running = false; battle._clear_active_combat_tweens()
	game.graph = battle.original_graph; game.rooms = battle.original_rooms; game.combat_scene = battle.original_controller
	game.effect_root.reparent(battle.effects_home,false)
	view.placement.day = 6; view.placement.food_state = Food.fresh()
	var Grade = load("res://scripts/map_builder/ApprovedGradeProgression.gd")
	Grade.stash(game,view.placement,{})
	game.monster_roster.erase("river_frog")
	Recruits.begin(game,["mon_v130r_pongdang"])
	await get_tree().process_frame
	expect(game.current_screen==Constants.SCREEN_DIALOGUE,"join uses existing dialogue UI")
	expect("mon_v130r_pongdang" not in Grade.load_session(game).layout.food_state.owned,"join locked before final line")
	await shot("join_scene")
	for index in range(4): game._onboarding_advance_dialogue()
	await get_tree().process_frame
	view = game.ui_layer.get_node("ApprovedMapManagement")
	expect("mon_v130r_pongdang" in view.monster_ui.joined and game.monster_roster.has("river_frog"),"join added after full four lines")
	evidence["join"] = {"species":"river_frog","lines":4,"owned_after":view.monster_ui.joined}

func balance() -> void:
	var rows: Array = []
	game.selected_contract_ids.assign(["spore_healer","stone_sentinel"])
	for day in ([30] if OS.get_cmdline_user_args().has("--balance-last") else [5,10,15,20,25,30]):
		for trial in range(1 if OS.get_cmdline_user_args().has("--balance-last") else 10):
			seed(130700+trial)
			view.placement = Buildings.initial(game,"F" if day<15 else "E")
			view.placement.day = day; view.placement.food_state = Food.fresh()
			GameState.day = day; GameState.max_day = 30; GameState.demon_lord_max_hp = 1500; GameState.demon_lord_hp = 1500
			GameState.food_state = Food.fresh(); GameState.gold = 1200; GameState.mana = 600; GameState.food = Food.capacity(day)
			var eligible: Array = Recruits.eligible(game,view.monster_ui.members,day)
			view.monster_ui.assignments = Members.auto_place(view.placement,view.monster_ui.members,eligible,Food.income(day))
			view.render_map()
			battle = load("res://tools/tests/V130RStep7Simulation.gd").new(); battle.begin(view)
			view.set_physics_process(false); game.combat_paused = false
			var steps := 0
			while battle.running and game.combat_time<600:
				var delta := 1.0/30.0
				battle.physics_process(delta)
				for unit in game.monster_units+game.enemy_units:
					unit.set_physics_process(false); unit._physics_process(delta)
				for tween in battle.active_combat_tweens.duplicate():
					if tween!=null and tween.is_valid(): tween.pause(); tween.custom_step(delta)
				steps += 1
				if steps%9000==0:
					for unit in game.monster_units+game.enemy_units:
						if unit.is_alive(): print("STATE ",game.combat_time," ",unit.unit_id," hp=",unit.hp," room=",unit.current_room," goal=",unit.goal_room," cell=",battle.map.cell(unit.position)," path=",unit.path_points.size()," state=",unit.tactical_state)
				if steps%150==0: await get_tree().process_frame
			expect(not battle.running,"DAY%d trial%d completes within600s" % [day,trial])
			var row: Dictionary = battle.last_result.duplicate(true)
			row.merge({"day":day,"trial":trial,"seed":130700+trial,"timeout":battle.running,"assignments":view.monster_ui.assignments.duplicate(true),"upkeep":Members.upkeep(view.monster_ui.assignments,view.monster_ui.members),"throne_hp":GameState.demon_lord_hp,"throne_max":GameState.demon_lord_max_hp})
			rows.append(row)
			print("BALANCE DAY",day," #",trial," win=",row.get("win",false)," HP=",GameState.demon_lord_hp," time=",game.combat_time)
			battle.release(); battle = null
			await get_tree().process_frame
		evidence["balance"] = rows
		var checkpoint := FileAccess.open(OUT+"balance_rows.json",FileAccess.WRITE); checkpoint.store_string(JSON.stringify(rows,"\t")); checkpoint.close()

func stop() -> void:
	if battle!=null: battle.running = false; battle._clear_active_combat_tweens()
	game.campaign_autosave_pending = false; game._shutdown_audio_for_exit()
	preview.queue_free(); await get_tree().process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await boot()
	if OS.get_cmdline_user_args().has("--balance"):
		mode = "balance"; await balance()
	elif OS.get_cmdline_user_args().has("--capture"):
		mode = "capture"; await captures()
	else:
		catalog(); duos(); skills(); passives(); directions()
	await stop()
	var result := {"result":"TARGETED_PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"evidence":evidence}
	var file := FileAccess.open(OUT+mode+"_result.json",FileAccess.WRITE); file.store_string(JSON.stringify(result,"\t")); file.close()
	print("Step7 ",mode," ",checks," checks / ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
