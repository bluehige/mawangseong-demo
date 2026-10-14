extends RefCounted

const Build = preload("res://scripts/map_builder/MapBuildService.gd")
const Plot = preload("res://scripts/map_builder/PlotMask.gd")
const SavePlot = preload("res://scripts/map_builder/PlotSaveState.gd")
const Iso = preload("res://scripts/dungeon_quarter/IsoMath.gd")
const Objective = preload("res://scripts/systems/council/CouncilObjectiveService.gd")
const IDS := ["crown_sanctum", "seal_vault"]

static func default_state() -> Dictionary:
	return {"schema":1, "unlocked":false, "objective_hp":{}, "crown_suppressed":false, "repair_cost_gold":0, "seal_theft_count":0, "disable_count_since_day16":0, "record_complete":true, "eligible":false, "temporary":true, "rooms":{}, "assignments":{}}

static func convert_active(value) -> Dictionary:
	var active: Dictionary = value.duplicate(true) if value is Dictionary else {}
	if active.get("expansion") is Dictionary and active.expansion.get("schema") == 1:
		active.erase("upper_floor")
		return active
	var state := default_state()
	var old = active.get("upper_floor", {})
	if old is Dictionary and bool(old.get("unlocked", false)):
		state.unlocked = true
		for key in ["objective_hp", "crown_suppressed", "repair_cost_gold", "seal_theft_count", "facility_role"]:
			if old.has(key): state[key] = old[key].duplicate(true) if old[key] is Dictionary else old[key]
		# An old floor record cannot prove a complete first-floor defense history.
		state.record_complete = false
	active["expansion"] = state
	active.erase("upper_floor")
	var metrics: Dictionary = active.get("run_metrics_update4", {}).duplicate(true)
	var ending: Dictionary = metrics.get("ending", {}).duplicate(true)
	for key in ["upper_floor_integrity", "day30_upper_floor_contribution_ratio", "day30_lower_survivor_count", "day30_upper_survivor_count", "day30_damage_by_floor"]: ending.erase(key)
	if metrics.has("ending"): metrics["ending"] = ending
	active["run_metrics_update4"] = metrics
	return active

static func unlock_if_due(value, day: int, modules: Dictionary, stage: int) -> Dictionary:
	var active := convert_active(value)
	if day < 16 or str(active.get("campaign_mode_id", "")) != "council_season": return active
	var state: Dictionary = active.expansion
	state.unlocked = true
	if not state.objective_hp.has("crown_sanctum"):
		state.objective_hp["crown_sanctum"] = Objective.crown_max_hp(modules, stage)
	return active

