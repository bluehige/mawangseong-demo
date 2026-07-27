class_name V122ManagementViewModel
extends RefCounted

const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const LANDSCAPE_MIN_ASPECT := 1.45

const ACTIONS := {
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
	"start_combat": {
		"label": "전투 시작",
		"callback": "_start_combat",
		"area": "primary",
		"tooltip": "현재 성·시설·몬스터 배치를 확정하고 전투를 시작합니다."
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
	for action_id in ["build", "monsters", "start_combat", "chronicle"]:
		actions.append(_action(action_id, true, true))

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
		"actions": actions,
		"context_drawer_visible": _has_context_action(actions),
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
	var workspace_height := 740 if touch_landscape else 760
	var map_rect := Rect2(330, 92, 1170, workspace_height)
	return {
		"mode": "touch_landscape" if touch_landscape else "desktop",
		"map": _scaled(map_rect, scale_factor, offset),
		"room_list": _scaled(Rect2(16, 92, 300, 420), scale_factor, offset),
		"context_drawer": _scaled(Rect2(1518, 92, 370, workspace_height), scale_factor, offset),
		"primary_actions": _scaled(Rect2(98, 842 if touch_landscape else 888, 1725, 210 if touch_landscape else 124), scale_factor, offset)
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


static func _pending_reason(root: Node) -> String:
	if _call_bool(root, "_early_specialization_required_for_current_day"):
		return "specialization"
	if _call_bool(root, "_campaign_raid_choice_pending"):
		return "raid_choice"
	if _call_bool(root, "_update4_required_choice_pending"):
		return "council_choice"
	if _call_bool(root, "_campaign_final_declaration_pending"):
		return "final_declaration"
	return ""


static func _has_context_action(actions: Array[Dictionary]) -> bool:
	for value in actions:
		if str(value.get("area", "")) == "context" and bool(value.get("visible", false)):
			return true
	return false


static func _scaled(rect: Rect2, scale_factor: float, offset: Vector2) -> Rect2:
	return Rect2(offset + rect.position * scale_factor, rect.size * scale_factor)
