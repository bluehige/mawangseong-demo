extends RefCounted
const Constants=preload("res://scripts/core/Constants.gd")
const Dusk=preload("res://scripts/systems/enemies/DuskCourierCounterService.gd")
const Vesper=preload("res://scripts/systems/bosses/VesperBossBattleService.gd")
const Shadow=preload("res://scripts/systems/enemies/ShadowDuelistPressureService.gd")
const Upper=preload("res://scripts/systems/council/CouncilObjectiveService.gd")
const Popo=preload("res://scripts/systems/monsters/PopoCombatService.gd")
const NATIVE_IDS:=["dusk_courier","rival_vesper_council_champion"]
var _combat_ref:WeakRef
var combat:
	get:return _combat_ref.get_ref() if _combat_ref!=null else null
var generation:=0
var channels:Dictionary={}
var gold_channels:Dictionary={}
var shadows:Dictionary={}
var losses:Array=[]
var pending_bag:Dictionary={}
var bag_state:Dictionary=Popo.new_bag_state()
var loss_claimed:=false
var metrics:Dictionary={}
func setup(controller)->void:_combat_ref=weakref(controller)
func clock()->float:return float(combat.root.combat_time)
func alive(unit)->bool:return is_instance_valid(unit) and not unit.is_queued_for_deletion() and unit.is_alive()
func room(unit)->String:return combat.crown_mobility.room_of(unit)
func council_stock()->Dictionary:return combat.root.update4_active_run.get("council_season",{})
func stock_available()->bool:
	var council:Dictionary=council_stock()
	return int(council.get("council_votes",0))>=int(DataRegistry.update4_expansion_modules.get("seal_vault",{}).get("vote_loss",5)) or int(council.get("council_seals",0))>0
func objective_room()->String:
	var expansion: Dictionary = combat.root.update4_active_run.get("expansion",{})
	var target:String=str(expansion.get("rooms",{}).get("seal_vault","")) if bool(expansion.get("unlocked",false)) else combat._treasure_room()
	return target if target!="" and combat.root.graph.module_instance_ids().has(target) else ""
func context_available()->bool:return combat.root._update4_council_mode_active() and not loss_claimed and stock_available() and objective_room()!=""
func spawn(unit)->void:
	if not alive(unit) or str(unit.unit_id) not in NATIVE_IDS:return
	if not context_available():return
	var destination:String=objective_room();var point:Vector2=combat.root.graph.center(destination)
	if combat.crown_mobility.safe_route(unit.global_position,point).is_empty():return
	channels[unit.get_instance_id()]={"unit":unit,"kind":"dusk" if str(unit.unit_id)=="dusk_courier" else "vesper","phase":"moving","room":destination,"generation":generation,"channel_generation":1,"state":{},"next_cast":0.0,"started":0.0}
	unit.goal_room=destination;unit.stop_navigation();_walk(unit,point,"1층 의회 금고 접근")
	if bool(combat.root.update4_active_run.get("expansion",{}).get("unlocked",false)):
		var connected: Array = combat.root.graph.path_between(room(unit),destination)
		if str(unit.unit_id)=="dusk_courier":
			if Dusk.air_shortcut_path(room(unit),destination,connected).is_empty(): _fallback(unit)
		else:
			var route: Array = combat.crown_mobility.safe_route(unit.global_position,point)
			var endpoints := {"%s:%s" % [room(unit),destination]:[unit.global_position,point]}
			var dive := Vesper.deadline_dive(room(unit),destination,endpoints,DataRegistry.skill("deadline_dive"))
			if dive.ok and not route.is_empty() and connected.size() >= 2:
				var entry: Dictionary = channels[unit.get_instance_id()]
				entry.phase="dive_warning"; entry.dive=dive; entry.route=route; entry.route_start=unit.global_position; entry.dive_elapsed=0.0
				unit.stop_navigation(); combat.council_objectives.alert(destination)
