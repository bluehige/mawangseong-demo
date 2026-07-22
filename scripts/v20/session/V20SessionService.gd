class_name V20SessionService
extends RefCounted

const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const EconomyService = preload("res://scripts/v20/economy/V20EconomyService.gd")
const OnboardingService = preload("res://scripts/v20/onboarding/V20OnboardingService.gd")

const SCHEMA_VERSION := 2
const FINAL_DAY := 5


static func new_session(profile_id: String, economy_catalog: Dictionary, onboarding_config: Dictionary) -> Dictionary:
	var difficulty := EconomyService.profile(economy_catalog, profile_id)
	var economy := EconomyService.new_state(difficulty)
	return {
		"schema_version": SCHEMA_VERSION,
		"active": true,
		"status": "management",
		"day": 1,
		"difficulty_id": str(difficulty.get("id", EconomyService.DEFAULT_PROFILE_ID)),
		"economy": economy,
		"placement_state": initial_placement_state(int(economy.get("build_points", 10))),
		"onboarding": OnboardingService.new_state(onboarding_config),
		"retry_snapshot": {},
		"last_result": {},
		"completed": false
	}


static func initial_placement_state(build_points: int) -> Dictionary:
	return PlacementService.new_state(build_points, {
		"north_gate": {"display_name": "북문 길목", "placement_tags": ["door", "corridor"], "facility_id": "", "capacity": 2, "monster_ids": ["slime"]},
		"south_gate": {"display_name": "남문 길목", "placement_tags": ["door", "corridor"], "facility_id": "", "capacity": 2, "monster_ids": []},
		"treasure": {"display_name": "미끼 보물실", "placement_tags": ["bait", "room"], "facility_id": "", "capacity": 1, "monster_ids": ["goblin"]},
		"fallback": {"display_name": "후퇴선", "placement_tags": ["recovery", "room"], "facility_id": "", "capacity": 2, "monster_ids": ["imp"]}
	}, {
		"slime": {"display_name": "슬라임 · 성문 파수", "room_id": "north_gate"},
		"goblin": {"display_name": "고블린 · 도둑 사냥꾼", "room_id": "treasure"},
		"imp": {"display_name": "임프 · 장거리 화염술", "room_id": "fallback"}
	})


static func advance(state: Dictionary, delta: float, screen_name: String) -> Dictionary:
	var next := state.duplicate(true)
	next["onboarding"] = OnboardingService.advance(next.get("onboarding", {}), delta, screen_name)
	return next


