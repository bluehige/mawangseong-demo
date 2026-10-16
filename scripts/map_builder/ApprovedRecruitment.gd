extends RefCounted
## Existing conditions win over fallback DAYs. Addition follows the last dialogue.
const Grade = preload("res://scripts/map_builder/ApprovedGradeProgression.gd")
const Members = preload("res://scripts/map_builder/ApprovedMonsterPlacement.gd")
const FALLBACK := {"spore_healer":7,"stone_sentinel":9,"war_drummer":12,"moon_tracker":16,"mimic_porter":17}
const CORE := ["slime","goblin","imp","kobold_scout"]
const LINES := {"spore_healer":"다친 동료가 있나요? 밥 한 그릇이면 포자도 힘을 낼 수 있어요.","stone_sentinel":"입구를 맡겨 줘. 식사 시간에도 자리는 지킬게.","war_drummer":"밥 먹고 북 치자! 빈속엔 박자도 자꾸 늦어진다구.","moon_tracker":"달빛이 닿는 곳에서 지켜볼게. 식량 장부에도 내 이름을 적어 줘.","mimic_porter":"진짜 밥은 내 안에 넣지 마! 가짜 보물만 맡겨 줘."}

static func condition(species: String) -> String:
	if DataRegistry.update2_contracts.has(species): return "회차 계약에서 2명 선택"
	if DataRegistry.update3_monster_extensions.has(species): return "기존 전선 클리어 또는 해당 엔딩/보상"
	if species in ["spider_tailor","bat_courier"]: return "마왕 의회 회차"
	return "DAY %d" % int(FALLBACK.get(species,1))

static func eligible(game: Node, members: Dictionary, day: int) -> Array:
	var ids: Array = []
	var ending_codes: Array = game.campaign_profile.get("ending_catalog_codes",{}).values()
	for ending_id in game.update3_profile.get("update3_endings_seen",[]):
		var code: String = str(DataRegistry.update3_endings.get(ending_id,{}).get("catalog_code",""))
		if code!="" and code not in ending_codes: ending_codes.append(code)
	for id in members:
		var species: String = members[id].species_id
		var allowed: bool = species in CORE
		if DataRegistry.update2_contracts.has(species):
			allowed = species in game.selected_contract_ids
		elif DataRegistry.update3_monster_extensions.has(species):
			var rule: Dictionary = DataRegistry.update3_monster_extensions[species].get("unlock_condition",{})
			var front: String = str(rule.get("front_id",""))
			var ending: String = str(rule.get("alternate_ending_id",""))
			allowed = id in game.update3_profile.get("guaranteed_contract_instance_ids",[]) or (front!="" and int(game.update3_profile.get("fronts",{}).get("clear_counts",{}).get(front,0))>=1) or (ending!="" and ending in ending_codes)
		elif species in ["spider_tailor","bat_courier"]:
			allowed = game._update4_council_mode_active()
		elif DataRegistry.monster(species).has("join_day"): allowed = day>=int(DataRegistry.monster(species).join_day)
		elif FALLBACK.has(species): allowed = day>=int(FALLBACK[species])
		if allowed: ids.append(id)
	return ids

static func begin(game: Node, ids: Array) -> void:
	var members := Members.roster()
	var session := Grade.load_session(game)
	var eligible_ids := eligible(game,members,int(session.layout.day))
	var pending: Array = []; var entries: Array = []
	for id in ids:
		if id not in eligible_ids or id in session.layout.get("food_state",{}).get("owned",[]) or not members.has(id): continue
		var row: Dictionary = members[id]
		if row.species_id in CORE: continue
		pending.append(id)
		var scenes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/v130r/join_scenes.json"))
		var scene: Dictionary = scenes.get(str(row.stats.get("join_scene_id","")),{})
		if not scene.is_empty():
			for index in range(scene.lines.size()):
				var text: String = scene.lines[index]
				var close := text.find("]:")
				var heading := text.substr(1,close-1).split("|")
				var emotion: String = {"기쁨":"happy","단호":"determined","결의":"determined"}.get(heading[1],"base")
				entries.append({"speaker":scene.speaker_character_ids[index],"speaker_name":heading[0],"emotion":emotion,"text":text.substr(close+2).strip_edges(),"dialogue_header":"동료 합류 · "+row.display_name})
		else:
			entries.append({"speaker":row.character_id,"speaker_name":row.display_name,"emotion":"base","text":LINES.get(row.species_id,"보급과 수비, 함께 맡을게요. 오늘부터 잘 부탁해요!"),"dialogue_header":"동료 합류 · "+row.display_name})
	if pending.is_empty(): game._set_screen(Constants.SCREEN_MANAGEMENT); return
	game.set_meta("approved_join_pending",pending)
	game._onboarding_begin_dialogue(entries,Constants.SCREEN_MANAGEMENT,"v130r_join")

static func finish(game: Node) -> void:
	var session := Grade.load_session(game); var members := Members.roster()
	var state := GameState.Food.migrate(session.layout.get("food_state",{}),int(session.layout.day))
	state.contracts = game.selected_contract_ids.duplicate()
	for id in game.get_meta("approved_join_pending",[]):
		if not members.has(id) or id in state.owned: continue
		state.owned.append(id)
		var species: String = members[id].species_id
		if DataRegistry.update2_contracts.has(species): game._add_contract_monster_to_roster(species)
		else: game._add_update3_monster_to_roster(species,id)
	session.layout.food_state = state
	GameState.food_state = state.duplicate(true)
	game.remove_meta("approved_join_pending")
	Grade.stash(game,session.layout,session.defenders)
	Members.save_copy(session.layout,session.defenders,Grade.save_path())
	game._set_screen(Constants.SCREEN_MANAGEMENT)
