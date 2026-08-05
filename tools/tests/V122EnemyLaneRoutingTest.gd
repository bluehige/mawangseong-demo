extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const EncounterAdapter = preload("res://scripts/v122/combat/V122EncounterAdapter.gd")
const CombatSceneControllerScript = preload("res://scripts/game/CombatSceneController.gd")

var failed := false


class FakeGraph:
	extends RefCounted

	var centers := {
		"entrance": Vector2(10.0, 10.0),
		"service_entrance": Vector2(20.0, 20.0),
		"room_a_front": Vector2(30.0, 10.0),
		"room_a_rear": Vector2(40.0, 10.0),
		"room_b_front": Vector2(30.0, 20.0),
		"room_b_rear": Vector2(40.0, 20.0),
		"merge": Vector2(50.0, 15.0),
		"throne": Vector2(60.0, 15.0),
		"barracks_room": Vector2(30.0, 5.0),
		"recovery_room": Vector2(40.0, 5.0),
		"watch_room": Vector2(30.0, 25.0),
		"treasure_room": Vector2(40.0, 25.0)
	}

	func module_instance_ids() -> Array:
		return centers.keys()

	func center(room_id: String) -> Vector2:
		return centers.get(room_id, Vector2.ZERO)

	func path_to_point(_from_world: Vector2, target: Vector2) -> Array:
		return [target]

	func path_between(from_room_id: String, to_room_id: String) -> Array:
		return [from_room_id, to_room_id] if centers.has(from_room_id) and centers.has(to_room_id) else []

	func exits(_room_id: String) -> Array:
		return []

	func room_at_world(point: Vector2) -> String:
		var result := ""
		var best_distance := INF
		for room_id_value in centers.keys():
			var room_id := str(room_id_value)
			var distance := point.distance_squared_to(centers.get(room_id, Vector2.ZERO))
			if distance < best_distance:
				best_distance = distance
				result = room_id
		return result


class FakeUnit:
	extends Node2D

	var unit_id := ""
	var display_name := ""
	var faction := ""
	var role := ""
	var current_room := ""
	var assigned_room := ""
	var goal_room := ""
	var path_points: Array = []
	var hp := 100
	var down := false

	func is_alive() -> bool:
		return not down and hp > 0

	func set_path(points: Array) -> void:
		path_points = points.duplicate()

	func set_tactical_state(_state, _intent: String, _target: String = "") -> void:
		pass


class FakeWaveManager:
	extends RefCounted

	var schedule: Array = []
	var next_index := 0
	var elapsed := 0.0
	var total_to_spawn := 0


