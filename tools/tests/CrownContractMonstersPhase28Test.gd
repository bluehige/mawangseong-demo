extends Node

const CrownScript = preload("res://scripts/systems/crown/CrownEvolutionService.gd")
const PanelScript = preload("res://scripts/ui/CrownCandidatePanel.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_mastery_and_ui()
	_test_mori_crown()
	_test_toktok_crown()
	_test_popo_crown()
	_test_save_and_matrix()
	if failed:
		print("CROWN_CONTRACT_MONSTERS_PHASE28_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("CROWN_CONTRACT_MONSTERS_PHASE28_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _active() -> Dictionary:
	return {"campaign_mode_id": "council_season", "council_season": {"council_seals": 3, "crown_form_id": "", "crown_declined": false}}


func _instance(species_id: String, instance_id: String) -> Dictionary:
	return {"instance_id": instance_id, "species_id": species_id, "bond": 82, "level": 6, "growth_stage": 0, "specialization_id": "%s_tactic" % species_id, "evolution_id": ""}


func _test_catalog_mastery_and_ui() -> void:
	var catalog: Dictionary = DataRegistry.update4_catalogs.crown_evolutions
	_expect(catalog.size() == 6, "왕관 진화 출시 범위 정확히 6종")
	var contract_ids := ["crown_mori_grand_mycelial_priest", "crown_toktok_royal_armorer", "crown_popo_grand_night_courier"]
	var species := ["spore_healer", "armored_beetle", "bat_courier"]
	for index in contract_ids.size():
		var instance := _instance(species[index], "MON_%d" % index)
		var low := CrownScript.candidate_check(instance, catalog[contract_ids[index]], _active().council_season, {species[index]: 1})
		var ready := CrownScript.candidate_check(instance, catalog[contract_ids[index]], _active().council_season, {species[index]: 2})
		_expect(not bool(low.eligible) and low.reasons.has("species_mastery") and bool(ready.eligible), "%s 종별 숙련 2 gate" % contract_ids[index])
	var panel = PanelScript.new()
	add_child(panel)
	panel.configure([
		{"display_name": "A", "instance_id": "1"}, {"display_name": "B", "instance_id": "2"}, {"display_name": "C", "instance_id": "3"}, {"display_name": "D", "instance_id": "4"}, {"display_name": "E", "instance_id": "5"}
	])
	_expect(panel.candidate_buttons.size() == 4 and panel.decline_button.visible and panel.decline_button.custom_minimum_size.y == 48.0, "왕관 후보 UI 최대 4개·동등한 거절 선택")
	panel.queue_free()


func _test_mori_crown() -> void:
	var shield := CrownScript.mori_spore_sacrament(100, 100, true)
	_expect(bool(shield.ok) and int(shield.shield) == 35, "모리 과회복 50% 보호막·최대 HP35% 상한")
	var umbrella := CrownScript.mori_shared_umbrella([{"id": "a", "floor_id": "upper_02", "hp": 20, "max_hp": 100}, {"id": "b", "floor_id": "upper_02", "hp": 80, "max_hp": 100}, {"id": "c", "floor_id": "lower_01", "hp": 1, "max_hp": 100}], "upper_02", true, DataRegistry.skills.royal_shared_umbrella)
	_expect(umbrella.ally_ids == ["a", "b"] and bool(umbrella.cleanse) and float(umbrella.regeneration_seconds) == 5.0, "모리 같은 층 전체 정화·5초 재생")
	_expect(str(umbrella.rescue_target_id) == "a" and int(umbrella.rescue_hp) == 1, "모리 전투 불능 직전 1명 HP1 보호")
	_expect(is_equal_approx(float(umbrella.post_healing_multiplier), 0.85) and float(umbrella.post_healing_duration) == 6.0, "모리 스킬 후 회복 -15% 6초 약점")
	_expect(not bool(CrownScript.mori_spore_sacrament(20, 100, false).ok), "왕관실 무력화 시 모리 기능 정지")


func _test_toktok_crown() -> void:
	var forge := CrownScript.toktok_moving_forge(12, 35, true)
	_expect(bool(forge.ok) and int(forge.def) == 16, "톡톡 시설 피격 시 같은 방 방어 증가")
	var plating := CrownScript.toktok_emergency_plating([{"id": "crown_sanctum", "hp": 70, "max_hp": 100, "active": true}, {"id": "seal_vault", "hp": 20, "max_hp": 100, "active": true}], true, DataRegistry.skills.royal_emergency_plating)
	_expect(str(plating.target_id) == "seal_vault" and int(plating.repair) == 30 and float(plating.protection_seconds) == 8.0, "톡톡 최위험 목표 최대30% 수리·8초 방호")
	_expect(is_equal_approx(float(plating.post_move_multiplier), 0.75) and float(plating.post_move_duration) == 5.0, "톡톡 사용 후 이동 -25% 5초 약점")
	_expect(not bool(CrownScript.toktok_emergency_plating([], false, DataRegistry.skills.royal_emergency_plating).ok), "왕관실 무력화 시 톡톡 기능 정지")


func _test_popo_crown() -> void:
	var route := CrownScript.popo_shortest_mail_route(true)
	_expect(float(route.transition_seconds) == 0.20 and float(route.first_skill_cooldown_recovery) == 0.30 and float(route.capture_duration_multiplier) == 1.15, "포포 0.20초 전이·쿨30% 회복·포획15% 약점")
	var urgent := CrownScript.popo_urgent_courier("lower_01", {"id": "silky", "floor_id": "upper_02", "position": Vector2(320, 180)}, true, DataRegistry.skills.royal_urgent_courier)
	_expect(bool(urgent.ok) and str(urgent.target_id) == "silky" and str(urgent.target_floor_id) == "upper_02" and float(urgent.duration) == 6.0, "포포 다른 층 긴급전령 6초")
	_expect(float(urgent.move_multiplier) <= 1.30 and float(urgent.attack_interval_multiplier) >= 0.75 and float(urgent.status_resistance_bonus) == 0.20, "포포 이동·공격·상태저항 상한")
	_expect(not bool(CrownScript.popo_urgent_courier("upper_02", {"id": "silky", "floor_id": "upper_02"}, true, DataRegistry.skills.royal_urgent_courier).ok), "포포 같은 층 긴급전령 금지")
	_expect(not bool(CrownScript.popo_urgent_courier("lower_01", {"id": "silky", "floor_id": "upper_02"}, false, DataRegistry.skills.royal_urgent_courier).ok), "왕관실 무력화 시 포포 기능 정지")


func _test_save_and_matrix() -> void:
	var catalog: Dictionary = DataRegistry.update4_catalogs.crown_evolutions
	var mori := _instance("spore_healer", "mon_contract_mori")
	var confirmed := CrownScript.confirm(_active(), mori, "crown_mori_grand_mycelial_priest", catalog, {"spore_healer": 2})
	var restored = JSON.parse_string(JSON.stringify(confirmed.active_run))
	_expect(bool(confirmed.ok) and str(restored.council_season.crown_form_id) == "crown_mori_grand_mycelial_priest", "계약종 왕관 저장·복원")
	for crown_id in ["crown_mori_grand_mycelial_priest", "crown_toktok_royal_armorer", "crown_popo_grand_night_courier"]:
		for rival_id in DataRegistry.update4_rival_lords.keys():
			var trial := CrownScript.representative_matrix(crown_id, str(rival_id))
			_expect(bool(trial.viable) and not bool(trial.hard_countered) and float(trial.contribution_ratio) < 0.50, "%s × %s 역할 우위·약점 유지" % [crown_id, rival_id])


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[CrownContractMonstersPhase28] FAIL: %s" % label)
