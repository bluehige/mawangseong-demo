extends Node
## One owner for title -> prologue -> naming -> first-day guidance.
const Grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const UIFont = preload("res://scripts/ui/UIFont.gd")
const Obsidian = preload("res://scripts/ui/ObsidianStyleBox.gd")
const TEXT_PATH := "res://data/v130r/start_flow.json"
var root: Node
var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEXT_PATH))
var menu_open := false
var prologue_index := 0
var naming_turn := 0
var naming := false
var fresh := false
var intro_complete := true
var guide_step := 5
var command_seen := true
var play_seconds := 0.0
var guide: Control
var guide_key := ""
var command_paused := false
var command_pause_owned := false
var replaying := false
var replay_on_continue := false
var suspended_map: Control

func setup(game: Node) -> void:
	root = game
	var entry: String = game.get_tree().current_scene.scene_file_path if game.get_tree().current_scene!=null else ""
	if entry=="res://scenes/main/Main.tscn":
		for flag in ["1","2","5","6","7","10"]: ProjectSettings.set_setting("debug/approved_map_step"+flag,true)
		ProjectSettings.set_setting("debug/start_flow14",true)
	LanguageSettings.locale_changed.connect(locale_changed)

func before_screen_change(destination: String) -> void:
	if is_instance_valid(suspended_map):
		if destination not in ["settings","combat"]: abandon_battle(suspended_map); suspended_map.queue_free(); suspended_map = null
		return
	var view: Node = root.ui_layer.get_node_or_null("ApprovedMapManagement") if root.ui_layer!=null else null
	if view==null or view.battle==null or not view.battle.running or destination=="combat": return
	if destination=="settings":
		Grade.stash(root,view.placement,view.monster_ui.assignments)
		view.get_parent().remove_child(view); root.add_child(view)
		view.hide(); view.set_physics_process(false); suspended_map = view
	else: abandon_battle(view)

func restore_battle_view() -> bool:
	if not is_instance_valid(suspended_map): return false
	suspended_map.get_parent().remove_child(suspended_map); root.ui_layer.add_child(suspended_map)
	suspended_map.show(); suspended_map.set_physics_process(true); suspended_map = null
	root.world_overlay_layer.hide()
	if root.quarter_renderer!=null: root.quarter_renderer.set_world_layers_visible(false)
	return true

func abandon_battle(view: Node) -> void:
	var battle = view.battle
	if battle==null: return
	battle.running = false; battle._clear_active_combat_tweens()
	root.graph = battle.original_graph; root.rooms = battle.original_rooms; root.combat_scene = battle.original_controller
	if root.effect_root.get_parent()!=battle.effects_home: root.effect_root.reparent(battle.effects_home,false)
	root.effect_root.position = Vector2.ZERO; root._clear_units()
	root.set_physics_process(true); root.set_process_input(true)

func text(key: String) -> String:
	return str(catalog[LanguageSettings.locale].get(key,key))

func locale_changed(_locale: String) -> void:
	if root.current_screen=="title" or root.current_screen=="prologue" or root.current_screen=="name_entry": root._set_screen(root.current_screen,false)
	guide_key = ""

func open_menu() -> void:
	menu_open = true; root._onboarding_set_stage("LV00_START_MENU"); root._set_screen("title",false)

func reset_run() -> void:
	fresh = true; intro_complete = false; guide_step = 1; command_seen = false
	play_seconds = 0.0; naming = false; prologue_index = 0; replaying = false; replay_on_continue = false
	if root.has_meta(Grade.SESSION): root.remove_meta(Grade.SESSION)
	if Buildings.enabled():
		var initial := Buildings.initial(root,"F")
		Grade.stash(root,initial,{})
	root.tutorial_manager.active = false
	root.tutorial_gate_enabled = false

func start_prologue() -> void:
	root.get_viewport().set_input_as_handled()
	reset_run()
	root._onboarding_set_stage("LV00_PROLOGUE")
	root._set_screen("prologue",false)

func build_prologue() -> void:
	var screen := ColorRect.new(); screen.color = Color.BLACK; screen.size = Vector2(1920,1080)
	root.ui_layer.add_child(screen)
	screen.name = "StartPrologue"; screen.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var lines: Array = catalog[LanguageSettings.locale].prologue
	var text := label(screen,str(lines[prologue_index]),Rect2(270,400,1380,250),38,"PrologueText")
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button(screen,text("skip"),Rect2(1640,50,220,64),begin_naming,"PrologueSkip")
	button(screen,text("next"),Rect2(760,840,400,76),next_prologue,"PrologueNext")
	var hint := label(screen,text("advance_hint"),Rect2(510,940,900,50),22,"PrologueHint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hint.modulate.a = .6
	screen.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT: next_prologue())
	# Existing cave ambience includes water drips. No external audio is introduced.
	root._shutdown_audio_for_exit()
	if root.stage_ambience_player!=null:
		root.stage_ambience_player.stream = load("res://assets/audio/ambience/stage01_cave.ogg")
		root.stage_ambience_player.play()

