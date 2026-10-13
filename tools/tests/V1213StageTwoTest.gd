extends Node

const GameScene = preload("res://scenes/game/GameRoot.tscn")
const Constants = preload("res://scripts/core/Constants.gd")
const Standard = preload("res://scripts/ui/UIStandard.gd")
const OUTPUT := "res://tmp/v1213_s2"
var game: Node
var failures: Array[String] = []
var checks := 0
var audit: Array[Dictionary] = []
var width := 1920
var capture_filter: PackedStringArray = []

func _ready() -> void:
	get_window().gui_embed_subwindows = true
	get_tree().create_timer(180).timeout.connect(func(): get_tree().quit(1))
	call_deferred("run")

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL: " + message)

func settle() -> void:
	for i in range(12): await get_tree().process_frame

func control(id: String) -> Control:
	return game.ui_layer.find_child(id, true, false) as Control

func inspect_node(node: Node, report: Dictionary) -> void:
	if node is Control and node.is_visible_in_tree():
		if node is BaseButton or node is Range or (node is TextureRect and node.mouse_filter != Control.MOUSE_FILTER_IGNORE):
			report.controls.append({"path":str(node.get_path()), "tooltip":LanguageSettings.ui_text(node.tooltip_text)})
			if node.tooltip_text.strip_edges() == "": report.empty_tooltips.append(str(node.get_path()))
			if LanguageSettings.locale != "ko":
				var hangul := RegEx.new()
				hangul.compile("[가-힣]")
				expect(hangul.search(LanguageSettings.ui_text(node.tooltip_text).replace("한국어", "")) == null, "localized tooltip: " + str(node.get_path()))
		if node is Button and not node is OptionButton and node.text.strip_edges() != "":
			var font: Font = node.get_theme_font("font")
			var needed := font.get_multiline_string_size(LanguageSettings.ui_text(node.text),HORIZONTAL_ALIGNMENT_CENTER,-1,node.get_theme_font_size("font_size"))
			if needed.x > node.size.x - 24 or needed.y > node.size.y - 16:
				report.clipped_text.append({"path":str(node.get_path()),"text":LanguageSettings.ui_text(node.text),"size":str(node.size),"needed":str(needed),"kind":"button"})
		if node is Label and node.text.strip_edges() != "":
			var font_size: int = node.get_theme_font_size("font_size")
			if font_size < Standard.SUPPORT_SIZE: report.small_fonts.append({"path":str(node.get_path()), "size":font_size, "text":node.text})
			if node.get_line_count() > node.get_visible_line_count(): report.clipped_text.append({"path":str(node.get_path()), "text":LanguageSettings.ui_text(node.text), "size":str(node.size), "font":font_size, "lines":node.get_line_count(), "visible":node.get_visible_line_count()})
		if node is RichTextLabel and node.text.strip_edges() != "":
			var font_size: int = node.get_theme_font_size("normal_font_size")
			if font_size < Standard.SUPPORT_SIZE: report.small_fonts.append({"path":str(node.get_path()), "size":font_size, "text":node.text})
			if not node.scroll_active and node.get_content_height() > node.size.y + 1: report.clipped_text.append({"path":str(node.get_path()),"text":node.text,"size":str(node.size),"height":node.get_content_height()})
	for child in node.get_children(): inspect_node(child, report)

