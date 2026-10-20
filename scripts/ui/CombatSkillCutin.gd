extends RefCounted
# Reads successful casts. No combat callback, reward action, pause owner or input.
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const MAX_PENDING := 2
const GLOBAL_INTERVAL := 1.5
const ACTOR_SKILL_INTERVAL := 6.0
const PENDING_LIFETIME := 2.0
var root: Node
var layer: CanvasLayer
var panel: Panel
var pending: Array[Dictionary] = []
var seen: Array[String] = []
var cooldowns := {}
var current := {}
var clock := 0.0
var last_started := -GLOBAL_INTERVAL
var age := 0.0
var epoch := 0
var displayed := 0
var dropped := 0
var last_mode := ""

func setup(value: Node) -> void:
	root = value
	layer = CanvasLayer.new()
	layer.name = "CombatSkillCutinLayer"
	layer.layer = 0 # All existing HUD, dialogue and menus remain above this layer.
	root.add_child(layer)
	last_mode = UISettings.combat_cutin_mode

func reset() -> void:
	cancel()
	seen.clear()
	cooldowns.clear()
	clock = 0.0
	last_started = -GLOBAL_INTERVAL
	epoch += 1
	displayed = 0
	dropped = 0

func cancel() -> void:
	pending.clear()
	current.clear()
	if is_instance_valid(panel):
		panel.get_parent().remove_child(panel)
		panel.queue_free()
	panel = null

func protected() -> bool:
	return root.current_screen != "combat" or root.combat_paused or root.pause_menu_open or root.story_combat_overlay_open or root.continuity.backlog_open or root.continuity.update_open

func enqueue(unit: Node, skill_id: String, definition: Dictionary = {}) -> bool:
	if last_mode != UISettings.combat_cutin_mode:
		cancel()
		last_mode = UISettings.combat_cutin_mode
	if UISettings.combat_cutin_mode == "off" or protected() or not is_instance_valid(unit): return false
	var key := "%d:%s" % [unit.get_instance_id(), skill_id]
	var cast_id := "%d:%s:%d" % [epoch, key, int(floor(float(root.combat_time) * 60.0 + 0.0001))]
	if seen.has(cast_id): return false
	seen.append(cast_id)
	if seen.size() > 64: seen.pop_front()
	if clock - float(cooldowns.get(key, -ACTOR_SKILL_INTERVAL)) < ACTOR_SKILL_INTERVAL:
		dropped += 1
		return false
	var skill: Dictionary = DataRegistry.skill(skill_id) if definition.is_empty() else definition
	var packet := {
		"key": key, "cast_id": cast_id, "at": clock, "skill_id": skill_id,
		"name": LanguageSettings.ui_text(str(unit.display_name)),
		"skill_name": LanguageSettings.ui_text(str(skill.get("display_name", skill_id))),
		"icon": str(skill.get("icon", "")),
		"portrait": root.management_scene.monster_portrait_path(str(unit.unit_id)),
		"priority": int(unit == root.selected_unit) + int(str(root.monster_roster.get(unit.unit_id, {}).get("promotion_id", "")) != "")
	}
	if pending.size() >= MAX_PENDING:
		var victim := -1
		for index in range(pending.size()):
			if int(pending[index].priority) < int(packet.priority): victim = index; break
		if victim < 0: dropped += 1; return false
		pending.remove_at(victim)
		dropped += 1
	pending.append(packet)
	return true

func tick(delta: float) -> void:
	if not is_instance_valid(root): return
	var mode: String = UISettings.combat_cutin_mode
	if last_mode != mode:
		cancel()
		last_mode = mode
	if mode == "off" or protected(): cancel(); return
	clock += maxf(0.0, delta)
	if not current.is_empty():
		for protected_rect in _protected_rects():
			if Rect2(panel.position, panel.size).intersects(protected_rect):
				cancel()
				return
		age += delta
		var duration := 0.75 if current.mode == "full" else 0.45
		if age >= duration:
			current.clear()
			if is_instance_valid(panel): panel.get_parent().remove_child(panel); panel.queue_free()
			panel = null
		else:
			var entrance := clampf(age / 0.10, 0.0, 1.0)
			panel.position = Vector2(current.position) + Vector2(36.0 * pow(1.0 - entrance, 3.0), 0)
			panel.modulate.a = clampf(entrance, 0.0, 1.0) * minf(1.0, (duration - age) / 0.12)
	for index in range(pending.size() - 1, -1, -1):
		if clock - float(pending[index].at) > PENDING_LIFETIME:
			pending.remove_at(index)
			dropped += 1
	if current.is_empty() and not pending.is_empty() and clock - last_started >= GLOBAL_INTERVAL:
		var packet: Dictionary = pending.pop_front()
		if clock - float(cooldowns.get(packet.key, -ACTOR_SKILL_INTERVAL)) < ACTOR_SKILL_INTERVAL:
			dropped += 1
			return
		_show(packet, "simple" if UISettings.reduce_combat_effects else mode)

