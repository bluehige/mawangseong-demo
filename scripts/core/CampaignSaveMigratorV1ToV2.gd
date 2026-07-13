extends RefCounted
class_name CampaignSaveMigratorV1ToV2

const SOURCE_VERSION := 1
const TARGET_VERSION := 2
const CAMPAIGN_FINAL_DAY := 30
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
const CORE_INSTANCE_IDS := ["mon_core_pudding", "mon_core_gob", "mon_core_pynn"]


static func migrate_inspection(v1_inspection: Dictionary, instance_templates: Dictionary, metric_definitions: Dictionary) -> Dictionary:
	if str(v1_inspection.get("status", "")) != "valid":
		return {"ok": false, "error": "유효한 저장 v1 검사 결과가 아닙니다.", "envelope": {}}
	var payload = v1_inspection.get("payload")
	var summary = v1_inspection.get("summary")
	if not (payload is Dictionary) or not (summary is Dictionary):
		return {"ok": false, "error": "저장 v1의 진행 정보 또는 요약이 없습니다.", "envelope": {}}
	var monsters_result := _migrate_monsters(payload.get("world", {}).get("monster_roster", {}), instance_templates)
	if not bool(monsters_result.get("ok", false)):
		return {"ok": false, "error": str(monsters_result.get("error", "몬스터 변환 실패")), "envelope": {}}
	var migrated_payload: Dictionary = payload.duplicate(true)
	_remap_known_instance_references(migrated_payload)
	var campaign: Dictionary = payload.get("campaign", {})
	var completed := bool(campaign.get("completed", false)) and str(campaign.get("final_battle_outcome", "")) == "victory"
	var legacy_expansion: Dictionary = payload.get("legacy_expansion", {})
	var source_profile: Dictionary = legacy_expansion.get("profile", {}) if legacy_expansion.get("profile") is Dictionary else {}
	var ending_archive: Dictionary = source_profile.get("ending_archive", {}).duplicate(true) if source_profile.get("ending_archive") is Dictionary else {}
	if completed and ending_archive.is_empty():
		ending_archive["true_demon_castle"] = {
			"first_seen_cycle": 1,
			"seen_count": 1,
			"migrated_from_v1": true
		}
	var envelope := {
		"version": TARGET_VERSION,
		"campaign_final_day": CAMPAIGN_FINAL_DAY,
		"migrated_from_version": SOURCE_VERSION,
		"saved_at_unix": int(v1_inspection.get("saved_at_unix", 0)),
		"saved_at_text": str(v1_inspection.get("saved_at_text", "")),
		"summary": summary.duplicate(true),
		"profile": {
			"profile_version": 1,
			"profile_id": str(source_profile.get("profile_id", "profile_default")),
			"completed_cycles": maxi(int(source_profile.get("completed_cycles", 0)), 1 if completed else 0),
			"ending_archive": ending_archive,
			"unlocked_memory_ids": _array_copy(source_profile.get("unlocked_memory_ids", [])),
			"seen_event_ids": _array_copy(source_profile.get("seen_event_ids", [])),
			"unlocked_contract_ids": _array_copy(source_profile.get("unlocked_contract_ids", [])),
			"contract_history": _array_copy(source_profile.get("contract_history", [])),
			"active_doctrine_id": str(source_profile.get("active_doctrine_id", "")),
			"doctrine_history": _array_copy(source_profile.get("doctrine_history", [])),
			"active_decree_id": str(source_profile.get("active_decree_id", "")),
			"decree_history": _array_copy(source_profile.get("decree_history", [])),
			"active_challenge_seal_id": str(source_profile.get("active_challenge_seal_id", "")),
			"challenge_seal_history": _array_copy(source_profile.get("challenge_seal_history", [])),
			"leon_stance_history": _array_copy(source_profile.get("leon_stance_history", [])),
			"legacy_monster": source_profile.get("legacy_monster", {}).duplicate(true) if source_profile.get("legacy_monster") is Dictionary else {}
		},
		"active_run": {
			"cycle_index": maxi(1, int(legacy_expansion.get("cycle_index", 1))),
			"checkpoint": str(payload.get("checkpoint", payload.get("screen", "management"))),
			"screen": str(payload.get("screen", "management")),
			"monsters": monsters_result.get("monsters", {}).duplicate(true),
			"run_metrics": _metric_defaults(metric_definitions),
			"legacy_payload": migrated_payload
		}
	}
	var validation_error := validate_v2(envelope, instance_templates, metric_definitions)
	if validation_error != "":
		return {"ok": false, "error": validation_error, "envelope": {}}
	return {"ok": true, "error": "", "envelope": envelope}


