extends RefCounted
## Supplemental scripts use the existing dialogue presenter and saved read IDs.
const FOLDER := "res://data/v130r/story/"
var documents: Dictionary = {}
var translations: Dictionary = {}
var bark_clock := 0.0
var bark_last: Dictionary = {}
var bark_queue: Array = []
var bark_panel: Control
var bark_remaining := 0.0
var bark_gap := 0.0
var victory_cue: Dictionary = {}
var bark_locale := ""

func _init() -> void:
	for file in ["join_scenes", "day_overlays", "barks", "bond_scenes", "duo_scenes"]:
		documents[file] = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+file+".json"))
	for locale in ["en", "zh_cn"]:
		translations[locale] = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"localization_story_"+locale+".json"))

func scenes(kind: String) -> Array:
	var locale: String = "zh_cn" if LanguageSettings.locale == "zh_CN" else LanguageSettings.locale
	return translations[locale].documents[kind+".json"].scenes if translations.has(locale) else documents[kind].scenes

func entries(scene: Dictionary, block: Dictionary = {}) -> Array:
	var result: Array = []
	for cue in block.get("cues", scene.get("cues", [])):
		result.append({"id":cue.id,"speaker":cue.speaker_id,"speaker_name":cue.speaker_label,"emotion":cue.portrait_emotion,"text":cue.text,"v130r_text":true,"v130r_scene_id":block.get("id",scene.id),"dialogue_header":scene.get("title","")})
	return result

func localized_entry(id: String) -> Dictionary:
	for kind in documents:
		for scene in scenes(kind):
			for block in scene.get("segments",[scene]):
				for line in entries(scene,block):
					if line.id==id: return line
	return {}

func restore_pending(game: Node) -> void:
	var ids: Array = []
	for line in game.onboarding_dialogue_queue:
		var id: String = str(line.get("v130r_scene_id",""))
		if id!="" and not ids.has(id): ids.append(id)
	if not ids.is_empty(): game.set_meta("v130r_story_pending",ids)

func owned(game: Node) -> Array:
	return game.get_meta("v130r_owned_species",game.monster_roster.keys())

func allowed(game: Node, condition: Dictionary) -> bool:
	for species in condition.get("requires_owned_species_ids", []):
		if not owned(game).has(species): return false
	for memory in condition.get("requires_unlocked_memory_ids", []):
		var found := false
		for row in game.monster_roster.values():
			if row.get("unlocked_memory_ids", []).has(memory): found = true
		if game.update4_profile.get("unlocked_memory_ids",[]).has(memory): found = true
		if not found: return false
	return true

func join_entries(species: String) -> Array:
	for scene in scenes("join_scenes"):
		if scene.monster_id == species and scene.trigger == "management_entered": return entries(scene)
	return []

func start(game: Node, lines: Array, ids: Array, action: String = "v130r_story") -> bool:
	if lines.is_empty(): return false
	game.set_meta("v130r_story_pending",ids)
	game._onboarding_begin_dialogue(lines,Constants.SCREEN_MANAGEMENT,action)
	return true

func finish(game: Node) -> void:
	for id in game.get_meta("v130r_story_pending",[]):
		if not game.story_director.seen_scene_ids.has(id): game.story_director.seen_scene_ids.append(id)
	game.remove_meta("v130r_story_pending")

func management(game: Node) -> bool:
	if game.current_screen != Constants.SCREEN_MANAGEMENT or not game.onboarding_dialogue_queue.is_empty() or game.story_director.is_active(): return false
	var lines: Array = []; var ids: Array = []
	# Play only the authored management anchor, never an entire DAY or a battle.
	# The supplemental block follows it after the existing director returns here.
	for scene in scenes("day_overlays"):
		if int(scene.day)!=GameState.day or int(game.campaign_cycle_index)>1: continue
		var wanted := false
		for block in scene.segments:
			if not game.story_director.seen_scene_ids.has(block.id) and allowed(game,block.conditions): wanted = true
		var anchor: String = str(scene.insert_after_scene_id)
		if wanted and game.story_catalog.loaded and not game.story_director.seen_scene_ids.has(anchor) and game.story_catalog.has_scene(anchor):
			if game.story_director.start_scene(anchor,game._story_context(),Constants.SCREEN_MANAGEMENT):
				game._story_show_active_scene()
				return true
	# The same existing eligibility service owns numeric unlock requirements.
	for event in game.DuoLinkServiceScript.eligible_memory_event_ids(game.update3_profile,game.update3_active_run,game._update3_duo_member_progress(),DataRegistry.update3_duo_links):
		var ready := true
		for definition in DataRegistry.update3_duo_links.values():
			if definition.unlock_condition.event_id!=event: continue
			for member in definition.member_instance_ids:
				if not owned(game).has(str(DataRegistry.monster_instance(member).species_id)): ready = false
		if not ready: continue
		var result: Dictionary = game.DuoLinkServiceScript.complete_memory_event(game.update3_profile,event,DataRegistry.update3_duo_links)
		if result.get("ok",false):
			game.update3_profile = result.profile
			game._record_update3_metric_count("new_duo_memories_this_run",1)
			var flags: Dictionary = game.update3_active_run.get("front_flags",{}).duplicate(true)
			flags["event_%s_choice" % event] = "remember_together"
			game.update3_active_run["front_flags"] = flags
	for kind in ["day_overlays","bond_scenes","duo_scenes"]:
		for scene in scenes(kind):
			if game.story_director.seen_scene_ids.has(scene.id): continue
			if kind=="day_overlays" and int(scene.day)!=GameState.day: continue
			if kind=="day_overlays" and int(game.campaign_cycle_index)>1: continue
			if kind=="duo_scenes" and not game.update3_profile.get("duo_links",{}).get("unlocked",[]).has(scene.duo_id): continue
			if kind=="day_overlays":
				for block in scene.segments:
					if not game.story_director.seen_scene_ids.has(block.id) and allowed(game,block.conditions):
						lines.append_array(entries(scene,block)); ids.append(block.id)
			else:
				if not allowed(game,scene.conditions): continue
				lines.append_array(entries(scene))
				ids.append(scene.id)
	return start(game,lines,ids)