func _walk(unit,destination:Vector2,label:String)->bool:
	if not unit.path_points.is_empty() and unit.path_points[-1].distance_to(destination)<=unit.PATH_POINT_REACHED_RADIUS:
		unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET,label);return true
	var route:Array=combat.crown_mobility.safe_route(unit.global_position,destination)
	if route.is_empty():return false
	unit.set_path(route);unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET,label);return true
func _at_anchor(unit,entry:Dictionary)->bool:
	return alive(unit) and room(unit)==str(entry.room) and unit.global_position.distance_to(combat.root.graph.center(str(entry.room)))<=unit.PATH_POINT_REACHED_RADIUS
func gold_active(unit)->bool:
	return _gold_inside(unit) and not combat._thief_loot_is_contested(unit)
func _gold_inside(unit)->bool:
	return alive(unit) and str(unit.unit_id)=="thief" and room(unit)==combat._treasure_room() and str(unit.goal_room)==combat._treasure_room() and float(combat.root.thief_steal_timers.get(unit,0.0))>=0
func _gold_context(unit)->Dictionary:
	var inside:bool=_gold_inside(unit)
	var entry:Dictionary=gold_channels.get(unit.get_instance_id(),{"generation":1,"inside":inside})
	return {"generation":int(entry.generation)+(1 if bool(entry.inside)!=inside else 0),"inside":inside}
func _sync_gold()->void:
	for unit in combat.root.enemy_units:
		if not alive(unit) or str(unit.unit_id)!="thief":continue
		var id:int=unit.get_instance_id();var inside:bool=_gold_inside(unit)
		if not gold_channels.has(id):gold_channels[id]={"unit":unit,"generation":1,"inside":inside}
		var entry:Dictionary=gold_channels[id]
		if bool(entry.inside)!=inside:
			combat.echo_alarm.discard_channel(unit,int(entry.generation));entry.generation=int(entry.generation)+1;entry.inside=inside
	for id in gold_channels.keys():
		if not alive(gold_channels[id].unit):gold_channels.erase(id)
func channel_generation(unit)->int:
	if gold_active(unit):return int(_gold_context(unit).generation)
	if not alive(unit) or not channels.has(unit.get_instance_id()):return -1
	var entry:Dictionary=channels[unit.get_instance_id()]
	return int(entry.channel_generation) if str(entry.phase)=="channel" and _at_anchor(unit,entry) else -1
func channel_exists(unit,channel:int)->bool:
	if not alive(unit):return false
	if str(unit.unit_id)=="thief":
		var entry:Dictionary=_gold_context(unit)
		return bool(entry.inside) and int(entry.generation)==channel
	var entry:Dictionary=channels.get(unit.get_instance_id(),{})
	return int(entry.get("channel_generation",-1))==channel and str(entry.get("phase",""))=="channel" and _at_anchor(unit,entry)
func attack_owned(unit)->bool:
	if not is_instance_valid(unit):return false
	return str(channels.get(unit.get_instance_id(),{}).get("phase","")) in ["channel","retry","exit","dive_warning","dive_travel"]
func incoming_factor(unit)->float:
	if not alive(unit):return 1.0
	var entry:Dictionary=channels.get(unit.get_instance_id(),{})
	if str(entry.get("kind",""))=="vesper" and str(entry.get("phase",""))=="channel" and _at_anchor(unit,entry):return float(entry.state.get("incoming_damage_multiplier",1.25))
	return 1.0
func _start(unit,entry:Dictionary)->void:
	unit.stop_navigation();entry.phase="channel";entry.started=clock()
	if str(entry.kind)=="dusk":entry.state=Dusk.start_theft(Dusk.new_theft_state(str(unit.get_instance_id()),DataRegistry.skill("seal_envelope")),DataRegistry.skill("seal_envelope"))
	else:
		entry.state=Vesper.start_seal_snatch(DataRegistry.skill("seal_snatch"));entry.next_cast=clock()+float(DataRegistry.skill("seal_snatch").get("cooldown",14))
	if bool(combat.root.update4_active_run.get("expansion",{}).get("unlocked",false)) and str(entry.kind)=="dusk":
		entry["warning_remaining"] = float(DataRegistry.update4_expansion_modules.seal_vault.warning_seconds)
		combat.council_objectives.alert(str(entry.room))
	unit.set_tactical_state(Constants.UNIT_STATE_LOOTING,"1층 의회 자원 수거",combat._room_name(str(entry.room)))
	combat.root._log("%s · 실제1층 의회 금고 수거 %.1f초 시작."%[unit.display_name,_remaining(entry)])