static func record_placement(state: Dictionary, placement_state: Dictionary, result: Dictionary, onboarding_config: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var before_points := int(next.get("placement_state", {}).get("build_points", 0))
	next["placement_state"] = placement_state.duplicate(true)
	next["economy"]["build_points"] = int(placement_state.get("build_points", 0))
	var spent := maxi(0, before_points - int(placement_state.get("build_points", 0)))
	if spent > 0 and next.get("economy", {}).get("metrics", {}).has("build_points_spent"):
		next["economy"]["metrics"]["build_points_spent"] = float(next["economy"]["metrics"].get("build_points_spent", 0.0)) + spent
	var action_id := ""
	match str(result.get("status", "")):
		PlacementService.STATUS_INSTALLED:
			action_id = "facility_installed"
		PlacementService.STATUS_REPLACED:
			action_id = "facility_replaced"
		PlacementService.STATUS_MONSTER_PLACED:
			action_id = "monster_placed"
	if action_id != "":
		var recorded := OnboardingService.record_action(next.get("onboarding", {}), onboarding_config, action_id, result.get("state", {}).get("last_action", {}))
		next["onboarding"] = recorded.get("state", next.get("onboarding", {}))
	return next


static func record_action(state: Dictionary, onboarding_config: Dictionary, action_id: String, details: Dictionary = {}) -> Dictionary:
	var next := state.duplicate(true)
	var recorded := OnboardingService.record_action(next.get("onboarding", {}), onboarding_config, action_id, details)
	next["onboarding"] = recorded.get("state", next.get("onboarding", {}))
	return next


static func begin_combat(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	next["status"] = "combat"
	next["retry_snapshot"] = {
		"day": int(next.get("day", 1)),
		"placement_state": PlacementService.serialize(next.get("placement_state", {})),
		"difficulty_id": str(next.get("difficulty_id", EconomyService.DEFAULT_PROFILE_ID))
	}
	return next


static func finalize_battle(state: Dictionary, result_summary: Dictionary, economy_catalog: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var result := result_summary.duplicate(true)
	var metrics: Dictionary = result.get("metrics", {})
	var success := bool(result.get("win", false))
	var cause := cause_for_result(result)
	var highlight := highlight_for_result(result)
	var guidance := guidance_for_result(result)
	var outcome := {
		"success": success,
		"objective_damage": maxi(0, 1500 - int(metrics.get("demon_lord_hp", 1500))),
		"command_points_spent": int(metrics.get("v20_command_points_spent", 0)),
		"secondary_objectives_lost": 1 if int(metrics.get("treasure_gold_stolen", 0)) > 0 or int(metrics.get("facility_disables", 0)) > 0 else 0
	}
	var difficulty := EconomyService.profile(economy_catalog, str(next.get("difficulty_id", EconomyService.DEFAULT_PROFILE_ID)))
	var settlement := EconomyService.settle_day(next.get("economy", {}), difficulty, outcome)
	next["economy"] = settlement.get("state", next.get("economy", {}))
	result["v20"] = {
		"cause": cause,
		"highlight": highlight,
		"guidance": guidance,
		"placement_preserved": true,
		"gross_income": int(settlement.get("gross_income", 0)),
		"repair_cost": int(settlement.get("repair_cost", 0)),
		"net_income": int(settlement.get("net_income", 0))
	}
	var lines: Array = result.get("lines", []).duplicate()
	lines.push_front("다음 수정: %s" % guidance)
	lines.push_front("원인: %s" % cause)
	result["lines"] = lines
	next["last_result"] = result.duplicate(true)
	next["status"] = "result"
	if success and int(next.get("day", 1)) == 1:
		next["onboarding"] = OnboardingService.complete_day_one(next.get("onboarding", {}))
	return {"state": next, "result": result}


static func retry(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var snapshot: Dictionary = next.get("retry_snapshot", {})
	var restored := PlacementService.restore(snapshot.get("placement_state", {}))
	if bool(restored.get("ok", false)):
		next["placement_state"] = restored.get("state", {}).duplicate(true)
		next["placement_state"]["build_points"] = int(next.get("economy", {}).get("build_points", next["placement_state"].get("build_points", 0)))
	var cause := str(next.get("last_result", {}).get("v20", {}).get("cause", "패배 원인을 다시 확인하세요."))
	next["onboarding"] = OnboardingService.record_retry(next.get("onboarding", {}), cause)
	next["status"] = "management"
	return next


static func advance_after_win(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	if not bool(next.get("last_result", {}).get("win", false)):
		return next
	if int(next.get("day", 1)) >= FINAL_DAY:
		next["completed"] = true
		next["status"] = "completed"
		return next
	next["day"] = int(next.get("day", 1)) + 1
	next["status"] = "management"
	next["last_result"] = {}
	next["retry_snapshot"] = {}
	return next


static func save_payload(state: Dictionary) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"active": bool(state.get("active", true)),
		"status": str(state.get("status", "management")),
		"day": int(state.get("day", 1)),
		"difficulty_id": str(state.get("difficulty_id", EconomyService.DEFAULT_PROFILE_ID)),
		"economy": state.get("economy", {}).duplicate(true),
		"placement": PlacementService.serialize(state.get("placement_state", {})),
		"onboarding": state.get("onboarding", {}).duplicate(true),
		"retry_snapshot": state.get("retry_snapshot", {}).duplicate(true),
		"last_result": state.get("last_result", {}).duplicate(true),
		"completed": bool(state.get("completed", false))
	}


static func restore(payload: Dictionary, economy_catalog: Dictionary) -> Dictionary:
	if int(payload.get("schema_version", 0)) != SCHEMA_VERSION:
		return {"ok": false, "error": "unsupported_schema", "state": {}}
	var day := int(payload.get("day", 0))
	if day < 1 or day > FINAL_DAY or not economy_catalog.has(str(payload.get("difficulty_id", ""))):
		return {"ok": false, "error": "invalid_session_contract", "state": {}}
	var placement := PlacementService.restore(payload.get("placement", {}))
	if not bool(placement.get("ok", false)):
		return {"ok": false, "error": "invalid_placement", "state": {}}
	var state := payload.duplicate(true)
	state["placement_state"] = placement.get("state", {}).duplicate(true)
	state.erase("placement")
	return {"ok": true, "error": "", "state": state}


static func cause_for_result(result_summary: Dictionary) -> String:
	if bool(result_summary.get("win", false)):
		return "목표를 지키며 마지막 침입자까지 격퇴했습니다."
	var metrics: Dictionary = result_summary.get("metrics", {})
	if int(metrics.get("demon_lord_hp", 1)) <= 0:
		return "왕좌 피해가 누적되어 방어선이 무너졌습니다."
	if int(metrics.get("facility_disables", 0)) > 0:
		return "공병이 핵심 시설을 무력화한 동안 전선이 비었습니다."
	if int(metrics.get("treasure_gold_stolen", 0)) > 0:
		return "도둑을 놓쳐 보물 목표와 왕좌 방어가 동시에 흔들렸습니다."
	return "첫 교전선이 너무 앞에 모여 후속 경로 전환에 대응하지 못했습니다."


static func highlight_for_result(result_summary: Dictionary) -> String:
	var metrics: Dictionary = result_summary.get("metrics", {})
	var alive := int(metrics.get("alive_monsters", 0))
	var total := maxi(1, int(metrics.get("total_monsters", 0)))
	if alive == total:
		return "몬스터 전원이 끝까지 전선을 지켜 다음 방어 준비를 온전히 남겼습니다."
	if int(metrics.get("facilities_saved", 0)) > 0:
		return "공병의 시설 무력화를 막아 핵심 방어선을 지켜냈습니다."
	if int(metrics.get("v20_command_points_spent", 0)) > 0:
		return "전술 명령으로 위험 구간의 교전을 끊어냈습니다."
	return "첫 교전선이 침입대의 속도를 늦춰 후퇴할 시간을 벌었습니다."


static func guidance_for_result(result_summary: Dictionary) -> String:
	if bool(result_summary.get("win", false)):
		return "현재 배치를 유지하거나 다음 날의 새 목표에 맞춰 한 곳만 조정하세요."
	var metrics: Dictionary = result_summary.get("metrics", {})
	if int(metrics.get("facility_disables", 0)) > 0:
		return "시설을 분산하고 집중 명령을 공병에게 예약하세요."
	if int(metrics.get("treasure_gold_stolen", 0)) > 0:
		return "고블린을 보물 경로에 두거나 미끼 보물실로 목표를 분리하세요."
	return "후퇴선에 한 명을 남기고 집결·비상 후퇴 명령력을 보존하세요."
