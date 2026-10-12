extends RefCounted
const Constants=preload("res://scripts/core/Constants.gd")
const FORM:="crown_gob_midnight_marshal"
var _combat_ref:WeakRef
var combat:
	get:return _combat_ref.get_ref() if _combat_ref!=null else null
var marks:Dictionary={}
var chains:Dictionary={}
var penalties:Dictionary={}
var trap_windows:Dictionary={}
var contributions:Dictionary={}
var generation:=0
func setup(controller)->void:_combat_ref=weakref(controller)
func alive(unit)->bool:return is_instance_valid(unit) and not unit.is_queued_for_deletion() and unit.is_alive()
func active(unit)->bool:return alive(unit) and combat._active_crown_id(unit)==FORM
func room(unit)->String:return combat.crown_mobility.room_of(unit)
func clock()->float:return float(combat.root.combat_time)
func owned(unit)->bool:return is_instance_valid(unit) and chains.has(unit.get_instance_id())
func available(unit)->bool:
	return active(unit) and not owned(unit) and int(unit.get_meta("royal_chain_uses",0))<int(DataRegistry.skill("royal_no_second_cut").get("uses_per_battle",2))
func mark(unit)->Node:
	if not active(unit):
		if is_instance_valid(unit):marks.erase(unit.get_instance_id())
		return null
	var best:Node=null;var score:=-INF
	for enemy in combat.root.enemy_units:
		if not alive(enemy):continue
		var pressure:=0.0;var current:String=room(enemy)
		var timer:float=float(combat.root.thief_steal_timers.get(enemy,0.0))
		if str(enemy.unit_id)=="thief" and timer< -100:pressure=500.0
		elif str(enemy.unit_id)=="thief" and current==combat._treasure_room() and str(enemy.goal_room)==current and not combat._thief_loot_is_contested(enemy) and timer>0 and timer<5:pressure=400.0+timer
		elif current in [combat._core_room(),"heart_chamber"] and str(enemy.goal_room)==current:pressure=300.0
		elif combat.root._facility_room_is_active(current) and str(combat.root.rooms.get(current,{}).get("facility_role","")) not in ["","none","core","treasure"] and str(enemy.goal_room)==current:pressure=200.0
		elif current==room(unit):pressure=100.0
		var candidate:float=pressure-unit.global_position.distance_to(enemy.global_position)/10000.0
		if best==null or candidate>score or (is_equal_approx(candidate,score) and enemy.get_instance_id()<best.get_instance_id()):best=enemy;score=candidate
	if best==null:marks.erase(unit.get_instance_id());return null
	var old:Dictionary=marks.get(unit.get_instance_id(),{})
	marks[unit.get_instance_id()]={"source":"royal_command","target":best,"score":score}
	if old.get("target")!=best:
		combat.spawn_effect_burst("guard",best.global_position,Vector2(0,-24),Vector2(.8,.8),10)
		combat.root._log("왕명 표식 · %s (%s)."%[best.display_name,combat._room_name(room(best))])
	return best
func support(enemy)->bool:
	var data:Dictionary=DataRegistry.enemy(str(enemy.unit_id));var tags:Array=data.get("role_tags",[])
	return str(data.get("role",""))=="support" or tags.has("support") or tags.has("healing") or tags.has("aura")
func prepare(unit)->Dictionary:
	if not available(unit):return {}
	var focus=combat._v122_focus_target();var primary=focus if alive(focus) else mark(unit)
	if not alive(primary) or combat.crown_mobility.safe_route(unit.global_position,primary.global_position).is_empty():return {}
	if unit.threat_forced and unit.threat_timer>0 and alive(unit.threat_unit) and unit.threat_unit!=primary:return {}
	var secondary:Node=null;var distance:=INF
	for enemy in combat.root.enemy_units:
		if enemy==primary or not alive(enemy) or not support(enemy) or room(enemy)!=room(primary):continue
		var adjacent:float=enemy.global_position.distance_to(primary.global_position)
		if adjacent>float(unit.attack_range)+38.0 or combat.crown_mobility.safe_route(primary.global_position,enemy.global_position).is_empty():continue
		if adjacent<distance or (is_equal_approx(adjacent,distance) and (secondary==null or enemy.get_instance_id()<secondary.get_instance_id())):secondary=enemy;distance=adjacent
	return {"primary":primary,"secondary":secondary,"primary_room":room(primary),"origin":unit.global_position,"origin_room":room(unit),"source":combat.crown_mobility.source_evolution(unit,true),"focus_id":focus.get_instance_id() if alive(focus) else 0}
