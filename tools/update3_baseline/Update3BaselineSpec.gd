extends RefCounted
class_name Update3BaselineSpec

const SCHEMA_VERSION := 1
const FIXTURE_VERSION := "update3_day30_proxy_v1"
const POLICY_ID := "low_input_v1"
const TRIAL_EVIDENCE_KIND := "automated_update3_day30_proxy_trial"
const SUMMARY_EVIDENCE_KIND := "automated_update3_day30_proxy"

const DAY := 30
const STAGE_ID := "stage_04_citadel"
const MONSTER_LEVEL := 7
const MONSTER_BOND := 65
const HEART_INITIAL_CHARGE := 100
const BASE_ASSIGNMENT_COUNT := 18
const TRIAL_COUNT := 54

const FRONT_IDS := [
	"front_hero_oath",
	"front_holy_purification",
	"front_guild_repossession"
]
const HEART_IDS := [
	"heart_stonebone",
	"heart_hungry_maw",
	"heart_dream_lantern"
]
const DUO_LINK_IDS := [
	"link_spore_jelly_shelter",
	"link_ghostly_evacuate",
	"link_moon_scent_hunt",
	"link_molten_carapace",
	"link_stone_march",
	"link_false_beacon_vault"
]
const SEEDS := [20260711, 20260729, 20260747]

const EXPECTED_BOSS_BY_FRONT := {
	"front_hero_oath": "official_hero_leon",
	"front_holy_purification": "official_paladin_selen",
	"front_guild_repossession": "guild_commissioner_roman"
}

const OPERATION_BY_FRONT := {
	"front_hero_oath": "d28_siege_route_recon",
	"front_holy_purification": "d28_holy_relic_registry_swap",
	"front_guild_repossession": "d28_guild_ledger_forgery"
}

const DUO_MEMBERS := {
	"link_spore_jelly_shelter": ["mon_core_pudding", "mon_contract_mori"],
	"link_ghostly_evacuate": ["mon_core_pudding", "monster_bebe"],
	"link_moon_scent_hunt": ["mon_core_gob", "monster_koko"],
	"link_molten_carapace": ["mon_core_pynn", "monster_toktok"],
	"link_stone_march": ["mon_contract_dolkong", "mon_contract_dudum"],
	"link_false_beacon_vault": ["mon_contract_lumi", "mon_contract_mimi"]
}

# Five combat-capable instances per link. Rolo is intentionally excluded because
# the production roster marks that character as raid support, not a defender.
const DEPLOYMENT_BY_DUO := {
	"link_spore_jelly_shelter": ["mon_core_pudding", "mon_contract_mori", "mon_core_gob", "mon_core_pynn", "monster_koko"],
	"link_ghostly_evacuate": ["mon_core_pudding", "monster_bebe", "mon_core_gob", "mon_core_pynn", "mon_contract_mori"],
	"link_moon_scent_hunt": ["mon_core_gob", "monster_koko", "mon_core_pudding", "mon_core_pynn", "mon_contract_mori"],
	"link_molten_carapace": ["mon_core_pynn", "monster_toktok", "mon_core_pudding", "mon_core_gob", "mon_contract_mori"],
	"link_stone_march": ["mon_contract_dolkong", "mon_contract_dudum", "mon_core_gob", "mon_core_pynn", "mon_contract_mori"],
	"link_false_beacon_vault": ["mon_contract_lumi", "mon_contract_mimi", "mon_core_pudding", "mon_core_gob", "mon_core_pynn"]
}

const INSTANCE_SPECIES := {
	"mon_core_pudding": "slime",
	"mon_core_gob": "goblin",
	"mon_core_pynn": "imp",
	"mon_contract_mori": "spore_healer",
	"mon_contract_dolkong": "stone_sentinel",
	"mon_contract_dudum": "war_drummer",
	"mon_contract_lumi": "moon_tracker",
	"monster_bebe": "ghost_housemaid",
	"monster_koko": "graveyard_hound",
	"monster_toktok": "armored_beetle",
	"mon_contract_mimi": "mimic_porter"
}

const REVIEW_THRESHOLDS := {
	"front_win_rate_gap": 0.10,
	"heart_win_rate_gap": 0.10,
	"duo_win_rate_gap": 0.15,
	"winning_clear_time_spread": 0.20,
	"duo_activation_rate_min": 2.0 / 3.0,
	"individual_average_contribution_max": 0.40,
	"duo_pair_average_contribution_review": 0.65,
	"winning_time_min_samples_per_group": 2,
	"winning_combat_time_min_seconds": 65.0,
	"winning_combat_time_max_seconds": 105.0,
	"heart_chamber_disable_rate_min": 0.10,
	"heart_chamber_disable_rate_max": 0.45,
	"duo_average_activation_rate_min": 0.50,
	"duo_average_activation_rate_max": 0.85
}


static func base_assignments() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for duo_index in range(DUO_LINK_IDS.size()):
		for front_index in range(FRONT_IDS.size()):
			var heart_index := (front_index + duo_index) % HEART_IDS.size()
			var duo_id := str(DUO_LINK_IDS[duo_index])
			rows.append({
				"assignment_index": rows.size(),
				"row_id": "u3b_a%02d" % rows.size(),
				"front_id": str(FRONT_IDS[front_index]),
				"heart_id": str(HEART_IDS[heart_index]),
				"duo_link_id": duo_id,
				"operation_id": operation_for_front(str(FRONT_IDS[front_index])),
				"deployed_instance_ids": deployment_for_duo(duo_id)
			})
	return rows


static func trials() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for assignment in base_assignments():
		for seed_index in range(SEEDS.size()):
			var trial_index := rows.size()
			var row: Dictionary = assignment.duplicate(true)
			row["trial_index"] = trial_index
			row["seed_index"] = seed_index
			row["seed"] = int(SEEDS[seed_index])
			row["trial_id"] = "u3b_t%02d" % trial_index
			row["output_filename"] = "trial_%02d.json" % trial_index
			rows.append(row)
	return rows


static func trial_for_index(trial_index: int) -> Dictionary:
	if trial_index < 0 or trial_index >= TRIAL_COUNT:
		return {}
	return trials()[trial_index].duplicate(true)


static func deployment_for_duo(duo_link_id: String) -> Array[String]:
	var result: Array[String] = []
	for instance_id_value in DEPLOYMENT_BY_DUO.get(duo_link_id, []):
		result.append(str(instance_id_value))
	return result


static func duo_members(duo_link_id: String) -> Array[String]:
	var result: Array[String] = []
	for instance_id_value in DUO_MEMBERS.get(duo_link_id, []):
		result.append(str(instance_id_value))
	return result


static func expected_boss(front_id: String) -> String:
	return str(EXPECTED_BOSS_BY_FRONT.get(front_id, ""))


static func operation_for_front(front_id: String) -> String:
	return str(OPERATION_BY_FRONT.get(front_id, ""))


static func species_for_instance(instance_id: String) -> String:
	return str(INSTANCE_SPECIES.get(instance_id, ""))
