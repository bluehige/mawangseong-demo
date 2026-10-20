extends "res://tools/tests/V130RStep8BSpreadTest.gd"
const SPEC = preload("res://scripts/systems/SpecializationEffects.gd")
const DEST := "res://_mockup/game_step9_spec/"
const Silky = preload("res://scripts/systems/monsters/SilkyCombatService.gd")
const Popo = preload("res://scripts/systems/monsters/PopoCombatService.gd")
var spec_rows: Array = []
var spec_variant := -1

func prepare(day: int, layout_mode: String) -> void:
	super.prepare(day,layout_mode)
	if spec_variant>=0:
		for species in game.monster_roster:
			var options: Array = game._specializations_for_monster(species)
			if options.size()==2: game.monster_roster[species].specialization_id = options[spec_variant].id
	for id in view.monster_ui.members:
		view.monster_ui.members[id].level = int(game.monster_roster[view.monster_ui.members[id].species_id].level)
	if DisplayServer.get_name()!="headless":
		for id in view.monster_ui.cards:
			for child in view.monster_ui.cards[id].get_children():
				if child is Label and child.text.begins_with("Lv"): child.text = "Lv"+str(view.monster_ui.members[id].level)

func actor(species: String, at: Vector2) -> Node:
	var stats: Dictionary = DataRegistry.monster(species).duplicate(true)
	game._apply_specialization_stats(species,stats)
	var unit: Node = battle.make_unit(species,stats,"monster","barracks")
	unit.position = at; unit.set_physics_process(false)
	unit.set_meta("base_attack_range",unit.attack_range)
	unit.set_meta("specialization",game._monster_specialization(species).duplicate(true))
	battle.homes[unit.get_instance_id()] = at; game.monster_units.append(unit)
	return unit

func near(a: float, b: float) -> bool: return absf(a-b)<.0001

func legacy_skill(unit: Node, id: String) -> bool:
	var slots: Array = battle.skill_slots_for(unit)
	game.selected_unit = unit; game.combat_paused = false
	var intent: Dictionary = battle._prepare_selected_skill(slots.find(id),false)
	return not intent.is_empty() and battle._commit_prepared_skill(intent)

