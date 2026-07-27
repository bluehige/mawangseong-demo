class_name V122EncounterAdapter
extends RefCounted


static func telegraph(enemy: Dictionary, battle_plan: Dictionary) -> Dictionary:
	var role := str(enemy.get("role", enemy.get("goal_type", "assault")))
	var target := _role_target(role, battle_plan)
	return {
		"enemy_id": str(enemy.get("id", enemy.get("unit_id", ""))),
		"role": role,
		"target_room_id": str(target.get("room_id", "")),
		"target_object_id": str(target.get("object_id", "")),
		"target_anchor": target.get("world_anchor", []),
		"route": _route_to_target(battle_plan, str(target.get("room_id", ""))),
		"counter_hint": _counter_hint(role)
	}


static func _role_target(role: String, battle_plan: Dictionary) -> Dictionary:
	var wanted_roles: Array = []
	match role:
		"engineer", "facility":
			wanted_roles = ["barracks", "watch_post", "recovery"]
		"thief", "loot":
			wanted_roles = ["treasure"]
		"heart":
			wanted_roles = ["heart_chamber"]
	for wanted_role in wanted_roles:
		for value in battle_plan.get("facility_slots", []):
			if value is Dictionary and str(value.get("facility_role", "")) == wanted_role:
				return value
	var goal_id := str(battle_plan.get("enemy_goals", ["throne"]).front())
	return {
		"room_id": goal_id,
		"object_id": "",
		"world_anchor": battle_plan.get("world_anchors", {}).get(goal_id, [])
	}


static func _route_to_target(battle_plan: Dictionary, room_id: String) -> Array:
	var route: Array = battle_plan.get("active_route", [])
	var target_index := route.find(room_id)
	return route.slice(0, target_index) if target_index >= 0 else route.duplicate()


static func _counter_hint(role: String) -> String:
	match role:
		"engineer", "facility":
			return "시설 앞 집중 또는 감시 초소로 공병 접근을 끊으세요."
		"thief", "loot":
			return "보물방 경로에 수비대를 배치하세요."
		"rearline":
			return "감시 초소 또는 집중 명령으로 후열을 노출하세요."
		"heart":
			return "심장실 앞 방어 구간을 유지하세요."
	return "첫 방어 구간에서 진입을 지연하세요."
