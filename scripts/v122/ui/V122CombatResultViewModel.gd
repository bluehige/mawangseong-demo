class_name V122CombatResultViewModel
extends RefCounted

const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const LANDSCAPE_MIN_ASPECT := 1.45
const COMMAND_ORDER := ["rally", "focus", "activate_facility", "emergency_fallback"]
const ROOM_LABELS := {
	"outside_approach": "정문 외곽",
	"outside_approach_b": "후문 외곽",
	"entrance": "정문 입구",
	"service_entrance": "서비스 침입 균열",
	"spike_corridor": "함정 복도",
	"barracks": "병영",
	"recovery": "회복실",
	"treasure": "보물방",
	"heart_chamber": "마왕성 심장실",
	"watch_post_01": "감시초소",
	"ward_core_01": "마력 수호핵",
	"elite_garrison_01": "최정예 주둔지",
	"slot_01": "건설 구역 1",
	"slot_02": "건설 구역 2",
	"slot_03": "건설 구역 3",
	"lane_a_rear": "정문 후방 방어선",
	"lane_b_front": "후문 전방 방어선",
	"lane_b_rear": "후문 후방 방어선",
	"lane_b_merge": "후문 합류 지점",
	"throne_antechamber": "왕좌 전실",
	"throne": "왕좌"
}


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
		var active: Dictionary = command_state.get("active_commands", {}).get(command_id, {})
		commands.append({
			"id": command_id,
			"label": str(definition.get("display_name", command_id)),
			"target_type": str(definition.get("target_type", "")),
			"cost": cost,
			"description": str(definition.get("description", "")),
			"cooldown_seconds": cooldown,
			"active_seconds": float(active.get("remaining_seconds", 0.0)),
			"active": not active.is_empty(),
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
		"throne_hp": int(runtime_state.get("throne_hp", 0)),
		"throne_hp_max": int(runtime_state.get("throne_hp_max", 0)),
		"defense_progress": clampf(float(runtime_state.get("defense_progress", 0.0)), 0.0, 1.0),
		"context_drawer_open": bool(runtime_state.get("context_drawer_open", false)),
		"pending_command_id": str(runtime_state.get("pending_command_id", "")),
		"pending_command_target": runtime_state.get("pending_command_target", {}).duplicate(true),
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
	var alive_monsters := int(metrics.get("alive_monsters", 0))
	var total_monsters := int(metrics.get("total_monsters", 0))
	var final_breach_segment := _final_breach_segment(metrics, ledger_summary)
	var facility_damage_count := _facility_damage_count(metrics, ledger_summary)
	var core_metrics: Array[Dictionary] = [
		{
			"id": "throne_damage",
			"label": "왕좌 피해",
			"value": "%d" % throne_damage
		},
		{
			"id": "monster_survival",
			"label": "몬스터 생존",
			"value": "%d / %d" % [alive_monsters, total_monsters]
		},
		{
			"id": "final_breach_segment",
			"label": "최종 돌파 구간",
			"value": final_breach_segment
		}
	]
	if bool(result_summary.get("management_only", false)):
		core_metrics = [
			{
				"id": "preparation_state",
				"label": "준비 상태",
				"value": "확정"
			},
			{
				"id": "placement_state",
				"label": "배치 · 지침",
				"value": "유지"
			},
			{
				"id": "next_schedule",
				"label": "다음 일정",
				"value": "DAY %02d" % maxi(1, int(metrics.get("next_day", int(metrics.get("day", 0)) + 1)))
			}
		]
	elif bool(result_summary.get("outpost_battle", false)):
		core_metrics = [
			{
				"id": "outpost_hp",
				"label": "깃발 내구도",
				"value": "%d / %d" % [int(metrics.get("ending_hp", 0)), int(metrics.get("max_hp", 0))]
			},
			{
				"id": "outpost_duration",
				"label": "방어 시간",
				"value": "%.1f초" % float(metrics.get("duration_seconds", 0.0))
			},
			{
				"id": "outpost_retries",
				"label": "재도전",
				"value": "%d회" % int(metrics.get("retry_count", 0))
			}
		]
	var conditional_alerts: Array[Dictionary] = []
	if gold_stolen > 0:
		conditional_alerts.append({
			"id": "treasure_theft",
			"label": "탈취",
			"value": "금화 %d" % gold_stolen
		})
	if facility_damage_count > 0:
		conditional_alerts.append({
			"id": "facility_damage",
			"label": "시설 피해",
			"value": "%d곳" % facility_damage_count
		})
	var actions := _result_actions(result_summary)
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
	var decision_feedback := _decision_feedback(metrics)
	var retry_action_label := ""
	if not bool(result_summary.get("win", false)) and not bool(result_summary.get("management_only", false)) and not bool(result_summary.get("outpost_battle", false)):
		retry_action_label = _retry_action(metrics, gold_stolen, throne_damage, breach_progress, facility_damage_count)
	return {
		"schema_version": 1,
		"source": "product_runtime",
		"win": bool(result_summary.get("win", false)),
		"primary_cause_id": str(cause.get("id", "")),
		"primary_cause_label": str(cause.get("label", "")),
		"gold_stolen": gold_stolen,
		"throne_damage": throne_damage,
		"breach_progress": breach_progress,
		"core_metrics": core_metrics,
		"conditional_alerts": conditional_alerts,
		"decision_feedback": decision_feedback,
		"retry_action_label": retry_action_label,
		"actions": actions,
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


static func _retry_action(
	metrics: Dictionary,
	gold_stolen: int,
	throne_damage: int,
	breach_progress: float,
	facility_damage_count: int
) -> String:
	var alive_monsters := int(metrics.get("alive_monsters", 0))
	var total_monsters := int(metrics.get("total_monsters", 0))
	var decision_context: Dictionary = metrics.get("decision_context", {}) if metrics.get("decision_context", {}) is Dictionary else {}
	var directive_id := str(decision_context.get("directive_id", metrics.get("directive", "")))
	if gold_stolen > 0:
		return "다음 시도: 곱을 보물방 인접 통로에 배치하고 추격 지침을 유지하세요."
	if facility_damage_count > 0:
		return "다음 시도: 공병이 닿는 시설 앞 방에 방어자를 한 명 배치하세요."
	if total_monsters > 0 and alive_monsters <= 0:
		return "다음 시도: 한 명을 왕좌 전실에 남기고 생존 지침을 사용하세요."
	if directive_id == "all_out" and (throne_damage > 0 or breach_progress > 0.0):
		return "다음 시도: 전체 지침을 사수로 바꾸고 돌파 구간에 집결하세요."
	if throne_damage > 0 or breach_progress > 0.0:
		return "다음 시도: 최종 돌파 구간 바로 앞 방에 집결 지점을 지정하세요."
	return "다음 시도: 기여가 가장 낮았던 방의 배치와 지침을 하나씩 바꾸세요."


static func _decision_feedback(metrics: Dictionary) -> Dictionary:
	var context = metrics.get("decision_context", {})
	if not context is Dictionary:
		return {}
	var placements = context.get("monster_placements", [])
	var contributions = metrics.get("monster_contributions", {})
	if not placements is Array or placements.is_empty() or not contributions is Dictionary:
		return {}
	var selected: Dictionary = {}
	if int(context.get("day", 0)) == 1:
		for value in placements:
			if value is Dictionary and str(value.get("monster_id", "")) == "goblin":
				selected = value
				break
	var best_score := -1
	if selected.is_empty():
		for value in placements:
			if not value is Dictionary:
				continue
			var monster_id := str(value.get("monster_id", ""))
			var stats = contributions.get(monster_id, {})
			if not stats is Dictionary:
				continue
			var score := (
				int(stats.get("damage_dealt", 0))
				+ int(stats.get("damage_absorbed", 0))
				+ int(stats.get("facility_value", 0))
				+ int(stats.get("finishing_blows", 0)) * 20
			)
			if score > best_score:
				best_score = score
				selected = value
	if selected.is_empty():
		selected = placements.front()
	var monster_id := str(selected.get("monster_id", ""))
	var stats: Dictionary = (
		contributions.get(monster_id, {})
		if contributions.get(monster_id, {}) is Dictionary
		else {}
	)
	var impact_parts: Array[String] = []
	var damage_absorbed := int(stats.get("damage_absorbed", 0))
	var damage_dealt := int(stats.get("damage_dealt", 0))
	var finishing_blows := int(stats.get("finishing_blows", 0))
	var facility_value := int(stats.get("facility_value", 0))
	if damage_absorbed > 0:
		impact_parts.append("피해 %d 흡수" % damage_absorbed)
	if damage_dealt > 0:
		impact_parts.append("공격 %d" % damage_dealt)
	if finishing_blows > 0:
		impact_parts.append("마무리 %d회" % finishing_blows)
	if facility_value > 0:
		impact_parts.append("시설 지원 %d" % facility_value)
	if impact_parts.is_empty():
		impact_parts.append("교전 기록 없음")
	var room_id := str(selected.get("room_id", ""))
	var defense_zone_id := str(selected.get("defense_zone_id", ""))
	var strategy_label := "배치 결과"
	var destination_label := str(selected.get("room_name", room_id))
	if int(context.get("day", 0)) == 1 and monster_id == "goblin":
		var rear_choice := (
			defense_zone_id in ["zone_a_rear", "zone_throne_antechamber"]
			or room_id in ["path_a_front_rear", "lane_a_rear", "recovery", "throne_antechamber"]
		)
		strategy_label = "후방 화력" if rear_choice else "전방 봉쇄"
		destination_label = "후열" if rear_choice else "전열"
	var directive_name := str(context.get("directive_name", "기본"))
	var placement_label := "%s → %s" % [
		str(selected.get("monster_name", monster_id)),
		destination_label
	]
	return {
		"id": "placement_impact",
		"strategy_label": strategy_label,
		"placement_label": placement_label,
		"directive_label": directive_name,
		"impact_label": " · ".join(impact_parts),
		"summary": "%s · %s · %s · %s" % [
			strategy_label,
			placement_label,
			directive_name,
			" · ".join(impact_parts)
		]
	}


static func _final_breach_segment(metrics: Dictionary, ledger_summary: Dictionary) -> String:
	var explicit_segment := str(ledger_summary.get("final_breach_segment", "")).strip_edges()
	if explicit_segment == "":
		explicit_segment = str(metrics.get("final_breach_segment", "")).strip_edges()
	if explicit_segment != "":
		return explicit_segment
	var events: Array = ledger_summary.get("events", [])
	for value in events:
		if value is Dictionary and str(value.get("type", "")) == "throne_damage":
			return "왕좌"
	for event_index in range(events.size() - 1, -1, -1):
		var value = events[event_index]
		if not value is Dictionary:
			continue
		var event: Dictionary = value
		if str(event.get("type", "")) != "breach_progress":
			continue
		var from_room := str(event.get("from_room_name", event.get("from_room_id", ""))).strip_edges()
		var to_room := str(
			event.get(
				"to_room_name",
				event.get("to_room_id", event.get("room_name", event.get("room_id", "")))
			)
		).strip_edges()
		if from_room != "" and to_room != "":
			return "%s → %s" % [_room_segment_label(from_room), _room_segment_label(to_room)]
		if to_room != "":
			return _room_segment_label(to_room)
	for value in events:
		if value is Dictionary and str(value.get("type", "")) == "treasure_stolen":
			return "보물방"
	return "돌파 없음"


static func _facility_damage_count(metrics: Dictionary, ledger_summary: Dictionary) -> int:
	var count := maxi(
		int(metrics.get("facility_disables", 0)),
		int(metrics.get("facility_damage_count", 0))
	)
	count = maxi(count, int(ledger_summary.get("facility_damage_count", 0)))
	if count > 0:
		return count
	var damaged_ids = metrics.get("damaged_facility_ids", [])
	if damaged_ids is Array:
		return damaged_ids.size()
	return 0


static func _result_actions(result_summary: Dictionary) -> Array[Dictionary]:
	if bool(result_summary.get("management_only", false)) or bool(result_summary.get("outpost_battle", false)):
		return [{
			"id": "continue",
			"label": "결산 확인",
			"priority": "primary",
			"callback": "_continue_from_result"
		}]
	if bool(result_summary.get("win", false)):
		return [{
			"id": "continue",
			"label": "다음 DAY 진행",
			"priority": "primary",
			"callback": "_continue_from_result"
		}]
	return [
		{
			"id": "edit_placement",
			"label": "배치 수정",
			"priority": "primary",
			"callback": "_edit_placement_from_result"
		},
		{
			"id": "retry_same_placement",
			"label": "동일 배치 재도전",
			"priority": "secondary",
			"callback": "_retry_same_placement_from_result",
			"countdown_seconds": 3.0
		}
	]


static func _room_segment_label(room_id: String) -> String:
	var normalized := room_id.strip_edges()
	if normalized == "":
		return "미확인 구역"
	if ROOM_LABELS.has(normalized):
		return str(ROOM_LABELS[normalized])
	if normalized.begins_with("path_") or normalized.begins_with("candidate_"):
		return "연결 통로"
	return "미확인 구역"


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
	var touch_landscape := viewport_size.x < 1000.0
	var compact_desktop := not touch_landscape and viewport_size.x < 1440.0
	var design_contract := design_layout_contract(compact_desktop, touch_landscape)
	var scaled_contract: Dictionary = {"mode": str(design_contract.get("mode", ""))}
	for key in design_contract.keys():
		if key == "mode":
			continue
		var value = design_contract[key]
		scaled_contract[key] = _scaled(value, scale_factor, offset) if value is Rect2 else value
	return scaled_contract


static func design_layout_contract(compact: bool = false, touch_landscape: bool = false) -> Dictionary:
	if touch_landscape:
		return {
			"mode": "touch_landscape",
			"battlefield": Rect2(20, 170, 1380, 640),
			"tactical_status": Rect2(20, 20, 620, 130),
			"throne_status": Rect2(20, 20, 620, 130),
			"threat": Rect2(660, 20, 700, 130),
			"commands": Rect2(100, 830, 1300, 220),
			"speed_pause": Rect2(1420, 654, 260, 396),
			"unit_inspector": Rect2(820, 120, 1068, 620),
			"context_drawer": Rect2(820, 120, 1068, 900)
		}
	if compact:
		return {
			"mode": "compact_desktop",
			"battlefield": Rect2(12, 88, 1896, 816),
			"tactical_status": Rect2(12, 8, 600, 68),
			"throne_status": Rect2(12, 8, 600, 68),
			"threat": Rect2(624, 8, 744, 68),
			"tactics": Rect2(12, 916, 374, 148),
			"commands": Rect2(398, 916, 1040, 148),
			"speed_pause": Rect2(1450, 916, 118, 148),
			"special_actions": Rect2(1580, 916, 328, 148),
			"unit_inspector": Rect2(1526, 88, 382, 290),
			"context_drawer": Rect2(1518, 88, 390, 804)
		}
	return {
		"mode": "desktop",
		"battlefield": Rect2(16, 82, 1888, 850),
		"tactical_status": Rect2(16, 12, 520, 58),
		"throne_status": Rect2(16, 12, 520, 58),
		"threat": Rect2(548, 12, 620, 58),
		"tactics": Rect2(16, 944, 310, 120),
		"commands": Rect2(338, 944, 912, 120),
		"speed_pause": Rect2(1262, 944, 112, 120),
		"special_actions": Rect2(1386, 944, 518, 120),
		"unit_inspector": Rect2(1534, 82, 370, 270),
		"context_drawer": Rect2(1534, 82, 370, 824)
	}


static func _objective_label(goals: Array) -> String:
	if goals.is_empty():
		return "목표 미확인"
	return "방어 목표 · %s" % " / ".join(goals.map(func(value): return _room_segment_label(str(value))))


static func _route_label(route: Array) -> String:
	if route.is_empty():
		return "활성 경로 없음"
	return "활성 경로 · %s" % " → ".join(route.map(func(value): return _room_segment_label(str(value))))


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
