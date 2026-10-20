extends RefCounted

const Objective = preload("res://scripts/systems/council/CouncilObjectiveService.gd")
const Constants = preload("res://scripts/core/Constants.gd")
var _combat_ref: WeakRef
var combat:
	get: return _combat_ref.get_ref() if _combat_ref != null else null
var alerted := {}
var alert_voices: Array[String] = []
var spawned := 0
func setup(controller) -> void: _combat_ref = weakref(controller)
func active() -> bool:
	return combat.root._update4_council_mode_active() and bool(combat.root.update4_active_run.get("expansion",{}).get("unlocked",false))
func crown_room() -> String:
	return str(combat.root.update4_active_run.get("expansion",{}).get("rooms",{}).get("crown_sanctum",""))
func spawn(unit) -> void:
	if not active() or GameState.day == 17 or str(unit.unit_id) in ["dusk_courier","shadow_duelist","rival_vesper_council_champion"]: return
	spawned += 1
	# Distribute existing enemies between throne and auxiliary target, never add waves.
	if spawned % 2 == 0 and GameState.day not in [18,27]: return
	var destination := crown_room()
	if destination == "" or bool(combat.root.update4_active_run.expansion.get("crown_suppressed",false)): return
	var route: Array = combat.crown_mobility.safe_route(unit.global_position,combat.root.graph.center(destination))
	if route.is_empty(): return
	unit.set_meta("council_crown_target",true)
	unit.goal_room = destination; unit.set_path(route)
func tick(_delta: float) -> void:
	if not active(): return
	var destination := crown_room()
	for enemy in combat.root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive() or not bool(enemy.get_meta("council_crown_target",false)): continue
		if bool(combat.root.update4_active_run.expansion.get("crown_suppressed",false)):
			enemy.remove_meta("council_crown_target"); enemy.goal_room = combat._core_room(); enemy.set_path(combat._path_from_world_to_room(enemy.global_position,enemy.goal_room)); continue
		if combat.crown_mobility.room_of(enemy) != destination: continue
		alert(destination)
		if enemy.attack_cooldown > 0 or enemy.action_interrupt_timer > 0 or enemy.tactical_state == Constants.UNIT_STATE_STUNNED: continue
		if combat.nearest_monster_in_rooms(enemy,[destination]) != null: continue
		var damage := maxi(0,int(enemy.atk))
		if destination == "crown_sanctum":
			var applied: Dictionary = combat.root._damage_update3_facility(destination,damage,"crown:%d:%d" % [enemy.get_instance_id(),Time.get_ticks_usec()])
			damage = int(applied.get("actual_hp_loss",0))
		var hit := Objective.damage_crown_sanctum(combat.root.update4_active_run,damage)
		combat.root.update4_active_run = hit.active_run
		enemy.attack_cooldown = enemy.effective_attack_interval()
		enemy.set_tactical_state(Constants.UNIT_STATE_ATTACK,combat.root.continuity.localized("왕관실 압박","Crown Chamber pressure","王冠室压制"))
		if hit.destroyed: combat.root._log(combat.root.continuity.localized("왕관실 무력화 · 이번 전투 왕관 기능 억제","Crown Chamber disabled · crown powers suppressed this battle","王冠室失效 · 本场战斗王冠功能停用"))
func alert(room: String) -> void:
	if alerted.has(room): return
	alerted[room] = true
	var settings: Dictionary = combat.root.update4_profile.get("chronicle_update4",{}).get("accessibility",{})
	combat.root._log(combat.root.continuity.localized("목표 구역 침입: ","Objective district intrusion: ","目标区域遭到入侵：")+combat._room_name(room))
	if combat.root.audio_director != null:
		var volume := float(settings.get("objective_alert_volume",0.8))
		if volume > 0:
			var result: Dictionary = combat.root.audio_director.play_event("update4.floor_intrusion.alarm",linear_to_db(volume),"sfx",-1,"","objective:"+room)
			if bool(result.get("accepted",false)): alert_voices.append(str(result.get("voice_id","")))
func clear() -> void:
	if combat != null and combat.root.audio_director != null:
		for voice in alert_voices: combat.root.audio_director.stop_voice(voice)
	alert_voices.clear(); alerted.clear(); spawned = 0
