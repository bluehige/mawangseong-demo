extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const FrontService = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const DuoService = preload("res://scripts/systems/duo_links/DuoLinkService.gd")

const L02 := "link_ghostly_evacuate"
const L03 := "link_moon_scent_hunt"
const L04 := "link_molten_carapace"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_and_memory_unlocks()
	_test_equip_conflict()
	await _test_runtime_effects()
	print("DUO_LINKS_PHASE24_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_catalog_and_memory_unlocks() -> void:
	var catalog := DataRegistry.update3_duo_links
	_expect(catalog.size() == 6 and catalog.has(L02) and catalog.has(L03) and catalog.has(L04), "L01~L06 합동기 총 6개 카탈로그")
	for link_id in catalog.keys():
		var definition: Dictionary = catalog[link_id]
		var condition: Dictionary = definition.get("unlock_condition", {})
		var vfx: Dictionary = definition.get("vfx", {})
		_expect(int(condition.get("bond_each", 0)) == 45 and int(condition.get("personal_memory_each", 0)) == 1 and int(condition.get("deployed_together_days", 0)) == 3 and int(condition.get("role_combo_count", 0)) == 5, "%s 공통 유대·추억·출전·역할 조건" % link_id)
		_expect(not bool(vfx.get("placeholder", true)) and str(vfx.get("id", "")) != "" and FileAccess.file_exists(str(vfx.get("sheet", ""))), "%s 최종 VFX 시트·식별자" % link_id)
		_expect(str(DataRegistry.update3_events.get(str(condition.get("event_id", "")), {}).get("kind", "")) == "duo_memory", "%s 합동 기억 사건 연결" % link_id)
	var run := FrontService.default_legacy_active_run(2)
	var member_progress: Dictionary = {}
	var all_members: Array = []
	for definition_value in catalog.values():
		for member_id in definition_value.get("member_instance_ids", []):
			if not all_members.has(member_id):
				all_members.append(member_id)
			member_progress[str(member_id)] = {"bond": 45, "unlocked_memory_ids": ["personal_1"]}
	for day in [5, 10, 15]:
		run = DuoService.record_deployed_day(run, all_members, day, catalog)
	for link_id in catalog.keys():
		for source_value in catalog[link_id].get("gauge_sources", []):
			for index in range(5):
				run = DuoService.record_unlock_action(run, str(source_value.get("member_instance_id", "")), str(source_value.get("source_id", "")), int(source_value.get("threshold", 1)), "%s:%s:%d" % [link_id, str(source_value.get("source_id", "")), index], catalog)
	var eligible := DuoService.eligible_memory_event_ids(FrontService.default_update3_profile(), run, member_progress, catalog)
	_expect(eligible.size() == 6, "한 회차에 조건을 쌓아 여섯 합동 기억 모두 해금 후보 가능")
	var first_event := str(eligible[0])
	var completed := DuoService.complete_memory_event(FrontService.default_update3_profile(), first_event, catalog)
	_expect(bool(completed.get("ok", false)) and completed.get("profile", {}).get("duo_links", {}).get("unlocked", []).size() == 1, "합동 기억 확인 시 대응 합동기 영구 해금")
	var repeated := DuoService.complete_memory_event(completed.get("profile", {}), first_event, catalog)
	_expect(not bool(repeated.get("ok", false)) and str(repeated.get("error", "")).contains("이미"), "같은 합동 기억 사건 반복 방지")
	var low_bond := member_progress.duplicate(true)
	low_bond[str(catalog[L02]["member_instance_ids"][0])]["bond"] = 44
	_expect(not DuoService.eligible_memory_event_ids(FrontService.default_update3_profile(), run, low_bond, catalog).has(str(catalog[L02]["unlock_condition"]["event_id"])), "멤버 한 명 유대 44면 해당 기억 후보 제외")


func _test_equip_conflict() -> void:
	var profile := FrontService.default_update3_profile()
	profile["duo_links"]["unlocked"] = DataRegistry.update3_duo_links.keys()
	var run := FrontService.default_legacy_active_run(2)
	var first := DuoService.equip(profile, run, "link_spore_jelly_shelter", DataRegistry.update3_duo_links)
	var shared := DuoService.equip(profile, first.get("active_run", {}), L02, DataRegistry.update3_duo_links)
	_expect(bool(first.get("ok", false)) and not bool(shared.get("ok", false)) and str(shared.get("error", "")).contains("동시에"), "푸딩이 겹치는 L01·L02 동시 장착 거부")
	var separate := DuoService.equip(profile, first.get("active_run", {}), L03, DataRegistry.update3_duo_links)
	_expect(bool(separate.get("ok", false)), "멤버가 겹치지 않는 링크는 두 번째 슬롯 장착")


func _test_runtime_effects() -> void:
	var host = MainScene.instantiate()
	add_child(host)
	await get_tree().process_frame
	var game = host.get_node("GameRoot")
	game._set_campaign_save_path_for_tests("")
	game.current_screen = Constants.SCREEN_COMBAT
	game.combat_paused = true
	game.monster_units.clear()
	game.enemy_units.clear()
	var pudding = _add_monster(game, "slime", Vector2(250, 250))
	var bebe = _add_monster(game, "ghost_housemaid", Vector2(300, 250))
	var rescued = _add_monster(game, "spore_healer", Vector2(500, 250))
	rescued.hp = 20
	var rescued_before: Vector2 = rescued.global_position
	var pudding_hp := int(pudding.hp)
	game._apply_ghostly_evacuate(L02)
	_expect(rescued.global_position != rescued_before and rescued.global_position.distance_to(pudding.global_position) <= 45.0, "L02 최저 HP 아군을 푸딩 뒤 안전 위치로 이동")
	rescued.receive_damage(40)
	_expect(rescued.hp == 0 or rescued.hp == 20 - 30, "L02 구조 대상이 피해의 75%만 받음")
	_expect(pudding.hp == pudding_hp - 10 and is_equal_approx(float(pudding.duo_penalty_move_multiplier), 0.85), "L02 푸딩이 25% 대납·4초 이동 -15%")
	var gob = _add_monster(game, "goblin", Vector2(100, 400))
	var koko = _add_monster(game, "graveyard_hound", Vector2(120, 430))
	var marked = _add_enemy(game, "shieldbearer", Vector2(420, 410))
	marked.apply_duo_mark(6.0, "test")
	var marked_hp := int(marked.hp)
	game._apply_moon_scent_hunt(L03)
	var hunt_damage := marked_hp - int(marked.hp)
	_expect(hunt_damage > 0 and hunt_damage <= 80, "L03 두 번의 합동 타격 직접 피해 합계 상한 80")
	_expect(int(marked.armor_break_amount) == 2 and is_equal_approx(float(marked.armor_break_timer), 5.0), "L03 일반 적 DEF -2·5초")
	_expect(gob.global_position.distance_to(marked.global_position) < 220.0 and koko.global_position.distance_to(marked.global_position) < 220.0, "L03 두 멤버가 표식 대상에게 최대 140px 접근")
	_expect(is_equal_approx(float(gob.duo_damage_taken_multiplier), 1.10) and is_equal_approx(float(koko.duo_damage_taken_multiplier), 1.10), "L03 사용 대가로 둘의 받는 피해 +10%·3초")
	var pynn = _add_monster(game, "imp", Vector2(100, 600))
	var toktok = _add_monster(game, "armored_beetle", Vector2(130, 600))
	var burn_target = _add_enemy(game, "shieldbearer", Vector2(300, 600))
	var burn_hp := int(burn_target.hp)
	game._apply_molten_carapace(L04)
	_expect(burn_hp - int(burn_target.hp) <= 26 and int(burn_target.armor_break_amount) == 1, "L04 충격 피해 26 이하·DEF -1")
	_expect(is_equal_approx(float(toktok.skill_cooldowns.get("patch_plates", 0.0)), 3.0), "L04 톡톡 수리 재사용 대기 +3초")
	var burn_state: Dictionary = game.update3_active_run.get("duo_link_active_effects", []).back()
	var finished: Dictionary = game._update_molten_carapace_burn(burn_state, 5.0, DataRegistry.update3_duo_links[L04]["effect"])
	var burn_done := int(finished.get("targets", [])[0].get("damage_done", 0))
	_expect(burn_done <= 41 and burn_done >= 26, "L04 충격+5초 화상 직접 피해 상한 41")
	_expect(str(DataRegistry.update3_duo_links[L02].get("vfx", {}).get("effect_key", "")) == "ghost" and str(DataRegistry.update3_duo_links[L03].get("vfx", {}).get("effect_key", "")) == "moon" and str(DataRegistry.update3_duo_links[L04].get("vfx", {}).get("effect_key", "")) == "flame", "L02~L04 최종 VFX 효과 구분")
	for unit in [pudding, bebe, rescued, gob, koko, marked, pynn, toktok, burn_target]:
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


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[DuoLinksPhase24] FAIL: %s" % message)
