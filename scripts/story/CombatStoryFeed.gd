extends RefCounted
# Ordinary battle reactions never own keyboard focus or pause the simulation.
const Reader = preload("res://scripts/story/StoryDirector.gd")
var pending: Array[Dictionary] = []
var presented: Dictionary = {}
var reader = null
var active: Dictionary = {}
var panel: Control
var remaining := 0.0

func clear() -> void:
	pending.clear()
	presented.clear()
	reader = null
	active.clear()
	_clear_panel()

func enqueue(root: Node, scene: Dictionary, facts: Dictionary) -> void:
	var key := str(facts.get("battle_scope_id", "")) + ":" + str(scene.get("id", ""))
	if presented.has(key): return
	presented[key] = true
	var entry := {"scene":scene, "facts":facts.duplicate(true), "at":float(root.combat_time)}
	var priority := int(scene.get("metadata", {}).get("feed_priority", 0))
	# Immediate combat facts replace an older remark; unread lines remain unread.
	if reader != null and priority > int(active.get("scene", {}).get("metadata", {}).get("feed_priority", 0)):
		reader = null
		active.clear()
		_clear_panel()
	pending.append(entry)
	pending.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		return int(a.scene.get("metadata", {}).get("feed_priority", 0)) > int(b.scene.get("metadata", {}).get("feed_priority", 0)))
	while pending.size() > 4: pending.pop_back()

func tick(root: Node, delta: float) -> void:
	if root.current_screen != "combat":
		clear()
		return
	if root.combat_paused or root.story_combat_overlay_open:
		if is_instance_valid(panel): panel.visible = not root.story_combat_overlay_open
		return
	if is_instance_valid(panel): panel.visible = true
	if reader != null and not _still_relevant(root,active):
		reader = null
		active.clear()
		_clear_panel()
	if reader == null:
		_start_next(root)
		return
	if not is_instance_valid(panel): _show(root, false)
	remaining -= delta
	if remaining > 0.0: return
	var result: Dictionary = reader.advance(false)
	_copy_read_flags(root)
	if bool(result.get("completed", false)):
		reader = null
		active.clear()
		_clear_panel()
		_start_next(root)
	else:
		_show(root)

func _still_relevant(root: Node, entry: Dictionary) -> bool:
	var scene: Dictionary = entry.get("scene", {})
	var event := str(scene.get("metadata", {}).get("required_event", ""))
	if event != "" and not bool(root._story_live_combat_events().get(event, false)): return false
	# Do not deliver an old tactical instruction after the engagement has moved on.
	return float(root.combat_time) - float(entry.get("at", 0.0)) <= 12.0

func _start_next(root: Node) -> void:
	while not pending.is_empty():
		var entry: Dictionary = pending.pop_front()
		if not _still_relevant(root,entry): continue
		reader = Reader.new()
		reader.setup(root.story_catalog,GameState.day)
		if reader.start_scene(str(entry.scene.id),entry.facts,"combat"):
			active = entry
			_show(root)
			return
		reader = null

func _copy_read_flags(root: Node) -> void:
	for id in reader.seen_cue_ids:
		if not root.story_director.seen_cue_ids.has(id): root.story_director.seen_cue_ids.append(id)
	for id in reader.seen_scene_ids:
		if not root.story_director.seen_scene_ids.has(id): root.story_director.seen_scene_ids.append(id)
	for id in reader.seen_scene_scope_ids:
		if not root.story_director.seen_scene_scope_ids.has(id): root.story_director.seen_scene_scope_ids.append(id)

func _show(root: Node, new_cue: bool = true) -> void:
	_clear_panel()
	var cue: Dictionary = reader.current_cue()
	var speaker: Dictionary = root._story_resolve_cue_speaker(cue)
	var name := LanguageSettings.story_speaker(speaker, root._onboarding_player_name())
	var text := LanguageSettings.story_text(cue, root._onboarding_player_name())
	panel = root.hud.panel(Rect2(32,112,1080,160),Color("#0b0e18ec"),Color("#655578"),"StoryCombatFeed","flat")
	panel.name = "StoryCombatFeed"
	panel.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	panel.z_index = 115
	var portrait_path: String = root._onboarding_speaker_portrait_path(str(speaker.get("speaker_id","")),str(speaker.get("portrait_emotion","")))
	if portrait_path != "": root.hud.texture(panel,portrait_path,Rect2(16,20,100,112))
	root.hud.label(panel,name,Vector2(132,12),Vector2(912,32),22,Color("#e8bd76"),HORIZONTAL_ALIGNMENT_LEFT,"StoryCombatFeedSpeaker")
	var body: Label = root.hud.label(panel,text,Vector2(132,48),Vector2(912,96),23,Color("#f4eadc"),HORIZONTAL_ALIGNMENT_LEFT,"StoryCombatFeedText")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ignore_input(panel)
	if new_cue:
		root._log("%s: %s" % [name,text])
		remaining = clampf(1.8 + text.length() * 0.055, 2.8, 5.0)

func refresh_locale(root: Node) -> void:
	if reader == null:
		return
	_show(root, false)
	var text := LanguageSettings.story_text(reader.current_cue(), root._onboarding_player_name())
	remaining = clampf(1.8 + text.length() * 0.055, 2.8, 5.0)
	panel.visible = not root.story_combat_overlay_open

func _ignore_input(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children(): _ignore_input(child)

func _clear_panel() -> void:
	if is_instance_valid(panel):
		if panel.get_parent() != null: panel.get_parent().remove_child(panel)
		panel.queue_free()
	panel = null
