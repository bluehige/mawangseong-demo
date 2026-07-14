extends Node

const SilkyScript = preload("res://scripts/systems/monsters/SilkyCombatService.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_and_unit()
	_test_thread_scenarios()
	_test_rescue_and_transition()
	_test_ai_fallback()
	if failed:
		print("SILKY_COMBAT_PHASE13_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("SILKY_COMBAT_PHASE13_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_data_and_unit() -> void:
	_expect(DataRegistry.monsters.has("spider_tailor") and DataRegistry.monster_instances.has("MON_SILKY") and DataRegistry.characters.has("CHR_SILKY"), "실키 species·instance·character 분리 로드")
	_expect(DataRegistry.skills.has("stitch_stairway") and DataRegistry.skills.has("emergency_thread_pull") and DataRegistry.skills.has("ceiling_path"), "실키 액티브 2개·패시브 1개")
	_expect(DataRegistry.specializations.has("silky_stair_warden") and DataRegistry.specializations.has("silky_field_tailor"), "실키 전술 특화 2개")
	var definition: Dictionary = DataRegistry.monsters.spider_tailor
	_expect(bool(definition.placeholder_art) and not definition.has("sprite"), "Phase 13 최종 아트 금지·placeholder Unit")
	var unit = UnitScript.new()
	add_child(unit)
	unit.setup("spider_tailor", definition, "monster", "spike_corridor")
	_expect(unit.max_hp == 128 and unit.atk == 11 and unit.def == 3 and is_equal_approx(unit.move_speed, 118.0), "실키 기본 능력치 런타임 적용")
	_expect(float(definition.atk) / float(definition.attack_interval) < float(DataRegistry.monsters.goblin.atk) / float(DataRegistry.monsters.goblin.attack_interval) and definition.max_hp < DataRegistry.monsters.slime.max_hp, "기존 화력·탱커 몬스터 상위호환 아님")
	unit.queue_free()


func _test_thread_scenarios() -> void:
	var skill: Dictionary = DataRegistry.skills.stitch_stairway
	var placed := SilkyScript.place_thread(SilkyScript.new_state(), "stair", ["stair", "threshold"], "", skill)
	_expect(bool(placed.ok) and str(placed.state.thread.anchor) == "stair", "계단 꿰매기 계단 시나리오")
	var state: Dictionary = placed.state
	for index in 4:
		var triggered := SilkyScript.trigger_thread(state, "enemy_%d" % index)
		state = triggered.state
		_expect(bool(triggered.applied) and is_equal_approx(float(triggered.effect.move_multiplier), 0.65) and is_equal_approx(float(triggered.effect.duration), 4.0), "거미실 %d번째 적 35%% 둔화" % (index + 1))
	var fifth := SilkyScript.trigger_thread(state, "enemy_5")
	_expect(not bool(fifth.applied), "거미실 첫 4명 이후 비활성")
	var threshold := SilkyScript.place_thread(SilkyScript.new_state(), "missing", ["threshold"], "", skill)
	_expect(bool(threshold.ok) and str(threshold.state.thread.anchor) == "threshold", "계단 없는 1층 문턱 fallback")
	var outpost := SilkyScript.place_thread(SilkyScript.new_state(), "stair", ["outpost_retreat"], "", skill)
	_expect(bool(outpost.ok) and str(outpost.state.thread.anchor) == "outpost_retreat", "전초기지 퇴각 통로 fallback")
	var burning := SilkyScript.apply_fire_hit(placed.state, 1)
	_expect(bool(burning.thread.active), "화염 피해 1회 후 거미실 유지")
	burning = SilkyScript.apply_fire_hit(burning, 1)
	_expect(not bool(burning.thread.active), "화염 피해 2회에 거미실 제거")
	var warden := SilkyScript.place_thread(SilkyScript.new_state(), "stair", ["stair"], "silky_stair_warden", skill)
	_expect(is_equal_approx(float(warden.state.thread.slow_multiplier), 0.60) and int(warden.state.thread.fire_durability) == 3, "계단 파수 재봉 특화 제어 강화")


func _test_rescue_and_transition() -> void:
	var skill: Dictionary = DataRegistry.skills.emergency_thread_pull
	var ally := {"id": "ally_low", "hp": 30, "max_hp": 100, "alive": true, "fixed": false, "boss": false}
	var pulled := SilkyScript.emergency_pull(SilkyScript.new_state(), ally, Vector2.LEFT, "", skill)
	_expect(bool(pulled.ok) and is_equal_approx(pulled.pull_offset.length(), 120.0) and int(pulled.shield) == 10, "응급 실밥 120px 구조·10% 보호막")
	ally.fixed = true
	var fixed := SilkyScript.emergency_pull(SilkyScript.new_state(), ally, Vector2.RIGHT, "", skill)
	_expect(bool(fixed.ok) and fixed.pull_offset == Vector2.ZERO and int(fixed.shield) == 10, "고정형 아군 이동 금지·보호막 적용")
	ally.fixed = false
	var tailor := SilkyScript.emergency_pull(SilkyScript.new_state(), ally, Vector2.LEFT, "silky_field_tailor", skill)
	_expect(int(tailor.shield) == 15 and int(tailor.facility_repair) == 12, "전장 수선사 보호막·시설 수리 강화")
	var transition := SilkyScript.ceiling_path_transition(0.60, true, DataRegistry.skills.ceiling_path)
	_expect(is_equal_approx(float(transition.transition_seconds), 0.36) and bool(transition.ignore_ally_queue_collision) and is_equal_approx(float(transition.first_move_multiplier), 1.20), "천장길 전이 -40%·아군 충돌 무시·경보 이동 +20%")


func _test_ai_fallback() -> void:
	var rescue := SilkyScript.choose_ai_action(SilkyScript.new_state(), [{"id": "hurt", "hp": 20, "max_hp": 100, "alive": true}], ["stair"], false)
	_expect(str(rescue.action) == "emergency_thread_pull", "실키 AI 저체력 구조 우선")
	var outpost := SilkyScript.choose_ai_action(SilkyScript.new_state(), [], ["outpost_retreat"], true)
	_expect(str(outpost.action) == "stitch_stairway" and str(outpost.anchor) == "outpost_retreat", "실키 AI 전초기지 fallback")
	var no_anchor := SilkyScript.choose_ai_action(SilkyScript.new_state(), [], [], false)
	_expect(str(no_anchor.action) == "basic_attack", "계단·문턱 없음 AI 교착 없이 기본 공격")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[SilkyCombatPhase13] FAIL: %s" % label)
