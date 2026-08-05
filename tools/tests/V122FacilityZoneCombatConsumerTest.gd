extends Node

const CombatSceneControllerScript = preload("res://scripts/game/CombatSceneController.gd")
const Constants = preload("res://scripts/core/Constants.gd")

var failed := false


class FakeUnit:
	extends Node

	var faction := ""
	var current_room := ""
	var assigned_room := ""
	var unit_id := ""
	var display_name := ""
	var hp := 100
	var down := false
	var slow_timer := 0.0
	var last_slow_factor := 1.0
	var last_slow_seconds := 0.0

	func is_alive() -> bool:
		return not down and hp > 0

	func apply_slow(seconds: float, factor: float) -> void:
		last_slow_seconds = seconds
		last_slow_factor = factor
		slow_timer = seconds

	func heal(amount: int) -> void:
		hp = mini(100, hp + amount)


class FakeRoot:
	extends Node

	var rooms := {
		"facility_room_a_front": {"facility_role": "barracks"},
		"facility_room_a_rear": {"facility_role": "recovery"},
		"facility_room_b_front": {"facility_role": "watch_post"},
		"facility_room_b_rear": {"facility_role": "ward_core"},
		"room_a_front": {},
		"room_a_rear": {},
		"room_b_front": {},
		"room_b_rear": {},
		"room_merge": {}
	}
	var facility_disabled_timers: Dictionary = {}
	var monster_units: Array = []
	var enemy_units: Array = []
	var facility_stats: Dictionary = {}
	var global_directive := ""

	func _facility_room_is_active(room_id: String) -> bool:
		return rooms.has(room_id) and float(facility_disabled_timers.get(room_id, 0.0)) <= 0.0

	func _castle_facility_scale(key: String, fallback: float = 1.0) -> float:
		return 0.9 if key == "ward_damage_taken_scale" else fallback

	func _facility_is_active(facility_role: String) -> bool:
		for room_id_value in rooms.keys():
			var room_id := str(room_id_value)
			if (
				str(rooms[room_id].get("facility_role", "")) == facility_role
				and _facility_room_is_active(room_id)
			):
				return true
		return false

	func _rooms_by_facility(facility_role: String) -> Array[String]:
		var result: Array[String] = []
		for room_id_value in rooms.keys():
			var room_id := str(room_id_value)
			if str(rooms[room_id].get("facility_role", "")) == facility_role:
				result.append(room_id)
		return result

	func _record_facility_effect_stat(key: String, amount) -> void:
		facility_stats[key] = float(facility_stats.get(key, 0.0)) + float(amount)

	func _update3_modify_monster_damage(_target: Node, damage: int) -> int:
		return damage

	func display_name_for_instance(instance_id: String) -> String:
		return instance_id

	func _facility_short_label(facility_role: String) -> String:
		return facility_role


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var fake_root := FakeRoot.new()
	add_child(fake_root)
	var controller = CombatSceneControllerScript.new()
	controller.setup(fake_root, null)
	fake_root.set_meta("v122_battle_plan", _zone_plan())
	fake_root.set_meta("v122_command_state", {"active_commands": {}})

	var attacker_a := _unit(Constants.FACTION_MONSTER, "room_a_front", "monster_a")
	var attacker_a_gap := _unit(Constants.FACTION_MONSTER, "path_a_gap", "monster_a_gap")
	var attacker_b := _unit(Constants.FACTION_MONSTER, "room_b_rear", "monster_b")
	var enemy_b_front := _unit(Constants.FACTION_ENEMY, "room_b_front", "enemy_b_front")
	var enemy_b_rear := _unit(Constants.FACTION_ENEMY, "room_b_rear", "enemy_b_rear")
	var enemy_a := _unit(Constants.FACTION_ENEMY, "room_a_front", "enemy_a")
	var defender_a := _unit(Constants.FACTION_MONSTER, "room_a_front", "defender_a")
	var defender_a_rear := _unit(Constants.FACTION_MONSTER, "room_a_rear", "defender_a_rear")

	_expect(controller._v122_uses_zone_facility_effects(), "explicit zones and linked facility slots enable the zone consumer")
	_expect(controller._v122_zone_id_for_room("path_a_gap") == "zone_a_front", "lane path gaps map deterministically to the nearest defense zone")
	_expect(controller._v122_zone_id_for_room("shared_path") == "zone_merge", "shared lane-merge rooms map to the merge zone")
	var combined_attack := controller._facility_attack_multiplier(attacker_a, enemy_b_rear)
	_expect(is_equal_approx(combined_attack, 1.1 * 1.12), "barracks attack and watch exposure affect the actual attack multiplier")
	_expect(is_equal_approx(controller._facility_attack_multiplier(attacker_a_gap, enemy_a), 1.1), "lane path gaps retain their nearest-zone facility effect")
	_expect(is_equal_approx(controller._facility_attack_multiplier(attacker_b, enemy_b_rear), 1.12), "barracks does not leak to another zone")
	_expect(controller._apply_facility_damage_taken_modifier(enemy_a, defender_a, 100) == 90, "same-category defense keeps the strongest ward effect")
	_expect(controller._apply_facility_damage_taken_modifier(enemy_a, defender_a_rear, 100) == 90, "ward applies globally without local barracks")
	_expect(float(fake_root.facility_stats.get("ward_damage_reduced", 0.0)) == 20.0, "ward reductions are recorded under the ward role")
	_expect(not fake_root.facility_stats.has("barracks_damage_reduced"), "ward reductions are not mislabeled as barracks reductions")
	fake_root.set_meta("v122_command_state", {
		"active_commands": {
			"rally": {
				"target": {"type": "defense_zone", "id": "zone_a_front", "room_ids": ["room_a_front"]},
				"effect": {"damage_taken_multiplier": 0.9}
			}
		}
	})
	var facility_only_damage := controller._apply_facility_damage_taken_modifier(enemy_a, defender_a, 100)
	_expect(facility_only_damage == 90, "facility damage reduction excludes command reduction")
	_expect(controller._apply_command_damage_taken_modifier(defender_a, facility_only_damage) == 81, "command reduction is applied in its separate stage")
	fake_root.set_meta("v122_command_state", {"active_commands": {}})
	_expect(is_equal_approx(controller._v122_zone_recovery_rate(defender_a_rear), 8.0), "recovery affects its linked defense zone")
	_expect(is_zero_approx(controller._v122_zone_recovery_rate(defender_a)), "recovery does not follow the facility room through adjacency")

	controller._v122_apply_zone_watch_effect(enemy_b_front)
	_expect(is_equal_approx(enemy_b_front.last_slow_factor, 0.82), "watch applies its actual movement slow in the local zone")
	_expect(bool(enemy_b_front.get_meta("v122_facility_revealed", false)), "watch marks a local enemy as revealed")
	controller._v122_apply_zone_watch_effect(enemy_b_rear)
	_expect(is_equal_approx(enemy_b_rear.last_slow_factor, 1.0), "watch slow remains local")
	_expect(bool(enemy_b_rear.get_meta("v122_facility_revealed", false)), "watch reveal covers the full lane")
	controller._v122_apply_zone_watch_effect(enemy_a)
	_expect(not bool(enemy_a.get_meta("v122_facility_revealed", true)), "watch reveal does not cross lanes")

	fake_root.facility_disabled_timers["facility_room_b_front"] = 3.0
	controller._v122_apply_zone_watch_effect(enemy_b_rear)
	_expect(not bool(enemy_b_rear.get_meta("v122_facility_revealed", true)), "disabled watch immediately loses reveal")
	_expect(is_equal_approx(controller._facility_attack_multiplier(attacker_b, enemy_b_rear), 1.0), "disabled watch loses additional damage")
	fake_root.facility_disabled_timers.erase("facility_room_b_front")

	fake_root.facility_disabled_timers["facility_room_b_rear"] = 3.0
	_expect(controller._apply_facility_damage_taken_modifier(enemy_a, defender_a_rear, 100) == 100, "disabled ward contributes no defense")
	_expect(controller._apply_facility_damage_taken_modifier(enemy_a, defender_a, 100) == 92, "barracks guard remains when the stronger ward is disabled")
	fake_root.facility_disabled_timers.erase("facility_room_b_rear")

	var two_barracks_plan := _zone_plan()
	two_barracks_plan["facility_slots"][3]["facility_role"] = "barracks"
	fake_root.rooms["facility_room_b_rear"]["facility_role"] = "barracks"
	fake_root.set_meta("v122_battle_plan", two_barracks_plan)
	fake_root.set_meta("v122_command_state", {
		"active_commands": {
			"activate_facility": {
				"target": {
					"type": "facility",
					"id": "facility_a_front",
					"facility_slot_id": "facility_a_front",
					"room_id": "facility_room_a_front",
					"facility_role": "barracks"
				},
				"effect": {"facility_power_multiplier": 1.35}
			}
		}
	})
	_expect(is_equal_approx(controller._facility_attack_multiplier(attacker_a, enemy_a), 1.135), "facility activation strengthens the selected slot")
	_expect(is_equal_approx(controller._facility_attack_multiplier(attacker_b, enemy_a), 1.1), "same-role facility in another slot is not strengthened")

	controller.pending_v122_command_id = "rally"
	var zone_candidates: Array = controller._v122_command_target_candidates()
	_expect(zone_candidates.size() == 5, "rally exposes five direct-map defense-zone candidates")
	var first_zone: Dictionary = zone_candidates.front()
	_expect(
		first_zone.has("id")
		and first_zone.has("anchor_room_id")
		and first_zone.has("room_id")
		and first_zone.has("room_ids")
		and first_zone.has("world_anchor"),
		"defense-zone candidate carries the complete map-target contract"
	)
	controller.pending_v122_command_id = "activate_facility"
	var facility_candidates: Array = controller._v122_command_target_candidates()
	var first_facility: Dictionary = facility_candidates.front()
	_expect(str(first_facility.get("id", "")) == str(first_facility.get("facility_slot_id", "")), "facility candidate ID prefers the slot ID")
	_expect(str(first_facility.get("room_id", "")) != "", "facility candidate retains its separate room ID")
	_expect(str(first_facility.get("facility_instance_id", "")) == str(first_facility.get("room_id", "")), "facility candidate exposes its spatial instance ID")

	var incomplete_plan := _zone_plan()
	incomplete_plan["facility_slots"][0].erase("linked_zone_ids")
	fake_root.set_meta("v122_battle_plan", incomplete_plan)
	_expect(not controller._v122_uses_zone_facility_effects(), "an incomplete zone contract falls back to legacy behavior")

	var legacy_plan := {
		"defense_zones": [],
		"defense_segments": [{
			"segment_id": "legacy_front",
			"entry_room_id": "room_a_front",
			"room_ids": ["room_a_front"]
		}],
		"facility_slots": [],
		"world_anchors": {"room_a_front": [10.0, 20.0]}
	}
	fake_root.set_meta("v122_battle_plan", legacy_plan)
	controller.pending_v122_command_id = "rally"
	var legacy_candidates: Array = controller._v122_command_target_candidates()
	_expect(legacy_candidates.size() == 1, "legacy defense segments remain valid direct-map command zones")
	_expect(str(legacy_candidates[0].get("id", "")) == "legacy_front", "legacy segment ID is preserved as its zone ID")

	if failed:
		print("V122_FACILITY_ZONE_COMBAT_CONSUMER_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_FACILITY_ZONE_COMBAT_CONSUMER_TEST: PASS")
		get_tree().quit(0)


