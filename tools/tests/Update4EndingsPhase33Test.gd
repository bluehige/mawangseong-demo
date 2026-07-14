extends Node

const CouncilEndingScript = preload("res://scripts/systems/endings/CouncilEndingService.gd")
const EndingEvaluatorScript = preload("res://scripts/systems/endings/EndingConditionEvaluator.gd")
const CampaignModeScript = preload("res://scripts/systems/campaign/CampaignModeService.gd")
const SaveMigratorScript = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd")

const REGIONS := [
	"region_ironbell_ravine",
	"region_moonbat_aerie",
	"region_mistcap_marsh",
	"region_bone_lantern_fields",
	"region_blackwater_exchange"
]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_and_assets()
	_test_two_fixture_paths()
	_test_reachability_and_priority()
	_test_profile_current_run_separation()
	_test_rewards_and_round_trip()
	if failed:
		print("UPDATE4_ENDINGS_PHASE33_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE4_ENDINGS_PHASE33_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_and_assets() -> void:
	var endings: Dictionary = DataRegistry.update4_council_endings
	_expect(endings.size() == 6, "Update 4 E17~E22 정확히 여섯 종")
	_expect(DataRegistry.update4_run_metric_definitions.size() == 33, "Update 4 엔딩 지표 33종")
	_expect(DataRegistry.ending_rules.size() >= 23, "공용 엔딩 목록 E00~E22 병합")
	var errors := EndingEvaluatorScript.validate_rules(DataRegistry.ending_rules, DataRegistry.run_metric_definitions)
	_expect(errors.is_empty(), "E00~E22 조건·지표 계약 검증: %s" % [errors])
	var codes := {}
	for ending_id in endings.keys():
		codes[str(endings[ending_id].get("catalog_code", ""))] = true
		var serialized := JSON.stringify(endings[ending_id])
		_expect(not serialized.contains("stat_reward") and not serialized.contains("combat_bonus") and not serialized.contains("attribute_bonus"), "%s 수평 보상 전용" % ending_id)
	_expect(codes.size() == 6 and ["E17", "E18", "E19", "E20", "E21", "E22"].all(func(code): return codes.has(code)), "E17~E22 도감 코드 고유")
	for ending_id in ["ending_outpost_becomes_home", "ending_three_rivals_cosign", "ending_council_dissolved"]:
		var texture = ResourceLoader.load(str(endings[ending_id].illustration))
		var image: Image = texture.get_image() if texture is Texture2D else null
		_expect(image != null and image.get_size() == Vector2i(1920, 1080), "%s 1920×1080 엔딩 일러스트" % ending_id)
	var source_text := FileAccess.get_file_as_string("res://assets/source/imagegen/update4_endings_phase33/SOURCE.md")
	_expect(source_text.contains("Generation model: GPT internal image generation") and source_text.contains("Generated date: 2026-07-14") and source_text.contains("Target version: v0.4"), "Phase 33 GPT 내부 생성 SOURCE 고정 필드")
	_expect(source_text.count("Source image path:") == 3 and source_text.count("Runtime image path:") == 3, "Phase 33 원본 3개와 런타임 3개 일대일 기록")


func _test_two_fixture_paths() -> void:
	for ending_id in ["ending_outpost_becomes_home", "ending_three_rivals_cosign", "ending_council_dissolved"]:
		var direct := _fixture(ending_id, false, 0)
		var stored := _fixture(ending_id, true, 1)
		_expect(_resolved(direct.active_run, direct.profile, direct.context) == ending_id, "%s 직접 문맥 fixture" % ending_id)
		_expect(_resolved(stored.active_run, stored.profile, stored.context) == ending_id, "%s 저장 복원 fixture" % ending_id)


func _test_reachability_and_priority() -> void:
	var e20 := _fixture("ending_outpost_becomes_home", false, 0)
	e20.context.outpost_assigned_average_bond = 74
	_expect(_resolved(e20.active_run, e20.profile, e20.context) == CouncilEndingScript.LOCAL_FALLBACK_ID, "E20 평균 유대 1 부족 시 fallback")
	var e21 := _fixture("ending_three_rivals_cosign", false, 0)
	e21.profile.regions.charters_completed.resize(2)
	_expect(_resolved(e21.active_run, e21.profile, e21.context) == CouncilEndingScript.LOCAL_FALLBACK_ID, "E21 관계만 충족하고 헌장 2개면 fallback")
	var e22_profile := _fixture("ending_council_dissolved", false, 0)
	e22_profile.profile.rivals.rival_mirella.day30_representative_defeats = 0
	_expect(_resolved(e22_profile.active_run, e22_profile.profile, e22_profile.context) == CouncilEndingScript.LOCAL_FALLBACK_ID, "E22 프로필 경쟁 대표 한 명 미격퇴 시 fallback")
	var e22_run := _fixture("ending_council_dissolved", false, 0)
	e22_run.active_run.council_season.independence = 84
	_expect(_resolved(e22_run.active_run, e22_run.profile, e22_run.context) == CouncilEndingScript.LOCAL_FALLBACK_ID, "E22 현재 회차 독립도 1 부족 시 fallback")
	var collision := _fixture("ending_three_rivals_cosign", false, 0)
	_apply_e20_state(collision.active_run, collision.profile, collision.context)
	collision.profile.regions.charters_completed = [REGIONS[0], REGIONS[1], REGIONS[2]]
	_expect(_resolved(collision.active_run, collision.profile, collision.context) == "ending_three_rivals_cosign", "E21이 동시 충족 E20보다 우선")
	var e20_e18 := _fixture("ending_outpost_becomes_home", false, 0)
	_apply_e18_state(e20_e18.active_run, e20_e18.context)
	_expect(_resolved(e20_e18.active_run, e20_e18.profile, e20_e18.context) == "ending_outpost_becomes_home", "E20이 동시 충족 E18보다 우선")


func _test_profile_current_run_separation() -> void:
	var profile := CampaignModeScript.default_profile()
	profile.update4_endings_seen = ["E17"]
	profile.regions.completed_ids = REGIONS.slice(0, 4)
	profile.rivals.rival_brassa.day30_representative_defeats = 1
	profile.rivals.rival_vesper.day30_representative_defeats = 1
	var active_run := CampaignModeScript.default_active_run()
	active_run.council_season.selected_regions = [REGIONS[4]]
	active_run.council_season.current_region_index = 0
	active_run.council_season.final_representative_id = "rival_mirella"
	active_run.council_season.council_votes = 35
	active_run.council_season.independence = 85
	active_run.council_season.day29_decision_id = "reject_council_authority"
	active_run.outpost.stats.day20_win = true
	active_run.crown.replacement_reward_id = "seal_replacement_support"
	var context := {"final_battle_won": true, "outpost_day20_survived": true, "completed_region_ids": [REGIONS[4]]}
	_expect(_resolved(active_run, profile, context) == CouncilEndingScript.LOCAL_FALLBACK_ID, "현재 승리 기록 전에는 E22 프로필 조건 미충족")
	var final := CouncilEndingScript.finalize_day30(profile, active_run, context, DataRegistry.update4_council_endings)
	_expect(bool(final.ok) and str(final.ending_id) == "ending_council_dissolved", "현재 세 번째 대표·다섯 번째 지역 기록 후 E22 달성")
	_expect(int(final.profile.rivals.rival_mirella.day30_representative_defeats) == 1 and final.profile.regions.completed_ids.size() == 5, "대표 격퇴와 지역 완료를 프로필에 분리 복원")
	var repeated := CouncilEndingScript.record_day30_outcome(final.profile, final.active_run, context)
	_expect(int(repeated.profile.campaign_modes.council_season_clears) == 1 and int(repeated.profile.rivals.rival_mirella.day30_representative_defeats) == 1, "DAY30 결과 재기록 멱등")


func _test_rewards_and_round_trip() -> void:
	var e20 := _fixture("ending_outpost_becomes_home", false, 0)
	var outpost_profile := CouncilEndingScript.apply_rewards(e20.profile, e20.active_run, "ending_outpost_becomes_home", DataRegistry.update4_council_endings)
	_expect(bool(outpost_profile.outpost.epilogue_management_card_unlocked) and bool(outpost_profile.outpost.decoration_codex_unlocked), "E20 전초기지 후일담 카드·장식 도감")
	var e21 := _fixture("ending_three_rivals_cosign", false, 0)
	var alliance_profile := CouncilEndingScript.apply_rewards(e21.profile, e21.active_run, "ending_three_rivals_cosign", DataRegistry.update4_council_endings)
	_expect(int(alliance_profile.campaign_modes.representative_candidates_pre_revealed) == 3 and alliance_profile.cosmetic_ids.has("three_rivals_joint_banner"), "E21 대표 후보 3명 사전 공개·공동 깃발")
	var e22 := _fixture("ending_council_dissolved", false, 0)
	var free_profile := CouncilEndingScript.apply_rewards(e22.profile, e22.active_run, "ending_council_dissolved", DataRegistry.update4_council_endings)
	_expect(bool(free_profile.campaign_modes.free_representative_rotation_unlocked) and bool(free_profile.campaign_modes.direct_representative_selection_unlocked), "E22 자유 대표 순환·직접 선택 해금")
	_expect(is_equal_approx(float(free_profile.campaign_modes.direct_representative_reward_multiplier), 1.0), "E22 대표 직접 선택 보상 증가 없음")
	_expect(free_profile.update4_endings_seen.has("E22") and not free_profile.update4_endings_seen.has("ending_council_dissolved"), "Update 4 엔딩은 저장 계약의 도감 코드로 기록")
	var encoded := JSON.stringify({"profile": free_profile, "active_run": e22.active_run, "context": e22.context})
	var restored: Dictionary = JSON.parse_string(encoded)
	_expect(_resolved(restored.active_run, restored.profile, restored.context) == "ending_council_dissolved", "저장 문자열 복원 전후 E22 판정 동일")
	_expect(SaveMigratorScript.UPDATE4_ENDING_IDS.has("E22"), "저장 v5 E22 도감 코드 허용")


func _fixture(ending_id: String, stored_path: bool, variant: int) -> Dictionary:
	var active_run := CampaignModeScript.default_active_run()
	active_run.campaign_mode_id = CampaignModeScript.COUNCIL_MODE_ID
	var profile := CampaignModeScript.default_profile()
	var context := {}
	match ending_id:
		"ending_outpost_becomes_home":
			_apply_e20_state(active_run, profile, context)
		"ending_three_rivals_cosign":
			_apply_e21_state(active_run, profile, context, variant)
		"ending_council_dissolved":
			_apply_e22_state(active_run, profile, context, variant)
	if stored_path:
		active_run.run_metrics_update4 = {"ending": context.duplicate(true), "outpost": {
			"day10_win": bool(active_run.outpost.stats.day10_win),
			"day20_win": bool(active_run.outpost.stats.day20_win),
			"outpost_level": int(active_run.outpost.level),
			"banner_hp_average_ratio": float(active_run.outpost.stats.average_ending_hp_ratio)
		}}
		context = {}
	return {"active_run": active_run, "profile": profile, "context": context}


func _apply_e20_state(active_run: Dictionary, profile: Dictionary, context: Dictionary) -> void:
	active_run.outpost.level = 2
	active_run.outpost.stats.day10_win = true
	active_run.outpost.stats.day20_win = true
	active_run.outpost.stats.average_ending_hp_ratio = 0.50
	active_run.council_season.day29_decision_id = "keep_outpost_after_council"
	profile.regions.charters_completed = [REGIONS[0], REGIONS[1]]
	context.outpost_assigned_average_bond = 75


func _apply_e21_state(active_run: Dictionary, profile: Dictionary, context: Dictionary, variant: int) -> void:
	active_run.council_season.rival_relations = {"rival_brassa": 55, "rival_vesper": 62, "rival_mirella": 70}
	active_run.council_season.council_votes = 60
	active_run.council_season.final_representative_id = "rival_brassa" if variant == 0 else "rival_vesper"
	active_run.council_season.rival_support_used = true
	profile.regions.charters_completed = [REGIONS[variant], REGIONS[(variant + 1) % 5], REGIONS[(variant + 2) % 5]]
	context.final_battle_won = true


func _apply_e22_state(active_run: Dictionary, profile: Dictionary, context: Dictionary, variant: int) -> void:
	for rival_id in ["rival_brassa", "rival_vesper", "rival_mirella"]:
		profile.rivals[rival_id].day30_representative_defeats = 1
	profile.update4_endings_seen = ["E17" if variant == 0 else "E21"]
	profile.regions.completed_ids = REGIONS.duplicate()
	active_run.council_season.council_votes = 35
	active_run.council_season.independence = 85
	active_run.council_season.day29_decision_id = "reject_council_authority"
	active_run.outpost.stats.day20_win = true
	if variant == 0:
		active_run.crown.crown_form_id = "slime_rescue_alchemy_gel"
	else:
		active_run.crown.replacement_reward_id = "seal_replacement_support"
	context.final_battle_won = true
	context.outpost_day20_survived = true


func _apply_e18_state(active_run: Dictionary, context: Dictionary) -> void:
	active_run.upper_floor.seal_theft_count = 0
	context.merge({"final_battle_won": true, "upper_floor_integrity": 80, "crown_room_disable_count_since_day16": 0, "day30_upper_floor_contribution_ratio": 0.25, "day30_lower_survivor_count": 1, "day30_upper_survivor_count": 1}, true)


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
		push_error("[Update4EndingsPhase33] FAIL: %s" % label)
