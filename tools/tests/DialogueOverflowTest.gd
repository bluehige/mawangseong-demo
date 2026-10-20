extends Node
## Measure the same controls/fonts used by the game, in isolated user storage.
const OUT := "res://tmp/dialogue_overflow/"
const Fonts = preload("res://scripts/ui/UIFont.gd")
const TextLayout = preload("res://scripts/ui/DialogueLayout.gd")
var game: Node
var phase := "before"
var corpus: Array
var profiles: Dictionary = {}
var counts: Dictionary = {}
var violations: Array = []
var checks := 0
var failures: Array = []
var samples: Dictionary = {}
var profile_snapshots: Dictionary = {}

func _ready() -> void: run.call_deferred()
func frames(n: int = 5) -> void:
	for i in n: await get_tree().process_frame
func expect(ok: bool, detail: String) -> void:
	checks += 1
	if not ok: failures.append(detail)
func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(OUT+path,FileAccess.WRITE)
	file.store_string(JSON.stringify(value,"\t"))
func clear() -> void:
	for child in game.ui_layer.get_children(): child.free()
	game.continuity.backlog_open = false
func text_for(row: Dictionary, locale: String) -> String:
	var raw: String = row.text
	if row.key == "text_key": raw = LanguageSettings.text(raw)
	elif row.key == "text_ko" and LanguageSettings.localized_story_catalogs.get(locale,{}).get("cues",{}).has(row.id):
		raw = str(LanguageSettings.localized_story_catalogs[locale].cues[row.id])
	elif str(row.locale) == "": raw = LanguageSettings.ui_text(raw)
	for token in ["{{player_name}}","{name}","{player_name}","{player}","{darklord_name}","<PLAYER_NAME>"]:
		raw = raw.replace(token,"W".repeat(12))
	return raw
func relevant(row: Dictionary, locale: String) -> bool:
	return str(row.locale) == "" or str(row.locale).to_lower() == locale.to_lower()
func save_profile(id: String, control: Control, parent: Control, scrolling: bool = false) -> void:
	profiles[id] = {"control":control,"parent":parent,"scroll":scrolling}