class FakeRoot:
	extends Node2D

	var graph = FakeGraph.new()
	var wave_manager = FakeWaveManager.new()
	var rooms := {
		"entrance": {"display_name": "정문", "type": "entry"},
		"service_entrance": {"display_name": "서비스 침입 균열", "type": "entry"},
		"throne": {"display_name": "왕좌", "type": "core"},
		"barracks_room": {"display_name": "병영", "facility_role": "barracks"},
		"recovery_room": {"display_name": "회복실", "facility_role": "recovery"},
		"watch_room": {"display_name": "감시 초소", "facility_role": "watch_post"},
		"treasure_room": {"display_name": "금고", "facility_role": "treasure"}
	}
	var enemy_units: Array = []
	var monster_units: Array = []
	var engineer_target_rooms: Dictionary = {}
	var engineer_targeted_facility_rooms: Dictionary = {}
	var engineer_completed_units: Dictionary = {}
	var spawned_count := 0
	var engineers_spawned_this_battle := 0
	var thieves_spawned_this_battle := 0
	var thieves_reached_treasure_this_battle := 0
	var thieves_completed_theft_this_battle := 0
	var thieves_escaped_this_battle := 0
	var global_directive := Constants.DIRECTIVE_DEFENSE
	var room_directives := {}

	func _create_unit(source_id: String, stats: Dictionary, faction: String, room_id: String) -> FakeUnit:
		var unit := FakeUnit.new()
		add_child(unit)
		unit.unit_id = source_id
		unit.display_name = str(stats.get("display_name", source_id))
		unit.faction = faction
		unit.role = str(stats.get("role", stats.get("goal_type", "")))
		unit.current_room = room_id
		unit.assigned_room = room_id
		unit.goal_room = room_id
		return unit

	func _clamp_to_combat_walkable(point: Vector2) -> Vector2:
		return point

	func _room_actor_point(room_id: String, _index: int, _combat: bool = false) -> Vector2:
		return graph.center(room_id)

	func _room_by_type(room_type: String, fallback: String = "") -> String:
		for room_id_value in rooms.keys():
			var room_id := str(room_id_value)
			if str(rooms[room_id].get("type", "")) == room_type:
				return room_id
		return fallback

	func _room_by_facility(facility_role: String, fallback: String = "") -> String:
		for room_id_value in rooms.keys():
			var room_id := str(room_id_value)
			if str(rooms[room_id].get("facility_role", "")) == facility_role:
				return room_id
		return fallback

	func _facility_room_is_active(room_id: String) -> bool:
		return rooms.has(room_id)

	func _engineer_target_facility_rooms() -> Array[String]:
		return ["barracks_room", "recovery_room", "watch_room"]

	func _log(_message: String) -> void:
		pass

	func display_name_for_instance(instance_id: String) -> String:
		return str(rooms.get(instance_id, {}).get("display_name", instance_id))


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var plan := _battle_plan()
	var source_schedule := [
		{"enemy_id": "explorer", "lane_id": "lane_b", "time": 6.0},
		{"enemy_id": "guard", "time": 12.0},
		{"enemy_id": "thief", "time": 18.0},
		{
			"enemy_id": "engineer",
			"target_facility_slot_id": "facility_b_front",
			"time": 24.0
		}
	]
	var catalog := {
		"explorer": {"goal_type": "throne"},
		"guard": {"goal_type": "throne"},
		"thief": {"goal_type": "treasure"},
		"engineer": {"goal_type": "facility"}
	}
	var annotated := EncounterAdapter.annotate_schedule(source_schedule, plan, catalog)
	_expect(not source_schedule[0].has("spawn_room_id"), "schedule annotation does not mutate the source wave")

	var lane_b_assault: Dictionary = annotated[0]
	_expect(str(lane_b_assault.get("lane_id", "")) == "lane_b", "an explicit general-enemy lane is preserved")
	_expect(str(lane_b_assault.get("spawn_room_id", "")) == "service_entrance", "lane B enemies spawn at the service entrance")
	_expect(str(lane_b_assault.get("target_room_id", "")) == "throne", "general enemies keep the throne goal")

	var default_assault: Dictionary = annotated[1]
	_expect(str(default_assault.get("lane_id", "")) == "lane_a", "an unassigned legacy wave uses the compatibility primary lane")
	_expect(str(default_assault.get("spawn_room_id", "")) == "entrance", "primary-lane fallback keeps the existing entrance")

	var thief: Dictionary = annotated[2]
	_expect(str(thief.get("lane_id", "")) == "lane_b", "the thief follows the current treasure slot lane")
	_expect(str(thief.get("spawn_room_id", "")) == "service_entrance", "the thief enters on the treasure lane")
	_expect(str(thief.get("exit_room_id", "")) == "service_entrance", "the thief exits through its own entry lane")
	_expect(str(thief.get("target_facility_slot_id", "")) == "facility_b_rear", "the thief records the exact treasure slot")

	var engineer: Dictionary = annotated[3]
	_expect(str(engineer.get("lane_id", "")) == "lane_b", "the engineer follows the selected facility lane")
	_expect(str(engineer.get("target_room_id", "")) == "watch_room", "the engineer records the selected facility room")
	_expect(engineer.get("telegraph_id", "") != thief.get("telegraph_id", ""), "lane telegraphs have stable distinct IDs")

	var engineer_telegraph := EncounterAdapter.telegraph(
		{"id": "engineer", "goal_type": "facility"},
		plan,
		engineer
	)
	_expect(str(engineer_telegraph.get("lane_label", "")) == "서비스 침입 균열 전선", "telegraph exposes the player-facing lane label")
	_expect(engineer_telegraph.get("route", []).has("room_b_front"), "facility telegraph follows the selected lane")
	_expect(str(engineer_telegraph.get("route", []).back()) == "watch_room", "facility telegraph ends at the facility branch")

	var swapped_plan := plan.duplicate(true)
	swapped_plan["facility_slots"][0]["facility_role"] = "treasure"
	swapped_plan["facility_slots"][3]["facility_role"] = "barracks"
	var moved_treasure := EncounterAdapter.telegraph(
		{"id": "thief", "goal_type": "treasure"},
		swapped_plan
	)
	_expect(str(moved_treasure.get("lane_id", "")) == "lane_a", "moving the treasure changes the thief entry lane")
	_expect(str(moved_treasure.get("target_facility_slot_id", "")) == "facility_a_front", "moving the treasure changes the telegraphed target slot")

	var invalid_lane := EncounterAdapter.spawn_contract(
		{"id": "explorer", "goal_type": "throne"},
		{"lane_id": "missing_lane"},
		plan
	)
	_expect(str(invalid_lane.get("lane_id", "")) == "lane_a", "invalid explicit lanes fall back deterministically")
	_expect(not invalid_lane.get("route", []).has("watch_room"), "general enemies never divert into a facility branch")
	_check_runtime_spawn_consumption(plan, annotated)

	if failed:
		print("V122_ENEMY_LANE_ROUTING_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_ENEMY_LANE_ROUTING_TEST: PASS")
		get_tree().quit(0)


