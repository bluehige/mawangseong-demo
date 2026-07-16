extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const MAX_SIM_SECONDS = 120.0
const PHYSICS_STEP = 1.0 / 60.0
const SIM_TIME_SCALE = 8.0
const TEST_COMBAT_SPEED = 1.5
const RUN_SEED = 20260711
const PROXY_PROFILE_IDS = ["balanced", "aggressive", "fortified", "survival", "minimal"]

var failed := false
var output_dir := ""
var log_messages: Array[String] = []
var day_records: Array[Dictionary] = []
var proxy_mode := false
var proxy_profile_id := "balanced"
var run_seed := RUN_SEED
var simulation_time_scale := SIM_TIME_SCALE
var max_sim_seconds := MAX_SIM_SECONDS

func _ready() -> void:
	var log_collector = Callable(self, "_collect_log")
	if not SignalBus.log_added.is_connected(log_collector):
		SignalBus.log_added.connect(log_collector)
	call_deferred("_run")

func _run() -> void:
	_read_proxy_profile_argument()
	if failed:
		get_tree().quit(1)
		return
	simulation_time_scale = SIM_TIME_SCALE
	max_sim_seconds = 180.0 if proxy_mode else MAX_SIM_SECONDS
	Engine.time_scale = simulation_time_scale
	run_seed = RUN_SEED + PROXY_PROFILE_IDS.find(proxy_profile_id) * 101 if proxy_mode else RUN_SEED
	seed(run_seed)
	output_dir = ProjectSettings.globalize_path("res://tmp/day1_3_proxy_records" if proxy_mode else "res://tmp/day1_3_playtest_records")
	DirAccess.make_dir_recursive_absolute(output_dir)
	print("DAY1_3_PLAYTEST_RECORDER: START (%s)" % proxy_profile_id)

	var game = GameRootScene.instantiate()
	add_child(game)
	await _settle(2)
	if game.has_method("_debug_skip_onboarding"):
		game._debug_skip_onboarding()
		await _settle(1)

	for day in [1, 2, 3]:
		if GameState.day != day:
			_fail("DAY %d 시작 전 날짜가 어긋남: 현재 DAY %d" % [day, GameState.day])
			break
		var log_start_index = log_messages.size()
		var choices = _prepare_day(game, day)
		var record = await _run_day(game, day, choices, log_start_index)
		day_records.append(record)
		if failed:
			break
		if day < 3:
			game._review_growth_from_result()
			await _settle(1)
			game._continue_from_result()
			await _settle(4)
			_expect(GameState.day == day + 1 and game.current_screen == Constants.SCREEN_MANAGEMENT, "DAY %d 결산 후 DAY %d 관리 화면 진입" % [day, day + 1])
		else:
			if proxy_mode:
				_expect(game.current_screen == Constants.SCREEN_RESULT and (GameState.victory or GameState.defeat), "DAY 3 승패 결과 저장")
			else:
				_expect(GameState.victory, "DAY 3 승리 플래그 저장")
	_assert_activity_growth_limits()

	var written_paths = _write_report()
	game.queue_free()
	await _settle(2)
	Engine.time_scale = 1.0
	print("DAY1_3_PLAYTEST_RECORDER_JSON: %s" % written_paths.get("json", ""))
	print("DAY1_3_PLAYTEST_RECORDER_MARKDOWN: %s" % written_paths.get("markdown", ""))
	print("DAY1_3_PLAYTEST_RECORDER: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)

func _read_proxy_profile_argument() -> void:
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--proxy-profile="):
			continue
		var requested := argument.trim_prefix("--proxy-profile=")
		if not PROXY_PROFILE_IDS.has(requested):
			_fail("알 수 없는 자동 대리 프로필: %s" % requested)
			return
		proxy_mode = true
		proxy_profile_id = requested

func _prepare_day(game: Node, day: int) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	if day >= 2 and game._early_specialization_required_for_current_day():
		var chosen = game._choose_early_specialization("goblin", "goblin_treasure_hunter")
		_expect(chosen, "DAY %d 도둑 대응 전술 특화 선택" % day)
		_add_choice(choices, "specialization", "고블린: 도둑 사냥꾼", "도둑을 실제로 추격하는지 기록한다.")
		game._set_screen(Constants.SCREEN_MANAGEMENT)
	if day == 2:
		var facility_id := str(_profile_settings().get("facility", ""))
		if facility_id != "" and game.rooms.has("slot_01") and str(game.rooms["slot_01"].get("facility_role", "")) != facility_id:
			var changed = game._change_room_facility("slot_01", facility_id)
			_expect(changed, "DAY 2 %s 건설" % _facility_label(facility_id))
			_add_choice(choices, "facility", "건설 슬롯: %s" % _facility_label(facility_id), "시설별 실제 전투 기여를 비교한다.")

	var room_plan: Dictionary = _profile_room_plan(day)
	if not room_plan.is_empty():
		game.selected_room = str(room_plan.get("room_id", ""))
		game._set_room_directive(str(room_plan.get("directive", "")))
		_add_choice(choices, "room_directive", "%s: %s" % [_room_label(game.selected_room), _room_directive_label(str(room_plan.get("directive", "")))], "대리 프로필의 방어 동선을 적용한다.")

	var directive := _profile_directive(day)
	game._set_global_directive(directive)
	_add_choice(choices, "global_directive", "전체 지침: %s" % _directive_label(directive), "서로 다른 운용 성향의 결과를 비교한다.")
	if _profile_assist(day) != "none":
		_add_choice(choices, "assist", "자동 스킬 보조", "사용 가능한 전투 스킬을 조건에 맞춰 사용한다.")
	return choices

func _profile_settings() -> Dictionary:
	match proxy_profile_id:
		"aggressive":
			return {"facility": "barracks", "directives": [Constants.DIRECTIVE_ALL_OUT, Constants.DIRECTIVE_ALL_OUT, Constants.DIRECTIVE_ALL_OUT], "growth": "most_damage"}
		"fortified":
			return {"facility": "watch_post", "directives": [Constants.DIRECTIVE_DEFENSE, Constants.DIRECTIVE_DEFENSE, Constants.DIRECTIVE_DEFENSE], "growth": "slime"}
		"survival":
			return {"facility": "recovery", "directives": [Constants.DIRECTIVE_SURVIVAL, Constants.DIRECTIVE_SURVIVAL, Constants.DIRECTIVE_SURVIVAL], "growth": "least_active"}
		"minimal":
			return {"facility": "", "directives": [Constants.DIRECTIVE_DEFENSE, Constants.DIRECTIVE_DEFENSE, Constants.DIRECTIVE_DEFENSE], "growth": "most_active"}
		_:
			return {"facility": "watch_post", "directives": [Constants.DIRECTIVE_DEFENSE, Constants.DIRECTIVE_ALL_OUT, Constants.DIRECTIVE_DEFENSE], "growth": "most_active"}

func _profile_directive(day: int) -> String:
	var directives: Array = _profile_settings().get("directives", [])
	return str(directives[clampi(day - 1, 0, directives.size() - 1)])

func _profile_room_plan(day: int) -> Dictionary:
	match proxy_profile_id:
		"survival":
			return {"room_id": "recovery", "directive": Constants.ROOM_DIRECTIVE_RETREAT}
		"minimal":
			return {}
		"fortified":
			return {"room_id": "entrance", "directive": Constants.ROOM_DIRECTIVE_ENTRY_BLOCK}
		_:
			if day == 1:
				return {"room_id": "entrance", "directive": Constants.ROOM_DIRECTIVE_ENTRY_BLOCK}
			return {"room_id": "spike_corridor", "directive": Constants.ROOM_DIRECTIVE_TRAP_LURE}

func _profile_assist(day: int) -> String:
	if proxy_profile_id == "aggressive" and day >= 2:
		return "active_skills"
	if proxy_profile_id == "balanced" and day == 3:
		return "active_skills"
	return "none"

func _facility_label(facility_id: String) -> String:
	return str({"watch_post": "감시 초소", "barracks": "병영", "recovery": "회복 둥지"}.get(facility_id, facility_id))

func _room_label(room_id: String) -> String:
	return str({"entrance": "입구", "spike_corridor": "가시 복도", "recovery": "회복 둥지"}.get(room_id, room_id))

func _room_directive_label(directive: String) -> String:
	return str({Constants.ROOM_DIRECTIVE_ENTRY_BLOCK: "입구 봉쇄", Constants.ROOM_DIRECTIVE_TRAP_LURE: "함정 유도", Constants.ROOM_DIRECTIVE_RETREAT: "후퇴선"}.get(directive, directive))

func _run_day(game: Node, day: int, choices: Array[Dictionary], log_start_index: int) -> Dictionary:
	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "DAY %d 전투 화면 진입" % day)
	game.combat_speed = TEST_COMBAT_SPEED
	var elapsed := 0.0
	var skill_uses := 0
	var thief_reached_treasure := false
	var assist_mode := _profile_assist(day)
	while game.current_screen != Constants.SCREEN_RESULT and elapsed < max_sim_seconds:
		skill_uses += _apply_assist(game, assist_mode)
		if _any_thief_in_treasure(game):
			thief_reached_treasure = true
		await get_tree().physics_frame
		elapsed += PHYSICS_STEP * simulation_time_scale * TEST_COMBAT_SPEED
	_apply_result_growth_choice(game, choices)
	await get_tree().process_frame
	var record = _collect_day_record(game, day, elapsed, skill_uses, thief_reached_treasure, choices, log_start_index)
	_assert_day_record(record)
	return record

