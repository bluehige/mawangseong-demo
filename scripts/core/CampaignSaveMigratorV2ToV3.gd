extends RefCounted
class_name CampaignSaveMigratorV2ToV3

const SaveV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const ContractRosterServiceScript = preload("res://scripts/systems/contracts/ContractRosterService.gd")

const SOURCE_VERSION := 2
const TARGET_VERSION := 3
const CAMPAIGN_FINAL_DAY := 30
const CORE_INSTANCE_ORDER := [
	"mon_core_pudding",
	"mon_core_gob",
	"mon_core_pynn",
	"mon_core_rolo"
]
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
	"twelve_endings_chronicle": "E11"
}


static func migrate_envelope(v2_envelope: Dictionary, instance_templates: Dictionary, metric_definitions: Dictionary) -> Dictionary:
	v2_envelope = v2_envelope.duplicate(true)
	var source_active_run: Dictionary = v2_envelope.get("active_run", {})
	var source_metrics: Dictionary = source_active_run.get("run_metrics", {}).duplicate(true) if source_active_run.get("run_metrics") is Dictionary else {}
	for metric_id_value in metric_definitions.keys():
		if not source_metrics.has(metric_id_value):
			source_metrics[metric_id_value] = _copy_value(metric_definitions.get(metric_id_value, {}).get("default", 0.0))
	source_active_run["run_metrics"] = source_metrics
	v2_envelope["active_run"] = source_active_run
	var v2_error := SaveV2MigratorScript.validate_v2(v2_envelope, instance_templates, metric_definitions)
	if v2_error != "":
		return {"ok": false, "error": "유효한 저장 v2가 아닙니다: %s" % v2_error, "envelope": {}}

	var profile: Dictionary = v2_envelope.get("profile", {}).duplicate(true)
	profile["profile_version"] = 2
	profile["contract_history"] = _array_copy(profile.get("contract_history", []))
	profile["ending_catalog_codes"] = _migrated_ending_codes(profile.get("ending_archive", {}), profile.get("ending_catalog_codes", {}))
	profile["active_decree_id"] = str(profile.get("active_decree_id", ""))
	profile["decree_history"] = _array_copy(profile.get("decree_history", []))
	profile["active_challenge_seal_id"] = str(profile.get("active_challenge_seal_id", ""))
	profile["challenge_seal_history"] = _array_copy(profile.get("challenge_seal_history", []))
	profile["leon_stance_history"] = _array_copy(profile.get("leon_stance_history", []))

	var active_run: Dictionary = v2_envelope.get("active_run", {}).duplicate(true)
	var update2: Dictionary = active_run.get("legacy_payload", {}).get("update2", {})
	var deployment := _initial_deployment(active_run)
	active_run["cycle_seed"] = int(update2.get("cycle_seed", _cycle_seed(v2_envelope, active_run)))
	active_run["contract_board_offer_ids"] = _array_copy(update2.get("contract_board_offer_ids", []))
	active_run["selected_contract_ids"] = _array_copy(update2.get("selected_contract_ids", []))
	active_run["deployed_instance_ids"] = _array_copy(update2.get("deployed_instance_ids", deployment.get("deployed", [])))
	active_run["reserve_instance_ids"] = _array_copy(update2.get("reserve_instance_ids", deployment.get("reserve", [])))
	active_run["stage_deployment_limit"] = int(update2.get("stage_deployment_limit", deployment.get("limit", 3)))
	active_run["event_deck_order"] = _array_copy(update2.get("event_deck_order", []))
	active_run["wave_variant_ids"] = _array_copy(update2.get("wave_variant_ids", []))
	active_run["triggered_event_ids"] = _array_copy(update2.get("triggered_event_ids", []))
	active_run["leon_adaptation"] = _normalized_leon_adaptation(update2.get("leon_adaptation", active_run.get("leon_adaptation", {})))

	var envelope: Dictionary = v2_envelope.duplicate(true)
	envelope["version"] = TARGET_VERSION
	envelope["migrated_from_version"] = SOURCE_VERSION
	envelope["profile"] = profile
	envelope["active_run"] = active_run
	var validation_error := validate_v3(envelope, instance_templates, metric_definitions)
	if validation_error != "":
		return {"ok": false, "error": validation_error, "envelope": {}}
	return {"ok": true, "error": "", "envelope": envelope}


