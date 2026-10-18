extends RefCounted
## Existing conditions win over fallback DAYs. Addition follows the last dialogue.
const Grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const FALLBACK := {"spore_healer":7,"stone_sentinel":9,"war_drummer":12,"moon_tracker":16,"mimic_porter":17}
const CORE := ["slime","goblin","imp","kobold_scout"]
const LINES := {"spore_healer":"map.anyone_hurt_a_bowl_of_food_will_put_some_spring_in_these_spores","stone_sentinel":"map.leave_the_entrance_to_me_i_ll_hold_my_post_even_at_mealtime","war_drummer":"map.food_first_drums_second_an_empty_stomach_throws_off_my_beat","moon_tracker":"map.i_ll_watch_where_the_moonlight_falls_put_my_name_in_the_food_ledger_to","mimic_porter":"map.don_t_put_real_food_inside_me_just_leave_the_fake_treasure_to_me"}

static func condition(species: String) -> String:
	if DataRegistry.update2_contracts.has(species): return LanguageSettings.text("map.choose_two_companions_through_cycle_contracts")
	if DataRegistry.update3_monster_extensions.has(species): return LanguageSettings.text("map.clear_the_required_front_or_earn_its_ending_reward")
	if species in ["spider_tailor","bat_courier"]: return LanguageSettings.text("map.demon_council_cycle")
	return "DAY %d" % int(FALLBACK.get(species,1))

static func eligible(game: Node, members: Dictionary, day: int) -> Array:
	var ids: Array = []
	var ending_codes: Array = game.campaign_profile.get("ending_catalog_codes",{}).values()
	for ending_id in game.update3_profile.get("update3_endings_seen",[]):
		var code: String = str(DataRegistry.update3_endings.get(ending_id,{}).get("catalog_code",""))
		if code!="" and code not in ending_codes: ending_codes.append(code)
	for id in members:
		var species: String = members[id].species_id
		var allowed: bool = species in CORE
		if DataRegistry.update2_contracts.has(species):
			allowed = species in game.selected_contract_ids
		elif DataRegistry.update3_monster_extensions.has(species):
			var rule: Dictionary = DataRegistry.update3_monster_extensions[species].get("unlock_condition",{})
			var front: String = str(rule.get("front_id",""))
			var ending: String = str(rule.get("alternate_ending_id",""))
			allowed = id in game.update3_profile.get("guaranteed_contract_instance_ids",[]) or (front!="" and int(game.update3_profile.get("fronts",{}).get("clear_counts",{}).get(front,0))>=1) or (ending!="" and ending in ending_codes)
		elif species in ["spider_tailor","bat_courier"]:
			allowed = game._update4_council_mode_active()
		elif DataRegistry.monster(species).has("join_day"): allowed = day>=int(DataRegistry.monster(species).join_day)
		elif FALLBACK.has(species): allowed = day>=int(FALLBACK[species])
		if allowed: ids.append(id)
	return ids

static func begin(game: Node, ids: Array) -> void:
	var members := Members.roster()
	var session := Grade.load_session(game)
	var eligible_ids := eligible(game,members,int(session.layout.day))
	var pending: Array = []; var entries: Array = []
	for id in ids:
		if id not in eligible_ids or id in session.layout.get("food_state",{}).get("owned",[]) or not members.has(id): continue
		var row: Dictionary = members[id]
		if row.species_id in CORE: continue
		pending.append(id)
		var full_entries: Array = game.v130r_story.join_entries(row.species_id)
		if not full_entries.is_empty():
			entries.append_array(full_entries)
			continue
		var scenes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/v130r/join_scenes.json"))
		var scene: Dictionary = scenes.get(str(row.stats.get("join_scene_id","")),{})
		if not scene.is_empty():
			for index in range(scene.lines.size()):
				var text: String = scene.lines[index]
				var close := text.find("]:")
				var heading := text.substr(1,close-1).split("|")
				var emotion: String = {"기쁨":"happy","단호":"determined","결의":"determined"}.get(heading[1],"base")
				entries.append({"speaker":scene.speaker_character_ids[index],"speaker_name":heading[0],"emotion":emotion,"text":text.substr(close+2).strip_edges(),"dialogue_header":LanguageSettings.text("map.companion_joins")+row.display_name})
		else:
			entries.append({"speaker":row.character_id,"speaker_name":row.display_name,"emotion":"base","text":LanguageSettings.text(LINES.get(row.species_id,"map.supplies_and_defense_i_ll_help_with_both_glad_to_be_here")),"dialogue_header":LanguageSettings.text("map.companion_joins")+row.display_name})
	if pending.is_empty(): game._set_screen(Constants.SCREEN_MANAGEMENT); return
	game.set_meta("approved_join_pending",pending)
	game._onboarding_begin_dialogue(entries,Constants.SCREEN_MANAGEMENT,"v130r_join")

static func finish(game: Node) -> void:
	var session := Grade.load_session(game); var members := Members.roster()
	var state := GameState.Food.migrate(session.layout.get("food_state",{}),int(session.layout.day))
	state.contracts = game.selected_contract_ids.duplicate()
	for id in game.get_meta("approved_join_pending",[]):
		if not members.has(id) or id in state.owned: continue
		state.owned.append(id)
		if not bool(game.get_meta("ach_dialogue_skipped",false)): AchievementService.record("dialogue_completed",{"join_scene_seen":1,"join_species":str(members[id].species_id)})
		var species: String = members[id].species_id
		if DataRegistry.update2_contracts.has(species): game._add_contract_monster_to_roster(species)
		else: game._add_update3_monster_to_roster(species,id)
	session.layout.food_state = state
	GameState.food_state = state.duplicate(true)
	game.remove_meta("approved_join_pending")
	Grade.stash(game,session.layout,session.defenders)
	Members.save_copy(session.layout,session.defenders,Grade.save_path())
	game._set_screen(Constants.SCREEN_MANAGEMENT)