func _apply_result_growth_choice(game: Node, choices: Array[Dictionary]) -> void:
	if not game.has_method("_result_growth_choice_required") or not game._result_growth_choice_required() or game.result_growth_choice_applied:
		return
	var target_id = _growth_focus_target(game)
	if target_id == "":
		return
	if game._choose_result_growth(target_id):
		_add_choice(
			choices,
			"growth_focus",
			"%s 집중 성장" % game._monster_display_name(target_id),
			"결산에서 가장 활약한 몬스터에게 추가 EXP를 부여한다."
		)

func _growth_focus_target(game: Node) -> String:
	var growth_strategy := str(_profile_settings().get("growth", "most_active"))
	if growth_strategy in ["slime", "goblin", "imp"]:
		return growth_strategy
	var best_id := ""
	var best_score := INF if growth_strategy == "least_active" else -1.0
	for row_value in game.last_growth_summary:
		var row: Dictionary = row_value
		var score := float(int(row.get("activity_exp", 0)) * 1000 + int(row.get("damage_dealt", 0)) + int(row.get("damage_absorbed", 0)))
		if growth_strategy == "most_damage":
			score = float(int(row.get("damage_dealt", 0)) * 1000 + int(row.get("finishing_blows", 0)))
		var is_better := score < best_score if growth_strategy == "least_active" else score > best_score
		if is_better:
			best_score = score
			best_id = str(row.get("monster_id", ""))
	return best_id

