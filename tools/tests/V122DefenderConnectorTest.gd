extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const UnitActor = preload("res://scripts/units/Unit.gd")
const LAYOUT_ID := "stage01_dual_front_candidate_01"
const LAYOUT_PATH := "res://data/dungeon_quarter/layouts/stage01_dual_front_01.json"

var failed := false


class FactionUnit:
	extends Node

	var faction := ""


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	_expect(layout is Dictionary, "candidate layout fixture loads")
	if not layout is Dictionary:
		_finish()
		return
	var game := GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game.campaign_save_enabled = false
	game._debug_skip_onboarding()
	DataRegistry.register_quarter_layout(LAYOUT_ID, layout, false)
	game.quarter_layout_id = LAYOUT_ID
	game._setup_dungeon_graph()
	game.current_screen = Constants.SCREEN_MANAGEMENT

	GameState.day = 2
	GameState.gold = 1200
	GameState.mana = 150
	_expect(not game._v122_can_build_defender_connector(), "connector cannot be built before DAY 3")
	_expect(not game._build_v122_defender_connector(), "locked connector rejects construction")
	_expect(GameState.gold == 1200 and GameState.mana == 150, "locked construction spends no resources")

	GameState.day = 3
	_expect(game._v122_can_build_defender_connector(), "connector becomes purchasable on DAY 3")
	_expect(game._build_v122_defender_connector(), "DAY 3 connector construction succeeds")
	_expect(GameState.gold == 200 and GameState.mana == 50, "construction spends exactly 1000 gold and 100 mana")
	_expect(
		bool(game.v122_connector_state.get("built", false))
			and int(game.v122_connector_state.get("built_day", 0)) == 3,
		"runtime records permanent construction state"
	)
	_expect(
		bool(game._v122_current_battle_plan().get("defender_connector", {}).get("built", false)),
		"current battle plan consumes the built state"
	)
	var connector: Dictionary = game._v122_current_battle_plan().get("defender_connector", {})
	var anchor_value: Array = connector.get("world_anchor", [])
	var connector_anchor := Vector2(float(anchor_value[0]), float(anchor_value[1]))
	var defender := FactionUnit.new()
	defender.faction = Constants.FACTION_MONSTER
	game.add_child(defender)
	var enemy := FactionUnit.new()
	enemy.faction = Constants.FACTION_ENEMY
	game.add_child(enemy)
	_expect(not game.graph.is_walkable(connector_anchor), "connector center remains outside the shared enemy walk map")
	_expect(
		game._clamp_unit_to_combat_walkable(connector_anchor, defender) == connector_anchor,
		"built connector grants its crossing width to defenders"
	)
	_expect(
		game._clamp_unit_to_combat_walkable(connector_anchor, enemy) != connector_anchor,
		"enemy floor clamping still rejects the connector"
	)
	var runtime_defender = UnitActor.new()
	runtime_defender.faction = Constants.FACTION_MONSTER
	runtime_defender.set_physics_process(false)
	game.add_child(runtime_defender)
	runtime_defender.set_path([connector_anchor])
	_expect(
		runtime_defender.path_points.has(connector_anchor),
		"the real unit path setter preserves the defender crossing anchor"
	)
	var runtime_enemy = UnitActor.new()
	runtime_enemy.faction = Constants.FACTION_ENEMY
	runtime_enemy.set_physics_process(false)
	game.add_child(runtime_enemy)
	runtime_enemy.set_path([connector_anchor])
	_expect(
		not runtime_enemy.path_points.has(connector_anchor),
		"the real unit path setter clamps the same anchor away for enemies"
	)
	_check_room_directive_scope(game)
	_check_thief_hunter_combat_priority(game)
	_check_vault_guard_closes_to_intruder(game)
	_check_throne_attack_feedback(game)
	_expect(
		bool(game._v122_save_progression_payload().get("connector_state", {}).get("built", false)),
		"campaign save payload contains the built state"
	)
	_expect(not game._build_v122_defender_connector(), "permanent connector cannot be purchased twice")
	_expect(GameState.gold == 200 and GameState.mana == 50, "duplicate construction spends no resources")

	_expect(game._undo_last_management_placement(), "normal management undo can revert the latest construction")
	_expect(not bool(game.v122_connector_state.get("built", false)), "undo returns the connector to unbuilt")
	_expect(GameState.gold == 1200 and GameState.mana == 150, "undo refunds both construction resources")

	_expect(game._build_v122_defender_connector(), "connector can be rebuilt after undo")
	var confirmed_plan: Dictionary = game._v122_current_battle_plan()
	game._capture_v122_battle_confirmation(confirmed_plan)
	game.v122_connector_state = {
		"connector_id": "rear_cross_lane_connector",
		"built": false,
		"built_day": 0
	}
	game._apply_v122_retry_snapshot()
	_expect(
		bool(game.v122_connector_state.get("built", false)),
		"retry restores the last confirmed connector state"
	)

	game.queue_free()
	await _settle(2)
	_finish()


