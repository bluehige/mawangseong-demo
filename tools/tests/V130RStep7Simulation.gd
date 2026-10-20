extends "res://scripts/game/ApprovedBattleController.gd"
## Same production battle; result UI suppressed to permit repeated isolated trials.
func finish_combat(win: bool, reason: String) -> void:
	if not running: return
	running = false
	spec_effects.refund_tolls()
	last_result = {"win":win,"reason":reason,"duration":root.combat_time,"spawned":root.spawned_count,"skills":skill_events.size(),"throne_hp":GameState.demon_lord_hp,"throne_max":GameState.demon_lord_max_hp}
	for unit in root.monster_units+root.enemy_units: unit.set_physics_process(false)

func release() -> void:
	running = false; _clear_active_combat_tweens()
	root.graph = original_graph; root.rooms = original_rooms; root.combat_scene = original_controller
	root.effect_root.reparent(effects_home,false)
	for unit in root.monster_units+root.enemy_units: unit.queue_free()
	root.monster_units.clear(); root.enemy_units.clear()
	actors.queue_free(); visuals.queue_free()
