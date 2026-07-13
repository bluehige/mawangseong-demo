extends Node

const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const FrontScreenScene = preload("res://scenes/ui/screens/FrontSelectionScreen.tscn")
const SaveV1ToV2MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd")
const SaveV2ToV3MigratorScript = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd")
const SaveV4MigratorScript = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_front_service()
	await _test_screen_contract()
	_test_v4_front_only_save()
	if failed:
		print("FRONT_SELECTION_PHASE3_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("FRONT_SELECTION_PHASE3_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_front_service() -> void:
	var catalog := DataRegistry.update3_fronts
	var profile := FrontServiceScript.default_update3_profile()
	var active := FrontServiceScript.new_cycle_active_run(2)
	var wave_snapshot := JSON.stringify(DataRegistry.waves)
	_expect(catalog.size() == 3, "전선 카탈로그 3종")
	_expect(FrontServiceScript.selectable_front_ids(profile, catalog) == [FrontServiceScript.HERO_FRONT_ID], "기본은 레온 전선만 선택 가능")
	_expect(FrontServiceScript.lock_reason(profile, FrontServiceScript.HOLY_FRONT_ID, catalog) != "", "셀렌 전선 잠금 이유 표시")
	_expect(FrontServiceScript.lock_reason(profile, FrontServiceScript.GUILD_FRONT_ID, catalog) != "", "로만 전선 잠금 이유 표시")
	_expect(FrontServiceScript.invitation_required(profile, catalog), "첫 진입 대체 전선 초대장 필요")
	var bad_invitation := FrontServiceScript.apply_invitation(profile, FrontServiceScript.HERO_FRONT_ID, catalog)
	_expect(not bool(bad_invitation.get("ok", true)), "레온 전선을 대체 초대장으로 선택 불가")
	var invitation := FrontServiceScript.apply_invitation(profile, FrontServiceScript.HOLY_FRONT_ID, catalog)
	_expect(bool(invitation.get("ok", false)), "성광 초대장 선택")
	profile = invitation.get("profile", {})
	_expect(profile.get("fronts", {}).get("unlocked", []).has(FrontServiceScript.HOLY_FRONT_ID) and not bool(profile.get("fronts", {}).get("invitation_pending", true)), "셀렌 전선 즉시 해금·초대 종료")
	_expect(not profile.get("fronts", {}).get("unlocked", []).has(FrontServiceScript.GUILD_FRONT_ID), "선택하지 않은 로만 전선은 잠금 유지")
	var locked := FrontServiceScript.select_front(profile, active, FrontServiceScript.GUILD_FRONT_ID, catalog)
	_expect(not bool(locked.get("ok", true)) and bool(active.get("new_cycle_selection_pending", false)), "잠긴 전선 선택 거부·활성 회차 불변")
	var invalid := FrontServiceScript.select_front(profile, active, "front_missing", catalog)
	_expect(not bool(invalid.get("ok", true)) and str(invalid.get("error", "")).contains("ID"), "잘못된 front ID 선택 거부")
	var selected := FrontServiceScript.select_front(profile, active, FrontServiceScript.HERO_FRONT_ID, catalog)
	_expect(bool(selected.get("ok", false)), "레온 전선 새 회차 선택")
	var selected_run: Dictionary = selected.get("active_run", {})
	_expect(str(selected_run.get("front_id", "")) == FrontServiceScript.HERO_FRONT_ID and bool(selected_run.get("front_selection_completed", false)), "레온 전선 ID·선택 완료 상태 저장")
	_expect(not bool(selected_run.get("update3_enabled", true)) and str(selected_run.get("heart", {}).get("heart_id", "")) == "", "Phase 3에서 심장·전투 활성화 금지")
	_expect(JSON.stringify(DataRegistry.waves) == wave_snapshot, "전선 선택 전후 기존 웨이브 데이터 동일")


func _test_screen_contract() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var screen = FrontScreenScene.instantiate()
	screen.setup(FrontServiceScript.default_update3_profile(), DataRegistry.update3_fronts, 2, true)
	host.add_child(screen)
	await get_tree().process_frame
	_expect(screen.get_node_or_null("DesignCanvas/FrontCardButton_front_hero_oath") != null, "레온 전선 카드 생성")
	var hero_button: Button = screen.get_node("DesignCanvas/FrontCardButton_front_hero_oath")
	var holy_button: Button = screen.get_node("DesignCanvas/FrontCardButton_front_holy_purification")
	var guild_button: Button = screen.get_node("DesignCanvas/FrontCardButton_front_guild_repossession")
	_expect(not hero_button.disabled and holy_button.disabled and guild_button.disabled, "레온 활성·셀렌/로만 UI 잠금")
	_expect(screen.get_node_or_null("DesignCanvas/InvitationStrip/HolyInvitationButton") != null and screen.get_node_or_null("DesignCanvas/InvitationStrip/GuildInvitationButton") != null, "첫 진입 초대장 버튼 2종")
	_expect(screen.get_node_or_null("DesignCanvas/FrontSelectionCancelButton") != null, "새 회차 선택 취소·복귀 버튼")
	for viewport_size in [Vector2(1920, 1080), Vector2(1366, 768)]:
		var rects: Dictionary = screen.layout_rects_for_viewport(viewport_size)
		_expect(_rects_inside(rects, viewport_size), "%dx%d 전선 카드 화면 내부" % [int(viewport_size.x), int(viewport_size.y)])
		_expect(_no_overlaps(rects), "%dx%d 전선 카드 비겹침" % [int(viewport_size.x), int(viewport_size.y)])
	host.queue_free()


func _test_v4_front_only_save() -> void:
	var v3 := _base_v3_fixture()
	var catalogs := _save_catalogs()
	var migration := SaveV4MigratorScript.migrate_envelope(v3, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, catalogs)
	_expect(bool(migration.get("ok", false)), "Phase 3 검증용 v4 기본 저장 구성")
	var envelope: Dictionary = migration.get("envelope", {}).duplicate(true)
	var profile: Dictionary = envelope.get("profile", {})
	var selection := FrontServiceScript.select_front(profile, FrontServiceScript.new_cycle_active_run(2), FrontServiceScript.HERO_FRONT_ID, DataRegistry.update3_fronts)
	var front_run: Dictionary = selection.get("active_run", {})
	for key in front_run.keys():
		envelope["active_run"][key] = front_run[key].duplicate(true) if front_run[key] is Dictionary or front_run[key] is Array else front_run[key]
	_expect(SaveV4MigratorScript.validate_v4(envelope, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, catalogs) == "", "심장 전 Phase 3 레온 전선 선택 v4 저장 유효")
	var restored = JSON.parse_string(JSON.stringify(envelope))
	_expect(restored is Dictionary and str(restored.get("active_run", {}).get("front_id", "")) == FrontServiceScript.HERO_FRONT_ID, "전선 선택 저장·이어하기 복원")
	var corrupt := envelope.duplicate(true)
	corrupt["active_run"]["front_id"] = "front_missing"
	_expect(SaveV4MigratorScript.validate_v4(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, catalogs).contains("전선"), "잘못된 front ID v4 저장 거부")
	corrupt = envelope.duplicate(true)
	corrupt["active_run"]["front_id"] = FrontServiceScript.HOLY_FRONT_ID
	corrupt["active_run"]["rival_finale"]["rival_id"] = "selen"
	_expect(SaveV4MigratorScript.validate_v4(corrupt, DataRegistry.monster_instances, DataRegistry.run_metric_definitions, catalogs).contains("전선"), "잠긴 셀렌 전선 v4 저장 거부")


func _base_v3_fixture() -> Dictionary:
	var payload := {
		"checkpoint": "management",
		"screen": "management",
		"world": {"selected_monster_id": "slime", "castle_art_stage": "stage_01_cave", "monster_roster": {"slime": {"level": 1}, "goblin": {"level": 1}, "imp": {"level": 1}}},
		"raid": {"selected_monster_ids": []},
		"campaign": {"completed": false, "final_battle_outcome": "", "postgame_active": false},
		"result": {},
		"game_state": {"day": 4},
		"onboarding": {},
		"update2": {}
	}
	var v2 := SaveV1ToV2MigratorScript.migrate_inspection({"status": "valid", "payload": payload, "summary": {"day": 4}, "saved_at_unix": 1783872000}, DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	var v3 := SaveV2ToV3MigratorScript.migrate_envelope(v2.get("envelope", {}), DataRegistry.monster_instances, DataRegistry.run_metric_definitions)
	return v3.get("envelope", {})


func _save_catalogs() -> Dictionary:
	return {
		"fronts": DataRegistry.update3_fronts,
		"castle_hearts": DataRegistry.update3_castle_hearts,
		"duo_links": DataRegistry.update3_duo_links,
		"rival_finales": DataRegistry.update3_rival_finales
	}


func _rects_inside(rects: Dictionary, viewport_size: Vector2) -> bool:
	var bounds := Rect2(Vector2.ZERO, viewport_size)
	for rect_value in rects.values():
		if not bounds.encloses(rect_value):
			return false
	return true


func _no_overlaps(rects: Dictionary) -> bool:
	var values := rects.values()
	for first in range(values.size()):
		for second in range(first + 1, values.size()):
			if values[first].intersects(values[second]):
				return false
	return true


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[FrontSelectionPhase3] FAIL: %s" % message)
