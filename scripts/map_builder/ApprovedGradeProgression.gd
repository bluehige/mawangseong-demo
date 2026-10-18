extends RefCounted
## Isolated preview progression. Never reads or writes a campaign save.
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const Plan = preload("res://scripts/map_builder/ApprovedMapLayout.gd")
const SAVE_PATH := "res://tmp/v130r_step5/copies/progression_test.json"
const SESSION := "approved_grade_progression"

static func save_path() -> String:
	if bool(ProjectSettings.get_setting("debug/start_flow14",false)): return "user://start_map_layout.json"
	if bool(ProjectSettings.get_setting("debug/approved_map_step10",false)): return "res://tmp/v130r_step10/copies/dc_test.json"
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
	if day<int(source.day): return {"ok":false,"errors":[LanguageSettings.text("map.cannot_move_to_an_earlier_day")]}
	var stage := stage_for_day(day,source.stage_rules)
	var grade := grade_for_stage(stage,source.stage_rules)
	var next := source.duplicate(true)
	var changes: Array = []
	if grade!=str(source.get("grade","E")):
		next = Buildings.initial(game,grade)
		next["specializations"] = source.get("specializations",{}).duplicate(true)
		next.resources = source.resources.duplicate(true); next.serial = source.serial
		# Preserve fixed facility identity, upgrades and capacity at the new sockets.
		for b in next.buildings.filter(func(row): return row.fixed):
			var old := Buildings.building(source,b.id)
			if old.is_empty(): return {"ok":false,"errors":[LanguageSettings.text("map.required_fixed_facility_missing_during_expansion")]}
			for key in old:
				if key not in ["rect","socket_front","preferred"]: b[key] = old[key]
			changes.append({"id":b.id,"rule":"fixed_plan_socket","from":str(old.rect),"to":str(b.rect)})
		next.buildings = next.buildings.filter(func(row): return row.fixed)
		next.traps = []; next.stage = stage; next.day = day
		var defaults: Array = Plan.read(grade).buildings
		for old in source.buildings:
			if old.fixed: continue
			var origins: Array[Vector2i] = []
			var source_default := {}
			if grade in ["D","C"]:
				for b in Plan.read(str(source.grade)).buildings:
					if b.id==str(old.get("plan_site_id",old.id)) and b.get("kind",b.id)==old.kind: source_default = b
					elif source_default.is_empty() and b.get("kind",b.id)==old.kind and old.rect==Rect2i(b.rect[0],b.rect[1],b.rect[2],b.rect[3]): source_default = b
			for b in defaults:
				if not source_default.is_empty() and b.id==source_default.id:
					origins.append(old.rect.position+Vector2i(b.rect[0]-source_default.rect[0],b.rect[1]-source_default.rect[1]))
			for b in defaults:
				if b.get("kind",b.id)==old.kind and Vector2i(b.rect[0],b.rect[1]) not in origins: origins.append(Vector2i(b.rect[0],b.rect[1]))
			for y in range(Buildings.dimensions(next).y-old.rect.size.y+1):
				for x in range(Buildings.dimensions(next).x-old.rect.size.x+1):
					var c := Vector2i(x,y)
					if c not in origins: origins.append(c)
			var placed := false
			for i in range(origins.size()):
				var candidate := next.duplicate(true)
				var row: Dictionary = old.duplicate(true); row.rect.position = origins[i]
				if grade in ["D","C"]:
					var bonus: int = int(Buildings.stage_rule(next).get("facility_capacity_bonus",0))
					# Older E purchase copies predate the optional bonus marker.
					var base: int = int(source.catalog[old.kind].capacity)+maxi(0,int(old.level)-1)
					var legacy_bonus: int = clampi(int(old.capacity)-base,0,int(Buildings.stage_rule(source).get("facility_capacity_bonus",0)))
					row.capacity += bonus-int(row.get("capacity_bonus",legacy_bonus)); row["capacity_bonus"] = bonus
				for b in defaults:
					if b.get("kind",b.id)==old.kind and origins[i]==Vector2i(b.rect[0],b.rect[1]):
						row.preferred = b.door
						if grade in ["D","C"]: row["plan_site_id"] = b.id
				candidate.buildings.append(row)
				candidate = Buildings.rebuild(candidate)
				if not candidate.ok: continue
				next = candidate; placed = true
				changes.append({"id":old.id,"rule":"same_kind_default" if i==0 else "vacant_y_then_x","from":str(old.rect),"to":str(row.rect)})
				break
			if not placed: return {"ok":false,"errors":[LanguageSettings.text("map.not_enough_room_after_expansion")+old.id]}
		next = Buildings.rebuild(next)
		if not next.ok: return next
		# Traps follow the nearest dry road, preserving each original kind/count.
		var used := {}
		var blocked := {}
		var from_line: RefCounted
		var to_line: RefCounted
		if grade in ["D","C"]:
			from_line = preload("res://scripts/map_builder/ApprovedBattleMap.gd").new(); from_line.setup(source)
			to_line = preload("res://scripts/map_builder/ApprovedBattleMap.gd").new(); to_line.setup(next)
			for hint in next.plan_defense.values():
				for c in hint.cells: blocked[c] = true
				for pair in hint.front: blocked[Vector2i(pair[0],pair[1])] = true
			for points in next.defense_points.values():
				for c in points: blocked[c] = true
			for d in next.doors.values():
				for c in d.front: blocked[c] = true
				for extra in d.get("secondary",[]):
					for c in extra.front: blocked[c] = true
		for trap in source.traps:
			var origin := Vector2i(trap.cell[0],trap.cell[1])
			var cells: Array = next.road_cells.keys()
			if grade in ["D","C"]:
				var zone: String = from_line.line_for(origin)
				cells = cells.filter(func(c): return to_line.line_for(c)==zone)
			cells.sort_custom(func(a,b):
				var da: int = Buildings.Defense.manhattan(a,origin); var db: int = Buildings.Defense.manhattan(b,origin)
				return da<db or (da==db and (a.y<b.y or (a.y==b.y and a.x<b.x))))
			var placed := false
			for c in cells:
				if next.water.has(c) or used.has(c) or blocked.has(c): continue
				used[c] = true
				var moved: Dictionary = trap.duplicate(true); moved.cell = [c.x,c.y]
				next.traps.append(moved); placed = true; break
			if not placed: return {"ok":false,"errors":[LanguageSettings.text("map.not_enough_room_for_traps_after_expansion")]}
	if source.has("food_state"): next.food_state = source.food_state.duplicate(true)
	next.stage = stage; next.day = day
	next = Buildings.rebuild(next)
	if not next.ok: return next
	var assigned := {}; var waiting: Array = []
	var upkeep := 0
	var roster := Members.roster()
	var food_limit: int = Members.income(stage) if grade in ["D","C"] else 2147483647
	for id in defenders:
		var target: Dictionary = defenders[id]
		var points: Array = next.defense_points.get(target.building,[])
		var slot := int(target.slot)
		if slot<0 or slot>=points.size() or Members.occupant(assigned,{"building":target.building,"slot":slot})!="":
			slot = -1
			for i in range(points.size()):
				if Members.occupant(assigned,{"building":target.building,"slot":i})=="": slot = i; break
		var cost: int = int(roster.get(id,{}).get("upkeep",0))
		if slot<0 or upkeep+cost>food_limit: waiting.append(id)
		else:
			assigned[id] = {"building":target.building,"slot":slot}; upkeep += cost
	return {"ok":true,"layout":next,"defenders":assigned,"waiting":waiting,"moves":changes}

