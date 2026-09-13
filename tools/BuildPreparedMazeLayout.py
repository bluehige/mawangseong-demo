"""Rebuild the hand-authored fixed maze. Not a random/runtime map generator."""
from pathlib import Path
import copy
import json
ROOT = Path(__file__).resolve().parents[1]
def read(p): return json.loads((ROOT/p).read_text(encoding="utf-8"))
def save(p,v): (ROOT/p).write_text(json.dumps(v,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
old=read("data/dungeon_quarter/layouts/stage01_dual_front_01.json")
bp=read("data/dungeon_quarter/dual_front_blueprints.json")
# The graph keeps every existing content room, effect link and capacity.
positions={"entrance":(0,1),"service_entrance":(0,2),"spike_corridor":(1,1),"maze_a_turn":(1,0),"lane_a_rear":(2,0),"throne_antechamber":(3,0),"throne":(3,-1),"lane_b_front":(1,2),"maze_b_turn":(2,2),"lane_b_rear":(2,1),"barracks":(0,0),"recovery":(2,-1),"slot_01":(1,3),"treasure":(3,2),"lane_b_merge":(3,1),"watch_post_01":(0,3),"heart_chamber":(-1,0),"ward_core_01":(4,0),"slot_02":(4,1),"elite_garrison_01":(0,-1),"slot_03":(1,-1)}
origins={k:[9+7*x,9+7*y] for k,(x,y) in positions.items()}
modules={p["instance_id"]:p["module_id"] for p in old["placed_modules"]}
for s in old["castle_stage_expansion_overrides"].values():
 for p in s["placed_modules"]: modules[p["instance_id"]]=p["module_id"]
modules.update({"maze_a_turn":"maze_corridor_ew_s_5x5","maze_b_turn":"maze_corridor_ew_n_5x5"})
new_bp={}
for id,sides in [("maze_corridor_ew_s_5x5","ESW"),("maze_corridor_ew_n_5x5","NEW")]:
 m=copy.deepcopy(bp["corridor_lane_a_narrow_5x5_01"])
 m.update(id=id,display_name="미궁 꺾임 회랑",tags=["prepared_maze","corridor","grid_5x5"])
 cells={(x,y) for x in [2,3] for y in [2,3]}
 for side in sides:
  if side in "NS": cells.update((x,y) for x in [2,3] for y in (range(0,3) if side=="N" else range(2,5)))
  else: cells.update((x,y) for y in [2,3] for x in (range(0,3) if side=="W" else range(2,5)))
 m["floor_cells"]=m["walk_cells"]=[list(c) for c in sorted(cells,key=lambda c:(c[1],c[0]))]
 new_bp[id]=m
# Trap footprint is unchanged; the north exit already belongs to the old module.
new_bp["maze_corridor_ew_s_5x5"]["floor_cells"] += [[2,0],[3,0],[2,1],[3,1]] # stage 4 north loop, closed socket until then
new_bp["maze_corridor_ew_s_5x5"]["walk_cells"]=copy.deepcopy(new_bp["maze_corridor_ew_s_5x5"]["floor_cells"])
nav={"entrance","service_entrance","spike_corridor","maze_a_turn","lane_a_rear","throne_antechamber","throne","lane_b_front","maze_b_turn","lane_b_rear","lane_b_merge","heart_chamber"}
oldcells={c["instance_id"]:c for c in old["room_grid"]["cells"] if c["instance_id"]}
for s in old["castle_stage_expansion_overrides"].values():
 oldcells.update({c["instance_id"]:c for c in s["room_grid_cells"]})
def package(): return {"placed_modules":[],"connections":[],"required_paths":[],"room_grid_cells":[],"facility_slots":[],"fixed_instance_ids":[],"replaceable_facility_instance_ids":[],"legacy_instance_ids_preserved":[]}
def room(pack,id):
 p={"instance_id":id,"module_id":modules[id],"grid_id":"MAZE_"+id.upper(),"grid_origin":origins[id],"locked":id in nav,"legacy_room_id":id}
 if id not in nav: p["replaceable_with"]=["room_barracks_01","room_recovery_01","room_treasure_01","room_empty_slot_01"]
 if id=="heart_chamber": p.update(update3_only=True,system_required=True)
 pack["placed_modules"].append(p)
 c=copy.deepcopy(oldcells.get(id,{"room_role":"corridor"}))
 c.update(grid_id=p["grid_id"],master_cell=origins[id],instance_id=id,anchor_cell=p["grid_id"],connected_sides=[],blocked_sides=["N","E","S","W"])
 pack["room_grid_cells"].append(c)
 pack["fixed_instance_ids" if id in nav else "replaceable_facility_instance_ids"].append(id)
 if id in modules and not id.startswith("maze_"): pack["legacy_instance_ids_preserved"].append(id)
 pack["required_paths"].append(dict({"from":"outside_approach","to":id,"purpose":"prepared_maze_reachable"},**({"update3_only":True} if id=="heart_chamber" else {})))
def connect(pack,a,b,id=None,heart=False):
 ax,ay=origins[a]; bx,by=origins[b]
 assert abs(ax-bx)+abs(ay-by)==7,(a,b)
 if bx<ax or by<ay: a,b=b,a; ax,ay,bx,by=bx,by,ax,ay
 horizontal=bx!=ax; sides=("e","w") if horizontal else ("s","n"); suffixes="ud" if horizontal else "lr"
 id=id or "maze_path_"+a+"_"+b
 pack["placed_modules"].append(dict({"instance_id":id,"module_id":"corridor_gap_"+("ew" if horizontal else "ns")+"_2x2_01","grid_id":id.upper(),"grid_origin":[ax+5,ay+2] if horizontal else [ax+2,ay+5],"locked":True,"legacy_room_id":id},**({"update3_only":True,"system_required":True} if heart else {})))
 pack["fixed_instance_ids"].append(id)
 for suffix in suffixes:
  for f,t in [(a+":to_"+sides[0]+"_"+suffix,id+":to_"+sides[1]+"_"+suffix),(id+":to_"+sides[0]+"_"+suffix,b+":to_"+sides[1]+"_"+suffix)]:
   pack["connections"].append(dict({"from":f,"to":t},**({"update3_only":True,"system_required":True} if heart else {})))
def outside(pack,id,entry):
 x,y=origins[entry]
 pack["placed_modules"].append({"instance_id":id,"module_id":"outside_approach_01","grid_id":id.upper(),"grid_origin":[x-2,y+2],"locked":True,"legacy_room_id":id})
 pack["fixed_instance_ids"].append(id)
 for suffix in "ud": pack["connections"].append({"from":id+":to_entrance_"+suffix,"to":entry+":to_w_"+suffix})
base=package()
for id in list(positions)[:14]: room(base,id)
outside(base,"outside_approach","entrance")
for a,b,id in [("entrance","spike_corridor","path_a_entry_front"),("spike_corridor","maze_a_turn","path_a_front_rear"),("maze_a_turn","lane_a_rear",None),("lane_a_rear","throne_antechamber","path_a_rear_merge"),("throne_antechamber","throne","path_merge_throne"),("barracks","maze_a_turn","path_facility_a_front"),("recovery","lane_a_rear","path_facility_a_rear"),("spike_corridor","lane_b_rear",None),("service_entrance","lane_b_front","path_b_entry_front"),("lane_b_front","maze_b_turn","path_b_front_rear"),("maze_b_turn","lane_b_rear",None),("maze_b_turn","treasure","path_facility_b_rear"),("lane_b_front","slot_01","path_facility_b_front")]: connect(base,a,b,id)
exp={s:package() for s in old["castle_stage_expansion_overrides"]}
s2=exp["stage_02_castle"]
for id in ["lane_b_merge","watch_post_01","heart_chamber"]: room(s2,id)
outside(s2,"outside_approach_b","service_entrance")
for a,b,id in [("lane_b_rear","lane_b_merge","path_b_rear_merge"),("lane_b_merge","throne_antechamber","path_b_merge_antechamber"),("lane_b_merge","treasure",None),("service_entrance","watch_post_01",None),("watch_post_01","slot_01",None)]: connect(s2,a,b,id)
connect(s2,"heart_chamber","barracks","heart_chamber_path",True)
s3=exp["stage_03_keep"]
for id in ["ward_core_01","slot_02"]: room(s3,id)
for a,b in [("throne_antechamber","ward_core_01"),("lane_b_merge","slot_02"),("ward_core_01","slot_02")]: connect(s3,a,b)
s4=exp["stage_04_citadel"]
for id in ["elite_garrison_01","slot_03"]: room(s4,id)
for a,b in [("elite_garrison_01","barracks"),("elite_garrison_01","slot_03"),("slot_03","maze_a_turn"),("slot_03","recovery")]: connect(s4,a,b)
for stage,p in exp.items(): p["facility_slots"]=copy.deepcopy(old["castle_stage_expansion_overrides"][stage]["facility_slots"])
# Populate visual room exits from exactly the same connection endpoints as navigation.
allconnections=base["connections"]+sum((s["connections"] for s in exp.values()),[])
for pack in [base,*exp.values()]:
 for cell in pack["room_grid_cells"]:
  sides=set()
  for c in allconnections:
   for endpoint in [c["from"],c["to"]]:
    if endpoint.startswith(cell["instance_id"]+":to_"): sides.add(endpoint.split(":to_")[1][0].upper())
  cell["connected_sides"]=sorted(sides);cell["blocked_sides"]=[s for s in "NESW" if s not in sides]
layout={k:copy.deepcopy(v) for k,v in old.items() if k not in ["placed_modules","connections","required_paths","castle_stage_expansion_overrides","room_grid","combat_topology"]}
layout.update(template_id="prepared_maze_growth_01",display_name="성장하는 왕좌 미궁",layout_label="고정 미궁 · 방과 갈림길",room_grid_contract_id="prepared_maze_growth_grid",max_grid_size=[42,40],active_rect=[0,0,42,40],prepared_maze=True,wave_catalog_alias="stage01_dual_front_candidate_01")
layout["room_grid"]={"contract_id":"prepared_maze_growth_grid","grid_size":[6,5],"cell_size":[5,5],"master_origin":[2,2],"gap_size":[2,2],"stride":[7,7],"room_lattice_master_size":[40,33],"active_master_size":[42,40],"cells":base["room_grid_cells"]}
for k in ["placed_modules","connections","required_paths"]: layout[k]=base[k]
top=copy.deepcopy(old["combat_topology"])
for key in ["fixed_instance_ids","replaceable_facility_instance_ids","legacy_instance_ids_preserved"]: top[key]=base[key]
for zone in top["defense_zones"]:
 if zone["zone_id"]=="zone_a_rear": zone["anchor_room_id"]="lane_a_rear"; zone["room_ids"]=["lane_a_rear"]
 if zone["zone_id"]=="zone_b_rear": zone["room_ids"]=["lane_b_rear"]
top["connector_contract"]["grid_origin"]=[origins["lane_a_rear"][0]+2,origins["lane_a_rear"][1]+5]
top["connector_contract"]["display_name"]="수비대 전용 샛문"
for id,lane in top["lanes"].items():
 lane.update(entry_room_id="entrance",outside_room_id="outside_approach",route=[],display_name="정문 진입" if id=="lane_a" else "정문 후속대")
# Both scheduled groups share the one physical stage-1 entrance. Stage 2 unlocks the side entrance.
s2["combat_topology"]={"lanes":copy.deepcopy(old["combat_topology"]["lanes"]),"defense_zones":copy.deepcopy(top["defense_zones"])}
for lane in s2["combat_topology"]["lanes"].values(): lane["route"]=[]
s2["combat_topology"]["lanes"]["lane_b"]["display_name"]="측문 진입"
for zone in s2["combat_topology"]["defense_zones"]:
 if zone["zone_id"]=="zone_b_rear": zone["room_ids"].append("lane_b_merge")
# Persist real authored module routes too: the existing placement adapter uses them
# to map entry/facility clicks onto defense zones when no explicit zone was saved.
def route_for(packages,start,goal):
 adjacency={}
 for package in packages:
  for edge in package["connections"]:
   a=edge["from"].split(":")[0]; b=edge["to"].split(":")[0]
   adjacency.setdefault(a,[]).append(b);adjacency.setdefault(b,[]).append(a)
 queue=[start]; paths={start:[start]}
 for current in queue:
  if current==goal:return paths[current]
  for target in adjacency.get(current,[]):
   if target not in paths: paths[target]=paths[current]+[target];queue.append(target)
 raise ValueError((start,goal))
for lane in top["lanes"].values():lane["route"]=route_for([base],lane["outside_room_id"],"throne")
for lane in s2["combat_topology"]["lanes"].values():lane["route"]=route_for([base,s2],lane["outside_room_id"],"throne")
layout["combat_topology"]=top
layout["castle_stage_expansion_overrides"]=exp
save("data/dungeon_quarter/prepared_maze_blueprints.json",new_bp)
save("data/dungeon_quarter/layouts/prepared_maze_growth_01.json",layout)
print("Prepared maze:",len(base["placed_modules"]),"base modules;",[len(v["placed_modules"]) for v in exp.values()],"stage additions")
