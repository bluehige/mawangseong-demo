extends Node

const PressureScript = preload("res://scripts/systems/enemies/MirellaEnemyPressureService.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_enemy_data()
	_test_wet_spore()
	_test_root_barrier()
	_test_overlays_and_balance()
	if failed:
		print("MIRELLA_ENEMY_PACKAGE_PHASE19_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("MIRELLA_ENEMY_PACKAGE_PHASE19_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_enemy_data() -> void:
	var spore: Dictionary = DataRegistry.enemies.get("spore_doll", {})
	var root: Dictionary = DataRegistry.enemies.get("root_tender", {})
	_expect(is_equal_approx(float(spore.get("threat", 0.0)), 1.10) and is_equal_approx(float(root.get("threat", 0.0)), 1.40), "포자 인형·뿌리 정원사 threat 계약")
	_expect(bool(spore.get("placeholder_art", false)) and bool(root.get("placeholder_art", false)) and not DataRegistry.enemies.has("boss_mirella"), "일반 적 placeholder·미렐라 보스 금지")
	var spore_unit = UnitScript.new()
	add_child(spore_unit)
	spore_unit.setup("spore_doll", spore, "enemy", "entrance")
	_expect(spore_unit.max_hp == 120 and spore_unit.atk == 8 and spore_unit.def == 3 and is_equal_approx(spore_unit.move_speed, 96.0), "포자 인형 능력치")
	spore_unit.queue_free()
	var root_unit = UnitScript.new()
	add_child(root_unit)
	root_unit.setup("root_tender", root, "enemy", "entrance")
	_expect(root_unit.max_hp == 145 and root_unit.atk == 10 and root_unit.def == 5 and is_equal_approx(root_unit.move_speed, 88.0), "뿌리 정원사 능력치")
	root_unit.queue_free()


func _test_wet_spore() -> void:
	var skill: Dictionary = DataRegistry.skills.wet_spore
	var first := PressureScript.place_wet_spore([], "zone_a", "upper_slot", skill)
	_expect(bool(first.ok) and is_equal_approx(float(first.zones[0].duration), 5.0), "젖은 포자 5초 구역")
	_expect(is_equal_approx(float(first.zones[0].enemy_heal_multiplier), 1.10) and is_equal_approx(float(first.zones[0].player_move_multiplier), 0.85), "적 회복 +10%·플레이어 이동 -15%")
	_expect(not bool(PressureScript.place_wet_spore(first.zones, "zone_b", "upper_slot", skill).ok), "같은 구역 중첩 금지")
	var second := PressureScript.place_wet_spore(first.zones, "zone_b", "throne", skill)
	_expect(bool(second.ok) and not bool(PressureScript.place_wet_spore(second.zones, "zone_c", "barracks", skill).ok), "활성 포자 구역 상한 2")
	_expect(PressureScript.cleanse_zone(second.zones, "zone_a").size() == 1, "정화로 포자 구역 제거")
	_expect(float(PressureScript.fire_reduce_zone(first.zones[0], 8.0).duration) == 3.0, "화염으로 포자 지속시간 감소")


func _test_root_barrier() -> void:
	var skill: Dictionary = DataRegistry.skills.root_threshold
	var placed := PressureScript.place_root_barrier([], "root_a", "stair", skill)
	_expect(bool(placed.ok) and is_equal_approx(float(placed.barriers[0].duration), 6.0), "뿌리 문턱 계단 6초 장벽")
	_expect(is_equal_approx(float(placed.barriers[0].player_move_multiplier), 0.55) and is_equal_approx(float(placed.barriers[0].enemy_move_multiplier), 1.0), "몬스터만 지연·적 이동 영향 없음")
	_expect(not bool(PressureScript.place_root_barrier(placed.barriers, "root_b", "threshold", skill).ok), "뿌리 장벽 동시 1개")
	var damaged := PressureScript.damage_barrier(placed.barriers[0], 45)
	_expect(not bool(damaged.active) and int(damaged.hp) == 0, "피해로 뿌리 장벽 제거")
	_expect(not PressureScript.has_deadlock(placed.barriers[0], false), "우회로 없어도 파괴·정화 가능해 교착 없음")
	_expect(not bool(PressureScript.place_root_barrier([], "root_x", "room_center", skill).ok), "문턱·계단 외 배치 금지")


func _test_overlays_and_balance() -> void:
	var overlays: Dictionary = DataRegistry.update4_region_day_overlays
	var mist: Dictionary = overlays.get("mistcap_garden_pressure", {})
	var bone: Dictionary = overlays.get("bone_lantern_morale_pressure", {})
	_expect(is_equal_approx(float(mist.get("all_healing_multiplier", 0.0)), 1.10) and int(mist.get("slow_cap_relief_points", 0)) == 5, "안개습원 회복 +10%·둔화 상한 -5%p")
	_expect(is_equal_approx(float(bone.get("morale_damage_multiplier", 0.0)), 1.15) and bool(bone.get("down_signal_emphasis", false)), "묘원 사기 효과 +15%·전투불능 표시 강화")
	var mist_wave := PressureScript.region_wave("region_mistcap_marsh", DataRegistry.enemies)
	var bone_wave := PressureScript.region_wave("region_bone_lantern_fields", DataRegistry.enemies)
	_expect(bool(mist_wave.within_budget) and bool(bone_wave.within_budget), "안개습원·묘원 threat 예산 ±5%")
	var raw_trial := PressureScript.healing_build_trial(2, false, false)
	_expect(bool(raw_trial.completable) and float(raw_trial.efficiency_reduction_ratio) >= 0.20 and float(raw_trial.efficiency_reduction_ratio) <= 0.25, "회복형 빌드 20~25% 압박 후 완주 가능")
	_expect(float(PressureScript.healing_build_trial(2, true, false).effective_survival) > float(raw_trial.effective_survival), "정화 대응으로 회복 빌드 개선")
	_expect(float(PressureScript.healing_build_trial(2, false, true).effective_survival) > float(raw_trial.effective_survival), "화염 대응으로 회복 빌드 개선")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[MirellaEnemyPackagePhase19] FAIL: %s" % label)