static func stash(game: Node, layout: Dictionary, defenders: Dictionary) -> void:
	game.set_meta(SESSION,{"layout":Buildings.snapshot(layout),"defenders":defenders.duplicate(true)})

static func load_session(game: Node) -> Dictionary:
	var raw = game.get_meta(SESSION,{})
	var baseline := Buildings.initial(game,"F")
	if raw.is_empty() and OS.get_cmdline_user_args().has("--fresh-grade-f"): return {"layout":baseline,"defenders":{}}
	if raw.is_empty() and not bool(ProjectSettings.get_setting("debug/start_flow14",false)) and FileAccess.file_exists(save_path()): raw = JSON.parse_string(FileAccess.get_file_as_string(save_path()))
	if not raw is Dictionary or not raw.get("layout") is Dictionary: return {"layout":baseline,"defenders":{}}
	var grade := str(raw.layout.get("grade","F"))
	if grade not in ["F","E","D","C"]: return {"layout":baseline,"defenders":{}}
	var restored := Buildings.restore(raw.layout,Buildings.initial(game,grade))
	if not restored.get("ok",false): return {"layout":baseline,"defenders":{}}
	return {"layout":restored,"defenders":Members.sanitize(restored,raw.get("defenders",{}),Members.roster())}

static func reset_campaign_map(game: Node) -> void:
	if not enabled(): return
	var baseline := Buildings.initial(game,"F")
	var grade := grade_for_stage(stage_for_day(GameState.day,baseline.stage_rules),baseline.stage_rules)
	var layout := Buildings.initial(game,grade)
	layout.day = GameState.day
	layout.stage = stage_for_day(GameState.day,baseline.stage_rules)
	layout.resources = {"gold":GameState.gold,"mana":GameState.mana,"food":GameState.food}
	layout["food_state"] = GameState.food_state.duplicate(true)
	stash(game,layout,{})

static func sync_campaign_day(game: Node) -> void:
	if not enabled(): return
	if not game.has_meta(SESSION):
		reset_campaign_map(game)
		return
	var session := load_session(game)
	var result := advance(game,session.layout,session.defenders,GameState.day)
	if not result.ok:
		push_error(str(result.errors)); return
	result.layout.resources = {"gold":GameState.gold,"mana":GameState.mana,"food":GameState.food}
	result.layout["food_state"] = GameState.food_state.duplicate(true)
	# Roster choices made in the campaign screens remain authoritative.
	result.layout["specializations"] = {}
	for species in game.monster_roster:
		var choice := str(game.monster_roster[species].get("specialization_id",""))
		if choice!="": result.layout.specializations[species] = choice
	stash(game,result.layout,result.defenders)

static func continue_after_result(game: Node) -> void:
	game._advance_after_result()
