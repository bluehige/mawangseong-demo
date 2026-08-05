extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const UnitActorScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var runtime = GameRootScene.instantiate()
	add_child(runtime)
	await get_tree().process_frame
	runtime.set_process(false)
	runtime.set_physics_process(false)
	runtime.onboarding_enabled = false
	runtime.current_screen = Constants.SCREEN_COMBAT
	var combat = runtime.combat_scene
	var goblin = _spawn_unit(runtime, "goblin", DataRegistry.monster("goblin"), Constants.FACTION_MONSTER, Vector2(320, 280))
	var thief = _spawn_unit(runtime, "thief", DataRegistry.enemy("thief"), Constants.FACTION_ENEMY, Vector2(380, 280))
	var imp = _spawn_unit(runtime, "imp", DataRegistry.monster("imp"), Constants.FACTION_MONSTER, Vector2(320, 340))
	var hero = _spawn_unit(runtime, "official_hero_leon", DataRegistry.enemy("official_hero_leon"), Constants.FACTION_ENEMY, Vector2(320, 400))
	runtime.monster_units = [goblin, imp]
	runtime.enemy_units = [thief, hero]
	for unit in [goblin, thief, imp, hero]:
		unit.max_hp = 1000
		unit.hp = 1000
		unit.down = false

	_test_melee_contact(combat, goblin, thief)
	_test_projectile_contact(combat, imp, thief)
	_test_dash_contact(combat, hero, goblin)
	_test_area_contact(combat, goblin, thief)
	_test_speed_invariance(combat, goblin, thief, runtime)

	runtime.queue_free()
	await get_tree().process_frame
	if failed:
		print("CONTACT_FEEDBACK_SYNC_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("CONTACT_FEEDBACK_SYNC_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _spawn_unit(runtime: Node, unit_id: String, stats: Dictionary, faction: String, position: Vector2) -> Node:
	var unit = UnitActorScript.new()
	runtime.add_child(unit)
	unit.setup(unit_id, stats, faction, "entrance")
	unit.global_position = position
	return unit


func _reset_target(target: Node) -> void:
	target.max_hp = 1000
	target.hp = 1000
	target.down = false
	target.escaped = false
	target.visible = true


func _begin_contact(combat, runtime: Node, target: Node, amount: int, speed: float = 1.0) -> int:
	_reset_target(target)
	runtime.combat_speed = speed
	runtime.combat_time = 6.0
	combat.contact_feedback_events.clear()
	combat.contact_feedback_tokens.clear()
	var dealt := int(target.receive_damage(amount))
	return dealt


func _test_melee_contact(combat, attacker: Node, target: Node) -> void:
	var dealt := _begin_contact(combat, attacker.get_parent(), target, 18)
	combat._apply_combat_hit_feedback(attacker, target, dealt, false, "melee")
	_assert_contact(combat, "melee", dealt, "일반 공격 접촉은 피해·피격·숫자·소리·VFX를 한 사건으로 기록")


func _test_projectile_contact(combat, attacker: Node, target: Node) -> void:
	var runtime = attacker.get_parent()
	_reset_target(target)
	runtime.combat_speed = 2.0
	runtime.combat_time = 8.0
	combat.contact_feedback_events.clear()
	combat.contact_feedback_tokens.clear()
	combat._resolve_projectile_damage(
		attacker.get_instance_id(),
		target.get_instance_id(),
		attacker.global_position,
		"imp",
		"임프",
		24,
		true,
		"fireball"
	)
	_assert_contact(combat, "projectile", 24, "투사체 도착 시점이 피해와 피격 피드백의 기준 사건")


func _test_dash_contact(combat, attacker: Node, target: Node) -> void:
	var runtime = attacker.get_parent()
	_reset_target(target)
	runtime.combat_speed = 3.0
	runtime.combat_time = 10.0
	# 실제 돌진 충돌 함수는 방어 측 배열의 대상을 찾아 접촉 피드백을 발생시킨다.
	var original_monsters: Array = runtime.monster_units.duplicate()
	runtime.monster_units = [target]
	combat.contact_feedback_events.clear()
	combat.contact_feedback_tokens.clear()
	combat._apply_hero_dash_impact(attacker, target.global_position, target)
	_assert_contact(combat, "dash", 20, "돌진 충돌점에서 피해와 피격 피드백이 함께 기록")
	runtime.monster_units = original_monsters
	runtime.combat_speed = 1.0


func _test_area_contact(combat, attacker: Node, target: Node) -> void:
	var runtime = attacker.get_parent()
	var dealt := _begin_contact(combat, runtime, target, 12)
	combat._apply_combat_hit_feedback(attacker, target, dealt, false, "area")
	_assert_contact(combat, "area", dealt, "광역 스킬 접촉점에서 피해와 피드백이 함께 기록")
	runtime.audio_director.stop_all()


func _test_speed_invariance(combat, attacker: Node, target: Node, runtime: Node) -> void:
	var damages: Array[int] = []
	var frames: Array[int] = []
	for speed in [1.0, 2.0, 3.0]:
		var dealt := _begin_contact(combat, runtime, target, 17, speed)
		damages.append(dealt)
		combat._apply_combat_hit_feedback(attacker, target, dealt, false, "melee")
		frames.append(int(combat.contact_feedback_events[0].get("simulation_frame", -1)))
	_expect(damages == [17, 17, 17], "x1·x2·x3에서 동일한 고정 접촉 피해량")
	_expect(frames == [360, 360, 360], "배속이 달라도 동일 simulation 시간의 접촉 프레임")
	var event: Dictionary = combat.contact_feedback_events[0]
	_expect(event.get("channels", []) == ["damage", "hit_reaction", "damage_number", "audio", "vfx"], "다섯 피드백 채널의 순서가 하나의 접촉 사건으로 고정")


func _assert_contact(combat, expected_kind: String, expected_damage: int, message: String) -> void:
	_expect(combat.contact_feedback_events.size() == 1, message + " (단일 이벤트)")
	if combat.contact_feedback_events.is_empty():
		return
	var event: Dictionary = combat.contact_feedback_events[0]
	_expect(str(event.get("contact_kind", "")) == expected_kind, message + " (접촉 종류)")
	_expect(int(event.get("damage", 0)) == expected_damage, message + " (피해량)")
	_expect(int(event.get("target_hp_after", -1)) >= 0, message + " (HP와 이벤트 동시 기록)")
	_expect(event.get("channels", []).size() == 5, message + " (다섯 채널)")


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % message)
		return
	failed = true
	push_error("  FAIL - %s" % message)