func verify_spec(id: String) -> void:
	clear_units(); seed(130900)
	var rule: Dictionary = DataRegistry.specialization(id)
	var species := str(rule.monster_id)
	game.monster_roster.clear(); game.monster_roster[species] = {"level":1,"exp":0,"bond":0,"specialization_id":id}
	var center: Vector2 = battle.map.world(battle.map.layout.bridges.keys()[0])
	var unit := actor(species,center)
	var ally := actor("slime",center+Vector2(15,0)); ally.hp = 25
	var second := actor("goblin",center+Vector2(25,0)); second.hp = 25
	var enemy := foe("explorer",center+Vector2(20,0))
	var engineer := foe("engineer",center+Vector2(25,5))
	var thief := foe("thief",center+Vector2(30,0)); thief.set_meta("stolen_gold",100)
	var investigator := foe("investigator",center+Vector2(35,0))
	for foe_unit in game.enemy_units: foe_unit.new_skill_clock = 0
	var count_before := checks
	expect(not SPEC.preview(rule,DataRegistry.monster(species)).is_empty(),"numeric arrow preview "+id)
	if rule.has("ai_behavior"): expect(game._monster_ai_behavior(species)==str(rule.ai_behavior),"existing AI behavior connected "+id)
	var failures_before := failures.size()
	var detail := ""
	match id:
		"slime_gate_keeper": expect(unit.max_hp==roundi(float(DataRegistry.monster(species).max_hp)*1.15),"gate HP +15% applied to spawned actor")
		"slime_rescue_guard":
			expect(near(unit.move_speed,float(DataRegistry.monster(species).move_speed)*1.2),"rescue movement +20%")
			ally.position = center+Vector2(95,0); ally.current_room = "line_final"
			second.hp = second.max_hp; enemy.position = center-Vector2(80,0)
			expect(battle._most_wounded_ally(unit)==ally,"guard chooses an actual local wounded ally")
			battle.move_unit_to_room(unit,"line_final")
			expect(unit.get_meta("road_destination")==battle.map.nearest_cell(ally.position),"guard follows ally position rather than enemy")
			ally.position = center+Vector2(4*SPEC.CELL,0)
			expect(battle._most_wounded_ally(unit)==null,"guard respects existing three-cell home leash")
		"goblin_treasure_hunter": expect(near(unit.move_speed,float(DataRegistry.monster(species).move_speed)*1.18),"hunter movement +18%")
		"goblin_finisher": expect(unit.atk==roundi(float(DataRegistry.monster(species).atk)*1.18),"finisher ATK +18%")
		"imp_artillery": expect(near(unit.attack_range,float(DataRegistry.monster(species).attack_range)*1.18),"artillery range +18%")
		"imp_trap_weaver": expect(unit.max_hp==roundi(float(DataRegistry.monster(species).max_hp)*1.12),"weaver HP +12%")
		"bebe_night_steward": expect(unit.atk==roundi(float(DataRegistry.monster(species).atk)*.9),"steward ATK penalty")
		"bebe_poltergeist_cleaner":
			var result: Dictionary = battle.perform_bebe_broom(unit)
			expect(result.get("ok",false) and near(game._combat_skill_float(species,"haunted_broom_whirl","knockback_bonus"),14),"cleaner broom uses +14 knockback")
			var rescue: Dictionary = battle.perform_bebe_rescue(unit,ally)
			expect(rescue.get("ok",false) and ally.duo_barrier==10,"cleaner rescue penalty applies once")
		"koko_bounty_sniffer":
			var result: Dictionary = battle.perform_koko_scent_lock(unit,enemy)
			expect(result.get("ok",false) and near(float(result.get("attack_multiplier",0)),1.22) and near(float(result.get("duration",0)),8),"bounty marked hit +12pp / +1s")
			var bark: Dictionary = battle.perform_koko_home_guard_bark(unit)
			expect(bark.shield==10,"bounty other-skill shield penalty")
		"koko_throne_shepherd":
			var result: Dictionary = battle.perform_koko_home_guard_bark(unit)
			expect(result.get("normal_targets",0)==3,"shepherd taunts three actual targets")
		"toktok_shell_breaker": expect(near(game._combat_skill_float(species,"carapace_ram","def_reduction_bonus"),1),"ram extra armor break")
		"toktok_castle_mason":
			expect(near(battle._toktok_ram_distance(unit),85),"mason actual ram distance 85px")
			var plates: Dictionary = battle.perform_toktok_patch_plates(unit,ally)
			expect(plates.get("shield",0)==38,"mason other-skill barrier bonus")
		"silky_stair_warden":
			var result := Silky.place_thread({},"threshold",["threshold"],id,DataRegistry.skill("stitch_stairway"))
			expect(near(result.state.thread.slow_multiplier,.6) and result.state.thread.fire_durability==3,"thread slow40% / durability3")
		"silky_field_tailor":
			var result := Silky.emergency_pull({},{"hp":20,"max_hp":200,"alive":true},Vector2.LEFT,id,DataRegistry.skill("emergency_thread_pull"))
			expect(result.shield==30 and result.facility_repair==12,"tailor barrier15% / repair12")
		"popo_royal_express":
			var result := Popo.apply_night_relay({},id,DataRegistry.skill("night_relay"))
			expect(near(result.popo_buff.move_multiplier,1.2) and near(result.popo_buff.attack_interval_multiplier,.86),"express buff values")
			var hold := Popo.hold_first_theft({},"thief",id,DataRegistry.skill("messenger_bag"))
			expect(near(hold.state.pending.remaining,4),"express bag tradeoff4s")
		"popo_seal_guard":
			var result := Popo.hold_first_theft({},"thief",id,DataRegistry.skill("messenger_bag"))
			expect(result.held and near(result.state.pending.remaining,7),"seal guard holds actual theft7s")
			enemy.set_meta("spec_bag_carrier",unit.get_instance_id()); enemy.set_meta("spec_bag_until",7)
			expect(near(battle.spec_effects.damage_multiplier(unit,enemy),1.1),"seal guard actual held-target damage10%")
		"frog_bridge_watch":
			expect(battle.monster_skills.cast(unit,"tongue_snag"),"tongue cast")
			expect(near(enemy.root_timer,2),"tongue roots2s")
		"frog_choir":
			ally.position = center+Vector2(SPEC.CELL*2.8,0)
			expect(battle.monster_skills.cast(unit,"puddle_song"),"choir cast")
			expect(ally.guard_bonus==4,"choir reaches2.8cells with DEF4")
		"snail_trail_layer":
			expect(battle.monster_skills.cast(unit,"slime_trail"),"trail cast")
			expect(battle.temporary_traps.size()==2 and near(unit.skill_cooldowns.get("slime_trail",0),10),"two actual traps /10s cooldown")
		"snail_fortress":
			unit.hp = 20; expect(battle.monster_skills.cast(unit,"shell_retreat"),"retreat cast")
			expect(near(unit.damage_reduction,.7),"70% damage reduction")
		"troll_gatekeeper":
			enemy.position = center+Vector2(1.9*SPEC.CELL,0)
			expect(battle.monster_skills.cast(unit,"no_passage"),"gate taunt cast")
			expect(enemy.threat_forced and near(enemy.threat_timer,4),"taunt4s reaches1.9cells")
		"troll_tax_collector":
			var gold: int = GameState.gold
			battle.monster_skills.toll(thief,unit)
			expect(GameState.gold==gold and unit.get_meta("spec_toll_pending",0)==50,"toll removed from carrier, deferred once")
			expect(battle.spec_effects.refund_tolls()==50 and GameState.gold==gold+50 and battle.spec_effects.refund_tolls()==0,"100% dropped toll returned once at settlement")
		"shadow_nightmare":
			unit.hidden_until = 10
			expect(battle.monster_skills.cast(unit,"peekaboo"),"fear cast")
			expect(near(investigator.get_meta("v130r_false_until",0),3.5),"fear spreads1cell for3.5s")
		"shadow_lullaby":
			unit.hidden_until = 10; battle.spec_effects.tick(1)
			expect(ally.hp==27 and second.hp==27,"stealth heals nearby2HP/sec")
		"armor_throne_guard":
			unit.position = battle.map.center("throne"); battle.spec_effects.tick(.01)
			expect(unit.get_meta("spec_position_def",0)==5,"throne conditional DEF+5")
			unit.position += Vector2(6*SPEC.CELL,0); battle.spec_effects.tick(.01)
			expect(unit.get_meta("spec_position_def",0)==0,"throne defense removed outside5cells")
		"armor_wandering_knight":
			expect(battle.monster_skills.cast(unit,"hero_pose"),"hero pose cast")
			expect(investigator.threat_forced and near(unit.skill_cooldowns.get("hero_pose",0),7),"fourth taunt /7s cooldown")
		"wisp_beacon":
			ally.position = center+Vector2(3.8*SPEC.CELL,0); battle.spec_effects.tick(.01)
			expect(near(battle.spec_effects.damage_multiplier(ally,enemy),1.05),"beacon damage+5% at3.8cells")
		"wisp_bonfire":
			expect(battle.monster_skills.cast(unit,"wax_drip"),"wax cast")
			var hp: int = investigator.hp; battle.spec_effects.tick(1)
			expect(investigator.hp<hp and near(investigator.get_meta("spec_burn_until",0),2),"adjacent enemy burns2s")
		"mole_foreman":
			var point: Vector2i = view.placement.defense_points.throne[0]
			unit.position = battle.map.world(point); battle.homes[unit.get_instance_id()] = unit.position
			# A next legal defense slot has nearby enemies, enabling the real hop.
			enemy.position = battle.map.world(view.placement.defense_points.throne[-1])+Vector2(8,0)
			var destination: Dictionary = battle.monster_skills.hop_destination(unit)
			if not destination.is_empty(): ally.position = destination.point+Vector2(12,0)
			expect(battle.monster_skills.cast(unit,"tunnel_hop"),"foreman hop cast")
			expect(ally.guard_bonus==3 and near(ally.guard_timer,2),"arrival grants DEF3 /2s")
		"mole_saboteur":
			expect(battle.monster_skills.cast(unit,"undermine"),"undermine cast")
			expect(near(engineer.action_interrupt_timer,3.5),"engineer interrupted3.5s")
		"map_labyrinth":
			expect(battle.monster_skills.cast(unit,"wrong_way"),"wrong way cast")
			expect(investigator.has_meta("v130r_original_goal") and near(investigator.get_meta("v130r_false_until",0),6),"investigator rerouted6s")
		"map_guide":
			ally.position = center+Vector2(2.8*SPEC.CELL,0)
			expect(battle.monster_skills.cast(unit,"map_spread"),"map spread cast")
			expect(near(ally.effective_move_speed()/ally.move_speed,1.25),"guide move25% reaches2.8cells")
		"rats_vault_union":
			thief.position = center+Vector2(3.8*SPEC.CELL,0)
			var gold: int = GameState.gold; battle.monster_skills.on_downed(thief)
			expect(GameState.gold==gold+120 and thief.get_meta("stolen_gold",0)==0,"4cell recovery100 + bonus20")
		"rats_night_shift":
			var hp: int = enemy.hp; var per_hit: int = battle.monster_skills.deal(unit,enemy,1); enemy.hp = hp
			expect(battle.monster_skills.cast(unit,"swarm"),"swarm cast")
			expect(hp-enemy.hp==per_hit*5 and near(unit.skill_cooldowns.get("swarm",0),11),"swarm five hits /11s")
		"doll_hex_mistress":
			expect(battle.monster_skills.cast(unit,"stitch_curse"),"curse cast")
			expect(near(enemy.get_meta("curse_damage_multiplier",0),1.3) and near(enemy.get_meta("curse_attack_multiplier",0),.8) and near(enemy.get_meta("curse_until",0),8),"curse+30/-20/8s")
		"doll_guardian":
			expect(battle.monster_skills.cast(unit,"proxy_pain"),"proxy cast")
			expect(near(ally.duo_redirect_fraction,.4) and near(second.duo_redirect_fraction,.4),"two allies redirect40%")
		"mori_field_medic":
			expect(legacy_skill(unit,"spore_mend"),"mend cast")
			expect(ally.hp==80 and second.hp==80,"mend heals two allies55 each")
		"mori_purifier":
			expect(legacy_skill(unit,"cleansing_bloom"),"cleanse cast")
			ally.apply_root(2); ally.apply_action_interrupt(2)
			expect(ally.root_timer==0 and ally.action_interrupt_timer==0 and near(ally.get_meta("spec_immunity_until",0),3),"3s cleanse immunity blocks root and interrupt")
			ally.new_skill_clock = 3.01; ally.apply_root(2)
			expect(ally.root_timer>0,"cleanse immunity expires")
		"dolkong_gate_stone":
			var cell: Vector2i = view.placement.defense_points.watchtower[0]
			unit.position = battle.map.world(cell); battle.spec_effects.tick(.01)
			expect(unit.get_cell_tags().defense_line=="1" and unit.get_meta("spec_position_def",0)==5,"entry-line DEF5")
		"dolkong_quake":
			enemy.position = center+Vector2(230,0)
			expect(legacy_skill(unit,"stone_pulse"),"pulse cast")
			expect(near(enemy.root_timer,1) and near(enemy.action_interrupt_timer,1),"extended pulse stuns movement and actions1s")
		"dudum_war_band":
			ally.position = center+Vector2(230,0); ally.current_room = "throne"
			expect(legacy_skill(unit,"war_rhythm"),"rhythm cast")
			expect(ally.guard_bonus==2,"extended rhythm reaches230px")
		"dudum_lullaby":
			expect(legacy_skill(unit,"war_rhythm"),"lullaby cast")
			expect(near(enemy.effective_attack_interval()/enemy.attack_interval,1/.85) and ally.guard_bonus==0,"enemy attacks15% slower, replaces ally buff")
		"lumi_hunter":
			expect(legacy_skill(unit,"moon_mark"),"moon mark cast")
			expect(near(battle.spec_effects.damage_multiplier(unit,enemy),1.15),"marked damage+15%")
		"lumi_moon_guide":
			expect(legacy_skill(unit,"moon_mark"),"shared moon mark cast"); battle.spec_effects.tick(.01)
			expect(ally.get_meta("spec_team_target",0)==enemy.get_instance_id() and near(ally.effective_move_speed()/ally.move_speed,1.1),"team target and move10%")
		"mimi_bait_master":
			expect(legacy_skill(unit,"false_treasure"),"lure cast")
			expect(near(enemy.threat_timer,8),"lure lasts8s")
		"mimi_vault_jaws":
			expect(legacy_skill(unit,"false_treasure"),"jaws lure cast")
			expect(near(battle.spec_effects.damage_multiplier(unit,enemy),1.5) and near(battle.spec_effects.damage_multiplier(unit,enemy),1),"first lured hit+50% exactly once")
		"rolo_trail_master":
			enemy.position = center+Vector2(300,0)
			expect(legacy_skill(unit,"false_footprints"),"footprints cast")
			expect(near(enemy.slow_factor,.52) and enemy.slow_timer>0,"extended footprints slows48% at300px")
		"rolo_raid_captain":
			var mission := {"reward":{"infamy":100},"recommended_captain":"kobold_scout","risk":"보통","risk_level":2}
			expect(game._raid_reward_with_bonus(mission).infamy==120,"raid reward includes original10% plus spec10%")
			expect(game._raid_risk_level(mission)==1,"raid risk tier reduced by1")
		_: expect(false,"missing test "+id)
	expect(checks>count_before,"effect test exists "+id)
	spec_rows.append({"id":id,"monster":species,"name":rule.display_name,"desc":rule.get("short_effect",rule.get("description","")),"checks":checks-count_before,"pass":failures_before==failures.size(),"failures":failures.slice(failures_before)})
	print("SPEC ",id," ",spec_rows[-1].pass)
	# Remove temporary traps without waiting through their duration.
	for trap in battle.temporary_traps: trap.sprite.queue_free()
	battle.temporary_traps.clear(); battle.rebuild_trap_tags()
	await get_tree().process_frame