func _check_room_directive_scope(game: Node) -> void:
	var original_monsters: Array = game.monster_units.duplicate()
	var original_enemies: Array = game.enemy_units.duplicate()
	var original_directives: Dictionary = game.room_directives.duplicate(true)
	var original_global_directive: String = str(game.global_directive)
	var remote_room := "lane_b_front" if game.rooms.has("lane_b_front") else "service_entrance"
	var slime = game._create_unit("slime", DataRegistry.monster("slime"), Constants.FACTION_MONSTER, "entrance")
	var imp = game._create_unit("imp", DataRegistry.monster("imp"), Constants.FACTION_MONSTER, remote_room)
	var explorer = game._create_unit("explorer", DataRegistry.enemy("explorer"), Constants.FACTION_ENEMY, remote_room)
	for unit in [slime, imp, explorer]:
		unit.set_physics_process(false)
	slime.assigned_room = "entrance"
	slime.current_room = "entrance"
	slime.global_position = game.graph.center("entrance")
	imp.assigned_room = remote_room
	imp.current_room = remote_room
	imp.global_position = game.graph.center(remote_room)
	explorer.current_room = remote_room
	explorer.goal_room = "throne"
	explorer.global_position = game.graph.center(remote_room)
	game.monster_units = [slime, imp]
	game.enemy_units = [explorer]
	game.room_directives["entrance"] = Constants.ROOM_DIRECTIVE_ENTRY_BLOCK
	_expect(game.combat_scene._room_directive_active_for_unit(slime, "entrance", Constants.ROOM_DIRECTIVE_ENTRY_BLOCK), "entrance guard receives its local room directive")
	_expect(not game.combat_scene._room_directive_active_for_unit(imp, "entrance", Constants.ROOM_DIRECTIVE_ENTRY_BLOCK), "remote-lane imp ignores the entrance room directive")
	slime.stop_navigation()
	game.combat_scene.update_monster_path(slime)
	_expect(slime.intent_text == "입구 봉쇄", "entry-block directive resolves before autonomous role movement")
	game.room_directives["spike_corridor"] = Constants.ROOM_DIRECTIVE_TRAP_LURE
	_expect(not game.combat_scene._room_directive_active_for_unit(imp, "spike_corridor", Constants.ROOM_DIRECTIVE_TRAP_LURE), "remote-lane imp is not pulled into the legacy spike-corridor directive")
	imp.current_room = "spike_corridor"
	imp.global_position = game.graph.center("spike_corridor")
	imp.stop_navigation()
	game.combat_scene.update_monster_path(imp)
	_expect(imp.intent_text == "함정 뒤 화력 지원", "trap-lure directive resolves before autonomous support movement")
	imp.current_room = remote_room
	imp.global_position = game.graph.center(remote_room)
	imp.stop_navigation()
	game.global_directive = Constants.DIRECTIVE_DEFENSE
	_expect(game.combat_scene._defense_target(slime, explorer) == null, "defense doctrine does not chase a remote lane merely because a defender connector exists")
	game.room_directives["recovery"] = Constants.ROOM_DIRECTIVE_RETREAT
	imp.current_room = "recovery"
	imp.global_position = game.graph.center("recovery")
	imp.stop_navigation()
	game.combat_scene.update_monster_path(imp)
	_expect(imp.intent_text == "후퇴선 유지" and imp.path_points.is_empty(), "retreat line holds its room instead of repeatedly routing to recovery")
	game.monster_units = original_monsters
	game.enemy_units = original_enemies
	game.room_directives = original_directives
	game.global_directive = original_global_directive
	slime.queue_free()
	imp.queue_free()
	explorer.queue_free()


