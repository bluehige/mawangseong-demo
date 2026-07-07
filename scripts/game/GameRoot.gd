extends Node2D

const Constants = preload("res://scripts/core/Constants.gd")
const RoomGraphScript = preload("res://scripts/map/RoomGraph.gd")
const ModuleGraphScript = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")
const TargetingService = preload("res://scripts/combat/TargetingService.gd")
const DamageService = preload("res://scripts/combat/DamageService.gd")
const DirectiveManager = preload("res://scripts/combat/DirectiveManager.gd")
const UnitActorScript = preload("res://scripts/units/Unit.gd")
const HUDControllerScript = preload("res://scripts/ui/HUDController.gd")
const ManagementSceneControllerScript = preload("res://scripts/game/ManagementSceneController.gd")
const CombatSceneControllerScript = preload("res://scripts/game/CombatSceneController.gd")
const OnboardingFlowScript = preload("res://scripts/systems/tutorial/OnboardingFlow.gd")
const TutorialManagerScript = preload("res://scripts/systems/tutorial/TutorialManager.gd")
const DungeonRendererScript = preload("res://scripts/map/DungeonRenderer.gd")
const QuarterDungeonRendererScript = preload("res://scripts/dungeon_quarter/QuarterDungeonRenderer.gd")
const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const IsoMathScript = preload("res://scripts/dungeon_quarter/IsoMath.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const UI_FONT = UIFontScript.BODY_FONT

const FACILITY_CHOICES = ["barracks", "treasure", "recovery", "watch_post", "build_slot"]
const UNIQUE_FACILITIES = ["treasure", "recovery"]
const LOCKED_FACILITY_ROOMS = ["entrance", "spike_corridor", "throne"]
const COMBAT_ZOOM_MIN = 0.78
const COMBAT_ZOOM_MAX = 1.85
const COMBAT_ZOOM_STEP = 1.12
const COMBAT_CAMERA_HOME = Vector2(960, 540)
const REQUIRED_MAIN_ROUTE_FROM = "entrance"
const REQUIRED_MAIN_ROUTE_TO = "throne"
const REQUIRED_ROUTE_REPAIR_MAX_STEPS = 16
const SYSTEM_REQUIRED_PATH_PREFIX = "system_required_path"
const SYSTEM_REQUIRED_PATH_GRID_ID = "SYSTEM_REQUIRED_ROUTE"
const USER_AUTHORED_PATH_PREFIX = "user_path"
const USER_AUTHORED_PATH_GRID_ID = "USER_AUTHORED_PATH"
const ONBOARDING_OPENING_TRIGGERS = [
	"opening_start",
	"after_narration",
	"after_player",
	"after_bati",
	"goldin_intro",
	"throne_reveal",
	"opening_end"
]
const ONBOARDING_ACTION_NONE = ""
const ONBOARDING_ACTION_DAY1_MANAGEMENT = "day1_management"
const ONBOARDING_SCENE_BASE = "res://assets/ui/onboarding/scenes/"
const ONBOARDING_SCENE_ILLUSTRATIONS = {
	"default": ONBOARDING_SCENE_BASE + "scene_demon_castle_dialogue.png",
	"LV02_OPENING_CUTSCENE": ONBOARDING_SCENE_BASE + "scene_demon_castle_dialogue.png"
}

var graph = null
var use_quarter_module_map := true
var quarter_layout_id: String = ""
var map_editor_active := false
var map_editor_layout: Dictionary = {}
var map_editor_status: String = ""
var map_editor_errors: Array = []
var map_editor_path_candidate_index := 0
var wave_manager = WaveManagerScript.new()
var hud
var management_scene
var combat_scene
var onboarding_flow = OnboardingFlowScript.new()
var tutorial_manager = TutorialManagerScript.new()
var onboarding_enabled := false
var onboarding_stage_id: String = "LV00_TITLE_BOOT"
var onboarding_dialogue_queue: Array = []
var onboarding_dialogue_index := 0
var onboarding_dialogue_return_screen: String = Constants.SCREEN_MANAGEMENT
var onboarding_dialogue_complete_action: String = ONBOARDING_ACTION_NONE
var onboarding_seen_dialogue_ids: Dictionary = {}
var onboarding_name_input: LineEdit = null
var onboarding_bati_comment_label: Label = null
var onboarding_boss_hp_thresholds: Dictionary = {}
var onboarding_treasure_stolen_this_day := false
var tutorial_gate_enabled := true
var tutorial_targets: Dictionary = {}
var dungeon_renderer
var quarter_renderer

var rooms: Dictionary = {}
var current_screen: String = Constants.SCREEN_MANAGEMENT
var selected_room: String = "entrance"
var selected_monster_id: String = "slime"
var selected_unit: Node = null

var global_directive: String = Constants.DIRECTIVE_DEFENSE
var room_directives: Dictionary = {}
var monster_roster: Dictionary = {}
var logs: Array[String] = []

var unit_root: Node2D
var effect_root: Node2D
var ui_layer: CanvasLayer
var combat_camera: Camera2D
var combat_time: float = 0.0
var combat_speed: float = 1.0
var combat_paused: bool = false
var combat_view_zoom: float = 1.0
var trap_cooldown: float = 0.0
var spawned_count: int = 0
var result_summary: Dictionary = {}
var rewards_pending: Dictionary = {}
var thief_steal_timers: Dictionary = {}

var monster_units: Array = []
var enemy_units: Array = []

var dragging_monster_id: String = ""
var drag_monster_position := Vector2.ZERO
var drag_start_position := Vector2.ZERO
var drag_hover_room: String = ""
var monster_drag_texture_cache: Dictionary = {}

var floor_texture: Texture2D
var wall_texture: Texture2D
var spike_texture: Texture2D
var dungeon_art: Dictionary = {}
var props: Dictionary = {}
var effect_textures: Dictionary = {}
var effect_frame_sets: Dictionary = {}

var debug_show_quarter_module_overlay := false
var debug_show_active_overlay := false
var debug_show_socket_overlay := false
var debug_show_walkable_overlay := false
var debug_show_floor_mask_overlay := false
var debug_show_room_id_overlay := false
var debug_show_blocked_overlay := false
var debug_show_cursor_cell := false
var debug_show_path_overlay := false

func _ready() -> void:
	randomize()
	RenderingServer.set_default_clear_color(Color("#07050b"))
	DataRegistry.load_all()
	GameState.reset()
	rooms = DataRegistry.rooms.duplicate(true)
	_init_room_facilities()
	_setup_dungeon_graph()
	_init_roster()
	_init_room_directives()
	_load_textures()
	_create_layers()
	_create_controllers()
	SignalBus.log_added.connect(_on_log_added)
	SignalBus.tutorial_action.connect(_on_tutorial_action)
	onboarding_enabled = onboarding_flow.load()
	if onboarding_enabled:
		tutorial_manager.setup(onboarding_flow.data.get("tutorial_steps", []))
		_onboarding_set_stage("LV00_TITLE_BOOT")
		_set_screen(Constants.SCREEN_TITLE)
	else:
		_set_screen(Constants.SCREEN_MANAGEMENT)
	set_process_input(true)

func _physics_process(delta: float) -> void:
	combat_scene.physics_process(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging_monster_id != "":
		_update_management_monster_drag(get_global_mouse_position())
		return
	if _onboarding_screen_blocks_map_input():
		if event is InputEventKey and event.pressed and not event.echo:
			_handle_key(event.keycode)
		return
	if event is InputEventMouseButton:
		var screen_point = event.position
		var point = _combat_screen_to_world(screen_point) if current_screen == Constants.SCREEN_COMBAT else get_global_mouse_position()
		if event.pressed and current_screen == Constants.SCREEN_COMBAT:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_adjust_combat_zoom(1, screen_point)
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_adjust_combat_zoom(-1, screen_point)
				return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if current_screen == Constants.SCREEN_MANAGEMENT:
				if event.pressed:
					if _start_management_monster_drag(point):
						return
					_handle_left_click(point, screen_point)
				elif dragging_monster_id != "":
					_finish_management_monster_drag(point)
				return
			if event.pressed:
				_handle_left_click(point, screen_point)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_handle_right_click(point, screen_point)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)

func _draw() -> void:
	if use_quarter_module_map and quarter_renderer != null:
		quarter_renderer.draw()
		if current_screen != Constants.SCREEN_COMBAT:
			dungeon_renderer.draw_roster_preview()
	else:
		dungeon_renderer.draw()
	_draw_management_drag_feedback()

func _init_roster() -> void:
	monster_roster = {
		"slime": {"level": 1, "exp": 0, "room": "entrance"},
		"goblin": {"level": 1, "exp": 0, "room": "barracks"},
		"imp": {"level": 1, "exp": 0, "room": "recovery"}
	}

func _init_room_directives() -> void:
	room_directives.clear()
	for room_id in rooms.keys():
		room_directives[room_id] = Constants.ROOM_DIRECTIVE_NONE

func _init_room_facilities() -> void:
	for room_id in rooms.keys():
		if rooms[room_id].has("facility_role"):
			continue
		rooms[room_id]["facility_role"] = _default_facility_role(room_id, rooms[room_id])

func _setup_dungeon_graph() -> void:
	var layout_data = _quarter_layout_for_graph()
	var can_use_quarter_map = use_quarter_module_map and not DataRegistry.quarter_modules.is_empty() and not layout_data.is_empty()
	if can_use_quarter_map:
		if quarter_layout_id == "" and not map_editor_active:
			quarter_layout_id = str(layout_data.get("template_id", DataRegistry.quarter_default_layout_id))
		graph = ModuleGraphScript.new()
		graph.setup_quarter(DataRegistry.quarter_modules, layout_data, rooms)
		var validation = graph.validation_summary()
		if not bool(validation.get("ok", false)) and not map_editor_active:
			push_warning("Quarter module map validation errors: %s" % str(validation.get("errors", [])))
	else:
		graph = RoomGraphScript.new()
		graph.setup(rooms)

func _quarter_layout_for_graph() -> Dictionary:
	if map_editor_active and not map_editor_layout.is_empty():
		return map_editor_layout.duplicate(true)
	return DataRegistry.quarter_layout(quarter_layout_id)

func set_quarter_layout(layout_id: String) -> bool:
	if not DataRegistry.quarter_layouts.has(layout_id):
		push_warning("Unknown quarter layout: %s" % layout_id)
		return false
	map_editor_active = false
	map_editor_layout.clear()
	map_editor_errors.clear()
	quarter_layout_id = layout_id
	_setup_dungeon_graph()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	queue_redraw()
	return true

func quarter_layout_display_name(layout_id: String) -> String:
	var layout = DataRegistry.quarter_layout(layout_id)
	return str(layout.get("display_name", layout_id))

func _select_quarter_layout(layout_id: String) -> void:
	if layout_id == quarter_layout_id:
		return
	if set_quarter_layout(layout_id):
		_log("맵 레이아웃을 %s로 전환했습니다." % quarter_layout_display_name(layout_id))
		_set_screen(Constants.SCREEN_MANAGEMENT)

func _open_map_editor() -> void:
	if not use_quarter_module_map:
		_log("쿼터뷰 맵에서만 편집할 수 있습니다.")
		return
	var source_layout = DataRegistry.quarter_layout(quarter_layout_id)
	if source_layout.is_empty():
		_log("편집할 맵 레이아웃이 없습니다.")
		return
	map_editor_active = true
	map_editor_layout = source_layout.duplicate(true)
	map_editor_layout["template_id"] = "%s_draft" % quarter_layout_id
	map_editor_status = "편집 중"
	map_editor_path_candidate_index = 0
	map_editor_errors.clear()
	_rebuild_map_editor_preview("편집 시작")
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _cancel_map_editor() -> void:
	if not map_editor_active:
		return
	map_editor_active = false
	map_editor_layout.clear()
	map_editor_status = ""
	map_editor_path_candidate_index = 0
	map_editor_errors.clear()
	_setup_dungeon_graph()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	_log("맵 편집을 취소했습니다.")
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _move_map_editor_room(delta: Vector2i) -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	var room_id = selected_room
	if _map_editor_selected_locked():
		map_editor_status = "고정 방은 이동할 수 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	map_editor_path_candidate_index = 0
	var candidate = map_editor_layout.duplicate(true)
	var moved = false
	var placed_modules: Array = candidate.get("placed_modules", [])
	for index in range(placed_modules.size()):
		var placed: Dictionary = placed_modules[index]
		if str(placed.get("instance_id", "")) != room_id:
			continue
		var origin_value: Array = placed.get("grid_origin", [0, 0])
		var origin = Vector2i(int(origin_value[0]), int(origin_value[1])) if origin_value.size() >= 2 else Vector2i.ZERO
		placed["grid_origin"] = [origin.x + delta.x, origin.y + delta.y]
		placed_modules[index] = placed
		moved = true
		break
	if not moved:
		map_editor_status = "선택 방을 레이아웃에서 찾을 수 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	candidate["placed_modules"] = placed_modules
	map_editor_layout = candidate
	_rebuild_map_editor_preview("이동")
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_disconnect_selected_room() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	map_editor_path_candidate_index = 0
	var connections: Array = map_editor_layout.get("connections", [])
	var kept_connections: Array = []
	var socket_states: Dictionary = map_editor_layout.get("socket_states", {}).duplicate(true)
	var removed_count = 0
	for connection in connections:
		var from_ref = str(connection.get("from", ""))
		var to_ref = str(connection.get("to", ""))
		if _map_editor_ref_instance(from_ref) == selected_room or _map_editor_ref_instance(to_ref) == selected_room:
			socket_states[from_ref] = "open_placeholder"
			socket_states[to_ref] = "open_placeholder"
			removed_count += 1
		else:
			kept_connections.append(connection)
	map_editor_layout["connections"] = kept_connections
	map_editor_layout["socket_states"] = socket_states
	_rebuild_map_editor_preview("연결 해제")
	if removed_count == 0:
		map_editor_status = "끊을 연결이 없습니다."
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_connect_adjacent_socket() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	map_editor_path_candidate_index = 0
	var candidate = _map_editor_first_adjacent_socket_pair()
	if candidate.is_empty():
		map_editor_status = "인접한 연결 후보가 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	var connections: Array = map_editor_layout.get("connections", []).duplicate(true)
	connections.append({"from": candidate["from"], "to": candidate["to"]})
	var socket_states: Dictionary = map_editor_layout.get("socket_states", {}).duplicate(true)
	socket_states[str(candidate["from"])] = "connected"
	socket_states[str(candidate["to"])] = "connected"
	map_editor_layout["connections"] = connections
	map_editor_layout["socket_states"] = socket_states
	_rebuild_map_editor_preview("인접 연결")
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_connect_selected_path_ends() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	var placed = _map_editor_placed_entry(selected_room)
	if placed.is_empty() or not _map_editor_entry_is_path(placed):
		map_editor_status = "선택한 항목은 양끝 연결 가능한 통로가 아닙니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	map_editor_path_candidate_index = 0
	var added := 0
	for other_id in _layout_instance_ids(map_editor_layout):
		if str(other_id) == selected_room:
			continue
		added += _layout_connect_adjacent_sockets_between_instances(map_editor_layout, selected_room, str(other_id), false)
	_rebuild_map_editor_preview("통로 양끝 연결")
	if added == 0:
		map_editor_status = "통로 양끝에 새로 연결할 인접 소켓이 없습니다."
	else:
		map_editor_status = "통로 양끝 연결 %d개. 저장 전 경로를 확인하세요." % added
		_log("통로 %s 양끝 연결 %d개." % [selected_room, added])
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_next_gap_path_candidate() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	var candidates = _map_editor_gap_path_candidates_for_selected()
	if candidates.is_empty():
		map_editor_path_candidate_index = 0
		map_editor_status = "배치 가능한 2칸 통로 후보가 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	map_editor_path_candidate_index = (map_editor_path_candidate_index + 1) % candidates.size()
	map_editor_status = _map_editor_path_candidate_line()
	queue_redraw()
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_select_gap_path_candidate_to(target_instance_id: String) -> bool:
	if not map_editor_active:
		return false
	if target_instance_id == "" or target_instance_id == selected_room:
		return false
	var candidates = _map_editor_gap_path_candidates_for_selected()
	var matching_indices: Array = []
	for index in range(candidates.size()):
		var candidate: Dictionary = candidates[index]
		if str(candidate.get("other_instance", "")) == target_instance_id:
			matching_indices.append(index)
	if matching_indices.is_empty():
		return false

	var current_index = _map_editor_clamped_path_candidate_index(candidates.size())
	var next_index = int(matching_indices[0])
	if str(candidates[current_index].get("other_instance", "")) == target_instance_id:
		for local_index in range(matching_indices.size()):
			if int(matching_indices[local_index]) != current_index:
				continue
			next_index = int(matching_indices[(local_index + 1) % matching_indices.size()])
			break
	map_editor_path_candidate_index = next_index
	var local_position = matching_indices.find(next_index) + 1
	map_editor_status = "목표 후보 %d/%d 선택: %s -> %s. 통로 배치로 확정하세요." % [
		local_position,
		matching_indices.size(),
		selected_room,
		target_instance_id
	]
	queue_redraw()
	_set_screen(Constants.SCREEN_MANAGEMENT)
	return true
	return false

func _map_editor_place_gap_path() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	var candidate = _map_editor_gap_path_candidate_for_selected()
	if candidate.is_empty():
		map_editor_status = "배치 가능한 2칸 통로 후보가 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	var path_id = _layout_next_user_path_id(map_editor_layout)
	var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
	var placed_modules: Array = map_editor_layout.get("placed_modules", []).duplicate(true)
	placed_modules.append({
		"instance_id": path_id,
		"module_id": str(candidate.get("module_id", "")),
		"grid_id": USER_AUTHORED_PATH_GRID_ID,
		"grid_origin": [origin.x, origin.y],
		"locked": false,
		"legacy_room_id": path_id,
		"user_authored": true
	})
	map_editor_layout["placed_modules"] = placed_modules
	selected_room = path_id
	map_editor_path_candidate_index = 0
	_rebuild_map_editor_preview("통로 배치")
	if map_editor_errors.is_empty():
		map_editor_status = "통로를 배치했습니다. 인접 연결로 방과 이어주세요."
	_log("수동 통로 %s 배치: %s -> %s." % [path_id, str(candidate.get("source_instance", "")), str(candidate.get("other_instance", ""))])
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _map_editor_delete_selected_path() -> void:
	if not map_editor_active:
		_open_map_editor()
		return
	var placed = _map_editor_placed_entry(selected_room)
	if placed.is_empty() or not _map_editor_entry_is_path(placed):
		map_editor_status = "선택한 항목은 삭제 가능한 통로가 아닙니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	var candidate_layout = map_editor_layout.duplicate(true)
	_layout_remove_path_instance(candidate_layout, selected_room)
	if bool(placed.get("system_required", false)) and not _layout_has_instance_path(candidate_layout, REQUIRED_MAIN_ROUTE_FROM, REQUIRED_MAIN_ROUTE_TO):
		map_editor_status = "필수 통로는 대체 경로가 있을 때만 삭제할 수 있습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	var deleted_id = selected_room
	map_editor_layout = candidate_layout
	selected_room = REQUIRED_MAIN_ROUTE_FROM if _layout_has_instance(map_editor_layout, REQUIRED_MAIN_ROUTE_FROM) else ""
	map_editor_path_candidate_index = 0
	_rebuild_map_editor_preview("통로 삭제")
	_log("통로 %s 삭제." % deleted_id)
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _save_map_editor_layout(persist: bool = true) -> bool:
	if not map_editor_active:
		return false
	var repair_result = _repair_required_main_route(map_editor_layout)
	if not bool(repair_result.get("ok", false)):
		map_editor_status = "필수 경로 복구 실패: %s" % str(repair_result.get("error", "unknown"))
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return false
	if bool(repair_result.get("changed", false)):
		map_editor_layout = repair_result.get("layout", map_editor_layout).duplicate(true)
		var created_count = int(repair_result.get("created_paths", 0))
		var connected_count = int(repair_result.get("connections_added", 0))
		_log("입구-왕좌 필수 경로를 복구했습니다. 길 %d개, 연결 %d개." % [created_count, connected_count])
	_rebuild_map_editor_preview("필수 경로 복구" if bool(repair_result.get("changed", false)) else "저장 검증")
	if not map_editor_errors.is_empty():
		map_editor_status = "오류가 있어 저장할 수 없습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return false
	var layout_id = DataRegistry.next_quarter_custom_layout_id("map_custom")
	var saved_layout = map_editor_layout.duplicate(true)
	saved_layout["template_id"] = layout_id
	saved_layout["display_name"] = "사용자 편집 맵 %s" % layout_id.get_slice("_", 2)
	if not DataRegistry.register_quarter_layout(layout_id, saved_layout, persist):
		map_editor_status = "맵 저장에 실패했습니다."
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return false
	map_editor_active = false
	map_editor_layout.clear()
	map_editor_errors.clear()
	quarter_layout_id = layout_id
	_setup_dungeon_graph()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	_log("맵 레이아웃을 %s로 저장했습니다." % quarter_layout_display_name(layout_id))
	_set_screen(Constants.SCREEN_MANAGEMENT)
	return true

func _map_editor_selected_origin_label() -> String:
	var origin = _map_editor_selected_origin()
	if origin == Vector2i(-9999, -9999):
		return "-"
	return "%d,%d" % [origin.x, origin.y]

func _map_editor_selected_locked() -> bool:
	var placed = _map_editor_placed_entry(selected_room)
	return bool(placed.get("locked", false)) if not placed.is_empty() else true

func _map_editor_status_line() -> String:
	if not map_editor_active:
		return "대기"
	if map_editor_errors.is_empty():
		return map_editor_status if map_editor_status != "" else "유효"
	return str(map_editor_errors[0])

func _map_editor_path_candidate_line() -> String:
	if not map_editor_active:
		return ""
	var candidates = _map_editor_gap_path_candidates_for_selected()
	if candidates.is_empty():
		return "통로 후보 없음"
	var index = _map_editor_clamped_path_candidate_index(candidates.size())
	var candidate: Dictionary = candidates[index]
	var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
	return "후보 %d/%d: %s -> %s (%d,%d) %s/%s" % [
		index + 1,
		candidates.size(),
		str(candidate.get("source_instance", "")),
		str(candidate.get("other_instance", "")),
		origin.x,
		origin.y,
		_map_editor_socket_id_from_ref(str(candidate.get("source_socket", ""))),
		_map_editor_socket_id_from_ref(str(candidate.get("other_socket", "")))
	]

func _rebuild_map_editor_preview(action_label: String) -> void:
	_setup_dungeon_graph()
	var validation = graph.validation_summary() if graph != null and graph.has_method("validation_summary") else {"ok": false, "errors": ["graph unavailable"]}
	map_editor_errors = validation.get("errors", []).duplicate(true)
	map_editor_status = "%s: 유효" % action_label if map_editor_errors.is_empty() else "%s: 오류 %d개" % [action_label, map_editor_errors.size()]
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	queue_redraw()

func _map_editor_selected_origin() -> Vector2i:
	var placed = _map_editor_placed_entry(selected_room)
	var origin_value: Array = placed.get("grid_origin", []) if not placed.is_empty() else []
	if origin_value.size() < 2:
		return Vector2i(-9999, -9999)
	return Vector2i(int(origin_value[0]), int(origin_value[1]))

func _map_editor_placed_entry(instance_id: String) -> Dictionary:
	var source_layout = map_editor_layout if map_editor_active and not map_editor_layout.is_empty() else DataRegistry.quarter_layout(quarter_layout_id)
	for placed in source_layout.get("placed_modules", []):
		if placed is Dictionary and str(placed.get("instance_id", "")) == instance_id:
			return placed
	return {}

func _map_editor_first_adjacent_socket_pair() -> Dictionary:
	var selected_sockets = _map_editor_socket_records(selected_room)
	var all_sockets = _map_editor_socket_records("")
	for selected_socket in selected_sockets:
		var from_ref = str(selected_socket.get("ref", ""))
		if _map_editor_ref_has_connection(from_ref):
			continue
		for other_socket in all_sockets:
			if str(other_socket.get("instance_id", "")) == selected_room:
				continue
			var to_ref = str(other_socket.get("ref", ""))
			if _map_editor_ref_has_connection(to_ref):
				continue
			var side = AutoTileMaskScript.side_between(selected_socket.get("cell", Vector2i.ZERO), other_socket.get("cell", Vector2i.ZERO))
			if side == "":
				continue
			if side != str(selected_socket.get("side", "")):
				continue
			if AutoTileMaskScript.opposite_side(side) != str(other_socket.get("side", "")):
				continue
			return {"from": from_ref, "to": to_ref}
	return {}

func _map_editor_gap_path_candidate_for_selected() -> Dictionary:
	var candidates = _map_editor_gap_path_candidates_for_selected()
	if candidates.is_empty():
		map_editor_path_candidate_index = 0
		return {}
	return candidates[_map_editor_clamped_path_candidate_index(candidates.size())]

func _map_editor_gap_path_candidates_for_selected() -> Array:
	var selected_sockets = _map_editor_socket_records(selected_room)
	var all_sockets = _map_editor_socket_records("")
	var candidates: Array = []
	var seen_candidates: Dictionary = {}
	for selected_socket in selected_sockets:
		if _map_editor_ref_has_connection(str(selected_socket.get("ref", ""))):
			continue
		for other_socket in all_sockets:
			var other_id = str(other_socket.get("instance_id", ""))
			if other_id == selected_room:
				continue
			if other_id.begins_with(USER_AUTHORED_PATH_PREFIX) or other_id.begins_with(SYSTEM_REQUIRED_PATH_PREFIX):
				continue
			if _map_editor_ref_has_connection(str(other_socket.get("ref", ""))):
				continue
			for candidate in _gap_corridor_candidates_from_socket_pair(map_editor_layout, selected_socket, other_socket):
				var score = _cell_distance_sq(selected_socket.get("cell", Vector2i.ZERO), other_socket.get("cell", Vector2i.ZERO)) \
					+ _cell_distance_sq(_layout_instance_center_cell(map_editor_layout, other_id), _layout_instance_center_cell(map_editor_layout, selected_room))
				var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
				var candidate_key = "%s|%s|%d,%d" % [other_id, str(candidate.get("module_id", "")), origin.x, origin.y]
				if seen_candidates.has(candidate_key):
					continue
				seen_candidates[candidate_key] = true
				candidate["score"] = score
				candidate["source_socket"] = str(selected_socket.get("ref", ""))
				candidate["other_socket"] = str(other_socket.get("ref", ""))
				candidates.append(candidate)
	candidates.sort_custom(Callable(self, "_map_editor_gap_path_candidate_less"))
	if candidates.is_empty():
		map_editor_path_candidate_index = 0
	elif map_editor_path_candidate_index >= candidates.size():
		map_editor_path_candidate_index = 0
	return candidates

func _map_editor_gap_path_candidate_less(first: Dictionary, second: Dictionary) -> bool:
	var first_score := float(first.get("score", 0.0))
	var second_score := float(second.get("score", 0.0))
	if not is_equal_approx(first_score, second_score):
		return first_score < second_score
	var first_target = str(first.get("other_instance", ""))
	var second_target = str(second.get("other_instance", ""))
	if first_target != second_target:
		return first_target < second_target
	var first_origin: Vector2i = first.get("origin", Vector2i.ZERO)
	var second_origin: Vector2i = second.get("origin", Vector2i.ZERO)
	if first_origin.y != second_origin.y:
		return first_origin.y < second_origin.y
	return first_origin.x < second_origin.x

func _map_editor_clamped_path_candidate_index(candidate_count: int) -> int:
	if candidate_count <= 0:
		map_editor_path_candidate_index = 0
		return 0
	if map_editor_path_candidate_index < 0 or map_editor_path_candidate_index >= candidate_count:
		map_editor_path_candidate_index = 0
	return map_editor_path_candidate_index

func _map_editor_preview_gap_path_candidate() -> Dictionary:
	if not map_editor_active:
		return {}
	return _map_editor_gap_path_candidate_for_selected()

func _map_editor_preview_gap_path_socket_markers() -> Array:
	if not map_editor_active:
		return []
	var candidate = _map_editor_preview_gap_path_candidate()
	if candidate.is_empty():
		return []
	var markers: Array = []
	var refs = [
		{"key": "source_socket", "role": "source"},
		{"key": "other_socket", "role": "target"}
	]
	for entry in refs:
		var socket = _map_editor_socket_record_for_ref(str(candidate.get(str(entry["key"]), "")))
		if socket.is_empty():
			continue
		var marker = socket.duplicate(true)
		marker["role"] = str(entry["role"])
		markers.append(marker)
	return markers

func _map_editor_socket_records(instance_filter: String) -> Array:
	var source_layout = map_editor_layout if map_editor_active and not map_editor_layout.is_empty() else DataRegistry.quarter_layout(quarter_layout_id)
	return _layout_socket_records(source_layout, instance_filter)

func _map_editor_socket_record_for_ref(reference: String) -> Dictionary:
	if reference == "":
		return {}
	for socket in _map_editor_socket_records(""):
		if str(socket.get("ref", "")) == reference:
			return socket
	return {}

func _layout_socket_records(source_layout: Dictionary, instance_filter: String = "") -> Array:
	var records: Array = []
	for placed in source_layout.get("placed_modules", []):
		if not (placed is Dictionary):
			continue
		var instance_id = str(placed.get("instance_id", ""))
		if instance_filter != "" and instance_id != instance_filter:
			continue
		var module_id = str(placed.get("module_id", ""))
		var module: Dictionary = DataRegistry.quarter_module(module_id)
		var origin = IsoMathScript.array_to_cell(placed.get("grid_origin", []))
		for socket in module.get("sockets", []):
			var socket_id = str(socket.get("id", ""))
			var local_cell = IsoMathScript.array_to_cell(socket.get("cell", socket.get("local_cell", [0, 0])))
			var ref = "%s:%s" % [instance_id, socket_id]
			records.append({
				"ref": ref,
				"instance_id": instance_id,
				"socket_id": socket_id,
				"side": str(socket.get("side", "")),
				"cell": origin + local_cell
			})
	return records

func _map_editor_ref_has_connection(reference: String) -> bool:
	return _layout_ref_has_connection(map_editor_layout, reference)

func _layout_ref_has_connection(source_layout: Dictionary, reference: String) -> bool:
	for connection in source_layout.get("connections", []):
		if str(connection.get("from", "")) == reference or str(connection.get("to", "")) == reference:
			return true
	return false

func _map_editor_ref_instance(reference: String) -> String:
	var parts = reference.split(":")
	if parts.size() < 2:
		return ""
	return str(parts[0])

func _map_editor_socket_id_from_ref(reference: String) -> String:
	var parts = reference.split(":")
	if parts.size() < 2:
		return "-"
	return str(parts[1])

func _ensure_required_main_route_for_current_layout(action_label: String) -> bool:
	if not use_quarter_module_map:
		return true
	var source_layout = DataRegistry.quarter_layout(quarter_layout_id)
	if source_layout.is_empty():
		return true
	var repair_result = _repair_required_main_route(source_layout)
	if not bool(repair_result.get("ok", false)):
		_log("%s 실패: 입구-왕좌 필수 경로를 복구할 수 없습니다. %s" % [action_label, str(repair_result.get("error", ""))])
		return false
	if not bool(repair_result.get("changed", false)):
		return true
	var repaired_layout: Dictionary = repair_result.get("layout", source_layout).duplicate(true)
	DataRegistry.register_quarter_layout(quarter_layout_id, repaired_layout, false)
	_setup_dungeon_graph()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	queue_redraw()
	_log("%s 전 입구-왕좌 필수 경로를 복구했습니다. 길 %d개, 연결 %d개." % [
		action_label,
		int(repair_result.get("created_paths", 0)),
		int(repair_result.get("connections_added", 0))
	])
	return true

func _repair_required_main_route(source_layout: Dictionary) -> Dictionary:
	var work: Dictionary = source_layout.duplicate(true)
	if _layout_has_instance_path(work, REQUIRED_MAIN_ROUTE_FROM, REQUIRED_MAIN_ROUTE_TO):
		return {"ok": true, "changed": false, "layout": work, "created_paths": 0, "connections_added": 0}
	if not _layout_has_instance(work, REQUIRED_MAIN_ROUTE_FROM):
		return {"ok": false, "changed": false, "layout": work, "error": "missing %s" % REQUIRED_MAIN_ROUTE_FROM}
	if not _layout_has_instance(work, REQUIRED_MAIN_ROUTE_TO):
		return {"ok": false, "changed": false, "layout": work, "error": "missing %s" % REQUIRED_MAIN_ROUTE_TO}

	var changed := false
	var created_paths := 0
	var connections_added := 0
	for _step in range(REQUIRED_ROUTE_REPAIR_MAX_STEPS):
		if _layout_has_instance_path(work, REQUIRED_MAIN_ROUTE_FROM, REQUIRED_MAIN_ROUTE_TO):
			return {
				"ok": true,
				"changed": changed,
				"layout": work,
				"created_paths": created_paths,
				"connections_added": connections_added
			}
		var source_component = _layout_component(work, REQUIRED_MAIN_ROUTE_FROM)
		if source_component.has(REQUIRED_MAIN_ROUTE_TO):
			return {
				"ok": true,
				"changed": changed,
				"layout": work,
				"created_paths": created_paths,
				"connections_added": connections_added
			}

		var bridge = _layout_closest_adjacent_instance_bridge(work, source_component, REQUIRED_MAIN_ROUTE_TO)
		if not bridge.is_empty():
			var bridge_added = _layout_connect_adjacent_sockets_between_instances(work, str(bridge.get("source_instance", "")), str(bridge.get("other_instance", "")), true)
			if bridge_added > 0:
				changed = true
				connections_added += bridge_added
				continue

		var inserted = _layout_insert_closest_gap_corridor(work, source_component, REQUIRED_MAIN_ROUTE_TO)
		if not inserted.is_empty():
			changed = true
			created_paths += 1
			connections_added += int(inserted.get("connections_added", 0))
			continue

		return {"ok": false, "changed": changed, "layout": work, "error": "no connectable socket or 2x2 gap candidate"}

	return {"ok": false, "changed": changed, "layout": work, "error": "repair step limit exceeded"}

func _layout_has_instance_path(source_layout: Dictionary, from_id: String, to_id: String) -> bool:
	var route_graph = ModuleGraphScript.new()
	route_graph.setup_quarter(DataRegistry.quarter_modules, source_layout, rooms)
	return not route_graph.path_between(from_id, to_id).is_empty()

func _layout_has_instance(source_layout: Dictionary, instance_id: String) -> bool:
	return not _layout_placed_entry(source_layout, instance_id).is_empty()

func _layout_placed_entry(source_layout: Dictionary, instance_id: String) -> Dictionary:
	for placed in source_layout.get("placed_modules", []):
		if placed is Dictionary and str(placed.get("instance_id", "")) == instance_id:
			return placed
	return {}

func _map_editor_entry_is_path(placed: Dictionary) -> bool:
	var instance_id = str(placed.get("instance_id", ""))
	var grid_id = str(placed.get("grid_id", ""))
	var module_id = str(placed.get("module_id", ""))
	return instance_id.begins_with(USER_AUTHORED_PATH_PREFIX) \
		or instance_id.begins_with(SYSTEM_REQUIRED_PATH_PREFIX) \
		or grid_id == USER_AUTHORED_PATH_GRID_ID \
		or grid_id == SYSTEM_REQUIRED_PATH_GRID_ID \
		or module_id.begins_with("corridor_gap_")

func _layout_remove_path_instance(source_layout: Dictionary, instance_id: String) -> void:
	var placed_modules: Array = []
	for placed in source_layout.get("placed_modules", []):
		if not (placed is Dictionary):
			continue
		if str(placed.get("instance_id", "")) != instance_id:
			placed_modules.append(placed)
	source_layout["placed_modules"] = placed_modules

	var socket_states: Dictionary = source_layout.get("socket_states", {}).duplicate(true)
	var kept_connections: Array = []
	for connection in source_layout.get("connections", []):
		var from_ref = str(connection.get("from", ""))
		var to_ref = str(connection.get("to", ""))
		if _map_editor_ref_instance(from_ref) == instance_id or _map_editor_ref_instance(to_ref) == instance_id:
			if _map_editor_ref_instance(from_ref) != instance_id:
				socket_states[from_ref] = "open_placeholder"
			else:
				socket_states.erase(from_ref)
			if _map_editor_ref_instance(to_ref) != instance_id:
				socket_states[to_ref] = "open_placeholder"
			else:
				socket_states.erase(to_ref)
		else:
			kept_connections.append(connection)
	source_layout["connections"] = kept_connections
	source_layout["socket_states"] = socket_states

func _layout_instance_ids(source_layout: Dictionary) -> Array:
	var ids: Array = []
	for placed in source_layout.get("placed_modules", []):
		if placed is Dictionary:
			var instance_id = str(placed.get("instance_id", ""))
			if instance_id != "":
				ids.append(instance_id)
	return ids

func _layout_component(source_layout: Dictionary, start_id: String) -> Dictionary:
	var adjacency: Dictionary = {}
	for instance_id in _layout_instance_ids(source_layout):
		adjacency[instance_id] = []
	if not adjacency.has(start_id):
		return {}
	for connection in source_layout.get("connections", []):
		var from_ref = _split_layout_ref(str(connection.get("from", "")))
		var to_ref = _split_layout_ref(str(connection.get("to", "")))
		if from_ref.is_empty() or to_ref.is_empty():
			continue
		var from_id = str(from_ref.get("instance_id", ""))
		var to_id = str(to_ref.get("instance_id", ""))
		if not adjacency.has(from_id) or not adjacency.has(to_id):
			continue
		if not adjacency[from_id].has(to_id):
			adjacency[from_id].append(to_id)
		if not adjacency[to_id].has(from_id):
			adjacency[to_id].append(from_id)
	var visited: Dictionary = {start_id: true}
	var frontier: Array = [start_id]
	while not frontier.is_empty():
		var current = str(frontier.pop_front())
		for next_id in adjacency.get(current, []):
			if visited.has(next_id):
				continue
			visited[next_id] = true
			frontier.append(next_id)
	return visited

func _split_layout_ref(reference: String) -> Dictionary:
	var parts = reference.split(":")
	if parts.size() != 2 or str(parts[0]) == "" or str(parts[1]) == "":
		return {}
	return {"instance_id": str(parts[0]), "socket_id": str(parts[1])}

func _layout_closest_adjacent_instance_bridge(source_layout: Dictionary, source_component: Dictionary, goal_id: String) -> Dictionary:
	var sockets = _layout_socket_records(source_layout)
	var best: Dictionary = {}
	var best_score := INF
	for source_socket in sockets:
		var source_id = str(source_socket.get("instance_id", ""))
		if not source_component.has(source_id):
			continue
		if _layout_ref_has_connection(source_layout, str(source_socket.get("ref", ""))):
			continue
		for other_socket in sockets:
			var other_id = str(other_socket.get("instance_id", ""))
			if other_id == source_id or source_component.has(other_id):
				continue
			if _layout_ref_has_connection(source_layout, str(other_socket.get("ref", ""))):
				continue
			if not _socket_records_can_connect(source_socket, other_socket):
				continue
			var score = _layout_bridge_score(source_layout, source_socket, other_socket, goal_id)
			if score < best_score:
				best_score = score
				best = {
					"source_instance": source_id,
					"other_instance": other_id,
					"score": score
				}
	return best

func _layout_bridge_score(source_layout: Dictionary, source_socket: Dictionary, other_socket: Dictionary, goal_id: String) -> float:
	var other_id = str(other_socket.get("instance_id", ""))
	var goal_component = _layout_component(source_layout, goal_id)
	var goal_component_penalty := 0.0 if goal_component.has(other_id) else 10000.0
	return goal_component_penalty \
		+ _cell_distance_sq(source_socket.get("cell", Vector2i.ZERO), other_socket.get("cell", Vector2i.ZERO)) \
		+ _cell_distance_sq(_layout_instance_center_cell(source_layout, other_id), _layout_instance_center_cell(source_layout, goal_id))

func _layout_connect_adjacent_sockets_between_instances(source_layout: Dictionary, first_id: String, second_id: String, system_required: bool = false) -> int:
	var added := 0
	var first_sockets = _layout_socket_records(source_layout, first_id)
	var second_sockets = _layout_socket_records(source_layout, second_id)
	for first_socket in first_sockets:
		var first_ref = str(first_socket.get("ref", ""))
		if _layout_ref_has_connection(source_layout, first_ref):
			continue
		for second_socket in second_sockets:
			var second_ref = str(second_socket.get("ref", ""))
			if _layout_ref_has_connection(source_layout, second_ref):
				continue
			if not _socket_records_can_connect(first_socket, second_socket):
				continue
			if _layout_add_connection(source_layout, first_ref, second_ref, system_required):
				added += 1
				break
	return added

func _layout_count_adjacent_sockets_between_instances(source_layout: Dictionary, first_id: String, second_id: String) -> int:
	var count := 0
	var first_sockets = _layout_socket_records(source_layout, first_id)
	var second_sockets = _layout_socket_records(source_layout, second_id)
	for first_socket in first_sockets:
		var first_ref = str(first_socket.get("ref", ""))
		if _layout_ref_has_connection(source_layout, first_ref):
			continue
		for second_socket in second_sockets:
			var second_ref = str(second_socket.get("ref", ""))
			if _layout_ref_has_connection(source_layout, second_ref):
				continue
			if _socket_records_can_connect(first_socket, second_socket):
				count += 1
				break
	return count

func _layout_add_connection(source_layout: Dictionary, from_ref: String, to_ref: String, system_required: bool = false) -> bool:
	if from_ref == "" or to_ref == "" or _layout_connection_exists(source_layout, from_ref, to_ref):
		return false
	var connections: Array = source_layout.get("connections", []).duplicate(true)
	var entry = {"from": from_ref, "to": to_ref}
	if system_required:
		entry["system_required"] = true
	connections.append(entry)
	source_layout["connections"] = connections
	var socket_states: Dictionary = source_layout.get("socket_states", {}).duplicate(true)
	socket_states[from_ref] = "connected"
	socket_states[to_ref] = "connected"
	source_layout["socket_states"] = socket_states
	return true

func _layout_connection_exists(source_layout: Dictionary, from_ref: String, to_ref: String) -> bool:
	for connection in source_layout.get("connections", []):
		var existing_from = str(connection.get("from", ""))
		var existing_to = str(connection.get("to", ""))
		if existing_from == from_ref and existing_to == to_ref:
			return true
		if existing_from == to_ref and existing_to == from_ref:
			return true
	return false

func _socket_records_can_connect(first_socket: Dictionary, second_socket: Dictionary) -> bool:
	var first_cell: Vector2i = first_socket.get("cell", Vector2i.ZERO)
	var second_cell: Vector2i = second_socket.get("cell", Vector2i.ZERO)
	var side = AutoTileMaskScript.side_between(first_cell, second_cell)
	if side == "":
		return false
	if side != str(first_socket.get("side", "")):
		return false
	return AutoTileMaskScript.opposite_side(side) == str(second_socket.get("side", ""))

func _layout_insert_closest_gap_corridor(source_layout: Dictionary, source_component: Dictionary, goal_id: String) -> Dictionary:
	var candidate = _layout_closest_gap_corridor_candidate(source_layout, source_component, goal_id)
	if candidate.is_empty():
		return {}
	var path_id = _layout_next_system_path_id(source_layout)
	var placed_modules: Array = source_layout.get("placed_modules", []).duplicate(true)
	var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
	placed_modules.append({
		"instance_id": path_id,
		"module_id": str(candidate.get("module_id", "")),
		"grid_id": SYSTEM_REQUIRED_PATH_GRID_ID,
		"grid_origin": [origin.x, origin.y],
		"locked": false,
		"legacy_room_id": path_id,
		"system_required": true
	})
	source_layout["placed_modules"] = placed_modules
	var added := 0
	added += _layout_connect_adjacent_sockets_between_instances(source_layout, str(candidate.get("source_instance", "")), path_id, true)
	added += _layout_connect_adjacent_sockets_between_instances(source_layout, path_id, str(candidate.get("other_instance", "")), true)
	return {
		"instance_id": path_id,
		"connections_added": added
	}

func _layout_closest_gap_corridor_candidate(source_layout: Dictionary, source_component: Dictionary, goal_id: String) -> Dictionary:
	var sockets = _layout_socket_records(source_layout)
	var best: Dictionary = {}
	var best_score := INF
	for source_socket in sockets:
		var source_id = str(source_socket.get("instance_id", ""))
		if not source_component.has(source_id):
			continue
		if _layout_ref_has_connection(source_layout, str(source_socket.get("ref", ""))):
			continue
		for other_socket in sockets:
			var other_id = str(other_socket.get("instance_id", ""))
			if other_id == source_id or source_component.has(other_id):
				continue
			if _layout_ref_has_connection(source_layout, str(other_socket.get("ref", ""))):
				continue
			var candidates = _gap_corridor_candidates_from_socket_pair(source_layout, source_socket, other_socket)
			for candidate in candidates:
				var score = _layout_gap_candidate_score(source_layout, source_socket, other_socket, goal_id)
				if score < best_score:
					best_score = score
					best = candidate
	return best

func _gap_corridor_candidates_from_socket_pair(source_layout: Dictionary, source_socket: Dictionary, other_socket: Dictionary) -> Array:
	var results: Array = []
	var source_cell: Vector2i = source_socket.get("cell", Vector2i.ZERO)
	var other_cell: Vector2i = other_socket.get("cell", Vector2i.ZERO)
	var source_side = str(source_socket.get("side", ""))
	if AutoTileMaskScript.opposite_side(source_side) != str(other_socket.get("side", "")):
		return results
	var delta = other_cell - source_cell
	var module_id := ""
	var origins: Array = []
	match source_side:
		"E":
			if delta != Vector2i(3, 0):
				return results
			module_id = "corridor_gap_ew_2x2_01"
			origins = [Vector2i(source_cell.x + 1, source_cell.y), Vector2i(source_cell.x + 1, source_cell.y - 1)]
		"W":
			if delta != Vector2i(-3, 0):
				return results
			module_id = "corridor_gap_ew_2x2_01"
			origins = [Vector2i(source_cell.x - 2, source_cell.y), Vector2i(source_cell.x - 2, source_cell.y - 1)]
		"S":
			if delta != Vector2i(0, 3):
				return results
			module_id = "corridor_gap_ns_2x2_01"
			origins = [Vector2i(source_cell.x, source_cell.y + 1), Vector2i(source_cell.x - 1, source_cell.y + 1)]
		"N":
			if delta != Vector2i(0, -3):
				return results
			module_id = "corridor_gap_ns_2x2_01"
			origins = [Vector2i(source_cell.x, source_cell.y - 2), Vector2i(source_cell.x - 1, source_cell.y - 2)]
		_:
			return results
	for origin in origins:
		var candidate = {
			"source_instance": str(source_socket.get("instance_id", "")),
			"other_instance": str(other_socket.get("instance_id", "")),
			"module_id": module_id,
			"origin": origin
		}
		if _layout_gap_corridor_candidate_is_valid(source_layout, candidate):
			results.append(candidate)
	return results

func _layout_gap_corridor_candidate_is_valid(source_layout: Dictionary, candidate: Dictionary) -> bool:
	var module_id = str(candidate.get("module_id", ""))
	var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
	if not _layout_cells_available_for_module(source_layout, module_id, origin):
		return false
	var probe_id = "__required_route_probe_path"
	var probe_layout: Dictionary = source_layout.duplicate(true)
	var placed_modules: Array = probe_layout.get("placed_modules", []).duplicate(true)
	placed_modules.append({
		"instance_id": probe_id,
		"module_id": module_id,
		"grid_origin": [origin.x, origin.y],
		"locked": false,
		"legacy_room_id": probe_id
	})
	probe_layout["placed_modules"] = placed_modules
	var source_count = _layout_count_adjacent_sockets_between_instances(probe_layout, str(candidate.get("source_instance", "")), probe_id)
	var other_count = _layout_count_adjacent_sockets_between_instances(probe_layout, probe_id, str(candidate.get("other_instance", "")))
	return source_count >= 2 and other_count >= 2

func _layout_cells_available_for_module(source_layout: Dictionary, module_id: String, origin: Vector2i) -> bool:
	var module: Dictionary = DataRegistry.quarter_module(module_id)
	if module.is_empty():
		return false
	var occupied = _layout_floor_cell_set(source_layout)
	var active_rect = _layout_active_rect(source_layout)
	var max_grid = _layout_max_grid_size()
	for value in module.get("floor_cells", []):
		if not value is Array:
			continue
		var cell = origin + IsoMathScript.array_to_cell(value)
		if occupied.has(cell):
			return false
		if cell.x < 0 or cell.y < 0 or cell.x >= max_grid.x or cell.y >= max_grid.y:
			return false
		if not active_rect.has_point(cell):
			return false
	return true

func _layout_floor_cell_set(source_layout: Dictionary) -> Dictionary:
	var occupied: Dictionary = {}
	for placed in source_layout.get("placed_modules", []):
		if not placed is Dictionary:
			continue
		var module: Dictionary = DataRegistry.quarter_module(str(placed.get("module_id", "")))
		var origin = IsoMathScript.array_to_cell(placed.get("grid_origin", []))
		for value in module.get("floor_cells", []):
			if value is Array:
				occupied[origin + IsoMathScript.array_to_cell(value)] = true
	return occupied

func _layout_active_rect(source_layout: Dictionary) -> Rect2i:
	var grade = str(source_layout.get("castle_grade", "F"))
	var grades: Dictionary = DataRegistry.quarter_castle_grade_rules.get("grades", {})
	var grade_rule: Dictionary = grades.get(grade, grades.get("F", {}))
	var rect_value: Array = grade_rule.get("active_rect", [0, 0, _layout_max_grid_size().x, _layout_max_grid_size().y])
	if rect_value.size() < 4:
		return Rect2i(Vector2i.ZERO, _layout_max_grid_size())
	return Rect2i(int(rect_value[0]), int(rect_value[1]), int(rect_value[2]), int(rect_value[3]))

func _layout_max_grid_size() -> Vector2i:
	var max_value: Array = DataRegistry.quarter_castle_grade_rules.get("max_grid_size", [28, 26])
	if max_value.size() < 2:
		return Vector2i(28, 26)
	return Vector2i(int(max_value[0]), int(max_value[1]))

func _layout_gap_candidate_score(source_layout: Dictionary, source_socket: Dictionary, other_socket: Dictionary, goal_id: String) -> float:
	var other_id = str(other_socket.get("instance_id", ""))
	var goal_component = _layout_component(source_layout, goal_id)
	var goal_component_penalty := 0.0 if goal_component.has(other_id) else 10000.0
	return goal_component_penalty \
		+ _cell_distance_sq(source_socket.get("cell", Vector2i.ZERO), other_socket.get("cell", Vector2i.ZERO)) \
		+ _cell_distance_sq(_layout_instance_center_cell(source_layout, other_id), _layout_instance_center_cell(source_layout, goal_id))

func _layout_instance_center_cell(source_layout: Dictionary, instance_id: String) -> Vector2:
	var placed = _layout_placed_entry(source_layout, instance_id)
	if placed.is_empty():
		return Vector2.ZERO
	var module: Dictionary = DataRegistry.quarter_module(str(placed.get("module_id", "")))
	var origin = IsoMathScript.array_to_cell(placed.get("grid_origin", []))
	var total := Vector2.ZERO
	var count := 0
	for value in module.get("floor_cells", []):
		if value is Array:
			var cell = origin + IsoMathScript.array_to_cell(value)
			total += Vector2(cell.x, cell.y)
			count += 1
	if count == 0:
		return Vector2(origin.x, origin.y)
	return total / float(count)

func _cell_distance_sq(first, second) -> float:
	var first_point = Vector2(float(first.x), float(first.y))
	var second_point = Vector2(float(second.x), float(second.y))
	return first_point.distance_squared_to(second_point)

func _layout_next_system_path_id(source_layout: Dictionary) -> String:
	var index := 1
	while true:
		var candidate = "%s_%02d" % [SYSTEM_REQUIRED_PATH_PREFIX, index]
		if not _layout_has_instance(source_layout, candidate):
			return candidate
		index += 1
	return "%s_%02d" % [SYSTEM_REQUIRED_PATH_PREFIX, index]

func _layout_next_user_path_id(source_layout: Dictionary) -> String:
	var index := 1
	while true:
		var candidate = "%s_%02d" % [USER_AUTHORED_PATH_PREFIX, index]
		if not _layout_has_instance(source_layout, candidate):
			return candidate
		index += 1
	return "%s_%02d" % [USER_AUTHORED_PATH_PREFIX, index]

func _default_facility_role(room_id: String, room: Dictionary) -> String:
	match room_id:
		"barracks":
			return "barracks"
		"treasure":
			return "treasure"
		"recovery":
			return "recovery"
		"slot_01":
			return "build_slot"
	var room_type = str(room.get("type", ""))
	match room_type:
		"entry":
			return "entry"
		"trap":
			return "trap"
		"corridor":
			return "corridor"
		"core":
			return "core"
	return room_type

func _load_textures() -> void:
	var dungeon_path = "res://assets/sprites/dungeon_gpt2/"
	floor_texture = _load_png(dungeon_path + "gpt2_floor_stone.png")
	wall_texture = _load_png(dungeon_path + "gpt2_floor_rough.png")
	spike_texture = _load_png("res://assets/sprites/tiles/tile_spike_floor_01.png")
	dungeon_art = {
		"asset_sheet": _load_png(dungeon_path + "gpt2_dungeon_asset_sheet.png"),
		"connected_map": _load_png(dungeon_path + "gpt2_dungeon_connected_map.png"),
		"floor_stone": floor_texture,
		"floor_rough": wall_texture,
		"wall_cap": _load_png(dungeon_path + "gpt2_wall_cap_long.png"),
		"wall_face": _load_png(dungeon_path + "gpt2_wall_face_banner.png"),
		"wall_panel": _load_png(dungeon_path + "gpt2_wall_panel_torch.png"),
		"door_arch": _load_png(dungeon_path + "gpt2_door_arch.png"),
		"pillar": _load_png(dungeon_path + "gpt2_pillar.png"),
		"purple_torch": _load_png(dungeon_path + "gpt2_purple_torch.png"),
		"brazier": _load_png(dungeon_path + "gpt2_brazier.png"),
		"rock_border": _load_png(dungeon_path + "gpt2_rock_border_front.png"),
		"rock_columns": _load_png(dungeon_path + "gpt2_rock_columns.png"),
		"fortress_wall": _load_png(dungeon_path + "gpt2_fortress_wall.png")
	}
	props = {
		"res://assets/ui/room_v2/room_v2_entrance.png": _load_png("res://assets/ui/room_v2/room_v2_entrance.png"),
		"res://assets/ui/room_v2/room_v2_spike_corridor.png": _load_png("res://assets/ui/room_v2/room_v2_spike_corridor.png"),
		"res://assets/ui/room_v2/room_v2_center.png": _load_png("res://assets/ui/room_v2/room_v2_center.png"),
		"res://assets/ui/room_v2/room_v2_throne.png": _load_png("res://assets/ui/room_v2/room_v2_throne.png"),
		"res://assets/ui/room_v2/room_v2_barracks.png": _load_png("res://assets/ui/room_v2/room_v2_barracks.png"),
		"res://assets/ui/room_v2/room_v2_treasure.png": _load_png("res://assets/ui/room_v2/room_v2_treasure.png"),
		"res://assets/ui/room_v2/room_v2_recovery.png": _load_png("res://assets/ui/room_v2/room_v2_recovery.png"),
		"res://assets/ui/room_v2/room_v2_build_slot.png": _load_png("res://assets/ui/room_v2/room_v2_build_slot.png"),
		"res://assets/ui/room_v2/room_v2_watch_post.png": _load_png("res://assets/ui/room_v2/room_v2_watch_post.png")
	}
	effect_textures = {
		"fireball": _load_png("res://assets/sprites/effects/fx_fireball_00.png"),
		"slash": _load_png("res://assets/sprites/effects/fx_hit_slash_00.png"),
		"impact": _load_png("res://assets/sprites/effects/fx_fire_impact_00.png"),
		"shield": _load_png("res://assets/sprites/effects/fx_shield_pulse_00.png"),
		"guard": _load_png("res://assets/sprites/effects/fx_guard_pulse_00.png"),
		"loot": _load_png("res://assets/sprites/effects/fx_loot_spark_00.png")
	}
	effect_frame_sets = {
		"fireball": _load_effect_frames("fx_fireball"),
		"slash": _load_effect_frames("fx_hit_slash"),
		"impact": _load_effect_frames("fx_fire_impact"),
		"shield": _load_effect_frames("fx_shield_pulse"),
		"guard": _load_effect_frames("fx_guard_pulse"),
		"loot": _load_effect_frames("fx_loot_spark")
	}

func _load_png(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded = ResourceLoader.load(path)
		if loaded is Texture2D:
			return loaded
	var image = Image.new()
	var err = image.load(path)
	if err != OK and path.begins_with("res://"):
		err = image.load(ProjectSettings.globalize_path(path))
	if err == OK:
		return ImageTexture.create_from_image(image)
	push_warning("Could not load texture: %s" % path)
	return null

func _load_effect_frames(base_name: String) -> Array:
	var frames: Array = []
	for index in range(8):
		var frame_path = "res://assets/sprites/effects/%s_%02d.png" % [base_name, index]
		if ResourceLoader.exists(frame_path):
			var texture = _load_png(frame_path)
			if texture != null:
				frames.append(texture)
	return frames

func room_icon_path(icon_name: String) -> String:
	if icon_name == "":
		return ""
	if icon_name.begins_with("res://"):
		return icon_name
	if icon_name.begins_with("marker_"):
		return "res://assets/sprites/room_markers/%s" % icon_name
	return "res://assets/sprites/rooms/%s" % icon_name

func _create_layers() -> void:
	combat_camera = Camera2D.new()
	combat_camera.name = "CombatCamera"
	combat_camera.enabled = false
	combat_camera.position = COMBAT_CAMERA_HOME
	add_child(combat_camera)
	unit_root = Node2D.new()
	unit_root.name = "UnitYSortLayer"
	unit_root.y_sort_enabled = true
	unit_root.z_index = 0
	add_child(unit_root)
	effect_root = Node2D.new()
	effect_root.name = "FxLayer"
	effect_root.z_index = 70
	add_child(effect_root)
	ui_layer = CanvasLayer.new()
	ui_layer.name = "HUD"
	add_child(ui_layer)

func _create_controllers() -> void:
	dungeon_renderer = DungeonRendererScript.new()
	dungeon_renderer.setup(self)
	quarter_renderer = QuarterDungeonRendererScript.new()
	quarter_renderer.setup(self)
	hud = HUDControllerScript.new()
	hud.setup(self)
	management_scene = ManagementSceneControllerScript.new()
	management_scene.setup(self, hud)
	combat_scene = CombatSceneControllerScript.new()
	combat_scene.setup(self, hud)

func _set_screen(screen_name: String) -> void:
	current_screen = screen_name
	_update_combat_camera_enabled()
	SignalBus.screen_changed.emit(screen_name)
	hud.clear()
	tutorial_targets.clear()
	match current_screen:
		Constants.SCREEN_TITLE:
			_build_onboarding_title_ui()
		Constants.SCREEN_NAME_ENTRY:
			_build_onboarding_name_entry_ui()
		Constants.SCREEN_DIALOGUE:
			_build_onboarding_dialogue_ui()
		Constants.SCREEN_MANAGEMENT:
			management_scene.build_management_ui()
		Constants.SCREEN_MONSTER:
			management_scene.build_monster_ui()
		Constants.SCREEN_COMBAT:
			combat_scene.build_combat_ui()
		Constants.SCREEN_RESULT:
			management_scene.build_result_ui()
		Constants.SCREEN_RAID_PREVIEW:
			_build_onboarding_raid_preview_ui()
	_tutorial_build_overlay()
	queue_redraw()

func _onboarding_screen_blocks_map_input() -> bool:
	return current_screen in [
		Constants.SCREEN_TITLE,
		Constants.SCREEN_NAME_ENTRY,
		Constants.SCREEN_DIALOGUE,
		Constants.SCREEN_RAID_PREVIEW
	]

func _build_onboarding_title_ui() -> void:
	var screen = _onboarding_screen_panel(Color("#07050dee"))
	hud.label(screen, "마왕님, 마왕성은 누가 지켜요?", _onboarding_rect("S00_TITLE", "Logo", Rect2(360, 120, 1200, 220)).position, _onboarding_rect("S00_TITLE", "Logo", Rect2(360, 120, 1200, 220)).size, 54, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(screen, "F급 신입 마왕성 방어 튜토리얼", Vector2(560, 330), Vector2(800, 44), 24, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.button(screen, "새 게임", _onboarding_rect("S00_TITLE", "Menu_NewGame", Rect2(760, 460, 400, 72)), Callable(self, "_onboarding_start_new_game"), 24)
	var continue_button = hud.button(screen, "이어하기", _onboarding_rect("S00_TITLE", "Menu_Continue", Rect2(760, 548, 400, 72)), Callable(self, "_log").bind("저장 데이터는 아직 연결되지 않았습니다."), 24)
	continue_button.disabled = true
	continue_button.add_theme_stylebox_override("disabled", hud.style(Color("#15121aaa"), Color("#3b3143"), 2))
	continue_button.add_theme_color_override("font_disabled_color", Color("#766d7f"))
	hud.button(screen, "설정", _onboarding_rect("S00_TITLE", "Menu_Options", Rect2(760, 636, 400, 72)), Callable(self, "_log").bind("설정 화면은 정규 캠페인 작업에서 연결합니다."), 24)
	hud.button(screen, "종료", _onboarding_rect("S00_TITLE", "Menu_Quit", Rect2(760, 724, 400, 72)), Callable(self, "_onboarding_quit_requested"), 24)
	hud.label(screen, "onboarding_flow_dialogue_v0.4 / Godot 4.5", _onboarding_rect("S00_TITLE", "VersionLabel", Rect2(32, 1020, 400, 32)).position, _onboarding_rect("S00_TITLE", "VersionLabel", Rect2(32, 1020, 400, 32)).size, 15, Color("#8d8398"))

func _build_onboarding_name_entry_ui() -> void:
	onboarding_name_input = null
	onboarding_bati_comment_label = null
	var screen = _onboarding_screen_panel(Color("#08060dee"))
	var panel_rect = _onboarding_rect("S01_NAME_ENTRY", "Panel_NameForm", Rect2(560, 210, 800, 610))
	var panel = _onboarding_child_panel(screen, panel_rect, Color("#100d14f2"), Color("#9b6a27"))
	var title_rect = _onboarding_rect("S01_NAME_ENTRY", "Title", Rect2(620, 260, 680, 60))
	hud.label(panel, "F급 신입 마왕 등록", title_rect.position - panel_rect.position, title_rect.size, 34, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(panel, "이름은 대사 치환값 {{player_name}}으로 저장됩니다.", Vector2(80, 130), Vector2(640, 34), 18, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)

	var input_rect = _onboarding_rect("S01_NAME_ENTRY", "NameInput", Rect2(700, 420, 520, 64))
	onboarding_name_input = LineEdit.new()
	onboarding_name_input.position = input_rect.position - panel_rect.position
	onboarding_name_input.size = input_rect.size
	onboarding_name_input.placeholder_text = "마왕명을 입력하세요"
	onboarding_name_input.max_length = 12
	onboarding_name_input.add_theme_font_override("font", UI_FONT)
	onboarding_name_input.add_theme_font_size_override("font_size", 24)
	onboarding_name_input.add_theme_color_override("font_color", Color("#f7efe1"))
	onboarding_name_input.add_theme_color_override("font_placeholder_color", Color("#7d7586"))
	onboarding_name_input.add_theme_stylebox_override("normal", hud.panel_style("dark", Color("#17141ddd"), Color("#57485e"), 2))
	onboarding_name_input.text_submitted.connect(_onboarding_name_submitted)
	panel.add_child(onboarding_name_input)
	register_tutorial_target("NameInput", input_rect)
	onboarding_name_input.call_deferred("grab_focus")

	hud.button(panel, "무작위 이름", _onboarding_relative_rect(_onboarding_rect("S01_NAME_ENTRY", "RandomNameButton", Rect2(700, 500, 250, 56)), panel_rect), Callable(self, "_onboarding_random_name"), 19)
	hud.button(panel, "확정", _onboarding_relative_rect(_onboarding_rect("S01_NAME_ENTRY", "ConfirmButton", Rect2(970, 500, 250, 56)), panel_rect), Callable(self, "_onboarding_confirm_name"), 19)

	var portrait_rect = _onboarding_rect("S01_NAME_ENTRY", "BatiPortrait", Rect2(610, 610, 120, 120))
	_onboarding_add_portrait(panel, Rect2(portrait_rect.position - panel_rect.position, portrait_rect.size), "CHR_BATI", "바티", "dry", false)

	var comment_rect = _onboarding_rect("S01_NAME_ENTRY", "BatiComment", Rect2(750, 610, 520, 130))
	onboarding_bati_comment_label = hud.label(panel, _onboarding_name_screen_comment(), comment_rect.position - panel_rect.position, comment_rect.size, 18, Color("#d8d1df"))

func _build_onboarding_dialogue_ui() -> void:
	var screen = _onboarding_screen_panel(Color("#050407d8"))
	if onboarding_dialogue_queue.is_empty():
		_onboarding_add_scene_illustration(screen, _onboarding_rect("S02_DIALOGUE", "SceneIllustration", Rect2(0, 0, 1920, 1080)), _onboarding_dialogue_scene_path({}))
		hud.label(screen, "튜토리얼", Vector2(72, 50), Vector2(360, 42), 24, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
		hud.rich_label(screen, "표시할 대사가 없습니다.", Vector2(560, 766), Vector2(1040, 150), 24, Color("#f7efe1"), UIFontScript.ROLE_DIALOGUE, TextServer.AUTOWRAP_ARBITRARY, VERTICAL_ALIGNMENT_CENTER)
		hud.button(screen, "닫기", Rect2(1600, 920, 190, 48), Callable(self, "_onboarding_advance_dialogue"), 18)
		return
	var line: Dictionary = onboarding_dialogue_queue[clampi(onboarding_dialogue_index, 0, onboarding_dialogue_queue.size() - 1)]
	_onboarding_add_scene_illustration(screen, _onboarding_rect("S02_DIALOGUE", "SceneIllustration", Rect2(0, 0, 1920, 1080)), _onboarding_dialogue_scene_path(line))
	hud.label(screen, "튜토리얼", Vector2(72, 50), Vector2(360, 42), 24, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var speaker_id = str(line.get("speaker", ""))
	var speaker_name = _onboarding_speaker_name(speaker_id)
	var portrait_rect = _onboarding_rect("S02_DIALOGUE", "SpeakerPortrait", Rect2(96, 636, 270, 372))
	_onboarding_add_portrait(screen, portrait_rect, speaker_id, speaker_name, str(line.get("emotion", "")), true)
	var box_rect = _onboarding_rect("S02_DIALOGUE", "DialogueBox", Rect2(380, 648, 1444, 360))
	_onboarding_child_panel(screen, box_rect, Color("#100d14f4"), Color("#9b6a27"))
	var speaker_rect = _onboarding_rect("S02_DIALOGUE", "SpeakerName", Rect2(560, 704, 520, 42))
	hud.label(screen, speaker_name, speaker_rect.position, speaker_rect.size, 24, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "", UIFontScript.ROLE_EMPHASIS)
	var text_rect = _onboarding_rect("S02_DIALOGUE", "DialogueText", Rect2(560, 766, 1048, 150))
	var dialogue_label = hud.rich_label(screen, _onboarding_line_text(line), text_rect.position, text_rect.size, 23, Color("#f7efe1"), UIFontScript.ROLE_DIALOGUE, TextServer.AUTOWRAP_ARBITRARY, VERTICAL_ALIGNMENT_CENTER)
	dialogue_label.add_theme_constant_override("line_separation", 4)
	var next_rect = _onboarding_rect("S02_DIALOGUE", "NextIndicator", Rect2(1688, 958, 100, 32))
	hud.label(screen, "%d/%d" % [onboarding_dialogue_index + 1, onboarding_dialogue_queue.size()], next_rect.position - Vector2(88, 0), Vector2(80, 32), 16, Color("#8d8398"), HORIZONTAL_ALIGNMENT_RIGHT, "", UIFontScript.ROLE_BODY)
	hud.button(screen, "다음", Rect2(next_rect.position.x - 20, next_rect.position.y - 8, 130, 44), Callable(self, "_onboarding_advance_dialogue"), 18)

func _build_onboarding_raid_preview_ui() -> void:
	var screen = _onboarding_screen_panel(Color("#06050bee"))
	_onboarding_set_stage("LV12_DAY04_RAID_PREVIEW")
	var world_rect = _onboarding_rect("S06_RAID_PREVIEW", "WorldMapPanel", Rect2(120, 100, 1080, 780))
	var world = _onboarding_child_panel(screen, world_rect, Color("#101017e8"), Color("#6e5630"))
	register_tutorial_target("WorldMapPanel", world_rect)
	hud.label(world, "DAY 04 악명 원정 예고", Vector2(0, 42), Vector2(world_rect.size.x, 52), 34, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(world, "마왕성 방어 이후에는 밖으로 나가 악명을 얻는 원정 루프가 열립니다.", Vector2(120, 132), Vector2(840, 56), 22, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(world, "첫 목표: 마을 외곽 표지판", Vector2(240, 325), Vector2(600, 48), 30, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(world, "정규 캠페인 연결 지점: CAMPAIGN_DAY_04", Vector2(240, 575), Vector2(600, 40), 20, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
	var info_rect = _onboarding_rect("S06_RAID_PREVIEW", "RaidInfoPanel", Rect2(1240, 100, 560, 780))
	var info = _onboarding_child_panel(screen, info_rect, Color("#100d14f2"), Color("#9b6a27"))
	hud.label(info, "예고", Vector2(0, 34), Vector2(info_rect.size.x, 46), 31, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	hud.label(info, "방어만으로 악명을 올리는 초반 루프는 DAY 03에서 검증됩니다.\n\nDAY 04부터는 원정 선택, 목표 보상, 귀환 후 성 강화 루프로 확장합니다.\n\n데모 범위에서는 예고 화면까지만 잠금 해제합니다.", Vector2(44, 120), Vector2(472, 420), 22, Color("#d8d1df"))
	hud.button(screen, "관리 화면", _onboarding_rect("S06_RAID_PREVIEW", "BackButton", Rect2(1520, 920, 280, 64)), Callable(self, "_onboarding_finish_raid_preview"), 20, "BackButton")
	call_deferred("_onboarding_emit_raid_preview_dialogue")

func _onboarding_screen_panel(color: Color) -> Panel:
	var screen = hud.panel(Rect2(0, 0, 1920, 1080), color, color, "", "flat")
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	return screen

func _onboarding_child_panel(parent: Control, rect: Rect2, color: Color, border: Color) -> Panel:
	var result = Panel.new()
	result.position = rect.position
	result.size = rect.size
	result.mouse_filter = Control.MOUSE_FILTER_STOP
	result.add_theme_stylebox_override("panel", hud.panel_style("panel", color, border, 2))
	parent.add_child(result)
	return result

func _onboarding_add_scene_illustration(parent: Control, rect: Rect2, path: String) -> void:
	if path != "":
		var image = hud.texture(parent, path, rect)
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var shade = ColorRect.new()
	shade.position = rect.position
	shade.size = rect.size
	shade.color = Color("#0302078c")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shade)

func _onboarding_add_portrait(parent: Control, rect: Rect2, speaker_id: String, speaker_name: String, emotion: String = "", show_name: bool = true) -> Panel:
	var portrait = _onboarding_child_panel(parent, rect, Color("#130f19f0"), _onboarding_speaker_accent(speaker_id))
	var portrait_path = _onboarding_speaker_portrait_path(speaker_id, emotion)
	if portrait_path == "":
		hud.label(portrait, speaker_name, Vector2.ZERO, rect.size, 24, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
		return portrait
	var padding := 8.0
	var label_height := 42.0 if show_name else 0.0
	var image_rect = Rect2(Vector2(padding, padding), Vector2(rect.size.x - padding * 2.0, rect.size.y - padding * 2.0 - label_height))
	hud.texture(portrait, portrait_path, image_rect)
	if show_name:
		var plate = ColorRect.new()
		plate.position = Vector2(padding, rect.size.y - label_height - padding)
		plate.size = Vector2(rect.size.x - padding * 2.0, label_height)
		plate.color = Color("#050407c8")
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.add_child(plate)
		hud.label(portrait, speaker_name, plate.position, plate.size, 18, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	return portrait

func _onboarding_rect(screen_id: String, node_name: String, fallback: Rect2) -> Rect2:
	if onboarding_flow.loaded:
		return onboarding_flow.screen_rect(screen_id, node_name, fallback)
	return fallback

func _onboarding_relative_rect(rect: Rect2, parent_rect: Rect2) -> Rect2:
	return Rect2(rect.position - parent_rect.position, rect.size)

func _onboarding_name_screen_comment() -> String:
	var entries = onboarding_flow.dialogue_for_trigger("screen_open", "LV01_NAME_ENTRY") if onboarding_flow.loaded else []
	if entries.is_empty():
		return "마왕명을 입력하고 확정하십시오."
	return _onboarding_line_text(entries[0])

func _onboarding_start_new_game() -> void:
	GameState.reset()
	logs.clear()
	_clear_units()
	_init_roster()
	_init_room_directives()
	selected_room = "entrance"
	selected_monster_id = "slime"
	onboarding_seen_dialogue_ids.clear()
	onboarding_boss_hp_thresholds.clear()
	onboarding_enabled = onboarding_flow.loaded
	tutorial_gate_enabled = true
	tutorial_manager.reset()
	_onboarding_set_stage("LV01_NAME_ENTRY")
	_set_screen(Constants.SCREEN_NAME_ENTRY)

func _onboarding_random_name() -> void:
	if onboarding_name_input == null:
		return
	var names = ["그림송곳", "밤안개", "불씨왕", "동굴남작", "작은파멸"]
	onboarding_name_input.text = names[randi() % names.size()]

func _onboarding_name_submitted(_text: String) -> void:
	_onboarding_confirm_name()

func _onboarding_confirm_name() -> void:
	if onboarding_name_input == null:
		return
	var player_name = onboarding_name_input.text.strip_edges()
	if player_name == "":
		_onboarding_show_name_comment("invalid_empty")
		return
	if player_name.length() > 12:
		_onboarding_show_name_comment("invalid_too_long")
		return
	GameState.player_name = player_name
	_tutorial_emit_action("name_valid", {"player_name": player_name})
	var entries: Array = []
	entries.append_array(onboarding_flow.dialogue_for_trigger("confirm_name", "LV01_NAME_ENTRY"))
	_onboarding_set_stage("LV02_OPENING_CUTSCENE")
	entries.append_array(onboarding_flow.dialogue_for_stage_triggers("LV02_OPENING_CUTSCENE", ONBOARDING_OPENING_TRIGGERS))
	_onboarding_begin_dialogue(entries, Constants.SCREEN_MANAGEMENT, ONBOARDING_ACTION_DAY1_MANAGEMENT)

func _onboarding_show_name_comment(trigger_id: String) -> void:
	var entries = onboarding_flow.dialogue_for_trigger(trigger_id, "LV01_NAME_ENTRY")
	if entries.is_empty() or onboarding_bati_comment_label == null:
		return
	onboarding_bati_comment_label.text = _onboarding_line_text(entries[0])

func _onboarding_begin_dialogue(entries: Array, return_screen: String, complete_action: String = ONBOARDING_ACTION_NONE) -> void:
	if entries.is_empty():
		_onboarding_complete_dialogue_action(complete_action, return_screen)
		return
	onboarding_dialogue_queue = entries
	onboarding_dialogue_index = 0
	onboarding_dialogue_return_screen = return_screen
	onboarding_dialogue_complete_action = complete_action
	_set_screen(Constants.SCREEN_DIALOGUE)

func _onboarding_advance_dialogue() -> void:
	if onboarding_dialogue_index + 1 < onboarding_dialogue_queue.size():
		onboarding_dialogue_index += 1
		_set_screen(Constants.SCREEN_DIALOGUE)
		return
	var return_screen = onboarding_dialogue_return_screen
	var complete_action = onboarding_dialogue_complete_action
	onboarding_dialogue_queue.clear()
	onboarding_dialogue_index = 0
	onboarding_dialogue_complete_action = ONBOARDING_ACTION_NONE
	_tutorial_emit_action("dialogue_closed", {"stage": onboarding_stage_id})
	_onboarding_complete_dialogue_action(complete_action, return_screen)

func _onboarding_complete_dialogue_action(action: String, return_screen: String) -> void:
	match action:
		ONBOARDING_ACTION_DAY1_MANAGEMENT:
			_onboarding_enter_management_day(1, true)
		_:
			_set_screen(return_screen)

func _onboarding_enter_management_day(day: int, show_dialogue: bool) -> void:
	GameState.day = day
	_onboarding_set_stage(_onboarding_management_stage_for_day(day))
	_set_screen(Constants.SCREEN_MANAGEMENT)
	if show_dialogue:
		call_deferred("_onboarding_emit_management_intro", day)

func _onboarding_emit_management_intro(day: int) -> void:
	if not onboarding_enabled:
		return
	var triggers: Array = ["management_open"]
	if day == 2:
		triggers.append("enemy_preview")
	if day == 3:
		triggers.append("recovery_nest_unlock")
	_onboarding_open_stage_dialogue(triggers, Constants.SCREEN_MANAGEMENT)

func _onboarding_emit_raid_preview_dialogue() -> void:
	if not onboarding_enabled or current_screen != Constants.SCREEN_RAID_PREVIEW:
		return
	_onboarding_open_stage_dialogue(["raid_preview_open"], Constants.SCREEN_RAID_PREVIEW)

func _onboarding_open_stage_dialogue(triggers: Array, return_screen: String) -> bool:
	if not onboarding_enabled or not onboarding_flow.loaded:
		return false
	var entries = _onboarding_collect_unseen_entries(onboarding_flow.dialogue_for_stage_triggers(onboarding_stage_id, triggers))
	if entries.is_empty():
		return false
	_onboarding_begin_dialogue(entries, return_screen)
	return true

func _onboarding_emit_trigger(trigger_id: String, stage_id: String = "") -> bool:
	if not onboarding_enabled or not onboarding_flow.loaded:
		return false
	var active_stage = stage_id if stage_id != "" else onboarding_stage_id
	var entries = _onboarding_collect_unseen_entries(onboarding_flow.dialogue_for_trigger(trigger_id, active_stage))
	if entries.is_empty():
		return false
	if current_screen == Constants.SCREEN_COMBAT:
		for entry in entries:
			_log(_onboarding_log_line(entry))
	else:
		_onboarding_begin_dialogue(entries, current_screen)
	return true

func _onboarding_collect_unseen_entries(entries: Array) -> Array:
	var result: Array = []
	for entry in entries:
		if not (entry is Dictionary):
			continue
		var line_id = str(entry.get("id", ""))
		if line_id != "" and onboarding_seen_dialogue_ids.has(line_id):
			continue
		if line_id != "":
			onboarding_seen_dialogue_ids[line_id] = true
		result.append(entry)
	return result

func _onboarding_line_text(line: Dictionary) -> String:
	return str(line.get("text", "")).replace("{{player_name}}", _onboarding_player_name())

func _onboarding_log_line(line: Dictionary) -> String:
	var speaker = _onboarding_speaker_name(str(line.get("speaker", "")))
	if speaker == "" or speaker == "나레이션":
		return _onboarding_line_text(line)
	return "%s: %s" % [speaker, _onboarding_line_text(line)]

func _onboarding_speaker_name(speaker_id: String) -> String:
	if speaker_id == "NARRATOR":
		return "나레이션"
	if speaker_id == "CHR_DARKLORD_PLAYER":
		return _onboarding_player_name()
	var character = DataRegistry.character(speaker_id)
	if not character.is_empty():
		return str(character.get("display_name", speaker_id))
	return speaker_id

func _onboarding_speaker_portrait_path(speaker_id: String, emotion: String = "") -> String:
	var portrait = _onboarding_speaker_portrait_data(speaker_id)
	if portrait.is_empty():
		return ""
	var selected_emotion = _onboarding_portrait_emotion_key(portrait, emotion)
	var variants: Dictionary = portrait.get("variants", {})
	if selected_emotion != "" and variants.has(selected_emotion):
		return str(variants[selected_emotion])
	return str(portrait.get("base", ""))

func _onboarding_speaker_accent(speaker_id: String) -> Color:
	var portrait = _onboarding_speaker_portrait_data(speaker_id)
	if portrait.is_empty():
		return Color("#57485e")
	return Color(str(portrait.get("accent", "#57485e")))

func _onboarding_speaker_portrait_data(speaker_id: String) -> Dictionary:
	var character = DataRegistry.character(speaker_id)
	if character.is_empty():
		return {}
	var portrait = character.get("portrait", {})
	if portrait is Dictionary:
		return portrait
	return {}

func _onboarding_portrait_emotion_key(portrait: Dictionary, emotion: String) -> String:
	if emotion == "":
		return ""
	var aliases: Dictionary = portrait.get("emotion_aliases", {})
	return str(aliases.get(emotion, emotion))

func _onboarding_dialogue_scene_path(line: Dictionary) -> String:
	var stage_id = str(line.get("stage", onboarding_stage_id))
	return str(ONBOARDING_SCENE_ILLUSTRATIONS.get(stage_id, ONBOARDING_SCENE_ILLUSTRATIONS["default"]))

func _onboarding_player_name() -> String:
	if GameState.player_name.strip_edges() == "":
		return "신입 마왕"
	return GameState.player_name

func _onboarding_set_stage(stage_id: String) -> void:
	onboarding_stage_id = stage_id
	GameState.onboarding_stage = stage_id

func _onboarding_management_stage_for_day(day: int) -> String:
	match day:
		1:
			return "LV03_DAY01_MANAGEMENT_TUTORIAL"
		2:
			return "LV06_DAY02_MANAGEMENT_TREASURE"
		3:
			return "LV09_DAY03_MANAGEMENT_HERO"
		_:
			return "LV12_DAY04_RAID_PREVIEW"

func _onboarding_battle_stage_for_day(day: int) -> String:
	match day:
		1:
			return "LV04_DAY01_BATTLE_EXPLORER"
		2:
			return "LV07_DAY02_BATTLE_THIEF"
		3:
			return "LV10_DAY03_BATTLE_HERO"
		_:
			return ""

func _onboarding_result_stage_for_day(day: int) -> String:
	match day:
		1:
			return "LV05_DAY01_RESULT"
		2:
			return "LV08_DAY02_RESULT"
		3:
			return "LV11_DAY03_RESULT_DEMO_CLEAR"
		_:
			return ""

func _onboarding_quit_requested() -> void:
	get_tree().quit()

func _onboarding_finish_raid_preview() -> void:
	GameState.onboarding_complete = true
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _debug_skip_onboarding() -> void:
	onboarding_enabled = false
	onboarding_dialogue_queue.clear()
	onboarding_seen_dialogue_ids.clear()
	tutorial_gate_enabled = false
	tutorial_manager.reset()
	GameState.onboarding_complete = true
	_onboarding_set_stage("")
	if _onboarding_screen_blocks_map_input():
		_set_screen(Constants.SCREEN_MANAGEMENT)

func _tutorial_build_overlay() -> void:
	_tutorial_clear_overlay()
	if not onboarding_enabled or not tutorial_manager.is_active_for_stage(onboarding_stage_id):
		return
	if current_screen == Constants.SCREEN_DIALOGUE:
		return
	var step = tutorial_manager.current_step()
	if step.is_empty():
		return
	var overlay = Panel.new()
	overlay.name = "TutorialOverlay"
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1920, 1080)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_theme_stylebox_override("panel", hud.style(Color("#00000000"), Color("#00000000"), 0))
	ui_layer.add_child(overlay)
	var focus_rect = _tutorial_focus_rect(str(step.get("focus", "")))
	if focus_rect.size.x > 0.0 and focus_rect.size.y > 0.0:
		var highlight = Panel.new()
		highlight.position = focus_rect.position
		highlight.size = focus_rect.size
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight.add_theme_stylebox_override("panel", hud.style(Color("#ffd36a22"), Color("#ffd36a"), 4))
		overlay.add_child(highlight)
	var message_rect = _tutorial_message_rect(focus_rect)
	var message_panel = Panel.new()
	message_panel.position = message_rect.position
	message_panel.size = message_rect.size
	message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_panel.add_theme_stylebox_override("panel", hud.style(Color("#100d14f2"), Color("#be72ff"), 2))
	overlay.add_child(message_panel)
	var title = "튜토리얼  %s" % str(step.get("id", ""))
	hud.label(message_panel, title, Vector2(22, 12), Vector2(message_rect.size.x - 44, 28), 16, Color("#ffd36a"))
	hud.label(message_panel, _onboarding_line_text(step), Vector2(22, 44), Vector2(message_rect.size.x - 44, message_rect.size.y - 58), 19, Color("#f7efe1"))

func _tutorial_clear_overlay() -> void:
	if ui_layer == null:
		return
	for child in ui_layer.get_children():
		if child.name == "TutorialOverlay":
			child.queue_free()

func _tutorial_message_rect(focus_rect: Rect2) -> Rect2:
	if focus_rect.size.x <= 0.0:
		return Rect2(560, 900, 800, 132)
	if focus_rect.position.y > 730:
		return Rect2(560, 86, 800, 132)
	return Rect2(560, 900, 800, 132)

func _tutorial_focus_rect(focus_id: String) -> Rect2:
	var registered_rect = _tutorial_registered_target_rect(focus_id)
	if registered_rect.size.x > 0.0 and registered_rect.size.y > 0.0:
		return registered_rect.grow(8)
	match focus_id:
		"NameInput":
			return _onboarding_rect("S01_NAME_ENTRY", "NameInput", Rect2(700, 420, 520, 64)).grow(10)
		"ROOM_THRONE":
			return _tutorial_room_rect("throne")
		"ROOM_ENTRANCE":
			return _tutorial_room_rect("entrance")
		"ROOM_TREASURE":
			return _tutorial_room_rect("treasure")
		"ROOM_RECOVERY_NEST":
			return _tutorial_room_rect("recovery")
		"CHR_PUDDING":
			return _tutorial_monster_rect("slime")
		"CHR_GOB":
			return _tutorial_monster_rect("goblin")
		"CHR_PYNN":
			return _tutorial_monster_rect("imp")
		"GLOBAL_DIRECTIVE_DEFEND":
			return Rect2(596, 932, 120, 66).grow(8)
		"ROOM_DIRECTIVE_BLOCK_ENTRANCE":
			return Rect2(1546, 766, 145, 34).grow(8) if current_screen == Constants.SCREEN_MANAGEMENT else Rect2(1056, 932, 136, 66).grow(8)
		"ROOM_DIRECTIVE_TRAP_LURE":
			return Rect2(1708, 766, 145, 34).grow(8) if current_screen == Constants.SCREEN_MANAGEMENT else Rect2(1056, 932, 136, 66).grow(8)
		"ROOM_DIRECTIVE_RETREAT_LINE":
			return Rect2(1546, 808, 145, 34).grow(8) if current_screen == Constants.SCREEN_MANAGEMENT else Rect2(1056, 932, 136, 66).grow(8)
		"DirectControlButton":
			return Rect2(1554, 746, 136, 52).grow(8)
		"BattleLogPanel":
			return Rect2(20, 710, 360, 288).grow(8)
		"BossHpBar":
			return Rect2(1460, 22, 360, 42).grow(8)
		"WorldMapPanel":
			return _onboarding_rect("S06_RAID_PREVIEW", "WorldMapPanel", Rect2(120, 100, 1080, 780)).grow(8)
		_:
			return Rect2()

func register_tutorial_target(target_id: String, rect: Rect2) -> void:
	if target_id == "":
		return
	tutorial_targets[target_id] = rect

func register_tutorial_target_control(target_id: String, control: Control, grow_amount: float = 0.0) -> void:
	if target_id == "" or control == null:
		return
	var rect = Rect2(control.global_position, control.size)
	if grow_amount != 0.0:
		rect = rect.grow(grow_amount)
	register_tutorial_target(target_id, rect)

func _tutorial_registered_target_rect(target_id: String) -> Rect2:
	if tutorial_targets.has(target_id):
		return tutorial_targets[target_id]
	return Rect2()

func _tutorial_room_rect(room_id: String) -> Rect2:
	if graph == null or not rooms.has(room_id):
		return Rect2()
	if current_screen == Constants.SCREEN_COMBAT:
		var center = _combat_world_to_screen(graph.center(room_id))
		return Rect2(center - Vector2(70, 50), Vector2(140, 100))
	return graph.rect(room_id).grow(12)

func _tutorial_monster_rect(monster_id: String) -> Rect2:
	if current_screen == Constants.SCREEN_MONSTER:
		var order = ["slime", "goblin", "imp"]
		var index = order.find(monster_id)
		if index >= 0:
			return Rect2(48, 196 + index * 90, 460, 76).grow(8)
	if current_screen == Constants.SCREEN_COMBAT:
		for unit in monster_units:
			if unit.unit_id == monster_id and is_instance_valid(unit):
				var screen_pos = _combat_world_to_screen(unit.global_position)
				return Rect2(screen_pos - Vector2(48, 64), Vector2(96, 110))
	var point = _management_monster_preview_position(monster_id)
	if point == Vector2.INF:
		return Rect2()
	return Rect2(point - Vector2(54, 64), Vector2(108, 128))

func _tutorial_allows(action_id: String, payload: Dictionary = {}) -> bool:
	if not onboarding_enabled or not tutorial_gate_enabled:
		return true
	if not tutorial_manager.is_active_for_stage(onboarding_stage_id):
		return true
	if tutorial_manager.allows_action(action_id, payload):
		return true
	var step = tutorial_manager.current_step()
	_log("튜토리얼 진행 중입니다: %s" % _onboarding_line_text(step))
	_tutorial_build_overlay()
	return false

func _tutorial_emit_action(action_id: String, payload: Dictionary = {}) -> void:
	SignalBus.emit_tutorial_action(action_id, payload)

func _on_tutorial_action(action_id: String, payload: Dictionary) -> void:
	if not onboarding_enabled:
		return
	var advanced = tutorial_manager.handle_action(action_id, payload)
	if advanced:
		_tutorial_build_overlay()

func _clear_ui() -> void:
	hud.clear()

func _build_management_ui() -> void:
	management_scene.build_management_ui()

func _build_monster_ui() -> void:
	management_scene.build_monster_ui()

func _build_combat_ui() -> void:
	combat_scene.build_combat_ui()

func _build_result_ui() -> void:
	management_scene.build_result_ui()

func _build_top_bar() -> void:
	hud.build_top_bar()

func _build_room_list(x: int, y: int, w: int, h: int) -> void:
	hud.build_room_list(x, y, w, h)

func _build_selected_room_info(parent: Control) -> void:
	hud.build_selected_room_info(parent)

func _build_stat_lines(parent: Control, monster: Dictionary, roster: Dictionary) -> void:
	hud.build_stat_lines(parent, monster, roster)

func _build_log_panel() -> void:
	hud.build_log_panel()

func _build_selected_unit_panel() -> void:
	hud.build_selected_unit_panel()

func _build_command_panel() -> void:
	hud.build_command_panel()

func _build_speed_panel() -> void:
	hud.build_speed_panel()

func _rebuild_combat_ui_light() -> void:
	if int(combat_time * 4.0) % 4 != 0:
		return

func _reset_combat_view() -> void:
	combat_view_zoom = 1.0
	if combat_camera == null:
		return
	combat_camera.position = COMBAT_CAMERA_HOME
	combat_camera.zoom = Vector2.ONE

func _update_combat_camera_enabled() -> void:
	if combat_camera == null:
		return
	var enabled = current_screen == Constants.SCREEN_COMBAT
	combat_camera.enabled = enabled
	if enabled:
		combat_camera.make_current()

func _adjust_combat_zoom(direction: int, screen_point: Vector2) -> void:
	if current_screen != Constants.SCREEN_COMBAT or combat_camera == null:
		return
	if _combat_ui_at(screen_point):
		return
	var focus_world = _combat_screen_to_world(screen_point)
	var next_zoom = combat_view_zoom * (COMBAT_ZOOM_STEP if direction > 0 else 1.0 / COMBAT_ZOOM_STEP)
	combat_view_zoom = clamp(next_zoom, COMBAT_ZOOM_MIN, COMBAT_ZOOM_MAX)
	combat_camera.zoom = Vector2(combat_view_zoom, combat_view_zoom)
	var viewport_size = get_viewport().get_visible_rect().size
	combat_camera.position = focus_world - (screen_point - viewport_size * 0.5) / combat_view_zoom
	queue_redraw()

func _combat_screen_to_world(screen_point: Vector2) -> Vector2:
	if current_screen != Constants.SCREEN_COMBAT or combat_camera == null or not combat_camera.enabled:
		return screen_point
	var viewport_size = get_viewport().get_visible_rect().size
	return combat_camera.position + (screen_point - viewport_size * 0.5) / combat_view_zoom

func _combat_world_to_screen(world_point: Vector2) -> Vector2:
	if combat_camera == null:
		return world_point
	var viewport_size = get_viewport().get_visible_rect().size
	return (world_point - combat_camera.position) * combat_view_zoom + viewport_size * 0.5

func _clamp_to_combat_walkable(point: Vector2) -> Vector2:
	if graph == null or not graph.has_method("clamp_to_walkable"):
		return point
	return graph.clamp_to_walkable(point)

func _handle_left_click(point: Vector2, screen_point: Vector2 = Vector2(-99999, -99999)) -> void:
	if current_screen == Constants.SCREEN_COMBAT:
		if screen_point.x > -90000 and _combat_ui_at(screen_point):
			return
		var unit = _unit_at(point)
		if unit != null:
			_select_unit(unit)
		return
	if screen_point.x > -90000 and _management_ui_at(screen_point):
		return
	var room_id = _room_at(point)
	if room_id != "":
		if map_editor_active and _map_editor_select_gap_path_candidate_to(room_id):
			return
		_select_room(room_id)

func _handle_right_click(point: Vector2, screen_point: Vector2 = Vector2(-99999, -99999)) -> void:
	if current_screen != Constants.SCREEN_COMBAT:
		return
	if screen_point.x > -90000 and _combat_ui_at(screen_point):
		return
	if selected_unit == null or selected_unit.faction != Constants.FACTION_MONSTER:
		return
	var enemy_target = _enemy_at(point)
	if enemy_target != null:
		selected_unit.command_attack(enemy_target)
		if graph != null and graph.has_method("path_to_point"):
			var target_point = _clamp_to_combat_walkable(enemy_target.global_position)
			selected_unit.set_path(graph.path_to_point(selected_unit.global_position, target_point))
		_log("%s 직접 공격 지정: %s." % [selected_unit.display_name, enemy_target.display_name])
		return
	selected_unit.command_move(_clamp_to_combat_walkable(point))
	_log("%s 직접 이동 명령." % selected_unit.display_name)

func _handle_key(keycode: int) -> void:
	if current_screen == Constants.SCREEN_DIALOGUE:
		if keycode == KEY_SPACE or keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
			_onboarding_advance_dialogue()
		return
	match keycode:
		KEY_SPACE:
			if current_screen == Constants.SCREEN_COMBAT:
				_toggle_pause()
		KEY_TAB:
			_select_next_monster_unit()
		KEY_1:
			_use_selected_skill(0)
		KEY_2:
			_use_selected_skill(1)
		KEY_3:
			_use_selected_skill(2)
		KEY_F3:
			_toggle_quarter_debug_overlay("active")
		KEY_F4:
			_toggle_quarter_debug_overlay("walkable")
		KEY_F5:
			_toggle_quarter_debug_overlay("floor_mask")
		KEY_F6:
			_toggle_quarter_debug_overlay("sockets")
		KEY_F7:
			_toggle_quarter_debug_overlay("room_id")
		KEY_F8:
			_toggle_quarter_debug_overlay("cursor")
		KEY_F9:
			_toggle_quarter_debug_overlay("path")
		KEY_ESCAPE:
			if current_screen == Constants.SCREEN_MONSTER:
				_set_screen(Constants.SCREEN_MANAGEMENT)

func _toggle_quarter_debug_overlay(overlay_id: String) -> void:
	match overlay_id:
		"active":
			debug_show_active_overlay = not debug_show_active_overlay
			_log("활성 셀 표시 %s." % ("ON" if debug_show_active_overlay else "OFF"))
		"sockets":
			debug_show_socket_overlay = not debug_show_socket_overlay
			_log("소켓 디버그 표시 %s." % ("ON" if debug_show_socket_overlay else "OFF"))
		"modules":
			debug_show_quarter_module_overlay = not debug_show_quarter_module_overlay
			_log("모듈 외곽선 표시 %s." % ("ON" if debug_show_quarter_module_overlay else "OFF"))
		"walkable":
			debug_show_walkable_overlay = not debug_show_walkable_overlay
			_log("보행 가능 셀 표시 %s." % ("ON" if debug_show_walkable_overlay else "OFF"))
		"floor_mask":
			debug_show_floor_mask_overlay = not debug_show_floor_mask_overlay
			_log("바닥 마스크 표시 %s." % ("ON" if debug_show_floor_mask_overlay else "OFF"))
		"room_id":
			debug_show_room_id_overlay = not debug_show_room_id_overlay
			_log("방 ID 표시 %s." % ("ON" if debug_show_room_id_overlay else "OFF"))
		"blocked":
			debug_show_blocked_overlay = not debug_show_blocked_overlay
			_log("차단 셀 표시 %s." % ("ON" if debug_show_blocked_overlay else "OFF"))
		"cursor":
			debug_show_cursor_cell = not debug_show_cursor_cell
			_log("선택 유닛/커서 셀 표시 %s." % ("ON" if debug_show_cursor_cell else "OFF"))
		"path":
			debug_show_path_overlay = not debug_show_path_overlay
			_log("경로 라인 표시 %s." % ("ON" if debug_show_path_overlay else "OFF"))
	queue_redraw()

func _start_combat() -> void:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 전투를 시작하세요.")
		return
	if not _tutorial_allows("combat_started", {"day": GameState.day}):
		return
	if not _ensure_required_main_route_for_current_layout("전투 시작"):
		return
	if onboarding_enabled:
		_onboarding_set_stage(_onboarding_battle_stage_for_day(GameState.day))
		onboarding_boss_hp_thresholds.clear()
		onboarding_treasure_stolen_this_day = false
	combat_scene.start_combat()
	_tutorial_emit_action("combat_started", {"day": GameState.day})
	if onboarding_enabled and GameState.day == 1:
		_onboarding_emit_trigger("direct_control_prompt")

func _spawn_monsters() -> void:
	combat_scene.spawn_monsters()

func _spawn_ready_enemies(delta: float) -> void:
	combat_scene.spawn_ready_enemies(delta)

func _spawn_enemy(enemy_id: String) -> void:
	combat_scene.spawn_enemy(enemy_id)

func _create_unit(source_id: String, stats: Dictionary, faction: String, room_id: String) -> Node:
	var unit = UnitActorScript.new()
	unit_root.add_child(unit)
	unit.setup(source_id, stats, faction, room_id)
	unit.downed.connect(_on_unit_downed)
	return unit

func _scaled_monster_stats(monster_id: String) -> Dictionary:
	var stats = DataRegistry.monster(monster_id).duplicate(true)
	var roster: Dictionary = monster_roster[monster_id]
	var level = int(roster["level"])
	stats["max_hp"] = int(stats.get("max_hp", 100)) + (level - 1) * 20
	stats["atk"] = int(stats.get("atk", 10)) + (level - 1) * 3
	stats["def"] = int(stats.get("def", 0)) + (level - 1)
	return stats

func _clear_units() -> void:
	for unit in monster_units + enemy_units:
		if is_instance_valid(unit):
			unit.queue_free()
	monster_units.clear()
	enemy_units.clear()
	selected_unit = null

func _clear_effects() -> void:
	combat_scene.clear_effects()

func _refresh_unit_rooms() -> void:
	combat_scene.refresh_unit_rooms()

func _update_ai_paths() -> void:
	combat_scene.update_ai_paths()

func _update_monster_path(unit: Node) -> void:
	combat_scene.update_monster_path(unit)

func _update_enemy_path(unit: Node) -> void:
	combat_scene.update_enemy_path(unit)

func _nearest_enemy_in_rooms(unit: Node, room_ids: Array) -> Node:
	return combat_scene.nearest_enemy_in_rooms(unit, room_ids)

func _nearest_monster_in_rooms(unit: Node, room_ids: Array) -> Node:
	return combat_scene.nearest_monster_in_rooms(unit, room_ids)

func _move_unit_to_room(unit: Node, room_id: String) -> void:
	combat_scene.move_unit_to_room(unit, room_id)

func _move_unit_to_point(unit: Node, point: Vector2) -> void:
	combat_scene.move_unit_to_point(unit, point)

func _update_room_effects(delta: float) -> void:
	combat_scene.update_room_effects(delta)

func _update_attacks(delta: float) -> void:
	combat_scene.update_attacks(delta)

func _try_attack(attacker: Node, opponents: Array) -> void:
	combat_scene.try_attack(attacker, opponents)

func _on_unit_downed(unit: Node) -> void:
	combat_scene.on_unit_downed(unit)

func _check_combat_end() -> void:
	combat_scene.check_combat_end()

func _finish_combat(win: bool, reason: String) -> void:
	combat_scene.finish_combat(win, reason)

func _count_downed_enemies() -> int:
	return combat_scene.count_downed_enemies()

func _advance_after_result() -> void:
	GameState.advance_day()
	_tutorial_emit_action("day_advanced", {"day": GameState.day})
	if onboarding_enabled:
		_onboarding_enter_management_day(GameState.day, true)
	else:
		_set_screen(Constants.SCREEN_MANAGEMENT)

func _continue_from_result() -> void:
	if onboarding_enabled:
		if GameState.victory and GameState.day >= GameState.max_day:
			GameState.day = 4
			_onboarding_set_stage("LV12_DAY04_RAID_PREVIEW")
			_set_screen(Constants.SCREEN_RAID_PREVIEW)
			return
		if not GameState.defeat and GameState.day < GameState.max_day:
			_advance_after_result()
			return
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _advance_day_from_management() -> void:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 날짜를 진행하세요.")
		return
	if not _tutorial_allows("day_advanced", {"day": GameState.day + 1}):
		return
	if not _ensure_required_main_route_for_current_layout("날짜 진행"):
		return
	GameState.advance_day()
	_tutorial_emit_action("day_advanced", {"day": GameState.day})
	_log("하루를 넘겼습니다. DAY %d." % GameState.day)
	if onboarding_enabled:
		_onboarding_enter_management_day(GameState.day, true)
	else:
		_set_screen(Constants.SCREEN_MANAGEMENT)

func _open_monster_screen() -> void:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 몬스터 관리를 여세요.")
		return
	_set_screen(Constants.SCREEN_MONSTER)

func _select_monster(monster_id: String) -> void:
	selected_monster_id = monster_id
	_tutorial_emit_action("unit_selected", {"monster_id": monster_id, "unit_id": monster_id})
	_set_screen(Constants.SCREEN_MONSTER)
	if onboarding_enabled:
		match monster_id:
			"slime":
				_onboarding_emit_trigger("select_slime")
			"goblin":
				_onboarding_emit_trigger("select_goblin")
			"imp":
				_onboarding_emit_trigger("select_imp")

func _train_selected_monster() -> void:
	if not GameState.pay({"gold": 30}):
		_log("훈련 비용이 부족합니다.")
		return
	var roster: Dictionary = monster_roster[selected_monster_id]
	roster["exp"] = int(roster["exp"]) + 20
	var need = 50 + (int(roster["level"]) - 1) * 30
	if int(roster["exp"]) >= need:
		roster["exp"] = int(roster["exp"]) - need
		roster["level"] = int(roster["level"]) + 1
		_log("%s 레벨 업." % DataRegistry.monster(selected_monster_id).get("display_name", selected_monster_id))
	else:
		_log("%s 훈련 완료." % DataRegistry.monster(selected_monster_id).get("display_name", selected_monster_id))
	_set_screen(Constants.SCREEN_MONSTER)

func _place_selected_monster() -> void:
	if _assign_monster_to_room(selected_monster_id, selected_room):
		_set_screen(current_screen)

func _placement_count(room_id: String, ignore_monster_id: String = "") -> int:
	var count = 0
	for monster_id in monster_roster.keys():
		if monster_id == ignore_monster_id:
			continue
		if monster_roster[monster_id].get("room", "") == room_id:
			count += 1
	return count

func _assign_monster_to_room(monster_id: String, room_id: String) -> bool:
	if not monster_roster.has(monster_id) or not rooms.has(room_id):
		return false
	if not _tutorial_allows("unit_deployed", {"monster_id": monster_id, "unit_id": monster_id, "room_id": room_id}):
		return false
	if str(monster_roster[monster_id].get("room", "")) == room_id:
		selected_monster_id = monster_id
		selected_room = room_id
		_tutorial_emit_action("unit_deployed", {"monster_id": monster_id, "unit_id": monster_id, "room_id": room_id})
		return true
	if rooms[room_id].get("type", "") == "build_slot":
		_log("비어 있는 건설 슬롯에는 배치할 수 없습니다.")
		return false
	if _placement_count(room_id, monster_id) >= int(rooms[room_id].get("max_monsters", 1)):
		_log("선택 방의 배치 한도가 찼습니다.")
		return false
	monster_roster[monster_id]["room"] = room_id
	selected_monster_id = monster_id
	selected_room = room_id
	_log("%s을(를) %s에 배치했습니다." % [DataRegistry.monster(monster_id).get("display_name", monster_id), rooms[room_id].get("display_name", room_id)])
	_tutorial_emit_action("unit_deployed", {"monster_id": monster_id, "unit_id": monster_id, "room_id": room_id})
	if onboarding_enabled:
		_onboarding_emit_trigger("unit_deployed")
	return true

func _build_selected_slot() -> void:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 건설하세요.")
		return
	if rooms[selected_room].get("type", "") != "build_slot":
		_log("건설 가능한 슬롯을 선택하세요.")
		return
	_change_selected_room_facility("watch_post")

func _facility_choices() -> Array:
	return FACILITY_CHOICES.duplicate()

func _facility_short_label(facility_id: String) -> String:
	return _facility_definition(facility_id).get("short_label", facility_id)

func _facility_cost_label(facility_id: String) -> String:
	return _cost_label(_facility_definition(facility_id).get("cost", {}))

func _can_change_room_facility(room_id: String) -> bool:
	if not rooms.has(room_id):
		return false
	return not LOCKED_FACILITY_ROOMS.has(room_id)

func _room_by_facility(facility_id: String, fallback: String = "") -> String:
	for room_id in rooms.keys():
		if str(rooms[room_id].get("facility_role", "")) == facility_id:
			return room_id
	return fallback

func _room_by_type(room_type: String, fallback: String = "") -> String:
	for room_id in rooms.keys():
		if str(rooms[room_id].get("type", "")) == room_type:
			return room_id
	return fallback

func _change_selected_room_facility(facility_id: String) -> void:
	if map_editor_active:
		_log("맵 편집을 저장하거나 취소한 뒤 시설을 변경하세요.")
		return
	if not _can_change_room_facility(selected_room):
		_log("입구, 가시 복도, 중앙 통로, 왕좌의 방은 변경할 수 없습니다.")
		return
	var definition = _facility_definition(facility_id)
	if definition.is_empty():
		return
	if str(rooms[selected_room].get("facility_role", "")) == facility_id:
		_log("이미 %s입니다." % definition.get("display_name", facility_id))
		return
	var old_name = str(rooms[selected_room].get("display_name", selected_room))
	var cost: Dictionary = definition.get("cost", {})
	if not GameState.pay(cost):
		_log("시설 변경 비용이 부족합니다. 필요: %s." % _cost_label(cost))
		return
	var replaced_rooms: Array[String] = []
	if UNIQUE_FACILITIES.has(facility_id):
		for room_id in rooms.keys():
			if room_id == selected_room:
				continue
			if str(rooms[room_id].get("facility_role", "")) == facility_id and _can_change_room_facility(room_id):
				_apply_facility_to_room(room_id, "build_slot")
				replaced_rooms.append(room_id)
	_apply_facility_to_room(selected_room, facility_id)
	_relocate_invalid_monsters()
	var moved_text = ""
	if not replaced_rooms.is_empty():
		moved_text = " 기존 %s 위치는 빈 슬롯으로 바뀌었습니다." % definition.get("display_name", facility_id)
	_refresh_quarter_map_from_rooms()
	_log("%s을(를) %s로 변경했습니다.%s" % [old_name, definition.get("display_name", facility_id), moved_text])
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _refresh_quarter_map_from_rooms() -> void:
	if not use_quarter_module_map:
		return
	_setup_dungeon_graph()
	if quarter_renderer != null and quarter_renderer.has_method("refresh_layout"):
		quarter_renderer.refresh_layout()
	queue_redraw()

func _facility_definition(facility_id: String) -> Dictionary:
	match facility_id:
		"barracks":
			return {
				"display_name": "병영",
				"short_label": "병영",
				"type": "support",
				"hp": 450,
				"max_monsters": 4,
				"icon": "res://assets/ui/room_v2/room_v2_barracks.png",
				"icon_offset": [0, -8],
				"icon_size": 54,
				"cost": {"gold": 100, "food": 2}
			}
		"treasure":
			return {
				"display_name": "보물 보관실",
				"short_label": "보물고",
				"type": "bait",
				"hp": 250,
				"max_monsters": 2,
				"bait_priority": 80,
				"icon": "res://assets/ui/room_v2/room_v2_treasure.png",
				"icon_offset": [0, -8],
				"icon_size": 58,
				"cost": {"gold": 120}
			}
		"recovery":
			return {
				"display_name": "회복 둥지",
				"short_label": "회복",
				"type": "recovery",
				"hp": 350,
				"max_monsters": 2,
				"icon": "res://assets/ui/room_v2/room_v2_recovery.png",
				"icon_offset": [0, -8],
				"icon_size": 58,
				"cost": {"mana": 80}
			}
		"watch_post":
			return {
				"display_name": "감시 초소",
				"short_label": "감시",
				"type": "support",
				"hp": 380,
				"max_monsters": 3,
				"icon": "res://assets/ui/room_v2/room_v2_watch_post.png",
				"icon_offset": [0, -8],
				"icon_size": 54,
				"cost": {"gold": 100, "mana": 50}
			}
		"build_slot":
			return {
				"display_name": "건설 슬롯",
				"short_label": "빈 슬롯",
				"type": "build_slot",
				"hp": 200,
				"max_monsters": 1,
				"icon": "res://assets/ui/room_v2/room_v2_build_slot.png",
				"icon_offset": [0, -4],
				"icon_size": 50,
				"cost": {}
			}
	return {}

func _apply_facility_to_room(room_id: String, facility_id: String) -> void:
	var definition = _facility_definition(facility_id)
	if definition.is_empty() or not rooms.has(room_id):
		return
	var room: Dictionary = rooms[room_id]
	room["facility_role"] = facility_id
	room["display_name"] = definition.get("display_name", room.get("display_name", room_id))
	room["type"] = definition.get("type", room.get("type", "support"))
	room["hp"] = int(definition.get("hp", room.get("hp", 200)))
	room["max_monsters"] = int(definition.get("max_monsters", room.get("max_monsters", 1)))
	room["icon"] = definition.get("icon", room.get("icon", ""))
	room["icon_offset"] = definition.get("icon_offset", room.get("icon_offset", [0, -8]))
	room["icon_size"] = int(definition.get("icon_size", room.get("icon_size", 54)))
	room.erase("bait_priority")
	room.erase("build_slot_id")
	if definition.has("bait_priority"):
		room["bait_priority"] = definition["bait_priority"]
	if facility_id == "build_slot":
		room["build_slot_id"] = room_id

func _relocate_invalid_monsters() -> void:
	var room_counts: Dictionary = {}
	for monster_id in monster_roster.keys():
		var room_id = str(monster_roster[monster_id].get("room", ""))
		if not _room_accepts_monsters(room_id):
			var fallback = _first_available_monster_room(monster_id, room_counts)
			monster_roster[monster_id]["room"] = fallback
			room_counts[fallback] = int(room_counts.get(fallback, 0)) + 1
			continue
		var count = int(room_counts.get(room_id, 0))
		if count >= int(rooms[room_id].get("max_monsters", 1)):
			var overflow_target = _first_available_monster_room(monster_id, room_counts)
			monster_roster[monster_id]["room"] = overflow_target
			room_counts[overflow_target] = int(room_counts.get(overflow_target, 0)) + 1
		else:
			room_counts[room_id] = count + 1

func _room_accepts_monsters(room_id: String) -> bool:
	return rooms.has(room_id) and rooms[room_id].get("type", "") != "build_slot"

func _first_available_monster_room(monster_id: String, room_counts: Dictionary = {}) -> String:
	var preferred = [str(monster_roster.get(monster_id, {}).get("room", "")), "entrance", "barracks", "recovery", "treasure", "throne", "slot_01"]
	for room_id in preferred:
		if not _room_accepts_monsters(room_id):
			continue
		var used = int(room_counts.get(room_id, _placement_count(room_id, monster_id)))
		if used < int(rooms[room_id].get("max_monsters", 1)):
			return room_id
	return "entrance"

func _cost_label(cost: Dictionary) -> String:
	var parts: Array[String] = []
	if int(cost.get("gold", 0)) > 0:
		parts.append("금화 %d" % int(cost.get("gold", 0)))
	if int(cost.get("mana", 0)) > 0:
		parts.append("마력 %d" % int(cost.get("mana", 0)))
	if int(cost.get("food", 0)) > 0:
		parts.append("식량 %d" % int(cost.get("food", 0)))
	if int(cost.get("infamy", 0)) > 0:
		parts.append("악명 %d" % int(cost.get("infamy", 0)))
	if parts.is_empty():
		return "무료"
	return " / ".join(parts)

func _select_room(room_id: String) -> void:
	selected_room = room_id
	if map_editor_active:
		map_editor_path_candidate_index = 0
	SignalBus.room_selected.emit(room_id)
	_tutorial_emit_action("room_selected", {"room_id": room_id})
	if current_screen == Constants.SCREEN_COMBAT:
		_set_screen(Constants.SCREEN_COMBAT)
	else:
		_set_screen(current_screen)
	queue_redraw()

func _select_unit(unit: Node) -> void:
	if selected_unit != null and is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	selected_unit = unit
	selected_unit.set_selected(true)
	SignalBus.unit_selected.emit(unit)
	_tutorial_emit_action("unit_selected", {"unit_id": unit.unit_id, "room_id": unit.current_room, "faction": unit.faction})
	if current_screen == Constants.SCREEN_COMBAT:
		_set_screen(Constants.SCREEN_COMBAT)

func _select_next_monster_unit() -> void:
	if monster_units.is_empty():
		return
	var alive: Array = []
	for unit in monster_units:
		if unit.is_alive():
			alive.append(unit)
	if alive.is_empty():
		return
	var index = alive.find(selected_unit)
	index = (index + 1) % alive.size()
	_select_unit(alive[index])

func _set_global_directive(directive: String) -> void:
	if not _tutorial_allows("global_directive_set", {"directive": directive}):
		return
	combat_scene.set_global_directive(directive)
	_tutorial_emit_action("global_directive_set", {"directive": directive})
	if onboarding_enabled:
		match directive:
			Constants.DIRECTIVE_DEFENSE:
				_onboarding_emit_trigger("global_directive_defend")
			Constants.DIRECTIVE_SURVIVAL:
				_onboarding_emit_trigger("survival_priority")

func _set_room_directive(directive: String) -> void:
	if not _tutorial_allows("room_directive_set", {"directive": directive, "room_id": selected_room}):
		return
	combat_scene.set_room_directive(directive)
	_tutorial_emit_action("room_directive_set", {"directive": directive, "room_id": selected_room})
	if onboarding_enabled:
		match directive:
			Constants.ROOM_DIRECTIVE_ENTRY_BLOCK:
				_onboarding_emit_trigger("room_directive_block")
			Constants.ROOM_DIRECTIVE_TRAP_LURE:
				_onboarding_emit_trigger("trap_lure")
			Constants.ROOM_DIRECTIVE_RETREAT:
				_onboarding_emit_trigger("retreat_line")

func _enable_direct_control() -> void:
	if not _tutorial_allows("direct_control_once", {"unit_id": selected_unit.unit_id if selected_unit != null else ""}):
		return
	combat_scene.enable_direct_control()
	_tutorial_emit_action("direct_control_once", {"unit_id": selected_unit.unit_id if selected_unit != null else ""})
	if onboarding_enabled:
		_onboarding_emit_trigger("direct_control_start")

func _release_direct_control() -> void:
	combat_scene.release_direct_control()

func _use_selected_skill(slot: int) -> void:
	var used_skill_id = ""
	if selected_unit != null and selected_unit.faction == Constants.FACTION_MONSTER:
		var skills: Array = DataRegistry.monster(selected_unit.unit_id).get("skill_slots", [])
		if slot >= 0 and slot < skills.size() and skills[slot] != null:
			used_skill_id = str(skills[slot])
	var tutorial_action_id = "imp_casts_fireball" if used_skill_id == "fireball" else "skill_used"
	if not _tutorial_allows(tutorial_action_id, {"skill_id": used_skill_id, "unit_id": selected_unit.unit_id if selected_unit != null else ""}):
		return
	combat_scene.use_selected_skill(slot)
	if onboarding_enabled and used_skill_id == "fireball":
		_tutorial_emit_action("imp_casts_fireball", {"skill_id": used_skill_id, "unit_id": selected_unit.unit_id if selected_unit != null else ""})
		_onboarding_emit_trigger("imp_fireball")

func _onboarding_enemy_spawned(enemy_id: String) -> void:
	if not onboarding_enabled:
		return
	if enemy_id == "trainee_hero":
		_onboarding_emit_trigger("boss_spawn")
	elif GameState.day == 1 and enemy_id == "explorer":
		_onboarding_emit_trigger("enemy_spawn")
	elif GameState.day == 2 and enemy_id == "thief":
		_onboarding_emit_trigger("enemy_spawn")

func _onboarding_trap_triggered() -> void:
	_onboarding_emit_trigger("trap_triggered")

func _onboarding_treasure_stolen() -> void:
	onboarding_treasure_stolen_this_day = true
	_onboarding_emit_trigger("treasure_stolen")

func _onboarding_unit_retreat(unit: Node) -> void:
	if not onboarding_enabled or unit == null:
		return
	if unit.unit_id == "slime":
		_onboarding_emit_trigger("slime_low_hp_retreat")
	_onboarding_emit_trigger("unit_retreat")

func _onboarding_unit_damaged(unit: Node) -> void:
	if not onboarding_enabled or unit == null or not is_instance_valid(unit):
		return
	if unit.max_hp <= 0:
		return
	var hp_ratio = float(unit.hp) / float(unit.max_hp)
	if unit.faction == Constants.FACTION_ENEMY and unit.unit_id == "trainee_hero":
		_onboarding_emit_boss_hp_threshold(hp_ratio)
	elif unit.faction == Constants.FACTION_ENEMY and hp_ratio <= 0.35:
		_onboarding_emit_trigger("low_hp")

func _onboarding_emit_boss_hp_threshold(hp_ratio: float) -> void:
	var thresholds = [
		{"key": "75", "ratio": 0.75, "trigger": "boss_hp_75"},
		{"key": "50", "ratio": 0.50, "trigger": "boss_hp_50"},
		{"key": "25", "ratio": 0.25, "trigger": "boss_hp_25"}
	]
	for threshold in thresholds:
		var key = str(threshold["key"])
		if onboarding_boss_hp_thresholds.has(key):
			continue
		if hp_ratio <= float(threshold["ratio"]):
			onboarding_boss_hp_thresholds[key] = true
			if key == "50":
				_tutorial_emit_action("boss_hp_50", {"hp_ratio": hp_ratio})
			_onboarding_emit_trigger(str(threshold["trigger"]))

func _onboarding_battle_finished(win: bool) -> void:
	if not onboarding_enabled:
		return
	_tutorial_emit_action("battle_finished", {"win": win, "day": GameState.day})
	if win:
		_onboarding_set_stage(_onboarding_result_stage_for_day(GameState.day))
		var triggers: Array = []
		if GameState.day == 2 and not onboarding_treasure_stolen_this_day:
			triggers.append("win_no_treasure_loss")
		triggers.append("win")
		_onboarding_open_stage_dialogue(triggers, Constants.SCREEN_RESULT)
	else:
		_onboarding_set_stage(_onboarding_battle_stage_for_day(GameState.day))
		_onboarding_open_stage_dialogue(["lose"], Constants.SCREEN_RESULT)

func _set_speed(speed: float) -> void:
	combat_scene.set_speed(speed)

func _toggle_pause() -> void:
	combat_scene.toggle_pause()

func _unit_at(point: Vector2) -> Node:
	var best: Node = null
	var best_distance = 36.0
	for unit in monster_units + enemy_units:
		if not unit.is_alive():
			continue
		var distance = unit.global_position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = unit
	return best

func _enemy_at(point: Vector2) -> Node:
	var best: Node = null
	var best_distance = 36.0
	for unit in enemy_units:
		if not unit.is_alive():
			continue
		var distance = unit.global_position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = unit
	return best

func _combat_ui_at(point: Vector2) -> bool:
	if current_screen != Constants.SCREEN_COMBAT:
		return false
	var rects = [
		Rect2(16, 10, 1870, 70),
		Rect2(20, 105, 300, 385),
		Rect2(20, 500, 360, 200),
		Rect2(20, 710, 360, 288),
		Rect2(1518, 142, 370, 710),
		Rect2(560, 884, 860, 142),
		Rect2(1438, 884, 74, 142)
	]
	for rect in rects:
		if rect.has_point(point):
			return true
	return false

func _management_ui_at(point: Vector2) -> bool:
	if current_screen != Constants.SCREEN_MANAGEMENT:
		return false
	var rects = [
		Rect2(16, 10, 1870, 70),
		Rect2(16, 530, 300, 342),
		Rect2(98, 880, 1725, 142),
		Rect2(1518, 92, 370, 760)
	]
	for rect in rects:
		if rect.has_point(point):
			return true
	return false

func _room_at(point: Vector2) -> String:
	if graph != null and graph.has_method("room_at_world"):
		var room_id = str(graph.room_at_world(point))
		if room_id != "":
			return room_id
	var best_room = ""
	var best_area = INF
	for room_id in rooms.keys():
		var rect = graph.rect(room_id)
		if not rect.has_point(point):
			continue
		var area = rect.size.x * rect.size.y
		if area < best_area:
			best_area = area
			best_room = room_id
	return best_room

func _start_management_monster_drag(point: Vector2) -> bool:
	var monster_id = _management_monster_at(point)
	if monster_id == "":
		return false
	dragging_monster_id = monster_id
	drag_monster_position = point
	drag_start_position = point
	drag_hover_room = _room_at(point)
	selected_monster_id = monster_id
	var current_room = str(monster_roster[monster_id].get("room", ""))
	if rooms.has(current_room):
		selected_room = current_room
	_tutorial_emit_action("unit_selected", {"monster_id": monster_id, "unit_id": monster_id, "room_id": current_room})
	queue_redraw()
	return true

func _update_management_monster_drag(point: Vector2) -> void:
	drag_monster_position = point
	drag_hover_room = _room_at(point)
	queue_redraw()

func _finish_management_monster_drag(point: Vector2) -> void:
	var monster_id = dragging_monster_id
	var room_id = _room_at(point)
	dragging_monster_id = ""
	drag_hover_room = ""
	drag_monster_position = Vector2.ZERO
	var current_room = str(monster_roster.get(monster_id, {}).get("room", ""))
	if point.distance_to(drag_start_position) < 8.0:
		if rooms.has(current_room):
			selected_room = current_room
		_set_screen(Constants.SCREEN_MANAGEMENT)
		return
	drag_start_position = Vector2.ZERO
	if room_id != "":
		_assign_monster_to_room(monster_id, room_id)
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _management_monster_at(point: Vector2) -> String:
	var best_monster = ""
	var best_distance = 48.0
	for monster_id in monster_roster.keys():
		var preview_pos = _management_monster_preview_position(monster_id)
		if preview_pos == Vector2.INF:
			continue
		var distance = preview_pos.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best_monster = monster_id
	return best_monster

func _management_monster_preview_position(monster_id: String) -> Vector2:
	var room_counts: Dictionary = {}
	for current_monster_id in monster_roster.keys():
		var roster: Dictionary = monster_roster[current_monster_id]
		var room_id: String = roster.get("room", "")
		if not rooms.has(room_id):
			continue
		var count = int(room_counts.get(room_id, 0))
		if current_monster_id == monster_id:
			return _room_actor_point(room_id, count)
		room_counts[room_id] = count + 1
	return Vector2.INF

func _management_preview_offset(index: int) -> Vector2:
	var offsets = [
		Vector2(-30, 10),
		Vector2(0, -2),
		Vector2(30, 10),
		Vector2(-16, -24),
		Vector2(20, -24)
	]
	return offsets[index % offsets.size()]

func _room_actor_point(room_id: String, index: int, combat: bool = false) -> Vector2:
	if graph == null or not rooms.has(room_id):
		return Vector2.ZERO
	var center = graph.center(room_id)
	var rect = graph.rect(room_id)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return center + (_spawn_offset(index) if combat else _management_preview_offset(index))
	var normalized = _room_actor_offset(room_id, index)
	var spread = 0.92 if combat else 0.78
	return center + Vector2(rect.size.x * normalized.x * spread, rect.size.y * normalized.y * spread)

func _room_actor_offset(room_id: String, index: int) -> Vector2:
	var offsets = {
		"entrance": [Vector2(-0.30, 0.22), Vector2(-0.14, 0.30), Vector2(0.08, 0.18), Vector2(-0.24, -0.02), Vector2(0.18, 0.02)],
		"spike_corridor": [Vector2(-0.26, 0.16), Vector2(0.00, 0.24), Vector2(0.24, 0.12), Vector2(-0.12, -0.06), Vector2(0.14, -0.06)],
		"barracks": [Vector2(0.26, 0.18), Vector2(0.08, 0.28), Vector2(-0.14, 0.14), Vector2(0.18, -0.04)],
		"recovery": [Vector2(0.20, -0.02), Vector2(0.30, 0.14), Vector2(0.04, 0.18), Vector2(-0.12, 0.04)],
		"treasure": [Vector2(-0.14, 0.20), Vector2(0.08, 0.16), Vector2(-0.28, 0.04)],
		"throne": [Vector2(-0.10, 0.18), Vector2(0.12, 0.16), Vector2(0.00, -0.04)],
		"slot_01": [Vector2(-0.12, 0.18), Vector2(0.14, 0.16), Vector2(0.00, -0.06)],
		"watch_post": [Vector2(0.18, 0.14), Vector2(-0.08, 0.18), Vector2(0.26, -0.02)]
	}
	var room_offsets: Array = offsets.get(room_id, [])
	if room_offsets.is_empty():
		room_offsets = [Vector2(-0.22, 0.18), Vector2(0.00, 0.26), Vector2(0.22, 0.18), Vector2(-0.10, -0.06), Vector2(0.12, -0.06)]
	return room_offsets[index % room_offsets.size()]

func _draw_management_drag_feedback() -> void:
	if current_screen != Constants.SCREEN_MANAGEMENT or dragging_monster_id == "":
		return
	if drag_hover_room != "":
		var target_rect = graph.rect(drag_hover_room)
		var can_drop = _can_drop_monster_in_room(dragging_monster_id, drag_hover_room)
		var color = Color("#ffd36a") if can_drop else Color("#ff5d6c")
		draw_rect(target_rect.grow(12.0), Color(color.r, color.g, color.b, 0.16), true)
		draw_rect(target_rect.grow(12.0), Color(color.r, color.g, color.b, 0.88), false, 4.0)
	var texture = _monster_drag_texture(dragging_monster_id)
	draw_circle(drag_monster_position + Vector2(0, 18), 30.0, Color("#050506aa"))
	if texture != null:
		draw_texture_rect(texture, Rect2(drag_monster_position - Vector2(42, 58), Vector2(84, 84)), false, Color(1, 1, 1, 0.86))
	draw_arc(drag_monster_position + Vector2(0, 2), 44.0, 0.0, TAU, 40, Color("#ffd36acc"), 3.0)
	var monster = DataRegistry.monster(dragging_monster_id)
	draw_string(UI_FONT, drag_monster_position + Vector2(-52, 62), monster.get("display_name", dragging_monster_id), HORIZONTAL_ALIGNMENT_CENTER, 104.0, 16, Color("#fff3cd"))

func _can_drop_monster_in_room(monster_id: String, room_id: String) -> bool:
	if not rooms.has(room_id):
		return false
	if rooms[room_id].get("type", "") == "build_slot":
		return false
	return _placement_count(room_id, monster_id) < int(rooms[room_id].get("max_monsters", 1))

func _monster_drag_texture(monster_id: String) -> Texture2D:
	if monster_drag_texture_cache.has(monster_id):
		return monster_drag_texture_cache[monster_id]
	var monster = DataRegistry.monster(monster_id)
	var texture: Texture2D = null
	var path = str(monster.get("sprite", ""))
	if path != "":
		texture = _load_png(path)
	monster_drag_texture_cache[monster_id] = texture
	return texture

func _spawn_offset(index: int) -> Vector2:
	var offsets = [
		Vector2(-30, 12),
		Vector2(0, 0),
		Vector2(30, 12),
		Vector2(-18, -24),
		Vector2(22, -24)
	]
	return offsets[index % offsets.size()]

func _spawn_projectile(from_position: Vector2, to_position: Vector2) -> void:
	combat_scene.spawn_projectile(from_position, to_position)

func _spawn_slash(position: Vector2) -> void:
	combat_scene.spawn_slash(position)

func _spawn_impact(position: Vector2) -> void:
	combat_scene.spawn_impact(position)

func _log(message: String) -> void:
	var time_text = "[%05.1f] " % combat_time if current_screen == Constants.SCREEN_COMBAT else ""
	SignalBus.emit_log("%s%s" % [time_text, message])

func _on_log_added(message: String) -> void:
	logs.append(message)
	while logs.size() > 8:
		logs.pop_front()
	if current_screen == Constants.SCREEN_COMBAT:
		_tutorial_emit_action("log_event_seen", {"message": message})
	if current_screen == Constants.SCREEN_COMBAT:
		_set_screen(Constants.SCREEN_COMBAT)

func _draw_background() -> void:
	dungeon_renderer.draw_background()

func _draw_connections() -> void:
	dungeon_renderer.draw_connections()

func _draw_rooms() -> void:
	dungeon_renderer.draw_rooms()

func _draw_room_tiles(rect: Rect2, room_type: String) -> void:
	dungeon_renderer.draw_room_tiles(rect, room_type)

func _panel(rect: Rect2, color: Color, border: Color = Color("#3b3143")) -> Panel:
	return hud.panel(rect, color, border)

func _label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int = 20, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return hud.label(parent, text, position, size, font_size, color, align)

func _button(parent: Control, text: String, rect: Rect2, callback: Callable) -> Button:
	return hud.button(parent, text, rect, callback)

func _texture(parent: Control, path: String, rect: Rect2) -> TextureRect:
	return hud.texture(parent, path, rect)

func _style(color: Color, border: Color, width: int) -> StyleBoxFlat:
	return hud.style(color, border, width)

