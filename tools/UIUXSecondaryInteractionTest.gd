extends "res://tools/UIUXU4InteractionTest.gd"
const Fixture = preload("res://tools/UIUXSecondaryFixture.gd")
func capture(id: String) -> void:
	await settle()
	var path := "res://tmp/uiux_secondary/interaction/" + id + ".png"
	expect(get_viewport().get_texture().get_image().save_png(path) == OK,id+" capture saved")
	captures.append(path)
func economy() -> Array:
	return [GameState.gold,GameState.mana,GameState.food,GameState.infamy,GameState.gold_income,GameState.mana_income,GameState.food_income,GameState.demon_lord_hp,GameState.demon_lord_max_hp]
func focus_choice(id: String) -> void:
	var b := node("CampaignChoice_"+id) as Button
	expect(b != null,id+" exists in full list")
	if b == null: return
	b.grab_focus()
	await settle()
	expect((node("CampaignChoiceScroll") as Control).get_global_rect().encloses(b.get_global_rect()),id+" focus scrolls choice into view")
	await key(KEY_ENTER)
func open_screen(id: String) -> void:
	game._set_screen(id)
	await settle()
	check_copy(game.ui_layer)
func outpost_member(id: String) -> void:
	var b := node("OutpostAssignButton_"+id) as Button
	expect(b != null,id+" exists in outpost roster")
	if b == null: return
	b.grab_focus()
	await settle()
	expect((node("OutpostRosterScroll") as Control).get_global_rect().encloses(b.get_global_rect()),id+" focus scrolls member into view")
	await key(KEY_ENTER)
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp/uiux_secondary/interaction")
	game = Game.instantiate()
	add_child(game)
	await settle()
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale_value in [0.9,1.0,1.15]:
			UISettings.text_scale = scale_value
			Fixture.prepare(game)
			var tag := "%dx%d_%d" % [resolution.x,resolution.y,roundi(scale_value*100)]
			await test_cycle(tag)
			await test_archive(tag)
			await test_contracts(tag)
			await test_outpost(tag)
	game.queue_free()
	await settle(3)
	var file := FileAccess.open("res://tmp/uiux_secondary/interaction/results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions":count,"failed":failed,"captures":captures},"\t"))
	file.close()
	print("UIUX_SECONDARY_INTERACTION_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS",count])
	get_tree().quit(1 if failed else 0)

func test_cycle(tag: String) -> void:
	for field in ["active_doctrine_id","active_decree_id","active_challenge_seal_id"]:
		game.campaign_profile[field] = ""
	for field in ["doctrine_history","decree_history","challenge_seal_history"]:
		game.campaign_profile[field] = []
	var before := economy()
	var roster: Dictionary = game.monster_roster.duplicate(true)
	await open_screen(C.SCREEN_CYCLE_DOCTRINE)
	expect(node("CampaignConfirmButton").disabled,tag+" new step requires explicit choice")
	var choices: Array = DataRegistry.cycle_doctrine_ids()
	var id := str(choices.back())
	await focus_choice(id)
	expect(economy() == before and game.monster_roster == roster and game.campaign_profile.active_doctrine_id == "",tag+" doctrine preview changes no game state")
	await key(KEY_ESCAPE)
	expect(game.current_screen == C.SCREEN_CYCLE_DOCTRINE and node("CampaignConfirmButton").disabled and economy() == before,tag+" ESC clears preview without skipping mandatory setup")
	await focus_choice(id)
	await capture(tag+"_doctrine_review")
	await click(node("CampaignConfirmButton"))
	expect(game.campaign_profile.active_doctrine_id == id and game.campaign_profile.doctrine_history.size() == 1,tag+" doctrine confirm records once")
	var after := economy()
	await click(node("CampaignConfirmButton"))
	expect(game.current_screen == C.SCREEN_CYCLE_DECREE and game.campaign_profile.active_decree_id == "" and economy() == after,tag+" second confirm click cannot commit new decree")
	game._select_cycle_doctrine(id)
	expect(economy() == after and game.campaign_profile.doctrine_history.size() == 1,tag+" stale doctrine callback cannot duplicate effects")
	id = str(DataRegistry.cycle_decree_ids().back())
	await focus_choice(id)
	check_copy(game.ui_layer)
	await click(node("CampaignConfirmButton"))
	expect(game.campaign_profile.active_decree_id == id and game.campaign_profile.decree_history.size() == 1,tag+" decree applies once")
	await click(node("CampaignConfirmButton"))
	expect(game.current_screen == C.SCREEN_CHALLENGE_SEAL and game.campaign_profile.active_challenge_seal_id == "",tag+" second confirm click cannot commit new seal")
	id = str(DataRegistry.challenge_seal_ids().back())
	await focus_choice(id)
	check_copy(game.ui_layer)
	await click(node("CampaignConfirmButton"))
	expect(game.campaign_profile.active_challenge_seal_id == id and game.campaign_profile.challenge_seal_history.size() == 1 and game.current_screen == C.SCREEN_MANAGEMENT,tag+" seal completes setup once")
	# Existing battle selection must not consume Tab while a menu owns keyboard focus.
	var actor = game._create_unit("slime",DataRegistry.monster("slime"),C.FACTION_MONSTER,"entrance")
	game.monster_units.append(actor)
	game.selected_unit = null
	await open_screen(C.SCREEN_CYCLE_DOCTRINE)
	await key(KEY_TAB)
	expect(game.selected_unit == null,tag+" menu Tab never selects a battle unit")
	game._clear_units()