func _remaining(entry:Dictionary)->float:
	return float(entry.state.get("channel_remaining",4)) if str(entry.kind)=="dusk" else float(entry.state.get("remaining",5))
func _cancel_channel(unit,entry:Dictionary)->void:
	combat.echo_alarm.discard_channel(unit,int(entry.channel_generation));entry.channel_generation=int(entry.channel_generation)+1;entry.state={};entry.phase="moving"
	unit.stop_navigation()
func damage_received(unit,hp_before:int,hp_after:int)->void:
	if not is_instance_valid(unit) or hp_before<=hp_after:return
	var id:int=unit.get_instance_id()
	if shadows.has(id):shadows[id].hidden_ends=clock();refresh_concealment(unit)
	if not pending_bag.is_empty() and pending_bag.get("thief")==unit and hp_after<=0:
		pending_bag.drop=true;pending_bag.point=unit.global_position
		combat.spawn_effect_burst("fx_popo_relay",unit.global_position,Vector2.ZERO,Vector2.ONE,10)
	if not channels.has(id):return
	var entry:Dictionary=channels[id]
	if str(entry.kind)=="dusk" and str(entry.phase)=="channel":
		combat.echo_alarm.discard_channel(unit,int(entry.channel_generation));entry.channel_generation=int(entry.channel_generation)+1
		entry.state=Dusk.receive_damage(entry.state,DataRegistry.skill("seal_envelope"));entry.phase="retry"
		_count("dusk_actual_damage_interrupts",1)
func interrupt(unit)->float:
	if not alive(unit) or not channels.has(unit.get_instance_id()):return 0.0
	var entry:Dictionary=channels[unit.get_instance_id()]
	if str(entry.phase)!="channel" or not _at_anchor(unit,entry):return 0.0
	var total:float=float(DataRegistry.skill("seal_envelope" if str(entry.kind)=="dusk" else "seal_snatch").get("channel_seconds",4 if str(entry.kind)=="dusk" else 5))
	var cancelled:float=maxf(0,total-_remaining(entry))
	if cancelled<=0:return 0.0
	combat.echo_alarm.discard_channel(unit,int(entry.channel_generation));entry.channel_generation=int(entry.channel_generation)+1
	if str(entry.kind)=="dusk":entry.state=Dusk.receive_damage(entry.state,DataRegistry.skill("seal_envelope"));entry.phase="retry"
	else:entry.state=Vesper.start_seal_snatch(DataRegistry.skill("seal_snatch"));entry.started=clock()
	_count("native_royal_interrupt_milliseconds",roundi(cancelled*1000));return cancelled
func behavior(unit)->bool:
	if not alive(unit):return false
	if unit.action_interrupt_timer>0:return channels.has(unit.get_instance_id()) or str(unit.unit_id)=="shadow_duelist"
	if str(unit.unit_id)=="shadow_duelist":return _shadow_behavior(unit)
	if not channels.has(unit.get_instance_id()):return false
	var entry:Dictionary=channels[unit.get_instance_id()]
	match str(entry.phase):
		"dive_warning","dive_travel":
			unit.stop_navigation(); unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET,"연결 통로 급강하",combat._room_name(str(entry.room)))
		"moving":
			if not _walk(unit,combat.root.graph.center(str(entry.room)),"1층 의회 금고 접근"):_fallback(unit);return false
		"channel","retry":
			unit.stop_navigation();unit.set_tactical_state(Constants.UNIT_STATE_LOOTING,"의회 수거 %.1f초"%_remaining(entry),"피격 재시도" if str(entry.phase)=="retry" else combat._room_name(str(entry.room)))
		"exit":_walk(unit,combat.root.graph.center(str(unit.goal_room)),"의회 봉투 탈출")
	return true
