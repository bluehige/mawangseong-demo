class_name V122ManagementViewModel
extends RefCounted

const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const LANDSCAPE_MIN_ASPECT := 1.45

const ACTIONS := {
	"intrusion_brief": {
		"label": "침입 정보",
		"callback": "_open_intrusion_brief",
		"area": "primary",
		"tooltip": "이번 방어에 실제로 투입되는 적 편성과 경로를 다시 확인합니다."
	},
	"build": {
		"label": "건설",
		"callback": "_build_selected_slot",
		"area": "primary",
		"tooltip": "선택한 빈 방에 제품 시설을 건설합니다."
	},
	"monsters": {
		"label": "몬스터",
		"callback": "_open_monster_screen",
		"area": "primary",
		"tooltip": "전체 보유 몬스터의 성장·진화·전술 특화를 관리합니다."
	},
	"context": {
		"label": "전술 · 상세",
		"callback": "_open_management_context_drawer",
		"area": "primary",
		"tooltip": "선택 방 지침과 원정·전선 보조 기능을 한 드로어에서 확인합니다."
	},
	"undo": {
		"label": "되돌리기",
		"callback": "_undo_last_management_placement",
		"area": "primary",
		"tooltip": "방금 적용한 시설 또는 몬스터 배치를 되돌립니다."
	},
	"start_combat": {
		"label": "방어 시작",
		"callback": "_request_combat_start",
		"area": "primary",
		"tooltip": "현재 성·시설·몬스터 배치를 3초 뒤 확정하고 방어를 시작합니다."
	},
	"chronicle": {
		"label": "전선 연대기",
		"callback": "_open_chronicle",
		"area": "context",
		"tooltip": "전선·심장 숙련, 라이벌 관계, 합동 기억, 최근 회차와 후일담을 확인합니다."
	},
	"duo_loadout": {
		"label": "합동기 편성 변경",
		"callback": "_open_update3_duo_link_loadout",
		"area": "context",
		"tooltip": "전투 사이에 장착 합동기를 변경합니다."
	},
	"raid": {
		"label": "원정",
		"callback": "_open_raid_screen",
		"area": "context",
		"tooltip": "원정 계획과 출전 몬스터를 확정합니다."
	},
	"outpost": {
		"label": "전초기지",
		"callback": "_open_update4_outpost_management",
		"area": "context",
		"tooltip": "전초기지 시설과 지역 방어 상태를 관리합니다."
	},
	"upper_floor": {
		"label": "상층 왕성",
		"callback": "_open_update4_upper_floor",
		"area": "context",
		"tooltip": "상층 배치·시설·왕관 목표를 관리합니다."
	}
}


static func build(root: Node) -> Dictionary:
	var actions: Array[Dictionary] = []
	for action_id in ["intrusion_brief", "monsters", "context"]:
		actions.append(_action(action_id, true, true))
	var undo_state := _dictionary_property(root, "management_undo")
	actions.append(_action("undo", true, not undo_state.is_empty()))
	var start_state: Dictionary = root.call("_management_start_state") if root.has_method("_management_start_state") else {"can_start": true, "blocked_reason": ""}
	actions.append(_action("start_combat", true, bool(start_state.get("can_start", false))))
	actions.append(_action("chronicle", true, true))

	if _call_bool(root, "_update3_duo_loadout_edit_available"):
		actions.append(_action("duo_loadout", true, true))
	if _call_bool(root, "_raid_unlocked"):
		actions.append(_action("raid", true, not _call_bool(root, "_campaign_raid_choice_pending")))
	if _call_bool(root, "_update4_council_mode_active"):
		var active_run: Dictionary = _dictionary_property(root, "update4_active_run")
		var outpost: Dictionary = active_run.get("outpost", {})
		var upper_floor: Dictionary = active_run.get("upper_floor", {})
		actions.append(_action("outpost", true, str(outpost.get("type_id", "")) != ""))
		actions.append(_action("upper_floor", true, bool(upper_floor.get("unlocked", false))))

	var selected_room := str(root.get("selected_room"))
	var room_name := selected_room
	if selected_room != "" and root.has_method("display_name_for_instance"):
		room_name = str(root.call("display_name_for_instance", selected_room))
	var pending_reason := _pending_reason(root)
	return {
		"schema_version": 1,
		"workspace": {
			"map_is_primary": true,
			"selected_room_id": selected_room,
			"selected_room_name": room_name,
			"pending_reason": pending_reason
		},
		"start": start_state,
		"actions": actions,
		"context_drawer_visible": _bool_property(root, "management_context_drawer_open") or pending_reason != "",
		"developer_copy": [],
		"source": "product_runtime"
	}


