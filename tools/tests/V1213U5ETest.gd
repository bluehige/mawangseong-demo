extends Node
const GameScene = preload("res://scenes/game/GameRoot.tscn")
const Audit = preload("res://tools/ux_audit/Audit.gd")
var game: Node
var checks := 0
var failures: Array[String] = []
var out := "res://tmp/v1213_u5e/contract"
var capture_only := false
var captures: Array[String] = []
var observations: Array = []
var capture_filter: PackedStringArray = []

func _ready() -> void:
	get_tree().create_timer(140).timeout.connect(func(): get_tree().quit(2))
	call_deferred("run")
func expect(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures.append(text); print("FAIL: "+text)
func settle(frames: int = 8) -> void:
	for i in range(frames): await get_tree().process_frame
func control(id: String) -> Control:
	return game.ui_layer.find_child(id,true,false) as Control
func click(id: String) -> void:
	var target := control(id)
	expect(target != null and target.is_visible_in_tree(),"input visible "+id)
	if target == null: return
	var ancestor: Node = target.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(target)
		ancestor = ancestor.get_parent()
	await settle()
	var point := target.get_global_transform_with_canvas()*(target.size/2)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		get_viewport().push_input(event,true)
		await get_tree().process_frame
	await settle()

func prepare(day: int = 1, win: bool = true) -> void:
	game.onboarding_enabled = false; game.tutorial_gate_enabled = false
	game.story_feature_enabled = false; game.tutorial_manager.active = false
	game.story_director.cancel_active_scene(); game.onboarding_dialogue_queue.clear()
	game.pause_menu_open = false
	GameState.player_name = "U5E test"; GameState.day = day
	game.campaign_completed = day == 30 and win
	game.campaign_final_battle_outcome = "victory" if day == 30 and win else ""
	GameState.gold = 1000; GameState.mana = 500; GameState.victory = false; GameState.defeat = not win
	game.result_growth_choice_applied = false; game.result_growth_reviewed = false
	game.result_growth_choice_monster_id = ""; game.last_growth_choice_summary = {}
	game.battle_growth_start.clear(); game._reset_battle_contribution_stats()
	for id in game.monster_roster:
		game.monster_roster[id].level = 1; game.monster_roster[id].exp = 22
		game.monster_roster[id].training_day = day; game.monster_roster[id].training_count_today = 1
		game.battle_growth_start[id] = {"level":1,"exp":22,"bond":int(game.monster_roster[id].get("bond",0))}
	for pair in [["damage_dealt",133],["effective_healing",39],["support_protection_applications",3],["shield_absorbed",23],["redirect_actual_hp_taken",17],["duo_shared_commits",2],["facility_value",31]]:
		game._record_monster_contribution("slime",pair[0],pair[1])
	game._finalize_battle_growth(win)
	game.result_summary = {"win":win,"growth":game.last_growth_summary.duplicate(true),"rewards":{"gold":198,"mana":60,"infamy":15},"metrics":{"day":day,"alive_monsters":3,"total_monsters":3},"v122_ledger":{"throne_damage":0,"breach_progress":0},"resource_balance":{"before":{"gold":802,"mana":440},"after":{"gold":1000,"mana":500},"delta":{"gold":198,"mana":60}}}
	game._set_screen("result",false)

func behavior() -> void:
	prepare(); await settle()
	var before: Dictionary = game.monster_roster.duplicate(true)
	var rewards: Dictionary = game.result_summary.rewards.duplicate(true)
	var gold: int = GameState.gold
	var count: int = int(game.monster_roster.slime.training_count_today)
	var original_summary: Dictionary = game.result_summary.duplicate(true)
	var original_growth: Array = game.last_growth_summary.duplicate(true)
	game._set_screen("result",false); await settle()
	expect(game.monster_roster == before and game.result_summary == original_summary and game.last_growth_summary == original_growth,"visual rebuild preserves roster, rewards and growth payload")
	expect(GameState.gold == gold and not game.result_growth_choice_applied and not game.result_growth_reviewed,"visual rebuild spends nothing and applies no focus or review")
	expect(control("ResultVictory_slime") != null and control("ResultVictory_goblin") != null and control("ResultVictory_imp") != null,"three existing victory illustrations")
	expect(control("ResultCastleBackground") is TextureRect,"existing castle background rendered")
	for id in ["gold","mana","infamy"]:
		expect(control("ResultRewardIcon_"+id) is TextureRect,"reward icon "+id)
		expect((control("ResultRewardValue_"+id) as Label).text == "+%d" % int(rewards[id]),"reward card uses original value "+id)
	for i in range(7): expect(control("ResultColumn_%d" % i) != null,"performance table column %d" % i)
	expect((control("ResultAttack_slime") as Label).text == "133" and (control("ResultHealing_slime") as Label).text == "39","measured damage and healing cells")
	expect((control("ResultProtection_slime") as Label).text.contains("3") and (control("ResultDuo_slime") as Label).text.contains("2"),"measured protection and duo cells")
	expect((control("ResultAttack_goblin") as Label).text == "—","zero performance displayed as dash")
	expect(control("ResultCompanion_slime").tooltip_text.contains("23") and control("ResultCompanion_slime").tooltip_text.contains("17") and control("ResultCompanion_slime").tooltip_text.contains("31"),"barrier, redirected HP and facility details retained")
	expect(control("ResultTrainingCost") != null and not game.result_growth_choice_applied,"read-only preview available before focus without selecting")
	expect(game.last_growth_summary[game._growth_row_index("slime")].support_contribution.duo_shared_commits == 2,"actual recorder/finalizer carries duo support")
	expect((control("NextDayButton") as Button).disabled,"focus and review required before next day")
	game._continue_from_result(); expect(GameState.day == 1,"direct continue cannot bypass focus")
	await click("GrowthChoice_slime")
	expect(game.result_growth_choice_applied and game.result_growth_choice_monster_id == "slime","mouse focus input selects one companion")
	var added: int = int(game.monster_roster.slime.exp)-int(before.slime.exp)
	if int(game.monster_roster.slime.level) > int(before.slime.level): added += game._monster_exp_to_next(int(before.slime.level))
	expect(added == 8,"free focus exact EXP +8 including level boundary")
	expect(GameState.gold == gold and int(game.monster_roster.slime.training_count_today) == count,"focus and preview spend no gold or training uses")
	expect(int(game.monster_roster.slime.growth_preparation_day) == 2,"preparation remains assigned next DAY2")
	expect(game.result_summary.rewards == rewards,"reward dictionary unchanged")
	expect(control("MonsterTrainingButton") == null,"no paid training input in result state")
	expect((control("GrowthChoicePreparation_slime") as Label).text.contains("DAY 2"),"designated preparation DAY displayed")
	expect((control("ResultName_slime") as Label).text == game._monster_companion_name("slime"),"performance and preview share companion identity")
	expect(not game._choose_result_growth("goblin"),"second focus choice rejected")
	game._continue_from_result(); expect(GameState.day == 1,"direct continue cannot bypass review")
	await click("GrowthReviewButton")
	expect(game.result_growth_reviewed and not (control("NextDayButton") as Button).disabled,"review input unlocks explicit next DAY")
	game.management_scene.monster_ui.active_tab = "memory"
	game.onboarding_enabled = true; GameState.onboarding_complete = false
	game.onboarding_seen_dialogue_ids.clear()
	await click("NextDayButton")
	expect(GameState.day == 2,"existing day advance invoked once")
	expect(game.current_screen != "monster","next DAY keeps intro and management procedure")
	expect(game.selected_monster_id == "slime" and game.management_scene.monster_ui.active_tab == "training","same companion/training context reserved")
	# First-day result -> real day2 intro queue; finish through the existing dialogue API.
	var dialogue_count: int = game.onboarding_dialogue_queue.size()
	expect(dialogue_count > 0 or game.story_director.is_active(),"actual day2 dialogue not skipped")
	var guard := 0
	while game.current_screen == "dialogue" and guard < 120:
		if game.story_director.is_active() and game.onboarding_dialogue_queue.is_empty(): game._story_advance_dialogue()
		else: game._onboarding_advance_dialogue()
		await settle(2); guard += 1
	expect(game.current_screen == "management","date dialogue returns to management")
	await click("MonsterManagementButton")
	expect(game.current_screen == "monster" and game.management_scene.monster_ui.inspected_id == "slime" and control("TrainingBeforeBar") != null,"management opens same companion training")
	var predicted: Dictionary = game.management_scene.monster_ui.training_preview("slime")
	gold = GameState.gold
	await click("MonsterTrainingButton")
	expect(GameState.gold == gold-30,"paid training spends exactly30 only in management's monster state")
	expect(int(game.monster_roster.slime.exp) == int(predicted.exp) and int(game.monster_roster.slime.level) == int(predicted.level),"paid EXP+20 matches U5D preview")
	expect(int(game.monster_roster.slime.training_day) == 2 and int(game.monster_roster.slime.training_count_today) == 1,"actual training count starts new day")
	expect(int(game.monster_roster.slime.growth_preparation_day) == 2,"paid training does not shift preparation day")
	prepare(30,true); await settle()
	before = game.monster_roster.duplicate(true)
	expect(not game._result_growth_choice_required() and control("GrowthChoice_slime") == null,"final victory has no focus input")
	expect(not game._choose_result_growth("slime") and game.monster_roster == before,"final victory direct focus rejected")
	expect(control("ResultTrainingCost") == null,"final result has no next-DAY training promise")
	await click("NextDayButton")
	expect(GameState.day == 30 and game.current_screen == "ending","final victory continues to existing ending, not next day")
	prepare(7,false); await settle(); before = game.monster_roster.duplicate(true)
	expect((control("ResultCastleBackground") as TextureRect).modulate.r < 0.5,"defeat background uses darker tone")
	expect(control("GrowthChoice_slime") == null and control("GrowthReviewButton") == null,"defeat has no focus/review input")
	expect(not game._choose_result_growth("slime") and game.monster_roster == before,"defeat direct focus rejected")
	game.result_growth_reviewed = false; game._review_growth_from_result()
	expect(not game.result_growth_reviewed,"defeat cannot perform growth review")
	expect(control("ResultEditPlacement") != null and control("ResultRetrySamePlacement") != null,"defeat retains both retry actions")
	await click("ResultEditPlacement")
	expect(GameState.day == 7 and game.current_screen == "management","retry placement preserves day")
	prepare(29,true); game.last_growth_summary.clear(); game.result_summary.management_only = true
	game._set_screen("result",false); await settle()
	expect(control("ResultTrainingCost") == null and (control("ResultPreviewHeading") as Label).text == "결산 확인","recordless preparation victory keeps result review instead of retry copy")

func inspect(id: String, capture: bool = false) -> void:
	await settle(12)
	var audit := Audit.new(); audit.game = game
	var items: Array = []; audit.collect(game.ui_layer,items); audit.free()
	var visible_labels: Array = []
	for item in items:
		if item.type == "Label" and str(item.text) != "":
			expect(int(item.line_count) <= int(item.visible_lines),id+" label lines "+str(item.name))
			expect(not str(item.text).contains("�"),id+" no corrupt glyph "+str(item.name))
			if LanguageSettings.locale != "ko": expect(not has_korean(str(item.text)),id+" translated "+str(item.name)+": "+str(item.text))
		if bool(item.button):
			expect(str(item.tooltip).strip_edges() != "",id+" tooltip "+str(item.name))
			var b := control(str(item.name)) as Button
			if b != null:
				var font := b.get_theme_font("font"); var pixels := b.get_theme_font_size("font_size")
				expect(font.get_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x <= b.size.x-32,id+" button text width "+str(b.name))
	for label in game.ui_layer.find_children("*","Label",true,false):
		if not label.is_visible_in_tree(): continue
		var owner: Node = label.get_parent()
		if owner is Control and not owner is Container: expect(owner.get_global_rect().grow(2).encloses(label.get_global_rect()),id+" label stays inside owner "+str(label.name))
		if label.name.begins_with("Result") or label.name.begins_with("GrowthChoice"):
			visible_labels.append(label)
	for i in range(visible_labels.size()):
		for j in range(i+1,visible_labels.size()):
			if visible_labels[i].get_parent() == visible_labels[j].get_parent(): expect(not visible_labels[i].get_global_rect().grow(-1).intersects(visible_labels[j].get_global_rect().grow(-1)),id+" text rectangles separated "+str(visible_labels[i].name)+"/"+str(visible_labels[j].name))
	for a in ["ResultGrowthPanel","ResultTrainingPreview","GrowthReviewButton","NextDayButton","ResultEditPlacement","ResultRetrySamePlacement"]:
		var ca := control(a)
		if ca == null: continue
		expect(get_viewport().get_visible_rect().encloses(ca.get_global_rect()),id+" component inside viewport "+a)
		for b in ["ResultGrowthPanel","ResultTrainingPreview","GrowthReviewButton","NextDayButton","ResultEditPlacement","ResultRetrySamePlacement"]:
			var cb := control(b)
			if cb != null and a != b: expect(not ca.get_global_rect().intersects(cb.get_global_rect()),id+" component separated "+a+"/"+b)
	for row in game.last_growth_summary:
		var monster_id := str(row.monster_id)
		var card := control("ResultCompanion_"+monster_id)
		var focus := control("GrowthChoice_"+monster_id)
		var note := control(("GrowthChoicePreparation_" if game.result_growth_choice_monster_id == monster_id else "GrowthChoicePreview_")+monster_id)
		if focus != null and note != null:
			expect(card.get_global_rect().grow(1).encloses(focus.get_global_rect()),id+" focus chip inside row "+monster_id)
			expect(not focus.get_global_rect().intersects(note.get_global_rect()),id+" focus chip and next DAY effect separated "+monster_id)
	for a in ["ResultTitleBanner","ResultMetricsBanner","ResultRewards"]:
		for b in ["ResultTitleBanner","ResultMetricsBanner","ResultRewards"]:
			if a != b: expect(not control(a).get_global_rect().intersects(control(b).get_global_rect()),id+" hero blocks separated "+a+"/"+b)
	var notes := control("ResultColumn_6")
	expect(not notes.get_global_rect().intersects(control("ResultDetailsButton").get_global_rect()),id+" notes heading and details button separated")
	observations.append({"id":id,"items":items})
	if capture and DisplayServer.get_name() != "headless" and (capture_filter.is_empty() or capture_filter.has(id)):
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(id+".png")); captures.append(id+".png")