func _protected_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for control in root.ui_layer.find_children("*", "Control", true, false):
		if control.is_visible_in_tree() and (control is BaseButton or "Inspector" in control.name or control.name in ["StoryCombatFeed", "PromotionContributionNotice"]):
			result.append(control.get_global_rect())
	for row in root.combat_scene.damage_presentation.active:
		if row.has("screen_rect") and row.label.visible: result.append(row.screen_rect)
	return result

func _choose_rect(mode: String) -> Rect2:
	var font := UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS)
	var height := maxf(94.0, font.get_height(UISettings.scaled_font_size(20)) * 2.0 + 24.0)
	var candidates := [Rect2(1320, 112, 520, 250), Rect2(710, 112, 520, 250), Rect2(710, 520, 520, 250)] if mode == "full" else [Rect2(740, 112, 420, height), Rect2(1410, 120, 420, height), Rect2(740, 740, 420, height)]
	var protected_rects := _protected_rects()
	for candidate in candidates:
		var blocked := false
		for rect in protected_rects:
			if Rect2(candidate.position, candidate.size + Vector2(36, 0)).intersects(rect): blocked = true; break
		if not blocked: return candidate
	return Rect2()

func _show(packet: Dictionary, mode: String) -> void:
	var rect := _choose_rect(mode)
	if rect.size == Vector2.ZERO and mode == "full":
		mode = "simple"
		rect = _choose_rect(mode)
	if rect.size == Vector2.ZERO: dropped += 1; return
	var portrait: Texture2D = root._onboarding_portrait_texture(packet.portrait) if mode == "full" and packet.portrait != "" else null
	if mode == "full" and portrait == null:
		mode = "simple"
		rect = _choose_rect(mode)
		if rect.size == Vector2.ZERO: dropped += 1; return
	panel = Panel.new()
	panel.name = "CombatSkillCutin"
	panel.position = rect.position
	panel.size = rect.size
	panel.modulate.a = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#21172de8")
	style.border_color = Color("#d8b370")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var art := TextureRect.new()
	art.name = "SkillCutinArt"
	art.texture = portrait if mode == "full" else root._load_png(packet.icon) if packet.icon != "" else null
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.position = Vector2(12, 8)
	art.size = Vector2(210, 232) if mode == "full" else Vector2(58, 58)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(art)
	var label := Label.new()
	label.name = "SkillCutinText"
	label.text = "%s\n%s" % [packet.name, packet.skill_name]
	label.position = Vector2(234, 55) if mode == "full" else Vector2(84, 10)
	label.size = Vector2(268, 170) if mode == "full" else Vector2(320, rect.size.y - 24.0)
	var font := UIFontScript.font_for_role(UIFontScript.ROLE_EMPHASIS)
	var font_size := UISettings.scaled_font_size(27 if mode == "full" else 20)
	while font_size > 18 and maxf(font.get_string_size(packet.name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, font.get_string_size(packet.skill_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) > label.size.x:
		font_size -= 1
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#ffe9b1"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	panel.set_meta("cutin_portrait_path", packet.portrait)
	panel.set_meta("cutin_mode", mode)
	panel.set_meta("cutin_cast_id", packet.cast_id)
	current = packet.duplicate()
	current.mode = mode
	current.position = rect.position
	last_started = clock
	cooldowns[packet.key] = clock
	age = 0.0
	displayed += 1

func debug_snapshot() -> Dictionary:
	return {"pending": pending.size(), "active": not current.is_empty(), "displayed": displayed, "dropped": dropped, "clock": clock}