func next_prologue() -> void:
	if root.current_screen!="prologue": return
	if prologue_index<6: prologue_index += 1; root._set_screen("prologue",false)
	else: begin_naming()

func begin_naming() -> void:
	root.get_viewport().set_input_as_handled()
	naming = true; naming_turn = 0
	root._onboarding_set_stage("LV01_NAME_ENTRY")
	root._set_screen("name_entry",false)

func next_naming() -> void:
	naming_turn += 1; root._set_screen("name_entry",false)

func build_naming_talk() -> void:
	var screen: Panel = root.hud.panel(Rect2(0,0,1920,1080),Color("#08060d"),Color.TRANSPARENT,"NamingConversation","flat")
	screen.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	root._onboarding_add_scene_illustration(screen,Rect2(0,0,1920,1080),root.ONBOARDING_START_SCENE)
	var art: TextureRect = root.hud.texture(screen,root._onboarding_speaker_portrait_path("CHR_BATI","dry"),Rect2(650,160,620,530))
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var box := raster_panel(screen,Rect2(310,700,1300,285),"NamingTalkPanel")
	label(box,text("bati"),Rect2(42,24,400,44),28,"NamingSpeaker")
	label(box,str(catalog[LanguageSettings.locale].name_talk[mini(naming_turn,1)]),Rect2(42,82,1216,100),32,"NamingTalk")
	button(box,text("next"),Rect2(950,198,300,62),next_naming,"NamingNext")

func input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER]:
		if event.keycode==KEY_ENTER and root.get_viewport().gui_get_focus_owner() is BaseButton: return false
		if root.current_screen=="prologue": next_prologue(); return true
		if root.current_screen=="name_entry" and naming and naming_turn<2: next_naming(); return true
	return false

func valid_name(value: String) -> bool:
	var name_text := value.strip_edges()
	if name_text.length()<1 or name_text.length()>12: return false
	for c in name_text:
		if c in "<>:{}[]/\\|\"*?" or c.unicode_at(0)<32 or c.unicode_at(0)==127: return false
	return true

func confirm_name() -> void:
	naming = false
	root._onboarding_set_stage("LV02_NAME_CONFIRMED")
	var text := text("name_confirm").replace("{name}",GameState.player_name)
	root._onboarding_begin_dialogue([{"id":"START_NAME_CONFIRMED","speaker":"CHR_BATI","text":text,"v130r_text":true}],"management","start_day1")

func enter_day1() -> void:
	GameState.day = 1
	root._onboarding_set_stage("LV03_DAY01_MANAGEMENT_TUTORIAL")
	root._set_screen("management",false)
	management_intro.call_deferred()

func management_intro() -> void:
	if not fresh or intro_complete or root.current_screen!="management": return
	if root._story_begin_trigger("management_entered",{},"management","start_guide",false,1): return
	after_intro()

func after_intro() -> void:
	if root.story_director.is_active() or not root.onboarding_dialogue_queue.is_empty(): return
	if root.v130r_story.management(root): return
	intro_complete = true
	root._schedule_campaign_autosave("management")
	guide_key = ""

func _process(delta: float) -> void:
	if root==null or root.ui_layer==null: return
	if root.current_screen not in ["title","settings","prologue","name_entry"] and not root.pause_menu_open: play_seconds += delta
	if root.current_screen not in ["management","combat"] or root.pause_menu_open or not intro_complete:
		clear_guide(); return
	var view: Node = root.ui_layer.get_node_or_null("ApprovedMapManagement")
	if view==null: clear_guide(); return
	if view.battle!=null:
		if not command_seen and view.battle.running:
			if guide_key!="command":
				clear_guide()
				if not command_pause_owned: command_paused = root.combat_paused; command_pause_owned = true
				view.battle.set_pause_state(true)
				show_guide(view,"command",text("commands"),Rect2(600,580,900,330),ack_commands)
		else: clear_guide()
		return
	if guide_step>4 or not (replaying or (fresh and GameState.day==1)): clear_guide(); return
	if guide_step==2 and view.placement.buildings.any(func(b): return not b.fixed): advance_guide(); return
	if guide_step==3:
		var placed := 0
		for id in view.monster_ui.assignments:
			if view.monster_ui.members[id].species_id in ["slime","goblin","imp"]: placed += 1
		if placed>=3: advance_guide(); return
	var key := "%d:%s:%s" % [guide_step,LanguageSettings.locale,view.monster_ui.mode]
	if key!=guide_key: show_guide(view,key,text("guide_"+str(guide_step)),guide_rect(view),advance_guide if guide_step==1 else Callable())
	if is_instance_valid(guide): update_highlights(view)

