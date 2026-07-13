extends Node

const FrontService = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const DuoService = preload("res://scripts/systems/duo_links/DuoLinkService.gd")
const MainScene = preload("res://scenes/main/Main.tscn")
const LoadoutScene = preload("res://scenes/ui/screens/DuoLinkLoadoutScreen.tscn")
const HUDScene = preload("res://scenes/ui/hud/DuoLinkCombatHUD.tscn")
const L01 := "link_spore_jelly_shelter"
const L05 := "link_stone_march"
const L06 := "link_false_beacon_vault"

var failed := false
var assertion_count := 0
var hud_state: Dictionary = {}
var activated_link_ids: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_contracts()
	_test_two_slot_equip_and_separate_gauges()
	_test_unit_caps()
	await _test_two_row_ui()
	await _test_runtime_effects_and_activation_order()
	print("DUO_LINKS_PHASE10_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_catalog_contracts() -> void:
	var catalog := DataRegistry.update3_duo_links
	_expect(catalog.size() == 6 and catalog.has(L01) and catalog.has(L05) and catalog.has(L06), "Phase 24 누적 6개 카탈로그에서 기존 L01·L05·L06 유지")
	var stone: Dictionary = catalog.get(L05, {})
	_expect(stone.get("member_instance_ids", []) == ["mon_contract_dolkong", "mon_contract_dudum"], "L05 멤버는 돌콩+두둠")
	_expect(str(stone.get("effect_handler", "")) == "stone_march", "L05 전투 처리기 연결")
	var stone_effect: Dictionary = stone.get("effect", {})
	_expect(int(stone_effect.get("radius", 0)) == 180 and int(stone_effect.get("damage", 0)) == 12 and int(stone_effect.get("morale_damage", 0)) == 30, "L05 반경·피해·사기 수치")
	_expect(float(stone_effect.get("ally_buff_seconds", 0.0)) == 5.0 and int(stone_effect.get("ally_def_bonus", 0)) == 1 and is_equal_approx(float(stone_effect.get("ally_move_multiplier", 0.0)), 1.06), "L05 아군 5초 방어+이동 버프")
	_expect(float(stone_effect.get("dolkong_move_lock_seconds", 0.0)) == 2.0, "L05 돌콩 이동 불가 2초")
	var beacon: Dictionary = catalog.get(L06, {})
	_expect(beacon.get("member_instance_ids", []) == ["mon_contract_lumi", "mon_contract_mimi"], "L06 멤버는 루미+미미")
	_expect(str(beacon.get("effect_handler", "")) == "false_beacon_vault", "L06 전투 처리기 연결")
	var beacon_effect: Dictionary = beacon.get("effect", {})
	_expect(float(beacon_effect.get("duration", 0.0)) == 6.0 and float(beacon_effect.get("lure_seconds", 0.0)) == 3.0, "L06 등대 6초·확인 3초")
	_expect(int(beacon_effect.get("max_lured_normal_enemies", 0)) == 2 and beacon_effect.get("excluded_unit_ids", []).has("thief"), "L06 유인 최대 2명·도둑 제외")
	_expect(float(beacon_effect.get("mark_seconds", 0.0)) == 6.0 and float(beacon_effect.get("mimi_cooldown_penalty", 0.0)) == 4.0, "L06 표식 6초·미미 재사용 +4초")


func _test_two_slot_equip_and_separate_gauges() -> void:
	var profile := FrontService.default_update3_profile()
	profile["duo_links"]["unlocked"] = [L01, L05, L06]
	var run := FrontService.default_legacy_active_run(2)
	var first := DuoService.equip(profile, run, L05, DataRegistry.update3_duo_links)
	var second := DuoService.equip(profile, first.get("active_run", {}), L06, DataRegistry.update3_duo_links)
	_expect(bool(first.get("ok", false)) and bool(second.get("ok", false)), "L05와 L06 동시 장착")
	run = second.get("active_run", {})
	_expect(run.get("equipped_duo_links", []) == [L05, L06], "장착 순서를 슬롯 1·2에 유지")
	var third := DuoService.equip(profile, run, L01, DataRegistry.update3_duo_links)
	_expect(not bool(third.get("ok", false)), "2슬롯이 차면 세 번째 링크 장착 거부")
	run = DuoService.begin_battle(run, ["mon_contract_dolkong", "mon_contract_dudum", "mon_contract_lumi", "mon_contract_mimi"], DataRegistry.update3_duo_links)
	var result := DuoService.record_action(run, L05, "mon_contract_dolkong", "fixed_attack", 1, "stone_a", DataRegistry.update3_duo_links)
	run = result.get("active_run", {})
	_expect(int(result.get("gain", 0)) == 3 and _charge(run, L05) == 3 and _charge(run, L06) == 0, "돌콩 고정 공격은 L05만 +3")
	result = DuoService.record_action(run, L05, "mon_contract_dudum", "buffed_ally", 3, "drum_a", DataRegistry.update3_duo_links)
	run = result.get("active_run", {})
	_expect(int(result.get("gain", 0)) == 6 and _charge(run, L05) == 9 and _charge(run, L06) == 0, "두둠 아군 3명 버프는 L05만 +6")
	result = DuoService.record_action(run, L06, "mon_contract_lumi", "mark_success", 1, "mark_a", DataRegistry.update3_duo_links)
	run = result.get("active_run", {})
	_expect(int(result.get("gain", 0)) == 5 and _charge(run, L05) == 9 and _charge(run, L06) == 5, "루미 표식은 L06만 +5")
	result = DuoService.record_action(run, L06, "mon_contract_mimi", "false_treasure_contact", 3, "mimi_a", DataRegistry.update3_duo_links)
	run = result.get("active_run", {})
	_expect(int(result.get("gain", 0)) == 10 and _charge(run, L06) == 15, "미미 접촉은 한 행동 상한 10")
	var duplicate := DuoService.record_action(run, L06, "mon_contract_mimi", "false_treasure_contact", 1, "mimi_a", DataRegistry.update3_duo_links)
	_expect(int(duplicate.get("gain", -1)) == 0 and _charge(duplicate.get("active_run", {}), L06) == 15, "같은 이벤트는 중복 충전 없음")
	run["duo_link_states"][L05]["charge"] = 100
	run["duo_link_states"][L05]["ready"] = true
	run["duo_link_states"][L06]["charge"] = 100
	run["duo_link_states"][L06]["ready"] = true
	var l06_used := DuoService.activate(run, L06, DataRegistry.update3_duo_links)
	run = l06_used.get("active_run", {})
	_expect(bool(l06_used.get("ok", false)) and bool(run["duo_link_states"][L06]["used_this_battle"]), "슬롯 2의 L06을 지정 발동")
	_expect(bool(run["duo_link_states"][L05]["ready"]) and not bool(run["duo_link_states"][L05]["used_this_battle"]), "L06 발동 후에도 L05 준비 상태 유지")
	var l05_used := DuoService.activate(run, L05, DataRegistry.update3_duo_links)
	_expect(bool(l05_used.get("ok", false)) and bool(l05_used.get("active_run", {})["duo_link_states"][L05]["used_this_battle"]), "다음 순서로 L05도 발동")
	var one_missing := DuoService.begin_battle(second.get("active_run", {}), ["mon_contract_dolkong", "mon_contract_dudum", "mon_contract_lumi"], DataRegistry.update3_duo_links)
	_expect(bool(one_missing["duo_link_states"][L05]["active"]) and not bool(one_missing["duo_link_states"][L06]["active"]), "멤버 한 명 미출전은 해당 링크만 비활성")


func _test_unit_caps() -> void:
	var unit = preload("res://scripts/units/Unit.gd").new()
	add_child(unit)
	unit.setup("explorer", {"display_name": "테스트 용병", "max_hp": 100, "morale": 20, "move_speed": 100}, Constants.FACTION_ENEMY, "entrance")
	_expect(unit.receive_morale_damage(30) == 20 and unit.morale == 0, "사기 피해는 0 아래로 내려가지 않음")
	unit.apply_duo_march_buff(5.0, 1, 1.06)
	_expect(unit.guard_bonus == 1 and is_equal_approx(unit.duo_march_move_multiplier, 1.06), "행진곡 방어+이동 버프 적용")
	unit.apply_duo_move_lock(2.0)
	_expect(is_equal_approx(unit.duo_move_lock_timer, 2.0), "돌콩 이동 잠금 2초 저장")
	unit.apply_duo_mark(6.0, "mon_contract_lumi")
	_expect(is_equal_approx(unit.duo_mark_timer, 6.0) and unit.duo_mark_source_id == "mon_contract_lumi", "루미 표식 6초 및 출처 저장")
	unit.queue_free()


func _test_two_row_ui() -> void:
	var profile := FrontService.default_update3_profile()
	profile["duo_links"]["unlocked"] = [L01, L05, L06]
	var run := FrontService.default_legacy_active_run(2)
	run["equipped_duo_links"] = [L05, L06]
	var screen = LoadoutScene.instantiate()
	add_child(screen)
	screen.setup(profile, run, DataRegistry.update3_duo_links, ["mon_contract_dolkong", "mon_contract_dudum", "mon_contract_lumi", "mon_contract_mimi"])
	await get_tree().process_frame
	var card_rects: Array[Rect2] = screen.link_card_rects_for_viewport(Vector2(1366, 768))
	_expect(card_rects.size() == 6 and not card_rects[0].intersects(card_rects[1]) and not card_rects[1].intersects(card_rects[2]), "1366×768 장착 화면의 6개 카드가 겹치지 않음")
	screen.queue_free()
	var hud = HUDScene.instantiate()
	add_child(hud)
	hud_state = {
		"equipped": [L05, L06],
		"states": {L05: {"charge": 100, "active": true, "used_this_battle": false}, L06: {"charge": 100, "active": true, "used_this_battle": false}},
		"names": {L05: "석상 행진곡", L06: "가짜 등대 금고"}
	}
	hud.setup(Callable(self, "_provide_hud_state"), Callable(self, "_capture_activation"))
	await get_tree().process_frame
	_expect(hud.row_panels[0].visible and hud.row_panels[1].visible and hud.use_buttons.size() == 2, "전투 HUD에 장착 링크 2개를 두 줄로 표시")
	var row_rects: Array[Rect2] = hud.row_rects_for_viewport(Vector2(1366, 768))
	_expect(row_rects.size() == 2 and not row_rects[0].intersects(row_rects[1]), "1366×768 HUD 두 줄이 겹치지 않음")
	hud.use_buttons[1].pressed.emit()
	_expect(activated_link_ids == [L06], "두 번째 HUD 버튼은 L06만 지정 발동")
	hud_state["states"][L06]["used_this_battle"] = true
	await get_tree().process_frame
	_expect(hud.use_buttons[1].disabled and not hud.use_buttons[0].disabled, "L06 사용 후 L06 버튼만 비활성")
	hud.queue_free()
	await get_tree().process_frame


func _test_runtime_effects_and_activation_order() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.current_screen = Constants.SCREEN_COMBAT
	game.combat_paused = false
	game.monster_units.clear()
	game.enemy_units.clear()
	var dolkong = _add_monster(game, "stone_sentinel", Vector2(200, 200))
	var dudum = _add_monster(game, "war_drummer", Vector2(230, 200))
	var lumi = _add_monster(game, "moon_tracker", Vector2(300, 200))
	var mimi = _add_monster(game, "mimic_porter", Vector2(330, 200))
	var ally = _add_monster(game, "slime", Vector2(240, 220))
	var near_enemy = _add_enemy(game, "explorer", Vector2(260, 200))
	var normal_b = _add_enemy(game, "engineer", Vector2(300, 230))
	var normal_c = _add_enemy(game, "roman", Vector2(350, 230))
	var thief = _add_enemy(game, "thief", Vector2(310, 210))
	var appraiser = _add_enemy(game, "explorer", Vector2(320, 210))
	appraiser.role = "appraiser"
	var far_enemy = _add_enemy(game, "explorer", Vector2(700, 700))
	for enemy in [near_enemy, normal_b, normal_c, thief, appraiser, far_enemy]:
		enemy.morale = 100
	var run := FrontService.default_legacy_active_run(2)
	run["equipped_duo_links"] = [L05, L06]
	game.update3_active_run = DuoService.begin_battle(run, ["mon_contract_dolkong", "mon_contract_dudum", "mon_contract_lumi", "mon_contract_mimi"], DataRegistry.update3_duo_links)
	for link_id in [L05, L06]:
		game.update3_active_run["duo_link_states"][link_id]["charge"] = 100
		game.update3_active_run["duo_link_states"][link_id]["ready"] = true
	game._activate_update3_duo_link(L06)
	_expect(bool(game.update3_active_run["duo_link_states"][L06]["used_this_battle"]) and bool(game.update3_active_run["duo_link_states"][L05]["ready"]), "실제 전투에서 L06만 먼저 발동")
	var beacon_states: Array = game.update3_active_run.get("duo_link_active_effects", [])
	var target_entries: Array = beacon_states[0].get("targets", []) if not beacon_states.is_empty() else []
	var target_ids: Array = target_entries.map(func(entry): return int(entry.get("node_id", 0)))
	_expect(target_entries.size() == 2, "가짜 등대는 일반 적 최대 2명만 유인")
	_expect(not target_ids.has(thief.get_instance_id()) and not target_ids.has(appraiser.get_instance_id()), "도둑과 감정가는 유인 대상에서 제외")
	_expect(is_equal_approx(appraiser.duo_mark_timer, 6.0), "감정가는 즉시 루미 표식")
	var beacon_effect: Dictionary = DataRegistry.update3_duo_links[L06]["effect"]
	var checked: Dictionary = game._update_false_beacon_effect(beacon_states[0], 3.0, beacon_effect)
	var marked_count := 0
	for target_id in target_ids:
		var target = instance_from_id(target_id)
		if target != null and target.duo_mark_timer > 0.0:
			marked_count += 1
	_expect(marked_count == 2 and bool(checked.get("checked", false)), "3초 확인을 끝낸 유인 대상 2명에게 표식")
	var ended: Dictionary = game._update_false_beacon_effect(checked, 3.0, beacon_effect)
	_expect(bool(ended.get("penalty_applied", false)) and is_equal_approx(float(mimi.skill_cooldowns.get("false_treasure", 0.0)), 4.0), "등대 종료 후 미미 가짜 보물 재사용 +4초")
	var near_hp := int(near_enemy.hp)
	var far_hp := int(far_enemy.hp)
	game._activate_update3_duo_link(L05)
	_expect(bool(game.update3_active_run["duo_link_states"][L05]["used_this_battle"]), "이어서 실제 L05 발동")
	_expect(near_enemy.hp == near_hp - 12 and near_enemy.morale == 70, "L05 반경 내 적에게 피해 12·사기 30")
	_expect(far_enemy.hp == far_hp and far_enemy.morale == 100, "L05 반경 밖 적은 영향 없음")
	_expect(ally.guard_bonus == 1 and is_equal_approx(ally.duo_march_move_multiplier, 1.06), "L05 반경 내 아군 방어+1·이동+6%")
	_expect(is_equal_approx(dolkong.duo_move_lock_timer, 2.0), "L05 발동 비용으로 돌콩 2초 이동 잠금")
	for unit in [dolkong, dudum, lumi, mimi, ally, near_enemy, normal_b, normal_c, thief, appraiser, far_enemy]:
		unit.queue_free()
	host.queue_free()
	await get_tree().process_frame


func _add_monster(game: Node, species_id: String, position: Vector2):
	var unit = game._create_unit(species_id, DataRegistry.monster(species_id), Constants.FACTION_MONSTER, "entrance")
	unit.global_position = position
	game.monster_units.append(unit)
	return unit


func _add_enemy(game: Node, enemy_id: String, position: Vector2):
	var unit = game._create_unit(enemy_id, DataRegistry.enemy(enemy_id), Constants.FACTION_ENEMY, "entrance")
	unit.global_position = position
	game.enemy_units.append(unit)
	return unit


func _charge(run: Dictionary, link_id: String) -> int:
	return int(run.get("duo_link_states", {}).get(link_id, {}).get("charge", 0))


func _provide_hud_state() -> Dictionary:
	return hud_state


func _capture_activation(link_id: String) -> void:
	activated_link_ids.append(link_id)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		return
	failed = true
	push_error("[DuoLinksPhase10] FAIL: %s" % message)
