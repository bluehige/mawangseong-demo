extends "res://scripts/game/ApprovedBattleController.gd"
## No combat overrides: only replace per-tick raster work in headless trials.
var observe_engagement := OS.get_environment("MAWANG_TEST_ENGAGEMENT")=="1"
var encounter_rows := {}
var active_encounters := {}

func physics_process(delta: float) -> void:
	if observe_engagement and running and not root.combat_paused: _observe_contacts()
	super.physics_process(delta)

func _observe_contacts() -> void:
	var now := {}
	for enemy in root.enemy_units:
		if not enemy.is_alive(): continue
		for defender in root.monster_units:
			if not defender.is_alive() or not defender.is_targetable_by(enemy): continue
			if enemy.position.distance_to(defender.position)>defender.attack_range: continue
			var key := str(enemy.get_instance_id())+":"+str(defender.get_instance_id())
			now[key]=true
			if not encounter_rows.has(key):
				var axis: Vector2=(goal_point(enemy)-enemy.position).normalized()
				encounter_rows[key]={"enemy":enemy.unit_id,"defender":defender.unit_id,"objective":bool(enemy.get_meta("objective_priority",false)),"entry":root.combat_time,"attacks":0,"engaged":false,"passed":false,"entry_projection":(enemy.position-defender.position).dot(axis),"axis":axis,"enemy_node":enemy,"defender_node":defender}
			var row: Dictionary=encounter_rows[key]
			row["last"]=root.combat_time
	for key in active_encounters:
		if now.has(key): continue
		var row: Dictionary=encounter_rows[key]
		if row.enemy_node.is_alive() and row.defender_node.is_alive() and not row.engaged and row.entry_projection<=0 and (row.enemy_node.position-row.defender_node.position).dot(row.axis)>16: row.passed=true
	active_encounters=now

func _hold_attack_position(unit: Node, target: Node) -> bool:
	var held: bool=super._hold_attack_position(unit,target)
	if held: _record_engagement(unit,target)
	return held

func _move_to_attack_target(unit: Node, target: Node, preserve_goal: bool = false) -> void:
	super._move_to_attack_target(unit,target,preserve_goal)
	_record_engagement(unit,target)

func _record_engagement(unit: Node, target: Node) -> void:
	if not observe_engagement or unit.faction!=Constants.FACTION_ENEMY: return
	var key := str(unit.get_instance_id())+":"+str(target.get_instance_id())
	if encounter_rows.has(key): encounter_rows[key].engaged=true

func _perform_standard_attack(attacker: Node, target: Node, fighting_retreat: bool = false, contact_callback: Callable = Callable()) -> Dictionary:
	var result: Dictionary=super._perform_standard_attack(attacker,target,fighting_retreat,contact_callback)
	if observe_engagement and attacker.faction==Constants.FACTION_ENEMY and not result.is_empty():
		var key := str(attacker.get_instance_id())+":"+str(target.get_instance_id())
		if encounter_rows.has(key): encounter_rows[key].attacks+=1; encounter_rows[key].engaged=true
	return result

func engagement_report() -> Dictionary:
	var result := {"contacts":0,"engaged":0,"attacks":0,"ignored_passes":0,"killed_before_response":0,"rows":[]}
	for source in encounter_rows.values():
		var row: Dictionary=source.duplicate()
		row.erase("enemy_node"); row.erase("defender_node"); row.erase("axis")
		result.contacts+=1
		result.engaged+=int(row.engaged)
		result.attacks+=int(row.attacks)
		result.ignored_passes+=int(row.passed)
		result.killed_before_response+=int(not row.engaged and not row.passed and not source.enemy_node.is_alive())
		result.rows.append(row)
	return result

func _init() -> void: map=preload("res://tools/tests/V130RB04FastMap.gd").new()
func spawn_damage_number(_point: Vector2, _damage: int, _faction: String, _anchor = null) -> void: pass
func spawn_contact_effect(_id: String, _point: Vector2, _seconds: float, _growth: float) -> void: pass
func spawn_effect_burst(_id: String, _point: Vector2, _offset: Vector2 = Vector2.ZERO, _scale: Vector2 = Vector2.ONE, _fps: float = 0.0) -> void: pass
func make_unit(id: String, stats: Dictionary, faction: String, room_id: String) -> Node:
	var unit = preload("res://tools/tests/V130RB04FastUnit.gd").new()
	unit.battle_map=map; unit.battle_runtime=self
	actors.add_child(unit); unit.setup(id,stats,faction,room_id)
	unit.attach_map_visuals(visuals)
	root._connect_combat_unit(unit)
	return unit
