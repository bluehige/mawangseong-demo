extends "res://tools/UIUXU4InteractionTest.gd"
const Fixture = preload("res://tools/UIUXSecondaryFixture.gd")
const Encounter = preload("res://scripts/systems/outpost/OutpostEncounterService.gd")
var phase := "after"
var output := ""
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg=="--before": phase="before"
	output="res://tmp/uiux_completion_20260913/"+phase
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	game=Game.instantiate()
	add_child(game)
	await settle()
	Fixture.prepare(game)
	var active: Dictionary=game.update4_active_run.duplicate(true)
	for resolution in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(resolution)
		for scale in [0.9,1.0,1.15]:
			UISettings.text_scale=scale
			var tag := "%dx%d_%d" % [resolution.x,resolution.y,roundi(scale*100)]
			game._set_screen(C.SCREEN_NAME_ENTRY)
			await capture(tag+"_name")
			game.onboarding_name_input.text="                 "
			game._onboarding_confirm_name()
			expect(game.current_screen==C.SCREEN_NAME_ENTRY,tag+" empty name rejected")
			await capture(tag+"_name_invalid")
			game.selected_monster_id="goblin"
			game.monster_roster.goblin.unlocked_memory_ids=[]
			game._set_screen(C.SCREEN_MEMORY_ARCHIVE)
			await capture(tag+"_memory_empty")
			var ids: Array=[]
			for rank in range(1,5): ids.append("bond_goblin_rank_%d"%rank)
			for cycle in range(1,13): ids.append("legacy_mon_core_gob_cycle_%d"%cycle)
			game.monster_roster.goblin.unlocked_memory_ids=ids
			if phase=="after": game.management_scene.memory_archive_ui.selected_by_monster.clear()
			game._set_screen(C.SCREEN_MEMORY_ARCHIVE)
			await capture(tag+"_memory")
			game._set_screen(C.SCREEN_CHRONICLE)
			await settle()
			var chronicle=node("ChronicleScreen")
			for page in range(3):
				chronicle._select_tab(page)
				await capture(tag+"_chronicle%d"%page)
			game.update4_active_run=active.duplicate(true)
			game.update4_active_run.expansion={"unlocked":true,"temporary":true,"objective_hp":{"crown_sanctum":600},"rooms":{}}
			game._set_screen(C.SCREEN_EXPANSION)
			await capture(tag+"_temporary_objectives")
			game.update4_active_run.expansion.temporary=false
			game._set_screen(C.SCREEN_EXPANSION)
			await capture(tag+"_expanded_objectives")
			game.update4_active_run=active.duplicate(true)
			game.update4_active_run.outpost.assigned_monster_ids=["mon_core_pudding","mon_core_gob","mon_contract_mori"]
			GameState.day=10
			game._set_screen(C.SCREEN_OUTPOST_BATTLE)
			await settle()
			var battle=node("OutpostBattleRoot")
			battle.set_process(false)
			battle._reset_battle(0)
			battle.set_process(false)
			for tick in range(100): battle.battle_state=Encounter.step(battle.battle_state,0.1)
			battle._refresh_battle_view()
			await capture(tag+"_outpost")
			for tick in range(500): battle.battle_state=Encounter.step(battle.battle_state,0.1)
			expect(bool(battle.battle_state.completed),tag+" service reaches actual result")
			battle._refresh_battle_view()
			battle._show_result()
			await capture(tag+"_outpost_result")
			if phase=="after": await screen_checks(tag)
			game._set_screen(C.SCREEN_MANAGEMENT)
	if phase=="after": await interactions()
	game.queue_free()
	await settle()
	var file := FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase":phase,"assertions":count,"failed":failed,"captures":captures},"\t"))
	file.close()
	print("UIUX_COMPLETION_SCREENS_TEST: %s (%d assertions, %d captures)" % ["FAIL" if failed else "PASS",count,captures.size()])
	get_tree().quit(1 if failed else 0)
func capture(id: String) -> void:
	await settle()
	var path := output.path_join(id+".png")
	expect(get_viewport().get_texture().get_image().save_png(path)==OK,id+" capture")
	captures.append(path)
