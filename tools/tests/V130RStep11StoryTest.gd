extends "res://tools/tests/V130RStep10DCTest.gd"
const S11 := "res://_mockup/game_step11_story/"
var condition := "off"
var link_evidence: Array = []

func start() -> void:
	battle = SIM8B.new(); battle.begin(view)
	view.set_physics_process(false); game.combat_paused = true
	game.wave_manager.next_index = game.wave_manager.total_to_spawn

func prepare(day: int, layout_mode: String) -> void:
	super.prepare(day,layout_mode)
	game.update3_profile = game.FrontCampaignServiceScript.default_update3_profile()
	game.update3_active_run = {"equipped_duo_links":[],"duo_link_auto_use":condition=="on"}
	if condition=="on":
		# Hypothetical prior unlock, not a natural-campaign unlock date claim.
		for id in DataRegistry.update3_duo_links:
			if str(id).begins_with("planned_"):
				game.update3_profile = Duo.unlock_fixture(game.update3_profile,id,DataRegistry.update3_duo_links).profile
		var deployed: Array = view.monster_ui.assignments.keys()
		var ready: Array = []
		for id in game.update3_profile.duo_links.unlocked:
			var members: Array = DataRegistry.update3_duo_links[id].member_instance_ids
			if deployed.has(members[0]) and deployed.has(members[1]): ready.append(id)
		ready.sort()
		for id in ready:
			var result: Dictionary = Duo.equip(game.update3_profile,game.update3_active_run,id,DataRegistry.update3_duo_links)
			if result.ok: game.update3_active_run = result.active_run

func trial(day: int, index: int, layout_mode: String, capture: bool = false) -> Dictionary:
	var result: Dictionary = await super.trial(day,index,layout_mode,capture)
	result["condition"] = condition
	result["unlocked"] = game.update3_profile.get("duo_links",{}).get("unlocked",[]).duplicate()
	result["equipped"] = game.update3_active_run.get("equipped_duo_links",[]).duplicate()
	result["duo_states"] = game.update3_active_run.get("duo_link_states",{}).duplicate(true)
	result["activations"] = game.update3_active_run.get("duo_activation_events",[]).duplicate(true)
	return result

func charge(id: String) -> void:
	for source in DataRegistry.update3_duo_links[id].gauge_sources:
		for n in range(30):
			game._record_update3_duo_link_action(source.member_instance_id,source.source_id,int(source.threshold),"test:%s:%s:%d" % [id,source.member_instance_id,n])

func duo_fixture(id: String) -> Array:
	clear_units()
	var center: Vector2 = battle.map.center("barracks")
	var members: Array = []
	for member_id in DataRegistry.update3_duo_links[id].member_instance_ids:
		var species: String = DataRegistry.monster_instance(member_id).species_id
		var unit: Node = make(species,center+Vector2(members.size()*40,0)); unit.set_meta("instance_id",member_id)
		members.append(unit)
	var enemy: Node = foe("thief",center+Vector2(20,10)); enemy.set_meta("stolen_gold",40)
	game.treasure_gold_stolen_this_battle = 40
	game.update3_profile = Duo.unlock_fixture({},id,DataRegistry.update3_duo_links).profile
	game.update3_active_run = {"equipped_duo_links":[id],"duo_link_auto_use":false}
	battle.duos.setup(battle)
	return members

