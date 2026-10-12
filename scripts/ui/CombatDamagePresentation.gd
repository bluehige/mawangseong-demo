extends RefCounted
# Presentation only: never applies damage, consumes resources or changes combat time.
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const MAX_VISIBLE_NUMBERS := 32
const MERGE_SECONDS := 0.10
const LIFETIME_SECONDS := 0.72
const MAX_IMPACT_SCALE := 1.25
const LANE_OFFSETS := [Vector2.ZERO, Vector2(-28, -14), Vector2(28, -24), Vector2(-48, -38), Vector2(48, -50)]

var root: Node
var active: Array[Dictionary] = []
var pool: Array[Label] = []
var clock := 0.0
var submitted := 0
var merged := 0
var suppressed := 0
var layout_declines := 0

func setup(value: Node) -> void:
	root = value

func reset() -> void:
	for row in active:
		_dispose(row.label)
	for label in pool:
		_dispose(label)
	active.clear()
	pool.clear()
	clock = 0.0
	submitted = 0
	merged = 0
	suppressed = 0
	layout_declines = 0

func _dispose(label) -> void:
	if not is_instance_valid(label): return
	if label.get_parent() != null: label.get_parent().remove_child(label)
	label.queue_free()

func show_number(anchor: Vector2, damage: int, faction: String, target_id: int, source: String, kind: String, lane: int, simulation_time: float) -> Label:
	if damage <= 0 or root == null or root.effect_root == null: return null
	submitted += 1
	var key := "%d:%s:%s" % [target_id, source, kind]
	# Public legacy visual probes use the old simulation-time window. Runtime
	# contacts use presentation seconds, independent of x1/x3 simulation speed.
	var merge_time := simulation_time if kind == "legacy" else clock
	var window := 0.15 if kind == "legacy" else MERGE_SECONDS
	if target_id != 0:
		for row in active:
			if row.key == key and merge_time - float(row.merge_time) >= 0.0 and merge_time - float(row.merge_time) <= window:
				row.total = int(row.total) + damage
				row.hits = int(row.hits) + 1
				row.peak = maxi(int(row.peak), damage)
				# Do not prolong one number forever during a continuous barrage.
				if clock - float(row.last_pulse) >= 0.08:
					row.pulse_age = 0.0
					row.last_pulse = clock
				merged += 1
				_style(row)
				_draw(row)
				return row.label
	var priority := _priority(damage, kind)
	if active.size() >= MAX_VISIBLE_NUMBERS:
		var victim := -1
		for index in range(active.size()):
			if int(active[index].priority) <= priority and (victim < 0 or int(active[index].priority) < int(active[victim].priority)):
				victim = index
		if victim < 0:
			suppressed += 1
			return null
		_retire(victim)
		suppressed += 1
	var label: Label = pool.pop_back() if not pool.is_empty() else Label.new()
	if label.get_parent() == null: root.effect_root.add_child(label)
	var near_count := 0
	for row in active:
		if Vector2(row.anchor).distance_to(anchor) < 70.0: near_count += 1
	var row := {
		"label": label, "key": key, "anchor": anchor, "total": damage,
		"peak": damage, "hits": 1, "age": 0.0, "pulse_age": 0.0,
		"merge_time": merge_time, "last_pulse": clock, "faction": faction,
		"priority": priority, "kind": kind, "lane": lane,
		"offset": LANE_OFFSETS[posmod(lane, LANE_OFFSETS.size())] + Vector2(0, -float(near_count / 5) * 24.0)
	}
	label.visible = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 3100
	label.set_meta("combat_feedback_kind", "damage")
	label.set_meta("damage_number_lane", lane)
	label.set_meta("damage_merge_key", key)
	label.set_meta("damage_kind", kind)
	active.append(row)
	_style(row)
	# Place just the incoming number. Repack the batch once on the next tick,
	# rather than doing a full O(n^2) layout for every hit in one frame.
	_draw(row)
	return label

func tick(delta: float) -> void:
	if root == null or root.current_screen != "combat" or root.combat_paused: return
	clock += maxf(0.0, delta)
	for index in range(active.size() - 1, -1, -1):
		var row := active[index]
		if not is_instance_valid(row.label):
			active.remove_at(index)
			continue
		row.age = float(row.age) + delta
		row.pulse_age = float(row.pulse_age) + delta
		if float(row.age) >= LIFETIME_SECONDS:
			_retire(index)
	_layout()

func _layout() -> void:
	# Stable oldest-first placement prevents two moving labels from chasing
	# each other's previous-frame rectangles upward during a dense barrage.
	for row in active: row.erase("screen_rect")
	for row in active: _draw(row)

func _retire(index: int) -> void:
	var label: Label = active[index].label
	active.remove_at(index)
	if is_instance_valid(label):
		label.visible = false
		label.set_meta("combat_feedback_kind", "pooled_damage")
		pool.append(label)

func _priority(damage: int, kind: String) -> int:
	return int(kind in ["skill_melee", "area", "counter", "dash"]) + int(damage >= 40)