func _check_runtime_spawn_consumption(plan: Dictionary, annotated: Array) -> void:
	var fake_root := FakeRoot.new()
	add_child(fake_root)
	fake_root.set_meta("v122_battle_plan", plan)
	var controller = CombatSceneControllerScript.new()
	controller.setup(fake_root, null)
	_check_defender_only_connector_path(fake_root, controller, plan)
	_expect(controller._v122_breach_depth("room_b_rear", plan, "lane_b") == 2, "lane B breach depth uses its own entry instead of the main entrance")
	_expect(controller._v122_breach_depth("watch_room", plan, "lane_b") == 1, "a facility branch inherits its linked lane-zone depth")

	controller.spawn_enemy("explorer", annotated[0])
	var assault: FakeUnit = fake_root.enemy_units.back()
	_expect(assault.current_room == "service_entrance", "actual general-enemy creation consumes the lane B spawn room")
	_expect(str(assault.get_meta("v122_lane_id", "")) == "lane_b", "actual general enemy keeps its fixed lane metadata")
	_expect(assault.goal_room == "throne", "actual general enemy advances to the throne")

	controller.spawn_enemy("thief", annotated[2])
	var thief: FakeUnit = fake_root.enemy_units.back()
	_expect(thief.current_room == "service_entrance", "actual thief creation consumes the treasure lane entry")
	_expect(thief.goal_room == "treasure_room", "actual thief advances to the current treasure room")
	_expect(controller._v122_unit_exit_room(thief) == "service_entrance", "actual thief retains the same-lane exit")

	controller.spawn_enemy("engineer", annotated[3])
	var engineer: FakeUnit = fake_root.enemy_units.back()
	_expect(engineer.current_room == "service_entrance", "actual engineer creation consumes the target facility lane")
	_expect(engineer.goal_room == "watch_room", "actual engineer advances to the telegraphed facility")
	_expect(str(engineer.get_meta("v122_target_facility_slot_id", "")) == "facility_b_front", "actual engineer retains the exact facility slot")

	fake_root.enemy_units.clear()
	fake_root.wave_manager.schedule = [annotated[0].duplicate(true)]
	fake_root.wave_manager.next_index = 0
	fake_root.wave_manager.elapsed = 0.0
	var warning_threats: Array = controller._v122_active_threats()
	_expect(warning_threats.size() == 1, "the next lane threat appears in the six-second warning window")
	_expect(str(warning_threats[0].get("status_label", "")) == "6초 후", "the warning exposes the remaining lead time")
	_expect(str(warning_threats[0].get("lane_id", "")) == "lane_b", "the warning exposes the exact entry lane")

	var delayed_entry: Dictionary = annotated[0].duplicate(true)
	delayed_entry["time"] = 8.0
	fake_root.wave_manager.schedule = [delayed_entry]
	_expect(controller._v122_active_threats().is_empty(), "the runtime warning stays hidden before the lead window")

	fake_root.queue_free()