func snapshot(id: String) -> void:
	await settle()
	var report := {"screen":id,"locale":LanguageSettings.locale,"width":width,"controls":[],"empty_tooltips":[],"small_fonts":[],"clipped_text":[]}
	inspect_node(game.ui_layer, report)
	inspect_node(game.unit_root, report)
	inspect_node(game.effect_root, report)
	audit.append(report)
	expect(report.empty_tooltips.is_empty(), "%s/%s empty tooltips: %s" % [LanguageSettings.locale,id,report.empty_tooltips])
	expect(report.small_fonts.is_empty(), "%s/%s fonts below 18: %s" % [LanguageSettings.locale,id,report.small_fonts])
	expect(report.clipped_text.is_empty(), "%s/%s clipped text: %s" % [LanguageSettings.locale,id,report.clipped_text])
	if DisplayServer.get_name() != "headless" and (capture_filter.is_empty() or capture_filter.has(id)):
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		print("CAPTURE %s/%s window=%s texture=%s logical=%s" % [LanguageSettings.locale,id,DisplayServer.window_get_size(),image.get_size(),get_viewport().get_visible_rect().size])
		var name := "%s_%d_%s" % [LanguageSettings.locale,width,id]
		if width == 2560:
			expect(DisplayServer.window_get_size() == Vector2i(2560,1080), "actual ultrawide window size")
			expect(image.get_size() == Vector2i(1920,1080), "keep-aspect ultrawide content retains 16:9")
			image.save_png(OUTPUT.path_join(name + "_content.png"))
			# Keep-aspect windows expose the content texture only. Store the exact
			# content plus engine letterbox margins; this is not an OS screenshot.
			var presentation := Image.create(2560,1080,false,Image.FORMAT_RGBA8)
			presentation.fill(Color.BLACK)
			presentation.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i(320,0))
			presentation.save_png(OUTPUT.path_join(name + ".png"))
		else:
			expect(image.get_size() == Vector2i(1920,1080), "representative 1920 capture")
			image.save_png(OUTPUT.path_join(name + ".png"))

func click(button: BaseButton) -> void:
	expect(button != null, "button exists")
	if button == null: return
	var point := button.get_global_transform_with_canvas() * (button.size / 2)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		get_viewport().push_input(event, true)
	await settle()

