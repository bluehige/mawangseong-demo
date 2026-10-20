extends RefCounted
const Crown=preload("res://scripts/systems/crown/CrownEvolutionService.gd")
const PYNN:="crown_pynn_castle_flame_sage"
var _combat_ref:WeakRef
var combat:
	get:return _combat_ref.get_ref() if _combat_ref!=null else null
var histories:Dictionary={}
var selections:Dictionary={}
var curses:Dictionary={}
var contributions:Dictionary={}
func setup(controller)->void:_combat_ref=weakref(controller)
func active(unit:Node)->bool:
	return is_instance_valid(unit) and not unit.is_queued_for_deletion() and unit.is_alive() and combat._active_crown_id(unit)==PYNN
func available(unit:Node)->bool:return active(unit) and int(unit.get_meta("tricolor_uses",0))<int(DataRegistry.skill("tricolor_demonfire").get("uses_per_battle",2))
func history(unit:Node)->Array:return histories.get(unit.get_instance_id(),[]).duplicate()
func mode(unit:Node)->String:return str(selections.get(unit.get_instance_id(),"single_flame"))
func set_mode(unit:Node,value:String)->void:
	if not is_instance_valid(unit) or value not in DataRegistry.skill("tricolor_demonfire").get("modes",[]):return
	selections[unit.get_instance_id()]=value
func mode_name(value:String)->String:
	match value:
		"single_flame":return combat.root.continuity.localized("단일","Single","单体")
		"area_flame":return combat.root.continuity.localized("광역","Area","范围")
		"ember_curse":return combat.root.continuity.localized("저주","Curse","诅咒")
	return ""
func quote(unit:Node,value:String)->Dictionary:
	var raw:Dictionary=Crown.pynn_ember_cost(history(unit),value,DataRegistry.skill("tricolor_demonfire"))
	if not bool(raw.get("ok",false)):return {}
	var skill:Dictionary=DataRegistry.skill("tricolor_demonfire").duplicate(true);skill.cost_mana=int(raw.mana_cost)
	return {"cost":combat.root._current_skill_mana_cost(skill,unit),"before_efficiency":combat.root._current_skill_mana_cost(skill),"reason":raw.reason}
func single_target(unit:Node)->Node:
	return combat._combat_action_target(unit,combat.root.enemy_units,320.0+combat._combat_skill_float(str(unit.unit_id),"fireball","range_bonus",0))
func area_targets()->Array:
	return combat._flame_zone_targets().filter(func(target):return is_instance_valid(target) and not target.is_queued_for_deletion())
func auto_mode(unit:Node)->String:
	if not available(unit):return ""
	var target:Node=single_target(unit);var recent:Array=history(unit)
	if target!=null and recent.size()>=2 and str(recent[-1])!=str(recent[-2]) and "ember_curse" not in recent and def_penalty(target)==0 and useful_curse(unit,target):return "ember_curse"
	if area_targets().filter(func(enemy):return enemy.is_targetable_by(unit)).size()>=2:return "area_flame"
	return "single_flame" if target!=null else ""
func useful_curse(unit:Node,target:Node)->bool:
	if target.effective_def()>0:return true
	var effect:Dictionary=Crown.pynn_tricolor_fire("ember_curse",combat.crown_mobility.source_evolution(unit),true)
	var duration:float=target._hostile_status_duration(2.5*float(effect.debuff_duration_multiplier))
	if target.heart_first_control_available and target.heart_first_control_multiplier>1:duration*=target.heart_first_control_multiplier
	return target.move_speed>0 and not bool(target.get_meta("fixed",false)) and maxf(target.seal_move_lock_timer,target.duo_move_lock_timer)<duration and (target.slow_factor>.70 or target.slow_timer<duration)
func prepare(unit:Node,value:String)->Dictionary:
	if not available(unit):return {}
	var skill:Dictionary=DataRegistry.skill("tricolor_demonfire")
	if value not in skill.modes:return {}
	var targets:Array=area_targets() if value=="area_flame" else []
	var target:Node=single_target(unit) if value!="area_flame" else (targets[0] if not targets.is_empty() else null)
	if target==null:return {}
	return {"mode":value,"automatic":false,"source":combat.crown_mobility.source_evolution(unit,true),"history":history(unit),"quote":quote(unit,value),"target":target,"targets":targets}