func direct_story() -> void:
	prepare(20,"recommended"); start()
	game.set_meta("v130r_owned_species",game.monster_roster.keys())
	var new_links: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/v130r/duo_links_new.json"))
	expect(new_links.size()==10 and DataRegistry.update3_duo_links.size()==16,"10 new + 6 existing links")
	for id in new_links:
		var definition: Dictionary = new_links[id]
		var members := duo_fixture(id)
		var progress := {}; var role_counts := {}; var days := {}
		for member in definition.member_instance_ids: progress[member] = {"bond":45,"unlocked_memory_ids":["fixture"]}
		role_counts[id] = {"combo_count":5}; days[id] = [1,2,3]
		var run_state := {"run_metrics_update3":{"duo_deployed_days":days,"duo_role_progress":role_counts}}
		expect(Duo.eligible_memory_event_ids({},run_state,progress,{id:definition}).size()==1,"unlock at 45/1/3/5 "+id)
		for missing in ["bond","unlocked_memory_ids","days","roles"]:
			var p: Dictionary = progress.duplicate(true); var s: Dictionary = run_state.duplicate(true)
			if missing=="bond": p[definition.member_instance_ids[0]].bond = 44
			elif missing=="unlocked_memory_ids": p[definition.member_instance_ids[0]].unlocked_memory_ids = []
			elif missing=="days": s.run_metrics_update3.duo_deployed_days[id] = [1,2]
			else: s.run_metrics_update3.duo_role_progress[id].combo_count = 4
			expect(Duo.eligible_memory_event_ids({},s,p,{id:definition}).is_empty(),"incomplete "+missing+" blocks "+id)
		expect(not battle.duos.activate(id),"uncharged cannot activate "+id)
		var source: Dictionary = definition.gauge_sources[0]
		var gain: int = game._record_update3_duo_link_action(source.member_instance_id,source.source_id,source.threshold,"same")
		expect(gain>0 and game._record_update3_duo_link_action(source.member_instance_id,source.source_id,source.threshold,"same")==0,"gauge token dedup "+id)
		charge(id)
		expect(game.update3_active_run.duo_link_states[id].charge==100,"gauge capped 100 "+id)
		game.combat_paused = true
		expect(not battle.duos.activate(id),"pause blocks activation "+id)
		game.combat_paused = false
		for unit in members: unit.hp -= 20
		expect(battle.duos.activate(id),"actual activation "+id)
		var effect: Dictionary = game.get_meta("v130r_last_duo_effect",{})
		expect(effect.get("hits",0)>0 or effect.get("shield",0)>0,"actual target effect "+id)
		var victim: Node = game.enemy_units[-1]
		if definition.effect.has("damage"): expect(victim.hp<victim.max_hp,"actual HP loss "+id)
		if definition.effect.has("root_seconds"): expect(victim.root_timer>0,"actual root timer "+id)
		if definition.effect.has("slow_seconds"): expect(victim.slow_timer>0,"actual slow timer "+id)
		if definition.effect.has("mark_seconds"): expect(victim.duo_mark_timer>0,"actual mark timer "+id)
		if definition.effect.has("shield"): expect(members[0].duo_barrier>0,"actual barrier "+id)
		if definition.effect.has("recover_fraction"): expect(victim.get_meta("stolen_gold")==20,"actual recovered gold "+id)
		if definition.effect.has("heal"): expect(effect.heal>0,"actual effective healing "+id)
		expect(not battle.duos.activate(id),"second use blocked "+id)
		link_evidence.append({"id":id,"effect":effect.duplicate(true),"state":game.update3_active_run.duo_link_states[id].duplicate(true)})
		var inactive: Dictionary = Duo.begin_battle({"equipped_duo_links":[id]},[definition.member_instance_ids[0]],DataRegistry.update3_duo_links)
		expect(not inactive.duo_link_states[id].active,"missing member disables "+id)
		var downed: Dictionary = Duo.member_downed(game.update3_active_run,definition.member_instance_ids[0],DataRegistry.update3_duo_links)
		expect(not downed.duo_link_states[id].active,"downed member disables "+id)
	var speaker: Node = game.monster_units[0]
	game.v130r_story.reset_battle()
	for event in ["deployed","engagement_started","skill_used","hp_below_30","ally_downed","victory","hungry"]:
		expect(game.v130r_story.bark(game,speaker,event),"bark trigger "+event)
		expect(not game.v130r_story.bark(game,speaker,event),"same bark cooldown "+event)
	game.v130r_story.bark_clock += 26
	expect(game.v130r_story.bark(game,speaker,"deployed"),"bark eligible after cooldown")
	var child_count: int = game.ui_layer.get_child_count()
	game.v130r_story.show_victory(game)
	var victory_panel: Control = game.ui_layer.get_children()[-1]
	expect(game.ui_layer.get_child_count()==child_count+1 and victory_panel.mouse_filter==Control.MOUSE_FILTER_IGNORE,"victory bark is visible without owning input")
	await get_tree().create_timer(3.7).timeout
	expect(not is_instance_valid(victory_panel),"victory bark expires instead of covering result controls")
	for locale in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		var joined: Array = game.v130r_story.join_entries("river_frog")
		expect(joined.size()==8,"full join dialogue "+locale)
		expect(joined[1].text!="연못 반환 요구서 37번째인데요." if locale!="ko" else joined[1].text=="연못 반환 요구서 37번째인데요.","localized join body "+locale)
	LanguageSettings.set_locale("ko",false)
	game.monster_roster.erase("under_bed_shadow")
	var owned_species: Array = game.get_meta("v130r_owned_species",[])
	owned_species.erase("under_bed_shadow"); game.set_meta("v130r_owned_species",owned_species)
	expect(not game.v130r_story.allowed(game,{"requires_owned_species_ids":["under_bed_shadow"]}),"unowned speaker skipped")
	expect(not game.v130r_story.allowed(game,{"requires_unlocked_memory_ids":["not_unlocked"]}),"locked memory skipped")
	expect(DataRegistry.waves.day_29.is_empty(),"DAY29 no battle waves")
	GameState.day = 29
	expect(not game.v130r_story.first_battle(game,["river_frog"]),"DAY29 first battle dialogue blocked")
	battle.release(); battle = null
	game.current_screen = Constants.SCREEN_MANAGEMENT; GameState.day = 6
	game.monster_roster = {"river_frog":{"level":1,"exp":0,"unlocked_memory_ids":[]}}
	game.set_meta("v130r_owned_species",["river_frog"])
	view.monster_ui.show_info("mon_v130r_pongdang")
	expect(view.monster_ui.detail.has_node("V130RBondMemoryButton") and view.monster_ui.detail.has_node("V130RDuoLoadoutButton"),"management has memory and duo entry buttons")
	# Merely inspecting an unowned species must not satisfy story ownership.
	game.monster_roster["under_bed_shadow"] = {"level":1,"exp":0}
	expect(not game.v130r_story.allowed(game,{"requires_owned_species_ids":["under_bed_shadow"]}),"preview roster entry is not actual ownership")
	game.update3_profile = {}; game.campaign_cycle_index = 1
	var anchor := ""
	for scene in game.v130r_story.scenes("day_overlays"):
		if scene.day==6: anchor = scene.insert_after_scene_id
	game.story_director.seen_scene_ids.erase(anchor)
	expect(game.v130r_story.management(game),"original management anchor starts before overlay")
	expect(game.story_director.current_scene_id==anchor,"authored insertion anchor is respected")
	game.story_director.cancel_active_scene(); game.current_screen = Constants.SCREEN_MANAGEMENT
	game.story_director.seen_scene_ids.append(anchor)
	expect(game.v130r_story.management(game),"actual management overlay enters existing dialogue UI")
	expect(not game.onboarding_dialogue_queue.is_empty(),"management supplies real dialogue entries")
	var queued_ids: Array = []
	for line in game.onboarding_dialogue_queue:
		if not queued_ids.has(line.v130r_scene_id): queued_ids.append(line.v130r_scene_id)
	game.v130r_story.restore_pending(game); game.v130r_story.finish(game)
	for id in queued_ids: expect(game.story_director.seen_scene_ids.has(id),"completed story uses existing saved read IDs")
	game.onboarding_dialogue_queue.clear(); game.current_screen = Constants.SCREEN_MANAGEMENT
	game.monster_roster.river_frog["bond"] = 45; game.monster_roster.river_frog.unlocked_memory_ids = ["fixture"]
	game.monster_roster["spider_tailor"] = {"level":1,"exp":0,"bond":45,"unlocked_memory_ids":["fixture"]}
	game.set_meta("v130r_owned_species",["river_frog","spider_tailor"])
	game.update3_active_run = {"run_metrics_update3":{"duo_deployed_days":{"planned_web_bridge":[1,2,3]},"duo_role_progress":{"planned_web_bridge":{"combo_count":5}}}}
	expect(game.v130r_story.management(game),"eligible duo opens management unlock scene")
	expect(game.update3_profile.duo_links.unlocked.has("planned_web_bridge"),"management performs real existing-service unlock")
	expect(game.update3_active_run.run_metrics_update3.new_duo_memories_this_run==1,"unlock metric once")
	game.v130r_story.finish(game); game.onboarding_dialogue_queue.clear(); game.current_screen = Constants.SCREEN_MANAGEMENT
	game.v130r_story.management(game)
	expect(game.update3_active_run.run_metrics_update3.new_duo_memories_this_run==1,"reopening cannot duplicate unlock metric")
	save_json(S11+"duo_effect_checks.json",link_evidence)