func build_profiles() -> void:
	clear(); profiles.clear()
	var screen: Control = game._onboarding_screen_panel(Color("#08060d"))
	game.story_presenter._build_shared_frame(screen,"CHR_BATI","W".repeat(12),"dry","Sample",false,true)
	await frames(10)
	save_profile("dialogue",screen.find_child("DialogueText",true,false),screen.find_child("DialogueTextPanel",true,false),true)
	save_profile("speaker",screen.find_child("DialogueSpeakerLabel",true,false),screen.find_child("DialogueTextPanel",true,false))
	# A second real presenter instance for combat cutscenes.
	var overlay: Control = game._onboarding_screen_panel(Color.TRANSPARENT)
	game.story_presenter._build_shared_frame(overlay,"CHR_BATI","W".repeat(12),"dry","Sample",true,false)
	await frames(10)
	save_profile("cutscene_combat",overlay.find_child("StoryDialogueText",true,false),overlay.find_child("StoryDialogueTextPanel",true,false),true)
	var feed: Control = game.hud.panel(Rect2(32,112,1080,160),Color("#0b0e18ec"),Color("#655578"),"AuditFeed","flat")
	game.hud.label(feed,"W".repeat(12),Vector2(132,12),Vector2(912,32),22)
	var feed_label: Label = game.hud.label(feed,"Sample",Vector2(132,48),Vector2(912,96),23)
	save_profile("combat_feed",feed_label,feed)
	game.v130r_story.victory_cue = {"speaker_label":"W".repeat(12),"text":"Sample"}
	game.v130r_story.show_victory(game)
	var victory: Control = game.ui_layer.get_node_or_null("V130RVictoryBark")
	if victory == null:
		for child in game.ui_layer.get_children():
			if child is Panel and child.position == Vector2(32,112) and child.size.y == 112: victory = child
	if victory != null:
		var labels := victory.get_children().filter(func(n): return n is Label)
		save_profile("victory_bark",labels.back(),victory)
	var intro: Control = game.start_flow.raster_panel(screen,Rect2(310,400,1300,285),"AuditIntro")
	save_profile("naming",game.start_flow.label(intro,"Sample",Rect2(42,82,1216,100),32,"AuditNameTalk"),intro)
	var form_note: Control = game.hud.child_panel(screen,Rect2(100,758,630,190),Color.BLACK,Color.WHITE)
	save_profile("naming_form",game.management_scene.workspace_ui.copy(form_note,"Sample",Rect2(28,65,570,100),24),form_note)
	var guide: Control = game.start_flow.raster_panel(screen,Rect2(42,180,720,290),"AuditGuide")
	save_profile("first_day",game.start_flow.label(guide,"Sample",Rect2(28,65,664,135),25,"AuditGuideText"),guide)
	var tutorial: Control = game.hud.child_panel(screen,Rect2(400,180,760,220),Color.BLACK,Color.WHITE)
	save_profile("tutorial",game.hud.rich_label(tutorial,"Sample",Vector2(24,52),Vector2(712,74),22),tutorial)
	save_profile("tutorial_observation",game.hud.rich_label(tutorial,"Sample",Vector2(24,48),Vector2(652,92),17),tutorial)
	var prologue: Label = game.start_flow.label(screen,"Sample",Rect2(270,400,1380,250),38,"AuditPrologue")
	save_profile("prologue",prologue,screen)
	game.continuity.history.clear(); game.continuity.history.append({"day":1,"speaker":"W".repeat(12),"text":"Sample"})
	game.continuity.open_backlog(); await frames(8)
	var scroll: ScrollContainer = game.ui_layer.find_child("DialogueBacklogScroll",true,false)
	save_profile("log",scroll.get_child(0).get_child(0),scroll,true)
	var result: Control = game.hud.child_panel(screen,Rect2(200,200,1000,400),Color.BLACK,Color.WHITE)
	# Result and daily-report flowing text uses the shared kit's actual factory.
	var report: Label = game.management_scene.workspace_ui.kit_copy(result,"Sample",Rect2(24,30,952,300),24)
	save_profile("result_daily",report,result,true)
	var choice: Button = game.hud.button(result,"Sample",Rect2(24,330,740,68),Callable(),20,"AuditChoice")
	save_profile("choice",choice,result)
	var event_card: Control = game.hud.child_panel(screen,Rect2(460,170,1000,740),Color.BLACK,Color.WHITE)
	save_profile("event_body",game.hud.rich_label(event_card,"Sample",Vector2(100,190),Vector2(800,128),21,Color.WHITE,"dialogue",TextServer.AUTOWRAP_WORD_SMART,VERTICAL_ALIGNMENT_CENTER),event_card)
	var food = preload("res://scripts/systems/MonsterFoodService.gd")
	var ledger: Dictionary = food.settle(0,30,food.COSTS.keys(),food.fresh()).ledger
	game.result_summary["food_ledger"]=ledger
	preload("res://scripts/ui/ApprovedBattleUI.gd").food_result_panel(game)
	var food_panel: Control = game.ui_layer.get_node("FoodSettlementPanel")
	save_profile("food_daily",food_panel.get_node("FoodSettlementDetails"),food_panel,true)
	AchievementService.toast.queue.append(str(AchievementService.catalog.achievements[0].api_name)); AchievementService.toast.show_next()
	var toast: Control = AchievementService.toast.current
	save_profile("achievement",toast.get_child(3),toast)
	await frames(55)
	for id in profiles:
		var p: Dictionary = profiles[id]; var c: Control = p.control
		p["width"] = c.size.x; p["height"] = c.size.y
		p["font_size"] = c.get_theme_font_size("normal_font_size" if c is RichTextLabel else "font_size")
		p["rect"] = str(c.get_global_rect()); p["parent_rect"] = str(p.parent.get_global_rect())
		p["contained"] = p.parent.get_global_rect().grow(1).encloses(c.get_global_rect())
		# Text must clear the existing GPT frame's bevel, not merely the texture
		# rectangle (which includes translucent edge/glow pixels).
		if id in ["dialogue","speaker","cutscene_combat"]:
			p.contained = p.parent.get_global_rect().grow_individual(-32,-24,-32,-24).grow(1).encloses(c.get_global_rect())
		p["onscreen"] = Rect2(0,0,1920,1080).grow(1).encloses(c.get_global_rect())
		if id in ["choice","result_daily"]: p.contained = true
		if id == "tutorial": p.height = 74.0; p.contained=true
		if id == "tutorial_observation": p.height = 92.0
		if id == "event_body": p.height = 128.0
		if id == "log": p.height = 540.0
		if id == "achievement": p.onscreen = Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).encloses(c.get_global_rect())
		p["base_font_size"] = p.font_size

