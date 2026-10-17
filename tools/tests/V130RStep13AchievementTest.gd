extends Node
const Service = preload("res://scripts/achievements/AchievementService.gd")
const Gameplay = preload("res://scripts/achievements/AchievementGameplay.gd")
const OUT := "res://_mockup/game_step13_ach/"
var checks := 0
var failures: Array = []
var coverage: Array = []
var mode := "direct"
var game: Node

class MockSteam extends Node:
	signal stats_ready
	signal stats_stored(ok: bool)
	var stats_available := false
	var accepted := true
	var calls: Array = []
	var remote := {}
	func achieved(id: String) -> bool: return remote.has(id)
	func send(ids: Array, stats: Dictionary, _catalog: Array) -> bool:
		calls.append({"ids":ids.duplicate(),"stats":stats.duplicate()}); return accepted
	func debug_clear(_ids: Array) -> bool: return true

class MockSteamAPI extends RefCounted:
	var calls: Array = []
	var stats := {"STAT_TRAPS_PLACED":30}
	var achieved := {}
	var accepted := true
	func getSteamID() -> int: return 123
	func getAchievement(id: String) -> Dictionary: return {"ret":true,"achieved":achieved.has(id)}
	func getStatInt(id: String) -> int: return int(stats.get(id,0))
	func setStatInt(id: String, value: int) -> bool:
		calls.append(["setStatInt",id,value]); stats[id] = value; return accepted
	func setAchievement(id: String) -> bool:
		calls.append(["setAchievement",id]); achieved[id] = true; return accepted
	func storeStats() -> bool: calls.append(["storeStats"]); return accepted
	func indicateAchievementProgress(id: String, value: int, maximum: int) -> bool:
		calls.append(["indicateAchievementProgress",id,value,maximum]); return accepted

func expect(ok: bool, name: String) -> void:
	checks += 1
	if not ok: failures.append(name); print("FAIL ",name)

func fresh() -> Node:
	var service := Service.new(); service.storage_enabled = false; return service

func frames(n: int = 3) -> void:
	for i in n: await get_tree().process_frame

func _ready() -> void: run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ach-mode="): mode = arg.get_slice("=",1)
	await frames()
	if Engine.has_singleton("Steam"):
		var api := Engine.get_singleton("Steam")
		for method in ["steamInitEx","getAchievement","setAchievement","storeStats","setStatInt","getStatInt","indicateAchievementProgress","requestUserStats","run_callbacks"]:
			expect(api.has_method(method),"official extension API "+method)
		write_json("steam_api_methods.json",api.get_method_list())
	else: expect(false,"official GDExtension singleton loaded")
	if mode == "offline":
		expect(not AchievementService.bridge.initialized,"no Steam client: initialization fails safely")
		expect(not AchievementService.bridge.stats_available,"no Steam client: stats unavailable")
		write_json("offline_runtime.json",{"status":AchievementService.bridge.status,"initialized":AchievementService.bridge.initialized,"initialize_msec":AchievementService.bridge.initialize_msec,"frames":Engine.get_process_frames()})
		game = load("res://scenes/game/GameRoot.tscn").instantiate()
		game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
		game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
		add_child(game); await frames(3)
		expect(game.current_screen == "title","full GameRoot boots title without Steam")
		expect(game.ui_layer.find_child("TitleStartButton",true,false) != null,"offline title UI constructed")
	unit_cases(); persistence(); retro(); queue_tests(); bridge_tests(); old_copies()
	if mode == "capture": await capture_screens()
	write_json(mode+"_checks.json",{"checks":checks,"failures":failures,"coverage":coverage,"mode":mode})
	print("STEP13 ",mode," checks=",checks," failures=",failures.size()," achievements=",coverage.size())
	if is_instance_valid(game): game._shutdown_audio_for_exit(); game.campaign_autosave_pending = false; game.queue_free()
	await frames(3)
	get_tree().quit(0 if failures.is_empty() else 1)

