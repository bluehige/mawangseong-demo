class_name V20SessionService
extends RefCounted

const PlacementService = preload("res://scripts/v20/placement/V20PlacementService.gd")
const EconomyService = preload("res://scripts/v20/economy/V20EconomyService.gd")
const OnboardingService = preload("res://scripts/v20/onboarding/V20OnboardingService.gd")
const SpatialModel = preload("res://scripts/v20/spatial/V20SpatialModel.gd")
const DayFlowService = preload("res://scripts/v20/flow/V20DayFlowService.gd")

const SCHEMA_VERSION := 3
const FINAL_DAY := 5


static func new_session(profile_id: String, economy_catalog: Dictionary, onboarding_config: Dictionary) -> Dictionary:
	var difficulty := EconomyService.profile(economy_catalog, profile_id)
	var economy := EconomyService.new_state(difficulty)
	economy["build_points"] = DayFlowService.BUILD_CAP
	return {
		"schema_version": SCHEMA_VERSION,
		"active": true,
		"status": "management",
		"flow_state": DayFlowService.INTRUSION_BRIEF,
		"day": 1,
		"difficulty_id": str(difficulty.get("id", EconomyService.DEFAULT_PROFILE_ID)),
		"economy": economy,
		"placement_state": initial_placement_state(DayFlowService.BUILD_CAP),
		"onboarding": OnboardingService.new_state(onboarding_config),
		"runtime_state": {},
		"precombat_snapshot": {},
		"retry_snapshot": {},
		"encounter_seed": 2001,
		"rng_state": 0,
		"defense_countdown_seconds": 0.0,
		"last_result": {},
		"completed": false
	}


static func initial_placement_state(build_points: int) -> Dictionary:
	var rooms := _canonical_rooms()
	rooms["gate_outpost"]["monster_ids"] = ["slime"]
	rooms["central_battle_room"]["monster_ids"] = ["goblin"]
	rooms["throne_anteroom"]["monster_ids"] = ["imp"]
	return PlacementService.new_state(build_points, rooms, {
		"slime": {"display_name": "슬라임 · 성문 파수", "room_id": "gate_outpost"},
		"goblin": {"display_name": "고블린 · 도둑 사냥꾼", "room_id": "central_battle_room"},
		"imp": {"display_name": "임프 · 장거리 화염술", "room_id": "throne_anteroom"}
	})


