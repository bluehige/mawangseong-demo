extends RefCounted

const Silky = preload("res://scripts/systems/monsters/SilkyCombatService.gd")
const Popo = preload("res://scripts/systems/monsters/PopoCombatService.gd")
const Constants = preload("res://scripts/core/Constants.gd")
var _combat_ref: WeakRef
var combat:
	get: return _combat_ref.get_ref() if _combat_ref != null else null
var thread: Dictionary = {}
var relays: Dictionary = {}

func setup(controller) -> void:
	_combat_ref = weakref(controller)

func clear() -> void:
	_remove_thread()
	for relay in relays.values():
		if is_instance_valid(relay.caster): relay.caster.stop_navigation()
	relays.clear()
	if combat == null or combat.root == null: return
	for unit in combat.root.monster_units:
		if is_instance_valid(unit): unit.clear_night_relay_buffs()

func thread_active() -> bool:
	return not thread.is_empty() and bool(thread.state.thread.get("active", false))

func thread_anchor(caster: Node) -> Dictionary:
	var graph = combat.root.graph
	if graph == null or not graph.has_method("debug_socket_cells"): return {}
	var sockets: Array = graph.debug_socket_cells()
	var best: Dictionary = {}
	var distance := INF
	var anchor_room: String = graph.room_at_world(caster.global_position)
	for pair in graph.connection_pairs():
		if anchor_room not in [str(pair.from_instance), str(pair.to_instance)]: continue
		var from_socket: Dictionary = {}; var to_socket: Dictionary = {}
		for socket in sockets:
			if socket.instance_id == pair.from_instance and socket.socket_id == pair.from_socket: from_socket = socket
			if socket.instance_id == pair.to_instance and socket.socket_id == pair.to_socket: to_socket = socket
		if from_socket.is_empty() or to_socket.is_empty(): continue
		if from_socket.state not in ["open", "connected"] or to_socket.state not in ["open", "connected"]: continue
		var a: Vector2i = from_socket.cell; var b: Vector2i = to_socket.cell
		if absi(a.x-b.x)+absi(a.y-b.y) != 1: continue
		var start: Vector2 = graph.tile_cell_center(a); var end: Vector2 = graph.tile_cell_center(b)
		var center: Vector2 = (start+end)*.5
		if not graph.is_walkable(center): continue
		var transverse: Vector2 = graph.tile_cell_center(a+Vector2i(0,1) if a.x != b.x else a+Vector2i(1,0))-start
		var current: float = caster.global_position.distance_to(center)
		if current < distance:
			distance = current
			best = {"id":str(pair.from_instance)+":"+str(pair.from_socket), "point":center,
				"a":center-transverse*.5, "b":center+transverse*.5,
				"rooms":[str(pair.from_instance),str(pair.to_instance)]}
	return best

func place_thread(caster: Node, anchor: Dictionary, skill: Dictionary) -> void:
	_remove_thread()
	var result: Dictionary = Silky.place_thread(caster.get_meta("silky_state", {}), "threshold", ["threshold"],
		str(combat.root.monster_roster.get(caster.unit_id, {}).get("specialization_id", "")), skill)
	var marker := Line2D.new()
	marker.name = "SilkyThresholdThread"; marker.points = PackedVector2Array([anchor.a, anchor.b])
	marker.width = 2.0; marker.default_color = Color("#c3d4ed"); marker.z_index = 1
	combat.root.effect_root.add_child(marker)
	thread = {"caster":caster,"state":result.state,"anchor":anchor.duplicate(true),"seen":{},"previous":{},"fire_seen":{},"marker":marker}
	for enemy in combat.root.enemy_units:
		if is_instance_valid(enemy): thread.previous[enemy.get_instance_id()] = enemy.global_position
	caster.set_meta("silky_state", result.state)
	caster.play_skill(anchor.point)
	combat.spawn_effect_burst("fx_silky_thread", anchor.point, Vector2.ZERO, Vector2.ONE, 11.0)
	combat.root._log("실키가 문턱에 거미실을 설치했습니다. 첫 %d명 통과에 둔화." % int(result.state.thread.remaining_targets))

