extends Node

const ContentScript = preload("res://scripts/systems/regions/RegionContentService.gd")
const ProgressPanelScript = preload("res://scripts/ui/RegionSettlementProgressPanel.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_counts_and_chapter_coverage()
	_test_charters()
	_test_wave_budgets()
	_test_selection_and_rewards()
	_test_settlement_progress()
	if failed:
		print("REGION_CONTENT_PHASE20_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("REGION_CONTENT_PHASE20_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_counts_and_chapter_coverage() -> void:
	_expect(DataRegistry.update4_region_events.size() == 15, "지역 사건 15개")
	_expect(DataRegistry.update4_council_wave_templates.size() == 15, "의회 웨이브 템플릿 15개")
	var charter_count := 0
	for region_id in DataRegistry.update4_regions:
		var region: Dictionary = DataRegistry.update4_regions[region_id]
		if not region.get("charter", {}).is_empty():
			charter_count += 1
		for chapter_slot in [1, 2, 3]:
			var event := ContentScript.event_for_chapter(region, DataRegistry.update4_region_events, chapter_slot)
			var wave := ContentScript.wave_for_chapter(region_id, chapter_slot, DataRegistry.update4_council_wave_templates)
			_expect(not event.is_empty() and int(event.get("chapter_positions", []).size()) == 3, "%s 챕터 %d 사건 유효" % [region_id, chapter_slot])
			_expect(not wave.is_empty(), "%s 챕터 %d 웨이브 유효" % [region_id, chapter_slot])
	_expect(charter_count == 5, "지역 헌장 5개")
	_expect(DataRegistry.update4_region_day_overlays.has("region_chapter_slot_1") and DataRegistry.update4_region_day_overlays.has("region_chapter_slot_3"), "지역 선택 순서 overlay 3단계")


func _test_charters() -> void:
	_expect(ContentScript.charter_completed(DataRegistry.update4_regions.region_ironbell_ravine, {"facility_disables": 2}), "철종 시설 무력화 2회 이하 헌장")
	_expect(ContentScript.charter_completed(DataRegistry.update4_regions.region_moonbat_aerie, {"seal_thefts": 0}), "월박쥐 절도 0회 헌장")
	_expect(ContentScript.charter_completed(DataRegistry.update4_regions.region_mistcap_marsh, {"down_count": 2}), "안개습원 전투 불능 2명 이하 헌장")
	_expect(ContentScript.charter_completed(DataRegistry.update4_regions.region_bone_lantern_fields, {"distinct_duo_links": 2}), "묘원 합동기 2개 헌장")
	_expect(ContentScript.charter_completed(DataRegistry.update4_regions.region_blackwater_exchange, {"treasure_loss": 12, "security_grade": "A"}), "검은물 보안 A 대체 헌장")
	_expect(not ContentScript.charter_completed(DataRegistry.update4_regions.region_blackwater_exchange, {"treasure_loss": 1, "security_grade": "B"}), "검은물 헌장 실패 판정")


func _test_wave_budgets() -> void:
	for template_id in DataRegistry.update4_council_wave_templates:
		var template: Dictionary = DataRegistry.update4_council_wave_templates[template_id]
		var recomputed := ContentScript.recompute_wave_threat(template, DataRegistry.enemies)
		var budget := float(template.get("threat_budget", 0.0))
		_expect(is_equal_approx(recomputed, float(template.get("actual_threat", -1.0))), "%s threat 재계산 일치" % template_id)
		_expect(absf(recomputed - budget) <= budget * 0.05 + 0.001, "%s threat 예산 ±5%%" % template_id)


func _test_selection_and_rewards() -> void:
	var simulation := ContentScript.simulate_region_selection(DataRegistry.update4_regions, 5000, 40420)
	for region_id in simulation.rates:
		var rate := float(simulation.rates[region_id])
		_expect(rate >= 0.17 and rate <= 0.23, "%s 선택률 20%% 근방" % region_id)
	var reward := ContentScript.reward_balance(DataRegistry.update4_regions)
	_expect(bool(reward.balanced) and float(reward.max_deviation_ratio) <= 0.10, "지역 보상 시뮬레이션 편차 10% 이하")


func _test_settlement_progress() -> void:
	var progress := ContentScript.settlement_progress(2, 1, 1)
	_expect(str(progress.label) == "지역 2/3 · 헌장 1/3 · 인장 1/3" and is_equal_approx(float(progress.ratio), 1.0 / 3.0), "결산 진행 표시 데이터")
	var panel = ProgressPanelScript.new()
	add_child(panel)
	panel.set_progress(progress)
	_expect(panel.progress_label.text == str(progress.label) and is_equal_approx(float(panel.progress_bar.value), 1.0 / 3.0), "결산 진행 패널 반영")
	panel.queue_free()


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[RegionContentPhase20] FAIL: %s" % label)
