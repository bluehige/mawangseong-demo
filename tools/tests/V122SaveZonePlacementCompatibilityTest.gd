extends Node

const SaveProgressionAdapter = preload("res://scripts/v122/save/V122SaveProgressionAdapter.gd")

var failed := false


func _ready() -> void:
	var candidate_plan := _candidate_plan()
	_check_candidate_build(candidate_plan)
	_check_legacy_normalization(candidate_plan)
	_check_retry_restore(candidate_plan)
	if failed:
		print("V122_SAVE_ZONE_PLACEMENT_COMPATIBILITY_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_SAVE_ZONE_PLACEMENT_COMPATIBILITY_TEST: PASS")
		get_tree().quit(0)


func _check_candidate_build(candidate_plan: Dictionary) -> void:
	var state := SaveProgressionAdapter.build(candidate_plan)
	_expect(
		int(state.get("schema_version", 0)) == 1,
		"additive zone placement fields keep save schema version 1"
	)
	var facility: Dictionary = state.get("facility_placements", []).front()
	_expect(
		str(facility.get("facility_slot_id", "")) == "facility_a_front",
		"build prefers independent facility placements over facility slot state"
	)
	_expect(
		str(facility.get("facility_instance_id", "")) == "barracks",
		"build preserves the concrete facility instance alias"
	)
	_expect(
		str(facility.get("facility_role", "")) == "treasure",
		"build preserves the current facility occupant"
	)
	var monster: Dictionary = state.get("monster_placements", []).front()
	_expect(
		str(monster.get("defense_zone_id", "")) == "zone_a_front",
		"build preserves a monster defense zone"
	)
	_expect(
		str(monster.get("slot_id", "")) == "monster:zone_a_front:1",
		"build preserves a defense-zone slot ID"
	)
	_expect(
		bool(state.get("connector_state", {}).get("built", false))
			and int(state.get("connector_state", {}).get("built_day", 0)) == 3,
		"build persists the permanent connector construction state"
	)
	var object_only_plan := _legacy_plan()
	object_only_plan["facility_placements"] = [
		{"room_id": "barracks", "object_id": "weapon_rack"}
	]
	var legacy_build := SaveProgressionAdapter.build(object_only_plan)
	var legacy_facility: Dictionary = legacy_build.get("facility_placements", []).front()
	_expect(
		str(legacy_facility.get("facility_role", "")) == "barracks"
			and str(legacy_facility.get("facility_slot_id", "")) == "facility:barracks",
		"object-only legacy facility placements fall back to facility slot state"
	)

	var confirmation := SaveProgressionAdapter.capture_confirmation(
		candidate_plan,
		3,
		"all_out",
		{"zone_a_front": "hold"}
	)
	var retry: Dictionary = confirmation.get("retry_snapshot", {})
	_expect(
		str(retry.get("facility_placements", []).front().get("facility_slot_id", "")) == "facility_a_front",
		"confirmation preserves a facility slot ID"
	)
	_expect(
		str(retry.get("monster_placements", []).front().get("slot_id", "")) == "monster:zone_a_front:1",
		"confirmation preserves a defense-zone slot ID"
	)
	_expect(
		bool(retry.get("connector_state", {}).get("built", false)),
		"confirmation and retry preserve the built connector"
	)


