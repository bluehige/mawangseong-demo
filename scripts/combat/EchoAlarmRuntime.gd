extends RefCounted
const Popo=preload("res://scripts/systems/monsters/PopoCombatService.gd")
var _combat_ref:WeakRef
var combat:
	get:return _combat_ref.get_ref() if _combat_ref!=null else null
var warnings:Dictionary={}
var credits:Dictionary={}
var contributions:Dictionary={}
func setup(controller)->void:_combat_ref=weakref(controller)
func alive(unit)->bool:return is_instance_valid(unit) and not unit.is_queued_for_deletion() and unit.is_alive()
func clock()->float:return float(combat.root.combat_time)
func eligible(enemy)->bool:
	if not alive(enemy) or combat.crown_mobility.room_of(enemy)=="":return false
	if str(enemy.unit_id)=="thief":return combat.native_objectives.gold_active(enemy)
	var tags:Array=DataRegistry.enemy(str(enemy.unit_id)).get("role_tags",[])
	for tag in DataRegistry.skill("echo_alarm").get("revealed_role_tags",[]):
		if tags.has(tag):return true
	return false
func candidates()->Array:
	var result:Array=[]
	for enemy in combat.root.enemy_units:
		if eligible(enemy):result.append(enemy)
	return result
func delay_cap(enemy)->float:
	return float(DataRegistry.skill("echo_alarm").get("boss_interaction_delay",.7)) if DataRegistry.enemy(str(enemy.unit_id)).get("role_tags",[]).has("boss") else float(DataRegistry.skill("echo_alarm").get("normal_interaction_delay",2))
func credit_key(enemy,generation:int)->String:return "%d:%d"%[enemy.get_instance_id(),generation]
func possible_delay(enemy)->float:
	var generation:int=combat.native_objectives.channel_generation(enemy)
	if generation<0:return 0.0
	var record:Dictionary=credits.get(credit_key(enemy,generation),{})
	return maxf(0.0,delay_cap(enemy)-float(record.get("allocated",0.0)))
func useful()->bool:
	for enemy in candidates():
		if combat.native_objectives.concealed(enemy) and not combat.native_objectives.targetable(enemy):return true
		if possible_delay(enemy)>.0001:return true
	return false
func prepare(unit,automatic:bool=false)->Dictionary:
	if not alive(unit) or str(unit.unit_id)!="bat_courier":return {}
	var targets:Array=candidates()
	var channel_ids:Dictionary={}
	for enemy in targets:channel_ids[enemy.get_instance_id()]=combat.native_objectives.channel_generation(enemy)
	return {"targets":targets,"channel_ids":channel_ids,"automatic":automatic,"generations":combat.native_objectives.generation} if not targets.is_empty() else {}
func valid(unit,plan:Dictionary)->bool:
	if not alive(unit) or str(unit.unit_id)!="bat_courier" or int(plan.get("generations",-1))!=combat.native_objectives.generation:return false
	var targets:Array=plan.get("targets",[]).filter(func(enemy):return eligible(enemy))
	if targets.is_empty():return false
	if not bool(plan.get("automatic",false)):return true
	for enemy in targets:
		if combat.native_objectives.concealed(enemy) and not combat.native_objectives.targetable(enemy):return true
		var channel:int=combat.native_objectives.channel_generation(enemy)
		if channel>=0 and channel==int(plan.get("channel_ids",{}).get(enemy.get_instance_id(),-1)) and possible_delay(enemy)>.0001:return true
	return false
