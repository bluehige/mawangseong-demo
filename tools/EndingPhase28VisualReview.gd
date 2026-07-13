extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""
var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://tmp/update3_phase28")
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game._debug_skip_onboarding()
	_prepare_common()
	_prepare_e15()
	game._set_screen(Constants.SCREEN_ENDING)
	await _capture(Vector2i(1920, 1080), "ending_e15_1920x1080.png", "ending_linked_corridors")
	_prepare_common()
	_prepare_e16()
	game._set_screen(Constants.SCREEN_ENDING)
	await _capture(Vector2i(1366, 768), "ending_e16_1366x768.png", "ending_three_front_armistice")
	game.update3_profile = FrontServiceScript.apply_ending_rewards(game.update3_profile, {}, "ending_three_front_armistice", DataRegistry.update3_endings)
	game._set_screen(Constants.SCREEN_FRONT_SELECTION)
	await _capture_screen(Vector2i(1920, 1080), "front_rotation_unlocked_1920x1080.png")
	game._set_screen(Constants.SCREEN_CHRONICLE)
	await _capture_screen(Vector2i(1366, 768), "chronicle_nameplate_1366x768.png")
	print("ENDING_PHASE28_VISUAL_REVIEW: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _prepare_common() -> void:
	GameState.day = 30
	GameState.gold = 500
	GameState.infamy = 0
	GameState.demon_lord_max_hp = 1000
	GameState.demon_lord_hp = 900
	game.campaign_cycle_index = 5
	game.campaign_completed = true
	game.campaign_final_battle_outcome = "victory"
	game.update3_profile = FrontServiceScript.default_update3_profile()
	game.update3_active_run = FrontServiceScript.default_legacy_active_run(5)
	game.update3_active_run["update3_enabled"] = true
	game.update3_active_run["front_selection_completed"] = true
	game.update3_active_run["duo_link_loadout_confirmed"] = true
	game._reset_run_metrics()


func _prepare_e15() -> void:
	game.update3_active_run["front_id"] = FrontServiceScript.HERO_FRONT_ID
	var link_ids := ["link_spore_jelly_shelter", "link_stone_march", "link_false_beacon_vault"]
	game.update3_active_run["equipped_duo_links"] = [link_ids[0], link_ids[1]]
	game.update3_active_run["duo_link_states"] = {link_ids[0]: {"downed_members": []}, link_ids[1]: {"downed_members": []}}
	var contribution_by_species: Dictionary = {}
	for link_id in link_ids:
		for member_id_value in DataRegistry.update3_duo_links.get(link_id, {}).get("member_instance_ids", []):
			var species_id := str(DataRegistry.monster_instances.get(str(member_id_value), {}).get("species_id", ""))
			if species_id == "":
				continue
			game.monster_roster[species_id] = {"bond": 72}
			contribution_by_species[species_id] = 160
	game.update3_active_run["run_metrics_update3"] = {
		"link_skills_used_campaign": link_ids,
		"link_skills_used_day30": [link_ids[0]],
		"campaign_monster_contribution": 1000,
		"campaign_monster_contribution_by_species": contribution_by_species,
		"heart_chamber_disable_count": 0
	}


func _prepare_e16() -> void:
	game.update3_active_run["front_id"] = FrontServiceScript.HERO_FRONT_ID
	game.update3_active_run["run_metrics_update3"] = {"campaign_treasure_losses": 1, "heart_chamber_disable_count": 0, "campaign_abandonment_count": 0}
	game.update3_profile["fronts"]["clear_counts"] = {"front_hero_oath": 1, "front_holy_purification": 1, "front_guild_repossession": 1}
	game.update3_profile["rival_relations"] = {"leon": 70, "selen": 70, "roman": 70}
	game.update3_profile["update3_endings_seen"] = ["ending_holy_open_gate", "ending_off_ledger_independence"]
	game.run_metrics_tracker.set_value("decision.day29", "grand_armistice_request")


func _capture(size: Vector2i, file_name: String, expected_ending_id: String) -> void:
	await _capture_screen(size, file_name)
	if game.resolved_campaign_ending_id != expected_ending_id:
		failed = true
		push_error("예상 엔딩 %s 대신 %s가 표시됐습니다." % [expected_ending_id, game.resolved_campaign_ending_id])


func _capture_screen(size: Vector2i, file_name: String) -> void:
	DisplayServer.window_set_size(size)
	await _settle(10)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or absi(image.get_width() - size.x) > 1 or absi(image.get_height() - size.y) > 1:
		failed = true
		push_error("예상 해상도 %s 캡처 실패" % size)
		return
	image.convert(Image.FORMAT_RGB8)
	if image.save_png(output_dir.path_join(file_name)) != OK:
		failed = true
		push_error("캡처 저장 실패: %s" % file_name)


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame
