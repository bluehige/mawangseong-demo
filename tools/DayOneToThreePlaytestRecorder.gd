extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

const MAX_SIM_SECONDS = 120.0
const PHYSICS_STEP = 1.0 / 60.0
const SIM_TIME_SCALE = 8.0
const TEST_COMBAT_SPEED = 1.5
const RUN_SEED = 20260711
const ACTIVITY_EXP_CAP = 8

var failed := false
var output_dir := ""
var log_messages: Array[String] = []
var day_records: Array[Dictionary] = []

func _ready() -> void:
	var log_collector = Callable(self, "_collect_log")
	if not SignalBus.log_added.is_connected(log_collector):
		SignalBus.log_added.connect(log_collector)
	call_deferred("_run")

func _run() -> void:
	Engine.time_scale = SIM_TIME_SCALE
	seed(RUN_SEED)
	output_dir = ProjectSettings.globalize_path("res://tmp/day1_3_playtest_records")
	DirAccess.make_dir_recursive_absolute(output_dir)
	print("DAY1_3_PLAYTEST_RECORDER: START")

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
			_expect(GameState.victory, "DAY 3 승리 플래그 저장")

	var written_paths = _write_report()
	game.queue_free()
	await _settle(2)
	Engine.time_scale = 1.0
	print("DAY1_3_PLAYTEST_RECORDER_JSON: %s" % written_paths.get("json", ""))
	print("DAY1_3_PLAYTEST_RECORDER_MARKDOWN: %s" % written_paths.get("markdown", ""))
	print("DAY1_3_PLAYTEST_RECORDER: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)

func _prepare_day(game: Node, day: int) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	match day:
		1:
			_add_choice(choices, "global_directive", "전체 지침: 사수", "첫 전투는 오래 버티며 성장 결산을 확인한다.")
			game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
			game.selected_room = "entrance"
			_add_choice(choices, "room_directive", "입구 지침: 입구 봉쇄", "첫 침입자를 입구에서 붙잡는다.")
			game._set_room_directive(Constants.ROOM_DIRECTIVE_ENTRY_BLOCK)
		2:
			if game._early_specialization_required_for_current_day():
				var chosen = game._choose_early_specialization("goblin", "goblin_treasure_hunter")
				_expect(chosen, "DAY 2 도둑 대응 전술 특화 선택")
				_add_choice(choices, "specialization", "고블린: 도둑 사냥꾼", "도둑을 실제로 추격하는지 기록한다.")
				game._set_screen(Constants.SCREEN_MANAGEMENT)
			if game.rooms.has("slot_01") and str(game.rooms["slot_01"].get("facility_role", "")) != "watch_post":
				var changed = game._change_room_facility("slot_01", "watch_post")
				_expect(changed, "DAY 2 감시 초소 건설")
				_add_choice(choices, "facility", "건설 슬롯: 감시 초소", "시설 발동 기록과 전투 시간 변화를 본다.")
			game.selected_room = "spike_corridor"
			game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
			_add_choice(choices, "room_directive", "가시 복도: 함정 유도", "도둑과 일반 적을 가시 복도로 끌어들인다.")
			game._set_global_directive(Constants.DIRECTIVE_ALL_OUT)
			_add_choice(choices, "global_directive", "전체 지침: 총공격", "DAY 2에서는 빠른 처치가 얼마나 위험한지 기록한다.")
		3:
			if game._early_specialization_required_for_current_day():
				var chosen_day3 = game._choose_early_specialization("goblin", "goblin_treasure_hunter")
				_expect(chosen_day3, "DAY 3 전술 특화 보정 선택")
				game._set_screen(Constants.SCREEN_MANAGEMENT)
			if game.rooms.has("slot_01") and str(game.rooms["slot_01"].get("facility_role", "")) != "watch_post":
				var changed_day3 = game._change_room_facility("slot_01", "watch_post")
				_expect(changed_day3, "DAY 3 감시 초소 유지")
			game.selected_room = "spike_corridor"
			game._set_room_directive(Constants.ROOM_DIRECTIVE_TRAP_LURE)
			_add_choice(choices, "room_directive", "가시 복도: 함정 유도", "강한 웨이브를 한곳으로 묶어 스킬을 맞춘다.")
			game._set_global_directive(Constants.DIRECTIVE_DEFENSE)
			_add_choice(choices, "global_directive", "전체 지침: 사수", "DAY 2의 총공격을 그대로 고집하지 않는 방어 선택을 검증한다.")
			_add_choice(choices, "assist", "자동 스킬 보조", "임프 화염구/화염 지대와 고블린 베기를 실제 전투 중 사용한다.")
	return choices

func _run_day(game: Node, day: int, choices: Array[Dictionary], log_start_index: int) -> Dictionary:
	game._start_combat()
	await get_tree().physics_frame
	_expect(game.current_screen == Constants.SCREEN_COMBAT, "DAY %d 전투 화면 진입" % day)
	game.combat_speed = TEST_COMBAT_SPEED
	var elapsed := 0.0
	var skill_uses := 0
	var thief_reached_treasure := false
	var assist_mode = "active_skills" if day == 3 else "none"
	while game.current_screen != Constants.SCREEN_RESULT and elapsed < MAX_SIM_SECONDS:
		skill_uses += _apply_assist(game, assist_mode)
		if _any_thief_in_treasure(game):
			thief_reached_treasure = true
		await get_tree().physics_frame
		elapsed += PHYSICS_STEP * SIM_TIME_SCALE * TEST_COMBAT_SPEED
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
	var best_id := ""
	var best_score := -1
	for row_value in game.last_growth_summary:
		var row: Dictionary = row_value
		var score = int(row.get("activity_exp", 0)) * 1000 + int(row.get("damage_dealt", 0)) + int(row.get("damage_absorbed", 0))
		if score > best_score:
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
		"result_lines": result_lines.duplicate(true),
		"recent_logs": day_logs.slice(max(0, day_logs.size() - 10), day_logs.size())
	}
	record["growth_diagnostics"] = _growth_diagnostics(record.get("growth", []))
	record["choice_outcome"] = _choice_outcome_summary(record)
	return record

