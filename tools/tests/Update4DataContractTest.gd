extends Node

const LoaderScript = preload("res://scripts/data/update4/Update4CatalogLoader.gd")
const ValidatorScript = preload("res://tools/content/ValidateUpdate4Content.gd")
const SaveV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_empty_catalog_root()
	_test_valid_synthetic_fixture()
	_test_rejection_cases()
	if failed:
		print("UPDATE4_DATA_CONTRACT_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE4_DATA_CONTRACT_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_empty_catalog_root() -> void:
	var loaded := LoaderScript.load_all()
	_expect(bool(loaded.get("ok", false)), "Update 4 빈 JSON 26종 parse PASS: %s" % [loaded.get("errors", [])])
	var catalogs: Dictionary = loaded.get("catalogs", {})
	_expect(catalogs.size() == 26, "Update 4 카탈로그 26종 분리 로드")
	_expect(ValidatorScript.validate_catalogs(catalogs, _context()).is_empty(), "빈 Phase 1 fixture 참조 검증 PASS")
	_expect(SaveV4MigratorScript.TARGET_VERSION == 4, "Phase 1에서 저장 버전 v4 유지")
	var missing := LoaderScript.load_all("res://data/regular_version/__missing_update4__")
	_expect(not bool(missing.get("ok", true)) and missing.get("errors", []).size() == 26, "누락 데이터 root는 카탈로그별 명확한 오류")


func _test_valid_synthetic_fixture() -> void:
	var errors := ValidatorScript.validate_catalogs(_valid_catalogs(), _context())
	_expect(errors.is_empty(), "모든 스키마와 참조를 갖춘 합성 fixture PASS: %s" % [errors])


func _test_rejection_cases() -> void:
	var catalogs := _valid_catalogs()
	catalogs["campaign_modes"]["mode_fixture"].erase("start_screen_id")
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "필수 필드 누락"), "campaign mode 필수 필드 누락 검출")

	catalogs = _valid_catalogs()
	catalogs["regions"]["region_fixture"]["rival_id"] = "rival_missing"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "rival 참조가 없습니다"), "region의 누락 rival 참조 검출")

	catalogs = _valid_catalogs()
	catalogs["council_agendas"]["agenda_fixture"]["modifier_handler_id"] = "handler_missing"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "modifier handler 참조가 없습니다"), "agenda의 미등록 handler 검출")

	catalogs = _valid_catalogs()
	catalogs["rival_events"]["region_fixture"] = {}
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "ID 중복"), "서로 다른 Update 4 카탈로그 ID 중복 검출")

	catalogs = _valid_catalogs()
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context(), {"regions": 5}), "수량 오류"), "카탈로그 기대 수량 불일치 검출")

	catalogs = _valid_catalogs()
	catalogs["upper_floor_layouts"]["upper_fixture"]["placed_modules"][0]["module_id"] = "upper_missing"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "module 참조가 없습니다"), "상층 module 누락 참조 검출")

	catalogs = _valid_catalogs()
	catalogs["crown_evolutions"]["crown_fixture"]["branch_inheritance"] = {"slime_rescue_alchemist": "crown_anchor_bonus"}
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "evolution branch 참조가 없습니다"), "계획 예시의 잘못된 진화 ID 검출")

	catalogs = _valid_catalogs()
	catalogs["council_endings"]["ending_fixture"]["illustration"] = "res://assets/update4/missing_ending.png"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "illustration 리소스가 없습니다"), "엔딩 리소스 누락 검출")


