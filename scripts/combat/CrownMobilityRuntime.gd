extends RefCounted
const Constants=preload("res://scripts/core/Constants.gd")
const Crown=preload("res://scripts/systems/crown/CrownEvolutionService.gd")
const PUDDING:="crown_pudding_royal_bastion"
const POPO:="crown_popo_grand_night_courier"
var _combat_ref:WeakRef
var combat:
	get:return _combat_ref.get_ref() if _combat_ref!=null else null
var anchors:Dictionary={}
var transits:Dictionary={}
var buffs:Dictionary={}
var contributions:Dictionary={}
func setup(controller)->void:_combat_ref=weakref(controller)
func active(unit:Node,form:String)->bool:
	return is_instance_valid(unit) and not unit.is_queued_for_deletion() and unit.is_alive() and combat._active_crown_id(unit)==form
func room_of(unit:Node)->String:return str(combat.root.graph.room_at_world(unit.global_position))
func source_evolution(unit:Node,freeze_missing:bool=false)->String:
	var season:Dictionary=combat.root.update4_active_run.get("council_season",{})
	if season.has("crown_source_evolution_id"):return str(season.crown_source_evolution_id)
	var source:String=str(combat.root.monster_roster.get(str(unit.unit_id),{}).get("promotion_id",""))
	if freeze_missing:
		season["crown_source_evolution_id"]=source;combat.root.update4_active_run["council_season"]=season
	return source
func safe_route(start:Vector2,destination:Vector2)->Array:
	if not combat.root.graph.is_walkable(destination):return []
	var route:Array=[destination] if start.distance_to(destination)<.1 else combat.root.graph.path_to_point(start,destination)
	if not route.is_empty() and route[-1].distance_to(destination)>.1:route.append(destination)
	return route if combat.single_floor_support._route_safe(start,route,destination) else []
func prepare_jelly(unit:Node,allies:Array)->Dictionary:
	var source:String=source_evolution(unit,true);var room_id:String=room_of(unit)
	var result:Dictionary={"source":source,"room":room_id,"kind":"","target_id":0,"caster_position":unit.global_position}
	if source=="slime_gate_bulwark":
		result.kind="anchor";result.point=combat.root.graph.center(room_id)
	elif source=="slime_rescue_alchemy_gel":
		result.kind="rescue";var lowest:=2.0
		for ally in allies:
			if ally==unit or not is_instance_valid(ally) or not ally.is_alive() or ally.is_queued_for_deletion():continue
			var ratio:float=float(ally.hp)/maxf(1.0,float(ally.max_hp))
			if ratio<lowest:lowest=ratio;result.target_id=ally.get_instance_id()
		var facing:Vector2=unit.action_direction.normalized()
		if facing==Vector2.ZERO:facing=Vector2.RIGHT
		var offset:float=float(DataRegistry.update3_duo_links.get("link_ghostly_evacuate",{}).get("effect",{}).get("safe_offset",44.0))
		result.point=unit.global_position-facing*offset
	return result
func jelly_valid(unit:Node,plan:Dictionary)->bool:
	return active(unit,PUDDING) and str(plan.get("source",""))==source_evolution(unit) and str(plan.get("room",""))==room_of(unit) and (str(plan.get("kind",""))!="rescue" or unit.global_position.distance_to(plan.get("caster_position",unit.global_position))<.1)
func apply_jelly(unit:Node,plan:Dictionary,seconds:float)->void:
	var result:Dictionary={"kind":str(plan.get("kind","")),"moved":false,"anchored":false}
	if str(plan.get("kind",""))=="anchor":
		var point:Vector2=plan.point;var route:Array=safe_route(unit.global_position,point)
		if not route.is_empty():
			anchors[unit.get_instance_id()]={"unit":unit,"room":room_of(unit),"point":point,"ends":float(combat.root.combat_time)+seconds,"arrived":false,"last_position":unit.global_position,"stall":0.0}
			unit.crown_anchor_pending=true;unit.set_path(route);maintain_anchor(unit)
			result.anchored=unit.crown_anchor_fixed
	elif str(plan.get("kind",""))=="rescue":
		var target=instance_from_id(int(plan.get("target_id",0)));var point:Vector2=plan.point
		if is_instance_valid(target) and not target.is_queued_for_deletion() and target.is_alive() and target!=unit and room_of(target)==room_of(unit) and target.seal_move_lock_timer<=0 and target.duo_move_lock_timer<=0 and not bool(target.get_meta("fixed",false)) and room_of_point(point)==room_of(unit) and not safe_route(target.global_position,point).is_empty() and point_safe(point):
			var moved:float=target.global_position.distance_to(point)
			target.global_position=point;target.stop_navigation();target.current_room=room_of(target);target.refresh_depth_slot()
			result.moved=moved>.1
			if result.moved:_record(unit,"royal_jelly_rescues",1);_record(unit,"royal_jelly_rescue_distance",moved)
	unit.set_meta("jelly_inheritance_result",result)
