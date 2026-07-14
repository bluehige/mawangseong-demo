extends Node

const CrownScript = preload("res://scripts/systems/crown/CrownEvolutionService.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_candidates_and_save()
	_test_gob_mark_and_chain()
	_test_pynn_three_embers()
	_test_representative_matrix()
	if failed:
		print("CROWN_GOB_PYNN_PHASE27_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("CROWN_GOB_PYNN_PHASE27_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _active() -> Dictionary:
	return {"campaign_mode_id": "council_season", "council_season": {"council_seals": 3, "crown_form_id": "", "crown_declined": false}}


func _instance(species_id: String, evolution_id: String) -> Dictionary:
	return {"instance_id": "MON_%s" % species_id.to_upper(), "species_id": species_id, "bond": 82, "level": 7, "growth_stage": 1, "specialization_id": "%s_tactic" % species_id, "evolution_id": evolution_id}


func _test_data_candidates_and_save() -> void:
	var catalog: Dictionary = DataRegistry.update4_catalogs.crown_evolutions
	_expect(catalog.size() == 3 and catalog.has("crown_gob_midnight_marshal") and catalog.has("crown_pynn_castle_flame_sage"), "Phase 27 왕관 3종 누적")
	var gob := _instance("goblin", "goblin_ambush_captain")
	var pynn := _instance("imp", "imp_flame_adept")
	_expect(bool(CrownScript.candidate_check(gob, catalog.crown_gob_midnight_marshal, _active().council_season).eligible), "곱 후보 조건")
	_expect(bool(CrownScript.candidate_check(pynn, catalog.crown_pynn_castle_flame_sage, _active().council_season).eligible), "핀 후보 조건")
	_expect(catalog.crown_gob_midnight_marshal.branch_inheritance.size() == 2 and catalog.crown_pynn_castle_flame_sage.branch_inheritance.size() == 2, "곱·핀 1차 진화 분기 2종씩 계승")
	var confirmed := CrownScript.confirm(_active(), gob, "crown_gob_midnight_marshal", catalog)
	var restored = JSON.parse_string(JSON.stringify(confirmed.active_run))
	_expect(bool(confirmed.ok) and str(restored.council_season.crown_source_evolution_id) == "goblin_ambush_captain", "곱 왕관 전투·UI·저장 상태")


func _test_gob_mark_and_chain() -> void:
	var enemies := [{"id": "spark", "danger": 2.0, "role": "support"}, {"id": "boss", "danger": 8.0, "role": "boss"}, {"id": "courier", "danger": 5.0, "role": "support"}]
	var mark := CrownScript.gob_royal_mark(enemies, true)
	_expect(bool(mark.ok) and str(mark.target_id) == "boss", "왕명 표식 위험도 1위")
	var ambush := CrownScript.gob_chain_command("boss", enemies, "throne", "goblin_ambush_captain", true, DataRegistry.skills.royal_no_second_cut)
	_expect(ambush.target_ids == ["boss", "spark"] and str(ambush.return_room_id) == "throne", "표식·인접 보조 적 연쇄 후 원래 방 복귀")
	_expect(str(ambush.inheritance) == "crown_trap_opening_bonus" and float(ambush.trap_damage_multiplier) == 1.20, "매복대장 함정 증폭 계승")
	var vault := CrownScript.gob_chain_command("boss", enemies, "vault", "goblin_vault_keeper", true, DataRegistry.skills.royal_no_second_cut)
	_expect(str(vault.inheritance) == "crown_theft_interrupt_bonus" and bool(vault.interrupt_theft), "금고지기 절도 중단 계승")
	_expect(is_equal_approx(float(vault.post_def_multiplier), 0.85) and float(vault.post_def_duration) == 4.0, "왕관 곱 스킬 후 방어 -15% 4초 대가")
	_expect(not bool(CrownScript.gob_royal_mark(enemies, false).ok), "왕관실 무력화 시 곱 왕관 기능 정지")


func _test_pynn_three_embers() -> void:
	var skill: Dictionary = DataRegistry.skills.tricolor_demonfire
	var repeated := CrownScript.pynn_ember_cost(["single_flame"], "single_flame", skill)
	_expect(int(repeated.mana_cost) == 29 and str(repeated.reason) == "repeat_cost", "같은 불씨 반복 마나 +20%")
	var cycled := CrownScript.pynn_ember_cost(["single_flame", "area_flame", "ember_curse"], "single_flame", skill)
	_expect(int(cycled.mana_cost) == 17 and str(cycled.reason) == "three_embers_discount", "세 가지 불씨 순환 다음 마나 -30%")
	var adept := CrownScript.pynn_tricolor_fire("area_flame", "imp_flame_adept", true)
	_expect(str(adept.inheritance) == "crown_direct_area_damage_bonus" and float(adept.area_damage_multiplier) > 1.35, "화염 숙련자 단일·광역 계승")
	var shaman := CrownScript.pynn_tricolor_fire("ember_curse", "imp_ember_shaman", true)
	_expect(str(shaman.inheritance) == "crown_debuff_duration_bonus" and float(shaman.debuff_duration_multiplier) > 1.30, "잿불 주술사 약화 지속 계승")
	_expect(not bool(CrownScript.pynn_tricolor_fire("single_flame", "imp_flame_adept", false).ok), "왕관실 무력화 시 핀 왕관 기능 정지")


func _test_representative_matrix() -> void:
	for crown_id in ["crown_gob_midnight_marshal", "crown_pynn_castle_flame_sage"]:
		for rival_id in DataRegistry.update4_rival_lords.keys():
			var trial := CrownScript.representative_matrix(crown_id, str(rival_id))
			_expect(bool(trial.viable) and not bool(trial.hard_countered) and float(trial.contribution_ratio) < 0.50, "%s × %s 기여 상한 매트릭스" % [crown_id, rival_id])


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[CrownGobPynnPhase27] FAIL: %s" % label)
