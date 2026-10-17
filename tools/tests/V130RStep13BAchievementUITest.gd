extends Node
const OUT := "res://_mockup/game_step13b_ach_ui/"
var checks := 0
var failures: Array = []
var layouts: Array = []
var screen: CanvasLayer
var game: Node
var profile_before := ""
var pixel_result := {}

func expect(ok: bool, title: String) -> void:
	checks += 1
	if not ok: failures.append(title); print("FAIL ",title)

func frames(n := 4) -> void:
	for i in n: await get_tree().process_frame

func _ready() -> void: run.call_deferred()

func open() -> void:
	AchievementService.open_screen(); await frames()
	screen = AchievementService.get_child(AchievementService.get_child_count()-1)

func close() -> void:
	screen.queue_free(); await frames()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	AchievementService.storage_enabled = false
	AchievementService.profile = {"version":1,"unlocked":{"ACH_FIRST_NIGHT":1792281600},"stats":{"STAT_TRAPS_PLACED":27},"unique":{},"pending":{},"pending_stats":{}}
	AchievementService.dirty = false
	profile_before = JSON.stringify(AchievementService.profile)
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	ProjectSettings.set_setting("debug/start_flow14",true)
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
	add_child(game); await frames(5); game.set_physics_process(false)
	LanguageSettings.set_locale("ko",false); game.start_flow.open_menu(); await frames()
	var entry := game.ui_layer.find_child("TitleAchievementsButton",true,false) as Button
	expect(entry != null and not entry.disabled,"actual start menu achievement entry")
	entry.pressed.emit(); await frames()
	screen = AchievementService.get_child(AchievementService.get_child_count()-1)
	expect(screen.page.name == "AchievementPage","actual entry opens screen")
	await close()
	# Every card in all eight collections, including offscreen rows, in all three languages.
	for locale in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(locale,false); await open()
		expect(screen.tabs.size() == 8,"eight tabs "+locale)
		for definition in AchievementService.catalog.sets:
			screen.select(definition.id); await frames(); inspect_layout(locale,definition.id)
			var selected: Button = screen.tabs[AchievementService.catalog.sets.find(definition)]
			var total := 0; var earned := 0
			for row in AchievementService.catalog.achievements:
				if row.set == definition.id:
					total += 1
					if AchievementService.profile.unlocked.has(row.api_name): earned += 1
			expect(selected.text.ends_with("%d / %d" % [earned,total]),"correct set progress "+locale+" "+definition.id)
			expect(selected.button_pressed,"selected set state "+definition.id)
		screen.select("base_campaign"); await frames()
		await capture("menu_"+{"ko":"ko","en":"en","zh_CN":"zh"}[locale])
		await close()
	LanguageSettings.set_locale("ko",false); await open()
	await verify_pixels()
	screen.select("castle_builder"); await frames()
	var unlocked_id := str(AchievementService.catalog.achievements.filter(func(row): return row.set == "castle_builder" and row.progress_stat == null)[0].api_name)
	AchievementService.profile.unlocked[unlocked_id] = 1792281600
	screen.refresh(); await frames()
	var dates: Array = screen.page.find_children("UnlockDate","Label",true,false)
	expect(not dates.is_empty() and dates[0].text.contains("2026-10-18"),"unlock date displayed")
	var bars: Array = screen.page.find_children("AchievementProgress","TextureProgressBar",true,false)
	expect(not bars.is_empty(),"GPT HP C progress frames present")
	var partial := false
	for bar in bars:
		if bar.value == 27 and bar.max_value == 50: partial = true
	expect(partial,"partial progress 27/50")
	await capture("locked_vs_unlocked")
	AchievementService.profile.unlocked.ACH_TRAPS_50 = 1792281600
	screen.refresh(); await frames()
	var completed: Node = screen.list.get_node("ACH_TRAPS_50")
	expect(completed.find_child("AchievementProgress",true,false).value == 50,"unlocked progress shows completed total")
	expect(completed.find_child("UnlockDate",true,false) != null,"progress achievement also has unlock date")
	AchievementService.profile.unlocked.erase("ACH_TRAPS_50")
	AchievementService.profile.unlocked.erase(unlocked_id)
	screen.select("challenge_and_secret"); await frames()
	var hidden_count := 0
	for row in AchievementService.catalog.achievements:
		if row.set != "challenge_and_secret" or not row.hidden: continue
		hidden_count += 1
		var card: Node = screen.list.get_node(str(row.api_name))
		expect(card.find_child("AchievementName",true,false).text == "???","secret title concealed "+row.api_name)
		expect(card.find_child("AchievementIcon",true,false).texture.resource_path.ends_with("/question.png"),"secret question icon "+row.api_name)
		expect(not all_text(card).contains(str(row.name_ko)),"secret real title absent "+row.api_name)
		expect(card.find_children("AchievementProgress","TextureProgressBar",true,false).is_empty(),"secret progress concealed "+row.api_name)
	expect(hidden_count == 7,"seven concealed secrets in challenge set")
	# Put the first secret into view for the requested representative image.
	var scroll := screen.list.get_parent() as ScrollContainer
	scroll.scroll_vertical = int(screen.list.get_node("ACH_SECRET_BUCKET").position.y); await frames()
	await capture("hidden")
	AchievementService.profile.unlocked.ACH_SECRET_BUCKET = 1792281600
	screen.refresh(); await frames()
	var revealed: Node = screen.list.get_node("ACH_SECRET_BUCKET")
	expect(revealed.find_child("AchievementName",true,false).text != "???","unlocked secret reveals title")
	expect(not revealed.find_child("AchievementIcon",true,false).texture.resource_path.ends_with("/question.png"),"unlocked secret reveals original icon")
	AchievementService.profile.unlocked.erase("ACH_SECRET_BUCKET")
	# Language button callback preserves the collection and remains in memory-only profile.
	screen.change_language("en"); await frames()
	screen = AchievementService.get_child(AchievementService.get_child_count()-1)
	expect(screen.selected_set == "challenge_and_secret","language switch preserves selected set")
	expect(screen.page.find_child("AchievementBack",true,false).text == "Back  ·  ESC","actual language switch relabels buttons")
	var escape := InputEventKey.new(); escape.pressed = true; escape.keycode = KEY_ESCAPE
	screen._input(escape); await frames(); expect(not is_instance_valid(screen),"ESC closes screen")
	expect(JSON.stringify(AchievementService.profile) == profile_before,"screen leaves profile unchanged")
	game._shutdown_audio_for_exit(); game.campaign_autosave_pending = false; game.queue_free(); await frames()
	var result := {"checks":checks,"failures":failures,"layouts":layouts,"locked_pixels":pixel_result,"profile_unchanged":JSON.stringify(AchievementService.profile) == profile_before}
	var file := FileAccess.open(OUT+"checks.json",FileAccess.WRITE); file.store_string(JSON.stringify(result,"\t")); file.close()
	print("STEP13B checks=",checks," failures=",failures.size()," layouts=",layouts.size())
	get_tree().quit(0 if failures.is_empty() else 1)