func _fallback(unit)->void:
	if not is_instance_valid(unit):return
	var entry:Dictionary=channels.get(unit.get_instance_id(),{})
	if not entry.is_empty():combat.echo_alarm.discard_channel(unit,int(entry.channel_generation))
	channels.erase(unit.get_instance_id());unit.goal_room=combat._core_room();unit.stop_navigation();unit.set_path(combat._path_from_world_to_room(unit.global_position,unit.goal_room))
func tick(delta:float)->void:
	_sync_gold()
	for unit in combat.root.enemy_units:
		if not alive(unit):continue
		if str(unit.unit_id) in NATIVE_IDS and not channels.has(unit.get_instance_id()) and context_available():spawn(unit)
		if str(unit.unit_id)=="shadow_duelist":_tick_shadow(unit)
	for id in channels.keys():
		if not channels.has(id):continue
		var entry:Dictionary=channels[id];var unit=entry.unit
		if not alive(unit):channels.erase(id);continue
		if int(entry.generation)!=generation:_fallback(unit);continue
		if str(entry.phase) in ["dive_warning","dive_travel"]:
			_tick_dive(unit,entry,delta); continue
		if str(entry.phase)=="exit":
			if room(unit)==str(unit.goal_room) and unit.global_position.distance_to(combat.root.graph.center(str(unit.goal_room)))<=unit.PATH_POINT_REACHED_RADIUS:
				unit.hp=0;unit.down=true;unit.escaped=true;unit.visible=false;channels.erase(id);_count("native_1f_couriers_escaped",1)
			continue
		if not context_available():_fallback(unit);continue
		if str(entry.room)!=objective_room():_fallback(unit);continue
		if str(entry.phase)=="moving":
			if _at_anchor(unit,entry) and clock()>=float(entry.next_cast):_start(unit,entry)
			continue # A new channel owns its full duration after actual arrival.
		if not _at_anchor(unit,entry):_cancel_channel(unit,entry);continue
		if unit.action_interrupt_timer>0 or unit.tactical_state==Constants.UNIT_STATE_STUNNED:continue
		var remaining:float=maxf(0,delta)
		if str(entry.phase)=="retry":
			var wait:float=float(entry.state.get("retry_remaining",1));var consumed:float=minf(wait,remaining)
			entry.state.retry_remaining=wait-consumed;remaining-=consumed
			if float(entry.state.retry_remaining)>.00001:continue
			entry.phase="channel";entry.state.phase="channel";entry.started=clock()-remaining
		if float(entry.get("warning_remaining",0)) > 0:
			var consumed_warning := minf(remaining,float(entry.warning_remaining))
			entry.warning_remaining = float(entry.warning_remaining)-consumed_warning
			remaining -= consumed_warning
		if remaining>0:
			remaining=combat.echo_alarm.consume_delay(unit,remaining,int(entry.channel_generation))
			var channel_remaining:float=_remaining(entry)
			if str(entry.kind)=="dusk":entry.state=Dusk.tick_theft(entry.state,remaining)
			else:entry.state=Vesper.tick_seal_snatch(entry.state,remaining)
			if bool(entry.state.get("completed",false)):
				_settle(unit,entry,clock()-maxf(0,remaining-channel_remaining))
	_tick_bag()
