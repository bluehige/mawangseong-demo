extends Node
const Unit = preload("res://scripts/units/Unit.gd")
const Combat = preload("res://scripts/game/CombatSceneController.gd")
const Constants = preload("res://scripts/core/Constants.gd")
class Arena extends Node:
	var monster_units: Array = []
	var enemy_units: Array = []
	var combat_time := 0.0
	var graph: Node = self
	var quarter_renderer = null
	var wall_enabled := false
	func room_at_world(point: Vector2) -> String:
		return "arena" if Rect2(80,80,300,260).has_point(point) else ""
	func _clamp_to_combat_walkable(point: Vector2) -> Vector2:
		return _clamp_unit_to_combat_walkable(point, null)
	func _clamp_unit_to_combat_walkable(point: Vector2, _unit: Node) -> Vector2:
		if wall_enabled and Rect2(208,180,8,80).has_point(point):
			return Vector2(207,point.y)
		return point.clamp(Vector2(80,80), Vector2(379,339))
var failed := false
var count := 0
func expect(ok: bool, label: String) -> void:
	count += 1
	if not ok:
		failed = true
		push_error("CROWD_ASSERT " + label)
func actor(arena: Node, id: String, side: String, point: Vector2):
	var unit = Unit.new()
	arena.add_child(unit)
	unit.setup(id, DataRegistry.monster(id) if side == Constants.FACTION_MONSTER else DataRegistry.enemy(id), side, "arena")
	unit.set_physics_process(false)
	unit.global_position = point
	unit.move_speed = 100.0
	unit.intrinsic_move_multiplier = 1.0
	return unit
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	var arena := Arena.new()
	add_child(arena)
	var combat := Combat.new()
	combat.root = arena
	var target = actor(arena,"explorer",Constants.FACTION_ENEMY,Vector2(230,210))
	arena.enemy_units.append(target)
	for i in range(4):
		var u = actor(arena,"goblin",Constants.FACTION_MONSTER,Vector2(195,210))
		u.attack_range = 48.0
		arena.monster_units.append(u)
	var before: Vector2 = arena.monster_units[0].global_position
	var maximum_step := 0.0
	for tick in range(120):
		arena.combat_time += 1.0/60.0
		for u in arena.monster_units:
			if tick % 6 == 0:
				if not combat._hold_attack_position(u,target):
					combat._move_to_attack_target(u,target)
			var old: Vector2 = u.global_position
			u._physics_process(1.0/60.0)
			maximum_step = maxf(maximum_step, old.distance_to(u.global_position))
	expect(maximum_step <= 1.6671,"spacing obeys movement speed throughout convergence")
	for i in range(4):
		var u = arena.monster_units[i]
		expect(u.global_position.distance_to(target.global_position) <= u.attack_range,"spacing keeps attack range")
		for j in range(i+1,4):
			expect(u.global_position.distance_to(arena.monster_units[j].global_position) >= 17.5,"overlapping allies settle into separate positions")
	expect(arena.monster_units[0].global_position.distance_to(before) < 0.01,"first defender holds ground")
	var u = arena.monster_units[1]
	u.global_position = Vector2(195,210)
	u.stop_navigation()
	u.remove_meta("attack_position_claim")
	arena.wall_enabled = true
	expect(not combat._attack_position_segment_clear(u,Vector2(240,210)),"reject segment across thin wall even when both ends are walkable")
	var point: Vector2 = combat._attack_approach_point(u,target)
	expect(point == target.global_position or combat._attack_position_segment_clear(u,point),"selected spacing position has clear segment")
	arena.wall_enabled = false
	target.current_room = "other_room"
	expect(combat._attack_approach_point(u,target) == target.global_position,"cross-room pursuit uses original navigation")
	target.current_room = "arena"
	u.seal_move_lock_timer = 10.0
	u.set_path([Vector2(180,220)])
	var locked: Vector2 = u.global_position
	u._physics_process(0.1)
	expect(u.global_position == locked,"crowd adjustment cannot break movement lock")
	u.seal_move_lock_timer = 0.0
	u.stop_navigation()
	u.attack_anim_timer = 0.0
	u.skill_anim_timer = 0.0
	u.velocity = Vector2(-100,20)
	u._update_animation()
	expect(u.sprite.flip_h,"clear left movement turns left")
	u.velocity = Vector2(3,-100)
	u._update_animation()
	expect(u.sprite.flip_h,"small lateral correction does not flip body")
	u.velocity = Vector2(100,20)
	u._update_animation()
	expect(not u.sprite.flip_h,"clear right movement responds immediately")
	u.velocity = Vector2(100,45)
	u._update_animation()
	expect(u.movement_facing == "side","side direction hysteresis")
	u.velocity = Vector2(100,70)
	u._update_animation()
	expect(u.movement_facing == "front","leaving side dead zone turns front")
	u.velocity = Vector2(0,-100)
	u._update_animation()
	expect(u.movement_facing == "back","upward movement selects back")
	u.velocity = Vector2.ZERO
	u._update_animation()
	expect(u.movement_facing == "back","stopping retains last direction")
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/uiux_actor_art.json"))
	for art_id in ["imp_flame_adept","slime_rescue_alchemy_gel"]:
		var stats: Dictionary = DataRegistry.monster("imp" if art_id.begins_with("imp") else "slime").duplicate(true)
		stats["sprite"] = art[art_id]["path"]
		u.setup("imp" if art_id.begins_with("imp") else "slime",stats,Constants.FACTION_MONSTER,"arena")
		u.attack_anim_timer = 0.0
		u.skill_anim_timer = 0.0
		u.velocity = Vector2(0,-100)
		u._update_animation()
		expect(u.sprite.frame == int(art[art_id]["directional_move_frames"]["back"]),"actual art uses back frame " + art_id)
		u.velocity = Vector2.ZERO
		u._update_animation()
		expect(u.sprite.animation == "move_down" and u.sprite.frame == int(art[art_id]["directional_move_frames"]["back"]),"actual art holds back frame at rest " + art_id)
		u.velocity = Vector2(0,100)
		u._update_animation()
		expect(u.sprite.frame == int(art[art_id]["directional_move_frames"]["front"]),"actual art returns to front on forward movement " + art_id)
	var peer = arena.monster_units[0]
	peer.global_position = Vector2(100,100)
	var sample := Vector2(330,300)
	peer.set_meta("attack_position_claim",{"point":sample,"until":arena.combat_time + 0.1})
	expect(combat._attack_position_pressure(u,sample) > 0,"live reservation avoids conflicting destinations")
	arena.combat_time += 0.2
	expect(combat._attack_position_pressure(u,sample) == 0,"expired reservation does not block new command")
	peer.set_meta("attack_position_claim",{"point":sample,"until":arena.combat_time + 1.0})
	peer.hp = 0
	expect(combat._attack_position_pressure(u,sample) == 0,"defeated teammate releases its destination")
	var support: Vector2 = combat._support_point_inside_room(Vector2(350,210),Vector2(410,210))
	expect(arena.room_at_world(support) == "arena","support destination stays inside the room that activates its order")
	expect(support.x < 377.0,"support destination has room-boundary margin")
	arena.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("UIUX_CROWD_MOTION_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS",count])
	get_tree().quit(1 if failed else 0)