func room_of_point(point:Vector2)->String:return str(combat.root.graph.room_at_world(point))
func point_safe(point:Vector2)->bool:
	for enemy in combat.root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and enemy.global_position.distance_to(point)<24.0:return false
	return true
func _anchor_valid(unit:Node)->bool:
	if not is_instance_valid(unit) or not anchors.has(unit.get_instance_id()):return false
	var value:Dictionary=anchors[unit.get_instance_id()]
	if not active(unit,PUDDING) or float(combat.root.combat_time)>=float(value.ends) or room_of(unit)!=str(value.room):
		cancel_anchor(unit);return false
	return true
func maintain_anchor(unit:Node)->bool:
	if not _anchor_valid(unit):return false
	var value:Dictionary=anchors[unit.get_instance_id()]
	if unit.global_position.distance_to(value.point)<=unit.PATH_POINT_REACHED_RADIUS:
		if not bool(value.arrived):
			value.arrived=true;unit.stop_navigation();unit.crown_anchor_fixed=true
			unit.set_meta("jelly_inheritance_result",{"kind":"anchor","moved":false,"anchored":true})
			_record(unit,"royal_jelly_anchor_arrivals",1);combat.spawn_effect_burst("shield",unit.global_position,Vector2.ZERO,Vector2.ONE,11)
			combat.root._log("왕관 성문 계승 · 실제 중앙 도착, 남은 방호 동안 추가 방어 +3.")
	else:
		value.arrived=false;unit.crown_anchor_fixed=false
		var route:Array=safe_route(unit.global_position,value.point)
		if route.is_empty():cancel_anchor(unit);return false
		if unit.path_points.is_empty():unit.set_path(route)
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET,"왕관 중앙 접근")
	return true
func anchor_bonus(unit:Node)->int:
	return 3 if _anchor_valid(unit) and bool(anchors[unit.get_instance_id()].arrived) and unit.global_position.distance_to(anchors[unit.get_instance_id()].point)<=unit.PATH_POINT_REACHED_RADIUS else 0
func anchored(unit:Node)->bool:return anchor_bonus(unit)>0
func cancel_anchor(unit:Node,clear_navigation:bool=true)->void:
	if not is_instance_valid(unit):return
	anchors.erase(unit.get_instance_id());unit.crown_anchor_pending=false;unit.crown_anchor_fixed=false
	if clear_navigation:unit.stop_navigation()
func courier_available(unit:Node)->bool:
	return active(unit,POPO) and not transits.has(unit.get_instance_id()) and int(unit.get_meta("royal_courier_uses",0))<int(DataRegistry.skill("royal_urgent_courier").get("uses_per_battle",2))
func courier_target(unit:Node)->Node:
	if not courier_available(unit):return null
	var best:Node=null;var best_ratio:=INF;var best_danger:=-1;var best_distance:=INF
	for ally in combat.root.monster_units:
		if not courier_eligible(unit,ally):continue
		var danger:=0
		for enemy in combat.root.enemy_units:
			if is_instance_valid(enemy) and enemy.is_alive() and room_of(enemy)==room_of(ally):danger+=1
		var route:Array=safe_route(unit.global_position,ally.global_position);var distance:float=route_length(unit.global_position,route)
		var ratio:float=float(ally.hp)/maxf(1.0,float(ally.max_hp))
		if ratio<best_ratio or (is_equal_approx(ratio,best_ratio) and (danger>best_danger or (danger==best_danger and distance<best_distance))):
			best=ally;best_ratio=ratio;best_danger=danger;best_distance=distance
	return best
func courier_eligible(unit:Node,target:Node)->bool:
	if not active(unit,POPO) or not is_instance_valid(target) or target==unit or target.is_queued_for_deletion() or not target.is_alive() or room_of(unit)==room_of(target) or room_of(target)=="" or safe_route(unit.global_position,target.global_position).is_empty():return false
	for enemy in combat.root.enemy_units:
		if is_instance_valid(enemy) and enemy.is_alive() and room_of(enemy)==room_of(target):return true
	return false