func test_archive(tag: String) -> void:
	var all_ids: Array = game._ending_catalog_ids()
	var saved: Dictionary = game.campaign_profile.ending_archive.duplicate(true)
	game._set_screen(C.SCREEN_CYCLE_DOCTRINE)
	await open_screen(C.SCREEN_ENDING_ARCHIVE)
	expect(get_viewport().gui_get_focus_owner() == node("CampaignChoice_"+game.secondary_workspace.selected_id),tag+" rapid screen switch focuses only the current live menu")
	expect(game.secondary_workspace.list.get_child_count() == all_ids.size() and all_ids.size() == 23,tag+" all 23 endings are listed")
	await focus_choice(str(all_ids.back()))
	expect(node("EndingDetailArt") != null and node("EndingDetailArt").texture != null,tag+" last discovered ending displays actual art")
	check_copy(game.ui_layer)
	await capture(tag+"_last_ending")
	await key(KEY_ESCAPE)
	expect(game.current_screen == C.SCREEN_TITLE and game.campaign_profile.ending_archive == saved,tag+" archive ESC returns without mutating records")
	game.campaign_profile.ending_archive.erase(all_ids.back())
	await open_screen(C.SCREEN_ENDING_ARCHIVE)
	await focus_choice(str(all_ids.back()))
	expect(node("EndingDetailArt") == null and node("EndingDetailTitle") == null,tag+" undiscovered ending hides image and title")
	game.campaign_profile.ending_archive = saved

func test_contracts(tag: String) -> void:
	game.selected_contract_ids.clear()
	game.contract_board_pending_ids.clear()
	game.campaign_profile["contract_history"] = []
	await open_screen(C.SCREEN_CONTRACT_BOARD)
	expect(game.secondary_workspace.ids.size() == 5,tag+" five contract offers visible")
	var before := economy()
	var roster: Dictionary = game.monster_roster.duplicate(true)
	var actual_mori: Texture2D = game.management_scene.monster_identity_texture("spore_healer")
	expect(actual_mori is AtlasTexture and actual_mori.atlas.resource_path == str(DataRegistry.monster("spore_healer").get("sprite","")),tag+" Mori uses its actual base sprite, never Pudding portrait")
	var ids: Array = game.secondary_workspace.ids.duplicate()
	await focus_choice(str(ids.back()))
	expect(game.selected_contract_ids.is_empty() and game.contract_board_pending_ids.is_empty() and game.monster_roster == roster,tag+" contract detail is read-only")
	await click(node("ContractToggleButton"))
	expect(game.contract_board_pending_ids == [ids.back()] and economy() == before and node("CampaignConfirmButton").disabled,tag+" candidate stays pending without cost")
	await key(KEY_ESCAPE)
	expect(game.contract_board_pending_ids.is_empty() and game.current_screen == C.SCREEN_CONTRACT_BOARD,tag+" candidate ESC clears pending only")
	for id in ids.slice(0,2):
		await focus_choice(str(id))
		await click(node("ContractToggleButton"))
	await focus_choice(str(ids[2]))
	expect(node("ContractToggleButton").disabled and not node("CampaignConfirmButton").disabled,tag+" third candidate blocked with two ready to confirm")
	await capture(tag+"_contracts_review")
	await click(node("CampaignConfirmButton"))
	expect(game.selected_contract_ids == ids.slice(0,2) and game.campaign_profile.contract_history.size() == 1 and economy() == before,tag+" two contracts committed once")
	game._confirm_contract_selection()
	expect(game.campaign_profile.contract_history.size() == 1,tag+" stale contract confirmation ignored")
	Fixture.prepare(game)
	await open_screen(C.SCREEN_CONTRACT_BOARD)
	var all_ids: Array = game.secondary_workspace.ids.duplicate()
	expect(all_ids.size() > 8,tag+" full owned roster exceeds former footer overlap")
	var last := ""
	for value in all_ids:
		if game._contract_owned_instance_ids(true).has(str(value)):
			last = str(value)
	expect(last != "" and all_ids.find(last) >= 8,tag+" a late owned monster is available for actual deployment")
	await focus_choice(last)
	await capture(tag+"_last_contract_member")
	var was_deployed: bool = game.deployed_instance_ids.has(last)
	await click(node("ContractToggleButton"))
	expect(game.deployed_instance_ids.has(last) != was_deployed,tag+" late member toggle immediately changes deployment")
	for value in game.deployed_instance_ids.duplicate():
		await focus_choice(str(value))
		await click(node("ContractToggleButton"))
	expect(game.deployed_instance_ids.is_empty() and node("CampaignConfirmButton").disabled,tag+" zero deployment cannot be completed")
	await key(KEY_ESCAPE)
	expect(game.current_screen == C.SCREEN_CONTRACT_BOARD and game.deployed_instance_ids.is_empty(),tag+" ESC cannot bypass empty roster validation")
	await focus_choice("mon_core_pudding")
	await click(node("ContractToggleButton"))
	await key(KEY_ESCAPE)
	expect(game.current_screen == C.SCREEN_MANAGEMENT and game.deployed_instance_ids == ["mon_core_pudding"],tag+" valid roster ESC completes with immediate changes preserved")
	var deployed: Array = game.deployed_instance_ids.duplicate()
	game._toggle_contract_deployment(last)
	expect(game.deployed_instance_ids == deployed,tag+" stale deployment callback ignored")

