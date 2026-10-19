extends "res://tools/tests/V130RB04Stacking.gd"
## Paired 0119 entry copies. Only the command policy differs between each pair.
var command_mode := "none"
var unit_only := false
var capture_mode := false
var command_events: Array = []
var captures: Array = []
var command_coverage: Array = []

func write_json(id: String, data) -> void:
	var f := FileAccess.open("res://tmp/v130r_commands/"+label+"/"+id+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"\t")); f.close()

func run() -> void:
	started=Time.get_ticks_msec(); label="paired"; stack_source="v13_final"
	stack_days="5,15,27,30"; stack_seeds="130401,130402,130403"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("label="): label=arg.get_slice("=",1)
		if arg=="unit=true": unit_only=true
		if arg=="capture=true": capture_mode=true
	expect(OS.get_user_data_dir().replace("\\","/").contains("v130r_commands"),"isolated command test profile")
	if not failures.is_empty(): get_tree().quit(1); return
	if DisplayServer.get_name()=="headless":
		cosmetic_controller=load("res://tools/tests/V130RB04FastController.gd")
		cosmetic_controller.take_over_path("res://scripts/game/ApprovedBattleController.gd")
	await create_game(); base_controller=game.combat_scene
	if unit_only:
		run_seed=130401
		var snapshot := read_entry(5)
		if await restore_entry(snapshot): await battle_day()
	else:
		for day_text in ("15" if capture_mode else stack_days).split(","):
			var day := int(day_text)
			for seed_text in ("130401" if capture_mode else stack_seeds).split(","):
				run_seed=int(seed_text)
				var snapshot := read_entry(day)
				for policy in (["crisis"] if capture_mode else ["none","crisis"]):
					command_mode=policy
					var failures_before := failures.size()
					await restore_entry(snapshot)
					if failures.size()>failures_before: await finish_commands(); return
					seed(run_seed+day*1000)
					var result := await battle_day()
					result.merge({"seed":run_seed,"day":day,"policy":policy,"entry_file_sha256":FileAccess.get_sha256(entry_path(day))})
					rows.append(result); write_json("battles",rows)
					print("COMMAND_PAIR ",run_seed," D",day," ",policy," win=",result.get("win",false)," HP=",result.get("hp",-1)," commands=",command_events.size())
					# Complete the declared matrix even if a prior battle missed the
					# crisis trigger. Keep every failure visible in the final evidence.
	await finish_commands()

func entry_path(day: int) -> String:
	return "res://tmp/v130r_b04/"+stack_source+"/checkpoints/"+str(run_seed)+"_"+str(day)+".json"

func read_entry(day: int) -> Dictionary:
	expect(FileAccess.file_exists(entry_path(day)),"0119 real campaign entry exists")
	return JSON.parse_string(FileAccess.get_file_as_string(entry_path(day)))

func finish_commands() -> void:
	if not unit_only:
		expect(command_coverage.any(func(row): return row.status=="BOTH_ACCEPTED"),"suite actually exercises both accepted crisis orders")
	write_json("checks",{"checks":checks,"failures":failures,"elapsed_msec":Time.get_ticks_msec()-started,"captures":captures,"command_coverage":command_coverage})
	game._shutdown_audio_for_exit(); game.campaign_autosave_pending=false
	game.queue_free(); await frames(5)
	get_tree().quit(0 if failures.is_empty() else 1)

func start_test_battle():
	var v := view()
	v.monster_ui.set_mode("place"); place_defenders(v); await frames(2)
	game.global_directive=Constants.DIRECTIVE_ALL_OUT # A previously leaked save/stance.
	for i in 12:
		v=view()
		if v.battle!=null: break
		v.start_battle(); await drain(); await frames(2)
	expect(v.battle!=null,"actual approved battle starts")
	if v.battle==null: return null
	if not game.start_flow.command_seen: game.start_flow.ack_commands()
	var b=v.battle
	b.set_speed(1.0); v.set_physics_process(false)
	for unit in game.monster_units+game.enemy_units: unit.set_physics_process(false)
	expect(game.global_directive==Constants.DIRECTIVE_DEFENSE,"battle start discards previous attack stance")
	expect(b.command=="" and b.command_target==null and b.command_remaining()==0,"battle starts without a lingering order")
	return b