func _collect_day_record(game: Node, day: int, elapsed: float, skill_uses: int, thief_reached_treasure: bool, choices: Array[Dictionary], log_start_index: int) -> Dictionary:
	var metrics: Dictionary = game.result_summary.get("metrics", {})
	var result_lines: Array = game.result_summary.get("lines", [])
	var day_logs: Array[String] = []
	for index in range(log_start_index, log_messages.size()):
		day_logs.append(log_messages[index])
	var record = {
		"day": day,
		"result": "timeout" if game.current_screen != Constants.SCREEN_RESULT else ("win" if bool(game.result_summary.get("win", false)) else "loss"),
		"timed_out": game.current_screen != Constants.SCREEN_RESULT,
		"elapsed_seconds": elapsed,
		"combat_time": float(metrics.get("combat_time", elapsed)),
		"choices": choices,
		"skill_uses": skill_uses,
		"thief_reached_treasure": thief_reached_treasure,
		"thief_stole": _logs_contain(day_logs, "도둑이 보물을 훔쳤습니다"),
		"enemy_down": game._count_downed_enemies(),
		"spawned": game.spawned_count,
		"throne_hp": GameState.demon_lord_hp,
		"throne_max_hp": GameState.demon_lord_max_hp,
		"remaining_monster_hp": int(metrics.get("remaining_monster_hp", 0)),
		"total_monster_hp": int(metrics.get("total_monster_hp", 0)),
		"alive_monsters": int(metrics.get("alive_monsters", 0)),
		"total_monsters": int(metrics.get("total_monsters", 0)),
		"directive": str(metrics.get("directive", game.global_directive)),
		"directive_effects": metrics.get("directive_effects", {}).duplicate(true),
		"facility_effects": metrics.get("facility_effects", {}).duplicate(true),
		"growth": game.last_growth_summary.duplicate(true),
		"growth_choice": game.last_growth_choice_summary.duplicate(true),
		"roster": _roster_snapshot(game),
		"resources": _resource_snapshot(),
		"wave": {
			"done": game.wave_manager.is_done(),
			"next_index": game.wave_manager.next_index,
			"total_to_spawn": game.wave_manager.total_to_spawn,
			"elapsed": game.wave_manager.elapsed
		},
		"live_units": _live_unit_snapshot(game),
		"result_lines": result_lines.duplicate(true),
		"recent_logs": day_logs.slice(max(0, day_logs.size() - 10), day_logs.size())
	}
	record["growth_diagnostics"] = _growth_diagnostics(record.get("growth", []))
	record["choice_outcome"] = _choice_outcome_summary(record)
	return record

