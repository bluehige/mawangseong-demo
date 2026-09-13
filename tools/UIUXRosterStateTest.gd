extends "res://tools/UIUXU4InteractionTest.gd"
const Fixture = preload("res://tools/UIUXSecondaryFixture.gd")
var phase := "after"
var output := ""
var owned: Dictionary = {}
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg=="--before": phase="before"
	output="res://tmp/uiux_roster_state_20260913/"+phase
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	game=Game.instantiate()
	add_child(game)
	await settle()
	Fixture.prepare(game)
	game.update4_active_run={}
	GameState.day=2
	game._unlock_kobold_scout_commander()
	game.deployed_instance_ids.assign(["mon_core_pudding","mon_core_gob","mon_contract_mori"])
	expect(game._choose_early_specialization("goblin","goblin_treasure_hunter"),"fixture legal specialization")
	owned=game.monster_roster.duplicate(true)
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale in [0.9,1.0,1.15]:
			UISettings.text_scale=scale
			var tag := "%dx%d_%d" % [resolution.x,resolution.y,roundi(scale*100)]
			prepare_roster()
			game._set_screen(C.SCREEN_MANAGEMENT)
			await click(node("ManagementTab_roster"))
			var preserved := placements()
			var capacity: int = game._placement_count("barracks")
			if phase=="after":
				check_map(tag)
				expect(node("ManagementRosterButton")!=null,tag+" direct roster entry")
				expect(text_contains(node("MonsterRosterDock"),"출전 3"),tag+" visible deployment count")
				expect(text_contains(node("MonsterRosterDock"),"예비 2"),tag+" visible reserve count")
				expect(text_contains(node("MonsterRosterDock"),"지원 1"),tag+" support distinct from reserves")
				expect((node("MonsterCard_goblin") as Button).text.contains("곱"),tag+" companion name on card")
			else:
				expect(game.dungeon_renderer._roster_preview_monster_ids().has("stone_sentinel"),tag+" baseline reproduces reserve on map")
			await capture(tag+"_management")
			if phase=="after": await press("ManagementRosterButton")
			else: game._open_contract_roster()
			await settle()
			expect(game.current_screen==C.SCREEN_CONTRACT_BOARD,tag+" live roster opens")
			await press("CampaignChoice_mon_contract_dolkong")
			if phase=="after":
				expect(text_contains(node("CampaignActionNotice"),"예비 2명 · 지원 1명"),tag+" board counts agree with dock")
				expect(text_contains(node("CampaignChoiceDetail"),"예비"),tag+" reserve status in detail")
				expect(text_contains(node("CampaignChoiceDetail"),"병영"),tag+" saved room visible")
				expect((node("ContractDetailArt") as TextureRect).texture.resource_path.ends_with("dolkong_base.png"),tag+" full portrait in roster")
			await capture(tag+"_reserve")
			await press("ContractToggleButton")
			expect(game.deployed_instance_ids.has("mon_contract_dolkong"),tag+" actual toggle deploys")
			expect(placements()==preserved,tag+" toggle keeps stored placements and economy")
			expect(game._placement_count("barracks")==capacity,tag+" existing room capacity rule preserved")
			await capture(tag+"_deployed")
			await press("CampaignConfirmButton")
			if phase=="after": expect(game.current_screen==C.SCREEN_MANAGEMENT,tag+" returns to entry screen")
			else: game._set_screen(C.SCREEN_MANAGEMENT)
			await settle()
			if phase=="after": check_map(tag+" after toggle")
			await capture(tag+"_updated_map")
			await press("MonsterCard_stone_sentinel")
			expect(game.deploy_pick_monster_id=="stone_sentinel",tag+" keyboard card starts placement")
			await key(KEY_ESCAPE)
			expect(game.deploy_pick_monster_id=="" and placements()==preserved,tag+" ESC cancels without losing saved place")
			game._open_contract_roster()
			await settle()
			await press("CampaignChoice_mon_core_rolo")
			expect((node("ContractToggleButton") as Button).disabled,tag+" support cannot join defense")
			if phase=="after":
				expect(text_contains(node("CampaignChoiceDetail"),"지원 전용"),tag+" support gets accurate reason")
				expect(not text_contains(node("CampaignChoiceDetail"),"외형 준비"),tag+" no false art-pending excuse")
			await capture(tag+"_support")
			await press("CampaignChoice_mon_core_pynn")
			await press("ContractToggleButton")
			expect(game.deployed_instance_ids.size()==5,tag+" stage four allows five")
			await press("CampaignChoice_mon_contract_dolkong")
			await press("ContractToggleButton")
			expect(not game.deployed_instance_ids.has("mon_contract_dolkong"),tag+" reserve switch")
			await press("CampaignConfirmButton")
			if phase=="before": game._set_screen(C.SCREEN_MANAGEMENT)
			game._open_monster_screen()
			await settle()
			if phase=="after":
				await press("MonsterRoster_stone_sentinel")
				expect(game.selected_monster_id=="stone_sentinel",tag+" reserve accessible in growth list")
				expect((node("MonsterRosterScroll") as Control).get_global_rect().encloses((node("MonsterRoster_stone_sentinel") as Control).get_global_rect()),tag+" selected reserve remains fully visible after rebuild")
				expect(text_contains(node("MonsterCurrentRoom"),"예비"),tag+" growth shows reserve status")
				expect(text_contains(node("MonsterSavedRoom"),"병영"),tag+" growth shows saved reserve room")
				check_visible_text(node("MonsterSavedRoom") as Label,tag+" saved room readable")
				check_copy(game.ui_layer)
			else:
				game._select_monster("stone_sentinel")
				await settle()
			await capture(tag+"_growth")
			if phase=="after":
				await press("MonsterContractRoster")
				await press("CampaignConfirmButton")
				expect(game.current_screen==C.SCREEN_MONSTER,tag+" roster returns to growth")
	if phase=="after":
		await interactions()
		await unowned_candidates()
	game.queue_free()
	await settle()
	var file := FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase":phase,"assertions":count,"failed":failed,"captures":captures},"\t"))
	file.close()
	print("UIUX_ROSTER_STATE_TEST: %s (%d assertions, %d captures)" % ["FAIL" if failed else "PASS",count,captures.size()])
	get_tree().quit(1 if failed else 0)

