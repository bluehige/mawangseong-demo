class_name V122CombatResultViewModel
extends RefCounted

const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const LANDSCAPE_MIN_ASPECT := 1.45
const COMMAND_ORDER := ["rally", "focus", "activate_facility", "emergency_fallback"]


static func build_combat(
	battle_plan: Dictionary,
	telegraphs: Array,
	command_catalog: Dictionary,
	command_state: Dictionary,
	runtime_state: Dictionary = {}
) -> Dictionary:
	var route: Array = battle_plan.get("active_route", []).duplicate()
	var threats: Array[Dictionary] = []
	for value in telegraphs:
		if value is Dictionary and str(value.get("enemy_id", "")) != "":
			threats.append(value.duplicate(true))
	var commands: Array[Dictionary] = []
	var points := int(command_state.get("points", 0))
	for command_id_value in COMMAND_ORDER:
		var command_id := str(command_id_value)
		var definition: Dictionary = command_catalog.get(command_id, {})
		if definition.is_empty():
			continue
		var cooldown := float(command_state.get("cooldowns", {}).get(command_id, 0.0))
		var cost := int(definition.get("command_point_cost", 0))
		commands.append({
			"id": command_id,
			"label": str(definition.get("display_name", command_id)),
			"target_type": str(definition.get("target_type", "")),
			"cost": cost,
			"cooldown_seconds": cooldown,
			"enabled": cooldown <= 0.0 and points >= cost
		})
	var goals: Array = battle_plan.get("enemy_goals", []).duplicate()
	return {
		"schema_version": 1,
		"source": "product_runtime",
		"objective_room_ids": goals,
		"objective_label": _objective_label(goals),
		"active_route": route,
		"active_route_label": _route_label(route),
		"defense_segments": battle_plan.get("defense_segments", []).duplicate(true),
		"threats": threats,
		"threat_panel_visible": not threats.is_empty(),
		"commands": commands,
		"command_points": points,
		"command_points_max": int(command_state.get("max_points", 0)),
		"boss_status_preserved": bool(runtime_state.get("boss_status_preserved", true)),
		"heart_status_preserved": bool(runtime_state.get("heart_status_preserved", true)),
		"duo_status_preserved": bool(runtime_state.get("duo_status_preserved", true)),
		"speed": float(runtime_state.get("speed", 1.0)),
		"paused": bool(runtime_state.get("paused", false)),
		"developer_copy": []
	}


static func build_result(result_summary: Dictionary, ledger_summary: Dictionary, progression: Dictionary = {}) -> Dictionary:
	var metrics: Dictionary = result_summary.get("metrics", {})
	var gold_stolen := maxi(
		int(ledger_summary.get("gold_stolen", 0)),
		int(metrics.get("treasure_gold_stolen", 0))
	)
	var throne_damage := int(ledger_summary.get("throne_damage", 0))
	var breach_progress := float(ledger_summary.get("breach_progress", 0.0))
	var cause: Dictionary
	if bool(result_summary.get("management_only", false)):
		cause = {"id": "preparation_confirmed", "label": "핵심 결과 · 최종 준비 확정"}
	elif bool(result_summary.get("outpost_battle", false)):
		cause = {
			"id": "outpost_held" if bool(result_summary.get("win", false)) else "outpost_withdrawal",
			"label": "핵심 원인 · 전초기지 방어" if bool(result_summary.get("win", false)) else "핵심 원인 · 전초기지 후퇴"
		}
	else:
		cause = _primary_cause(
			bool(result_summary.get("win", false)),
			gold_stolen,
			throne_damage,
			breach_progress,
			metrics
		)
	return {
		"schema_version": 1,
		"source": "product_runtime",
		"win": bool(result_summary.get("win", false)),
		"primary_cause_id": str(cause.get("id", "")),
		"primary_cause_label": str(cause.get("label", "")),
		"gold_stolen": gold_stolen,
		"throne_damage": throne_damage,
		"breach_progress": breach_progress,
		"facility_contribution": ledger_summary.get("facility_contribution", {}).duplicate(true),
		"command_contribution": ledger_summary.get("command_contribution", {}).duplicate(true),
		"growth": result_summary.get("growth", []).duplicate(true),
		"rewards": progression.get("rewards", {}).duplicate(true),
		"story_preserved": bool(progression.get("story_preserved", true)),
		"meta_progress_preserved": bool(progression.get("meta_progress_preserved", true)),
		"ending_preserved": bool(progression.get("ending_preserved", true)),
		"next_day_preserved": bool(progression.get("next_day_preserved", true)),
		"developer_copy": []
	}


static func command(model: Dictionary, command_id: String) -> Dictionary:
	for value in model.get("commands", []):
		if value is Dictionary and str(value.get("id", "")) == command_id:
			return value
	return {}


static func layout_contract(viewport_size: Vector2) -> Dictionary:
	if viewport_size.y > viewport_size.x or viewport_size.x / maxf(1.0, viewport_size.y) < LANDSCAPE_MIN_ASPECT:
		return {
			"mode": "orientation_notice",
			"orientation_notice": Rect2(Vector2.ZERO, viewport_size)
		}
	var scale_factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	return {
		"mode": "touch_landscape" if viewport_size.x < 1000.0 else "desktop",
		"tactical_status": _scaled(Rect2(840, 92, 660, 112), scale_factor, offset),
		"battlefield": _scaled(Rect2(360, 220, 1140, 646), scale_factor, offset),
		"commands": _scaled(Rect2(560, 884, 860, 142), scale_factor, offset),
		"speed_pause": _scaled(Rect2(1438, 884, 74, 142), scale_factor, offset)
	}


static func _objective_label(goals: Array) -> String:
	if goals.is_empty():
		return "목표 미확인"
	return "방어 목표 · %s" % " / ".join(goals.map(func(value): return str(value)))


static func _route_label(route: Array) -> String:
	if route.is_empty():
		return "활성 경로 없음"
	return "활성 경로 · %s" % " → ".join(route.map(func(value): return str(value)))


static func _primary_cause(
	win: bool,
	gold_stolen: int,
	throne_damage: int,
	breach_progress: float,
	metrics: Dictionary
) -> Dictionary:
	if throne_damage > 0:
		return {
			"id": "throne_damage",
			"label": "핵심 원인 · 왕좌 피해 %d" % throne_damage
		}
	if breach_progress > 0.0:
		return {
			"id": "breach",
			"label": "핵심 원인 · 방어선 돌파 %.0f%%" % (breach_progress * 100.0)
		}
	if gold_stolen > 0:
		return {
			"id": "treasure_loss",
			"label": "핵심 원인 · 보물 손실 %d" % gold_stolen
		}
	if win:
		if metrics.is_empty():
			return {
				"id": "defense_held",
				"label": "핵심 원인 · 방어 성공"
			}
		var alive := int(metrics.get("alive_monsters", 0))
		var total := int(metrics.get("total_monsters", 0))
		return {
			"id": "defense_held",
			"label": "핵심 원인 · 방어선 유지 %d/%d" % [alive, total]
		}
	return {
		"id": "combat_collapse",
		"label": "핵심 원인 · 수비 전력 붕괴"
	}


static func _scaled(rect: Rect2, scale_factor: float, offset: Vector2) -> Rect2:
	return Rect2(offset + rect.position * scale_factor, rect.size * scale_factor)