func _assert_day_record(record: Dictionary) -> void:
	var day = int(record.get("day", 0))
	var result := str(record.get("result", ""))
	var won := result == "win"
	var final_proxy_loss := proxy_mode and day == 3 and result == "loss"
	_expect(not bool(record.get("timed_out", false)), "DAY %d 전투가 제한 시간 안에 결산 도달" % day)
	_expect(won or final_proxy_loss, "DAY %d 승패 결과 기록" % day)
	if won:
		_expect(int(record.get("enemy_down", 0)) == int(record.get("spawned", -1)), "DAY %d 스폰된 적 전원 격퇴" % day)
		_expect(int(record.get("throne_hp", 0)) > 0, "DAY %d 마왕성 체력 생존" % day)
	elif final_proxy_loss:
		_expect(int(record.get("throne_hp", -1)) == 0, "DAY 3 패배 원인인 마왕성 체력 소진 기록")
	if proxy_mode:
		_expect(int(record.get("total_monster_hp", 0)) > 0, "DAY %d 몬스터 전체 체력 기준 기록" % day)
	else:
		_expect(int(record.get("remaining_monster_hp", 0)) > 0, "DAY %d 몬스터 잔여 체력 기록" % day)
	_expect((record.get("growth", []) as Array).size() >= 3, "DAY %d 몬스터 성장 기록 3명 이상" % day)
	_expect(not (record.get("growth_diagnostics", {}) as Dictionary).is_empty(), "DAY %d 활약 진단 기록" % day)
	if won:
		_expect(not (record.get("growth_choice", {}) as Dictionary).is_empty(), "DAY %d 집중 성장 선택 기록" % day)
		var saw_choice_bonus := false
		for row_value in (record.get("growth", []) as Array):
			var row: Dictionary = row_value
			if int(row.get("choice_bonus_exp", 0)) > 0:
				saw_choice_bonus = true
		_expect(saw_choice_bonus, "DAY %d 성장 기록에 집중 보너스 EXP 반영" % day)
	_expect((record.get("result_lines", []) as Array).size() >= 8, "DAY %d 결산 문구 기록" % day)
	if day == 2:
		if not proxy_mode:
			_expect(not bool(record.get("thief_stole", false)), "DAY 2 도둑 보물 도난 없음")
		if str(_profile_settings().get("facility", "")) == "watch_post":
			_expect(int(record.get("facility_effects", {}).get("watch_post_bonus_damage", 0)) > 0, "DAY 2 감시 초소 추가 피해 기록")
	if day == 3 and _profile_assist(day) != "none":
		_expect(int(record.get("skill_uses", 0)) > 0, "DAY 3 스킬 보조 사용 기록")
	if day == 3:
		var diagnostics: Dictionary = record.get("growth_diagnostics", {})
		var contribution_signatures: Dictionary = {}
		for summary_value in (diagnostics.get("rows", []) as Array):
			var summary: Dictionary = summary_value
			contribution_signatures[str(summary.get("breakdown_text", ""))] = true
		var has_activity_difference := (
			int(diagnostics.get("activity_exp_spread", 0)) > 0
			or contribution_signatures.size() > 1
		)
		_expect(has_activity_difference, "DAY 3 몬스터별 활약 EXP 또는 역할 기여 차이 기록")

func _assert_activity_growth_limits() -> void:
	var capped_days_by_monster: Dictionary = {}
	var total_activity_by_monster: Dictionary = {}
	var total_activity := 0
	var values_in_range := true
	for record_value in day_records:
		var record: Dictionary = record_value
		var day = int(record.get("day", 0))
		for row_value in (record.get("growth", []) as Array):
			var row: Dictionary = row_value
			var monster_id = str(row.get("monster_id", ""))
			var activity_exp = int(row.get("activity_exp", -1))
			total_activity += maxi(0, activity_exp)
			total_activity_by_monster[monster_id] = int(total_activity_by_monster.get(monster_id, 0)) + maxi(0, activity_exp)
			if activity_exp < 0 or activity_exp > Constants.ACTIVITY_EXP_CAP:
				values_in_range = false
			if activity_exp >= Constants.ACTIVITY_EXP_CAP:
				var capped_days: Array = capped_days_by_monster.get(monster_id, [])
				capped_days.append(day)
				capped_days_by_monster[monster_id] = capped_days
	_expect(values_in_range, "DAY 1~3 활약 EXP가 0~%d 범위" % Constants.ACTIVITY_EXP_CAP)
	var dominance_failures: Array[String] = []
	for monster_id_value in capped_days_by_monster.keys():
		var capped_days: Array = capped_days_by_monster[monster_id_value]
		var activity_share := float(total_activity_by_monster.get(monster_id_value, 0)) / float(maxi(1, total_activity))
		if capped_days.size() >= day_records.size() or activity_share > 0.60:
			dominance_failures.append("%s(DAY %s, %.0f%%)" % [str(monster_id_value), ",".join(capped_days.map(func(day): return str(day))), activity_share * 100.0])
	_expect(dominance_failures.is_empty(), "한 몬스터가 전 기간 활약을 독식하지 않음: %s" % ("없음" if dominance_failures.is_empty() else ", ".join(dominance_failures)))