func has_korean(value: String) -> bool:
	for i in range(value.length()):
		if value.unicode_at(i) >= 0xAC00 and value.unicode_at(i) <= 0xD7A3: return true
	return false

func layout() -> void:
	for locale in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		var sizes := [Vector2i(1920,1080),Vector2i(1280,720)] if capture_only else [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(2560,1080)]
		for dimensions in sizes:
			get_window().size = dimensions
			for state in ["victory","focused","reviewed","defeat","final"]:
				prepare(30 if state == "final" else 1,state != "defeat")
				if state in ["focused","reviewed"]: game._choose_result_growth("slime")
				if state == "reviewed": game._review_growth_from_result()
				var name := "%s_%d_%s" % [locale,dimensions.x,state]
				await inspect(name,capture_only and capture_filter.has(name))
				if state == "victory":
					var scroll := control("ResultGrowthScroll") as ScrollContainer
					scroll.ensure_control_visible(control("ResultCompanion_imp")); await inspect(name+"_tail")
					scroll.scroll_vertical = 0
				if state == "reviewed":
					await click("ResultDetailsButton"); expect(control("ResultDetailsPanel").visible,"details input opens source records"); await inspect(name+"_details",capture_only and capture_filter.has(name+"_details"))
					await click("ResultDetailsClose"); expect(not control("ResultDetailsPanel").visible,"details closes without advancing DAY")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output-dir="): out = arg.trim_prefix("--output-dir=")
		if arg.begins_with("--capture-filter="): capture_filter = arg.trim_prefix("--capture-filter=").split(",")
	capture_only = OS.get_cmdline_user_args().has("--capture-only")
	expect(ProjectSettings.globalize_path("user://").replace("\\","/").contains("/tmp/v1213_u5e/"),"isolated APPDATA")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	GameState.reset(); LanguageSettings.set_locale("ko",false)
	game = GameScene.instantiate()
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v4_enabled = false; game.campaign_save_v5_enabled = false
	add_child(game); await settle()
	game._debug_skip_onboarding(); game.set_process(false); game.set_physics_process(false)
	if not capture_only: await behavior()
	await layout()
	var file := FileAccess.open(out.path_join("result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"observations":observations},"\t")); file.close()
	print("V1213_U5E_TEST: %s (%d checks, %d failures, %d captures)" % ["PASS" if failures.is_empty() else "FAIL",checks,failures.size(),captures.size()])
	game.queue_free(); await settle(3); get_tree().quit(0 if failures.is_empty() else 1)