func _check_legacy_normalization(candidate_plan: Dictionary) -> void:
	var legacy_state := _legacy_state()
	var normalized := SaveProgressionAdapter.normalize(legacy_state, candidate_plan)
	_expect(
		not bool(normalized.get("connector_state", {}).get("built", true)),
		"a save without connector fields receives the safe unbuilt default"
	)
	var facility: Dictionary = normalized.get("facility_placements", []).front()
	_expect(
		str(facility.get("facility_slot_id", "")) == "facility_a_front",
		"legacy room facility placement gains its fixed facility slot ID"
	)
	_expect(
		str(facility.get("room_id", "")) == "barracks"
			and str(facility.get("facility_instance_id", "")) == "barracks"
			and str(facility.get("slot_id", "")) == "facility:barracks",
		"legacy facility room, instance, and slot fields remain available"
	)

	var monster: Dictionary = normalized.get("monster_placements", []).front()
	_expect(
		str(monster.get("defense_zone_id", "")) == "zone_a_front"
			and str(monster.get("assigned_defense_zone_id", "")) == "zone_a_front",
		"legacy room monster placement gains both defense-zone fields"
	)
	_expect(
		str(monster.get("slot_id", "")) == "monster:zone_a_front:1",
		"legacy room monster slot is normalized to a defense-zone slot"
	)
	_expect(
		str(monster.get("legacy_slot_id", "")) == "monster:barracks:1"
			and str(monster.get("room_id", "")) == "barracks",
		"legacy monster slot and room remain recoverable"
	)

	var throne_monster: Dictionary = normalized.get("monster_placements", [])[1]
	_expect(
		str(throne_monster.get("defense_zone_id", "")) == "zone_throne_antechamber",
		"a legacy throne placement maps to the shared antechamber zone"
	)
	var confirmed_monster: Dictionary = normalized.get(
		"last_confirmed_placements", {}
	).get("monster_placements", []).front()
	_expect(
		str(confirmed_monster.get("defense_zone_id", "")) == "zone_a_front",
		"last-confirmed legacy placements are normalized"
	)
	var retry_monster: Dictionary = normalized.get(
		"retry_snapshot", {}
	).get("monster_placements", []).front()
	_expect(
		str(retry_monster.get("slot_id", "")) == "monster:zone_a_front:1",
		"retry legacy placements are normalized"
	)
	_expect(
		SaveProgressionAdapter.validate_optional_payload({"v122_battle_plan": normalized}) == "",
		"normalized legacy state remains valid under schema version 1"
	)
	var invalid_optional_id := normalized.duplicate(true)
	invalid_optional_id["monster_placements"][0]["defense_zone_id"] = 1
	_expect(
		SaveProgressionAdapter.validate_optional_payload({"v122_battle_plan": invalid_optional_id}) != "",
		"optional zone identifiers are type-checked when present"
	)

	var json_round_trip = JSON.parse_string(JSON.stringify(normalized))
	var renormalized := SaveProgressionAdapter.normalize(json_round_trip, candidate_plan)
	_expect(
		renormalized.get("facility_placements", []) == normalized.get("facility_placements", [])
			and renormalized.get("monster_placements", []) == normalized.get("monster_placements", [])
			and renormalized.get("retry_snapshot", {}).get("monster_placements", [])
				== normalized.get("retry_snapshot", {}).get("monster_placements", []),
		"candidate-enriched legacy placement contracts are stable across JSON round trip"
	)


func _check_retry_restore(candidate_plan: Dictionary) -> void:
	var normalized := SaveProgressionAdapter.normalize(_legacy_state(), candidate_plan)
	var retry: Dictionary = normalized.get("retry_snapshot", {})
	var rooms := {
		"barracks": {"facility_role": "barracks"},
		"recovery": {"facility_role": "recovery"},
		"throne": {"facility_role": "throne"}
	}
	var roster := {
		"slime": {
			"room": "recovery",
			"defense_zone_id": "zone_a_rear",
			"assigned_defense_zone_id": "zone_a_rear",
			"placement_slot_id": "monster:zone_a_rear:0"
		},
		"guard": {
			"room": "recovery",
			"placement_slot_id": "monster:zone_a_rear:1"
		}
	}
	var restored := SaveProgressionAdapter.apply_retry_snapshot(
		retry,
		rooms,
		roster,
		"guard",
		{},
		candidate_plan
	)
	_expect(
		str(restored.get("rooms", {}).get("barracks", {}).get("facility_role", "")) == "treasure",
		"retry restores the facility occupant role"
	)
	var slime: Dictionary = restored.get("monster_roster", {}).get("slime", {})
	_expect(str(slime.get("room", "")) == "barracks", "retry restores the legacy monster room")
	_expect(
		str(slime.get("defense_zone_id", "")) == "zone_a_front"
			and str(slime.get("assigned_defense_zone_id", "")) == "zone_a_front",
		"retry restores both monster defense-zone fields"
	)
	_expect(
		str(slime.get("placement_slot_id", "")) == "monster:zone_a_front:1",
		"retry restores the normalized defense-zone placement slot"
	)
	_expect(
		not bool(restored.get("connector_state", {}).get("built", true)),
		"legacy retry keeps the connector unbuilt"
	)


