extends RefCounted
## Individual branch-preview defenders. Only an isolated test copy is written.
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const SAVE_PATH := "res://tmp/v130r_step3/copies/placement_test.json"
const COSTS := {"slime":1,"goblin":1,"imp":1,"kobold_scout":1,"spore_healer":2,"war_drummer":2,"ghost_housemaid":2,"bat_courier":2,"spider_tailor":2,"stone_sentinel":3,"mimic_porter":3,"moon_tracker":3,"graveyard_hound":3,"armored_beetle":3}
const SUPPORT := ["spore_healer","ghost_housemaid","spider_tailor"]
const RANGED := ["imp","moon_tracker","bat_courier"]
const TANKS := ["slime","stone_sentinel","armored_beetle"]

static func roster() -> Dictionary:
	var instances: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/monster_instances.json"))
	instances.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/regular_version/update4/monster_instances.json")))
	var species: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/monsters.json"))
	species.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/regular_version/update3/monsters.json")))
	species.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/regular_version/update4/monsters.json")))
	for id in instances:
		var row: Dictionary = instances[id]
		row["stats"] = species[row.species_id].duplicate(true)
		row["upkeep"] = COSTS[row.species_id]
	return instances

static func available(row: Dictionary, day: int, unlock_all: bool, joined: Array) -> bool:
	return unlock_all or row.instance_id in joined or row.species_id in ["slime","goblin","imp","kobold_scout"]

static func income(stage: int) -> int:
	# This preview's approved map is E, regardless of legacy castle stage=3.
	return [15,23,30,34][clampi(stage-1,0,3)]

static func cell(layout: Dictionary, target: Dictionary) -> Vector2i:
	var points: Array = layout.defense_points.get(target.get("building",""),[])
	var index := int(target.get("slot",-1))
	return points[index] if index>=0 and index<points.size() else Vector2i(-999,-999)

static func occupant(assignments: Dictionary, target: Dictionary) -> String:
	for id in assignments:
		if assignments[id]==target: return id
	return ""

static func put(layout: Dictionary, assignments: Dictionary, id: String, target: Dictionary, members: Dictionary, unlocked: Array) -> Dictionary:
	var next := assignments.duplicate(true)
	if not members.has(id) or id not in unlocked: return {"ok":false,"assignments":next}
	if target.is_empty(): next.erase(id); return {"ok":true,"assignments":next}
	if cell(layout,target)==Vector2i(-999,-999): return {"ok":false,"assignments":next}
	var other := occupant(next,target)
	var old: Dictionary = next.get(id,{})
	if other!="" and other!=id:
		if old.is_empty(): next.erase(other)
		else: next[other] = old.duplicate()
	next[id] = target.duplicate()
	return {"ok":true,"assignments":next}

static func upkeep(assignments: Dictionary, members: Dictionary) -> int:
	var total := 0
	for id in assignments:
		if members.has(id): total += int(members[id].upkeep)
	return total

static func preferences(species: String) -> Array:
	if species in TANKS: return ["barracks","entrance","ward_core","throne","vault"]
	if species in RANGED: return ["watchtower","throne","ward_core","barracks"]
	if species in SUPPORT: return ["recovery_nest","ward_core","throne","barracks"]
	if species=="mimic_porter": return ["bait_treasure","vault","barracks"]
	return ["barracks","vault","bait_treasure","throne"]

static func auto_place(layout: Dictionary, members: Dictionary, unlocked: Array, limit: int) -> Dictionary:
	var next := {}; var spent := 0
	# Cover tank/ranged/healer/decoy roles before filling remaining roster order.
	var roster_order: Array = members.keys()
	var order := roster_order.duplicate()
	var first := ["slime","imp","spore_healer","mimic_porter"]
	order.sort_custom(func(a,b):
		var pa: int = first.find(members[a].species_id); var pb: int = first.find(members[b].species_id)
		if pa<0: pa = first.size()
		if pb<0: pb = first.size()
		return pa<pb or (pa==pb and roster_order.find(a)<roster_order.find(b)))
	for id in order:
		var row: Dictionary = members[id]
		if id not in unlocked or spent+row.upkeep>limit: continue
		var placed := false
		for kind in preferences(row.species_id):
			for b in layout.buildings:
				if b.kind!=kind: continue
				var slots: Array = range(layout.defense_points[b.id].size())
				# Front line tanks face the entrance, ranged defenders use rear slots.
				slots.sort_custom(func(a,b_index):
					var pa: Vector2i = layout.defense_points[b.id][a]; var pb: Vector2i = layout.defense_points[b.id][b_index]
					return pa.x>pb.x if row.species_id in RANGED else pa.x<pb.x)
				for slot in slots:
					var target := {"building":b.id,"slot":slot}
					if occupant(next,target)!="": continue
					next[id] = target; spent += int(row.upkeep); placed = true; break
				if placed: break
			if placed: break
	return next

static func sanitize(layout: Dictionary, assignments: Dictionary, members: Dictionary) -> Dictionary:
	var clean := {}; var used := {}
	for id in assignments:
		if not members.has(id) or not assignments[id] is Dictionary: continue
		var point := cell(layout,assignments[id])
		if point==Vector2i(-999,-999) or used.has(point): continue
		used[point] = true; clean[id] = {"building":str(assignments[id].building),"slot":int(assignments[id].slot)}
	return clean

static func save_copy(layout: Dictionary, assignments: Dictionary) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_PATH.get_base_dir()))
	var file := FileAccess.open(SAVE_PATH+".tmp",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"schema":"v130r_step3_1","layout":Buildings.snapshot(layout),"defenders":assignments},"\t")); file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH+".tmp"),ProjectSettings.globalize_path(SAVE_PATH))

static func load_copy(baseline: Dictionary, members: Dictionary) -> Dictionary:
	var result := {"layout":baseline,"defenders":{}}
	if not FileAccess.file_exists(SAVE_PATH): return result
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or data.get("schema","")!="v130r_step3_1": return result
	var layout := Buildings.restore(data.get("layout",{}),baseline)
	if not layout.get("ok",false): return result
	return {"layout":layout,"defenders":sanitize(layout,data.get("defenders",{}),members)}
