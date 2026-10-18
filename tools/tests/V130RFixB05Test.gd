extends Node
## Real UI builders and input, isolated by run_v130r_b05.py. No personal saves.
const OUT := "res://tmp/v130r_b05/"
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const Food = preload("res://scripts/systems/MonsterFoodService.gd")
var game: Node
var checks := 0
var failures: Array = []
var korean: Array = []
var overflow: Array = []
var texts: Array = []
var language := "en"
var hangul := RegEx.new()
func _ready() -> void: run.call_deferred()
func frames(n: int = 5) -> void:
	for i in n: await get_tree().process_frame
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL ",message)
func no_korean(value: String, context: String) -> void:
	checks += 1
	if hangul.search(value)!=null: korean.append({"locale":language,"context":context,"text":value})
func scan(node: Node, screen: String) -> void:
	if node is Control and node.is_visible_in_tree():
		var value := ""
		if node is Label or node is Button or node is RichTextLabel or node is LineEdit:
			value = str(node.text)
			# Godot's translated label is what reaches the viewport.
			value = node.tr(value) if node.can_auto_translate() else value
			no_korean(value,screen+":"+str(node.get_path()))
			texts.append({"screen":screen,"path":str(node.get_path()),"text":value})
		if not node.tooltip_text.is_empty(): no_korean(LanguageSettings.ui_text(node.tooltip_text),screen+":tooltip:"+str(node.get_path()))
		if node is Label and not value.strip_edges().is_empty():
			var font: Font = node.get_theme_font("font")
			var px: int = node.get_theme_font_size("font_size")
			var height: float = node.get_line_count()*font.get_height(px)
			var width := 0.0
			if node.autowrap_mode==TextServer.AUTOWRAP_OFF:
				for line in value.split("\n"): width = maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x)
			var slot_width: float=float(node.get_meta("localized_slot_width",node.size.x))
			if height>node.size.y+3 or ((node.clip_text or node.has_meta("localized_slot_width")) and width>slot_width+3):
				overflow.append({"locale":language,"screen":screen,"path":str(node.get_path()),"text":value,"size":str(node.size),"width":width,"height":height})
	for child in node.get_children(): scan(child,screen)
func capture(id: String) -> void:
	await frames(8)
	scan(game.ui_layer,id)
	scan(AchievementService,id)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.resize(1280,720,Image.INTERPOLATE_LANCZOS)
		expect(img.save_png(OUT+language+"_"+id+".png")==OK,"capture "+language+" "+id)
func press(id: String) -> void:
	var target := game.ui_layer.find_child(id,true,false) as BaseButton
	expect(target!=null and not target.disabled,"input target "+id)
	if target!=null and not target.disabled:
		# Same public action signal as normal GUI activation, paired with keyboard
		# input for the prologue/dialogue flow. No direct writes to screen state.
		target.pressed.emit()
	await frames(5)
func space() -> void:
	var event := InputEventKey.new(); event.pressed=true; event.keycode=KEY_SPACE; event.physical_keycode=KEY_SPACE
	game._input(event); await frames(3)
func dismiss() -> void:
	for i in 200:
		await frames(2)
		if game.current_screen!="dialogue": return
		await space()
	expect(false,"dialogue finishes")
func view() -> Node: return game.ui_layer.get_node_or_null("ApprovedMapManagement")
func catalog_checks() -> void:
	var catalogs := {"monsters":DataRegistry.monsters,"enemies":DataRegistry.enemies,"hpbar_names":DataRegistry.monster_instances,"skills":DataRegistry.skills,"specializations":DataRegistry.specializations}
	for category in catalogs:
		for id in catalogs[category]:
			var row: Dictionary = catalogs[category][id]
			for field in ["display_name","description","short_effect"]:
				if row.get(field) is String: no_korean(LanguageSettings.ui_text(row[field]),category+":"+str(id)+":"+field)
	for key in LanguageSettings.catalog_keys():
		if key.begins_with("map."):
			expect(key not in LanguageSettings.missing_keys(language),"key present "+key)
			no_korean(LanguageSettings.text(key),key)
	# Every original priority candidate, even nonvisual diagnostics, has a translation.
	var inventory: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tools/tests/v130r_b05_inventory.json"))
	expect(inventory.size()==144,"all 144 priority candidates accounted for")
	for item in inventory: no_korean(LanguageSettings.text(item.key),"priority:"+str(item.index))
	# 0089a name mapping remains authoritative at every presentation boundary.
	var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/v130r/story/speaker_registry.json"))
	for species in registry.species_names:
		var names: Dictionary = registry.species_names[species]
		var locale_key := "zh_cn" if language=="zh_CN" else language
		expect(LanguageSettings.ui_text(names.ko)==names[locale_key],"0089a name "+species)
