extends Node
const Controller = preload("res://scripts/game/CombatSceneController.gd")
var checks := 0
var failed := false
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)
func _ready() -> void:
	var controller = Controller.new()
	var plan := {"defense_zones":[
		{"zone_id":"front_a","lane_id":"a","anchor_room_id":"a_front"},
		{"zone_id":"rear_a","lane_id":"a","anchor_room_id":"a_rear"},
		{"zone_id":"front_b","lane_id":"b","anchor_room_id":"b_front"},
		{"zone_id":"rear_b","lane_id":"b","anchor_room_id":"b_rear"},
		{"zone_id":"merge","lane_id":"merge","anchor_room_id":"merge_room"}],
		"facility_slots":[{"room_id":"barracks","linked_zone_ids":["front_a"]}],
		"lane_routes":{"a":["entry","a_front","a_corridor","a_rear","merge_room","tail","throne"]}}
	plan.lane_routes["b"] = plan.lane_routes.a.duplicate()
	var before := JSON.stringify(plan)
	var mapping: Dictionary = controller._v122_room_to_zone_map(plan)
	check(mapping.entry == "front_a", "동일 진입로 별칭이 입구를 왕좌 합류 구역으로 바꾸지 않음")
	check(mapping.a_corridor == "front_a", "동일 진입로 복도에서 기존 전방 시설 범위 유지")
	check(mapping.a_rear == "rear_a", "후방 기준 방 유지")
	check(mapping.barracks == "front_a", "시설 지정 구역 유지")
	check(mapping.tail == "merge" and mapping.throne == "merge", "실제 합류 기준점 이후 왕좌 범위 유지")
	check(JSON.stringify(plan) == before, "범위 조회가 전투 계획을 변경하지 않음")
	plan.lane_routes.b = ["entry","b_front","b_corridor","b_rear","merge_room","tail","throne"]
	mapping = controller._v122_room_to_zone_map(plan)
	check(mapping.entry != "merge", "갈림길 앞 공통 입구를 왕좌 구역으로 오인하지 않음")
	check(mapping.a_corridor == "front_a" and mapping.b_corridor == "front_b", "두 실제 전선의 시설 범위를 분리")
	check(mapping.tail == "merge" and mapping.throne == "merge", "두 전선 합류 뒤 왕좌 범위 유지")
	var text_model = preload("res://scripts/ui/FacilityEffectText.gd")
	var definition := {"effect_summary":"체력 770 / 몬스터 7명 배치. 공격 +25%."}
	var summary: String = text_model.for_topology(definition,"barracks",plan)
	check(summary.contains("체력 770 / 몬스터 7명") and summary.contains("공격 +10%") and summary.contains("받는 피해 -8%") and not summary.contains("25%"), "건설 검토가 실제 구역 효과와 성 단계 체력을 표시")
	check(text_model.for_topology(definition,"barracks",{}) == definition.effect_summary, "구역 시설이 없는 기존 지도 설명 보존")
	var watch: String = text_model.for_topology({},"watch_post",plan)
	check(watch.contains("적 이동 -18%") and watch.contains("같은 전선") and watch.contains("적이 받는 피해 +12%"), "감시 범위·수치가 실제 효과 카탈로그와 일치")
	check(text_model.for_topology({}, "recovery", plan, 1.5).contains("초당 12.0"), "성 단계 회복 배율을 실제 전투와 동일하게 표시")
	print("UIUX_FACILITY_ROUTE_SCOPE_TEST: %s (%d)" % ["FAIL" if failed else "PASS",checks])
	get_tree().quit(1 if failed else 0)