func _tick_dive(unit,entry:Dictionary,delta:float)->void:
	if not context_available() or str(entry.room)!=objective_room(): _fallback(unit); return
	if unit.action_interrupt_timer>0 or unit.tactical_state==Constants.UNIT_STATE_STUNNED:return
	entry.dive_elapsed=float(entry.dive_elapsed)+maxf(0,delta)
	if str(entry.phase)=="dive_warning":
		if float(entry.dive_elapsed)<float(entry.dive.warning_seconds):return
		entry.dive_elapsed=maxf(0,float(entry.dive_elapsed)-float(entry.dive.warning_seconds));entry.phase="dive_travel"
	var duration:=maxf(.0001,float(entry.dive.travel_seconds))
	var ratio:=clampf(float(entry.dive_elapsed)/duration,0,1)
	var length:=0.0;var previous:Vector2=entry.route_start
	for point:Vector2 in entry.route:length+=previous.distance_to(point);previous=point
	var distance:=length*ratio;previous=entry.route_start
	for point:Vector2 in entry.route:
		var segment:=previous.distance_to(point)
		if distance<=segment:
			unit.global_position=previous.lerp(point,distance/maxf(.0001,segment));break
		distance-=segment;previous=point
	unit.current_room=room(unit);unit.refresh_depth_slot()
	if ratio<1:return
	unit.global_position=entry.route[-1];unit.current_room=str(entry.room);entry.phase="moving"
	unit.apply_action_interrupt(float(entry.dive.arrival_lock_seconds))
	for ally in combat.root.monster_units:
		if alive(ally) and room(ally)==str(entry.room):ally.seal_skill_lock_timer=maxf(ally.seal_skill_lock_timer,float(entry.dive.silence_seconds))
	_count("native_passage_dives",1)
func _settle(unit,entry:Dictionary,completed_at:float)->void:
	if loss_claimed or not alive(unit) or not _at_anchor(unit,entry):_fallback(unit);return
	var before:Dictionary=council_stock().duplicate(true)
	if not stock_available():_fallback(unit);return
	var result:Dictionary=Upper.settle_seal_theft(combat.root.update4_active_run,{"seal_theft":{"ready_to_settle":true,"loss_applied":false}},DataRegistry.update4_expansion_modules)
	var after:Dictionary=result.active_run.get("council_season",{});var kind:="";var amount:=0
	for key in ["council_votes","council_seals"]:
		var removed:int=maxi(0,int(before.get(key,0))-int(after.get(key,0)))
		if removed>0:kind=key;amount=removed;break
	if amount<=0:_fallback(unit);return
	loss_claimed=true
	var loss:Dictionary={"id":"1f:%d:%d:%d"%[generation,unit.get_instance_id(),int(entry.channel_generation)],"owner_id":unit.get_instance_id(),"channel_generation":int(entry.channel_generation),"kind":kind,"amount":amount,"before":before,"after":after.duplicate(true),"status":"final","completed_at":completed_at,"floor_adapter":"actual_1F"}
	losses.append(loss);combat.root.update4_active_run=result.active_run
	_count("native_1f_resource_losses",1);_hold_bag(unit,loss,completed_at)
	combat.echo_alarm.discard_channel(unit,int(entry.channel_generation))
	if str(entry.kind)=="dusk":entry.phase="exit";unit.goal_room=combat._v122_unit_exit_room(unit);unit.stop_navigation();_walk(unit,combat.root.graph.center(str(unit.goal_room)),"의회 봉투 탈출")
	else:_fallback(unit)
	SignalBus.resources_changed.emit()
	combat.root._log("1층 의회 금고 · %s %d 손실%s."%[_resource_name(kind),amount," (포포 회수 대기)" if str(loss.status)=="held" else ""])
func _resource_name(kind:String)->String:return combat.root.continuity.localized("의회 표","Council votes","议会票") if kind=="council_votes" else combat.root.continuity.localized("인장","Seals","印章")
func _count(key:String,amount:int)->void:
	if amount>0:metrics[key]=int(metrics.get(key,0))+amount
func watch_revealed(unit)->bool:
	if not alive(unit):return false
	var current:String=room(unit)
	if combat._v122_uses_zone_facility_effects():
		return str(combat._v122_zone_effect_for_room(current,"detection","enemies").get("facility_role",""))=="watch_post"
	return combat._watch_post_pressure_rooms().has(current)
func concealed(unit)->bool:
	if not alive(unit):return false
	return clock()<float(shadows.get(unit.get_instance_id(),{}).get("hidden_ends",0))
