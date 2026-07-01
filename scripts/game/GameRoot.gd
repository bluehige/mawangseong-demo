extends Node2D

const Constants = preload("res://scripts/core/Constants.gd")
const RoomGraphScript = preload("res://scripts/map/RoomGraph.gd")
const WaveManagerScript = preload("res://scripts/combat/WaveManager.gd")
const TargetingService = preload("res://scripts/combat/TargetingService.gd")
const DamageService = preload("res://scripts/combat/DamageService.gd")
const DirectiveManager = preload("res://scripts/combat/DirectiveManager.gd")
const UnitActorScript = preload("res://scripts/units/Unit.gd")

var graph = RoomGraphScript.new()
var wave_manager = WaveManagerScript.new()

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
	SignalBus.log_added.connect(_on_log_added)
	_set_screen(Constants.SCREEN_MANAGEMENT)
	set_process_input(true)

func _physics_process(delta: float) -> void:
	if current_screen != Constants.SCREEN_COMBAT or combat_paused:
		return
	var sim_delta = delta * combat_speed
	combat_time += sim_delta
	trap_cooldown = max(0.0, trap_cooldown - sim_delta)
	_spawn_ready_enemies(sim_delta)
	_refresh_unit_rooms()
	_update_ai_paths()
	_update_room_effects(sim_delta)
	_update_attacks(sim_delta)
	_check_combat_end()
	_rebuild_combat_ui_light()

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
	_draw_background()
	_draw_connections()
	_draw_rooms()

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
	floor_texture = _load_png("res://assets/sprites/tiles/tile_cave_floor_01.png")
	wall_texture = _load_png("res://assets/sprites/tiles/tile_cave_wall_top_01.png")
	spike_texture = _load_png("res://assets/sprites/tiles/tile_spike_floor_01.png")
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
	var image = Image.new()
	var err = image.load(path)
	if err != OK:
		push_warning("Could not load image: %s" % path)
		return null
	return ImageTexture.create_from_image(image)

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

func _set_screen(screen_name: String) -> void:
	current_screen = screen_name
	SignalBus.screen_changed.emit(screen_name)
	_clear_ui()
	match current_screen:
		Constants.SCREEN_MANAGEMENT:
			_build_management_ui()
		Constants.SCREEN_MONSTER:
			_build_monster_ui()
		Constants.SCREEN_COMBAT:
			_build_combat_ui()
		Constants.SCREEN_RESULT:
			_build_result_ui()
	queue_redraw()

func _clear_ui() -> void:
	for child in ui_layer.get_children():
		child.queue_free()

