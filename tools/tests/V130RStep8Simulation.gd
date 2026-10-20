extends "res://tools/tests/V130RStep7Simulation.gd"
func make_unit(id: String, stats: Dictionary, faction: String, room_id: String) -> Node:
	var unit = preload("res://tools/tests/V130RStep8FastUnit.gd").new()
	unit.battle_map = map; unit.battle_runtime = self
	actors.add_child(unit); unit.setup(id,stats,faction,room_id)
	unit.attach_map_visuals(visuals); unit.downed.connect(on_unit_downed)
	unit.omit_raster = DisplayServer.get_name()=="headless"
	return unit
