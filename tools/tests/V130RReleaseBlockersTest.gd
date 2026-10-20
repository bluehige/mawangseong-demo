extends "res://tools/tests/V130SavePlotTest.gd"
## Real disk round trips in a disposable APPDATA profile, including every species.
const V1Migrator = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const BASE := "user://release_blockers/"

func same(a, b) -> bool:
	# JSON reads integer-valued numbers as floats; compare their JSON values.
	return JSON.stringify(JSON.parse_string(JSON.stringify(a)),"",true)==JSON.stringify(JSON.parse_string(JSON.stringify(b)),"",true)

func run() -> void:
	expect(OS.get_user_data_dir().replace("\\","/").contains("v130r_release_blockers"),"isolated profile required")
	if not failures.is_empty(): get_tree().quit(1); return
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	ProjectSettings.set_setting("debug/start_flow14",true)
	await spawn()
	game._onboarding_start_new_game()
	game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
	use_paths(BASE+"all/")
	game._set_screen("management",false)
	GameState.day = 2
	GameState.player_name = "ReleaseTest"
	var roster := {}
	var outcomes := {}
	for instance_id in DataRegistry.monster_instances:
		var template: Dictionary = DataRegistry.monster_instances[instance_id]
		var species: String = template.species_id
		var specs: Array = game._specializations_for_monster(species)
		var promos: Array = game._evolution_rules_for_monster(species)
		roster[species] = {"level":7,"exp":13,"bond":65,"bond_rank":game._monster_bond_rank(65),"unlocked_memory_ids":["bond_"+species+"_rank_1"],"room":"recovery","defense_zone_id":"zone_a_front","assigned_defense_zone_id":"zone_a_front","specialization_id":str(specs[0].id) if not specs.is_empty() else "","promotion_id":str(promos[0].id) if not promos.is_empty() else ""}
		outcomes[species] = {"hp":17,"max_hp":180,"down":false}
		var input := {"slime":roster.get("slime",{}),"goblin":roster.get("goblin",{}),"imp":roster.get("imp",{})}
		input[species] = roster[species]
		var migrated := V1Migrator._migrate_monsters(input,DataRegistry.monster_instances)
		expect(migrated.ok,"v1 accepts "+species)
		if migrated.ok:
			expect(migrated.monsters.has(instance_id),"stable instance ID "+species)
			for key in roster[species]: expect(same(migrated.monsters[instance_id][key],roster[species][key]),"v1 preserves "+species+" "+key)
	expect(roster.size()==24,"complete 24-species catalog")
	expect(V1Migrator.SPECIES_TO_INSTANCE.size()==24,"complete v1 conversion table")
	game.monster_roster = roster.duplicate(true)
	game.deployed_instance_ids.assign(DataRegistry.monster_instances.keys())
	game.reserve_instance_ids.clear()
	game.result_summary = {"win":true,"metrics":{"monster_outcomes":outcomes}}
	GameState.food=7
	GameState.food_state={"version":1,"hungry":["rat_union","slime"],"owned":roster.keys(),"contracts":["spore_healer"],"last_day":1,"last":{"shortfall":4,"day":1}}
	var food_before := GameState.food_state.duplicate(true)
	var grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
	grade.reset_campaign_map(game)
	game._schedule_campaign_autosave("management")
	var saved: bool = game._flush_campaign_autosave()
	expect(saved,"24-species v1-v6 bundle writes: "+game.campaign_save_error)
	if saved:
		var run_id := str(Time.get_unix_time_from_system()).replace(".","_")
		for version in range(1,7):
			await release(); await spawn()
			var folder := BASE+run_id+"/version_%d/" % version
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
			var source := BASE+"all/campaign_save_v%d.json" % version
			var target := folder+"campaign_save_v%d.json" % version
			expect(DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(target))==OK,"disk copy v%d" % version)
			use_paths(folder)
			expect(game.campaign_save_status=="valid","inspect v%d: %s" % [version,game.campaign_save_error])
			game._continue_campaign_save(); await settle()
			expect(game.deployed_instance_ids.size()==24,"v%d preserves free-layout deployment above legacy cap" % version)
			write_json("res://tmp/v130r_release_blockers/unit_v%d.json" % version,{"roster":game.monster_roster,"food":GameState.food,"food_state":GameState.food_state,"result":game.result_summary})
			for species in roster:
				for key in roster[species]:
					expect(same(game.monster_roster.get(species,{}).get(key),roster[species][key]),"disk v%d %s %s" % [version,species,key])
				expect(game.management_scene.result_portrait_emotion(species)=="wounded","v%d injury %s" % [version,species])
			expect(GameState.food==7 and same(GameState.food_state,food_before),"v%d food and hunger preserved" % version)
			expect(same(game.result_summary.get("metrics",{}).get("monster_outcomes",{}),outcomes),"v%d injury outcomes preserved" % version)
			expect(game.current_screen=="management" and GameState.day==2,"v%d checkpoint" % version)
	await release()
	write_json("res://tmp/v130r_release_blockers/unit_checks.json",{"checks":checks,"failures":failures,"species":roster.keys()})
	print("RELEASE_BLOCKERS_UNIT ",checks," checks; failures=",failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
