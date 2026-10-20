extends "res://tools/tests/V130RStep8Simulation.gd"
## Observation only: retain every production movement, attack and facility rule.
var facility_losses: Array = []
var road_traces := {}
var observed_disables := {}
var trace_tick := 0.0
var omit_cosmetics := false

func spawn_damage_number(point: Vector2, damage: int, faction: String, anchor = null) -> void:
	if not omit_cosmetics: super.spawn_damage_number(point,damage,faction,anchor)

func spawn_contact_effect(id: String, point: Vector2, seconds: float, growth: float) -> void:
	if not omit_cosmetics: super.spawn_contact_effect(id,point,seconds,growth)

func spawn_enemy(id: String, entry: Dictionary = {}) -> void:
	super.spawn_enemy(id,entry)
	var unit: Node = root.enemy_units[-1]
	var key := str(root.spawned_count)
	unit.set_meta("spread_trace_id",key)
	road_traces[key] = {"id":id,"goal":unit.goal_room,"cells":[],"last":""}

func physics_process(delta: float) -> void:
	super.physics_process(delta)
	trace_tick += delta
	if trace_tick<.25: return
	trace_tick = 0
	for enemy in root.enemy_units:
		if not enemy.is_alive(): continue
		var key := str(enemy.get_meta("spread_trace_id",""))
		if not road_traces.has(key): continue
		var c: Vector2i = map.cell(enemy.position)
		var value := "%d,%d" % [c.x,c.y]
		if road_traces[key].last!=value:
			road_traces[key].cells.append([c.x,c.y]); road_traces[key].last = value

func update_room_effects(delta: float) -> void:
	super.update_room_effects(delta)
	for id in map.layout.doors:
		var until := float(map.rooms[id].get("disabled_until",0))
		if until>float(observed_disables.get(id,0)):
			observed_disables[id] = until
			facility_losses.append({"building":id,"time":root.combat_time,"disabled_until":until})