func prepare_roster() -> void:
	game.monster_roster={}
	for id in ["slime","goblin","imp","spore_healer","stone_sentinel","kobold_scout"]:
		game.monster_roster[id]=owned[id].duplicate(true)
	game.monster_roster.spore_healer.room="treasure"
	game.monster_roster.stone_sentinel.room="barracks"
	game.selected_contract_ids.assign(["spore_healer","stone_sentinel"])
	game.deployed_instance_ids.assign(["mon_core_pudding","mon_core_gob","mon_contract_mori"])
	game.combat_speed_intro_seen=true
	game.selected_monster_id="goblin"
	game._sync_contract_reserves()

func press(id: String) -> void:
	var b := node(id) as Button
	expect(b!=null and b.is_visible_in_tree(),id+" live button")
	if b==null: return
	b.grab_focus()
	await key(KEY_ENTER)

func placements() -> Dictionary:
	return {"roster":game.monster_roster.duplicate(true),"gold":GameState.gold,"mana":GameState.mana}

func check_map(tag: String) -> void:
	var ids: Array = game._defense_monster_ids()
	expect(game.dungeon_renderer._roster_preview_monster_ids()==ids,tag+" map exact deployment order")
	for id in game.monster_roster:
		var p: Vector2 = game._management_monster_preview_position(id)
		expect((p!=Vector2.INF)==ids.has(id),tag+" hit position matches deployment "+id)
		if p!=Vector2.INF:
			expect(game._management_monster_at(p)==id,tag+" visible unit hit test "+id)

func text_contains(parent: Node, value: String) -> bool:
	if parent==null: return false
	if (parent is Label or parent is Button) and parent.text.contains(value): return true
	for child in parent.get_children():
		if text_contains(child,value): return true
	return false

