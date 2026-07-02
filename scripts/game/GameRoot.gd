extends Node2D

const Constants = preload("res://scripts/core/Constants.gd")
const RoomGraphScript = preload("res://scripts/map/RoomGraph.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")
const TargetingService = preload("res://scripts/combat/TargetingService.gd")
const DamageService = preload("res://scripts/combat/DamageService.gd")
const DirectiveManager = preload("res://scripts/combat/DirectiveManager.gd")
const UnitActorScript = preload("res://scripts/units/Unit.gd")
const HUDControllerScript = preload("res://scripts/ui/HUDController.gd")
const ManagementSceneControllerScript = preload("res://scripts/game/ManagementSceneController.gd")
const CombatSceneControllerScript = preload("res://scripts/game/CombatSceneController.gd")
const DungeonRendererScript = preload("res://scripts/map/DungeonRenderer.gd")

const FACILITY_CHOICES = ["barracks", "treasure", "recovery", "watch_post", "build_slot"]
const UNIQUE_FACILITIES = ["treasure", "recovery"]
const LOCKED_FACILITY_ROOMS = ["entrance", "spike_corridor", "center", "throne"]

var graph = RoomGraphScript.new()
var wave_manager = WaveManagerScript.new()
var hud
var management_scene
var combat_scene
var dungeon_renderer

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
var combat_time: float = 0.0
var combat_speed: float = 1.0
var combat_paused: bool = false
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

func _ready() -> void:
	randomize()
	RenderingServer.set_default_clear_color(Color("#07050b"))
	DataRegistry.load_all()
	GameState.reset()
	rooms = DataRegistry.rooms.duplicate(true)
	_init_room_facilities()
	graph.setup(rooms)
	_init_roster()
	_init_room_directives()
	_load_textures()
	_create_layers()
	_create_controllers()
	SignalBus.log_added.connect(_on_log_added)
	_set_screen(Constants.SCREEN_MANAGEMENT)
	set_process_input(true)

func _physics_process(delta: float) -> void:
	combat_scene.physics_process(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging_monster_id != "":
		_update_management_monster_drag(get_global_mouse_position())
		return
	if event is InputEventMouseButton:
		var point = get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if current_screen == Constants.SCREEN_MANAGEMENT:
				if event.pressed:
					if _start_management_monster_drag(point):
						return
					_handle_left_click(point)
				elif dragging_monster_id != "":
					_finish_management_monster_drag(point)
				return
			if event.pressed:
				_handle_left_click(point)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_handle_right_click(point)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)

func _draw() -> void:
	dungeon_renderer.draw()
	_draw_management_drag_feedback()

func _init_roster() -> void:
	monster_roster = {
		"slime": {"level": 1, "exp": 0, "room": "entrance"},
		"goblin": {"level": 1, "exp": 0, "room": "barracks"},
		"imp": {"level": 1, "exp": 0, "room": "center"}
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
		"marker_gate_gpt2.png": _load_png("res://assets/sprites/room_markers/marker_gate_gpt2.png"),
		"marker_spike_corridor_gpt2.png": _load_png("res://assets/sprites/room_markers/marker_spike_corridor_gpt2.png"),
		"marker_brazier_passage_gpt2.png": _load_png("res://assets/sprites/room_markers/marker_brazier_passage_gpt2.png"),
		"marker_throne_gpt2.png": _load_png("res://assets/sprites/room_markers/marker_throne_gpt2.png"),
		"marker_barracks_gpt2.png": _load_png("res://assets/sprites/room_markers/marker_barracks_gpt2.png"),
		"marker_treasure_gpt2.png": _load_png("res://assets/sprites/room_markers/marker_treasure_gpt2.png"),
		"marker_recovery_nest_gpt2.png": _load_png("res://assets/sprites/room_markers/marker_recovery_nest_gpt2.png"),
		"marker_recovery_room_gpt2.png": _load_png("res://assets/sprites/room_markers/marker_recovery_room_gpt2.png"),
		"marker_build_slot_gpt2.png": _load_png("res://assets/sprites/room_markers/marker_build_slot_gpt2.png"),
		"prop_gate_01.png": _load_png("res://assets/sprites/rooms/prop_gate_01.png"),
		"prop_spike_floor_01.png": _load_png("res://assets/sprites/rooms/prop_spike_floor_01.png"),
		"prop_brazier_01.png": _load_png("res://assets/sprites/rooms/prop_brazier_01.png"),
		"prop_throne_01.png": _load_png("res://assets/sprites/rooms/prop_throne_01.png"),
		"prop_barracks_01.png": _load_png("res://assets/sprites/rooms/prop_barracks_01.png"),
		"prop_treasure_pile_01.png": _load_png("res://assets/sprites/rooms/prop_treasure_pile_01.png"),
		"prop_recovery_nest_01.png": _load_png("res://assets/sprites/rooms/prop_recovery_nest_01.png"),
		"prop_build_slot_01.png": _load_png("res://assets/sprites/rooms/prop_build_slot_01.png"),
		"prop_watch_post_01.png": _load_png("res://assets/sprites/rooms/prop_watch_post_01.png")
	}
	effect_textures = {
		"fireball": _load_png("res://assets/sprites/effects/fx_fireball_00.png"),
		"slash": _load_png("res://assets/sprites/effects/fx_hit_slash_00.png"),
		"impact": _load_png("res://assets/sprites/effects/fx_fire_impact_00.png")
	}

func _load_png(path: String) -> Texture2D:
	var texture = ResourceLoader.load(path)
	if texture is Texture2D:
		return texture
	push_warning("Could not load texture: %s" % path)
	return null