func battle_day() -> Dictionary:
	var b=await start_test_battle()
	if b==null: return {"error":"battle not started"}
	if unit_only:
		await test_commands(b)
		return {}
	var hp_start := GameState.demon_lord_hp
	var max_hp_start := GameState.demon_lord_max_hp
	var assignments: Dictionary=view().monster_ui.assignments.duplicate(true)
	command_events=[]
	var steps := 0
	var focus_time := -1.0
	var focus_target: Node
	var held := false
	var capture_post := false
	while b.running and game.combat_time<600:
		if game.current_screen=="dialogue": await drain(); continue
		if game.combat_speed_intro_open: game._dismiss_combat_speed_intro()
		if game.story_combat_overlay_open and game.story_director.is_active():
			game._story_advance_dialogue(); await frames(1); continue
		if command_mode=="crisis":
			if focus_time<0:
				var target := crisis_target(b)
				if target!=null:
					var accepted: bool=b.issue_command("focus_attack",target.position,target)
					expect(accepted,"crisis focus accepted")
					focus_time=game.combat_time
					focus_target=target
					command_events.append({"id":"focus_attack","accepted":accepted,"time":game.combat_time,"target":target.unit_id,"position":[target.position.x,target.position.y]})
					if capture_mode: await capture_battle("focus_active",b)
			elif not held and (game.combat_time>=focus_time+b.COMMAND_SECONDS or not is_instance_valid(focus_target) or not focus_target.is_alive()):
				if game.combat_time>=focus_time+b.COMMAND_SECONDS: expect(game.global_directive==Constants.DIRECTIVE_DEFENSE and b.command=="","focus expires before hold")
				var accepted: bool=b.issue_command("hold_ground")
				expect(accepted,"crisis hold accepted")
				held=true
				command_events.append({"id":"hold_ground","accepted":accepted,"time":game.combat_time})
				if capture_mode: await capture_battle("hold_active",b)
			elif held and not capture_post and b.command=="":
				capture_post=true
				if capture_mode: await capture_battle("commands_expired",b)
		b.physics_process(1.0/60.0)
		for unit in game.monster_units+game.enemy_units:
			if is_instance_valid(unit): unit.set_physics_process(false); unit._physics_process(1.0/60.0)
		for tween in b.active_combat_tweens.duplicate():
			if tween!=null and tween.is_valid(): tween.pause(); tween.custom_step(1.0/60.0)
		steps+=1
		if steps%300==0: await frames(1)
	var result: Dictionary=b.last_result.duplicate(true)
	result.merge({"hp":GameState.demon_lord_hp,"hp_start":hp_start,"max_hp_start":max_hp_start,"defenders":assignments,"steps":steps,"commands":command_events.duplicate(true),"directive":game.global_directive,"survivors":game.monster_units.filter(func(u):return u.is_alive()).size()})
	expect(not b.running,"battle completes before timeout")
	expect(game.global_directive==Constants.DIRECTIVE_DEFENSE and b.command=="","battle finish clears the command stance")
	if command_mode=="crisis":
		# A defended throne may never meet the unchanged 180px crisis trigger.
		# Preserve that missing coverage instead of manufacturing an order/target.
		var status := "NO_CRISIS"
		if focus_time>=0: status="BOTH_ACCEPTED" if held else "ENDED_AFTER_FOCUS"
		if command_events.any(func(row): return not row.accepted): status="REJECTED"
		var coverage := {"seed":run_seed,"day":GameState.day,"status":status,"orders":command_events.size()}
		command_coverage.append(coverage); result.command_coverage=coverage
		if held: expect(command_events.size()==2,"triggered crisis records both issued orders")
	await frames(5); await drain(); await frames(2)
	return result