func routes(row: Dictionary) -> Array:
	# Translated 0111 files contain several full documents; their JSON pointer
	# retains the original UI source (including barks.json and bond_scenes.json).
	var path: String = str(row.source)+str(row.pointer); var key: String = row.key
	if "/achievements/" in path: return ["achievement"] if key.begins_with("name_") else ["achievement_list"]
	if key in ["speaker_label","speaker_name","display_name"]: return ["speaker"]
	if "start_flow" in path:
		if key == "prologue": return ["prologue"]
		if key.begins_with("guide_") or key == "commands": return ["first_day"]
		return ["naming","naming_form"]
	if "tutorial" in row.pointer or key == "instruction": return ["tutorial","tutorial_observation"]
	if key == "label": return ["choice"]
	if "events" in path and key in ["text","prompt"]: return ["event_body","bond_memory_duo_join","log"]
	if "barks" in path: return ["combat_feed","victory_bark","log"]
	if "memory" in path or "bond" in path or "duo" in path or "join" in path: return ["bond_memory_duo_join","log"]
	return ["dialogue","cutscene_combat","combat_feed","result_daily","log"]

func measure(row: Dictionary, text: String, id: String, locale: String, resolution: Vector2i, scale_value: float) -> void:
	var profile_id := "dialogue" if id == "bond_memory_duo_join" else "log" if id == "achievement_list" else id
	if not profiles.has(profile_id): return
	var p: Dictionary = profiles[profile_id]
	var c: Control = p.control
	if phase=="after" and id in ["combat_feed","victory_bark"]:
		var parent: Control = p.parent
		var heading: Label
		if id=="combat_feed":
			heading = parent.get_child(0) as Label
		else: heading = parent.get_child(0) as Label
		parent.size = Vector2(1080,160 if id=="combat_feed" else 112)
		heading.position = Vector2(132,12) if id=="combat_feed" else Vector2(24,24)
		c.position = Vector2(132,48) if id=="combat_feed" else Vector2(20,44)
		c.text = text
		c.add_theme_font_size_override("font_size",UISettings.scaled_font_size(23))
		TextLayout.grow_feed(parent,heading,c)
		p.width = c.size.x; p.height = c.size.y; p.font_size=c.get_theme_font_size("font_size")
	var font: Font = c.get_theme_font("normal_font" if c is RichTextLabel else "font")
	var size_px: int = p.font_size
	var wrap := TextServer.AUTOWRAP_WORD_SMART
	if c is Label: wrap = c.autowrap_mode
	if c is Button: wrap = TextServer.AUTOWRAP_OFF
	var width: float = p.width-4
	if c is Button:
		width = p.width-c.get_theme_stylebox("normal").get_minimum_size().x-8
		size_px = game.hud._fit_button_font_size(text,p.width,UISettings.scaled_font_size(20))
	var para := TextParagraph.new(); para.width = width
	para.break_flags = TextServer.BREAK_MANDATORY | (TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE if wrap != TextServer.AUTOWRAP_OFF else 0)
	para.add_string(text,font,size_px,locale)
	var needed := para.get_size()
	if c is Label:
		c.text=text; c.size=Vector2(p.width,p.height); c.add_theme_font_size_override("font_size",size_px)
		needed.y=TextLayout.label_height(c,p.width)
	elif c is RichTextLabel:
		c.text=text; c.size=Vector2(p.width,p.height); c.add_theme_font_size_override("normal_font_size",size_px)
		needed.y=c.get_content_height()
	# HUD labels fit each new string down to the existing 18 logical pixel floor.
	if id in ["combat_feed","victory_bark","tutorial","tutorial_observation","naming_form","event_body"] or c.get_meta("dialogue_layout_managed",false):
		var minimum := 20 if id in ["achievement","naming","first_day","prologue"] else 18
		while size_px>minimum and needed.y>float(p.height)-2:
			size_px -= 1; para.clear(); para.width=width; para.add_string(text,font,size_px,locale); needed=para.get_size()
			if c is Label:
				c.add_theme_font_size_override("font_size",size_px); needed.y=TextLayout.label_height(c,p.width)
			elif c is RichTextLabel:
				c.add_theme_font_size_override("normal_font_size",size_px); needed.y=c.get_content_height()
	if phase == "after" and id in ["dialogue","cutscene_combat","bond_memory_duo_join"]:
		var parts := TextLayout.pages(text,font,size_px,Vector2(p.width,p.height),6)
		expect("".join(parts)==text,"lossless pages: "+str(row.source)+str(row.pointer))
		needed = Vector2.ZERO
		for part in parts:
			var body := c as RichTextLabel
			body.text = part.strip_edges()
			needed.y = maxf(needed.y,body.get_content_height())
			needed.x = maxf(needed.x,TextLayout.paragraph(part.strip_edges(),font,size_px,width,6).get_size().x)
	var overflow := not bool(p.contained) or not bool(p.onscreen)
	var reason := "geometry" if overflow else ""
	var paged: bool = phase=="after" and id in ["dialogue","cutscene_combat","bond_memory_duo_join"]
	if (not bool(p.scroll) or paged) and (needed.y > float(p.height)+1 or needed.x > float(p.width)+1): overflow = true; reason += " text"
	if c is Label and not bool(p.scroll) and c.get_visible_line_count()<c.get_line_count(): overflow=true; reason+=" hidden_lines"
	var key := "%s|%s|%dx%d|%.2f" % [id,locale,resolution.x,resolution.y,scale_value]
	if not counts.has(key): counts[key] = {"tested":0,"overflow":0}
	counts[key].tested += 1
	if overflow:
		counts[key].overflow += 1
		violations.append({"case":key,"source":row.source,"pointer":row.pointer,"id":row.id,"text":text,"reason":reason,"needed":str(needed),"available":str(Vector2(p.width,p.height)),"font":size_px})
	if row.key in ["text","text_ko"] and ("/story/" in row.source):
		var sample_key := locale+ ("_bark" if "barks" in (str(row.source)+str(row.pointer)) else "_main" if "/v122_main/" in row.source else "_extra")
		if not samples.has(sample_key) or text.length()>str(samples[sample_key].text).length(): samples[sample_key] = {"text":text,"source":row.source,"id":row.id}