static func validate_v2(envelope: Dictionary, instance_templates: Dictionary, metric_definitions: Dictionary) -> String:
	if int(envelope.get("version", 0)) != TARGET_VERSION:
		return "저장 v2 버전이 올바르지 않습니다."
	if int(envelope.get("campaign_final_day", 0)) != CAMPAIGN_FINAL_DAY:
		return "저장 v2의 캠페인 마지막 날이 DAY 30이 아닙니다."
	for key in ["summary", "profile", "active_run"]:
		if not (envelope.get(key) is Dictionary):
			return "저장 v2의 필수 영역이 없습니다: %s" % key
	var profile: Dictionary = envelope.get("profile", {})
	if int(profile.get("profile_version", 0)) != 1 or str(profile.get("profile_id", "")) == "":
		return "프로필 버전 또는 ID가 올바르지 않습니다."
	for key in ["ending_archive", "legacy_monster"]:
		if not (profile.get(key) is Dictionary):
			return "프로필 자료 형식이 올바르지 않습니다: %s" % key
	for key in ["unlocked_memory_ids", "seen_event_ids", "unlocked_contract_ids"]:
		if not (profile.get(key) is Array):
			return "프로필 해금 목록 형식이 올바르지 않습니다: %s" % key
	if profile.has("doctrine_history") and not (profile.get("doctrine_history") is Array):
		return "2회차 교리 이력 형식이 올바르지 않습니다."
	if profile.has("active_doctrine_id") and not (profile.get("active_doctrine_id") is String):
		return "2회차 교리 ID 형식이 올바르지 않습니다."
	for key in ["decree_history", "challenge_seal_history", "leon_stance_history"]:
		if profile.has(key) and not (profile.get(key) is Array):
			return "2회차 선택 이력 형식이 올바르지 않습니다: %s" % key
	for key in ["active_decree_id", "active_challenge_seal_id"]:
		if profile.has(key) and not (profile.get(key) is String):
			return "2회차 선택 ID 형식이 올바르지 않습니다: %s" % key
	var active_run: Dictionary = envelope.get("active_run", {})
	for key in ["monsters", "run_metrics", "legacy_payload"]:
		if not (active_run.get(key) is Dictionary):
			return "현재 회차 자료 형식이 올바르지 않습니다: %s" % key
	var monsters: Dictionary = active_run.get("monsters", {})
	for required_instance_id in CORE_INSTANCE_IDS:
		if instance_templates.has(required_instance_id) and not monsters.has(required_instance_id):
			return "기존 핵심 몬스터 변환이 누락되었습니다: %s" % required_instance_id
	var metrics: Dictionary = active_run.get("run_metrics", {})
	for metric_id in metric_definitions.keys():
		if not metrics.has(metric_id):
			return "현재 회차 기본 지표가 누락되었습니다: %s" % metric_id
	return ""


static func _migrate_monsters(v1_roster, instance_templates: Dictionary) -> Dictionary:
	if not (v1_roster is Dictionary):
		return {"ok": false, "error": "저장 v1의 몬스터 로스터가 사전 형식이 아닙니다.", "monsters": {}}
	var monsters: Dictionary = {}
	for species_id_value in v1_roster.keys():
		var species_id := str(species_id_value)
		var instance_id := str(SPECIES_TO_INSTANCE.get(species_id, ""))
		if instance_id == "":
			return {"ok": false, "error": "저장 v1에 변환 규칙이 없는 몬스터가 있습니다: %s" % species_id, "monsters": {}}
		if not instance_templates.has(instance_id):
			return {"ok": false, "error": "몬스터 개체 원형을 찾을 수 없습니다: %s" % instance_id, "monsters": {}}
		var roster_value = v1_roster.get(species_id_value)
		if not (roster_value is Dictionary):
			return {"ok": false, "error": "저장 v1의 몬스터 자료가 사전 형식이 아닙니다: %s" % species_id, "monsters": {}}
		var migrated: Dictionary = instance_templates.get(instance_id, {}).duplicate(true)
		for key in roster_value.keys():
			migrated[key] = _copy_value(roster_value.get(key))
		migrated["instance_id"] = instance_id
		migrated["species_id"] = species_id
		migrated["specialization_id"] = str(roster_value.get("specialization_id", migrated.get("specialization_id", "")))
		migrated["evolution_id"] = str(roster_value.get("promotion_id", migrated.get("evolution_id", "")))
		monsters[instance_id] = migrated
	return {"ok": true, "error": "", "monsters": monsters}


static func _remap_known_instance_references(payload: Dictionary) -> void:
	var world: Dictionary = payload.get("world", {})
	world["selected_monster_id"] = _map_id(str(world.get("selected_monster_id", "")))
	var raid: Dictionary = payload.get("raid", {})
	raid["selected_monster_ids"] = _map_id_array(raid.get("selected_monster_ids", []))
	var result: Dictionary = payload.get("result", {})
	result["growth_choice_monster_id"] = _map_id(str(result.get("growth_choice_monster_id", "")))
	var growth_choice: Dictionary = result.get("last_growth_choice_summary", {})
	if growth_choice.has("monster_id"):
		growth_choice["monster_id"] = _map_id(str(growth_choice.get("monster_id", "")))
	for row_value in result.get("last_growth_summary", []):
		if row_value is Dictionary and row_value.has("monster_id"):
			row_value["monster_id"] = _map_id(str(row_value.get("monster_id", "")))


static func _metric_defaults(metric_definitions: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for metric_id in metric_definitions.keys():
		var definition: Dictionary = metric_definitions.get(metric_id, {})
		result[metric_id] = _copy_value(definition.get("default", 0.0))
	return result


static func _map_id(value: String) -> String:
	return str(SPECIES_TO_INSTANCE.get(value, value))


static func _map_id_array(values) -> Array:
	var result: Array = []
	if not (values is Array):
		return result
	for value in values:
		result.append(_map_id(str(value)))
	return result


static func _copy_value(value):
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


static func _array_copy(value) -> Array:
	return value.duplicate(true) if value is Array else []