static func font_size(damage: int) -> int:
	return 24 + mini(6, maxi(0, damage) / 16)

static func impact_scale(damage: int) -> float:
	return 1.18 if damage >= 55 else 1.08 if damage >= 30 else 1.0

static func screen_compensation(zoom: float, window: Vector2, viewport: Vector2) -> float:
	var stretch := 1.0
	if window.x > 0 and window.y > 0 and viewport.x > 0 and viewport.y > 0:
		stretch = minf(window.x / viewport.x, window.y / viewport.y)
	return 1.0 / maxf(0.1, zoom * stretch)

func _style(row: Dictionary) -> void:
	var label: Label = row.label
	var font := UIFontScript.font_for_role(UIFontScript.ROLE_DAMAGE)
	var size := UISettings.scaled_font_size(font_size(int(row.peak)))
	label.text = "-%d" % int(row.total)
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#ffaaa4") if row.faction == "monster" else Color("#ffe68e"))
	label.add_theme_color_override("font_outline_color", Color("#241522"))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_shadow_color", Color("#120a18c0"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.size = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size) + Vector2(16, 12)
	label.pivot_offset = label.size * 0.5
	label.set_meta("damage_total", int(row.total))
	label.set_meta("damage_hit_count", int(row.hits))
	label.set_meta("damage_peak_hit", int(row.peak))

func _draw(row: Dictionary) -> void:
	var label: Label = row.label
	var viewport: Vector2 = root.get_viewport().get_visible_rect().size
	var window := Vector2(DisplayServer.window_get_size()) if DisplayServer.get_name() != "headless" else viewport
	var zoom := float(root.combat_view_zoom) if root.combat_camera != null and root.combat_camera.enabled else 1.0
	var compensation := screen_compensation(zoom, window, viewport)
	var pulse := float(row.pulse_age)
	var pop := 1.0
	if pulse < 0.08:
		pop = lerpf(0.80, 1.12, 1.0 - pow(1.0 - pulse / 0.08, 3.0))
	elif pulse < 0.22:
		pop = 1.0 + 0.12 * pow(1.0 - (pulse - 0.08) / 0.14, 2.0)
	var impact := minf(MAX_IMPACT_SCALE, pop * impact_scale(int(row.peak)))
	label.scale = Vector2.ONE * compensation * impact
	var offset: Vector2 = row.offset
	offset += Vector2(0, -28.0 - 32.0 * minf(1.0, float(row.age) / LIFETIME_SECONDS))
	var center: Vector2 = row.anchor + offset * compensation
	# Keep the whole number inside the physical viewport, including long sums.
	if DisplayServer.get_name() != "headless" and root.has_method("_combat_world_to_screen"):
		var screen: Vector2 = root._combat_world_to_screen(center) if root.combat_camera.enabled else center
		# Reserve the maximum pulse rectangle so settling numbers do not swap
		# lanes, and keep damage away from the top status and bottom controls.
		var half := label.size * compensation * zoom * MAX_IMPACT_SCALE * 0.5
		var padding := 6.0 * compensation * zoom
		var found := false
		var base_screen := screen
		for attempt in range(72):
			var column: int = attempt / 12
			var column_step: int = (column + 1) / 2
			var column_sign := 1.0 if column % 2 == 1 else -1.0
			var row_index := attempt % 12
			var row_step := -float(row_index) if row_index < 8 else float(row_index - 7)
			screen = base_screen + Vector2(column_sign * column_step * (half.x * 2.0 + padding), row_step * (half.y * 2.0 + padding))
			screen.x = clampf(screen.x, half.x + padding, maxf(half.x + padding, viewport.x - half.x - padding))
			screen.y = clampf(screen.y, half.y + 112.0, maxf(half.y + 112.0, viewport.y - 210.0 - half.y))
			var rect := Rect2(screen - half, half * 2.0).grow(padding * 0.5)
			var collision := false
			for other in active:
				if other.label != label and other.has("screen_rect") and rect.intersects(other.screen_rect):
					collision = true
					break
			if not collision:
				row.screen_rect = rect
				found = true
				break
		label.visible = found
		label.set_meta("damage_layout_suppressed", not found)
		if not found and not row.has("layout_suppressed"):
			row.layout_suppressed = true
			layout_declines += 1
		center = root._combat_screen_to_world(screen) if root.combat_camera.enabled else screen
	label.position = center - label.size * 0.5
	label.modulate.a = 1.0 if float(row.age) <= 0.38 else clampf((LIFETIME_SECONDS - float(row.age)) / (LIFETIME_SECONDS - 0.38), 0.0, 1.0)
	label.set_meta("damage_screen_compensation", compensation)
	label.set_meta("damage_impact_scale", impact)

func debug_snapshot() -> Dictionary:
	var visible := 0
	for row in active:
		if is_instance_valid(row.label) and row.label.visible: visible += 1
	return {"active": active.size(), "visible": visible, "pooled": pool.size(), "submitted": submitted, "merged": merged, "overflow_replacements_or_rejections": suppressed, "layout_declines": layout_declines, "clock": clock}