func shot(name: String) -> void:
	await get_tree().process_frame; await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(S11+name+".png")

func leave_dialogue() -> void:
	game.onboarding_dialogue_index = game.onboarding_dialogue_queue.size()-1
	game._onboarding_advance_dialogue()
	await get_tree().process_frame
	view = game.ui_layer.get_node("ApprovedMapManagement")
	view.set_physics_process(false)

func capture_story() -> void:
	# Same entries/presenter as recruitment; fixture does not grant ownership.
	for locale in ["ko","en"]:
		LanguageSettings.set_locale(locale,false)
		game.v130r_story.start(game,game.v130r_story.join_entries("river_frog"),[])
		game._onboarding_advance_dialogue()
		await shot("join_scene_"+locale)
		await leave_dialogue()
	LanguageSettings.set_locale("ko",false)
	for scene in game.v130r_story.scenes("day_overlays"):
		if scene.day==20:
			var lines: Array = []
			for block in scene.segments: lines.append_array(game.v130r_story.entries(scene,block))
			game.v130r_story.start(game,lines,[]); await shot("day_overlay_d20"); await leave_dialogue(); break
	for scene in game.v130r_story.scenes("bond_scenes"):
		if scene.monster_id=="under_bed_shadow" and scene.memory_stage==3:
			game.v130r_story.start(game,game.v130r_story.entries(scene),[])
			game._onboarding_advance_dialogue(); await shot("bond_scene"); await leave_dialogue(); break
	base_members = Members.roster(); prepare(20,"recommended"); start()
	var members := duo_fixture("planned_web_bridge")
	view.battle = battle
	view.monster_ui.set_mode("battle"); view.monster_ui.unit_layer.hide()
	view.battle_ui = load("res://scripts/ui/ApprovedBattleUI.gd").new(); view.add_child(view.battle_ui); view.battle_ui.setup(view,battle)
	view.set_camera((members[0].position+members[1].position)*.5,1.0)
	for unit in members: unit.refresh_depth_slot()
	game.v130r_story.reset_battle(); game.v130r_story.bark(game,members[0],"engagement_started")
	game.v130r_story.tick_barks(game,.01); await shot("bark_battle")
	game.v130r_story.clear_bark()
	charge("planned_web_bridge"); game.combat_paused = false
	expect(battle.duos.activate("planned_web_bridge"),"capture actual new duo activation")
	game.combat_paused = true
	await shot("duo_new")
	battle.release(); battle = null; view.battle = null

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(S11))
	config = {"name":"step11","fast_cosmetics":true}
	var run_mode := "direct"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--story-mode="): run_mode = arg.get_slice("=",1)
	await boot(); base_members = Members.roster(); game.selected_contract_ids.assign(["spore_healer","stone_sentinel"])
	if run_mode=="direct": await direct_story()
	elif run_mode=="capture": await capture_story()
	else:
		for selected_condition in ["off","on"]:
			condition = selected_condition; config.name = "step11_"+condition
			var path: String = S11+condition+"_rows.json"
			rows = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else []
			for day in [20,24,27,30]:
				for layout_mode in ["recommended","anchor_cluster","final_line","first_line"]:
					for index in range(10):
						if rows.any(func(r): return r.day==day and r.layout==layout_mode and r.trial==index): continue
						rows.append(await trial(day,index,layout_mode)); save_json(path,rows)
	await stop()
	save_json(S11+run_mode+"_checks.json",{"checks":checks,"failures":failures})
	print("STEP11_DONE ",run_mode," checks=",checks," failures=",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
