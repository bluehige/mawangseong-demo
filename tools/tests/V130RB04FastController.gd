extends "res://scripts/game/ApprovedBattleController.gd"
## No combat overrides: only replace per-tick raster work in headless trials.
func _init() -> void: map=preload("res://tools/tests/V130RB04FastMap.gd").new()
func spawn_damage_number(_point: Vector2, _damage: int, _faction: String, _anchor = null) -> void: pass
func spawn_contact_effect(_id: String, _point: Vector2, _seconds: float, _growth: float) -> void: pass
func make_unit(id: String, stats: Dictionary, faction: String, room_id: String) -> Node:
	var unit = preload("res://tools/tests/V130RB04FastUnit.gd").new()
	unit.battle_map=map; unit.battle_runtime=self
	actors.add_child(unit); unit.setup(id,stats,faction,room_id)
	unit.attach_map_visuals(visuals)
	root._connect_combat_unit(unit)
	return unit