func crisis_target(b) -> Node:
	# One observable crisis: an enemy reaches the final 180px approach to the throne.
	# The same fixed trigger and target ranking apply to every seed and day.
	for enemy in game.enemy_units:
		if enemy.is_alive() and enemy.goal_room=="throne" and enemy.position.distance_to(b.goal_point(enemy))<=180: return enemy
	return null

func capture_battle(id: String, b) -> void:
	view().battle_ui.refresh()
	await RenderingServer.frame_post_draw
	var path := "res://tmp/v130r_commands/"+label+"/"+id+".png"
	get_viewport().get_texture().get_image().save_png(path)
	var state := {"id":id,"path":path,"time":game.combat_time,"command":b.command,"remaining":b.command_remaining(),"directive":game.global_directive,"size":get_viewport().get_visible_rect().size}
	captures.append(state); write_json("captures",captures)

func test_commands(b) -> void:
	var unit: Node=game.monster_units[0]
	b.spawn_enemy("explorer")
	var target: Node=game.enemy_units.back()
	target.position=b.home(unit)+Vector2(10,0)
	var other: Node=b.make_unit("explorer",DataRegistry.enemy("explorer"),Constants.FACTION_ENEMY,"entrance")
	other.position=unit.position; game.enemy_units.append(other)
	var unit_rows: Array=[]
	for id in ["rally","focus_attack","emergency_retreat","hold_ground","lure_retreat"]:
		b.reset_command(); game.combat_time=10.0
		unit.position=b.home(unit); unit.stop_navigation()
		var point: Vector2=b.map.center("throne")
		expect(b.issue_command(id,point,target if id=="focus_attack" else null),id+" accepted")
		var expected := Constants.DIRECTIVE_ALL_OUT if id=="focus_attack" else (Constants.DIRECTIVE_SURVIVAL if id=="emergency_retreat" else Constants.DIRECTIVE_DEFENSE)
		expect(game.global_directive==expected,id+" active stance")
		var atk: float=b._directive_attack_multiplier(unit)
		var taken: int=b._apply_directive_damage_taken_modifier(unit,1000)
		expect(is_equal_approx(atk,1.15 if id=="focus_attack" else (.9 if id=="emergency_retreat" else 1.0)),id+" active attack multiplier")
		expect(taken==(450 if id=="emergency_retreat" else 500),id+" active incoming multiplier")
		expect(b._directive_attack_multiplier(target)==1.0 and b._apply_directive_damage_taken_modifier(target,1000)==1000,id+" does not buff enemies")
		b.update_monster_path(unit)
		if id in ["rally","emergency_retreat","lure_retreat"]:
			expect(not unit.path_points.is_empty(),id+" moves to command point")
			expect(unit.path_points.back().distance_to(b.command_point)<80,id+" path reaches chosen destination")
		elif id=="hold_ground": expect(unit.path_points.is_empty(),"hold stays at defense post")
		else:
			expect(b.local_target(unit)==target,"focus overrides nearest target")
			expect(b._combat_action_target(unit,[other,target],100)==target,"focus attack chooses selected enemy")
		if id=="lure_retreat": expect(target.forced_attack_target(game.monster_units,260)!=null,"lure taunts nearby enemy")
		game.combat_time=15.99
		expect(b.command_remaining()>0,id+" persists until deadline")
		view().battle_ui.refresh()
		expect(view().battle_ui.command_timers[id].visible and view().battle_ui.command_timers[id].text!="",id+" visible remaining seconds")
		game.combat_time=16.0
		# Exercise real expiry on the next simulation tick, including the exact boundary.
		b.physics_process(1.0/60.0)
		expect(b.command=="" and b.command_target==null and b.command_point==Vector2.ZERO and b.command_remaining()==0,id+" clears expired target and movement")
		expect(game.global_directive==Constants.DIRECTIVE_DEFENSE and b._directive_attack_multiplier(unit)==1.0 and b._apply_directive_damage_taken_modifier(unit,1000)==500,id+" returns to defense multipliers")
		view().battle_ui.refresh()
		expect(not view().battle_ui.command_timers[id].visible,id+" timer disappears after expiry")
		unit.position=b.home(unit); unit.stop_navigation(); b.update_monster_path(unit)
		expect(b.command_target==null,id+" leaves ordinary target selection")
		expect(b._combat_action_target(unit,[other,target],100)==other,id+" ordinary attacks stop preferring the former focus")
		for enemy in game.enemy_units: enemy.down=true
		unit.position=b.map.center("throne"); unit.stop_navigation(); b.update_monster_path(unit)
		expect(not unit.path_points.is_empty() and unit.path_points.back().distance_to(b.home(unit))<80,id+" expired movement returns to defense post")
		for enemy in game.enemy_units: enemy.down=false
		unit_rows.append({"id":id,"active_attack":atk,"active_taken_per_1000":taken,"expired_attack":b._directive_attack_multiplier(unit),"expired_taken_per_1000":b._apply_directive_damage_taken_modifier(unit,1000)})
	target._physics_process(4.1)
	expect(target.forced_attack_target(game.monster_units,260)==null,"lure forced target expires with the original four-second status")
	b.issue_command("focus_attack",target.position,target)
	var deadline: float=b.command_until
	expect(not b.issue_command("focus_attack") and b.command_until==deadline,"invalid focus preserves existing command")
	b.issue_command("hold_ground")
	expect(b.command_target==null and game.global_directive==Constants.DIRECTIVE_DEFENSE,"replacement immediately clears focus")
	b.issue_command("emergency_retreat")
	# Campaign snapshots are taken on the management boundary, using its graph.
	# The live battle map deliberately does not implement the legacy save graph API.
	game.graph=b.original_graph; game.rooms=b.original_rooms
	game.current_screen=Constants.SCREEN_MANAGEMENT
	var saved: Dictionary=game._campaign_save_payload("management")
	expect(saved.world.global_directive==Constants.DIRECTIVE_DEFENSE,"save capture excludes temporary stance")
	# Real atomic store and parser, at a test-only path; no personal save is opened.
	var path := "user://command_resume_copy.json"
	var store=preload("res://scripts/core/CampaignSaveStore.gd")
	var summary: Dictionary=game._campaign_save_summary("management")
	var written: Dictionary=store.write(saved,summary,path)
	expect(written.ok,"test-only campaign save writes through real store")
	if not written.ok: write_json("save_error",written); return
	var loaded: Dictionary=store.inspect(path)
	expect(loaded.status=="valid","test-only campaign save rereads through real parser")
	if loaded.status!="valid": return
	b.reset_command()
	game.combat_scene=base_controller
	expect(game._restore_campaign_payload(loaded.payload),"saved copy resumes")
	expect(game.global_directive==Constants.DIRECTIVE_DEFENSE,"resumed save uses defense")
	for stale in [Constants.DIRECTIVE_ALL_OUT,Constants.DIRECTIVE_SURVIVAL]:
		var legacy: Dictionary=saved.duplicate(true); legacy.world.global_directive=stale
		expect(game._restore_campaign_payload(legacy),"old leaked save restores")
		expect(game.global_directive==Constants.DIRECTIVE_DEFENSE,"old leaked stance normalizes to defense")
	# The shipping v6 envelope must use the same normalized world payload.
	# B04's diagnostic snapshots are legacy-only and include newer species that
	# its v1-to-v2 importer cannot map. Use the existing v5 compatibility copy.
	var fixture_path := "res://tmp/v130_m6/original_copies/campaign_save_v5.json"
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	var migration: Dictionary=game.SaveV5ToV6MigratorScript.migrate_envelope(fixture,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)
	expect(migration.ok,"existing v5 test fixture converts to native v6")
	if not migration.ok: return
	game.campaign_save_v5_envelope=migration.envelope.duplicate(true)
	var migrated: Dictionary=game._campaign_v6_primary_inspection(migration.envelope)
	expect(game._restore_campaign_payload(migrated.payload),"native v6 fixture restores")
	game.current_screen=Constants.SCREEN_MANAGEMENT; game.combat_scene=b
	game.global_directive=Constants.DIRECTIVE_ALL_OUT
	game.campaign_save_enabled=true; game.campaign_save_v6_enabled=true
	game.campaign_save_v6_path="user://command_resume_v6_copy.json"
	var v6_written: bool=game._write_campaign_v6_snapshot()
	expect(v6_written,"v6 test copy writes through production store")
	if not v6_written:
		write_json("v6_error",{"error":game.campaign_save_error}); return
	var v6: Dictionary=game._inspect_campaign_v6()
	expect(v6.get("status")=="valid","v6 test copy validates through production parser")
	if v6.get("status")=="valid":
		expect(v6.payload.world.global_directive==Constants.DIRECTIVE_DEFENSE,"v6 envelope excludes temporary attack stance")
		game.combat_scene=base_controller
		expect(game._restore_campaign_payload(v6.payload),"v6 copy resumes through production restore")
		expect(game.global_directive==Constants.DIRECTIVE_DEFENSE,"v6 continue uses defense")
		var leaked: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.campaign_save_v6_path))
		leaked.active_run.legacy_payload.world.global_directive=Constants.DIRECTIVE_ALL_OUT
		var v6_store=preload("res://scripts/systems/save/CampaignSaveV6Store.gd")
		var leaked_path := "user://command_leaked_v6_copy.json"
		var leak_write: Dictionary=v6_store.write(leaked,leaked_path,DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)
		expect(leak_write.ok,"old leaking v6 save is reproduced in a test-only copy")
		game.campaign_save_v6_path=leaked_path
		var old_v6: Dictionary=game._inspect_campaign_v6()
		expect(old_v6.get("status")=="valid","old leaking v6 copy remains readable")
		if old_v6.get("status")=="valid":
			expect(game._restore_campaign_payload(old_v6.payload),"old leaking v6 copy resumes")
			expect(game.global_directive==Constants.DIRECTIVE_DEFENSE,"old leaking v6 continue returns to defense")
	game.campaign_save_enabled=false; game.campaign_save_v6_enabled=false
	write_json("unit_effects",unit_rows)
	expect(not game._has_defense_wave_for_day(29),"DAY29 remains preparation only")
	# A second real battle after the restore must independently reset its stance.
	await restore_entry(read_entry(5))
	var next_battle=await start_test_battle()
	expect(next_battle!=null and game.global_directive==Constants.DIRECTIVE_DEFENSE,"next battle after save/continue uses defense")
	if next_battle==null: return
	next_battle.issue_command("hold_ground")
	var remaining: float=next_battle.command_remaining()
	next_battle.set_pause_state(true)
	next_battle.physics_process(.1)
	expect(is_equal_approx(next_battle.command_remaining(),remaining),"pause freezes command duration")
	next_battle.set_speed(3)
	next_battle.physics_process(.1)
	expect(is_equal_approx(next_battle.command_remaining(),remaining-.3),"duration follows x3 simulation time")
	next_battle.spawn_enemy("explorer")
	var last_target: Node=game.enemy_units.back()
	next_battle.issue_command("focus_attack",last_target.position,last_target)
	next_battle.finish_combat(false,"command lifecycle test")
	expect(not next_battle.running and next_battle.command=="" and next_battle.command_target==null and game.global_directive==Constants.DIRECTIVE_DEFENSE,"finishing during active focus clears stance and target")
	await frames(5)
