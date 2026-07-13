extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const UnitActorScript = preload("res://scripts/units/Unit.gd")

const COUNTERFORCE_IDS := [
	"royal_scout",
	"monster_binder",
	"ward_breaker",
	"supply_raider",
	"anti_magic_archer",
	"royal_field_medic",
	"royal_strategist_evelyn"
]
const FRAME_COUNTS := {
	"idle_down": 2,
	"move_down": 4,
	"attack_down": 4,
	"skill_down": 4,
	"down": 2
}

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_counterforce_data()
	_test_graphics_contract()
	await _test_runtime_behaviors()
	if failed:
		print("UPDATE2_COUNTERFORCE_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE2_COUNTERFORCE_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_counterforce_data() -> void:
	_expect(DataRegistry.update2_counterforce_ids() == COUNTERFORCE_IDS, "왕국 대응군 7종이 설계 순서대로 등록됨")
	for enemy_id in COUNTERFORCE_IDS:
		var profile: Dictionary = DataRegistry.update2_counterforce_profile(enemy_id)
		var enemy: Dictionary = DataRegistry.enemy(enemy_id)
		_expect(not profile.is_empty(), "%s 대응 행동 데이터" % enemy_id)
		_expect(not enemy.is_empty() and str(enemy.get("display_name", "")) != "", "%s 전투 유닛 데이터" % enemy_id)
		_expect(str(enemy.get("sprite", "")).begins_with("res://assets/sprites/enemies/enemy_%s_" % enemy_id), "%s 전용 그래픽 참조" % enemy_id)
		var strength := float(profile.get("counter_strength", 0.0))
		_expect(strength >= 0.0 and strength <= 0.35, "%s 소프트 카운터가 35%% 상한 이내" % enemy_id)
		_expect(float(profile.get("cooldown", 0.0)) > 0.0, "%s 행동 재사용 대기시간 존재" % enemy_id)
	var evelyn: Dictionary = DataRegistry.character("CHR_EVELYN")
	_expect(evelyn.get("unit_ref", {}).get("id", "") == "royal_strategist_evelyn", "에블린 캐릭터와 전투 유닛 연결")
	_expect(ResourceLoader.exists(str(evelyn.get("portrait", {}).get("base", ""))), "에블린 초상화 파일 존재")


func _test_graphics_contract() -> void:
	_expect(FileAccess.file_exists("res://assets/source/imagegen/update2_counterforce/SOURCE.md"), "생성 그래픽 출처 문서 보존")
	for source_name in ["design", "move", "attack", "skill", "down"]:
		var source_path := "res://assets/source/imagegen/update2_counterforce/counterforce_%s_sheet_4x2_chroma.png" % source_name
		_expect(FileAccess.file_exists(source_path), "%s 원본 생성 시트 보존" % source_name)
	for enemy_id in COUNTERFORCE_IDS:
		var idle_path := "res://assets/sprites/enemies/enemy_%s_idle_down_00.png" % enemy_id
		var frames: SpriteFrames = UnitActorScript.warm_animation_frames(idle_path)
		_expect(frames != null, "%s 애니메이션 묶음 로드" % enemy_id)
		if frames == null:
			continue
		for animation_name in FRAME_COUNTS.keys():
			_expect(frames.has_animation(animation_name), "%s %s 애니메이션 존재" % [enemy_id, animation_name])
			if frames.has_animation(animation_name):
				_expect(frames.get_frame_count(animation_name) == int(FRAME_COUNTS[animation_name]), "%s %s 프레임 수" % [enemy_id, animation_name])
		var texture: Texture2D = ResourceLoader.load(idle_path)
		var image: Image = texture.get_image() if texture != null else null
		_expect(image != null and image.detect_alpha() != Image.ALPHA_NONE, "%s 런타임 프레임에 투명 배경 존재" % enemy_id)


func _test_runtime_behaviors() -> void:
	var root = GameRootScene.instantiate()
	add_child(root)
	await get_tree().process_frame
	root._onboarding_reset_game()

	root._clear_units()
	var capped = _add_monster(root, "slime", Vector2(700, 500))
	var applied: float = capped.apply_soft_counter("movement", 5.0, 1.0, "test")
	_expect(is_equal_approx(applied, 0.35), "비정상적으로 큰 대응 수치도 35%로 제한")
	_expect(is_equal_approx(capped.soft_counter_move_multiplier, 0.65) and capped.soft_counter_move_multiplier > 0.0, "이동 대응은 둔화일 뿐 행동 불능이 아님")

	root._clear_units()
	var scout = _add_enemy(root, "royal_scout", Vector2(760, 500))
	var short_range = _add_monster(root, "slime", Vector2(700, 500))
	var long_range = _add_monster(root, "imp", Vector2(710, 500))
	short_range.attack_range = 30.0
	long_range.attack_range = 500.0
	_expect(root.combat_scene._try_update2_counter_action(scout), "왕실 정찰병이 후열 약점 노출 사용")
	_expect(is_equal_approx(long_range.soft_counter_damage_taken_multiplier, 1.20) and is_equal_approx(short_range.soft_counter_damage_taken_multiplier, 1.0), "가장 긴 사거리 대상만 받는 피해 20% 증가")

	root._clear_units()
	var binder = _add_enemy(root, "monster_binder", Vector2(760, 500))
	var bound = _add_monster(root, "slime", Vector2(720, 500))
	_expect(root.combat_scene._try_update2_counter_action(binder), "마물 구속병이 룬 구속 사용")
	_expect(is_equal_approx(bound.soft_counter_move_multiplier, 0.70), "룬 구속이 이동 효율만 30% 감소")

	root._clear_units()
	var breaker = _add_enemy(root, "ward_breaker", Vector2(760, 500))
	var warded = _add_monster(root, "stone_sentinel", Vector2(720, 500))
	_expect(root.combat_scene._try_update2_counter_action(breaker), "결계 파쇄병이 수호 파쇄 사용")
	_expect(is_equal_approx(warded.soft_counter_healing_multiplier, 0.70), "수호 파쇄가 회복 효율 30% 감소")
	_expect(is_equal_approx(warded.soft_counter_shield_multiplier, 0.70), "수호 파쇄가 보호막 효율 30% 감소")

	root._clear_units()
	var raider = _add_enemy(root, "supply_raider", Vector2(760, 500))
	var defender = _add_monster(root, "slime", Vector2(720, 500))
	_expect(root.combat_scene._try_update2_counter_action(raider), "보급 습격병이 보급선 절단 사용")
	_expect(is_equal_approx(defender.soft_counter_attack_interval_multiplier, 1.25), "보급선 절단이 공격 간격을 25% 늘림")

	root._clear_units()
	var archer = _add_enemy(root, "anti_magic_archer", Vector2(760, 500))
	var caster = _add_monster(root, "imp", Vector2(720, 500))
	_expect(root.combat_scene._try_update2_counter_action(archer), "파마 궁수가 파마 화살 사용")
	_expect(is_equal_approx(caster.soft_counter_skill_recovery_multiplier, 0.75), "파마 화살이 기술 회복 속도만 25% 감소")

	root._clear_units()
	var medic = _add_enemy(root, "royal_field_medic", Vector2(760, 500))
	var wounded = _add_enemy(root, "royal_scout", Vector2(720, 500))
	wounded.receive_damage(60)
	wounded.apply_slow(3.0, 0.5)
	var hp_before := int(wounded.hp)
	_expect(root.combat_scene._try_update2_counter_action(medic), "왕실 야전의무관이 응급처치 사용")
	_expect(int(wounded.hp) > hp_before and is_equal_approx(wounded.slow_factor, 1.0), "응급처치가 아군을 회복하고 둔화를 정화")

	root._clear_units()
	var evelyn = _add_enemy(root, "royal_strategist_evelyn", Vector2(760, 500))
	var healer = _add_monster(root, "spore_healer", Vector2(710, 500))
	var tank = _add_monster(root, "slime", Vector2(720, 500))
	_expect(root.combat_scene._try_update2_counter_action(evelyn), "에블린이 현재 출전 편성을 분석해 대응 전술 사용")
	_expect(is_equal_approx(healer.soft_counter_healing_multiplier, 0.75) and is_equal_approx(tank.soft_counter_healing_multiplier, 0.75), "회복형 편성에는 회복 효율 대응을 전체 적용")
	_expect(healer.soft_counter_max_strength() <= 0.35 and tank.soft_counter_max_strength() <= 0.35, "에블린 효과도 35% 상한을 넘지 않음")
	_expect(int(root.combat_scene.update2_counter_activations.get("royal_strategist_evelyn", 0)) == 1, "에블린 전술 발동 횟수 기록")
	root.queue_free()
	await get_tree().process_frame


func _add_monster(root: Node, monster_id: String, position: Vector2) -> Node:
	var unit = root._create_unit(monster_id, DataRegistry.monster(monster_id), Constants.FACTION_MONSTER, "entrance")
	unit.global_position = position
	root.monster_units.append(unit)
	return unit


func _add_enemy(root: Node, enemy_id: String, position: Vector2) -> Node:
	var unit = root._create_unit(enemy_id, DataRegistry.enemy(enemy_id), Constants.FACTION_ENEMY, "entrance")
	unit.global_position = position
	root.enemy_units.append(unit)
	return unit


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[Update2Counterforce] FAIL: %s" % message)