func tick_thread() -> void:
	for id in relays.keys():
		if not is_instance_valid(relays[id].caster) or not relays[id].caster.is_alive(): relays.erase(id)
	if not thread_active(): return
	for enemy in combat.root.enemy_units:
		if not is_instance_valid(enemy) or not enemy.is_alive(): continue
		var id: int = enemy.get_instance_id()
		var current: Vector2 = enemy.global_position
		var previous: Vector2 = thread.previous.get(id, current)
		thread.previous[id] = current
		if thread.seen.has(id) or current.distance_squared_to(previous) < .0001: continue
		if Geometry2D.segment_intersects_segment(previous, current, thread.anchor.a, thread.anchor.b) == null: continue
		var applied: Dictionary = Silky.trigger_thread(thread.state, str(id))
		thread.state = applied.state
		if not applied.applied: continue
		thread.seen[id] = true
		enemy.apply_slow(float(applied.effect.duration), float(applied.effect.move_multiplier))
		combat.spawn_effect_burst("fx_silky_thread", current, Vector2.ZERO, Vector2.ONE, 11.0)
		_sync_thread_state()
		combat.root._log("거미실 통과: %s · %.0f%% 둔화 %.0f초." % [enemy.display_name, (1.0-float(applied.effect.move_multiplier))*100, float(applied.effect.duration)])
		if not thread_active(): _remove_marker(); break

func fire_hit(source: Vector2, destination: Vector2, rooms: Array, token: String) -> void:
	if not thread_active() or thread.fire_seen.has(token): return
	var hit: bool = Geometry2D.segment_intersects_segment(source, destination, thread.anchor.a, thread.anchor.b) != null
	for room in rooms:
		if room in thread.anchor.rooms: hit = true
	if not hit: return
	thread.fire_seen[token] = true
	thread.state = Silky.apply_fire_hit(thread.state)
	_sync_thread_state()
	if not thread_active():
		_remove_marker()
		combat.root._log("화염으로 거미실이 제거되었습니다.")

func relay_target(caster: Node) -> Dictionary:
	if relays.has(caster.get_instance_id()): return {}
	var candidates: Array = []; var routes: Dictionary = {}
	for ally in combat.root.monster_units:
		if not is_instance_valid(ally) or not ally.is_alive() or ally == caster or ally.current_room == caster.current_room: continue
		var danger := 0
		for enemy in combat.root.enemy_units:
			if is_instance_valid(enemy) and enemy.is_alive() and enemy.current_room == ally.current_room: danger += 1
		if danger == 0: continue
		var route: Array = combat.root.graph.path_to_point(caster.global_position, ally.global_position)
		if not _route_safe(caster.global_position, route, ally.global_position): continue
		var length := 0.0; var previous: Vector2 = caster.global_position
		for point in route: length += previous.distance_to(point); previous = point
		var id := str(ally.get_instance_id()); routes[id] = {"target":ally,"route":route}
		candidates.append({"id":id,"alive":true,"room_id":ally.current_room,"floor_id":"1F","danger":danger,"distance":length})
	var target: Dictionary = Popo.choose_relay_target({"id":str(caster.get_instance_id()),"floor_id":"1F"}, candidates, [])
	return routes.get(str(target.get("target_id", "")), {})

func begin_relay(caster: Node, target: Node, skill: Dictionary) -> bool:
	var route: Array = combat.root.graph.path_to_point(caster.global_position, target.global_position)
	if not _route_safe(caster.global_position, route, target.global_position): return false
	relays[caster.get_instance_id()] = {"caster":caster,"target":target,"skill":skill,"last_position":caster.global_position,"stall":0.0}
	caster.set_path(route)
	caster.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "중계 이동 · 도착 후 강화", target.display_name)
	return true

