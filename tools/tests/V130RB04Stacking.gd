extends "res://tools/tests/V130RB04Campaign.gd"
## Counterfactuals restore the exact real campaign entry, never a level/resource fixture.
var stack_source := "final_recommended"
var stack_days := "1,5,10,15,20,24,27,30"
var stack_seeds := "130401,130402,130403,130404,130405,130406,130407,130408,130409,130410"
var base_controller: RefCounted

func place_defenders(v: Node) -> void:
	if layout_mode=="recommended":
		super.place_defenders(v)
		return
	v.monster_ui.auto_place()
	var members: Dictionary=v.monster_ui.members
	var unlocked: Array=v.monster_ui.unlocked().filter(func(id): return game.monster_roster.has(members[id].species_id))
	var restricted: Dictionary=v.placement.duplicate(true)
	var topology=preload("res://scripts/map_builder/ApprovedBattleMap.gd").new()
	topology.setup(v.placement)
	var slot_maps := {}
	for building in restricted.defense_points:
		var kind: String=Buildings.building(v.placement,building).kind
		var keep: Array=[]
		var original: Array=[]
		for i in restricted.defense_points[building].size():
			var c: Vector2i=restricted.defense_points[building][i]
			if (layout_mode=="anchor_cluster" and kind in ["barracks","ward_core","throne"]) or (layout_mode=="final_line" and topology.line_for(c)=="final") or (layout_mode=="first_line" and topology.line_for(c)=="1"):
				keep.append(c); original.append(i)
		restricted.defense_points[building]=keep
		slot_maps[building]=original
	# Keep the product's guard roles, then prefer trained real companions over
	# low-level roster order when concentration capacity cannot hold everyone.
	var ranked: Array=unlocked.duplicate()
	ranked.sort_custom(func(a,b):
		var la: int=int(game.monster_roster[members[a].species_id].level)
		var lb: int=int(game.monster_roster[members[b].species_id].level)
		return la>lb or (la==lb and members.keys().find(a)<members.keys().find(b)))
	var ranked_members := {}
	for id in ranked: ranked_members[id]=members[id]
	var assigned := Members.auto_place(restricted,ranked_members,unlocked,v.monster_ui.food_income)
	for id in assigned:
		var target: Dictionary=assigned[id]
		target.slot=slot_maps[target.building][int(target.slot)]
	# Preferences are recommendations, not legal placement restrictions. Fill
	# available concentration slots with the strongest remaining real companions.
	var remaining := unlocked.filter(func(id): return not assigned.has(id))
	remaining.sort_custom(func(a,b):
		var la: int=int(game.monster_roster[members[a].species_id].level)
		var lb: int=int(game.monster_roster[members[b].species_id].level)
		return la>lb if la!=lb else str(a)<str(b))
	for id in remaining:
		if Members.upkeep(assigned,members)+int(members[id].upkeep)>v.monster_ui.food_income: continue
		var placed := false
		for building in slot_maps:
			var used := 0
			for target in assigned.values():
				if target.building==building: used+=1
			if used>=int(Buildings.building(v.placement,building).capacity): continue
			for slot in slot_maps[building]:
				var target := {"building":building,"slot":slot}
				if Members.occupant(assigned,target)!="": continue
				var result := Members.put(v.placement,assigned,id,target,members,unlocked)
				expect(result.ok,"concentration fallback uses the actual legal placement API")
				assigned=result.assignments; placed=true; break
			if placed: break
	v.monster_ui.assignments=assigned
	v.monster_ui.refresh()
	expect(Members.sanitize(v.placement,assigned,members)==assigned,"concentration has unique actual defense cells")
	expect(Members.upkeep(assigned,members)<=v.monster_ui.food_income,"concentration obeys actual food income")
	var counts := {}
	for id in assigned:
		expect(id in unlocked,"concentration deploys only actually owned companions")
		var building: String=assigned[id].building
		counts[building]=int(counts.get(building,0))+1
	for building in counts: expect(counts[building]<=Buildings.building(v.placement,building).capacity,"concentration obeys actual capacity")
	Grade.stash(game,v.placement,assigned)

