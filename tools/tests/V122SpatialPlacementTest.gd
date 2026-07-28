extends Node

const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const BattlePlanAdapter = preload("res://scripts/v122/spatial/V122BattlePlanAdapter.gd")
const PlacementSlotAdapter = preload("res://scripts/v122/spatial/V122PlacementSlotAdapter.gd")

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_check_explicit_monster_slot_stability()
	var stages := [
		{"id": "stage_01_cave", "day": 1, "expansions": []},
		{"id": "stage_02_castle", "day": 10, "expansions": ["stage_02_castle"]},
		{"id": "stage_03_keep", "day": 20, "expansions": ["stage_02_castle", "stage_03_keep"]},
		{"id": "stage_04_citadel", "day": 30, "expansions": ["stage_02_castle", "stage_03_keep", "stage_04_citadel"]}
	]
	for stage_value in stages:
		var stage: Dictionary = stage_value
		var state := _expanded_state(stage.get("expansions", []))
		var graph = ModuleGraphScript.new()
		graph.setup_quarter(DataRegistry.quarter_modules, state["layout"], state["rooms"])
		_expect(bool(graph.validation_summary().get("ok", false)), "%s ModuleGraph is valid: %s" % [stage["id"], graph.validation_summary()])
		var roster := {
			"mon_core_pudding": {"species_id": "slime", "room": "barracks"},
			"mon_core_gob": {"species_id": "goblin", "room": "recovery"}
		}
		var snapshot := BattlePlanAdapter.build_snapshot(
			graph,
			str(stage["id"]),
			state["rooms"],
			roster,
			["throne"],
			int(stage["day"])
		)
		_expect(BattlePlanAdapter.validate_snapshot(snapshot).is_empty(), "%s snapshot validates: %s" % [stage["id"], BattlePlanAdapter.validate_snapshot(snapshot)])
		_expect(snapshot["active_route"] == graph.path_between("outside_approach", "throne"), "%s uses the product route from the real enemy entry" % stage["id"])
		_expect(snapshot["world_anchors"]["barracks"] == _vector_array(graph.center("barracks")), "%s management and combat room anchors match" % stage["id"])
		var pudding := _monster_placement(snapshot, "mon_core_pudding")
		_expect(pudding.get("world_anchor", []) == _vector_array(graph.center("barracks") + Vector2(-18.0, 6.0)), "%s first monster spawn derives from its assigned room" % stage["id"])
		_expect(snapshot["defense_segments"].size() == (4 if int(stage["day"]) <= 5 else clampi(int(round(snapshot["active_route"].size() / 2.0)), 3, 6)), "%s defense segment count follows the day rule" % stage["id"])
		var restored := BattlePlanAdapter.build_snapshot(graph, str(stage["id"]), state["rooms"], roster.duplicate(true), ["throne"], int(stage["day"]))
		_expect(snapshot["layout_fingerprint"] == restored["layout_fingerprint"], "%s save/load layout fingerprint is stable" % stage["id"])
		_expect(snapshot["monster_placements"] == restored["monster_placements"], "%s save/load monster placements are stable" % stage["id"])
		if str(stage["id"]) == "stage_04_citadel":
			_expect(snapshot["rooms"].has("watch_post_01"), "stage 4 retains the stage 2 watch post")
			_expect(snapshot["rooms"].has("ward_core_01"), "stage 4 retains the stage 3 ward core")

	var custom_state := _expanded_state([])
	var custom_graph = ModuleGraphScript.new()
	custom_graph.setup_quarter(DataRegistry.quarter_modules, custom_state["layout"], custom_state["rooms"])
	var custom_snapshot := BattlePlanAdapter.build_snapshot(custom_graph, "user_fixture_layout", custom_state["rooms"], {}, ["throne"], 6)
	_expect(str(custom_snapshot.get("layout_source", "")) == "user_custom", "custom layouts are explicitly supported without a zone translation table")

	if failed:
		print("V122_SPATIAL_PLACEMENT_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_SPATIAL_PLACEMENT_TEST: PASS")
		get_tree().quit(0)