static func validate_v3(envelope: Dictionary, instance_templates: Dictionary, metric_definitions: Dictionary) -> String:
	if int(envelope.get("version", 0)) != TARGET_VERSION:
		return "저장 v3 버전이 올바르지 않습니다."
	if int(envelope.get("campaign_final_day", 0)) != CAMPAIGN_FINAL_DAY:
		return "저장 v3의 캠페인 마지막 날이 DAY 30이 아닙니다."
	for key in ["summary", "profile", "active_run"]:
		if not (envelope.get(key) is Dictionary):
			return "저장 v3의 필수 영역이 없습니다: %s" % key

	var v2_compat: Dictionary = envelope.duplicate(true)
	v2_compat["version"] = SOURCE_VERSION
	var v2_profile: Dictionary = v2_compat.get("profile", {}).duplicate(true)
	v2_profile["profile_version"] = 1
	v2_compat["profile"] = v2_profile
	var legacy_error := SaveV2MigratorScript.validate_v2(v2_compat, instance_templates, metric_definitions)
	if legacy_error != "":
		return "저장 v2 호환 자료가 손상되었습니다: %s" % legacy_error

	var profile: Dictionary = envelope.get("profile", {})
	if int(profile.get("profile_version", 0)) != 2:
		return "저장 v3 프로필 버전이 올바르지 않습니다."
	for key in ["ending_archive", "legacy_monster", "ending_catalog_codes"]:
		if not (profile.get(key) is Dictionary):
			return "저장 v3 프로필 사전 형식이 올바르지 않습니다: %s" % key
	for key in ["unlocked_memory_ids", "seen_event_ids", "unlocked_contract_ids", "contract_history", "doctrine_history", "decree_history", "challenge_seal_history", "leon_stance_history"]:
		if not (profile.get(key) is Array):
			return "저장 v3 프로필 목록 형식이 올바르지 않습니다: %s" % key
	for key in ["active_doctrine_id", "active_decree_id", "active_challenge_seal_id"]:
		if not (profile.get(key) is String):
			return "저장 v3 프로필 ID 형식이 올바르지 않습니다: %s" % key
	for ending_id_value in profile.get("ending_catalog_codes", {}).keys():
		var code := str(profile.get("ending_catalog_codes", {}).get(ending_id_value, ""))
		if not code.begins_with("E") or code.length() != 3:
			return "엔딩 도감 코드가 올바르지 않습니다: %s" % code

	var active_run: Dictionary = envelope.get("active_run", {})
	if not _is_number(active_run.get("cycle_seed")) or int(active_run.get("cycle_seed", 0)) <= 0:
		return "회차 seed가 올바르지 않습니다."
	for key in ["contract_board_offer_ids", "selected_contract_ids", "deployed_instance_ids", "reserve_instance_ids", "event_deck_order", "wave_variant_ids"]:
		if not _string_array_is_valid(active_run.get(key)):
			return "현재 회차 목록 형식이 올바르지 않습니다: %s" % key
	var selected: Array = active_run.get("selected_contract_ids", [])
	if selected.size() > 2:
		return "회차당 계약 몬스터는 최대 2종입니다."
	if _has_duplicates(selected):
		return "계약 몬스터 선택에 중복이 있습니다."
	var deployed: Array = active_run.get("deployed_instance_ids", [])
	var reserve: Array = active_run.get("reserve_instance_ids", [])
	if _has_duplicates(deployed) or _has_duplicates(reserve):
		return "출전 또는 예비 로스터에 중복 개체가 있습니다."
	for instance_id_value in deployed:
		if reserve.has(instance_id_value):
			return "같은 몬스터가 출전과 예비 로스터에 동시에 있습니다: %s" % instance_id_value
	var deployment_limit := int(active_run.get("stage_deployment_limit", 0))
	if deployment_limit <= 0 or deployed.size() > deployment_limit:
		return "Stage 출전 한도와 출전 로스터가 일치하지 않습니다."
	var monsters: Dictionary = active_run.get("monsters", {})
	for instance_id_value in deployed + reserve:
		if not monsters.has(instance_id_value):
			return "로스터가 존재하지 않는 몬스터 개체를 참조합니다: %s" % instance_id_value
	var adaptation = active_run.get("leon_adaptation")
	if not (adaptation is Dictionary):
		return "레온 적응 자료 형식이 올바르지 않습니다."
	for key in ["stance_id"]:
		if not (adaptation.get(key) is String):
			return "레온 적응 ID 형식이 올바르지 않습니다: %s" % key
	for key in ["announced_day", "retry_seed"]:
		if not _is_number(adaptation.get(key)):
			return "레온 적응 수치 형식이 올바르지 않습니다: %s" % key
	if not (adaptation.get("locked") is bool) or not (adaptation.get("analysis") is Dictionary):
		return "레온 적응 상태 형식이 올바르지 않습니다."
	return ""


