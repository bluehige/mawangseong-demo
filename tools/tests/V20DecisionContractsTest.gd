extends Node

const Validator = preload("res://scripts/v20/contracts/V20ContractValidator.gd")
const Evidence = preload("res://scripts/v20/contracts/V20DecisionEvidence.gd")
const VALID_FIXTURE_PATH := "res://tools/fixtures/v20/valid_decision_contracts.json"
const INVALID_FIXTURE_PATH := "res://tools/fixtures/v20/invalid_decision_contracts.json"
const COMMIT_SHA := "0123456789abcdef0123456789abcdef01234567"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_registry_contract()
	_test_valid_fixture()
	_test_invalid_fixtures()
	_test_deterministic_evidence()
	if failed:
		print("V20_DECISION_CONTRACTS_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V20_DECISION_CONTRACTS_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_registry_contract() -> void:
	var contract := DataRegistry.v20_decision_contracts
	_expect(int(contract.get("schema_version", 0)) == 1, "v20 계약 namespace 분리 로드")
	_expect(contract.get("weighted_path_terms", []) == Validator.PATH_WEIGHT_TERMS, "weighted path 6개 비용 항 고정")
	_expect(str(contract.get("decision_evidence", {}).get("evidence_kind", "")) == Evidence.EVIDENCE_KIND, "고정 seed evidence 종류 고정")
	_expect(str(contract.get("interpretation_limit", "")).contains("재미"), "자동 결과의 재미 판정 금지 명시")
	var path_validation := Validator.validate_catalog("path", DataRegistry.v20_dungeon_layouts)
	_expect(bool(path_validation.get("ok", false)), "실제 DAY 1~5 고정 침입로 계약 승인: %s" % [path_validation.get("errors", [])])
	var invalid_fixed_path: Dictionary = DataRegistry.v20_dungeon_layouts.duplicate(true)
	invalid_fixed_path["v20_day_01_05_board"]["fixed_route"]["edges"].pop_back()
	_expect(not bool(Validator.validate_catalog("path", invalid_fixed_path).get("ok", true)), "노드 사이 edge가 빠진 고정 침입로 계약 거부")


func _test_valid_fixture() -> void:
	var fixture := _load_json(VALID_FIXTURE_PATH)
	var result := Validator.validate_bundle(fixture)
	_expect(bool(result.get("ok", false)), "유효 Encounter·Facility·Command·path fixture 승인: %s" % [result.get("errors", [])])
	for kind in Validator.CATALOG_KINDS:
		_expect(bool(Validator.validate_catalog(kind, fixture.get(kind)).get("ok", false)), "%s 단독 catalog 승인" % kind)
	var empty_combat_effect: Dictionary = fixture.get("facility", {}).duplicate(true)
	empty_combat_effect["v20_fixture_barricade"]["combat_effect"] = {}
	var invalid_combat_result := Validator.validate_catalog("facility", empty_combat_effect)
	_expect(not bool(invalid_combat_result.get("ok", true)) and str(invalid_combat_result.get("errors", [])).contains("combat_effect must not be empty"), "빈 시설 전투 효과 계약 거부")


func _test_invalid_fixtures() -> void:
	var fixture := _load_json(INVALID_FIXTURE_PATH)
	var cases = fixture.get("cases", [])
	_expect(cases.size() == 4, "무효 fixture 4종 로드")
	for case_value in cases:
		var case: Dictionary = case_value
		var kind := str(case.get("kind", ""))
		var result := Validator.validate_catalog(kind, case.get("catalog"))
		_expect(not bool(result.get("ok", true)) and not result.get("errors", []).is_empty(), "%s 무효 fixture 거부" % kind)
	_expect(not bool(Validator.validate_bundle({}).get("ok", true)), "누락 bundle 거부")


func _test_deterministic_evidence() -> void:
	var seed_value := 20260721
	var configuration := {"board_id": "v20_fixture_board", "day": 3, "doctrine": "hold_line"}
	var decisions := [
		{"kind": "facility", "id": "v20_fixture_barricade", "slot_id": "door_north"},
		{"kind": "command", "id": "v20_fixture_focus", "target_id": "engineer_01"}
	]
	var outcome := {"result": "win", "first_engagement_node": "gate_outpost", "route_signature": ["gate_outpost", "spike_corridor", "central_battle_room", "throne_anteroom", "throne"]}
	var metrics := {"throne_damage": 4.0, "facility_disabled_seconds": 0.0}
	var first: Dictionary = Evidence.build(seed_value, "fixture-run", COMMIT_SHA, configuration, decisions, outcome, metrics)
	var second: Dictionary = Evidence.build(seed_value, "fixture-run", COMMIT_SHA, configuration, decisions, outcome, metrics)
	_expect(first == second, "같은 seed·입력의 evidence byte-equivalent 재현")
	_expect(bool(Evidence.validate(first).get("ok", false)), "고정 seed evidence 형식 승인")
	_expect(Evidence.stable_index(seed_value, "engineer_route", 97) == Evidence.stable_index(seed_value, "engineer_route", 97), "같은 seed route 선택 재현")
	_expect(Evidence.stable_index(seed_value, "engineer_route", 97) != Evidence.stable_index(seed_value + 1, "engineer_route", 97), "다른 seed route 신호 분리")
	var tampered: Dictionary = first.duplicate(true)
	tampered["metrics"]["throne_damage"] = 99.0
	_expect(not bool(Evidence.validate(tampered).get("ok", true)), "결과 변조 fingerprint 거부")
	var wrong_sha: Dictionary = first.duplicate(true)
	wrong_sha["commit_sha"] = "not-a-sha"
	wrong_sha["fingerprint"] = Evidence.fingerprint(wrong_sha)
	_expect(not bool(Evidence.validate(wrong_sha).get("ok", true)), "잘못된 commit SHA 거부")


func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	return {}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[V20DecisionContracts] FAIL: %s" % message)
