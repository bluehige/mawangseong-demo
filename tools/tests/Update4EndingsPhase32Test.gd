extends Node

const CouncilEndingScript = preload("res://scripts/systems/endings/CouncilEndingService.gd")
const EndingEvaluatorScript = preload("res://scripts/systems/endings/EndingConditionEvaluator.gd")
const CampaignModeScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_and_assets()
	_test_two_fixture_paths()
	_test_boundaries_and_priority()
	_test_horizontal_rewards()
	_test_save_round_trip()
	if failed:
		print("UPDATE4_ENDINGS_PHASE32_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE4_ENDINGS_PHASE32_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_and_assets() -> void:
	var endings: Dictionary = DataRegistry.update4_council_endings
	_expect(endings.size() == 3, "Phase 32 E17~E19 세 종 로드")
	_expect(DataRegistry.update4_run_metric_definitions.size() == 17, "Phase 32 전용 지표 17종 로드")
	_expect(DataRegistry.ending_rules.size() >= 20, "공용 엔딩 목록 E00~E19 병합")
	var errors := EndingEvaluatorScript.validate_rules(DataRegistry.ending_rules, DataRegistry.run_metric_definitions)
	_expect(errors.is_empty(), "E00~E19 조건·지표 계약 검증: %s" % [errors])
	var codes := {}
	for ending_id in endings.keys():
		var ending: Dictionary = endings[ending_id]
		codes[str(ending.get("catalog_code", ""))] = true
		var path := str(ending.get("illustration", ""))
		var texture = ResourceLoader.load(path)
		var image: Image = texture.get_image() if texture is Texture2D else null
		_expect(image != null and image.get_size() == Vector2i(1920, 1080), "%s 1920×1080 엔딩 일러스트" % ending_id)
		var serialized := JSON.stringify(ending)
		_expect(not serialized.contains("stat_reward") and not serialized.contains("combat_bonus") and not serialized.contains("attribute_bonus"), "%s 수평 보상 전용" % ending_id)
	_expect(codes.size() == 3 and codes.has("E17") and codes.has("E18") and codes.has("E19"), "E17~E19 도감 코드 고유")
	var source_text := FileAccess.get_file_as_string("res://assets/source/imagegen/update4_endings_phase32/SOURCE.md")
	_expect(source_text.contains("Generation model: GPT internal image generation") and source_text.contains("Generated date: 2026-07-14") and source_text.contains("Target version: v0.4"), "GPT 내부 생성 SOURCE 고정 필드")
	_expect(source_text.count("Source image path:") == 3 and source_text.count("Runtime image path:") == 3, "원본 3개와 런타임 3개 일대일 기록")


func _test_two_fixture_paths() -> void:
	for ending_id in ["ending_council_seat", "ending_two_floors_one_throne", "ending_minion_wears_the_crown"]:
		var direct := _fixture(ending_id, false)
		var stored := _fixture(ending_id, true)
		_expect(_resolved(direct.active_run, direct.profile, direct.context) == ending_id, "%s 직접 DAY30 문맥 경로" % ending_id)
		_expect(_resolved(stored.active_run, stored.profile, stored.context) == ending_id, "%s 저장 지표 복원 경로" % ending_id)


func _test_boundaries_and_priority() -> void:
	var e17 := _fixture("ending_council_seat", false)
	e17.active_run.council_season.council_votes = 69
	_expect(_resolved(e17.active_run, e17.profile, e17.context) == CouncilEndingScript.LOCAL_FALLBACK_ID, "E17 의결표 1 부족 시 fallback")
	var e18 := _fixture("ending_two_floors_one_throne", false)
	e18.context.upper_floor_integrity = 79
	_expect(_resolved(e18.active_run, e18.profile, e18.context) == CouncilEndingScript.LOCAL_FALLBACK_ID, "E18 상층 무결성 1 부족 시 fallback")
	var e19 := _fixture("ending_minion_wears_the_crown", false)
	e19.context.crown_monster_bond = 99
	_expect(_resolved(e19.active_run, e19.profile, e19.context) == CouncilEndingScript.LOCAL_FALLBACK_ID, "E19 왕관 몬스터 유대 1 부족 시 fallback")
	var low_ratio := _fixture("ending_minion_wears_the_crown", false)
	low_ratio.context.day30_crown_contribution_ratio = 0.19
	_expect(_resolved(low_ratio.active_run, low_ratio.profile, low_ratio.context) == CouncilEndingScript.LOCAL_FALLBACK_ID, "E19 기여도 20% 미만 차단")
	var high_ratio := _fixture("ending_minion_wears_the_crown", false)
	high_ratio.context.day30_crown_contribution_ratio = 0.46
	_expect(_resolved(high_ratio.active_run, high_ratio.profile, high_ratio.context) == CouncilEndingScript.LOCAL_FALLBACK_ID, "E19 기여도 45% 초과 차단")
	var collision := _fixture("ending_minion_wears_the_crown", false)
	_apply_e17_state(collision.active_run, collision.context)
	_apply_e18_state(collision.active_run, collision.context)
	_expect(_resolved(collision.active_run, collision.profile, collision.context) == "ending_minion_wears_the_crown", "E19가 E18·E17 동시 충족보다 우선")
	collision.context.crown_monster_bond = 99
	_expect(_resolved(collision.active_run, collision.profile, collision.context) == "ending_two_floors_one_throne", "E19 탈락 시 E18이 E17보다 우선")


func _test_horizontal_rewards() -> void:
	var e17 := _fixture("ending_council_seat", false)
	var profile := CouncilEndingScript.apply_rewards(e17.profile, e17.active_run, "ending_council_seat", DataRegistry.update4_council_endings)
	profile = CouncilEndingScript.apply_rewards(profile, e17.active_run, "ending_council_seat", DataRegistry.update4_council_endings)
	_expect(bool(profile.get("campaign_modes", {}).get("agenda_extra_preview_unlocked", false)), "E17 다음 회차 안건 후보 추가 공개")
	_expect(profile.get("cosmetic_ids", []).count("council_nameplate") == 1 and profile.get("unlocked_reward_ids", []).size() == 2, "E17 외형 보상 재적용 멱등")
	var e18 := _fixture("ending_two_floors_one_throne", false)
	var floor_profile := CouncilEndingScript.apply_rewards({}, e18.active_run, "ending_two_floors_one_throne", DataRegistry.update4_council_endings)
	_expect(bool(floor_profile.get("chronicle", {}).get("floor_detail_unlocked", false)) and floor_profile.get("cosmetic_ids", []).has("upper_floor_epilogue_layout"), "E18 층별 연대기·외형 해금")
	var e19 := _fixture("ending_minion_wears_the_crown", false)
	var crown_profile := CouncilEndingScript.apply_rewards({}, e19.active_run, "ending_minion_wears_the_crown", DataRegistry.update4_council_endings)
	_expect(bool(crown_profile.get("crown_evolution", {}).get("representative_portrait_unlocked", false)), "E19 왕관 몬스터 대표 초상 해금")
	_expect(crown_profile.get("crown_evolution", {}).get("epilogue_form_ids", []).has("slime_rescue_alchemy_gel"), "E19 실제 왕관 형태별 후일담 기록")
	_expect(crown_profile.get("ending_catalog_codes", {}).get("ending_minion_wears_the_crown", "") == "E19", "E19 도감 코드 프로필 기록")


func _test_save_round_trip() -> void:
	var fixture := _fixture("ending_minion_wears_the_crown", true)
	var before := _resolved(fixture.active_run, fixture.profile, fixture.context)
	var encoded := JSON.stringify({"active_run": fixture.active_run, "profile": fixture.profile, "context": fixture.context})
	var restored: Dictionary = JSON.parse_string(encoded)
	var after := _resolved(restored.active_run, restored.profile, restored.context)
	_expect(before == "ending_minion_wears_the_crown" and after == before, "저장 문자열 복원 전후 E19 판정 동일")


func _fixture(ending_id: String, stored_path: bool) -> Dictionary:
	var active_run := CampaignModeScript.default_active_run()
	active_run["campaign_mode_id"] = CampaignModeScript.COUNCIL_MODE_ID
	var profile := CampaignModeScript.default_profile()
	var context := {}
	match ending_id:
		"ending_council_seat":
			_apply_e17_state(active_run, context)
		"ending_two_floors_one_throne":
			_apply_e18_state(active_run, context)
		"ending_minion_wears_the_crown":
			_apply_e19_state(active_run, context)
	if stored_path:
		active_run["run_metrics_update4"] = {"ending": context.duplicate(true)}
		context = {}
	return {"active_run": active_run, "profile": profile, "context": context}


func _apply_e17_state(active_run: Dictionary, context: Dictionary) -> void:
	var council: Dictionary = active_run.council_season
	council["council_votes"] = 70
	council["council_seals"] = 3
	council["rival_relations"] = {"rival_brassa": -40, "rival_vesper": 5, "rival_mirella": 40}
	council["agenda_promise_violations"] = 1
	active_run["council_season"] = council
	context["final_battle_won"] = true
	context["outpost_day20_survived"] = true


func _apply_e18_state(active_run: Dictionary, context: Dictionary) -> void:
	active_run.council_season.council_votes = 0
	active_run.upper_floor.seal_theft_count = 0
	context.merge({
		"final_battle_won": true,
		"upper_floor_integrity": 80,
		"crown_room_disable_count_since_day16": 0,
		"day30_upper_floor_contribution_ratio": 0.25,
		"day30_lower_survivor_count": 1,
		"day30_upper_survivor_count": 1
	}, true)


func _apply_e19_state(active_run: Dictionary, context: Dictionary) -> void:
	active_run.council_season.council_votes = 0
	active_run.council_season.day29_decision_id = "delegate_the_crown"
	active_run.crown.crown_form_id = "slime_rescue_alchemy_gel"
	context.merge({
		"final_battle_won": true,
		"crown_monster_bond": 100,
		"day30_crown_monster_survived": true,
		"day30_crown_contribution_ratio": 0.20,
		"day30_other_contributors_eight_percent": 3
	}, true)


func _resolved(active_run: Dictionary, profile: Dictionary, context: Dictionary) -> String:
	var result := CouncilEndingScript.resolve(active_run, profile, context, DataRegistry.update4_council_endings)
	_expect(bool(result.get("ok", false)), "엔딩 판정 오류 없음: %s" % result.get("error", ""))
	return str(result.get("ending_id", ""))


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[Update4EndingsPhase32] FAIL: %s" % label)