func begin_courier(unit:Node,target:Node,skill:Dictionary)->void:
	unit.stop_navigation();unit.set_meta("royal_courier_uses",int(unit.get_meta("royal_courier_uses",0))+1)
	transits[unit.get_instance_id()]={"unit":unit,"target":target,"origin_room":room_of(unit),"target_room":room_of(target),"elapsed":0.0,"skill":skill.duplicate(true)}
	unit.play_skill(target.global_position);unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET,"왕관 긴급 이동",target.display_name)
func route_length(start:Vector2,route:Array)->float:
	var distance:=0.0;var previous:=start
	for point in route:distance+=previous.distance_to(point);previous=point
	return distance
func route_point(start:Vector2,route:Array,distance:float)->Vector2:
	var previous:=start
	for point in route:
		var length:float=previous.distance_to(point)
		if distance<=length:return previous.lerp(point,clampf(distance/maxf(.001,length),0,1))
		distance-=length;previous=point
	return previous
func cancel_courier(unit:Node,clear_navigation:bool=true)->void:
	if not is_instance_valid(unit):return
	if transits.erase(unit.get_instance_id()):
		if clear_navigation:unit.stop_navigation()
		combat.root._log("왕관 긴급 이동 취소 · 이미 확정한 사용 횟수는 유지됩니다.")
func tick(delta:float)->void:
	for id in anchors.keys():
		var unit=anchors[id].unit
		if not is_instance_valid(unit):anchors.erase(id);continue
		if not maintain_anchor(unit):continue
		var value:Dictionary=anchors[id]
		if not bool(value.arrived) and unit.seal_move_lock_timer<=0 and unit.duo_move_lock_timer<=0:
			value.stall=float(value.stall)+delta if unit.global_position.distance_to(value.last_position)<=unit.NAVIGATION_PROGRESS_EPSILON else 0.0
			value.last_position=unit.global_position
			if float(value.stall)>=unit.NAVIGATION_STALL_TIMEOUT:cancel_anchor(unit)
	for id in transits.keys():
		var value:Dictionary=transits[id];var unit=value.unit;var target=value.target
		if not is_instance_valid(unit):transits.erase(id);continue
		if not active(unit,POPO) or unit.seal_move_lock_timer>0 or unit.duo_move_lock_timer>0 or not is_instance_valid(target) or target.is_queued_for_deletion() or not target.is_alive() or room_of(target)!=str(value.target_room):cancel_courier(unit);continue
		var route:Array=safe_route(unit.global_position,target.global_position)
		if route.is_empty():cancel_courier(unit);continue
		var remaining:float=maxf(.001,float(value.skill.transition_seconds)-float(value.elapsed))
		unit.global_position=route_point(unit.global_position,route,route_length(unit.global_position,route)*minf(1,delta/remaining))
		var previous_room:String=str(unit.current_room)
		unit.current_room=room_of(unit);room_transition(unit,previous_room,str(unit.current_room));unit.refresh_depth_slot();value.elapsed=float(value.elapsed)+delta
		if float(value.elapsed)>=float(value.skill.transition_seconds):
			var effect:Dictionary=Crown.popo_urgent_courier(str(value.origin_room),{"id":str(target.get_instance_id()),"room_id":room_of(target),"position":target.global_position},true,value.skill)
			if bool(effect.get("ok",false)):_courier_arrive(unit,target,effect)
			transits.erase(id)
	for key in buffs.keys():
		if not buffs.has(key):continue
		var target=buffs[key].target
		if not is_instance_valid(target):buffs.erase(key);continue
		validate_buffs(target)