func _check_thief_hunter_combat_priority(game: Node) -> void:
	var gold_before := int(GameState.gold)
	var mana_before := int(GameState.mana)
	var roster_entry: Dictionary = game.monster_roster.get("goblin", {}).duplicate(true)
	roster_entry.erase("specialization_id")
	roster_entry["promotion_id"] = ""
	game.monster_roster["goblin"] = roster_entry
	_expect(game._monster_ai_behavior("goblin") == "thief_hunter", "base goblin uses the documented thief-hunter AI")
	var room_id: String = str(game._room_by_facility("treasure", ""))
	var center: Vector2 = game.graph.center(room_id)
	var goblin = game._create_unit("goblin", DataRegistry.monster("goblin"), Constants.FACTION_MONSTER, room_id)
	var explorer = game._create_unit("explorer", DataRegistry.enemy("explorer"), Constants.FACTION_ENEMY, room_id)
	var thief = game._create_unit("thief", DataRegistry.enemy("thief"), Constants.FACTION_ENEMY, room_id)
	for unit in [goblin, explorer, thief]:
		unit.set_physics_process(false)
		unit.current_room = room_id
	goblin.global_position = center
	explorer.global_position = center + Vector2(14.0, 0.0)
	thief.global_position = center + Vector2(minf(38.0, float(goblin.attack_range) - 4.0), 0.0)
	game.monster_units = [goblin]
	game.enemy_units = [explorer, thief]
	goblin.skill_cooldowns = {"quick_slash": 99.0, "loot_instinct": 99.0}
	goblin.attack_cooldown = 0.0
	var explorer_hp_before := int(explorer.hp)
	var thief_hp_before := int(thief.hp)
	game.combat_scene.try_attack(goblin, game.enemy_units)
	_expect(thief.hp < thief_hp_before and explorer.hp == explorer_hp_before, "thief hunter basic attack ignores a closer explorer")

	explorer.hp = explorer.max_hp
	thief.hp = thief.max_hp
	goblin.skill_cooldowns["quick_slash"] = 0.0
	GameState.mana = 100
	explorer_hp_before = int(explorer.hp)
	thief_hp_before = int(thief.hp)
	_expect(game.combat_scene.try_auto_monster_skill(goblin), "thief hunter can auto-cast quick slash")
	_expect(thief.hp < thief_hp_before and explorer.hp == explorer_hp_before, "thief hunter quick slash ignores a closer explorer")

	explorer.hp = explorer.max_hp
	thief.hp = thief.max_hp
	thief.global_position = center + Vector2(float(goblin.attack_range) + 70.0, 0.0)
	goblin.skill_cooldowns = {"quick_slash": 99.0, "loot_instinct": 99.0}
	goblin.attack_cooldown = 0.0
	goblin.stop_navigation()
	game.combat_scene.update_monster_path(goblin)
	var chase_path: Array = goblin.path_points.duplicate()
	explorer_hp_before = int(explorer.hp)
	game.combat_scene.try_attack(goblin, game.enemy_units)
	_expect(not chase_path.is_empty() and goblin.intent_text == "도둑 추격", "thief hunter starts an out-of-range thief pursuit")
	_expect(explorer.hp == explorer_hp_before and goblin.path_points == chase_path, "nearby explorer does not interrupt an active thief pursuit")

	var corridor_room := "spike_corridor"
	_expect(
		game.rooms.has(corridor_room) and game.graph.is_corridor_room(corridor_room),
		"the runtime fixture exposes the corridor used by the defense patrol"
	)
	if game.rooms.has(corridor_room) and game.graph.is_corridor_room(corridor_room):
		goblin.assigned_room = corridor_room
		goblin.current_room = corridor_room
		goblin.global_position = game.graph.center(corridor_room)
		explorer.current_room = "entrance"
		explorer.global_position = game.graph.center("entrance")
		thief.current_room = room_id
		thief.global_position = game.graph.center(room_id)
		game.global_directive = Constants.DIRECTIVE_DEFENSE
		goblin.stop_navigation()
		game.combat_scene.update_monster_path(goblin)
		_expect(
			goblin.intent_text == "도둑 추격" and not goblin.path_points.is_empty(),
			"a defense-patrol goblin abandons corridor patrol immediately when a thief appears"
		)
		thief.current_room = "entrance"
		thief.goal_room = room_id
		thief.global_position = game.graph.center("entrance")
		goblin.stop_navigation()
		game.combat_scene.update_monster_path(goblin)
		_expect(
			goblin.goal_room == room_id,
			"a thief hunter cuts off a vault-bound thief at the treasure room instead of trailing its current room"
		)
		game.enemy_units.clear()
		game.set_meta("v122_encounter_telegraphs", [{"enemy_id": "thief", "target_room_id": room_id}])
		goblin.current_room = corridor_room
		goblin.global_position = game.graph.center(corridor_room)
		goblin.stop_navigation()
		game.combat_scene.update_monster_path(goblin)
		_expect(
			goblin.goal_room == room_id,
			"a thief hunter stages at the vault before a scheduled thief arrives"
		)
		game.remove_meta("v122_encounter_telegraphs")
		game.enemy_units = [explorer, thief]
		goblin.assigned_room = room_id
		goblin.current_room = room_id
		goblin.global_position = center
		explorer.current_room = room_id
		thief.current_room = room_id

	roster_entry["specialization_id"] = "goblin_finisher"
	game.monster_roster["goblin"] = roster_entry
	explorer.hp = explorer.max_hp
	thief.hp = maxi(1, int(thief.max_hp) / 2)
	explorer.global_position = center + Vector2(14.0, 0.0)
	thief.global_position = center + Vector2(minf(38.0, float(goblin.attack_range) - 4.0), 0.0)
	goblin.attack_cooldown = 0.0
	explorer_hp_before = int(explorer.hp)
	thief_hp_before = int(thief.hp)
	game.combat_scene.try_attack(goblin, game.enemy_units)
	_expect(thief.hp < thief_hp_before and explorer.hp == explorer_hp_before, "wounded hunter attacks the lower-health enemy instead of the closer enemy")

	roster_entry["promotion_id"] = "goblin_vault_keeper"
	game.monster_roster["goblin"] = roster_entry
	explorer.hp = explorer.max_hp
	thief.hp = thief.max_hp
	goblin.current_room = "barracks"
	explorer.current_room = "barracks"
	thief.current_room = "barracks"
	explorer.goal_room = "throne"
	thief.goal_room = room_id
	explorer.global_position = center + Vector2(14.0, 0.0)
	thief.global_position = center + Vector2(minf(38.0, float(goblin.attack_range) - 4.0), 0.0)
	goblin.attack_cooldown = 0.0
	explorer_hp_before = int(explorer.hp)
	thief_hp_before = int(thief.hp)
	game.combat_scene.try_attack(goblin, game.enemy_units)
	_expect(thief.hp < thief_hp_before and explorer.hp == explorer_hp_before, "vault guard attacks the vault-bound intruder instead of the closer enemy")
	game.monster_units.clear()
	game.enemy_units.clear()
	GameState.gold = gold_before
	GameState.mana = mana_before
	goblin.queue_free()
	explorer.queue_free()
	thief.queue_free()