func update_relay(caster: Node, delta: float) -> bool:
	var id: int = caster.get_instance_id()
	if not relays.has(id): return false
	var relay: Dictionary = relays[id]; var target = relay.target
	if not is_instance_valid(target) or not target.is_alive() or target.is_queued_for_deletion():
		cancel_relay(caster, "지원 대상 전투 불능"); return false
	var destination: Vector2 = target.global_position
	if caster.global_position.distance_to(destination) <= caster.PATH_POINT_REACHED_RADIUS:
		var effect: Dictionary = Popo.apply_night_relay({"target_id":str(target.get_instance_id())},
			str(combat.root.monster_roster.get(caster.unit_id, {}).get("specialization_id", "")), relay.skill)
		var source := str(id)
		caster.apply_night_relay_buff(source, float(effect.duration), float(effect.popo_buff.move_multiplier), float(effect.popo_buff.attack_interval_multiplier))
		target.apply_night_relay_buff(source, float(effect.duration), float(effect.target_buff.move_multiplier), float(effect.target_buff.attack_interval_multiplier))
		caster.stop_navigation(); relays.erase(id)
		caster.set_meta("night_relay_arrivals", int(caster.get_meta("night_relay_arrivals",0))+1)
		combat.spawn_effect_burst("fx_popo_relay", target.global_position, Vector2.ZERO, Vector2.ONE, 11.0)
		combat.root._log("포포가 %s에게 도착했습니다. 둘 모두 %.0f초 중계 강화." % [target.display_name,float(effect.duration)])
		return true
	if caster.duo_move_lock_timer > 0.0 or caster.seal_move_lock_timer > 0.0: return true
	if caster.global_position.distance_to(relay.last_position) <= caster.NAVIGATION_PROGRESS_EPSILON:
		relay.stall = float(relay.stall)+delta
	else: relay.stall = 0.0
	relay.last_position = caster.global_position
	if float(relay.stall) >= caster.NAVIGATION_STALL_TIMEOUT:
		cancel_relay(caster, "보행 진행 없음"); return false
	var route: Array = combat.root.graph.path_to_point(caster.global_position, destination)
	if not _route_safe(caster.global_position, route, destination):
		cancel_relay(caster, "도착 경로 없음"); return false
	if caster.path_points.is_empty() or caster.path_points[-1].distance_to(destination) > caster.PATH_POINT_REACHED_RADIUS:
		caster.set_path(route)
	caster.set_tactical_state(Constants.UNIT_STATE_MOVE_TO_TARGET, "중계 이동 · 도착 후 강화", target.display_name)
	return true

func cancel_relay(caster: Node, reason: String) -> void:
	if relays.erase(caster.get_instance_id()):
		caster.stop_navigation()
		combat.root._log("밤길 중계 이동 취소: %s. 시전 후 마력·대기시간은 유지됩니다." % reason)

func _route_safe(start: Vector2, route: Array, destination: Vector2) -> bool:
	if combat.root.monster_units.is_empty(): return false
	var step_size:float = combat.root.monster_units[0].PATH_POINT_REACHED_RADIUS
	if route.is_empty() or route[-1].distance_to(destination) > step_size: return false
	var previous := start
	for point in route:
		if not point is Vector2 or not combat.root.graph.is_walkable(point): return false
		var length: float = previous.distance_to(point)
		for step in range(1, maxi(1, ceili(length/step_size))+1):
			if not combat.root.graph.is_walkable(previous.lerp(point,float(step)/maxi(1,ceili(length/step_size)))): return false
		previous = point
	return true

func _sync_thread_state() -> void:
	if is_instance_valid(thread.caster): thread.caster.set_meta("silky_state",thread.state)

func _remove_marker() -> void:
	if not thread.is_empty() and is_instance_valid(thread.get("marker")): thread.marker.queue_free()

func _remove_thread() -> void:
	if not thread.is_empty():
		thread.state.thread.active = false
		_sync_thread_state(); _remove_marker()
	thread.clear()
