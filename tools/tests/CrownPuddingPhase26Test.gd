extends Node

const CrownScript = preload("res://scripts/systems/crown/CrownEvolutionService.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_candidate_and_growth_contract()
	_test_confirm_save_restore()
	_test_decline_options_and_no_crown_run()
	_test_pudding_combat_and_ab()
	if failed:
		print("CROWN_PUDDING_PHASE26_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("CROWN_PUDDING_PHASE26_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _instance() -> Dictionary:
	return {"instance_id": "MON_SLIME", "species_id": "slime", "bond": 84, "level": 6, "growth_stage": 1, "specialization_id": "slime_guard", "evolution_id": "slime_gate_bulwark", "memory": {"wins": 12}}


func _active() -> Dictionary:
	return {"campaign_mode_id": "council_season", "council_season": {"council_seals": 3, "alternative_seal_resource": 0, "crown_form_id": "", "crown_declined": false}}


func _test_candidate_and_growth_contract() -> void:
	_expect(DataRegistry.update4_catalogs.crown_evolutions.has("crown_pudding_royal_bastion"), "Phase 26 푸딩 왕관 계약 유지")
	var crown: Dictionary = DataRegistry.update4_catalogs.crown_evolutions.crown_pudding_royal_bastion
	var check := CrownScript.candidate_check(_instance(), crown, _active().council_season)
	_expect(bool(check.eligible) and str(check.payment) == "council_seals", "유대80·레벨6·특화·1차진화·인장2 후보 조건")
	var invalid := _instance()
	invalid.bond = 79
	invalid.evolution_id = ""
	var invalid_check := CrownScript.candidate_check(invalid, crown, _active().council_season)
	_expect(not bool(invalid_check.eligible) and invalid_check.reasons.has("bond") and invalid_check.reasons.has("stage_one_evolution"), "미충족 후보 사유 표시")
	var layers := CrownScript.growth_layers(_instance(), crown)
	_expect(layers.map(func(layer): return str(layer.layer)) == ["species_base", "level", "tactical_specialization", "stage_one_evolution", "memory", "crown_evolution"], "성장 계층 적용 순서")
	_expect(str(layers[2].id) == "slime_guard" and str(layers[3].id) == "slime_gate_bulwark", "특화·1차 진화 보존")
	_expect(crown.branch_inheritance.keys().size() == 2 and crown.branch_inheritance.has("slime_rescue_alchemy_gel"), "푸딩 분기 계승 2종·정식 진화 ID")


func _test_confirm_save_restore() -> void:
	var confirmed := CrownScript.confirm(_active(), _instance(), "crown_pudding_royal_bastion", DataRegistry.update4_catalogs.crown_evolutions)
	_expect(bool(confirmed.ok) and bool(confirmed.autosave_required) and int(confirmed.active_run.council_season.council_seals) == 1, "왕관 확정 전 자동저장 요청·인장2 비용")
	_expect(str(confirmed.active_run.council_season.crown_source_specialization_id) == "slime_guard" and str(confirmed.active_run.council_season.crown_source_evolution_id) == "slime_gate_bulwark", "왕관 원본 성장 분기 저장")
	var restored = JSON.parse_string(JSON.stringify(confirmed.active_run))
	_expect(restored is Dictionary and str(restored.council_season.crown_form_id) == "crown_pudding_royal_bastion" and str(restored.council_season.crown_monster_instance_id) == "MON_SLIME", "왕관 저장·복원")
	_expect(not bool(CrownScript.confirm(confirmed.active_run, _instance(), "crown_pudding_royal_bastion", DataRegistry.update4_catalogs.crown_evolutions).ok), "회차당 왕관 진화 1마리")


func _test_decline_options_and_no_crown_run() -> void:
	for option_id in CrownScript.DECLINE_OPTIONS:
		var declined := CrownScript.decline(_active(), option_id)
		_expect(bool(declined.ok) and bool(declined.autosave_required) and str(declined.active_run.council_season.crown_form_id) == "" and str(declined.active_run.council_season.crown_decline_reward) == option_id, "%s 인장 거절 보상" % option_id)
	var no_crown_trial := CrownScript.ab_trial(false)
	_expect(bool(no_crown_trial.day30_completable) and float(no_crown_trial.win_rate) >= 0.55, "왕관 없는 DAY 30 빌드 완주")


func _test_pudding_combat_and_ab() -> void:
	var passive := CrownScript.pudding_room_embrace([], {"id": "gob", "hp": 39, "max_hp": 100}, true)
	_expect(bool(passive.triggered) and int(passive.shield) == 15, "성벽의 품 첫 40% 이하 아군 최대 HP15% 보호막")
	_expect(not bool(CrownScript.pudding_room_embrace(passive.triggered_ids, {"id": "gob", "hp": 20, "max_hp": 100}, true).triggered), "성벽의 품 같은 아군 중복 금지")
	var anchor := CrownScript.royal_jelly_bastion([{"id": "gob", "hp": 80, "max_hp": 100}], "slime_gate_bulwark", true, DataRegistry.skills.royal_jelly_bastion)
	_expect(bool(anchor.ok) and float(anchor.duration) == 6.0 and is_equal_approx(float(anchor.damage_reduction), 0.30) and str(anchor.inheritance) == "crown_anchor_bonus", "성 전체를 품는 젤 6초·피해30%·방벽 계승")
	var rescue := CrownScript.royal_jelly_bastion([{"id": "gob", "hp": 80, "max_hp": 100}, {"id": "pynn", "hp": 20, "max_hp": 100}], "slime_rescue_alchemy_gel", true, DataRegistry.skills.royal_jelly_bastion)
	_expect(str(rescue.inheritance) == "crown_rescue_bonus" and str(rescue.rescue_target_id) == "pynn", "구조 연금젤 최저 HP 아군 이동 계승")
	_expect(not bool(CrownScript.royal_jelly_bastion([], "slime_gate_bulwark", false, DataRegistry.skills.royal_jelly_bastion).ok), "왕관실 무력화 시 패시브·왕관 스킬 정지")
	var base := CrownScript.ab_trial(false)
	var crown := CrownScript.ab_trial(true)
	var contribution_gain := (float(crown.contribution_ratio) - float(base.contribution_ratio)) / float(base.contribution_ratio)
	_expect(contribution_gain >= 0.16 and contribution_gain <= 0.22 and float(crown.contribution_ratio) < 0.50, "왕관 기여 +16~22%·단일 기여 50% 미만")
	_expect(float(crown.win_rate) - float(base.win_rate) <= 0.10, "왕관 있음/없음 승률 차이 10%p 이하")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[CrownPuddingPhase26] FAIL: %s" % label)