func _valid_catalogs() -> Dictionary:
	var catalogs := {}
	for catalog_name_value in LoaderScript.CATALOG_FILES.keys():
		catalogs[str(catalog_name_value)] = {}
	catalogs["campaign_modes"] = {
		"mode_fixture": {
			"display_name": "검증 의회 회차",
			"start_day": 1,
			"max_day": 30,
			"day_schedule_id": "schedule_fixture",
			"supported_systems": ["regions", "council"],
			"data_root": "res://data/regular_version/update4",
			"start_screen_id": "screen_fixture"
		}
	}
	catalogs["council_campaign_days"] = {"schedule_fixture": {"days": {}}}
	catalogs["regions"] = {
		"region_fixture": {
			"display_name": "검증 지역",
			"rival_id": "rival_fixture",
			"environment_rule_id": "environment_fixture",
			"enemy_pool": ["enemy_fixture"],
			"event_ids": ["event_fixture"],
			"charter_condition_id": "charter_fixture",
			"reward_table_id": "reward_fixture"
		}
	}
	catalogs["region_events"] = {"event_fixture": {"display_name": "검증 사건"}}
	catalogs["council_agendas"] = {
		"agenda_fixture": {
			"display_name": "검증 안건",
			"vote_day": 13,
			"choices": ["approve", "amend", "reject"],
			"preferred_rival_ids": ["rival_fixture"],
			"disliked_rival_ids": [],
			"modifier_handler_id": "agenda_fixture_handler"
		}
	}
	catalogs["rival_lords"] = {
		"rival_fixture": {
			"character_id": "CHR_RIVAL_FIXTURE",
			"display_name": "검증 경쟁 마왕",
			"region_affinities": ["region_fixture"],
			"preferred_agendas": ["agenda_fixture"],
			"disliked_agendas": [],
			"enemy_pool": ["enemy_fixture"],
			"boss_enemy_id": "enemy_fixture",
			"support_handler_id": "rival_support_fixture"
		}
	}
	catalogs["outpost_types"] = {
		"outpost_fixture": {
			"display_name": "검증 전초기지",
			"battle_layout_id": "outpost_battle_fixture",
			"passive_handler_id": "outpost_passive_fixture",
			"upgrade_handler_id": "outpost_upgrade_fixture",
			"max_deployed": 3
		}
	}
	catalogs["outpost_encounters"] = {"outpost_battle_fixture": {"display_name": "검증 전투"}}
	catalogs["upper_floor_modules"] = {"upper_stair_landing": {"display_name": "검증 계단"}}
	catalogs["upper_floor_layouts"] = {
		"upper_fixture": {
			"display_name": "검증 상층",
			"floor_id": "upper_02",
			"placed_modules": [{"instance_id": "upper_stair", "module_id": "upper_stair_landing", "grid_origin": [0, 0]}],
			"connections": []
		}
	}
	catalogs["monsters"] = {"monster_fixture": {"display_name": "검증 몬스터"}}
	catalogs["enemies"] = {"enemy_fixture": {"display_name": "검증 적"}}
	catalogs["characters"] = {"CHR_RIVAL_FIXTURE": {"display_name": "검증 캐릭터"}}
	catalogs["skills"] = {"royal_skill_fixture": {"display_name": "검증 왕관 스킬"}}
	catalogs["crown_evolutions"] = {
		"crown_fixture": {
			"monster_id": "monster_fixture",
			"display_name": "검증 왕관",
			"required_bond": 80,
			"required_level": 6,
			"required_growth_stage": 1,
			"cost": {"council_seals": 2},
			"stat_multipliers": {"max_hp": 1.16},
			"passive_handler_id": "crown_passive_fixture",
			"royal_skill_id": "royal_skill_fixture",
			"branch_inheritance": {"slime_rescue_alchemy_gel": "crown_anchor_bonus"},
			"animation_set_id": "animation_fixture"
		}
	}
	catalogs["run_metric_definitions"] = {"council.fixture": {"type": "int"}}
	catalogs["council_endings"] = {
		"ending_fixture": {
			"catalog_code": "E17",
			"priority": 170,
			"condition": {"metric": "council.fixture", "op": ">=", "value": 1},
			"reward_ids": [],
			"illustration": "res://assets/ui/endings/ending_true_demon_castle.png"
		}
	}
	return catalogs


func _context() -> Dictionary:
	return {
		"screens": {"screen_fixture": true, "front_selection": true, "management": true},
		"day_schedules": {"legacy_front_schedule": true, "council_day_schedule": true},
		"handlers": {
			"environment_fixture": true,
			"charter_fixture": true,
			"reward_fixture": true,
			"agenda_fixture_handler": true,
			"rival_support_fixture": true,
			"outpost_passive_fixture": true,
			"outpost_upgrade_fixture": true,
			"crown_passive_fixture": true,
			"crown_anchor_bonus": true
		},
		"evolutions": {"slime_rescue_alchemy_gel": true},
		"animation_sets": {"animation_fixture": true},
		"metrics": {},
		"monsters": {},
		"enemies": {},
		"characters": {},
		"skills": {}
	}


func _has_error(errors: Array[String], token: String) -> bool:
	for error in errors:
		if error.contains(token):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("[PASS] %s" % message)
		return
	failed = true
	push_error("[FAIL] %s" % message)
