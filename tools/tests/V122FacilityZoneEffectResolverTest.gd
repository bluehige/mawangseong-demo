extends Node

const Resolver = preload("res://scripts/v122/spatial/V122FacilityZoneEffectResolver.gd")
const LAYOUT_PATH := "res://data/dungeon_quarter/layouts/stage01_dual_front_01.json"

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var layout := _load_json(LAYOUT_PATH)
	var topology: Dictionary = layout.get("combat_topology", {})
	var catalog := Resolver.load_catalog()
	_expect(not topology.is_empty(), "dual-front combat topology loads")
	_expect(int(catalog.get("schema_version", 0)) == 1, "facility effect catalog schema loads")
	_expect(
		catalog.get("supported_scopes", []) == ["local", "adjacent", "lane", "global"],
		"all approved zone scopes are declared"
	)
	_expect(
		catalog.get("supported_targets", []) == ["allies", "enemies", "facilities", "path"],
		"all approved effect targets are declared"
	)

	var defaults := _default_facility_states(topology)
	var default_effects := Resolver.resolve_by_zone(topology, defaults, catalog)
	_expect(default_effects.size() == 5, "resolver returns every fixed defense zone")
	_expect(_has_effect(default_effects, "zone_a_front", "placement_capacity", "allies"), "barracks adds local placement capacity")
	_expect(_has_effect(default_effects, "zone_a_front", "attack", "allies"), "barracks adds local combat power")
	_expect(_has_effect(default_effects, "zone_a_front", "defense", "allies"), "barracks adds local damage protection")
	_expect(_has_effect(default_effects, "zone_a_rear", "healing", "allies"), "recovery heals its linked zone")
	_expect(default_effects.get("zone_b_front", []).is_empty(), "empty build slot has no combat effect")
	_expect(default_effects.get("zone_b_rear", []).is_empty(), "treasure remains economy-only")
	_expect(default_effects.get("zone_throne_antechamber", []).is_empty(), "local facilities do not leak into the antechamber")

	var scoped_effects := Resolver.resolve_by_zone(topology, [
		{"slot_id": "facility_a_front", "facility_role": "watch_post"},
		{"slot_id": "facility_b_front", "facility_role": "ward_core"}
	], catalog)
	_expect(_has_effect(scoped_effects, "zone_a_front", "slow", "enemies"), "watch slow applies to its local zone")
	_expect(not _has_effect(scoped_effects, "zone_a_rear", "slow", "enemies"), "watch slow does not leak beyond local")
	_expect(_has_effect(scoped_effects, "zone_a_front", "detection", "enemies"), "watch exposes its front lane zone")
	_expect(_has_effect(scoped_effects, "zone_a_rear", "detection", "enemies"), "watch exposes the rest of its lane")
	_expect(_has_effect(scoped_effects, "zone_a_rear", "exposure", "enemies"), "watch exposure has a real lane-wide damage consequence")
	_expect(not _has_effect(scoped_effects, "zone_b_front", "detection", "enemies"), "lane scope does not cross to the other lane")
	for zone_id in topology.get("defense_zones", []).map(func(zone): return str(zone.get("zone_id", ""))):
		_expect(_has_effect(scoped_effects, zone_id, "defense", "allies"), "ward applies globally to %s" % zone_id)

	var adjacent_catalog: Dictionary = catalog.duplicate(true)
	var recovery_rule: Dictionary = adjacent_catalog.get("facilities", {}).get("recovery", {})
	var recovery_effects: Array = recovery_rule.get("effects", [])
	recovery_effects[0]["scope"] = "adjacent"
	var adjacent_effects := Resolver.resolve_by_zone(topology, [
		{"slot_id": "facility_a_front", "facility_role": "recovery"}
	], adjacent_catalog)
	_expect(_has_effect(adjacent_effects, "zone_a_front", "healing", "allies"), "adjacent scope includes the linked zone")
	_expect(_has_effect(adjacent_effects, "zone_a_rear", "healing", "allies"), "adjacent scope includes directly adjacent zones")
	_expect(not _has_effect(adjacent_effects, "zone_throne_antechamber", "healing", "allies"), "adjacent scope is one hop only")

	var strongest_effects := Resolver.resolve_by_zone(topology, [
		{"slot_id": "facility_a_front", "facility_role": "ward_core"},
		{"slot_id": "facility_b_rear", "facility_role": "ward_core", "power_multiplier": 1.4}
	], catalog)
	var strongest_defense := _effect(strongest_effects, "zone_a_front", "defense", "allies")
	_expect(_effect_count(strongest_effects, "zone_a_front", "defense", "allies") == 1, "same category keeps one strongest effect")
	_expect(str(strongest_defense.get("source_slot_id", "")) == "facility_b_rear", "stronger source wins regardless of slot order")
	_expect(is_equal_approx(float(strongest_defense.get("value", 0.0)), 0.86), "multiplier strength scales from the neutral value")

	var tied_forward := Resolver.resolve_by_zone(topology, [
		{"slot_id": "facility_b_rear", "facility_role": "ward_core"},
		{"slot_id": "facility_a_front", "facility_role": "ward_core"}
	], catalog)
	var tied_reverse := Resolver.resolve_by_zone(topology, [
		{"slot_id": "facility_a_front", "facility_role": "ward_core"},
		{"slot_id": "facility_b_rear", "facility_role": "ward_core"}
	], catalog)
	_expect(
		str(_effect(tied_forward, "zone_b_front", "defense", "allies").get("source_slot_id", "")) == "facility_a_front",
		"equal strength uses the stable source-slot tie break"
	)
	_expect(tied_forward == tied_reverse, "tie resolution is independent of facility input order")

	var disabled_effects := Resolver.resolve_by_zone(topology, [
		{"slot_id": "facility_a_front", "facility_role": "ward_core", "power_multiplier": 2.0, "disabled_remaining": 3.0},
		{"slot_id": "facility_b_rear", "facility_role": "ward_core"}
	], catalog)
	_expect(
		str(_effect(disabled_effects, "zone_a_front", "defense", "allies").get("source_slot_id", "")) == "facility_b_rear",
		"disabled facilities contribute no effect"
	)
	var only_disabled := Resolver.resolve_by_zone(topology, [
		{"slot_id": "facility_a_front", "facility_role": "ward_core", "disabled": true}
	], catalog)
	_expect(only_disabled.get("zone_a_front", []).is_empty(), "a disabled-only zone remains effect-free")

	if failed:
		print("V122_FACILITY_ZONE_EFFECT_RESOLVER_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_FACILITY_ZONE_EFFECT_RESOLVER_TEST: PASS")
		get_tree().quit(0)