static func _normalized_leon_adaptation(value) -> Dictionary:
	var result := {
		"stance_id": "",
		"announced_day": 0,
		"locked": false,
		"analysis": {},
		"retry_seed": 0,
		"applied_count": 0
	}
	if not (value is Dictionary):
		return result
	result["stance_id"] = str(value.get("stance_id", ""))
	result["announced_day"] = maxi(0, int(value.get("announced_day", 0)))
	result["locked"] = bool(value.get("locked", false)) and str(result.get("stance_id", "")) != ""
	result["analysis"] = value.get("analysis", {}).duplicate(true) if value.get("analysis") is Dictionary else {}
	result["retry_seed"] = maxi(0, int(value.get("retry_seed", 0)))
	result["applied_count"] = maxi(0, int(value.get("applied_count", 0)))
	return result


static func _migrated_ending_codes(archive_value, existing_value) -> Dictionary:
	var result: Dictionary = existing_value.duplicate(true) if existing_value is Dictionary else {}
	if not (archive_value is Dictionary):
		return result
	for ending_id_value in archive_value.keys():
		var ending_id := str(ending_id_value)
		if ENDING_CATALOG_CODES.has(ending_id):
			result[ending_id] = ENDING_CATALOG_CODES[ending_id]
	return result


static func _initial_deployment(active_run: Dictionary) -> Dictionary:
	var monsters: Dictionary = active_run.get("monsters", {})
	var legacy_payload: Dictionary = active_run.get("legacy_payload", {})
	var stage_id := str(legacy_payload.get("world", {}).get("castle_art_stage", "stage_01_cave"))
	var limit := _stage_limit(stage_id)
	var ordered_ids: Array[String] = []
	for instance_id in CORE_INSTANCE_ORDER:
		if monsters.has(instance_id):
			ordered_ids.append(instance_id)
	var remaining: Array[String] = []
	for instance_id_value in monsters.keys():
		var instance_id := str(instance_id_value)
		if not ordered_ids.has(instance_id):
			remaining.append(instance_id)
	remaining.sort()
	ordered_ids.append_array(remaining)
	var deployed: Array[String] = []
	var reserve: Array[String] = []
	for instance_id in ordered_ids:
		var monster: Dictionary = monsters.get(instance_id, {})
		if bool(monster.get("raid_support", false)) or deployed.size() >= limit:
			reserve.append(instance_id)
		else:
			deployed.append(instance_id)
	return {"deployed": deployed, "reserve": reserve, "limit": limit}


static func _stage_limit(stage_id: String) -> int:
	return ContractRosterServiceScript.stage_deployment_limit(stage_id)


static func _cycle_seed(envelope: Dictionary, active_run: Dictionary) -> int:
	var saved_at := int(envelope.get("saved_at_unix", 0))
	var cycle_index := maxi(1, int(active_run.get("cycle_index", 1)))
	var result: int = absi(saved_at * 31 + cycle_index * 1009) % 2147483647
	return result if result > 0 else cycle_index


static func _array_copy(value) -> Array:
	return value.duplicate(true) if value is Array else []


static func _copy_value(value):
	return value.duplicate(true) if value is Dictionary or value is Array else value


static func _string_array_is_valid(value) -> bool:
	if not (value is Array):
		return false
	for entry in value:
		if not (entry is String):
			return false
	return true


static func _has_duplicates(values: Array) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if seen.has(value):
			return true
		seen[value] = true
	return false


static func _is_number(value) -> bool:
	return value is int or value is float