func capture(id: String) -> void:
	await frames(12); await RenderingServer.frame_post_draw
	if id=="bark":
		var state: Array=[]
		for panel in game.ui_layer.get_children():
			for child in panel.get_children():
				if child is Label: state.append({"text":child.text,"visible":child.is_visible_in_tree(),"rect":str(child.get_global_rect()),"font":child.get_theme_font_size("font_size"),"color":str(child.get_theme_color("font_color")),"lines":child.get_line_count(),"visible_lines":child.get_visible_line_count(),"line_height":child.get_line_height(),"font_height":child.get_theme_font("font").get_height(child.get_theme_font_size("font_size")),"max_lines":child.max_lines_visible,"skipped":child.lines_skipped,"line_spacing":child.get_theme_constant("line_spacing"),"min_size":str(child.get_minimum_size()),"modulate":str(child.modulate),"self_modulate":str(child.self_modulate),"parent_rect":str(panel.get_global_rect()),"parent_modulate":str(panel.modulate),"parent_clip":panel.clip_contents})
		write_json(phase+"_bark_render.json",state)
		if phase=="after":
			for label in state: expect(int(label.visible_lines)>=int(label.lines),"rendered bark lines are visible")
	var image := get_viewport().get_texture().get_image(); image.resize(960,540,Image.INTERPOLATE_LANCZOS)
	image.save_png(OUT+phase+"_"+id+".png")
func render_samples() -> void:
	UISettings.set_text_scale(1.15,false)
	for entry in [["ko_main","long_ko"],["en_main","long_en_main"],["en_extra","long_en_extra"],["zh_CN_main","long_zh"]]:
		LanguageSettings.set_locale(str(entry[0]).split("_main")[0].split("_extra")[0],false)
		clear()
		var screen: Control = game._onboarding_screen_panel(Color("#08060d"))
		game.story_presenter._background(screen,{})
		game.story_presenter._build_shared_frame(screen,"CHR_BATI","W".repeat(12),"dry",str(samples[entry[0]].text),false,true)
		await capture(entry[1])
	LanguageSettings.set_locale("en",false); clear()
	game.v130r_story.victory_cue = {"speaker_label":"W".repeat(12),"text":str(samples.en_bark.text)}
	game.v130r_story.show_victory(game); await capture("bark")
	await get_tree().create_timer(3.6).timeout
	clear(); game.continuity.history.clear(); game.continuity.history.append({"day":1,"speaker":"W".repeat(12),"text":str(samples.en_extra.text)}); game.continuity.open_backlog(); await capture("log")

