extends Node

const FrontService = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const DuoService = preload("res://scripts/systems/duo_links/DuoLinkService.gd")
const GaugePolicy = preload("res://scripts/systems/duo_links/DuoLinkGaugePolicy.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")
const LoadoutScene = preload("res://scenes/ui/screens/DuoLinkLoadoutScreen.tscn")
const HUDScene = preload("res://scenes/ui/hud/DuoLinkCombatHUD.tscn")
const MainScene = preload("res://scenes/main/Main.tscn")
const LINK_ID := "link_spore_jelly_shelter"

var failed := false
var assertion_count := 0
var hud_state: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_and_unlock()
	_test_equip_contract()
	_test_gauge_and_activation()
	_test_inactive_and_member_down()
	_test_settlement()
	_test_unit_effect_contract()
	await _test_loadout_screen()
	await _test_hud()
	await _test_game_root_flow()
	print("DUO_LINK_PHASE9_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_catalog_and_unlock() -> void:
	var catalog := DataRegistry.update3_duo_links
	_expect(catalog.has(LINK_ID), "Phase 10 누적 카탈로그에서도 L01 유지")
	var link: Dictionary = catalog.get(LINK_ID, {})
	_expect(link.get("member_instance_ids", []) == ["mon_core_pudding", "mon_contract_mori"], "L01 멤버는 푸딩+모리")
	_expect(int(link.get("effect", {}).get("radius", 0)) == 190 and int(link.get("effect", {}).get("shield", 0)) == 40, "반경 190·보호막 40")
	_expect(float(link.get("effect", {}).get("duration", 0.0)) == 5.0 and int(link.get("effect", {}).get("heal_per_second", 0)) == 3, "5초·초당 회복 3")
	_expect(int(link.get("effect", {}).get("cleanse_count", 0)) == 1 and float(link.get("effect", {}).get("action_lock_seconds", 0.0)) == 0.6, "정화 1개·행동 잠금 0.6초")
	_expect(int(link.get("max_uses_per_battle", 0)) == 1 and not bool(link.get("effect", {}).get("deals_damage", true)), "전투당 1회·피해 없음")
	var profile := FrontService.default_update3_profile()
	_expect(profile.get("duo_links", {}).get("unlocked", []).is_empty(), "합동기 자동 해금 금지")
	var unlocked := DuoService.unlock_fixture(profile, LINK_ID, catalog)
	_expect(bool(unlocked.get("ok", false)) and unlocked.get("profile", {}).get("duo_links", {}).get("unlocked", []).has(LINK_ID), "프로필 해금 fixture")


func _test_equip_contract() -> void:
	var catalog := _synthetic_catalog()
	var profile := _unlocked_profile(catalog.keys())
	var run := FrontService.default_legacy_active_run(2)
	var first := DuoService.equip(profile, run, LINK_ID, catalog)
	_expect(bool(first.get("ok", false)) and first.get("active_run", {}).get("equipped_duo_links", []).size() == 1, "새 회차 첫 슬롯 장착")
	var duplicate := DuoService.equip(profile, first.get("active_run", {}), "link_shared_pudding", catalog)
	_expect(not bool(duplicate.get("ok", false)) and str(duplicate.get("error", "")).contains("동시에"), "한 멤버의 두 링크 중복 장착 거부")
	var second := DuoService.equip(profile, first.get("active_run", {}), "link_other", catalog)
	_expect(bool(second.get("ok", false)) and second.get("active_run", {}).get("equipped_duo_links", []).size() == 2, "서로 다른 멤버 링크는 두 번째 슬롯 장착")
	var third := DuoService.equip(profile, second.get("active_run", {}), "link_third", catalog)
	_expect(not bool(third.get("ok", false)) and str(third.get("error", "")).contains("최대 2개"), "세 번째 링크 장착 거부")
	_expect(DuoService.unequip(second.get("active_run", {}), "link_other").get("equipped_duo_links", []) == [LINK_ID], "장착 해제 후 슬롯 복구")


func _test_gauge_and_activation() -> void:
	var catalog := DataRegistry.update3_duo_links
	var run := DuoService.begin_battle(_active_run(), ["mon_core_pudding", "mon_contract_mori"], catalog)
	_expect(bool(run.get("duo_link_states", {}).get(LINK_ID, {}).get("active", false)), "두 멤버 출전 시 활성")
	_expect(not bool(run.get("duo_link_auto_use", true)), "자동 사용 토글 기본 OFF")
	var auto_run := _active_run()
	auto_run["duo_link_auto_use"] = true
	_expect(bool(DuoService.begin_battle(auto_run, ["mon_core_pudding", "mon_contract_mori"], catalog).get("duo_link_auto_use", false)), "사용자가 켠 자동 사용 설정은 전투 시작에 유지")
	var absorb_19 := DuoService.record_action(run, LINK_ID, "mon_core_pudding", "damage_absorbed", 19, "same_event", catalog)
	_expect(int(absorb_19.get("gain", -1)) == 0, "푸딩 흐수 20 미만은 보류")
	var duplicate := DuoService.record_action(absorb_19.get("active_run", {}), LINK_ID, "mon_core_pudding", "damage_absorbed", 20, "same_event", catalog)
	_expect(int(duplicate.get("gain", -1)) == 0, "동일 사건 중복 충전 없음")
	var absorb_1 := DuoService.record_action(absorb_19.get("active_run", {}), LINK_ID, "mon_core_pudding", "damage_absorbed", 1, "absorb_1", catalog)
	_expect(int(absorb_1.get("gain", 0)) == 3, "푸딩 누적 흡수 20마다 +3")
	var heal := DuoService.record_action(absorb_1.get("active_run", {}), LINK_ID, "mon_contract_mori", "effective_heal", 15, "heal_1", catalog)
	_expect(int(heal.get("gain", 0)) == 3, "모리 실제 회복 15마다 +3")
	var capped := DuoService.record_action(heal.get("active_run", {}), LINK_ID, "mon_core_pudding", "damage_absorbed", 100, "absorb_cap", catalog)
	_expect(int(capped.get("gain", 0)) == GaugePolicy.MAX_GAIN_PER_ACTION, "행동 1회 충전 상한 10")
	run = capped.get("active_run", {})
	var index := 0
	while int(run.get("duo_link_states", {}).get(LINK_ID, {}).get("charge", 0)) < 100 and index < 100:
		run = DuoService.record_action(run, LINK_ID, "mon_contract_mori", "effective_heal", 60, "fill_%d" % index, catalog).get("active_run", {})
		index += 1
	_expect(int(run.get("duo_link_states", {}).get(LINK_ID, {}).get("charge", 0)) == 100 and bool(run.get("duo_link_states", {}).get(LINK_ID, {}).get("ready", false)), "게이지 100에서 준비 완료·초과 충전 없음")
	var activated := DuoService.activate(run, LINK_ID, catalog)
	_expect(bool(activated.get("ok", false)) and str(activated.get("effect_handler", "")) == "spore_jelly_shelter", "수동 발동 성공")
	run = activated.get("active_run", {})
	_expect(bool(run.get("duo_link_states", {}).get(LINK_ID, {}).get("used_this_battle", false)), "발동 후 전투당 사용 완료 기록")
	var recharge := DuoService.record_action(run, LINK_ID, "mon_contract_mori", "effective_heal", 999, "after_use", catalog)
	_expect(int(recharge.get("gain", -1)) == 0 and int(recharge.get("active_run", {}).get("duo_link_states", {}).get(LINK_ID, {}).get("charge", -1)) == 0, "사용 후 재충전 불가")
	var reused := DuoService.activate(recharge.get("active_run", {}), LINK_ID, catalog)
	_expect(not bool(reused.get("ok", false)) and str(reused.get("error", "")).contains("이미 사용"), "게이지를 다시 채워도 재사용 불가")


func _test_inactive_and_member_down() -> void:
	var catalog := DataRegistry.update3_duo_links
	var inactive := DuoService.begin_battle(_active_run(), ["mon_core_pudding"], catalog)
	var state: Dictionary = inactive.get("duo_link_states", {}).get(LINK_ID, {})
	_expect(not bool(state.get("active", true)) and str(state.get("inactive_reason", "")).contains("mon_contract_mori"), "미출전 멤버 링크 비활성 표시")
	_expect(int(inactive.get("duo_link_inactive_count", 0)) == 1, "전투 시작 비활성 합동기 수 요약")
	_expect(DuoService.deployment_warnings(_active_run(), ["mon_core_pudding"], catalog).size() == 1, "편성 단계 미출전 경고는 배치를 막지 않음")
	var active := DuoService.begin_battle(_active_run(), ["mon_core_pudding", "mon_contract_mori"], catalog)
	active = DuoService.record_action(active, LINK_ID, "mon_core_pudding", "damage_absorbed", 20, "before_down", catalog).get("active_run", {})
	var downed := DuoService.member_downed(active, "mon_contract_mori", catalog)
	state = downed.get("duo_link_states", {}).get(LINK_ID, {})
	_expect(not bool(state.get("active", true)) and int(state.get("charge", 0)) == 3, "멤버 전투 불능 시 게이지 동결")
	var after_down := DuoService.record_action(downed, LINK_ID, "mon_core_pudding", "damage_absorbed", 200, "after_down", catalog)
	_expect(int(after_down.get("gain", -1)) == 0 and int(after_down.get("active_run", {}).get("duo_link_states", {}).get(LINK_ID, {}).get("charge", 0)) == 3, "멤버 다운 뒤 충전 불가")


func _test_settlement() -> void:
	var profile := _unlocked_profile([LINK_ID])
	var run := DuoService.begin_battle(_active_run(), ["mon_core_pudding", "mon_contract_mori"], DataRegistry.update3_duo_links)
	var state: Dictionary = run.get("duo_link_states", {}).get(LINK_ID, {})
	state["used_this_battle"] = true
	run["duo_link_states"][LINK_ID] = state
	var settled := DuoService.settle_profile(profile, run, 4)
	_expect(int(settled.get("duo_links", {}).get("usage_counts", {}).get(LINK_ID, 0)) == 1, "정산에서 사용 횟수 +1")
	_expect(int(settled.get("duo_links", {}).get("first_use_cycle", {}).get(LINK_ID, 0)) == 4, "최초 사용 회차 기록")


func _test_unit_effect_contract() -> void:
	var unit = UnitScript.new()
	add_child(unit)
	unit.setup("slime", {"display_name": "시험 푸딩", "max_hp": 100, "atk": 1, "def": 0}, "monster", "entrance")
	unit.grant_duo_barrier(40)
	_expect(unit.receive_damage(30) == 0 and unit.hp == 100 and unit.duo_barrier == 10, "보호막이 HP보다 먼저 피해 흡수")
	_expect(unit.receive_damage(20) == 10 and unit.hp == 90 and unit.duo_barrier == 0, "남은 보호막 소진 후 HP 피해")
	unit.hp = 40
	unit.soft_counter_healing_multiplier = 0.5
	unit.heart_healing_multiplier = 0.5
	_expect(unit.heal(20, "first", true) == 20, "첫 회복 틱은 회복 피로 무시")
	_expect(unit.heal(20, "later", false) == 5, "후속 회복 틱은 회복 피로 적용")
	unit.apply_slow(3.0, 0.5)
	_expect(unit.cleanse_one_negative_status() and unit.slow_timer == 0.0, "상태 이상 1개 정화")
	unit.apply_duo_action_lock(0.6)
	_expect(unit.duo_action_locked() and is_equal_approx(unit.duo_action_lock_timer, 0.6), "두 멤버 행동 잠금 0.6초")
	unit.queue_free()


func _test_loadout_screen() -> void:
	var screen = LoadoutScene.instantiate()
	add_child(screen)
	screen.setup(_unlocked_profile([LINK_ID]), _active_run(), DataRegistry.update3_duo_links, ["mon_core_pudding"])
	await get_tree().process_frame
	var slots: Dictionary = screen.slot_contract()
	_expect(str(slots.get("slot_1", "")) == LINK_ID and str(slots.get("slot_2", "")) == "" and int(slots.get("max_slots", 0)) == 2, "정식 편성 화면의 2개 슬롯")
	_expect(screen.content_root != null and is_instance_valid(screen.content_root), "정식 합동기 편성 화면 생성")
	var auto_toggle = screen.content_root.get_node_or_null("DuoLinkAutoUseToggle")
	_expect(auto_toggle != null and not auto_toggle.button_pressed, "자동 사용 토글 UI 기본 OFF")
	screen.queue_free()
	await get_tree().process_frame


func _test_hud() -> void:
	var hud = HUDScene.instantiate()
	add_child(hud)
	hud_state = {"equipped": [LINK_ID], "states": {LINK_ID: {"charge": 100, "active": true, "used_this_battle": false, "inactive_reason": ""}}, "names": {LINK_ID: "포자 젤리 피난처"}}
	hud.setup(Callable(self, "_provide_hud_state"), Callable())
	await get_tree().process_frame
	_expect(hud.visible and hud.use_button != null and not hud.use_button.disabled, "최소 HUD는 이름·게이지·수동 발동 상태 표시")
	hud_state["states"][LINK_ID]["used_this_battle"] = true
	await get_tree().process_frame
	_expect(hud.use_button.disabled, "사용 완료 뒤 HUD 발동 비활성")
	hud.queue_free()
	await get_tree().process_frame


func _provide_hud_state() -> Dictionary:
	return hud_state


func _test_game_root_flow() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.campaign_cycle_index = 2
	game.update3_profile = _unlocked_profile([LINK_ID])
	game.update3_active_run = FrontService.default_legacy_active_run(2)
	game.update3_active_run["update3_enabled"] = true
	game.contract_board_pending_ids.clear()
	game.contract_board_pending_ids.append("spore_healer")
	game.contract_board_pending_ids.append("stone_sentinel")
	game.selected_contract_ids.clear()
	game._confirm_contract_selection()
	_expect(game.current_screen == Constants.SCREEN_DUO_LINK_LOADOUT and game.ui_layer.get_node_or_null("DuoLinkLoadoutScreen") != null, "실제 계약 확정 뒤 합동기 편성 화면 진입")
	_expect(not bool(game.update3_active_run.get("duo_link_loadout_confirmed", true)), "편성 화면 진입 전 확정 플래그 OFF")
	game._toggle_update3_duo_link(LINK_ID)
	_expect(game.update3_active_run.get("equipped_duo_links", []).has(LINK_ID), "실제 새 회차 L01 장착")
	_expect(DuoService.deployment_warnings(game.update3_active_run, game.deployed_instance_ids, DataRegistry.update3_duo_links).is_empty(), "푸딩+모리 출전 편성은 활성 예정")
	game._confirm_update3_duo_link_loadout()
	_expect(game.current_screen == Constants.SCREEN_CYCLE_DOCTRINE and bool(game.update3_active_run.get("duo_link_loadout_confirmed", false)), "합동기 확정 뒤 교리 선택으로 순차 진행")
	host.queue_free()
	await get_tree().process_frame


func _active_run() -> Dictionary:
	var run := FrontService.default_legacy_active_run(2)
	run["equipped_duo_links"] = [LINK_ID]
	return run


func _unlocked_profile(ids: Array) -> Dictionary:
	var profile := FrontService.default_update3_profile()
	profile["duo_links"]["unlocked"] = ids.duplicate()
	return profile


func _synthetic_catalog() -> Dictionary:
	var catalog := DataRegistry.update3_duo_links.duplicate(true)
	var base: Dictionary = catalog.get(LINK_ID, {}).duplicate(true)
	for pair in [["link_shared_pudding", ["mon_core_pudding", "mon_x"]], ["link_other", ["mon_a", "mon_b"]], ["link_third", ["mon_c", "mon_d"]]]:
		var item := base.duplicate(true)
		item["member_instance_ids"] = pair[1]
		catalog[pair[0]] = item
	return catalog


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		return
	failed = true
	push_error("[DuoLinkPhase9] FAIL: %s" % message)