func _growth_diagnostics(growth_rows: Array) -> Dictionary:
	var row_summaries: Array[Dictionary] = []
	var zero_activity: Array[String] = []
	var capped_activity: Array[String] = []
	var near_cap_activity: Array[String] = []
	var total_activity := 0
	var min_activity := 999999
	var max_activity := -1
	for row_value in growth_rows:
		var row: Dictionary = row_value
		var activity_exp = int(row.get("activity_exp", 0))
		var display_name = str(row.get("display_name", row.get("monster_id", "")))
		total_activity += activity_exp
		min_activity = mini(min_activity, activity_exp)
		max_activity = maxi(max_activity, activity_exp)
		if activity_exp <= 0:
			zero_activity.append(display_name)
		if activity_exp >= Constants.ACTIVITY_EXP_CAP:
			capped_activity.append(display_name)
		elif activity_exp >= Constants.ACTIVITY_EXP_CAP - 1:
			near_cap_activity.append(display_name)
		row_summaries.append({
			"monster_id": str(row.get("monster_id", "")),
			"display_name": display_name,
			"activity_exp": activity_exp,
			"shared_exp": int(row.get("shared_exp", 0)),
			"choice_bonus_exp": int(row.get("choice_bonus_exp", 0)),
			"damage_dealt": int(row.get("damage_dealt", 0)),
			"damage_absorbed": int(row.get("damage_absorbed", 0)),
			"finishing_blows": int(row.get("finishing_blows", 0)),
			"facility_value": int(row.get("facility_value", 0)),
			"breakdown_text": _activity_breakdown_text(row.get("activity_breakdown", {}))
		})
	if growth_rows.is_empty():
		min_activity = 0
		max_activity = 0
	return {
		"rows": row_summaries,
		"total_activity_exp": total_activity,
		"min_activity_exp": min_activity,
		"max_activity_exp": max_activity,
		"activity_exp_spread": max_activity - min_activity,
		"zero_activity_monsters": zero_activity,
		"capped_activity_monsters": capped_activity,
		"near_cap_activity_monsters": near_cap_activity,
		"observation_notes": _growth_observation_notes(zero_activity, capped_activity, near_cap_activity, max_activity - min_activity)
	}

func _growth_observation_notes(zero_activity: Array[String], capped_activity: Array[String], near_cap_activity: Array[String], spread: int) -> Array[String]:
	var notes: Array[String] = []
	if zero_activity.is_empty():
		notes.append("활약 0 EXP 몬스터 없음")
	else:
		notes.append("활약 0 EXP: %s" % ", ".join(zero_activity))
	if capped_activity.is_empty():
		notes.append("활약 상한 %d EXP 도달 없음" % Constants.ACTIVITY_EXP_CAP)
	else:
		notes.append("활약 상한 도달: %s" % ", ".join(capped_activity))
	if not near_cap_activity.is_empty():
		notes.append("활약 상한 근접: %s" % ", ".join(near_cap_activity))
	if spread <= 2:
		notes.append("활약 분포가 좁음: 유저 선택 차이가 덜 보일 수 있음")
	elif spread >= 6:
		notes.append("활약 분포가 큼: 특정 몬스터 중심 운용이 뚜렷함")
	else:
		notes.append("활약 분포가 중간: 역할 차이가 적당히 보임")
	return notes

func _activity_breakdown_text(breakdown_value) -> String:
	var breakdown: Dictionary = breakdown_value if breakdown_value is Dictionary else {}
	var labels = {
		"attack": "공격",
		"defense": "흡수",
		"finisher": "마무리",
		"facility": "시설"
	}
	var parts: Array[String] = []
	for key in ["attack", "defense", "finisher", "facility"]:
		var value = int(breakdown.get(key, 0))
		if value > 0:
			parts.append("%s +%d" % [str(labels[key]), value])
	if parts.is_empty():
		return "활약 보너스 없음"
	return " / ".join(parts)

