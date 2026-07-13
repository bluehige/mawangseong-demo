extends RefCounted
class_name ContractRosterService

const REQUIRED_CONTRACT_COUNT := 2
const STAGE_DEPLOYMENT_LIMITS := {
	"stage_01_cave": 3,
	"stage_02_castle": 4,
	"stage_03_keep": 4,
	"stage_04_citadel": 5
}


static func contract_ids(contracts: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for contract_id_value in contracts.keys():
		var contract_id := str(contract_id_value)
		if contract_id != "":
			ids.append(contract_id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(contracts.get(a, {}).get("order", 0)) < int(contracts.get(b, {}).get("order", 0))
	)
	return ids


static func offer_ids(contracts: Dictionary, cycle_seed: int) -> Array[String]:
	var ids := contract_ids(contracts)
	if ids.size() < 2:
		return ids
	var rng := RandomNumberGenerator.new()
	rng.seed = cycle_seed
	for index in range(ids.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held := ids[index]
		ids[index] = ids[swap_index]
		ids[swap_index] = held
	return ids


static func validate_contract_selection(selected_ids: Array, contracts: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if selected_ids.size() != REQUIRED_CONTRACT_COUNT:
		errors.append("계약 몬스터는 정확히 %d종을 선택해야 합니다." % REQUIRED_CONTRACT_COUNT)
	var seen: Dictionary = {}
	for contract_id_value in selected_ids:
		var contract_id := str(contract_id_value)
		if contract_id == "" or not contracts.has(contract_id):
			errors.append("존재하지 않는 계약 ID입니다: %s" % contract_id)
		elif seen.has(contract_id):
			errors.append("같은 계약을 두 번 선택할 수 없습니다: %s" % contract_id)
		seen[contract_id] = true
	return errors


static func stage_deployment_limit(stage_id: String) -> int:
	return int(STAGE_DEPLOYMENT_LIMITS.get(stage_id, STAGE_DEPLOYMENT_LIMITS["stage_01_cave"]))


static func instance_id_for_species(species_id: String, instances: Dictionary) -> String:
	for instance_id_value in instances.keys():
		var instance: Dictionary = instances.get(instance_id_value, {})
		if str(instance.get("species_id", "")) == species_id:
			return str(instance_id_value)
	return ""


static func species_id_for_instance(instance_id: String, instances: Dictionary) -> String:
	return str(instances.get(instance_id, {}).get("species_id", ""))


static func owned_instance_ids(monster_roster: Dictionary, instances: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for species_id_value in monster_roster.keys():
		var instance_id := instance_id_for_species(str(species_id_value), instances)
		if instance_id != "" and not result.has(instance_id):
			result.append(instance_id)
	return result


static func validate_deployment(deployed_ids: Array, owned_ids: Array, stage_id: String, limit_bonus: int = 0) -> Array[String]:
	var errors: Array[String] = []
	var limit := stage_deployment_limit(stage_id) + maxi(0, limit_bonus)
	if deployed_ids.is_empty():
		errors.append("출전 몬스터를 한 명 이상 선택해야 합니다.")
	if deployed_ids.size() > limit:
		errors.append("%s의 출전 한도는 %d명입니다." % [stage_id, limit])
	var seen: Dictionary = {}
	for instance_id_value in deployed_ids:
		var instance_id := str(instance_id_value)
		if not owned_ids.has(instance_id):
			errors.append("보유하지 않은 몬스터는 출전할 수 없습니다: %s" % instance_id)
		elif seen.has(instance_id):
			errors.append("같은 몬스터를 중복 출전시킬 수 없습니다: %s" % instance_id)
		seen[instance_id] = true
	return errors


static func reserve_instance_ids(owned_ids: Array, deployed_ids: Array) -> Array[String]:
	var result: Array[String] = []
	for instance_id_value in owned_ids:
		var instance_id := str(instance_id_value)
		if not deployed_ids.has(instance_id):
			result.append(instance_id)
	return result