func run() -> void:
	for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
	ProjectSettings.set_setting("debug/start_flow14",true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dialogue-phase="): phase = arg.get_slice("=",1)
	corpus = JSON.parse_string(FileAccess.get_file_as_string(OUT+"corpus.json"))
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled=false; game.campaign_auxiliary_save_enabled=false; game.campaign_save_v5_enabled=false; game.campaign_save_v6_enabled=false
	add_child(game); await frames(10)
	game.set_process(false); game.set_physics_process(false); game.start_flow.set_process(false)
	game.current_screen = "dialogue"
	game.story_feature_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
	GameState.player_name = "W".repeat(12)
	if phase in ["render","render-before"]:
		samples = JSON.parse_string(FileAccess.get_file_as_string(OUT+"samples.json"))
		phase = "before" if phase=="render-before" else "after"
		await render_samples(); game._shutdown_audio_for_exit(); game.campaign_autosave_pending=false
		clear(); game.queue_free(); await frames(10); get_tree().quit(); return
	if phase=="behavior":
		await behavior(); write_json("behavior.json",{"checks":checks,"failures":failures})
		game.queue_free(); await frames(); print("BEHAVIOR checks=",checks," failures=",failures.size()); get_tree().quit(0 if failures.is_empty() else 1); return
	if phase=="fixture":
		await fixture(); write_json("fixture.json",{"checks":checks,"failures":failures,"user_dir":OS.get_user_data_dir()})
		game.queue_free(); await frames(); print("FIXTURE checks=",checks," failures=",failures); get_tree().quit(0 if failures.is_empty() else 1); return
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = resolution
		for scale_value in [1.0,1.15]:
			UISettings.set_text_scale(scale_value,false)
			for locale in ["ko","en","zh_CN"]:
				LanguageSettings.set_locale(locale,false); await build_profiles()
				var snapshot: Dictionary = {}
				for id in profiles:
					snapshot[id] = profiles[id].duplicate(); snapshot[id].erase("control"); snapshot[id].erase("parent")
				profile_snapshots["%s|%s|%s" % [resolution,scale_value,locale]] = snapshot
				for row in corpus:
					if not relevant(row,locale): continue
					var text := text_for(row,locale)
					for id in routes(row): measure(row,text,id,locale,resolution,scale_value)
				var food_text: String = profiles.food_daily.control.text
				measure({"source":"runtime:MonsterFoodService.lines(all24)","pointer":"/food_ledger","id":"all24","text":food_text,"key":"text","locale":locale},food_text,"food_daily",locale,resolution,scale_value)
				await frames(1)
				print("AUDIT ",phase," ",resolution," ",scale_value," ",locale)
	write_json(phase+".json",{"counts":counts,"violations":violations,"checks":checks,"failures":failures})
	write_json("samples.json",samples)
	write_json(phase+"_profiles.json",profile_snapshots)
	print("SUMMARY cases=",counts.size()," violations=",violations.size()," failures=",failures.size())
	clear(); game.queue_free(); await frames(5); get_tree().quit(0 if failures.is_empty() else 1)

func advance_key() -> void:
	var event := InputEventKey.new(); event.pressed=true; event.keycode=KEY_SPACE; event.physical_keycode=KEY_SPACE
	game._input(event); await frames(8)

func behavior() -> void:
	UISettings.set_text_scale(1.15,false); LanguageSettings.set_locale("en",false)
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT+"samples.json"))
	var long_text: String = (str(source.en_main.text)+"\n").repeat(8)
	game._onboarding_begin_dialogue([{"id":"LAYOUT_STRESS","speaker":"CHR_BATI","text":long_text,"v130r_text":true},{"id":"LAYOUT_NEXT","speaker":"CHR_BATI","text":source.en_extra.text,"v130r_text":true}],"title","")
	await frames(15)
	expect(game.story_presenter.text_pages.size()>1,"stress dialogue has multiple pages")
	expect("".join(game.story_presenter.text_pages)==long_text,"stress preserves source characters")
	var page_count: int = game.story_presenter.text_pages.size()
	for i in page_count-1:
		await advance_key()
		expect(game.onboarding_dialogue_index==0,"Space advances page before cue")
		expect(game.story_presenter.page_index==i+1,"Space reaches page "+str(i+2))
		expect(game.story_presenter.page_body.get_content_height()<=game.story_presenter.page_body.size.y+1,"rendered page fits")
	await advance_key(); expect(game.onboarding_dialogue_index==1,"cue advances after final page")
	# A real pointer action uses the same connected gui_input path as mouse play.
	var pointer := InputEventMouseButton.new(); pointer.button_index=MOUSE_BUTTON_LEFT; pointer.pressed=true
	game.story_presenter.page_body.gui_input.emit(pointer); await frames(8)
	expect(game.onboarding_dialogue_queue.is_empty(),"mouse advances final cue")
	game._onboarding_begin_dialogue([{"id":"LAYOUT_AUTO","speaker":"CHR_BATI","text":long_text,"v130r_text":true}],"title","")
	await frames(12); game.story_presenter.legacy_auto_enabled=true; game.story_presenter.legacy_auto_remaining=0
	game.story_presenter.tick_legacy_auto(1); await frames(8)
	expect(game.story_presenter.page_index==1 and game.onboarding_dialogue_index==0,"auto pages even on last cue")
	game.continuity.open_backlog(); await frames(8)
	var index: int=game.story_presenter.page_index; await advance_key()
	expect(game.story_presenter.page_index==index,"backlog blocks dialogue input")
	game.continuity.close_backlog(); await frames(8)
	game.onboarding_dialogue_queue.clear(); game.story_feature_enabled=true
	game.story_director.reset_for_new_game()
	game.story_director.current_scene_id="STORY_D01_MANAGEMENT_ENTRY"
	game.story_director.current_cue_id="LAYOUT_CORE"
	game.story_director._active_cues.append({"id":"LAYOUT_CORE","speaker_id":"CHR_BATI","speaker_label":"Bati","portrait_emotion":"dry","text_ko":long_text})
	game._story_show_active_scene(); await frames(12)
	expect(game.story_presenter.text_pages.size()>1,"director path paginates")
	game.story_director.set_auto(true); game.story_auto_remaining=0
	game._story_tick_auto(1); await frames(8)
	expect(game.story_presenter.page_index==1 and game.story_director.cursor==0,"director auto pages on final cue")
	expect(not game.story_director.seen_cue_ids.has("LAYOUT_CORE"),"partial page does not mark cue read")
	await advance_key()
	expect(not game.story_director.auto_enabled,"manual page input disables director auto")
	game.story_director.reset_for_new_game()
	expect(DataRegistry.waves.get("day_29",[]).is_empty(),"DAY29 remains noncombat")
	for locale in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		var font: Font=Fonts.font_for_role("dialogue")
		for name in ["W".repeat(12),"힣".repeat(12),"龘".repeat(12)]:
			var measured:=TextLayout.paragraph(name,font,33,1700)
			expect(measured.get_size().x<=1700,"maximum name width: "+locale)
	game.campaign_autosave_pending=false; game._shutdown_audio_for_exit()

