extends RefCounted
class_name MapBuildService

const Plot = preload("res://scripts/map_builder/PlotMask.gd")
const Roads = preload("res://scripts/map_builder/AutoRoadBuilder.gd")
const Mask = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const Iso = preload("res://scripts/dungeon_quarter/IsoMath.gd")
const SITES := {"entrance":Vector2i(15,34), "throne":Vector2i(29,16), "barracks":Vector2i(21,24), "recovery":Vector2i(36,25), "treasure":Vector2i(30,34), "slot_01":Vector2i(23,39)}
const DOOR_SIDES := {"entrance":"E", "throne":"S", "barracks":"E", "recovery":"W", "treasure":"N", "slot_01":"N"}

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
	var rows: Array = layout.get("placed_modules", []).duplicate(true)
	rows.sort_custom(func(a,b):
		var order := ["entrance","throne","barracks","recovery","treasure","slot_01"]
		var ai: int = order.find(a.get("instance_id",""))
		var bi: int = order.find(b.get("instance_id",""))
		return (ai if ai >= 0 else 99) < (bi if bi >= 0 else 99)
	)
	for row in rows:
		var id := str(row.get("instance_id", ""))
		var module: Dictionary = modules.get(row.get("module_id", ""), {})
		if str(module.get("module_type", "")) != "room":
			continue
		var size := Iso.array_to_cell(module.get("size", [5,5]))
		var origin: Vector2i = SITES.get(id, Vector2i.ZERO) + plot["center"] - Vector2i(30,30)
		if source.has("plot_grid"):
			origin = Iso.array_to_cell(row.get("grid_origin", []))
		elif not SITES.has(id):
			origin = _find_site(plot, buildings, size)
		if origin == Vector2i(-1,-1):
			layout["map_build_errors"] = ["no plot site for %s" % id]
			return layout
		row["grid_origin"] = [origin.x, origin.y]
		placed.append(row)
		buildings.append({"id":id, "rect":Rect2i(origin,size)})
		var side := str(DOOR_SIDES.get(id,"E"))
		var pair: Array = []
		var preferred_sides: Array = [side,"N","E","S","W"]
		for candidate in preferred_sides:
			var count := 0
			for socket in module.get("sockets", []):
				if socket.get("side", "") == candidate: count += 1
			if count >= 2:
				side = candidate
				break
		for socket in module.get("sockets", []):
			if str(socket.get("side", "")) == side:
				pair.append(socket)
		if pair.size() < 2:
			layout["map_build_errors"] = ["width-2 socket pair missing: %s" % id]
			return layout
		var first: Vector2i = origin + Iso.array_to_cell(pair[0].get("cell",[])) + Mask.DIRS[side]
		var second: Vector2i = origin + Iso.array_to_cell(pair[1].get("cell",[])) + Mask.DIRS[side]
		var anchor := Vector2i(mini(first.x,second.x),mini(first.y,second.y))
		if side == "N": anchor.y -= 1
		if side == "W": anchor.x -= 1
		doors.append({"id":id,"building_id":id,"anchor":anchor,"side":side,"sockets":pair,"origin":origin})
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
	var compiled := preload("res://scripts/map_builder/RoadGraphCompiler.gd").compile(result["road_cells"], aliases)
	var derived: Dictionary = compiled["modules"]
	var connections: Array = compiled["connections"]
	placed.append_array(compiled["placed"])
	for door in doors:
		for socket in door["sockets"]:
			var side: String = door["side"]
			var cell: Vector2i = door["origin"] + Iso.array_to_cell(socket["cell"]) + Mask.DIRS[side]
			var socket_id := "%s_%s" % [door["id"],socket["id"]]
			var owner: String = compiled["owner"][cell]
			derived["map_road_%s" % owner]["sockets"].append({"id":socket_id,"cell":[cell.x,cell.y],"side":Mask.opposite_side(side)})
			connections.append({"from":"%s:%s" % [door["id"],socket["id"]], "to":"%s:%s" % [owner,socket_id]})
	# Keep the combat entry sentinel, physically attached to the entrance's W door.
	var entry: Dictionary = doors[0]
	var outside_cells: Dictionary = {}
	var outside_sockets: Array = []
	var entrance_module: Dictionary = modules[placed[0]["module_id"]]
	for socket in entrance_module["sockets"]:
		if socket["side"] != "W": continue
		var cell: Vector2i = entry["origin"] + Iso.array_to_cell(socket["cell"]) + Vector2i.LEFT
		outside_cells[cell] = true
		outside_cells[cell + Vector2i.LEFT] = true
		var socket_id := str(socket["id"])
		outside_sockets.append({"id":socket_id,"cell":[cell.x,cell.y],"side":"E"})
		connections.append({"from":"entrance:%s" % socket_id,"to":"outside_approach:%s" % socket_id})
	var outside := _road_module(outside_cells, "map_builder_outside", "outside")
	outside["sockets"] = outside_sockets

	placed.append({"instance_id":"outside_approach","module_id":"map_builder_outside","grid_origin":[0,0],"locked":true,"legacy_room_id":"outside_approach"})
	layout["placed_modules"] = placed
	layout["connections"] = connections
	layout["socket_states"] = {}
	layout["coordinate_mode"] = "screen_plot_v130"
	layout["plot_grid"] = {"size":[plot["size"].x,plot["size"].y], "grade_index":grade_index, "locked_anchors":["entrance","throne"]}
	layout["plot_mask"] = plot["cells"]
	derived["map_builder_outside"] = outside
	layout["map_builder_modules"] = derived
	layout["auto_roads"] = result
	layout["wall_profile"] = "cutaway"
	layout["max_grid_size"] = [plot["size"].x*2+20,plot["size"].x*2+20]
	layout["active_rect"] = [0,0,layout["max_grid_size"][0],layout["max_grid_size"][1]]
	layout.erase("unlocked_room_grid_ids")
	# Historical grid IDs remain UI identifiers until M3, never placement bounds.
	for grid_row in layout.get("room_grid",{}).get("cells",[]):
		for row in placed:
			if grid_row.get("instance_id", "") == row["instance_id"]:
				grid_row["master_cell"] = row["grid_origin"].duplicate()
	return layout

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
