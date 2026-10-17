extends RefCounted
const Cycle = preload("res://scripts/systems/legacy/NewCycleService.gd")
const SEALS := {"seal_no_throne_damage":"no_throne_damage","seal_no_monster_down":"no_monster_down","seal_mana_limit":"low_mana","seal_no_facility_disable":"no_facility_disable","seal_contract_vanguard":"contract_vanguard","seal_adaptive_rival":"adaptive_rival"}

static func collection(service: Node, roster: Dictionary, owned: Array, memories: Array, duos: Array, specs: Dictionary) -> void:
	var species: Array = []
	for id in owned:
		var key := str(DataRegistry.monster_instances.get(id,{}).get("species_id",id))
		if not species.has(key): species.append(key)
	owned = species
	for id in owned: service.count("STAT_ROSTER",1,str(id))
	for id in memories:
		if service.catalog.memory_progress_definition.ids.has(id): service.count("STAT_MEMORIES",1,str(id))
	for id in duos: service.count("STAT_DUOS",1,str(id))
	for id in specs:
		if str(specs[id]) != "": service.count("STAT_SPECS",1,str(DataRegistry.monster_instances.get(id,{}).get("species_id",id)))
	var level := 0
	for id in owned:
		var row: Dictionary = roster.get(id,{})
		level = maxi(level,int(row.get("level",1)))
		for memory in row.get("unlocked_memory_ids",[]):
			if service.catalog.memory_progress_definition.ids.has(memory): service.count("STAT_MEMORIES",1,str(memory))
		if str(row.get("specialization_id","")) != "": service.count("STAT_SPECS",1,str(id))
	service.record("collection",{"monster_level":level,"memories":int(service.profile.stats.get("STAT_MEMORIES",0)),"duos":int(service.profile.stats.get("STAT_DUOS",0)),"specs":int(service.profile.stats.get("STAT_SPECS",0))})

static func profile_records(service: Node, profile: Dictionary) -> void:
	var codes: Dictionary = Cycle.ENDING_CATALOG_CODES.duplicate()
	for row in service.catalog.achievements:
		if str(row.api_name).begins_with("ACH_END4_"):
			var id: String = row.trigger.trim_prefix("ending==")
			var index: int = ["ending_council_seat","ending_two_floors_one_throne","ending_minion_wears_the_crown","ending_outpost_becomes_home","ending_three_rivals_cosign","ending_council_dissolved"].find(id)
			if index >= 0: codes[id] = "E%d" % (17+index)
	var seen: Array = profile.get("ending_archive",{}).keys()
	seen.append_array(profile.get("update3_endings_seen",[])); seen.append_array(profile.get("update4_endings_seen",[]))
	seen.append_array(profile.get("ending_catalog_codes",{}).values())
	for ending in codes:
		if seen.has(ending) or seen.has(codes[ending]): service.record("ending",{"ending":ending})
	for entry in profile.get("challenge_seal_history",[]):
		if entry is Dictionary and bool(entry.get("completed",false)):
			var raw := str(entry.get("seal_id",""))
			service.record("seal_cleared",{"seal":SEALS.get(raw,raw.trim_prefix("seal_"))})
	for crown in profile.get("crown_evolution",{}).get("forms_unlocked",[]): service.record("crown_evolved",{"crown":crown})
	for front in profile.get("fronts",{}).get("clear_counts",{}):
		if int(profile.fronts.clear_counts[front]) > 0: service.record("front_cleared",{"front":front})

static func apply(service: Node, payload: Dictionary, update4: Dictionary = {}) -> void:
	if not payload.has("achievements"):
		service.run = {"defeats":0,"hunger_days":0,"complete_history":false,"zero_food":false}
	service.restore_snapshot(payload.get("achievements",{}))
	var world: Dictionary = payload.get("world",{})
	var roster: Dictionary = world.get("monster_roster",{})
	var game: Dictionary = payload.get("game_state",{})
	var legacy: Dictionary = payload.get("legacy_expansion",{})
	var profile: Dictionary = legacy.get("profile",{})
	var third: Dictionary = payload.get("update3",{}).get("profile",{})
	var layout: Dictionary = payload.get("onboarding",{}).get("start_flow",{}).get("map",{}).get("layout",{})
	var owned: Array = game.get("food_state",{}).get("owned",[])
	# Legacy rosters contain actual members. New rosters may include locked definitions;
	# prefer their saved owned list whenever it exists.
	if owned.is_empty(): owned = roster.keys()
	var memories: Array = profile.get("unlocked_memory_ids",[]).duplicate()
	memories.append_array(third.get("unlocked_memory_ids",[])); memories.append_array(update4.get("unlocked_memory_ids",[]))
	var duos: Array = third.get("duo_links",{}).get("unlocked",[]).duplicate()
	duos.append_array(update4.get("duo_links",{}).get("unlocked",[]))
	collection(service,roster,owned,memories,duos,layout.get("specializations",{}))
	for data in [profile,third,update4]: profile_records(service,data)
	var ending := str(legacy.get("resolved_ending_id",""))
	if bool(payload.get("campaign",{}).get("completed",false)):
		service.record("campaign_complete",{"completed":true})
		if ending != "": service.record("ending",{"ending":ending})
	var stage := str(world.get("castle_art_stage","stage_01_cave"))
	service.record("snapshot",{"castle_stage":int(layout.get("stage",{"stage_01_cave":1,"stage_02_castle":2,"stage_03_keep":3,"stage_04_citadel":4}.get(stage,1))),"day_reached":int(game.get("day",1))})
	# Old seen_scene_ids also include skips. They are not proof of reading a secret.
	service.persist()

static func observe(service: Node, game: Node) -> void:
	var session: Dictionary = game.get_meta("approved_grade_progression",{})
	var layout: Dictionary = session.get("layout",{})
	var owned: Array = GameState.food_state.get("owned",[])
	if owned.is_empty():
		for id in game.monster_roster:
			if game._monster_available_for_defense(str(id)): owned.append(id)
	var memories: Array = game.campaign_profile.get("unlocked_memory_ids",[]).duplicate()
	memories.append_array(game.update3_profile.get("unlocked_memory_ids",[]))
	memories.append_array(game.update4_profile.get("unlocked_memory_ids",[]))
	collection(service,game.monster_roster,owned,memories,game.update3_profile.get("duo_links",{}).get("unlocked",[]),layout.get("specializations",{}))
	for profile in [game.campaign_profile,game.update3_profile,game.update4_profile]: profile_records(service,profile)
	if game.campaign_completed:
		var facts: Dictionary = service.run.duplicate()
		facts.completed = true; service.record("campaign_complete",facts)
		if game.resolved_campaign_ending_id != "": service.record("ending",{"ending":game.resolved_campaign_ending_id})
	service.record("snapshot",{"castle_stage":int(layout.get("stage",game.castle_stage_index() if game.has_method("castle_stage_index") else 1)),"day_reached":GameState.day})