func locale_run(locale: String) -> void:
	language=locale; LanguageSettings.set_locale(locale,false)
	game=load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled=false; game.campaign_auxiliary_save_enabled=false
	game.campaign_save_v5_enabled=false; game.campaign_save_v6_enabled=false
	add_child(game); await frames(8); seed(130013)
	game.set_physics_process(false)
	await capture("title")
	await press("TitleStartButton"); await capture("menu")
	await press("CampaignNewGameButton"); await capture("prologue")
	for i in 7: await space()
	await press("NamingNext"); await press("NamingNext")
	expect(game.onboarding_name_input!=null,"name input reached")
	await capture("name")
	game.onboarding_name_input.text="Arden"; game._onboarding_name_changed("Arden")
	await press("ConfirmNameButton"); await dismiss(); await frames(12)
	expect(view()!=null,"new map reached")
	if view()==null: return
	await capture("management")
	game.start_flow.fresh=false; game.start_flow.guide_step=5; game.start_flow.command_seen=true; game.start_flow.intro_complete=true
	game.start_flow.guide_key=""; game.start_flow.clear_guide()
	if is_instance_valid(game.start_flow.guide): game.start_flow.guide.hide()
	var v := view()
	v.monster_ui.set_mode("build")
	v.begin_build("spikes"); await capture("construction"); v.cancel_build()
	for id in v.placement.buildings.map(func(b): return b.id):
		v.selected_id=id; v.show_info("menu_info"); await frames(3); scan(game.ui_layer,"building:"+str(id)); v.clear_context()
	v.monster_ui.set_mode("place"); v.monster_ui.auto_place(); await frames()
	await capture("deployment")
	v.monster_ui.unlock_all=true
	for id in v.monster_ui.unlocked():
		v.monster_ui.show_info(id); await frames(4); scan(game.ui_layer,"monster:"+str(id)); v.monster_ui.close_info()
	v.monster_ui.unlock_all=false
	game.story_feature_enabled=false; game.onboarding_enabled=false; game.tutorial_gate_enabled=false; game.tutorial_manager.active=false
	var start_ok: bool=v.start_battle(); await frames(8)
	expect(start_ok and v.battle!=null,"battle starts")
	if v.battle!=null:
		v.set_physics_process(false)
		v.battle.physics_process(.3)
		for unit in game.monster_units+game.enemy_units: unit.set_physics_process(false)
		v.battle_ui.refresh(); await capture("battle")
		if not game.monster_units.is_empty(): v.battle_ui.select_unit(game.monster_units[0]); await frames(); scan(game.ui_layer,"selected_battle_skill")
		game.start_flow.abandon_battle(v); v.battle=null
	# Explicit ledger fixture tests every settlement branch without a forced campaign victory.
	var ledger: Dictionary = Food.settle(0,1,["slime","goblin","imp"],Food.fresh()).ledger
	ledger.overflow=3
	for line in Food.lines(ledger): no_korean(line,"food ledger")
	var hungry_ledger: Dictionary=Food.settle(0,1,DataRegistry.monsters.keys(),Food.fresh()).ledger
	for line in Food.lines(hungry_ledger): no_korean(line,"hungry food ledger")
	game.result_summary={"victory":true,"day":1,"gold":100,"food":0,"mana":10,"food_ledger":ledger}
	game._set_screen("result",false)
	preload("res://scripts/ui/ApprovedBattleUI.gd").food_result_panel(game)
	await capture("settlement")
	game._open_settings_screen(false); await capture("settings")
	game._set_screen("title",false)
	AchievementService.open_screen(); await frames(); await capture("achievements")
	var achievement := AchievementService.get_children().filter(func(n): return n is CanvasLayer and n.has_method("select"))
	for node in achievement:
		for set_info in AchievementService.catalog.sets:
			node.select(str(set_info.id)); await frames(); scan(node,"achievement_set:"+str(set_info.id))
		node.queue_free()
	# DAY29 remains a preparation day; this test never adds or starts a battle there.
	expect(DataRegistry.waves.get("day_29",[]).is_empty(),"DAY29 has no battle")
	catalog_checks()
	game.campaign_autosave_pending=false; game._shutdown_audio_for_exit()
	game.queue_free(); await frames(6)
func run() -> void:
	hangul.compile("[가-힣ㄱ-ㅎㅏ-ㅣ]")
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	ProjectSettings.set_setting("debug/start_flow14",true)
	for locale in ["en","zh_CN"]: await locale_run(locale)
	expect(korean.is_empty(),"no Korean in tested non-Korean UI/catalogs")
	expect(overflow.is_empty(),"no text overflow in tested screens")
	var file := FileAccess.open(OUT+("headless" if DisplayServer.get_name()=="headless" else "rendered")+"_checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"korean":korean,"overflow":overflow,"texts":texts},"\t")); file.close()
	print("B05_TEST: ",checks," checks; failures=",failures," Korean=",korean.size()," overflow=",overflow.size())
	get_tree().quit(0 if failures.is_empty() else 1)
