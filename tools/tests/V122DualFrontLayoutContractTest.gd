extends Node

const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const BattlePlanAdapter = preload("res://scripts/v122/spatial/V122BattlePlanAdapter.gd")
const LAYOUT_PATH := "res://data/dungeon_quarter/layouts/stage01_dual_front_01.json"

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var layout := _load_layout()
	_expect(not layout.is_empty(), "dual-front candidate layout loads")
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, layout, DataRegistry.rooms)
	_expect(
		bool(graph.validation_summary().get("ok", false)),
		"dual-front candidate ModuleGraph validates: %s" % str(graph.validation_summary().get("errors", []))
	)

	var topology: Dictionary = layout.get("combat_topology", {})
	_expect(int(topology.get("schema_version", 0)) == 1, "combat topology schema is explicit")
	_expect(str(topology.get("activation_state", "")) == "product_default", "approved dual-front layout is marked as the product default")
	var lanes: Dictionary = topology.get("lanes", {})
	_expect(lanes.size() == 2 and lanes.has("lane_a") and lanes.has("lane_b"), "exactly two lanes are declared")

	var lane_a: Dictionary = lanes.get("lane_a", {})
	var lane_b: Dictionary = lanes.get("lane_b", {})
	var route_a: Array = lane_a.get("route", [])
	var route_b: Array = lane_b.get("route", [])
	_expect(
		route_a == graph.path_between(str(lane_a.get("outside_room_id", "")), "throne"),
		"lane A contract equals the real ModuleGraph route"
	)
	_expect(
		route_b == graph.path_between(str(lane_b.get("outside_room_id", "")), "throne"),
		"lane B contract equals the real ModuleGraph route"
	)
	_expect(_shared_prefix_before_merge(route_a, route_b, "throne_antechamber").is_empty(), "lanes remain separate before the throne antechamber")
	_expect(
		route_a.slice(route_a.find("throne_antechamber")) == route_b.slice(route_b.find("throne_antechamber")),
		"lanes share one route only after entering the throne antechamber"
	)
	var lane_a_length := _polyline_length(graph.path_to_point(graph.center("outside_approach"), graph.center("throne")))
	var lane_b_length := _polyline_length(graph.path_to_point(graph.center("outside_approach_b"), graph.center("throne")))
	var length_ratio := lane_b_length / maxf(lane_a_length, 0.001)
	_expect(length_ratio >= 1.15 and length_ratio <= 1.35, "lane B route is about 25 percent longer: %.3f" % length_ratio)

	var trap_module: Dictionary = graph.module_data_for_instance("spike_corridor")
	var narrow_module: Dictionary = graph.module_data_for_instance("lane_a_rear")
	var wide_module: Dictionary = graph.module_data_for_instance("lane_b_front")
	_expect(trap_module.get("trap_cells", []).size() == 6, "lane A preserves six real spike cells")
	_expect(narrow_module.get("walk_cells", []).size() < wide_module.get("walk_cells", []).size(), "lane A is physically narrower than lane B")
	_expect(int(lane_a.get("target_width_cells", 0)) == 3, "lane A target width is three cells")
	_expect(int(lane_b.get("target_width_cells", 0)) == 5, "lane B target width is five cells")

	var antechamber: Dictionary = graph.module_data_for_instance("throne_antechamber")
	_expect(antechamber.get("walk_cells", []).size() >= 25, "throne antechamber keeps at least a 5x5 combat floor")
	_expect(antechamber.get("object_slots", []).is_empty(), "throne antechamber has no facility object slot")
	_expect(antechamber.get("trap_cells", []).is_empty(), "throne antechamber has no fixed trap")

	var zones: Array = topology.get("defense_zones", [])
	_expect(zones.size() == 5, "five fixed defense zones are declared")
	_expect(_unique_string_field(zones, "zone_id").size() == 5, "defense zone IDs are unique")
	var lane_a_rear_zone := _zone(zones, "zone_a_rear")
	_expect(
		str(lane_a_rear_zone.get("anchor_room_id", "")) == "path_a_front_rear"
			and lane_a_rear_zone.get("room_ids", []).has("lane_a_rear"),
		"lane A rear support anchor can join a front-room engagement without losing rear-zone coverage"
	)
	var facility_slots: Array = topology.get("facility_slots", [])
	_expect(facility_slots.size() == 4, "four replaceable facility slots are declared")
	_expect(_unique_string_field(facility_slots, "slot_id").size() == 4, "facility slot IDs are unique")
	for slot_value in facility_slots:
		var slot: Dictionary = slot_value
		var room_id := str(slot.get("room_id", ""))
		_expect(not route_a.has(room_id) and not route_b.has(room_id), "%s is a side branch, not an enemy main-lane node" % room_id)
		_expect(not bool(graph.placed_module_data(room_id).get("locked", true)), "%s remains replaceable" % room_id)

	var connector: Dictionary = topology.get("connector_contract", {})
	_expect(str(connector.get("initial_state", "")) == "collapsed_unplaced", "defender connector begins collapsed and unplaced")
	_expect(bool(connector.get("defender_only", false)), "future connector is defender-only")
	_expect(not bool(connector.get("enemy_path_allowed", true)), "future connector forbids enemy pathing")
	_expect(not graph.module_instance_ids().has(str(connector.get("connector_id", ""))), "collapsed connector is not part of the shared ModuleGraph")
	_expect(int(connector.get("cost", {}).get("gold", 0)) == 1000, "connector gold cost is fixed at 1000")
	_expect(int(connector.get("cost", {}).get("mana", 0)) == 100, "connector mana cost is fixed at 100")

	for legacy_id in topology.get("legacy_instance_ids_preserved", []):
		_expect(graph.module_instance_ids().has(str(legacy_id)), "legacy instance ID is preserved: %s" % legacy_id)

	_check_dual_front_snapshot(graph, layout, topology, route_a, route_b)

	if failed:
		print("V122_DUAL_FRONT_LAYOUT_CONTRACT_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_DUAL_FRONT_LAYOUT_CONTRACT_TEST: PASS")
		get_tree().quit(0)