func persistence_checks() -> void:
	prepare(15,"recommended")
	GameState.day = 1
	expect(not game._can_choose_early_specialization("slime","slime_gate_keeper"),"DAY1 locked")
	GameState.day = 2
	expect(game._choose_early_specialization("slime","slime_gate_keeper",false),"DAY2 first pick")
	expect(not game._can_choose_early_specialization("goblin","goblin_finisher"),"DAY2 team limit")
	GameState.day = 4
	expect(game._can_choose_early_specialization("goblin","goblin_finisher"),"DAY4 next pick")
	expect(not game._can_choose_early_specialization("slime","slime_rescue_guard"),"permanent pick")
	expect(not game._can_choose_early_specialization("goblin","slime_rescue_guard"),"wrong species rejected")
	view.monster_ui.persist()
	var restored := Members.load_copy(view.placement,view.monster_ui.members,view.save_path())
	expect(restored.layout.specializations.get("slime","")=="slime_gate_keeper","copy save/reload preserves selection")
	var old := Buildings.snapshot(view.placement); old.erase("specializations")
	var migrated := Buildings.restore(old,Buildings.initial(game,"E"))
	expect(migrated.get("ok",false) and migrated.specializations.is_empty(),"old copy missing optional field loads")
	expect(SPEC.valid_choices({"slime":"goblin_finisher","imp":"missing"}).is_empty(),"invalid saved selections ignored")
	var next := preload("res://scripts/map_builder/ApprovedGradeProgression.gd").advance(game,restored.layout,restored.defenders,16)
	expect(next.ok and next.layout.specializations.slime=="slime_gate_keeper","next day preserves selection")
	var lower := Buildings.initial(game,"F"); lower.day = 14
	lower["specializations"] = {"slime":"slime_gate_keeper"}
	var expanded := preload("res://scripts/map_builder/ApprovedGradeProgression.gd").advance(game,lower,{},15)
	expect(expanded.ok and expanded.layout.grade=="E" and expanded.layout.specializations.slime=="slime_gate_keeper","F to E expansion preserves selected specialization")

