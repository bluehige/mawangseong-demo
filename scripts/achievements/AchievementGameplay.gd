extends RefCounted
## Hooks observe successful effects; they never change battle results or resources.
static func begin(battle: RefCounted) -> Dictionary:
	AchievementService.battle_throne_damage = 0
	return {"throne_hp":GameState.demon_lord_hp,"speed_x3":is_equal_approx(battle.root.combat_speed,3.0),"facility_disabled":0,"pudding_blocked":0,"leon":GameState.day == 30,"final_lines":{},"boss_kills":{}}

static func tick(battle: RefCounted) -> void:
	if not is_equal_approx(battle.root.combat_speed,3.0): battle.achievement_state.speed_x3 = false
	for enemy in battle.root.enemy_units:
		if enemy.is_alive() and enemy.goal_room == "throne" and enemy.position.distance_to(battle.goal_point(enemy)) < 18:
			battle.achievement_state.final_lines[str(enemy.get_meta("route_id","unknown"))] = true

static func finish(battle: RefCounted, win: bool) -> void:
	var service := AchievementService
	var hungry := 0; var armor := false
	for unit in battle.root.monster_units:
		if unit.get_meta("food_hungry",false): hungry += 1
		if unit.unit_id == "hollow_armor" and unit.is_alive() and bool(unit.get_meta("ach_reassembled",false)): armor = true
	service.note_hunger(GameState.day,hungry > 0 or not GameState.food_state.get("hungry",[]).is_empty())
	if not win: service.run.defeats = int(service.run.get("defeats",0))+1
	service.remember_run()
	var buildings := {}; var full: bool = not battle.assignments.is_empty()
	for assignment in battle.assignments.values(): buildings[str(assignment.building)] = true
	for building in battle.view.placement.buildings:
		var capacity := int(building.get("capacity",0))
		if capacity <= 0: continue
		var used := 0
		for assignment in battle.assignments.values():
			if assignment.building == building.id: used += 1
		if used < capacity: full = false
	var c_grade: bool = battle.view.placement.grade == "C"
	var held: bool = battle.achievement_state.final_lines.is_empty()
	battle.achievement_state.full_house = full
	service.record("battle_finished",{"win":win,"day":GameState.day,"thief_day":battle.root.thieves_spawned_this_battle > 0,"vault_loss":battle.root.treasure_gold_stolen_this_battle,"castle_stage":int(battle.view.placement.stage),"grade":battle.view.placement.grade,"throne_damage":service.battle_throne_damage,"facility_disabled":int(battle.achievement_state.facility_disabled),"slots_full":full,"hungry_units":hungry,"all_units_one_building":buildings.size() == 1,"leon_battle":bool(battle.achievement_state.leon),"armor_reassembled_alive":armor,"both_final_lines_held":c_grade and held,"gate_bridge_held":c_grade and held,"speed_always_x3":bool(battle.achievement_state.speed_x3),"previous_settlement_zero_food":bool(service.run.get("zero_food",false))})

static func settlement(game: Node) -> void:
	AchievementService.record("settlement",{"gold":GameState.gold})
	AchievementService.run.zero_food = GameState.food == 0
	AchievementService.observe_game(game)
	AchievementService.persist()
	AchievementService.flush()

static func construction(before: Dictionary, after: Dictionary, kind: String, moving: String) -> void:
	if moving != "":
		for old in before.buildings:
			if old.id != moving: continue
			for next in after.buildings:
				if next.id == moving and next.rect.position != old.rect.position: AchievementService.count("STAT_BUILDING_MOVES")
	elif kind in ["spikes","sticky"]:
		if after.traps.size() > before.traps.size(): AchievementService.count("STAT_TRAPS_PLACED")
	elif after.buildings.size() > before.buildings.size():
		AchievementService.run.buildings_built = int(AchievementService.run.get("buildings_built",0))+1
	var types := {}; var maximum := false
	for building in after.buildings:
		if building.fixed: continue
		types[building.kind] = true
		maximum = maximum or int(building.get("level",1)) >= int(preload("res://scripts/map_builder/ApprovedPlacement.gd").stage_rule(after).get("facility_level_cap",2))
	AchievementService.record("construction",{"buildings_built":int(AchievementService.run.get("buildings_built",0)),"built_types":types.size(),"building_level_max":maximum})

static func damage(battle: RefCounted, attacker: Node, target: Node, hp_before: int, _incoming: int, _dealt: int, attacker_id: String = "") -> void:
	if not is_instance_valid(target): return
	var id := str(attacker.unit_id) if is_instance_valid(attacker) else attacker_id
	if target.faction == "enemy" and hp_before > 0 and not target.is_alive():
		if id == "goblin" and ("thief" in str(target.unit_id) or str(target.get_meta("goal_type","")) == "treasure"): AchievementService.count("STAT_GOB_THIEF")
		if bool(DataRegistry.enemies.get(target.unit_id,{}).get("boss",false)) or "leon" in str(target.unit_id) or "selen" in str(target.unit_id) or "roman" in str(target.unit_id):
			var boss: String = "roman" if "roman" in str(target.unit_id) else str(target.unit_id)
			var direct: bool = battle.direct_unit == attacker if battle.has_method("issue_command") else false
			AchievementService.record("boss_defeated",{"boss":boss,"direct_control":direct and is_instance_valid(attacker)})

static func read_line(id: String, speaker: String) -> void:
	# Called when a displayed line is consumed, never by a UI redraw. Re-reading
	# the same sentence is a new display event; the design does not require 100 IDs.
	if id != "" and speaker in ["CHR_BATI","CHR_BATI_ADVISOR","bati"]: AchievementService.count("STAT_BATI_LINES")

static func scene_completed(id: String, skipped: bool = false) -> void:
	if skipped: return
	var facts := {}
	if id == "STORY_D01_MANAGEMENT_ENTRY": facts.leak_complete = true
	if id.to_lower().contains("join"):
		facts.join_scene_seen = 1
		if id.to_lower().contains("river_frog"): facts.join_species = "river_frog"
	AchievementService.record("dialogue_completed",facts)
