extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const VfxCatalogScript = preload("res://scripts/v122/combat/V122CombatVfxCatalog.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog_source := FileAccess.get_file_as_string("res://scripts/v122/combat/V122CombatVfxCatalog.gd")
	_expect("ResourceLoader.exists(frame_path)" in catalog_source, "export 패키지에서도 VFX import 리소스를 찾는 검사 방식 사용")
	_expect(not "FileAccess.file_exists(frame_path)" in catalog_source, "export에서 원본 PNG 파일 존재 여부에 의존하지 않음")
	var loaded := VfxCatalogScript.load_catalog()
	_expect(bool(loaded.get("ok", false)), "V5 전투 VFX 카탈로그 JSON과 프레임 경로 검증")
	var catalog: Dictionary = loaded.get("catalog", {})
	var active_ids: Array = VfxCatalogScript.active_ids_from_catalog(catalog)
	_expect(active_ids.size() == 34, "기본·특수·Update 4 활성 VFX ID 34종 등록")
	var validation := VfxCatalogScript.validate_catalog(catalog, active_ids)
	_expect(bool(validation.get("ok", false)) and validation.get("errors", []).is_empty(), "활성 VFX ID 미해결 0건")

	DataRegistry.load_all()
	_test_update4_references(catalog)
	var runtime = GameRootScene.instantiate()
	add_child(runtime)
	await get_tree().process_frame
	runtime.set_process(false)
	runtime.set_physics_process(false)
	runtime.onboarding_enabled = false
	runtime.current_screen = Constants.SCREEN_COMBAT
	_test_runtime_frames(runtime, active_ids)
	_test_runtime_profiles(runtime)
	runtime.queue_free()
	await get_tree().process_frame
	if failed:
		print("V122_COMBAT_VFX_CATALOG_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V122_COMBAT_VFX_CATALOG_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_update4_references(catalog: Dictionary) -> void:
	var references: Dictionary = catalog.get("references", {})
	var skill_refs: Dictionary = references.get("update4_skills", {})
	for skill_id_value in skill_refs.keys():
		var skill_id := str(skill_id_value)
		var expected := str(skill_refs[skill_id])
		_expect(str(DataRegistry.update4_skills.get(skill_id, {}).get("vfx_id", "")) == expected and not VfxCatalogScript.resolve_entry(catalog, expected).is_empty(), "%s 스킬 VFX ID가 실제 프레임으로 해석" % skill_id)
	var crown_refs: Dictionary = references.get("update4_crown_evolutions", {})
	for crown_id_value in crown_refs.keys():
		var crown_id := str(crown_id_value)
		var expected := str(crown_refs[crown_id])
		_expect(str(DataRegistry.update4_crown_evolutions.get(crown_id, {}).get("vfx_id", "")) == expected and not VfxCatalogScript.resolve_entry(catalog, expected).is_empty(), "%s 왕관 VFX ID가 실제 프레임으로 해석" % crown_id)
	var boss_refs: Dictionary = references.get("update4_rival_bosses", {})
	for boss_id_value in boss_refs.keys():
		var boss_id := str(boss_id_value)
		var expected := str(boss_refs[boss_id])
		_expect(str(DataRegistry.update4_rival_bosses.get(boss_id, {}).get("boss_vfx_id", "")) == expected and not VfxCatalogScript.resolve_entry(catalog, expected).is_empty(), "%s 보스 VFX ID가 실제 프레임으로 해석" % boss_id)


func _test_runtime_frames(runtime: Node, active_ids: Array) -> void:
	_expect(runtime.combat_vfx_catalog_errors.is_empty(), "GameRoot 런타임 VFX 카탈로그 로드 오류 0건")
	for effect_id_value in active_ids:
		var effect_id := str(effect_id_value)
		var frames: Array = runtime.effect_frame_sets.get(effect_id, [])
		_expect(frames.size() > 0 and runtime.effect_textures.get(effect_id) != null, "%s 런타임 프레임·대표 텍스처 연결" % effect_id)


func _test_runtime_profiles(runtime: Node) -> void:
	var combat = runtime.combat_scene
	var slash = combat._make_effect_sprite("slash", false, 0.0)
	combat._apply_vfx_profile(slash, "slash", Vector2.ONE)
	_expect(slash != null and str(slash.get_meta("vfx_anchor", "")) == "body" and str(slash.get_meta("vfx_depth", "")) == "unit_fx" and slash.z_index == -30, "일반 근접 VFX는 몸통 기준·전면 벽 아래 레이어")
	var boss = combat._make_effect_sprite("fx_brassa_boss", false, 0.0)
	combat._apply_vfx_profile(boss, "fx_brassa_boss", Vector2.ONE)
	_expect(boss != null and str(boss.get_meta("vfx_anchor", "")) == "aerial" and str(boss.get_meta("vfx_intensity", "")) == "boss" and boss.z_index == 3000, "보스 VFX는 공중 기준·보스 강도·전면 레이어")
	var holy_offset: Vector2 = combat._vfx_anchor_offset("holy", Vector2.ZERO)
	_expect(holy_offset == Vector2(0, -30), "공중 앵커의 기본 오프셋이 비행 위치를 사용")
	runtime.set_combat_vfx_accessibility(true, 0.8)
	var reduced = combat._make_effect_sprite("impact", false, 0.0)
	combat._apply_vfx_profile(reduced, "impact", Vector2.ONE)
	_expect(float(reduced.modulate.a) < 1.0 and reduced.scale.x < 1.0, "접근성 감소 옵션이 섬광·크기를 줄임")
	_expect(runtime.play_update4_skill_vfx("stitch_stairway", Vector2(420, 260)), "Update 4 스킬 VFX 런타임 호출 연결")
	_expect(runtime.play_update4_boss_vfx("rival_brassa_council_champion", Vector2(520, 260)), "Update 4 보스 VFX 런타임 호출 연결")
	for sprite in [slash, boss, reduced]:
		if sprite != null and is_instance_valid(sprite):
			sprite.queue_free()


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % message)
		return
	failed = true
	push_error("  FAIL - %s" % message)
