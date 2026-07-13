extends RefCounted
class_name NewCycleService

const SPECIES_TO_INSTANCE := {
	"slime": "mon_core_pudding",
	"goblin": "mon_core_gob",
	"imp": "mon_core_pynn",
	"kobold_scout": "mon_core_rolo",
	"spore_healer": "mon_contract_mori",
	"stone_sentinel": "mon_contract_dolkong",
	"war_drummer": "mon_contract_dudum",
	"moon_tracker": "mon_contract_lumi",
	"mimic_porter": "mon_contract_mimi"
}
const ENDING_CATALOG_CODES := {
	"true_demon_castle": "E00",
	"monster_family_castle": "E01",
	"impregnable_demon_citadel": "E02",
	"dread_overlord_rises": "E03",
	"demon_hero_rival_pact": "E04",
	"contract_monster_alliance": "E05",
	"royal_doctrine_broken": "E06",
	"challenge_seal_legend": "E07",
	"evelyns_counterledger": "E08",
	"adaptive_rival_mastery": "E09",
	"castle_without_reserves": "E10",
	"twelve_endings_chronicle": "E11",
	"ending_holy_open_gate": "E12",
	"ending_off_ledger_independence": "E13",
	"ending_living_castle_voice": "E14",
	"ending_linked_corridors": "E15",
	"ending_three_front_armistice": "E16"
}


static func default_profile() -> Dictionary:
	return {
		"profile_version": 2,
		"profile_id": "profile_default",
		"completed_cycles": 0,
		"ending_archive": {},
		"unlocked_memory_ids": [],
		"seen_event_ids": [],
		"unlocked_contract_ids": [],
		"contract_history": [],
		"active_doctrine_id": "",
		"doctrine_history": [],
		"active_decree_id": "",
		"decree_history": [],
		"active_challenge_seal_id": "",
		"challenge_seal_history": [],
		"leon_stance_history": [],
		"ending_catalog_codes": {},
		"legacy_monster": {}
	}


static func normalize_profile(value) -> Dictionary:
	var profile := default_profile()
	if not (value is Dictionary):
		return profile
	for key in profile.keys():
		if key == "completed_cycles" and (value.get(key) is int or value.get(key) is float):
			profile[key] = int(value.get(key))
			continue
		if value.has(key) and typeof(value.get(key)) == typeof(profile.get(key)):
			profile[key] = _copy_value(value.get(key))
	profile["profile_version"] = 2
	if str(profile.get("profile_id", "")) == "":
		profile["profile_id"] = "profile_default"
	profile["completed_cycles"] = maxi(0, int(profile.get("completed_cycles", 0)))
	return profile


static func complete_cycle(profile_value, ending_id: String, metrics: Dictionary, legacy_candidate: Dictionary) -> Dictionary:
	var profile := normalize_profile(profile_value)
	var completed_cycle := int(profile.get("completed_cycles", 0)) + 1
	profile["completed_cycles"] = completed_cycle
	var archive: Dictionary = profile.get("ending_archive", {})
	var archive_entry: Dictionary = archive.get(ending_id, {})
	if archive_entry.is_empty():
		archive_entry["first_seen_cycle"] = completed_cycle
	archive_entry["seen_count"] = int(archive_entry.get("seen_count", 0)) + 1
	archive_entry["last_seen_cycle"] = completed_cycle
	archive_entry["last_metrics"] = metrics.duplicate(true)
	archive[ending_id] = archive_entry
	profile["ending_archive"] = archive
	var catalog_codes: Dictionary = profile.get("ending_catalog_codes", {})
	if ENDING_CATALOG_CODES.has(ending_id):
		catalog_codes[ending_id] = ENDING_CATALOG_CODES[ending_id]
	profile["ending_catalog_codes"] = catalog_codes

	var species_id := str(legacy_candidate.get("species_id", ""))
	var instance_id := str(SPECIES_TO_INSTANCE.get(species_id, legacy_candidate.get("instance_id", "")))
	var memory_id := "legacy_%s_cycle_%d" % [instance_id, completed_cycle]
	var legacy_monster := {
		"instance_id": instance_id,
		"species_id": species_id,
		"display_name": str(legacy_candidate.get("display_name", species_id)),
		"source_level": int(legacy_candidate.get("level", 1)),
		"source_specialization_id": str(legacy_candidate.get("specialization_id", "")),
		"source_evolution_id": str(legacy_candidate.get("promotion_id", legacy_candidate.get("evolution_id", ""))),
		"inherited_memory_id": memory_id,
		"completed_ending_id": ending_id,
		"source_cycle": completed_cycle
	}
	profile["legacy_monster"] = legacy_monster
	var unlocked_memories: Array = profile.get("unlocked_memory_ids", [])
	if not unlocked_memories.has(memory_id):
		unlocked_memories.append(memory_id)
	profile["unlocked_memory_ids"] = unlocked_memories
	profile["active_doctrine_id"] = ""
	profile["active_decree_id"] = ""
	profile["active_challenge_seal_id"] = ""
	return profile


static func apply_legacy_memory(roster: Dictionary, legacy_monster: Dictionary) -> bool:
	var species_id := str(legacy_monster.get("species_id", ""))
	if species_id == "" or not roster.has(species_id) or not (roster.get(species_id) is Dictionary):
		return false
	var monster: Dictionary = roster.get(species_id)
	var memory_id := str(legacy_monster.get("inherited_memory_id", ""))
	var memory_ids: Array = monster.get("unlocked_memory_ids", [])
	if memory_id != "" and not memory_ids.has(memory_id):
		memory_ids.append(memory_id)
	monster["unlocked_memory_ids"] = memory_ids
	monster["legacy_source_cycle"] = int(legacy_monster.get("source_cycle", 0))
	monster["legacy_source_level"] = int(legacy_monster.get("source_level", 1))
	roster[species_id] = monster
	return true


static func instance_id_for_species(species_id: String) -> String:
	return str(SPECIES_TO_INSTANCE.get(species_id, ""))


static func _copy_value(value):
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value