func hover(button: BaseButton) -> void:
	if DisplayServer.get_name() == "headless" or button == null: return
	var event := InputEventMouseMotion.new()
	event.position = button.get_global_transform_with_canvas() * (button.size / 2)
	event.global_position = event.position
	get_viewport().push_input(event,true)
	await get_tree().create_timer(0.8).timeout

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").replace("\\", "/").contains("/tmp/v1213_s2/"), "isolated user directory")
	if not failures.is_empty(): get_tree().quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--width="): width = int(arg.trim_prefix("--width="))
		if arg.begins_with("--captures="): capture_filter = arg.trim_prefix("--captures=").split(",")
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(width,1080))
		await settle()
	game = GameScene.instantiate()
	game.campaign_save_enabled = false
	game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false
	game.campaign_save_v5_enabled = false
	add_child(game)
	await settle()
	expect(game.current_screen == Constants.SCREEN_TITLE, "boot starts at official title")
	expect(control("TitleWorkspace") != null and control("UpdateNotesOverlay") == null, "title illustration and menu visible before overlays")
	game.set_process(false); game.set_physics_process(false)
	for locale in ["ko", "en", "zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		game._set_screen(Constants.SCREEN_TITLE,false)
		await snapshot("title")
		await click(control("TitleSettingsButton"))
		for category in ["general", "display", "combat", "audio"]:
			game.settings_category = category
			game._set_screen(Constants.SCREEN_SETTINGS,false)
			await settle()
			if category == "general":
				var languages: OptionButton = control("LanguageOption")
				expect(languages.item_count == 3, locale + " three language choices")
				for i in range(3): expect(languages.get_item_text(i) == ["한국어", "English", "简体中文"][i], locale + " native language name")
				expect(languages.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED, "native language labels exclude automatic translation")
				if DisplayServer.get_name() != "headless":
					var popup: PopupMenu = languages.get_popup()
					popup.popup(Rect2i(970,395,362,160))
					await snapshot("language_choices")
					popup.hide()
			if category == "display":
				game._on_ui_scale_changed(90,null)
				expect(game.settings_text_preview_label.get_theme_font_size("font_size") >= Standard.BODY_SIZE, "live preview maintains body minimum at 90 percent")
				UISettings.set_text_scale(1.0,false)
			await snapshot("settings_" + category)
		game._cancel_settings_changes()
		game.onboarding_enabled = false; game.tutorial_gate_enabled = false
		GameState.day = 7; GameState.gold = 5000; GameState.mana = 5000; GameState.food = 100
		game.management_tool_tab = "build"; game.management_context_drawer_open = false
		game._set_screen(Constants.SCREEN_MANAGEMENT,false)
		await snapshot("management")
		game.selected_room = "barracks"; game.management_context_drawer_open = true
		game._set_screen(Constants.SCREEN_MANAGEMENT,false)
		await settle()
		var upgrade: Button = control("FacilityUpgradeButton")
		expect(upgrade != null and not upgrade.disabled and upgrade.tooltip_text != "", locale + " active upgrade retains tooltip")
		await snapshot("management_inspector")
		await hover(upgrade)
		if DisplayServer.get_name() != "headless": await snapshot("upgrade_tooltip")
		game.management_context_drawer_open = false
		game._set_build_facility("barracks")
		await settle()
		var tested := 0
		for room_id in game.rooms:
			if not bool(game._evaluate_facility_placement(room_id,"barracks").get("ok",false)): continue
			var bounds: Rect2 = game.graph.rect(room_id)
			var transform: Transform2D = game.get_global_transform_with_canvas()
			var anchor := transform * Vector2(bounds.get_center().x,bounds.end.y)
			var label: Rect2 = game._management_label_layout(anchor,game._building_area_label()).rect
			# Test the far visible edge as well as the center, in each locale.
			for point in [label.get_center(),Vector2(label.end.x-2,label.get_center().y)]:
				expect(game.build_placement.target_room(transform.affine_inverse()*point)==room_id, locale+" displayed build label edge hit "+room_id)
			tested += 1
		expect(tested > 0, "localized build candidates exercised")
		await snapshot("build_labels")
		game._cancel_management_action_mode()
		game.story_director.cancel_active_scene()
		expect(game.story_director.start_scene("STORY_D01_MANAGEMENT_ENTRY",game._story_context(),Constants.SCREEN_MANAGEMENT,"",true), "catalogue dialogue fixture")
		game.story_director.set_auto(false)
		game._story_show_active_scene()
		await settle()
		expect(control("StoryCueProgress") == null, "story numbering removed")
		expect((control("StoryAutoButton") as Button).text == "", "auto is an icon")
		await snapshot("dialogue")
		await hover(control("DialogueBacklogButton"))
		if DisplayServer.get_name() != "headless": await snapshot("dialogue_tooltip")
		var cursor: int = game.story_director.cursor
		await click(control("DialogueBacklogButton"))
		expect(game.continuity.backlog_open and game.story_director.cursor == cursor, "icon log opens without advancing dialogue")
		await snapshot("dialogue_log")
		game.continuity.close_backlog()
		await click(control("StoryAutoButton"))
		expect(game.story_director.auto_enabled, "auto icon toggles actual auto mode")
		for cue in game.story_director._active_cues:
			if not game.story_director.seen_cue_ids.has(str(cue.id)): game.story_director.seen_cue_ids.append(str(cue.id))
		game._story_refresh_dialogue_ui()
		await settle()
		expect(control("StorySkipButton") != null, "read dialogue exposes skip icon")
		await snapshot("dialogue_skip")
		await click(control("StorySkipButton"))
		expect(not game.story_director.is_active(), "skip icon completes allowed dialogue")
		game.story_director.cancel_active_scene()
		game.onboarding_dialogue_queue = [{"speaker":"CHR_BATI", "speaker_name":"바티", "text":"테스트 대사", "text_ko":"테스트 대사"}]
		game._set_screen(Constants.SCREEN_DIALOGUE,false)
		await snapshot("legacy_dialogue")
		game.onboarding_dialogue_queue.clear()
		game._set_screen(Constants.SCREEN_MANAGEMENT,false)
		await click(control("CommonGameMenuButton"))
		expect(game.pause_menu_open, "common menu icon opens menu")
		await snapshot("menu")
		await click(control("PauseResumeButton"))
		expect(not game.pause_menu_open, "resume icon closes menu")
		game._set_screen(Constants.SCREEN_COMBAT,false)
		await snapshot("combat_hud")
		game.combat_scene.start_combat()
		game.combat_scene.set_pause_state(true,false)
		for unit in game.unit_root.get_children(): unit.set_physics_process(false)
		var units: Array[Node] = game.unit_root.get_children()
		expect(not units.is_empty(), "combat inspector uses an actual unit")
		if not units.is_empty():
			game.selected_unit = units[0]
			game._set_screen(Constants.SCREEN_COMBAT,false)
			await snapshot("combat_inspector")
		game._show_combat_command_feedback(false,game.continuity.localized("명령 포인트 부족", "Not enough command points", "指令点数不足"),game.continuity.localized("남은 명령 포인트를 확인하고 다른 행동을 선택하세요.", "Check remaining command points and choose another action.", "请查看剩余指令点数并选择其他行动。"))
		game.combat_scene.spawn_growth_preparation_feedback(Vector2(900,460),game.continuity.localized("공격 준비", "Attack preparation", "攻击准备"))
		await snapshot("combat_feedback")
		game.selected_unit = null
		game.result_summary = {"win":true,"day":7,"damage_to_castle":0,"enemies_defeated":3,"v122_ledger":{}}
		game._set_screen(Constants.SCREEN_RESULT,false)
		await snapshot("result")
		game.selected_monster_id = "slime"
		game._set_screen(Constants.SCREEN_MONSTER,false)
		await snapshot("growth")
		await additional_tooltip_screens()
	var file := FileAccess.open(OUTPUT.path_join("audit_%d_%s.json" % [width,DisplayServer.get_name()]),FileAccess.WRITE)
	file.store_string(JSON.stringify(audit,"\t")); file.close()
	print("V1213 S2 checks=%d failures=%d" % [checks,failures.size()])
	game.queue_free(); await settle()
	get_tree().quit(0 if failures.is_empty() else 1)

func additional_tooltip_screens() -> void:
	game._set_screen(Constants.SCREEN_MANAGEMENT,false)
	var crown := preload("res://scripts/ui/CrownCandidatePanel.gd").new()
	crown.name = "CrownTooltipFixture"
	crown.position = Vector2(680,350)
	game.ui_layer.add_child(crown)
	crown.configure([{"display_name":game._monster_companion_name("slime"),"instance_id":"slime"}])
	await snapshot("crown_candidates")
	game.ui_layer.remove_child(crown); crown.queue_free()
	for action in ["council_vote","council_crown","council_final_declaration"]:
		var council := preload("res://scripts/ui/Update4CouncilDecisionOverlay.gd").new()
		council.name = "CouncilTooltipFixture"
		game.ui_layer.add_child(council)
		var catalogs := {"council_agendas":DataRegistry.update4_council_agendas,"rival_lords":DataRegistry.update4_rival_lords,"crown_evolutions":DataRegistry.update4_crown_evolutions}
		var candidates: Array = []
		if action == "council_crown":
			var crown_id: String = DataRegistry.update4_crown_evolutions.keys()[0]
			candidates.append({"display_name":game._monster_companion_name("slime"),"instance_id":"slime","crown_form_id":crown_id})
		council.setup(action,13 if action == "council_vote" else 18,{"council_season":{"council_seals":2}},catalogs,candidates)
		expect(council.find_children("*","Button",true,false).size() > 0, "council tooltip fixture includes real choices")
		await snapshot(action)
		game.ui_layer.remove_child(council); council.queue_free()
	game._set_screen(Constants.SCREEN_COMBAT,false)
	var presentation = game.combat_scene.skill_actions
	presentation.current = {"name":LanguageSettings.ui_text("빠른 베기"),"actors":[],"kind":"skill"}
	presentation._build_stage()
	presentation.stage.set_process(false)
	await settle()
	var skip: Button = game.effect_root.find_child("SkillActionSkipButton",true,false)
	expect(skip != null and skip.tooltip_text != "", "skill presentation skip has localized explanation")
	await snapshot("skill_presentation")
	presentation.stage.queue_free(); presentation.current.clear(); presentation.stage = null