func unit_cases() -> void:
	var cases: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tools/tests/v130r_achievement_cases.json"))
	expect(cases.size() == 100,"100 positive design cases")
	var model := fresh()
	expect(model.catalog.sets.size() == 8,"8 sets")
	var hidden := 0
	for row in model.catalog.achievements:
		if row.hidden: hidden += 1
	expect(hidden == 8,"8 hidden achievements")
	model.free()
	for case in cases:
		var service := fresh()
		if case.id == "ACH_100":
			for row in service.catalog.achievements:
				if row.api_name != "ACH_100": service.profile.unlocked[row.api_name] = 1
		service.record(case.event,case.facts)
		expect(service.profile.unlocked.has(case.id),"positive "+case.id)
		var pending: int = service.profile.pending.size()
		service.record(case.event,case.facts)
		expect(service.profile.pending.size() == pending,"idempotent "+case.id)
		service.free()
		service = fresh(); service.record("unrelated_event",case.facts)
		expect(not service.profile.unlocked.has(case.id),"wrong event "+case.id); service.free()
		for key in case.facts:
			service = fresh()
			var missing: Dictionary = case.facts.duplicate(true); missing.erase(key)
			service.record(case.event,missing)
			expect(not service.profile.unlocked.has(case.id),"missing guard "+case.id+":"+key); service.free()
			service = fresh()
			var wrong: Dictionary = case.facts.duplicate(true)
			var value: Variant = wrong[key]
			wrong[key] = not value if value is bool else (float(value)-1 if float(value) > 0 else 1) if value is int or value is float else "wrong_id"
			service.record(case.event,wrong)
			expect(not service.profile.unlocked.has(case.id),"wrong guard "+case.id+":"+key); service.free()
		coverage.append(case.id)
	var service := fresh()
	service.count("STAT_FROG_SNAG",29); expect(not service.profile.unlocked.has("ACH_M_FROG"),"29 frog roots below threshold")
	service.count("STAT_FROG_SNAG",1); expect(service.profile.unlocked.has("ACH_M_FROG"),"30th root unlocks")
	service.count("STAT_TRAPS_PLACED",1,"placement_a"); service.count("STAT_TRAPS_PLACED",1,"placement_a")
	expect(service.profile.stats.STAT_TRAPS_PLACED == 1,"duplicate placement event ignored")
	service.count("STAT_TRAPS_PLACED",-50); expect(service.profile.stats.STAT_TRAPS_PLACED == 1,"negative counter ignored")
	service.record("meta",{"achievements":99}); expect(not service.profile.unlocked.has("ACH_100"),"meta requires real 99 unlocks")
	service.free()
	var bati_before := int(AchievementService.profile.stats.get("STAT_BATI_LINES",0))
	Gameplay.read_line("repeated_sentence","CHR_BATI"); Gameplay.read_line("repeated_sentence","CHR_BATI")
	expect(int(AchievementService.profile.stats.STAT_BATI_LINES) == bati_before+2,"two displayed readings count even with same sentence ID")
	Gameplay.read_line("not_bati","CHR_GOLDIN")
	expect(int(AchievementService.profile.stats.STAT_BATI_LINES) == bati_before+2,"other speakers do not count as Bati")

func persistence() -> void:
	var service := fresh(); service.storage_enabled = true; service.storage_path = "user://achievement_test_profile.json"
	service.record("battle_finished",{"win":true,"day":1}); service.count("STAT_TRAPS_PLACED",17)
	service.fresh_campaign(); service.run.defeats = 2
	var saved: Dictionary = service.snapshot()
	expect(service.persist(),"atomic local profile write")
	var restored := fresh(); restored.storage_enabled = true; restored.storage_path = service.storage_path; restored.load_profile()
	expect(restored.profile.unlocked.has("ACH_FIRST_NIGHT"),"unlock survives next process/profile load")
	expect(restored.profile.pending.has("ACH_FIRST_NIGHT"),"offline queue survives reload")
	expect(restored.profile.stats.STAT_TRAPS_PLACED == 17,"progress survives reload")
	restored.restore_snapshot(saved)
	expect(restored.run.defeats == 2,"campaign state embedded in save")
	# A damaged primary recovers the previous fully written profile.
	service.count("STAT_TRAPS_PLACED",1); service.persist()
	var file := FileAccess.open(service.storage_path,FileAccess.WRITE); file.store_string("{broken"); file.close()
	restored.load_profile(); expect(restored.profile.stats.STAT_TRAPS_PLACED == 17,"corrupt primary uses backup")
	service.free(); restored.free()
	service = fresh(); service.fresh_campaign(); var older: Dictionary = service.snapshot()
	service.run.defeats = 1; service.note_hunger(12,true); service.remember_run(); service.restore_snapshot(older)
	expect(service.run.defeats == 1 and service.run.hunger_days == 1,"retry/older same-campaign save cannot erase failures")
	service.note_hunger(12,true); expect(service.run.hunger_days == 1,"hunger recorded once per day")
	service.fresh_campaign(); expect(service.run.defeats == 0 and service.run.hunger_days == 0,"fresh campaign resets challenge history")
	service.free()

