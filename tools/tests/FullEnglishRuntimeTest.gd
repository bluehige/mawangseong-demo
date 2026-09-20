extends Node
## Presentation audit, not a replacement for gameplay/end-to-end campaign tests.
const Game = preload("res://scenes/game/GameRoot.tscn")
const C = preload("res://scripts/core/Constants.gd")
var game: Node
var directory := "res://tmp/full_english_validation"
var failures: Array[Dictionary] = []
var seen_failures: Dictionary = {}
var visited: Array[String] = []
var inspected := 0
var cue_count := 0
var hangul := RegEx.new()

func _ready() -> void:
	call_deferred("_run")

func frames(count: int = 6) -> void:
	for index in range(count):
		await get_tree().process_frame

func issue(screen: String, kind: String, source: String, rendered: String, node: String) -> void:
	var key := kind + ":" + source
	if seen_failures.has(key): return
	seen_failures[key] = true
	failures.append({"screen":screen, "kind":kind, "source":source, "rendered":rendered, "node":node})

func inspect(node: Node, screen: String) -> void:
	if node is Control and node.is_visible_in_tree():
		var strings: Array[String] = []
		if node is Label or node is RichTextLabel or node is Button:
			strings.append(str(node.text))
		if node.tooltip_text != "": strings.append(node.tooltip_text)
		if node is LineEdit and node.placeholder_text != "": strings.append(node.placeholder_text)
		if node is OptionButton:
			for index in range(node.item_count): strings.append(node.get_item_text(index))
		for source in strings:
			inspected += 1
			var rendered := str(node.tr(source)) if node.can_auto_translate() else source
			if hangul.search(rendered.replace("한국어", "").replace("테스트이름", "")) != null:
				issue(screen, "untranslated", source, rendered, str(node.get_path()))
		if node is Label and node.text != "" and node.text_overrun_behavior != TextServer.OVERRUN_TRIM_ELLIPSIS:
			if node.get_line_count() > node.get_visible_line_count():
				issue(screen, "clipped_label", node.text, LanguageSettings.ui_text(node.text), str(node.get_path()))
		if node is RichTextLabel and not node.scroll_active and node.get_content_height() > node.size.y + 2:
			issue(screen, "clipped_rich_text", node.text, LanguageSettings.ui_text(node.text), str(node.get_path()))
	for child in node.get_children(): inspect(child, screen)

