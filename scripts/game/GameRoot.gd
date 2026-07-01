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
	if event is InputEventMouseButton and event.pressed:
		var point = get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(point)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(point)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)

func _draw() -> void:
	dungeon_renderer.draw()

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
	if selected_unit == null or selected_unit.faction != Constants.FACTION_MONSTER:
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
	if current_screen != Constants.SCREEN_MONSTER:
		_set_screen(Constants.SCREEN_MONSTER)
		return
	if selected_room == "slot_01" and rooms[selected_room].get("type", "") == "build_slot":
		_log("비어 있는 건설 슬롯에는 배치할 수 없습니다.")
		return
	if _placement_count(selected_room) >= int(rooms[selected_room].get("max_monsters", 1)):
		_log("선택 방의 배치 한도가 찼습니다.")
		return
	monster_roster[selected_monster_id]["room"] = selected_room
	_log("%s을(를) %s에 배치했습니다." % [DataRegistry.monster(selected_monster_id).get("display_name", selected_monster_id), rooms[selected_room].get("display_name", selected_room)])
	_set_screen(Constants.SCREEN_MONSTER)

func _placement_count(room_id: String) -> int:
	var count = 0
	for monster_id in monster_roster.keys():
		if monster_roster[monster_id].get("room", "") == room_id:
			count += 1
	return count

func _build_selected_slot() -> void:
	if selected_room != "slot_01" or rooms[selected_room].get("type", "") != "build_slot":
		_log("건설 가능한 슬롯을 선택하세요.")
		return
	if not GameState.pay({"gold": 100, "mana": 50}):
		_log("건설 비용이 부족합니다.")
		return
	rooms[selected_room]["display_name"] = "감시 초소"
	rooms[selected_room]["type"] = "support"
	rooms[selected_room]["max_monsters"] = 2
	rooms[selected_room]["icon"] = "prop_watch_post_01.png"
	_log("건설 슬롯에 감시 초소를 지었습니다.")
	_set_screen(Constants.SCREEN_MANAGEMENT)

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

func _room_at(point: Vector2) -> String:
	for room_id in rooms.keys():
		if graph.rect(room_id).has_point(point):
			return room_id
	return ""

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