func retro() -> void:
	var service := fresh()
	var payload := {"game_state":{"day":30},"world":{"castle_art_stage":"stage_04_citadel","monster_roster":{"slime":{"level":10,"specialization_id":"slime_gate_bulwark","unlocked_memory_ids":["bond_slime_rank_1"]},"river_frog":{"level":1}}},"campaign":{"completed":true},"legacy_expansion":{"resolved_ending_id":"true_demon_castle","profile":{"ending_archive":{"monster_family_castle":{"seen_count":1}},"challenge_seal_history":[{"seal_id":"seal_low_mana","completed":true},{"seal_id":"seal_no_throne_damage","completed":false}]}},"update3":{"profile":{"duo_links":{"unlocked":["test_duo"]},"fronts":{"clear_counts":{"front_hero_oath":1}},"update3_endings_seen":["E12"]}},"onboarding":{"seen_dialogue_ids":{"unread_join":true}}}
	var fourth := {"crown_evolution":{"forms_unlocked":["crown_pudding_royal_bastion"]},"update4_endings_seen":["E17"]}
	var before := JSON.stringify(payload)
	service.retroactive(payload,fourth)
	for id in ["ACH_LEON","ACH_END_TRUE_DEMON_CASTLE","ACH_END_MONSTER_FAMILY_CASTLE","ACH_FIRST_MEMORY","ACH_FIRST_DUO","ACH_FIRST_SPEC","ACH_LEVEL_10","ACH_SEAL_LOW_MANA","ACH_FRONT_FRONT_HERO_OATH","ACH_END3_ENDING_HOLY_OPEN_GATE","ACH_END4_ENDING_COUNCIL_SEAT","ACH_CROWN_CROWN_PUDDING_ROYAL_BASTION"]:
		expect(service.profile.unlocked.has(id),"retro "+id)
	expect(not service.profile.unlocked.has("ACH_SEAL_NO_THRONE"),"incomplete seal not retro unlocked")
	expect(not service.profile.unlocked.has("ACH_NO_HUNGER"),"old save missing hunger history not assumed perfect")
	expect(not service.profile.unlocked.has("ACH_PERFECT_CAMPAIGN"),"old save missing defeats history not assumed perfect")
	expect(not service.profile.unlocked.has("ACH_SECRET_BUCKET"),"queued/read IDs are not proof of completed leak")
	expect(not service.profile.unlocked.has("ACH_FIRST_JOIN_SCENE"),"owning monster not proof of viewing join")
	expect(JSON.stringify(payload) == before,"retro source payload unmodified")
	var count: int = service.profile.unlocked.size(); service.retroactive(payload,fourth)
	expect(service.profile.unlocked.size() == count,"retro is idempotent")
	service.free()

func queue_tests() -> void:
	var service := fresh(); var fake := MockSteam.new(); service.bridge = fake
	service.record("battle_finished",{"win":true,"day":1}); service.flush()
	expect(fake.calls.is_empty(),"offline never calls set/store")
	fake.stats_available = true; service.flush()
	expect(fake.calls.size() == 1,"next online sends persisted unlock batch")
	expect(service.profile.pending.has("ACH_FIRST_NIGHT"),"queue retained before store callback")
	service._stored(false); expect(service.profile.pending.has("ACH_FIRST_NIGHT"),"Steam store failure retains queue")
	service.flush(); service.count("STAT_TRAPS_PLACED",2)
	service._stored(true); expect(service.profile.pending.is_empty(),"successful callback acknowledges only sent unlocks")
	expect(service.profile.pending_stats.get("STAT_TRAPS_PLACED",0) == 2,"progress created during flight retained")
	service.flush(); service._stored(true); expect(service.profile.pending_stats.is_empty(),"later successful stat batch acknowledged")
	fake.accepted = false; service.record("battle_finished",{"win":true,"day":3}); service.flush()
	expect(service.inflight.is_empty() and service.profile.pending.has("ACH_HERO_TRAINEE"),"set/store rejection retries later")
	fake.accepted = true; service.flush(); service._stored(true)
	expect(service.profile.pending.is_empty(),"queue drains after recovery")
	service.record("battle_finished",{"win":true,"day":5})
	var sends_before: int = fake.calls.size(); service.steam_reset_requested = true; service._online()
	expect(fake.calls.size() == sends_before,"debug Steam reset precedes old queued uploads")
	expect(service.profile.unlocked.is_empty(),"debug reset clears local achievement profile")
	service.free(); fake.free()

