extends RefCounted
const Iso = preload("res://scripts/dungeon_quarter/IsoMath.gd")
static var catalog: Dictionary = {}
static func data() -> Dictionary:
	if catalog.is_empty(): catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_builder/decorations.json"))
	return catalog
static func item(id: String) -> Dictionary:
	for row in data().items:
		if row.id == id: return row
	return {}
static func name_for(id: String) -> String:
	var names: Array = item(id).get("names",["?","?","?"])
	return names[LanguageSettings.SUPPORTED_LOCALES.find(LanguageSettings.locale)]
static func occupied(layout: Dictionary, modules: Dictionary) -> Dictionary:
	var result: Dictionary = layout.get("auto_roads",{}).get("road_cells",{}).duplicate()
	for row in layout.get("placed_modules",[]):
		var module: Dictionary = layout.get("map_builder_modules",{}).get(row.module_id,modules.get(row.module_id,{}))
		var origin := Iso.array_to_cell(row.grid_origin)
		for v in module.get("floor_cells",[]): result[origin+Iso.array_to_cell(v)] = true
	return result
static func validate(layout: Dictionary, modules: Dictionary) -> String:
	var rows = layout.get("decorations",[])
	if not rows is Array or rows.size()>256: return "Invalid decorations"
	var used := {}
	var blocked := occupied(layout,modules)
	for row in rows:
		if not row is Dictionary or not row.get("id") is String or item(row.id).is_empty(): return "Invalid decoration type"
		var cell = row.get("cell")
		if not cell is Array or cell.size()!=2: return "Invalid decoration cell"
		for v in cell:
			if not (v is int or v is float) or int(v)!=v: return "Invalid decoration cell"
		var coord := Iso.array_to_cell(cell)
		if not layout.get("plot_mask",{}).has(coord) or blocked.has(coord) or used.has(coord): return "Decoration overlaps road, room or plot boundary"
		used[coord] = true
	return ""
static func score(source: Dictionary) -> int:
	var total := 0
	for row in source.get("decorations",[]): total += int(item(str(row.get("id",""))).get("intimidation",0))
	return total

static func rehome_after_growth(layout: Dictionary, modules: Dictionary) -> Array:
	# Mandatory growth rooms/roads retain their exact generated positions. Move
	# only cosmetic objects they cover, so decorations cannot prevent evolution.
	var rows: Array = layout.get("decorations",[]).duplicate(true)
	var used := occupied(layout,modules)
	var displaced: Array[int] = []
	for i in range(rows.size()):
		var cell := Iso.array_to_cell(rows[i].cell)
		if used.has(cell) or not layout.plot_mask.has(cell): displaced.append(i)
		else: used[cell] = true
	for i in displaced:
		var row: Dictionary = rows[i]
		var old := Iso.array_to_cell(row.cell)
		var cell := Vector2i(-1,-1)
		var distance := INF
		for candidate: Vector2i in layout.plot_mask:
			if used.has(candidate): continue
			var next_distance := Vector2(candidate-old).length_squared()
			if next_distance<distance:
				distance = next_distance; cell = candidate
		row.cell = [cell.x,cell.y]
		used[cell] = true
	return rows
static func evaluation(source: Dictionary, stage_index: int) -> Dictionary:
	# Cosmetic appraisal only. Never writes graph.castle_grade, active_rect or stage gates.
	var grades := ["F","E","D","C","B","A","S"]
	var base := clampi(stage_index,0,3)*20
	var points := mini(score(source),int(data().score_cap))
	var index := clampi(int((base+points)/int(data().points_per_grade)),0,grades.size()-1)
	return {"grade":grades[index],"score":base+points,"base":base,"decoration":points,"intimidation":score(source)}
