extends RefCounted
static func prepare(game: Node) -> void:
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.story_feature_enabled = false
	game.campaign_cycle_index = 2
	GameState.day = 16
	game.castle_art_stage = "stage_04_citadel"
	for value in DataRegistry.monster_instances.values():
		var species := str(value.get("species_id",""))
		if species != "" and not DataRegistry.monster(species).is_empty() and not game.monster_roster.has(species):
			game.monster_roster[species] = {"level":1,"exp":0,"bond":0,"room":"barracks"}
	game.update4_active_run = {"campaign_mode_id":"council_season","council_season":{"selected_regions":DataRegistry.update4_regions.keys().slice(0,2)}}
	game.update4_profile["unlocked_outpost_type_ids"] = DataRegistry.update4_outpost_types.keys()
	var hp := int(DataRegistry.update4_outpost_types.outpost_supply_burrow.base_hp)
	game.update4_active_run["outpost"] = {"type_id":"outpost_supply_burrow","level":1,"max_hp":hp,"current_hp":hp,"assigned_monster_ids":[]}
	game.campaign_profile["ending_archive"] = {}
	var ids: Array = game._ending_catalog_ids()
	for id in ids:
		game.campaign_profile.ending_archive[id] = {"first_seen_cycle":1,"last_seen_cycle":2,"seen_count":2}
	game.selected_contract_ids.assign(["spore_healer","stone_sentinel"])
	game.deployed_instance_ids.assign(["mon_contract_mori","mon_contract_dolkong","mon_core_pudding"])