func targetable(unit,observer:Node=null)->bool:
	if not concealed(unit):return true
	if watch_revealed(unit) or combat.echo_alarm.revealed(unit):return true
	return alive(observer) and str(observer.unit_id)=="graveyard_hound" and observer.has_active_scent_mark() and observer.scent_mark_target==unit
func refresh_concealment(unit)->void:
	if not is_instance_valid(unit) or not shadows.has(unit.get_instance_id()):return
	var entry:Dictionary=shadows[unit.get_instance_id()]
	if not alive(unit):entry.alpha_owned=false;return
	var hidden:bool=concealed(unit) and not watch_revealed(unit) and not combat.echo_alarm.revealed(unit)
	var value:Color=unit.modulate
	if hidden:
		if not bool(entry.alpha_owned):entry.original_alpha=value.a
		value.a=float(entry.original_alpha)*.18;unit.modulate=value;entry.alpha_owned=true
	elif bool(entry.alpha_owned):value.a=float(entry.original_alpha);unit.modulate=value;entry.alpha_owned=false
func attack_factor(unit)->float:
	if not alive(unit):return 1.0
	return float(DataRegistry.skill("shadow_promise").get("atk_multiplier",1.20)) if clock()<float(shadows.get(unit.get_instance_id(),{}).get("boost_ends",0)) else 1.0
func defense_factor(unit)->float:
	if not alive(unit):return 1.0
	return float(DataRegistry.skill("shadow_promise").get("def_multiplier",.75)) if clock()<float(shadows.get(unit.get_instance_id(),{}).get("boost_ends",0)) else 1.0
func before_attack(unit)->void:
	if is_instance_valid(unit) and shadows.has(unit.get_instance_id()):
		shadows[unit.get_instance_id()].hidden_ends=clock();refresh_concealment(unit)
func _hunt_target(unit)->Node:
	if unit.threat_forced and unit.threat_timer>0 and alive(unit.threat_unit):return unit.threat_unit
	var candidates:Array=[];var scores:Dictionary={};var recent:Dictionary=combat.root._recent_monster_contribution_scores(12.0)
	for ally in combat.root.monster_units:
		if not alive(ally):continue
		var id:String=str(ally.get_instance_id());candidates.append({"id":id,"active":true});scores[id]=float(recent.get(str(ally.unit_id),0))
	var selected:String=Shadow.select_target(candidates,scores)
	return instance_from_id(int(selected)) if selected!="" else null
func _tick_shadow(unit)->void:
	var id:int=unit.get_instance_id()
	if not shadows.has(id):shadows[id]={"unit":unit,"used":false,"hidden_ends":0.0,"boost_ends":0.0,"alpha_owned":false,"original_alpha":unit.modulate.a}
	var entry:Dictionary=shadows[id];refresh_concealment(unit)
	if bool(entry.used) or unit.action_interrupt_timer>0 or unit.seal_move_lock_timer>0 or unit.duo_move_lock_timer>0:return
	var target=_hunt_target(unit)
	if not alive(target) or room(target)!=room(unit):return
	var direction:Vector2=target.action_direction.normalized()
	if direction==Vector2.ZERO:direction=Vector2.RIGHT
	var skill:Dictionary=DataRegistry.skill("shadow_promise")
	var destination:Vector2=target.global_position-direction*float(skill.get("behind_distance",90))
	if combat.crown_mobility.room_of_point(destination)!=room(target) or combat.crown_mobility.safe_route(unit.global_position,destination).is_empty():return
	unit.global_position=destination;unit.current_room=room(unit);unit.stop_navigation();unit.refresh_depth_slot();unit.play_skill(target.global_position)
	entry.used=true;entry.hidden_ends=clock()+float(skill.get("duration",2));entry.boost_ends=entry.hidden_ends;entry.target=target
	refresh_concealment(unit);_count("native_1f_shadow_promises",1)
	combat.spawn_effect_burst("guard",unit.global_position,Vector2.ZERO,Vector2.ONE,11)
	combat.root._log("그림자 약속 · 실제 같은방 뒤90 급습, 2초 공격·방어 변화 및 잠행.")
