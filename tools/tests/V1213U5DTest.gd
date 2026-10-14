extends Node
const GameScene = preload("res://scenes/game/GameRoot.tscn")
const Duo = preload("res://scripts/systems/duo_links/DuoLinkService.gd")
const Legacy = preload("res://scripts/systems/legacy/NewCycleService.gd")
const Store = preload("res://scripts/core/CampaignSaveStore.gd")
const Audit = preload("res://tools/ux_audit/Audit.gd")
var game: Node
var ui
var checks := 0
var failures: Array[String] = []
var out := "res://tmp/v1213_u5d/contract"
var capture_only := false
var polish_capture := false
var capture_filter: PackedStringArray = []
var captures: Array[String] = []
var observations: Array = []

func _ready() -> void:
	get_tree().create_timer(140).timeout.connect(func(): get_tree().quit(2))
	call_deferred("run")

func expect(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures.append(text); print("FAIL: "+text)

func settle(frames: int = 8) -> void:
	for i in range(frames): await get_tree().process_frame

func control(id: String) -> Control:
	return game.ui_layer.find_child(id,true,false) as Control

func click(id: String) -> void:
	var target := control(id)
	expect(target != null and target.is_visible_in_tree(),"input visible "+id)
	if target == null: return
	var ancestor: Node = target.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(target)
		ancestor = ancestor.get_parent()
	await settle()
	var point := target.get_global_transform_with_canvas()*(target.size/2)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		get_viewport().push_input(event,true)
		await get_tree().process_frame
	await settle()

func prepare(day: int = 7) -> void:
	game.onboarding_enabled = false; game.tutorial_gate_enabled = false
	game.story_feature_enabled = false; game.tutorial_manager.active = false
	game.story_director.cancel_active_scene()
	game.onboarding_dialogue_queue.clear()
	game.pause_menu_open = false
	GameState.player_name = "U5D test"
	GameState.day = day; GameState.gold = 5000; GameState.mana = 5000; GameState.infamy = 650
	game.selected_monster_id = "slime"
	ui.inspected_id = "slime"; ui.list_mode = "owned"; ui.active_tab = "training"
	game._set_screen("monster",false)

func behavior() -> void:
	prepare()
	game.monster_roster.slime.level = 1; game.monster_roster.slime.exp = 29
	game.monster_roster.slime.training_day = 0; game.monster_roster.slime.training_count_today = 2
	game._set_screen("monster",false); await settle()
	var predicted: Dictionary = ui.training_preview("slime")
	var gold: int = GameState.gold
	await click("MonsterTrainingButton")
	expect(GameState.gold == gold-30,"training exact cost")
	expect(int(game.monster_roster.slime.level) == int(predicted.level) and int(game.monster_roster.slime.exp) == int(predicted.exp),"EXP crossing matches actual levelup")
	expect(int(game.monster_roster.slime.training_count_today) == 1,"day rollover resets actual training count")
	expect(control("TrainingReceipt") != null,"last training receipt separate from preview")
	await click("CHR_GOB"); expect(game.selected_monster_id == "goblin","select another companion after training")
	await click("MonsterTab_skills"); await click("CHR_PYNN")
	expect(ui.active_tab == "skills" and game.selected_monster_id == "imp","tab retained on companion change")
	await click("CHR_PUDDING"); await click("MonsterTab_training"); await click("MonsterTrainingButton")
	expect(int(game.monster_roster.slime.training_count_today) == 2,"second training consumes second use")
	expect((control("MonsterTrainingButton") as Button).disabled,"third training locked")
	var frozen: Dictionary = game.monster_roster.slime.duplicate(true)
	game._train_selected_monster()
	expect(game.monster_roster.slime == frozen,"direct third training rejected")
	game.monster_roster.slime.level = game._training_level_cap()
	game._set_screen("monster",false); await settle()
	expect((control("MonsterTrainingButton") as Button).disabled,"chapter level cap matches existing rule")
	GameState.day = 1; ui.active_tab = "promotion"; game._set_screen("monster",false); await settle()
	expect(control("PromotionOption0") != null and (control("PromotionOption0") as Button).disabled,"promotion preview visible before unlock")
	await click("PromotionChoice1")
	expect(ui.promotion_choice == 1 and control("PromotionOption1") != null and (control("PromotionOption1") as Button).disabled,"second existing promotion remains selectable while locked")
	await click("PromotionChoice0")
	expect(ui.promotion_choice == 0 and control("PromotionOption0") != null,"first promotion action restored by candidate selector")
	GameState.day = 12; game.campaign_chapter_two_started = true
	game.monster_roster.slime.level = 5; game.monster_roster.slime.bond = 80
	game._set_screen("monster",false); await settle()
	expect(ui.promotion_capacity().contains("총 1명"),"cumulative total limit displayed")
	var rule: Dictionary = game._first_evolution_rule_for_monster("slime")
	expect(game._promote_monster("slime",str(rule.id)),"promotion actual execution")
	expect(game._promotion_count() == 1 and ui.promotion_capacity().contains("DAY23"),"next expansion from current-mode dates")
	expect(not ui.promotion_capacity().contains("오늘은"),"ambiguous today wording removed")
	GameState.day = 23
	expect(game._promotion_limit_for_current_day() == 2,"second promotion actual total allowance")
	# Existing support-only entry stays read-only; no defense-selection bypass.
	game.monster_roster["kobold_scout"] = game.monster_roster.slime.duplicate(true)
	game.monster_roster.kobold_scout.merge({"level":1,"exp":0,"bond":0,"raid_support":true,"defense_enabled":false,"promotion_id":"","room":"entrance","unlocked_memory_ids":[]},true)
	ui._select_owned("kobold_scout"); ui._tab("training"); await settle()
	expect(ui.inspected_id == "kobold_scout" and game.selected_monster_id != "kobold_scout","support inspection preserves defense selection contract")
	expect((control("MonsterTrainingButton") as Button).disabled,"support training locked in UI")
	ui._scope("codex"); ui._select_codex("spore_healer"); await settle()
	expect((control("CodexIdentity") as Label).text == "???","future companion identity hidden")
	expect(control("MonsterTrainingButton") == null,"codex offers no training")
	expect(control("MonsterTabs") == null,"codex is a list scope, not a sixth growth tab")
	expect(game.monster_roster.size() == 4,"codex does not add first-cycle companions")

func memories() -> void:
	prepare(7)
	game.monster_roster.slime.bond = 24; game.monster_roster.slime.unlocked_memory_ids = []
	var grant: Dictionary = game._grant_monster_bond("slime",1)
	var memory_id := str(grant.unlocked_memory_id)
	expect(memory_id != "" and game.monster_roster.slime.unlocked_memory_ids.has(memory_id),"actual bond boundary acquires memory")
	var profile: Dictionary = Legacy.complete_cycle({},"ending_monster_family_castle",{}, {"species_id":"slime","display_name":"푸딩","level":3})
	expect(Legacy.apply_legacy_memory(game.monster_roster,profile.legacy_monster),"cycle inheritance connects memory to roster")
	var inherited := str(profile.legacy_monster.inherited_memory_id)
	ui._tab("memory"); await settle()
	expect(control("MemoryChoice_"+memory_id) != null and control("MemoryChoice_"+inherited) != null,"bond and inherited memories rendered")
	game.campaign_profile = profile
	game._set_screen("management",false)
	var payload: Dictionary = game._campaign_save_payload("management")
	var saved: Dictionary = Store.write(payload,game._campaign_save_summary("management"),"user://u5d_memory.json")
	expect(bool(saved.get("ok",false)),"real campaign store writes acquired memories: "+str(saved))
	game.monster_roster.slime.unlocked_memory_ids.clear()
	game.monster_roster.slime.bond = 0
	# Fresh scene instance proves restored memory does not rely on UI/session caches.
	game.queue_free(); await settle(3)
	game = GameScene.instantiate()
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false; game.campaign_save_v5_enabled = false
	add_child(game); await settle()
	game.set_process(false); game.set_physics_process(false)
	ui = game.management_scene.monster_ui
	var read: Dictionary = Store.inspect("user://u5d_memory.json")
	expect(game._restore_campaign_payload(read.get("payload",{})),"real campaign payload restores")
	expect(game.monster_roster.slime.unlocked_memory_ids.has(memory_id) and game.monster_roster.slime.unlocked_memory_ids.has(inherited),"bond and inherited IDs survive disk roundtrip")
	prepare(7); ui._tab("memory"); await settle()
	var before: Dictionary = game.monster_roster.slime.duplicate(true)
	await click("MemoryChoice_"+inherited)
	expect(game.monster_roster.slime == before,"reading memory grants no reward")
	expect(control("MemoryOrigin") != null and (control("MemoryOrigin") as Label).text.contains("1회차"),"inheritance source cycle rendered")
	game._open_selected_monster_memories(); await settle()
	expect(control("MonsterTabs") != null and ui.active_tab == "memory","legacy archive screen enters same five-tab workspace")

func links() -> void:
	var id := "link_spore_jelly_shelter"
	var catalog: Dictionary = DataRegistry.update3_duo_links
	var members: Array = catalog[id].member_instance_ids
	var progress: Dictionary = {}
	for member in members: progress[member] = {"bond":45,"unlocked_memory_ids":["fixture"]}
	var run: Dictionary = {}
	for day in range(1,4): run = Duo.record_deployed_day(run,members,day,catalog)
	for i in range(5):
		run = Duo.record_unlock_action(run,str(members[0]),"damage_absorbed",20,"shield%d" % i,catalog)
		run = Duo.record_unlock_action(run,str(members[1]),"effective_heal",15,"heal%d" % i,catalog)
	var event_id := str(catalog[id].unlock_condition.event_id)
	expect(Duo.eligible_memory_event_ids({},run,progress,catalog).has(event_id),"duo real day/action counters reach memory eligibility")
	var result := Duo.complete_memory_event({},event_id,catalog)
	expect(bool(result.ok) and result.profile.duo_links.unlocked.has(id),"duo memory event unlocks link")
	expect(not bool(Duo.complete_memory_event(result.profile,event_id,catalog).ok),"duo event reward idempotent")
	prepare(7); game.update3_profile = result.profile; game.update3_active_run = run
	game.update3_active_run.update3_enabled = true; game.update3_active_run.duo_link_loadout_confirmed = true
	game.campaign_cycle_index = 2
	ui._tab("duo"); await settle()
	expect(not (control("MonsterDuoEditButton") as Button).disabled,"existing cycle editor availability used")
	await click("MonsterDuoEditButton")
	expect(game.current_screen == "duo_link_loadout","duo edit callback enters signal screen")
	await click("DuoEquip_"+id)
	expect(game.update3_active_run.get("equipped_duo_links",[]).has(id),"equip signal reaches actual service")
	await click("DuoEquip_"+id)
	expect(not game.update3_active_run.get("equipped_duo_links",[]).has(id),"unequip signal preserved")
	await click("DuoCancelButton")
	expect(game.current_screen == "management","cancel signal preserves existing return contract")
	game.campaign_cycle_index = 1; ui._tab("duo"); await settle()
	expect((control("MonsterDuoEditButton") as Button).disabled,"first-cycle edit remains locked")

func contracts() -> void:
	prepare(7); game.campaign_cycle_index = 2
	game.selected_contract_ids.clear(); game.contract_board_pending_ids.clear()
	game._set_screen("contract_board",false); await settle()
	var offers: Array = game.contract_board_offer_ids.duplicate()
	expect(offers.size() >= 2,"existing next-cycle contract offers")
	await click("CampaignChoice_"+str(offers[0])); await click("ContractToggleButton")
	expect(game.contract_board_pending_ids.size() == 1 and (control("CampaignConfirmButton") as Button).disabled,"one candidate does not confirm")
	await click("CampaignCancelButton")
	expect(game.contract_board_pending_ids.is_empty(),"contract cancel clears pending choices")
	for i in range(2):
		await click("CampaignChoice_"+str(offers[i])); await click("ContractToggleButton")
	await click("CampaignConfirmButton")
	expect(game.selected_contract_ids.size() == 2 and game.current_screen == "duo_link_loadout","two contracts confirm through existing transition")
	game.update3_active_run.duo_link_loadout_confirmed = true
	ui._tab("training"); await settle()
	await click("MonsterContractRoster")
	await click("CampaignChoice_mon_core_pudding")
	var room: String = game.monster_roster.slime.room
	await click("ContractToggleButton")
	expect(not game.deployed_instance_ids.has("mon_core_pudding") and game.monster_roster.slime.room == room,"reserve toggle preserves saved room")
	await click("CampaignConfirmButton")
	expect(game.current_screen == "monster","deployment confirm returns to companion workspace")
	game.monster_roster.slime.level = 1
	game.monster_roster.slime.exp = 0
	game.monster_roster.slime.training_count_today = 0
	game._set_screen("monster",false); await settle()
	await click("MonsterTab_training")
	expect(not (control("MonsterTrainingButton") as Button).disabled,"reserve keeps growth according to existing training rule")

func inspect(id: String, capture: bool = false) -> void:
	await settle(12)
	var audit := Audit.new(); audit.game = game
	var items: Array = []; audit.collect(game.ui_layer,items); audit.free()
	for label in game.ui_layer.find_children("*","Label",true,false):
		if not label.is_visible_in_tree(): continue
		var ancestor: Node = label.get_parent()
		while ancestor != null:
			if ancestor is BaseButton:
				expect(ancestor.get_global_rect().grow(2).encloses(label.get_global_rect()),id+" label inside button "+str(label.name))
				break
			ancestor = ancestor.get_parent()
		var owner: Node = label.get_parent()
		if owner is Control and not owner is Container:
			expect(owner.get_global_rect().grow(2).encloses(label.get_global_rect()),id+" label remains in owner "+str(label.name))
	for item in items:
		if item.type == "Label" and str(item.text) != "": expect(int(item.line_count) <= int(item.visible_lines),id+" label lines "+str(item.name))
		if bool(item.button): expect(str(item.tooltip).strip_edges() != "",id+" tooltip "+str(item.name))
	var roster := control("MonsterRosterPanel"); var tabs := control("MonsterTabs"); var body := control("MonsterGrowthScroll")
	if roster != null:
		for button in roster.find_children("*","Button",true,false):
			var ancestor: Node = button.get_parent()
			var in_scroll := false
			while ancestor != roster and ancestor != null:
				if ancestor is ScrollContainer: in_scroll = true; break
				ancestor = ancestor.get_parent()
			if not in_scroll: expect(roster.get_global_rect().grow(2).encloses(button.get_global_rect()),id+" roster owns "+str(button.name))
	if roster != null and tabs != null:
		expect(not roster.get_global_rect().intersects(tabs.get_global_rect()),id+" list and tabs don't overlap")
		expect(get_viewport().get_visible_rect().encloses(tabs.get_global_rect()),id+" all tabs inside viewport")
		expect(tabs._buttons.size() == 5,id+" exact five tabs")
		if body != null: expect(not tabs.get_global_rect().intersects(body.get_global_rect()),id+" tabs/body don't overlap")
	if control("MonsterGrowthTools") != null:
		var hero := control("MonsterHero")
		expect(hero != null and not hero.get_global_rect().intersects(tabs.get_global_rect()),id+" hero and tabs separated")
		var portrait: Control = hero.find_child("MonsterPortrait_"+ui.inspected_id,true,false)
		var pedestal := control("MonsterPedestal")
		expect(hero.get_global_rect().encloses(portrait.get_global_rect()),id+" large portrait stays inside hero")
		expect(absf(portrait.get_global_rect().end.y-pedestal.get_global_rect().position.y) <= 7,id+" portrait sits on pedestal")
		var footer := control("MonsterActionFooter")
		if footer != null:
			expect(get_viewport().get_visible_rect().grow(2).encloses(footer.get_global_rect()),id+" fixed actions inside viewport")
			expect(not footer.get_global_rect().intersects(body.get_global_rect()),id+" fixed actions outside scrolling content")
		for action in ["MonsterTrainingButton","PromotionOption0","PromotionOption1"]:
			var button := control(action)
			if button != null:
				expect(get_viewport().get_visible_rect().grow(2).encloses(button.get_global_rect()),id+" complete action visible "+action)
		if ui.active_tab == "promotion":
			expect(control("PromotionConditions").columns == 2,id+" promotion conditions use two columns")
			var option: Dictionary = game._evolution_rules_for_monster(ui.inspected_id)[ui.promotion_choice]
			if int(option.get("required_bond",0)) == 0: expect(control("PromotionBondCondition") == null,id+" zero bond requirement hidden")
			if not UISettings.is_touch_ui(): expect(body.get_global_rect().grow(2).encloses(control("PromotionConditions").get_global_rect()),id+" compact promotion conditions fully visible")
	for tooltip_id in ["FocusGrowthExplanation","FocusPreparation","TrainingStats_max_hp","MemorySource"]:
		var label := control(tooltip_id)
		if label != null: expect(label.mouse_filter != Control.MOUSE_FILTER_IGNORE and label.tooltip_text != "",id+" condensed explanation can receive tooltip hover "+tooltip_id)
	if roster != null:
		expect(control("MonsterCastleBackground") != null,id+" existing castle background displayed")
	for item in items:
		if LanguageSettings.locale != "ko" and item.type == "Label":
			var regex := RegEx.new(); regex.compile("[가-힣]")
			expect(regex.search(str(item.text)) == null,id+" translated label "+str(item.name))
		expect(not str(item.text).contains("�"),id+" no replacement glyph "+str(item.name))
	observations.append({"id":id,"items":items})
	if capture and DisplayServer.get_name() != "headless" and (capture_filter.is_empty() or capture_filter.has(id)):
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(id+".png"))
		captures.append(id+".png")