func _load_layout() -> Dictionary:
	if not FileAccess.file_exists(LAYOUT_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	return parsed if parsed is Dictionary else {}


func _check_dual_front_snapshot(
	graph,
	layout: Dictionary,
	topology: Dictionary,
	route_a: Array,
	route_b: Array
) -> void:
	var roster := {
		"mon_a_legacy": {
			"species_id": "goblin",
			"room": "barracks",
			"placement_slot_id": "monster:barracks:0"
		},
		"mon_b_zone": {
			"species_id": "slime",
			"defense_zone_id": "zone_b_front",
			"placement_slot_id": "monster:zone_b_front:1"
		},
		"mon_merge_legacy": {
			"species_id": "imp",
			"room": "throne"
		}
	}
	var snapshot := BattlePlanAdapter.build_snapshot(
		graph,
		"stage01_dual_front_candidate_01",
		DataRegistry.rooms,
		roster,
		["throne"],
		1
	)
	var snapshot_errors := BattlePlanAdapter.validate_snapshot(snapshot)
	_expect(
		snapshot_errors.is_empty(),
		"dual-front battle snapshot validates: %s" % str(snapshot_errors)
	)
	_expect(str(snapshot.get("primary_lane_id", "")) == "lane_a", "lane A remains the active_route compatibility lane")
	_expect(snapshot.get("active_route", []) == route_a, "active_route remains compatible with lane A consumers")
	_expect(snapshot.get("lane_routes", {}).get("lane_a", []) == route_a, "snapshot exposes lane A route")
	_expect(snapshot.get("lane_routes", {}).get("lane_b", []) == route_b, "snapshot exposes lane B route")
	_expect(str(snapshot.get("route_starts", {}).get("lane_a", "")) == "outside_approach", "snapshot exposes lane A start")
	_expect(str(snapshot.get("route_starts", {}).get("lane_b", "")) == "outside_approach_b", "snapshot exposes lane B start")
	_expect(str(snapshot.get("lane_entries", {}).get("lane_a", "")) == "entrance", "snapshot exposes lane A combat entry")
	_expect(str(snapshot.get("lane_entries", {}).get("lane_b", "")) == "service_entrance", "snapshot exposes lane B combat entry")
	_expect(str(snapshot.get("lane_labels", {}).get("lane_a", "")) == "정문 전선", "snapshot exposes the lane A player label")
	_expect(str(snapshot.get("lane_labels", {}).get("lane_b", "")) == "서비스 침입 균열 전선", "snapshot exposes the lane B player label")
	_expect(snapshot.get("defense_zones", []).size() == 5, "snapshot exposes five defense zones")
	var connector: Dictionary = snapshot.get("defender_connector", {})
	_expect(str(connector.get("connector_id", "")) == "rear_cross_lane_connector", "snapshot exposes the connector contract")
	_expect(not bool(connector.get("unlocked", true)), "connector remains locked before DAY 3")
	_expect(not bool(connector.get("built", true)), "connector starts unbuilt")
	_expect(int(connector.get("cost", {}).get("gold", 0)) == 1000, "snapshot keeps the 1000 gold connector cost")
	_expect(int(connector.get("cost", {}).get("mana", 0)) == 100, "snapshot keeps the 100 mana connector cost")
	_expect(not bool(connector.get("enemy_path_allowed", true)), "snapshot keeps enemy pathing disabled")
	_expect(snapshot.get("facility_slot_contracts", []).size() == 4, "snapshot exposes four facility slot contracts")
	_expect(snapshot.get("facility_slots", []).size() == 4, "candidate has four current facility slot states")
	_expect(snapshot.get("facility_placements", []).size() == 4, "facility placements are stored independently from slot contracts")
	_expect(
		str(_monster_placement(snapshot, "mon_a_legacy").get("defense_zone_id", "")) == "zone_a_front",
		"legacy barracks placement falls back to linked zone A front"
	)
	_expect(
		str(_monster_placement(snapshot, "mon_a_legacy").get("slot_id", "")) == "monster:zone_a_front:0",
		"legacy room slot index is preserved in its mapped defense zone"
	)
	_expect(
		str(_monster_placement(snapshot, "mon_b_zone").get("slot_id", "")) == "monster:zone_b_front:1",
		"explicit defense-zone placement remains stable"
	)
	_expect(
		str(_monster_placement(snapshot, "mon_merge_legacy").get("defense_zone_id", "")) == "zone_throne_antechamber",
		"legacy throne placement falls back to the throne antechamber zone"
	)

	var swapped_rooms: Dictionary = DataRegistry.rooms.duplicate(true)
	swapped_rooms["barracks"]["facility_role"] = "treasure"
	swapped_rooms["treasure"]["facility_role"] = "barracks"
	var swapped_graph = ModuleGraphScript.new()
	swapped_graph.setup_quarter(DataRegistry.quarter_modules, layout, swapped_rooms)
	var swapped := BattlePlanAdapter.build_snapshot(
		swapped_graph,
		"stage01_dual_front_candidate_01",
		swapped_rooms,
		roster,
		["throne"],
		1
	)
	_expect(
		snapshot.get("facility_slot_contracts", []) == swapped.get("facility_slot_contracts", []),
		"facility slot contracts do not move when facility occupants are swapped"
	)
	_expect(
		str(_facility_placement(swapped, "facility_a_front").get("facility_role", "")) == "treasure",
		"facility A front records its swapped occupant independently"
	)
	_expect(
		str(_facility_placement(swapped, "facility_b_rear").get("facility_role", "")) == "barracks",
		"facility B rear records its swapped occupant independently"
	)
	_expect(
		snapshot.get("monster_placements", []) == swapped.get("monster_placements", []),
		"monster defense-zone placements do not move when facilities are swapped"
	)

	var built_snapshot := BattlePlanAdapter.build_snapshot(
		graph,
		"stage01_dual_front_candidate_01",
		DataRegistry.rooms,
		roster,
		["throne"],
		3,
		{
			"connector_id": "rear_cross_lane_connector",
			"built": true,
			"built_day": 3
		}
	)
	var built_connector: Dictionary = built_snapshot.get("defender_connector", {})
	_expect(bool(built_connector.get("unlocked", false)), "connector unlocks on DAY 3")
	_expect(bool(built_connector.get("built", false)), "matching permanent construction state marks the connector built")
	_expect(int(built_connector.get("built_day", 0)) == 3, "connector records its construction day")
	_expect(built_connector.get("route_points", []).size() == 3, "built connector exposes entry, crossing, and exit anchors")
	_expect(
		str(built_snapshot.get("layout_fingerprint", "")) == str(snapshot.get("layout_fingerprint", "")),
		"construction state does not mutate the structural layout fingerprint"
	)
	_expect(
		BattlePlanAdapter.validate_snapshot(built_snapshot).is_empty(),
		"built connector snapshot remains valid"
	)


func _monster_placement(snapshot: Dictionary, monster_instance_id: String) -> Dictionary:
	for value in snapshot.get("monster_placements", []):
		if value is Dictionary and str(value.get("monster_instance_id", "")) == monster_instance_id:
			return value
	return {}


func _facility_placement(snapshot: Dictionary, facility_slot_id: String) -> Dictionary:
	for value in snapshot.get("facility_placements", []):
		if value is Dictionary and str(value.get("facility_slot_id", "")) == facility_slot_id:
			return value
	return {}


func _zone(zones: Array, zone_id: String) -> Dictionary:
	for value in zones:
		if value is Dictionary and str(value.get("zone_id", "")) == zone_id:
			return value
	return {}


func _shared_prefix_before_merge(route_a: Array, route_b: Array, merge_room_id: String) -> Array:
	var a_before := route_a.slice(0, route_a.find(merge_room_id))
	var b_before := route_b.slice(0, route_b.find(merge_room_id))
	var shared: Array = []
	for room_id in a_before:
		if b_before.has(room_id):
			shared.append(room_id)
	return shared


func _polyline_length(points: Array) -> float:
	var total := 0.0
	for index in range(1, points.size()):
		total += Vector2(points[index - 1]).distance_to(Vector2(points[index]))
	return total


func _unique_string_field(values: Array, field: String) -> Dictionary:
	var result: Dictionary = {}
	for value in values:
		if value is Dictionary:
			result[str(value.get(field, ""))] = true
	return result


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
