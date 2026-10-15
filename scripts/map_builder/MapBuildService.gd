extends RefCounted
class_name MapBuildService

const Plot = preload("res://scripts/map_builder/PlotMask.gd")
const Roads = preload("res://scripts/map_builder/AutoRoadBuilder.gd")
const Mask = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const Iso = preload("res://scripts/dungeon_quarter/IsoMath.gd")
const SITES := {"entrance":Vector2i(15,34), "throne":Vector2i(29,16), "barracks":Vector2i(21,24), "recovery":Vector2i(36,25), "treasure":Vector2i(30,34), "slot_01":Vector2i(23,39)}
const DOOR_SIDES := {"entrance":"E", "throne":"S", "barracks":"E", "recovery":"W", "treasure":"N", "slot_01":"N"}

# The graybox is an opt-in management runtime layout, never a save migration.
static func defense_state(root: Node, preset_id: String = "") -> Dictionary:
	var defense = preload("res://scripts/map_builder/DefenseLayout.gd")
	if preset_id == "" and root.has_meta("defense_layout_state"):
		return root.get_meta("defense_layout_state")
	var state: Dictionary = defense.build(defense.preset(preset_id if preset_id!="" else "A",DataRegistry.rooms))
	if state.ok: apply_defense_state(root,state)
	return state

static func apply_defense_state(root: Node, state: Dictionary) -> void:
	assert(state.ok)
	root.set_meta("defense_layout_state",state)
	# Graph-owned source for the renderer, hit testing, doors and defense dots.
	# Legacy campaign layout remains intact when the debug flag is switched off.
	root.graph.layout["defense_layout"] = state