func _default_facility_states(topology: Dictionary) -> Array:
	var result: Array = []
	for slot_value in topology.get("facility_slots", []):
		var slot: Dictionary = slot_value
		result.append({
			"slot_id": str(slot.get("slot_id", "")),
			"facility_role": str(slot.get("default_facility_role", ""))
		})
	return result


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _has_effect(
	resolved_by_zone: Dictionary,
	zone_id: String,
	category: String,
	target: String
) -> bool:
	return not _effect(resolved_by_zone, zone_id, category, target).is_empty()


func _effect(
	resolved_by_zone: Dictionary,
	zone_id: String,
	category: String,
	target: String
) -> Dictionary:
	for effect_value in resolved_by_zone.get(zone_id, []):
		if not effect_value is Dictionary:
			continue
		var effect: Dictionary = effect_value
		if str(effect.get("category", "")) == category and str(effect.get("target", "")) == target:
			return effect
	return {}


func _effect_count(
	resolved_by_zone: Dictionary,
	zone_id: String,
	category: String,
	target: String
) -> int:
	var count := 0
	for effect_value in resolved_by_zone.get(zone_id, []):
		if effect_value is Dictionary:
			var effect: Dictionary = effect_value
			if str(effect.get("category", "")) == category and str(effect.get("target", "")) == target:
				count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