func _build_management_ui() -> void:
	_build_top_bar()
	_build_room_list(16, 92, 300, 420)
	var right = _panel(Rect2(1518, 92, 370, 760), Color("#111016dd"))
	_label(right, "선택 방", Vector2(24, 22), Vector2(320, 32), 28, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	_build_selected_room_info(right)

	var bottom = _panel(Rect2(98, 880, 1725, 142), Color("#100e14e8"))
	_button(bottom, "건설", Rect2(18, 20, 250, 86), Callable(self, "_build_selected_slot"))
	_button(bottom, "몬스터", Rect2(288, 20, 250, 86), Callable(self, "_open_monster_screen"))
	_button(bottom, "침공 작전", Rect2(558, 20, 250, 86), Callable(self, "_log").bind("침공 작전은 데모에서 비활성화되어 있습니다."))
	_button(bottom, "방어 준비", Rect2(828, 20, 300, 86), Callable(self, "_start_combat"))
	_button(bottom, "다음 날", Rect2(1148, 20, 300, 86), Callable(self, "_advance_day_from_management"))
	_label(bottom, "방을 클릭해 선택하고, 방어 준비로 실시간 전투를 시작합니다.", Vector2(1470, 22), Vector2(230, 80), 18, Color("#bfb7cc"))

func _build_monster_ui() -> void:
	_build_top_bar()
	var left = _panel(Rect2(24, 118, 520, 820), Color("#0f0f14e8"))
	_label(left, "보유 몬스터", Vector2(24, 18), Vector2(460, 36), 28, Color("#f4e7d2"))
	var y = 78
	for monster_id in monster_roster.keys():
		var data = DataRegistry.monster(monster_id)
		var roster = monster_roster[monster_id]
		var suffix = "  Lv.%d  HP %d" % [int(roster["level"]), int(data.get("max_hp", 1)) + (int(roster["level"]) - 1) * 20]
		var button = _button(left, "%s%s" % [data.get("display_name", monster_id), suffix], Rect2(24, y, 460, 76), Callable(self, "_select_monster").bind(monster_id))
		if monster_id == selected_monster_id:
			button.add_theme_color_override("font_color", Color("#d99bff"))
		y += 90
	_button(left, "돌아가기", Rect2(24, 714, 220, 72), Callable(self, "_set_screen").bind(Constants.SCREEN_MANAGEMENT))
	_button(left, "선택 방 배치", Rect2(264, 714, 220, 72), Callable(self, "_place_selected_monster"))

	var center = _panel(Rect2(590, 130, 780, 800), Color("#111016cc"))
	var monster = DataRegistry.monster(selected_monster_id)
	var roster: Dictionary = monster_roster[selected_monster_id]
	_label(center, monster.get("display_name", selected_monster_id), Vector2(280, 32), Vector2(240, 46), 42, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	_texture(center, monster.get("sprite", ""), Rect2(294, 118, 192, 192))
	_label(center, "Lv.%d / %s" % [int(roster["level"]), monster.get("role", "")], Vector2(245, 315), Vector2(300, 34), 24, Color("#be72ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_label(center, "배치 방: %s" % rooms[roster["room"]].get("display_name", roster["room"]), Vector2(245, 360), Vector2(300, 34), 22, Color("#d5cbe3"), HORIZONTAL_ALIGNMENT_CENTER)
	_build_stat_lines(center, monster, roster)
	_button(center, "훈련  금화 30", Rect2(120, 680, 250, 72), Callable(self, "_train_selected_monster"))
	_button(center, "배치", Rect2(410, 680, 250, 72), Callable(self, "_place_selected_monster"))

	var right = _panel(Rect2(1410, 130, 420, 800), Color("#0f0e13e8"))
	_label(right, "스킬 슬롯", Vector2(24, 24), Vector2(360, 36), 28, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	var skills: Array = monster.get("skill_slots", [])
	y = 88
	for skill_id in skills:
		if skill_id == null:
			_label(right, "잠금 슬롯", Vector2(28, y), Vector2(360, 70), 22, Color("#7d7586"))
		else:
			var skill = DataRegistry.skill(str(skill_id))
			_label(right, skill.get("display_name", skill_id), Vector2(28, y), Vector2(360, 28), 24, Color("#ffffff"))
			_label(right, skill.get("description", ""), Vector2(28, y + 32), Vector2(360, 54), 17, Color("#bfb7cc"))
		y += 118
	_label(right, "레벨업 후보 선택 UI는 다음 세션 확장 대상으로 남겼습니다.", Vector2(28, 690), Vector2(360, 70), 18, Color("#9d90ac"))

func _build_combat_ui() -> void:
	_build_top_bar()
	_build_room_list(20, 105, 300, 455)
	_build_log_panel()
	_build_selected_unit_panel()
	_build_command_panel()
	_build_speed_panel()

func _build_result_ui() -> void:
	_build_top_bar()
	var panel = _panel(Rect2(520, 205, 880, 630), Color("#100d14f2"), Color("#9b6a27"))
	var title = "방어 성공" if result_summary.get("win", false) else "방어 실패"
	if GameState.victory:
		title = "데모 클리어"
	_label(panel, title, Vector2(0, 48), Vector2(880, 64), 48, Color("#f7efe1"), HORIZONTAL_ALIGNMENT_CENTER)
	var y = 150
	for line in result_summary.get("lines", []):
		_label(panel, str(line), Vector2(120, y), Vector2(640, 34), 24, Color("#d8d1df"))
		y += 44
	if GameState.victory or GameState.defeat or GameState.day >= GameState.max_day:
		_button(panel, "관리 화면으로", Rect2(315, 500, 250, 76), Callable(self, "_set_screen").bind(Constants.SCREEN_MANAGEMENT))
	else:
		_button(panel, "다음 날 진행", Rect2(315, 500, 250, 76), Callable(self, "_advance_after_result"))

func _build_top_bar() -> void:
	var top = _panel(Rect2(16, 10, 1870, 70), Color("#0d0b10e8"), Color("#6e5630"))
	_label(top, "금화  %d  +%d/분" % [GameState.gold, GameState.gold_income], Vector2(22, 12), Vector2(270, 42), 24, Color("#ffd36a"))
	_label(top, "마력  %d  +%d/분" % [GameState.mana, GameState.mana_income], Vector2(310, 12), Vector2(270, 42), 24, Color("#67b7ff"))
	_label(top, "식량  %d/30  +%d/분" % [GameState.food, GameState.food_income], Vector2(600, 12), Vector2(280, 42), 24, Color("#d8a77f"))
	_label(top, "악명  %d  +%d/일" % [GameState.infamy, GameState.infamy_income], Vector2(900, 12), Vector2(270, 42), 24, Color("#be72ff"))
	_label(top, "DAY %d / 밤" % GameState.day, Vector2(1260, 12), Vector2(170, 42), 26, Color("#e7e0ff"), HORIZONTAL_ALIGNMENT_CENTER)
	_label(top, "마왕성 체력  %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp], Vector2(1460, 12), Vector2(360, 42), 24, Color("#ff7982"))

func _build_room_list(x: int, y: int, w: int, h: int) -> void:
	var panel = _panel(Rect2(x, y, w, h), Color("#0e0d12e8"))
	_label(panel, "방 목록", Vector2(0, 12), Vector2(w, 32), 24, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	var order = ["entrance", "spike_corridor", "treasure", "barracks", "recovery", "throne", "slot_01"]
	var row_y = 58
	for room_id in order:
		if not rooms.has(room_id):
			continue
		var room = rooms[room_id]
		var text = "%s   %s" % [room.get("display_name", room_id), DirectiveManager.directive_label(room_directives.get(room_id, "none"))]
		var button = _button(panel, text, Rect2(16, row_y, w - 32, 48), Callable(self, "_select_room").bind(room_id))
		if room_id == selected_room:
			button.add_theme_color_override("font_color", Color("#d99bff"))
		row_y += 58

func _build_selected_room_info(parent: Control) -> void:
	var room = rooms.get(selected_room, {})
	_label(parent, room.get("display_name", selected_room), Vector2(24, 76), Vector2(320, 42), 34, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	_texture(parent, "res://assets/sprites/rooms/%s" % room.get("icon", "prop_build_slot_01.png"), Rect2(126, 132, 120, 120))
	_label(parent, "타입: %s" % room.get("type", ""), Vector2(30, 280), Vector2(300, 30), 22, Color("#cfc7d9"))
	_label(parent, "HP: %d / 최대 배치 %d" % [int(room.get("hp", 0)), int(room.get("max_monsters", 0))], Vector2(30, 320), Vector2(300, 30), 22, Color("#cfc7d9"))
	_label(parent, "방 지침: %s" % DirectiveManager.directive_label(room_directives.get(selected_room, "none")), Vector2(30, 360), Vector2(300, 30), 22, Color("#d99bff"))
	_label(parent, "연결: %s" % ", ".join(room.get("exits", [])), Vector2(30, 410), Vector2(300, 64), 18, Color("#998fa8"))
	if room.get("type", "") == "build_slot":
		_label(parent, "건설 비용: 금화 100 / 마력 50", Vector2(30, 510), Vector2(300, 30), 22, Color("#ffd36a"))
	else:
		_label(parent, "이 방은 현재 고정 시설입니다.", Vector2(30, 510), Vector2(300, 30), 22, Color("#bfb7cc"))
	_button(parent, "입구 봉쇄", Rect2(28, 586, 145, 52), Callable(self, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_ENTRY_BLOCK))
	_button(parent, "함정 유도", Rect2(190, 586, 145, 52), Callable(self, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_TRAP_LURE))
	_button(parent, "후퇴 유도", Rect2(28, 652, 145, 52), Callable(self, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_RETREAT))
	_button(parent, "기본", Rect2(190, 652, 145, 52), Callable(self, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_NONE))

func _build_stat_lines(parent: Control, monster: Dictionary, roster: Dictionary) -> void:
	var level = int(roster["level"])
	var max_hp = int(monster.get("max_hp", 1)) + (level - 1) * 20
	var attack = int(monster.get("atk", 1)) + (level - 1) * 3
	var defense = int(monster.get("def", 0)) + (level - 1)
	var lines = [
		"HP      %d / %d" % [max_hp, max_hp],
		"공격력   %d" % attack,
		"방어력   %d" % defense,
		"이동속도 %d" % int(monster.get("move_speed", 0)),
		"지능     %d" % int(monster.get("int", 0)),
		"충성도   %d" % int(monster.get("loyalty", 0)),
		"EXP      %d" % int(roster["exp"])
	]
	var y = 420
	for line in lines:
		_label(parent, line, Vector2(250, y), Vector2(300, 26), 22, Color("#d8d1df"))
		y += 34

func _build_log_panel() -> void:
	var panel = _panel(Rect2(20, 710, 455, 300), Color("#0b0b0fe8"))
	_label(panel, "전투 로그", Vector2(18, 14), Vector2(400, 30), 24, Color("#f4e7d2"))
	var y = 56
	for message in logs:
		_label(panel, message, Vector2(18, y), Vector2(410, 26), 17, Color("#cfc7d9"))
		y += 30

func _build_selected_unit_panel() -> void:
	var panel = _panel(Rect2(1518, 142, 370, 710), Color("#0e0d12e8"))
	_label(panel, "선택 유닛", Vector2(0, 16), Vector2(370, 34), 26, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	if selected_unit == null or not is_instance_valid(selected_unit):
		_label(panel, "유닛을 클릭해 선택하세요.", Vector2(36, 90), Vector2(300, 48), 22, Color("#bfb7cc"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	_texture(panel, selected_unit.sprite_path, Rect2(118, 72, 132, 132))
	_label(panel, selected_unit.display_name, Vector2(26, 220), Vector2(320, 38), 32, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
	_label(panel, selected_unit.role, Vector2(26, 262), Vector2(320, 30), 20, Color("#d99bff"), HORIZONTAL_ALIGNMENT_CENTER)
	_label(panel, "체력  %d / %d" % [selected_unit.hp, selected_unit.max_hp], Vector2(36, 330), Vector2(300, 30), 24, Color("#e8dff0"))
	_label(panel, "공격력  %d" % selected_unit.atk, Vector2(36, 372), Vector2(300, 28), 22, Color("#e8dff0"))
	_label(panel, "방어력  %d" % selected_unit.def, Vector2(36, 410), Vector2(300, 28), 22, Color("#e8dff0"))
	_label(panel, "공격 속도  %.1fs" % selected_unit.attack_interval, Vector2(36, 448), Vector2(300, 28), 22, Color("#e8dff0"))
	_label(panel, "현재 방  %s" % rooms.get(selected_unit.current_room, {}).get("display_name", selected_unit.current_room), Vector2(36, 486), Vector2(300, 28), 22, Color("#e8dff0"))
	if selected_unit.faction == Constants.FACTION_MONSTER:
		_button(panel, "직접 조종", Rect2(36, 560, 136, 58), Callable(self, "_enable_direct_control"))
		_button(panel, "AI 복귀", Rect2(196, 560, 136, 58), Callable(self, "_release_direct_control"))
		_button(panel, "스킬 1", Rect2(36, 632, 136, 50), Callable(self, "_use_selected_skill").bind(0))
		_button(panel, "스킬 2", Rect2(196, 632, 136, 50), Callable(self, "_use_selected_skill").bind(1))

func _build_command_panel() -> void:
	var panel = _panel(Rect2(560, 804, 860, 206), Color("#100e14e8"), Color("#6e5630"))
	_label(panel, "전체 지침", Vector2(0, 8), Vector2(430, 32), 24, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	_label(panel, "방 지침", Vector2(430, 8), Vector2(430, 32), 24, Color("#f4e7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	_button(panel, "사수", Rect2(40, 55, 130, 110), Callable(self, "_set_global_directive").bind(Constants.DIRECTIVE_DEFENSE))
	_button(panel, "총공격", Rect2(185, 55, 130, 110), Callable(self, "_set_global_directive").bind(Constants.DIRECTIVE_ALL_OUT))
	_button(panel, "생존 우선", Rect2(330, 55, 130, 110), Callable(self, "_set_global_directive").bind(Constants.DIRECTIVE_SURVIVAL))
	_button(panel, "함정 유도", Rect2(500, 55, 145, 110), Callable(self, "_set_room_directive").bind(Constants.ROOM_DIRECTIVE_TRAP_LURE))
	_button(panel, "직접 조종", Rect2(665, 55, 145, 110), Callable(self, "_enable_direct_control"))

func _build_speed_panel() -> void:
	var panel = _panel(Rect2(1438, 820, 80, 190), Color("#100e14e8"))
	_button(panel, "x1", Rect2(10, 16, 60, 48), Callable(self, "_set_speed").bind(1.0))
	_button(panel, "x1.5", Rect2(10, 72, 60, 48), Callable(self, "_set_speed").bind(1.5))
	_button(panel, "II", Rect2(10, 128, 60, 48), Callable(self, "_toggle_pause"))

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
	_clear_units()
	_clear_effects()
	combat_time = 0.0
	combat_paused = false
	combat_speed = 1.0
	trap_cooldown = 0.0
	spawned_count = 0
	thief_steal_timers.clear()
	rewards_pending = {"gold": 0, "mana": 0, "food": 0, "infamy": 0}
	result_summary = {"win": false, "lines": []}
	wave_manager.setup(GameState.day, DataRegistry.waves)
	_spawn_monsters()
	for unit in monster_units:
		unit.set_physics_process(true)
	_log("DAY %d 침입이 시작되었습니다." % GameState.day)
	_set_screen(Constants.SCREEN_COMBAT)

func _spawn_monsters() -> void:
	var spawn_counts: Dictionary = {}
	for monster_id in monster_roster.keys():
		var roster: Dictionary = monster_roster[monster_id]
		var room_id: String = roster.get("room", DataRegistry.monster(monster_id).get("recommended_room", "entrance"))
		var stats = _scaled_monster_stats(monster_id)
		var unit = _create_unit(monster_id, stats, Constants.FACTION_MONSTER, room_id)
		var count = int(spawn_counts.get(room_id, 0))
		unit.global_position = graph.center(room_id) + _spawn_offset(count)
		spawn_counts[room_id] = count + 1
		monster_units.append(unit)
		if selected_unit == null:
			_select_unit(unit)

func _spawn_ready_enemies(delta: float) -> void:
	for entry in wave_manager.tick(delta):
		_spawn_enemy(entry.get("enemy_id", "explorer"))

func _spawn_enemy(enemy_id: String) -> void:
	var stats = DataRegistry.enemy(enemy_id)
	var unit = _create_unit(enemy_id, stats, Constants.FACTION_ENEMY, "entrance")
	unit.global_position = graph.center("entrance") + Vector2(-90 + spawned_count * 34, 58)
	unit.goal_room = "treasure" if stats.get("goal_type", "") == "treasure" else "throne"
	unit.set_path(graph.path_points("entrance", unit.goal_room))
	enemy_units.append(unit)
	spawned_count += 1
	_log("%s가 입구에 도착했습니다." % unit.display_name)

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
	for child in effect_root.get_children():
		child.queue_free()

func _refresh_unit_rooms() -> void:
	for unit in monster_units + enemy_units:
		if unit.is_alive():
			unit.current_room = graph.closest_room(unit.global_position)

func _update_ai_paths() -> void:
	for unit in monster_units:
		if not unit.is_alive() or unit.direct_control:
			continue
		_update_monster_path(unit)
	for unit in enemy_units:
		if not unit.is_alive():
			continue
		_update_enemy_path(unit)

func _update_monster_path(unit: Node) -> void:
	if float(unit.hp) / float(unit.max_hp) <= 0.35 and global_directive == Constants.DIRECTIVE_SURVIVAL:
		_move_unit_to_room(unit, "recovery")
		return
	if room_directives.get(unit.current_room, Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_RETREAT:
		_move_unit_to_room(unit, "recovery")
		return
	if room_directives.get("spike_corridor", Constants.ROOM_DIRECTIVE_NONE) == Constants.ROOM_DIRECTIVE_TRAP_LURE:
		var enemies_in_spike = TargetingService.units_in_room(enemy_units, "spike_corridor")
		if not enemies_in_spike.is_empty():
			_move_unit_to_room(unit, "spike_corridor")
			return
	if global_directive == Constants.DIRECTIVE_ALL_OUT:
		var target = TargetingService.nearest(unit, enemy_units)
		if target != null:
			if target.current_room == unit.current_room:
				_move_unit_to_point(unit, target.global_position)
			else:
				_move_unit_to_room(unit, target.current_room)
			return
	var nearby = _nearest_enemy_in_rooms(unit, [unit.current_room] + graph.exits(unit.current_room))
	if nearby != null:
		if nearby.current_room == unit.current_room:
			_move_unit_to_point(unit, nearby.global_position)
		else:
			_move_unit_to_room(unit, nearby.current_room)
	elif unit.current_room != unit.assigned_room:
		_move_unit_to_room(unit, unit.assigned_room)

func _update_enemy_path(unit: Node) -> void:
	var monster_target = _nearest_monster_in_rooms(unit, [unit.current_room])
	if monster_target != null:
		_move_unit_to_point(unit, monster_target.global_position)
		return
	if unit.current_room == unit.goal_room:
		return
	_move_unit_to_room(unit, unit.goal_room)

func _nearest_enemy_in_rooms(unit: Node, room_ids: Array) -> Node:
	var candidates: Array = []
	for enemy in enemy_units:
		if enemy.is_alive() and room_ids.has(enemy.current_room):
			candidates.append(enemy)
	return TargetingService.nearest(unit, candidates)

func _nearest_monster_in_rooms(unit: Node, room_ids: Array) -> Node:
	var candidates: Array = []
	for monster in monster_units:
		if monster.is_alive() and room_ids.has(monster.current_room):
			candidates.append(monster)
	return TargetingService.nearest(unit, candidates)

func _move_unit_to_room(unit: Node, room_id: String) -> void:
	if unit.goal_room == room_id and not unit.path_points.is_empty():
		return
	unit.goal_room = room_id
	unit.set_path(graph.path_points(unit.current_room, room_id))

func _move_unit_to_point(unit: Node, point: Vector2) -> void:
	if unit.global_position.distance_to(point) <= max(12.0, unit.attack_range * 0.75):
		return
	unit.goal_room = unit.current_room
	unit.set_path([point])

func _update_room_effects(delta: float) -> void:
	for unit in monster_units:
		if unit.is_alive() and unit.current_room == "recovery":
			unit.heal(int(round(8.0 * delta)))
	if trap_cooldown <= 0.0:
		for enemy in enemy_units:
			if enemy.is_alive() and enemy.current_room == "spike_corridor":
				enemy.receive_damage(12)
				enemy.apply_slow(2.0, 0.8)
				trap_cooldown = 2.0
				_log("가시 복도가 %s에게 피해를 주었습니다." % enemy.display_name)
				_spawn_impact(enemy.global_position)
				break
	for enemy in enemy_units:
		if enemy.is_alive() and enemy.current_room == "throne":
			if enemy.attack_cooldown <= 0.0 and TargetingService.nearest(enemy, monster_units, enemy.attack_range) == null:
				GameState.damage_throne(max(8, enemy.atk))
				enemy.attack_cooldown = enemy.attack_interval
				_log("%s가 왕좌의 방을 공격했습니다." % enemy.display_name)
		if enemy.is_alive() and enemy.unit_id == "thief" and enemy.current_room == "treasure":
			var timer = float(thief_steal_timers.get(enemy, 0.0)) + delta
			thief_steal_timers[enemy] = timer
			if timer >= 5.0:
				GameState.gold = max(0, GameState.gold - 100)
				SignalBus.resources_changed.emit()
				thief_steal_timers[enemy] = -999.0
				enemy.goal_room = "entrance"
				enemy.set_path(graph.path_points(enemy.current_room, "entrance"))
				_log("도둑이 보물을 훔쳤습니다. 금화 -100.")
		if enemy.is_alive() and enemy.unit_id == "thief" and float(thief_steal_timers.get(enemy, 0.0)) < -100.0 and enemy.current_room == "entrance":
			enemy.hp = 0
			enemy.down = true
			enemy.visible = false
			_log("도둑이 입구로 도주했습니다.")

func _update_attacks(delta: float) -> void:
	for unit in monster_units:
		if unit.is_alive():
			_try_attack(unit, enemy_units)
	for unit in enemy_units:
		if unit.is_alive():
			_try_attack(unit, monster_units)

func _try_attack(attacker: Node, opponents: Array) -> void:
	if attacker.attack_cooldown > 0.0:
		return
	var target = TargetingService.nearest(attacker, opponents, attacker.attack_range)
	if target == null:
		return
	var damage = DamageService.compute(attacker, target)
	target.receive_damage(damage)
	attacker.attack_cooldown = attacker.attack_interval
	if attacker.faction == Constants.FACTION_MONSTER and attacker.unit_id == "imp":
		_spawn_projectile(attacker.global_position, target.global_position)
	else:
		_spawn_slash(target.global_position)
	_log("%s가 %s에게 %d 피해." % [attacker.display_name, target.display_name, damage])

func _on_unit_downed(unit: Node) -> void:
	if unit.faction == Constants.FACTION_ENEMY:
		rewards_pending["gold"] = int(rewards_pending.get("gold", 0)) + 60
		rewards_pending["mana"] = int(rewards_pending.get("mana", 0)) + 20
		rewards_pending["infamy"] = int(rewards_pending.get("infamy", 0)) + unit.infamy_reward
		for monster_id in monster_roster.keys():
			monster_roster[monster_id]["exp"] = int(monster_roster[monster_id]["exp"]) + max(5, int(unit.exp_reward / 3))
		_log("%s 격퇴. 악명 +%d." % [unit.display_name, unit.infamy_reward])
	else:
		_log("%s가 전투 불능이 되었습니다." % unit.display_name)

func _check_combat_end() -> void:
	if GameState.defeat:
		_finish_combat(false, "마왕성 체력이 0이 되었습니다.")
		return
	var alive_enemies = 0
	for enemy in enemy_units:
		if enemy.is_alive():
			alive_enemies += 1
	if wave_manager.is_done() and alive_enemies == 0:
		var win_text = "DAY %d 방어 성공." % GameState.day
		if GameState.day >= GameState.max_day:
			GameState.victory = true
			win_text = "3일차 수련생 용사를 격퇴했습니다."
		_finish_combat(true, win_text)

func _finish_combat(win: bool, reason: String) -> void:
	if current_screen == Constants.SCREEN_RESULT:
		return
	for unit in monster_units + enemy_units:
		if is_instance_valid(unit):
			unit.set_physics_process(false)
	GameState.add_rewards(rewards_pending)
	var lines: Array[String] = []
	lines.append(reason)
	lines.append("격퇴한 적: %d / 스폰: %d" % [_count_downed_enemies(), spawned_count])
	lines.append("획득 금화: %d" % int(rewards_pending.get("gold", 0)))
	lines.append("획득 마력: %d" % int(rewards_pending.get("mana", 0)))
	lines.append("증가 악명: %d" % int(rewards_pending.get("infamy", 0)))
	lines.append("마왕성 체력: %d / %d" % [GameState.demon_lord_hp, GameState.demon_lord_max_hp])
	result_summary = {"win": win, "lines": lines}
	SignalBus.battle_finished.emit(result_summary)
	_set_screen(Constants.SCREEN_RESULT)

func _count_downed_enemies() -> int:
	var count = 0
	for enemy in enemy_units:
		if not enemy.is_alive():
			count += 1
	return count

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
	global_directive = directive
	_log("전체 지침: %s." % DirectiveManager.directive_label(directive))
	if current_screen == Constants.SCREEN_COMBAT:
		_set_screen(Constants.SCREEN_COMBAT)

func _set_room_directive(directive: String) -> void:
	room_directives[selected_room] = directive
	_log("%s 지침: %s." % [rooms[selected_room].get("display_name", selected_room), DirectiveManager.directive_label(directive)])
	_set_screen(current_screen)

func _enable_direct_control() -> void:
	if selected_unit == null or selected_unit.faction != Constants.FACTION_MONSTER:
		_log("직접 조종할 몬스터를 선택하세요.")
		return
	selected_unit.direct_control = true
	_log("%s 직접 조종 시작. 우클릭으로 이동합니다." % selected_unit.display_name)

func _release_direct_control() -> void:
	if selected_unit == null:
		return
	selected_unit.release_direct_control()
	_log("%s AI 복귀." % selected_unit.display_name)

func _use_selected_skill(slot: int) -> void:
	if selected_unit == null or selected_unit.faction != Constants.FACTION_MONSTER:
		return
	var monster_data = DataRegistry.monster(selected_unit.unit_id)
	var skills: Array = monster_data.get("skill_slots", [])
	if slot < 0 or slot >= skills.size() or skills[slot] == null:
		_log("사용 가능한 스킬이 없습니다.")
		return
	var skill_id = str(skills[slot])
	if not selected_unit.skill_ready(skill_id):
		_log("스킬 재사용 대기 중입니다.")
		return
	var skill = DataRegistry.skill(skill_id)
	var cost = int(skill.get("cost_mana", 0))
	if GameState.mana < cost:
		_log("마력이 부족합니다.")
		return
	GameState.mana -= cost
	SignalBus.resources_changed.emit()
	match skill_id:
		"slime_shield":
			selected_unit.activate_shield(5.0, 0.4)
			_log("슬라임이 점액 방패를 펼쳤습니다.")
		"quick_slash":
			var target = TargetingService.nearest(selected_unit, enemy_units, selected_unit.attack_range + 38.0)
			if target != null:
				var damage = DamageService.compute(selected_unit, target, 1.6)
				target.receive_damage(damage)
				_spawn_slash(target.global_position)
				_log("고블린이 날붙이 베기로 %d 피해." % damage)
		"fireball":
			var target = TargetingService.nearest(selected_unit, enemy_units, 320.0)
			if target != null:
				target.receive_damage(30)
				_spawn_projectile(selected_unit.global_position, target.global_position)
				_log("임프가 화염구를 발사했습니다.")
		"flame_zone":
			var affected = 0
			for enemy in enemy_units:
				if enemy.is_alive() and ["spike_corridor", "center"].has(enemy.current_room):
					enemy.receive_damage(18)
					enemy.apply_slow(2.0, 0.75)
					_spawn_impact(enemy.global_position)
					affected += 1
			_log("화염 지대가 %d명에게 피해를 줬습니다." % affected)
		_:
			_log("%s 사용." % skill.get("display_name", skill_id))
	selected_unit.set_skill_cooldown(skill_id, float(skill.get("cooldown", 5.0)))
	_set_screen(Constants.SCREEN_COMBAT)

func _set_speed(speed: float) -> void:
	combat_speed = speed
	_log("전투 속도 x%.1f." % combat_speed)

func _toggle_pause() -> void:
	combat_paused = not combat_paused
	for unit in monster_units + enemy_units:
		if is_instance_valid(unit):
			unit.set_physics_process(not combat_paused)
	_log("일시정지." if combat_paused else "전투 재개.")

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
		Vector2(-56, 28),
		Vector2(0, 16),
		Vector2(56, 28),
		Vector2(-28, -30),
		Vector2(36, -30)
	]
	return offsets[index % offsets.size()]

func _spawn_projectile(from_position: Vector2, to_position: Vector2) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = effect_textures.get("fireball")
	sprite.global_position = from_position
	sprite.z_index = 3000
	effect_root.add_child(sprite)
	var tween = create_tween()
	tween.tween_property(sprite, "global_position", to_position, 0.22)
	tween.tween_callback(sprite.queue_free)
	_spawn_impact(to_position)

func _spawn_slash(position: Vector2) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = effect_textures.get("slash")
	sprite.global_position = position + Vector2(0, -18)
	sprite.z_index = 3000
	effect_root.add_child(sprite)
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.12)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.18)
	tween.tween_callback(sprite.queue_free)

func _spawn_impact(position: Vector2) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = effect_textures.get("impact")
	sprite.global_position = position + Vector2(0, -20)
	sprite.z_index = 3000
	effect_root.add_child(sprite)
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.35, 1.35), 0.18)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(sprite.queue_free)

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
	draw_rect(Rect2(Vector2.ZERO, Vector2(1920, 1080)), Color("#08060c"))
	draw_circle(Vector2(960, 500), 560.0, Color(0.25, 0.11, 0.36, 0.12))
	draw_circle(Vector2(1180, 270), 280.0, Color(0.42, 0.18, 0.62, 0.14))
	draw_circle(Vector2(560, 610), 260.0, Color(0.08, 0.13, 0.18, 0.18))

func _draw_connections() -> void:
	var drawn: Dictionary = {}
	for room_id in rooms.keys():
		for exit_id in graph.exits(room_id):
			var key = "%s-%s" % [room_id, exit_id]
			var reverse_key = "%s-%s" % [exit_id, room_id]
			if drawn.has(key) or drawn.has(reverse_key):
				continue
			drawn[key] = true
			var start = graph.center(room_id)
			var end = graph.center(exit_id)
			draw_line(start, end, Color("#2e2935"), 50.0)
			draw_line(start, end, Color("#5e5068"), 8.0)
			draw_dashed_line(start, end, Color("#9564d9"), 2.0, 14.0)

func _draw_rooms() -> void:
	var font = ThemeDB.fallback_font
	for room_id in rooms.keys():
		var room = rooms[room_id]
		var rect = graph.rect(room_id)
		_draw_room_tiles(rect, room.get("type", ""))
		var fill = Color("#17151bdf")
		if room.get("type", "") == "trap":
			fill = Color("#21131adf")
		elif room.get("type", "") == "core":
			fill = Color("#201621e8")
		elif room.get("type", "") == "bait":
			fill = Color("#211b11df")
		elif room.get("type", "") == "recovery":
			fill = Color("#152018df")
		elif room.get("type", "") == "build_slot":
			fill = Color("#151019bb")
		draw_rect(rect, fill, true)
		var border = Color("#6e5630")
		if room_id == selected_room:
			border = Color("#b15dff")
		draw_rect(rect, border, false, 4.0)
		var label_pos = rect.position + Vector2(14, -10)
		draw_rect(Rect2(label_pos + Vector2(-8, -25), Vector2(180, 34)), Color("#0b090ddd"), true)
		draw_string(font, label_pos, room.get("display_name", room_id), HORIZONTAL_ALIGNMENT_LEFT, 180.0, 22, Color("#f6ebd4"))
		var texture: Texture2D = props.get(room.get("icon", ""))
		if texture != null:
			var size = Vector2(92, 92)
			if room.get("type", "") == "core":
				size = Vector2(120, 120)
			draw_texture_rect(texture, Rect2(graph.center(room_id) - size * 0.5 + Vector2(0, -8), size), false)
		if room.get("type", "") == "build_slot":
			draw_arc(graph.center(room_id), 48.0, 0.0, TAU, 48, Color("#b15dff"), 3.0)

func _draw_room_tiles(rect: Rect2, room_type: String) -> void:
	var texture = spike_texture if room_type == "trap" else floor_texture
	if texture == null:
		return
	var end_x = int(rect.position.x + rect.size.x)
	var end_y = int(rect.position.y + rect.size.y)
	for x in range(int(rect.position.x), end_x, 64):
		for y in range(int(rect.position.y), end_y, 64):
			draw_texture_rect(texture, Rect2(Vector2(x, y), Vector2(64, 64)), false)
	if wall_texture != null:
		for x in range(int(rect.position.x), end_x, 64):
			draw_texture_rect(wall_texture, Rect2(Vector2(x, rect.position.y - 32), Vector2(64, 64)), false)

func _panel(rect: Rect2, color: Color, border: Color = Color("#3b3143")) -> Panel:
	var panel = Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _style(color, border, 2))
	ui_layer.add_child(panel)
	return panel

func _label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int = 20, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label = Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Control, text: String, rect: Rect2, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_stylebox_override("normal", _style(Color("#17141ddd"), Color("#57485e"), 2))
	button.add_theme_stylebox_override("hover", _style(Color("#2a1a37ee"), Color("#a65dff"), 2))
	button.add_theme_stylebox_override("pressed", _style(Color("#35194dee"), Color("#d6a5ff"), 2))
	button.add_theme_color_override("font_color", Color("#eee5f4"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _texture(parent: Control, path: String, rect: Rect2) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.position = rect.position
	texture_rect.size = rect.size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if path != "":
		texture_rect.texture = _load_png(path)
	parent.add_child(texture_rect)
	return texture_rect

func _style(color: Color, border: Color, width: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin(SIDE_LEFT, 8)
	style.set_content_margin(SIDE_RIGHT, 8)
	style.set_content_margin(SIDE_TOP, 8)
	style.set_content_margin(SIDE_BOTTOM, 8)
	return style