# Pure legacy-layout conversion; never reads/writes user saves or changes stats.
# Room instance IDs, module types, replacement choices and object metadata survive.
# Runtime-only derived modules are owned by the layout, not DataRegistry.
static func prepare_layout(source: Dictionary, modules: Dictionary, grade_index: int = 0) -> Dictionary:
	if source.is_empty():
		return source.duplicate(true)
	var layout := source.duplicate(true)
	var plot := Plot.build(grade_index)
	var buildings: Array = []
	var placed: Array = []
	var doors: Array = []
	var rotated: Dictionary = {}
	var new_sites: Array = []
	var rows: Array = layout.get("placed_modules", []).duplicate(true)
	rows.sort_custom(func(a,b):
		var order := ["entrance","throne","barracks","recovery","treasure","slot_01"]
		var ai: int = order.find(a.get("instance_id",""))
		var bi: int = order.find(b.get("instance_id",""))
		return (ai if ai >= 0 else 99) < (bi if bi >= 0 else 99)
	)
	# Place newly unlocked rooms after all persisted footprints are reserved.
	for row in rows.duplicate():
		if bool(row.get("plot_new_site",false)):
			rows.erase(row)
			new_sites.append(row)
	rows.append_array(new_sites)
	for row in rows:
		var id := str(row.get("instance_id", ""))
		var module: Dictionary = modules.get(row.get("module_id", ""), {})
		if str(module.get("module_type", "")) != "room":
			continue
		var preferred := str(row.get("plot_door_side",DOOR_SIDES.get(id,"E")))
		if int(row.get("plot_rotation",0)) == 1:
			module = rotate_module(module)
			var rotated_id := "map_rotated_%s" % id
			module["id"] = rotated_id
			rotated[rotated_id] = module
			row["module_id"] = rotated_id
			preferred = {"N":"E","E":"S","S":"W","W":"N"}[preferred]
		var size := Iso.array_to_cell(module.get("size", [5,5]))
		var origin: Vector2i = SITES.get(id, Vector2i.ZERO) + plot["center"] - Vector2i(30,30)
		if source.has("plot_grid"):
			origin = Iso.array_to_cell(row.get("grid_origin", []))
			if bool(row.get("plot_new_site",false)): origin = _find_site(plot,buildings,size)
		elif not SITES.has(id):
			origin = _find_site(plot, buildings, size)
		if origin == Vector2i(-1,-1):
			layout["map_build_errors"] = ["no plot site for %s" % id]
			return layout
		row["grid_origin"] = [origin.x, origin.y]
		placed.append(row)
		buildings.append({"id":id, "rect":Rect2i(origin,size)})
		var selection := _socket_pair(module, preferred)
		var side := str(selection.get("side",""))
		var pair: Array = selection.get("sockets",[])
		if pair.size() != 2:
			layout["map_build_errors"] = ["adjacent width-2 socket pair missing: %s" % id]
			return layout
		var first: Vector2i = origin + Iso.array_to_cell(pair[0].get("cell",[])) + Mask.DIRS[side]
		var second: Vector2i = origin + Iso.array_to_cell(pair[1].get("cell",[])) + Mask.DIRS[side]
		var anchor := Vector2i(mini(first.x,second.x),mini(first.y,second.y))
		if side == "N": anchor.y -= 1
		if side == "W": anchor.x -= 1
		doors.append({"id":id,"building_id":id,"anchor":anchor,"side":side,"sockets":pair,"origin":origin})
	var ports := _outside_ports(source, placed, modules, plot, buildings)
	if not ports["errors"].is_empty():
		layout["map_build_errors"] = ports["errors"]
		return layout
	plot["blocked_cells"] = ports["cells"]
	var result := Roads.build(plot, buildings, doors)
	if not result["ok"]:
		layout["map_build_errors"] = result["errors"]
		return layout
	var aliases: Array = ["spike_corridor"]
	for requirement in source.get("required_paths", []):
		var id := str(requirement.get("to", ""))
		for row in rows:
			if row["instance_id"] == id and id != "outside_approach" and str(modules.get(row["module_id"],{}).get("module_type", "")) == "corridor" and not aliases.has(id):
				aliases.append(id)
	for zone in source.get("combat_topology",{}).get("defense_zones",[]):
		var references: Array = zone.get("room_ids",[]).duplicate()
		references.append(zone.get("anchor_room_id",""))
		for id in references:
			for row in rows:
				if row["instance_id"] == id and str(modules.get(row["module_id"],{}).get("module_type","")) in ["corridor","junction"] and not aliases.has(id):
					aliases.append(id)
	var compiled := preload("res://scripts/map_builder/RoadGraphCompiler.gd").compile(result["road_cells"], aliases, doors[0]["anchor"])
	var derived: Dictionary = compiled["modules"]
	derived.merge(rotated)
	var semantic_errors := _restore_road_semantics(derived,rows,modules,aliases)
	if not semantic_errors.is_empty():
		layout["map_build_errors"] = semantic_errors
		return layout
	var connections: Array = compiled["connections"]
	placed.append_array(compiled["placed"])
	for door in doors:
		for socket in door["sockets"]:
			var side: String = door["side"]
			var cell: Vector2i = door["origin"] + Iso.array_to_cell(socket["cell"]) + Mask.DIRS[side]
			var socket_id := "%s_%s" % [door["id"],socket["id"]]
			if not compiled["owner"].has(cell):
				layout["map_build_errors"] = ["unconnected door cell: %s/%s" % [door["id"],socket["id"]]]
				return layout
			var owner: String = compiled["owner"][cell]
			derived["map_road_%s" % owner]["sockets"].append({"id":socket_id,"cell":[cell.x,cell.y],"side":Mask.opposite_side(side)})
			connections.append({"from":"%s:%s" % [door["id"],socket["id"]], "to":"%s:%s" % [owner,socket_id]})
	# Each existing enemy entry (including the DAY12 service entrance) owns
	# a separate width-2 approach. Never collapse a secondary lane into A.
	for port in ports["ports"]:
		var module_id := "map_builder_%s" % port["id"]
		var outside := _road_module(port["cells"],module_id,"outside")
		outside["sockets"] = port["sockets"]
		derived[module_id] = outside
		placed.append({"instance_id":port["id"],"module_id":module_id,"grid_origin":[0,0],"locked":true,"legacy_room_id":port["id"]})
		connections.append_array(port["connections"])

	layout["placed_modules"] = placed
	layout["connections"] = connections
	var topology: Dictionary = layout.get("combat_topology",{}).duplicate(true)
	for lane in topology.get("lanes",{}).values():
		var start := str(lane.get("outside_room_id",lane.get("entry_room_id","entrance")))
		lane["route"] = preload("res://scripts/map_builder/RoadGraphCompiler.gd").room_path(connections,start,str(topology.get("goal_room_id","throne")))
		lane["target_width_cells"] = 2
		topology["route_source"] = "automatic_cell_adjacency"
	layout["combat_topology"] = topology
	layout["socket_states"] = {}
	layout["coordinate_mode"] = "screen_plot_v130"
	layout["plot_grid"] = {"size":[plot["size"].x,plot["size"].y], "grade_index":grade_index, "locked_anchors":["entrance","throne"]}
	layout["plot_mask"] = plot["cells"]
	layout["map_builder_modules"] = derived
	layout["auto_roads"] = result
	layout["wall_profile"] = "cutaway"
	layout["max_grid_size"] = [plot["size"].x*2+20,plot["size"].x*2+20]
	layout["active_rect"] = [0,0,layout["max_grid_size"][0],layout["max_grid_size"][1]]
	var decorations = preload("res://scripts/map_builder/PlotDecorationRules.gd")
	if int(source.get("plot_grid",{}).get("grade_index",grade_index))<grade_index:
		layout["decorations"] = decorations.rehome_after_growth(layout,modules)
	var decor_error: String = decorations.validate(layout,modules)
	if decor_error!="": layout["map_build_errors"] = [decor_error]
	layout.erase("unlocked_room_grid_ids")
	# Historical grid IDs remain UI identifiers until M3, never placement bounds.
	for grid_row in layout.get("room_grid",{}).get("cells",[]):
		for row in placed:
			if grid_row.get("instance_id", "") == row["instance_id"]:
				grid_row["master_cell"] = row["grid_origin"].duplicate()
	return layout

