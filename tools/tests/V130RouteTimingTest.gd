extends Node

const Game = preload("res://scenes/game/GameRoot.tscn")
const Build = preload("res://scripts/map_builder/MapBuildService.gd")
const Graph = preload("res://scripts/dungeon_quarter/ModuleGraph.gd")
var game: Node
var rows: Array = []
var failures: Array[String] = []

func _ready() -> void: call_deferred("run")
func settle(count: int = 3) -> void:
	for i in range(count): await get_tree().process_frame
func length_of(path: Array) -> float:
	var length := 0.0
	for i in range(1,path.size()): length += path[i-1].distance_to(path[i])
	return length

func run() -> void:
	for sample in ["default","near","far"]:
		game = Game.instantiate(); game.campaign_save_enabled = false; add_child(game); await settle()
		game.onboarding_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
		game.story_feature_enabled = false; game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
		GameState.day = 1
		seed(1306)
		var source: Dictionary = game._plot_source_from_graph()
		if sample != "default":
			# A small set of legal free placements; stats and grade remain identical.
			var best := INF if sample == "near" else -1.0
			var chosen: Dictionary = {}
			var throne := Vector2i.ZERO
			for row in source.placed_modules:
				if row.instance_id == "throne": throne = Vector2i(int(row.grid_origin[0]),int(row.grid_origin[1]))
			for offset in [Vector2i(-2,0),Vector2i(-1,0),Vector2i(1,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,-1),Vector2i(0,1),Vector2i(0,2),Vector2i(3,-3),Vector2i(-3,3)]:
				var cell: Vector2i = throne+offset
				var candidate := source.duplicate(true)
				for row in candidate.placed_modules:
					if row.instance_id == "throne": row.grid_origin = [cell.x,cell.y]
				var layout := Build.prepare_layout(candidate,DataRegistry.quarter_modules,0)
				if layout.has("map_build_errors"): continue
				var graph := Graph.new(); graph.setup_quarter(DataRegistry.quarter_modules,layout,game.rooms)
				var length := length_of(graph.path_points("outside_approach","throne"))
				if (sample == "near" and length < best) or (sample == "far" and length > best): best = length; chosen = candidate
			if chosen.is_empty(): failures.append("no legal "+sample+" route")
			else: game.runtime_plot_layout = chosen; game._setup_dungeon_graph()
		var path: Array = game.graph.path_points("outside_approach","throne")
		game.set_physics_process(false)
		game.combat_scene.start_combat()
		game._set_speed(1.0)
		game.set_process(false)
		var first_contact := -1.0
		var first_throne := -1.0
		var first_enemy: Node
		var first_spawn := -1.0
		var spawn_room := ""
		var first_room := ""
		var first_room_time := -1.0
		var initial_position := Vector2.ZERO
		var initial_path: Array = []
		var initial_stats: Dictionary = {}
		var spawn_definition: Dictionary = {}
		var first_enemy_id := ""
		var seed_schedule: Array = game.wave_manager.schedule.duplicate(true)
		var stats_hash := JSON.stringify(DataRegistry.enemies).sha256_text()
		# Run the real combat controller and Unit physics at a fixed 60Hz.
		# Engine-owned physics is disabled on these nodes to prevent double steps.
		for step in range(180*60):
			if game.current_screen != "combat": break
			game._physics_process(1.0/60.0)
			if first_enemy==null and not game.enemy_units.is_empty():
				first_enemy=game.enemy_units[0]; first_spawn=game.combat_time
				initial_position=first_enemy.global_position; initial_path=first_enemy.path_points.duplicate()
				spawn_room=game.graph.exact_room_at_world(initial_position)
				initial_stats={"speed":first_enemy.move_speed,"hp":first_enemy.hp,"atk":first_enemy.atk,"def":first_enemy.def}
				first_enemy_id=first_enemy.unit_id
				spawn_definition=game.combat_scene._scaled_enemy_stats(first_enemy_id,seed_schedule[0]).duplicate(true)
			for unit in game.monster_units+game.enemy_units:
				if not is_instance_valid(unit): continue
				unit.set_physics_process(false)
				if game.combat_scene.presentation_hold or game.combat_paused: continue
				unit._physics_process(1.0/60.0)
				if unit.faction == "enemy" and unit.is_alive():
					if unit.attack_anim_timer > 0 and first_contact < 0: first_contact = game.combat_time
					if unit==first_enemy:
						var actual_room: String=game.graph.exact_room_at_world(unit.global_position)
						if actual_room!="" and actual_room!=spawn_room and not actual_room.begins_with("auto_") and not actual_room.begins_with("outside_") and first_room_time<0:
							first_room=actual_room; first_room_time=game.combat_time-first_spawn
						if actual_room=="throne" and first_throne<0: first_throne=game.combat_time-first_spawn
			if game.combat_scene.skill_actions.is_active(): game.combat_scene.skill_actions.skip()
			if game.combat_paused:
				# Let the existing presentation controller finish its visible action.
				await settle(2)
			if step % 60 == 59: await settle(1)
			if step % 600 == 599: print("TIMING_PROGRESS ",sample," step=",step+1," combat_seconds=",game.combat_time)
		var measured := {"sample":sample,"day":1,"seed":1306,"size":[30,20],"path_points":path.size(),"path_pixels":length_of(path),"first_contact_seconds":first_contact,"first_throne_seconds":first_throne,"combat_seconds":game.combat_time,"outcome":"unfinished" if game.current_screen == "combat" else game.current_screen,"enemy_stats_sha256":stats_hash,"schedule_sha256":JSON.stringify(seed_schedule).sha256_text(),"clock":"real controller + Unit physics, fixed 60Hz, 180 simulation seconds maximum"}
		measured["victory"] = bool(game.result_summary.get("win",false))
		# Separate traversal probe, using the same spawned enemy and native movement.
		# Clone its captured spawn definition/path without inherited combat status.
		var traversal := -1.0
		var throne_entry := -1.0
		var travelled := 0.0
		if is_instance_valid(first_enemy) and not initial_path.is_empty():
			var probe: Node=game._create_unit(first_enemy_id,spawn_definition,"enemy",spawn_room)
			probe.set_physics_process(false); probe.global_position=initial_position
			probe.set_simulation_speed(1.0); probe.set_path(initial_path)
			var goal: Vector2=initial_path.back()
			var consumed := 0
			for tick in range(180*60):
				var old: Vector2=probe.global_position
				var pending: Array=probe.path_points.duplicate()
				probe._physics_process(1.0/60.0)
				travelled+=old.distance_to(probe.global_position)
				var removed: int=pending.size()-probe.path_points.size()
				var covered := 0.0
				var previous: Vector2=old
				for index in range(removed):
					covered+=previous.distance_to(pending[index]); previous=pending[index]
				if covered>probe.effective_move_speed()/60.0+0.1: failures.append("skipped waypoint "+sample)
				if not game.graph.is_walkable(probe.global_position): failures.append("probe outside physical road "+sample)
				consumed+=removed
				if throne_entry<0 and game.graph.exact_room_at_world(probe.global_position)=="throne": throne_entry=(tick+1)/60.0
				if probe.path_points.is_empty():
					if probe.global_position.distance_to(goal)<0.1 and consumed==initial_path.size(): traversal=(tick+1)/60.0
					break
			if probe.move_speed!=initial_stats.speed or probe.atk!=initial_stats.atk or probe.def!=initial_stats.def: failures.append("probe stats changed "+sample)
			probe.queue_free()
		else: failures.append("missing captured first enemy "+sample)
		var actual_path: Array=[initial_position]; actual_path.append_array(initial_path)
		measured.merge({"first_spawn_seconds":first_spawn,"spawn_room":spawn_room,"first_room":first_room,"first_room_seconds":null if first_room_time<0 else first_room_time,"first_throne_seconds":null if first_throne<0 else first_throne,"actual_spawn_path_pixels":length_of(actual_path),"probe_throne_entry_seconds":throne_entry,"probe_complete_seconds":traversal,"probe_travelled_pixels":travelled,"first_enemy_move_speed":initial_stats.get("speed",0),"arrival_status":"arrived" if first_throne>=0 else "downed_before_arrival"},true)
		if traversal<=0 or throne_entry<=0: failures.append("probe did not reach throne "+sample)
		rows.append(measured)
		print("TIMING: ",JSON.stringify(measured))
		game._shutdown_audio_for_exit(); game.queue_free(); await settle()
	if rows.size() == 3:
		if not float(rows[1].path_pixels) < float(rows[0].path_pixels) or not float(rows[2].path_pixels) > float(rows[0].path_pixels): failures.append("route lengths are not distinct")
		for row in rows:
			if row.schedule_sha256 != rows[0].schedule_sha256 or row.enemy_stats_sha256 != rows[0].enemy_stats_sha256: failures.append("timing inputs changed")
	if not float(rows[1].probe_complete_seconds)<float(rows[0].probe_complete_seconds) or not float(rows[0].probe_complete_seconds)<float(rows[2].probe_complete_seconds): failures.append("native traversal timing not sensitive to length")
	var file := FileAccess.open("res://tmp/v130_m5/route_timing.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows":rows,"failures":failures},"\t")); file.close()
	print("V130RouteTimingTest %s samples=%d failures=%s" % ["PASS" if failures.is_empty() else "FAIL",rows.size(),failures])
	get_tree().quit(0 if failures.is_empty() else 1)
