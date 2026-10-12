extends RefCounted

const Crown=preload("res://scripts/systems/crown/CrownEvolutionService.gd")
const FORM:="crown_toktok_royal_armorer"
var _combat_ref:WeakRef
var combat:
	get:return _combat_ref.get_ref() if _combat_ref!=null else null
var protections:Dictionary={}
var contributions:Dictionary={}

func setup(controller)->void:_combat_ref=weakref(controller)
func active(caster:Node)->bool:
	return is_instance_valid(caster) and not caster.is_queued_for_deletion() and caster.is_alive() and combat._active_crown_id(caster)==FORM
func available(caster:Node)->bool:
	return active(caster) and int(caster.get_meta("royal_plating_uses",0))<int(DataRegistry.skill("royal_emergency_plating").get("uses_per_battle",1))
func physical_room(unit:Node)->String:
	return str(combat.root.graph.room_at_world(unit.global_position)) if combat.root.graph!=null else str(unit.current_room)
func eligible(caster:Node,room_id:String)->bool:
	if not active(caster) or not combat.root.rooms.has(room_id):return false
	var room:Dictionary=combat.root.rooms[room_id]
	if str(room.get("facility_role","")) in ["","entry","trap","corridor","core","build_slot"] or bool(room.get("disabled",false)):return false
	var maximum:int=int(room.get("max_hp",room.get("hp",0)))
	if maximum<=0 or int(room.get("hp",maximum))>=maximum:return false
	if str(room.get("runtime_floor_id","1F"))!=combat.royal_support.floor_of(caster):return false
	if physical_room(caster)==room_id:return true
	var destination:Vector2=combat.root.graph.center(room_id)
	if caster.global_position.distance_to(destination)>float(DataRegistry.skill("patch_plates").get("range",120.0)):return false
	var route:Array=combat.root.graph.path_to_point(caster.global_position,destination)
	return combat.single_floor_support._route_safe(caster.global_position,route,destination)
func target(caster:Node)->String:
	if not available(caster):return ""
	var objectives:Array=[]
	for room_id in combat.root.rooms:
		if eligible(caster,str(room_id)):
			var room:Dictionary=combat.root.rooms[room_id]
			objectives.append({"id":str(room_id),"active":true,"hp":int(room.hp),"max_hp":int(room.get("max_hp",room.hp))})
	var effect:Dictionary=Crown.toktok_emergency_plating(objectives,true,DataRegistry.skill("royal_emergency_plating"))
	return str(effect.get("target_id","")) if bool(effect.get("ok",false)) else ""
func cast(caster:Node,room_id:String,skill:Dictionary)->void:
	var room:Dictionary=combat.root.rooms[room_id]
	var maximum:int=int(room.get("max_hp",room.hp))
	var cap:int=floori(float(maximum)*float(skill.max_repair_ratio))
	var token:="royal_plating:%d:%d"%[caster.get_instance_id(),Time.get_ticks_usec()]
	var repaired:Dictionary=combat.root._repair_update3_facility(room_id,cap,token,cap)
	caster.set_meta("royal_plating_uses",int(caster.get_meta("royal_plating_uses",0))+1)
	protections[room_id]={"source_id":caster.get_instance_id(),"expires_at":float(combat.root.combat_time)+float(skill.protection_seconds),"reduction":float(skill.protection_damage_reduction),"facility_role":str(room.get("facility_role","")),"floor_id":str(room.get("runtime_floor_id","1F"))}
	caster.crown_plating_move_timer=float(skill.post_move_duration)
	caster.crown_plating_move_multiplier=float(skill.post_move_multiplier)
	_record(caster,"facility_repair_actual",int(repaired.get("effective_repair",0)))
	combat.root.support_mastery.record_support(caster,"royal_repair",int(repaired.get("effective_repair",0)))
	caster.set_meta("plating_result",{"repair":int(repaired.get("effective_repair",0)),"room_id":room_id})
	caster.play_skill(combat.root.graph.center(room_id))
	combat.spawn_effect_burst("toktok_repair",combat.root.graph.center(room_id),Vector2.ZERO,Vector2.ONE,11.0)
	combat.root._log("왕성 긴급 판금: %s HP %d 수리 · 8초 피해감소30%%, 톡톡5초 이동-25%%."%[combat._room_name(room_id),int(repaired.get("effective_repair",0))])
func caption(caster:Node)->String:
	var result:Dictionary=caster.get_meta("plating_result",{})
	return combat.root.continuity.localized("수리 %d · 방호 8초", "Repaired %d · Guard 8s", "修复 %d · 防护8秒")%int(result.get("repair",0))
func damage_scale(room_id:String)->float:
	if not protections.has(room_id):return 1.0
	var guard:Dictionary=protections[room_id];var source=instance_from_id(int(guard.source_id))
	var room:Dictionary=combat.root.rooms.get(room_id,{})
	if not active(source) or float(combat.root.combat_time)>=float(guard.expires_at) or room.is_empty() or bool(room.get("disabled",false)) or str(room.get("facility_role",""))!=str(guard.facility_role) or str(room.get("runtime_floor_id","1F"))!=str(guard.floor_id):
		protections.erase(room_id);return 1.0
	return 1.0-clampf(float(guard.reduction),0.0,.8)
func record_prevention(room_id:String,actual_hp_prevented:int)->void:
	if actual_hp_prevented<=0 or not protections.has(room_id):return
	var source=instance_from_id(int(protections[room_id].source_id))
	if active(source):_record(source,"facility_hp_prevented",actual_hp_prevented)
func notify_damage(room_id:String,actual_hp_loss:int)->void:
	if actual_hp_loss<=0:return
	for unit in combat.root.monster_units:
		if active(unit) and physical_room(unit)==room_id:
			var effect:Dictionary=Crown.toktok_moving_forge(0,actual_hp_loss,true)
			unit.crown_forge_bonus=int(effect.bonus);unit.crown_forge_room=room_id
func forge_bonus(unit:Node)->int:
	if not active(unit) or unit.crown_forge_room!=physical_room(unit):
		unit.crown_forge_bonus=0;unit.crown_forge_room="";return 0
	return int(unit.crown_forge_bonus)
func tick()->void:
	for room_id in protections.keys():damage_scale(str(room_id))
	for unit in combat.root.monster_units:
		if is_instance_valid(unit) and unit.crown_forge_bonus>0:forge_bonus(unit)
func _record(caster:Node,key:String,amount:int)->void:
	if amount<=0:return
	var id:int=caster.get_instance_id();var counter:Dictionary=contributions.get(id,{})
	counter[key]=int(counter.get(key,0))+amount;contributions[id]=counter
	combat.root._record_monster_contribution(str(caster.unit_id),key,amount)
func clear()->void:
	protections.clear();contributions.clear()
	if combat==null or combat.root==null:return
	for unit in combat.root.monster_units:
		if is_instance_valid(unit):
			unit.crown_forge_bonus=0;unit.crown_forge_room="";unit.crown_plating_move_timer=0.0;unit.crown_plating_move_multiplier=1.0