func _check_defender_only_connector_path(
	fake_root: FakeRoot,
	controller,
	plan: Dictionary
) -> void:
	var connector_anchor := Vector2(45.0, 15.0)
	for defender_id in ["slime", "goblin", "imp"]:
		var defender := FakeUnit.new()
		fake_root.add_child(defender)
		defender.unit_id = defender_id
		defender.faction = Constants.FACTION_MONSTER
		defender.current_room = "room_a_rear"
		defender.assigned_room = "room_a_rear"
		defender.global_position = fake_root.graph.center(defender.current_room)
		var defender_route: Array = controller._path_from_world_to_room(
			defender.global_position,
			"room_b_rear",
			defender
		)
		_expect(
			defender_route.has(connector_anchor),
			"%s consumes the built defender connector" % defender_id
		)

	var crossing_defender := FakeUnit.new()
	fake_root.add_child(crossing_defender)
	crossing_defender.unit_id = "slime"
	crossing_defender.faction = Constants.FACTION_MONSTER
	crossing_defender.current_room = "room_a_rear"
	crossing_defender.assigned_room = "room_a_rear"
	crossing_defender.global_position = Vector2(44.0, 14.0)
	var replanned_route: Array = controller._path_from_world_to_room(
		crossing_defender.global_position,
		"room_b_rear",
		crossing_defender
	)
	_expect(
		not replanned_route.is_empty()
			and replanned_route[0] == connector_anchor
			and not replanned_route.has(fake_root.graph.center("room_a_rear")),
		"mid-connector replanning continues forward instead of returning to the source lane"
	)
	crossing_defender.global_position = Vector2(44.0, 16.0)
	var reverse_replanned_route: Array = controller._path_from_world_to_room(
		crossing_defender.global_position,
		"room_a_rear",
		crossing_defender
	)
	_expect(
		not reverse_replanned_route.is_empty()
			and reverse_replanned_route[0] == connector_anchor
			and not reverse_replanned_route.has(fake_root.graph.center("room_b_rear")),
		"reverse mid-connector replanning continues forward instead of returning to lane B"
	)

	var cross_lane_target := FakeUnit.new()
	fake_root.add_child(cross_lane_target)
	cross_lane_target.unit_id = "guard"
	cross_lane_target.faction = Constants.FACTION_ENEMY
	cross_lane_target.current_room = "room_b_rear"
	cross_lane_target.global_position = fake_root.graph.center(cross_lane_target.current_room)
	fake_root.enemy_units = [cross_lane_target]
	for defender_id in ["slime", "goblin", "imp"]:
		var defender := FakeUnit.new()
		fake_root.add_child(defender)
		defender.unit_id = defender_id
		defender.faction = Constants.FACTION_MONSTER
		defender.current_room = "room_a_rear"
		defender.assigned_room = "room_a_rear"
		defender.global_position = fake_root.graph.center(defender.current_room)
		fake_root.monster_units = [defender]
		_expect(
			controller._defense_target(defender, cross_lane_target) == cross_lane_target,
			"사수 상태의 %s supports the opposite lane through a built connector when its lane is clear" % defender_id
		)

	var local_target := FakeUnit.new()
	fake_root.add_child(local_target)
	local_target.unit_id = "guard"
	local_target.faction = Constants.FACTION_ENEMY
	local_target.current_room = "room_a_rear"
	local_target.global_position = fake_root.graph.center(local_target.current_room)
	fake_root.enemy_units = [local_target, cross_lane_target]
	var local_defender := FakeUnit.new()
	fake_root.add_child(local_defender)
	local_defender.unit_id = "slime"
	local_defender.faction = Constants.FACTION_MONSTER
	local_defender.current_room = "room_a_rear"
	local_defender.assigned_room = "room_a_rear"
	local_defender.global_position = fake_root.graph.center(local_defender.current_room)
	fake_root.monster_units = [local_defender]
	_expect(
		controller._defense_target(local_defender, cross_lane_target) == local_target,
		"사수 상태의 defender keeps its own lane priority before using the connector"
	)

	var enemy := FakeUnit.new()
	fake_root.add_child(enemy)
	enemy.faction = Constants.FACTION_ENEMY
	enemy.current_room = "room_a_front"
	enemy.global_position = fake_root.graph.center(enemy.current_room)
	var enemy_route: Array = controller._path_from_world_to_room(
		enemy.global_position,
		"room_b_front",
		enemy
	)
	_expect(
		not enemy_route.has(connector_anchor) and enemy_route == [fake_root.graph.center("room_b_front")],
		"enemy movement keeps the shared graph and never consumes the defender connector"
	)

	var unbuilt_plan := plan.duplicate(true)
	unbuilt_plan["defender_connector"]["built"] = false
	fake_root.set_meta("v122_battle_plan", unbuilt_plan)
	var unbuilt_route: Array = controller._path_from_world_to_room(
		crossing_defender.global_position,
		"room_b_front",
		crossing_defender
	)
	_expect(
		not unbuilt_route.has(connector_anchor),
		"defenders cannot cross the connector before construction"
	)
	fake_root.set_meta("v122_battle_plan", plan)