func room_icon_path(icon_name: String) -> String:
	if icon_name == "":
		return ""
	if icon_name.begins_with("res://"):
		return icon_name
	if icon_name.begins_with("marker_"):
		return "res://assets/sprites/room_markers/%s" % icon_name
	return "res://assets/sprites/rooms/%s" % icon_name

func _create_layers() -> void:
	unit_root = Node2D.new()
	unit_root.name = "Units"
	add_child(unit_root)
	effect_root = Node2D.new()
	effect_root.name = "Effects"
	add_child(effect_root)
	ui_layer = CanvasLayer.new()
	ui_layer.name = "HUD"
	add_child(ui_layer)

func _create_controllers() -> void:
	dungeon_renderer = DungeonRendererScript.new()
	dungeon_renderer.setup(self)
	hud = HUDControllerScript.new()
	hud.setup(self)
	management_scene = ManagementSceneControllerScript.new()
	management_scene.setup(self, hud)
	combat_scene = CombatSceneControllerScript.new()
	combat_scene.setup(self, hud)

func _set_screen(screen_name: String) -> void:
	current_screen = screen_name
	SignalBus.screen_changed.emit(screen_name)
	hud.clear()
	match current_screen:
		Constants.SCREEN_MANAGEMENT:
			management_scene.build_management_ui()
		Constants.SCREEN_MONSTER:
			management_scene.build_monster_ui()
		Constants.SCREEN_COMBAT:
			combat_scene.build_combat_ui()
		Constants.SCREEN_RESULT:
			management_scene.build_result_ui()
	queue_redraw()

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

func _handle_left_click(point: Vector2) -> void:
	if current_screen == Constants.SCREEN_COMBAT:
		var unit = _unit_at(point)
		if unit != null:
			_select_unit(unit)
		return
	var room_id = _room_at(point)
	if room_id != "":
		_select_room(room_id)

func _handle_right_click(point: Vector2) -> void:
	if current_screen != Constants.SCREEN_COMBAT:
		return
	if _combat_ui_at(point):
		return
	if selected_unit == null or selected_unit.faction != Constants.FACTION_MONSTER:
		return
	var enemy_target = _enemy_at(point)
	if enemy_target != null:
		selected_unit.command_attack(enemy_target)
		_log("%s 직접 공격 지정: %s." % [selected_unit.display_name, enemy_target.display_name])
		return
	selected_unit.command_move(point)
	_log("%s 직접 이동 명령." % selected_unit.display_name)

func _handle_key(keycode: int) -> void:
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
		KEY_ESCAPE:
			if current_screen == Constants.SCREEN_MONSTER:
				_set_screen(Constants.SCREEN_MANAGEMENT)

func _start_combat() -> void:
	combat_scene.start_combat()

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
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _advance_day_from_management() -> void:
	GameState.advance_day()
	_log("하루를 넘겼습니다. DAY %d." % GameState.day)
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _open_monster_screen() -> void:
	_set_screen(Constants.SCREEN_MONSTER)

func _select_monster(monster_id: String) -> void:
	selected_monster_id = monster_id
	_set_screen(Constants.SCREEN_MONSTER)

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
	if str(monster_roster[monster_id].get("room", "")) == room_id:
		selected_monster_id = monster_id
		selected_room = room_id
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
	return true

func _build_selected_slot() -> void:
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
	_log("%s을(를) %s로 변경했습니다.%s" % [old_name, definition.get("display_name", facility_id), moved_text])
	_set_screen(Constants.SCREEN_MANAGEMENT)

func _facility_definition(facility_id: String) -> Dictionary:
	match facility_id:
		"barracks":
			return {
				"display_name": "병영",
				"short_label": "병영",
				"type": "support",
				"hp": 450,
				"max_monsters": 4,
				"icon": "marker_barracks_gpt2.png",
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
				"icon": "marker_treasure_gpt2.png",
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
				"icon": "marker_recovery_room_gpt2.png",
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
				"icon": "prop_watch_post_01.png",
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
				"icon": "marker_build_slot_gpt2.png",
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
	var preferred = [str(monster_roster.get(monster_id, {}).get("room", "")), "entrance", "barracks", "center", "recovery", "treasure", "slot_01", "throne"]
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
	SignalBus.room_selected.emit(room_id)
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
	combat_scene.set_global_directive(directive)

func _set_room_directive(directive: String) -> void:
	combat_scene.set_room_directive(directive)

func _enable_direct_control() -> void:
	combat_scene.enable_direct_control()

func _release_direct_control() -> void:
	combat_scene.release_direct_control()

func _use_selected_skill(slot: int) -> void:
	combat_scene.use_selected_skill(slot)

func _set_speed(speed: float) -> void:
	combat_scene.set_speed(speed)

func _toggle_pause() -> void:
	combat_scene.toggle_pause()

func _unit_at(point: Vector2) -> Node:
	var best: Node = null
	var best_distance = 58.0
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
	var best_distance = 58.0
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

func _room_at(point: Vector2) -> String:
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
			return graph.center(room_id) + _management_preview_offset(count)
		room_counts[room_id] = count + 1
	return Vector2.INF

func _management_preview_offset(index: int) -> Vector2:
	var offsets = [
		Vector2(-48, 14),
		Vector2(0, 2),
		Vector2(48, 14),
		Vector2(-24, -34),
		Vector2(32, -34)
	]
	return offsets[index % offsets.size()]

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
	draw_string(ThemeDB.fallback_font, drag_monster_position + Vector2(-52, 62), monster.get("display_name", dragging_monster_id), HORIZONTAL_ALIGNMENT_CENTER, 104.0, 16, Color("#fff3cd"))

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
		Vector2(-48, 16),
		Vector2(0, 4),
		Vector2(48, 16),
		Vector2(-24, -34),
		Vector2(34, -34)
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