func valid(unit,plan:Dictionary)->bool:
	if plan.is_empty() or not available(unit) or not alive(plan.primary) or room(plan.primary)!=str(plan.primary_room) or room(unit)!=str(plan.origin_room) or unit.global_position.distance_to(plan.origin)>.1:return false
	if str(plan.source)!=combat.crown_mobility.source_evolution(unit) or unit.active_skills_locked() or unit.duo_action_locked() or unit.seal_move_lock_timer>0 or unit.duo_move_lock_timer>0:return false
	var focus=combat._v122_focus_target()
	if (focus.get_instance_id() if alive(focus) else 0)!=int(plan.focus_id):return false
	return not (unit.threat_forced and unit.threat_timer>0 and alive(unit.threat_unit) and unit.threat_unit!=plan.primary) and not combat.crown_mobility.safe_route(unit.global_position,plan.primary.global_position).is_empty()
func begin(unit,plan:Dictionary,notify_ai:bool=false)->void:
	chains[unit.get_instance_id()]={"unit":unit,"plan":plan.duplicate(),"phase":"primary","strikes":0,"generation":generation,"in_flight":false,"cancel_requested":false,"cancel_navigation":true,"notify_ai":notify_ai,"last_position":unit.global_position,"stall":0.0}
	unit.set_meta("royal_chain_result",{"phase":"approach","strikes":0})
	unit.play_skill(plan.primary.global_position);unit.stop_navigation();_approach(unit,plan.primary.global_position,"왕명 표적 접근")
func _approach(unit,destination:Vector2,label:String)->bool:
	# Rebuilding a graph route every frame would repeatedly lead back to its
	# starting grid center. Preserve the walking route until the endpoint moves.
	if not unit.path_points.is_empty() and unit.path_points[-1].distance_to(destination)<=unit.PATH_POINT_REACHED_RADIUS:
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET,label)
		return true
	var route:Array=combat.crown_mobility.safe_route(unit.global_position,destination)
	if route.is_empty():return false
	unit.set_path(route);unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET,label)
	return true
func defense_factor(unit)->float:
	if not is_instance_valid(unit):return 1.0
	var id:int=unit.get_instance_id()
	if penalties.has(id) and (not active(unit) or clock()>=float(penalties[id].ends)):penalties.erase(id)
	return float(penalties[id].factor) if penalties.has(id) else 1.0
func _finish(unit,state:Dictionary,clear_navigation:bool=true)->void:
	if int(state.strikes)>0 and active(unit):
		var skill:Dictionary=DataRegistry.skill("royal_no_second_cut")
		penalties[unit.get_instance_id()]={"unit":unit,"ends":clock()+float(skill.post_def_duration),"factor":float(skill.post_def_multiplier)}
	unit.set_meta("royal_chain_result",{"phase":"finished","strikes":int(state.strikes)})
	chains.erase(unit.get_instance_id())
	if clear_navigation:unit.stop_navigation()
func cancel(unit,clear_navigation:bool=true)->void:
	if not owned(unit):return
	var state:Dictionary=chains[unit.get_instance_id()]
	if bool(state.in_flight):
		state.cancel_requested=true;state.cancel_navigation=clear_navigation
		return
	_finish(unit,state,clear_navigation)
	combat.root._log("왕명 연쇄 중단 · 실제 명중 %d회, 확정 사용은 유지."%int(state.strikes))
func _return(unit,state:Dictionary)->void:
	state.phase="return";state.stall=0.0;state.last_position=unit.global_position;unit.stop_navigation()
	if not _approach(unit,state.plan.origin,"왕명 출발점 복귀"):
		combat.root._log("왕명 복귀 경로 차단 · 현재 위치에서 종료.");_finish(unit,state)