static func action(model: Dictionary, action_id: String) -> Dictionary:
	for value in model.get("actions", []):
		if value is Dictionary and str(value.get("id", "")) == action_id:
			return value
	return {}


static func validate_entrypoints(root: Node, model: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for value in model.get("actions", []):
		if not value is Dictionary:
			errors.append("action_not_dictionary")
			continue
		var action_id := str(value.get("id", ""))
		var callback := str(value.get("callback", ""))
		if action_id == "" or callback == "":
			errors.append("missing_action_contract")
		elif not root.has_method(callback):
			errors.append("%s:%s" % [action_id, callback])
	return errors


static func layout_contract(viewport_size: Vector2) -> Dictionary:
	if viewport_size.y > viewport_size.x or viewport_size.x / maxf(1.0, viewport_size.y) < LANDSCAPE_MIN_ASPECT:
		return {
			"mode": "orientation_notice",
			"orientation_notice": Rect2(Vector2.ZERO, viewport_size)
		}
	var scale_factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	var touch_landscape := viewport_size.x < 1000.0
	var compact := viewport_size.x < 1440.0 and not touch_landscape
	var map_rect := Rect2(170, 210, 1580, 360) if touch_landscape else (
		Rect2(16, 72, 1888, 732) if compact else Rect2(24, 80, 1872, 690)
	)
	var roster_dock_rect := Rect2(98, 586, 1725, 276) if touch_landscape else (
		Rect2(16, 820, 1888, 86) if compact else Rect2(24, 786, 1872, 110)
	)
	var drawer_rect := Rect2(820, 92, 1068, 770) if touch_landscape else (
		Rect2(1532, 80, 372, 824) if compact else Rect2(1524, 88, 372, 806)
	)
	var primary_rect := Rect2(98, 878, 1725, 174) if touch_landscape else (
		Rect2(16, 920, 1888, 112) if compact else Rect2(24, 912, 1872, 132)
	)
	return {
		"mode": "touch_landscape" if touch_landscape else ("compact" if compact else "standard"),
		"full_canvas": true,
		"world_canvas": _scaled(Rect2(Vector2.ZERO, DESIGN_SIZE), scale_factor, offset),
		"map": _scaled(map_rect, scale_factor, offset),
		"card_rail": _scaled(roster_dock_rect, scale_factor, offset),
		"monster_roster": _scaled(roster_dock_rect, scale_factor, offset),
		"context_drawer": _scaled(drawer_rect, scale_factor, offset),
		"primary_actions": _scaled(primary_rect, scale_factor, offset)
	}


static func _action(action_id: String, visible: bool, enabled: bool) -> Dictionary:
	var result: Dictionary = ACTIONS.get(action_id, {}).duplicate(true)
	result["id"] = action_id
	result["visible"] = visible
	result["enabled"] = enabled
	return result


static func _call_bool(root: Node, method_name: String) -> bool:
	return root.has_method(method_name) and bool(root.call(method_name))


static func _dictionary_property(root: Node, property_name: String) -> Dictionary:
	var value = root.get(property_name)
	return value if value is Dictionary else {}


static func _bool_property(root: Node, property_name: String) -> bool:
	return root.get(property_name) == true


static func _pending_reason(root: Node) -> String:
	if _call_bool(root, "_campaign_final_declaration_pending"):
		return "final_declaration"
	if _call_bool(root, "_early_specialization_required_for_current_day"):
		return "specialization"
	if _call_bool(root, "_campaign_raid_choice_pending"):
		return "raid_choice"
	if _call_bool(root, "_update4_required_choice_pending"):
		return "council_choice"
	return ""


static func _has_context_action(actions: Array[Dictionary]) -> bool:
	for value in actions:
		if str(value.get("area", "")) == "context" and bool(value.get("visible", false)):
			return true
	return false


static func _scaled(rect: Rect2, scale_factor: float, offset: Vector2) -> Rect2:
	return Rect2(offset + rect.position * scale_factor, rect.size * scale_factor)
