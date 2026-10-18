extends RefCounted
## Individual branch-preview defenders. Only an isolated test copy is written.
const Buildings = preload("res://scripts/map_builder/ApprovedPlacement.gd")
const SAVE_PATH := "res://tmp/v130r_step3/copies/placement_test.json"
static var COSTS = preload("res://scripts/systems/MonsterFoodService.gd").COSTS
const SUPPORT := ["spore_healer","ghost_housemaid","spider_tailor","curse_doll","crumpled_map"]
const RANGED := ["imp","moon_tracker","bat_courier","candle_wisp","river_frog"]
const TANKS := ["slime","stone_sentinel","armored_beetle","bridge_troll","hollow_armor","glue_snail"]

static func roster() -> Dictionary:
	var instances: Dictionary = DataRegistry.monster_instances.duplicate(true)
	var species: Dictionary = DataRegistry.monsters
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
	# A small final guard prevents every recommended defender fighting at the gate.
	if species=="imp": return ["throne","watchtower","ward_core","barracks"]
	if species=="crumpled_map": return ["throne","ward_core","recovery_nest","barracks"]
	if species in TANKS: return ["barracks","entrance","ward_core","throne","vault"]
	if species in RANGED: return ["watchtower","throne","ward_core","barracks"]
	if species in SUPPORT: return ["recovery_nest","ward_core","throne","barracks"]
	if species=="rat_union": return ["vault","bait_treasure","barracks"]
	if species=="hollow_armor": return ["throne","ward_core","barracks"]
	if species=="mole_digger": return ["ward_core","barracks","throne"]
	if species=="mimic_porter": return ["bait_treasure","vault","barracks"]
	return ["barracks","vault","bait_treasure","throne"]

static func auto_place(layout: Dictionary, members: Dictionary, unlocked: Array, limit: int) -> Dictionary:
	var next := {}; var spent := 0
	# The first campaign has no guaranteed stone sentinel. Reserve two guards
	# from the companions actually present, before the two ranged/support slots.
	var core_guards: Array = []
	if layout.get("grade","") in ["D","C"]:
		var guard_order := ["slime","stone_sentinel","bridge_troll","hollow_armor","glue_snail","armored_beetle"]
		# C also needs its trained entrance tank at the first crossing.
		if layout.get("grade","")=="C": guard_order = ["bridge_troll","glue_snail","hollow_armor","stone_sentinel","armored_beetle","slime"]
		for species in guard_order:
			for id in unlocked:
				if members.has(id) and members[id].species_id==species:
					core_guards.append(species); break
			if core_guards.size()==2: break
	# Cover tank/ranged/healer/decoy roles before filling remaining roster order.
	var roster_order: Array = members.keys()
	var order := roster_order.duplicate()
	var first := ["slime","imp","spore_healer","mimic_porter"]
	if layout.get("grade","") in ["D","C"]: first = core_guards+["imp","crumpled_map","spore_healer","mimic_porter"]
	order.sort_custom(func(a,b):
		var pa: int = first.find(members[a].species_id); var pb: int = first.find(members[b].species_id)
		if pa<0: pa = first.size()
		if pb<0: pb = first.size()
		return pa<pb or (pa==pb and roster_order.find(a)<roster_order.find(b)))
	for id in order:
		var row: Dictionary = members[id]
		if id not in unlocked or spent+row.upkeep>limit: continue
		var placed := false
		var preferred := preferences(row.species_id)
		# Guard the larger final apron with two durable defenders, retaining the
		# imp/map support pair. C divides that quartet between independent doors.
		if row.species_id in core_guards: preferred = ["throne","barracks","ward_core","recovery_nest","vault"]
		for kind in preferred:
			for b in layout.buildings:
				if b.kind!=kind: continue
				var slots: Array = range(layout.defense_points[b.id].size())
				# Front line tanks face the entrance, ranged defenders use rear slots.
				slots.sort_custom(func(a,b_index):
					if layout.get("grade","")=="C" and b.kind=="throne":
						var a_port: int = int(a)/2; var b_port: int = int(b_index)/2
						var counts := [0,0]
						for target in next.values():
							if target.building==b.id: counts[int(target.slot)/2] += 1
						if counts[a_port]!=counts[b_port]: return counts[a_port]<counts[b_port]
						if a_port!=b_port: return a_port<b_port
						return a%2>b_index%2 if row.species_id in RANGED or row.species_id in SUPPORT else a%2<b_index%2
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

static func save_copy(layout: Dictionary, assignments: Dictionary, path: String = SAVE_PATH) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"schema":"v130r_step3_1","layout":Buildings.snapshot(layout),"defenders":assignments},"\t")); file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))

static func load_copy(baseline: Dictionary, members: Dictionary, path: String = SAVE_PATH) -> Dictionary:
	var result := {"layout":baseline,"defenders":{}}
	if not FileAccess.file_exists(path): return result
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("schema","")!="v130r_step3_1": return result
	var layout := Buildings.restore(data.get("layout",{}),baseline)
	if not layout.get("ok",false): return result
	return {"layout":layout,"defenders":sanitize(layout,data.get("defenders",{}),members)}