func restore_entry(snapshot: Dictionary) -> bool:
	if game.combat_scene!=base_controller:
		game.combat_scene._clear_active_combat_tweens()
	game.combat_scene=base_controller
	game.update4_profile=snapshot.update4_profile.duplicate(true)
	game.update4_active_run=snapshot.update4_active_run.duplicate(true)
	var ok: bool=game._restore_campaign_payload(snapshot.payload.duplicate(true))
	expect(ok,"real campaign entry restores")
	await restore_test_map(snapshot)
	await drain(); await frames(2)
	if not ok or view()==null: return false
	for field in ["day","gold","mana","food","demon_lord_hp","demon_lord_max_hp"]:
		expect(GameState.get(field)==snapshot.payload.game_state[field],"paired entry preserves "+field)
	for species in snapshot.payload.world.monster_roster:
		for field in ["level","exp","bond","promotion_id","specialization_id"]:
			expect(game.monster_roster.get(species,{}).get(field)==snapshot.payload.world.monster_roster[species].get(field),"paired entry preserves "+species+" "+field)
	return failures.is_empty()

func finish_stacking() -> void:
	write_json("days",rows)
	write_json("checks",{"checks":checks,"failures":failures,"source":stack_source,"days":stack_days,"seeds":stack_seeds,"elapsed_msec":Time.get_ticks_msec()-started})
	game._shutdown_audio_for_exit(); game.campaign_autosave_pending=false
	game.queue_free(); await frames(5)
	get_tree().quit(0 if failures.is_empty() else 1)

func run() -> void:
	started=Time.get_ticks_msec()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("label="): label=arg.get_slice("=",1)
		if arg.begins_with("stack_source="): stack_source=arg.get_slice("=",1)
		if arg.begins_with("stack_days="): stack_days=arg.get_slice("=",1)
		if arg.begins_with("seeds="): stack_seeds=arg.get_slice("=",1)
		if arg=="raster=full": fast=false
	expect(OS.get_user_data_dir().replace("\\","/").contains("v130r_b04") or OS.get_user_data_dir().replace("\\","/").contains("v130r_engage"),"isolated paired test profile")
	if not failures.is_empty(): get_tree().quit(1); return
	if fast and DisplayServer.get_name()=="headless":
		cosmetic_controller=load("res://tools/tests/V130RB04FastController.gd")
		cosmetic_controller.take_over_path("res://scripts/game/ApprovedBattleController.gd")
	await create_game()
	base_controller=game.combat_scene
	for day_text in stack_days.split(","):
		var day := int(day_text)
		for seed_text in stack_seeds.split(","):
			run_seed=int(seed_text)
			var path := "res://tmp/v130r_b04/"+stack_source+"/checkpoints/"+str(run_seed)+"_"+str(day)+".json"
			if not FileAccess.file_exists(path): continue # This campaign ended before the day.
			var snapshot: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
			for assignment_mode in ["recommended","anchor_cluster","final_line","first_line"]:
				layout_mode=assignment_mode
				if not await restore_entry(snapshot): await finish_stacking(); return
				seed(run_seed+day*1000)
				var result := await battle_day()
				result.merge({"seed":run_seed,"day":day,"layout":layout_mode,"entry_sha256":JSON.stringify(snapshot).sha256_text(),"entry_file_sha256":FileAccess.get_sha256(path)},false)
				rows.append(result); write_json("days",rows)
				expect(not result.has("error"),"paired battle completes")
				print("B04_PAIRED ",run_seed," D",day," ",layout_mode," win=",result.get("win",false)," HP=",result.get("hp",-1))
				if not failures.is_empty(): await finish_stacking(); return
	await finish_stacking()