func screen_checks(tag: String) -> void:
	# These are UI actions in controlled saved-state fixtures, not campaign playthrough.
	var profile: Dictionary=game.update4_profile.duplicate(true)
	var economy: Array=[GameState.gold,GameState.mana]
	game._set_screen(C.SCREEN_NAME_ENTRY)
	await settle()
	var input: LineEdit=game.onboarding_name_input
	input.text="마왕이름열세글자초과확인문자"
	input.text_changed.emit(input.text)
	input.grab_focus()
	await key(KEY_ENTER)
	expect(game.current_screen==C.SCREEN_NAME_ENTRY,tag+" overlong name rejected by Enter")
	expect((node("NameLengthHint") as Label).text.contains("12자 이내"),tag+" inline length feedback")
	await capture(tag+"_name_long")
	await press("RandomNameButton")
	expect(input.text.strip_edges().length() in range(1,13),tag+" random name remains valid")
	check_copy(game.ui_layer)
	await key(KEY_TAB)
	expect(game.get_viewport().gui_get_focus_owner()==node("ConfirmNameButton"),tag+" Tab connects random to confirm")
	game.selected_monster_id="goblin"
	game._set_screen(C.SCREEN_MEMORY_ARCHIVE)
	await settle()
	var roster: Dictionary=game.monster_roster.duplicate(true)
	await press("MemoryChoice_legacy_mon_core_gob_cycle_12")
	expect(game.monster_roster==roster,tag+" reading last legacy memory is read-only")
	expect(text_contains(node("MemorySelectedDetail"),"12회차"),tag+" final legacy cycle readable")
	var scroll:=node("MemoryListScroll") as ScrollContainer
	expect(scroll.get_global_rect().encloses((node("MemoryChoice_legacy_mon_core_gob_cycle_12") as Control).get_global_rect()),tag+" focused memory scrolls fully into view")
	await capture(tag+"_memory_last")
	await press("MemoryBackButton")
	expect(game.current_screen==C.SCREEN_MONSTER,tag+" memory returns to growth")
	game._set_screen(C.SCREEN_CHRONICLE)
	await settle()
	var chronicle=node("ChronicleScreen")
	for page in range(3):
		await press("ChronicleTab%d"%page)
		var sections: Array=chronicle._sections(page)
		for index in sections.size():
			await press("ChronicleSection%d"%index)
			var label:=node("ChroniclePageText%d"%page) as Label
			expect(label.text==str(sections[index].body),tag+" full chapter retained "+str(sections[index].title))
			expect(game.get_viewport().gui_get_focus_owner()==node("ChronicleSection%d"%index),tag+" chapter keyboard focus retained")
		await capture(tag+"_chronicle%d_last"%page)
	await press("ChronicleTab3")
	expect(node("ChroniclePage2")==null and node("Update4AccessibilityControls")!=null,tag+" settings has dedicated page")
	await press("QuickDialogueToggle")
	expect(bool(game.update4_profile.chronicle_update4.accessibility.quick_dialogue)!=bool(profile.get("chronicle_update4",{}).get("accessibility",{}).get("quick_dialogue",false)),tag+" toggle persists through existing callback")
	await capture(tag+"_chronicle_settings")
	await press("ChronicleCloseButton")
	expect(game.current_screen==C.SCREEN_MANAGEMENT,tag+" chronicle returns to management")
	game.update4_profile=profile
	game.update4_active_run.expansion={"unlocked":true,"temporary":true,"objective_hp":{"crown_sanctum":600},"rooms":{}}
	game._set_screen(C.SCREEN_EXPANSION)
	await settle()
	var active: Dictionary=game.update4_active_run.duplicate(true)
	await capture(tag+"_objective_overview")
	expect(game.update4_active_run==active and [GameState.gold,GameState.mana]==economy,tag+" objective overview does not mutate state or resources")
	game._set_screen(C.SCREEN_MANAGEMENT)
	check_copy(game.ui_layer)

func press(id: String) -> void:
	var control:=node(id) as BaseButton
	expect(control!=null and control.is_visible_in_tree(),id+" visible control")
	if control==null: return
	control.grab_focus()
	await key(KEY_ENTER)

func text_contains(parent: Node,text: String) -> bool:
	if parent==null: return false
	if parent is Label and parent.text.contains(text): return true
	for child in parent.get_children():
		if text_contains(child,text): return true
	return false

func interactions() -> void:
	# Settlement duplicate protection is checked outside the campaign reward callback.
	var battle=preload("res://scenes/outpost/OutpostBattleRoot.tscn").instantiate()
	add_child(battle)
	var base: Dictionary=game.update4_active_run.outpost.duplicate(true)
	base.assigned_monster_ids=[]
	battle.setup(base,DataRegistry.update4_outpost_encounters.outpost_fixed_four_modules,DataRegistry.update4_outpost_types[base.type_id],[],20)
	battle.set_process(false)
	var emitted: Array=[]
	battle.battle_settled.connect(func(result: Dictionary): emitted.append(result))
	battle._settle()
	expect(emitted.is_empty(),"unfinished encounter cannot settle")
	for tick in range(100): battle.battle_state=Encounter.step(battle.battle_state,0.1)
	battle._refresh_battle_view()
	var existing: Dictionary=battle.enemy_markers.duplicate()
	battle._refresh_battle_view()
	expect(battle.enemy_markers==existing,"refresh reuses actual intruder controls")
	for tick in range(500): battle.battle_state=Encounter.step(battle.battle_state,0.1)
	expect(bool(battle.battle_state.completed) and not bool(battle.battle_state.win),"unmanned day20 fixture loses through actual service")
	battle._show_result()
	battle._retry()
	battle.set_process(false)
	expect(int(battle.battle_state.retry_count)==1 and not bool(battle.battle_state.completed),"retry resets actual encounter without settling")
	expect(emitted.is_empty(),"retry produces no settlement")
	for tick in range(600): battle.battle_state=Encounter.step(battle.battle_state,0.1)
	battle._show_result()
	battle._settle()
	battle._settle()
	battle._retry()
	expect(emitted.size()==1 and battle.settlement_sent,"settlement dispatches once and blocks retry")
	battle.queue_free()
	await settle()
