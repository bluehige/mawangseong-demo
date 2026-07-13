extends Node

const ValidatorScript = preload("res://tools/content/ValidateUpdate3Content.gd")
const SaveV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_empty_workspace_fixtures()
	_test_valid_reference_fixture()
	_test_rejection_cases()
	if failed:
		print("UPDATE3_DATA_CONTRACT_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE3_DATA_CONTRACT_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_empty_workspace_fixtures() -> void:
	var load_result := ValidatorScript.load_catalogs()
	_expect(bool(load_result.get("ok", false)), "3차 Phase 1 JSON 9개 parse PASS: %s" % [load_result.get("errors", [])])
	var catalogs: Dictionary = load_result.get("catalogs", {})
	_expect(catalogs.size() == ValidatorScript.DATA_PATHS.size(), "3차 카탈로그 9종 로드")
	_expect(ValidatorScript.validate_catalogs(catalogs, _context()).is_empty(), "현재 Phase 누적 카탈로그 참조 검증 PASS")
	_expect(DataRegistry.update3_fronts.size() == 3 and DataRegistry.update3_castle_hearts.size() == 3 and DataRegistry.update3_duo_links.size() == 6 and DataRegistry.update3_duo_links.has("link_spore_jelly_shelter") and DataRegistry.update3_duo_links.has("link_ghostly_evacuate") and DataRegistry.update3_duo_links.has("link_moon_scent_hunt") and DataRegistry.update3_duo_links.has("link_molten_carapace") and DataRegistry.update3_duo_links.has("link_stone_march") and DataRegistry.update3_duo_links.has("link_false_beacon_vault") and DataRegistry.update3_monster_extensions.has("ghost_housemaid") and DataRegistry.monsters.has("ghost_housemaid") and DataRegistry.update3_monster_extensions.has("graveyard_hound") and DataRegistry.monsters.has("graveyard_hound") and DataRegistry.update3_monster_extensions.has("armored_beetle") and DataRegistry.monsters.has("armored_beetle") and DataRegistry.update3_enemy_extensions.has("seal_chainbearer") and DataRegistry.enemies.has("seal_chainbearer") and DataRegistry.update3_enemy_extensions.has("reliquary_guard") and DataRegistry.enemies.has("reliquary_guard") and DataRegistry.update3_enemy_extensions.has("choir_exorcist") and DataRegistry.enemies.has("choir_exorcist") and DataRegistry.update3_enemy_extensions.has("bounty_tracker") and DataRegistry.enemies.has("bounty_tracker") and DataRegistry.update3_enemy_extensions.has("combat_alchemist") and DataRegistry.enemies.has("combat_alchemist") and DataRegistry.update3_enemy_extensions.has("ledger_binder") and DataRegistry.enemies.has("ledger_binder"), "DataRegistry는 Phase 24 누적 전선·심장·합동기 6종·신규 몬스터·신규 적을 로드")
	_expect(SaveV3MigratorScript.TARGET_VERSION == 3, "Phase 1에서 저장 버전 v3 유지")


func _test_valid_reference_fixture() -> void:
	var errors := ValidatorScript.validate_catalogs(_valid_catalogs(), _context())
	_expect(errors.is_empty(), "모든 schema와 참조를 갖춘 합성 fixture PASS: %s" % [errors])


func _test_rejection_cases() -> void:
	var catalogs := _valid_catalogs()
	catalogs["castle_hearts"]["front_fixture"] = catalogs["castle_hearts"]["heart_fixture"].duplicate(true)
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "ID 중복"), "서로 다른 3차 카탈로그의 중복 ID 검출")

	catalogs = _valid_catalogs()
	catalogs["enemies"]["enemy_fixture"]["character_id"] = "CHR_MISSING"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "캐릭터 참조가 없습니다"), "잘못된 캐릭터 참조 검출")

	catalogs = _valid_catalogs()
	catalogs["castle_hearts"]["heart_fixture"]["active_skill_id"] = "missing_skill"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "스킬 참조가 없습니다"), "잘못된 스킬 참조 검출")

	catalogs = _valid_catalogs()
	catalogs["endings"]["ending_fixture"]["illustration"] = "res://missing/update3_ending.png"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "리소스 참조가 없습니다"), "잘못된 리소스 참조 검출")

	catalogs = _valid_catalogs()
	catalogs["fronts"]["front_fixture"].erase("final_enemy_id")
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "front DAY 30 보스 누락"), "front DAY 30 보스 누락 검출")

	catalogs = _valid_catalogs()
	catalogs["front_day_overlays"]["overlay_fixture"]["days"]["30"].erase("boss_enemy_id")
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "overlay DAY 30 보스 누락"), "front overlay DAY 30 보스 누락 검출")

	catalogs = _valid_catalogs()
	catalogs["duo_links"]["link_fixture"]["member_instance_ids"][1] = "mon_missing"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "duo member 누락"), "duo member 누락 검출")

	catalogs = _valid_catalogs()
	catalogs["endings"]["ending_fixture"]["condition"]["metric"] = "run.missing_metric"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "ending metric이 없습니다"), "ending metric 누락 검출")

	catalogs = _valid_catalogs()
	catalogs["rival_finales"]["rival_fixture"]["phases"].pop_back()
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "정확히 3단계"), "rival finale 3단계 계약 위반 검출")

	catalogs = _valid_catalogs()
	catalogs["duo_links"]["link_fixture"]["effect_handler"] = "missing_handler"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "effect handler가 등록되지 않았습니다"), "duo effect handler 누락 검출")

	catalogs = _valid_catalogs()
	catalogs["enemies"]["enemy_fixture"]["behavior_handler"] = "missing_handler"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "behavior handler가 등록되지 않았습니다"), "enemy behavior handler 누락 검출")

	catalogs = _valid_catalogs()
	catalogs["front_day_overlays"]["overlay_fixture"]["days"].erase("29")
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "DAY 29 결전 전야 누락"), "전선별 DAY 29 결전 전야 누락 검출")

	catalogs = _valid_catalogs()
	catalogs["events"]["finale_fixture"]["dialogue_templates"][0]["text"] = "필수 맥락이 없는 대사"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "대사 토큰 누락"), "결전 전야 필수 문맥 토큰 누락 검출")

	catalogs = _valid_catalogs()
	catalogs["events"]["finale_fixture"]["dialogue_templates"][1]["speaker"] = "CHR_MISSING"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "대사 캐릭터 참조가 없습니다"), "결전 전야 잘못된 화자 참조 검출")

	catalogs = _valid_catalogs()
	catalogs["front_operations"]["operation_fixture"].erase("reward")
	catalogs["front_operations"]["operation_fixture"].erase("defense_modifier")
	catalogs["front_operations"]["operation_fixture"]["raid_source_id"] = "missing_source"
	_expect(_has_error(ValidatorScript.validate_catalogs(catalogs, _context()), "원본 raid가 없습니다"), "source-backed DAY 28 작전 원본 누락 검출")