func valid(unit:Node,plan:Dictionary,target:Node)->bool:
	if not available(unit) or str(plan.get("source",""))!=combat.crown_mobility.source_evolution(unit) or plan.get("history",[])!=history(unit) or plan.get("quote",{})!=quote(unit,str(plan.get("mode",""))):return false
	if not bool(plan.get("automatic",false)) and mode(unit)!=str(plan.mode):return false
	if str(plan.mode)=="area_flame":return not valid_area(plan.get("targets",[])).is_empty()
	return is_instance_valid(target) and not target.is_queued_for_deletion() and target.is_alive() and target.global_position.distance_to(unit.global_position)<=320.0+combat._combat_skill_float(str(unit.unit_id),"fireball","range_bonus",0)
func valid_area(targets:Array)->Array:
	var actual:Array=area_targets()
	return targets.filter(func(target):return is_instance_valid(target) and actual.has(target) and target.is_alive())
func record_cast(unit:Node,value:String)->void:
	if not active(unit):return
	var recent:Array=history(unit);recent.append(value)
	if recent.size()>3:recent=recent.slice(recent.size()-3)
	histories[unit.get_instance_id()]=recent
func ordinary_cast(unit:Node,skill_id:String,cost:int)->void:
	if not active(unit):return
	if skill_id=="fireball":record_cast(unit,"single_flame")
	elif skill_id=="flame_zone":record_cast(unit,"area_flame")
	_record(unit,"pynn_mana_efficiency_saved",maxi(0,combat.root._current_skill_mana_cost(DataRegistry.skill(skill_id))-cost))
func cast(unit:Node,target:Node,plan:Dictionary)->void:
	var value:String=plan.mode;var effect:Dictionary=Crown.pynn_tricolor_fire(value,str(plan.source),true)
	unit.set_meta("tricolor_uses",int(unit.get_meta("tricolor_uses",0))+1)
	var count:=0
	if value=="single_flame":
		var raw:float=52+combat._combat_skill_float(str(unit.unit_id),"fireball","damage_bonus",0)
		var damage:int=combat._apply_v122_focus_damage(unit,target,roundi(raw*float(effect.direct_damage_multiplier)))
		unit.play_attack(target.global_position);unit.play_skill_visual(target.global_position)
		combat._launch_damage_projectile(unit,target,damage,true,"fireball")
		count=1
	elif value=="area_flame":
		var token:="tricolor_area:%d:%d"%[unit.get_instance_id(),int(unit.get_meta("tricolor_uses",0))]
		var raw:float=34+combat._combat_skill_float(str(unit.unit_id),"flame_zone","damage_bonus",0)
		var damage:int=roundi(raw*float(effect.area_damage_multiplier))
		var slow:float=2.5+combat._combat_skill_float(str(unit.unit_id),"flame_zone","slow_seconds_bonus",0)
		var factor:float=maxf(.4,.7-combat._combat_skill_float(str(unit.unit_id),"flame_zone","slow_factor_bonus",0))
		combat.single_floor_support.fire_hit(unit.global_position,unit.global_position,["spike_corridor",combat._barracks_room()],token)
		for enemy in valid_area(plan.targets):
			var before:int=enemy.hp;var requested:int=combat._apply_v122_focus_damage(unit,enemy,damage)
			var dealt:int=enemy.receive_magic_damage(requested)
			combat._record_damage_contribution(unit,enemy,requested,dealt,before,"",token)
			enemy.mark_threat(unit);enemy.apply_slow(slow,factor);combat._apply_combat_hit_feedback(unit,enemy,dealt,count==0,"area");count+=1
		unit.play_skill()
	elif value=="ember_curse":
		apply_curse(unit,target,float(effect.debuff_duration_multiplier));unit.play_skill(target.global_position);count=1
	combat.root.play_update4_crown_vfx(PYNN,unit.global_position)
	combat.root._play_update4_crown_sfx(PYNN,"tricolor:%d:%d"%[unit.get_instance_id(),int(unit.get_meta("tricolor_uses",0))])
	unit.set_meta("tricolor_result",{"mode":value,"count":count,"cost":int(plan.quote.cost)})
	_record(unit,"pynn_mana_efficiency_saved",maxi(0,int(plan.quote.before_efficiency)-int(plan.quote.cost)))
	record_cast(unit,value)
	combat.root._log("삼색 마왕화 · %s · 마나 %d · %d명 · 전투 %d/2회"%[mode_name(value),int(plan.quote.cost),count,int(unit.get_meta("tricolor_uses",0))])