func test_outpost(tag: String) -> void:
	Fixture.prepare(game)
	var before := economy()
	await open_screen(C.SCREEN_OUTPOST_MANAGEMENT)
	var screen = node("OutpostManagementScreen")
	var ids: Array = screen.owned_instance_ids.duplicate()
	expect(ids.size() > 7,tag+" outpost full roster exceeds former seven cap")
	var last := str(ids.back())
	await outpost_member(last)
	expect(game.update4_active_run.outpost.assigned_monster_ids == [last] and economy() == before,tag+" last outpost member assigned without cost")
	await capture(tag+"_last_outpost_member")
	await outpost_member(last)
	expect(game.update4_active_run.outpost.assigned_monster_ids.is_empty(),tag+" late assigned member can be released")
	for id in ids.slice(0,3):
		await outpost_member(str(id))
	expect(node("OutpostAssignButton_"+last).disabled and game.update4_active_run.outpost.assigned_monster_ids.size() == 3,tag+" capacity blocks fourth assignment")
	await outpost_member(str(ids[0]))
	await outpost_member(last)
	expect(game.update4_active_run.outpost.assigned_monster_ids.has(last),tag+" released capacity admits late member")
	await click(node("OutpostUpgradeButton"))
	expect(game.update4_active_run.outpost.level == 2 and node("OutpostUpgradeButton").disabled and economy() == before,tag+" level2 upgrade applies once with original no-resource cost")
	await click(node("OutpostUpgradeButton"))
	expect(game.update4_active_run.outpost.level == 2,tag+" repeated upgrade input ignored")
	await key(KEY_ESCAPE)
	expect(game.current_screen == C.SCREEN_MANAGEMENT,tag+" built outpost ESC returns")
	var saved: Dictionary = game.update4_active_run.duplicate(true)
	var empty_ids: Array[String] = []
	game._set_update4_outpost_assignment(empty_ids)
	game._upgrade_update4_outpost()
	game._select_update4_outpost("outpost_watch_nest")
	expect(game.update4_active_run == saved,tag+" outpost callbacks after screen switch ignored")
	game.update4_active_run.outpost = {}
	await open_screen(C.SCREEN_OUTPOST_MANAGEMENT)
	await click(node("OutpostTypeButton_outpost_false_gate"))
	expect(game.update4_active_run.outpost.is_empty() and economy() == before,tag+" outpost type click is preview only")
	await key(KEY_ESCAPE)
	expect(game.current_screen == C.SCREEN_OUTPOST_MANAGEMENT and game.update4_active_run.outpost.is_empty(),tag+" mandatory outpost setup cannot be skipped")
	await capture(tag+"_outpost_build_review")
	await click(node("OutpostBuildButton"))
	expect(game.update4_active_run.outpost.type_id == "outpost_false_gate" and game.update4_active_run.outpost.level == 1 and economy() == before,tag+" explicit build uses existing service once")
	GameState.day = 4
	await open_screen(C.SCREEN_OUTPOST_MANAGEMENT)
	expect(node("OutpostUpgradeButton").disabled,tag+" original day12 upgrade gate preserved")