func _battle_plan() -> Dictionary:
	return {
		"primary_lane_id": "lane_a",
		"lane_routes": {
			"lane_a": ["outside_a", "entrance", "room_a_front", "room_a_rear", "merge", "throne"],
			"lane_b": ["outside_b", "service_entrance", "room_b_front", "room_b_rear", "merge", "throne"]
		},
		"lane_entries": {
			"lane_a": "entrance",
			"lane_b": "service_entrance"
		},
		"lane_labels": {
			"lane_a": "정문 전선",
			"lane_b": "서비스 침입 균열 전선"
		},
		"active_route": ["outside_a", "entrance", "room_a_front", "room_a_rear", "merge", "throne"],
		"route_start": "outside_a",
		"rooms": ["entrance", "service_entrance", "room_a_front", "room_a_rear", "room_b_front", "room_b_rear", "merge", "throne", "barracks_room", "recovery_room", "watch_room", "treasure_room"],
		"enemy_goals": ["throne"],
		"defender_connector": {
			"connector_id": "rear_cross_lane_connector",
			"from_zone_id": "zone_a_rear",
			"to_zone_id": "zone_b_rear",
			"from_lane_id": "lane_a",
			"to_lane_id": "lane_b",
			"from_room_id": "room_a_rear",
			"to_room_id": "room_b_rear",
			"world_anchor": [45.0, 15.0],
			"route_points": [[40.0, 10.0], [45.0, 15.0], [40.0, 20.0]],
			"defender_only": true,
			"enemy_path_allowed": false,
			"unlock_day": 3,
			"unlocked": true,
			"cost": {"gold": 1000, "mana": 100},
			"permanent": true,
			"built": true,
			"built_day": 3
		},
		"defense_zones": [
			{"zone_id": "zone_a_front", "lane_id": "lane_a", "anchor_room_id": "room_a_front"},
			{"zone_id": "zone_a_rear", "lane_id": "lane_a", "anchor_room_id": "room_a_rear"},
			{"zone_id": "zone_b_front", "lane_id": "lane_b", "anchor_room_id": "room_b_front"},
			{"zone_id": "zone_b_rear", "lane_id": "lane_b", "anchor_room_id": "room_b_rear"}
		],
		"facility_slots": [
			{"slot_id": "facility_a_front", "room_id": "barracks_room", "facility_instance_id": "barracks_room", "lane_id": "lane_a", "linked_zone_ids": ["zone_a_front"], "facility_role": "barracks", "object_id": "barracks_object", "world_anchor": [10.0, 10.0]},
			{"slot_id": "facility_a_rear", "room_id": "recovery_room", "facility_instance_id": "recovery_room", "lane_id": "lane_a", "linked_zone_ids": ["zone_a_rear"], "facility_role": "recovery", "object_id": "recovery_object", "world_anchor": [20.0, 20.0]},
			{"slot_id": "facility_b_front", "room_id": "watch_room", "facility_instance_id": "watch_room", "lane_id": "lane_b", "linked_zone_ids": ["zone_b_front"], "facility_role": "watch_post", "object_id": "watch_object", "world_anchor": [30.0, 30.0]},
			{"slot_id": "facility_b_rear", "room_id": "treasure_room", "facility_instance_id": "treasure_room", "lane_id": "lane_b", "linked_zone_ids": ["zone_b_rear"], "facility_role": "treasure", "object_id": "treasure_object", "world_anchor": [40.0, 40.0]}
		],
		"world_anchors": {
			"entrance": [1.0, 1.0],
			"service_entrance": [2.0, 2.0],
			"throne": [50.0, 50.0]
		}
	}


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