func fixture() -> void:
	LanguageSettings.set_locale("en",true); UISettings.set_text_scale(1.15,true)
	game._onboarding_reset_game(); GameState.player_name="W".repeat(12)
	game.start_flow.fresh=false; game.start_flow.intro_complete=true; game.start_flow.guide_step=5; game.start_flow.command_seen=true
	game.story_feature_enabled=true
	# Start with a genuine DAY1 save. Select its longest authored English cue,
	# avoiding synthetic later-day progression just to reach a layout sample.
	var cue_id := ""; var scene_id := ""; var longest := ""
	for id in game.story_catalog.all_scene_ids():
		var candidate: Dictionary=game.story_catalog.scene(id)
		if int(candidate.day)!=1: continue
		for cue in candidate.cues:
			var text: String=LanguageSettings.story_text(cue,GameState.player_name)
			if text.length()>longest.length(): cue_id=cue.id; scene_id=id; longest=text
	var scene: Dictionary=game.story_catalog.scene(scene_id)
	GameState.day=1
	expect(game.story_director.start_scene(scene_id,game._story_context(),"management","",true),"fixture starts real authored scene")
	for i in scene.cues.size():
		if str(scene.cues[i].id)==cue_id:
			game.story_director.cursor=i; game.story_director.current_cue_id=cue_id; break
	game._story_show_active_scene(); await frames(12)
	game.campaign_save_enabled=true; game.campaign_save_v6_enabled=true
	expect(game._write_campaign_v6_snapshot(),"isolated v6 save: "+game.campaign_save_error)
	expect(FileAccess.file_exists("user://campaign_save_v6.json"),"EXE fixture file exists")
	write_json("fixture_cue.json",{"scene":scene_id,"cue":cue_id,"text":longest})
	game.campaign_autosave_pending=false; game._shutdown_audio_for_exit()