func first_battle(game: Node, deployed_species: Array) -> bool:
	if GameState.day==29: return false
	var lines: Array = []; var ids: Array = []
	for scene in scenes("join_scenes"):
		if scene.trigger!="precombat_confirmed" or not deployed_species.has(scene.monster_id) or game.story_director.seen_scene_ids.has(scene.id): continue
		if allowed(game,scene.conditions): lines.append_array(entries(scene)); ids.append(scene.id)
	return start(game,lines,ids,"v130r_first_battle")

func memory(game: Node, species: String, memory_id: String) -> bool:
	for scene in scenes("bond_scenes"):
		if scene.monster_id==species and scene.memory_id==memory_id and allowed(game,scene.conditions): return start(game,entries(scene),[scene.id])
	return false

func reset_battle() -> void:
	bark_clock = 0.0; bark_gap = 0.0; bark_last.clear(); bark_queue.clear()
	bark_locale = LanguageSettings.locale
	victory_cue.clear()
	clear_bark()

func bark(game: Node, unit: Node, event: String) -> bool:
	if not is_instance_valid(unit) or not unit.is_alive() or unit.faction!="monster": return false
	var key: String = str(unit.unit_id)+":"+event
	if bark_clock-float(bark_last.get(key,-1000.0))<25.0: return false
	for scene in scenes("barks"):
		if scene.monster_id!=unit.unit_id or scene.trigger!=event: continue
		if event=="victory" and victory_cue.is_empty(): victory_cue = scene.cues[0].duplicate(true)
		var priority: int = {"hp_below_30":5,"ally_downed":5,"victory":4,"hungry":3,"skill_used":2,"engagement_started":1,"deployed":0}.get(event,0)
		bark_last[key] = bark_clock
		bark_queue.append({"unit":weakref(unit),"cue":scene.cues[0],"expires":bark_clock+10.0,"priority":priority})
		bark_queue.sort_custom(func(a,b): return int(a.priority)>int(b.priority))
		while bark_queue.size()>5: bark_queue.pop_back()
		return true
	return false

func clear_bark() -> void:
	if is_instance_valid(bark_panel): bark_panel.queue_free()
	bark_panel = null; bark_remaining = 0.0

func tick_barks(game: Node, delta: float) -> void:
	if bark_locale!=LanguageSettings.locale:
		clear_bark(); bark_queue.clear(); bark_locale = LanguageSettings.locale
	bark_clock += delta; bark_gap = maxf(0,bark_gap-delta)
	if is_instance_valid(bark_panel):
		bark_remaining -= delta
		if bark_remaining<=0: clear_bark()
	if is_instance_valid(bark_panel) or bark_gap>0 or DisplayServer.get_name()=="headless": return
	while not bark_queue.is_empty():
		var next: Dictionary = bark_queue.pop_front()
		var unit = next.unit.get_ref()
		if not is_instance_valid(unit) or not unit.is_alive() or float(next.expires)<bark_clock: continue
		# Same dark bordered panel, portrait and typography as CombatStoryFeed.
		bark_panel = game.hud.panel(Rect2(32,212,1080,160),Color("#0b0e18ec"),Color("#655578"),"V130RCombatBark","flat")
		bark_panel.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED; bark_panel.z_index = 116
		var cue: Dictionary = next.cue
		var path: String = game._onboarding_speaker_portrait_path(cue.speaker_id,cue.portrait_emotion,true)
		if path!="": game.hud.texture(bark_panel,path,Rect2(16,20,100,112))
		game.hud.label(bark_panel,cue.speaker_label,Vector2(132,12),Vector2(912,32),22,Color("#e8bd76"))
		var label: Label = game.hud.label(bark_panel,cue.text,Vector2(132,48),Vector2(912,96),23,Color("#f4eadc"))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ignore_input(bark_panel); bark_remaining = 3.5; bark_gap = 4.5
		return

func ignore_input(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE; node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children(): ignore_input(child)

func show_victory(game: Node) -> void:
	if victory_cue.is_empty(): return
	var cue: Dictionary = victory_cue
	var panel: Control = game.hud.panel(Rect2(32,112,1080,112),Color("#0b0e18ec"),Color("#655578"),"V130RVictoryBark","flat")
	panel.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED; panel.z_index = 116
	game.hud.label(panel,cue.speaker_label,Vector2(20,10),Vector2(1040,30),22,Color("#e8bd76"))
	var text: Label = game.hud.label(panel,cue.text,Vector2(20,44),Vector2(1040,62),23,Color("#f4eadc"))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ignore_input(panel)
	game.get_tree().create_timer(3.5).timeout.connect(func():
		if is_instance_valid(panel): panel.queue_free())