func _choice_outcome_summary(record: Dictionary) -> String:
	var day = int(record.get("day", 0))
	var combat_time = float(record.get("combat_time", record.get("elapsed_seconds", 0.0)))
	var remaining_hp = int(record.get("remaining_monster_hp", 0))
	var total_hp = int(record.get("total_monster_hp", 0))
	var hp_text = "%d/%d" % [remaining_hp, total_hp]
	var directive = _directive_label(str(record.get("directive", "")))
	var facility: Dictionary = record.get("facility_effects", {})
	var facility_text = "시설 발동 없음"
	if int(facility.get("watch_post_bonus_damage", 0)) > 0:
		facility_text = "감시 피해 +%d, 둔화 %d회" % [
			int(facility.get("watch_post_bonus_damage", 0)),
			int(facility.get("watch_post_slow_applications", 0))
		]
	elif int(facility.get("barracks_bonus_damage", 0)) > 0 or int(facility.get("barracks_damage_reduced", 0)) > 0:
		facility_text = "병영 피해 +%d, 방어 %d" % [
			int(facility.get("barracks_bonus_damage", 0)),
			int(facility.get("barracks_damage_reduced", 0))
		]
	elif int(facility.get("recovery_healing", 0)) > 0:
		facility_text = "회복 %d" % int(facility.get("recovery_healing", 0))
	var thief_text = "도둑 도달 없음"
	if bool(record.get("thief_stole", false)):
		thief_text = "도둑 도난 발생"
	elif bool(record.get("thief_reached_treasure", false)):
		thief_text = "도둑 보물방 도달"
	var skill_text = "스킬 %d회" % int(record.get("skill_uses", 0))
	return "DAY %d 선택 결과: 지침 %s, %.1f초, 몬스터 HP %s, %s, %s, %s" % [
		day,
		directive,
		combat_time,
		hp_text,
		facility_text,
		thief_text,
		skill_text
	]

func _directive_label(directive: String) -> String:
	match directive:
		Constants.DIRECTIVE_DEFENSE:
			return "사수"
		Constants.DIRECTIVE_ALL_OUT:
			return "총공격"
		Constants.DIRECTIVE_SURVIVAL:
			return "생존"
		_:
			return directive

func _apply_assist(game: Node, assist: String) -> int:
	if assist == "none":
		return 0
	var used := 0
	used += _try_goblin_quick_slash(game)
	used += _try_imp_skills(game)
	return used

func _try_imp_skills(game: Node) -> int:
	var imp = _unit_by_id(game.monster_units, "imp")
	if imp == null or not imp.is_alive():
		return 0
	var flame_rooms = ["spike_corridor", game._room_by_facility("barracks", "")]
	if _alive_enemy_count_in_rooms(game, flame_rooms) >= 2 and imp.skill_ready("flame_zone") and GameState.mana >= 40:
		return 1 if game.combat_scene.use_unit_skill_for_ai(imp, 1) else 0
	if _alive_enemy_count(game) >= 1 and imp.skill_ready("fireball") and GameState.mana >= 20:
		return 1 if game.combat_scene.use_unit_skill_for_ai(imp, 0) else 0
	return 0

func _try_goblin_quick_slash(game: Node) -> int:
	var goblin = _unit_by_id(game.monster_units, "goblin")
	if goblin == null or not goblin.is_alive() or not goblin.skill_ready("quick_slash"):
		return 0
	if _nearest_enemy_in_range(game, goblin, goblin.attack_range + 38.0) == null:
		return 0
	return 1 if game.combat_scene.use_unit_skill_for_ai(goblin, 0) else 0

func _any_thief_in_treasure(game: Node) -> bool:
	var treasure_room = game._room_by_facility("treasure", "")
	for enemy in game.enemy_units:
		if enemy.is_alive() and enemy.unit_id == "thief" and enemy.current_room == treasure_room:
			return true
	return false

func _alive_enemy_count(game: Node) -> int:
	var count := 0
	for enemy in game.enemy_units:
		if enemy.is_alive():
			count += 1
	return count

func _alive_enemy_count_in_rooms(game: Node, room_ids: Array) -> int:
	var count := 0
	for enemy in game.enemy_units:
		if enemy.is_alive() and room_ids.has(enemy.current_room):
			count += 1
	return count

func _nearest_enemy_in_range(game: Node, unit: Node, range: float) -> Node:
	var nearest = null
	var best_distance := INF
	for enemy in game.enemy_units:
		if not enemy.is_alive():
			continue
		var distance = unit.global_position.distance_to(enemy.global_position)
		if distance <= range and distance < best_distance:
			nearest = enemy
			best_distance = distance
	return nearest