func _candidate_plan() -> Dictionary:
	return {
		"layout_id": "stage01_dual_front_candidate_01",
		"layout_fingerprint": "a".repeat(64),
		"active_route": [
			"outside_approach",
			"entrance",
			"spike_corridor",
			"lane_a_rear",
			"throne_antechamber",
			"throne"
		],
		"lane_routes": {
			"lane_a": [
				"outside_approach",
				"entrance",
				"spike_corridor",
				"lane_a_rear",
				"throne_antechamber",
				"throne"
			],
			"lane_b": [
				"outside_approach_b",
				"service_entrance",
				"lane_b_front",
				"lane_b_rear",
				"throne_antechamber",
				"throne"
			]
		},
		"enemy_goals": ["throne"],
		"defender_connector": {
			"connector_id": "rear_cross_lane_connector",
			"from_zone_id": "zone_a_rear",
			"to_zone_id": "zone_b_rear",
			"from_lane_id": "lane_a",
			"to_lane_id": "lane_b",
			"from_room_id": "lane_a_rear",
			"to_room_id": "lane_b_rear",
			"world_anchor": [3, 0.5],
			"route_points": [[3, 0], [3, 0.5], [3, 1]],
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
			{
				"zone_id": "zone_a_front",
				"lane_id": "lane_a",
				"anchor_room_id": "spike_corridor",
				"room_ids": ["spike_corridor"]
			},
			{
				"zone_id": "zone_a_rear",
				"lane_id": "lane_a",
				"anchor_room_id": "lane_a_rear",
				"room_ids": ["lane_a_rear"]
			},
			{
				"zone_id": "zone_b_front",
				"lane_id": "lane_b",
				"anchor_room_id": "lane_b_front",
				"room_ids": ["lane_b_front"]
			},
			{
				"zone_id": "zone_b_rear",
				"lane_id": "lane_b",
				"anchor_room_id": "lane_b_rear",
				"room_ids": ["lane_b_rear"]
			},
			{
				"zone_id": "zone_throne_antechamber",
				"lane_id": "merge",
				"anchor_room_id": "throne_antechamber",
				"room_ids": ["throne_antechamber"]
			}
		],
		"facility_slot_contracts": [
			{
				"slot_id": "facility_a_front",
				"room_id": "barracks",
				"linked_zone_ids": ["zone_a_front"]
			}
		],
		"facility_slots": [
			{
				"slot_id": "facility_a_front",
				"room_id": "barracks",
				"facility_role": "barracks"
			}
		],
		"facility_placements": [
			{
				"placement_id": "facility_placement:facility_a_front",
				"facility_slot_id": "facility_a_front",
				"room_id": "barracks",
				"facility_role": "treasure"
			}
		],
		"monster_slots": [
			{
				"slot_id": "monster:zone_a_front:1",
				"defense_zone_id": "zone_a_front",
				"room_id": "spike_corridor"
			}
		],
		"monster_placements": [
			{
				"monster_instance_id": "slime",
				"room_id": "spike_corridor",
				"defense_zone_id": "zone_a_front",
				"slot_id": "monster:zone_a_front:1"
			}
		],
		"defense_segments": [{"segment_id": "front"}],
		"world_anchors": {
			"outside_approach": [0, 0],
			"entrance": [1, 0],
			"spike_corridor": [2, 0],
			"lane_a_rear": [3, 0],
			"outside_approach_b": [0, 1],
			"service_entrance": [1, 1],
			"lane_b_front": [2, 1],
			"lane_b_rear": [3, 1],
			"throne_antechamber": [4, 0],
			"throne": [5, 0],
			"barracks": [2, -1]
		}
	}


func _legacy_state() -> Dictionary:
	var legacy_facility := {
		"slot_id": "facility:barracks",
		"room_id": "barracks",
		"facility_role": "treasure"
	}
	var legacy_monsters := [
		{
			"monster_instance_id": "slime",
			"room_id": "barracks",
			"slot_id": "monster:barracks:1"
		},
		{
			"monster_instance_id": "guard",
			"room_id": "throne",
			"slot_id": "monster:throne:0"
		}
	]
	var placements := {
		"layout_id": "legacy_stage01",
		"layout_fingerprint": "b".repeat(64),
		"facility_placements": [legacy_facility.duplicate(true)],
		"monster_placements": legacy_monsters.duplicate(true)
	}
	return {
		"schema_version": 1,
		"battle_plan": _legacy_plan(),
		"facility_placements": [legacy_facility.duplicate(true)],
		"monster_placements": legacy_monsters.duplicate(true),
		"last_confirmed_placements": placements.duplicate(true),
		"retry_snapshot": {
			"day": 3,
			"layout_id": "legacy_stage01",
			"layout_fingerprint": "b".repeat(64),
			"facility_placements": [legacy_facility.duplicate(true)],
			"monster_placements": legacy_monsters.duplicate(true),
			"global_directive": "guard",
			"room_directives": {}
		}
	}


func _legacy_plan() -> Dictionary:
	return {
		"layout_id": "legacy_stage01",
		"layout_fingerprint": "b".repeat(64),
		"active_route": ["outside_approach", "entrance", "barracks", "throne"],
		"enemy_goals": ["throne"],
		"facility_slots": [
			{
				"slot_id": "facility:barracks",
				"room_id": "barracks",
				"facility_role": "barracks"
			}
		],
		"facility_placements": [
			{
				"slot_id": "facility:barracks",
				"room_id": "barracks",
				"facility_role": "barracks"
			}
		],
		"monster_slots": [
			{
				"slot_id": "monster:barracks:1",
				"room_id": "barracks"
			}
		],
		"monster_placements": [
			{
				"monster_instance_id": "slime",
				"room_id": "barracks",
				"slot_id": "monster:barracks:1"
			}
		],
		"defense_segments": [{"segment_id": "front"}],
		"world_anchors": {
			"outside_approach": [0, 0],
			"entrance": [1, 0],
			"barracks": [2, 0],
			"throne": [3, 0]
		}
	}


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