func tick(delta:float)->void:
	for unit in combat.root.monster_units:
		if active(unit):mark(unit)
	for id in marks.keys():
		var unit=instance_from_id(int(id))
		if not active(unit) or not alive(marks[id].target):marks.erase(id)
	for id in penalties.keys():
		if not is_instance_valid(penalties[id].unit):penalties.erase(id)
		else:defense_factor(penalties[id].unit)
	for id in trap_windows.keys():
		var window:Dictionary=trap_windows[id]
		if not active(window.unit) or not alive(window.target) or clock()>=float(window.ends):trap_windows.erase(id)
	for id in chains.keys():
		if not chains.has(id):continue
		var state:Dictionary=chains[id];var unit=state.unit;var plan:Dictionary=state.plan
		if not alive(unit):chains.erase(id);continue
		if not active(unit) or str(plan.source)!=combat.crown_mobility.source_evolution(unit):cancel(unit);continue
		var focus=combat._v122_focus_target()
		if (focus.get_instance_id() if alive(focus) else 0)!=int(plan.focus_id):cancel(unit);continue
		var current=plan.primary if str(state.phase)=="primary" else plan.secondary
		if unit.threat_forced and unit.threat_timer>0 and alive(unit.threat_unit) and (str(state.phase)=="return" or unit.threat_unit!=current):cancel(unit);continue
		if unit.active_skills_locked() or unit.duo_action_locked() or unit.tactical_state==Constants.UNIT_STATE_STUNNED or unit.seal_move_lock_timer>0 or unit.duo_move_lock_timer>0:continue
		if str(state.phase)=="return":
			if room(unit)==str(plan.origin_room) and unit.global_position.distance_to(plan.origin)<=unit.PATH_POINT_REACHED_RADIUS:
				_record(unit,"royal_chain_returns",1);_finish(unit,state);continue
		elif not alive(current) or room(current)!=str(plan.primary_room):
			_return(unit,state);continue
		elif str(state.phase)=="secondary" and current.global_position.distance_to(plan.get("primary_contact_point",plan.origin))>float(unit.attack_range)+38:
			_return(unit,state);continue
		elif unit.global_position.distance_to(current.global_position)<=float(unit.attack_range) and room(unit)==room(current):
			unit.stop_navigation();state.stall=0.0
			if unit.attack_cooldown>0 or combat.presentation_hold or combat.pending_atomic_tail.is_valid() or bool(state.in_flight):continue
			state.in_flight=true
			var impact:Dictionary=combat._perform_standard_attack(unit,current,false,Callable(self,"_strike_contact").bind(unit,current,state,id))
			state.in_flight=false
			if int(state.generation)!=generation or not chains.has(id):continue
			if not bool(impact.get("applied",false)):_return(unit,state);continue
			if not active(unit):cancel(unit);continue
			if bool(state.cancel_requested):_finish(unit,state,bool(state.cancel_navigation));continue
			combat.spawn_effect_burst("slash",unit.global_position,Vector2.ZERO,Vector2.ONE,12)
			if str(state.phase)=="primary" and alive(plan.secondary) and room(plan.secondary)==str(plan.primary_room) and plan.secondary.global_position.distance_to(plan.primary.global_position)<=float(unit.attack_range)+38:
				state.phase="secondary";_approach(unit,plan.secondary.global_position,"왕명 보조 적 접근")
			else:_return(unit,state)
			continue
		else:
			if not _approach(unit,current.global_position,"왕명 표적 접근"):_return(unit,state);continue
		if not chains.has(id):continue
		state.stall=float(state.stall)+delta if unit.global_position.distance_to(state.last_position)<=unit.NAVIGATION_PROGRESS_EPSILON else 0.0
		state.last_position=unit.global_position
		if float(state.stall)>=unit.NAVIGATION_STALL_TIMEOUT:
			if str(state.phase)=="return":combat.root._log("왕명 복귀 정체 · 현재 위치에서 종료.");_finish(unit,state)
			else:_return(unit,state)
