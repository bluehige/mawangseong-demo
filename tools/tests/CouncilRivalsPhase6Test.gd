extends Node

const VoteLedgerScript = preload("res://scripts/systems/council/CouncilVoteLedger.gd")
const RivalServiceScript = preload("res://scripts/systems/council/RivalLordService.gd")
const ModeServiceScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_contract()
	_test_relation_contract()
	_test_vote_contract()
	_test_representative_contract()
	if failed:
		print("COUNCIL_RIVALS_PHASE6_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("COUNCIL_RIVALS_PHASE6_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_data_contract() -> void:
	_expect(DataRegistry.update4_council_agendas.size() == 12, "의회 안건 12종 로드")
	_expect(DataRegistry.update4_rival_lords.size() == 3, "경쟁 마왕 3명 로드")
	_expect(DataRegistry.update4_characters.size() == 3, "경쟁 마왕 캐릭터 3명 분리 로드")
	for day in VoteLedgerScript.VOTE_DAYS:
		_expect(VoteLedgerScript.agendas_for_day(DataRegistry.update4_council_agendas, day).size() == 4, "DAY %d 안건 후보 4종" % day)


func _test_relation_contract() -> void:
	var active := _active()
	var raised := RivalServiceScript.change_relation(active, "rival_brassa", 500, DataRegistry.update4_rival_lords)
	active = raised.get("active_run", {})
	_expect(bool(raised.get("ok", false)) and RivalServiceScript.relation(active, "rival_brassa") == 100, "관계 상한 +100 고정")
	var lowered := RivalServiceScript.set_relation(active, "rival_brassa", -200, DataRegistry.update4_rival_lords)
	active = lowered.get("active_run", {})
	_expect(RivalServiceScript.relation(active, "rival_brassa") == -100, "관계 하한 -100 고정")
	_expect(RivalServiceScript.validate_relations(active, DataRegistry.update4_rival_lords) == "", "관계 원장 범위 검증")
	_expect(RivalServiceScript.relation_stage(-61) == "hostile_challenger" and RivalServiceScript.relation_stage(-60) == "challenger", "적대·도전자 관계 경계")
	_expect(RivalServiceScript.relation_stage(-29) == "neutral_rival" and RivalServiceScript.relation_stage(30) == "respectful" and RivalServiceScript.relation_stage(60) == "council_ally", "중립·존중·의회 동맹 관계 경계")


func _test_vote_contract() -> void:
	var active := _active()
	var first := VoteLedgerScript.forecast(active, "agenda_safety_code", DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords, VoteLedgerScript.CHOICE_AMEND)
	var second := VoteLedgerScript.forecast(active, "agenda_safety_code", DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords, VoteLedgerScript.CHOICE_AMEND)
	_expect(first == second, "예상 표 동일 입력 재현")
	_expect(first.get("positions", {}).get("rival_brassa") == "approve" and first.get("positions", {}).get("rival_vesper") == "reject" and first.get("positions", {}).get("rival_mirella") == "amend", "안건 선호 기반 예상 표 공개")
	_expect(bool(first.get("passed", false)), "플레이어 수정안 포함 3표로 가결 예고")
	var hostile: Dictionary = RivalServiceScript.set_relation(active, "rival_brassa", -40, DataRegistry.update4_rival_lords).get("active_run", {})
	var hostile_vote := VoteLedgerScript.forecast(hostile, "agenda_safety_code", DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords, VoteLedgerScript.CHOICE_APPROVE)
	_expect(hostile_vote.get("positions", {}).get("rival_brassa") == "reject", "관계 -40 이하 반대 표 예고")
	var ally: Dictionary = RivalServiceScript.set_relation(active, "rival_vesper", 60, DataRegistry.update4_rival_lords).get("active_run", {})
	var ally_vote := VoteLedgerScript.forecast(ally, "agenda_safety_code", DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords, VoteLedgerScript.CHOICE_AMEND)
	_expect(ally_vote.get("positions", {}).get("rival_vesper") == "amend", "관계 60 이상 수정안 지지 예고")
	var recorded := VoteLedgerScript.record_empty_vote(active, "agenda_safety_code", "amend", 13, DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords)
	active = recorded.get("active_run", {})
	_expect(bool(recorded.get("ok", false)) and active.get("council_season", {}).get("agenda_history", []) == ["agenda_safety_code"], "DAY 13 빈 표결 이력 기록")
	_expect(active.get("council_season", {}).get("vote_records", []).size() == 1 and not bool(recorded.get("record", {}).get("effect_applied", true)), "빈 표결은 효과 미적용 원장으로 보존")
	_expect(not bool(VoteLedgerScript.record_empty_vote(active, "agenda_safety_code", "approve", 13, DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords).get("ok", true)), "동일 안건 재표결 거부")
	_expect(VoteLedgerScript.validate_ledger(active, DataRegistry.update4_council_agendas) == "", "표결 원장과 안건 이력 일치")


func _test_representative_contract() -> void:
	var active := _active()
	active = RivalServiceScript.set_relation(active, "rival_brassa", -35, DataRegistry.update4_rival_lords).get("active_run", {})
	active = RivalServiceScript.set_relation(active, "rival_mirella", -70, DataRegistry.update4_rival_lords).get("active_run", {})
	var hostile_preview := RivalServiceScript.representative_preview(active, DataRegistry.update4_rival_lords, 41)
	_expect(hostile_preview.get("rival_id") == "rival_mirella" and hostile_preview.get("reason") == "lowest_relation", "-30 이하 중 최저 관계 대표 우선")

	active = _active()
	active["council_season"]["rival_states"]["rival_vesper"]["competitive_score"] = 80
	var score_preview := RivalServiceScript.representative_preview(active, DataRegistry.update4_rival_lords, 41)
	_expect(score_preview.get("rival_id") == "rival_vesper" and score_preview.get("reason") == "competitive_score", "모두 -29 이상이면 최고 경쟁 점수 대표")

	active = _active()
	var tie_a := RivalServiceScript.representative_preview(active, DataRegistry.update4_rival_lords, 0)
	var tie_b := RivalServiceScript.representative_preview(active, DataRegistry.update4_rival_lords, 1)
	_expect(tie_a == RivalServiceScript.representative_preview(active, DataRegistry.update4_rival_lords, 0) and tie_a.get("rival_id") != tie_b.get("rival_id"), "동률 seed 결정 재현·분기")
	active = RivalServiceScript.set_relation(active, "rival_brassa", 70, DataRegistry.update4_rival_lords).get("active_run", {})
	active = RivalServiceScript.set_relation(active, "rival_vesper", 80, DataRegistry.update4_rival_lords).get("active_run", {})
	var locked := RivalServiceScript.lock_representative(active, DataRegistry.update4_rival_lords, 1)
	var locked_active: Dictionary = locked.get("active_run", {})
	var locked_id := str(locked.get("preview", {}).get("rival_id", ""))
	var support_id := str(locked.get("preview", {}).get("support_rival_id", ""))
	_expect(bool(locked.get("ok", false)) and str(locked_active.get("council_season", {}).get("final_representative_id", "")) == locked_id, "DAY 24용 대표 잠금 상태 생성")
	_expect(support_id == "" or support_id != locked_id, "관계 60 이상 지원 토큰 후보 최대 1명")
	_expect(RivalServiceScript.representative_preview(locked_active, DataRegistry.update4_rival_lords, 999).get("rival_id") == locked_id, "공지 후 대표 후보 불변")


func _active() -> Dictionary:
	var profile := ModeServiceScript.normalize_profile(ModeServiceScript.default_profile(), {"fronts": {"clear_counts": {"front_hero_oath": 1}}})
	return ModeServiceScript.select_mode(profile, ModeServiceScript.new_cycle_active_run(), ModeServiceScript.COUNCIL_MODE_ID, DataRegistry.update4_campaign_modes).get("active_run", {})


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[CouncilRivalsPhase6] FAIL: %s" % message)