func _shadow_behavior(unit)->bool:
	var entry:Dictionary=shadows.get(unit.get_instance_id(),{});var target=entry.get("target") if clock()<float(entry.get("boost_ends",0)) else _hunt_target(unit)
	if not alive(target):return false
	if unit.threat_forced and unit.threat_timer>0 and alive(unit.threat_unit):target=unit.threat_unit
	if combat._hold_attack_position(unit,target):return true
	combat._move_to_attack_target(unit,target,true);unit.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET,"최근 기여 추적",target.display_name)
	return true
func _carrier()->Node:
	for unit in combat.root.monster_units:
		if alive(unit) and str(unit.unit_id)=="bat_courier":return unit
	return null
func _hold_bag(thief,loss:Dictionary,completed_at:float)->void:
	var carrier=_carrier()
	if not alive(carrier):return
	var source:String=str(combat.root.monster_roster.get(str(carrier.unit_id),{}).get("specialization_id",""))
	var result:Dictionary=Popo.hold_first_theft(bag_state,str(thief.get_instance_id()),source,DataRegistry.skill("messenger_bag"))
	if not bool(result.get("held",false)):return
	bag_state=result.state;loss.status="held"
	pending_bag={"loss":loss,"carrier":carrier,"thief":thief,"generation":generation,"ends":completed_at+float(bag_state.pending.remaining),"manual":false,"drop":false,"point":thief.global_position}
	_count("native_bag_holds",1)
func bag_owns(unit)->bool:
	return not pending_bag.is_empty() and pending_bag.get("carrier")==unit and not bool(pending_bag.manual) and not bool(pending_bag.get("closed",false)) and not combat.crown_mobility.transits.has(unit.get_instance_id()) and not combat.single_floor_support.relays.has(unit.get_instance_id())
func manual_command(unit)->void:
	if not pending_bag.is_empty() and pending_bag.get("carrier")==unit:pending_bag.manual=true
func bag_navigation(unit)->bool:
	if not bag_owns(unit):return false
	if unit.seal_move_lock_timer>0 or unit.duo_move_lock_timer>0:return true
	var moving:bool=_walk(unit,Vector2(pending_bag.point),"의회 봉투 실제 회수")
	pending_bag.path_owned=moving
	return moving
func _tick_bag()->void:
	if pending_bag.is_empty():return
	var carrier=pending_bag.carrier;var thief=pending_bag.thief
	if int(pending_bag.generation)!=generation or not alive(carrier):finalize_bag("회수원 부재");return
	if clock()>=float(pending_bag.ends):finalize_bag("회수 기한 종료");return
	if not bool(pending_bag.drop):
		if not alive(thief) or bool(thief.escaped):finalize_bag("절도범 이탈");return
		pending_bag.point=thief.global_position
	var point:Vector2=pending_bag.point
	if not combat.root.graph.is_walkable(point):finalize_bag("회수 위치 부재");return
	if carrier.global_position.distance_to(point)<=carrier.PATH_POINT_REACHED_RADIUS and room(carrier)==combat.crown_mobility.room_of_point(point):_recover_bag()