func bridge_tests() -> void:
	var bridge := preload("res://scripts/achievements/SteamAchievementBridge.gd").new()
	var api := MockSteamAPI.new(); bridge.api = api
	bridge._received(5267750,1,999); expect(not bridge.stats_available,"other Steam user callback ignored")
	bridge._received(42,1,123); expect(not bridge.stats_available,"other app callback ignored")
	bridge._received(5267750,1,123); expect(bridge.stats_available,"matching app/user callback enables stats")
	var rows: Array = AchievementService.catalog.achievements
	expect(bridge.send(["ACH_FIRST_NIGHT"],{"STAT_TRAPS_PLACED":20},rows),"actual bridge calls setAchievement/storeStats")
	expect(api.stats.STAT_TRAPS_PLACED == 30,"remote high water stat never decreases")
	expect(api.calls.has(["setAchievement","ACH_FIRST_NIGHT"]),"Steam API achievement ID exact")
	expect(not api.calls.has(["indicateAchievementProgress","ACH_TRAPS_50",20,50]),"progress popup waits until store ack")
	bridge._stored(5267750,1)
	expect(api.calls.has(["indicateAchievementProgress","ACH_TRAPS_50",30,50]),"progress popup uses committed high water after durable store")
	expect(bridge.progress_pending,"progress callback kept distinct")
	expect(not bridge.send(["ACH_HERO_TRAINEE"],{},rows),"next batch waits for progress callbacks")
	bridge._stored(5267750,1)
	expect(not bridge.progress_pending,"progress callback drains separately")
	api.calls.clear(); expect(bridge.send(["ACH_FIRST_NIGHT"],{},rows),"already achieved batch stores safely")
	expect(not api.calls.has(["setAchievement","ACH_FIRST_NIGHT"]),"already achieved Steam unlock not repeated")
	bridge._stored(5267750,1); bridge.free()

func old_copies() -> void:
	var results := []
	for version in [1,5]:
		var path := "res://tmp/v130_m6/original_copies/campaign_save_v%d.json" % version
		if not FileAccess.file_exists(path): continue
		var hash_before := FileAccess.get_sha256(path)
		var copy := "user://retro_copy_v%d.json" % version
		expect(DirAccess.copy_absolute(path,copy) == OK,"copy legacy save v%d" % version)
		var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(copy))
		var payload: Dictionary = document.get("payload",document.get("active_run",{}).get("legacy_payload",{}))
		var service := fresh(); service.retroactive(payload,document.get("profile",{}))
		var saved: Dictionary = service.snapshot()
		expect(int(service.profile.stats.get("STAT_ROSTER",0)) == 3,"legacy v%d restores three owned species" % version)
		var again := fresh(); again.restore_snapshot(saved)
		expect(again.profile.unlocked == service.profile.unlocked,"legacy v%d migrated achievements roundtrip" % version)
		expect(FileAccess.get_sha256(path) == hash_before and FileAccess.get_sha256(copy) == hash_before,"legacy source/copy v%d bytes unchanged" % version)
		results.append({"version":version,"source":path,"sha256":hash_before,"unlocked":service.profile.unlocked.keys(),"run":service.run})
		service.free(); again.free()
	expect(results.size() == 2,"v1/v5 test copies exercised")
	write_json("retro_copies.json",results)

