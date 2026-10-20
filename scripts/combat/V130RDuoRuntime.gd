extends RefCounted
## All links share the existing unlock, gauge, deduplication and one-use policy.
const Service = preload("res://scripts/systems/duo_links/DuoLinkService.gd")
var controller_ref: WeakRef
var game: Node:
	get: return controller_ref.get_ref().root
var activations: Array = []
var hp_before: Dictionary = {}
var sequence := 0
var sources: Dictionary = {}

func setup(controller: RefCounted) -> void:
	controller_ref = weakref(controller); activations.clear(); hp_before.clear()
	sources.clear()
	for definition in DataRegistry.update3_duo_links.values():
		for source in definition.get("gauge_sources",[]): sources[str(source.member_instance_id)+":"+str(source.source_id)] = true
	game._prepare_update3_duo_link_battle()
	game.update3_active_run["duo_activation_events"] = []
	for unit in game.monster_units: hp_before[unit.get_instance_id()] = unit.hp

func action(unit: Node, source: String, amount: int = 1) -> void:
	var member: String = game._update3_unit_instance_id(unit)
	# Unregistered events cannot change role progress or any gauge. Avoid copying
	# the growing run metrics for those frequent observations.
	if not sources.has(member+":"+source): return
	sequence += 1
	game._record_update3_duo_link_action(member,source,amount,"v130r:%d:%d:%s" % [unit.get_instance_id(),sequence,source])

func skill(unit: Node, skill_id: String) -> void:
	action(unit,"skill_used")
	# Fire hits and beetle repair/break events already report actual outcomes
	# through the existing controller; a cast must not charge them a second time.
	game.v130r_story.bark(game,unit,"skill_used")

func hit(attacker: Node, target: Node, applied: bool) -> void:
	if not applied or attacker.faction!="monster": return
	game.v130r_story.bark(game,attacker,"engagement_started")
	if not target.is_alive(): action(attacker,"finisher")
	# Fixed attacks and marked hits already report their sources in the base controller.

func tick(delta: float) -> void:
	for unit in game.monster_units:
		if not unit.is_alive(): continue
		var previous: int = int(hp_before.get(unit.get_instance_id(),unit.hp))
		if unit.hp<previous:
			action(unit,"damage_absorbed",previous-unit.hp)
			if unit.guard_timer>0 or unit.shield_timer>0: action(unit,"guard_or_block")
		if unit.hp<=unit.max_hp*.3: game.v130r_story.bark(game,unit,"hp_below_30")
		hp_before[unit.get_instance_id()] = unit.hp
	game._update3_duo_link_effects(delta/maxf(.01,game.combat_speed))
	game.v130r_story.tick_barks(game,delta)
	if bool(game.update3_active_run.get("duo_link_auto_use",false)):
		for id in game.update3_active_run.get("equipped_duo_links",[]):
			if game.update3_active_run.get("duo_link_states",{}).get(id,{}).get("ready",false): activate(str(id))

func activate(id: String) -> bool:
	if not controller_ref.get_ref().running or game.combat_paused: return false
	var definition: Dictionary = DataRegistry.update3_duo_links.get(id,{})
	var members: Array = []
	for member_id in definition.get("member_instance_ids",[]):
		var actor = game._update3_duo_member_unit(str(member_id))
		if not is_instance_valid(actor) or not actor.is_alive() or actor.active_skills_locked() or actor.duo_action_locked(): return false
		members.append(actor)
	if members.size()!=2: return false
	if str(definition.get("effect_handler","")).begins_with("v130r_") and int(definition.effect.get("max_targets",0))>0:
		var in_range := false
		for enemy in game.enemy_units:
			if is_instance_valid(enemy) and enemy.is_alive() and game._duo_enemy_targetable(enemy,members) and minf(enemy.global_position.distance_to(members[0].global_position),enemy.global_position.distance_to(members[1].global_position))<=float(definition.effect.get("radius",190)): in_range = true
		if not in_range: return false
	var target = game._prepared_duo_action_target(id,members)
	if definition.get("effect_handler","") in ["molten_carapace","moon_scent_hunt"] and target==null: return false
	if not game._commit_prepared_duo(id,members,target,target.get_instance_id() if target!=null else 0): return false
	activations.append({"link_id":id,"time":game.combat_time,"members":definition.member_instance_ids.duplicate()})
	game.update3_active_run["duo_activation_events"] = activations.duplicate(true)
	return true