func guide_rect(view: Node) -> Rect2:
	return Rect2(42,180,720,290) if guide_step==1 else Rect2(1010,170,790,290)

func show_guide(view: Node, key: String, content: String, rect: Rect2, callback: Callable) -> void:
	clear_guide(); guide_key = key
	guide = Control.new(); guide.name = "StartGuide"; guide.mouse_filter = Control.MOUSE_FILTER_IGNORE; guide.z_index = 4095
	guide.scale = Vector2.ONE*view.ui_unit
	view.add_child(guide)
	var box := raster_panel(guide,rect,"StartGuidePanel")
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	label(box,text("guide_title")+"  "+("4 / 4" if key=="command" else str(guide_step)+" / 4"),Rect2(28,18,rect.size.x-56,40),25,"StartGuideHeading")
	label(box,content,Rect2(28,65,rect.size.x-56,rect.size.y-155),25,"StartGuideText")
	if callback.is_valid(): button(box,text("understood"),Rect2(rect.size.x-248,rect.size.y-68,220,52),callback,"StartGuideNext")
	else: label(box,text("guide_do"),Rect2(28,rect.size.y-62,rect.size.x-56,44),20,"StartGuideAction")
	if key!="command": update_highlights(view)

func update_highlights(view: Node) -> void:
	if not is_instance_valid(guide): return
	var old := guide.get_node_or_null("Targets")
	if old!=null: old.free()
	var targets := Control.new(); targets.name = "Targets"; targets.mouse_filter = Control.MOUSE_FILTER_IGNORE; guide.add_child(targets)
	if guide_step==1:
		for id in ["throne","entrance","vault"]:
			var b := Buildings.building(view.placement,id)
			var point: Vector2 = view.screen_cell(Vector2(b.rect.position)+Vector2(b.rect.size)/2)/view.ui_unit
			var mark := raster_panel(targets,Rect2(point-Vector2(90,30),Vector2(180,60)),"Highlight_"+id)
			label(mark,text(id),Rect2(8,5,164,50),24,"MapLabel_"+id).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif guide_step==2:
		label(targets,"▼ "+text("build"),Rect2(630,832,670,50),30,"BuildHighlight")
	elif guide_step==3:
		label(targets,"▼ "+text("place"),Rect2(878,94,440,50),28,"PlaceHighlight")
		# The live placement mode owns its glowing legal defense cells.
	elif guide_step==4:
		label(targets,"▼ "+text("battle"),Rect2(1070,94,440,50),28,"BattleHighlight")

func advance_guide() -> void:
	guide_step += 1; guide_key = ""; clear_guide()
	root._schedule_campaign_autosave("management")

func ack_commands() -> void:
	command_seen = true; guide_step = 5; replaying = false; clear_guide()
	var view: Node = root.ui_layer.get_node_or_null("ApprovedMapManagement")
	if view!=null and view.battle!=null: view.battle.set_pause_state(command_paused)
	command_pause_owned = false

func clear_guide() -> void:
	if is_instance_valid(guide): guide.queue_free()
	guide = null; guide_key = ""

func before_battle(view: Node) -> bool:
	if (replaying or (fresh and GameState.day==1)) and (not intro_complete or guide_step<4):
		view.status_text.text = text("finish_guide"); return true
	if root.story_director.is_active() or not root.onboarding_dialogue_queue.is_empty(): return true
	if root._story_begin_trigger("precombat_confirmed",{},"management","start_map_battle",false): return true
	return false

func resume_battle() -> void:
	root._set_screen("management",false)
	var view: Node = root.ui_layer.get_node_or_null("ApprovedMapManagement")
	if view!=null: view.start_battle.call_deferred()

func replay_guide() -> void:
	replaying = true; intro_complete = true; guide_step = 1; command_seen = false; guide_key = ""
	replay_on_continue = root.settings_return_screen=="title"
	UISettings.set_tutorial_guidance_level(UISettings.TUTORIAL_GUIDANCE_FULL,false)
	var note: Node = root.ui_layer.find_child("ReplayStartGuideButton",true,false)
	if note!=null: note.text = text("replay_ready")