func _recover_bag()->void:
	if pending_bag.is_empty() or str(pending_bag.loss.status)!="held":return
	var claim:Dictionary=pending_bag;var loss:Dictionary=claim.loss
	var stop_bag_path:bool=bool(claim.get("path_owned",false)) and bag_owns(claim.carrier)
	var result:Dictionary=Popo.arrive_at_thief(bag_state,str(loss.owner_id))
	if not bool(result.get("recovered",false)):return
	# Refund the exact debit into CURRENT stock. Never restore an old snapshot.
	var council:Dictionary=council_stock();var key:String=str(loss.kind);council[key]=int(council.get(key,0))+int(loss.amount)
	combat.root.update4_active_run.council_season=council;loss.status="recovered";bag_state=result.state;pending_bag={}
	var carrier=claim.carrier
	if alive(carrier):
		combat.root.support_mastery.record_support(carrier,"bag_recovery",int(loss.amount))
		if stop_bag_path:carrier.stop_navigation()
		combat.root._record_monster_contribution(str(carrier.unit_id),"messenger_bag_actual_resource_recovered",int(loss.amount))
		combat.root._record_monster_contribution(str(carrier.unit_id),"facility_value",int(loss.amount))
		combat.spawn_effect_burst("fx_popo_relay",carrier.global_position,Vector2.ZERO,Vector2.ONE,11)
	_count("native_bag_recoveries",1);SignalBus.resources_changed.emit()
	combat.root._log("전령 가방 실제 도달 · %s %d 회수, 같은 손실 재환불 없음."%[_resource_name(key),int(loss.amount)])
func finalize_bag(reason:String)->void:
	if pending_bag.is_empty():return
	var claim:Dictionary=pending_bag
	var stop_bag_path:bool=bool(claim.get("path_owned",false)) and bag_owns(claim.carrier)
	pending_bag={}
	if str(claim.loss.status)=="held":claim.loss.status="final";bag_state.pending={};bag_state.finalized_losses=int(bag_state.get("finalized_losses",0))+1;_count("native_bag_finalized",1)
	if alive(claim.carrier) and stop_bag_path:claim.carrier.stop_navigation()
	combat.root._log("전령 가방 · %s, 이미 차감한 손실 확정(추가 차감0)."%reason)
func before_result()->void:
	finalize_bag("전투 종료")
	# These are council objectives. A migrated/current legacy campaign must not
	# receive Update 4 run data merely because any defense has ended.
	if not combat.root._update4_council_mode_active():return
	var run_metrics:Dictionary=combat.root.update4_active_run.get("run_metrics_update4",{})
	run_metrics.native_1f_objectives={"adapter":"actual_1F","metrics":metrics.duplicate(true),"losses":losses.duplicate(true)}
	combat.root.update4_active_run.run_metrics_update4=run_metrics
func status(unit)->String:
	if not is_instance_valid(unit):return ""
	var parts:Array[String]=[];var entry:Dictionary=channels.get(unit.get_instance_id(),{})
	if not entry.is_empty() and str(entry.phase) in ["channel","retry"]:
		parts.append(combat.root.continuity.localized("1층 의회 수거","1F council collection","1层议会收取")+" %.1fs"%_remaining(entry))
		if str(entry.phase)=="retry":parts.append(combat.root.continuity.localized("피격 재시도","Hit retry","受击重试")+" %.1fs"%float(entry.state.get("retry_remaining",0)))
		if incoming_factor(unit)>1:parts.append(combat.root.continuity.localized("받는 피해+25%","Incoming damage+25%","受到伤害+25%"))
	if concealed(unit):parts.append(combat.root.continuity.localized("잠행","Concealed","潜行") if not targetable(unit) else combat.root.continuity.localized("잠행 탐지","Concealment detected","潜行被发现"))
	if attack_factor(unit)>1:parts.append(combat.root.continuity.localized("급습 공격+20%·방어-25%","Ambush ATK+20%·DEF-25%","突袭攻击+20%·防御-25%"))
	if not pending_bag.is_empty() and (pending_bag.carrier==unit or pending_bag.thief==unit):
		parts.append(combat.root.continuity.localized("봉투 회수 대기","Envelope recovery pending","信封等待回收")+" %.1fs"%maxf(0,float(pending_bag.ends)-clock()))
	return " · ".join(parts)
func clear()->void:
	finalize_bag("전투 이탈")
	for entry in shadows.values():
		if alive(entry.unit) and bool(entry.alpha_owned):
			var value:Color=entry.unit.modulate;value.a=float(entry.original_alpha);entry.unit.modulate=value
	channels.clear();gold_channels.clear();shadows.clear();losses.clear();pending_bag={};bag_state=Popo.new_bag_state();loss_claimed=false;metrics.clear();generation+=1