static func normalize_placement_sections(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	if not (next.get("rooms") is Dictionary):
		return next
	var canonical_rooms := _canonical_rooms()
	for zone_id_value in canonical_rooms.keys():
		var zone_id := str(zone_id_value)
		if not next["rooms"].has(zone_id):
			continue
		var existing: Dictionary = next["rooms"].get(zone_id, {}).duplicate(true)
		var canonical: Dictionary = canonical_rooms.get(zone_id, {}).duplicate(true)
		canonical["facility_id"] = str(existing.get("facility_id", ""))
		canonical["monster_ids"] = existing.get("monster_ids", []).duplicate()
		next["rooms"][zone_id] = canonical
	return PlacementService.new_state(int(next.get("build_points", 0)), next.get("rooms", {}), next.get("roster", {}))


static func _canonical_rooms() -> Dictionary:
	var rooms: Dictionary = {}
	var board := SpatialModel.load_default_board()
	for definition in SpatialModel.defense_zones(board):
		var zone_id := str(definition.get("zone_id", ""))
		var monster_slot_ids: Array = []
		for slot_value in definition.get("monster_slots", []):
			monster_slot_ids.append(str(slot_value.get("slot_id", "")))
		rooms[zone_id] = {
			"zone_id": zone_id,
			"display_name": "%d · %s" % [int(definition.get("order", 0)), str(definition.get("display_name", zone_id))],
			"section_index": int(definition.get("order", 0)),
			"strategy_hint": str(definition.get("strategy_hint", "배치 슬롯의 실제 전투 구역")),
			"placement_tags": definition.get("placement_tags", []).duplicate(),
			"capacity": int(definition.get("max_defenders", 0)),
			"facility_slot_id": str(definition.get("facility_slot", {}).get("slot_id", "")),
			"monster_slot_ids": monster_slot_ids,
			"facility_id": "",
			"monster_ids": []
		}
	return rooms


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


static func begin_placement(state: Dictionary) -> Dictionary:
	return DayFlowService.transition(state, DayFlowService.PLACEMENT, {"action": "placement_start"})


static func record_action(state: Dictionary, onboarding_config: Dictionary, action_id: String, details: Dictionary = {}) -> Dictionary:
	var next := state.duplicate(true)
	var recorded := OnboardingService.record_action(next.get("onboarding", {}), onboarding_config, action_id, details)
	next["onboarding"] = recorded.get("state", next.get("onboarding", {}))
	return next


static func begin_defense_start(state: Dictionary, facility_catalog: Dictionary, runtime_state: Dictionary, encounter_seed: int, rng_state: int) -> Dictionary:
	var placement_validation := DayFlowService.validate_defense_placement(state.get("placement_state", {}), facility_catalog)
	if not bool(placement_validation.get("ok", false)):
		return {"ok": false, "error": "invalid_defense_placement", "errors": placement_validation.get("errors", []), "state": state.duplicate(true)}
	var transition := DayFlowService.transition(state, DayFlowService.DEFENSE_START, {"placement_valid": true})
	if not bool(transition.get("ok", false)):
		return transition
	var next: Dictionary = transition.get("state", {}).duplicate(true)
	next["placement_state"] = DayFlowService.recalculate_placement_budget(next.get("placement_state", {}), facility_catalog)
	next["economy"]["build_points"] = int(next.get("placement_state", {}).get("build_points", DayFlowService.BUILD_CAP))
	next["runtime_state"] = runtime_state.duplicate(true)
	next["encounter_seed"] = encounter_seed
	next["rng_state"] = rng_state
	next["defense_countdown_seconds"] = DayFlowService.COUNTDOWN_SECONDS
	next["precombat_snapshot"] = DayFlowService.make_precombat_snapshot(next, runtime_state, encounter_seed, rng_state)
	next["retry_snapshot"] = next["precombat_snapshot"].duplicate(true)
	return {"ok": true, "error": "", "state": next}


static func cancel_defense_start(state: Dictionary) -> Dictionary:
	var transitioned := DayFlowService.transition(state, DayFlowService.PLACEMENT, {"cancel_or_error": true})
	if bool(transitioned.get("ok", false)):
		transitioned["state"]["defense_countdown_seconds"] = 0.0
	return transitioned


static func advance_defense_countdown(state: Dictionary, delta: float) -> Dictionary:
	var next := state.duplicate(true)
	if str(next.get("flow_state", "")) != DayFlowService.DEFENSE_START:
		return next
	var remaining := maxf(0.0, float(next.get("defense_countdown_seconds", DayFlowService.COUNTDOWN_SECONDS)) - maxf(0.0, delta))
	next["defense_countdown_seconds"] = 0.0 if remaining <= 0.0001 else remaining
	return next


static func begin_combat(state: Dictionary, snapshot_saved: bool = true, spatial_resolved: bool = true, countdown_complete: bool = true) -> Dictionary:
	return DayFlowService.transition(state, DayFlowService.COMBAT, {
		"snapshot_saved": snapshot_saved and not state.get("precombat_snapshot", {}).is_empty(),
		"spatial_resolved": spatial_resolved,
		"countdown_complete": countdown_complete and float(state.get("defense_countdown_seconds", 0.0)) <= 0.0
	})


static func finalize_battle(state: Dictionary, result_summary: Dictionary, economy_catalog: Dictionary) -> Dictionary:
	var transitioned := DayFlowService.transition(state, DayFlowService.RESULT, {"battle_finished": true})
	if not bool(transitioned.get("ok", false)):
		return {"state": state.duplicate(true), "result": result_summary.duplicate(true), "ok": false, "error": str(transitioned.get("error", "forbidden_edge"))}
	var next: Dictionary = transitioned.get("state", {}).duplicate(true)
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
	if success and int(next.get("day", 1)) == 1:
		next["onboarding"] = OnboardingService.complete_day_one(next.get("onboarding", {}))
	return {"state": next, "result": result, "ok": true, "error": ""}


static func retry(state: Dictionary, retry_mode: String, facility_catalog: Dictionary) -> Dictionary:
	if retry_mode not in ["edit", "same"]:
		return {"ok": false, "error": "unknown_retry_mode", "state": state.duplicate(true)}
	var target_state := DayFlowService.PLACEMENT if retry_mode == "edit" else DayFlowService.DEFENSE_START
	var transitioned := DayFlowService.transition(state, target_state, {"win": false, "retry_mode": retry_mode})
	if not bool(transitioned.get("ok", false)):
		return transitioned
	var next: Dictionary = transitioned.get("state", {}).duplicate(true)
	var snapshot: Dictionary = next.get("precombat_snapshot", next.get("retry_snapshot", {}))
	if snapshot.is_empty():
		return {"ok": false, "error": "precombat_snapshot_missing", "state": state.duplicate(true)}
	var snapshot_placement = snapshot.get("placement_state", {})
	if not (snapshot_placement is Dictionary):
		return {"ok": false, "error": "invalid_snapshot_placement", "state": state.duplicate(true)}
	next["placement_state"] = DayFlowService.recalculate_placement_budget(normalize_placement_sections(snapshot_placement), facility_catalog)
	next["economy"]["build_points"] = int(next.get("placement_state", {}).get("build_points", DayFlowService.BUILD_CAP))
	next["runtime_state"] = snapshot.get("runtime_state", {}).duplicate(true)
	next["encounter_seed"] = int(snapshot.get("encounter_seed", 0))
	next["rng_state"] = int(snapshot.get("rng_state", 0))
	next["precombat_snapshot"] = snapshot.duplicate(true)
	next["retry_snapshot"] = snapshot.duplicate(true)
	next["defense_countdown_seconds"] = DayFlowService.COUNTDOWN_SECONDS if retry_mode == "same" else 0.0
	var cause := str(next.get("last_result", {}).get("v20", {}).get("cause", "패배 원인을 다시 확인하세요."))
	next["onboarding"] = OnboardingService.record_retry(next.get("onboarding", {}), cause)
	return {"ok": true, "error": "", "state": next}


static func recover_interrupted_combat(state: Dictionary, facility_catalog: Dictionary) -> Dictionary:
	var snapshot: Dictionary = state.get("precombat_snapshot", state.get("retry_snapshot", {}))
	if snapshot.is_empty():
		return {"ok": false, "error": "precombat_snapshot_missing", "state": state.duplicate(true)}
	var next := state.duplicate(true)
	next["flow_state"] = DayFlowService.DEFENSE_START
	next["status"] = "management"
	next["placement_state"] = DayFlowService.recalculate_placement_budget(normalize_placement_sections(snapshot.get("placement_state", {})), facility_catalog)
	next["economy"]["build_points"] = int(next.get("placement_state", {}).get("build_points", DayFlowService.BUILD_CAP))
	next["runtime_state"] = snapshot.get("runtime_state", {}).duplicate(true)
	next["encounter_seed"] = int(snapshot.get("encounter_seed", 0))
	next["rng_state"] = int(snapshot.get("rng_state", 0))
	next["defense_countdown_seconds"] = DayFlowService.COUNTDOWN_SECONDS
	return {"ok": true, "error": "", "state": next}


static func advance_after_win(state: Dictionary, facility_catalog: Dictionary = {}, monster_catalog: Dictionary = {}, command_catalog: Dictionary = {}) -> Dictionary:
	var next := state.duplicate(true)
	if not bool(next.get("last_result", {}).get("win", false)):
		return {"ok": false, "error": "win_required", "state": next}
	if int(next.get("day", 1)) >= FINAL_DAY:
		next["completed"] = true
		next["status"] = "result"
		return {"ok": true, "error": "", "state": next}
	var transitioned := DayFlowService.transition(next, DayFlowService.INTRUSION_BRIEF, {"win": true, "day": int(next.get("day", 1))})
	if not bool(transitioned.get("ok", false)):
		return transitioned
	next = transitioned.get("state", {}).duplicate(true)
	next["day"] = int(next.get("day", 1)) + 1
	next["last_result"] = {}
	next["placement_state"] = DayFlowService.recalculate_placement_budget(next.get("placement_state", {}), facility_catalog) if not facility_catalog.is_empty() else next.get("placement_state", {}).duplicate(true)
	next["economy"]["build_points"] = int(next.get("placement_state", {}).get("build_points", DayFlowService.BUILD_CAP))
	next["runtime_state"] = DayFlowService.new_day_runtime(next.get("placement_state", {}), monster_catalog, command_catalog, facility_catalog) if not monster_catalog.is_empty() else {}
	next["encounter_seed"] = 2000 + int(next.get("day", 1))
	next["rng_state"] = 0
	next["precombat_snapshot"] = {}
	next["retry_snapshot"] = {}
	next["defense_countdown_seconds"] = 0.0
	return {"ok": true, "error": "", "state": next}


static func save_payload(state: Dictionary) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"active": bool(state.get("active", true)),
		"status": str(state.get("status", "management")),
		"flow_state": str(state.get("flow_state", DayFlowService.INTRUSION_BRIEF)),
		"day": int(state.get("day", 1)),
		"difficulty_id": str(state.get("difficulty_id", EconomyService.DEFAULT_PROFILE_ID)),
		"economy": state.get("economy", {}).duplicate(true),
		"placement": PlacementService.serialize(state.get("placement_state", {})),
		"onboarding": state.get("onboarding", {}).duplicate(true),
		"runtime_state": state.get("runtime_state", {}).duplicate(true),
		"precombat_snapshot": state.get("precombat_snapshot", {}).duplicate(true),
		"retry_snapshot": state.get("retry_snapshot", {}).duplicate(true),
		"encounter_seed": int(state.get("encounter_seed", 2000 + int(state.get("day", 1)))),
		"rng_state": int(state.get("rng_state", 0)),
		"defense_countdown_seconds": float(state.get("defense_countdown_seconds", 0.0)),
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
	if not DayFlowService.STATES.has(str(state.get("flow_state", ""))):
		state["flow_state"] = _flow_state_from_legacy_status(str(state.get("status", "management")))
	state["runtime_state"] = state.get("runtime_state", {}).duplicate(true)
	state["precombat_snapshot"] = state.get("precombat_snapshot", state.get("retry_snapshot", {})).duplicate(true)
	state["encounter_seed"] = int(state.get("encounter_seed", 2000 + day))
	state["rng_state"] = int(state.get("rng_state", 0))
	state["defense_countdown_seconds"] = float(state.get("defense_countdown_seconds", 0.0))
	state["placement_state"] = normalize_placement_sections(placement.get("state", {}))
	state.erase("placement")
	return {"ok": true, "error": "", "state": state}


static func _flow_state_from_legacy_status(status: String) -> String:
	match status:
		"combat":
			return DayFlowService.PLACEMENT
		"result", "completed":
			return DayFlowService.RESULT
		_:
			return DayFlowService.PLACEMENT


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
	return "첫 교전선이 너무 앞에 모여 뒤쪽 구역의 연속 방어가 무너졌습니다."


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
