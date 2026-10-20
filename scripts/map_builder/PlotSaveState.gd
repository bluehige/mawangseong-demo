extends RefCounted

const Build = preload("res://scripts/map_builder/MapBuildService.gd")
const Plot = preload("res://scripts/map_builder/PlotMask.gd")
const STAGES := ["stage_01_cave", "stage_02_castle", "stage_03_keep", "stage_04_citadel"]

static func grade(world: Dictionary) -> int:
	return maxi(0, STAGES.find(str(world.get("castle_art_stage", STAGES[0]))))

static func history(index: int, day: int, reason: String) -> Array:
	var result: Array = []
	for i in range(index + 1):
		result.append({"grade_index":i, "stage_id":STAGES[i], "size":[30 + 6*i,20], "day":day, "reason":reason})
	return result

static func capture(source: Dictionary, index: int, unlocks: Array) -> Dictionary:
	return {"size":[30 + 6*index,20], "grade_index":index, "unlock_history":unlocks.duplicate(true), "layout_source":source.duplicate(true)}

static func source_for_world(world: Dictionary, update3: Dictionary = {}) -> Dictionary:
	var source: Dictionary = world.get("quarter_layout", {}).duplicate(true)
	if source.is_empty(): source = DataRegistry.quarter_layout(str(world.get("quarter_layout_id",DataRegistry.quarter_default_layout_id)))
	if DataRegistry.LEGACY_QUARTER_DEFAULT_LAYOUT_IDS.has(str(world.get("quarter_layout_id",""))):
		source = DataRegistry.quarter_layout("stage01_dual_front_candidate_01")
	var index := grade(world)
	var include_heart := preload("res://scripts/systems/hearts/HeartChamberService.gd").should_spawn(update3, index + 1)
	for i in range(index + 1):
		var addition: Dictionary = DataRegistry.castle_stage_expansion_for_layout(STAGES[i],source)
		for key in ["placed_modules","connections","required_paths"]:
			var rows: Array = source.get(key,[]).duplicate(true)
			for row in addition.get(key,[]):
				if bool(row.get("update3_only",false)) and not include_heart: continue
				var found := false
				for existing in rows:
					if (key == "placed_modules" and existing.instance_id == row.instance_id) or (key != "placed_modules" and existing.get("from","") == row.get("from","") and existing.get("to","") == row.get("to","")): found = true
				if not found: rows.append(row.duplicate(true))
			source[key] = rows
		if addition.has("combat_topology"): source["combat_topology"] = addition.combat_topology.duplicate(true)
	return source

static func migrate(world: Dictionary, day: int, update3: Dictionary = {}) -> Dictionary:
	var index := grade(world)
	var source := source_for_world(world,update3)
	var built := Build.prepare_layout(source,DataRegistry.quarter_modules,index) if source_modules_valid(source) else {"map_build_errors":["invalid source modules"]}
	var fallback := built.has("map_build_errors")
	if fallback:
		# Keep the caller's original world intact; discard only invalid coordinates.
		source.erase("plot_grid")
		for row in source.get("placed_modules",[]): row.erase("plot_rotation")
		built = Build.prepare_layout(source,DataRegistry.quarter_modules,index) if source_modules_valid(source) else {"map_build_errors":["invalid source modules"]}
	if built.has("map_build_errors"):
		var safe_world := world.duplicate(true)
		safe_world["quarter_layout"] = DataRegistry.quarter_layout(DataRegistry.quarter_default_layout_id)
		safe_world["quarter_layout_id"] = DataRegistry.quarter_default_layout_id
		source = source_for_world(safe_world,update3)
		built = Build.prepare_layout(source,DataRegistry.quarter_modules,index)
	if built.has("map_build_errors"): return {"ok":false,"error":str(built.map_build_errors)}
	for row in source.placed_modules:
		for placed in built.placed_modules:
			if row.instance_id == placed.instance_id and DataRegistry.quarter_modules.get(row.module_id,{}).get("module_type","") == "room": row["grid_origin"] = placed.grid_origin.duplicate()
	source["plot_grid"] = built.plot_grid.duplicate(true)
	return {"ok":true,"fallback":fallback,"state":capture(source,index,history(index,day,"migration"))}

static func source_modules_valid(source: Dictionary) -> bool:
	var rows = source.get("placed_modules")
	if not rows is Array: return false
	var ids := {}
	for row in rows:
		if not row is Dictionary or not row.get("instance_id") is String or ids.has(row.instance_id) or not DataRegistry.quarter_modules.has(row.get("module_id")): return false
		ids[row.instance_id] = true
	return ids.has("entrance") and ids.has("throne")

static func validate(state: Dictionary) -> String:
	var index = state.get("grade_index")
	if not (index is int or index is float) or int(index) != index or index < 0 or index >= STAGES.size(): return "Invalid plot grade"
	if not size_matches(state.get("size"),int(index)): return "Invalid plot size"
	var unlocks = state.get("unlock_history")
	if not unlocks is Array or unlocks.size() != int(index)+1: return "Invalid plot unlock history"
	for i in range(unlocks.size()):
		var entry = unlocks[i]
		if not entry is Dictionary or entry.get("grade_index") != i or entry.get("stage_id") != STAGES[i] or not size_matches(entry.get("size"),i) or not (entry.get("day") is int or entry.get("day") is float) or int(entry.day) != entry.day or entry.day < 0 or not entry.get("reason") in ["migration","new_game","grade_up"]: return "Invalid plot unlock entry"
	var source = state.get("layout_source")
	if not source is Dictionary or not source.get("plot_grid") is Dictionary or source.plot_grid.get("grade_index") != index or source.plot_grid.get("size") != state.size: return "Invalid plot source"
	var ids := {}
	for row in source.get("placed_modules",[]):
		if not row is Dictionary or ids.has(row.get("instance_id")) or not DataRegistry.quarter_modules.has(row.get("module_id")): return "Invalid plot module"
		ids[row.instance_id] = true
		var cell = row.get("grid_origin")
		if not cell is Array or cell.size()!=2: return "Invalid plot coordinate"
		for v in cell:
			if not (v is int or v is float) or int(v)!=v: return "Invalid plot coordinate"
		var rotation = row.get("plot_rotation",0)
		if not (rotation is int or rotation is float) or (rotation != 0 and rotation != 1): return "Invalid plot rotation"
	if not ids.has("entrance") or not ids.has("throne"): return "Missing plot anchors"
	var built := Build.prepare_layout(source,DataRegistry.quarter_modules,int(index))
	return str(built.map_build_errors) if built.has("map_build_errors") else ""

static func size_matches(value, index: int) -> bool:
	if not value is Array or value.size() != 2: return false
	for v in value:
		if not (v is int or v is float): return false
	return value[0] == 30+6*index and value[1] == 20

static func region_for_cell(state: Dictionary, cell: Vector2i) -> int:
	# Coordinates translate by (+6,+6) on each upgrade, preserving world positions.
	var current := int(state.get("grade_index",0))
	for entry in state.get("unlock_history",[]):
		var i := int(entry.grade_index)
		if Plot.build(i).cells.has(cell - Vector2i(6,6)*(current-i)): return i
	return -1