func _valid_catalogs() -> Dictionary:
	return {
		"fronts": {
			"front_fixture": {
				"display_name": "검증 전선",
				"final_rival_id": "rival_fixture",
				"final_enemy_id": "official_hero_leon",
				"enemy_pool_tags": ["kingdom_base"],
				"danger_goals": ["throne"],
				"recommended_role_tags": ["blocker"],
				"day_overlay_id": "overlay_fixture",
				"day28_choice_group": "day28_fixture"
			}
		},
		"front_day_overlays": {
			"overlay_fixture": {
				"front_id": "front_fixture",
				"days": {
					"29": {"eve_id": "finale_fixture"},
					"30": {"boss_enemy_id": "official_hero_leon"}
				}
			}
		},
		"front_operations": {
			"operation_fixture": {
				"display_name": "검증 작전",
				"front_id": "front_fixture",
				"choice_group": "day28_fixture",
				"day": 28,
				"description": "검증용 DAY 28 작전",
				"reward": {},
				"defense_modifier": {"apply_on_day": 30}
			}
		},
		"events": {
			"event_fixture": {
				"display_name": "검증 사건",
				"front_id": "front_fixture",
				"day": 15,
				"kind": "front_event",
				"text": "검증용 사건",
				"choices": []
			},
			"finale_fixture": {
				"display_name": "검증 결전 전야",
				"front_id": "front_fixture",
				"day": 29,
				"kind": "finale_eve",
				"text": "검증용 결전 전야",
				"rival_id": "rival_fixture",
				"rival_short_name": "레온",
				"rival_character_id": "CHR_HERO_LEON",
				"rival_emotion": "hero_final",
				"required_context": ["final_rival_portrait", "heart_id", "one_equipped_duo_link", "day28_front_operation", "relation_rival_fixture"],
				"relation_tiers": [
					{"min": 65, "text": "높은 관계"},
					{"min": 45, "text": "중간 관계"},
					{"min": 0, "text": "낮은 관계"}
				],
				"ending_hint": "검증 엔딩 방향",
				"day_info_overrides": {
					"title": "검증 DAY 29",
					"summary": "검증 요약",
					"compact_management_summary": "검증 짧은 요약",
					"management_hint": "검증 관리 힌트",
					"enemy_notice_line": "검증 적 예고",
					"cast_notice_line": "검증 등장인물",
					"compact_enemy_notice_line": "검증 짧은 적 예고",
					"management_dialogue_header": "검증 대사",
					"management_only_prompt": "검증 준비"
				},
				"dialogue_templates": [
					{"speaker": "CHR_PUDDING", "text": "{{heart_name}} {{duo_name}} {{operation_name}} {{operation_result}} {{ending_hint}} {{armistice_hint}} {{relation_line}}"},
					{"speaker": "CHR_GOB", "text": "검증 2"},
					{"speaker": "CHR_PYNN", "text": "검증 3"},
					{"speaker": "CHR_GOLDIN", "text": "검증 4"},
					{"speaker": "CHR_THIEF_NIA", "text": "검증 5"},
					{"speaker": "CHR_BATI", "text": "검증 6"},
					{"speaker": "CHR_DARKLORD_PLAYER", "text": "검증 7"},
					{"speaker": "CHR_BATI", "text": "검증 8"},
					{"speaker": "CHR_DARKLORD_PLAYER", "text": "검증 9"},
					{"speaker": "CHR_HERO_LEON", "text": "검증 10"}
				]
			}
		},
		"castle_hearts": {
			"heart_fixture": {
				"display_name": "검증 심장",
				"passives": [],
				"tradeoffs": [],
				"charge_sources": [],
				"active_skill_id": "slime_shield",
				"max_uses_per_battle": 1,
				"room_hp_by_stage": {"2": 420, "3": 600, "4": 820}
			}
		},
		"duo_links": {
			"link_fixture": {
				"display_name": "검증 합동기",
				"member_instance_ids": ["mon_core_pudding", "mon_contract_mori"],
				"unlock_condition": {},
				"gauge_sources": [],
				"effect_handler": "link_fixture_handler",
				"max_uses_per_battle": 1
			}
		},
		"monsters": {
			"monster_fixture": {
				"display_name": "검증 몬스터",
				"instance_id": "mon_fixture",
				"character_id": "CHR_SELEN",
				"skills": ["slime_shield"],
				"role_tags": ["rescue"]
			}
		},
		"enemies": {
			"enemy_fixture": {
				"display_name": "검증 적",
				"character_id": "CHR_HERO_LEON",
				"front_tags": ["fixture_front"],
				"skills": ["slime_shield"],
				"behavior_handler": "fixture_enemy_handler"
			}
		},
		"rival_finales": {
			"rival_fixture": {
				"display_name": "검증 라이벌",
				"front_id": "front_fixture",
				"enemy_id": "official_hero_leon",
				"character_id": "CHR_HERO_LEON",
				"phases": [{"id": "phase_1"}, {"id": "phase_2"}, {"id": "phase_3"}]
			}
		},
		"endings": {
			"ending_fixture": {
				"catalog_code": "E12",
				"priority": 120,
				"front_required": "front_fixture",
				"condition": {"metric": "castle.throne_hp_ratio", "op": ">", "value": 0},
				"reward_ids": [],
				"illustration": "res://assets/ui/endings/ending_true_demon_castle.png"
			}
		},
		"chronicle_goals": {
			"chronicle_fixture": {
				"goal_type": "front_clear",
				"target_id": "front_fixture",
				"threshold": 1,
				"reward_ids": []
			}
		}
	}


func _context() -> Dictionary:
	return {
		"characters": DataRegistry.characters,
		"skills": DataRegistry.skills,
		"enemies": DataRegistry.enemies,
		"raid_missions": DataRegistry.raid_missions,
		"monster_instances": DataRegistry.monster_instances,
		"metric_definitions": DataRegistry.run_metric_definitions,
		"duo_effect_handlers": ["link_fixture_handler", "spore_jelly_shelter", "ghostly_evacuate", "moon_scent_hunt", "molten_carapace", "stone_march", "false_beacon_vault"],
		"enemy_behavior_handlers": ["fixture_enemy_handler", "seal_chainbearer", "reliquary_guard", "choir_exorcist", "bounty_tracker", "combat_alchemist", "ledger_binder", "official_paladin_selen", "guild_commissioner_roman"]
	}


func _has_error(errors: Array[String], fragment: String) -> bool:
	for error in errors:
		if error.contains(fragment):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[Update3DataContract] FAIL: %s" % message)
