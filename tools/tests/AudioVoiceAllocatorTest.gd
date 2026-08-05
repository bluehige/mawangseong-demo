extends Node

const AllocatorScript = preload("res://scripts/audio/AudioVoiceAllocator.gd")
const CatalogScript = preload("res://scripts/audio/AudioCatalogApi.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_voice_budget()
	_test_catalog_resolution()
	if failed:
		print("AUDIO_VOICE_ALLOCATOR_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("AUDIO_VOICE_ALLOCATOR_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_voice_budget() -> void:
	var allocator = AllocatorScript.new()
	for index in range(AllocatorScript.MAX_GLOBAL_ONE_SHOTS):
		var result: Dictionary = allocator.admit_voice(
			"ambient_%02d" % index,
			AllocatorScript.CATEGORY_GENERAL,
			AllocatorScript.PRIORITY_GENERAL,
			"ambient_%02d" % index,
			float(index)
		)
		_expect(bool(result.get("accepted", false)), "global 24개까지 일반 voice 승인")
	_expect(allocator.active_count() == AllocatorScript.MAX_GLOBAL_ONE_SHOTS, "global 상한은 24")

	var critical: Dictionary = allocator.admit_voice(
		"boss_warning",
		AllocatorScript.CATEGORY_GENERAL,
		AllocatorScript.PRIORITY_CRITICAL,
		"boss.warning",
		100.0
	)
	_expect(bool(critical.get("accepted", false)), "중요 경보는 global 상한에서 승인")
	_expect(str(critical.get("evicted_id", "")) == "ambient_00", "상한 초과 시 가장 오래된 낮은 우선순위 voice 축출")
	_expect(not allocator.snapshot().has("ambient_00"), "축출된 voice는 active 목록에서 제거")

	allocator.clear()
	for index in range(AllocatorScript.MAX_GENERAL_EVENT_VOICES):
		var group_result: Dictionary = allocator.admit_voice(
			"slash_%d" % index,
			AllocatorScript.CATEGORY_GENERAL,
			AllocatorScript.PRIORITY_GENERAL,
			"attack.slash",
			float(index)
		)
		_expect(bool(group_result.get("accepted", false)), "같은 일반 event 4개까지 승인")
	var group_rejected: Dictionary = allocator.admit_voice(
		"slash_overflow",
		AllocatorScript.CATEGORY_GENERAL,
		AllocatorScript.PRIORITY_GENERAL,
		"attack.slash",
		10.0
	)
	_expect(not bool(group_rejected.get("accepted", true)), "같은 일반 event 5번째는 상한으로 거부")
	_expect(str(group_rejected.get("reason", "")) == "cap_protected", "동급 voice 보호 사유를 반환")
	var unique_skill: Dictionary = allocator.admit_voice(
		"skill_unique",
		AllocatorScript.CATEGORY_GENERAL,
		AllocatorScript.PRIORITY_UNIQUE,
		"attack.slash",
		11.0
	)
	_expect(bool(unique_skill.get("accepted", false)), "고유 스킬은 일반 event 상한에서 승인")
	_expect(str(unique_skill.get("evicted_id", "")) == "slash_0", "고유 스킬이 오래된 일반 타격을 축출")
	_expect(allocator.active_count_for_event("attack.slash") == AllocatorScript.MAX_GENERAL_EVENT_VOICES, "일반 event 상한 유지")

	allocator.clear()
	allocator.admit_voice("ui_1", AllocatorScript.CATEGORY_UI, AllocatorScript.PRIORITY_UI, "ui", 1.0)
	allocator.admit_voice("ui_2", AllocatorScript.CATEGORY_UI, AllocatorScript.PRIORITY_UI, "ui", 2.0)
	var ui_low: Dictionary = allocator.admit_voice("ui_low", AllocatorScript.CATEGORY_UI, AllocatorScript.PRIORITY_UNIQUE, "ui", 3.0)
	_expect(not bool(ui_low.get("accepted", true)), "UI 상한을 높은 우선순위 UI가 보호")
	var ui_critical: Dictionary = allocator.admit_voice("ui_critical", AllocatorScript.CATEGORY_UI, AllocatorScript.PRIORITY_CRITICAL, "ui", 4.0)
	_expect(bool(ui_critical.get("accepted", false)) and str(ui_critical.get("evicted_id", "")) == "ui_1", "중요 UI가 가장 오래된 UI를 대체")
	_expect(allocator.active_count_for_category(AllocatorScript.CATEGORY_UI) == AllocatorScript.MAX_UI_VOICES, "UI 상한은 2")

	allocator.clear()
	for index in range(AllocatorScript.MAX_FOOTSTEP_VOICES):
		allocator.admit_voice("step_%d" % index, AllocatorScript.CATEGORY_FOOTSTEP, AllocatorScript.PRIORITY_FOOTSTEP, "steps", float(index))
	var step_overflow: Dictionary = allocator.admit_voice("step_overflow", AllocatorScript.CATEGORY_FOOTSTEP, AllocatorScript.PRIORITY_FOOTSTEP, "steps", 3.0)
	_expect(not bool(step_overflow.get("accepted", true)), "발소리 상한은 3")
	var step_warning: Dictionary = allocator.admit_voice("step_warning", AllocatorScript.CATEGORY_FOOTSTEP, AllocatorScript.PRIORITY_CRITICAL, "steps", 4.0)
	_expect(bool(step_warning.get("accepted", false)) and str(step_warning.get("evicted_id", "")) == "step_0", "중요 경보는 오래된 발소리를 축출")

	allocator.clear()
	for index in range(AllocatorScript.MAX_GLOBAL_ONE_SHOTS):
		allocator.admit_voice("protected_%02d" % index, AllocatorScript.CATEGORY_GENERAL, AllocatorScript.PRIORITY_CRITICAL, "protected_%02d" % index, float(index))
	var low_overflow: Dictionary = allocator.admit_voice("low_overflow", AllocatorScript.CATEGORY_GENERAL, AllocatorScript.PRIORITY_GENERAL, "low", 30.0)
	_expect(not bool(low_overflow.get("accepted", true)), "낮은 우선순위 요청은 보호된 voice를 축출하지 않음")
	_expect(allocator.release_voice("protected_00"), "voice release 성공")
	_expect(allocator.active_count() == AllocatorScript.MAX_GLOBAL_ONE_SHOTS - 1, "release 후 global 수 감소")
	_expect(not allocator.release_voice("not_active"), "없는 voice release는 false")


func _test_catalog_resolution() -> void:
	CatalogScript.reset_for_test()
	var resolved_event: Dictionary = CatalogScript.resolve_event("music.screen.management")
	_expect(not resolved_event.is_empty(), "등록된 관리 BGM event 해석")
	_expect(str(resolved_event.get("event", {}).get("asset_id", "")) == "management_castle_bustle", "event와 asset 연결 확인")
	_expect(str(resolved_event.get("runtime_path", "")).ends_with("management_castle_bustle.wav"), "runtime 경로 확인")
	var resolved_asset: Dictionary = CatalogScript.resolve_asset("combat_hit")
	_expect(not resolved_asset.is_empty(), "실제 runtime SFX asset 해석")
	var connected_update4: Dictionary = CatalogScript.resolve_asset("boss_brassa_motif")
	_expect(not connected_update4.is_empty(), "Update 4 보스 모티프가 재생 경로로 해석됨")
	var missing_event: Dictionary = CatalogScript.resolve_event("audio.missing.event")
	_expect(missing_event.is_empty(), "없는 event를 빈 결과로만 소비하지 않고 차단")
	var missing_asset: Dictionary = CatalogScript.resolve_asset("audio_missing_asset")
	_expect(missing_asset.is_empty(), "없는 asset을 차단")
	var diagnostics: Array = CatalogScript.diagnostics()
	_expect(_contains_diagnostic(diagnostics, "AUDIO_CATALOG_MISSING_EVENT"), "없는 event 진단 로그 기록")
	_expect(_contains_diagnostic(diagnostics, "AUDIO_CATALOG_MISSING_ASSET"), "없는 asset 진단 로그 기록")


func _contains_diagnostic(values: Array, prefix: String) -> bool:
	for value in values:
		if str(value).begins_with(prefix):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % message)
		return
	failed = true
	push_error("  FAIL - %s" % message)
