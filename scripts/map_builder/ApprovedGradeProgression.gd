extends RefCounted
## Isolated preview progression. Never reads or writes a campaign save.
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const Plan = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const SAVE_PATH := "res://tmp/v130r_step5/copies/progression_test.json"
const SESSION := "approved_grade_progression"

static func save_path() -> String:
	if bool(ProjectSettings.get_setting("debug/approved_map_step7",false)): return "res://tmp/v130r_step7/copies/monsters_test.json"
	return "res://tmp/v130r_step6/copies/food_test.json" if bool(ProjectSettings.get_setting("debug/approved_map_step6",false)) else SAVE_PATH

static func enabled() -> bool:
	return bool(ProjectSettings.get_setting("debug/approved_map_step5",false))

static func stage_for_day(day: int, rules: Dictionary) -> int:
	var stage := 1
	for rule in rules.values():
		if day>=int(rule.map_start_day): stage = maxi(stage,int(rule.index))
	return stage

static func grade_for_stage(stage: int, rules: Dictionary) -> String:
	for rule in rules.values():
		if int(rule.index)==stage: return str(rule.map_grade)
	return "F"

static func advance(game: Node, source: Dictionary, defenders: Dictionary, day: int) -> Dictionary:
	if day<int(source.day): return {"ok":false,"errors":["날짜 역행 금지"]}
	var stage := stage_for_day(day,source.stage_rules)
	var grade := grade_for_stage(stage,source.stage_rules)
	var next := source.duplicate(true)
	var changes: Array = []
	if grade!=str(source.get("grade","E")):
		next = Buildings.initial(game,grade)
		next.resources = source.resources.duplicate(true); next.serial = source.serial
		# Preserve fixed facility identity, upgrades and capacity at the new sockets.
		for b in next.buildings.filter(func(row): return row.fixed):
			var old := Buildings.building(source,b.id)
			for key in ["level","capacity","paid"]: b[key] = old[key]
			changes.append({"id":b.id,"rule":"fixed_plan_socket","from":str(old.rect),"to":str(b.rect)})
		next.buildings = next.buildings.filter(func(row): return row.fixed)
		next.traps = []; next.stage = stage; next.day = day
		var defaults: Array = Plan.read(grade).buildings
		for old in source.buildings:
			if old.fixed: continue
			var origins: Array[Vector2i] = []
			for b in defaults:
				if b.id==old.kind: origins.append(Vector2i(b.rect[0],b.rect[1]))
			for y in range(Buildings.dimensions(next).y-old.rect.size.y+1):
				for x in range(Buildings.dimensions(next).x-old.rect.size.x+1):
					var c := Vector2i(x,y)
					if c not in origins: origins.append(c)
			var placed := false
			for i in range(origins.size()):
				var candidate := next.duplicate(true)
				var row: Dictionary = old.duplicate(true); row.rect.position = origins[i]
				for b in defaults:
					if b.id==old.kind and origins[i]==Vector2i(b.rect[0],b.rect[1]): row.preferred = b.door
				candidate.buildings.append(row)
				candidate = Buildings.rebuild(candidate)
				if not candidate.ok: continue
				next = candidate; placed = true
				changes.append({"id":old.id,"rule":"same_kind_default" if i==0 else "vacant_y_then_x","from":str(old.rect),"to":str(row.rect)})
				break
			if not placed: return {"ok":false,"errors":["등급 이전 공간 부족: "+old.id]}
		next = Buildings.rebuild(next)
		if not next.ok: return next
		# Traps follow the nearest dry road, preserving each original kind/count.
		var used := {}
		for trap in source.traps:
			var origin := Vector2i(trap.cell[0],trap.cell[1])
			var cells: Array = next.road_cells.keys()
			cells.sort_custom(func(a,b):
				var da: int = Buildings.Defense.manhattan(a,origin); var db: int = Buildings.Defense.manhattan(b,origin)
				return da<db or (da==db and (a.y<b.y or (a.y==b.y and a.x<b.x))))
			for c in cells:
				if next.water.has(c) or used.has(c): continue
				used[c] = true; next.traps.append({"kind":trap.kind,"cell":[c.x,c.y]}); break
	if source.has("food_state"): next.food_state = source.food_state.duplicate(true)
	next.stage = stage; next.day = day
	next = Buildings.rebuild(next)
	if not next.ok: return next
	var assigned := {}; var waiting: Array = []
	for id in defenders:
		var target: Dictionary = defenders[id]
		var points: Array = next.defense_points.get(target.building,[])
		var slot := int(target.slot)
		if slot<0 or slot>=points.size() or Members.occupant(assigned,{"building":target.building,"slot":slot})!="":
			slot = -1
			for i in range(points.size()):
				if Members.occupant(assigned,{"building":target.building,"slot":i})=="": slot = i; break
		if slot<0: waiting.append(id)
		else: assigned[id] = {"building":target.building,"slot":slot}
	return {"ok":true,"layout":next,"defenders":assigned,"waiting":waiting,"moves":changes}

static func stash(game: Node, layout: Dictionary, defenders: Dictionary) -> void:
	game.set_meta(SESSION,{"layout":Buildings.snapshot(layout),"defenders":defenders.duplicate(true)})

static func load_session(game: Node) -> Dictionary:
	var raw = game.get_meta(SESSION,{})
	var baseline := Buildings.initial(game,"F")
	if raw.is_empty() and OS.get_cmdline_user_args().has("--fresh-grade-f"): return {"layout":baseline,"defenders":{}}
	if raw.is_empty() and FileAccess.file_exists(save_path()): raw = JSON.parse_string(FileAccess.get_file_as_string(save_path()))
	if not raw is Dictionary or not raw.get("layout") is Dictionary: return {"layout":baseline,"defenders":{}}
	var grade := str(raw.layout.get("grade","F"))
	if grade not in ["F","E"]: return {"layout":baseline,"defenders":{}}
	var restored := Buildings.restore(raw.layout,Buildings.initial(game,grade))
	if not restored.get("ok",false): return {"layout":baseline,"defenders":{}}
	return {"layout":restored,"defenders":Members.sanitize(restored,raw.get("defenders",{}),Members.roster())}

static func continue_after_result(game: Node) -> void:
	var session := load_session(game)
	# Battle rewards are already settled by the existing result service.
	session.layout.resources = {"gold":GameState.gold,"mana":GameState.mana,"food":GameState.food}
	if bool(ProjectSettings.get_setting("debug/approved_map_step6",false)): session.layout.food_state = GameState.food_state.duplicate(true)
	var result := advance(game,session.layout,session.defenders,int(session.layout.day)+1)
	if not result.ok:
		push_error(str(result.errors)); return
	stash(game,result.layout,result.defenders)
	Members.save_copy(result.layout,result.defenders,save_path())
	GameState.day = int(result.layout.day)
	game._set_screen("management",false)
