extends Node

const ContractRosterServiceScript = preload("res://scripts/systems/contracts/ContractRosterService.gd")
const MonsterInstanceValidatorScript = preload("res://scripts/systems/monsters/MonsterInstanceValidator.gd")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const CONTRACT_IDS := ["spore_healer", "stone_sentinel", "war_drummer", "moon_tracker", "mimic_porter"]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_contract_data()
	_test_selection_and_limits()
	await _test_runtime_contract_flow()
	if failed:
		print("UPDATE2_CONTRACT_ROSTER_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE2_CONTRACT_ROSTER_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_contract_data() -> void:
	_expect(DataRegistry.update2_contract_ids().size() == 5, "계약 게시판 후보 5종 로드")
	for contract_id in CONTRACT_IDS:
		var contract: Dictionary = DataRegistry.update2_contract(contract_id)
		var monster: Dictionary = DataRegistry.monster(contract_id)
		var instance_id := str(contract.get("instance_id", ""))
		var instance: Dictionary = DataRegistry.monster_instance(instance_id)
		_expect(not contract.is_empty() and str(contract.get("display_name", "")) != "", "%s 계약 설명" % contract_id)
		_expect(not monster.is_empty() and bool(monster.get("contract_monster", false)), "%s 전투 종 자료" % contract_id)
		_expect(str(instance.get("species_id", "")) == contract_id, "%s 고정 개체 연결" % contract_id)
		_expect(DataRegistry.character(str(instance.get("character_id", ""))).get("category", "") == "contract_monster", "%s 캐릭터 연결" % contract_id)
		var skill_slots: Array = monster.get("skill_slots", [])
		_expect(skill_slots.size() == 3 and skill_slots[0] != null and skill_slots[1] != null, "%s 고유 스킬 2개" % contract_id)
		for slot in [0, 1]:
			_expect(not DataRegistry.skill(str(skill_slots[slot])).is_empty(), "%s 스킬 %d 참조" % [contract_id, slot + 1])
	var instance_errors := MonsterInstanceValidatorScript.validate_catalog(DataRegistry.monster_instances, DataRegistry.monsters, DataRegistry.characters, DataRegistry.skills, DataRegistry.evolution_rules)
	_expect(instance_errors.is_empty(), "계약 개체를 포함한 전체 개체 참조 검증")


func _test_selection_and_limits() -> void:
	var offer_a := ContractRosterServiceScript.offer_ids(DataRegistry.update2_contracts, 424242)
	var offer_b := ContractRosterServiceScript.offer_ids(DataRegistry.update2_contracts, 424242)
	_expect(offer_a == offer_b and offer_a.size() == 5, "같은 회차 seed는 같은 계약 후보 순서")
	_expect(ContractRosterServiceScript.validate_contract_selection(["spore_healer"], DataRegistry.update2_contracts).size() > 0, "계약 1종 확정 거부")
	_expect(ContractRosterServiceScript.validate_contract_selection(["spore_healer", "stone_sentinel"], DataRegistry.update2_contracts).is_empty(), "서로 다른 계약 정확히 2종 허용")
	_expect(ContractRosterServiceScript.validate_contract_selection(["spore_healer", "spore_healer"], DataRegistry.update2_contracts).size() > 0, "중복 계약 거부")
	_expect(ContractRosterServiceScript.stage_deployment_limit("stage_01_cave") == 3, "Stage 01 출전 한도 3")
	_expect(ContractRosterServiceScript.stage_deployment_limit("stage_02_castle") == 4, "Stage 02 출전 한도 4")
	_expect(ContractRosterServiceScript.stage_deployment_limit("stage_03_keep") == 4, "Stage 03 출전 한도 4")
	_expect(ContractRosterServiceScript.stage_deployment_limit("stage_04_citadel") == 5, "Stage 04 출전 한도 5")
	var owned := ["mon_core_pudding", "mon_core_gob", "mon_core_pynn", "mon_contract_mori", "mon_contract_dolkong"]
	_expect(ContractRosterServiceScript.validate_deployment(owned.slice(0, 3), owned, "stage_01_cave").is_empty(), "Stage 01 출전 3명 허용")
	_expect(not ContractRosterServiceScript.validate_deployment(owned.slice(0, 4), owned, "stage_01_cave").is_empty(), "Stage 01 출전 4명 거부")
	_expect(ContractRosterServiceScript.validate_deployment(owned, owned, "stage_04_citadel").is_empty(), "Stage 04 출전 5명 허용")


func _test_runtime_contract_flow() -> void:
	var root = GameRootScene.instantiate()
	add_child(root)
	await get_tree().process_frame
	root._onboarding_reset_game()
	root.campaign_cycle_index = 2
	root.update2_cycle_seed = 2222
	root.contract_board_offer_ids = ContractRosterServiceScript.offer_ids(DataRegistry.update2_contracts, root.update2_cycle_seed)
	root.contract_board_pending_ids.clear()
	root.contract_board_pending_ids.append("spore_healer")
	root.contract_board_pending_ids.append("stone_sentinel")
	root._confirm_contract_selection()
	_expect(root.selected_contract_ids == ["spore_healer", "stone_sentinel"], "계약 게시판 확정값을 현재 회차에 기록")
	_expect(root.monster_roster.has("spore_healer") and root.monster_roster.has("stone_sentinel"), "선택한 계약 2종만 보유 로스터에 합류")
	_expect(not root.monster_roster.has("war_drummer"), "선택하지 않은 계약은 합류하지 않음")
	_expect(root.deployed_instance_ids.size() == 3 and root.deployed_instance_ids.has("mon_core_pudding"), "계약 2종과 푸딩을 Stage 01 기본 출전 편성")
	_expect(root.reserve_instance_ids.has("mon_core_gob") and root.reserve_instance_ids.has("mon_core_pynn"), "나머지 핵심 몬스터는 예비 편성")
	var payload: Dictionary = root._campaign_save_payload(Constants.SCREEN_CONTRACT_BOARD)
	_expect(payload.get("update2", {}).get("selected_contract_ids", []) == root.selected_contract_ids, "계약 선택을 캠페인 저장 자료에 기록")
	_expect(payload.get("update2", {}).get("deployed_instance_ids", []) == root.deployed_instance_ids, "출전 편성을 캠페인 저장 자료에 기록")
	var v2_migration := SaveV1ToV2MigratorScript.migrate_inspection({"status": "valid", "payload": payload, "summary": {"day": GameState.day}, "saved_at_unix": 1783872000, "saved_at_text": "2026-07-13"}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v2_migration.get("ok", false)), "계약 몬스터를 포함한 저장 v1→v2 변환")
	var v3_migration := SaveV2ToV3MigratorScript.migrate_envelope(v2_migration.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	_expect(bool(v3_migration.get("ok", false)), "계약 몬스터를 포함한 저장 v2→v3 변환")
	var v3: Dictionary = v3_migration.get("envelope", {})
	_expect(v3.get("active_run", {}).get("selected_contract_ids", []) == root.selected_contract_ids, "저장 v3 현재 회차에 계약 2종 보존")
	_expect(v3.get("active_run", {}).get("monsters", {}).has("mon_contract_mori") and v3.get("active_run", {}).get("monsters", {}).has("mon_contract_dolkong"), "저장 v3에 계약 개체 성장 자료 보존")
	_expect(v3.get("profile", {}).get("contract_history", []).size() == 1 and v3.get("profile", {}).get("unlocked_contract_ids", []).size() == 2, "저장 v3 프로필에 계약 해금·이력 보존")
	root._clear_units()
	root.combat_scene.spawn_monsters()
	var spawned_ids: Array[String] = []
	for unit in root.monster_units:
		spawned_ids.append(str(unit.unit_id))
	_expect(spawned_ids.size() == 3, "Stage 출전 한도를 실제 전투 생성 수에 적용")
	_expect(spawned_ids.has("spore_healer") and spawned_ids.has("stone_sentinel") and spawned_ids.has("slime"), "출전 편성에 든 3명만 실제 전투에 등장")
	_expect(not spawned_ids.has("goblin") and not spawned_ids.has("imp"), "예비 몬스터는 실제 전투 생성에서 제외")
	_test_contract_skill_effects(root)
	root.queue_free()
	await get_tree().process_frame


func _test_contract_skill_effects(root) -> void:
	root._clear_units()
	root.monster_units.clear()
	root.enemy_units.clear()
	var actors: Dictionary = {}
	for contract_id in CONTRACT_IDS:
		var actor = root._create_unit(contract_id, DataRegistry.monster(contract_id), Constants.FACTION_MONSTER, "entrance")
		actor.global_position = Vector2(700 + actors.size() * 24, 520)
		root.monster_units.append(actor)
		actors[contract_id] = actor
	var ally = root._create_unit("slime", DataRegistry.monster("slime"), Constants.FACTION_MONSTER, "entrance")
	ally.global_position = Vector2(760, 520)
	root.monster_units.append(ally)
	var enemy = root._create_unit("explorer", DataRegistry.enemy("explorer"), Constants.FACTION_ENEMY, "entrance")
	enemy.global_position = Vector2(820, 520)
	root.enemy_units.append(enemy)
	GameState.mana = 999
	ally.receive_damage(70)
	var ally_before := int(ally.hp)
	root.selected_unit = actors["spore_healer"]
	_expect(root.combat_scene.use_selected_skill(0) and int(ally.hp) > ally_before, "모리 포자 재생이 가장 다친 아군을 회복")
	root.selected_unit = actors["stone_sentinel"]
	_expect(root.combat_scene.use_selected_skill(0) and actors["stone_sentinel"].guard_bonus >= 5 and actors["stone_sentinel"].damage_reduction >= 0.25, "돌콩 뿌리내린 수호가 방어·피해 감소 적용")
	root.selected_unit = actors["war_drummer"]
	var guard_before := int(ally.guard_bonus)
	_expect(root.combat_scene.use_selected_skill(0) and int(ally.guard_bonus) > guard_before, "두둠 진군 장단이 같은 방 아군 방어 지원")
	root.selected_unit = actors["moon_tracker"]
	var enemy_hp_before := int(enemy.hp)
	_expect(root.combat_scene.use_selected_skill(0) and int(enemy.hp) < enemy_hp_before, "루미 달빛 표식이 적에게 실제 피해 적용")
	root.selected_unit = actors["mimic_porter"]
	_expect(root.combat_scene.use_selected_skill(0) and enemy.slow_timer > 0.0 and enemy.threat_unit == actors["mimic_porter"], "미미 가짜 보물이 적을 유인·둔화")


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[Update2ContractRoster] FAIL: %s" % message)