func shot(id: String, capture: bool = true) -> void:
	await frames()
	visited.append(id)
	inspect(game.ui_layer, id)
	if capture and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(directory.path_join(id + ".png"))

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--audit-dir="):
			directory = "res://" + argument.trim_prefix("--audit-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	hangul.compile("[가-힣]")
	LanguageSettings.set_locale("en", false)
	UISettings.apply_snapshot({"text_scale":1.0, "layout_mode":UISettings.LAYOUT_AUTO}, false)
	game = Game.instantiate()
	game.campaign_save_enabled = false
	add_child(game)
	await frames()
	game.set_process(false)
	game.set_physics_process(false)
	if not OS.get_cmdline_user_args().has("--story-only"):
		await views()
	if not OS.get_cmdline_user_args().has("--views-only"):
		await story()
	var report := {"result":"PASS" if failures.is_empty() else "FAIL", "screens":visited, "inspected_strings":inspected, "story_cues":cue_count, "failures":failures}
	var suffix := "_views" if OS.get_cmdline_user_args().has("--views-only") else ("_story" if OS.get_cmdline_user_args().has("--story-only") else "")
	var file := FileAccess.open(directory.path_join("runtime_report" + suffix + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	game.queue_free()
	await frames(3)
	print("FULL_ENGLISH_RUNTIME_TEST: %s (%d strings, %d cues, %d issues)" % [report.result, inspected, cue_count, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func views() -> void:
	await shot("title")
	game._debug_skip_onboarding()
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.story_feature_enabled = false
	GameState.player_name = "Aster"
	for day in range(1,31):
		GameState.day = day
		game._set_screen(C.SCREEN_MANAGEMENT, false)
		await shot("day_%02d_management" % day, day in [1,10,20,30])
	GameState.day = 16
	for target in [C.SCREEN_MONSTER,C.SCREEN_MEMORY_ARCHIVE,C.SCREEN_CAMPAIGN_MODE,C.SCREEN_FRONT_SELECTION,C.SCREEN_HEART_SELECTION,C.SCREEN_DUO_LINK_LOADOUT,C.SCREEN_REGION_SELECTION,C.SCREEN_OUTPOST_MANAGEMENT,C.SCREEN_UPPER_FLOOR,C.SCREEN_CHRONICLE,C.SCREEN_CYCLE_DOCTRINE,C.SCREEN_CYCLE_DECREE,C.SCREEN_CHALLENGE_SEAL,C.SCREEN_CONTRACT_BOARD,C.SCREEN_RAID,C.SCREEN_ENDING_ARCHIVE,C.SCREEN_NAME_ENTRY]:
		var saved_run: Dictionary = game.update4_active_run.duplicate(true)
		if target == C.SCREEN_REGION_SELECTION:
			GameState.day = 4
			game.update4_active_run = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd").fresh_update4_active_run("council_season", 2, 404, {})
		game._set_screen(target, false)
		await shot(str(target))
		if target == C.SCREEN_REGION_SELECTION:
			var regions := game.ui_layer.find_child("EnglishRegionScroll", true, false) as ScrollContainer
			if regions != null:
				regions.scroll_vertical = 652
				await shot("region_selection_lower")
			game.update4_active_run = saved_run
			GameState.day = 16
		if target == C.SCREEN_CHRONICLE:
			var chronicle = game.ui_layer.find_child("ChronicleScreen", true, false)
			if chronicle != null:
				for tab in range(4):
					chronicle.active_tab = tab
					chronicle._build()
					if tab < 3:
						for section in range(chronicle._sections(tab).size()):
							chronicle._select_section(section)
							await shot("chronicle_%d_section_%d" % [tab,section])
					else:
						await shot("chronicle_tab_%d" % tab)
	for category in ["general","display","audio"]:
		game.settings_category = category
		game._set_screen(C.SCREEN_SETTINGS, false)
		await shot("settings_" + category)
	GameState.day = 2
	game.pending_precombat_snapshot = game.combat_scene.build_precombat_snapshot(false)
	for target in [C.SCREEN_INTRUSION_BRIEF,C.SCREEN_DEFENSE_START,C.SCREEN_RAID_PREVIEW,C.SCREEN_ENDING]:
		game.defense_start_remaining = 3.0
		game._set_screen(target, false)
		await shot(str(target))
	game.result_summary = {"win":false,"metrics":{"alive_monsters":1,"total_monsters":3,"treasure_gold_stolen":40,"facility_disables":2},"v122_ledger":{"throne_damage":125,"gold_stolen":40,"breach_progress":0.8,"final_breach_segment":"병영 → 왕좌 전실"}}
	game._set_screen(C.SCREEN_RESULT, false)
	await shot("result_defeat")
	game.result_summary = {"win":true,"metrics":{"alive_monsters":3,"total_monsters":3}}
	game.rewards_pending = {"gold":60,"mana":20,"food":10,"infamy":5}
	game._set_screen(C.SCREEN_RESULT, false)
	await shot("result_win")
	game._set_screen(C.SCREEN_MANAGEMENT, false)
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game._start_combat()
	await frames()
	if game.monster_units.is_empty():
		issue("combat", "fixture", "No live monsters", "Actual combat must start", "GameRoot")
	game._spawn_ready_enemies(0.2)
	game.combat_paused = true
	game._set_screen(C.SCREEN_COMBAT, false)
	await shot("combat")
	for control in game.ui_layer.get_children():
		if control is Control: control.hide()
	var outpost = preload("res://scenes/outpost/OutpostBattleRoot.tscn").instantiate()
	outpost.setup({"type_id":"outpost_supply_burrow","level":1,"current_hp":400,"max_hp":400,"assigned_monster_ids":["mon_core_pudding","mon_core_gob","mon_core_pynn"]}, DataRegistry.update4_outpost_encounters.get("outpost_fixed_four_modules", {}), DataRegistry.update4_outpost_types.get("outpost_supply_burrow", {}), ["푸딩","곱","핀"], 10)
	game.ui_layer.add_child(outpost)
	outpost.set_process(false)
	await shot("outpost_battle")
	outpost.debug_complete(false)
	await shot("outpost_defeat")
	outpost._retry()
	outpost.debug_complete(true)
	await shot("outpost_victory")
	outpost.queue_free()
	game.combat_story_feed.clear()
	game.story_director.reset_for_new_game()
	game.story_feature_enabled = true
	print("ENGLISH_VIEWS_AUDITED: %d" % visited.size())

func story() -> void:
	game.onboarding_enabled = false
	game.tutorial_gate_enabled = false
	game.tutorial_manager.active = false
	game.story_combat_overlay_open = false
	game.combat_story_feed.clear()
	GameState.player_name = "Aster"
	var catalog = game.story_catalog
	for id in catalog.all_scene_ids():
		var scene: Dictionary = catalog.scene(id)
		GameState.day = int(scene.day)
		game.story_director.reset_for_new_game()
		# Include every authored branch for presentation coverage, regardless of save flags.
		game.story_director.current_scene_id = str(id)
		game.story_director._active_cues.assign(scene.cues)
		for index in range(scene.cues.size()):
			game.story_director.cursor = index
			game.story_director.current_cue_id = str(scene.cues[index].id)
			game._set_screen(C.SCREEN_DIALOGUE, false)
			await frames(2)
			var body: RichTextLabel = game.ui_layer.find_child("StoryDialogueText", true, false)
			var expected := LanguageSettings.story_text(scene.cues[index], "Aster")
			if body == null or body.text != expected:
				issue(str(id), "story_binding", str(scene.cues[index].id), expected, "StoryDialogueText")
			elif body.get_content_height() > body.size.y + 2:
				issue(str(id), "story_overflow", str(scene.cues[index].id), expected, str(body.get_path()))
			cue_count += 1
			if index == 0:
				await shot(str(id), int(scene.day) in [1,10,20,30] and str(id).contains("MANAGEMENT"))
		print("ENGLISH_STORY_AUDITED: %s (%d total cues)" % [id,cue_count])
	if cue_count != 1741:
		issue("story", "coverage", str(cue_count), "1741", "catalog")