func capture_screens() -> void:
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	ProjectSettings.set_setting("debug/start_flow14",true)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
	add_child(game); await frames(5); game.set_physics_process(false)
	AchievementService.debug_reset(); AchievementService.toast.queue.clear()
	LanguageSettings.set_locale("ko",false); game.start_flow.open_menu(); await frames()
	var button := game.ui_layer.find_child("TitleAchievementsButton",true,false) as Button
	expect(button != null and not button.disabled,"0114 menu achievement button enabled")
	button.pressed.emit(); await frames()
	var screen: Node = AchievementService.get_child(AchievementService.get_child_count()-1)
	expect(screen is CanvasLayer and screen.name != "AchievementToast","actual menu opens achievement screen")
	await capture("ach_menu_ko")
	screen.queue_free(); await frames()
	LanguageSettings.set_locale("en",false); AchievementService.open_screen(); await frames()
	screen = AchievementService.get_child(AchievementService.get_child_count()-1)
	await capture("ach_menu_en"); screen.queue_free(); await frames()
	LanguageSettings.set_locale("zh_CN",false); AchievementService.open_screen(); await frames()
	screen = AchievementService.get_child(AchievementService.get_child_count()-1)
	expect(screen.list.get_child_count() == 14,"Chinese base campaign list renders")
	screen.queue_free(); await frames()
	LanguageSettings.set_locale("ko",false)
	AchievementService.count("STAT_TRAPS_PLACED",27); AchievementService.open_screen(); await frames()
	screen = AchievementService.get_child(AchievementService.get_child_count()-1); screen.select("castle_builder"); await frames()
	await capture("ach_progress")
	screen.select("challenge_and_secret"); await frames()
	expect(not all_text(screen.page).contains("바티는 건조하다"),"locked secret title concealed")
	screen.queue_free(); await frames()
	AchievementService.record("battle_finished",{"win":true,"day":1}); await frames(6)
	expect(is_instance_valid(AchievementService.toast.current),"unlock toast visible")
	await capture("ach_toast")
	# Direct gameplay hooks use actual placement math and a real day-one battle.
	await live_hooks()

func live_hooks() -> void:
	AchievementService.debug_reset(); AchievementService.toast.queue.clear()
	game.start_flow.reset_run(); game.start_flow.intro_complete = true; game.start_flow.guide_step = 5; game.start_flow.command_seen = true
	game.story_director.enabled = false; game._set_screen("management",false); await frames(5)
	var view: Node = game.ui_layer.get_node_or_null("ApprovedMapManagement")
	expect(view != null,"live map available for event validation")
	if view == null: return
	view.monster_ui.assignments = view.Monsters.auto_place(view.placement,view.monster_ui.members,view.monster_ui.unlocked(),view.monster_ui.food_income)
	seed(130013)
	view.start_battle(); await frames(3)
	for i in 100:
		if game.current_screen != "dialogue": break
		game._onboarding_advance_dialogue(); await frames(1)
	view = game.ui_layer.get_node_or_null("ApprovedMapManagement")
	if view != null and view.battle == null: view.start_battle(); await frames(3)
	if view == null or view.battle == null: expect(false,"real battle started"); return
	var battle: RefCounted = view.battle; view.set_physics_process(false)
	for i in 18000:
		if not battle.running: break
		battle.physics_process(1.0/60)
		for unit in game.monster_units+game.enemy_units:
			if is_instance_valid(unit): unit.set_physics_process(false); unit._physics_process(1.0/60)
		if i%120 == 0: await frames(1)
	await frames(5)
	expect(not battle.running,"live DAY1 reaches natural result")
	expect(bool(battle.last_result.get("win",false)),"live DAY1 wins without injected result")
	expect(AchievementService.profile.unlocked.has("ACH_FIRST_NIGHT"),"live victory delivered to service")
	write_json("live_battle.json",battle.last_result)

func all_text(node: Node) -> String:
	var result := str(node.text) if node is Label else ""
	for child in node.get_children(): result += all_text(child)
	return result

func capture(id: String) -> void:
	await frames(); await RenderingServer.frame_post_draw
	var picture := get_viewport().get_texture().get_image(); picture.resize(1280,720,Image.INTERPOLATE_LANCZOS)
	expect(picture.save_png(OUT+id+".png") == OK,"capture "+id)

func write_json(name: String, value: Variant) -> void:
	var file := FileAccess.open(OUT+name,FileAccess.WRITE); file.store_string(JSON.stringify(value,"\t")); file.close()