func _check_vault_guard_closes_to_intruder(game: Node) -> void:
	var roster_entry: Dictionary = game.monster_roster.get("goblin", {}).duplicate(true)
	roster_entry["promotion_id"] = "goblin_vault_keeper"
	game.monster_roster["goblin"] = roster_entry
	var vault_room: String = str(game._room_by_facility("treasure", ""))
	_expect(vault_room != "", "the runtime fixture exposes the active vault room")
	if vault_room == "":
		return
	var goblin = game._create_unit(
		"goblin",
		DataRegistry.monster("goblin"),
		Constants.FACTION_MONSTER,
		vault_room
	)
	var thief = game._create_unit(
		"thief",
		DataRegistry.enemy("thief"),
		Constants.FACTION_ENEMY,
		vault_room
	)
	goblin.set_physics_process(false)
	thief.set_physics_process(false)
	var vault_center: Vector2 = game.graph.center(vault_room)
	goblin.global_position = vault_center
	goblin.skill_cooldowns = {"quick_slash": 99.0, "loot_instinct": 99.0}
	var candidates := [
		game._clamp_to_combat_walkable(vault_center + Vector2(160.0, 0.0)),
		game._clamp_to_combat_walkable(vault_center + Vector2(-160.0, 0.0)),
		game._clamp_to_combat_walkable(vault_center + Vector2(0.0, 96.0)),
		game._clamp_to_combat_walkable(vault_center + Vector2(0.0, -96.0))
	]
	var thief_position: Vector2 = candidates[0]
	for candidate in candidates:
		if vault_center.distance_to(candidate) > vault_center.distance_to(thief_position):
			thief_position = candidate
	thief.global_position = thief_position
	thief.goal_room = vault_room
	game.monster_units = [goblin]
	game.enemy_units = [thief]
	game.global_directive = Constants.DIRECTIVE_DEFENSE
	_expect(
		goblin.global_position.distance_to(thief.global_position) > goblin.attack_range,
		"vault intruder starts outside the goblin attack range"
	)
	game.combat_scene.update_monster_path(goblin)
	_expect(
		not goblin.path_points.is_empty()
			and goblin.path_points[-1].distance_to(thief.global_position) <= 1.0,
		"vault guard closes to the intruder position instead of stopping at the room center "
			+ "(path=%s target=%s intent=%s behavior=%s)"
			% [
				str(goblin.path_points),
				str(thief.global_position),
				str(goblin.intent_text),
				str(game._monster_ai_behavior("goblin"))
			]
	)
	game.monster_units.clear()
	game.enemy_units.clear()
	goblin.queue_free()
	thief.queue_free()


func _check_throne_attack_feedback(game: Node) -> void:
	var throne_room: String = str(game._room_by_type("core", "throne"))
	var enemy = game._create_unit(
		"explorer",
		DataRegistry.enemy("explorer"),
		Constants.FACTION_ENEMY,
		throne_room
	)
	enemy.set_physics_process(false)
	enemy.global_position = game.graph.center(throne_room)
	enemy.current_room = throne_room
	enemy.goal_room = throne_room
	enemy.attack_cooldown = 0.0
	game.monster_units.clear()
	game.enemy_units = [enemy]
	var hp_before := int(GameState.demon_lord_hp)
	game.combat_scene.update_room_effects(0.1)
	_expect(GameState.demon_lord_hp < hp_before, "throne pressure still applies damage")
	_expect(enemy.attack_anim_timer > 0.0, "throne pressure triggers the normal enemy attack motion")
	game.enemy_units.clear()
	enemy.queue_free()


func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame


func _finish() -> void:
	if failed:
		print("V122_DEFENDER_CONNECTOR_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_DEFENDER_CONNECTOR_TEST: PASS")
		get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