func snapshot() -> Dictionary:
	var view: Node = root.ui_layer.get_node_or_null("ApprovedMapManagement") if root.ui_layer!=null else null
	if view!=null: Grade.stash(root,view.placement,view.monster_ui.assignments)
	return {"version":1,"fresh":fresh,"replaying":replaying,"replay_on_continue":replay_on_continue,"intro_complete":intro_complete,"guide_step":guide_step,"command_seen":command_seen,"play_seconds":play_seconds,"map":root.get_meta(Grade.SESSION,{}).duplicate(true)}

func restore(value: Dictionary) -> void:
	clear_guide(); naming = false
	fresh = bool(value.get("fresh",false)); intro_complete = bool(value.get("intro_complete",true))
	replaying = bool(value.get("replaying",false))
	replay_on_continue = bool(value.get("replay_on_continue",false))
	guide_step = clampi(int(value.get("guide_step",5)),1,5); command_seen = bool(value.get("command_seen",true))
	play_seconds = maxf(0,float(value.get("play_seconds",0)))
	if root.has_meta(Grade.SESSION): root.remove_meta(Grade.SESSION)
	if value.get("map") is Dictionary and not value.map.is_empty(): root.set_meta(Grade.SESSION,value.map.duplicate(true))
	elif Buildings.enabled():
		# Older campaigns had no free-placement snapshot. Derive a safe map at
		# their saved day and preserve their wallet, roster and name.
		var baseline := Buildings.initial(root,"F")
		var grade := Grade.grade_for_stage(Grade.stage_for_day(GameState.day,baseline.stage_rules),baseline.stage_rules)
		var layout := Buildings.initial(root,grade); layout.day = GameState.day
		layout.resources = {"gold":GameState.gold,"mana":GameState.mana,"food":GameState.food}
		layout["food_state"] = GameState.food_state.duplicate(true)
		var members := Members.roster(); var owned: Array = []
		for id in members:
			if root.monster_roster.has(members[id].species_id): owned.append(id)
		Grade.stash(root,layout,Members.auto_place(layout,members,owned,GameState.food_income))
	root.tutorial_manager.active = false; root.tutorial_gate_enabled = false

func build_reset_confirmation() -> void:
	var overlay: Panel = root.hud.panel(Rect2(0,0,1920,1080),Color("#000000c0"),Color.TRANSPARENT,"TitleResetConfirmation","flat")
	overlay.name = "TitleResetConfirmation"; overlay.z_index = 500
	var box := raster_panel(overlay,Rect2(520,320,880,430),"OverwritePanel")
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	label(box,text("overwrite_title"),Rect2(48,38,784,60),36,"OverwriteHeading")
	label(box,text("overwrite_body"),Rect2(48,120,784,130),28,"OverwriteDescription")
	button(box,text("overwrite_yes"),Rect2(48,305,430,76),Callable(root,"_onboarding_start_new_game"),"TitleResetConfirmButton")
	button(box,text("cancel"),Rect2(510,305,322,76),Callable(root,"_cancel_title_reset_confirmation"),"TitleResetCancelButton").grab_focus()

func label(parent: Control, content: String, rect: Rect2, font_size: int, id: String) -> Label:
	var result := Label.new()
	result.name = id; result.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_override("font",UIFont.font_for_role(UIFont.ROLE_BODY))
	result.add_theme_font_size_override("font_size",font_size)
	result.add_theme_color_override("font_color",Color("#f4eadc"))
	result.set_meta("hud_text_fit",true)
	result.text = content; result.position = rect.position; result.size = rect.size
	parent.add_child(result)
	return result

func raster_panel(parent: Control, rect: Rect2, id: String) -> Panel:
	var panel := Panel.new(); panel.name = id; panel.position = rect.position; panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(panel)
	var style := Obsidian.new(); style.texture = load("res://assets/ui/uiux/obsidian_panel.png")
	panel.add_theme_stylebox_override("panel",style)
	return panel

func button(parent: Control, content: String, rect: Rect2, callback: Callable, id: String) -> Button:
	var result := Button.new(); result.text = content
	result.add_theme_font_override("font",UIFont.font_for_role(UIFont.ROLE_BUTTON))
	result.add_theme_font_size_override("font_size",26)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style := Obsidian.new(); style.texture = load("res://assets/ui/uiux/obsidian_button.png"); style.button_shape = true
		style.tint = Color(.45,.45,.5) if state=="disabled" else Color(1.25,1.16,.85) if state in ["hover","focus"] else Color.WHITE
		result.add_theme_stylebox_override(state,style)
	result.name = id; result.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	result.set_meta("uiux_external_button",true)
	parent.add_child(result); result.position = rect.position; result.custom_minimum_size = rect.size; result.size = rect.size
	result.pressed.connect(callback)
	return result