func _assert_day_record(record: Dictionary) -> void:
	var day = int(record.get("day", 0))
	_expect(not bool(record.get("timed_out", false)), "DAY %d 전투가 제한 시간 안에 결산 도달" % day)
	_expect(str(record.get("result", "")) == "win", "DAY %d 방어 성공" % day)
	_expect(int(record.get("enemy_down", 0)) == int(record.get("spawned", -1)), "DAY %d 스폰된 적 전원 격퇴" % day)
	_expect(int(record.get("throne_hp", 0)) > 0, "DAY %d 마왕성 체력 생존" % day)
	_expect(int(record.get("remaining_monster_hp", 0)) > 0, "DAY %d 몬스터 잔여 체력 기록" % day)
	_expect((record.get("growth", []) as Array).size() >= 3, "DAY %d 몬스터 성장 기록 3명 이상" % day)
	_expect(not (record.get("growth_choice", {}) as Dictionary).is_empty(), "DAY %d 집중 성장 선택 기록" % day)
	_expect(not (record.get("growth_diagnostics", {}) as Dictionary).is_empty(), "DAY %d 활약 진단 기록" % day)
	var saw_choice_bonus := false
	for row_value in (record.get("growth", []) as Array):
		var row: Dictionary = row_value
		if int(row.get("choice_bonus_exp", 0)) > 0:
			saw_choice_bonus = true
	_expect(saw_choice_bonus, "DAY %d 성장 기록에 집중 보너스 EXP 반영" % day)
	_expect((record.get("result_lines", []) as Array).size() >= 8, "DAY %d 결산 문구 기록" % day)
	if day == 2:
		_expect(not bool(record.get("thief_stole", false)), "DAY 2 도둑 보물 도난 없음")
		_expect(int(record.get("facility_effects", {}).get("watch_post_bonus_damage", 0)) > 0, "DAY 2 감시 초소 추가 피해 기록")
	if day == 3:
		_expect(int(record.get("skill_uses", 0)) > 0, "DAY 3 스킬 보조 사용 기록")

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
		if activity_exp >= ACTIVITY_EXP_CAP:
			capped_activity.append(display_name)
		elif activity_exp >= ACTIVITY_EXP_CAP - 1:
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
		notes.append("활약 상한 %d EXP 도달 없음" % ACTIVITY_EXP_CAP)
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
		game._select_unit(imp)
		return 1 if game._use_selected_skill(1) else 0
	if _alive_enemy_count(game) >= 1 and imp.skill_ready("fireball") and GameState.mana >= 20:
		game._select_unit(imp)
		return 1 if game._use_selected_skill(0) else 0
	return 0

func _try_goblin_quick_slash(game: Node) -> int:
	var goblin = _unit_by_id(game.monster_units, "goblin")
	if goblin == null or not goblin.is_alive() or not goblin.skill_ready("quick_slash"):
		return 0
	if _nearest_enemy_in_range(game, goblin, goblin.attack_range + 38.0) == null:
		return 0
	game._select_unit(goblin)
	return 1 if game._use_selected_skill(0) else 0

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

func _write_report() -> Dictionary:
	var report = {
		"tool": "DayOneToThreePlaytestRecorder",
		"generated_at": Time.get_datetime_string_from_system(false, true),
		"seed": RUN_SEED,
		"time_scale": SIM_TIME_SCALE,
		"combat_speed": TEST_COMBAT_SPEED,
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
	var json_path = output_dir.path_join("latest.json")
	var markdown_path = output_dir.path_join("latest.md")
	_write_text(json_path, JSON.stringify(report, "\t"))
	_write_text(markdown_path, _build_markdown(report))
	return {"json": json_path, "markdown": markdown_path}

func _build_markdown(report: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("# DAY 1~3 자동 플레이테스트 기록")
	lines.append("")
	lines.append("- 생성 시각: %s" % str(report.get("generated_at", "")))
	lines.append("- 고정 난수값: %d" % int(report.get("seed", 0)))
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