func layout() -> void:
	# First-cycle codex has every future contract; do not let behavior fixtures hide rows.
	game.selected_contract_ids.clear()
	for id in game.monster_roster.keys():
		if id not in ["slime","goblin","imp"]: game.monster_roster.erase(id)
	for locale in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		for dimensions in ([Vector2i(1920,1080),Vector2i(1280,720)] if polish_capture else [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(2560,1080)]):
			get_window().size = dimensions
			prepare(12)
			game.monster_roster.slime.level = 5; game.monster_roster.slime.bond = 80
			game.campaign_chapter_two_started = true
			if game.monster_roster.slime.get("unlocked_memory_ids",[]).is_empty():
				game.monster_roster.slime.bond = 24
				game._grant_monster_bond("slime",1)
			for tab in ["training","skills","promotion","duo","memory"]:
				ui._tab(tab)
				var name := "%s_%d_%s" % [locale,dimensions.x,tab]
				await inspect(name,capture_only and ((dimensions.x == 1920 and tab != "duo") or capture_filter.has(name)))
			ui._scope("codex"); ui._select_codex("spore_healer")
			var codex_name := "%s_%d_codex" % [locale,dimensions.x]
			await inspect(codex_name,capture_only and (dimensions.x == 1920 or capture_filter.has(codex_name)))
			ui._scope("owned")
			game.campaign_cycle_index = 2
			if polish_capture: continue
			game._set_screen("contract_board",false)
			await inspect("%s_%d_contract" % [locale,dimensions.x],capture_only and dimensions.x == 1280 and locale == "en")
			if locale == "ko" and dimensions.x == 1920:
				game._set_screen("duo_link_loadout",false)
				await inspect("ko_1920_team_duo",capture_only)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output-dir="): out = arg.trim_prefix("--output-dir=")
		if arg.begins_with("--capture-filter="): capture_filter = arg.trim_prefix("--capture-filter=").split(",")
	capture_only = OS.get_cmdline_user_args().has("--capture-only")
	polish_capture = OS.get_cmdline_user_args().has("--polish-capture")
	expect(ProjectSettings.globalize_path("user://").replace("\\","/").contains("/tmp/v1213_u5d/"),"isolated APPDATA")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	GameState.reset(); GameState.player_name = "U5D test"; LanguageSettings.set_locale("ko",false)
	game = GameScene.instantiate()
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false; game.campaign_save_v5_enabled = false
	add_child(game); await settle()
	game._debug_skip_onboarding(); game.set_process(false); game.set_physics_process(false)
	ui = game.management_scene.monster_ui
	if not capture_only: await behavior(); await memories(); await links(); await contracts()
	await layout()
	var file := FileAccess.open(out.path_join("result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"observations":observations},"\t")); file.close()
	print("V1213_U5D_TEST: %s (%d checks, %d failures, %d captures)" % ["PASS" if failures.is_empty() else "FAIL",checks,failures.size(),captures.size()])
	game.queue_free(); await settle(3)
	get_tree().quit(0 if failures.is_empty() else 1)