func _check_explicit_monster_slot_stability() -> void:
	var state := _expanded_state([])
	state["rooms"]["barracks"]["max_monsters"] = 5
	var graph = ModuleGraphScript.new()
	graph.setup_quarter(DataRegistry.quarter_modules, state["layout"], state["rooms"])
	var roster := {
		"mon_a_missing": {"species_id": "slime", "room": "barracks"},
		"mon_b_explicit": {"species_id": "goblin", "room": "barracks", "placement_slot_id": "monster:barracks:0"},
		"mon_c_explicit": {"species_id": "imp", "room": "barracks", "placement_slot_id": "monster:barracks:2"},
		"mon_d_conflict": {"species_id": "slime", "room": "barracks", "placement_slot_id": "monster:barracks:2"},
		"mon_e_wrong_room": {"species_id": "goblin", "room": "barracks", "placement_slot_id": "monster:recovery:0"}
	}
	var placements: Dictionary = PlacementSlotAdapter.build(graph, state["rooms"], roster)
	_expect(_monster_placement(placements, "mon_b_explicit").get("slot_id", "") == "monster:barracks:0", "valid explicit slot 0 remains reserved")
	_expect(_monster_placement(placements, "mon_c_explicit").get("slot_id", "") == "monster:barracks:2", "valid explicit slot 2 remains reserved")
	_expect(_monster_placement(placements, "mon_a_missing").get("slot_id", "") == "monster:barracks:1", "missing slot uses first empty slot after explicit reservations")
	_expect(_monster_placement(placements, "mon_d_conflict").get("slot_id", "") == "monster:barracks:3", "conflicting slot deterministically uses next empty slot")
	_expect(_monster_placement(placements, "mon_e_wrong_room").get("slot_id", "") == "monster:barracks:4", "slot from another room is corrected to first empty local slot")

	var reversed_roster := {
		"mon_e_wrong_room": roster["mon_e_wrong_room"].duplicate(true),
		"mon_d_conflict": roster["mon_d_conflict"].duplicate(true),
		"mon_c_explicit": roster["mon_c_explicit"].duplicate(true),
		"mon_b_explicit": roster["mon_b_explicit"].duplicate(true),
		"mon_a_missing": roster["mon_a_missing"].duplicate(true)
	}
	var reversed_placements: Dictionary = PlacementSlotAdapter.build(graph, state["rooms"], reversed_roster)
	_expect(placements["monster_placements"] == reversed_placements["monster_placements"], "slot correction is independent of dictionary insertion order")

	var restored_roster := roster.duplicate(true)
	for placement_value in placements.get("monster_placements", []):
		var placement: Dictionary = placement_value
		var monster_id := str(placement.get("monster_instance_id", ""))
		restored_roster[monster_id]["placement_slot_id"] = str(placement.get("slot_id", ""))
	var restored: Dictionary = PlacementSlotAdapter.build(graph, state["rooms"], restored_roster)
	_expect(placements["monster_placements"] == restored["monster_placements"], "corrected placement slot IDs are stable after save/load")


func _expanded_state(expansion_ids: Array) -> Dictionary:
	var rooms: Dictionary = DataRegistry.rooms.duplicate(true)
	var layout: Dictionary = DataRegistry.quarter_starting_layout.duplicate(true)
	for stage_id_value in expansion_ids:
		var expansion: Dictionary = DataRegistry.castle_stage_expansion(str(stage_id_value))
		for room_id_value in expansion.get("rooms", {}).keys():
			rooms[str(room_id_value)] = expansion.get("rooms", {}).get(room_id_value).duplicate(true)
		layout["placed_modules"].append_array(expansion.get("placed_modules", []).duplicate(true))
		layout["connections"].append_array(expansion.get("connections", []).duplicate(true))
		layout["required_paths"].append_array(expansion.get("required_paths", []).duplicate(true))
	return {"rooms": rooms, "layout": layout}


func _vector_array(value: Vector2) -> Array:
	return [snappedf(value.x, 0.001), snappedf(value.y, 0.001)]


func _monster_placement(snapshot: Dictionary, monster_instance_id: String) -> Dictionary:
	for value in snapshot.get("monster_placements", []):
		if value is Dictionary and str(value.get("monster_instance_id", "")) == monster_instance_id:
			return value
	return {}


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