func capture(id: String) -> void:
	await settle()
	var path := output.path_join(id+".png")
	expect(get_viewport().get_texture().get_image().save_png(path)==OK,id+" capture")
	captures.append(path)

func world(point: Vector2) -> Vector2:
	return game.get_global_transform_with_canvas()*point

func mouse(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=down
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
	event.position=point
	event.global_position=point
	get_viewport().push_input(event,true)

func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position=point
	event.global_position=point
	event.button_mask=MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(event,true)

func interactions() -> void:
	prepare_roster()
	game._set_management_tool_tab("roster")
	await settle()
	var before := placements()
	game._begin_management_roster_drag("stone_sentinel")
	expect(game.dragging_monster_id=="","reserve cannot enter drag")
	game._start_monster_placement("stone_sentinel")
	expect(game.deploy_pick_monster_id=="","reserve cannot enter click placement")
	expect(placements()==before,"reserve selection is read-only")
	var card := node("MonsterCard_goblin") as Button
	mouse(card.get_global_rect().get_center(),true)
	await settle()
	expect(game.dragging_monster_id=="goblin","actual card press starts drag")
	var target := world(game.graph.center("recovery"))
	motion(target)
	await settle()
	await capture("interaction_drag")
	mouse(target,false)
	await settle()
	expect(game.monster_roster.goblin.room=="recovery","actual drop changes existing room")
	expect(GameState.gold==before.gold and GameState.mana==before.mana,"monster drop has no cost")
	await capture("interaction_placed")
	await press("PlacementUndoButton")
	expect(placements()==before,"existing Undo restores exact roster")
	await capture("interaction_undo")
	game._start_combat()
	await settle(20)
	expect(game.current_screen==C.SCREEN_COMBAT,"actual defense starts")
	if game.current_screen==C.SCREEN_COMBAT:
		game.combat_scene.set_pause_state(true,false)
		var spawned: Array[String]=[]
		for unit in game.monster_units: spawned.append(unit.unit_id)
		expect(spawned==game._defense_monster_ids(),"spawned allies match map and cards")
		await capture("interaction_combat")
	game._set_screen(C.SCREEN_MANAGEMENT)
	game.deployed_instance_ids.clear()
	game.selected_contract_ids.clear()
	game.campaign_cycle_index=1
	expect(game._monster_deployed_for_defense("imp"),"empty legacy deployment keeps existing all-active meaning")
	expect(game.dungeon_renderer._roster_preview_monster_ids()==game._defense_monster_ids(),"legacy map remains consistent")

func check_visible_text(label: Label, tag: String) -> void:
	expect(label!=null,tag+" label exists")
	if label==null: return
	var font: Font = label.get_theme_font("font")
	var measured := font.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,label.size.x,label.get_theme_font_size("font_size"))
	expect(measured.y<=label.size.y+1,tag+" full text fits")

func unowned_candidates() -> void:
	prepare_roster()
	for id in DataRegistry.update2_contract_ids(): game.monster_roster.erase(id)
	game.selected_contract_ids.clear()
	game.contract_board_pending_ids.clear()
	game.deployed_instance_ids.assign(["mon_core_pudding","mon_core_gob","mon_core_pynn"])
	var before := placements()
	game._set_screen(C.SCREEN_CONTRACT_BOARD)
	await settle()
	var portraits := {"spore_healer":"mori_base.png","stone_sentinel":"dolkong_base.png","war_drummer":"dudum_base.png","moon_tracker":"moon_base.png","mimic_porter":"mimi_base.png"}
	for id in DataRegistry.update2_contract_ids():
		await press("CampaignChoice_"+id)
		var art := node("ContractDetailArt") as TextureRect
		expect(art!=null and art.texture.resource_path.ends_with(portraits[id]),"unowned candidate uses own full base portrait "+id)
		expect(placements()==before,"unowned candidate preview never creates owned growth data "+id)
		check_visible_text(node("ContractToggleReason") as Label,"candidate reason "+id)
		await capture("candidate_"+id)