func inspect_layout(locale: String, set_id: String) -> void:
	var issues: Array = []
	var text_count := 0
	for node in screen.page.find_children("*","Control",true,false):
		if node is Label:
			text_count += 1
			var required: Vector2 = node.get_minimum_size()
			if required.x > node.size.x+1 or required.y > node.size.y+1: issues.append(node.text)
			if node.get_parent() is VBoxContainer and node.get_parent().get_parent() is HBoxContainer:
				var card := node.get_parent().get_parent().get_parent() as Control
				if card is PanelContainer and node.get_global_rect().end.x > card.get_global_rect().end.x-12: issues.append("card text outside "+node.text)
		elif node is Button:
			text_count += 1
			var font: Font = node.get_theme_font("font")
			var measured := font.get_multiline_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,node.get_theme_font_size("font_size"))
			if measured.x > node.size.x-36 or measured.y > node.size.y-16: issues.append("button "+node.text)
			if node.get_global_rect().end.y > 1044: issues.append("button below viewport "+node.text)
	layouts.append({"locale":locale,"set":set_id,"texts":text_count,"issues":issues})
	expect(issues.is_empty(),"text fit "+locale+" "+set_id+" "+str(issues))

func all_text(node: Node) -> String:
	var result := str(node.text) if node is Label else ""
	for child in node.get_children(): result += all_text(child)
	return result

func verify_pixels() -> void:
	# Compare the same opaque icon region with and without the locked shader on the GPU.
	screen.select("base_campaign"); await frames(); await RenderingServer.frame_post_draw
	var card: Node = screen.list.get_node("ACH_FIRST_NIGHT")
	var icon := card.find_child("AchievementIcon",true,false) as TextureRect
	var rect := Rect2i(get_viewport().get_final_transform() * icon.get_global_rect())

	var original := get_viewport().get_texture().get_image().get_region(rect)
	AchievementService.profile.unlocked.erase("ACH_FIRST_NIGHT"); screen.refresh(); await frames(); await RenderingServer.frame_post_draw
	var locked := get_viewport().get_texture().get_image().get_region(rect)
	var max_error := 0.0; var samples := 0; var chroma := 0.0
	for y in range(10,40,2):
		for x in range(10,40,2):
			var source := original.get_pixel(x,y); var grey := (source.r*.299+source.g*.587+source.b*.114)*.35
			var actual := locked.get_pixel(x,y)
			max_error = maxf(max_error,absf(actual.r-grey))
			chroma = maxf(chroma,maxf(absf(actual.r-actual.g),absf(actual.g-actual.b))); samples += 1
	expect(max_error < .025,"GPU locked luminance is original grayscale times 35%")
	expect(chroma < .01,"GPU locked saturation zero")
	pixel_result = {"samples":samples,"max_luminance_error":max_error,"max_chroma":chroma}
	AchievementService.profile.unlocked.ACH_FIRST_NIGHT = 1792281600
	screen.refresh(); await frames()

func capture(id: String) -> void:
	await frames(); await RenderingServer.frame_post_draw
	var picture := get_viewport().get_texture().get_image(); picture.resize(1280,720,Image.INTERPOLATE_LANCZOS)
	expect(picture.save_png(OUT+id+".png") == OK,"capture "+id)