func _strike_contact(impact:Dictionary,unit,current,state:Dictionary,id:int)->void:
	if int(state.generation)!=generation or not chains.has(id) or not bool(impact.get("applied",false)):return
	state.strikes=int(state.strikes)+1;unit.set_meta("royal_chain_result",{"phase":"contact","strikes":state.strikes})
	if int(state.strikes)==1:state.plan.primary_contact_point=current.global_position
	_record(unit,"royal_chain_contacts",1);_record(unit,"royal_chain_actual_hp_damage",float(impact.get("actual_hp_loss",0)))
	if int(state.strikes)==1:
		unit.set_meta("royal_chain_uses",int(unit.get_meta("royal_chain_uses",0))+1)
		combat.record_ledger_skill_use(unit,"royal_no_second_cut")
		if bool(state.notify_ai) and combat.root.has_method("_tutorial_emit_action"):combat.root._tutorial_emit_action("skill_used",{"skill_id":"royal_no_second_cut","unit_id":unit.unit_id})
	if int(state.generation)!=generation or not chains.has(id) or not active(unit):return
	if int(state.strikes)==1 and str(state.plan.source)=="goblin_ambush_captain":trap_windows[id]={"unit":unit,"target":state.plan.primary,"ends":clock()+4.0}
	if str(state.plan.source)=="goblin_vault_keeper":_record(unit,"royal_chain_theft_seconds_cancelled",interrupt_objective_channel(current))
func interrupt_objective_channel(enemy)->float:
	if not alive(enemy) or str(enemy.unit_id)!="thief" or room(enemy)!=combat._treasure_room() or str(enemy.goal_room)!=combat._treasure_room() or combat._thief_loot_is_contested(enemy):return 0.0
	var progress:float=float(combat.root.thief_steal_timers.get(enemy,0.0))
	if progress<=0 or progress>=5:return 0.0
	combat.root.thief_steal_timers[enemy]=0.0
	combat.root._log("금고 왕명 · 실제 약탈 진행 %.1f초 중단."%progress)
	return progress
func trap_request(enemy,base:int)->Dictionary:
	for id in trap_windows.keys():
		var window:Dictionary=trap_windows[id]
		if not active(window.unit) or not alive(window.target) or clock()>=float(window.ends):trap_windows.erase(id);continue
		if window.target==enemy:
			trap_windows.erase(id)
			return {"unit":window.unit,"base":base,"damage":roundi(base*1.20)}
	return {"damage":base}
func trap_contact(request:Dictionary,actual_hp:int)->void:
	if not request.has("unit"):return
	var unit=request.unit
	if not alive(unit):return
	_record(unit,"royal_trap_contacts",1);_record(unit,"royal_trap_actual_total_hp_damage",actual_hp);_record(unit,"royal_trap_extra_requested_damage",int(request.damage)-int(request.base))
func caption(unit)->String:return combat.root.continuity.localized("연쇄 접근 시작 · 실제 타격 후 사용","Chain approach · Use on actual first hit","连击接近 · 实际首击后计次")
func status(unit)->String:
	if not active(unit):return ""
	var target=mark(unit);var value:String=combat.root.continuity.localized("왕명","Royal mark","王令")+" · "+(target.display_name if alive(target) else "—")
	value+=" · %d/2"%int(unit.get_meta("royal_chain_uses",0))
	if owned(unit):
		var phase:String=str(chains[unit.get_instance_id()].phase)
		value+=" · "+combat.root.continuity.localized("표적 접근" if phase=="primary" else "보조 적 접근" if phase=="secondary" else "출발점 복귀","Primary approach" if phase=="primary" else "Support approach" if phase=="secondary" else "Returning","接近目标" if phase=="primary" else "接近辅助敌" if phase=="secondary" else "返回起点")
	if defense_factor(unit)<1:value+=" · "+combat.root.continuity.localized("방어-15%","DEF-15%","防御-15%")+" %.1fs"%maxf(0,float(penalties[unit.get_instance_id()].ends)-clock())
	return value
func _record(unit,key:String,amount:float)->void:
	if amount<=0:return
	var record:Dictionary=contributions.get(unit.get_instance_id(),{});record[key]=float(record.get(key,0))+amount;contributions[unit.get_instance_id()]=record
	combat.root._record_monster_contribution(str(unit.unit_id),key,amount)
func clear()->void:
	generation+=1
	for state in chains.values():
		if is_instance_valid(state.unit):state.unit.stop_navigation()
	marks.clear();chains.clear();penalties.clear();trap_windows.clear();contributions.clear()