func _unit_by_id(units: Array, unit_id: String) -> Node:
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null

func _roster_snapshot(game: Node) -> Dictionary:
	var snapshot := {}
	for monster_id in ["slime", "goblin", "imp"]:
		if not game.monster_roster.has(monster_id):
			continue
		var roster: Dictionary = game.monster_roster[monster_id]
		snapshot[monster_id] = {
			"display_name": game._monster_display_name(monster_id),
			"level": int(roster.get("level", 1)),
			"exp": int(roster.get("exp", 0)),
			"room": str(roster.get("room", "")),
			"specialization_id": str(roster.get("specialization_id", "")),
			"promotion_id": str(roster.get("promotion_id", ""))
		}
	return snapshot

func _resource_snapshot() -> Dictionary:
	return {
		"gold": GameState.gold,
		"mana": GameState.mana,
		"food": GameState.food,
		"infamy": GameState.infamy
	}

func _live_unit_snapshot(game: Node) -> Dictionary:
	var snapshot := {"monsters": [], "enemies": []}
	for group in [["monsters", game.monster_units], ["enemies", game.enemy_units]]:
		for unit in group[1]:
			if not is_instance_valid(unit):
				continue
			snapshot[group[0]].append({
				"unit_id": unit.unit_id,
				"hp": unit.hp,
				"max_hp": unit.max_hp,
				"down": unit.down,
				"room": unit.current_room,
				"goal_room": unit.goal_room,
				"tactical_state": unit.tactical_state,
				"intent_text": unit.intent_text,
				"target_text": unit.target_text,
				"target_unit_id": "" if unit.target == null or not is_instance_valid(unit.target) else unit.target.unit_id,
				"state_age": unit.state_age,
				"position": [snappedf(unit.global_position.x, 0.1), snappedf(unit.global_position.y, 0.1)],
				"velocity": [snappedf(unit.velocity.x, 0.1), snappedf(unit.velocity.y, 0.1)],
				"path_point_count": unit.path_points.size(),
				"next_path_point": [] if unit.path_points.is_empty() else [snappedf(unit.path_points[0].x, 0.1), snappedf(unit.path_points[0].y, 0.1)],
				"avoidance_timer": unit.avoidance_detour_timer
			})
	return snapshot

func _write_report() -> Dictionary:
	var report = {
		"tool": "DayOneToThreePlaytestRecorder",
		"evidence_kind": "automated_proxy" if proxy_mode else "automated_regression",
		"proxy_profile": proxy_profile_id if proxy_mode else "",
		"proxy_profile_label": _profile_label(proxy_profile_id) if proxy_mode else "",
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"seed": run_seed,
		"time_scale": simulation_time_scale,
		"combat_speed": TEST_COMBAT_SPEED,
		"max_sim_seconds": max_sim_seconds,
		"summary": {
			"days_recorded": day_records.size(),
			"failed": failed,
			"final_day": GameState.day,
			"victory": GameState.victory,
			"defeat": GameState.defeat,
			"resources": _resource_snapshot()
		},
		"days": day_records
	}
	var file_stem := "proxy_%s" % proxy_profile_id if proxy_mode else "latest"
	var json_path = output_dir.path_join("%s.json" % file_stem)
	var markdown_path = output_dir.path_join("%s.md" % file_stem)
	_write_text(json_path, JSON.stringify(report, "\t"))
	_write_text(markdown_path, _build_markdown(report))
	return {"json": json_path, "markdown": markdown_path}