func cast(unit,plan:Dictionary)->void:
	var revealed_count:=0;var granted:=0.0;var count:=0
	for enemy in plan.targets:
		if not eligible(enemy):continue
		count+=1
		var hidden:bool=combat.native_objectives.concealed(enemy) and not revealed(enemy) and not combat.native_objectives.watch_revealed(enemy)
		var id:int=enemy.get_instance_id();var entry:Dictionary=warnings.get(id,{"unit":enemy,"sources":{}})
		entry.sources[unit.get_instance_id()]=clock()+float(DataRegistry.skill("echo_alarm").get("duration",8));warnings[id]=entry
		if hidden:revealed_count+=1
		var channel:int=combat.native_objectives.channel_generation(enemy)
		if channel>=0 and channel==int(plan.get("channel_ids",{}).get(enemy.get_instance_id(),-1)):
			var key:String=credit_key(enemy,channel);var record:Dictionary=credits.get(key,{"unit":enemy,"generation":channel,"allocated":0.0,"consumed":0.0,"remaining":0.0,"source":unit,"species":str(unit.unit_id)})
			var added:float=maxf(0.0,delay_cap(enemy)-float(record.allocated))
			if added>0:record.allocated=float(record.allocated)+added;record.remaining=float(record.remaining)+added;granted+=added
			credits[key]=record
		combat.native_objectives.refresh_concealment(enemy)
		combat.spawn_effect_burst("fx_popo_relay",enemy.global_position,Vector2.ZERO,Vector2.ONE,11)
	unit.play_skill();unit.set_meta("echo_result",{"warnings":count,"revealed":revealed_count,"allocated_seconds":granted})
	_record(unit,"echo_casts",1);_record(unit,"echo_hidden_reveals",revealed_count)
	combat.root._log("메아리 경보8초 · 실제 잠행 해제%d · 현재 목표 지연 예약%.1f초."%[revealed_count,granted])
func revealed(enemy)->bool:
	if not alive(enemy):return false
	var entry:Dictionary=warnings.get(enemy.get_instance_id(),{})
	for ends in entry.get("sources",{}).values():
		if clock()<float(ends):return true
	return false
func consume_delay(enemy,delta:float,channel:int)->float:
	var key:String=credit_key(enemy,channel)
	if not credits.has(key):return delta
	var entry:Dictionary=credits[key];var used:float=minf(maxf(0,delta),maxf(0,float(entry.remaining)))
	entry.remaining=maxf(0,float(entry.remaining)-used);entry.consumed=float(entry.consumed)+used
	if used>0:
		var source=entry.source
		if is_instance_valid(source):
			combat.root.support_mastery.record_support(source,"echo_delay",used)
			var id:int=source.get_instance_id();var counter:Dictionary=contributions.get(id,{})
			var before:float=float(counter.get("echo_actual_delay_seconds",0));var after:float=before+used
			counter.echo_actual_delay_seconds=after;contributions[id]=counter
			# The existing campaign contribution API is integer-valued. Keep exact
			# seconds here and transfer accumulated milliseconds, never nominal debt.
			var ms:int=roundi(after*1000)-roundi(before*1000)
			if ms>0:combat.root._record_monster_contribution(str(entry.species),"echo_actual_delay_milliseconds",ms)
			var whole:int=floori(after+.00001)-floori(before+.00001)
			if whole>0:combat.root._record_monster_contribution(str(entry.species),"facility_value",whole)
	return maxf(0,delta-used)
func discard_channel(enemy,channel:int)->void:
	if is_instance_valid(enemy):credits.erase(credit_key(enemy,channel))
func tick()->void:
	for id in warnings.keys():
		var entry:Dictionary=warnings[id]
		if not alive(entry.unit):warnings.erase(id);continue
		for source in entry.sources.keys():
			if clock()>=float(entry.sources[source]):entry.sources.erase(source)
		if entry.sources.is_empty():warnings.erase(id)
	for key in credits.keys():
		var entry:Dictionary=credits[key]
		if not alive(entry.unit) or not combat.native_objectives.channel_exists(entry.unit,int(entry.generation)):credits.erase(key)
func caption(unit)->String:
	var result:Dictionary=unit.get_meta("echo_result",{})
	return combat.root.continuity.localized("경보8초 · 숨김해제%d · 지연예약%.1f초","Alarm8s · Revealed%d · Delay allocated%.1fs","警报8秒 · 显形%d · 延迟预约%.1f秒")%[int(result.get("revealed",0)),float(result.get("allocated_seconds",0))]
func status(enemy)->String:
	if not revealed(enemy):return ""
	var remaining:=0.0
	for ends in warnings[enemy.get_instance_id()].sources.values():remaining=maxf(remaining,float(ends)-clock())
	return combat.root.continuity.localized("메아리 경보","Echo warning","回声警报")+" %.1fs"%remaining
func _record(unit,key:String,amount:int)->void:
	if amount<=0:return
	var counter:Dictionary=contributions.get(unit.get_instance_id(),{});counter[key]=int(counter.get(key,0))+amount;contributions[unit.get_instance_id()]=counter
	combat.root._record_monster_contribution(str(unit.unit_id),key,amount)
func clear()->void:warnings.clear();credits.clear();contributions.clear()