func _zone_plan() -> Dictionary:
	return {
		"defense_zones": [
			{"zone_id": "zone_a_front", "lane_id": "lane_a", "anchor_room_id": "room_a_front", "room_ids": ["room_a_front"], "adjacent_zone_ids": ["zone_a_rear"]},
			{"zone_id": "zone_a_rear", "lane_id": "lane_a", "anchor_room_id": "room_a_rear", "room_ids": ["room_a_rear"], "adjacent_zone_ids": ["zone_a_front", "zone_merge"]},
			{"zone_id": "zone_b_front", "lane_id": "lane_b", "anchor_room_id": "room_b_front", "room_ids": ["room_b_front"], "adjacent_zone_ids": ["zone_b_rear"]},
			{"zone_id": "zone_b_rear", "lane_id": "lane_b", "anchor_room_id": "room_b_rear", "room_ids": ["room_b_rear"], "adjacent_zone_ids": ["zone_b_front", "zone_merge"]},
			{"zone_id": "zone_merge", "lane_id": "merge", "anchor_room_id": "room_merge", "room_ids": ["room_merge"], "adjacent_zone_ids": ["zone_a_rear", "zone_b_rear"]}
		],
		"facility_slots": [
			{"slot_id": "facility_a_front", "room_id": "facility_room_a_front", "lane_id": "lane_a", "facility_role": "barracks", "linked_zone_ids": ["zone_a_front"], "world_anchor": [1.0, 1.0], "object_id": "barracks_object"},
			{"slot_id": "facility_a_rear", "room_id": "facility_room_a_rear", "lane_id": "lane_a", "facility_role": "recovery", "linked_zone_ids": ["zone_a_rear"], "world_anchor": [2.0, 2.0], "object_id": "recovery_object"},
			{"slot_id": "facility_b_front", "room_id": "facility_room_b_front", "lane_id": "lane_b", "facility_role": "watch_post", "linked_zone_ids": ["zone_b_front"], "world_anchor": [3.0, 3.0], "object_id": "watch_object"},
			{"slot_id": "facility_b_rear", "room_id": "facility_room_b_rear", "lane_id": "lane_b", "facility_role": "ward_core", "linked_zone_ids": ["zone_b_rear"], "world_anchor": [4.0, 4.0], "object_id": "ward_object"}
		],
		"lane_routes": {
			"lane_a": ["outside_a", "room_a_front", "path_a_gap", "room_a_rear", "shared_path", "room_merge", "throne"],
			"lane_b": ["outside_b", "room_b_front", "path_b_gap", "room_b_rear", "shared_path", "room_merge", "throne"]
		},
		"world_anchors": {
			"room_a_front": [10.0, 10.0],
			"room_a_rear": [20.0, 20.0],
			"room_b_front": [30.0, 30.0],
			"room_b_rear": [40.0, 40.0],
			"room_merge": [50.0, 50.0]
		}
	}


func _unit(faction: String, room_id: String, unit_id: String) -> FakeUnit:
	var unit := FakeUnit.new()
	unit.faction = faction
	unit.current_room = room_id
	unit.assigned_room = room_id
	unit.unit_id = unit_id
	unit.display_name = unit_id
	add_child(unit)
	return unit


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