func _build_markdown(report: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("# DAY 1~3 자동 대리 플레이 기록" if proxy_mode else "# DAY 1~3 자동 플레이테스트 기록")
	lines.append("")
	if proxy_mode:
		lines.append("- 프로필: %s (`%s`)" % [_profile_label(proxy_profile_id), proxy_profile_id])
		lines.append("- 자료 성격: 실제 사람이 아닌 규칙 기반 자동 대리 플레이")
		lines.append("- 제한: 조작 이해도와 재미는 판단할 수 없으며 조합별 전투 결과 비교에만 사용합니다.")
	lines.append("- 생성 시각: %s" % str(report.get("generated_at", "")))
	lines.append("- 난수 시작값: %d" % int(report.get("seed", 0)))
	lines.append("- 참고: 동시 충돌·공격 순서에 따라 세부 피해와 활약 EXP는 실행마다 조금 달라질 수 있습니다.")
	lines.append("- 판정: %s" % ("실패" if bool(report.get("summary", {}).get("failed", false)) else "통과"))
	lines.append("")
	lines.append("| DAY | 결과 | 전투 시간 | 마왕성 HP | 몬스터 HP | 적 격퇴 | 스킬 |")
	lines.append("|---:|---|---:|---:|---:|---:|---:|")
	for record in day_records:
		lines.append("| %d | %s | %.1f초 | %d/%d | %d/%d | %d/%d | %d |" % [
			int(record.get("day", 0)),
			str(record.get("result", "")),
			float(record.get("combat_time", record.get("elapsed_seconds", 0.0))),
			int(record.get("throne_hp", 0)),
			int(record.get("throne_max_hp", 0)),
			int(record.get("remaining_monster_hp", 0)),
			int(record.get("total_monster_hp", 0)),
			int(record.get("enemy_down", 0)),
			int(record.get("spawned", 0)),
			int(record.get("skill_uses", 0))
		])
	lines.append("")
	for record in day_records:
		lines.append("## DAY %d" % int(record.get("day", 0)))
		lines.append("")
		lines.append("선택:")
		for choice_value in record.get("choices", []):
			var choice: Dictionary = choice_value
			lines.append("- %s: %s" % [str(choice.get("id", "")), str(choice.get("label", ""))])
		lines.append("")
		lines.append("관찰 포인트:")
		lines.append("- %s" % str(record.get("choice_outcome", "")))
		var diagnostics: Dictionary = record.get("growth_diagnostics", {})
		for note_value in diagnostics.get("observation_notes", []):
			lines.append("- %s" % str(note_value))
		lines.append("")
		lines.append("성장:")
		var growth_choice: Dictionary = record.get("growth_choice", {})
		if not growth_choice.is_empty():
			lines.append("- 집중 성장: %s +%d EXP" % [str(growth_choice.get("display_name", growth_choice.get("monster_id", ""))), int(growth_choice.get("bonus_exp", 0))])
		for row_value in record.get("growth", []):
			var row: Dictionary = row_value
			var choice_bonus = int(row.get("choice_bonus_exp", 0))
			var choice_text = " / 집중 +%d" % choice_bonus if choice_bonus > 0 else ""
			lines.append("- %s: 공유 +%d / 활약 +%d%s / Lv.%d -> Lv.%d" % [
				str(row.get("display_name", row.get("monster_id", ""))),
				int(row.get("shared_exp", 0)),
				int(row.get("activity_exp", 0)),
				choice_text,
				int(row.get("level_before", 1)),
				int(row.get("level_after", 1))
			])
		lines.append("")
		lines.append("활약 근거:")
		for summary_value in diagnostics.get("rows", []):
			var summary: Dictionary = summary_value
			lines.append("- %s: 활약 %d EXP (%s), 피해 %d, 흡수 %d, 마무리 %d, 시설값 %d" % [
				str(summary.get("display_name", summary.get("monster_id", ""))),
				int(summary.get("activity_exp", 0)),
				str(summary.get("breakdown_text", "")),
				int(summary.get("damage_dealt", 0)),
				int(summary.get("damage_absorbed", 0)),
				int(summary.get("finishing_blows", 0)),
				int(summary.get("facility_value", 0))
			])
		var facility: Dictionary = record.get("facility_effects", {})
		if not facility.is_empty():
			lines.append("")
			lines.append("시설 기록: 감시 피해 +%d, 감시 둔화 %d회, 병영 피해 +%d, 회복 %d" % [
				int(facility.get("watch_post_bonus_damage", 0)),
				int(facility.get("watch_post_slow_applications", 0)),
				int(facility.get("barracks_bonus_damage", 0)),
				int(facility.get("recovery_healing", 0))
			])
		lines.append("")
	return "\n".join(lines)

func _profile_label(profile_id: String) -> String:
	return str({
		"balanced": "균형형",
		"aggressive": "공격형",
		"fortified": "방어형",
		"survival": "생존형",
		"minimal": "최소 조작형"
	}.get(profile_id, profile_id))

func _write_text(path: String, text: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("파일 저장 실패: %s" % path)
		return
	file.store_string(text)
	file.close()

func _add_choice(choices: Array[Dictionary], id: String, label: String, note: String) -> void:
	choices.append({"id": id, "label": label, "note": note})

func _logs_contain(logs: Array[String], fragment: String) -> bool:
	for message in logs:
		if message.find(fragment) >= 0:
			return true
	return false

func _collect_log(message: String) -> void:
	log_messages.append(message)

func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_fail(message)

func _fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	failed = true