func apply(id: String, members: Array) -> Dictionary:
	var definition: Dictionary = DataRegistry.update3_duo_links[id]
	var effect: Dictionary = definition.effect
	var center: Vector2 = (members[0].global_position+members[1].global_position)*.5
	var candidates: Array = []
	for enemy in game.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive(): continue
		# Work around either partner, even when they guard different lines.
		if minf(enemy.global_position.distance_to(members[0].global_position),enemy.global_position.distance_to(members[1].global_position))>float(effect.get("radius",190)): continue
		if not game._duo_enemy_targetable(enemy,members): continue
		candidates.append(enemy)
	candidates.sort_custom(func(a,b): return a.global_position.distance_squared_to(center)<b.global_position.distance_squared_to(center))
	var hits := 0; var shields := 0; var healed := 0; var recovered := 0
	for enemy in candidates.slice(0,int(effect.get("max_targets",0))):
		if effect.has("root_seconds"): enemy.apply_root(float(effect.root_seconds))
		if effect.has("slow_seconds"): enemy.apply_slow(float(effect.slow_seconds),float(effect.slow_factor))
		if effect.has("mark_seconds"): enemy.apply_duo_mark(float(effect.mark_seconds),str(definition.member_instance_ids[0]))
		if effect.has("damage"):
			var before: int = enemy.hp
			enemy.incoming_source = members[0]; enemy.incoming_area = true
			var dealt: int = enemy.receive_damage(int(effect.damage))
			game.combat_scene._apply_combat_hit_feedback(members[0],enemy,dealt,false,"area")
			game.combat_scene._record_damage_contribution(members[0],enemy,int(effect.damage),dealt,before,"",id+":"+str(enemy.get_instance_id()))
		if effect.has("morale_damage"): enemy.receive_morale_damage(int(effect.morale_damage))
		if effect.has("recover_fraction"): recovered += game.combat_scene.monster_skills.recover_gold(enemy,float(effect.recover_fraction))
		hits += 1
	for ally in game.monster_units:
		if not is_instance_valid(ally) or not ally.is_alive() or minf(ally.global_position.distance_to(members[0].global_position),ally.global_position.distance_to(members[1].global_position))>float(effect.get("radius",190)): continue
		if effect.has("shield"):
			ally.grant_duo_barrier(int(effect.shield)); shields += int(effect.shield)
		if effect.has("def_bonus"): ally.activate_guard(float(effect.duration),int(effect.def_bonus))
		if effect.has("heal"):
			var before: int = ally.hp
			ally.heal(int(effect.heal),id)
			healed += ally.hp-before
			ally.cleanse_one_negative_status()
	for member in members:
		member.play_skill(); member.apply_duo_action_lock(.6)
	var effect_art := "guard"
	if definition.effect_handler in ["v130r_web_bridge","v130r_sewn_bond"]: effect_art = "fx_silky_thread"
	elif definition.effect_handler in ["v130r_slippery_flame","v130r_candle_ember"]: effect_art = "impact"
	elif effect.has("damage"): effect_art = "hit_slash"
	game.combat_scene.spawn_effect_burst(effect_art,center,Vector2(0,-12),Vector2(1.5,1.5),14.0)
	var evidence := {"link_id":id,"hits":hits,"shield":shields,"heal":healed,"gold_recovered":recovered}
	game.set_meta("v130r_last_duo_effect",evidence)
	game._log(LanguageSettings.ui_text(str(definition.display_name)))
	return evidence