func _courier_arrive(unit:Node,target:Node,skill:Dictionary)->void:
	var key:="royal_courier:%d:%d"%[unit.get_instance_id(),target.get_instance_id()]
	target.apply_night_relay_buff(key,float(skill.duration),minf(1.30,float(skill.move_multiplier)),maxf(.75,float(skill.attack_interval_multiplier)))
	# Simulation clock owns this Royal lifetime. The recipient's later physics
	# step in the arrival frame must not subtract that frame a second time.
	target.night_relay_buffs[key].combat_deadline=float(combat.root.combat_time)+float(skill.duration)
	target.crown_courier_sources[key]=unit.get_instance_id()
	buffs[key]={"source":unit,"target":target,"resistance_bonus":clampf(float(skill.status_resistance_bonus),0,.20)}
	unit.stop_navigation();_record(unit,"royal_courier_arrivals",1)
	combat.root.support_mastery.record_support(unit,"royal_courier_arrival",1)
	combat.spawn_effect_burst("fx_popo_relay",target.global_position,Vector2.ZERO,Vector2.ONE,11)
	combat.root._play_update4_crown_sfx(POPO,"royal_courier:%d:%d"%[unit.get_instance_id(),int(unit.get_meta("royal_courier_uses",0))])
	combat.root._log("왕관 긴급전령 실제 도착 · %s 6초 이동·공격·상태 저항 지원."%target.display_name)
func validate_buffs(target:Node)->void:
	for key in target.crown_courier_sources.keys():
		if not buffs.has(key) or buffs[key].target!=target or not active(buffs[key].source,POPO) or target.is_queued_for_deletion() or not target.is_alive() or not target.night_relay_buffs.has(key):
			_remove_buff(key,target);continue
		var effect:Dictionary=target.night_relay_buffs[key]
		effect.remaining=maxf(0.0,float(effect.combat_deadline)-float(combat.root.combat_time))
		if float(effect.remaining)<=0:_remove_buff(key,target)
func resistance_factor(target:Node)->float:
	validate_buffs(target);var bonus:=0.0
	for key in target.crown_courier_sources:bonus=maxf(bonus,float(buffs[key].resistance_bonus))
	return 1.0-bonus
func _remove_buff(key:String,target:Node)->void:
	target.crown_courier_sources.erase(key);target.night_relay_buffs.erase(key);target._refresh_night_relay_multipliers()
	if buffs.has(key) and buffs[key].target==target:buffs.erase(key)
func room_transition(unit:Node,previous:String,current:String)->void:
	if not active(unit,POPO) or previous=="" or current=="" or previous==current or bool(unit.get_meta("royal_mail_cd_used",false)):return
	unit.set_meta("royal_mail_cd_used",true)
	var slots:Array=DataRegistry.monster(str(unit.unit_id)).get("skill_slots",[])
	if slots.is_empty() or slots[0]==null:return
	var skill_id:String=str(slots[0]);var remaining:float=float(unit.skill_cooldowns.get(skill_id,0))
	unit.set_skill_cooldown(skill_id,remaining*.70);_record(unit,"royal_mail_cooldown_seconds",remaining*.30)
func jelly_caption(unit:Node)->String:
	var result:Dictionary=unit.get_meta("jelly_inheritance_result",{})
	if str(result.get("kind",""))=="anchor":
		if bool(result.get("anchored",false)):return combat.root.continuity.localized("방호 · 중앙 방어 +3","Guard · Center DEF +3","防护 · 中央防御 +3")
		return combat.root.continuity.localized("방호 · 중앙 접근","Guard · Approaching center","防护 · 接近中央") if unit.crown_anchor_pending else combat.root.continuity.localized("방호 · 중앙 접근 불가","Guard · Center unreachable","防护 · 无法到达中央")
	if str(result.get("kind",""))=="rescue":return combat.root.continuity.localized("방호 · 아군 안전 이동","Guard · Ally moved to safety","防护 · 友军安全移动") if bool(result.get("moved",false)) else combat.root.continuity.localized("방호 · 구조 이동 불가","Guard · Rescue movement blocked","防护 · 无法救援移动")
	return combat.root.continuity.localized("왕관 젤 방호","Royal jelly guard","王冠凝胶防护")
func _record(unit:Node,key:String,amount:float)->void:
	if amount<=0:return
	var id:int=unit.get_instance_id();var counter:Dictionary=contributions.get(id,{})
	counter[key]=float(counter.get(key,0))+amount;contributions[id]=counter
	combat.root._record_monster_contribution(str(unit.unit_id),key,amount)
func clear()->void:
	for value in anchors.values():
		if is_instance_valid(value.unit):value.unit.crown_anchor_pending=false;value.unit.crown_anchor_fixed=false;value.unit.stop_navigation()
	for value in transits.values():
		if is_instance_valid(value.unit):value.unit.stop_navigation()
	for key in buffs.keys():
		if is_instance_valid(buffs[key].target):_remove_buff(key,buffs[key].target)
	anchors.clear();transits.clear();buffs.clear();contributions.clear()