static func rotate_module(source: Dictionary) -> Dictionary:
	var module := source.duplicate(true)
	var size := Iso.array_to_cell(module.get("size",[5,5]))
	module["size"] = [size.y,size.x]
	for key in ["floor_cells","walk_cells","blocked_cells","trap_cells"]:
		for index in range(module.get(key,[]).size()):
			var cell := Iso.array_to_cell(module[key][index])
			module[key][index] = [size.y-1-cell.y,cell.x]
	for socket in module.get("sockets",[]):
		var cell := Iso.array_to_cell(socket["cell"])
		socket["cell"] = [size.y-1-cell.y,cell.x]
		socket["side"] = {"N":"E","E":"S","S":"W","W":"N"}[socket["side"]]
	for slot in module.get("object_slots",[]):
		var cell := Iso.array_to_cell(slot["cell"])
		slot["cell"] = [size.y-1-cell.y,cell.x]
		for key in ["footprint","block_cells"]:
			for index in range(slot.get(key,[]).size()):
				var offset := Iso.array_to_cell(slot[key][index])
				slot[key][index] = [-offset.y,offset.x]
	return module

static func _road_module(cells: Dictionary, id: String, function: String) -> Dictionary:
	var values: Array = []
	for cell: Vector2i in cells:
		values.append([cell.x,cell.y])
	return {"id":id,"display_name":"Automatic road", "theme":"cave_f","module_type":"corridor","room_function":function,"size":[100,100],"floor_cells":values,"walk_cells":values.duplicate(true),"blocked_cells":[],"sockets":[],"object_slots":[],"trap_cells":[]}

static func _find_site(plot: Dictionary, buildings: Array, size: Vector2i) -> Vector2i:
	var cells: Array = plot["cells"].keys()
	cells.sort_custom(func(a,b): return a.x+a.y < b.x+b.y if a.x+a.y != b.x+b.y else a.x < b.x)
	for cell: Vector2i in cells:
		var rect := Rect2i(cell,size)
		if not Plot.contains_rect(plot,rect.grow(2)): continue
		var valid := true
		for building in buildings:
			if rect.grow(2).intersects(building["rect"]): valid = false
		if valid: return cell
	return Vector2i(-1,-1)

static func is_plot(graph) -> bool:
	return graph != null and graph.get("layout") is Dictionary and graph.layout.has("plot_grid")

