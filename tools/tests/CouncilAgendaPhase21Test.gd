extends Node

const LedgerScript = preload("res://scripts/systems/council/CouncilVoteLedger.gd")
const ForecastPanelScript = preload("res://scripts/ui/CouncilVoteForecastPanel.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_and_seed()
	_test_forecast_and_vote_days()
	_test_failure_and_promises()
	_test_modifier_cap_and_panel()
	if failed:
		print("COUNCIL_AGENDA_PHASE21_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("COUNCIL_AGENDA_PHASE21_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _base_run() -> Dictionary:
	return {"campaign_mode_id": "council_season", "council_season": {"agenda_history": [], "vote_records": [], "rival_relations": {"rival_brassa": 10, "rival_vesper": 10, "rival_mirella": 10}, "council_votes": 20, "independence": 15}}


func _test_catalog_and_seed() -> void:
	_expect(DataRegistry.update4_council_agendas.size() == 12, "의회 안건 12개")
	for day in [13, 22, 26]:
		_expect(LedgerScript.agendas_for_day(DataRegistry.update4_council_agendas, day).size() == 4, "DAY %d 안건 4개" % day)
		var first := LedgerScript.seeded_agendas_for_day(DataRegistry.update4_council_agendas, day, _base_run(), 421337, 3)
		var repeat := LedgerScript.seeded_agendas_for_day(DataRegistry.update4_council_agendas, day, _base_run(), 421337, 3)
		_expect(first == repeat and first.size() == 3, "DAY %d 동일 seed 후보 재현" % day)


func _test_forecast_and_vote_days() -> void:
	var run := _base_run()
	var forecast := LedgerScript.forecast(run, "agenda_open_gate", DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords, "amend")
	_expect(forecast.positions.size() == 4 and forecast.tally.values().reduce(func(a, b): return int(a) + int(b), 0) == 4, "플레이어·라이벌 3명 예상 표")
	var result := LedgerScript.record_empty_vote(run, "agenda_open_gate", "amend", 13, DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords)
	_expect(bool(result.ok) and int(result.record.day) == 13, "DAY 13 찬성·수정안·반대 원장")
	_expect(not bool(LedgerScript.record_empty_vote(run, "agenda_open_gate", "approve", 22, DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords).ok), "안건 DAY 불일치 거부")


func _test_failure_and_promises() -> void:
	var failed_run := LedgerScript.apply_vote_outcome(_base_run(), {"passed": false}, DataRegistry.update4_council_balance)
	_expect(int(failed_run.council_season.independence) == 20 and int(failed_run.council_season.vote_failures) == 1 and bool(failed_run.council_season.last_vote_resolved), "표결 실패도 독립성으로 전환·진행")
	var passed_run := LedgerScript.apply_vote_outcome(_base_run(), {"passed": true}, DataRegistry.update4_council_balance)
	_expect(int(passed_run.council_season.council_votes) == 25, "표결 통과 의회 표 반영")
	var promised := LedgerScript.record_promise(_base_run(), "agenda_safety_code", "keep_facilities_active")
	var violated := LedgerScript.resolve_promise(promised, "agenda_safety_code", false)
	_expect(str(violated.council_season.agenda_promises.agenda_safety_code.status) == "violated" and int(violated.council_season.agenda_promise_violations) == 1, "약속 위반 1회 기록")
	var duplicate := LedgerScript.resolve_promise(violated, "agenda_safety_code", false)
	_expect(int(duplicate.council_season.agenda_promise_violations) == 1, "같은 약속 위반 중복 집계 금지")


func _test_modifier_cap_and_panel() -> void:
	_expect(is_equal_approx(LedgerScript.compose_modifier([1.20, 1.20, 1.10], DataRegistry.update4_council_balance), 1.25), "modifier 곱 상한 1.25")
	_expect(is_equal_approx(LedgerScript.compose_modifier([0.80, 0.80, 0.90], DataRegistry.update4_council_balance), 0.75), "modifier 곱 하한 0.75")
	var forecast := LedgerScript.forecast(_base_run(), "agenda_open_gate", DataRegistry.update4_council_agendas, DataRegistry.update4_rival_lords, "reject")
	var panel = ForecastPanelScript.new()
	add_child(panel)
	panel.show_forecast(forecast, DataRegistry.update4_rival_lords)
	_expect(panel.votes_label.text.contains("마왕") and panel.votes_label.text.contains("브라사") and panel.result_label.text != "", "예상 표 UI 4표·결과 표시")
	panel.queue_free()


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[CouncilAgendaPhase21] FAIL: %s" % label)