static func place_objectives(source: Dictionary, built: Dictionary, modules: Dictionary, history: Array, value: Dictionary) -> Dictionary:
	var state := value.duplicate(true)
	if built.has("map_build_errors"): return {"source":source,"layout":built,"state":state}
	var grade := int(built.plot_grid.grade_index)
	var plot_state := {"grade_index":grade,"unlock_history":history}
	var candidate := source.duplicate(true)
	candidate["plot_grid"] = built.plot_grid.duplicate(true)
	# Normalize authored coordinates before adding targets to a previously legacy map.
	for row in candidate.get("placed_modules", []):
		for placed in built.placed_modules:
			if row.instance_id == placed.instance_id and str(modules.get(row.module_id, {}).get("module_type", "")) == "room": row.grid_origin = placed.grid_origin.duplicate()
	var known := {}
	for row in candidate.placed_modules:
		if str(row.instance_id) in IDS: known[str(row.instance_id)] = row
	var needs_move := bool(state.get("temporary", true)) and int(state.get("placement_grade", -1)) != grade
	if known.size() == 2 and not needs_move:
		state = _placement_state(candidate, modules, plot_state, state)
		return {"source":candidate,"layout":built,"state":state}
	var original := candidate.duplicate(true)
	for row in candidate.placed_modules.duplicate():
		if str(row.instance_id) in IDS: candidate.placed_modules.erase(row)
	var buildings: Array = []
	for row in candidate.placed_modules:
		var module: Dictionary = modules.get(row.module_id, {})
		if module.get("module_type", "") == "room": buildings.append({"rect":Rect2i(Iso.array_to_cell(row.grid_origin),Iso.array_to_cell(module.get("size",[5,5])))})
	var plot := Plot.build(grade)
	var all_expansion := grade > 0
	for id in IDS:
		var size := Iso.array_to_cell(modules["room_"+id].size)
		var cell := _site(plot, buildings, size, plot_state, grade > 0)
		if cell == Vector2i(-1,-1):
			all_expansion = false
			cell = _site(plot, buildings, size, plot_state, false)
		if cell == Vector2i(-1,-1):
			# Saturated plots use an existing safe room as a temporary objective site.
			# No building is displaced, no free land or stat bonus is granted.
			state.rooms = {"crown_sanctum":"recovery", "seal_vault":"treasure"}
			state.eligible = false; state.temporary = true; state.placement_grade = grade
			return {"source":original,"layout":built,"state":state}
		candidate.placed_modules.append({"instance_id":id,"module_id":"room_"+id,"grid_origin":[cell.x,cell.y],"plot_rotation":0,"plot_door_side":"E" if cell.x < cell.y else "W","legacy_room_id":id})
		buildings.append({"rect":Rect2i(cell,size)})
	var layout := Build.prepare_layout(candidate, modules, grade)
	if layout.has("map_build_errors"):
		state.rooms = {"crown_sanctum":"recovery", "seal_vault":"treasure"}
		state.eligible = false; state.temporary = true; state.placement_grade = grade
		return {"source":original,"layout":built,"state":state}
	state.rooms = {"crown_sanctum":"crown_sanctum", "seal_vault":"seal_vault"}
	state.placement_grade = grade
	state = _placement_state(candidate, modules, plot_state, state)
	return {"source":candidate,"layout":layout,"state":state}

static func _site(plot: Dictionary, buildings: Array, size: Vector2i, plot_state: Dictionary, expansion_only: bool) -> Vector2i:
	var cells: Array = plot.cells.keys()
	cells.sort_custom(func(a,b): return a.x+a.y < b.x+b.y if a.x+a.y != b.x+b.y else a.x < b.x)
	for cell: Vector2i in cells:
		var rect := Rect2i(cell,size)
		if not Plot.contains_rect(plot,rect): continue
		# Edge objectives keep the width-two doorway on the inward side. Only the
		# usable footprint must be on unlocked land; no outside buffer grants land.
		var door := Rect2i(cell+Vector2i(size.x,0),Vector2i(2,2)) if cell.x < cell.y else Rect2i(cell+Vector2i(-2,1),Vector2i(2,2))
		if not Plot.contains_rect(plot,door): continue
		var valid := true
		for building in buildings:
			if rect.grow(2).intersects(building.rect): valid = false; break
		if not valid: continue
		if expansion_only and not _expanded_rect(rect, plot_state): continue
		return cell
	return Vector2i(-1,-1)

static func _expanded_rect(rect: Rect2i, state: Dictionary) -> bool:
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			if SavePlot.region_for_cell(state,Vector2i(x,y)) <= 0: return false
	return true

static func _placement_state(source: Dictionary, modules: Dictionary, plot: Dictionary, state: Dictionary) -> Dictionary:
	var eligible := int(plot.grade_index) > 0
	var count := 0
	for row in source.placed_modules:
		if str(row.instance_id) not in IDS: continue
		count += 1
		var size := Iso.array_to_cell(modules[row.module_id].size)
		if int(row.get("plot_rotation",0)) == 1: size = Vector2i(size.y,size.x)
		eligible = eligible and _expanded_rect(Rect2i(Iso.array_to_cell(row.grid_origin),size),plot)
	state.eligible = eligible and count == 2
	state.temporary = not state.eligible
	return state

static func survivors(state: Dictionary, units: Array) -> Dictionary:
	var result := {"original":0,"expansion":0}
	var assignments: Dictionary = state.get("assignments",{})
	for unit in units:
		if not is_instance_valid(unit) or not unit.is_alive(): continue
		var zone := str(assignments.get(str(unit.get_instance_id()), "original"))
		result[zone] = int(result[zone]) + 1
	if not bool(state.get("eligible",false)) or not bool(state.get("record_complete",false)): result.expansion = 0
	return result