static func _socket_pair(module: Dictionary, preferred: String) -> Dictionary:
	for side in [preferred,"N","E","S","W"]:
		var sockets: Array = module.get("sockets",[])
		for index in range(sockets.size()):
			var a: Dictionary = sockets[index]
			if a.get("side","") != side: continue
			for b in sockets.slice(index+1):
				if b.get("side","") != side: continue
				var delta := Iso.array_to_cell(a.get("cell",[])) - Iso.array_to_cell(b.get("cell",[]))
				if (side in ["N","S"] and delta.y == 0 and absi(delta.x) == 1) or (side in ["E","W"] and delta.x == 0 and absi(delta.y) == 1):
					return {"side":side,"sockets":[a.duplicate(true),b.duplicate(true)]}
	return {}

static func _restore_road_semantics(derived: Dictionary, rows: Array, source_modules: Dictionary, aliases: Array) -> Array[String]:
	var errors: Array[String] = []
	for row in rows:
		var alias := str(row["instance_id"])
		if not aliases.has(alias): continue
		var original: Dictionary = source_modules.get(row["module_id"],{})
		var module: Dictionary = derived["map_road_%s" % alias]
		module["room_function"] = original.get("room_function","corridor")
		var trap_count: int = original.get("trap_cells",[]).size()
		if trap_count == 0: continue
		var floor: Array = module["floor_cells"]
		if floor.size() < trap_count:
			errors.append("road region too small to preserve trap cells: %s" % alias)
			continue
		var selected: Array = floor.slice(0,trap_count).duplicate(true)
		module["trap_cells"] = selected
		for original_slot in original.get("object_slots",[]):
			var slot: Dictionary = original_slot.duplicate(true)
			var anchor := Iso.array_to_cell(selected[0])
			slot["cell"] = [anchor.x,anchor.y]
			slot["footprint"] = []
			for value in selected:
				var offset := Iso.array_to_cell(value) - anchor
				slot["footprint"].append([offset.x,offset.y])
			module["object_slots"].append(slot)
	return errors

static func _outside_ports(source: Dictionary, placed: Array, modules: Dictionary, plot: Dictionary, buildings: Array) -> Dictionary:
	var specs: Dictionary = {"outside_approach":"entrance"}
	for lane in source.get("combat_topology",{}).get("lanes",{}).values():
		var id := str(lane.get("outside_room_id",""))
		if id != "": specs[id] = str(lane.get("entry_room_id","entrance"))
	var ports: Array = []
	var occupied: Dictionary = {}
	var errors: Array[String] = []
	for id in specs:
		var entry_id: String = specs[id]
		var entry: Dictionary = {}
		for row in placed:
			if row["instance_id"] == entry_id: entry = row
		if entry.is_empty():
			errors.append("outside approach entry missing: %s" % id)
			continue
		var origin := Iso.array_to_cell(entry["grid_origin"])
		var pair: Dictionary = _socket_pair(modules[entry["module_id"]],"W")
		if pair.is_empty() or pair["side"] != "W":
			errors.append("outside W width-2 door missing: %s" % id)
			continue
		var cells: Dictionary = {}
		var sockets: Array = []
		var connections: Array = []
		for socket in pair["sockets"]:
			var cell: Vector2i = origin + Iso.array_to_cell(socket["cell"]) + Vector2i.LEFT
			cells[cell] = true
			cells[cell+Vector2i.LEFT] = true
			var socket_id := str(socket["id"])
			sockets.append({"id":socket_id,"cell":[cell.x,cell.y],"side":"E"})
			connections.append({"from":"%s:%s" % [entry_id,socket_id],"to":"%s:%s" % [id,socket_id]})
		for cell in cells:
			if not plot["cells"].has(cell) or occupied.has(cell): errors.append("outside approach outside plot or overlapping: %s" % id)
			for building in buildings:
				if building["rect"].has_point(cell): errors.append("outside approach overlaps building: %s" % id)
			occupied[cell] = true
		ports.append({"id":id,"cells":cells,"sockets":sockets,"connections":connections})
	return {"ports":ports,"cells":occupied,"errors":errors}
