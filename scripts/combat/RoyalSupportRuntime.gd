extends RefCounted

const Crown=preload("res://scripts/systems/crown/CrownEvolutionService.gd")
var _combat_ref:WeakRef
var combat:
	get:return _combat_ref.get_ref() if _combat_ref!=null else null
var umbrellas:Dictionary={}
var contributions:Dictionary={}

func setup(controller)->void:_combat_ref=weakref(controller)
func floor_of(unit:Node)->String:return str(unit.get_meta("runtime_floor_id","1F"))
func mori_active(caster:Node)->bool:
	return is_instance_valid(caster) and not caster.is_queued_for_deletion() and caster.is_alive() and combat._active_crown_id(caster)=="crown_mori_grand_mycelial_priest"
func barrier_active(source_id:int)->bool:return mori_active(instance_from_id(source_id))
func available(caster:Node)->bool:
	return mori_active(caster) and int(caster.get_meta("royal_umbrella_uses",0))<int(DataRegistry.skill("royal_shared_umbrella").get("uses_per_battle",1))
func targets(caster:Node)->Array:
	return combat.root.monster_units.filter(func(unit):return is_instance_valid(unit) and not unit.is_queued_for_deletion() and unit.is_alive() and floor_of(unit)==floor_of(caster))
func guard_target(allies:Array)->Node:
	var best:Node=null;var ratio:=INF
	for unit in allies:
		var value:float=float(unit.hp)/maxf(1.0,float(unit.max_hp))
		if value<ratio:best=unit;ratio=value
	return best
func useful(caster:Node)->bool:
	if not available(caster):return false
	for ally in targets(caster):
		if ally.royal_cleansable_status_count()>0 or float(ally.hp)/maxf(1.0,float(ally.max_hp))<=.35:return true
	return false
func cast(caster:Node,allies:Array,guard:Node,skill:Dictionary)->void:
	caster.set_meta("royal_umbrella_uses",int(caster.get_meta("royal_umbrella_uses",0))+1)
	var actual:Array=allies.filter(func(unit):return is_instance_valid(unit) and not unit.is_queued_for_deletion() and unit.is_alive() and floor_of(unit)==floor_of(caster))
	var cleansed:=0
	for ally in actual:
		cleansed+=ally.cleanse_all_negative_status()
		combat.spawn_effect_burst("shield",ally.global_position,Vector2.ZERO,Vector2.ONE,11.0)
	umbrellas[caster.get_instance_id()]={"caster":caster,"allies":actual,"guard":guard,"guard_used":false,"remaining":float(skill.regeneration_seconds),"accumulator":0.0,"skill":skill,"floor":floor_of(caster)}
	caster.play_skill()
	combat.root._log("같은 우산: %d명 정화(%d상태), 5초 재생 · %s에게 치명 피해 1회 방지."%[actual.size(),cleansed,guard.display_name])

func tick(delta:float)->void:
	for id in umbrellas.keys():
		var entry:Dictionary=umbrellas[id];var caster=entry.caster
		if not mori_active(caster) or floor_of(caster)!=str(entry.floor):
			_finish(id,0.0);continue
		var active_delta:float=minf(maxf(delta,0.0),float(entry.remaining))
		entry.remaining=maxf(0.0,float(entry.remaining)-active_delta)
		entry.accumulator=float(entry.accumulator)+active_delta
		while float(entry.accumulator)>=1.0-.000001:
			entry.accumulator=maxf(0.0,float(entry.accumulator)-1.0)
			for ally in entry.allies:
				if is_instance_valid(ally) and not ally.is_queued_for_deletion() and ally.is_alive() and floor_of(ally)==str(entry.floor):
					heal_from(caster,ally,int(entry.skill.regeneration_heal_per_second),"umbrella:%d:%d"%[id,Time.get_ticks_usec()])
		umbrellas[id]=entry
		if float(entry.remaining)<=0.0:_finish(id,maxf(0.0,delta-active_delta))
	# Previously granted sacrament belongs to its actual source, not whichever
	# monster happens to be crowned after a mid-battle suppression/restore.
	for ally in combat.root.monster_units:
		if not is_instance_valid(ally) or ally.mori_barrier<=0:continue
		var source=instance_from_id(ally.mori_barrier_source_id)
		if not mori_active(source):ally.clear_mori_barrier()

