extends Node

const BossScript = preload("res://scripts/systems/bosses/VesperBossBattleService.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_data_and_profiles()
	_test_dive_and_alerts()
	_test_seal_channel_and_exchange()
	_test_return_retry_and_metrics()
	if failed:
		print("VESPER_BOSS_PHASE23_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("VESPER_BOSS_PHASE23_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_data_and_profiles() -> void:
	var boss: Dictionary = DataRegistry.enemies.get("rival_vesper_council_champion", {})
	_expect(bool(boss.get("placeholder_art", false)) and boss.get("skills", []).size() == 4, "베스퍼 placeholder boss·기술 4개")
	var unit = UnitScript.new()
	add_child(unit)
	unit.setup("rival_vesper_council_champion", boss, "enemy", "entrance")
	_expect(unit.max_hp == 540 and unit.atk == 27 and unit.def == 7 and is_equal_approx(unit.move_speed, 155.0) and is_equal_approx(unit.attack_interval, 0.85), "베스퍼 최종 능력치 계약")
	unit.queue_free()
	var day25 := BossScript.battle_profile(25, boss)
	var day30 := BossScript.battle_profile(30, boss)
	_expect(int(day25.max_hp) == 405 and day25.skills.size() == 3, "DAY 25 1차 형태·3기술")
	_expect(int(day30.max_hp) == 540 and day30.skills.size() == 4, "DAY 30 최종 형태·4기술")


func _test_dive_and_alerts() -> void:
	var paths := {"lower_01:upper_02": ["lower_stair", "upper_stair"], "upper_02:lower_01": ["upper_stair", "lower_stair"]}
	var dive := BossScript.deadline_dive("lower_01", "upper_02", paths, DataRegistry.skills.deadline_dive)
	_expect(bool(dive.ok) and dive.endpoints == ["lower_stair", "upper_stair"], "층간 급강하 계단 endpoint 경로")
	_expect(str(dive.camera_focus_floor) == "upper_02" and bool(dive.hidden_floor_alert), "도착 층 카메라·숨은 층 경보")
	_expect(is_equal_approx(float(dive.silence_seconds), 1.5) and is_equal_approx(float(dive.arrival_lock_seconds), 1.0), "도착 침묵·1초 행동 정지")
	_expect(not bool(BossScript.deadline_dive("lower_01", "upper_02", {}, DataRegistry.skills.deadline_dive).ok), "등록되지 않은 순간이동 경로 거부")


func _test_seal_channel_and_exchange() -> void:
	var channel := BossScript.start_seal_snatch(DataRegistry.skills.seal_snatch)
	_expect(is_equal_approx(float(channel.remaining), 5.0) and is_equal_approx(float(channel.incoming_damage_multiplier), 1.25), "인장 수거 5초 채널·받는 피해 25% 증가")
	channel = BossScript.tick_seal_snatch(channel, 4.9)
	_expect(bool(channel.active) and not bool(channel.completed), "5초 전 인장 채널 유지")
	channel = BossScript.tick_seal_snatch(channel, 0.1)
	_expect(not bool(channel.active) and bool(channel.completed), "5초 인장 채널 완료")
	var boss := {"floor_id": "lower_01", "position": Vector2(100, 200)}
	var courier := {"active": true, "floor_id": "upper_02", "position": Vector2(500, 220)}
	var exchange := BossScript.airmail_exchange(boss, [courier], ["lower_01", "upper_02"], DataRegistry.skills.airmail_exchange)
	_expect(bool(exchange.ok) and str(exchange.boss.floor_id) == "upper_02" and exchange.boss.position == Vector2(500, 220), "베스퍼·황혼 전령 위치 교환")
	_expect(str(exchange.courier.floor_id) == "lower_01" and exchange.courier.position == Vector2(100, 200), "전령 교환 위치 유효")
	_expect(not bool(BossScript.airmail_exchange(boss, [{"active": true, "floor_id": "void", "position": Vector2.ZERO}], ["lower_01", "upper_02"], DataRegistry.skills.airmail_exchange).ok), "유효 층 밖 교환 금지")


func _test_return_retry_and_metrics() -> void:
	var returned := BossScript.return_to_sender([{"skill_id": "guard", "position_skill": false}, {"skill_id": "ceiling_path", "position_skill": true}, {"skill_id": "heal", "position_skill": false}], DataRegistry.skills.return_to_sender)
	_expect(bool(returned.ok) and str(returned.skill_id) == "ceiling_path" and is_equal_approx(float(returned.cooldown_increase_seconds), 4.0), "최근 위치 스킬 재사용 대기 +4초")
	_expect(not bool(BossScript.return_to_sender([{"skill_id": "heal", "position_skill": false}], DataRegistry.skills.return_to_sender).ok), "위치 스킬 기록 없으면 압박 생략")
	var loss := BossScript.resolve_battle({}, 25, false, {"seal_channels_completed": 1, "floor_transitions": 3})
	_expect(int(loss.retry_day) == 25 and str(loss.return_screen) == "management", "DAY 25 패배 관리 복귀·재도전")
	_expect(int(loss.active_run.run_metrics_update4.rival_bosses.rival_vesper.losses) == 1 and int(loss.active_run.run_metrics_update4.rival_bosses.rival_vesper.floor_transitions) == 3, "패배·층 전이 지표")
	var win := BossScript.resolve_battle(loss.active_run, 30, true, {"seal_channels_completed": 0, "floor_transitions": 4})
	_expect(int(win.retry_day) == 0 and int(win.active_run.run_metrics_update4.rival_bosses.rival_vesper.wins) == 1, "DAY 30 승리·결산 이동")
	_expect(int(win.active_run.run_metrics_update4.rival_bosses.rival_vesper.seal_channels_completed) == 1 and int(win.active_run.run_metrics_update4.rival_bosses.rival_vesper.floor_transitions) == 7, "인장·층 전이 누적 지표")


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[VesperBossPhase23] FAIL: %s" % label)