func capture_info() -> void:
	prepare(15,"recommended"); view.monster_ui.set_mode("place")
	var id := ""
	for candidate in view.monster_ui.assignments:
		if view.monster_ui.members[candidate].species_id=="slime": id = candidate
	if id=="": id = str(view.monster_ui.assignments.keys()[0])
	var species: String = view.monster_ui.members[id].species_id
	game.monster_roster[species].specialization_id = ""
	view.set_camera(Vector2(1900,1250),.65)
	view.monster_ui.show_info(id)
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DEST+"spec_choose.png")
	var options: Array = game._specializations_for_monster(species)
	var icon: TextureButton = view.monster_ui.detail.find_child("SpecChoose_"+str(options[0].id),true,false)
	var point: Vector2 = icon.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = point; Input.parse_input_event(motion)
	await get_tree().process_frame
	for pressed in [true,false]:
		var click := InputEventMouseButton.new(); click.position = point; click.button_index = MOUSE_BUTTON_LEFT; click.pressed = pressed
		Input.parse_input_event(click); await get_tree().process_frame
	await get_tree().process_frame
	expect(game.monster_roster[species].specialization_id==str(options[0].id),"actual map icon click selects specialization")
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DEST+"spec_info.png")

func capture_spread(_day: int, _layout_mode: String) -> void:
	for unit in game.monster_units+game.enemy_units: unit.refresh_depth_slot()
	view.set_camera(Vector2(1900,1250),.65); view.battle_ui.refresh()
	set_review_caption("DAY24 · 전문화 전원 적용 · 추천 배치 · 실제 전투")
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DEST+"spec_battle.png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DEST))
	var run_mode := "direct"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--spec-mode="): run_mode = arg.get_slice("=",1)
	config = {"name":"step9","fast_cosmetics":true}
	await boot(); base_members = Members.roster(); game.selected_contract_ids.assign(["spore_healer","stone_sentinel"])
	if run_mode=="direct":
		await persistence_checks()
		prepare(30,"recommended"); battle = SIM8B.new(); battle.omit_cosmetics = true; battle.begin(view); game.combat_paused = true
		var source_probe := foe("explorer",battle.map.center("entrance"))
		expect(battle._apply_v122_focus_damage(null,source_probe,100)==100,"optional absent damage source stays safe")
		expect(near(battle.spec_effects.damage_multiplier(null,source_probe),1),"null source has no specialization damage bonus")
		var ids: Array = DataRegistry.specializations.keys(); ids.sort()
		expect(ids.size()==48,"48 specialization definitions")
		for id in ids: await verify_spec(str(id))
		battle.release(); battle = null
		save_json(DEST+"spec_results.json",spec_rows)
		await preparation_day_checks()
	elif run_mode=="capture":
		await capture_info()
		spec_variant = 0
		rows.append(await trial(24,0,"recommended",true))
	else:
		if FileAccess.file_exists(DEST+"balance_rows.json"): rows = JSON.parse_string(FileAccess.get_file_as_string(DEST+"balance_rows.json"))
		for variant in [-1,0,1]:
			spec_variant = variant
			for day in [15,24,30]:
				for index in range(10):
					if rows.any(func(r): return r.day==day and r.trial==index and r.spec_variant==variant): continue
					var row: Dictionary = await trial(day,index,"recommended",false)
					row["spec_variant"] = variant; rows.append(row)
					save_json(DEST+"balance_rows.json",rows)
	await stop()
	save_json(DEST+run_mode+"_checks.json",{"checks":checks,"failures":failures})
	print("STEP9_DONE ",run_mode," checks=",checks," failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
