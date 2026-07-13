extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const ContractRosterServiceScript = preload("res://scripts/systems/contracts/ContractRosterService.gd")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const DOCTRINE_IDS := [
	"royal_supply_lock", "royal_mana_watch", "royal_bounty_decree",
	"royal_contract_registry", "royal_fortification_audit", "royal_adaptive_command"
]
const DECREE_IDS := [
	"decree_open_pantry", "decree_arcane_rationing", "decree_family_watch",
	"decree_mobile_reserve", "decree_trap_maintenance", "decree_rival_protocol"
]
const SEAL_IDS := [
	"seal_no_throne_damage", "seal_no_monster_down", "seal_low_mana",
	"seal_no_facility_disable", "seal_contract_vanguard", "seal_adaptive_rival"
]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalogs()
	await _test_selection_effects_and_save()
	if failed:
		print("UPDATE2_CYCLE_CHOICES_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE2_CYCLE_CHOICES_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalogs() -> void:
	_expect(DataRegistry.cycle_doctrine_ids() == DOCTRINE_IDS, "왕국 교리 6종 고정 ID와 순서")
	_expect(DataRegistry.cycle_decree_ids() == DECREE_IDS, "마왕 칙령 6종 고정 ID와 순서")
	_expect(DataRegistry.challenge_seal_ids() == SEAL_IDS, "도전 인장 6종 고정 ID와 순서")
	for doctrine_id in DOCTRINE_IDS:
		var doctrine: Dictionary = DataRegistry.cycle_doctrine(doctrine_id)
		_expect(str(doctrine.get("kingdom_title", "")) != "", "%s 교리 제목" % doctrine_id)
		_expect(str(doctrine.get("effect_label", "")) != "", "%s 교리 적용 효과" % doctrine_id)
	for decree_id in DECREE_IDS:
		var decree: Dictionary = DataRegistry.cycle_decree(decree_id)
		_expect(str(decree.get("title", "")) != "", "%s 칙령 제목" % decree_id)
		_expect(not decree.get("effects", {}).is_empty(), "%s 칙령 런타임 효과" % decree_id)
	for seal_id in SEAL_IDS:
		var seal: Dictionary = DataRegistry.challenge_seal(seal_id)
		_expect(str(seal.get("condition_id", "")) != "", "%s 인장 판정 조건" % seal_id)
		_expect(int(seal.get("reward", {}).get("infamy", 0)) > 0, "%s 인장 달성 보상" % seal_id)


func _test_selection_effects_and_save() -> void:
	var root = GameRootScene.instantiate()
	add_child(root)
	await get_tree().process_frame
	root._onboarding_reset_game()
	root.campaign_cycle_index = 2
	root.update2_cycle_seed = 424242
	root.contract_board_offer_ids = ContractRosterServiceScript.offer_ids(DataRegistry.update2_contracts, root.update2_cycle_seed)
	root.contract_board_pending_ids.clear()
	root.contract_board_pending_ids.append("spore_healer")
	root.contract_board_pending_ids.append("stone_sentinel")
	root._confirm_contract_selection()
	_expect(root.current_screen == Constants.SCREEN_DUO_LINK_LOADOUT, "계약 확정 뒤 합동기 편성 화면")
	_expect(root._next_update2_cycle_setup_screen() == Constants.SCREEN_DUO_LINK_LOADOUT, "미확정 합동기 편성 재개 지점")
	root._confirm_update3_duo_link_loadout()
	_expect(root.current_screen == Constants.SCREEN_CYCLE_DOCTRINE, "합동기 편성 확정 뒤 교리 선택 화면")
	_expect(root._next_update2_cycle_setup_screen() == Constants.SCREEN_CYCLE_DOCTRINE, "미선택 교리 재개 지점")

	var mana_before := int(GameState.mana)
	root._select_cycle_doctrine("royal_adaptive_command")
	_expect(root.current_screen == Constants.SCREEN_CYCLE_DECREE, "교리 확정 뒤 칙령 선택 화면")
	_expect(root.campaign_profile.get("active_doctrine_id", "") == "royal_adaptive_command", "활성 교리 프로필 기록")
	_expect(root.campaign_profile.get("doctrine_history", []).size() == 1, "교리 선택 이력 1회 기록")
	_expect(is_equal_approx(root._update2_soft_counter_strength(0.30), 0.24), "적응 지휘가 소프트 카운터 강도를 20% 감소")
	root._select_cycle_doctrine("royal_supply_lock")
	_expect(root.campaign_profile.get("active_doctrine_id", "") == "royal_adaptive_command" and int(GameState.mana) == mana_before, "같은 회차 교리 중복 선택 차단")

	var mana_before_decree := int(GameState.mana)
	root._select_cycle_decree("decree_arcane_rationing")
	_expect(root.current_screen == Constants.SCREEN_CHALLENGE_SEAL, "칙령 확정 뒤 인장 선택 화면")
	_expect(root.campaign_profile.get("active_decree_id", "") == "decree_arcane_rationing", "활성 칙령 프로필 기록")
	_expect(int(GameState.mana) == mana_before_decree + 80, "마력 배급제 즉시 마력 보상 적용")
	var sample_skill := {"cost_mana": 21}
	_expect(root._current_skill_mana_cost(sample_skill) == 17, "마력 배급제 기술 소모 20% 감소 후 올림")
	root._select_cycle_decree("decree_mobile_reserve")
	_expect(root.campaign_profile.get("active_decree_id", "") == "decree_arcane_rationing", "같은 회차 칙령 중복 선택 차단")

	root._select_challenge_seal("seal_no_throne_damage")
	_expect(root.current_screen == Constants.SCREEN_MANAGEMENT, "인장 확정 뒤 관리 화면 진입")
	_expect(root.campaign_profile.get("active_challenge_seal_id", "") == "seal_no_throne_damage", "활성 인장 프로필 기록")
	_expect(root.campaign_profile.get("challenge_seal_history", []).size() == 1, "인장 선택 이력 1회 기록")
	root._select_challenge_seal("seal_low_mana")
	_expect(root.campaign_profile.get("active_challenge_seal_id", "") == "seal_no_throne_damage", "같은 회차 인장 중복 선택 차단")
	_expect(root._next_update2_cycle_setup_screen() == Constants.SCREEN_MANAGEMENT, "세 선택 완료 후 재개 지점은 관리 화면")

	root.campaign_profile["active_decree_id"] = "decree_mobile_reserve"
	_expect(root._current_stage_deployment_limit() == 4, "기동 예비대가 Stage 01 출전 상한을 3명에서 4명으로 확장")
	root.campaign_profile["active_decree_id"] = "decree_trap_maintenance"
	_expect(is_equal_approx(root._update2_cycle_effect_value("trap_cooldown_multiplier", 1.0), 0.70), "함정 정비일 재사용 시간 30% 감소")
	root.campaign_profile["active_decree_id"] = "decree_rival_protocol"
	_expect(is_equal_approx(root._update2_soft_counter_strength(0.30), 0.195), "교리와 숙적 규약의 대응 저항이 합산 적용")
	root.campaign_profile["active_decree_id"] = "decree_arcane_rationing"

	GameState.day = GameState.max_day
	GameState.demon_lord_hp = GameState.demon_lord_max_hp
	root.rewards_pending = {"gold": 0, "mana": 0, "food": 0, "infamy": 0}
	var seal_line: String = root._resolve_update2_challenge_seal(true)
	_expect(seal_line.begins_with("도전 인장 달성"), "DAY 30 흠 없는 왕좌 인장 달성 판정")
	_expect(int(root.rewards_pending.get("infamy", 0)) == 250, "인장 보상 악명 250을 결산 대기 보상에 추가")
	_expect(bool(root.campaign_profile.get("challenge_seal_history", [])[0].get("completed", false)), "인장 달성 상태를 선택 이력에 기록")
	root._resolve_update2_challenge_seal(true)
	_expect(int(root.rewards_pending.get("infamy", 0)) == 250, "같은 회차 인장 보상 중복 지급 차단")

	var payload: Dictionary = root._campaign_save_payload(Constants.SCREEN_MANAGEMENT)
	var v2_result := SaveV1ToV2MigratorScript.migrate_inspection({
		"status": "valid",
		"payload": payload,
		"summary": {"day": GameState.day},
		"saved_at_unix": 1783872000,
		"saved_at_text": "2026-07-13"
	}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v2_result.get("ok", false)), "교리·칙령·인장 포함 저장 v1→v2 변환")
	var v3_result := SaveV2ToV3MigratorScript.migrate_envelope(v2_result.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v3_result.get("ok", false)), "교리·칙령·인장 포함 저장 v2→v3 변환")
	var v3_profile: Dictionary = v3_result.get("envelope", {}).get("profile", {})
	_expect(v3_profile.get("active_doctrine_id", "") == "royal_adaptive_command", "저장 v3 활성 교리 보존")
	_expect(v3_profile.get("active_decree_id", "") == "decree_arcane_rationing", "저장 v3 활성 칙령 보존")
	_expect(v3_profile.get("active_challenge_seal_id", "") == "seal_no_throne_damage", "저장 v3 활성 인장 보존")
	_expect(v3_profile.get("doctrine_history", []).size() == 1 and v3_profile.get("decree_history", []).size() == 1 and v3_profile.get("challenge_seal_history", []).size() == 1, "저장 v3 세 선택 이력 보존")
	root.queue_free()
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[Update2CycleChoices] FAIL: %s" % message)