func _finish(id:int,overrun:float)->void:
	var entry:Dictionary=umbrellas[id];umbrellas.erase(id)
	if is_instance_valid(entry.caster):
		entry.caster.mori_healing_penalty_timer=maxf(0.0,float(entry.skill.post_healing_duration)-overrun)
		entry.caster.mori_healing_penalty_multiplier=float(entry.skill.post_healing_multiplier)

func prevent_fatal(target:Node,incoming:int)->bool:
	if not is_instance_valid(target) or target.is_queued_for_deletion() or not target.is_alive():return false
	for id in umbrellas:
		var entry:Dictionary=umbrellas[id]
		if not bool(entry.guard_used) and entry.guard==target and mori_active(entry.caster) and floor_of(target)==str(entry.floor):
			entry.guard_used=true;umbrellas[id]=entry
			var prevented:int=maxi(0,incoming-maxi(0,int(target.hp)-1))
			_record(entry.caster,"fatal_raw_damage_cancelled",prevented)
			_record(entry.caster,"fatal_saves",1)
			_record(entry.caster,"fatal_hp_preserved",1)
			combat.root._log("우산 구조: %s 쓰러짐 1회 방지 · HP 1 유지(원피해 %d 무효)."%[target.display_name,prevented])
			combat.spawn_effect_burst("shield",target.global_position,Vector2.ZERO,Vector2.ONE,11.0)
			return true
	return false

func heal_from(caster:Node,target:Node,base_amount:int,token:String="",ignore_fatigue:bool=false)->int:
	if not is_instance_valid(caster) or caster.is_queued_for_deletion() or not caster.is_alive() or not is_instance_valid(target) or target.is_queued_for_deletion() or not target.is_alive():return 0
	var requested:int=combat._outgoing_heal_amount(caster,base_amount)
	var adjusted:int=target.resolved_heal_amount(requested,ignore_fatigue)
	var missing:int=maxi(0,int(target.max_hp)-int(target.hp))
	var effective:int=target.heal(requested,token,ignore_fatigue)
	_record(caster,"effective_healing",effective)
	if mori_active(caster):
		var result:Dictionary=Crown.mori_spore_sacrament(maxi(0,adjusted-missing),target.max_hp,true)
		if int(result.shield)>0:
			var seconds:float=float(DataRegistry.skill("royal_shared_umbrella").get("overheal_barrier_seconds",5.0))
			target.grant_mori_barrier(int(result.shield),seconds,caster.get_instance_id())
			_record(caster,"overheal_shield_offered",int(result.shield))
	return effective

func record_absorbed(source_id:int,amount:int)->void:
	var source=instance_from_id(source_id)
	if is_instance_valid(source):_record(source,"shield_absorbed",amount)
func _record(caster:Node,key:String,value:int)->void:
	if value<=0 or not is_instance_valid(caster):return
	var id:int=caster.get_instance_id();var counters:Dictionary=contributions.get(id,{})
	counters[key]=int(counters.get(key,0))+value;contributions[id]=counters
	# These are measured support values, separate from historical damage/XP.
	combat.root._record_monster_contribution(str(caster.unit_id),key,value)

func clear()->void:
	umbrellas.clear();contributions.clear()
	if combat==null or combat.root==null:return
	for unit in combat.root.monster_units:
		if is_instance_valid(unit):
			unit.clear_mori_barrier();unit.mori_healing_penalty_timer=0.0;unit.mori_healing_penalty_multiplier=1.0
