extends "res://tools/tests/V130RB04Campaign.gd"
## Continuous campaign through production behavior; only cosmetic rendering is reduced.
const AUDIT_OUT := "res://tmp/v130r_release_blockers/"
var observations: Array = []
var resume_only := false
func write_json(id: String, data) -> void:
	var f := FileAccess.open(AUDIT_OUT+"campaign_"+str(run_seed)+"_"+id+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"\t",false)); f.close()
func write_entry_snapshot(_v: Node) -> bool: return true
func event(tag: String, extra: Dictionary = {}) -> void:
	observations.append({"tag":tag,"day":GameState.day,"screen":game.current_screen,"hp":GameState.demon_lord_hp,"extra":extra})
	write_json("events",observations)
	print("REAUDIT_EVENT ",run_seed," D",GameState.day," ",tag)
func save_state() -> Dictionary:
	return {"day":GameState.day,"hp":GameState.demon_lord_hp,"gold":GameState.gold,"mana":GameState.mana,"food":GameState.food,"food_state":GameState.food_state.duplicate(true),"completed":game.campaign_completed,"postgame":game.campaign_postgame_active,"ending":game.resolved_campaign_ending_id,"roster":game.monster_roster.duplicate(true),"layout":Buildings.snapshot(view().placement) if view()!=null else {}}
func save_postgame() -> void:
	expect(game.current_screen=="ending" and game.campaign_completed,"natural ending screen reached")
	if game.current_screen!="ending": return
	await press("PostgameContinueButton"); await drain(); await frames(5)
	expect(game.campaign_postgame_active and game.current_screen=="management","postgame opened by real ending button")
	game._schedule_campaign_autosave("management")
	expect(game._flush_campaign_autosave(),"postgame save written: "+game.campaign_save_error)
	write_json("postgame_before",save_state())
	event("postgame_saved",{"save_status":game.campaign_save_status,"v6_path":game.campaign_save_v6_path})
func resume_postgame() -> void:
	await press("TitleStartButton"); await press("CampaignContinueButton"); await drain(); await frames(8)
	var before: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(AUDIT_OUT+"campaign_"+str(run_seed)+"_postgame_before.json"))
	var after: Dictionary=JSON.parse_string(JSON.stringify(save_state(),"",false))
	for key in before:
		expect(JSON.stringify(before[key],"",true)==JSON.stringify(after[key],"",true),"process restart postgame preserves "+key)
	expect(game.current_screen=="management" and game.campaign_postgame_active and GameState.day==30,"process restart resumes DAY30 postgame management")
	write_json("postgame_after",after)
	event("postgame_resumed",{"checks":checks,"failures":failures})
func run() -> void:
	started=Time.get_ticks_msec(); retries=1; fast=true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("seed="): run_seed=int(arg.get_slice("=",1))
		if arg=="resume=true": resume_only=true
	expect(OS.get_user_data_dir().replace("\\","/").contains("v130r_release_blockers"),"isolated audit save profile")
	if not failures.is_empty(): get_tree().quit(1); return
	if not resume_only and DisplayServer.get_name()=="headless":
		cosmetic_controller=load("res://tools/tests/V130RB04FastController.gd")
		cosmetic_controller.take_over_path("res://scripts/game/ApprovedBattleController.gd")
	await create_game()
	if resume_only: await resume_postgame()
	else:
		await campaign()
		write_json("days",rows); write_json("purchases",purchases)
		if game.campaign_completed: await save_postgame()
		else: expect(false,"campaign reaches DAY30 ending")
	write_json("resume_checks" if resume_only else "checks",{"checks":checks,"failures":failures,"elapsed_msec":Time.get_ticks_msec()-started,"resume":resume_only,"user_dir":OS.get_user_data_dir()})
	game._shutdown_audio_for_exit(); game.campaign_autosave_pending=false
	game.queue_free(); await frames(5)
	get_tree().quit(0 if failures.is_empty() else 1)