func boss(target:Node)->bool:
	return combat._bebe_broom_boss(target) or DataRegistry.update4_rival_bosses.has(str(target.unit_id)) or "boss" in DataRegistry.enemy(str(target.unit_id)).get("tags",[])
func apply_curse(unit:Node,target:Node,multiplier:float)->void:
	var key:="royal_ember:%d:%d"%[unit.get_instance_id(),target.get_instance_id()]
	var previous:Dictionary=curses.get(key,{})
	var defense:int=1 if boss(target) else 2
	var defense_seconds:float=target._hostile_status_duration((4.0 if boss(target) else 5.0)*multiplier)
	var slow_seconds:float=target._heart_control_duration(2.5*multiplier)
	curses[key]={"source":unit,"target":target,"defense":maxi(defense,int(previous.get("defense",0))),"def_ends":maxf(float(combat.root.combat_time)+defense_seconds,float(previous.get("def_ends",0))),"slow_ends":maxf(float(combat.root.combat_time)+slow_seconds,float(previous.get("slow_ends",0)))}
	target.crown_ember_sources[key]=unit.get_instance_id()
	combat.spawn_effect_burst("imp_ember_shaman",target.global_position,Vector2.ZERO,Vector2.ONE,11)
	_record(unit,"royal_ember_curse_applications",1)
func validate_curses(target:Node)->void:
	for key in target.crown_ember_sources.keys():
		if not curses.has(key) or curses[key].target!=target or not active(curses[key].source) or target.is_queued_for_deletion() or not target.is_alive() or float(combat.root.combat_time)>=maxf(float(curses[key].def_ends),float(curses[key].slow_ends)):
			target.crown_ember_sources.erase(key)
			if curses.has(key) and curses[key].target==target:curses.erase(key)
func def_penalty(target:Node)->int:
	validate_curses(target);var amount:=0
	for key in target.crown_ember_sources:
		if float(combat.root.combat_time)<float(curses[key].def_ends):amount=maxi(amount,int(curses[key].defense))
	return amount
func slow_factor(target:Node)->float:
	validate_curses(target)
	for key in target.crown_ember_sources:
		if float(combat.root.combat_time)<float(curses[key].slow_ends):return .70
	return 1.0
func tick()->void:
	for key in curses.keys():
		if not curses.has(key):continue
		var target=curses[key].target
		if not is_instance_valid(target):curses.erase(key);continue
		validate_curses(target)
func caption(unit:Node)->String:
	var result:Dictionary=unit.get_meta("tricolor_result",{})
	var value:String=str(result.get("mode",""));var cost:int=int(result.get("cost",0))
	var text:String=combat.root.continuity.localized("투사체 발사 · 도착 시 피해","Projectile launched · Damage on arrival","发射弹体 · 到达时伤害") if value=="single_flame" else combat.root.continuity.localized("광역 명중","Area contact","范围命中") if value=="area_flame" else combat.root.continuity.localized("잿불 저주 · 방어 약화·둔화","Ember curse · DEF down and slow","余烬诅咒 · 防御削弱·减速")
	return text+" · "+combat.root.continuity.localized("마나","Mana","魔力")+" %d"%cost
func _record(unit:Node,key:String,amount:float)->void:
	if amount<=0:return
	var counter:Dictionary=contributions.get(unit.get_instance_id(),{});counter[key]=float(counter.get(key,0))+amount;contributions[unit.get_instance_id()]=counter
	combat.root._record_monster_contribution(str(unit.unit_id),key,amount)
func clear()->void:
	for key in curses.keys():
		if is_instance_valid(curses[key].target):curses[key].target.crown_ember_sources.erase(key)
	curses.clear();histories.clear();selections.clear();contributions.clear()
