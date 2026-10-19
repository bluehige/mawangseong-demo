extends "res://tools/tests/V130RB04Stacking.gd"
## Same real first-cycle entry copies before/after; no stat or wallet fixtures.
func run() -> void:
	started=Time.get_ticks_msec(); stack_source="v13_final"
	stack_days="1,5,15,20,27,30"; stack_seeds="130401,130402,130403"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("label="): label=arg.get_slice("=",1)
	expect(OS.get_user_data_dir().replace("\\","/").contains("v130r_engage"),"isolated engagement sample")
	if not failures.is_empty(): get_tree().quit(1); return
	cosmetic_controller=load("res://tools/tests/V130RB04FastController.gd")
	cosmetic_controller.take_over_path("res://scripts/game/ApprovedBattleController.gd")
	for day_text in stack_days.split(","):
		var day := int(day_text)
		for seed_text in stack_seeds.split(","):
			run_seed=int(seed_text)
			await create_game(); base_controller=game.combat_scene
			var path := "res://tmp/v130r_b04/"+stack_source+"/checkpoints/"+str(run_seed)+"_"+str(day)+".json"
			expect(FileAccess.file_exists(path),"actual reference campaign reached sample date")
			if not FileAccess.file_exists(path): await finish_stacking(); return
			var snapshot: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
			if not await restore_entry(snapshot): await finish_stacking(); return
			seed(run_seed+day*1000)
			var result := await battle_day()
			result.merge({"seed":run_seed,"day":day,"layout":"recommended","entry_file_sha256":FileAccess.get_sha256(path)},false)
			rows.append(result); write_json("days",rows)
			print("ENGAGEMENT_SAMPLE ",run_seed," D",day," contacts=",result.engagement.contacts," engaged=",result.engagement.engaged," passes=",result.engagement.ignored_passes)
			if not failures.is_empty(): await finish_stacking(); return
			game._shutdown_audio_for_exit(); game.campaign_autosave_pending=false
			game.queue_free(); await frames(5)
			game=null
	write_json("checks",{"checks":checks,"failures":failures,"source":stack_source,"days":stack_days,"seeds":stack_seeds,"elapsed_msec":Time.get_ticks_msec()-started})
	get_tree().quit(0 if failures.is_empty() else 1)
